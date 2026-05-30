import SwiftUI

@Observable
final class RecentlyPlayedViewModel {
    var items: [PlayHistoryItem] = []
    var isLoading = false
    var error: String?

    private let api = SpotifyAPIService.shared

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await api.fetchRecentlyPlayed(limit: 50)
            items = response.items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        items = []
        await load()
    }
}

struct RecentlyPlayedView: View {
    @State private var viewModel = RecentlyPlayedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading history…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.items.isEmpty {
                    ContentUnavailableView(
                        "Could not load history",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List(viewModel.items) { item in
                        RecentTrackRow(item: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.refresh() }
                }
            }
            .navigationTitle("Recently Played")
            .toolbar {
                if viewModel.isLoading && !viewModel.items.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }
}

#Preview {
    RecentlyPlayedView()
}
