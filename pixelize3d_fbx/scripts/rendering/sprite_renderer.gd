# scripts/rendering/sprite_renderer.gd
# Input: Modelo 3D combinado con animaciones y configuración de renderizado desde AnimationManager
# Output: Frames renderizados para cada dirección y animación, preview funcional en UI

extends Node3D

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)
signal preview_updated(texture: ViewportTexture)

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

# Estado del preview
var preview_active: bool = false
var preview_paused: bool = false
var ui_controller = null

func _ready():
	_setup_viewport()
	_setup_render_environment()
	_connect_to_ui()

func _setup_viewport():
	"""Configurar SubViewport para renderizado de sprites con correcciones críticas"""
	print("🔧 CONFIGURANDO VIEWPORT CON CORRECCIONES")
	
	if not viewport:
		print("❌ ERROR: SubViewport no encontrado en la escena")
		return
	
	# CORRECCIÓN CRÍTICA 1: Configuración correcta del viewport
	viewport.size = Vector2i(512, 512)  # Tamaño fijo para consistencia
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # Forzar actualización continua
	viewport.transparent_bg = true
	viewport.snap_2d_transforms_to_pixel = false  # Evitar pixelización no deseada
	viewport.physics_object_picking = false  # Desactivar picking para performance
	
	# CORRECCIÓN CRÍTICA 2: Forzar que el viewport esté activo
	viewport.set_update_mode(SubViewport.UPDATE_ALWAYS)
	
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
	
	# Desactivar efectos que interfieren con pixel art
	env.glow_enabled = false
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	
	# Configurar tonemapping para colores precisos
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
	"""CORRECCIÓN CRÍTICA: Establecer conexión con UIController"""
	print("🔗 CONECTANDO CON UI CONTROLLER")
	
	# Buscar UIController en la escena
	var main_scene = get_tree().current_scene
	ui_controller = main_scene.get_node_or_null("UIController")
	
	if ui_controller:
		print("✅ UIController encontrado: %s" % ui_controller.name)
		
		# Conectar señales para controles de preview
		if ui_controller.has_signal("preview_play_requested"):
			ui_controller.preview_play_requested.connect(_on_preview_play)
		if ui_controller.has_signal("preview_pause_requested"):
			ui_controller.preview_pause_requested.connect(_on_preview_pause)
			
		# Enviar textura del viewport al UI
		call_deferred("_send_viewport_texture_to_ui")
	else:
		print("❌ UIController no encontrado - Preview no se conectará con UI")

func _send_viewport_texture_to_ui():
	"""CORRECCIÓN CRÍTICA: Enviar textura del viewport al UIController"""
	print("📺 ENVIANDO TEXTURA A UI CONTROLLER")
	
	if not ui_controller:
		print("❌ No hay UIController para enviar textura")
		return
	
	# Forzar renderizado del viewport
	await _force_viewport_render()
	
	var viewport_texture = viewport.get_texture()
	if viewport_texture:
		print("✅ Textura obtenida del viewport: %s" % str(viewport_texture.get_size()))
		
		# Verificar si UIController tiene método para recibir textura
		if ui_controller.has_method("set_preview_texture"):
			ui_controller.set_preview_texture(viewport_texture)
			print("✅ Textura enviada a UIController.set_preview_texture()")
		else:
			print("❌ UIController no tiene método set_preview_texture()")
			
		# Emitir señal con textura
		emit_signal("preview_updated", viewport_texture)
	else:
		print("❌ No se pudo obtener textura del viewport")

func _force_viewport_render():
	"""Forzar renderizado inmediato del viewport"""
	print("🔄 FORZANDO RENDERIZADO DEL VIEWPORT")
	
	# Múltiples métodos para forzar renderizado
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
	
	# Forzar actualización del RenderingServer
	RenderingServer.force_sync()
	await RenderingServer.frame_post_draw
	
	print("✅ Renderizado forzado completado")

