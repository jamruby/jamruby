#include "jamruby_mruby_ext.h"
#include "jamruby_mruby_utils.h"
#include "jamruby_Context.h"
#include "jamruby_jni_method_call.h"
#include "jamruby_jni_functor.h"
#include "jamruby_MethodResolver.h"
#include "jamruby_JObject.h"
#include "jamruby_JThrowable.h"
#include "jamruby_JClass.h"
#include "jamruby_JMethod.h"
#include "jni_Log.h"
#include "safe_jni.hpp"
#include <cstring>
extern "C" {
#include "mruby.h"
#include "mruby/dump.h"
#include "mruby/compile.h"
#include <mruby/string.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <mruby/range.h>
#include <mruby/proc.h>
#include <mruby/data.h>
#include <mruby/class.h>
#include <mruby/value.h>
#include <mruby/variable.h>
#include <string.h>
#ifndef _MSC_VER
#include <strings.h>
#include <unistd.h>
#endif
#ifdef _WIN32
#include <windows.h>
#endif
#include <ctype.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
}
#include <string>
#include <vector>
#include <algorithm>

namespace org {
namespace jamruby {

static std::string gen_java_class_name(std::string const &name, int const &len);
static std::string gen_java_inner_class_path(std::string const &name, int const &len);
static void export_jclass(mrb_state *mrb, JNIEnv *env, jclass cls, std::string const &name, std::string const &nice);
static RClass* define_class(mrb_state *mrb, JNIEnv *env, RClass *parent, jclass cls, std::string const &name);
static mrb_value java_class_method(mrb_state *mrb, mrb_value self);
static mrb_value java_object_method(mrb_state *mrb, mrb_value self);

};
};

mrb_value jamruby_kernel_require(mrb_state *mrb, mrb_value self)
{
	using namespace org::jamruby;

	LOGD("'Jamruby.Kernel.require' is called instead of '%s.%s'.",
		mrb_class_name(mrb, get_called_mrb_class(mrb)), get_called_mrb_func_name(mrb));

	mrb_value name;
	int const argc = mrb_get_args(mrb, "S", &name);
	if (1 != argc) {
		mrb_raisef(mrb, E_ARGUMENT_ERROR, "wrong number of arguments (%d for 1)", argc);
		return mrb_nil_value(); // don't reach here
	}

	if (mrb_type(name) != MRB_TT_STRING) {
		name = mrb_funcall(mrb, name, "to_s", 0);
	}

	char const * const str = RSTRING_PTR(name);
	int const len = RSTRING_LEN(name);
LOGE("DAZ CLAZZ: %s", str);
	if (len > 3) {
		// if 'name' is end with ".rb", loading ruby script file.
		if (0 == strncmp(&str[len-3], ".rb", 3)) {
			// TODO call original 'Kernel.require' method.
			return mrb_nil_value();
		}
	}

	jamruby_context *context = jamruby_context::find_context(mrb);
	if (NULL == context) {
		LOGE("UH OH");
		mrb_raise(mrb, E_RUNTIME_ERROR, "jamruby context cannot found.");
		return mrb_nil_value(); // don't reach here
	}

	std::string const class_name = gen_java_class_name(str, len);

	// JNIEnv *env = getEnv();
	safe_jni::safe_local_ref<jclass> cls(getEnv(), findClass(class_name.c_str()));
	if (!cls) {
		LOGE("class not in JVM");
		getEnv()->ExceptionClear();
		// TODO call original 'Kernel.require' method.
		mrb_raisef(mrb, E_NAME_ERROR, "class '%s' is not found in JVM.", str);
		return mrb_nil_value(); // don't reach here
	}
    LOGE("PRE EXP");
	export_jclass(mrb,getEnv(), cls.get(), class_name, gen_java_inner_class_path(class_name.c_str(), len));

	return mrb_nil_value();
}

