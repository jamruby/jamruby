#include <jni.h>
#include "jamruby_jni_method_call.h"
#include "jni_load.h"
#include "jni_Log.h"

JavaVM* gJvm = NULL;
jobject gClassLoader;
jmethodID gFindClassMethod;
JNIEnv *gEnv;

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *pjvm, void *reserved) {


    	
    gJvm = pjvm;  // cache the JavaVM pointer
    

	jclass randomClass = getEnv()->FindClass("org/jamruby/core/Jamruby");
	jclass classClass = getEnv()->GetObjectClass(randomClass);
	jclass classLoaderClass = getEnv()->FindClass("java/lang/ClassLoader");
	jmethodID getClassLoaderMethod = getEnv()->GetMethodID(classClass, "getClassLoader",
											 "()Ljava/lang/ClassLoader;");
	gClassLoader = getEnv()->NewGlobalRef(getEnv()->CallObjectMethod(randomClass, getClassLoaderMethod));
	gFindClassMethod = getEnv()->GetMethodID(classLoaderClass, "findClass",
								"(Ljava/lang/String;)Ljava/lang/Class;");		


	org::jamruby::init_converters();

    return JNI_VERSION_1_6;
}


jclass findClass(const char* name) {
	if (jam_thread == 1) {
	  jstring str = getEnv()->NewStringUTF(name);
	  jclass j = static_cast<jclass>(getEnv()->CallObjectMethod(gClassLoader, gFindClassMethod, str));
	  getEnv()->DeleteLocalRef(str);
	  return j	;
	}
    return getEnv()->FindClass(name);
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

