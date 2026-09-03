# frozen_string_literal: true

require "open3"
require "tempfile"

module AutoGUI
  module Platform
    # macOS backend. Prefers CoreGraphics via Fiddle; falls back to osascript / screencapture.
    module Darwin
      KEYBOARD_CODES = {
        "a" => 0x00, "s" => 0x01, "d" => 0x02, "f" => 0x03, "h" => 0x04, "g" => 0x05,
        "z" => 0x06, "x" => 0x07, "c" => 0x08, "v" => 0x09, "b" => 0x0B, "q" => 0x0C,
        "w" => 0x0D, "e" => 0x0E, "r" => 0x0F, "y" => 0x10, "t" => 0x11, "1" => 0x12,
        "2" => 0x13, "3" => 0x14, "4" => 0x15, "6" => 0x16, "5" => 0x17, "=" => 0x18,
        "9" => 0x19, "7" => 0x1A, "-" => 0x1B, "8" => 0x1C, "0" => 0x1D, "]" => 0x1E,
        "o" => 0x1F, "u" => 0x20, "[" => 0x21, "i" => 0x22, "p" => 0x23, "l" => 0x25,
        "j" => 0x26, "'" => 0x27, "k" => 0x28, ";" => 0x29, "\\" => 0x2A, "," => 0x2B,
        "/" => 0x2C, "n" => 0x2D, "m" => 0x2E, "." => 0x2F, "`" => 0x32, " " => 0x31,
        "space" => 0x31, "enter" => 0x24, "return" => 0x24, "\n" => 0x24, "\r" => 0x24,
        "tab" => 0x30, "\t" => 0x30, "backspace" => 0x33, "esc" => 0x35, "escape" => 0x35,
        "command" => 0x37, "shift" => 0x38, "shiftleft" => 0x38, "capslock" => 0x39,
        "alt" => 0x3A, "option" => 0x3A, "optionleft" => 0x3A, "altleft" => 0x3A,
        "ctrl" => 0x3B, "ctrlleft" => 0x3B, "shiftright" => 0x3C, "altright" => 0x3D,
        "optionright" => 0x3D, "ctrlright" => 0x3E, "fn" => 0x3F, "f17" => 0x40,
        "volumeup" => 0x48, "volumedown" => 0x49, "volumemute" => 0x4A, "f18" => 0x4F,
        "f19" => 0x50, "f20" => 0x5A, "f5" => 0x60, "f6" => 0x61, "f7" => 0x62,
        "f3" => 0x63, "f8" => 0x64, "f9" => 0x65, "f11" => 0x67, "f13" => 0x69,
        "f16" => 0x6A, "f14" => 0x6B, "f10" => 0x6D, "f12" => 0x6F, "f15" => 0x71,
        "help" => 0x72, "home" => 0x73, "pageup" => 0x74, "pgup" => 0x74, "del" => 0x75,
        "delete" => 0x75, "f4" => 0x76, "end" => 0x77, "f2" => 0x78, "pagedown" => 0x79,
        "pgdn" => 0x79, "f1" => 0x7A, "left" => 0x7B, "right" => 0x7C, "down" => 0x7D,
        "up" => 0x7E, "win" => 0x37, "winleft" => 0x37
      }.freeze

      OSA_KEYS = {
        "enter" => "return", "return" => "return", "esc" => "escape", "escape" => "escape",
        "ctrl" => "control", "ctrlleft" => "control", "alt" => "option", "option" => "option",
        "command" => "command", "win" => "command", "shift" => "shift", "tab" => "tab",
        "space" => "space", "up" => "up arrow", "down" => "down arrow",
        "left" => "left arrow", "right" => "right arrow", "backspace" => "delete",
        "delete" => "forward delete", "home" => "home", "end" => "end",
        "pageup" => "page up", "pagedown" => "page down"
      }.freeze

      module_function

      def init!; end

      def keyboard_mapping
        @keyboard_mapping ||= begin
          map = {}
          KEY_NAMES.each { |k| map[k] = KEYBOARD_CODES[k] }
          ("a".."z").each { |c| map[c] = KEYBOARD_CODES[c] }
          map
        end
      end

      def position
        out, status = Open3.capture2("osascript", "-e",
                                     'tell application "System Events" to get the {x, y} of the mouse')
        if status.success?
          x, y = out.strip.split(",").map { |v| v.strip.to_i }
          return [x, y]
        end
        quartz_position || [0, 0]
      end

      def size
        out, status = Open3.capture2("osascript", "-e",
                                     'tell application "Finder" to get bounds of window of desktop')
        if status.success?
          parts = out.split(",").map { |v| v.strip.to_i }
          return [parts[2], parts[3]] if parts.length == 4
        end
        quartz_size || [1440, 900]
      end

      def move_to(x, y)
        system("osascript", "-e", "tell application \"System Events\" to set the mouse location to {#{x.to_i}, #{y.to_i}}")
        sleep(AutoGUI.darwin_catch_up_time)
      end

      def mouse_is_swapped?
        false
      end

      def mouse_down(x, y, button)
        osa_click(x, y, button, "mousedown")
      end

      def mouse_up(x, y, button)
        osa_click(x, y, button, "mouseup")
      end

      def click(x, y, button)
        btn = osa_button(button)
        system("osascript", "-e",
               "tell application \"System Events\" to click at {#{x.to_i}, #{y.to_i}}") if btn == "left"
        system("osascript", "-e",
               "tell application \"System Events\" to #{btn} click at {#{x.to_i}, #{y.to_i}}") unless btn == "left"
        sleep(AutoGUI.darwin_catch_up_time)
      end

      def scroll(clicks, x, y)
        move_to(x, y)
        direction = clicks.to_i.positive? ? "up" : "down"
        n = clicks.to_i.abs
        system("osascript", "-e",
               "tell application \"System Events\" to scroll #{direction} #{n}")
      end

      alias vscroll scroll

      def hscroll(clicks, x, y)
        scroll(clicks, x, y)
      end

      def key_down(key)
        osa_key(key, "key down")
      end

      def key_up(key)
        osa_key(key, "key up")
      end

      def screenshot(region = nil)
        file = Tempfile.new(["autogui", ".png"])
        file.close
        system("screencapture", "-x", file.path)
        img = Image.open(file.path)
        File.unlink(file.path) rescue nil
        if region
          left, top, width, height = region.to_a
          img.crop(left, top, width, height)
        else
          img
        end
      end

      def pixel(x, y)
        screenshot([x, y, 1, 1]).getpixel(0, 0)
      end

      def message_box(text, title, _flags)
        script = %(display dialog #{text.to_s.inspect} with title #{title.to_s.inspect} buttons {"OK"} default button 1)
        system("osascript", "-e", script)
        1
      end

      def each_hwnd; end

      def quartz_position
        nil
      end

      def quartz_size
        nil
      end

      def osa_button(button)
        case button.to_s
        when "left" then "left"
        when "right" then "right"
        when "middle" then "middle"
        else "left"
        end
      end

      def osa_click(x, y, button, _kind)
        move_to(x, y)
        click(x, y, button)
      end

      def osa_key(key, action)
        name = OSA_KEYS[key] || (key.length == 1 ? key : key)
        if name.length == 1
          system("osascript", "-e", "tell application \"System Events\" to #{action} #{name.inspect}")
        else
          system("osascript", "-e", "tell application \"System Events\" to #{action} #{name}")
        end
        sleep(AutoGUI.darwin_catch_up_time)
      end
    end
  end
end
