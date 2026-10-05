unit uRoundDateTimePicker;

{ TRoundDateTimePicker - Date/time picker with rounded, anti-aliased corners
  (GDI+) that behaves like the standard TDateTimePicker: an edit where the
  date is typed directly, plus a button that opens a calendar to pick from.

  Editing (the value is edited field by field, e.g. day / month / year):
    - Type digits: they fill the current field and move on to the next one
      when it is complete. A separator key ( / . - : space ) also moves to
      the next field, so "5/10/2026" can be typed as it reads.
    - Left/Right (or a click) select a field, Up/Down and the mouse wheel
      change it, Home/End jump to the first/last field.
    - Ctrl+V pastes a full date/time, Ctrl+C copies the text.
  Drop-down calendar:
    - Click the button, or press F4 / Alt+Down. Arrows, PageUp/PageDown,
      Home/End and Enter work inside it; Esc closes it.

  The calendar is shown as a child of the form, so it can only be as large as
  the form's client area allows (it opens above the picker when there is no
  room below). }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Classes, System.SysUtils, System.Types, System.DateUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, uRoundCalendar;

type
  TRoundDateTimeKind = (rdkDate, rdkTime, rdkDateTime);

  TRoundPickerField = (pfLiteral, pfDay, pfDayName, pfMonth, pfMonthName,
    pfYear, pfHour, pfHour12, pfMinute, pfSecond, pfAmPm);

  TRoundPickerSegment = record
    Field: TRoundPickerField;
    Len: Integer;          // number of letters of the format token
    Literal: string;       // text of a pfLiteral segment
    Area: TRect;           // set while painting, used for mouse hit testing
  end;

  TRoundDateTimePicker = class(TCustomControl)
  private
    FDateTime: TDateTime;
    FKind: TRoundDateTimeKind;
    FFormat: string;
    FMinDate: TDateTime;     // 0 = no limit
    FMaxDate: TDateTime;     // 0 = no limit
    FRadius: Integer;
    FBorderWidth: Integer;
    FPadding: Integer;
    FBorderColor: TColor;
    FFocusColor: TColor;
    FFillColor: TColor;
    FHoverColor: TColor;
    FSelectedTextColor: TColor;
    FTransparent: Boolean;
    FFirstDayOfWeek: TRoundWeekDay;
    FShowToday: Boolean;
    FTodayCaption: string;
    FSegments: array of TRoundPickerSegment;
    FActiveSeg: Integer;
    FDigits: string;         // digits typed so far in the active field
    FCapH: Integer;          // cap height of the current font (layout)
    FTextTop: Integer;       // top of the text line box (layout)
    FHoverButton: Boolean;
    FDroppedDown: Boolean;
    FCalendar: TRoundCalendar;
    FOnChange: TNotifyEvent;
    FOnDropDown: TNotifyEvent;
    FOnCloseUp: TNotifyEvent;
    procedure SetDateTime(const Value: TDateTime);
    procedure SetKind(const Value: TRoundDateTimeKind);
    procedure SetFormat(const Value: string);
    procedure SetMinDate(const Value: TDateTime);
    procedure SetMaxDate(const Value: TDateTime);
    procedure SetRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetPadding(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFocusColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetSelectedTextColor(const Value: TColor);
    procedure SetTransparent(const Value: Boolean);
    procedure ChangeColor(var Field: TColor; const Value: TColor);
    function GetDate: TDate;
    procedure SetDate(const Value: TDate);
    function GetTime: TTime;
    procedure SetTime(const Value: TTime);
    function IsMinDateStored: Boolean;
    function IsMaxDateStored: Boolean;
    function IsFirstDayStored: Boolean;
    // format / segments
    function EffectiveFormat: string;
    procedure BuildSegments;
    function SegmentText(const ASeg: TRoundPickerSegment): string;
    function DisplayText: string;
    function IsEditable(const ASeg: TRoundPickerSegment): Boolean;
    function FindEditable(AStart, ADir: Integer): Integer;
    function ValidSeg: Boolean;
    procedure LayoutSegments;
    function HasButton: Boolean;
    function ButtonRect: TRect;
    function SegmentAt(X: Integer): Integer;
    // value editing
    function ClampToLimits(AValue: TDateTime): TDateTime;
    procedure SetValueInternal(AValue: TDateTime; AClamp: Boolean);
    procedure ApplyField(AField: TRoundPickerField; AValue: Integer; AClamp: Boolean);
    procedure StepField(AField: TRoundPickerField; ADelta: Integer);
    procedure StepActive(ADelta: Integer);
    procedure TypeDigit(ADigit: Integer);
    procedure SetAmPm(APm: Boolean);
    procedure CommitEdit;
    procedure MoveSegment(ADir: Integer);
    procedure PasteFromClipboard;
    procedure CopyToClipboard;
    // calendar
    procedure PrepareCalendar(AForm: TCustomForm);
    procedure CalendarSelect(Sender: TObject);
    // painting
    procedure PaintShapes;
    procedure PaintText;
    // messages
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure CMCancelMode(var Msg: TCMCancelMode); message CM_CANCELMODE;
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DropDown;
    procedure CloseUp;
    property DroppedDown: Boolean read FDroppedDown;
    { Date part / time part of DateTime }
    property Date: TDate read GetDate write SetDate;
    property Time: TTime read GetTime write SetTime;
  published
    property DateTime: TDateTime read FDateTime write SetDateTime;
    property Kind: TRoundDateTimeKind read FKind write SetKind default rdkDate;
    { Custom display format, e.g. 'dd/MM/yyyy HH:mm'. Empty = default format
      of Kind (the system short date format for dates). See the README for
      the supported tokens. }
    property Format: string read FFormat write SetFormat;
    property MinDate: TDateTime read FMinDate write SetMinDate stored IsMinDateStored;
    property MaxDate: TDateTime read FMaxDate write SetMaxDate stored IsMaxDateStored;
    property Radius: Integer read FRadius write SetRadius default 10;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property Padding: Integer read FPadding write SetPadding default 8;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00ADADAD;
    property FocusColor: TColor read FFocusColor write SetFocusColor default $00D77800;
    property FillColor: TColor read FFillColor write SetFillColor default clWhite;
    property HoverColor: TColor read FHoverColor write SetHoverColor default $00F0F0F0;
    property SelectedTextColor: TColor read FSelectedTextColor write SetSelectedTextColor default clWhite;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
    property FirstDayOfWeek: TRoundWeekDay read FFirstDayOfWeek write FFirstDayOfWeek stored IsFirstDayStored;
    property ShowToday: Boolean read FShowToday write FShowToday default True;
    property TodayCaption: string read FTodayCaption write FTodayCaption;
    property Align;
    property Anchors;
    property Cursor;
    property Enabled;
    property Font;
    property Height default 32;
    property Hint;
    property Margins;
    property AlignWithMargins;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Width default 200;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnDropDown: TNotifyEvent read FOnDropDown write FOnDropDown;
    property OnCloseUp: TNotifyEvent read FOnCloseUp write FOnCloseUp;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
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

procedure Register;

implementation

uses
  System.Math, Vcl.Clipbrd, uColossalDraw;

procedure Register;
begin
  RegisterComponents('Colossal Controls', [TRoundDateTimePicker]);
end;

function WrapValue(AValue, ALow, AHigh: Integer): Integer;
var
  Span: Integer;
begin
  Span := AHigh - ALow + 1;
  Result := ALow + (((AValue - ALow) mod Span) + Span) mod Span;
end;

function PadNumber(AValue, ALen: Integer): string;
begin
  Result := IntToStr(AValue);
  if (ALen >= 2) and (Length(Result) < 2) then
    Result := '0' + Result;
end;

function LocaleDateFormat: string;
begin
  // The system short date format may use 'm' for the month; in this unit 'M'
  // is the month and 'm' the minute (like .NET custom formats)
  Result := StringReplace(FormatSettings.ShortDateFormat, 'm', 'M', [rfReplaceAll]);
end;

procedure DrawCalendarGlyph(G: TGPGraphics; CX, CY: Single; AColor: TColor);
var
  Pen: TGPPen;
  Brush: TGPSolidBrush;
  X, Y: Single;
  Col, Row: Integer;
begin
  X := CX - 7;
  Y := CY - 7;
  Pen := nil;
  Brush := nil;
  try
    Pen := TGPPen.Create(ToARGB(AColor), 1.3);
    Pen.SetStartCap(LineCapRound);
    Pen.SetEndCap(LineCapRound);
    Brush := TGPSolidBrush.Create(ToARGB(AColor));

    StrokeRoundRect(G, X + 0.65, Y + 2.65, 12.7, 11.7, 2.5, AColor, 1.3); // body
    G.DrawLine(Pen, X + 1, Y + 6.5, X + 13, Y + 6.5);                     // header line
    G.DrawLine(Pen, X + 4, Y + 0.7, X + 4, Y + 3.7);                      // rings
    G.DrawLine(Pen, X + 10, Y + 0.7, X + 10, Y + 3.7);
    for Row := 0 to 1 do                                                  // days
      for Col := 0 to 2 do
        G.FillRectangle(Brush, X + 3 + Col * 3.2, Y + 8.4 + Row * 2.6, 1.6, 1.6);
  finally
    Brush.Free;
    Pen.Free;
  end;
end;

{ TRoundDateTimePicker }

constructor TRoundDateTimePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque, csAcceptsControls];
  DoubleBuffered := True;
  TabStop := True;
  Width := 200;
  Height := 32;
  FRadius := 10;
  FBorderWidth := 1;
  FPadding := 8;
  FBorderColor := $00ADADAD;
  FFocusColor := $00D77800;
  FFillColor := clWhite;
  FHoverColor := $00F0F0F0;
  FSelectedTextColor := clWhite;
  FFirstDayOfWeek := LocaleFirstDayOfWeek;
  FShowToday := True;
  FTodayCaption := 'Today';
  FKind := rdkDate;
  FDateTime := RecodeMilliSecond(Now, 0);
  BuildSegments;
