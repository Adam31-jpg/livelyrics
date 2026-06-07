import Foundation

/// Catalogue des providers disponibles. Centralise la création et le choix du provider
/// actif pour que l'UI n'ait jamais à instancier un service concret directement.
@MainActor
public final class ProviderRegistry {

    public private(set) var providers: [MusicProvider]

    public init(providers: [MusicProvider]? = nil) {
        // Ordre = ordre d'affichage. Apple Music en premier (seul fonctionnel pour l'instant).
        self.providers = providers ?? [
            AppleMusicProvider(),
            SpotifyProvider(),
            DeezerProvider(),
        ]
    }

    public func provider(id: String) -> MusicProvider? {
        providers.first { $0.serviceID == id }
    }

    /// Provider à utiliser par défaut : celui choisi en réglages s'il est dispo,
    /// sinon le premier provider disponible.
    public func defaultProvider() -> MusicProvider {
        if let saved = Settings.shared.selectedProviderID,
           let p = provider(id: saved), p.isAvailable {
            return p
        }
        return providers.first(where: { $0.isAvailable }) ?? providers[0]
    }
}
