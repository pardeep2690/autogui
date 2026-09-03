# frozen_string_literal: true

require_relative "lib/autogui/version"

Gem::Specification.new do |spec|
  spec.name = "autogui"
  spec.version = AutoGUI::VERSION
  spec.authors = ["pardeep2690"]
  spec.email = ["pardeep2690@users.noreply.github.com"]
  spec.summary = "Ruby GUI automation: mouse, keyboard, screenshots, and image search"
  spec.description = <<~DESC
    AutoGUI controls the mouse and keyboard, takes screenshots, finds images on
    the screen, shows message boxes, and inspects application windows. It is a
    Ruby port of Python PyAutoGUI with snake_case methods and CamelCase aliases.

    Windows talks to the Win32 API through Ruby's standard-library Fiddle
    (no extra gems). macOS uses osascript and screencapture. Linux uses
    xdotool plus scrot, ImageMagick, or grim.

    Fail-safe: moving the cursor into a screen corner raises FailSafeException.
  DESC
  spec.homepage = "https://github.com/pardeep2690/autogui"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/pardeep2690/autogui",
    "bug_tracker_uri" => "https://github.com/pardeep2690/autogui/issues",
    "changelog_uri" => "https://github.com/pardeep2690/autogui/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/pardeep2690/autogui#readme",
    "allowed_push_host" => "https://rubygems.org",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir[
      "lib/**/*.rb",
      "bin/*",
      "examples/**/*.rb",
      "docs/**/*.md",
      "README.md",
      "CHANGELOG.md",
      "LICENSE"
    ]
  end
  spec.bindir = "bin"
  spec.executables = ["autogui"]
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = %w[README.md CHANGELOG.md LICENSE docs/api.md docs/guide.md]
  spec.rdoc_options = ["--main", "README.md", "--title", "AutoGUI"]
end
