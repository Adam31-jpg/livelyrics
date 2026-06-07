import SwiftUI
import LiveLyricsCore

/// Vue karaoké : paroles synchronisées qui défilent et se surlignent, ligne active centrée.
struct LyricsView: View {
    let lyrics: SyncedLyrics?
    let currentIndex: Int?

    var body: some View {
        if let lyrics, !lyrics.lines.isEmpty {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        // Espace haut/bas pour pouvoir centrer la 1re et la dernière ligne.
                        Color.clear.frame(height: 120)
                        ForEach(lyrics.lines) { line in
                            LyricRow(line: line, state: rowState(for: line.id))
                                .id(line.id)
                        }
                        Color.clear.frame(height: 200)
                    }
                    .padding(.horizontal, 24)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    guard let newIndex else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        } else {
            StatusMessage(icon: "music.note.list", title: "Pas de paroles synchronisées",
                          subtitle: "Ce morceau n'a pas de version synchronisée.")
        }
    }

    private func rowState(for id: Int) -> LyricRow.State {
        guard let currentIndex else { return .upcoming }
        if id == currentIndex { return .active }
        return id < currentIndex ? .past : .upcoming
    }
}

private struct LyricRow: View {
    enum State { case past, active, upcoming }

    let line: LyricLine
    let state: State

    var body: some View {
        Group {
            if line.isBlank {
                Image(systemName: "music.note")
                    .font(.title3)
            } else {
                Text(line.text)
                    .font(.system(size: state == .active ? 28 : 22, weight: .bold))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(color)
        .scaleEffect(state == .active ? 1.0 : 0.96)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: state)
    }

    private var color: Color {
        switch state {
        case .active:   .white
        case .past:     .white.opacity(0.35)
        case .upcoming: .white.opacity(0.55)
        }
    }
}
