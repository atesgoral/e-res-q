{
Fixed contact info
Removed splash
Made application window resizeable
Removed port
Disconnect asks apply
Decodes From and Date fields
Fixed a typo
}

unit Main;

interface

uses
  Messages, SysUtils, Graphics, Forms, Classes, Controls,
  Winsock, StdCtrls, ComCtrls, ExtCtrls, IniFiles, TextUtils, Read,
  Menus, Dialogs, FlashLed,
  StrUtilsX, MIMEDecode, DateTimeDecode;

const
  WSVersion = $202;
  FD_GEN = FD_READ or FD_CLOSE;
  WM_SDNS = WM_USER + 100;
  WM_SCONN = WM_SDNS + 1;
  WM_SGEN = WM_SCONN + 1;
  TimeOutDur = 60;
  TODiv = TimeOutDur / 3;
  FlashStartDur = 2;
  TOColors: array [0..3] of TColor = (clDkGray, clGray, clLtGray, clWhite);
  IniFileName = 'E-Res-Q.ini';
  SectSett = 'settings';
  KeyUser = 'username';
  KeyPass = 'password';
  KeyServer = 'server';
  KeyHdr = 'getheaders';
  KeyGrid = 'gridlines';
  KeySaveUser = 'saveusername';
  KeySavePass = 'savepassword';
  KeySaveServer = 'saveserver';

type
  TFormMain = class(TForm)
    EditServer: TEdit;
    MemoLog: TMemo;
    EditUser: TEdit;
    EditPass: TEdit;
    Splitter: TSplitter;
    PanelSett: TPanel;
    PanelFunc: TPanel;
    PanelLV: TPanel;
    ListView: TListView;
    CheckBoxUser: TCheckBox;
    CheckBoxPass: TCheckBox;
    CheckBoxServer: TCheckBox;
    CheckBoxHdr: TCheckBox;
    TimerTO: TTimer;
    PanelStatus: TPanel;
    StatusBar: TStatusBar;
    ProgressBar: TProgressBar;
    PopupMenuLV: TPopupMenu;
    MenuItemGrid: TMenuItem;
    MenuItemFont: TMenuItem;
    FontDialog: TFontDialog;
    FlashLedRead: TFlashLed;
    FlashLedWrite: TFlashLed;
    FlashLedTO: TFlashLed;
    Panel1: TPanel;
    ButtonRead: TButton;
    ButtonDelete: TButton;
    Panel2: TPanel;
    ButtonConn: TButton;
    ButtonApply: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonConnClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure ButtonDeleteClick(Sender: TObject);
    procedure EditReqChange(Sender: TObject);
    procedure CheckBoxHdrClick(Sender: TObject);
    procedure ListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListViewCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerTOTimer(Sender: TObject);
    procedure EditUserKeyPress(Sender: TObject; var Key: Char);
    procedure EditPassKeyPress(Sender: TObject; var Key: Char);
    procedure ButtonReadClick(Sender: TObject);
    procedure MenuItemGridClick(Sender: TObject);
    procedure MenuItemFontClick(Sender: TObject);
    procedure ListViewDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  protected
    procedure WMSockDNS(var Message: TMessage); message WM_SDNS;
    procedure WMSockConn(var Message: TMessage); message WM_SCONN;
    procedure WMSockGen(var Message: TMessage); message WM_SGEN;
  end;
  TTask= (TSKNone, TSKWaitDNS, TSKWaitConn, TSKWaitWelc, TSKWaitUser,
  TSKWaitPass, TSKWaitCount, TSKWaitList, TSKParseList, TSKWaitHeader,
  TSKParseHeader, TSKWaitRetr, TSKParseRetr, TSKWaitDel, TSKWaitQuit);

var
  FormMain: TFormMain;
  SettIni: TIniFile;
  HostEntBuf: array [1..MAXGETHOSTSTRUCT] of byte;
  Buf: array [1..SO_RCVBUF + 1] of Char;
  DNSHandle: Integer;
  SockDesc: TSocket;
  StatConnected: Boolean = False;
  StatNoHeaders, StatDeleted: Boolean;
  Task, LastTask: TTask;
  MsgCount, MsgIndex, DelCount: Integer;
  RcvQue: String = '';
  NumSortDir: Integer = -1;
  SizeSortDir: Integer = -1;
  TimeOutCount: Integer;
  NewFormRead: TFormRead;

  SplitHost, SplitPort: String;

implementation

{$R *.DFM}

