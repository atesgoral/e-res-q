program EResQ;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  TextUtils in 'TextUtils.pas',
  Read in 'Read.pas' {FormRead},
  MIMEDecode in 'MIMEDecode.pas',
  DateTimeDecode in 'DateTimeDecode.pas',
  StrUtilsX in 'StrUtilsX.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'E-Res-Q';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
