#version 440
// the weather over the wallpaper, one shader, picked by `kind`:
//   1 snow     flakes in layers, the near ones bigger, faster and drifting
//   2 rain     thin streaks, slanted by the wind
//   3 aurora   slow curtains of light across the top, in the palette's colours
//   4 fog      a haze rolling along the bottom
//   5 storm    heavy rain with the odd flash of lightning
// `amount` (0..1) is how much of it there is. Out comes premultiplied colour.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float aspect;
    float kind;
    float amount;
    float wind;         // -1..1, which way and how hard things slant
    vec4 tint;          // flakes, drops and haze
    vec4 glowA;         // the aurora, low and high
    vec4 glowB;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * noise(p); p = p * 2.03 + 17.1; a *= 0.5; }
    return v;
}

float snow(vec2 p) {
    float a = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float near = 1.0 - fi / 5.0;                       // 1 the nearest layer .. 0.2 the farthest
        float cells = mix(22.0, 6.0, near);                // far flakes are smaller and closer together
        float speed = mix(0.025, 0.11, near);
        vec2 q = p;
        q.y -= time * speed;
        q.x -= time * speed * wind * 1.4 + sin(time * 0.5 + q.y * 4.0 + fi * 2.1) * 0.012 * near;
        vec2 g = q * cells + fi * 31.7;
        vec2 cell = floor(g);
        vec2 r = hash2(cell);
        if (r.x > 0.2 + amount * 0.6) continue;           // not every cell has a flake
        vec2 f = fract(g) - 0.5 - (r - 0.5) * 0.6;
        float size = mix(0.05, 0.13, r.y) * mix(0.8, 1.2, near);
        float flake = smoothstep(size, size * 0.25, length(f));
        a += flake * mix(0.35, 0.9, near);
    }
    return a;
}

float rain(vec2 p, float heavy) {
    float a = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float near = 1.0 - fi / 4.0;
        vec2 q = p;
        q.x += q.y * wind * 0.35;                           // the slant
        q.y -= time * mix(0.9, 1.9, near) * (1.0 + heavy * 0.3);
        q.x -= time * wind * 0.3;
        vec2 cells = vec2(mix(110.0, 45.0, near), mix(5.0, 2.5, near));
        vec2 g = q * cells + fi * 17.3;
        vec2 cell = floor(g);
        vec2 r = hash2(cell);
        if (r.x > 0.15 + (amount + heavy * 0.3) * 0.55) continue;
        vec2 f = fract(g);
        float x = abs(f.x - 0.2 - r.y * 0.6);
        float len = mix(0.25, 0.6, r.y);
        float y = f.y - r.x;                                // where along the cell the drop is
        float streak = smoothstep(0.12, 0.0, x) * smoothstep(0.0, 0.08, y) * smoothstep(len, 0.0, y);
        a += streak * mix(0.25, 0.65, near);
    }
    return a;
}

vec4 aurora(vec2 uv, vec2 p) {
    vec4 c = vec4(0.0);
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float x = p.x * 0.8 + fi * 3.7;
        // the curtain folds: its lower edge sways in long waves that drift sideways
        float fold = fbm(vec2(x * 0.9 + time * 0.015, fi * 5.0));
        float base = 0.2 + fi * 0.06 + 0.09 * sin(x * 2.3 + fold * 5.0 + time * 0.04) + 0.06 * (fold - 0.5);
        float above = base - uv.y;                          // > 0 above the edge
        float body = smoothstep(-0.03, 0.025, above) * exp(-max(above, 0.0) / (0.1 + 0.05 * fi));
        // bright rays climbing out of the edge, and gaps where the curtain thins out
        float rays = 0.4 + 0.6 * noise(vec2(x * 45.0 + fold * 9.0, time * 0.12));
        float thin = smoothstep(0.35, 0.7, fbm(vec2(x * 0.6 - time * 0.025, fi * 3.0 + 1.0)));
        float glow = body * rays * thin;
        vec3 col = mix(glowA.rgb, glowB.rgb, clamp(above * 4.0, 0.0, 1.0)) * 1.25;
        float alpha = glow * mix(1.0, 0.6, fi / 2.0);
        // half added light, so it glows over bright pictures too, not just tints them
        c += vec4(col * alpha, alpha * 0.5);
    }
    return c * (0.35 + amount * 0.65);
}

float fog(vec2 uv, vec2 p) {
    float n = fbm(vec2(p.x * 1.6 + time * 0.035, p.y * 2.2 - time * 0.01));
    float m = fbm(vec2(p.x * 3.1 - time * 0.02, p.y * 3.0 + 4.0));
    float low = smoothstep(0.15, 1.0, uv.y);
    return clamp((n * 0.7 + m * 0.5 - 0.35) * low, 0.0, 1.0) * (0.4 + amount * 0.6);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = vec2(uv.x * aspect, uv.y);
    int k = int(kind + 0.5);
    vec4 c = vec4(0.0);

    if (k == 1) {
        float a = clamp(snow(p), 0.0, 1.0) * 0.85;
        c = vec4(tint.rgb * a, a);
    } else if (k == 2 || k == 5) {
        float heavy = k == 5 ? 1.0 : 0.0;
        float a = clamp(rain(p, heavy), 0.0, 1.0) * 0.8;
        c = vec4(tint.rgb * a, a);
        if (k == 5) {
            // a flash now and then: a few seconds apart, sometimes twice
            float slot = floor(time / 4.0);
            float t = time - slot * 4.0 - hash(vec2(slot, 3.0)) * 2.5;
            float flash = hash(vec2(slot, 7.0)) < 0.35 ? exp(-t * t * 90.0) + 0.6 * exp(-pow(t - 0.18, 2.0) * 160.0) : 0.0;
            float f = clamp(flash, 0.0, 1.0) * 0.22 * (1.0 - uv.y * 0.5);
            c = c * (1.0 - f) + vec4(vec3(f), f);
        }
    } else if (k == 3) {
        c = aurora(uv, p);
    } else if (k == 4) {
        float a = fog(uv, p);
        c = vec4(tint.rgb * a, a);
    }
    fragColor = c * qt_Opacity;
}
