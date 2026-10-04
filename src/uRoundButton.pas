unit uRoundButton;

{ TRoundButton - Button with rounded, anti-aliased corners drawn with GDI+.

  A self-painted TCustomControl (no inner TButton), so the frame, the state
  colors and the caption are all drawn by the component itself.

  Behaves like a regular button:
    - States: normal, hover, pressed, disabled (+ focus/default highlight)
    - Mouse and keyboard (Space), Default (Enter) and Cancel (Esc) buttons
    - Accelerator keys through '&' in the caption (e.g. '&Save')
    - ModalResult }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Forms, Vcl.Menus;

type
  TRoundButtonState = (rbsNormal, rbsHover, rbsPressed, rbsDisabled);

  TRoundButton = class(TCustomControl)
  private
    FRadius: Integer;
    FBorderWidth: Integer;
    FBorderColor: TColor;
    FFocusColor: TColor;
    FFillColor: TColor;
    FHoverColor: TColor;
    FPressedColor: TColor;
    FDisabledColor: TColor;
    FModalResult: TModalResult;
    FDefault: Boolean;
    FCancel: Boolean;
    FActive: Boolean;      // True when Enter should "click" this button
    FMouseInside: Boolean;
    FMouseDown: Boolean;
    FKeyDown: Boolean;
    procedure SetRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFocusColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetPressedColor(const Value: TColor);
    procedure SetDisabledColor(const Value: TColor);
    procedure SetDefault(const Value: Boolean);
    procedure ChangeColor(var Field: TColor; const Value: TColor);
    function CurrentState: TRoundButtonState;
    function StateFillColor(AState: TRoundButtonState): TColor;
    function StateBorderColor(AState: TRoundButtonState): TColor;
    function CreateFramePath: TGPGraphicsPath;
    procedure PaintParentBackground;
    procedure PaintFrame(AFillColor, ABorderColor: TColor);
    procedure PaintCaption(AState: TRoundButtonState);
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure CMFocusChanged(var Msg: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMDialogChar(var Msg: TCMDialogChar); message CM_DIALOGCHAR;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMLButtonDblClk(var Msg: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMUpdateUIState(var Msg: TMessage); message WM_UPDATEUISTATE;
  protected
    procedure Paint; override;
    procedure CreateWnd; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
  published
    property Caption;
    property Radius: Integer read FRadius write SetRadius default 10;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00ADADAD;
    property FocusColor: TColor read FFocusColor write SetFocusColor default $00D77800;
    property FillColor: TColor read FFillColor write SetFillColor default $00E1E1E1;
    property HoverColor: TColor read FHoverColor write SetHoverColor default $00FBF1E5;
    property PressedColor: TColor read FPressedColor write SetPressedColor default $00F7E4CC;
    property DisabledColor: TColor read FDisabledColor write SetDisabledColor default $00CCCCCC;
    property Default: Boolean read FDefault write SetDefault default False;
    property Cancel: Boolean read FCancel write FCancel default False;
    property ModalResult: TModalResult read FModalResult write FModalResult default 0;
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
    property Width default 100;
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
  System.Math;

function ToARGB(C: TColor; Alpha: Byte = 255): ARGB;
var
  RGB: Cardinal;
begin
  RGB := ColorToRGB(C);
  Result := MakeColor(Alpha, GetRValue(RGB), GetGValue(RGB), GetBValue(RGB));
end;

procedure Register;
begin
  RegisterComponents('Colossal Controls', [TRoundButton]);
end;

function CapHeightOf(DC: HDC; const TM: TTextMetric): Integer;
var
  GM: TGlyphMetrics;
  Mat: TMat2;
begin
  // Real height of a capital letter above the baseline in the font currently
  // selected into DC (identity matrix = no transform).
  FillChar(Mat, SizeOf(Mat), 0);
  Mat.eM11.value := 1;
  Mat.eM22.value := 1;
  if GetGlyphOutline(DC, Ord('H'), GGO_METRICS, GM, 0, nil, Mat) <> GDI_ERROR then
    Result := GM.gmptGlyphOrigin.Y
  else
    Result := TM.tmAscent - TM.tmInternalLeading; // bitmap fonts etc.
end;

{ TRoundButton }

constructor TRoundButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csOpaque, csAcceptsControls] + [csSetCaption];
  DoubleBuffered := True;
  TabStop := True;
  Width := 100;
  Height := 32;
  FRadius := 10;
  FBorderWidth := 1;
  FBorderColor := $00ADADAD;
  FFocusColor := $00D77800;
  FFillColor := $00E1E1E1;
  FHoverColor := $00FBF1E5;
  FPressedColor := $00F7E4CC;
  FDisabledColor := $00CCCCCC;
end;

procedure TRoundButton.CreateWnd;
begin
  inherited;
  FActive := FDefault;
end;

{ ---- state ---- }

function TRoundButton.CurrentState: TRoundButtonState;
begin
  if not Enabled then
    Result := rbsDisabled
  else if (FMouseDown and FMouseInside) or FKeyDown then
    Result := rbsPressed
  else if FMouseInside then
    Result := rbsHover
  else
    Result := rbsNormal;
end;

function TRoundButton.StateFillColor(AState: TRoundButtonState): TColor;
begin
  case AState of
    rbsHover:    Result := FHoverColor;
    rbsPressed:  Result := FPressedColor;
    rbsDisabled: Result := FDisabledColor;
  else
    Result := FFillColor;
  end;
end;

function TRoundButton.StateBorderColor(AState: TRoundButtonState): TColor;
begin
  // Hover, pressed, keyboard focus and the active default button all use
  // FocusColor, so the accent color is configurable in a single place.
  if (AState in [rbsHover, rbsPressed]) or ((AState <> rbsDisabled) and (Focused or FActive)) then
    Result := FFocusColor
  else
    Result := FBorderColor;
end;

{ ---- painting ---- }

procedure TRoundButton.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1; // Paint draws everything (avoids flicker)
end;

function TRoundButton.CreateFramePath: TGPGraphicsPath;
var
  X, Y, W, H, D: Single;
begin
  // Same geometry as TRoundEdit so both controls line up visually
  X := FBorderWidth / 2;
  Y := X;
  W := Width - FBorderWidth - 1;
  H := Height - FBorderWidth - 1;
  D := FRadius * 2;
  if D > H then D := H;
  if D > W then D := W;

  Result := TGPGraphicsPath.Create;
  if D <= 0 then
    Result.AddRectangle(MakeRect(X, Y, W, H))
  else
  begin
    Result.AddArc(X, Y, D, D, 180, 90);                 // top left
    Result.AddArc(X + W - D, Y, D, D, 270, 90);         // top right
    Result.AddArc(X + W - D, Y + H - D, D, D, 0, 90);   // bottom right
    Result.AddArc(X, Y + H - D, D, D, 90, 90);          // bottom left
    Result.CloseFigure;
  end;
end;

procedure TRoundButton.PaintParentBackground;
begin
  // Paint the parent's color so the corners blend with the background
  if Parent <> nil then
    Canvas.Brush.Color := Parent.Brush.Color
  else
    Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(ClientRect);
end;

procedure TRoundButton.PaintFrame(AFillColor, ABorderColor: TColor);
var
  G: TGPGraphics;
  Path: TGPGraphicsPath;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
begin
  G := nil;
  Path := nil;
  Brush := nil;
  Pen := nil;
  try
    G := TGPGraphics.Create(Canvas.Handle);
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHalf);

    Path := CreateFramePath;
    Brush := TGPSolidBrush.Create(ToARGB(AFillColor));
    G.FillPath(Brush, Path);

    if FBorderWidth > 0 then
    begin
      Pen := TGPPen.Create(ToARGB(ABorderColor), FBorderWidth);
      G.DrawPath(Pen, Path);
    end;
  finally
    Pen.Free;
    Brush.Free;
    Path.Free;
    G.Free;
  end;
