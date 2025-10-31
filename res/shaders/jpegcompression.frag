#pragma header

uniform float iWashoutIntensity;
uniform float iBlurAmount;
uniform float iBlockiness;
uniform float iColorSteps;
uniform float iGrainAmount;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    
    // Compress/pixelate
    vec2 block_uv = floor(uv * iBlockiness) / iBlockiness;
    
    // Blur with checkerboard sampling
    vec2 texel_size = vec2(1.0) / openfl_TextureSize;
    vec4 color = vec4(0.0);
    int samples = 0;
    
    for (float x = -1.0; x <= 1.0; x++) {
        for (float y = -1.0; y <= 1.0; y++) {
            if (mod(x + y, 2.0) == 0.0) {
                color += flixel_texture2D(bitmap, block_uv + vec2(x, y) * texel_size * iBlurAmount);
                samples++;
            }
        }
    }
    color /= float(samples);
    
    // Washout effect
    float grayscale = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(grayscale) + vec3(0.1), iWashoutIntensity);
    
    // Posterize
    color.rgb = floor(color.rgb * (iColorSteps * 1.5)) / (iColorSteps * 1.5);
    
    // Film grain
    float noise = (fract(sin(dot(block_uv * vec2(12.9898, 78.233), vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 2.0;
    color.rgb += noise * (iGrainAmount * 0.5);
    
    gl_FragColor = clamp(color, 0.0, 1.0);
}
