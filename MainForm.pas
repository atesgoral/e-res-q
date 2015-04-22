unit MainForm;

interface

// TODO: Column Editor
// DONE: ! -- Position Restore
// ToDo: Double Buffered Browser
// ToDo: Account importer
// ToDo: Unique User ID Generator
// ToDo: Export - Import Settings
// ToDo: ? -- Attachment
// ToDo: ? -- Web Profile
// ToDo: ? -- Minimize to Tray
// ToDo: ? -- New Message Notification
// ToDo: show live stats: total #msgs, total KB etc.
// ToDo: Disable some ctrls when connected
// ToDo: Turbo setting per preset
// ToDo: RegEx to check valid host
// ToDo: Safe password field
// ToDo: select last selected preset by default on launch
// DONE: Connection preset -> Account Preset
// ToDo: Check for update

uses
  Messages, SysUtils, Graphics, Forms, Classes, Controls, Winsock, StdCtrls,
  ComCtrls, ExtCtrls, Contnrs,
  Registry, Menus, Dialogs, OleCtrls, SHDocVw, ScktComp,
  FlashLed, Presets, LineBuffer, ColumnsForm, StrUtilsX, IdBaseComponent,
  Buttons, ActnList, ERQMessage, MsgForm, IdMessage;

type
  TPOP3State = (
    stNone,
    stConnecting,
    stAuthorization,
    stTransaction,
    stUpdate
  );

{
  TPOP3Command = (
    cmdUser,
    cmdPass,
    cmdStat,
    cmdList,
    cmdTop,
    cmdRetr,
    cmdDele,
    cmdQuit
  );
}
  // Apop!?

  TPOP3Response = (
    //resNone,
    resWelcome,
    resUser,
    resPass,
    resStat,
    resList,
    resListData,
    resTop,
    resTopData,
    resRetr,
    resRetrData,
    resDele,
    resRset,
    resQuit
  );


  TExpectedResponse = class // Pool these objects?
  public
    POP3Response: TPOP3Response;
    Index: Integer;
    constructor Create(POP3Response: TPOP3Response; Index: Integer);
  end;

  TAccount = class(TPersistent)
  public
    User, Pass, Host: String;
    Port: Integer;
    Turbo: Boolean; // -> TurboMode: TTurboMode ?
  end;

  TFlagRec = record
    Alias, Server, User, Pass: Boolean;
  end;

  TLineReaderSocketAdapter = class(TLineReaderSource)
  private
    Socket: TCustomWinSocket;
  public
    constructor Create(Socket: TCustomWinSocket);
    function Read(var Buf; Size: Integer): Integer; override;
  end;

const
  CRLF = #13#10;

  FR_TRUE: TFlagRec = (Alias: True; Server: True; User: True; Pass: True);
  FR_FALSE: TFlagRec = (Alias: False; Server: False; User: False; Pass: False);

  DU_DELETE = 0;
  DU_UPDATE = 1;

  RK_ROOT = '\Software\Magnetiq\E-Res-Q';
  RK_PRESET = RK_ROOT + '\Presets';
  RK_POS = RK_ROOT + '\Position';
  RK_COLUMN = RK_ROOT + '\Columns';

  RN_ALIAS = 'Alias';
  RN_SERVER = 'Server';
  RN_PORT = 'Port';
  RN_USER = 'User';
  RN_PASS = 'Pass';

  RN_LEFT = 'Left';
  RN_TOP = 'Top';
  RN_WIDTH = 'Width';
  RN_HEIGHT = 'Height';
  RN_LOGHEIGHT = 'LogHeight';

