unit unixkeys;

{$mode delphi}

interface

uses
  LCL, LCLType;

const
  MOD_CONTROL = VK_CONTROL;
  MOD_ALT     = VK_MENU;
  MOD_SHIFT   = VK_SHIFT;

function GetKeyState(nVirtKey: Integer): Smallint;
function GetAsyncKeyState(vKey: integer): SmallInt;

implementation

           { ughhh, this is garbage. imma just do this for now
              Probably gonna borrow it from wine later }

function GetKeyState(nVirtKey: Integer): Smallint;
begin
  { #todo -cGetKeyState : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeystate }
  result := 0;
end;

function GetAsyncKeyState(vKey: integer): SmallInt;
begin
  { #todo -cGetAsyncKeyState : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getasynckeystate }
  result := 0;
end;

end.

