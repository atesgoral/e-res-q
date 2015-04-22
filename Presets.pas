unit Presets;

interface

uses
  Classes, SysUtils;

const
  DEFAULTPORT = 110;

type
  TPreset = class
    ID: Integer;
    Alias, Server, ServerRaw: String;
    Port: Word;
    User, Pass: String;
  end;

  TPresetList = class
    constructor Create;
    destructor Destroy; override;
  private
    List: TList;
  public
    function Add(NID: Integer; NAlias, NServer: String; NPort: Word; NUser, NPass: String): TPreset;
    procedure Remove(Index: Integer);
    function PresetAt(Index: Integer): TPreset;
    function Count: Integer;
  end;

implementation

{ TPresetList }

constructor TPresetList.Create;
begin
  List := TList.Create;
end;

destructor TPresetList.Destroy;
begin
  while (List.Count > 0) do
    Remove(0);
  List.Free;
end;

function TPresetList.Add(NID: Integer; NAlias, NServer: String; NPort: Word;
  NUser, NPass: String): TPreset;
begin
  Result := TPreset.Create;
  with Result do
    begin
      ID := NID;
      Alias := NAlias;
      Server := NServer;
      if (NPort = DEFAULTPORT) then
        ServerRaw := NServer
      else
        ServerRaw := Format('%s:%d', [NServer, NPort]);
      Port := NPort;
      User := NUser;
      Pass := NPass;
    end;
  List.Add(Result);
end;

function TPresetList.Count: Integer;
begin
  Result := List.Count;
end;

function TPresetList.PresetAt(Index: Integer): TPreset;
begin
  Result := TPreset(List[Index]);
end;

procedure TPresetList.Remove(Index: Integer);
begin
  TPreset(List[Index]).Free;
  List.Delete(Index);
end;

end.
