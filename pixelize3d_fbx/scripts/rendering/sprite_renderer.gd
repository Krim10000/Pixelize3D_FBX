# scripts/rendering/sprite_renderer.gd
# Versión completa y corregida

extends Node3D

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)
signal preview_updated(texture: ViewportTexture)

@onready var viewport: SubViewport = $SubViewport
@onready var camera_controller = $SubViewport/CameraController

# Referencias para UI
var preview_texture_rect: TextureRect
var preview_status_label: Label

var render_settings: Dictionary
var current_model: Node3D
var frames_buffer: Array = []

# Estado del renderizado
var is_rendering: bool = false
var current_animation: String = ""
var current_direction: int = 0
var current_frame: int = 0
var total_frames: int = 0

# Estado del preview
var preview_active: bool = false
var preview_paused: bool = false
var ui_controller = null

func _ready():
	_setup_viewport()
	_setup_render_environment()
	_connect_to_ui()
	
	# Inicializar referencias a los elementos UI
	preview_texture_rect = _find_node_by_name(get_tree().root, "PreviewTextureRect")
	preview_status_label = _find_node_by_name(get_tree().root, "PreviewStatusLabel")

func _setup_viewport():
	"""Configurar SubViewport para renderizado de sprites con correcciones críticas"""
	print("🔧 CONFIGURANDO VIEWPORT CON CORRECCIONES")
	
	if not viewport:
		print("❌ ERROR: SubViewport no encontrado en la escena")
		return
	
	# Configuración del viewport
	viewport.size = Vector2i(512, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	viewport.snap_2d_transforms_to_pixel = false
	viewport.physics_object_picking = false
	
	print("✅ Viewport configurado: %s, transparent: %s" % [viewport.size, viewport.transparent_bg])
	
	# Verificar camera controller
	if not camera_controller:
		print("❌ ADVERTENCIA: CameraController no encontrado")
		camera_controller = load("res://scripts/rendering/camera_controller.gd").new()
		viewport.add_child(camera_controller)
		print("✅ CameraController creado automáticamente")

func _setup_render_environment():
	"""Configurar ambiente de renderizado optimizado para pixel art"""
	print("🌟 CONFIGURANDO AMBIENTE DE RENDERIZADO")
	
	# Crear ambiente optimizado
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 0.4
	
	# Desactivar efectos
	env.glow_enabled = false
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	
	# Configurar tonemapping
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	
	# Aplicar ambiente a la cámara
	var camera = camera_controller.get_camera()
	if camera:
		camera.environment = env
		print("✅ Ambiente aplicado a la cámara")
	else:
		print("❌ No se pudo aplicar ambiente - cámara no encontrada")

func _connect_to_ui():
	"""Establecer conexión con UIController"""
	print("🔗 CONECTANDO CON UI CONTROLLER")
	
	# Buscar UIController en la escena
	var main_scene = get_tree().current_scene
	ui_controller = main_scene.get_node_or_null("UIController")
	
	if ui_controller:
		print("✅ UIController encontrado: %s" % ui_controller.name)
	else:
		print("❌ UIController no encontrado - Preview no se conectará con UI")

func initialize(settings: Dictionary):
	"""Inicializar renderer con configuraciones"""
	render_settings = settings
	
	# Configurar tamaño del viewport
	var sprite_size = settings.get("sprite_size", 512)
	viewport.size = Vector2i(sprite_size, sprite_size)
	
	# Configurar cámara
	if camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings({
			"camera_angle": settings.get("camera_angle", 45.0),
			"camera_height": settings.get("camera_height", 10.0),
			"camera_distance": settings.get("camera_distance", 8.0)
		})
	
	print("🔧 SpriteRenderer inicializado con configuraciones: %s" % str(settings))

func setup_preview(model: Node3D = null):
	"""Configurar preview con correcciones para visualización"""
	print("🎬 CONFIGURANDO PREVIEW CON CORRECCIONES")
	
	preview_active = true
	preview_paused = false
	
	# Limpiar modelo anterior
	if current_model and current_model != model:
		print("🧹 Limpiando modelo anterior: %s" % current_model.name)
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		current_model.queue_free()
		await get_tree().process_frame
	
	# Verificar si tenemos modelo
	if model == null:
		print("❌ No se proporcionó modelo para preview")
		return
	
	# Mostrar modelo
	current_model = model
	viewport.add_child(current_model)
	print("✅ Modelo añadido: %s" % current_model.name)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	print("📐 Bounds calculados: %s" % str(bounds))
	
	# Configurar iluminación
	_setup_enhanced_lighting()
	
	# Activar controles de cámara
	print("🎬 HABILITANDO PREVIEW MODE EN CÁMARA")
	camera_controller.enable_preview_mode()
	
	# Configurar animación
	_setup_animation_with_controls()
	
	# Forzar renderizado inicial
	await _force_viewport_render()
	
	# Actualizar preview UI
	update_preview_display(viewport.get_texture())
	
	print("🎬 PREVIEW CONFIGURADO EXITOSAMENTE")

func _setup_enhanced_lighting():
	"""Configurar iluminación visible y funcional"""
	print("💡 CONFIGURANDO ILUMINACIÓN MEJORADA")
	
	var existing_lights = _find_lights_in_viewport()
	
	if existing_lights.size() == 0:
		print("  ⚠️ Creando iluminación de emergencia")
		
		# Luz principal
		var main_light = DirectionalLight3D.new()
		main_light.name = "FillLight"
		main_light.light_energy = 2.5
		main_light.light_color = Color(1.0, 1.0, 1.0)
		main_light.position = Vector3(5, 10, 5)
		main_light.rotation_degrees = Vector3(-45, -30, 0)
		main_light.shadow_enabled = true
		main_light.shadow_blur = 0.5
		viewport.add_child(main_light)
		
		# Luz de relleno
		var fill_light = DirectionalLight3D.new()
		fill_light.name = "RimLight"
		fill_light.light_energy = 1.2
		fill_light.light_color = Color(0.9, 0.95, 1.0)
		fill_light.position = Vector3(-3, 8, -3)
		fill_light.rotation_degrees = Vector3(-30, 120, 0)
		fill_light.shadow_enabled = false
		viewport.add_child(fill_light)
		
		# Luz ambiental
		var ambient_light = OmniLight3D.new()
		ambient_light.name = "AmbientLight"
		ambient_light.light_energy = 0.8
		ambient_light.light_color = Color(1.0, 1.0, 1.0)
		ambient_light.position = Vector3(0, 5, 0)
		ambient_light.omni_range = 20.0
		ambient_light.shadow_enabled = false
		viewport.add_child(ambient_light)
		
		print("  ✅ Iluminación creada (3 luces)")
	else:
		print("  ✅ Luces existentes: %d" % existing_lights.size())
		for light in existing_lights:
			if light.name.contains("FillLight"):
				light.light_energy = 1.5
				print("    🔆 Energía de FillLight aumentada a 1.5")
			elif light.name.contains("RimLight"):
				light.light_energy = 1.5
				print("    🔆 Energía de RimLight aumentada a 1.5")

func _find_lights_in_viewport() -> Array:
	"""Buscar luces existentes en el viewport"""
	var lights = []
	_search_lights_recursive(viewport, lights)
	return lights

func _search_lights_recursive(node: Node, lights: Array):
	"""Búsqueda recursiva de luces"""
	if node is Light3D:
		lights.append(node)
	
	for child in node.get_children():
		_search_lights_recursive(child, lights)

func ensure_animation_updates():
	"""Asegurar que la animación se actualice correctamente"""
	if not current_model:
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		return
	
	if anim_player.is_playing():
		var current_pos = anim_player.current_animation_position
		var current_anim_name = anim_player.current_animation
		anim_player.seek(current_pos, true)
		
		var skeleton = current_model.get_node_or_null("Skeleton3D_combined")
		if skeleton:
			skeleton.force_update_all_bone_transforms()

func _setup_animation_with_controls():
	"""Configurar animación con controles de reproducción"""
	print("🎮 CONFIGURANDO ANIMACIÓN CON CONTROLES")
	
	if not current_model:
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		print("❌ No se encontró AnimationPlayer")
		return
	
	if anim_player.get_animation_list().size() == 0:
		print("❌ No hay animaciones disponibles")
		return
	
	# Configurar primera animación
	var first_anim = anim_player.get_animation_list()[0]
	current_animation = first_anim
	
	var anim = anim_player.get_animation(first_anim)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
		print("🔄 Animación configurada para loop: %s (%.2fs)" % [first_anim, anim.length])
	
	# Conectar signal
	if not anim_player.is_connected("animation_changed", _on_animation_frame_changed):
		anim_player.animation_changed.connect(_on_animation_frame_changed)
	
	# Reproducir animación
	anim_player.play(first_anim)
	print("▶️ Animación iniciada: %s" % first_anim)
	
	# Crear timer para actualizaciones
	_create_skeleton_update_timer()

func _create_skeleton_update_timer():
	"""Crear timer para actualizaciones del skeleton"""
	var skeleton_timer = Timer.new()
	skeleton_timer.name = "SkeletonUpdateTimer"
	skeleton_timer.wait_time = 1.0 / 60.0
	skeleton_timer.autostart = true
	skeleton_timer.timeout.connect(_force_skeleton_update)
	add_child(skeleton_timer)
	print("⚡ Timer de skeleton creado a 60 FPS")

func _force_skeleton_update():
	"""Forzar actualización del skeleton cada frame"""
	if not current_model or not preview_active:
		return
	
	var skeleton = current_model.get_node_or_null("Skeleton3D_combined")
	if skeleton:
		skeleton.force_update_all_bone_transforms()
		
		for child in skeleton.get_children():
			if child is MeshInstance3D:
				child.force_update_transform()
	
	# Actualizar preview cada 2 frames
	if preview_active and not preview_paused and Engine.get_frames_drawn() % 2 == 0:
		update_preview_display(viewport.get_texture())

func _on_animation_frame_changed():
	"""Callback cuando la animación cambia de frame"""
	ensure_animation_updates()

func _force_viewport_render():
	"""Forzar renderizado inmediato del viewport"""
	if not viewport:
		return
	
	ensure_animation_updates()
	await get_tree().process_frame
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame

func update_preview_display(texture: ViewportTexture):
	"""Actualizar la visualización del preview en tiempo real"""
	if not texture:
		return
	
	if preview_texture_rect:
		var current_image = texture.get_image()
		if current_image:
			var image_texture = ImageTexture.new()
			image_texture.create_from_image(current_image)
			preview_texture_rect.texture = image_texture
			
			# Ocultar mensaje de "no preview"
			var no_preview_label = _find_node_by_name(get_tree().root, "NoPreviewLabel")
			if no_preview_label:
				no_preview_label.visible = false
		else:
			preview_texture_rect.texture = texture
	
	if preview_status_label and preview_status_label.text != "🎬 Preview activo - Animación en tiempo real":
		preview_status_label.text = "🎬 Preview activo - Animación en tiempo real"
		preview_status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))

