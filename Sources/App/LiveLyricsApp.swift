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
            // On garde l'observation active ; on pourrait réduire la fréquence en arrière-plan.
            if phase == .active { viewModel.objectWillResume() }
        }
    }
}

extension LyricsViewModel {
    /// Hook léger appelé au retour au premier plan (rien de bloquant ici pour l'instant).
    func objectWillResume() {}
}
