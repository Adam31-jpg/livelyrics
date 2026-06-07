import Foundation

/// Identifiants partagés entre l'app et l'extension widget.
/// ⚠️ Si tu changes le préfixe, mets-le à jour ici ET dans les fichiers `.entitlements`
/// ET dans `project.yml`.
public enum AppGroup {
    /// App Group reliant l'app et le widget (UserDefaults + conteneur fichiers partagés).
    public static let identifier = "group.com.adamhaouzi.livelyrics"

    /// UserDefaults partagés. Force-unwrap volontaire : une mauvaise config App Group
    /// doit échouer fort et tôt (au lieu de masquer un bug de partage de données).
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }
}
