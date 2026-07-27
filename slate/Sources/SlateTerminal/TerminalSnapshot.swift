import Foundation
import SlateTheme

/// The text in a cell.
///
/// Most cells on most screens are a single ASCII byte, so that case is stored
/// inline. Allocating a `String` per cell per frame would put an 80x50 grid at
/// 4,000 allocations a frame, which is not a budget a 120 Hz iPad has.
public enum CellText: Hashable, Sendable {
    case empty
    case ascii(UInt8)
    case grapheme(String)

    public var isEmpty: Bool {
        switch self {
        case .empty: true
        case .ascii(let byte): byte == 0x20
        case .grapheme(let text): text.isEmpty
        }
    }

    /// The string form, allocated only when it isn't already one.
    public var string: String {
        switch self {
        case .empty: " "
        case .ascii(let byte): String(UnicodeScalar(byte))
        case .grapheme(let text): text
        }
    }
}

public struct CellAttributes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt16
    public init(rawValue: UInt16) { self.rawValue = rawValue }

    public static let bold = CellAttributes(rawValue: 1 << 0)
    public static let italic = CellAttributes(rawValue: 1 << 1)
    public static let faint = CellAttributes(rawValue: 1 << 2)
    public static let blink = CellAttributes(rawValue: 1 << 3)
    public static let inverse = CellAttributes(rawValue: 1 << 4)
    public static let invisible = CellAttributes(rawValue: 1 << 5)
    public static let strikethrough = CellAttributes(rawValue: 1 << 6)
    public static let overline = CellAttributes(rawValue: 1 << 7)
    public static let underline = CellAttributes(rawValue: 1 << 8)
}

public struct TerminalCell: Hashable, Sendable {
    public var text: CellText
    /// Already resolved against the palette and theme — the renderer never has
    /// to think about indexed vs RGB vs default.
    public var foreground: RGB
    public var background: RGB
    public var attributes: CellAttributes
    public var isSelected: Bool

    public init(
        text: CellText = .empty,
        foreground: RGB,
        background: RGB,
        attributes: CellAttributes = [],
        isSelected: Bool = false
    ) {
        self.text = text
        self.foreground = foreground
        self.background = background
        self.attributes = attributes
        self.isSelected = isSelected
    }
}

public struct TerminalRow: Sendable {
    public var cells: [TerminalCell]
    /// libghostty tracks per-row dirtiness. The renderer uses this to skip
    /// re-rasterising rows that didn't change.
    public var isDirty: Bool

    public init(cells: [TerminalCell], isDirty: Bool) {
        self.cells = cells
        self.isDirty = isDirty
    }
}

public struct TerminalCursor: Sendable, Hashable {
    public enum Style: Sendable, Hashable {
        case block
        case blockHollow
        case bar
        case underline
    }

    public var column: UInt16
    public var row: UInt16
    public var style: Style
    public var isVisible: Bool
    public var isBlinking: Bool
    /// Set when the shell has signalled password input (OSC 133 / DECSET 2004
    /// adjacent). Slate hides the cursor trail and disables the accessory bar's
    /// paste button while this is on.
    public var isPasswordInput: Bool

    public init(
        column: UInt16 = 0,
        row: UInt16 = 0,
        style: Style = .block,
        isVisible: Bool = true,
        isBlinking: Bool = true,
        isPasswordInput: Bool = false
    ) {
        self.column = column
        self.row = row
        self.style = style
        self.isVisible = isVisible
        self.isBlinking = isBlinking
        self.isPasswordInput = isPasswordInput
    }
}

/// One frame's worth of terminal state, fully resolved and detached from
/// libghostty's memory. Everything the renderer needs and nothing it doesn't.
public struct TerminalSnapshot: Sendable {
    public var columns: Int
    public var rows: [TerminalRow]
    public var cursor: TerminalCursor?
    public var background: RGB
    public var foreground: RGB
    /// Monotonic; bumped on every successful read. The renderer compares this
    /// to decide whether to redraw at all.
    public var generation: UInt64

    public init(
        columns: Int = 0,
        rows: [TerminalRow] = [],
        cursor: TerminalCursor? = nil,
        background: RGB = RGB(r: 0, g: 0, b: 0),
        foreground: RGB = RGB(r: 255, g: 255, b: 255),
        generation: UInt64 = 0
    ) {
        self.columns = columns
        self.rows = rows
        self.cursor = cursor
        self.background = background
        self.foreground = foreground
        self.generation = generation
    }

    public var rowCount: Int { rows.count }

    public var isEmpty: Bool { rows.isEmpty || columns == 0 }
}
