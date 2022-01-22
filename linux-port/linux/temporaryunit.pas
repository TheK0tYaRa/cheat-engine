unit temporaryunit;

{$mode delphi}

interface

function SendMessage(hWnd: THandle; Msg: Word; wParam: Word; lParam: LongInt): QWord;

implementation

function SendMessage(hWnd: THandle; Msg: Word; wParam: Word; lParam: LongInt): QWord;
begin
  { #todo -cSendMessage : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage }
  if hWnd <> $ffff then
  begin
    //send to all top-level windows

  end
  else
  begin
    //send everywhere

  end;
end;

end.

