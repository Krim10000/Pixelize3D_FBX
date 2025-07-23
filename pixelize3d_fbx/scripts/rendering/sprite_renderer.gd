# sprite_renderer.gd
extends Node3D

# Input: Modelo 3D combinado con animaciones y configuración de renderizado
# Output: Frames renderizados para cada dirección y animación

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal direction_complete(animation_name: String, direction: int)
signal rendering_progress(current: int, total: int)
signal rendering_started(animation_name: String, direction_count: int)

@onready var viewport: SubViewport = $SubViewport
@onready var camera_controller = $SubViewport/CameraController

var render_settings: Dictionary
var current_model: Node3D
var frames_buffer: Array = []

# Estado del renderizado
var is_rendering: bool = false
var should_stop_rendering: bool = false
var current_animation: String = ""
var current_direction: int = 0
var current_frame: int = 0
var total_frames: int = 0
var render_queue: Array = []

# Configuración de direcciones
var direction_count: int = 8
var angle_offset: float = 0.0
var rendered_frames: Dictionary = {}

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
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	viewport.size = Vector2i(512, 512)
	
	# Crear camera controller si no existe
	if not camera_controller:
		camera_controller = preload("res://scripts/rendering/camera_controller.gd").new()
		camera_controller.name = "CameraController"
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
	
	# Configurar direcciones
	direction_count = settings.get("directions", 8)
	angle_offset = settings.get("angle_offset", 0.0)
	
	print("Sprite Renderer inicializado - Tamaño: %dx%d, Direcciones: %d, Offset: %.1f°" % 
		  [settings.sprite_size, settings.sprite_size, direction_count, angle_offset])

func render_animation(model: Node3D, animation_name: String):
	if is_rendering:
		print("WARNING: Ya hay un renderizado en proceso. Añadiendo a cola...")
		render_queue.append({
			"model": model,
			"animation_name": animation_name
		})
		return
	
	# Marcar como ocupado
	is_rendering = true
	should_stop_rendering = false
	current_animation = animation_name
	current_direction = 0  # Empezar por la primera dirección
	current_frame = 0
	
	# Inicializar almacenamiento para esta animación
	rendered_frames[current_animation] = {
		"direction_count": direction_count,
		"frames": []
	}
	
	# Limpiar modelo anterior si existe
	if current_model and current_model.get_parent() == viewport:
		viewport.remove_child(current_model)
	
	# Añadir nuevo modelo al viewport
	current_model = model
	viewport.add_child(current_model)
	
	# Calcular el ángulo para la primera dirección
	var angle = _get_direction_angle(current_direction)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	camera_controller.set_rotation_angle(angle)
	
	# Obtener información de la animación
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		var fps = render_settings.fps
		total_frames = max(1, int(anim.length * fps))
	else:
		# Si no se encuentra la animación, buscar una alternativa
		print("Buscando animación alternativa para: ", animation_name)
		if anim_player:
			var anims = anim_player.get_animation_list()
			if anims.size() > 0:
				var first_anim = anims[0]
				if anim_player.has_animation(first_anim):
					current_animation = first_anim
					var anim = anim_player.get_animation(first_anim)
					var fps = render_settings.fps
					total_frames = max(1, int(anim.length * fps))
					print("Usando animación alternativa: ", first_anim)
				else:
					total_frames = 1
			else:
				total_frames = 1
		else:
			total_frames = 1
	
	print("Iniciando renderizado: %s, %d direcciones, %d frames" % [current_animation, direction_count, total_frames])
	emit_signal("rendering_started", current_animation, direction_count)
	
	# Iniciar renderizado de la primera dirección
	_render_next_frame_in_direction()

func _get_direction_angle(direction_index: int) -> float:
	var angle_step = 360.0 / direction_count
	return direction_index * angle_step + angle_offset

func _render_next_frame_in_direction():
	if should_stop_rendering:
		_finish_direction()
		return
	
	# Verificar si hemos terminado todos los frames de esta dirección
	if current_frame >= total_frames:
		# Emitir señal de dirección completada
		emit_signal("direction_complete", current_animation, current_direction)
		
		# Pasar a la siguiente dirección
		current_direction += 1
		current_frame = 0
		
		# Verificar si hemos terminado todas las direcciones
		if current_direction >= direction_count:
			_finish_rendering()
			return
		
		# Configurar nueva dirección
		var angle = _get_direction_angle(current_direction)
		camera_controller.set_rotation_angle(angle)
		await get_tree().process_frame  # Esperar un frame para que la cámara se actualice
	
	# Preparar el modelo para el frame actual
	var anim_manager = get_node_or_null("/root/Main/AnimationManager")
	if anim_manager:
		anim_manager.prepare_model_for_rendering(
			current_model,
			current_frame,
			total_frames,
			current_animation
		)
	else:
		# Fallback: Usar AnimationPlayer directamente
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			if anim_player.has_animation(current_animation):
				anim_player.play(current_animation)
				var anim = anim_player.get_animation(current_animation)
				var time = (float(current_frame) / float(total_frames)) * anim.length
				anim_player.seek(time, true)
	
	# Esperar un frame para que se actualice la pose
	await get_tree().process_frame
	
	# Forzar renderizado
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	# Capturar la imagen
	var image = viewport.get_texture().get_image()
	
	if not image:
		print("ERROR: No se pudo capturar imagen del viewport")
		_finish_rendering()
		return
	
	# Aplicar pixelización si es necesario
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	# Emitir frame renderizado
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": _get_direction_angle(current_direction),
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	emit_signal("rendering_progress", _calculate_overall_progress(), direction_count * total_frames)
	
	# Almacenar frame
	if not rendered_frames[current_animation].has("dir_%d" % current_direction):
		rendered_frames[current_animation]["dir_%d" % current_direction] = []
	
	rendered_frames[current_animation]["dir_%d" % current_direction].append(image)
	
	# Avanzar al siguiente frame
	current_frame += 1
	call_deferred("_render_next_frame_in_direction")

