unit unixerrors;

{$mode delphi}

interface

const
  NO_ERROR = 0;
  ERROR_NOT_ENOUGH_MEMORY = 8;

  {exceptions shamelessly borrowed from win/wininc/defines.inc}
  EXCEPTION_ACCESS_VIOLATION    = $c0000005;
  EXCEPTION_ILLEGAL_INSTRUCTION = $c000001d;
  EXCEPTION_PRIV_INSTRUCTION    = $c0000096;
  EXCEPTION_BREAKPOINT          = $80000003;
  EXCEPTION_SINGLE_STEP         = $80000004;

procedure SetLastError(dwErrCode:DWORD);

implementation

procedure SetLastError(dwErrCode:DWORD);
begin
  { TODO -cSetLastError : https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-setlasterror }
end;

end.