namespace org {
namespace jamruby {

static bool is_dot(char const &c)
{
	return '.' == c ? true : false;
}

static bool is_dollar(char const &c)
{
	return '$' == c ? true : false;
}

static std::string gen_java_class_name(std::string const &name, int const &len)
{
	std::string copied;
	copied.resize(len+1);
	std::replace_copy_if(name.begin(), name.end(), copied.begin(), is_dot, '/');
	copied[len] = '\0';
	return copied;
}

static std::string gen_java_inner_class_path(std::string const &name, int const &len)
{
	std::string copied;
	copied.resize(len+1);
	std::replace_copy_if(name.begin(), name.end(), copied.begin(), is_dollar, '/');
	copied[len] = '\0';
	return copied;
}

static void export_jclass(mrb_state *mrb, JNIEnv *env, jclass cls, std::string const &name, std::string const &nice)
{
	std::string::size_type ofst = 0;
	RClass *parent = NULL;
	LOGD("export java class '%s'.", name.c_str());
	for (;;) {
		std::string::size_type const n = nice.find_first_of('/', ofst);
		std::string mod_name = nice.substr(ofst, n - ofst);
		if (std::islower(mod_name[0])) {
			mod_name[0] = std::toupper(mod_name[0]);
		}
		if (std::string::npos == n) {
			RClass* target = define_class(mrb,getEnv(), parent, cls, mod_name);
			 mrb_define_const(mrb, target, "CLASS_PATH", mrb_str_new_cstr(mrb, name.c_str()));
			break;
		}
		ofst = n + 1;
    RClass *j;
    if (mrb_const_defined_at(mrb, mrb_obj_value(mrb->object_class), mrb_intern_cstr(mrb, "JAVA"))) {
      j = mrb_module_get(mrb, "JAVA");
    } else {
      j = mrb_define_module(mrb, "JAVA");
    }

		RClass *mod;
		mrb_sym const sym = mrb_intern_cstr(mrb, mod_name.c_str());
		if (NULL == parent) {
			if (mrb_const_defined_at(mrb, mrb_obj_value(j), sym)) {
				mod = mrb_module_get_under(mrb, j, mod_name.c_str());
			} else {
				LOGD("define module (%s)\n", mod_name.c_str());
				mod = mrb_define_module_under(mrb, j, mod_name.c_str());
			}
		} else {
			if (mrb_const_defined_at(mrb, mrb_obj_value(parent), sym)) {
				mod = mrb_class_ptr(mrb_const_get(mrb, mrb_obj_value(parent), sym));
			} else {
				LOGD("define module (%s::%s)\n", mrb_string_value_ptr(mrb, mrb_class_path(mrb, parent)), mod_name.c_str());
				mod = mrb_define_module_under(mrb, parent, mod_name.c_str());
			}
		}
		if (NULL == mod) {
			// TODO error handling
			LOGE("failed to define module (%s)\n", mod_name.c_str());
			return;
		}
		parent = mod;
	}
}

static bool is_method_defined(mrb_state *mrb, RClass *target, char const * const name)
{
	RClass *c = target;
	RProc *proc = mrb_method_search_vm(mrb, &c, mrb_intern_cstr(mrb, name));
	if ((c == target) && (NULL != proc)) {
		return true;
	}
	return false;
}

static bool is_class_method_defined(mrb_state *mrb, RClass *target, char const * const name)
{
	return is_method_defined(mrb, target->c, name);
}

static RClass* define_class(mrb_state *mrb, JNIEnv *env, RClass *parent, jclass cls, std::string const &name)
{
	LOGE("define class (%s::%s)\n", (NULL == parent) ? "" : mrb_string_value_ptr(mrb, mrb_class_path(mrb, parent)), name.c_str());

	// TODO resolve java class inheritance hierarchy and get the super class.
	RClass *jobject_class = mrb_class_get(mrb, "JObject");
	RClass *target;
	if (NULL == parent) {
		target = mrb_define_class(mrb, name.c_str(), jobject_class);
	} else {
		target = mrb_define_class_under(mrb, parent, name.c_str(), jobject_class);
	}
	if (NULL == target) {
		// TODO error handling.
		LOGE("cannot define the class '%s'.", name.c_str());
		return NULL;
	}
	MRB_SET_INSTANCE_TT(target, MRB_TT_DATA);

    

	jobject obj = static_cast<jobject>(cls);

	// get public constructors
	safe_jni::method<jobjectArray> get_constructors(getEnv(), obj, "getConstructors", "()[Ljava/lang/reflect/Constructor;");
	if (!get_constructors) {
		getEnv()->ExceptionClear();
		LOGE("cannot find 'getConstructors()' method in JVM.");
		return NULL;
	}

	safe_jni::safe_local_ref<jobjectArray> rctors(getEnv(), get_constructors(obj));
	if (!rctors) {
		getEnv()->ExceptionClear();
		LOGE("cannot get public constructors.");
		return NULL;
	}
	safe_jni::safe_object_array ctors(getEnv(), rctors.get());
	size_t const num_of_ctors = ctors.size();

	// get public methods
	safe_jni::method<jobjectArray> get_methods(getEnv(), obj, "getMethods", "()[Ljava/lang/reflect/Method;");
	if (!get_methods) {
		getEnv()->ExceptionClear();
		LOGE("cannot find 'getMethods()' method in JVM.");
		return NULL;
	}

	safe_jni::safe_local_ref<jobjectArray> ret(getEnv(), get_methods(obj));
	if (!ret) {
		getEnv()->ExceptionClear();
		LOGE("cannot get public methods.");
		return NULL;
	}
	safe_jni::safe_object_array methods(getEnv(), ret.get());
	size_t const num_of_methods = methods.size();
	if (0 == num_of_methods) {
		LOGW("'%s' has no methods.", name.c_str());
		return NULL;
	}

	safe_jni::safe_local_ref<jclass> modifier_class(getEnv(), findClass("java/lang/reflect/Modifier"));
	if (!modifier_class) {
		LOGE("cannot find class 'java.lang.reflect.Modifier' in JVM.");
		return NULL;
	}
	safe_jni::method<bool> is_static(getEnv(), modifier_class.get(), "isStatic", "(I)Z");
	if (!is_static) {
		LOGE("cannot find method 'isStatic'.");
		return NULL;
	}

	safe_jni::safe_local_ref<jclass> method_signature_class(getEnv(), findClass("org/jamruby/java/MethodSignature"));
	if (!method_signature_class) {
		LOGE("cannot find class 'org.jamruby.java.MethodSignature' in JVM.");
		return NULL;
	}
	safe_jni::method<jstring> gen_method_signature(getEnv(), method_signature_class.get(), "genMethodSignature", "(Ljava/lang/reflect/Method;)Ljava/lang/String;");
	if (!gen_method_signature) {
		LOGE("cannot find method 'genMethodSignature'.");
		return NULL;
	}
	safe_jni::method<jstring> gen_ctor_signature(getEnv(), method_signature_class.get(), "genCtorSignature", "(Ljava/lang/reflect/Constructor;)Ljava/lang/String;");
	if (!gen_ctor_signature) {
		LOGE("cannot find method 'genCtorSignature'.");
		return NULL;
	}

	jamruby_context *context = jamruby_context::find_context(mrb);
	if (NULL == context) {
		LOGE("cannot find jamruby context.");
		return NULL;
	}

	jclass gref_cls = static_cast<jclass>(getEnv()->NewGlobalRef(cls));
	if (NULL == gref_cls) {
		LOGE("cannot create global reference.");
		return NULL;
	}

	context->register_jclass(target, gref_cls);

    mrb_value im = mrb_ary_new(mrb);
    mrb_value sm = mrb_ary_new(mrb);
    
	for (size_t i = 0; i < num_of_ctors; ++i) {
		safe_jni::safe_local_ref<jobject> c(getEnv(), ctors.get(i));
		safe_jni::safe_local_ref<jstring> js_signature(getEnv(), gen_ctor_signature(method_signature_class.get(), c.get()));
		safe_jni::safe_string signature(getEnv(), js_signature.get());
		context->register_ctor_signature(target, signature.string());
		LOGE("register constructor: <init>%s", signature.string());
	}

	for (size_t i = 0; i < num_of_methods; ++i) {
		safe_jni::safe_local_ref<jobject> m(getEnv(), methods.get(i));
		safe_jni::method<jstring> get_name(getEnv(), m.get(), "getName", "()Ljava/lang/String;");
		safe_jni::safe_local_ref<jstring> mname(getEnv(), get_name(m.get()));
		safe_jni::safe_string mname_str(getEnv(), mname.get());

		safe_jni::safe_local_ref<jstring> js_signature(getEnv(), gen_method_signature(method_signature_class.get(), m.get()));
		safe_jni::safe_string signature(getEnv(), js_signature.get());

		safe_jni::method<int> get_modifiers(getEnv(), m.get(), "getModifiers", "()I");
		if (!get_modifiers) {
			LOGW("cannot find 'getModifiers' method.");
			break;
		}
		int const modifiers = get_modifiers(m.get());
		if (is_static(modifier_class.get(), modifiers)) {
			context->register_method_signature(true, target, mname_str.string(), signature.string());
			if (is_class_method_defined(mrb, target, mname_str.string())) {
				// already exported.
				continue;
			}

			LOGE("define class method '%s::%s : %s'.", name.c_str(), mname_str.string(), signature.string());
			mrb_define_class_method(mrb, target, mname_str.string(), java_class_method, MRB_ARGS_ANY());
			mrb_value m = mrb_ary_new(mrb);
			
			mrb_ary_push(mrb, m, mrb_str_new_cstr(mrb, mname_str.string()));
			mrb_ary_push(mrb, m, mrb_str_new_cstr(mrb, signature.string()));
			
			mrb_ary_push(mrb, sm, m);
		} else {
			context->register_method_signature(false, target, mname_str.string(), signature.string());
			if (is_method_defined(mrb, target, mname_str.string())) {
				// already exported.
				continue;
			}

			LOGE("define instance method '%s.%s : %s'.", name.c_str(), mname_str.string(), signature.string());
			mrb_define_method(mrb, target, mname_str.string(), java_object_method, MRB_ARGS_ANY());
			
			mrb_value m = mrb_ary_new(mrb);
			
			mrb_ary_push(mrb, m, mrb_str_new_cstr(mrb, mname_str.string()));
			mrb_ary_push(mrb, m, mrb_str_new_cstr(mrb, signature.string()));
			
			mrb_ary_push(mrb, im, m);
		}
		
		mrb_define_const(mrb, target, "SIGNATURES", im);
		mrb_define_const(mrb, target, "STATIC_SIGNATURES", sm);		
	}
	
	return target;
}

static mrb_value java_class_method(mrb_state *mrb, mrb_value self)
{
	if (mrb_type(self) != MRB_TT_CLASS) {
		mrb_raise(mrb, E_ARGUMENT_ERROR, "argument type must be class type.");
	}

	try {
		RClass *cls = mrb_class_ptr(self);
		jamruby_context *context = jamruby_context::find_context(mrb);
		if (NULL == context) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "jamruby context is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		jamruby_context::signatures_t const &signatures = context->find_method_signatures(true, cls, get_called_mrb_func_name(mrb));
		if (signatures.empty()) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "JVM method signature is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		jclass jcls = context->find_jclass(cls);
		if (NULL == jcls) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "class object in JVM is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		mrb_value *rb_argv = NULL;
		int rb_argc = 0;
		mrb_get_args(mrb, "*", &rb_argv, &rb_argc);

		method_resolver resolver;
		std::string const &sig = resolver.resolve_ambiguous(mrb, signatures, rb_argc, rb_argv);
		if (sig.empty()) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "JVM method signature is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		jmethodID jmid = getEnv()->GetStaticMethodID(jcls, get_called_mrb_func_name(mrb), sig.c_str());
		if (NULL == jmid) {
			LOGE("failed to get method %s::%s - %s", mrb_class_name(mrb, cls), get_called_mrb_func_name(mrb), sig.c_str());
			getEnv()->ExceptionClear();
			mrb_raise(mrb, E_RUNTIME_ERROR, "method in JVM is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		int const argc = get_count_of_arguments(sig.c_str());
		if (rb_argc != argc) {
			mrb_raise(mrb, E_ARGUMENT_ERROR, "number of argument is not match.");
			return mrb_nil_value(); // don't reach here.
		}

		jni_type_t ret_type = get_return_type(sig.c_str());
		std::vector<jvalue> jvals(argc);
		std::vector<jni_type_t> types(argc);
		if (!get_argument_types(sig.c_str(), &types[0], argc)) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "invalid signature format.");
			return mrb_nil_value(); // don't reach here.
		}

		for (int i = 0; i < argc; ++i) {
			convert_mrb_value_to_jvalue(mrb, getEnv(), rb_argv[i], jvals[i], types[i]);
		}
		

		jvalue const &ret = call_method(mrb, getEnv(), ret_type, jcls, jmid, &jvals[0]);
		
		for (int i=0; i < argc; i++) {
			switch (mrb_type(rb_argv[i])) {
			case MRB_TT_STRING: getEnv()->DeleteLocalRef(jvals[i].l);
			default: break;
			}
		}			
		
		mrb_value n = convert_jvalue_to_mrb_value(mrb, getEnv(), ret_type, ret);
		switch(mrb_type(n)) {
		case MRB_TT_STRING: getEnv()->DeleteLocalRef(ret.l);
		default: break; 
	    }
	    return n;
	} catch (std::exception& e) {
		mrb_raise(mrb, E_RUNTIME_ERROR, e.what());
	}
	return mrb_nil_value();
}

static mrb_value java_object_method(mrb_state *mrb, mrb_value self)
{
	LOGD("%s:(%u,%s - %s::%s)", __func__, self.tt, mrb_obj_classname(mrb, self), mrb_class_name(mrb, get_called_mrb_class(mrb)), get_called_mrb_func_name(mrb));
	try {
		jobject jobj = jobject_get_jobject(mrb, self);

		jamruby_context *context = jamruby_context::find_context(mrb);
		if (NULL == context) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "jamruby context is not found.");
		}

