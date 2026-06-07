import Foundation

/// Abstraction d'un service de musique. C'est LE point d'extension de l'app :
/// pour supporter un nouveau service, on écrit une classe conforme à ce protocole.
///
/// Le reste de l'app (ViewModel, UI, widget) ne dépend QUE de ce protocole — jamais
/// d'un service concret. → couplage minimal, ajout/débogage facile.
@MainActor
public protocol MusicProvider: AnyObject {

    /// Identifiant stable du service (ex: "apple-music"). Sert au choix persistant.
    var serviceID: String { get }
    var displayName: String { get }

    /// Le service est-il utilisable sur cet appareil (app installée, OS compatible…) ?
    var isAvailable: Bool { get }

    /// Demande l'autorisation d'accès. Retourne `true` si accordée.
    func requestAuthorization() async -> Bool

    /// Démarre l'observation et renvoie un flux d'états de lecture.
    /// Le premier élément émis reflète l'état courant.
    func start() -> AsyncStream<PlaybackState>

    /// Arrête l'observation et libère les ressources.
    func stop()

    /// Lit l'état courant à la demande (utile pour rafraîchir au premier plan).
    func currentState() -> PlaybackState
}

/// Erreurs communes aux providers.
public enum MusicProviderError: Error, Sendable {
    case notAuthorized
    case serviceUnavailable
    case notImplemented(String)
}
