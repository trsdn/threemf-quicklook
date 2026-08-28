# Conformance self-assessment

Against the [trsdn Repository Quality Standard](https://github.com/trsdn/.github) v1.3.3, assessed
2026-08-28. The machine-readable result is [`.github/conformance.yml`](../.github/conformance.yml);
the badge in the README is rendered from it and cannot be edited independently.

**Result: Needs work — 57 pass, 4 partial, 0 fail, 23 not applicable.**

No criterion fails. The state is `Needs work` rather than `Healthy` because of X03: this app's
entire output is images rendered into Finder, and their accessible description is Finder's, not
ours. That is worth naming rather than burying.

## The four partials

| # | Requirement | Where it stands |
|---|---|---|
| X03 | Non-text content has a text alternative | The preview and thumbnail extensions return an image to Finder. What VoiceOver announces for it is Finder's, and `QLPreviewingController` offers no accessible-description hook for a returned image. The host app window is a single line of text and is readable. There is no known way to close this from here; it is recorded rather than claimed. |
| S03 | Formatting, linting, type and static checks run automatically | Swift 6 language mode makes concurrency and sendability errors rather than warnings, and CI checks bundle shape, plist versions and badge drift. There is no SwiftLint or SwiftFormat configuration, so style is not enforced. |
| P09 | Repository activity from a self-hosted, generated source | No statistics card is committed yet. No third-party image service is used in its place, which is the failure the criterion exists to prevent. |
| G08 | Repository-scoped agent configuration is intentional | No `.github/github-app.yml`. The defaults are acceptable, but that is an assumption rather than a recorded decision. |

## What is not applicable, and why

- **D02, D04, D06** — there are no secrets, no infrastructure and no runtime configuration. The
  deliverable is a signed application bundle a user drags into `/Applications`.
- **Documentation repositories (T01–T05)** — this is not a documentation repository.
- **Data protection (Y03, Y04, Y06)** — the extensions read the file they were asked about and
  return an image. Nothing is collected, stored or transmitted, so there is no data to export,
  retain or delete. Y01, Y02 and Y05 do apply and pass.
- **Localization (L04–L06)** — English-only by decision, with no string catalogs and no planned
  localization; there is almost no user-facing text to localize.
- **Accessibility (X01, X02, X04, X05)** — the host app has one window with one line of text and no
  interactive controls. There is no navigation, no form, no colour-carried meaning.
- **S06** — there is no configuration.
- **Archived (A01–A04)** — actively developed.

## Evidence for the ones worth naming

| # | Requirement | Evidence |
|---|---|---|
| B05 | A reproducible validation command | `xcodegen generate` then `xcodebuild … build`, plus `scripts/check-bundle.sh`; documented in README, CONTRIBUTING and AGENTS.md and run unchanged by CI. |
| B07 | Dependencies and runtimes declared | `project.yml` declares Swift 6, macOS 15 and ThreeMFKit pinned by `exactVersion`. |
| S01 | Setup reproducible from a clean checkout | Verified: the project was built from a fresh checkout against the published package, and the first attempt failed for a real reason — ThreeMFKit's `.unsafeFlags`, which SwiftPM forbids for a versioned dependency. Fixed at the source and released as 1.0.1. |
| S02 | Tests cover important behaviour and failure paths | The parsing logic and its failure paths are tested in [ThreeMFKit](https://github.com/trsdn/ThreeMFKit), which has 18 tests including malformed and hostile input. This repository has no unit tests of its own: it is two thin extension entry points and a host app. What it has instead is `scripts/check-bundle.sh`, which is run by CI and was itself verified by deliberately introducing each failure. This is the weakest evidence in this record and is recorded as such. |
| S04 | CI covers every supported runtime | macOS 15, universal arm64 + x86_64. The universal build is what ships and is what CI builds. |
| S05 | Secret scanning | Enabled with push protection. |
| S09 | Required checks protect the default branch | `main` requires `Build` and `Versions`; force pushes and deletions are off. |
| S10 | Architecture and non-obvious constraints documented | README explains where the logic actually lives and why the extensions must decline plain ZIPs. AGENTS.md records the constraints that are invisible in the code: no embedded frameworks because preflight rejects symlinks, the exact-version pin because the bundle is notarized, and that `qlmanage -t` proves nothing. |
| D01 | Install, prerequisites and command documented | README documents the install, the mandatory single launch that registers the extensions, and the registry refresh. |
| D03 | Health verification and rollback documented | `scripts/verify-quicklook.swift` asks macOS for a thumbnail through the API Finder uses and reports the size and duration. Rollback is installing an earlier signed release; the app holds no state to migrate. |
| D05 | Verification after deploy | Verified for v1.0.0 against a real library: both extensions registered and enabled at 1.0.0, five real `.3mf` files rendered in 28–434 ms. |
| I05 | Icon reused across surfaces | The app icon is embedded at all ten sizes and is the DMG volume icon. |
| I06 | Identity metadata produced by the build | Every `Info.plist` references `$(MARKETING_VERSION)`; `scripts/check_plist_versions.py` fails on a literal, in CI. |
| R03 | Releases are signed and identifiable | v1.0.0 publishes signed, notarized, universal DMG and ZIP with checksums and a `provenance.json` naming the broker run and source commit. `spctl -a` reports `accepted`, `source=Notarized Developer ID`. |
| Y02 | No third-party observation of readers | Licence and platform badges are generated from `LICENSE` and `project.yml` and committed, so no external host is contacted when the README is read. The release badge remains remote because its value genuinely changes without a commit. |
| Y05 | Third-party data flows are declared | There are none. The extensions reach no network. |

## Notes

The most useful thing found while preparing this repository was that the previous documentation was
wrong in a way that would have wasted other people's time: it recommended `qlmanage` for verifying
the extension, and `qlmanage -t` hangs forever against modern Quick Look extensions. Anyone
following it would have concluded the extension was broken. The README now says so explicitly and
ships a script that works.
