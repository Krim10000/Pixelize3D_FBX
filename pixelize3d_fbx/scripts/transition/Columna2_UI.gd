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


	
var area_value_label
var orient_container
var orient_label_fixed
var orient_value_label
var orient_slider
	


var area_slider: float
# === ESTADO INTERNO ===
var animations_loaded: bool = false

func _ready():
	print("🎮 Columna2UI inicializando...")
	_get_viewport_references()
	#_create_ui_controls()
	_setup_physical_controls()
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
			_add_border_to_container(anim_a_container, "Viewport A")
			print("  ✅ Viewport A borde dibujado")
		
		if anim_b_container:
			anim_b_viewport = anim_b_container.get_node("SubViewport_B")
			print("  ✅ Viewport B encontrado")
			_add_border_to_container(anim_b_container, "Viewport B")
			print("  ✅ Viewport B borde dibujado")
		
	_debug_border_styling()

	
	if not anim_a_viewport or not anim_b_viewport:
		print("  ⚠️ No se encontraron todos los viewports")

#func _create_ui_controls():
	#"""Crear controles de UI para preview"""
	#print("🎨 Creando controles de UI...")
	#
	## Título de la columna
	#var title = Label.new()
	#title.text = "🎬 PREVIEW ANIMACIONES"
	#title.add_theme_font_size_override("font_size", 14)
	#title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#add_child(title)
	#
	#add_child(HSeparator.new())
	#
	## Container principal para controles
	#controls_container = VBoxContainer.new()
	#controls_container.add_theme_constant_override("separation", 10)
	#add_child(controls_container)
	#
	## === CONTROLES ANIMACIÓN A ===
	#animation_a_controls = _create_animation_control_panel("A")
	#controls_container.add_child(animation_a_controls)
	##controls_container.add_child(anim_a_viewport)
	#
	## === CONTROLES ANIMACIÓN B ===
	#animation_b_controls = _create_animation_control_panel("B")
	#controls_container.add_child(animation_b_controls)
	##controls_container.add_child(anim_b_viewport)
	#
	#print("✅ Controles de UI creados")

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




# ========================================================================
# FUNCIONES NUEVAS - AGREGAR AL FINAL DE Columna2_UI.gd
# ========================================================================

func _setup_viewport_styling():
	"""Configurar bordes y estilos para los viewports"""
	print("🎨 Configurando estilos de viewports...")
	
	if anim_a_container:
		_add_border_to_container(anim_a_container, "Viewport A")
		print("  ✅ Borde agregado a Viewport A")
	
	if anim_b_container:
		_add_border_to_container(anim_b_container, "Viewport B") 
		print("  ✅ Borde agregado a Viewport B")

func _add_border_to_container(container: SubViewportContainer, label_text: String):
	"""Agregar borde visible a un SubViewportContainer"""
	# Crear StyleBox con borde
	var style_box = StyleBoxFlat.new()
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.3)
	
	# Aplicar el estilo al container
	container.add_theme_stylebox_override("panel", style_box)
	
	# Asegurar tamaño mínimo
	container.custom_minimum_size = Vector2(128, 128)



func _setup_physical_controls():
	"""Configurar controles usando nodos físicos existentes"""
	print("🎨 Configurando controles físicos...")
	
	# Obtener referencias a paneles de control físicos
	var controls_a = get_node("PanelContainer_A/LayoutContainer_A/PanelContainer_A_Controls")
	var controls_b = get_node("PanelContainer_B/LayoutContainer_B/PanelContainer_B_Controls")
	
	# Configurar cada panel de control
	_setup_control_panel(controls_a, "A")
	_setup_control_panel(controls_b, "B")
	
	_create_model_config_panel()
	
	print("✅ Controles físicos configurados")

