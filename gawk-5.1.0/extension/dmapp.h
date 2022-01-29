/* $Id: dmapp.h,v 5.25 2003/05/01 16:51:29 afoster Exp $ */

/*
**
** Documentum DocuServer
** Confidential Property of Documentum, Inc.
** (c) Copyright Documentum, Inc., 1991-2002
** All rights reserved.
**
** dmapp.h - API interface to class library to Documentum Server
**
** This is a character based interface for using the Documentum class library.
** There are three main routines: dmAPIExec(), dmAPIGet(), dmAPISet() for executing
** methods, getting the values of attributes and setting values of attributes.
** These routines call the class library directly.
**
** From this interface you can create a session, run queries, create new
** documents, checkin results and basically anything else you can do through
** the class library.
**
** The interface is designed to work with character string representations of data
** to work with the widest variety of programming environments including those
** incorporated into word processors such as WordBasic in Word for Windows. 
**
*/

#ifndef _dmapp_
#define _dmapp_ 1

#if defined(WINDOWS)
#include <windows.h>
#endif

#if !defined(DM_EXTERNAL_ERROR_CODES_ONLY)

/* Various compiler "defines" needed for compilation under different
** environments.
*/
#ifndef NULL
#define NULL 0
#endif

/* The following is a list severity levels that can be returned
** in the special "_status" field and the "listmessage" method.
**
** Example:
**
**	int status;
**	status = atoi(dmAPIGet("get,current,last,_status"));
*/
#define  DM_OK		0
#define  DM_INFORMATION 0
#define  DM_TRACE	1        
#define  DM_WARNING	2
#define  DM_ERROR	3
#define  DM_FATAL	4


/* List of internal Documentum C++ classes used for specifying the
** object type in the id. These values are included in hex as part
** of the character representation of ids stored in the database.
*/

