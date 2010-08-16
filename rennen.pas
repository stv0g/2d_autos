unit rennen;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Math, ExtCtrls, ComCtrls, Grids, IniFiles;

type
    TAuto = class
        Loc: TPoint;
        LastLoc: TPoint;
        Color: TColor;
        Dir: Double;
        LastDir: Double;
        RndState: boolean;
        Throttle: Double;
        Steer: Double;
        v: Double;
        a: Double;

        Name: String;
        LapTime: Cardinal;
        LapTimeTot: Cardinal;
        LapTimeAvg: Cardinal;
        FastestLap: Cardinal;

        Masse: Double;
        FRoll: Double;
        FLuft: Double;
        FAntrieb: Double;
        RLuft: Double;
        FMax: Double;

        PedalInc: Double;
        PedalDec: Double;
        SteerInc: Double;
        SteerDec: Double;
        RSpeedMax: Double;
        RSpeedCollission: Double;

        KeyUp: Integer;
        KeyDown: Integer;
        KeyLeft: Integer;
        KeyRight: Integer;

        Rnd: Integer;

        Form: array of TPoint;
        StdForm: array of TPoint;

        PbSpeed: TProgressBar;
        PbThrottle: TProgressBar;

        constructor Create();
        procedure Draw(Ground: TBitmap; Loc: TPoint; Dir: Double);
        procedure CalcLoc;
        procedure CalcDir;
        procedure Display(i: Integer);
        procedure RndCount;
        procedure Collission;
  end;

  TForm1 = class(TForm)
    Timer: TTimer;
    SgData: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure SgDataDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private-Deklarationen}
  public
    { Public-Deklarationen}
  end;

  procedure Rotate(car: TAuto; m: TPoint; dir: double);
  function GetCarBgd(Ground: TBitmap; Form: array of TPoint; color: TColor): Integer;
  function ColorToHtml(AColor: TColor): string;
  function HtmlToColor(AHtmlColor: string): TColor;

var
  Form1: TForm1;
  Auto: array of TAuto;
  Real: TBitmap;
  Shadow: TBitmap;
  Background: TBitmap;
  StartTime: Cardinal;
  RaceState: Integer;
  Rnds: Integer;

implementation

{$R *.DFM}

constructor TAuto.Create();
begin
     SetLength(StdForm, 5);
     SetLength(Form, 5);
     
     StdForm[0] := Point(-7,-10);
     StdForm[1] := Point(+7,-10);
     StdForm[2] := Point(+7,+15);
     StdForm[3] := Point(0,+20);
     StdForm[4] := Point(-7,+15);

     PbSpeed := TProgressBar.Create(nil);
     PbSpeed.Smooth := true;
     PbSpeed.Step := 1;
     PbSpeed.Parent := Form1.SgData;

     PbThrottle := TProgressBar.Create(nil);
     PbThrottle.Smooth := true;
     PbThrottle.Step := 1;
     PbThrottle.parent := Form1.SgData;
end;

procedure TAuto.Collission;
begin
     //Kollission
     if GetCarBgd(Shadow, Form, clBlack) > 0 then
        begin
             Loc := LastLoc;
             Dir := LastDir;
             Rotate(self, Loc, Dir);
             v := -v * RSpeedCollission;
     end;
end;

procedure TAuto.Draw(Ground: TBitmap; loc: TPoint; dir: Double);
begin
      Ground.Canvas.Pen.color := color;
      Ground.Canvas.Brush.Color := color;
      Ground.Canvas.Polygon(form);
end;

procedure TAuto.CalcDir;
begin
     //Lenkdynamik
     Steer := Steer * SteerDec;

     if Abs(v) < 1 then
        Steer := 0;

     if v > 0 then
        Dir := Dir + Steer
     else
         dir := dir - steer;
end;

procedure TAuto.CalcLoc;
var
   FFahr: Double;
   Sinus, Cosinus: Extended;