end;

procedure TRoundDateTimePicker.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FCalendar) then
    FCalendar := nil;
end;

{ ---- format and segments ---- }

function TRoundDateTimePicker.EffectiveFormat: string;
begin
  if FFormat <> '' then
    Result := FFormat
  else
    case FKind of
      rdkTime:     Result := 'HH:mm';
      rdkDateTime: Result := LocaleDateFormat + ' HH:mm';
    else
      Result := LocaleDateFormat;
    end;
end;

procedure TRoundDateTimePicker.BuildSegments;
var
  Fmt, Lit: string;
  I, J, N: Integer;
  C: Char;

  procedure Append(const ASeg: TRoundPickerSegment);
  begin
    SetLength(FSegments, Length(FSegments) + 1);
    FSegments[High(FSegments)] := ASeg;
  end;

  procedure FlushLiteral;
  var
    Seg: TRoundPickerSegment;
  begin
    if Lit = '' then Exit;
    Seg := Default(TRoundPickerSegment);
    Seg.Field := pfLiteral;
    Seg.Literal := Lit;
    Append(Seg);
    Lit := '';
  end;

  procedure AddField(ALetter: Char; ACount: Integer);
  var
    Seg: TRoundPickerSegment;
  begin
    Seg := Default(TRoundPickerSegment);
    Seg.Len := ACount;
    case ALetter of
      'd': if ACount >= 3 then Seg.Field := pfDayName else Seg.Field := pfDay;
      'M': if ACount >= 3 then Seg.Field := pfMonthName else Seg.Field := pfMonth;
      'y':
        begin
          Seg.Field := pfYear;
          if ACount >= 3 then Seg.Len := 4 else Seg.Len := 2;
        end;
      'H': Seg.Field := pfHour;
      'h': Seg.Field := pfHour12;
      'm': Seg.Field := pfMinute;
      's': Seg.Field := pfSecond;
      't': Seg.Field := pfAmPm;
    end;
    Append(Seg);
  end;

