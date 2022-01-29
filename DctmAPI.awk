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

dmLogLevel = 1
 
function dmShow(mesg) {
# displays the message msg if dmLogLevel is set;
# also, if a session is passed, get the error message from the API;
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
      # truncate is not allowed here; must force the unused settings to an empty value;
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
   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error calling query in dmExecute()")
      dmShow("aborting dmExecute()")
      exit_status = 0
   }
   if (!dmAPIExec("close," session "," query_id)) {
      dmShow("Error calling close in dmExecute()")
      dmShow("aborting dmExecute()")
   }
   dmShow("exiting dmExecute()")
   return exit_status
}
 
function dmSelecto(session, dql_stmt, attribute_names      , query_id, s, nb_attrs, attr, attributes_tab, resp_cntr, value) {
# execute the DQL SELECT statement passed in dql_stmt and outputs the result to stdout (hence the "o" in dmSelecto);
# attributes_names is a comma-separated list of mono-valued attributes to extract from the result set;
# return the number of rows in the result set if OK, -1 otherwise;
   dmShow("in dmSelect(), dql_stmt=" dql_stmt)
   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error calling query in dmSelecto()")
      dmShow("aborting dmSelecto()")
      return -1 
   }
 
   s = ""
   nb_attrs = split(attribute_names, attributes_tab, ",")
   for (attr = 1; attr <= nb_attrs; attr++)
      s = s "[" attributes_tab[attr] "]\t"
   print s
   resp_cntr = 0
   while (dmAPIExec("next," session "," query_id) > 0) {
      s = ""
      for (attr = 1; attr <= nb_attrs; attr++) {
         value = dmAPIGet("get," session "," query_id "," attributes_tab[attr])
         if ("r_object_id" == attributes_tab[attr] && !value) {
            dmShow("Error getting r_object_id in dmSelecto()")
            dmShow("aborting dmSelecto()")
            return -1
         }
         s= s "[" (value ? value : "NULL") "]\t"
      }
      resp_cntr += 1
      dmShow(sprintf("%d: %s", resp_cntr, s))
   }
   dmShow(sprintf("%d rows iterated", resp_cntr))
 
   if (!dmAPIExec("close," session "," query_id)) {
      dmShow("Error calling close in dmSelecto()")
      dmShow("aborting dmSelecto()")
      return -1
   }
 
   dmShow("exiting dmSelecto()")
   return resp_cntr
}
 
function dmSelect(session, dql_stmt         , query_id) {
# execute the DQL SELECT statement passed in dql_stmt and return the query's id, or an empty string in case of error;
# use dmNext() to iterate through the result set and dmClose() to close the query;
   dmShow("in dmSelect(), dql_stmt=" dql_stmt)
   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error in dmSelect()")
      dmShow("aborting dmSelect()")
   }
   dmShow("exiting dmSelect()")
   return query_id
}

