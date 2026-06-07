import SwiftUI
import LiveLyricsCore

/// Écran racine : en-tête "now playing" + paroles, ou un état vide selon le statut.
struct ContentView: View {

    @Environment(LyricsViewModel.self) private var viewModel
    @State private var showSettings = false

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                NowPlayingHeader(track: viewModel.track, isPlaying: viewModel.isPlaying)
                    .padding(.horizontal)
                    .padding(.top, 8)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .padding(12)
            }
            .tint(.white.opacity(0.8))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(viewModel)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .idle, .waitingForMusic:
            StatusMessage(icon: "music.note", title: "En attente de musique",
                          subtitle: "Lance un morceau dans Apple Music.")
        case .needsAuthorization:
            StatusMessage(icon: "lock", title: "Accès requis",
                          subtitle: "Autorise l'accès à la médiathèque dans Réglages.")
        case .loadingLyrics:
            ProgressView("Recherche des paroles…").tint(.white)
        case .ready:
            LyricsView(lyrics: viewModel.lyrics, currentIndex: viewModel.currentLineIndex)
        case .noLyrics:
            PlainLyricsOrEmpty(lyrics: viewModel.lyrics)
        case .error(let message):
            StatusMessage(icon: "exclamationmark.triangle", title: "Erreur", subtitle: message)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.07, blue: 0.12), .black],
            startPoint: .top, endPoint: .bottom)
    }
}

/// Affiche les paroles brutes (non synchronisées) ou un message vide.
private struct PlainLyricsOrEmpty: View {
    let lyrics: SyncedLyrics?
    var body: some View {
        if let plain = lyrics?.plainText, !plain.isEmpty {
            ScrollView {
                Text(plain)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        } else {
            StatusMessage(icon: "text.badge.xmark", title: "Paroles introuvables",
                          subtitle: "Aucune parole disponible pour ce morceau.")
        }
    }
}

struct StatusMessage: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(.white.opacity(0.6))
            Text(title).font(.title2.bold()).foregroundStyle(.white)
            Text(subtitle).font(.body).foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
