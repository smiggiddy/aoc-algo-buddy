import Foundation
import Observation
import SlateIO
import SlateInput
import SlateTerminal
import SlateTheme
import UIKit

/// A tab: a split tree plus which pane is focused.
@MainActor
@Observable
public final class TerminalTab: Identifiable {
    public let id = UUID()
    public var root: SplitNode
    public var focusedSurfaceID: UUID
    /// Set by ⌘⇧↩; the zoomed pane fills the tab until it's toggled off.
    public var zoomedSurfaceID: UUID?

    public init(surface: TerminalSurface) {
        root = .leaf(surface)
        focusedSurfaceID = surface.id
    }

    public var focusedSurface: TerminalSurface? {
        root.surfaces.first { $0.id == focusedSurfaceID }
    }

    public var title: String {
        focusedSurface?.title ?? "Terminal"
    }

    public var hasUnreadBell: Bool {
        root.surfaces.contains(where: \.hasUnreadBell)
    }
}

/// Owns the window's tabs and turns `KeyAction`s into state changes.
///
/// This is the only place that knows about tabs *and* splits *and* settings, so
/// it's the natural home for action dispatch — the views stay declarative and
/// the terminal layer stays ignorant of UI.
@MainActor
@Observable
public final class AppModel {
    public private(set) var tabs: [TerminalTab] = []
    public var selectedTabID: UUID?

    public var isShowingSettings = false
    public var isShowingCommandPalette = false

    /// Modifiers latched by the accessory bar, applied to the next key and then
    /// cleared. Lives here rather than in the view so it survives a split
    /// changing focus mid-chord.
    public var stickyModifiers: Modifiers = []

    public let themeStore: ThemeStore
    public private(set) var keymap: Keymap

    /// Bumped whenever the font changes, so terminal views know to rebuild
    /// their atlas. Cheaper than threading a callback through every split.
    public private(set) var fontGeneration = 0

    public init(themeStore: ThemeStore = ThemeStore()) {
        self.themeStore = themeStore
        keymap = DefaultKeybindings.keymap
        loadUserKeybindings()
        newTab()
    }

    public var selectedTab: TerminalTab? {
        tabs.first { $0.id == selectedTabID }
    }

    public var focusedSurface: TerminalSurface? {
        selectedTab?.focusedSurface
    }

    public func theme(systemIsDark: Bool) -> Theme {
        themeStore.theme(systemIsDark: systemIsDark)
    }

    // MARK: - Surfaces

    private func makeSurface() -> TerminalSurface? {
        guard let surface = try? TerminalSurface(theme: themeStore.theme(systemIsDark: true)) else {
            return nil
        }
        Task {
            // The built-in shell is the default so a fresh build runs. Swap for
            // IOSSystemBackend once the framework is vendored.
            await surface.attach(BuiltinShellBackend(), size: TerminalSize(columns: 80, rows: 24))
        }
        return surface
    }

    @discardableResult
    public func newTab() -> TerminalTab? {
        guard let surface = makeSurface() else { return nil }
        let tab = TerminalTab(surface: surface)
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    public func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        tabs[index].root.surfaces.forEach { $0.detach() }
        tabs.remove(at: index)

        if selectedTabID == tabID {
            selectedTabID = tabs[safe: index]?.id ?? tabs.last?.id
        }
        if tabs.isEmpty { newTab() }
    }

    public func closeFocusedSurface() {
        guard let tab = selectedTab, let surface = tab.focusedSurface else { return }

        guard let remaining = tab.root.removing(surface.id) else {
            // Last split in the tab: closing it closes the tab.
            closeTab(tab.id)
            return
        }
        surface.detach()
        tab.root = remaining
        tab.zoomedSurfaceID = nil
        tab.focusedSurfaceID = remaining.surfaces.first?.id ?? tab.focusedSurfaceID
    }

    // MARK: - Action dispatch

