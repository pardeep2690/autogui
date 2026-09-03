# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "autogui"

puts AutoGUI.print_info

puts "Screen: #{AutoGUI.size}"
puts "Mouse:  #{AutoGUI.position}"
puts "On screen (0,0): #{AutoGUI.on_screen(0, 0)}"

puts
puts "In 3 seconds the mouse will move to (200, 200) and back."
puts "Slam it into a corner to abort."
AutoGUI.countdown(3)

here = AutoGUI.position
AutoGUI.move_to(200, 200, duration: 0.4)
AutoGUI.move_to(here.x, here.y, duration: 0.4)
puts "back at #{AutoGUI.position}"
