import Foundation
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
final class SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    // MARK: - App Configuration
    // Create an app at https://developer.spotify.com/dashboard
    // Set Redirect URI to: spotifyhistoryios://callback
    static let clientID = "YOUR_CLIENT_ID_HERE"
    static let redirectURI = "spotifyhistoryios://callback"
    static let scopes = [
        "user-read-recently-played",
        "user-top-read",
        "user-read-private",
        "user-read-email",
    ].joined(separator: " ")

    // MARK: - State
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private
    private let keychain = KeychainHelper.shared
    private let accessTokenKey = "spotify_access_token"
    private let refreshTokenKey = "spotify_refresh_token"
    private let expiryKey = "spotify_token_expiry"
    private var codeVerifier = ""
    private var activeSession: ASWebAuthenticationSession?
    private let contextProvider = AuthPresentationContextProvider()

    private init() {
        let token = keychain.read(key: accessTokenKey)
        let expiry = tokenExpiry
        isAuthenticated = token != nil && expiry != nil && expiry! > Date()
    }

    private var tokenExpiry: Date? {
        guard let str = keychain.read(key: expiryKey),
              let ts = Double(str) else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    // MARK: - Public API

    func getValidToken() async throws -> String {
        if let token = keychain.read(key: accessTokenKey),
           let expiry = tokenExpiry, expiry > Date() {
            return token
        }
        if keychain.read(key: refreshTokenKey) != nil {
            try await refreshToken()
            guard let token = keychain.read(key: accessTokenKey) else {
                throw SpotifyError.notAuthenticated
            }
            return token
        }
        throw SpotifyError.notAuthenticated
    }

    func login() async {
        isLoading = true
        errorMessage = nil

        let verifier = makeCodeVerifier()
        codeVerifier = verifier
        let challenge = makeChallenge(from: verifier)
        let state = UUID().uuidString

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            .init(name: "client_id", value: Self.clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: Self.redirectURI),
            .init(name: "scope", value: Self.scopes),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "state", value: state),
        ]

        guard let authURL = components.url else {
            errorMessage = "Could not build authorization URL"
            isLoading = false
            return
        }

        do {
            let callbackURL = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<URL, Error>) in
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "spotifyhistoryios"
                ) { [weak self] url, error in
                    self?.activeSession = nil
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: SpotifyError.authFailed("No callback URL"))
                    }
                }
                session.presentationContextProvider = contextProvider
                session.prefersEphemeralWebBrowserSession = false
                activeSession = session
                session.start()
            }

            guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value
            else {
                let errMsg = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "error" })?.value ?? "unknown"
                throw SpotifyError.authFailed("Callback error: \(errMsg)")
            }

            try await exchangeCode(code)
            isAuthenticated = true

        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User dismissed – not an error
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        keychain.delete(key: accessTokenKey)
        keychain.delete(key: refreshTokenKey)
        keychain.delete(key: expiryKey)
        isAuthenticated = false
        errorMessage = nil
    }

    // MARK: - Token Exchange

    private func exchangeCode(_ code: String) async throws {
        let body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectURI,
            "client_id": Self.clientID,
            "code_verifier": codeVerifier,
        ]
        try await performTokenRequest(body: body)
    }

    private func refreshToken() async throws {
        guard let refresh = keychain.read(key: refreshTokenKey) else {
            logout()
            throw SpotifyError.notAuthenticated
        }
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": Self.clientID,
        ]
        do {
            try await performTokenRequest(body: body)
        } catch {
            logout()
            throw error
        }
    }

    private func performTokenRequest(body: [String: String]) async throws {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // application/x-www-form-urlencoded: percent-encode everything except unreserved chars.
        // Using urlQueryAllowed would leave '+' unencoded, but '+' means space in form bodies.
        let formChars = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: formChars) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SpotifyError.networkError("Invalid response")
        }

        guard http.statusCode == 200 else {
            // Decode Spotify's error JSON  {"error":"...", "error_description":"..."}
            struct SpotifyAPIError: Decodable {
                let error: String
                let errorDescription: String?
                enum CodingKeys: String, CodingKey {
                    case error
                    case errorDescription = "error_description"
                }
            }
            if let apiError = try? JSONDecoder().decode(SpotifyAPIError.self, from: data) {
                throw SpotifyError.authFailed("\(apiError.error): \(apiError.errorDescription ?? "")")
            }
            let rawBody = String(data: data, encoding: .utf8) ?? "(empty)"
            throw SpotifyError.authFailed("HTTP \(http.statusCode) – \(rawBody.prefix(200))")
        }

        do {
            let token = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
            keychain.save(key: accessTokenKey, value: token.accessToken)
            if let refresh = token.refreshToken {
                keychain.save(key: refreshTokenKey, value: refresh)
            }
            let expiry = Date().addingTimeInterval(TimeInterval(token.expiresIn) - 60)
            keychain.save(key: expiryKey, value: String(expiry.timeIntervalSince1970))
        } catch is DecodingError {
            let rawBody = String(data: data, encoding: .utf8) ?? "(empty)"
            throw SpotifyError.authFailed("Unexpected response: \(rawBody.prefix(300))")
        }
    }

    // MARK: - PKCE

    private func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func makeChallenge(from verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8)))
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Presentation Context

private final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {
    // ASWebAuthenticationSession always calls presentationAnchor on the main thread,
    // so MainActor.assumeIsolated is safe here (avoids deadlock from DispatchQueue.main.sync).
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let window = scenes
                .first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: \.isKeyWindow) {
                return window
            }
            if let window = scenes.flatMap(\.windows).first { return window }
            if let scene = scenes.first { return UIWindow(windowScene: scene) }
            return UIWindow()
        }
    }
}
