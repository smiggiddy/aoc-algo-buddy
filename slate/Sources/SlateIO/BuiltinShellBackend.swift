import Foundation
import SlateTerminal

/// A small shell implemented in Swift, so Slate does something useful the
/// moment it builds — before you've vendored `ios_system`.
///
/// It is also the reference for what a backend has to do when there is no PTY:
/// there's no kernel line discipline on iPadOS, so *we* own echo, backspace,
/// and history. `IOSSystemBackend` inherits exactly the same problem.
///
/// Commands live in `Builtins`; adding one is a dictionary entry.
public final class BuiltinShellBackend: TerminalBackend, @unchecked Sendable {
    public let displayName = "slate-sh"

    public var onOutput: (@MainActor (Data) -> Void)?
    public var onTermination: (@MainActor (TerminalBackendTermination) -> Void)?

    private var size = TerminalSize(columns: 80, rows: 24)
    private var lineBuffer: [Character] = []
    private var cursorIndex = 0
    private var history: [String] = []
    private var historyIndex: Int?
    private var workingDirectory: URL

    /// Set while a command is producing output, so a stray keypress doesn't get
    /// treated as line input mid-command.
    private var isExecuting = false

    public init(workingDirectory: URL? = nil) {
        self.workingDirectory = workingDirectory
            ?? (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    public func start(size: TerminalSize) async throws {
        self.size = size
        await emit(Self.banner)
        await prompt()
    }

    public func resize(to size: TerminalSize) {
        self.size = size
    }

    public func terminate() {
        Task { @MainActor in self.onTermination?(.exited(code: 0)) }
    }

    // MARK: - Input

    public func write(_ data: Data) {
        guard !isExecuting else { return }
        // Decode incrementally-safe: input arrives a keystroke at a time, so a
        // multi-byte scalar never splits across calls in practice.
        let text = String(decoding: data, as: UTF8.self)
        Task { @MainActor in await self.handle(text) }
    }

    @MainActor
    private func handle(_ text: String) async {
        var iterator = text.makeIterator()
        while let character = iterator.next() {
            switch character {
            case "\r", "\n":
                await execute()

            case "\u{7f}", "\u{8}": // DEL / BS
                await backspace()

            case "\u{3}": // ^C
                await emit("^C\r\n")
                lineBuffer.removeAll()
                cursorIndex = 0
                await prompt()

            case "\u{4}": // ^D on an empty line ends the session
                if lineBuffer.isEmpty {
                    await emit("\r\nexit\r\n")
                    onTermination?(.exited(code: 0))
                    return
                }

            case "\u{c}": // ^L
                await emit("\u{1b}[H\u{1b}[2J")
                await prompt()

            case "\u{15}": // ^U — kill line
                await killLine()

            case "\u{1b}":
                // An escape sequence: consume the rest of it as a unit.
                await handleEscape(&iterator)

            default:
                guard !character.isASCII || character.asciiValue.map({ $0 >= 0x20 }) ?? true else { continue }
                lineBuffer.insert(character, at: cursorIndex)
                cursorIndex += 1
                await redrawLine()
            }
        }
    }

    @MainActor
    private func handleEscape(_ iterator: inout String.Iterator) async {
        guard iterator.next() == "[" , let final = iterator.next() else { return }
        switch final {
        case "A": await recallHistory(offset: -1)
        case "B": await recallHistory(offset: 1)
        case "C": if cursorIndex < lineBuffer.count { cursorIndex += 1; await emit("\u{1b}[C") }
        case "D": if cursorIndex > 0 { cursorIndex -= 1; await emit("\u{1b}[D") }
        default: break
        }
    }

    // MARK: - Line editing

    @MainActor
    private func backspace() async {
        guard cursorIndex > 0 else { return }
        cursorIndex -= 1
        lineBuffer.remove(at: cursorIndex)
        await redrawLine()
    }

    @MainActor
    private func killLine() async {
        lineBuffer.removeAll()
        cursorIndex = 0
        await redrawLine()
    }

    /// Repaints from the prompt. Simple and correct; a smarter shell would emit
    /// only the delta, which matters over SSH but not for a local buffer.
    @MainActor
    private func redrawLine() async {
        var output = "\r\u{1b}[K" + Self.promptText(for: workingDirectory) + String(lineBuffer)
        let trailing = lineBuffer.count - cursorIndex
        if trailing > 0 { output += "\u{1b}[\(trailing)D" }
        await emit(output)
    }

    @MainActor
    private func recallHistory(offset: Int) async {
        guard !history.isEmpty else { return }
        let current = historyIndex ?? history.count
        let target = min(max(current + offset, 0), history.count)
        historyIndex = target
        lineBuffer = target < history.count ? Array(history[target]) : []
        cursorIndex = lineBuffer.count
        await redrawLine()
    }

    // MARK: - Execution

    @MainActor
    private func execute() async {
        let line = String(lineBuffer).trimmingCharacters(in: .whitespaces)
        lineBuffer.removeAll()
        cursorIndex = 0
        historyIndex = nil
        await emit("\r\n")

        guard !line.isEmpty else {
            await prompt()
            return
        }
        history.append(line)

        isExecuting = true
        let result = Builtins.run(line, in: &workingDirectory, size: size)
        isExecuting = false

        switch result {
        case .output(let text):
            if !text.isEmpty { await emit(text.replacingOccurrences(of: "\n", with: "\r\n")) }
            await prompt()
        case .exit:
            onTermination?(.exited(code: 0))
        }
    }

    @MainActor
    private func prompt() async {
        await emit(Self.promptText(for: workingDirectory))
    }

    @MainActor
    private func emit(_ text: String) async {
        onOutput?(Data(text.utf8))
    }

    // MARK: - Chrome

    private static func promptText(for directory: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var path = directory.path
        if path.hasPrefix(home) { path = "~" + path.dropFirst(home.count) }
        // Bold blue path, then a bright prompt character.
        return "\u{1b}[1;34m\(directory.lastPathComponent.isEmpty ? path : path)\u{1b}[0m \u{1b}[1;35m❯\u{1b}[0m "
    }

    private static let banner = """
        \u{1b}[1;35mSlate\u{1b}[0m — libghostty terminal for iPadOS\r
        \u{1b}[2mType `help` for built-in commands.\u{1b}[0m\r
        \r

        """
}
