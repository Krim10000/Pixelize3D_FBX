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
@onready var directional_light = $ViewportContainer/SubViewport/DirectionalLight3D
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

func _ready():
	print("🎬 ModelPreviewPanel MEJORADO inicializado")
	_setup_ui()
	_connect_signals()
	
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
	
	status_label.text = "Esperando modelo..."
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	controls_help_label.text = "CONTROLES: Click+Arrastrar=Rotar | Rueda=Zoom | Shift+Click=Panear"
	controls_help_label.add_theme_font_size_override("font_size", 9)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false

func _connect_signals():
	"""Conectar señales entre componentes"""
	if camera_controller and camera_controller.has_signal("camera_ready"):
		camera_controller.connect("camera_ready", _on_camera_ready)
	
	if model_rotator and model_rotator.has_signal("north_changed"):
		model_rotator.connect("north_changed", _on_north_changed)

# === GESTIÓN DEL MODELO ===

func set_model(model: Node3D):
	"""✅ MEJORADO: Configurar modelo para preview"""
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
	
	# Duplicar modelo para preview
	current_model = model.duplicate()
	current_model.name = "Preview_" + model.name
	model_container.add_child(current_model)
	
	# Buscar AnimationPlayer
	animation_player = _find_animation_player(current_model)
	
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
	
	# Actualizar UI
	status_label.text = "Modelo: " + model.name
	controls_help_label.visible = true
	preview_active = true
	
	emit_signal("preview_ready")

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
	print("📷 Cámara lista")
	# NO llamar a ninguna función de configuración de cámara aquí
	# Eso causaría recursión infinita
	
	# La cámara ya fue configurada cuando se emitió esta señal
	# Solo hacer tareas que no involucren reconfigurar la cámara:
	
	# Actualizar UI
	if preview_active:
		controls_help_label.visible = true
		status_label.text = "Vista previa activa"
		
func _on_north_changed(new_north: float):
	"""Callback cuando cambia la orientación norte"""
	print("🧭 Norte actualizado: %.1f°" % new_north)

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
	
	print("🔄 Loops configurados para %d animaciones" % anim_list.size())

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
		var size = current_bounds.get_longest_axis_size()
		camera.position = center + Vector3(size, size, size)
		camera.look_at(center, Vector3.UP)

# === DEBUG ===

func debug_state():
	"""Debug del estado actual"""
	print("\n🎬 === MODEL PREVIEW DEBUG ===")
	print("Preview activo: %s" % preview_active)
	print("Modelo: %s" % (current_model.name if current_model else "NULL"))
	print("AnimationPlayer: %s" % (animation_player.name if animation_player else "NULL"))
	if animation_player:
		print("  Animaciones: %s" % str(animation_player.get_animation_list()))
		print("  Reproduciendo: %s" % is_animation_playing)
		print("  Actual: %s" % current_animation_name)
	print("Bounds: %s" % str(current_bounds))
	print("============================\n")
