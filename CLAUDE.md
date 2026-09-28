# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

CCloud for Apple platforms: a SwiftUI port of the CCloud Android streaming app (movies and series) for iPhone, iPad, Apple TV and Mac. The Android app it keeps feature parity with lives in the sibling directory `../CCloud` (Kotlin/Compose); its CLAUDE.md describes the catalog API and the Android behavior. The UI is in English and Persian (right-to-left). Targets: iOS/iPadOS 18, tvOS 18, macOS 15; Xcode 27, Swift 6 language mode. `README.md` covers features, distribution and credits.

## Commands

Run from the repository root.

```bash
# Unit tests (Swift Testing, run on the macOS host)
swift test --package-path CCloud/CCloudKit
swift test --package-path CCloud/CCloudKit --filter FavoritesBookTests                          # one suite
swift test --package-path CCloud/CCloudKit --filter "FavoritesBookTests/membershipIsSetExactly"  # one test

# Build an app. Schemes: CCloud-iOS (iPhone + iPad), CCloud-tvOS, CCloud-macOS
xcodebuild build -project CCloud/CCloud.xcodeproj -scheme CCloud-iOS -destination 'generic/platform=iOS Simulator'
xcodebuild build -project CCloud/CCloud.xcodeproj -scheme CCloud-tvOS -destination 'generic/platform=tvOS Simulator'
xcodebuild build -project CCloud/CCloud.xcodeproj -scheme CCloud-macOS -destination 'platform=macOS'

# Compile just the package for a device platform (the package's scheme is "CCloudKit")
cd CCloud/CCloudKit && xcodebuild build -scheme CCloudKit -destination 'generic/platform=tvOS' CODE_SIGNING_ALLOWED=NO

# Distribution builds, written to build/<platform>/<method>/
scripts/build.sh <ios|tvos|macos|all> <unsigned|development|ad-hoc|app-store|developer-id> [--upload] [--no-bump]
scripts/bump-build-number.sh [n]          # +1 on every target's build number, or set it to n

# Generated files: re-run after changing targets/build settings or strings
python3 scripts/generate-xcodeproj.py     # CCloud/CCloud.xcodeproj and its shared schemes
python3 scripts/build-string-catalog.py   # CCloudDesignSystem/Resources/Localizable.xcstrings
```

Simulator device names repeat across installed runtimes, so `-destination 'name=…'` can fail as ambiguous; use `id=<udid>` from `xcrun simctl list devices`.

`build.sh` runs `bump-build-number.sh` after every archive (the archive uses the current number, the next build gets the next one) and disables Xcode's `manageAppVersionAndBuildNumber` at export so the `.ipa` keeps the project's number. That leaves the working tree dirty after a build; commit it. The number lives in `CURRENT_PROJECT_VERSION` in the pbxproj and `BUILD_NUMBER` in `generate-xcodeproj.py`, and the script edits both. For `tvos app-store` it archives unsigned and signs at export, since a signed archive needs a tvOS development profile and the team has no Apple TV registered.

The public TestFlight beta (iOS, iPadOS, tvOS) is `https://testflight.apple.com/join/wYAZ139h`. Every target sets `ITSAppUsesNonExemptEncryption = NO`, so uploads skip the export compliance prompt.

## Architecture

All code is in the local Swift package `CCloud/CCloudKit`, one module per Clean Architecture layer. `Package.swift` enforces the dependency rule, and only the composition root imports `CCloudData`.

- **CCloudDomain** (Foundation only): entities, repository protocols, use cases, and value types holding the business rules. `MediaID` pairs kind and server id because movies and series have separate id spaces. `FavoritesBook` holds favorites and playlists and validates playlist names. `TitleContentPolicy` hides Persian-script titles, like the Android app. `SourceSelection` spots trailers ("تیزر") and picks the source a plain Play starts.
- **CCloudData**: `APIClient` tries the primary host, then the fallback hosts in `APIConfiguration`, and maps failures to `DomainError`. `Endpoint` copies the Android app's paths, including trailing slashes. The API's JSON is loosely typed, so DTOs decode leniently (`LossyList`, `lossyArray`, `lenientInt`/`lenientDouble`/`lenientString`) and skip malformed items. Local repositories persist through `KeyValueStorage`: `FileStorage` on iOS/macOS, `UserDefaultsStorage` on tvOS (tvOS may purge app files), and `InMemoryStorage` for demo mode and tests. `Demo*Repositories` provide an offline catalog.
- **CCloudPresentation**: `@MainActor @Observable` ViewModels. App-wide shared state lives in `AppSettingsModel`, `FavoritesLibrary` and `WatchHistoryLibrary`, one instance each, so a change made on one screen shows everywhere. Ports: `PlaybackLauncher` (implemented by the player module) and `ViewModelFactory` (implemented by the composition root).
- **CCloudDesignSystem**: shared SwiftUI components, per-platform `Metrics`, `.appFont` (system font or the bundled Vazirmatn), `ImagePipeline` (downsampled artwork with caches), and the `L10n` string table with its resources.
- **CCloudPlayer**: `PlaybackCoordinator` implements `PlaybackLauncher`. `EngineSelection` sends VLC-only containers (mkv, avi…) to VLCKit and everything else to AVPlayer, which falls back to VLC when it can't open a file. iOS/tvOS present `AVPlayerViewController` (or the VLC screen) modally through UIKit, which keeps Picture in Picture working; macOS opens one `NSWindow` per video. VLC code sits behind `#if canImport(VLCKitSPM)`.
- **CCloudFeatures**: screens and the per-platform shells. `RootView` is a `.sidebarAdaptable` `TabView` on iOS, iPadOS and tvOS. `MacRootView` is a `NavigationSplitView` sidebar that lists playlists; on Mac, Settings is a separate `Settings` scene. Navigation uses `AppRoute`, and `RouteDestination` builds ViewModels through the `ViewModelFactory` in the environment. Each window has its own `AppNavigation`; menu commands reach it through `@FocusedValue`.
- **CCloudComposition**: `AppContainer` is the DI composition root and the only place that knows concrete types. `-demo` swaps in the demo repositories. `AppRootView` injects the factory and the shared libraries into the environment.

