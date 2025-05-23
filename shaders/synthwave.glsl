precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

#define INTENSITY 0.3 
#define GRID_LINE_WIDTH 0.0001
#define SUN_INTENSITY 1.2

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float round(float x) {
    return floor(x + 0.5);
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

vec3 createSun(vec2 uv) {
    float aspect = u_resolution.x / u_resolution.y;
    vec2 center = vec2(0.5, 0.5 + 0.10);
    vec2 adjustedUV = vec2((uv.x - 0.5) * aspect + 0.5, uv.y);
    float dist = distance(adjustedUV, center);
    float sunSize = 0.24;
    float sunMask = step(dist, sunSize);
    
    if (uv.y < center.y && sunMask > 0.5) {
        float chordOffsets[6];
        float baseOffsets[6];
        baseOffsets[0] = 0.0;
        baseOffsets[1] = 0.04;
        baseOffsets[2] = 0.08;
        baseOffsets[3] = 0.12;
        baseOffsets[4] = 0.16;
        baseOffsets[5] = 0.2;
        
        float panSpeed = 0.25; 
        float panOffset = fract(u_time * panSpeed); 
        float maxOffset = 0.25; 
        for (int i = 0; i < 6; i++) {
            chordOffsets[i] = baseOffsets[i] + panOffset * maxOffset;
            if (chordOffsets[i] > maxOffset) {
                chordOffsets[i] -= maxOffset;
            }
        }
        
        float chordThicknesses[6];
        chordThicknesses[0] = 0.005;
        chordThicknesses[1] = 0.006;
        chordThicknesses[2] = 0.007;
        chordThicknesses[3] = 0.008;
        chordThicknesses[4] = 0.009;
        chordThicknesses[5] = 0.01;

        for (int i = 0; i < 6; i++) {
            float chordY = center.y - chordOffsets[i];
            if (abs(uv.y - chordY) < chordThicknesses[i]) {
                float y_dist = abs(chordY - center.y);
                float x_dist = sqrt(max(0.0, sunSize * sunSize - y_dist * y_dist)) + 0.2;
                float x_min = center.x - x_dist / aspect;
                float x_max = center.x + x_dist / aspect;
                if (uv.x >= x_min && uv.x <= x_max) {
                    sunMask = 0.0;
                    break;
                }
            }
        }
    }
    
    vec3 yellowColor = vec3(1.0, 0.9, 0.2);
    vec3 pinkColor = vec3(0.98, 0.2, 0.8);
    float gradientFactor = clamp((uv.y - (center.y - sunSize)) / (2.0 * sunSize), 0.0, 1.0);
    vec3 sunColor = mix(yellowColor, pinkColor, gradientFactor);
    
    sunColor *= SUN_INTENSITY;
    
    return sunColor * sunMask;
}

vec3 createGrid(vec2 p) {
    vec3 gridcolor = vec3(0.1, 0.15, 0.31); 
    vec3 linecolor = vec3(0.13, 0.31, 0.24);

    vec2 q = vec2(p.x/p.y, 1.0/p.y);
    
    float offs = -0.9 * u_time;
    q.y += offs;
    
    vec2 qh = vec2(q.x, round(q.y));
    vec2 qv = vec2(round(q.x), q.y);
    qh.y -= offs;
    qv.y -= offs;
    
    vec2 ph = vec2(qh.x/qh.y, 1.0/qh.y);
    vec2 pv = vec2(qv.x/qv.y, 1.0/qv.y);
    
    ph.y = min(ph.y, 0.0);
    pv.y = min(pv.y, 0.0);
    
    float dh = length(p-ph);
    float dv = length(p-pv);
    
    float eps = 0.01;
    dh = max(dh - GRID_LINE_WIDTH * eps * abs(qh.y), 0.0);
    dv = max(dv - GRID_LINE_WIDTH * eps * abs(qv.y), 0.0);
    
    gridcolor += linecolor * 0.001/(dh*dh+eps*eps) * INTENSITY * 0.5;
    gridcolor += linecolor * 0.001/(dv*dv+eps*eps) * INTENSITY * 0.5;
    
    return gridcolor;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    vec2 p = (uv * 2.0 - 1.0);
    p.x *= u_resolution.x / u_resolution.y; 
    
    vec3 bg1color = vec3(0.57, 0.73, 0.92);
    vec3 bg2color = vec3(0.3, 0.0, 0.5);
    
    vec3 bgColor = mix(bg1color, bg2color, uv.y);
    
    vec3 sunColor = createSun(uv);
    bgColor = mix(bgColor, sunColor, sunColor.r);
    
    if (p.y < 0.0) {
        vec3 gridColor = createGrid(p);
        bgColor = gridColor; 
    }
    
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
            
            float twinkleEffect = twinkle(gridCoord, u_time);
            
            float distToCenter = distance(uv, vec2(0.5, 0.5));
            float sunInfluence = smoothstep(0.25, 0.4, distToCenter);
            
            bgColor += vec3(0.6 * star * twinkleEffect * sunInfluence);
        }
    }
    
    float scanlineEffect = scanline(uv, u_time);
    bgColor *= scanlineEffect;
    
    float vignetteEffect = vignette(uv);
    bgColor *= vignetteEffect;
    
    gl_FragColor = vec4(bgColor, 1.0);
}