@load "dctm"
@load "gexec"

# provides high-level function to do Documentum stuff;
# set environment variable $DOCUMENTUM to where the dmcl.ini file is and $LD_LIBRARY_PATH to the location of libdmcl40.so;
# this library file is made available to gawk scripts by @include-ing in it;
# the environment variable AWKPATH can be set to the path containing the included awk sources;
# 5/2018, Cesare Cervini@dbi-services.com;
#  creation;
# 11/2021, Cesare Cervini@dbi-services.com, modified with dctm.c for gawk 5.1.0;
#  added dmSelecta(), renamed dmSelect to dmSelecto()
#  added dmSelect() and dmNext();
#  added syntax repo:docbroker:docbroker_port so docbroker.host and docbroker.port in dfc.properties are not used;
#  better logging;
#
# to be able to use the syntax repo:docbroker_host:docbroker_port, follow the instructions below:
#    cd /home/dmadmin/D
#    a custom dfc.properties file must be prepared in current directory, say in directory /home/dmadmin/D;
#    create one by copying an existing file:
#       cp /app/dctm/config/dfc.properties . 
#    remove the dfc.docbroker.* entries, keep the other pertinent settings;
#       sed ... dfc.properties;
#    export DM_JAVA_CONFIG=/home/dmadmin/D/java.ini
#    copy the official java.ini file:
#       cp /app/dctm/product/16.4/bin/java.ini .
#    edit the java.ini and replace the config path from the java_classpath parameter with the directory above, e.g.:
#       before:
#          java_classpath = /app/dctm/product/16.4/dctm-server.jar:/app/dctm/dctm.jar:/app/dctm/config:/app/dctm/java64/JAVA_LINK/jre/lib
#       after:
#          java_classpath = /app/dctm/product/16.4/dctm-server.jar:/app/dctm/dctm.jar:/home/dmadmin/D:/app/dctm/java64/JAVA_LINK/jre/lib
#    avoid errors about missing log4j file by copying its properties file locally:
#       cp /app/dctm/config/log4j.properties /home/dmadmin/D/.

# verbosity is turned off by default;
# turn it on in the client;
dmLogLevel = 0
 
function dmShow(mesg) {
# display the message msg if dmLogLevel is set;
# also, get the error message from the API;
   if (dmLogLevel > 0) {
      print mesg
      while (mesg = dmAPIGet("getmessage,c"))
         print mesg
   } 
}
 
function dmConnect2(docbase, user_name, password          , session, status, repo, docbroker_host, docbroker_port) {
# connects to given docbase as user_name/password;
# docbase syntax:
#   name[:docker_host[:docbroker_port]]
# if a docbroker_host is given, the docbroker hosts specified in the dfc.properties file are no longer necessary and can even be removed;
# this extension permits to access any docbase with the same name or id;
# we apply the trick here: https://blog.dbi-services.com/connecting-to-a-repository-via-a-dynamically-edited-dfc-properties-file-part-i/ but we access the dfc.properties in 
# $DFC_CONFIG_FILE_FULLPATH so make sure it exists;
# also, as all dfc.docbroker.* keys are removed, make sure a backup exists beforehand;
# it is the responsability of the user to make sure that the underlying DFCs really access $DFC_CONFIG_FILE and not the default one, see KB7794243 "How to specify a different dfc.properties with IAPI on a Linux server";
# if the default DFCs installation is preferred, i.e. no changes to the $DM_HOME/bin/java.ini is wanted, the easiest is to:
#    export DFC_CONFIG_FILE_FULLPATH=....
#    cp /app/dctm/product/16.4/../../config/dfc.properties $DFC_CONFIG_FILE_FULLPATH/.
#    mv /app/dctm/product/16.4/../../config/dfc.properties /app/dctm/product/16.4/../../config/dfc.properties_original
#    ln -s $DFC_CONFIG_FILE_FULLPATH /app/dctm/product/16.4/../../config/dfc.properties
# once the dfc.properties file is edited, an exec() call replaces the current process with the same command that started it, so it reloads the new dfc.properties file;
# the gawk extension exec() is used instead of system() to prevent process cluttering;
# returns a session id if OK, an empty string otherwise;
   dmShow("in dmConnect(), docbase = " docbase ", user_name = " user_name ", password = " password)

   if (!match(docbase, /^([^:]+)(:([^:]+)(:([0-9]+))?)?$/, m)) {
      dmShow("Invalid repository specification")
      dmShow("aborting dmConnect()")
      session = ""
   }
   else if (!m[2])
      session = dmAPIGet("connect," docbase "," user_name "," password)
   else {
        repo = m[1]
        docbroker_host = m[3]
        docbroker_port = m[5] ? m[5] : "1489"
        # remove existing dfc.docbroker.* settings, append the new ones for the taget repository;
        status = system("sed -i -e '$adfc.docbroker.host[0]=" docbroker_host "' -e '$adfc.docbroker.port[0]=" docbroker_port "' -e '/dfc.docbroker/d' " ENVIRON["DFC_CONFIG_FILE_FULLPATH"])
      if (status) {
         dmShow("Error while pointing to docbroker " docbroker_host ":" docbroker_port)
         dmShow("aborting dmConnect()")
         session = ""
      }
      exec("/home/dmadmin/project/blogs/blog_gawk_extension/gawk-5.1.0/gawk", "-f", "/home/dmadmin/project/blogs/dmftp/dmftp.awk", "-v", "docbase=" repo, "-v", "user_name=" user_name, "-v", "password=" password, "-v", "pid=" PROCINFO["pid"], "-v", "ppid=" PROCINFO["ppid"])
   }
   if (!session) {
      dmShow("unsuccessful connection to docbase " docbase " as user " user_name)
      dmShow("aborting dmConnect()")
   }
   else {
      dmShow("successful session " session " to " docbase)
      dmShow("exiting dmConnect()")
   }
   return session
}
 
function dmConnect(docbase, user_name, password          , session, status, repo, docbroker_host, docbroker_port) {
# connects to given docbase as user_name/password;
# docbase syntax:
#   name[:docker_host[:docbroker_port]]
# if a docbroker_host is given, the docbroker hosts specified in the dfc.properties file are no longer necessary and can even be removed;
# this extension permits to access any docbase with the same name or id;
# we apply the trick here: https://blog.dbi-services.com/connecting-to-repositories-with-the-same-name-and-or-id/
# returns a session id if OK, an empty string otherwise;
   dmShow("in dmConnect(), docbase = " docbase ", user_name = " user_name ", password = " password)

   if (!match(docbase, /^([^:]+)(:([^:]+)(:([0-9]+))?)?$/, m)) {
      dmShow("Invalid repository specification")
      dmShow("aborting dmConnect()")
      session = ""
   }
   else if (!m[2])
      session = dmAPIGet("connect," docbase "," user_name "," password)
   else {
      repo = m[1]
      docbroker_host = m[3]
      docbroker_port = m[5] ? m[5] : "1489"
      dmAPISet("set,a,apiconfig,dfc.docbroker.host[0]", docbroker_host)
      dmAPISet("set,a,apiconfig,dfc.docbroker.port[0]", docbroker_port)
      nb_values = dmAPIGet("values,a,apiconfig,dfc.docbroker.host")
      # iapi truncate is not allowed against apiconfig; must force the unused settings to an empty value;
      for (i = 1; i < nb_values; i++) {
         dmAPISet("set,a,apiconfig,dfc.docbroker.host[" i "]",     "")
         dmAPISet("set,a,apiconfig,dfc.docbroker.port[" i "]",     "")
         dmAPISet("set,a,apiconfig,dfc.docbroker.protocol[" i "]", "")
         dmAPISet("set,a,apiconfig,dfc.docbroker.service[" i "]",  "")
         dmAPISet("set,a,apiconfig,dfc.docbroker.timeout[" i "]",  "")
      }
      session = dmAPIGet("connect," repo "," user_name "," password)
   } 
   if (!session) {
      dmShow("unsuccessful connection to docbase " docbase " as user " user_name)
      dmShow("aborting dmConnect()")
   }
   else {
      dmShow("successful session " session " to " docbase)
      dmShow("exiting dmConnect()")
   }
   return session
}
 
