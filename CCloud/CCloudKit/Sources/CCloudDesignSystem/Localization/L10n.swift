import CCloudDomain
import Foundation

// Every user-facing string, typed. Keys are semantic ("tab.series" vs "kind.series") because
// Persian needs different words where English reuses one. Translations live in
// Resources/Localizable.xcstrings (English and Persian).

public enum L10n {
    public enum Tab {
        public static var movies: String { String(localized: "tab.movies", defaultValue: "Movies", bundle: .module) }
        public static var series: String { String(localized: "tab.series", defaultValue: "Series", bundle: .module) }
        public static var search: String { String(localized: "tab.search", defaultValue: "Search", bundle: .module) }
        public static var favorites: String { String(localized: "tab.favorites", defaultValue: "Favorites", bundle: .module) }
        public static var settings: String { String(localized: "tab.settings", defaultValue: "Settings", bundle: .module) }
        public static var browse: String { String(localized: "tab.browse", defaultValue: "Browse", bundle: .module) }
        public static var library: String { String(localized: "tab.library", defaultValue: "Library", bundle: .module) }
    }

    public enum Common {
        public static var retry: String { String(localized: "common.retry", defaultValue: "Try Again", bundle: .module) }
        public static var cancel: String { String(localized: "common.cancel", defaultValue: "Cancel", bundle: .module) }
        public static var done: String { String(localized: "common.done", defaultValue: "Done", bundle: .module) }
        public static var save: String { String(localized: "common.save", defaultValue: "Save", bundle: .module) }
        public static var delete: String { String(localized: "common.delete", defaultValue: "Delete", bundle: .module) }
        public static var ok: String { String(localized: "common.ok", defaultValue: "OK", bundle: .module) }
        public static var create: String { String(localized: "common.create", defaultValue: "Create", bundle: .module) }
        public static var rename: String { String(localized: "common.rename", defaultValue: "Rename", bundle: .module) }
        public static var refresh: String { String(localized: "common.refresh", defaultValue: "Refresh", bundle: .module) }
        public static var loading: String { String(localized: "common.loading", defaultValue: "Loading…", bundle: .module) }
        public static var more: String { String(localized: "common.more", defaultValue: "More", bundle: .module) }
        public static var showMore: String { String(localized: "common.showMore", defaultValue: "Show More", bundle: .module) }
        public static var showLess: String { String(localized: "common.showLess", defaultValue: "Show Less", bundle: .module) }
        public static var untitled: String { String(localized: "common.untitled", defaultValue: "Untitled", bundle: .module) }
    }

    public enum Kind {
        public static var movie: String { String(localized: "kind.movie", defaultValue: "Movie", bundle: .module) }
        public static var series: String { String(localized: "kind.series", defaultValue: "Series", bundle: .module) }

        public static func name(_ kind: MediaKind) -> String {
            switch kind {
            case .movie: movie
            case .series: series
            }
        }
    }

    public enum Catalog {
        public static var allGenres: String { String(localized: "catalog.allGenres", defaultValue: "All Genres", bundle: .module) }
        public static var genre: String { String(localized: "catalog.genre", defaultValue: "Genre", bundle: .module) }
        public static var sortBy: String { String(localized: "catalog.sortBy", defaultValue: "Sort By", bundle: .module) }
        public static var filter: String { String(localized: "catalog.filter", defaultValue: "Filter", bundle: .module) }
        public static var loadMoreFailed: String { String(localized: "catalog.loadMoreFailed", defaultValue: "Couldn't load more titles.", bundle: .module) }
        public static var refreshFailed: String { String(localized: "catalog.refreshFailed", defaultValue: "Couldn't refresh. Showing earlier results.", bundle: .module) }
        public static var emptyTitle: String { String(localized: "catalog.emptyTitle", defaultValue: "No Titles", bundle: .module) }
        public static var emptyMessage: String { String(localized: "catalog.emptyMessage", defaultValue: "There's nothing here yet. Try another genre.", bundle: .module) }
        public static var countryEmptyMessage: String { String(localized: "catalog.countryEmptyMessage", defaultValue: "There are no titles from this country yet.", bundle: .module) }