    /// Returns true if the action was handled. A false return lets the key fall
    /// through to the terminal, which matters for chords we don't implement.
    @discardableResult
    public func perform(_ action: KeyAction) -> Bool {
        switch action {
        case .newWindow:
            requestNewWindow()

        case .newTab:
            newTab()

        case .closeSurface:
            closeFocusedSurface()

        case .closeWindow:
            guard let tab = selectedTab else { return false }
            closeTab(tab.id)

        case .newSplit(let direction):
            split(direction: SplitDirection(direction))

        case .gotoSplit(let target):
            focusSplit(target)

        case .resizeSplit, .equalizeSplits:
            // Splits are drag-resizable; keyboard resize needs the geometry
            // that only the view hierarchy has. Left unhandled on purpose
            // rather than silently doing nothing surprising.
            return false

        case .toggleSplitZoom:
            guard let tab = selectedTab else { return false }
            tab.zoomedSurfaceID = tab.zoomedSurfaceID == nil ? tab.focusedSurfaceID : nil

        case .gotoTab(let index):
            if index == -1 {
                selectedTabID = tabs.last?.id
            } else if let tab = tabs[safe: index - 1] {
                selectedTabID = tab.id
            }

        case .nextTab:
            cycleTab(by: 1)

        case .previousTab:
            cycleTab(by: -1)

        case .moveTab(let delta):
            moveTab(by: delta)

        case .copyToClipboard:
            // Selection lives in libghostty; until the selection UI lands this
            // copies nothing rather than copying the wrong thing.
            return false

        case .pasteFromClipboard:
            guard let text = UIPasteboard.general.string else { return false }
            focusedSurface?.paste(text)

        case .selectAll, .clearSelection:
            return false

        case .scrollPageUp:
            focusedSurface?.scroll(.delta(-Int(pageSize)))

        case .scrollPageDown:
            focusedSurface?.scroll(.delta(Int(pageSize)))

        case .scrollLineUp:
            focusedSurface?.scroll(.delta(-1))

        case .scrollLineDown:
            focusedSurface?.scroll(.delta(1))

        case .scrollToTop:
            focusedSurface?.scroll(.top)

        case .scrollToBottom:
            focusedSurface?.scroll(.bottom)

        case .jumpToPrompt:
            // Needs OSC 133 prompt marks from shell integration.
            return false

        case .increaseFontSize(let amount):
            themeStore.adjustFontSize(by: amount)
            fontGeneration += 1

        case .decreaseFontSize(let amount):
            themeStore.adjustFontSize(by: -amount)
            fontGeneration += 1

        case .resetFontSize:
            themeStore.resetFontSize()
            fontGeneration += 1

        case .clearScreen:
            focusedSurface?.clearScreen()

        case .reset:
            focusedSurface?.resetTerminal()

        case .sendText(let text):
            focusedSurface?.send(text: text)

        case .openSettings:
            isShowingSettings = true

        case .reloadConfig:
            themeStore.reloadUserThemes()
            loadUserKeybindings()

        case .toggleCommandPalette:
            isShowingCommandPalette.toggle()

        case .toggleFullscreen, .find:
            return false
        }
        return true
    }

    /// Sends a key from the on-screen accessory bar, applying and clearing any
    /// latched modifiers.
    public func sendAccessoryKey(_ key: SlateKey) {
        guard let surface = focusedSurface else { return }
        let mods = stickyModifiers
        stickyModifiers = []
        _ = surface.send(key: key, mods: mods)
    }

    public func toggleSticky(_ modifier: Modifiers) {
        stickyModifiers.formSymmetricDifference(modifier)
    }

    /// Tells every terminal view to rebuild its glyph atlas and re-measure the
    /// grid. Called when the font changes from Settings rather than a keybind.
    public func notifyFontChanged() {
        fontGeneration += 1
    }

    /// Rows to move for a page scroll. Uses the focused surface's height so a
    /// tall split pages further than a short one.
    private var pageSize: Int {
        max(1, (focusedSurface?.snapshot.rowCount ?? 24) - 1)
    }

    // MARK: - Splits

    private func split(direction: SplitDirection) {
        guard let tab = selectedTab,
              let focused = tab.focusedSurface,
              let surface = makeSurface()
        else { return }

        var root = tab.root
        guard root.split(focused.id, with: surface, direction: direction) else { return }
        tab.root = root
        tab.focusedSurfaceID = surface.id
        tab.zoomedSurfaceID = nil
    }

    private func focusSplit(_ target: KeyAction.SplitTarget) {
        guard let tab = selectedTab else { return }
        let surfaces = tab.root.surfaces
        guard surfaces.count > 1 else { return }

        switch target {
        case .direction(let direction):
            if let neighbor = tab.root.neighbor(of: tab.focusedSurfaceID, direction: SplitDirection(direction)) {
                tab.focusedSurfaceID = neighbor.id
            }
        case .next, .previous:
            guard let index = surfaces.firstIndex(where: { $0.id == tab.focusedSurfaceID }) else { return }
            let offset = target == .next ? 1 : -1
            let next = (index + offset + surfaces.count) % surfaces.count
            tab.focusedSurfaceID = surfaces[next].id
        }
        tab.zoomedSurfaceID = nil
    }

    // MARK: - Tabs

    private func cycleTab(by offset: Int) {
        guard !tabs.isEmpty, let current = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        let next = (current + offset + tabs.count) % tabs.count
        selectedTabID = tabs[next].id
    }

    private func moveTab(by delta: Int) {
        guard let current = tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }
        let target = min(max(current + delta, 0), tabs.count - 1)
        guard target != current else { return }
        tabs.swapAt(current, target)
    }

    private func requestNewWindow() {
        // Stage Manager and iPad multitasking only; the system declines on
        // devices or configurations that can't show a second scene.
        let activity = NSUserActivity(activityType: "dev.slate.terminal.window")
        UIApplication.shared.requestSceneSessionActivation(
            nil,
            userActivity: activity,
            options: nil
        )
    }

    // MARK: - User config

    /// Reads `Documents/keybindings.conf` — Ghostty `keybind` syntax, one per
    /// line — and layers it over the defaults.
    public func loadUserKeybindings() {
        var map = DefaultKeybindings.keymap
        defer { keymap = map }

        guard let directory = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return }

        let url = directory.appendingPathComponent("keybindings.conf")
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return }
        map.apply(configLines: contents.components(separatedBy: .newlines))
    }
}

extension SplitDirection {
    init(_ direction: KeyAction.SplitDirection) {
        switch direction {
        case .left: self = .left
        case .right: self = .right
        case .up: self = .up
        case .down: self = .down
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
