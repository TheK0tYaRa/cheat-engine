unit pseudoregistry;

{$mode delphi}

interface

uses
  Unix,betterControls;

function loadFromConfigDefault(ConfDir: UnicodeString; Config: string): boolean;overload;
function loadFromConfigDefault:boolean;overload;

implementation
(*var
  HomeDir:  PChar = FPC_SYSC_FPGETENV('HOME');//i hate it
  ConfigDir:UnicodeString = '/.config/Cheat Engine/';
  *)
function loadFromConfigDefault(ConfDir: UnicodeString; Config: string): boolean;
begin
  { TODO -cloadFromConfigDefault : Write this at some point before it launches }
  (*

function TSynCustomHighlighterHelper.loadFromRegistryDefault(RootKey: HKEY; Key: string): boolean;
//for highlighters that do not implement loadFromRegistry , like the cpp highlighter
var
  reg: TRegistry;
  i: integer;
begin
  reg:=tregistry.create;
  reg.RootKey:=Rootkey;
  result:=false;

  if reg.OpenKey(Key,false) then
  begin
    result:=true;
    for i:=0 to AttrCount-1 do
      result:=result and Attribute[i].LoadFromRegistry(reg);
  end;

  reg.free;

  if result=false then
  begin
    if self is TSynCppSyn then //load default C colors
    begin
      with TSynCppSyn(Self) do
      begin
        if ShouldAppsUseDarkMode then
        begin

          CommentAttri.Foreground:=$ff00;
          CommentAttri.Style:=[fsItalic];
          CommentAttri.StyleMask:=[fsItalic];

          IdentifierAttri.Foreground:=$ffff;
          InvalidAttri.Foreground:=$ff;
          NumberAttri.Foreground:=$ffff00;
          DirecAttri.Foreground:=$5024b5;
          KeyAttri.Foreground:=$e1af04;
          KeyAttri.Style:=[fsBold];
          KeyAttri.StyleMask:=[fsBold];
          StringAttri.Foreground:=$c0dcc0;
          SymbolAttri.Foreground:=$c0c0c0;
        end
        else
        begin
          CommentAttri.Foreground:=$808000;
          CommentAttri.Style:=[fsItalic];
          CommentAttri.StyleMask:=[fsItalic];

          IdentifierAttri.Foreground:=$364bc5;
          InvalidAttri.Foreground:=$ff;
          NumberAttri.Foreground:=$ff0000;
          DirecAttri.Foreground:=$5024b5;
          KeyAttri.Foreground:=$800000;
          KeyAttri.Style:=[fsBold];
          KeyAttri.StyleMask:=[fsBold];
          StringAttri.Foreground:=$3de12f;
          SymbolAttri.Foreground:=$808080;

        end;

      end;
    end;

  end;

  DefHighlightChange(self);
end;

*)
end;

function loadFromConfigDefault: boolean;
begin
  result:=loadFromConfigDefault(ConfigDir,'CPP Highlighter'+darkmodestring);
end;

end.

