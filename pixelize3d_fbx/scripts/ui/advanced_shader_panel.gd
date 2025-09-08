# scripts/ui/advanced_shader_panel.gd
# Panel avanzado de shader con soporte para POST-PROCESSING
# Input: Interacción del usuario con controles de pixelización
# Output: Configuración de post-processing para aplicar a toda la pantalla

extends VBoxContainer

# === SEÑAL PRINCIPAL ===
signal shader_settings_changed(settings: Dictionary)
signal reset_to_defaults_requested()

# === CONTROLES UI PIXELIZACIÓN ===
var pixelize_enabled_check: CheckBox
var pixel_size_slider: HSlider
var pixel_size_label: Label

# === CONTROLES UI REDUCCIÓN DE COLORES ===
var reduce_colors_check: CheckBox
var color_levels_slider: HSlider
var color_levels_label: Label

# === CONTROLES UI DITHERING ===
var enable_dithering_check: CheckBox
var dither_strength_slider: HSlider
var dither_strength_label: Label

# === CONTROLES UI EFECTOS AVANZADOS ===
var contrast_enabled_check: CheckBox
var contrast_boost_slider: HSlider
var contrast_boost_label: Label
var saturation_enabled_check: CheckBox
var saturation_mult_slider: HSlider
var saturation_mult_label: Label
var tint_enabled_check: CheckBox
var color_tint_picker: ColorPicker

# === CONTROLES DE ACCIÓN ===
var apply_button: Button
var clear_button: Button
var reset_button: Button

# === CONFIGURACIÓN ACTUAL ===
var current_settings: Dictionary = {
	"pixelize_enabled": true,
	"pixel_size": 2.0,
	"reduce_colors": false,
	"color_levels": 16,
	"enable_dithering": false,
	"dither_strength": 0.1,
	"contrast_enabled": false,
	"contrast_boost": 1.0,
	"saturation_enabled": false,
	"saturation_mult": 1.0,
	"tint_enabled": false,
	"color_tint": Color.WHITE,
	"post_processing": true,  # Indica que es post-processing
	"shader_path": "res://resources/shaders/pixelize_postprocess.gdshader"
}

# ========================================================================
# INICIALIZACIÓN
# ========================================================================

func _ready():
	print("🎨 AdvancedShaderPanel POST-PROCESSING inicializando...")
	_create_postprocess_ui()
	_connect_all_signals()
	print("✅ Panel de post-processing listo")

