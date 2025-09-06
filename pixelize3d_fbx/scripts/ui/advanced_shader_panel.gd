# scripts/ui/advanced_shader_panel.gd
# Panel avanzado de shader con soporte completo para outline 3D y efectos
# Input: Interacción del usuario con controles avanzados
# Output: Configuración de shader con bordes 3D configurables

extends VBoxContainer

# === SEÑAL PRINCIPAL ===
signal shader_settings_changed(settings: Dictionary)
signal reset_to_defaults_requested()

# === CONTROLES UI BÁSICOS ===
var pixelize_enabled_check: CheckBox
var pixel_size_slider: HSlider
var pixel_size_label: Label
var reduce_colors_check: CheckBox
var color_levels_slider: HSlider
var color_levels_label: Label

# === CONTROLES UI OUTLINE 3D ===
var outline_enabled_check: CheckBox
var outline_thickness_slider: HSlider
var outline_thickness_label: Label
var outline_color_picker: ColorPicker
var outline_pixelated_check: CheckBox
var outline_3d_mode_check: CheckBox
var outline_auto_detect_check: CheckBox

# === CONTROLES DE ACCIÓN ===
var apply_button: Button
var clear_button: Button
var reset_button: Button

# === CONFIGURACIÓN ACTUAL ===
var current_settings: Dictionary = {
	"pixelize_enabled": true,
	"pixel_size": 4.0,
	"reduce_colors": false,
	"color_levels": 16,
	"enable_dithering": false,
	"enable_outline": false,
	"outline_thickness": 1.0,
	"outline_color": Color.BLACK,
	"outline_pixelated": true,
	"outline_auto_detect": true,
	"outline_3d_mode": true,
	"contrast_boost": 1.0,
	"saturation_mult": 1.0,
	"color_tint": Color.WHITE,
	"apply_gamma_correction": false,
	"gamma_value": 1.0,
	"shader_path": "res://resources/shaders/pixelize_spatial.gdshader"
}

# ========================================================================
# INICIALIZACIÓN
# ========================================================================

func _ready():
	print("🎨 AdvancedShaderPanel con soporte 3D outline inicializando...")
	_create_complete_ui()
	_connect_all_signals()
	print("✅ Panel avanzado completo listo")

func _create_complete_ui():
	"""Crear interfaz completa con todas las opciones"""
	
	# Título principal
	var title = Label.new()
	title.text = "🎨 Configuración Avanzada de Shader"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	add_child(HSeparator.new())
	
	# Info del shader
	var info_label = Label.new()
	info_label.text = "✅ Sistema: pixelize_spatial.gdshader + outline_3d.gdshader"
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.add_theme_color_override("font_color", Color.GREEN)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_label)
	
	add_child(HSeparator.new())
	
	# === SECCIÓN PIXELIZACIÓN ===
	_create_pixelization_section()
	
	add_child(HSeparator.new())
	
	# === SECCIÓN OUTLINE 3D ===
	_create_outline_3d_section()
	
	add_child(HSeparator.new())
	
	# === SECCIÓN REDUCCIÓN DE COLORES ===
	_create_color_reduction_section()
	
	add_child(HSeparator.new())
	
	# === PRESETS ===
	_create_presets_section()
	
	add_child(HSeparator.new())
	
	# === BOTONES DE ACCIÓN ===
	_create_action_buttons()

