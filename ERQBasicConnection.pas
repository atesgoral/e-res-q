unit ERQBasicConnection;

interface

uses
  Classes, ScktComp,

  ERQConnection, ERQConnectionHandler, ERQLineReader;

type
  TERQBasicConnection = class(AERQConnection)
  private
    MySocket: TClientSocket;
    MyLineReader: TERQLineReader;

    { TClientSocket event handlers }

    procedure SocketLookup(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketConnecting(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketWrite(Sender: TObject; Socket: TCustomWinSocket);
    procedure SocketError(Sender: TObject; SocketError: Integer);

    { TERQLineReader event handlers }

    function HandleReadBuf(var Buf; Count: Integer): Integer;

  public
    constructor Create(AOwner: TComponent;
      ConnectionHandler: IERQConnectionHandler);

    { AERQConnection overrides }

    procedure Connect(const Host: String; Port: Integer); override;

    procedure SetLineReadHandler(Handler: TERQLineReadHandler); override;
    procedure WriteLine(const S: String); override;
  end;

implementation

{ TERQBasicConnection }

constructor TERQBasicConnection.Create(AOwner: TComponent;
  ConnectionHandler: IERQConnectionHandler);
begin
  inherited Create(ConnectionHandler);

  MySocket := TClientSocket.Create(AOwner);
  MySocket.OnLookup := SocketLookup;
  MySocket.OnConnecting := SocketConnecting;
  MySocket.OnConnect := SocketConnect;
  MySocket.OnDisconnect := SocketDisconnect;
  MySocket.OnRead := SocketRead;
  MySocket.OnWrite := SocketWrite;
  //MySocket.OnError := SocketError;

  MyLineReader := TERQLineReader.Create(32000); // Arbitrary!
  MyLineReader.OnReadBuf := HandleReadBuf;
end;

{ TERQBasicConnection: AERQConnection overrides }

procedure TERQBasicConnection.Connect(const Host: String; Port: Integer);
begin
  MySocket.Host := Host;
  MySocket.Port := Port;
  MySocket.Open;
end;

procedure TERQBasicConnection.SetLineReadHandler(Handler: TERQLineReadHandler);
begin
  MyLineReader.OnLineRead := Handler;
end;

procedure TERQBasicConnection.WriteLine(const S: String);
var
  Sent: Integer;
begin
  Sent := MySocket.Socket.SendText(S + #13#10);
  // Assume will write in one go for now!
  Assert(Sent = (Length(S) + 2), 'Could not send line in one go');
end;

{ TERQBasicConnection: TClientSocket events }

procedure TERQBasicConnection.SocketLookup(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionLookup();
end;

procedure TERQBasicConnection.SocketConnecting(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionConnecting();
end;

procedure TERQBasicConnection.SocketConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionConnect();
end;

procedure TERQBasicConnection.SocketDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionDisconnect();
end;

procedure TERQBasicConnection.SocketRead(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionRead();
  MyLineReader.Read;
end;

procedure TERQBasicConnection.SocketWrite(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  MyConnectionHandler.ConnectionWrite();
end;

procedure TERQBasicConnection.SocketError(Sender: TObject;
  SocketError: Integer);
begin
  MyConnectionHandler.ConnectionError();
end;

{ TERQBasicConnection: TERQLineReader events }

function TERQBasicConnection.HandleReadBuf(var Buf; Count: Integer): Integer;
begin
  Result := MySocket.Socket.ReceiveBuf(Buf, Count);
end;

end.
