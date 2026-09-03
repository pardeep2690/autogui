# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-09-03

### Added

- First public release: Ruby port of Python PyAutoGUI.
- Mouse: move, drag, click, scroll, button down/up, tweens.
- Keyboard: write, press, hotkey, hold, key down/up, Unicode on Windows.
- Screenshots and locate (PNG/BMP, grayscale, confidence, region).
- Message boxes: alert, confirm, prompt, password.
- Window helpers on Windows (list, activate, move, resize, min/max/close).
- Fail-safe corners, `PAUSE`, screenshot logging, `run` mini-language.
- CLI: `autogui info|mouse|screenshot`.
- Windows (Win32/`Fiddle`), macOS (`osascript`/`screencapture`), Linux (`xdotool` + screenshot tools).
