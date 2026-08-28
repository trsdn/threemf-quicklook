# Changelog

All notable changes to this project are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-08-28

### Added

- **The preview now has a text alternative.** It returned raw image bytes, so the entire content of
  a Quick Look preview was non-text with nothing for VoiceOver to announce. The image is now
  wrapped in HTML and attached by `cid:`, carrying an `alt` that names the file and its pixel
  dimensions — something a sighted user judges at a glance and a screen-reader user otherwise
  cannot. The decorative icon on the no-preview card is `aria-hidden`, and the file name and reason
  are real text.

  The conformance record previously claimed this could not be fixed, because
  `QLPreviewingController` offers no accessible-description hook. That was wrong: `QLPreviewReply`
  accepts HTML with attachments, which is the supported way to do exactly this.
- **A test target**, the first in this repository — 12 tests over the markup a preview returns:
  the text alternative, the decorative-icon marking, dark mode, rounding, and escaping of an
  untrusted file name in both an element body and an attribute value. Verified to catch
  regressions by deliberately removing the quote escape, which failed two of them.
- SwiftLint in CI, sharing thresholds with the repository this was split from.
- A committed repository statistics card, refreshed weekly by a workflow that opens a pull request
  rather than pushing, so branch protection is not weakened for it.
- `.github/github-app.yml`, recording where the logic actually lives and two traps that cost real
  time: `qlmanage -t` proving nothing, and an ad-hoc signed build breaking extension registration.

### Changed

- Both preview documents now adapt to dark mode. Quick Look is shown over the desktop, and a white
  card in dark mode is jarring.
- The markup moved out of `PreviewProvider` into `PreviewMarkup`, which has no QuickLook
  dependency. An app extension cannot be hosted by a unit test, which is why the markup previously
  had nothing testing it at all.

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
