import Foundation

// MARK: - User

struct SpotifyUser: Codable, Identifiable, Sendable {
    let id: String
    let displayName: String?
    let email: String?
    let images: [SpotifyImage]?
    let followers: SpotifyFollowers?
    let country: String?
    let product: String?

    enum CodingKeys: String, CodingKey {
        case id, email, images, followers, country, product
        case displayName = "display_name"
    }

    var avatarURL: URL? {
        images?.first.flatMap { URL(string: $0.url) }
    }

    var isPremium: Bool { product == "premium" }
}

struct SpotifyImage: Codable, Sendable {
    let url: String
    let width: Int?
    let height: Int?
}

struct SpotifyFollowers: Codable, Sendable {
    let total: Int
}

// MARK: - Track

struct SpotifyTrack: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let artists: [SpotifyArtistSimple]
    let album: SpotifyAlbum
    let durationMs: Int
    let popularity: Int?
    let previewUrl: String?
    let externalUrls: SpotifyExternalUrls

    enum CodingKeys: String, CodingKey {
        case id, name, artists, album, popularity
        case durationMs = "duration_ms"
        case previewUrl = "preview_url"
        case externalUrls = "external_urls"
    }

    var durationFormatted: String {
        let totalSeconds = durationMs / 1000
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }

    var albumArtURL: URL? {
        album.images.last.flatMap { URL(string: $0.url) }
    }

    var albumArtLargeURL: URL? {
        album.images.first.flatMap { URL(string: $0.url) }
    }
}

// MARK: - Artist

struct SpotifyArtist: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let genres: [String]?
    let popularity: Int?
    let followers: SpotifyFollowers?
    let externalUrls: SpotifyExternalUrls

    enum CodingKeys: String, CodingKey {
        case id, name, images, genres, popularity, followers
        case externalUrls = "external_urls"
    }

    var imageURL: URL? {
        images?.first.flatMap { URL(string: $0.url) }
    }

    var thumbnailURL: URL? {
        images?.last.flatMap { URL(string: $0.url) }
    }

    var genreList: String {
        genres?.prefix(3).joined(separator: " · ") ?? "No genre info"
    }
}

struct SpotifyArtistSimple: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let externalUrls: SpotifyExternalUrls

    enum CodingKeys: String, CodingKey {
        case id, name
        case externalUrls = "external_urls"
    }
}

// MARK: - Album

struct SpotifyAlbum: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, images
        case releaseDate = "release_date"
    }
}

// MARK: - External URLs

struct SpotifyExternalUrls: Codable, Sendable {
    let spotify: String?
}

// MARK: - Recently Played

struct RecentlyPlayedResponse: Codable, Sendable {
    let items: [PlayHistoryItem]
    let next: String?
    let cursors: Cursors?

    struct Cursors: Codable, Sendable {
        let after: String?
        let before: String?
    }
}

struct PlayHistoryItem: Codable, Identifiable, Sendable {
    let track: SpotifyTrack
    let playedAt: String
    let context: PlayContext?

    var id: String { playedAt + track.id }

    enum CodingKeys: String, CodingKey {
        case track, context
        case playedAt = "played_at"
    }

    var playedAtDate: Date? {
        ISO8601DateFormatter().date(from: playedAt)
    }

    var playedAtFormatted: String {
        guard let date = playedAtDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PlayContext: Codable, Sendable {
    let type: String?
    let uri: String?
}

// MARK: - Top Items Responses

struct TopTracksResponse: Codable, Sendable {
    let items: [SpotifyTrack]
    let total: Int
    let limit: Int
    let offset: Int
}

struct TopArtistsResponse: Codable, Sendable {
    let items: [SpotifyArtist]
    let total: Int
    let limit: Int
    let offset: Int
}

// MARK: - Auth Token

struct SpotifyTokenResponse: Codable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String

    enum CodingKeys: String, CodingKey {
        case tokenType, scope
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Time Range

enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case shortTerm = "short_term"
    case mediumTerm = "medium_term"
    case longTerm = "long_term"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shortTerm: "Last 4 Weeks"
        case .mediumTerm: "Last 6 Months"
        case .longTerm: "All Time"
        }
    }
}

// MARK: - Errors

enum SpotifyError: LocalizedError, Sendable {
    case notAuthenticated
    case authFailed(String)
    case networkError(String)
    case decodingError(String)
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Not authenticated with Spotify"
        case .authFailed(let msg): "Authentication failed: \(msg)"
        case .networkError(let msg): "Network error: \(msg)"
        case .decodingError(let msg): "Data error: \(msg)"
        case .rateLimited: "Too many requests. Please wait a moment."
        case .serverError(let code): "Server error (code \(code))"
        }
    }
}
