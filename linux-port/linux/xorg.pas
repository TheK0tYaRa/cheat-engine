unit xorg;

{$mode delphi}

interface

uses
  unixporthelper, dialogs, unixhandles;

const
  MB_OK = $0000;

function GetForegroundWindow(): THandle;
function MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: Cardinal = MB_OK): integer;

implementation

function GetForegroundWindow(): THandle;
var
  w:HWND;
begin
  { TODO -cGetForegroundWindow : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getforegroundwindow }
  // xdotool getwindowfocus
end;

function MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: Cardinal = MB_OK): integer;
begin
  DefaultMessageBox(lpText, lpCaption, uType);
end;

end.

