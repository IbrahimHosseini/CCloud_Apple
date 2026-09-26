# CCloud for Apple platforms

Movies and series from the CCloud catalog on **iPhone, iPad, Mac and Apple TV**, built with SwiftUI.
It's a native port of the [CCloud Android app](https://github.com/code3-dev/CCloud): same catalog API,
same features, with each platform's own navigation, controls and conventions.

| Platform | Navigation | Player |
| --- | --- | --- |
| iPhone | Tab bar (shrinks while scrolling on iOS 26+) | Full-screen system player with Picture in Picture and AirPlay |
| iPad | Floating tab bar that turns into a sidebar | Same, plus keyboard shortcuts and pointer support |
| Mac | Source-list sidebar with playlists, toolbar, menu commands, Settings window (⌘,) | A resizable window per video, keyboard control, full screen |
| Apple TV | tvOS sidebar, focus-driven grids and shelves, lift effects | Full-screen system player driven by the Siri Remote |

All icons are SF Symbols. The UI is in **English and Persian** (right-to-left), following the
device language, or iOS's per-app language setting.

## Features

- Movies and series grids with genre filter, sorting (recently added, release year, IMDb) and infinite scroll
- Search by title, and browsing by country
- Movie and series pages: overview, genres, countries, qualities, seasons and episodes
- Watched marks on episodes (set when playback starts, can be toggled by hand)
- Favorites with playlists: create, rename, delete, and put a title in several playlists
- Playback of MP4/HLS with the system player, and MKV/AVI/… with VLCKit, including embedded
  audio and subtitle tracks and speed control
- Open a file in VLC or Infuse, download it in the browser, copy or share its link
- Settings: appearance (system/light/dark), accent color, Vazirmatn font, skip interval,
  subtitle color, background and size, watched-episode storage, reset

## Architecture

Clean Architecture with MVVM, in a local Swift package (`CCloud/CCloudKit`). Each layer is its own
module, so the compiler enforces the dependency rule: inner layers never import outer ones.

```
CCloudDomain         Entities, repository protocols (ports), use cases, business rules. Foundation only.
CCloudData           → Domain. REST client with host fallback, lenient DTO decoding, JSON/UserDefaults storage.
CCloudPresentation   → Domain. @Observable ViewModels and app-wide state (settings, favorites, watch history).
CCloudDesignSystem   → Domain, Presentation. Shared SwiftUI components, typography, theme, images, strings.
CCloudPlayer         → + DesignSystem, VLCKit. AVPlayer and VLCKit engines, per-platform presentation.
CCloudFeatures       → + Player. Screens and the per-platform navigation shells.
CCloudComposition    → everything. The composition root.
```

- **Dependency injection**: constructor injection everywhere. `AppContainer` (the composition root)
  is the only type that knows concrete implementations. It builds the data layer, hands it to use
  cases through protocols, and creates ViewModels through the `ViewModelFactory` protocol, which
  views read from the environment. Swapping the backend (for example the offline demo catalog) is a
  one-line change there.
- **MVVM**: every screen has an `@Observable` ViewModel in `CCloudPresentation`. Views hold no logic
  beyond layout. Shared state that several screens show (favorites, watch history, settings) lives
  in observable "libraries", so a change on one screen appears everywhere at once.
- **Ports and adapters**: `PlaybackLauncher` is declared by the presentation layer and implemented
  by the player module. Storage is a `KeyValueStorage` protocol with file, UserDefaults (tvOS may
  purge files) and in-memory implementations.

The app targets are thin: an `App` struct per platform in `CCloud/App/<platform>/` that shows
`AppRootView`. Assets, the privacy manifest and localized Info.plist strings live in
`CCloud/App/Shared/`.

## Requirements

- Xcode 27 (Swift 6)
- iOS / iPadOS 18, tvOS 18, macOS 15 or later

## Getting started

Open `CCloud/CCloud.xcodeproj` and pick a scheme: **CCloud-iOS** (iPhone and iPad), **CCloud-tvOS**
or **CCloud-macOS**. The first build downloads VLCKit (about 780 MB, once, cached by Swift Package
Manager).

