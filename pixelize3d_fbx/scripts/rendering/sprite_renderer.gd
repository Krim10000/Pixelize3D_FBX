# pixelize3d_fbx/scripts/rendering/sprite_renderer.gd
# Script de renderizado REFACTORIZADO - Solo responsabilidades de renderizado individual
# Input: Modelo 3D combinado con animaciones y configuración de renderizado (incluyendo north_offset)
# Output: Frames renderizados individuales para cada dirección y animación con orientación aplicada

extends Node3D

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)

# ✅ CORREGIDO: Referencias dinámicas en lugar de rutas hardcodeadas
@onready var viewport: SubViewport
@onready var camera_controller
@onready var anim_manager

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
	print("🎬 SpriteRenderer REFACTORIZADO iniciado")
	# ✅ CRÍTICO: Inicializar referencias dinámicamente
	_initialize_references()
	_setup_viewport()
	_setup_render_environment()

func _initialize_references():
	"""Inicializar referencias de forma segura"""
	print("🔧 Inicializando referencias del SpriteRenderer...")
	
	# Buscar viewport dinámicamente
	viewport = _find_viewport_safely()
	if not viewport:
		push_error("❌ No se pudo encontrar SubViewport")
		return
	
	# Buscar camera controller
	camera_controller = viewport.get_node_or_null("CameraController")
	if not camera_controller:
		print("⚠️ CameraController no encontrado, creando uno...")
		var camera_script = load("res://scripts/rendering/camera_controller.gd")
		if camera_script:
			camera_controller = camera_script.new()
			camera_controller.name = "CameraController"
			viewport.add_child(camera_controller)
	
	# Buscar animation manager
	anim_manager = get_parent().get_node_or_null("AnimationManager")
	if not anim_manager:
		anim_manager = get_node_or_null("/root/Main/AnimationManager")
	
	print("✅ Referencias inicializadas:")
	print("  Viewport: %s" % ("✅" if viewport else "❌"))
	print("  CameraController: %s" % ("✅" if camera_controller else "❌"))
	print("  AnimationManager: %s" % ("✅" if anim_manager else "❌"))

func _find_viewport_safely() -> SubViewport:
	"""Buscar viewport de forma segura"""
	# Intentar rutas conocidas primero
	var known_paths = [
		"/root/ViewerModular/HSplitContainer/RightPanel/ModelPreviewPanel/ViewportContainer/SubViewport",
		"SubViewport"
	]
	
	for path in known_paths:
		var node = get_node_or_null(path)
		if node and node is SubViewport:
			print("✅ Viewport encontrado en: %s" % path)
			return node
	
	# Buscar recursivamente como fallback
	print("🔍 Buscando viewport recursivamente...")
	return _search_for_viewport(get_tree().current_scene)

func _search_for_viewport(node: Node) -> SubViewport:
	"""Buscar viewport recursivamente"""
	if node is SubViewport:
		print("✅ Viewport encontrado: %s" % node.get_path())
		return node
	
	for child in node.get_children():
		var result = _search_for_viewport(child)
		if result:
			return result
	
	return null

func _setup_viewport():
	"""Configurar viewport de forma segura"""
	if not viewport:
		print("❌ No hay viewport para configurar")
		return
	
	# Configurar viewport para renderizado de sprites
	
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.transparent_bg = true
	
	print("✅ Viewport configurado")

func _setup_render_environment():
	"""Configurar ambiente de renderizado"""
	if not camera_controller:
		print("❌ No hay camera_controller para configurar ambiente")
		return
	
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
		print("✅ Ambiente de renderizado configurado")

