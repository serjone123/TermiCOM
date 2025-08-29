unit ComPort;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Class:       TComPort                                                     //
//                                                                            //
//  Description: Asynchronous (overlapped) COM port                           //
//  Version:     1.0                                                          //
//  Date:        10-Jun-2003                                                  //
//  Author:      Igor Pavlov, pavlov_igor@nm.ru                               //
//                                                                            //
//  Copyright:   (c) 2003, Igor Pavlov                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//   Serjone: Когда-то давно брал модуль ком порта товарища выше              //
//            поэтому оставляю его копирайт, хоть код и претерпел             //
//            значительные изменения                                          //
//                                                                            //
//            Август 2025                                                     //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
interface

uses
  SysUtils, Windows, Variants, Classes
, CircularBuffer
, System.Generics.Collections
  ;

type
  EComPortError = class(Exception);

  TBaudRate = (br110 = CBR_110,
               br300 = CBR_300,
               br600 = CBR_600,
               br1200 = CBR_1200,
               br2400 = CBR_2400,
               br4800 = CBR_4800,
               br9600 = CBR_9600,
               br14400 = CBR_14400,
               br19200 = CBR_19200,
               br38400 = CBR_38400,
               br56000 = CBR_56000,
               br57600 = CBR_57600,
               br115200 = CBR_115200,
               br128000 = CBR_128000,
               br256000 = CBR_256000);

  TComPort = class;

  {Reading thread}
  TReadThread = class(TThread)
  private
    FBuf: array[0..$FFFF] of Byte;
    FComPort: TComPort;
    FOverRead: TOverlapped;
    FRead: DWORD;
    procedure DoRead;
  protected
    procedure Execute; override;
  public
    constructor Create(ComPort: TComPort);
    destructor Destroy; override;
  end;

  {Reading event}
  TReadEventData = procedure(Sender: TObject; ReadBytes: array of Byte) of object;
  TOpenPortEvent = procedure(APortName: string) of object;
  TClosePortEvent = procedure(APortName: string) of object;

  {Com port class}
  TComPort = class
  private
    FOverWrite: TOverlapped;
    FPort: THandle;
    FPortName: String;
    FReadEvent: TNotifyEvent;
    FReadEventData: TReadEventData;
    FOpenPortEvent: TOpenPortEvent;
    FClosePortEvent: TClosePortEvent;
    FReadThread: TReadThread;
    fDictionary : TDictionary<string,TProc>;
    class function CheckPort(APortName:string):boolean;
  public
    //constructor Create(PortNumber: Cardinal; BaudRate: TBaudRate); overload;
    constructor Create(APortName: string; ABaudRate: DWORD; AParity: Byte = NOPARITY; AByteSize: Byte = 8; AStopBits: Byte = ONESTOPBIT); overload;
    destructor Destroy; override;
    procedure Write(WriteBytes: array of Byte);
    class function GetPorts:string;
  published
    //property OnRead: TReadEvent read FReadEvent write FReadEvent;
    property OnRead: TNotifyEvent read FReadEvent write FReadEvent;
    property OnOpen: TOpenPortEvent read FOpenPortEvent write FOpenPortEvent;
    property OnClose: TClosePortEvent read FClosePortEvent write FClosePortEvent;
    property PortName: String read FPortName;
  end;

implementation

constructor TReadThread.Create(ComPort: TComPort);
begin
  FComPort := ComPort;
  ZeroMemory(@FOverRead, SizeOf(FOverRead));

  {Event}
  FOverRead.hEvent := CreateEvent(nil, True, False, nil);

  if FOverRead.hEvent = Null then
    raise EComPortError.Create('Error creating read event');

  inherited Create(False);
end;

destructor TReadThread.Destroy;
begin
  CloseHandle(FOverRead.hEvent);

  inherited Destroy;
end;

procedure TReadThread.Execute;
var
  ComStat: TComStat;
  dwMask, dwError: DWORD;
