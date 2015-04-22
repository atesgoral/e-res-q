unit ERQParser;

interface

uses
  Classes;

type
  TERQParser = class
  public
    procedure BeginParsing(); virtual; abstract;
    procedure Parse(const Line: String); virtual; abstract;
    procedure EndParsing(); virtual; abstract;
  end;

implementation

end.
