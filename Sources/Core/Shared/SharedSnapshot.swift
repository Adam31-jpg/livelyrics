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

    public static func write(_ snapshot: SharedSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroup.defaults.set(data, forKey: key)
        // Une seule demande de reload par mise à jour → le widget recalcule sa timeline.
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

public enum WidgetKind {
    public static let lyrics = "LyricsTimelineWidget"
}
