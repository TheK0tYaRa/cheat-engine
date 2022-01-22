unit UnixUI;

{$mode delphi}

interface

uses
  unixporthelper, unixhandles, unixdebug, Forms, Dialogs;

type
  LPCSTR = {$IFDEF USE_DELPHI_TYPES} Windows.LPCSTR {$ELSE} PAnsiChar {$ENDIF};
  {$EXTERNALSYM LPCSTR}

  {$IFDEF UNICODE}
  LPCTSTR = LPTSTR;
  {$EXTERNALSYM LPCTSTR}

  {$else}
  LPCTSTR = LPCSTR;
  {$EXTERNALSYM LPCTSTR}

  {$ENDIF UNICODE}

function MessageBox(hWnd: THandle = 0; lpText: LPCTSTR = 'Text'; lpCaption: LPCTSTR = 'Caption';
  uType: UINT = $0):Integer;

implementation

function MessageBox(hWnd: THandle = 0; lpText: LPCTSTR = 'Text'; lpCaption: LPCTSTR = 'Caption';
  uType: UINT = $0):Integer;
begin
  OutputDebugString('Untested linux MessageBox');
  if hWnd <> 0 then
    OutputDebugString('HWND is not implemented in MessageBox on linux yet');
  result:=Application.MessageBox(lpText,lpCaption,uType);
end;

end.

