#version 330 core

uniform sampler2D colorTexture;
uniform sampler2D glowTexture;

uniform vec2 resolution = vec2(800, 600);

in vec2 uv;

layout (location = 0) out vec4 gColor;
layout (location = 1) out vec3 gGlow;

#define FXAA_REDUCE_MIN   (1.0/ 128.0)
#define FXAA_REDUCE_MUL   (1.0 / 8.0)
#define FXAA_SPAN_MAX 8.0

vec4 fxaa(sampler2D tex, vec2 uv, vec2 resolution,
            vec2 v_rgbNW, vec2 v_rgbNE,
            vec2 v_rgbSW, vec2 v_rgbSE,
            vec2 v_rgbM) {
    vec4 color;
    vec2 inverseVP = 1.0 / resolution;
    vec3 rgbNW = texture2D(tex, v_rgbNW).xyz;
    vec3 rgbNE = texture2D(tex, v_rgbNE).xyz;
    vec3 rgbSW = texture2D(tex, v_rgbSW).xyz;
    vec3 rgbSE = texture2D(tex, v_rgbSE).xyz;
    vec4 texColor = texture2D(tex, v_rgbM);
    vec3 rgbM  = texColor.xyz;
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
              dir * rcpDirMin)) * inverseVP;

    vec3 rgbA = 0.5 * (
        texture2D(tex, uv + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture2D(tex, uv + dir * (2.0 / 3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture2D(tex, uv + dir * -0.5).xyz +
        texture2D(tex, uv + dir * 0.5).xyz);

    float lumaB = dot(rgbB, luma);
    if ((lumaB < lumaMin) || (lumaB > lumaMax))
        color = vec4(rgbA, texColor.a);
    else
        color = vec4(rgbB, texColor.a);
    return color;
}

vec4 FXAA(sampler2D tex, vec2 uv) {
    vec2 rgbNW=uv+(vec2(-1, -1)/resolution);
    vec2 rgbNE=uv+(vec2( 1, -1)/resolution);
    vec2 rgbSW=uv+(vec2(-1,  1)/resolution);
    vec2 rgbSE=uv+(vec2( 1,  1)/resolution);
    vec2 rgbM=uv;
    return fxaa(tex, uv, resolution, rgbNW, rgbNE, rgbSW, rgbSE, rgbM);
}

void main() {
    gColor = FXAA(colorTexture, uv);
    gGlow = FXAA(glowTexture, uv).rgb;
}
