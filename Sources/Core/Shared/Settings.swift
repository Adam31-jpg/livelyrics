import Foundation

/// Réglages persistants, partagés via l'App Group (le widget peut lire l'offset).
@MainActor
public final class Settings {

    public static let shared = Settings()
    private let defaults = AppGroup.defaults

    private enum Key {
        static let offset = "syncOffset"
        static let provider = "selectedProviderID"
        static let useLiveActivity = "useLiveActivity"
    }

    private init() {}

    /// Décalage de synchro en secondes. Positif = paroles en avance, négatif = en retard.
    /// Permet de compenser la latence d'affichage / l'inertie du système.
    public var syncOffset: TimeInterval {
        get { defaults.double(forKey: Key.offset) }
        set { defaults.set(newValue, forKey: Key.offset) }
    }

    public var selectedProviderID: String? {
        get { defaults.string(forKey: Key.provider) }
        set { defaults.set(newValue, forKey: Key.provider) }
    }

    /// true = Live Activity (temps réel), false = Widget timeline. À comparer sur CarPlay.
    public var useLiveActivity: Bool {
        get { defaults.object(forKey: Key.useLiveActivity) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.useLiveActivity) }
    }
}
