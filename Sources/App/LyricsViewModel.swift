import Foundation
import Observation
import LiveLyricsCore

/// Orchestrateur de l'app : relie provider de musique → service de paroles → moteur de
/// synchro → UI + état partagé (widget) + Live Activity.
///
/// C'est le seul endroit qui "câble" les briques ensemble. Chaque brique reste ignorante
/// des autres → on peut en remplacer une sans casser le reste.
@MainActor
@Observable
public final class LyricsViewModel {

    // État exposé à l'UI
    public private(set) var track: Track?
    /// Pochette d'album du morceau courant (JPEG), pour l'UI plein écran.
    public private(set) var artwork: Data?
    public private(set) var lyrics: SyncedLyrics?
    public private(set) var currentLineIndex: Int?
    public private(set) var isPlaying = false
    public private(set) var status: Status = .idle

    public enum Status: Equatable {
        case idle
        case needsAuthorization
        case waitingForMusic
        case loadingLyrics
        case ready
        case noLyrics
        case error(String)
    }

    // Réglage de calibration exposé à l'UI (relié à Settings).
    public var offset: TimeInterval {
        get { Settings.shared.syncOffset }
        set { Settings.shared.syncOffset = newValue; refreshSharedState() }
    }

    // Dépendances (injectées → testables / remplaçables)
    private let registry: ProviderRegistry
    private let lyricsService: LyricsService
    private let activityController: LiveActivityController

    private var provider: MusicProvider
    private var playback: PlaybackState = .empty
    private var streamTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var lyricsLoadTask: Task<Void, Never>?

    /// Fréquence de rafraîchissement de la surbrillance au premier plan.
    private let tickInterval: Duration = .milliseconds(150)

    public init(registry: ProviderRegistry? = nil,
                lyricsService: LyricsService? = nil,
                activityController: LiveActivityController? = nil) {
        let resolvedRegistry = registry ?? ProviderRegistry()
        self.registry = resolvedRegistry
        self.lyricsService = lyricsService ?? CachingLyricsService(upstream: LRCLIBClient())
        self.activityController = activityController ?? LiveActivityController()
        self.provider = resolvedRegistry.defaultProvider()
    }

    // MARK: - Cycle de vie

    public func start() async {
        guard await provider.requestAuthorization() else {
            status = .needsAuthorization
            return
        }
        status = .waitingForMusic
        subscribeToProvider()
        startTickLoop()
    }

    public func stop() {
        streamTask?.cancel()
        tickTask?.cancel()
        lyricsLoadTask?.cancel()
        provider.stop()
        activityController.end()
    }

    /// Change de service (Apple Music → Spotify…). Re-câble proprement.
    public func switchProvider(to id: String) async {
        guard let next = registry.provider(id: id), next.serviceID != provider.serviceID else { return }
        provider.stop()
        streamTask?.cancel()
        Settings.shared.selectedProviderID = id
        provider = next
        await start()
    }

    // MARK: - Abonnement au provider

    private func subscribeToProvider() {
        streamTask?.cancel()
        let stream = provider.start()
        streamTask = Task { [weak self] in
            for await state in stream {
                await self?.handle(state)
            }
        }
    }

    private func handle(_ state: PlaybackState) async {
        let previousTrackID = playback.track?.id
        playback = state
        isPlaying = state.isPlaying

        if state.track?.id != previousTrackID {
            // Nouvelle chanson → on (ré)initialise tout.
            track = state.track
            artwork = state.artwork
            currentLineIndex = nil
            lyrics = nil
            if let track = state.track {
                loadLyrics(for: track)
            } else {
                status = .waitingForMusic
                activityController.end()
            }
        } else if state.artwork != nil {
            // Même morceau : la pochette peut arriver après coup (chargement asynchrone).
            artwork = state.artwork
        }
        refreshSharedState()
    }

    // MARK: - Chargement des paroles

    private func loadLyrics(for track: Track) {
        status = .loadingLyrics
        lyricsLoadTask?.cancel()
        lyricsLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await lyricsService.fetchLyrics(for: track)
                guard !Task.isCancelled, track.id == self.track?.id else { return }
                if let result, !result.isEmpty {
                    self.lyrics = result
                    self.status = result.isSynced ? .ready : .noLyrics
                    Log.lyrics.info("Paroles chargées (\(result.lines.count) lignes, synced=\(result.isSynced))")
                } else {
                    self.lyrics = nil
                    self.status = .noLyrics
                    Log.lyrics.notice("Aucune parole trouvée pour \(track.displayName)")
                }
                self.startActivityIfNeeded()
                self.refreshSharedState()
            } catch {
                guard !Task.isCancelled else { return }
                self.status = .error(error.localizedDescription)
                Log.lyrics.error("Échec chargement paroles: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Boucle de synchro (premier plan)

    private func startTickLoop() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: self?.tickInterval ?? .milliseconds(150))
            }
        }
    }

    private func tick() {
        guard let lyrics, lyrics.isSynced else { return }
        let position = playback.estimatedPosition() + offset
        let newIndex = LyricsSyncEngine.activeIndex(in: lyrics.lines, at: position)
        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
            updateActivity(lineIndex: newIndex)
        }
    }

    // MARK: - État partagé (widget) + Live Activity

    private func refreshSharedState() {
        let snapshot = SharedSnapshot(
            track: track,
            lines: lyrics?.lines ?? [],
            isSynced: lyrics?.isSynced ?? false,
            anchorPosition: playback.position,
            anchorDate: playback.referenceDate,
            isPlaying: playback.isPlaying,
            offset: offset)
        SharedSnapshotStore.write(snapshot)
    }

    private func startActivityIfNeeded() {
        guard Settings.shared.useLiveActivity, let track, let lyrics, lyrics.isSynced else { return }
        activityController.start(track: track)
        updateActivity(lineIndex: currentLineIndex)
    }

    private func updateActivity(lineIndex: Int?) {
        guard Settings.shared.useLiveActivity, let lyrics else { return }
        let current = lineIndex.flatMap { lyrics.lines[safe: $0]?.text } ?? ""
        let next = lineIndex.flatMap { lyrics.lines[safe: $0 + 1]?.text } ?? ""
        activityController.update(
            state: .init(currentLine: current, nextLine: next,
                         lineIndex: lineIndex ?? -1, isPlaying: isPlaying))
    }
}

extension Array {
    /// Accès indexé sûr (évite les crashs d'index hors bornes dans les calculs de ligne).
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
