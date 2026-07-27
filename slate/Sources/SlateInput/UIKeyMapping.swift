#if canImport(UIKit)
import UIKit

extension SlateKey {
    /// Maps a hardware key's HID usage to a physical key.
    ///
    /// We key off `UIKey.keyCode` rather than `characters` because a chord is
    /// positional: ⌘+D must fire on the D key regardless of the active layout,
    /// and a Dvorak or AZERTY user still expects Ghostty's bindings where their
    /// fingers are. Text input goes down a separate path.
    public init?(keyCode: UIKeyboardHIDUsage) {
        switch keyCode {
        case .keyboardA: self = .a
        case .keyboardB: self = .b
        case .keyboardC: self = .c
        case .keyboardD: self = .d
        case .keyboardE: self = .e
        case .keyboardF: self = .f
        case .keyboardG: self = .g
        case .keyboardH: self = .h
        case .keyboardI: self = .i
        case .keyboardJ: self = .j
        case .keyboardK: self = .k
        case .keyboardL: self = .l
        case .keyboardM: self = .m
        case .keyboardN: self = .n
        case .keyboardO: self = .o
        case .keyboardP: self = .p
        case .keyboardQ: self = .q
        case .keyboardR: self = .r
        case .keyboardS: self = .s
        case .keyboardT: self = .t
        case .keyboardU: self = .u
        case .keyboardV: self = .v
        case .keyboardW: self = .w
        case .keyboardX: self = .x
        case .keyboardY: self = .y
        case .keyboardZ: self = .z

        case .keyboard0: self = .zero
        case .keyboard1: self = .one
        case .keyboard2: self = .two
        case .keyboard3: self = .three
        case .keyboard4: self = .four
        case .keyboard5: self = .five
        case .keyboard6: self = .six
        case .keyboard7: self = .seven
        case .keyboard8: self = .eight
        case .keyboard9: self = .nine

        case .keyboardHyphen: self = .minus
        case .keyboardEqualSign: self = .equal
        case .keyboardOpenBracket: self = .bracketLeft
        case .keyboardCloseBracket: self = .bracketRight
        case .keyboardBackslash: self = .backslash
        case .keyboardSemicolon: self = .semicolon
        case .keyboardQuote: self = .quote
        case .keyboardComma: self = .comma
        case .keyboardPeriod: self = .period
        case .keyboardSlash: self = .slash
        case .keyboardGraveAccentAndTilde: self = .backquote

        case .keyboardEscape: self = .escape
        case .keyboardReturnOrEnter: self = .enter
        case .keyboardTab: self = .tab
        case .keyboardSpacebar: self = .space
        case .keyboardDeleteOrBackspace: self = .backspace
        case .keyboardDeleteForward: self = .delete
        case .keyboardHome: self = .home
        case .keyboardEnd: self = .end
        case .keyboardPageUp: self = .pageUp
        case .keyboardPageDown: self = .pageDown
        case .keyboardInsert: self = .insert

        case .keyboardUpArrow: self = .up
        case .keyboardDownArrow: self = .down
        case .keyboardLeftArrow: self = .left
        case .keyboardRightArrow: self = .right

        case .keyboardF1: self = .f1
        case .keyboardF2: self = .f2
        case .keyboardF3: self = .f3
        case .keyboardF4: self = .f4
        case .keyboardF5: self = .f5
        case .keyboardF6: self = .f6
        case .keyboardF7: self = .f7
        case .keyboardF8: self = .f8
        case .keyboardF9: self = .f9
        case .keyboardF10: self = .f10
        case .keyboardF11: self = .f11
        case .keyboardF12: self = .f12

        case .keypadPlus: self = .keypadPlus
        case .keypadHyphen: self = .keypadMinus
        case .keypadEnter: self = .enter

        default: return nil
        }
    }

    /// The `UIKeyCommand` input string for this key, for chords we register
    /// with the system (so they appear in the ⌘-held discoverability overlay).
    public var uiKeyCommandInput: String? {
        switch self {
        case .up: UIKeyCommand.inputUpArrow
        case .down: UIKeyCommand.inputDownArrow
        case .left: UIKeyCommand.inputLeftArrow
        case .right: UIKeyCommand.inputRightArrow
        case .escape: UIKeyCommand.inputEscape
        case .pageUp: UIKeyCommand.inputPageUp
        case .pageDown: UIKeyCommand.inputPageDown
        case .home: UIKeyCommand.inputHome
        case .end: UIKeyCommand.inputEnd
        case .enter: "\r"
        case .tab: "\t"
        case .space: " "
        case .backspace, .delete: nil
        case .bracketLeft: "["
        case .bracketRight: "]"
        case .minus, .keypadMinus: "-"
        case .equal: "="
        case .keypadPlus: "+"
        case .comma: ","
        case .period: "."
        case .slash: "/"
        case .backslash: "\\"
        case .semicolon: ";"
        case .quote: "'"
        case .backquote: "`"
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12, .insert: nil
        default: rawValue
        }
    }
}

extension Modifiers {
    public init(_ flags: UIKeyModifierFlags) {
        var mods: Modifiers = []
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.control) { mods.insert(.control) }
        if flags.contains(.alternate) { mods.insert(.alt) }
        if flags.contains(.command) { mods.insert(.super) }
        self = mods
    }

    public var uiKeyModifierFlags: UIKeyModifierFlags {
        var flags: UIKeyModifierFlags = []
        if contains(.shift) { flags.insert(.shift) }
        if contains(.control) { flags.insert(.control) }
        if contains(.alt) { flags.insert(.alternate) }
        if contains(.super) { flags.insert(.command) }
        return flags
    }
}

extension Chord {
    /// Builds a chord from a hardware key press. Returns nil for keys we have
    /// no physical mapping for — those fall through to text input.
    public init?(_ key: UIKey) {
        guard let slateKey = SlateKey(keyCode: key.keyCode) else { return nil }
        self.init(slateKey, Modifiers(key.modifierFlags))
    }

    /// A `UIKeyCommand` for this chord, or nil if the key can't be expressed as
    /// one. Registering these is what puts Slate's shortcuts in the iPadOS
    /// ⌘-held overlay, which is the discoverability story on iPad.
    public func makeKeyCommand(title: String, action: Selector) -> UIKeyCommand? {
        guard let input = key.uiKeyCommandInput else { return nil }
        let command = UIKeyCommand(
            title: title,
            action: action,
            input: input,
            modifierFlags: mods.uiKeyModifierFlags
        )
        // Without this, iPadOS beeps and shows an alert when a chord we handle
        // is also a system-reserved one.
        command.wantsPriorityOverSystemBehavior = true
        return command
    }
}
#endif
