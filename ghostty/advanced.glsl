// CRT Shader Advanced Effects
// Advanced effects including bloom, pixel response, subpixel rendering, electron beam, and interlacing

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