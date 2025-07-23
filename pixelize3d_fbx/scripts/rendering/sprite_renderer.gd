# scripts/rendering/sprite_renderer.gd
# Input: Modelo 3D combinado con animaciones y configuración de renderizado
# Output: Frames renderizados para cada dirección y animación

extends Node3D

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

# FUNCIÓN MEJORADA para configurar preview con objetos de debug
#func setup_preview(model: Node3D = null, debug_mode: bool = false):
	#print("--- CONFIGURANDO PREVIEW ---")
	#
	#if current_model and current_model != model:
		#print("Limpiando modelo anterior: %s" % current_model.name)
		#if current_model.get_parent() == viewport:
			#viewport.remove_child(current_model)
		#current_model.queue_free()
	#
	## Limpiar objetos de debug previos
	#_clear_debug_test_objects()
	#
	## MODO DEBUG: Solo mostrar objetos de prueba (cuando no hay modelo o modo debug forzado)
	#if debug_mode or model == null:
		#print("🔴 MODO DEBUG ACTIVADO - Mostrando objetos de prueba")
		#_create_debug_test_objects()
		#
		## CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
		#print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
		#_setup_emergency_lighting()
		#
		## ACTIVAR modo preview en camera controller
		#camera_controller.enable_preview_mode()
		#
		#print("✅ Preview mode activado en camera controller")
		#_debug_viewport_rendering()
		#
		#print("🔴 PRUEBA ACTIVADA: Deberías ver Esfera ROJA, Cubo VERDE, Cilindro AZUL")
		#return
	#
	## MODO NORMAL: Mostrar modelo + objetos de prueba para comparación
	#current_model = model
	#viewport.add_child(current_model)
	#
	#print("✅ Modelo añadido al viewport: %s" % current_model.name)
	#
	## Configurar cámara para el modelo
	#var bounds = _calculate_model_bounds(current_model)
	#print("Bounds calculados: %s" % str(bounds))
	#
	#camera_controller.setup_for_model(bounds)
	#
	## CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
	#print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
	#_setup_emergency_lighting()
	#
	## CREAR OBJETOS DE PRUEBA JUNTO AL MODELO para comparación
	#print("🔴 AGREGANDO OBJETOS DE PRUEBA JUNTO AL MODELO")
	#_create_debug_test_objects()
	#
	## ACTIVAR modo preview en camera controller
	#camera_controller.enable_preview_mode()
	#
	#print("✅ Preview mode activado en camera controller")
	#
	## Iniciar animación de preview si existe
	#_start_preview_animation()
	#
	## Debug completo del estado
	#_debug_preview_setup()
	#_debug_viewport_rendering()

#func setup_preview(model: Node3D = null, debug_mode: bool = false):
	#print("--- CONFIGURANDO PREVIEW ---")
	#
	#if current_model and current_model != model:
		#print("Limpiando modelo anterior: %s" % current_model.name)
		#if current_model.get_parent() == viewport:
			#viewport.remove_child(current_model)
		#current_model.queue_free()
	#
	## Limpiar objetos de debug previos
	#_clear_debug_test_objects()
	#
	## MODO DEBUG: Solo mostrar objetos de prueba (cuando no hay modelo o modo debug forzado)
	#if debug_mode or model == null:
		#print("🔴 MODO DEBUG ACTIVADO - Mostrando objetos de prueba")
		#_create_debug_test_objects()
		#
		## CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
		#print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
		#_setup_emergency_lighting()
		#
		## ACTIVAR modo preview en camera controller
		#camera_controller.enable_preview_mode()
		#
		#print("✅ Preview mode activado en camera controller")
		#_debug_viewport_rendering()
		#
		## NUEVO: Crear display temporal automáticamente
		#print("🖥️  CREANDO DISPLAY TEMPORAL AUTOMÁTICAMENTE")
		#call_deferred("debug_viewport_ui_connection")
		#
		#print("🔴 PRUEBA ACTIVADA: Deberías ver Esfera ROJA, Cubo VERDE, Cilindro AZUL")
		#return
	#
	## MODO NORMAL: Mostrar modelo + objetos de prueba para comparación
	#current_model = model
	#viewport.add_child(current_model)
	#
	#print("✅ Modelo añadido al viewport: %s" % current_model.name)
	#
	## Configurar cámara para el modelo
	#var bounds = _calculate_model_bounds(current_model)
	#print("Bounds calculados: %s" % str(bounds))
	#
	#camera_controller.setup_for_model(bounds)
	#
	## CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
	#print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
	#_setup_emergency_lighting()
	#
	## CREAR OBJETOS DE PRUEBA JUNTO AL MODELO para comparación
	#print("🔴 AGREGANDO OBJETOS DE PRUEBA JUNTO AL MODELO")
	#_create_debug_test_objects()
	#
	## ACTIVAR modo preview en camera controller
	#camera_controller.enable_preview_mode()
	#
	#print("✅ Preview mode activado en camera controller")
	#
	## Iniciar animación de preview si existe
	#_start_preview_animation()
	#
	## Debug completo del estado
	#_debug_preview_setup()
	#_debug_viewport_rendering()
	#
	## NUEVO: Crear display temporal para el modelo también
	#print("🖥️  CREANDO DISPLAY TEMPORAL PARA MODELO")
	#call_deferred("debug_viewport_ui_connection")