The catalog servers may not be reachable from every network. To try the app without them, enable
the `-demo` launch argument in the scheme (Product › Scheme › Edit Scheme › Arguments). It swaps in
an offline sample catalog with Apple's public HLS test stream as video, and keeps nothing on disk.

Debug builds also accept `-ui-section <movies|series|search|favorites|settings>` and
`-ui-open-first YES` to start on a given screen, which is handy for screenshots and UI tests.

## Building for distribution

Each platform has its own scheme, so you can archive from Xcode (Product › Archive) as usual.
`scripts/build.sh` does it from the command line and packages the result:

```bash
scripts/build.sh <ios|tvos|macos|all> <method> [--upload]
```

| Method | iOS / iPadOS | tvOS | macOS |
| --- | --- | --- | --- |
| `unsigned` | Unsigned `.ipa` for sideloading (AltStore, Sideloadly, TrollStore…) | Unsigned `.ipa` | Ad-hoc signed app in a `.dmg` |
| `development` | Signed for your devices | Signed for your devices | Signed for your Mac |
| `ad-hoc` | Signed `.ipa` for registered devices | Signed `.ipa` for registered devices | — |
| `app-store` | App Store Connect / TestFlight (`--upload` to upload) | Same | Same |
| `developer-id` | — | — | Developer ID signed, notarized, stapled `.dmg` (needs `NOTARY_PROFILE`) |

Output goes to `build/<platform>/<method>/`. iPhone and iPad share one universal binary.

The macOS `unsigned` DMG is ad-hoc signed and not notarized. On another Mac, macOS blocks the first
launch until it's allowed in System Settings › Privacy & Security › Open Anyway. It's built without
the hardened runtime, whose library validation would refuse the ad-hoc signed VLCKit framework and
crash the app at launch. The same applies to archiving in Xcode with "Sign to Run Locally".

The iOS and tvOS targets have a **Thin VLCKit** build phase (`scripts/thin-vlckit.sh`) that removes
the 32-bit slices and embedded bitcode from VideoLAN's binaries. Bitcode alone is about 140 MB on
tvOS, and App Store Connect rejects it.

## Localization

Every string is typed in `CCloudDesignSystem/Localization/L10n.swift` and translated in
`Resources/Localizable.xcstrings`. The catalog is generated, with the Persian translations kept
next to the generator so the two languages can't drift apart:

```bash
python3 scripts/build-string-catalog.py
```

Text coming from the API (mostly Persian descriptions, genres and countries) is laid out in its own
reading direction, so it reads correctly in both UI languages.

## Tests

```bash
swift test --package-path CCloud/CCloudKit
```

Unit tests cover the domain rules (playlists, content policy, trailer detection, pagination end),
the data layer (endpoint URLs, lenient decoding, host fallback, persistence) and the ViewModels
(pagination, filters, errors, search, detail and favorites). They also run from each scheme's Test
action.

The Xcode project is generated. After changing targets or build settings, edit and re-run:

```bash
python3 scripts/generate-xcodeproj.py
```

## Notes

- **Network security**: `NSAllowsArbitraryLoads` is on, like the Android app's network config,
  because artwork and video hosts aren't all known in advance. App Review asks for a
  justification; narrow it to specific domains if you can.
- **Export compliance**: the app only uses standard HTTPS. If that applies to your build, add
  `ITSAppUsesNonExemptEncryption = NO` to the Info.plists to skip the question on every upload.
- **App Review**: apps that stream third-party video are reviewed strictly (guideline 5.2).
  Sideloading, Ad Hoc and Developer ID don't go through App Review.
- **Titles in Persian script are hidden**, as in the Android app (`TitleContentPolicy`).
- **tvOS storage**: tvOS may purge app files at any time, so favorites, watch history and
  settings are kept in `UserDefaults` there.

## Credits

- The CCloud Android app by Hossein Pira ([code3-dev/CCloud](https://github.com/code3-dev/CCloud), MIT).
- [VLCKit](https://code.videolan.org/videolan/VLCKit) by VideoLAN (LGPL 2.1), via
  [vlckit-spm](https://github.com/tylerjonesio/vlckit-spm).
- [Vazirmatn](https://github.com/rastikerdar/vazirmatn) font by Saber Rastikerdar (SIL Open Font License 1.1).
