import CGhosttyShim
import Foundation
import GhosttyKit
import SlateInput

/// Turns key presses into the bytes a terminal program expects.
///
/// This is the single best reason to use libghostty rather than rolling your
/// own: correct key encoding is a minefield of legacy modes (application cursor
/// keys, `modifyOtherKeys`, alt-as-esc-prefix, backarrow mode) plus the modern
/// Kitty keyboard protocol. libghostty implements all of it and, crucially,
/// `setopt_from_terminal` syncs the encoder to whatever modes the running
/// program has actually enabled.
public final class KeyEncoder {
    private let encoder: OpaquePointer
    /// Encoded sequences are short; 128 bytes is comfortably beyond the longest
    /// Kitty protocol sequence. `encode` reports OUT_OF_SPACE if that's ever
    /// wrong, and we grow rather than truncate.
    private var buffer = [CChar](repeating: 0, count: 128)

    public init() throws {
        var encoder: OpaquePointer?
        try check(ghostty_key_encoder_new(slateAllocator, &encoder))
        guard let encoder else { throw GhosttyError.outOfMemory }
        self.encoder = encoder
    }

    deinit {
        ghostty_key_encoder_free(encoder)
    }

    /// Re-syncs encoder options from the terminal's current modes. Call this
    /// before encoding — a program can flip application cursor mode at any
    /// moment and the next arrow key has to reflect it.
    public func sync(with terminal: GhosttyTerminal) {
        ghostty_key_encoder_setopt_from_terminal(encoder, terminal.handle)
    }

    /// Encodes a key press. `text` is the character the keyboard layout
    /// produced, which the Kitty protocol reports alongside the physical key.
    /// Returns nil when the key produces no bytes (e.g. a bare modifier).
    public func encode(
        key: SlateKey,
        mods: Modifiers,
        text: String? = nil,
        isRepeat: Bool = false
    ) throws -> Data? {
        var event: OpaquePointer?
        try check(ghostty_key_event_new(slateAllocator, &event))
        guard let event else { throw GhosttyError.outOfMemory }
        defer { ghostty_key_event_free(event) }

        ghostty_key_event_set_action(event, isRepeat ? GHOSTTY_KEY_ACTION_REPEAT : GHOSTTY_KEY_ACTION_PRESS)
        ghostty_key_event_set_key(event, key.ghostty)
        ghostty_key_event_set_mods(event, mods.ghostty)

        if let text, !text.isEmpty {
            var utf8 = Array(text.utf8)
            utf8.withUnsafeBufferPointer { pointer in
                pointer.baseAddress?.withMemoryRebound(to: CChar.self, capacity: pointer.count) { chars in
                    ghostty_key_event_set_utf8(event, chars, pointer.count)
                }
            }
            if let scalar = text.unicodeScalars.first {
                ghostty_key_event_set_unshifted_codepoint(event, scalar.value)
            }
        }

        return try encode(event: event)
    }

    private func encode(event: OpaquePointer) throws -> Data? {
        var written = 0
        var result = buffer.withUnsafeMutableBufferPointer { pointer in
            ghostty_key_encoder_encode(encoder, event, pointer.baseAddress, pointer.count, &written)
        }

        // Grow once and retry rather than silently truncating a sequence — a
        // half-written escape sequence would corrupt the program's input stream.
        if result == GHOSTTY_OUT_OF_SPACE {
            buffer = [CChar](repeating: 0, count: max(buffer.count * 2, written + 1))
            result = buffer.withUnsafeMutableBufferPointer { pointer in
                ghostty_key_encoder_encode(encoder, event, pointer.baseAddress, pointer.count, &written)
            }
        }

        try check(result)
        guard written > 0 else { return nil }
        return buffer.withUnsafeBufferPointer { pointer in
            Data(bytes: pointer.baseAddress!, count: written)
        }
    }
}

extension Modifiers {
    var ghostty: GhosttyMods {
        var mods: GhosttyMods = 0
        if contains(.shift) { mods |= GhosttyMods(GHOSTTY_MODS_SHIFT) }
        if contains(.control) { mods |= GhosttyMods(GHOSTTY_MODS_CTRL) }
        if contains(.alt) { mods |= GhosttyMods(GHOSTTY_MODS_ALT) }
        if contains(.super) { mods |= GhosttyMods(GHOSTTY_MODS_SUPER) }
        return mods
    }
}