func _setup_control_panel(panel: PanelContainer, id: String):
	"""Configurar un panel de control individual"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	
	# Label del nombre de animación
	var anim_label = Label.new()
	anim_label.text = "Animación %s: (Sin cargar)" % id
	anim_label.add_theme_font_size_override("font_size", 12)
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(anim_label)
	
	# Label de información de frames
	var frame_label = Label.new()
	frame_label.text = "Frame: 0/0 | Duración: 0.0s"
	frame_label.add_theme_font_size_override("font_size", 10)
	frame_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(frame_label)
	
	
	
	
	# Container horizontal para botones
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons_hbox)
	
	# Botones de control
	var play_button = Button.new()
	play_button.text = "▶"  +id
	play_button.custom_minimum_size = Vector2(40, 30)
	play_button.tooltip_text = "Reproducir animación %s" % id
	buttons_hbox.add_child(play_button)
	
	var pause_button = Button.new()
	pause_button.text = "PAUSE  "+id
	pause_button.custom_minimum_size = Vector2(40, 30)
	pause_button.tooltip_text = "Pausar animación %s" % id
	buttons_hbox.add_child(pause_button)
	
	# Guardar referencias según el ID
	if id == "A":
		play_button_a = play_button
		pause_button_a = pause_button
		anim_name_label_a = anim_label
		frame_label_a = frame_label
	else:
		play_button_b = play_button
		pause_button_b = pause_button
		anim_name_label_b = anim_label
		frame_label_b = frame_label



func _debug_border_styling():
	"""Debug para verificar estilos de bordes"""
	print("🔍 Debug de estilos...")
	
	if anim_a_container:
		# Aplicar borde más visible
		var style = StyleBoxFlat.new()
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color.RED  # Rojo para que se vea
		style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
		
		var panel_a = get_node("PanelContainer_A")
		panel_a.add_theme_stylebox_override("panel", style)
		var panel_b = get_node("PanelContainer_B") 
		panel_b.add_theme_stylebox_override("panel", style)	
		print("  🟥 Borde ROJO aplicado a Viewport A")




# === CONTROLES DE CONFIGURACIÓN ===
var model_config_panel: PanelContainer
var height_slider: HSlider
var height_label: Label
var angle_slider: HSlider 
var angle_label: Label
var north_slider: HSlider
var north_label: Label
var zoom_slider: HSlider
var zoom_label: Label
var auto_north_button: Button
var center_models_button: Button



#func _create_model_config_panel():
	#"""Crear panel de configuración de modelos"""
	#model_config_panel = PanelContainer.new()
	#model_config_panel.name = "ModelConfigPanel"
	#
	#var vbox = VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 8)
	#model_config_panel.add_child(vbox)
	#
	## Título
	#var title = Label.new()
	#title.text = "Configuración de Modelos"
	#title.add_theme_font_size_override("font_size", 12)
	#title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(title)
	#
	## Altura de cámara
	#var height_container = HBoxContainer.new()
	#vbox.add_child(height_container)
	#
#
	#
	#height_slider = HSlider.new()
	#height_slider.min_value = 0.5
	#height_slider.max_value = 10
	#height_slider.value = 2.5
	#height_slider.step = 0.5
	#height_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#
#
	#height_label = Label.new()
	#height_label.text = "Altura " + str(height_slider.value)
	#
	#height_label.custom_minimum_size.x = 80
	#height_container.add_child(height_label)
	#height_container.add_child(height_slider)
	#
	## Ángulo de cámara
	#var angle_container = HBoxContainer.new()
	#vbox.add_child(angle_container)
	#
	#angle_label = Label.new()
	#angle_label.text = "Ángulo: 45°"
	#angle_label.custom_minimum_size.x = 80
	#angle_container.add_child(angle_label)
	#
	#angle_slider = HSlider.new()
	#angle_slider.min_value = 15.0
	#angle_slider.max_value = 75.0
	#angle_slider.value = 45.0
	#angle_slider.step = 1.0
	#angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#angle_container.add_child(angle_slider)
	#
	## Orientación Norte
	#var north_container = HBoxContainer.new()
	#vbox.add_child(north_container)
	#
	#north_label = Label.new()
	#north_label.text = "Norte: 0°"
	#north_label.custom_minimum_size.x = 80
	#north_container.add_child(north_label)
	#
	#north_slider = HSlider.new()
	#north_slider.min_value = 0.0
	#north_slider.max_value = 360.0
	#north_slider.value = 0.0
	#north_slider.step = 1.0
	#north_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#north_container.add_child(north_slider)
	#
	## Zoom
	#var zoom_container = HBoxContainer.new()
	#vbox.add_child(zoom_container)
	#
	#zoom_label = Label.new()
	#zoom_label.text = "Zoom: 8.0"
	#zoom_label.custom_minimum_size.x = 80
	#zoom_container.add_child(zoom_label)
	#
	#zoom_slider = HSlider.new()
	#zoom_slider.min_value = 2.0
	#zoom_slider.max_value = 20.0
	#zoom_slider.value = 8.0
	#zoom_slider.step = 0.2
	#zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#zoom_container.add_child(zoom_slider)
	#
	## Botones
	#var buttons_container = HBoxContainer.new()
	#buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	#vbox.add_child(buttons_container)
	#
	#auto_north_button = Button.new()
	#auto_north_button.text = "Auto Norte"
	#buttons_container.add_child(auto_north_button)
	#
	#center_models_button = Button.new()
	#center_models_button.text = "Centrar"
	#buttons_container.add_child(center_models_button)
	#
	## Conectar señales
	#height_slider.value_changed.connect(_on_height_changed)
	#angle_slider.value_changed.connect(_on_angle_changed)
	#north_slider.value_changed.connect(_on_north_changed)
	#zoom_slider.value_changed.connect(_on_zoom_changed)
	#auto_north_button.pressed.connect(_on_auto_north_pressed)
	#center_models_button.pressed.connect(_on_center_models_pressed)
	#
	#add_child(model_config_panel)


func _create_model_config_panel():
	"""Panel simplificado con solo capture_area y orientación"""
	model_config_panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	model_config_panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "Configuración de Vista"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Área de captura
	var area_container = HBoxContainer.new()
	vbox.add_child(area_container)
	
	var area_label_fixed = Label.new()
	area_label_fixed.text = "Área:"
	area_label_fixed.custom_minimum_size.x = 60
	area_container.add_child(area_label_fixed)
	
	var area_slider
	area_slider = HSlider.new()
	area_slider.min_value = 0.5
	area_slider.max_value = 20.0
	area_slider.value = 2.5
	area_slider.step = 0.5
	area_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_container.add_child(area_slider)
	
	area_value_label = Label.new()
	#area_value_label.text = "2.5"
	area_value_label.text= str(area_slider.value)
	area_value_label.custom_minimum_size.x = 40
	area_container.add_child(area_value_label)
	
	# Orientación
	orient_container = HBoxContainer.new()
	vbox.add_child(orient_container)
	
	orient_label_fixed = Label.new()
	orient_label_fixed.text = "Norte:"
	orient_label_fixed.custom_minimum_size.x = 60
	orient_container.add_child(orient_label_fixed)

	orient_slider = HSlider.new()
	orient_slider.min_value = 0.0
	orient_slider.max_value = 360.0
	orient_slider.value = 0.0
	orient_slider.step = 1.0
	orient_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orient_container.add_child(orient_slider)
	
	orient_value_label = Label.new()
	orient_value_label.text = "0°"
	orient_value_label.custom_minimum_size.x = 40
	orient_container.add_child(orient_value_label)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	var compare_frames_button = Button.new()
	compare_frames_button.text = "Comparar: A=Final | B=Inicio"  
	compare_frames_button.custom_minimum_size = Vector2(0, 30)
	compare_frames_button.pressed.connect(_on_compare_frames_pressed)
	vbox.add_child(compare_frames_button)

	
	# Conectar señales
	area_slider.value_changed.connect(_on_area_changed)
	orient_slider.value_changed.connect(_on_orientation_changed)


	
	add_child(model_config_panel)


func _on_compare_frames_pressed():
	var logic = get_node("../../../../Columna2_Logic")
	if logic and logic.has_method("quick_compare_frames"):
		logic.quick_compare_frames()

func _on_area_changed(value: float):
	area_value_label.text = "%.1f" % value
	var logic = get_node("../../../../Columna2_Logic")
	if logic:
		logic.set_capture_area(value)

func _on_orientation_changed(value: float):
	orient_value_label.text = "%.0f°" % value
	var logic = get_node("../../../../Columna2_Logic")
	if logic:
		logic.set_model_orientation(value)

func _on_height_changed(value: float):
	height_label.text = "Altura: %.1f" % value
	_apply_model_settings({"camera_height": value})

func _on_angle_changed(value: float):
	angle_label.text = "Ángulo: %.0f°" % value
	_apply_model_settings({"camera_angle": value})

func _on_north_changed(value: float):
	north_label.text = "Norte: %.0f°" % value
	_apply_model_settings({"north_offset": value})

func _on_zoom_changed(value: float):
	zoom_label.text = "Zoom: %.1f" % value
	_apply_model_settings({"orthographic_size": value, "manual_zoom_active": true})

func _on_auto_north_pressed():
	var logic = get_node("../../../../Columna2_Logic") 
	if logic and logic.has_method("request_auto_north_detection"):
		logic.request_auto_north_detection()

func _on_center_models_pressed():
	var logic= get_node("../../../../Columna2_Logic") 
	if logic and logic.has_method("recenter_models"):
		logic.recenter_models()

func _apply_model_settings(settings: Dictionary):
	var logic = get_node("../../../../Columna2_Logic") 
	if logic and logic.has_method("apply_model_settings"):
		logic.apply_model_settings(settings)
