unit xorg;

{$mode delphi}

interface

uses
  unixporthelper;

function GetForegroundWindow():Handle;

implementation

function GetForegroundWindow():Handle;
var
  w:HWND;
begin
  { TODO -cGetForegroundWindow : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getforegroundwindow }
  // xdotool getwindowfocus
end;

end.