		RClass *cls = mrb_obj_class(mrb, self);

		jamruby_context::signatures_t const &signatures = context->find_method_signatures(false, cls, get_called_mrb_func_name(mrb));
		if (signatures.empty()) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "JVM method signature is not found.");
		}

		jclass jcls = context->find_jclass(cls);
		if (NULL == jcls) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "class object in JVM is not found.");
		}

		mrb_value *rb_argv = NULL;
		int rb_argc = 0;
		mrb_get_args(mrb, "*", &rb_argv, &rb_argc);

		method_resolver resolver;
		std::string const &sig = resolver.resolve_ambiguous(mrb, signatures, rb_argc, rb_argv);
		if (sig.empty()) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "JVM method signature is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		
		jmethodID jmid = getEnv()->GetMethodID(jcls, get_called_mrb_func_name(mrb), sig.c_str());
		if (NULL == jmid) {
			LOGE("failed to get method %s::%s - %s", mrb_class_name(mrb, cls), get_called_mrb_func_name(mrb), sig.c_str());
			getEnv()->ExceptionClear();
			mrb_raise(mrb, E_RUNTIME_ERROR, "method in JVM is not found.");
			return mrb_nil_value(); // don't reach here.
		}

		int const argc = get_count_of_arguments(sig.c_str());
		if (rb_argc != argc) {
			mrb_raise(mrb, E_ARGUMENT_ERROR, "number of argument is not match.");
			return mrb_nil_value(); // don't reach here.
		}

		jni_type_t ret_type = get_return_type(sig.c_str());
		std::vector<jvalue> jvals(argc);
		std::vector<jni_type_t> types(argc);
		if (!get_argument_types(sig.c_str(), &types[0], argc)) {
			mrb_raise(mrb, E_RUNTIME_ERROR, "invalid signature format.");
			return mrb_nil_value(); // don't reach here.
		}

		for (int i = 0; i < argc; ++i) {
			convert_mrb_value_to_jvalue(mrb, getEnv(), rb_argv[i], jvals[i], types[i]);
		}

		jvalue const &ret = call_method(mrb, getEnv(), ret_type, jobj, jmid, &jvals[0]);
		
		for (int i=0; i < argc; i++) {
			switch (mrb_type(rb_argv[i])) {
			case MRB_TT_STRING: getEnv()->DeleteLocalRef(jvals[i].l);
			default: break;
			}
		}			
		
		mrb_value n = convert_jvalue_to_mrb_value(mrb, getEnv(), ret_type, ret);
		switch(mrb_type(n)) {
		case MRB_TT_STRING: getEnv()->DeleteLocalRef(ret.l);
		default: break; 
	    }
	    return n;
	} catch (std::exception& e) {
		mrb_raise(mrb, E_RUNTIME_ERROR, e.what());
	}
	return mrb_nil_value();
}

};
};

