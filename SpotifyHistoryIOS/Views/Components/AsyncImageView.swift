import SwiftUI

struct SpotifyAsyncImage: View {
    let url: URL?
    var cornerRadius: CGFloat = 6
    var size: CGFloat? = nil

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholderView
                    .overlay(ProgressView().tint(.gray))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderView
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
    }
}

struct ArtistAsyncImage: View {
    let url: URL?
    var size: CGFloat = 56

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Circle().fill(Color(.systemGray5))
                    .overlay(ProgressView().tint(.gray))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            case .failure:
                Circle().fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                Circle().fill(Color(.systemGray5))
            }
        }
        .frame(width: size, height: size)
    }
}
