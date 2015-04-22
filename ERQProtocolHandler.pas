unit ERQProtocolHandler;

interface

type
  IERQProtocolHandler = interface(IInterface)
    procedure ProtocolWelcome();
    procedure ProtocolUserResponse();
    procedure ProtocolPassResponse();
    procedure ProtocolStatResponse();
  end;

implementation

end.
