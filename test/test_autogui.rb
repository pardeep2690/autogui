# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "tmpdir"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "autogui"

class GeometryTest < Minitest::Test
  def test_point_deconstructs
    p = AutoGUI::Point.new(10, 20)
    x, y = p
    assert_equal 10, x
    assert_equal 20, y
    assert_equal [10, 20], p.to_a
    assert_equal 10, p[0]
    assert_equal p, [10, 20]
  end

  def test_size_and_box
    s = AutoGUI::Size.new(1920, 1080)
    assert_equal 1920, s.width
    b = AutoGUI::Box.new(1, 2, 3, 4)
    assert_equal [1, 2, 3, 4], b.to_a
    assert_equal "Box(left=1, top=2, width=3, height=4)", b.to_s
  end
end

class TweenTest < Minitest::Test
  def test_linear
    assert_equal 0.0, AutoGUI.linear(0)
    assert_equal 0.5, AutoGUI.linear(0.5)
    assert_equal 1.0, AutoGUI.linear(1)
    assert_raises(AutoGUI::AutoGUIException) { AutoGUI.linear(1.1) }
  end

  def test_quad_endpoints
    %i[easeInQuad easeOutQuad easeInOutQuad easeInCubic easeOutBounce].each do |name|
      assert_in_delta 0.0, AutoGUI.public_send(name, 0), 1e-9, name.to_s
      assert_in_delta 1.0, AutoGUI.public_send(name, 1), 1e-9, name.to_s
    end
  end

  def test_point_on_line
    x, y = AutoGUI.getPointOnLine(0, 0, 10, 20, 0.5)
    assert_equal 5.0, x
    assert_equal 10.0, y
  end
end

class KeysTest < Minitest::Test
  def test_shift_character
    assert AutoGUI.shift_character?("A")
    assert AutoGUI.shift_character?("!")
    refute AutoGUI.shift_character?("a")
    refute AutoGUI.shift_character?("1")
    assert AutoGUI.isShiftCharacter("?")
  end

  def test_key_names_include_common_keys
    %w[enter esc tab shift ctrl alt f1 left space].each do |k|
      assert_includes AutoGUI::KEYBOARD_KEYS, k
    end
  end
end

class ImageTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def sample
    # 2x2: red, green / blue, white
    AutoGUI::Image.from_pixels(2, 2, [
      [255, 0, 0], [0, 255, 0],
      [0, 0, 255], [255, 255, 255]
    ])
  end

  def test_getpixel
    img = sample
    assert_equal [255, 0, 0], img.getpixel(0, 0)
    assert_equal [0, 255, 0], img.getpixel(1, 0)
    assert_equal [0, 0, 255], img.getpixel(0, 1)
    assert_equal [255, 255, 255], img.getpixel(1, 1)
  end

  def test_png_roundtrip
    path = File.join(@dir, "t.png")
    sample.save(path)
    loaded = AutoGUI::Image.open(path)
    assert_equal 2, loaded.width
    assert_equal 2, loaded.height
    assert_equal [255, 0, 0], loaded.getpixel(0, 0)
    assert_equal [0, 255, 0], loaded.getpixel(1, 0)
    assert_equal [0, 0, 255], loaded.getpixel(0, 1)
    assert_equal [255, 255, 255], loaded.getpixel(1, 1)
  end

  def test_bmp_roundtrip
    path = File.join(@dir, "t.bmp")
    sample.save(path)
    loaded = AutoGUI::Image.open(path)
    assert_equal [255, 0, 0], loaded.getpixel(0, 0)
    assert_equal [255, 255, 255], loaded.getpixel(1, 1)
  end

  def test_crop_and_grayscale
    cropped = sample.crop(1, 0, 1, 1)
    assert_equal [0, 255, 0], cropped.getpixel(0, 0)
    gray = sample.grayscale
    r, g, b = gray.getpixel(0, 0)
    assert_equal r, g
    assert_equal g, b
  end
end

class LocateTest < Minitest::Test
  def haystack
    pixels = Array.new(10 * 10) { [0, 0, 0] }
    # red 2x2 at (3,4)
    [[3, 4], [4, 4], [3, 5], [4, 5]].each do |x, y|
      pixels[y * 10 + x] = [255, 0, 0]
    end
    AutoGUI::Image.from_pixels(10, 10, pixels)
  end

  def needle
    AutoGUI::Image.from_pixels(2, 2, [[255, 0, 0], [255, 0, 0], [255, 0, 0], [255, 0, 0]])
  end

  def test_locate_exact
    box = AutoGUI.locate(needle, haystack)
    assert_equal [3, 4, 2, 2], box.to_a
  end

  def test_locate_all
    boxes = AutoGUI.locateAll(needle, haystack).to_a
    assert_equal 1, boxes.length
  end

  def test_center
    p = AutoGUI.center([10, 20, 4, 6])
    assert_equal 12, p.x
    assert_equal 23, p.y
  end

  def test_confidence
    noisy = AutoGUI::Image.from_pixels(2, 2, [[250, 5, 5], [255, 0, 0], [255, 0, 0], [254, 1, 0]])
    box = AutoGUI.locate(noisy, haystack, confidence: 0.9)
    assert_equal [3, 4, 2, 2], box.to_a
  end

  def test_missing_returns_nil
    blue = AutoGUI::Image.from_pixels(2, 2, [[0, 0, 255]] * 4)
    assert_nil AutoGUI.locate(blue, haystack)
  end

  def test_missing_raises_when_configured
    old = AutoGUI.use_image_not_found_exception
    AutoGUI.useImageNotFoundException(true)
    blue = AutoGUI::Image.from_pixels(2, 2, [[0, 0, 255]] * 4)
    assert_raises(AutoGUI::ImageNotFoundException) { AutoGUI.locate(blue, haystack) }
  ensure
    AutoGUI.use_image_not_found_exception = old
  end
