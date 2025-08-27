# pixelize3d_fbx/scripts/transition/ui/transition_panel.gd
# Panel principal de la herramienta de transiciones
# Input: Interacción del usuario para seleccionar animaciones y configurar transiciones
# Output: UI completa para generar transiciones suaves entre animaciones

extends VBoxContainer
class_name TransitionPanel

# Señales
signal base_load_requested(file_path: String)
signal animation_a_load_requested(file_path: String)  
signal animation_b_load_requested(file_path: String)
signal transition_generate_requested()
signal settings_changed(config: Dictionary)

# UI Components - Sección informativa  
var file_section: VBoxContainer

# UI Components - Estado de la base
var base_status_label: Label

# UI Components - Selección de animaciones
var animations_section: VBoxContainer
var anim_a_panel: VBoxContainer
var anim_a_list: ItemList
var anim_a_status: Label
var anim_b_panel: VBoxContainer
var anim_b_list: ItemList
var anim_b_status: Label

# UI Components - Configuración
var config_section: VBoxContainer
var duration_spinbox: SpinBox
var frames_spinbox: SpinBox
var curve_option: OptionButton
var fps_spinbox: SpinBox

# UI Components - Acciones
var actions_section: VBoxContainer
var validate_button: Button
var generate_button: Button
var progress_bar: ProgressBar
var status_label: Label

# Estado interno
var base_loaded: bool = false
var animation_a_loaded: bool = false
var animation_b_loaded: bool = false
var is_generating_transition: bool = false

# Datos
var loaded_base_path: String = ""
var loaded_animation_a_path: String = ""
var loaded_animation_b_path: String = ""
var current_config: Dictionary = {}

func _ready():
	print("🎮 TransitionPanel INICIANDO...")
	_setup_default_config()
	_create_ui()
	print("✅ TransitionPanel UI creada")
	print("🎮 TransitionPanel inicializado completamente")

func _create_ui():
	"""Crear interfaz optimizada para columnas verticales"""
	print("🎮 Creando UI del TransitionPanel...")
	
	# === ESTADO DE BASE ===
	_create_base_status_section()
	add_child(HSeparator.new())
	
	# === SELECCIÓN DE ANIMACIONES (COMPACTA) ===
	_create_vertical_animations_section()
	add_child(HSeparator.new())
	
	# === CONFIGURACIÓN COMPACTA ===
	_create_vertical_config_section()
	add_child(HSeparator.new())
	
	# === ACCIONES ===
	_create_vertical_actions_section()
	
	print("✅ UI del TransitionPanel creada")

func _create_base_status_section():
	"""Crear sección de estado de la base"""
	var base_section = VBoxContainer.new()
	
	var base_title = Label.new()
	base_title.text = "🏗️ Modelo Base"
	base_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_title.add_theme_stylebox_override("normal", _create_section_style())
	base_section.add_child(base_title)
	
	base_status_label = Label.new()
	base_status_label.text = "❌ No cargado - Selecciona una carpeta"
	base_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_section.add_child(base_status_label)
	
	add_child(base_section)

func _create_vertical_animations_section():
	"""Crear sección de animaciones de forma vertical y compacta"""
	print("🎭 Creando sección de animaciones...")
	
	animations_section = VBoxContainer.new()
	
	var anim_title = Label.new()
	anim_title.text = "🎭 Selección de Transición"
	anim_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_title.add_theme_stylebox_override("normal", _create_section_style())
	animations_section.add_child(anim_title)
	
	# Container horizontal para las dos listas
	var lists_container = HBoxContainer.new()
	lists_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Panel A
	_create_animation_a_panel()
	lists_container.add_child(anim_a_panel)
	
	# Separador
	var separator = VSeparator.new()
	lists_container.add_child(separator)
	
	# Panel B
	_create_animation_b_panel()
	lists_container.add_child(anim_b_panel)
	
	animations_section.add_child(lists_container)
	add_child(animations_section)
	
	print("✅ Sección de animaciones creada con %d hijos" % animations_section.get_child_count())

