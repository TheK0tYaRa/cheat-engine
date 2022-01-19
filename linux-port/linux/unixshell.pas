unit unixshell;

{$mode Delphi}

interface

uses
  Process,
  linuxbase
  ;

type
  HINSTANCE = QWord;

//function shellexecute(execWithPathAbs: String): boolean;
function ShellExecute(hwnd: Integer=0; lpOperation: LPCSTR=''; lpFile: LPCSTR='';
  lpParameters: LPCSTR=''; lpDirectory: LPCSTR=''; nShowCmd: Integer=0): HINSTANCE;

implementation

function ShellExecute(hwnd: Integer=0; lpOperation: LPCSTR=''; lpFile: LPCSTR='';
  lpParameters: LPCSTR=''; lpDirectory: LPCSTR=''; nShowCmd: Integer=0): HINSTANCE;
var prc: TProcess;
begin
  writeln('ShellExecute dummy');
  if lpFile <> '' then
  begin
    if nShowCmd <> 0 then
    begin
      prc:=TProcess.Create ( nil ) ;
      prc.CommandLine:= lpFile;
      prc.Execute;
      prc.free;
    end
    else
    begin
      writeln('nShowCmd not zero');
    end;
  end
  else
    writeln('no lpFile');
end;

end.

