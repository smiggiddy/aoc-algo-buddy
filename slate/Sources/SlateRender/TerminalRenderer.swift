import Foundation
import Metal
import MetalKit
import simd
import SlateTerminal
import SlateTheme

/// Instance data, laid out to match `CellInstance` in Shaders.metal.
struct CellInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
    var uv: SIMD4<Float>
}

struct RendererUniforms {
    var viewportSize: SIMD2<Float>
}

/// Turns a `TerminalSnapshot` into two instanced draw calls: one for cell
/// backgrounds, one for glyphs.
///
/// Two calls total, regardless of grid size — the cost is in building the
/// instance arrays, not in the GPU work, which is why the buffers are reused
/// and the arrays are `reserveCapacity`'d up front.
public final class TerminalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let backgroundPipeline: MTLRenderPipelineState
    private let glyphPipeline: MTLRenderPipelineState

    public private(set) var atlas: GlyphAtlas

    private var backgroundInstances: [CellInstance] = []
    private var glyphInstances: [CellInstance] = []
    private var instanceBuffer: MTLBuffer?
    private var instanceBufferCapacity = 0

    /// Blink phase, advanced by the view's display link. Cursor and blinking
    /// text share it so they pulse together rather than beating against
    /// each other.
    public var blinkIsOn = true

    public var cellWidth: CGFloat { atlas.cellWidth }
    public var cellHeight: CGFloat { atlas.cellHeight }

    public init(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        fontName: String,
        fontSize: CGFloat,
        lineHeightMultiple: CGFloat,
        scale: CGFloat
    ) throws {
        self.device = device
        guard let commandQueue = device.makeCommandQueue() else { throw RendererError.metalUnavailable }
        self.commandQueue = commandQueue

        atlas = try GlyphAtlas(
            device: device,
            fontName: fontName,
            fontSize: fontSize,
            lineHeightMultiple: lineHeightMultiple,
            scale: scale
        )

        let library = try Self.makeLibrary(device: device)
        backgroundPipeline = try Self.makePipeline(
            device: device,
            library: library,
            vertex: "cell_vertex",
            fragment: "background_fragment",
            pixelFormat: pixelFormat
        )
        glyphPipeline = try Self.makePipeline(
            device: device,
            library: library,
            vertex: "cell_vertex",
            fragment: "glyph_fragment",
            pixelFormat: pixelFormat
        )
    }

    private static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        // SwiftPM compiles Shaders.metal into the module's resource bundle, not
        // the app's default library.
        if let library = try? device.makeDefaultLibrary(bundle: .module) { return library }
        if let library = device.makeDefaultLibrary() { return library }
        throw RendererError.shaderLibraryMissing
    }

    private static func makePipeline(
        device: MTLDevice,
        library: MTLLibrary,
        vertex: String,
        fragment: String,
        pixelFormat: MTLPixelFormat
    ) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertex)
        descriptor.fragmentFunction = library.makeFunction(name: fragment)
        descriptor.colorAttachments[0].pixelFormat = pixelFormat

        // Straight alpha blending, so glyph coverage composites over the
        // background pass.
        let attachment = descriptor.colorAttachments[0]!
        attachment.isBlendingEnabled = true
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.sourceAlphaBlendFactor = .sourceAlpha
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            throw RendererError.pipelineCreationFailed
        }
        return state
    }

    public func updateFont(name: String, size: CGFloat, lineHeightMultiple: CGFloat) {
        atlas.reset(fontName: name, fontSize: size, lineHeightMultiple: lineHeightMultiple)
    }

    /// Cell geometry that fits `size`, which is what the surface resizes to.
    public func gridSize(for size: CGSize) -> TerminalSize {
        guard cellWidth > 0, cellHeight > 0 else { return TerminalSize(columns: 80, rows: 24) }
        return TerminalSize(
            columns: UInt16(max(1, Int(size.width / cellWidth))),
            rows: UInt16(max(1, Int(size.height / cellHeight))),
            pixelWidth: UInt32(size.width),
            pixelHeight: UInt32(size.height)
        )
    }

    // MARK: - Drawing

    public func draw(
        snapshot: TerminalSnapshot,
        theme: Theme,
        backgroundOpacity: Double,
        in drawable: CAMetalDrawable,
        viewportSize: CGSize
    ) {
        buildInstances(snapshot: snapshot, theme: theme)
        guard uploadInstances() else { return }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        let (r, g, b) = snapshot.background.components
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: Double(r), green: Double(g), blue: Double(b), alpha: backgroundOpacity
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor),
              let instanceBuffer
        else { return }

        var uniforms = RendererUniforms(
            viewportSize: SIMD2(Float(viewportSize.width), Float(viewportSize.height))
        )

        encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<RendererUniforms>.stride, index: 1)

        if !backgroundInstances.isEmpty {
            encoder.setRenderPipelineState(backgroundPipeline)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6,
                instanceCount: backgroundInstances.count
            )
        }

        if !glyphInstances.isEmpty {
            encoder.setRenderPipelineState(glyphPipeline)
            encoder.setFragmentTexture(atlas.texture, index: 0)
            // Glyph instances live after the backgrounds in the same buffer;
            // offset the binding rather than using a second buffer.
            encoder.setVertexBuffer(
                instanceBuffer,
                offset: backgroundInstances.count * MemoryLayout<CellInstance>.stride,
                index: 0
            )
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6,
                instanceCount: glyphInstances.count
            )
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func buildInstances(snapshot: TerminalSnapshot, theme: Theme) {
        backgroundInstances.removeAll(keepingCapacity: true)
        glyphInstances.removeAll(keepingCapacity: true)

        let capacity = snapshot.columns * snapshot.rowCount
        backgroundInstances.reserveCapacity(capacity)
        glyphInstances.reserveCapacity(capacity)

        let width = Float(cellWidth)
        let height = Float(cellHeight)
        let defaultBackground = snapshot.background

        for (rowIndex, row) in snapshot.rows.enumerated() {
            let y = Float(rowIndex) * height

            for (columnIndex, cell) in row.cells.enumerated() {
                let x = Float(columnIndex) * width

                var foreground = cell.foreground
                var background = cell.background
                if cell.isSelected {
                    background = theme.selectionBackground
                    if let selectionForeground = theme.selectionForeground {
                        foreground = selectionForeground
                    }
                }

                // Skip default-background fills: on a typical screen that's the
                // large majority of cells, and the clear colour already covers
                // them.
                if background != defaultBackground {
                    backgroundInstances.append(CellInstance(
                        origin: SIMD2(x, y),
                        size: SIMD2(width, height),
                        color: background.simd,
                        uv: .zero
                    ))
                }

                guard !cell.attributes.contains(.invisible) else { continue }
                if cell.attributes.contains(.blink), !blinkIsOn { continue }

                if let glyph = atlas.glyph(for: cell.text, attributes: cell.attributes) {
                    // Faint is rendered as reduced alpha rather than a mixed
                    // colour, so it stays correct over any background.
                    let alpha: Float = cell.attributes.contains(.faint) ? 0.6 : 1.0
                    var color = foreground.simd
                    color.w = alpha

                    glyphInstances.append(CellInstance(
                        origin: SIMD2(
                            x + Float(glyph.bearing.x),
                            y + Float(atlas.baseline) + Float(glyph.bearing.y)
                        ),
                        size: SIMD2(Float(glyph.size.width), Float(glyph.size.height)),
                        color: color,
                        uv: SIMD4(
                            Float(glyph.uv.minX),
                            Float(glyph.uv.minY),
                            Float(glyph.uv.width),
                            Float(glyph.uv.height)
                        )
                    ))
                }

                appendDecorations(for: cell, x: x, y: y, width: width, height: height, color: foreground)
            }
        }

        appendCursor(snapshot: snapshot, theme: theme, width: width, height: height)
    }

    /// Underline, strikethrough, and overline are solid rules, so they go in
    /// the background pass — no atlas lookup needed.
    private func appendDecorations(
        for cell: TerminalCell,
        x: Float,
        y: Float,
        width: Float,
        height: Float,
        color: RGB
    ) {
        let thickness = max(1, (height / 16).rounded())

        func rule(atY offset: Float) {
            backgroundInstances.append(CellInstance(
                origin: SIMD2(x, y + offset),
                size: SIMD2(width, thickness),
                color: color.simd,
                uv: .zero
            ))
        }

        if cell.attributes.contains(.underline) { rule(atY: Float(atlas.baseline) + thickness) }
        if cell.attributes.contains(.strikethrough) { rule(atY: height * 0.55) }
        if cell.attributes.contains(.overline) { rule(atY: 0) }
    }

    private func appendCursor(snapshot: TerminalSnapshot, theme: Theme, width: Float, height: Float) {
        guard let cursor = snapshot.cursor, cursor.isVisible else { return }
        if cursor.isBlinking, !blinkIsOn { return }

        let x = Float(cursor.column) * width
        let y = Float(cursor.row) * height
        let color = theme.cursor.simd

        let (origin, size): (SIMD2<Float>, SIMD2<Float>) = switch cursor.style {
        case .block, .blockHollow:
            (SIMD2(x, y), SIMD2(width, height))
        case .bar:
            (SIMD2(x, y), SIMD2(max(1, width / 8), height))
        case .underline:
            (SIMD2(x, y + height - max(1, height / 12)), SIMD2(width, max(1, height / 12)))
        }

        backgroundInstances.append(CellInstance(
            origin: origin,
            size: size,
            color: color,
            uv: .zero
        ))
    }

    /// Grows the shared instance buffer as needed and copies both arrays in.
    private func uploadInstances() -> Bool {
        let total = backgroundInstances.count + glyphInstances.count
        guard total > 0 else { return false }

        if instanceBufferCapacity < total {
            // Over-allocate so a slowly growing screen doesn't reallocate every
            // frame.
            let capacity = max(total * 2, 4096)
            guard let buffer = device.makeBuffer(
                length: capacity * MemoryLayout<CellInstance>.stride,
                options: .storageModeShared
            ) else { return false }
            instanceBuffer = buffer
            instanceBufferCapacity = capacity
        }

        guard let instanceBuffer else { return false }
        let pointer = instanceBuffer.contents().bindMemory(to: CellInstance.self, capacity: instanceBufferCapacity)
        pointer.update(from: backgroundInstances, count: backgroundInstances.count)
        (pointer + backgroundInstances.count).update(from: glyphInstances, count: glyphInstances.count)
        return true
    }
}

extension RGB {
    var simd: SIMD4<Float> {
        let (r, g, b) = components
        return SIMD4(r, g, b, 1)
    }
}
