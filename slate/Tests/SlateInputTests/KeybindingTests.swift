import Testing
@testable import SlateInput

@Suite("Keybindings")
struct KeybindingTests {
    @Test("Ghostty trigger syntax parses")
    func chordParsing() {
        #expect(Chord(parsing: "super+d") == Chord(.d, [.super]))
        #expect(Chord(parsing: "super+shift+d") == Chord(.d, [.super, .shift]))
        #expect(Chord(parsing: "ctrl+alt+delete") == Chord(.delete, [.control, .alt]))
        // Aliases Ghostty configs use interchangeably.
        #expect(Chord(parsing: "cmd+t") == Chord(parsing: "super+t"))
        #expect(Chord(parsing: "opt+left") == Chord(parsing: "alt+arrow_left"))
    }

    @Test("malformed triggers are rejected")
    func chordRejection() {
        #expect(Chord(parsing: "") == nil)
        #expect(Chord(parsing: "hyper+d") == nil)
        #expect(Chord(parsing: "super+nope") == nil)
    }

    @Test("no default binding is registered twice")
    func defaultsAreUnambiguous() {
        let chords = DefaultKeybindings.all.map(\.chord)
        let duplicates = Dictionary(grouping: chords, by: { $0 })
            .filter { $0.value.count > 1 }
            .keys
            .map(\.displayString)
        #expect(duplicates.isEmpty, "duplicate chords: \(duplicates)")
    }

    @Test("the defaults match Ghostty's macOS bindings")
    func ghosttyParity() {
        let map = DefaultKeybindings.keymap
        #expect(map.action(for: Chord(.t, [.super])) == .newTab)
        #expect(map.action(for: Chord(.d, [.super])) == .newSplit(.right))
        #expect(map.action(for: Chord(.d, [.super, .shift])) == .newSplit(.down))
        #expect(map.action(for: Chord(.w, [.super])) == .closeSurface)
        #expect(map.action(for: Chord(.k, [.super])) == .clearScreen)
        #expect(map.action(for: Chord(.zero, [.super])) == .resetFontSize)
        #expect(map.action(for: Chord(.enter, [.super, .shift])) == .toggleSplitZoom)
    }

    @Test("only super chords are claimed by the app")
    func terminalKeysAreNotStolen() {
        // The critical property: if the app claimed ^C or Esc, the terminal
        // would be unusable.
        #expect(DefaultKeybindings.isReservedForApp(Chord(.c, [.control])) == false)
        #expect(DefaultKeybindings.isReservedForApp(Chord(.escape, [])) == false)
        #expect(DefaultKeybindings.isReservedForApp(Chord(.d, [.control])) == false)
        #expect(DefaultKeybindings.isReservedForApp(Chord(.c, [.super])))

        for binding in DefaultKeybindings.all where !DefaultKeybindings.isReservedForApp(binding.chord) {
            // Everything not on ⌘ must be a chord the terminal doesn't need:
            // currently only shift+page up/down.
            #expect(
                binding.chord.key == .pageUp || binding.chord.key == .pageDown,
                "\(binding.chord.displayString) would be stolen from the terminal"
            )
        }
    }

    @Test("user config overrides defaults")
    func configOverrides() {
        var map = DefaultKeybindings.keymap
        let rejected = map.apply(configLines: [
            "# a comment",
            "",
            "keybind = super+t=new_split:down",
            "keybind = super+j=scroll_page_down",
        ])

        #expect(rejected.isEmpty)
        #expect(map.action(for: Chord(.t, [.super])) == .newSplit(.down))
        #expect(map.action(for: Chord(.j, [.super])) == .scrollPageDown)
    }

    @Test("unbind removes a default")
    func configUnbind() {
        var map = DefaultKeybindings.keymap
        #expect(map.action(for: Chord(.k, [.super])) == .clearScreen)
        map.apply(configLines: ["keybind = super+k=unbind"])
        #expect(map.action(for: Chord(.k, [.super])) == nil)
    }

    @Test("bad config lines are reported, not fatal")
    func configRejection() {
        var map = DefaultKeybindings.keymap
        let rejected = map.apply(configLines: [
            "keybind = super+t=new_tab",
            "keybind = nonsense=new_tab",
            "keybind = super+y=not_a_real_action",
        ])
        #expect(rejected.count == 2)
        // The good line still applied.
        #expect(map.action(for: Chord(.t, [.super])) == .newTab)
    }
}
