# scripts/rendering/sprite_renderer.gd
extends Node3D

# Input: Modelo 3D combinado con animaciones y configuración de renderizado
# Output: Frames renderizados para cada dirección y animación

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)

@onready var viewport: SubViewport = $SubViewport
@onready var camera_controller = $SubViewport/CameraController

var render_settings: Dictionary
var current_model: Node3D
var frames_buffer: Array = []

# Estado del renderizado
var is_rendering: bool = false
var current_animation: String = ""
var current_direction: int = 0
var current_frame: int = 0
var total_frames: int = 0

func _ready():
	_setup_viewport()
	_setup_render_environment()

func _setup_viewport():
	# Crear SubViewport si no existe
	if not viewport:
		viewport = SubViewport.new()
		viewport.name = "SubViewport"
		add_child(viewport)
	
	# Configurar viewport para renderizado de sprites
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.transparent_bg = true
	
	# Crear camera controller si no existe
	if not camera_controller:
		camera_controller = preload("res://scripts/rendering/camera_controller.gd").new()
		viewport.add_child(camera_controller)

func _setup_render_environment():
	# Configurar ambiente de renderizado
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 0.3
	
	# Desactivar efectos no deseados para pixel art
	env.glow_enabled = false
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	
	# Configurar tonemapping para colores precisos
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	# Aplicar ambiente
	var camera = camera_controller.get_camera()
	if camera:
		camera.environment = env

func initialize(settings: Dictionary):
	render_settings = settings
	
	# Configurar tamaño del viewport
	viewport.size = Vector2i(settings.sprite_size, settings.sprite_size)
	
	# Configurar cámara
	camera_controller.set_camera_settings({
		"camera_angle": settings.camera_angle,
		"camera_height": settings.camera_height,
		"camera_distance": settings.camera_distance
	})

func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int):
	if is_rendering:
		push_warning("Ya hay un renderizado en proceso")
		return
	
	is_rendering = true
	current_animation = animation_name
	current_direction = direction_index
	current_frame = 0
	
	# Limpiar modelo anterior si existe
	if current_model and current_model.get_parent() == viewport:
		viewport.remove_child(current_model)
		current_model.queue_free()
	
	# Añadir nuevo modelo al viewport
	current_model = model
	viewport.add_child(current_model)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	camera_controller.set_rotation_angle(angle)
	
	# Obtener información de la animación
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		var fps = render_settings.fps
		total_frames = int(anim.length * fps)
		
		# Iniciar renderizado de frames
		_render_next_frame()
	else:
		# Si no hay animación, renderizar un solo frame
		total_frames = 1
		_render_static_frame()

func _render_next_frame():
	if current_frame >= total_frames:
		# Animación completa para esta dirección
		is_rendering = false
		emit_signal("animation_complete", current_animation)
		return
	
	# Preparar el modelo para el frame actual
	var anim_manager = get_node("/root/Main/AnimationManager")
	anim_manager.prepare_model_for_rendering(
		current_model,
		current_frame,
		total_frames,
		current_animation
	)
	
	# Esperar un frame para que se actualice la pose
	await get_tree().process_frame
	
	# Renderizar el frame
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	# Capturar la imagen
	var image = viewport.get_texture().get_image()
	
	# Aplicar pixelización si es necesario
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	# Emitir frame renderizado
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": camera_controller.pivot_node.rotation_degrees.y,
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	emit_signal("rendering_progress", current_frame + 1, total_frames)
	
	# Continuar con el siguiente frame
	current_frame += 1
	call_deferred("_render_next_frame")

func _render_static_frame():
	# Para modelos sin animación
	await get_tree().process_frame
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	var image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": 0,
		"angle": camera_controller.pivot_node.rotation_degrees.y,
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	is_rendering = false
	emit_signal("animation_complete", current_animation)

func _apply_pixelization(image: Image) -> Image:
	# Aplicar efecto de pixelización
	var original_size = image.get_size()
	var pixel_size = render_settings.get("pixel_scale", 4)
	
	# Reducir tamaño
	var small_size = original_size / pixel_size
	image.resize(small_size.x, small_size.y, Image.INTERPOLATE_NEAREST)
	
	# Opcional: Reducir paleta de colores
	if render_settings.get("reduce_colors", false):
		_reduce_color_palette(image, render_settings.get("color_count", 16))
	
	# Volver al tamaño original
	image.resize(original_size.x, original_size.y, Image.INTERPOLATE_NEAREST)
	
	return image

func _reduce_color_palette(image: Image, color_count: int):
	# Implementación simple de reducción de paleta
	# En una implementación completa, usarías algoritmos como k-means
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var color = image.get_pixel(x, y)
			# Cuantizar cada canal de color
			var steps = float(color_count)
			color.r = round(color.r * steps) / steps
			color.g = round(color.g * steps) / steps
			color.b = round(color.b * steps) / steps
			image.set_pixel(x, y, color)

func _calculate_model_bounds(model: Node3D) -> AABB:
	var combined_aabb = AABB()
	var first = true
	
	# Buscar todos los MeshInstance3D en el modelo
	var mesh_instances = _find_all_mesh_instances(model)
	
	for mesh_inst in mesh_instances:
		if mesh_inst.mesh:
			var mesh_aabb = mesh_inst.mesh.get_aabb()
			var global_aabb = mesh_inst.global_transform * mesh_aabb
			
			if first:
				combined_aabb = global_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(global_aabb)
	
	return combined_aabb

func _find_all_mesh_instances(node: Node) -> Array:
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_mesh_instances(child))
	
	return meshes

func update_camera_settings(settings: Dictionary):
	camera_controller.set_camera_settings(settings)

# Función para preview en tiempo real
func setup_preview(model: Node3D):
	if current_model and current_model != model:
		current_model.queue_free()
	
	current_model = model
	viewport.add_child(current_model)
	
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	camera_controller.enable_preview_mode()

func stop_preview():
	camera_controller.disable_preview_mode()
	if current_model:
		viewport.remove_child(current_model)
