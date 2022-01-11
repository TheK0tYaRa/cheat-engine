unit unixporthelper;

//

{$mode delphi}

interface

uses
  Classes, SysUtils{$ifdef android},log{$endif},BaseUnix;

//just fill in some basic info. Most of it won't be used for jni. It's mostly for some structures and function declaration/pointers
type
  TColor = DWord;
  { defined by sysutils }
  //PByteArray = ^TByteArray;
  //TByteArray = Array[0..{$ifdef CPU16}32766{$else}32767{$endif}] of Byte;
  //
  //PWordarray = ^TWordArray;
  //TWordArray = array[0..{$ifdef CPU16}16382{$else}16383{$endif}] of Word;

  TLargeInteger=QWORD;
  PUINT64=^UInt64;
  ULONG_PTR=ptruint;
  ULONG64=qword;
  ULONG32=dword;
  LONG=integer;
  ULONG=DWORD;

  PULONG=^ULONG;
  DWORD_PTR=^DWORD;

  pint=^integer;

  dword64=UInt64;
  PDWORD64=^dword64;
  LONG64=UInt64;

  PVOID=pointer;
  LPBYTE=^BYTE;
  LPVOID=pointer;
  SIZE_T=QWord; //tcclib:1209 complained, so now it's QWord instead of Integer
  LPLPVOID=^pointer;
  WINBOOL=boolean;
  BOOL=boolean;
  PBOOL=^BOOL;
  PSTR=pchar;
  LPSTR=pchar;
  LPTSTR=pwidechar;
  TCHAR=WCHAR;
  PWCHAR=^WCHAR;
  UCHAR=Byte;
  USHORT=Word;
  HANDLE=integer;
  HDC=HANDLE;
  HWND=HANDLE;
  HICON=HANDLE;
  HMODULE=HANDLE;
  PHMODULE=^HMODULE;

  UINT=UInt32;
  UINT_PTR=QWord; //^UINT
  PSYSTEM_LOGICAL_PROCESSOR_INFORMATION=pointer;
  TFNThreadStartRoutine=pointer;
  //TThreadEntry32=record end; //implemented lower
  THeapList32=record end;
  TDebugEvent=record end;
  TFloatingSaveArea=record end;

  TMemoryBasicInformation=record
    BaseAddress: PVOID;
    AllocationBase: PVOID;
    AllocationProtect: ULONG;
    RegionSize: ULONG;
    State: ULONG;
    Protect: ULONG;
    _Type: ULONG;
  end;
  MEMORY_BASIC_INFORMATION  = TMemoryBasicInformation;
  _MEMORY_BASIC_INFORMATION = TMemoryBasicInformation;
  PMemoryBasicInformation   = ^TMemoryBasicInformation;

  M128A= record
    low,high: qword;
  end;

  TMessage = record
    Msg: Cardinal;
    case Integer of
      0: (
        WParam: UINT;
        LParam: LONG;
        Result: LONG);
      1: (
        WParamLo: Word;
        WParamHi: Word;
        WParamFiller: DWord;
        LParamLo: Word;
        LParamHi: Word;
        LParamFiller: DWord;
        ResultLo: Word;
        ResultHi: Word;
        ResultFiller: DWord);
  end;
  PMessage = ^TMessage;

  _MEMORYSTATUS=record end;

  //ce classes not implemented yet, but globally accessed
  TCustomProgressBar=class(Tobject)
  private
  public
    position: integer;
  end;

  TListViewItem=class(TObject)
  private
  public
    index: integer;
    procedure MakeVisible({%H-}s: boolean);
  end;

  TListViewItems=class(TStrings)
  public
    count: integer;
    function getItem({%H-}index: integer): TListViewItem;
  published
    property item[index:integer]: TListViewItem read getItem; default;
  end;

  //TListView=class(TObject)
  //private
  //public
  //  itemindex: integer;
  //  items: TListViewItems;
  //  topitem: TListViewItem;
  //  VisibleRowCount: integer;
  //  ownerdata: boolean;
  //  procedure Refresh;
  //  procedure clear;
  //  constructor create(aowner: TObject);
  //  destructor destroy; override;
  //published
  //end;

// Thread walking        //yoinked from jwatlhelp32
  PTHREADENTRY32 = ^THREADENTRY32;
  tagTHREADENTRY32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ThreadID: DWORD;       // this thread
    th32OwnerProcessID: DWORD; // Process this thread is associated with
    tpBasePri: LONG;
    tpDeltaPri: LONG;
    dwFlags: DWORD;
  end;
  THREADENTRY32 = tagTHREADENTRY32;
  LPTHREADENTRY32 = ^THREADENTRY32;        // LPTHREADENTRY32 = ^THREADENTRY32 = ^tagTHREADENTRY32
  TThreadEntry32 = THREADENTRY32;

  //LPMODULEENTRY32 = ^tagMODULEENTRY32;

