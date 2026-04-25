// In-game CRT shader
// Author: sarphiv
// License: CC BY-NC-SA 4.0
// Description:
//   Shader for ghostty that is focussed on being usable while looking like a stylized CRT terminal in a modern video game.
//   I know a tiny bit about shaders, and nothing about GLSL,
//   so this is a Frakenstein's monster combination of other shaders together with a lot of surgery.
//   On the bright side, i've cleaned up the body parts and surgery a lot.

// Based on:
//   1. https://gist.github.com/mitchellh/39d62186910dcc27cad097fed16eb882 (forces the choice of license)
//   2. https://gist.github.com/qwerasd205/c3da6c610c8ffe17d6d2d3cc7068f17f
//   3. https://gist.github.com/seanwcom/0fbe6b270aaa5f28823e053d3dbb14ca

// Settings:
// How straight the terminal is in each axis
// (x, y) \in R^2 : x, y > 0
#define CURVE 7.0, 8.0

// How far apart the different colors are from each other
// x \in R
#define COLOR_FRINGING_SPREAD 1.0

// How much stronger the chromatic aberration is at the edges compared to center
// x \in R : x >= 1.0
#define COLOR_FRINGING_EDGE_INTENSITY 3.0

// How much the ghost images are spread out
// x \in R : x >= 0
#define GHOSTING_SPREAD 0.75
// How visible ghost images are
// x \in R : x >= 0
#define GHOSTING_STRENGTH 1.0

// How much of the non-linearly darkened colors are mixed in
// [0, 1]
#define DARKEN_MIX 0.4

// How far in the vignette spreads
// x \in R : x >= 0
#define VIGNETTE_SPREAD 0.3
// How bright the vignette is
// x \in R : x >= 0
#define VIGNETTE_BRIGHTNESS 6.4

// Tint all colors
// [0, 1]^3
#define TINT 0.93, 1.00, 0.96

// How visible the scan line effect is
// NOTE: Technically these are not scan lines, but rather the lack of them
// [0, 1]
#define SCAN_LINES_STRENGTH 0.15
// How bright the spaces between the lines are
// [0, 1]
#define SCAN_LINES_VARIANCE 0.35
// Pixels per scan line effect
// x \in R : x > 0
#define SCAN_LINES_PERIOD 4.0

// How visible the aperture grille is
// x \in R : x >= 0
#define APERTURE_GRILLE_STRENGTH 0.2
// Pixels per aperture grille
// x \in R : x > 0
#define APERTURE_GRILLE_PERIOD 5.0

// How much the screen flickers
// x \in R : x >= 0
#define FLICKER_STRENGTH 0.05
// How fast the screen flickers
// x \in R : x > 0
#define FLICKER_FREQUENCY 7.5

// How much noise is added to filled areas
// [0, 1]
#define NOISE_CONTENT_STRENGTH 0.5
// How much noise is added everywhere
// [0, 1]
#define NOISE_UNIFORM_STRENGTH 0.003

// How big the bloom is
// x \in R : x >= 0
#define BLOOM_SPREAD 5000.0
// How visible the bloom is
// [0, 1]
#define BLOOM_STRENGTH 0.5

// How fast colors fade in and out
// [0, 1]
#define FADE_FACTOR 0.75

// Maximum time value to prevent long-term accumulation effects
// x \in R : x > 0
#define MAX_TIME_CYCLE 60.0

// --- New CRT Simulation Settings ---

// Pixel response time simulation (ms)
// Higher values create more motion blur similar to real CRTs
// x \in R : x >= 0
#define PIXEL_RESPONSE_TIME 2.0

// Subpixel layout simulation
// 0 = RGB, 1 = BGR, 2 = RGBW, 3 = RBGW
#define SUBPIXEL_LAYOUT 0

// Subpixel intensity - controls how pronounced the subpixel effect is
// [0, 1]
#define SUBPIXEL_INTENSITY 0.4

// Electron beam width - controls the width of the electron beam
// Smaller values create sharper pixels, larger values create softer pixels
// x \in R : x > 0
#define BEAM_WIDTH 1.5

