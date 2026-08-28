#!/usr/bin/env bash
# Check the built bundle against what the notarization broker will demand.
#
# The broker validates a bundle only at signing time, which is after a tag has been cut. Every
# check here corresponds to a failure that has actually happened and cost a release cycle:
#
#   - an embedded framework, which is a versioned bundle full of symlinks; preflight rejects any
#     symlink outright
#   - a version that did not equal the tag, because an Info.plist carried a literal
#   - a display name that did not match the profile
#
# Finding these locally costs seconds. Finding them in the broker costs a tag, a build and a
# preflight run.
set -euo pipefail

cd "$(dirname "$0")/.."

APP="${1:-}"
if [[ -z "$APP" ]]; then
  APP="$(find ~/Library/Developer/Xcode/DerivedData build . -maxdepth 6 -name ThreeMFQuickLook.app \
         -path '*/Build/Products/*' 2>/dev/null | head -1 || true)"
fi

if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "error: no built ThreeMFQuickLook.app found. Build first, or pass the path." >&2
  exit 1
fi

echo "Checking $APP"
status=0

fail() {
  echo "  FAIL  $1" >&2
  status=1
}

# Preflight rejects any symlink in the bundle, and an embedded framework is full of them. This is
# why ThreeMFKit is a static product.
if symlinks="$(find "$APP" -type l)" && [[ -n "$symlinks" ]]; then
  fail "bundle contains symlinks, which preflight rejects:"
  echo "$symlinks" | sed 's|^|        |' >&2
fi

if [[ -d "$APP/Contents/Frameworks" ]]; then
  fail "bundle embeds frameworks; link dependencies statically instead"
fi

# Every Info.plist must agree on the version, and it must be full X.Y.Z semver -- the broker
# rejects anything else, and rejected v0.1 for exactly this reason.
declared="$(awk -F'"' '/^ *MARKETING_VERSION:/ { print $2; exit }' project.yml)"
if [[ ! "$declared" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fail "MARKETING_VERSION '$declared' is not full X.Y.Z semver"
fi

while IFS= read -r plist; do
  actual="$(plutil -extract CFBundleShortVersionString raw -o - "$plist" 2>/dev/null || echo "")"
  if [[ "$actual" != "$declared" ]]; then
    fail "$(basename "$(dirname "$(dirname "$plist")")") reports version '$actual', expected '$declared'"
  fi
done < <(
  # Only our own bundles. SwiftPM emits a resource bundle for any dependency shipping a privacy
  # manifest, and those legitimately carry no version -- checking them would fail on something we
  # neither own nor need to be versioned.
  echo "$APP/Contents/Info.plist"
  find "$APP/Contents/PlugIns" -maxdepth 3 -name Info.plist -path '*.appex/Contents/Info.plist' 2>/dev/null
)

# The broker compares the display name, falling back from CFBundleDisplayName to CFBundleName.
display="$(plutil -extract CFBundleDisplayName raw -o - "$APP/Contents/Info.plist" 2>/dev/null \
           || plutil -extract CFBundleName raw -o - "$APP/Contents/Info.plist" 2>/dev/null || echo "")"
if [[ "$display" != "3MF Quick Look" ]]; then
  fail "display name is '$display', but the broker profile expects '3MF Quick Look'"
fi

# Both extensions must actually be present; an app that registers nothing is not a failure Xcode
# reports.
for appex in ThreeMFPreviewExtension ThreeMFThumbnailExtension; do
  if [[ ! -d "$APP/Contents/PlugIns/$appex.appex" ]]; then
    fail "missing $appex.appex"
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "  OK    no symlinks, no embedded frameworks, version $declared everywhere, both extensions present"
fi

exit "$status"
