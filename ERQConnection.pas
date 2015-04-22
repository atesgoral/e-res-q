unit ERQConnection;

interface

uses
  Classes, ERQConnectionHandler;

type
  TERQLineReadHandler = procedure (const Line: String) of object;

  AERQConnection = class
  protected
    MyConnectionHandler: IERQConnectionHandler;

  public
    constructor Create(ConnectionHandler: IERQConnectionHandler);

    procedure Connect(const Host: String; Port: Integer); virtual; abstract;

    procedure SetLineReadHandler(Handler: TERQLineReadHandler); virtual;
      abstract;
    procedure WriteLine(const S: String); virtual; abstract;
  end;

implementation

{ AERQConnection }

constructor AERQConnection.Create(ConnectionHandler: IERQConnectionHandler);
begin
  MyConnectionHandler := ConnectionHandler;
end;

end.
