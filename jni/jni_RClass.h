/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class org_jamruby_mruby_RClass */

#ifndef _Included_org_jamruby_mruby_RClass
#define _Included_org_jamruby_mruby_RClass
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_getSuperClass
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1getSuperClass
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_getIv
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1getIv
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_getMt
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1getMt
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_defineClassId
 * Signature: (JJJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1defineClassId
  (JNIEnv *, jclass, jlong, jlong, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_defineModuleId
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1defineModuleId
  (JNIEnv *, jclass, jlong, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_vmDefineClass
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1vmDefineClass
  (JNIEnv *, jclass, jlong, jobject, jobject, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_vmDefineModule
 * Signature: (JLorg/jamruby/mruby/Value;J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1vmDefineModule
  (JNIEnv *, jclass, jlong, jobject, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_defineMethodVm
 * Signature: (JJJLorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_RClass_n_1defineMethodVm
  (JNIEnv *, jclass, jlong, jlong, jlong, jobject);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_defineMethodRaw
 * Signature: (JJJJ)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_RClass_n_1defineMethodRaw
  (JNIEnv *, jclass, jlong, jlong, jlong, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_classOuterModule
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1classOuterModule
  (JNIEnv *, jclass, jlong, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_methodSearch
 * Signature: (JJJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1methodSearch
  (JNIEnv *, jclass, jlong, jlong, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_respondTo
 * Signature: (JLorg/jamruby/mruby/Value;J)Z
 */
JNIEXPORT jboolean JNICALL Java_org_jamruby_mruby_RClass_n_1respondTo
  (JNIEnv *, jclass, jlong, jobject, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_objIsInstanceOf
 * Signature: (JLorg/jamruby/mruby/Value;J)Z
 */
JNIEXPORT jboolean JNICALL Java_org_jamruby_mruby_RClass_n_1objIsInstanceOf
  (JNIEnv *, jclass, jlong, jobject, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_classReal
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RClass_n_1classReal
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RClass
 * Method:    n_objCallInit
 * Signature: (JLorg/jamruby/mruby/Value;I[Lorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_RClass_n_1objCallInit
  (JNIEnv *, jclass, jlong, jobject, jint, jobjectArray);

#ifdef __cplusplus
}
#endif
#endif
