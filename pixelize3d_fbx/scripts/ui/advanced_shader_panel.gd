# scripts/ui/advanced_shader_panel.gd
# Panel de shader SIMPLE que SÍ FUNCIONA y está CONECTADO
# Input: Interacción del usuario con controles simples
# Output: Señales que SÍ llegan al sistema de preview
# ✅ VERSIÓN SIMPLIFICADA PERO FUNCIONAL

extends VBoxContainer

# === SEÑAL QUE SÍ SE CONECTA ===
signal shader_settings_changed(settings: Dictionary)

# === CONTROLES UI SIMPLES ===
var pixelize_enabled_check: CheckBox
var pixel_size_slider: HSlider
var pixel_size_label: Label
var reduce_colors_check: CheckBox
var color_levels_slider: HSlider
var color_levels_label: Label
var apply_button: Button
var clear_button: Button

# === CONFIGURACIÓN ACTUAL ===
var current_settings: Dictionary = {
	"pixelize_enabled": true,
	"pixel_size": 4.0,
	"reduce_colors": false,
	"color_levels": 16,
	"enable_dithering": false,
	"enable_outline": false,
	"shader_path": "res://resources/shaders/pixelize_spatial.gdshader"
}

# ========================================================================
# INICIALIZACIÓN SIMPLE
# ========================================================================

func _ready():
	print("🎨 AdvancedShaderPanel SIMPLE inicializando...")
	_create_simple_ui()
	_connect_simple_signals()
	print("✅ Panel simple listo y conectado")

func _create_simple_ui():
	"""Crear interfaz SIMPLE pero funcional"""
	
	# Título
	var title = Label.new()
	title.text = "🎨 Configuración de Shader"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.CYAN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	add_child(HSeparator.new())
	
	# Info del shader
	var info_label = Label.new()
	info_label.text = "✅ Usando: pixelize_spatial.gdshader (funciona bien)"
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.add_theme_color_override("font_color", Color.GREEN)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_label)
	
	add_child(HSeparator.new())
	
	# === SECCIÓN PIXELIZACIÓN ===
	var pixel_title = Label.new()
	pixel_title.text = "🟦 Pixelización"
	pixel_title.add_theme_font_size_override("font_size", 14)
	pixel_title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(pixel_title)
	
	# Checkbox habilitar
	pixelize_enabled_check = CheckBox.new()
	pixelize_enabled_check.text = "Habilitar Pixelización"
	pixelize_enabled_check.button_pressed = current_settings.pixelize_enabled
	add_child(pixelize_enabled_check)
	
	# Slider tamaño
	var pixel_container = HBoxContainer.new()
	add_child(pixel_container)
	
	var pixel_label_text = Label.new()
	pixel_label_text.text = "Tamaño de Píxel:"
	pixel_label_text.custom_minimum_size.x = 120
	pixel_container.add_child(pixel_label_text)
	
	pixel_size_slider = HSlider.new()
	pixel_size_slider.min_value = 1.0
	pixel_size_slider.max_value = 32.0
	pixel_size_slider.step = 1.0
	pixel_size_slider.value = current_settings.pixel_size
	pixel_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pixel_container.add_child(pixel_size_slider)
	
	pixel_size_label = Label.new()
	pixel_size_label.text = "%.0f" % current_settings.pixel_size
	pixel_size_label.custom_minimum_size.x = 40
	pixel_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pixel_container.add_child(pixel_size_label)
	
	add_child(HSeparator.new())
	
	# === SECCIÓN REDUCCIÓN DE COLORES ===
	var colors_title = Label.new()
	colors_title.text = "🎨 Reducción de Colores"
	colors_title.add_theme_font_size_override("font_size", 14)
	colors_title.add_theme_color_override("font_color", Color.ORANGE)
	add_child(colors_title)
	
	# Checkbox reducir colores
	reduce_colors_check = CheckBox.new()
	reduce_colors_check.text = "Reducir Colores"
	reduce_colors_check.button_pressed = current_settings.reduce_colors
	add_child(reduce_colors_check)
	
	# Slider niveles
	var color_container = HBoxContainer.new()
	add_child(color_container)
	
	var color_label_text = Label.new()
	color_label_text.text = "Niveles de Color:"
	color_label_text.custom_minimum_size.x = 120
	color_container.add_child(color_label_text)
	
	color_levels_slider = HSlider.new()
	color_levels_slider.min_value = 2
	color_levels_slider.max_value = 64
	color_levels_slider.step = 1
	color_levels_slider.value = current_settings.color_levels
	color_levels_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_container.add_child(color_levels_slider)
	
	color_levels_label = Label.new()
	color_levels_label.text = "%d" % current_settings.color_levels
	color_levels_label.custom_minimum_size.x = 40
	color_levels_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	color_container.add_child(color_levels_label)
	
	add_child(HSeparator.new())
	
	# === BOTONES ===
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 15)
	add_child(button_container)
	
	apply_button = Button.new()
	apply_button.text = "✅ Aplicar Shader"
	apply_button.custom_minimum_size.x = 120
	button_container.add_child(apply_button)
	
	clear_button = Button.new()
	clear_button.text = "🧹 Quitar Shader"
	clear_button.custom_minimum_size.x = 120
	button_container.add_child(clear_button)
	
	# Info final
	add_child(HSeparator.new())
	
	var final_info = Label.new()
	final_info.text = "💡 Los cambios se aplican instantáneamente"
	final_info.add_theme_font_size_override("font_size", 9)
	final_info.add_theme_color_override("font_color", Color.GRAY)
	final_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(final_info)

