// resources/shaders/pixelize_advanced_improved.gdshader
// Shader spatial mejorado para pixelización - BASADO EN EL SHADER SIMPLE QUE FUNCIONA BIEN
// Combina la simplicidad de pixelize_spatial.gdshader con funcionalidades avanzadas
shader_type spatial;
render_mode unshaded, cull_disabled;

// === PARÁMETROS DE PIXELIZACIÓN (SIMPLE Y EFECTIVA) ===
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 2.0;
uniform bool reduce_colors = false;
uniform int color_levels : hint_range(2, 64, 1) = 16;
uniform bool enable_dithering = false;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.1;

// === PARÁMETROS DE EFECTOS AVANZADOS (OPCIONALES) ===
uniform bool contrast_enabled = false;
uniform float contrast_boost : hint_range(0.5, 2.0, 0.01) = 1.0;
uniform bool saturation_enabled = false;
uniform float saturation_mult : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform bool tint_enabled = false;
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool gamma_enabled = false;
uniform float gamma_value : hint_range(0.5, 2.5, 0.01) = 1.0;

// === TEXTURA PRINCIPAL ===
uniform sampler2D main_texture : source_color;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// === MATRIZ DE DITHERING BAYER 4x4 (IGUAL QUE EL SHADER ORIGINAL) ===
const mat4 dither_matrix = mat4(
    vec4(0.0,  8.0,  2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0,  1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

// === FUNCIONES AUXILIARES ===

// Función para cuantizar colores (IGUAL QUE EL SHADER ORIGINAL)
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

// Función para aplicar corrección gamma
vec3 apply_gamma(vec3 color, float gamma) {
    return pow(max(color, vec3(0.0)), vec3(1.0 / gamma));
}

// === VERTEX SHADER (MANTENER SIMPLE) ===
void vertex() {
    // Mantener la geometría sin cambios - IGUAL QUE EL SHADER ORIGINAL
}

// === FRAGMENT SHADER (BASADO EN EL SHADER SIMPLE QUE FUNCIONA) ===
void fragment() {
    // === PASO 1: PIXELIZACIÓN BÁSICA (IGUAL QUE pixelize_spatial.gdshader) ===
    vec2 texture_size = vec2(textureSize(main_texture, 0));

    // Calcular coordenadas pixelizadas EXACTAMENTE como el shader original
    vec2 pixel_coord = UV * texture_size;
    vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_coord / texture_size;

    // Obtener el color de la textura
    vec4 color = texture(main_texture, pixelated_uv);

    // Aplicar base_color si se especifica
    color *= base_color;

    // === PASO 2: DITHERING (IGUAL QUE EL SHADER ORIGINAL) ===
    if (enable_dithering) {
        ivec2 dither_pos = ivec2(mod(pixel_coord, 4.0));
        float dither_value = dither_matrix[dither_pos.x][dither_pos.y];
        // Aplicar dithering al color antes de la cuantización - IGUAL QUE ORIGINAL
        vec3 dithered = color.rgb + (dither_value - 0.5) * dither_strength;
        color.rgb = clamp(dithered, 0.0, 1.0);
    }

    // === PASO 3: REDUCCIÓN DE COLORES (IGUAL QUE EL SHADER ORIGINAL) ===
    if (reduce_colors) {
        color.rgb = quantize_color(color.rgb, float(color_levels));
    }

    // === PASO 4: EFECTOS AVANZADOS OPCIONALES (NUEVOS, PERO SIMPLES) ===

    // Aplicar contraste solo si está habilitado
    if (contrast_enabled && contrast_boost != 1.0) {
        color.rgb = adjust_contrast(color.rgb, contrast_boost);
    }

    // Aplicar saturación solo si está habilitada
    if (saturation_enabled && saturation_mult != 1.0) {
        color.rgb = adjust_saturation(color.rgb, saturation_mult);
    }

    // Aplicar tinte solo si está habilitado
    if (tint_enabled && color_tint != vec4(1.0, 1.0, 1.0, 1.0)) {
        color.rgb *= color_tint.rgb;
    }

    // Aplicar corrección gamma solo si está habilitada
    if (gamma_enabled && gamma_value != 1.0) {
        color.rgb = apply_gamma(color.rgb, gamma_value);
    }

    // === RESULTADO FINAL ===
    ALBEDO = color.rgb;
    ALPHA = color.a;
}