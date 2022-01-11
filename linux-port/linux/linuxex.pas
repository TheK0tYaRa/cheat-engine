unit LinuxEx;

{$mode Delphi}

interface

uses
  Process;

function RunIt(execWithPathAbs: String): boolean;

implementation

function RunIt(execWithPathAbs: String): boolean;
var prc: TProcess;
begin
  prc:=TProcess.Create ( nil ) ;
  prc.CommandLine:= execWithPathAbs;
  prc.Execute;
  prc.free;
end ;

end.