#define DM_SESSION     	1
#define DM_OBJECT      	2
#define DM_TYPE        	3
#define DM_COLLECTION  	4
#define DM_CONTAINMENT 	5
#define DM_CONTENT  	  6
#define DM_SYSOBJECT  	8
#define DM_DOCUMENT  	  9
#define DM_QUERY  	    10
#define DM_FOLDER  	    11
#define DM_CABINET  	  12
#define DM_ASSEMBLY   	13
#define DM_STORE  	    14
#define DM_FULLTEXT  	  15
#define DM_METHOD  	    16
#define DM_USER  	      17
#define DM_GROUP  	    18
#define DM_API  	      20
#define DM_TYPE_MANAGER 21
/* Composite Removal - AF          */
/* #define DM_COMPOSITE  	22 */
/* End of Composite Removal - AF   */
#define DM_OUTPUTDEVICE 23
#define DM_ROUTER       24
#define DM_REGISTERED  	25
#define DM_QUEUE_ITEM  	27
#define DM_VERITY_COLL 	28
#define DM_EVENT  	    29
#define DM_VSTAMP  	    30
#define DM_INDEX  	    31
#define DM_SEQUENCE     32
#define DM_TRANSACTION_LOG  33
#define DM_FILE  	      34
#define DM_OTHERFILE  	35
#define DM_VERITY_INDEX 36
#define DM_INBOX  	    37
#define DM_REGISTRY  	  38
#define DM_FORMAT  	    39
#define DM_FILESTORE  	40
#define DM_NETSTORE  	  41
#define DM_LINKSTORE  	42
#define DM_LINKRECORD  	43
#define DM_DISTRIBUTEDSTORE     44
#define DM_REPLICA_RECORD       45
#define DM_TYPE_INFO  	        46
#define DM_DUMP_RECORD          47
#define DM_DUMP_OBJECT_RECORD  	48
#define DM_LOAD_RECORD          49
#define DM_LOAD_OBJECT_RECORD  	50
#define DM_CHANGE_RECORD   51
#define DM_BLOB_TICKET     52
#define DM_STAGED_DOCUMENT  	53
#define DM_DIST_COMP_RECORD  	54
#define DM_RELATION  	     55
#define DM_RELATIONTYPE    56
#define DM_LOCATION  	     58
#define DM_FULLTEXT_INDEX  59
#define DM_DOCBASE_CONFIG  60
#define DM_SERVER_CONFIG   61
#define DM_MOUNT_POINT   62
#define DM_DOCBROKER  	 63
#define DM_BLOBSTORE  	 64  
#define DM_NOTE  	       65
#define DM_REMOTESTORE   66
#define DM_REMOTETICKET  67
#define DM_DOCBASEID_MAP 68
#define DM_ACL		       69
#define DM_POLICY       70
#define DM_REFERENCE    71
#define DM_RECOVERY     72
#define DM_IPKG         73
#define DM_WITEM        74
#define DM_BPROCESS     75
#define DM_ACTIVITY     76
#define DM_WORKFLOW     77
#define DM_DD_INFO      78
#define DM_NLS_DD_INFO  79
#define DM_DOMAIN       80
#define DM_AGGR_DOMAIN  81
#define DM_EXPRESSION   82
#define DM_LITERAL_EXPR 83
#define DM_BUILTIN_EXPR 84
#define DM_FUNC_EXPR    85
#define DM_COND_EXPR    86
#define DM_COND_ID_EXPR 87
#define DM_EXPR_CODE    88
#define DM_KEY          89
#define DM_VALUE_ASSIST 90
#define DM_VALUE_LIST   91
#define DM_VALUE_QUERY  92
#define DM_VALUE_FUNC   93
#define DM_FEDERATION   94
#define DM_AUDIT_TRAIL  95
#define DM_EXTERNALSTORE_TAG      96
#define DM_EXTERNALSTORE_FILE_TAG 97
#define DM_EXTERNALSTORE_URL_TAG  98
#define DM_EXTERNALSTORE_FREE_TAG 99
#define DM_SUBCONTENT            100
#define DM_FOREIGN_KEY           101
#define DM_ALIAS_SET             102
#define DM_PLUGIN		 103
#define DM_PARTITION_SCHEME      104


#define DM_DOCUWORKS  128  
/* All docuworks side objs w/ this type */

/* Permission constants for sysobj security. These are found
** in the "owner_permit", "group_permit" and "world_permit"
** attributes.
**
** Example:
**
**	int permit;
**	permit  atoi(dmAPIGet("get,current,last,owner_permit"));
*/
#define DM_PERMIT_NULL   	0
#define DM_PERMIT_NONE   	1
#define DM_PERMIT_BROWSE 	2
#define DM_PERMIT_READ   	3
#define DM_PERMIT_NOTE   	4
#define DM_PERMIT_VERSION	5
#define DM_PERMIT_WRITE  	6
#define DM_PERMIT_DELETE 	7

/* user_state constants */
#define DM_USER_ACTIVE 		0
#define DM_USER_INACTIVE 	1 
#define DM_USER_LOCKED 		2
#define DM_USER_LOCKED_INACTIVE 3

/* client_capability constants */
#define CLIENT_CONSUMER		1
#define CLIENT_CONTRIBUTOR	2
#define CLIENT_COORDINATOR	4
#define CLIENT_CUSTODIAN	8 


/* Parsing API commands.  The dmAPIDescribe call describes an
** API command and return its type (Get, Set, Exec) and a value
** reflecting the method name. Below are the call types and some
** special API methods.
*/
#define DM_GET			0
#define DM_SET 			1
#define DM_EXEC			2
#define DM_OTHER		3
#define DM_CMD_get 	 	100
#define DM_CMD_getmessage	123
#define DM_CMD_connect		126
#define DM_CMD_disconnect	152
#define DM_CMD_quit	    	160
#define DM_CMD_anyevents	178
#define DM_CMD_shutdown	    	185

