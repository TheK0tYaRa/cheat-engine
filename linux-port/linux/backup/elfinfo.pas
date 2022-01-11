unit ELFInfo;

{$mode delphi}

interface

uses
  Classes;

function elfinfo_getSectionList(modulebase: ptruint; sectionList: Tstrings): boolean;

implementation

function elfinfo_getSectionList(modulebase: ptruint; sectionList: Tstrings): boolean;
begin
  { TODO -celfinfo_getSectionList :  }
end;

end.

