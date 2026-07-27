import SlateInput
import SlateRender
import SlateTerminal
import SlateTheme
import SwiftUI

/// Bridges `MetalTerminalView` into SwiftUI, wiring the environment's theme and
/// font through so the UIKit layer never reaches for global state.
struct TerminalPaneView: UIViewRepresentable {
    let surface: TerminalSurface
    let isFocused: Bool

    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> MetalTerminalView {
        let view = MetalTerminalView(surface: surface, keymap: model.keymap)

        view.themeProvider = { [weak themeStore] in
            themeStore?.theme(systemIsDark: context.environment.colorScheme == .dark) ?? BuiltinThemes.default
        }
        view.fontProvider = { [weak themeStore] in
            guard let themeStore else { return ("SF Mono", 14, 1.2) }
            return (themeStore.fontName, themeStore.fontSize, themeStore.lineHeightMultiple)
        }
        view.backgroundOpacityProvider = { [weak themeStore] in
            themeStore?.backgroundOpacity ?? 1.0
        }
        view.onKeyAction = { action in
            MainActor.assumeIsolated { model.perform(action) }
        }
        view.onStickyModifiersConsumed = {
            MainActor.assumeIsolated { context.coordinator.stickyModifiers = [] }
        }

        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: MetalTerminalView, context: Context) {
        surface.theme = themeStore.theme(systemIsDark: colorScheme == .dark)

        if context.coordinator.fontGeneration != model.fontGeneration {
            context.coordinator.fontGeneration = model.fontGeneration
            view.fontDidChange()
        }

        view.stickyModifiers = context.coordinator.stickyModifiers

        if isFocused, !view.isFirstResponder {
            view.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator {
        var view: MetalTerminalView?
        var fontGeneration = 0
        var stickyModifiers: Modifiers = [] {
            didSet { view?.stickyModifiers = stickyModifiers }
        }

        func send(_ key: SlateKey) {
            view?.sendAccessoryKey(key)
        }

        func toggleSticky(_ modifier: Modifiers) {
            stickyModifiers.formSymmetricDifference(modifier)
        }
    }
}