func _create_postprocess_ui():
	"""Crear interfaz para post-processing"""
	
	# Crear container con scroll para opciones
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)
	
	var main_vbox = VBoxContainer.new()
	scroll_container.add_child(main_vbox)
	
	# Título principal
	var title = Label.new()
	title.text = "🎨 Pixelización Post-Processing"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	main_vbox.add_child(HSeparator.new())
	
	# Info del sistema
	var info_label = Label.new()
	info_label.text = "✅ Sistema: Post-Processing (pantalla completa)"
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.add_theme_color_override("font_color", Color.GREEN)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(info_label)
	
	main_vbox.add_child(HSeparator.new())
	
	# === SECCIÓN PRINCIPAL: PIXELIZACIÓN ===
	_create_pixelization_section(main_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# === SECCIÓN: REDUCCIÓN DE COLORES ===
	_create_color_reduction_section(main_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# === SECCIÓN: DITHERING ===
	_create_dithering_section(main_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# === SECCIÓN: EFECTOS AVANZADOS ===
	_create_advanced_effects_section(main_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# === PRESETS ===
	_create_presets_section(main_vbox)
	
	main_vbox.add_child(HSeparator.new())
	
	# === BOTONES DE ACCIÓN ===
	_create_action_buttons()

func _create_pixelization_section(parent: VBoxContainer):
	"""Crear sección de pixelización principal"""
	var pixel_title = Label.new()
	pixel_title.text = "🟦 Pixelización"
	pixel_title.add_theme_font_size_override("font_size", 14)
	pixel_title.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	parent.add_child(pixel_title)
	
	# Checkbox principal para habilitar/deshabilitar
	pixelize_enabled_check = CheckBox.new()
	pixelize_enabled_check.text = "Habilitar Pixelización"
	pixelize_enabled_check.button_pressed = true
	pixelize_enabled_check.toggled.connect(_on_pixelize_enabled_changed)
	parent.add_child(pixelize_enabled_check)
	
	# Tamaño de píxel
	var pixel_size_container = HBoxContainer.new()
	parent.add_child(pixel_size_container)
	
	var pixel_label = Label.new()
	pixel_label.text = "Tamaño:"
	pixel_label.custom_minimum_size.x = 80
	pixel_size_container.add_child(pixel_label)
	
	pixel_size_slider = HSlider.new()
	pixel_size_slider.min_value = 0.0
	pixel_size_slider.max_value = 32.0
	pixel_size_slider.step = 0.1
	pixel_size_slider.value = 2.0
	pixel_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pixel_size_slider.value_changed.connect(_on_pixel_size_changed)
	pixel_size_container.add_child(pixel_size_slider)
	
	pixel_size_label = Label.new()
	pixel_size_label.text = str(pixel_size_slider.value)
	pixel_size_label.custom_minimum_size.x = 30
	pixel_size_container.add_child(pixel_size_label)

func _create_color_reduction_section(parent: VBoxContainer):
	"""Crear sección de reducción de colores"""
	var color_title = Label.new()
	color_title.text = "🎨 Reducción de Colores"
	color_title.add_theme_font_size_override("font_size", 14)
	color_title.add_theme_color_override("font_color", Color.YELLOW)
	parent.add_child(color_title)
	
	# Checkbox para habilitar reducción de colores
	reduce_colors_check = CheckBox.new()
	reduce_colors_check.text = "Reducir Colores"
	reduce_colors_check.button_pressed = false
	reduce_colors_check.toggled.connect(_on_reduce_colors_changed)
	parent.add_child(reduce_colors_check)
	
	# Niveles de color
	var color_levels_container = HBoxContainer.new()
	parent.add_child(color_levels_container)
	
	var levels_label = Label.new()
	levels_label.text = "Niveles:"
	levels_label.custom_minimum_size.x = 80
	color_levels_container.add_child(levels_label)
	
	color_levels_slider = HSlider.new()
	color_levels_slider.min_value = 2
	color_levels_slider.max_value = 64
	color_levels_slider.step = 1
	color_levels_slider.value = 16
	color_levels_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_levels_slider.value_changed.connect(_on_color_levels_changed)
	color_levels_container.add_child(color_levels_slider)
	
	color_levels_label = Label.new()
	color_levels_label.text = "16"
	color_levels_label.custom_minimum_size.x = 30
	color_levels_container.add_child(color_levels_label)

func _create_dithering_section(parent: VBoxContainer):
	"""Crear sección de dithering"""
	var dither_title = Label.new()
	dither_title.text = "⚫ Dithering"
	dither_title.add_theme_font_size_override("font_size", 14)
	dither_title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	parent.add_child(dither_title)
	
	# Checkbox para habilitar dithering
	enable_dithering_check = CheckBox.new()
	enable_dithering_check.text = "Habilitar Dithering"
	enable_dithering_check.button_pressed = false
	enable_dithering_check.toggled.connect(_on_dithering_enabled_changed)
	parent.add_child(enable_dithering_check)
	
	# Intensidad del dithering
	var dither_strength_container = HBoxContainer.new()
	parent.add_child(dither_strength_container)
	
	var strength_label = Label.new()
	strength_label.text = "Intensidad:"
	strength_label.custom_minimum_size.x = 80
	dither_strength_container.add_child(strength_label)
	
	dither_strength_slider = HSlider.new()
	dither_strength_slider.min_value = 0.0
	dither_strength_slider.max_value = 1.0
	dither_strength_slider.step = 0.01
	dither_strength_slider.value = 0.1
	dither_strength_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dither_strength_slider.value_changed.connect(_on_dither_strength_changed)
	dither_strength_container.add_child(dither_strength_slider)
	
	dither_strength_label = Label.new()
	dither_strength_label.text = "0.10"
	dither_strength_label.custom_minimum_size.x = 40
	dither_strength_container.add_child(dither_strength_label)

func _create_advanced_effects_section(parent: VBoxContainer):
	"""Crear sección de efectos avanzados"""
	var effects_title = Label.new()
	effects_title.text = "✨ Efectos Avanzados"
	effects_title.add_theme_font_size_override("font_size", 14)
	effects_title.add_theme_color_override("font_color", Color.MAGENTA)
	parent.add_child(effects_title)
	
	# === CONTRASTE ===
	contrast_enabled_check = CheckBox.new()
	contrast_enabled_check.text = "Ajustar Contraste"
	contrast_enabled_check.button_pressed = false
	contrast_enabled_check.toggled.connect(_on_contrast_enabled_changed)
	parent.add_child(contrast_enabled_check)
	
	var contrast_container = HBoxContainer.new()
	parent.add_child(contrast_container)
	
	var contrast_label = Label.new()
	contrast_label.text = "Contraste:"
	contrast_label.custom_minimum_size.x = 80
	contrast_container.add_child(contrast_label)
	
	contrast_boost_slider = HSlider.new()
	contrast_boost_slider.min_value = 0.5
	contrast_boost_slider.max_value = 2.0
	contrast_boost_slider.step = 0.01
	contrast_boost_slider.value = 1.0
	contrast_boost_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contrast_boost_slider.value_changed.connect(_on_contrast_boost_changed)
	contrast_container.add_child(contrast_boost_slider)
	
	contrast_boost_label = Label.new()
	contrast_boost_label.text = "1.00"
	contrast_boost_label.custom_minimum_size.x = 40
	contrast_container.add_child(contrast_boost_label)
	
	# === SATURACIÓN ===
	saturation_enabled_check = CheckBox.new()
	saturation_enabled_check.text = "Ajustar Saturación"
	saturation_enabled_check.button_pressed = false
	saturation_enabled_check.toggled.connect(_on_saturation_enabled_changed)
	parent.add_child(saturation_enabled_check)
	
	var saturation_container = HBoxContainer.new()
	parent.add_child(saturation_container)
	
	var saturation_label = Label.new()
	saturation_label.text = "Saturación:"
	saturation_label.custom_minimum_size.x = 80
	saturation_container.add_child(saturation_label)
	
	saturation_mult_slider = HSlider.new()
	saturation_mult_slider.min_value = 0.0
	saturation_mult_slider.max_value = 2.0
	saturation_mult_slider.step = 0.01
	saturation_mult_slider.value = 1.0
	saturation_mult_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saturation_mult_slider.value_changed.connect(_on_saturation_mult_changed)
	saturation_container.add_child(saturation_mult_slider)
	
	saturation_mult_label = Label.new()
	saturation_mult_label.text = "1.00"
	saturation_mult_label.custom_minimum_size.x = 40
	saturation_container.add_child(saturation_mult_label)
	
	# === TINTE DE COLOR ===
	tint_enabled_check = CheckBox.new()
	tint_enabled_check.text = "Tinte de Color"
	tint_enabled_check.button_pressed = false
	tint_enabled_check.toggled.connect(_on_tint_enabled_changed)
	parent.add_child(tint_enabled_check)
	
	var color_container = HBoxContainer.new()
	parent.add_child(color_container)
	
	var color_title = Label.new()
	color_title.text = "Color:"
	color_title.custom_minimum_size.x = 80
	color_container.add_child(color_title)
	
	color_tint_picker = ColorPicker.new()
	color_tint_picker.color = Color.WHITE
	color_tint_picker.custom_minimum_size = Vector2(180, 120)
	color_tint_picker.color_changed.connect(_on_color_tint_changed)
	color_container.add_child(color_tint_picker)

func _create_presets_section(parent: VBoxContainer):
	"""Crear sección de presets"""
	var presets_title = Label.new()
	presets_title.text = "⚡ Presets Rápidos"
	presets_title.add_theme_font_size_override("font_size", 14)
	presets_title.add_theme_color_override("font_color", Color.ORANGE)
	parent.add_child(presets_title)
	
	var presets_container = HBoxContainer.new()
	parent.add_child(presets_container)
	
	var preset_retro = Button.new()
	preset_retro.text = "Retro"
	preset_retro.custom_minimum_size.x = 80
	preset_retro.pressed.connect(_apply_preset.bind("retro"))
	presets_container.add_child(preset_retro)
	
	var preset_modern = Button.new()
	preset_modern.text = "Moderno"
	preset_modern.custom_minimum_size.x = 80
	preset_modern.pressed.connect(_apply_preset.bind("modern"))
	presets_container.add_child(preset_modern)
	
	var preset_gameboy = Button.new()
	preset_gameboy.text = "Game Boy"
	preset_gameboy.custom_minimum_size.x = 80
	preset_gameboy.pressed.connect(_apply_preset.bind("gameboy"))
	presets_container.add_child(preset_gameboy)
	
	var preset_off = Button.new()
	preset_off.text = "Desactivar"
	preset_off.custom_minimum_size.x = 80
	preset_off.pressed.connect(_apply_preset.bind("off"))
	presets_container.add_child(preset_off)

func _create_action_buttons():
	"""Crear botones de acción"""
	var buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(buttons_container)
	
	apply_button = Button.new()
	apply_button.text = "✅ Aplicar"
	apply_button.custom_minimum_size.x = 80
	apply_button.pressed.connect(_on_apply_pressed)
	buttons_container.add_child(apply_button)
	
	clear_button = Button.new()
	clear_button.text = "🧹 Limpiar"
	clear_button.custom_minimum_size.x = 80
	clear_button.pressed.connect(_on_clear_pressed)
	buttons_container.add_child(clear_button)
	
	reset_button = Button.new()
	reset_button.text = "🔄 Reset"
	reset_button.custom_minimum_size.x = 80
	reset_button.pressed.connect(_on_reset_pressed)
	buttons_container.add_child(reset_button)

# ========================================================================
# MANEJADORES DE EVENTOS
# ========================================================================

func _connect_all_signals():
	"""Conectar todas las señales necesarias"""
	print("🔗 Conectando señales del panel de post-processing...")
	# Las señales ya están conectadas en la creación de UI
	print("✅ Todas las señales conectadas")

func _on_pixelize_enabled_changed(enabled: bool):
	"""Manejar activación/desactivación principal"""
	current_settings.pixelize_enabled = enabled
	print("🎨 Post-processing %s" % ("habilitado" if enabled else "deshabilitado"))
	_emit_settings_signal()

func _on_pixel_size_changed(value: float):
	"""Manejar cambio en tamaño de píxel"""
	pixel_size_label.text = "%.0f" % value
	current_settings.pixel_size = value
	_emit_settings_signal()

func _on_reduce_colors_changed(enabled: bool):
	"""Manejar activación de reducción de colores"""
	current_settings.reduce_colors = enabled
	print("🎨 Reducción de colores %s" % ("habilitada" if enabled else "deshabilitada"))
	_emit_settings_signal()

func _on_color_levels_changed(value: float):
	"""Manejar cambio en niveles de color"""
	color_levels_label.text = "%d" % int(value)
	current_settings.color_levels = int(value)
	_emit_settings_signal()

func _on_dithering_enabled_changed(enabled: bool):
	"""Manejar activación de dithering"""
	current_settings.enable_dithering = enabled
	print("⚫ Dithering %s" % ("habilitado" if enabled else "deshabilitado"))
	_emit_settings_signal()

func _on_dither_strength_changed(value: float):
	"""Manejar cambio en intensidad de dithering"""
	dither_strength_label.text = "%.2f" % value
	current_settings.dither_strength = value
	_emit_settings_signal()

func _on_contrast_enabled_changed(enabled: bool):
	"""Manejar activación de ajuste de contraste"""
	current_settings.contrast_enabled = enabled
	print("✨ Ajuste de contraste %s" % ("habilitado" if enabled else "deshabilitado"))
	_emit_settings_signal()

func _on_contrast_boost_changed(value: float):
	"""Manejar cambio en contraste"""
	contrast_boost_label.text = "%.2f" % value
	current_settings.contrast_boost = value
	_emit_settings_signal()

func _on_saturation_enabled_changed(enabled: bool):
	"""Manejar activación de ajuste de saturación"""
	current_settings.saturation_enabled = enabled
	print("✨ Ajuste de saturación %s" % ("habilitado" if enabled else "deshabilitado"))
	_emit_settings_signal()

func _on_saturation_mult_changed(value: float):
	"""Manejar cambio en saturación"""
	saturation_mult_label.text = "%.2f" % value
	current_settings.saturation_mult = value
	_emit_settings_signal()

func _on_tint_enabled_changed(enabled: bool):
	"""Manejar activación de tinte"""
	current_settings.tint_enabled = enabled
	print("✨ Tinte de color %s" % ("habilitado" if enabled else "deshabilitado"))
	_emit_settings_signal()

func _on_color_tint_changed(color: Color):
	"""Manejar cambio en color de tinte"""
	current_settings.color_tint = color
	print("🎨 Color de tinte cambiado: %s" % color)
	_emit_settings_signal()

func _on_apply_pressed():
	"""Aplicar configuración manualmente"""
	print("🎨 Aplicando post-processing manualmente...")
	current_settings.pixelize_enabled = true
	pixelize_enabled_check.button_pressed = true
	_emit_settings_signal()

func _on_clear_pressed():
	"""Quitar post-processing completamente"""
	print("🧹 Desactivando post-processing...")
	current_settings.pixelize_enabled = false
	pixelize_enabled_check.button_pressed = false
	_emit_settings_signal()

func _on_reset_pressed():
	"""Resetear a valores por defecto"""
	print("🔄 Reseteando configuración...")
	reset_to_defaults_requested.emit()
	_reset_to_defaults()

# ========================================================================
# SISTEMA DE PRESETS
# ========================================================================

func _apply_preset(preset_name: String):
	"""Aplicar preset de configuración"""
	print("⚡ Aplicando preset: %s" % preset_name)
	
	match preset_name:
		"retro":
			_set_preset_values(true, 8.0, true, 8, true, 0.3, false, 1.0, false, 1.0, false, Color.WHITE)
		"modern":
			_set_preset_values(true, 2.0, false, 16, false, 0.1, true, 1.2, true, 1.1, false, Color.WHITE)
		"gameboy":
			_set_preset_values(true, 4.0, true, 4, true, 0.2, true, 1.3, false, 0.0, true, Color(0.6, 0.8, 0.4))
		"off":
			_set_preset_values(false, 4.0, false, 16, false, 0.1, false, 1.0, false, 1.0, false, Color.WHITE)
	
	_emit_settings_signal()

func _set_preset_values(
	pixelize: bool, pixel_sz: float, 
	reduce_col: bool, col_levels: int,
	dither: bool, dither_str: float,
	contrast: bool, contrast_val: float,
	saturation: bool, saturation_val: float,
	tint: bool, tint_color: Color
):
	"""Aplicar valores específicos de preset"""
	# Pixelización
	pixelize_enabled_check.button_pressed = pixelize
	pixel_size_slider.value = pixel_sz
	pixel_size_label.text = "%.1f" % pixel_sz
	
	# Reducción de colores
	reduce_colors_check.button_pressed = reduce_col
	color_levels_slider.value = col_levels
	color_levels_label.text = "%d" % col_levels
	
	# Dithering
	enable_dithering_check.button_pressed = dither
	dither_strength_slider.value = dither_str
	dither_strength_label.text = "%.2f" % dither_str
	
	# Contraste
	contrast_enabled_check.button_pressed = contrast
	contrast_boost_slider.value = contrast_val
	contrast_boost_label.text = "%.2f" % contrast_val
	
	# Saturación
	saturation_enabled_check.button_pressed = saturation
	saturation_mult_slider.value = saturation_val
	saturation_mult_label.text = "%.2f" % saturation_val
	
	# Tinte
	tint_enabled_check.button_pressed = tint
	color_tint_picker.color = tint_color
	
	# Actualizar configuración
	_update_current_settings()

# ========================================================================
# LÓGICA DE CONFIGURACIÓN
# ========================================================================

func _update_current_settings():
	"""Actualizar configuración actual desde UI"""
	current_settings.pixelize_enabled = pixelize_enabled_check.button_pressed
	current_settings.pixel_size = pixel_size_slider.value
	current_settings.reduce_colors = reduce_colors_check.button_pressed
	current_settings.color_levels = int(color_levels_slider.value)
	current_settings.enable_dithering = enable_dithering_check.button_pressed
	current_settings.dither_strength = dither_strength_slider.value
	current_settings.contrast_enabled = contrast_enabled_check.button_pressed
	current_settings.contrast_boost = contrast_boost_slider.value
	current_settings.saturation_enabled = saturation_enabled_check.button_pressed
	current_settings.saturation_mult = saturation_mult_slider.value
	current_settings.tint_enabled = tint_enabled_check.button_pressed
	current_settings.color_tint = color_tint_picker.color
	current_settings.post_processing = true
	current_settings.shader_path = "res://resources/shaders/pixelize_postprocess.gdshader"

func _emit_settings_signal():
	"""Emitir señal con configuración actual"""
	_update_current_settings()
	#print("📡 Emitiendo señal: shader_settings_changed (POST-PROCESSING)")
	#print("   - pixelize_enabled: %s" % current_settings.pixelize_enabled)
	#print("   - pixel_size: %.0f" % current_settings.pixel_size)
	#print("   - reduce_colors: %s" % current_settings.reduce_colors)
	#print("   - enable_dithering: %s" % current_settings.enable_dithering)
	#print("   - post_processing: %s" % current_settings.post_processing)
	
	# Emitir señal
	shader_settings_changed.emit(current_settings.duplicate())

# ========================================================================
# API PÚBLICA
# ========================================================================

func get_current_settings() -> Dictionary:
	"""Obtener configuración actual"""
	_update_current_settings()
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	"""Aplicar configuración externa"""
	current_settings = settings.duplicate()
	
	# Actualizar UI
	pixelize_enabled_check.button_pressed = current_settings.get("pixelize_enabled", false)
	pixel_size_slider.value = current_settings.get("pixel_size", 2.0)
	pixel_size_label.text = "%.2f" % pixel_size_slider.value
	reduce_colors_check.button_pressed = current_settings.get("reduce_colors", false)
	color_levels_slider.value = current_settings.get("color_levels", 16)
	color_levels_label.text = "%d" % color_levels_slider.value
	enable_dithering_check.button_pressed = current_settings.get("enable_dithering", false)
	dither_strength_slider.value = current_settings.get("dither_strength", 0.1)
	dither_strength_label.text = "%.2f" % dither_strength_slider.value
	contrast_enabled_check.button_pressed = current_settings.get("contrast_enabled", false)
	contrast_boost_slider.value = current_settings.get("contrast_boost", 1.0)
	contrast_boost_label.text = "%.2f" % contrast_boost_slider.value
	saturation_enabled_check.button_pressed = current_settings.get("saturation_enabled", false)
	saturation_mult_slider.value = current_settings.get("saturation_mult", 1.0)
	saturation_mult_label.text = "%.2f" % saturation_mult_slider.value
	tint_enabled_check.button_pressed = current_settings.get("tint_enabled", false)
	color_tint_picker.color = current_settings.get("color_tint", Color.WHITE)
	
	print("⚙️ Configuración de post-processing aplicada desde externa")

func force_emit_current_settings():
	"""Forzar emisión de configuración actual"""
	_emit_settings_signal()

func _reset_to_defaults():
	"""Resetear a configuración por defecto"""
	current_settings = {
		"pixelize_enabled": true,
		"pixel_size": 2.0,
		"reduce_colors": false,
		"color_levels": 16,
		"enable_dithering": false,
		"dither_strength": 0.1,
		"contrast_enabled": false,
		"contrast_boost": 1.0,
		"saturation_enabled": false,
		"saturation_mult": 1.0,
		"tint_enabled": false,
		"color_tint": Color.WHITE,
		"post_processing": true,
		"shader_path": "res://resources/shaders/pixelize_postprocess.gdshader"
	}
	
	apply_settings(current_settings)
	_emit_settings_signal()

# ========================================================================
# FUNCIONES DE UTILIDAD
# ========================================================================

func is_postprocessing_enabled() -> bool:
	"""Verificar si post-processing está habilitado"""
	return current_settings.get("pixelize_enabled", false)

func debug_panel_state():
	"""Debug del estado del panel"""
	pass
	#print("\n🔍 === DEBUG PANEL CANVAS POST-PROCESSING ===")
	#print("pixelize_enabled: %s" % current_settings.pixelize_enabled)
	#print("pixel_size: %.0f" % current_settings.pixel_size)
	#print("reduce_colors: %s" % current_settings.reduce_colors)
	#print("enable_dithering: %s" % current_settings.enable_dithering)
	#print("canvas_postprocess: %s" % current_settings.get("canvas_postprocess", true))
	#print("post_processing: %s" % current_settings.post_processing)
	#print("shader_path: %s" % current_settings.get("shader_path", "N/A"))
	#print("============================================\n")
