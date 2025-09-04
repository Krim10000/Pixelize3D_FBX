# scripts/rendering/sprite_renderer.gd
# MODIFICADO: Usa directamente la cámara del ModelPreviewPanel para garantizar consistencia
# Input: Modelo 3D combinado con animaciones y configuración de renderizado
# Output: Frames renderizados usando exactamente la misma cámara que ve el usuario

extends Node3D

signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)

# ✅ MODIFICADO: Referencias directas al preview en lugar de crear propias
var preview_panel: Control
var viewport: SubViewport
var camera: Camera3D
var camera_controller: Node3D
var model_container: Node3D
var anim_manager: Node
var orientation_analyzer: Node

var render_settings: Dictionary
var current_model: Node3D
var frames_buffer: Array = []

# Estado del renderizado
var is_rendering: bool = false
var current_animation: String = ""
var current_direction: int = 0
var current_frame: int = 0
var total_frames: int = 0

# ✅ NUEVO: Estado de la cámara durante renderizado
var original_viewport_mode: int
var render_backup_model: Node3D
@onready  var analyzer_script = load("res://scripts/orientation/orientation_analyzer.gd")

func _ready():
	print("🎬 SpriteRenderer MODIFICADO iniciado - Usa cámara del preview")
	call_deferred("_initialize_shared_references")
	
	if analyzer_script:
		orientation_analyzer = analyzer_script.new()
		add_child(orientation_analyzer)
		print("✅ OrientationAnalyzer inicializado")
	else:
		push_error("❌ No se pudo cargar orientation_analyzer.gd")

func update_render_settings(new_settings: Dictionary):
	"""Actualizar configuración de renderizado en tiempo real"""
	#print("🔄 Actualizando configuración de sprite renderer...")
	
	render_settings = new_settings.duplicate()
	
	# Aplicar cambios inmediatamente si hay una cámara configurada
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings(new_settings)
		#print("✅ Configuración aplicada al camera controller del renderer")
	
	#print("✅ Configuración de renderer actualizada")
	#print("  - directions: %d" % render_settings.get("directions", 16))
	#print("  - sprite_size: %d" % render_settings.get("sprite_size", 128))
	#print("  - camera_height: %.1f" % render_settings.get("camera_height", 12.0))

func _initialize_shared_references():
	"""Inicializar referencias compartidas con ModelPreviewPanel"""
	#print("🔗 Inicializando referencias compartidas...")
	
	# Buscar ModelPreviewPanel
	preview_panel = _find_model_preview_panel()
	if not preview_panel:
		push_error("❌ No se encontró ModelPreviewPanel")
		return
	
	# Obtener referencias directas del preview
	_get_preview_references()
	
	# Buscar animation manager
	anim_manager = get_parent().get_node_or_null("AnimationManager")
	if not anim_manager:
		anim_manager = get_node_or_null("/root/ViewerModular/AnimationManager")
	
	_log_initialization_status()

func _find_model_preview_panel() -> Control:
	"""Buscar ModelPreviewPanel en la escena"""
	var paths_to_try = [
		"/root/ViewerModular/HSplitContainer/RightPanel/ModelPreviewPanel",
		"../HSplitContainer/RightPanel/ModelPreviewPanel"
	]
	
	for path in paths_to_try:
		var node = get_node_or_null(path)
		if node:
			print("✅ ModelPreviewPanel encontrado en: %s" % path)
			return node
	
	# Búsqueda recursiva como fallback
	print("🔍 Buscando ModelPreviewPanel recursivamente...")
	return _search_for_preview_panel(get_tree().current_scene)

func _search_for_preview_panel(node: Node) -> Control:
	"""Buscar preview panel recursivamente"""
	if node.name == "ModelPreviewPanel":
		print("✅ ModelPreviewPanel encontrado: %s" % node.get_path())
		return node
	
	for child in node.get_children():
		var result = _search_for_preview_panel(child)
		if result:
			return result
	
	return null

