import SwiftUI
import WidgetKit
import LiveLyricsCore

/// Widget "page de widgets CarPlay / écran d'accueil" affichant la parole courante.
///
/// Astuce anti-throttling : au lieu de demander un refresh à chaque ligne (budget iOS
/// limité), on construit en UNE fois une timeline contenant une entrée par ligne, datée.
/// WidgetKit affiche chaque entrée à l'heure prévue. → 1 reload par chanson.
struct LyricsTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.lyrics, provider: LyricsTimelineProvider()) { entry in
            LyricsWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Paroles en direct")
        .description("Affiche la parole en cours, synchronisée avec la musique.")
        // .systemSmall est requis pour apparaître sur le dashboard CarPlay (iOS 26).
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct LyricsEntry: TimelineEntry {
    let date: Date
    let track: Track?
    let currentLine: String
    let nextLine: String
}

struct LyricsTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> LyricsEntry {
        LyricsEntry(date: Date(), track: nil, currentLine: "♪", nextLine: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (LyricsEntry) -> Void) {
        completion(makeCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LyricsEntry>) -> Void) {
        let snapshot = SharedSnapshotStore.read()

        guard let track = snapshot.track, snapshot.isSynced, !snapshot.lines.isEmpty, snapshot.isPlaying else {
            // Pas de lecture synchronisée → une seule entrée, on attend le prochain reload.
            completion(Timeline(entries: [makeCurrentEntry()], policy: .never))
            return
        }

        // Construit une entrée par ligne à venir, à sa date d'apparition réelle.
        let now = Date()
        var entries: [LyricsEntry] = []
        for (i, line) in snapshot.lines.enumerated() {
            // Date absolue où cette ligne devient active, d'après l'ancre de lecture.
            let secondsFromAnchor = line.time - snapshot.anchorPosition - snapshot.offset
            let lineDate = snapshot.anchorDate.addingTimeInterval(secondsFromAnchor)
            guard lineDate >= now.addingTimeInterval(-1) else { continue }   // ignore le passé

            let next = snapshot.lines[safe: i + 1]?.text ?? ""
            entries.append(LyricsEntry(date: lineDate, track: track,
                                       currentLine: line.text, nextLine: next))
            if entries.count >= 200 { break }    // garde-fou taille de timeline
        }

        if entries.isEmpty { entries = [makeCurrentEntry()] }
        // À la fin de la chanson, demande un nouveau calcul.
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Entrée reflétant l'instant présent (utilisée pour snapshot / fallback).
    private func makeCurrentEntry() -> LyricsEntry {
        let snapshot = SharedSnapshotStore.read()
        let pos = snapshot.position(at: Date())
        let index = LyricsSyncEngine.activeIndex(in: snapshot.lines, at: pos)
        let current = index.flatMap { snapshot.lines[safe: $0]?.text } ?? "♪"
        let next = index.flatMap { snapshot.lines[safe: $0 + 1]?.text } ?? ""
        return LyricsEntry(date: Date(), track: snapshot.track, currentLine: current, nextLine: next)
    }
}

struct LyricsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LyricsEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.currentLine).font(.headline).lineLimit(2)
            }
        case .systemSmall:
            // Format CarPlay : compact, parole courante mise en avant.
            VStack(spacing: 4) {
                Text(entry.currentLine.isEmpty ? "♪" : entry.currentLine)
                    .font(.headline).foregroundStyle(.white)
                    .multilineTextAlignment(.center).lineLimit(4)
                    .minimumScaleFactor(0.6)
                if !entry.nextLine.isEmpty {
                    Text(entry.nextLine)
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center).lineLimit(2)
                }
            }
            .padding(8)
        default:
            VStack(spacing: 8) {
                if let track = entry.track {
                    Text(track.displayName)
                        .font(.caption2).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
                }
                Text(entry.currentLine.isEmpty ? "♪" : entry.currentLine)
                    .font(.title2.bold()).foregroundStyle(.white)
                    .multilineTextAlignment(.center).lineLimit(3)
                if !entry.nextLine.isEmpty {
                    Text(entry.nextLine)
                        .font(.body).foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center).lineLimit(2)
                }
            }
            .padding()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
