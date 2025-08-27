# pixelize3d_fbx/scripts/transition/transition_preview_system.gd
# Input: Modelos 3D con animaciones, datos de transición
# Output: Previsualización visual con frames estáticos y animación de transición

extends Control

# Señales
signal preview_ready()
signal transition_animation_started()
signal transition_animation_stopped()

# Referencias a UI
var first_animation_preview: TextureRect
var transition_animation_preview: SubViewportContainer
var last_animation_preview: TextureRect

# Viewports para rendering
var first_frame_viewport: SubViewport
var transition_viewport: SubViewport 
var last_frame_viewport: SubViewport

# Datos del sistema
var first_animation_data: Dictionary = {}
var last_animation_data: Dictionary = {}
var transition_model: Node3D = null
var is_transition_playing: bool = false

# Configuración de renderizado
const PREVIEW_SIZE = Vector2i(128, 128)
const CAMERA_DISTANCE = 8.0
const CAMERA_HEIGHT = 6.0
const CAMERA_ANGLE = -25.0

func _ready():
	print("🎬 TransitionPreviewSystem inicializado")
	_setup_preview_ui()
	_setup_viewports()

# ========================================================================
# CONFIGURACIÓN DE UI
# ========================================================================

func _setup_preview_ui():
	"""Configurar la interfaz de previsualización"""
	custom_minimum_size = Vector2(280, 400)  # Más alto para 3 secciones
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var main_vbox = VBoxContainer.new()
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	add_child(main_vbox)
	
	# === SECCIÓN SUPERIOR: ÚLTIMO FRAME DE PRIMERA ANIMACIÓN ===
	var first_section = _create_preview_section("Fin de Primera Animación", Color(0.2, 0.6, 0.8))
	main_vbox.add_child(first_section)
	
	first_animation_preview = TextureRect.new()
	first_animation_preview.custom_minimum_size = Vector2(PREVIEW_SIZE.x, PREVIEW_SIZE.y)
	first_animation_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	first_animation_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	first_section.add_child(first_animation_preview)
	
	# === SECCIÓN CENTRAL: ANIMACIÓN DE TRANSICIÓN ===
	var transition_section = _create_preview_section("Transición (En Vivo)", Color(0.8, 0.4, 0.2))
	main_vbox.add_child(transition_section)
	
	transition_animation_preview = SubViewportContainer.new()
	transition_animation_preview.custom_minimum_size = Vector2(PREVIEW_SIZE.x, PREVIEW_SIZE.y)
	transition_animation_preview.stretch = true
	transition_section.add_child(transition_animation_preview)
	
	# === SECCIÓN INFERIOR: PRIMER FRAME DE ÚLTIMA ANIMACIÓN ===
	var last_section = _create_preview_section("Inicio de Última Animación", Color(0.6, 0.8, 0.3))
	main_vbox.add_child(last_section)
	
	last_animation_preview = TextureRect.new()
	last_animation_preview.custom_minimum_size = Vector2(PREVIEW_SIZE.x, PREVIEW_SIZE.y)
	last_animation_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	last_animation_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	last_section.add_child(last_animation_preview)
	
	# === CONTROLES DE TRANSICIÓN ===
	var controls_section = _create_controls_section()
	main_vbox.add_child(controls_section)

func _create_preview_section(title: String, color: Color) -> VBoxContainer:
	"""Crear sección de previsualización con título"""
	var section = VBoxContainer.new()
	section.custom_minimum_size.y = 150
	
	# Título con color
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(title_label)
	
	# Separador visual
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", color)
	section.add_child(separator)
	
	return section

func _create_controls_section() -> VBoxContainer:
	"""Crear sección de controles"""
	var controls_section = VBoxContainer.new()
	controls_section.custom_minimum_size.y = 80
	
	var controls_label = Label.new()
	controls_label.text = "Controles de Transición"
	controls_label.add_theme_font_size_override("font_size", 9)
	controls_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_section.add_child(controls_label)
	
	var controls_hbox = HBoxContainer.new()
	controls_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_section.add_child(controls_hbox)
	
	# Botón Play/Pause
	var play_button = Button.new()
	play_button.text = "▶️"
	play_button.custom_minimum_size = Vector2(30, 30)
	play_button.pressed.connect(_on_play_pause_pressed)
	controls_hbox.add_child(play_button)
	
	# Botón Stop
	var stop_button = Button.new()
	stop_button.text = "⏹️"
	stop_button.custom_minimum_size = Vector2(30, 30)
	stop_button.pressed.connect(_on_stop_pressed)
	controls_hbox.add_child(stop_button)
	
	# Botón Reset
	var reset_button = Button.new()
	reset_button.text = "🔄"
	reset_button.custom_minimum_size = Vector2(30, 30)
	reset_button.pressed.connect(_on_reset_pressed)
	controls_hbox.add_child(reset_button)
	
	return controls_section

