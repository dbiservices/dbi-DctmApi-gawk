# test program for DctmAPI.awk and the interface dctm.c;
# Cesare Cervini
# dbi-services.com
# 5/2018
 
@include "DctmAPI.awk"
 
BEGIN {
   dmLogLevel = 1
 
   session = dmConnect("dmtest", "dmadmin" , "dmadmin")
   printf("dmConnect: session=%s\n", session)
   if (!session) {
      print("no session opened, exiting ...")
      exit(1)
   }
 
   printf "\n"
   dump = dmAPIGet("dump," session ",0900c35080008107")
   print("object 0900c35080008107 dumped:\n" dump)
 
   #printf "\n"
   #stmt = "update dm_document object set language_code = 'FR' where r_object_id = '0900c35080008107'"
   #status = dmExecute(session, stmt)
   #if (status)
      #print("dmExecute [" stmt "] was successful")
   #else
      #print("dmExecute [" stmt "] was not successful")
 
   printf "\n"
   stmt = "select r_object_id, object_name, owner_name, acl_domain, acl_name from dm_document enable(return_top 100)"
   status = dmSelecto(session, stmt, "r_object_id,object_name,owner_name,acl_domain,acl_name")
   if (status)
      print("dmSelecto [" stmt "] was successful")
   else
      print("dmSelecto [" stmt "] was not successful")
 
   status = dmSelecta(session, stmt, result)
   if (status) {
      print("dmSelecta [" stmt "] was successful")
      show_table("test selecta", result)
   }
   else
      print("dmSelecta [" stmt "] was not successful")
 
   printf "\n"
   stmt = "select count(*) from dm_document"
   status = dmSelecto(session, stmt,  "count(*)")
   if (status)
      print("dmSelect [" stmt "] was successful")
   else
      print("dmSelect [" stmt "] was not successful")
 
   printf "\n"
   status = dmDisconnect(session)
   if (status)
      print("successfully disconnected")
   else
      print("error while  disconnecting")
 
   printf "\n"
   status = dmAPIDeInit()
   if (status)
      print("successfully deInited")
   else
      print("error while  deInited")
 
   exit(0)
}

