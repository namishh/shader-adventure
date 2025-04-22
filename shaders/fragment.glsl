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

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 7; i++) {
        value += amplitude * noise(st * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
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

float gridLines(vec2 uv, float lineWidth, float irregularity, float fadeEdges) {
    vec2 distortUV = uv;
    
    distortUV.x += noise(uv * 5.0) * irregularity;
    distortUV.y += noise((uv + vec2(42.0, 17.0)) * 5.0) * irregularity;
    
    const float GRID_DENSITY = 30.0;
    
    float xGrid = abs(sin(distortUV.x * GRID_DENSITY * 3.14159));
    float yGrid = abs(sin(distortUV.y * GRID_DENSITY * 3.14159));
    
    xGrid = smoothstep(1.0 - lineWidth, 1.0, xGrid);
    yGrid = smoothstep(1.0 - lineWidth, 1.0, yGrid);
    
    float edgeFade = smoothstep(0.0, fadeEdges, uv.x) * 
                     smoothstep(0.0, fadeEdges, uv.y) * 
                     smoothstep(0.0, fadeEdges, 1.0 - uv.x) * 
                     smoothstep(0.0, fadeEdges, 1.0 - uv.y);
    
    float grid = max(xGrid, yGrid);
    
    return grid * edgeFade;
}

float forestFeature(vec2 uv, vec2 center, float size) {
    float dist = length(uv - center);
    float noiseVal = noise(uv * 15.0) * 0.02;
    
    float baseShape = smoothstep(size + noiseVal, size - 0.01 + noiseVal, dist);
    float forestTexture = noise(uv * 40.0) * 0.3 + 0.7;
    
    return baseShape * forestTexture;
}

float mountainFeature(vec2 uv, vec2 center, float size) {
    float dist = length(uv - center);
    float baseShape = smoothstep(size, size - 0.01, dist);
    float mountainTexture = noise(uv * 30.0) * 0.4 + 0.6;
    
    return baseShape * mountainTexture;
}

void main() {
    vec3 paperColor = vec3(0.94, 0.88, 0.71);
    vec3 darkPaperColor = vec3(0.69, 0.64, 0.49);
    vec3 waterColor = vec3(0.5, 0.7, 0.8) * 0.7; 
    vec3 landColor = vec3(0.76, 0.7, 0.5); 
    vec3 forestColor = vec3(0.2, 0.5, 0.25);
    vec3 mountainColor = vec3(0.29, 0.19, 0.15); 
    
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    float noise1 = fbm(uv * 12.0 + vec2(23.0, 42.0));
    float noise2 = fbm(uv * 2.5 + vec2(11.0, 79.0));
    float noise3 = fbm(uv * 6.0 + vec2(7.0, 13.0));
    float noise4 = fbm(uv * 2.0 + vec2(7.0, 4.0));
    
    float terrainValue = noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2 + noise4 * 0.1;
    
    float centerDist = length(uv - vec2(0.5, 0.5));
    terrainValue = mix(terrainValue, terrainValue * (1.0 - centerDist * 0.5), 0.3);
    
    bool isLand = terrainValue > 0.5;
    
    vec3 baseColor = isLand ? landColor : waterColor;
    vec3 finalColor = mix(paperColor, baseColor, 0.7);

    float grid = gridLines(uv, 0.001, 0.003, 0.005);
    vec3 gridColor = vec3(0.2, 0.15, 0.1);
    finalColor = mix(finalColor, gridColor, grid * 0.2); 
    
    float edgeEffect = edgeDarkening(uv);
    finalColor = mix(darkPaperColor, finalColor, edgeEffect);
    
    float cornerDist = min(min(length(uv), length(uv - vec2(1.0, 0.0))), 
                          min(length(uv - vec2(0.0, 1.0)), length(uv - vec2(1.0, 1.0))));
    float cornerEffect = smoothstep(0.0, 0.3, cornerDist);
    finalColor = mix(darkPaperColor * 0.8, finalColor, cornerEffect);

    float coastline = smoothstep(0.5 - 0.02, 0.5 + 0.02, terrainValue);
    coastline = abs(coastline - 0.5) * 2.0;
    coastline = pow(coastline, 0.3);
    finalColor = mix(finalColor, vec3(0.3, 0.2, 0.1), (1.0 - coastline) * 0.3);

    if (isLand) {
        float forestDensity = 0.0;
        
        float forestNoise = fbm(uv * 3.0 + vec2(42.0, 17.0));
        bool forestRegion = forestNoise > 0.60 && forestNoise < 0.85;
        
        if (forestRegion && terrainValue > 0.55) {
            for (int i = 0; i < 100; i++) {
                float seed = float(i) * 3.145;
                
                vec2 forestPos = vec2(
                    random(vec2(seed, seed * 0.13)) * 0.1 + uv.x - 0.05,
                    random(vec2(seed * 0.27, seed * 0.31)) * 0.1 + uv.y - 0.05
                );
                
                if (fbm(forestPos * 3.0 + vec2(42.0, 17.0)) > 0.55) {
                    float forestSize = 0.008 + random(vec2(seed * 0.41, seed * 0.59)) * 0.008;
                    forestDensity += forestFeature(uv, forestPos, forestSize) * 0.4;
                }
            }
            
            forestDensity = min(forestDensity, 0.8);
            
            finalColor = mix(finalColor, forestColor, forestDensity * 0.8);
        }
        
        float mountainNoise = fbm(uv * 2.5 + vec2(91.0, 47.0));
        bool mountainRegion = mountainNoise > 0.65 && terrainValue > 0.65;
        
        if (mountainRegion) {
            float mountainFeatures = 0.0;
            
            for (int i = 0; i < 80; i++) {
                float seed = float(i) * 7.919;
                
                vec2 mountainPos = vec2(
                    random(vec2(seed, seed * 0.17)) * 0.1 + uv.x - 0.05,
                    random(vec2(seed * 0.29, seed * 0.37)) * 0.1 + uv.y - 0.05
                );
                
                if (fbm(mountainPos * 2.5 + vec2(91.0, 47.0)) > 0.65) {
                    float mountainSize = 0.005 + random(vec2(seed * 0.43, seed * 0.53)) * 0.005;
                    float feature = mountainFeature(uv, mountainPos, mountainSize);
                    mountainFeatures += feature;
                }
            }
            
            finalColor = mix(finalColor, mountainColor, mountainFeatures * 0.7);
        }
    }

    float totalStain = 0.0;
    for (int i = 1; i <= 20; i++) {
        float seed = float(i) * random(vec2(0, 100));
        totalStain += randomStain(uv, seed);
    }
    
    vec3 stainColor = vec3(0.34, 0.23, 0.05);
    finalColor = mix(finalColor, stainColor, totalStain * 0.7);
    
    float grainn = grain(uv, 500.0, 0.08);
    finalColor += grainn;
    
    float ageSpots = noise(uv * 2.0) * 0.1;
    vec3 ageSpotColor = vec3(0.07, 0.06, 0.04);
    finalColor = mix(finalColor, ageSpotColor, ageSpots);
    
    float fiberss = fibers(uv);
    finalColor = mix(finalColor, finalColor * 0.9, (1.0 - fiberss) * 0.7);
    
    gl_FragColor = vec4(finalColor, 1.0);
}