import Testing
@testable import SlateTheme

@Suite("Theme")
struct ThemeTests {
    @Test("every built-in theme defines 16 ANSI colours")
    func builtinsAreComplete() {
        for theme in BuiltinThemes.all {
            #expect(theme.ansi.count == 16, "\(theme.name) has \(theme.ansi.count) colours")
        }
    }

    @Test("built-in theme names are unique")
    func namesAreUnique() {
        let names = BuiltinThemes.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test("light themes are detected as light")
    func lightnessDetection() {
        #expect(BuiltinThemes.catppuccinLatte.isDark == false)
        #expect(BuiltinThemes.solarizedLight.isDark == false)
        #expect(BuiltinThemes.catppuccinMocha.isDark)
        #expect(BuiltinThemes.tokyoNight.isDark)
    }

    @Test("hex parsing round-trips")
    func hexRoundTrip() {
        let color = RGB(hex: "#89b4fa")
        #expect(color?.r == 0x89)
        #expect(color?.g == 0xb4)
        #expect(color?.b == 0xfa)
        #expect(color?.hex == "#89b4fa")
        #expect(RGB(hex: "89b4fa") == color)
    }

    @Test("malformed hex is rejected rather than trapping")
    func hexRejection() {
        #expect(RGB(hex: "") == nil)
        #expect(RGB(hex: "#fff") == nil)
        #expect(RGB(hex: "#gggggg") == nil)
        #expect(RGB(hex: "#1234567") == nil)
    }

    @Test("the 256-colour palette follows the xterm cube")
    func paletteGeneration() {
        let theme = BuiltinThemes.catppuccinMocha

        // 0-15 come from the theme itself.
        #expect(theme.paletteEntry(1) == theme.ansi[1])

        // 16 is the cube's origin: pure black.
        #expect(theme.paletteEntry(16) == RGB(r: 0, g: 0, b: 0))
        // 231 is the cube's far corner: pure white.
        #expect(theme.paletteEntry(231) == RGB(r: 255, g: 255, b: 255))
        // 232 starts the greyscale ramp at 8.
        #expect(theme.paletteEntry(232) == RGB(r: 8, g: 8, b: 8))
        #expect(theme.paletteEntry(255) == RGB(r: 238, g: 238, b: 238))

        #expect(theme.palette256.count == 256)
    }

    @Test("themes survive a JSON round trip")
    func codableRoundTrip() throws {
        let original = BuiltinThemes.tokyoNight
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        #expect(decoded == original)
    }
}