func _create_pixelization_section():
	"""Crear sección de pixelización"""
	var pixel_title = Label.new()
	pixel_title.text = "🟦 Pixelización"
	pixel_title.add_theme_font_size_override("font_size", 14)
	pixel_title.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	add_child(pixel_title)
	
	# Habilitar pixelización
	pixelize_enabled_check = CheckBox.new()
	pixelize_enabled_check.text = "Habilitar Pixelización"
	pixelize_enabled_check.button_pressed = true
	pixelize_enabled_check.toggled.connect(_on_setting_changed)
	add_child(pixelize_enabled_check)
	
	# Tamaño de píxel
	var pixel_size_container = HBoxContainer.new()
	add_child(pixel_size_container)
	
	var pixel_label = Label.new()
	pixel_label.text = "Tamaño:"
	pixel_label.custom_minimum_size.x = 80
	pixel_size_container.add_child(pixel_label)
	
	pixel_size_slider = HSlider.new()
	pixel_size_slider.min_value = 1.0
	pixel_size_slider.max_value = 32.0
	pixel_size_slider.step = 1.0
	pixel_size_slider.value = 4.0
	pixel_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pixel_size_slider.value_changed.connect(_on_pixel_size_changed)
	pixel_size_container.add_child(pixel_size_slider)
	
	pixel_size_label = Label.new()
	pixel_size_label.text = "4"
	pixel_size_label.custom_minimum_size.x = 30
	pixel_size_container.add_child(pixel_size_label)

func _create_outline_3d_section():
	"""Crear sección completa de outline 3D"""
	var outline_title = Label.new()
	outline_title.text = "🔲 Bordes 3D Avanzados"
	outline_title.add_theme_font_size_override("font_size", 14)
	outline_title.add_theme_color_override("font_color", Color.ORANGE)
	add_child(outline_title)
	
	# Descripción del outline 3D
	var outline_desc = Label.new()
	outline_desc.text = "Bordes reales mediante expansión de vértices (no post-procesamiento)"
	outline_desc.add_theme_font_size_override("font_size", 9)
	outline_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	outline_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(outline_desc)
	
	# Habilitar outline
	outline_enabled_check = CheckBox.new()
	outline_enabled_check.text = "Habilitar Bordes 3D"
	outline_enabled_check.button_pressed = false
	outline_enabled_check.toggled.connect(_on_outline_enabled_changed)
	add_child(outline_enabled_check)
	
	# Grosor del outline
	var thickness_container = HBoxContainer.new()
	add_child(thickness_container)
	
	var thickness_label = Label.new()
	thickness_label.text = "Grosor:"
	thickness_label.custom_minimum_size.x = 80
	thickness_container.add_child(thickness_label)
	
	outline_thickness_slider = HSlider.new()
	outline_thickness_slider.min_value = 0.1
	outline_thickness_slider.max_value = 5.0
	outline_thickness_slider.step = 0.1
	outline_thickness_slider.value = 1.0
	outline_thickness_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outline_thickness_slider.value_changed.connect(_on_outline_thickness_changed)
	thickness_container.add_child(outline_thickness_slider)
	
	outline_thickness_label = Label.new()
	outline_thickness_label.text = "1.0"
	outline_thickness_label.custom_minimum_size.x = 30
	thickness_container.add_child(outline_thickness_label)
	
	# Color del outline - versión compacta
	var color_container = HBoxContainer.new()
	add_child(color_container)
	
	var color_title = Label.new()
	color_title.text = "Color:"
	color_title.custom_minimum_size.x = 80
	color_container.add_child(color_title)
	
	outline_color_picker = ColorPicker.new()
	outline_color_picker.color = Color.BLACK
	outline_color_picker.custom_minimum_size = Vector2(180, 120)
	outline_color_picker.color_changed.connect(_on_outline_color_changed)
	color_container.add_child(outline_color_picker)
	
	# Opciones del outline
	outline_pixelated_check = CheckBox.new()
	outline_pixelated_check.text = "Bordes Pixelizados"
	outline_pixelated_check.button_pressed = true
	outline_pixelated_check.tooltip_text = "Los bordes siguen el estilo pixelizado del modelo"
	outline_pixelated_check.toggled.connect(_on_setting_changed)
	add_child(outline_pixelated_check)
	
	outline_3d_mode_check = CheckBox.new()
	outline_3d_mode_check.text = "Modo 3D Real (recomendado)"
	outline_3d_mode_check.button_pressed = true
	outline_3d_mode_check.tooltip_text = "Usa expansión de vértices para bordes reales"
	outline_3d_mode_check.toggled.connect(_on_setting_changed)
	add_child(outline_3d_mode_check)
	
	outline_auto_detect_check = CheckBox.new()
	outline_auto_detect_check.text = "Detección Automática de Bordes"
	outline_auto_detect_check.button_pressed = true
	outline_auto_detect_check.tooltip_text = "Detecta automáticamente dónde aplicar bordes"
	outline_auto_detect_check.toggled.connect(_on_setting_changed)
	add_child(outline_auto_detect_check)