function dmExecute(session, dql_stmt   , query_id, exit_status) {
# execute non-SELECT DQL statements;
# returns 1 if OK, 0 otherwise;
   dmShow("in dmExecute(), dql_stmt=" dql_stmt)

   exit_status = 1
   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error calling query in dmExecute()")
      dmShow("aborting dmExecute()")
      exit_status = 0
   }
   if (!dmAPIExec("close," session "," query_id)) {
      dmShow("Error calling close in dmExecute()")
   }
   dmShow("exiting dmExecute()")
   return exit_status
}
 
function dmSelect(session, dql_stmt, metadata         , query_id) {
# execute the DQL SELECT statement passed in dql_stmt;
# also return the metadata of the result set obtained from a call to get_metadata(), see that function;
# use dmNext() to iterate through the result set and dmClose() to close the query;
# return the query's id if OK, or an empty string in case of error;
   dmShow("in dmSelect(), dql_stmt=" dql_stmt)

   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error in dmSelect()")
      dmShow("aborting dmSelect()")
   }

   if (!get_metadata(session, query_id, metadata)) {
      dmShow("aborting dmSelect()")
      return ""
   }

   dmShow("exiting dmSelect()")
   return query_id
}

function dmNext(session, query_id, result, metadata        , nb_attrs, i, count, j, value) {
# execute the DQL SELECT statement passed in dql_stmt and return the next row if the result set into the array result;
# if the metadata array is empty or missing, it gets filled with same the structure as that returned by dmSelect() and is accessible by the caller;
# result[0..n] contain the attributes' values, or arrays of values if the attributes are repeating;
# return 1 if OK, 0 in case of error or attempt to fetch past the end of the result set;
   dmShow("in dmNext(), query_id =" query_id)

   if (!metadata["nb_cols"]) {
      if (!get_metadata(session, query_id, metadata)) {
         dmShow("aborting dmNext()")
         return 0
      }
   }

   if (dmAPIExec("next," session "," query_id) > 0) {
      for (i = 0; i < metadata["nb_cols"]; i++) {
         if (metadata["is_repeating"][i]) {
            # multi-valued attributes;
            count = dmAPIGet("values," session "," query_id "," metadata["col_name"][i])
            if (NULL == count) {
               dmShow("error in dmNext() while getting the arity of attribute " metadata["col_name"][i] ": ")
               dmShow("aborting dmNext()")
               return 0
            }
            count += 0

            for (j = 0; j < count; j++) {
               value = dmAPIGet("get," session "," query_id "," metadata["col_name"][i] "[" j "]")
               gsub(/[[:blank:]]+$/, "", value)
               result[i][j] = value
            }
         }
         else {
            # mono-valued attributes;
            value = dmAPIGet("get," session "," query_id "," metadata["col_name"][i])
            gsub(/[[:blank:]]+$/, "", value)
            result[i] = value
         }
      }
   }
   # here, either next attempted to go past the end of the result set or an error occurred;
   # the former is OK and means the result set has been completely iterated through; the second is an error;
   # unfortunately, there is no way to tell these 2 situations apart and we must return an error condition in both cases in order to prevent an endless loop in the caller;
   else
      return 0

   dmShow("exiting dmNext()")
   return 1
}

# get the metadata of the query's result set:
# metadata["nb_cols"]                               : the number of columns, i.e. length(result["metadata"]["col_name"]);
# metadata["col_name"][0..n]                        : the column names;
# metadata["is_repeating"][0..n]                    : the length of the column's value;
# metadata["max_nb_repeating"][0..nb_cols - 1]      : the maximum number of repeating values for each column;
# metadata["max_col_length"][0..nb_cols - 1]        : the maximum length of the column's value or values if the attribute is repeating;
# metadata["max_length"]                            : the maximum of the largest column values, i.e. max(result["metadata"]["max_col_length"][0..n]);
# metadata["max_concat_col_length"][0..nb_cols - 1] : the maximum length of the column's value or concatenated values if the attribute is repeating;
#                                                     = metadata["max_col_length"][0..nb_cols - 1] if there are no repeating values or just one;
# metadata["max_concat_length"]                     : the maximum of the largest column values, i.e. max(metadata["max_concat_col_length"][0..nb_cols]);
#                                                     = metadata["max_length"] if there are no repeating values or just one; 
# metadata["total_max_length"]                      : the sum of the maximum length of all the column values, i.e. sum(metadata["max_concat_col_length"][0..nb_cols]);
# metadata["nb_rows"]                               : the number or rows in the result set, -1 at this point as it is unknown yet;
# return the number of columns if OK, 0 if not;
function get_metadata(session, query_id, metadata     , nb_attrs, i) {
   dmShow("in get_metadata(), session=" session ", query_id=" query_id)

   delete metadata
   nb_attrs = dmAPIGet("count," session "," query_id)
   if (NULL == nb_attrs) {
      dmShow("Error in get_metadata() while retrieving the count of returned attributes")
      dmShow("aborting get_metadata()")
      return 0
   }
   nb_attrs += 0
   metadata["nb_cols"] = nb_attrs

   for (i = 0; i < nb_attrs; i++) {
      # get the attributes' names;
      metadata["col_name"][i] = dmAPIGet("get," session "," query_id ",_names[" i "]")
      if (NULL == metadata["col_name"][i]) {
         dmShow("error in get_metadata() while getting the attribute name at position " i ": ")
         dmShow("aborting get_metadata()")
         return 0
      }

      metadata["is_repeating"][i] = dmAPIGet("repeating," session "," query_id "," metadata["col_name"][i])
      if (NULL == metadata["is_repeating"][i]) {
         dmShow("error in get_metadata() while getting the arity of attribute " metadata["col_name"][i] ": ")
         dmShow("aborting get_metadata()")
         return 0
      }
      metadata["is_repeating"][i] += 0

      # initialize the max column lengths with the length of the column name, i.e. header; cannot be narrower than the column header;
      metadata["max_col_length"][i]        = length(metadata["col_name"][i])
      metadata["max_length"]               = max(metadata["max_length"], metadata["max_col_length"][i])
      metadata["max_concat_col_length"][i] = metadata["max_col_length"][i]
      metadata["max_concat_length"]        = metadata["max_length"]

      result["metadata"]["max_nb_repeating"][i] = 0

      metadata["total_max_length"] += metadata["max_col_length"][i]
   }

   metadata["total_length"] = 0
   metadata["nb_rows"] = -1

   dmShow("exiting get_metadata()")
   return nb_attrs
}

function dmClose(session, query_id) {
# close the query query_id in session session;
# returns 0 if OK, -1 if not;
   dmShow("in dmClose()")

   if (!dmAPIExec("close," session "," query_id)) {
      dmShow("Error in dmClose()")
      dmShow("aborting dmClose()")
      return -1
   }
   dmShow("exiting dmClose()")
   return 0
}

function dmSelecto(session, dql_stmt        , metadata, row , query_id, s, i, count, value, j) {
# execute the DQL SELECT statement passed in dql_stmt and outputs the result to stdout (hence the "o" in dmSelecto);
# attributes_names is a comma-separated list of mono-valued attributes to extract from the result set;
# return the number of rows in the result set if OK, -1 otherwise;
   dmShow("in dmSelecto(), dql_stmt=" dql_stmt)

   query_id = dmSelect(session, dql_stmt, metadata)
   if (!query_id) {
      dmShow("Error calling dmSelect() in dmSelecto()")
      dmShow("aborting dmSelecto()")
      return -1 
   }

   # print header line;
   s = ""
   for (i = 0; i < metadata["nb_cols"]; i++)
      s = s (i > 0 ? "\t" : "") metadata["col_name"][i]
   print s

   count = 0
   while (dmNext(session, query_id, row, metadata)) {
      s = ""
      for (i = 0; i < metadata["nb_cols"]; i++) {
         value = ""
         if (!metadata["is_repeating"][i])
            value = row[i]
         else
            for (j = 0; j < length(row[i]); j++)
               value = value (j > 0 ? "|" : "") row[i][j]
         s = s (i > 0 ? "\t" : "") value
      }
      count += 1
      printf("%d: %s\n", count, s)
   }
   printf("%d rows iterated\n", count)
 
   if (!dmAPIExec("close," session "," query_id)) {
      dmShow("Error calling close in dmSelecto()")
      dmShow("aborting dmSelecto()")
      return -1
   }
 
   dmShow("exiting dmSelecto()")
   return count
}
 
