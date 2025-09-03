// resources/shaders/pixelize_advanced.gdshader
// Shader espacial (3D) avanzado para pixelización con efectos de borde - CORREGIDO para Godot 4.4
// Input: Textura principal del modelo 3D, parámetros configurables desde UI
// Output: Imagen pixelizada con efectos de borde opcionales y post-procesamiento avanzado

shader_type spatial;
render_mode unshaded, cull_disabled, alpha_to_coverage_and_one;

// === PARÁMETROS DE PIXELIZACIÓN ===
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;
uniform bool reduce_colors = false;
uniform int color_levels : hint_range(2, 64, 1) = 16;
uniform bool enable_dithering = false;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.1;

// === PARÁMETROS DE BORDE CORREGIDOS ===
uniform bool enable_outline = false;
uniform float outline_thickness : hint_range(0.5, 8.0, 0.1) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool outline_pixelated = true;
uniform float outline_smooth : hint_range(0.0, 1.0, 0.01) = 0.0;

// === PARÁMETROS AVANZADOS DE ESTILO ===
uniform float contrast_boost : hint_range(0.5, 2.0, 0.01) = 1.0;
uniform float saturation_mult : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform vec3 color_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform bool apply_gamma_correction = true;
uniform float gamma_value : hint_range(0.5, 2.5, 0.01) = 1.0;

// === TEXTURAS ===
uniform sampler2D main_texture : source_color;
uniform sampler2D outline_pattern_texture : source_color;
uniform bool use_outline_pattern = false;