// Electron beam intensity - controls the brightness of the beam center
// Higher values create brighter centers with more pronounced falloff
// x \in R : x > 0
#define BEAM_INTENSITY 0.005

// Phosphor persistence - controls how long phosphors glow
// Higher values create more motion trails
// x \in R : x >= 0
#define PHOSPHOR_PERSISTENCE 0.3

// Interlacing simulation - simulates interlaced CRT displays
// 0 = off, 1 = on
#define INTERLACING 0

// Interlacing phase - controls which field is currently being drawn
// 0 = even field, 1 = odd field
#define INTERLACING_PHASE 0

// Constants
#define PI 3.1415926535897932384626433832795



// Fallback definitions for when settings are not defined
#ifndef COLOR_FRINGING_SPREAD
#define COLOR_FRINGING_SPREAD 0.0
#endif

#ifndef COLOR_FRINGING_EDGE_INTENSITY
#define COLOR_FRINGING_EDGE_INTENSITY 1.0
#endif

#if !defined(GHOSTING_SPREAD) || !defined(GHOSTING_STRENGTH)
#undef GHOSTING_SPREAD
#undef GHOSTING_STRENGTH
#define GHOSTING_SPREAD 0.0
#define GHOSTING_STRENGTH 0.0
#endif

#ifndef DARKEN_MIX
#define DARKEN_MIX 0.0
#endif

#if !defined(VIGNETTE_SPREAD) || !defined(VIGNETTE_BRIGHTNESS)
#undef VIGNETTE_SPREAD
#undef VIGNETTE_BRIGHTNESS
#define VIGNETTE_SPREAD 0.0
#define VIGNETTE_BRIGHTNESS 1.0
#endif

#ifndef TINT
#define TINT 1.00, 1.00, 1.00
#endif

#if !defined(SCAN_LINES_STRENGTH) || !defined(SCAN_LINES_VARIANCE) || !defined(SCAN_LINES_PERIOD)
#undef SCAN_LINES_STRENGTH
#undef SCAN_LINES_VARIANCE
#undef SCAN_LINES_PERIOD
#define SCAN_LINES_STRENGTH 0.0
#define SCAN_LINES_VARIANCE 1.0
#define SCAN_LINES_PERIOD 1.0
#endif

#if !defined(APERTURE_GRILLE_STRENGTH) || !defined(APERTURE_GRILLE_PERIOD)
#undef APERTURE_GRILLE_STRENGTH
#undef APERTURE_GRILLE_PERIOD
#define APERTURE_GRILLE_STRENGTH 0.0
#define APERTURE_GRILLE_PERIOD 1.0
#endif

#if !defined(FLICKER_STRENGTH) || !defined(FLICKER_FREQUENCY)
#undef FLICKER_STRENGTH
#undef FLICKER_FREQUENCY
#define FLICKER_STRENGTH 0.0
#define FLICKER_FREQUENCY 1.0
#endif

#if !defined(NOISE_CONTENT_STRENGTH) || !defined(NOISE_UNIFORM_STRENGTH)
#undef NOISE_CONTENT_STRENGTH
#undef NOISE_UNIFORM_STRENGTH
#define NOISE_CONTENT_STRENGTH 0.0
#define NOISE_UNIFORM_STRENGTH 0.0
#endif

#if !defined(BLOOM_SPREAD) || !defined(BLOOM_STRENGTH)
#undef BLOOM_SPREAD
#undef BLOOM_STRENGTH
#define BLOOM_SPREAD 0.0
#define BLOOM_STRENGTH 0.0
#endif

#ifndef FADE_FACTOR
#define FADE_FACTOR 1.00
#endif

#ifndef MAX_TIME_CYCLE
#define MAX_TIME_CYCLE 60.0
#endif

#ifdef BLOOM_SPREAD
// Gaussian kernel weights for bloom effect
// These weights approximate a Gaussian distribution for a more natural bloom
const float gaussian_weights[9] = float[9](
        0.0625, 0.125, 0.0625, // 1/16, 2/16, 1/16
        0.125, 0.25, 0.125, // 2/16, 4/16, 2/16
        0.0625, 0.125, 0.0625 // 1/16, 2/16, 1/16
    );
