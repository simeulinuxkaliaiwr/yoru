#version 440
// yoru's shader visualizer styles, picked by `mode`:
//   0 aurora  curtains of light rising off the bottom, rays drifting through them
//   1 silk    glowing ribbons mirrored about the middle, like a wave on still water
// `levels` is cava's 64 bars as a 64x1 texture (red = height), so the GPU's
// linear filtering already joins the bars into one smooth line.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float mode;
    float aspect;
    vec4 c1;    // primary
    vec4 c2;    // tertiary
    vec4 c3;    // secondary
};
layout(binding = 1) uniform sampler2D levels;

// a level at x, softened with its neighbours so peaks read as hills, not spikes
float level(float x) {
    float s = 0.0, w = 0.0;
    for (int i = -3; i <= 3; i++) {
        float k = exp(-float(i * i) / 4.0);
        s += texture(levels, vec2(clamp(x + float(i) / 80.0, 0.0, 1.0), 0.5)).r * k;
        w += k;
    }
    return s / w;
}

vec3 aurora(vec2 uv, out float a) {
    float yb = 1.0 - uv.y;      // 0 at the bottom
    vec3 col = vec3(0.0);
    a = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        // each curtain sways a little on its own, so they never line up
        float x = uv.x + 0.012 * sin(time * (0.35 + 0.1 * fi) + fi * 2.1 + uv.x * 3.0);
        float h = 0.05 + level(x) * (0.92 - 0.22 * fi);
        if (h <= 0.0)
            continue;
        // rays: thin vertical streaks that wander
        float rays = 0.72 + 0.28 * sin(uv.x * aspect * (34.0 + 9.0 * fi) + time * (1.1 + 0.3 * fi)
                                       + 2.5 * sin(uv.x * 6.0 - time * 0.5 + fi));
        float inside = smoothstep(h + 0.015, h - 0.015, yb);
        // the curtain: brightest under its crest, thinning toward the bottom, streaked by the rays
        float body = inside * (0.1 + 0.9 * pow(clamp(yb / h, 0.0, 1.0), 1.3)) * rays;
        float crest = exp(-abs(yb - h) * 70.0);
        // a haze over the crest only (under it, the curtain is the light)
        float glow = (1.0 - inside) * exp(-(yb - h) * 14.0) * smoothstep(0.0, 0.5, h) * 0.35;
        float k = (body * 0.7 + crest * 0.9 + glow) * (1.0 - 0.28 * fi);
        // low in the curtain the primary, high up the tertiary, the secondary drifting across
        vec3 tint = mix(c1.rgb, c2.rgb, clamp(yb / max(h, 0.05) * 0.9 + 0.1 * fi, 0.0, 1.0));
        tint = mix(tint, c3.rgb, 0.25 * (0.5 + 0.5 * sin(uv.x * 4.0 + time * 0.2 + fi * 1.7)));
        col += tint * k;
        a += k;
    }
    // light adds up: brighten toward white where curtains overlap, keep it from clipping hard
    a = clamp(a, 0.0, 1.0);
    col = col / max(1.0, max(col.r, max(col.g, col.b)));
    return col;
}

vec3 silk(vec2 uv, out float a) {
    float d = abs(uv.y - 0.5) * 2.0;    // 0 on the middle line, 1 at the edges
    vec3 col = vec3(0.0);
    a = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float x = uv.x + 0.02 * sin(time * 0.4 + fi * 2.4);
        // each ribbon is its own size, breathing slowly against the others
        float amp = (0.04 + level(x) * 0.9) * (1.0 - 0.27 * fi) * (0.9 + 0.1 * sin(time * 0.8 + fi * 1.3 + uv.x * 5.0));
        float edge = exp(-abs(d - amp) * (60.0 - 12.0 * fi));
        float fill = smoothstep(amp + 0.01, amp - 0.01, d) * (0.08 + 0.35 * pow(clamp(d / amp, 0.0, 1.0), 3.0));
        float k = (edge * 0.85 + fill) * (1.0 - 0.25 * fi);
        vec3 tint = mix(c1.rgb, c2.rgb, clamp(uv.x + 0.25 * fi - 0.1, 0.0, 1.0));
        col += mix(tint, c3.rgb, 0.3 * fi / 2.0) * k;
        a += k;
    }
    // the middle line itself, faint, so silence still shows a thread
    float line = exp(-d * 90.0) * 0.35;
    col += mix(c1.rgb, c2.rgb, uv.x) * line;
    a += line;
    // the edges of the strip fade out instead of ending
    float side = smoothstep(0.0, 0.04, uv.x) * smoothstep(1.0, 0.96, uv.x);
    a = clamp(a, 0.0, 1.0) * side;
    col = col / max(1.0, max(col.r, max(col.g, col.b))) * side;
    return col;
}

void main() {
    float a;
    vec3 col = mode < 0.5 ? aurora(qt_TexCoord0, a) : silk(qt_TexCoord0, a);
    fragColor = vec4(col, a) * qt_Opacity;      // col already carries a: premultiplied
}
