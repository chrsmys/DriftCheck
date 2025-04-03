//
//  GrogShader.metal
//  DriftCheckExample
//
//  Created by Chris Mays on 3/30/25.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 grogDistortion(float2 position, float time, float2 size, float intensity) {
    float2 uv = position / size;

    float waveX = sin((uv.y * 20.0) + (time * 3.0)) * 10.0;
    float waveY = cos((uv.x * 15.0) + (time * 2.0)) * 5.0;

    float2 offset = float2(waveX, waveY) * intensity;

    return position + offset;
}
