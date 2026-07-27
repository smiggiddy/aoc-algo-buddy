import Foundation

/// A physical key, named the way Ghostty's config names them (W3C
/// `KeyboardEvent.code` semantics — position, not the character produced).
///
/// This deliberately does not import GhosttyKit: `SlateInput` stays a pure
/// value layer, and `SlateTerminal` owns the translation to `GhosttyKey`.
public enum SlateKey: String, Hashable, Sendable, Codable, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z

    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"

    case minus, equal
    case bracketLeft = "bracket_left", bracketRight = "bracket_right"
    case backslash, semicolon, quote, comma, period, slash, backquote

    case escape, enter, tab, space, backspace, delete
    case home, end, pageUp = "page_up", pageDown = "page_down", insert

    case up, down, left, right

    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12

    /// Ghostty writes these as `plus`; on most layouts it's shift+equal, but
    /// the numeric keypad has a real one and iPadOS reports it distinctly.
    case keypadPlus = "keypad_plus"
    case keypadMinus = "keypad_minus"
}

/// Modifier flags, matching Ghostty's naming. `super` is Command on Apple
/// platforms — on an iPad this is the Magic Keyboard's ⌘.
public struct Modifiers: OptionSet, Hashable, Sendable, Codable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = Modifiers(rawValue: 1 << 0)
    public static let control = Modifiers(rawValue: 1 << 1)
    public static let alt = Modifiers(rawValue: 1 << 2)
    public static let `super` = Modifiers(rawValue: 1 << 3)

    /// Ghostty config spellings, longest-first so `super` doesn't shadow `s`.
    static let parseTable: [(String, Modifiers)] = [
        ("super", .super), ("cmd", .super), ("command", .super),
        ("control", .control), ("ctrl", .control),
        ("shift", .shift),
        ("alt", .alt), ("opt", .alt), ("option", .alt),
    ]

    /// Rendered with the glyphs iPadOS uses in the ⌘-held shortcut overlay.
    public var displayString: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.alt) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.super) { result += "⌘" }
        return result
    }
}

/// A key chord: one physical key plus modifiers.
public struct Chord: Hashable, Sendable, Codable {
    public var key: SlateKey
    public var mods: Modifiers

    public init(_ key: SlateKey, _ mods: Modifiers = []) {
        self.key = key
        self.mods = mods
    }

    /// Parses Ghostty's `keybind` trigger syntax, e.g. `super+shift+d`.
    /// Returns nil rather than throwing so a bad line in a user config can be
    /// skipped with a warning instead of failing the whole load.
    public init?(parsing text: String) {
        let parts = text.lowercased().split(separator: "+").map(String.init)
        guard let last = parts.last else { return nil }

        var mods: Modifiers = []
        for part in parts.dropLast() {
            guard let match = Modifiers.parseTable.first(where: { $0.0 == part }) else { return nil }
            mods.insert(match.1)
        }

        guard let key = SlateKey(parsing: last) else { return nil }
        self.init(key, mods)
    }

    public var displayString: String {
        mods.displayString + key.displayString
    }
}

extension SlateKey {
    /// Accepts both the canonical rawValue and the aliases Ghostty configs use.
    init?(parsing text: String) {
        if let key = SlateKey(rawValue: text) {
            self = key
            return
        }
        switch text {
        case "return": self = .enter
        case "esc": self = .escape
        case "bracketleft", "[": self = .bracketLeft
        case "bracketright", "]": self = .bracketRight
        case "grave", "`": self = .backquote
        case "plus", "+": self = .keypadPlus
        case "-": self = .minus
        case "=": self = .equal
        case ",": self = .comma
        case ".": self = .period
        case "/": self = .slash
        case ";": self = .semicolon
        case "'": self = .quote
        case "\\": self = .backslash
        case "arrow_up": self = .up
        case "arrow_down": self = .down
        case "arrow_left": self = .left
        case "arrow_right": self = .right
        default: return nil
        }
    }

    /// How the key is drawn in the shortcut list and command palette.
    public var displayString: String {
        switch self {
        case .escape: "esc"
        case .enter: "↩"
        case .tab: "⇥"
        case .space: "space"
        case .backspace: "⌫"
        case .delete: "⌦"
        case .up: "↑"
        case .down: "↓"
        case .left: "←"
        case .right: "→"
        case .pageUp: "⇞"
        case .pageDown: "⇟"
        case .home: "↖"
        case .end: "↘"
        case .bracketLeft: "["
        case .bracketRight: "]"
        case .minus, .keypadMinus: "−"
        case .equal: "="
        case .keypadPlus: "+"
        case .comma: ","
        case .period: "."
        case .slash: "/"
        case .backslash: "\\"
        case .semicolon: ";"
        case .quote: "'"
        case .backquote: "`"
        default: rawValue.uppercased()
        }
    }
}

/// A chord bound to an action.
public struct Keybinding: Hashable, Sendable, Codable, Identifiable {
    public var chord: Chord
    public var action: KeyAction

    public var id: Chord { chord }

    public init(_ chord: Chord, _ action: KeyAction) {
        self.chord = chord
        self.action = action
    }
}

