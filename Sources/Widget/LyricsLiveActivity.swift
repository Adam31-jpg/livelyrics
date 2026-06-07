import SwiftUI
import WidgetKit
import ActivityKit
import LiveLyricsCore

/// Rendu de la Live Activity des paroles : écran verrouillé, Dynamic Island, et
/// surface CarPlay (iOS 26). Mise à jour en temps réel par l'app via `LiveActivityController`.
struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            // Vue sur l'écran verrouillé / bannière / CarPlay.
            LockScreenLyricsView(context: context)
                .activityBackgroundTint(.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.currentLine.isEmpty ? "♪" : context.state.currentLine)
                            .font(.headline).foregroundStyle(.white)
                            .multilineTextAlignment(.center).lineLimit(2)
                        if !context.state.nextLine.isEmpty {
                            Text(context.state.nextLine)
                                .font(.caption).foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } compactLeading: {
                Image(systemName: "music.note")
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
            } minimal: {
                Image(systemName: "music.note")
            }
        }
    }
}

private struct LockScreenLyricsView: View {
    let context: ActivityViewContext<LyricsActivityAttributes>

    var body: some View {
        VStack(spacing: 6) {
            Text("\(context.attributes.artist) – \(context.attributes.title)")
                .font(.caption2).foregroundStyle(.white.opacity(0.5)).lineLimit(1)

            Text(context.state.currentLine.isEmpty ? "♪" : context.state.currentLine)
                .font(.title3.bold()).foregroundStyle(.white)
                .multilineTextAlignment(.center).lineLimit(2)

            if !context.state.nextLine.isEmpty {
                Text(context.state.nextLine)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