func _get_preview_references():
	"""Obtener referencias directas del ModelPreviewPanel"""
	if not preview_panel:
		return
	
	# Obtener viewport del preview
	var viewport_container = preview_panel.get_node_or_null("ViewportContainer")
	if viewport_container:
		viewport = viewport_container.get_node_or_null("SubViewport")
	
	if not viewport:
		push_error("❌ No se encontró SubViewport en ModelPreviewPanel")
		return
	
	# Obtener cámara del preview
	camera = viewport.get_node_or_null("Camera3D")
	if not camera:
		push_error("❌ No se encontró Camera3D en viewport del preview")
		return
	
	# Obtener camera controller del preview
	camera_controller = viewport.get_node_or_null("CameraController")
	if not camera_controller:
		push_warning("⚠️ No se encontró CameraController en viewport del preview")
	
	# Obtener model container del preview
	model_container = viewport.get_node_or_null("ModelContainer")
	if not model_container:
		push_warning("⚠️ No se encontró ModelContainer en viewport del preview")

func _log_initialization_status():
	"""Log del estado de inicialización"""
	#print("✅ Referencias compartidas inicializadas:")
	#print("  PreviewPanel: %s" % ("✅" if preview_panel else "❌"))
	#print("  Viewport: %s" % ("✅" if viewport else "❌"))
	#print("  Camera: %s" % ("✅" if camera else "❌"))
	#print("  CameraController: %s" % ("✅" if camera_controller else "❌"))
	#print("  ModelContainer: %s" % ("✅" if model_container else "❌"))
	#print("  AnimationManager: %s" % ("✅" if anim_manager else "❌"))

# ========================================================================
# INICIALIZACIÓN DE RENDERIZADO - MODIFICADO
# ========================================================================

func initialize(settings: Dictionary):
	"""Inicializar configuración de renderizado usando viewport compartido"""
	if not viewport:
		push_error("❌ No se puede inicializar sin viewport compartido")
		return
	
	render_settings = settings
	
	#print("🎨 Inicializando renderizado con viewport compartido...")
	#print("  Viewport path: %s" % viewport.get_path())
	#print("  Tamaño solicitado: %dx%d" % [settings.get("sprite_size", 128), settings.get("sprite_size", 128)])
	#
	# ✅ NUEVO: Configurar viewport para renderizado sin afectar preview
	_prepare_viewport_for_rendering(settings)
	
	# Configurar cámara para renderizado
	_configure_camera_for_rendering(settings)
	
	#print("✅ SpriteRenderer inicializado con viewport compartido")

func _prepare_viewport_for_rendering(settings: Dictionary):
	"""Preparar viewport compartido para renderizado"""
	if not viewport:
		return
	
	# Guardar configuración original del viewport
	original_viewport_mode = viewport.render_target_update_mode
	
	# Configurar tamaño para renderizado
	var sprite_size = settings.get("sprite_size", 128)
	
	# ✅ CRÍTICO: Respetar el tamaño del preview pero preparar para captura
	#print("🔧 Preparando viewport para renderizado:")
	#print("  Tamaño actual: %s" % str(viewport.size))	
	#print("  Modo actual: %d" % viewport.render_target_update_mode)
	
	# Configurar para renderizado óptimo
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # CRÍTICO
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	
	# No cambiar el tamaño para mantener consistencia con preview
	# El tamaño se mantendrá igual al preview para garantizar WYSIWYG

func _configure_camera_for_rendering(settings: Dictionary):
	"""Configurar cámara compartida para renderizado"""
	if not camera or not camera_controller:
		return
	
	#print("📸 Configurando cámara compartida para renderizado...")
	
	# 1. Verificar si necesitamos auto-detección de norte
	var final_settings = settings.duplicate()
	if settings.get("auto_north_detection", true) and current_model:
		#print("🧭 Aplicando detección automática de norte...")
		
		# 2. Obtener orientación sugerida
		var suggested_north = orientation_analyzer.analyze_model_quick(current_model)
		
		var adjusted_north = suggested_north 

		# Normalizar
		while adjusted_north >= 360.0:
			adjusted_north -= 360.0
		while adjusted_north < 0.0:
			adjusted_north += 360.0

		
		# 3. Calcular compensación para la cámara
		var camera_offset = -suggested_north
		
		
		# 4. Actualizar settings con el nuevo norte
		final_settings["north_offset"] = camera_offset
		print("   Norte automático aplicado: %.1f° (original: %.1f°, ajustado: %.1f°)" % [camera_offset, suggested_north, adjusted_north])	
	
	
	# 5. Aplicar configuración de cámara
	if camera_controller.has_method("set_camera_settings"):
		var camera_settings = {
			"camera_angle": final_settings.get("camera_angle", 45.0),
			"camera_height": final_settings.get("camera_height", 12.0),
			"camera_distance": final_settings.get("camera_distance", 20.0),
			"north_offset": final_settings.get("north_offset" , 270.0)
		}
		camera_controller.set_camera_settings(camera_settings)
		print( camera_settings)
		print("✅ Configuración de cámara aplicada para renderizado")




