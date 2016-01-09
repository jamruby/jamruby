#ifndef JAMRUBY_MRUBY_EXT_H
#define JAMRUBY_MRUBY_EXT_H
#include "jni_load.h"
#include "safe_jni.hpp"
#include "jni_type_conversion.hpp"
#include "jni_common.hpp"
#ifdef __cplusplus
extern "C" {
#endif

#include "mruby.h"

extern mrb_value jamruby_kernel_require(mrb_state *mrb, mrb_value self);
void mrb_mruby_thread_init(mrb_state* mrb);
mrb_value java_find_class(mrb_state *mrb, mrb_value self);

#ifdef __cplusplus
}
#endif

#endif // end of JAMRUBY_MRUBY_EXT_H

