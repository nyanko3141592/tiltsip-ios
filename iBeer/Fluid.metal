#include <metal_stdlib>
using namespace metal;

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), f.x), mix(hash21(i + float2(0, 1)), hash21(i + float2(1, 1)), f.x), f.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise2(p);
        p = p * 2.03 + 17.1;
        amplitude *= 0.5;
    }
    return value;
}

struct Particle { float x, y, vx, vy, size, kind, phase; };
struct Uniforms { float time, fill, carbonation, tilt, pouring; float4 color; };

kernel void updateParticles(device Particle *p [[buffer(0)]], constant Uniforms &u [[buffer(1)]], uint id [[thread_position_in_grid]]) {
    Particle q = p[id];
    float speed = 0.92 + u.carbonation * 0.72;
    q.vy += (0.19 + u.carbonation * 0.18) * 0.016;
    q.vx += sin(u.time * 1.7 + q.phase) * 0.0022 * speed;
    q.vx *= 0.992; q.vy *= 0.998;
    q.x += q.vx * 0.016; q.y += q.vy * 0.016;
    float surface = -0.72 + u.fill * 1.38;
    if (q.kind < 0.5) {
        if (q.y > surface + 0.03) { q.y = surface + 0.03; q.vy *= -0.12; }
        if (q.y < -0.72) { q.y = -0.72; q.vy = abs(q.vy) * 0.45; }
    } else {
        q.vy += 0.34 * 0.016;
        if (q.y > surface) { q.y = -0.70; q.x = sin(q.phase * 9.0 + u.time) * 0.24; q.vy = 0.08 + u.carbonation * 0.2; }
    }
    if (abs(q.x) > 0.96) { q.x = clamp(q.x, -0.96, 0.96); q.vx *= -0.5; }
    if (u.pouring > 0.5 && q.kind < 0.5 && id < 38) { q.y = surface + 0.02 + sin(u.time * 5.0 + q.phase) * 0.02; q.x = sin(u.time * 2.0 + q.phase) * 0.20; }
    p[id] = q;
}

struct VertexOut { float4 position [[position]]; float2 uv; float kind; };
vertex VertexOut particleVertex(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], device const Particle *p [[buffer(0)]], constant Uniforms &u [[buffer(1)]]) {
    const float2 corners[6] = { float2(-1,-1), float2(1,-1), float2(-1,1), float2(-1,1), float2(1,-1), float2(1,1) };
    Particle q = p[instanceID]; float2 c = corners[vertexID]; float2 pos = float2(q.x + c.x*q.size, q.y + c.y*q.size); float cs = cos(u.tilt), sn = sin(u.tilt); pos = float2(pos.x*cs-pos.y*sn, pos.x*sn+pos.y*cs); VertexOut o; o.position = float4(pos, 0, 1); o.uv = c * 0.5 + 0.5; o.kind = q.kind; return o;
}
fragment float4 particleFragment(VertexOut in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    float2 d = in.uv * 2.0 - 1.0; float a = smoothstep(1.0, 0.62, dot(d,d));
    if (in.kind > 0.5) { return float4(0.92, 0.98, 1.0, a * 0.62 * u.carbonation); }
    return float4(0.0);
}

struct SurfaceOut { float4 position [[position]]; float2 uv; };
vertex SurfaceOut surfaceVertex(uint vertexID [[vertex_id]]) {
    const float2 corners[6] = { float2(-1,-1), float2(1,-1), float2(-1,1), float2(-1,1), float2(1,-1), float2(1,1) };
    SurfaceOut o; float2 c = corners[vertexID]; o.position = float4(c, 0, 1); o.uv = c * 0.5 + 0.5; return o;
}

fragment float4 surfaceFragment(SurfaceOut in [[stage_in]], constant Uniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float wave = sin(uv.x * 13.0 + u.time * 0.72) * 0.010 + sin(uv.x * 29.0 - u.time * 0.41) * 0.004;
    float surface = 0.275 + wave;
    float liquidMask = 1.0 - smoothstep(surface - 0.008, surface + 0.008, uv.y);
    float foamTexture = fbm(uv * float2(18.0, 48.0) + float2(u.time * 0.08, -u.time * 0.05));
    float foamMask = (1.0 - smoothstep(0.0, 0.085, abs(uv.y - surface))) * (0.60 + foamTexture * 0.48);
    float liquidGrain = fbm(uv * float2(5.0, 19.0) + float2(0.0, u.time * 0.03));
    float3 beer = u.color.rgb * (0.92 + 0.18 * (1.0 - uv.y));
    beer += float3(0.16, 0.072, 0.008) * sin(uv.x * 5.0 + u.time * 0.25);
    beer *= 0.90 + liquidGrain * 0.16;
    float isBeer = step(0.30, u.color.r);
    float3 foam = mix(float3(0.19, 0.035, 0.022), float3(1.0, 0.72, 0.38), isBeer);
    float3 color = mix(beer, foam, foamMask * 0.96);
    float rim = 1.0 - smoothstep(0.0, 0.008, abs(uv.y - surface));
    color += float3(1.0, 0.74, 0.34) * rim * isBeer * 0.24;
    float inLiquid = step(uv.y, surface - 0.012);
    for (int i = 0; i < 14; i++) {
        float fi = float(i);
        float2 center = float2(hash21(float2(fi, 8.2)) * 0.96 + 0.02, 0.04 + hash21(float2(fi, 21.7)) * (surface - 0.08));
        center.x += sin(u.time * (0.25 + fi * 0.01) + fi) * 0.008;
        float radius = 0.0025 + hash21(float2(fi, 31.3)) * 0.006;
        float bubble = 1.0 - smoothstep(radius * 0.35, radius, distance(uv, center));
        color += float3(1.0, 0.86, 0.58) * bubble * inLiquid * 0.18;
    }
    return float4(color, max(liquidMask * 0.07, foamMask * 0.75));
}
