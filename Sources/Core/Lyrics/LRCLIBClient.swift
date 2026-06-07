import Foundation

/// Client de l'API LRCLIB (https://lrclib.net/docs) — gratuite, sans clé.
///
/// Stratégie :
///   1. `/api/get` avec artiste + titre + album + durée → match exact si dispo.
///   2. Si 404, `/api/search` avec artiste + titre → on prend le meilleur candidat
///      (durée la plus proche, paroles synchronisées en priorité).
public struct LRCLIBClient: LyricsService {

    private let session: URLSession
    private let baseURL = URL(string: "https://lrclib.net")!
    /// LRCLIB demande un User-Agent identifiant l'app (politesse / quotas).
    private let userAgent = "LiveLyrics/0.1 (https://github.com/adamhaouzi/livelyrics)"

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchLyrics(for track: Track) async throws -> SyncedLyrics? {
        if let exact = try await getExact(track) {
            return exact
        }
        return try await search(track)
    }

    // MARK: - /api/get (match exact)

    private func getExact(_ track: Track) async throws -> SyncedLyrics? {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/get"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "artist_name", value: track.artist),
            .init(name: "track_name", value: track.title),
            .init(name: "album_name", value: track.album ?? ""),
            .init(name: "duration", value: String(Int(track.duration.rounded()))),
        ]
        guard let item: LRCLIBItem = try await fetchOptional(comps.url!) else { return nil }
        return item.toSyncedLyrics(trackID: track.id)
    }

    // MARK: - /api/search (fallback)

    private func search(_ track: Track) async throws -> SyncedLyrics? {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/search"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "track_name", value: track.title),
            .init(name: "artist_name", value: track.artist),
        ]
        let results: [LRCLIBItem] = try await fetchArray(comps.url!)
        guard !results.isEmpty else { return nil }

        // Meilleur candidat : synchronisé d'abord, puis durée la plus proche.
        let best = results.min { lhs, rhs in
            let lSynced = (lhs.syncedLyrics?.isEmpty == false) ? 0 : 1
            let rSynced = (rhs.syncedLyrics?.isEmpty == false) ? 0 : 1
            if lSynced != rSynced { return lSynced < rSynced }
            let lDelta = abs((lhs.duration ?? 0) - track.duration)
            let rDelta = abs((rhs.duration ?? 0) - track.duration)
            return lDelta < rDelta
        }
        return best?.toSyncedLyrics(trackID: track.id)
    }

    // MARK: - Réseau

    private func makeRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        return req
    }

    /// Retourne `nil` proprement sur 404 (paroles non trouvées).
    private func fetchOptional(_ url: URL) async throws -> LRCLIBItem? {
        let (data, response) = try await session.data(for: makeRequest(url))
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }
        try validate(response)
        return try JSONDecoder().decode(LRCLIBItem.self, from: data)
    }

    private func fetchArray(_ url: URL) async throws -> [LRCLIBItem] {
        let (data, response) = try await session.data(for: makeRequest(url))
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return [] }
        try validate(response)
        return try JSONDecoder().decode([LRCLIBItem].self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - DTO LRCLIB

/// Réponse brute LRCLIB. Découplée de notre modèle interne via `toSyncedLyrics`.
private struct LRCLIBItem: Decodable {
    let id: Int?
    let trackName: String?
    let artistName: String?
    let duration: Double?
    let plainLyrics: String?
    let syncedLyrics: String?

    func toSyncedLyrics(trackID: String) -> SyncedLyrics? {
        if let synced = syncedLyrics, !synced.isEmpty {
            let lines = LRCParser.parse(synced)
            if !lines.isEmpty {
                return SyncedLyrics(trackID: trackID, lines: lines, isSynced: true, plainText: plainLyrics)
            }
        }
        if let plain = plainLyrics, !plain.isEmpty {
            return SyncedLyrics(trackID: trackID, lines: [], isSynced: false, plainText: plain)
        }
        return nil
    }
}