func initialize(settings: Dictionary):
	"""Inicializar configuración de renderizado"""
	if not viewport:
		push_error("❌ No se puede inicializar sin viewport")
		return
	
	render_settings = settings
	
	# ✅ CORREGIDO: Configurar tamaño del viewport de forma segura
	var sprite_size = settings.get("sprite_size", 256)
	
	# Verificar si el viewport tiene un parent SubViewportContainer con stretch
	var viewport_container = viewport.get_parent()
	if viewport_container is SubViewportContainer:
		if viewport_container.stretch:
			print("⚠️ SubViewportContainer tiene stretch=true, deshabilitando temporalmente...")
			# Deshabilitar stretch temporalmente para permitir cambio de tamaño
			viewport_container.stretch = false
			viewport.size = Vector2i(sprite_size, sprite_size)
			# Volver a habilitar stretch después del cambio
			viewport_container.stretch = true
			print("✅ Tamaño del viewport configurado: %dx%d (con stretch workaround)" % [sprite_size, sprite_size])
		else:
			viewport.size = Vector2i(sprite_size, sprite_size)
			print("✅ Tamaño del viewport configurado: %dx%d" % [sprite_size, sprite_size])
	else:
		# No hay container, cambiar directamente
		viewport.size = Vector2i(sprite_size, sprite_size)
		print("✅ Tamaño del viewport configurado: %dx%d" % [sprite_size, sprite_size])
	
	# Configurar cámara
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings({
			"camera_angle": settings.get("camera_angle", 45.0),
			"camera_height": settings.get("camera_height", 12.0),
			"camera_distance": settings.get("camera_distance", 20.0)
		})
	
	print("✅ SpriteRenderer inicializado con tamaño: %dx%d" % [sprite_size, sprite_size])

func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int):
	"""Renderizar animación con validaciones mejoradas - FUNCIÓN PRINCIPAL DEL RENDERER"""
	# ✅ CRÍTICO: Validaciones completas antes de iniciar
	if not _validate_render_prerequisites():
		emit_signal("animation_complete", animation_name)
		return
		
	if not is_instance_valid(model):
		push_error("❌ Modelo no es válido para renderizado")
		emit_signal("animation_complete", animation_name)
		return
	
	# ✅ CORREGIDO: Manejo mejorado del estado is_rendering
	if is_rendering:
		print("⚠️ Ya hay un renderizado en proceso, esperando...")
		# En lugar de rechazar, esperar un poco y verificar de nuevo
		await get_tree().create_timer(0.1).timeout
		if is_rendering:
			push_warning("Ya hay un renderizado en proceso")
			emit_signal("animation_complete", animation_name)
			return
	
	print("🎬 Renderizando: %s, dirección %d, ángulo %.1f°" % [animation_name, direction_index, angle])
	
	is_rendering = true
	current_animation = animation_name
	current_direction = direction_index
	current_frame = 0
	
	# ✅ CRÍTICO: Limpiar modelo anterior de forma segura
	_cleanup_current_model()
	
	# Añadir nuevo modelo al viewport
	current_model = model
	#viewport.add_child(current_model)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	if camera_controller and camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(bounds)
	
	if camera_controller and camera_controller.has_method("set_rotation_angle"):
		camera_controller.set_rotation_angle(angle)
	
	# Obtener información de la animación
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		var fps = render_settings.get("fps", 12)
		total_frames = int(anim.length * fps)
		
		# Iniciar renderizado de frames
		_render_next_frame()
	else:
		# Si no hay animación, renderizar un solo frame
		total_frames = 1
		_render_static_frame()

func _validate_render_prerequisites() -> bool:
	"""Validar que todos los componentes estén listos para renderizado"""
	if not viewport:
		push_error("❌ Viewport no disponible")
		return false
	
	if not camera_controller:
		push_error("❌ CameraController no disponible")
		return false
	
	if render_settings.is_empty():
		push_error("❌ Configuración de renderizado no establecida")
		return false
	
	return true

func _cleanup_current_model():
	"""Limpiar modelo actual de forma segura"""
	if current_model and is_instance_valid(current_model):
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		# NO hacer queue_free aquí, el modelo puede estar siendo usado en otro lugar
		current_model = null

