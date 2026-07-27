import SlateInput
import SlateTerminal
import SlateTheme
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { themeStore.theme(systemIsDark: colorScheme == .dark) }

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            TabStrip()
            Divider().overlay(theme.background.color.opacity(0.001))

            if let tab = model.selectedTab {
                SplitContainer(tab: tab)
                    .id(tab.id)
            } else {
                Color.clear
            }

            AccessoryBar()
        }
        .background(theme.background.color.ignoresSafeArea())
        .sheet(isPresented: $model.isShowingSettings) {
            SettingsView()
                .environment(model)
                .environment(themeStore)
        }
        .sheet(isPresented: $model.isShowingCommandPalette) {
            CommandPaletteView()
                .environment(model)
                .presentationDetents([.medium, .large])
                .presentationBackground(.regularMaterial)
        }
        // Registering the ⌘ chords as SwiftUI commands is what surfaces them in
        // the iPadOS ⌘-held overlay. Non-⌘ chords are deliberately absent —
        // those belong to the terminal.
        .background(KeyCommandHost())
    }
}

// MARK: - Tabs

private struct TabStrip: View {
    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { themeStore.theme(systemIsDark: colorScheme == .dark) }

    var body: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(model.tabs) { tab in
                        TabChip(tab: tab, isSelected: tab.id == model.selectedTabID)
                            .onTapGesture { model.selectedTabID = tab.id }
                    }
                }
                .padding(.horizontal, 10)
            }

            Button {
                model.perform(.newTab)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.foreground.color.opacity(0.7))

            Button {
                model.perform(.openSettings)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.foreground.color.opacity(0.7))
            .padding(.trailing, 10)
        }
        .frame(height: 40)
        .background(.ultraThinMaterial)
    }
}

private struct TabChip: View {
    let tab: TerminalTab
    let isSelected: Bool

    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { themeStore.theme(systemIsDark: colorScheme == .dark) }

    var body: some View {
        HStack(spacing: 6) {
            if tab.hasUnreadBell {
                Circle()
                    .fill(theme.ansi[3].color)
                    .frame(width: 6, height: 6)
            }

            Text(tab.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .rounded))
                .lineLimit(1)
                .truncationMode(.middle)

            Button {
                model.closeTab(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 0.6 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: 90, maxWidth: 200)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? theme.background.color.opacity(0.85) : .clear)
        }
        .foregroundStyle(theme.foreground.color.opacity(isSelected ? 1 : 0.55))
        .contentShape(Rectangle())
    }
}

// MARK: - Splits

private struct SplitContainer: View {
    let tab: TerminalTab

    var body: some View {
        Group {
            if let zoomedID = tab.zoomedSurfaceID,
               let surface = tab.root.surfaces.first(where: { $0.id == zoomedID }) {
                PaneView(surface: surface, tab: tab)
            } else {
                SplitNodeView(node: tab.root, tab: tab)
            }
        }
        .padding(6)
    }
}

private struct SplitNodeView: View {
    let node: SplitNode
    let tab: TerminalTab

    var body: some View {
        switch node {
        case .leaf(let surface):
            PaneView(surface: surface, tab: tab)

        case .split(let split):
            GeometryReader { geometry in
                let isHorizontal = split.axis == .horizontal
                let total = isHorizontal ? geometry.size.width : geometry.size.height
                let firstExtent = total * split.ratio - 3

                let layout = isHorizontal
                    ? AnyLayout(HStackLayout(spacing: 6))
                    : AnyLayout(VStackLayout(spacing: 6))

                layout {
                    SplitNodeView(node: split.first, tab: tab)
                        .frame(
                            width: isHorizontal ? max(firstExtent, 40) : nil,
                            height: isHorizontal ? nil : max(firstExtent, 40)
                        )

                    SplitDivider(axis: split.axis) { delta in
                        let ratio = split.ratio + delta / total
                        tab.root.setRatio(ratio, forSplit: split.id)
                    }

                    SplitNodeView(node: split.second, tab: tab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

private struct SplitDivider: View {
    let axis: SplitNode.Axis
    let onDrag: (Double) -> Void

    @State private var isDragging = false

    var body: some View {
        Rectangle()
            .fill(.white.opacity(isDragging ? 0.25 : 0.08))
            .frame(
                width: axis == .horizontal ? 2 : nil,
                height: axis == .horizontal ? nil : 2
            )
            // A 2pt line is far too thin to hit with a finger; the content
            // shape gives it a 20pt target without changing the visuals.
            .contentShape(Rectangle().inset(by: -9))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        onDrag(axis == .horizontal ? value.translation.width : value.translation.height)
                    }
                    .onEnded { _ in isDragging = false }
            )
            .animation(.easeOut(duration: 0.15), value: isDragging)
    }
}

private struct PaneView: View {
    let surface: TerminalSurface
    let tab: TerminalTab

    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { themeStore.theme(systemIsDark: colorScheme == .dark) }
    private var isFocused: Bool { tab.focusedSurfaceID == surface.id }
    private var isSplit: Bool { tab.root.surfaces.count > 1 }

    var body: some View {
        TerminalPaneView(surface: surface, isFocused: isFocused)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                // Only draw a focus ring when there's more than one pane —
                // a permanent border around a single terminal is just noise.
                if isSplit {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isFocused ? theme.ansi[4].color.opacity(0.6) : .white.opacity(0.06),
                            lineWidth: 1
                        )
                }
            }
            .overlay(alignment: .bottom) {
                if let termination = surface.termination {
                    Text(termination.message)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                }
            }
            .onTapGesture {
                tab.focusedSurfaceID = surface.id
                surface.acknowledgeBell()
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Accessory bar

/// The keys an iPadOS software keyboard doesn't have but a terminal can't live
/// without. Hidden when a hardware keyboard is attached, since it's dead space
/// then.
private struct AccessoryBar: View {
    @Environment(AppModel.self) private var model
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { themeStore.theme(systemIsDark: colorScheme == .dark) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AccessoryKey.allCases) { key in
                    accessoryButton(for: key)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(height: 44)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func accessoryButton(for key: AccessoryKey) -> some View {
        let isLatched = isLatched(key)

        Button {
            switch key {
            case .control: model.toggleSticky(.control)
            case .alt: model.toggleSticky(.alt)
            default:
                if let slateKey = key.key { model.sendAccessoryKey(slateKey) }
            }
        } label: {
            Text(key.label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .frame(minWidth: 38, minHeight: 32)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isLatched ? theme.ansi[4].color.opacity(0.35) : .white.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.foreground.color.opacity(0.9))
    }

    private func isLatched(_ key: AccessoryKey) -> Bool {
        switch key {
        case .control: model.stickyModifiers.contains(.control)
        case .alt: model.stickyModifiers.contains(.alt)
        default: false
        }
    }
}

extension RGB {
    var color: Color {
        let (r, g, b) = components
        return Color(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: 1)
    }
}
