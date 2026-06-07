import Foundation

/// Parseur du format LRC. Fonction pure (entrée String → sortie [LyricLine]),
/// donc 100% testable hors appareil.
///
/// Gère :
///  - les horodatages `[mm:ss.xx]` et `[mm:ss.xxx]`
///  - plusieurs horodatages sur une même ligne : `[00:12.00][00:47.00]texte`
///  - les balises méta (`[ar:]`, `[ti:]`, `[length:]`…) → ignorées
public enum LRCParser {

    /// `[mm:ss.xx]` ou `[mm:ss]` — capture minutes, secondes, fraction optionnelle.
    private static let timeTagPattern = try! NSRegularExpression(
        pattern: #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#)

    public static func parse(_ lrc: String) -> [LyricLine] {
        var collected: [(time: TimeInterval, text: String)] = []

        for rawLine in lrc.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let range = NSRange(line.startIndex..., in: line)
            let matches = timeTagPattern.matches(in: line, range: range)
            guard !matches.isEmpty else { continue }   // ligne sans timestamp (méta) → ignorée

            // Texte = tout ce qui suit le dernier tag temporel.
            let lastTagEnd = matches.last!.range.upperBound
            let textStart = Range(NSRange(location: lastTagEnd, length: (line as NSString).length - lastTagEnd), in: line)
            let text = textStart.map { String(line[$0]) }?.trimmingCharacters(in: .whitespaces) ?? ""

            for match in matches {
                guard let time = timeInterval(from: match, in: line) else { continue }
                collected.append((time, text))
            }
        }

        return collected
            .sorted { $0.time < $1.time }
            .enumerated()
            .map { LyricLine(id: $0.offset, time: $0.element.time, text: $0.element.text) }
    }

    private static func timeInterval(from match: NSTextCheckingResult, in line: String) -> TimeInterval? {
        func group(_ i: Int) -> String? {
            guard let r = Range(match.range(at: i), in: line) else { return nil }
            return String(line[r])
        }
        guard let mm = group(1).flatMap({ Double($0) }),
              let ss = group(2).flatMap({ Double($0) }) else { return nil }

        var fraction = 0.0
        if let frac = group(3), let value = Double(frac) {
            // "5" → 0.5 ; "05" → 0.05 ; "050" → 0.050
            fraction = value / pow(10.0, Double(frac.count))
        }
        return mm * 60 + ss + fraction
    }
}