/// The active keymap. Last binding for a chord wins, which is what lets a user
/// config override a default by simply restating the chord.
public struct Keymap: Sendable {
    private var table: [Chord: KeyAction]

    public init(_ bindings: [Keybinding]) {
        table = bindings.reduce(into: [:]) { $0[$1.chord] = $1.action }
    }

    public func action(for chord: Chord) -> KeyAction? {
        table[chord]
    }

    /// All bindings, sorted for display.
    public var bindings: [Keybinding] {
        table
            .map { Keybinding($0.key, $0.value) }
            .sorted { $0.action.title < $1.action.title }
    }

    public mutating func bind(_ chord: Chord, to action: KeyAction) {
        table[chord] = action
    }

    public mutating func unbind(_ chord: Chord) {
        table[chord] = nil
    }

    /// Applies `keybind = trigger=action` lines from a user config on top of
    /// the current map. Returns the lines that couldn't be parsed.
    @discardableResult
    public mutating func apply(configLines lines: [String]) -> [String] {
        var rejected: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let body = trimmed.hasPrefix("keybind")
                ? trimmed.drop(while: { $0 != "=" }).dropFirst()
                : Substring(trimmed)

            let halves = body.split(separator: "=", maxSplits: 1)
            guard halves.count == 2,
                  let chord = Chord(parsing: halves[0].trimmingCharacters(in: .whitespaces)),
                  let action = KeyAction(configName: halves[1].trimmingCharacters(in: .whitespaces))
            else {
                rejected.append(line)
                continue
            }

            if action == .unbind {
                table[chord] = nil
            } else {
                table[chord] = action
            }
        }
        return rejected
    }
}

extension KeyAction {
    /// Sentinel used by `Keymap.apply` for Ghostty's `unbind` action.
    static let unbind = KeyAction.sendText("\u{0}__slate_unbind__")

    /// Parses Ghostty's action syntax. Covers the actions Slate implements;
    /// anything else returns nil and the line is reported as rejected.
    init?(configName text: String) {
        // Parameterised forms: `goto_tab:3`, `text:hello`, `new_split:right`.
        let parts = text.split(separator: ":", maxSplits: 1)
        let name = String(parts[0])
        let argument = parts.count > 1 ? String(parts[1]) : nil

        switch (name, argument) {
        case ("unbind", _): self = .unbind
        case ("new_window", _): self = .newWindow
        case ("new_tab", _): self = .newTab
        case ("close_surface", _): self = .closeSurface
        case ("close_window", _): self = .closeWindow
        case ("new_split", let direction?):
            guard let value = SplitDirection(rawValue: direction) else { return nil }
            self = .newSplit(value)
        case ("goto_split", let target?):
            switch target {
            case "next": self = .gotoSplit(.next)
            case "previous": self = .gotoSplit(.previous)
            default:
                guard let value = SplitDirection(rawValue: target) else { return nil }
                self = .gotoSplit(.direction(value))
            }
        case ("resize_split", let argument?):
            let fields = argument.split(separator: ",")
            guard fields.count == 2,
                  let direction = SplitDirection(rawValue: String(fields[0])),
                  let amount = UInt16(fields[1])
            else { return nil }
            self = .resizeSplit(direction, amount: amount)
        case ("equalize_splits", _): self = .equalizeSplits
        case ("toggle_split_zoom", _): self = .toggleSplitZoom
        case ("goto_tab", let index?):
            guard let value = Int(index) else { return nil }
            self = .gotoTab(value)
        case ("next_tab", _): self = .nextTab
        case ("previous_tab", _): self = .previousTab
        case ("move_tab", let delta?):
            guard let value = Int(delta) else { return nil }
            self = .moveTab(value)
        case ("copy_to_clipboard", _): self = .copyToClipboard
        case ("paste_from_clipboard", _): self = .pasteFromClipboard
        case ("select_all", _): self = .selectAll
        case ("scroll_page_up", _): self = .scrollPageUp
        case ("scroll_page_down", _): self = .scrollPageDown
        case ("scroll_to_top", _): self = .scrollToTop
        case ("scroll_to_bottom", _): self = .scrollToBottom
        case ("jump_to_prompt", let delta?):
            guard let value = Int(delta) else { return nil }
            self = .jumpToPrompt(value)
        case ("increase_font_size", let amount):
            self = .increaseFontSize(amount.flatMap(Double.init) ?? 1)
        case ("decrease_font_size", let amount):
            self = .decreaseFontSize(amount.flatMap(Double.init) ?? 1)
        case ("reset_font_size", _): self = .resetFontSize
        case ("clear_screen", _): self = .clearScreen
        case ("reset", _): self = .reset
        case ("text", let value?): self = .sendText(value)
        case ("open_config", _): self = .openSettings
        case ("reload_config", _): self = .reloadConfig
        case ("toggle_fullscreen", _): self = .toggleFullscreen
        case ("toggle_command_palette", _): self = .toggleCommandPalette
        case ("find", _): self = .find
        default: return nil
        }
    }
}
