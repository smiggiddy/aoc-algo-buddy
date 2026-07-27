import SlateInput
import SwiftUI
import UIKit

/// Registers Slate's ⌘ chords as `UIKeyCommand`s.
///
/// Two reasons this exists rather than relying on the terminal view's
/// `pressesBegan`:
///
/// 1. iPadOS shows registered key commands in the ⌘-held discoverability
///    overlay. That's the entire shortcut-discovery story on iPad, and it's
///    free once the commands are registered.
/// 2. Some ⌘ chords (⌘W, ⌘N, ⌘T) are intercepted by the system before a view
///    ever sees them, unless claimed here with
///    `wantsPriorityOverSystemBehavior`.
///
/// Only ⌘ chords are registered. Registering ⌃ or bare keys would steal them
/// from the terminal — ⌃C has to reach the program, not the app.
struct KeyCommandHost: UIViewControllerRepresentable {
    @Environment(AppModel.self) private var model

    func makeUIViewController(context: Context) -> KeyCommandController {
        let controller = KeyCommandController()
        controller.model = model
        return controller
    }

    func updateUIViewController(_ controller: KeyCommandController, context: Context) {
        controller.model = model
        controller.rebuildCommandsIfNeeded()
    }
}

final class KeyCommandController: UIViewController {
    var model: AppModel?

    private var registeredBindings: [Keybinding] = []
    private var commands: [UIKeyCommand] = []

    override var keyCommands: [UIKeyCommand]? { commands }

    /// The responder chain has to reach us even though the Metal view is first
    /// responder — key commands walk up the chain, so this just needs to be in
    /// it, which it is by virtue of being a parent view controller.
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        rebuildCommandsIfNeeded()
    }

    func rebuildCommandsIfNeeded() {
        guard let model else { return }
        let bindings = model.keymap.bindings.filter { DefaultKeybindings.isReservedForApp($0.chord) }
        guard bindings != registeredBindings else { return }
        registeredBindings = bindings

        commands = bindings.compactMap { binding in
            binding.chord.makeKeyCommand(
                title: binding.action.title,
                action: #selector(handleKeyCommand(_:))
            )
        }
        // Indices into `registeredBindings`, so the selector can find its
        // action without encoding it in the selector name.
        for (index, command) in commands.enumerated() {
            command.propertyList = index
        }
    }

    @objc private func handleKeyCommand(_ sender: UIKeyCommand) {
        guard let index = sender.propertyList as? Int,
              let binding = registeredBindings[safe: index],
              let model
        else { return }
        model.perform(binding.action)
    }
}
