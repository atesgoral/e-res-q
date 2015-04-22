unit _Trace;

interface

procedure Trace(const S: String; const Dest: String = 'trace';
  CRLF: Boolean = True);

implementation

uses
  SysUtils;
  
procedure Trace(const S: String; const Dest: String = 'trace';
  CRLF: Boolean = True);
var
  Filename: String;
  TF: TextFile;

begin
  Filename := 'C:\' + Dest + '.txt';

  AssignFile(TF, Filename);

  if (FileExists(Filename)) then
    Append(TF)
  else
    Rewrite(TF);

  if (CRLF) then
    WriteLn(TF, S)
  else
    Write(TF, S);

  Flush(TF);
  CloseFile(TF);
end;

end.