func _create_color_reduction_section():
	"""Crear sección de reducción de colores"""
	var color_title = Label.new()
	color_title.text = "🎨 Reducción de Colores"
	color_title.add_theme_font_size_override("font_size", 14)
	color_title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(color_title)
	
	# Habilitar reducción de colores
	reduce_colors_check = CheckBox.new()
	reduce_colors_check.text = "Reducir Colores"
	reduce_colors_check.button_pressed = false
	reduce_colors_check.toggled.connect(_on_setting_changed)
	add_child(reduce_colors_check)
	
	# Niveles de color
	var color_levels_container = HBoxContainer.new()
	add_child(color_levels_container)
	
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

func _create_presets_section():
	"""Crear sección de presets"""
	var presets_title = Label.new()
	presets_title.text = "⚡ Presets Rápidos"
	presets_title.add_theme_font_size_override("font_size", 14)
	presets_title.add_theme_color_override("font_color", Color.MAGENTA)
	add_child(presets_title)
	
	# Presets de outline
	var outline_presets_container = HBoxContainer.new()
	add_child(outline_presets_container)
	
	var outline_presets_label = Label.new()
	outline_presets_label.text = "Bordes:"
	outline_presets_label.custom_minimum_size.x = 80
	outline_presets_container.add_child(outline_presets_label)
	
	var preset_thin = Button.new()
	preset_thin.text = "Fino"
	preset_thin.custom_minimum_size.x = 60
	preset_thin.pressed.connect(_apply_outline_preset.bind("thin"))
	outline_presets_container.add_child(preset_thin)
	
	var preset_medium = Button.new()
	preset_medium.text = "Medio"
	preset_medium.custom_minimum_size.x = 60
	preset_medium.pressed.connect(_apply_outline_preset.bind("medium"))
	outline_presets_container.add_child(preset_medium)
	
	var preset_thick = Button.new()
	preset_thick.text = "Grueso"
	preset_thick.custom_minimum_size.x = 60
	preset_thick.pressed.connect(_apply_outline_preset.bind("thick"))
	outline_presets_container.add_child(preset_thick)
	
	var preset_off = Button.new()
	preset_off.text = "Sin Borde"
	preset_off.custom_minimum_size.x = 80
	preset_off.pressed.connect(_apply_outline_preset.bind("off"))
	outline_presets_container.add_child(preset_off)
	
	# Presets generales
	var general_presets_container = HBoxContainer.new()
	add_child(general_presets_container)
	
	var general_presets_label = Label.new()
	general_presets_label.text = "Generales:"
	general_presets_label.custom_minimum_size.x = 80
	general_presets_container.add_child(general_presets_label)
	
	var preset_retro = Button.new()
	preset_retro.text = "Retro"
	preset_retro.custom_minimum_size.x = 60
	preset_retro.pressed.connect(_apply_general_preset.bind("retro"))
	general_presets_container.add_child(preset_retro)
	
	var preset_modern = Button.new()
	preset_modern.text = "Moderno"
	preset_modern.custom_minimum_size.x = 60
	preset_modern.pressed.connect(_apply_general_preset.bind("modern"))
	general_presets_container.add_child(preset_modern)
	
	var preset_cartoon = Button.new()
	preset_cartoon.text = "Cartoon"
	preset_cartoon.custom_minimum_size.x = 60
	preset_cartoon.pressed.connect(_apply_general_preset.bind("cartoon"))
	general_presets_container.add_child(preset_cartoon)

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
	print("🔗 Conectando señales del panel avanzado...")
	# Las señales ya están conectadas en la creación de UI
	print("✅ Todas las señales conectadas")