type
  TFormMain = class(TForm)
    PanelLeft: TPanel;
    PanelRight: TPanel;
    PanelTop: TPanel;
    MemoLog: TMemo;
    SplitterMain: TSplitter;
    StatusBarMain: TStatusBar;
    PanelLeftTop: TPanel;
    PanelProgress: TPanel;
    FlashLedWrite: TFlashLed;
    FlashLedRead: TFlashLed;
    FlashLedTO: TFlashLed;
    ProgressBar: TProgressBar;
    PanelAccTitle: TPanel;
    PanelMsgTitle: TPanel;
    PanelDetailTitle: TPanel;
    PanelAlias: TPanel;
    LabelAlias: TLabel;
    EditAlias: TEdit;
    ButtonAdd: TButton;
    PanelDetail: TPanel;
    LabelServer: TLabel;
    LabelUser: TLabel;
    LabelPass: TLabel;
    EditPass: TEdit;
    ButtonConn: TButton;
    ImageLogo: TImage;
    ButtonDelUpd: TButton;
    ComboBoxServer: TComboBox;
    ComboBoxUser: TComboBox;
    TimerMain: TTimer;
    BevelConn: TBevel;
    BevelAddUpd: TBevel;
    PanelMsg: TPanel;
    ListViewMsg: TListView;
    CheckBoxTurbo: TCheckBox;
    CheckBoxHdr: TCheckBox;
    CheckBoxSizes: TCheckBox;
    MainMenuMain: TMainMenu;
    File1: TMenuItem;
    Edit1: TMenuItem;
    View1: TMenuItem;
    Help1: TMenuItem;
    PopupMenuMsg: TPopupMenu;
    PopupMenuAcc: TPopupMenu;
    Connect1: TMenuItem;
    N1: TMenuItem;
    Edit2: TMenuItem;
    Rename1: TMenuItem;
    Delete1: TMenuItem;
    GetSize1: TMenuItem;
    GetHeaders1: TMenuItem;
    Open1: TMenuItem;
    Delete2: TMenuItem;
    Grid1: TMenuItem;
    N2: TMenuItem;
    SelectAll1: TMenuItem;
    N3: TMenuItem;
    SelectFont1: TMenuItem;
    N4: TMenuItem;
    ListViewAccs: TListView;
    SpeedButton1: TSpeedButton;
    ActionListMain: TActionList;
    ActionDeleteMsg: TAction;
    ActionViewMsg: TAction;
    ActionConnAcc: TAction;
    IdMessageMain: TIdMessage;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerMainTimer(Sender: TObject);

    procedure EditAliasChange(Sender: TObject);
    procedure ComboBoxServerChange(Sender: TObject);
    procedure ComboBoxUserChange(Sender: TObject);
    procedure EditPassChange(Sender: TObject);

    procedure ButtonAddClick(Sender: TObject);
    procedure ButtonDelUpdClick(Sender: TObject);
    procedure ButtonConnClick(Sender: TObject);

    procedure ListBoxAccsClick(Sender: TObject);
    procedure CheckBoxHdrClick(Sender: TObject);
    procedure ActionDeleteMsgExecute(Sender: TObject);
    procedure ActionViewMsgExecute(Sender: TObject);
    procedure ActionConnAccExecute(Sender: TObject);
    procedure ListViewAccsDblClick(Sender: TObject);
  private
    ClientSocketMain: TClientSocket;
    ActiveAccount: TAccount;
    ExpectedResponseQueue: TObjectQueue;

    LastRequestedMsgIndex: Integer;
    DataReceptor: TERQMessage; // bad name
    DataStream: TStringStream; // better name?

