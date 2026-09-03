# AutoGUI API reference

All methods below live on the `AutoGUI` module unless noted. Snake_case is canonical. CamelCase aliases are listed in the Alias column.

Return values that unpack (`Point`, `Size`, `Box`) also respond to `to_a`, `[]`, and named readers.

---

## Screen and cursor

| Method | Alias | Returns | Notes |
| --- | --- | --- | --- |
| `size` | `resolution` | `Size` | Primary monitor width × height |
| `position(x = nil, y = nil)` | | `Point` | Override x and/or y if passed |
| `on_screen(x, y = nil)` | `onScreen` | `true`/`false` | Also accepts `[x, y]` |
| `pixel(x, y)` | | `[r, g, b]` | 0–255 each |
| `pixel_matches_color(x, y, rgb, tolerance: 0)` | `pixelMatchesColor` | `true`/`false` | `rgb` is `[r, g, b]` |
| `print_info(dont_print = false)` | `printInfo` | `String` | Also prints unless `dont_print` |
| `get_info` | `getInfo` | Array | platform, Ruby, version, executable, size, timestamp |
| `sleep(seconds)` | | `nil` | `Kernel.sleep` |
| `countdown(seconds)` | | `nil` | Prints `3 2 1` |
| `fail_safe_check` | `failSafeCheck` | `nil` or raises | Used internally |

---

## Mouse

Shared keywords on movement/click helpers: `duration:` (seconds), `tween:` (callable), `logScreenshot:` (`true`/`false`/`nil`), `_pause:` (internal).

