# pixelize3d_fbx/scripts/transition/Columna3_UI.gd
# Interfaz de usuario para configuración de transiciones entre esqueletos
# Input: Interacción del usuario y datos desde Columna3_Logic
# Output: Configuración de transición hacia Columna3_Logic

extends Control
class_name Columna3UI

# === SEÑALES HACIA LÓGICA ===
signal duration_changed(duration: float)
signal frames_changed(frames: int)
signal interpolation_changed(interpolation_type: String)
signal reset_requested()
signal generate_requested()

# === REFERENCIAS A CONTROLES DE UI ===
# Información de esqueletos
var skeleton_info_label: Label
var bones_count_label: Label
var status_label: Label

# Controles de configuración
var duration_slider: HSlider
var duration_spinbox: SpinBox
var duration_label: Label

var frames_slider: HSlider
var frames_spinbox: SpinBox
var frames_label: Label

var interpolation_option: OptionButton
var interpolation_label: Label

# Botones de acción
var reset_button: Button
var generate_button: Button

# Containers
var main_container: VBoxContainer
var config_container: VBoxContainer
var info_container: VBoxContainer
var buttons_container: HBoxContainer

# === ESTADO INTERNO ===
var current_config: Dictionary = {}
var skeleton_info: Dictionary = {}
var is_updating_ui: bool = false

func _ready():
	print("Columna3_UI inicializando...")
	_create_ui_layout()
	_setup_initial_values()
	_connect_ui_signals()
	print("Columna3_UI lista - Interfaz de configuración")

# ========================================================================
# CONSTRUCCIÓN DE INTERFAZ
# ========================================================================

func _create_ui_layout():
	"""Crear layout completo de la interfaz"""
	# Container principal
	main_container = VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_container)
	
	# Título
	_create_title_section()
	
	# Información de esqueletos
	_create_skeleton_info_section()
	
	# Separador
	_create_separator()
	
	# Configuración de transición
	_create_config_section()
	
	# Separador
	_create_separator()
	
	# Botones de acción
	_create_buttons_section()

func _create_title_section():
	"""Crear sección de título"""
	var title = Label.new()
	title.text = "⚙️ CONFIGURACIÓN DE TRANSICIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 0.8))
	main_container.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	main_container.add_child(spacer)

func _create_skeleton_info_section():
	"""Crear sección de información de esqueletos"""
	info_container = VBoxContainer.new()
	main_container.add_child(info_container)
	
	# Título de sección
	var info_title = Label.new()
	info_title.text = "📊 Información de Esqueletos:"
	info_title.add_theme_font_size_override("font_size", 12)
	info_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	info_container.add_child(info_title)
	
	# Estado general
	status_label = Label.new()
	status_label.text = "Estado: Esperando datos..."
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.modulate = Color(0.9, 0.9, 0.9)
	info_container.add_child(status_label)
	
	# Información de esqueletos
	skeleton_info_label = Label.new()
	skeleton_info_label.text = "Esqueletos: No cargados"
	skeleton_info_label.add_theme_font_size_override("font_size", 10)
	skeleton_info_label.modulate = Color(0.9, 0.9, 0.9)
	info_container.add_child(skeleton_info_label)
	
	# Número de bones
	bones_count_label = Label.new()
	bones_count_label.text = "Bones: 0"
	bones_count_label.add_theme_font_size_override("font_size", 10)
	bones_count_label.modulate = Color(0.9, 0.9, 0.9)
	info_container.add_child(bones_count_label)

func _create_config_section():
	"""Crear sección de configuración de transición"""
	config_container = VBoxContainer.new()
	main_container.add_child(config_container)
	
	# Título de configuración
	var config_title = Label.new()
	config_title.text = "🎛️ Parámetros de Transición:"
	config_title.add_theme_font_size_override("font_size", 12)
	config_title.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	config_container.add_child(config_title)
	
	# Duración
	_create_duration_controls()
	
	# Frames
	_create_frames_controls()
	
	# Interpolación
	_create_interpolation_controls()

func _create_duration_controls():
	"""Crear controles para duración"""
	# Label
	duration_label = Label.new()
	duration_label.text = "Duración (segundos):"
	duration_label.add_theme_font_size_override("font_size", 10)
	config_container.add_child(duration_label)
	
	# Container horizontal para slider y spinbox
	var duration_container = HBoxContainer.new()
	config_container.add_child(duration_container)
	
	# Slider
	duration_slider = HSlider.new()
	duration_slider.min_value = 0.1
	duration_slider.max_value = 5.0
	duration_slider.step = 0.1
	duration_slider.value = 0.5
	duration_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duration_container.add_child(duration_slider)
	
	# SpinBox
	duration_spinbox = SpinBox.new()
	duration_spinbox.min_value = 0.1
	duration_spinbox.max_value = 5.0
	duration_spinbox.step = 0.1
	duration_spinbox.value = 0.5
	duration_spinbox.custom_minimum_size.x = 80
	duration_container.add_child(duration_spinbox)

