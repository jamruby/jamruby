#ifndef JAMRUBY_JNI_FUNCTOR_H
#define JAMRUBY_JNI_FUNCTOR_H

#include <jni.h>
#include "jamruby_jni_types.h"

template <typename JType> class jni_functor {
private:
	JNIEnv *env_;
	jni_functor();
	jni_functor(jni_functor const&);
	jni_functor &operator=(jni_functor const&);
public:
	jni_functor(JNIEnv *env) : env_(env) {
	}
		~jni_functor() {
	}
	jvalue operator () (jni_type_t const &type, JType obj, jmethodID jmid, jvalue *args) const {
		// JNIEnv *env = env_;
		jvalue ret;
		if (type.is_array()) {
			ret.l = getEnv()->CallObjectMethodA(obj, jmid, args);
		} else {
			switch(type.type_id()) {
			case JNI_TYPE_VOID:
				getEnv()->CallVoidMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_BOOLEAN:
				ret.z = getEnv()->CallBooleanMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_BYTE:
				ret.b = getEnv()->CallByteMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_CHAR:
				ret.c = getEnv()->CallCharMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_SHORT:
				ret.s = getEnv()->CallShortMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_INT:
				ret.i = getEnv()->CallIntMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_LONG:
				ret.j = getEnv()->CallLongMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_FLOAT:
				ret.f = getEnv()->CallFloatMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_DOUBLE:
				ret.d = getEnv()->CallDoubleMethodA(obj, jmid, args);
				break;
			case JNI_TYPE_OBJECT:
				ret.l = getEnv()->CallObjectMethodA(obj, jmid, args);
				break;
			default:
				// TODO handle error.
				break;
			}
		}
		return ret;
	}
};

template <> class jni_functor<jclass> {
private:
	JNIEnv *env_;
	jni_functor();
	jni_functor(jni_functor const&);
	jni_functor &operator=(jni_functor const&);
public:
	jni_functor(JNIEnv *env) : env_(env) {
	}
	~jni_functor() {
	}
	jvalue operator () (jni_type_t const &type, jclass cls, jmethodID jmid, jvalue *args) const {
		// JNIEnv *env = env_;
		jvalue ret;
		if (type.is_array()) {
			ret.l = getEnv()->CallStaticObjectMethodA(cls, jmid, args);
		} else {
			switch (type.type_id()) {
			case JNI_TYPE_VOID:
				getEnv()->CallStaticVoidMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_BOOLEAN:
				ret.z = getEnv()->CallStaticBooleanMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_BYTE:
				ret.b = getEnv()->CallStaticByteMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_CHAR:
				ret.c = getEnv()->CallStaticCharMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_SHORT:
				ret.s = getEnv()->CallStaticShortMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_INT:
				ret.i = getEnv()->CallStaticIntMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_LONG:
				ret.j = getEnv()->CallStaticLongMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_FLOAT:
				ret.f = getEnv()->CallStaticFloatMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_DOUBLE:
				ret.d = getEnv()->CallStaticDoubleMethodA(cls, jmid, args);
				break;
			case JNI_TYPE_OBJECT:
				ret.l = getEnv()->CallStaticObjectMethodA(cls, jmid, args);
				break;
			default:
				// TODO handle error.
				break;
			}
		}
		return ret;
	}
};

#endif // end of JAMRUBY_JNI_FUNCTOR_H