// === MATRIZ DE DITHERING BAYER 4x4 ===
const mat4 dither_matrix = mat4(
    vec4(0.0,  8.0,  2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0,  1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

// === FUNCIONES DE UTILIDAD ===

// Función para cuantizar colores
vec3 quantize_color(vec3 color, float levels) {
    return floor(color * levels + 0.5) / levels;
}

// Función para detectar bordes usando diferencias de color
float detect_edge(sampler2D tex, vec2 uv, vec2 tex_size, float thickness) {
    vec2 texel_size = 1.0 / tex_size;
    
    vec4 center = texture(tex, uv);
    
    // Muestreo en 8 direcciones para detección de borde
    vec4 n  = texture(tex, uv + vec2(0.0, -thickness) * texel_size);
    vec4 s  = texture(tex, uv + vec2(0.0, thickness) * texel_size);
    vec4 e  = texture(tex, uv + vec2(thickness, 0.0) * texel_size);
    vec4 w  = texture(tex, uv + vec2(-thickness, 0.0) * texel_size);
    vec4 ne = texture(tex, uv + vec2(thickness, -thickness) * texel_size);
    vec4 nw = texture(tex, uv + vec2(-thickness, -thickness) * texel_size);
    vec4 se = texture(tex, uv + vec2(thickness, thickness) * texel_size);
    vec4 sw = texture(tex, uv + vec2(-thickness, thickness) * texel_size);
    
    // Calcular diferencias de color
    float max_diff = 0.0;
    max_diff = max(max_diff, length(center.rgb - n.rgb));
    max_diff = max(max_diff, length(center.rgb - s.rgb));
    max_diff = max(max_diff, length(center.rgb - e.rgb));
    max_diff = max(max_diff, length(center.rgb - w.rgb));
    max_diff = max(max_diff, length(center.rgb - ne.rgb));
    max_diff = max(max_diff, length(center.rgb - nw.rgb));
    max_diff = max(max_diff, length(center.rgb - se.rgb));
    max_diff = max(max_diff, length(center.rgb - sw.rgb));
    
    // Considerar diferencias de alpha para bordes de transparencia
    float alpha_diff = 0.0;
    alpha_diff = max(alpha_diff, abs(center.a - n.a));
    alpha_diff = max(alpha_diff, abs(center.a - s.a));
    alpha_diff = max(alpha_diff, abs(center.a - e.a));
    alpha_diff = max(alpha_diff, abs(center.a - w.a));
    alpha_diff = max(alpha_diff, abs(center.a - ne.a));
    alpha_diff = max(alpha_diff, abs(center.a - nw.a));
    alpha_diff = max(alpha_diff, abs(center.a - se.a));
    alpha_diff = max(alpha_diff, abs(center.a - sw.a));
    
    return max(max_diff, alpha_diff * 2.0);
}

// Función para aplicar corrección gamma
vec3 apply_gamma(vec3 color, float gamma) {
    return pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
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

// === FUNCIÓN DEL VERTEX SHADER ===
void vertex() {
    // Mantener la geometría sin cambios para compatibilidad máxima
}

// === FUNCIÓN PRINCIPAL DEL FRAGMENT SHADER ===
void fragment() {
    vec2 texture_size = vec2(textureSize(main_texture, 0));
    
    // === PASO 1: PIXELIZACIÓN BÁSICA ===
    vec2 pixel_coord = UV * texture_size;
    vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_coord / texture_size;
    
    // Obtener el color base pixelizado
    vec4 base_color = texture(main_texture, pixelated_uv);
    vec4 final_color = base_color;
    
    // === PASO 2: APLICAR DITHERING SI ESTÁ HABILITADO ===
    if (enable_dithering && dither_strength > 0.0) {
        ivec2 dither_pos = ivec2(mod(pixel_coord, 4.0));
        float dither_value = dither_matrix[dither_pos.x][dither_pos.y];
        
        vec3 dithered = base_color.rgb + (dither_value - 0.5) * dither_strength;
        final_color.rgb = clamp(dithered, 0.0, 1.0);
    }
    
    // === PASO 3: REDUCCIÓN DE COLORES SI ESTÁ HABILITADA ===
    if (reduce_colors) {
        final_color.rgb = quantize_color(final_color.rgb, float(color_levels));
    }
    
    // === PASO 4: DETECCIÓN Y APLICACIÓN DE BORDES ===
    float outline_factor = 0.0;
    if (enable_outline && final_color.a > 0.1) {
        // Usar coordenadas pixelizadas o originales según configuración
        vec2 edge_uv = outline_pixelated ? pixelated_uv : UV;
        outline_factor = detect_edge(main_texture, edge_uv, texture_size, outline_thickness);
        
        // Aplicar suavizado al borde si está configurado
        if (outline_smooth > 0.0) {
            outline_factor = smoothstep(0.1, 0.1 + outline_smooth, outline_factor);
        } else {
            outline_factor = step(0.1, outline_factor);
        }
    }
    
    // === PASO 5: APLICAR PATRÓN DE BORDE SI ESTÁ CONFIGURADO ===
    vec4 computed_outline_color = outline_color;
    if (use_outline_pattern && outline_factor > 0.0) {
        vec4 pattern_color = texture(outline_pattern_texture, UV);
        computed_outline_color = mix(outline_color, pattern_color, 0.5);
    }
    
    // === PASO 6: MEZCLAR COLOR BASE CON BORDE ===
    if (outline_factor > 0.0) {
        final_color = mix(final_color, computed_outline_color, outline_factor);
    }
    
    // === PASO 7: APLICAR EFECTOS AVANZADOS DE COLOR ===
    if (contrast_boost != 1.0) {
        final_color.rgb = adjust_contrast(final_color.rgb, contrast_boost);
    }
    
    if (saturation_mult != 1.0) {
        final_color.rgb = adjust_saturation(final_color.rgb, saturation_mult);
    }
    
    if (color_tint != vec3(1.0, 1.0, 1.0)) {
        final_color.rgb *= color_tint;
    }
    
    if (apply_gamma_correction && gamma_value != 1.0) {
        final_color.rgb = apply_gamma(final_color.rgb, gamma_value);
    }
    
    // === PASO 8: APLICAR RESULTADO FINAL ===
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
    
    // Asegurar que los bordes sean opacos si se especifica
    if (enable_outline && outline_factor > 0.5) {
        ALPHA = max(ALPHA, outline_color.a);
    }
}