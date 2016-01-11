#include <jni.h>
#include "jamruby_jni_method_call.h"
#include "jni_load.h"
#include "jni_Log.h"

JavaVM* gJvm = NULL;
jobject gClassLoader;
jmethodID gFindClassMethod;
JNIEnv *gEnv;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *pjvm, void *reserved) {
	org::jamruby::init_converters();

    return JNI_VERSION_1_2;
}


jclass findClass(const char* name) {
  jclass c = NULL;
  JNIEnv *env=getEnv();
  c = env->FindClass(name);
	if (env->ExceptionCheck()) {
    env->ExceptionClear();
	  jstring str = env->NewStringUTF(name);
	  c = static_cast<jclass>(env->CallObjectMethod(gClassLoader, gFindClassMethod, str));
	  env->DeleteLocalRef(str);
	}
  return c;
}

JNIEnv* getEnv() {
	JNIEnv *env;
    gJvm->GetEnv((void**)&env, JNI_VERSION_1_2);
        int status = gJvm->AttachCurrentThread(&env, NULL);
        if(status < 0) {        
            return NULL;
        }
    
    return env;
}


void JNI_OnUnload(JavaVM *vm, void *reserved)
{
	// nothing to do
}

