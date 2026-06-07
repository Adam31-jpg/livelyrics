import SwiftUI
import LiveLyricsCore

/// Réglages : calibration de la synchro, choix du mode d'affichage CarPlay, service source.
struct SettingsView: View {

    @Environment(LyricsViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var offset: TimeInterval = Settings.shared.syncOffset
    @State private var useLiveActivity: Bool = Settings.shared.useLiveActivity

    var body: some View {
        NavigationStack {
            Form {
                Section("Calibration de la synchro") {
                    VStack(alignment: .leading) {
                        Text(String(format: "Décalage : %+.2f s", offset))
                            .font(.subheadline.monospacedDigit())
                        Slider(value: $offset, in: -2...2, step: 0.05)
                            .onChange(of: offset) { _, value in viewModel.offset = value }
                        Text("Positif = paroles en avance. Ajuste si elles sont en retard sur la musique.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Affichage CarPlay") {
                    Toggle("Live Activity (temps réel)", isOn: $useLiveActivity)
                        .onChange(of: useLiveActivity) { _, value in
                            Settings.shared.useLiveActivity = value
                        }
                    Text("Activé : Live Activity (maj ligne par ligne). Désactivé : widget timeline pré-calculé. À comparer sur ton CarPlay.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Source") {
                    Text("Apple Music")
                    Text("Spotify et Deezer : à venir (providers stub).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
