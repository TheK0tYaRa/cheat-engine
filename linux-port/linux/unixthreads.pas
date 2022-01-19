unit unixthreads;

{$mode delphi}

interface

uses
  unixporthelper, uconst;

const
  INVALID_HANDLE_VALUE = THandle(-1);

  THREAD_ALL_ACCESS = $1FFFFF;

  EXIT_THREAD_DEBUG_EVENT = 4;

  { timeout }
  INFINITE = longint($FFFFFFFF);

  { what is it for again? }
  WAIT_OBJECT_0 = 0;
  WAIT_TIMEOUT  = $102;

type
  PTHREAD_START_ROUTINE = Pointer;
  SECURITY_ATTRIBUTES = record
    nLength : DWORD;
    lpSecurityDescriptor : LPVOID;
    bInheritHandle : Boolean;
  end;

  LPDWORD = ^DWORD;
  LPSECURITY_ATTRIBUTES = ^SECURITY_ATTRIBUTES;
  LPTHREAD_START_ROUTINE = PTHREAD_START_ROUTINE;

  { TLHelp32 }
  PMODULEENTRY32 = ^MODULEENTRY32;
  tagMODULEENTRY32 = record
    dwSize: DWORD;
    th32ModuleID: DWORD;       // This module
    th32ProcessID: DWORD;      // owning process
    GlblcntUsage: DWORD;       // Global usage count on the module
    ProccntUsage: DWORD;       // Module usage count in th32ProcessID's context
    modBaseAddr: LPBYTE;       // Base address of module in th32ProcessID's context
    modBaseSize: DWORD;        // Size in bytes of module starting at modBaseAddr
    hModule: HMODULE;          // The hModule of this module in th32ProcessID's context
    szModule: array [0..MAX_MODULE_NAME32] of Char;
    szExePath: array [0..MAX_PATH - 1] of Char;
  end;
  MODULEENTRY32   = tagMODULEENTRY32;
  LPMODULEENTRY32 = ^MODULEENTRY32;
  TModuleEntry32  = LPMODULEENTRY32;

  tagTHREADENTRY32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ThreadID: DWORD;
    th32OwnerProcessID : DWORD;
    tpBasePri  : LONG;
    tpDeltaPri : LONG;
    dwFlags    : DWORD;
  end;
  THREADENTRY32   = tagTHREADENTRY32;
  LPTHREADENTRY32 = ^THREADENTRY32;
  TThreadEntry32  = LPTHREADENTRY32;

{ Threads }
function CreateRemoteThread(hProcess: THandle; lpThreadAttributes: LPSECURITY_ATTRIBUTES;
  dwStackSize: SIZE_T; lpStartAddress: LPTHREAD_START_ROUTINE; lpParameter: LPVOID;
  dwCreationFlags: DWORD; var lpThreadId: LPDWORD): THandle;

function GetCurrentProcessId: DWORD;
function GetCurrentProcess: THandle;

function OpenThread(dwDesiredAccess:DWORD; bInheritHandle:BOOL; dwThreadId:DWORD):THandle;

function GetExitCodeThread(hThread: THandle; var lpExitCode: LongWord ): boolean;

{ TLHelp32 }
function  CreateToolhelp32Snapshot(dwFlags: DWORD; th32ProcessID: DWORD): THandle;

function Thread32First(hSnapshot: THandle; var lpte: LPTHREADENTRY32): Boolean;
function Thread32Next(hSnapshot: THandle; var lpte: LPTHREADENTRY32):Boolean;

function Module32First(hSnapshot: Thandle; var lpme: LPMODULEENTRY32):Boolean;
function Module32Next(hSnapshot: THandle; var lpme: LPMODULEENTRY32):Boolean;

implementation

{ Threads }
function CreateRemoteThread(hProcess: THandle; lpThreadAttributes: LPSECURITY_ATTRIBUTES;
  dwStackSize: SIZE_T; lpStartAddress: LPTHREAD_START_ROUTINE; lpParameter: LPVOID;
  dwCreationFlags: DWORD; var lpThreadId: LPDWORD): THandle;
begin
  { TODO -cCreateRemoteThread : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createremotethread }
end;

function GetCurrentProcessId: DWORD;
begin
  { TODO -cGetCurrentProcessId : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocessid }
end;

function OpenThread(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwThreadId: DWORD): THandle;
begin
  { TODO -cOpenThread : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthread }
end;

function GetExitCodeThread(hThread: THandle; var lpExitCode: LongWord ): boolean;
begin
  { #todo -cGetExitCodeThread : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodethread }
end;

function GetCurrentProcess: THandle;
var
  pid: dword;
begin
  { #todo -cGetCurrentProcess : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess }
  pid := GetProcessID;
  GetCurrentProcess := -1;
end;

{ TLHelp32 }
function  CreateToolhelp32Snapshot(dwFlags: DWORD; th32ProcessID: DWORD): THandle;
begin
  { #todo -cCreateToolhelp32Snapshot : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot }
end;

function Thread32First(hSnapshot: THandle; var lpte: LPTHREADENTRY32): Boolean;
begin
  { #todo -cThread32First : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32first }
end;

function Thread32Next(hSnapshot: THandle; var lpte: LPTHREADENTRY32):Boolean;
begin
  { #todo -cThread32Next : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32next }
end;

function Module32First(hSnapshot: Thandle; var lpme: LPMODULEENTRY32):Boolean;
begin
  { #todo -cModule32First : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-module32first }
end;

function Module32Next(hSnapshot: THandle; var lpme: LPMODULEENTRY32): Boolean;
begin
  { #todo -cModule32Next : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-module32next }
end;

end.

