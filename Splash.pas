unit Splash;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

type
  TFormSplash = class(TForm)
    TimerClose: TTimer;
    PanelBack: TPanel;
    ImageLogo1: TImage;
    ImageLogo2: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure TimerCloseTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormSplash: TFormSplash;

procedure ShowSplash;

implementation

uses Main;

{$R *.DFM}

procedure ShowSplash;

begin
  FormSplash.Show;
  FormSplash.TimerClose.Enabled:= True;
end;

procedure TFormSplash.TimerCloseTimer(Sender: TObject);

begin
  FormSplash.TimerClose.Enabled:= False;
  FormSplash.Destroy;
end;

procedure TFormSplash.FormCreate(Sender: TObject);
begin
  ShowSplash;
end;

end.
