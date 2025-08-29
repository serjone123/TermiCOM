unit uTCmain;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Программа TermiCOM                                                        //
//                                                                            //
//  Description: Предназначена для работы с ком портом                        //
//  Version:     1.0                                                          //
//  Date:        30-Авг-2025                                                  //
//  Author:      Асылгарев Сергей, serj.temp@mail.ru, @Serjone123             //
//                                                                            //
//  Copyright:   (c) 2025, Асылгарев Сергей                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.ComboEdit, FMX.ListBox,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls ,
  Windows, ComPort, FMX.EditBox, FMX.NumberBox
, System.Diagnostics
, CircularBuffer
, Core.JsonSettings ,
FMX.Menus, FMX.Layouts, FMX.TabControl, FMX.Ani, FMX.Objects
  ;

type
  TfmTermiCOM = class(TForm)
    TabControl: TTabControl;
    tiTerminal: TTabItem;
    Memo1: TMemo;
    tmSendChar: TTimer;
    pmPorts: TPopupMenu;
    cbSendChar: TCheckBox;
    lySendPn: TLayout;
    ceSendStr: TComboEdit;
    tmUpdateCOMData: TTimer;
    cbSendEnt: TCheckBox;
    btClearBuffer: TButton;
    btOpenPort: TButton;
    cbSelectComPort: TComboBox;
    Layout1: TLayout;
    btM3: TButton;
    btM2: TButton;
    tiSettings: TTabItem;
    TabItem2: TTabItem;
    btSendHex: TButton;
    edHexStr: TEdit;
    tbMax: TTrackBar;
    tbMin: TTrackBar;
    ProgressBar1: TProgressBar;
    cbDataAsTxt: TCheckBox;
    cbShowProgress: TCheckBox;
    cbOutToLog: TCheckBox;
    Button3: TButton;
    cbNewLine: TCheckBox;
    cbProcessing: TCheckBox;
    Button2: TButton;
    Label1: TLabel;
    btM4: TButton;
    btM7: TButton;
    btM6: TButton;
    btM5: TButton;
    btM1: TButton;
    gbMacross: TGroupBox;
    lbMacross: TListBox;
    edMacross: TEdit;
    ColorAnimation1: TColorAnimation;
    btIpToScanUpdate: TButton;
    lbiM1: TListBoxItem;
    lbiM2: TListBoxItem;
    lbiM3: TListBoxItem;
    lbiM4: TListBoxItem;
    lbiM5: TListBoxItem;
    lbiM6: TListBoxItem;
    lbiM7: TListBoxItem;
    lbiM8: TListBoxItem;
    cbBaud: TComboEdit;
    gbBaud: TGroupBox;
    rb9600: TRadioButton;
    rb115200: TRadioButton;
    rbCustom: TRadioButton;
    nbCustomBaud: TNumberBox;
    StatusBar1: TStatusBar;
    lbStatus: TLabel;
    btM8: TButton;
    btM11: TButton;
    Layout2: TLayout;
    Rectangle1: TRectangle;
    rtbg1: TRectangle;
    Rectangle2: TRectangle;
    btM9: TButton;
    btM10: TButton;
    lbiM9: TListBoxItem;
    lbiM10: TListBoxItem;
    btM12: TButton;
    lbiM11: TListBoxItem;
    lbiM12: TListBoxItem;
    btSend: TButton;
    nbCharToSend: TNumberBox;
    lbEvery: TLabel;
    nbRepeatTime: TNumberBox;
    cbScroll: TCheckBox;
    cbHEX: TCheckBox;
    procedure cbSelectComPortEnter(Sender: TObject);
    procedure btOpenPortClick(Sender: TObject);
    procedure cbSelectComPortClosePopup(Sender: TObject);
    procedure btSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btClearBufferClick(Sender: TObject);
    procedure btCtrlCClick(Sender: TObject);
    procedure btIpToScanUpdateClick(Sender: TObject);
    procedure tbMinChange(Sender: TObject);
    procedure tbMaxChange(Sender: TObject);
    procedure btSendHexClick(Sender: TObject);
    procedure btM2Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure cbSendCharChange(Sender: TObject);
    procedure ceSendStrKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar;
        Shift: TShiftState);
    procedure lbMacrossItemClick(const Sender: TCustomListBox; const Item:
        TListBoxItem);
    procedure Memo1ChangeTracking(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
        Shift: TShiftState);
    procedure tmSendCharTimer(Sender: TObject);
    procedure tmUpdateCOMDataTimer(Sender: TObject);
  private
    function selectBaud:DWORD;
    //procedure OnRead(Sender: TObject; ReadBytes: array of Byte);
    procedure OnReadEvent(Sender: TObject) ;
    procedure OnClose(APortName: string) ;
    procedure SendStr(strWrite: string);
    procedure SendBytes(Bytes: TBytes);
  public
    { Public declarations }
  end;

