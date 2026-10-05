unit uColossalDraw;

{ Shared drawing helpers for the Colossal Controls components. }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Types, Vcl.Controls, Vcl.Graphics, System.Classes;

{ Converts a TColor (including system colors) to a GDI+ ARGB value. }
function ToARGB(C: TColor; Alpha: Byte = 255): ARGB;

{ Creates a rounded rectangle path (the caller frees it). The radius is
  limited so it never exceeds half of the width/height. A radius of 0 gives a
  plain rectangle. }
function CreateRoundRectPath(X, Y, W, H, ARadius: Single): TGPGraphicsPath;

{ Fills / outlines a rounded rectangle with anti-aliasing (G must already
  have its smoothing mode set). }
procedure FillRoundRect(G: TGPGraphics; X, Y, W, H, ARadius: Single;
  AColor: TColor);
procedure StrokeRoundRect(G: TGPGraphics; X, Y, W, H, ARadius: Single;
  AColor: TColor; AWidth: Single);

{ Height of a capital letter above the baseline, in the font currently
  selected into DC. Used to center text optically (by the body of the
  letters instead of the whole line box, which includes the descender and the
  internal leading and makes the text look low). }
function CapHeightOf(DC: HDC; const TM: TTextMetric): Integer;

{ Paints the background of AControl into DC (a DC whose origin is the
  top-left corner of the control).

  ATransparent = True: paints what is really behind the control - the
  parent's background (color, theme, VCL style, ...) plus the siblings that
  are below it in the Z-order - so rounded corners blend with whatever is
  underneath, even when the control overlaps a sibling such as a panel.

  ATransparent = False: fills the control with the parent's color only. }
procedure PaintControlBackground(AControl: TWinControl; DC: HDC;
  ATransparent: Boolean);

{ True while the background of AControl is being composed. Painting the
  parent can ask the control itself to paint (the parent paints all of its
  children), so the control must skip its own Paint in that case. }
function IsPaintingBackgroundOf(AControl: TControl): Boolean;

implementation

var
  // The control whose background is being composed (VCL painting is single
  // threaded, so one global is enough)
  GComposing: TControl = nil;

function ToARGB(C: TColor; Alpha: Byte): ARGB;
var
  RGB: Cardinal;
begin
  RGB := ColorToRGB(C);
  Result := MakeColor(Alpha, GetRValue(RGB), GetGValue(RGB), GetBValue(RGB));
end;

function CreateRoundRectPath(X, Y, W, H, ARadius: Single): TGPGraphicsPath;
var
  D: Single;
begin
  D := ARadius * 2;
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

procedure FillRoundRect(G: TGPGraphics; X, Y, W, H, ARadius: Single;
  AColor: TColor);
var
  Path: TGPGraphicsPath;
  Brush: TGPSolidBrush;
begin
  Path := nil;
  Brush := nil;
  try
    Path := CreateRoundRectPath(X, Y, W, H, ARadius);
    Brush := TGPSolidBrush.Create(ToARGB(AColor));
    G.FillPath(Brush, Path);
  finally
    Brush.Free;
    Path.Free;
  end;
end;

procedure StrokeRoundRect(G: TGPGraphics; X, Y, W, H, ARadius: Single;
  AColor: TColor; AWidth: Single);
var
  Path: TGPGraphicsPath;
  Pen: TGPPen;
begin
  Path := nil;
  Pen := nil;
  try
    Path := CreateRoundRectPath(X, Y, W, H, ARadius);
    Pen := TGPPen.Create(ToARGB(AColor), AWidth);
    G.DrawPath(Pen, Path);
  finally
    Pen.Free;
    Path.Free;
  end;
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

function IsPaintingBackgroundOf(AControl: TControl): Boolean;
begin
  Result := AControl = GComposing;
end;

function IsDrawn(AControl: TControl): Boolean;
begin
  Result := AControl.Visible or
    ((csDesigning in AControl.ComponentState) and
     not (csNoDesignVisible in AControl.ControlStyle));
end;

procedure PaintControlInto(DC: HDC; AControl: TControl);
var
  SaveIndex: Integer;
begin
  // Same technique the VCL uses to paint the children of a control
  SaveIndex := SaveDC(DC);
  try
    OffsetViewportOrgEx(DC, AControl.Left, AControl.Top, nil);
    IntersectClipRect(DC, 0, 0, AControl.Width, AControl.Height);
    AControl.Perform(WM_PAINT, WPARAM(DC), 0);
  finally
    RestoreDC(DC, SaveIndex);
  end;
end;

procedure PaintControlBackground(AControl: TWinControl; DC: HDC;
  ATransparent: Boolean);
var
  Parent: TWinControl;
  Area: TRect;
  SaveIndex, I: Integer;
  Sibling: TControl;
begin
  // A compose is already running: this paint was triggered by it (another
  // Colossal control being drawn as part of the background). The background
  // is already in the DC, so there is nothing to do.
  if GComposing <> nil then Exit;

  Parent := AControl.Parent;
  Area := Rect(0, 0, AControl.Width, AControl.Height);

  if Parent = nil then
  begin
    FillRect(DC, Area, GetSysColorBrush(COLOR_BTNFACE));
    Exit;
  end;

  if not ATransparent then
  begin
    FillRect(DC, Area, Parent.Brush.Handle);
    Exit;
  end;

  GComposing := AControl;
  SaveIndex := SaveDC(DC);
  try
    // Work in the parent's client coordinates, clipped to this control
    OffsetViewportOrgEx(DC, -AControl.Left, -AControl.Top, nil);
    IntersectClipRect(DC, AControl.Left, AControl.Top,
      AControl.Left + AControl.Width, AControl.Top + AControl.Height);

    // Plain color first as a safety net, then let the parent erase its own
    // background: this honors themes, VCL styles, and background images. The
    // parent also paints its children, which includes non-windowed controls
    // (labels, shapes, ...).
    FillRect(DC, AControl.BoundsRect, Parent.Brush.Handle);
    Parent.Perform(WM_ERASEBKGND, WPARAM(DC), 0);

    // Windowed siblings below this control in the Z-order (e.g. a panel the
    // control overlaps). Painting one twice is harmless.
    for I := 0 to Parent.ControlCount - 1 do
    begin
      Sibling := Parent.Controls[I];
      if Sibling = AControl then Break;
      if (Sibling is TWinControl) and IsDrawn(Sibling) and
         not TRect.Intersect(AControl.BoundsRect, Sibling.BoundsRect).IsEmpty then
        PaintControlInto(DC, Sibling);
    end;
  finally
    RestoreDC(DC, SaveIndex);
    GComposing := nil;
  end;
end;

end.