# ========================================================================
# CONFIGURACIÓN DE VIEWPORTS
# ========================================================================

func _setup_viewports():
	"""Configurar viewports para rendering"""
	print("🖼️ Configurando viewports para previsualización...")
	
	# === VIEWPORT PARA PRIMER FRAME ===
	first_frame_viewport = SubViewport.new()
	first_frame_viewport.size = PREVIEW_SIZE
	first_frame_viewport.transparent_bg = true
	first_frame_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(first_frame_viewport)
	
	# === VIEWPORT PARA TRANSICIÓN (EN VIVO) ===
	transition_viewport = SubViewport.new()
	transition_viewport.size = PREVIEW_SIZE
	transition_viewport.transparent_bg = true
	transition_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	transition_animation_preview.add_child(transition_viewport)
	
	# === VIEWPORT PARA ÚLTIMO FRAME ===
	last_frame_viewport = SubViewport.new()
	last_frame_viewport.size = PREVIEW_SIZE
	last_frame_viewport.transparent_bg = true
	last_frame_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(last_frame_viewport)
	
	# Configurar cámaras para cada viewport
	_setup_viewport_cameras()

func _setup_viewport_cameras():
	"""Configurar cámaras para todos los viewports"""
	# Cámara para primer frame
	var first_camera = Camera3D.new()
	first_camera.name = "FirstFrameCamera"
	_configure_camera(first_camera)
	first_frame_viewport.add_child(first_camera)
	
	# Cámara para transición
	var transition_camera = Camera3D.new()
	transition_camera.name = "TransitionCamera" 
	_configure_camera(transition_camera)
	transition_viewport.add_child(transition_camera)
	
	# Cámara para último frame
	var last_camera = Camera3D.new()
	last_camera.name = "LastFrameCamera"
	_configure_camera(last_camera)
	last_frame_viewport.add_child(last_camera)
	
	# Iluminación para cada viewport
	_add_lighting_to_viewport(first_frame_viewport)
	_add_lighting_to_viewport(transition_viewport)
	_add_lighting_to_viewport(last_frame_viewport)

