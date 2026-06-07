import SwiftUI
import LiveLyricsCore

/// En-tête compact : titre + artiste du morceau en cours, et un indicateur de lecture.
struct NowPlayingHeader: View {
    let track: Track?
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPlaying ? "waveform" : "pause.circle")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.85))
                .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                .frame(width: 32)

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
            Spacer(minLength: 40)   // laisse la place au bouton réglages
        }
        .padding(.vertical, 8)
    }
}