function dmSelecta(session, dql_stmt, result       , query_id, row_counter, tot_length, i, count, max_v_length, tot_col_length, v_length, j, value) {
# execute the DQL SELECT statement passed in dql_stmt and return the result set into the 2D array result (hence the "a" in dmSelecta but the name can also be interpreted as "select all at once");
# result["metadata"]["nb_cols"]                        : the number of columns, i.e. length(result["metadata"]["col_name"]);
# result["metadata"]["col_name"][0..nb_cols - 1]       : the column names;
# result["metadata"]["is_repeating"][0..nb_cols - 1]   : the length of the column's value;
# result["metadata"]["max_nb_repeating"][0..nb_cols - 1]   : the maximum number of repeating values for each column;
# result["metadata"]["max_col_length"][0..nb_cols - 1] : the maximum length of the column's value or values if the attribute is repeating;
# result["metadata"]["max_length"]                     : the maximum of the largest column values, i.e. max(result["metadata"]["max_col_length"][0..nb_cols - 1])
# result["metadata"]["max_concat_col_length"][0..nb_cols - 1] : the maximum length of the column's value or concatenated values if the attribute is repeating;
#                                                               = result["metadata"]["max_col_length"][0..nb_cols - 1] if there are no repeating values or just one;
# result["metadata"]["max_concat_length"]                     : the maximum of the largest column values, i.e. max(result["metadata"]["max_concat_col_length"][0..nb_cols - 1])
#                                                               = result["metadata"]["max_length"] if there are no repeating values or just one; 
# result["metadata"]["nb_rows"]                        : the number or rows in the result set;
# result["data"][0..nb_rows - 1]                       : the result set, an array of repeating values if the attribute is repeating;
# columns lengths are only used to output the data into a nicely formatted table;
# returns -1 in case of error, the number of rows in the result set if successful;
   dmShow("in dmSelecta(), dql_stmt=" dql_stmt)

   # type forcing hack: result has not type yet, nor has result["metadata"], so it defaults to scalar; force it to an array (of array);
   result["metadata"]["nb_cols"] = 0
   query_id = dmSelect(session, dql_stmt, result["metadata"])
   if (!query_id) {
      dmShow("Error calling dmSelect() in dmSelecta()")
      dmShow("aborting dmSelecta()")
      return -1
   }
 
   # iterate through the result set;
   row_counter = 0 
   while (dmAPIExec("next," session "," query_id) > 0) {
      tot_length = 0
      for (i = 0; i < result["metadata"]["nb_cols"]; i++) {
         if (result["metadata"]["is_repeating"][i]) {
            # multi-valued attributes;
            count = dmAPIGet("values," session "," query_id "," result["metadata"]["col_name"][i])
            if (NULL == count) {
               dmShow("error in dmSelecta() while getting the arity of attribute " result["metadata"]["col_name"][i] ": ")
               dmShow("aborting dmSelecta()")
               return -1
            }
            count += 0
            result["metadata"]["max_nb_repeating"][i] = max(result["metadata"]["max_nb_repeating"][i], count)

            max_v_length = 0
            tot_col_length = 0
            for (j = 0; j < count; j++) {
               value = dmAPIGet("get," session "," query_id "," result["metadata"]["col_name"][i] "[" j "]")
               gsub(/[[:blank:]]+$/, "", value)
               result["data"][row_counter][i][j] = value
               v_length = length(value)
               max_v_length = max(max_v_length, v_length)
               tot_col_length += v_length
            }
            result["metadata"]["max_col_length"][i] = max(result["metadata"]["max_col_length"][i], max_v_length)
            result["metadata"]["max_length"] = max(result["metadata"]["max_length"], result["metadata"]["max_col_length"][i])
            result["metadata"]["max_concat_col_length"][i] = max(result["metadata"]["max_concat_col_length"][i], tot_col_length)
            result["metadata"]["max_concat_length"] = max(result["metadata"]["max_concat_length"], result["metadata"]["max_concat_col_length"][i])

            tot_length += max_v_length
         }
         else {
            # mono-valued attributes;
            value = dmAPIGet("get," session "," query_id "," result["metadata"]["col_name"][i])
            gsub(/[[:blank:]]+$/, "", value)
            result["data"][row_counter][i] = value
            v_length = length(value)
            result["metadata"]["max_col_length"][i] = max(result["metadata"]["max_col_length"][i], v_length)
            result["metadata"]["max_length"] = max(result["metadata"]["max_length"], result["metadata"]["max_col_length"][i]) #v_length)
            result["metadata"]["max_concat_col_length"][i] = result["metadata"]["max_col_length"][i]
            result["metadata"]["max_concat_length"] = result["metadata"]["max_length"]

            tot_length += v_length
         }
      }
      metadata["total_max_length"] = max(metadata["total_max_length"], tot_length)
      row_counter++
   }
   result["metadata"]["nb_rows"] = row_counter
   dmShow("exiting dmSelecta()")
   return row_counter
}
 
# print into a table the result of a select statement stored in array result with the structure described in dmSelecta() above;
# colors is the fg/bg colors expressed as string with format fg[.bg], bg default to black; leave it empty if no colors wanted;
# colors defaults to "", i.e. no color;
# col_periods is a string containing the periodicities of the colors, expressed as string with format [-]fg_period.[-]bg_period;
# periodicities are defined as the number of lines to display in the respective color before switching to bg_color.fg_color (i.e. reversing the colors) for that many lines;
# it defaults to 1.1, also in case of syntax error;
# i.e. fg_period lines are displayed in fg_color/bf_color and then bg_period lines displayed in bg_color/fg_color, rinse, repeat;
# if fg_color or bg_color, or both, is negative, no respective colorization takes place;
# grid_type can be empty or contain one of the available values such as ascii, half-light, light, light-double-dash, etc...; see function init_grid_symbols();
function simple_show_table(title, result, colors, col_periods, grid_type       , periods, nb_fg, nb_bg, bno_color, bno_inverse, i, j, k, s) {
   dmShow("in simple_show_table(), title=" title)

   if (colors) {
      if (match(col_periods, /((-?[0-9]+)(\.?(-?[0-9]+))?)/, periods)) {
         nb_fg = periods[2]
         if (nb_fg < 0) {
            nb_fg = -nb_fg
            bno_color = 1
         }
         else
            bno_color = !nb_fg

         if ("" != periods[4]) {
            nb_bg = periods[4]
            if (nb_bg < 0) {
               nb_bg = -nb_bg
               bno_inverse = 1
            }
            else
               bno_inverse = !nb_bg
         }
         else {
            nb_bg = 0
            bno_inverse = 1
         }
      }
      else {
         dmShow("in simple_show_table(), missing or invalid color alternation periods [" col_periods "], disabling alternation")
         nb_fg = 1
         nb_bg = 0
         bno_color = 0
         bno_inverse = 1
      }
   }
   dmShow("in simple_show_table(), colors=" colors ", col_periods=" col_periods ", nb_fg=" nb_fg ", nb_bg=" nb_bg)
   if (bno_color && bno_inverse) {
      nb_fg = 1
      nb_bg = 0
      bno_color = 0
      bno_inverse = 1
      dmShow("in simple_show_table(), invalid nb_fg.nb_bg periodicity given, assuming 1.0")
   }

   prep_grid(result["metadata"]["max_concat_col_length"], result["metadata"]["max_nb_repeating"], grid_art, grid_type)

   print title

   # print column headers;
   # cell width takes into account the | separator for repeating values, if any;
   printf grid_art["top_line"]
   for (i = 0; i < result["metadata"]["nb_cols"]; i++)
      printf("%s%-*s", !grid_type || "no-grid" == grid_type ? (i > 0 ? "  " : "") : grid_art["ver_line"], result["metadata"]["max_concat_col_length"][i] + (result["metadata"]["max_nb_repeating"][i] > 0 ? result["metadata"]["max_nb_repeating"][i] - 1 : 0), result["metadata"]["col_name"][i])
   printf("%s\n", grid_art["ver_line"])

   # iterate through the row set and print the data;
   for (i = 0; i < result["metadata"]["nb_rows"]; i++) {
      printf grid_art["middle_line"]

      # iterate through the row's columns;
      for (j = 0; j < result["metadata"]["nb_cols"]; j++) {
         if (result["metadata"]["is_repeating"][j]) {
            s = ""
            for (k = 0; k < length(result["data"][i][j]); k++)
               s = s (k > 0 ? "|" : "") result["data"][i][j][k]
            # include the | repeating values' separator;
            # as ANSI color sequences are counted towards the column width, colorization must follow formatting; therefore, the values are output in 2 steps;
            s = sprintf("%-*s", result["metadata"]["max_concat_col_length"][j] + (result["metadata"]["max_nb_repeating"][j] > 0 ? result["metadata"]["max_nb_repeating"][j] - 1 : 0), s)
            printf("%s%-s", !grid_type || "no-grid" == grid_type ? (j > 0 ? "  " : "") : grid_art["ver_line"], colorize(s, colors && (i % (nb_fg + nb_bg)) >= nb_fg ? (!bno_inverse ? colors : "") : (bno_color ? "" : colors), colors && (i % (nb_fg + nb_bg)) >= nb_fg && !bno_inverse))
         } 
         else {
            # as ANSI color sequences are counted towards the column width, colorization must follow formatting; therefore, the values are output in 2 steps;
            s = sprintf("%-*s", result["metadata"]["max_col_length"][j], result["data"][i][j])
            printf("%s%-s", !grid_type || "no-grid" == grid_type ? (j > 0 ? "  " : "") : grid_art["ver_line"], colorize(s, colors && (i % (nb_fg + nb_bg)) >= nb_fg ? (!bno_inverse ? colors : "") : (bno_color ? "" : colors), colors && (i % (nb_fg + nb_bg)) >= nb_fg && !bno_inverse))
         }
      }
      printf("%s\n", grid_art["ver_line"])
   } 
   printf grid_art["bottom_line"]
}
   
