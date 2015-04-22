unit ERQLineReader;

interface

uses
  SysUtils;

type
  TERQLineReader = class
  private
    MyBuf: array of byte;
    MyCapacity: Integer;
    MyCount: Integer;

  public
    constructor Create(Capacity: Integer);

    procedure Read;

  public
    OnReadBuf: function (var Buf; Count: Integer): Integer of object;
    OnLineRead: procedure (const Line: String) of object;
  end;

implementation

uses
  _Trace;

constructor TERQLineReader.Create(Capacity: Integer);
begin
  Self.MyCapacity := Capacity;
  SetLength(MyBuf, MyCapacity + 1);

  OnReadBuf := nil;
  OnLineRead := nil;

  MyCount := 0;
end;

procedure TERQLineReader.Read;
var
  CRPos, Count, Start: Integer;

begin
  Trace(Format('Receive MyCount: %d  Left: %d', [MyCount, MyCapacity - MyCount]),
    'linebuffer');

  if Assigned(OnReadBuf) then
    Count := OnReadBuf(MyBuf[MyCount], MyCapacity - MyCount)
  else
    Exit;

  Trace(Format('Count: %d', [Count]), 'linebuffer');

  if (Count < 1) then
    Exit;

  MyBuf[MyCount + Count] := 0;
  Trace('DATA: |' + StrPas(@MyBuf[MyCount]) + '|', 'linebuffer');
  Trace(StrPas(@MyBuf[MyCount]), 'raw', False);

  if (MyBuf[0] <> $a) then
    Start := 0
  else
    Start := 1;

  CRPos := MyCount; // was Start

  inc(MyCount, Count);

  Trace(Format('Read: %d  Start: %d  MyCount: %d', [Count, Start, MyCount]),
    'linebuffer');

  repeat
    while (CRPos < MyCount) and (MyBuf[CRPos] <> $d) do
      inc(CRPos);

    Trace(Format('Scanned CRPos: %d  Start: %d  MyCount: %d', [CRPos, Start, MyCount]),
      'linebuffer');

    if (MyBuf[CRPos] = $d) then
      begin
        Trace(Format('Found CR at pos: %d', [CRPos]), 'linebuffer');
        if Assigned(OnLineRead) then
          begin
            MyBuf[CRPos] := 0;
            Trace('OnLineRead: |' + StrPas(@MyBuf[Start]) + '|', 'linebuffer');
            Trace(StrPas(@MyBuf[Start]), 'parsed');
            OnLineRead(StrPas(@MyBuf[Start]));
          end;

        inc(CRPos, 2);

        if (CRPos < MyCapacity) then
          begin
            Start := CRPos;

            Trace(Format('New Start: %d', [Start]), 'linebuffer');
          end
        else
          begin
            Trace('End of buffer', 'linebuffer');
            MyCount := 0;
            break;
          end;
      end
    else if (Start = 0) and (MyCount = MyCapacity) then
      begin
        Trace('End of buffer 2', 'linebuffer');
        MyBuf[MyCapacity] := 0;
        Trace('OnLineRead: |' + StrPas(@MyBuf[Start]) + '|', 'linebuffer');
        Trace(StrPas(@MyBuf[Start]), 'parsed');
        OnLineRead(StrPas(@MyBuf[Start]));
        MyCount := 0;
        break;
      end
    else
      begin
        if (Start > 0) then
          begin
            dec(MyCount, Start);

            Trace(Format('MyCount: %d', [MyCount]), 'linebuffer');

            if (MyCount > 0) then
              begin
                Trace(Format('Blitting from: %d  Count: %d', [Start, MyCount]),
                  'linebuffer');
                StrMove(@MyBuf[0], @MyBuf[Start], MyCount);
                Trace(Format('Blitted from: %d  Count: %d', [Start, MyCount]),
                  'linebuffer');
              end;
          end;

        break;
      end;
  until False;
  Trace('Leave Read()', 'linebuffer');
end;

end.


