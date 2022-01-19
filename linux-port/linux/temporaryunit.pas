unit temporaryunit;

{$mode delphi}

interface

type
  HWND = THandle;
  UINT = Word;

  WParam = UINT;
  LParam = LongInt;

  LResult = QWord;

function SendMessage(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;

implementation

function SendMessage(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  { #todo -cSendMessage : https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessage }
end;

end.

