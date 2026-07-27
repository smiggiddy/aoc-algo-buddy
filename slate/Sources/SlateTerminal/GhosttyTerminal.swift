import CGhosttyShim
import Foundation
import GhosttyKit
import SlateTheme

public enum GhosttyError: Error, CustomStringConvertible {
    case outOfMemory
    case invalidValue
    case outOfSpace
    case noValue
    case unknown(Int32)

    init?(_ result: GhosttyResult) {
        switch result {
        case GHOSTTY_SUCCESS: return nil
        case GHOSTTY_OUT_OF_MEMORY: self = .outOfMemory
        case GHOSTTY_INVALID_VALUE: self = .invalidValue
        case GHOSTTY_OUT_OF_SPACE: self = .outOfSpace
        case GHOSTTY_NO_VALUE: self = .noValue
        default: self = .unknown(result.rawValue)
        }
    }

    public var description: String {
        switch self {
        case .outOfMemory: "libghostty: out of memory"
        case .invalidValue: "libghostty: invalid value"
        case .outOfSpace: "libghostty: out of space"
        case .noValue: "libghostty: no value"
        case .unknown(let code): "libghostty: unknown error \(code)"
        }
    }
}

/// Throws if a libghostty call didn't return `GHOSTTY_SUCCESS`.
@inline(__always)
func check(_ result: GhosttyResult) throws {
    if let error = GhosttyError(result) { throw error }
}

/// The allocator every libghostty object in Slate is built from. Backed by
/// posix_memalign in the C shim — see `slate_ghostty_shim.c`.
let slateAllocator: UnsafePointer<GhosttyAllocator> = slate_libc_allocator()

/// A libghostty terminal: the VT state machine, screen, and scrollback.
///
/// This owns no I/O. Bytes arriving from a backend go in via `write(_:)`;
/// bytes the terminal wants to send back (query replies, mouse reports, focus
/// events) come out via `onWriteToBackend`.
///
/// Not thread-safe. Slate drives it entirely from the main actor; backends
/// hand bytes over by hopping to the main actor first. If that ever becomes a
/// bottleneck, the fix is to move the terminal to a dedicated serial queue and
/// snapshot to the renderer — not to add locks here.
public final class GhosttyTerminal {
    public private(set) var handle: GhosttyTerminal_Handle

    /// Called when the terminal produces bytes for the backend (i.e. what a
    /// real terminal would write to the PTY master).
    public var onWriteToBackend: ((Data) -> Void)?

    /// Called on OSC 0/1/2 title changes.
    public var onTitleChanged: ((String) -> Void)?

    /// Called on OSC 7 working-directory reports.
    public var onWorkingDirectoryChanged: ((String) -> Void)?

    /// Called on BEL. iPadOS has no system beep for apps, so the app layer
    /// turns this into haptics or a visual flash.
    public var onBell: (() -> Void)?

    public private(set) var columns: UInt16
    public private(set) var rows: UInt16

    public init(columns: UInt16, rows: UInt16, maxScrollback: Int = 10_000) throws {
        self.columns = max(columns, 1)
        self.rows = max(rows, 1)

        let options = GhosttyTerminalOptions(
            cols: self.columns,
            rows: self.rows,
            max_scrollback: maxScrollback
        )

        var created: GhosttyTerminal_Handle?
        try check(ghostty_terminal_new(slateAllocator, &created, options))
        guard let created else { throw GhosttyError.outOfMemory }
        handle = created

        try installCallbacks()
    }

    deinit {
        ghostty_terminal_free(handle)
    }

    // MARK: - Callbacks
    //
    // libghostty hands each callback a `void *userdata` that we set to an
    // unretained pointer back to `self`. Unretained is correct: the terminal
    // handle never outlives this object, since we free it in `deinit`.