        public static func sortOrder(_ order: CatalogSortOrder) -> String {
            switch order {
            case .recentlyAdded: String(localized: "sort.recentlyAdded", defaultValue: "Recently Added", bundle: .module)
            case .releaseYear: String(localized: "sort.releaseYear", defaultValue: "Release Year", bundle: .module)
            case .imdbRating: String(localized: "sort.imdbRating", defaultValue: "IMDb Rating", bundle: .module)
            }
        }
    }

    public enum Detail {
        public static var play: String { String(localized: "detail.play", defaultValue: "Play", bundle: .module) }
        public static var favorite: String { String(localized: "detail.favorite", defaultValue: "Favorite", bundle: .module) }
        public static var addToFavorites: String { String(localized: "detail.addToFavorites", defaultValue: "Add to Favorites", bundle: .module) }
        public static var removeFromFavorites: String { String(localized: "detail.removeFromFavorites", defaultValue: "Remove from Favorites", bundle: .module) }
        public static var addToPlaylist: String { String(localized: "detail.addToPlaylist", defaultValue: "Add to Playlist…", bundle: .module) }
        public static var qualities: String { String(localized: "detail.qualities", defaultValue: "Qualities", bundle: .module) }
        public static var genres: String { String(localized: "detail.genres", defaultValue: "Genres", bundle: .module) }
        public static var overview: String { String(localized: "detail.overview", defaultValue: "Overview", bundle: .module) }
        public static var countries: String { String(localized: "detail.countries", defaultValue: "Countries", bundle: .module) }
        public static var seasons: String { String(localized: "detail.seasons", defaultValue: "Seasons", bundle: .module) }
        public static var season: String { String(localized: "detail.season", defaultValue: "Season", bundle: .module) }
        public static var episodes: String { String(localized: "detail.episodes", defaultValue: "Episodes", bundle: .module) }
        public static var watched: String { String(localized: "detail.watched", defaultValue: "Watched", bundle: .module) }
        public static var markWatched: String { String(localized: "detail.markWatched", defaultValue: "Mark as Watched", bundle: .module) }
        public static var markUnwatched: String { String(localized: "detail.markUnwatched", defaultValue: "Mark as Unwatched", bundle: .module) }
        public static var noSourcesTitle: String { String(localized: "detail.noSourcesTitle", defaultValue: "Not Available", bundle: .module) }
        public static var noSourcesMessage: String { String(localized: "detail.noSourcesMessage", defaultValue: "This title has no playable files yet.", bundle: .module) }
        public static var noSeasonsTitle: String { String(localized: "detail.noSeasonsTitle", defaultValue: "No Episodes", bundle: .module) }
        public static var noSeasonsMessage: String { String(localized: "detail.noSeasonsMessage", defaultValue: "This series has no episodes yet.", bundle: .module) }
        public static var seasonsFailed: String { String(localized: "detail.seasonsFailed", defaultValue: "Couldn't load the episodes.", bundle: .module) }
        public static var imdb: String { String(localized: "detail.imdb", defaultValue: "IMDb", bundle: .module) }
        public static var chooseQuality: String { String(localized: "detail.chooseQuality", defaultValue: "Choose Quality", bundle: .module) }

        public static func seasonNumber(_ number: Int) -> String {
            String(localized: "detail.seasonNumber", defaultValue: "Season \(number)", bundle: .module)
        }

        public static func episodeNumber(_ number: Int) -> String {
            String(localized: "detail.episodeNumber", defaultValue: "Episode \(number)", bundle: .module)
        }

        /// "S1 · E3"
        public static func episodeCode(season: Int, episode: Int) -> String {
            String(localized: "detail.episodeCode", defaultValue: "S\(season) · E\(episode)", bundle: .module)
        }

        public static func playEpisode(season: Int, episode: Int) -> String {
            String(localized: "detail.playEpisode", defaultValue: "Play S\(season) · E\(episode)", bundle: .module)
        }

        public static func playQuality(_ quality: String) -> String {
            String(localized: "detail.playQuality", defaultValue: "Play \(quality)", bundle: .module)
        }

        public static func qualityCount(_ count: Int) -> String {
            String(localized: "detail.qualityCount", defaultValue: "\(count) qualities", bundle: .module)
        }

        public static func imdbRating(_ rating: String) -> String {
            String(localized: "detail.imdbRating", defaultValue: "IMDb rating \(rating)", bundle: .module)
        }
    }

