import SwiftUI
import LiveLyricsCore

/// Page plein écran "Now Playing" : grande pochette, titre / artiste / album,
/// et paroles karaoké défilantes. Présentée depuis l'en-tête de `ContentView`.
struct NowPlayingFullView: View {

    @Environment(LyricsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 16) {
                grabber

                AlbumArtworkView(data: viewModel.artwork)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
                    .padding(.top, 4)

                trackInfo

                Divider().overlay(.white.opacity(0.15)).padding(.horizontal, 40)

                LyricsView(lyrics: viewModel.lyrics, currentIndex: viewModel.currentLineIndex)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 10)
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(16)
            }
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(.white.opacity(0.25))
            .frame(width: 40, height: 5)
    }

    @ViewBuilder
    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(viewModel.track?.title ?? "—")
                .font(.title2.bold()).foregroundStyle(.white)
                .multilineTextAlignment(.center).lineLimit(2)
            Text(viewModel.track?.artist ?? "Aucune lecture")
                .font(.title3).foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            if let album = viewModel.track?.album, !album.isEmpty {
                Text(album)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 24)
    }

    /// Fond : pochette floutée et assombrie, ou dégradé par défaut.
    @ViewBuilder
    private var background: some View {
        if let data = viewModel.artwork, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .overlay(.black.opacity(0.6))
                .blur(radius: 60)
        } else {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.07, blue: 0.12), .black],
                startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Affiche une pochette d'album depuis des données JPEG, avec un placeholder si absente.
struct AlbumArtworkView: View {
    let data: Data?

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(.white.opacity(0.08))
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
