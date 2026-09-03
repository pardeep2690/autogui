# frozen_string_literal: true

require "zlib"
require "stringio"

module AutoGUI
  # Packed RGB bitmap used by screenshot and locate* functions.
  # +data+ is a binary string of 3-byte RGB pixels, row-major, top-down.
  class Image
    attr_reader :width, :height, :data

    def initialize(width, height, data = nil)
      @width = width.to_i
      @height = height.to_i
      expected = @width * @height * 3
      @data =
        if data.nil?
          "\x00".b * expected
        else
          d = data.dup.force_encoding(Encoding::BINARY)
          raise AutoGUIException, "image data size mismatch" unless d.bytesize == expected

          d
        end
    end

    def size
      [@width, @height]
    end

    def [](x, y = nil)
      if y.nil? && x.is_a?(Array)
        y = x[1]
        x = x[0]
      end
      getpixel(x, y)
    end

    def getpixel(x, y)
      x = x.to_i
      y = y.to_i
      raise ArgumentError, "pixel out of bounds" unless x.between?(0, @width - 1) && y.between?(0, @height - 1)

      i = (y * @width + x) * 3
      [@data.getbyte(i), @data.getbyte(i + 1), @data.getbyte(i + 2)]
    end

    def putpixel(x, y, rgb)
      x = x.to_i
      y = y.to_i
      raise ArgumentError, "pixel out of bounds" unless x.between?(0, @width - 1) && y.between?(0, @height - 1)

      i = (y * @width + x) * 3
      @data.setbyte(i, rgb[0].to_i)
      @data.setbyte(i + 1, rgb[1].to_i)
      @data.setbyte(i + 2, rgb[2].to_i)
    end

    def grayscale
      out = String.new(capacity: @width * @height * 3, encoding: Encoding::BINARY)
      i = 0
      while i < @data.bytesize
        r = @data.getbyte(i)
        g = @data.getbyte(i + 1)
        b = @data.getbyte(i + 2)
        y = ((r * 299) + (g * 587) + (b * 114)) / 1000
        out << y.chr << y.chr << y.chr
        i += 3
      end
      Image.new(@width, @height, out)
    end

    def crop(left, top, width, height)
      left = left.to_i
      top = top.to_i
      width = width.to_i
      height = height.to_i
      raise ArgumentError, "invalid crop" if width <= 0 || height <= 0
      raise ArgumentError, "crop out of bounds" unless left >= 0 && top >= 0 && left + width <= @width && top + height <= @height

      out = String.new(capacity: width * height * 3, encoding: Encoding::BINARY)
      height.times do |row|
        src = ((top + row) * @width + left) * 3
        out << @data.byteslice(src, width * 3)
      end
      Image.new(width, height, out)
    end

    def save(path)
      path = path.to_s
      ext = File.extname(path).downcase
      File.binwrite(path, ext == ".bmp" ? to_bmp : to_png)
      self
    end

    def to_png
      raw = String.new(capacity: @height * (1 + @width * 3), encoding: Encoding::BINARY)
      @height.times do |y|
        raw << "\x00"
        raw << @data.byteslice(y * @width * 3, @width * 3)
      end
      compressed = Zlib::Deflate.deflate(raw, Zlib::BEST_SPEED)
      png = "\x89PNG\r\n\x1a\n".b
      png << png_chunk("IHDR", [@width, @height, 8, 2, 0, 0, 0].pack("NNC5"))
      png << png_chunk("IDAT", compressed)
      png << png_chunk("IEND", "".b)
      png
    end

    def to_bmp
      row_stride = ((@width * 3 + 3) / 4) * 4
      pixel_size = row_stride * @height
      file_size = 54 + pixel_size
      file_header = ["BM", file_size, 0, 0, 54].pack("a2VvvV")
      info_header = [40, @width, @height, 1, 24, 0, pixel_size, 0, 0, 0, 0].pack("VllvvVVllVV")
      pixels = String.new(capacity: pixel_size, encoding: Encoding::BINARY)
      pad = "\x00".b * (row_stride - @width * 3)
      (@height - 1).downto(0) do |y|
        row = @data.byteslice(y * @width * 3, @width * 3).dup
        i = 0
        while i < row.bytesize
          r = row.getbyte(i)
          b = row.getbyte(i + 2)
          row.setbyte(i, b)
          row.setbyte(i + 2, r)
          i += 3
        end
        pixels << row << pad
      end
      file_header + info_header + pixels
    end

    def self.open(path_or_image)
      return path_or_image if path_or_image.is_a?(Image)

      path = path_or_image.to_s
      bytes = File.binread(path)
      if bytes.start_with?("\x89PNG".b)
        from_png(bytes)
      elsif bytes.start_with?("BM")
        from_bmp(bytes)
      else
        raise AutoGUIException, "unsupported image format: #{path} (use PNG or BMP)"
      end
    end

    def self.from_png(bytes)
      raise AutoGUIException, "invalid PNG signature" unless bytes.start_with?("\x89PNG\r\n\x1a\n".b)

      offset = 8
      width = height = nil
      bit_depth = color_type = nil
      idat = String.new(encoding: Encoding::BINARY)
      palette = nil
      until offset >= bytes.bytesize
        length = bytes.byteslice(offset, 4).unpack1("N")
        type = bytes.byteslice(offset + 4, 4)
        data = bytes.byteslice(offset + 8, length)
        offset += 12 + length
        case type
        when "IHDR"
          width, height, bit_depth, color_type = data.unpack("NNC2")
        when "PLTE"
          palette = data
        when "IDAT"
          idat << data
        when "IEND"
          break
        end
      end
      raise AutoGUIException, "PNG missing IHDR" if width.nil?
      raise AutoGUIException, "only 8-bit PNG is supported" unless bit_depth == 8

      inflated = Zlib::Inflate.inflate(idat)
      channels =
        case color_type
        when 0 then 1
        when 2 then 3
        when 3 then 1
        when 4 then 2
        when 6 then 4
        else
          raise AutoGUIException, "unsupported PNG color type #{color_type}"
        end
      rgb = unfilter_png(inflated, width, height, channels, color_type, palette)
      new(width, height, rgb)
    end

    def self.from_bmp(bytes)
      _magic, _file_size, _res1, _res2, offset = bytes.unpack("a2VvvV")
      header_size, width, height, _planes, bits, compression =
        bytes.byteslice(14, 24).unpack("VllvvV")
      raise AutoGUIException, "compressed BMP is not supported" unless compression.to_i.zero?
      raise AutoGUIException, "unsupported BMP bit depth" unless [24, 32].include?(bits)

      top_down = height.negative?
      height = height.abs
      bytes_pp = bits / 8
      row_stride = ((width * bytes_pp + 3) / 4) * 4
      rgb = String.new(capacity: width * height * 3, encoding: Encoding::BINARY)
      height.times do |row|
        src_row = top_down ? row : (height - 1 - row)
        src = offset + src_row * row_stride
        width.times do |x|
          i = src + x * bytes_pp
          b = bytes.getbyte(i)
          g = bytes.getbyte(i + 1)
          r = bytes.getbyte(i + 2)
          rgb << r.chr << g.chr << b.chr
        end
      end
      new(width, height, rgb)
    end

    def self.from_bgra(width, height, bgra, stride = nil)
      stride ||= width * 4
      rgb = String.new(capacity: width * height * 3, encoding: Encoding::BINARY)
      height.times do |y|
        row = y * stride
        width.times do |x|
          i = row + x * 4
          rgb << bgra.getbyte(i + 2).chr << bgra.getbyte(i + 1).chr << bgra.getbyte(i).chr
        end
      end
      new(width, height, rgb)
    end

    def self.from_pixels(width, height, pixels)
      data = String.new(capacity: width * height * 3, encoding: Encoding::BINARY)
      pixels.each do |r, g, b|
        data << r.chr << g.chr << b.chr
      end
      new(width, height, data)
    end

    class << self
      private

      def png_chunk_crc(type, data)
        Zlib.crc32(type + data)
      end

      def unfilter_png(inflated, width, height, channels, color_type, palette)
        bpp = channels
        stride = width * bpp
        prev = "\x00".b * stride
        rgb = String.new(capacity: width * height * 3, encoding: Encoding::BINARY)
        pos = 0
        height.times do
          filter = inflated.getbyte(pos)
          pos += 1
          raw = inflated.byteslice(pos, stride).dup
          pos += stride
          recon = apply_filter(filter, raw, prev, bpp)
          prev = recon
          case color_type
          when 2
            rgb << recon
          when 0
            recon.bytesize.times { |i| rgb << recon[i] << recon[i] << recon[i] }
          when 4
            (width).times do |x|
              g = recon.getbyte(x * 2)
              a = recon.getbyte(x * 2 + 1)
              v = composite_white(g, a)
              rgb << v.chr << v.chr << v.chr
            end
          when 6
            width.times do |x|
              i = x * 4
              a = recon.getbyte(i + 3)
              rgb << composite_white(recon.getbyte(i), a).chr
              rgb << composite_white(recon.getbyte(i + 1), a).chr
              rgb << composite_white(recon.getbyte(i + 2), a).chr
            end
          when 3
            raise AutoGUIException, "PNG palette missing" if palette.nil?

            width.times do |x|
              idx = recon.getbyte(x) * 3
              rgb << palette.getbyte(idx).chr << palette.getbyte(idx + 1).chr << palette.getbyte(idx + 2).chr
            end
          end
        end
        rgb
      end

      def apply_filter(filter, raw, prev, bpp)
        recon = raw.dup
        case filter
        when 0
          recon
        when 1
          recon.bytesize.times do |i|
            left = i >= bpp ? recon.getbyte(i - bpp) : 0
            recon.setbyte(i, (raw.getbyte(i) + left) & 255)
          end
          recon
        when 2
          recon.bytesize.times do |i|
            recon.setbyte(i, (raw.getbyte(i) + prev.getbyte(i)) & 255)
          end
          recon
        when 3
          recon.bytesize.times do |i|
            left = i >= bpp ? recon.getbyte(i - bpp) : 0
            up = prev.getbyte(i)
            recon.setbyte(i, (raw.getbyte(i) + ((left + up) / 2)) & 255)
          end
          recon
        when 4
          recon.bytesize.times do |i|
            a = i >= bpp ? recon.getbyte(i - bpp) : 0
            b = prev.getbyte(i)
            c = i >= bpp ? prev.getbyte(i - bpp) : 0
            recon.setbyte(i, (raw.getbyte(i) + paeth(a, b, c)) & 255)
          end
          recon
        else
          raise AutoGUIException, "unsupported PNG filter #{filter}"
        end
      end

      def paeth(a, b, c)
        p = a + b - c
        pa = (p - a).abs
        pb = (p - b).abs
        pc = (p - c).abs
        return a if pa <= pb && pa <= pc
        return b if pb <= pc

        c
      end

      def composite_white(value, alpha)
        ((value * alpha) + (255 * (255 - alpha))) / 255
      end
    end

    def png_chunk(type, data)
      [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
    end
  end
end
