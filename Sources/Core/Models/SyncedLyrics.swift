import Foundation

/// Paroles complètes d'un morceau. Si `isSynced == false`, on n'a que du texte brut
/// (pas d'horodatage) — l'UI affiche alors les paroles sans surlignage temporel.
public struct SyncedLyrics: Equatable, Codable, Sendable {

    public let trackID: String
    /// Lignes triées par `time` croissant. Garanti par l'initialiseur.
    public let lines: [LyricLine]
    public let isSynced: Bool
    /// Texte brut éventuel (fallback si pas de synchro).
    public let plainText: String?

    public init(trackID: String, lines: [LyricLine], isSynced: Bool, plainText: String? = nil) {
        self.trackID = trackID
        self.lines = lines.sorted { $0.time < $1.time }
        self.isSynced = isSynced
        self.plainText = plainText
    }

    public var isEmpty: Bool { lines.isEmpty && (plainText?.isEmpty ?? true) }
}
