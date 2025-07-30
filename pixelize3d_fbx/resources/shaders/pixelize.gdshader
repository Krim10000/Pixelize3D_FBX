// resources/shaders/pixelize.gdshader
shader_type spatial;
render_mode unshaded, cull_disabled;

// Parámetros configurables
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;
uniform bool reduce_colors = false;
uniform int color_levels : hint_range(2, 64, 1) = 16;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Función para cuantizar colores
vec3 quantize_color(vec3 color, float levels) {
    return floor(color * levels + 0.5) / levels;
}

void vertex() {
    // Mantener la geometría sin cambios
    POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
    // Obtener las coordenadas de pantalla
    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    vec2 pixel_coord = SCREEN_UV * screen_size;

    // Aplicar pixelización
    vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_coord / screen_size;

    // Obtener el color pixelizado
    vec4 color = texture(screen_texture, pixelated_uv);

    // Aplicar reducción de colores si está activada
    if (reduce_colors) {
        color.rgb = quantize_color(color.rgb, float(color_levels));
    }

    // Aplicar el color final
    ALBEDO = color.rgb;
    ALPHA = color.a;
}

// Versión alternativa para post-procesamiento

uniform float pixel_scale : hint_range(1.0, 16.0, 1.0) = 4.0;
uniform bool enable_dithering = false;
uniform float dither_strength : hint_range(0.0, 1.0, 0.01) = 0.1;

// Matriz de dithering Bayer 4x4
const mat4 dither_matrix = mat4(
    vec4(0.0,  8.0,  2.0, 10.0),
    vec4(12.0, 4.0, 14.0, 6.0),
    vec4(3.0, 11.0,  1.0, 9.0),
    vec4(15.0, 7.0, 13.0, 5.0)
) / 16.0;

void fragment() {
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = vec2(pixel_scale);

    // Calcular posición pixelizada
    vec2 pos = UV * size;
    vec2 pixelated_pos = floor(pos / pixel_size) * pixel_size;
    vec2 pixelated_uv = pixelated_pos / size;

    // Obtener color
    vec4 color = texture(TEXTURE, pixelated_uv);

    // Aplicar dithering si está activado
    if (enable_dithering) {
        ivec2 dither_pos = ivec2(mod(pos, 4.0));
        float dither_value = dither_matrix[dither_pos.x][dither_pos.y];

        // Aplicar dithering al color
        vec3 dithered = color.rgb + (dither_value - 0.5) * dither_strength;
        color.rgb = clamp(dithered, 0.0, 1.0);
    }

    COLOR = color;
}