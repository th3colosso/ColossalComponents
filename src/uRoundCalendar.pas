unit uRoundCalendar;

{ TRoundCalendar - Month calendar with rounded, anti-aliased shapes (GDI+).

  Shows one month at a time with previous/next month buttons, the selected
  day, today's date, and an optional "Today" footer. It works as a standalone
  control and as the drop-down of TRoundDateTimePicker.

  Mouse:    click a day to select it (OnSelect); arrows change the month.
  Keyboard: arrows move the date, PageUp/PageDown change the month (Ctrl =
            year), Home/End go to the first/last day, Enter selects. }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Classes, System.SysUtils, System.Types, System.DateUtils,
  Vcl.Controls, Vcl.Graphics;

type
  TRoundWeekDay = (wdSunday, wdMonday, wdTuesday, wdWednesday, wdThursday,
    wdFriday, wdSaturday);

  TRoundCalendarPart = (cpNone, cpPrev, cpNext, cpDay, cpToday);

  TRoundCalendar = class(TCustomControl)
  private
    FDate: TDate;             // selected date (whole days only)
    FViewYear: Word;          // month being displayed
    FViewMonth: Word;
    FMinDate: TDate;          // 0 = no limit
    FMaxDate: TDate;          // 0 = no limit
    FFirstDayOfWeek: TRoundWeekDay;
    FShowToday: Boolean;
    FTodayCaption: string;
    FRadius: Integer;
    FDayRadius: Integer;
    FBorderWidth: Integer;
    FBorderColor: TColor;
    FFillColor: TColor;
    FSelectedColor: TColor;
    FSelectedTextColor: TColor;
    FHoverColor: TColor;
    FTodayColor: TColor;
    FMutedColor: TColor;
    FTransparent: Boolean;
    FHoverPart: TRoundCalendarPart;
    FHoverDate: TDate;
    FDownPart: TRoundCalendarPart;
    FDownDate: TDate;
    FOnChange: TNotifyEvent;
    FOnSelect: TNotifyEvent;
    procedure SetDate(const Value: TDate);
    procedure SetMinDate(const Value: TDate);
    procedure SetMaxDate(const Value: TDate);
    procedure SetFirstDayOfWeek(const Value: TRoundWeekDay);
    procedure SetShowToday(const Value: Boolean);
    procedure SetTodayCaption(const Value: string);
    procedure SetRadius(const Value: Integer);
    procedure SetDayRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetSelectedColor(const Value: TColor);
    procedure SetSelectedTextColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetTodayColor(const Value: TColor);
    procedure SetMutedColor(const Value: TColor);
    procedure SetTransparent(const Value: Boolean);
    procedure ChangeColor(var Field: TColor; const Value: TColor);
    function IsFirstDayStored: Boolean;
    function IsMinDateStored: Boolean;
    function IsMaxDateStored: Boolean;
    function GridStart: TDate;
    function DayEnabled(ADate: TDate): Boolean;
    function CanShowPrevMonth: Boolean;
    function CanShowNextMonth: Boolean;
    function TitleText: string;
    function WeekDayName(AColumn: Integer): string;
    function FontUnit: Integer;
    function TitleWidth: Integer;
    function HeaderH: Integer;
    function WeekRowH: Integer;
    function FooterH: Integer;
    procedure ShowMonthOf(ADate: TDate);
    procedure ShiftMonth(ADelta: Integer);
    procedure GetLayout(out Header, WeekRow, Grid, Footer: TRect);
    function PrevRect(const Header: TRect): TRect;
    function NextRect(const Header: TRect): TRect;
    function DayRect(const Grid: TRect; AIndex: Integer): TRect;
    procedure HitTest(X, Y: Integer; out APart: TRoundCalendarPart;
      out ADate: TDate);
    procedure PaintShapes;
    procedure PaintTexts;
    procedure DoSelect;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Paint; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    { Resizes the control so the cells have a compact, comfortable size for
      the current font. Everything in the layout scales with the font. }
    procedure FitToFont;
    { Handles the navigation keys (arrows, PageUp/Down, Home/End, Enter).
      Returns True and sets Key to 0 when the key was used. The drop-down of
      TRoundDateTimePicker forwards the keys it receives to this method. }
    function ProcessKey(var Key: Word; Shift: TShiftState): Boolean;
  published
    property Date: TDate read FDate write SetDate;
    property MinDate: TDate read FMinDate write SetMinDate stored IsMinDateStored;
    property MaxDate: TDate read FMaxDate write SetMaxDate stored IsMaxDateStored;
    property FirstDayOfWeek: TRoundWeekDay read FFirstDayOfWeek write SetFirstDayOfWeek stored IsFirstDayStored;
    property ShowToday: Boolean read FShowToday write SetShowToday default True;
    property TodayCaption: string read FTodayCaption write SetTodayCaption;
    property Radius: Integer read FRadius write SetRadius default 12;
    property DayRadius: Integer read FDayRadius write SetDayRadius default 6;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00C0C0C0;
    property FillColor: TColor read FFillColor write SetFillColor default clWhite;
    property SelectedColor: TColor read FSelectedColor write SetSelectedColor default $00D77800;
    property SelectedTextColor: TColor read FSelectedTextColor write SetSelectedTextColor default clWhite;
    property HoverColor: TColor read FHoverColor write SetHoverColor default $00F0F0F0;
    property TodayColor: TColor read FTodayColor write SetTodayColor default $00D77800;
    property MutedColor: TColor read FMutedColor write SetMutedColor default $00A0A0A0;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
    property Align;
    property Anchors;
    property Font;
    property Height default 192;
    property Margins;
    property AlignWithMargins;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Enabled;
    property Width default 160;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property OnClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

