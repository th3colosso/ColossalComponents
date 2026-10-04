unit uRoundEdit;

{ TRoundEdit - Edit with rounded, anti-aliased corners drawn with GDI+.
  Works as a "container": it draws the frame with GDI+ and hosts a borderless
  TEdit inside it. }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Forms, Vcl.Menus;

type
  TRoundEdit = class(TCustomControl)
  private
    FEdit: TEdit;
    FRadius: Integer;
    FBorderWidth: Integer;
    FBorderColor: TColor;
    FFocusColor: TColor;
    FFillColor: TColor;
    FPadding: Integer;
    FTransparent: Boolean;
    FMouseInside: Boolean;
    FOnChange: TNotifyEvent;
    function GetText: string;
    procedure SetText(const Value: string);
    procedure SetRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFocusColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetPadding(const Value: Integer);
    procedure SetTransparent(const Value: Boolean);
    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure EditClick(Sender: TObject);
    procedure EditDblClick(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditKeyPress(Sender: TObject; var Key: Char);
    procedure EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EditMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure EditMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure EditMouseEnter(Sender: TObject);
    procedure EditMouseLeave(Sender: TObject);
    procedure EditContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    function CursorInside: Boolean;
    procedure LayoutEdit;
    function MeasureTextHeight: Integer;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Edit: TEdit read FEdit; // access to PasswordChar, OnChange, etc.
  published
    property Text: string read GetText write SetText;
    property Radius: Integer read FRadius write SetRadius default 10;
    property BorderWidth: Integer read FBorderWidth write SetBorderWidth default 1;
    property BorderColor: TColor read FBorderColor write SetBorderColor default $00C0C0C0;
    property FocusColor: TColor read FFocusColor write SetFocusColor default $00D77800;
    property FillColor: TColor read FFillColor write SetFillColor default clWhite;
    property Padding: Integer read FPadding write SetPadding default 8;
    property Transparent: Boolean read FTransparent write SetTransparent default False;
    property Align;
    property Anchors;
    property Font;
    property Height default 32;
    property Width default 200;
    property TabOrder;
    property Visible;
    property Enabled;
    property Margins;
    property AlignWithMargins;
    property PopupMenu;
    // Events of the inner edit are forwarded to these, so they fire as if
    // the focus and the mouse were on the TRoundEdit itself.
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
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
  uColossalDraw;

procedure Register;
begin
  RegisterComponents('Colossal Controls', [TRoundEdit]);
end;

{ TRoundEdit }

constructor TRoundEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // csAcceptsControls removed: the designer does not allow dropping other
  // components inside TRoundEdit
  ControlStyle := ControlStyle - [csOpaque, csAcceptsControls];
  DoubleBuffered := True;
  Width := 200;
  Height := 32;
  FRadius := 10;
  FBorderWidth := 1;
  FBorderColor := $00C0C0C0;
  FFocusColor := $00D77800;
  FFillColor := clWhite;
  FPadding := 8;
  FTransparent := False;

  FEdit := TEdit.Create(Self);
  FEdit.Name := 'InnerEdit';
  FEdit.SetSubComponent(True);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.AutoSize := False;
  FEdit.Color := FFillColor;
  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
  FEdit.OnChange := EditChange;
  FEdit.OnClick := EditClick;
  FEdit.OnDblClick := EditDblClick;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.OnKeyPress := EditKeyPress;
  FEdit.OnKeyUp := EditKeyUp;
  FEdit.OnMouseDown := EditMouseDown;
  FEdit.OnMouseMove := EditMouseMove;
  FEdit.OnMouseUp := EditMouseUp;
  FEdit.OnMouseEnter := EditMouseEnter;
  FEdit.OnMouseLeave := EditMouseLeave;
  FEdit.OnContextPopup := EditContextPopup;
  LayoutEdit;
end;

procedure TRoundEdit.CreateWnd;
begin
  inherited;
  LayoutEdit;
end;

procedure TRoundEdit.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1; // Paint draws everything (avoids flicker)
end;

{ ---- inner edit events, forwarded to the TRoundEdit events ---- }

procedure TRoundEdit.EditEnter(Sender: TObject);
begin
  Invalidate; // focus color
  DoEnter;
end;

procedure TRoundEdit.EditExit(Sender: TObject);
begin
  Invalidate; // back to the normal border color
  DoExit;
end;

procedure TRoundEdit.EditChange(Sender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TRoundEdit.EditClick(Sender: TObject);
begin
  Click;
end;

procedure TRoundEdit.EditDblClick(Sender: TObject);
begin
  DblClick;
end;

procedure TRoundEdit.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  KeyDown(Key, Shift);
end;

procedure TRoundEdit.EditKeyPress(Sender: TObject; var Key: Char);
begin
  KeyPress(Key);
end;

procedure TRoundEdit.EditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  KeyUp(Key, Shift);
end;

procedure TRoundEdit.EditMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Coordinates are translated from the inner edit to the TRoundEdit
  MouseDown(Button, Shift, X + FEdit.Left, Y + FEdit.Top);
end;

procedure TRoundEdit.EditMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  MouseMove(Shift, X + FEdit.Left, Y + FEdit.Top);
end;

procedure TRoundEdit.EditMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseUp(Button, Shift, X + FEdit.Left, Y + FEdit.Top);
end;

function TRoundEdit.CursorInside: Boolean;
begin
  Result := ClientRect.Contains(ScreenToClient(Mouse.CursorPos));
end;

procedure TRoundEdit.CMMouseEnter(var Msg: TMessage);
begin
  // The inner edit sits on top of the TRoundEdit, so moving between the two
  // would report a leave + enter pair. Track "inside" for the whole control.
  if not FMouseInside then
  begin
    FMouseInside := True;
    inherited;
  end;
end;

procedure TRoundEdit.CMMouseLeave(var Msg: TMessage);
begin
  // Ignore the leave when the cursor only moved onto the inner edit
  if FMouseInside and not CursorInside then
  begin
    FMouseInside := False;
    inherited;
  end;
end;

procedure TRoundEdit.EditMouseEnter(Sender: TObject);
begin
  Perform(CM_MOUSEENTER, 0, 0); // no-op when already inside
end;

procedure TRoundEdit.EditMouseLeave(Sender: TObject);
begin
  Perform(CM_MOUSELEAVE, 0, 0); // ignored while the cursor is still inside
end;

procedure TRoundEdit.EditContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  ClientPos, ScreenPos: TPoint;
begin
  // MousePos is (-1, -1) when the menu is opened from the keyboard
  if (MousePos.X = -1) and (MousePos.Y = -1) then
  begin
    ClientPos := MousePos;
    ScreenPos := FEdit.ClientToScreen(Point(0, FEdit.Height));
  end
  else
  begin
    ClientPos := Point(MousePos.X + FEdit.Left, MousePos.Y + FEdit.Top);
    ScreenPos := FEdit.ClientToScreen(MousePos);
  end;

  if Assigned(OnContextPopup) then
    OnContextPopup(Self, ClientPos, Handled);

  // Show the TRoundEdit's PopupMenu instead of the default edit menu
  if (not Handled) and (PopupMenu <> nil) and PopupMenu.AutoPopup then
  begin
    PopupMenu.PopupComponent := Self;
    PopupMenu.Popup(ScreenPos.X, ScreenPos.Y);
    Handled := True;
  end;
end;

function TRoundEdit.MeasureTextHeight: Integer;
var
  DC: HDC;
  OldFont: HFONT;
  TM: TTextMetric;
begin
  // Measures the font without depending on the control's handle/canvas
  DC := GetDC(0);
  try
    OldFont := SelectObject(DC, Font.Handle);
    try
      GetTextMetrics(DC, TM);
      Result := TM.tmHeight;
    finally
      SelectObject(DC, OldFont);
    end;
  finally
    ReleaseDC(0, DC);
  end;
end;

procedure TRoundEdit.LayoutEdit;
var
  TextH, Inset: Integer;
begin
  if FEdit = nil then Exit;
  FEdit.Font.Assign(Font);
  FEdit.Color := FFillColor;
  TextH := MeasureTextHeight;
  Inset := FPadding + FBorderWidth;
  // AutoSize is off: the edit height = the exact text height, so
  // centering the edit = centering the text.
  FEdit.SetBounds(Inset, (Height - TextH) div 2, Width - Inset * 2, TextH);
end;

procedure TRoundEdit.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  LayoutEdit;
  Invalidate;
end;

procedure TRoundEdit.Resize;
begin
  inherited;
  LayoutEdit;
  Invalidate;
end;

procedure TRoundEdit.Paint;
var
  G: TGPGraphics;
  Path: TGPGraphicsPath;
  Pen: TGPPen;
  Brush: TGPSolidBrush;
  X, Y, W, H, D, HalfPen: Single;
  BorderCol: TColor;
begin
  // Painting our own background makes the parent paint its children, us
  // included: skip that nested request
  if IsPaintingBackgroundOf(Self) then Exit;

  // 1) Paint what is behind the control so the corners blend with it
  // (the parent and the siblings below, or just the parent's color when
  // Transparent is False)
  PaintControlBackground(Self, Canvas.Handle, FTransparent);

  // 2) Draw the anti-aliased rounded rectangle
  if FEdit.Focused then BorderCol := FFocusColor else BorderCol := FBorderColor;

  HalfPen := FBorderWidth / 2;
  X := HalfPen;
  Y := HalfPen;
  W := Width - FBorderWidth - 1;
  H := Height - FBorderWidth - 1;
  D := FRadius * 2;
  if D > H then D := H;
  if D > W then D := W;

  G := TGPGraphics.Create(Canvas.Handle);
  Path := TGPGraphicsPath.Create;
  Brush := TGPSolidBrush.Create(ToARGB(FFillColor));
  Pen := TGPPen.Create(ToARGB(BorderCol), FBorderWidth);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHalf);

    Path.AddArc(X, Y, D, D, 180, 90);                 // top left
    Path.AddArc(X + W - D, Y, D, D, 270, 90);         // top right
    Path.AddArc(X + W - D, Y + H - D, D, D, 0, 90);   // bottom right
    Path.AddArc(X, Y + H - D, D, D, 90, 90);          // bottom left
    Path.CloseFigure;

    G.FillPath(Brush, Path);
    if FBorderWidth > 0 then
      G.DrawPath(Pen, Path);
  finally
    Pen.Free;
    Brush.Free;
    Path.Free;
    G.Free;
  end;
end;

function TRoundEdit.GetText: string;
begin
  Result := FEdit.Text;
end;

procedure TRoundEdit.SetText(const Value: string);
begin
  FEdit.Text := Value;
end;

procedure TRoundEdit.SetRadius(const Value: Integer);
begin
  if FRadius <> Value then begin FRadius := Value; Invalidate; end;
end;

procedure TRoundEdit.SetBorderWidth(const Value: Integer);
begin
  if FBorderWidth <> Value then begin FBorderWidth := Value; LayoutEdit; Invalidate; end;
end;

procedure TRoundEdit.SetBorderColor(const Value: TColor);
begin
  if FBorderColor <> Value then begin FBorderColor := Value; Invalidate; end;
end;

procedure TRoundEdit.SetFocusColor(const Value: TColor);
begin
  if FFocusColor <> Value then begin FFocusColor := Value; Invalidate; end;
end;

procedure TRoundEdit.SetFillColor(const Value: TColor);
begin
  if FFillColor <> Value then begin FFillColor := Value; LayoutEdit; Invalidate; end;
end;

procedure TRoundEdit.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then begin FTransparent := Value; Invalidate; end;
end;

procedure TRoundEdit.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then begin FPadding := Value; LayoutEdit; Invalidate; end;
end;

end.
