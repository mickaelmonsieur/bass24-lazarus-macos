unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, BASS;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnOpen: TButton;
    btnPlayPause: TButton;
    btnStop: TButton;
    lbTime: TLabel;
    OpenDialog1: TOpenDialog;
    tmTimer: TTimer;
    tbSeek: TTrackBar;
    procedure btnOpenClick(Sender: TObject);
    procedure btnPlayPauseClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tbSeekChange(Sender: TObject);
    procedure tmTimerTimer(Sender: TObject);
  private
    FSeekBarChanging: Boolean;
    FStreamHandle: HSTREAM;
    procedure FreeStream;
    procedure ShowBassErrorMessage(const AInvoker: string);
    procedure UpdateControlsState;
    procedure UpdateTrackPosition;
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FreeStream;
    FStreamHandle := BASS_StreamCreateFile(False,
      PWideChar(WideString(OpenDialog1.FileName)), 0, 0, BASS_UNICODE or BASS_STREAM_PRESCAN);
    if FStreamHandle = 0 then
      ShowBassErrorMessage('BASS_StreamCreateFile')
    else
      BASS_ChannelPlay(FStreamHandle, False);

    UpdateControlsState;
  end;
end;

procedure TMainForm.btnPlayPauseClick(Sender: TObject);
begin
  if BASS_ChannelIsActive(FStreamHandle) = BASS_ACTIVE_PLAYING then
    BASS_ChannelPause(FStreamHandle)
  else
    BASS_ChannelPlay(FStreamHandle, False);
end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  FreeStream;
  UpdateControlsState;
end;

procedure TMainForm.Edit1Change(Sender: TObject);
begin

end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  UpdateControlsState;

  if not BASS_Init(-1, 44100, 0, {$IFDEF MSWINDOWS}0{$ELSE}nil{$ENDIF}, nil) then
  begin
    ShowBassErrorMessage('BASS_Init');
    Exit;
  end;

  if not BASS_Start then
    ShowBassErrorMessage('BASS_Start');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  BASS_Stop;
  BASS_Free;
end;

procedure TMainForm.tbSeekChange(Sender: TObject);
begin
  if not FSeekBarChanging then
    BASS_ChannelSetPosition(FStreamHandle, BASS_ChannelSeconds2Bytes(FStreamHandle, tbSeek.Position), BASS_POS_BYTE);
end;

procedure TMainForm.tmTimerTimer(Sender: TObject);
begin
  UpdateTrackPosition;
end;

procedure TMainForm.FreeStream;
begin
  if FStreamHandle <> 0 then
  begin
    BASS_StreamFree(FStreamHandle);
    FStreamHandle := 0;
  end;
end;

procedure TMainForm.ShowBassErrorMessage(const AInvoker: string);
begin
  MessageDlg(Format('%s fails, error code: %d', [AInvoker, BASS_ErrorGetCode]),
    TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], 0);
end;

procedure TMainForm.UpdateControlsState;
begin
  btnPlayPause.Enabled := FStreamHandle <> 0;
  btnStop.Enabled := FStreamHandle <> 0;
  tmTimer.Enabled := FStreamHandle <> 0;
  tbSeek.Enabled := FStreamHandle <> 0;
  UpdateTrackPosition;
end;

procedure TMainForm.UpdateTrackPosition;
var
  ADuration, APosition: Double;
begin
  if FStreamHandle <> 0 then
  begin
    ADuration := BASS_ChannelBytes2Seconds(FStreamHandle, BASS_ChannelGetLength(FStreamHandle, BASS_POS_BYTE));
    APosition := BASS_ChannelBytes2Seconds(FStreamHandle, BASS_ChannelGetPosition(FStreamHandle, BASS_POS_BYTE));
    lbTime.Caption := FormatDateTime('hh:mm:ss', APosition / SecsPerDay) + ' / ' + FormatDateTime('hh:mm:ss', ADuration / SecsPerDay);

    FSeekBarChanging := True;
    try
      tbSeek.Max := Round(ADuration);
      tbSeek.Position := Round(APosition);
    finally
      FSeekBarChanging := False;
    end;
  end
  else
    lbTime.Caption := '--:--:-- / --:--:--';

end;

end.

