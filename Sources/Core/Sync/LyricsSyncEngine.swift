import Foundation

/// Cœur de la synchronisation : à partir de paroles et d'une position de lecture,
/// détermine quelle ligne est active. **Logique pure, sans état mutable partagé** →
/// la pièce la plus facile à tester et à débugger isolément.
public enum LyricsSyncEngine {

    /// Index de la ligne active à `time` (dernière ligne dont `time <= position`).
    /// Recherche dichotomique → O(log n), adapté à un appel à haute fréquence.
    /// Retourne `nil` si la lecture est avant la 1re ligne ou si pas de paroles.
    public static func activeIndex(in lines: [LyricLine], at time: TimeInterval) -> Int? {
        guard !lines.isEmpty else { return nil }
        guard time >= lines[0].time else { return nil }

        var low = 0
        var high = lines.count - 1
        var result = 0
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].time <= time {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    /// Temps restant (s) avant la ligne suivante — utile pour planifier un réveil/refresh.
    public static func timeUntilNextLine(in lines: [LyricLine], at time: TimeInterval) -> TimeInterval? {
        guard let next = lines.first(where: { $0.time > time }) else { return nil }
        return next.time - time
    }
}
