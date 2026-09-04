# frozen_string_literal: true

require "open3"
require "tempfile"

module AutoGUI
  module Platform
    # Linux backend. Uses xdotool when present, with xte / ImageMagick / scrot fallbacks.
    module Linux
      XDOTOOL_KEYS = {
        "enter" => "Return", "return" => "Return", "\n" => "Return", "\r" => "Return",
        "esc" => "Escape", "escape" => "Escape", "tab" => "Tab", "\t" => "Tab",
        "backspace" => "BackSpace", "delete" => "Delete", "del" => "Delete",
        "space" => "space", " " => "space", "shift" => "shift", "shiftleft" => "Shift_L",
        "shiftright" => "Shift_R", "ctrl" => "ctrl", "ctrlleft" => "Control_L",
        "ctrlright" => "Control_R", "alt" => "alt", "altleft" => "Alt_L",
        "altright" => "Alt_R", "win" => "super", "winleft" => "Super_L",
        "winright" => "Super_R", "command" => "super", "up" => "Up", "down" => "Down",
        "left" => "Left", "right" => "Right", "home" => "Home", "end" => "End",
        "pageup" => "Page_Up", "pgup" => "Page_Up", "pagedown" => "Page_Down",
        "pgdn" => "Page_Down", "capslock" => "Caps_Lock", "numlock" => "Num_Lock",
        "scrolllock" => "Scroll_Lock", "printscreen" => "Print", "insert" => "Insert"
      }.freeze

      module_function

      def init!; end

      def keyboard_mapping
        @keyboard_mapping ||= begin
          map = {}
          KEY_NAMES.each { |k| map[k] = xdo_key(k) }
          map
        end
      end

      def position
        out, status = Open3.capture2("xdotool", "getmouselocation", "--shell")
        if status.success?
          x = out[/X=(\d+)/, 1].to_i
          y = out[/Y=(\d+)/, 1].to_i
          return [x, y]
        end
        [0, 0]
      end

      def size
        out, status = Open3.capture2("xdotool", "getdisplaygeometry")
        if status.success?
          w, h = out.split.map(&:to_i)
          return [w, h] if w.positive? && h.positive?
        end
        out, status = Open3.capture2("xdpyinfo")
        if status.success? && out =~ /dimensions:\s+(\d+)x(\d+)/
          return [Regexp.last_match(1).to_i, Regexp.last_match(2).to_i]
        end

        [1920, 1080]
      end

      def move_to(x, y)
        system("xdotool", "mousemove", x.to_i.to_s, y.to_i.to_s)
      end

      def mouse_is_swapped?
        false
      end

      def mouse_down(x, y, button)
        move_to(x, y)
        system("xdotool", "mousedown", xdo_button(button))
      end

      def mouse_up(x, y, button)
        move_to(x, y)
        system("xdotool", "mouseup", xdo_button(button))
      end

      def click(x, y, button)
        move_to(x, y)
        system("xdotool", "click", xdo_button(button))
      end

      def scroll(clicks, x, y)
        move_to(x, y)
        btn = clicks.to_i.positive? ? "4" : "5"
        clicks.to_i.abs.times { system("xdotool", "click", btn) }
      end

      alias vscroll scroll

      def hscroll(clicks, x, y)
        move_to(x, y)
        btn = clicks.to_i.positive? ? "6" : "7"
        clicks.to_i.abs.times { system("xdotool", "click", btn) }
      end

      def key_down(key)
        system("xdotool", "keydown", xdo_key(key))
      end

      def key_up(key)
        system("xdotool", "keyup", xdo_key(key))
      end

      def screenshot(region = nil)
        file = Tempfile.new(["autogui", ".png"])
        file.close
        captured = false
        if command?("scrot")
          captured = system("scrot", "-o", file.path)
        elsif command?("import")
          captured = system("import", "-window", "root", file.path)
        elsif command?("gnome-screenshot")
          captured = system("gnome-screenshot", "-f", file.path)
        elsif command?("grim")
          captured = system("grim", file.path)
        end
        raise AutoGUIException, "no screenshot tool found (install scrot, imagemagick, or grim)" unless captured && File.size?(file.path)

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
        if command?("zenity")
          system("zenity", "--info", "--title=#{title}", "--text=#{text}")
        elsif command?("kdialog")
          system("kdialog", "--title", title.to_s, "--msgbox", text.to_s)
        elsif command?("xmessage")
          system("xmessage", "-center", "#{title}: #{text}")
        else
          warn("#{title}: #{text}")
        end
        1
      end

      def each_hwnd; end

      def xdo_button(button)
        case button.to_s
        when "left" then "1"
        when "middle" then "2"
        when "right" then "3"
        else button.to_s
        end
      end

      def xdo_key(key)
        return XDOTOOL_KEYS[key] if XDOTOOL_KEYS.key?(key)
        return "F#{Regexp.last_match(1)}" if key =~ /^f(\d+)$/
        return key if key.length == 1

        key
      end

      def command?(name)
        system("which", name, out: File::NULL, err: File::NULL)
      end

      Platform.copy_aliases!(self)
    end
  end
end
