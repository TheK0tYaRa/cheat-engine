unit keys;

{$mode delphi}

interface
type
  short = SmallInt;

function GetKeyState(nVirtKey: integer): SHORT;

implementation

function GetKeyState(nVirtKey: integer): SHORT;
begin
  { TODO -cGetKeyState : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeystate }
end;

end.

