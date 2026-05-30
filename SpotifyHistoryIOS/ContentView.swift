//
//  ContentView.swift
//  SpotifyHistoryIOS
//
//  Created by David Martens on 30.05.26.
//

import SwiftUI

struct ContentView: View {
    @Environment(SpotifyAuthManager.self) private var auth

    var body: some View {
        if auth.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("History", systemImage: "clock.fill") {
                RecentlyPlayedView()
            }
            Tab("Top Tracks", systemImage: "chart.bar.fill") {
                TopTracksView()
            }
            Tab("Top Artists", systemImage: "person.2.fill") {
                TopArtistsView()
            }
            Tab("Profile", systemImage: "person.circle.fill") {
                ProfileView()
            }
        }
        .tint(Color.spotifyGreen)
    }
}

#Preview {
    ContentView()
        .environment(SpotifyAuthManager.shared)
}