begin
     //Fahrzeugdynamik
     Throttle := Throttle * PedalDec;

     if  v > 0 then
        FFahr := FRoll + FLuft
     else
         FFahr := -FRoll - FLuft;

     FLuft := RLuft * Sqr(v);
     FAntrieb := FMax * Throttle;
     a := (FAntrieb - FFahr) / Masse;

     v := v + a;
     if v < RSpeedMax then v := RSpeedMax;

     //Streckenberechnung
     SinCos(degtorad(dir), sinus, cosinus);

     loc.x := Round(loc.x + v * sinus);
     loc.y := Round(loc.y + v * cosinus);
end;

procedure TAuto.Display(i: Integer);
begin
     //Anzeige
     Form1.SgData.Cells[0,i + 1] := name;
     Form1.SgData.Cells[1,i + 1] := inttostr(rnd) + ' / ' + inttostr(rnds);
     Form1.SgData.Cells[2,i + 1] := floattostr(LapTime / 1000);
     Form1.SgData.Cells[3,i + 1] := floattostr((LapTimeTot + LapTime) / 1000);
     if Auto[i].rnd <> 0 then
        Form1.SgData.Cells[4,i + 1] := floattostr((LapTimeTot / Rnd) / 1000)
     else
         Form1.SgData.Cells[4,i + 1] := '0';

     Form1.SgData.Cells[5,i + 1] := floattostr(FastestLap / 1000);
     Form1.SgData.Cells[6,i + 1] := inttostr(loc.x) + ' | ' + inttostr(loc.y);
     Form1.SgData.Cells[7,i + 1] := floattostr(Round(Dir));

     //Progressbars
     PbSpeed.position := round(Abs(Auto[i].v*3));
     if v > 0 then
        PbSpeed.Perform($0409, 0, clGreen)
     else
         PbSpeed.Perform($0409, 0, clRed);

     PbThrottle.position := round(Abs(Auto[i].throttle*100));
     if Throttle > 0 then
        PbThrottle.Perform($0409, 0, clGreen)
     else
         PbThrottle.Perform($0409, 0, clRed);
end;

procedure TAuto.RndCount;
begin
     //Rundenzähler
     if (Shadow.Canvas.Pixels[LastLoc.x,LastLoc.y] = clBlue) and (Shadow.Canvas.Pixels[Loc.x,Loc.y] = clRed) then
        if RndState = true then
           begin
                if Rnd = 0 then FastestLap := LapTime;
                if LapTime < FastestLap then
                   FastestLap := LapTime;

                if Rnd + 1 = Rnds then
                   begin
                        RaceState := -1;
                        if Application.MessageBox(PChar(Name + ' hat gewonnen! Neues Rennen starten?'), 'Ziel', 4+32) = IDYES then
                           begin
                                RaceState := 0;
                                StartTime := GetTickCount;
                                FastestLap := 0;
                                Rnd := 0;
                           end
                        else
                            Form1.Close;
                   end
                else
                    begin
                         Inc(Rnd);
                         RndState := false;
                         LapTimeTot := LapTimeTot + LapTime;
                         LapTime := 0;
                    end;
           end
        else
            begin
                 if (Rnd = 0) and (RaceState = 0) then
                    begin
                         RaceState := 1;
                         StartTime := GetTickCount;
                    end;
                    RndState := true;
             end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
   Ini: TIniFile;
   i: Integer;
