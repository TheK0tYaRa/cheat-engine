unit unixerrors;

{$mode delphi}

interface

const
  ERROR_NOT_ENOUGH_MEMORY = 8;

procedure SetLastError(dwErrCode:DWORD);

implementation

procedure SetLastError(dwErrCode:DWORD);
begin
  { TODO -cSetLastError : https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-setlasterror }
end;

end.

