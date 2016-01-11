#include "jni_type_conversion.hpp"
#include "safe_jni.hpp"
#include "jni_Log.h"

#include "jni_load.h"
static inline int valueAsInt(JNIEnv *env, jclass cls, jobject value)
{
    jmethodID mid = getEnv()->GetMethodID(cls, "asInt", "()I");
    if (NULL == mid) {
        return -1;
    }
    return getEnv()->CallIntMethod(value, mid);
}

static inline void *valueAsPtr(JNIEnv *env, jclass cls, jobject value)
{
    jmethodID mid = getEnv()->GetMethodID(cls, "asObject", "()Lorg/jamruby/mruby/RBasic;");
    if (NULL == mid) {
        return NULL;
    }
    safe_jni::safe_local_ref<jobject> robj(getEnv(), getEnv()->CallObjectMethod(value, mid));
    if (!robj) {
        return NULL;
    }
    safe_jni::safe_local_ref<jclass> robj_cls(getEnv(), findClass("org/jamruby/mruby/RBasic"));
    if (!robj_cls) {
        return NULL;
    }
    jmethodID nobj_mid = getEnv()->GetMethodID(robj_cls.get(), "nativeObject", "()J");
    return reinterpret_cast<void*>(static_cast<intptr_t>(getEnv()->CallLongMethod(robj.get(), nobj_mid)));
}

static inline mrb_sym valueAsSymbol(JNIEnv *env, jclass cls, jobject value)
{
    jmethodID mid = getEnv()->GetMethodID(cls, "asSymbol", "()J");
    if (NULL == mid) {
        return 0;
    }
    return static_cast<mrb_sym>(getEnv()->CallLongMethod(value, mid));
}

static inline mrb_float valueAsFloat(JNIEnv *env, jclass cls, jobject value)
{
    jmethodID mid = getEnv()->GetMethodID(cls, "asFloat", "()D");
    if (NULL == mid) {
        return -1;
    }
    return static_cast<mrb_float>(getEnv()->CallDoubleMethod(value, mid));
}

bool create_mrb_value(JNIEnv *env, jobject value, mrb_value &store)
{
    char const value_class_name[]      = "org/jamruby/mruby/Value";
    char const value_type_class_name[] = "org/jamruby/mruby/ValueType";
    safe_jni::safe_local_ref<jclass> vclazz(getEnv(), findClass(value_class_name));
    if (!vclazz) {
        return false;
    }
    safe_jni::safe_local_ref<jclass> vtclazz(getEnv(), findClass(value_type_class_name));
    if (!vtclazz) {
        return false;
    }

    jmethodID type_mid = getEnv()->GetMethodID(vclazz.get(), "type", "()Lorg/jamruby/mruby/ValueType;");
    if (!type_mid) {
        return false;
    }
    safe_jni::safe_local_ref<jobject> vtype(getEnv(), getEnv()->CallObjectMethod(value, type_mid));
    if (!vtype) {
        return false;
    }

    jmethodID toint_mid = getEnv()->GetStaticMethodID(vtclazz.get(), "toInteger", "(Lorg/jamruby/mruby/ValueType;)I");
    if (!toint_mid) {
        return false;
    }

    int const type = getEnv()->CallStaticIntMethod(vtclazz.get(), toint_mid, vtype.get());
    switch(type) {
    case MRB_TT_TRUE:
        store = mrb_true_value();
        break;
    case MRB_TT_FALSE: {
        int i   = valueAsInt(getEnv(), vclazz.get(), value);
        void *p = valueAsPtr(getEnv(), vclazz.get(), value);
        if (0 != i) {
            store.value.i = i;
        } else {
            store.value.p = p;
        }
        break;
    }
    case MRB_TT_FLOAT:
        store.value.f = valueAsFloat(getEnv(), vclazz.get(), value);
        break;
    case MRB_TT_FIXNUM:
        store.value.i = valueAsInt(getEnv(), vclazz.get(), value);
        break;
    case MRB_TT_UNDEF:
        store = mrb_undef_value();
        break;
    case MRB_TT_SYMBOL:
        store.value.sym = valueAsSymbol(getEnv(), vclazz.get(), value);
        break;
    default:
        store.value.p = valueAsPtr(getEnv(), vclazz.get(), value);
        break;
    }
    store.tt = static_cast<mrb_vtype>(type);
    LOGD("value to { type = %d, value = %p }", store.tt, store.value.p);
    return true;
}

