import Foundation
import Observation

/// Where a theme came from. User themes are `#rrggbb` JSON dropped into the
/// app's Documents directory, so they show up in the Files app.
public enum ThemeSource: Sendable, Hashable {
    case builtin
    case user(URL)
}

/// Observable appearance state: which theme is active (optionally split by
/// light/dark system appearance), plus the font settings the renderer needs.
@MainActor
@Observable
public final class ThemeStore {
    public private(set) var userThemes: [Theme] = []

    /// When true, `theme(for:)` follows the system appearance using
    /// `darkThemeName`/`lightThemeName`. When false, `darkThemeName` is used
    /// unconditionally — a terminal that changes colour mid-session is
    /// surprising, so this defaults off.
    public var followsSystemAppearance: Bool {
        didSet { defaults.set(followsSystemAppearance, forKey: Keys.followsSystem) }
    }

    public var darkThemeName: String {
        didSet { defaults.set(darkThemeName, forKey: Keys.darkTheme) }
    }

    public var lightThemeName: String {
        didSet { defaults.set(lightThemeName, forKey: Keys.lightTheme) }
    }

    public var fontName: String {
        didSet { defaults.set(fontName, forKey: Keys.fontName) }
    }

    public var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }

    /// Extra leading as a multiple of the font's natural line height.
    public var lineHeightMultiple: Double {
        didSet { defaults.set(lineHeightMultiple, forKey: Keys.lineHeight) }
    }

    /// Background opacity. Below 1 the Metal layer composites over the app
    /// chrome, which is how you get the frosted look on iPad.
    public var backgroundOpacity: Double {
        didSet { defaults.set(backgroundOpacity, forKey: Keys.backgroundOpacity) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let followsSystem = "slate.theme.followsSystem"
        static let darkTheme = "slate.theme.dark"
        static let lightTheme = "slate.theme.light"
        static let fontName = "slate.font.name"
        static let fontSize = "slate.font.size"
        static let lineHeight = "slate.font.lineHeight"
        static let backgroundOpacity = "slate.appearance.backgroundOpacity"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        followsSystemAppearance = defaults.bool(forKey: Keys.followsSystem)
        darkThemeName = defaults.string(forKey: Keys.darkTheme) ?? BuiltinThemes.default.name
        lightThemeName = defaults.string(forKey: Keys.lightTheme) ?? BuiltinThemes.catppuccinLatte.name
        fontName = defaults.string(forKey: Keys.fontName) ?? "SF Mono"
        fontSize = defaults.double(forKey: Keys.fontSize) > 0 ? defaults.double(forKey: Keys.fontSize) : 14
        lineHeightMultiple = defaults.double(forKey: Keys.lineHeight) > 0 ? defaults.double(forKey: Keys.lineHeight) : 1.2
        backgroundOpacity = defaults.object(forKey: Keys.backgroundOpacity) as? Double ?? 1.0
        reloadUserThemes()
    }

    /// Built-ins first, then anything the user dropped in Documents/Themes.
    public var availableThemes: [Theme] {
        BuiltinThemes.all + userThemes
    }

    public func theme(named name: String) -> Theme? {
        availableThemes.first { $0.name == name }
    }

    /// Resolves the active theme. `systemIsDark` comes from the environment's
    /// colour scheme at the call site.
    public func theme(systemIsDark: Bool) -> Theme {
        let name = (followsSystemAppearance && !systemIsDark) ? lightThemeName : darkThemeName
        return theme(named: name) ?? BuiltinThemes.default
    }

    // MARK: - User themes

    public static var userThemeDirectory: URL? {
        try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Themes", isDirectory: true)
    }

    /// Rescans Documents/Themes. Malformed files are skipped rather than
    /// surfaced as errors — one bad theme shouldn't stop the app launching.
    public func reloadUserThemes() {
        guard let directory = Self.userThemeDirectory else {
            userThemes = []
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []

        let decoder = JSONDecoder()
        userThemes = contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Theme.self, from: data)
            }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Font size, driven by the Ghostty-style keybindings

    public static let fontSizeRange: ClosedRange<Double> = 8...48
    private static let defaultFontSize: Double = 14

    public func adjustFontSize(by delta: Double) {
        fontSize = min(max(fontSize + delta, Self.fontSizeRange.lowerBound), Self.fontSizeRange.upperBound)
    }

    public func resetFontSize() {
        fontSize = Self.defaultFontSize
    }
}