# Agregar estas funciones al sprite_renderer.gd para debuggear y corregir la animación

# NUEVA FUNCIÓN: Debug detallado del estado de animación
func debug_animation_state():
	print("🎬 DEBUG: VERIFICANDO ESTADO DE ANIMACIÓN")
	
	if not current_model:
		print("  ❌ No hay modelo actual")
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		print("  ❌ No se encontró AnimationPlayer")
		return
	
	print("  ✅ AnimationPlayer encontrado: %s" % anim_player.name)
	print("    Animaciones disponibles: %s" % str(anim_player.get_animation_list()))
	print("    Animación actual: %s" % anim_player.current_animation)
	print("    Está reproduciendo: %s" % anim_player.is_playing())
	print("    Posición actual: %.3f" % anim_player.current_animation_position)
	print("    Velocidad: %.3f" % anim_player.speed_scale)
	
	if anim_player.current_animation != "":
		var current_anim = anim_player.get_animation(anim_player.current_animation)
		if current_anim:
			print("    Duración: %.3f" % current_anim.length)
			print("    Loop mode: %s" % current_anim.loop_mode)
			print("    Tracks: %d" % current_anim.get_track_count())
			
			# Verificar si los tracks están funcionando
			for i in range(min(5, current_anim.get_track_count())):
				var track_path = current_anim.track_get_path(i)
				print("      Track %d: %s" % [i, track_path])
	
	# Verificar el skeleton y si los huesos se están moviendo
	var skeleton = current_model.get_node_or_null("Skeleton3D_combined")
	if skeleton:
		print("  ✅ Skeleton encontrado: %s (%d huesos)" % [skeleton.name, skeleton.get_bone_count()])
		
		# Verificar algunos huesos principales
		var key_bones = ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Head", "mixamorig_LeftArm"]
		for bone_name in key_bones:
			var bone_idx = skeleton.find_bone(bone_name)
			if bone_idx >= 0:
				var bone_pose = skeleton.get_bone_pose_position(bone_idx)
				print("    Hueso %s (idx %d): pos %s" % [bone_name, bone_idx, bone_pose])
	else:
		print("  ❌ No se encontró skeleton combinado")

# NUEVA FUNCIÓN: Forzar reinicio de animación con debug
func force_restart_animation():
	print("🔄 FORZANDO REINICIO DE ANIMACIÓN")
	
	if not current_model:
		print("  ❌ No hay modelo para animar")
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		print("  ❌ No se encontró AnimationPlayer")
		return
	
	# Detener animación actual
	anim_player.stop()
	await get_tree().process_frame
	
	# Obtener la primera animación disponible
	var anim_list = anim_player.get_animation_list()
	if anim_list.size() == 0:
		print("  ❌ No hay animaciones disponibles")
		return
	
	var first_anim = anim_list[0]
	print("  🎬 Reiniciando animación: %s" % first_anim)
	
	# Configurar para loop
	var anim = anim_player.get_animation(first_anim)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
		print("    Configurado para loop infinito")
	
	# Reproducir desde el inicio
	anim_player.play(first_anim)
	anim_player.seek(0.0, true)
	
	print("  ✅ Animación reiniciada")
	
	# Debug inmediato del estado
	await get_tree().process_frame
	debug_animation_state()

