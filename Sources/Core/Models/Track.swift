import Foundation

/// Un morceau en cours de lecture, indépendant du service source (Apple Music, Spotify…).
/// Type pur et `Sendable` : aucune dépendance UI ou framework média.
public struct Track: Equatable, Codable, Sendable, Identifiable {

    public let title: String
    public let artist: String
    public let album: String?
    /// Durée en secondes. Sert à départager les bons résultats sur LRCLIB.
    public let duration: TimeInterval

    public init(title: String, artist: String, album: String? = nil, duration: TimeInterval) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
    }

    /// Identité stable d'un morceau (sert de clé de cache + de comparaison "même chanson ?").
    public var id: String {
        "\(artist.lowercased())|\(title.lowercased())|\(Int(duration.rounded()))"
    }

    public var displayName: String { "\(artist) – \(title)" }
}
