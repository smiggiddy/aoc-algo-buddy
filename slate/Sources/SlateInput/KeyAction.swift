import Foundation

/// Every action a keybinding can trigger.
///
/// Names mirror Ghostty's `keybind` action names where one exists, so a Ghostty
/// config is mostly copy-pasteable and the mental model transfers. Actions that
/// have no desktop equivalent (or that iPadOS can't do) are marked.
public enum KeyAction: Hashable, Sendable, Codable {
    // MARK: Surfaces

    /// Ghostty: `new_window`. On iPadOS this requests a new
    /// `UIWindowScene`, which the system may decline (e.g. no Stage Manager).
    case newWindow
    case newTab
    case closeSurface
    case closeWindow

    case newSplit(SplitDirection)
    case gotoSplit(SplitTarget)
    case resizeSplit(SplitDirection, amount: UInt16)
    case equalizeSplits
    case toggleSplitZoom

    case gotoTab(Int)
    case nextTab
    case previousTab
    case moveTab(Int)

    // MARK: Clipboard & selection

    case copyToClipboard
    case pasteFromClipboard
    case selectAll
    case clearSelection

    // MARK: Scrollback

    case scrollPageUp
    case scrollPageDown
    case scrollToTop
    case scrollToBottom
    case scrollLineUp
    case scrollLineDown
    /// Ghostty: `jump_to_prompt`. Requires shell integration to have marked
    /// prompts (OSC 133); without it this is a no-op.
    case jumpToPrompt(Int)

    // MARK: Appearance

    case increaseFontSize(Double)
    case decreaseFontSize(Double)
    case resetFontSize

    // MARK: Terminal

    /// Ghostty: `clear_screen` — scroll the viewport clear, keeping scrollback.
    case clearScreen
    case reset
    /// Send a literal byte string to the backend (Ghostty: `text:`/`esc:`).
    case sendText(String)

    // MARK: App

    case openSettings
    case reloadConfig
    case toggleFullscreen
    case toggleCommandPalette
    case find

    public enum SplitDirection: String, Hashable, Sendable, Codable {
        case right, left, up, down
    }

    public enum SplitTarget: Hashable, Sendable, Codable {
        case direction(SplitDirection)
        case next
        case previous
    }
}

extension KeyAction {
    /// Short label for the command palette and the settings list.
    public var title: String {
        switch self {
        case .newWindow: "New Window"
        case .newTab: "New Tab"
        case .closeSurface: "Close Split"
        case .closeWindow: "Close Window"
        case .newSplit(let direction): "Split \(direction.rawValue.capitalized)"
        case .gotoSplit(.direction(let direction)): "Focus Split \(direction.rawValue.capitalized)"
        case .gotoSplit(.next): "Focus Next Split"
        case .gotoSplit(.previous): "Focus Previous Split"
        case .resizeSplit(let direction, _): "Resize Split \(direction.rawValue.capitalized)"
        case .equalizeSplits: "Equalize Splits"
        case .toggleSplitZoom: "Zoom Split"
        case .gotoTab(let index): "Go to Tab \(index)"
        case .nextTab: "Next Tab"
        case .previousTab: "Previous Tab"
        case .moveTab(let delta): delta > 0 ? "Move Tab Right" : "Move Tab Left"
        case .copyToClipboard: "Copy"
        case .pasteFromClipboard: "Paste"
        case .selectAll: "Select All"
        case .clearSelection: "Clear Selection"
        case .scrollPageUp: "Scroll Page Up"
        case .scrollPageDown: "Scroll Page Down"
        case .scrollToTop: "Scroll to Top"
        case .scrollToBottom: "Scroll to Bottom"
        case .scrollLineUp: "Scroll Line Up"
        case .scrollLineDown: "Scroll Line Down"
        case .jumpToPrompt(let delta): delta > 0 ? "Next Prompt" : "Previous Prompt"
        case .increaseFontSize: "Increase Font Size"
        case .decreaseFontSize: "Decrease Font Size"
        case .resetFontSize: "Reset Font Size"
        case .clearScreen: "Clear Screen"
        case .reset: "Reset Terminal"
        case .sendText: "Send Text"
        case .openSettings: "Settings"
        case .reloadConfig: "Reload Config"
        case .toggleFullscreen: "Toggle Full Screen"
        case .toggleCommandPalette: "Command Palette"
        case .find: "Find"
        }
    }

    /// SF Symbol for the command palette rows.
    public var symbolName: String {
        switch self {
        case .newWindow, .newTab: "plus.rectangle.on.rectangle"
        case .closeSurface, .closeWindow: "xmark.rectangle"
        case .newSplit, .equalizeSplits, .resizeSplit: "rectangle.split.2x1"
        case .gotoSplit, .toggleSplitZoom: "arrow.up.left.and.arrow.down.right"
        case .gotoTab, .nextTab, .previousTab, .moveTab: "rectangle.stack"
        case .copyToClipboard: "doc.on.doc"
        case .pasteFromClipboard: "doc.on.clipboard"
        case .selectAll, .clearSelection: "selection.pin.in.out"
        case .scrollPageUp, .scrollLineUp, .scrollToTop, .jumpToPrompt: "arrow.up"
        case .scrollPageDown, .scrollLineDown, .scrollToBottom: "arrow.down"
        case .increaseFontSize: "textformat.size.larger"
        case .decreaseFontSize: "textformat.size.smaller"
        case .resetFontSize: "textformat.size"
        case .clearScreen, .reset: "eraser"
        case .sendText: "keyboard"
        case .openSettings, .reloadConfig: "gearshape"
        case .toggleFullscreen: "arrow.up.left.and.arrow.down.right.rectangle"
        case .toggleCommandPalette: "command"
        case .find: "magnifyingglass"
        }
    }
}