var
  fmTermiCOM: TfmTermiCOM;
  GComPort : TComPort;
  SS:TStringStream  ;
  isChanged: boolean;
  Settings: TJsonSettings;
implementation

{$R *.fmx}

procedure TfmTermiCOM.btSendClick(Sender: TObject);
begin
  SendStr(ceSendStr.Text);
  //ceSendStr.Items.Insert(0, ceSendStr.Text)  ;
  ceSendStr.Items.Add(ceSendStr.Text)  ;
  ceSendStr.Text:='';
end;

procedure TfmTermiCOM.btSendHexClick(Sender: TObject);
var
  arrBytes: array of Byte;
  i, vHexPos: Integer;
  sHexByte: string;
begin
  vHexPos:=0;
  var sInputStr :=  edHexStr.Text ;
  var len:= (round(sInputStr.Length/2));
  SetLength(arrBytes, len);
  for I := 1 to edHexStr.Text.Length do
    begin
      case I mod 2 of
        1: sHexByte:= '$'+sInputStr[i];
        0:
          begin
            sHexByte:= sHexByte+sInputStr[i];
            //Memo1.Lines.Add(sHexByte)  ;
            arrBytes[vHexPos]:= strtoint(sHexByte);
            inc(vHexPos);
          end;
      end;
    end;
  GComPort.Write(arrBytes);
end;

procedure TfmTermiCOM.btClearBufferClick(Sender: TObject);
begin
  SS.Clear;
  memo1.Lines.Clear;
end;

procedure TfmTermiCOM.btCtrlCClick(Sender: TObject);
begin
  SendBytes([03]);
end;

procedure TfmTermiCOM.btIpToScanUpdateClick(Sender: TObject);
begin
  if lbMacross.ItemIndex=-1 then exit;
  lbMacross.ListItems[lbMacross.ItemIndex].Text:=edMacross.Text;
  var btn := (findcomponent('btM'+inttostr(lbMacross.ItemIndex+1)) as TButton) ;
  btn.Text := edMacross.Text ;
  btn.Hint := edMacross.Text ;
  btn.ShowHint:= true ;
end;

procedure TfmTermiCOM.lbMacrossItemClick(const Sender: TCustomListBox; const
    Item: TListBoxItem);
begin
  edMacross.Text := lbMacross.ListItems[lbMacross.ItemIndex].Text
end;

procedure TfmTermiCOM.btOpenPortClick(Sender: TObject);
var
  PortName: string;
begin
  if cbSelectComPort.ItemIndex<>-1 then
    PortName:= cbSelectComPort.Items[cbSelectComPort.ItemIndex]
  else
    begin
      memo1.Lines.Add('Не выбран порт') ;
      exit;
    end;

  if assigned(GComPort) then
    begin
      //GComPort.Destroy;

      FreeAndNil(GComPort) ;
      btOpenPort.Text:= 'Открыть';
      exit;
    end;

  try
    GComPort:=TComPort.Create(PortName, selectBaud) ;
    GComPort.OnRead:= OnReadEvent;
    GComPort.OnClose:= OnClose;
    btOpenPort.Text:= 'Закрыть';
  except
    on e: Exception do
      memo1.Lines.Add(e.ToString)
    end;
 lbStatus.Text:= 'Подключен ' + PortName+ ' На скорости '+ selectBaud.ToString;
 // GComPort.

end;

procedure TfmTermiCOM.btM2Click(Sender: TObject);
var
  b: TButton;
begin
  b:= Sender as TButton;
  SendStr(b.Text);
end;

procedure TfmTermiCOM.Button2Click(Sender: TObject);
var
  SSt:TStringStream ;
  SW: TStopwatch;
