import CGhosttyShim
import Foundation
import GhosttyKit
import SlateTheme

/// Pulls a `TerminalSnapshot` out of libghostty's render state.
///
/// libghostty's render API is explicitly designed so an embedder can take a
/// consistent view of the screen without locking the terminal for the duration
/// of a frame: `begin_update` / iterate / `end_update`. We keep the state,
/// iterator, and cell reader alive across frames because allocating them per
/// frame would defeat the point.
///
/// INTEGRATION NOTE: the ownership dance below — allocate the iterator, then
/// bind it to the state via `render_state_get(.rowIterator)` — is the reading
/// of the header that matches how the row/cells objects are separately
/// allocated. If a build fails or misbehaves here, this is the first place to
/// check against the vendored `render.h`.
public final class RenderStateReader {
    private let state: OpaquePointer
    private let iterator: OpaquePointer
    private let cells: OpaquePointer
    private var generation: UInt64 = 0

    public init() throws {
        var state: OpaquePointer?
        try check(ghostty_render_state_new(slateAllocator, &state))
        guard let state else { throw GhosttyError.outOfMemory }
        self.state = state

        var iterator: OpaquePointer?
        try check(ghostty_render_state_row_iterator_new(slateAllocator, &iterator))
        guard let iterator else {
            ghostty_render_state_free(state)
            throw GhosttyError.outOfMemory
        }
        self.iterator = iterator

        var cells: OpaquePointer?
        try check(ghostty_render_state_row_cells_new(slateAllocator, &cells))
        guard let cells else {
            ghostty_render_state_row_iterator_free(iterator)
            ghostty_render_state_free(state)
            throw GhosttyError.outOfMemory
        }
        self.cells = cells
    }

    deinit {
        ghostty_render_state_row_cells_free(cells)
        ghostty_render_state_row_iterator_free(iterator)
        ghostty_render_state_free(state)
    }

