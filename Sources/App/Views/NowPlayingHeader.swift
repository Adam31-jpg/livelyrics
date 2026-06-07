import SwiftUI
import LiveLyricsCore

/// En-tête compact : pochette miniature + titre + artiste, et un indicateur de lecture.
/// Tappable → ouvre la page Now Playing plein écran.
struct NowPlayingHeader: View {
    let track: Track?
    let isPlaying: Bool
    var artwork: Data? = nil

    var body: some View {
        HStack(spacing: 12) {
            AlbumArtworkView(data: artwork)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(track?.title ?? "—")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(track?.artist ?? "Aucune lecture")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Image(systemName: isPlaying ? "waveform" : "pause.circle")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .symbolEffect(.variableColor.iterative, isActive: isPlaying)

            Spacer(minLength: 40)   // laisse la place au bouton réglages

            Image(systemName: "chevron.up")
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.4))
                .padding(.trailing, 40)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
