import Foundation

/// Slate's default keymap, modelled on Ghostty's macOS defaults.
///
/// Ghostty on macOS binds almost everything to `super` (⌘), which maps cleanly
/// to an iPad Magic Keyboard. Bindings that only make sense on a desktop are
/// noted; a handful of iPad-only additions are marked `[iPad]`.
///
/// The rule of thumb: if muscle memory from Ghostty desktop would fire it,
/// it should work here.
public enum DefaultKeybindings {
    public static let all: [Keybinding] = [
        // MARK: - Windows, tabs, splits

        Keybinding(Chord(.n, [.super]), .newWindow),
        Keybinding(Chord(.t, [.super]), .newTab),
        Keybinding(Chord(.w, [.super]), .closeSurface),
        Keybinding(Chord(.w, [.super, .shift]), .closeWindow),

        Keybinding(Chord(.d, [.super]), .newSplit(.right)),
        Keybinding(Chord(.d, [.super, .shift]), .newSplit(.down)),

        Keybinding(Chord(.left, [.super, .alt]), .gotoSplit(.direction(.left))),
        Keybinding(Chord(.right, [.super, .alt]), .gotoSplit(.direction(.right))),
        Keybinding(Chord(.up, [.super, .alt]), .gotoSplit(.direction(.up))),
        Keybinding(Chord(.down, [.super, .alt]), .gotoSplit(.direction(.down))),
        Keybinding(Chord(.bracketLeft, [.super]), .gotoSplit(.previous)),
        Keybinding(Chord(.bracketRight, [.super]), .gotoSplit(.next)),

        Keybinding(Chord(.left, [.super, .control]), .resizeSplit(.left, amount: 10)),
        Keybinding(Chord(.right, [.super, .control]), .resizeSplit(.right, amount: 10)),
        Keybinding(Chord(.up, [.super, .control]), .resizeSplit(.up, amount: 10)),
        Keybinding(Chord(.down, [.super, .control]), .resizeSplit(.down, amount: 10)),
        Keybinding(Chord(.enter, [.super, .shift]), .toggleSplitZoom),

        Keybinding(Chord(.bracketLeft, [.super, .shift]), .previousTab),
        Keybinding(Chord(.bracketRight, [.super, .shift]), .nextTab),

        Keybinding(Chord(.one, [.super]), .gotoTab(1)),
        Keybinding(Chord(.two, [.super]), .gotoTab(2)),
        Keybinding(Chord(.three, [.super]), .gotoTab(3)),
        Keybinding(Chord(.four, [.super]), .gotoTab(4)),
        Keybinding(Chord(.five, [.super]), .gotoTab(5)),
        Keybinding(Chord(.six, [.super]), .gotoTab(6)),
        Keybinding(Chord(.seven, [.super]), .gotoTab(7)),
        Keybinding(Chord(.eight, [.super]), .gotoTab(8)),
        // Ghostty binds super+9 to "last tab", not "tab 9".
        Keybinding(Chord(.nine, [.super]), .gotoTab(-1)),

        // MARK: - Clipboard

        Keybinding(Chord(.c, [.super]), .copyToClipboard),
        Keybinding(Chord(.v, [.super]), .pasteFromClipboard),
        Keybinding(Chord(.a, [.super]), .selectAll),

        // MARK: - Scrollback

        Keybinding(Chord(.pageUp, [.shift]), .scrollPageUp),
        Keybinding(Chord(.pageDown, [.shift]), .scrollPageDown),
        Keybinding(Chord(.home, [.super]), .scrollToTop),
        Keybinding(Chord(.end, [.super]), .scrollToBottom),
        Keybinding(Chord(.up, [.super, .shift]), .jumpToPrompt(-1)),
        Keybinding(Chord(.down, [.super, .shift]), .jumpToPrompt(1)),

        // MARK: - Font size
        //
        // Ghostty binds both super+plus and super+equal, because on a US layout
        // the unshifted key is `=` and users reach for it either way.

        Keybinding(Chord(.equal, [.super]), .increaseFontSize(1)),
        Keybinding(Chord(.keypadPlus, [.super]), .increaseFontSize(1)),
        Keybinding(Chord(.minus, [.super]), .decreaseFontSize(1)),
        Keybinding(Chord(.zero, [.super]), .resetFontSize),

        // MARK: - Terminal

        Keybinding(Chord(.k, [.super]), .clearScreen),

        // MARK: - App

        Keybinding(Chord(.comma, [.super]), .openSettings),
        Keybinding(Chord(.comma, [.super, .shift]), .reloadConfig),
        Keybinding(Chord(.enter, [.super]), .toggleFullscreen),
        Keybinding(Chord(.p, [.super, .shift]), .toggleCommandPalette),
        Keybinding(Chord(.f, [.super]), .find),
    ]

    public static var keymap: Keymap { Keymap(all) }

    /// Chords Slate must not swallow before the terminal sees them.
    ///
    /// On iPadOS, `UIKeyCommand` steals a chord app-wide. A terminal needs
    /// ⌃-anything to reach the shell (⌃C, ⌃D, ⌃Z…), and ⌥-anything to reach it
    /// as a meta prefix. So we only ever register ⌘-based chords as key
    /// commands and let everything else fall through to the key encoder.
    public static func isReservedForApp(_ chord: Chord) -> Bool {
        chord.mods.contains(.super)
    }
}

/// The keys the on-screen accessory bar exposes. iPadOS software keyboards have
/// no Esc, Ctrl, Tab, or arrow cluster, and those are exactly the keys a
/// terminal cannot live without.
public enum AccessoryKey: String, CaseIterable, Sendable, Identifiable {
    case escape, control, alt, tab
    case left, down, up, right
    case home, end, pageUp, pageDown

    public var id: String { rawValue }

    /// Sticky modifiers latch for the next keypress; the rest send immediately.
    public var isStickyModifier: Bool {
        self == .control || self == .alt
    }

    public var key: SlateKey? {
        switch self {
        case .escape: .escape
        case .tab: .tab
        case .left: .left
        case .down: .down
        case .up: .up
        case .right: .right
        case .home: .home
        case .end: .end
        case .pageUp: .pageUp
        case .pageDown: .pageDown
        case .control, .alt: nil
        }
    }

    public var label: String {
        switch self {
        case .escape: "esc"
        case .control: "ctrl"
        case .alt: "alt"
        case .tab: "⇥"
        case .left: "←"
        case .down: "↓"
        case .up: "↑"
        case .right: "→"
        case .home: "↖"
        case .end: "↘"
        case .pageUp: "⇞"
        case .pageDown: "⇟"
        }
    }
}
