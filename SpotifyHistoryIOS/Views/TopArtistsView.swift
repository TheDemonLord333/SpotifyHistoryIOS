import SwiftUI

@Observable
final class TopArtistsViewModel {
    var artists: [SpotifyArtist] = []
    var timeRange: TimeRange = .mediumTerm
    var isLoading = false
    var error: String?

    private let api = SpotifyAPIService.shared

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await api.fetchTopArtists(timeRange: timeRange, limit: 50)
            artists = response.items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func changeTimeRange(_ range: TimeRange) async {
        timeRange = range
        artists = []
        await load()
    }
}

struct TopArtistsView: View {
    @State private var viewModel = TopArtistsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.artists.isEmpty {
                    ProgressView("Loading top artists…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.artists.isEmpty {
                    ContentUnavailableView(
                        "Could not load artists",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List {
                        Section {
                            ForEach(Array(viewModel.artists.enumerated()), id: \.element.id) { index, artist in
                                NavigationLink {
                                    ArtistDetailView(artist: artist)
                                } label: {
                                    ArtistRow(artist: artist, index: index + 1)
                                }
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
            .navigationTitle("Top Artists")
            .toolbar {
                if viewModel.isLoading && !viewModel.artists.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView()
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Artist Detail

struct ArtistDetailView: View {
    let artist: SpotifyArtist

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ArtistAsyncImage(url: artist.imageURL, size: 200)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text(artist.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if let followers = artist.followers {
                        Text("\(followers.total.formatted()) followers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let popularity = artist.popularity {
                        PopularityBadge(value: popularity)
                    }
                }

                if let genres = artist.genres, !genres.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Genres")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FlowLayout(spacing: 8) {
                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    TopArtistsView()
}