    public enum Actions {
        public static var openIn: String { String(localized: "actions.openIn", defaultValue: "Open In", bundle: .module) }
        public static var openInVLC: String { String(localized: "actions.openInVLC", defaultValue: "Open in VLC", bundle: .module) }
        public static var openInInfuse: String { String(localized: "actions.openInInfuse", defaultValue: "Open in Infuse", bundle: .module) }
        public static var downloadInBrowser: String { String(localized: "actions.downloadInBrowser", defaultValue: "Download in Browser", bundle: .module) }
        public static var copyLink: String { String(localized: "actions.copyLink", defaultValue: "Copy Link", bundle: .module) }
        public static var copyImageLink: String { String(localized: "actions.copyImageLink", defaultValue: "Copy Artwork Link", bundle: .module) }
        public static var share: String { String(localized: "actions.share", defaultValue: "Share", bundle: .module) }
        public static var moreOptions: String { String(localized: "actions.moreOptions", defaultValue: "More Options", bundle: .module) }

        public static func appNotInstalledTitle(_ app: String) -> String {
            String(localized: "actions.appNotInstalledTitle", defaultValue: "\(app) Isn't Installed", bundle: .module)
        }

        public static func appNotInstalledMessage(_ app: String) -> String {
            String(localized: "actions.appNotInstalledMessage", defaultValue: "Install \(app) to open videos with it.", bundle: .module)
        }
    }

    public enum Favorites {
        public static var allFavorites: String { String(localized: "favorites.all", defaultValue: "All Favorites", bundle: .module) }
        public static var playlists: String { String(localized: "favorites.playlists", defaultValue: "Playlists", bundle: .module) }
        public static var newPlaylist: String { String(localized: "favorites.newPlaylist", defaultValue: "New Playlist", bundle: .module) }
        public static var newPlaylistEllipsis: String { String(localized: "favorites.newPlaylistEllipsis", defaultValue: "New Playlist…", bundle: .module) }
        public static var playlistName: String { String(localized: "favorites.playlistName", defaultValue: "Playlist Name", bundle: .module) }
        public static var renamePlaylist: String { String(localized: "favorites.renamePlaylist", defaultValue: "Rename Playlist", bundle: .module) }
        public static var renameEllipsis: String { String(localized: "favorites.renameEllipsis", defaultValue: "Rename…", bundle: .module) }
        public static var deletePlaylist: String { String(localized: "favorites.deletePlaylist", defaultValue: "Delete Playlist", bundle: .module) }
        public static var deletePlaylistQuestion: String { String(localized: "favorites.deletePlaylistQuestion", defaultValue: "Delete Playlist?", bundle: .module) }
        public static var editPlaylists: String { String(localized: "favorites.editPlaylists", defaultValue: "Playlists…", bundle: .module) }
        public static var removeFromPlaylist: String { String(localized: "favorites.removeFromPlaylist", defaultValue: "Remove from Playlist", bundle: .module) }
        public static var removeAll: String { String(localized: "favorites.removeAll", defaultValue: "Remove All Favorites", bundle: .module) }
        public static var removeAllQuestion: String { String(localized: "favorites.removeAllQuestion", defaultValue: "Remove All Favorites?", bundle: .module) }
        public static var removeAllMessage: String { String(localized: "favorites.removeAllMessage", defaultValue: "Every favorite will be removed and your playlists will be emptied. This can't be undone.", bundle: .module) }
        public static var removeAllConfirm: String { String(localized: "favorites.removeAllConfirm", defaultValue: "Remove All", bundle: .module) }
        public static var emptyTitle: String { String(localized: "favorites.emptyTitle", defaultValue: "No Favorites", bundle: .module) }
        public static var emptyMessage: String { String(localized: "favorites.emptyMessage", defaultValue: "Use the heart on a movie or series page to save it here.", bundle: .module) }
        public static var emptyPlaylistTitle: String { String(localized: "favorites.emptyPlaylistTitle", defaultValue: "Empty Playlist", bundle: .module) }
        public static var noPlaylistsMessage: String { String(localized: "favorites.noPlaylistsMessage", defaultValue: "Create a playlist to group your favorites.", bundle: .module) }
        public static var choosePlaylists: String { String(localized: "favorites.choosePlaylists", defaultValue: "Choose Playlists", bundle: .module) }

        public static func deletePlaylistMessage(_ name: String) -> String {
            String(localized: "favorites.deletePlaylistMessage", defaultValue: "“\(name)” will be deleted. Its titles stay in your favorites.", bundle: .module)
        }

