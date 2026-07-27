import Foundation
import SlateTerminal

#if SLATE_IOS_SYSTEM
import ios_system
#endif

/// Runs commands locally through `ios_system`.
///
/// ## Why this exists
///
/// iOS denies `fork`/`exec`/`posix_spawn` to sandboxed apps, so there is no PTY
/// and no child process. `ios_system` (the engine behind a-Shell) sidesteps
/// that by compiling each Unix command as a *function* and dispatching it on a
/// thread, with `thread_stdin`/`thread_stdout`/`thread_stderr` as its streams.
///
/// So this backend is a PTY impersonator:
/// - **stdout/stderr** are a `pipe()` we poll on a background queue.
/// - **stdin** is the write end of a second pipe.
/// - **Window size** has no `TIOCSWINSZ` to set, so we export `COLUMNS`/`LINES`
///   and call `ios_setWindowSize` before each command.
/// - **Line discipline does not exist.** Nothing echoes your keystrokes, and
///   nothing turns ^C into a signal. Commands that use readline get it from
///   their own linked copy; everything else needs the echo/editing that
///   `BuiltinShellBackend` demonstrates.
///
/// ## Vendoring
///
/// This file compiles to a stub unless `SLATE_IOS_SYSTEM` is defined. To enable:
///
/// 1. `git clone https://github.com/holzschu/ios_system`
/// 2. `swift run --package-path xcfs build` (fetches libssh2 + openssl, builds
///    the xcframeworks)
/// 3. Link `ios_system.xcframework`; *embed without linking* the command
///    frameworks you want (`awk`, `curl`, `files`, `shell`, `text`, `ssh_cmd`…)
/// 4. Add `SLATE_IOS_SYSTEM` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
///
/// Only step 3's embed-don't-link distinction is easy to get wrong; the symptom
/// is commands that report "not found" despite the framework being present.
public final class IOSSystemBackend: TerminalBackend, @unchecked Sendable {
    public let displayName = "local"

    public var onOutput: (@MainActor (Data) -> Void)?
    public var onTermination: (@MainActor (TerminalBackendTermination) -> Void)?

    private let queue = DispatchQueue(label: "dev.slate.ios-system", qos: .userInitiated)
    private var outputPipe: Pipe?
    private var inputPipe: Pipe?
    private var size = TerminalSize(columns: 80, rows: 24)
    private var isRunning = false

    /// `ios_system` keys per-session state (cwd, environment, stream bindings)
    /// off an opaque identifier, so each Slate split gets its own. Without
    /// this, two splits share a working directory.
    private let sessionIdentifier = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)

    public init() {}

    deinit {
        sessionIdentifier.deallocate()
    }

    public func start(size: TerminalSize) async throws {
        self.size = size

        #if SLATE_IOS_SYSTEM
        let output = Pipe()
        let input = Pipe()
        outputPipe = output
        inputPipe = input

        initializeEnvironment()
        ios_switchSession(sessionIdentifier)
        ios_setContext(sessionIdentifier)
        applySize(size)

        // Bind ios_system's per-thread streams to our pipes. These are FILE*,
        // not fds, so we fdopen the pipe ends.
        let stdinFile = fdopen(input.fileHandleForReading.fileDescriptor, "r")
        let stdoutFile = fdopen(output.fileHandleForWriting.fileDescriptor, "w")
        ios_setStreams(stdinFile, stdoutFile, stdoutFile)
        // Unbuffered, or interactive output arrives only when a command exits.
        setvbuf(stdoutFile, nil, _IONBF, 0)

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { @MainActor in self?.onOutput?(data) }
        }

        isRunning = true
        #else
        throw BackendError.notCompiledIn
        #endif
    }

    public func write(_ data: Data) {
        #if SLATE_IOS_SYSTEM
        guard isRunning, let inputPipe else { return }
        try? inputPipe.fileHandleForWriting.write(contentsOf: data)
        #endif
    }

    /// Dispatches a command line. Each command runs on `queue` so a long-running
    /// `find` doesn't block the UI; output streams back through the pipe as it
    /// is produced.
    public func execute(_ commandLine: String) {
        #if SLATE_IOS_SYSTEM
        queue.async { [weak self] in
            guard let self else { return }
            ios_switchSession(self.sessionIdentifier)
            ios_setContext(self.sessionIdentifier)
            self.applySize(self.size)

            let status = commandLine.withCString { ios_system($0) }
            if status != 0 {
                Task { @MainActor in
                    self.onOutput?(Data("\u{1b}[31m[exit \(status)]\u{1b}[0m\r\n".utf8))
                }
            }
        }
        #endif
    }

    public func resize(to size: TerminalSize) {
        self.size = size
        #if SLATE_IOS_SYSTEM
        queue.async { [weak self] in self?.applySize(size) }
        #endif
    }

    public func terminate() {
        isRunning = false
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        try? outputPipe?.fileHandleForWriting.close()
        try? inputPipe?.fileHandleForWriting.close()
        Task { @MainActor in self.onTermination?(.exited(code: 0)) }
    }

    #if SLATE_IOS_SYSTEM
    /// The closest thing to `TIOCSWINSZ` that exists here. Commands that check
    /// the environment (most) pick it up; commands that call `ioctl` (few, and
    /// they'd fail anyway without a tty) do not.
    private func applySize(_ size: TerminalSize) {
        ios_setWindowSize(Int32(size.columns), Int32(size.rows))
        setenv("COLUMNS", String(size.columns), 1)
        setenv("LINES", String(size.rows), 1)
        setenv("TERM", "xterm-256color", 1)
        setenv("COLORTERM", "truecolor", 1)
    }
    #endif

    enum BackendError: LocalizedError {
        case notCompiledIn

        var errorDescription: String? {
            "ios_system is not linked. Build with -DSLATE_IOS_SYSTEM after vendoring the framework — see IOSSystemBackend.swift."
        }
    }
}
