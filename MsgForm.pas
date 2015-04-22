unit MsgForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ERQMessage, OleCtrls, SHDocVw;

type
  TFormMsg = class(TForm)
    Panel1: TPanel;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    ListView: TListView;
    ListView1: TListView;
    TabControl1: TTabControl;
    WebBrowser: TWebBrowser;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    Msg: TERQMessage;
  public
    constructor Create(AOwner: TComponent; Msg: TERQMessage);
  end;

var
  FormMsg: TFormMsg;

implementation

{$R *.dfm}

uses
  ActiveX;

{ TFormMsg }


constructor TFormMsg.Create(AOwner: TComponent; Msg: TERQMessage);
begin
  inherited Create(AOwner);

  Self.Msg := Msg;
end;

procedure TFormMsg.FormActivate(Sender: TObject);
var
  MS: TStringStream;
  PersistStreamInit: IPersistStreamInit;
  SA: TStreamAdapter;
  Cnt: Integer;

  HS: TStringList;
  LI: TListItem;

  Header: String;

begin
{
  Memo1.Lines.Append('Content-type: ' + Msg.ContentType);
  Memo1.Lines.Append('Content-disposition: ' + Msg.ContentDisposition);

  Memo1.Lines.Append('parts count: ' + IntToStr(Msg.MessageParts.Count));

  for Cnt := 0 to Msg.MessageParts.Count - 1 do
   begin
     Memo1.Lines.Append('  Content-type: ' + Msg.MessageParts[Cnt].ContentType);
     TabControl1.Tabs.Append(Msg.MessageParts[Cnt].ContentType);
   end;

  Memo1.Lines.AddStrings(Msg.Body);


  //HS := TStringList.Create;
//  Msg.Headers.ConvertToStdValues(HS);
  //Msg.Headers.UnfoldLines := True;

  for Cnt := 0 to Msg.Headers.Count - 1 do
  begin
    Header := Msg.Headers.Names[Cnt];

    if (Length(Header) > 0) and
      (ListView.FindCaption(0, Header, False, True, False) = nil) then
    begin
      LI := ListView.Items.Add;
      LI.Caption := Header;
      LI.SubItems.Append(Header);
      LI.SubItems.Append(Msg.Headers.Values[Header]);
    end;
  end;

  //-------------------
  // Load a blank page.
  //-------------------
  WebBrowser.Navigate('about:blank');
  while WebBrowser.ReadyState <> READYSTATE_COMPLETE do
  begin
    Sleep(5);
    Application.ProcessMessages;
  end;


  MS := TStringStream.Create(Msg.Body.Text);

  if WebBrowser.Document.QueryInterface(
      IPersistStreamInit, PersistStreamInit
    ) = S_OK then
    begin
      // Clear document
      if PersistStreamInit.InitNew = S_OK then
      begin
        // Get IStream interface on stream
        SA := TStreamAdapter.Create(MS);
        // Load data from Stream into WebBrowser
        //PersistStreamInit.Load(StreamAdapter);
        PersistStreamInit.Load(SA);
      end;
    end;
    }
end;

procedure TFormMsg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Msg.ViewForm := nil;
  Action := caFree;
end;

end.