procedure ResetProgBar(MaxVal: Integer);

begin
  with FormMain.ProgressBar do
    begin
      Max:= MaxVal;
      Visible:= True;
      Position:= 0;
    end;
end;

procedure AdvProgBar;

begin
  with FormMain.ProgressBar do
    begin
      StepIt;
      Hint:= '%' + IntToStr(Trunc(100 * Position / Max));
    end;
end;

procedure AdvProgBarBy(StepCnt: Integer);

begin
  with FormMain.ProgressBar do
    begin
      StepBy(StepCnt);
      Hint:= '%' + IntToStr(Trunc(100 * Position / Max));
    end;
end;
procedure HideProgBar;

begin
  FormMain.ProgressBar.Visible:= False;
end;

procedure ResetTimer(TOTask: TTask);

begin
  Task:= TOTask;
  TimeOutCount:= 0;
  Screen.Cursor:= crAppStart;
  FormMain.TimerTO.Interval:= 500;
  FormMain.TimerTO.Enabled:= True;
end;

procedure StopTimer;

begin
  LastTask:= Task;
  Task:= TSKNone;
  FormMain.TimerTO.Enabled:= False;
  Screen.Cursor:= crDefault;
end;

procedure Log(S: String);

begin
  FormMain.MemoLog.Lines.Add(S)
end;

procedure Status(S: String);

begin
  FormMain.StatusBar.SimpleText:= S;
  Log(S);
end;

procedure Error(S: String);

begin
  Status('Error - ' + S);
end;

procedure StatusMsgCnt;

begin
  Status(Plural(FormMain.ListView.Items.Count,'message', 'messages'));
end;

procedure ErrorNum(WSCode: Integer);

begin
  if ( WSCode <> 10035 ) then
    begin
      StopTimer;
      Error(IntToStr(WSCode) + ': ' + ErrToText(WSCode));
    end;
end;

procedure CheckError(Code, ErrCode: Integer);

begin
  if ( Code = ErrCode ) then
    ErrorNum(WSAGetLastError);
end;

procedure LoadIni(Key: String; var Edit: TEdit; var CheckBox: TCheckBox);

begin
  CheckBox.Checked:= SettIni.ReadBool(SectSett, 'save' + Key, False);
  Edit.Text:= SettIni.ReadString(SectSett, Key, '');
end;

procedure SaveIni(Key, Value: String; var CheckBox: TCheckBox);

begin
  SettIni.WriteBool(SectSett, 'save' + Key, CheckBox.Checked);
  if CheckBox.Checked then
    SettIni.WriteString(SectSett, Key, Value);
end;

procedure LoadSett;

begin
  with FormMain do
    begin
      LoadIni(KeyUser, EditUser, CheckBoxUser);
      LoadIni(KeyPass, EditPass, CheckBoxPass);
      EditPass.Text:=Decrypt(EditPass.Text);
      LoadIni(KeyServer, EditServer, CheckBoxServer);
      CheckBoxHdr.Checked:= SettIni.ReadBool(SectSett, KeyHdr, False);
      ListView.GridLines:= SettIni.ReadBool(SectSett, KeyGrid, False);
      MenuItemGrid.Checked:= ListView.GridLines;
      FontDialog.Font:= ListView.Font;
    end;
end;

procedure SaveSett;

begin
  with FormMain do
    begin
      SaveIni(KeyUser, EditUser.Text, CheckBoxUser);
      SaveIni(KeyPass, Encrypt(EditPass.Text), CheckBoxPass);
      SaveIni(KeyServer, EditServer.Text, CheckBoxServer);
      SettIni.WriteBool(SectSett, KeyHdr, CheckBoxHdr.Checked);
      SettIni.WriteBool(SectSett, KeyGrid, MenuItemGrid.Checked);
    end;
end;

procedure DNSLookup(Name: String);

begin
  Status('Looking up ' + Name + '...');
  ResetTimer(TSKWaitDNS);
  DNSHandle:= WSAAsyncGetHostByName(FormMain.Handle, WM_SDNS, PChar(Name),
  @HostEntBuf, MAXGETHOSTSTRUCT);
  CheckError(DNSHandle, 0);
end;

procedure CheckFields;

begin
  with FormMain do
    if ( EditUser.Text <> '' ) and ( EditPass.Text <> '' ) and
    ( EditServer.Text <> '' ) then
      begin
        if ( ButtonConn.Enabled = False ) then
          ButtonConn.Enabled:= True;
      end
    else if ButtonConn.Enabled then
      ButtonConn.Enabled:= False;
