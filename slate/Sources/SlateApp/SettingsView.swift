import SlateInput
import SlateTheme
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var themeStore = themeStore

        NavigationStack {
            Form {
                Section("Theme") {
                    ThemeGrid()

                    Toggle("Follow system appearance", isOn: $themeStore.followsSystemAppearance)

                    if themeStore.followsSystemAppearance {
                        Picker("Light theme", selection: $themeStore.lightThemeName) {
                            ForEach(themeStore.availableThemes.filter { !$0.isDark }) { theme in
                                Text(theme.name).tag(theme.name)
                            }
                        }
                    }
                }

                Section("Font") {
                    Picker("Family", selection: $themeStore.fontName) {
                        ForEach(["SF Mono", "Menlo", "Courier New"], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }

                    LabeledContent("Size") {
                        HStack {
                            Slider(
                                value: $themeStore.fontSize,
                                in: ThemeStore.fontSizeRange,
                                step: 1
                            )
                            Text("\(Int(themeStore.fontSize))")
                                .monospacedDigit()
                                .frame(width: 28, alignment: .trailing)
                        }
                    }

                    LabeledContent("Line height") {
                        HStack {
                            Slider(value: $themeStore.lineHeightMultiple, in: 1.0...1.8, step: 0.05)
                            Text(String(format: "%.2f", themeStore.lineHeightMultiple))
                                .monospacedDigit()
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }

                Section {
                    LabeledContent("Background opacity") {
                        HStack {
                            Slider(value: $themeStore.backgroundOpacity, in: 0.5...1.0, step: 0.05)
                            Text(String(format: "%.0f%%", themeStore.backgroundOpacity * 100))
                                .monospacedDigit()
                                .frame(width: 46, alignment: .trailing)
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Below 100% the terminal composites over the window material.")
                }

                Section {
                    NavigationLink("Keyboard shortcuts") {
                        KeybindingList()
                    }
                } footer: {
                    Text("Drop a `keybindings.conf` into the app's Documents folder to override these. Ghostty's `keybind = trigger=action` syntax; reload with ⌘⇧,")
                }

                Section {
                    LabeledContent("Themes folder", value: "Documents/Themes")
                    Button("Reload themes and shortcuts") {
                        themeStore.reloadUserThemes()
                        model.loadUserKeybindings()
                    }
                } footer: {
                    Text("Custom themes are JSON with the same fields as the built-ins, using `#rrggbb` colours.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: themeStore.fontSize) { _, _ in model.notifyFontChanged() }
        .onChange(of: themeStore.fontName) { _, _ in model.notifyFontChanged() }
        .onChange(of: themeStore.lineHeightMultiple) { _, _ in model.notifyFontChanged() }
    }
}

/// Theme picker as swatch cards — a colour scheme is a visual choice, and a
/// list of names makes you guess.
private struct ThemeGrid: View {
    @Environment(ThemeStore.self) private var themeStore

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(themeStore.availableThemes) { theme in
                ThemeSwatch(
                    theme: theme,
                    isSelected: theme.name == themeStore.darkThemeName
                )
                .onTapGesture { themeStore.darkThemeName = theme.name }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ThemeSwatch: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // A miniature of what the theme actually looks like: prompt colour,
            // a couple of ANSI colours, foreground text.
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 3) {
                    Rectangle().fill(theme.ansi[5].color).frame(width: 8, height: 6)
                    Rectangle().fill(theme.ansi[4].color).frame(width: 26, height: 6)
                    Rectangle().fill(theme.foreground.color.opacity(0.6)).frame(width: 16, height: 6)
                }
                HStack(spacing: 3) {
                    Rectangle().fill(theme.ansi[2].color).frame(width: 18, height: 6)
                    Rectangle().fill(theme.foreground.color.opacity(0.35)).frame(width: 34, height: 6)
                }
                HStack(spacing: 3) {
                    Rectangle().fill(theme.ansi[1].color).frame(width: 12, height: 6)
                    Rectangle().fill(theme.ansi[3].color).frame(width: 22, height: 6)
                    Rectangle().fill(theme.cursor.color).frame(width: 6, height: 6)
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.background.color)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(theme.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(Rectangle())
    }
}

private struct KeybindingList: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List(model.keymap.bindings) { binding in
            LabeledContent(binding.action.title) {
                Text(binding.chord.displayString)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
