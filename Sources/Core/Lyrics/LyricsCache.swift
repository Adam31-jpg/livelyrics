import Foundation

/// Cache disque des paroles dans le conteneur App Group (donc lisible aussi par le widget).
/// Évite de re-télécharger les mêmes paroles et permet un affichage instantané au replay.
///
/// On enveloppe un `LyricsService` : c'est un décorateur. Le ViewModel utilise un
/// `LyricsService`, sans savoir s'il y a un cache derrière → substituable facilement.
public actor CachingLyricsService: LyricsService {

    private let upstream: LyricsService
    private let directory: URL
    private let fileManager = FileManager.default

    public init(upstream: LyricsService) {
        self.upstream = upstream
        let base = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent("LyricsCache", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func fetchLyrics(for track: Track) async throws -> SyncedLyrics? {
        if let cached = loadFromDisk(trackID: track.id) {
            return cached
        }
        let fetched = try await upstream.fetchLyrics(for: track)
        if let fetched { saveToDisk(fetched) }
        return fetched
    }

    // MARK: - Disque

    private func fileURL(for trackID: String) -> URL {
        // Nom de fichier sûr (le trackID peut contenir des caractères spéciaux).
        let safe = trackID.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent(safe).appendingPathExtension("json")
    }

    private func loadFromDisk(trackID: String) -> SyncedLyrics? {
        let url = fileURL(for: trackID)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SyncedLyrics.self, from: data)
    }

    private func saveToDisk(_ lyrics: SyncedLyrics) {
        guard let data = try? JSONEncoder().encode(lyrics) else { return }
        try? data.write(to: fileURL(for: lyrics.trackID), options: .atomic)
    }
}
