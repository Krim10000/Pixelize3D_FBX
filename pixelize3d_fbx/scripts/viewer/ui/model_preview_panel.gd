# scripts/viewer/ui/model_preview_panel.gd
# Panel MEJORADO con métodos completos para control de animaciones
# Input: Modelo 3D con AnimationPlayer
# Output: Vista previa interactiva con control total

extends VBoxContainer

# Señales
signal bounds_calculated(bounds: AABB)
signal animation_started(animation_name: String)
signal animation_stopped()
signal preview_ready()

# Referencias a componentes
@onready var viewport_container = $ViewportContainer
@onready var viewport = $ViewportContainer/SubViewport
@onready var camera = $ViewportContainer/SubViewport/Camera3D
@onready var camera_controller = $ViewportContainer/SubViewport/CameraController
@onready var model_container = $ViewportContainer/SubViewport/ModelContainer
#@onready var directional_light = $ViewportContainer/SubViewport/DirectionalLight3D
@onready var directional_light = find_child("DirectionalLight3D", true, false)
@onready var model_rotator = find_child("ModelRotator")

# UI elements
var status_label: Label
var controls_help_label: Label

# Estado interno
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var current_bounds: AABB = AABB()
var preview_active: bool = false

# ✅ NUEVO: Estado de animación
var is_animation_playing: bool = false
var current_animation_name: String = ""
var capture_area_indicator: Control
var orientation_overlay: Control
var orientation_cross: Control

var current_shader_settings: Dictionary = {}
var shader_applied_to_model: bool = false
var outline_3d_enabled: bool = false
var outline_material: ShaderMaterial = null


# === NUEVAS VARIABLES PARA POST-PROCESSING ===
var postprocess_quad: MeshInstance3D = null
var postprocess_material: ShaderMaterial = null
var postprocess_enabled: bool = false
var previous_viewport_state: Dictionary = {}



var original_material: Material = null

func _ready():
	print("🎬 ModelPreviewPanel MEJORADO inicializado")
	_setup_ui()
	_connect_signals()
	#call_deferred("setup_postprocessing_system")
	call_deferred("setup_canvas_postprocessing")
	print("oooooooooooooooooooooooo camera")
	print(camera)
	
	# Configurar viewport
	if viewport:
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _setup_ui():
	"""Configurar elementos de UI básicos"""
	if not status_label:
		status_label = Label.new()
		add_child(status_label)
	
	if not controls_help_label:
		controls_help_label = Label.new()
		add_child(controls_help_label)
	
	_create_orientation_overlay()
	_create_capture_area_indicator()
	status_label.text = "Esperando modelo..."
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	controls_help_label.text = "CONTROLES: Click+Arrastrar=Rotar | Rueda=Zoom | Shift+Click=Panear"
	controls_help_label.add_theme_font_size_override("font_size", 9)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false

func _create_capture_area_indicator():
	"""Crear indicador visual del área de captura"""
	if not viewport_container:
		return
	
	# Crear overlay para el indicador
	capture_area_indicator = Control.new()
	capture_area_indicator.name = "CaptureAreaIndicator"
	capture_area_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_area_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.add_child(capture_area_indicator)
	
	# Configurar para dibujar el borde
	capture_area_indicator.draw.connect(_draw_capture_area)
	
	#print("✅ Indicador de área de captura creado")


func _draw_capture_area():
	"""Dibujar borde del área de captura - CORREGIDO COMPLETAMENTE"""
	if not viewport or not capture_area_indicator:
		return
	
	# ✅ CRÍTICO: Obtener el tamaño real del viewport interno, NO del container
	var actual_viewport_size = viewport.size
	
	## ✅ DEBUG: Mostrar información de tamaños
	#print("🔍 DEBUG _draw_capture_area:")
	#print("  viewport.size: %s" % actual_viewport_size)
	#print("  viewport_container.size: %s" % viewport_container.size)
	#print("  capture_area_indicator.size: %s" % capture_area_indicator.size)
	
	# ✅ CORRECCIÓN: El área de captura debe coincidir exactamente con el viewport
	# NO usar el viewport_container.size porque puede estar mal escalado
	var indicator_size = capture_area_indicator.size
	
	# Calcular área cuadrada centrada en el indicador
	var square_size = min(indicator_size.x, indicator_size.y)
	var offset_x = (indicator_size.x - square_size) / 2.0
	var offset_y = (indicator_size.y - square_size) / 2.0
	
	var rect = Rect2(offset_x, offset_y, square_size, square_size)
	
	#print("  square_size calculado: %.1f" % square_size)
	#print("  rect final: %s" % rect)
	
	# Configuración visual mejorada
	var border_color = Color(1.0, 1.0, 0.0, 0.9)  # Amarillo más opaco
	var border_width = 3.0  # Más grueso para mejor visibilidad
	
	# Dibujar marco principal
	capture_area_indicator.draw_rect(rect, border_color, false, border_width)
	
	# Dibujar esquinas para mejor visibilidad
	var corner_size = min(20.0, square_size * 0.15)  # Proporcional al tamaño real
	var corner_color = Color(1.0, 0.5, 0.0, 1.0)  # Naranja
	var corner_width = 4.0
	
	# Esquina superior izquierda
	capture_area_indicator.draw_line(
		rect.position,
		rect.position + Vector2(corner_size, 0),
		corner_color, corner_width
	)
	capture_area_indicator.draw_line(
		rect.position,
		rect.position + Vector2(0, corner_size),
		corner_color, corner_width
	)
	
	# Esquina superior derecha
	var top_right = Vector2(rect.position.x + rect.size.x, rect.position.y)
	capture_area_indicator.draw_line(
		top_right,
		top_right + Vector2(-corner_size, 0),
		corner_color, corner_width
	)
	capture_area_indicator.draw_line(
		top_right,
		top_right + Vector2(0, corner_size),
		corner_color, corner_width
	)
	
	# Esquina inferior izquierda
	var bottom_left = Vector2(rect.position.x, rect.position.y + rect.size.y)
	capture_area_indicator.draw_line(
		bottom_left,
		bottom_left + Vector2(corner_size, 0),
		corner_color, corner_width
	)
	capture_area_indicator.draw_line(
		bottom_left,
		bottom_left + Vector2(0, -corner_size),
		corner_color, corner_width
	)
	
	# Esquina inferior derecha
	var bottom_right = rect.position + rect.size
	capture_area_indicator.draw_line(
		bottom_right,
		bottom_right + Vector2(-corner_size, 0),
		corner_color, corner_width
	)
	capture_area_indicator.draw_line(
		bottom_right,
		bottom_right + Vector2(0, -corner_size),
		corner_color, corner_width
	)

