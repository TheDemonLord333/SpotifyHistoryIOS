//
//  SpotifyHistoryIOSApp.swift
//  SpotifyHistoryIOS
//
//  Created by David Martens on 30.05.26.
//

import SwiftUI

@main
struct SpotifyHistoryIOSApp: App {
    @State private var auth = SpotifyAuthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
    }
}
