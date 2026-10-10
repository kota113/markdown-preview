//
//  AutoSaveSetting.swift
//  md-preview
//

import Foundation

/// Delay after the last editor change before autosaving (configured in Settings).
enum AutoSaveSetting {
    static let defaultsKey = "MarkdownPreview.autoSaveIntervalMinutes"
    // Preserve minute-based settings; negative sentinels identify sub-minute
    // choices without changing previously saved preferences.
    static let twoSeconds = -2
    static let thirtySeconds = -30
    static let disabledMinutes = 0
    static let minimumMinutes = 1
    static let maximumMinutes = 60

    static var currentMinutes: Int {
        currentMinutes(from: .standard)
    }

    static func currentMinutes(from defaults: UserDefaults) -> Int {
        guard let stored = defaults.object(forKey: defaultsKey) as? NSNumber else {
            return twoSeconds
        }
        return clampedMinutes(stored.intValue)
    }

    static func store(minutes: Int, in defaults: UserDefaults = .standard) {
        defaults.set(clampedMinutes(minutes), forKey: defaultsKey)
    }

    static func clampedMinutes(_ minutes: Int) -> Int {
        if minutes == twoSeconds || minutes == thirtySeconds { return minutes }
        guard minutes != disabledMinutes else { return disabledMinutes }
        return min(max(minutes, minimumMinutes), maximumMinutes)
    }

    static var interval: TimeInterval? {
        interval(for: currentMinutes)
    }

    static func interval(for minutes: Int) -> TimeInterval? {
        switch minutes {
        case disabledMinutes:
            return nil
        case twoSeconds:
            return 2
        case thirtySeconds:
            return 30
        default:
            return TimeInterval(minutes * 60)
        }
    }
}