# ========================================================================
# FUNCIÓN MEJORADA: set_viewport_resolution() 
# ========================================================================
func set_viewport_resolution(resolution: int):
	"""Cambiar resolución del viewport de preview - COMPLETAMENTE CORREGIDO"""
	if not viewport:
		print("❌ No hay viewport disponible")
		return
	
	var new_size = Vector2i(resolution, resolution)
	#print("🖼️ Cambiando viewport de preview a: %dx%d" % [new_size.x, new_size.y])
	
	# 1. Cambiar tamaño del viewport interno
	viewport.size = new_size
	#print("  ✅ viewport.size = %s" % viewport.size)
	
	# 2. ✅ CRÍTICO: Actualizar el viewport container para que coincida EXACTAMENTE
	if viewport_container:
		viewport_container.custom_minimum_size = Vector2(resolution, resolution)
		viewport_container.size = Vector2(resolution, resolution)  # ← AGREGAR ESTO
		# Forzar actualización del layout
		viewport_container.queue_sort()
		#print("  ✅ viewport_container.custom_minimum_size = %s" % viewport_container.custom_minimum_size)
	
	# 3. Esperar frames para que se apliquen los cambios de layout
	await get_tree().process_frame
	await get_tree().process_frame  # Doble frame para asegurar
	
	# 4. ✅ VERIFICAR que los tamaños coincidan
	#print("🔍 VERIFICACIÓN POST-CAMBIO:")
	#print("  viewport.size final: %s" % viewport.size)
	#print("  viewport_container.size final: %s" % viewport_container.size)
	
	# 5. Actualizar indicador de área de captura
	update_capture_area_indicator()
	
	#print("✅ Resolución de viewport actualizada y verificada")

# ========================================================================
# FUNCIÓN NUEVA: debug_viewport_sizes()
# ========================================================================
func debug_viewport_sizes():
	"""Debug completo de tamaños de viewport"""
	#print("\n🔍 === DEBUG TAMAÑOS VIEWPORT ===")
	#print("viewport existe: %s" % (viewport != null))
	#print("viewport_container existe: %s" % (viewport_container != null))
	#
	if viewport:
		pass
		#print("viewport.size: %s" % viewport.size)
		#print("viewport.render_target_update_mode: %d" % viewport.render_target_update_mode)
	#
	if viewport_container:
		pass
		#print("viewport_container.size: %s" % viewport_container.size)
		#print("viewport_container.custom_minimum_size: %s" % viewport_container.custom_minimum_size)
	#
	if capture_area_indicator:
		pass
		#print("capture_area_indicator.size: %s" % capture_area_indicator.size)
	#
	#print("===================================\n")
# ========================================================================
# FUNCIÓN A MODIFICAR: update_for_resolution_change()
# ========================================================================
func update_for_resolution_change(resolution: int, capture_area: float):
	"""Actualizar preview para cambio de resolución y área de captura"""
	#print("🔄 Actualizando preview - Resolución: %dx%d, Área: %.1f" % [resolution, resolution, capture_area])
	
	# 1. Cambiar resolución del viewport
	await set_viewport_resolution(resolution)
	
	# 2. Actualizar configuración de cámara si existe (área de captura)
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		var camera_settings = {
			"orthographic_size": capture_area,
			"manual_zoom_override": true,
			"fixed_orthographic_size": capture_area
		}
		camera_controller.set_camera_settings(camera_settings)
		
		if camera_controller.has_method("update_camera_position"):
			camera_controller.update_camera_position()
	
	# 3. Actualizar indicador visual (después de que todo esté aplicado)
	await get_tree().process_frame
	update_capture_area_indicator()
	
	#print("✅ Preview completamente actualizado")

# ========================================================================
# FUNCIÓN A AGREGAR: get_current_viewport_info()
# ========================================================================
func get_current_viewport_info() -> Dictionary:
	"""Obtener información actual del viewport"""
	var info = {
		"viewport_size": Vector2i.ZERO,
		"container_size": Vector2.ZERO,
		"is_valid": false
	}
	
	if viewport:
		info.viewport_size = viewport.size
		info.is_valid = true
	
	if viewport_container:
		info.container_size = Vector2i(viewport_container.size)
	
	return info


func update_capture_area_indicator():
	"""Actualizar indicador cuando cambie la configuración"""
	if capture_area_indicator:
		capture_area_indicator.queue_redraw()




func _connect_signals():
	"""Conectar señales entre componentes"""
	if camera_controller and camera_controller.has_signal("camera_ready"):
		camera_controller.connect("camera_ready", _on_camera_ready)
	
	if model_rotator and model_rotator.has_signal("north_changed"):
		model_rotator.connect("north_changed", _on_north_changed)

func set_model(model: Node3D):
	"""✅ MEJORADO: Configurar modelo para preview con wiggle fix de centrado"""
	print("🎬 Configurando modelo para preview: %s" % model.name)
	
	if not model_container:
		print("❌ model_container no disponible")
		return
	
	# Limpiar modelo anterior
	_clear_current_model_safe()
	
	if not model:
		status_label.text = "No hay modelo cargado"
		controls_help_label.visible = false
		return
	
	if not current_shader_settings.is_empty():
		call_deferred("_reapply_shader_after_model_change")
	
	show_orientation_cross()
	emit_signal("preview_ready")
	print("✅ Preview configurado con soporte 3D outline")
	
	# Duplicar modelo para preview
	current_model = model.duplicate()
	current_model.name = "Preview_" + model.name
	model_container.add_child(current_model)
	
	# Buscar AnimationPlayer
	animation_player = _find_animation_player(current_model)
	
	if capture_area_indicator:
		capture_area_indicator.visible = true
		update_capture_area_indicator()
	
	if animation_player:
		print("✅ AnimationPlayer encontrado con %d animaciones" % animation_player.get_animation_list().size())
		_setup_animation_loops()
		
		# Conectar señales del AnimationPlayer
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		print("⚠️ No se encontró AnimationPlayer")
	
	# Calcular bounds
	current_bounds = _calculate_model_bounds_safe(current_model)
	emit_signal("bounds_calculated", current_bounds)
	
	# Configurar cámara
	if camera_controller and camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(current_bounds)
	
	# Actualizar status
	status_label.text = "Modelo cargado: " + model.name
	controls_help_label.visible = true
	
	# ✅ WIGGLE FIX: Ejecutar wiggle de centrado después de cargar modelo
	call_deferred("_trigger_initial_centering_wiggle")

