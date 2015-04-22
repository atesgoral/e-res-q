{ Version 0.9 2000.10.26 02:33 }

unit MIMEDecode;

interface

uses
  SysUtils, Classes,
  StrUtilsX;

type
  EMIMEError = class(Exception);

function DecodeHdr(S: String): String;

implementation

function CharsetID(S: String): Integer;
begin
  Result := 0;
  if (S = 'Ufuk') then
    raise EMIMEError.Create('Unsupported character set');
end;

function HexToInt(Ch: Char): Integer;
begin
  if (Ch >= '0') and (Ch <= '9') then
    Result := Ord(Ch) - Ord('0')
  else if (Ch >= 'A') and (Ch <= 'F') then
    Result := Ord(Ch) - Ord('A') + 10
  else if (Ch >= 'a') and (Ch <= 'f') then
    Result := Ord(Ch) - Ord('a') + 10
  else
    raise EMIMEError.Create('Invalid hexadecimal digit');
end;

function HexToChar(Charset: Integer; S: String): Char;
begin
  if (Length(S) = 2) then
    Result := Chr(HexToInt(S[1]) shl 4 + HexToInt(S[2]))
  else
    raise EMIMEError.Create('Unexpected end of text');
end;

function MIMEDecodeQ(Charset: Integer; S: String): String;
var
  Len, Index: Integer;
  Ch: Char;

begin
  Result := '';
  Len := Length(S);
  Index := 1;
  while (Index <= Len) do
    begin
      Ch := S[Index];
      case Ch of
        '_': Result := Result + ' ';
        '=':
          begin
            if (Index + 1 < Len) then
              Result := Result + Chr(HexToInt(S[Index + 1]) shl 4 + HexToInt(S[Index + 2]))
            else
              raise EMIMEError.Create('Unexpected end of text');
            inc(Index, 2);
          end;
      else
        Result := Result + Ch;
      end;
      inc(Index);
    end;

end;

function MIMEDecodeB(Charset: Integer; S: String): String;
type
  TChar3 = record
    Chars: packed array [1..3] of Char;
    Pad: Byte;
  end;

var
  Len, Cnt: Integer;
  Ch: Char;
  Buff: Longword;
  Sixels: Integer;
  Legal: Boolean;
  Char3: ^TChar3;
  CharIdx: Integer;

begin
  Result := '';
  Buff := 0;
  Char3 := @Buff;
  Sixels := 0;
  Len := Length(S);
  for Cnt := 1 to Len do
    begin
      Ch := S[Cnt];
      Legal := True;
      case Ch of
        'A'..'Z': Buff := Buff shl 6 + Ord(Ch) - Ord('A');
        'a'..'z': Buff := Buff shl 6 + Ord(Ch) - Ord('a') + 26;
        '0'..'9': Buff := Buff shl 6 + Ord(Ch) - Ord('0') + 52;
        '+': Buff := Buff shl 6 + 62;
        '/': Buff := Buff shl 6 + 63;
        '=': Buff := Buff shl 6;
      else
        Legal := False;
      end;
      if Legal then
        begin
          inc(Sixels);
          if (Sixels = 4) then
            begin
              CharIdx := 3;
              while (CharIdx > 0) and (Char3.Chars[CharIdx] <> #0) do
                begin
                  Result := Result + Char3.Chars[CharIdx];
                  dec(CharIdx);
                end;
              Sixels := 0;
            end;
        end;
    end;
end;

function DecodeHdr(S: String): String;
var
  Len, StartPos, EndPos: Integer;
  Tokens: TStringList;
  Encoding: String;
  Decoded: String;

begin
  Result := '';
  Len := Length(S);
  StartPos := Pos('=?', S);
  if (StartPos > 0) then
    begin
      EndPos := Pos('?=', S);
      if (EndPos > 0) then
        begin
          Tokens := SplitTokens(Copy(S, StartPos + 2, EndPos - StartPos - 2), '?', False);
          try
            Encoding := Tokens.Strings[1];
            case Encoding[1] of
              'Q', 'q': Decoded := MIMEDecodeQ(CharsetID(Tokens[0]), Tokens[2]);
              'B', 'b': Decoded := MIMEDecodeB(CharsetID(Tokens[0]), Tokens[2]);
            else
              raise EMIMEError.Create('Unknown encoding');
            end;
          finally
            Tokens.Free;
          end;
          Result := Result + Copy(S, 1, StartPos - 1) + Decoded;
          if (EndPos + 1 < Len) then
            Result := Result + DecodeHdr(Copy(S, EndPos + 2, Len - EndPos - 1));
        end
      else
        raise EMIMEError.Create('Unterminated text');
    end
  else
    Result := S;
end;

end.

