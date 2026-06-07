import Foundation
import MediaPlayer

/// Provider Apple Music basé sur `MPMusicPlayerController.systemMusicPlayer`.
///
/// Le `systemMusicPlayer` reflète la lecture du vrai lecteur Apple Music du système :
/// on récupère titre / artiste / album / durée + position de lecture, et on est notifié
/// des changements de morceau et d'état (play/pause).
@MainActor
public final class AppleMusicProvider: MusicProvider {

    public let serviceID = "apple-music"
    public let displayName = "Apple Music"
    public var isAvailable: Bool { true }

    private let player = MPMusicPlayerController.systemMusicPlayer
    private var continuation: AsyncStream<PlaybackState>.Continuation?
    private var observing = false

    public init() {}

    public func requestAuthorization() async -> Bool {
        // iOS 16+ : MPMediaLibrary couvre l'accès "now playing" du lecteur système.
        if MPMediaLibrary.authorizationStatus() == .authorized { return true }
        return await withCheckedContinuation { cont in
            MPMediaLibrary.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    public func start() -> AsyncStream<PlaybackState> {
        AsyncStream { continuation in
            self.continuation = continuation
            self.beginObserving()
            // Émet l'état courant immédiatement.
            continuation.yield(self.currentState())

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        }
    }

    public func stop() {
        guard observing else { return }
        observing = false
        player.endGeneratingPlaybackNotifications()
        NotificationCenter.default.removeObserver(self)
        continuation?.finish()
        continuation = nil
    }

    public func currentState() -> PlaybackState {
        let item = player.nowPlayingItem
        let track = item.map {
            Track(
                title: $0.title ?? "Titre inconnu",
                artist: $0.artist ?? "Artiste inconnu",
                album: $0.albumTitle,
                duration: $0.playbackDuration
            )
        }
        return PlaybackState(
            track: track,
            isPlaying: player.playbackState == .playing,
            position: player.currentPlaybackTime,
            referenceDate: Date()
        )
    }

    // MARK: - Observation

    private func beginObserving() {
        guard !observing else { return }
        observing = true

        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(handleChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        center.addObserver(
            self, selector: #selector(handleChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)

        player.beginGeneratingPlaybackNotifications()
    }

    @objc private func handleChange() {
        continuation?.yield(currentState())
    }
}