# ========================================================================
# FUNCIÓN NUEVA: _trigger_initial_centering_wiggle() - en model_preview_panel.gd
# ========================================================================
func _trigger_initial_centering_wiggle():
	"""Ejecutar wiggle de centrado después de cargar modelo inicial"""
	print("🎯 Ejecutando wiggle de centrado para modelo inicial...")
	
	# Esperar frames adicionales para asegurar que todo esté estabilizado
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Buscar el settings panel
	var viewer_coordinator = get_node("/root/ViewerModular")
	if not viewer_coordinator:
		print("❌ ViewerModular no encontrado para wiggle")
		return
	
	var settings_panel = viewer_coordinator.get_node("HSplitContainer/LeftPanel/VBoxContainer/SettingsPanel")
	if not settings_panel:
		print("❌ SettingsPanel no encontrado para wiggle")
		return
	
	# Ejecutar wiggle de centrado
	if settings_panel.has_method("trigger_centering_wiggle"):
		print("🔄 Ejecutando wiggle de centrado inicial...")
		settings_panel.trigger_centering_wiggle()
		print("✅ Wiggle de centrado inicial completado")
	else:
		print("❌ Método trigger_centering_wiggle no encontrado en SettingsPanel")

# ========================================================================
# FUNCIÓN ALTERNATIVA: force_initial_wiggle() - en model_preview_panel.gd
# ========================================================================
func force_initial_wiggle():
	"""Función de debug para forzar wiggle inicial manualmente"""
	print("🧪 === FORZANDO WIGGLE INICIAL MANUAL ===")
	_trigger_initial_centering_wiggle()

# ========================================================================
# FUNCIÓN NUEVA: _setup_initial_camera_centering()
# ========================================================================
func _setup_initial_camera_centering():
	"""Configuración inicial de cámara con centrado forzado"""
	#print("🎯 Configurando centrado inicial de cámara...")
	
	if not current_model:
		print("❌ No hay modelo para centrar")
		return
	
	# 1. Esperar a que el modelo esté completamente en el árbol
	await get_tree().process_frame
	await get_tree().process_frame  # Doble frame para asegurar
	
	# 2. Calcular bounds del modelo
	current_bounds = _calculate_model_bounds_safe(current_model)
	#print("📐 Bounds calculados: %s" % current_bounds)
	
	# 3. Emitir señal de bounds calculados
	emit_signal("bounds_calculated", current_bounds)
	
	# 4. Configurar cámara para el modelo
	if camera_controller and camera_controller.has_method("setup_for_model"):
		#print("📸 Configurando cámara para modelo...")
		camera_controller.setup_for_model(current_bounds)
		
		# ✅ CRÍTICO: Forzar actualización inmediata de posición
		if camera_controller.has_method("update_camera_position"):
			camera_controller.update_camera_position()
			#print("🔄 Posición de cámara actualizada inmediatamente")
	
	# 5. ✅ NUEVO: Aplicar configuración actual del settings panel si existe
	_apply_current_settings_to_camera()
	
	# 6. Esperar otro frame y verificar resultado
	await get_tree().process_frame
	_verify_initial_centering()
	
	#print("✅ Centrado inicial completado")

# ========================================================================
# FUNCIÓN NUEVA: _apply_current_settings_to_camera()
# ========================================================================
func _apply_current_settings_to_camera():
	"""Aplicar configuración actual del settings panel a la cámara"""
	print("⚙️ Aplicando configuración actual a cámara...")
	
	# Buscar el settings panel para obtener configuración actual
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if not viewer_coordinator:
		print("❌ ViewerModular no encontrado")
		return
	
	var settings_panel = viewer_coordinator.get_node_or_null("HSplitContainer/LeftPanel/SettingsPanel")
	if not settings_panel:
		print("❌ SettingsPanel no encontrado")
		return
	
	# Obtener configuración actual
	var current_settings = {}
	if settings_panel.has_method("_get_enhanced_settings"):
		current_settings = settings_panel._get_enhanced_settings()
	elif settings_panel.has_method("get_settings"):
		current_settings = settings_panel.get_settings()
	else:
		print("❌ No se puede obtener configuración del settings panel")
		return
	
	print("📋 Configuración obtenida: %s claves" % current_settings.size())
	
	# Aplicar a la cámara
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings(current_settings)
		print("✅ Configuración aplicada a cámara")
		
		# Forzar actualización
		if camera_controller.has_method("update_camera_position"):
			camera_controller.update_camera_position()

# ========================================================================
# FUNCIÓN NUEVA: _verify_initial_centering()
# ========================================================================
func _verify_initial_centering():
	"""Verificar que el centrado inicial funcionó correctamente"""
	print("🔍 Verificando centrado inicial...")
	
	if not camera_controller:
		print("❌ No hay camera_controller para verificar")
		return
	
	# Obtener información de la cámara
	var camera_info = {}
	if camera_controller.has_method("get_current_zoom_info"):
		camera_info = camera_controller.get_current_zoom_info()
	
	print("📸 Estado de cámara:")
	for key in camera_info:
		print("  %s: %s" % [key, camera_info[key]])
	
	# Verificar si el modelo está visible
	if current_bounds != AABB():
		var bounds_center = current_bounds.get_center()
		print("📐 Centro del modelo: %s" % bounds_center)
		
		# Si el centro está muy lejos del origen, puede estar descentrado
		var distance_from_origin = bounds_center.length()
		if distance_from_origin > 10.0:  # Umbral arbitrario
			print("⚠️ Modelo parece estar lejos del centro (distancia: %.2f)" % distance_from_origin)
			_force_recenter_model()
		else:
			print("✅ Modelo parece estar bien centrado")