# NUEVA FUNCIÓN: Monitor continuo de animación (para debug temporal)
var animation_monitor_active = false

func start_animation_monitoring():
	if animation_monitor_active:
		return
		
	animation_monitor_active = true
	print("📊 INICIANDO MONITOR DE ANIMACIÓN")
	
	# Crear timer para monitoreo
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_animation_monitor)
	add_child(timer)
	timer.start()

func _on_animation_monitor():
	if not animation_monitor_active:
		return
		
	if current_model:
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player and anim_player.is_playing():
			print("📊 Anim: %s | Pos: %.2f/%.2f | Speed: %.2f" % [
				anim_player.current_animation,
				anim_player.current_animation_position,
				anim_player.get_animation(anim_player.current_animation).length,
				anim_player.speed_scale
			])
		else:
			print("📊 ❌ Animación no está reproduciéndose")

func stop_animation_monitoring():
	animation_monitor_active = false
	print("📊 MONITOR DE ANIMACIÓN DETENIDO")

# FUNCIÓN MODIFICADA: Agregar debug de animación al setup_preview
func setup_preview(model: Node3D = null, debug_mode: bool = false):
	print("--- CONFIGURANDO PREVIEW ---")
	
	if current_model and current_model != model:
		print("Limpiando modelo anterior: %s" % current_model.name)
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		current_model.queue_free()
	
	# Limpiar objetos de debug previos
	_clear_debug_test_objects()
	
	# MODO DEBUG: Solo mostrar objetos de prueba (cuando no hay modelo o modo debug forzado)
	if debug_mode or model == null:
		print("🔴 MODO DEBUG ACTIVADO - Mostrando objetos de prueba")
		_create_debug_test_objects()
		
		# CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
		print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
		_setup_emergency_lighting()
		
		# ACTIVAR modo preview en camera controller
		camera_controller.enable_preview_mode()
		
		print("✅ Preview mode activado en camera controller")
		_debug_viewport_rendering()
		
		# NUEVO: Crear display temporal automáticamente
		print("🖥️  CREANDO DISPLAY TEMPORAL AUTOMÁTICAMENTE")
		call_deferred("debug_viewport_ui_connection")
		
		print("🔴 PRUEBA ACTIVADA: Deberías ver Esfera ROJA, Cubo VERDE, Cilindro AZUL")
		return
	
	# MODO NORMAL: Mostrar modelo + objetos de prueba para comparación
	current_model = model
	viewport.add_child(current_model)
	
	print("✅ Modelo añadido al viewport: %s" % current_model.name)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	print("Bounds calculados: %s" % str(bounds))
	
	camera_controller.setup_for_model(bounds)
	
	# CORRECCIÓN CRÍTICA: Forzar configuración de iluminación
	print("🔆 CONFIGURANDO ILUMINACIÓN FORZADA")
	_setup_emergency_lighting()
	
	# CREAR OBJETOS DE PRUEBA JUNTO AL MODELO para comparación
	print("🔴 AGREGANDO OBJETOS DE PRUEBA JUNTO AL MODELO")
	_create_debug_test_objects()
	
	# ACTIVAR modo preview en camera controller
	camera_controller.enable_preview_mode()
	
	print("✅ Preview mode activado en camera controller")
	
	# MODIFICADO: Iniciar animación con debug mejorado
	_start_preview_animation_with_debug()
	
	# Debug completo del estado
	_debug_preview_setup()
	_debug_viewport_rendering()
	
	# NUEVO: Crear display temporal para el modelo también
	print("🖥️  CREANDO DISPLAY TEMPORAL PARA MODELO")
	call_deferred("debug_viewport_ui_connection")
	
	# NUEVO: Debug de animación después de un momento
	call_deferred("_delayed_animation_debug")

