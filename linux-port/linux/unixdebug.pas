unit unixdebug;

{$mode Delphi}

interface

//uses
//  unixporthelper;

const
  EXCEPTION_NONCONTINUABLE     = $1; // Noncontinuable exception
  EXCEPTION_MAXIMUM_PARAMETERS = 15; // maximum number of exception parameters

type
  PEXCEPTION_RECORD = ^EXCEPTION_RECORD;
  _EXCEPTION_RECORD = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: PEXCEPTION_RECORD;
    ExceptionAddress: Pointer;
    NumberParameters: DWORD;
    ExceptionInformation: array [0..EXCEPTION_MAXIMUM_PARAMETERS - 1] of PtrUInt;
  end;
  EXCEPTION_RECORD = _EXCEPTION_RECORD;
  TExceptionRecord = EXCEPTION_RECORD;
  PExceptionRecord = PEXCEPTION_RECORD;

  _EXCEPTION_RECORD32 = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: DWORD;
    ExceptionAddress: DWORD;
    NumberParameters: DWORD;
    ExceptionInformation: array [0..EXCEPTION_MAXIMUM_PARAMETERS - 1] of DWORD;
  end;
  EXCEPTION_RECORD32 = _EXCEPTION_RECORD32;
  PEXCEPTION_RECORD32 = ^EXCEPTION_RECORD32;
  TExceptionRecord32 = EXCEPTION_RECORD32;
  PExceptionRecord32 = PEXCEPTION_RECORD32;

  _EXCEPTION_RECORD64 = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: UInt64;
    ExceptionAddress: UInt64;
    NumberParameters: DWORD;
    __unusedAlignment: DWORD;
    ExceptionInformation: array [0..EXCEPTION_MAXIMUM_PARAMETERS - 1] of UInt64;
  end;
  EXCEPTION_RECORD64 = _EXCEPTION_RECORD64;
  PEXCEPTION_RECORD64 = ^EXCEPTION_RECORD64;
  TExceptionRecord64 = EXCEPTION_RECORD64;
  PExceptionRecord64 = PEXCEPTION_RECORD64;

  _EXCEPTION_DEBUG_INFO = record
    ExceptionRecord: EXCEPTION_RECORD;
    dwFirstChance: DWORD;
  end;
  EXCEPTION_DEBUG_INFO = _EXCEPTION_DEBUG_INFO;
  LPEXCEPTION_DEBUG_INFO = ^EXCEPTION_DEBUG_INFO;
  TExceptionDebugInfo = EXCEPTION_DEBUG_INFO;
  PExceptionDebugInfo = LPEXCEPTION_DEBUG_INFO;

type
  PTHREAD_START_ROUTINE = function(lpThreadParameter: Pointer): DWORD; stdcall;
  LPTHREAD_START_ROUTINE = PTHREAD_START_ROUTINE;
  TThreadStartRoutine = PTHREAD_START_ROUTINE;
  LPCREATE_THREAD_DEBUG_INFO = ^CREATE_THREAD_DEBUG_INFO;
  _CREATE_THREAD_DEBUG_INFO = record
    hThread: THandle;
    lpThreadLocalBase: Pointer;
    lpStartAddress: LPTHREAD_START_ROUTINE;
  end;
  CREATE_THREAD_DEBUG_INFO = _CREATE_THREAD_DEBUG_INFO;
  TCreateThreadDebugInfo = CREATE_THREAD_DEBUG_INFO;
  PCreateThreadDebugInfo = LPCREATE_THREAD_DEBUG_INFO;

type
  LPCREATE_PROCESS_DEBUG_INFO = ^CREATE_PROCESS_DEBUG_INFO;
  _CREATE_PROCESS_DEBUG_INFO = record
    hFile: THandle;
    hProcess: THandle;
    hThread: THandle;
    lpBaseOfImage: Pointer;
    dwDebugInfoFileOffset: DWORD;
    nDebugInfoSize: DWORD;
    lpThreadLocalBase: Pointer;
    lpStartAddress: LPTHREAD_START_ROUTINE;
    lpImageName: Pointer;
    fUnicode: Word;
  end;
  CREATE_PROCESS_DEBUG_INFO = _CREATE_PROCESS_DEBUG_INFO;
  TCreateProcessDebugInfo = CREATE_PROCESS_DEBUG_INFO;
  PCreateProcessDebugInfo = LPCREATE_PROCESS_DEBUG_INFO;

type
  LPEXIT_THREAD_DEBUG_INFO = ^EXIT_THREAD_DEBUG_INFO;
  _EXIT_THREAD_DEBUG_INFO = record
    dwExitCode: DWORD;
  end;
  EXIT_THREAD_DEBUG_INFO = _EXIT_THREAD_DEBUG_INFO;
  TExitThreadDebugInfo = EXIT_THREAD_DEBUG_INFO;
  PExitThreadDebugInfo = LPEXIT_THREAD_DEBUG_INFO;

