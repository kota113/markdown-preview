import Foundation

/// Controls CSS pretty wrapping in Read Mode, Edit Mode, and Quick Look.
/// Enabled by default to preserve the existing paragraph layout.
nonisolated enum PrettyTextWrappingSetting {
    static let defaultsKey = "MarkdownPreview.prettyTextWrapping"

    static var current: Bool {
        get { read(from: AppearanceMode.sharedDefaults()) }
        set { write(newValue, to: AppearanceMode.sharedDefaults()) }
    }

    static func read(from defaults: UserDefaults?) -> Bool {
        guard let defaults, let saved = defaults.object(forKey: defaultsKey) as? Bool else {
            return true
        }
        return saved
    }

    static func write(_ enabled: Bool, to defaults: UserDefaults?) {
        if enabled {
            defaults?.removeObject(forKey: defaultsKey)
        } else {
            defaults?.set(false, forKey: defaultsKey)
        }
    }
}
