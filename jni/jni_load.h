
#ifndef JNI_LOAD_H
#define JNI_LOAD_H

#include <jni.h>
#include <stdlib.h>

JNIEnv *getEnv();

extern int jam_thread;
extern JavaVM* gJvm;
extern jobject gClassLoader;
extern jmethodID gFindClassMethod;
extern int jam_once;
jclass findClass(const char* name);
#endif // JNI_LOAD_H
