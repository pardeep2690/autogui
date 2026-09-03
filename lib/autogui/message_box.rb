# frozen_string_literal: true

require "open3"
require "tempfile"

module AutoGUI
  module MessageBox
    MB_OK = 0x00000000
    MB_OKCANCEL = 0x00000001
    MB_YESNOCANCEL = 0x00000003
    MB_YESNO = 0x00000004
    IDOK = 1
    IDCANCEL = 2
    IDYES = 6
    IDNO = 7

    module_function

    def alert(text = "", title = "AutoGUI Alert", button = "OK")
      if windows?
        Platform.current.message_box(text.to_s, title.to_s, MB_OK)
        button.to_s
      else
        dialog_alert(text, title, button)
        button.to_s
      end
    end

    def confirm(text = "", title = "AutoGUI Confirm", buttons = %w[OK Cancel])
      buttons = Array(buttons)
      if windows? && buttons.map(&:to_s) == %w[OK Cancel]
        result = Platform.current.message_box(text.to_s, title.to_s, MB_OKCANCEL)
        result == IDOK ? "OK" : "Cancel"
      elsif windows? && buttons.map(&:to_s) == %w[Yes No]
        result = Platform.current.message_box(text.to_s, title.to_s, MB_YESNO)
        result == IDYES ? "Yes" : "No"
      else
        dialog_choice(text, title, buttons)
      end
    end

    def prompt(text = "", title = "AutoGUI Prompt", default = "")
      dialog_input(text, title, default, password: false)
    end

    def password(text = "", title = "AutoGUI Password", default = "", mask = "*")
      dialog_input(text, title, default, password: true, mask: mask)
    end

    def windows?
      RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/i
    end

    def dialog_alert(text, title, _button)
      if windows?
        Platform.current.message_box(text.to_s, title.to_s, MB_OK)
      else
        system("osascript", "-e", %(display dialog #{js(text)} with title #{js(title)} buttons {"OK"} default button 1)) ||
          system("zenity", "--info", "--title=#{title}", "--text=#{text}")
      end
    end

    def dialog_choice(text, title, buttons)
      if windows?
        vbs = <<~VBS
          Set fso = CreateObject("Scripting.FileSystemObject")
          Set stdout = fso.GetStandardStream(1)
          r = MsgBox(#{vbs_str(text)}, vbYesNoCancel, #{vbs_str(title)})
          If r = vbYes Then stdout.Write "Yes"
          If r = vbNo Then stdout.Write "No"
          If r = vbCancel Then stdout.Write "Cancel"
        VBS
        out = run_vbs(vbs)
        mapped = { "Yes" => buttons[0], "No" => buttons[1], "Cancel" => buttons[2] || buttons[-1] }
        mapped[out] || buttons[-1]
      else
        btns = buttons.map(&:to_s)
        script = "set r to button returned of (display dialog #{js(text)} with title #{js(title)} buttons {#{btns.map { |b| js(b) }.join(',')}} default button 1)"
        out, = Open3.capture2("osascript", "-e", script)
        out.strip.empty? ? nil : out.strip
      end
    end

    def dialog_input(text, title, default, password: false, mask: "*")
      if windows?
        vbs = <<~VBS
          Set fso = CreateObject("Scripting.FileSystemObject")
          Set stdout = fso.GetStandardStream(1)
          r = InputBox(#{vbs_str(text)}, #{vbs_str(title)}, #{vbs_str(default)})
          If IsEmpty(r) Then
            stdout.Write Chr(0)
          Else
            stdout.Write r
          End If
        VBS
        out = run_vbs(vbs)
        return nil if out == "\u0000" || out.nil?

        out
      else
        hidden = password ? " with hidden answer" : ""
        script = "text returned of (display dialog #{js(text)} with title #{js(title)} default answer #{js(default)}#{hidden})"
        out, status = Open3.capture2("osascript", "-e", script)
        status.success? ? out.sub(/\r?\n\z/, "") : nil
      end
    end

    def run_vbs(script)
      file = Tempfile.new(["autogui", ".vbs"])
      file.write(script)
      file.close
      out, = Open3.capture2("cscript", "//Nologo", file.path)
      File.unlink(file.path) rescue nil
      out
    end

    def vbs_str(s)
      %("#{s.to_s.gsub('"', '""')}")
    end

    def js(s)
      s.to_s.inspect
    end
  end
end
