# LiveLyrics 🎤

Paroles synchronisées en live pour iPhone + CarPlay (iOS 26), maison et gratuit.
Alternative DIY à Musixmatch / Dynamic Lyrics.

- **Source des paroles** : [LRCLIB](https://lrclib.net) — API gratuite, sans clé, format LRC synchronisé.
- **Détection du morceau** : Apple Music via `MediaPlayer` (titre, artiste, position de lecture en temps réel).
- **Affichage CarPlay** : Widget WidgetKit + Live Activity (API publiques, **aucun entitlement CarPlay à demander à Apple**).

> ⚠️ Coût incompressible : l'**Apple Developer Program (99 $/an)** est requis pour les
> widgets / Live Activities sur ton appareil au-delà de 7 jours et pour TestFlight.

---

## Architecture (modulaire, en couches)

```
Sources/
├── Core/                       # Framework partagé (app + widget)
│   ├── Models/                 # Types purs, Sendable, testables sans dépendance
│   │   ├── Track.swift
│   │   ├── LyricLine.swift
│   │   ├── SyncedLyrics.swift
│   │   └── PlaybackState.swift
│   ├── MusicProviders/         # 🔌 Brique remplaçable : 1 provider par service
│   │   ├── MusicProvider.swift         (protocole)
│   │   ├── AppleMusicProvider.swift     ✅ fonctionnel
│   │   ├── SpotifyProvider.swift        🚧 stub prêt à brancher
│   │   └── DeezerProvider.swift         🚧 stub prêt à brancher
│   ├── Lyrics/                  # 🔌 Brique remplaçable : source de paroles
│   │   ├── LyricsService.swift          (protocole)
│   │   ├── LRCLIBClient.swift            ✅ LRCLIB
│   │   ├── LRCParser.swift               (parseur LRC pur, testable)
│   │   └── LyricsCache.swift             (cache disque via App Group)
│   ├── Sync/
│   │   └── LyricsSyncEngine.swift        (logique pure : position → ligne active)
│   └── Shared/
│       ├── AppGroup.swift                (identifiants partagés)
│       ├── SharedSnapshot.swift          (pont app ↔ widget)
│       ├── LyricsActivityAttributes.swift(contrat Live Activity)
│       ├── Settings.swift                (offset de calibration, provider choisi)
│       └── Log.swift                     (os.Logger par catégorie)
├── App/                        # Cible application (UI iPhone)
│   ├── LiveLyricsApp.swift
│   ├── LyricsViewModel.swift            (orchestrateur @Observable)
│   ├── LiveActivityController.swift
│   ├── Views/
│   └── Resources/              (Info.plist, entitlements, Assets)
└── Widget/                     # Extension Widget + Live Activity
    ├── LyricsWidgetBundle.swift
    ├── LyricsTimelineWidget.swift       (timeline pré-calculée par chanson)
    ├── LyricsLiveActivity.swift         (rendu temps réel)
    ├── Info.plist
    └── LyricsWidget.entitlements
```

**Principe de découplage** : l'app ne connaît que des *protocoles* (`MusicProvider`,
`LyricsService`). Ajouter Spotify = écrire une classe conforme à `MusicProvider`, sans
toucher au reste. Le moteur de synchro (`LyricsSyncEngine`) est une fonction pure :
`(paroles, position) → index de ligne`, donc trivial à tester et débugger.

---

## Build (sur ton Mac)

### 1. Prérequis
```bash
# Xcode 26 + outils en ligne de commande
xcode-select --install

# XcodeGen (génère le .xcodeproj depuis project.yml)
brew install xcodegen
```

### 2. Générer et ouvrir le projet
```bash
cd livelyrics
xcodegen generate
open LiveLyrics.xcodeproj
```

### 3. Configurer la signature (une seule fois)
Dans Xcode, pour **chaque** cible (`LiveLyrics` et `LyricsWidgetExtension`) :
1. Onglet **Signing & Capabilities** → choisis ton **Team**.
2. Vérifie la capability **App Groups** → coche `group.com.adamhaouzi.livelyrics`
   (le même groupe sur les deux cibles — c'est ce qui relie l'app au widget).
3. Sur la cible `LiveLyrics`, vérifie la capability **Live Activities** (déjà activée
   via `NSSupportsLiveActivities` dans l'Info.plist).

> Astuce : tu peux remplacer `com.adamhaouzi` par ton propre préfixe partout
> (`project.yml` + `AppGroup.swift` + les `.entitlements`).

### 4. Lancer
Branche ton iPhone, sélectionne la cible **LiveLyrics**, lance (⌘R).
Au premier lancement, accepte l'accès à la médiathèque. Lance un morceau dans
Apple Music → les paroles défilent.

---

## Statut

| Brique | État |
|---|---|
| Détection morceau Apple Music + position | ✅ |
| Récupération paroles LRCLIB + parseur LRC | ✅ |
| Moteur de synchro + UI karaoké auto-scroll | ✅ |
| Cache disque des paroles | ✅ |
| Widget timeline (CarPlay) | ✅ structure complète |
| Live Activity (CarPlay temps réel) | ✅ structure complète |
| Spotify / Deezer | 🚧 stubs (voir TODO dans les fichiers) |
| Offset de calibration synchro | ✅ (réglable dans l'app) |

## Le point à valider tôt
La **fréquence de rafraîchissement** des widgets/Live Activities est budgétée par iOS.
Le widget utilise une *timeline pré-calculée* (1 reload par chanson, N entrées) pour
contourner ça. La Live Activity se met à jour ligne par ligne. À tester sur CarPlay réel
pour voir laquelle donne le meilleur rendu — voir `LyricsLiveActivity.swift`.