##func _render_next_frame():
	##"""Renderizar siguiente frame con validaciones mejoradas"""
	##if current_frame >= total_frames:
		### Animación completa para esta dirección
		##is_rendering = false
		##emit_signal("animation_complete", current_animation)
		##return
	##
	### ✅ CRÍTICO: Validar modelo antes de cada frame
	##if not current_model or not is_instance_valid(current_model):
		##push_error("❌ Modelo se invalidó durante el renderizado")
		##is_rendering = false
		##emit_signal("animation_complete", current_animation)
		##return
	##
	### Preparar el modelo para el frame actual
	##_prepare_model_for_frame()
	##
	### Esperar un frame para que se actualice la pose
	##await get_tree().process_frame
	##
	### ✅ CRÍTICO: Validar nuevamente después del await
	##if not current_model or not is_instance_valid(current_model):
		##push_error("❌ Modelo se invalidó después del await")
		##is_rendering = false
		##emit_signal("animation_complete", current_animation)
		##return
	##
	### Renderizar el frame
	##if not viewport:
		##push_error("❌ Viewport no disponible")
		##is_rendering = false
		##emit_signal("animation_complete", current_animation)
		##return
	##
	##viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	##await RenderingServer.frame_post_draw
	##
	### Capturar la imagen
	##var image = viewport.get_texture().get_image()
	##
	### Aplicar pixelización si es necesario
	##if render_settings.get("pixelize", true):
		##image = _apply_pixelization(image)
	##
	### Emitir frame renderizado
	##var frame_data = {
		##"animation": current_animation,
		##"direction": current_direction,
		##"frame": current_frame,
		##"angle": camera_controller.pivot_node.rotation_degrees.y if camera_controller and camera_controller.has_method("get_current_angle") else 0.0,
		##"image": image
	##}
	##
	##emit_signal("frame_rendered", frame_data)
	##emit_signal("rendering_progress", current_frame + 1, total_frames)
	##
	### Continuar con el siguiente frame
	##current_frame += 1
	##call_deferred("_render_next_frame")
#func _cleanup_current_model():
	#"""Eliminar TODOS los modelos del viewport antes de continuar"""
	#if viewport:
		#for child in viewport.get_children():
			#if child != camera_controller:
				#viewport.remove_child(child)
				#if is_instance_valid(child):
					#child.queue_free()
	#current_model = null


func _render_next_frame():
	if current_frame >= total_frames:
		is_rendering = false
		emit_signal("animation_complete", current_animation)
		return
	
	if not current_model or not is_instance_valid(current_model):
		push_error("❌ Modelo se invalidó durante el renderizado")
		is_rendering = false
		emit_signal("animation_complete", current_animation)
		return

	_prepare_model_for_frame()

	# 🕒 Esperar 2 frames completos para garantizar render limpio
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	
	# 🧼 Reforzar limpieza
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	#viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED #NO 
	#viewport.render_target_update_mode = SubViewport.UPDATE_ONCE #TANPOCO
	#viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# ⚠️ Esperar render posterior a la instrucción de actualización
	await RenderingServer.frame_post_draw
	
	# ✅ Captura del frame limpio
	var image := viewport.get_texture().get_image().duplicate()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)

	var frame_data := {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": camera_controller.pivot_node.rotation_degrees.y if camera_controller else 0.0,
		"image": image
	}

	emit_signal("frame_rendered", frame_data)
	emit_signal("rendering_progress", current_frame + 1, total_frames)
	print("_render_next_frame")

	current_frame += 1
	call_deferred("_render_next_frame")


func _prepare_model_for_frame():
	"""Preparar modelo para frame actual de forma segura"""
	# ✅ CRÍTICO: Usar anim_manager solo si está disponible y el modelo es válido
	if anim_manager and anim_manager.has_method("prepare_model_for_rendering"):
		if current_model and is_instance_valid(current_model):
			anim_manager.prepare_model_for_rendering(
				current_model,
				current_frame,
				total_frames,
				current_animation
			)
		else:
			print("⚠️ Modelo no válido para preparación")
	else:
		# Implementación de respaldo
		_prepare_model_fallback()

func _prepare_model_fallback():
	"""Preparación de respaldo cuando AnimationManager no está disponible"""
	if not current_model or not is_instance_valid(current_model):
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(current_animation):
		var anim = anim_player.get_animation(current_animation)
		var time = (float(current_frame) / total_frames) * anim.length
		anim_player.seek(time, true)
		anim_player.advance(0)  # Forzar actualización
	else:
		print("⚠️ No se pudo preparar modelo para renderizado")

