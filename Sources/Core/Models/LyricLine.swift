import Foundation

/// Une ligne de paroles avec son horodatage (issu du format LRC `[mm:ss.xx]`).
public struct LyricLine: Equatable, Codable, Sendable, Identifiable {

    /// Index de la ligne dans le morceau (0-based) — sert d'identité stable pour SwiftUI.
    public let id: Int
    /// Position dans le morceau, en secondes, à laquelle la ligne doit s'activer.
    public let time: TimeInterval
    public let text: String

    public init(id: Int, time: TimeInterval, text: String) {
        self.id = id
        self.time = time
        self.text = text
    }

    /// Ligne vide (interlude instrumental) — utile pour afficher un indicateur ♪.
    public var isBlank: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }
}