func _delayed_animation_debug():
	await get_tree().create_timer(2.0).timeout
	print("🎬 DEBUG RETRASADO DE ANIMACIÓN:")
	debug_animation_state()
	
	# Si la animación no está funcionando, forzar reinicio
	var anim_player = current_model.get_node_or_null("AnimationPlayer") if current_model else null
	if anim_player and not anim_player.is_playing():
		print("🔄 Animación detenida - Forzando reinicio")
		force_restart_animation()

func _start_preview_animation_with_debug():
	print("--- INICIANDO ANIMACIÓN DE PREVIEW CON DEBUG ---")
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		print("❌ No se encontró AnimationPlayer")
		return
	
	if anim_player.get_animation_list().size() == 0:
		print("❌ No hay animaciones en AnimationPlayer")
		return
	
	var first_anim = anim_player.get_animation_list()[0]
	print("🎬 Iniciando animación: %s" % first_anim)
	
	# Configurar la animación para loop
	var anim = anim_player.get_animation(first_anim)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR
		print("  Configurado para loop infinito")
		print("  Duración: %.2fs" % anim.length)
		print("  Tracks: %d" % anim.get_track_count())
	
	# Reproducir animación
	anim_player.play(first_anim)
	print("✅ Animación iniciada")
	
	# Iniciar monitoreo temporal
	start_animation_monitoring()
	
	# Detener monitoreo después de 10 segundos
	get_tree().create_timer(10.0).timeout.connect(stop_animation_monitoring)


# NUEVA FUNCIÓN: Crear objetos de prueba en el viewport
func _create_debug_test_objects():
	print("🔴 CREANDO OBJETOS DE PRUEBA EN VIEWPORT")
	
	# Crear esfera de prueba
	var test_sphere = MeshInstance3D.new()
	test_sphere.name = "DEBUG_TestSphere"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	test_sphere.mesh = sphere_mesh
	
	# Material rojo brillante para la esfera
	var sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color.RED
	sphere_material.emission_enabled = true
	sphere_material.emission = Color(1.0, 0.2, 0.2)
	sphere_material.roughness = 0.3
	test_sphere.set_surface_override_material(0, sphere_material)
	
	# Posicionar la esfera en el centro
	test_sphere.position = Vector3(0, 1, 0)
	viewport.add_child(test_sphere)
	print("  ✅ Esfera roja creada en posición: %s" % str(test_sphere.position))
	
	# Crear cubo de prueba
	var test_cube = MeshInstance3D.new()
	test_cube.name = "DEBUG_TestCube"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.5, 0.5, 0.5)
	test_cube.mesh = box_mesh
	
	# Material verde brillante para el cubo
	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = Color.GREEN
	cube_material.emission_enabled = true
	cube_material.emission = Color(0.2, 1.0, 0.2)
	cube_material.roughness = 0.3
	test_cube.set_surface_override_material(0, cube_material)
	
	# Posicionar el cubo a un lado
	test_cube.position = Vector3(1.5, 0.5, 0)
	viewport.add_child(test_cube)
	print("  ✅ Cubo verde creado en posición: %s" % str(test_cube.position))
	
	# Crear cilindro azul para referencia
	var test_cylinder = MeshInstance3D.new()
	test_cylinder.name = "DEBUG_TestCylinder"
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 1.0
	cylinder_mesh.top_radius = 0.3
	cylinder_mesh.bottom_radius = 0.3
	test_cylinder.mesh = cylinder_mesh
	
	# Material azul brillante
	var cylinder_material = StandardMaterial3D.new()
	cylinder_material.albedo_color = Color.BLUE
	cylinder_material.emission_enabled = true
	cylinder_material.emission = Color(0.2, 0.2, 1.0)
	cylinder_material.roughness = 0.3
	test_cylinder.set_surface_override_material(0, cylinder_material)
	
	# Posicionar el cilindro al otro lado
	test_cylinder.position = Vector3(-1.5, 0.5, 0)
	viewport.add_child(test_cylinder)
	print("  ✅ Cilindro azul creado en posición: %s" % str(test_cylinder.position))
	
	# Ajustar cámara para ver los objetos de prueba
	var test_bounds = AABB(Vector3(-2, 0, -1), Vector3(4, 2, 2))
	camera_controller.setup_for_model(test_bounds)
	
	print("🔴 OBJETOS DE PRUEBA CREADOS - Deberías ver: Esfera ROJA, Cubo VERDE, Cilindro AZUL")

