# res://scripts/transition/Columna2_UI.gd
# Interfaz de usuario para preview de animaciones - Columna 2
# Input: Controles del usuario para reproducir/pausar animaciones
# Output: Señales de control de reproducción y actualización visual

extends VBoxContainer
class_name Columna2UI

# === SEÑALES HACIA LA LÓGICA ===
signal play_animation_a_requested()
signal pause_animation_a_requested()
signal play_animation_b_requested()
signal pause_animation_b_requested()

# === REFERENCIAS UI ===
var anim_a_viewport: SubViewport
var anim_b_viewport: SubViewport
var anim_a_container: SubViewportContainer
var anim_b_container: SubViewportContainer

# Controles dinámicos
var controls_container: VBoxContainer
var animation_a_controls: PanelContainer
var animation_b_controls: PanelContainer

# Controles Animation A
var play_button_a: Button
var pause_button_a: Button
var anim_name_label_a: Label
var frame_label_a: Label
var duration_label_a: Label

# Controles Animation B
var play_button_b: Button
var pause_button_b: Button
var anim_name_label_b: Label
var frame_label_b: Label
var duration_label_b: Label

# === ESTADO INTERNO ===
var animations_loaded: bool = false

func _ready():
	print("🎮 Columna2UI inicializando...")
	_get_viewport_references()
	_create_ui_controls()
	_connect_internal_signals()
	_setup_initial_state()
	print("✅ Columna2UI lista")

func _get_viewport_references():
	"""Obtener referencias a viewports existentes en la escena"""
	print("🔍 Obteniendo referencias de viewports...")
	
	# Navegar hacia arriba para encontrar los containers
	var main_node = get_parent()
	while main_node and not main_node.name == "Columna2_Container":
		main_node = main_node.get_parent()
	
	if main_node:
		# Buscar SubViewportContainers
		anim_a_container = main_node.get_node("%SubViewportContainer_A")
		anim_b_container = main_node.get_node("%SubViewportContainer_B")
		
		# Obtener viewports desde los containers
		if anim_a_container:
			anim_a_viewport = anim_a_container.get_node("SubViewport_A")
			print("  ✅ Viewport A encontrado")
		
		if anim_b_container:
			anim_b_viewport = anim_b_container.get_node("SubViewport_B")
			print("  ✅ Viewport B encontrado")
	
	if not anim_a_viewport or not anim_b_viewport:
		print("  ⚠️ No se encontraron todos los viewports")

func _create_ui_controls():
	"""Crear controles de UI para preview"""
	print("🎨 Creando controles de UI...")
	
	# Título de la columna
	var title = Label.new()
	title.text = "🎬 PREVIEW ANIMACIONES"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	add_child(HSeparator.new())
	
	# Container principal para controles
	controls_container = VBoxContainer.new()
	controls_container.add_theme_constant_override("separation", 10)
	add_child(controls_container)
	
	# === CONTROLES ANIMACIÓN A ===
	animation_a_controls = _create_animation_control_panel("A")
	controls_container.add_child(animation_a_controls)
	#controls_container.add_child(anim_a_viewport)
	
	# === CONTROLES ANIMACIÓN B ===
	animation_b_controls = _create_animation_control_panel("B")
	controls_container.add_child(animation_b_controls)
	#controls_container.add_child(anim_b_viewport)
	
	print("✅ Controles de UI creados")

func _create_animation_control_panel(anim_id: String) -> PanelContainer:
	"""Crear panel de control para una animación"""
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Título del panel
	var title_container = HBoxContainer.new()
	var title = Label.new()
	title.text = "Animación %s" % anim_id
	title.add_theme_font_size_override("font_size", 12)
	title_container.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(spacer)
	
	vbox.add_child(title_container)
	vbox.add_child(HSeparator.new())
	
	# Controles de reproducción
	var controls_hbox = HBoxContainer.new()
	controls_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_hbox.add_theme_constant_override("separation", 5)
	
	# Botón Play
	var play_button = Button.new()
	play_button.text = "▶"
	play_button.tooltip_text = "Reproducir animación %s" % anim_id
	play_button.custom_minimum_size = Vector2(40, 30)
	controls_hbox.add_child(play_button)
	
	# Botón Pause
	var pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.tooltip_text = "Pausar animación %s" % anim_id
	pause_button.custom_minimum_size = Vector2(40, 30)
	pause_button.disabled = true
	controls_hbox.add_child(pause_button)
	
	vbox.add_child(controls_hbox)
	
	# Información de la animación
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	
	# Nombre de la animación
	var anim_name_label = Label.new()
	anim_name_label.text = "Animación: ---"
	anim_name_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(anim_name_label)
	
	# Frame actual
	var frame_label = Label.new()
	frame_label.text = "Frame: 0/0"
	frame_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(frame_label)
	
	# Duración
	var duration_label = Label.new()
	duration_label.text = "Duración: 0.0s"
	duration_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(duration_label)
	
	vbox.add_child(info_vbox)
	
	# Guardar referencias según el ID
	if anim_id == "A":
		play_button_a = play_button
		pause_button_a = pause_button
		anim_name_label_a = anim_name_label
		frame_label_a = frame_label
		duration_label_a = duration_label
	else:
		play_button_b = play_button
		pause_button_b = pause_button
		anim_name_label_b = anim_name_label
		frame_label_b = frame_label
		duration_label_b = duration_label
	
	return panel

