# frozen_string_literal: true

module AutoGUI
  module Run
    module_function

    def tokenize(command_str)
      command_pattern = /^(su|sd|ss|c|l|m|r|g|d|k|w|h|f|s|a|p)/
      command_list = []
      i = 0
      while i < command_str.length
        if command_str[i] =~ /[ \t\n\r]/
          i += 1
          next
        end

        mo = command_pattern.match(command_str[i..])
        raise AutoGUIException, "Invalid command at index #{i}: #{command_str[i]} is not a valid command" if mo.nil?

        individual = mo[1]
        command_list << individual
        i += individual.length

        case individual
        when "c", "l", "m", "r", "su", "sd", "ss"
          nil
        when "g", "d"
          x = get_number_token(command_str[i..])
          i += x.length
          comma = get_comma_token(command_str[i..])
          i += comma.length
          y = get_number_token(command_str[i..])
          i += y.length
          command_list << x.lstrip << y.lstrip
        when "s", "p"
          num = get_number_token(command_str[i..])
          i += num.length
          command_list << num.lstrip
        when "k", "w", "h", "a"
          quoted = get_quoted_string_token(command_str[i..])
          i += quoted.length
          command_list << quoted.strip[1..-2]
        when "f"
          loops = get_number_token(command_str[i..])
          i += loops.length
          sub = get_parens_token(command_str[i..])
          i += sub.length
          command_list << loops.lstrip
          inner = sub.lstrip[1..-2]
          command_list << tokenize(inner)
        end
      end
      command_list
    end

    def run(command_str, ss_count = nil)
      ss_count ||= [0]
      original_pause = AutoGUI.pause
      run_list(tokenize(command_str), ss_count)
    ensure
      AutoGUI.pause = original_pause
    end

    def run_list(command_list, ss_count)
      i = 0
      while i < command_list.length
        command = command_list[i]
        case command
        when "c" then AutoGUI.click(button: PRIMARY)
        when "l" then AutoGUI.click(button: LEFT)
        when "m" then AutoGUI.click(button: MIDDLE)
        when "r" then AutoGUI.click(button: RIGHT)
        when "su" then AutoGUI.scroll(1)
        when "sd" then AutoGUI.scroll(-1)
        when "ss"
          AutoGUI.screenshot("screenshot#{ss_count[0]}.png")
          ss_count[0] += 1
        when "s"
          AutoGUI.sleep(command_list[i + 1].to_f)
          i += 1
        when "p"
          AutoGUI.pause = command_list[i + 1].to_f
          i += 1
        when "g"
          x = command_list[i + 1]
          y = command_list[i + 2]
          if x.start_with?("+", "-") && y.start_with?("+", "-")
            AutoGUI.move(x.to_i, y.to_i)
          else
            AutoGUI.moveTo(x.to_i, y.to_i)
          end
          i += 2
        when "d"
          x = command_list[i + 1]
          y = command_list[i + 2]
          if x.start_with?("+", "-") && y.start_with?("+", "-")
            AutoGUI.drag(x.to_i, y.to_i)
          else
            AutoGUI.dragTo(x.to_i, y.to_i)
          end
          i += 2
        when "k"
          AutoGUI.press(command_list[i + 1])
          i += 1
        when "w"
          AutoGUI.write(command_list[i + 1])
          i += 1
        when "h"
          AutoGUI.hotkey(*command_list[i + 1].delete(" ").split(","))
          i += 1
        when "a"
          AutoGUI.alert(command_list[i + 1])
          i += 1
        when "f"
          command_list[i + 1].to_i.times { run_list(command_list[i + 2], ss_count) }
          i += 2
        end
        i += 1
      end
    end

    def get_number_token(command_str)
      mo = /^\s*[+-]?\d+(?:\.\d+)?/.match(command_str)
      raise AutoGUIException, "Invalid command at index 0: a number was expected" if mo.nil?

      mo[0]
    end

    def get_quoted_string_token(command_str)
      mo = /^\s*'(.*?)'/.match(command_str)
      raise AutoGUIException, "Invalid command at index 0: a quoted string was expected" if mo.nil?

      mo[0]
    end

    def get_comma_token(command_str)
      mo = /^\s*,/.match(command_str)
      raise AutoGUIException, "Invalid command at index 0: a comma was expected" if mo.nil?

      mo[0]
    end

    def get_parens_token(command_str)
      raise AutoGUIException, "Invalid command at index 0: No open parenthesis found." unless command_str =~ /^\s*\(/

      i = 0
      open_count = 0
      while i < command_str.length
        case command_str[i]
        when "("
          open_count += 1
        when ")"
          open_count -= 1
          if open_count.zero?
            i += 1
            break
          elsif open_count.negative?
            raise AutoGUIException, "Invalid command at index 0: No open parenthesis for this close parenthesis."
          end
        end
        i += 1
      end
      raise AutoGUIException, "Invalid command at index 0: Not enough close parentheses." if open_count.positive?

      command_str[0...i]
    end
  end
end
