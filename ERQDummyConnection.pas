unit ERQDummyConnection;

interface

uses
  ERQConnection, ERQConnectionHandler;

type
  TERQDummyConnection = class(AERQConnection)
  private
    MyLineReadHandler: procedure (const S: String) of object;

  public
    OnWriteLine: procedure (const S: String) of object;

    procedure FakeLineRead(const S: String);

    { AERQConnection overrides }

    procedure Connect(const Host: String; Port: Integer); override;

    procedure SetLineReadHandler(Handler: TERQLineReadHandler); override;
    procedure WriteLine(const S: String); override;

  end;

implementation

{ TERQDummyConnection }

procedure TERQDummyConnection.Connect(const Host: String; Port: Integer);
begin
end;

procedure TERQDummyConnection.FakeLineRead(const S: String);
begin
  MyLineReadHandler(S);
end;

procedure TERQDummyConnection.SetLineReadHandler(Handler: TERQLineReadHandler);
begin
  MyLineReadHandler := Handler;
end;

procedure TERQDummyConnection.WriteLine(const S: String);
begin
  if Assigned(OnWriteLine) then
    OnWriteLine(S);
end;

end.
