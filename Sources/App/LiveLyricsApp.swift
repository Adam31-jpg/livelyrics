import SwiftUI
import LiveLyricsCore

@main
struct LiveLyricsApp: App {

    @State private var viewModel = LyricsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .task { await viewModel.start() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Retour au premier plan → re-synchro (le morceau a pu changer en arrière-plan).
            if phase == .active { viewModel.refreshNow() }
        }
    }
}
