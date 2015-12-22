#include "jni_MRuby.h"
#include "jni_Log.h"
#include "safe_jni.hpp"
#include "jni_type_conversion.hpp"
#include "jni_common.hpp"
extern "C" {
#include "mruby.h"
#include "mruby/dump.h"
#include "mruby/compile.h"
#include "mruby/proc.h"
#include "mruby/array.h"
#include "mruby/string.h"
#include "mruby/class.h"
}
#include <unistd.h>
#include <cstdio>
#include <cerrno>
#include <cstring>
#include <map>

#include "jamruby_JClass.h"
#include "jamruby_JObject.h"
#include "jamruby_JMethod.h"
#include "jamruby_JThrowable.h"
#include "jamruby_Context.h"
#include "jamruby_mruby_ext.h"
#include "jamruby_mruby_utils.h"

#define MRBSTATE(mrb) to_ptr<mrb_state>(mrb)

static inline mrb_sym to_sym(jlong &sym) {
	return static_cast<mrb_sym>(sym);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_redirect_stdout
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1redirect_1stdout
  (JNIEnv *env, jclass clazz)
{
	int stdout_pipe[2] = { -1, -1 };
	if (0 > pipe(stdout_pipe)) {
		throw_exception(env, "java/io/IOException", "Can not create pipe.");
		return -1;
	}
	if (0 > dup2(stdout_pipe[1], STDOUT_FILENO)) {
		throw_exception(env, "java/io/IOException", "Can not duplicate file descriptor.");
		return -1;
	}
	(void)close(stdout_pipe[1]);
	return stdout_pipe[0];
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_redirect_stderr
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1redirect_1stderr
  (JNIEnv *env, jclass clazz)
{
	int stderr_pipe[2] = { -1, -1 };
	if (0 > pipe(stderr_pipe)) {
		throw_exception(env, "java/io/IOException", "Can not create pipe.");
		return -1;
	}
	if (0 > dup2(stderr_pipe[1], STDERR_FILENO)) {
		throw_exception(env, "java/io/IOException", "Can not duplicate file descriptor.");
		return -1;
	}
	(void)close(stderr_pipe[1]);
	return stderr_pipe[0];
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_redirect_stdin
 * Signature: ()I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1redirect_1stdin
  (JNIEnv *env, jclass clazz)
{
	int stdin_pipe[2] = { -1, -1 };
	if (0 > pipe(stdin_pipe)) {
		throw_exception(env, "java/io/IOException", "Can not create pipe.");
		return -1;
	}
	if (0 > dup2(stdin_pipe[0], STDIN_FILENO)) {
		throw_exception(env, "java/io/IOException", "Can not duplicate file descriptor.");
		return -1;
	}
	(void)close(stdin_pipe[0]);
	return stdin_pipe[1];
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_loadIrep
 * Signature: (JLjava/lang/String;)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1loadIrep
  (JNIEnv *env, jclass clazz, jlong mrb, jstring path)
{
	int n = -1;
	try {
		safe_jni::safe_string file_path(env, path);
		FILE *fp = fopen(file_path.string(), "rb");
		mrb_value ret;
		if (NULL == fp) {
			throw safe_jni::file_not_found_exception(strerror(errno));
		}
		ret = mrb_load_irep_file(MRBSTATE(mrb), fp);
		fclose(fp);
	} catch (safe_jni::exception &e) {
		throw_exception(env, e.java_exception_name(), e.message());
	}
	return n;
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_parseString
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1parseString
  (JNIEnv *env, jclass clazz, jlong mrb, jstring command)
{
	mrb_parser_state *state = NULL;
	try {
		safe_jni::safe_string command_line(env, command);
		size_t const length = command_line.length();
		char *copy = new char[length + 1];
		if (NULL == copy) {
			throw std::bad_alloc();
		}
		strncpy(copy, command_line.string(), length);
		copy[length] = '\0';
		mrbc_context *ctx = mrbc_context_new(MRBSTATE(mrb));
		if (NULL == ctx) {
			delete[] copy;
			throw std::bad_alloc();
		}
		state = mrb_parse_string(MRBSTATE(mrb), copy, ctx);
		mrbc_context_free(MRBSTATE(mrb), ctx);
		delete[] copy;
	} catch (std::bad_alloc &e) {
		throw_exception(env, "java/lang/OutOfMemoryError", "Insufficient memory.");
	}
	return static_cast<jlong>(reinterpret_cast<intptr_t>(state));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_parseFile
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1parseFile
  (JNIEnv *env, jclass clazz, jlong mrb, jstring path)
{
	mrb_parser_state *state = NULL;
	try {
		safe_jni::safe_string file_path(env, path);
		FILE *fp = fopen(file_path.string(), "r");
		if (NULL == fp) {
			throw safe_jni::file_not_found_exception(strerror(errno));
		}
		mrbc_context *ctx = mrbc_context_new(MRBSTATE(mrb));
		if (NULL == ctx) {
			fclose(fp);
			throw new std::bad_alloc();
		}
		state = mrb_parse_file(MRBSTATE(mrb), fp, ctx);
		mrbc_context_free(MRBSTATE(mrb), ctx);
		fclose(fp);
	} catch (safe_jni::exception &e) {
		throw_exception(env, e.java_exception_name(), e.message());
	} catch (std::bad_alloc& e) {
		throw_exception(env, "java/lang/OutOfMemoryError", "Insufficient memory.");
	}
	return static_cast<jlong>(reinterpret_cast<intptr_t>(state));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_generateCode
 * Signature: (JJ)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1generateCode
  (JNIEnv *env, jclass clazz, jlong mrb, jlong parser_state)
{
	mrb_parser_state *pstate = to_ptr<mrb_parser_state>(parser_state);
	RProc *rproc = mrb_generate_code(MRBSTATE(mrb), pstate);
	return static_cast<jlong>(reinterpret_cast<intptr_t>(rproc));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_arrayNew
 * Signature: (J)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1arrayNew
  (JNIEnv *env, jclass clazz, jlong mrb)
{
	mrb_value const &value = mrb_ary_new(MRBSTATE(mrb));
	safe_jni::safe_local_ref<jobject> val(env, create_value(env, value));
	return val.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_arrayPush
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1arrayPush
  (JNIEnv *env, jclass clazz, jlong mrb, jobject array, jobject elem)
{
	mrb_value varray = { { 0, } };
	if (!create_mrb_value(env, array, varray)) {
		return;
	}
	mrb_value velem = { { 0, } };
	if (!create_mrb_value(env, elem, velem)) {
		return;
	}
	mrb_ary_push(MRBSTATE(mrb),	varray, velem);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_procNew
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1procNew
  (JNIEnv *env, jclass clazz, jlong mrb, jlong irep)
{
	RProc *rproc = mrb_proc_new(MRBSTATE(mrb), to_ptr<mrb_irep>(irep));
	return static_cast<jlong>(reinterpret_cast<intptr_t>(rproc));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineClass
 * Signature: (JLjava/lang/String;J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1defineClass
  (JNIEnv *env, jclass, jlong mrb, jstring name, jlong superClass)
{
	safe_jni::safe_string class_name(env, name);
	RClass *cls = mrb_define_class(MRBSTATE(mrb), class_name.string(), to_ptr<RClass>(superClass));
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineModule
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1defineModule
  (JNIEnv *env, jclass, jlong mrb, jstring name)
{
	safe_jni::safe_string module_name(env, name);
	RClass *mod = mrb_define_module(MRBSTATE(mrb), module_name.string());
	return to_jlong(mod);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_singletonClass
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1singletonClass
  (JNIEnv *env, jclass, jlong mrb, jobject value)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_singleton_class(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_includeModule
 * Signature: (JJJ)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1includeModule
  (JNIEnv *env, jclass, jlong mrb, jlong c, jlong m)
{
	mrb_include_module(MRBSTATE(mrb), to_ptr<RClass>(c), to_ptr<RClass>(m));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineMethod
 * Signature: (JJLjava/lang/String;Lorg/jamruby/mruby/RFunc;I)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineMethod
  (JNIEnv *env, jclass, jlong mrb, jlong c, jstring name, jobject func, jint aspec)
{
	throw_exception(env, "org/jamruby/exception/UnsupportedImplementationException", "Unsupported method.");
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineClassMethod
 * Signature: (JJLjava/lang/String;Lorg/jamruby/mruby/RFunc;I)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineClassMethod
  (JNIEnv *env, jclass, jlong, jlong, jstring, jobject, jint)
{
	throw_exception(env, "org/jamruby/exception/UnsupportedImplementationException", "Unsupported method.");
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineSingletonMethod
 * Signature: (JJLjava/lang/String;Lorg/jamruby/mruby/RFunc;I)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineSingletonMethod
  (JNIEnv *env, jclass, jlong, jlong, jstring, jobject, jint)
{
	throw_exception(env, "org/jamruby/exception/UnsupportedImplementationException", "Unsupported method.");
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineModuleFunction
 * Signature: (JJLjava/lang/String;Lorg/jamruby/mruby/RFunc;I)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineModuleFunction
  (JNIEnv *env, jclass, jlong, jlong, jstring, jobject, jint)
{
	throw_exception(env, "org/jamruby/exception/UnsupportedImplementationException", "Unsupported method.");
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineConst
 * Signature: (JJLjava/lang/String;Lorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineConst
  (JNIEnv *env, jclass, jlong mrb, jlong c, jstring name, jobject value)
{
	safe_jni::safe_string value_name(env, name);
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return;
	}
	mrb_define_const(MRBSTATE(mrb), to_ptr<RClass>(c), value_name.string(), val);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_instanceNew
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1instanceNew
  (JNIEnv *env, jclass, jlong mrb, jobject cv)
{
	mrb_value val;
	if (!create_mrb_value(env, cv, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_instance_new(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_classNew
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1classNew
  (JNIEnv *env, jclass, jlong mrb, jlong superClass)
{
	RClass *cls = mrb_class_new(MRBSTATE(mrb), to_ptr<RClass>(superClass));
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_moduleNew
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1moduleNew
  (JNIEnv *env, jclass, jlong mrb)
{
	RClass *mod = mrb_module_new(MRBSTATE(mrb));
	return to_jlong(mod);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_classGet
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1classGet
  (JNIEnv *env, jclass, jlong mrb, jstring name)
{
	safe_jni::safe_string class_name(env, name);
	RClass *cls = mrb_class_get(MRBSTATE(mrb), class_name.string());
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_classObjGet
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1classObjGet
  (JNIEnv *env, jclass, jlong mrb, jstring name)
{
	safe_jni::safe_string obj_name(env, name);
	RClass *cls = mrb_class_get(MRBSTATE(mrb), obj_name.string());
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objDup
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1objDup
  (JNIEnv *env, jclass, jlong mrb, jobject obj)
{
	mrb_value val;
	if (create_mrb_value(env, obj, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_obj_dup(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_checkToInteger
 * Signature: (JLorg/jamruby/mruby/Value;Ljava/lang/String;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1checkToInteger
  (JNIEnv *env, jclass, jlong mrb, jobject value, jstring method)
{
	mrb_value val;
	if (!create_mrb_value(env, value ,val)) {
		return NULL;
	}
	safe_jni::safe_string method_name(env, method);
	mrb_value const &ret = mrb_check_to_integer(MRBSTATE(mrb), val, method_name.string());
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objRespondTo
 * Signature: (JJ)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1objRespondTo
  (JNIEnv *env, jclass, jlong mrb, jlong c, jlong mid)
{
	return mrb_obj_respond_to(MRBSTATE(mrb), to_ptr<RClass>(c), to_sym(mid));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineClassUnder
 * Signature: (JJLjava/lang/String;J)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1defineClassUnder
  (JNIEnv *env, jclass, jlong mrb, jlong outer, jstring name, jlong superClass)
{
	safe_jni::safe_string class_name(env, name);
	RClass *cls = mrb_define_class_under(MRBSTATE(mrb), to_ptr<RClass>(outer), class_name.string(), to_ptr<RClass>(superClass));
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineModuleUnder
 * Signature: (JJLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1defineModuleUnder
  (JNIEnv *env, jclass, jlong mrb, jlong outer, jstring name)
{
	safe_jni::safe_string module_name(env, name);
	RClass *mod = mrb_define_module_under(MRBSTATE(mrb), to_ptr<RClass>(outer), module_name.string());
	return to_jlong(mod);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_funcall
 * Signature: (JLorg/jamruby/mruby/Value;Ljava/lang/String;I[Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1funcall
  (JNIEnv *env, jclass, jlong mrb, jobject self, jstring name, jint argc, jobjectArray argv)
{
	mrb_value self_val;
	if (!create_mrb_value(env, self, self_val)) {
		return NULL;
	}

	mrb_value *values = create_mrb_value_array(env, argc, argv);
	if (NULL == values) {
		return NULL;
	}

	safe_jni::safe_string func_name(env, name);
	mrb_value const &ret = mrb_funcall_argv(MRBSTATE(mrb), self_val, mrb_intern_cstr(MRBSTATE(mrb), func_name.string()), argc, values);
	delete[] values;
	values = NULL;

	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));

	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_funcallWithBlock
 * Signature: (JLorg/jamruby/mruby/Value;Ljava/lang/String;I[Lorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1funcallWithBlock
  (JNIEnv *env, jclass, jlong mrb, jobject self, jstring name, jint argc, jobjectArray argv, jobject block)
{
	mrb_value self_val, block_val;
	if (!create_mrb_value(env, self, self_val)) {
		return NULL;
	}
	if (!create_mrb_value(env, block, block_val)) {
		return NULL;
	}

	mrb_value *values = create_mrb_value_array(env, argc, argv);
	if (NULL == values) {
		return NULL;
	}

	safe_jni::safe_string func_name(env, name);
	mrb_value const &ret = mrb_funcall_with_block(MRBSTATE(mrb), self_val, mrb_intern_cstr(MRBSTATE(mrb), func_name.string()), argc, values, block_val);
	delete[] values;
	values = NULL;

	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_intern
 * Signature: (JLjava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1intern
  (JNIEnv *env, jclass, jlong mrb, jstring name)
{
	safe_jni::safe_string symbol_name(env, name);
	mrb_sym mid = mrb_intern_cstr(MRBSTATE(mrb), symbol_name.string());
	return static_cast<jlong>(mid);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_sym2name
 * Signature: (JJ)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_org_jamruby_mruby_MRuby_n_1sym2name
  (JNIEnv *env, jclass clazz, jlong mrb, jlong sym)
{
	safe_jni::safe_local_ref<jstring> jstr(env, env->NewStringUTF(mrb_sym2name(MRBSTATE(mrb), to_sym(sym))));
	return jstr.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_malloc
 * Signature: (JJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1malloc
  (JNIEnv *env, jclass, jlong mrb, jlong size)
{
	if (0 < size) {
		throw_exception(env, "java/lang/IllegalArgumentException", "'size' must be positive value.");
		return to_jlong(NULL);
	}
	void *ptr = mrb_malloc(MRBSTATE(mrb), static_cast<size_t>(size));
	return to_jlong(ptr);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_calloc
 * Signature: (JJJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1calloc
  (JNIEnv *env, jclass, jlong mrb, jlong nelem, jlong len)
{
	void *ptr = mrb_calloc(MRBSTATE(mrb), static_cast<size_t>(nelem), static_cast<size_t>(len));
	return to_jlong(ptr);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_realloc
 * Signature: (JJJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1realloc
  (JNIEnv *env, jclass, jlong mrb, jlong p, jlong len)
{
	void *ptr = mrb_realloc(MRBSTATE(mrb), to_ptr<void>(p), static_cast<size_t>(len));
	return to_jlong(ptr);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objAlloc
 * Signature: (JIJ)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1objAlloc
  (JNIEnv *env, jclass, jlong mrb, jint ttype, jlong c)
{
	RBasic *obj = mrb_obj_alloc(MRBSTATE(mrb), static_cast<mrb_vtype>(ttype), to_ptr<RClass>(c));
	return to_jlong(obj);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_free
 * Signature: (JJ)J
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1free
  (JNIEnv *env, jclass, jlong mrb, jlong p)
{
	mrb_free(MRBSTATE(mrb), to_ptr<void>(p));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_strNew
 * Signature: (JLjava/lang/String;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1strNew
  (JNIEnv *env, jclass clazz, jlong mrb, jstring str)
{
	safe_jni::safe_string jstr(env, str);
	mrb_value const &value = mrb_str_new(MRBSTATE(mrb), jstr.string(), jstr.length());
	safe_jni::safe_local_ref<jobject> val(env, create_value(env, value));
	return val.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_open
 * Signature: ()J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1open
  (JNIEnv *env, jclass clazz)
{
	return to_jlong(mrb_open());
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_topSelf
 * Signature: (J)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1topSelf
  (JNIEnv *env, jclass clazz, jlong mrb)
{
	safe_jni::safe_local_ref<jclass> vclazz(env, env->FindClass("org/jamruby/mruby/Value"));
	if (!vclazz) {
		return NULL;
	}
	jmethodID ctor = env->GetMethodID(vclazz.get(), "<init>", "(IJ)V");
	if (NULL == ctor) {
		return NULL;
	}
	mrb_value const &value = mrb_top_self(MRBSTATE(mrb));
	safe_jni::safe_local_ref<jobject> val(env, create_value(env, value)); 
	return val.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_run
 * Signature: (JJLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1run
  (JNIEnv *env, jclass clazz, jlong mrb, jlong proc, jobject value)
{
	mrb_value val = { { 0, } };
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	mrb_value ret = mrb_run(MRBSTATE(mrb), to_ptr<RProc>(proc), val);
	safe_jni::safe_local_ref<jobject> vref(env, create_value(env, ret));
	return vref.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_p
 * Signature: (JLorg/jamruby/mruby/Value;)V;
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1p
  (JNIEnv *env, jclass clazz, jlong mrb, jobject value)
{
	mrb_value val = { { 0, } };
	if (!create_mrb_value(env, value, val)) {
		return;
	}
	mrb_p(MRBSTATE(mrb), val);
	fflush(0);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_toId
 * Signature: (JLorg/jamruby/mruby/Value;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1toId
  (JNIEnv *env, jclass, jlong mrb, jobject name)
{
	mrb_value name_val;
	if (!create_mrb_value(env, name, name_val)) {
		return 0;
	}
	mrb_sym mid = mrb_obj_to_sym(MRBSTATE(mrb), name_val);
	return static_cast<jlong>(mid);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objEqual
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1objEqual
  (JNIEnv *env, jclass, jlong mrb, jobject left, jobject right)
{
	mrb_value left_val, right_val;
	if (!create_mrb_value(env, left, left_val)) {
		return 0;
	}
	if (!create_mrb_value(env, right, right_val)) {
		return 0;
	}
	return mrb_obj_equal(MRBSTATE(mrb), left_val, right_val);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_equal
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1equal
  (JNIEnv *env, jclass, jlong mrb, jobject left, jobject right)
{
	mrb_value left_val, right_val;
	if (!create_mrb_value(env, left, left_val)) {
		return 0;
	}
	if (!create_mrb_value(env, right, right_val)) {
		return 0;
	}
	return mrb_equal(MRBSTATE(mrb), left_val, right_val);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_Integer
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1Integer
  (JNIEnv *env, jclass, jlong mrb, jobject value)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_Integer(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_Float
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1Float
  (JNIEnv *env, jclass, jlong mrb, jobject value)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_Float(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_inspect
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1inspect
  (JNIEnv *env, jclass, jlong mrb, jobject value)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_inspect(MRBSTATE(mrb), val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_eql
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1eql
  (JNIEnv *env, jclass, jlong mrb, jobject left, jobject right)
{
	mrb_value left_val, right_val;
	if (!create_mrb_value(env, left, left_val)) {
		return 0;
	}
	if (!create_mrb_value(env, right, right_val)) {
		return 0;
	}
	return mrb_eql(MRBSTATE(mrb), left_val, right_val);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_checkConvertType
 * Signature: (JLorg/jamruby/mruby/Value;ILjava/lang/String;Ljava/lang/String;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1checkConvertType
  (JNIEnv *env, jclass, jlong mrb, jobject value, jint type, jstring tname, jstring method)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	safe_jni::safe_string type_name(env, tname);
	safe_jni::safe_string method_name(env, method);
	mrb_value const &ret = mrb_check_convert_type(MRBSTATE(mrb), val, (mrb_vtype)type, type_name.string(), method_name.string());
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_anyToS
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1anyToS
  (JNIEnv *env, jclass, jlong mrb, jobject obj)
{
	mrb_value obj_val;
	if (!create_mrb_value(env, obj, obj_val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_any_to_s(MRBSTATE(mrb), obj_val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objClassname
 * Signature: (JLorg/jamruby/mruby/Value;)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_org_jamruby_mruby_MRuby_n_1objClassname
  (JNIEnv *env, jclass, jlong mrb, jobject obj)
{
	mrb_value obj_val;
	if (!create_mrb_value(env, obj, obj_val)) {
		return NULL;
	}
	char const *name = mrb_obj_classname(MRBSTATE(mrb), obj_val);
	if (NULL == name) {
		return NULL;
	}
	safe_jni::safe_local_ref<jstring> class_name(env, env->NewStringUTF(name));
	return class_name.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objClass
 * Signature: (JLorg/jamruby/mruby/Value;)J
 */
JNIEXPORT jlong JNICALL Java_org_jamruby_mruby_MRuby_n_1objClass
  (JNIEnv *env, jclass, jlong mrb, jobject obj)
{
	mrb_value obj_val;
	if (!create_mrb_value(env, obj, obj_val)) {
		return to_jlong(NULL);
	}
	RClass *cls = mrb_obj_class(MRBSTATE(mrb), obj_val);
	return to_jlong(cls);
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_classPath
 * Signature: (JJ)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1classPath
  (JNIEnv *env, jclass, jlong mrb, jlong c)
{
	mrb_value const &ret = mrb_class_path(MRBSTATE(mrb), to_ptr<RClass>(c));
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_convertType
 * Signature: (JLorg/jamruby/mruby/Value;ILjava/lang/String;Ljava/lang/String;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1convertType
  (JNIEnv *env, jclass, jlong mrb, jobject value, jint type, jstring tname, jstring method)
{
	mrb_value val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	safe_jni::safe_string type_name(env, tname);
	safe_jni::safe_string method_name(env, method);
	mrb_value const &ret = mrb_convert_type(MRBSTATE(mrb), val, (mrb_vtype)type, type_name.string(), method_name.string());
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objIsKindOf
 * Signature: (JLorg/jamruby/mruby/Value;J)I
 */
JNIEXPORT jint JNICALL Java_org_jamruby_mruby_MRuby_n_1objIsKindOf
  (JNIEnv *env, jclass, jlong mrb, jobject obj, jlong c)
{
	mrb_value val;
	if (!create_mrb_value(env, obj, val)) {
		return -1;
	}
	return mrb_obj_is_kind_of(MRBSTATE(mrb), val, to_ptr<RClass>(c));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objInspect
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1objInspect
  (JNIEnv *env, jclass, jlong mrb, jobject self)
{
	mrb_value self_val;
	if (!create_mrb_value(env, self, self_val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_obj_inspect(MRBSTATE(mrb), self_val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objClone
 * Signature: (JLorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1objClone
  (JNIEnv *env, jclass, jlong mrb, jobject self)
{
	mrb_value self_val;
	if (!create_mrb_value(env, self, self_val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_obj_clone(MRBSTATE(mrb), self_val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_raise
 * Signature: (JJLjava/lang/String;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1raise
  (JNIEnv *env, jclass, jlong mrb, jlong c, jstring msg)
{
	safe_jni::safe_string message(env, msg);
	mrb_raise(MRBSTATE(mrb), to_ptr<RClass>(c), message.string());
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_warn
 * Signature: (JLjava/lang/String;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1warn
  (JNIEnv *env, jclass, jlong mrb, jstring msg)
{
	safe_jni::safe_string message(env, msg);
	mrb_warn(MRBSTATE(mrb), message.string());
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_bug
 * Signature: (JLjava/lang/String;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1bug
  (JNIEnv *env, jclass, jlong mrb, jstring msg)
{
	safe_jni::safe_string message(env, msg);
	mrb_bug(MRBSTATE(mrb), message.string());
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_yield
 * Signature: (JLorg/jamruby/mruby/Value;Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1yield
  (JNIEnv *env, jclass, jlong mrb, jobject value, jobject blk)
{
	mrb_value val, blk_val;
	if (!create_mrb_value(env, value, val)) {
		return NULL;
	}
	if (!create_mrb_value(env, blk, blk_val)) {
		return NULL;
	}
	mrb_value const &ret = mrb_yield(MRBSTATE(mrb), val, blk_val);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_yieldArgv
 * Signature: (JLorg/jamruby/mruby/Value;I[Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1yieldArgv
  (JNIEnv *env, jclass, jlong mrb, jobject blk, jint argc, jobjectArray argv)
{
	mrb_value blk_val;
	if (!create_mrb_value(env, blk, blk_val)) {
		return NULL;
	}
	mrb_value *values = create_mrb_value_array(env, argc, argv);
	if (NULL == values) {
		return NULL;
	}
	mrb_value const &ret = mrb_yield_argv(MRBSTATE(mrb), blk_val, argc, values);
	delete[] values;
	values = NULL;
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_classNewInstance
 * Signature: (JI[Lorg/jamruby/mruby/Value;J)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1classNewInstance
  (JNIEnv *env, jclass, jlong mrb, jint argc, jobjectArray argv, jlong c)
{
	mrb_value *values = create_mrb_value_array(env, argc, argv);
	if (NULL == values) {
		return NULL;
	}
	mrb_value const &ret = mrb_class_new_instance(MRBSTATE(mrb), argc, values, to_ptr<RClass>(c));
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_objNew
 * Signature: (JJI[Lorg/jamruby/mruby/Value;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1objNew
  (JNIEnv *env, jclass, jlong mrb, jlong c, jint argc, jobjectArray argv)
{
	mrb_value *values = create_mrb_value_array(env, argc, argv);
	mrb_value const &ret = mrb_obj_new(MRBSTATE(mrb), to_ptr<RClass>(c), argc, values);
	safe_jni::safe_local_ref<jobject> result(env, create_value(env, ret));
	delete[] values;
	values = NULL;
	return result.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineAlias
 * Signature: (JJLjava/lang/String;Ljava/lang/String;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineAlias
  (JNIEnv *env, jclass, jlong mrb, jlong c, jstring name1, jstring name2)
{
	safe_jni::safe_string n1(env, name1);
	safe_jni::safe_string n2(env, name2);
	mrb_define_alias(MRBSTATE(mrb), to_ptr<RClass>(c), n1.string(), n2.string());
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_className
 * Signature: (JJ)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_org_jamruby_mruby_MRuby_n_1className
  (JNIEnv *env, jclass, jlong mrb, jlong c)
{
	char const *name = mrb_class_name(MRBSTATE(mrb), to_ptr<RClass>(c));
	safe_jni::safe_local_ref<jstring> class_name(env, env->NewStringUTF(name));
	return class_name.get();
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_defineGlobalConst
 * Signature: (JLjava/lang/String;Lorg/jamruby/mruby/Value;)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1defineGlobalConst
  (JNIEnv *env, jclass clazz, jlong mrb, jstring name, jobject value)
{
	safe_jni::safe_string vname(env, name);
	mrb_value val = { { 0, } };
	if (!create_mrb_value(env, value, val)) {
		return;
	}
	mrb_define_global_const(MRBSTATE(mrb), vname.string(), val);
}

static mrb_value java_find_class(mrb_state *mrb, mrb_value self)
{
	using namespace org::jamruby;
	jamruby_context *context = jamruby_context::find_context(mrb);
	if (NULL == context) {
		LOGE("cannot find jamruby context.");
		return mrb_nil_value();
	}

	JNIEnv *env = context->get_jni_env();
	if (NULL == env) {
		LOGE("null environment.");
		return mrb_nil_value();
	}

	mrb_value class_name;
	int argc = mrb_get_args(mrb, "o", &class_name);
	if (1 != argc) {
		LOGE("invalid argument (argc = %d, %s).", argc, mrb_string_value_ptr(mrb, class_name));
		return mrb_nil_value();
	}

	env->ExceptionClear();
	return jcls_make(mrb, env, mrb_string_value_ptr(mrb, class_name));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_init_JNI_module
 * Signature: (JJ)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1init_1JNI_1module
  (JNIEnv *env, jclass, jlong mrb, jlong threadId)
{
	using namespace org::jamruby;
	jamruby_context *context = jamruby_context::register_context(MRBSTATE(mrb), env);
	if (NULL == context) {
		LOGE("cannot register jamruby context.");
		return;
	}

	RClass *mod_jni = mrb_define_module(MRBSTATE(mrb), "JAVA");
	mrb_define_const(MRBSTATE(mrb), mod_jni, "JAVA_THREAD_ID", mrb_fixnum_value(threadId));
	mrb_define_module_function(MRBSTATE(mrb), mod_jni, "find_class", java_find_class, MRB_ARGS_REQ(1));

	if (0 != jobject_init_class(MRBSTATE(mrb))) {
		// TODO error handling
	}

	if (0 != jcls_init_class(MRBSTATE(mrb))) {
		// TODO error handling
	}

	if (0 != jmethod_init_class(MRBSTATE(mrb))) {
		// TODO error handling
	}

	if (0 != jthrowable_init_class(MRBSTATE(mrb))) {
		// TODO error handling
	}
    LOGE("jam 1");
	RClass *clsKern = mrb_class_get(MRBSTATE(mrb), "Object");
	if (NULL != clsKern)
	{
		LOGE("jam 2");
		RProc * const proc = replace_mrb_func(MRBSTATE(mrb), clsKern, "require", jamruby_kernel_require);
		if (NULL != proc) {
			mrb_gc_mark(MRBSTATE(mrb), reinterpret_cast<RBasic*>(proc));
		} else {
			mrb_define_module_function(MRBSTATE(mrb), clsKern, "require", jamruby_kernel_require, MRB_ARGS_REQ(1));
		}
	}
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_cleanup_JNI_module
 * Signature: (JJ)V
 */
JNIEXPORT void JNICALL Java_org_jamruby_mruby_MRuby_n_1cleanup_1JNI_1module
  (JNIEnv *env, jclass, jlong mrb, jlong threadId)
{
	using namespace org::jamruby;
	jamruby_context::unregister_context(MRBSTATE(mrb));
}

/*
 * Class:     org_jamruby_mruby_MRuby
 * Method:    n_loadString
 * Signature: (JLjava/lang/String;)Lorg/jamruby/mruby/Value;
 */
JNIEXPORT jobject JNICALL Java_org_jamruby_mruby_MRuby_n_1loadString
  (JNIEnv *env, jclass clazz, jlong mrb, jstring code)
{

	safe_jni::safe_string script(env, code);
	mrb_value ret = mrb_load_string(MRBSTATE(mrb), script.string());
	safe_jni::safe_local_ref<jobject> vref(env, create_value(env, ret));
	return vref.get();
}
