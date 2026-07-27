import Foundation

/// The size a backend needs to know about, in both cells and pixels.
/// Pixels matter for `TIOCGWINSZ`-style reporting and for programs that draw
/// images (Kitty graphics, sixel).
public struct TerminalSize: Equatable, Sendable {
    public var columns: UInt16
    public var rows: UInt16
    public var pixelWidth: UInt32
    public var pixelHeight: UInt32

    public init(columns: UInt16, rows: UInt16, pixelWidth: UInt32 = 0, pixelHeight: UInt32 = 0) {
        self.columns = columns
        self.rows = rows
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// Where a terminal's bytes come from and go to.
///
/// Deliberately narrow. On iPadOS there is no single answer here — a local
/// `ios_system` runner, a WASI runtime, and an SSH channel are all legitimate,
/// and none of them is a real PTY. Everything above this protocol is written
/// against a byte stream, so swapping backends doesn't touch the terminal,
/// renderer, or input layers.
public protocol TerminalBackend: AnyObject, Sendable {
    /// Human-readable name for the tab's subtitle.
    var displayName: String { get }

    /// Called with output as it arrives. Always delivered on the main actor,
    /// because that's where the terminal lives.
    var onOutput: (@MainActor (Data) -> Void)? { get set }

    /// Called when the backend finishes: process exit, disconnect, or error.
    var onTermination: (@MainActor (TerminalBackendTermination) -> Void)? { get set }

    /// Starts the backend at the given size.
    func start(size: TerminalSize) async throws

    /// Sends bytes toward the program (what a PTY master write would do).
    func write(_ data: Data)

    /// Notifies the program of a resize. Backends without a real PTY should
    /// approximate this — see `LocalShellBackend` for how `ios_system` does it
    /// with `COLUMNS`/`LINES` plus a synthetic SIGWINCH.
    func resize(to size: TerminalSize)

    /// Requests a clean shutdown.
    func terminate()
}

public enum TerminalBackendTermination: Sendable, Equatable {
    case exited(code: Int32)
    case disconnected
    case failed(String)

    public var message: String {
        switch self {
        case .exited(let code) where code == 0: "Process exited"
        case .exited(let code): "Process exited with status \(code)"
        case .disconnected: "Disconnected"
        case .failed(let reason): reason
        }
    }
}
