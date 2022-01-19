unit
linuxbase; //jwawinbase alternative for linux, name pending

{$mode delphi}

interface

uses
  Classes, SysUtils, unixporthelper, unixtype;

const
  {$IFDEF UNICODE}
  AWSuffix = 'W';
  {$ELSE}
  AWSuffix = 'A';
  {$ENDIF UNICODE}
  GENERIC_READ             = $80000000;
  FILE_FLAG_SEQUENTIAL_SCAN = $8000000;
  FILE_SHARE_READ   = 1;
  OPEN_EXISTING     = 3;
  FILE_SHARE_DELETE = 4;

type
  LPCSTR = ^Char;
  LPCWSTR = wchar_t;
  SECURITY_ATTRIBUTES = record
    nLength : DWORD;
    lpSecurityDescriptor : LPVOID;
    bInheritHandle : WINBOOL;
  end;
  LPSECURITY_ATTRIBUTES = ^SECURITY_ATTRIBUTES;

  LONGLONG = int64;
  LARGE_INTEGER = QWord; (*record  //eh fuck it
  case byte of
    0: (LowPart : DWORD;
        HighPart : LONG);
    1: (QuadPart : LONGLONG);
  end;*)
  //PLARGE_INTEGER = ^LARGE_INTEGER;

function CreateFile(lpFileName: LPCSTR; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: LPSECURITY_ATTRIBUTES; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle;
function GetFileSizeEx(hFile: THandle; var lpFileSize: LARGE_INTEGER): BOOL;

implementation

function CreateFileA(lpFileName: LPCSTR; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: LPSECURITY_ATTRIBUTES; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle;
begin                         //char
  { TODO -cCreateFileA : https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea }
end;

function CreateFileW(lpFileName: LPCWSTR;dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: LPSECURITY_ATTRIBUTES; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle;
begin                         //wchar_t
  { TODO -cCreateFileW : https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew }
end;

function CreateFile(lpFileName: LPCSTR; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: LPSECURITY_ATTRIBUTES; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle;
begin
  (*
  GetProcedureAddress(_CreateFile, kernel32, 'CreateFile' + AWSuffix);
  asm
        MOV     ESP, EBP
        POP     EBP
        JMP     [_CreateFile]
  end;
  *)
  case AWSuffix of  //you know what? fuck you. *unlongints your char*
    'A':(CreateFileA(lpFileName,dwDesiredAccess,dwShareMode,
      lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile));
    'W':(CreateFileW(wchar_t(byte(lpFileName)),dwDesiredAccess,dwShareMode,
      lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile));
  end;
end;

function GetFileSizeEx(hFile: THandle; var lpFileSize: LARGE_INTEGER): BOOL;
begin
  { TODO -cGetFileSizeEx : https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfilesizeex }
end;

end.

