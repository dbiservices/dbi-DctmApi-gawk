/*
 * gexec.c - provide an interface to execl() for gawk;
 *
 * Cesare Cervini, dbi-services.com, 11/2021 for gawk 5.1.0;
 * go to .libs and and link gexec.o it with ;
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
 
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
 
#include <sys/types.h>
#include <sys/stat.h>
 
#include "gawkapi.h"

static const gawk_api_t *api;   /* for convenience macros to work */
static awk_ext_id_t ext_id;
static const char *ext_version = "dctm extension: version 1.0";
 
int plugin_is_GPL_compatible;
 
/* do_exec() */
/*
interface to execl() function for gawk;
usage from gawk:
   exec(program, param1, param2, ...)
does not return if successful;
return errno if an error occurred;
*/
static awk_value_t *
do_exec(int nargs, awk_value_t *result, struct awk_ext_func *unused) {
   awk_value_t exec_name;
   awk_value_t param;
   unsigned int ret;

   assert(result != NULL);

   if (!get_argument(0, AWK_STRING, &exec_name)) {
      fprintf(stderr, "cannot get parameter 0, i.e. the executable name\n");
      return 0;
   }

   char *params[nargs + 1];
   params[0] = exec_name.str_value.str;
   for (unsigned int i = 1; i < nargs; i++) {
      if (!get_argument(i, AWK_STRING, &param)) {
         fprintf(stderr, "cannot get i-th parameter\n");
         return 0;
      }
      params[i] = param.str_value.str;
   }
   params[nargs] = NULL;

//printf("cmd is %s\n", cmd);

   ret = execv(exec_name.str_value.str, params);
//fprintf(stderr, "ret = %d, errno=%d\n", ret, errno);
   return make_number(-1 == ret ? errno : 0, result);
}

static awk_bool_t (*init_func)(void) = NULL;

/* these are the exported functions along with their min and max arities; */
static awk_ext_func_t func_table[] = {
    {"exec",   do_exec,   0, 1, awk_true, NULL},
};

/* define the dl_load function using the boilerplate macro */

dl_load_func(func_table, exec, "")


