import Foundation

@MainActor
final class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    private init() {}

    private let baseURL = "https://api.spotify.com/v1"
    private let auth = SpotifyAuthManager.shared

    // MARK: - Current User

    func fetchCurrentUser() async throws -> SpotifyUser {
        try await get(path: "/me")
    }

    // MARK: - Recently Played

    func fetchRecentlyPlayed(limit: Int = 50) async throws -> RecentlyPlayedResponse {
        try await get(path: "/me/player/recently-played", query: [
            "limit": String(min(limit, 50)),
        ])
    }

    // MARK: - Top Items

    func fetchTopTracks(timeRange: TimeRange = .mediumTerm, limit: Int = 50) async throws -> TopTracksResponse {
        try await get(path: "/me/top/tracks", query: [
            "time_range": timeRange.rawValue,
            "limit": String(min(limit, 50)),
        ])
    }

    func fetchTopArtists(timeRange: TimeRange = .mediumTerm, limit: Int = 50) async throws -> TopArtistsResponse {
        try await get(path: "/me/top/artists", query: [
            "time_range": timeRange.rawValue,
            "limit": String(min(limit, 50)),
        ])
    }

    // MARK: - Generic Request

    private func get<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> T {
        let token = try await auth.getValidToken()

        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else {
            throw SpotifyError.networkError("Invalid URL for \(path)")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SpotifyError.networkError("No HTTP response")
        }

        switch http.statusCode {
        case 200...299:
            break
        case 401:
            throw SpotifyError.notAuthenticated
        case 429:
            throw SpotifyError.rateLimited
        default:
            throw SpotifyError.serverError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SpotifyError.decodingError(error.localizedDescription)
        }
    }
}