# flexible tabular presentation of the result set in result;
# title is a string that is printed right before the table, if given;
# result is the associative array coming from dmSelecta(); see there for a description of its structure;
# maxw is the default maximum column width, applied to all columns unless it is superseded by requested_max_widths; if -1, requested_max_widths takes over; see below for precedence;
# if maxw is 0, display_width is used; it is the maximum allowed screen width; if 0, $COLUMNS is used and longer lines get wrapped around by the terminal emulation software; if 0, it is assumed to be unlimited, with possible wrap around;
# it looks like the environment variable $COLUMNS is not exported so child processes don't see it; gawk returns an empty string from ENVIRON["COLUMNS"]; to work around it, just execute an export COLUMNS=$COLUMNS e.g. in a wrapper bash script, before running an awk program that uses DctmAPI;
# requested_max_widths_str is a comma-separated list of explicitely requested positional column widths, possible empty and/or with gaps, superseding maxw, e.g. "10,15,,,8,12,," meaning 1st attribute to be displayed in a 10 character wide column, 2nd attribute in a 15 character wide column, 3rd attribute not limited, etc.. ;
# display_width is the screen width to allocate for the table; must be less or equal to the actual terminal's width to avoid wrapping around by the terminal; if 0, it defaults to the $COLUMNS environment variable;
# individual column widths are selected in this order of precedence:
#   maxw > 0, i.e. same width maxw for all the columns;
#   maxw = 0, display_width > 0: maxw will be set to max(default_min_col, int(screen_width/length(result["medatada"]["nb_cols"]))), with default_min_col = 1;
#   maxw = 0, display_width = 0: $COLUMNS is taken as display_width, same as above; if not set, maxw is set to the locally declared default_min_col variable;
#             when display_width is used, available space is allocated to columns as needed; e.g., if an attribute is empty in all the result set, it will receive no additional space; larger attributes will be allocated larger width; the idea is to minimize wrapping or truncation;
#   maxw = -1: requested_max_widths_str is used if not empty; missing values defaults to their respective result["medatada"]["max_col_length"][0...] value;
#              particular case: empty requested_max_widths_str; max column width defaults to result["medatada"]["max_col_length"][0...], i.e. the widest data of the respective column;
# when result["medatada"]["max_col_length"][0...] is used, obviously no truncation nor wrap around take place (except by the terminal) as the respective column widths are large enough for all their data, particularly for their largest datum;
# wrap_str is string containing a comma-separated list of booleans (value of 0 or 1) indicating if column at respective position has to be wrapped around or not;
# truncate_str is a string containing a comma-separated list of booleans (value of 0 or 1) indicating if column at respective position has to be truncated or not;
# wrapping is the default and has priority over truncating;
#    truncate=0 wrap=0 --> wrapping around;
#    truncate=0 wrap=1 --> wrapping around;
#    truncate=1 wrap=0 --> truncate;
#    truncate=1 wrap=1 --> wrapping around;
#    truncating is therefore only effective when explicitly and unambiguously requested; this is to preserve data integrity whenever possible;
# ellipsis string is only considered when truncating and defaults to '...'; thus, by default, there is always one to warn of truncation;
# that's a lot of fine tuning parameters and at first one may not want to spend time looking for some ideal value; for this reason, it is suggested to start with the following values:
# thus, a lazy and quick invocation is using the current screen width and possible column wrapping: show_table(title, result)
# the table will use up to the screen width as needed, with each attribute using up to result["medatada"]["max_col_length"][0...] characters, and wrapped around if too large;
# use an unlimited screen width, no wrapping, best used with | less -S -R: show_table(title, result, -1)
# further optimization can be done later on as needed;
# fg_color, bg_color are the respective foreground and background color of the displayed rows;
# fg_length, bg_length are the number of lines to display in the respective color before switching to bg_color/fg_color for that many lines; i.e. fg_length lines are displayed in fg_color/bf_color and then bg_length lines displayed in bg_color/fg_color, rinse, repeat;
# if fg_color or bg_color, or both, is negative, no respective colorization takes place;
# grid_type can be empty or contain one of the available values such as ascii, half-light, light, light-double-dash, etc...; see function init_grid_symbols();
function show_table(title, result, maxw, display_width, requested_max_widths_str, wrap_str, truncate_str, ellipsis, colors, col_periods, grid_type           , periods, nb_fg, nb_bg, bno_color, bno_inverse, default_min_col, sep_string, used_width, col_stopped, nb_requested, t_requested_max_widths, i, requested_max_widths, wrap, truncate, s) {
   dmShow("in show_table(), title=" title ", maxw=" maxw ", display_width=" display_width ", requested_max_widths_str=" requested_max_widths_str ", wrap_str=" wrap_str ", truncate_str=" truncate_str ", ellipsis=" ellipsis ", colors=" colors ", col_periods=" col_periods ", grid_type=" grid_type)

   if (colors) {
      if (match(col_periods, /((-?[0-9]+)(\.?(-?[0-9]+))?)/, periods)) {
         nb_fg = periods[2]
         if (nb_fg < 0) {
            nb_fg = -nb_fg
            bno_color = 1
         }
         else
            bno_color = !nb_fg

         if ("" != periods[4]) {
            nb_bg = periods[4]
            if (nb_bg < 0) {
               nb_bg = -nb_bg
               bno_inverse = 1
            }
            else
               bno_inverse = !nb_bg
         }
         else {
            nb_bg = 1
            nb_bg = 0
            bno_inverse = 1
         }
      }
      else {
         dmShow("in show_table(), missing or invalid color alternation periods [" col_periods "], disabling alternation")
         nb_fg = 1
         nb_bg = 0
         bno_color = 0
         bno_inverse = 1
      }
   }
   dmShow("in show_table(), colors=" colors ", col_periods=" col_periods ", nb_fg=" nb_fg ", nb_bg=" nb_bg)
   if (bno_color && bno_inverse) {
      nb_fg = 1
      nb_bg = 0
      bno_color = 0
      bno_inverse = 1
      dmShow("in show_table(), invalid nb_fg.nb_bg periodicity given, assuming 1.0")
   }

   # minimum global column width if not individually set or computable;
   default_min_col = 5

   # column separator;
   sep_string = "  "

   if (title)
      print title

   if (0 == maxw) {
      # use display_width or else $COLUMNS or else default_min_col for all the columns;
      if (display_width > 0)
         ;
      else if (ENVIRON["COLUMNS"]) {
         display_width = ENVIRON["COLUMNS"]
         dmShow("in show_table(), display_width=" display_width)
      }
      else {
         # this test does not work, strange ...
         if (!("COLUMNS" in ENVIRON))
            dmShow("in show_table(), warning: $COLUMNS not found in environment, assuming it is 0 for an unlimited screen width")
         # no screen width limit: use default_min_col for each attribute taking the separators into account;
         display_width = default_min_col * result["metadata"]["nb_cols"] + length(sep_string) * (result["metadata"]["nb_cols"] - 1)
      }
      # let's be optimistic: suppose the screen is large enough to display without wrapping nor truncation;
      used_width = 0
      for (i = 0; i < result["metadata"]["nb_cols"]; i++) {
         requested_max_widths[i] = result["metadata"]["max_col_length"][i]
         used_width += requested_max_widths[i]
      }

      # table would be too to large ?
      # if so, shrink the attributes in round-robin fashion until the table fits into the given screen width or no attribute left to further shrink;
      col_stopped = 0
      while (col_stopped < result["metadata"]["nb_cols"] && used_width + length(sep_string) * (result["metadata"]["nb_cols"] - 1) > display_width) {
         col_stopped = 0
         for (i = 0; i < result["metadata"]["nb_cols"]; i++) {
            if (requested_max_widths[i] <= default_min_col)
               # no more shrinking for this column;
               col_stopped += 1
            else {
               requested_max_widths[i] -= 1
               used_width -= 1
               # stop as soon as no shrinking is needed any more;
               if (used_width + length(sep_string) * (result["metadata"]["nb_cols"] - 1) == display_width) {
                  col_stopped += 1
                  break
               }
            }
         }
      }
   }
   else if (maxw < 0)
      # don't use the display width;
      # use the requested_max_widths_str and/or complete the missing data with respective values from result["metadata"]["max_col_length"][0..n];
      # ingest requested widths if given;
      if (requested_max_widths_str) {
         # split string of numbers into a temporary 1-based array t_requested_max_widths[...];
         # values are then copied into the 0-based array requested_max_widths[...]
         nb_requested = split(requested_max_widths_str, t_requested_max_widths, ",")
         for (i = 1; i <= nb_requested; i++)
            if (t_requested_max_widths[i])
               requested_max_widths[i - 1] = t_requested_max_widths[i]
            else
               # complete requested_max_widths' gaps;
               requested_max_widths[i - 1] = result["metadata"]["max_col_length"][i - 1]
         for (--i; i < result["metadata"]["nb_cols"]; i++)
            # complete missing values in requested_max_widths with the effective widths;
            requested_max_widths[i] = result["metadata"]["max_col_length"][i - 1]
      } 
      else
         for (i = 0; i < result["metadata"]["nb_cols"]; i++)
            requested_max_widths[i] = result["metadata"]["max_col_length"][i]
   else {
      # if (maxw > 0): use it for all the attributes;
      maxw = max(default_min_col, maxw)
      for (i = 0; i < result["metadata"]["nb_cols"]; i++)
         requested_max_widths[i] = maxw
   }
   # in summary, if maxw > 0, use its value for all the columns; if maxw == 0, use display_width or else $COLUMNS or else default_min_col for all the columns; if maxw < 0, use the requested widths completed with the respective column widths;
   # the rules are complex but have been implemented into requested_max_widths[...] so using that array implicitly applies the rules;

   prep_grid(requested_max_widths, 0, grid_art, grid_type)

   # wrapping requests;
   # convert string list to 1-based array;
   split(wrap_str, wrap, ",")
   # resolve gaps and missing values to true, the default for wrapping;
   for (i = 1; i <= result["metadata"]["nb_cols"]; i++)
      wrap[i - 1] = wrap[i] ? 1 : 0

   # truncation requests;
   # convert string list to 1-based array;
   # leave gaps and missing values, they default to false anyway which is what we want; they will be explicitly completed later below;
   split(truncate_str, truncate, ",")

   # wrapping is prioritary over truncating so, basically, always wrap except when no wrap AND truncate;
   # can also be expressed as follows: if (!(!wrap[i] && truncate[i])) {wrap[i] = 1; truncate[i] = 0}
   # but the block below looks more readable to express the logic;
   # subsequent usage is: if truncate[i], then truncate column i else wrap it;
   for (i = 1; i <= result["metadata"]["nb_cols"]; i++)
      if (!truncate[i]) {
         truncate[i - 1] = 0
         if (!wrap[i - 1])
            wrap[i - 1] = 1
         else
            truncate[i - 1] = 0
      }
      else if (!wrap[i - 1])
         truncate[i - 1] = 1
      else
         truncate[i - 1] = 0

   if (!ellipsis)
      ellipsis = "..."

   printf grid_art["top_line"]
   printWithWA(-1, result["metadata"], result["metadata"]["col_name"], requested_max_widths, wrap, truncate, ellipsis, sep_string, colors, nb_fg, nb_bg, bno_color, bno_inverse, grid_art)
   for (i = 0; i < result["metadata"]["nb_rows"]; i++) {
      printf grid_art["middle_line"]
      printWithWA(i, result["metadata"], result["data"][i], requested_max_widths, wrap, truncate, ellipsis, sep_string, colors, nb_fg, nb_bg, bno_color, bno_inverse, grid_art)
   }
   printf grid_art["bottom_line"]
}

