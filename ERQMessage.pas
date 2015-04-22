unit ERQMessage;

interface

uses
  Classes, ComCtrls, IdMessage, Forms, SysUtils, StrUtilsX;

type
  TERQMessage = class
  private
//    IdMsg: TIdMessage;
  public
    ListItem: TListItem;
    Index: Integer;
    Octets: Integer;

    ViewForm: TForm;

    FHaveSize, FHaveHeaders, FHaveBody: Boolean;

    constructor Create(
      AOwner: TComponent;
      ListItem: TListItem;
      Index, Octets: Integer);

    procedure ShowSize;
    procedure ShowHeaders;

    procedure ProcessHeaders;
//    procedure MyProcessHeaders;
  end;

implementation

{ TERQMessage }

uses
  IdMessageCoderMIME, // Here so the 'MIME' in create will always suceed
  IdGlobal, IdMessageCoder, IdResourceStrings, IdStream,
  IdMessageClient, IdIOHandlerStream, IdStrings, IdCoderHeader,

//uses
  _Trace;

procedure TERQMessage.ProcessHeaders;
begin
  Trace(Format('TERQMessage.ProcessHeaders Index: %d', [Index]));
  //inherited ProcessHeaders;
  //MyProcessHeaders;
end;
constructor TERQMessage.Create(
  AOwner: TComponent;
  ListItem: TListItem;
  Index, Octets: Integer);
begin
//  inherited Create(AOwner);

//  Self.SetParentComponent(AOwner); // nec???

  Self.ListItem := ListItem;
  Self.Index := Index;
  Self.Octets := Octets;

//  Headers := TStringList.Create;

  ViewForm := nil;
end;

procedure TERQMessage.ShowSize;
begin
  if (Octets > -1) then
    ListItem.SubItems[0] := IntToUnitStr(Octets);
end;

procedure TERQMessage.ShowHeaders;
begin
  // method??
  // 0 <-  size = content-length + header length??
//  ListItem.SubItems[1] := FormatDateTime('yyyy-mm-dd hh:nn', FDate);
// ListItem.SubItems[2] := FFrom.Name;
//  ListItem.SubItems[3] := FSubject;
  ListItem.SubItems[1] := 'Date';
  ListItem.SubItems[2] := 'From';
  ListItem.SubItems[3] := 'Subject';
end;

end.