static inline jobject new_value(JNIEnv *env, jclass cls, mrb_vtype type, int value) {
    jmethodID ctor = getEnv()->GetMethodID(cls, "<init>", "(II)V");
    if (NULL == ctor) {
        return NULL;
    }
    return getEnv()->NewObject(cls, ctor, static_cast<int>(type), value);
}

static inline jobject new_value(JNIEnv *env, jclass cls, mrb_vtype type, void *value) {
    jmethodID ctor = getEnv()->GetMethodID(cls, "<init>", "(IJ)V");
    if (NULL == ctor) {
        return NULL;
    }
    return getEnv()->NewObject(cls, ctor, static_cast<int>(type), static_cast<jlong>(reinterpret_cast<intptr_t>(value)));
}

static inline jobject new_value(JNIEnv *env, jclass cls, int value) {
    jmethodID ctor = getEnv()->GetMethodID(cls, "<init>", "(I)V");
    if (NULL == ctor) {
        return NULL;
    }
    return getEnv()->NewObject(cls, ctor, value);
}

static inline jobject new_value(JNIEnv *env, jclass cls, mrb_float value) {
    jmethodID ctor = getEnv()->GetMethodID(cls, "<init>", "(D)V");
    if (NULL == ctor) {
        return NULL;
    }
    return getEnv()->NewObject(cls, ctor, static_cast<jdouble>(value));
}

static inline jobject new_value_sym(JNIEnv *env, jclass cls, mrb_sym value) {
    jmethodID ctor = getEnv()->GetMethodID(cls, "<init>", "(IJ)V");
    if (NULL == ctor) {
        return NULL;
    }
    return getEnv()->NewObject(cls, ctor, static_cast<int>(MRB_TT_SYMBOL), static_cast<jlong>(value));
}

jobject create_value(JNIEnv *env, mrb_value const &value) {
    safe_jni::safe_local_ref<jclass> cls(env, findClass("org/jamruby/mruby/Value"));
    if (!cls) {
        return NULL;
    }
    LOGD("value from { type = %d, value = %p }", value.tt, value.value.p);
    jobject v = NULL;
    switch(value.tt) {
    case MRB_TT_TRUE:
    case MRB_TT_FALSE:
    case MRB_TT_UNDEF:
        v = new_value(env, cls.get(), value.tt, value.value.i);
        break;
    case MRB_TT_FIXNUM:
        v = new_value(env, cls.get(), value.value.i);
        break;
    case MRB_TT_FLOAT:
        v = new_value(env, cls.get(), value.value.f);
        break;
    case MRB_TT_SYMBOL:
        v = new_value_sym(env, cls.get(), value.value.sym);
        break;
    default:
        v = new_value(env, cls.get(), value.tt, value.value.p);
        break;
    }
    return v;
}

mrb_value *create_mrb_value_array(JNIEnv *env, int const &num, jobjectArray array) {
	safe_jni::safe_object_array ar(getEnv(), array);
	mrb_value *values = NULL;
	try {
		values = new mrb_value[num];
	} catch (std::bad_alloc &e) {
	}
	if (NULL == values) {
		throw_exception(getEnv(), "java/lang/OutOfMemoryError", "insufficient memory.");
		return NULL;
	}

	for (int i = 0; i < num; ++i) {
		safe_jni::safe_local_ref<jobject> arg(getEnv(), ar.get(i));
		if (!create_mrb_value(getEnv(), arg.get(), values[i])) {
			delete[] values;
			return NULL;
		}
	}
	return values;
}

