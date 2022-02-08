unit unixporthelper;

{$mode delphi}
{$WARN 5033 off : Function result does not seem to be set}
interface

uses
  Classes, SysUtils, {$ifdef android}log,{$else}unixdebug,{$endif} BaseUnix;

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
  //HANDLE=integer;
  //HDC=HANDLE;
  //HWND=HANDLE;
  HICON=THANDLE;
  HMODULE=THANDLE;
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
  //PTHREADENTRY32 = ^THREADENTRY32;
  //tagTHREADENTRY32 = record
  //  dwSize: DWORD;
  //  cntUsage: DWORD;
  //  th32ThreadID: DWORD;       // this thread
  //  th32OwnerProcessID: DWORD; // Process this thread is associated with
  //  tpBasePri: LONG;
  //  tpDeltaPri: LONG;
  //  dwFlags: DWORD;
  //end;
  //THREADENTRY32 = tagTHREADENTRY32;
  //LPTHREADENTRY32 = ^THREADENTRY32;        // LPTHREADENTRY32 = ^THREADENTRY32 = ^tagTHREADENTRY32
  //TThreadEntry32 = THREADENTRY32;

  //LPMODULEENTRY32 = ^tagMODULEENTRY32;

{$ifdef ANDROID}
function GetTempDir: string;
var tempdirOverride: string;
{$endif}

function VirtualAlloc(lpAddress:LPVOID; dwSize:PTRUINT; flAllocationType:DWORD; flProtect:DWORD):LPVOID;
function VirtualFree(lpAddress:LPVOID; dwSize:PTRUINT; dwFreeType:DWORD):WINBOOL;

//function VirtualAllocEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; flAllocationType,flProtect:DWORD):LPVOID;
//function VirtualFreeEx(hProcess:HANDLE; lpAddress:LPVOID; dwSize:SIZE_T; dwFreeType:DWORD):BOOL;

//function OpenThread(dwDesiredAccess:DWORD; bInheritHandle:BOOL; dwThreadId:DWORD):HANDLE;

//procedure CloseHandle(hObject:THANDLE);

//function CreateToolhelp32Snapshot(dwFlags,th32ProcessID:DWORD):HANDLE;
//function Thread32First(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
//function Thread32Next(hSnapshot:HANDLE; lpte:tagTHREADENTRY32):BOOL;
//function Module32First(hSnapshot:HANDLE; lpme:tagMODULEENTRY32):BOOL;

function GetLastError:DWORD;

function CopyFile(source: string; destination: string; failifdestinationExists: boolean=false): boolean;
Function DirectoryExistsUTF8 (Const Directory : RawByteString) : Boolean;
Function CreateDirUTF8(Const NewDir : UnicodeString) : Boolean;

function QueryPerformanceFrequency(var tps: TLargeInteger): boolean;
function QueryPerformanceCounter(var currenttick: TLargeInteger): boolean;

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


//function CreateToolhelp32Snapshot(dwFlags,th32ProcessID:DWORD):THandle;
//begin
//  { TODO -cCreateToolhelp32Snapshot : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-createtoolhelp32snapshot }
//end;

//function Thread32First(hSnapshot:THandle; lpte:tagTHREADENTRY32):BOOL;
//begin
//  { TODO -cThread32First : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32first }
//end;

//function Thread32Next(hSnapshot:THandle; lpte:tagTHREADENTRY32):BOOL;
//begin
//  { TODO -cThread32Next : https://docs.microsoft.com/en-us/windows/win32/api/tlhelp32/nf-tlhelp32-thread32next }
//end;

//function Module32First(hSnapshot:THandle; lpme:tagMODULEENTRY32):BOOL;
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

procedure log(l: string);
begin
{$ifdef android}
  __android_log_write(ANDROID_LOG_ERROR, 'CECORE',pchar(l));
{$endif}

{$if defined(windows) or defined(linux)}
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