# ========================================================================
# FUNCIÓN NUEVA: _force_recenter_model()
# ========================================================================
func _force_recenter_model():
	"""Forzar re-centrado del modelo si parece estar mal posicionado"""
	print("🔧 Forzando re-centrado del modelo...")
	
	if not current_model or not camera_controller:
		return
	
	# Re-calcular bounds
	current_bounds = _calculate_model_bounds_safe(current_model)
	
	# Re-configurar cámara
	if camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(current_bounds)
		
		if camera_controller.has_method("update_camera_position"):
			camera_controller.update_camera_position()
	
	print("🎯 Re-centrado forzado completado")

# ========================================================================
# FUNCIÓN NUEVA: force_immediate_centering() - Para debugging
# ========================================================================
func force_immediate_centering():
	"""Función de debug para forzar centrado inmediato - llamar desde consola"""
	print("🧪 === FORZANDO CENTRADO INMEDIATO ===")
	
	if current_model:
		_setup_initial_camera_centering()
	else:
		print("❌ No hay modelo cargado para centrar")



# === CONTROL DE ANIMACIONES ===

func play_animation(animation_name: String):
	"""✅ NUEVO: Reproducir animación específica"""
	print("▶️ Reproduciendo animación: %s" % animation_name)
	
	if not animation_player:
		print("❌ No hay AnimationPlayer")
		return
	
	# Limpiar nombre si viene con extensión
	var clean_name = animation_name.get_basename()
	
	# Buscar la animación con diferentes variantes
	var found_animation = ""
	for anim in animation_player.get_animation_list():
		if anim == animation_name or anim == clean_name or clean_name in anim:
			found_animation = anim
			break
	
	if found_animation == "":
		print("❌ Animación no encontrada: %s" % animation_name)
		status_label.text = "Error: Animación no encontrada"
		return
	
	# Reproducir
	animation_player.play(found_animation)
	is_animation_playing = true
	current_animation_name = found_animation
	
	status_label.text = "▶️ " + _get_display_name(found_animation)
	emit_signal("animation_started", found_animation)

func pause_animation():
	"""✅ NUEVO: Pausar animación actual"""
	print("⏸️ Pausando animación")
	
	if not animation_player or not is_animation_playing:
		return
	
	animation_player.pause()
	is_animation_playing = false
	status_label.text = "⏸️ " + _get_display_name(current_animation_name)

func resume_animation():
	"""✅ NUEVO: Reanudar animación pausada"""
	print("▶️ Reanudando animación")
	
	if not animation_player or is_animation_playing:
		return
	
	animation_player.play()
	is_animation_playing = true
	status_label.text = "▶️ " + _get_display_name(current_animation_name)

func stop_animation():
	"""✅ NUEVO: Detener animación completamente"""
	print("⏹️ Deteniendo animación")
	
	if not animation_player:
		return
	
	animation_player.stop()
	is_animation_playing = false
	current_animation_name = ""
	
	if current_model:
		status_label.text = "Modelo: " + current_model.name
	else:
		status_label.text = "Listo"
	
	emit_signal("animation_stopped")

func change_animation_speed(speed: float):
	"""✅ NUEVO: Cambiar velocidad de reproducción"""
	if animation_player:
		animation_player.speed_scale = speed
		print("🎬 Velocidad de animación: %.1fx" % speed)

# === MANEJO DE EVENTOS ===

func _on_animation_finished(anim_name: String):
	"""Callback cuando termina una animación"""
	print("🏁 Animación terminada: %s" % anim_name)
	
	# Con loops infinitos, esto raramente se llamará
	# pero es útil para animaciones sin loop
	if is_animation_playing and animation_player:
		# Reiniciar si está en modo loop
		animation_player.play(anim_name)

func _on_camera_ready():
	"""Callback cuando la cámara está lista - CORREGIDO"""

	
	# Actualizar UI
	if preview_active:
		controls_help_label.visible = true
		status_label.text = "Vista previa activa"
		
func _on_north_changed(new_north: float):
	"""Callback cuando cambia la orientación norte"""
	#print("🧭 Norte actualizado: %.1f°" % new_north)

# === UTILIDADES ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _setup_animation_loops():
	"""Configurar loops infinitos para todas las animaciones"""
	if not animation_player:
		return
	
	var anim_list = animation_player.get_animation_list()
	for anim_name in anim_list:
		if animation_player.has_animation(anim_name):
			var anim_lib = animation_player.get_animation_library("")
			if anim_lib and anim_lib.has_animation(anim_name):
				var animation = anim_lib.get_animation(anim_name)
				animation.loop_mode = Animation.LOOP_LINEAR
	
	#print("🔄 Loops configurados para %d animaciones" % anim_list.size())

func _clear_current_model_safe():
	"""Limpiar modelo actual de forma segura"""
	if current_model:
		if animation_player:
			animation_player.stop()
			if animation_player.animation_finished.is_connected(_on_animation_finished):
				animation_player.animation_finished.disconnect(_on_animation_finished)
		
		current_model.queue_free()
		current_model = null
		animation_player = null
		is_animation_playing = false
		current_animation_name = ""

func _calculate_model_bounds_safe(model: Node3D) -> AABB:
	"""Calcular bounds del modelo de forma segura"""
	var bounds = AABB()
	var found_mesh = false
	
	for node in model.get_children():
		if node is MeshInstance3D:
			if not found_mesh:
				bounds = node.get_aabb()
				found_mesh = true
			else:
				bounds = bounds.merge(node.get_aabb())
	
	if not found_mesh:
		bounds = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	
	return bounds

func _get_display_name(animation_name: String) -> String:
	"""Obtener nombre limpio para mostrar"""
	var clean_name = animation_name
	
	# Limpiar patrones comunes
	clean_name = clean_name.replace("mixamo.com", "")
	clean_name = clean_name.replace("Armature|", "")
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	
	return clean_name.strip_edges().capitalize()

# === FUNCIONES PÚBLICAS DE ESTADO ===

func is_preview_active() -> bool:
	"""Verificar si el preview está activo"""
	return preview_active and current_model != null

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func get_animation_player() -> AnimationPlayer:
	"""Obtener AnimationPlayer actual"""
	return animation_player

func get_current_animation() -> String:
	"""Obtener animación actual"""
	return current_animation_name

func is_playing() -> bool:
	"""Verificar si hay animación reproduciéndose"""

	return is_animation_playing