# print the row with the columns from array rowa, with optional truncation or wrapping around, in respective fields requested_max_widths[...]-wide;
function printWithWA(no_row, metadata, rowa, requested_max_widths, wrap, truncate, ellipsis, sep_string, colors, nb_fg, nb_bg, bno_color, bno_inverse, grid_art        , is_header, bany_wrap, i, j, rep_index, lrowa, bleft_over, realw, columnS) {
   bany_wrap = 0
   is_header = -1 == no_row
   # arrays are passed by reference and can be modified by the callee; as we don't want that, we deep copy rowa into lrowa, l for local;
   for (i = 0; i < metadata["nb_cols"]; i++) {
      if (is_header || !metadata["is_repeating"][i])
         lrowa[i] = rowa[i]
      else {
         # copy the repeating attributes;
         for (j = 0; j < length(rowa[i]); j++)
            lrowa[i][j] = rowa[i][j]
         rep_index[i] = 0                          # pointer to the current repeating attribute's current value;
      }
      bany_wrap = bany_wrap || wrap[i]             # if any attribute is repeating then the resulting overall wrapping is true;
   }
   do {
      bleft_over = 0
      for (i = 0; i < metadata["nb_cols"]; i++) {
         col_data = !is_header && metadata["is_repeating"][i] ? lrowa[i][rep_index[i]] : lrowa[i]
         realw = requested_max_widths[i]
         if (!truncate[i] || length(col_data) <= realw) {
            displayed_length = realw
            columnS = substr(col_data, 1, realw)
            col_data = substr(col_data, displayed_length + 1)
         }
         else {
            # truncation must occur;
            displayed_length = realw - length(ellipsis)
            columnS = substr(col_data, 1, displayed_length) ellipsis
            col_data = ""
         }
         columnS = sprintf("%-*s", realw, columnS)
         printf("%s%-s", i > 0 ? (!grid_art["type"] || "no-grid" == grid_art["type"] ? sep_string : grid_art["ver_line"]) : grid_art["ver_line"], is_header ? columnS : colorize(columnS, colors && (no_row % (nb_fg + nb_bg)) >= nb_fg ? (!bno_inverse ? colors : "") : (bno_color ? "" : colors), colors && (no_row % (nb_fg + nb_bg)) >= nb_fg && !bno_inverse))
         if (!is_header && metadata["is_repeating"][i]) {
            # repeating attribute;
            lrowa[i][rep_index[i]] = col_data
            bleft_over = bleft_over ||            # the status is cumulative for the entire row;
                         lrowa[i][rep_index[i]]   # this attribute still has characters to display;
         }
         else {
            # monovalued attribute;
            lrowa[i] = col_data # substr(lrowa[i], displayed_length + 1)
            bleft_over = bleft_over ||           # the status is cumulative for the entire row;
                         lrowa[i]                # this attribute still has characters to display;
         }
      }
      printf("%s\n", grid_art["ver_line"])
      if (!bleft_over)
         # check if there are any repeating attributes left to display synchronously with other such attributes;
         for (i = 0; i < metadata["nb_cols"]; i++)
            if (!is_header && metadata["is_repeating"][i] && rep_index[i] < length(lrowa[i]) - 1) {
               rep_index[i]++
               bleft_over = 1
            }
   } while (bleft_over && bany_wrap)
}