{ First day of the week of the user's locale. }
function LocaleFirstDayOfWeek: TRoundWeekDay;

procedure Register;

implementation

uses
  System.Math, uColossalDraw;

const
  InnerMargin = 4;

function LocaleFirstDayOfWeek: TRoundWeekDay;
var
  Buf: array[0..3] of Char;
begin
  Result := wdSunday;
  // LOCALE_IFIRSTDAYOFWEEK: '0' = Monday ... '6' = Sunday
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IFIRSTDAYOFWEEK, @Buf[0], Length(Buf)) > 0 then
    if (Buf[0] >= '0') and (Buf[0] <= '6') then
      Result := TRoundWeekDay((Ord(Buf[0]) - Ord('0') + 1) mod 7);
end;

procedure Register;
begin
  RegisterComponents('Colossal Controls', [TRoundCalendar]);
end;

procedure DrawChevron(G: TGPGraphics; CX, CY: Single; ALeft: Boolean;
  AColor: TColor; AButtonSize: Integer);
var
  Pen: TGPPen;
  Outer, Tip, DX, DY: Single;
begin
  // The chevron scales with the size of its button
  DX := AButtonSize * 0.09;
  DY := AButtonSize * 0.17;
  if ALeft then
  begin
    Outer := CX + DX;
    Tip := CX - DX;
  end
  else
  begin
    Outer := CX - DX;
    Tip := CX + DX;
  end;
  Pen := TGPPen.Create(ToARGB(AColor), 1.6);
  try
    Pen.SetStartCap(LineCapRound);
    Pen.SetEndCap(LineCapRound);
    G.DrawLine(Pen, Outer, CY - DY, Tip, CY);
    G.DrawLine(Pen, Tip, CY, Outer, CY + DY);
  finally
    Pen.Free;
  end;
end;

{ TRoundCalendar }

