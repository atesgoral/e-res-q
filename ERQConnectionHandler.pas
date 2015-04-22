unit ERQConnectionHandler;

interface

type
  IERQConnectionHandler = interface(IInterface)
    procedure ConnectionLookup();
    procedure ConnectionConnecting();
    procedure ConnectionConnect();
    procedure ConnectionDisconnect();
    procedure ConnectionRead();
    procedure ConnectionWrite();
    procedure ConnectionError();
  end;

implementation

end.