func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int):
	"""Renderizar animación usando delay system en lugar de FPS"""
	
	if not _validate_shared_render_prerequisites():
		animation_complete.emit(animation_name)  # ✅ Godot 4.4
		return
		
	if not is_instance_valid(model):
		push_error("❌ Modelo no es válido")
		animation_complete.emit(animation_name)  # ✅ Godot 4.4
		return
	
	if is_rendering:
		print("⚠️ Ya renderizando")
		animation_complete.emit(animation_name)  # ✅ Godot 4.4
		return
	
	#print("⏱️ Renderizando con DELAY SYSTEM: %s" % animation_name)
	
	is_rendering = true
	current_animation = animation_name
	current_direction = direction_index
	current_frame = 0
	
	_switch_to_render_mode(model, angle)
	
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		
		# ✅ USAR DELAY EN LUGAR DE FPS
		#var frame_delay = render_settings.get("frame_delay", 0.033333)
		var frame_delay = _get_current_user_delay()
		total_frames = int(anim.length / frame_delay)
		
		print("📊 Delay: %.4fs, Frames: %d" % [frame_delay, total_frames])
		_render_next_frame_with_delay()
	else:
		total_frames = 1
		_render_static_frame()


func _validate_shared_render_prerequisites() -> bool:
	"""Validar que todos los componentes compartidos estén listos"""
	if not viewport:
		push_error("❌ Viewport compartido no disponible")
		return false
	
	if not camera:
		push_error("❌ Cámara compartida no disponible")
		return false
	
	if render_settings.is_empty():
		push_error("❌ Configuración de renderizado no establecida")
		return false
	
	return true

func _switch_to_render_mode(model: Node3D, angle: float):
	"""Cambiar viewport compartido a modo renderizado"""
	#print("🔄 Cambiando a modo renderizado...")
	
	# Limpiar container y añadir modelo para renderizado
	_safe_switch_model_in_container(model)
	
	# Configurar cámara para el modelo y ángulo específico
	if camera_controller:
		# Calcular bounds del modelo
		var bounds = _calculate_model_bounds(model)
		if camera_controller.has_method("setup_for_model"):
			camera_controller.setup_for_model(bounds)
		
		# Aplicar ángulo específico para esta dirección
		if camera_controller.has_method("set_rotation_angle"):
			camera_controller.set_rotation_angle(angle)
			#print("🧭 Ángulo de cámara establecido: %.1f°" % angle)
	
	# Configurar viewport para captura
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	#print("✅ Modo renderizado activado")

func _safe_switch_model_in_container(new_model: Node3D):
	"""Cambiar modelo en container de forma segura"""
	if not model_container:
		push_error("❌ No hay model_container disponible")
		return
	
	# Remover modelo actual del container (pero no hacer queue_free)
	for child in model_container.get_children():
		model_container.remove_child(child)
		# No hacer queue_free aquí - el modelo puede estar siendo usado en otro lugar
	
	# Añadir nuevo modelo
	current_model = new_model
	model_container.add_child(current_model)
	
	#print("🔄 Modelo cambiado en container: %s" % current_model.name)

func _restore_preview_mode():
	"""Restaurar modo preview después del renderizado"""
	#print("🔄 Restaurando modo preview...")
	
	# Restaurar modelo original del preview si existe
	if render_backup_model and is_instance_valid(render_backup_model):
		_safe_switch_model_in_container(render_backup_model)
		render_backup_model = null
		#print("✅ Modelo del preview restaurado")
	
	# Restaurar configuración original del viewport
	if original_viewport_mode >= 0:
		viewport.render_target_update_mode = original_viewport_mode
	
	# Limpiar referencias del renderizado
	current_model = null
	
	#print("✅ Modo preview restaurado")