func initialize(settings: Dictionary):
	"""Inicializar renderer con configuraciones"""
	render_settings = settings
	
	# Configurar tamaño del viewport desde settings
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

# FUNCIÓN CORREGIDA: Setup preview con correcciones críticas
func setup_preview(model: Node3D = null, debug_mode: bool = false):
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
	
	# Limpiar objetos de debug previos
	_clear_debug_test_objects()
	
	# MODO DEBUG: Solo objetos de prueba
	if debug_mode or model == null:
		print("🔴 MODO DEBUG ACTIVADO")
		_create_debug_test_objects()
		_setup_emergency_lighting()
		camera_controller.enable_preview_mode()
		
		# CORRECCIÓN: Forzar renderizado y envío a UI
		await _force_viewport_render()
		call_deferred("_send_viewport_texture_to_ui")
		
		print("🔴 OBJETOS DEBUG: Esfera ROJA, Cubo VERDE, Cilindro AZUL")
		return
	
	# MODO NORMAL: Mostrar modelo
	current_model = model
	viewport.add_child(current_model)
	print("✅ Modelo añadido: %s" % current_model.name)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	camera_controller.setup_for_model(bounds)
	print("📐 Bounds calculados: %s" % str(bounds))
	
	# Configurar iluminación
	_setup_emergency_lighting()
	
	# Activar controles de cámara
	camera_controller.enable_preview_mode()
	
	# Iniciar animación si existe
	_start_preview_animation_with_controls()
	
	# CORRECCIÓN CRÍTICA: Forzar renderizado y envío a UI
	await _force_viewport_render()
	call_deferred("_send_viewport_texture_to_ui")
	
	# Debug del setup
	_debug_preview_setup()
	
	print("🎬 PREVIEW CONFIGURADO EXITOSAMENTE")

func _start_preview_animation_with_controls():
	"""Iniciar animación con controles de play/pause"""
	print("🎮 CONFIGURANDO ANIMACIÓN CON CONTROLES")
	
	if not current_model:
		print("❌ No hay modelo para animar")
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
	
	# Reproducir animación
	anim_player.play(first_anim)
	print("▶️ Animación iniciada: %s" % first_anim)

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

func toggle_preview_playback():
	"""Toggle entre play y pause"""
	if preview_paused:
		_on_preview_play()
	else:
		_on_preview_pause()

# FUNCIÓN CORREGIDA: Objetos de debug con materiales más visibles
func _create_debug_test_objects():
	"""Crear objetos de prueba más visibles"""
	print("🔴 CREANDO OBJETOS DEBUG MEJORADOS")
	
	# Esfera roja brillante
	var test_sphere = MeshInstance3D.new()
	test_sphere.name = "DEBUG_TestSphere"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	sphere_mesh.height = 1.6
	test_sphere.mesh = sphere_mesh
	
	var sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color.RED
	sphere_material.emission_enabled = true
	sphere_material.emission = Color(0.8, 0.0, 0.0)
	sphere_material.emission_energy = 2.0
	sphere_material.roughness = 0.1
	sphere_material.metallic = 0.0
	test_sphere.set_surface_override_material(0, sphere_material)
	
	test_sphere.position = Vector3(0, 1, 0)
	viewport.add_child(test_sphere)
	print("  ✅ Esfera ROJA creada en %s" % str(test_sphere.position))
	
	# Cubo verde brillante
	var test_cube = MeshInstance3D.new()
	test_cube.name = "DEBUG_TestCube"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.8, 0.8)
	test_cube.mesh = box_mesh
	
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color.GREEN
	cube_material.emission_enabled = true
	cube_material.emission = Color(0.0, 0.8, 0.0)
	cube_material.emission_energy = 2.0
	cube_material.roughness = 0.1
	test_cube.set_surface_override_material(0, cube_material)
	
	test_cube.position = Vector3(2, 0.5, 0)
	viewport.add_child(test_cube)
	print("  ✅ Cubo VERDE creado en %s" % str(test_cube.position))
	
	# Cilindro azul brillante
	var test_cylinder = MeshInstance3D.new()
	test_cylinder.name = "DEBUG_TestCylinder"
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 1.5
	cylinder_mesh.top_radius = 0.4
	cylinder_mesh.bottom_radius = 0.4
	test_cylinder.mesh = cylinder_mesh
	
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color.BLUE
	cylinder_material.emission_enabled = true
	cylinder_material.emission = Color(0.0, 0.0, 0.8)
	cylinder_material.emission_energy = 2.0
	cylinder_material.roughness = 0.1
	test_cylinder.set_surface_override_material(0, cylinder_material)
	
	test_cylinder.position = Vector3(-2, 0.75, 0)
	viewport.add_child(test_cylinder)
	print("  ✅ Cilindro AZUL creado en %s" % str(test_cylinder.position))
	
	# Configurar cámara para ver objetos
	var debug_bounds = AABB(Vector3(-3, 0, -2), Vector3(6, 3, 4))
	camera_controller.setup_for_model(debug_bounds)
	
	print("🔴 OBJETOS DEBUG CREADOS Y CONFIGURADOS")

