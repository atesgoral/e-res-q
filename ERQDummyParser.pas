unit ERQDummyParser;

interface

uses
  ERQParser;

type
  TParserState = (psBegin, psHeader, psHeaderUnfold, psBody, psEnd);

  TERQDummyParser = class(TERQParser)
  private
    State: TParserState;

    FSubject: String;

  public
    procedure BeginParsing; override;
    procedure Parse(const Line: String); override;
    procedure EndParsing; override;
  published
    property Subject: String read FSubject;
  end;

implementation

{ TERQDummyParser }

procedure TERQDummyParser.BeginParsing;
begin
end;

procedure TERQDummyParser.Parse(const Line: String);
begin
end;

procedure TERQDummyParser.EndParsing;
begin
  FSubject := 'foo';
end;

end.
