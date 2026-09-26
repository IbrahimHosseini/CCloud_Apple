import CCloudDomain
import Foundation

public struct RemoteCatalogRepository: CatalogRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func page(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, index: Int) async throws -> [MediaItem] {
        switch feed {
        case .movies(let genreID):
            let list = try await client.get(.movies(genreID: genreID ?? 0, sort: order, page: index), as: LossyList<PosterDTO>.self)
            return list.elements.compactMap { $0.toDomain(kind: .movie) }
        case .series(let genreID):
            let list = try await client.get(.series(genreID: genreID ?? 0, sort: order, page: index), as: LossyList<PosterDTO>.self)
            return list.elements.compactMap { $0.toDomain(kind: .series) }
        case .country(let countryID):
            let list = try await client.get(.countryTitles(countryID: countryID, sort: order, page: index), as: LossyList<PosterDTO>.self)
            return list.elements.compactMap { $0.toDomain() }
        }
    }
}

public struct RemoteSeasonRepository: SeasonRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func seasons(ofSeries seriesID: Int) async throws -> [Season] {
        let list = try await client.get(.seasons(seriesID: seriesID), as: LossyList<SeasonDTO>.self)
        return list.elements.enumerated().map { index, season in season.toDomain(position: index + 1) }
    }
}

public struct RemoteSearchRepository: SearchRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func search(_ query: String) async throws -> [MediaItem] {
        let response = try await client.get(.search(query: query), as: SearchResponseDTO.self)
        return response.posters.compactMap { $0.toDomain() }
    }
}

public struct RemoteGenreRepository: GenreRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func genres() async throws -> [Genre] {
        let list = try await client.get(.genres, as: LossyList<GenreDTO>.self)
        return list.elements.compactMap { $0.toDomain() }
    }
}

public struct RemoteCountryRepository: CountryRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func countries() async throws -> [Country] {
        let list = try await client.get(.countries, as: LossyList<CountryDTO>.self)
        return list.elements.compactMap { $0.toDomain() }
    }
}
