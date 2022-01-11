unit ELFInfo;

{$mode delphi}

interface

uses
  Classes;

function elf_getSectionList(modulebase: ptruint; sectionList: Tstrings): boolean;

implementation

function elf_getSectionList(modulebase: ptruint; sectionList: Tstrings): boolean;
begin
  { TODO -celf_getSectionList :  }
end;

end.

