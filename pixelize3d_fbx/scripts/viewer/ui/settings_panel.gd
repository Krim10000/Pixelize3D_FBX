# scripts/viewer/ui/settings_panel.gd
# Panel COMPLETO con control de área de captura y orientación automática
# Input: Cambios en controles de configuración
# Output: Señales con configuración actualizada

extends VBoxContainer

# Señales específicas de este panel
signal settings_changed(settings: Dictionary)
signal preset_applied(preset_name: String)
signal request_auto_north_detection() 

# UI propia de este panel
var section_label: Label
var directions_spinbox: SpinBox
var sprite_size_spinbox: SpinBox
var fps_spinbox: SpinBox
var pixelize_check: CheckBox
var camera_angle_slider: HSlider
var camera_angle_label: Label
var north_offset_slider: HSlider
var north_offset_label: Label
# Altura:
var camera_height_slider: HSlider
var camera_height_label: Label

# Controles de área de captura
var capture_area_slider: HSlider
var capture_area_label: Label
var auto_north_check: CheckBox
var show_orientation_cross_check: CheckBox
# Configuración interna
var current_settings: Dictionary = {
	"directions": 16,
	"sprite_size": 512,
	"fps": 30,
	"camera_height": 12.0,  
	"pixelize": true,
	"camera_angle": 45.0,
	"north_offset": 0.0,
	"capture_area_size": 8.0,
	"auto_north_detection": true
}

func _ready():
	print("⚙️ SettingsPanel inicializado")
	_create_ui()
	_apply_current_settings()

func _create_ui():
	# Título de sección
	section_label = Label.new()
	section_label.text = "⚙️ Configuración de Renderizado"
	section_label.add_theme_font_size_override("font_size", 20)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# SECCIÓN: CONFIGURACIÓN BÁSICA
	_create_basic_settings()
	
	add_child(HSeparator.new())
	
	# SECCIÓN: CONFIGURACIÓN DE CÁMARA
	_create_camera_settings()
	
	add_child(HSeparator.new())
	
	# SECCIÓN: ÁREA DE CAPTURA
	_create_capture_area_settings()
	
	add_child(HSeparator.new())
	
	# SECCIÓN: ORIENTACIÓN
	_create_orientation_settings()

