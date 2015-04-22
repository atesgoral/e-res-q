object FormMsg: TFormMsg
  Left = 233
  Top = 166
  Width = 498
  Height = 403
  Caption = 'FormMsg'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 490
    Height = 41
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 0
  end
  object PageControl: TPageControl
    Left = 0
    Top = 41
    Width = 490
    Height = 328
    ActivePage = TabSheet2
    Align = alClient
    TabOrder = 1
    TabPosition = tpBottom
    object TabSheet2: TTabSheet
      Caption = 'View'
      ImageIndex = 1
      object TabControl1: TTabControl
        Left = 0
        Top = 0
        Width = 482
        Height = 302
        Align = alClient
        TabOrder = 0
        Tabs.Strings = (
          'HTML'
          'Text')
        TabIndex = 0
        object WebBrowser: TWebBrowser
          Left = 4
          Top = 24
          Width = 474
          Height = 274
          Align = alClient
          TabOrder = 0
          ControlData = {
            4C000000FD300000521C00000000000000000000000000000000000000000000
            000000004C000000000000000000000001000000E0D057007335CF11AE690800
            2B2E126208000000000000004C0000000114020000000000C000000000000046
            8000000000000000000000000000000000000000000000000000000000000000
            00000000000000000100000000000000000000000000000000000000}
        end
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Attachments'
      ImageIndex = 2
      object ListView1: TListView
        Left = 0
        Top = 0
        Width = 482
        Height = 309
        Align = alClient
        Columns = <>
        TabOrder = 0
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Headers'
      ImageIndex = 3
      object ListView: TListView
        Left = 0
        Top = 0
        Width = 482
        Height = 302
        Align = alClient
        Columns = <
          item
            Caption = 'Skip'
            Width = 0
          end
          item
            Alignment = taRightJustify
            AutoSize = True
            Caption = 'Header'
          end
          item
            AutoSize = True
            Caption = 'Value'
          end>
        GridLines = True
        MultiSelect = True
        ReadOnly = True
        RowSelect = True
        SortType = stText
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Raw'
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 482
        Height = 302
        Align = alClient
        Lines.Strings = (
          'Memo1')
        TabOrder = 0
      end
    end
  end
end