`x` / `y` follow [coordinate rules](guide.md#coordinates): numbers, `[x, y]`, a `Box`, or an image filename.

| Method | Alias | Notes |
| --- | --- | --- |
| `move_to(x = nil, y = nil, duration: 0)` | `moveTo` | Absolute move |
| `move(x = nil, y = nil, duration: 0)` | `move_rel`, `moveRel` | Relative move |
| `drag_to(x = nil, y = nil, duration: 0, button: "primary", mouseDownUp: true)` | `dragTo` | Drag while holding `button` |
| `drag(x = 0, y = 0, ...)` | `drag_rel`, `dragRel` | Relative drag |
| `click(x = nil, y = nil, clicks: 1, interval: 0, button: "primary", duration: 0)` | | |
| `left_click(...)` | `leftClick` | |
| `right_click(...)` | `rightClick` | |
| `middle_click(...)` | `middleClick` | |
| `double_click(..., button: "left")` | `doubleClick` | |
| `triple_click(..., button: "left")` | `tripleClick` | |
| `mouse_down(x = nil, y = nil, button: "primary")` | `mouseDown` | |
| `mouse_up(x = nil, y = nil, button: "primary")` | `mouseUp` | |
| `scroll(clicks, x = nil, y = nil)` | | Positive = up |
| `hscroll(clicks, x = nil, y = nil)` | | Horizontal |
| `vscroll(clicks, x = nil, y = nil)` | | Vertical (same as `scroll` on Windows) |
| `display_mouse_position(x_offset = 0, y_offset = 0)` | `displayMousePosition`, `mouseInfo`, `mouse_info` | Live HUD; Ctrl-C to quit |

Buttons: `"left"` `"middle"` `"right"` `"primary"` `"secondary"` or `1` `2` `3`. On Linux, `4`–`7` are extra buttons.

---

## Keyboard

| Method | Alias | Notes |
| --- | --- | --- |
| `write(message, interval: 0)` | `typewrite` | String of chars, or array of key names |
| `press(keys, presses: 1, interval: 0)` | | String or array of key names |
| `hotkey(*keys, interval: 0)` | `shortcut` | Down in order, up in reverse |
| `hold(keys) { ... }` | | Requires a block; releases in `ensure` |
| `key_down(key)` | `keyDown` | |
| `key_up(key)` | `keyUp` | |
| `valid_key?(key)` | `isValidKey`, `is_valid_key` | |
| `shift_character?(ch)` | `isShiftCharacter` | Uppercase or `~!@#$…` |

`keys` / `key` values are strings from `AutoGUI::KEYBOARD_KEYS` (also `AutoGUI::KEY_NAMES`).

Modifier aliases: `ctrl` = left ctrl, `alt` = left alt, `shift` = left shift, `win` / `command` = left Super/Cmd.

---

## Screenshots and locate

| Method | Alias | Returns |
| --- | --- | --- |
| `screenshot(path = nil, region: nil)` | `grab` | `Image`; saves if `path` given |
| `locate_on_screen(image, grayscale: false, confidence: nil, region: nil, minSearchTime: 0)` | `locateOnScreen` | `Box` or `nil` |
| `locate_center_on_screen(...)` | `locateCenterOnScreen` | `Point` or `nil` |
| `locate_all_on_screen(...)` | `locateAllOnScreen` | Enumerator of `Box` |
| `locate(needle, haystack, grayscale: false, confidence: nil)` | | `Box` or `nil` |
| `locate_all(needle, haystack, ...)` | `locateAll` | Enumerator of `Box` |
| `locate_on_window(image, title, ...)` | `locateOnWindow` | `Box` in that window |
| `center(box)` | | `Point` |
| `use_image_not_found_exception!(value = true)` | `useImageNotFoundException` | miss raises instead of `nil` |

`region` is `[left, top, width, height]`. `image` / `needle` / `haystack` may be a path or an `AutoGUI::Image`.

### `AutoGUI::Image`

| Method | Notes |
| --- | --- |
| `Image.open(path)` | PNG or uncompressed BMP |
| `Image.from_pixels(w, h, [[r,g,b], ...])` | |
| `#width` `#height` `#data` | RGB bytes, top-down |
| `#getpixel(x, y)` | `[r, g, b]` |
| `#putpixel(x, y, [r, g, b])` | |
| `#crop(left, top, width, height)` | new `Image` |
| `#grayscale` | new `Image` |
| `#save(path)` | `.png` or `.bmp` from extension |
| `#to_png` `#to_bmp` | binary strings |

---

## Dialogs

| Method | Returns |
| --- | --- |
| `alert(text = "", title = "", button = "OK")` | button label |
| `confirm(text = "", title = "", buttons = ["OK", "Cancel"])` | chosen label |
| `prompt(text = "", title = "", default = "")` | string or `nil` |
| `password(text = "", title = "", default = "", mask = "*")` | string or `nil` |

---

## Window objects (Windows OS)

Module functions:

| Method | Alias |
| --- | --- |
| `get_all_windows` | `getAllWindows` |
| `get_all_titles` | `getAllTitles` |
| `get_active_window` | `getActiveWindow` |
| `get_active_window_title` | `getActiveWindowTitle` |
| `get_windows_with_title(title)` | `getWindowsWithTitle` |
| `get_windows_at(x, y)` | `getWindowsAt` |

`AutoGUI::Window` instance:

| Method | Notes |
| --- | --- |
| `#title` `#hwnd` | |
| `#left` `#top` `#width` `#height` `#right` `#bottom` `#box` | |
| `#visible?` `#minimized?` `#maximized?` | |
| `#activate` `#minimize` `#maximize` `#restore` `#hide` `#close` | chainable |
| `#move_to(x, y)` | alias `moveTo` |
| `#resize_to(w, h)` | alias `resizeTo` |

---

## Geometry

```ruby
AutoGUI::Point.new(x, y)           # #x #y
AutoGUI::Size.new(width, height)   # #width #height
AutoGUI::Box.new(left, top, width, height)
```

All three implement `#to_a`, `#to_ary` (so `x, y = point` works), `#[]`, and `#==` against arrays.

---

## Tweens

`AutoGUI.linear(n)` and `AutoGUI.easeInQuad(n)` … `AutoGUI.easeInOutBounce(n)` — see the README. `n` must be in `0.0..1.0` or `AutoGUIException` is raised.

`get_point_on_line(x1, y1, x2, y2, n)` → `[x, y]` (`getPointOnLine`).

---

## Mini-language

`AutoGUI.run(command_string)` — tokens documented in the README and [guide.md](guide.md#mini-language).

---

## Constants

| Name | Value |
| --- | --- |
| `AutoGUI::VERSION` | gem version string |
| `AutoGUI::LEFT` `MIDDLE` `RIGHT` `PRIMARY` `SECONDARY` | button names |
| `AutoGUI::KEYBOARD_KEYS` | array of valid key strings (`KEY_NAMES`) |
| `AutoGUI::QWERTY` `QWERTZ` | layout strings |

---

## Exceptions

```ruby
AutoGUI::AutoGUIException          # StandardError
AutoGUI::FailSafeException         # < AutoGUIException
AutoGUI::ImageNotFoundException    # < AutoGUIException
```
