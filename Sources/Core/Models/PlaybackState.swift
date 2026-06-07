import Foundation

/// Instantané de l'état de lecture à un instant donné.
///
/// On ne stocke pas une position "live" (impossible à garder à jour en continu) mais
/// une **ancre** : la position connue `position` à la date `referenceDate`. On extrapole
/// ensuite la position courante côté lecture (`estimatedPosition`). C'est ce qui permet
/// au widget de calculer une timeline entière sans réveiller l'app à chaque seconde.
public struct PlaybackState: Equatable, Codable, Sendable {

    public let track: Track?
    public let isPlaying: Bool
    /// Position de lecture (s) au moment `referenceDate`.
    public let position: TimeInterval
    public let referenceDate: Date

    public init(track: Track?, isPlaying: Bool, position: TimeInterval, referenceDate: Date) {
        self.track = track
        self.isPlaying = isPlaying
        self.position = position.isFinite ? max(0, position) : 0
        self.referenceDate = referenceDate
    }

    /// Position estimée à `date` (par défaut maintenant), extrapolée si la lecture continue.
    public func estimatedPosition(at date: Date = Date()) -> TimeInterval {
        guard isPlaying else { return position }
        return max(0, position + date.timeIntervalSince(referenceDate))
    }

    public static let empty = PlaybackState(track: nil, isPlaying: false, position: 0, referenceDate: .distantPast)
}