typedef struct {
  int argc;
  mrb_value* argv;
  struct RProc* proc;
  pthread_t thread;
  mrb_state* mrb_caller;
  mrb_state* mrb;
  mrb_value result;
  mrb_bool alive;
} mrb_thread_context;

static void
mrb_thread_context_free(mrb_state *mrb, void *p) {
  if (p) {

    mrb_thread_context* context = (mrb_thread_context*) p;
    

    if (context->mrb && context->mrb != mrb) mrb_close(context->mrb);
    pthread_kill(context->thread, SIGINT);
    if (context->argv) free(context->argv);
    free(p);
  }
}

static const struct mrb_data_type mrb_thread_context_type = {
  "mrb_thread_context", mrb_thread_context_free,
};

typedef struct {
  pthread_mutex_t mutex;
  int locked;
} mrb_mutex_context;

static void
mrb_mutex_context_free(mrb_state *mrb, void *p) {
  if (p) {
    mrb_mutex_context* context = (mrb_mutex_context*) p;
    pthread_mutex_destroy(&context->mutex);
    free(p);
  }
}

static const struct mrb_data_type mrb_mutex_context_type = {
  "mrb_mutex_context", mrb_mutex_context_free,
};

typedef struct {
  pthread_mutex_t mutex;
  pthread_mutex_t queue_lock;
  mrb_state* mrb;
  mrb_value queue;
} mrb_queue_context;

static void
mrb_queue_context_free(mrb_state *mrb, void *p) {
  if (p) {
    mrb_queue_context* context = (mrb_queue_context*) p;
    pthread_mutex_destroy(&context->mutex);
    pthread_mutex_destroy(&context->queue_lock);
    free(p);
  }
}

static const struct mrb_data_type mrb_queue_context_type = {
  "mrb_queue_context", mrb_queue_context_free,
};

static mrb_value migrate_simple_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2);

static mrb_sym
migrate_sym(mrb_state *mrb, mrb_sym sym, mrb_state *mrb2)
{
  mrb_int len;
  const char *p = mrb_sym2name_len(mrb, sym, &len);
  return mrb_intern_static(mrb2, p, len);
}

static void
migrate_all_symbols(mrb_state *mrb, mrb_state *mrb2)
{
  mrb_sym i;
  for (i = 1; i < mrb->symidx + 1; i++) {
    migrate_sym(mrb, i, mrb2);
  }
}

static void
migrate_simple_iv(mrb_state *mrb, mrb_value v, mrb_state *mrb2, mrb_value v2)
{
  mrb_value ivars = mrb_obj_instance_variables(mrb, v);
  struct RArray *a = mrb_ary_ptr(ivars);
  mrb_value iv;
  mrb_int i;

  for (i=0; i<a->len; i++) {
    mrb_sym sym = mrb_symbol(a->ptr[i]);
    mrb_sym sym2 = migrate_sym(mrb, sym, mrb2);
    iv = mrb_iv_get(mrb, v, sym);
    mrb_iv_set(mrb2, v2, sym2, migrate_simple_value(mrb, iv, mrb2));
  }
}

static mrb_bool
is_safe_migratable_datatype(const mrb_data_type *type)
{
  static const char *known_type_names[] = {
    "mrb_mutex_context",
    "mrb_queue_context",
    "IO",
    NULL
  };
  int i;
  for (i = 0; known_type_names[i]; i++) {
    if (strcmp(type->struct_name, known_type_names[i]) == 0)
      return TRUE;
  }
  return FALSE;
}

static mrb_bool
is_safe_migratable_simple_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2)
{
  switch (mrb_type(v)) {
  case MRB_TT_OBJECT:
  case MRB_TT_EXCEPTION:
    {
      struct RObject *o = mrb_obj_ptr(v);
      mrb_value path = mrb_class_path(mrb, o->c);

      if (mrb_nil_p(path) || !mrb_class_defined(mrb2, RSTRING_PTR(path))) {
        return FALSE;
      }
    }
    break;
  case MRB_TT_FALSE:
  case MRB_TT_TRUE:
  case MRB_TT_FIXNUM:
  case MRB_TT_SYMBOL:
  case MRB_TT_FLOAT:
  case MRB_TT_STRING:
    break;
  case MRB_TT_RANGE:
    {
      struct RRange *r = mrb_range_ptr(v);
      if (!is_safe_migratable_simple_value(mrb, r->edges->beg, mrb2) ||
          !is_safe_migratable_simple_value(mrb, r->edges->end, mrb2)) {
        return FALSE;
      }
    }
    break;
  case MRB_TT_ARRAY:
    {
      struct RArray *a0;
      int i;
      a0 = mrb_ary_ptr(v);
      for (i=0; i<a0->len; i++) {
        if (!is_safe_migratable_simple_value(mrb, a0->ptr[i], mrb2)) {
          return FALSE;
        }
      }
    }
    break;
  case MRB_TT_HASH:
    {
      mrb_value ka;
      int i, l;
      ka = mrb_hash_keys(mrb, v);
      l = RARRAY_LEN(ka);
      for (i = 0; i < l; i++) {
        mrb_value k = mrb_ary_entry(ka, i);
        if (!is_safe_migratable_simple_value(mrb, k, mrb2) ||
            !is_safe_migratable_simple_value(mrb, mrb_hash_get(mrb, v, k), mrb2)) {
          return FALSE;
        }
      }
    }
    break;
  case MRB_TT_DATA:
    if (!is_safe_migratable_datatype(DATA_TYPE(v)))
      return FALSE;
    break;
  default:
    return FALSE;
    break;
  }
  return TRUE;
}

