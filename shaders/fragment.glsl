precision mediump float;

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

void main() {
    vec3 paperColor = vec3(0.94, 0.88, 0.71);
    
    vec2 uv = gl_FragCoord.xy / vec2(1920.0, 1080.0); 
    
    float totalStain = 0.0;
    
    for (int i = 1; i <= 30; i++) {
        float seed = float(i) * random(vec2(0, 100));
        totalStain += randomStain(uv, seed);
    }
    
    vec3 stainColor = vec3(0.34, 0.23, 0.05);
    
    vec3 finalColor = mix(paperColor, stainColor, totalStain);
    
    float paperNoise = noise(uv * 20.0) * 0.03;
    finalColor = mix(finalColor, vec3(0.92, 0.85, 0.67), paperNoise);
    
    gl_FragColor = vec4(finalColor, 1.0);
}