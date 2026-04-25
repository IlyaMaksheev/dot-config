// CRT Shader Common Utilities
// Utility functions and coordinate transforms

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