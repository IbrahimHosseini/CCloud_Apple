@testable import CCloudDomain
import Foundation
import Testing

@Suite("Source selection")
struct SourceSelectionTests {
    private func source(_ id: Int, _ quality: String) -> MediaSource {
        MediaSource(id: id, quality: quality, format: "mkv", url: URL(string: "https://cdn.example.com/\(id).mkv")!)
    }

    @Test(arguments: [
        ("تیزر", true),
        ("Trailer 1080", true),
        ("480 زیرنویس", false),
        ("1080p", false),
    ])
    func trailerDetection(quality: String, isTrailer: Bool) {
        #expect(source(1, quality).isTrailer == isTrailer)
    }

    @Test(arguments: [
        ("1080 زیرنویس", 1080),
        ("720p x265", 720),
        ("4K HDR", 2160),
        ("دوبله", nil),
        ("5.1 Audio", nil),
    ] as [(String, Int?)])
    func resolutionParsing(quality: String, resolution: Int?) {
        #expect(source(1, quality).resolution == resolution)
    }

    @Test func playPrefersTheSharpestNonTrailer() {
        let sources = [source(1, "تیزر"), source(2, "480 زیرنویس"), source(3, "1080 زیرنویس"), source(4, "720 زیرنویس")]
        #expect(sources.preferredForPlayback?.id == 3)
    }

    @Test func playFallsBackSensibly() {
        #expect([source(1, "تیزر")].preferredForPlayback?.id == 1)
        #expect([source(1, "دوبله"), source(2, "زیرنویس")].preferredForPlayback?.id == 1)
        #expect([MediaSource]().preferredForPlayback == nil)
    }

    @Test func trailerEpisodesAreRecognized() {
        let trailer = Episode(id: 1, number: 1, title: "تیزر", overview: "", duration: nil, imageURL: nil, sources: [source(1, "720")])
        let episode = Episode(id: 2, number: 2, title: "قسمت 1", overview: "", duration: nil, imageURL: nil, sources: [source(2, "720")])
        #expect(trailer.isTrailer)
        #expect(!episode.isTrailer)
    }
}