end;

procedure ConnectHost(Addr: String);
var
  SAddr: tsockaddr;

begin
  Status('Connecting... (' + Addr + ')');
  ResetTimer(TSKWaitConn);
  SockDesc:= socket(PF_INET,SOCK_STREAM,0);
  CheckError(SockDesc, INVALID_SOCKET);
  SAddr.sin_family:= AF_INET;
  SAddr.sin_addr.S_addr:= inet_addr(PChar(Addr));
  SAddr.sin_port:= htons(StrToInt(SplitPort));
  CheckError(WSAAsyncSelect(SockDesc, FormMain.Handle, WM_SCONN, FD_CONNECT),
  SOCKET_ERROR);
  CheckError(connect(SockDesc, SAddr, SizeOf(SAddr)), SOCKET_ERROR);
end;

procedure ErrPort;

begin
  Error('Invalid port');
  FormMain.EditServer.SetFocus;
end;

procedure SConnect;
var
  S: String;
  ColPos: Integer;

begin
  S := FormMain.EditServer.Text;
  ColPos := Pos(':', S);
  if (ColPos = 0) then
    begin
      SplitHost := S;
      SplitPort := '110';
    end
  else
    begin
      SplitHost := Copy(S, 1, ColPos - 1);
      SplitPort := Copy(S, ColPos + 1, Length(S) - ColPos);
    end;
  if not IsValidPort(SplitPort) then
    ErrPort
  else if IsValidIP(SplitHost) then
    ConnectHost(SplitHost)
  else
    DNSLookup(SplitHost);
end;

procedure SetDisc;

begin
  StatConnected:= False;
  StopTimer;
  with FormMain do
    begin
      HideProgBar;
      ButtonConn.Caption:= '&Connect';
      ButtonConn.Default:= true;
      ButtonDelete.Enabled:= False;
      ButtonRead.Enabled:= False;
      ButtonApply.Enabled:= False;
//      ListView.Items.Clear;
    end;
  CheckFields;
end;

procedure SDisconnect;

begin
  if FormMain.ButtonApply.Enabled and (MessageDlg('Disconnect without applying deletes?' + #13#10 +
    '(You must press Apply before disconnecting' + #13#10 +
    'to actually remove the deleted messages from the server.)',
    mtConfirmation, mbOKCancel, 0) = mrCancel) then
    Exit;
  if WSAIsBlocking then
    CheckError(WSACancelBlockingCall, SOCKET_ERROR);
  CheckError(closesocket(SockDesc), SOCKET_ERROR);
  Status('Disconnected');
  SetDisc;
end;

procedure SSendCR(S: String);
var
  Buf: PChar;

begin
  S:= S + #13#10;
  Buf:= PChar(S);
  FormMain.FlashLedWrite.Flash;
  CheckError(send(SockDesc, Buf^, Length(S), 0), SOCKET_ERROR);
end;

procedure SendUser;

begin
  Status('Logging in...');
  ResetProgBar(2);
  AdvProgBar;
  ResetTimer(TSKWaitUser);
  SSendCR('user ' + FormMain.EditUser.Text);
end;

procedure SendPass;

begin
  AdvProgBar;
  ResetTimer(TSKWaitPass);
  SSendCR('pass '+FormMain.EditPass.Text);
end;

procedure AskCount;

begin
  Status('Checking messages...');
  SSendCR('stat');
  ResetTimer(TSKWaitCount);
end;

procedure AskList;

begin
  SSendCR('list');
  ResetTimer(TSKWaitList);
end;

procedure GetCount(S: String);

begin
  MsgCount:= StrToInt(GetField(S, 2, ' '));
  if ( MsgCount > 0 ) then
    begin
      ResetProgBar(MsgCount);
      StatNoHeaders:= True;
      StatDeleted:= False;
      FormMain.ButtonDelete.Enabled:= True;
      FormMain.ButtonRead.Enabled:= True;
      FormMain.ListView.Items.Clear;
      AskList;
      ResetTimer(TSKWaitList);
    end
  else
    begin
      StopTimer;
      HideProgBar;
      StatusMsgCnt;
    end;
end;

procedure AskHeadersEnd;

begin
  StopTimer;
  HideProgBar;
  StatusMsgCnt;
end;

procedure AskNextHeader;