# do they really need a comment ?
function max(x, y) {
   return(x >= y ? x : y)
}
function min(x, y) {
   return(x <= y ? x : y)
}

function repeat_str(ch, len   , s) {
   s = ""
   ch = sprintf("%0c", ch)
   while (len-- > 0)
      s = s ch
   return s
}

# closes the given session;
# returns 1 if no error, 0 otherwise;
function dmDisconnect(session   , status) {
   dmShow("in dmDisconnect()")

   status = dmAPIExec("disconnect," session)
   if (!status)
      dmShow("Exception in dmDisconnect():")
   dmShow("exiting disconnect()")
   return status
}

# initialize the array g of grid drawing symbols;
# currently supported grid types are:
#    no-grid, ascii, half-light, light, light-double-dash, light-triple-dash, light-quadruple-dash, heavy, heavy-double-dash, heavy-triple-dash, heavy-quadruple-dash, double, hdouble-vsingle, hsingle-vdouble, light-with-round-corners, hheavy-vlight, hlight-vheavy; 
# many more could be added by combining compatible line styles, have fun;
function init_grid_symbols(g) {
   # ascii;
   g["ascii"]["ltc"] = "+"
   g["ascii"]["rtc"] = "+"
   g["ascii"]["lbc"] = "+"
   g["ascii"]["rbc"] = "+"
   g["ascii"]["hor_line"] = "-"
   g["ascii"]["ver_line"] = "|"
   g["ascii"]["tt"] = "+"
   g["ascii"]["bt"] = "+"
   g["ascii"]["lt"] = "+"
   g["ascii"]["rt"] = "+"
   g["ascii"]["x"]  = "+"

   # no-grid;
   g["no-grid"]["ltc"] = ""
   g["no-grid"]["rtc"] = ""
   g["no-grid"]["lbc"] = ""
   g["no-grid"]["rbc"] = ""
   g["no-grid"]["hor_line"] = ""
   g["no-grid"]["ver_line"] = ""
   g["no-grid"]["tt"] = ""
   g["no-grid"]["bt"] = ""
   g["no-grid"]["lt"] = ""
   g["no-grid"]["rt"] = ""
   g["no-grid"]["x"]  = ""

   # grid drawing using UTF-8 characters, cf. UTF-8 codepoints here: https://cloford.com/resources/charcodes/utf-8_box-drawing.htm;
   # half-light;
   g["half-light"]["ltc"] = 0x250c
   g["half-light"]["rtc"] = 0x2510
   g["half-light"]["lbc"] = 0x2514
   g["half-light"]["rbc"] = 0x2518
   g["half-light"]["hor_line"] = 0x2574
   g["half-light"]["ver_line"] = sprintf("%0c", 0x2577)
   g["half-light"]["tt"] = 0x252c
   g["half-light"]["bt"] = 0x2534
   g["half-light"]["lt"] = 0x251c
   g["half-light"]["rt"] = 0x2524
   g["half-light"]["x"]  = 0x253c

   # light;
   g["light"]["ltc"] = 0x250c
   g["light"]["rtc"] = 0x2510
   g["light"]["lbc"] = 0x2514
   g["light"]["rbc"] = 0x2518
   g["light"]["hor_line"] = 0x2500
   g["light"]["ver_line"] = sprintf("%0c", 0x2502)
   g["light"]["tt"] = 0x252c
   g["light"]["bt"] = 0x2534
   g["light"]["lt"] = 0x251c
   g["light"]["rt"] = 0x2524
   g["light"]["x"]  = 0x253c

   # light double dash;
   g["light-double-dash"]["ltc"] = 0x250c
   g["light-double-dash"]["rtc"] = 0x2510
   g["light-double-dash"]["lbc"] = 0x2514
   g["light-double-dash"]["rbc"] = 0x2518
   g["light-double-dash"]["hor_line"] = 0x254c
   g["light-double-dash"]["ver_line"] = sprintf("%0c", 0x254e)
   g["light-double-dash"]["tt"] = 0x252c
   g["light-double-dash"]["bt"] = 0x2534
   g["light-double-dash"]["lt"] = 0x251c
   g["light-double-dash"]["rt"] = 0x2524
   g["light-double-dash"]["x"]  = 0x253c

   # light triple dash;
   g["light-triple-dash"]["ltc"] = 0x250c
   g["light-triple-dash"]["rtc"] = 0x2510
   g["light-triple-dash"]["lbc"] = 0x2514
   g["light-triple-dash"]["rbc"] = 0x2518
   g["light-triple-dash"]["hor_line"] = 0x2504
   g["light-triple-dash"]["ver_line"] = sprintf("%0c", 0x2506)
   g["light-triple-dash"]["tt"] = 0x252c
   g["light-triple-dash"]["bt"] = 0x2534
   g["light-triple-dash"]["lt"] = 0x251c
   g["light-triple-dash"]["rt"] = 0x2524
   g["light-triple-dash"]["x"]  = 0x253c

   # light quadruple dash;
   g["light-quadruple-dash"]["ltc"] = 0x250c
   g["light-quadruple-dash"]["rtc"] = 0x2510
   g["light-quadruple-dash"]["lbc"] = 0x2514
   g["light-quadruple-dash"]["rbc"] = 0x2518
   g["light-quadruple-dash"]["hor_line"] = 0x2508
   g["light-quadruple-dash"]["ver_line"] = sprintf("%0c", 0x250a)
   g["light-quadruple-dash"]["tt"] = 0x252c
   g["light-quadruple-dash"]["bt"] = 0x2534
   g["light-quadruple-dash"]["lt"] = 0x251c
   g["light-quadruple-dash"]["rt"] = 0x2524
   g["light-quadruple-dash"]["x"]  = 0x253c

   # heavy;
   g["heavy"]["ltc"] = 0x250f
   g["heavy"]["rtc"] = 0x2513
   g["heavy"]["lbc"] = 0x2517
   g["heavy"]["rbc"] = 0x251b
   g["heavy"]["hor_line"] = 0x2501
   g["heavy"]["ver_line"] = sprintf("%0c", 0x2503)
   g["heavy"]["tt"] = 0x2533
   g["heavy"]["bt"] = 0x253b
   g["heavy"]["lt"] = 0x2523
   g["heavy"]["rt"] = 0x252b
   g["heavy"]["x"]  = 0x254b

   # heavy double dash;
   g["heavy-double-dash"]["ltc"] = 0x250f
   g["heavy-double-dash"]["rtc"] = 0x2513
   g["heavy-double-dash"]["lbc"] = 0x2517
   g["heavy-double-dash"]["rbc"] = 0x251b
   g["heavy-double-dash"]["hor_line"] = 0x254d
   g["heavy-double-dash"]["ver_line"] = sprintf("%0c", 0x254f)
   g["heavy-double-dash"]["tt"] = 0x2533
   g["heavy-double-dash"]["bt"] = 0x253b
   g["heavy-double-dash"]["lt"] = 0x2523
   g["heavy-double-dash"]["rt"] = 0x252b
   g["heavy-double-dash"]["x"]  = 0x254b

   # heavy triple dash;
   g["heavy-triple-dash"]["ltc"] = 0x250f
   g["heavy-triple-dash"]["rtc"] = 0x2513
   g["heavy-triple-dash"]["lbc"] = 0x2517
   g["heavy-triple-dash"]["rbc"] = 0x251b
   g["heavy-triple-dash"]["hor_line"] = 0x2509
   g["heavy-triple-dash"]["ver_line"] = sprintf("%0c", 0x2507)
   g["heavy-triple-dash"]["tt"] = 0x2533
   g["heavy-triple-dash"]["bt"] = 0x253b
   g["heavy-triple-dash"]["lt"] = 0x2523
   g["heavy-triple-dash"]["rt"] = 0x252b
   g["heavy-triple-dash"]["x"]  = 0x254b

   # heavy quadruple dash;
   g["heavy-quadruple-dash"]["ltc"] = 0x250f
   g["heavy-quadruple-dash"]["rtc"] = 0x2513
   g["heavy-quadruple-dash"]["lbc"] = 0x2517
   g["heavy-quadruple-dash"]["rbc"] = 0x251b
   g["heavy-quadruple-dash"]["hor_line"] = 0x2509
   g["heavy-quadruple-dash"]["ver_line"] = sprintf("%0c", 0x250b)
   g["heavy-quadruple-dash"]["tt"] = 0x2533
   g["heavy-quadruple-dash"]["bt"] = 0x253b
   g["heavy-quadruple-dash"]["lt"] = 0x2523
   g["heavy-quadruple-dash"]["rt"] = 0x252b
   g["heavy-quadruple-dash"]["x"]  = 0x254b

   # double;
   g["double"]["ltc"] = 0x2554
   g["double"]["rtc"] = 0x2557
   g["double"]["lbc"] = 0x255a
   g["double"]["rbc"] = 0x255d
   g["double"]["hor_line"] = 0x2550
   g["double"]["ver_line"] = sprintf("%0c", 0x2551)
   g["double"]["tt"] = 0x2566
   g["double"]["bt"] = 0x2569
   g["double"]["lt"] = 0x2560
   g["double"]["rt"] = 0x2563
   g["double"]["x"]  = 0x256C

   # hdouble-vsingle;
   g["hdouble-vsingle"]["ltc"] = 0x2552
   g["hdouble-vsingle"]["rtc"] = 0x2555
   g["hdouble-vsingle"]["lbc"] = 0x2558
   g["hdouble-vsingle"]["rbc"] = 0x255b
   g["hdouble-vsingle"]["hor_line"] = 0x2550
   g["hdouble-vsingle"]["ver_line"] = sprintf("%0c", 0x2502)
   g["hdouble-vsingle"]["tt"] = 0x2564
   g["hdouble-vsingle"]["bt"] = 0x2567
   g["hdouble-vsingle"]["lt"] = 0x255e
   g["hdouble-vsingle"]["rt"] = 0x2561
   g["hdouble-vsingle"]["x"]  = 0x256a

   # hsingle-vdouble;
   g["hsingle-vdouble"]["ltc"] = 0x2553
   g["hsingle-vdouble"]["rtc"] = 0x2556
   g["hsingle-vdouble"]["lbc"] = 0x2559
   g["hsingle-vdouble"]["rbc"] = 0x255c
   g["hsingle-vdouble"]["hor_line"] = 0x2500
   g["hsingle-vdouble"]["ver_line"] = sprintf("%0c", 0x2551)
   g["hsingle-vdouble"]["tt"] = 0x2565
   g["hsingle-vdouble"]["bt"] = 0x2568
   g["hsingle-vdouble"]["lt"] = 0x255f
   g["hsingle-vdouble"]["rt"] = 0x2562
   g["hsingle-vdouble"]["x"]  = 0x256b

   # light-with-round-corners;
   g["light-with-round-corners"]["ltc"] = 0x256d
   g["light-with-round-corners"]["rtc"] = 0x256e
   g["light-with-round-corners"]["lbc"] = 0x2570
   g["light-with-round-corners"]["rbc"] = 0x256f
   g["light-with-round-corners"]["hor_line"] = 0x2500
   g["light-with-round-corners"]["ver_line"] = sprintf("%0c", 0x2502)
   g["light-with-round-corners"]["tt"] = 0x252c
   g["light-with-round-corners"]["bt"] = 0x2534
   g["light-with-round-corners"]["lt"] = 0x251c
   g["light-with-round-corners"]["rt"] = 0x2524
   g["light-with-round-corners"]["x"]  = 0x253c

   # hheavy-vlight;
   g["hheavy-vlight"]["ltc"] = 0x250D
   g["hheavy-vlight"]["rtc"] = 0x2511
   g["hheavy-vlight"]["lbc"] = 0x2515
   g["hheavy-vlight"]["rbc"] = 0x2519
   g["hheavy-vlight"]["hor_line"] = 0x2501
   g["hheavy-vlight"]["ver_line"] = sprintf("%0c", 0x2502)
   g["hheavy-vlight"]["tt"] = 0x252f
   g["hheavy-vlight"]["bt"] = 0x2537
   g["hheavy-vlight"]["lt"] = 0x251d
   g["hheavy-vlight"]["rt"] = 0x2525
   g["hheavy-vlight"]["x"]  = 0x253f

   # hlight-vheavy;
   g["hlight-vheavy"]["ltc"] = 0x250e
   g["hlight-vheavy"]["rtc"] = 0x2512
   g["hlight-vheavy"]["lbc"] = 0x2516
   g["hlight-vheavy"]["rbc"] = 0x251a
   g["hlight-vheavy"]["hor_line"] = 0x2500
   g["hlight-vheavy"]["ver_line"] = sprintf("%0c", 0x2503)
   g["hlight-vheavy"]["tt"] = 0x2530
   g["hlight-vheavy"]["bt"] = 0x2538
   g["hlight-vheavy"]["lt"] = 0x2520
   g["hlight-vheavy"]["rt"] = 0x2528
   g["hlight-vheavy"]["x"]  = 0x2542
}