func _configure_camera(camera: Camera3D):
	"""Configurar cámara isométrica"""
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	camera.rotation_degrees = Vector3(CAMERA_ANGLE, 0, 0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.0  # Zoom apropiado para modelos de personajes

func _add_lighting_to_viewport(viewport: SubViewport):
	"""Añadir iluminación básica al viewport"""
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.position = Vector3(2, 4, 2)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 0.8
	light.shadow_enabled = false  # Sin sombras para mejor performance
	viewport.add_child(light)

# ========================================================================
# FUNCIONES PRINCIPALES DE PREVISUALIZACIÓN
# ========================================================================

func setup_transition_preview(first_anim_data: Dictionary, last_anim_data: Dictionary, transition_frames: Array):
	"""Configurar previsualización completa de transición"""
	print("🎬 === CONFIGURANDO PREVISUALIZACIÓN DE TRANSICIÓN ===")
	print("Primera animación: %s" % first_anim_data.get("name", "Unknown"))
	print("Última animación: %s" % last_anim_data.get("name", "Unknown"))
	print("Frames de transición: %d" % transition_frames.size())
	
	# Guardar datos
	first_animation_data = first_anim_data
	last_animation_data = last_anim_data
	
	# 1. Capturar último frame de primera animación
	await _capture_first_animation_end_frame()
	
	# 2. Configurar animación de transición en vivo
	await _setup_live_transition_animation(transition_frames)
	
	# 3. Capturar primer frame de última animación
	await _capture_last_animation_start_frame()
	
	print("✅ Previsualización de transición configurada")
	emit_signal("preview_ready")

func _capture_first_animation_end_frame():
	"""Capturar último frame de la primera animación"""
	print("📸 Capturando último frame de primera animación...")
	
	if not first_animation_data.has("model") or not first_animation_data.model:
		print("❌ No hay modelo en primera animación")
		return
	
	# Duplicar modelo para renderizado estático
	var static_model = first_animation_data.model.duplicate()
	first_frame_viewport.add_child(static_model)
	
	# Buscar AnimationPlayer
	var anim_player = _find_animation_player(static_model)
	if anim_player and anim_player.get_animation_list().size() > 0:
		var anim_name = anim_player.get_animation_list()[0]
		var animation = anim_player.get_animation(anim_name)
		
		# Ir al último frame
		if animation:
			anim_player.play(anim_name)
			anim_player.seek(animation.length, true)  # Ir al final
			anim_player.pause()
	
	# Esperar y capturar
	await get_tree().process_frame
	await get_tree().process_frame
	
	var texture = first_frame_viewport.get_texture()
	if texture:
		first_animation_preview.texture = texture
		print("✅ Último frame capturado")
	
	# Limpiar
	static_model.queue_free()

func _setup_live_transition_animation(transition_frames: Array):
	"""Configurar animación de transición en vivo"""
	print("🎭 Configurando animación de transición en vivo...")
	
	# Usar el transition_coordinator para crear el modelo
	var coordinator = get_node_or_null("../TransitionCoordinator")
	if coordinator and coordinator.has_method("create_transition_model"):
		transition_model = coordinator.create_transition_model(transition_frames)
	
	if not transition_model:
		print("❌ No se pudo crear modelo de transición")
		return
	
	# Añadir modelo al viewport de transición
	transition_viewport.add_child(transition_model)
	
	# El modelo ya debería estar reproduciéndose automáticamente
	print("✅ Animación de transición configurada")

func _capture_last_animation_start_frame():
	"""Capturar primer frame de la última animación"""
	print("📸 Capturando primer frame de última animación...")
	
	if not last_animation_data.has("model") or not last_animation_data.model:
		print("❌ No hay modelo en última animación")
		return
	
	# Duplicar modelo para renderizado estático
	var static_model = last_animation_data.model.duplicate()
	last_frame_viewport.add_child(static_model)
	
	# Buscar AnimationPlayer
	var anim_player = _find_animation_player(static_model)
	if anim_player and anim_player.get_animation_list().size() > 0:
		var anim_name = anim_player.get_animation_list()[0]
		
		# Ir al primer frame
		anim_player.play(anim_name)
		anim_player.seek(0.0, true)  # Ir al inicio
		anim_player.pause()
	
	# Esperar y capturar
	await get_tree().process_frame
	await get_tree().process_frame
	
	var texture = last_frame_viewport.get_texture()
	if texture:
		last_animation_preview.texture = texture
		print("✅ Primer frame capturado")
	
	# Limpiar
	static_model.queue_free()

# ========================================================================
# CONTROLES DE REPRODUCCIÓN
# ========================================================================

func _on_play_pause_pressed():
	"""Manejar play/pause de la transición"""
	if not transition_model:
		print("⚠️ No hay modelo de transición")
		return
	
	var anim_player = _find_animation_player(transition_model)
	if not anim_player:
		return
	
	if is_transition_playing:
		anim_player.pause()
		is_transition_playing = false
		print("⏸️ Transición pausada")
		emit_signal("transition_animation_stopped")
	else:
		if anim_player.is_playing():
			anim_player.play()
		else:
			anim_player.play("transition")
		is_transition_playing = true
		print("▶️ Transición reproduciéndose")
		emit_signal("transition_animation_started")

func _on_stop_pressed():
	"""Detener transición y volver al inicio"""
	if not transition_model:
		return
	
	var anim_player = _find_animation_player(transition_model)
	if anim_player:
		anim_player.stop()
		anim_player.seek(0.0, true)
		is_transition_playing = false
		print("⏹️ Transición detenida")
		emit_signal("transition_animation_stopped")

func _on_reset_pressed():
	"""Reset completo de la previsualización"""
	print("🔄 Reseteando previsualización...")
	
	# Limpiar modelo de transición
	if transition_model and is_instance_valid(transition_model):
		transition_model.queue_free()
		transition_model = null
	
	# Limpiar texturas
	first_animation_preview.texture = null
	last_animation_preview.texture = null
	
	# Reset estado
	is_transition_playing = false
	first_animation_data.clear()
	last_animation_data.clear()
	
	print("✅ Previsualización reseteada")

# ========================================================================
# FUNCIONES DE UTILIDAD
# ========================================================================

func _find_animation_player(model: Node3D) -> AnimationPlayer:
	"""Buscar AnimationPlayer en modelo recursivamente"""
	if model is AnimationPlayer:
		return model
	
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func set_preview_quality(quality: String):
	"""Configurar calidad de previsualización"""
	var size_multiplier = 1.0
	match quality:
		"low":
			size_multiplier = 0.5
		"medium":
			size_multiplier = 1.0
		"high":
			size_multiplier = 1.5
	
	var new_size = Vector2i(PREVIEW_SIZE.x * size_multiplier, PREVIEW_SIZE.y * size_multiplier)
	
	if first_frame_viewport:
		first_frame_viewport.size = new_size
	if transition_viewport:
		transition_viewport.size = new_size
	if last_frame_viewport:
		last_frame_viewport.size = new_size

func get_transition_status() -> Dictionary:
	"""Obtener estado actual de la transición"""
	return {
		"is_playing": is_transition_playing,
		"has_transition_model": transition_model != null,
		"first_frame_captured": first_animation_preview.texture != null,
		"last_frame_captured": last_animation_preview.texture != null,
		"ready": (first_animation_preview.texture != null and 
				 last_animation_preview.texture != null and 
				 transition_model != null)
	}
