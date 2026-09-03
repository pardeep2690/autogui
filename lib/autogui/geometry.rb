# frozen_string_literal: true

module AutoGUI
  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x.to_i
      @y = y.to_i
    end

    def to_a
      [@x, @y]
    end
    alias to_ary to_a

    def [](index)
      to_a[index]
    end

    def ==(other)
      case other
      when Point then @x == other.x && @y == other.y
      when Array then to_a == other.to_a
      else false
      end
    end

    def to_s
      "Point(x=#{@x}, y=#{@y})"
    end
    alias inspect to_s
  end

  class Size
    attr_reader :width, :height

    def initialize(width, height)
      @width = width.to_i
      @height = height.to_i
    end

    def to_a
      [@width, @height]
    end
    alias to_ary to_a

    def [](index)
      to_a[index]
    end

    def ==(other)
      case other
      when Size then @width == other.width && @height == other.height
      when Array then to_a == other.to_a
      else false
      end
    end

    def to_s
      "Size(width=#{@width}, height=#{@height})"
    end
    alias inspect to_s
  end

  class Box
    attr_reader :left, :top, :width, :height

    def initialize(left, top, width, height)
      @left = left.to_i
      @top = top.to_i
      @width = width.to_i
      @height = height.to_i
    end

    def to_a
      [@left, @top, @width, @height]
    end
    alias to_ary to_a

    def [](index)
      to_a[index]
    end

    def ==(other)
      case other
      when Box then to_a == other.to_a
      when Array then to_a == other.to_a
      else false
      end
    end

    def to_s
      "Box(left=#{@left}, top=#{@top}, width=#{@width}, height=#{@height})"
    end
    alias inspect to_s
  end
end