func _on_setting_changed(_value = null):
	"""Manejar cambio general en configuración"""
	_update_current_settings()
	_emit_settings_signal()

func _on_pixel_size_changed(value: float):
	"""Manejar cambio en tamaño de píxel"""
	pixel_size_label.text = "%.0f" % value
	_update_current_settings()
	_emit_settings_signal()

func _on_color_levels_changed(value: float):
	"""Manejar cambio en niveles de color"""
	color_levels_label.text = "%d" % int(value)
	_update_current_settings()
	_emit_settings_signal()

func _on_outline_enabled_changed(enabled: bool):
	"""Manejar activación/desactivación de outline"""
	print("🔲 Outline 3D %s" % ("habilitado" if enabled else "deshabilitado"))
	_update_current_settings()
	_emit_settings_signal()

func _on_outline_thickness_changed(value: float):
	"""Manejar cambio en grosor del outline"""
	outline_thickness_label.text = "%.1f" % value
	_update_current_settings()
	_emit_settings_signal()

func _on_outline_color_changed(color: Color):
	"""Manejar cambio en color del outline"""
	print("🎨 Color de outline cambiado: %s" % color)
	_update_current_settings()
	_emit_settings_signal()

func _on_apply_pressed():
	"""Aplicar shader manualmente"""
	print("🎨 Aplicando shader manualmente...")
	_update_current_settings()
	current_settings.pixelize_enabled = true
	_emit_settings_signal()

func _on_clear_pressed():
	"""Quitar shader completamente"""
	print("🧹 Quitando shader...")
	current_settings.pixelize_enabled = false
	current_settings.enable_outline = false
	pixelize_enabled_check.button_pressed = false
	outline_enabled_check.button_pressed = false
	_emit_settings_signal()

func _on_reset_pressed():
	"""Resetear a valores por defecto"""
	print("🔄 Reseteando configuración...")
	reset_to_defaults_requested.emit()
	_reset_to_defaults()

# ========================================================================
# LÓGICA DE CONFIGURACIÓN
# ========================================================================

func _update_current_settings():
	"""Actualizar configuración actual desde UI"""
	current_settings.pixelize_enabled = pixelize_enabled_check.button_pressed
	current_settings.pixel_size = pixel_size_slider.value
	current_settings.reduce_colors = reduce_colors_check.button_pressed
	current_settings.color_levels = int(color_levels_slider.value)
	
	# Configuración de outline 3D
	current_settings.enable_outline = outline_enabled_check.button_pressed
	current_settings.outline_thickness = outline_thickness_slider.value
	current_settings.outline_color = outline_color_picker.color
	current_settings.outline_pixelated = outline_pixelated_check.button_pressed
	current_settings.outline_3d_mode = outline_3d_mode_check.button_pressed
	current_settings.outline_auto_detect = outline_auto_detect_check.button_pressed
	
	# Mantener otros valores por defecto
	current_settings.enable_dithering = false
	current_settings.shader_path = "res://resources/shaders/pixelize_spatial.gdshader"

func _emit_settings_signal():
	"""Emitir señal con configuración actual"""
	print("📡 Emitiendo señal: shader_settings_changed")
	print("   - pixelize_enabled: %s" % current_settings.pixelize_enabled)
	print("   - pixel_size: %.0f" % current_settings.pixel_size)
	print("   - outline_enabled: %s" % current_settings.enable_outline)
	if current_settings.enable_outline:
		print("   - outline_3d_mode: %s" % current_settings.outline_3d_mode)
		print("   - outline_thickness: %.1f" % current_settings.outline_thickness)
		print("   - outline_color: %s" % current_settings.outline_color)
	
	# Emitir señal
	shader_settings_changed.emit(current_settings.duplicate())