        public static func emptyPlaylistMessage(_ name: String) -> String {
            String(localized: "favorites.emptyPlaylistMessage", defaultValue: "Add titles to “\(name)” from their page or from All Favorites.", bundle: .module)
        }

        public static func titleCount(_ count: Int) -> String {
            String(localized: "favorites.titleCount", defaultValue: "\(count) titles", bundle: .module)
        }

        public static func error(_ error: PlaylistError) -> String {
            switch error {
            case .emptyName: String(localized: "playlistError.emptyName", defaultValue: "Enter a name for the playlist.", bundle: .module)
            case .duplicateName: String(localized: "playlistError.duplicateName", defaultValue: "A playlist with this name already exists.", bundle: .module)
            case .notFound: String(localized: "playlistError.notFound", defaultValue: "This playlist no longer exists.", bundle: .module)
            }
        }
    }

    public enum Search {
        public static var prompt: String { String(localized: "search.prompt", defaultValue: "Movies and Series", bundle: .module) }
        public static var browseByCountry: String { String(localized: "search.browseByCountry", defaultValue: "Browse by Country", bundle: .module) }
        public static var startTitle: String { String(localized: "search.startTitle", defaultValue: "Search Movies and Series", bundle: .module) }
        public static var startMessage: String { String(localized: "search.startMessage", defaultValue: "Type a title, then search.", bundle: .module) }
        public static var countriesFailed: String { String(localized: "search.countriesFailed", defaultValue: "Couldn't load the countries.", bundle: .module) }
        public static var results: String { String(localized: "search.results", defaultValue: "Results", bundle: .module) }

        public static func noResults(_ query: String) -> String {
            String(localized: "search.noResults", defaultValue: "No results for “\(query)”.", bundle: .module)
        }
    }

    public enum Settings {
        public static var appearance: String { String(localized: "settings.appearance", defaultValue: "Appearance", bundle: .module) }
        public static var theme: String { String(localized: "settings.theme", defaultValue: "Theme", bundle: .module) }
        public static var accentColor: String { String(localized: "settings.accentColor", defaultValue: "Accent Color", bundle: .module) }
        public static var font: String { String(localized: "settings.font", defaultValue: "Font", bundle: .module) }
        public static var player: String { String(localized: "settings.player", defaultValue: "Player", bundle: .module) }
        public static var seekInterval: String { String(localized: "settings.seekInterval", defaultValue: "Skip Interval", bundle: .module) }
        public static var seekIntervalFooter: String { String(localized: "settings.seekIntervalFooter", defaultValue: "How far the skip buttons and arrow keys jump in the VLC player.", bundle: .module) }
        public static var subtitles: String { String(localized: "settings.subtitles", defaultValue: "Subtitles", bundle: .module) }
        public static var textColor: String { String(localized: "settings.textColor", defaultValue: "Text Color", bundle: .module) }
        public static var background: String { String(localized: "settings.background", defaultValue: "Background", bundle: .module) }
        public static var textSize: String { String(localized: "settings.textSize", defaultValue: "Text Size", bundle: .module) }
        public static var subtitlePreview: String { String(localized: "settings.subtitlePreview", defaultValue: "This is how subtitles will look.", bundle: .module) }
        public static var storage: String { String(localized: "settings.storage", defaultValue: "Storage", bundle: .module) }
        public static var watchedEpisodes: String { String(localized: "settings.watchedEpisodes", defaultValue: "Watched Episodes", bundle: .module) }
        public static var clearWatched: String { String(localized: "settings.clearWatched", defaultValue: "Clear Watched Episodes", bundle: .module) }
        public static var clearWatchedQuestion: String { String(localized: "settings.clearWatchedQuestion", defaultValue: "Clear Watched Episodes?", bundle: .module) }
        public static var clearWatchedMessage: String { String(localized: "settings.clearWatchedMessage", defaultValue: "All watched marks will be removed. This can't be undone.", bundle: .module) }
        public static var clear: String { String(localized: "settings.clear", defaultValue: "Clear", bundle: .module) }
        public static var reset: String { String(localized: "settings.reset", defaultValue: "Reset to Defaults", bundle: .module) }
        public static var resetQuestion: String { String(localized: "settings.resetQuestion", defaultValue: "Reset All Settings?", bundle: .module) }
        public static var resetMessage: String { String(localized: "settings.resetMessage", defaultValue: "Appearance, player and subtitle settings go back to their defaults. Favorites and watched episodes are kept.", bundle: .module) }
        public static var resetConfirm: String { String(localized: "settings.resetConfirm", defaultValue: "Reset", bundle: .module) }
        public static var general: String { String(localized: "settings.general", defaultValue: "General", bundle: .module) }
        public static var about: String { String(localized: "settings.about", defaultValue: "About", bundle: .module) }
        public static var language: String { String(localized: "settings.language", defaultValue: "Language", bundle: .module) }
        public static var languageFooter: String { String(localized: "settings.languageFooter", defaultValue: "CCloud uses your device's language. You can choose another one for CCloud in the system Settings.", bundle: .module) }
        public static var openSystemSettings: String { String(localized: "settings.openSystemSettings", defaultValue: "Open System Settings", bundle: .module) }

