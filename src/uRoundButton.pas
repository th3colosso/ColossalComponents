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
  System.Classes, System.SysUtils, System.Types, Vcl.ImgList,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Forms, Vcl.Menus,
 System.UITypes;

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
    FTransparent: Boolean;
    FImages: TCustomImageList;
    FImageIndex: TImageIndex;
    FImageAlignment: TImageAlignment;
    FSpacing: Integer;
    FImageChangeLink: TChangeLink;
    procedure SetRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFocusColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetPressedColor(const Value: TColor);
    procedure SetDisabledColor(const Value: TColor);
    procedure SetDefault(const Value: Boolean);
    procedure SetTransparent(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImageAlignment(const Value: TImageAlignment);
    procedure SetSpacing(const Value: Integer);
    procedure ImageListChange(Sender: TObject);
    function HasImage: Boolean;
    procedure ChangeColor(var Field: TColor; const Value: TColor);
    function CurrentState: TRoundButtonState;
    function StateFillColor(AState: TRoundButtonState): TColor;
    function StateBorderColor(AState: TRoundButtonState): TColor;
    function CreateFramePath: TGPGraphicsPath;
    procedure PaintParentBackground;
    procedure PaintFrame(AFillColor, ABorderColor: TColor);
    procedure PaintContent(AState: TRoundButtonState);
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
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateWnd; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property ImageAlignment: TImageAlignment read FImageAlignment write SetImageAlignment default iaLeft;
    property Spacing: Integer read FSpacing write SetSpacing default 8;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
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
  System.Math, uColossalDraw;

procedure Register;
begin
  RegisterComponents('Colossal Controls', [TRoundButton]);
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
  FImageIndex := -1;
  FImageAlignment := iaLeft;
  FSpacing := 8;
  FTransparent := False;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
end;

destructor TRoundButton.Destroy;
begin
  FImageChangeLink.Free; // also unregisters itself from the image list
  inherited;
end;

procedure TRoundButton.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  // The image list was destroyed: drop the dangling reference
  if (Operation = opRemove) and (AComponent = FImages) then
    SetImages(nil);
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
  // Transparent: paints what is behind the button (parent + siblings below)
  // so the rounded corners blend with it. Otherwise: the parent's color.
  PaintControlBackground(Self, Canvas.Handle, FTransparent);
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

function TRoundButton.HasImage: Boolean;
begin
  Result := (FImages <> nil) and (FImageIndex >= 0) and (FImageIndex < FImages.Count);
end;

procedure TRoundButton.PaintContent(AState: TRoundButtonState);
var
  Text: string;
  Format: TTextFormat;
  TM: TTextMetric;
  Content, TextBox, Measure: TRect;
  CapH, ImgW, ImgH, ImgX, ImgY: Integer;
  TextW, TextH, TextTop, AvailW, GroupW, GroupH, X0, Y0, Gap: Integer;
  ShowImage, ShowText: Boolean;
begin
  Text := Caption;
  ShowImage := HasImage;
  ShowText := Text <> '';
  if not (ShowImage or ShowText) then Exit;

  Canvas.Font.Assign(Font);
  if AState = rbsDisabled then
    Canvas.Font.Color := clGrayText;
  Canvas.Brush.Style := bsClear;

  // TextHeight forces the font to be selected into the canvas DC
  Canvas.TextHeight('Hg');
  GetTextMetrics(Canvas.Handle, TM);
  CapH := CapHeightOf(Canvas.Handle, TM);

  Content := Rect(FBorderWidth + 4, 0, Width - FBorderWidth - 4, Height);
  AvailW := Max(0, Content.Right - Content.Left);

  ImgW := 0;
  ImgH := 0;
  if ShowImage then
  begin
    ImgW := FImages.Width;
    ImgH := FImages.Height;
  end;

  TextW := 0;
  if ShowText then
  begin
    Measure := Rect(0, 0, 0, 0);
    Canvas.TextRect(Measure, Text, [tfCalcRect, tfSingleLine]);
    TextW := Measure.Right - Measure.Left;
  end;

  if ShowImage and ShowText then
    Gap := FSpacing
  else
    Gap := 0;

  // Default (no image): optical vertical centering. Center the body of the
  // text (the height of a capital letter above the baseline) instead of the
  // whole line box, which also contains the descender and internal leading
  // and makes the text look low. DT_VCENTER is not used because it pins text
  // taller than the rect to the top.
  TextTop := (Height + CapH) div 2 - TM.tmAscent;
  TextBox := Rect(Content.Left, TextTop, Content.Right, TextTop + TM.tmHeight);
  ImgX := 0;
  ImgY := 0;

  if ShowImage then
    case FImageAlignment of
      iaLeft, iaRight:
        begin
          // [image][gap][text], the whole group centered horizontally
          TextW := Min(TextW, Max(0, AvailW - ImgW - Gap));
          GroupW := ImgW + Gap + TextW;
          X0 := Content.Left + (AvailW - GroupW) div 2;
          ImgY := (Height - ImgH) div 2;
          if FImageAlignment = iaLeft then
          begin
            ImgX := X0;
            TextBox.Left := X0 + ImgW + Gap;
          end
          else
          begin
            TextBox.Left := X0;
            ImgX := X0 + TextW + Gap;
          end;
          TextBox.Right := TextBox.Left + TextW;
        end;
      iaTop, iaBottom:
        begin
          // image above/below the text, the whole group centered vertically
          if ShowText then TextH := TM.tmHeight else TextH := 0;
          GroupH := ImgH + Gap + TextH;
          Y0 := (Height - GroupH) div 2;
          ImgX := Content.Left + (AvailW - ImgW) div 2;
          if FImageAlignment = iaTop then
          begin
            ImgY := Y0;
            TextTop := Y0 + ImgH + Gap;
          end
          else
          begin
            TextTop := Y0;
            ImgY := Y0 + TextH + Gap;
          end;
          TextBox := Rect(Content.Left, TextTop, Content.Right, TextTop + TM.tmHeight);
        end;
      iaCenter:
        begin
          // image centered, caption (if any) drawn on top like TButton does
          ImgX := Content.Left + (AvailW - ImgW) div 2;
          ImgY := (Height - ImgH) div 2;
        end;
    end;

  if ShowImage then
    FImages.Draw(Canvas, ImgX, ImgY, FImageIndex, Enabled);

  if ShowText then
  begin
    // tfNoClip: oversized text must not be cut off by the line-box rect
    Format := [tfCenter, tfSingleLine, tfEndEllipsis, tfNoClip];
    // Underline the accelerator only when Windows says it should be visible
    if (Perform(WM_QUERYUISTATE, 0, 0) and UISF_HIDEACCEL) <> 0 then
      Include(Format, tfHidePrefix);
    Canvas.TextRect(TextBox, Text, Format);
  end;
end;

procedure TRoundButton.Paint;
var
  State: TRoundButtonState;
begin
  // Painting our own background makes the parent paint its children, us
  // included: skip that nested request
  if IsPaintingBackgroundOf(Self) then Exit;

  State := CurrentState;
  PaintParentBackground;
  PaintFrame(StateFillColor(State), StateBorderColor(State));
  PaintContent(State);
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

procedure TRoundButton.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    Invalidate;
  end;
end;

procedure TRoundButton.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then Exit;
  if FImages <> nil then
    FImages.UnRegisterChanges(FImageChangeLink);
  FImages := Value;
  if FImages <> nil then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
  Invalidate;
end;

procedure TRoundButton.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Invalidate;
  end;
end;

procedure TRoundButton.SetImageAlignment(const Value: TImageAlignment);
begin
  if FImageAlignment <> Value then
  begin
    FImageAlignment := Value;
    Invalidate;
  end;
end;

procedure TRoundButton.SetSpacing(const Value: Integer);
var
  NewValue: Integer;
begin
  NewValue := Max(0, Value);
  if FSpacing <> NewValue then
  begin
    FSpacing := NewValue;
    Invalidate;
  end;
end;

procedure TRoundButton.ImageListChange(Sender: TObject);
begin
  Invalidate; // the image list content or size changed
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