# ========================================================================
# SISTEMA DE PRESETS
# ========================================================================

func _apply_outline_preset(preset_name: String):
	"""Aplicar preset de configuración de outline"""
	print("🎨 Aplicando preset de outline: %s" % preset_name)
	
	match preset_name:
		"thin":
			_set_outline_settings(true, 0.5, Color.BLACK, true, true)
		"medium":
			_set_outline_settings(true, 1.0, Color.BLACK, true, true)
		"thick":
			_set_outline_settings(true, 2.0, Color.BLACK, true, true)
		"off":
			_set_outline_settings(false, 1.0, Color.BLACK, true, true)
	
	_emit_settings_signal()

func _apply_general_preset(preset_name: String):
	"""Aplicar preset general de configuración"""
	print("⚡ Aplicando preset general: %s" % preset_name)
	
	match preset_name:
		"retro":
			# Píxeles grandes, colores reducidos, sin outline
			_set_pixelization_settings(true, 8.0)
			_set_color_reduction_settings(true, 8)
			_set_outline_settings(false, 1.0, Color.BLACK, true, true)
		"modern":
			# Píxeles pequeños, outline fino
			_set_pixelization_settings(true, 2.0)
			_set_color_reduction_settings(false, 16)
			_set_outline_settings(true, 0.5, Color.BLACK, true, true)
		"cartoon":
			# Píxeles medianos, outline grueso y colorido
			_set_pixelization_settings(true, 4.0)
			_set_color_reduction_settings(true, 12)
			_set_outline_settings(true, 1.5, Color(0.2, 0.2, 0.8), true, true)
	
	_emit_settings_signal()

func _set_outline_settings(enabled: bool, thickness: float, color: Color, pixelated: bool, mode_3d: bool):
	"""Aplicar configuración específica de outline"""
	outline_enabled_check.button_pressed = enabled
	outline_thickness_slider.value = thickness
	outline_thickness_label.text = "%.1f" % thickness
	outline_color_picker.color = color
	outline_pixelated_check.button_pressed = pixelated
	outline_3d_mode_check.button_pressed = mode_3d
	_update_current_settings()

func _set_pixelization_settings(enabled: bool, pixel_size: float):
	"""Aplicar configuración de pixelización"""
	pixelize_enabled_check.button_pressed = enabled
	pixel_size_slider.value = pixel_size
	pixel_size_label.text = "%.0f" % pixel_size
	_update_current_settings()

func _set_color_reduction_settings(enabled: bool, levels: int):
	"""Aplicar configuración de reducción de colores"""
	reduce_colors_check.button_pressed = enabled
	color_levels_slider.value = levels
	color_levels_label.text = "%d" % levels
	_update_current_settings()

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
	
	# Actualizar UI básica
	pixelize_enabled_check.button_pressed = current_settings.get("pixelize_enabled", true)
	pixel_size_slider.value = current_settings.get("pixel_size", 4.0)
	pixel_size_label.text = "%.0f" % pixel_size_slider.value
	reduce_colors_check.button_pressed = current_settings.get("reduce_colors", false)
	color_levels_slider.value = current_settings.get("color_levels", 16)
	color_levels_label.text = "%d" % color_levels_slider.value
	
	# Actualizar UI de outline
	outline_enabled_check.button_pressed = current_settings.get("enable_outline", false)
	outline_thickness_slider.value = current_settings.get("outline_thickness", 1.0)
	outline_thickness_label.text = "%.1f" % outline_thickness_slider.value
	outline_color_picker.color = current_settings.get("outline_color", Color.BLACK)
	outline_pixelated_check.button_pressed = current_settings.get("outline_pixelated", true)
	outline_3d_mode_check.button_pressed = current_settings.get("outline_3d_mode", true)
	outline_auto_detect_check.button_pressed = current_settings.get("outline_auto_detect", true)
	
	print("⚙️ Configuración con outline 3D aplicada desde externa")

func force_emit_current_settings():
	"""Forzar emisión de configuración actual"""
	_update_current_settings()
	_emit_settings_signal()

