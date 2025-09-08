// resources/shaders/pixelize_advanced_optimized.gdshader
// Shader optimizado para pixelización con efectos de borde - BASADO EN pixelize.gdshader FUNCIONAL
// Input: Textura principal del modelo 3D, parámetros configurables desde advanced_shader_panel.gd
// Output: Imagen pixelizada con efectos de borde en tiempo real

shader_type spatial;
render_mode unshaded, cull_disabled;

// === PARÁMETROS DE PIXELIZACIÓN (CARACTERÍSTICAS PRIORITARIAS) ===
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 2.0;

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

// === MATRIZ DE DITHERING BAYER 4x4 (IGUAL QUE EL SHADER ORIGINAL FUNCIONAL) ===
const mat4 dither_matrix = mat4(
    vec4(0.0,  8.0,  2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0,  1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

// === FUNCIONES AUXILIARES ===

// Función para cuantizar colores (IGUAL QUE EL SHADER ORIGINAL FUNCIONAL)
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

// === VERTEX SHADER (MANTENER SIMPLE COMO EL ORIGINAL) ===
void vertex() {
    // Mantener la geometría sin cambios para máxima compatibilidad
}

// === FRAGMENT SHADER (BASADO EN pixelize.gdshader QUE FUNCIONA BIEN) ===
void fragment() {
    // === PASO 1: PIXELIZACIÓN BÁSICA (EXACTAMENTE COMO pixelize.gdshader) ===

    // Obtener el tamaño de la textura
    vec2 texture_size = vec2(textureSize(main_texture, 0));

    // Calcular coordenadas pixelizadas (ALGORITMO ORIGINAL QUE FUNCIONA)
    vec2 pixel_coord = UV * texture_size;
    vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_coord / texture_size;

    // Obtener el color de la textura
    vec4 color = texture(main_texture, pixelated_uv);

    // === PASO 2: APLICAR DITHERING SI ESTÁ ACTIVADO (IGUAL QUE EL ORIGINAL) ===
    if (enable_dithering && dither_strength > 0.0) {
        ivec2 dither_pos = ivec2(mod(pixel_coord, 4.0));
        float dither_value = dither_matrix[dither_pos.x][dither_pos.y];

        // Aplicar dithering al color antes de la cuantización
        vec3 dithered = color.rgb + (dither_value - 0.5) * dither_strength;
        color.rgb = clamp(dithered, 0.0, 1.0);
    }

    // === PASO 3: APLICAR REDUCCIÓN DE COLORES SI ESTÁ ACTIVADA (IGUAL QUE EL ORIGINAL) ===
    if (reduce_colors) {
        color.rgb = quantize_color(color.rgb, float(color_levels));
    }

    // === PASO 4: APLICAR EFECTOS AVANZADOS OPCIONALES ===

    // Ajustar contraste si está habilitado
    if (contrast_enabled && contrast_boost != 1.0) {
        color.rgb = adjust_contrast(color.rgb, contrast_boost);
    }

    // Ajustar saturación si está habilitado
    if (saturation_enabled && saturation_mult != 1.0) {
        color.rgb = adjust_saturation(color.rgb, saturation_mult);
    }

    // Aplicar tinte de color si está habilitado
    if (tint_enabled) {
        color.rgb *= color_tint.rgb;
        color.a *= color_tint.a;
    }

    // === PASO 5: APLICAR EL COLOR FINAL ===
    ALBEDO = color.rgb;
    ALPHA = color.a;
}