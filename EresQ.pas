unit EresQ;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Winsock, StdCtrls, ComCtrls, ExtCtrls, IniFiles, TextUtils;

const
  WSVersion = $202;
  FD_GEN = FD_READ or FD_CLOSE;
  WM_SDNS = WM_USER + 100;
  WM_SCONN = WM_SDNS + 1;
  WM_SGEN = WM_SCONN + 1;
  TimeOutDur = 60;
  TODiv = TimeOutDur / 3;
  FlashDur = 100;
  FlashStartDur = 2;
  TOColors: array [0..3] of TColor = (clDkGray, clGray, clLtGray, clWhite);
  IniFileName = 'POP3Spy.ini';
  SectSett = 'settings';
  KeyUser = 'username';
  KeyPass = 'password';
  KeyServer = 'server';
  KeyPort = 'port';
  KeyHdr = 'getheaders';
  KeyGrid = 'gridlines';
  KeySaveUser = 'saveusername';
  KeySavePass = 'savepassword';
  KeySaveServer = 'saveserver';
  KeySavePort = 'saveport';

type
  TFormMain = class(TForm)
    ButtonConn: TButton;
    EditServer: TEdit;
    EditPort: TEdit;
    MemoLog: TMemo;
    EditUser: TEdit;
    EditPass: TEdit;
    Splitter: TSplitter;
    PanelSett: TPanel;
    PanelFunc: TPanel;
    PanelLV: TPanel;
    BevelServer: TBevel;
    ButtonDelete: TButton;
    ListView: TListView;
    ButtonApply: TButton;
    CheckBoxUser: TCheckBox;
    CheckBoxPass: TCheckBox;
    CheckBoxServer: TCheckBox;
    CheckBoxPort: TCheckBox;
    CheckBoxHdr: TCheckBox;
    TimerTO: TTimer;
    PanelStatus: TPanel;
    StatusBar: TStatusBar;
    LedWrite: TShape;
    LedRead: TShape;
    LedTO: TShape;
    BevelTO: TBevel;
    TimerLedWrite: TTimer;
    TimerLedRead: TTimer;
    TimerLedTO: TTimer;
    BevelRead: TBevel;
    BevelWrite: TBevel;
    ProgressBar: TProgressBar;
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
    procedure TimerLedTOTimer(Sender: TObject);
    procedure TimerLedReadTimer(Sender: TObject);
    procedure TimerLedWriteTimer(Sender: TObject);
    procedure EditUserKeyPress(Sender: TObject; var Key: Char);
    procedure EditPassKeyPress(Sender: TObject; var Key: Char);
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
  TSKWaitPass, TSKWaitList, TSKParseList, TSKWaitHeader, TSKParseHeader,
  TSKWaitDel, TSKWaitQuit);

var
  FormMain: TFormMain;
  SettIni: TIniFile;
  HostEntBuf: array [1..MAXGETHOSTSTRUCT] of byte;
  DNSHandle: Integer;
  SockDesc: TSocket;
  lpWSAData: TWSAData;
  StatConnected: Boolean = False;
  StatGridsOn: Boolean = False;
  StatNoHeaders, StatDeleted: Boolean;
  Task, LastTask: TTask;
  MsgCount, MsgIndex, DelCount: Integer;
  RcvQue: String = '';
  NumSortDir: Integer = -1;
  SizeSortDir: Integer = -1;
  TimeOutCount: Integer;

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

procedure HideProgBar;

begin
  FormMain.ProgressBar.Visible:= False;
end;

procedure FlashLed(var Led: TShape; var Timer: TTimer; Color: TColor);

begin
  Led.Brush.Color:= Color;
  Timer.Interval:= FlashDur;
  Timer.Enabled:= True;
end;

procedure ResetTimer(TOTask: TTask);

begin
  Task:= TOTask;
  TimeOutCount:= 0;
  Screen.Cursor:= crAppStart;
  FormMain.TimerTO.Enabled:= True;
  FormMain.TimerTO.Interval:= 500;
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
  Status(Plural(FormMain.ListView.Items.Count,'message'));
