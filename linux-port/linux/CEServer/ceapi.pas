unit CEapi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, unixtype, Contnrs, TEMPlibc

//function OpenProcess(pid: dword): THandle; stdcall; external 'linux/ceserver/libs/api.so'; overload;

 {api.h}

 (*
 * api.h
 *
 *  Created on: Jul 21, 2011
 *      Author: erich
 *)

//{$if }ndef API_H_
//#define API_H_

//#include <stdint.h>
//#include <pthread.h>
//#include <sys/queue.h>

//#include 'porthelp.h'  { #todo : dewit }
  //,CEcontext //#include 'context.h'

//#include <sys/ptrace.h>

{$ifdef ANDROID}
  #include<android/log.h>
{$endif}
(*

{$if } defined(__arm__) || defined(__ANDROID__)
#include <linux/user.h>
#{$else}
#include <sys/user.h>
{$endif}
*)

{$ifdef HAS_LINUX_USER_H}
  //#include <linux/user.h>  { #todo : dewit }
{$else}
  //#include <sys/user.h>
{$endif}
  ;

const
  VQE_PAGEDONLY = 1;
  VQE_DIRTYONLY = 2;
  VQE_NOSHARED  = 4;

type
  PModuleListEntry = ^ModuleListEntry;
  ModuleListEntry = record
    baseAddress: culonglong;
    moduleSize:  Integer;
    moduleName:  ^char;
  end;

  PProcessListEntry = ^ProcessListEntry;
  ProcessListEntry = record
    PID:         Integer;
    ProcessName: ^char;
  end;

//#pragma pack(1)

  PHBP_RESOURCE_INFO = ^HBP_RESOURCE_INFO;
  HBP_RESOURCE_INFO = record
    num_brps:   uint8_t; //number of instruction breakpoints
    num_wrps:   uint8_t; //number of data breakpoints
    wp_len:     uint8_t; //max length of a data breakpoint
    debug_arch: uint8_t; //debug architecture
  end;

