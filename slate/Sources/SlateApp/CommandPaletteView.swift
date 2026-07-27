import SlateInput
import SwiftUI

/// ⌘⇧P. Every bound action, searchable, with its shortcut alongside — which
/// doubles as the shortcut reference on a device with no hardware keyboard.
struct CommandPaletteView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    private var results: [Keybinding] {
        let bindings = model.keymap.bindings
        guard !query.isEmpty else { return bindings }
        return bindings.filter {
            $0.action.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { binding in
                Button {
                    dismiss()
                    // Let the sheet finish dismissing before mutating state the
                    // presenting view depends on.
                    Task { @MainActor in
                        model.perform(binding.action)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: binding.action.symbolName)
                            .font(.system(size: 13))
                            .frame(width: 22)
                            .foregroundStyle(.secondary)

                        Text(binding.action.title)

                        Spacer()

                        Text(binding.chord.displayString)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Run a command")
            .navigationTitle("Commands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
