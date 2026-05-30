import SwiftUI

@Observable
final class TopTracksViewModel {
    var tracks: [SpotifyTrack] = []
    var timeRange: TimeRange = .mediumTerm
    var isLoading = false
    var error: String?

    private let api = SpotifyAPIService.shared

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await api.fetchTopTracks(timeRange: timeRange, limit: 50)
            tracks = response.items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func changeTimeRange(_ range: TimeRange) async {
        timeRange = range
        tracks = []
        await load()
    }
}

struct TopTracksView: View {
    @State private var viewModel = TopTracksViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tracks.isEmpty {
                    ProgressView("Loading top tracks…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.tracks.isEmpty {
                    ContentUnavailableView(
                        "Could not load tracks",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List {
                        Section {
                            ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                                TrackRow(track: track, index: index + 1)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        } header: {
                            TimeRangePicker(selected: viewModel.timeRange) { range in
                                Task { await viewModel.changeTimeRange(range) }
                            }
                            .textCase(nil)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await viewModel.changeTimeRange(viewModel.timeRange) }
                }
            }
            .navigationTitle("Top Tracks")
            .toolbar {
                if viewModel.isLoading && !viewModel.tracks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }
}

struct TimeRangePicker: View {
    let selected: TimeRange
    let onSelect: (TimeRange) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        onSelect(range)
                    } label: {
                        Text(range.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selected == range
                                    ? Color.spotifyGreen
                                    : Color(.systemGray5),
                                in: Capsule()
                            )
                            .foregroundStyle(selected == range ? .black : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    TopTracksView()
}
