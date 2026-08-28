# Notes for automated agents

## What this is

A macOS host app plus two Quick Look extensions — preview and thumbnail — for `.3mf` files. The
host app exists only so macOS registers the extensions.

## Validation

```bash
xcodegen generate
xcodebuild -project ThreeMFQuickLook.xcodeproj -scheme ThreeMFQuickLook \
           -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
./scripts/check-bundle.sh
./scripts/badges.py --check
./scripts/check_plist_versions.py
```

CI runs the same. If SwiftPM fails with `cannot use bare repository ... safe.bareRepository is
'explicit'`, that is a local git setting, not a defect:

```bash
GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.bareRepository GIT_CONFIG_VALUE_0=all xcodegen generate
```

## Things worth knowing before changing code

- **The logic is mostly in another repository.** Reading `.3mf` and choosing the preview image is
  [ThreeMFKit](https://github.com/trsdn/ThreeMFKit). A change about which image is picked, or about
  a malformed package, belongs there, not here.
- **ThreeMFKit is pinned to an exact version on purpose.** The bundle is notarized; its inputs must
  be reproducible. Do not loosen it to `from:` for convenience.
- **Do not embed frameworks.** The notarization broker's preflight rejects any symlink in the
  bundle, and a framework is a versioned bundle full of them. ThreeMFKit is a static product for
  this reason. `scripts/check-bundle.sh` enforces it.
- **`qlmanage -t` hangs and proves nothing.** It launches the extension and never sends it a
  request. Use `scripts/verify-quicklook.swift`, which goes through `QLThumbnailGenerator` like
  Finder does. Do not "fix" a reported hang by changing extension code before checking with that
  script.
- **Extensions register only after the host app has been launched once**, and `qlmanage -r` is
  needed afterwards. An extension that appears not to work is usually one that was never
  registered.
- **Every Info.plist must reference `$(MARKETING_VERSION)`**, never a literal. A literal silently
  wins, and the broker rejects a bundle whose version does not equal the tag — at signing time,
  long after CI is green. `scripts/check_plist_versions.py` enforces this.

## Releasing

Tag `vX.Y.Z`, then notarize through the broker:

```bash
scripts/request.sh threemfquicklook vX.Y.Z   # from the macos-notarization-broker checkout
```

The broker builds this source without credentials present and pauses for a manual approval before
signing.
