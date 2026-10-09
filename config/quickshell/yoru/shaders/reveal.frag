#version 440
// the wallpaper transition: the new picture spills out of a point as a
// widening ring, bending the light at its edge like a drop in water
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    vec2 origin;
};
layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 d = uv - origin;
    d.x *= aspect;
    float dist = length(d);
    float far = length(vec2(max(origin.x, 1.0 - origin.x) * aspect, max(origin.y, 1.0 - origin.y)));
    float edge = 0.16;
    float r = progress * (far + edge * 2.0);
    float t = smoothstep(r - edge, r, dist);            // 0 inside the ring: the new picture
    float ring = exp(-pow((dist - r + edge * 0.5) / 0.07, 2.0));
    float fade = 1.0 - progress;
    vec2 dir = dist > 0.0001 ? d / dist : vec2(0.0);
    dir.x /= aspect;
    vec2 bend = dir * ring * 0.03 * fade;
    vec4 a = texture(from, clamp(uv + bend, 0.0, 1.0));
    vec4 b = texture(to, clamp(uv - bend * 0.5, 0.0, 1.0));
    vec4 c = mix(b, a, t);
    c.rgb += ring * 0.07 * fade;
    fragColor = c * qt_Opacity;
}
