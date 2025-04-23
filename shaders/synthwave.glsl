precision mediump float;
uniform vec2 u_resolution;
uniform float u_time;

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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    vec3 bg1color = vec3(0.57, 0.73, 0.92);
    vec3 bg2color = vec3(0.3, 0.0, 0.5);
    
    vec3 bgColor = mix(bg1color, bg2color, uv.y);
    
    if (uv.y > 0.5) {
        float cellSize = 100.0;
        vec2 gridCoord = floor(uv * vec2(cellSize, cellSize * 0.5));
        vec2 cellUv = fract(uv * vec2(cellSize, cellSize * 0.5));
        
        vec2 cellCenter = vec2(
            random(gridCoord) * 0.6 + 0.2, 
            random(gridCoord + 1.0) * 0.6 + 0.2  
        );
        
        float r = random(gridCoord + 2.0);
        
        if (r > 0.97) {
            float dist = distance(cellUv, cellCenter);
            float starSize = 0.06;
            float star = smoothstep(starSize, starSize - 0.01, dist);
            
            float twinkleEffect = twinkle(gridCoord, u_time);
            
            bgColor += vec3(0.6 * star * twinkleEffect);
        }
    }
    
    float scanlineEffect = scanline(uv, u_time);
    bgColor *= scanlineEffect;
    
    float vignetteEffect = vignette(uv);
    bgColor *= vignetteEffect;
    
    gl_FragColor = vec4(bgColor, 1.0);
}