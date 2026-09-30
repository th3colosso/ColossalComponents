# Colossal Controls

A collection of custom VCL components for Delphi.

Components are registered on the **Colossal Controls** tab of the Tool Palette.

## Components

### TRoundEdit

An edit box with rounded corners. The frame is drawn with **GDI+** using anti-aliasing, so the corners are smooth instead of jagged (which is what you get when clipping a window with `SetWindowRgn`).

![TRoundEdit example](src/assets/readme_example.png)

`TRoundEdit` is a `TCustomControl` that paints the rounded frame and hosts a borderless `TEdit` inside it. The inner edit's height is set from the real font height and centered vertically, so the text stays aligned at any font size.

**Features**

- Anti-aliased rounded corners (GDI+)
- Configurable corner radius, border width, and colors
- Different border color when the edit has focus
- Text is vertically centered and follows font changes
- Cannot be used as a parent for other components (`csAcceptsControls` removed)
- Double buffered, no flicker

**Published properties**

| Property      | Type     | Default   | Description                                   |
|---------------|----------|-----------|-----------------------------------------------|
| `Text`        | string   |           | Text of the inner edit                        |
| `Radius`      | Integer  | `10`      | Corner radius in pixels                       |
| `BorderWidth` | Integer  | `1`       | Border thickness in pixels (`0` = no border)  |
| `BorderColor` | TColor   | `$00C0C0C0` | Border color when not focused               |
| `FocusColor`  | TColor   | `$00D77800` | Border color when the edit has focus        |
| `FillColor`   | TColor   | `clWhite` | Background color of the box and inner edit    |
| `Padding`     | Integer  | `8`       | Space between the border and the text         |
| `Font`        | TFont    |           | Font of the text                              |

Standard properties such as `Align`, `Anchors`, `Margins`, `TabOrder`, `Visible`, and `Enabled` are also published.

**Accessing the inner edit**

The inner `TEdit` is exposed through the public `Edit` property, for anything not published directly:

```pascal
RoundEdit1.Edit.OnChange := MyChangeHandler;
RoundEdit1.Edit.PasswordChar := '*';
RoundEdit1.Edit.NumbersOnly := True;
```

## Requirements

- Delphi 13 (RAD Studio 37.0)
- VCL, Windows (the package currently targets Win32)

## Installation

1. Open `ColossalControls.dproj` in the IDE.
2. In the Project Manager, right-click `ColossalControls.bpl` and choose **Build**, then **Install**.
3. The IDE should report that `TRoundEdit` was registered. The package appears in *Component > Install Packages* as **Colossal Controls**.
4. Open a VCL form. `TRoundEdit` is on the **Colossal Controls** tab of the Tool Palette.

To use the components in your own projects, add the `src` folder of this repository to the IDE's library path (*Tools > Options > Language > Delphi > Library > Library path*), or add `uRoundEdit.pas` to your project.

## Usage

Drop a `TRoundEdit` on a form and adjust its properties in the Object Inspector, or create it in code:

```pascal
uses
  uRoundEdit;

procedure TForm1.FormCreate(Sender: TObject);
var
  Edt: TRoundEdit;
begin
  Edt := TRoundEdit.Create(Self);
  Edt.Parent := Self;
  Edt.SetBounds(20, 20, 250, 36);
  Edt.Radius := 12;
  Edt.FocusColor := clHighlight;
  Edt.Text := 'Hello';
end;
```

## Project structure

```
ColossalComponents/
├── ColossalControls.dpk     Package source
├── ColossalControls.dproj   Package project
├── src/
│   └── uRoundEdit.pas       TRoundEdit component
└── bin/                     Compiled output (DCU)
```

## Known limitations

- The corners are painted with the parent's `Brush.Color`. If the parent has a background image or gradient, the corners show a solid color instead of the parent's background.
- With VCL Styles active, the parent's `Brush.Color` may not match the style color, so the corners can look slightly off.
- There is no special visual style for the disabled state yet.
- Only Win32 is built by the package at the moment.

## License

No license specified yet.
