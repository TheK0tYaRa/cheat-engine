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

procedure ZeroMemory(destination: pointer; size: integer);
procedure CopyMemory(destination: pointer; Origin: pointer; size: integer);
procedure MoveMemory(destination: pointer; Origin: pointer; size: integer);
procedure FillMemory(destination: pointer; Length: integer; Filler: BYTE);

implementation

procedure ZeroMemory(destination: pointer; size: integer);
begin
  //log('ZeroMemory');
  FillByte(destination^, size, 0); //perhaps filldword might be faster, but for now keep it compatible
  //log('ZeroMemory returned');
end;

procedure MoveMemory(destination: pointer; Origin: pointer; size: integer);
begin
  Move(Origin^, Destination^, size);
end;

procedure CopyMemory(destination: pointer; Origin: pointer; size: integer);
begin
  MoveMemory(destination, origin, size);
end;

procedure FillMemory(destination: pointer; Length: integer; Filler: BYTE);
begin
  { TODO -cFollMemory : https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa366561(v=vs.85) }
  FillByte(destination^, Length, Filler); //not tested whatsoever
end;

end.

