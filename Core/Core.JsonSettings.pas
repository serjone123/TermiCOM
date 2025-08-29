unit Core.JsonSettings;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  ������ ���������� �������� � JSON ����                                    //
//                                                                            //
//  ����������� ��������� ������� ���������� DeepSeek � �������� � ������     //
//  TermiCOM, ������� ���� �� �������� ���������                              //
//                                                                            //
//  Date:        ���-2025                                                     //
//  ������ �����: ��������� ������, serj.temp@mail.ru, @Serjone123            //
//                                                                            //
//  Copyright:   (c) 2025, ��������� ������                                   //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils;

type
  TJsonSettings = class
  private
    FFileName: string;
    FJsonObject: TJSONObject;
    procedure LoadFromFile;
    procedure SaveToFile;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    // ������ ��� ������ � �����������
    procedure SetValue(const AName: string; AValue: Integer); overload;
    procedure SetValue(const AName: string; AValue: Boolean); overload;
    procedure SetValue(const AName: string; const AValue: string); overload;
    procedure SetValue(const AName: string; AValue: Double); overload;

    function GetValue(const AName: string; Default: Integer): Integer; overload;
    function GetValue(const AName: string; Default: Boolean): Boolean; overload;
    function GetValue(const AName: string; const Default: string): string; overload;
    function GetValue(const AName: string; Default: Double): Double; overload;

    // �������������� ������
    procedure DeleteValue(const AName: string);
    function ValueExists(const AName: string): Boolean;
    procedure Clear;
  end;

implementation

constructor TJsonSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FJsonObject := TJSONObject.Create;
  LoadFromFile;
end;

destructor TJsonSettings.Destroy;
begin
  SaveToFile;
  FJsonObject.Free;
  inherited;
end;

procedure TJsonSettings.LoadFromFile;
var
  JsonText: string;
  JsonValue: TJSONValue;
begin
  if FileExists(FFileName) then
  begin
    JsonText := TFile.ReadAllText(FFileName, TEncoding.UTF8);
    JsonValue := TJSONObject.ParseJSONValue(JsonText);
    try
      if Assigned(JsonValue) and (JsonValue is TJSONObject) then
      begin
        FJsonObject.Free;
        FJsonObject := TJSONObject(JsonValue.Clone as TJSONObject);
      end;
    finally
      JsonValue.Free;
    end;
  end;
end;

procedure TJsonSettings.SaveToFile;
var
  JsonText: string;
begin
  JsonText := FJsonObject.Format(2); // �������������� � ���������
  TFile.WriteAllText(FFileName, JsonText, TEncoding.UTF8);
end;

// ������ ��� ��������� ��������
procedure TJsonSettings.SetValue(const AName: string; AValue: Integer);
begin
  FJsonObject.RemovePair(AName).Free;
  FJsonObject.AddPair(AName, TJSONNumber.Create(AValue));
end;

procedure TJsonSettings.SetValue(const AName: string; AValue: Boolean);
begin
  FJsonObject.RemovePair(AName).Free;
  FJsonObject.AddPair(AName, TJSONBool.Create(AValue));
end;

procedure TJsonSettings.SetValue(const AName: string; const AValue: string);
begin
  FJsonObject.RemovePair(AName).Free;
  FJsonObject.AddPair(AName, AValue);
end;

procedure TJsonSettings.SetValue(const AName: string; AValue: Double);
begin
  FJsonObject.RemovePair(AName).Free;
  FJsonObject.AddPair(AName, TJSONNumber.Create(AValue));
end;

// ������ ��� ��������� ��������
function TJsonSettings.GetValue(const AName: string; Default: Integer): Integer;
var
  Pair: TJSONPair;
begin
  Pair := FJsonObject.Get(AName);
  if Assigned(Pair) and (Pair.JsonValue is TJSONNumber) then
    Result := TJSONNumber(Pair.JsonValue).AsInt
  else
    Result := Default;
end;

function TJsonSettings.GetValue(const AName: string; Default: Boolean): Boolean;
var
  Pair: TJSONPair;
begin
  Pair := FJsonObject.Get(AName);
  if Assigned(Pair) and (Pair.JsonValue is TJSONBool) then
    Result := TJSONBool(Pair.JsonValue).AsBoolean
  else
    Result := Default;
end;

function TJsonSettings.GetValue(const AName: string; const Default: string): string;
var
  Pair: TJSONPair;
begin
  Pair := FJsonObject.Get(AName);
  if Assigned(Pair) then
    Result := Pair.JsonValue.Value
  else
    Result := Default;
end;

function TJsonSettings.GetValue(const AName: string; Default: Double): Double;
var
  Pair: TJSONPair;
begin
  Pair := FJsonObject.Get(AName);
  if Assigned(Pair) and (Pair.JsonValue is TJSONNumber) then
    Result := TJSONNumber(Pair.JsonValue).AsDouble
  else
    Result := Default;
end;

// �������������� ������
procedure TJsonSettings.DeleteValue(const AName: string);
begin
  FJsonObject.RemovePair(AName).Free;
end;

function TJsonSettings.ValueExists(const AName: string): Boolean;
begin
  Result := FJsonObject.Get(AName) <> nil;
end;

procedure TJsonSettings.Clear;
begin
  FJsonObject.Free;
  FJsonObject := TJSONObject.Create;
end;

end.
