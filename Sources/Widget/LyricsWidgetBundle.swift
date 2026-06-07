import SwiftUI
import WidgetKit

/// Point d'entrée de l'extension : regroupe le widget timeline et la Live Activity.
@main
struct LyricsWidgetBundle: WidgetBundle {
    var body: some Widget {
        LyricsTimelineWidget()
        LyricsLiveActivity()
    }
}
