# frozen_string_literal: true

module AutoGUI
  class Window
    SW_HIDE = 0
    SW_SHOWNORMAL = 1
    SW_SHOWMINIMIZED = 2
    SW_SHOWMAXIMIZED = 3
    SW_RESTORE = 9

    attr_reader :hwnd

    def initialize(hwnd)
      @hwnd = hwnd
    end

    def title
      Platform.current.window_title(@hwnd)
    end

    def box
      left, top, width, height = Platform.current.window_rect(@hwnd)
      Box.new(left, top, width, height)
    end

    def left
      box.left
    end

    def top
      box.top
    end

    def width
      box.width
    end

    def height
      box.height
    end

    def right
      left + width
    end

    def bottom
      top + height
    end

    def visible?
      Platform.current.window_visible?(@hwnd)
    end

    def minimized?
      Platform.current.window_minimized?(@hwnd)
    end

    def maximized?
      Platform.current.window_maximized?(@hwnd)
    end

    def activate
      Platform.current.activate_window(@hwnd)
      self
    end

    def minimize
      Platform.current.show_window(@hwnd, SW_SHOWMINIMIZED)
      self
    end

    def maximize
      Platform.current.show_window(@hwnd, SW_SHOWMAXIMIZED)
      self
    end

    def restore
      Platform.current.show_window(@hwnd, SW_RESTORE)
      self
    end

    def hide
      Platform.current.show_window(@hwnd, SW_HIDE)
      self
    end

    def close
      Platform.current.close_window(@hwnd)
      self
    end

    def moveTo(x, y)
      Platform.current.move_window(@hwnd, x.to_i, y.to_i, width, height)
      self
    end
    alias move_to moveTo

    def resizeTo(w, h)
      Platform.current.move_window(@hwnd, left, top, w.to_i, h.to_i)
      self
    end
    alias resize_to resizeTo

    def to_s
      "Window(title=#{title.inspect}, box=#{box})"
    end
    alias inspect to_s

    def ==(other)
      other.is_a?(Window) && other.hwnd.to_i == @hwnd.to_i
    end
  end

  module WindowFunctions
    module_function

    def getAllWindows
      windows = []
      return windows unless Platform.current.respond_to?(:each_hwnd)

      Platform.current.each_hwnd do |hwnd|
        next unless Platform.current.window_visible?(hwnd)

        title = Platform.current.window_title(hwnd)
        next if title.nil? || title.empty?

        windows << Window.new(hwnd)
      end
      windows
    end
    alias get_all_windows getAllWindows

    def getAllTitles
      getAllWindows.map(&:title)
    end
    alias get_all_titles getAllTitles

    def getWindowsWithTitle(title)
      re = title.is_a?(Regexp) ? title : /#{Regexp.escape(title.to_s)}/i
      getAllWindows.select { |w| w.title.match?(re) }
    end
    alias get_windows_with_title getWindowsWithTitle

    def getWindowsAt(x, y)
      getAllWindows.select do |w|
        b = w.box
        x >= b.left && x < b.left + b.width && y >= b.top && y < b.top + b.height
      end
    end
    alias get_windows_at getWindowsAt

    def getActiveWindow
      return nil unless Platform.current.respond_to?(:GetForegroundWindow)

      hwnd = Platform.current.GetForegroundWindow()
      return nil unless Platform.current.valid_window?(hwnd)

      Window.new(hwnd)
    rescue StandardError
      nil
    end
    alias get_active_window getActiveWindow

    def getActiveWindowTitle
      w = getActiveWindow
      w&.title
    end
    alias get_active_window_title getActiveWindowTitle
  end
end