// based on https://gist.github.com/3066997
static mrb_value
migrate_simple_value(mrb_state *mrb, mrb_value v, mrb_state *mrb2) {
  mrb_value nv;

  switch (mrb_type(v)) {
  case MRB_TT_OBJECT:
  case MRB_TT_EXCEPTION:
    {
      struct RObject *o = mrb_obj_ptr(v);
      mrb_value path = mrb_class_path(mrb, o->c);
      struct RClass *c;

      if (mrb_nil_p(path)) {
        mrb_raise(mrb, E_TYPE_ERROR, "cannot migrate class");
      }
      c = mrb_class_get(mrb2, RSTRING_PTR(path));
      nv = mrb_obj_value(mrb_obj_alloc(mrb2, mrb_type(v), c));
    }
    migrate_simple_iv(mrb, v, mrb2, nv);
    break;
  case MRB_TT_FALSE:
  case MRB_TT_TRUE:
  case MRB_TT_FIXNUM:
    nv = v;
    break;
  case MRB_TT_SYMBOL:
    nv = mrb_symbol_value(migrate_sym(mrb, mrb_symbol(v), mrb2));
    break;
  case MRB_TT_FLOAT:
    nv = mrb_float_value(mrb2, mrb_float(v));
    break;
  case MRB_TT_STRING:
    nv = mrb_str_new(mrb2, RSTRING_PTR(v), RSTRING_LEN(v));
    break;
  case MRB_TT_RANGE:
    {
      struct RRange *r = mrb_range_ptr(v);
      nv = mrb_range_new(mrb2,
                         migrate_simple_value(mrb, r->edges->beg, mrb2),
                         migrate_simple_value(mrb, r->edges->end, mrb2),
                         r->excl);
    }
    break;
  case MRB_TT_ARRAY:
    {
      struct RArray *a0, *a1;
      int i;

      a0 = mrb_ary_ptr(v);
      nv = mrb_ary_new_capa(mrb2, a0->len);
      a1 = mrb_ary_ptr(nv);
      for (i=0; i<a0->len; i++) {
        int ai = mrb_gc_arena_save(mrb2);
        a1->ptr[i] = migrate_simple_value(mrb, a0->ptr[i], mrb2);
        a1->len++;
        mrb_gc_arena_restore(mrb2, ai);
      }
    }
    break;
  case MRB_TT_HASH:
    {
      mrb_value ka;
      int i, l;

      nv = mrb_hash_new(mrb2);
      ka = mrb_hash_keys(mrb, v);
      l = RARRAY_LEN(ka);
      for (i = 0; i < l; i++) {
        int ai = mrb_gc_arena_save(mrb2);
        mrb_value k = migrate_simple_value(mrb, mrb_ary_entry(ka, i), mrb2);
        mrb_value o = migrate_simple_value(mrb, mrb_hash_get(mrb, v, k), mrb2);
        mrb_hash_set(mrb2, nv, k, o);
        mrb_gc_arena_restore(mrb2, ai);
      }
    }
    migrate_simple_iv(mrb, v, mrb2, nv);
    break;
  case MRB_TT_DATA:
    if (!is_safe_migratable_datatype(DATA_TYPE(v)))
      mrb_raise(mrb, E_TYPE_ERROR, "cannot migrate object");
    nv = v;
    DATA_PTR(nv) = DATA_PTR(v);
    DATA_TYPE(nv) = DATA_TYPE(v);
    migrate_simple_iv(mrb, v, mrb2, nv);
    break;
  default:
    mrb_raise(mrb, E_TYPE_ERROR, "cannot migrate object");
    break;
  }
  return nv;
}


mrb_value java_find_class(mrb_state *mrb, mrb_value self)
{
	LOGE("nil 1");

LOGE("nil 2");
	// JNIEnv *env = getEnv();
	if (NULL == getEnv()) {
		LOGE("null environment.");
		return mrb_nil_value();
	}
LOGE("nil 4");
	mrb_value class_name;
	int argc = mrb_get_args(mrb, "o", &class_name);
	if (1 != argc) {
		LOGE("invalid argument (argc = %d, %s).", argc, mrb_string_value_ptr(mrb, class_name));
		return mrb_nil_value();
	}
LOGE("nil 3");
LOGE("nil %s","tree");
	getEnv()->ExceptionClear();
	LOGE("nil %s",mrb_string_value_ptr(mrb, class_name));
	return jcls_make(mrb,getEnv(), mrb_string_value_ptr(mrb, class_name));
}

mrb_value jam_puts(mrb_state* mrb, mrb_value self) {
	mrb_value str;
	mrb_get_args(mrb, "o", &str);
	LOGE("%s", mrb_string_value_ptr(mrb, str));
	return self;
}




// This makes findClass use a cached ClassLoader once it is set to '1'
// set to '1' once a thread is run
//
//
// Caching the class-loader in jni_load will fail
//   this works around that
int jam_thread = 0;

