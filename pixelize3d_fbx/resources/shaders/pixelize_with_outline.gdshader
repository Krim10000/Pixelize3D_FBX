// resources/shaders/pixelize_with_outline.gdshader
// Shader completo optimizado: pixelización + borde 2D en una sola pasada
// Input: Textura principal + configuración desde advanced_shader_panel.gd
// Output: Imagen pixelizada con borde 2D integrado en tiempo real

shader_type spatial;
render_mode unshaded, cull_disabled;

// === PARÁMETROS DE PIXELIZACIÓN (CARACTERÍSTICAS PRIORITARIAS) ===
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;

// === PARÁMETROS DE BORDE 2D (CARACTERÍSTICAS PRIORITARIAS) ===
uniform bool enable_outline = false;
uniform float outline_thickness : hint_range(0.5, 8.0, 0.1) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool outline_pixelated = true;
uniform float outline_smooth : hint_range(0.0, 1.0, 0.01) = 0.0;

// === PARÁMETROS DE REDUCCIÓN DE COLORES ===
uniform bool reduce_colors = false;
uniform int color_levels : hint_range(2, 64, 1) = 16;

// === PARÁMETROS DE DITHERING ===
uniform bool enable_dithering = false;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.1;

// === PARÁMETROS DE EFECTOS AVANZADOS ===
uniform bool contrast_enabled = false;
uniform float contrast_boost : hint_range(0.5, 2.0, 0.01) = 1.0;
uniform bool saturation_enabled = false;
uniform float saturation_mult : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform bool tint_enabled = false;
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// === TEXTURA PRINCIPAL ===
uniform sampler2D main_texture : source_color;

// === MATRIZ DE DITHERING BAYER 4x4 ===
const mat4 dither_matrix = mat4(
    vec4(0.0,  8.0,  2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0,  1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

// === FUNCIONES AUXILIARES ===

// Función para cuantizar colores
vec3 quantize_color(vec3 color, float levels) {
    return floor(color * levels + 0.5) / levels;
}

// Función para ajustar contraste
vec3 adjust_contrast(vec3 color, float contrast) {
    return clamp(((color - 0.5) * contrast) + 0.5, 0.0, 1.0);
}

// Función para ajustar saturación
vec3 adjust_saturation(vec3 color, float saturation) {
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(luminance), color, saturation);
}

// Función para detectar bordes usando diferencias de color
float detect_edge_2d(sampler2D tex, vec2 uv, vec2 texture_size, float thickness) {
    vec2 texel_size = 1.0 / texture_size;
    float edge_threshold = 0.1;
    
    // Obtener color central
    vec4 center_color = texture(tex, uv);
    
    // Muestrear vecinos en las 8 direcciones
    vec4 neighbors[8];
    neighbors[0] = texture(tex, uv + vec2(-texel_size.x, -texel_size.y) * thickness); // Top-left
    neighbors[1] = texture(tex, uv + vec2(0.0, -texel_size.y) * thickness);          // Top
    neighbors[2] = texture(tex, uv + vec2(texel_size.x, -texel_size.y) * thickness); // Top-right
    neighbors[3] = texture(tex, uv + vec2(-texel_size.x, 0.0) * thickness);          // Left
    neighbors[4] = texture(tex, uv + vec2(texel_size.x, 0.0) * thickness);           // Right
    neighbors[5] = texture(tex, uv + vec2(-texel_size.x, texel_size.y) * thickness); // Bottom-left
    neighbors[6] = texture(tex, uv + vec2(0.0, texel_size.y) * thickness);           // Bottom
    neighbors[7] = texture(tex, uv + vec2(texel_size.x, texel_size.y) * thickness);  // Bottom-right
    
    // Calcular diferencias de color
    float max_diff = 0.0;
    for (int i = 0; i < 8; i++) {
        vec3 diff = abs(center_color.rgb - neighbors[i].rgb);
        float color_diff = length(diff);
        max_diff = max(max_diff, color_diff);
    }
    
    // También considerar diferencias de transparencia
    float alpha_diff = 0.0;
    for (int i = 0; i < 8; i++) {
        alpha_diff = max(alpha_diff, abs(center_color.a - neighbors[i].a));
    }
    
    // Combinar diferencias de color y transparencia
    float edge_strength = max(max_diff, alpha_diff);
    
    return step(edge_threshold, edge_strength);
}

// === VERTEX SHADER ===
void vertex() {
    // Mantener la geometría sin cambios
}

// === FRAGMENT SHADER COMPLETO ===
void fragment() {
    // === PASO 1: PIXELIZACIÓN BÁSICA ===
    vec2 texture_size = vec2(textureSize(main_texture, 0));
    
    // Calcular coordenadas pixelizadas
    vec2 pixel_coord = UV * texture_size;
    vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_coord / texture_size;
    
    // Obtener el color base pixelizado
    vec4 color = texture(main_texture, pixelated_uv);
    
    // === PASO 2: APLICAR DITHERING SI ESTÁ ACTIVADO ===
    if (enable_dithering && dither_strength > 0.0) {
        ivec2 dither_pos = ivec2(mod(pixel_coord, 4.0));
        float dither_value = dither_matrix[dither_pos.x][dither_pos.y];
        
        vec3 dithered = color.rgb + (dither_value - 0.5) * dither_strength;
        color.rgb = clamp(dithered, 0.0, 1.0);
    }
    
    // === PASO 3: APLICAR REDUCCIÓN DE COLORES SI ESTÁ ACTIVADA ===
    if (reduce_colors) {
        color.rgb = quantize_color(color.rgb, float(color_levels));
    }
    
    // === PASO 4: DETECCIÓN Y APLICACIÓN DE BORDE 2D ===
    float outline_factor = 0.0;
    if (enable_outline && color.a > 0.1) {
        // Usar coordenadas pixelizadas o originales según configuración
        vec2 edge_uv = outline_pixelated ? pixelated_uv : UV;
        outline_factor = detect_edge_2d(main_texture, edge_uv, texture_size, outline_thickness);
        
        // Aplicar suavizado al borde si está configurado
        if (outline_smooth > 0.0) {
            outline_factor = smoothstep(0.1, 0.1 + outline_smooth, outline_factor);
        } else {
            outline_factor = step(0.1, outline_factor);
        }
    }
    
    // === PASO 5: MEZCLAR COLOR BASE CON BORDE ===
    if (outline_factor > 0.0) {
        color = mix(color, outline_color, outline_factor);
    }
    
    // === PASO 6: APLICAR EFECTOS AVANZADOS ===
    
    // Ajustar contraste
    if (contrast_enabled && contrast_boost != 1.0) {
        color.rgb = adjust_contrast(color.rgb, contrast_boost);
    }
    
    // Ajustar saturación
    if (saturation_enabled && saturation_mult != 1.0) {
        color.rgb = adjust_saturation(color.rgb, saturation_mult);
    }
    
    // Aplicar tinte
    if (tint_enabled) {
        color.rgb *= color_tint.rgb;
        color.a *= color_tint.a;
    }
    
    // === PASO 7: APLICAR RESULTADO FINAL ===
    ALBEDO = color.rgb;
    ALPHA = color.a;
    
    // Asegurar que los bordes sean opacos si se especifica
    if (enable_outline && outline_factor > 0.5) {
        ALPHA = max(ALPHA, outline_color.a);
    }
}