begin
  SetLength(FSegments, 0);
  Fmt := EffectiveFormat;
  Lit := '';
  I := 1;
  while I <= Length(Fmt) do
  begin
    C := Fmt[I];
    case C of
      'd', 'M', 'y', 'H', 'h', 'm', 's', 't':
        begin
          J := I;
          while (J <= Length(Fmt)) and (Fmt[J] = C) do
            Inc(J);
          N := J - I;
          FlushLiteral;
          AddField(C, N);
          I := J;
        end;
      '''': // text between single quotes is a literal
        begin
          J := I + 1;
          while (J <= Length(Fmt)) and (Fmt[J] <> '''') do
          begin
            Lit := Lit + Fmt[J];
            Inc(J);
          end;
          I := J + 1;
        end;
    else
      Lit := Lit + C;
      Inc(I);
    end;
  end;
  FlushLiteral;

  FDigits := '';
  FActiveSeg := FindEditable(0, 1);
end;

function TRoundDateTimePicker.SegmentText(const ASeg: TRoundPickerSegment): string;
var
  Y, M, D, H, N, S, MS: Word;
  H12: Integer;
begin
  DecodeDateTime(FDateTime, Y, M, D, H, N, S, MS);
  case ASeg.Field of
    pfLiteral: Result := ASeg.Literal;
    pfDay:     Result := PadNumber(D, ASeg.Len);
    pfMonth:   Result := PadNumber(M, ASeg.Len);
    pfMonthName:
      if ASeg.Len = 3 then Result := FormatSettings.ShortMonthNames[M]
      else Result := FormatSettings.LongMonthNames[M];
    pfDayName:
      if ASeg.Len = 3 then Result := FormatSettings.ShortDayNames[DayOfWeek(FDateTime)]
      else Result := FormatSettings.LongDayNames[DayOfWeek(FDateTime)];
    pfYear:
      if ASeg.Len = 2 then
        Result := PadNumber(Y mod 100, 2)
      else
      begin
        Result := IntToStr(Y);
        Result := StringOfChar('0', 4 - Length(Result)) + Result;
      end;
    pfHour:    Result := PadNumber(H, ASeg.Len);
    pfHour12:
      begin
        H12 := H mod 12;
        if H12 = 0 then H12 := 12;
        Result := PadNumber(H12, ASeg.Len);
      end;
    pfMinute:  Result := PadNumber(N, ASeg.Len);
    pfSecond:  Result := PadNumber(S, ASeg.Len);
    pfAmPm:
      begin
        if H < 12 then Result := FormatSettings.TimeAMString
        else Result := FormatSettings.TimePMString;
        if Result = '' then // some locales have no AM/PM strings
          if H < 12 then Result := 'AM' else Result := 'PM';
      end;
  end;