static void* mrb_thread_func(void* data) {
	mrb_thread_context* context = (mrb_thread_context*) data;
	mrb_state* mrb = context->mrb;

	jam_thread = 1;
	
	using namespace org::jamruby;


	// JNIEnv *env = getEnv();
    
	jamruby_context *jam_t_context = jamruby_context::register_context(context->mrb, getEnv());
	if (NULL == jam_t_context) {
		LOGE("cannot register jamruby context.");
		return NULL;
	}  


	RClass *mod_jni = mrb_define_module(context->mrb, "JAVA");
	//mrb_define_const(context->mrb, mod_jni, "JAVA_THREAD_ID", mrb_fixnum_value(threadId));
	mrb_define_module_function(context->mrb, mod_jni, "find_class", java_find_class, MRB_ARGS_REQ(1));

	if (0 != jobject_init_class(context->mrb)) {
		// TODO error handling
	}

	if (0 != jcls_init_class(context->mrb)) {
		// TODO error handling
	}

	if (0 != jmethod_init_class(context->mrb)) {
		// TODO error handling
	}

	if (0 != jthrowable_init_class(context->mrb)) {
		// TODO error handling
	}


	RClass *clsKern = mrb_class_get(context->mrb, "Object");
	
	if (NULL != clsKern)
	{
		//RProc * const proc = replace_mrb_func(context->mrb, clsKern, "require", jamruby_kernel_require);
		//if (NULL != proc) {
			//mrb_gc_mark(context->mrb, reinterpret_cast<RBasic*>(proc));
		//} else {
			mrb_define_module_function(context->mrb, clsKern, "require", jamruby_kernel_require, MRB_ARGS_REQ(1));
			
		//}
	}  
  
  mrb_mruby_thread_init(context->mrb);

  
  
  context->result = mrb_yield_with_class(mrb, mrb_obj_value(context->proc),
                                         context->argc, context->argv, mrb_nil_value(), mrb->object_class);
  context->alive = FALSE;
  
  using namespace org::jamruby;
  jamruby_context::unregister_context(context->mrb);
  gJvm->DetachCurrentThread();
  
  return NULL;
}
extern "C" {
static mrb_value
mrb_thread_init(mrb_state* mrb, mrb_value self) {
  mrb_value proc = mrb_nil_value();
  mrb_int argc;
  mrb_value* argv;
  mrb_get_args(mrb, "&*", &proc, &argv, &argc);
  if (!mrb_nil_p(proc) && MRB_PROC_CFUNC_P(mrb_proc_ptr(proc))) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "forking C defined block");
  }
  if (!mrb_nil_p(proc)) {
    int i, l;
    mrb_thread_context* context = (mrb_thread_context*) malloc(sizeof(mrb_thread_context));
    context->mrb_caller = mrb;
    context->mrb = mrb_open();
        
    migrate_all_symbols(mrb, context->mrb);
    context->proc = mrb_proc_new(mrb, mrb_proc_ptr(proc)->body.irep);
    context->proc->target_class = context->mrb->object_class;
    context->argc = argc;
    context->argv = (mrb_value*)calloc(sizeof (mrb_value), context->argc);
    context->result = mrb_nil_value();
    context->alive = TRUE;
    for (i = 0; i < context->argc; i++) {
      context->argv[i] = migrate_simple_value(mrb, argv[i], context->mrb);
    }

    {
      mrb_value gv = mrb_funcall(mrb, self, "global_variables", 0, NULL);
      l = RARRAY_LEN(gv);
      for (i = 0; i < l; i++) {
        mrb_int len;
        int ai = mrb_gc_arena_save(mrb);
        mrb_value k = mrb_ary_entry(gv, i);
        mrb_value o = mrb_gv_get(mrb, mrb_symbol(k));
        if (is_safe_migratable_simple_value(mrb, o, context->mrb)) {
          const char *p = mrb_sym2name_len(mrb, mrb_symbol(k), &len);
          mrb_gv_set(context->mrb,
            mrb_intern_static(context->mrb, p, len),
            migrate_simple_value(mrb, o, context->mrb));
        }
        mrb_gc_arena_restore(mrb, ai);
      }
    }

    mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "context"), mrb_obj_value(
      Data_Wrap_Struct(mrb, mrb->object_class,
      &mrb_thread_context_type, (void*) context)));

    pthread_create(&context->thread, NULL, &mrb_thread_func, (void*) context);
  }
  return self;
}
}
static mrb_value
mrb_thread_join(mrb_state* mrb, mrb_value self) {
  mrb_value value_context = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "context"));
  mrb_thread_context* context = NULL;
  Data_Get_Struct(mrb, value_context, &mrb_thread_context_type, context);
  pthread_join(context->thread, NULL);

  context->result = migrate_simple_value(mrb, context->result, mrb);
  mrb_close(context->mrb);
  context->mrb = NULL;
  return context->result;
}

static mrb_value
mrb_thread_kill(mrb_state* mrb, mrb_value self) {
  mrb_value value_context = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "context"));
  mrb_thread_context* context = NULL;
  Data_Get_Struct(mrb, value_context, &mrb_thread_context_type, context);
  if (context->mrb == NULL) {
    return mrb_nil_value();
  }
  pthread_kill(context->thread, SIGINT);
  mrb_close(context->mrb);
  context->mrb = NULL;
  return context->result;
}

static mrb_value
mrb_thread_alive(mrb_state* mrb, mrb_value self) {
  mrb_value value_context = mrb_iv_get(mrb, self, mrb_intern_lit(mrb, "context"));
  mrb_thread_context* context = NULL;
  Data_Get_Struct(mrb, value_context, &mrb_thread_context_type, context);

  return context->alive ? mrb_true_value() : mrb_false_value();
}

static mrb_value
mrb_thread_sleep(mrb_state* mrb, mrb_value self) {
  mrb_int t;
  mrb_get_args(mrb, "i", &t);
#ifndef _WIN32
  sleep(t);
#else
  Sleep(t * 1000);
#endif
  return mrb_nil_value();
}

static mrb_value
mrb_mutex_init(mrb_state* mrb, mrb_value self) {
  mrb_mutex_context* context = (mrb_mutex_context*) malloc(sizeof(mrb_mutex_context));
  pthread_mutex_init(&context->mutex, NULL);
  context->locked = FALSE;
  DATA_PTR(self) = context;
  DATA_TYPE(self) = &mrb_mutex_context_type;
  return self;
}

static mrb_value
mrb_mutex_lock(mrb_state* mrb, mrb_value self) {
  mrb_mutex_context* context =(mrb_mutex_context*)DATA_PTR(self);
  if (pthread_mutex_lock(&context->mutex) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot lock");
  }
  context->locked = TRUE;
  return mrb_nil_value();
}

static mrb_value
mrb_mutex_try_lock(mrb_state* mrb, mrb_value self) {
  mrb_mutex_context* context = (mrb_mutex_context*)DATA_PTR(self);
  if (pthread_mutex_trylock(&context->mutex) == 0) {
    context->locked = TRUE;
    return mrb_true_value();
  }
  return mrb_false_value();
}

static mrb_value
mrb_mutex_locked(mrb_state* mrb, mrb_value self) {
  mrb_mutex_context* context = (mrb_mutex_context*)DATA_PTR(self);
  return context->locked ? mrb_true_value() : mrb_false_value();
}

static mrb_value
mrb_mutex_unlock(mrb_state* mrb, mrb_value self) {
  mrb_mutex_context* context =(mrb_mutex_context*) DATA_PTR(self);
  if (pthread_mutex_unlock(&context->mutex) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot unlock");
  }
  context->locked = FALSE;
  return mrb_nil_value();
}

