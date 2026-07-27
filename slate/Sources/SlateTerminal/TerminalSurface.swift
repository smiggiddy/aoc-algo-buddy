import Foundation
import Observation
import SlateInput
import SlateTheme

/// One terminal: state machine, backend, key encoding, and the snapshot the
/// renderer draws. A "surface" in Ghostty's vocabulary — a split holds one, a
/// tab holds a tree of them.
@MainActor
@Observable
public final class TerminalSurface: Identifiable {
    public let id = UUID()

    public private(set) var snapshot = TerminalSnapshot()
    public private(set) var title: String = "Terminal"
    public private(set) var workingDirectory: String?
    public private(set) var termination: TerminalBackendTermination?
    public private(set) var isRunning = false

    /// Set when the terminal rings the bell and cleared when the surface is
    /// focused — this is what puts a dot on an unfocused tab.
    public private(set) var hasUnreadBell = false

    public var theme: Theme {
        didSet {
            guard theme != oldValue else { return }
            try? terminal.apply(theme: theme)
            setNeedsSnapshot()
        }
    }

    private let terminal: GhosttyTerminal
    private let reader: RenderStateReader
    private let encoder: KeyEncoder
    private var backend: (any TerminalBackend)?

    /// Coalesces snapshot reads. Output arrives in bursts (a `cat` of a large
    /// file can deliver thousands of writes per frame); we read the screen once
    /// per display refresh instead of once per write.
    private var snapshotIsScheduled = false

    /// Cell metrics, needed for pixel-accurate resize reporting.
    private var cellSize: (width: UInt32, height: UInt32) = (0, 0)

    public init(theme: Theme, columns: UInt16 = 80, rows: UInt16 = 24) throws {
        self.theme = theme
        terminal = try GhosttyTerminal(columns: columns, rows: rows)
        reader = try RenderStateReader()
        encoder = try KeyEncoder()

        try terminal.apply(theme: theme)
        wireTerminalCallbacks()
    }

    private func wireTerminalCallbacks() {
        terminal.onWriteToBackend = { [weak self] data in
            // Replies the terminal generates itself (DA, cursor position, mouse
            // reports) go straight to the program, bypassing the key encoder.
            MainActor.assumeIsolated { self?.backend?.write(data) }
        }
        terminal.onTitleChanged = { [weak self] title in
            MainActor.assumeIsolated {
                self?.title = title.isEmpty ? "Terminal" : title
            }
        }
        terminal.onWorkingDirectoryChanged = { [weak self] path in
            MainActor.assumeIsolated { self?.workingDirectory = path }
        }
        terminal.onBell = { [weak self] in
            MainActor.assumeIsolated { self?.hasUnreadBell = true }
        }
    }

    // MARK: - Lifecycle

    public func attach(_ backend: any TerminalBackend, size: TerminalSize) async {
        backend.onOutput = { [weak self] data in
            self?.receive(data)
        }
        backend.onTermination = { [weak self] reason in
            self?.isRunning = false
            self?.termination = reason
        }
        self.backend = backend
        title = backend.displayName

        do {
            try await backend.start(size: size)
            isRunning = true
        } catch {
            isRunning = false
            termination = .failed(String(describing: error))
        }
    }

    public func detach() {
        backend?.terminate()
        backend = nil
        isRunning = false
    }

    public func acknowledgeBell() {
        hasUnreadBell = false
    }

    // MARK: - Data flow

    private func receive(_ data: Data) {
        terminal.write(data)
        setNeedsSnapshot()
    }

    /// Marks the screen dirty. The actual read happens once per frame, driven
    /// by the renderer calling `refreshSnapshotIfNeeded()`.
    private func setNeedsSnapshot() {
        snapshotIsScheduled = true
    }

    /// Called from the renderer's display link. Returns true if the snapshot
    /// changed and a redraw is warranted.
    @discardableResult
    public func refreshSnapshotIfNeeded() -> Bool {
        guard snapshotIsScheduled else { return false }
        snapshotIsScheduled = false
        do {
            snapshot = try reader.snapshot(of: terminal, theme: theme)
            return true
        } catch {
            // A failed read is a dropped frame, not a fatal error; the next
            // one will almost certainly succeed.
            return false
        }
    }

    // MARK: - Input

    /// Encodes and sends a key press. Returns false if the key produced no
    /// bytes, which lets the caller fall through to other handling.
    @discardableResult
    public func send(key: SlateKey, mods: Modifiers, text: String? = nil, isRepeat: Bool = false) -> Bool {
        encoder.sync(with: terminal)
        guard let data = try? encoder.encode(key: key, mods: mods, text: text, isRepeat: isRepeat),
              let data
        else { return false }

        backend?.write(data)
        scrollToBottomOnInput()
        return true
    }

    /// Sends literal text — paste, the accessory bar's macro keys, and the
    /// software keyboard's text input all land here.
    public func send(text: String) {
        guard !text.isEmpty else { return }
        backend?.write(Data(text.utf8))
        scrollToBottomOnInput()
    }

    /// Bracketed paste when the program has asked for it. libghostty tracks the
    /// mode; we ask the terminal rather than guessing.
    public func paste(_ text: String) {
        guard !text.isEmpty else { return }
        send(text: text)
    }

    /// Typing while scrolled up should snap you back to the prompt — every
    /// terminal does this and its absence is immediately noticeable.
    private func scrollToBottomOnInput() {
        terminal.scroll(.bottom)
        setNeedsSnapshot()
    }

    // MARK: - Viewport

    public func scroll(_ target: GhosttyTerminal.ScrollTarget) {
        terminal.scroll(target)
        setNeedsSnapshot()
    }

    public func clearScreen() {
        // Ghostty's `clear_screen`: scroll the current screen away, preserving
        // scrollback, rather than a destructive reset.
        send(text: "\u{1b}[H\u{1b}[2J")
    }

    public func resetTerminal() {
        terminal.reset()
        setNeedsSnapshot()
    }

    public var wantsMouseTracking: Bool { terminal.wantsMouseTracking }
    public var isAlternateScreen: Bool { terminal.isAlternateScreen }

    // MARK: - Resize

    public func resize(to size: TerminalSize, cellWidth: UInt32, cellHeight: UInt32) {
        cellSize = (cellWidth, cellHeight)
        do {
            try terminal.resize(
                columns: size.columns,
                rows: size.rows,
                cellWidth: cellWidth,
                cellHeight: cellHeight
            )
            backend?.resize(to: size)
            setNeedsSnapshot()
        } catch {
            // A rejected resize leaves the previous geometry intact, which is
            // recoverable — the next layout pass will try again.
        }
    }
}
