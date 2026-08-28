# Contributing

Issues and pull requests are welcome. This is a personal project maintained by one person, so there
is no response commitment.

## Before you open a pull request

```bash
xcodegen generate
xcodebuild -project ThreeMFQuickLook.xcodeproj -scheme ThreeMFQuickLook \
           -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
./scripts/check-bundle.sh
./scripts/badges.py --check
```

`ThreeMFQuickLook.xcodeproj` is generated from `project.yml` and is also committed. Regenerate and
commit it in the same change, or CI fails on a stale project.

## Where the code lives

Most of the interesting logic is **not here**. Reading `.3mf` packages and choosing which embedded
image is the preview worth showing is [ThreeMFKit](https://github.com/trsdn/ThreeMFKit), which has
its own tests. This repository holds the two Finder extensions and the host app that registers
them.

If your change is about which image gets picked, or about handling a malformed package, it belongs
in ThreeMFKit.

## Testing a change by hand

Quick Look extensions only register once their host app has been launched:

```bash
# after building, from the built products directory
cp -R ThreeMFQuickLook.app /Applications/
open -a /Applications/ThreeMFQuickLook.app
qlmanage -r && qlmanage -r cache
swift scripts/verify-quicklook.swift ~/Downloads/some-model.3mf
```

Do not use `qlmanage -t` — it hangs against modern Quick Look extensions and tells you nothing.
See the README for why.

## What a change needs

- **A reason in the commit message.** What was wrong and why this fixes it, not what the diff shows.
- **Verification you actually ran.** "Previews work" is not evidence; the output of
  `verify-quicklook.swift` against a real file is.

## Ownership

Every path is owned by @trsdn — see [.github/CODEOWNERS](.github/CODEOWNERS).