# NUEVA FUNCIÓN: Limpiar objetos de prueba
func _clear_debug_test_objects():
	var objects_to_remove = []
	
	for child in viewport.get_children():
		if child.name.begins_with("DEBUG_Test"):
			objects_to_remove.append(child)
	
	for obj in objects_to_remove:
		viewport.remove_child(obj)
		obj.queue_free()

# NUEVA FUNCIÓN: Activar solo modo de prueba (para llamar externamente)
func activate_debug_mode():
	print("🔴 ACTIVANDO MODO DEBUG DESDE EXTERNAL")
	setup_preview(null, true)

# NUEVA FUNCIÓN: Configurar iluminación de emergencia si falla la del camera_controller  
func _setup_emergency_lighting():
	# Verificar si ya hay luces en el viewport
	var existing_lights = _find_lights_in_viewport()
	print("  Luces existentes encontradas: %d" % existing_lights.size())
	
	if existing_lights.size() == 0:
		print("  ⚠️  No hay luces - Creando iluminación de emergencia")
		
		# Crear luz direccional principal
		var main_light = DirectionalLight3D.new()
		main_light.name = "EmergencyMainLight"
		main_light.light_energy = 1.5
		main_light.light_color = Color(1.0, 1.0, 1.0)
		main_light.position = Vector3(10, 15, 10)
		main_light.rotation_degrees = Vector3(-45, -45, 0)
		main_light.shadow_enabled = false  # Desactivar sombras para debug
		viewport.add_child(main_light)
		print("  ✅ Luz principal de emergencia creada")
		
		# Crear luz ambiental adicional
		var ambient_light = DirectionalLight3D.new()
		ambient_light.name = "EmergencyAmbientLight"
		ambient_light.light_energy = 0.8
		ambient_light.light_color = Color(0.8, 0.9, 1.0)
		ambient_light.position = Vector3(-5, 10, -5)
		ambient_light.rotation_degrees = Vector3(-30, 135, 0)
		ambient_light.shadow_enabled = false
		viewport.add_child(ambient_light)
		print("  ✅ Luz ambiental de emergencia creada")
		
		# Forzar actualización del viewport
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await get_tree().process_frame
		viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		
	else:
		print("  ✅ Luces existentes detectadas - No se necesita emergencia")
		for light in existing_lights:
			print("    - %s: energía %.2f" % [light.name, light.light_energy])

# NUEVA FUNCIÓN: Buscar luces existentes en el viewport
func _find_lights_in_viewport() -> Array:
	var lights = []
	_search_lights_recursive(viewport, lights)
	return lights

func _search_lights_recursive(node: Node, lights: Array):
	if node is Light3D:
		lights.append(node)
	
	for child in node.get_children():
		_search_lights_recursive(child, lights)