func _create_animation_a_panel():
	"""Crear panel para Animación A (origen)"""
	
	anim_a_panel = VBoxContainer.new()
	anim_a_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var anim_a_title = Label.new()
	anim_a_title.text = "🅰️ Animación Inicial"
	anim_a_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_a_panel.add_child(anim_a_title)
	
	anim_a_list = ItemList.new()
	anim_a_list.custom_minimum_size = Vector2(200, 150)
	anim_a_list.add_item("-- Selecciona una carpeta primero --")
	anim_a_list.item_selected.connect(_on_animation_a_selected)
	anim_a_list.select_mode = ItemList.SELECT_SINGLE
	anim_a_panel.add_child(anim_a_list)
	
	anim_a_status = Label.new()
	anim_a_status.text = "❌ No seleccionada"
	anim_a_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_a_panel.add_child(anim_a_status)

func _create_animation_b_panel():
	"""Crear panel para Animación B (destino)"""
	
	anim_b_panel = VBoxContainer.new()
	anim_b_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var anim_b_title = Label.new()
	anim_b_title.text = "🅱️ Animación Final"
	anim_b_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_b_panel.add_child(anim_b_title)
	
	anim_b_list = ItemList.new()
	anim_b_list.custom_minimum_size = Vector2(200, 150)
	anim_b_list.add_item("-- Selecciona una carpeta primero --")
	anim_b_list.item_selected.connect(_on_animation_b_selected)
	anim_b_list.select_mode = ItemList.SELECT_SINGLE
	anim_b_panel.add_child(anim_b_list)
	
	anim_b_status = Label.new()
	anim_b_status.text = "❌ No seleccionada"
	anim_b_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_b_panel.add_child(anim_b_status)

func _create_vertical_config_section():
	"""Crear sección de configuración vertical"""
	print("⚙️ Creando sección de configuración...")
	
	config_section = VBoxContainer.new()
	
	var config_title = Label.new()
	config_title.text = "⚙️ Configuración de Transición"
	config_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	config_title.add_theme_stylebox_override("normal", _create_section_style())
	config_section.add_child(config_title)
	
	# Grid para configuración compacta
	var config_grid = GridContainer.new()
	config_grid.columns = 2
	
	# Duración
	var duration_label = Label.new()
	duration_label.text = "Duración (s):"
	duration_label.custom_minimum_size.x = 100
	config_grid.add_child(duration_label)
	
	duration_spinbox = SpinBox.new()
	duration_spinbox.min_value = 0.1
	duration_spinbox.max_value = 5.0
	duration_spinbox.step = 0.1
	duration_spinbox.value = 1.0
	duration_spinbox.value_changed.connect(_on_config_changed)
	config_grid.add_child(duration_spinbox)
	
	# Frames
	var frames_label = Label.new()
	frames_label.text = "Frames:"
	config_grid.add_child(frames_label)
	
	frames_spinbox = SpinBox.new()
	frames_spinbox.min_value = 5
	frames_spinbox.max_value = 60
	frames_spinbox.step = 1
	frames_spinbox.value = 24
	frames_spinbox.value_changed.connect(_on_config_changed)
	config_grid.add_child(frames_spinbox)
	
	# FPS
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	config_grid.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 12
	fps_spinbox.max_value = 60
	fps_spinbox.step = 1
	fps_spinbox.value = 24
	fps_spinbox.value_changed.connect(_on_config_changed)
	config_grid.add_child(fps_spinbox)
	
	# Curva
	var curve_label = Label.new()
	curve_label.text = "Curva:"
	config_grid.add_child(curve_label)
	
	curve_option = OptionButton.new()
	curve_option.add_item("Linear")
	curve_option.add_item("Ease In")
	curve_option.add_item("Ease Out") 
	curve_option.add_item("Ease In-Out")
	curve_option.selected = 3  # Ease In-Out por defecto
	curve_option.item_selected.connect(_on_config_changed)
	config_grid.add_child(curve_option)
	
	config_section.add_child(config_grid)
	add_child(config_section)
	
	print("✅ Sección de configuración creada con %d hijos" % config_section.get_child_count())