begin
  SW:=TStopwatch.StartNew;
  SW.Reset;
  SW.Start;
//  SSt:=TStringStream.Create  ;
//  SSt.LoadFromFile('V:\HARD\soft\IMSProg\IMSProg_programmer\build\CMakeFiles\IMSProg_autogen.dir\ParseCache.txt') ;
//  //Memo1.BeginUpdate;
//  Memo1.Text:= SSt.DataString;
//  //memo1.EndUpdate;
//  SSt.Free;
  for var i := 0 to 61 do

  cb.WriteData(chr(random(60)+30)) ;
  cb.WriteData(sLineBreak) ;
  Memo1.Text:= cb.GetAsString  ;

  SW.Stop;
  Label1.Text := SW.Elapsed.TotalMilliseconds.ToString    ;

end;

procedure TfmTermiCOM.Button3Click(Sender: TObject);
var
  miPool  : TMenuItem ;
begin
  for var I := 0 to pmPorts.ItemsCount-1  do
    begin
      pmPorts.Items[0].Free ;
    end;
  for var s in TComPort.GetPorts.Split([sLineBreak])  do
  begin
    if s='' then continue;

    miPool := TMenuItem.Create(pmPorts)  ;
    miPool.Parent:= pmPorts;
    miPool.Text:=s ;
    //miPool.OnClick:= selectpool;
  end;
  //pmPorts.Popup(Screen.MousePos.x, Screen.MousePos.y) ;
  var x:= self.Left+ Button3.Position.X ;
  var y:= self.Top+ Button3.Position.y ;
  pmPorts.Popup(x, y) ;
end;

procedure TfmTermiCOM.cbSelectComPortClosePopup(Sender: TObject);
begin
  if (cbSelectComPort.ItemIndex=-1) and (cbSelectComPort.Count>0) then cbSelectComPort.ItemIndex:=0;

end;

procedure TfmTermiCOM.cbSelectComPortEnter(Sender: TObject);
begin
  cbSelectComPort.Clear;
  cbSelectComPort.Items.Text:= TComPort.GetPorts;
end;

procedure TfmTermiCOM.cbSendCharChange(Sender: TObject);
begin
  tmSendChar.Enabled := cbSendChar.IsChecked
end;

procedure TfmTermiCOM.FormCreate(Sender: TObject);
var
  i: integer;
  sComPort: string; //Порт при запуске программы
begin
  TabControl.TabIndex:=0;
  SS:=TStringStream.Create  ;

  isChanged:= false;

  CB:= TCircularBuffer.Create(1048576, 256);
  TabItem2.Visible:= false;

  cbSelectComPort.Items.Text:= TComPort.GetPorts;
  cbSelectComPortClosePopup(self) ;

  Settings := TJsonSettings.Create('settings.json');

  for I := 1 to 12 do
   begin
     var lbi := (findcomponent('lbiM'+inttostr(i)) as TListBoxItem) ;
     var btn := (findcomponent('btM'+inttostr(i)) as TButton) ;
     if (lbi<> nil) and (btn<> nil) then
      begin
        lbi.Text:= Settings.GetValue('M'+i.ToString, '');
        btn.Text:= lbi.Text ;
        btn.Hint:= lbi.Text ;
        btn.ShowHint:= true ;
      end;
   end;
   cbBaud.Text:= Settings.GetValue('Baud', '115200');
   sComPort:= Settings.GetValue('ComPort', '');
   if (sComPort<>'') and (cbSelectComPort.Items.IndexOf(sComPort)<>-1)  then
     cbSelectComPort.ItemIndex:= cbSelectComPort.Items.IndexOf(sComPort);

end;

procedure TfmTermiCOM.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  SS.Free ;
  CB.Free ;

  for I := 1 to 8 do
   begin
     var lbi := (findcomponent('lbiM'+inttostr(i)) as TListBoxItem) ;
     if lbi<> nil then
       Settings.SetValue('M'+i.ToString, lbi.Text);
   end;
   Settings.SetValue('Baud', cbBaud.Text);
   Settings.SetValue('ComPort', cbSelectComPort.Text);

  Settings.Free ;
end;

procedure TfmTermiCOM.ceSendStrKeyUp(Sender: TObject; var Key: Word; var
    KeyChar: WideChar; Shift: TShiftState);