const
 MAX_PATH=256;
 MAX_MODULE_NAME32=256;
 CONTEXT_i386=$10000;
 PAGE_READONLY = 2;
 PAGE_READWRITE = 4;
 PAGE_WRITECOPY = 8;
 PAGE_EXECUTE = 16;
 PAGE_EXECUTE_READ = 32;
 PAGE_EXECUTE_READWRITE = 64;
 PAGE_EXECUTE_WRITECOPY = 128;
 PAGE_GUARD = 256;
 PAGE_NOACCESS = 1;
 PAGE_NOCACHE = 512;
 MEM_COMMIT = 4096;
 MEM_FREE = 65536;
 MEM_RESERVE = 8192;
 MEM_IMAGE = 16777216;
 MEM_MAPPED = 262144;
 MEM_PRIVATE = 131072;
 MEM_DECOMMIT = 16384;
 MEM_RELEASE = 32768;
 MEM_TOP_DOWN = 1048576;
 MEM_RESET        = $80000;
 MEM_WRITE_WATCH  = $200000;
 MEM_PHYSICAL     = $400000;
 MEM_LARGE_PAGES  = $20000000;
 MEM_4MB_PAGES    = dword($80000000);

 {$ifdef cpux86_64}
 CONTEXT_AMD64=$100000;

 CONTEXT_CONTROL         = (CONTEXT_AMD64 or $00000001);
 CONTEXT_INTEGER         = (CONTEXT_AMD64 or $00000002);
 CONTEXT_SEGMENTS        = (CONTEXT_AMD64 or $00000004);
 CONTEXT_FLOATING_POINT  = (CONTEXT_AMD64 or $00000008);
 CONTEXT_DEBUG_REGISTERS = (CONTEXT_AMD64 or $00000010);

 CONTEXT_FULL            = (CONTEXT_CONTROL or CONTEXT_INTEGER or CONTEXT_FLOATING_POINT);
 CONTEXT_ALL             = (CONTEXT_CONTROL or CONTEXT_INTEGER or CONTEXT_SEGMENTS or CONTEXT_FLOATING_POINT or CONTEXT_DEBUG_REGISTERS);
 {$endif}

{
 INITIAL_MXCSR = $1f80;            // initial MXCSR value
 INITIAL_FPCSR = $027f;            // initial FPCSR value

 CONTEXT_EXCEPTION_ACTIVE    = $08000000;
 CONTEXT_SERVICE_ACTIVE      = $10000000;
 CONTEXT_EXCEPTION_REQUEST   = $40000000;
 CONTEXT_EXCEPTION_REPORTING = $80000000;
}

 THREAD_GET_CONTEXT = 8;
 THREAD_SUSPEND_RESUME = 2;
 THREAD_SET_CONTEXT = 16;
 THREAD_QUERY_INFORMATION = 64;

 INVALID_SOCKET = THandle(not(0));
 INADDR_BROADCAST=CARDINAL($FFFFFFFF);

 TH32CS_SNAPHEAPLIST = $00000001;
 TH32CS_SNAPPROCESS  = $00000002;
 TH32CS_SNAPTHREAD   = $00000004;
 TH32CS_SNAPMODULE   = $00000008;
 TH32CS_SNAPMODULE32 = 0;
 TH32CS_SNAPALL      = TH32CS_SNAPHEAPLIST or TH32CS_SNAPPROCESS or
                       TH32CS_SNAPTHREAD or TH32CS_SNAPMODULE;
 TH32CS_GETALLMODS   = $80000000;

 PROCESS_ALL_ACCESS = $1f0fff; //not really used

 clWindowText=0;

 {exceptions shamelessly borrowed from win/wininc/defines.inc}
 EXCEPTION_ACCESS_VIOLATION    = $c0000005;
 EXCEPTION_SINGLE_STEP         = $80000004;
 EXCEPTION_BREAKPOINT          = $80000003;
 EXCEPTION_ILLEGAL_INSTRUCTION = $c000001d;
 EXCEPTION_PRIV_INSTRUCTION    = $c0000096;

