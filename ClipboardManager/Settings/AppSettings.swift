import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private let defaults: UserDefaults
    private enum Key { static let historyLimit = "historyLimit"; static let launchAtLogin = "launchAtLogin"; static let moveSelectedToTop = "moveSelectedToTop"; static let playCopySound = "playCopySound" }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var historyLimit: Int {
        get { max(10, min(100, defaults.object(forKey: Key.historyLimit) as? Int ?? 20)) }
        set { defaults.set(max(10, min(100, newValue)), forKey: Key.historyLimit) }
    }
    var launchAtLogin: Bool { get { defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false } set { defaults.set(newValue, forKey: Key.launchAtLogin) } }
    var moveSelectedToTop: Bool { get { defaults.object(forKey: Key.moveSelectedToTop) as? Bool ?? true } set { defaults.set(newValue, forKey: Key.moveSelectedToTop) } }
    var playCopySound: Bool { get { defaults.object(forKey: Key.playCopySound) as? Bool ?? false } set { defaults.set(newValue, forKey: Key.playCopySound) } }
}