/* Basic constants and types. The following are the basic Documentum
** datatypes of the attributes stored in the database. These can
** be described using the special "_datatype" attribute.
**
** Example:
**
**	int datatype;
**	datatype = atoi(dmAPIGet("get,current,last,_datatype[0]"));
*/
#define DM_BOOLEAN	0 		 
#define DM_INTEGER	1
#define DM_STRING	2 		 
#define DM_ID	 	3
#define DM_TIME	 	4
#define DM_DOUBLE	5

#define DM_TINYINT	6 // Used internally. When saved to dm_type, it is DM_INTEGER, with length 1.
#define DM_SMALLINT	7 // Used internally. When saved to dm_type, it is DM_INTEGER, with length 2.

#define DM_UNDEFINED	8


#endif /* !defined(DM_EXTERNAL_ERROR_CODES_ONLY) */
/* ----------------------------------------- */
/* Constants and types for external programs */
/* See documentation for complete details    */
/* ----------------------------------------- */

#if defined(unix)
# define MAX_PROCESS_RETURN_CODE 255
#else
# include <limits.h> /* get ULONG_MAX */
# define MAX_PROCESS_RETURN_CODE ULONG_MAX
#endif

/* ----- GENERIC ERRORS ----- */
#define DM_EXT_APP_SUCCESS             0
#define DM_EXT_APP_UNEXPECTED_ERROR    MAX_PROCESS_RETURN_CODE
#define DM_EXT_APP_NOT_IMPLEMENTED     (MAX_PROCESS_RETURN_CODE -  1)
#define DM_EXT_APP_OS_ERROR            (MAX_PROCESS_RETURN_CODE -  2)

/* ----- PASSWORD CHECKING ERRORS ----- */
#define DM_CHKPASS_ACCOUNT_LOCKED      (MAX_PROCESS_RETURN_CODE -  11)
#define DM_CHKPASS_NO_RIGHT            (MAX_PROCESS_RETURN_CODE -  5)
#define DM_CHKPASS_ACCOUNT_DROPPED     (MAX_PROCESS_RETURN_CODE -  6)
#define DM_CHKPASS_ACCOUNT_EXPIRED     (MAX_PROCESS_RETURN_CODE -  7)
#define DM_CHKPASS_PASSWORD_EXPIRED    (MAX_PROCESS_RETURN_CODE -  8)
#define DM_CHKPASS_PASSWORD_STALE      (MAX_PROCESS_RETURN_CODE -  9)
#define DM_CHKPASS_BAD_LOGIN           (MAX_PROCESS_RETURN_CODE - 10)

/* ----- LDAP PASSWORD CHECKING ERRORS ----- */
#define DM_CHKPASS_LDAP_NOSEARCHBASE   (MAX_PROCESS_RETURN_CODE -  12)
#define DM_CHKPASS_LDAP_DOWN           (MAX_PROCESS_RETURN_CODE -  13)
#define DM_CHKPASS_LDAP_SEARCH         (MAX_PROCESS_RETURN_CODE -  14)
#define DM_CHKPASS_LDAP_MULTIPLE_UID   (MAX_PROCESS_RETURN_CODE -  15)
#define DM_CHKPASS_LDAP_NOENTRY        (MAX_PROCESS_RETURN_CODE -  16)
#define DM_CHKPASS_LDAP_BIND           (MAX_PROCESS_RETURN_CODE -  17)

/* ----- ASSUME USER ERRORS ----- */

#define DM_ASSUME_USER_SYSTEM_ERROR    (MAX_PROCESS_RETURN_CODE - 3)
#define DM_ASSUME_USER_TIMEOUT_EXPIRED (MAX_PROCESS_RETURN_CODE - 5)
#define DM_ASSUME_USER_COMMAND_BUF_FULL (MAX_PROCESS_RETURN_CODE - 18)

/* ----- CHANGE PASSWORD ERRORS ----- */

#define DM_CHGPASS_PASSWORD_CRITERIA   (MAX_PROCESS_RETURN_CODE - 4)