func _create_frames_controls():
	"""Crear controles para número de frames"""
	# Label
	frames_label = Label.new()
	frames_label.text = "Número de Frames:"
	frames_label.add_theme_font_size_override("font_size", 10)
	config_container.add_child(frames_label)
	
	# Container horizontal
	var frames_container = HBoxContainer.new()
	config_container.add_child(frames_container)
	
	# Slider
	frames_slider = HSlider.new()
	frames_slider.min_value = 10
	frames_slider.max_value = 120
	frames_slider.step = 1
	frames_slider.value = 10
	frames_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frames_container.add_child(frames_slider)
	
	# SpinBox
	frames_spinbox = SpinBox.new()
	frames_spinbox.min_value = 10
	frames_spinbox.max_value = 120
	frames_spinbox.step = 1
	frames_spinbox.value = 10
	frames_spinbox.custom_minimum_size.x = 80
	frames_container.add_child(frames_spinbox)

func _create_interpolation_controls():
	"""Crear controles para tipo de interpolación"""
	# Label
	interpolation_label = Label.new()
	interpolation_label.text = "Tipo de Interpolación:"
	interpolation_label.add_theme_font_size_override("font_size", 10)
	config_container.add_child(interpolation_label)
	
	# OptionButton
	interpolation_option = OptionButton.new()
	interpolation_option.add_item("Linear")
	interpolation_option.add_item("Ease In")
	interpolation_option.add_item("Ease Out")
	interpolation_option.add_item("Ease In-Out")
	interpolation_option.add_item("Smooth")
	interpolation_option.add_item("Cubic")
	interpolation_option.selected = 0  # Linear por defecto
	config_container.add_child(interpolation_option)

func _create_buttons_section():
	"""Crear sección de botones de acción"""
	buttons_container = HBoxContainer.new()
	buttons_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(buttons_container)
	
	# Reset button
	reset_button = Button.new()
	reset_button.text = "🔄 Resetear"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_container.add_child(reset_button)
	
	# Generate button
	generate_button = Button.new()
	generate_button.text = "🎬 Generar Transición"
	generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generate_button.disabled = true  # Deshabilitado inicialmente
	buttons_container.add_child(generate_button)

func _create_separator():
	"""Crear separador visual"""
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	main_container.add_child(separator)

# ========================================================================
# CONFIGURACIÓN INICIAL
# ========================================================================

func _setup_initial_values():
	"""Configurar valores iniciales"""
	current_config = {
		"duration": 0.5,
		"frames": 10,
		"interpolation": "Linear",
		"valid": false
	}

func _connect_ui_signals():
	"""Conectar señales de controles de UI"""
	# Duración
	duration_slider.value_changed.connect(_on_duration_slider_changed)
	duration_spinbox.value_changed.connect(_on_duration_spinbox_changed)
	
	# Frames
	frames_slider.value_changed.connect(_on_frames_slider_changed)
	frames_spinbox.value_changed.connect(_on_frames_spinbox_changed)
	
	# Interpolación
	interpolation_option.item_selected.connect(_on_interpolation_selected)
	
	# Botones
	reset_button.pressed.connect(_on_reset_pressed)
	generate_button.pressed.connect(_on_generate_pressed)

# ========================================================================
# MANEJADORES DE EVENTOS DE UI
# ========================================================================

func _on_duration_slider_changed(value: float):
	"""Manejar cambio en slider de duración"""
	if is_updating_ui:
		return
	
	is_updating_ui = true
	duration_spinbox.value = value
	current_config.duration = value
	is_updating_ui = false
	
	print("UI: Duración cambiada a %.2fs" % value)
	emit_signal("duration_changed", value)

func _on_duration_spinbox_changed(value: float):
	"""Manejar cambio en spinbox de duración"""
	if is_updating_ui:
		return
		
	is_updating_ui = true
	duration_slider.value = value
	current_config.duration = value
	is_updating_ui = false
	
	print("UI: Duración cambiada a %.2fs" % value)
	emit_signal("duration_changed", value)

func _on_frames_slider_changed(value: float):
	"""Manejar cambio en slider de frames"""
	if is_updating_ui:
		return
		
	var int_value = int(value)
	is_updating_ui = true
	frames_spinbox.value = int_value
	current_config.frames = int_value
	is_updating_ui = false
	
	print("UI: Frames cambiados a %d" % int_value)
	emit_signal("frames_changed", int_value)

