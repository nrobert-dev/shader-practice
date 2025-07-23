shader_type spatial;

// ======== Uniforms ========
uniform sampler2D noiseTexture;
uniform float land_threshold : hint_range(0.0, 1.0) = 0.5;

uniform vec3 sea_color : source_color = vec3(0.369, 0.827, 0.988);
uniform vec3 land_color : source_color = vec3(1.0, 1.0, 1.0);

uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform vec3 edge_color : source_color = vec3(1.0, 0.5, 0.0);

uniform float extrusion_height : hint_range(0.0, 0.2) = 0.05;

// ======== Vertex Shader ========
void vertex() {
    // Sample noise texture at this vertex UV
    float noise_value = texture(noiseTexture, UV).r;
    
    // Calculate difference from land_threshold
    float diff = noise_value - land_threshold;
    
    // If vertex is land (above threshold), extrude it upward
    if (diff >= 0.0) {
        // Extrude along vertex normal, scaled by noise_value and extrusion height
        VERTEX += NORMAL * noise_value * extrusion_height;
    }
}

// ======== Fragment Shader ========
void fragment() {
    // Sample noise texture for this fragment
    vec4 base_color = texture(noiseTexture, UV);
    float noise_value = base_color.r;
    
    // Calculate difference from land_threshold
    float diff = noise_value - land_threshold;
    
    // Calculate upwardness based on WORLD_NORMAL for shading
    vec3 WORLD_NORMAL = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;
    float up_factor = clamp(dot(WORLD_NORMAL, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    
    // ======== Water / Sea shading ========
    if (diff < 0.0) {
        // Calculate depth factor for water color gradient (deep = dark, shallow = sea_color)
        float depth_factor = clamp(noise_value / land_threshold, 0.0, 1.0);
        
        // Interpolate between deep ocean blue and sea_color
        ALBEDO = mix(vec3(0.0, 0.1, 0.3), sea_color, depth_factor);
        
        // Water surface properties: shiny and reflective
        ROUGHNESS = 0.098;
        SPECULAR = 0.9;
        
        // Fresnel effect for glancing angle glow
        float fresnel = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
        EMISSION = sea_color * 0.1 + sea_color * fresnel * 0.5;
    }
    
    // ======== Edge glow shading ========
    else if (diff < edge_width) {
        // Apply glowing edge color at land boundary
        ALBEDO = edge_color;
        EMISSION = edge_color * 2.0;
    }
    
    // ======== Land shading ========
    else {
        // Base land color blended with whiteness based on upward facing normal
        float whiteness = smoothstep(0.6, 1.0, up_factor);
        ALBEDO = mix(land_color, vec3(1.0), whiteness);
        
        ROUGHNESS = 1.0;
    }
}
