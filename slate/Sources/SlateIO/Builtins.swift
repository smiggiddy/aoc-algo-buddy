import Foundation
import SlateTerminal

/// The command set `BuiltinShellBackend` understands.
///
/// Intentionally small: enough to navigate, read files, and prove the terminal
/// works end to end. The real command set arrives with `ios_system`.
enum Builtins {
    enum Result {
        case output(String)
        case exit
    }

    static func run(_ line: String, in workingDirectory: inout URL, size: TerminalSize) -> Result {
        let arguments = tokenize(line)
        guard let command = arguments.first else { return .output("") }
        let rest = Array(arguments.dropFirst())

        switch command {
        case "help":
            return .output(help)

        case "exit", "logout":
            return .exit

        case "pwd":
            return .output(workingDirectory.path + "\n")

        case "cd":
            return .output(changeDirectory(to: rest.first, from: &workingDirectory))

        case "ls":
            return .output(list(rest.first.map { resolve($0, from: workingDirectory) } ?? workingDirectory, columns: Int(size.columns)))

        case "cat":
            guard let target = rest.first else { return .output("cat: missing operand\n") }
            let url = resolve(target, from: workingDirectory)
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
                return .output("cat: \(target): no such file\n")
            }
            return .output(contents.hasSuffix("\n") ? contents : contents + "\n")

        case "mkdir":
            guard let target = rest.first else { return .output("mkdir: missing operand\n") }
            do {
                try FileManager.default.createDirectory(
                    at: resolve(target, from: workingDirectory),
                    withIntermediateDirectories: true
                )
                return .output("")
            } catch {
                return .output("mkdir: \(error.localizedDescription)\n")
            }

        case "rm":
            guard let target = rest.first else { return .output("rm: missing operand\n") }
            do {
                try FileManager.default.removeItem(at: resolve(target, from: workingDirectory))
                return .output("")
            } catch {
                return .output("rm: \(error.localizedDescription)\n")
            }

        case "echo":
            return .output(rest.joined(separator: " ") + "\n")

        case "env":
            return .output(
                ProcessInfo.processInfo.environment
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value)" }
                    .joined(separator: "\n") + "\n"
            )

        case "clear":
            return .output("\u{1b}[H\u{1b}[2J")

        case "size":
            return .output("\(size.columns)x\(size.rows) cells, \(size.pixelWidth)x\(size.pixelHeight) px\n")

        case "colors":
            return .output(colorChart)

        default:
            return .output("slate-sh: command not found: \(command)\n")
        }
    }

    // MARK: - Helpers

    /// Whitespace splitting with quote support. Not a real shell grammar — no
    /// expansion, no pipes — but enough that `cat "my file.txt"` works.
    private static func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?

        for character in line {
            if let active = quote {
                if character == active { quote = nil } else { current.append(character) }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character.isWhitespace {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    private static func resolve(_ path: String, from base: URL) -> URL {
        if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
        if path.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home.appendingPathComponent(String(path.dropFirst().drop(while: { $0 == "/" })))
        }
        return base.appendingPathComponent(path).standardizedFileURL
    }

    private static func changeDirectory(to path: String?, from current: inout URL) -> String {
        let target = path.map { resolve($0, from: current) }
            ?? (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
            ?? current

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return "cd: \(path ?? target.path): not a directory\n"
        }
        current = target.standardizedFileURL
        return ""
    }

    /// Column-packed listing, directories in blue, like `ls` with colour.
    private static func list(_ directory: URL, columns: Int) -> String {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return "ls: cannot access \(directory.lastPathComponent)\n"
        }
        guard !entries.isEmpty else { return "" }

        let names = entries
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            .map { url -> (String, Bool) in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return (url.lastPathComponent, isDirectory)
            }

        let widest = names.map(\.0.count).max() ?? 1
        let columnWidth = widest + 2
        let perRow = max(1, columns / columnWidth)

        var output = ""
        for (index, entry) in names.enumerated() {
            let padded = entry.0.padding(toLength: max(columnWidth, entry.0.count), withPad: " ", startingAt: 0)
            output += entry.1 ? "\u{1b}[1;34m\(padded)\u{1b}[0m" : padded
            if (index + 1) % perRow == 0 { output += "\n" }
        }
        if names.count % perRow != 0 { output += "\n" }
        return output
    }

    private static let help = """
        Slate built-in shell. This is a placeholder runtime — wire up ios_system
        for the real command set (see IOSSystemBackend.swift).

          help              show this text
          pwd               print working directory
          cd [dir]          change directory
          ls [dir]          list directory contents
          cat <file>        print a file
          mkdir <dir>       create a directory
          rm <path>         remove a file or directory
          echo <text>       print text
          env               print the environment
          size              print the terminal geometry
          colors            print an ANSI colour chart
          clear             clear the screen
          exit              end the session

        """

    /// Renders the 16 ANSI colours plus the 256-colour cube — the quickest way
    /// to eyeball whether a theme and the renderer agree.
    private static var colorChart: String {
        var output = "\nANSI 0-15:\n"
        for index in 0..<16 {
            output += "\u{1b}[48;5;\(index)m  \u{1b}[0m"
            if index == 7 { output += "\n" }
        }
        output += "\n\n216-colour cube:\n"
        for index in 16..<232 {
            output += "\u{1b}[48;5;\(index)m \u{1b}[0m"
            if (index - 16) % 36 == 35 { output += "\n" }
        }
        output += "\nGreyscale:\n"
        for index in 232..<256 {
            output += "\u{1b}[48;5;\(index)m \u{1b}[0m"
        }
        output += "\n\nStyles: \u{1b}[1mbold\u{1b}[0m \u{1b}[3mitalic\u{1b}[0m \u{1b}[4munderline\u{1b}[0m \u{1b}[9mstrike\u{1b}[0m \u{1b}[7minverse\u{1b}[0m\n\n"
        return output
    }
}