end;

procedure TRoundButton.PaintCaption(AState: TRoundButtonState);
var
  R: TRect;
  Text: string;
  Format: TTextFormat;
  TM: TTextMetric;
  CapH, Baseline: Integer;
begin
  Text := Caption;
  if Text = '' then Exit;

  Canvas.Font.Assign(Font);
  if AState = rbsDisabled then
    Canvas.Font.Color := clGrayText;
  Canvas.Brush.Style := bsClear;

  // Optical vertical centering: center the body of the text (the height of a
  // capital letter above the baseline) instead of the whole line box, which
  // also contains the descender and internal leading and makes the text look
  // low. DT_VCENTER is not used because it pins text taller than the rect to
  // the top. TextHeight forces the font to be selected into the canvas DC.
  Canvas.TextHeight(Text);
  GetTextMetrics(Canvas.Handle, TM);
  CapH := CapHeightOf(Canvas.Handle, TM);
  Baseline := (Height + CapH) div 2;
  R := Rect(FBorderWidth + 4, Baseline - TM.tmAscent,
    Width - FBorderWidth - 4, Baseline - TM.tmAscent + TM.tmHeight);

  // tfNoClip: oversized text must not be cut off by the line-box rect
  Format := [tfCenter, tfSingleLine, tfEndEllipsis, tfNoClip];
  // Underline the accelerator only when Windows says it should be visible
  if (Perform(WM_QUERYUISTATE, 0, 0) and UISF_HIDEACCEL) <> 0 then
    Include(Format, tfHidePrefix);

  Canvas.TextRect(R, Text, Format);
end;

procedure TRoundButton.Paint;
var
  State: TRoundButtonState;
begin
  State := CurrentState;
  PaintParentBackground;
  PaintFrame(StateFillColor(State), StateBorderColor(State));
  PaintCaption(State);
end;

{ ---- mouse ---- }

procedure TRoundButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FMouseInside := True;
  Invalidate;
end;