# ========================================================================
# RENDERIZADO DE FRAMES - MANTIENE LÓGICA EXISTENTE
# ========================================================================

func _render_next_frame():
	"""Renderizar siguiente frame usando cámara compartida"""
	if current_frame >= total_frames:
		_finish_rendering()
		return
	
	if not current_model or not is_instance_valid(current_model):
		push_error("❌ Modelo se invalidó durante el renderizado")
		_finish_rendering()
		return

	_prepare_model_for_frame()

	# Esperar frames para garantizar render limpio
	#await get_tree().process_frame
	#await RenderingServer.frame_post_draw
	await get_tree().process_frame
	
	# Configurar viewport para captura
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#await RenderingServer.frame_post_draw
	
	# ✅ Captura del frame usando viewport compartido
	var image := viewport.get_texture().get_image().duplicate()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)

	var frame_data := {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": _get_current_camera_angle(),
		"image": image
	}

	#emit_signal("frame_rendered", frame_data)
	frame_rendered.emit(frame_data)
	#emit_signal("rendering_progress", current_frame + 1, total_frames)
	rendering_progress.emit(current_frame+1, total_frames)
	
	
	

	current_frame += 1
	call_deferred("_render_next_frame")

func _get_current_camera_angle() -> float:
	"""Obtener ángulo actual de la cámara"""
	if camera_controller and camera_controller.has_method("get_relative_angle"):
		return camera_controller.get_relative_angle()
	elif camera_controller and camera_controller.has_node("pivot_node"):
		return camera_controller.get_node("pivot_node").rotation_degrees.y
	else:
		return 0.0

func _finish_rendering():
	"""Finalizar renderizado y restaurar estado"""
	is_rendering = false
	_restore_preview_mode()
	#emit_signal("animation_complete", current_animation)
	animation_complete.emit(current_animation)
	#print("✅ Renderizado completado y preview restaurado")

func _render_static_frame():
	"""Renderizar frame estático para modelos sin animación"""
	await get_tree().process_frame
	
	if not viewport:
		push_error("❌ Viewport no disponible para frame estático")
		_finish_rendering()
		return
	
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	
	var image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": 0,
		"angle": _get_current_camera_angle(),
		"image": image
	}
	
	emit_signal("frame_rendered", frame_data)
	_finish_rendering()

# ========================================================================
# PREPARACIÓN DE MODELO - MANTIENE LÓGICA EXISTENTE
# ========================================================================

func _prepare_model_for_frame():
	"""Preparar modelo para frame actual"""
	if anim_manager and anim_manager.has_method("prepare_model_for_rendering"):
		if current_model and is_instance_valid(current_model):
			anim_manager.prepare_model_for_rendering(
				current_model,
				current_frame,
				total_frames,
				current_animation
			)
	else:
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
		anim_player.advance(0)

# ========================================================================
# CONFIGURACIÓN DE PREVIEW - NUEVO PARA COMPATIBILIDAD
# ========================================================================

func setup_preview(model: Node3D, settings: Dictionary = {}):
	"""Configurar preview usando el sistema compartido"""
	#print("🎬 Configurando preview usando cámara compartida...")
	
	if not preview_panel:
		push_error("❌ No hay ModelPreviewPanel disponible")
		return
	
	# Delegar al ModelPreviewPanel para mantener consistencia
	if preview_panel.has_method("set_model"):
		preview_panel.set_model(model)
		#print("✅ Preview configurado a través de ModelPreviewPanel")
	
	# Aplicar configuración de cámara si se proporciona
	if not settings.is_empty() and camera_controller:
		if camera_controller.has_method("set_camera_settings"):
			camera_controller.set_camera_settings(settings)

# ========================================================================
# UTILIDADES - MANTIENE FUNCIONES EXISTENTES
# ========================================================================

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
	"""Buscar todas las instancias de mesh"""
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_mesh_instances(child))
	
	return meshes

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
			var steps = float(color_count)
			color.r = round(color.r * steps) / steps
			color.g = round(color.g * steps) / steps
			color.b = round(color.b * steps) / steps
			image.set_pixel(x, y, color)

# ========================================================================
# FUNCIONES PÚBLICAS PARA COMPATIBILIDAD
# ========================================================================

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func is_busy() -> bool:
	"""Verificar si el renderer está ocupado"""
	return is_rendering

