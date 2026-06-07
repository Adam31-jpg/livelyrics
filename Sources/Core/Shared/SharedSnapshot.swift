import Foundation
import WidgetKit

/// Instantané que l'app écrit et que le widget lit, via l'App Group.
///
/// Contient tout ce dont le widget a besoin pour calculer SEUL la timeline des paroles
/// d'une chanson (sans réveiller l'app à chaque ligne) : les lignes + une ancre de lecture.
public struct SharedSnapshot: Codable, Sendable, Equatable {

    public let track: Track?
    public let lines: [LyricLine]
    public let isSynced: Bool
    /// Ancre de position (cf. `PlaybackState`).
    public let anchorPosition: TimeInterval
    public let anchorDate: Date
    public let isPlaying: Bool
    /// Offset de calibration en secondes (réglé par l'utilisateur).
    public let offset: TimeInterval

    public init(track: Track?, lines: [LyricLine], isSynced: Bool,
                anchorPosition: TimeInterval, anchorDate: Date,
                isPlaying: Bool, offset: TimeInterval) {
        self.track = track
        self.lines = lines
        self.isSynced = isSynced
        self.anchorPosition = anchorPosition
        self.anchorDate = anchorDate
        self.isPlaying = isPlaying
        self.offset = offset
    }

    /// Position estimée (avec offset appliqué) à une date donnée.
    public func position(at date: Date) -> TimeInterval {
        let base = isPlaying ? anchorPosition + date.timeIntervalSince(anchorDate) : anchorPosition
        return max(0, base + offset)
    }

    public static let empty = SharedSnapshot(
        track: nil, lines: [], isSynced: false,
        anchorPosition: 0, anchorDate: .distantPast, isPlaying: false, offset: 0)
}

/// Lecture/écriture de l'instantané partagé + déclenchement du refresh widget.
public enum SharedSnapshotStore {

    private static let key = "currentSnapshot"

    /// Écrit l'instantané. NE déclenche PAS de reload : appeler `reloadWidget()`
    /// explicitement, et seulement sur un vrai changement (morceau / play-pause), pour
    /// ne pas épuiser le budget de refresh d'iOS (sinon le widget finit par se figer).
    public static func write(_ snapshot: SharedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }

    /// Demande à WidgetKit de recalculer la timeline (1 reload = 1 chanson recalculée).
    public static func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.lyrics)
    }

    public static func read() -> SharedSnapshot {
        guard let data = AppGroup.defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(SharedSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

/// Stocke la pochette du morceau courant dans un FICHIER du conteneur App Group
/// (et non dans UserDefaults : un JPEG y serait trop lourd et écrit trop souvent).
/// Lue par le grand widget et la Live Activity.
public enum SharedArtworkStore {

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appendingPathComponent("current-artwork.jpg")
    }

    public static func write(_ data: Data?) {
        guard let url = fileURL else { return }
        if let data {
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    public static func read() -> Data? {
        guard let url = fileURL else { return nil }
        return try? Data(contentsOf: url)
    }
}

public enum WidgetKind {
    // ⚠️ Changer ce "kind" force WidgetKit à repartir d'un store de timeline VIERGE.
    // Indispensable après un changement de structure d'entrée : sinon WidgetKit tente
    // de relire l'ancien cache (incompatible) → "Unable to unarchive collection" →
    // tous les reloads échouent et le widget reste figé.
    public static let lyrics = "LyricsCardWidget"
}
