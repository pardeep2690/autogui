# frozen_string_literal: true

require_relative "lib/autogui/version"

Gem::Specification.new do |spec|
  spec.name = "autogui"
  spec.version = AutoGUI::VERSION
  spec.authors = ["AutoGUI"]
  spec.summary = "Ruby GUI automation library (mouse, keyboard, screenshots)"
  spec.description = <<~DESC
    Control the mouse and keyboard, take screenshots, locate images on screen,
    show message boxes, and inspect windows. Ruby port of Python PyAutoGUI.
    Windows is implemented through the Win32 API via Fiddle (stdlib). macOS and
    Linux use system tools (osascript/screencapture, xdotool/scrot).
  DESC
  spec.homepage = "https://github.com/pardeep2690/autogui"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 2.7.0"
  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb", "bin/*", "examples/**/*.rb", "README.md", "LICENSE"]
  end
  spec.bindir = "bin"
  spec.executables = ["autogui"]
  spec.require_paths = ["lib"]
  spec.metadata = {
    "source_code_uri" => "https://github.com/pardeep2690/autogui",
    "bug_tracker_uri" => "https://github.com/pardeep2690/autogui/issues",
    "documentation_uri" => "https://github.com/pardeep2690/autogui#readme"
  }
end
