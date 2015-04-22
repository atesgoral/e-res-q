unit TextUtils;

interface

uses
  SysUtils;

const
  CryptoKey = 'P3.CK;666';

function ErrToText(Code: Integer): String;
function Plural(Count: Integer; S: String): String;
function GetField(S: String; Field: Integer; Delim: Char): String;
function IsValidPort(S: String): Boolean;
function IsValidIP(S: String): Boolean;
function Encrypt(S: String): String;
function Decrypt(S: String): String;

implementation

function ErrToText(Code: Integer): String;

begin
  case Code of
    10004: ErrToText:= 'WSAEINTR';
    10009: ErrToText:= 'WSAEBADF';
    10013: ErrToText:= 'WSEACCES';
    10014: ErrToText:= 'WSAEFAULT';
    10022: ErrToText:= 'WSAEINVAL';
    10024: ErrToText:= 'WSAEMFILE';
    10035: ErrToText:= 'WSAEWOULDBLOCK';
    10036: ErrToText:= 'WSAEINPROGRESS';
    10037: ErrToText:= 'WSAEALREADY';
    10038: ErrToText:= 'WSAENOTSOCK';
    10039: ErrToText:= 'WSAEDESTADDRREQ';
    10040: ErrToText:= 'WSAEMSGSIZE';
    10041: ErrToText:= 'WSAEPROTOTYPE';
    10042: ErrToText:= 'WSAENOPROTOOPT';
    10043: ErrToText:= 'WSAEPROTONOSUPPORT';
    10044: ErrToText:= 'WSAESOCKTNOSUPPORT';
    10045: ErrToText:= 'WSAEOPNOTSUPP';
    10046: ErrToText:= 'WSAEPFNOSUPPORT';
    10047: ErrToText:= 'WSAEAFNOSUPPORT';
    10048: ErrToText:= 'WSAEADDRINUSE';
    10049: ErrToText:= 'WSAEADDRNOTAVAIL';
    10050: ErrToText:= 'WSAENETDOWN';
    10051: ErrToText:= 'WSAENETUNREACH';
    10052: ErrToText:= 'WSAENETRESET';
    10053: ErrToText:= 'WSAECONNABORTED';
    10054: ErrToText:= 'WSAECONNRESET';
    10055: ErrToText:= 'WSAENOBUFS';
    10056: ErrToText:= 'WSAEISCONN';
    10057: ErrToText:= 'WSAENOTCONN';
    10058: ErrToText:= 'WSAESHUTDOWN';
    10059: ErrToText:= 'WSAETOOMANYREFS';
    10060: ErrToText:= 'WSAETIMEDOUT';
    10061: ErrToText:= 'Connection refused';
    10062: ErrToText:= 'WSAELOOP';
    10063: ErrToText:= 'WSAENAMETOOLONG';
    10064: ErrToText:= 'WSAEHOSTDOWN';
    10065: ErrToText:= 'Host unreachable';
    10091: ErrToText:= 'WSASYSNOTREADY';
    10092: ErrToText:= 'WSAVERNOTSUPPORTED';
    10093: ErrToText:= 'WSANOTINITIALISED';
    11001: ErrToText:= 'WSAHOST_NOT_FOUND';
    11002: ErrToText:= 'WSATRY_AGAIN';
    11003: ErrToText:= 'WSANO_RECOVERY';
    11004: ErrToText:= 'Address does not resolve';
    else ErrToText:= 'Winsock - ' + IntToStr(Code);
  end;
end;

function Plural(Count: Integer; S: String): String;
var
  IntTxt, Attach: String;
begin
  if ( Count > 0 ) then
    IntTxt:= IntToStr(Count)
  else
    IntTxt:= 'No';
  if ( Count <> 1 ) then
     Attach:= 's'
  else
     Attach:= '';
  Plural:= IntTxt + ' ' + S + Attach;
end;

function GetField(S: String; Field: Integer; Delim: Char): String;
var
  Len, Start, Index: Integer;

begin
  Len:= Length(S);
  if ( Len > 0 ) then
    begin
      Index:= 1;
      repeat
        while ( S[Index] = Delim ) and ( Index <= Len ) do
          inc(Index);
        if ( Index <= Len ) then
          begin
            if ( Field = 1 ) then
              Start:= Index;
            repeat
              inc(Index);
            until ( S[Index] = Delim ) or ( Index > Len );
            dec(Field);
            if ( Field = 0 ) then
              GetField:= Copy(S,Start,Index-Start);
          end
        else
          begin
            GetField:= '';
            Field:= 0;
          end;
      until ( Field = 0 );
    end;
end;

function IsValidToken(S: String; Field: Integer): Boolean;
var
  Value, Code: Integer;

begin
  Val(GetField(S,Field,'.'), Value, Code);
  IsValidToken:= ( Code = 0 ) and ( Value in [0..255] );
end;

function IsValidPort(S: String): Boolean;
var
  Value, Code: Integer;

begin
  Val(S, Value, Code);
  IsValidPort:= ( Code = 0 ) and ( Value > 0 ) and ( Value < 65535 );
end;

function IsValidIP(S: String): Boolean;

begin
  IsValidIP:= IsValidToken(S,1) and IsValidToken(S,2) and IsValidToken(S,3) and
  IsValidToken(S,4);
end;

function Encrypt(S: String): String;
var
  Index, KeyIndex: Integer;
  NewStr: String;
  AscSum: Integer;

begin
  NewStr:= '';
  KeyIndex:= 1;
  for Index:= 1 to Length(S) do
    begin
      AscSum:= Ord(S[Index]) + Ord(CryptoKey[KeyIndex]);
      NewStr:= NewStr + Chr(Ascsum div 16 + 33) + Chr(Ascsum mod 16 + 33);
      inc(KeyIndex);
      if ( KeyIndex > Length(CryptoKey) ) then
        KeyIndex:= 1;
    end;
  Encrypt:= NewStr;
end;

function Decrypt(S: String): String;
var
  Index, KeyIndex: Integer;
  NewStr: String;
  HiNum, LoNum: Integer;

begin
  NewStr:= '';
  KeyIndex:= 1;
  for Index:= 1 to Length(S) div 2 do
    begin
      HiNum:= Ord(S[Index * 2 - 1]) - 33;
      LoNum:= Ord(S[Index * 2]) - 33;
      NewStr:= NewStr + Chr(HiNum * 16 + LoNum - Ord(CryptoKey[KeyIndex]));
      inc(KeyIndex);
      if ( KeyIndex > Length(CryptoKey) ) then
        KeyIndex:= 1;
    end;
  Decrypt:= NewStr;
end;

end.
