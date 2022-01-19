unit unixkeys;

{$mode delphi}

interface

uses
  LCL, LCLType;

type
  short = SmallInt;

const
  MOD_CONTROL = VK_CONTROL;
  MOD_ALT     = VK_MENU;
  MOD_SHIFT   = VK_SHIFT;

function GetKeyState(nVirtKey: integer): SHORT;
function GetAsyncKeyState(vKey: integer): SHORT;

implementation

function GetKeyState(nVirtKey: integer): SHORT;
begin
  { TODO -cGetKeyState : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeystate }
end;

function GetAsyncKeyState(vKey: integer): SHORT;
begin
  { #todo -cGetAsyncKeyState : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getasynckeystate }
end;

end.

