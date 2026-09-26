#!/bin/sh
# Xcode build phase (iOS and tvOS targets): trims the embedded VLCKit framework.
#
# The VideoLAN binaries carry 32-bit slices (iOS, ~60 MB) and embedded bitcode (tvOS,
# ~140 MB). Neither is used by this app, bitcode makes App Store Connect reject the upload
# (ITMS-90482), and sideloaded builds don't get App Store thinning. Remove both, then
# re-sign the framework if the build is signed.
set -eu

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

for name in MobileVLCKit TVVLCKit; do
    framework="${frameworks_dir}/${name}.framework"
    binary="${framework}/${name}"
    [ -f "$binary" ] || continue
    changed=0

    for arch in $(lipo -archs "$binary"); do
        case " ${ARCHS} " in
            *" ${arch} "*) ;;
            *)
                lipo -remove "$arch" -output "$binary" "$binary"
                echo "Removed ${arch} from ${name}"
                changed=1
                ;;
        esac
    done

    if otool -l "$binary" | grep -q "segname __LLVM"; then
        xcrun bitcode_strip -r "$binary" -o "$binary"
        echo "Stripped bitcode from ${name}"
        changed=1
    fi

    if [ "$changed" = 1 ] && [ "${CODE_SIGNING_ALLOWED:-NO}" = "YES" ] && [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
        codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --preserve-metadata=identifier,entitlements,flags "$framework"
    fi
done