function dmNext(session, query_id, result        , nb_attrs, i, count, j, value) {
# execute the DQL SELECT statement passed in dql_stmt and return the result set into the three-line array result;
# result[-1] contains an array with the repeating flag of respective attribute in result[0][0..], i.e. result[-1][i] = 1 if attribute result[0][i] is repeating, 0 otherwise;
# result[0] contains an array with the attribute names in result[-1][0..];
# initially, both lines are empty and get populated during the first call to dmNext();
# result[1] contain the attributes' values, or arrays of values if the attributes are repeating;
# pass the same result parameter to subsequent calls to dmNext() because those 2 first lines are needed;
# return 0 if OK, -1 if not;
   dmShow("in dmNext(), dql_stmt=" dql_stmt)
   while (dmAPIExec("next," session "," query_id) > 0) {
      nb_attrs = dmAPIGet("count," session "," query_id)
      if (NULL == nb_attrs) {
         dmShow("Error in dmNext() while retrieving the count of returned attributes")
         dmShow("aborting dmNext()")
         return -1
      }
      nb_attrs += 0
      for (i = 0; i < nb_attrs; i++) {
         if (!result || !result[0] || !result[0][i]) {
            # get the attributes' names only once for the whole query;
            result[0][i] = dmAPIGet("get," session "," query_id ",_names[" i "]")
            if (NULL == result[0][i]) {
               dmShow("error in dmNext() while getting the attribute name at position " i ": ")
               dmShow("aborting dmNext()")
               return -1
            }

            result[-1][i] = dmAPIGet("repeating," session "," query_id "," result[0][i])
            if (NULL == result[-1][i]) {
               dmShow("error in dmNext() while getting the arity of attribute " result[0][i] ": ")
               dmShow("aborting dmNext()")
               return -1
            }
            result[-1][i] += 0
         }

         if (1 == result[-1][i]) {
            # multi-valued attributes;
            count = dmAPIGet("values," session "," query_id "," result[0][i])
            if (NULL == count) {
               dmShow("error in dmNext() while getting the arity of attribute " result[0][i] ": ")
               dmShow("aborting dmNext()")
               return -1
            }
            count += 0

            for (j = 0; j < count; j++) {
               value = dmAPIGet("get," session "," query_id "," result[0][i] "[" j "]")
               gsub(/[[:blank:]]+$/, "", value)
               result[1][i][j] = value
            }
         }
         else {
            # mono-valued attributes;
            value = dmAPIGet("get," session "," query_id "," result[0][i])
            gsub(/[[:blank:]]+$/, "", value)
            result[1][i] = value
         }
      }
   }
   dmShow("exiting dmNext()")
   return 0
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

function dmSelecta(session, dql_stmt, result       , query_id, row_counter, nb_attrs, i, is_repeating, count, j, value) {
# execute the DQL SELECT statement passed in dql_stmt and return the result set into the 2D array result (hence the "a" in dmSelecta but the name can also be interpreted as "select all at once");
# result[0][0..] contains the column names;
# result[1..][0..] contains the values, an array of repeating values if the attribute is repeating;
# result is empty in case of error;
# returns -1 in case of error and the number of rows in the result set if successful;
   dmShow("in dmSelecta(), dql_stmt=" dql_stmt)
   query_id = dmAPIGet("query," session "," dql_stmt)
   if (!query_id) {
      dmShow("Error calling query in dmSelecta()")
      dmShow("aborting dmSelecta()")
      return -1
   }
 
   # iterate through the result set;
   row_counter = 0 
   while (dmAPIExec("next," session "," query_id) > 0) {
      row_counter++
      nb_attrs = dmAPIGet("count," session "," query_id)
      if (NULL == nb_attrs) {
         dmShow("Error in dmSelecta() while retrieving the count of returned attributes: ")
         dmShow("aborting dmSelecta()")
         return -1
      }
      nb_attrs += 0
      for (i = 0; i < nb_attrs; i++) {
         if (1 == row_counter) {
            # get the attributes' names only once for the whole query;
            result[0][i] = dmAPIGet("get," session "," query_id ",_names[" i "]")
            if (NULL == result[0][i]) {
               dmShow("error in dmSelecta() while getting the attribute name at position " i ": ")
               dmShow("aborting dmSelecta()")
               return -1
            }

            is_repeating[i] = dmAPIGet("repeating," session "," query_id "," result[0][i])
            if (NULL == is_repeating[i]) {
               dmShow("error in dmSelecta() while getting the arity of attribute " result[0][i] ": ")
               dmShow("aborting dmSelecta()")
               return -1
            }
            is_repeating[i] += 0
         }

         if (1 == is_repeating[i]) {
            # multi-valued attributes;
            count = dmAPIGet("values," session "," query_id "," result[0][i])
            if (NULL == count) {
               dmShow("error in dmSelecta() while getting the arity of attribute " result[0][i] ": ")
               dmShow("aborting dmSelecta()")
               return -1
            }
            count += 0

            for (j = 0; j < count; j++) {
               value = dmAPIGet("get," session "," query_id "," result[0][i] "[" j "]")
               gsub(/[[:blank:]]+$/, "", value)
               result[row_counter][i][j] = value
            }
         }
         else {
            # mono-valued attributes;
            value = dmAPIGet("get," session "," query_id "," result[0][i])
            gsub(/[[:blank:]]+$/, "", value)
            result[row_counter][i] = value
         }
      }
   }
   dmShow("exiting dmSelecta()")
   return row_counter
}
 
# print the result of a select statement stored in array object with the structure described in dmSelecta() above;
function show_table(title, object      , i, j, max_col_length) {
   print title
   # determine maximum column lengths;
   # column headers;
   for (i = 0; i < length(object[0]); i++)
      max_col_length[i] = length(object[0][i])

   # data;
   for (i = 1; i < length(object); i++)
      for (j = 0; j < length(object[i]); j++)
         if (max_col_length[j] < length(object[i][j]))
            max_col_length[j] = length(object[i][j])

   # print column headers;
   for (i = 0; i < length(object[0]); i++)
      printf("%s%-*s", i > 0 ? "  " : "", max_col_length[i], object[0][i])
   printf("\n")

   # print data;
   for (i = 1; i < length(object); i++) {
      for (j = 0; j < length(object[i]); j++)
         printf("%s%-*s", j > 0 ? "  " : "", max_col_length[j], object[i][j])
      printf("\n")
   } 
}

function dmDisconnect(session   , status) {
# closes the given session;
# returns 1 if no error, 0 otherwise;
   dmShow("in dmDisconnect()")
   status = dmAPIExec("disconnect," session)
   if (!status)
      dmShow("Exception in dmDisconnect():")
   dmShow("exiting disconnect()")
   return status
}

