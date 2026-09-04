# AutoGUI

[![Gem Version](https://badge.fury.io/rb/autogui.svg)](https://rubygems.org/gems/autogui)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

Ruby library for desktop GUI automation: mouse, keyboard, screenshots, image search, message boxes, and window control.

It is a Ruby port of Python [PyAutoGUI](https://pyautogui.readthedocs.io/). Call `AutoGUI` after `require "autogui"`. Snake_case is the Ruby API (`move_to`, `left_click`). CamelCase aliases match Python (`moveTo`, `leftClick`).

**No runtime gem dependencies.** Ruby 2.7+ and the standard library are enough.

> **Fail-safe:** moving the mouse into a corner of the primary screen raises `AutoGUI::FailSafeException` and stops the script. Leave `AutoGUI.FAILSAFE = true` unless you have a very good reason not to.

## Table of contents

- [Install](#install)
- [Quick start](#quick-start)
- [Safety](#safety)
- [Coordinates](#coordinates)
- [Mouse](#mouse)
- [Keyboard](#keyboard)
- [Screenshots and image search](#screenshots-and-image-search)
- [Message boxes](#message-boxes)
- [Windows](#windows)
- [Settings](#settings)
- [Tweens](#tweens)
- [Mini-language](#mini-language)
- [CLI](#cli)
- [Platforms](#platforms)
- [Exceptions](#exceptions)
- [API reference](#api-reference)
- [Development](#development)
- [License](#license)

Full method tables live in [docs/api.md](docs/api.md). A longer walkthrough is in [docs/guide.md](docs/guide.md).

## Install

### RubyGems

```
gem install autogui
```

```ruby
require "autogui"

p AutoGUI.size
# => Size(width=1920, height=1080)
```

### Bundler

```ruby
# Gemfile
source "https://rubygems.org"
gem "autogui"
```

```
bundle install
```

### From GitHub (before / besides RubyGems)

```ruby
# Gemfile
gem "autogui", git: "https://github.com/pardeep2690/autogui.git"
```

Or build a `.gem` from the repo:

```
git clone https://github.com/pardeep2690/autogui.git
cd autogui
gem build autogui.gemspec
gem install autogui-1.0.1.gem
```

### Platform extras

| OS | Mouse / keyboard | Screenshots | Notes |
| --- | --- | --- | --- |
| **Windows** | Win32 via stdlib `Fiddle` | GDI | Works out of the box |
| **macOS** | `osascript` | `screencapture` | Grant Accessibility to Terminal / Ruby |
| **Linux** | `xdotool` | `scrot`, ImageMagick `import`, or `grim` | Install those tools |

```
# Debian / Ubuntu
sudo apt-get install xdotool scrot
```

## Quick start

```ruby
require "autogui"

AutoGUI.PAUSE = 0.25
AutoGUI.FAILSAFE = true

width, height = AutoGUI.size
x, y = AutoGUI.position

AutoGUI.move_to(width / 2, height / 2, duration: 0.4)
AutoGUI.click
AutoGUI.write("Hello from AutoGUI", interval: 0.02)
AutoGUI.press("enter")
AutoGUI.hotkey("ctrl", "s")

img = AutoGUI.screenshot("desktop.png")
box = AutoGUI.locate_on_screen("button.png")
AutoGUI.click(box) if box
```

Give yourself a moment before the script takes over:

```ruby
AutoGUI.countdown(3)   # prints 3 2 1
AutoGUI.click(100, 200)
```

## Safety

Every public action (move, click, type, …) does two things:

1. **Fail-safe check** — if the cursor is on a corner listed in `AutoGUI.FAILSAFE_POINTS`, it raises `AutoGUI::FailSafeException`.
2. **Pause** — sleeps `AutoGUI.PAUSE` seconds (default `0.1`) so you can yank the mouse to a corner.

```ruby
AutoGUI.FAILSAFE = true     # default; do not disable in production scripts
AutoGUI.PAUSE = 0.1         # seconds after each call
```

Corners of the primary monitor are registered at load time. Do not `move_to(0, 0)` while fail-safe is on.

Rescue it if you want a clean shutdown:

```ruby
begin
  AutoGUI.move_to(500, 500)
  AutoGUI.click
rescue AutoGUI::FailSafeException
  warn "aborted: mouse in a screen corner"
end
```

## Coordinates

Origin is the **top-left** of the primary display. `x` increases to the right, `y` increases downward.

```ruby
AutoGUI.size        # Size(width:, height:) — also AutoGUI.resolution
AutoGUI.position    # Point(x:, y:) of the cursor
AutoGUI.on_screen(100, 200)          # true / false
AutoGUI.on_screen([100, 200])
```

`Point`, `Size`, and `Box` unpack like arrays:

```ruby
x, y = AutoGUI.position
w, h = AutoGUI.size
left, top, width, height = box
```

Most mouse methods accept:

| Argument | Meaning |
| --- | --- |
| no args | current cursor position |
| `x, y` | absolute pixel |
| `[x, y]` | same |
| `[left, top, width, height]` or a `Box` | center of that box |
| `"needle.png"` | center of that image on screen (`locate_on_screen`) |
| `x: nil, y: 80` | keep current x, set y (and the reverse) |

## Mouse

Buttons: `"left"`, `"middle"`, `"right"`, `"primary"`, `"secondary"` (or `1` / `2` / `3`). `"primary"` is left unless the OS has swapped buttons.

```ruby
AutoGUI.move_to(100, 150)
AutoGUI.move_to(100, 150, duration: 1.0, tween: AutoGUI.method(:easeInOutQuad))
AutoGUI.move(0, 10)                 # relative; aliases: move_rel
AutoGUI.drag_to(300, 400, duration: 0.5, button: "left")
AutoGUI.drag(50, 0)                 # relative drag

AutoGUI.click
AutoGUI.click(200, 220, clicks: 2, interval: 0.1, button: "right")
AutoGUI.left_click
AutoGUI.right_click
AutoGUI.middle_click
AutoGUI.double_click
AutoGUI.triple_click

AutoGUI.mouse_down(button: "left")
AutoGUI.mouse_up(button: "left")

AutoGUI.scroll(3)                   # positive = up, negative = down
AutoGUI.hscroll(-2)                 # horizontal where the OS supports it
AutoGUI.vscroll(3)
```

`duration:` below `AutoGUI.MINIMUM_DURATION` (0.1s) is treated as instant.

## Keyboard

Keys go to whatever window has focus.

```ruby
AutoGUI.write("Hello world!", interval: 0.05)
AutoGUI.write(["a", "b", "left", "enter"])   # alias: typewrite
AutoGUI.press("enter")
AutoGUI.press("f1", presses: 3, interval: 0.2)
AutoGUI.press(["up", "up", "down"])
AutoGUI.hotkey("ctrl", "c")                  # alias: shortcut
AutoGUI.hold("shift") { AutoGUI.press(["left", "left"]) }
AutoGUI.key_down("ctrl")
AutoGUI.key_up("ctrl")
AutoGUI.valid_key?("esc")                    # => true
```

`hold` **requires a block**; the key is released in `ensure`.

Common names (full list: `AutoGUI::KEYBOARD_KEYS`):

`enter` `return` `esc` `tab` `space` `backspace` `delete` `shift` `ctrl` `alt` `win` `command` `option` `up` `down` `left` `right` `home` `end` `pageup` `pagedown` `f1`…`f24` plus printable characters.

On Windows, non-ASCII characters in `write` are sent as Unicode.

## Screenshots and image search

```ruby
img = AutoGUI.screenshot                         # AutoGUI::Image
img.save("desktop.png")
AutoGUI.screenshot("desktop.png")                # capture and save
AutoGUI.screenshot("crop.png", region: [0, 0, 300, 400])  # left, top, width, height

r, g, b = AutoGUI.pixel(100, 200)
AutoGUI.pixel_matches_color(100, 200, [255, 255, 255], tolerance: 10)

box = AutoGUI.locate_on_screen("button.png")     # Box or nil
# Box(left:, top:, width:, height:)
pt  = AutoGUI.locate_center_on_screen("button.png")  # Point or nil
AutoGUI.click(box) if box

AutoGUI.locate_all_on_screen("icon.png").each { |b| p b }
AutoGUI.locate("needle.png", "haystack.png")
AutoGUI.center([10, 20, 40, 30])                 # Point at the box center
```

Needle files may be **PNG or BMP**. Matching is pure Ruby (no OpenCV).

```ruby
AutoGUI.locate_on_screen("needle.png", grayscale: true, confidence: 0.9)
AutoGUI.locate_on_screen("needle.png", region: [0, 0, 800, 600], minSearchTime: 5)
```

| Option | Default | Meaning |
| --- | --- | --- |
| `grayscale:` | `false` | compare luminance only |
| `confidence:` | `nil` (exact pixels) | `0.0`–`1.0` mean-absolute-error score |
| `region:` | full screen | `[left, top, width, height]` |
| `minSearchTime:` | `0` | keep retrying that many seconds |

By default a miss returns `nil`. To raise instead:

```ruby
AutoGUI.use_image_not_found_exception!(true)
AutoGUI.locate_on_screen("missing.png")
# raises AutoGUI::ImageNotFoundException
```

`AutoGUI::Image` supports `getpixel`, `putpixel`, `crop`, `grayscale`, `save`, and `Image.open(path)`.

## Message boxes

```ruby
AutoGUI.alert("Done.")
choice = AutoGUI.confirm("Continue?")            # "OK" or "Cancel"
name   = AutoGUI.prompt("Your name?", "Title", "guest")
secret = AutoGUI.password("Password")            # nil if cancelled
```

On Windows these use Win32 / VBScript dialogs. Elsewhere they use `osascript` or `zenity` when present.

## Windows

Window helpers are implemented for **Windows**. They return empty / `nil` on other OSes.

```ruby
AutoGUI.get_all_titles
AutoGUI.get_all_windows
AutoGUI.get_active_window
AutoGUI.get_active_window_title
AutoGUI.get_windows_with_title("Notepad")        # substring, case-insensitive
AutoGUI.get_windows_at(400, 300)

win = AutoGUI.get_windows_with_title("Notepad").first
win&.activate
win&.move_to(40, 40)
win&.resize_to(800, 600)
win&.minimize
win&.maximize
win&.restore
win&.close
win.title
win.left
win.top
win.width
win.height
win.visible?
```

CamelCase aliases exist (`getAllTitles`, `getActiveWindow`, …).

## Settings

| Setting | Default | Role |
| --- | --- | --- |
| `AutoGUI.PAUSE` | `0.1` | seconds to sleep after each public call |
| `AutoGUI.FAILSAFE` | `true` | abort when the cursor is on a fail-safe point |
| `AutoGUI.FAILSAFE_POINTS` | four corners | `Point` list checked before actions |
| `AutoGUI.MINIMUM_DURATION` | `0.1` | shorter `duration:` moves are instant |
| `AutoGUI.MINIMUM_SLEEP` | `0.05` | floor between tween steps |
| `AutoGUI.DARWIN_CATCH_UP_TIME` | `0.01` | extra delay after macOS events |
| `AutoGUI.LOG_SCREENSHOTS` | `false` | save a PNG on each action |
| `AutoGUI.LOG_SCREENSHOTS_LIMIT` | `10` | rotate old log screenshots |

```ruby
AutoGUI.print_info
# Platform, Ruby version, AutoGUI version, executable, resolution, timestamp
```

## Tweens

Pass any callable that maps `0.0..1.0` → `0.0..1.0` as `tween:`:

```ruby
AutoGUI.move_to(800, 400, duration: 1.2, tween: AutoGUI.method(:easeInOutQuad))
```

Built-ins: `linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInQuart`, `easeOutQuart`, `easeInOutQuart`, `easeInQuint`, `easeOutQuint`, `easeInOutQuint`, `easeInSine`, `easeOutSine`, `easeInOutSine`, `easeInExpo`, `easeOutExpo`, `easeInOutExpo`, `easeInCirc`, `easeOutCirc`, `easeInOutCirc`, `easeInElastic`, `easeOutElastic`, `easeInOutElastic`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeInBounce`, `easeOutBounce`, `easeInOutBounce`.

## Mini-language

```ruby
AutoGUI.run("c c g 100, 200 c")
```

| Token | Action |
| --- | --- |
| `c` `l` `m` `r` | click primary / left / middle / right |
| `su` `sd` | scroll up / down |
| `ss` | screenshot `screenshotN.png` |
| `gX,Y` / `g+X,-Y` | `move_to` / relative `move` |
| `dX,Y` / `d+X,-Y` | `drag_to` / relative `drag` |
| `k'enter'` | `press` |
| `w'hello'` | `write` |
| `h'ctrl,c'` | `hotkey` |
| `a'hi'` | `alert` |
| `s0.5` | `sleep` |
| `p0.2` | set `PAUSE` for the rest of this `run` (restored after) |
| `f3(cc)` | repeat inner commands 3 times |

Whitespace is ignored. Quotes must be single quotes.

## CLI

After `gem install autogui` the `autogui` executable is on your PATH:

```
autogui info
autogui mouse                 # live X/Y/RGB; Ctrl-C to quit
autogui screenshot out.png
```

From a git checkout: `ruby bin/autogui info`.

## Platforms

- **Windows** — `user32` / `gdi32` through `Fiddle`. DPI-aware. Unicode typing via `SendInput`. Window enumeration via `EnumWindows`.
- **macOS** — System Events through `osascript`; captures with `screencapture`. Enable Accessibility for the process running Ruby.
- **Linux** — `xdotool` for input; `scrot` / `import` / `grim` for captures.

## Exceptions

| Class | When |
| --- | --- |
| `AutoGUI::AutoGUIException` | invalid arguments, missing tools, bad images |
| `AutoGUI::FailSafeException` | cursor on a fail-safe corner |
| `AutoGUI::ImageNotFoundException` | locate\* miss *and* exceptions enabled |

## API reference

See **[docs/api.md](docs/api.md)** for every method, alias, return type, and option.

See **[docs/guide.md](docs/guide.md)** for recipes, coordinate details, and the command language.

See **[CHANGELOG.md](CHANGELOG.md)** for releases.

## Development

```
git clone https://github.com/pardeep2690/autogui.git
cd autogui
ruby -Ilib:test test/test_autogui.rb
```

Live mouse tests stay skipped unless you opt in:

```
# Unix
AUTOGUI_LIVE=1 ruby -Ilib:test test/test_autogui.rb

# Windows PowerShell
$env:AUTOGUI_LIVE=1; ruby -Ilib:test test/test_autogui.rb
```

Examples:

```
ruby -Ilib examples/hello.rb
ruby -Ilib examples/locate_demo.rb path/to/needle.png
```

Publishing this gem to RubyGems is documented in [docs/publishing.md](docs/publishing.md).

## License

BSD 3-Clause. API and behavior follow [PyAutoGUI](https://github.com/asweigart/pyautogui) (Al Sweigart).
