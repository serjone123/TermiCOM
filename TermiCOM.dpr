program TermiCOM;

uses
  System.StartUpCopy,
  FMX.Forms,
  uTCmain in 'uTCmain.pas' {fmTermiCOM},
  ComPort in 'ComPort.pas',
  CircularBuffer in 'CircularBuffer.pas',
  Core.JsonSettings in 'Core\Core.JsonSettings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmTermiCOM, fmTermiCOM);
  Application.Run;
end.
