// CRT Shader Core Functions
// Core CRT functions including curvature and chromatic aberration

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