#endif

// Calculate vector from center and normalized distance
vec2 getFromCenter(vec2 uv) {
    return (uv - 0.5) * 2.0; // Vector from center (-1 to 1 range)
}

float getNormalizedDistance(vec2 fromCenter) {
    return dot(fromCenter, fromCenter) * 0.35355; // Optimized: length(fromCenter) / 1.414 ≈ sqrt(dot) * 0.35355
}

// Cursor shader utility functions
float ease(float x) {
    return pow(1.0 - x, 10.0);
}

float sdBox(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}





// Apply screen curvature to UV coordinates
vec2 applyCurvature(vec2 uv) {
    #ifdef CURVE
    // Curve texture coordinates to mimic non-flat CRT monitor
    vec2 fromCenter = getFromCenter(uv);
    fromCenter.xy *= 1.0 + pow((abs(vec2(fromCenter.y, fromCenter.x)) / vec2(CURVE)), vec2(2.0));
    return (fromCenter / 2.0) + 0.5;
    #else
    return uv;
    #endif
}

// Calculate edge factor based on distance from center
float calculateEdgeFactor(vec2 uv) {
    vec2 fromCenter = getFromCenter(uv);
    float normalizedDist = getNormalizedDistance(fromCenter);

    #ifdef CURVE
    // Use the same curvature formula as the screen distortion to calculate aberration strength
    vec2 curvePower = vec2(CURVE);
    float avgCurvePower = (curvePower.x + curvePower.y) * 0.5;

    // Calculate how much the pixel would be displaced by the curve effect
    float curveDisplacement = pow(normalizedDist, 2.0) / avgCurvePower;

    // Use the curve displacement to drive the aberration strength
    return smoothstep(0.0, 0.5, curveDisplacement);
    #else
    // Fallback if CURVE is not defined
    return smoothstep(0.0, 1.0, normalizedDist);
    #endif
}

// Apply chromatic aberration effect
vec4 applyChromatic(vec2 uv, float edgeFactor, vec4 baseTexture, vec2 aberrationDir) {
    vec4 color;

    // Calculate the chromatic aberration offset based on curvature
    float baseOffset = 0.001 * COLOR_FRINGING_SPREAD;
    float edgeOffset = baseOffset * mix(1.0, COLOR_FRINGING_EDGE_INTENSITY, edgeFactor);

    // Sample the colors with offsets in the direction from center
    color.r = texture(iChannel0, uv + aberrationDir * edgeOffset * 0.8).r;
    color.g = baseTexture.g;
    color.b = texture(iChannel0, uv - aberrationDir * edgeOffset).b;
    color.a = baseTexture.a;

    return color;
}