constructor TRoundCalendar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque, csAcceptsControls];
  DoubleBuffered := True;
  TabStop := True;
  Width := 160;
  Height := 192;
  FRadius := 12;
  FDayRadius := 6;
  FBorderWidth := 1;
  FBorderColor := $00C0C0C0;
  FFillColor := clWhite;
  FSelectedColor := $00D77800;
  FSelectedTextColor := clWhite;
  FHoverColor := $00F0F0F0;
  FTodayColor := $00D77800;
  FMutedColor := $00A0A0A0;
  FFirstDayOfWeek := LocaleFirstDayOfWeek;
  FShowToday := True;
  FTodayCaption := 'Today';
  FDate := Trunc(Now);
  FViewYear := YearOf(FDate);
  FViewMonth := MonthOf(FDate);
end;

{ ---- date logic ---- }

function TRoundCalendar.GridStart: TDate;
var
  First: TDate;
  Offset: Integer;
begin
  // The grid always has 6 rows x 7 columns; it starts on the first column of
  // the week that contains the 1st of the displayed month.
  First := EncodeDate(FViewYear, FViewMonth, 1);
  Offset := (DayOfWeek(First) - 1 - Ord(FFirstDayOfWeek) + 7) mod 7;
  Result := First - Offset;
end;

function TRoundCalendar.DayEnabled(ADate: TDate): Boolean;
begin
  Result := ((FMinDate = 0) or (ADate >= FMinDate)) and
            ((FMaxDate = 0) or (ADate <= FMaxDate));
end;

function TRoundCalendar.CanShowPrevMonth: Boolean;
begin
  Result := (FMinDate = 0) or (EncodeDate(FViewYear, FViewMonth, 1) > FMinDate);
end;

function TRoundCalendar.CanShowNextMonth: Boolean;
begin
  Result := (FMaxDate = 0) or
    (IncMonth(EncodeDate(FViewYear, FViewMonth, 1), 1) <= FMaxDate);
end;

procedure TRoundCalendar.ShowMonthOf(ADate: TDate);
begin
  FViewYear := YearOf(ADate);
  FViewMonth := MonthOf(ADate);
  Invalidate;
end;

procedure TRoundCalendar.ShiftMonth(ADelta: Integer);
var
  First: TDate;
begin
  if (ADelta < 0) and not CanShowPrevMonth then Exit;
  if (ADelta > 0) and not CanShowNextMonth then Exit;
  First := IncMonth(EncodeDate(FViewYear, FViewMonth, 1), ADelta);
  ShowMonthOf(First);
end;

function TRoundCalendar.TitleText: string;
var
  MonthName: string;
begin
  MonthName := FormatSettings.LongMonthNames[FViewMonth];
  MonthName := UpperCase(Copy(MonthName, 1, 1)) + Copy(MonthName, 2, MaxInt);
  Result := MonthName + ' ' + IntToStr(FViewYear);
end;

function TRoundCalendar.WeekDayName(AColumn: Integer): string;
begin
  // ShortDayNames is 1-based and starts on Sunday
  Result := FormatSettings.ShortDayNames[((Ord(FFirstDayOfWeek) + AColumn) mod 7) + 1];
end;

function TRoundCalendar.FontUnit: Integer;
begin
  // Height of the font in pixels. Every size of the layout is derived from
  // it, so the calendar scales with the font (and with the DPI).
  Result := Max(8, Abs(Font.Height));
end;

function TRoundCalendar.HeaderH: Integer;
begin
  Result := Round(FontUnit * 1.8);
end;

function TRoundCalendar.WeekRowH: Integer;
begin
  Result := Round(FontUnit * 1.3);
end;

function TRoundCalendar.FooterH: Integer;
begin
  Result := Round(FontUnit * 1.6);
end;

function TRoundCalendar.TitleWidth: Integer;
var
  Bmp: TBitmap;
  I, W: Integer;
begin
  // Width of the widest "Month YYYY" (bold) in the current font and locale
  Result := 0;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    Bmp.Canvas.Font.Style := Bmp.Canvas.Font.Style + [fsBold];
    for I := 1 to 12 do
    begin
      W := Bmp.Canvas.TextWidth(FormatSettings.LongMonthNames[I] + ' 9999');
      if W > Result then
        Result := W;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TRoundCalendar.FitToFont;
var
  P, CellW, CellH: Integer;