begin
     //Autos
     ini:=TIniFile.create(ExtractFilePath(ParamStr(0)) + 'Auto.ini');
     i := 0;
     while ini.SectionExists('Auto' + inttostr(i)) do
     begin
           inc(i)
     end;

     SetLength(Auto, i);

     for i := 0 to i - 1 do
     begin
          Auto[i] :=  TAuto.Create;
          Auto[i].Loc.x := ini.ReadInteger('Auto' + inttostr(i), 'loc_x', 0);
          Auto[i].Loc.y := ini.ReadInteger('Auto' + inttostr(i), 'loc_y', 0);
          Auto[i].Color := htmltocolor(ini.ReadString('Auto' + inttostr(i), 'color', '#FFFFFF'));
          Auto[i].Dir := ini.ReadInteger('Auto' + inttostr(i), 'dir', 90);
          Auto[i].Name := ini.ReadString('Auto' + inttostr(i), 'name', 'Auto ' + inttostr(i + 1));
          Auto[i].KeyUp := ini.ReadInteger('Auto' + inttostr(i), 'key_up', 0);
          Auto[i].KeyDown := ini.ReadInteger('Auto' + inttostr(i), 'key_down', 0);
          Auto[i].KeyLeft := ini.ReadInteger('Auto' + inttostr(i), 'key_left', 0);
          Auto[i].KeyRight := ini.ReadInteger('Auto' + inttostr(i), 'key_right', 0);

          Auto[i].Masse := ini.ReadFloat('Auto' + inttostr(i), 'Masse', ini.ReadFloat('general', 'Masse', 1000));
          Auto[i].FRoll := ini.ReadFloat('Auto' + inttostr(i), 'FRoll', ini.ReadFloat('general', 'FRoll', 80));
          Auto[i].RLuft := ini.ReadFloat('Auto' + inttostr(i), 'RLuft', ini.ReadFloat('general', 'RLuft', 2.5));
          Auto[i].FMax := ini.ReadFloat('Auto' + inttostr(i), 'FMax', ini.ReadFloat('general', 'FMax', 3000));

          Auto[i].PedalInc := ini.ReadFloat('Auto' + inttostr(i), 'PedalInc', ini.ReadFloat('general', 'PedalInc', 0.2));
          Auto[i].PedalDec := ini.ReadFloat('Auto' + inttostr(i), 'PedalDec', ini.ReadFloat('general', 'PedalDec', 0.8));
          Auto[i].SteerInc := ini.ReadFloat('Auto' + inttostr(i), 'SteerInc', ini.ReadFloat('general', 'SteerInc', 5));
          Auto[i].SteerDec := ini.ReadFloat('Auto' + inttostr(i), 'SteerDec', ini.ReadFloat('general', 'SteerDec', 0.9));
          Auto[i].RSpeedMax := ini.ReadFloat('Auto' + inttostr(i), 'RSpeedMax', ini.ReadFloat('general', 'RSpeedMax', -10));
          Auto[i].RSpeedCollission := ini.ReadFloat('Auto' + inttostr(i), 'RSpeedCollission', ini.ReadFloat('general', 'RSpeedCollission', 0.4));
     end;

     Rnds :=  ini.ReadInteger('general', 'rnds', 10);

     Doublebuffered := true;
     Background := TBitmap.Create;
     Background.LoadFromFile(Ini.ReadString('general', 'map', ''));

     Real := TBitmap.Create;
     Real.Width := Background.Width;
     Real.Height := Background.Height;

     Shadow := TBitmap.Create;
     Shadow.Width := Background.Width;
     Shadow.Height := Background.Height;
     Shadow.LoadFromFile(Ini.ReadString('general', 'shmap', ''));

     ClientWidth := Background.Width;
     ClientHeight := Background.Height + SgData.RowCount * SgData.DefaultRowHeight;

     SgData.RowCount := High(Auto) + 2;

     for i:= 0 to SgData.ColCount - 1 do
         SgData.Cells[i,0] := ini.ReadString('general', 'col' + inttostr(i), '');

     ini.free;
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
   i: Integer;
begin
     Real.Canvas.StretchDraw(Rect(0,0,Background.Width, Background.Height),Background);

     for i := Low(Auto) to High(Auto) do
     begin
          Auto[i].LastLoc := Auto[i].Loc;
          Auto[i].LastDir := Auto[i].Dir;

          Auto[i].CalcDir();
          Auto[i].CalcLoc();

          Rotate(Auto[i], Auto[i].Loc, Auto[i].Dir);

          Auto[i].Collission;

          Auto[i].RndCount;

          //Zeit
          if RaceState = 1 then
             Auto[i].LapTime := GetTickCount - StartTime - Auto[i].LapTimeTot;

          Auto[i].Display(i);
          Auto[i].Draw(Real, Auto[i].loc, Auto[i].dir);
     end;

     Canvas.StretchDraw(Rect(0,0,ClientWidth, ClientHeight - SgData.RowCount * (SgData.DefaultRowHeight + SgData.GridLineWidth) + 1), Real);
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
   i: Integer;
