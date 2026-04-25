// CRT Shader Visual Effects
// Visual effects including ghosting, vignette, scan lines, aperture grille, flicker, and noise

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