begin
  FreeOnTerminate := True;

  while not Terminated do
  begin
    if not WaitCommEvent(FComPort.FPort, dwMask, @FOverRead) then
    begin
      if GetLastError = ERROR_IO_PENDING then
        WaitForSingleObject(FOverRead.hEvent, INFINITE)
      else
        raise EComPortError.Create('Error waiting port ' + FComPort.PortName
          + ' event');
    end;

    if not ClearCommError(FComPort.FPort, dwError, @ComStat) then
      raise EComPortError.Create('Error clearing port ' + FComPort.PortName);

    FRead := ComStat.cbInQue;

    if FRead > 0 then
    begin
      if not ReadFile(FComPort.FPort, FBuf, FRead, FRead, @FOverRead) then
        raise EComPortError.Create('Error reading port ' + FComPort.PortName);

      //Synchronize(DoRead);
      CB.WriteData(FBuf, FRead );
      Synchronize(DoRead);
    end;
  end; {while}
end;

procedure TReadThread.DoRead;
var
  arrBytes: array of Byte;
  i: Integer;
begin
  if Assigned(FComPort.FReadEvent) then
    begin
      FComPort.FReadEvent(Self);
    end;

end;

constructor TComPort.Create(APortName: string; ABaudRate: DWORD; AParity,
  AByteSize, AStopBits: Byte);
var
  Dcb: TDcb;
begin
  inherited Create;

  ZeroMemory(@FOverWrite, SizeOf(FOverWrite));

  var portnum:= APortName.Replace('COM', '').ToInteger;
     case  portnum of
       1..10:  FPortName := APortName;
       else    FPortName :=('\\.\' + APortName);
     end;
//  FPortName := APortName;

  {Open port}
  FPort := CreateFile(PChar(PortName),
    GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);

  if FPort = INVALID_HANDLE_VALUE then
    raise EComPortError.Create('Error opening port ' + PortName);

  try
    {Set port state}
    if not GetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error setting port ' + PortName + ' state');

    Dcb.BaudRate := ABaudRate;
    Dcb.Parity := AParity;
    Dcb.ByteSize := AByteSize;
    Dcb.StopBits := AStopBits;

    if not SetCommState(FPort, Dcb) then
      raise EComPortError.Create('Error setting port ' + PortName + ' state');

    {Purge port}
    if not PurgeComm(FPort, PURGE_TXCLEAR or PURGE_RXCLEAR) then
      raise EComPortError.Create('Error purging port ' + PortName);

    {Set mask}
    if not SetCommMask(FPort, EV_RXCHAR) then
      raise EComPortError.Create('Error setting port ' + PortName + ' mask');

    FOverWrite.hEvent := CreateEvent(nil, True, False, nil);

    if FOverWrite.hEvent = Null then
      raise EComPortError.Create('Error creating write event');

    {Reading thread}
    FReadThread := TReadThread.Create(Self);
  except
    CloseHandle(FOverWrite.hEvent);
    CloseHandle(FPort);
    raise;
  end;
end;

destructor TComPort.Destroy;
begin
  if Assigned(FReadThread) then
    FReadThread.Terminate;
    
  CloseHandle(FOverWrite.hEvent);
  CloseHandle(FPort);

    if Assigned(FClosePortEvent) then
      FClosePortEvent(self.FPortName)  ;
  inherited Destroy;
end;

class function TComPort.GetPorts: string;
var
  vPortName: string;
  i: integer;
  PortAvaible: boolean ;
begin
 // сканируем доступные порты
   for i:= 1 to 64 do
   begin
     vPortName:= ('COM' + inttostr(i)) ;
     case  i of
       1..10:  PortAvaible:= CheckPort(vPortName);
       else    PortAvaible:= CheckPort('\\.\' + vPortName);
     end;

     if PortAvaible then result:= result+vPortName+sLineBreak;

   end;
end;

class function TComPort.CheckPort(APortName: string): boolean;
var
  CommH : hFile;
begin
  result := true;

  CommH := CreateFile(PWideChar(APortName), GENERIC_READ or GENERIC_WRITE,
                0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if (CommH = INVALID_HANDLE_VALUE) then
  begin
    result:=false;
  end ;
 CloseHandle(CommH);
end;

procedure TComPort.Write(WriteBytes: array of Byte);
var
  dwWrite: DWORD;
begin
  if  (not WriteFile(FPort, WriteBytes, SizeOf(WriteBytes), dwWrite, @FOverWrite))
  and (GetLastError <> ERROR_IO_PENDING) then
    raise EComPortError.Create('Error writing port ' + PortName);
end;

end.