func _create_basic_settings():
	"""Crear configuración básica"""
	var basic_title = Label.new()
	basic_title.text = "📋 Configuración Básica"
	basic_title.add_theme_font_size_override("font_size", 14)
	basic_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(basic_title)
	
	# Direcciones
	var directions_container = HBoxContainer.new()
	add_child(directions_container)
	
	var directions_label = Label.new()
	directions_label.text = "Direcciones:"
	directions_label.custom_minimum_size.x = 100
	directions_container.add_child(directions_label)
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 8
	directions_spinbox.max_value = 32
	directions_spinbox.step = 8
	directions_spinbox.value = 16
	directions_spinbox.value_changed.connect(_on_setting_changed)
	directions_container.add_child(directions_spinbox)
	
	# Tamaño de sprite (RESOLUCIÓN)
	var sprite_size_container = HBoxContainer.new()
	add_child(sprite_size_container)
	
	var sprite_size_label = Label.new()
	sprite_size_label.text = "Resolución:"
	sprite_size_label.custom_minimum_size.x = 100
	sprite_size_container.add_child(sprite_size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 64
	sprite_size_spinbox.max_value = 512
	sprite_size_spinbox.step = 64
	sprite_size_spinbox.value = 512
	sprite_size_spinbox.value_changed.connect(_on_setting_changed)
	sprite_size_container.add_child(sprite_size_spinbox)
	
	# FPS
	var fps_container = HBoxContainer.new()
	add_child(fps_container)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_label.custom_minimum_size.x = 100
	fps_container.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 6
	fps_spinbox.max_value = 60
	fps_spinbox.value = 30
	fps_spinbox.value_changed.connect(_on_setting_changed)
	fps_container.add_child(fps_spinbox)
	
	# Pixelizado
	pixelize_check = CheckBox.new()
	pixelize_check.text = "Aplicar pixelización"
	pixelize_check.button_pressed = true
	pixelize_check.toggled.connect(_on_setting_changed)
	add_child(pixelize_check)

func _create_camera_settings():
	"""Crear configuración de cámara"""
	var camera_title = Label.new()
	camera_title.text = "📐 Cámara"
	camera_title.add_theme_font_size_override("font_size", 14)
	camera_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(camera_title)
	
	# Ángulo de cámara
	var camera_angle_container = HBoxContainer.new()
	add_child(camera_angle_container)
	
	var angle_label = Label.new()
	angle_label.text = "Ángulo:"
	angle_label.custom_minimum_size.x = 80
	camera_angle_container.add_child(angle_label)
	
	camera_angle_slider = HSlider.new()
	camera_angle_slider.min_value = 15.0
	camera_angle_slider.max_value = 75.0
	camera_angle_slider.value = 45.0
	camera_angle_slider.step = 1.0
	camera_angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camera_angle_slider.value_changed.connect(_on_camera_angle_changed)
	camera_angle_container.add_child(camera_angle_slider)
	
	camera_angle_label = Label.new()
	camera_angle_label.text = "45°"
	camera_angle_label.custom_minimum_size.x = 40
	camera_angle_container.add_child(camera_angle_label)


	#altura
	var camera_height_container = HBoxContainer.new()
	add_child(camera_height_container)
	
	var height_label = Label.new()
	height_label.text = "Altura:"
	height_label.custom_minimum_size.x = 80
	camera_height_container.add_child(height_label)
	
	camera_height_slider = HSlider.new()
	camera_height_slider.min_value = 5.0
	camera_height_slider.max_value = 25.0
	camera_height_slider.value = 12.0
	camera_height_slider.step = 0.5
	camera_height_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camera_height_slider.value_changed.connect(_on_camera_height_changed)
	camera_height_container.add_child(camera_height_slider)
	
	camera_height_label = Label.new()
	camera_height_label.text = "12.0"
	camera_height_label.custom_minimum_size.x = 40
	camera_height_container.add_child(camera_height_label)
	
func _on_camera_height_changed(value: float):
	"""Manejar cambio en altura de cámara"""
	current_settings.camera_height = value
	camera_height_label.text = "%.1f" % value
	
	print("📏 Altura de cámara: %.1f" % value)
	emit_signal("settings_changed", current_settings.duplicate())

	
	
func _create_capture_area_settings():
	"""Crear configuración de área de captura"""
	var capture_title = Label.new()
	capture_title.text = "🖼️ Área de Captura"
	capture_title.add_theme_font_size_override("font_size", 14)
	capture_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(capture_title)
	
	# Descripción del área de captura
	var capture_desc = Label.new()
	capture_desc.text = "Controla qué tan grande se ve el modelo en el sprite final"
	capture_desc.add_theme_font_size_override("font_size", 10)
	capture_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	capture_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(capture_desc)
	
	# Slider de área de captura
	var capture_container = HBoxContainer.new()
	add_child(capture_container)
	
	var capture_label = Label.new()
	capture_label.text = "Tamaño:"
	capture_label.custom_minimum_size.x = 80
	capture_container.add_child(capture_label)
	
	capture_area_slider = HSlider.new()
	capture_area_slider.min_value = 3.0    # Modelo MUY grande (área pequeña)
	capture_area_slider.max_value = 20.0   # Modelo pequeño (área grande)
	capture_area_slider.value = 8.0        # Tamaño normal
	capture_area_slider.step = 0.5
	capture_area_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capture_area_slider.value_changed.connect(_on_capture_area_changed)
	capture_container.add_child(capture_area_slider)
	
	capture_area_label = Label.new()
	capture_area_label.text = "8.0"
	capture_area_label.custom_minimum_size.x = 40
	capture_container.add_child(capture_area_label)
	
	# Botones de presets de tamaño
	var size_presets_container = HBoxContainer.new()
	add_child(size_presets_container)
	
	var size_presets_label = Label.new()
	size_presets_label.text = "Presets:"
	size_presets_label.custom_minimum_size.x = 80
	size_presets_container.add_child(size_presets_label)
	
	var size_huge_btn = Button.new()
	size_huge_btn.text = "Gigante"
	size_huge_btn.custom_minimum_size.x = 55
	size_huge_btn.pressed.connect(_on_size_preset_pressed.bind(4.0))
	size_huge_btn.tooltip_text = "Modelo muy grande en el sprite"
	size_presets_container.add_child(size_huge_btn)
	
	var size_big_btn = Button.new()
	size_big_btn.text = "Grande"
	size_big_btn.custom_minimum_size.x = 55
	size_big_btn.pressed.connect(_on_size_preset_pressed.bind(6.0))
	size_presets_container.add_child(size_big_btn)
	
	var size_normal_btn = Button.new()
	size_normal_btn.text = "Normal"
	size_normal_btn.custom_minimum_size.x = 55
	size_normal_btn.pressed.connect(_on_size_preset_pressed.bind(8.0))
	size_presets_container.add_child(size_normal_btn)
	
	var size_small_btn = Button.new()
	size_small_btn.text = "Pequeño"
	size_small_btn.custom_minimum_size.x = 55
	size_small_btn.pressed.connect(_on_size_preset_pressed.bind(12.0))
	size_presets_container.add_child(size_small_btn)
	
	# Información adicional
	var info_label = Label.new()
	info_label.text = "💡 Valores menores = modelo más grande en sprite"
	info_label.add_theme_font_size_override("font_size", 9)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(info_label)

func _create_orientation_settings():
	"""Crear configuración de orientación"""
	var orientation_title = Label.new()
	orientation_title.text = "🧭 Orientación"
	orientation_title.add_theme_font_size_override("font_size", 14)
	orientation_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(orientation_title)
	
	
		# ✅ AGREGAR: Checkbox para mostrar cruz
	show_orientation_cross_check = CheckBox.new()
	show_orientation_cross_check.text = "Mostrar cruz de orientación"
	show_orientation_cross_check.button_pressed = true
	show_orientation_cross_check.toggled.connect(_on_orientation_cross_toggled)
	add_child(show_orientation_cross_check)
	
	# Detección automática de norte
	auto_north_check = CheckBox.new()
	auto_north_check.text = "Detectar orientación norte automáticamente"
	auto_north_check.button_pressed = true
	auto_north_check.toggled.connect(_on_auto_north_toggled)
	add_child(auto_north_check)
	
	# Descripción de detección automática
	var auto_desc = Label.new()
	auto_desc.text = "El sistema analiza la geometría del modelo para determinar el frente"
	auto_desc.add_theme_font_size_override("font_size", 9)
	auto_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	auto_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(auto_desc)
	
	# Norte del modelo
	var north_container = HBoxContainer.new()
	add_child(north_container)
	
	var north_label = Label.new()
	north_label.text = "Norte:"
	north_label.custom_minimum_size.x = 80
	north_container.add_child(north_label)
	
	north_offset_slider = HSlider.new()
	north_offset_slider.min_value = 0.0
	north_offset_slider.max_value = 360.0
	north_offset_slider.value = 0.0
	north_offset_slider.step = 1.0
	north_offset_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	north_offset_slider.value_changed.connect(_on_north_offset_changed)
	north_container.add_child(north_offset_slider)
	
	north_offset_label = Label.new()
	north_offset_label.text = "0°"
	north_offset_label.custom_minimum_size.x = 40
	north_container.add_child(north_offset_label)
	
	# Presets de orientación
	var presets_container = HBoxContainer.new()
	add_child(presets_container)
	
	var presets_label = Label.new()
	presets_label.text = "Presets:"
	presets_label.custom_minimum_size.x = 80
	presets_container.add_child(presets_label)
	
	var north_btn = Button.new()
	north_btn.text = "N"
	north_btn.custom_minimum_size.x = 30
	north_btn.pressed.connect(_on_preset_pressed.bind(0.0))
	north_btn.tooltip_text = "Norte (0°)"
	presets_container.add_child(north_btn)
	
	var east_btn = Button.new()
	east_btn.text = "E"
	east_btn.custom_minimum_size.x = 30
	east_btn.pressed.connect(_on_preset_pressed.bind(90.0))
	east_btn.tooltip_text = "Este (90°)"
	presets_container.add_child(east_btn)
	
	var south_btn = Button.new()
	south_btn.text = "S"
	south_btn.custom_minimum_size.x = 30
	south_btn.pressed.connect(_on_preset_pressed.bind(180.0))
	south_btn.tooltip_text = "Sur (180°)"
	presets_container.add_child(south_btn)
	
	var west_btn = Button.new()
	west_btn.text = "W"
	west_btn.custom_minimum_size.x = 30
	west_btn.pressed.connect(_on_preset_pressed.bind(270.0))
	west_btn.tooltip_text = "Oeste (270°)"
	presets_container.add_child(west_btn)

# ========================================================================
# APLICACIÓN DE CONFIGURACIÓN
# ========================================================================

func _apply_current_settings():
	"""Aplicar valores actuales a controles"""
	print("🔧 Aplicando configuración actual a controles")
	
	#altura
	
	# Aplicar valores básicos
	directions_spinbox.value = current_settings.directions
	sprite_size_spinbox.value = current_settings.sprite_size
	fps_spinbox.value = current_settings.fps
	pixelize_check.button_pressed = current_settings.pixelize
	
	# Aplicar valores de cámara
	camera_angle_slider.value = current_settings.camera_angle
	camera_height_slider.value = current_settings.camera_height  
	
	# Aplicar valores de orientación
	north_offset_slider.value = current_settings.north_offset
	auto_north_check.button_pressed = current_settings.auto_north_detection
	
	# Aplicar área de captura
	capture_area_slider.value = current_settings.capture_area_size
	
	# Actualizar labels
	_on_camera_angle_changed(current_settings.camera_angle)
	_on_camera_height_changed(current_settings.camera_height)  
	_on_north_offset_changed(current_settings.north_offset)
	_on_capture_area_changed(current_settings.capture_area_size)

# ========================================================================
# MANEJADORES DE EVENTOS
# ========================================================================

func _on_setting_changed(value = null):
	"""Manejar cambios en configuración básica"""
	# Actualizar configuración interna
	current_settings.directions = int(directions_spinbox.value)
	current_settings.sprite_size = int(sprite_size_spinbox.value)
	current_settings.fps = int(fps_spinbox.value)
	current_settings.pixelize = pixelize_check.button_pressed
	
	print("⚙️ Configuración básica actualizada")
	emit_signal("settings_changed", current_settings.duplicate())

func _on_camera_angle_changed(value: float):
	"""Manejar cambio en ángulo de cámara"""
	current_settings.camera_angle = value
	camera_angle_label.text = "%.0f°" % value
	
	print("📐 Ángulo de cámara: %.1f°" % value)
	emit_signal("settings_changed", current_settings.duplicate())

func _on_north_offset_changed(value: float):
	"""Manejar cambio en orientación norte"""
	current_settings.north_offset = value
	north_offset_label.text = "%.0f°" % value
	
	print("🧭 Orientación norte: %.1f°" % value)
	emit_signal("settings_changed", current_settings.duplicate())

func _on_capture_area_changed(value: float):
	"""Manejar cambio en área de captura"""
	current_settings.capture_area_size = value
	capture_area_label.text = "%.1f" % value
	
	# Convertir a configuración de cámara (para compatibilidad)
	current_settings.manual_zoom_override = true
	current_settings.fixed_orthographic_size = value
	
	print("🖼️ Área de captura: %.1f" % value)
	emit_signal("settings_changed", current_settings.duplicate())

	_update_capture_area_visual()
	
	
func _update_capture_area_visual():
	"""Actualizar indicador visual del área de captura"""
	# Buscar el ModelPreviewPanel y actualizar su indicador
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		var preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if preview_panel and preview_panel.has_method("update_capture_area_indicator"):
			preview_panel.update_capture_area_indicator()
			print("🔄 Indicador de área de captura actualizado")
	
func _on_size_preset_pressed(size_value: float):
	"""Manejar preset de tamaño"""
	capture_area_slider.value = size_value
	print("📐 Preset de tamaño aplicado: %.1f" % size_value)

func _on_auto_north_toggled(enabled: bool):
	"""Manejar detección automática de norte"""
	current_settings.auto_north_detection = enabled
	print("🧭 Detección automática de norte %s" % ("habilitada" if enabled else "deshabilitada"))
	if enabled:
		emit_signal("request_auto_north_detection")  # Nueva señal
	emit_signal("settings_changed", current_settings.duplicate())

func _on_preset_pressed(angle: float):
	"""Manejar preset de orientación"""
	north_offset_slider.value = angle
	print("🧭 Preset de orientación aplicado: %.1f°" % angle)
	emit_signal("preset_applied", "orientation_%.0f" % angle)

# ========================================================================
# FUNCIONES PÚBLICAS
# ========================================================================

func get_settings() -> Dictionary:
	"""Obtener configuración actual"""
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	"""Aplicar configuración externa"""
	print("📥 Aplicando configuración externa: %s" % str(settings))
	
	for key in settings:
		if key in current_settings:
			current_settings[key] = settings[key]
	
	_apply_current_settings()
	emit_signal("settings_changed", current_settings.duplicate())

func reset_to_defaults():
	"""Resetear a valores por defecto"""
	print("🔄 Reseteando a valores por defecto")
	
	current_settings = {
		"directions": 16,
		"sprite_size": 512,
		"fps": 30,
		"pixelize": true,
		"camera_angle": 45.0,
		"north_offset": 0.0,
		"capture_area_size": 8.0,
		"auto_north_detection": true
	}
	
	_apply_current_settings()
	emit_signal("settings_changed", current_settings.duplicate())

func apply_preset(preset_name: String):
	"""Aplicar preset específico"""
	print("🎯 Aplicando preset: %s" % preset_name)
	
	match preset_name:
		"rts_standard":
			current_settings.directions = 16
			current_settings.sprite_size = 512
			current_settings.camera_angle = 45.0
			current_settings.capture_area_size = 8.0
			current_settings.auto_north_detection = true
		
		"high_quality":
			current_settings.sprite_size = 512
			current_settings.fps = 30
			current_settings.capture_area_size = 6.0  # Modelo más grande
			current_settings.auto_north_detection = true
		
		"fast_preview":
			current_settings.directions = 8
			current_settings.sprite_size = 256
			current_settings.fps = 15
			current_settings.capture_area_size = 10.0  # Modelo más pequeño para preview rápido
			current_settings.auto_north_detection = true
		
		"model_showcase":
			current_settings.sprite_size = 512
			current_settings.fps = 30
			current_settings.capture_area_size = 4.0  # Modelo muy grande
			current_settings.auto_north_detection = true
			current_settings.directions = 16
		
		"pixel_art":
			current_settings.sprite_size = 64
			current_settings.fps = 30
			current_settings.capture_area_size = 6.0
			current_settings.pixelize = true
			current_settings.directions = 8
		
		"debug_large":
			current_settings.sprite_size = 512
			current_settings.fps = 15
			current_settings.capture_area_size = 3.0  # Modelo gigante para debug
			current_settings.directions = 4  # Solo 4 direcciones para debug rápido
	
	_apply_current_settings()
	emit_signal("preset_applied", preset_name)
	emit_signal("settings_changed", current_settings.duplicate())

# ========================================================================
# FUNCIONES DE INFORMACIÓN
# ========================================================================

func get_capture_info() -> String:
	"""Obtener información de captura para mostrar al usuario"""
	var area = current_settings.capture_area_size
	var description = ""
	
	if area <= 4.0:
		description = "Gigante - El modelo llena casi todo el sprite"
	elif area <= 6.0:
		description = "Grande - Modelo prominente en el sprite"
	elif area <= 8.0:
		description = "Normal - Tamaño balanceado"
	elif area <= 12.0:
		description = "Pequeño - Modelo con mucho espacio alrededor"
	else:
		description = "Muy pequeño - Modelo se ve lejano"
	
	return "Área: %.1f (%s)" % [area, description]

func get_orientation_info() -> String:
	"""Obtener información de orientación"""
	var angle = current_settings.north_offset
	var direction = ""
	
	if angle >= 0 and angle < 45:
		direction = "Norte"
	elif angle >= 45 and angle < 135:
		direction = "Este"
	elif angle >= 135 and angle < 225:
		direction = "Sur"
	elif angle >= 225 and angle < 315:
		direction = "Oeste"
	else:
		direction = "Norte"
	
	return "%.0f° (%s)" % [angle, direction]

# ========================================================================
# FUNCIONES DE DEBUG
# ========================================================================

func debug_settings():
	"""Debug de configuración actual"""
	print("\n=== SETTINGS PANEL DEBUG ===")
	print("Configuración actual:")
	for key in current_settings:
		print("  %s: %s" % [key, str(current_settings[key])])
	print("============================\n")

func validate_settings() -> bool:
	"""Validar que la configuración sea válida"""
	var valid = true
	
	if current_settings.directions < 4 or current_settings.directions > 32:
		print("❌ Direcciones inválidas: %d" % current_settings.directions)
		valid = false
	
	if current_settings.sprite_size < 32 or current_settings.sprite_size > 2048:
		print("❌ Tamaño de sprite inválido: %d" % current_settings.sprite_size)
		valid = false
	
	if current_settings.fps < 1 or current_settings.fps > 120:
		print("❌ FPS inválido: %d" % current_settings.fps)
		valid = false
	
	if current_settings.capture_area_size < 1.0 or current_settings.capture_area_size > 50.0:
		print("❌ Área de captura inválida: %.1f" % current_settings.capture_area_size)
		valid = false
	
	return valid


func _on_orientation_cross_toggled(enabled: bool):
	"""Manejar mostrar/ocultar cruz de orientación"""
	print("🎯 Cruz de orientación: %s" % ("visible" if enabled else "oculta"))
	
	# Buscar preview panel y actualizar
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		var preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if preview_panel:
			if enabled:
				if preview_panel.has_method("show_orientation_cross"):
					preview_panel.show_orientation_cross()
			else:
				if preview_panel.has_method("hide_orientation_cross"):
					preview_panel.hide_orientation_cross()
