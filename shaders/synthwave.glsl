precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.001

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float twinkle(vec2 gridCoord, float time) {
    float speed = 1.0 + random(gridCoord + 3.0) * 2.0;
    float phaseOffset = random(gridCoord + 4.0) * 6.28;
    
    return 0.5 + 0.5 * sin(time * speed + phaseOffset);
}

float scanline(vec2 uv, float time) {
    float scanlineCount = 100.0;
    float speed = 10.0;
    
    float scanlineY = fract(uv.y * scanlineCount + time * speed);
    float scanlineIntensity = 0.14;
    
    return 1.0 - scanlineIntensity * smoothstep(0.4, 0.6, scanlineY);
}

float vignette(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    float vignetteStrength = 0.35; 
    return 1.0 - (uv.x * uv.x + uv.y * uv.y) * vignetteStrength;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdSunSlices(vec3 p, vec3 center, float radius) {
    float result = sdSphere(p - center, radius);
    
    float panSpeed = 0.25;
    float panOffset = fract(u_time * panSpeed);
    float maxOffset = 0.25;
    
    float baseOffsets[6];
    baseOffsets[0] = 0.0;
    baseOffsets[1] = 0.04;
    baseOffsets[2] = 0.08;
    baseOffsets[3] = 0.12;
    baseOffsets[4] = 0.16;
    baseOffsets[5] = 0.2;
    
    float chordThicknesses[6];
    chordThicknesses[0] = 0.005;
    chordThicknesses[1] = 0.006;
    chordThicknesses[2] = 0.007;
    chordThicknesses[3] = 0.008;
    chordThicknesses[4] = 0.009;
    chordThicknesses[5] = 0.01;
    
    if (p.y < center.y) {
        for (int i = 0; i < 6; i++) {
            float chordOffset = baseOffsets[i] + panOffset * maxOffset;
            if (chordOffset > maxOffset) {
                chordOffset -= maxOffset;
            }
            
            float sliceY = center.y - chordOffset;
            float thickness = chordThicknesses[i];
            
            float sliceDist = abs(p.y - sliceY) - thickness;
            
            float y_dist = abs(sliceY - center.y);
            float x_dist = sqrt(max(0.0, radius * radius - y_dist * y_dist)) + 0.2;
            
            if (abs(p.x - center.x) < x_dist) {
                result = max(result, -sliceDist);
            }
        }
    }
    
    return result;
}

float sceneSDF(vec3 p) {
    vec3 sunCenter = vec3(0.5, 0.5 + 0.08, 2.0);
    float sunRadius = 0.24;
    
    return sdSunSlices(p, sunCenter, sunRadius);
}

float rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = sceneSDF(p);
        dO += dS;
        if (dO > MAX_DIST || dS < SURF_DIST) break;
    }
    
    return dO;
}

vec3 getSunColor(vec3 p) {
    vec3 sunCenter = vec3(0.5, 0.5 + 0.08, 2.0);
    float sunRadius = 0.24;
    
    float gradientFactor = clamp((p.y - (sunCenter.y - sunRadius)) / (2.0 * sunRadius), 0.0, 1.0);
    
    vec3 yellowColor = vec3(1.0, 0.9, 0.2);
    vec3 pinkColor = vec3(0.98, 0.2, 0.8);
    
    return mix(yellowColor, pinkColor, gradientFactor);
}

vec3 createStars(vec2 uv, float time) {
    vec3 stars = vec3(0.0);
    
    if (uv.y > 0.4) {
        float cellSize = 100.0;
        vec2 gridCoord = floor(uv * vec2(cellSize, cellSize * 0.5));
        vec2 cellUv = fract(uv * vec2(cellSize, cellSize * 0.5));
        
        vec2 cellCenter = vec2(
            random(gridCoord) * 0.6 + 0.2, 
            random(gridCoord + 1.0) * 0.6 + 0.2  
        );
        
        float r = random(gridCoord + 2.0);
        
        if (r > 0.6) {
            float dist = distance(cellUv, cellCenter);
            float starSize = 0.06;
            float star = smoothstep(starSize, starSize - 0.01, dist);
            
            float twinkleEffect = twinkle(gridCoord, time);
            
            float distToCenter = distance(uv, vec2(0.5, 0.5));
            float sunInfluence = smoothstep(0.25, 0.4, distToCenter);
            
            stars = vec3(0.6 * star * twinkleEffect * sunInfluence);
        }
    }
    
    return stars;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float aspect = u_resolution.x / u_resolution.y;
    
    vec3 bg1color = vec3(0.57, 0.73, 0.92);
    vec3 bg2color = vec3(0.3, 0.0, 0.5);
    vec3 bgColor = mix(bg1color, bg2color, uv.y);
    
    vec3 ro = vec3((uv.x - 0.5) * aspect + 0.5, uv.y, 0.0); 
    vec3 rd = vec3(0.0, 0.0, 1.0); 
    
    float d = rayMarch(ro, rd);
    
    bool hitSun = d < MAX_DIST;
    
    vec2 originalUv = uv;
    if (hitSun) {
        vec3 p = ro + rd * d;
        vec3 sunColor = getSunColor(p);
        
        bgColor = sunColor;
    }
    
    if (!hitSun) {
        vec3 starColor = createStars(originalUv, u_time);
        bgColor += starColor;
    }
    
    float scanlineEffect = scanline(originalUv, u_time);
    bgColor *= scanlineEffect;
    
    float vignetteEffect = vignette(originalUv);
    bgColor *= vignetteEffect;
    
    gl_FragColor = vec4(bgColor, 1.0);
}