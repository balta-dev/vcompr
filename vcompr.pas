{$mode objfpc}{$H+}
program CompressVideo;

uses
  SysUtils, Process, Classes;

function RunCommandAndGetOutput(const Cmd: string): string;
var
  AProcess: TProcess;
  OutputLines: TStringList;
begin
  AProcess := TProcess.Create(nil);
  OutputLines := TStringList.Create;
  try
    {$IFDEF Windows}
    AProcess.Executable := 'cmd.exe';
    AProcess.Parameters.Add('/C');
    {$ELSE}
    AProcess.Executable := '/bin/sh';
    AProcess.Parameters.Add('-c');
    {$ENDIF}
    AProcess.Parameters.Add(Cmd);
    AProcess.Options := [poUsePipes, poWaitOnExit];
    AProcess.Execute;

    OutputLines.LoadFromStream(AProcess.Output);
    Result := Trim(OutputLines.Text);
  finally
    OutputLines.Free;
    AProcess.Free;
  end;
end;

var
  InputFile, OutputFile: string;
  Percent: Integer;
  DurationStr, SizeStr: string;
  Duration: Double;
  SizeBytes, TargetSize: Int64;
  TargetBitrate: Int64;
  BaseName, Ext: string;
begin
  if ParamCount < 2 then
  begin
    Writeln('Uso: vcompr <porcentaje> <video.mp4>');
    Halt(1);
  end;

  InputFile := ParamStr(2);
  Percent := StrToInt(ParamStr(1));

  // Duración
  DurationStr := RunCommandAndGetOutput(
    'ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "' + InputFile + '"'
  );
  Duration := StrToFloat(DurationStr);

  // Tamaño
  SizeStr := RunCommandAndGetOutput(
    'ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 "' + InputFile + '"'
  );
  SizeBytes := StrToInt64(SizeStr);

  // Cálculos
  TargetSize := Round(SizeBytes * Percent / 100);
  TargetBitrate := Round((TargetSize * 8) / Duration / 1000); // kbps

  // Nombre salida
  BaseName := ChangeFileExt(InputFile, '');
  Ext := ExtractFileExt(InputFile);
  OutputFile := BaseName + '-' + IntToStr(Percent) + Ext;

  Writeln('Comprimiendo "', InputFile, '" al ', Percent, '%...');
  Writeln('Bitrate objetivo: ', TargetBitrate, ' kbps');
  Writeln('Salida: ', OutputFile);

  // Ejecutar ffmpeg
  RunCommandAndGetOutput(
    'ffmpeg -y -i "' + InputFile + '" -b:v ' + IntToStr(TargetBitrate) + 'k -b:a 128k "' + OutputFile + '"'
  );

  Writeln('Listo. Archivo generado: ', OutputFile);
end.

