#include <metal_stdlib>
using namespace metal;

// One instance per cell. The vertex shader expands each into a quad from the
// unit square, so there is no vertex buffer to manage — just instance data.
struct CellInstance {
    float2 origin;   // top-left in points
    float2 size;     // width/height in points
    float4 color;    // solid fill, or the tint for a glyph
    float4 uv;       // atlas rect (x, y, w, h) in normalised coords; unused for backgrounds
};

struct Uniforms {
    float2 viewportSize; // in points
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 uv;
};

// The unit quad, as two triangles. Indexed by vertex_id so the draw call is a
// plain non-indexed draw of 6 vertices per instance.
constant float2 kQuad[6] = {
    float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0),
    float2(1.0, 0.0), float2(1.0, 1.0), float2(0.0, 1.0),
};

static float4 toClipSpace(float2 point, float2 viewport) {
    // Points -> normalised device coords, with Y flipped so that (0,0) is the
    // top-left, matching how a terminal grid is addressed.
    float2 normalized = point / viewport;
    return float4(normalized.x * 2.0 - 1.0, 1.0 - normalized.y * 2.0, 0.0, 1.0);
}

vertex VertexOut cell_vertex(uint vertexID [[vertex_id]],
                             uint instanceID [[instance_id]],
                             const device CellInstance *instances [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    CellInstance instance = instances[instanceID];
    float2 corner = kQuad[vertexID];

    VertexOut out;
    out.position = toClipSpace(instance.origin + corner * instance.size, uniforms.viewportSize);
    out.color = instance.color;
    out.uv = instance.uv.xy + corner * instance.uv.zw;
    return out;
}

fragment float4 background_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}

fragment float4 glyph_fragment(VertexOut in [[stage_in]],
                               texture2d<float> atlas [[texture(0)]]) {
    constexpr sampler atlasSampler(mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    // The atlas stores coverage in a single channel; the cell's foreground
    // colour comes from the instance. This keeps the atlas colour-agnostic, so
    // a theme change never invalidates it.
    float coverage = atlas.sample(atlasSampler, in.uv).r;
    return float4(in.color.rgb, in.color.a * coverage);
}
