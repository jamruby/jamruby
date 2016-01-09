#include "jni_RArray.h"
#include "jni_load.h"
extern "C" {
#include "mruby.h"
#include "mruby/array.h"
}
#include <cstddef>

#include "safe_jni.hpp"
#include "jni_type_conversion.hpp"
#include "jni_common.hpp"

/*
 * Class:     org_jamruby_mruby_RArray
 * Method:    n_getLen
 * Signature: (J)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_RArray_n_1getLen
  (JNIEnv *env, jclass clazz, jlong array)
{
	return to_ptr<RArray>(array)->len;
}

/*
 * Class:     org_jamruby_mruby_RArray
 * Method:    n_getCapa
 * Signature: (J)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_RArray_n_1getCapa
  (JNIEnv *env, jclass clazz, jlong array)
{
	return to_ptr<RArray>(array)->aux.capa;
}

/*
 * Class:     org_jamruby_mruby_RArray
 * Method:    n_getPtr
 * Signature: (J)[Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobjectArray JNICALL Java_org_jamruby_mruby_RArray_n_1getPtr
  (JNIEnv *env, jclass clazz, jlong array)
{
	size_t const len = to_ptr<RArray>(array)->len;
	mrb_value const * const values = to_ptr<RArray>(array)->ptr;

	if (NULL == values) {
		return NULL;
	}

	safe_jni::safe_local_ref<jclass> cls(getEnv(), findClass("org/jamruby/mruby/Value"));
	safe_jni::safe_local_ref<jobjectArray> valArray(getEnv(), getEnv()->NewObjectArray(len, cls.get(), NULL));

	for (size_t i = 0; i < len; ++i) {
		safe_jni::safe_local_ref<jobject> val(getEnv(), create_value(getEnv(), values[i]));
		getEnv()->SetObjectArrayElement(valArray.get(), i, val.get());
	}

	return valArray.get();
}

