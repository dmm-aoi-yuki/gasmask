import Foundation

/// Manages per-hosts-file status bar icon preferences stored in UserDefaults.
@objc final class StatusBarIconStore: NSObject {
    @objc static let iconChangedNotification = NSNotification.Name("StatusBarIconChangedNotification")

    private static let userDefaultsKey = "statusBarIcons"

    @objc static func iconName(forHostsPath path: String) -> String? {
        let dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String]
        return dict?[path]
    }

    @objc static func setIconName(_ name: String?, forHostsPath path: String) {
        var dict = (UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String]) ?? [:]
        dict[path] = name
        UserDefaults.standard.set(dict, forKey: userDefaultsKey)
        NotificationCenter.default.post(name: iconChangedNotification, object: nil)
    }

    @objc static func iconNameForActiveHosts() -> String? {
        guard let path = Preferences.activeHostsFile() else { return nil }
        return iconName(forHostsPath: path)
    }
}
