import Foundation

/// 🚧 STUB — Provider Deezer, prêt à brancher.
///
/// Comme Spotify, pas d'accès système. Deezer propose un SDK natif iOS (en déclin) et
/// une API. La position de lecture en temps réel d'une lecture externe est limitée :
/// l'intégration la plus fiable consiste à passer par le SDK quand il pilote la lecture.
///
/// Étapes pour activer :
///   1. App Deezer Connect (https://developers.deezer.com) → App ID.
///   2. OAuth → token.
///   3. Mapper l'état de lecture vers `PlaybackState`.
@MainActor
public final class DeezerProvider: MusicProvider {

    public let serviceID = "deezer"
    public let displayName = "Deezer"
    public var isAvailable: Bool { false }   // TODO

    public init() {}

    public func requestAuthorization() async -> Bool { false }     // TODO
    public func start() -> AsyncStream<PlaybackState> { AsyncStream { $0.finish() } }  // TODO
    public func stop() {}                                          // TODO
    public func currentState() -> PlaybackState { .empty }
}
