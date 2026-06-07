import Foundation
import ActivityKit

/// Contrat de la Live Activity, partagé entre l'app (qui la démarre/met à jour) et
/// l'extension widget (qui la dessine). C'est pour ça qu'il vit dans Core.
public struct LyricsActivityAttributes: ActivityAttributes {

    /// État dynamique : mis à jour à chaque changement de ligne.
    public struct ContentState: Codable, Hashable {
        public var currentLine: String
        public var nextLine: String
        public var lineIndex: Int
        public var isPlaying: Bool

        public init(currentLine: String, nextLine: String, lineIndex: Int, isPlaying: Bool) {
            self.currentLine = currentLine
            self.nextLine = nextLine
            self.lineIndex = lineIndex
            self.isPlaying = isPlaying
        }
    }

    /// Données fixes pour toute la durée de la chanson.
    public var title: String
    public var artist: String

    public init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}
