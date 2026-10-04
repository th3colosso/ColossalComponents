unit uColossalDraw;

{ Shared drawing helpers for the Colossal Controls components. }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI,
  System.Types, Vcl.Controls, Vcl.Graphics, System.Classes;

{ Converts a TColor (including system colors) to a GDI+ ARGB value. }
function ToARGB(C: TColor; Alpha: Byte = 255): ARGB;

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
