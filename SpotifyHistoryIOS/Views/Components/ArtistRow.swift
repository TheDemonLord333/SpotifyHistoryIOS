import SwiftUI

struct ArtistRow: View {
    let artist: SpotifyArtist
    var index: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let index {
                Text("\(index)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
            }

            ArtistAsyncImage(url: artist.thumbnailURL, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(artist.genreList)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let popularity = artist.popularity {
                PopularityBadge(value: popularity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PopularityBadge: View {
    let value: Int

    private var color: Color {
        switch value {
        case 80...: .green
        case 60..<80: .yellow
        default: .orange
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.caption2)
            Text("\(value)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
    }
}
