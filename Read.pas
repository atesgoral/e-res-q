unit Read;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus;

type
  TFormRead = class(TForm)
    MemoMsg: TMemo;
    PopupMenu: TPopupMenu;
    FontDialog: TFontDialog;
    MenuItemFont: TMenuItem;
    MenuItemCopy: TMenuItem;
    procedure MenuItemFontClick(Sender: TObject);
    procedure MenuItemCopyClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
  public
  end;

implementation

{$R *.DFM}

uses
  Main;

procedure TFormRead.MenuItemFontClick(Sender: TObject);
begin
  if FontDialog.Execute then
    MemoMsg.Font:= FontDialog.Font;
end;

procedure TFormRead.MenuItemCopyClick(Sender: TObject);
begin
  if ( MemoMsg.SelLength = 0 ) then
    MemoMsg.SelectAll;
  MemoMsg.CopyToClipboard;
end;

procedure TFormRead.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ( Task = TSKParseRetr ) and  ( NewFormRead = Self )then
    Action:= caNone;
end;

end.