func _render_static_frame():
	"""Renderizar frame estático para modelos sin animación"""
	# Para modelos sin animación
	await get_tree().process_frame
	
	if not viewport:
		push_error("❌ Viewport no disponible para frame estático")
		is_rendering = false
		emit_signal("animation_complete", current_animation)
		return
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	#viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	
	await RenderingServer.frame_post_draw
	
	var image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": 0,
		"angle": camera_controller.pivot_node.rotation_degrees.y if camera_controller else 0.0,
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	print("_render_static_frame")
	is_rendering = false
	emit_signal("animation_complete", current_animation)

func _apply_pixelization(image: Image) -> Image:
	"""Aplicar efecto de pixelización"""
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
	"""Reducir paleta de colores"""
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
	"""Calcular bounds del modelo"""
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
	"""Buscar todas las instancias de mesh"""
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_mesh_instances(child))
	
	return meshes

func update_camera_settings(settings: Dictionary):
	"""Actualizar configuración de cámara"""
	if not camera_controller:
		return
	
	if camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings(settings)
	
	# Aplicar orientación norte en preview si está activo
	if camera_controller.has_method("get_preview_mode_enabled") and camera_controller.get_preview_mode_enabled():
		if settings.has("north_offset"):
			var north_offset = settings.get("north_offset", 0.0)
			print("🧭 Aplicando orientación norte en preview: %.1f°" % north_offset)
			if camera_controller.has_method("set_rotation_angle"):
				camera_controller.set_rotation_angle(north_offset)

func setup_preview(model: Node3D, settings: Dictionary = {}):
	"""Configurar preview de forma segura"""
	print("--- CONFIGURANDO PREVIEW CON ORIENTACIÓN ---")
	
	if not viewport:
		push_error("❌ No hay viewport para preview")
		return
	
	if not is_instance_valid(model):
		push_error("❌ Modelo no válido para preview")
		return
	
	# Limpiar modelo anterior de forma segura
	_cleanup_current_model()
	
	current_model = model
	viewport.add_child(current_model)
	
	print("✅ Modelo añadido al viewport: %s" % current_model.name)
	
	# Configurar cámara para el modelo
	var bounds = _calculate_model_bounds(current_model)
	print("Bounds calculados: %s" % str(bounds))
	
	if camera_controller and camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(bounds)
	
	# Aplicar orientación norte inicial en preview
	var north_offset = settings.get("north_offset", 0.0)
	if north_offset != 0.0 and camera_controller and camera_controller.has_method("set_rotation_angle"):
		print("🧭 Aplicando orientación norte inicial: %.1f°" % north_offset)
		camera_controller.set_rotation_angle(north_offset)
	
	# Activar modo preview en camera controller
	if camera_controller and camera_controller.has_method("enable_preview_mode"):
		camera_controller.enable_preview_mode()
	
	print("✅ Preview mode activado con orientación norte")
	
	# Iniciar animación de preview si existe
	_start_preview_animation()
	
	# Verificar que el modelo se ve
	_debug_preview_setup()

func _start_preview_animation():
	"""Iniciar animación de preview"""
	print("--- INICIANDO ANIMACIÓN DE PREVIEW ---")
	
	if not current_model or not is_instance_valid(current_model):
		print("❌ No hay modelo válido para animación de preview")
		return
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.get_animation_list().size() > 0:
		var first_anim = anim_player.get_animation_list()[0]
		print("Reproduciendo animación: %s" % first_anim)
		
		anim_player.play(first_anim)
		print("✅ Animación iniciada")
	else:
		print("❌ No se encontró AnimationPlayer o animaciones")