func has_viewport() -> bool:
	"""Verificar si hay viewport disponible"""
	return viewport != null

func has_camera_controller() -> bool:
	"""Verificar si hay camera controller disponible"""
	return camera_controller != null

func get_shared_camera() -> Camera3D:
	"""Obtener referencia a la cámara compartida"""
	return camera

func get_shared_viewport() -> SubViewport:
	"""Obtener referencia al viewport compartido"""
	return viewport

func debug_shared_state():
	"""Debug del estado compartido"""
	pass
	##print("\n🎬 === SPRITE RENDERER SHARED DEBUG ===")
	##print("Preview Panel: %s" % ("✅" if preview_panel else "❌"))
	##print("Viewport compartido: %s" % ("✅" if viewport else "❌"))
	##print("Cámara compartida: %s" % ("✅" if camera else "❌"))
	##print("CameraController: %s" % ("✅" if camera_controller else "❌"))
	##print("ModelContainer: %s" % ("✅" if model_container else "❌"))
	##print("Estado renderizado: %s" % ("🔄 Activo" if is_rendering else "⏸️ Inactivo"))
	#if viewport:
		#print("Viewport path: %s" % viewport.get_path())
		#print("Viewport size: %s" % str(viewport.size))
		#print("Viewport mode: %d" % viewport.render_target_update_mode)
	#print("==========================================\n")
#


# NUEVO - AGREGAR DESPUÉS DE _render_next_frame():
func _render_next_frame_with_delay():
	"""Renderizar frame usando timing de delay preciso"""
	if current_frame >= total_frames:
		_finish_rendering()
		return
	
	if not current_model or not is_instance_valid(current_model):
		_finish_rendering()
		return
	
	# Calcular tiempo preciso usando delay
	#var frame_delay = render_settings.get("frame_delay", 0.033333)
	var frame_delay = _get_current_user_delay()
	var target_time = current_frame * frame_delay
	
	#print("⏰ Frame %d/%d en tiempo %.4fs" % [current_frame + 1, total_frames, target_time])
	
	# Aplicar timing preciso
	var anim_player = current_model.get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.seek(target_time, true)
		anim_player.advance(0.0)
	
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	
	var image = viewport.get_texture().get_image().duplicate()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	var frame_data = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": _get_current_camera_angle(),
		"image": image,
		"timing_data": {
			"target_time": target_time,
			"frame_delay": frame_delay,
			"fps_equivalent": 1.0 / frame_delay
		}
	}
	
	frame_rendered.emit(frame_data)  # ✅ Godot 4.4
	rendering_progress.emit(current_frame + 1, total_frames)  # ✅ Godot 4.4
	
	current_frame += 1
	call_deferred("_render_next_frame_with_delay")



func _get_current_user_delay() -> float:
	"""Obtener el delay que configuró el usuario en el SettingsPanel"""
	
	# Buscar SettingsPanel en la escena
	var settings_panel = get_tree().current_scene.find_child("SettingsPanel", true, false)
	if not settings_panel:
		settings_panel = get_tree().current_scene.find_child("UpdatedSettingsPanel", true, false)
	
	if not settings_panel:
		print("⚠️ SettingsPanel no encontrado, usando delay default")
		return 0.033333
	
	# Método 1: Desde delay_spinbox directamente
	if settings_panel.get("delay_spinbox") and settings_panel.delay_spinbox:
		var spinbox_value = settings_panel.delay_spinbox.value
	#	print("✅ Delay obtenido del SpinBox: %.4fs" % spinbox_value)
		return spinbox_value
	
	# Método 2: Desde get_current_settings()
	if settings_panel.has_method("get_current_settings"):
		var settings = settings_panel.get_current_settings()
		if settings.get("frame_delay"):
	#		print("✅ Delay obtenido de current_settings: %.4fs" % settings.frame_delay)
			return settings.frame_delay
	
	# Método 3: Desde current_settings directamente
	if settings_panel.get("current_settings"):
		var current_settings = settings_panel.current_settings
		if current_settings.get("frame_delay"):
			print("✅ Delay obtenido de current_settings directo: %.4fs" % current_settings.frame_delay)
			return current_settings.frame_delay
	
	#print("⚠️ No se pudo obtener delay del usuario, usando default: 0.033333")
	return 0.0321
