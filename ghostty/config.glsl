// CRT Shader Configuration
// All #define settings and constants for the CRT shader

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