begin
  case Key of
    $0D:
      begin
        btSendClick(self);
      end;
    $25:
      begin

      end;
    $26:
      begin
        ceSendStr.ItemIndex:= ceSendStr.ItemIndex+1;

      end;
    $27:
      begin

      end;
    $28:
      begin
        ceSendStr.ItemIndex:= ceSendStr.ItemIndex-1;

      end;
    $2E:   //DEL
      begin
//        fCMD := fCMD.Remove(length(fCMD)-fCurPos, 1) ;
//        dec(fCurPos);
      end ;
    8 :  // Backspace
      begin

      end
  end;

  // Ctrl+C
  if (Shift = [ssCtrl]) and (Key=67) then SendBytes([03]);

  // Ctrl+X
  if (Shift = [ssCtrl]) and (Key=88) then SendBytes([$18]);
  // Ctrl+Z
  if (Shift = [ssCtrl]) and (Key=90) then SendBytes([$1A]);
  // Ctrl+V
  if (Shift = [ssCtrl]) and (Key=86) then SendBytes([$16]);

end;

procedure TfmTermiCOM.Memo1ChangeTracking(Sender: TObject);
begin
   lbStatus.text:= format('x=%f, y= %f', [
   memo1.ViewportPosition.X,
   memo1.ViewportPosition.Y
                                         ]);

end;

procedure TfmTermiCOM.Memo1KeyDown(Sender: TObject; var Key: Word; var KeyChar:
    WideChar; Shift: TShiftState);
begin
  ceSendStr.SetFocus;
  ceSendStr.Text:= ceSendStr.Text+ KeyChar;
  ceSendStr.GoToTextEnd;
end;

procedure TfmTermiCOM.OnClose(APortName: string);
begin
  //memo1.Lines.Add(APortName +' порт закрыт') ;
  lbStatus.Text:= APortName +' порт закрыт'
end;



procedure TfmTermiCOM.OnReadEvent(Sender: TObject);
begin
  //memo1.Text:= cb.GetAsString;
    isChanged:= true;
end;



function TfmTermiCOM.selectBaud: DWORD;
var
  BaudRate:Dword;
begin
  result:= 115200;
  try
    result:=cbBaud.Text.ToInteger;
  except
    on e: Exception do
      lbStatus.Text:= 'Ошибка выбора скорости порта: '+cbBaud.Text;
  end;

end;

procedure TfmTermiCOM.SendBytes(Bytes: TBytes);
begin
  if assigned(GComPort) then GComPort.Write(Bytes);
end;

procedure TfmTermiCOM.SendStr(strWrite: string);
var
  arrBytes: array of Byte;
  i: Integer;
begin
//  if GFlagOpen = False then // проверяем, открыт ли порт
//    OpenPort(strtoint(edtPort.Text)); // если нет, то открываем
  if assigned(GComPort) then
  begin
    var len:= Length(strWrite);
    SetLength(arrBytes, len);

    for i := Low(arrBytes) to High(arrBytes) do
      arrBytes[i] := Ord(strWrite[i + 1]);
    if cbSendEnt.IsChecked then arrBytes:=arrBytes+[10] ;
    GComPort.Write(arrBytes);
    arrBytes := nil;
  end;
end;

procedure TfmTermiCOM.tbMaxChange(Sender: TObject);
begin
  ProgressBar1.Max:= tbMax.Value;
end;

procedure TfmTermiCOM.tbMinChange(Sender: TObject);
begin
  ProgressBar1.Min:= tbMin.Value;
end;

procedure TfmTermiCOM.tmSendCharTimer(Sender: TObject);
begin
  SendStr(#13);
end;

procedure TfmTermiCOM.tmUpdateCOMDataTimer(Sender: TObject);
begin
  if isChanged then
    begin
      memo1.BeginUpdate;
      if cbHEX.IsChecked then
        memo1.Text := cb.GetAsHexStr
      else
        memo1.Text:= cb.GetAsString;
      if cbScroll.IsChecked then
        memo1.GoToTextEnd;
//      memo1.SelStart := Length(memo1.Text) - 1;
//      memo1.SelLength := 0;
      memo1.EndUpdate;
      isChanged:= false;
    end;

end;

end.