end;

function TRoundDateTimePicker.DisplayText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FSegments) do
    Result := Result + SegmentText(FSegments[I]);
end;

function TRoundDateTimePicker.IsEditable(const ASeg: TRoundPickerSegment): Boolean;
begin
  Result := not (ASeg.Field in [pfLiteral, pfDayName]);
end;

function TRoundDateTimePicker.FindEditable(AStart, ADir: Integer): Integer;
var
  I: Integer;
begin
  I := AStart;
  while (I >= 0) and (I <= High(FSegments)) do
  begin
    if IsEditable(FSegments[I]) then
      Exit(I);
    Inc(I, ADir);
  end;
  Result := -1;
end;

function TRoundDateTimePicker.ValidSeg: Boolean;
begin
  Result := (FActiveSeg >= 0) and (FActiveSeg <= High(FSegments));
end;

function TRoundDateTimePicker.HasButton: Boolean;
begin
  Result := FKind <> rdkTime;
end;

function TRoundDateTimePicker.ButtonRect: TRect;
begin
  if HasButton then
    Result := Rect(Width - FBorderWidth - (Height - 2 * FBorderWidth),
      FBorderWidth, Width - FBorderWidth, Height - FBorderWidth)
  else
    Result := Rect(0, 0, 0, 0);
end;

procedure TRoundDateTimePicker.LayoutSegments;
var
  TM: TTextMetric;
  I, X, W: Integer;
begin
  Canvas.Font.Assign(Font);
  Canvas.TextHeight('Hg'); // forces the font to be selected into the DC
  GetTextMetrics(Canvas.Handle, TM);
  FCapH := CapHeightOf(Canvas.Handle, TM);
  // Optical vertical centering (by the cap height, see CapHeightOf)
  FTextTop := (Height + FCapH) div 2 - TM.tmAscent;

  X := FBorderWidth + FPadding;
  for I := 0 to High(FSegments) do
  begin
    W := Canvas.TextWidth(SegmentText(FSegments[I]));
    FSegments[I].Area := Rect(X, FTextTop, X + W, FTextTop + TM.tmHeight);
    Inc(X, W);
  end;
end;

function TRoundDateTimePicker.SegmentAt(X: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FSegments) do
    if X < FSegments[I].Area.Right then
    begin
      Result := I;
      Break;
    end;
  if Result < 0 then
    Result := High(FSegments); // past the end: the last segment

  if (Result >= 0) and not IsEditable(FSegments[Result]) then
  begin
    // Clicked on a separator: use the next editable field, else the previous
    I := FindEditable(Result, 1);
    if I < 0 then
      I := FindEditable(Result, -1);
    Result := I;
  end;
end;

{ ---- value editing ---- }

function TRoundDateTimePicker.ClampToLimits(AValue: TDateTime): TDateTime;
var
  MaxLimit: TDateTime;
begin
  Result := AValue;
  if (FMinDate <> 0) and (Result < FMinDate) then
    Result := FMinDate;
  if FMaxDate <> 0 then
  begin
    MaxLimit := FMaxDate;
    if Frac(MaxLimit) = 0 then // a date without time: the whole day is allowed
      MaxLimit := MaxLimit + EncodeTime(23, 59, 59, 0);
    if Result > MaxLimit then
      Result := MaxLimit;
  end;
end;

procedure TRoundDateTimePicker.SetValueInternal(AValue: TDateTime; AClamp: Boolean);
begin
  if AClamp then
    AValue := ClampToLimits(AValue);
  if FDateTime <> AValue then
  begin
    FDateTime := AValue;
    Invalidate;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TRoundDateTimePicker.ApplyField(AField: TRoundPickerField;
  AValue: Integer; AClamp: Boolean);
var
  Y, M, D, H, N, S, MS, MaxDay: Word;
begin
  DecodeDateTime(FDateTime, Y, M, D, H, N, S, MS);
  case AField of
    pfDay:                D := Word(AValue);
    pfMonth, pfMonthName: M := Word(AValue);
    pfYear:               Y := Word(AValue);
    pfHour, pfHour12:     H := Word(AValue);
    pfMinute:             N := Word(AValue);
    pfSecond:             S := Word(AValue);
  else
    Exit;
  end;
  if Y < 1 then Y := 1;
  MaxDay := DaysInAMonth(Y, M);
  if D > MaxDay then D := MaxDay;
  SetValueInternal(EncodeDateTime(Y, M, D, H, N, S, MS), AClamp);
end;

procedure TRoundDateTimePicker.StepField(AField: TRoundPickerField; ADelta: Integer);
var
  Y, M, D, H, N, S, MS: Word;
