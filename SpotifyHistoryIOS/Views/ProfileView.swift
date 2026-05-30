import SwiftUI

@Observable
final class ProfileViewModel {
    var user: SpotifyUser?
    var isLoading = false
    var error: String?

    private let api = SpotifyAPIService.shared

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            user = try await api.fetchCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct ProfileView: View {
    @Environment(SpotifyAuthManager.self) private var auth
    @State private var viewModel = ProfileViewModel()
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.user == nil {
                    ProgressView("Loading profile…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.user == nil {
                    ContentUnavailableView(
                        "Could not load profile",
                        systemImage: "person.slash",
                        description: Text(error)
                    )
                } else if let user = viewModel.user {
                    List {
                        Section {
                            HStack(spacing: 16) {
                                ArtistAsyncImage(url: user.avatarURL, size: 72)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName ?? user.id)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    if let email = user.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if user.isPremium {
                                        Label("Spotify Premium", systemImage: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundStyle(Color.spotifyGreen)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        Section("Stats") {
                            if let followers = user.followers {
                                InfoRow(label: "Followers", value: followers.total.formatted())
                            }
                            if let country = user.country {
                                InfoRow(label: "Country", value: country)
                            }
                            InfoRow(label: "Account", value: user.product?.capitalized ?? "Free")
                            InfoRow(label: "User ID", value: user.id)
                        }

                        Section("About") {
                            InfoRow(label: "App Version", value: Bundle.main.appVersion)
                            InfoRow(label: "API", value: "Spotify Web API v1")
                        }

                        Section {
                            Button(role: .destructive) {
                                showLogoutConfirm = true
                            } label: {
                                Label("Disconnect from Spotify", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
                    .refreshable { await viewModel.load() }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Disconnect from Spotify?",
                isPresented: $showLogoutConfirm,
                titleVisibility: .visible
            ) {
                Button("Disconnect", role: .destructive) { auth.logout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your Spotify tokens will be removed from this device.")
            }
        }
        .task { await viewModel.load() }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    ProfileView()
        .environment(SpotifyAuthManager.shared)
}