type
  LPEXIT_PROCESS_DEBUG_INFO = ^EXIT_PROCESS_DEBUG_INFO;
  _EXIT_PROCESS_DEBUG_INFO = record
    dwExitCode: DWORD;
  end;
  EXIT_PROCESS_DEBUG_INFO = _EXIT_PROCESS_DEBUG_INFO;
  TExitProcessDebugInfo = EXIT_PROCESS_DEBUG_INFO;
  PExitProcessDebugInfo = LPEXIT_PROCESS_DEBUG_INFO;

type
  LPLOAD_DLL_DEBUG_INFO = ^LOAD_DLL_DEBUG_INFO;
  _LOAD_DLL_DEBUG_INFO = record
    hFile: THandle;
    lpBaseOfDll: Pointer;
    dwDebugInfoFileOffset: DWORD;
    nDebugInfoSize: DWORD;
    lpImageName: Pointer;
    fUnicode: Word;
  end;
  LOAD_DLL_DEBUG_INFO = _LOAD_DLL_DEBUG_INFO;
  TLoadDllDebugInfo = LOAD_DLL_DEBUG_INFO;
  PLoadDllDebugInfo = LPLOAD_DLL_DEBUG_INFO;

type
  LPUNLOAD_DLL_DEBUG_INFO = ^UNLOAD_DLL_DEBUG_INFO;
  _UNLOAD_DLL_DEBUG_INFO = record
    lpBaseOfDll: Pointer;
  end;
  UNLOAD_DLL_DEBUG_INFO = _UNLOAD_DLL_DEBUG_INFO;
  TUnloadDllDebugInfo = UNLOAD_DLL_DEBUG_INFO;
  PUnloadDllDebugInfo = LPUNLOAD_DLL_DEBUG_INFO;

type
  LPOUTPUT_DEBUG_STRING_INFO = ^OUTPUT_DEBUG_STRING_INFO;
  _OUTPUT_DEBUG_STRING_INFO = record
    lpDebugStringData: PChar;
    fUnicode: Word;
    nDebugStringLength: Word;
  end;
  OUTPUT_DEBUG_STRING_INFO = _OUTPUT_DEBUG_STRING_INFO;
  TOutputDebugStringInfo = OUTPUT_DEBUG_STRING_INFO;
  POutputDebugStringInfo = LPOUTPUT_DEBUG_STRING_INFO;

type
  LPRIP_INFO = ^RIP_INFO;
  _RIP_INFO = record
    dwError: DWORD;
    dwType: DWORD;
  end;
  RIP_INFO = _RIP_INFO;
  TRipInfo = RIP_INFO;
  PRipInfo = LPRIP_INFO;

type
  LPDEBUG_EVENT = ^DEBUG_EVENT;
  _DEBUG_EVENT = record
    dwDebugEventCode: DWORD;
    dwProcessId: DWORD;
    dwThreadId: DWORD;
    case Integer of
      0: (Exception: EXCEPTION_DEBUG_INFO);
      1: (CreateThread: CREATE_THREAD_DEBUG_INFO);
      2: (CreateProcessInfo: CREATE_PROCESS_DEBUG_INFO);
      3: (ExitThread: EXIT_THREAD_DEBUG_INFO);
      4: (ExitProcess: EXIT_PROCESS_DEBUG_INFO);
      5: (LoadDll: LOAD_DLL_DEBUG_INFO);
      6: (UnloadDll: UNLOAD_DLL_DEBUG_INFO);
      7: (DebugString: OUTPUT_DEBUG_STRING_INFO);
      8: (RipInfo: RIP_INFO);
  end;
  DEBUG_EVENT = _DEBUG_EVENT;
  TDebugEvent = DEBUG_EVENT;
  PDebugEvent = LPDEBUG_EVENT;

const
  DBG_CONTINUE              =    $10002;
  DBG_EXCEPTION_NOT_HANDLED = $80010001;

  EXCEPTION_DEBUG_EVENT      = 1;
  CREATE_THREAD_DEBUG_EVENT  = 2;
  CREATE_PROCESS_DEBUG_EVENT = 3;
  EXIT_PROCESS_DEBUG_EVENT   = 5;
  LOAD_DLL_DEBUG_EVENT       = 6;
  UNLOAD_DLL_DEBUG_EVENT     = 7;
  OUTPUT_DEBUG_STRING_EVENT  = 8;
  RIP_EVENT                  = 9;

const    //yes, ntstatus aka LONG, { TODO -cNtStatus : fix that before it gets to debugging }
  STATUS_WX86_SINGLE_STEP = Integer($4000001E);
  {$EXTERNALSYM STATUS_WX86_SINGLE_STEP}
  STATUS_WX86_BREAKPOINT =  Integer($4000001F);
  {$EXTERNALSYM STATUS_WX86_BREAKPOINT}

function IsDebuggerPresent:boolean;
procedure OutputDebugString(l:string);

implementation

function IsDebuggerPresent:boolean;
begin
  { #todo -cIsDebuggerPresent : https://docs.microsoft.com/en-us/windows/win32/api/debugapi/nf-debugapi-isdebuggerpresent }
  //IsDebuggerPresent:=false;
end;

procedure OutputDebugString(l:string);
begin
  writeln(l);
end;

end.