func _reset_to_defaults():
	"""Resetear a configuración por defecto"""
	# Valores por defecto
	current_settings = {
		"pixelize_enabled": true,
		"pixel_size": 4.0,
		"reduce_colors": false,
		"color_levels": 16,
		"enable_dithering": false,
		"enable_outline": false,
		"outline_thickness": 1.0,
		"outline_color": Color.BLACK,
		"outline_pixelated": true,
		"outline_auto_detect": true,
		"outline_3d_mode": true,
		"shader_path": "res://resources/shaders/pixelize_spatial.gdshader"
	}
	
	# Aplicar a UI
	apply_settings(current_settings)
	_emit_settings_signal()

# ========================================================================
# VALIDACIÓN Y DEBUG
# ========================================================================

func validate_outline_settings() -> bool:
	"""Validar configuración de outline"""
	if not outline_enabled_check.button_pressed:
		return true
	
	var thickness = outline_thickness_slider.value
	if thickness < 0.1 or thickness > 10.0:
		print("❌ Grosor de outline inválido: %.1f" % thickness)
		return false
	
	var color = outline_color_picker.color
	if color.a < 0.1:
		print("❌ Color de outline muy transparente: %.2f" % color.a)
		return false
	
	return true

func debug_panel_state():
	"""Debug del estado del panel"""
	print("\n🔍 === DEBUG PANEL AVANZADO CON OUTLINE 3D ===")
	print("=== PIXELIZACIÓN ===")
	print("pixelize_enabled: %s" % current_settings.pixelize_enabled)
	print("pixel_size: %.0f" % current_settings.pixel_size)
	print("reduce_colors: %s" % current_settings.reduce_colors)
	print("color_levels: %d" % current_settings.color_levels)
	
	print("=== OUTLINE 3D ===")
	print("enable_outline: %s" % current_settings.enable_outline)
	print("outline_thickness: %.1f" % current_settings.outline_thickness)
	print("outline_color: %s" % current_settings.outline_color)
	print("outline_pixelated: %s" % current_settings.outline_pixelated)
	print("outline_3d_mode: %s" % current_settings.outline_3d_mode)
	print("outline_auto_detect: %s" % current_settings.outline_auto_detect)
	
	print("=== SISTEMA ===")
	print("shader_path: %s" % current_settings.get("shader_path", "N/A"))
	
	if has_signal("shader_settings_changed"):
		var connections = get_signal_connection_list("shader_settings_changed")
		print("Conexiones de shader_settings_changed: %d" % connections.size())
		for conn in connections:
			if conn.has("callable"):
				print("  - %s" % conn["callable"].get_method())
	else:
		print("❌ No tiene señal shader_settings_changed")
	
	print("===========================================\n")

# ========================================================================
# FUNCIONES DE UTILIDAD
# ========================================================================

func get_outline_settings() -> Dictionary:
	"""Obtener solo configuración de outline"""
	return {
		"enable_outline": current_settings.enable_outline,
		"outline_thickness": current_settings.outline_thickness,
		"outline_color": current_settings.outline_color,
		"outline_pixelated": current_settings.outline_pixelated,
		"outline_3d_mode": current_settings.outline_3d_mode,
		"outline_auto_detect": current_settings.outline_auto_detect
	}

func get_pixelization_settings() -> Dictionary:
	"""Obtener solo configuración de pixelización"""
	return {
		"pixelize_enabled": current_settings.pixelize_enabled,
		"pixel_size": current_settings.pixel_size,
		"reduce_colors": current_settings.reduce_colors,
		"color_levels": current_settings.color_levels
	}

func is_outline_enabled() -> bool:
	"""Verificar si outline está habilitado"""
	return current_settings.get("enable_outline", false)

func is_3d_outline_mode() -> bool:
	"""Verificar si está en modo outline 3D"""
	return current_settings.get("outline_3d_mode", true) and is_outline_enabled()