    private func installCallbacks() throws {
        let userdata = Unmanaged.passUnretained(self).toOpaque()
        try set(.userdata, pointer: userdata)

        var writeFn: GhosttyTerminalWritePtyFn = { _, userdata, data, len in
            guard let userdata, let data else { return }
            let terminal = Unmanaged<GhosttyTerminal>.fromOpaque(userdata).takeUnretainedValue()
            terminal.onWriteToBackend?(Data(bytes: data, count: len))
        }
        try set(.writePty, value: &writeFn)

        var bellFn: GhosttyTerminalBellFn = { _, userdata in
            guard let userdata else { return }
            Unmanaged<GhosttyTerminal>.fromOpaque(userdata).takeUnretainedValue().onBell?()
        }
        try set(.bell, value: &bellFn)

        var titleFn: GhosttyTerminalTitleChangedFn = { terminal, userdata in
            guard let userdata else { return }
            let object = Unmanaged<GhosttyTerminal>.fromOpaque(userdata).takeUnretainedValue()
            object.onTitleChanged?(object.string(for: GHOSTTY_TERMINAL_DATA_TITLE) ?? "")
        }
        try set(.titleChanged, value: &titleFn)

        var pwdFn: GhosttyTerminalPwdChangedFn = { _, userdata in
            guard let userdata else { return }
            let object = Unmanaged<GhosttyTerminal>.fromOpaque(userdata).takeUnretainedValue()
            object.onWorkingDirectoryChanged?(object.string(for: GHOSTTY_TERMINAL_DATA_PWD) ?? "")
        }
        try set(.pwdChanged, value: &pwdFn)

        // Answer DA/ENQ/XTVERSION as ourselves rather than leaving them unset;
        // some TUIs branch on the response.
        var xtversionFn: GhosttyTerminalXtversionFn = { _, _ in
            Self.staticString(Self.xtversion)
        }
        try set(.xtversion, value: &xtversionFn)
    }

    /// Backing storage for the C strings we hand back to libghostty. These must
    /// outlive the call, so they're process-lifetime allocations made once.
    private static let xtversion = Array("Slate(1.0.0)".utf8)

    private static func staticString(_ bytes: [UInt8]) -> GhosttyString {
        bytes.withUnsafeBufferPointer { buffer in
            GhosttyString(ptr: buffer.baseAddress, len: buffer.count)
        }
    }

    // MARK: - Options

    public enum Option {
        case userdata, writePty, bell, titleChanged, pwdChanged, xtversion
        case colorForeground, colorBackground, colorCursor, colorPalette
        case defaultCursorStyle

        var raw: GhosttyTerminalOption {
            switch self {
            case .userdata: GHOSTTY_TERMINAL_OPT_USERDATA
            case .writePty: GHOSTTY_TERMINAL_OPT_WRITE_PTY
            case .bell: GHOSTTY_TERMINAL_OPT_BELL
            case .titleChanged: GHOSTTY_TERMINAL_OPT_TITLE_CHANGED
            case .pwdChanged: GHOSTTY_TERMINAL_OPT_PWD_CHANGED
            case .xtversion: GHOSTTY_TERMINAL_OPT_XTVERSION
            case .colorForeground: GHOSTTY_TERMINAL_OPT_COLOR_FOREGROUND
            case .colorBackground: GHOSTTY_TERMINAL_OPT_COLOR_BACKGROUND
            case .colorCursor: GHOSTTY_TERMINAL_OPT_COLOR_CURSOR
            case .colorPalette: GHOSTTY_TERMINAL_OPT_COLOR_PALETTE
            case .defaultCursorStyle: GHOSTTY_TERMINAL_OPT_DEFAULT_CURSOR_STYLE
            }
        }
    }

    func set(_ option: Option, pointer: UnsafeRawPointer?) throws {
        try check(ghostty_terminal_set(handle, option.raw, pointer))
    }

    func set<T>(_ option: Option, value: inout T) throws {
        try withUnsafePointer(to: &value) { pointer in
            try check(ghostty_terminal_set(handle, option.raw, UnsafeRawPointer(pointer)))
        }
    }

    /// Pushes a Slate theme into the terminal so that default colours and
    /// palette queries (OSC 4/10/11) answer correctly.
    public func apply(theme: Theme) throws {
        var background = theme.background.ghostty
        var foreground = theme.foreground.ghostty
        var cursor = theme.cursor.ghostty
        try set(.colorBackground, value: &background)
        try set(.colorForeground, value: &foreground)
        try set(.colorCursor, value: &cursor)

        var palette = theme.palette256.map(\.ghostty)
        try palette.withUnsafeBufferPointer { buffer in
            try check(ghostty_terminal_set(
                handle,
                GHOSTTY_TERMINAL_OPT_COLOR_PALETTE,
                UnsafeRawPointer(buffer.baseAddress)
            ))
        }
    }

