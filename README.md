# AutoGUI

Ruby GUI automation: mouse, keyboard, screenshots, image search, message boxes, and windows.

This is a Ruby port of Python [PyAutoGUI](https://pyautogui.readthedocs.io/). Require it as `autogui` and call `AutoGUI`.

> Moving the mouse into a screen corner aborts the script (`FailSafeException`). Leave `AutoGUI.FAILSAFE = true` unless you have a very good reason not to.

## Install

Ruby 2.7+ is enough. There are no gem dependencies.

### From GitHub (Bundler)

```ruby
# Gemfile
gem "autogui", git: "https://github.com/pardeep2690/autogui.git"
```

```
bundle install
```

Then:

```ruby
require "autogui"
```

### Clone and use locally

```
git clone https://github.com/pardeep2690/autogui.git
cd autogui
```

```ruby
$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "autogui"
```

Or from the project root:

```
ruby -Ilib -e "require 'autogui'; p AutoGUI.size"
ruby bin/autogui info
```

### Build the gem

```
git clone https://github.com/pardeep2690/autogui.git
cd autogui
gem build autogui.gemspec
gem install autogui-1.0.0.gem
```

### Platform extras

| OS | Mouse / keyboard | Screenshots |
| --- | --- | --- |
| Windows | built-in Win32 | built-in GDI |
| macOS | Accessibility permission for Terminal/Ruby; `osascript` | `screencapture` |
| Linux | `xdotool` | `scrot`, `import`, or `grim` |

## Cheat sheet

Snake_case is the Ruby style. CamelCase aliases match the Python names (`move_to` / `moveTo`, and so on).

```ruby
require "autogui"

# General
x, y = AutoGUI.position            # current mouse
w, h = AutoGUI.size                # primary screen
AutoGUI.on_screen(100, 200)        # true if on the primary screen
AutoGUI.PAUSE = 0.5                # pause after every public call (default 0.1)
AutoGUI.FAILSAFE = true            # slam mouse to a corner to abort

# Mouse  (origin is top-left; y grows downward)
AutoGUI.move_to(100, 150)
AutoGUI.move_to(100, 150, duration: 1.0, tween: AutoGUI.method(:easeInOutQuad))
AutoGUI.move(0, 10)                # relative; alias: move_rel
AutoGUI.click
AutoGUI.click(200, 220, clicks: 2, button: "right")
AutoGUI.double_click
AutoGUI.right_click
AutoGUI.drag_to(300, 400, duration: 0.5)
AutoGUI.scroll(3)                  # positive = up
AutoGUI.mouse_down(button: "left")
AutoGUI.mouse_up(button: "left")

# Keyboard
AutoGUI.write("Hello world!", interval: 0.05)
AutoGUI.write(["a", "b", "left", "enter"])
AutoGUI.press("enter")
AutoGUI.press("f1", presses: 3)
AutoGUI.hotkey("ctrl", "c")
AutoGUI.hold("shift") { AutoGUI.press(["left", "left"]) }
AutoGUI.key_down("shift")
AutoGUI.key_up("shift")

# Screenshots & image search
img = AutoGUI.screenshot
img.save("screen.png")
AutoGUI.screenshot("screen2.png", region: [0, 0, 300, 400])
box = AutoGUI.locate_on_screen("button.png")         # Box(left, top, width, height) or nil
AutoGUI.locate_center_on_screen("button.png")        # Point
AutoGUI.click(box) if box                            # clicks the center
r, g, b = AutoGUI.pixel(100, 200)
AutoGUI.pixel_matches_color(100, 200, [255, 255, 255], tolerance: 10)

# Message boxes
AutoGUI.alert("Done.")
AutoGUI.confirm("Continue?")                         # "OK" or "Cancel"
name = AutoGUI.prompt("Your name?")
secret = AutoGUI.password("Password")

# Windows (Windows OS)
AutoGUI.get_all_titles
win = AutoGUI.get_windows_with_title("Notepad").first
win&.activate
win&.move_to(40, 40)
win&.resize_to(800, 600)

# Mini-language
AutoGUI.run("c c g 100, 200 c")
```

## Fail-safe

If `FAILSAFE` is true (the default), calling an AutoGUI function while the cursor sits on a corner of the primary monitor raises `AutoGUI::FailSafeException`. That is the emergency stop.

```ruby
AutoGUI.FAILSAFE = true
AutoGUI.PAUSE = 0.1
```

## Tweens

Pass a callable as `tween:` to `move_to` / `drag_to`:

`linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInQuart`, `easeOutQuart`, `easeInOutQuart`, `easeInQuint`, `easeOutQuint`, `easeInOutQuint`, `easeInSine`, `easeOutSine`, `easeInOutSine`, `easeInExpo`, `easeOutExpo`, `easeInOutExpo`, `easeInCirc`, `easeOutCirc`, `easeInOutCirc`, `easeInElastic`, `easeOutElastic`, `easeInOutElastic`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeInBounce`, `easeOutBounce`, `easeInOutBounce`

## Image matching

`locate*` does pixel template matching in pure Ruby (no OpenCV). Exact match is the default. Approximate match:

```ruby
AutoGUI.locate_on_screen("needle.png", confidence: 0.9, grayscale: true)
```

Set `AutoGUI.use_image_not_found_exception!(true)` to raise `ImageNotFoundException` instead of returning `nil`.

Needle images may be PNG or BMP.

## Key names

See `AutoGUI::KEYBOARD_KEYS`: `enter`, `esc`, `tab`, `shift`, `ctrl`, `alt`, `win`, `left`/`up`/`right`/`down`, `f1`–`f24`, `pageup`, `pagedown`, `backspace`, `delete`, and printable characters.

## CLI

```
ruby bin/autogui info
ruby bin/autogui mouse        # live X/Y/RGB (Ctrl-C to quit)
ruby bin/autogui screenshot out.png
```

## Tests

```
git clone https://github.com/pardeep2690/autogui.git
cd autogui
ruby -Ilib:test test/test_autogui.rb
```

Live mouse/keyboard tests are skipped unless `AUTOGUI_LIVE=1` is set:

```
AUTOGUI_LIVE=1 ruby -Ilib:test test/test_autogui.rb
```

## License

BSD 3-Clause, following the original PyAutoGUI project.
