unit CircularBuffer;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Модуль кольцевого буфера.                                                 //
//                                                                            //
//  Практически полностью написан нейросетью DeepSeek и вставлен в проект     //
//  TermiCOM, особо не разбираясь как оно там работает.                      //
//                                                                            //
//  Date:        23-Авг-2025                                                  //
//  Промпт писал: Асылгарев Сергей, serj.temp@mail.ru, @Serjone123            //
//                                                                            //
//  Copyright:   (c) 2025, Асылгарев Сергей                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses
  SysUtils, Classes, math;

type
  TCircularBuffer = class
  private
    FStream: TStringStream;
    FBufferSize: Integer;
    FWritePosition: Integer;
    FTotalBytesWritten: Int64;
    FBlockSize: Integer;
    procedure SetBufferSize(Value: Integer);
    procedure SetBlockSize(Value: Integer);
    function GetAvailableSpace: Integer;
    function GetAvailableBlocks: Integer;
    function GetCount: Integer;
  public
    constructor Create(BufferSize: Integer; BlockSize: Integer);
    destructor Destroy; override;

    procedure WriteData(const Data: array of Byte; DataLength: Integer); overload;
    procedure WriteData(const Data: string); overload;
    function ReadData(var Data: array of Byte; var BytesRead: Integer): Boolean; overload;
    function ReadData(var Data: string; var BytesRead: Integer): Boolean; overload;
    function ReadBlock(var Data: array of Byte): Boolean; overload;
    function ReadBlock(var Data: string): Boolean; overload;
    procedure Clear;

    function GetAsString: string;
    function GetAsBytes : TBytes;
    function GetAsHexStr: string;
    function PeekData(StartPos: Integer; Length: Integer): string;

    property BufferSize: Integer read FBufferSize write SetBufferSize;
    property BlockSize: Integer read FBlockSize write SetBlockSize;
    property Count: Integer read GetCount;
    property AvailableSpace: Integer read GetAvailableSpace;
    property AvailableBlocks: Integer read GetAvailableBlocks;
    property AsString: string read GetAsString;
    property AsBytes: TBytes read GetAsBytes;
  end;
var
  CB: TCircularBuffer;

implementation

{ TCircularBuffer }

constructor TCircularBuffer.Create(BufferSize: Integer; BlockSize: Integer);
begin
  inherited Create;
  FStream := TStringStream.Create('', TEncoding.ANSI);
  SetBufferSize(BufferSize);
  SetBlockSize(BlockSize);
  FWritePosition := 0;
  FTotalBytesWritten := 0;
end;

destructor TCircularBuffer.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

procedure TCircularBuffer.SetBufferSize(Value: Integer);
begin
  if Value <= 0 then
    raise Exception.Create('Buffer size must be greater than 0');

  if FBufferSize <> Value then
  begin
    FBufferSize := Value;
    // Обрезаем поток до нового размера если нужно
    if FStream.Size > FBufferSize then
    begin
      FStream.Size := FBufferSize;
      FWritePosition := FWritePosition mod FBufferSize;
    end;
  end;
end;

procedure TCircularBuffer.SetBlockSize(Value: Integer);
begin
  if Value <= 0 then
    raise Exception.Create('Block size must be greater than 0');
  FBlockSize := Value;
end;

function TCircularBuffer.GetAvailableSpace: Integer;
begin
  Result := FBufferSize;
end;

function TCircularBuffer.GetAvailableBlocks: Integer;
begin
  if FBlockSize > 0 then
    Result := Count div FBlockSize
  else
    Result := 0;
end;

function TCircularBuffer.GetCount: Integer;
begin
  Result := Min(FBufferSize, FTotalBytesWritten);
end;

procedure TCircularBuffer.WriteData(const Data: array of Byte; DataLength: Integer);
var
  BytesToWrite, FirstPart, SecondPart: Integer;
  TempBytes: TBytes;
begin
  if DataLength <= 0 then
    Exit;


  // Преобразуем массив байт в временный массив для удобства
  SetLength(TempBytes, DataLength);
  Move(Data[0], TempBytes[0], DataLength);

  BytesToWrite := Min(DataLength, FBufferSize);

  if FWritePosition + BytesToWrite <= FBufferSize then
  begin
    // Запись помещается в конец буфера
    FStream.Position := FWritePosition;
    FStream.Write(TempBytes, BytesToWrite);
  end
  else
  begin
    // Запись переходит через конец буфера
    FirstPart := FBufferSize - FWritePosition;
    SecondPart := BytesToWrite - FirstPart;

    // Записываем первую часть в конец
    FStream.Position := FWritePosition;
    FStream.Write(TempBytes[0], FirstPart);

    // Записываем вторую часть в начало
    FStream.Position := 0;
    FStream.Write(TempBytes[FirstPart], SecondPart);
  end;

  FWritePosition := (FWritePosition + BytesToWrite) mod FBufferSize;
  Inc(FTotalBytesWritten, BytesToWrite);
end;

procedure TCircularBuffer.WriteData(const Data: string);
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.ANSI.GetBytes(Data);
  WriteData(Bytes, Length(Bytes));
end;

function TCircularBuffer.ReadData(var Data: array of Byte; var BytesRead: Integer): Boolean;
var
  StartPos, BytesToRead, FirstPart, SecondPart: Integer;
  TempBytes: TBytes;
