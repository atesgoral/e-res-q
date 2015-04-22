{ Version 1.0 2000.10.30 09:38 }

unit DateTimeDecode;

interface

uses
  SysUtils, Windows, Classes,
  StrUtilsX;

type
  EDateTimeError = class(Exception);

function DecodeDateTime(S: String): TDateTime;

implementation

const
  TZE_UNRECOGNIZED = 'Unrecognized time zone';

function MonthNameToInt(S: String): Integer;
begin
  if (S = 'Jan') then
    Result := 1
  else if (S = 'Feb') then
    Result := 2
  else if (S = 'Mar') then
    Result := 3
  else if (S = 'Apr') then
    Result := 4
  else if (S = 'May') then
    Result := 5
  else if (S = 'Jun') then
    Result := 6
  else if (S = 'Jul') then
    Result := 7
  else if (S = 'Aug') then
    Result := 8
  else if (S = 'Sep') then
    Result := 9
  else if (S = 'Oct') then
    Result := 10
  else if (S = 'Nov') then
    Result := 11
  else if (S = 'Dec') then
    Result := 12
  else
    raise EDateTimeError.Create('Invalid month name');
end;

function NorthAmericanToZoneBias(S: String): Integer;
var
  Zone, Daylight: Integer;

begin
  case S[1] of
    'E': Zone := - 5;
    'C': Zone := - 6;
    'M': Zone := - 7;
    'P': Zone := - 8;
  else
    raise EDateTimeError.Create(TZE_UNRECOGNIZED);
  end;
  case S[2] of
    'S': Daylight := 0;
    'D': Daylight := 1;
  else
    raise EDateTimeError.Create(TZE_UNRECOGNIZED);
  end;
  Result := (Zone + Daylight) * 60;
end;

function TimeZoneToTimeDiff(S: String): TDateTime;
var
  TZI: _TIME_ZONE_INFORMATION;
  ZoneInt, ZoneBias: Integer;
  Len: Integer;
  Mil: Char;
  MilZone: Integer;

begin
  try
    ZoneInt := StrToInt(S);
    ZoneBias := ZoneInt div 100 * 60 + ZoneInt mod 100;
  except
    Len := Length(S);
    if (Len = 3) and (S[3] = 'T') then
      begin
        if (S = 'GMT') then
          ZoneBias := 0
        else
          ZoneBias := NorthAmericanToZoneBias(S)
      end
    else if (Len = 2) and (S = 'UT') then
      ZoneBias := 0
    else if (Len = 1) then
      begin
        Mil := S[1];
        case Mil of
          'A'..'I': MilZone := Ord('A') - Ord(Mil) - 1;
          'K'..'M': MilZone := Ord('K') - Ord(Mil) - 10;
          'N'..'Y': MilZone := Ord(Mil) - Ord('N') + 1;
          'Z': MilZone := 0;
        else
          raise EDateTimeError.Create('Illegal military letter in time zone');
        end;
        ZoneBias := MilZone * 60;
      end
    else
      raise EDateTimeError.Create(TZE_UNRECOGNIZED);
  end;
  GetTimeZoneInformation(TZI);
  Result := (ZoneBias + TZI.Bias) / (24 * 60);
end;

function DecodeDateTime(S: String): TDateTime;
var
  Tokens: TStringList;
  WeekDay, DayStr, MonthStr, YearStr, TimeStr, GMTStr: String;

begin
  Tokens := SplitTokens(S, ' ', False);
  try
    try
      WeekDay := Tokens[0];
      if (WeekDay[4] = ',') then
        Tokens.Delete(0);
      DayStr := Tokens[0];
      MonthStr := Tokens[1];
      YearStr := Tokens[2];
      TimeStr := Tokens[3];
      GMTStr := Tokens[4];
    except
      raise EDateTimeError.Create('Missing token');
    end;
  finally
    Tokens.Free;
  end;
  Result := EncodeDate(StrToInt(YearStr), MonthNameToInt(MonthStr), StrToInt(DayStr)) +
    StrToTime(TimeStr) - TimeZoneToTimeDiff(GMTStr);
end;

end.
