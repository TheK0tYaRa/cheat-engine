unit UnixUI;

{$mode delphi}

interface

uses
  unixporthelper;

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

procedure MessageBox(hWnd: HWND; lpText: LPCTSTR; lpCaption: LPCTSTR; uType: UINT);

implementation

procedure MessageBox(hWnd: HWND; lpText: LPCTSTR; lpCaption: LPCTSTR; uType: UINT);
begin

end;

end.