func get_viewport_texture() -> ViewportTexture:
	"""Obtener textura del viewport para otros usos"""
	if viewport:
		return viewport.get_texture()
	return null

# === CONFIGURACIÓN DE CÁMARA ===

func set_camera_position(position: Vector3):
	"""Configurar posición de cámara"""
	if camera:
		camera.position = position


func set_camera_rotation(rotation: Vector3):
	"""Configurar rotación de cámara"""
	if camera:
		camera.rotation = rotation

func reset_camera():
	"""Resetear cámara a posición por defecto"""
	if camera_controller and camera_controller.has_method("reset_to_default"):
		camera_controller.reset_to_default()
	elif current_bounds != AABB():
		# Posición por defecto manual
		var center = current_bounds.get_center()
		var camera_size = current_bounds.get_longest_axis_size()
		camera.position = center + Vector3(camera_size, camera_size, camera_size)
		camera.look_at(center, Vector3.UP)

# === DEBUG ===

func debug_state():
	"""Debug del estado actual"""
	pass
	#print("\n🎬 === MODEL PREVIEW DEBUG ===")
	#print("Preview activo: %s" % preview_active)
##	print("Modelo: %s" % (current_model.name if current_model else "NULL"))
## Error original
	#print("Modelo: %s" % (str(current_model.name) if current_model else "NULL"))
	##print("AnimationPlayer: %s" % (animation_player.name if animation_player else "NULL"))
	#print("AnimationPlayer: %s" % (str(animation_player.name) if animation_player else "NULL"))
	#if animation_player:
		#print("  Animaciones: %s" % str(animation_player.get_animation_list()))
		#print("  Reproduciendo: %s" % is_animation_playing)
		#print("  Actual: %s" % current_animation_name)
	#print("Bounds: %s" % str(current_bounds))
	#print("============================\n")



func _create_orientation_overlay():
	"""Crear overlay de orientación con cruz y norte"""
	if not viewport_container:
		return
	
	# Crear overlay principal
	orientation_overlay = Control.new()
	orientation_overlay.name = "OrientationOverlay"
	orientation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.add_child(orientation_overlay)
	
	# Crear cruz de orientación
	orientation_cross = Control.new()
	orientation_cross.name = "OrientationCross"
	orientation_cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orientation_cross.draw.connect(_draw_orientation_cross)
	orientation_overlay.add_child(orientation_cross)
	
	print("✅ Cruz de orientación creada")

func _draw_orientation_cross():
	"""Dibujar cruz de orientación con indicador de norte"""
	if not orientation_cross:
		return
	
	var viewport_size = viewport_container.size
	var center = viewport_size / 2.0
	
	# Configuración visual
	var cross_size = 60.0
	var line_width = 2.0
	var cross_color = Color(1.0, 1.0, 1.0, 0.8)  # Blanco semi-transparente
	var north_color = Color(1.0, 0.2, 0.2, 1.0)  # Rojo para norte
	
	# Dibujar cruz principal
	# Línea horizontal
	orientation_cross.draw_line(
		Vector2(center.x - cross_size, center.y),
		Vector2(center.x + cross_size, center.y),
		cross_color, line_width
	)
	
	# Línea vertical
	orientation_cross.draw_line(
		Vector2(center.x, center.y - cross_size),
		Vector2(center.x, center.y + cross_size),
		cross_color, line_width
	)
	
	# Dibujar círculo en el centro
	orientation_cross.draw_arc(
		center, 8.0, 0, TAU, 32, cross_color, line_width
	)
	
	# Obtener rotación actual del modelo para orientar la "N"
	var north_angle = 0.0
	if current_model and is_instance_valid(current_model):
		north_angle = deg_to_rad(-current_model.rotation_degrees.y)
	
	# Calcular posición del norte
	var north_distance = cross_size + 20.0
	var north_pos = Vector2(
		center.x + cos(north_angle) * north_distance,
		center.y + sin(north_angle) * north_distance
	)
	
	# Dibujar línea hacia el norte
	orientation_cross.draw_line(
		center,
		Vector2(center.x + cos(north_angle) * cross_size, center.y + sin(north_angle) * cross_size),
		north_color, line_width + 1.0
	)
	
	# Dibujar "N" para el norte
	var font = ThemeDB.fallback_font
	var font_size = 16
	orientation_cross.draw_string(
		font, 
		north_pos - Vector2(8, -8), 
		"N", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size, 
		north_color
	)
	
	# Dibujar flecha en el norte
	var arrow_size = 8.0
	var arrow_tip = Vector2(center.x + cos(north_angle) * cross_size, center.y + sin(north_angle) * cross_size)
	var arrow_left = arrow_tip + Vector2(cos(north_angle + 2.5), sin(north_angle + 2.5)) * arrow_size
	var arrow_right = arrow_tip + Vector2(cos(north_angle - 2.5), sin(north_angle - 2.5)) * arrow_size
	
	orientation_cross.draw_line(arrow_tip, arrow_left, north_color, line_width)
	orientation_cross.draw_line(arrow_tip, arrow_right, north_color, line_width)

func update_orientation_display():
	"""Actualizar visualización de orientación"""
	if orientation_cross:
		orientation_cross.queue_redraw()

func show_orientation_cross():
	"""Mostrar cruz de orientación"""
	if orientation_overlay:
		orientation_overlay.visible = true
		update_orientation_display()

func hide_orientation_cross():
	"""Ocultar cruz de orientación"""
	if orientation_overlay:
		orientation_overlay.visible = false



func _apply_shader_to_mesh_instance(mesh_instance: MeshInstance3D, shader_settings: Dictionary) -> int:
	"""Aplicar shader a todas las superficies de una MeshInstance3D"""
	if not mesh_instance or not mesh_instance.mesh:
		return 0
	
	var surfaces_processed = 0
	var surface_count = mesh_instance.mesh.get_surface_count()
	
	for surface_idx in range(surface_count):
		if _apply_shader_to_surface(mesh_instance, surface_idx, shader_settings):
			surfaces_processed += 1
	
	return surfaces_processed


func _reapply_shader_after_model_change():
	"""Re-aplicar shader después de cambiar modelo"""
	if not current_shader_settings.is_empty() and current_model:
		print("🔄 Re-aplicando shader al nuevo modelo...")
		apply_advanced_shader(current_shader_settings)