begin
  inc(MsgIndex);
  if ( MsgIndex <= FormMain.ListView.Items.Count ) then
    begin
      ResetTimer(TSKWaitHeader);
      AdvProgBar;
      SSendCR('top ' + FormMain.ListView.Items.Item[MsgIndex-1].Caption + ' 0');
    end
  else
    AskHeadersEnd;
end;

procedure AskHeaders;

begin
  StatNoHeaders:= False;
  Status('Retrieving headers...');
  ResetProgBar(FormMain.ListView.Items.Count);
  MsgIndex:= 0;
  AskNextHeader;
end;

procedure ParseHeader(S: String);
var
  Field1: String;

begin
  ResetTimer(TSKParseHeader);
  if ( S <> '.' ) then
    try
      Field1:= GetField(S, 1, ':');
      if ( Field1 = 'From' ) then
        FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Strings[1]:=
        DecodeHdr(Copy(S, 7, Length(S) - 6))
      else if ( Field1 = 'Subject' ) then
        FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Strings[2]:=
        DecodeHdr(Copy(S, 10, Length(S) - 9))
      else if ( Field1 = 'Date' ) then
        FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Strings[3]:=
        DateTimeToStr(DecodeDateTime(Copy(S, 7, Length(S) - 6)));
    except
    end
  else
    AskNextHeader;
end;

procedure ParseListEnd;

begin
  if FormMain.CheckBoxHdr.Checked then
    AskHeaders
  else
    begin
      StopTimer;
      HideProgBar;
      StatusMsgCnt;
    end;
end;

procedure ParseList(S: String);
var
  ListItem: TListItem;

begin
 ResetTimer(TSKParseList);
 if ( S <> '.' ) then
   begin
     AdvProgBar;
     ListItem:= FormMain.ListView.Items.Add;
     ListItem.Caption:= GetField(S, 1, ' ');
     ListItem.SubItems.Add(GetField(S, 2, ' '));
     ListItem.SubItems.Add('-');
     ListItem.SubItems.Add('-');
     ListItem.SubItems.Add('-');
   end
 else
   ParseListEnd;
end;

procedure DeleteItem;

begin
  AdvProgBar;
  ResetTimer(TSKWaitDel);
  with FormMain.ListView.Items.Item[MsgIndex] do
    begin
      SSendCR('dele ' + Caption);
      Caption:= '-';
    end;
end;

procedure DeleteFromList;
var
 Index: Integer;

begin
 Index:= 0;
 repeat
   Index:= FormMain.ListView.FindCaption(Index,'-',False,True,False)
   .Index;
   FormMain.ListView.Items.Delete(Index);
   dec(DelCount);
 until DelCount = 0;
 HideProgBar;
end;

procedure DeleteItemsEnd;

begin
  StopTimer;
  DeleteFromList;
  StatusMsgCnt;
  if not StatDeleted then
    begin
      StatDeleted:= True;
      FormMain.ButtonApply.Enabled:= True;
    end;
end;

procedure DeleteNextItem;

begin
  dec(MsgCount);
  if ( MsgCount > 0 ) then
    begin
      with FormMain.ListView do
        MsgIndex:= GetNextItem(Items.Item[MsgIndex], sdAll, [isSelected]).Index;
      DeleteItem;
    end
  else
    DeleteItemsEnd;
end;

procedure ErrUser;

begin
  StopTimer;
  Error('Invalid username');
  FormMain.EditUser.SetFocus;
end;

procedure ErrPass;

begin
  StopTimer;
  Error('Invalid password');
  FormMain.EditPass.SetFocus;
end;

procedure RetrEnd;

begin
  StopTimer;
  HideProgBar;
  Status('Done');
end;

procedure ParseRetr(S: String);

begin
  ResetTimer(TSKParseRetr);
  NewFormRead.MemoMsg.Lines.Add(S);
  AdvProgBarBy(Length(S) + 2);
  if ( S = '.' ) then
    RetrEnd;
end;

procedure StartRetr;
begin
  NewFormRead.Show;
  ResetTimer(TSKParseRetr);
end;

procedure ParseRcv(S: String);
var
  Field1: String;