        public static func watchedEpisodeCount(_ count: Int) -> String {
            String(localized: "settings.watchedEpisodeCount", defaultValue: "\(count) episodes", bundle: .module)
        }

        public static func seconds(_ seconds: Int) -> String {
            String(localized: "settings.seconds", defaultValue: "\(seconds) seconds", bundle: .module)
        }

        public static func appearance(_ appearance: Appearance) -> String {
            switch appearance {
            case .system: String(localized: "appearance.system", defaultValue: "System", bundle: .module)
            case .light: String(localized: "appearance.light", defaultValue: "Light", bundle: .module)
            case .dark: String(localized: "appearance.dark", defaultValue: "Dark", bundle: .module)
            }
        }

        public static func font(_ font: FontChoice) -> String {
            switch font {
            case .system: String(localized: "font.system", defaultValue: "System Font", bundle: .module)
            case .vazirmatn: String(localized: "font.vazirmatn", defaultValue: "Vazirmatn", bundle: .module)
            }
        }

        public static func accentColor(_ option: AccentColorOption) -> String {
            switch option {
            case .system: String(localized: "color.default", defaultValue: "Default", bundle: .module)
            case .purple: String(localized: "color.purple", defaultValue: "Purple", bundle: .module)
            case .teal: String(localized: "color.teal", defaultValue: "Teal", bundle: .module)
            case .red: red
            case .pink: String(localized: "color.pink", defaultValue: "Pink", bundle: .module)
            case .purpleGrey: String(localized: "color.purpleGrey", defaultValue: "Purple Grey", bundle: .module)
            case .green: green
            case .blue: blue
            case .yellow: yellow
            }
        }

        public static func subtitleColor(_ color: SubtitleTextColor) -> String {
            switch color {
            case .yellow: yellow
            case .white: white
            case .black: black
            case .red: red
            case .blue: blue
            case .green: green
            }
        }

        public static func subtitleBackground(_ background: SubtitleBackground) -> String {
            switch background {
            case .none: String(localized: "color.none", defaultValue: "None", bundle: .module)
            case .glass: String(localized: "color.glass", defaultValue: "Glass", bundle: .module)
            case .white: white
            case .black: black
            case .red: red
            case .blue: blue
            case .green: green
            }
        }

        private static var red: String { String(localized: "color.red", defaultValue: "Red", bundle: .module) }
        private static var green: String { String(localized: "color.green", defaultValue: "Green", bundle: .module) }
        private static var blue: String { String(localized: "color.blue", defaultValue: "Blue", bundle: .module) }
        private static var yellow: String { String(localized: "color.yellow", defaultValue: "Yellow", bundle: .module) }
        private static var white: String { String(localized: "color.white", defaultValue: "White", bundle: .module) }
        private static var black: String { String(localized: "color.black", defaultValue: "Black", bundle: .module) }
    }

