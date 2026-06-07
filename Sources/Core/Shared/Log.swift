import Foundation
import os

/// Loggers par catégorie pour débugger via Console.app / Xcode.
/// Filtre dans la console avec le subsystem `com.adamhaouzi.livelyrics`.
public enum Log {
    private static let subsystem = "com.adamhaouzi.livelyrics"

    public static let music    = Logger(subsystem: subsystem, category: "music")
    public static let lyrics   = Logger(subsystem: subsystem, category: "lyrics")
    public static let sync     = Logger(subsystem: subsystem, category: "sync")
    public static let widget   = Logger(subsystem: subsystem, category: "widget")
    public static let activity = Logger(subsystem: subsystem, category: "activity")
}
