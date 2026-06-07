import Foundation

/// Abstraction d'une source de paroles. Permet de remplacer LRCLIB par une autre source
/// (ou d'en combiner plusieurs) sans toucher au reste de l'app.
public protocol LyricsService: Sendable {
    /// Cherche les paroles d'un morceau. Retourne `nil` si introuvable (pas une erreur).
    func fetchLyrics(for track: Track) async throws -> SyncedLyrics?
}
