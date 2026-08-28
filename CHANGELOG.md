# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-28

First standalone release.

This app previously shipped as a second project inside
[printfilemanager](https://github.com/trsdn/printfilemanager). Someone who wants Finder previews for
`.3mf` files should not have to find them inside a library manager, so it now lives on its own.
History is preserved.

### Added

- `scripts/verify-quicklook.swift`, which asks macOS for a thumbnail through `QLThumbnailGenerator`
  — the API Finder actually calls — and reports the size and how long it took. This exists because
  the obvious tool does not work; see below.
- `scripts/check-bundle.sh`, run by CI, which checks the built bundle against what the notarization
  broker demands: no symlinks, no embedded frameworks, one version across the app and both
  extensions, full `X.Y.Z` semver, the display name the profile expects, and both extensions
  present. Every one of those corresponds to a failure that previously cost a release cycle,
  because the broker only validates at signing time.

### Changed

- 3MF parsing now comes from [ThreeMFKit](https://github.com/trsdn/ThreeMFKit) 1.0.1 as a published
  package pinned to an exact version, rather than a sibling directory on disk. The two projects no
  longer have to sit next to each other in the filesystem.

### Documented

- **`qlmanage -t` does not work with modern Quick Look extensions.** It hangs indefinitely: it
  launches the extension and then never sends it a request. A sample of the stalled process shows
  it idle in its run loop, having been asked to do nothing — no frame of this project's code is on
  the stack. The same file returns a 512×512 thumbnail in about 400 ms through
  `QLThumbnailGenerator`. The previous README recommended `qlmanage` as the way to verify the
  extension, which would have led anyone following it to conclude the extension was broken.
- `qlmanage -p` does work, but opens a window and waits for it to be closed, which looks like a
  hang in a script.