begin
  if ( Task in [TSKWaitWelc, TSKWaitUser, TSKWaitPass, TSKWaitCount,
  TSKWaitRetr, TSKWaitDel, TSKWaitQuit] ) then
    Log('<Server> ' + S);
  Field1:= GetField(S, 1, ' ');
  if ( Field1 = '+OK' ) then
    case Task of
      TSKWaitWelc: SendUser;
      TSKWaitUser: SendPass;
      TSKWaitPass: AskCount;
      TSKWaitCount: GetCount(S);
      TSKWaitList: ResetTimer(TSKParseList);
      TSKWaitHeader: ResetTimer(TSKParseHeader);
      TSKWaitRetr: StartRetr;
      TSKWaitDel: DeleteNextItem;
      TSKWaitQuit: Status('Changes applied');
    end
  else if ( Field1 = '-ERR' ) then
    case Task of
      TSKWaitUser: ErrUser;
      TSKWaitPass: ErrPass;
    end
  else
    case Task of
      TSKParseList: ParseList(S);
      TSKParseHeader: ParseHeader(S);
      TSKParseRetr: ParseRetr(S);
    end;
end;

procedure EvtConn;

begin
  Status('Connected');
  StatConnected:= True;
  FormMain.ButtonConn.Caption:= 'Dis&connect';
  FormMain.ButtonConn.Default:= False;
  ResetTimer(TSKWaitWelc);
  CheckError(WSAAsyncSelect(SockDesc, FormMain.Handle, WM_SGEN, FD_GEN),
  SOCKET_ERROR);
end;

procedure EvtRead;
var
  Read, CRPos: Integer;