func _clear_debug_test_objects():
	"""Limpiar objetos de debug"""
	var objects_to_remove = []
	
	for child in viewport.get_children():
		if child.name.begins_with("DEBUG_Test"):
			objects_to_remove.append(child)
	
	for obj in objects_to_remove:
		viewport.remove_child(obj)
		obj.queue_free()

# FUNCIÓN CORREGIDA: Iluminación de emergencia más intensa
func _setup_emergency_lighting():
	"""Configurar iluminación visible y funcional"""
	print("💡 CONFIGURANDO ILUMINACIÓN MEJORADA")
	
	var existing_lights = _find_lights_in_viewport()
	
	if existing_lights.size() == 0:
		print("  ⚠️ Creando iluminación de emergencia")
		
		# Luz principal más intensa
		var main_light = DirectionalLight3D.new()
		main_light.name = "EmergencyMainLight"
		main_light.light_energy = 2.5
		main_light.light_color = Color(1.0, 1.0, 1.0)
		main_light.position = Vector3(5, 10, 5)
		main_light.rotation_degrees = Vector3(-45, -30, 0)
		main_light.shadow_enabled = true
		main_light.shadow_blur = 0.5
		viewport.add_child(main_light)
		
		# Luz de relleno
		var fill_light = DirectionalLight3D.new()
		fill_light.name = "EmergencyFillLight"
		fill_light.light_energy = 1.2
		fill_light.light_color = Color(0.9, 0.95, 1.0)
		fill_light.position = Vector3(-3, 8, -3)
		fill_light.rotation_degrees = Vector3(-30, 120, 0)
		fill_light.shadow_enabled = false
		viewport.add_child(fill_light)
		
		# Luz ambiental adicional
		var ambient_light = OmniLight3D.new()
		ambient_light.name = "EmergencyAmbientLight"
		ambient_light.light_energy = 0.8
		ambient_light.light_color = Color(1.0, 1.0, 1.0)
		ambient_light.position = Vector3(0, 5, 0)
		ambient_light.omni_range = 20.0
		ambient_light.shadow_enabled = false
		viewport.add_child(ambient_light)
		
		print("  ✅ Iluminación de emergencia creada (3 luces)")
	else:
		print("  ✅ Luces existentes: %d" % existing_lights.size())
		for light in existing_lights:
			if light.light_energy < 1.0:
				light.light_energy = 1.5  # Aumentar energía
				print("    🔆 Energía de %s aumentada a %.1f" % [light.name, light.light_energy])

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

