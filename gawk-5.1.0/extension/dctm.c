/*
 * dctm.c - Builtin functions that provide an interface to Documentum dmapp.h;
 * see dmapp.h for description of functions; 
 *
 * Cesare Cervini
 * dbi-services.com
 * 5/2018
 * reviewed 11/2021 for gawk 5.1.0;
 * go to .libs and and link dmcl.o it with the Documentum library with: gcc -o dctm.so -shared dctm.o path-to-the-shared-library/libdmcl40.so;
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
 
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
 
#include <sys/types.h>
#include <sys/stat.h>
 
#include "gawkapi.h"
 
#include "gettext.h"
#define _(msgid)  gettext(msgid)
#define N_(msgid) msgid
 
/* make it point to the Documentum dmapp.h on your system */
#include "dmapp.h"
 
static const gawk_api_t *api;   /* for convenience macros to work */
static awk_ext_id_t ext_id;
static const char *ext_version = "dctm extension: version 1.1";
//static awk_bool_t (*init_func)(void) = NULL;
 
int plugin_is_GPL_compatible;
 
/*  do_dmAPIInit */
//static awk_value_t *
//do_dmAPIInit(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
// no longer exported, called automatically at load time;
static awk_bool_t *
do_dmAPIInit(void) {
   unsigned int ret = 0;
 
   ret = dmAPIInit();
   ret &= 0xff;
 
   if (!ret)
      printf("error in do_dmAPIInit()\n");
}
 
/*  do_dmAPIDeInit */
static awk_value_t *
do_dmAPIDeInit(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   unsigned int ret = 0;
 
   assert(result != NULL);
 
   ret = dmAPIDeInit();
   ret &= 0xff;
 
   return make_number(ret, result);
}
 
/*  do_dmAPIExec */
static awk_value_t *
do_dmAPIExec(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   awk_value_t str;
   unsigned int ret = 0;
 
   assert(result != NULL);
 
   if (get_argument(0, AWK_STRING, & str)) {
      ret = dmAPIExec(str.str_value.str);
      ret &= 0xff;
   } else if (do_lint)
      lintwarn(ext_id, _("dmAPIExec: called with inappropriate argument(s)"));
 
   return make_number(ret, result);
}
 
/*  do_dmAPIGet */
static awk_value_t *
do_dmAPIGet(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   awk_value_t str;
   char *got_value = NULL;
 
   assert(result != NULL);
 
   if (get_argument(0, AWK_STRING, &str)) {
      got_value = dmAPIGet(str.str_value.str);
   } else if (do_lint)
      lintwarn(ext_id, _("dmAPIGet: called with inappropriate argument(s)"));
 
   if (got_value)
      make_const_string(got_value, strlen(got_value), result);
   else
      make_const_string("", 0, result);

   return result;
}
 
/*  do_dmAPISet */
static awk_value_t *
do_dmAPISet(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   awk_value_t str1;
   awk_value_t str2;
   unsigned int ret = 0;
 
   assert(result != NULL);
 
   if (get_argument(0, AWK_STRING, & str1) && get_argument(1, AWK_STRING, & str2)) {
      ret = dmAPISet(str1.str_value.str, str2.str_value.str);
      ret &= 0xff;
   } else if (do_lint)
      lintwarn(ext_id, _("dmAPISet: called with inappropriate argument(s)"));
 
   return make_number(ret, result);
}
 
/* do_dmGetPassword */
static awk_value_t *
do_dmGetPassword(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   awk_value_t prompt;
   char *password = NULL;

   assert(result != NULL);


   if (get_argument(0, AWK_STRING, &prompt))
      password = getpass(prompt.str_value.str);
   else
      password = getpass("");

  if (password)
     make_const_string(password, strlen(password), result);
  else
     make_const_string("", 0, result);

   return result;
}

static awk_bool_t (*init_func)(void) = do_dmAPIInit;

/* these are the exported functions along with their min and max arities; */
/* dmAPIInit is no longer user-callable; */
/* { "dmAPIInit",   do_dmAPIInit, 0, 0, awk_false, NULL }, */
static awk_ext_func_t func_table[] = {
    {"dmAPIDeInit",   do_dmAPIDeInit,   0, 0, awk_false, NULL},
    {"dmAPIExec",     do_dmAPIExec,     1, 1, awk_false, NULL},
    {"dmAPIGet",      do_dmAPIGet,      1, 1, awk_false, NULL},
    {"dmAPISet",      do_dmAPISet,      2, 2, awk_false, NULL},
    {"dmGetPassword", do_dmGetPassword, 1, 0, awk_false, NULL},
};
 
/* define the dl_load function using the boilerplate macro */
 
dl_load_func(func_table, dctm, "")

