object FormColumns: TFormColumns
  Left = 391
  Top = 206
  BorderStyle = bsDialog
  Caption = 'Columns'
  ClientHeight = 392
  ClientWidth = 388
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object ListView1: TListView
    Left = 24
    Top = 48
    Width = 265
    Height = 265
    Checkboxes = True
    Columns = <
      item
        Caption = 'Column'
      end
      item
        Caption = 'Width'
      end
      item
        Caption = 'Align'
      end
      item
        Caption = 'Type'
      end>
    TabOrder = 0
    ViewStyle = vsReport
  end
  object Edit1: TEdit
    Left = 96
    Top = 336
    Width = 57
    Height = 21
    TabOrder = 1
    Text = 'Edit1'
  end
  object ComboBox1: TComboBox
    Left = 160
    Top = 336
    Width = 65
    Height = 21
    ItemHeight = 13
    TabOrder = 2
    Text = 'ComboBox1'
  end
  object ComboBox2: TComboBox
    Left = 232
    Top = 336
    Width = 65
    Height = 21
    ItemHeight = 13
    TabOrder = 3
    Text = 'ComboBox2'
  end
  object Button1: TButton
    Left = 296
    Top = 144
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 4
  end
  object Button2: TButton
    Left = 296
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 5
  end
  object Button3: TButton
    Left = 296
    Top = 248
    Width = 75
    Height = 25
    Caption = 'Button3'
    TabOrder = 6
  end
  object Button4: TButton
    Left = 296
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Button4'
    TabOrder = 7
  end
  object Edit2: TEdit
    Left = 24
    Top = 336
    Width = 65
    Height = 21
    TabOrder = 8
    Text = 'Edit2'
  end
end
