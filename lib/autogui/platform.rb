# frozen_string_literal: true

require "rbconfig"

module AutoGUI
  module Platform
    # `module_function` copies each `def` to the singleton class, but not later
    # `alias` names. Promote any instance method that is still missing there.
    def self.copy_aliases!(mod)
      names = (mod.private_instance_methods(false) + mod.instance_methods(false)).uniq
      names.each do |name|
        sc = mod.singleton_class
        next if sc.method_defined?(name) || sc.private_method_defined?(name)

        mod.send(:module_function, name)
      end
    end

    module_function

    def current
      @current ||=
        case RbConfig::CONFIG["host_os"]
        when /mswin|mingw|cygwin/i
          require_relative "platform/windows"
          Windows.init!
          Windows
        when /darwin/i
          require_relative "platform/darwin"
          Darwin.init!
          Darwin
        when /linux|bsd/i
          require_relative "platform/linux"
          Linux.init!
          Linux
        else
          raise NotImplementedError, "Your platform (#{RbConfig::CONFIG['host_os']}) is not supported by AutoGUI."
        end
    end

    def windows?
      current == Windows
    end

    def darwin?
      current.name.end_with?("Darwin")
    end

    def linux?
      current.name.end_with?("Linux")
    end
  end
end
