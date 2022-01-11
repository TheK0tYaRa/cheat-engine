unit unixmemory;

{$mode delphi}

interface

uses
  Classes, SysUtils,commonTypeDefs,unixporthelper;

type
  TAddresslist=record
    pos: integer;
    maxsize: integer;
    a: PPtrUintArray;
    isstring: boolean;
    pointsto: ptruint; //0 if not a pointer
    pointstostring: boolean;
  end;
  PAddresslist=^TAddresslist;

procedure ZeroMemory(Destination:PVOID;Length:SIZE_T);

implementation

procedure ZeroMemory(Destination:PVOID;Length:SIZE_T);
//var
//  array of pointer
begin
  { TODO -cZeroMemory : Gonna finish it after it gets to the debugger stuff
  https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa366920(v=vs.85)}

end;

end.

