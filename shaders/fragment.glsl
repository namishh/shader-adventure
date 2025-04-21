precision mediump float;

uniform vec2 u_resolution;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = smoothstep(0.0, 1.0, f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float stain(vec2 uv, vec2 center, float size, float irregularity) {
    float dist = length(uv - center);
    float noise_val = noise(uv * 3.0) * irregularity;
    return smoothstep(size + noise_val, size - 0.1 + noise_val, dist);
}

float randomStain(vec2 uv, float seed) {
    vec2 pos = vec2(
        random(vec2(seed, seed * 0.1)),
        random(vec2(seed * 0.2, seed * 0.3))
    );
    
    float size = 0.05 + random(vec2(seed * 0.4, seed * 0.5)) * 0.1;
    float irreg = 0.03 + random(vec2(seed * 0.6, seed * 0.7)) * 0.05;
    float intensity = 0.08 + random(vec2(seed * 0.8, seed * 0.9)) * 0.05;
    
    return stain(uv, pos, size, irreg) * intensity;
}

float grain(vec2 uv, float scale, float intensity) {
    return (random(uv * scale) - 0.5) * intensity;
}

float fibers(vec2 uv) {
    float hPattern = noise(vec2(uv.x * 100.0, uv.y * 10.0)) * 0.5 + 0.9;
    float vPattern = noise(vec2(uv.x * 10.0, uv.y * 100.0)) * 0.5 + 0.9;
    
    return mix(hPattern, vPattern, 0.8);
}

float edgeDarkening(vec2 uv) {
    float distFromLeft = uv.x;
    float distFromRight = 1.0 - uv.x;
    float distFromTop = uv.y;
    float distFromBottom = 1.0 - uv.y;
    
    float minDist = min(min(distFromLeft, distFromRight), min(distFromTop, distFromBottom));
    float edgeEffect = smoothstep(0.0, 0.15, minDist);
    float noiseEffect = noise(uv * 5.0) * 0.2;
    
    return edgeEffect * (0.85 + noiseEffect);
}

void main() {
    vec3 paperColor = vec3(0.94, 0.88, 0.71);
    vec3 darkPaperColor = vec3(0.69, 0.64, 0.49);
    
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float totalStain = 0.0;
    for (int i = 1; i <= 30; i++) {
        float seed = float(i) * random(vec2(0, 100));
        totalStain += randomStain(uv, seed);
    }
    
    vec3 stainColor = vec3(0.34, 0.23, 0.05);
    vec3 finalColor = mix(paperColor, stainColor, totalStain);
    
    float grainn = grain(uv, 500.0, 0.08);
    finalColor += grainn;
    
    float ageSpots = noise(uv * 2.0) * 0.1;
    vec3 ageSpotColor = vec3(0.07, 0.06, 0.04);
    finalColor = mix(finalColor, ageSpotColor, ageSpots);
    
    float edgeEffect = edgeDarkening(uv);
    
    finalColor = mix(darkPaperColor, finalColor, edgeEffect);
    
    float cornerDist = min(min(length(uv), length(uv - vec2(1.0, 0.0))), 
                          min(length(uv - vec2(0.0, 1.0)), length(uv - vec2(1.0, 1.0))));
    float cornerEffect = smoothstep(0.0, 0.3, cornerDist);
    finalColor = mix(darkPaperColor * 0.8, finalColor, cornerEffect);


    float fiberss = fibers(uv);
    finalColor = mix(finalColor, finalColor * 0.9, (1.0 - fiberss) * 0.7);

    gl_FragColor = vec4(finalColor, 1.0);
}