# FUNCIONES DE DEBUG MEJORADAS
func _debug_preview_setup():
	"""Debug completo del estado del preview"""
	print("🔍 DEBUG PREVIEW COMPLETO")
	print("  Current model: %s" % (current_model.name if current_model else "NULL"))
	print("  Viewport size: %s" % str(viewport.size))
	print("  Preview active: %s" % preview_active)
	print("  Preview paused: %s" % preview_paused)
	
	# Debug de la cámara
	var camera = camera_controller.get_camera()
	if camera:
		print("  Cámara: %s en %s" % [camera.name, camera.global_position])
		print("  Mirando hacia: %s" % str(camera_controller.target_position if camera_controller.has_method("get_target_position") else "N/A"))
	
	# Debug del modelo
	if current_model:
		_debug_model_state()
	
	# Debug del viewport
	_debug_viewport_state()

func _debug_model_state():
	"""Debug del estado del modelo"""
	print("  🎭 DEBUG MODELO:")
	print("    Nombre: %s" % current_model.name)
	print("    Posición: %s" % str(current_model.global_position))
	print("    Visible: %s" % current_model.visible)
	
	# Debug del skeleton
	var skeleton = current_model.get_node_or_null("Skeleton3D_combined")
	if skeleton:
		print("    Skeleton: %s (%d huesos)" % [skeleton.name, skeleton.get_bone_count()])
		
		# Debug de meshes
		var mesh_count = 0
		for child in skeleton.get_children():
			if child is MeshInstance3D:
				mesh_count += 1
				print("      Mesh: %s (visible: %s)" % [child.name, child.visible])
		print("    Total meshes: %d" % mesh_count)
	
	# Debug de animación
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player:
		print("    AnimationPlayer: %s" % anim_player.name)
		print("      Animaciones: %s" % str(anim_player.get_animation_list()))
		print("      Actual: %s (playing: %s)" % [anim_player.current_animation, anim_player.is_playing()])

func _debug_viewport_state():
	"""Debug del estado del viewport"""
	print("  📺 DEBUG VIEWPORT:")
	print("    Size: %s" % str(viewport.size))
	print("    Transparent BG: %s" % viewport.transparent_bg)
	print("    Update mode: %s" % viewport.render_target_update_mode)
	print("    Hijos: %d" % viewport.get_child_count())
	
	# Listar hijos
	for child in viewport.get_children():
		print("      - %s (%s)" % [child.name, child.get_class()])
	
	# Debug de textura
	var texture = viewport.get_texture()
	if texture:
		print("    Textura: %s (%s)" % [texture.get_class(), str(texture.get_size())])
	else:
		print("    ❌ Sin textura")

# FUNCIONES DE RENDERIZADO (originales mejoradas)
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
	
	# Preparar modelo para renderizado
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
	var anim_manager = get_node("/root/Main/AnimationManager")
	if anim_manager and anim_manager.has_method("prepare_model_for_rendering"):
		anim_manager.prepare_model_for_rendering(current_model, current_frame, total_frames, current_animation)
	
	await get_tree().process_frame
	
	# Renderizar frame
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
		"angle": camera_controller.pivot_node.rotation_degrees.y if camera_controller.has_method("get_pivot_rotation") else 0.0,
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

# FUNCIONES PÚBLICAS PARA CONTROL EXTERNO
func activate_debug_mode():
	"""Activar modo debug (llamada externa)"""
	print("🔴 ACTIVANDO MODO DEBUG EXTERNO")
	setup_preview(null, true)

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
	
	_clear_debug_test_objects()
	print("✅ Preview detenido completamente")

func get_viewport_texture() -> ViewportTexture:
	"""Obtener textura actual del viewport"""
	return viewport.get_texture()

func get_viewport_image_texture() -> ImageTexture:
	"""Obtener textura del viewport convertida a ImageTexture"""
	var viewport_texture = viewport.get_texture()
	if viewport_texture:
		var image = viewport_texture.get_image()
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	return null

func is_preview_active() -> bool:
	"""Verificar si el preview está activo"""
	return preview_active

func is_preview_paused() -> bool:
	"""Verificar si el preview está pausado"""
	return preview_paused
