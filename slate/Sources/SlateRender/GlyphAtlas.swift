import CoreGraphics
import CoreText
import Foundation
import Metal
import SlateTerminal

/// A single-channel coverage texture holding rasterised glyphs, packed with a
/// shelf allocator.
///
/// Coverage-only (not colour) is deliberate: the fragment shader tints with the
/// cell's foreground colour, so switching themes never invalidates the atlas.
public final class GlyphAtlas {
    /// Identity of a rasterised glyph. Bold and italic get their own entries
    /// because they're different faces, not transforms.
    struct Key: Hashable {
        let text: String
        let bold: Bool
        let italic: Bool
    }

    struct Glyph {
        /// Normalised atlas rect.
        let uv: CGRect
        /// Offset from the cell's top-left to the bitmap's top-left, in points.
        let bearing: CGPoint
        /// Bitmap size in points.
        let size: CGSize
    }

    public private(set) var texture: MTLTexture
    /// Advance width of "M" — the grid's column width.
    public private(set) var cellWidth: CGFloat = 0
    /// Ascent + descent + leading, scaled by the line-height multiple.
    public private(set) var cellHeight: CGFloat = 0
    public private(set) var baseline: CGFloat = 0

    private let device: MTLDevice
    private let scale: CGFloat
    private var cache: [Key: Glyph] = [:]

    private var regular: CTFont
    private var bold: CTFont
    private var italic: CTFont
    private var boldItalic: CTFont

    // Shelf packing state, in texture pixels.
    private var cursorX = 1
    private var cursorY = 1
    private var shelfHeight = 0
    private let dimension: Int

    /// The bitmap we rasterise into before blitting to the texture. Reused so
    /// that adding a glyph mid-frame doesn't allocate.
    private var scratch: CGContext
    private let scratchSize = 256

    public init(
        device: MTLDevice,
        fontName: String,
        fontSize: CGFloat,
        lineHeightMultiple: CGFloat,
        scale: CGFloat,
        dimension: Int = 2048
    ) throws {
        self.device = device
        self.scale = scale
        self.dimension = dimension

        regular = Self.makeFont(named: fontName, size: fontSize, traits: [])
        bold = Self.makeFont(named: fontName, size: fontSize, traits: .traitBold)
        italic = Self.makeFont(named: fontName, size: fontSize, traits: .traitItalic)
        boldItalic = Self.makeFont(named: fontName, size: fontSize, traits: [.traitBold, .traitItalic])

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: dimension,
            height: dimension,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw RendererError.textureAllocationFailed
        }
        self.texture = texture

        guard let scratch = CGContext(
            data: nil,
            width: scratchSize,
            height: scratchSize,
            bitsPerComponent: 8,
            bytesPerRow: scratchSize,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw RendererError.textureAllocationFailed
        }
        self.scratch = scratch

