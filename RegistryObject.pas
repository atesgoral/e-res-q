unit RegistryObject;

interface

uses
  Classes, Registry, Windows;

type
  TRegistryObject = class
  private
    Parent: TRegistryObject;
    Key: String;
    Children: TList;
    StringValue: String;
    IntegerValue: Integer;
  public
    constructor Create(Parent: TRegistryObject; const Key: String);
    procedure Save;
    procedure Load;
    function AddSubKey(const Key: String; const Value: String): TRegistryObject;
      overload;
    function AddSubKey(const Key: String; Value: Integer): TRegistryObject;
      overload;
    function GetStringValue: String;
    function GetIntegerValue: Integer;
  end;

implementation

{ TRegistryObject }

function TRegistryObject.AddSubKey(const Key, Value: String): TRegistryObject;
begin
  Result := TRegistryObject.Create(Self, Key);
  Result.StringValue := Value;
  Children.Add(Result);
end;

function TRegistryObject.AddSubKey(const Key: String; Value: Integer):
  TRegistryObject;
begin
  Result := TRegistryObject.Create(Self, Key);
  Result.IntegerValue := Value;
  Children.Add(Result);
end;

constructor TRegistryObject.Create(Parent: TRegistryObject; const Key: String);
begin
  Self.Parent := Parent;
  Self.Key := Key;
  Children := TList.Create;
end;

function TRegistryObject.GetIntegerValue: Integer;
begin
  Result := IntegerValue;
end;

function TRegistryObject.GetStringValue: String;
begin
  Result := StringValue;
end;

procedure TRegistryObject.Load;
var
  Reg: TRegistry;

begin
  Reg := TRegistry.Create(KEY_READ or KEY_QUERY_VALUE or
    KEY_ENUMERATE_SUB_KEYS);
  Reg.OpenKey(Key, False);

//  Reg.GetDataInfo();
  Reg.CloseKey;
  Reg.Free;
end;

procedure TRegistryObject.Save;
begin

end;

end.