func _apply_3d_outline(shader_settings: Dictionary):
	"""Aplicar outline 3D real expandiendo vertices"""
	if not current_model:
		return
	
	print("🔲 Aplicando outline 3D...")
	
	# Buscar si ya existe outline
	var outline_node = current_model.find_child("Outline3D", false)
	
	if not outline_node:
		# Crear nuevo outline duplicando el modelo
		outline_node = current_model.duplicate()
		outline_node.name = "Outline3D"
		current_model.add_child(outline_node)
		
		# Configurar para que se renderice primero (detrás)
		outline_node.position = current_model.position
		outline_node.rotation = current_model.rotation
		outline_node.scale = current_model.scale
	
	# Aplicar outline shader a todas las mesh instances del outline
	var outline_meshes = _find_all_mesh_instances_in_model(outline_node)
	
	for mesh_instance in outline_meshes:
		# Crear material de outline para cada superficie
		for surface_idx in range(mesh_instance.mesh.get_surface_count() if mesh_instance.mesh else 0):
			var outline_material = _create_outline_material(shader_settings)
			mesh_instance.set_surface_override_material(surface_idx, outline_material)
	
	outline_3d_enabled = true
	print("✅ Outline 3D aplicado con %d mesh instances" % outline_meshes.size())
	
	
	
func _create_outline_material(shader_settings: Dictionary) -> ShaderMaterial:
	"""Crear material específico para outline 3D"""
	var outline_material = ShaderMaterial.new()
	
	# Cargar shader de outline 3D
	var outline_shader_path = "res://resources/shaders/outline_3d.gdshader"
	if ResourceLoader.exists(outline_shader_path):
		outline_material.shader = load(outline_shader_path)
	else:
		print("❌ Shader de outline 3D no encontrado: %s" % outline_shader_path)
		return null
	
	# Configurar parámetros del outline
	outline_material.set_shader_parameter("outline_color", shader_settings.get("outline_color", Color.BLACK))
	outline_material.set_shader_parameter("outline_thickness", shader_settings.get("outline_thickness", 1.0) * 0.01)
	outline_material.set_shader_parameter("outline_pixelated", shader_settings.get("outline_pixelated", true))
	outline_material.set_shader_parameter("pixel_size", shader_settings.get("pixel_size", 4.0))
	
	# Configurar render priority para que se dibuje primero
	outline_material.set("render_priority", -1)
	
	return outline_material
	
	
func _clear_3d_outline():
	"""Eliminar outline 3D del modelo"""
	if not current_model:
		return
	
	var outline_node = current_model.find_child("Outline3D", false)
	if outline_node:
		outline_node.queue_free()
		outline_3d_enabled = false
		print("🧹 Outline 3D eliminado")




func _find_all_mesh_instances_in_model(model: Node3D) -> Array:
	"""Encontrar recursivamente todas las MeshInstance3D"""
	var mesh_instances = []
	
	if model is MeshInstance3D:
		mesh_instances.append(model)
	
	for child in model.get_children():
		if child is Node3D and child.name != "Outline3D":  # Evitar recursión infinita
			mesh_instances.append_array(_find_all_mesh_instances_in_model(child))
	
	return mesh_instances
	
	# Si el nodo actual es MeshInstance3D, agregarlo
	if model is MeshInstance3D:
		mesh_instances.append(model)
	
	# Buscar recursivamente en todos los hijos
	for child in model.get_children():
		if child is Node3D:
			mesh_instances.append_array(_find_all_mesh_instances_in_model(child))
	
	return mesh_instances

func _apply_shader_to_surface(mesh_instance: MeshInstance3D, surface_idx: int, shader_settings: Dictionary) -> bool:
	"""Aplicar shader a una superficie específica"""
	var target_material = null
	
	# Obtener o crear material
	var surface_override = mesh_instance.get_surface_override_material(surface_idx)
	if surface_override:
		target_material = surface_override
	elif mesh_instance.mesh.surface_get_material(surface_idx):
		target_material = mesh_instance.mesh.surface_get_material(surface_idx).duplicate()
		mesh_instance.set_surface_override_material(surface_idx, target_material)
	else:
		target_material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(surface_idx, target_material)
	
	# Convertir a ShaderMaterial
	var shader_material = _convert_to_shader_material(target_material, mesh_instance, surface_idx)
	if not shader_material:
		return false
	
	# Cargar shader
	if not _ensure_advanced_shader_loaded(shader_material):
		return false
	
	# Aplicar parámetros
	_apply_shader_parameters(shader_material, shader_settings)
	
	return true

func _convert_to_shader_material(material: Material, mesh_instance: MeshInstance3D, surface_idx: int) -> ShaderMaterial:
	"""Convertir material a ShaderMaterial preservando propiedades"""
	if material is ShaderMaterial:
		return material as ShaderMaterial
	
	var shader_material = ShaderMaterial.new()
	
	# Preservar propiedades de StandardMaterial3D
	if material is StandardMaterial3D:
		var std_material = material as StandardMaterial3D
		if std_material.albedo_texture:
			shader_material.set_shader_parameter("main_texture", std_material.albedo_texture)
		if std_material.albedo_color != Color.WHITE:
			shader_material.set_shader_parameter("base_color", std_material.albedo_color)
	
	mesh_instance.set_surface_override_material(surface_idx, shader_material)
	return shader_material

func _ensure_advanced_shader_loaded(shader_material: ShaderMaterial) -> bool:
	"""Cargar shader avanzado si no está cargado"""
	var shader_path = "res://resources/shaders/pixelize_spatial.gdshader"
	
	if shader_material.shader and shader_material.shader.resource_path == shader_path:
		return true
	
	if ResourceLoader.exists(shader_path):
		var advanced_shader = load(shader_path) as Shader
		if advanced_shader:
			shader_material.shader = advanced_shader
			return true
	
	print("❌ No se pudo cargar shader: %s" % shader_path)
	return false