begin
  Result := False;
  BytesRead := 0;

  if Count = 0 then
    Exit;

  // Определяем начальную позицию для чтения (самые старые данные)
  StartPos := (FWritePosition - Count + FBufferSize) mod FBufferSize;
  BytesToRead := Min(Length(Data), Count);

  SetLength(TempBytes, BytesToRead);

  if StartPos + BytesToRead <= FBufferSize then
  begin
    // Чтение из конца буфера
    FStream.Position := StartPos;
    BytesRead := FStream.Read(TempBytes[0], BytesToRead);
  end
  else
  begin
    // Чтение переходит через конец буфера
    FirstPart := FBufferSize - StartPos;
    SecondPart := BytesToRead - FirstPart;

    // Читаем первую часть из конца
    FStream.Position := StartPos;
    BytesRead := FStream.Read(TempBytes[0], FirstPart);

    // Читаем вторую часть из начала
    FStream.Position := 0;
    BytesRead := BytesRead + FStream.Read(TempBytes[FirstPart], SecondPart);
  end;

  Move(TempBytes[0], Data[0], BytesRead);
  Result := BytesRead > 0;
end;

function TCircularBuffer.ReadData(var Data: string; var BytesRead: Integer): Boolean;
var
  TempData: TBytes;
  MaxRead: Integer;
begin
  Result := False;
  BytesRead := 0;

  if Count = 0 then
    Exit;

  MaxRead := Min(Length(Data) * SizeOf(Char), Count);
  SetLength(TempData, MaxRead);

  Result := ReadData(TempData, BytesRead);
  if Result then
  begin
    Data := TEncoding.ANSI.GetString(TempData, 0, BytesRead);
  end;
end;

function TCircularBuffer.ReadBlock(var Data: array of Byte): Boolean;
var
  BytesRead: Integer;
begin
  BytesRead := Min(Length(Data), FBlockSize);
  Result := ReadData(Data, BytesRead);
end;

function TCircularBuffer.ReadBlock(var Data: string): Boolean;
var
  BytesRead: Integer;
  TempData: array of Byte;
begin
  SetLength(TempData, FBlockSize);
  Result := ReadBlock(TempData);
  if Result then
  begin
    Data := TEncoding.ANSI.GetString(TempData);
  end;
end;

procedure TCircularBuffer.Clear;
begin
  FStream.Size := 0;
  FStream.Size := FBufferSize;
  FWritePosition := 0;
  FTotalBytesWritten := 0;
end;

function TCircularBuffer.GetAsString: string;
var
  StartPos, BytesToRead, FirstPart, SecondPart: Integer;
  TempBytes: TBytes;
begin
  if Count = 0 then
    Exit('');

  StartPos := (FWritePosition - Count + FBufferSize) mod FBufferSize;
  BytesToRead := Count;

  SetLength(TempBytes, BytesToRead);

  if StartPos + BytesToRead <= FBufferSize then
  begin
    FStream.Position := StartPos;
    FStream.Read(TempBytes[0], BytesToRead);
  end
  else
  begin
    FirstPart := FBufferSize - StartPos;
    SecondPart := BytesToRead - FirstPart;

    FStream.Position := StartPos;
    FStream.Read(TempBytes[0], FirstPart);

    FStream.Position := 0;
    FStream.Read(TempBytes[FirstPart], SecondPart);
  end;

  Result := TEncoding.ANSI.GetString(TempBytes);
end;

function TCircularBuffer.GetAsBytes: TBytes;
var
  StartPos, BytesToRead, FirstPart, SecondPart: Integer;
begin
  if Count = 0 then
    Exit(nil);

  StartPos := (FWritePosition - Count + FBufferSize) mod FBufferSize;
  BytesToRead := Count;

  SetLength(Result, BytesToRead);

  if StartPos + BytesToRead <= FBufferSize then
  begin
    FStream.Position := StartPos;
    FStream.Read(Result[0], BytesToRead);
  end
  else
  begin
    FirstPart := FBufferSize - StartPos;
    SecondPart := BytesToRead - FirstPart;

    FStream.Position := StartPos;
    FStream.Read(Result[0], FirstPart);

    FStream.Position := 0;
    FStream.Read(Result[FirstPart], SecondPart);
  end;
end;

function TCircularBuffer.GetAsHexStr: string;
begin
  for var bt in GetAsBytes  do
    result:= result+ bt.ToHexString +' ';
end;

function TCircularBuffer.PeekData(StartPos: Integer; Length: Integer): string;
var
  ActualStart, BytesToRead, FirstPart, SecondPart: Integer;
  TempBytes: TBytes;
begin
  if (Count = 0) or (Length <= 0) then
    Exit('');

  // Корректируем начальную позицию относительно самых старых данных
  ActualStart := ((FWritePosition - Count + FBufferSize) mod FBufferSize + StartPos) mod FBufferSize;
  BytesToRead := Min(Length, Count - StartPos);

  if BytesToRead <= 0 then
    Exit('');

  SetLength(TempBytes, BytesToRead);

  if ActualStart + BytesToRead <= FBufferSize then
  begin
    FStream.Position := ActualStart;
    FStream.Read(TempBytes[0], BytesToRead);
  end
  else
  begin
    FirstPart := FBufferSize - ActualStart;
    SecondPart := BytesToRead - FirstPart;

    FStream.Position := ActualStart;
    FStream.Read(TempBytes[0], FirstPart);

    FStream.Position := 0;
    FStream.Read(TempBytes[FirstPart], SecondPart);
  end;

  Result := TEncoding.ANSI.GetString(TempBytes);
end;

end.
