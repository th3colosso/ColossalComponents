unit uRoundEdit;

{ TRoundEdit - Edit with rounded, anti-aliased corners drawn with GDI+.
  Works as a "container": it draws the frame with GDI+ and hosts a borderless
  TEdit inside it. }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Forms;

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
    function GetText: string;
    procedure SetText(const Value: string);
    procedure SetRadius(const Value: Integer);
    procedure SetBorderWidth(const Value: Integer);
    procedure SetBorderColor(const Value: TColor);
    procedure SetFocusColor(const Value: TColor);
    procedure SetFillColor(const Value: TColor);
    procedure SetPadding(const Value: Integer);
    procedure EditStateChange(Sender: TObject);
    procedure LayoutEdit;
    function MeasureTextHeight: Integer;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
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
  end;

procedure Register;

implementation

function ToARGB(C: TColor; Alpha: Byte = 255): ARGB;
var
  RGB: Cardinal;
begin
  RGB := ColorToRGB(C);
  Result := MakeColor(Alpha, GetRValue(RGB), GetGValue(RGB), GetBValue(RGB));
end;

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

  FEdit := TEdit.Create(Self);
  FEdit.Name := 'InnerEdit';
  FEdit.SetSubComponent(True);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.AutoSize := False;
  FEdit.Color := FFillColor;
  FEdit.OnEnter := EditStateChange;
  FEdit.OnExit := EditStateChange;
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

procedure TRoundEdit.EditStateChange(Sender: TObject);
begin
  Invalidate;
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
  // 1) Paint the parent's background so the corners blend with it
  if Parent <> nil then
    Canvas.Brush.Color := Parent.Brush.Color
  else
    Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(ClientRect);

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

procedure TRoundEdit.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then begin FPadding := Value; LayoutEdit; Invalidate; end;
end;

end.