begin
     if RaceState <> -1 then
     for i := Low(Auto) to High(Auto) do
         begin
              if Key = Auto[i].KeyUp then Auto[i].Throttle := Auto[i].Throttle + Auto[i].PedalInc;
              if Key = Auto[i].KeyDown then Auto[i].Throttle := Auto[i].Throttle - Auto[i].PedalInc;
              if Key = Auto[i].KeyLeft then Auto[i].Steer := Auto[i].Steer + Auto[i].SteerInc;
              if Key = Auto[i].KeyRight then Auto[i].Steer := Auto[i].Steer - Auto[i].SteerInc;
         end;
         
     case Key of
          VK_ESCAPE: close;

          Ord('F'): if BorderStyle = bsSizeable then
                       begin
                            BorderStyle := bsNone;
                            WindowState :=  wsMaximized;
                       end
                     else
                         begin
                              BorderStyle := bsSizeable;
                              WindowState := wsNormal;
                         end;
    end;
end;

procedure TForm1.FormResize(Sender: TObject);
var
   i: Integer;
begin
     SgData.Width := ClientWidth;
     SgData.DefaultColWidth := SgData.Width div SgData.ColCount;

     SgData.Height := SgData.RowCount * SgData.DefaultRowHeight;

     for i := Low(Auto) to High(Auto) do
     begin
          Auto[i].PbSpeed.Boundsrect := SgData.Cellrect(8, i + 1);
          Auto[i].PbThrottle.Boundsrect := SgData.Cellrect(9, i + 1);
     end;
end;

function GetCarBgd(Ground: TBitmap; Form: array of TPoint; Color: TColor): Integer;
var
i: Integer;
begin
     result := 0;
     for i := Low(form) to High(form) do
     if Ground.Canvas.Pixels[form[i].x, form[i].y] = color then
         inc(result);
end;

function ColorToHtml(AColor: TColor): string;
begin
 Result := IntToHex(ColorToRgb(AColor), 6);
 Result := '#' + Copy(Result, 5, 2) + Copy(Result, 3, 2) + Copy(Result, 1, 2);
end;

function HtmlToColor(AHtmlColor: string): TColor;
begin
 Delete(AHtmlColor, 1, 1);
 Result := StrToInt('$' + Copy(AHtmlColor, 5, 2) + Copy(AHtmlColor, 3, 2) + Copy(AHtmlColor, 1, 2));
end;

procedure Rotate(car: TAuto; m: TPoint; dir: double);
var
   i: Integer;
   Sinus, Cosinus: Extended;
begin
     SinCos(degtorad(dir), sinus, cosinus);
     for i := 0 to High(car.form) do
     begin
         Car.Form[i].x := Round(Car.StdForm[i].x*cosinus + car.StdForm[i].y*sinus + m.x);
         Car.Form[i].y := Round(-Car.StdForm[i].x*sinus + car.StdForm[i].y*cosinus + m.y);
     end;
end;

procedure TForm1.SgDataDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
i: Integer;
begin
     for i := 0 to High(Auto) do
         if ARow = i + 1 then
            begin
                 SgData.Canvas.Brush.Color := Auto[i].Color;
                 SgData.Canvas.FillRect(Rect);
                 SgData.Canvas.Font.Color := (not ColorToRGB(Auto[i].Color)) and $00FFFFFF;
            end;
     SgData.Canvas.TextOut(Rect.Left + 2, Rect.Top + 1, SgData.Cells[ACol, ARow]);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     SgData.Selection := TGridRect(Rect(-1,-1,-1,-1));
end;

end.