/* ----- WORKFLOW external program return values. ----- */
#define DM_ROUTER_PRE_IGNORE_METHOD    (MAX_PROCESS_RETURN_CODE - 55)

/* ----- UPPER BOUND FOR USER DEFINED RETURN VALUES ---- */
#define DM_MAX_USER_RETURN_VALUE       (MAX_PROCESS_RETURN_CODE - 55)


#if !defined(DM_EXTERNAL_ERROR_CODES_ONLY)

/* Boolean expressions:
*/
#define dmBool		char
#define DM_TRUE		1
#define DM_FALSE	0

#if defined(MSDOS) && !defined(WIN32) && !defined(WIN64)
#define DM_EXPORT huge pascal
#else
#define DM_EXPORT
#endif

#ifdef __cplusplus
    extern "C" {
        int     DM_EXPORT dmAPIInit();
        int     DM_EXPORT dmAPIDeInit();
        char*   DM_EXPORT dmAPIDesc(const char *str, int *code, int *type, int *sess);
        int     DM_EXPORT dmAPIExec(const char *str);
        char*   DM_EXPORT dmAPIGet(const char *str);
        int     DM_EXPORT dmAPISet(const char *str, const char *arg);
        char*   DM_EXPORT dmAPIEval(const char *str, const char *arg);
	char*	DM_EXPORT dmGetPassword(const char *str);
	int	DM_EXPORT dmGetVersion( int *, int * );
    };
#else
        int     DM_EXPORT dmAPIInit();
        int     DM_EXPORT dmAPIDeInit();
        char*   DM_EXPORT dmAPIDesc();
        int     DM_EXPORT dmAPIExec();
        char*   DM_EXPORT dmAPIGet();
        int     DM_EXPORT dmAPISet();
        char*   DM_EXPORT dmAPIEval();
	char*	DM_EXPORT dmGetPassword();
	int	DM_EXPORT dmGetVersion();
#endif

#if defined (WIN32) || defined (WIN64) || defined(WIN16)
/* This is the definition of the message to be used for asynchronous 
** completion in the Windows world for asynchronous network calls
** These definitions MUST MATCH DMNETWRK.H or things WILL NOT WORK
*/
#define DM_ASYNC_COMPLETE WM_USER+967

/* The following structure DMNETWORKINFO will be passed to the callback
** function. This is a read-only structure.
*/

typedef struct dmNetworkInfo
{
  unsigned int	sizStruct;	 /* size of dmNetwrokInfo	  	   */
  unsigned int	callOrdinal;     /* One of the values in dmNetworkOrdinal  */
  char 		*statusString;	 /* Message for the user		   */
  void		*userData;	 /* This is the pointer from the setting   */
				 /* of network_callback_data		   */
  unsigned int	terminalCount;	 /* Number of MSGs in following array	   */
  MSG		*terminalMSGList; /* Array of MSG structures if the message */
				 /* from the system matches any in this    */
				 /* the callback function should return	   */
  int          timeticks;       /* number of milliseconds request has been*/
                                 /* active                                 */
} DMNETWORKINFO;

/* The following structure DMNETWORKRESULT will be passed to the callback
** the callback should fill this out based on the what happens
*/

typedef struct dmNetworkResult
{
  unsigned int	sizStruct;	 /* size of dmNetworkResult		   */
  int		haveLastMSG;	 /* When TRUE the lastMsg field will 	   */
				 /* contain the last message from the 	   */
				 /* message queue.			   */
  MSG		lastMSG;	 /* Contains the last message from the	   */
				 /* message queue			   */
} DMNETWORKRESULT;

/* The following is the definition of the return values from the callback
** function. If 0 is returned, it assumed that async request competed
** if -1 is returned then the request is cancelled.
*/
typedef enum { dmNR_OK = 0, dmNR_Cancel = -1 } dmNetworkReturn;

