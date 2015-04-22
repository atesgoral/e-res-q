unit ERQProtocol;

interface

uses
  ERQConnection;

type
  AERQProtocol = class
  protected
    MyConn: AERQConnection;

    procedure HandleLineRead(const S: String); virtual; abstract;

  public
    constructor Create(Conn: AERQConnection);
  end;

implementation

{ TERQProtocol }

constructor AERQProtocol.Create(Conn: AERQConnection);
begin
  MyConn := Conn;
  MyConn.SetLineReadHandler(HandleLineRead);
end;

end.