func _create_vertical_actions_section():
	"""Crear sección de acciones vertical"""
	print("🎬 Creando sección de acciones...")
	
	actions_section = VBoxContainer.new()
	
	var actions_title = Label.new()
	actions_title.text = "🎬 Generar Transición"
	actions_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_title.add_theme_stylebox_override("normal", _create_section_style())
	actions_section.add_child(actions_title)
	
	# Botones
	var buttons_container = HBoxContainer.new()
	
	validate_button = Button.new()
	validate_button.text = "🔍 Validar"
	validate_button.disabled = true
	validate_button.pressed.connect(_on_validate_pressed)
	buttons_container.add_child(validate_button)
	
	generate_button = Button.new()
	generate_button.text = "🎬 Generar"
	generate_button.disabled = true
	generate_button.pressed.connect(_on_generate_pressed)
	buttons_container.add_child(generate_button)
	
	actions_section.add_child(buttons_container)
	
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	actions_section.add_child(progress_bar)
	
	status_label = Label.new()
	status_label.text = "Listo - Carga archivos para comenzar"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_section.add_child(status_label)
	
	add_child(actions_section)
	
	print("✅ Sección de acciones creada con %d hijos" % actions_section.get_child_count())

# ========================================================================
# CONFIGURACIÓN Y ESTADO
# ========================================================================

func _setup_default_config():
	"""Configurar valores por defecto"""
	current_config = {
		"duration": 1.0,
		"transition_frames": 24,
		"interpolation_curve": "ease_in_out",
		"fps": 24
	}
	_emit_config_change()

func _update_ui_state():
	"""Actualizar estado de la UI"""
	
	var all_loaded = base_loaded and animation_a_loaded and animation_b_loaded
	
	validate_button.disabled = not all_loaded or is_generating_transition
	generate_button.disabled = not all_loaded or is_generating_transition
	
	# Actualizar texto del botón de validación
	if all_loaded:
		validate_button.text = "🔍 Validar Compatibilidad"
	else:
		validate_button.text = "🔍 Carga archivos primero"

# ========================================================================
# EVENTOS DE UI - CONFIGURACIÓN
# ========================================================================

func _on_config_changed(_value = null):
	"""Manejar cambios en configuración"""
	
	current_config.duration = duration_spinbox.value
	current_config.transition_frames = int(frames_spinbox.value)
	current_config.fps = int(fps_spinbox.value)
	
	var curve_names = ["linear", "ease_in", "ease_out", "ease_in_out"]
	current_config.interpolation_curve = curve_names[curve_option.selected]
	
	_emit_config_change()

func _on_validate_pressed():
	"""Manejar validación"""
	status_label.text = "🔍 Validando compatibilidad..."
	# La validación será manejada por el coordinador

func _on_generate_pressed():
	"""Manejar generación de transición"""
	is_generating_transition = true
	_update_ui_state()
	
	progress_bar.visible = true
	progress_bar.value = 0
	status_label.text = "🎬 Generando transición..."
	
	emit_signal("transition_generate_requested")

# ========================================================================
# EVENTOS DE UI - SELECCIÓN DE ANIMACIONES
# ========================================================================

func _on_animation_a_selected(index: int):
	"""Manejar selección de Animación A"""
	if index < 0 or anim_a_list.get_item_count() <= index:
		return
	
	var file_path = anim_a_list.get_item_metadata(index)
	if file_path:
		loaded_animation_a_path = file_path
		animation_a_loaded = true
		anim_a_status.text = "✅ " + file_path.get_file()
		emit_signal("animation_a_load_requested", file_path)
		_update_ui_state()

