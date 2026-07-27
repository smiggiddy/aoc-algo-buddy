import Foundation

/// The themes that ship with Slate.
///
/// ANSI order is: black, red, green, yellow, blue, magenta, cyan, white,
/// then the eight bright variants.
public enum BuiltinThemes {
    public static let catppuccinMocha = Theme.make(
        "Catppuccin Mocha",
        background: "#1e1e2e",
        foreground: "#cdd6f4",
        cursor: "#f5e0dc",
        selection: "#45475a",
        ansi: [
            "#45475a", "#f38ba8", "#a6e3a1", "#f9e2af",
            "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de",
            "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af",
            "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8",
        ]
    )

    public static let catppuccinLatte = Theme.make(
        "Catppuccin Latte",
        background: "#eff1f5",
        foreground: "#4c4f69",
        cursor: "#dc8a78",
        selection: "#ccd0da",
        ansi: [
            "#5c5f77", "#d20f39", "#40a02b", "#df8e1d",
            "#1e66f5", "#ea76cb", "#179299", "#acb0be",
            "#6c6f85", "#d20f39", "#40a02b", "#df8e1d",
            "#1e66f5", "#ea76cb", "#179299", "#bcc0cc",
        ]
    )

    public static let tokyoNight = Theme.make(
        "Tokyo Night",
        background: "#1a1b26",
        foreground: "#c0caf5",
        cursor: "#c0caf5",
        selection: "#283457",
        ansi: [
            "#15161e", "#f7768e", "#9ece6a", "#e0af68",
            "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6",
            "#414868", "#f7768e", "#9ece6a", "#e0af68",
            "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5",
        ]
    )

    public static let rosePine = Theme.make(
        "Rosé Pine",
        background: "#191724",
        foreground: "#e0def4",
        cursor: "#524f67",
        selection: "#403d52",
        ansi: [
            "#26233a", "#eb6f92", "#31748f", "#f6c177",
            "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4",
            "#6e6a86", "#eb6f92", "#31748f", "#f6c177",
            "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4",
        ]
    )

    public static let nord = Theme.make(
        "Nord",
        background: "#2e3440",
        foreground: "#d8dee9",
        cursor: "#d8dee9",
        selection: "#434c5e",
        ansi: [
            "#3b4252", "#bf616a", "#a3be8c", "#ebcb8b",
            "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0",
            "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b",
            "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4",
        ]
    )

    public static let gruvboxDark = Theme.make(
        "Gruvbox Dark",
        background: "#282828",
        foreground: "#ebdbb2",
        cursor: "#ebdbb2",
        selection: "#504945",
        ansi: [
            "#282828", "#cc241d", "#98971a", "#d79921",
            "#458588", "#b16286", "#689d6a", "#a89984",
            "#928374", "#fb4934", "#b8bb26", "#fabd2f",
            "#83a598", "#d3869b", "#8ec07c", "#ebdbb2",
        ]
    )

    public static let everforestDark = Theme.make(
        "Everforest Dark",
        background: "#2d353b",
        foreground: "#d3c6aa",
        cursor: "#d3c6aa",
        selection: "#475258",
        ansi: [
            "#343f44", "#e67e80", "#a7c080", "#dbbc7f",
            "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa",
            "#859289", "#e67e80", "#a7c080", "#dbbc7f",
            "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa",
        ]
    )

    public static let dracula = Theme.make(
        "Dracula",
        background: "#282a36",
        foreground: "#f8f8f2",
        cursor: "#f8f8f2",
        selection: "#44475a",
        ansi: [
            "#21222c", "#ff5555", "#50fa7b", "#f1fa8c",
            "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2",
            "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5",
            "#d6acff", "#ff92df", "#a4ffff", "#ffffff",
        ]
    )

    public static let oneDark = Theme.make(
        "One Dark",
        background: "#282c34",
        foreground: "#abb2bf",
        cursor: "#528bff",
        selection: "#3e4451",
        ansi: [
            "#282c34", "#e06c75", "#98c379", "#e5c07b",
            "#61afef", "#c678dd", "#56b6c2", "#abb2bf",
            "#5c6370", "#e06c75", "#98c379", "#e5c07b",
            "#61afef", "#c678dd", "#56b6c2", "#ffffff",
        ]
    )

    public static let solarizedLight = Theme.make(
        "Solarized Light",
        background: "#fdf6e3",
        foreground: "#657b83",
        cursor: "#586e75",
        selection: "#eee8d5",
        ansi: [
            "#073642", "#dc322f", "#859900", "#b58900",
            "#268bd2", "#d33682", "#2aa198", "#eee8d5",
            "#002b36", "#cb4b16", "#586e75", "#657b83",
            "#839496", "#6c71c4", "#93a1a1", "#fdf6e3",
        ]
    )

    /// Presentation order in the theme picker: modern-first, then classics.
    public static let all: [Theme] = [
        catppuccinMocha,
        tokyoNight,
        rosePine,
        everforestDark,
        catppuccinLatte,
        nord,
        gruvboxDark,
        dracula,
        oneDark,
        solarizedLight,
    ]

    public static let `default` = catppuccinMocha

    public static func named(_ name: String) -> Theme? {
        all.first { $0.name == name }
    }
}