const                        //yes, ntstatus aka LONG, { TODO -cNtStatus : fix that before it gets to debugging }
  STATUS_WX86_SINGLE_STEP = LONG($4000001E);
  {$EXTERNALSYM STATUS_WX86_SINGLE_STEP}
  STATUS_WX86_BREAKPOINT =  LONG($4000001F);
  {$EXTERNALSYM STATUS_WX86_BREAKPOINT}

{$ifdef ANDROID}
function GetTempDir: string;
var tempdirOverride: string;
{$endif}

function VirtualAlloc(lpAddress:LPVOID; dwSize:PTRUINT; flAllocationType:DWORD; flProtect:DWORD):LPVOID;
function VirtualFree(lpAddress:LPVOID; dwSize:PTRUINT; dwFreeType:DWORD):WINBOOL;

//function VirtualAllocEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; flAllocationType,flProtect:DWORD):LPVOID;
//function VirtualFreeEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; dwFreeType:DWORD):BOOL;

//function OpenThread(dwDesiredAccess:DWORD; bInheritHandle:BOOL; dwThreadId:DWORD):HANDLE;

//procedure CloseHandle(hObject:HANDLE);

//function CreateToolhelp32Snapshot(dwFlags,th32ProcessID:DWORD):HANDLE;
//function Thread32First(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
//function Thread32Next(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
//function Module32First(hSnapshot:HANDLE; lpme:tagMODULEENTRY32):BOOL;

function GetLastError:DWORD;

function CopyFile(source: string; destination: string; failifdestinationExists: boolean=false): boolean;
Function DirectoryExistsUTF8 (Const Directory : RawByteString) : Boolean;
Function CreateDirUTF8(Const NewDir : UnicodeString) : Boolean;

function GetCurrentProcessID: SizeUInt;
procedure ZeroMemory(destination: pointer; size: integer);
procedure CopyMemory(destination: pointer; Origin: pointer; size: integer);
procedure MoveMemory(destination: pointer; Origin: pointer; size: integer);
procedure FillMemory(destination: pointer; Length: integer; Filler: BYTE);
function QueryPerformanceFrequency(var tps: TLargeInteger): boolean;
function QueryPerformanceCounter(var currenttick: TLargeInteger): boolean;

{$ifdef linux}procedure OutputDebugString(l:string);{$endif}
procedure log(l: string);

function WinCPToUTF8(s: string): string;
function UTF8ToUTF16(s: string): widestring;
function UTF16ToUTF8(s: widestring): string;


{$ifndef cefuncproc}
//for now...
function InRangeX(const AValue, AMin, AMax: ptrUint): Boolean;inline;
function InRangeQ(const AValue, AMin, AMax: QWord): Boolean;inline;

function GetSystemMetrics( nIndex:integer ):integer;

{$endif}

implementation

function UTF16ToUTF8(s: widestring): string;
begin
  result:=s;
end;

function UTF8ToUTF16(s: string): widestring;
begin
  result:=s;
end;

function WinCPToUTF8(s: string): string;
begin
  result:=AnsiToUtf8(s);
end;



function TListViewItems.getItem(index: integer): TListViewItem;
begin
  result:=nil;
end;

procedure TListViewItem.MakeVisible(s: boolean);
begin
  //
end;

//procedure TListView.Refresh;
//begin
//  //
//end;
//
//procedure TListView.clear;
//begin
//  //
//end;
//
//constructor TListView.create(aowner: TObject);
//begin
//  items:=TListViewItems.Create;
//  inherited create;
//end;

//destructor TListView.destroy;
//begin
//  if items<>nil then
//    freeandnil(items);
//
//  inherited destroy;
//end;

{$ifdef ANDROID}
function GetTempDir: string;
begin
  result:=tempdirOverride;
end;

{$endif}

Function CreateDirUTF8(Const NewDir : UnicodeString) : Boolean;
begin
  result:=false;
end;

Function DirectoryExistsUTF8 (Const Directory : RawByteString) : Boolean;
begin
  result:=false;
end;

function CopyFile(source: string; destination: string; failifdestinationExists: boolean=false): boolean;
var src,dst: TFileStream;
begin
  Log('CopyFile. source='+source+' destination='+destination+'Fail if exists'+ BoolToStr(failifdestinationExists, 'yes','no'));

  result:=false;
  try
    src:=nil;
    dst:=nil;

    if not fileexists('"'+source+'"')=false then
    begin
      log('source does not exist');
      exit;
    end;

    if failifdestinationExists and fileexists(destination) then
    begin
      log('failifdestinationExists is true and the destination exists');
      exit;
    end;


    try
      src:=tfilestream.create(source, fmOpenRead);
      dst:=tfilestream.create(destination, fmCreate);
      dst.CopyFrom(src,0); //copy the whole file

      result:=true; //still here and no exception
      log('Copy successful')
    finally
      if src<>nil then
        freeandnil(src);

      if dst<>nil then
        freeandnil(dst);
    end;


    ;
  except
    on e: exception do
      log('Error during copy:'+e.message);
  end;