begin
  DecodeDateTime(FDateTime, Y, M, D, H, N, S, MS);
  case AField of
    pfDay:     ApplyField(pfDay, WrapValue(D + ADelta, 1, DaysInAMonth(Y, M)), True);
    pfMonth, pfMonthName:
               ApplyField(pfMonth, WrapValue(M + ADelta, 1, 12), True);
    pfYear:    ApplyField(pfYear, EnsureRange(Y + ADelta, 1, 9999), True);
    pfHour, pfHour12:
               ApplyField(pfHour, WrapValue(H + ADelta, 0, 23), True);
    pfMinute:  ApplyField(pfMinute, WrapValue(N + ADelta, 0, 59), True);
    pfSecond:  ApplyField(pfSecond, WrapValue(S + ADelta, 0, 59), True);
    pfAmPm:    ApplyField(pfHour, (H + 12) mod 24, True);
  end;
end;

procedure TRoundDateTimePicker.StepActive(ADelta: Integer);
begin
  if not ValidSeg then Exit;
  FDigits := '';
  StepField(FSegments[FActiveSeg].Field, ADelta);
end;

procedure TRoundDateTimePicker.TypeDigit(ADigit: Integer);
var
  Seg: TRoundPickerSegment;
  Y, M, D, H, N, S, MS: Word;
  Buf: string;
  Cand, MinV, MaxV, Need, NewValue: Integer;
begin
  if not ValidSeg then Exit;
  Seg := FSegments[FActiveSeg];
  DecodeDateTime(FDateTime, Y, M, D, H, N, S, MS);

  Need := 2; // digits that complete the field
  case Seg.Field of
    pfDay:                begin MinV := 1; MaxV := DaysInAMonth(Y, M); end;
    pfMonth, pfMonthName: begin MinV := 1; MaxV := 12; end;
    pfYear:
      if Seg.Len = 2 then
      begin
        MinV := 0; MaxV := 99;
      end
      else
      begin
        MinV := 1; MaxV := 9999; Need := 4;
      end;
    pfHour:               begin MinV := 0; MaxV := 23; end;
    pfHour12:             begin MinV := 1; MaxV := 12; end;
    pfMinute, pfSecond:   begin MinV := 0; MaxV := 59; end;
  else
    Exit; // digits mean nothing for AM/PM
  end;

  // Append the digit; if the result is not valid for the field, start over
  // with just this digit (same as the standard date picker)
  Buf := FDigits + IntToStr(ADigit);
  Cand := StrToInt(Buf);
  if (Length(Buf) > Need) or (Cand > MaxV) then
  begin
    Buf := IntToStr(ADigit);
    Cand := ADigit;
  end;
  FDigits := Buf;

  // Limits (MinDate/MaxDate) are enforced when the field is committed, so
  // typing a year like 2026 digit by digit is not pushed around meanwhile
  if Cand >= MinV then
    case Seg.Field of
      pfDay:                ApplyField(pfDay, Cand, False);
      pfMonth, pfMonthName: ApplyField(pfMonth, Cand, False);
      pfYear:
        if Seg.Len = 2 then ApplyField(pfYear, (Y div 100) * 100 + Cand, False)
        else ApplyField(pfYear, Cand, False);
      pfHour:               ApplyField(pfHour, Cand, False);
      pfHour12:
        begin
          NewValue := Cand mod 12;
          if H >= 12 then Inc(NewValue, 12);
          ApplyField(pfHour, NewValue, False);
        end;
      pfMinute:             ApplyField(pfMinute, Cand, False);
      pfSecond:             ApplyField(pfSecond, Cand, False);
    end;

  // The field is complete when no further digit can extend it
  if (Length(FDigits) >= Need) or (Cand * 10 > MaxV) then
    MoveSegment(1);
end;

procedure TRoundDateTimePicker.SetAmPm(APm: Boolean);
var
  Y, M, D, H, N, S, MS: Word;
begin
  DecodeDateTime(FDateTime, Y, M, D, H, N, S, MS);
  if APm and (H < 12) then
    ApplyField(pfHour, H + 12, True)
  else if (not APm) and (H >= 12) then
    ApplyField(pfHour, H - 12, True);
end;

procedure TRoundDateTimePicker.CommitEdit;
begin
  FDigits := '';
  SetValueInternal(FDateTime, True); // applies MinDate/MaxDate
end;

procedure TRoundDateTimePicker.MoveSegment(ADir: Integer);
var
  Idx: Integer;
begin
  CommitEdit;
  if ValidSeg then
    Idx := FindEditable(FActiveSeg + ADir, ADir)
  else
    Idx := FindEditable(0, 1);
  if Idx >= 0 then
  begin
    FActiveSeg := Idx;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.PasteFromClipboard;
var
  Text: string;
  Value: TDateTime;
  Ok: Boolean;