func _on_animation_b_selected(index: int):
	"""Manejar selección de Animación B"""
	if index < 0 or anim_b_list.get_item_count() <= index:
		return
	
	var file_path = anim_b_list.get_item_metadata(index)
	if file_path:
		loaded_animation_b_path = file_path
		animation_b_loaded = true
		anim_b_status.text = "✅ " + file_path.get_file()
		emit_signal("animation_b_load_requested", file_path)
		_update_ui_state()

# ========================================================================
# API PÚBLICA PARA CARGA AUTOMÁTICA
# ========================================================================

func populate_animation_lists(animation_files: Array):
	"""Poblar ambas listas con animaciones encontradas automáticamente"""
	print("📋 Poblando listas con %d animaciones" % animation_files.size())
	
	# Limpiar listas
	anim_a_list.clear()
	anim_b_list.clear()
	
	# Poblar ambas listas con las mismas animaciones
	for file_path in animation_files:
		var item_text = file_path.get_file().get_basename()
		
		# Lista A
		anim_a_list.add_item(item_text)
		anim_a_list.set_item_metadata(anim_a_list.get_item_count() - 1, file_path)
		
		# Lista B  
		anim_b_list.add_item(item_text)
		anim_b_list.set_item_metadata(anim_b_list.get_item_count() - 1, file_path)
	
	status_label.text = "✅ %d animaciones disponibles - Selecciona una de cada lista" % animation_files.size()
	print("✅ Listas pobladas correctamente")

func on_base_loaded(success: bool, file_name: String):
	"""Callback cuando se carga la base"""
	print("🔄 Actualizando UI - Base loaded: %s, success: %s" % [file_name, success])
	
	if success:
		base_loaded = true
		loaded_base_path = file_name
		base_status_label.text = "✅ " + file_name
		print("✅ UI actualizada: base_status_label = %s" % base_status_label.text)
	else:
		base_loaded = false
		loaded_base_path = ""
		base_status_label.text = "❌ Error cargando"
		print("❌ UI actualizada: error cargando base")
	
	_update_ui_state()

func on_validation_result(is_valid: bool, message: String):
	"""Callback de resultado de validación"""
	if is_valid:
		status_label.text = "✅ " + message
		generate_button.disabled = false
	else:
		status_label.text = "❌ " + message

func on_transition_progress(current: int, total: int):
	"""Callback de progreso"""
	var percentage = float(current) / float(total) * 100.0
	progress_bar.value = percentage
	status_label.text = "🎬 Generando... %d/%d (%.0f%%)" % [current, total, percentage]

func on_transition_complete(output_name: String):
	"""Callback de transición completada"""
	is_generating_transition = false
	progress_bar.visible = false
	status_label.text = "✅ Transición generada: " + output_name
	_update_ui_state()

func on_transition_failed(error: String):
	"""Callback de error"""
	is_generating_transition = false
	progress_bar.visible = false
	status_label.text = "❌ Error: " + error
	_update_ui_state()

# ========================================================================
# UTILIDADES INTERNAS
# ========================================================================

func _emit_config_change():
	"""Emitir cambio de configuración"""
	emit_signal("settings_changed", current_config.duplicate())

func _create_section_style() -> StyleBox:
	"""Crear estilo para títulos de sección"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _create_panel_style() -> StyleBox:
	"""Crear estilo para paneles"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.3)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func get_current_config() -> Dictionary:
	"""Obtener configuración actual"""
	return current_config.duplicate()

# ========================================================================
# MÉTODOS DE DEBUG Y TESTING
# ========================================================================

func debug_current_state():
	"""Debug del estado actual"""
	print("🔍 Debug - Estado actual:")
	print("  Base cargada: %s" % base_loaded)
	print("  Animación A cargada: %s" % animation_a_loaded) 
	print("  Animación B cargada: %s" % animation_b_loaded)
	print("  Base path: %s" % loaded_base_path)
	print("  Anim A path: %s" % loaded_animation_a_path)
	print("  Anim B path: %s" % loaded_animation_b_path)
	print("  Config: %s" % str(current_config))