end;

function VirtualFree(lpAddress:LPVOID; dwSize:PTRUINT; dwFreeType:DWORD):WINBOOL;
begin
  Fpmunmap(lpAddress, dwSize);
end;

function VirtualAlloc(lpAddress:LPVOID; dwSize:PTRUINT; flAllocationType:DWORD; flProtect:DWORD):LPVOID;
var r: pointer;
begin
  log('Calling VirtualAlloc');
  result:=Fpmmap(lpAddress,dwsize, PROT_READ or PROT_WRITE or PROT_EXEC, MAP_PRIVATE or MAP_ANONYMOUS, 0,0 );

  log('After calling VirtualAlloc. Result='+inttohex(ptruint(result),8));

end;

function VirtualAllocEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; flAllocationType,flProtect:DWORD):LPVOID;
begin
  { TODO -cVirtualAllocEx : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualallocex }
end;

function VirtualFreeEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; dwFreeType:DWORD):BOOL;
begin
  { TODO -cVirtualFreeEx : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualfreeex }
end;

function OpenThread(dwDesiredAccess:DWORD; bInheritHandle:BOOL; dwThreadId:DWORD):HANDLE;
begin
  { TODO -cOpenThread : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openthread }
end;

procedure CloseHandle(hObject:HANDLE);
begin
  { TODO -cCloseHandle : https://docs.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle }
end;

function CreateToolhelp32Snapshot(dwFlags,th32ProcessID:DWORD):HANDLE;
begin
  { TODO -cCreateToolhelp32Snapshot : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot }
end;

function Thread32First(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
begin
  { TODO -cThread32First : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32first }
end;

function Thread32Next(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
begin
  { TODO -cThread32Next : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32next }
end;

//function Module32First(hSnapshot:HANDLE; lpme:tagMODULEENTRY32):BOOL;
//begin
//  { TODO -cModule32First : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-module32first }
//end;

function GetLastError:DWORD;
begin
  { TODO -cGetLastError : https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror }
end;

function InRangeX(const AValue, AMin, AMax: ptrUint): Boolean;inline;
begin
  Result:=(AValue>=AMin) and (AValue<=AMax);
end;

function InRangeQ(const AValue, AMin, AMax: QWord): Boolean;inline;
begin
  Result:=(AValue>=AMin) and (AValue<=AMax);
end;

function QueryPerformanceFrequency(var tps: TLargeInteger): boolean;
begin
  tps:=1000;
  result:=true;
end;

function QueryPerformanceCounter(var currenttick: TLargeInteger): boolean;
begin
  currenttick:=GetTickCount64;
  result:=true;
end;

procedure ZeroMemory(destination: pointer; size: integer);
begin
  //log('ZeroMemory');
  FillByte(destination^, size, 0); //perhaps filldword might be faster, but for now keep it compatible
  //log('ZeroMemory returned');
end;

procedure MoveMemory(destination: pointer; Origin: pointer; size: integer);
begin
  Move(Origin^, Destination^, size);
end;

procedure CopyMemory(destination: pointer; Origin: pointer; size: integer);
begin
  MoveMemory(destination, origin, size);
end;

procedure FillMemory(destination: pointer; Length: integer; Filler: BYTE);
begin
  { TODO -cFollMemory : https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa366561(v=vs.85) }
  FillByte(destination^, Length, Filler); //not tested whatsoever
end;

function GetCurrentProcessID: SizeUInt;
begin
  result:=GetProcessID;
end;

{$ifdef linux}
procedure OutputDebugString(l:string);
begin
  writeln(l);
end;

{$endif}

procedure log(l: string);
begin
{$ifdef android}
  __android_log_write(ANDROID_LOG_ERROR, 'CECORE',pchar(l));
{$endif}

{$ifdef windows}
  Outputdebugstring(pchar(l));
{$endif}

end;

function GetSystemMetrics( nIndex:integer ):integer; { TODO -cGetSystemMetrics : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics }
begin
  case nIndex of
    30:GetSystemMetrics:=10; { TODO -cSM_CXSIZE : make it report actual SM_CXSIZE }
    54:GetSystemMetrics:=10; { TODO -cSM_CXMENUSIZE : make it report actual SM_CXMENUSIZE }
  end;
end;

end.