extension SlateKey {
    /// `SlateKey` was defined to mirror libghostty's key names (both follow W3C
    /// `KeyboardEvent.code`), so this is a rename rather than a translation.
    var ghostty: GhosttyKey {
        switch self {
        case .a: GHOSTTY_KEY_A
        case .b: GHOSTTY_KEY_B
        case .c: GHOSTTY_KEY_C
        case .d: GHOSTTY_KEY_D
        case .e: GHOSTTY_KEY_E
        case .f: GHOSTTY_KEY_F
        case .g: GHOSTTY_KEY_G
        case .h: GHOSTTY_KEY_H
        case .i: GHOSTTY_KEY_I
        case .j: GHOSTTY_KEY_J
        case .k: GHOSTTY_KEY_K
        case .l: GHOSTTY_KEY_L
        case .m: GHOSTTY_KEY_M
        case .n: GHOSTTY_KEY_N
        case .o: GHOSTTY_KEY_O
        case .p: GHOSTTY_KEY_P
        case .q: GHOSTTY_KEY_Q
        case .r: GHOSTTY_KEY_R
        case .s: GHOSTTY_KEY_S
        case .t: GHOSTTY_KEY_T
        case .u: GHOSTTY_KEY_U
        case .v: GHOSTTY_KEY_V
        case .w: GHOSTTY_KEY_W
        case .x: GHOSTTY_KEY_X
        case .y: GHOSTTY_KEY_Y
        case .z: GHOSTTY_KEY_Z

        case .zero: GHOSTTY_KEY_DIGIT_0
        case .one: GHOSTTY_KEY_DIGIT_1
        case .two: GHOSTTY_KEY_DIGIT_2
        case .three: GHOSTTY_KEY_DIGIT_3
        case .four: GHOSTTY_KEY_DIGIT_4
        case .five: GHOSTTY_KEY_DIGIT_5
        case .six: GHOSTTY_KEY_DIGIT_6
        case .seven: GHOSTTY_KEY_DIGIT_7
        case .eight: GHOSTTY_KEY_DIGIT_8
        case .nine: GHOSTTY_KEY_DIGIT_9

        case .minus: GHOSTTY_KEY_MINUS
        case .equal: GHOSTTY_KEY_EQUAL
        case .bracketLeft: GHOSTTY_KEY_BRACKET_LEFT
        case .bracketRight: GHOSTTY_KEY_BRACKET_RIGHT
        case .backslash: GHOSTTY_KEY_BACKSLASH
        case .semicolon: GHOSTTY_KEY_SEMICOLON
        case .quote: GHOSTTY_KEY_QUOTE
        case .comma: GHOSTTY_KEY_COMMA
        case .period: GHOSTTY_KEY_PERIOD
        case .slash: GHOSTTY_KEY_SLASH
        case .backquote: GHOSTTY_KEY_BACKQUOTE

        case .escape: GHOSTTY_KEY_ESCAPE
        case .enter: GHOSTTY_KEY_ENTER
        case .tab: GHOSTTY_KEY_TAB
        case .space: GHOSTTY_KEY_SPACE
        case .backspace: GHOSTTY_KEY_BACKSPACE
        case .delete: GHOSTTY_KEY_DELETE
        case .home: GHOSTTY_KEY_HOME
        case .end: GHOSTTY_KEY_END
        case .pageUp: GHOSTTY_KEY_PAGE_UP
        case .pageDown: GHOSTTY_KEY_PAGE_DOWN
        case .insert: GHOSTTY_KEY_INSERT

        case .up: GHOSTTY_KEY_ARROW_UP
        case .down: GHOSTTY_KEY_ARROW_DOWN
        case .left: GHOSTTY_KEY_ARROW_LEFT
        case .right: GHOSTTY_KEY_ARROW_RIGHT

        case .f1: GHOSTTY_KEY_F1
        case .f2: GHOSTTY_KEY_F2
        case .f3: GHOSTTY_KEY_F3
        case .f4: GHOSTTY_KEY_F4
        case .f5: GHOSTTY_KEY_F5
        case .f6: GHOSTTY_KEY_F6
        case .f7: GHOSTTY_KEY_F7
        case .f8: GHOSTTY_KEY_F8
        case .f9: GHOSTTY_KEY_F9
        case .f10: GHOSTTY_KEY_F10
        case .f11: GHOSTTY_KEY_F11
        case .f12: GHOSTTY_KEY_F12

        case .keypadPlus: GHOSTTY_KEY_NUMPAD_ADD
        case .keypadMinus: GHOSTTY_KEY_NUMPAD_SUBTRACT
        }
    }
}