func _debug_preview_setup():
	"""Debug del setup de preview"""
	print("--- DEBUG PREVIEW SETUP ---")
	#print("Current model: %s" % (current_model.name if current_model and is_instance_valid(current_model) else "NULL"))
	# Versión corregida
	#print("Current model: %s" % (current_model.name if current_model and is_instance_valid(current_model) else "NULL"))
	print("Current model: %s" % (str(current_model.name) if is_instance_valid(current_model) else "NULL"))
	#print("Viewport size: %s" % str(viewport.size if viewport else "NULL"))
	print("Viewport size: %s" % (str(viewport.size) if viewport else "NULL"))
	
	if camera_controller and camera_controller.has_method("get_camera"):
		var camera = camera_controller.get_camera()
		if camera:
			print("Camera position: %s" % str(camera.global_position))
			if camera_controller.has_method("get_target_position"):
				print("Camera looking at: %s" % str(camera_controller.get_target_position()))
			#print("Current rotation: %.1f°" % camera_controller.pivot_node.rotation_degrees.y if camera_controller.has_method("get_current_rotation") else 0.0)
			# Versión corregida
			var rotation_value = camera_controller.get_current_rotation() if camera_controller and camera_controller.has_method("get_current_rotation") else 0.0
			print("Current rotation: %.1f°" % rotation_value)
		else:
			print("❌ No se encontró cámara")
	
	# Verificar que el modelo tiene skeleton y meshes
	if current_model and is_instance_valid(current_model):
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
	"""Detener preview de forma segura"""
	print("--- DETENIENDO PREVIEW ---")
	
	if camera_controller and camera_controller.has_method("disable_preview_mode"):
		camera_controller.disable_preview_mode()
	
	if current_model and is_instance_valid(current_model):
		var anim_player = current_model.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.stop()
		
		if current_model.get_parent() == viewport:
			viewport.remove_child(current_model)
		
		current_model = null
	
	print("✅ Preview detenido")

# ========================================================================
# ❌ FUNCIÓN REMOVIDA: render_and_export_spritesheet()
# Esta función se movió a spritesheet_pipeline.gd según la refactorización
# ========================================================================

# ✅ AGREGADO: Función para forzar reset del estado de renderizado
func force_reset_rendering_state():
	"""Forzar reset del estado de renderizado en caso de emergencia"""
	print("🚨 FORCE RESET: Estado de renderizado")
	is_rendering = false
	current_animation = ""
	current_direction = 0
	current_frame = 0
	total_frames = 0
	
	# Limpiar modelo actual si existe
	_cleanup_current_model()
	
	print("✅ Estado de renderizado reseteado")

# ✅ AGREGADO: Función para obtener estado actual
func get_rendering_state() -> Dictionary:
	"""Obtener estado actual del renderizado para debug"""
	return {
		"is_rendering": is_rendering,
		"current_animation": current_animation,
		"current_direction": current_direction,
		"current_frame": current_frame,
		"total_frames": total_frames,
		"has_current_model": current_model != null and is_instance_valid(current_model),
		"viewport_available": viewport != null,
		"camera_controller_available": camera_controller != null
	}

# ✅ AGREGADO: Función de debug
func debug_rendering_state():
	"""Debug del estado de renderizado"""
	var state = get_rendering_state()
	print("\n🎬 === SPRITE RENDERER DEBUG ===")
	print("Estado de renderizado: %s" % ("🔄 Activo" if state.is_rendering else "⏸️ Inactivo"))
	print("Animación actual: %s" % state.current_animation)
	print("Dirección actual: %d" % state.current_direction)
	print("Frame actual: %d/%d" % [state.current_frame, state.total_frames])
	print("Modelo válido: %s" % ("✅" if state.has_current_model else "❌"))
	print("Viewport disponible: %s" % ("✅" if state.viewport_available else "❌"))
	print("CameraController disponible: %s" % ("✅" if state.camera_controller_available else "❌"))
	print("==============================\n")

# ========================================================================
# ✅ FUNCIONES PÚBLICAS SIMPLIFICADAS PARA USO DEL PIPELINE
# ========================================================================

func is_busy() -> bool:
	"""Verificar si el renderer está ocupado"""
	return is_rendering

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func has_viewport() -> bool:
	"""Verificar si hay viewport disponible"""
	return viewport != null

func has_camera_controller() -> bool:
	"""Verificar si hay camera controller disponible"""
	return camera_controller != null

# ========================================================================
# FUNCIÓN PARA COMPATIBILIDAD CON VERSIONES ANTERIORES
# ========================================================================

func render_single_direction(model: Node3D, animation_name: String, angle: float, direction_index: int):
	"""Alias para render_animation - compatibilidad"""
	render_animation(model, animation_name, angle, direction_index)