end;

procedure ErrorNum(WSCode: Integer);

begin
  if ( WSCode <> 10035 ) then
    Error(IntToStr(WSCode) + ': ' + ErrToText(WSCode));
end;

procedure CheckError(Code, ErrCode: Integer);

begin
  if ( Code = ErrCode ) then
    begin
      StopTimer;
      ErrorNum(WSAGetLastError);
    end;
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
      LoadIni(KeyPort, EditPort, CheckBoxPort);
      CheckBoxHdr.Checked:= SettIni.ReadBool(SectSett, KeyHdr, False);
      ListView.GridLines:= SettIni.ReadBool(SectSett, KeyGrid, False);
    end;
end;

procedure SaveSett;

begin
  with FormMain do
    begin
      SaveIni(KeyUser, EditUser.Text, CheckBoxUser);
      SaveIni(KeyPass, Encrypt(EditPass.Text), CheckBoxPass);
      SaveIni(KeyServer, EditServer.Text, CheckBoxServer);
      SaveIni(KeyPort, EditPort.Text, CheckBoxPort);
      SettIni.WriteBool(SectSett, KeyHdr, CheckBoxHdr.Checked);
      SettIni.WriteBool(SectSett, KeyGrid, ListView.GridLines);
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
  SAddr.sin_port:= htons(StrToInt(FormMain.EditPort.Text));
  CheckError(WSAAsyncSelect(SockDesc, FormMain.Handle, WM_SCONN, FD_CONNECT),
  SOCKET_ERROR);
  CheckError(connect(SockDesc, SAddr, SizeOf(SAddr)), SOCKET_ERROR);
end;

function IsValidPort(S: String): Boolean;
var
  Value, Code: Integer;

begin
  Val(S, Value, Code);
  IsValidPort:= ( Code = 0 ) and ( Value > 0 ) and ( Value < 65535 );
end;

procedure SConnect;

begin
  with FormMain.EditPort do
    if ( Text = '' ) or ( not IsValidPort(Text) ) then
      Text:= '110';
  if IsHost(FormMain.EditServer.Text) then
    ConnectHost(FormMain.EditServer.Text)
  else
    DNSLookup(FormMain.EditServer.Text);
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
      ButtonApply.Enabled:= False;
    end;
  CheckFields;
end;

procedure SDisconnect;

begin
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
  FlashLed(FormMain.LedWrite, FormMain.TimerLedWrite, clRed);
  CheckError(send(SockDesc,Buf^,Length(S),0), SOCKET_ERROR);
end;

procedure SendUser;

begin
  Status('Logging in...');
  ResetProgBar(2);
  AdvProgBar;
  ResetTimer(TSKWaitUser);
  SSendCR('user '+FormMain.EditUser.Text);
end;

procedure SendPass;

begin
  AdvProgBar;
  ResetTimer(TSKWaitPass);
  SSendCR('pass '+FormMain.EditPass.Text);
end;

procedure AskList;

begin
  Status('Checking messages...');
  SSendCR('list');
  ResetTimer(TSKWaitList);
end;

procedure GetCount(S: String);

begin
  MsgCount:= StrToInt(GetField(S,2,' '));
  if ( MsgCount > 0 ) then
    begin
      ResetProgBar(MsgCount);
      StatNoHeaders:= True;
      StatDeleted:= False;
      FormMain.ButtonDelete.Enabled:= True;
      FormMain.ListView.Items.Clear;
      ResetTimer(TSKParseList);
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
  Status('Checking headers...');
  ResetProgBar(FormMain.ListView.Items.Count);
  MsgIndex:= 0;
  AskNextHeader;
end;

procedure ParseHeader(S: String);
var
 Field: String;

begin
  if ( S <> '.' ) then
    begin
      Field:= GetField(S,1,':');
      if ( Field = 'From' ) then
        begin
          Delete(S,1,6);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Delete(1);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Insert(1,S);
        end
      else if ( Field = 'Subject' ) then
        begin
          Delete(S,1,9);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Delete(2);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Insert(2,S);
        end
      else if ( Field = 'Date' ) then
        begin
          Delete(S,1,6);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Delete(3);
          FormMain.ListView.Items.Item[MsgIndex-1].SubItems.Insert(3,S);
        end;
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
      StatusMsgCnt;
    end;