The app targets in `CCloud/App/<platform>/` are thin `@main` shells. `CCloud/App/Shared/` holds assets, the privacy manifest and `InfoPlist.xcstrings`. `CCloud/Config/<platform>/Info.plist` holds keys that build settings can't express: ATS, `UIBackgroundModes`, `CFBundleLocalizations`.

## Conventions and gotchas

- **Generated Xcode project.** Sources in the file-system-synchronized folders need no project edits. Xcode re-saves the pbxproj in its own order, so mirror any build setting change in `scripts/generate-xcodeproj.py`. For example, the macOS target signs "to run locally" with `CODE_SIGN_IDENTITY[sdk=macosx*] = -`.
- **Swift 6 concurrency.** The package doesn't use default MainActor isolation: mark ViewModels and libraries `@MainActor`, and keep Domain/Data types `Sendable`. KVO and notification callbacks must be `@Sendable` closures that hop to the main actor. A main-actor closure called off the main thread crashes at runtime.
- **Name clashes.** Don't reuse Foundation names for types or modules (hence `CatalogSortOrder`, and no module called `Data`).
- **Strings.** Every user-facing string is a typed accessor in `L10n.swift` with a semantic key and an English `defaultValue`.
  - Add the Persian text to `PERSIAN` in `scripts/build-string-catalog.py`, then run the script. It fails on any key without a translation.
  - Interpolated keys also need an `ARGUMENTS` entry, and count-dependent ones an `ENGLISH_ONE` entry.
  - `Text("\(x)")` silently becomes a localization key. Use `Text(verbatim:)` or an already-localized `String`.
  - Format numbers with `.formatted()` so Persian gets Persian digits.
- **Bidirectional text.** Descriptions, genres, countries and episode titles from the API are mostly Persian. Lay paragraphs out with `.naturalDirection(of:)`. Build lines of mixed facts from separate `Text` views; one joined string flips the whole line right-to-left.
- **tvOS limits.** tvOS has no `Slider`, `Stepper`, `ColorPicker`, `keyboardShortcut`, `searchable(text:isPresented:)` or `UIFont.TextStyle.largeTitle`, so branch with `#if os(tvOS)`. Search is live (debounced) there because the tvOS keyboard has no search key.
- **VLCKit** comes from `tylerjonesio/vlckit-spm` 3.6.0, a ~780 MB download cached by SwiftPM.
  - The iOS and tvOS targets end with a `scripts/thin-vlckit.sh` build phase that strips 32-bit slices and bitcode and re-signs; App Store Connect rejects bitcode.
  - Ad-hoc signed macOS builds must turn off the hardened runtime, or dyld refuses the ad-hoc VLCKit at launch. `scripts/build.sh … unsigned` does this.
- **Content.** Real sources are mostly MKV with embedded Persian subtitles (the VLC path); trailers are MP4 (the AVPlayer path). The catalog servers may be unreachable from some networks, so use `-demo` to work offline.

## Checking the UI

- Launch arguments:
  - `-demo`: offline sample catalog, nothing saved.
  - `-ui-section <movies|series|search|favorites|settings>` (debug builds only): start in that section.
  - `-ui-open-first YES` (debug builds only): push the first title's detail page.
  - `-ui-snapshot <path.png>` (debug builds, Mac only): the app renders its main window to a PNG. Window capture otherwise needs Screen Recording permission. Build with `ENABLE_APP_SANDBOX=NO` so the app can write outside its container.
- The Apple TV remote can't be driven from simulator tooling, so reach tvOS screens with the `-ui-*` arguments.
- Persian UI: `xcrun simctl launch <udid> app.thepixelforge.CCloud -AppleLanguages "(fa)" -AppleLocale fa_IR`.
