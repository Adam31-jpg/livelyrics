import Foundation

/// 🚧 STUB — Provider Spotify, prêt à brancher.
///
/// Pourquoi un stub : iOS n'expose AUCUN moyen public de lire "ce que joue Spotify"
/// depuis une app tierce. La voie officielle est le **Spotify iOS SDK (App Remote)** :
///   1. Créer une app sur https://developer.spotify.com/dashboard (Client ID + redirect URI).
///   2. Ajouter `SpotifyiOS.xcframework` (SPM ou manuel).
///   3. Authentifier l'utilisateur (OAuth via `SPTSessionManager`).
///   4. S'abonner à `playerAPI` → `PlayerState` (track URI, position, isPaused).
///
/// Pour activer : implémenter les méthodes ci-dessous en mappant le `PlayerState`
/// Spotify vers notre `PlaybackState`. Aucune autre partie de l'app ne change.
@MainActor
public final class SpotifyProvider: MusicProvider {

    public let serviceID = "spotify"
    public let displayName = "Spotify"

    /// Disponible uniquement si l'app Spotify est installée ET le SDK configuré.
    public var isAvailable: Bool { false }   // TODO: vérifier l'install + le SDK

    public init() {}

    public func requestAuthorization() async -> Bool {
        // TODO: lancer le flux OAuth via SPTSessionManager.
        false
    }

    public func start() -> AsyncStream<PlaybackState> {
        // TODO: pousser un PlaybackState à chaque callback `playerStateDidChange`.
        AsyncStream { $0.finish() }
    }

    public func stop() {
        // TODO: se désabonner du playerAPI, fermer la session.
    }

    public func currentState() -> PlaybackState { .empty }
}