static mrb_value
mrb_mutex_sleep(mrb_state* mrb, mrb_value self) {
  mrb_int t;
  mrb_get_args(mrb, "i", &t);
#ifndef _WIN32
  sleep(t);
#else
  Sleep(t * 1000);
#endif
  return mrb_mutex_unlock(mrb, self);
}

static mrb_value
mrb_mutex_synchronize(mrb_state* mrb, mrb_value self) {
  mrb_value ret = mrb_nil_value();
  mrb_value proc = mrb_nil_value();
  mrb_get_args(mrb, "&", &proc);
  if (!mrb_nil_p(proc)) {
    mrb_mutex_lock(mrb, self);
    ret = mrb_yield_argv(mrb, proc, 0, NULL);
    mrb_mutex_unlock(mrb, self);
  }
  return ret;
}

static mrb_value
mrb_queue_init(mrb_state* mrb, mrb_value self) {
  mrb_queue_context* context = (mrb_queue_context*) malloc(sizeof(mrb_queue_context));
  pthread_mutex_init(&context->mutex, NULL);
  pthread_mutex_init(&context->queue_lock, NULL);
  if (pthread_mutex_lock(&context->queue_lock) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot lock");
  }
  context->mrb = mrb;
  context->queue = mrb_ary_new(mrb);
  mrb_iv_set(mrb, self, mrb_intern_lit(mrb, "queue"), context->queue);
  DATA_PTR(self) = context;
  DATA_TYPE(self) = &mrb_queue_context_type;
  return self;
}

static mrb_value
mrb_queue_lock(mrb_state* mrb, mrb_value self) {
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  if (pthread_mutex_lock(&context->mutex) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot lock");
  }
  return mrb_nil_value();
}


static mrb_value
mrb_queue_unlock(mrb_state* mrb, mrb_value self) {
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  if (pthread_mutex_unlock(&context->mutex) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot unlock");
  }
  return mrb_nil_value();
}

static mrb_value
mrb_queue_clear(mrb_state* mrb, mrb_value self) {
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  mrb_queue_lock(mrb, self);
  mrb_ary_clear(mrb, context->queue);
  mrb_queue_unlock(mrb, self);
  return mrb_nil_value();
}

static mrb_value
mrb_queue_push(mrb_state* mrb, mrb_value self) {
  mrb_value arg;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  mrb_queue_lock(mrb, self);
  mrb_get_args(mrb, "o", &arg);
  mrb_ary_push(context->mrb, context->queue, migrate_simple_value(mrb, arg, context->mrb));
  mrb_queue_unlock(mrb, self);
  if (pthread_mutex_unlock(&context->queue_lock) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot unlock");
  }
  return mrb_nil_value();
}

static mrb_value
mrb_queue_pop(mrb_state* mrb, mrb_value self) {
  mrb_value ret;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  int len;
  mrb_queue_lock(mrb, self);
  len = RARRAY_LEN(context->queue);
  mrb_queue_unlock(mrb, self);
  if (len == 0) {
    if (pthread_mutex_lock(&context->queue_lock) != 0) {
      mrb_raise(mrb, E_RUNTIME_ERROR, "cannot lock");
    }
  }
  mrb_queue_lock(mrb, self);
  ret = migrate_simple_value(context->mrb, mrb_ary_pop(context->mrb, context->queue), mrb);
  mrb_queue_unlock(mrb, self);
  return ret;
}

static mrb_value
mrb_queue_unshift(mrb_state* mrb, mrb_value self) {
  mrb_value arg;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  mrb_queue_lock(mrb, self);
  mrb_get_args(mrb, "o", &arg);
  mrb_ary_unshift(context->mrb, context->queue, migrate_simple_value(mrb, arg, context->mrb));
  mrb_queue_unlock(mrb, self);
  if (pthread_mutex_unlock(&context->queue_lock) != 0) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "cannot unlock");
  }
  return mrb_nil_value();
}

static mrb_value
mrb_queue_shift(mrb_state* mrb, mrb_value self) {
  mrb_value ret;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  int len;
  mrb_queue_lock(mrb, self);
  len = RARRAY_LEN(context->queue);
  mrb_queue_unlock(mrb, self);
  if (len == 0) {
    if (pthread_mutex_lock(&context->queue_lock) != 0) {
      mrb_raise(mrb, E_RUNTIME_ERROR, "cannot lock");
    }
  }
  mrb_queue_lock(mrb, self);
  ret = migrate_simple_value(context->mrb, mrb_ary_shift(context->mrb, context->queue), mrb);
  mrb_queue_unlock(mrb, self);
  return ret;
}

static mrb_value
mrb_queue_num_waiting(mrb_state* mrb, mrb_value self) {
  /* TODO: multiple waiting */
  return mrb_fixnum_value(0);
}

static mrb_value
mrb_queue_empty_p(mrb_state* mrb, mrb_value self) {
  mrb_bool ret;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  mrb_queue_lock(mrb, self);
  ret = RARRAY_LEN(context->queue) == 0;
  mrb_queue_unlock(mrb, self);
  return mrb_bool_value(ret);
}

static mrb_value
mrb_queue_size(mrb_state* mrb, mrb_value self) {
  mrb_int ret;
  mrb_queue_context* context = (mrb_queue_context*)DATA_PTR(self);
  mrb_queue_lock(mrb, self);
  ret = RARRAY_LEN(context->queue);
  mrb_queue_unlock(mrb, self);
  return mrb_fixnum_value(ret);
}
int z = -1;
mrb_value jam_foo(mrb_state* mrb, mrb_value self) {
	mrb_int i;
	mrb_get_args(mrb, "i", &i);
	LOGE("thread: %d", z);
	z++;
	return mrb_nil_value();
}


