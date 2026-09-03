# frozen_string_literal: true

module AutoGUI
  class AutoGUIException < StandardError; end

  class FailSafeException < AutoGUIException; end

  class ImageNotFoundException < AutoGUIException; end
end