func _find_node_by_name(root: Node, name: String) -> Node:
	"""Buscar nodo recursivamente por nombre"""
	if root.get_name() == name:
		return root
	
	for child in root.get_children():
		var result = _find_node_by_name(child, name)
		if result:
			return result
	
	return null

# CONTROLES DE PREVIEW
func _on_preview_play():
	"""Callback para botón play"""
	print("▶️ PREVIEW PLAY")
	preview_paused = false
	
	if current_model:
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player and current_animation != "":
			anim_player.play(current_animation)
			print("✅ Animación reanudada")

func _on_preview_pause():
	"""Callback para botón pause"""
	print("⏸️ PREVIEW PAUSE")
	preview_paused = true
	
	if current_model:
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.pause()
			print("✅ Animación pausada")

func stop_preview():
	"""Detener preview"""
	print("⏹️ DETENIENDO PREVIEW")
	preview_active = false
	preview_paused = false
	
	if camera_controller.has_method("disable_preview_mode"):
		camera_controller.disable_preview_mode()
	
	if current_model:
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.stop()
		
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		
		current_model = null
	
	print("✅ Preview detenido completamente")

# FUNCIONES DE RENDERIZADO
func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int):
	"""Renderizar animación completa"""
	if is_rendering:
		push_warning("Ya hay un renderizado en proceso")
		return
	
	print("🎬 INICIANDO RENDERIZADO: %s (ángulo: %.1f°)" % [animation_name, angle])
	
	is_rendering = true
	current_animation = animation_name
	current_direction = direction_index
	current_frame = 0
	
	# Preparar modelo
	if current_model and current_model.get_parent() == viewport:
		viewport.remove_child(current_model)
		current_model.queue_free()
	
	current_model = model
	viewport.add_child(current_model)
	
	# Configurar cámara
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	camera_controller.set_rotation_angle(angle)
	
	# Obtener información de animación
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		var fps = render_settings.get("fps", 24)
		total_frames = int(anim.length * fps)
		
		print("📊 Frames a renderizar: %d (%.2fs @ %dfps)" % [total_frames, anim.length, fps])
		_render_next_frame()
	else:
		total_frames = 1
		_render_static_frame()