// Apply ghosting effect to simulate phosphor persistence
vec4 applyGhosting(vec4 color, vec2 uv, float edgeFactor, vec4 baseTexture, vec2 aberrationDir) {
    // Temporal component for more dynamic ghosting
    float temporalFactor = fract(iTime * 0.5);

    // Enhanced edge-dependent ghosting with temporal variation
    float ghostEdgeIntensity = mix(
            1.0,
            edgeFactor * edgeFactor * (2.0 + temporalFactor), // Replace pow with multiplication
            edgeFactor
        );

    // Use precomputed aberration direction for ghosting
    vec2 ghostDir = aberrationDir;

    // Multiple ghost samples with enhanced displacement and decay
    vec3 ghostSum = vec3(0.0);
    float decayFactor = 1.0 - temporalFactor;

    // Precompute common values
    float baseOffsetScale = 0.005 * GHOSTING_SPREAD * ghostEdgeIntensity * (1.0 + temporalFactor);
    float baseIntensity = 0.01 * decayFactor * GHOSTING_STRENGTH;

    // Ghost sampling with more pronounced displacement and temporal decay
    // Unroll loop for better performance
    // i = 1
    vec2 offset1 = ghostDir * baseOffsetScale * 1.0;
    vec3 ghostSample1 = vec3(
            texture(iChannel0, uv + offset1 * 1.2).r,
            texture(iChannel0, uv + offset1 * 0.9).g,
            texture(iChannel0, uv + offset1 * 0.6).b
        );
    ghostSum += ghostSample1 * (3.0 * baseIntensity);

    // i = 2
    vec2 offset2 = ghostDir * baseOffsetScale * 2.0;
    vec3 ghostSample2 = vec3(
            texture(iChannel0, uv + offset2 * 1.2).r,
            texture(iChannel0, uv + offset2 * 0.9).g,
            texture(iChannel0, uv + offset2 * 0.6).b
        );
    ghostSum += ghostSample2 * (2.0 * baseIntensity);

    // i = 3
    vec2 offset3 = ghostDir * baseOffsetScale * 3.0;
    vec3 ghostSample3 = vec3(
            texture(iChannel0, uv + offset3 * 1.2).r,
            texture(iChannel0, uv + offset3 * 0.9).g,
            texture(iChannel0, uv + offset3 * 0.6).b
        );
    ghostSum += ghostSample3 * (1.0 * baseIntensity);

    // Blend ghost with original color, emphasizing edge regions
    color.rgb = mix(
            color.rgb,
            color.rgb + ghostSum,
            smoothstep(0.2, 0.8, edgeFactor)
        );

    return color;
}

// Apply vignette effect
vec3 applyVignette(vec3 color, vec2 uv) {
    // Vignette effect - optimized calculation
    float vignette_raw = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    float vignette = VIGNETTE_BRIGHTNESS * pow(vignette_raw, VIGNETTE_SPREAD);

    // Calculate distance from center (0.5, 0.5) - optimized
    vec2 center_dist = abs(uv - 0.5);
    float dist_factor = max(center_dist.x, center_dist.y);

    // Apply stronger clamping near the center to prevent accumulation
    float center_region = smoothstep(0.0, 0.25, dist_factor);
    vignette = mix(1.0, min(vignette, 1.0), center_region);

    return color * vignette;
}

// Apply scan lines effect
vec3 applyScanLines(vec3 color, vec2 uv) {
    // Precompute constants
    const float TWO_PI = 6.28318530718;
    float scanline_freq = TWO_PI * iResolution.y / SCAN_LINES_PERIOD;
    float scanline_effect = SCAN_LINES_VARIANCE * 0.5 * (1.0 + sin(uv.y * scanline_freq));

    return color * mix(1.0, scanline_effect, SCAN_LINES_STRENGTH);
}