func _connect_internal_signals():
	"""Conectar señales internas de los controles"""
	print("🔌 Conectando señales internas...")
	
	# Controles animación A
	if play_button_a:
		play_button_a.pressed.connect(_on_play_a_pressed)
	if pause_button_a:
		pause_button_a.pressed.connect(_on_pause_a_pressed)
	
	# Controles animación B
	if play_button_b:
		play_button_b.pressed.connect(_on_play_b_pressed)
	if pause_button_b:
		pause_button_b.pressed.connect(_on_pause_b_pressed)
	
	print("✅ Señales conectadas")

func _setup_initial_state():
	"""Configurar estado inicial de la UI"""
	_set_controls_enabled(false)
	print("✅ Estado inicial configurado")

# ========================================================================
# CALLBACKS DE CONTROLES
# ========================================================================

func _on_play_a_pressed():
	"""Callback del botón Play A"""
	print("▶ Play animación A solicitado")
	play_button_a.disabled = true
	pause_button_a.disabled = false
	emit_signal("play_animation_a_requested")

func _on_pause_a_pressed():
	"""Callback del botón Pause A"""
	print("⏸ Pause animación A solicitado")
	play_button_a.disabled = false
	pause_button_a.disabled = true
	emit_signal("pause_animation_a_requested")

func _on_play_b_pressed():
	"""Callback del botón Play B"""
	print("▶ Play animación B solicitado")
	play_button_b.disabled = true
	pause_button_b.disabled = false
	emit_signal("play_animation_b_requested")

func _on_pause_b_pressed():
	"""Callback del botón Pause B"""
	print("⏸ Pause animación B solicitado")
	play_button_b.disabled = false
	pause_button_b.disabled = true
	emit_signal("pause_animation_b_requested")

# ========================================================================
# API PÚBLICA - ACTUALIZACIONES DE UI
# ========================================================================

func on_animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary):
	"""Actualizar UI cuando se cargan las animaciones"""
	print("📥 Actualizando UI con datos de animaciones...")
	
	animations_loaded = true
	_set_controls_enabled(true)	
	# Actualizar información de animación A
	anim_name_label_a.text = "Animación: %s" %  anim_a_data.name
	
	# Actualizar información de animación B
	anim_name_label_b.text = "Animación: %s" % anim_b_data.name
	


func update_animation_a_state(current_frame: int, total_frames: int, duration: float):
	"""Actualizar estado de animación A"""
	if frame_label_a:
		frame_label_a.text = "Frame: %d/%d" % [current_frame, total_frames]
	if duration_label_a:
		duration_label_a.text = "Duración: %.2fs" % duration

func update_animation_b_state(current_frame: int, total_frames: int, duration: float):
	"""Actualizar estado de animación B"""
	if frame_label_b:
		frame_label_b.text = "Frame: %d/%d" % [current_frame, total_frames]
	if duration_label_b:
		duration_label_b.text = "Duración: %.2fs" % duration

func on_playback_state_changed(animation_type: String, state: Dictionary):
	"""Callback cuando cambia el estado de reproducción"""
	if animation_type == "animation_a":
		update_animation_a_state(
			state.get("current_frame", 0),
			state.get("total_frames", 0),
			state.get("duration", 0.0)
		)
		
		# Actualizar botones
		var is_playing = state.get("playing", false)
		if play_button_a:
			play_button_a.disabled = is_playing
		if pause_button_a:
			pause_button_a.disabled = not is_playing
			
	elif animation_type == "animation_b":
		update_animation_b_state(
			state.get("current_frame", 0),
			state.get("total_frames", 0),
			state.get("duration", 0.0)
		)
		
		# Actualizar botones
		var is_playing = state.get("playing", false)
		if play_button_b:
			play_button_b.disabled = is_playing
		if pause_button_b:
			pause_button_b.disabled = not is_playing

# ========================================================================
# UTILIDADES
# ========================================================================

func _set_controls_enabled(enabled: bool):
	"""Habilitar/deshabilitar controles"""
	if play_button_a:
		play_button_a.disabled = not enabled
	if play_button_b:
		play_button_b.disabled = not enabled

func get_viewport_a() -> SubViewport:
	"""Obtener viewport de animación A"""
	return anim_a_viewport

func get_viewport_b() -> SubViewport:
	"""Obtener viewport de animación B"""
	return anim_b_viewport

# ========================================================================
# DEBUG
# ========================================================================

func debug_ui_state():
	"""Debug del estado de la UI"""
	print("=== DEBUG COLUMNA2 UI ===")
	print("Animaciones cargadas: %s" % animations_loaded)
	print("Viewport A válido: %s" % (anim_a_viewport != null))
	print("Viewport B válido: %s" % (anim_b_viewport != null))
	print("=========================")
