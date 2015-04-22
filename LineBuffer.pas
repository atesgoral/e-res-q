unit LineBuffer;

interface

uses
  //Winsock, ScktComp,
  SysUtils;

type
  TLineReaderSource = class
  public
    function Read(var Buf; Size: Integer): Integer; virtual; abstract;
  end;

  TLineReader = class
    constructor Create(Source: TLineReaderSource; BufferSize: Integer);
    procedure Read;
  private
    Source: TLineReaderSource;
    Buffer: array of byte;
    BufferSize: Integer;
    Size: Integer;
  public
    OnLineRead: procedure (const Line: String) of object;
  end;

implementation

uses
  _Trace;

constructor TLineReader.Create(Source: TLineReaderSource; BufferSize: Integer);
begin
  Self.Source := Source;
  Self.BufferSize := BufferSize;
  SetLength(Buffer, BufferSize + 1);

  OnLineRead := nil;

  Size := 0;
end;

procedure TLineReader.Read;
var
  CRPos, Count, Start: Integer;

begin
  Trace(Format('Receive Size: %d  Left: %d', [Size, BufferSize - Size]),
    'linebuffer');
  Count := Source.Read(Buffer[Size], BufferSize - Size);

  Trace(Format('Count: %d', [Count]), 'linebuffer');

  if (Count < 1) then
    Exit;

  Buffer[Size + Count] := 0;
  Trace('DATA: |' + StrPas(@Buffer[Size]) + '|', 'linebuffer');
  Trace(StrPas(@Buffer[Size]), 'raw', False);

  if (Buffer[0] <> $a) then
    Start := 0
  else
    Start := 1;

  CRPos := Size; // was Start

  inc(Size, Count);

  Trace(Format('Read: %d  Start: %d  Size: %d', [Count, Start, Size]),
    'linebuffer');

  repeat
    while (CRPos < Size) and (Buffer[CRPos] <> $d) do
      inc(CRPos);

    Trace(Format('Scanned CRPos: %d  Start: %d  Size: %d', [CRPos, Start, Size]),
      'linebuffer');

    if (Buffer[CRPos] = $d) then
      begin
        Trace(Format('Found CR at pos: %d', [CRPos]), 'linebuffer');
        if Assigned(OnLineRead) then
          begin
            Buffer[CRPos] := 0;
            Trace('OnLineRead: |' + StrPas(@Buffer[Start]) + '|', 'linebuffer');
            Trace(StrPas(@Buffer[Start]), 'parsed');
            OnLineRead(StrPas(@Buffer[Start]));
          end;

        inc(CRPos, 2);

        if (CRPos < BufferSize) then
          begin
            Start := CRPos;

            Trace(Format('New Start: %d', [Start]), 'linebuffer');
          end
        else
          begin
            Trace('End of buffer', 'linebuffer');
            Size := 0;
            break;
          end;
      end
    else if (Start = 0) and (Size = BufferSize) then
      begin
        Trace('End of buffer 2', 'linebuffer');
        Buffer[BufferSize] := 0;
        Trace('OnLineRead: |' + StrPas(@Buffer[Start]) + '|', 'linebuffer');
        Trace(StrPas(@Buffer[Start]), 'parsed');
        OnLineRead(StrPas(@Buffer[Start]));
        Size := 0;
        break;
      end
    else
      begin
        if (Start > 0) then
          begin
            dec(Size, Start);

            Trace(Format('Size: %d', [Size]), 'linebuffer');

            if (Size > 0) then
              begin
                Trace(Format('Blitting from: %d  Count: %d', [Start, Size]),
                  'linebuffer');
                StrMove(@Buffer[0], @Buffer[Start], Size);
                Trace(Format('Blitted from: %d  Count: %d', [Start, Size]),
                  'linebuffer');
              end;
          end;

        break;
      end;
  until False;
  Trace('Leave Read()', 'linebuffer');
end;

end.

