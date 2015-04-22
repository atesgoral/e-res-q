program EResQ;

uses
  Forms,
  Main in 'Main.pas' {FormMain},
  TextUtils in 'TextUtils.pas',
  Splash in 'Splash.pas' {FormSplash},
  Read in 'Read.pas' {FormRead};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'E-Res-Q';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormSplash, FormSplash);
  Application.Run;
end.
