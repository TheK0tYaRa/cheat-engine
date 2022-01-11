unit tea;

{$mode Delphi}

interface

type
  { TPersistent abstract class }

{$M+}

  TPersistent = class(TObject,IFPObserved)
  private
    FObservers : TFPList;
    procedure AssignError(Source: TPersistent);
  protected
    procedure AssignTo(Dest: TPersistent); virtual;
    procedure DefineProperties(Filer: TFiler); virtual;
    function  GetOwner: TPersistent; dynamic;
  public
    Destructor Destroy; override;
    procedure Assign(Source: TPersistent); virtual;
    Procedure FPOAttachObserver(AObserver : TObject);
    Procedure FPODetachObserver(AObserver : TObject);
    Procedure FPONotifyObservers(ASender : TObject; AOperation : TFPObservedOperation; Data : Pointer);
    function  GetNamePath: string; virtual; {dynamic;}
  end;

{$M-}

implementation

end.

