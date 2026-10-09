#version 440
// yoru's wallpaper transitions, one shader, picked by `mode`:
//   0 ripple     the new picture spills out of a point, bending light at its edge
//   1 fade       a plain crossfade
//   2 wipe       a soft line sweeping across at `angle`
//   3 disc       a circle growing from `origin`
//   4 stripes    diagonal bands sliding in one after another
//   5 zoom       the old one falls away while the new one settles in
//   6 honeycomb  hexagons opening outward from `origin`
//   7 pixelate   both pictures break into blocks and resolve again
// `smoothness` (0..1) is how soft every edge is.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    float mode;
    float smoothness;
    float angle;
    float seed;
    vec2 origin;
};
layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;

const float PI = 3.14159265;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.0) * 43758.5453);
}

// how far the farthest corner is from `o`, in aspect-corrected units
float farFrom(vec2 o) {
    return length(vec2(max(o.x, 1.0 - o.x) * aspect, max(o.y, 1.0 - o.y)));
}

// 0 where the old picture shows, 1 where the new one does: a front at
// `progress` passing over x (0..1), with a soft edge
float front(float x, float e) {
    return smoothstep(0.0, e, progress * (1.0 + e) - x);
}

vec4 ripple(vec2 uv, float e) {
    vec2 d = uv - origin;
    d.x *= aspect;
    float dist = length(d);
    float edge = 0.04 + e * 0.5;
    float r = progress * (farFrom(origin) + edge * 2.0);
    float t = smoothstep(r - edge, r, dist);
    float ring = exp(-pow((dist - r + edge * 0.5) / 0.07, 2.0));
    float fade = 1.0 - progress;
    vec2 dir = dist > 0.0001 ? d / dist : vec2(0.0);
    dir.x /= aspect;
    vec2 bend = dir * ring * 0.03 * fade;
    vec4 a = texture(from, clamp(uv + bend, 0.0, 1.0));
    vec4 b = texture(to, clamp(uv - bend * 0.5, 0.0, 1.0));
    vec4 c = mix(b, a, t);
    c.rgb += ring * 0.07 * fade;
    return c;
}

vec4 hexCell(vec2 p) {
    const vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    return vec4(gv, p - gv);
}

float hexDist(vec2 p) {
    p = abs(p);
    return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float e = mix(0.004, 0.3, smoothness);
    int m = int(mode + 0.5);
    vec2 pa = vec2(uv.x * aspect, uv.y);           // aspect-corrected
    vec4 a = texture(from, uv);
    vec4 b = texture(to, uv);
    vec4 c;

    if (m == 0) {
        c = ripple(uv, e);
    } else if (m == 1) {
        c = mix(a, b, smoothstep(0.0, 1.0, progress));
    } else if (m == 2) {
        vec2 dir = vec2(cos(angle), sin(angle));
        float span = 0.5 * (abs(dir.x) * aspect + abs(dir.y));
        float x = (dot(pa - vec2(0.5 * aspect, 0.5), dir) + span) / (2.0 * span);
        c = mix(a, b, front(x, e));
    } else if (m == 3) {
        vec2 o = vec2(origin.x * aspect, origin.y);
        float x = length(pa - o) / farFrom(origin);
        c = mix(a, b, front(x, e));
    } else if (m == 4) {
        float n = 14.0;
        vec2 dir = vec2(cos(angle), sin(angle));
        vec2 nrm = vec2(-dir.y, dir.x);
        float span = 0.5 * (abs(dir.x) * aspect + abs(dir.y));
        float spanN = 0.5 * (abs(nrm.x) * aspect + abs(nrm.y));
        vec2 q = pa - vec2(0.5 * aspect, 0.5);
        float along = (dot(q, dir) + span) / (2.0 * span);
        float across = (dot(q, nrm) + spanN) / (2.0 * spanN);
        float i = floor(across * n);
        float x = mod(i, 2.0) < 1.0 ? along : 1.0 - along;   // alternate bands run back
        float delay = i / n * 0.45;
        float local = clamp((progress - delay) / 0.55, 0.0, 1.0);
        c = mix(a, b, smoothstep(0.0, e, local * (1.0 + e) - x));
    } else if (m == 5) {
        float p = progress;
        vec2 ua = (uv - 0.5) / (1.0 + 0.35 * p) + 0.5;           // the old one recedes
        vec2 ub = (uv - 0.5) / (1.0 + 0.18 * (1.0 - p)) + 0.5;   // the new one settles
        vec4 za = texture(from, ua);
        za.rgb *= 1.0 - 0.5 * p;
        c = mix(za, texture(to, ub), smoothstep(0.15, 0.85, p));
    } else if (m == 6) {
        float size = 0.055;
        vec4 h = hexCell(pa / size);
        vec2 centre = h.zw * size;
        vec2 o = vec2(origin.x * aspect, origin.y);
        float delay = length(centre - o) / farFrom(origin) * 0.75 + hash(h.zw) * 0.25;
        float local = clamp(progress * 2.0 - delay, 0.0, 1.0);
        float d = hexDist(h.xy) * 2.0;                            // 0 centre .. 1 edge
        c = mix(a, b, smoothstep(0.0, max(0.02, e * 0.6), local * 1.05 - d));
    } else {
        float blocks = mix(900.0, 18.0, sin(PI * progress));
        vec2 grid = vec2(blocks * aspect, blocks);
        vec2 q = (floor(uv * grid) + 0.5) / grid;
        c = mix(texture(from, q), texture(to, q), smoothstep(0.35, 0.65, progress));
    }
    fragColor = c * qt_Opacity;
}
