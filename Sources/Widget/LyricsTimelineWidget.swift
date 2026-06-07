import SwiftUI
import WidgetKit
import UIKit
import LiveLyricsCore

/// Widget paroles (écran d'accueil + dashboard CarPlay) façon karaoké.
///
/// Astuce anti-throttling : au lieu de demander un refresh à chaque ligne (budget iOS
/// limité), on construit en UNE fois une timeline contenant une entrée par ligne, datée.
/// WidgetKit affiche chaque entrée à l'heure prévue → 1 reload par chanson.
///
/// ⚠️ L'entrée ne contient QUE des types primitifs (String/Date). WidgetKit archive les
/// timelines sur disque, et un tableau de structs custom y fait échouer l'archivage
/// (WidgetArchiver.ArchivingError) → widget figé. D'où les champs "à plat".
struct LyricsTimelineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.lyrics, provider: LyricsTimelineProvider()) { entry in
            LyricsWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Paroles en direct")
        .description("Affiche les paroles synchronisées avec la musique, façon karaoké.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct LyricsEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let prevLine: String
    let currentLine: String
    let nextLine: String
    let nextLine2: String
}

struct LyricsTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> LyricsEntry {
        LyricsEntry(date: Date(), title: "", artist: "",
                    prevLine: "", currentLine: "♪", nextLine: "", nextLine2: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (LyricsEntry) -> Void) {
        completion(makeCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LyricsEntry>) -> Void) {
        let snapshot = SharedSnapshotStore.read()

        guard snapshot.track != nil, snapshot.isSynced,
              !snapshot.lines.isEmpty, snapshot.isPlaying else {
            completion(Timeline(entries: [makeCurrentEntry()], policy: .never))
            return
        }

        let now = Date()
        let pos = snapshot.position(at: now)
        let currentIdx = LyricsSyncEngine.activeIndex(in: snapshot.lines, at: pos) ?? 0

        // 1re entrée = ligne courante affichée IMMÉDIATEMENT.
        var entries: [LyricsEntry] = [entry(at: currentIdx, date: now, snapshot: snapshot)]

        // Puis une entrée par ligne à venir, datée à son heure d'apparition réelle.
        for i in (currentIdx + 1)..<snapshot.lines.count {
            let line = snapshot.lines[i]
            let secondsFromAnchor = line.time - snapshot.anchorPosition - snapshot.offset
            guard secondsFromAnchor.isFinite else { continue }      // jamais de date NaN/inf
            let lineDate = snapshot.anchorDate.addingTimeInterval(secondsFromAnchor)
            guard lineDate > now else { continue }
            entries.append(entry(at: i, date: lineDate, snapshot: snapshot))
            // Timeline volontairement courte : au-delà, l'archive WidgetKit échoue
            // (ArchivingError). 25 entrées couvrent ~plusieurs minutes ; .atEnd recalcule.
            if entries.count >= 25 { break }
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Construit une entrée "à plat" centrée sur la ligne `i`.
    private func entry(at i: Int, date: Date, snapshot: SharedSnapshot) -> LyricsEntry {
        let lines = snapshot.lines
        let cur = lineText(lines, i)
        return LyricsEntry(
            date: date,
            title: snapshot.track?.title ?? "",
            artist: snapshot.track?.artist ?? "",
            prevLine: lineText(lines, i - 1),
            currentLine: cur.isEmpty ? "♪" : cur,
            nextLine: lineText(lines, i + 1),
            nextLine2: lineText(lines, i + 2))
    }

    /// Texte d'une ligne (vide si hors bornes ; "♪" pour une ligne instrumentale).
    private func lineText(_ lines: [LyricLine], _ i: Int) -> String {
        guard lines.indices.contains(i) else { return "" }
        let t = lines[i].text.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "♪" : t
    }

    private func makeCurrentEntry() -> LyricsEntry {
        let snapshot = SharedSnapshotStore.read()
        guard !snapshot.lines.isEmpty else {
            return LyricsEntry(date: Date(),
                               title: snapshot.track?.title ?? "",
                               artist: snapshot.track?.artist ?? "",
                               prevLine: "", currentLine: "♪", nextLine: "", nextLine2: "")
        }
        let pos = snapshot.position(at: Date())
        let idx = LyricsSyncEngine.activeIndex(in: snapshot.lines, at: pos) ?? 0
        return entry(at: idx, date: Date(), snapshot: snapshot)
    }
}

// MARK: - Vues

struct LyricsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LyricsEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            Text(entry.currentLine).font(.headline).lineLimit(2)

        case .systemSmall:
            // Card CarPlay : pochette en fond assombrie + parole courante + suivante.
            ZStack {
                WidgetArtwork().scaledToFill().overlay(.black.opacity(0.55))
                VStack(spacing: 4) {
                    Text(entry.currentLine).font(.headline.bold()).foregroundStyle(.white)
                        .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.55)
                    if !entry.nextLine.isEmpty {
                        Text(entry.nextLine).font(.caption2).foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center).lineLimit(2)
                    }
                }
                .padding(8)
            }

        case .systemLarge:
            VStack(alignment: .leading, spacing: 10) {
                trackHeader
                Divider().overlay(.white.opacity(0.15))
                karaoke(lines: [
                    (entry.prevLine, false),
                    (entry.currentLine, true),
                    (entry.nextLine, false),
                    (entry.nextLine2, false),
                ], active: .title3, other: .subheadline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()

        default:    // .systemMedium
            HStack(spacing: 12) {
                WidgetArtwork().frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                karaoke(lines: [
                    (entry.prevLine, false),
                    (entry.currentLine, true),
                    (entry.nextLine, false),
                ], active: .headline, other: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }

    private var trackHeader: some View {
        HStack(spacing: 10) {
            WidgetArtwork().frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.isEmpty ? "—" : entry.title).font(.subheadline.bold())
                    .foregroundStyle(.white).lineLimit(1)
                Text(entry.artist).font(.caption)
                    .foregroundStyle(.white.opacity(0.6)).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    /// Pile de lignes karaoké : ligne active en blanc/gras, autres estompées (lignes vides ignorées).
    @ViewBuilder
    private func karaoke(lines: [(String, Bool)], active: Font, other: Font) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, item in
                if !item.0.isEmpty {
                    Text(item.0)
                        .font(item.1 ? active.bold() : other)
                        .foregroundStyle(item.1 ? .white : .white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Pochette du morceau courant, lue depuis le fichier partagé (App Group).
private struct WidgetArtwork: View {
    var body: some View {
        if let data = SharedArtworkStore.read(), let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(.white.opacity(0.1))
                Image(systemName: "music.note").foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
