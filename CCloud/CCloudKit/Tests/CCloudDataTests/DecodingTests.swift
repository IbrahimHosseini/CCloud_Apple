@testable import CCloudData
import CCloudDomain
import Foundation
import Testing

@Suite("Lenient decoding")
struct DecodingTests {
    private func decodeList<T: Decodable>(_ json: String, as type: T.Type) throws -> [T] {
        try JSONDecoder().decode(LossyList<T>.self, from: Data(json.utf8)).elements
    }

    @Test func postersAcceptLooselyTypedFields() throws {
        let json = """
        [{
            "id": "15", "type": "movie", "title": " Inception ", "description": "Dreams",
            "year": "2010", "imdb": "8.8", "rating": 4, "duration": "148 min",
            "image": "https://img.example.com/p 1.jpg", "cover": "",
            "genres": [{"id": 1, "title": "Sci-Fi"}, {"title": "no id"}],
            "sources": [{"id": 3, "quality": "1080p", "type": "mkv", "url": "https://cdn.example.com/a.mkv"}, {"id": 4, "url": ""}],
            "country": [{"id": 2, "title": "USA", "image": "null"}]
        }]
        """
        let item = try #require(try decodeList(json, as: PosterDTO.self).first?.toDomain())

        #expect(item.id == MediaID(kind: .movie, value: 15))
        #expect(item.title == "Inception")
        #expect(item.year == 2010)
        #expect(item.imdbRating == 8.8)
        #expect(item.duration == "148 min")
        #expect(item.posterURL?.absoluteString == "https://img.example.com/p%201.jpg")
        #expect(item.coverURL == nil)
        #expect(item.genres == [Genre(id: 1, title: "Sci-Fi")])
        #expect(item.sources.map(\.id) == [3])
        #expect(item.sources.first?.fileExtension == "mkv")
        #expect(item.countries.first?.imageURL == nil)
    }

    @Test func malformedItemsAreSkippedNotFatal() throws {
        let json = #"[{"id": 1, "type": "movie", "title": "Good"}, "garbage", 42, {"id": 0, "type": "movie"}, {"id": 2, "type": "serie", "title": "Show"}]"#
        let items = try decodeList(json, as: PosterDTO.self).compactMap { $0.toDomain() }
        #expect(items.map(\.id) == [MediaID(kind: .movie, value: 1), MediaID(kind: .series, value: 2)])
    }

    @Test(arguments: [("null", nil), ("N/A", nil), ("", nil), ("  95 min ", "95 min")] as [(String, String?)])
    func unknownDurationsAreDropped(raw: String, expected: String?) {
        #expect(PosterDTO.cleanDuration(raw) == expected)
    }

    @Test func seriesNeverCarryMovieSources() throws {
        let json = #"[{"id": 9, "type": "serie", "title": "Show", "sources": [{"id": 1, "url": "https://x.example.com/a.mp4"}]}]"#
        let item = try #require(try decodeList(json, as: PosterDTO.self).first?.toDomain())
        #expect(item.kind == .series)
        #expect(item.sources.isEmpty)
    }

    @Test func endpointKindOverridesTheTypeField() throws {
        let json = #"[{"id": 9, "type": "", "title": "Unlabeled"}]"#
        let dto = try #require(try decodeList(json, as: PosterDTO.self).first)
        #expect(dto.toDomain() == nil)
        #expect(dto.toDomain(kind: .series)?.kind == .series)
    }

    @Test func seasonsAndEpisodesAreNumbered() throws {
        let json = """
        [{"id": 10, "title": "Season One", "episodes": [
            {"id": 100, "title": "Pilot", "duration": "null", "sources": [{"id": 1, "quality": "720p", "url": "https://x.example.com/1.mp4"}]},
            {"id": 101, "title": null}
        ]}, {"id": 11, "episodes": []}]
        """
        let seasons = try decodeList(json, as: SeasonDTO.self).enumerated().map { $1.toDomain(position: $0 + 1) }
        #expect(seasons.map(\.number) == [1, 2])
        #expect(seasons[0].episodes.map(\.number) == [1, 2])
        #expect(seasons[0].episodes[0].duration == nil)
        #expect(seasons[0].episodes[1].title.isEmpty)
        #expect(seasons[1].title.isEmpty)
    }

    @Test func searchResponsesNeedPosters() throws {
        let ok = try JSONDecoder().decode(SearchResponseDTO.self, from: Data(#"{"posters": [{"id": 1, "type": "movie", "title": "A"}], "channels": []}"#.utf8))
        #expect(ok.posters.count == 1)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SearchResponseDTO.self, from: Data(#"{"error": "bad key"}"#.utf8))
        }
    }
}
