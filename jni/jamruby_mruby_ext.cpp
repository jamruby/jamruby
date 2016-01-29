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

	if (len > 3) {
		// if 'name' is end with ".rb", loading ruby script file.
		if (0 == strncmp(&str[len-3], ".rb", 3)) {
			// TODO call original 'Kernel.require' method.
			return mrb_nil_value();
		}
	}

	jamruby_context *context = jamruby_context::find_context(mrb);
	if (NULL == context) {
		LOGE("Context not found");
		mrb_raise(mrb, E_RUNTIME_ERROR, "jamruby context cannot found.");
		return mrb_nil_value(); // don't reach here
	}

	std::string const class_name = gen_java_class_name(str, len);


	safe_jni::safe_local_ref<jclass> cls(getEnv(), findClass(class_name.c_str()));
	if (!cls) {
		LOGE("class not in JVM");
		getEnv()->ExceptionClear();
		// TODO call original 'Kernel.require' method.
		mrb_raisef(mrb, E_NAME_ERROR, "class '%s' is not found in JVM.", str);
		return mrb_nil_value(); // don't reach here
	}

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
	LOGD("define class (%s::%s)\n", (NULL == parent) ? "" : mrb_string_value_ptr(mrb, mrb_class_path(mrb, parent)), name.c_str());

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
	safe_jni::method<jobjectArray> get_constructors(env, obj, "getConstructors", "()[Ljava/lang/reflect/Constructor;");
	if (!get_constructors) {
		env->ExceptionClear();
		LOGE("cannot find 'getConstructors()' method in JVM.");
		return NULL;
	}

	safe_jni::safe_local_ref<jobjectArray> rctors(env, get_constructors(obj));
	if (!rctors) {
		env->ExceptionClear();
		LOGE("cannot get public constructors.");
		return NULL;
	}
	safe_jni::safe_object_array ctors(env, rctors.get());
	size_t const num_of_ctors = ctors.size();

	// get public methods
	safe_jni::method<jobjectArray> get_methods(env, obj, "getMethods", "()[Ljava/lang/reflect/Method;");
	if (!get_methods) {
		env->ExceptionClear();
		LOGE("cannot find 'getMethods()' method in JVM.");
		return NULL;
	}

	safe_jni::safe_local_ref<jobjectArray> ret(env, get_methods(obj));
	if (!ret) {
		env->ExceptionClear();
		LOGE("cannot get public methods.");
		return NULL;
	}
	safe_jni::safe_object_array methods(env, ret.get());
	size_t const num_of_methods = methods.size();
	if (0 == num_of_methods) {
		LOGW("'%s' has no methods.", name.c_str());
		return NULL;
	}

	safe_jni::safe_local_ref<jclass> modifier_class(env, findClass("java/lang/reflect/Modifier"));
	if (!modifier_class) {
		LOGE("cannot find class 'java.lang.reflect.Modifier' in JVM.");
		return NULL;
	}
	safe_jni::method<bool> is_static(env, modifier_class.get(), "isStatic", "(I)Z");
	if (!is_static) {
		LOGE("cannot find method 'isStatic'.");
		return NULL;
	}

	safe_jni::safe_local_ref<jclass> method_signature_class(env, findClass("org/jamruby/java/MethodSignature"));
	if (!method_signature_class) {
		LOGE("cannot find class 'org.jamruby.java.MethodSignature' in JVM.");
		return NULL;
	}
	safe_jni::method<jstring> gen_method_signature(env, method_signature_class.get(), "genMethodSignature", "(Ljava/lang/reflect/Method;)Ljava/lang/String;");
	if (!gen_method_signature) {
		LOGE("cannot find method 'genMethodSignature'.");
		return NULL;
	}
	safe_jni::method<jstring> gen_ctor_signature(env, method_signature_class.get(), "genCtorSignature", "(Ljava/lang/reflect/Constructor;)Ljava/lang/String;");
	if (!gen_ctor_signature) {
		LOGE("cannot find method 'genCtorSignature'.");
		return NULL;
	}

	jamruby_context *context = jamruby_context::find_context(mrb);
	if (NULL == context) {
		LOGE("cannot find jamruby context.");
		return NULL;
	}

	jclass gref_cls = static_cast<jclass>(env->NewGlobalRef(cls));
	if (NULL == gref_cls) {
		LOGE("cannot create global reference.");
		return NULL;
	}

	context->register_jclass(target, gref_cls);

    mrb_value im = mrb_ary_new(mrb);
    mrb_value sm = mrb_ary_new(mrb);
    
	for (size_t i = 0; i < num_of_ctors; ++i) {
		safe_jni::safe_local_ref<jobject> c(env, ctors.get(i));
		safe_jni::safe_local_ref<jstring> js_signature(env, gen_ctor_signature(method_signature_class.get(), c.get()));
		safe_jni::safe_string signature(env, js_signature.get());
		context->register_ctor_signature(target, signature.string());
		LOGD("register constructor: <init>%s", signature.string());
	}

	for (size_t i = 0; i < num_of_methods; ++i) {
		safe_jni::safe_local_ref<jobject> m(env, methods.get(i));
		safe_jni::method<jstring> get_name(env, m.get(), "getName", "()Ljava/lang/String;");
		safe_jni::safe_local_ref<jstring> mname(env, get_name(m.get()));
		safe_jni::safe_string mname_str(env, mname.get());

		safe_jni::safe_local_ref<jstring> js_signature(env, gen_method_signature(method_signature_class.get(), m.get()));
		safe_jni::safe_string signature(env, js_signature.get());

		safe_jni::method<int> get_modifiers(env, m.get(), "getModifiers", "()I");
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

			LOGD("define class method '%s::%s : %s'.", name.c_str(), mname_str.string(), signature.string());
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

			LOGD("define instance method '%s.%s : %s'.", name.c_str(), mname_str.string(), signature.string());
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




mrb_value java_find_class(mrb_state *mrb, mrb_value self)
{
	if (NULL == getEnv()) {
		LOGE("null environment.");
		return mrb_nil_value();
	}

	mrb_value class_name;
	int argc = mrb_get_args(mrb, "o", &class_name);

	if (1 != argc) {
		LOGE("invalid argument (argc = %d, %s).", argc, mrb_string_value_ptr(mrb, class_name));
		return mrb_nil_value();
	}

	getEnv()->ExceptionClear();

	return jcls_make(mrb,getEnv(), mrb_string_value_ptr(mrb, class_name));
}

int jam_thread = 0;

// mattn/mruby-thread
static mrb_sym
migrate_sym(mrb_state *mrb, mrb_sym sym, mrb_state *mrb2)
{
  mrb_int len;
  const char *p = mrb_sym2name_len(mrb, sym, &len);
  return mrb_intern_static(mrb2, p, len);
}

// mattn/mruby-thread
static void
migrate_all_symbols(mrb_state *mrb, mrb_state *mrb2)
{
  mrb_sym i;
  for (i = 1; i < mrb->symidx + 1; i++) {
    migrate_sym(mrb, i, mrb2);
  }
}

mrb_value jam_transfer_proc(mrb_state* parent, mrb_value proc, mrb_state* child) {
  
  RProc* fun = mrb_proc_new(parent, mrb_proc_ptr(proc)->body.irep);
  
  fun->target_class = child->object_class;  
  
  return mrb_obj_value(fun);
}

mrb_value jam_rbobj_to_value(mrb_state* mrb, mrb_value self) {
		jobject jobj = jobject_get_jobject(mrb, self);
	  mrb_value val;
	  if (!create_mrb_value(getEnv(), jobj, val)) {
	  	return mrb_nil_value();
	  }  
    return val;    
}

mrb_value jam_call(mrb_state* mrb, mrb_value fun) {
  mrb_value ary;
  mrb_get_args(mrb, "o", &ary);
  
  mrb_value i = mrb_funcall(mrb, ary, "length", 0);
  int argc = mrb_int(mrb, i);
  
  mrb_value* argv = (mrb_value*)calloc(sizeof (mrb_value), argc);
  
  for (int x=0; x < argc; x++) {
    argv[x] = mrb_funcall(mrb, ary, "[]", 1, mrb_fixnum_value(x));
  }  

  return mrb_yield_with_class(mrb, fun,
                                         argc, argv, mrb_nil_value(), mrb->object_class);  
}

mrb_value mrb_jam_thread_init(mrb_state* parent, mrb_value ary, mrb_value proc, mrb_state* child) {
  jam_thread = 1;
    
  migrate_all_symbols(parent, child);    
    
  mrb_value fun = jam_transfer_proc(parent, proc, child);

  jam_init_base(child, 0); 

  return mrb_funcall(child, fun, "__jam_call__", 1, ary);
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

    jobject proxy = getEnv()->CallStaticObjectMethod(vclazz.get(), m_proxy, getEnv()->NewStringUTF(mrb_string_value_ptr(mrb, path)), jlong(mrb), getEnv()->NewGlobalRef(val.get()));	

    jni_type_t const type = org::jamruby::get_return_type("(Ljava/lang/String;)Ljava/lang/Object;");
    jvalue ret;
    ret.l = proxy;

    mrb_value px =  org::jamruby::convert_jvalue_to_mrb_value(mrb, getEnv(), type, ret);

    mrb_iv_set(mrb, px, mrb_intern_lit(mrb, "@block"), proc);

    return px;
  }
	
	return mrb_nil_value();
}