# NUEVA FUNCIÓN: Debug completo del estado del viewport
func _debug_viewport_rendering():
	print("--- DEBUG VIEWPORT RENDERING ---")
	print("  Viewport size: %s" % str(viewport.size))
	print("  Viewport transparent_bg: %s" % viewport.transparent_bg)
	print("  Viewport render_target_update_mode: %s" % viewport.render_target_update_mode)
	print("  Viewport child count: %d" % viewport.get_child_count())
	
	# Listar todos los hijos del viewport
	for child in viewport.get_children():
		print("    Hijo: %s (%s)" % [child.name, child.get_class()])
		if child is Node3D:
			print("      Posición: %s" % str(child.position))
			print("      Visible: %s" % child.visible)
	
	# Verificar la cámara
	var camera = camera_controller.get_camera()
	if camera:
		print("  Cámara activa: %s" % camera.name)
		print("    Proyección: %s" % ("Ortográfica" if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else "Perspectiva"))
		print("    Posición: %s" % str(camera.global_position))
		print("    Rotación: %s" % str(camera.rotation_degrees))
		print("    Size/FOV: %.2f" % (camera.size if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else camera.fov))
		print("    Near: %.2f, Far: %.2f" % [camera.near, camera.far])
	else:
		print("  ❌ No se encontró cámara activa")
	
	# Debug del modelo en el viewport
	if current_model:
		print("  Modelo en viewport: %s" % current_model.name)
		print("    Posición global: %s" % str(current_model.global_position))
		print("    Escala global: %s" % str(current_model.global_scale))
		print("    Visible: %s" % current_model.visible)
		
		# Calcular si el modelo está en el campo de visión de la cámara
		if camera:
			var model_center = _calculate_model_bounds(current_model).get_center()
			var distance_to_camera = camera.global_position.distance_to(model_center)
			print("    Distancia a cámara: %.2f" % distance_to_camera)
			print("    Centro del modelo: %s" % str(model_center))
	
	print("✅ Debug de viewport completado")

func _start_preview_animation():
	print("--- INICIANDO ANIMACIÓN DE PREVIEW ---")
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.get_animation_list().size() > 0:
		var first_anim = anim_player.get_animation_list()[0]
		print("Reproduciendo animación: %s" % first_anim)
		
		anim_player.play(first_anim)
		# No pausar, dejar que se reproduzca en loop
		
		print("✅ Animación iniciada")
	else:
		print("❌ No se encontró AnimationPlayer o animaciones")

func _debug_preview_setup():
	print("--- DEBUG PREVIEW SETUP ---")
	print("Current model: %s" % (current_model.name if current_model else "NULL"))
	print("Viewport size: %s" % str(viewport.size))
	
	var camera = camera_controller.get_camera()
	if camera:
		print("Camera position: %s" % str(camera.global_position))
		print("Camera looking at: %s" % str(camera_controller.target_position))
	else:
		print("❌ No se encontró cámara")
	
	# Verificar que el modelo tiene skeleton y meshes
	if current_model:
		var skeleton = current_model.get_node_or_null("Skeleton3D_combined")
		if skeleton:
			print("✅ Skeleton encontrado: %d huesos" % skeleton.get_bone_count())
			
			var mesh_count = 0
			for child in skeleton.get_children():
				if child is MeshInstance3D:
					mesh_count += 1
					print("  Mesh: %s (visible: %s)" % [child.name, child.visible])
					
					if child.mesh:
						print("    Mesh resource: %s" % child.mesh.get_class())
						print("    Surfaces: %d" % child.mesh.get_surface_count())
					else:
						print("    ❌ Sin mesh resource")
			
			print("✅ Meshes encontrados: %d" % mesh_count)
			
			# Verificar AnimationPlayer
			var anim_player = current_model.get_node_or_null("AnimationPlayer")
			if anim_player:
				print("✅ AnimationPlayer encontrado")
				print("  Animaciones: %s" % str(anim_player.get_animation_list()))
				if anim_player.is_playing():
					print("  Estado: Reproduciendo %s" % anim_player.current_animation)
				else:
					print("  Estado: Detenido")
			else:
				print("❌ No se encontró AnimationPlayer")
		else:
			print("❌ No se encontró skeleton en modelo combinado")
			
			# Buscar otros skeletons
			for child in current_model.get_children():
				print("  Nodo hijo: %s (%s)" % [child.name, child.get_class()])
				if child is Skeleton3D:
					print("    Es Skeleton3D con %d huesos" % child.get_bone_count())

func stop_preview():
	print("--- DETENIENDO PREVIEW ---")
	camera_controller.disable_preview_mode()
	
	if current_model:
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.stop()
		
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		
		current_model = null
	
	print("✅ Preview detenido")



