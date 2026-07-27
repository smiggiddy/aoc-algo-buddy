#if canImport(UIKit)
import Metal
import QuartzCore
import SlateInput
import SlateTerminal
import SlateTheme
import UIKit

/// The terminal surface itself: a `CAMetalLayer`-backed view driven by a
/// `CADisplayLink`, handling hardware keys, software keyboard text, and touch.
///
/// `CADisplayLink` rather than `MTKView`'s internal timer because we want to
/// drive redraws from "did the snapshot change", not from a fixed rate — an
/// idle terminal should cost nothing.
public final class MetalTerminalView: UIView, UIKeyInput {
    public override class var layerClass: AnyClass { CAMetalLayer.self }

    private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }

    private let surface: TerminalSurface
    private var renderer: TerminalRenderer?
    private var displayLink: CADisplayLink?

    private var lastDrawnGeneration: UInt64 = .max
    private var lastBlinkToggle: CFTimeInterval = 0
    private var blinkInterval: CFTimeInterval = 0.6

    /// Modifiers latched by the accessory bar, consumed by the next keypress.
    public var stickyModifiers: Modifiers = []

    /// Called when a latched modifier is consumed, so the bar can un-highlight.
    public var onStickyModifiersConsumed: (() -> Void)?

    /// Routed to the app layer, which owns tabs/splits/settings.
    public var onKeyAction: ((KeyAction) -> Bool)?

    public var themeProvider: () -> Theme = { BuiltinThemes.default }
    public var fontProvider: () -> (name: String, size: CGFloat, lineHeight: CGFloat) = { ("SF Mono", 14, 1.2) }
    public var backgroundOpacityProvider: () -> Double = { 1.0 }

    private var keymap: Keymap

    public init(surface: TerminalSurface, keymap: Keymap = DefaultKeybindings.keymap) {
        self.surface = surface
        self.keymap = keymap
        super.init(frame: .zero)

        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        // Opaque only when the theme is; a translucent terminal over the app's
        // material is the iPad look.
        metalLayer.isOpaque = backgroundOpacityProvider() >= 1.0

        isMultipleTouchEnabled = true
        setupGestures()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Lifecycle

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startDisplayLink()
            becomeFirstResponder()
        } else {
            stopDisplayLink()
        }
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(step))
        // Let the system pick within the range; an idle terminal drops to the
        // low end and stops costing battery.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let renderer, let drawable = metalLayer.nextDrawable() else { return }

        if link.timestamp - lastBlinkToggle >= blinkInterval {
            lastBlinkToggle = link.timestamp
            renderer.blinkIsOn.toggle()
            lastDrawnGeneration = .max // force a redraw for the blink phase
        }

        surface.refreshSnapshotIfNeeded()
        let snapshot = surface.snapshot
        guard snapshot.generation != lastDrawnGeneration else { return }
        lastDrawnGeneration = snapshot.generation

        renderer.draw(
            snapshot: snapshot,
            theme: themeProvider(),
            backgroundOpacity: backgroundOpacityProvider(),
            in: drawable,
            viewportSize: bounds.size
        )
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let scale = window?.screen.scale ?? UIScreen.main.scale
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        if renderer == nil, let device = metalLayer.device {
            let font = fontProvider()
            renderer = try? TerminalRenderer(
                device: device,
                pixelFormat: metalLayer.pixelFormat,
                fontName: font.name,
                fontSize: font.size,
                lineHeightMultiple: font.lineHeight,
                scale: scale
            )
        }

        resizeSurfaceToBounds()
    }

    /// Recomputes the grid and tells the surface (and through it, the backend).
    public func resizeSurfaceToBounds() {
        guard let renderer, bounds.width > 0, bounds.height > 0 else { return }
        let scale = metalLayer.contentsScale
        let size = renderer.gridSize(for: CGSize(
            width: bounds.width,
            height: bounds.height
        ))
        surface.resize(
            to: size,
            cellWidth: UInt32(renderer.cellWidth * scale),
            cellHeight: UInt32(renderer.cellHeight * scale)
        )
        lastDrawnGeneration = .max
    }

    /// Called when the font settings change (⌘+, ⌘−, ⌘0, or Settings).
    public func fontDidChange() {
        let font = fontProvider()
        renderer?.updateFont(name: font.name, size: font.size, lineHeightMultiple: font.lineHeight)
        resizeSurfaceToBounds()
    }

    // MARK: - Hardware keyboard

    public override var canBecomeFirstResponder: Bool { true }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false

        for press in presses {
            guard let key = press.key, let chord = Chord(key) else { continue }

            // Sticky modifiers from the accessory bar merge into the chord.
            var chordWithSticky = chord
            if !stickyModifiers.isEmpty {
                chordWithSticky.mods.formUnion(stickyModifiers)
                stickyModifiers = []
                onStickyModifiersConsumed?()
            }

            // App bindings win, but only ⌘ ones — everything else has to reach
            // the program, or ^C and Esc stop working.
            if DefaultKeybindings.isReservedForApp(chordWithSticky),
               let action = keymap.action(for: chordWithSticky),
               onKeyAction?(action) == true {
                handled = true
                continue
            }

            if surface.send(
                key: chordWithSticky.key,
                mods: chordWithSticky.mods,
                text: key.characters.isEmpty ? nil : key.characters
            ) {
                handled = true
            }
        }

        if !handled {
            super.pressesBegan(presses, with: event)
        }
    }

    // MARK: - Software keyboard (UIKeyInput)

    public var hasText: Bool { true }

    public func insertText(_ text: String) {
        // The software keyboard delivers composed text, including IME output.
        // It bypasses the key encoder deliberately: there is no physical key.
        if !stickyModifiers.isEmpty, let scalar = text.unicodeScalars.first, let key = SlateKey(parsing: String(scalar).lowercased()) {
            let mods = stickyModifiers
            stickyModifiers = []
            onStickyModifiersConsumed?()
            _ = surface.send(key: key, mods: mods, text: text)
            return
        }
        surface.send(text: text)
    }

    public func deleteBackward() {
        _ = surface.send(key: .backspace, mods: [])
    }

    public var keyboardType: UIKeyboardType {
        get { .asciiCapable }
        set { _ = newValue }
    }

    public var autocorrectionType: UITextAutocorrectionType {
        get { .no }
        set { _ = newValue }
    }

    public var autocapitalizationType: UITextAutocapitalizationType {
        get { .none }
        set { _ = newValue }
    }

    public var smartQuotesType: UITextSmartQuotesType {
        get { .no }
        set { _ = newValue }
    }

    public var smartDashesType: UITextSmartDashesType {
        get { .no }
        set { _ = newValue }
    }

    public var spellCheckingType: UITextSpellCheckingType {
        get { .no }
        set { _ = newValue }
    }

    /// Sends a key from the accessory bar as though it were pressed.
    public func sendAccessoryKey(_ key: SlateKey) {
        let mods = stickyModifiers
        if !mods.isEmpty {
            stickyModifiers = []
            onStickyModifiersConsumed?()
        }
        _ = surface.send(key: key, mods: mods)
    }

    // MARK: - Touch

    private func setupGestures() {
        let scroll = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scroll.allowedScrollTypesMask = .all
        addGestureRecognizer(scroll)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    private var scrollAccumulator: CGFloat = 0

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let renderer, renderer.cellHeight > 0 else { return }

        // When the program has asked for mouse tracking (vim, htop, tmux), a
        // drag belongs to it, not to our scrollback.
        guard !surface.wantsMouseTracking else { return }

        switch gesture.state {
        case .began:
            scrollAccumulator = 0
        case .changed:
            let translation = gesture.translation(in: self)
            gesture.setTranslation(.zero, in: self)
            scrollAccumulator += translation.y

            let lines = Int(scrollAccumulator / renderer.cellHeight)
            if lines != 0 {
                scrollAccumulator -= CGFloat(lines) * renderer.cellHeight
                surface.scroll(.delta(-lines))
                lastDrawnGeneration = .max
            }
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Tapping the terminal should raise the software keyboard on a device
        // with no hardware one, and focus this split either way.
        becomeFirstResponder()
    }
}
#endif