begin
  Text := Trim(Clipboard.AsText);
  if Text = '' then Exit;
  case FKind of
    rdkTime:
      begin
        Ok := TryStrToTime(Text, Value);
        if Ok then SetValueInternal(Trunc(FDateTime) + Frac(Value), True);
      end;
    rdkDateTime:
      begin
        Ok := TryStrToDateTime(Text, Value);
        if Ok then SetValueInternal(Value, True);
      end;
  else
    Ok := TryStrToDate(Text, Value);
    if Ok then SetValueInternal(Trunc(Value) + Frac(FDateTime), True);
  end;
end;

procedure TRoundDateTimePicker.CopyToClipboard;
begin
  Clipboard.AsText := DisplayText;
end;

{ ---- calendar drop-down ---- }

procedure TRoundDateTimePicker.PrepareCalendar(AForm: TCustomForm);
begin
  if FCalendar = nil then
  begin
    FCalendar := TRoundCalendar.Create(Self);
    FCalendar.Visible := False;
    FCalendar.TabStop := False;      // it must never take the focus
    FCalendar.Transparent := True;   // the corners blend with what is behind
    FCalendar.OnSelect := CalendarSelect;
  end;
  if FCalendar.Parent <> AForm then
    FCalendar.Parent := AForm;

  // The calendar follows the style of the picker
  FCalendar.Font.Assign(Font);
  FCalendar.Radius := FRadius;
  FCalendar.BorderWidth := FBorderWidth;
  FCalendar.BorderColor := FBorderColor;
  FCalendar.FillColor := FFillColor;
  FCalendar.HoverColor := FHoverColor;
  FCalendar.SelectedColor := FFocusColor;
  FCalendar.TodayColor := FFocusColor;
  FCalendar.SelectedTextColor := FSelectedTextColor;
  FCalendar.FirstDayOfWeek := FFirstDayOfWeek;
  FCalendar.ShowToday := FShowToday;
  FCalendar.TodayCaption := FTodayCaption;
  FCalendar.FitToFont; // compact size for the picker's font
  FCalendar.MinDate := FMinDate;
  FCalendar.MaxDate := FMaxDate;
  FCalendar.Date := FDateTime;
end;

procedure TRoundDateTimePicker.DropDown;
var
  Form: TCustomForm;
  Origin: TPoint;
  X, Y: Integer;
begin
  if FDroppedDown or (csDesigning in ComponentState) or
     not HasButton or not Enabled then Exit;
  Form := GetParentForm(Self);
  if Form = nil then Exit;

  CommitEdit;
  PrepareCalendar(Form);

  // Below the picker; above it when there is no room below
  Origin := Form.ScreenToClient(ClientToScreen(Point(0, 0)));
  X := Origin.X;
  Y := Origin.Y + Height + 2;
  if (Y + FCalendar.Height > Form.ClientHeight) and
     (Origin.Y - FCalendar.Height - 2 >= 0) then
    Y := Origin.Y - FCalendar.Height - 2;
  if X + FCalendar.Width > Form.ClientWidth then
    X := Form.ClientWidth - FCalendar.Width;
  if X < 0 then X := 0;

  FCalendar.SetBounds(X, Y, FCalendar.Width, FCalendar.Height);
  FCalendar.Visible := True;
  FCalendar.BringToFront;
  FDroppedDown := True;
  Invalidate;
  if Assigned(FOnDropDown) then
    FOnDropDown(Self);
end;

procedure TRoundDateTimePicker.CloseUp;
begin
  if not FDroppedDown then Exit;
  FDroppedDown := False;
  if FCalendar <> nil then
    FCalendar.Visible := False;
  Invalidate;
  if Assigned(FOnCloseUp) then
    FOnCloseUp(Self);
end;

procedure TRoundDateTimePicker.CalendarSelect(Sender: TObject);
begin
  // Keep the time of day, take the date from the calendar
  SetValueInternal(Trunc(FCalendar.Date) + Frac(FDateTime), True);
  CloseUp;
end;

procedure TRoundDateTimePicker.CMCancelMode(var Msg: TCMCancelMode);
begin
  // A click on any other control closes the calendar
  if FDroppedDown and (Msg.Sender <> Self) and (Msg.Sender <> FCalendar) then
    CloseUp;
  inherited;
end;

procedure TRoundDateTimePicker.CMDialogKey(var Msg: TCMDialogKey);
begin
  // While the calendar is open, Esc/Enter belong to it (not to the dialog's
  // Cancel/Default buttons)
  if FDroppedDown and ((Msg.CharCode = VK_ESCAPE) or (Msg.CharCode = VK_RETURN)) then
  begin
    if Msg.CharCode = VK_ESCAPE then
      CloseUp
    else
      CalendarSelect(FCalendar);
    Msg.Result := 1;
  end
  else
    inherited;
end;

{ ---- painting ---- }

procedure TRoundDateTimePicker.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1; // Paint draws everything (avoids flicker)
end;