procedure TRoundButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FMouseInside := False;
  Invalidate;
end;

procedure TRoundButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    if CanFocus and not Focused then
      SetFocus;
    FMouseDown := True;
    Invalidate;
  end;
end;

procedure TRoundButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FMouseDown := False;
    Invalidate;
  end;
end;

procedure TRoundButton.WMLButtonDblClk(var Msg: TWMLButtonDblClk);
begin
  // Treat a double click as a second regular click, otherwise fast
  // clicking would swallow every other click (same as TButton).
  Perform(WM_LBUTTONDOWN, Msg.Keys, MakeLParam(Word(Msg.XPos), Word(Msg.YPos)));
end;

{ ---- keyboard / dialog ---- }

procedure TRoundButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_SPACE) and (Shift = []) then
  begin
    FKeyDown := True;
    Invalidate;
    Key := 0;
  end;
end;

procedure TRoundButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if (Key = VK_SPACE) and FKeyDown then
  begin
    FKeyDown := False;
    Key := 0;
    Click;
  end;
end;

procedure TRoundButton.DoExit;
begin
  FKeyDown := False;
  Invalidate;
  inherited;
end;

procedure TRoundButton.CMFocusChanged(var Msg: TCMFocusChanged);
begin
  // The default button stays "active" while the focus is on any control that
  // is not a button; a focused button takes the Enter key for itself.
  if (Msg.Sender is TRoundButton) or (Msg.Sender is TButton) then
    FActive := Msg.Sender = Self
  else
    FActive := FDefault;
  inherited;
  Invalidate;
end;

procedure TRoundButton.CMDialogKey(var Msg: TCMDialogKey);
begin
  if (((Msg.CharCode = VK_RETURN) and FActive) or
      ((Msg.CharCode = VK_ESCAPE) and FCancel)) and
     (KeyDataToShiftState(Msg.KeyData) = []) and CanFocus then
  begin
    Click;
    Msg.Result := 1;
  end
  else
    inherited;
end;

procedure TRoundButton.CMDialogChar(var Msg: TCMDialogChar);
begin
  if IsAccel(Msg.CharCode, Caption) and CanFocus then
  begin
    Click;
    Msg.Result := 1;
  end
  else
    inherited;
end;

procedure TRoundButton.Click;
var
  Form: TCustomForm;
begin
  // Go back to the released look before handlers run: a handler may show a
  // modal dialog, and the button must not stay painted as "pressed".
  FMouseDown := False;
  FKeyDown := False;
  Repaint;

  Form := GetParentForm(Self);
  if Form <> nil then
    Form.ModalResult := FModalResult;
  inherited Click;
end;

{ ---- misc messages ---- }

procedure TRoundButton.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FMouseDown := False;
    FKeyDown := False;
  end;
  Invalidate;
end;

procedure TRoundButton.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TRoundButton.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TRoundButton.WMUpdateUIState(var Msg: TMessage);
begin
  inherited;
  Invalidate; // accelerator underline may have appeared/disappeared
end;

{ ---- property setters ---- }

procedure TRoundButton.ChangeColor(var Field: TColor; const Value: TColor);
begin
  if Field <> Value then
  begin
    Field := Value;
    Invalidate;
  end;
end;

procedure TRoundButton.SetRadius(const Value: Integer);
var
  NewValue: Integer;
begin
  NewValue := Max(0, Value);
  if FRadius <> NewValue then
  begin
    FRadius := NewValue;
    Invalidate;
  end;
end;

procedure TRoundButton.SetBorderWidth(const Value: Integer);
var
  NewValue: Integer;
begin
  NewValue := Max(0, Value);
  if FBorderWidth <> NewValue then
  begin
    FBorderWidth := NewValue;
    Invalidate;
  end;
end;

procedure TRoundButton.SetBorderColor(const Value: TColor);
begin
  ChangeColor(FBorderColor, Value);
end;

procedure TRoundButton.SetFocusColor(const Value: TColor);
begin
  ChangeColor(FFocusColor, Value);
end;

procedure TRoundButton.SetFillColor(const Value: TColor);
begin
  ChangeColor(FFillColor, Value);
end;

procedure TRoundButton.SetHoverColor(const Value: TColor);
begin
  ChangeColor(FHoverColor, Value);
end;

procedure TRoundButton.SetPressedColor(const Value: TColor);
begin
  ChangeColor(FPressedColor, Value);
end;

procedure TRoundButton.SetDisabledColor(const Value: TColor);
begin
  ChangeColor(FDisabledColor, Value);
end;

procedure TRoundButton.SetDefault(const Value: Boolean);
var
  Form: TCustomForm;
begin
  if FDefault = Value then Exit;
  FDefault := Value;
  if HandleAllocated then
  begin
    // Make the form re-evaluate which button is "active"
    Form := GetParentForm(Self);
    if Form <> nil then
      Form.Perform(CM_FOCUSCHANGED, 0, LPARAM(Form.ActiveControl));
  end;
end;

end.
