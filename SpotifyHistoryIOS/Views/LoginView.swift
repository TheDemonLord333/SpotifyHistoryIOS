import SwiftUI

struct LoginView: View {
    @Environment(SpotifyAuthManager.self) private var auth

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo & Title
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.spotifyGreen)
                            .frame(width: 100, height: 100)
                        Image(systemName: "waveform")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.black)
                    }

                    VStack(spacing: 8) {
                        Text("Spotify History")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Text("Your personal listening insights")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Features list
                VStack(spacing: 16) {
                    FeatureRow(icon: "clock.fill", title: "Recently Played",
                               subtitle: "See your last 50 songs")
                    FeatureRow(icon: "chart.bar.fill", title: "Top Tracks",
                               subtitle: "Your most-played songs across all time")
                    FeatureRow(icon: "person.fill", title: "Top Artists",
                               subtitle: "Discover who you listen to most")
                }
                .padding(.horizontal, 32)

                Spacer()

                // Login Button
                VStack(spacing: 16) {
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        Task { await auth.login() }
                    } label: {
                        HStack(spacing: 10) {
                            if auth.isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(auth.isLoading ? "Connecting…" : "Connect with Spotify")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.spotifyGreen)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                    }
                    .disabled(auth.isLoading)
                    .padding(.horizontal, 32)

                    Text("You'll be redirected to Spotify to authorize the app.\nNo passwords are stored.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.spotifyGreen)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
    }
}

extension Color {
    static let spotifyGreen = Color(red: 0.118, green: 0.839, blue: 0.384)
    static let spotifyBlack = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let spotifyDarkGray = Color(red: 0.118, green: 0.118, blue: 0.118)
}

#Preview {
    LoginView()
        .environment(SpotifyAuthManager.shared)
}
