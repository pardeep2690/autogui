# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "autogui"

needle_path = ARGV[0]
abort "usage: ruby examples/locate_demo.rb path/to/needle.png" unless needle_path

puts "Searching for #{needle_path} on screen…"
box = AutoGUI.locate_on_screen(needle_path, confidence: 0.95)
if box
  puts "found #{box}"
  puts "center #{AutoGUI.center(box)}"
else
  puts "not found"
end