func _render_next_frame():
	"""Renderizar siguiente frame de la animación"""
	if current_frame >= total_frames:
		is_rendering = false
		emit_signal("animation_complete", current_animation)
		print("✅ Renderizado completo: %s" % current_animation)
		return
	
	# Preparar modelo para el frame actual
	var anim_manager = get_node("/root/main/AnimationManager")
	if anim_manager and anim_manager.has_method("prepare_model_for_rendering"):
		anim_manager.prepare_model_for_rendering(current_model, current_frame, total_frames, current_animation)
	
	await get_tree().process_frame
	await _force_viewport_render()
	
	# Capturar imagen
	var image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	# Emitir frame renderizado
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": camera_controller.pivot_node.rotation_degrees.y if "pivot_node" in camera_controller else 0.0,
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	emit_signal("rendering_progress", current_frame + 1, total_frames)
	
	current_frame += 1
	call_deferred("_render_next_frame")

func _render_static_frame():
	"""Renderizar frame estático"""
	await get_tree().process_frame
	await _force_viewport_render()
	
	var image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": 0,
		"angle": 0.0,
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	is_rendering = false
	emit_signal("animation_complete", current_animation)

func _apply_pixelization(image: Image) -> Image:
	"""Aplicar efecto de pixelización"""
	var original_size = image.get_size()
	var pixel_size = render_settings.get("pixel_scale", 4)
	
	# Reducir tamaño
	var small_size = original_size / pixel_size
	image.resize(small_size.x, small_size.y, Image.INTERPOLATE_NEAREST)
	
	# Reducir paleta si es necesario
	if render_settings.get("reduce_colors", false):
		_reduce_color_palette(image, render_settings.get("color_count", 16))
	
	# Volver al tamaño original
	image.resize(original_size.x, original_size.y, Image.INTERPOLATE_NEAREST)
	
	return image

func _reduce_color_palette(image: Image, color_count: int):
	"""Reducir paleta de colores"""
	var width = image.get_width()
	var height = image.get_height()
	
	for y in range(height):
		for x in range(width):
			var color = image.get_pixel(x, y)
			var steps = float(color_count)
			color.r = round(color.r * steps) / steps
			color.g = round(color.g * steps) / steps
			color.b = round(color.b * steps) / steps
			image.set_pixel(x, y, color)

func _calculate_model_bounds(model: Node3D) -> AABB:
	"""Calcular bounds del modelo"""
	var combined_aabb = AABB()
	var first = true
	
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
	"""Encontrar todas las instancias de mesh"""
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_mesh_instances(child))
	
	return meshes

func update_camera_settings(settings: Dictionary):
	"""Actualizar configuraciones de cámara"""
	camera_controller.set_camera_settings(settings)

# FUNCIONES PÚBLICAS
func get_viewport_texture() -> ViewportTexture:
	"""Obtener textura actual del viewport"""
	return viewport.get_texture()

func is_preview_active() -> bool:
	"""Verificar si el preview está activo"""
	return preview_active

func is_preview_paused() -> bool:
	"""Verificar si el preview está pausado"""
	return preview_paused