func _on_frames_spinbox_changed(value: float):
	"""Manejar cambio en spinbox de frames"""
	if is_updating_ui:
		return
		
	var int_value = int(value)
	is_updating_ui = true
	frames_slider.value = int_value
	current_config.frames = int_value
	is_updating_ui = false
	
	print("UI: Frames cambiados a %d" % int_value)
	emit_signal("frames_changed", int_value)

func _on_interpolation_selected(index: int):
	"""Manejar selección de tipo de interpolación"""
	if is_updating_ui:
		return
		
	var interpolation_type = interpolation_option.get_item_text(index)
	current_config.interpolation = interpolation_type
	
	print("UI: Interpolación cambiada a %s" % interpolation_type)
	emit_signal("interpolation_changed", interpolation_type)

func _on_reset_pressed():
	"""Manejar botón de reset"""
	print("UI: Reset solicitado")
	emit_signal("reset_requested")

func _on_generate_pressed():
	"""Manejar botón de generar"""
	print("UI: Generación solicitada")
	emit_signal("generate_requested")

# ========================================================================
# API PÚBLICA - RECEPCIÓN DE DATOS
# ========================================================================

func on_config_updated(config: Dictionary):
	"""Actualizar UI con nueva configuración desde lógica"""
	print("UI: Actualizando configuración...")
	
	is_updating_ui = true
	
	# Actualizar controles
	if config.has("duration"):
		duration_slider.value = config.duration
		duration_spinbox.value = config.duration
	
	if config.has("frames"):
		frames_slider.value = config.frames
		frames_spinbox.value = config.frames
	
	if config.has("interpolation"):
		var interpolation_type = config.interpolation
		for i in range(interpolation_option.get_item_count()):
			if interpolation_option.get_item_text(i) == interpolation_type:
				interpolation_option.selected = i
				break
	
	# Actualizar estado de botón generar
	if config.has("valid"):
		generate_button.disabled = not config.valid
		if config.valid:
			generate_button.modulate = Color(1, 1, 1)
		else:
			generate_button.modulate = Color(0.6, 0.6, 0.6)
	
	current_config = config.duplicate()
	is_updating_ui = false

func on_skeleton_info_ready(info: Dictionary):
	"""Actualizar información de esqueletos"""
	print("UI: Actualizando información de poses de esqueletos...")
	
	skeleton_info = info.duplicate()
	
	# Actualizar labels de información
	if info.has("is_valid") and info.is_valid:
		status_label.text = "Estado: ✅ Poses compatibles para transición"
		status_label.modulate = Color(0.8, 1, 0.8)
	else:
		status_label.text = "Estado: ❌ Poses incompatibles o faltantes"
		status_label.modulate = Color(1, 0.8, 0.8)
	
	if info.has("bones_count"):
		bones_count_label.text = "Bones: %d" % info.bones_count
		
	if info.has("has_pose_a") and info.has("has_pose_b"):
		var pose_status = ""
		if info.has_pose_a and info.has_pose_b:
			var source_a = info.get("pose_a_source", "unknown")
			var source_b = info.get("pose_b_source", "unknown")
			pose_status = "✅ Último frame A → Primer frame B"
		elif info.has_pose_a:
			pose_status = "⚠️ Solo pose A disponible"
		elif info.has_pose_b:
			pose_status = "⚠️ Solo pose B disponible"
		else:
			pose_status = "❌ Sin poses de transición"
		
		skeleton_info_label.text = "Transición: %s" % pose_status
	
	if info.has("has_mesh"):
		var mesh_status = "✅ Mesh del modelo base" if info.has_mesh else "❌ Sin mesh"
		# Si ya tenemos texto en skeleton_info_label, agregarlo
		skeleton_info_label.text += "\nMesh: %s" % mesh_status

# ========================================================================
# UTILIDADES PÚBLICAS
# ========================================================================

func get_current_config() -> Dictionary:
	"""Obtener configuración actual de la UI"""
	return current_config.duplicate()

func set_enabled(enabled: bool):
	"""Habilitar/deshabilitar toda la interfaz"""
	for child in config_container.get_children():
		if child.has_method("set_editable"):
			child.set_editable(enabled)
		elif child.has_method("set_disabled"):
			child.set_disabled(not enabled)
	
	reset_button.disabled = not enabled
	
	# El botón generar se maneja por separado según validez
	if not enabled:
		generate_button.disabled = true

func show_loading(loading: bool):
	"""Mostrar/ocultar estado de carga"""
	if loading:
		status_label.text = "Estado: 🔄 Procesando..."
		status_label.modulate = Color(1, 1, 0.8)
	# Si no está cargando, mantendremos el estado actual
