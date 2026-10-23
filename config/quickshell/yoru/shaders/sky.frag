#version 440
// the weather over the wallpaper, one shader, picked by `kind`:
//   1 snow     flakes in layers, the near ones bigger, faster and drifting
//   2 rain     thin streaks, slanted by the wind
//   3 aurora   slow curtains of light across the top, in the palette's colours,
//              over a night drawn across the sky first when the picture is bright
//   4 fog      a haze rolling along the bottom
//   5 storm    heavy rain with the odd flash of lightning
//   6 fireflies  warm sparks drifting low and blinking, on summer evenings
//   7 petals   sakura tumbling down and sideways, in spring
//   8 leaves   autumn's, bigger and slower, swaying as they fall
//   9 clouds   their shadows drifting over the picture, on an overcast day
// over any of them, shooting stars (`meteors`, 0..1: how often) and the aurora swelling
// with the music (`pulse`, 0..1). `amount` (0..1) is how much of it there is.
// Out comes premultiplied colour.
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
    float veil;         // 0..1, how much night the aurora brings over a bright picture
    float meteors;      // 0..1, how often a shooting star crosses
    float pulse;        // 0..1, the music, for the aurora
    vec4 tint;          // flakes, drops and haze
    vec4 glowA;         // the aurora, low and high
    vec4 glowB;
    vec4 night;         // the colour of that night
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
        float base = 0.26 + fi * 0.06 + 0.08 * sin(x * 2.3 + fold * 5.0 + time * 0.04) + 0.07 * (fold - 0.5);
        float above = base - uv.y;                          // > 0 above the edge
        float body = smoothstep(-0.03, 0.025, above) * exp(-max(above, 0.0) / (0.15 + 0.06 * fi));
        // bright rays climbing out of the edge, and gaps where the curtain thins out
        float rays = 0.4 + 0.6 * noise(vec2(x * 45.0 + fold * 9.0, time * 0.12));
        float thin = smoothstep(0.25, 0.6, fbm(vec2(x * 0.6 - time * 0.025, fi * 3.0 + 1.0)));
        float glow = body * rays * thin;
        vec3 col = mix(glowA.rgb, glowB.rgb, clamp(above * 3.0, 0.0, 1.0)) * 1.3;
        float alpha = glow * mix(1.0, 0.6, fi / 2.0);
        // half added light, so it glows rather than just tints
        c += vec4(col * alpha, alpha * 0.5);
    }
    c = min(c * (0.6 + amount * 0.6), vec4(1.0));
    // the night behind it: a bright picture darkens from the top down first,
    // or the light has nothing to show against
    float v = veil * 0.82 * smoothstep(0.7, 0.0, uv.y);
    return c + vec4(night.rgb * v, v) * (1.0 - c.a);
}

float fog(vec2 uv, vec2 p) {
    float n = fbm(vec2(p.x * 1.6 + time * 0.035, p.y * 2.2 - time * 0.01));
    float m = fbm(vec2(p.x * 3.1 - time * 0.02, p.y * 3.0 + 4.0));
    float low = smoothstep(0.15, 1.0, uv.y);
    return clamp((n * 0.7 + m * 0.5 - 0.35) * low, 0.0, 1.0) * (0.4 + amount * 0.6);
}

// a soft round glow at f (cell-local), radius s
float dotGlow(vec2 f, float s) { return exp(-dot(f, f) / (s * s)); }

float fireflies(vec2 uv, vec2 p) {
    float a = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        vec2 g = p * mix(5.0, 9.0, fi / 2.0) + fi * 23.1;
        vec2 cell = floor(g);
        vec2 r = hash2(cell);
        if (r.x > 0.35 + amount * 0.5) continue;
        // a slow wander around the middle of its cell, and a blink of its own
        vec2 at = 0.5 + 0.32 * vec2(sin(time * (0.21 + r.y * 0.2) + r.x * 6.28), cos(time * (0.17 + r.x * 0.2) + r.y * 6.28));
        float blink = smoothstep(0.4, 1.0, sin(time * (0.7 + r.y) + r.x * 40.0) * 0.5 + 0.5);
        vec2 f = fract(g) - at;
        // a bright core in a wide halo
        a += (dotGlow(f, 0.022) + 0.5 * dotGlow(f, 0.09)) * blink * mix(1.0, 0.6, fi / 2.0);
    }
    // they keep low, over the grass
    return a * smoothstep(0.2, 0.65, uv.y);
}

