#pragma header

#define iResolution openfl_TextureSize
#define iChannel0 bitmap

// Parameters to control compression quality and strength
float uQuality = 0.75;   // Compression quality (higher is worse)
float uStrength = 0.5;  // Compression strength (higher means more artifacts)
float uRedTint = 0.0;   // Red tint intensity (higher makes screen redder)

vec3 compressBlock(vec2 fragCoord) {
    vec2 blockStart = floor(fragCoord / 8.0) * 8.0;
    
    // Sample 4x4 instead of 8x8 for performance
    vec3 samples[16];
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            vec2 sampleCoord = blockStart + vec2(float(i) * 2.0, float(j) * 2.0);
            samples[i * 4 + j] = flixel_texture2D(bitmap, sampleCoord / openfl_TextureSize).rgb;
        }
    }
    
    // Simple quantization approximation
    vec3 avg = vec3(0.0);
    for (int i = 0; i < 16; i++) {
        avg += samples[i];
    }
    avg /= 16.0;
    
    // Apply quantization based on quality
    vec3 quantized = floor(avg * 255.0 / (uQuality * 32.0)) * (uQuality * 32.0) / 255.0;
    
    return quantized;
}

vec3 simulateColorSpaceArtifacts(vec3 color) {
    // Convert to YUV-like space
    float y = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    float u = -0.147 * color.r - 0.289 * color.g + 0.436 * color.b;
    float v = 0.615 * color.r - 0.515 * color.g - 0.100 * color.b;
    
    // Quantize chroma channels more aggressively
    float quantStep = uQuality * 0.05;
    u = floor(u / quantStep) * quantStep;
    v = floor(v / quantStep) * quantStep;
    
    // Convert back to RGB
    float r = y + 1.140 * v;
    float g = y - 0.395 * u - 0.581 * v;
    float b = y + 2.032 * u;
    
    return vec3(r, g, b);
}

void main() {
    vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize;
    vec3 originalColor = flixel_texture2D(bitmap, openfl_TextureCoordv).rgb;
    
    // Apply block-based compression simulation
    vec3 compressedColor = compressBlock(fragCoord);
    
    // Apply color space artifacts
    compressedColor = simulateColorSpaceArtifacts(compressedColor);
    
    // Mix original and compressed based on strength
    vec3 finalColor = mix(originalColor, compressedColor, uStrength);
    
    // Apply red tint
    finalColor.r += uRedTint;
    
    // Clamp to valid range
    finalColor = clamp(finalColor, 0.0, 1.0);
    
    gl_FragColor = vec4(finalColor, 1.0);
}