procedure TRoundDateTimePicker.PaintShapes;
var
  G: TGPGraphics;
  BorderCol, GlyphCol: TColor;
  Half: Single;
  R, BR: TRect;
begin
  if Focused or FDroppedDown then
    BorderCol := FFocusColor
  else
    BorderCol := FBorderColor;
  if Enabled then
    GlyphCol := Font.Color
  else
    GlyphCol := clGrayText;

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
        Height - FBorderWidth - 1, FRadius, BorderCol, FBorderWidth);

    // Selection of the active field
    if Focused and Enabled and ValidSeg then
    begin
      R := FSegments[FActiveSeg].Area;
      FillRoundRect(G, R.Left - 2, Height / 2 - FCapH / 2 - 4,
        R.Right - R.Left + 4, FCapH + 8, 4, FFocusColor);
    end;

    // Drop-down button
    if HasButton then
    begin
      BR := ButtonRect;
      if Enabled and (FHoverButton or FDroppedDown) then
        FillRoundRect(G, BR.Left + 2, BR.Top + 2, BR.Right - BR.Left - 4,
          BR.Bottom - BR.Top - 4, 6, FHoverColor);
      DrawCalendarGlyph(G, (BR.Left + BR.Right) / 2, (BR.Top + BR.Bottom) / 2, GlyphCol);
    end;
  finally
    G.Free;
  end;
end;

procedure TRoundDateTimePicker.PaintText;
var
  I: Integer;
  S: string;
begin
  Canvas.Font.Assign(Font);
  Canvas.Brush.Style := bsClear;
  for I := 0 to High(FSegments) do
  begin
    S := SegmentText(FSegments[I]);
    if not Enabled then
      Canvas.Font.Color := clGrayText
    else if Focused and (I = FActiveSeg) then
      Canvas.Font.Color := FSelectedTextColor
    else
      Canvas.Font.Color := Font.Color;
    Canvas.TextOut(FSegments[I].Area.Left, FSegments[I].Area.Top, S);
  end;
end;

procedure TRoundDateTimePicker.Paint;
begin
  // Painting our own background makes the parent paint its children, us
  // included: skip that nested request
  if IsPaintingBackgroundOf(Self) then Exit;

  PaintControlBackground(Self, Canvas.Handle, FTransparent);
  LayoutSegments;
  PaintShapes;
  PaintText;
end;

{ ---- focus ---- }

procedure TRoundDateTimePicker.DoEnter;
begin
  if not ValidSeg then
    FActiveSeg := FindEditable(0, 1);
  Invalidate;
  inherited;
end;

procedure TRoundDateTimePicker.DoExit;
begin
  CommitEdit;
  CloseUp;
  Invalidate;
  inherited;
end;

{ ---- mouse ---- }

procedure TRoundDateTimePicker.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Idx: Integer;
begin
  inherited;
  if (Button <> mbLeft) or (csDesigning in ComponentState) then Exit;
  if CanFocus and not Focused then
    SetFocus;

  if HasButton and PtInRect(ButtonRect, Point(X, Y)) then
  begin
    if FDroppedDown then CloseUp else DropDown;
    Exit;
  end;

  if FDroppedDown then
    CloseUp;
  Idx := SegmentAt(X);
  if Idx >= 0 then
  begin
    CommitEdit;
    FActiveSeg := Idx;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Inside: Boolean;
begin
  inherited;
  Inside := HasButton and PtInRect(ButtonRect, Point(X, Y));
  if Inside <> FHoverButton then
  begin
    FHoverButton := Inside;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if FHoverButton then
  begin
    FHoverButton := False;
    Invalidate;
  end;
end;

function TRoundDateTimePicker.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if (not Result) and Focused and Enabled and (not FDroppedDown) and ValidSeg then
  begin
    StepActive(Sign(WheelDelta));
    Result := True;
  end;
end;

{ ---- keyboard ---- }

procedure TRoundDateTimePicker.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  inherited;
  Msg.Result := Msg.Result or DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

procedure TRoundDateTimePicker.KeyDown(var Key: Word; Shift: TShiftState);
var
  Idx: Integer;
begin
  inherited KeyDown(Key, Shift);
  if Key = 0 then Exit;

  if FDroppedDown then
  begin
    // Keys go to the calendar
    if (Key = VK_ESCAPE) or (Key = VK_F4) or ((Key = VK_UP) and (ssAlt in Shift)) then
    begin
      CloseUp;
      Key := 0;
    end
    else
      FCalendar.ProcessKey(Key, Shift);
    Exit;
  end;

  if ssCtrl in Shift then
  begin
    if Key = Ord('V') then
    begin
      PasteFromClipboard;
      Key := 0;
    end
    else if Key = Ord('C') then
    begin
      CopyToClipboard;
      Key := 0;
    end;
    Exit;
  end;

  case Key of
    VK_F4:
      begin
        DropDown;
        Key := 0;
      end;
    VK_DOWN:
      begin
        if ssAlt in Shift then DropDown else StepActive(-1);
        Key := 0;
      end;
    VK_UP:
      begin
        StepActive(1);
        Key := 0;
      end;
    VK_LEFT:
      begin
        MoveSegment(-1);
        Key := 0;
      end;
    VK_RIGHT:
      begin
        MoveSegment(1);
        Key := 0;
      end;
    VK_HOME, VK_END:
      begin
        CommitEdit;
        if Key = VK_HOME then Idx := FindEditable(0, 1)
        else Idx := FindEditable(High(FSegments), -1);
        if Idx >= 0 then
        begin
          FActiveSeg := Idx;
          Invalidate;
        end;
        Key := 0;
      end;
  end;
