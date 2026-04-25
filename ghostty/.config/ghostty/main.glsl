// In-game CRT shader - Modular Version
// Author: sarphiv
// License: CC BY-NC-SA 4.0
// Description:
//   Shader for ghostty that is focussed on being usable while looking like a stylized CRT terminal in a modern video game.
//   This is a modular version of the original shader, split into separate files for better organization and maintainability.

// Based on:
//   1. https://gist.github.com/mitchellh/39d62186910dcc27cad097fed16eb882 (forces the choice of license)
//   2. https://gist.github.com/qwerasd205/c3da6c610c8ffe17d6d2d3cc7068f17f
//   3. https://gist.github.com/seanwcom/0fbe6b270aaa5f28823e053d3dbb14ca

// Include all shader modules
#include "config.glsl"
#include "common.glsl"
#include "crt-core.glsl"
#include "effects.glsl"
#include "advanced.glsl"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Get texture coordinates
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Modulate iTime to prevent long-term accumulation effects
    float cyclicTime = mod(iTime, MAX_TIME_CYCLE);

    // Apply screen curvature FIRST - this ensures all effects work in curved coordinate space
    uv = applyCurvature(uv);

    // Cache base texture sample AFTER curvature is applied
    vec4 baseTexture = texture(iChannel0, uv);

    // Precompute frequently used values using the CURVED coordinates
    vec2 fromCenter = getFromCenter(uv);
    float edgeFactor = calculateEdgeFactor(uv);
    vec2 aberrationDir = normalize(fromCenter + vec2(0.0001));
    vec2 texelSize = 1.0 / iResolution.xy;

    // Apply pixel response time simulation with optimized sampling
    vec4 responseColor = applyPixelResponse(uv, cyclicTime, baseTexture, texelSize);

    // Apply subpixel rendering with optimized sampling
    vec3 subpixelColor = applySubpixelRendering(uv, baseTexture, texelSize);

    // Blend response color with subpixel color
    vec4 baseColor = vec4(mix(responseColor.rgb, subpixelColor, 0.7), responseColor.a);

    // Apply chromatic aberration with optimized sampling
    fragColor = applyChromatic(uv, edgeFactor, baseTexture, aberrationDir);

    // Blend with base color
    fragColor.rgb = mix(baseColor.rgb, fragColor.rgb, 0.7);

    // Apply electron beam simulation
    fragColor.rgb = applyElectronBeam(uv, fragColor.rgb);

    // Apply ghosting effect with optimized sampling
    fragColor = applyGhosting(fragColor, uv, edgeFactor, baseTexture, aberrationDir);

    // Quadratically darken everything
    fragColor.rgb = mix(fragColor.rgb, fragColor.rgb * fragColor.rgb, DARKEN_MIX);

    // Apply vignette effect
    fragColor.rgb = applyVignette(fragColor.rgb, uv);

    // Tint all colors
    fragColor.rgb *= vec3(TINT);

    // Apply scan lines effect
    fragColor.rgb = applyScanLines(fragColor.rgb, uv);

    // Apply aperture grille effect
    fragColor.rgb = applyApertureGrille(fragColor.rgb, uv);

    // Apply interlacing
    fragColor.rgb = applyInterlacing(uv, fragColor.rgb);

    // Apply flicker effect
    fragColor = applyFlicker(fragColor, cyclicTime);

    // Apply bloom effect with optimized sampling
    fragColor = applyBloom(fragColor, uv, edgeFactor, baseTexture, texelSize);

    // Apply noise effect
    fragColor.rgb = applyNoise(fragColor.rgb, uv, cyclicTime);

    // Remove output outside of screen bounds
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor.rgb *= 0.0;
    }

    // Apply fade effect with cached texture
    fragColor = applyFade(fragColor, uv, baseTexture);
}