begin
  P := FBorderWidth + InnerMargin;
  CellW := Max(18, Round(FontUnit * 1.6));
  CellH := Max(17, Round(FontUnit * 1.5));
  // Wide enough for 7 cells, and for the month + year title between the two
  // (square) navigation buttons without being cut off
  Width := Max(2 * P + 7 * CellW,
    2 * P + 2 * HeaderH + TitleWidth + FontUnit);
  Height := 2 * P + HeaderH + WeekRowH + 6 * CellH;
  if FShowToday then
    Height := Height + FooterH;
end;

procedure TRoundCalendar.DoSelect;
begin
  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

{ ---- layout and hit testing ---- }

procedure TRoundCalendar.GetLayout(out Header, WeekRow, Grid, Footer: TRect);
var
  P: Integer;
begin
  P := FBorderWidth + InnerMargin;
  Header := Rect(P, P, Width - P, P + HeaderH);
  WeekRow := Rect(P, Header.Bottom, Width - P, Header.Bottom + WeekRowH);
  if FShowToday then
    Footer := Rect(P, Height - P - FooterH, Width - P, Height - P)
  else
    Footer := Rect(P, Height - P, Width - P, Height - P);
  Grid := Rect(P, WeekRow.Bottom, Width - P, Footer.Top);
  if Grid.Bottom < Grid.Top then
    Grid.Bottom := Grid.Top;
end;

function TRoundCalendar.PrevRect(const Header: TRect): TRect;
begin
  Result := Rect(Header.Left, Header.Top,
    Header.Left + (Header.Bottom - Header.Top), Header.Bottom);
end;

function TRoundCalendar.NextRect(const Header: TRect): TRect;
begin
  Result := Rect(Header.Right - (Header.Bottom - Header.Top), Header.Top,
    Header.Right, Header.Bottom);
end;

function TRoundCalendar.DayRect(const Grid: TRect; AIndex: Integer): TRect;
var
  GW, GH, Col, Row: Integer;
begin
  GW := Grid.Right - Grid.Left;
  GH := Grid.Bottom - Grid.Top;
  Col := AIndex mod 7;
  Row := AIndex div 7;
  Result := Rect(
    Grid.Left + (Col * GW) div 7,
    Grid.Top + (Row * GH) div 6,
    Grid.Left + ((Col + 1) * GW) div 7,
    Grid.Top + ((Row + 1) * GH) div 6);
end;

procedure TRoundCalendar.HitTest(X, Y: Integer; out APart: TRoundCalendarPart;
  out ADate: TDate);
var
  P: TPoint;
  Header, WeekRow, Grid, Footer: TRect;
  I: Integer;
begin
  APart := cpNone;
  ADate := 0;
  P := Point(X, Y);
  GetLayout(Header, WeekRow, Grid, Footer);
  if PtInRect(PrevRect(Header), P) then
    APart := cpPrev
  else if PtInRect(NextRect(Header), P) then
    APart := cpNext
  else if FShowToday and PtInRect(Footer, P) then
    APart := cpToday
  else if PtInRect(Grid, P) then
    for I := 0 to 41 do
      if PtInRect(DayRect(Grid, I), P) then
      begin
        APart := cpDay;
        ADate := GridStart + I;
        Break;
      end;
end;

{ ---- painting ---- }

procedure TRoundCalendar.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1; // Paint draws everything (avoids flicker)
end;

procedure TRoundCalendar.PaintShapes;
var
  G: TGPGraphics;
  Header, WeekRow, Grid, Footer, R: TRect;
  I: Integer;
  D, Start, TodayDate: TDate;
  Half, CellX, CellY, CellW, CellH: Single;
  ChevronColor: TColor;
