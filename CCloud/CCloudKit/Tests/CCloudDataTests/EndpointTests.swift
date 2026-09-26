@testable import CCloudData
import CCloudDomain
import Foundation
import Testing

@Suite("Endpoints")
struct EndpointTests {
    let host = URL(string: "https://example.com")!
    let key = "KEY"

    // The same paths the Android app requests.
    @Test(arguments: [
        (Endpoint.movies(genreID: 0, sort: .recentlyAdded, page: 0), "https://example.com/api/movie/by/filtres/0/created/0/KEY"),
        (.movies(genreID: 12, sort: .imdbRating, page: 3), "https://example.com/api/movie/by/filtres/12/imdb/3/KEY"),
        (.series(genreID: 0, sort: .releaseYear, page: 1), "https://example.com/api/serie/by/filtres/0/year/1/KEY"),
        (.countryTitles(countryID: 7, sort: .recentlyAdded, page: 2), "https://example.com/api/poster/by/filtres/0/7/created/2/KEY"),
        (.seasons(seriesID: 42), "https://example.com/api/season/by/serie/42/KEY/"),
        (.genres, "https://example.com/api/genre/all/KEY"),
        (.countries, "https://example.com/api/country/all/KEY/"),
    ])
    func paths(endpoint: Endpoint, expected: String) {
        #expect(endpoint.url(host: host, apiKey: key)?.absoluteString == expected)
    }

    @Test func searchQueriesArePercentEncodedAsOnePathSegment() {
        let url = Endpoint.search(query: "star wars/ماتریکس?").url(host: host, apiKey: key)
        #expect(url?.absoluteString == "https://example.com/api/search/star%20wars%2F%D9%85%D8%A7%D8%AA%D8%B1%DB%8C%DA%A9%D8%B3%3F/KEY/")
    }
}
