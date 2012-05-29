/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class org_jamruby_mruby_RHash */

#ifndef _Included_org_jamruby_mruby_RHash
#define _Included_org_jamruby_mruby_RHash
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_getIv
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RHash_n_1getIv
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_getHt
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_RHash_n_1getHt
  (JNIEnv *, jclass, jlong);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_hashSet
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_RHash_n_1hashSet
  (JNIEnv *, jclass, jlong, jobject, jobject, jobject);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_hashGet
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_RHash_n_1hashGet
  (JNIEnv *, jclass, jlong, jobject, jobject);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_hashGetWithDef
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_RHash_n_1hashGetWithDef
  (JNIEnv *, jclass, jlong, jobject, jobject, jobject);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_hashDeleteKey
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_RHash_n_1hashDeleteKey
  (JNIEnv *, jclass, jlong, jobject, jobject);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_hash
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_RHash_n_1hash
  (JNIEnv *, jclass, jlong, jobject);

/*
 * Class:     org_jamruby_mruby_RHash
 * Method:    n_checkHashType
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_RHash_n_1checkHashType
  (JNIEnv *, jclass, jlong, jobject);

#ifdef __cplusplus
}
#endif
#endif