begin
  GetLayout(Header, WeekRow, Grid, Footer);
  Start := GridStart;
  TodayDate := Trunc(Now);

  G := TGPGraphics.Create(Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHalf);

    // Frame (same geometry as the other Colossal controls)
    Half := FBorderWidth / 2;
    FillRoundRect(G, Half, Half, Width - FBorderWidth - 1,
      Height - FBorderWidth - 1, FRadius, FFillColor);
    if FBorderWidth > 0 then
      StrokeRoundRect(G, Half, Half, Width - FBorderWidth - 1,
        Height - FBorderWidth - 1, FRadius, FBorderColor, FBorderWidth);

    // Previous / next month buttons
    R := PrevRect(Header);
    if CanShowPrevMonth then ChevronColor := Font.Color else ChevronColor := FMutedColor;
    if CanShowPrevMonth and (FHoverPart = cpPrev) then
      FillRoundRect(G, R.Left + 2, R.Top + 2, R.Right - R.Left - 4,
        R.Bottom - R.Top - 4, FDayRadius, FHoverColor);
    DrawChevron(G, (R.Left + R.Right) / 2, (R.Top + R.Bottom) / 2, True,
      ChevronColor, R.Bottom - R.Top);

    R := NextRect(Header);
    if CanShowNextMonth then ChevronColor := Font.Color else ChevronColor := FMutedColor;
    if CanShowNextMonth and (FHoverPart = cpNext) then
      FillRoundRect(G, R.Left + 2, R.Top + 2, R.Right - R.Left - 4,
        R.Bottom - R.Top - 4, FDayRadius, FHoverColor);
    DrawChevron(G, (R.Left + R.Right) / 2, (R.Top + R.Bottom) / 2, False,
      ChevronColor, R.Bottom - R.Top);

    // Days: selected, hovered and today
    for I := 0 to 41 do
    begin
      D := Start + I;
      R := DayRect(Grid, I);
      CellX := R.Left + 1;
      CellY := R.Top + 1;
      CellW := R.Right - R.Left - 2;
      CellH := R.Bottom - R.Top - 2;
      if D = FDate then
        FillRoundRect(G, CellX, CellY, CellW, CellH, FDayRadius, FSelectedColor)
      else if (FHoverPart = cpDay) and (FHoverDate = D) and DayEnabled(D) then
        FillRoundRect(G, CellX, CellY, CellW, CellH, FDayRadius, FHoverColor);
      if D = TodayDate then
        StrokeRoundRect(G, CellX + 0.75, CellY + 0.75, CellW - 1.5, CellH - 1.5,
          FDayRadius, FTodayColor, 1.5);
    end;

    // "Today" footer hover
    if FShowToday and (FHoverPart = cpToday) and DayEnabled(TodayDate) then
      FillRoundRect(G, Footer.Left, Footer.Top + 2, Footer.Right - Footer.Left,
        Footer.Bottom - Footer.Top - 4, FDayRadius, FHoverColor);
  finally
    G.Free;
  end;
end;

procedure TRoundCalendar.PaintTexts;
var
  Header, WeekRow, Grid, Footer, R: TRect;
  I, GW, Chars: Integer;
  D, Start, TodayDate: TDate;
  S: string;
