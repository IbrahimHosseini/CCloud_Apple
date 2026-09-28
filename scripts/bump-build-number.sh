#!/usr/bin/env bash
# Raises the build number (CFBundleVersion) of every target by one, or sets it.
#
#   scripts/bump-build-number.sh          # highest current number + 1
#   scripts/bump-build-number.sh 12       # set it to 12
#
# TestFlight rejects an upload whose build number it has already seen, so
# scripts/build.sh runs this after every archive. The number lives in two places,
# which this keeps in step: CURRENT_PROJECT_VERSION in the Xcode project and BUILD_NUMBER
# in scripts/generate-xcodeproj.py (so regenerating the project doesn't reset it).
# Prints the new number.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$ROOT/CCloud/CCloud.xcodeproj/project.pbxproj"
GENERATOR="$ROOT/scripts/generate-xcodeproj.py"

if [ $# -ge 1 ]; then
    NEW="$1"
    case "$NEW" in ''|*[!0-9]*) echo "error: build number must be a positive integer" >&2; exit 1 ;; esac
else
    CURRENT="$(grep -oE 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ" | grep -oE '[0-9]+' | sort -n | tail -1)"
    [ -n "$CURRENT" ] || { echo "error: no CURRENT_PROJECT_VERSION in the project" >&2; exit 1; }
    NEW=$((CURRENT + 1))
fi

sed -i '' -E "s/(CURRENT_PROJECT_VERSION = )[0-9]+;/\1$NEW;/" "$PBXPROJ"
sed -i '' -E "s/^(BUILD_NUMBER = \")[0-9]+\"/\1$NEW\"/" "$GENERATOR"
echo "$NEW"
