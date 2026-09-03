# frozen_string_literal: true

require "rbconfig"
require "time"

require_relative "autogui/version"
require_relative "autogui/exceptions"
require_relative "autogui/geometry"
require_relative "autogui/keys"
require_relative "autogui/tween"
require_relative "autogui/image"
require_relative "autogui/screenshot"
require_relative "autogui/platform"
require_relative "autogui/message_box"
require_relative "autogui/window"
require_relative "autogui/run"

# AutoGUI — desktop GUI automation for Ruby (mouse, keyboard, screenshots).
#
#   require "autogui"
#   AutoGUI.move_to(100, 150)
#   AutoGUI.click
#   AutoGUI.write("Hello world!")
#
# Install: <tt>gem install autogui</tt>
# Docs: README.md, docs/api.md, docs/guide.md
# Fail-safe: moving the cursor to a screen corner raises {FailSafeException}.
module AutoGUI
  class << self
    attr_accessor :pause, :failsafe, :minimum_duration, :minimum_sleep,
                  :darwin_catch_up_time, :log_screenshots, :log_screenshots_limit,
                  :use_image_not_found_exception
    attr_reader :failsafe_points
  end

  @pause = 0.1
  @failsafe = true
  @minimum_duration = 0.1
  @minimum_sleep = 0.05
  @darwin_catch_up_time = 0.01
  @log_screenshots = false
  @log_screenshots_limit = 10
  @log_screenshot_filenames = []
  @use_image_not_found_exception = false
  @failsafe_points = [Point.new(0, 0)]

  # Python-style constant aliases
  def self.PAUSE
    @pause
  end

  def self.PAUSE=(value)
    @pause = value
  end

  def self.FAILSAFE
    @failsafe
  end

  def self.FAILSAFE=(value)
    @failsafe = value
  end

  def self.FAILSAFE_POINTS
    @failsafe_points
  end

  def self.MINIMUM_DURATION
    @minimum_duration
  end

  def self.MINIMUM_DURATION=(value)
    @minimum_duration = value
  end

  def self.MINIMUM_SLEEP
    @minimum_sleep
  end

  def self.MINIMUM_SLEEP=(value)
    @minimum_sleep = value
  end

  def self.DARWIN_CATCH_UP_TIME
    @darwin_catch_up_time
  end

  def self.DARWIN_CATCH_UP_TIME=(value)
    @darwin_catch_up_time = value
  end

  def self.LOG_SCREENSHOTS
    @log_screenshots
  end

  def self.LOG_SCREENSHOTS=(value)
    @log_screenshots = value
  end

  module_function

  def platform_module
    Platform.current
  end

  def getPointOnLine(x1, y1, x2, y2, n)
    [((x2 - x1) * n) + x1, ((y2 - y1) * n) + y1]
  end
  alias get_point_on_line getPointOnLine

  def linear(n)
    Tween.linear(n)
  end

  Tween.singleton_methods(false).each do |name|
    next if method_defined?(name) || name == :check

    define_singleton_method(name) { |*args| Tween.public_send(name, *args) }
  end

  def failSafeCheck
    return unless @failsafe

    pos = position
    return unless @failsafe_points.any? { |p| p.x == pos.x && p.y == pos.y }

    raise FailSafeException,
          "AutoGUI fail-safe triggered from mouse moving to a corner of the screen. " \
          "To disable this fail-safe, set AutoGUI.FAILSAFE to false. DISABLING FAIL-SAFE IS NOT RECOMMENDED."
  end
  alias fail_safe_check failSafeCheck

  def sleep(seconds)
    Kernel.sleep(seconds.to_f)
  end

  def countdown(seconds)
    seconds.to_i.downto(1) do |i|
      print "#{i} "
      $stdout.flush
      Kernel.sleep(1)
    end
    puts
  end

  def useImageNotFoundException(value = true)
    @use_image_not_found_exception = value
  end
  alias use_image_not_found_exception! useImageNotFoundException

  def position(x = nil, y = nil)
    posx, posy = platform_module.position
    posx = x.to_i unless x.nil?
    posy = y.to_i unless y.nil?
    Point.new(posx, posy)
  end

  def size
    Size.new(*platform_module.size)
  end
  alias resolution size

  def onScreen(x, y = nil)
    pt = normalize_xy(x, y)
    return false if pt.nil?

    w, h = platform_module.size
    pt.x >= 0 && pt.x < w && pt.y >= 0 && pt.y < h
  end
  alias on_screen onScreen

  def isValidKey(key)
    !platform_module.keyboard_mapping[key].nil? || key.length == 1
  end
  alias valid_key? isValidKey
  alias is_valid_key isValidKey

  def mouseDown(x = nil, y = nil, button: PRIMARY, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      button = normalize_button(button)
      pt = normalize_xy(x, y)
      mouse_move_drag("move", pt.x, pt.y, 0, 0, duration, tween)
      log_screenshot(logScreenshot, "mouseDown", "#{pt.x},#{pt.y}")
      platform_module.mouse_down(pt.x, pt.y, button)
    end
  end
  alias mouse_down mouseDown

  def mouseUp(x = nil, y = nil, button: PRIMARY, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      button = normalize_button(button)
      pt = normalize_xy(x, y)
      mouse_move_drag("move", pt.x, pt.y, 0, 0, duration, tween)
      log_screenshot(logScreenshot, "mouseUp", "#{pt.x},#{pt.y}")
      platform_module.mouse_up(pt.x, pt.y, button)
    end
  end
  alias mouse_up mouseUp

  def click(x = nil, y = nil, clicks: 1, interval: 0.0, button: PRIMARY, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      button = normalize_button(button)
      pt = normalize_xy(x, y)
      mouse_move_drag("move", pt.x, pt.y, 0, 0, duration, tween)
      log_screenshot(logScreenshot, "click", "#{button},#{clicks},#{pt.x},#{pt.y}")
      clicks.to_i.times do
        failSafeCheck
        platform_module.click(pt.x, pt.y, button)
        Kernel.sleep(interval.to_f) if interval.to_f.positive?
      end
    end
  end

  def leftClick(x = nil, y = nil, interval: 0.0, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    click(x, y, clicks: 1, interval: interval, button: LEFT, duration: duration, tween: tween, logScreenshot: logScreenshot, _pause: _pause)
  end
  alias left_click leftClick

  def rightClick(x = nil, y = nil, interval: 0.0, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    click(x, y, clicks: 1, interval: interval, button: RIGHT, duration: duration, tween: tween, logScreenshot: logScreenshot, _pause: _pause)
  end
  alias right_click rightClick

  def middleClick(x = nil, y = nil, interval: 0.0, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    click(x, y, clicks: 1, interval: interval, button: MIDDLE, duration: duration, tween: tween, logScreenshot: logScreenshot, _pause: _pause)
  end
  alias middle_click middleClick

  def doubleClick(x = nil, y = nil, interval: 0.0, button: LEFT, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    click(x, y, clicks: 2, interval: interval, button: button, duration: duration, tween: tween, logScreenshot: logScreenshot, _pause: _pause)
  end
  alias double_click doubleClick

  def tripleClick(x = nil, y = nil, interval: 0.0, button: LEFT, duration: 0.0, tween: nil, logScreenshot: nil, _pause: true)
    click(x, y, clicks: 3, interval: interval, button: button, duration: duration, tween: tween, logScreenshot: logScreenshot, _pause: _pause)
  end
  alias triple_click tripleClick

  def scroll(clicks, x = nil, y = nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      x, y = x.to_a if x.is_a?(Array)
      pt = position(x, y)
      log_screenshot(logScreenshot, "scroll", "#{clicks},#{pt.x},#{pt.y}")
      platform_module.scroll(clicks, pt.x, pt.y)
    end
  end

  def hscroll(clicks, x = nil, y = nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      x, y = x.to_a if x.is_a?(Array)
      pt = position(x, y)
      log_screenshot(logScreenshot, "hscroll", "#{clicks},#{pt.x},#{pt.y}")
      platform_module.hscroll(clicks, pt.x, pt.y)
    end
  end

  def vscroll(clicks, x = nil, y = nil, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      x, y = x.to_a if x.is_a?(Array)
      pt = position(x, y)
      log_screenshot(logScreenshot, "vscroll", "#{clicks},#{pt.x},#{pt.y}")
      platform_module.vscroll(clicks, pt.x, pt.y)
    end
  end

  def moveTo(x = nil, y = nil, duration: 0.0, tween: nil, logScreenshot: false, _pause: true)
    with_checks(_pause) do
      pt = normalize_xy(x, y)
      log_screenshot(logScreenshot, "moveTo", "#{pt.x},#{pt.y}")
      mouse_move_drag("move", pt.x, pt.y, 0, 0, duration, tween)
    end
  end
  alias move_to moveTo

  def moveRel(xOffset = nil, yOffset = nil, duration: 0.0, tween: nil, logScreenshot: false, _pause: true)
    with_checks(_pause) do
      if xOffset.is_a?(Array)
        yOffset = xOffset[1]
        xOffset = xOffset[0]
      end
      xOffset = 0 if xOffset.nil?
      yOffset = 0 if yOffset.nil?
      log_screenshot(logScreenshot, "moveRel", "#{xOffset},#{yOffset}")
      mouse_move_drag("move", nil, nil, xOffset, yOffset, duration, tween)
    end
  end
  alias move_rel moveRel
  alias move moveRel

  def dragTo(x = nil, y = nil, duration: 0.0, tween: nil, button: PRIMARY, logScreenshot: nil, _pause: true, mouseDownUp: true)
    with_checks(_pause) do
      pt = normalize_xy(x, y)
      log_screenshot(logScreenshot, "dragTo", "#{pt.x},#{pt.y}")
      mouseDown(button: button, logScreenshot: false, _pause: false) if mouseDownUp
      mouse_move_drag("drag", pt.x, pt.y, 0, 0, duration, tween, button)
      mouseUp(button: button, logScreenshot: false, _pause: false) if mouseDownUp
    end
  end
  alias drag_to dragTo

  def dragRel(xOffset = 0, yOffset = 0, duration: 0.0, tween: nil, button: PRIMARY, logScreenshot: nil, _pause: true, mouseDownUp: true)
    with_checks(_pause) do
      if xOffset.is_a?(Array)
        yOffset = xOffset[1]
        xOffset = xOffset[0]
      end
      xOffset = 0 if xOffset.nil?
      yOffset = 0 if yOffset.nil?
      return if xOffset.to_i.zero? && yOffset.to_i.zero?

      mousex, mousey = platform_module.position
      log_screenshot(logScreenshot, "dragRel", "#{xOffset},#{yOffset}")
      mouseDown(button: button, logScreenshot: false, _pause: false) if mouseDownUp
      mouse_move_drag("drag", mousex, mousey, xOffset, yOffset, duration, tween, button)
      mouseUp(button: button, logScreenshot: false, _pause: false) if mouseDownUp
    end
  end
  alias drag_rel dragRel
  alias drag dragRel

  def keyDown(key, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      key = key.downcase if key.length > 1
      log_screenshot(logScreenshot, "keyDown", key)
      platform_module.key_down(key)
    end
  end
  alias key_down keyDown

  def keyUp(key, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      key = key.downcase if key.length > 1
      log_screenshot(logScreenshot, "keyUp", key)
      platform_module.key_up(key)
    end
  end
  alias key_up keyUp

  def press(keys, presses: 1, interval: 0.0, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      keys = normalize_keys(keys)
      log_screenshot(logScreenshot, "press", keys.join(","))
      presses.to_i.times do
        keys.each do |k|
          failSafeCheck
          platform_module.key_down(k)
          platform_module.key_up(k)
        end
        Kernel.sleep(interval.to_f) if interval.to_f.positive?
      end
    end
  end

  def hold(keys, logScreenshot: nil, _pause: true)
    raise ArgumentError, "hold requires a block (AutoGUI.hold('shift') { ... })" unless block_given?

    keys = normalize_keys(keys)
    with_checks(_pause) do
      log_screenshot(logScreenshot, "hold", keys.join(","))
      keys.each do |k|
        failSafeCheck
        platform_module.key_down(k)
      end
    end
    begin
      yield
    ensure
      keys.each do |k|
        failSafeCheck
        platform_module.key_up(k)
      end
    end
  end

  def typewrite(message, interval: 0.0, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      log_screenshot(logScreenshot, "write", message.to_s[0, 12])
      chars = message.is_a?(String) ? message.chars : Array(message)
      chars.each do |c|
        c = c.downcase if c.length > 1
        press(c, _pause: false)
        Kernel.sleep(interval.to_f) if interval.to_f.positive?
        failSafeCheck
      end
    end
  end
  alias write typewrite

  def hotkey(*args, interval: 0.0, logScreenshot: nil, _pause: true)
    with_checks(_pause) do
      args = args[0].to_a if args.length == 1 && args[0].is_a?(Array)
      log_screenshot(logScreenshot, "hotkey", args.join(","))
      args.each do |c|
        c = c.downcase if c.length > 1
        platform_module.key_down(c)
        Kernel.sleep(interval.to_f) if interval.to_f.positive?
      end
      args.reverse_each do |c|
        c = c.downcase if c.length > 1
        platform_module.key_up(c)
        Kernel.sleep(interval.to_f) if interval.to_f.positive?
      end
    end
  end
  alias shortcut hotkey

  def screenshot(imageFilename = nil, region: nil)
    img = platform_module.screenshot(region)
    img.save(imageFilename) if imageFilename
    img
  end
  alias grab screenshot

  def locateOnScreen(image, grayscale: false, confidence: nil, region: nil, minSearchTime: 0)
    deadline = Time.now + minSearchTime.to_f
    loop do
      hay = screenshot(region: region)
      box = Screenshot.locate(image, hay, grayscale: grayscale, confidence: confidence)
      if box
        if region
          return Box.new(box.left + region[0], box.top + region[1], box.width, box.height)
        end

        return box
      end
      break if Time.now >= deadline

      Kernel.sleep(0.05)
    end
    raise ImageNotFoundException, "image not found on screen" if @use_image_not_found_exception

    nil
  end
  alias locate_on_screen locateOnScreen

  def locateAllOnScreen(image, grayscale: false, confidence: nil, region: nil)
    hay = screenshot(region: region)
    enum = Screenshot.locate_all(image, hay, grayscale: grayscale, confidence: confidence)
    if region
      enum = enum.lazy.map { |b| Box.new(b.left + region[0], b.top + region[1], b.width, b.height) }
    end
    enum
  end
  alias locate_all_on_screen locateAllOnScreen

  def locateCenterOnScreen(image, grayscale: false, confidence: nil, region: nil, minSearchTime: 0)
    box = locateOnScreen(image, grayscale: grayscale, confidence: confidence, region: region, minSearchTime: minSearchTime)
    box && center(box)
  end
  alias locate_center_on_screen locateCenterOnScreen

  def locate(needleImage, haystackImage, grayscale: false, confidence: nil)
    box = Screenshot.locate(needleImage, haystackImage, grayscale: grayscale, confidence: confidence)
    raise ImageNotFoundException, "image not found" if box.nil? && @use_image_not_found_exception

    box
  end

  def locateAll(needleImage, haystackImage, grayscale: false, confidence: nil)
    Screenshot.locate_all(needleImage, haystackImage, grayscale: grayscale, confidence: confidence)
  end
  alias locate_all locateAll

  def locateOnWindow(image, title, grayscale: false, confidence: nil)
    wins = getWindowsWithTitle(title)
    raise AutoGUIException, "no window with title #{title.inspect}" if wins.empty?

    w = wins.first
    locateOnScreen(image, grayscale: grayscale, confidence: confidence, region: [w.left, w.top, w.width, w.height])
  end
  alias locate_on_window locateOnWindow

  def center(coords)
    Screenshot.center(coords)
  end

  def pixel(x, y)
    platform_module.pixel(x.to_i, y.to_i)
  end

  def pixelMatchesColor(x, y, expectedRGBColor, tolerance: 0)
    Screenshot.pixel_matches_color(x, y, expectedRGBColor, tolerance)
  end
  alias pixel_matches_color pixelMatchesColor

  def alert(text = "", title = "", button = "OK")
    MessageBox.alert(text, title.empty? ? "AutoGUI Alert" : title, button)
  end

  def confirm(text = "", title = "", buttons = %w[OK Cancel])
    MessageBox.confirm(text, title.empty? ? "AutoGUI Confirm" : title, buttons)
  end

  def prompt(text = "", title = "", default = "")
    MessageBox.prompt(text, title.empty? ? "AutoGUI Prompt" : title, default)
  end

  def password(text = "", title = "", default = "", mask = "*")
    MessageBox.password(text, title.empty? ? "AutoGUI Password" : title, default, mask)
  end

  def mouseInfo
    displayMousePosition
  end
  alias mouse_info mouseInfo

  def displayMousePosition(xOffset = 0, yOffset = 0)
    puts "Press Ctrl-C to quit."
    puts "xOffset: #{xOffset} yOffset: #{yOffset}" unless xOffset.zero? && yOffset.zero?
    loop do
      x, y = position
      rx = x - xOffset
      ry = y - yOffset
      rgb =
        begin
          onScreen(rx, ry) ? pixel(x, y) : %w[NaN NaN NaN]
        rescue StandardError
          %w[NaN NaN NaN]
        end
      line = format("X: %4d Y: %4d RGB: (%3s, %3s, %3s)", rx, ry, rgb[0], rgb[1], rgb[2])
      print line
      print "\b" * line.length
      $stdout.flush
      Kernel.sleep(0.05)
    end
  rescue Interrupt
    puts
  end
  alias display_mouse_position displayMousePosition

  def run(commandStr, _ssCount = nil)
    Run.run(commandStr, _ssCount)
  end

  def printInfo(dontPrint = false)
    plat, ruby_ver, ver, exe, res, ts = getInfo
    msg = <<~MSG
             Platform: #{plat}
          Ruby Version: #{ruby_ver}
      AutoGUI Version: #{ver}
            Executable: #{exe}
            Resolution: #{res}
             Timestamp: #{ts}
    MSG
    puts msg unless dontPrint
    msg
  end
  alias print_info printInfo

  def getInfo
    [RbConfig::CONFIG["host_os"], RUBY_DESCRIPTION, VERSION, RbConfig.ruby, size, Time.now]
  end
  alias get_info getInfo

  %i[getAllWindows getAllTitles getWindowsWithTitle getWindowsAt getActiveWindow getActiveWindowTitle
     get_all_windows get_all_titles get_windows_with_title get_windows_at get_active_window get_active_window_title].each do |name|
    define_singleton_method(name) { |*args, **kwargs| WindowFunctions.public_send(name, *args, **kwargs) }
  end

  def with_checks(_pause)
    failSafeCheck
    result = yield
    Kernel.sleep(@pause.to_f) if _pause && @pause.to_f.positive?
    result
  end

  def normalize_button(button)
    button = button.to_s.downcase
    linux = Platform.linux?
    valid = linux ? %w[left middle right primary secondary 1 2 3 4 5 6 7] : %w[left middle right primary secondary 1 2 3]
    unless valid.include?(button)
      raise AutoGUIException, "button argument must be one of #{valid.inspect}"
    end

    if %w[primary secondary].include?(button)
      swapped = platform_module.mouse_is_swapped?
      if button == "primary"
        return swapped ? RIGHT : LEFT
      end

      return swapped ? LEFT : RIGHT
    end

    { "left" => LEFT, "middle" => MIDDLE, "right" => RIGHT, "1" => LEFT, "2" => MIDDLE, "3" => RIGHT,
      "4" => "4", "5" => "5", "6" => "6", "7" => "7" }[button]
  end

  def normalize_xy(first, second)
    if first.nil? && second.nil?
      return position
    elsif first.nil? && !second.nil?
      return Point.new(position.x, second)
    elsif second.nil? && !first.nil? && !first.is_a?(Array) && !first.is_a?(String) && !first.is_a?(Point) && !first.is_a?(Box)
      return Point.new(first, position.y)
    elsif first.is_a?(String)
      loc = locateOnScreen(first)
      return loc && center(loc)
    elsif first.is_a?(Point)
      return first
    elsif first.is_a?(Box)
      return center(first)
    elsif first.is_a?(Array) || first.is_a?(Size)
      arr = first.to_a
      if arr.length == 2 && second.nil?
        return Point.new(arr[0], arr[1])
      elsif arr.length == 4 && second.nil?
        return center(arr)
      elsif !second.nil?
        raise AutoGUIException, "When passing a sequence for firstArg, secondArg must not be passed (received #{second.inspect})."
      else
        raise AutoGUIException, "The supplied sequence must have exactly 2 or exactly 4 elements (#{arr.length} were received)."
      end
    else
      Point.new(first, second)
    end
  end

  def normalize_keys(keys)
    if keys.is_a?(String)
      keys = keys.downcase if keys.length > 1
      [keys]
    else
      Array(keys).map { |s| s.length > 1 ? s.downcase : s }
    end
  end

  def mouse_move_drag(move_or_drag, x, y, x_offset, y_offset, duration, tween = nil, _button = nil)
    tween ||= method(:linear)
    x_offset = x_offset.nil? ? 0 : x_offset.to_i
    y_offset = y_offset.nil? ? 0 : y_offset.to_i
    return if x.nil? && y.nil? && x_offset.zero? && y_offset.zero?

    startx, starty = position
    x = x.nil? ? startx : x.to_i
    y = y.nil? ? starty : y.to_i
    x += x_offset
    y += y_offset

    steps = [[x, y]]
    sleep_amount = 0
    if duration.to_f > @minimum_duration
      width, height = size
      num_steps = [width, height].max
      sleep_amount = duration.to_f / num_steps
      if sleep_amount < @minimum_sleep
        num_steps = (duration.to_f / @minimum_sleep).to_i
        num_steps = 1 if num_steps < 1
        sleep_amount = duration.to_f / num_steps
      end
      steps = (0...num_steps).map do |n|
        getPointOnLine(startx, starty, x, y, tween.call(n.to_f / num_steps))
      end
      steps << [x, y]
    end

    tween_x = x
    tween_y = y
    steps.each do |sx, sy|
      Kernel.sleep(sleep_amount) if steps.length > 1
      tween_x = sx.round
      tween_y = sy.round
      failSafeCheck unless @failsafe_points.any? { |p| p.x == tween_x && p.y == tween_y }
      platform_module.move_to(tween_x, tween_y)
    end
    failSafeCheck unless @failsafe_points.any? { |p| p.x == tween_x && p.y == tween_y }
  end

  def log_screenshot(log, func_name, func_args, folder = ".")
    return if log == false
    return if log.nil? && !@log_screenshots

    func_args = "#{func_args[0, 12]}..." if func_args.length > 12
    now = Time.now
    filename = format(
      "%04d-%02d-%02d_%02d-%02d-%02d-%03d_%s_%s.png",
      now.year, now.month, now.day, now.hour, now.min, now.sec,
      (now.usec / 1000), func_name, func_args.gsub(/[^\w,.-]/, "_")
    )
    if @log_screenshots_limit && @log_screenshot_filenames.length >= @log_screenshots_limit
      old = File.join(folder, @log_screenshot_filenames.shift)
      File.unlink(old) if File.exist?(old)
    end
    screenshot(File.join(folder, filename))
    @log_screenshot_filenames << filename
  end

  # module_function copies methods to the singleton class but does not copy
  # subsequent `alias` names. Re-alias them on the singleton class.
  class << self
    {
      get_point_on_line: :getPointOnLine,
      fail_safe_check: :failSafeCheck,
      use_image_not_found_exception!: :useImageNotFoundException,
      on_screen: :onScreen,
      valid_key?: :isValidKey,
      is_valid_key: :isValidKey,
      mouse_down: :mouseDown,
      mouse_up: :mouseUp,
      left_click: :leftClick,
      right_click: :rightClick,
      middle_click: :middleClick,
      double_click: :doubleClick,
      triple_click: :tripleClick,
      move_to: :moveTo,
      move_rel: :moveRel,
      move: :moveRel,
      drag_to: :dragTo,
      drag_rel: :dragRel,
      drag: :dragRel,
      key_down: :keyDown,
      key_up: :keyUp,
      write: :typewrite,
      shortcut: :hotkey,
      grab: :screenshot,
      locate_on_screen: :locateOnScreen,
      locate_all_on_screen: :locateAllOnScreen,
      locate_center_on_screen: :locateCenterOnScreen,
      locate_all: :locateAll,
      locate_on_window: :locateOnWindow,
      pixel_matches_color: :pixelMatchesColor,
      mouse_info: :mouseInfo,
      display_mouse_position: :displayMousePosition,
      print_info: :printInfo,
      get_info: :getInfo
    }.each do |snake, camel|
      alias_method snake, camel if method_defined?(camel) || private_method_defined?(camel)
    end
  end
end

begin
  _right, _bottom = AutoGUI.size
  AutoGUI.failsafe_points.concat(
    [AutoGUI::Point.new(0, _bottom - 1), AutoGUI::Point.new(_right - 1, 0), AutoGUI::Point.new(_right - 1, _bottom - 1)]
  )
rescue StandardError
  nil
end
