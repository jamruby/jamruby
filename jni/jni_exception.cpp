#include "jni_exception.hpp"
#include "safe_jni.hpp"

void throw_exception(JNIEnv *env, char const *name, char const *message)
{
	safe_jni::safe_local_ref<jclass> clazz(getEnv(), getEnv()->FindClass(name));
	if (!clazz) {
		return;
	}
	getEnv()->ThrowNew(clazz.get(), message);
}