typedef int dmNetworkCallbackFunc(
			DMNETWORKRESULT	*result,
			DMNETWORKINFO	*info
				);
#endif


/* Connection Callbacks
**
** The following callbacks allow the application to be informed
** when a new subconnection is being made, successfully made,
** or failed to made.  
**
** First of all, to enable the connection callbacks, the following
** attribute needs to be set to T.
**    sessionconfig.connect_callback_enabled (default is F)
**
** 1) dmNewConnectCallbackFunc() can be defined to track when the
**    dmcl establishes new subconnections to docbase servers. 
**    These type of callbacks and client_data can be set through
**
**    sessionconfig.new_connection_callback (int repeating)
**    sessionconfig.new_connection_data (int repeating)
**
** 2) dmConnectSuccessCallbackFunc() cal be defined to track
**    when the dmcl establishes new subconnections to docbase
**    servers successfully.
**    These type of callbacks and client_data can be set through
**
**    sessionconfig.connect_success_callback (int repeating)
**    sessionconfig.connect_success_data (int repeating)
**
** 3) dmConnectFailureCallbackFunc() can be defined to capture
**    logon failures on dmcl attempts to establish subconnections.
**    In this callback, the credential information can be prompted 
**    and set into DM_CONNECT_INFO* (docbase and username can not
**    be changed). The dmcl will re-attempt the login based on 
**    user's input after the callback returns dmCR_OK.
**    These type of callbacks and client_data can be set through
**
**    sessionconfig.connect_failure_callback (int repeating)
**    sessionconfig.connect_failure_data (int repeating)
**
*/

/* Connect callback return status */
typedef enum {
  dmCR_OK = 0, 
  dmCR_FAIL = 1
} DM_CALLBACK_RETURN;

/* Connect info usage */
typedef enum {
  dmIU_USE_ONCE = 0,      /* Connect info is used once */
  dmIU_USE_AS_DEFAULT = 1 /* Connect info replaces the default */
} DM_INFO_USAGE;

/* Connect callback retry info */
typedef struct dmConnectInfo
{
  char          docbase[256];     /* Read only */
  char          username[128];    /* Read only */
  char          password[128];
  char          user_arg1[128];
  char          user_arg2[128];
  DM_INFO_USAGE info_usage;       /* default is dmIU_USE_ONCE */
} DM_CONNECT_INFO;

/*
** New connect callback retry info
** This structure is needed to handle int passwords
** while preserving backward compatibility.
*/
typedef struct dmConnectInfoExt
{
  char          docbase[256];     /* Read only */
  char          username[128];    /* Read only */
  char          password[128];
  char          user_arg1[128];
  char          user_arg2[128];
  DM_INFO_USAGE info_usage;       /* default is dmIU_USE_ONCE */
  char          token[8192];
  char          secure_flag[128];
} DM_CONNECT_INFO_EXT;

#ifdef __cplusplus
/* 
** New connect callback prototype
*/
typedef DM_CALLBACK_RETURN dmNewConnectCallbackFunc(
                             const DM_CONNECT_INFO connect_info,
                             void *client_data);

/*
** Connect success callback prototype
*/
typedef DM_CALLBACK_RETURN dmConnectSuccessCallbackFunc(
                             const DM_CONNECT_INFO connect_info,
                             void *client_data);

/*
** Connect failure callback prototype (DEPRECATED)
**
** What can be changed:
**   connect_info->password
**   connect_info->user_arg1 (this stores Domain name in case of NT)
**   connect_info->user_arg2
**
** What to return:
**   returns dmCR_OK to re-attempt the login.
**   returns dmCR_FAIL to cancel the retry.
*/
typedef DM_CALLBACK_RETURN dmConnectFailureCallbackFunc(
                             DM_CONNECT_INFO *connect_info,
                             void *client_data);