end;

procedure TRoundDateTimePicker.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if (Key >= '0') and (Key <= '9') then
  begin
    if FDroppedDown then CloseUp;
    TypeDigit(Ord(Key) - Ord('0'));
    Key := #0;
  end
  else if CharInSet(Key, ['/', '.', '-', ':', ' ', ',']) then
  begin
    // A separator moves on to the next field, so a date can be typed as it
    // reads ("5/10/2026")
    if FDroppedDown then CloseUp;
    MoveSegment(1);
    Key := #0;
  end
  else if CharInSet(Key, ['a', 'A', 'p', 'P']) and ValidSeg and
          (FSegments[FActiveSeg].Field = pfAmPm) then
  begin
    SetAmPm(CharInSet(Key, ['p', 'P']));
    Key := #0;
  end;
end;

{ ---- misc messages ---- }

procedure TRoundDateTimePicker.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if not Enabled then
    CloseUp;
  Invalidate;
end;

procedure TRoundDateTimePicker.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

{ ---- property setters ---- }

procedure TRoundDateTimePicker.ChangeColor(var Field: TColor; const Value: TColor);
begin
  if Field <> Value then
  begin
    Field := Value;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetDateTime(const Value: TDateTime);
begin
  FDigits := '';
  SetValueInternal(Value, True);
end;

procedure TRoundDateTimePicker.SetKind(const Value: TRoundDateTimeKind);
begin
  if FKind <> Value then
  begin
    CloseUp;
    FKind := Value;
    BuildSegments;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetFormat(const Value: string);
begin
  if FFormat <> Value then
  begin
    FFormat := Value;
    BuildSegments;
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetMinDate(const Value: TDateTime);
begin
  FMinDate := Value;
  SetValueInternal(FDateTime, True);
end;

procedure TRoundDateTimePicker.SetMaxDate(const Value: TDateTime);
begin
  FMaxDate := Value;
  SetValueInternal(FDateTime, True);
end;

function TRoundDateTimePicker.IsMinDateStored: Boolean;
begin
  Result := FMinDate <> 0;
end;

function TRoundDateTimePicker.IsMaxDateStored: Boolean;
begin
  Result := FMaxDate <> 0;
end;

function TRoundDateTimePicker.IsFirstDayStored: Boolean;
begin
  Result := FFirstDayOfWeek <> LocaleFirstDayOfWeek;
end;

function TRoundDateTimePicker.GetDate: TDate;
begin
  Result := DateOf(FDateTime);
end;

procedure TRoundDateTimePicker.SetDate(const Value: TDate);
begin
  SetDateTime(Trunc(Value) + Frac(FDateTime));
end;

function TRoundDateTimePicker.GetTime: TTime;
begin
  Result := TimeOf(FDateTime);
end;

procedure TRoundDateTimePicker.SetTime(const Value: TTime);
begin
  SetDateTime(Trunc(FDateTime) + Frac(Value));
end;

procedure TRoundDateTimePicker.SetRadius(const Value: Integer);
begin
  if FRadius <> Max(0, Value) then
  begin
    FRadius := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetBorderWidth(const Value: Integer);
begin
  if FBorderWidth <> Max(0, Value) then
  begin
    FBorderWidth := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetPadding(const Value: Integer);
begin
  if FPadding <> Max(0, Value) then
  begin
    FPadding := Max(0, Value);
    Invalidate;
  end;
end;

procedure TRoundDateTimePicker.SetBorderColor(const Value: TColor);
begin
  ChangeColor(FBorderColor, Value);
end;

procedure TRoundDateTimePicker.SetFocusColor(const Value: TColor);
begin
  ChangeColor(FFocusColor, Value);
end;

procedure TRoundDateTimePicker.SetFillColor(const Value: TColor);
begin
  ChangeColor(FFillColor, Value);
end;

procedure TRoundDateTimePicker.SetHoverColor(const Value: TColor);
begin
  ChangeColor(FHoverColor, Value);
end;

procedure TRoundDateTimePicker.SetSelectedTextColor(const Value: TColor);
begin
  ChangeColor(FSelectedTextColor, Value);
end;

procedure TRoundDateTimePicker.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    Invalidate;
  end;
end;

end.
