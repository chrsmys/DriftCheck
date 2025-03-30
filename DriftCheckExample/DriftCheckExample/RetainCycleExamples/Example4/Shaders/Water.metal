#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    float2 uvs[4] = {
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = uvs[vertexID];
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> rippleTexture [[texture(0)]],
                              sampler samp [[sampler(0)]],
                              constant float &time [[buffer(0)]]) {
    float2 uv = in.texCoord;

    // Touch-driven ripple height
    float touchHeight = rippleTexture.sample(samp, uv).r;

    // Ambient wave pattern — smooth, calm ripples
    float ambient = sin((uv.x + time * 0.05) * 20.0) * cos((uv.y + time * 0.03) * 25.0) * 0.01;

    // Combined height field
    float height = touchHeight + ambient;

    // Offset UV for distortion
    float3 baseColor = float3(0.1, 0.4, 0.7);
    float3 highlight = float3(0.8, 0.95, 1.0);

    float mixFactor = clamp(height * 5.0, 0.0, 1.0);
    float3 color = mix(baseColor, highlight, mixFactor);

    // Alpha fades out when mixFactor is low (mostly baseColor = more see-through)
    float alpha = mix(0.0, 1.0, mixFactor);

    return float4(color, alpha);
}
