# frozen_string_literal: true

module AutoGUI
  module Screenshot
    module_function

    def load_image(image)
      Image.open(image)
    end

    def center(box)
      left, top, width, height =
        if box.respond_to?(:left)
          [box.left, box.top, box.width, box.height]
        else
          box.to_a
        end
      Point.new(left + width / 2, top + height / 2)
    end

    def pixel_matches_color(x, y, expected_rgb, tolerance = 0)
      r, g, b = AutoGUI.pixel(x, y)
      er, eg, eb = expected_rgb.to_a
      (r - er).abs <= tolerance && (g - eg).abs <= tolerance && (b - eb).abs <= tolerance
    end

    def locate(needle, haystack, grayscale: false, confidence: nil)
      locate_all(needle, haystack, grayscale: grayscale, confidence: confidence, limit: 1).first
    end

    def locate_all(needle, haystack, grayscale: false, confidence: nil, limit: nil)
      return enum_for(:locate_all, needle, haystack, grayscale: grayscale, confidence: confidence, limit: limit) unless block_given?

      needle = load_image(needle)
      haystack = load_image(haystack)
      if grayscale
        needle = needle.grayscale
        haystack = haystack.grayscale
      end

      nw = needle.width
      nh = needle.height
      hw = haystack.width
      hh = haystack.height
      raise AutoGUIException, "needle is larger than haystack" if nw > hw || nh > hh

      found = 0
      max_x = hw - nw
      max_y = hh - nh
      nd = needle.data
      hd = haystack.data
      nsize = nw * nh * 3

      (0..max_y).each do |y|
        (0..max_x).each do |x|
          matched =
            if confidence.nil?
              exact_match?(hd, hw, nd, nw, nh, x, y)
            else
              score = match_score(hd, hw, nd, nw, nh, x, y, nsize)
              score >= confidence
            end
          next unless matched

          yield Box.new(x, y, nw, nh)
          found += 1
          return if limit && found >= limit
        end
      end
    end

    def exact_match?(hay, hw, needle, nw, nh, x, y)
      row_bytes = nw * 3
      nh.times do |row|
        hay_off = ((y + row) * hw + x) * 3
        needle_off = row * row_bytes
        return false unless hay.byteslice(hay_off, row_bytes) == needle.byteslice(needle_off, row_bytes)
      end
      true
    end

    def match_score(hay, hw, needle, nw, nh, x, y, nsize)
      diff = 0
      ni = 0
      nh.times do |row|
        hay_off = ((y + row) * hw + x) * 3
        (nw * 3).times do |c|
          diff += (hay.getbyte(hay_off + c) - needle.getbyte(ni)).abs
          ni += 1
        end
      end
      1.0 - (diff.to_f / (nsize * 255.0))
    end
  end
end
