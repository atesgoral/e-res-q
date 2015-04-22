unit ERQPOP3Protocol;

interface

uses
  Contnrs,

  ERQProtocol, ERQProtocolHandler, ERQConnection;

type
  IERQPOP3StateMachine = interface(IInterface)
    procedure Leave(Success: Boolean);
  end;

  TERQPOP3State = class
  private
    MyNext: TERQPOP3State;

  protected
    procedure Leave(Success: Boolean);

  public
    constructor Create(Machine: IERQPOP3StateMachine);

    procedure ParseLine(const S: String); virtual;
  end;

  TERQPOP3WelcomeState = class(TERQPOP3State)
  end;

  TERQPOP3USERState = class(TERQPOP3State)
  end;

  TERQPOP3PASSState = class(TERQPOP3State)
  end;

  TERQPOP3STATState = class(TERQPOP3State)
  end;

  TERQPOP3LISTState = class(TERQPOP3State)
  end;

  TERQPOP3LISTDataState = class(TERQPOP3State)
  end;

  TERQPOP3TOPState = class(TERQPOP3State)
  end;

  TERQPOP3TOPDataState = class(TERQPOP3State)
  end;

  TERQPOP3RECVState = class(TERQPOP3State)
  end;

  TERQPOP3RECVDataState = class(TERQPOP3State)
  end;

  TERQPOP3DELEState = class(TERQPOP3State)
  end;

  TERQPOP3QUITState = class(TERQPOP3State)
  end;

  TERQPOP3Protocol = class(AERQProtocol)

  private
    MyUser, MyPass: String;
    MyTurbo: Boolean;

  protected
    { AERQProtocol overrides }

    procedure HandleLineRead(const S: String); override;

  public
    constructor Create(Conn: AERQConnection; const User, Pass: String;
      Turbo: Boolean);
  end;

implementation

{ TERQPOP3Protocol }

constructor TERQPOP3Protocol.Create(Conn: AERQConnection;
  const User, Pass: String; Turbo: Boolean);
begin
  inherited Create(Conn);

  MyUser := User;
  MyPass := Pass;
  MyTurbo := Turbo;
end;

procedure TERQPOP3Protocol.HandleLineRead(const S: String);
begin
  MyConn.WriteLine('ECHO ' + S);
end;

{ TERQPOP3State }

constructor TERQPOP3State.Create(Machine: IERQPOP3StateMachine);
begin
  MyMachine := Machine;
  MyNext := nil;
end;

procedure TERQPOP3State.Leave(Success: Boolean);
begin

end;

procedure TERQPOP3State.ParseLine(const S: String);
begin
  case S[1] of
    '+': Leave(True);
    '-': Leave(False);
  else
  // Proto error!
  end;
end;

end.