begin
  GetLayout(Header, WeekRow, Grid, Footer);
  Start := GridStart;
  TodayDate := Trunc(Now);

  Canvas.Font.Assign(Font);
  Canvas.Brush.Style := bsClear;

  // Month and year (bold)
  Canvas.Font.Style := Canvas.Font.Style + [fsBold];
  Canvas.Font.Color := Font.Color;
  R := Rect(PrevRect(Header).Right, Header.Top, NextRect(Header).Left, Header.Bottom);
  S := TitleText;
  Canvas.TextRect(R, S, [tfCenter, tfVerticalCenter, tfSingleLine, tfEndEllipsis]);
  Canvas.Font.Style := Font.Style;

  // Weekday names: a bit smaller than the days, abbreviated to 2 letters
  // unless the cells are wide enough for 3
  Canvas.Font.Color := FMutedColor;
  Canvas.Font.Size := Max(6, Font.Size - 1);
  GW := WeekRow.Right - WeekRow.Left;
  if GW div 7 >= Round(FontUnit * 2.6) then Chars := 3 else Chars := 2;
  for I := 0 to 6 do
  begin
    R := Rect(WeekRow.Left + (I * GW) div 7, WeekRow.Top,
      WeekRow.Left + ((I + 1) * GW) div 7, WeekRow.Bottom);
    S := Copy(WeekDayName(I), 1, Chars);
    Canvas.TextRect(R, S, [tfCenter, tfVerticalCenter, tfSingleLine, tfEndEllipsis]);
  end;
  Canvas.Font.Size := Font.Size;

  // Day numbers
  for I := 0 to 41 do
  begin
    D := Start + I;
    R := DayRect(Grid, I);
    if D = FDate then
      Canvas.Font.Color := FSelectedTextColor
    else if (not DayEnabled(D)) or (MonthOf(D) <> FViewMonth) then
      Canvas.Font.Color := FMutedColor
    else
      Canvas.Font.Color := Font.Color;
    S := IntToStr(DayOf(D));
    Canvas.TextRect(R, S, [tfCenter, tfVerticalCenter, tfSingleLine]);
  end;

  // "Today" footer (a bit smaller than the days)
  if FShowToday then
  begin
    Canvas.Font.Size := Max(6, Font.Size - 1);
    if DayEnabled(TodayDate) then
      Canvas.Font.Color := FSelectedColor
    else
      Canvas.Font.Color := FMutedColor;
    R := Footer;
    S := FTodayCaption;
    Canvas.TextRect(R, S, [tfCenter, tfVerticalCenter, tfSingleLine, tfEndEllipsis]);
  end;
end;

procedure TRoundCalendar.Paint;
begin
  // Painting our own background makes the parent paint its children, us
  // included: skip that nested request
  if IsPaintingBackgroundOf(Self) then Exit;

  PaintControlBackground(Self, Canvas.Handle, FTransparent);
  PaintShapes;
  PaintTexts;
end;

{ ---- mouse ---- }

procedure TRoundCalendar.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if FHoverPart <> cpNone then
  begin
    FHoverPart := cpNone;
    FHoverDate := 0;
    Invalidate;
  end;
end;

procedure TRoundCalendar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Part: TRoundCalendarPart;
  D: TDate;
begin
  inherited;
  HitTest(X, Y, Part, D);
  if (Part <> FHoverPart) or (D <> FHoverDate) then
  begin
    FHoverPart := Part;
    FHoverDate := D;
    Invalidate;
  end;
end;

procedure TRoundCalendar.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then Exit;
  // As the drop-down of TRoundDateTimePicker (TabStop = False) it must not
  // steal the focus from the picker
  if TabStop and CanFocus and not Focused then
    SetFocus;
  HitTest(X, Y, FDownPart, FDownDate);
end;

procedure TRoundCalendar.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Part: TRoundCalendarPart;
  D: TDate;
begin
  inherited;
  if Button <> mbLeft then Exit;
  HitTest(X, Y, Part, D);
  // The action happens on mouse up, and only if the press started on the
  // same button/day
  if (Part = FDownPart) and (D = FDownDate) then
    case Part of
      cpPrev: ShiftMonth(-1);
      cpNext: ShiftMonth(1);
      cpDay:
        if DayEnabled(D) then
        begin
          SetDate(D);
          DoSelect;
        end;
      cpToday:
        if DayEnabled(Trunc(Now)) then
        begin
          SetDate(Trunc(Now));
          DoSelect;
        end;
    end;
  FDownPart := cpNone;
  FDownDate := 0;
end;

{ ---- keyboard ---- }

procedure TRoundCalendar.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  inherited;
  Msg.Result := Msg.Result or DLGC_WANTARROWS;
end;