## FUNCIÓN AUXILIAR: Asegurar que el shader avanzado esté cargado
#func _ensure_advanced_shader_loaded(shader_material: ShaderMaterial) -> bool:
	#"""Asegurar que el shader avanzado esté cargado en el material"""
	#var shader_path = "res://resources/shaders/pixelize_advanced_improved.gdshader"
	#
	## Si ya tiene el shader correcto, retornar true
	#if shader_material.shader and shader_material.shader.resource_path == shader_path:
		#return true
	#
	## Cargar el shader avanzado
	#if ResourceLoader.exists(shader_path):
		#var advanced_shader = load(shader_path) as Shader
		#if advanced_shader:
			#shader_material.shader = advanced_shader
			#print("       🔧 Shader avanzado cargado desde: %s" % shader_path)
			#return true
		#else:
			#print("       ❌ Error: No se pudo cargar como Shader: %s" % shader_path)
			#return false
	#else:
		#print("       ❌ Error: Archivo de shader no encontrado: %s" % shader_path)
		#return false

func _apply_shader_parameters(shader_material: ShaderMaterial, shader_settings: Dictionary):
	"""Aplicar parámetros del shader al material"""
	# Parámetros básicos
	shader_material.set_shader_parameter("pixel_size", shader_settings.get("pixel_size", 4.0))
	shader_material.set_shader_parameter("reduce_colors", shader_settings.get("reduce_colors", false))
	shader_material.set_shader_parameter("color_levels", shader_settings.get("color_levels", 16))
	shader_material.set_shader_parameter("enable_dithering", shader_settings.get("enable_dithering", false))
	shader_material.set_shader_parameter("dither_strength", shader_settings.get("dither_strength", 0.1))
	
	# Parámetros de efectos avanzados
	shader_material.set_shader_parameter("contrast_boost", shader_settings.get("contrast_boost", 1.0))
	shader_material.set_shader_parameter("saturation_mult", shader_settings.get("saturation_mult", 1.0))
	shader_material.set_shader_parameter("color_tint", shader_settings.get("color_tint", Color.WHITE))
	shader_material.set_shader_parameter("apply_gamma_correction", shader_settings.get("apply_gamma_correction", false))
	shader_material.set_shader_parameter("gamma_value", shader_settings.get("gamma_value", 1.0))
# FUNCIÓN PÚBLICA: Re-aplicar shader cuando cambie el modelo - SIN EFECTOS DE CAMARA
func _on_model_changed_reapply_shader():
	"""Re-aplicar shader cuando el modelo cambia (llamar en show_model)"""
	if not current_shader_settings.is_empty() and current_model:
		print("🔄 Re-aplicando shader al nuevo modelo...")
		apply_advanced_shader(current_shader_settings)
		# ❌ NO emitir señales que muevan la cámara



# FUNCIÓN PÚBLICA: Obtener estado del shader
func get_shader_status() -> Dictionary:
	"""Obtener información del estado actual del shader"""
	return {
		"shader_applied": shader_applied_to_model,
		"settings_count": current_shader_settings.size(),
		"has_model": current_model != null,
		"model_name": current_model.name if current_model else ""
	}



func debug_shader_state():
	pass
	#"""Debug del estado del shader en el modelo"""
	#print("\n🔍 === DEBUG SHADER ESTADO ===")
	#print("Modelo: %s" % (current_model.name if current_model else "NINGUNO"))
	#print("Shader aplicado: %s" % shader_applied_to_model)
	#print("Outline 3D: %s" % outline_3d_enabled)
	#print("Configuración: %d parámetros" % current_shader_settings.size())
	#
	#if current_model:
		#var outline_node = current_model.find_child("Outline3D", false)
		#print("Nodo Outline3D: %s" % ("SÍ" if outline_node else "NO"))
	#
	#print("============================\n")
#


# ========================================================================
# SISTEMA DE POST-PROCESSING (NUEVO)
# ========================================================================

func setup_postprocessing_system():
	"""Configurar sistema de post-processing en el viewport"""
	if not viewport:
		print("❌ No hay viewport para configurar post-processing")
		return
	
	# Crear quad mesh para post-processing si no existe
	if not postprocess_quad:
		_create_postprocess_quad()
	
	print("✅ Sistema de post-processing configurado")

func _create_postprocess_quad():
	"""Crear quad mesh para post-processing"""
	if not viewport:
		return
	
	# Crear MeshInstance3D con QuadMesh
	postprocess_quad = MeshInstance3D.new()
	postprocess_quad.name = "PostProcessQuad"
	
	# Configurar QuadMesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(2, 2)  # Tamaño que cubre toda la pantalla
	postprocess_quad.mesh = quad_mesh
	
	# Crear material con shader de post-processing
	postprocess_material = ShaderMaterial.new()
	var shader = load("res://resources/shaders/pixelize_postprocess.gdshader")
	if shader:
		postprocess_material.shader = shader
		postprocess_quad.material_override = postprocess_material
	
	# Posicionar el quad para que cubra toda la pantalla
	postprocess_quad.position = Vector3(0, 0, -1)  # Frente a la cámara
	
	# Añadir al viewport (pero deshabilitado inicialmente)
	viewport.add_child(postprocess_quad)
	postprocess_quad.visible = false
	
	print("✅ Quad de post-processing creado")


func _apply_postprocess_parameters(settings: Dictionary):
	"""Aplicar parámetros específicos al shader de post-processing"""
	if not postprocess_material:
		return
	
	# Parámetros principales
	postprocess_material.set_shader_parameter("pixelize_enabled", settings.get("pixelize_enabled", false))
	postprocess_material.set_shader_parameter("pixel_size", settings.get("pixel_size", 4.0))
	
	# Reducción de colores
	postprocess_material.set_shader_parameter("reduce_colors", settings.get("reduce_colors", false))
	postprocess_material.set_shader_parameter("color_levels", settings.get("color_levels", 16))
	
	# Dithering
	postprocess_material.set_shader_parameter("enable_dithering", settings.get("enable_dithering", false))
	postprocess_material.set_shader_parameter("dither_strength", settings.get("dither_strength", 0.1))
	
	# Efectos avanzados
	postprocess_material.set_shader_parameter("contrast_enabled", settings.get("contrast_enabled", false))
	postprocess_material.set_shader_parameter("contrast_boost", settings.get("contrast_boost", 1.0))
	postprocess_material.set_shader_parameter("saturation_enabled", settings.get("saturation_enabled", false))
	postprocess_material.set_shader_parameter("saturation_mult", settings.get("saturation_mult", 1.0))
	postprocess_material.set_shader_parameter("tint_enabled", settings.get("tint_enabled", false))
	postprocess_material.set_shader_parameter("color_tint", settings.get("color_tint", Color.WHITE))
	
	print("📝 Parámetros de post-processing aplicados")