mrb_value jam_proxy(mrb_state* mrb, mrb_value self) {
	mrb_value path;
	mrb_value proc;
	
	mrb_get_args(mrb, "o&", &path, &proc);

    safe_jni::safe_local_ref<jclass> vclazz(getEnv(), findClass("org/jamruby/ext/ProcProxy"));
	if (!vclazz) {
		LOGE("PROXY: NO FIND CLASS");
	} else {
		
	  jmethodID m_proxy = getEnv()->GetStaticMethodID(vclazz.get(), "proxy", "(Ljava/lang/String;JLorg/jamruby/mruby/Value;)Ljava/lang/Object;");
	 
	  mrb_value const &value = proc;

	  safe_jni::safe_local_ref<jobject> val(getEnv(), create_value(getEnv(), value)); 
	 
	  // jint proxy = getEnv()->CallStaticIntMethod(vclazz.get(), m_proxy, getEnv()->NewStringUTF(mrb_string_value_ptr(mrb, path)), jlong(mrb), getEnv()->NewGlobalRef(val.get()));	
	  // mrb_value px = mrb_fixnum_value((int)proxy);
	  
	  jobject proxy = getEnv()->CallStaticObjectMethod(vclazz.get(), m_proxy, getEnv()->NewStringUTF(mrb_string_value_ptr(mrb, path)), jlong(mrb), getEnv()->NewGlobalRef(val.get()));	
	  
      jni_type_t const type = org::jamruby::get_return_type("(Ljava/lang/String;)Ljava/lang/Object;");
	  jvalue ret;
	  ret.l = proxy;
	  
	  // LOGE("HERE");
	  mrb_value px =  org::jamruby::convert_jvalue_to_mrb_value(mrb, getEnv(), type, ret);

	  mrb_iv_set(mrb, px, mrb_intern_lit(mrb, "@block"), proc);
	  // LOGE("HERE TOO");

	  return px;
	}
	
	return mrb_nil_value();
}


mrb_value jam_to_java(mrb_state* mrb, mrb_value self) {
	mrb_value ins;
	
	mrb_get_args(mrb, "o", &ins);

    safe_jni::safe_local_ref<jclass> vclazz(getEnv(), findClass("org/jamruby/ext/RubyObject"));
	  if (!vclazz) {
		  LOGE("to_java: NO FIND CLASS");
	  } else {
		
	  jmethodID m_create = getEnv()->GetStaticMethodID(vclazz.get(), "create", "(JLorg/jamruby/mruby/Value;)Lorg/jamruby/ext/RubyObject;");
	 
	  mrb_value const &value = ins;

	  safe_jni::safe_local_ref<jobject> val(getEnv(), create_value(getEnv(), value)); 
	 
	  jobject robject = getEnv()->CallStaticObjectMethod(vclazz.get(), m_create, jlong(mrb), getEnv()->NewGlobalRef(val.get()));	
	  
    jni_type_t const type = org::jamruby::get_return_type("()Lorg/jamruby/ext/RubyObject;");
	  jvalue ret;
	  ret.l = robject;
	  
	  // LOGE("HERE");
	  mrb_value ro =  org::jamruby::convert_jvalue_to_mrb_value(mrb, getEnv(), type, ret);

	  return ro;
	}
	
	return mrb_nil_value();
}

mrb_value jam_get_mrb(mrb_state* mrb, mrb_value self) {
  jlong ptr = jlong(mrb);
  
  jni_type_t const type = org::jamruby::get_return_type("()J");
  jvalue ret;
  ret.j = ptr;
  
  mrb_value ro =  org::jamruby::convert_jvalue_to_mrb_value(mrb, getEnv(), type, ret);

  return ro;  
}

void mrb_mruby_thread_init(mrb_state* mrb) {
  RClass *clsKern = mrb_class_get(mrb, "Object");
  mrb_define_method(mrb, clsKern, "proxy", jam_proxy, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, clsKern, "to_java", jam_to_java, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, clsKern, "__mrb_context__", jam_get_mrb, MRB_ARGS_NONE());  
  struct RClass *_class_thread, *_class_mutex, *_class_queue;

  _class_thread = mrb_define_class(mrb, "Thread", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_thread, MRB_TT_DATA);
  mrb_define_method(mrb, _class_thread, "initialize", mrb_thread_init, MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_thread, "join", mrb_thread_join, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_thread, "kill", mrb_thread_kill, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_thread, "terminate", mrb_thread_kill, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_thread, "alive?", mrb_thread_alive, MRB_ARGS_NONE());
  mrb_define_module_function(mrb, _class_thread, "sleep", mrb_thread_sleep, MRB_ARGS_REQ(1));
  mrb_define_module_function(mrb, _class_thread, "start", mrb_thread_init, MRB_ARGS_REQ(1));

  _class_mutex = mrb_define_class(mrb, "Mutex", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_mutex, MRB_TT_DATA);
  mrb_define_method(mrb, _class_mutex, "initialize", mrb_mutex_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_mutex, "lock", mrb_mutex_lock, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_mutex, "try_lock", mrb_mutex_try_lock, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_mutex, "locked?", mrb_mutex_locked, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_mutex, "sleep", mrb_mutex_sleep, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_mutex, "synchronize", mrb_mutex_synchronize, MRB_ARGS_REQ(1));
  mrb_define_method(mrb, _class_mutex, "unlock", mrb_mutex_unlock, MRB_ARGS_NONE());

  _class_queue = mrb_define_class(mrb, "Queue", mrb->object_class);
  MRB_SET_INSTANCE_TT(_class_queue, MRB_TT_DATA);
  mrb_define_method(mrb, _class_queue, "initialize", mrb_queue_init, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_queue, "clear", mrb_queue_clear, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_queue, "push", mrb_queue_push, MRB_ARGS_NONE());
  mrb_define_alias(mrb, _class_queue, "<<", "push");
  mrb_define_method(mrb, _class_queue, "unshift", mrb_queue_unshift, MRB_ARGS_NONE());
  mrb_define_alias(mrb, _class_queue, "enq", "unshift");
  mrb_define_method(mrb, _class_queue, "pop", mrb_queue_pop, MRB_ARGS_OPT(1));
  mrb_define_alias(mrb, _class_queue, "deq", "pop");
  mrb_define_method(mrb, _class_queue, "shift", mrb_queue_shift, MRB_ARGS_OPT(1));
  mrb_define_method(mrb, _class_queue, "size", mrb_queue_size, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_queue, "num_waiting", mrb_queue_num_waiting, MRB_ARGS_NONE());
  mrb_define_method(mrb, _class_queue, "empty?", mrb_queue_empty_p, MRB_ARGS_NONE());

  safe_jni::safe_local_ref<jclass> vclazz(getEnv(), findClass("org/jamruby/ext/JamActivity"));
	if (!vclazz) {
		LOGE("THREAD_INIT: NO FIND CLASS");
	} else {
		
	  jmethodID m_thread_init = getEnv()->GetStaticMethodID(vclazz.get(), "initThread", "(J)V");
	 
    getEnv()->CallStaticVoidMethod(vclazz.get(), m_thread_init, jlong(mrb));	
  }
}