    // MARK: - Input

    /// Feeds bytes from the backend into the VT parser.
    public func write(_ data: Data) {
        guard !data.isEmpty else { return }
        data.withUnsafeBytes { buffer in
            guard let base = buffer.bindMemory(to: UInt8.self).baseAddress else { return }
            ghostty_terminal_vt_write(handle, base, buffer.count)
        }
    }

    public func resize(columns: UInt16, rows: UInt16, cellWidth: UInt32, cellHeight: UInt32) throws {
        let columns = max(columns, 1)
        let rows = max(rows, 1)
        guard columns != self.columns || rows != self.rows else { return }
        try check(ghostty_terminal_resize(handle, columns, rows, cellWidth, cellHeight))
        self.columns = columns
        self.rows = rows
    }

    public func reset() {
        ghostty_terminal_reset(handle)
    }

    // MARK: - Scrollback

    public enum ScrollTarget {
        case top
        case bottom
        case delta(Int)
        case row(Int)
    }

    public func scroll(_ target: ScrollTarget) {
        var viewport = GhosttyTerminalScrollViewport()
        switch target {
        case .top:
            viewport.tag = GHOSTTY_SCROLL_VIEWPORT_TOP
        case .bottom:
            viewport.tag = GHOSTTY_SCROLL_VIEWPORT_BOTTOM
        case .delta(let amount):
            viewport.tag = GHOSTTY_SCROLL_VIEWPORT_DELTA
            viewport.value.delta = amount
        case .row(let index):
            viewport.tag = GHOSTTY_SCROLL_VIEWPORT_ROW
            viewport.value.row = index
        }
        ghostty_terminal_scroll_viewport(handle, viewport)
    }

    // MARK: - Reading state

    func value<T>(_ data: GhosttyTerminalData, default fallback: T) -> T {
        var out = fallback
        let result = withUnsafeMutablePointer(to: &out) { pointer in
            ghostty_terminal_get(handle, data, UnsafeMutableRawPointer(pointer))
        }
        return result == GHOSTTY_SUCCESS ? out : fallback
    }

    func string(for data: GhosttyTerminalData) -> String? {
        var out = GhosttyString(ptr: nil, len: 0)
        let result = withUnsafeMutablePointer(to: &out) { pointer in
            ghostty_terminal_get(handle, data, UnsafeMutableRawPointer(pointer))
        }
        guard result == GHOSTTY_SUCCESS, let ptr = out.ptr, out.len > 0 else { return nil }
        return String(decoding: UnsafeBufferPointer(start: ptr, count: out.len), as: UTF8.self)
    }

    public var title: String? { string(for: GHOSTTY_TERMINAL_DATA_TITLE) }
    public var workingDirectory: String? { string(for: GHOSTTY_TERMINAL_DATA_PWD) }
    public var isAlternateScreen: Bool {
        value(GHOSTTY_TERMINAL_DATA_ACTIVE_SCREEN, default: GHOSTTY_TERMINAL_SCREEN_PRIMARY)
            == GHOSTTY_TERMINAL_SCREEN_ALTERNATE
    }
    public var scrollbackRows: UInt64 { value(GHOSTTY_TERMINAL_DATA_SCROLLBACK_ROWS, default: UInt64(0)) }

    /// Whether the running program has asked for mouse reporting. When it has,
    /// touch drags become mouse events instead of scrollback scrolling.
    public var wantsMouseTracking: Bool {
        value(GHOSTTY_TERMINAL_DATA_MOUSE_TRACKING, default: false)
    }

    public var scrollbar: GhosttyTerminalScrollbar {
        value(
            GHOSTTY_TERMINAL_DATA_SCROLLBAR,
            default: GhosttyTerminalScrollbar(total: 0, offset: 0, len: 0)
        )
    }
}

/// GhosttyKit exposes the opaque handle as `GhosttyTerminal`, which collides
/// with our Swift class name. Alias it once, here.
public typealias GhosttyTerminal_Handle = OpaquePointer

extension RGB {
    var ghostty: GhosttyColorRgb {
        GhosttyColorRgb(r: r, g: g, b: b)
    }

    init(_ color: GhosttyColorRgb) {
        self.init(r: color.r, g: color.g, b: color.b)
    }
}