# returns in array grid_art index values grid-art["top_line"], ["middle_line"], ["bottom_line"] the strings to respectively draw the grid's top, middle and bottom lines
# plus the vertical line in grid_art["ver_line"] and grid_type in grid_art["type"];
# grid_type is optional and selects the type of grid;
function prep_grid(col_widths, rep_cols, grid_art, grid_type           , g, nb_cols, i) {
   dmShow("in prep_grid(), grid_type = " grid_type)

   init_grid_symbols(g)

   if (grid_type && grid_type in g && "no-grid" != grid_type) {
      # initialize the grid's components with the dimensions in col_widths;
      top_grid_line =    sprintf("%0c", g[grid_type]["ltc"])
      middle_grid_line = sprintf("%0c", g[grid_type]["lt"])
      bottom_grid_line = sprintf("%0c", g[grid_type]["lbc"])
      nb_cols = length(col_widths)
      for (i = 0; i < nb_cols; i++) {
         if (isarray(rep_cols)) {
            top_grid_line    = top_grid_line    repeat_str(g[grid_type]["hor_line"], col_widths[i]  + (rep_cols[i] > 0 ? rep_cols[i] - 1 : 0))
            middle_grid_line = middle_grid_line repeat_str(g[grid_type]["hor_line"], col_widths[i]  + (rep_cols[i] > 0 ? rep_cols[i] - 1 : 0))
            bottom_grid_line = bottom_grid_line repeat_str(g[grid_type]["hor_line"], col_widths[i]  + (rep_cols[i] > 0 ? rep_cols[i] - 1 : 0))
         } 
         else {
            top_grid_line =    top_grid_line    repeat_str(g[grid_type]["hor_line"], col_widths[i])
            middle_grid_line = middle_grid_line repeat_str(g[grid_type]["hor_line"], col_widths[i])
            bottom_grid_line = bottom_grid_line repeat_str(g[grid_type]["hor_line"], col_widths[i])
         }
         top_grid_line    = top_grid_line    (i < nb_cols - 1 ? sprintf("%0c", g[grid_type]["tt"]) : "")
         middle_grid_line = middle_grid_line (i < nb_cols - 1 ? sprintf("%0c", g[grid_type]["x"])  : "")
         bottom_grid_line = bottom_grid_line (i < nb_cols - 1 ? sprintf("%0c", g[grid_type]["bt"]) : "")
      }
      # include a lf so the strings can be printf-ed for compatibility with empty strings for no grid;
      top_grid_line    = top_grid_line    sprintf("%0c", g[grid_type]["rtc"]) "\n"
      middle_grid_line = middle_grid_line sprintf("%0c", g[grid_type]["rt"])  "\n"
      bottom_grid_line = bottom_grid_line sprintf("%0c", g[grid_type]["rbc"]) "\n"
   }
   else {
      # no-grid, or empty or unsupported grid_type;
      if (grid_type && !(grid_type in g))
         dmShow("in prep_grid, unsupported grid_type" grid_type ", no gridding") 
      else
         dmShow("in prep_grid, no gridding") 
      top_grid_line      = ""
      middle_grid_line   = ""
      bottom_grid_line   = ""
   } 
   grid_art["type"]        = grid_type
   grid_art["top_line"]    = top_grid_line
   grid_art["middle_line"] = middle_grid_line
   grid_art["bottom_line"] = bottom_grid_line
   grid_art["ver_line"]    = g[grid_type]["ver_line"]
}