{$ifdef CPUARM}
(*  struct user_pt_regs
  {
    long regs[18];
  };

  struct user_hwdebug_state {
   __u32 dbg_info;
   struct {
   __u32 addr;
   __u32 ctrl;
   } dbg_regs[16];
  };

#define NT_ARM_HW_WATCH 0x403
#define PTRACE_GETREGSET 0x4204
#define PTRACE_SETREGSET 0x4205
*)
{$endif}

  PDebugEvent = ^DebugEvent;
  DebugEvent = record
    debugevent: Integer;
    threadid:   int64_t;        { #note -cunion : I have no idea if i understood how to convert those }
    case address: uint64_t of //TRAP: Address that caused trap
      0: (maxBreakpointCount:   uint8_t); //Number of execute breakpoints this system supports at most
      1: (maxWatchpointCount:   uint8_t);
      2: (maxSharedBreakpoints: uint8_t); //If the system uses the same kind of breakpoints for execute and watchpoints. 0 otherwise
      //CreateProcess
    //other data
  end;

  DebugEventQueueElement = record
    entries: TQueue;  //TAILQ_ENTRY(DebugEventQueueElement) entries;
    de:      DebugEvent;
  end;

//#pragma pack()

  debugEventQueueHead = TQueue;  //TAILQ_HEAD(debugEventQueueHead, DebugEventQueueElement);


  PThreadData = ^ThreadData;
  ThreadData = record
    tid:             Integer;
    isPaused:        Integer;
    suspendCount:    Integer;
    suspendedDevent: DebugEvent; //debug event to be injected when resumed
  end;

  PProcessData = ^ProcessData;
  ProcessData = record
    ReferenceCount: Integer;
    pid:   Integer;
    mapfd: Integer; //file descriptor for /proc/pid/maps
    path:  ^char;
    maps:  ^char;
    mem:   Integer;
    hasLoadedExtension:      Integer; //set to true if the ceserver extension has been loaded in this process
    neverForceLoadExtension: Integer; //set to true if you don't want to force load the module (if it's loaded, use it, but don't use the injection method)
    extensionMutex: pthread_mutex_t;
    extensionFD:    Integer; //socket to communicate with the target

    isDebugged:       Integer; //if this is true no need to attach/detach constantly, BUT make sure the debugger thread does do it's job
    debuggerThreadID: pthread_t;

    threadlist:    PThreadData;
    threadlistmax: Integer;
    threadlistpos: Integer;

    debuggedThreadEvent: DebugEvent;

    debuggerServer: Integer; //sockets for communicating with the debugger thread by local threads
    debuggerClient: Integer;




    debugEventQueueMutex: pthread_mutex_t; //probably not necessary as all queue operations are all done in the debuggerthread of the process

    r: record
      debugEventQueue: debugEventQueueHead;
    end;
  end;



//#pragma pack(1)
  PRegionInfo = ^RegionInfo;
  RegionInfo = record
    baseaddress: uint64_t;
    size:        uint64_t;
    protection:  uint32_t;
    &type:        uint32_t;
  end;
//#pragma pack()

{$if defined(CPUi386) or defined(CPUx86_64)}
  PregDR6 = ^regDR6;
  regDR6 = record
    case value: uintptr_t of
      1: (B0:UInt);
      1: (B1:UInt);
      1: (B2:UInt);
      1: (B3:UInt);
      9: (Reserved:UInt);
      1: (BD:UInt);
      1: (BS:UInt);
      1: (BT:UInt);
  end;// __attribute__((__packed__)) regDR6,*PregDR6;
{$endif}





procedure CloseHandle(h: THandle);
function Process32Next(hSnapshot: THandle; processentry: PProcessListEntry): CBool;
function Process32First(hSnapshot: THandle; processentry: PProcessListEntry): CBool;
function CreateToolhelp32Snapshot(dwFlags: DWORD; th32ProcessID: DWORD):THandle;
function OpenProcess(pid: DWORD):THandle;
function VirtualQueryEx(hProcess: THandle; lpAddress: Pointer; rinfo: PRegionInfo; mapsline: PChar): Integer;
function VirtualQueryExFull(hProcess: THandle; flags: pcuint32; rinfo: PRegionInfo; count: pcuint32): Integer;
function ReadProcessMemory(hProcess: THandle; lpAddress: Pointer; buffer: Pointer; size: Integer): Integer;
function WriteProcessMemory(hProcess: THandle; lpAddress: Pointer; buffer: Pointer; size: Integer): Integer;

function StartDebug(hProcess: THandle): Integer;
function StopDebug(hProcess: THandle): Integer;

function WaitForDebugEventNative(p: PProcessData; devent: PDebugEvent; tid: Integer; timeout: Integer): Integer;
function WaitForDebugEvent(hProcess: THandle; devent: PDebugEvent; timeout: Integer): Integer;
function ContinueFromDebugEvent(hProcess: THandle; tid: Integer; ignoresignal: Integer): Integer;
function GetDebugPort(hProcess: THandle): Integer;

function SetBreakpoint(hProcess: THandle; tid: Integer; debugreg: Integer; address: Pointer; bptype: Integer; bpsize: Integer): Integer;
function RemoveBreakpoint(hProcess: THandle; tid: Integer; debugreg: Integer; wasWatchpoint: Integer): Integer;

function SuspendThread(hProcess: THandle; tid: Integer): Integer;
function ResumeThread(hProcess: THandle; tid: Integer): Integer;

function GetThreadContext(hProcess: THandle; tid: Integer; Context: PCONTEXT; &type: Integer): Integer;
function SetThreadContext(hProcess: THandle; tid: Integer; Context: PCONTEXT; &type: Integer): Integer;

function FindThreadDebugEventInQueue(p: PProcessData; tid: Integer): PDebugEvent;
procedure AddDebugEventToQueue(p: PProcessData; devent: PDebugEvent);
function RemoveThreadDebugEventFromQueue(p: PProcessData; tid: Integer): Integer;

procedure initAPI();

type
  debugsocketmutex: pthread_mutex_t; //extern pthread_mutex_t debugsocketmutex;

{$ifdef android}
const
  LOG_TAG = 'CESERVER' // #define LOG_TAG 'CESERVER'
  { #todo : what } // #define LOGD(fmt, args...) __android_log_vprint(ANDROID_LOG_DEBUG, LOG_TAG, fmt, ##args)
{$endif}

{ #todo : what } // Integer debug_log(const char * format , ...);
function safe_ptrace(request: Integer; pid: pid_t; addr: Pointer; data: Pointer): clong; // void * addr; void * data
extern Integer MEMORY_SEARCH_OPTION;
extern Integer ATTACH_PID;
extern unsigned char SPECIFIED_ARCH;
{$endif} (* API_H_ *)

 {}

implementation

{api.c} // ran it through OpenC2Pas from 2002 xD

(*
 * api.c
 *
 *  Created on: Jul 20, 2011
 *      Author: erich
 *
 *      This unit will implement the api's CE uses
 *      This will be the main point of interest when porting to another system
 *)

//#define _XOPEN_SOURCE 500

//todo for in the far future: Hook syscalls

const _FILE_OFFSET_BITS = 64;
{$define _LARGEFILE64_SOURCE}

//#include <stdio.h>
//#include <pthread.h>

//#include <sys/mman.h>


//#include <stddef.h>
//#include <string.h>
//#include <stdlib.h>
//#include <stdarg.h>

//#include <stdint.h>
//#include <dirent.h>
//#include <sys/types.h>
//#include <sys/socket.h>
//#include <sys/stat.h>
//#include <sys/time.h>
//#include <fcntl.h>
//#include <unistd.h>

//#include <strings.h>

//#include <sys/mman.h>
//#include <sys/ptrace.h>
//#include <sys/wait.h>
//#include <sys/syscall.h>
//#include <signal.h>

//{$if }ndef __x86_64__
////#include <asm/signal.h>
//{$endif}


//#include <sys/eventfd.h>

//#include <errno.h>

//#include <semaphore.h>
//#include <sys/queue.h>
//#include <limits.h>

//#include <sys/ptrace.h>

//{$if }ndef __x86_64__
//#include <linux/elf.h>
////#include <linux/uio.h>
//{$endif}


//{$ifdef } __arm__
//  {$if }ndef __ANDROID__
//    #include <linux/user.h>
//  {$endif}
//{$endif}

const
//blatantly stolen from the kernel source
  PTRACE_GETHBPREGS = 29;
  PTRACE_SETHBPREGS = 30;

(* Breakpoint *)
  ARM_BREAKPOINT_EXECUTE = 0;

(* Watchpoints *)
  ARM_BREAKPOINT_LOAD  = 1;
  ARM_BREAKPOINT_STORE = 2;

(* Privilege Levels *)
  ARM_BREAKPOINT_PRIV = 1;
  ARM_BREAKPOINT_USER = 2;

(* Lengths *)
  ARM_BREAKPOINT_LEN_1 = $1;
  ARM_BREAKPOINT_LEN_2 = $3;
  ARM_BREAKPOINT_LEN_4 = $f;
  ARM_BREAKPOINT_LEN_8 = $ff;

function encode_ctrl_reg(mismatch: Integer; len: Integer; &type: Integer;
  privilege: Integer; enabled: Integer): CUInt;
begin
  Result := (mismatch << 22) or (len << 5) or (&type << 3) or (privilege << 1) or enabled;
end;

{$ifndef ANDROID}
  {$if defined(CPUi386) or defined(CPUX86_64)}
    //#include <sys/user.h>      { #todo : dewit }
  {$endif}
{$endif}


(*
#include 'api.h'        { #todo : dewit }
#include 'porthelp.h'
#include 'ceserver.h'
#include 'threads.h'
#include 'symbols.h'
#include 'context.h'     *)

//#include <vector>
type
  sem_DebugThreadEvent = sem_t;

  memorymutex      = pthread_mutex_t;
  debugsocketmutex = pthread_mutex_t;
//pthread_mutex_t mut_RPM;

type
  PProcessList = ^ProcessList;
  ProcessList = record
    ReferenceCount:      Integer;
    processListIterator: Integer;
    processCount:        Integer;
    processList:         PProcessListEntry;
  end;

typedef struct
begin
  Integer ReferenceCount;
  Integer moduleListIterator;
  Integer moduleCount;
  PModuleListEntry moduleList;
end; ModuleList, *PModuleList;

Integer VerboseLevel := 0;

Integer MEMORY_SEARCH_OPTION := 0;
Integer ATTACH_PID := 0;
unsigned char SPECIFIED_ARCH := 9;

//Implementation for shared library version ceserver.
Integer debug_log(const char * format , ...)
begin
  va_list list;
  va_start(list,format);
  Integer ret := vprintf(format,list);

  {$ifdef } __ANDROID__
    LOGD(format,list);
  {$endif}
  va_end(list);
  (* C2PAS: Exit *) Result := ret;
end;

//Implementation for consistency with Android Studio.
long safe_ptrace(Integer request, pid_t pid, void * addr, void * data)
begin
  Integer result;
  errno := 0;
  result := ptrace(request, pid, addr, data);
  if (errno <> 0) then
  begin
    debug_log('ptrace error(%d)!'#10'',errno);
  end;
  (* C2PAS: Exit *) Result := result;
end;

Integer WakeDebuggerThread()
begin

  sem_post((* C2PAS: RefOrBit? *)&sem_DebugThreadEvent);
end;

void mychildhandler(Integer signal, struct siginfo *info, void *context)
begin
  //only call re-entrant functions

  Integer orig_errno := errno;
  WakeDebuggerThread();
  errno := orig_errno;


end;

Integer GetDebugPort(hProcess: THandle)
//return the debugserver fd
begin
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    if (p.isDebugged) then
    begin
      (* C2PAS: Exit *) Result := p.debuggerServer;
    end;
  end;

  (* C2PAS: Exit *) Result := -1;

end;

Integer FindPausedThread(p: PProcessData)
(*
 * Scan the threadlist and return the threadid of the thread that is paused. Return 0 if no thread is paused
 *)
begin
  Integer i;
  for (i := 0; i<p.threadlistpos; i++)
    if (p.threadlist[i].isPaused) then
      (* C2PAS: Exit *) Result := p.threadlist[i].tid;

  (* C2PAS: Exit *) Result := 0;
end;

Integer getBreakpointCapabilities(tid: Integer, uint8_t *maxBreakpointCount, uint8_t *maxWatchpointCount, uint8_t *maxSharedBreakpoints)
//Only called when the thread is suspended
begin

  *maxBreakpointCount := 0;
  *maxWatchpointCount := 0;
  *maxSharedBreakpoints := 0;


{$ifdef } __arm__
  HBP_RESOURCE_INFO hwbpcap;

  memset((* C2PAS: RefOrBit? *)&hwbpcap, 0, sizeof(HBP_RESOURCE_INFO));
  if (safe_ptrace(PTRACE_GETHBPREGS, tid, 0, (* C2PAS: RefOrBit? *)&hwbpcap)=0) then
  begin
    debug_log('hwbpcap:'#10'');
    debug_log('debug architecture:                %d'#10'', hwbpcap.debug_arch);
    debug_log('number of instruction breakpoints: %d'#10'', hwbpcap.num_brps);
    debug_log('number of data breakpoints:        %d'#10'', hwbpcap.num_wrps);
    debug_log('max length of a data breakpoint:   %d'#10'', hwbpcap.wp_len);

    *maxBreakpointCount := hwbpcap.num_brps;
    *maxWatchpointCount := hwbpcap.num_wrps;
    *maxSharedBreakpoints := 0;

    (* C2PAS: Exit *) Result := 1;
  end
  {$else}
    (* C2PAS: Exit *) Result := 0;
{$endif}

{$ifdef } __aarch64__
  struct iovec iov;
  struct user_hwdebug_state hwd;
  memset((* C2PAS: RefOrBit? *)&hwd, 0, sizeof(hwd));

  iov.iov_base := (* C2PAS: RefOrBit? *)&hwd;
  iov.iov_len := sizeof(hwd);

  if (safe_ptrace(PTRACE_GETREGSET, tid, NT_ARM_HW_WATCH, (* C2PAS: RefOrBit? *)&iov)=0) then
  begin
    debug_log('NT_ARM_HW_WATCH: dbg_info=%x:'#10'', hwd.dbg_info);
    *maxWatchpointCount := hwd.dbg_info (* C2PAS: RefOrBit? *)&$f;
  end
  {$else}
    (* C2PAS: Exit *) Result := 0;

  iov.iov_base := (* C2PAS: RefOrBit? *)&hwd;
  iov.iov_len := sizeof(hwd);
  if (safe_ptrace(PTRACE_GETREGSET, tid, NT_ARM_HW_BREAK, (* C2PAS: RefOrBit? *)&iov)=0) then
  begin
    debug_log('NT_ARM_HW_BREAK: dbg_info=%x:'#10'', hwd.dbg_info);
    *maxBreakpointCount := hwd.dbg_info (* C2PAS: RefOrBit? *)&$f;
  end
  {$else}
    (* C2PAS: Exit *) Result := 0;

  (* C2PAS: Exit *) Result := 1;
{$endif}

{$if } defined(__i386__) then or defined(__x86_64__)
  *maxBreakpointCount := 0;
  *maxWatchpointCount := 0;
  *maxSharedBreakpoints := 4;
  (* C2PAS: Exit *) Result := 1;
{$endif}
end;

Integer StartDebug(hProcess: THandle)
begin
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    struct sigaction childactionhandler;
    if (p.isDebugged) then
    begin
      debug_log('Trying to start debugging a process that is already debugged'#10'');
      (* C2PAS: Exit *) Result := FALSE;
    end;

    //attach to each task
    //first get a threadlist
    InitializeProcessThreadlist(p);

    //setup an event
    memset((* C2PAS: RefOrBit? *)&childactionhandler, 0, sizeof(childactionhandler));
    childactionhandler.sa_handler := (void *)mychildhandler;
    childactionhandler.sa_flags := SA_SIGINFO;



    sigaction(SIGCHLD, (* C2PAS: RefOrBit? *)&childactionhandler, nil);




    //read the taskid's from /proc/pid/task
    char _taskdir[255];
    DIR *taskdir;

    sprintf(_taskdir, '/proc/%d/task', p.pid);

    taskdir := opendir(_taskdir);

    if (taskdir) then
    begin
      struct dirent *d;

      d := readdir(taskdir);
      while (d) do
      begin
        tid: Integer := atoi(d.d_name);

        if (tid) then
        begin
          ThreadData td;
          memset((* C2PAS: RefOrBit? *)&td, 0, sizeof(td));
          td.tid := tid;
          td.isPaused := 0;
          AddThreadToProcess(p, (* C2PAS: RefOrBit? *)&td);

          pthread_mutex_lock((* C2PAS: RefOrBit? *)&memorymutex); //so there's no ptrace_attach busy when attaching after opening and reading memory

          if (safe_ptrace(PTRACE_ATTACH, tid,0,0)<0) then
            debug_log('Failed to attach to thread %d'#10'', tid)
          {$else}
          begin
            DebugEvent createThreadEvent;



            if (p.isDebugged=0) then
            begin
              p.isDebugged := 1; //at least one made it...
              p.debuggedThreadEvent.threadid := 0; //none yet
              p.debuggerThreadID := pthread_self();

              socketpair(PF_LOCAL, SOCK_STREAM, 0, (* C2PAS: RefOrBit? *)&p.debuggerServer);

              //first event, create process
              DebugEvent createProcessEvent;

{$if } defined(__arm__) then or defined (__aarch64__)

              if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&createProcessEvent, tid, -1)) then
              begin
                //get the debug capabilities

                getBreakpointCapabilities(tid, (* C2PAS: RefOrBit? *)&createProcessEvent.maxBreakpointCount, (* C2PAS: RefOrBit? *)&createProcessEvent.maxWatchpointCount, (* C2PAS: RefOrBit? *)&createProcessEvent.maxSharedBreakpoints);



                safe_ptrace(PTRACE_CONT, createProcessEvent.threadid, 0,0);

                PThreadData _td := GetThreadData(p, createProcessEvent.threadid);

                if (_td) then
                  _td.isPaused := 0
                {$else}
                  debug_log('Invalid first debug thread'#10'');
              end
              {$else}
              begin
                debug_log('Failure waiting for create event');
                createProcessEvent.maxBreakpointCount := 0;
                createProcessEvent.maxWatchpointCount := 0;
                createProcessEvent.maxSharedBreakpoints := 4;
              end;
{$endif}

{$if } defined(__i386__) then or defined(__x86_64__)
              //4 breakpoints, hybrid
              createProcessEvent.maxBreakpointCount := 0;
              createProcessEvent.maxWatchpointCount := 0;
              createProcessEvent.maxSharedBreakpoints := 4;
{$endif}


              createProcessEvent.debugevent := -2; //create process
              createProcessEvent.threadid := p.pid;

              AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&createProcessEvent);

            end;

            createThreadEvent.debugevent := -1; //create thread event (virtual event)
            createThreadEvent.threadid := tid;
            AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&createThreadEvent);


           // p->debuggerThreadID=syscall(SYS_gettid);
          end;

          pthread_mutex_unlock((* C2PAS: RefOrBit? *)&memorymutex);

        end;

        d := readdir(taskdir);
      end;

      closedir(taskdir);

    end
    {$else}
    begin
      debug_log('Failure opening %s',_taskdir);
    end;


    (* C2PAS: Exit *) Result := p.isDebugged;

  end
  {$else}
  begin
    //printf("Invalid handle\n");
    (* C2PAS: Exit *) Result := FALSE;
  end;

end;

Integer SetBreakpoint(hProcess: THandle, tid: Integer, debugreg: Integer, void *address, Integer bptype, Integer bpsize)
(*
 * Sets a breakpoint of the specifed type at the given address
 * tid of -1 means ALL threads
 * bptype: 0 = Execute
 * bptype: 1 = write
 * bptype: 2 = read (only)
 * bptype: 3 = Read/Write
 *
 * returns TRUE if the breakpoint was set *
 *)
begin
  Integer result := FALSE;


  debug_log('SetBreakpoint(%d, %d, %d, %p, %d, %d)'#10'', hProcess, tid, debugreg, address, bptype, bpsize);
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);



    if (p.debuggerThreadID=pthread_self()) then
    begin

      Integer isdebugged := FindPausedThread(p);
      Integer wtid;
      DebugEvent de;



      debug_log('SetBreakpoint from debuggerthread'#10'');

      if (tid=-1) then
      begin
        Integer i,r;
        debug_log('Calling SetBreakpoint for all threads'#10'');

        for (i := 0; i<p.threadlistpos; i++)
        begin
          r := SetBreakpoint(hProcess, p.threadlist[i].tid, debugreg, address, bptype, bpsize);
          if (r) then
            result := TRUE; //at least one thread succeeded
        end;

      end
      {$else}
      begin
        PThreadData td := GetThreadData(p, tid);
        Integer wasPaused;

        if (td=nil) then //should NEVER happen
          (* C2PAS: Exit *) Result := FALSE;

        wasPaused := td.isPaused;

        debug_log('Calling setbreakpoint for thread :%d'#10'', tid);

        debug_log('isdebugged=%d'#10'', isdebugged);

        if (wasPaused=0) then
        begin
          //manual
          debug_log('Target thread wasn''t stopped yet'#10'');

          Integer k := 0;

          debug_log('td=%p'#10'', td);
          debug_log('td->isPaused=%d'#10'', td.isPaused);




          wtid := tid;
          while ((td) and (td.isPaused=0) and (k<10)) do
          begin
            debug_log('Not yet paused'#10'');
            syscall(__NR_tkill, tid, SIGSTOP);

            if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&de, tid, 100)) then
            begin
              wtid := de.threadid;
              break;
            end;
            k++;
          end;



          if (wtid <>tid) then
          begin
            debug_log('<<<================UNEXPECTED TID (wtid=%d tid=%d)================>>>'#10'', wtid, tid);
          end;

          debug_log('k=%d (number of tries)'#10'', k);

          if (k=10) then
          begin
            debug_log('Timeout when waiting for thread'#10'');
          end;
        end
        {$else}
        begin
          debug_log('The thread I wanted to break was already broken. Yeeeh'#10'');
          wtid := isdebugged;
        end;

        //debugging the given tid
        debug_log('Setting breakpoint in thread %d'#10'', wtid);
{$ifdef } __aarch64__
        struct user_pt_regs regset;

        struct iovec iov;

        memset((* C2PAS: RefOrBit? *)&regset, 0, sizeof(regset));
        memset((* C2PAS: RefOrBit? *)&iov, 0, sizeof(iov));
        iov.iov_base := (* C2PAS: RefOrBit? *)&regset;
        iov.iov_len := sizeof(regset);
        Integer i := safe_ptrace(PTRACE_GETREGSET, wtid, (void*)NT_PRSTATUS, (* C2PAS: RefOrBit? *)&iov);

        debug_log('iov.iov_len=%d'#10'', (Integer)iov.iov_len);  //272=64 bit app. 72=32 bit app
        debug_log('i=%d'#10'', i);

        //printf("pc=%lx\n", regset.pc);

        if (iov.iov_len=72) then
        begin
          debug_log('This is a 32 bit target. Most likely debugging will fail'#10'');
        end;

        debug_log('r0=%llx'#10'', regset.regs[0]);
        debug_log('r1=%llx'#10'', regset.regs[1]);
        debug_log('r2=%llx'#10'', regset.regs[2]);
        debug_log('r3=%llx'#10'', regset.regs[3]);



        struct user_hwdebug_state hwd;
        memset((* C2PAS: RefOrBit? *)&hwd, 0, sizeof(hwd));





        iov.iov_base := (* C2PAS: RefOrBit? *)&hwd;
        iov.iov_len := sizeof(hwd);
        i := safe_ptrace(PTRACE_GETREGSET, wtid, NT_ARM_HW_WATCH, (* C2PAS: RefOrBit? *)&iov);


        debug_log('iov.iov_len=%d'#10'', (Integer)iov.iov_len);  //272=64 bit app. 72=32 bit app
        debug_log('i=%d (%d)'#10'', i,errno);

        debug_log('hwd.dbg_info=%x'#10'', hwd.dbg_info);
        debug_log('hwd.dbg_regs[0].addr=%llx'#10'', hwd.dbg_regs[0].addr);
        debug_log('hwd.dbg_regs[0].ctrl=%x'#10'', hwd.dbg_regs[0].ctrl);

        iov.iov_base := (* C2PAS: RefOrBit? *)&hwd;
        iov.iov_len := sizeof(hwd);
        i := safe_ptrace(PTRACE_GETREGSET, wtid, NT_ARM_HW_BREAK, (* C2PAS: RefOrBit? *)&iov);


        debug_log('iov.iov_len=%d'#10'', (Integer)iov.iov_len);  //272=64 bit app. 72=32 bit app
        debug_log('i=%d (%d)'#10'', i,errno);

        debug_log('hwd.dbg_info=%x'#10'', hwd.dbg_info);
        debug_log('hwd.dbg_regs[0].addr=%llx'#10'', hwd.dbg_regs[0].addr);
        debug_log('hwd.dbg_regs[0].ctrl=%x'#10'', hwd.dbg_regs[0].ctrl);



        Integer btype := 0;
        Integer bplist := NT_ARM_HW_BREAK;

        if (bptype=0) then
        begin
          //execute bp
          bplist := NT_ARM_HW_BREAK;

          btype := ARM_BREAKPOINT_EXECUTE;
        end
        {$else}
        begin
          //watchpoint
          bplist := NT_ARM_HW_WATCH;
          if (bptype=1) then
            btype := ARM_BREAKPOINT_STORE
          {$else}
          if (bptype=2) then
            btype := ARM_BREAKPOINT_LOAD
          {$else}
          if (bptype=3) then
            btype := ARM_BREAKPOINT_STORE or ARM_BREAKPOINT_LOAD;

        end;

        i := safe_ptrace(PTRACE_GETREGSET, wtid, bplist, (* C2PAS: RefOrBit? *)&iov);

        hwd.dbg_regs[debugreg].addr := (uintptr_t)address;
        hwd.dbg_regs[debugreg].ctrl := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_4, btype, 0, 1);

        i := safe_ptrace(PTRACE_SETREGSET, wtid, bplist, (* C2PAS: RefOrBit? *)&iov);

        debug_log('set=%d'#10'',i);

        memset((* C2PAS: RefOrBit? *)&hwd, 0, sizeof(hwd));

        i := safe_ptrace(PTRACE_GETREGSET, wtid, NT_ARM_HW_WATCH, (* C2PAS: RefOrBit? *)&iov);

        debug_log('get: iov.iov_len=%d'#10'', (Integer)iov.iov_len);  //272=64 bit app. 72=32 bit app
        debug_log('i=%d'#10'', i);

        debug_log('hwd.dbg_info=%x'#10'', hwd.dbg_info);
        debug_log('hwd.dbg_regs[0].addr=%llx'#10'', hwd.dbg_regs[0].addr);
        debug_log('hwd.dbg_regs[0].ctrl=%x'#10'', hwd.dbg_regs[0].ctrl);

{$endif}

{$ifdef } __arm__
    //hwbps
        unsigned long long val;
        Integer bpindex := 1+(2*debugreg);



        debug_log('PTRACE_GETHBPREGS=%d'#10'',PTRACE_GETHBPREGS);


        val := 0;

        if (safe_ptrace(PTRACE_GETHBPREGS, wtid, 0, (* C2PAS: RefOrBit? *)&val)=0) then
        begin
          Integer i;
          unsigned Integer hwbpreg;
          debug_log('BPREG0 (Info)=%x'#10'', val);

          debug_log('Setting bp address'#10'');



          if (bptype=0) then
          begin
            //execute
            void *rv := nil;
           // safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex, &rv);
           // safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex+1, &rv);


            i :=safe_ptrace(PTRACE_GETHBPREGS, wtid, bpindex, (* C2PAS: RefOrBit? *)&rv);
            debug_log('%d: Before: %d=%p'#10'', i, bpindex, rv);

            i := safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex, (* C2PAS: RefOrBit? *)&address);
            debug_log('i1=%d'#10'', i, hwbpreg);

            i := safe_ptrace(PTRACE_GETHBPREGS, wtid, bpindex, (* C2PAS: RefOrBit? *)&rv);
            debug_log('%d: After: %d=%p'#10'', i, bpindex, rv);


            //right now i'm not really sure how the breakpoint len is set and why it works in some cases and why not in other cases
            result := i=0;

            hwbpreg := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_4, ARM_BREAKPOINT_EXECUTE, 2, 1);
            if (safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex+1, (* C2PAS: RefOrBit? *)&hwbpreg)<0) then //according to my guess, this should usually work, but just in case...
            begin
              debug_log('f1'#10'');
              hwbpreg := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_2, ARM_BREAKPOINT_EXECUTE, 2, 1);
              if (safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex+1, (* C2PAS: RefOrBit? *)&hwbpreg)<0) then
              begin
                debug_log('f2'#10'');
                hwbpreg := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_1, ARM_BREAKPOINT_EXECUTE, 2, 1);
                if (safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex+1, (* C2PAS: RefOrBit? *)&hwbpreg)<0) then
                begin
                  debug_log('f3'#10'');
                  //last try, 8 ?
                  hwbpreg := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_8, ARM_BREAKPOINT_EXECUTE, 2, 1);
                  if (safe_ptrace(PTRACE_SETHBPREGS, wtid, bpindex+1, (* C2PAS: RefOrBit? *)&hwbpreg)<0) then
                  begin
                    debug_log('Failure to set breakpoint'#10'');
                    result := FALSE;
                  end;
                end;

              end;
            end;

            debug_log('bpindex=%d bpindex+1=%d'#10'', bpindex, bpindex+1);

            debug_log('hwbpreg=%x'#10'', hwbpreg);

            i := safe_ptrace(PTRACE_GETHBPREGS, wtid, bpindex+1, (* C2PAS: RefOrBit? *)&hwbpreg);
            debug_log('after=%x'#10'', hwbpreg);

          end
          {$else}
          begin
            //watchpoint
            //(negative)
            Integer btype;


            debug_log('watchpoint'#10'');

            i := safe_ptrace(PTRACE_SETHBPREGS, wtid, -bpindex, (* C2PAS: RefOrBit? *)&address);
            debug_log('i1=%d'#10'', i, hwbpreg);

            btype := 0;
            if (bptype=1) then
              btype := ARM_BREAKPOINT_STORE
            {$else}
            if (bptype=2) then
              btype := ARM_BREAKPOINT_LOAD
            {$else}
            if (bptype=3) then
              btype := ARM_BREAKPOINT_STORE or ARM_BREAKPOINT_LOAD;

            hwbpreg := encode_ctrl_reg(0, ARM_BREAKPOINT_LEN_4, btype, 0, 1);
            i := safe_ptrace(PTRACE_SETHBPREGS, wtid, -(bpindex+1), (* C2PAS: RefOrBit? *)&hwbpreg);

            debug_log('-bpindex=%d -(bpindex+1)=%d'#10'', -bpindex, -(bpindex+1));
            debug_log('i=%d  (hwbpreg=%x)'#10'', i, hwbpreg);
            result := i=0;

          end;

        end
        {$else}
          debug_log('Failure getting the debug capability register for thread %d (%d)'#10'', wtid, errno);


{$endif}

{$if } defined(__i386__) then or defined(__x86_64__)
        //debug regs
        //PTRACE_SETREGS
        Integer r,r2;

        uintptr_t newdr7 := safe_ptrace(PTRACE_PEEKUSER, wtid, offsetof(struct user, u_debugreg[7]), 0);


        newdr7 := newdr7 or (1<<debugreg*2);

        if (bptype=2) then //x86 does not support read onlyhw bps
          bptype := 3;

        newdr7 := newdr7 or (bptype << (16+(debugreg*4))); //bptype

        debug_log('Setting DR7 to %x'#10'', newdr7);

        //bplen
        if (bpsize< := 1) then
          newdr7 := newdr7 or (0 << (18+(debugreg*4)))
        {$else}
        if (bpsize< := 2) then
          newdr7 := newdr7 or (1 << (18+(debugreg*4)))
        {$else}
          newdr7 := newdr7 or (3 << (18+(debugreg*4)));


        r := safe_ptrace(PTRACE_POKEUSER, wtid, offsetof(struct user, u_debugreg[debugreg]), address);
        r2 := safe_ptrace(PTRACE_POKEUSER, wtid, offsetof(struct user, u_debugreg[7]), newdr7);

        result := (r=0) and (r2=0);
        if ( not result) then
        begin
          debug_log('Failure setting breakpoint'#10'');
        end;

        debug_log('result=%d  (r=%d r2=%d)'#10'', result, r, r2);


{$endif}

        //store this breakpoint in the list


        if (wasPaused=0) then
        begin
          Integer r;

          debug_log('Continue self broken thread'#10'');

          if (de.debugevent <> SIGSTOP) then //in case a breakpoint or something {$else} happened before sigstop happened
          begin


            debug_log('Not a SIGSTOP. Adding to queue and leave suspended'#10'');
            AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&de);
            td.isPaused := 1; //mark as paused for other api's
          end
          {$else}
          begin

            r :=safe_ptrace(PTRACE_CONT, wtid, 0,0);
            debug_log('PTRACE_CONT=%d'#10'', r);

            td.isPaused := 0;
          end;
        end;
      end;

    //

      debug_log('end of SetBreakpoint reached. result=%d'#10'', result);


    end
    {$else}
    begin
      //not the debugger thread. Send a message to the debuggerthread to execute this command
      debug_log('SetBreakpoint from outside the debuggerthread. Waking debuggerthread'#10'');
      //setup a sb command
  #pragma pack(1)
      struct
      begin
        char command;
        hProcess: THandle;
        tid: Integer;
        debugreg: Integer;
        uint64_t address;
        Integer bptype;
        Integer bpsize;
      end; sb;
  #pragma pack()

      sb.command := CMD_SETBREAKPOINT;
      sb.hProcess := hProcess;
      sb.tid := tid;
      sb.debugreg := debugreg;
      sb.address := (uintptr_t)address;
      sb.bptype := bptype;
      sb.bpsize := bpsize;

      if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
      begin
        debug_log('Sending message to the debuggerthread'#10'');

        sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&sb, sizeof(sb), 0);
        WakeDebuggerThread();
        recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&result, sizeof(result), MSG_WAITALL);

        debug_log('Received reply from debugger thread: %d'#10'', result);


        pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);
      end;

    end;

  end
  {$else}
  begin
   // debug_log("Invalid handle\n");
  end;

  (* C2PAS: Exit *) Result := result;

end;

Integer RemoveBreakpoint(hProcess: THandle, tid: Integer, debugreg: Integer,Integer wasWatchpoint)
(*
 * Removes the breakpoint with the provided address
 *)
begin
  Integer result := FALSE;

  debug_log('RemoveBreakpoint(%d, %d, %d, %d)'#10'', hProcess, tid, debugreg, wasWatchpoint);
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    if (p.debuggerThreadID=pthread_self()) then
    begin
      Integer isdebugged := p.debuggedThreadEvent.threadid;
      Integer wtid;
      DebugEvent de;

      debug_log('Called from the debuggerthread itself'#10'');

      if (tid=-1) then
      begin
        Integer i;
        debug_log('Calling RemoveBreakpoint for all threads'#10'');
        for (i := 0; i<p.threadlistpos; i++)
        begin
          if (RemoveBreakpoint(hProcess, p.threadlist[i].tid, debugreg, wasWatchpoint)=TRUE) then
            result := TRUE;
        end;
      end
      {$else}
      begin
        debug_log('specific thread'#10'');

        PThreadData td := GetThreadData(p, tid);
        Integer wasPaused := td.isPaused;

        if (wasPaused=0) then
        begin
          //manual
          debug_log('Not currently paused'#10'');
          debug_log('Going to kill and wait for this thread'#10'');

          Integer k;


          k := 0;
          while ((td) and (td.isPaused=0) and (k<10)) do
          begin
            syscall(__NR_tkill, tid, SIGSTOP);
            if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&de, tid, 100)) then
              break;
            k++;
          end;

          wtid := de.threadid;


          debug_log('----AFTER WAIT----'#10'');

          debug_log('after wtid=%d'#10'', wtid);
          debug_log('^^^^AFTER WAIT^^^^'#10'');
        end
        {$else}
        begin
          debug_log('The thread I wanted to break was already broken. Yeeeh'#10'');
          wtid := isdebugged;
        end;

        //debugging the given tid
        debug_log('Removing breakpoint from thread %d'#10'', wtid);


{$ifdef } __arm__
        Integer bpreg := 0;
        Integer i,i2,i3;
        void *a := nil;

        Integer bpIndex := 1+(2*debugreg);

        debug_log('arm'#10'');

        if (wasWatchpoint) then
        begin
          i := safe_ptrace(PTRACE_SETHBPREGS, wtid, -bpIndex, (* C2PAS: RefOrBit? *)&bpreg);
          i2 := safe_ptrace(PTRACE_SETHBPREGS, wtid, -(bpIndex+1), (* C2PAS: RefOrBit? *)&bpreg);
        end
        {$else}
        begin
          i := safe_ptrace(PTRACE_SETHBPREGS, wtid, bpIndex, (* C2PAS: RefOrBit? *)&bpreg);
          i2 := safe_ptrace(PTRACE_SETHBPREGS, wtid, bpIndex+1, (* C2PAS: RefOrBit? *)&bpreg);
        end;



        debug_log('i1=%d'#10'', i);

        debug_log('i2=%d'#10'', i2);



        i3 := safe_ptrace(PTRACE_SETHBPREGS, wtid, 1, (* C2PAS: RefOrBit? *)&a);

        result := (i=0) and (i2=0) and (i3=0);
{$endif}

{$ifdef } __aarch64__
        Integer i;
        struct user_hwdebug_state hwd;
        struct iovec iov;

        memset((* C2PAS: RefOrBit? *)&hwd, 0, sizeof(hwd));
        memset((* C2PAS: RefOrBit? *)&iov, 0, sizeof(iov));
        iov.iov_base := (* C2PAS: RefOrBit? *)&hwd;
        iov.iov_len := sizeof(hwd);

        Integer bplist;

        if (wasWatchpoint) then
          bplist := NT_ARM_HW_WATCH
        {$else}
          bplist := NT_ARM_HW_BREAK;

        i := safe_ptrace(PTRACE_GETREGSET, wtid, bplist, (* C2PAS: RefOrBit? *)&iov);
        if (i <> 0) then
          debug_log('PTRACE_GETREGSET failed'#10'');

        hwd.dbg_regs[debugreg].addr := 0;
        hwd.dbg_regs[debugreg].ctrl := 0;

        i := safe_ptrace(PTRACE_SETREGSET, wtid, bplist, (* C2PAS: RefOrBit? *)&iov);
        if (i <>0) then
          debug_log('PTRACE_SETREGSET failed'#10'');

        result := i;
{$endif}

{$if } defined(__i386__) then or defined(__x86_64__)
        Integer r;
        uintptr_t dr7 := 0;
        debug_log('x86'#10'');

        dr7 := safe_ptrace(PTRACE_PEEKUSER, wtid, offsetof(struct user, u_debugreg[7]), 0);

        dr7(* C2PAS: RefOrBit? *)& := ~(3 << (debugreg*2)); //disable G# and L#
        dr7(* C2PAS: RefOrBit? *)& := ~(15 << (16+debugreg*4)); //set len and type for this debugreg to 0


        r := safe_ptrace(PTRACE_POKEUSER, wtid, offsetof(struct user, u_debugreg[debugreg]), 0);


        r := safe_ptrace(PTRACE_POKEUSER, wtid, offsetof(struct user, u_debugreg[7]), dr7);
        if (r=0) then
          result := TRUE
        {$else}
          debug_log('Failure removing breakpoint from thread %d'#10'', wtid);


{$endif}

        if (wasPaused=0) then
        begin
          Integer r;
          PThreadData td := GetThreadData(p, tid);

          debug_log('Continue self broken thread'#10'');

          if (de.debugevent <> SIGSTOP) then //in case a breakpoint or something {$else} happened before sigstop happened
          begin
            debug_log('Not a SIGSTOP. Adding to queue and leave suspended'#10'');
            AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&de);


            td.isPaused := 1;
          end
          {$else}
          begin
            r := safe_ptrace(PTRACE_CONT, wtid, 0,0);
            debug_log('PTRACE_CONT=%d'#10'', r);

            td.isPaused := 0;
          end;
        end;


      end;

    end
    {$else}
    begin
      debug_log('Called from a secondary thread'#10'');
#pragma pack(1)
      struct
      begin
        char command;
        hProcess: THandle;
        tid: Integer;
        debugreg: Integer;
        Integer wasWatchpoint;
      end; rb;
#pragma pack()

      rb.command := CMD_REMOVEBREAKPOINT;
      rb.hProcess := hProcess;
      rb.tid := tid;
      rb.debugreg := debugreg;
      rb.wasWatchpoint := wasWatchpoint;


      if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
      begin

        debug_log('Sending message to the debuggerthread'#10'');

        sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&rb, sizeof(rb), 0);
        WakeDebuggerThread();
        recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&result, sizeof(result), MSG_WAITALL);


        pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);
      end;

    end;

  end
  {$else}
    debug_log('Invalid handle'#10'');

  (* C2PAS: Exit *) Result := result;
end;

Integer GetThreadContext(hProcess: THandle, tid: Integer, PCONTEXT Context, Integer type)
(*
 * Gets the context of the given thread
 * Freezes/Resumes the thread for you if it isn't suspended yet
 * type is the data to be gathered (currently ignored but may be used in the future for specific data)
 *)
begin
  Integer r := FALSE;
  debug_log('GetThreadContext(%d)'#10'', tid);



  if (tid< := 0) then
  begin
    debug_log('Invalid tid'#10'');
    (* C2PAS: Exit *) Result := FALSE;
  end;

  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);



    if (p.debuggerThreadID=pthread_self()) then
    begin
      PThreadData td := GetThreadData(p, tid);

      debug_log('Inside debuggerthread'#10'');

      if (td) then
      begin
        DebugEvent de;
        Integer wasPaused := td.isPaused;
        Integer k := 0;


        while ((td.isPaused=0) and (k<10)) do
        begin
          debug_log('This thread was not paused. Pausing it'#10'');
          syscall(__NR_tkill, tid, SIGSTOP);
          if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&de, tid, 100)) then
            break;

          k++;
        end;

        //the thread is paused, so fetch the data

        k := getRegisters(tid, (* C2PAS: RefOrBit? *)&Context.regs);


        //k=safe_ptrace(PTRACE_GETREGS, tid, 0, &Context->regs);
        debug_log('getRegisters() returned %d'#10'', k);

        if (k=0) then
          r := TRUE
        {$else}
          r := FALSE;


        if ( not wasPaused) then
        begin
          //continue if sigstop
          PThreadData td := GetThreadData(p, tid);

          debug_log('The thread was not paused, so resuming it now'#10'');

          if (de.debugevent <> SIGSTOP) then //in case a breakpoint or something {$else} happened before sigstop happened
          begin
            debug_log('Not a SIGSTOP. Adding to queue and leave suspended'#10'');
            AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&de);
            td.isPaused := 1;
          end
          {$else}
          begin
            r := (r and (safe_ptrace(PTRACE_CONT, de.threadid, 0,0)=0));


            td.isPaused := 0;
            debug_log('r=%d'#10'', r);
          end;
        end;


      end
      {$else}
        debug_log('Invalid tid'#10'');

    end
    {$else}
    begin
      debug_log('Not the debugger thread. Pass to serverthread');
#pragma pack(1)
      struct
      begin
        char command;
        hProcess: THandle;
        tid: Integer;
        Integer type;
      end; gtc;
#pragma pack()

      gtc.command := CMD_GETTHREADCONTEXT;
      gtc.hProcess := hProcess;
      gtc.tid := tid;
      gtc.type := type;


      if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
      begin
        debug_log('Sending message to the debuggerthread'#10'');

        sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&gtc, sizeof(gtc), 0);
        WakeDebuggerThread();
        recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&r, sizeof(r), MSG_WAITALL);

        if (r) then
        begin
          //followed by the contextsize
          uint32_t structsize;

          recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&structsize, sizeof(structsize), MSG_WAITALL);
          recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&Context.regs, structsize, MSG_WAITALL); //and context
        end;


        pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);
      end;

    end;
  end
  {$else}
    debug_log('invalid handle'#10'');


  (* C2PAS: Exit *) Result := r;
end;

(*
 * Sets the context of the given thread
 * Fails if the thread is not suspended first
 *)
Integer SetThreadContext(hProcess: THandle, tid: Integer, PCONTEXT Context, Integer type)
begin
  Integer r := FALSE;
  debug_log('SetThreadContext(%d)'#10'', tid);



  if (tid< := 0) then
  begin
    debug_log('Invalid tid'#10'');
    (* C2PAS: Exit *) Result := FALSE;
  end;

  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);



    if (p.debuggerThreadID=pthread_self()) then
    begin
        PThreadData td :=GetThreadData(p, tid);

        debug_log('Inside debuggerthread'#10'');

        if (td) then
        begin
          DebugEvent de;
          Integer wasPaused := td.isPaused;
          Integer k := 0;


          while ((td.isPaused=0) and (k<10)) do
          begin
            debug_log('This thread was not paused. Pausing it'#10'');
            syscall(__NR_tkill, tid, SIGSTOP);
            if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&de, tid, 100)) then
              break;

            k++;
          end;

          //the thread is paused, so fetch the data

          k := setRegisters(tid, (* C2PAS: RefOrBit? *)&Context.regs);


          //k=safe_ptrace(PTRACE_SETREGS, tid, 0, &Context->regs);
          debug_log('setRegisters() returned %d'#10'', k);

          if (k=0) then
            r := TRUE
          {$else}
            r := FALSE;


          if ( not wasPaused) then
          begin
            //continue if sigstop
            PThreadData td := GetThreadData(p, tid);

            debug_log('The thread was not paused, so resuming it now'#10'');

            if (de.debugevent <> SIGSTOP) then //in case a breakpoint or something {$else} happened before sigstop happened
            begin
              debug_log('Not a SIGSTOP. Adding to queue and leave suspended'#10'');
              AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&de);
              td.isPaused := 1;
            end
            {$else}
            begin
              r := (r and (safe_ptrace(PTRACE_CONT, de.threadid, 0,0)=0));


              td.isPaused := 0;
              debug_log('r=%d'#10'', r);
            end;
          end;


        end
        {$else}
          debug_log('Invalid tid'#10'');

      end;
    end
    {$else}
    debug_log('invalid handle'#10'');

    (* C2PAS: Exit *) Result := r;
end;

Integer SuspendThread(hProcess: THandle, tid: Integer)
(*
 * Increase the suspendcount. If it was 0, stop the given thread if it isn't stopped yet
 * If the thread was already stopped, look up this event in the queue and remove it
 * if it's the currently debugged thread it will not be in the queue, but continueFromDebugEvent
 * will see it is suspended, and as a result, NOT continue it, but store the debug event into the thread
 * If it wasn't stopped, stop it, and fetch the debug event
 *)
begin
  Integer result := -1;

  debug_log('SuspendThread(%d)'#10'', tid);
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    PThreadData t := GetThreadData(p, tid);

    if (t=nil) then
    begin
      debug_log('Invalid thread'#10'');
      (* C2PAS: Exit *) Result := -1;
    end;

    if (p.debuggerThreadID=pthread_self()) then
    begin
      //inside the debuggerthrad
      debug_log('Inside the debugger thread.'#10'');

      if (t.isPaused) then
      begin
        debug_log('Already paused'#10'');

        if (t.suspendCount=0) then
        begin
          //first time suspend. Gather the debug event and remove it from the queue (hardly ever, most of the time it's just the currently broken thread)

          if (p.debuggedThreadEvent.threadid=tid) then //it's the currently suspended thread
            t.suspendedDevent := p.debuggedThreadEvent
          {$else}
          begin
            //go through the queuelist to find the debug event and remove it
            t.suspendedDevent := *FindThreadDebugEventInQueue(p,tid);
            RemoveThreadDebugEventFromQueue(p, tid);
          end;
        end;

        t.suspendCount++;


      end
      {$else}
      begin
        debug_log('Not yet paused'#10'');

        while (t.isPaused=0) do
        begin
          syscall(__NR_tkill, tid, SIGSTOP);
          if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&t.suspendedDevent, tid, 100)) then
            break;

        end;

        t.suspendCount++;

      end;

      (* C2PAS: Exit *) Result := t.suspendCount;


      //PThreadData t=GetThreadData(tid);
    end
    {$else}
    begin
      debug_log('Not from the debugger thread. Switching...'#10'');
#pragma pack(1)
      struct
      begin
        char command;
        hProcess: THandle;
        tid: Integer;
      end; st;
#pragma pack()

      st.command :=CMD_SUSPENDTHREAD;
      st.hProcess := hProcess;
      st.tid := tid;

      if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
      begin
        sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&st, sizeof(st), 0);
        WakeDebuggerThread();
        recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&result, sizeof(result), MSG_WAITALL);

        pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);


      end;
    end;
  end
  {$else}
  begin
    debug_log('invalid handle'#10'');
    result := -1;
  end;

  (* C2PAS: Exit *) Result := result;

end;

Integer ResumeThread(hProcess: THandle, tid: Integer)
(*
 * Decrease suspendcount. If 0, resume the thread by adding the stored debug event back to the queue
 *)
begin
  Integer result;

  debug_log('ResumeThread(%d)'#10'', tid);
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    PThreadData t := GetThreadData(p, tid);

    if (t=nil) then
    begin
      debug_log('Invalid thread'#10'');
      (* C2PAS: Exit *) Result := -1;
    end;

    if (p.debuggerThreadID=pthread_self()) then
    begin
      //inside the debuggerthread
      debug_log('Inside the debugger thread.'#10'');

      if ((t.isPaused) and (t.suspendCount>0)) then
      begin

        t.suspendCount--;

        result := t.suspendCount;


        if (t.suspendCount=0) then
        begin
          //reached 0, continue process if sigstop, {$else} add to queue
          PThreadData td := GetThreadData(p, tid);
          debug_log('suspeneCount==0'#10'');

          if (t.suspendedDevent.debugevent=SIGSTOP) then
          begin
            debug_log('SIGSTOP: Continue thread without queing'#10'');
            safe_ptrace(PTRACE_CONT, t.suspendedDevent.threadid, 0,0);
            td.isPaused := 0;
          end
          {$else}
          begin
            debug_log('Not a SIGSTOP Add to the event queue'#10'');
            td.isPaused := 1;
            AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&t.suspendedDevent);
            WakeDebuggerThread();
          end;
        end;
      end
      {$else}
      begin
        debug_log('Failure resuming this thread'#10'');

      end;


      //PThreadData t=GetThreadData(tid);
    end
    {$else}
    begin
      debug_log('Not from the debugger thread. Switching...'#10'');
#pragma pack(1)
      struct
      begin
        char command;
        hProcess: THandle;
        tid: Integer;
      end; rt;
#pragma pack()

      rt.command := CMD_RESUMETHREAD;
      rt.hProcess := hProcess;
      rt.tid := tid;

      if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
      begin
        sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&rt, sizeof(rt), 0);
        WakeDebuggerThread();
        recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&result, sizeof(result), MSG_WAITALL);

        pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);
      end;
    end;
  end
  {$else}
  begin
    debug_log('invalid handle'#10'');
    result := -1;
  end;

  (* C2PAS: Exit *) Result := result;
end;

Integer RemoveThreadDebugEventFromQueue(p: PProcessData, tid: Integer)
(*
 * removes the debug event from the queue
 *)
begin
  Integer result := FALSE;
  struct DebugEventQueueElement *deqe;

  pthread_mutex_lock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);

 // debug_log("RemoveThreadDebugEventFromQueue(%d)\n", tid);

  deqe := p.debugEventQueue.tqh_first;
  while (deqe) do
  begin
   // debug_log("deqe->de.threadid=%d  (looking for %d)\n", deqe->de.threadid, tid);
    if (deqe.de.threadid=tid) then
    begin
      //printf("Found. Removing it\n");
      TAILQ_REMOVE((* C2PAS: RefOrBit? *)&p.debugEventQueue, deqe, entries);

      free(deqe);
      result := TRUE;
      break;
    end;

   // debug_log("Not what I wanted. Check next\n");
    deqe := deqe.entries.tqe_next;
  end;


  pthread_mutex_unlock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);
  (* C2PAS: Exit *) Result := result;
end;

PDebugEvent FindThreadDebugEventInQueue(p: PProcessData, tid: Integer)
(*
 * Finds the DebugEvent for this specific thread if there is one
 * Note that it returns a pointer to it. If you plan on removing it from the queue, copy the results manually
 *)
begin
  PDebugEvent result := nil;
  struct DebugEventQueueElement *deqe;
  pthread_mutex_lock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);

  deqe := p.debugEventQueue.tqh_first;
  while (deqe) do
  begin
    if ((tid=-1) or (deqe.de.threadid=tid)) then
    begin
      result := (* C2PAS: RefOrBit? *)&deqe.de;
      break;
    end;

    deqe := deqe.entries.tqe_next;
  end;


  pthread_mutex_unlock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);
  (* C2PAS: Exit *) Result := result;
end;

void AddDebugEventToQueue(p: PProcessData, devent: PDebugEvent)
begin
  struct DebugEventQueueElement *deqe;

  if (devent.debugevent=SIGSTOP) then
  begin
    debug_log('<<<<<--------------------SIGSTOP ADDED TO THE QUEUE!'#10'');
  end;

  pthread_mutex_lock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);

  deqe := malloc(sizeof(struct DebugEventQueueElement));
  deqe.de := *devent;

  TAILQ_INSERT_TAIL((* C2PAS: RefOrBit? *)&p.debugEventQueue, deqe, entries);

  pthread_mutex_unlock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);
end;

Integer GetStopSignalFromThread(tid: Integer)
begin
  siginfo_t si;
  if (safe_ptrace(PTRACE_GETSIGINFO, tid, nil, (* C2PAS: RefOrBit? *)&si)=0) then
    (* C2PAS: Exit *) Result := si.si_signo
  {$else}
    (* C2PAS: Exit *) Result := -1;
end;

Integer WaitForDebugEventNative(p: PProcessData, devent: PDebugEvent, tid: Integer, timeout: Integer)
(*
 * Waits for a debug event for a specific thread, queues the devent if not the expected tid
 * Only call this from a(the) debugger thread (NO OTHER THREAD MAY CALL THIS)
 *)
begin
  Integer currentTID;
  Integer status;
  Integer r;





  //printf("WaitForDebugEventNative (p=%p, devent=%p, tid=%d timeout=%d)\n", p, devent, tid, timeout);


  //first check if there is already a thread waiting
  currentTID := 1;
  while (currentTID>0) do
  begin
    currentTID := waitpid(tid, (* C2PAS: RefOrBit? *)&status, __WALL or WNOHANG);

    //printf("First waitid=%d\n", currentTID);

    if (currentTID>0) then
    begin
      devent.threadid := currentTID;
      devent.debugevent := GetStopSignalFromThread(devent.threadid);

      PThreadData td := GetThreadData(p, currentTID);
      if (td) then
        td.isPaused := 1;


      if ((tid=-1) or (currentTID=tid)) then
        (* C2PAS: Exit *) Result := TRUE;

      //still here, this wasn't what I was looking for...
      //add it to the queue

      //printf("Unexpected event from thread %d while waiting for %d\n", currentTID, tid);



      AddDebugEventToQueue(p, devent);
    end;
    //try again, perhaps there is another one available right now
  end;

 // debug_log("Checking for debug server command\n");

//  fflush(stdout);

  //still here
  //CheckForAndDispatchCommand(p->debuggerServer);


 // debug_log("After check and dispatch\n");
 // fflush(stdout);


  if (timeout> := 0) then
  begin
    //wait till there is an event

    if (timeout>0) then
    begin
      struct timespec abstime;
      struct timeval current,wanted, diff;
      Integer timedwait;

     // debug_log("timed wait\n");

      memset((* C2PAS: RefOrBit? *)&abstime, 0, sizeof(abstime));
      gettimeofday((* C2PAS: RefOrBit? *)&current,nil);

      diff.tv_sec := (timeout / 1000);
      diff.tv_usec := (timeout mod 1000)*1000;

      timeradd((* C2PAS: RefOrBit? *)&current, (* C2PAS: RefOrBit? *)&diff, (* C2PAS: RefOrBit? *)&wanted);

      abstime.tv_sec := wanted.tv_sec;
      abstime.tv_nsec := wanted.tv_usec*1000;

      currentTID := -1;
      while (currentTID< := 0) do
      begin
        timedwait := sem_timedwait((* C2PAS: RefOrBit? *)&sem_DebugThreadEvent, (* C2PAS: RefOrBit? *)&abstime);
       // if (log==1)
      //    debug_log("log=1: sem_timedwait=%d\n", timedwait);

        if (timedwait=0) then
        begin
          //it got signaled
          //check if there is a debugger thread message waiting
         // if (log==1)
         //   debug_log("Checking for dispatch command\n");

          CheckForAndDispatchCommand(p.debuggerServer);
          if (VerboseLevel>10) then
            debug_log('CheckForAndDispatchCommand returned'#10'');

          //check if an event got queued for this thread by the dispatcher
          PDebugEvent e := FindThreadDebugEventInQueue(p, tid);
          if (e) then
          begin
            debug_log('There was a queued event after CheckForAndDispatchCommand. TID=%ld (wanted %d)'#10'', e.threadid, tid);
            currentTID := e.threadid;

            r := RemoveThreadDebugEventFromQueue(p, currentTID);
            debug_log('RemoveThreadDebugEventFromQueue returned %d'#10'', r);
          end
          {$else}
            currentTID := waitpid(tid, (* C2PAS: RefOrBit? *)&status, __WALL or WNOHANG);

          if (VerboseLevel>10) then
            debug_log('currentTID = %d'#10'', currentTID);

          if (currentTID>0) then
          begin
            devent.threadid := currentTID;
            devent.debugevent := GetStopSignalFromThread(devent.threadid);

            PThreadData td := GetThreadData(p, currentTID);
            if (td) then
              td.isPaused := 1;

            if ((tid=-1) or (currentTID=tid)) then
              (* C2PAS: Exit *) Result := TRUE;

            //still here
            debug_log('Still here so currentTID(%d) is not the same as tid (%d)'#10'', currentTID, tid);
            AddDebugEventToQueue(p, devent);
          end;
          currentTID := -1; //retry

        end
        {$else}
        begin
          if (errno=ETIMEDOUT) then
          begin
            //printf("timeout\n");
            (* C2PAS: Exit *) Result := FALSE;
          end;
          //{$else}
          //  debug_log("Not a timeout. Retry\n");
        end;
      end;
    end
    {$else}
    begin
      //no wait
      //printf("no wait\n");


    end;

  end
  {$else}
  begin
    //printf("Infinite wait\n");
    currentTID := -1;
    while (currentTID<0) do
    begin
      currentTID := waitpid(tid, (* C2PAS: RefOrBit? *)&status, __WALL);
      if (currentTID>0) then
      begin
        devent.threadid := currentTID;
        devent.debugevent := GetStopSignalFromThread(devent.threadid);

        PThreadData td := GetThreadData(p, currentTID);
        if (td) then
          td.isPaused := 1;

        if ((tid=-1) or (currentTID=tid)) then
          (* C2PAS: Exit *) Result := TRUE;

        //still here
        AddDebugEventToQueue(p, devent);
      end;

      if ((currentTID=-1) and (errno <> EINTR)) then
      begin
        debug_log('WaitForDebugEventNative: Infinite wait: Could not wait for tid %d (errno=%d)'#10'', tid, errno);
        (* C2PAS: Exit *) Result := FALSE; //something bad happened
      end;

      currentTID := -1;
    end;

  end;

  //printf("Returning false\n");


  (* C2PAS: Exit *) Result := FALSE;

end;


Integer WaitForDebugEvent(hProcess: THandle, devent: PDebugEvent, timeout: Integer)
(*
 *Waits for the specified timeout in milliseconds, called by the ce gui
 *Does not care about which thread to wait for
 *)
begin
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    if (p.debuggedThreadEvent.threadid=0) then
    begin
      Integer r := 0;

      Integer status;
      tid: Integer;
      struct DebugEventQueueElement *de := nil;

      //check the queue (first one in the list)
      pthread_mutex_lock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);
      de := TAILQ_FIRST((* C2PAS: RefOrBit? *)&p.debugEventQueue);

      if (de) then
        TAILQ_REMOVE((* C2PAS: RefOrBit? *)&p.debugEventQueue, de, entries);


      pthread_mutex_unlock((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex);

      if (de) then //there was a queued event, return it
      begin
        debug_log('Returning queued event (sig=%d,  thread=%ld)'#10'', de.de.debugevent, de.de.threadid);
        if (de.de.debugevent=SIGSTOP) then
        begin
          debug_log('<---Something queued a SIGSTOP--->'#10'');
        end;

        *devent := de.de;
        p.debuggedThreadEvent := *devent;
        free(de);

        r := 1; //mark that a queued event happened
      end;

      if ( not r) then //not a queued event
        r := WaitForDebugEventNative(p, devent, -1, timeout);


      if (r) then
      begin
        p.debuggedThreadEvent := *devent;


        if (p.debuggedThreadEvent.debugevent=SIGTRAP) then
        begin
          siginfo_t si;
          debug_log('SIGTRAP'#10'');

          //fill in the address


{$if } (defined(__arm__) or defined(__aarch64__)) then
          //return si_addr of siginfo
          if (safe_ptrace(PTRACE_GETSIGINFO, p.debuggedThreadEvent.threadid, nil, (* C2PAS: RefOrBit? *)&si)=0) then
          begin

            p.debuggedThreadEvent.address := (uintptr_t)si.si_addr;
            debug_log('si.si_addr=%p'#10'', si.si_addr);
          end
          {$else}
            debug_log('Failure getting siginfo for this trap'#10'');
{$endif}

{$if } defined __i386__ or defined __x86_64__
          //use DR6 to determine which bp (if possible)
          uintptr_t DR0,DR1,DR2,DR3,DR7, IP;
          regDR6 DR6;
{$if } defined __i386__
          IP := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, regs.eip), 0) then ;
{$else}
          IP := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, regs.rip), 0);
{$endif}
          DR0 := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[0]), 0);
          DR1 := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[1]), 0);
          DR2 := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[2]), 0);
          DR3 := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[3]), 0);

          DR6.value :=safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[6]), 0);
          DR7 := safe_ptrace(PTRACE_PEEKUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[7]), 0);

          debug_log('DR0=%lx'#10'',DR0);
          debug_log('DR1=%lx'#10'',DR1);
          debug_log('DR2=%lx'#10'',DR2);
          debug_log('DR3=%lx'#10'',DR3);
          debug_log('DR6=%lx'#10'',DR6.value);
          debug_log('DR7=%lx'#10'',DR7);
          debug_log('IP=%lx'#10'',IP);

          p.debuggedThreadEvent.address := 0; //something unexpected
          if (DR6.B0) then
            p.debuggedThreadEvent.address := DR0
          {$else}
          if (DR6.B1) then
            p.debuggedThreadEvent.address := DR1
          {$else}
          if (DR6.B2) then
            p.debuggedThreadEvent.address := DR2
          {$else}
          if (DR6.B3) then
            p.debuggedThreadEvent.address := DR3
          {$else}
          if (DR6.BS) then //single step
            p.debuggedThreadEvent.address := 1;


          safe_ptrace(PTRACE_POKEUSER, p.debuggedThreadEvent.threadid, offsetof(struct user, u_debugreg[6]), 0); //not sure if needed, or if this should be moved to continuefromdebugevent

{$endif}
          debug_log('p->debuggedThreadEvent.address=%lx'#10'', p.debuggedThreadEvent.address);

          devent.address := p.debuggedThreadEvent.address;
        end;
      end;

      (* C2PAS: Exit *) Result := r;
    end
    {$else}
    begin
      *devent := p.debuggedThreadEvent;
      debug_log('Can not wait for a debug event when a thread is still paused'#10'');
      debug_log('tid=%d  debugevent=%d'#10'', (Integer)devent.threadid, devent.debugevent);
      (* C2PAS: Exit *) Result := 1; //success and just handle this event
    end;

  end;
  (* C2PAS: Exit *) Result := 0;
end;

Integer ContinueFromDebugEvent(hProcess: THandle, tid: Integer, Integer ignoresignal)
begin
  //printf("ContinueFromDebugEvent called\n");
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    PThreadData td := GetThreadData(p, tid);
    siginfo_t si;

   //printf("td==%p\n", td);

    if (p.debuggedThreadEvent.debugevent<0) then //virtual debug event. Just ignore
    begin
      debug_log('Virtual event. Ignore'#10'');
      p.debuggedThreadEvent.threadid := 0;
      p.debuggedThreadEvent.debugevent := 0;
      (* C2PAS: Exit *) Result := 1; //ignore it
    end;


    if (td=nil) then
    begin
      debug_log('Invalid thread'#10'');
      p.debuggedThreadEvent.threadid := 0;

      (* C2PAS: Exit *) Result := 0; //invalid thread
    end;

   // debug_log("td->suspendcount=%d\n", td->suspendCount);

    if (td.suspendCount>0) then
    begin
      debug_log('Tried to continue a suspended thread (suspendcount=%d)'#10'', td.suspendCount);
      (* C2PAS: Exit *) Result := 1; //keep it suspended
    end;

   // debug_log("p->debuggedThreadEvent.debugevent=%d\n", p->debuggedThreadEvent.debugevent);

    //if (p->debuggedThreadEvent.threadid!=tid)
    //  debug_log("Unexpected thread continue. Expected %d got %d\n", p->debuggedThreadEvent.threadid, tid);




    if (safe_ptrace(PTRACE_GETSIGINFO, tid, nil, (* C2PAS: RefOrBit? *)&si)=0) then
    begin
      Integer signal := ignoresignal?0:si.si_signo;

     // debug_log("si.si_signo=%d\n", si.si_signo);
     // debug_log("si.si_code=%d\n", si.si_code);



      if ((signal=19) or (signal=21)) then //STOPPED
      begin
        signal := 0;
      end;

      //printf("Continue %d with signal %d\n", tid, signal);

      Integer result;
      if (ignoresignal=2) then
      begin
        debug_log('Single step'#10'');

        result := safe_ptrace(PTRACE_SINGLESTEP, tid, 0,0);
        if (result <> 0) then
        begin
          debug_log('PTRACE_SINGLESTEP failed (%d). Shit happens'#10'', errno);
          result := safe_ptrace(PTRACE_CONT, tid, 0,signal);
        end;

      end
      {$else}
      begin
        result := safe_ptrace(PTRACE_CONT, tid, 0,signal);
      end;



     // debug_log("Continue result=%d\n", result);

      if (td) then
        td.isPaused := 0;


      if (result<0) then
      begin
        debug_log('Failure to continue thread %d with signal %d'#10'', tid, signal);
        RemoveThreadFromProcess(p, tid);
        p.debuggedThreadEvent.threadid := 0;
        (* C2PAS: Exit *) Result := 0;
      end
      {$else}
      begin
        p.debuggedThreadEvent.threadid := 0;
        (* C2PAS: Exit *) Result := 1;
      end;
    end
    {$else}
      debug_log('Failure getting sig info'#10'');

  end
  {$else}
    debug_log('Invalid handle'#10'');

  (* C2PAS: Exit *) Result := 0;
end;

Integer StopDebug(hProcess: THandle)
begin
  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    Integer i;
    for (i := 0; i<p.threadlistpos;i++)
      if (safe_ptrace(PTRACE_DETACH, p.threadlist[i].tid,0,0)<0) then
        debug_log('Failed to detach from %ld'#10'', p.threadlist[i].tid);
  end;

  (* C2PAS: Exit *) Result := 1;

end;

Integer WriteProcessMemoryDebug(hProcess: THandle, p: PProcessData, void *lpAddress, void *buffer, Integer size)
begin
  Integer byteswritten := 0;
  Integer i;

  debug_log('WriteProcessMemoryDebug:');
  for (i := 0; i<size; i++)
  begin
    debug_log('%.2x ', ((unsigned char *)buffer)[i]);
  end;

  debug_log(''#10'');




  if (p.debuggerThreadID=pthread_self()) then //this is the debugger thread
  begin
    Integer isdebugged := FindPausedThread(p); //find a paused thread if there is one
    DebugEvent event;

    event.threadid := isdebugged;

    if ( not isdebugged) then
    begin
     // debug_log("Not currently debugging a thread. Suspending a random thread\n");
      kill(p.pid, SIGSTOP);

      //printf("Going to wait for debug event\n");
      WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&event, -1, -1); //wait for it myself

     // debug_log("After WaitForDebugEventNative (tid=%d)\n", event.threadid);
    end;



    //write the bytes
    begin
      Integer offset := 0;
      Integer max := size-sizeof(long Integer);

      long Integer *address := (long Integer *)buffer;


      while (offset<max) do
      begin
        debug_log('offset=%d max=%d'#10'', offset, max);
        safe_ptrace(PTRACE_POKEDATA, p.pid, (void*)((uintptr_t)lpAddress+offset), (void *)*address);

        address++;
        offset+ := sizeof(long Integer);
        byteswritten+ := sizeof(long Integer);
      end;

      if (offset<size) then
      begin
        debug_log('Still some bytes left: %d'#10'', size-offset);
        //still a few bytes left
        long Integer oldvalue := safe_ptrace(PTRACE_PEEKDATA, p.pid,  (void *)(uintptr_t)lpAddress+offset, (void*)0);
        {$ifdef } __x86_64__
          //Even with 64 bits, peek_data can read only 4 bytes.
          oldvalue + := safe_ptrace(PTRACE_PEEKDATA, p.pid,  (void *)(uintptr_t)lpAddress+offset+4, (void*)0)*0x100000000;
        {$endif}
        unsigned char *oldbuf := (unsigned char *)(* C2PAS: RefOrBit? *)&oldvalue;
        unsigned char *newmem := (unsigned char *)address;
        Integer i;

        debug_log('oldvalue=%lx'#10'', oldvalue);

        for (i := 0; i< (size-offset); i++)
          oldbuf[i] := newmem[i];

        debug_log('newvalue=%lx'#10'', oldvalue);


        i := safe_ptrace(PTRACE_POKEDATA, p.pid, (void*)((uintptr_t)lpAddress+offset), (void *)oldvalue);

        debug_log('ptrace poke returned %d'#10'', i);
        if (i> := 0) then
          byteswritten+ := size-offset;

      end;

    end;



    if ( not isdebugged) then
    begin
      PThreadData td := GetThreadData(p, event.threadid);

      //if a SIGSTOP happened just continue it, {$else} the next time WaitForDebugEvent() runs it will get this event from the queue
      if (event.debugevent=SIGSTOP) then
      begin

      //  debug_log("Continue from sigstop\n");

        safe_ptrace(PTRACE_CONT, event.threadid, 0,0);

        if (td) then
          td.isPaused := 0;


      end
      {$else}
      begin
        debug_log('WriteProcessMemoryDebug: Adding unexpected signal to eventqueue (event.debugevent=%d event.threadid)'#10'', event.debugevent, event.threadid);

        AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&event);
        if (td) then
          td.isPaused := 1;
      end;
    end;

  end
  {$else}
  begin
    debug_log('WriteProcessMemoryDebug from outside the debuggerthread. Waking debuggerthread'#10'');

    //setup a rpm command
#pragma pack(1)
    struct
    begin
      uint8_t command;   //1
      uint32_t pHandle;  //5
      uint64_t address;  //13
      uint32_t size;     //17
    end; wpm;
#pragma pack()

    unsigned char data [size];
    debug_log('sizeof wpm=%d'#10'', sizeof(wpm));
    wpm.command := CMD_WRITEPROCESSMEMORY;
    wpm.pHandle := hProcess;
    wpm.address := (uintptr_t)lpAddress;
    wpm.size := size;
    memcpy(data, buffer, size);



    //and write it to the p->debuggerthreadfd and read out the data
    //aquire lock (I don't want other threads messing with the client socket)
    if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
    begin
      sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&wpm, sizeof(wpm), 0);
      sendall (p. debuggerClient, (* C2PAS: RefOrBit? *)&data, size, 0);
      WakeDebuggerThread();

      recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&byteswritten, sizeof(byteswritten), MSG_WAITALL);

      pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);

      debug_log('after recvall byteswritten=%d'#10'', byteswritten);
    end;
  end;


  (* C2PAS: Exit *) Result := byteswritten;
end;

Integer WriteProcessMemory(hProcess: THandle, void *lpAddress, void *buffer, Integer size)
begin
  Integer written := 0;

  debug_log('WriteProcessMemory(%d, %p, %p, %d'#10'', hProcess, lpAddress, buffer, size);

  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    if (p.isDebugged) then //&& cannotdealwithotherthreads
    begin
      //printf("This process is being debugged\n");
      //use the debugger specific readProcessMemory implementation
      (* C2PAS: Exit *) Result := WriteProcessMemoryDebug(hProcess, p, lpAddress, buffer, size);
    end;

    if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&memorymutex) = 0) then
    begin
      if (safe_ptrace(PTRACE_ATTACH, p.pid,0,0)=0) then
      begin
        Integer status;
        pid_t pid := wait((* C2PAS: RefOrBit? *)&status);
        Integer offset := 0;
        Integer max := size-sizeof(long Integer);

        long Integer *address := (long Integer *)buffer;


        while (offset<max) do
        begin
          debug_log('offset=%d max=%d'#10'', offset, max);
          safe_ptrace(PTRACE_POKEDATA, pid, (void*)((uintptr_t)lpAddress+offset), (void *)*address);

          address++;
          offset+ := sizeof(long Integer);

          written+ := sizeof(long Integer);
        end;

        if (offset<size) then
        begin
        	printf('Still some bytes left: %d'#10'', size-offset);
          //still a few bytes left
          long Integer oldvalue := safe_ptrace(PTRACE_PEEKDATA, pid,  (void *)(uintptr_t)lpAddress+offset, (void*)0);
          {$ifdef } __x86_64__
            //Even with 64 bits, peek_data can read only 4 bytes.
            oldvalue + := safe_ptrace(PTRACE_PEEKDATA, p.pid,  (void *)(uintptr_t)lpAddress+offset+4, (void*)0)*0x100000000;
          {$endif}
          unsigned char *oldbuf := (unsigned char *)(* C2PAS: RefOrBit? *)&oldvalue;
          unsigned char *newmem := (unsigned char *)address;
          Integer i;

          debug_log('oldvalue=%lx'#10'', oldvalue);

          for (i :=0; i< (size-offset); i++)
            oldbuf[i] := newmem[i];

          debug_log('newvalue=%lx'#10'', oldvalue);


          i := safe_ptrace(PTRACE_POKEDATA, pid, (void*)((uintptr_t)lpAddress+offset), (void *)oldvalue);

          debug_log('ptrace poke returned %d'#10'', i);
          if (i> := 0) then
        	  written+ := size-offset;

        end;




        safe_ptrace(PTRACE_DETACH, pid,0,0);
      end;
      //{$else}
      //  debug_log("PTRACE ATTACH FAILED\n");

      pthread_mutex_unlock((* C2PAS: RefOrBit? *)&memorymutex);
    end;



  end;

  (* C2PAS: Exit *) Result := written;
end;

Integer ReadProcessMemoryDebug(hProcess: THandle, p: PProcessData, void *lpAddress, void *buffer, Integer size)
begin
  //problem: Only the thread that is currently debugging a stopped thread has read access
  //work around: add a que to the debugger thread that fills in this
  //que a ReadProcessMemory command with the debugger

  //problem 2: If the debugger thread has broken on a breakpoint and another thread wants to read memory it can't
  //e.g: t1:WaitForDebugEvent  t1:Returned. T1: recv  t2: ReadProcessMemory...
  //solution, let the debuggerthread wait for a socket event with select on 2 fd's. One from the connected socket, and one from the que.
  //the que will contain normal rpm command


  Integer bytesread := 0;

 // debug_log("ReadProcessMemoryDebug");
//  debug_log("lpAddress=%p\n", lpAddress);



  if (p.debuggerThreadID=pthread_self()) then //this is the debugger thread
  begin
    Integer isdebugged := FindPausedThread(p); //find a paused thread if there is one
    DebugEvent event;

    event.threadid := isdebugged;


    //printf("ReadProcessMemoryDebug inside debuggerthread (thread debbugged=%d)\n", isdebugged);

    if ( not isdebugged) then
    begin
      // debug_log("Not currently debugging a thread. Suspending a random thread\n");
      kill(p.pid, SIGSTOP);

      //printf("Going to wait for debug event\n");
      if (WaitForDebugEventNative(p, (* C2PAS: RefOrBit? *)&event, -1, -1)=FALSE) then //wait for it myself
      begin
        debug_log('WaitForDebugEventNative returned FALSE for a wait without timeout'#10'');
        (* C2PAS: Exit *) Result := 0;
      end;

     // debug_log("After WaitForDebugEventNative (tid=%d)\n", event.threadid);
    end;

    if (MEMORY_SEARCH_OPTION= 0) then
    begin

      Integer inflooptest := 0;

      bytesread := -1;
      while (bytesread=-1) do
      begin
        inflooptest++;

        if (inflooptest>10) then
          debug_log('FUUU');



        //bytesread=pread(p->mem, buffer, size, (uintptr_t)lpAddress);

        lseek64(p.mem, (uintptr_t)lpAddress, SEEK_SET);
        bytesread := read(p.mem, buffer, size);


        if ((bytesread<0) and (errno <> EINTR)) then
        begin
          (*
          debug_log("pread failed and not due to a signal: %d  (isdebugged=%d)\n", errno, isdebugged);
          if (isdebugged)
          {
            debug_log("event.threadid=%d devent=%d\n", (int)event.threadid, event.debugevent);
          }
          debug_log("lpAddress=%p\n", lpAddress);
          debug_log("size=%d\n", size);
          *)

          bytesread := 0;

          if (isdebugged) then
          begin
          // debug_log("trying to read from specific task\n");

            Integer f;
            char mempath[255];

            sprintf(mempath,'/proc/%d/task/%d/mem', p.pid, (Integer)event.threadid);
          // debug_log("Opening %s\n", mempath);
            f := open(mempath, O_RDONLY);
            debug_log('f=%d'#10'', f);
            if (f> := 0) then
            begin
              //bytesread=pread(f, buffer, size, (uintptr_t)lpAddress);
              lseek64(p.mem, (uintptr_t)lpAddress, SEEK_SET);
              bytesread := read(p.mem, buffer, size);

              if ((bytesread<0) and (errno <> EINTR)) then
              begin
              //  debug_log("Also failed on second try\n");
                bytesread := 0;
              end;
              close(f);
            end;
          end;


          break;
        end;
      end;
    end
    {$else}
    begin

      Integer offset := 0;
      Integer max := size-sizeof(long Integer);

      long Integer *address := (long Integer *)buffer;

      long Integer value := 0;

      Integer is_readable := 1;

      while (offset<max) do
      begin
        errno := 0;
        value :=  safe_ptrace(PTRACE_PEEKDATA, p.pid, (void*)((uintptr_t)lpAddress+offset), (void *)0);

        if (errno = 0) then
        begin
          *address := value;

          address++;
          offset+ := sizeof(long Integer);

          bytesread+ := sizeof(long Integer);
        end
        {$else}
        begin
          is_readable := 0;
          break;
        end;

      end;

      if (offset < size and is_readable) then
      begin
        errno := 0;
        value :=  safe_ptrace(PTRACE_PEEKDATA, p.pid, (void*)((uintptr_t)lpAddress+offset), (void *)0);

        if (errno = 0) then
        begin
          memcpy(address,(* C2PAS: RefOrBit? *)&value,size-offset);

          Integer i := size-offset;
          if (i> := 0) then
            bytesread+ := size-offset;
        end;

      end;
    end;

    if ( not isdebugged) then
    begin
      PThreadData td := GetThreadData(p, event.threadid);

      //if a SIGSTOP happened just continue it, {$else} the next time WaitForDebugEvent() runs it will get this event from the queue
      if (event.debugevent=SIGSTOP) then
      begin

      //  debug_log("Continue from sigstop\n");

        safe_ptrace(PTRACE_CONT, event.threadid, 0,0);

        if (td) then
          td.isPaused := 0;


      end
      {$else}
      begin
        debug_log('ReadProcessMemoryDebug: Adding unexpected signal to eventqueue (event.debugevent=%d event.threadid=%d)'#10'', event.debugevent, event.threadid);

        if (td) then
          td.isPaused := 1;

        AddDebugEventToQueue(p, (* C2PAS: RefOrBit? *)&event);

        debug_log('After add'#10'');

        VerboseLevel := 1000000000;

      end;
    end;


  end
  {$else}
  begin

    tid: Integer := p.pid; //p->threadlist[p->threadlistpos-1];
   // debug_log("ReadProcessMemoryDebug from outside the debuggerthread. Waking debuggerthread\n");

    //setup a rpm command
#pragma pack(1)
    struct
    begin
      uint8_t command;
      uint32_t pHandle;
      uint64_t address;
      uint32_t size;
      uint8_t compressed;
    end; rpm;
#pragma pack()


    rpm.command := CMD_READPROCESSMEMORY;
    rpm.pHandle := hProcess;
    rpm.address := (uintptr_t)lpAddress;
    rpm.size := size;
    rpm.compressed := 0;

    //and write it to the p->debuggerthreadfd and read out the data
    //aquire lock (I don't want other threads messing with the client socket)
    if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&debugsocketmutex) = 0) then
    begin
    //  debug_log("Sending message to the debuggerthread\n");

      sendall(p.debuggerClient, (* C2PAS: RefOrBit? *)&rpm, sizeof(rpm), 0);


      //log=1;
      //printf("Waking debugger thread and waiting for result\n");
      WakeDebuggerThread();

      recvall(p.debuggerClient, (* C2PAS: RefOrBit? *)&bytesread, sizeof(bytesread), MSG_WAITALL);

      if (VerboseLevel>10) then
        debug_log('After waiting for debugger thread: bytesread=%d'#10'', bytesread);

      if (bytesread>0) then
        recvall(p.debuggerClient, buffer, bytesread, MSG_WAITALL);


      pthread_mutex_unlock((* C2PAS: RefOrBit? *)&debugsocketmutex);
    end;

    //bytesread=read...
  end;


  if (VerboseLevel>10) then
    debug_log('ReadProcessMemoryDebug returns %d'#10'', bytesread);

  (* C2PAS: Exit *) Result := bytesread;
end;

Integer ReadProcessMemory(hProcess: THandle, void *lpAddress, void *buffer, Integer size)
begin
  //idea in case this is too slow. always read a full page and keep the last 16 accessed pages.
  //only on cache miss, or if the cache is older than 1000 milliseconds fetch the page.
  //keep in mind that this routine can get called by multiple threads at the same time


  //todo: Try process_vm_readv

 // debug_log("ReadProcessMemory(%d, %p, %p, %d)\n", (int)hProcess, lpAddress, buffer, size);

  //printf("ReadProcessMemory\n");
  Integer bread := 0;


  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin //valid handle
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    //printf("hProcess=%d, lpAddress=%p, buffer=%p, size=%d\n", hProcess, lpAddress, buffer, size);

    if (p.isDebugged) then //&& cannotdealwithotherthreads
    begin
      //printf("This process is being debugged\n");
      //use the debugger specific readProcessMemory implementation
      (* C2PAS: Exit *) Result := ReadProcessMemoryDebug(hProcess, p, lpAddress, buffer, size);
    end;

    //printf("Read without debug\n");

    if (pthread_mutex_lock((* C2PAS: RefOrBit? *)&memorymutex) = 0) then
    begin


        if (safe_ptrace(PTRACE_ATTACH, p.pid,0,0)=0) then
        begin
          Integer status;

          pid_t pid := wait((* C2PAS: RefOrBit? *)&status);

          if (MEMORY_SEARCH_OPTION = 0) then
          begin

            lseek64(p.mem, (uintptr_t)lpAddress, SEEK_SET);

            bread := read(p.mem, buffer, size);

            if (bread=-1) then
            begin
              bread := 0;
              //printf("pread error for address %p (errno=%d) ", lpAddress, errno);
              //printf("\n");
            end;

          end
          {$else}
          begin

            Integer offset := 0;
            Integer max := size-sizeof(long Integer);

            long Integer *address := (long Integer *)buffer;

            long Integer value := 0;

            Integer is_readable := 1;

            while (offset<max) do
            begin
              errno := 0;
              value :=  safe_ptrace(PTRACE_PEEKDATA, pid, (void*)((uintptr_t)lpAddress+offset), (void *)0);

              if (errno = 0) then
              begin
                *address := value;

                address++;
                offset+ := sizeof(long Integer);

                bread+ := sizeof(long Integer);
              end
              {$else}
              begin
                is_readable := 0;
                break;
              end;

            end;

            if (offset < size and is_readable) then
            begin
              errno := 0;
              value :=  safe_ptrace(PTRACE_PEEKDATA, pid, (void*)((uintptr_t)lpAddress+offset), (void *)0);

              if (errno = 0) then
              begin
                memcpy(address,(* C2PAS: RefOrBit? *)&value,size-offset);

                Integer i := size-offset;
                if (i> := 0) then
                  bread+ := size-offset;
              end;

            end;

          end;

          //printf("bread=%d size=%d\n", bread, size);


          safe_ptrace(PTRACE_DETACH, pid,0,0);
        end
        {$else}
          debug_log('ptrace attach failed (pid=%d). This system might not be properly rooted'#10'', p.pid);


      pthread_mutex_unlock((* C2PAS: RefOrBit? *)&memorymutex);
    end
    {$else}
      debug_log('For some reason I failed to obtain a lock'#10'');
  end;
  //{$else}
  //  debug_log("RPM: invalid handle\n");

 // debug_log("Returned from rpm\n");

  fflush(stdout);

  (* C2PAS: Exit *) Result := bread;
end;


DWORD ProtectionStringToType(char *protectionstring)
begin
  if (strchr(protectionstring, 's')) then
    (* C2PAS: Exit *) Result := MEM_MAPPED
  {$else}
    (* C2PAS: Exit *) Result := MEM_PRIVATE;
end;

uint32_t ProtectionStringToProtection(char *protectionstring)
begin
  Integer w,x;

  if (strchr(protectionstring, 'x')) then
    x := 1
  {$else}
    x := 0;

  if (strchr(protectionstring, 'w')) then
    w := 1
  {$else}
    w := 0;

  if (x) then
  begin
    //executable
    if (w) then
      (* C2PAS: Exit *) Result := PAGE_EXECUTE_READWRITE
    {$else}
      (* C2PAS: Exit *) Result := PAGE_EXECUTE_READ;
  end
  {$else}
  begin
    //not executable
    if (w) then
      (* C2PAS: Exit *) Result := PAGE_READWRITE
    {$else}
      (* C2PAS: Exit *) Result := PAGE_READONLY;
  end;
end;

void AddToRegionList(uint64_t base, uint64_t size, uint32_t type, uint32_t protection, RegionInfo **list, Integer *pos, Integer *max)
//helper function for VirtualQueryExFull to add new entries to the list
begin
  //printf("Calling AddToRegionList\n");

  debug_log('++>%llx->%llx : (%llx)  - %d'#10'', (unsigned long long)base, (unsigned long long)base+size, (unsigned long long)size, type);

  (*list)[*pos].baseaddress := base;
  (*list)[*pos].size := size;
  (*list)[*pos].type := type;
  (*list)[*pos].protection := protection;

  (*pos)++;

  if (*pos> := *max) then
  begin
    debug_log('resize list'#10'');
    *max := (*max)*2;
    *list := (RegionInfo *)realloc(*list, sizeof(RegionInfo)*(*max));
  end;

  //printf("Returning from AddToRegionList\n");
end;

Integer VirtualQueryExFull(hProcess: THandle, uint32_t flags, RegionInfo **rinfo, uint32_t *count)
(*
 * creates a full list of the maps file (less seeking)
 *)
begin
  Integer pagedonly := flags (* C2PAS: RefOrBit? *)& VQE_PAGEDONLY;
  Integer dirtyonly := flags (* C2PAS: RefOrBit? *)& VQE_DIRTYONLY;
  Integer noshared := flags (* C2PAS: RefOrBit? *)& VQE_NOSHARED;

  debug_log('VirtualQueryExFull:'#10'');

  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);

    char smaps_name[64];
    char pagemap_name[64];

    sprintf(smaps_name,'/proc/%d/smaps', p.pid);
    sprintf(pagemap_name,'/proc/%d/pagemap', p.pid);

    FILE *maps := fopen(smaps_name, 'r');
    Integer pagemap := -1;

    uint64_t *pagemap_entries := nil;

    if (pagedonly) then
    begin
      debug_log('pagedonly'#10'');
      pagemap := open(pagemap_name, O_RDONLY);

     // debug_log("pagemap=%p\n", pagemap);


      pagemap_entries := (uint64_t *)malloc(512*8);

      debug_log('allocated pagemap_entries at %p'#10'', pagemap_entries);
    end;


    if (maps and ( not pagedonly or (pagemap> := 0))) then
    begin


      unsigned long long start := 0, stop := 0;
      char protectionstring[25];
      char x[200];
      Integer pos :=0, max := pagedonly?64:128;
      RegionInfo *r;

      debug_log('going to allocate r'#10'');
      r := (RegionInfo *)malloc(sizeof(RegionInfo)*max);

      debug_log('Allocated r at %p'#10'', r);

      Integer isdirty := 0;
      Integer end := 0;


      while ( not end) do
      begin
        unsigned long long _start, _stop;
        char temp[25];

        end := fgets(x, 200, maps)=0;


        //make sure the stream gets to tne next line. (long modulepaths can cause an issue)

        //printf("%s\n",x);

        if (x[strlen(x)-1] <> '\n') then
        begin
          //need to go to the end of line first

          char discard[100];

          do
          begin
            discard[99] := 0;
            fgets(discard, 99, maps);
          end; while (discard[99] <> 0) do ;
        end;

        temp[0] := 0;
        sscanf(x, '%llx-%llx %24s', (* C2PAS: RefOrBit? *)&_start, (* C2PAS: RefOrBit? *)&_stop, temp);

        if ((end) or (temp[0] <> 0)) then
        begin
          //new entry
          if (start) then
          begin
            Integer passed := 1;
            DWORD type := ProtectionStringToType(protectionstring);
            DWORD protection := ProtectionStringToProtection(protectionstring);

            //a block was being processed


            //some checks to see if it passed
            if (noshared and (type=MEM_MAPPED)) then //
              passed := 0;

            if (dirtyonly and not isdirty) then
              passed := 0;

            //writable only as well ?

            if (passed) then
            begin
              //printf("passed the initial check\n");
              if (pagedonly) then
              begin
                //only add the pages
                //todo: Add a dirtyonlyPlus which works in conjunction with softdirty pages (only works on newer kernels and requires a forced clear)
                uint64_t current := start;
                Integer pagesize;
{$if }ndef PAGESIZE
                pagesize := getpagesize();
{$else}
                pagesize := PAGESIZE;
{$endif}
                while (current<stop) do
                begin
                  Integer i;
                  Integer currentstart := -1;
                  off_t offset :=(current / pagesize)*8;
                  size_t pagecount := (stop-current) / pagesize;
                  if (pagecount>512) then
                    pagecount := 512;

                  debug_log('-->%llx->%llx : %s (%llx)'#10'', start, stop, protectionstring, stop-start);

                  i := pread(pagemap, pagemap_entries, pagecount*8, offset);
                  if (i=-1) then
                  begin
                    debug_log('offset=%llx, pagecount=%d read=%d (%d) '#10'', (unsigned long long)offset, (Integer)pagecount, i/8, i);
                    //exit(12);
                  end
                  {$else}
                  begin
                    for (i := 0; i<pagecount; i++)
                    begin
                      if (pagemap_entries[i] >> 63) then //present
                      begin
                        if (currentstart=-1) then //new entry
                          currentstart := i;

                        //total3+=pagesize;
                      end
                      {$else}
                      begin
                        if (currentstart <> -1) then
                        begin
                          //store this section (from currentstart to i-1)
                          AddToRegionList((uint64_t)(current+currentstart*pagesize), (i-currentstart)*pagesize, type, protection, (* C2PAS: RefOrBit? *)&r, (* C2PAS: RefOrBit? *)&pos, (* C2PAS: RefOrBit? *)&max);
                        end;

                        currentstart := -1;
                      end;
                    end;

                    if (currentstart <> -1) then
                    begin
                      //store this section (from currentstart to pagecount)
                      Integer count := pagecount-currentstart;
                      AddToRegionList((uint64_t)(current+currentstart*pagesize), count*pagesize, type, protection, (* C2PAS: RefOrBit? *)&r, (* C2PAS: RefOrBit? *)&pos, (* C2PAS: RefOrBit? *)&max);
                    end;

                    current+ := pagecount*pagesize;
                  end;


                end;

              end
              {$else}
                AddToRegionList(start, stop-start, type, protection, (* C2PAS: RefOrBit? *)&r, (* C2PAS: RefOrBit? *)&pos, (* C2PAS: RefOrBit? *)&max);
            end;



          end;


          //declare a new clean block for the next iteration
          isdirty := 0;
          StrCopy(protectionstring, temp);
          start := _start;
          stop := _stop;
        end
        {$else}
        begin
          //one of the info lines

          if (dirtyonly and (start <> 0)) then
          begin
            //figure out if it's something I am interested in (dirty pages)
            Integer i;
            Integer number;
            char name[32];
            i := sscanf(x, '%31[^:]: %d', name, (* C2PAS: RefOrBit? *)&number);
            if (i=2) then
            begin
              if ((number>0) and ((StrComp(name,'Shared_Dirty')=0) or (StrComp(name,'Private_Dirty')=0))) then //the value is >0 and it's information about the dirty state
                isdirty := 1;
            end;


          end;

        end;


      end;

     // debug_log("End of loop\n");

      if (maps) then
        fclose(maps);

      if (pagemap> := 0) then
        close(pagemap);


      *count := pos;
      *rinfo := r;

      if (pagemap_entries) then
        free(pagemap_entries);

      fflush(stdout);

      (* C2PAS: Exit *) Result := 1;
    end
    {$else}
    begin
      debug_log('Failure maps=%p pagemap=%d'#10'', maps, pagemap);


      if (maps) then
        fclose(maps)
      {$else}
        debug_log('Failure opening /proc/%d/smaps', p.pid);

      if (pagemap> := 0) then
        close(pagemap)
      {$else}
        debug_log('Failure opening /proc/%d/pagemap', p.pid);

      fflush(stdout);

      (* C2PAS: Exit *) Result := 0;
    end;

  end
  {$else}
    (* C2PAS: Exit *) Result := 0;

end;

Integer VirtualQueryEx(hProcess: THandle, void *lpAddress, PRegionInfo rinfo, char *mapsline)
begin
  (*
   * Alternate method: read pagemaps and look up the pfn in /proc/kpageflags (needs to 2 files open and random seeks through both files, so not sure if slow or painfully slow...)
   *)

  //VirtualQueryEx stub port. Not a real port, and returns true if successful and false on error
  Integer found := 0;

  //printf("VirtualQueryEx(%p)", lpAddress);

  if (GetHandleType(hProcess) = htProcesHandle ) then
  begin
    p: PProcessData := (PProcessData)GetPointerFromHandle(hProcess);
    FILE *maps := fopen(p.maps, 'r');
    if (maps) then
    begin
      char x[200];
      //printf("Opened %s\n", p->maps);


      rinfo.protection := 0;
      rinfo.baseaddress := (uintptr_t)lpAddress (* C2PAS: RefOrBit? *)& ~0xfff;
      lpAddress := (void *)(uintptr_t)(rinfo.baseaddress);

      while (fgets(x, 200, maps) ) do
      begin
        unsigned long long start := 0, stop := 0;
        char protectionstring[25];

        x[199] := 0;

        if (x[strlen(x)-1] <> '\n') then
        begin
          char discard[100];

          do
          begin
            discard[99] := 0;
            fgets(discard, 99, maps);
          end; while (discard[99] <> 0) do ;
        end;




        sscanf(x, '%llx-%llx %s', (* C2PAS: RefOrBit? *)&start, (* C2PAS: RefOrBit? *)&stop, protectionstring);
       // debug_log("%llx - %llx : %s\n", start,stop, protectionstring);

        if (stop > ((uintptr_t)lpAddress) ) then //we passed it
        begin
          found := 1;

          if (((uintptr_t)lpAddress) > := start ) then
          begin
            //it's inside the region, so useable

            rinfo.protection := ProtectionStringToProtection(protectionstring);
            rinfo.type := ProtectionStringToType(protectionstring);
            rinfo.size := stop-rinfo.baseaddress;
          end
          {$else}
          begin
            rinfo.size := start-rinfo.baseaddress;
            rinfo.protection := PAGE_NOACCESS;
            rinfo.type := 0;
          end;

          if (mapsline <> nil) then
            StrCopy(mapsline, x);

          break;
        end;
      end;

      fclose(maps);

      (* C2PAS: Exit *) Result := found;
    end
    {$else}
    begin
      debug_log('failed opening %s'#10'', p.maps);
    end;
  end;

  (* C2PAS: Exit *) Result := 0;
end;

Integer SearchHandleListProcessCallback(PProcessData data, Integer *pid)
(*
 * Callback. Called during the call to SearchHandleList
 * Searchdata is a pointer to the processid to be looked for
 *)
begin
  (* C2PAS: Exit *) Result := (data.pid=*pid);
end;

HANDLE OpenProcess(DWORD pid)
begin
  //check if the process exists
  char processpath[100];
  Integer handle;
  sprintf(processpath, '/proc/%d/', pid);


  //check if this process has already been opened
  handle := SearchHandleList(htProcesHandle, SearchHandleListProcessCallback, (* C2PAS: RefOrBit? *)&pid);
  if (handle) then
  begin
    debug_log('Already opened. Returning same handle'#10'');
    p: PProcessData := (PProcessData)GetPointerFromHandle(handle);
    p.ReferenceCount++;
    (* C2PAS: Exit *) Result := handle;
  end;

  //still here, so not opened yet


  if (chdir(processpath)=0) then
  begin
    //success

    //create a process info structure and return a handle to it
    p: PProcessData := (PProcessData)malloc(sizeof(ProcessData));

    memset(p, 0, sizeof(ProcessData));

    p.ReferenceCount := 1;
    p.pid := pid;
    p.path := strdup(processpath);

    sprintf(processpath,'/proc/%d/maps', pid);
    p.maps := strdup(processpath);

    if (MEMORY_SEARCH_OPTION = 0) then
    begin
      sprintf(processpath,'/proc/%d/mem', pid);
      p.mem := open(processpath, O_RDONLY);
    end;


    pthread_mutex_init((* C2PAS: RefOrBit? *)&p.extensionMutex, nil);
    p.hasLoadedExtension := 0;
    p.extensionFD := 0;


    p.isDebugged := 0;

    p.threadlistmax := 0;
    p.threadlistpos := 0;
    p.threadlist := nil;

    p.debuggedThreadEvent.threadid :=0;

    pthread_mutex_init((* C2PAS: RefOrBit? *)&p.debugEventQueueMutex, nil);

    (*
    p->queuedDebugEventList=NULL;
    p->queuedDebugEventListPos=0;
    p->queuedDebugEventListMax=0;
    *)

    TAILQ_INIT((* C2PAS: RefOrBit? *)&p.debugEventQueue);






    (* C2PAS: Exit *) Result := CreateHandleFromPointer(p, htProcesHandle);


  end
  {$else}
    (* C2PAS: Exit *) Result := 0; //could not find the process

end;


CBool Process32Next(HANDLE hSnapshot, PProcessListEntry processentry)
begin
  //get the current iterator of the list and increase it. If the max has been reached, return false
 // debug_log("Process32Next\n");

  if (GetHandleType(hSnapshot) = htTHSProcess) then
  begin
    PProcessList pl := (PProcessList)GetPointerFromHandle(hSnapshot);

    if (pl.processListIterator<pl.processCount) then
    begin
      processentry.PID := pl.processList[pl.processListIterator].PID;
      processentry.ProcessName := pl.processList[pl.processListIterator].ProcessName; //no need to copy
      pl.processListIterator++;

      (* C2PAS: Exit *) Result := TRUE;
    end
    {$else}
      (* C2PAS: Exit *) Result := FALSE;
  end
  {$else}
    (* C2PAS: Exit *) Result := FALSE;
end;




CBool Process32First(HANDLE hSnapshot, PProcessListEntry processentry)
begin
  //Get a processentry from the processlist snapshot. fill the given processentry with the data.

 // debug_log("Process32First\n");
  if (GetHandleType(hSnapshot) = htTHSProcess) then
  begin
    PProcessList pl := (PProcessList)GetPointerFromHandle(hSnapshot);
    pl.processListIterator := 0;
    (* C2PAS: Exit *) Result := Process32Next(hSnapshot, processentry);
  end
  {$else}
    (* C2PAS: Exit *) Result := FALSE;
end;


CBool Module32Next(HANDLE hSnapshot, PModuleListEntry moduleentry)
begin
  //get the current iterator of the list and increase it. If the max has been reached, return false
  debug_log('Module32First/Next(%d)'#10'', hSnapshot);

  if (GetHandleType(hSnapshot) = htTHSModule) then
  begin
    PModuleList ml := (PModuleList)GetPointerFromHandle(hSnapshot);

    if (ml.moduleListIterator<ml.moduleCount) then
    begin
      moduleentry.baseAddress := ml.moduleList[ml.moduleListIterator].baseAddress;
      moduleentry.moduleName := ml.moduleList[ml.moduleListIterator].moduleName;
      moduleentry.moduleSize := ml.moduleList[ml.moduleListIterator].moduleSize;

      ml.moduleListIterator++;

      //printf("Module32First/Next: Returning %s size %x\n", moduleentry->moduleName, moduleentry->moduleSize);

      (* C2PAS: Exit *) Result := TRUE;
    end
    {$else}
    begin
      debug_log('Module32First/Next: Returning false because ml->moduleListIterator=%d and ml->moduleCount=%d'#10'', ml.moduleListIterator, ml.moduleCount);
      (* C2PAS: Exit *) Result := FALSE;
    end;
  end
  {$else}
  begin
    debug_log('Module32First/Next: GetHandleType(hSnapshot)=%d'#10'',GetHandleType(hSnapshot));
    (* C2PAS: Exit *) Result := FALSE;
  end;
end;


CBool Module32First(HANDLE hSnapshot, PModuleListEntry moduleentry)
begin

  //printf("Module32First\n");
  if (GetHandleType(hSnapshot) = htTHSModule) then
  begin
    PModuleList ml := (PModuleList)GetPointerFromHandle(hSnapshot);
    ml.moduleListIterator := 0;
    (* C2PAS: Exit *) Result := Module32Next(hSnapshot, moduleentry);
  end
  {$else}
    (* C2PAS: Exit *) Result := FALSE;
end;


HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID)
begin

  if (dwFlags (* C2PAS: RefOrBit? *)& TH32CS_SNAPPROCESS) then
  begin
    //create a processlist which process32first/process32next will make use of. Not often called so you may make it as slow as you wish
    Integer max := 2048;
    PProcessList pl := (PProcessList)malloc(sizeof(ProcessList));

    //printf("Creating processlist\n");

    pl.ReferenceCount := 1;
    pl.processCount := 0;
    pl.processList := (PProcessListEntry)malloc(sizeof(ProcessListEntry)* max);

    DIR *procfolder := opendir('/proc/');

    struct dirent *currentfile;

    while ((currentfile := readdir(procfolder)) <> nil) do
    begin

      if (strspn(currentfile.d_name, '1234567890')=strlen(currentfile.d_name)) then
      begin
        Integer pid;
        char exepath[200];
        char processpath[512];
        snprintf(exepath, 200, '/proc/%s/exe', currentfile.d_name);
        exepath[199] := 0; //'should' not be needed in linux, but I read that microsoft is an asshole with this function

        Integer i := readlink(exepath, processpath, 254);
        if (i <> -1) then
        begin
          char extrafile[255];
          Integer f;

          if (i>254) then
            i := 254;

          processpath[i] := 0;

          snprintf(extrafile, 255, '/proc/%s/cmdline', currentfile.d_name);
          extrafile[254] := 0;

          f := open(extrafile, O_RDONLY);
          if (f <> -1) then
          begin
            i := read(f, extrafile, 255);
            if (i> := 0) then
              extrafile[i] := 0
            {$else}
              extrafile[0] := 0;

            StrCat(processpath,' ');
            StrCat(processpath,extrafile);

            close(f);
          end;


          sscanf(currentfile.d_name, '%d', (* C2PAS: RefOrBit? *)&pid);
         // debug_log("%d - %s\n", pid, processpath);

          //add this process to the list
          pl.processList[pl.processCount].PID := pid;
          pl.processList[pl.processCount].ProcessName := strdup(processpath);

          pl.processCount++;

          if (pl.processCount> := max) then
          begin
            max := max*2;
            pl.processList := (PProcessListEntry)realloc(pl.processList, max*sizeof(ProcessListEntry));
          end;
        end;


      end;

    end;

    closedir(procfolder);

    (* C2PAS: Exit *) Result := CreateHandleFromPointer(pl, htTHSProcess);
  end
  {$else}
  if ((dwFlags (* C2PAS: RefOrBit? *)& TH32CS_SNAPMODULE) and (ATTACH_PID = 0 or (ATTACH_PID <> 0 and (th32ProcessID = ATTACH_PID)))) then
  begin
    //make a list of all the modules loaded by processid th32ProcessID
    //the module list
    Integer max := 64;
    char mapfile[255];
    FILE *f := nil;
    snprintf(mapfile, 255, '/proc/%d/maps', th32ProcessID);

    PModuleList ml := (PModuleList)malloc(sizeof(ModuleList));

    debug_log('Creating module list for process %d'#10'', th32ProcessID);

    ml.ReferenceCount := 1;
    ml.moduleCount := 0;
    ml.moduleList := (PModuleListEntry)malloc(sizeof(ModuleListEntry)*max);


    f := fopen(mapfile, 'r');


    if (f) then
    begin
      char s[512];
      memset(s, 0, 512);

      PModuleListEntry mle := nil;
      Integer phandle := OpenProcess(th32ProcessID);
      Integer hasValidModuleSize := 0;



      while (fgets(s, 511, f)) do //read a line into s
      begin
        unsigned long long start, stop;
        char memoryrange[64],protectionstring[32],modulepath[511];
        uint32_t magic;

        modulepath[0] := '\0';
        memset(modulepath, 0, 255);


        sscanf(s, '%llx-%llx %s %*s %*s %*s %[^'#9''#10']'#10'', (* C2PAS: RefOrBit? *)&start, (* C2PAS: RefOrBit? *)&stop, protectionstring, modulepath);

        if (ProtectionStringToType(protectionstring)=MEM_MAPPED) then
          continue;

        if (modulepath[0]) then //it's something
        begin
          Integer i;
          if (StrComp(modulepath, '[heap]')=0) then  //not static enough to mark as a 'module'
            continue;

          debug_log('%s'#10'', modulepath);

          if (StrComp(modulepath, '[vdso]') <> 0) then  //temporary patch as to not rename vdso, because it is treated differently by the ce symbol loader
          begin
            for (i := 0; modulepath[i]; i++) //strip square brackets from the name (conflicts with pointer notations)
            begin
              if ((modulepath[i]='[') or (modulepath[i]=']')) then
                modulepath[i] := '_';
            end;
          end;

          if ((mle) and (StrComp(modulepath, mle.moduleName)=0)) then
          begin
            //same module as the last entry, adjust the size to encapsule this (may mark non module memory as module memory)
            if (hasValidModuleSize=0) then
              mle.moduleSize := stop-(mle.baseAddress); //{$else} use the already provided modulesize
            continue;
          end;

          //new module, or not linkable

//          debug_log("%llx : %s\n", start, modulepath);

          //check if it starts with ELF

           //printf("tempbuf=%s\n", tempbuf);
          i := ReadProcessMemory(phandle, (void *)start, (* C2PAS: RefOrBit? *)&magic, 4);
          if (i=0) then
          begin
            //printf("%s is unreadable(%llx)\n", modulepath, start);
            continue; //unreadable
          end;

          //printf("i=%d\n", i);

          if (magic <>$464c457f) then //  7f 45 4c 46
          begin
            //printf("%s is not an ELF(%llx).  tempbuf=%s\n", modulepath, start, tempbuf);
            continue; //not an ELF
          end;

          //printf("Found an ELF\n");

          mle := (* C2PAS: RefOrBit? *)&ml.moduleList[ml.moduleCount];
          mle.moduleName := strdup(modulepath);
          mle.baseAddress := start;
          mle.moduleSize := GetModuleSize(modulepath, 0);

          hasValidModuleSize := mle.moduleSize <> 0;

        //  debug_log("Setting size of %s to %x\n", modulepath, mle->moduleSize);

          ml.moduleCount++;

          if (ml.moduleCount> := max) then
          begin
            //printf("reallocate modulelist\n");
            max := max*2;
            ml.moduleList := (PModuleListEntry)realloc(ml.moduleList, max* sizeof(ModuleListEntry));
          end;


        end
        {$else}
          mle := nil;



      end;

      CloseHandle(phandle);

      fclose(f);

      (* C2PAS: Exit *) Result := CreateHandleFromPointer(ml, htTHSModule);
    end
    {$else}
    begin
      debug_log('Failed opening %s'#10'', mapfile);
      (* C2PAS: Exit *) Result := 0;
    end;



  end;


  (* C2PAS: Exit *) Result := 0;
end;

void CloseHandle(HANDLE h)
begin
  Integer i;
  handleType ht := GetHandleType(h);

 // debug_log("CloseHandle(%d)\n", h);
  if (ht=htTHSModule) then
  begin
    ModuleList *ml := (PModuleList)GetPointerFromHandle(h);
    ml.ReferenceCount--;
    if (ml.ReferenceCount< := 0) then
    begin
      //free all the processnames in the list
      for (i := 0; i<ml.moduleCount; i++)
        free(ml.moduleList[i].moduleName);

      free(ml.moduleList); //free the list
      free(ml); //free the descriptor

      RemoveHandle(h);
    end;

  end;
  if (ht=htTHSProcess) then
  begin
    ProcessList *pl :=(PProcessList)GetPointerFromHandle(h);


    pl.ReferenceCount--;

    if (pl.ReferenceCount< := 0) then
    begin
      //free all the processnames in the list
      for (i := 0; i<pl.processCount; i++)
        free(pl.processList[i].ProcessName);

      free(pl.processList); //free the list
      free(pl); //free the descriptor

      RemoveHandle(h);
    end;
  end
  {$else}
  if (ht=htProcesHandle) then
  begin
    p: PProcessDatad := (PProcessData)GetPointerFromHandle(h);

    pd.ReferenceCount--;
    if (pd.ReferenceCount< := 0) then
    begin
      free(pd.maps);
      free(pd.path);
      close(pd.mem);
      free(pd);

      RemoveHandle(h);
    end;
  end
  {$else}
  if (ht=htNativeThreadHandle) then
  begin
    uint64_t *th := GetPointerFromHandle(h);
    debug_log('Closing thread handle'#10'');

    free(th);
    RemoveHandle(h);
  end
  {$else}
    RemoveHandle(h); //no idea what it is...


end;

void initAPI()
begin
  pthread_mutex_init((* C2PAS: RefOrBit? *)&memorymutex, nil);
  pthread_mutex_init((* C2PAS: RefOrBit? *)&debugsocketmutex, nil);

  sem_init((* C2PAS: RefOrBit? *)&sem_DebugThreadEvent, 0, 0); //locked by default

end;

{}


//
//{api.h}
//
//(*
// * api.h
// *
// *  Created on: Jul 21, 2011
// *      Author: erich
// *)
//
////{$if }ndef API_H_
////#define API_H_
//
//uses
//
////#include <stdint.h>
////#include <pthread.h>
////#include <sys/queue.h>
//
//  CEporthelp,
//  CEcontext
//
////#include <sys/ptrace.h>
//
////{$ifdef android}
////  CElog,
////{$endif}
//(*
//
//{$if defined(CPUARM) or defined(android)}
//#include <linux/user.h>
//{${$else}}
//#include <sys/user.h>
//{$endif}
//*)
//
////{$ifdef linux} //HAS_LINUX_USER_H
////  CElinux_user
////{${$else}}
////  CEsys_user
////{$endif}
//  ;
//
//
//const
//  VQE_PAGEDONLY = 1;
//  VQE_DIRTYONLY = 2;
//  VQE_NOSHARED  = 4;
//
//type
//typedef struct
//{
//  unsigned long long baseAddress;
//  int moduleSize;
//  char *moduleName;
//
//} ModuleListEntry, *PModuleListEntry;
//
//typedef struct
//{
//  int PID;
//  char *ProcessName;
//
//} ProcessListEntry, *PProcessListEntry;
//
////#pragma pack(1)
//
//typedef struct
//{
//  uint8_t num_brps;   //number of instruction breakpoints
//  uint8_t num_wrps;   //number of data breakpoints
//  uint8_t wp_len;     //max length of a data breakpoint
//  uint8_t debug_arch; //debug architecture
//
//} HBP_RESOURCE_INFO, *PHBP_RESOURCE_INFO;
//
//{$ifdef CPUARM}
//(*  struct user_pt_regs
//  {
//    long regs[18];
//  };
//
//  struct user_hwdebug_state {
//   __u32 dbg_info;
//   struct {
//   __u32 addr;
//   __u32 ctrl;
//   } dbg_regs[16];
//  };
//
//const
//  NT_ARM_HW_WATCH  = $403;
//  PTRACE_GETREGSET = $4204;
//  PTRACE_SETREGSET = $4205;
//*)
//{$endif}
//
//
//typedef struct {
//  int debugevent;
//  int64_t threadid;
//  union
//  {
//    uint64_t address; //TRAP: Address that caused trap
//    struct {
//      uint8_t maxBreakpointCount; //Number of execute breakpoints this system supports at most
//      uint8_t maxWatchpointCount;
//      uint8_t maxSharedBreakpoints; //If the system uses the same kind of breakpoints for execute and watchpoints. 0 otherwise
//    }; //CreateProcess
//  };
////other data
//} DebugEvent, *PDebugEvent;
//
//type
//  DebugEventQueueElement = record
//    entries: TAILQ_ENTRY(DebugEventQueueElement);
//    de:      DebugEvent;
//  end;
//
////#pragma pack()
//
//TAILQ_HEAD(debugEventQueueHead, DebugEventQueueElement);
//
//
//typedef struct {
//  int tid;
//  int isPaused;
//  int suspendCount;
//  DebugEvent suspendedDevent; //debug event to be injected when resumed
//} ThreadData, *PThreadData;
//
//typedef struct {
//  int ReferenceCount;
//  int pid;
//  int mapfd; //file descriptor for /proc/pid/maps
//  char *path;
//  char *maps;
//  int mem;
//  int hasLoadedExtension; //set to true if the ceserver extension has been loaded in this process
//  int neverForceLoadExtension; //set to true if you don't want to force load the module (if it's loaded, use it, but don't use the injection method)
//  pthread_mutex_t extensionMutex;
//  int extensionFD; //socket to communicate with the target
//
//  int isDebugged; //if this is true no need to attach/detach constantly, BUT make sure the debugger thread does do it's job
//  pthread_t debuggerThreadID;
//
//  PThreadData threadlist;
//  int threadlistmax;
//  int threadlistpos;
//
//  DebugEvent debuggedThreadEvent;
//
//  int debuggerServer; //sockets for communicating with the debugger thread by local threads
//  int debuggerClient;
//
//
//
//
//  pthread_mutex_t debugEventQueueMutex; //probably not necessary as all queue operations are all done in the debuggerthread of the process
//
//  struct debugEventQueueHead debugEventQueue;
//} ProcessData, *PProcessData;
//
//
//
////#pragma pack(1)
//typedef struct {
//  uint64_t baseaddress;
//  uint64_t size;
//  uint32_t protection;
//  uint32_t type;
//} RegionInfo, *PRegionInfo;
////#pragma pack()
//
//{$if } defined __i386__ or defined __x86_64__
//typedef struct _regDR6
//{
//  union{
//    uintptr_t value;
//    struct {
//      unsigned B0        :1;
//      unsigned B1        :1;
//      unsigned B2        :1;
//      unsigned B3        :1;
//      unsigned Reserved  :9;
//      unsigned BD        :1;
//      unsigned BS        :1;
//      unsigned BT        :1;
//    };
//  };
//} __attribute__((__packed__)) regDR6,*PregDR6;
//{$endif}
//
//
//
//
//
//void CloseHandle(HANDLE h);
//BOOL Process32Next(HANDLE hSnapshot, PProcessListEntry processentry);
//BOOL Process32First(HANDLE hSnapshot, PProcessListEntry processentry);
//HANDLE CreateToolhelp32Snapshot(DWORD dwFlags, DWORD th32ProcessID);
//HANDLE OpenProcess(DWORD pid);
//int VirtualQueryEx(hProcess: THandle, void *lpAddress, PRegionInfo rinfo, char *mapsline);
//int VirtualQueryExFull(hProcess: THandle, uint32_t flags, RegionInfo **rinfo, uint32_t *count);
//int ReadProcessMemory(hProcess: THandle, void *lpAddress, void *buffer, int size);
//int WriteProcessMemory(hProcess: THandle, void *lpAddress, void *buffer, int size);
//
//int StartDebug(hProcess: THandle);
//int StopDebug(hProcess: THandle);
//
//int WaitForDebugEventNative(p: PProcessData, devent: PDebugEvent, int tid, int timeout);
//int WaitForDebugEvent(hProcess: THandle, devent: PDebugEvent, int timeout);
//int ContinueFromDebugEvent(hProcess: THandle, int tid, int ignoresignal);
//int GetDebugPort(hProcess: THandle);
//
//int SetBreakpoint(hProcess: THandle, int tid, int debugreg, void *address, int bptype, int bpsize);
//int RemoveBreakpoint(hProcess: THandle, int tid, int debugreg, int wasWatchpoint);
//
//int SuspendThread(hProcess: THandle, int tid);
//int ResumeThread(hProcess: THandle, int tid);
//
//int GetThreadContext(hProcess: THandle, int tid, PCONTEXT Context, int type);
//int SetThreadContext(hProcess: THandle, int tid, PCONTEXT Context, int type);
//
//PDebugEvent FindThreadDebugEventInQueue(p: PProcessData, int tid);
//void AddDebugEventToQueue(p: PProcessData, devent: PDebugEvent);
//int RemoveThreadDebugEventFromQueue(p: PProcessData, int tid);
//
//void initAPI();
//
//extern pthread_mutex_t debugsocketmutex;
//
//{$ifdef android}
//  const
//    LOG_TAG = 'CESERVER'
//  #define LOGD(fmt, args...) __android_log_vprint(ANDROID_LOG_DEBUG, LOG_TAG, fmt, ##args)
//{$endif}
//
//int debug_log(const char * format , ...);
//long safe_ptrace(int request, pid_t pid, void * addr, void * data);
//extern int MEMORY_SEARCH_OPTION;
//extern int ATTACH_PID;
//extern unsigned char SPECIFIED_ARCH;
//{$endif}
//
//{api.h end}
//
//function sprintf(__s: Pchar; __format: Pchar; args: Pointer): longint; cdecl; external 'clib' name 'sprintf';
//
//function OpenProcess( pid : DWORD):THandle;
//var
//  processpath : array[0..99] of byte;
//  handle      : integer;
//  p           : PProcessData;
//begin
//  //check if the process exists
//  sprintf(processpath, '/proc/%d/', pid);
//  //check if this process has already been opened
//  handle := SearchHandleList(htProcesHandle, SearchHandleListProcessCallback, &pid);
//  if handle then begin
//    debug_log('Already opened. Returning same handle\n');
//    p := (PProcessData)GetPointerFromHandle(handle);
//    p.PostInc(ReferenceCount);
//    Exit(handle);
//  end;
//  //still here, so not opened yet
//  if chdir(processpath then =0)
//  begin
//    //success
//    //create a process info structure and return a handle to it
//    p := (PProcessData)malloc(sizeof(ProcessData));
//    memset(p, 0, sizeof(ProcessData));
//    p.ReferenceCount := 1;
//    p.pid := pid;
//    p.path := strdup(processpath);
//    sprintf(processpath,'/proc/%d/maps', pid);
//    p.maps := strdup(processpath);
//    if MEMORY_SEARCH_OPTION = 0 then begin
//      sprintf(processpath,'/proc/%d/mem', pid);
//      p.mem := open(processpath, O_RDONLY);
//    end;
//    pthread_mutex_init(&p.extensionMutex, nil);
//    p.hasLoadedExtension := 0;
//    p.extensionFD := 0;
//    p.isDebugged := 0;
//    p.threadlistmax := 0;
//    p.threadlistpos := 0;
//    p.threadlist := nil;
//    p.debuggedThreadEvent.threadid := 0;
//    pthread_mutex_init(&p.debugEventQueueMutex, nil);
//    {
//    p.queuedDebugEventList := nil;
//    p.queuedDebugEventListPos := 0;
//    p.queuedDebugEventListMax := 0;
//    }
//    TAILQ_INIT(&p.debugEventQueue);
//    Exit(CreateHandleFromPointer(p, htProcesHandle));
//  end;
//  {$else}
//    return 0; //could not find the process
//end;
//
//end.
//
