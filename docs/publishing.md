# Publishing AutoGUI to RubyGems

The gem name is **`autogui`**. It was unused on [rubygems.org](https://rubygems.org/gems/autogui) at first publication.

## One-time setup

1. Create an account at [https://rubygems.org](https://rubygems.org) (enable MFA).
2. Sign in, open **Edit profile → API keys**, create a key with **push** permission.
3. Store it locally (do not commit this file):

```
mkdir $HOME/.gem
# Unix
echo ":rubygems_api_key: YOUR_KEY" > $HOME/.gem/credentials
chmod 0600 $HOME/.gem/credentials
```

Windows (PowerShell):

```
New-Item -ItemType Directory -Force $env:USERPROFILE\.gem | Out-Null
Set-Content $env:USERPROFILE\.gem\credentials ":rubygems_api_key: YOUR_KEY"
```

Or paste the key when `gem push` asks.

4. Confirm:

```
gem signin
gem owner autogui
```

(The last command works only after the first successful push.)

## Release checklist

1. Bump `AutoGUI::VERSION` in `lib/autogui/version.rb`.
2. Add a section to `CHANGELOG.md`.
3. Run tests:

```
ruby -Ilib:test test/test_autogui.rb
```

4. Build and inspect:

```
gem build autogui.gemspec
gem unpack autogui-VERSION.gem --target /tmp/autogui-unpack
```

5. Push:

```
gem push autogui-VERSION.gem
```

6. Tag and push git:

```
git tag -a vVERSION -m "vVERSION"
git push origin main --tags
```

After that, anyone can install with:

```
gem install autogui
```

```ruby
# Gemfile
gem "autogui"
```

## Metadata this gemspec already sets

- `homepage`, `source_code_uri`, `bug_tracker_uri`, `changelog_uri`, `documentation_uri`
- `allowed_push_host` → `https://rubygems.org`
- `rubygems_mfa_required` → `true` (new versions must be pushed with MFA)
- `extra_rdoc_files` → README, CHANGELOG, LICENSE, docs

## Yanking a bad release

```
gem yank autogui -v VERSION
```

Use yank only for secrets or broken installs; prefer a new patch version for ordinary bugs.
