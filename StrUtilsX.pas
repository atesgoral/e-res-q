unit StrUtilsX;

interface

uses
  Classes, SysUtils;
  
function SplitTokens(S: String; Delim: Char; AllowQuote: Boolean): TStringList;
function IntToUnitStr(I: Longint): String;
function Plural(N: Integer; SS, PS: String): String;

implementation

function SplitTokens(S: String; Delim: Char; AllowQuote: Boolean): TStringList;
var
  Len, Start, Index: Integer;
  Quote: Boolean;

begin
  Result := TStringList.Create;
  Len := Length(S);
  if (Len > 0) then
    begin
      Quote := False;
      Index := 1;
      repeat
        while (S[Index] = Delim) and (Index <= Len) do
          inc(Index);
        if (Index <= Len) then
          begin
            Start := Index;
            repeat
              if AllowQuote and (S[Index] = '"') then
                Quote := not Quote;
              inc(Index);
            until ((not Quote) and (S[Index] = Delim)) or (Index > Len);
            Result.Add(Copy(S, Start, Index - Start));
          end
      until (Index > Len);
    end;
end;

function IntToUnitStr(I: Longint): String;
var
  R: Real;

begin
  if (I < 1000) then
    Result := IntToStr(I)
  else
    begin
      R := I / 1024;
      if (R < 1000) then
        Result := Format('%.3g K', [R])
      else
        begin
          R := R / 1024;
          Result := Format('%.3g M', [R])
        end;
    end;
end;

function Plural(N: Integer; SS, PS: String): String;
begin
  if (N <> 1) then
    Result := PS
  else
    Result := SS;
  if (N > 0) then
    Result := IntToStr(N) + ' ' + Result
  else
    Result := 'no' + ' ' + Result;
end;

end.