end;

procedure ParseList(S: String);
var
  ListItem: TListItem;

begin
 if ( S <> '.' ) then
   begin
     AdvProgBar;
     ListItem:= FormMain.ListView.Items.Add;
     ListItem.Caption:= GetField(S,1,' ');
     ListItem.SubItems.Add(GetField(S,2,' '));
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

procedure ParseRcv(S: String);
var
  Field1: String;

begin
  if ( Task in [TSKWaitWelc, TSKWaitUser, TSKWaitPass, TSKWaitList,
  TSKWaitDel, TSKWaitQuit] ) then
    Log('<Server> ' + S);
  Field1:= GetField(S,1,' ');
  if ( Field1 = '+OK' ) then
    case Task of
      TSKWaitWelc: SendUser;
      TSKWaitUser: SendPass;
      TSKWaitPass: AskList;
      TSKWaitList: GetCount(S);
      TSKWaitHeader: ResetTimer(TSKParseHeader);
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
  Buf:array [1..SO_RCVBUF] of Char;
  CRPos: Integer;

begin
  FlashLed(FormMain.LedRead, FormMain.TimerLedRead, clLime);
  FillChar(Buf,SO_RCVBUF,#0);
  CheckError(recv(SockDesc,Buf,SO_RCVBUF,0), SOCKET_ERROR);
  RcvQue:= RcvQue + StrPas(@Buf);
  CRPos:= Pos(#13,RcvQue);
  while CRPos > 0 do
    begin
      ParseRcv(Trim(Copy(RcvQue,1,CRPos)));
      Delete(RcvQue,1,CRPos);
      CRPos:= Pos(#13,RcvQue);
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

begin
  if ( WSAStartup(WSVersion,lpWSAData) = 0 ) then
    Status('Ready')
  else
    Error('Winsock init failed!');
end;

procedure TFormMain.FormCreate(Sender: TObject);

begin
  Log('E-res-Q 1.1 - ©1998 - by HeaT - heat@turk.net');
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
  if ( Task = TSKNone ) then
    begin
      MsgCount:= ListView.SelCount;
      if ( MsgCount > 0 ) then
        begin
          Status('Deleting ' + Plural(MsgCount, 'message') + '...');
          ResetProgBar(MsgCount);
          MsgIndex:= ListView.Selected.Index;
          DelCount:= MsgCount;
          DeleteItem;
        end;
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
    begin
      SDisconnect;
      CheckError(WSACleanup, SOCKET_ERROR);
    end;
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
  SetDisc;
end;

procedure TimeOutGen;

begin
  Error('Server response timed out');
  SDisconnect;
end;

procedure TFormMain.TimerTOTimer(Sender: TObject);

begin
  inc(TimeOutCount);
  if ( TimeOutCount > FlashStartDur ) then
    FlashLed(LedTO, TimerLedTO, TOColors[trunc(TimeOutCount / TODiv + 0.5)]);
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

procedure TFormMain.TimerLedTOTimer(Sender: TObject);

begin
  FormMain.LedTO.Brush.Color:= clBlack;
  FormMain.TimerLedTO.Enabled:= False;
end;

procedure TFormMain.TimerLedReadTimer(Sender: TObject);

begin
  LedRead.Brush.Color:= clGreen;
  TimerLedRead.Enabled:= False;
end;

procedure TFormMain.TimerLedWriteTimer(Sender: TObject);

begin
  LedWrite.Brush.Color:= clMaroon;
  TimerLedWrite.Enabled:= False;
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

procedure TFormMain.ListViewDblClick(Sender: TObject);

begin
  if StatGridsOn then
    begin
      ListView.GridLines:= False;
      StatGridsOn:= False;
    end
  else
    begin
      ListView.GridLines:= True;
      StatGridsOn:= True;
    end;
end;

end.