    public enum About {
        public static var title: String { String(localized: "about.title", defaultValue: "About CCloud", bundle: .module) }
        public static var tagline: String { String(localized: "about.tagline", defaultValue: "Movies and series on iPhone, iPad, Mac and Apple TV.", bundle: .module) }
        public static var sourceCode: String { String(localized: "about.sourceCode", defaultValue: "Source Code", bundle: .module) }
        public static var androidProject: String { String(localized: "about.androidProject", defaultValue: "CCloud for Android", bundle: .module) }
        public static var credits: String { String(localized: "about.credits", defaultValue: "Credits", bundle: .module) }
        public static var androidCredit: String { String(localized: "about.androidCredit", defaultValue: "Based on the CCloud Android app by Hossein Pira.", bundle: .module) }
        public static var fontCredit: String { String(localized: "about.fontCredit", defaultValue: "Vazirmatn font by Saber Rastikerdar (SIL Open Font License).", bundle: .module) }
        public static var vlcCredit: String { String(localized: "about.vlcCredit", defaultValue: "Playback of more formats by VLCKit from VideoLAN (LGPL).", bundle: .module) }

        public static func version(_ version: String, build: String) -> String {
            String(localized: "about.version", defaultValue: "Version \(version) (\(build))", bundle: .module)
        }
    }

    public enum Player {
        public static var close: String { String(localized: "player.close", defaultValue: "Close", bundle: .module) }
        public static var play: String { String(localized: "player.play", defaultValue: "Play", bundle: .module) }
        public static var pause: String { String(localized: "player.pause", defaultValue: "Pause", bundle: .module) }
        public static var speed: String { String(localized: "player.speed", defaultValue: "Playback Speed", bundle: .module) }
        public static var audio: String { String(localized: "player.audio", defaultValue: "Audio", bundle: .module) }
        public static var subtitles: String { String(localized: "player.subtitles", defaultValue: "Subtitles", bundle: .module) }
        public static var off: String { String(localized: "player.off", defaultValue: "Off", bundle: .module) }
        public static var buffering: String { String(localized: "player.buffering", defaultValue: "Buffering…", bundle: .module) }
        public static var failedTitle: String { String(localized: "player.failedTitle", defaultValue: "Can't Play This Video", bundle: .module) }
        public static var failedMessage: String { String(localized: "player.failedMessage", defaultValue: "The file may be unavailable, or in a format this device can't play.", bundle: .module) }
        public static var fullScreen: String { String(localized: "player.fullScreen", defaultValue: "Full Screen", bundle: .module) }
        public static var position: String { String(localized: "player.position", defaultValue: "Position", bundle: .module) }

        public static func skipForward(_ seconds: Int) -> String {
            String(localized: "player.skipForward", defaultValue: "Skip Forward \(seconds) Seconds", bundle: .module)
        }

        public static func skipBackward(_ seconds: Int) -> String {
            String(localized: "player.skipBackward", defaultValue: "Skip Back \(seconds) Seconds", bundle: .module)
        }

        public static func track(_ number: Int) -> String {
            String(localized: "player.track", defaultValue: "Track \(number)", bundle: .module)
        }
    }

    public enum Errors {
        public static func title(_ error: DomainError) -> String {
            switch error {
            case .offline: String(localized: "error.offline.title", defaultValue: "You're Offline", bundle: .module)
            case .serverUnreachable: String(localized: "error.unreachable.title", defaultValue: "Can't Reach the Server", bundle: .module)
            case .timedOut: String(localized: "error.timedOut.title", defaultValue: "The Server Is Taking Too Long", bundle: .module)
            case .server: String(localized: "error.server.title", defaultValue: "Server Error", bundle: .module)
            case .invalidResponse: String(localized: "error.invalidResponse.title", defaultValue: "Unexpected Response", bundle: .module)
            case .unknown: String(localized: "error.unknown.title", defaultValue: "Something Went Wrong", bundle: .module)
            }
        }

        public static func message(_ error: DomainError) -> String {
            switch error {
            case .offline:
                String(localized: "error.offline.message", defaultValue: "Check your internet connection and try again.", bundle: .module)
            case .serverUnreachable:
                String(localized: "error.unreachable.message", defaultValue: "The CCloud servers couldn't be reached. They may be unavailable on your network.", bundle: .module)
            case .timedOut:
                String(localized: "error.timedOut.message", defaultValue: "Try again in a moment.", bundle: .module)
            case .server(let statusCode):
                String(localized: "error.server.message", defaultValue: "The server returned an error (\(statusCode)). Try again later.", bundle: .module)
            case .invalidResponse:
                String(localized: "error.invalidResponse.message", defaultValue: "The server sent data CCloud couldn't read.", bundle: .module)
            case .unknown:
                String(localized: "error.unknown.message", defaultValue: "Please try again.", bundle: .module)
            }
        }
    }
}