        computeMetrics(lineHeightMultiple: lineHeightMultiple)
    }

    private static func makeFont(named name: String, size: CGFloat, traits: CTFontSymbolicTraits) -> CTFont {
        // Fall back through the monospace options iPadOS actually has, rather
        // than letting CoreText substitute a proportional face — a proportional
        // fallback in a terminal is instantly, obviously broken.
        let candidates = [name, "SF Mono", "Menlo", "Courier New"]
        for candidate in candidates {
            let base = CTFontCreateWithName(candidate as CFString, size, nil)
            if traits.isEmpty { return base }
            if let derived = CTFontCreateCopyWithSymbolicTraits(base, size, nil, traits, traits) {
                return derived
            }
            return base
        }
        return CTFontCreateWithName("Menlo" as CFString, size, nil)
    }

    private func computeMetrics(lineHeightMultiple: CGFloat) {
        var glyph = CGGlyph()
        var character: UniChar = 0x4D // "M"
        CTFontGetGlyphsForCharacters(regular, &character, &glyph, 1)

        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(regular, .horizontal, &glyph, &advance, 1)

        let ascent = CTFontGetAscent(regular)
        let descent = CTFontGetDescent(regular)
        let leading = CTFontGetLeading(regular)

        // Round to whole points: fractional cell widths accumulate into visible
        // column drift across an 80-column line.
        cellWidth = (advance.width).rounded(.up)
        cellHeight = ((ascent + descent + leading) * lineHeightMultiple).rounded(.up)
        baseline = ((cellHeight - (ascent + descent)) / 2 + ascent).rounded()
    }

    // MARK: - Lookup

    func glyph(for text: CellText, attributes: CellAttributes) -> Glyph? {
        guard !text.isEmpty else { return nil }
        let key = Key(
            text: text.string,
            bold: attributes.contains(.bold),
            italic: attributes.contains(.italic)
        )
        if let cached = cache[key] { return cached }
        guard let rasterised = rasterise(key) else { return nil }
        cache[key] = rasterised
        return rasterised
    }

    private func font(bold isBold: Bool, italic isItalic: Bool) -> CTFont {
        switch (isBold, isItalic) {
        case (true, true): boldItalic
        case (true, false): bold
        case (false, true): italic
        case (false, false): regular
        }
    }

    private func rasterise(_ key: Key) -> Glyph? {
        let font = font(bold: key.bold, italic: key.italic)
        let attributed = NSAttributedString(string: key.text, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        // A 1px margin stops linear sampling from bleeding a neighbour's edge in.
        let pixelWidth = Int((bounds.width * scale).rounded(.up)) + 2
        let pixelHeight = Int((bounds.height * scale).rounded(.up)) + 2
        guard pixelWidth <= scratchSize, pixelHeight <= scratchSize else { return nil }

        guard let origin = allocate(width: pixelWidth, height: pixelHeight) else { return nil }

        scratch.setFillColor(gray: 0, alpha: 1)
        scratch.fill(CGRect(x: 0, y: 0, width: scratchSize, height: scratchSize))
        scratch.saveGState()
        scratch.scaleBy(x: scale, y: scale)
        scratch.setFillColor(gray: 1, alpha: 1)
        // Position so the glyph's own bounds land at (1,1) in the scratch bitmap.
        scratch.textPosition = CGPoint(x: 1 / scale - bounds.minX, y: 1 / scale - bounds.minY)
        CTLineDraw(line, scratch)
        scratch.restoreGState()

        guard let data = scratch.data else { return nil }
        texture.replace(
            region: MTLRegionMake2D(origin.x, origin.y, pixelWidth, pixelHeight),
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: scratchSize
        )

        let dimension = CGFloat(self.dimension)
        return Glyph(
            uv: CGRect(
                x: CGFloat(origin.x) / dimension,
                y: CGFloat(origin.y) / dimension,
                width: CGFloat(pixelWidth) / dimension,
                height: CGFloat(pixelHeight) / dimension
            ),
            // CoreText's Y grows up, the grid's grows down; flip here so the
            // renderer can stay in grid coordinates.
            bearing: CGPoint(x: bounds.minX - 1 / scale, y: -bounds.maxY - 1 / scale),
            size: CGSize(width: CGFloat(pixelWidth) / scale, height: CGFloat(pixelHeight) / scale)
        )
    }

    /// Shelf allocation: fill a row left to right, then start a new row below.
    /// Cheap, and near-optimal for glyphs, which are all roughly one height.
    private func allocate(width: Int, height: Int) -> (x: Int, y: Int)? {
        if cursorX + width + 1 > dimension {
            cursorX = 1
            cursorY += shelfHeight + 1
            shelfHeight = 0
        }
        guard cursorY + height + 1 <= dimension else {
            // Atlas full. Rather than evicting (which would need per-frame
            // reference tracking), drop the glyph — the caller renders a blank.
            // In practice 2048x2048 holds far more than a session ever uses.
            return nil
        }
        let origin = (x: cursorX, y: cursorY)
        cursorX += width + 1
        shelfHeight = max(shelfHeight, height)
        return origin
    }

    /// Rebuilds for a new font or size. Cheaper and simpler than invalidating
    /// selectively, and it only happens on ⌘+/⌘− or a settings change.
    public func reset(fontName: String, fontSize: CGFloat, lineHeightMultiple: CGFloat) {
        regular = Self.makeFont(named: fontName, size: fontSize, traits: [])
        bold = Self.makeFont(named: fontName, size: fontSize, traits: .traitBold)
        italic = Self.makeFont(named: fontName, size: fontSize, traits: .traitItalic)
        boldItalic = Self.makeFont(named: fontName, size: fontSize, traits: [.traitBold, .traitItalic])
        cache.removeAll(keepingCapacity: true)
        cursorX = 1
        cursorY = 1
        shelfHeight = 0
        computeMetrics(lineHeightMultiple: lineHeightMultiple)
    }
}

public enum RendererError: Error {
    case metalUnavailable
    case textureAllocationFailed
    case shaderLibraryMissing
    case pipelineCreationFailed
}
