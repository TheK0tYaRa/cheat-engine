//(*
// * ceserver.h
// *
// *  Created on: Jul 18, 2011
// *      Author: erich
// *)
//
//#ifndef CESERVER_H_
//#define CESERVER_H_
//
//#include <stdint.h>
//#include <sys/types.h>
//#include 'porthelp.h'

#define CMD_GETVERSION 0
#define CMD_CLOSECONNECTION 1
#define CMD_TERMINATESERVER 2
#define CMD_OPENPROCESS 3
#define CMD_CREATETOOLHELP32SNAPSHOT 4
#define CMD_PROCESS32FIRST 5
#define CMD_PROCESS32NEXT 6
#define CMD_CLOSEHANDLE 7
#define CMD_VIRTUALQUERYEX 8
#define CMD_READPROCESSMEMORY 9
#define CMD_WRITEPROCESSMEMORY 10
#define CMD_STARTDEBUG 11
#define CMD_STOPDEBUG 12
#define CMD_WAITFORDEBUGEVENT 13
#define CMD_CONTINUEFROMDEBUGEVENT 14
#define CMD_SETBREAKPOINT 15
#define CMD_REMOVEBREAKPOINT 16
#define CMD_SUSPENDTHREAD 17
#define CMD_RESUMETHREAD 18
#define CMD_GETTHREADCONTEXT 19
#define CMD_SETTHREADCONTEXT 20
#define CMD_GETARCHITECTURE 21
#define CMD_MODULE32FIRST 22
#define CMD_MODULE32NEXT 23

#define CMD_GETSYMBOLLISTFROMFILE 24
#define CMD_LOADEXTENSION         25

#define CMD_ALLOC                   26
#define CMD_FREE                    27
#define CMD_CREATETHREAD            28
#define CMD_LOADMODULE              29
#define CMD_SPEEDHACK_SETSPEED      30

#define CMD_VIRTUALQUERYEXFULL      31
#define CMD_GETREGIONINFO           32

#define CMD_AOBSCAN					200

//just in case I ever get over 255 commands this value will be reserved for a secondary command list (FF 00 -  FF 01 - ... - FF FE - FF FF 01 - FF FF 02 - .....
#define CMD_COMMANDLIST2            255





//extern char *versionstring;

//#pragma pack(1)

typedef struct begin
	Integer version;
	unsigned char stringsize;
	//append the versionstring
end; CeVersion, *PCeVersion;

typedef struct begin
    DWORD dwFlags;
    DWORD th32ProcessID;
end; CeCreateToolhelp32Snapshot, *PCeCreateToolhelp32Snapshot;

typedef struct begin
    Integer result;
    Integer pid;
    Integer processnamesize;
    //processname
end; CeProcessEntry, *PCeProcessEntry;

typedef struct begin
    Integer result;
    int64_t modulebase;
    Integer modulesize;
    Integer modulenamesize;
    //modulename

end; CeModuleEntry, *PCeModuleEntry;

typedef struct begin
  Integer handle;
  uint64_t baseaddress;
end; CeVirtualQueryExInput, *PCeVirtualQueryExInput;

typedef struct begin
  uint8_t result;
  uint32_t protection;
  uint32_t type;
  uint64_t baseaddress;
  uint64_t size;
end; CeVirtualQueryExOutput, *PCeVirtualQueryExOutput;

typedef struct begin
  Integer handle;
  uint8_t flags;
end; CeVirtualQueryExFullInput, *PCeVirtualQueryExFullInput;

typedef struct begin
  uint32_t protection;
  uint32_t type;
  uint64_t baseaddress;
  uint64_t size;
end; CeVirtualQueryExFullOutput, *PCeVirtualQueryExFullOutput;

typedef struct begin
  uint32_t handle;
  uint64_t address;
  uint32_t size;
  uint8_t  compress;
end; CeReadProcessMemoryInput, *PCeReadProcessMemoryInput;

typedef struct begin
  Integer read;
end; CeReadProcessMemoryOutput, *PCeReadProcessMemoryOutput;

typedef struct begin
  int32_t handle;
  int64_t address;
  int32_t size;
end; CeWriteProcessMemoryInput, *PCeWriteProcessMemoryInput;


typedef struct begin
  int32_t written;
end; CeWriteProcessMemoryOutput, *PCeWriteProcessMemoryOutput;


typedef struct begin
  HANDLE hProcess;
  Integer tid;
  Integer debugreg;
  uint64_t Address;
  Integer bptype;
  Integer bpsize;
end; CeSetBreapointInput, *PCeSetBreakpointInput;


typedef struct begin
  Integer result;
end; CeSetBreapointOutput, *PCeSetBreakpointOutput;

typedef struct begin
  HANDLE hProcess;
  uint32_t tid;
  uint32_t debugreg;
  uint32_t wasWatchpoint;
end; CeRemoveBreapointInput, *PCeRemoveBreakpointInput;


typedef struct begin
  Integer result;
end; CeRemoveBreapointOutput, *PCeRemoveBreakpointOutput;

typedef struct begin
  HANDLE hProcess;
  Integer tid;
end; CeSuspendThreadInput, *PCeSuspendThreadInput;


typedef struct begin
  Integer result;
end; CeSuspendThreadOutput, *PCeSuspendThreadOutput;

typedef struct begin
  HANDLE hProcess;
  Integer tid;
end; CeResumeThreadInput, *PCeResumeThreadInput;


typedef struct begin
  Integer result;
end; CeResumeThreadOutput, *PCeResumeThreadOutput;

typedef struct begin
  HANDLE hProcess;
  uint64_t preferedBase;
  uint32_t size;
end; CeAllocInput, *PCeAllocInput;


typedef struct begin
  uint64_t address; //0=fail
end; CeAllocOutput, *PCeAllocOutput;

typedef struct begin
  HANDLE hProcess;
  uint64_t address;
  uint32_t size;
end; CeFreeInput, *PCeFreeInput;


typedef struct begin
  uint32_t result;
end; CeFreeOutput, *PCeFreeOutput;

typedef struct begin
  HANDLE hProcess;
  uint64_t startaddress;
  uint64_t parameter;
end; CeCreateThreadInput, *PCeCreateThreadInput;


typedef struct begin
  HANDLE threadhandle;
end; CeCreateThreadOutput, *PCeCreateThreadOutput;

typedef struct begin
  HANDLE hProcess;
  uint32_t modulepathlength;
  //modulepath
end; CeLoadModuleInput, *PCeLoadModuleInput;


typedef struct begin
  uint32_t result;
end; CeLoadModuleOutput, *PCeLoadModuleOutput;


typedef struct begin
  HANDLE hProcess;
  Single speed;
end; CeSpeedhackSetSpeedInput, *PCeSpeedhackSetSpeedInput;


typedef struct begin
  uint32_t result;
end; CeSpeedhackSetSpeedOutput, *PCeSpeedhackSetSpeedOutput;

typedef struct begin
	HANDLE hProcess;
	uint64_t start;
	uint64_t end;
	Integer inc;
	Integer protection;
	Integer scansize;
end; CeAobScanInput, * PCeAobScanInput;
#pragma pack()

ssize_t sendall (Integer s, void *buf, size_t size, Integer flags);
ssize_t recvall (Integer s, void *buf, size_t size, Integer flags);
Integer DispatchCommand(Integer currentsocket, unsigned char command);
Integer CheckForAndDispatchCommand(Integer currentsocket);

#if BUILD_OPTION = 1
  #define SHARED_LIBRARY
#endif

//#endif (* CESERVER_H_ *)