end

class RunTokenizerTest < Minitest::Test
  def test_simple_clicks
    assert_equal %w[c c], AutoGUI::Run.tokenize("cc")
    assert_equal %w[c c], AutoGUI::Run.tokenize("c c")
  end

  def test_goto_and_relative
    tokens = AutoGUI::Run.tokenize("g 100, 200")
    assert_equal ["g", "100", "200"], tokens
    tokens = AutoGUI::Run.tokenize("g-20,+0")
    assert_equal ["g", "-20", "+0"], tokens
  end

  def test_write_hotkey_loop
    tokens = AutoGUI::Run.tokenize("w'hi' k'enter' h'ctrl,c' f2(cc)")
    assert_equal "w", tokens[0]
    assert_equal "hi", tokens[1]
    assert_equal "k", tokens[2]
    assert_equal "enter", tokens[3]
    assert_equal "h", tokens[4]
    assert_equal "ctrl,c", tokens[5]
    assert_equal "f", tokens[6]
    assert_equal "2", tokens[7]
    assert_equal %w[c c], tokens[8]
  end

  def test_invalid
    assert_raises(AutoGUI::AutoGUIException) { AutoGUI::Run.tokenize("z") }
  end
end

class ApiSmokeTest < Minitest::Test
  def test_size_and_position
    w, h = AutoGUI.size
    assert w.positive?
    assert h.positive?
    p = AutoGUI.position
    assert_kind_of Integer, p.x
    assert_kind_of Integer, p.y
  end

  def test_on_screen
    w, h = AutoGUI.size
    assert AutoGUI.onScreen(0, 0)
    refute AutoGUI.onScreen(-1, 0)
    refute AutoGUI.onScreen(w, h)
    assert AutoGUI.onScreen(w - 1, h - 1)
  end

  def test_failsafe_points_cover_corners
    w, h = AutoGUI.size
    pts = AutoGUI.FAILSAFE_POINTS.map { |p| [p.x, p.y] }
    assert_includes pts, [0, 0]
    assert_includes pts, [w - 1, 0]
    assert_includes pts, [0, h - 1]
    assert_includes pts, [w - 1, h - 1]
  end

  def test_aliases
    assert AutoGUI.respond_to?(:move_to)
    assert AutoGUI.respond_to?(:write)
    assert AutoGUI.respond_to?(:resolution)
    assert_equal AutoGUI.size, AutoGUI.resolution
  end

  def test_documented_public_methods_exist
    %i[
      size resolution position on_screen onScreen pixel pixel_matches_color pixelMatchesColor
      print_info printInfo get_info getInfo sleep countdown fail_safe_check failSafeCheck
      move_to moveTo move move_rel moveRel drag_to dragTo drag drag_rel dragRel
      click left_click leftClick right_click rightClick middle_click middleClick
      double_click doubleClick triple_click tripleClick mouse_down mouseDown mouse_up mouseUp
      scroll hscroll vscroll
      display_mouse_position displayMousePosition mouse_info mouseInfo
      write typewrite press hotkey shortcut hold key_down keyDown key_up keyUp
      valid_key? isValidKey is_valid_key shift_character? isShiftCharacter
      screenshot grab locate_on_screen locateOnScreen locate_center_on_screen locateCenterOnScreen
      locate_all_on_screen locateAllOnScreen locate locate_all locateAll locate_on_window locateOnWindow
      center use_image_not_found_exception! useImageNotFoundException
      alert confirm prompt password
      get_all_windows getAllWindows get_all_titles getAllTitles
      get_active_window getActiveWindow get_active_window_title getActiveWindowTitle
      get_windows_with_title getWindowsWithTitle get_windows_at getWindowsAt
      linear get_point_on_line getPointOnLine run platform_module
    ].each do |name|
      assert AutoGUI.respond_to?(name), "AutoGUI.#{name}"
    end
  end

  def test_module_function_aliases_are_promoted
    [AutoGUI, AutoGUI::WindowFunctions, AutoGUI.platform_module].each do |mod|
      missing = (mod.private_instance_methods(false) + mod.instance_methods(false)).uniq.reject do |name|
        mod.singleton_class.method_defined?(name) || mod.singleton_class.private_method_defined?(name)
      end
      assert_empty missing, "#{mod} missing module functions: #{missing.inspect}"
    end
    assert AutoGUI.platform_module.respond_to?(:vscroll)
    assert AutoGUI.platform_module.respond_to?(:scroll)
  end

  def test_normalize_xy_tuple_and_none
    p = AutoGUI.position
    same = AutoGUI.send(:normalize_xy, nil, nil)
    assert_equal p.x, same.x
    pt = AutoGUI.send(:normalize_xy, [11, 22], nil)
    assert_equal 11, pt.x
    assert_equal 22, pt.y
  end

  def test_normalize_button
    assert_equal "left", AutoGUI.send(:normalize_button, "primary") unless AutoGUI.platform_module.mouse_is_swapped?
    assert_equal "right", AutoGUI.send(:normalize_button, "right")
    assert_equal "left", AutoGUI.send(:normalize_button, 1)
  end

  def test_screenshot_and_pixel
    img = AutoGUI.screenshot
    assert img.width.positive?
    assert img.height.positive?
    p = AutoGUI.position
    rgb = AutoGUI.pixel(p.x.clamp(0, img.width - 1), p.y.clamp(0, img.height - 1))
    assert_equal 3, rgb.length
    rgb.each { |c| assert c.between?(0, 255) }
  end

  def test_screenshot_region_and_save
    Dir.mktmpdir do |dir|
      path = File.join(dir, "r.png")
      img = AutoGUI.screenshot(path, region: [0, 0, 16, 16])
      assert_equal 16, img.width
      assert_equal 16, img.height
      assert File.size?(path)
    end
  end

  def test_get_info
    info = AutoGUI.getInfo
    assert_equal 6, info.length
    assert_equal AutoGUI::VERSION, info[2]
  end

  def test_failsafe_raises_at_listed_point
    old = AutoGUI.FAILSAFE
    pos = AutoGUI.position
    AutoGUI.FAILSAFE = true
    AutoGUI.FAILSAFE_POINTS << pos
    assert_raises(AutoGUI::FailSafeException) { AutoGUI.failSafeCheck }
  ensure
    AutoGUI.FAILSAFE_POINTS.delete(pos) if pos
    AutoGUI.FAILSAFE = old
  end

  def test_hold_requires_block
    assert_raises(ArgumentError) { AutoGUI.hold("shift") }
  end

  def test_window_snake_case_aliases_exist
    %i[
      get_all_windows get_all_titles get_windows_with_title
      get_windows_at get_active_window get_active_window_title
    ].each do |name|
      assert AutoGUI.respond_to?(name), "AutoGUI.#{name}"
      assert AutoGUI::WindowFunctions.respond_to?(name), "WindowFunctions.#{name}"
    end
  end

  def test_windows_enumeration
    skip "window APIs are Windows-only" unless RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/i
    titles = AutoGUI.get_all_titles
    assert_kind_of Array, titles
    titles.each { |t| assert_kind_of String, t }
    windows = AutoGUI.get_all_windows
    assert_equal titles.length, windows.length
    active = AutoGUI.get_active_window
    assert active.nil? || active.title.is_a?(String)
    assert_equal active&.title, AutoGUI.get_active_window_title
    notepad = AutoGUI.get_windows_with_title("Notepad")
    assert_kind_of Array, notepad
    at_point = AutoGUI.get_windows_at(400, 300)
    assert_kind_of Array, at_point
    at_point.each { |w| assert_kind_of AutoGUI::Window, w }
  end