mrb_value jam_to_java(mrb_state* mrb, mrb_value self) {
	mrb_value ins;
  
	mrb_get_args(mrb, "o", &ins);

  safe_jni::safe_local_ref<jclass> vclazz(getEnv(), findClass("org/jamruby/mruby/Value"));
	  
  if (!vclazz) {
    LOGE("to_java: NO FIND CLASS");
  } else {
    
    mrb_value const &value = ins;
    jni_type_t const type = org::jamruby::get_return_type("()Lorg/jamruby/mruby/Value;");
    jvalue ret;
    ret.l = create_value(getEnv(), value);
    
    mrb_value ro =  org::jamruby::convert_jvalue_to_mrb_value(mrb, getEnv(), type, ret);

    return ro;
	}
	
	return mrb_nil_value();
}

mrb_value jam_get_mrb_with_context(mrb_state* context, mrb_state* mrb) {
  jlong ptr = jlong(mrb);
  
  jni_type_t const type = org::jamruby::get_return_type("()J");
  jvalue ret;
  ret.j = ptr;
  
  return org::jamruby::convert_jvalue_to_mrb_value(context, getEnv(), type, ret);  
}

mrb_value jam_get_mrb(mrb_state* mrb, mrb_value self) {
  return jam_get_mrb_with_context(mrb, mrb);  
}

