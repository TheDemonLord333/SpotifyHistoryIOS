import SwiftUI

struct TrackRow: View {
    let track: SpotifyTrack
    var index: Int? = nil
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let index {
                Text("\(index)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
            }

            SpotifyAsyncImage(url: track.albumArtURL, cornerRadius: 6, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle ?? track.artistNames)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(track.durationFormatted)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct RecentTrackRow: View {
    let item: PlayHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            SpotifyAsyncImage(url: item.track.albumArtURL, cornerRadius: 6, size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(item.track.artistNames)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.playedAtFormatted)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
