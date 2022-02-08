unit unixhandles;

{$mode objfpc}{$H+}
{$WARN 5033 off : Function result does not seem to be set}
interface

type
  HDC  = THandle;
  HWND = THandle;

{processthreadsapi.h}
function OpenProcess(dwDesiredAccess: DWORD; bInheritHandle: Boolean; dwProcessId: DWORD): THandle;

{}
function GetDC(hWnd:THandle):THandle;
function ReleaseDC(hWnd: THandle; hDC: THandle):Boolean;
function CloseHandle(hObject:THandle):Boolean;

implementation

{processthreadsapi.h}
function OpenProcess(dwDesiredAccess: DWORD; bInheritHandle: Boolean; dwProcessId: DWORD): THandle;
begin
  { #todo -cOpenProcess : https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess }
  //
end;

{}
function GetDC(hWnd:THandle):THandle;
begin
  { #todo -cGetDC : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getdc }
end;

function ReleaseDC(hWnd: THandle; hDC: THandle):Boolean;
begin
  { #todo -cReleaseDC : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-releasedc }
end;

function CloseHandle(hObject:THandle):Boolean;
begin
  { TODO -cCloseHandle : https://docs.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle }
end;

end.

