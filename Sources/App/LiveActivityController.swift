import Foundation
import ActivityKit
import LiveLyricsCore

/// Gère le cycle de vie de la Live Activity des paroles (démarrage, mises à jour, fin).
/// Isolé du ViewModel pour que toute la logique ActivityKit soit à un seul endroit.
@MainActor
public final class LiveActivityController {

    private var activity: Activity<LyricsActivityAttributes>?
    private var currentTrackID: String?

    public init() {}

    /// Démarre une Live Activity pour un nouveau morceau (termine la précédente).
    public func start(track: Track) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Log.activity.notice("Live Activities désactivées dans les réglages système.")
            return
        }
        if currentTrackID == track.id, activity != nil { return }
        end()

        let attributes = LyricsActivityAttributes(title: track.title, artist: track.artist)
        let initial = LyricsActivityAttributes.ContentState(
            currentLine: "", nextLine: "", lineIndex: -1, isPlaying: true)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initial, staleDate: nil),
                pushType: nil)            // mises à jour locales (pas de serveur push)
            currentTrackID = track.id
            Log.activity.info("Live Activity démarrée pour \(track.displayName)")
        } catch {
            Log.activity.error("Échec démarrage Live Activity: \(error.localizedDescription)")
        }
    }

    public func update(state: LyricsActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    public func end() {
        guard let activity else { return }
        let finished = activity
        Task {
            await finished.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
        currentTrackID = nil
    }
}