/*
** New connect failure callback prototype
**
** What can be changed:
**   connect_info->token
**   connect_info->user_arg1 (this stores Domain name in case of NT)
**   connect_info->user_arg2
** Both fields token and password contain the password/token used to authenticate.
** However, the password is limited to 128 characters so it may be truncated. New
** programs should use the token field.
**
** What to return:
**   returns dmCR_OK to re-attempt the login.
**   returns dmCR_FAIL to cancel the retry.
*/
typedef DM_CALLBACK_RETURN dmConnectFailureCallbackFuncExt(
                             DM_CONNECT_INFO_EXT *connect_info,
                             void *client_data);

#else
/* 
** New connect callback prototype
*/
typedef DM_CALLBACK_RETURN dmNewConnectCallbackFunc(
                             /*const DM_CONNECT_INFO connect_info,
                             void *client_data*/);

/*
** Connect success callback prototype
*/
typedef DM_CALLBACK_RETURN dmConnectSuccessCallbackFunc(
                             /*const DM_CONNECT_INFO connect_info,
                             void *client_data*/);

/*
** Connect failure callback prototype
**
** What can be changed:
**   connect_info->password
**   connect_info->user_arg1 (this stores Domain name in case of NT)
**   connect_info->user_arg2
**
** What to return:
**   returns dmCR_OK to re-attempt the login.
**   returns dmCR_FAIL to cancel the retry.
*/
typedef DM_CALLBACK_RETURN dmConnectFailureCallbackFunc(
                             /*DM_CONNECT_INFO *connect_info,
                             void *client_data*/);

/*
** New connect failure callback prototype
**
** What can be changed:
**   connect_info->token
**   connect_info->user_arg1 (this stores Domain name in case of NT)
**   connect_info->user_arg2
** Both fields token and password contain the password/token used to authenticate.
** However, the password is limited to 128 characters so it may be truncated. New
** programs should use the token field.
**
** What to return:
**   returns dmCR_OK to re-attempt the login.
**   returns dmCR_FAIL to cancel the retry.
*/
typedef DM_CALLBACK_RETURN dmConnectFailureCallbackFuncExt(
                             /*DM_CONNECT_INFO_EXT *connect_info,
                             void *client_data*/);

#endif /* __cplusplus */

/* DMCL trace callback
**
** This callback allows the application to be informed when a line of
** API or RPC tracing output is generated by the DMCL.  The callback must
** provide the address of a C function, it can optionally provide
** information required to invoke a static Java method.
**
** The trace callback is set through
**
**    apiconfig.trace_callback (int)
**
** A C function that uses Java JNI is required to invoke any 
** Java method specified by java_class and java_method.  It is recommended
** that the DFC method registerTraceCallback be used to register a
** static Java method trace callback.
*/

typedef struct dmTraceCallback
{
  void         *c_callback;     /* address of a dmTraceCallbackFcn function */
  void         *java_vm;
  void         *java_class;     /* global reference to class as returned */
                                /* by JNI NewGlobalRef.*/
  void         *java_method;    /* jmethodID as returned */
                                /* by JNI GetStaticMethodID. */

} DM_TRACE_CALLBACK;

typedef struct dmTraceCallbackInfo
{
  char          category[32];   /* category of trace message, either API or RPC */
  char          message[1024];  /* contents of the trace */
  double        duration;       /* approximate time to complete current operation */
  int           rpc_count;      /* running count of RPC calls */

} DM_TRACE_CALLBACK_INFO;

#ifdef __cplusplus

typedef DM_CALLBACK_RETURN dmTraceCallbackFcn (DM_TRACE_CALLBACK *callback,
                                               DM_TRACE_CALLBACK_INFO *callback_info);

#else

typedef DM_CALLBACK_RETURN dmTraceCallbackFcn (/* DM_TRACE_CALLBACK *callback,
                                                  DM_TRACE_CALLBACK_INFO *callback_info */ );
#endif /* __cplusplus */

#endif /* !defined(DM_EXTERNAL_ERROR_CODES_ONLY) */

#endif
