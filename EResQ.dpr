program EResQ;

uses
  Forms,
  MainForm in 'MainForm.pas' {FormMain},
  Presets in 'Presets.pas',
  ColumnsForm in 'ColumnsForm.pas' {FormColumns},
  LineBuffer in 'LineBuffer.pas',
  StrUtilsX in 'StrUtilsX.pas',
  RegistryObject in 'RegistryObject.pas',
  MsgForm in 'MsgForm.pas' {FormMsg},
  ERQMessage in 'ERQMessage.pas',
  _Trace in '_Trace.pas',
  ERQParser in 'ERQParser.pas',
  ERQDummyParser in 'ERQDummyParser.pas',
  ERQConnection in 'ERQConnection.pas',
  ERQProtocol in 'ERQProtocol.pas',
  ERQReader in 'ERQReader.pas',
  ERQWriter in 'ERQWriter.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'E-Res-Q';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