func _save_viewport_state():
	"""Guardar estado anterior del viewport"""
	previous_viewport_state = {
		"timestamp": Time.get_unix_time_from_system(),
		"postprocess_was_enabled": postprocess_enabled
	}
	print("💾 Estado anterior del viewport guardado")

func _restore_viewport_state():
	"""Restaurar estado anterior del viewport"""
	if previous_viewport_state.is_empty():
		print("⚠️ No hay estado anterior para restaurar")
		return
	
	print("🔄 Estado anterior del viewport restaurado")
	previous_viewport_state.clear()








func setup_canvas_postprocessing():
	"""Configurar sistema de post-processing canvas en el ViewportContainer"""
	if not viewport_container:
		print("❌ No hay ViewportContainer para configurar post-processing")
		return
	
	# Crear material de post-processing si no existe
	if not postprocess_material:
		_create_canvas_postprocess_material()
	
	print("✅ Sistema de post-processing canvas configurado")

func _create_canvas_postprocess_material():
	"""Crear material con shader canvas para post-processing"""
	postprocess_material = ShaderMaterial.new()
	
	# Cargar shader canvas
	var shader = load("res://resources/shaders/pixelize_postprocess.gdshader")
	if shader:
		postprocess_material.shader = shader
		print("✅ Shader canvas de post-processing cargado")
	else:
		print("❌ No se pudo cargar shader canvas: pixelize_postprocess.gdshader")
		return
	
	# Configurar parámetros por defecto
	postprocess_material.set_shader_parameter("pixelize_enabled", false)
	postprocess_material.set_shader_parameter("pixel_size", 4.0)
	postprocess_material.set_shader_parameter("reduce_colors", false)
	postprocess_material.set_shader_parameter("color_levels", 16)
	postprocess_material.set_shader_parameter("enable_dithering", false)
	postprocess_material.set_shader_parameter("dither_strength", 0.1)
	postprocess_material.set_shader_parameter("contrast_enabled", false)
	postprocess_material.set_shader_parameter("contrast_boost", 1.0)
	postprocess_material.set_shader_parameter("saturation_enabled", false)
	postprocess_material.set_shader_parameter("saturation_mult", 1.0)
	postprocess_material.set_shader_parameter("tint_enabled", false)
	postprocess_material.set_shader_parameter("color_tint", Color.WHITE)

func apply_postprocessing(settings: Dictionary):
	"""Aplicar configuración de post-processing canvas"""
	if not postprocess_material:
		setup_canvas_postprocessing()
		if not postprocess_material:
			print("❌ No se pudo configurar sistema de post-processing canvas")
			return
	
	# Guardar material original si no está guardado
	if not postprocess_enabled and viewport_container.material == null:
		original_material = viewport_container.material
	
	# Aplicar parámetros al shader
	_apply_canvas_postprocess_parameters(settings)
	
	# Activar/desactivar post-processing
	var enable_effect = settings.get("pixelize_enabled", false)
	
	if enable_effect:
		# Aplicar material de post-processing al ViewportContainer
		viewport_container.material = postprocess_material
		postprocess_enabled = true
		print("✅ Post-processing canvas activado en ViewportContainer")
	else:
		# Restaurar material original
		viewport_container.material = original_material
		postprocess_enabled = false
		print("🧹 Post-processing canvas desactivado")

func _apply_canvas_postprocess_parameters(settings: Dictionary):
	"""Aplicar parámetros específicos al shader canvas"""
	if not postprocess_material:
		return
	
	# Parámetros principales
	postprocess_material.set_shader_parameter("pixelize_enabled", settings.get("pixelize_enabled", false))
	postprocess_material.set_shader_parameter("pixel_size", settings.get("pixel_size", 4.0))
	
	# Reducción de colores
	postprocess_material.set_shader_parameter("reduce_colors", settings.get("reduce_colors", false))
	postprocess_material.set_shader_parameter("color_levels", settings.get("color_levels", 16))
	
	# Dithering
	postprocess_material.set_shader_parameter("enable_dithering", settings.get("enable_dithering", false))
	postprocess_material.set_shader_parameter("dither_strength", settings.get("dither_strength", 0.1))
	
	# Efectos avanzados
	postprocess_material.set_shader_parameter("contrast_enabled", settings.get("contrast_enabled", false))
	postprocess_material.set_shader_parameter("contrast_boost", settings.get("contrast_boost", 1.0))
	postprocess_material.set_shader_parameter("saturation_enabled", settings.get("saturation_enabled", false))
	postprocess_material.set_shader_parameter("saturation_mult", settings.get("saturation_mult", 1.0))
	postprocess_material.set_shader_parameter("tint_enabled", settings.get("tint_enabled", false))
	postprocess_material.set_shader_parameter("color_tint", settings.get("color_tint", Color.WHITE))
	
	print("📝 Parámetros de post-processing canvas aplicados")

func clear_postprocessing():
	"""Limpiar post-processing canvas y volver al estado anterior"""
	if viewport_container:
		viewport_container.material = original_material
	
	postprocess_enabled = false
	print("🧹 Post-processing canvas limpiado, estado anterior restaurado")

func get_postprocess_status() -> Dictionary:
	"""Obtener estado del sistema de post-processing canvas"""
	return {
		"enabled": postprocess_enabled,
		"material_exists": postprocess_material != null,
		"viewport_container_exists": viewport_container != null,
		"current_material": viewport_container.material.get_class() if viewport_container and viewport_container.material else "null"
	}

# ========================================================================
# REEMPLAZAR ESTAS FUNCIONES EXISTENTES
# ========================================================================

func apply_advanced_shader(shader_settings: Dictionary):
	"""Aplicar shader usando post-processing canvas"""
	current_shader_settings = shader_settings.duplicate()
	
	# Forzar que sea post-processing
	current_shader_settings["post_processing"] = true
	
	# Aplicar post-processing canvas
	apply_postprocessing(current_shader_settings)
	
	shader_applied_to_model = true
	print("✅ Shader aplicado usando post-processing canvas")

func clear_advanced_shader():
	"""Limpiar shader avanzado"""
	clear_postprocessing()
	
	current_shader_settings.clear()
	shader_applied_to_model = false
	postprocess_enabled = false
	
	print("✅ Shader canvas limpiado")