// a falling thing that tumbles: petals (small, quick to spin) or leaves (big, slow)
vec4 tumble(vec2 p, bool leaf) {
    vec4 c = vec4(0.0);
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float near = 1.0 - fi / 3.0;
        float cells = leaf ? mix(9.0, 4.0, near) : mix(16.0, 7.0, near);
        float speed = (leaf ? 0.035 : 0.05) * mix(0.6, 1.0, near);
        vec2 q = p;
        q.y -= time * speed;
        q.x -= time * speed * (0.6 + wind) + sin(time * 0.6 + q.y * 3.0 + fi) * 0.03 * near;
        vec2 g = q * cells + fi * 41.3;
        vec2 cell = floor(g);
        vec2 r = hash2(cell);
        if (r.x > 0.12 + amount * 0.35) continue;
        vec2 f = fract(g) - 0.5 - (r - 0.5) * 0.5;
        // turning as it falls: the shape rotates, and squashes as it flips
        float ang = time * (leaf ? 0.6 : 1.3) * (r.y - 0.5) * 2.0 + r.x * 6.28;
        vec2 rf = mat2(cos(ang), -sin(ang), sin(ang), cos(ang)) * f;
        rf.y /= 0.35 + 0.65 * abs(sin(time * (leaf ? 0.7 : 1.1) + r.y * 6.28));
        float size = (leaf ? 0.2 : 0.11) * mix(0.75, 1.15, near);
        float shape = smoothstep(size, size * 0.6, length(rf * vec2(1.0, leaf ? 1.6 : 1.9)));
        vec3 col = leaf ? mix(vec3(0.85, 0.42, 0.12), vec3(0.72, 0.18, 0.08), r.y) * mix(0.8, 1.1, r.x)
                        : mix(vec3(1.0, 0.8, 0.87), vec3(0.98, 0.66, 0.78), r.y);
        float alpha = shape * mix(0.55, 0.95, near);
        c += vec4(col * alpha, alpha) * (1.0 - c.a);
    }
    return c;
}

float clouds(vec2 uv, vec2 p) {
    float n = fbm(vec2(p.x * 0.9 - time * 0.012, p.y * 0.9 + time * 0.004));
    return smoothstep(0.45, 0.75, n) * (0.18 + amount * 0.25);
}

// now and then a shooting star across the upper sky: a bright head and a fading tail
vec4 meteor(vec2 uv, vec2 p) {
    float every = mix(14.0, 2.5, meteors);              // seconds between them, at best
    float slot = floor(time / every);
    vec2 r = hash2(vec2(slot, 11.0));
    if (r.x > 0.35 + meteors * 0.6) return vec4(0.0);
    float t = (time - slot * every) / 0.9;              // each lasts about a second
    if (t > 1.0) return vec4(0.0);
    vec2 start = vec2((0.15 + r.y * 0.75) * aspect, 0.05 + r.x * 0.25);
    vec2 dir = normalize(vec2(-0.75 - r.y * 0.5, 0.42));
    vec2 head = start + dir * t * 0.55;
    vec2 d = p - head;
    float along = -dot(d, dir);                         // > 0 behind the head
    float across = abs(d.x * dir.y - d.y * dir.x);
    float tail = smoothstep(0.003, 0.0, across) * smoothstep(0.22, 0.0, along) * step(0.0, along);
    float glow = exp(-dot(d, d) / 0.00004);
    float a = clamp((tail * 0.8 + glow) * sin(t * 3.14159), 0.0, 1.0);
    return vec4(vec3(a), a * 0.9);
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
        // the music lifts it and brightens it
        c = aurora(uv, p) * (1.0 + pulse * 0.9);
        c.a = min(c.a, 1.0);
    } else if (k == 4) {
        float a = fog(uv, p);
        c = vec4(tint.rgb * a, a);
    } else if (k == 6) {
        float a = clamp(fireflies(uv, p), 0.0, 1.0);
        vec3 col = mix(vec3(0.82, 1.0, 0.45), tint.rgb, 0.25);
        c = vec4(col * a, a * 0.8);
    } else if (k == 7 || k == 8) {
        c = tumble(p, k == 8);
    } else if (k == 9) {
        float a = clouds(uv, p);
        c = vec4(night.rgb * a, a);
    }
    if (meteors > 0.0) {
        vec4 m = meteor(uv, p);
        c = m + c * (1.0 - m.a);
    }
    fragColor = c * qt_Opacity;
}