func _calculate_overall_progress() -> int:
	var frames_per_direction = total_frames
	var completed_directions = current_direction
	var completed_frames_in_current = current_frame
	return (completed_directions * frames_per_direction) + completed_frames_in_current

func _finish_direction():
	# Limpiar y pasar a la siguiente dirección
	current_direction += 1
	current_frame = 0
	if current_direction >= direction_count:
		_finish_rendering()
	else:
		# Configurar nueva dirección
		var angle = _get_direction_angle(current_direction)
		camera_controller.set_rotation_angle(angle)
		call_deferred("_render_next_frame_in_direction")

func _finish_rendering():
	print("Renderizado completado: %s" % current_animation)
	
	# Limpiar modelo del viewport
	if current_model and current_model.get_parent() == viewport:
		viewport.remove_child(current_model)
	
	# Resetear estado
	is_rendering = false
	should_stop_rendering = false
	
	emit_signal("animation_complete", current_animation)
	
	# Procesar siguiente en cola si existe
	if render_queue.size() > 0:
		var next_render = render_queue.pop_front()
		call_deferred("render_animation", next_render.model, next_render.animation_name)

func stop_rendering():
	should_stop_rendering = true
	render_queue.clear()

#func generate_spritesheet(animation_name: String) -> Image:
	#if not rendered_frames.has(animation_name):
		#push_error("No hay frames renderizados para la animación: " + animation_name)
		#return null
	#
	#var anim_data = rendered_frames[animation_name]
	#var direction_count = anim_data.direction_count
	#var frames_per_direction = anim_data.get("dir_0", []).size()
	#
	#if frames_per_direction == 0:
		#push_error("No hay frames para generar el spritesheet")
		#return null
	#
	## Obtener tamaño de frame
	#var frame_size = viewport.size
	#var spritesheet = Image.create(
		#frame_size.x * direction_count,
		#frame_size.y * frames_per_direction,
		#false,
		#Image.FORMAT_RGBA8
	#)
	#
	## Llenar el spritesheet
	#for frame in range(frames_per_direction):
		#for direction in range(direction_count):
			#var dir_key = "dir_%d" % direction
			#if anim_data.has(dir_key) and anim_data[dir_key].size() > frame:
				#var frame_img = anim_data[dir_key][frame]
				#var pos = Vector2i(direction * frame_size.x, frame * frame_size.y)
				#spritesheet.blit_rect(frame_img, Rect2i(Vector2i.ZERO, frame_size), pos)
	#
	#return spritesheet
func generate_spritesheet(animation_name: String) -> Image:
	if not rendered_frames.has(animation_name):
		push_error("No hay frames renderizados para la animación: " + animation_name)
		return null
	
	var anim_data = rendered_frames[animation_name]
	# Cambia el nombre para evitar conflicto con variable de clase
	var anim_direction_count = anim_data.direction_count
	var frames_per_direction = anim_data.get("dir_0", []).size()
	
	if frames_per_direction == 0:
		push_error("No hay frames para generar el spritesheet")
		return null
	
	# Obtener tamaño de frame
	var frame_size = viewport.size
	var spritesheet = Image.create(
		frame_size.x * anim_direction_count,  # Usa el nuevo nombre
		frame_size.y * frames_per_direction,
		false,
		Image.FORMAT_RGBA8
	)
	
	# Llenar el spritesheet
	for frame in range(frames_per_direction):
		for direction in range(anim_direction_count):  # Usa el nuevo nombre
			var dir_key = "dir_%d" % direction
			if anim_data.has(dir_key) and anim_data[dir_key].size() > frame:
				var frame_img = anim_data[dir_key][frame]
				var pos = Vector2i(direction * frame_size.x, frame * frame_size.y)
				spritesheet.blit_rect(frame_img, Rect2i(Vector2i.ZERO, frame_size), pos)
	
	return spritesheet


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

# Función para preview en tiempo real
func setup_preview(model: Node3D, direction: int = 0):
	if is_rendering:
		print("No se puede hacer preview durante renderizado")
		return
	
	if current_model and current_model != model:
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
	
	current_model = model
	viewport.add_child(current_model)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	
	# Configurar dirección
	var angle = _get_direction_angle(direction)
	camera_controller.set_rotation_angle(angle)
	camera_controller.enable_preview_mode()
	
	# Asegurar que el modelo sea visible
	current_model.visible = true
	
	# Forzar un frame de renderizado
	RenderingServer.force_draw()

func stop_preview():
	camera_controller.disable_preview_mode()
	if current_model and not is_rendering:
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