    /// Reads the current screen. `theme` resolves palette indices and the
    /// "default" colour, so the snapshot the renderer gets is fully concrete.
    public func snapshot(of terminal: GhosttyTerminal, theme: Theme) throws -> TerminalSnapshot {
        try check(ghostty_render_state_begin_update(state, terminal.handle))
        defer { _ = ghostty_render_state_end_update(state) }

        var columns: UInt16 = 0
        var rowCount: UInt16 = 0
        _ = withUnsafeMutablePointer(to: &columns) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_COLS, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &rowCount) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_ROWS, UnsafeMutableRawPointer($0))
        }

        var colors = slate_render_state_colors_init()
        try check(ghostty_render_state_colors_get(state, &colors))
        let defaultForeground = RGB(colors.foreground)
        let defaultBackground = RGB(colors.background)

        // Bind our long-lived iterator to this update.
        var boundIterator: OpaquePointer? = iterator
        try check(withUnsafeMutablePointer(to: &boundIterator) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_ROW_ITERATOR, UnsafeMutableRawPointer($0))
        })

        var rows: [TerminalRow] = []
        rows.reserveCapacity(Int(rowCount))

        while ghostty_render_state_row_iterator_next(iterator) {
            rows.append(try readRow(
                columns: Int(columns),
                theme: theme,
                defaultForeground: defaultForeground,
                defaultBackground: defaultBackground
            ))
        }

        generation &+= 1

        return TerminalSnapshot(
            columns: Int(columns),
            rows: rows,
            cursor: readCursor(),
            background: defaultBackground,
            foreground: defaultForeground,
            generation: generation
        )
    }

    // MARK: - Rows

    private func readRow(
        columns: Int,
        theme: Theme,
        defaultForeground: RGB,
        defaultBackground: RGB
    ) throws -> TerminalRow {
        var isDirty = false
        _ = withUnsafeMutablePointer(to: &isDirty) {
            ghostty_render_state_row_get(iterator, GHOSTTY_RENDER_STATE_ROW_DATA_DIRTY, UnsafeMutableRawPointer($0))
        }

        var boundCells: OpaquePointer? = cells
        try check(withUnsafeMutablePointer(to: &boundCells) {
            ghostty_render_state_row_get(iterator, GHOSTTY_RENDER_STATE_ROW_DATA_CELLS, UnsafeMutableRawPointer($0))
        })

        var rowCells: [TerminalCell] = []
        rowCells.reserveCapacity(columns)

        while ghostty_render_state_row_cells_next(cells) {
            rowCells.append(readCell(
                theme: theme,
                defaultForeground: defaultForeground,
                defaultBackground: defaultBackground
            ))
        }

        // A row shorter than the grid is padded with blanks so the renderer can
        // index without bounds checks.
        if rowCells.count < columns {
            let blank = TerminalCell(foreground: defaultForeground, background: defaultBackground)
            rowCells.append(contentsOf: repeatElement(blank, count: columns - rowCells.count))
        }

        return TerminalRow(cells: rowCells, isDirty: isDirty)
    }

    private func readCell(
        theme: Theme,
        defaultForeground: RGB,
        defaultBackground: RGB
    ) -> TerminalCell {
        var foreground = GhosttyColorRgb(r: 0, g: 0, b: 0)
        var background = GhosttyColorRgb(r: 0, g: 0, b: 0)
        var isSelected = false
        var hasStyling = false

        // BG_COLOR/FG_COLOR are pre-resolved by libghostty: it has already
        // applied the palette, the default colours, and inverse video. That is
        // why we don't reimplement any of that here.
        _ = withUnsafeMutablePointer(to: &foreground) {
            ghostty_render_state_row_cells_get(cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_FG_COLOR, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &background) {
            ghostty_render_state_row_cells_get(cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_BG_COLOR, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &isSelected) {
            ghostty_render_state_row_cells_get(cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_SELECTED, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &hasStyling) {
            ghostty_render_state_row_cells_get(cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_HAS_STYLING, UnsafeMutableRawPointer($0))
        }

        return TerminalCell(
            text: readCellText(),
            foreground: RGB(foreground),
            background: RGB(background),
            attributes: hasStyling ? readCellAttributes() : [],
            isSelected: isSelected
        )
    }

    private func readCellText() -> CellText {
        var text = GhosttyString(ptr: nil, len: 0)
        let result = withUnsafeMutablePointer(to: &text) {
            ghostty_render_state_row_cells_get(
                cells,
                GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_GRAPHEMES_UTF8,
                UnsafeMutableRawPointer($0)
            )
        }
        guard result == GHOSTTY_SUCCESS, let ptr = text.ptr, text.len > 0 else { return .empty }

        // Fast path: a lone ASCII byte, which is the overwhelming majority.
        if text.len == 1, ptr[0] < 0x80 {
            return ptr[0] == 0x20 ? .empty : .ascii(ptr[0])
        }
        return .grapheme(String(decoding: UnsafeBufferPointer(start: ptr, count: text.len), as: UTF8.self))
    }

    private func readCellAttributes() -> CellAttributes {
        var style = slate_style_init()
        let result = withUnsafeMutablePointer(to: &style) {
            ghostty_render_state_row_cells_get(
                cells,
                GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_STYLE,
                UnsafeMutableRawPointer($0)
            )
        }
        guard result == GHOSTTY_SUCCESS else { return [] }

        var attributes: CellAttributes = []
        if style.bold { attributes.insert(.bold) }
        if style.italic { attributes.insert(.italic) }
        if style.faint { attributes.insert(.faint) }
        if style.blink { attributes.insert(.blink) }
        if style.inverse { attributes.insert(.inverse) }
        if style.invisible { attributes.insert(.invisible) }
        if style.strikethrough { attributes.insert(.strikethrough) }
        if style.overline { attributes.insert(.overline) }
        if style.underline != 0 { attributes.insert(.underline) }
        return attributes
    }

    // MARK: - Cursor

    private func readCursor() -> TerminalCursor? {
        var hasValue = false
        _ = withUnsafeMutablePointer(to: &hasValue) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_HAS_VALUE, UnsafeMutableRawPointer($0))
        }
        // No viewport cursor means the user has scrolled the cursor off screen.
        guard hasValue else { return nil }

        var column: UInt16 = 0
        var row: UInt16 = 0
        var visible = true
        var blinking = true
        var passwordInput = false
        var style = GHOSTTY_RENDER_STATE_CURSOR_VISUAL_STYLE_BLOCK

        _ = withUnsafeMutablePointer(to: &column) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_X, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &row) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_Y, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &visible) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VISIBLE, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &blinking) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_BLINKING, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &passwordInput) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_PASSWORD_INPUT, UnsafeMutableRawPointer($0))
        }
        _ = withUnsafeMutablePointer(to: &style) {
            ghostty_render_state_get(state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VISUAL_STYLE, UnsafeMutableRawPointer($0))
        }

        return TerminalCursor(
            column: column,
            row: row,
            style: TerminalCursor.Style(style),
            isVisible: visible,
            isBlinking: blinking,
            isPasswordInput: passwordInput
        )
    }
}

extension TerminalCursor.Style {
    init(_ style: GhosttyRenderStateCursorVisualStyle) {
        switch style {
        case GHOSTTY_RENDER_STATE_CURSOR_VISUAL_STYLE_BAR: self = .bar
        case GHOSTTY_RENDER_STATE_CURSOR_VISUAL_STYLE_UNDERLINE: self = .underline
        case GHOSTTY_RENDER_STATE_CURSOR_VISUAL_STYLE_BLOCK_HOLLOW: self = .blockHollow
        default: self = .block
        }
    }
}