# ========================================================================
# CONEXIÓN DE SEÑALES SIMPLES
# ========================================================================

func _connect_simple_signals():
	"""Conectar señales simples que SÍ funcionan"""
	print("🔗 Conectando señales simples...")
	
	# Conexiones que emiten cambios automáticamente
	pixelize_enabled_check.toggled.connect(_on_setting_changed)
	pixel_size_slider.value_changed.connect(_on_pixel_size_changed)
	reduce_colors_check.toggled.connect(_on_setting_changed)
	color_levels_slider.value_changed.connect(_on_color_levels_changed)
	
	# Botones manuales
	apply_button.pressed.connect(_on_apply_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	print("✅ Señales simples conectadas")

# ========================================================================
# MANEJADORES DE EVENTOS SIMPLES
# ========================================================================

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
	pixelize_enabled_check.button_pressed = false
	_emit_settings_signal()

# ========================================================================
# LÓGICA DE CONFIGURACIÓN
# ========================================================================

func _update_current_settings():
	"""Actualizar configuración actual desde UI"""
	current_settings.pixelize_enabled = pixelize_enabled_check.button_pressed
	current_settings.pixel_size = pixel_size_slider.value
	current_settings.reduce_colors = reduce_colors_check.button_pressed
	current_settings.color_levels = int(color_levels_slider.value)
	
	# Mantener otros valores por defecto
	current_settings.enable_dithering = false
	current_settings.enable_outline = false
	current_settings.shader_path = "res://resources/shaders/pixelize_spatial.gdshader"

func _emit_settings_signal():
	"""Emitir señal con configuración actual"""
	print("📡 Emitiendo señal: shader_settings_changed")
	print("   - pixelize_enabled: %s" % current_settings.pixelize_enabled)
	print("   - pixel_size: %.0f" % current_settings.pixel_size)
	print("   - reduce_colors: %s" % current_settings.reduce_colors)
	
	# ✅ EMITIR LA SEÑAL QUE SÍ SE CONECTA
	shader_settings_changed.emit(current_settings.duplicate())

# ========================================================================
# API PÚBLICA SIMPLE
# ========================================================================

func get_current_settings() -> Dictionary:
	"""Obtener configuración actual"""
	_update_current_settings()
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	"""Aplicar configuración externa"""
	current_settings = settings.duplicate()
	
	# Actualizar UI
	pixelize_enabled_check.button_pressed = current_settings.get("pixelize_enabled", true)
	pixel_size_slider.value = current_settings.get("pixel_size", 4.0)
	pixel_size_label.text = "%.0f" % pixel_size_slider.value
	reduce_colors_check.button_pressed = current_settings.get("reduce_colors", false)
	color_levels_slider.value = current_settings.get("color_levels", 16)
	color_levels_label.text = "%d" % color_levels_slider.value
	
	print("⚙️ Configuración aplicada desde externa")

func force_emit_current_settings():
	"""Forzar emisión de configuración actual"""
	_update_current_settings()
	_emit_settings_signal()

# ========================================================================
# FUNCIONES DE DEBUG
# ========================================================================

func debug_panel_state():
	"""Debug del estado del panel"""
	print("\n🔍 === DEBUG PANEL AVANZADO ===")
	print("pixelize_enabled: %s" % current_settings.pixelize_enabled)
	print("pixel_size: %.0f" % current_settings.pixel_size)
	print("reduce_colors: %s" % current_settings.reduce_colors)
	print("color_levels: %d" % current_settings.color_levels)
	print("shader_path: %s" % current_settings.get("shader_path", "N/A"))
	
	if has_signal("shader_settings_changed"):
		var connections = get_signal_connection_list("shader_settings_changed")
		print("Conexiones de shader_settings_changed: %d" % connections.size())
		for conn in connections:
			print("  - %s" % conn["callable"].get_method())
	else:
		print("❌ No tiene señal shader_settings_changed")
	
	print("==============================\n")