# print s in color fg.bg, i.e. foreground color fg and background bg_color bg, if defined;
# otherwise, no color change occurs;
# if binverse, inverse fg and bg colors, i.e. use color bg.fg instead of fg.bg;
function colorize(s, color, binverse    , colors) {
   if (color) {
      match(color, /([^.]+)(\.?([^.]+))/, colors)
      if (!binverse) {
         color1 = 1
         color2 = 3
      }
      else {
         color1 = 3
         color2 = 1
      }
      if (colors[color1] in FG_COLORS && colors[color2] in BG_COLORS)
         return sprintf("%s%s%s%s", FG_COLORS[colors[color1]], BG_COLORS[colors[color2]], s, FG_COLORS["reset_all"])
      else {
         dmShow("in colorize, undefined color [" colors[color1] "] or [" colors[color2] "]")
         return sprintf("%s", s)
      }
   }
   else
      return sprintf("%s", s)
}

# initializes the color arrays with the ANSI color codes;
# available variables from the outside are FG_COLORS and BG_COLORS;
# supported colors strings are: black, red, green, yellow, blue, magenta, cyan, white;
# use uppercase for bright colors;
# use "reset_fg" to reset the foreground color, "reset_bg" to reset the background color, "reset_all" to reset both the fg and bg to the default colors;
function init_colors(FG_COLORS, BG_COLORS     , esc, reset_all,
                                                black_fg, red_fg, green_fg, yellow_fg, blue_fg, magenta_fg, cyan_fg, white_fg, reset_fg,
                                                BLACK_fg, RED_fg, GREEN_fg, YELLOW_fg, BLUE_fg, MAGENTA_fg, CYAN_fg, WHITE_fg,
                                                black_bg, red_bg, green_bg, yellow_bg, blue_bg, magenta_bg, cyan_bg, white_bg, reset_bg,
                                                BLACK_bg, RED_bg, GREEN_bg, YELLOW_bg, BLUE_bg, MAGENTA_bg, CYAN_bg, WHITE_bg,
                                                _colors_str, nb_colors, _color_tab, i, cleol) {
   # ANSI codes for coloration of output;
   esc = 0x1b
   #reset_all  = sprintf("%c[0m", esc)
   reset_all  = sprintf("%c[39;49m", esc)
   #reset_all  = reset_fg reset_bg

   black_fg   = sprintf("%c[30m", esc); BLACK_fg   = sprintf("%c[90m", esc)
   red_fg     = sprintf("%c[31m", esc); RED_fg     = sprintf("%c[91m", esc)
   green_fg   = sprintf("%c[32m", esc); GREEN_fg   = sprintf("%c[92m", esc)
   yellow_fg  = sprintf("%c[33m", esc); YELLOW_fg  = sprintf("%c[93m", esc)
   blue_fg    = sprintf("%c[34m", esc); BLUE_fg    = sprintf("%c[94m", esc)
   magenta_fg = sprintf("%c[35m", esc); MAGENTA_fg = sprintf("%c[95m", esc)
   cyan_fg    = sprintf("%c[36m", esc); CYAN_fg    = sprintf("%c[96m", esc)
   white_fg   = sprintf("%c[37m", esc); WHITE_fg   = sprintf("%c[97m", esc)
   reset_fg   = sprintf("%c[39m", esc)

   black_bg   = sprintf("%c[40m", esc); BLACK_bg   = sprintf("%c[100m", esc)
   red_bg     = sprintf("%c[41m", esc); RED_bg     = sprintf("%c[101m", esc)
   green_bg   = sprintf("%c[42m", esc); GREEN_bg   = sprintf("%c[102m", esc)
   yellow_bg  = sprintf("%c[43m", esc); YELLOW_bg  = sprintf("%c[103m", esc)
   blue_bg    = sprintf("%c[44m", esc); BLUE_bg    = sprintf("%c[104m", esc)
   magenta_bg = sprintf("%c[45m", esc); MAGENTA_bg = sprintf("%c[105m", esc)
   cyan_bg    = sprintf("%c[46m", esc); CYAN_bg    = sprintf("%c[106m", esc)
   white_bg   = sprintf("%c[47m", esc); WHITE_bg   = sprintf("%c[107m", esc)
   reset_bg   = sprintf("%c[49m", esc)

   # colors in lowercase of normal intensity, in uppercase for bright intensity;
   _colors_str = "black, red, green, yellow, blue, magenta, cyan, white, reset, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset_fg, reset_bg, reset_all"
   nb_colors = split(_colors_str, _color_tab, ", ")
   for (i = 1; i <= nb_colors; i++)
      switch (_color_tab[i]) {
         case "black":     FG_COLORS[_color_tab[i]] = black_fg
                           BG_COLORS[_color_tab[i]] = reset_bg #black_bg
                           BG_COLORS[_color_tab[i]] = black_bg
                           break
         case "red":       FG_COLORS[_color_tab[i]] = red_fg
                           BG_COLORS[_color_tab[i]] = red_bg
                           break
         case "green":     FG_COLORS[_color_tab[i]] = green_fg
                           BG_COLORS[_color_tab[i]] = green_bg
                           break
         case "yellow":    FG_COLORS[_color_tab[i]] = yellow_fg
                           BG_COLORS[_color_tab[i]] = yellow_bg
                           break
         case "blue":      FG_COLORS[_color_tab[i]] = blue_fg
                           BG_COLORS[_color_tab[i]] = blue_bg
                           break
         case "magenta":   FG_COLORS[_color_tab[i]] = magenta_fg
                           BG_COLORS[_color_tab[i]] = magenta_bg
                           break
         case "cyan":      FG_COLORS[_color_tab[i]] = cyan_fg
                           BG_COLORS[_color_tab[i]] = cyan_bg
                           break
         case "white":     FG_COLORS[_color_tab[i]] = white_fg
                           BG_COLORS[_color_tab[i]] = white_bg
                           break
         case "reset_fg":  FG_COLORS[_color_tab[i]] = reset_fg
                           break
         case "reset":     FG_COLORS[_color_tab[i]] = reset_fg
                           BG_COLORS[_color_tab[i]] = reset_bg
                           break
         case "BLACK":     FG_COLORS[_color_tab[i]] = BLACK_fg
                           BG_COLORS[_color_tab[i]] = reset_bg #BLACK_bg
                           BG_COLORS[_color_tab[i]] = BLACK_bg
                           break
         case "RED":       FG_COLORS[_color_tab[i]] = RED_fg
                           BG_COLORS[_color_tab[i]] = RED_bg
                           break
         case "GREEN":     FG_COLORS[_color_tab[i]] = GREEN_fg
                           BG_COLORS[_color_tab[i]] = GREEN_bg
                           break
         case "YELLOW":    FG_COLORS[_color_tab[i]] = YELLOW_fg
                           BG_COLORS[_color_tab[i]] = YELLOW_bg
                           break
         case "BLUE":      FG_COLORS[_color_tab[i]] = BLUE_fg
                           BG_COLORS[_color_tab[i]] = BLUE_bg
                           break
         case "MAGENTA":   FG_COLORS[_color_tab[i]] = MAGENTA_fg
                           BG_COLORS[_color_tab[i]] = MAGENTA_bg
                           break
         case "CYAN":      FG_COLORS[_color_tab[i]] = CYAN_fg
                           BG_COLORS[_color_tab[i]] = CYAN_bg
                           break
         case "WHITE":     FG_COLORS[_color_tab[i]] = WHITE_fg
                           BG_COLORS[_color_tab[i]] = WHITE_bg
                           break
         case "reset_bg":  BG_COLORS[_color_tab[i]] = reset_bg
                           break
         case "reset_all": FG_COLORS[_color_tab[i]] = reset_all
                           BG_COLORS[_color_tab[i]] = reset_all
                           break
      }
}

# TO DO:
# standardize return codes;