begin
  FormMain.FlashLedRead.Flash;
  Read:= recv(SockDesc, Buf, SO_RCVBUF, 0);
  CheckError(Read, SOCKET_ERROR);
  Buf[Read + 1]:= #0;
  RcvQue:= RcvQue + StrPas(@Buf);
  CRPos:= Pos(#13, RcvQue);
  while CRPos > 0 do
    begin
      ParseRcv(Trim(Copy(RcvQue, 1, CRPos)));
      Delete(RcvQue, 1, CRPos);
      CRPos:= Pos(#13, RcvQue);
    end;
end;

procedure EvtClose;

begin
  Status('Connection closed by host');
  SetDisc;
end;

procedure TFormMain.WMSockGen(var Message: TMessage);

begin
  case Message.LParamLo of
    FD_READ: EvtRead;
    FD_CLOSE: EvtClose;
  end;
end;

procedure TFormMain.WMSockConn(var Message: TMessage);
begin
  StopTimer;
  if ( Message.LParamHi = 0 ) then
    EvtConn
  else
    begin
      ErrorNum(Message.LParamHi);
      FormMain.EditServer.SetFocus;
    end;
end;

procedure EvtDNS;
var
  HostEnt: PHostEnt;
  Addr: TInAddr;
  IntPtr: ^Integer;

begin
  HostEnt:= @HostEntBuf;
  IntPtr:= @HostEnt.h_addr^^;
  Addr.S_addr:= IntPtr^;
  ConnectHost(inet_ntoa(Addr));
end;

procedure TFormMain.WMSockDNS(var Message: TMessage);

begin
  StopTimer;
  if ( Message.LParamHi = 0 ) then
    EvtDNS
  else
    begin
      ErrorNum(Message.LParamHi);
      FormMain.EditServer.SetFocus;
    end;
end;

procedure TFormMain.ButtonConnClick(Sender: TObject);

begin
  if StatConnected then
    SDisconnect
  else
    SConnect;
end;

procedure InitWinsock;
var
  lpWSAData: TWSAData;
  Code: Integer;

begin
  Code:= WSAStartup(WSVersion,lpWSAData);
  if ( Code = 0 ) then
    Status('Ready')
  else
    ErrorNum(Code);
end;

procedure TFormMain.FormCreate(Sender: TObject);

begin
  Log('E-Res-Q 1.3 - 15/11/2000 - by Ates Goral');
  Log('Check for updates at:');
  Log('http://www.magnetiq.com');
  InitWinsock;
  SettIni:= TIniFile.Create(IniFileName);
  LoadSett;
end;

procedure TFormMain.ButtonApplyClick(Sender: TObject);
begin
  if ( Task = TSKNone ) then
    begin
      ResetTimer(TSKWaitQuit);
      SSendCR('quit');
    end;
end;

procedure TFormMain.ButtonDeleteClick(Sender: TObject);

begin
  if ( Task = TSKNone ) and ( ListView.SelCount > 0 ) then
    begin
      MsgCount:= ListView.SelCount;
      Status('Deleting ' + Plural(MsgCount, 'message', 'messages') + '...');
      ResetProgBar(MsgCount);
      MsgIndex:= ListView.Selected.Index;
      DelCount:= MsgCount;
      DeleteItem;
    end;
end;

procedure TFormMain.EditReqChange(Sender: TObject);
begin
  if not StatConnected then
    CheckFields;
end;

procedure TFormMain.CheckBoxHdrClick(Sender: TObject);
begin
  if StatConnected and CheckBoxHdr.Checked and StatNoHeaders and
  ( Task = TSKNone) and ( FormMain.ListView.Items.Count > 0 ) then
    begin
      AskHeaders;
    end;
end;

procedure TFormMain.ListViewColumnClick(Sender: TObject; Column: TListColumn);

begin
  if ( Task = TSKNone ) and ( ListView.Items.Count > 1 ) then
    if ( Column.Caption = '#' ) then
      begin
        ListView.CustomSort(nil,1);
        NumSortDir:= - NumSortDir;
      end
    else if ( Column.Caption = 'Size' ) then
      begin
        ListView.CustomSort(nil,2);
        SizeSortDir:= - SizeSortDir;
      end;
end;

procedure TFormMain.ListViewCompare(Sender: TObject; Item1, Item2: TListItem;
Data: Integer; var Compare: Integer);
var
  Val1, Val2, Multiplier: Integer;

begin
  case Data of
    1: begin
         Val1:= StrToInt(Item1.Caption);
         Val2:= StrToInt(Item2.Caption);
         Multiplier:= NumSortDir;
       end;
    2: begin
         Val1:= StrToInt(Item1.SubItems.Strings[0]);
         Val2:= StrToInt(Item2.SubItems.Strings[0]);
         Multiplier:= SizeSortDir;
       end;
  end;
  Compare:= (Val1 - Val2) * Multiplier;
end;

procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);

begin
  if StatConnected then
    SDisconnect;
  CheckError(WSACleanup, SOCKET_ERROR);
  SaveSett;
end;

procedure TimeOutDNS;

begin
  Error('DNS lookup timed out');
  WSACancelAsyncRequest(DNSHandle);
  FormMain.EditServer.SetFocus;
end;

procedure TimeOutConn;

begin
  Error('Connection attempt timed out');
  FormMain.EditServer.SetFocus;
  SDisconnect;
end;

procedure TimeOutGen;

begin
  HideProgBar;
  Error('Server response timed out');
end;

procedure TFormMain.TimerTOTimer(Sender: TObject);

begin
  inc(TimeOutCount);
  if ( TimeOutCount > FlashStartDur ) then
    begin
      FlashLedTO.OnColor:= TOColors[trunc(TimeOutCount / TODiv + 0.5)];
      FlashLedTO.Flash;
    end;
  if ( TimeOutCount >= TimeOutDur ) then
    begin
      StopTimer;
      case LastTask of
        TSKWaitDNS: TimeOutDNS;
        TSKWaitConn: TimeOutConn;
        else TimeOutGen;
      end;
    end;
end;

procedure TFormMain.EditUserKeyPress(Sender: TObject; var Key: Char);

begin
  if ( Task = TSKNone ) and ( Key = #13 ) then
    SendUser;
end;

procedure TFormMain.EditPassKeyPress(Sender: TObject; var Key: Char);

begin
  if ( Task = TSKNone ) and ( Key = #13 ) then
    SendPass;
end;

procedure ReadMsg(MsgItem: TListItem);

begin
  Status('Retrieving message ' + MsgItem.Caption + '...');
  ResetProgBar(StrToInt(MsgItem.SubItems.Strings[0]));
  NewFormRead:= TFormRead.Create(FormMain);
  NewFormRead.Caption:= 'Message ' + MsgItem.Caption;
  ResetTimer(TSKWaitRetr);
  SSendCR('retr ' + MsgItem.Caption);
end;

procedure TFormMain.ButtonReadClick(Sender: TObject);
begin
  if ( Task = TSKNone ) and ( ListView.SelCount > 0 ) then
    ReadMsg(ListView.Selected);
end;

procedure TFormMain.MenuItemGridClick(Sender: TObject);
begin
  MenuItemGrid.Checked:= not MenuItemGrid.Checked;
  ListView.GridLines:= MenuItemGrid.Checked;
end;

procedure TFormMain.MenuItemFontClick(Sender: TObject);
begin
  if FontDialog.Execute then
    ListView.Font:= FontDialog.Font;
end;

procedure TFormMain.ListViewDblClick(Sender: TObject);
begin
  if StatConnected and ( Task = TSKNone ) and ( ListView.SelCount > 0 ) then
    ReadMsg(ListView.Selected);
end;

end.
