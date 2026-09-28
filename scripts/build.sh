#!/usr/bin/env bash
# Builds CCloud for one platform (or all) and packages it for distribution.
#
#   scripts/build.sh <platform> <method> [--upload] [--no-bump]
#
# platform:  ios | tvos | macos | all
# method:
#   unsigned      For sideloading. iOS/tvOS: unsigned .ipa (AltStore, Sideloadly, TrollStore
#                 and similar tools sign it on install). macOS: ad-hoc signed app in a .dmg
#                 (users right-click > Open the first time).
#   development   Signed for your development devices.
#   ad-hoc        iOS/tvOS: signed .ipa for devices registered in your developer account.
#   app-store     For App Store Connect / TestFlight. Add --upload to upload right away.
#   developer-id  macOS: signed with Developer ID, notarized and stapled, in a .dmg.
#                 Needs NOTARY_PROFILE, a keychain profile made once with:
#                   xcrun notarytool store-credentials <name> --apple-id … --team-id 987RHGW4P4
#
# Every archive is followed by scripts/bump-build-number.sh, so the next build gets a
# fresh build number (TestFlight refuses a repeated one). Pass --no-bump to skip that.
#
# Signed methods use automatic signing with the team in the project and may create
# provisioning profiles in your account (-allowProvisioningUpdates).
# Everything lands in build/<platform>/<method>/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/CCloud/CCloud.xcodeproj"
TEAM_ID="987RHGW4P4"

usage() {
    sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

[ $# -ge 2 ] || usage
PLATFORM="$1"
METHOD="$2"
UPLOAD="no"
BUMP="yes"
for flag in "${@:3}"; do
    case "$flag" in
        --upload) UPLOAD="yes" ;;
        --no-bump) BUMP="no" ;;
        *) usage ;;
    esac
done
[ "$METHOD" = "sideload" ] && METHOD="unsigned"

scheme_for() {
    case "$1" in
        ios) echo "CCloud-iOS" ;;
        tvos) echo "CCloud-tvOS" ;;
        macos) echo "CCloud-macOS" ;;
    esac
}

destination_for() {
    case "$1" in
        ios) echo "generic/platform=iOS" ;;
        tvos) echo "generic/platform=tvOS" ;;
        macos) echo "generic/platform=macOS" ;;
    esac
}

export_method() {
    case "$1" in
        development) echo "debugging" ;;
        ad-hoc) echo "release-testing" ;;
        app-store) echo "app-store-connect" ;;
        developer-id) echo "developer-id" ;;
    esac
}

check_supported() {
    local platform="$1" method="$2"
    case "$platform:$method" in
        ios:unsigned|ios:development|ios:ad-hoc|ios:app-store) ;;
        tvos:unsigned|tvos:development|tvos:ad-hoc|tvos:app-store) ;;
        macos:unsigned|macos:development|macos:app-store|macos:developer-id) ;;
        *) echo "error: '$method' isn't available for $platform" >&2; return 1 ;;
    esac
}

bump_build_number() {
    [ "$BUMP" = "yes" ] || return 0
    echo "==> Next build number: $("$ROOT/scripts/bump-build-number.sh")"
}

make_dmg() {
    local app="$1" dmg="$2" staging
    staging="$(mktemp -d)"
    cp -R "$app" "$staging/"
    ln -s /Applications "$staging/Applications"
    rm -f "$dmg"
    hdiutil create -quiet -volname "CCloud" -srcfolder "$staging" -ov -format UDZO "$dmg"
    rm -rf "$staging"
}

build_one() {
    local platform="$1" method="$2"
    check_supported "$platform" "$method" || return 1

    local scheme destination out archive
    scheme="$(scheme_for "$platform")"
    destination="$(destination_for "$platform")"
    out="$ROOT/build/$platform/$method"
    archive="$out/CCloud-$platform.xcarchive"
    rm -rf "$out"
    mkdir -p "$out"

    echo "==> Archiving $scheme ($method)"
    if [ "$method" = "unsigned" ]; then
        local signing=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="")
        if [ "$platform" = "macos" ]; then
            # Apple silicon only runs signed code: sign ad hoc ("Sign to Run Locally").
            # Without the hardened runtime: its library validation refuses to load the ad-hoc
            # signed VLCKit framework (ad-hoc code has no Team ID to match), and the app
            # crashes at launch. Signed exports keep it, as notarization requires.
            signing=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO)
        fi
        xcodebuild archive -quiet -project "$PROJECT" -scheme "$scheme" -configuration Release \
            -destination "$destination" -archivePath "$archive" "${signing[@]}"
        bump_build_number

        local app="$archive/Products/Applications/CCloud.app"
        if [ "$platform" = "macos" ]; then
            make_dmg "$app" "$out/CCloud-macOS.dmg"
            echo "==> $out/CCloud-macOS.dmg"
        else
            local name="CCloud-$([ "$platform" = ios ] && echo iOS || echo tvOS)-unsigned.ipa"
            (cd "$out" && mkdir -p Payload && cp -R "$app" Payload/ && zip -qry "$name" Payload && rm -rf Payload)
            echo "==> $out/$name"
        fi
        return 0
    fi

    # Automatic signing at archive time asks for a tvOS development profile, which needs a
    # registered Apple TV in the developer account. For App Store builds, archive tvOS
    # unsigned and let the export step sign it with the distribution certificate.
    local archive_signing=(-allowProvisioningUpdates)
    if [ "$platform" = "tvos" ] && [ "$method" = "app-store" ]; then
        archive_signing=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="")
    fi
    xcodebuild archive -quiet -project "$PROJECT" -scheme "$scheme" -configuration Release \
        -destination "$destination" -archivePath "$archive" "${archive_signing[@]}"
    bump_build_number

    local options="$out/ExportOptions.plist" destination_mode="export"
    [ "$method" = "app-store" ] && [ "$UPLOAD" = "yes" ] && destination_mode="upload"
    cat > "$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$(export_method "$method")</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>$destination_mode</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

    # Xcode would otherwise renumber the build itself at export (to one above App Store
    # Connect's latest), and the .ipa would no longer match the project's build number.
    echo "==> Exporting ($(export_method "$method"), $destination_mode)"
    xcodebuild -exportArchive -archivePath "$archive" -exportPath "$out" \
        -exportOptionsPlist "$options" -allowProvisioningUpdates

    if [ "$platform" = "macos" ] && [ "$method" = "developer-id" ]; then
        : "${NOTARY_PROFILE:?Set NOTARY_PROFILE to a notarytool keychain profile (see the header of this script)}"
        local dmg="$out/CCloud-macOS.dmg"
        make_dmg "$out/CCloud.app" "$dmg"
        echo "==> Notarizing (this can take a few minutes)"
        xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
        xcrun stapler staple "$dmg"
        echo "==> $dmg"
    else
        echo "==> $out"
    fi
}

if [ "$PLATFORM" = "all" ]; then
    for platform in ios tvos macos; do
        if check_supported "$platform" "$METHOD" 2>/dev/null; then
            build_one "$platform" "$METHOD"
        else
            echo "--- skipping $platform: '$METHOD' isn't available there"
        fi
    done
else
    case "$PLATFORM" in ios|tvos|macos) ;; *) usage ;; esac
    build_one "$PLATFORM" "$METHOD"
fi