mrb_value jam_eval(mrb_state* mrb, mrb_value self) {
  mrb_value result;
  mrb_value code;
  
  mrb_get_args(mrb, "o", &code);
  
  result = mrb_load_string(mrb, mrb_string_value_ptr(mrb, code));
  
  return result;
}

void jam_init_base(mrb_state* mrb, jlong threadId) {
  using namespace org::jamruby;
	jamruby_context *context = jamruby_context::register_context(mrb, getEnv());
	if (NULL == context) {
		LOGE("cannot register jamruby context.");
		return;
	}

	RClass *mod_jni = mrb_define_module(mrb, "JAVA");
	mrb_define_const(mrb, mod_jni, "JAVA_THREAD_ID", mrb_fixnum_value(threadId));
	mrb_define_module_function(mrb, mod_jni, "find_class", java_find_class, MRB_ARGS_REQ(1));

	if (0 != jobject_init_class(mrb)) {
		// TODO error handling
	}

	if (0 != jcls_init_class(mrb)) {
		// TODO error handling
	}

	if (0 != jmethod_init_class(mrb)) {
		// TODO error handling
	}

	if (0 != jthrowable_init_class(mrb)) {
		// TODO error handling
	}

	RClass *clsKern = mrb_class_get(mrb, "Object");
	if (NULL != clsKern)
	{
		RProc * const proc = replace_mrb_func(mrb, clsKern, "require", jamruby_kernel_require);
		if (NULL != proc) {
			mrb_gc_mark(mrb, reinterpret_cast<RBasic*>(proc));
		} else {
			mrb_define_module_function(mrb, clsKern, "require", jamruby_kernel_require, MRB_ARGS_REQ(1));
		}
    

    mrb_define_method(mrb, clsKern, "__jam_call__", jam_call, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, clsKern, "__from_java__", jam_rbobj_to_value, MRB_ARGS_NONE());
    mrb_define_method(mrb, clsKern, "proxy", jam_proxy, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, clsKern, "_to_java_", jam_to_java, MRB_ARGS_REQ(1));
    mrb_define_method(mrb, clsKern, "__eval__", jam_eval, MRB_ARGS_REQ(1));  
    mrb_define_method(mrb, clsKern, "__mrb_context__", jam_get_mrb, MRB_ARGS_NONE());     
	}
}