# Agregar estas funciones al sprite_renderer.gd para diagnosticar el problema de UI

# NUEVA FUNCIÓN: Debug de la conexión UI-Viewport
func debug_viewport_ui_connection():
	print("🖥️  DEBUG: VERIFICANDO CONEXIÓN UI-VIEWPORT")
	
	# Verificar la textura del viewport
	var viewport_texture = viewport.get_texture()
	if viewport_texture:
		print("  ✅ Viewport tiene textura válida")
		print("    Tamaño de textura: %s" % str(viewport_texture.get_size()))
	else:
		print("  ❌ Viewport NO tiene textura")
		return
	
	# Buscar la escena principal
	var main_scene = get_tree().current_scene
	if not main_scene:
		print("  ❌ No se encontró escena principal")
		return
	
	print("  ✅ Escena principal: %s" % main_scene.name)
	
	# Buscar controles que podrían mostrar el viewport
	var ui_controls = _find_ui_controls_recursive(main_scene)
	print("  Controles UI encontrados: %d" % ui_controls.size())
	
	for control in ui_controls:
		print("    - %s (%s)" % [control.name, control.get_class()])
		if control is TextureRect:
			var texture_rect = control as TextureRect
			print("      Textura asignada: %s" % (texture_rect.texture != null))
		elif control is ColorRect:
			print("      Color: %s" % control.color)
	
	# Crear TextureRect temporal para mostrar el viewport
	_create_debug_viewport_display()

# NUEVA FUNCIÓN: Buscar controles UI recursivamente
func _find_ui_controls_recursive(node: Node) -> Array:
	var controls = []
	
	if node is Control:
		controls.append(node)
	
	for child in node.get_children():
		controls.append_array(_find_ui_controls_recursive(child))
	
	return controls

# NUEVA FUNCIÓN: Crear display temporal del viewport
func _create_debug_viewport_display():
	print("🖥️  CREANDO DISPLAY TEMPORAL DEL VIEWPORT")
	
	# Buscar o crear un nodo UI para mostrar el viewport
	var main_scene = get_tree().current_scene
	var debug_ui = main_scene.get_node_or_null("DEBUG_ViewportDisplay")
	
	if debug_ui:
		debug_ui.queue_free()
		await get_tree().process_frame
	
	# Crear nuevo Control para mostrar el viewport
	debug_ui = Control.new()
	debug_ui.name = "DEBUG_ViewportDisplay"
	debug_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_scene.add_child(debug_ui)
	
	# Crear TextureRect para mostrar el contenido del viewport
	var texture_rect = TextureRect.new()
	texture_rect.name = "DEBUG_ViewportTexture"
	texture_rect.texture = viewport.get_texture()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Posicionar en una esquina para debug
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	texture_rect.size = Vector2(400, 400)
	texture_rect.position = Vector2(10, 10)
	
	# Agregar borde para visibilidad
	var border = ColorRect.new()
	border.color = Color.RED
	border.size = texture_rect.size + Vector2(4, 4)
	border.position = texture_rect.position - Vector2(2, 2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_ui.add_child(border)
	debug_ui.add_child(texture_rect)
	
	print("  ✅ Display temporal creado en esquina superior izquierda")
	print("  🔴 Si ves un recuadro ROJO con contenido: UI funciona")
	print("  🔴 Si ves solo recuadro rojo vacío: Problema de renderizado")
	print("  🔴 Si NO ves nada: Problema de creación de UI")
	
	# Forzar actualización del viewport
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	
	print("🖥️  DEBUG UI DISPLAY COMPLETADO")

# NUEVA FUNCIÓN: Limpiar debug UI
func clean_debug_viewport_display():
	var main_scene = get_tree().current_scene
	var debug_ui = main_scene.get_node_or_null("DEBUG_ViewportDisplay")
	
	if debug_ui:
		debug_ui.queue_free()
		print("🧹 Display temporal limpiado")

# FUNCIÓN MODIFICADA: Agregar debug UI automáticamente