// Apply aperture grille effect
vec3 applyApertureGrille(vec3 color, vec2 uv) {
    // Use the curved UV coordinates to calculate the aperture grille
    float curved_x = uv.x * iResolution.x;
    float mod_val = mod(curved_x, APERTURE_GRILLE_PERIOD);
    int aperture_grille_step = int(8.0 * mod_val / APERTURE_GRILLE_PERIOD);
    float aperture_grille_mask;

    // Optimize branching using arithmetic operations
    if (aperture_grille_step < 3) {
        aperture_grille_mask = 0.0;
    } else if (aperture_grille_step < 4) {
        aperture_grille_mask = mod(8.0 * curved_x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;
    } else if (aperture_grille_step < 7) {
        aperture_grille_mask = 1.0;
    } else {
        aperture_grille_mask = mod(-8.0 * curved_x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;
    }

    return color * (1.0 - APERTURE_GRILLE_STRENGTH * aperture_grille_mask);
}

// Apply flicker effect
vec4 applyFlicker(vec4 color, float cyclicTime) {
    // Precompute constants
    const float TWO_PI = 6.28318530718;
    float flicker_factor = 1.0 - FLICKER_STRENGTH * 0.5 * (1.0 + sin(FLICKER_FREQUENCY * cyclicTime * TWO_PI));

    return color * flicker_factor;
}

// Apply noise effect
vec3 applyNoise(vec3 color, vec2 uv, float cyclicTime) {
    // Use different seed values for each noise type to prevent correlation
    float noiseSeed1 = cyclicTime * 4096.0 + uv.x * 123.4 + uv.y * 567.8;
    float noiseSeed2 = cyclicTime * 8192.0 + uv.x * 876.5 + uv.y * 432.1;

    // Use hash function for better noise distribution - optimized
    float hash1 = fract(sin(noiseSeed1) * 43758.5453);
    float hash2 = fract(sin(noiseSeed2) * 43758.5453);

    // Apply noise with spatial variation to prevent center accumulation
    vec2 centerDist = uv - 0.5;
    float spatialFactor = smoothstep(0.0, 0.5, dot(centerDist, centerDist)); // Use dot product instead of length
    float noiseContent = smoothstep(0.4, 0.6, hash1);
    float noiseUniform = smoothstep(0.4, 0.6, hash2);

    // Scale noise effect by distance from center
    float noiseContentScaled = mix(0.5, noiseContent, spatialFactor);
    float noiseUniformScaled = mix(0.5, noiseUniform, spatialFactor);

    color *= clamp(noiseContentScaled + 1.0 - NOISE_CONTENT_STRENGTH, 0.0, 1.0);
    color = clamp(color + noiseUniformScaled * NOISE_UNIFORM_STRENGTH, 0.0, 1.0);

    return color;
}

// Apply bloom effect with enhanced error handling and simplified sampling
vec4 applyBloom(vec4 color, vec2 uv, float edgeFactor, vec4 baseTexture, vec2 texelSize) {
    #ifdef BLOOM_SPREAD
    // Calculate bloom intensity based on edge factor and distance from center
    float bloomIntensity = BLOOM_STRENGTH * edgeFactor * sqrt(edgeFactor); // Replace pow(edgeFactor, 1.5) with multiplication

    // Prevent bloom on very dark areas
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    if (luminance < 0.1) return color;

    vec3 bloomSum = vec3(0.0);
    float bloomWeightSum = 0.0;

    // Precompute bloom spread factor
    float spreadFactor = texelSize.x * BLOOM_SPREAD;

    // Unroll 3x3 Gaussian kernel for better performance
    // Center (0,0)
    vec3 sampleColor00 = baseTexture.rgb;
    float weight00 = gaussian_weights[4]; // (0+1)*3 + (0+1) = 4
    float sampleLuminance00 = dot(sampleColor00, vec3(0.299, 0.587, 0.114));
    weight00 *= sampleLuminance00 * sampleLuminance00 * bloomIntensity;
    bloomSum += sampleColor00 * weight00;
    bloomWeightSum += weight00;

    // Right (1,0)
    vec2 offset10 = vec2(spreadFactor, 0.0);
    vec2 sampleUV10 = uv + offset10;
    if (sampleUV10.x <= 1.0) {
        vec3 sampleColor10 = texture(iChannel0, sampleUV10).rgb;
        float weight10 = gaussian_weights[5];
        float sampleLuminance10 = dot(sampleColor10, vec3(0.299, 0.587, 0.114));
        weight10 *= sampleLuminance10 * sampleLuminance10 * bloomIntensity;
        bloomSum += sampleColor10 * weight10;
        bloomWeightSum += weight10;
    }

    // Left (-1,0)
    vec2 offset_10 = vec2(-spreadFactor, 0.0);
    vec2 sampleUV_10 = uv + offset_10;
    if (sampleUV_10.x >= 0.0) {
        vec3 sampleColor_10 = texture(iChannel0, sampleUV_10).rgb;
        float weight_10 = gaussian_weights[3];
        float sampleLuminance_10 = dot(sampleColor_10, vec3(0.299, 0.587, 0.114));
        weight_10 *= sampleLuminance_10 * sampleLuminance_10 * bloomIntensity;
        bloomSum += sampleColor_10 * weight_10;
        bloomWeightSum += weight_10;
    }

    // Up (0,1)
    vec2 offset01 = vec2(0.0, spreadFactor);
    vec2 sampleUV01 = uv + offset01;
    if (sampleUV01.y <= 1.0) {
        vec3 sampleColor01 = texture(iChannel0, sampleUV01).rgb;
        float weight01 = gaussian_weights[7];
        float sampleLuminance01 = dot(sampleColor01, vec3(0.299, 0.587, 0.114));
        weight01 *= sampleLuminance01 * sampleLuminance01 * bloomIntensity;
        bloomSum += sampleColor01 * weight01;
        bloomWeightSum += weight01;
    }

    // Down (0,-1)
    vec2 offset0_1 = vec2(0.0, -spreadFactor);
    vec2 sampleUV0_1 = uv + offset0_1;
    if (sampleUV0_1.y >= 0.0) {
        vec3 sampleColor0_1 = texture(iChannel0, sampleUV0_1).rgb;
        float weight0_1 = gaussian_weights[1];
        float sampleLuminance0_1 = dot(sampleColor0_1, vec3(0.299, 0.587, 0.114));
        weight0_1 *= sampleLuminance0_1 * sampleLuminance0_1 * bloomIntensity;
        bloomSum += sampleColor0_1 * weight0_1;
        bloomWeightSum += weight0_1;
    }

    // Diagonals - only sample if both coordinates are in bounds
    vec2 offset11 = vec2(spreadFactor, spreadFactor);
    vec2 sampleUV11 = uv + offset11;
    if (sampleUV11.x <= 1.0 && sampleUV11.y <= 1.0) {
        vec3 sampleColor11 = texture(iChannel0, sampleUV11).rgb;
        float weight11 = gaussian_weights[8];
        float sampleLuminance11 = dot(sampleColor11, vec3(0.299, 0.587, 0.114));
        weight11 *= sampleLuminance11 * sampleLuminance11 * bloomIntensity;
        bloomSum += sampleColor11 * weight11;
        bloomWeightSum += weight11;
    }

    vec2 offset_1_1 = vec2(-spreadFactor, -spreadFactor);
    vec2 sampleUV_1_1 = uv + offset_1_1;
    if (sampleUV_1_1.x >= 0.0 && sampleUV_1_1.y >= 0.0) {
        vec3 sampleColor_1_1 = texture(iChannel0, sampleUV_1_1).rgb;
        float weight_1_1 = gaussian_weights[0];
        float sampleLuminance_1_1 = dot(sampleColor_1_1, vec3(0.299, 0.587, 0.114));
        weight_1_1 *= sampleLuminance_1_1 * sampleLuminance_1_1 * bloomIntensity;
        bloomSum += sampleColor_1_1 * weight_1_1;
        bloomWeightSum += weight_1_1;
    }

    vec2 offset1_1 = vec2(spreadFactor, -spreadFactor);
    vec2 sampleUV1_1 = uv + offset1_1;
    if (sampleUV1_1.x <= 1.0 && sampleUV1_1.y >= 0.0) {
        vec3 sampleColor1_1 = texture(iChannel0, sampleUV1_1).rgb;
        float weight1_1 = gaussian_weights[2];
        float sampleLuminance1_1 = dot(sampleColor1_1, vec3(0.299, 0.587, 0.114));
        weight1_1 *= sampleLuminance1_1 * sampleLuminance1_1 * bloomIntensity;
        bloomSum += sampleColor1_1 * weight1_1;
        bloomWeightSum += weight1_1;
    }

    vec2 offset_11 = vec2(-spreadFactor, spreadFactor);
    vec2 sampleUV_11 = uv + offset_11;
    if (sampleUV_11.x >= 0.0 && sampleUV_11.y <= 1.0) {
        vec3 sampleColor_11 = texture(iChannel0, sampleUV_11).rgb;
        float weight_11 = gaussian_weights[6];
        float sampleLuminance_11 = dot(sampleColor_11, vec3(0.299, 0.587, 0.114));
        weight_11 *= sampleLuminance_11 * sampleLuminance_11 * bloomIntensity;
        bloomSum += sampleColor_11 * weight_11;
        bloomWeightSum += weight_11;
    }

    // Normalize bloom
    if (bloomWeightSum > 0.0) {
        vec3 bloomColor = bloomSum / bloomWeightSum;

        // Blend bloom with original color
        color.rgb = mix(color.rgb, bloomColor, bloomIntensity);
    }
    #endif

    return color;
}

// Apply fade effect
vec4 applyFade(vec4 color, vec2 uv, vec4 baseTexture) {
    // Use cached base texture sample
    vec4 original = baseTexture;

    // Calculate luminance of both the original and processed colors
    float orig_lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
    float proc_lum = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // Adjust fade factor based on luminance difference to prevent accumulation
    float adaptive_fade = FADE_FACTOR;
    if (proc_lum > orig_lum * 1.2) {
        // If processed image is significantly brighter, reduce fade factor
        adaptive_fade = FADE_FACTOR * 0.8;
    }

    color.rgb = mix(original.rgb, color.rgb, adaptive_fade);
    color.a = adaptive_fade;

    return color;
}

// Simulate pixel response time for more realistic motion
vec4 applyPixelResponse(vec2 uv, float cyclicTime, vec4 baseTexture, vec2 texelSize) {
    // Use cached base texture sample
    vec4 currentFrame = baseTexture;

    // For pixel response simulation, we need to sample the previous frame
    // Since we don't have direct access to previous frames in this shader,
    // we'll simulate it by sampling slightly offset positions based on motion vectors

    // Estimate motion vector based on time derivative (simple approximation)
    // This creates a subtle trail in the direction of motion
    float motionScale = PIXEL_RESPONSE_TIME * 0.01;

    // Sample neighboring pixels for motion estimation
    vec4 rightSample = texture(iChannel0, uv + vec2(texelSize.x, 0.0));
    vec4 leftSample = texture(iChannel0, uv - vec2(texelSize.x, 0.0));
    vec4 upSample = texture(iChannel0, uv + vec2(0.0, texelSize.y));
    vec4 downSample = texture(iChannel0, uv - vec2(0.0, texelSize.y));

    vec2 motionVector = vec2(
            (rightSample.r - leftSample.r),
            (upSample.r - downSample.r)
        ) * motionScale;

    // Sample previous frame position (approximated)
    vec4 prevFrame = texture(iChannel0, uv - motionVector);

    // Blend current and previous frame based on response time
    // Higher response time means more persistence (more of the previous frame is visible)
    float persistence = clamp(PIXEL_RESPONSE_TIME * 0.05, 0.0, 0.95);

    // Apply different persistence values to different color channels
    // This simulates how different phosphors have different decay rates
    vec4 responseColor;
    responseColor.r = mix(currentFrame.r, prevFrame.r, persistence * 0.8); // Red phosphors decay faster
    responseColor.g = mix(currentFrame.g, prevFrame.g, persistence * 1.0); // Green phosphors decay medium
    responseColor.b = mix(currentFrame.b, prevFrame.b, persistence * 1.2); // Blue phosphors decay slower
    responseColor.a = currentFrame.a;

    return responseColor;
}

// Simulate subpixel rendering for more authentic CRT look
vec3 applySubpixelRendering(vec2 uv, vec4 baseTexture, vec2 texelSize) {
    // Get the pixel position in screen space
    vec2 pixelPos = uv * iResolution.xy;

    // Calculate subpixel position (within the current pixel)
    float subpixelPos = mod(pixelPos.x, 1.0);

    // Use cached base texture sample
    vec3 baseColor = baseTexture.rgb;

    // Sample neighboring pixels for subpixel interpolation
    vec3 leftColor = texture(iChannel0, uv - vec2(texelSize.x, 0.0)).rgb;
    vec3 rightColor = texture(iChannel0, uv + vec2(texelSize.x, 0.0)).rgb;

    // Initialize subpixel colors
    vec3 subpixelColor = baseColor;

    // Apply subpixel layout based on settings - optimize branching
    #if SUBPIXEL_LAYOUT == 0  // RGB layout
    float subpixelIndex = floor(subpixelPos * 3.0);
    float subpixelFract = fract(subpixelPos * 3.0);

    if (subpixelIndex < 0.5) {
        // Red subpixel
        subpixelColor.r = mix(leftColor.r, baseColor.r, subpixelFract);
        subpixelColor.g = baseColor.g;
        subpixelColor.b = baseColor.b;
    } else if (subpixelIndex < 1.5) {
        // Green subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = mix(baseColor.g, rightColor.g, subpixelFract);
        subpixelColor.b = baseColor.b;
    } else {
        // Blue subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = baseColor.g;
        subpixelColor.b = mix(baseColor.b, rightColor.b, subpixelFract);
    }
    #elif SUBPIXEL_LAYOUT == 1  // BGR layout
    float subpixelIndex = floor(subpixelPos * 3.0);
    float subpixelFract = fract(subpixelPos * 3.0);

    if (subpixelIndex < 0.5) {
        // Blue subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = baseColor.g;
        subpixelColor.b = mix(leftColor.b, baseColor.b, subpixelFract);
    } else if (subpixelIndex < 1.5) {
        // Green subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = mix(baseColor.g, rightColor.g, subpixelFract);
        subpixelColor.b = baseColor.b;
    } else {
        // Red subpixel
        subpixelColor.r = mix(baseColor.r, rightColor.r, subpixelFract);
        subpixelColor.g = baseColor.g;
        subpixelColor.b = baseColor.b;
    }
    #elif SUBPIXEL_LAYOUT == 2  // RGBW layout
    float subpixelIndex = floor(subpixelPos * 4.0);
    float subpixelFract = fract(subpixelPos * 4.0);

    if (subpixelIndex < 0.5) {
        // Red subpixel
        subpixelColor.r = mix(leftColor.r, baseColor.r, subpixelFract);
        subpixelColor.g = baseColor.g;
        subpixelColor.b = baseColor.b;
    } else if (subpixelIndex < 1.5) {
        // Green subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = mix(baseColor.g, rightColor.g, subpixelFract);
        subpixelColor.b = baseColor.b;
    } else if (subpixelIndex < 2.5) {
        // Blue subpixel
        subpixelColor.r = baseColor.r;
        subpixelColor.g = baseColor.g;
        subpixelColor.b = mix(baseColor.b, rightColor.b, subpixelFract);
    } else {
        // White subpixel (all channels)
        subpixelColor = mix(baseColor, rightColor, subpixelFract);
    }
    #endif

    // Mix the subpixel color with the base color based on intensity
    return mix(baseColor, subpixelColor, SUBPIXEL_INTENSITY);
}

// Simulate electron beam for more authentic CRT look
vec3 applyElectronBeam(vec2 uv, vec3 color) {
    // Get the pixel position in screen space
    vec2 pixelPos = uv * iResolution.xy;

    // Calculate the fractional position within the pixel
    vec2 pixelFract = fract(pixelPos);

    // Calculate distance from pixel center - optimized
    vec2 distVec = pixelFract - 0.5;
    float distFromCenter = dot(distVec, distVec); // Use dot product instead of length

    // Apply beam width and intensity
    float beamFalloff = 1.0 - smoothstep(0.0, BEAM_WIDTH * 0.5, sqrt(distFromCenter));
    beamFalloff = pow(beamFalloff, BEAM_INTENSITY);

    // Apply beam intensity to color
    vec3 beamColor = color * (0.8 + 0.2 * beamFalloff);

    // Add a slight bloom to bright areas to simulate beam spread
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    beamColor += color * luminance * beamFalloff * 0.2;

    return beamColor;
}

// Simulate interlacing for more authentic CRT look
vec3 applyInterlacing(vec2 uv, vec3 color) {
    #if INTERLACING == 1
    // Get the pixel position in screen space
    int scanline = int(uv.y * iResolution.y);

    // Check if current scanline is in the current field
    bool inCurrentField = (scanline % 2 == INTERLACING_PHASE);

    if (!inCurrentField) {
        // If not in current field, show the previous field's content
        // This creates the interlacing effect
        float decay = 0.7; // How much the previous field has decayed
        return color * decay;
    }
    #endif

    return color;
}



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
