# Security Policy

## Reporting a vulnerability

Report privately through
[GitHub Security Advisories](https://github.com/trsdn/threemf-quicklook/security/advisories/new).
Please do not open a public issue for a vulnerability.

This is a personal project maintained by one person. There is no response-time commitment, but
reports are read.

## Threat model

A Quick Look extension has an unusually exposed position. It runs on files the user has merely
**selected** in Finder — no double-click, no confirmation — and those files arrive from model
sharing sites, messages and downloads. A malicious `.3mf` reaches this code before anyone has
decided to trust it.

What that means here:

- **Parsing happens in [ThreeMFKit](https://github.com/trsdn/ThreeMFKit)**, which caps the
  uncompressed size of any entry, checked against the declared size and again while decompressing,
  because a `.3mf` preview legitimately compresses near 1000:1 and the declared size can lie. That
  package pins its own dependency and has tests for the malformed cases.
- **The dependency is pinned to an exact version.** A notarized artifact whose inputs can move is
  not reproducible.
- **The extensions also register for `public.zip-archive`**, because a slicer that claims the
  `.3mf` type would otherwise prevent them from ever being asked. They are therefore handed
  arbitrary ZIP files and must decline them rather than extracting something unrelated.
- **No network access, no writes, no code execution.** The extensions read a file and return an
  image.
- **Extensions run in the system's extension sandbox**, with read access only to the file they were
  asked about.

## Supply chain

Releases are signed and notarized by
[macos-notarization-broker](https://github.com/trsdn/macos-notarization-broker). It fetches this
repository's source anonymously at a pinned commit, builds it in a job with **no Apple credentials
present**, validates the resulting bundle against a fixed profile, and only then imports the
signing certificate behind a manual approval gate. No Apple credential exists in this repository or
its workflows.

Each release publishes a `provenance.json` recording the broker run, the profile digest and the
source commit the artifacts were built from, alongside SHA-256 checksums.