function TRoundCalendar.ProcessKey(var Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
  case Key of
    VK_LEFT:  SetDate(FDate - 1);
    VK_RIGHT: SetDate(FDate + 1);
    VK_UP:    SetDate(FDate - 7);
    VK_DOWN:  SetDate(FDate + 7);
    VK_PRIOR:
      if ssCtrl in Shift then SetDate(IncMonth(FDate, -12))
      else SetDate(IncMonth(FDate, -1));
    VK_NEXT:
      if ssCtrl in Shift then SetDate(IncMonth(FDate, 12))
      else SetDate(IncMonth(FDate, 1));
    VK_HOME:  SetDate(StartOfTheMonth(FDate));
    VK_END:   SetDate(EndOfTheMonth(FDate));
    VK_RETURN: DoSelect;
  else
    Result := False;
  end;
  if Result then
    Key := 0;
end;

procedure TRoundCalendar.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if Key <> 0 then
    ProcessKey(Key, Shift);
end;

procedure TRoundCalendar.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

{ ---- property setters ---- }

procedure TRoundCalendar.ChangeColor(var Field: TColor; const Value: TColor);
begin
  if Field <> Value then
  begin
    Field := Value;
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetDate(const Value: TDate);
var
  NewDate: TDate;
begin
  NewDate := Trunc(Value);
  if (FMinDate <> 0) and (NewDate < FMinDate) then NewDate := FMinDate;
  if (FMaxDate <> 0) and (NewDate > FMaxDate) then NewDate := FMaxDate;

  ShowMonthOf(NewDate); // also repaints
  if FDate <> NewDate then
  begin
    FDate := NewDate;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRoundCalendar.SetMinDate(const Value: TDate);
begin
  FMinDate := Trunc(Value);
  SetDate(FDate); // re-applies the limits
end;

procedure TRoundCalendar.SetMaxDate(const Value: TDate);
begin
  FMaxDate := Trunc(Value);
  SetDate(FDate);
end;

function TRoundCalendar.IsFirstDayStored: Boolean;
begin
  Result := FFirstDayOfWeek <> LocaleFirstDayOfWeek;
end;

function TRoundCalendar.IsMinDateStored: Boolean;
begin
  Result := FMinDate <> 0;
end;

function TRoundCalendar.IsMaxDateStored: Boolean;
begin
  Result := FMaxDate <> 0;
end;

procedure TRoundCalendar.SetFirstDayOfWeek(const Value: TRoundWeekDay);
begin
  if FFirstDayOfWeek <> Value then
  begin
    FFirstDayOfWeek := Value;
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetShowToday(const Value: Boolean);
begin
  if FShowToday <> Value then
  begin
    FShowToday := Value;
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetTodayCaption(const Value: string);
begin
  if FTodayCaption <> Value then
  begin
    FTodayCaption := Value;
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetRadius(const Value: Integer);
begin
  if FRadius <> Max(0, Value) then
  begin
    FRadius := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetDayRadius(const Value: Integer);
begin
  if FDayRadius <> Max(0, Value) then
  begin
    FDayRadius := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetBorderWidth(const Value: Integer);
begin
  if FBorderWidth <> Max(0, Value) then
  begin
    FBorderWidth := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundCalendar.SetBorderColor(const Value: TColor);
begin
  ChangeColor(FBorderColor, Value);
end;

procedure TRoundCalendar.SetFillColor(const Value: TColor);
begin
  ChangeColor(FFillColor, Value);
end;

procedure TRoundCalendar.SetSelectedColor(const Value: TColor);
begin
  ChangeColor(FSelectedColor, Value);
end;

procedure TRoundCalendar.SetSelectedTextColor(const Value: TColor);
begin
  ChangeColor(FSelectedTextColor, Value);
end;

procedure TRoundCalendar.SetHoverColor(const Value: TColor);
begin
  ChangeColor(FHoverColor, Value);
end;

procedure TRoundCalendar.SetTodayColor(const Value: TColor);
begin
  ChangeColor(FTodayColor, Value);
end;

procedure TRoundCalendar.SetMutedColor(const Value: TColor);
begin
  ChangeColor(FMutedColor, Value);
end;

procedure TRoundCalendar.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    Invalidate;
  end;
end;

end.
