# frozen_string_literal: true

require "fiddle"
require "fiddle/import"
require "fiddle/types"

module AutoGUI
  module Platform
    module Windows
      extend Fiddle::Importer
      dlload "user32", "gdi32", "kernel32"

      typealias "HWND", "void*"
      typealias "HDC", "void*"
      typealias "HBITMAP", "void*"
      typealias "HGDIOBJ", "void*"
      typealias "DWORD", "unsigned long"
      typealias "UINT", "unsigned int"
      typealias "LONG", "long"
      typealias "WORD", "unsigned short"
      typealias "BYTE", "unsigned char"
      typealias "BOOL", "int"
      typealias "UINT_PTR", "size_t"
      typealias "ULONG_PTR", "size_t"
      typealias "SHORT", "short"
      typealias "WCHAR", "unsigned short"

      extern "int GetCursorPos(void*)"
      extern "int SetCursorPos(int, int)"
      extern "int GetSystemMetrics(int)"
      extern "void mouse_event(DWORD, DWORD, DWORD, DWORD, ULONG_PTR)"
      extern "void keybd_event(BYTE, BYTE, DWORD, ULONG_PTR)"
      extern "int SetProcessDPIAware()"
      extern "SHORT VkKeyScanW(WCHAR)"
      extern "UINT SendInput(UINT, void*, int)"
      extern "int MessageBoxW(HWND, void*, void*, UINT)"
      extern "HDC GetDC(HWND)"
      extern "int ReleaseDC(HWND, HDC)"
      extern "DWORD GetPixel(HDC, int, int)"
      extern "HDC CreateCompatibleDC(HDC)"
      extern "HBITMAP CreateCompatibleBitmap(HDC, int, int)"
      extern "HGDIOBJ SelectObject(HDC, HGDIOBJ)"
      extern "int BitBlt(HDC, int, int, int, int, HDC, int, int, DWORD)"
      extern "int GetDIBits(HDC, HBITMAP, UINT, UINT, void*, void*, UINT)"
      extern "int DeleteObject(HGDIOBJ)"
      extern "int DeleteDC(HDC)"
      extern "HWND GetForegroundWindow()"
      extern "int SetForegroundWindow(HWND)"
      extern "int GetWindowTextW(HWND, void*, int)"
      extern "int GetWindowTextLengthW(HWND)"
      extern "int GetWindowRect(HWND, void*)"
      extern "int IsWindowVisible(HWND)"
      extern "int IsIconic(HWND)"
      extern "int IsZoomed(HWND)"
      extern "int ShowWindow(HWND, int)"
      extern "int MoveWindow(HWND, int, int, int, int, int)"
      extern "HWND GetTopWindow(HWND)"
      extern "HWND GetWindow(HWND, UINT)"
      extern "int IsWindow(HWND)"
      extern "int PostMessageW(HWND, UINT, UINT_PTR, LONG)"
      extern "DWORD GetWindowThreadProcessId(HWND, void*)"
      extern "DWORD GetCurrentThreadId()"
      extern "int AttachThreadInput(DWORD, DWORD, int)"
      extern "int BringWindowToTop(HWND)"
      extern "int SetWindowPos(HWND, HWND, int, int, int, int, UINT)"
      extern "HWND WindowFromPoint(long long)"

      MOUSEEVENTF_MOVE = 0x0001
      MOUSEEVENTF_LEFTDOWN = 0x0002
      MOUSEEVENTF_LEFTUP = 0x0004
      MOUSEEVENTF_RIGHTDOWN = 0x0008
      MOUSEEVENTF_RIGHTUP = 0x0010
      MOUSEEVENTF_MIDDLEDOWN = 0x0020
      MOUSEEVENTF_MIDDLEUP = 0x0040
      MOUSEEVENTF_WHEEL = 0x0800
      MOUSEEVENTF_HWHEEL = 0x01000
      MOUSEEVENTF_ABSOLUTE = 0x8000
      KEYEVENTF_KEYUP = 0x0002
      KEYEVENTF_UNICODE = 0x0004
      INPUT_KEYBOARD = 1
      SRCCOPY = 0x00CC0020
      CAPTUREBLT = 0x40000000
      DIB_RGB_COLORS = 0
      SM_CXSCREEN = 0
      SM_CYSCREEN = 1
      SM_SWAPBUTTON = 23
      GW_HWNDNEXT = 2
      SW_HIDE = 0
      SW_SHOWNORMAL = 1
      SW_SHOWMINIMIZED = 2
      SW_SHOWMAXIMIZED = 3
      SW_RESTORE = 9
      WM_CLOSE = 0x0010
      HWND_TOP = 0
      SWP_NOSIZE = 0x0001
      SWP_NOMOVE = 0x0002
      SWP_SHOWWINDOW = 0x0040
      WHEEL_DELTA = 120

      VK_MAP = {
        "backspace" => 0x08, "\b" => 0x08, "super" => 0x5B, "tab" => 0x09, "\t" => 0x09,
        "clear" => 0x0c, "enter" => 0x0d, "\n" => 0x0d, "\r" => 0x0d, "return" => 0x0d,
        "shift" => 0x10, "ctrl" => 0x11, "alt" => 0x12, "pause" => 0x13, "capslock" => 0x14,
        "kana" => 0x15, "hanguel" => 0x15, "hangul" => 0x15, "junja" => 0x17, "final" => 0x18,
        "hanja" => 0x19, "kanji" => 0x19, "esc" => 0x1b, "escape" => 0x1b, "convert" => 0x1c,
        "nonconvert" => 0x1d, "accept" => 0x1e, "modechange" => 0x1f, " " => 0x20, "space" => 0x20,
        "pgup" => 0x21, "pgdn" => 0x22, "pageup" => 0x21, "pagedown" => 0x22, "end" => 0x23,
        "home" => 0x24, "left" => 0x25, "up" => 0x26, "right" => 0x27, "down" => 0x28,
        "select" => 0x29, "print" => 0x2a, "execute" => 0x2b, "prtsc" => 0x2c, "prtscr" => 0x2c,
        "prntscrn" => 0x2c, "printscreen" => 0x2c, "insert" => 0x2d, "del" => 0x2e, "delete" => 0x2e,
        "help" => 0x2f, "win" => 0x5b, "winleft" => 0x5b, "winright" => 0x5c, "apps" => 0x5d,
        "sleep" => 0x5f, "num0" => 0x60, "num1" => 0x61, "num2" => 0x62, "num3" => 0x63,
        "num4" => 0x64, "num5" => 0x65, "num6" => 0x66, "num7" => 0x67, "num8" => 0x68,
        "num9" => 0x69, "multiply" => 0x6a, "add" => 0x6b, "separator" => 0x6c, "subtract" => 0x6d,
        "decimal" => 0x6e, "divide" => 0x6f, "f1" => 0x70, "f2" => 0x71, "f3" => 0x72, "f4" => 0x73,
        "f5" => 0x74, "f6" => 0x75, "f7" => 0x76, "f8" => 0x77, "f9" => 0x78, "f10" => 0x79,
        "f11" => 0x7a, "f12" => 0x7b, "f13" => 0x7c, "f14" => 0x7d, "f15" => 0x7e, "f16" => 0x7f,
        "f17" => 0x80, "f18" => 0x81, "f19" => 0x82, "f20" => 0x83, "f21" => 0x84, "f22" => 0x85,
        "f23" => 0x86, "f24" => 0x87, "numlock" => 0x90, "scrolllock" => 0x91, "shiftleft" => 0xa0,
        "shiftright" => 0xa1, "ctrlleft" => 0xa2, "ctrlright" => 0xa3, "altleft" => 0xa4,
        "altright" => 0xa5, "browserback" => 0xa6, "browserforward" => 0xa7, "browserrefresh" => 0xa8,
        "browserstop" => 0xa9, "browsersearch" => 0xaa, "browserfavorites" => 0xab,
        "browserhome" => 0xac, "volumemute" => 0xad, "volumedown" => 0xae, "volumeup" => 0xaf,
        "nexttrack" => 0xb0, "prevtrack" => 0xb1, "stop" => 0xb2, "playpause" => 0xb3,
        "launchmail" => 0xb4, "launchmediaselect" => 0xb5, "launchapp1" => 0xb6, "launchapp2" => 0xb7,
        "command" => 0x5b, "option" => 0x12, "optionleft" => 0xa4, "optionright" => 0xa5
      }.freeze

      module_function

      def init!
        SetProcessDPIAware()
      rescue StandardError
        nil
      end

      def keyboard_mapping
        @keyboard_mapping ||= begin
          map = {}
          KEY_NAMES.each { |k| map[k] = nil }
          map.merge!(VK_MAP)
          (32...127).each do |code|
            ch = code.chr
            map[ch] = VkKeyScanW(code)
          end
          map
        end
      end

      def position
        buf = "\x00".b * 8
        GetCursorPos(buf)
        buf.unpack("ll")
      end

      def size
        [GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN)]
      end

      def move_to(x, y)
        SetCursorPos(x.to_i, y.to_i)
      end

      def mouse_is_swapped?
        GetSystemMetrics(SM_SWAPBUTTON) != 0
      end

      def mouse_down(x, y, button)
        send_mouse(button_flag(button, :down), x, y)
      end

      def mouse_up(x, y, button)
        send_mouse(button_flag(button, :up), x, y)
      end

      def click(x, y, button)
        send_mouse(button_flag(button, :down) | button_flag(button, :up), x, y)
      end

      def scroll(clicks, x, y)
        send_mouse(MOUSEEVENTF_WHEEL, x, y, clicks.to_i * WHEEL_DELTA)
      end

      def hscroll(clicks, x, y)
        send_mouse(MOUSEEVENTF_HWHEEL, x, y, clicks.to_i * WHEEL_DELTA)
      end

      alias vscroll scroll

      def key_down(key)
        dispatch_key(key, up: false)
      end

      def key_up(key)
        dispatch_key(key, up: true)
      end

      def screenshot(region = nil)
        screen_w, screen_h = size
        if region
          left, top, width, height = region.to_a
        else
          left = 0
          top = 0
          width = screen_w
          height = screen_h
        end
        hdc_screen = GetDC(nil)
        hdc_mem = CreateCompatibleDC(hdc_screen)
        hbmp = CreateCompatibleBitmap(hdc_screen, width, height)
        old = SelectObject(hdc_mem, hbmp)
        BitBlt(hdc_mem, 0, 0, width, height, hdc_screen, left, top, SRCCOPY | CAPTUREBLT)

        bmi = [40, width, -height, 1, 32, 0, 0, 0, 0, 0, 0].pack("LllSSLLllLL")
        buf = "\x00".b * (width * height * 4)
        GetDIBits(hdc_mem, hbmp, 0, height, buf, bmi, DIB_RGB_COLORS)

        SelectObject(hdc_mem, old)
        DeleteObject(hbmp)
        DeleteDC(hdc_mem)
        ReleaseDC(nil, hdc_screen)
        Image.from_bgra(width, height, buf)
      end

      def pixel(x, y)
        hdc = GetDC(nil)
        color = GetPixel(hdc, x.to_i, y.to_i) & 0xFFFFFFFF
        ReleaseDC(nil, hdc)
        r = color & 0xFF
        g = (color >> 8) & 0xFF
        b = (color >> 16) & 0xFF
        [r, g, b]
      end

      def message_box(text, title, flags)
        MessageBoxW(nil, wide(text), wide(title), flags)
      end

      def window_from_point(x, y)
        packed = [x.to_i, y.to_i].pack("ll").unpack1("q<")
        hwnd = WindowFromPoint(packed)
        hwnd.null? ? nil : hwnd
      rescue StandardError
        nil
      end

      def each_hwnd
        hwnds = []
        callback = Fiddle::Closure::BlockCaller.new(
          Fiddle::TYPE_INT,
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP]
        ) do |hwnd, _lparam|
          hwnds << hwnd
          1
        end
        begin
          enum_windows_fn.call(callback, 0)
        rescue StandardError
          hwnd = GetTopWindow(0)
          while hwnd && !hwnd.null? && hwnd.to_i != 0
            hwnds << hwnd
            hwnd = GetWindow(hwnd, GW_HWNDNEXT)
            break if hwnd.nil? || hwnd.null? || hwnd.to_i.zero?
          end
        end
        hwnds.each { |h| yield h }
      end

      def enum_windows_fn
        @enum_windows_fn ||= Fiddle::Function.new(
          Fiddle::Handle.new("user32")["EnumWindows"],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
          Fiddle::TYPE_INT
        )
      end

      def window_title(hwnd)
        len = GetWindowTextLengthW(hwnd)
        return "" if len <= 0

        buf = "\x00".b * ((len + 1) * 2)
        GetWindowTextW(hwnd, buf, len + 1)
        buf.force_encoding("UTF-16LE").encode("UTF-8").delete("\x00")
      end

      def window_rect(hwnd)
        buf = "\x00".b * 16
        GetWindowRect(hwnd, buf)
        left, top, right, bottom = buf.unpack("l4")
        [left, top, right - left, bottom - top]
      end

      def window_visible?(hwnd)
        IsWindowVisible(hwnd) != 0
      end

      def window_minimized?(hwnd)
        IsIconic(hwnd) != 0
      end

      def window_maximized?(hwnd)
        IsZoomed(hwnd) != 0
      end

      def activate_window(hwnd)
        tid_fg = GetWindowThreadProcessId(GetForegroundWindow(), nil)
        tid_this = GetCurrentThreadId()
        AttachThreadInput(tid_this, tid_fg, 1) unless tid_fg == tid_this
        ShowWindow(hwnd, SW_RESTORE) if window_minimized?(hwnd)
        BringWindowToTop(hwnd)
        SetForegroundWindow(hwnd)
        SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW)
      ensure
        AttachThreadInput(tid_this, tid_fg, 0) unless tid_fg == tid_this
      end

      def show_window(hwnd, cmd)
        ShowWindow(hwnd, cmd)
      end

      def move_window(hwnd, x, y, w, h)
        MoveWindow(hwnd, x, y, w, h, 1)
      end

      def close_window(hwnd)
        PostMessageW(hwnd, WM_CLOSE, 0, 0)
      end

      def valid_window?(hwnd)
        hwnd && !hwnd.null? && hwnd.to_i != 0 && IsWindow(hwnd) != 0
      end

      def send_mouse(flags, x, y, data = 0)
        width, height = size
        cx = ((65_536 * x.to_i) / width) + 1
        cy = ((65_536 * y.to_i) / height) + 1
        mouse_event(flags, cx, cy, data, 0)
      end

      def button_flag(button, dir)
        case [button.to_s, dir]
        when ["left", :down] then MOUSEEVENTF_LEFTDOWN
        when ["left", :up] then MOUSEEVENTF_LEFTUP
        when ["middle", :down] then MOUSEEVENTF_MIDDLEDOWN
        when ["middle", :up] then MOUSEEVENTF_MIDDLEUP
        when ["right", :down] then MOUSEEVENTF_RIGHTDOWN
        when ["right", :up] then MOUSEEVENTF_RIGHTUP
        else
          raise AutoGUIException, "button must be left, middle, or right (got #{button.inspect})"
        end
      end

      def dispatch_key(key, up:)
        if key.length == 1 && (keyboard_mapping[key].nil? || key.ord > 127)
          send_unicode(key, up: up)
          return
        end

        mapped = keyboard_mapping[key]
        if mapped.nil?
          if key.length == 1
            send_unicode(key, up: up)
          end
          return
        end

        needs_shift = AutoGUI.shift_character?(key)
        mods, vk = mapped.divmod(0x100)
        mods_order_down = [[mods & 4, 0x12], [mods & 2, 0x11], [mods & 1 != 0 || needs_shift, 0x10]]
        mods_order_up = mods_order_down.reverse
        unless up
          mods_order_down.each { |apply, vk_mod| keybd_event(vk_mod, 0, 0, 0) if apply }
          keybd_event(vk, 0, 0, 0)
          mods_order_up.each { |apply, vk_mod| keybd_event(vk_mod, 0, KEYEVENTF_KEYUP, 0) if apply }
        else
          mods_order_down.each { |apply, vk_mod| keybd_event(vk_mod, 0, 0, 0) if apply }
          keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)
          mods_order_up.each { |apply, vk_mod| keybd_event(vk_mod, 0, KEYEVENTF_KEYUP, 0) if apply }
        end
      end

      def send_unicode(char, up:)
        flags = KEYEVENTF_UNICODE
        flags |= KEYEVENTF_KEYUP if up
        scan = char.ord
        ki = [0, scan, flags, 0].pack("SSLL")
        pad = 32 - ki.bytesize
        pad = 0 if pad.negative?
        union = ki + ("\x00".b * pad)
        union = union.byteslice(0, 32).ljust(32, "\x00".b)
        input = [INPUT_KEYBOARD].pack("L") + [0].pack("L") + union
        SendInput(1, input, input.bytesize)
      end

      def wide(str)
        (str.to_s.encode("UTF-16LE") + "\x00\x00".b).b
      end
    end
  end
end
