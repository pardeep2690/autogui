# AutoGUI guide

This guide expands the README with behavior notes, recipes, and the command mini-language. Method signatures are in [api.md](api.md).

## Coordinates

The origin `(0, 0)` is the **top-left pixel of the primary monitor**. `x` grows right, `y` grows down. The bottom-right pixel of a 1920×1080 screen is `(1919, 1079)` — `on_screen(1920, 1080)` is false.

`position` and `size` return objects that unpack:

```ruby
x, y = AutoGUI.position
width, height = AutoGUI.size
```

Multi-monitor setups: `size` / `on_screen` / fail-safe corners refer to the **primary** display. Mouse moves may still land on other screens if you pass coordinates that the OS accepts.

### Flexible `x, y` arguments

These are equivalent:

```ruby
AutoGUI.click(100, 200)
AutoGUI.click([100, 200])
AutoGUI.click(AutoGUI::Point.new(100, 200))
```

A four-number sequence or a `Box` clicks the **center**:

```ruby
AutoGUI.click([100, 200, 80, 40])
AutoGUI.click(AutoGUI.locate_on_screen("ok.png"))
```

A string is treated as an image path:

```ruby
AutoGUI.click("submit.png")   # locate on screen, click center
```

Pass `nil` to keep one axis:

```ruby
AutoGUI.move_to(nil, 0)       # same x, y = 0
AutoGUI.move_to(0, nil)       # x = 0, same y
```

## Fail-safe in practice

Fail-safe points are filled in when the library loads:

```ruby
AutoGUI.FAILSAFE_POINTS
# [Point(0,0), Point(0, height-1), Point(width-1, 0), Point(width-1, height-1)]
```

If you change resolution later, update that list yourself. During a tweened `move_to`, AutoGUI will not trip fail-safe merely because a **step** of the tween sits on a corner — but if **you** slam the real cursor to a corner between steps, the next check raises.

`PAUSE` exists so you have time to do that. For debugging, raise it:

```ruby
AutoGUI.PAUSE = 0.5
```

For tight loops, lower it — never to the point you cannot abort:

```ruby
AutoGUI.PAUSE = 0.01
```

## Mouse recipes

Smooth move with an easing curve:

```ruby
AutoGUI.move_to(800, 400, duration: 1.0, tween: AutoGUI.method(:easeOutCubic))
```

Drag a selection:

```ruby
AutoGUI.move_to(100, 100)
AutoGUI.drag_to(400, 300, duration: 0.4, button: "left")
```

Split a drag into segments (`mouseDownUp: false` skips the extra down/up):

```ruby
AutoGUI.mouse_down
AutoGUI.drag_to(200, 200, mouseDownUp: false)
AutoGUI.drag_to(300, 150, mouseDownUp: false)
AutoGUI.mouse_up
```

Scroll at a point:

```ruby
AutoGUI.scroll(-8, 500, 400)   # down, over (500, 400)
```

## Keyboard recipes

Type into the focused field, then submit:

```ruby
AutoGUI.click(field_box)
AutoGUI.hotkey("ctrl", "a")
AutoGUI.write("new value")
AutoGUI.press("enter")
```

Select a range with Shift held:

```ruby
AutoGUI.hold("shift") do
  AutoGUI.press("end")
end
```

`write` of a String sends **characters**. `write` of an Array sends **key names** (so `"left"` is the arrow, not the letters l-e-f-t):

```ruby
AutoGUI.write("Hi!")                 # H, i, !
AutoGUI.write(["H", "i", "enter"])   # H, i, Enter
```

`hotkey` presses keys down left-to-right, then up right-to-left, which is what OS shortcuts expect.

## Screenshot recipes

Full screen to disk and to memory:

```ruby
image = AutoGUI.screenshot("full.png")
image.width
image.getpixel(0, 0)   # [r, g, b]
```

Grab a region, search inside it:

```ruby
region = [0, 0, 800, 600]
hay = AutoGUI.screenshot(region: region)
box = AutoGUI.locate("ok.png", hay)
# box is relative to the screenshot; offset if you need screen coords:
if box
  AutoGUI.click(box.left + region[0] + box.width / 2,
                box.top + region[1] + box.height / 2)
end
```

Wait up to five seconds for a button to appear:

```ruby
box = AutoGUI.locate_on_screen("ready.png", minSearchTime: 5)
raise "UI never appeared" unless box
AutoGUI.click(box)
```

Fuzzy match (anti-aliased UI):

```ruby
AutoGUI.locate_on_screen("icon.png", grayscale: true, confidence: 0.92)
```

`confidence` is `1 - mean(|pixel difference|) / 255`. Exact matching (`confidence: nil`) is much faster because whole rows can be compared as strings.

Locating is CPU-bound Ruby. Keep needles small and pass `region:` when you can.

## Window recipes (Windows)

```ruby
notepad = AutoGUI.get_windows_with_title("Untitled").first
raise "open Notepad first" unless notepad

notepad.activate
AutoGUI.sleep(0.2)
notepad.move_to(40, 40)
notepad.resize_to(640, 480)
AutoGUI.write("typed into Notepad")
```

`get_windows_with_title` is a case-insensitive substring match. Pass a `Regexp` for tighter control.

## Dialogs

Use dialogs as breakpoints in unattended scripts:

```ruby
next unless AutoGUI.confirm("Click OK to start clicking") == "OK"
AutoGUI.click(100, 100)
```

`prompt` / `password` return `nil` when the user cancels.

## Mini-language

`AutoGUI.run` is a compact way to write short macros. Commands are lowercase. Whitespace is ignored. Strings use **single** quotes.

```ruby
# two clicks, move to 100,200, click, type hi, press enter
AutoGUI.run("c c g 100, 200 c w'hi' k'enter'")
```

Relative vs absolute: a leading `+` or `-` on **both** numbers means relative.

```ruby
AutoGUI.run("g+20,-10")   # move 20 right, 10 up
AutoGUI.run("g 20, 10")   # move to pixel (20, 10)
```

Loops:

```ruby
AutoGUI.run("f5(c s0.2)")   # click, sleep 0.2, five times
```

`p` changes `PAUSE` only until `run` returns.

Invalid tokens raise `AutoGUI::AutoGUIException` with an index into the string.

## Logging screenshots

```ruby
AutoGUI.LOG_SCREENSHOTS = true
AutoGUI.LOG_SCREENSHOTS_LIMIT = 20
AutoGUI.click(10, 10)
# writes a timestamped PNG in the working directory
```

## Mapping from PyAutoGUI

| Python | Ruby |
| --- | --- |
| `import pyautogui` | `require "autogui"` |
| `pyautogui.moveTo` | `AutoGUI.move_to` (or `moveTo`) |
| `with pyautogui.hold("shift"):` | `AutoGUI.hold("shift") { ... }` |
| `None` | `nil` |
| `True` / `False` | `true` / `false` |
| `pyautogui.PAUSE = 0.5` | `AutoGUI.PAUSE = 0.5` |
| keyword args `duration=1` | `duration: 1` |

Return tuples become `Point` / `Size` / `Box` but still unpack.
