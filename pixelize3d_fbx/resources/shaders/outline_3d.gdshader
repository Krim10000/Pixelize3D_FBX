// resources/shaders/outline_3d.gdshader
// Shader especializado para crear outline 3D real usando expansión de vértices
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, depth_test_disabled;

// Parámetros del outline
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.1, 0.001) = 0.01;
uniform bool outline_pixelated = true;
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;

void vertex() {
    // Expandir vértices hacia afuera usando las normales
    vec3 expanded_position = VERTEX + NORMAL * outline_thickness;

    // Aplicar las transformaciones normales
    VERTEX = expanded_position;
}

void fragment() {
    vec3 final_color = outline_color.rgb;

    // Aplicar pixelización al color del outline si está habilitado
    if (outline_pixelated) {
        // Pixelizar las coordenadas de pantalla para que el outline también se vea pixelado
        vec2 screen_size = vec2(1024.0, 1024.0); // Tamaño de referencia
        vec2 pixel_coord = SCREEN_UV * screen_size;
        vec2 pixelated_coord = floor(pixel_coord / pixel_size) * pixel_size;

        // Crear variación sutil en el color del outline basada en la posición pixelada
        float variation = sin(pixelated_coord.x * 0.1) * sin(pixelated_coord.y * 0.1) * 0.05;
        final_color = mix(final_color, final_color * 0.9, variation);
    }

    ALBEDO = final_color;
    ALPHA = outline_color.a;
}