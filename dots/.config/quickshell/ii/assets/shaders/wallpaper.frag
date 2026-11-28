#version 440
// Bake with qsb --qt6 --qsbversion 64 -o wallpaper.frag.qsb wallpaper.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D outgoing;
layout(binding = 2) uniform sampler2D incoming;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 viewport;
    int pattern;
};

const int Disc = 0, Stripes = 1, Tiles = 2, Pixelate = 3, Ripple = 4, Melt = 5;

float noiseAt(vec2 cell) {
    return fract(52.9829 * fract(dot(cell, vec2(0.06711, 0.00584))));
}

float reveal(float distance, float feather) {
    float edge = mix(-feather, 1.0 + feather, progress);
    return smoothstep(distance - feather, distance + feather, edge);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pixels = uv * viewport;
    float shortSide = min(viewport.x, viewport.y);
    vec2 oldUv = uv;
    vec2 newUv = uv;
    float amount = progress;

    if (pattern == Disc || pattern == Ripple) {
        vec2 offset = uv - 0.5;
        float radius = 2.0 * length(offset * viewport) / length(viewport);
        if (pattern == Ripple) {
            float wave = radius - progress;
            float band = 1.0 - smoothstep(0.0, 0.24, abs(wave));
            vec2 displacement = offset * sin(wave * 48.0) * band * 0.4 * progress * (1.0 - progress);
            oldUv += displacement;
            newUv -= displacement;
        }
        amount = reveal(radius, pattern == Disc ? 2.0 / length(viewport) : 0.09);
    } else if (pattern == Stripes) {
        float stripe = fract((pixels.x * 0.45 + pixels.y) * 7.0 / shortSide);
        amount = reveal(abs(stripe * 2.0 - 1.0), 7.0 / shortSide);
    } else if (pattern == Tiles) {
        vec2 tile = floor(pixels * 8.0 / shortSide);
        float start = noiseAt(tile) * 0.85;
        amount = smoothstep(start, start + 0.15, progress);
    } else if (pattern == Pixelate) {
        float block = floor(shortSide * 0.36 * progress * (1.0 - progress));
        if (block > 1.0) {
            oldUv = (floor(pixels / block) + 0.5) * block / viewport;
            newUv = oldUv;
        }
        amount = smoothstep(0.25, 0.75, progress);
    } else if (pattern == Melt) {
        float column = floor(pixels.x * 16.0 / shortSide);
        float drop = smoothstep(noiseAt(vec2(column, 0.0)) * 0.4, 1.0, progress);
        oldUv.y -= drop;
        amount = step(uv.y, drop);
    }

    fragColor = mix(texture(outgoing, oldUv), texture(incoming, newUv), amount) * qt_Opacity;
}