end

class WindowsWideTest < Minitest::Test
  def setup
    skip "wide() is Windows-only" unless RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/i
    AutoGUI::Platform.current
  end

  def test_wide_null_terminates_ascii
    wide = AutoGUI::Platform::Windows.wide("Done.")
    assert_equal Encoding::ASCII_8BIT, wide.encoding
    assert_equal "Done.\0".encode("UTF-16LE").b, wide
  end

  def test_wide_handles_non_ascii
    wide = AutoGUI::Platform::Windows.wide("café")
    decoded = wide.dup.force_encoding("UTF-16LE").encode("UTF-8").delete("\x00")
    assert_equal "café", decoded
  end
end

class LiveInputTest < Minitest::Test
  def setup
    skip "set AUTOGUI_LIVE=1 to run live mouse/keyboard tests" unless ENV["AUTOGUI_LIVE"] == "1"
    @old_pause = AutoGUI.PAUSE
    @old_failsafe = AutoGUI.FAILSAFE
    AutoGUI.PAUSE = 0.05
    AutoGUI.FAILSAFE = false
  end

  def teardown
    return unless defined?(@old_pause)

    AutoGUI.PAUSE = @old_pause
    AutoGUI.FAILSAFE = @old_failsafe
  end

  def test_move_and_restore
    origin = AutoGUI.position
    AutoGUI.moveTo(origin.x + 40, origin.y + 20, duration: 0.2)
    now = AutoGUI.position
    assert_in_delta origin.x + 40, now.x, 2
    assert_in_delta origin.y + 20, now.y, 2
    AutoGUI.moveTo(origin.x, origin.y, duration: 0.2)
  end
end
