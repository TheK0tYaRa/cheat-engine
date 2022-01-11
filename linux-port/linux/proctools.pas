unit proctools;
interface
uses
  unix;

function GetHugePageMinimum:size_t;

implementation

function GetHugePageMinimum:size_t;
Var
  C : String;
  F : TextFile;
begin
  Assign (F,'/proc/cpuinfo');
  Reset (F);
  C:='';
  While not Eof(f) do
    Begin
    Readln (F,C);
    if pos('pse',C)>0 then
      exit(2097152)
    else
      if pos('pdpe1gb',C)>0 then
        exit(1073741824);
    end;
 Writeln;
 Close (F);
end;

end.

