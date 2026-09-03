# frozen_string_literal: true

module AutoGUI
  module Tween
    module_function

    def check(n)
      n = n.to_f
      unless n.between?(0.0, 1.0)
        raise AutoGUIException, "Argument must be between 0.0 and 1.0."
      end

      n
    end

    def linear(n)
      check(n)
    end

    def easeInQuad(n)
      n = check(n)
      n * n
    end

    def easeOutQuad(n)
      n = check(n)
      -n * (n - 2)
    end

    def easeInOutQuad(n)
      n = check(n)
      if n < 0.5
        2 * n * n
      else
        n = n * 2 - 1
        -0.5 * (n * (n - 2) - 1)
      end
    end

    def easeInCubic(n)
      n = check(n)
      n**3
    end

    def easeOutCubic(n)
      n = check(n)
      n -= 1
      n**3 + 1
    end

    def easeInOutCubic(n)
      n = check(n)
      n *= 2
      if n < 1
        0.5 * n**3
      else
        n -= 2
        0.5 * (n**3 + 2)
      end
    end

    def easeInQuart(n)
      n = check(n)
      n**4
    end

    def easeOutQuart(n)
      n = check(n)
      n -= 1
      -(n**4 - 1)
    end

    def easeInOutQuart(n)
      n = check(n)
      n *= 2
      if n < 1
        0.5 * n**4
      else
        n -= 2
        -0.5 * (n**4 - 2)
      end
    end

    def easeInQuint(n)
      n = check(n)
      n**5
    end

    def easeOutQuint(n)
      n = check(n)
      n -= 1
      n**5 + 1
    end

    def easeInOutQuint(n)
      n = check(n)
      n *= 2
      if n < 1
        0.5 * n**5
      else
        n -= 2
        0.5 * (n**5 + 2)
      end
    end

    def easeInSine(n)
      n = check(n)
      -Math.cos(n * Math::PI / 2) + 1
    end

    def easeOutSine(n)
      n = check(n)
      Math.sin(n * Math::PI / 2)
    end

    def easeInOutSine(n)
      n = check(n)
      -0.5 * (Math.cos(Math::PI * n) - 1)
    end

    def easeInExpo(n)
      n = check(n)
      n == 0 ? 0 : 2**(10 * (n - 1))
    end

    def easeOutExpo(n)
      n = check(n)
      n == 1 ? 1 : -(2**(-10 * n)) + 1
    end

    def easeInOutExpo(n)
      n = check(n)
      return 0 if n.zero?
      return 1 if n == 1

      n *= 2
      if n < 1
        0.5 * (2**(10 * (n - 1)))
      else
        0.5 * (-(2**(-10 * (n - 1))) + 2)
      end
    end

    def easeInCirc(n)
      n = check(n)
      -(Math.sqrt(1 - n * n) - 1)
    end

    def easeOutCirc(n)
      n = check(n)
      n -= 1
      Math.sqrt(1 - n * n)
    end

    def easeInOutCirc(n)
      n = check(n)
      n *= 2
      if n < 1
        -0.5 * (Math.sqrt(1 - n * n) - 1)
      else
        n -= 2
        0.5 * (Math.sqrt(1 - n * n) + 1)
      end
    end

    def easeInElastic(n, amplitude = 1, period = 0.3)
      n = check(n)
      return 0 if n.zero?
      return 1 if n == 1

      s = period / (2 * Math::PI) * Math.asin(1.0 / amplitude)
      n -= 1
      -(amplitude * (2**(10 * n)) * Math.sin((n - s) * (2 * Math::PI) / period))
    end

    def easeOutElastic(n, amplitude = 1, period = 0.3)
      n = check(n)
      return 0 if n.zero?
      return 1 if n == 1

      s = period / (2 * Math::PI) * Math.asin(1.0 / amplitude)
      amplitude * (2**(-10 * n)) * Math.sin((n - s) * (2 * Math::PI) / period) + 1
    end

    def easeInOutElastic(n, amplitude = 1, period = 0.45)
      n = check(n)
      return 0 if n.zero?
      return 1 if n == 1

      s = period / (2 * Math::PI) * Math.asin(1.0 / amplitude)
      n *= 2
      if n < 1
        n -= 1
        -0.5 * (amplitude * (2**(10 * n)) * Math.sin((n - s) * (2 * Math::PI) / period))
      else
        n -= 1
        amplitude * (2**(-10 * n)) * Math.sin((n - s) * (2 * Math::PI) / period) * 0.5 + 1
      end
    end

    def easeInBack(n, s = 1.70158)
      n = check(n)
      n * n * ((s + 1) * n - s)
    end

    def easeOutBack(n, s = 1.70158)
      n = check(n)
      n -= 1
      n * n * ((s + 1) * n + s) + 1
    end

    def easeInOutBack(n, s = 1.70158)
      n = check(n)
      s *= 1.525
      n *= 2
      if n < 1
        0.5 * (n * n * ((s + 1) * n - s))
      else
        n -= 2
        0.5 * (n * n * ((s + 1) * n + s) + 2)
      end
    end

    def easeInBounce(n)
      n = check(n)
      1 - easeOutBounce(1 - n)
    end

    def easeOutBounce(n)
      n = check(n)
      if n < 1 / 2.75
        7.5625 * n * n
      elsif n < 2 / 2.75
        n -= 1.5 / 2.75
        7.5625 * n * n + 0.75
      elsif n < 2.5 / 2.75
        n -= 2.25 / 2.75
        7.5625 * n * n + 0.9375
      else
        n -= 2.625 / 2.75
        7.5625 * n * n + 0.984375
      end
    end

    def easeInOutBounce(n)
      n = check(n)
      if n < 0.5
        easeInBounce(n * 2) * 0.5
      else
        easeOutBounce(n * 2 - 1) * 0.5 + 0.5
      end
    end
  end
end