//    procedure Acce
    procedure AddLog(S: String);
    procedure ShowError(S: String);

    procedure CheckAlias;
    procedure CheckServer;
    procedure CheckUser;
    procedure CheckEnable;

    procedure EnhanceCombo(ComboBox: TComboBox; S: String);

    procedure AddAcc(Acc: TPreset);

    procedure ShowAcc(Index: Integer);
    procedure EnableUpdate(Func: Integer);
    procedure DeleteAcc(Index: Integer);
    procedure UpdateAcc(Index: Integer);

    procedure CheckServerRaw;

    procedure RegLoadAccs;
    procedure RegSavePosition;
    procedure RegLoadPosition;

    procedure Connect;
    procedure Disconnect;

    procedure ShowStatus(S: String);

    //procedure ParseStat(S: String); // Temp?

    procedure ViewMessage(Msg: TERQMessage);

    { Expected Response Queue }
    procedure PopExpectedResponse;
    procedure PushExpectedResponse(Response: TPOP3Response; Index: Integer = 0);
    function PeekExpectedResponse: TExpectedResponse;

    { Socket Events }
    procedure ClientSocketMainLookup(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketMainConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocketMainRead(Sender: TObject;
      Socket: TCustomWinSocket);
    //Disconnect?

    { Requests }
    procedure StartQuery; // bad name
    procedure GetHeaders;

    function CreateMessage(Index, Octets: Integer): TERQMessage;

    { Response Processing }
    procedure ParseStatResponse(const S: String); // -> Handle?
    procedure ParseListResponse(const S: String);
    procedure ParseListData(const S: String);
    function GetMsgByIdx(Index: Integer): TERQMessage;
    procedure HandleTopResponse(Index: Integer);
    procedure ParseTopData(const S: String);
    procedure HandleRetrResponse(Index: Integer);
    procedure ParseRetrData(const S: String);
    procedure HandleDeleResponse(Index: Integer);

    { I/O }
    procedure SendLine(const S: String);
    procedure EvtLineRead(const Line: String);

    { POP3 Commands }
    procedure POP3User;
    procedure POP3Pass;
    procedure POP3Stat;
    procedure POP3List;
    procedure POP3Top(Index: Integer);
    procedure POP3Retr(Index: Integer);
    procedure POP3Dele(Index: Integer);
  public
  end;

var
  FormMain: TFormMain;

  AccList: TPresetList;
  MaxAccID: Integer = 0;

  MsgList: TObjectList;

  FChanged, FValid: TFlagRec;
  FDataMode: Boolean;

  ValidServer: String;
  ValidPort: Word;

  Reader: TLineReader;
  Source: TLineReaderSocketAdapter;

  TotalMsgs: Integer;
  TotalBytes: Longint;

  MsgIndex: Integer;

implementation

{$R *.DFM}

uses
  _Trace;

{ Utils }

{ TExpectedResponse }

constructor TExpectedResponse.Create(POP3Response: TPOP3Response;
  Index: Integer);
begin
  Self.POP3Response := POP3Response;
  Self.Index := Index;
end;

{ TLineReaderSocketAdapter }

constructor TLineReaderSocketAdapter.Create(Socket: TCustomWinSocket);
begin
  Self.Socket := Socket;
end;

function TLineReaderSocketAdapter.Read(var Buf; Size: Integer): Integer;
begin
  Result := Socket.ReceiveBuf(Buf, Size);
end;

{ TFormMain }

{ Check validity }

procedure TFormMain.CheckAlias;
begin
  FValid.Alias := (EditAlias.Text <> '') and
    (ListViewAccs.FindCaption(0, EditAlias.Text, False, True, False) = nil);
end;

procedure TFormMain.CheckServer;
begin
  FValid.Server := (ComboBoxServer.Text <> '');
end;

procedure TFormMain.CheckUser;
begin
  FValid.User := (ComboBoxUser.Text <> '');
end;

{ Timer event }

procedure TFormMain.CheckEnable;
begin
  with FChanged do
    begin
      if Alias then
        CheckAlias;
      if Server then
        CheckServer;
      if User then
        CheckUser;
    end;
  with FValid do
    begin
      ButtonConn.Enabled := Server and User;
      ButtonAdd.Enabled := ButtonConn.Enabled and Alias;
    end;
//  with FChanged do // !!!
//    ButtonDelUpd.Enabled := ButtonAdd.Enabled and (not Alias) and
//      (Server or User or Pass)
//      and (ListBoxAccs.ItemIndex <> -1);
  FChanged := FR_FALSE;
end;

procedure TFormMain.TimerMainTimer(Sender: TObject);
begin
  CheckEnable;
end;

{ GUI Utils }

procedure TFormMain.AddLog(S: String);
begin
  MemoLog.Lines.Add(S)
end;

procedure TFormMain.ShowStatus(S: String);
begin
  StatusBarMain.SimpleText := S;
  AddLog(' - ' + S);
end;

procedure TFormMain.ShowError(S: String);
begin
  AddLog('ERROR: ' + S);
  MessageDlg(S, mtError, [mbOK], 0);
end;

procedure TFormMain.EnhanceCombo(ComboBox: TComboBox; S: String);
begin
  with ComboBox.Items do
    if (IndexOf(S) = -1) then
      Add(S);
end;

procedure TFormMain.CheckServerRaw;
var
  ServerRaw, PortStr: String;
  Len, ColPos: Integer;
  IntPort: Integer;

begin
  ServerRaw := ComboBoxServer.Text;
  ColPos := Pos(':', ServerRaw);
  if (ColPos = 0) then
    begin
      ValidServer := ServerRaw;
      ValidPort := DEFAULTPORT;
    end
  else
    begin
      Len := Length(ServerRaw);
      if (ColPos = Len) then
        raise Exception.Create('Port expected after colon (:).');
      PortStr := Copy(ServerRaw, ColPos + 1, Len - ColPos);
      try
        IntPort := StrToInt(PortStr);
      except
        IntPort := -1;
      end;
      if (IntPort < 0) or (IntPort > 65535) then
        raise Exception.Create('Invalid port: ' + PortStr);
      ValidServer := Copy(ServerRaw, 1, ColPos - 1);
      ValidPort := IntPort;
    end;
end;

{ POP3 actions }

procedure TFormMain.Connect;
begin
  ShowStatus('Connecting...');

  ActiveAccount := TAccount.Create; // Assign from preset etc. this one is the
                                    // one synched with GUI in real time
  ActiveAccount.User := ComboBoxUser.Text;
  ActiveAccount.Pass := EditPass.Text;
  ActiveAccount.Turbo := CheckBoxTurbo.Checked; // Per account!
  ActiveAccount.Host := ValidServer;
  ActiveAccount.Port := ValidPort;

  with ClientSocketMain do
    begin
      Host := ValidServer;
      Port := ValidPort;
      Open;
    end;
end;

procedure TFormMain.Disconnect;
begin
  ClientSocketMain.Close;
end;

// ToDo: Make preset list editable - rename preset alias + f2

{ Registry actions }

procedure RegSaveAcc(Acc: TPreset);
var
  Reg: TRegistry;

begin
  Reg := TRegistry.Create;
  with Reg, Acc do
    begin
      OpenKey(Format('%s\%d', [RK_PRESET, ID]), True);
      WriteString(RN_ALIAS, Alias);
      WriteString(RN_SERVER, Server);
      WriteInteger(RN_PORT, Port);
      WriteString(RN_USER, User);
      WriteString(RN_PASS, Pass);
      CloseKey;
    end;
  Reg.Free;
end;

procedure RegDeleteAcc(Acc: TPreset);
var
  Reg: TRegistry;

begin
  Reg := TRegistry.Create;
  with Reg do
    begin
      DeleteKey(Format('%s\%d', [RK_PRESET, Acc.ID]));
      Free;
    end;
end;

procedure TFormMain.RegLoadAccs;
var
  Reg: TRegistry;
  IDs: TStringList;
  IDStr: String;
  Cnt, ID: Integer;
  NewAcc: TPreset;

begin
  IDs := TStringList.Create;
  Reg := TRegistry.Create;
  with Reg do
    if OpenKey(RK_PRESET, False) then
      begin
        GetKeyNames(IDs);
        CloseKey;
        if (IDs.Count > 0) then
          for Cnt := 0 to IDs.Count - 1 do
            begin
              IDStr := IDs[Cnt];
              if OpenKey(Format('%s\%s', [RK_PRESET, IDStr]), False) then
                begin
                  ID := StrToInt(IDStr);
                  if (ID > MaxAccID) then
                    MaxAccID := ID;
                  try
                    NewAcc := AccList.Add(ID, ReadString(RN_ALIAS),
                      ReadString(RN_SERVER), ReadInteger(RN_PORT),
                      ReadString(RN_USER), ReadString(RN_PASS));
                    AddAcc(NewAcc);
                  except
                    ShowError('Invalid preset encountered in registry.');
                  end;
                  CloseKey;
                end;
            end;
      end;
  Reg.Free;
end;

procedure TFormMain.RegSavePosition;
var
  Reg: TRegistry;
//  Cnt: Integer;

begin
  Reg := TRegistry.Create;
  with Reg do
    begin
      OpenKey(RK_POS, True);
      WriteInteger(RN_LEFT, Left);
      WriteInteger(RN_TOP, Top);
      WriteInteger(RN_WIDTH, Width);
      WriteInteger(RN_HEIGHT, Height);
      WriteInteger(RN_LOGHEIGHT, MemoLog.Height);
      CloseKey;
{
      with ListViewMsg.Columns do
        for Cnt := 1 to Count - 1 do
          with Items[Cnt] do
            begin
              OpenKey(Format('%s\%d', [RK_COLUMN, Caption]), True);
              WriteInteger(RN_WIDTH, Width);
              CloseKey;
            end; }
    end;
  Reg.Free;
end;

procedure TFormMain.RegLoadPosition;
var
  Reg: TRegistry;

begin
  Reg := TRegistry.Create;
  with Reg do
    if OpenKey(RK_POS, False) then
      begin
        try
          Left := ReadInteger(RN_LEFT);
          Top := ReadInteger(RN_TOP);
          Width := ReadInteger(RN_WIDTH);
          Height := ReadInteger(RN_HEIGHT);
          MemoLog.Height := ReadInteger(RN_LOGHEIGHT);
        except
          Position := poDesktopCenter;
        end;
        CloseKey;
      end;
  Reg.Free;
end;

// HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts

{ GUI actions }

procedure TFormMain.AddAcc(Acc: TPreset);
begin
  with Acc do
    begin
      ListViewAccs.Items.Add.Caption := Alias;
      EnhanceCombo(ComboBoxServer, ServerRaw);
      EnhanceCombo(ComboBoxUser, User);
    end;
end;

procedure TFormMain.EnableUpdate(Func: Integer);
begin
  with ButtonDelUpd do
    begin
      Tag := Func;
      case Func of
        DU_UPDATE: Caption := 'Update';
        DU_DELETE: Caption := 'Delete';
      end;
      Enabled := True;
    end;
end;

procedure TFormMain.ShowAcc(Index: Integer);
begin
  with AccList.PresetAt(Index) do
    begin
      EditAlias.Text := Alias;
      ValidServer := Server;
      ValidPort := Port;
      ComboBoxServer.Text := ServerRaw;
      ComboBoxUser.Text := User;
      EditPass.Text := Pass;
    end;
  EnableUpdate(DU_DELETE);
end;

procedure TFormMain.DeleteAcc(Index: Integer);
begin
  ListViewAccs.Items.Delete(Index);
  RegDeleteAcc(AccList.PresetAt(Index));
  AccList.Remove(Index);
end;

procedure TFormMain.UpdateAcc(Index: Integer);
begin
  with AccList.PresetAt(Index) do
    begin
      Alias := EditAlias.Text;
      Server := ValidServer;
      Port := ValidPort;
      User := ComboBoxUser.Text;
      Pass := EditPass.Text;
      ListViewAccs.Items[Index].Caption := Alias;
    end;
end;

{ GUI events }

procedure TFormMain.EditAliasChange(Sender: TObject);
begin
  FChanged.Alias := True;
end;

procedure TFormMain.ComboBoxServerChange(Sender: TObject);
begin
  FChanged.Server := True;
end;

procedure TFormMain.ComboBoxUserChange(Sender: TObject);
begin
  FChanged.User := True;
end;

procedure TFormMain.EditPassChange(Sender: TObject);
begin
  FChanged.Pass := True;
end;

procedure TFormMain.ButtonAddClick(Sender: TObject);
var
  NewAcc: TPreset;

begin
  CheckEnable;
  if not ButtonAdd.Enabled then
    Exit;
  try
    CheckServerRaw;
    inc(MaxAccID);
    NewAcc := AccList.Add(MaxAccID, EditAlias.Text, ValidServer,
      ValidPort, ComboBoxUser.Text, EditPass.Text);
    AddAcc(NewAcc);
    RegSaveAcc(NewAcc);
    CheckAlias;
  except // Set focus...
    on E: Exception do ShowError('Cannot add preset. ' + E.Message);
  end;
end;

procedure TFormMain.ButtonDelUpdClick(Sender: TObject);
begin
  CheckEnable;
  if not ButtonDelUpd.Enabled then
    Exit;
  case ButtonDelUpd.Tag of
    DU_DELETE: DeleteAcc(ListViewAccs.ItemIndex);
    DU_UPDATE: UpdateAcc(ListViewAccs.ItemIndex);
  end;
end;

procedure TFormMain.ButtonConnClick(Sender: TObject);
begin
  CheckEnable;
  if not ButtonConn.Enabled then
    Exit;
  with ButtonConn do
    begin
      case Tag of
        0: Connect;
        1: Disconnect;
      end;
      Tag := Tag xor 1;
      case Tag of
        0: Caption := 'Connect';
        1: Caption := 'Disconnect';
      end;
    end;
end;

procedure TFormMain.ListBoxAccsClick(Sender: TObject);
begin
  with ListViewAccs do
    if (ItemIndex <> -1) then
      begin
        ShowAcc(ItemIndex);
        ButtonConn.Enabled := True;
        FValid := FR_TRUE;
        FChanged := FR_FALSE;
      end;
end;

{ Form events }

procedure TFormMain.FormCreate(Sender: TObject);

begin
  ClientSocketMain := TClientSocket.Create(Self);
  ClientSocketMain.OnConnect := ClientSocketMainConnect;
  ClientSocketMain.OnLookup := ClientSocketMainLookup;
  ClientSocketMain.OnRead := ClientSocketMainRead;

  MsgList := TObjectList.Create;
  MsgList.Add(nil); // Skip index 0

  ExpectedResponseQueue := TObjectQueue.Create;
  DataReceptor := nil; // nec?
  DataStream := TStringStream.Create('');

  FChanged := FR_FALSE;
  FValid := FR_FALSE;

  AccList := TPresetList.Create;

  RegLoadAccs;
  RegLoadPosition;

  AddLog('E-Res-Q 2.0 - 24/10/2000');
  AddLog('http://www.magnetiq.com');
  AddLog('');
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  RegSavePosition;

  DataStream.Free;//nc?

  MsgList.Free; // First free msgs?

  AccList.Free;
  ExpectedResponseQueue.Free;
  ClientSocketMain.Free;
end;

{ * }

procedure TFormMain.ClientSocketMainRead(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  FlashLedRead.Flash;
  Reader.Read;
end;

{ Response Queue }

function POP3ResponseToStr(POP3Response: TPOP3Response): String;
begin
  case POP3Response of
    resWelcome:
      Result := 'Welcome';
    resUser:
      Result := 'USER';
    resPass:
      Result := 'PASS';
    resStat:
      Result := 'STAT';
    resList:
      Result := 'LIST';
    resListData:
      Result := 'LIST Data';
    resTop:
      Result := 'TOP';
    resTopData:
      Result := 'TOP Data';
    resRetr:
      Result := 'RETR';
    resRetrData:
      Result := 'RETR Data';
    resDele:
      Result := 'DELE';
    resRset:
      Result := 'RSET';
    resQuit:
      Result := 'QUIT';
  else
    Result := 'UNKNOWN';
  end;
end;

procedure TFormMain.PopExpectedResponse;
var
  ExpectedResponse: TExpectedResponse;

begin
  if (ExpectedResponseQueue.Count > 0) then // Nec?
    begin
      ExpectedResponse := ExpectedResponseQueue.Pop as TExpectedResponse;
      Trace(Format('Pop: %s %d',
        [POP3ResponseToStr(ExpectedResponse.POP3Response),
        ExpectedResponse.Index]), 'queue');
      ExpectedResponse.Free;
    end;

    // else assert!?

  if (ExpectedResponseQueue.Count = 0) then
    AddLog('TASK DONE'); // !!!! more.. eg. hide progress bar etc.
end;

procedure TFormMain.PushExpectedResponse(Response: TPOP3Response;
  Index: Integer);
begin
  Trace(Format('Push: %s %d', [POP3ResponseToStr(Response), Index]), 'queue');
  ExpectedResponseQueue.Push(TExpectedResponse.Create(Response, Index));
end;

function TFormMain.PeekExpectedResponse: TExpectedResponse;
begin
  if (ExpectedResponseQueue.Count > 0) then
    Result := ExpectedResponseQueue.Peek as TExpectedResponse
  else
    Result := nil;

  if (Result <> nil) then
    Trace(Format('Peek: %s %d', [POP3ResponseToStr(Result.POP3Response),
      Result.Index]), 'queue')
  else
    Trace('Peek: nil');
end;

{ * }

function TFormMain.CreateMessage(Index, Octets: Integer): TERQMessage;
var
  ListItem: TListItem;

begin
  ListItem := ListViewMsg.Items.Add;

  Result := TERQMessage.Create(Self, ListItem, Index, Octets);

  MsgList.Add(Result);

  with (ListItem) do
    begin
      Data := Result;
      Caption := IntToStr(Result.Index);
      SubItems.Append('-');
      SubItems.Append('-');
      SubItems.Append('-');
      SubItems.Append('-');
    end;
end;

function TFormMain.GetMsgByIdx(Index: Integer): TERQMessage;
begin
   // assert index <>0
  if (Index <= MsgList.Count) then
    Result := TERQMessage(MsgList[Index])
  else
    Result := CreateMessage(Index, -1);
end;

// DONE: TLineBuffer -> TTextReader / TTextIO.WriteLine etc.

{ Socket events }

procedure TFormMain.ClientSocketMainLookup(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  ShowStatus('Looking up ' + ValidServer + '...');
end;

procedure TFormMain.ClientSocketMainConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  AddLog('Connected???');
  PushExpectedResponse(resWelcome);

// TODO: Cleanup Source & Reader
  Source := TLineReaderSocketAdapter.Create(Socket);
  Reader := TLineReader.Create(Source, SO_RCVBUF);
  Reader.OnLineRead := EvtLineRead;

  if ActiveAccount.Turbo then
    begin
      POP3User;
      POP3Pass;
      StartQuery;
    end;
end;

{ Requests }

procedure TFormMain.StartQuery; // bad name
begin
  if CheckBoxSizes.Checked then
    POP3List
  else
    POP3Stat;
end;

procedure TFormMain.GetHeaders;
var
  MsgCnt: Integer;

begin
  if (ActiveAccount.Turbo) then
    begin
      if (TotalMsgs < 10) then
        LastRequestedMsgIndex := TotalMsgs
      else
        LastRequestedMsgIndex := 10;
    end
  else
    LastRequestedMsgIndex := 1;

  for MsgCnt := 1 to LastRequestedMsgIndex do
    POP3Top(MsgCnt);
end;

// ToDo: save column widths

{ Response Processing }

procedure TFormMain.ParseStatResponse(const S: String);
var
  Tokens: TStringList;
  MsgCnt: Integer;

begin
  AddLog('<<< STAT OK');

  Tokens := TStringList.Create;
  Tokens.DelimitedText := S;

  try
    TotalMsgs := StrToInt(Tokens[1]);
    TotalBytes := StrToInt(Tokens[2]);

    AddLog(Format('%d bytes in %d messages', [TotalBytes, TotalMsgs]));

    if CheckBoxHdr.Checked then
      GetHeaders
    else
      begin
        ListViewMsg.Items.BeginUpdate;

        for MsgCnt := 1 to TotalMsgs do
          CreateMessage(MsgCnt, -1);

        ListViewMsg.Items.EndUpdate;
      end;
  except
    AddLog('Invalid STAT response!!!');
  end;
end;

procedure TFormMain.ParseListResponse(const S: String);
var
  Tokens: TStringList;

begin
  Tokens := TStringList.Create;
  Tokens.DelimitedText := S;

  try
    // reuse this part??
    TotalMsgs := StrToInt(Tokens[1]);
    AddLog(Format('%d messages', [TotalMsgs]));
  except
    AddLog('Invalid LIST response!!!');
  end;

  Tokens.Free;
end;

procedure TFormMain.ParseListData(const S: String);
var
  Tokens: TStringList;
  Index, Octets: Integer;
  Msg: TERQMessage;

begin
  Tokens := nil; // nec?

  try
    if (S[1] <> '.') then
      begin
        Tokens := TStringList.Create;
        Tokens.DelimitedText := S;

        Index := StrToInt(Tokens[0]);
        Octets := StrToInt(Tokens[1]);
        AddLog(Format('idx %d size %d', [Index, Octets]));

        Msg := CreateMessage(Index, Octets); // not necessarily!
        Msg.ShowSize;
      end
    else
      begin
        PopExpectedResponse;

        // Actually do this after sending the list request???
        if CheckBoxHdr.Checked then
          GetHeaders;
      end;
  except
    AddLog('Invalid LIST data!!!');
    // free msg if nec
  end;

  Tokens.Free;
end;

procedure TFormMain.ParseTopData(const S: String);
begin
  if (DataReceptor <> nil) then
    Trace(Format('ParseTopData S: |%s|  DataReceptor: %d',[S,
      DataReceptor.Index]))
  else
    Trace(Format('ParseTopData S: |%s|  DataReceptor: nil',[S]));

  try
    if (Length(S) <> 1) or (S[1] <> '.') then
      //DataReceptor.Headers.Append(S)
      begin
        DataStream.WriteString(S);
        DataStream.WriteString(CRLF);
      end
    else
      begin
        PopExpectedResponse; // Delegate this // DataDone() // do it at end?

        //DataReceptor.Headers.SaveToFile('E:/dump.txt');

        DataStream.Seek(0, soFromBeginning);
        IdMessageMain.LoadFromStream(DataStream);

        IdMessageMain.ProcessHeaders;

        //DataReceptor.ProcessHeaders;
        //AddLog('Name:' + ResponseMsg.FFrom.Name + ' Address: ' +
          //ResponseMsg.FFrom.Address);
        DataReceptor.ShowHeaders;

        AddLog('Top data for ' + IntToStr(DataReceptor.Index));
        DataReceptor := nil; // not nec

        if (LastRequestedMsgIndex < TotalMsgs) and CheckBoxHdr.Checked then
          begin
            inc(LastRequestedMsgIndex);
            POP3Top(LastRequestedMsgIndex);
          end;
      end;
    //AddLog('Hdr - ' + S);
  except
    AddLog('Invalid TOP data!!!');
  end;
end;

procedure TFormMain.HandleTopResponse(Index: Integer);
begin
  DataReceptor := GetMsgByIdx(Index);
  if (DataReceptor <> nil) then
  begin
    Trace(Format('HandleTopResponse Index: %d  DataReceptor: %d',[Index,
      DataReceptor.Index]));
    //DataReceptor.Headers.UnfoldLines := True;
  end
  else
    Trace(Format('HandleTopResponse Index: %d  DataReceptor: nil',[Index]));

{
  if (DataReceptor = nil) then
    DataReceptor := CreateMessage(ExpectedResponse.Index, -1);
}
end;

procedure TFormMain.HandleRetrResponse(Index: Integer);
begin
  DataReceptor := GetMsgByIdx(Index);
  //DataStream := TStringStream.Create('');
  DataStream.Seek(0, soFromBeginning);
{
  if (DataReceptor = nil) then
    DataReceptor := CreateMessage(ExpectedResponse.Index, -1);
}
end;

procedure TFormMain.ParseRetrData(const S: String);
begin
//try..
  DataStream.WriteString(S);
  DataStream.WriteString(CRLF);

  if (Length(S) = 1) and (S[1] = '.') then
    begin
      PopExpectedResponse; // Delegate this // DataDone() // do it at end?

      DataStream.Seek(0, soFromBeginning);
      IdMessageMain.LoadFromStream(DataStream);
{
      DataStream.Seek(0, soFromBeginning);
      DataReceptor.LoadFromStream(DataStream);
      FreeAndNil(DataStream);
}
      ViewMessage(DataReceptor);
      DataReceptor := nil; // nec?
    end;
end;

procedure TFormMain.HandleDeleResponse(Index: Integer);
var
  Msg: TERQMessage;

begin
  AddLog('<<< DELE OK');

  // Check if already deleted msg etc.?
  Msg := GetMsgByIdx(Index);

//  Msg.Status := deleted

  ListViewMsg.Items.Delete(Msg.ListItem.Index); // better way?
end;

{ I/O }

// ToDo: var Line

procedure TFormMain.SendLine(const S: String);
begin
  AddLog('>>> ' + S);
  FlashLedWrite.Flash;
  ClientSocketMain.Socket.SendText(S + CRLF);
end;

// ToDo: P*Response -> P*ExpectedResponse

// ToDo: push must be boolean - fixed value before connect

// ToDo: progress bar

procedure TFormMain.EvtLineRead(const Line: String);
var
  ExpectedResponse: TExpectedResponse;
  ResponseStr: String;

begin
  ExpectedResponse := PeekExpectedResponse;

  if (ExpectedResponse = nil) then
  begin
    ShowMessage('ExpectedResponse = nil');
    Exit; // Warning?
  end;

  case ExpectedResponse.POP3Response of
    resListData:
      ParseListData(Line);
    resTopData:
      ParseTopData(Line);
    resRetrData:
      ParseRetrData(Line);
  else
    if (Length(Line) >= 3) then
      begin
        ResponseStr := Uppercase(Copy(Line, 1, 3));

        if (ResponseStr = '+OK') then
          case ExpectedResponse.POP3Response of
            resWelcome:
              begin
                AddLog('<<< WELCOME');

                if not ActiveAccount.Turbo then
                  POP3User;
              end;
            resUser:
              begin
                AddLog('<<< USER OK');

                if not ActiveAccount.Turbo then
                  POP3Pass;
              end;
            resPass:
              begin
                AddLog('<<< PASS OK');

                if not ActiveAccount.Turbo then
                  StartQuery;
              end;
            resStat:
              ParseStatResponse(Line);
            resList:
              ParseListResponse(Line);
            resTop:
              HandleTopResponse(ExpectedResponse.Index);
            resRetr:
              HandleRetrResponse(ExpectedResponse.Index);
            resDele:
              HandleDeleResponse(ExpectedResponse.Index);
          end
        else if (ResponseStr = '-ER') then
          AddLog('ERR')
        else
          AddLog('Ulan bu ne???');
      end
    else
      AddLog('Ya bu ne?');

    PopExpectedResponse;
  end;
end;

{ POP3 Commands }

procedure TFormMain.POP3User;
begin
  SendLine('USER ' + ActiveAccount.User);
  PushExpectedResponse(resUser);
end;

procedure TFormMain.POP3Pass;
begin
  SendLine('PASS ' + ActiveAccount.Pass);
  PushExpectedResponse(resPass);
end;

procedure TFormMain.POP3Stat;
begin
  SendLine('STAT');
  PushExpectedResponse(resStat);
end;

procedure TFormMain.POP3List;
begin
  SendLine('LIST');
  PushExpectedResponse(resList);
  PushExpectedResponse(resListData);
end;

procedure TFormMain.POP3Top(Index: Integer);
begin
  SendLine(Format('TOP %d 0', [Index]));
  PushExpectedResponse(resTop, Index);
  PushExpectedResponse(resTopData);
end;

procedure TFormMain.POP3Retr(Index: Integer);
begin
  SendLine(Format('RETR %d', [Index]));
  PushExpectedResponse(resRetr, Index);
  PushExpectedResponse(resRetrData);
end;

procedure TFormMain.POP3Dele(Index: Integer);
begin
  SendLine(Format('DELE %d', [Index]));
  PushExpectedResponse(resDele, Index);
end;

{ GUI Events }

procedure TFormMain.CheckBoxHdrClick(Sender: TObject);
begin
  //CheckBoxSizes.Enabled := not CheckBoxHdr.Checked;
end;

procedure TFormMain.ActionDeleteMsgExecute(Sender: TObject);
var
  Cnt: Integer;
  ListItem: TListItem;

begin
//  ListViewMsg.SelCount > 0 etc. ?
  ListViewMsg.Items.BeginUpdate;

  for Cnt := 0 to ListViewMsg.Items.Count - 1 do
    begin
      ListItem := ListViewMsg.Items[Cnt];
      if (ListItem.Selected) and (ListItem.Caption <> '-') then
        begin
          ListItem.Caption := '-';
          //Msg.Status = deleting
          POP3Dele(TERQMessage(ListItem.Data).Index);
          // may flood server,
          // must queue on request queue max x at a time / if turbo 10, else 1
        end;
    end;

  ListViewMsg.Items.EndUpdate;
end;

procedure TFormMain.ActionViewMsgExecute(Sender: TObject);
begin
  if (ListViewMsg.Selected <> nil) then
    begin
      POP3Retr(TERQMessage(ListViewMsg.Selected.Data).Index);
    end;
end;

procedure TFormMain.ViewMessage(Msg: TERQMessage);
begin
  if (Msg.ViewForm = nil) then
    begin
      Msg.ViewForm := TFormMsg.Create(Self, Msg);
      Msg.ViewForm.Show;
    end
  else
    Msg.ViewForm.BringToFront;
end;

procedure TFormMain.ActionConnAccExecute(Sender: TObject);
begin
  AddLog('Conn Acc');
end;

procedure TFormMain.ListViewAccsDblClick(Sender: TObject);
begin
  if (ButtonConn.Tag = 0) then
    ButtonConnClick(Self); 
end;

end.


