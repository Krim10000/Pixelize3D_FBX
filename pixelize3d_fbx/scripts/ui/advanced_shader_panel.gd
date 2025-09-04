# scripts/ui/advanced_shader_panel.gd
# Panel avanzado de configuración del shader de pixelización con efectos completos
# Input: Interacción del usuario con controles de configuración avanzada
# Output: Señales con configuración de shader actualizada para aplicación en model_preview_panel

extends VBoxContainer

# === SEÑALES DE COMUNICACIÓN ===
signal shader_settings_changed(settings: Dictionary)
signal reset_to_defaults_requested()

# === REFERENCIAS A CONTROLES DE UI ===
var main_container: VBoxContainer
var preview_material: ShaderMaterial

# === CONTAINERS DE SECCIONES ===
var pixelize_section: VBoxContainer
var colors_section: VBoxContainer  
var dither_section: VBoxContainer
var outline_section: VBoxContainer
var advanced_section: VBoxContainer

# === SECCIÓN 1: PIXELIZACIÓN BÁSICA ===
var pixelize_enabled_check: CheckBox
var pixel_size_slider: HSlider
var pixel_size_label: Label

# === SECCIÓN 2: REDUCCIÓN DE COLORES ===
var reduce_colors_enabled_check: CheckBox
var color_levels_slider: HSlider
var color_levels_label: Label

# === SECCIÓN 3: DITHERING ===
var dithering_enabled_check: CheckBox
var dither_strength_slider: HSlider
var dither_strength_label: Label

# === SECCIÓN 4: EFECTOS DE BORDE ===
var outline_enabled_check: CheckBox
var outline_thickness_slider: HSlider
var outline_thickness_label: Label
var outline_color_picker: ColorPickerButton
var outline_pixelated_check: CheckBox
var outline_smooth_slider: HSlider
var outline_smooth_label: Label

# === SECCIÓN 5: EFECTOS AVANZADOS DE COLOR ===
var contrast_enabled_check: CheckBox
var contrast_slider: HSlider
var contrast_label: Label
var saturation_enabled_check: CheckBox
var saturation_slider: HSlider
var saturation_label: Label
var tint_enabled_check: CheckBox
var color_tint_picker: ColorPickerButton
var gamma_enabled_check: CheckBox
var gamma_slider: HSlider
var gamma_label: Label

# === ESTADO INTERNO ===
var current_settings: Dictionary = {}
var is_updating_ui: bool = false

# === CONFIGURACIÓN POR DEFECTO ===
var default_settings: Dictionary = {
	# Pixelización básica
	"pixelize_enabled": true,
	"pixel_size": 4.0,
	
	# Reducción de colores
	"reduce_colors_enabled": false,
	"reduce_colors": false,
	"color_levels": 16,
	
	# Dithering
	"dithering_enabled": false,
	"enable_dithering": false,
	"dither_strength": 0.1,
	
	# Efectos de borde
	"outline_enabled": false,
	"enable_outline": false,
	"outline_thickness": 1.0,
	"outline_color": Color.BLACK,
	"outline_pixelated": true,
	"outline_smooth": 0.0,
	
	# Efectos avanzados
	"contrast_enabled": false,
	"contrast_boost": 1.0,
	"saturation_enabled": false,
	"saturation_mult": 1.0,
	"tint_enabled": false,
	"color_tint": Color.WHITE,
	"gamma_enabled": false,
	"apply_gamma_correction": false,
	"gamma_value": 1.0
}

func _ready():
	print("🎨 AdvancedShaderPanel inicializando...")
	_initialize_settings()
	_setup_material_and_shader()
	_create_ui_layout()
	_connect_all_signals()
	_apply_current_settings()
	print("✅ AdvancedShaderPanel completamente inicializado")

# ========================================================================
# INICIALIZACIÓN Y CONFIGURACIÓN
# ========================================================================

func _initialize_settings():
	"""Inicializar configuración con valores por defecto"""
	current_settings = default_settings.duplicate()
	print("⚙️ Configuración inicializada con valores por defecto")

func _setup_material_and_shader():
	"""Configurar material y shader avanzado para preview"""
	preview_material = ShaderMaterial.new()
	
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path) as Shader
		if shader:
			preview_material.shader = shader
			print("✅ Shader avanzado cargado exitosamente para preview")
		else:
			print("❌ Error: El archivo existe pero no se pudo cargar como Shader")
	else:
		print("❌ Error: Archivo de shader no encontrado en: %s" % shader_path)

func _create_ui_layout():
	"""Crear layout principal de la interfaz"""
	print("🎨 Creando layout de interfaz avanzada...")
	
	# Título principal
	var title_label = Label.new()
	title_label.text = "🎨 Configuración Avanzada de Shader"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
	add_child(HSeparator.new())
	
	# Container principal con scroll
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size.y = 400
	add_child(scroll_container)
	
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 8)
	scroll_container.add_child(main_container)
	
	# Crear todas las secciones
	_create_pixelization_section()
	_create_color_reduction_section()
	_create_dithering_section()
	_create_outline_section()
	_create_advanced_effects_section()
	_create_actions_section()

# ========================================================================
# CREACIÓN DE SECCIONES DE UI CON COLAPSO
# ========================================================================

func _create_pixelization_section():
	"""Crear sección de pixelización básica"""
	pixelize_section = _create_collapsible_section("📐 Pixelización Básica", true)
	main_container.add_child(pixelize_section)
	
	var content = _get_section_content(pixelize_section)
	
	# Checkbox maestro para activar/desactivar toda la sección
	pixelize_enabled_check = CheckBox.new()
	pixelize_enabled_check.text = "✅ Aplicar pixelización"
	pixelize_enabled_check.button_pressed = current_settings.pixelize_enabled
	content.add_child(pixelize_enabled_check)
	
	content.add_child(HSeparator.new())
	
	# Control de tamaño de pixel
	var pixel_container = _create_labeled_slider_container("Tamaño de pixel:")
	content.add_child(pixel_container)
	
	pixel_size_slider = pixel_container.get_meta("slider")
	pixel_size_label = pixel_container.get_meta("label")
	pixel_size_slider.min_value = 1.0
	pixel_size_slider.max_value = 32.0
	pixel_size_slider.step = 1.0
	pixel_size_slider.value = current_settings.pixel_size
	pixel_size_label.text = "%.0f" % current_settings.pixel_size

func _create_color_reduction_section():
	"""Crear sección de reducción de colores"""
	colors_section = _create_collapsible_section("🎨 Reducción de Colores", false)
	main_container.add_child(colors_section)
	
	var content = _get_section_content(colors_section)
	
	# Checkbox maestro para activar/desactivar reducción de colores
	reduce_colors_enabled_check = CheckBox.new()
	reduce_colors_enabled_check.text = "✅ Aplicar reducción de colores"
	reduce_colors_enabled_check.button_pressed = current_settings.reduce_colors_enabled
	content.add_child(reduce_colors_enabled_check)
	
	content.add_child(HSeparator.new())
	
	# Control de niveles de color
	var levels_container = _create_labeled_slider_container("Niveles de color:")
	content.add_child(levels_container)
	
	color_levels_slider = levels_container.get_meta("slider")
	color_levels_label = levels_container.get_meta("label")
	color_levels_slider.min_value = 2
	color_levels_slider.max_value = 64
	color_levels_slider.step = 1
	color_levels_slider.value = current_settings.color_levels
	color_levels_label.text = "%d" % current_settings.color_levels

func _create_dithering_section():
	"""Crear sección de dithering"""
	dither_section = _create_collapsible_section("🔲 Dithering", false)
	main_container.add_child(dither_section)
	
	var content = _get_section_content(dither_section)
	
	# Checkbox maestro para activar/desactivar dithering
	dithering_enabled_check = CheckBox.new()
	dithering_enabled_check.text = "✅ Aplicar dithering"
	dithering_enabled_check.button_pressed = current_settings.dithering_enabled
	content.add_child(dithering_enabled_check)
	
	content.add_child(HSeparator.new())
	
	# Control de fuerza de dithering
	var strength_container = _create_labeled_slider_container("Fuerza de dithering:")
	content.add_child(strength_container)
	
	dither_strength_slider = strength_container.get_meta("slider")
	dither_strength_label = strength_container.get_meta("label")
	dither_strength_slider.min_value = 0.0
	dither_strength_slider.max_value = 1.0
	dither_strength_slider.step = 0.01
	dither_strength_slider.value = current_settings.dither_strength
	dither_strength_label.text = "%.2f" % current_settings.dither_strength

func _create_outline_section():
	"""Crear sección de efectos de borde"""
	outline_section = _create_collapsible_section("🖼️ Efectos de Borde", false)
	main_container.add_child(outline_section)
	
	var content = _get_section_content(outline_section)
	
	# Checkbox maestro para activar/desactivar efectos de borde
	outline_enabled_check = CheckBox.new()
	outline_enabled_check.text = "✅ Aplicar efectos de borde"
	outline_enabled_check.button_pressed = current_settings.outline_enabled
	content.add_child(outline_enabled_check)
	
	content.add_child(HSeparator.new())
	
	# Control de grosor de borde
	var thickness_container = _create_labeled_slider_container("Grosor del borde:")
	content.add_child(thickness_container)
	
	outline_thickness_slider = thickness_container.get_meta("slider")
	outline_thickness_label = thickness_container.get_meta("label")
	outline_thickness_slider.min_value = 0.5
	outline_thickness_slider.max_value = 8.0
	outline_thickness_slider.step = 0.1
	outline_thickness_slider.value = current_settings.outline_thickness
	outline_thickness_label.text = "%.1f" % current_settings.outline_thickness
	
	# Color del borde
	var color_container = HBoxContainer.new()
	content.add_child(color_container)
	
	var color_label = Label.new()
	color_label.text = "Color del borde:"
	color_label.custom_minimum_size.x = 120
	color_container.add_child(color_label)
	
	outline_color_picker = ColorPickerButton.new()
	outline_color_picker.color = current_settings.outline_color
	outline_color_picker.custom_minimum_size = Vector2(80, 30)
	color_container.add_child(outline_color_picker)
	
	# Borde pixelado
	outline_pixelated_check = CheckBox.new()
	outline_pixelated_check.text = "Borde pixelado"
	outline_pixelated_check.button_pressed = current_settings.outline_pixelated
	content.add_child(outline_pixelated_check)
	
	# Suavizado de borde
	var smooth_container = _create_labeled_slider_container("Suavizado:")
	content.add_child(smooth_container)
	
	outline_smooth_slider = smooth_container.get_meta("slider")
	outline_smooth_label = smooth_container.get_meta("label")
	outline_smooth_slider.min_value = 0.0
	outline_smooth_slider.max_value = 1.0
	outline_smooth_slider.step = 0.01
	outline_smooth_slider.value = current_settings.outline_smooth
	outline_smooth_label.text = "%.2f" % current_settings.outline_smooth

func _create_advanced_effects_section():
	"""Crear sección de efectos avanzados de color"""
	advanced_section = _create_collapsible_section("⚡ Efectos Avanzados de Color", false)
	main_container.add_child(advanced_section)
	
	var content = _get_section_content(advanced_section)
	
	# === CONTRASTE ===
	contrast_enabled_check = CheckBox.new()
	contrast_enabled_check.text = "✅ Ajustar contraste"
	contrast_enabled_check.button_pressed = current_settings.contrast_enabled
	content.add_child(contrast_enabled_check)
	
	var contrast_container = _create_labeled_slider_container("Contraste:")
	content.add_child(contrast_container)
	
	contrast_slider = contrast_container.get_meta("slider")
	contrast_label = contrast_container.get_meta("label")
	contrast_slider.min_value = 0.5
	contrast_slider.max_value = 2.0
	contrast_slider.step = 0.01
	contrast_slider.value = current_settings.contrast_boost
	contrast_label.text = "%.2f" % current_settings.contrast_boost
	
	content.add_child(HSeparator.new())
	
	# === SATURACIÓN ===
	saturation_enabled_check = CheckBox.new()
	saturation_enabled_check.text = "✅ Ajustar saturación"
	saturation_enabled_check.button_pressed = current_settings.saturation_enabled
	content.add_child(saturation_enabled_check)
	
	var saturation_container = _create_labeled_slider_container("Saturación:")
	content.add_child(saturation_container)
	
	saturation_slider = saturation_container.get_meta("slider")
	saturation_label = saturation_container.get_meta("label")
	saturation_slider.min_value = 0.0
	saturation_slider.max_value = 2.0
	saturation_slider.step = 0.01
	saturation_slider.value = current_settings.saturation_mult
	saturation_label.text = "%.2f" % current_settings.saturation_mult
	
	content.add_child(HSeparator.new())
	
	# === TINTE DE COLOR ===
	tint_enabled_check = CheckBox.new()
	tint_enabled_check.text = "✅ Aplicar tinte de color"
	tint_enabled_check.button_pressed = current_settings.tint_enabled
	content.add_child(tint_enabled_check)
	
	var tint_container = HBoxContainer.new()
	content.add_child(tint_container)
	
	var tint_label = Label.new()
	tint_label.text = "Color de tinte:"
	tint_label.custom_minimum_size.x = 120
	tint_container.add_child(tint_label)
	
	color_tint_picker = ColorPickerButton.new()
	color_tint_picker.color = current_settings.color_tint
	color_tint_picker.custom_minimum_size = Vector2(80, 30)
	tint_container.add_child(color_tint_picker)
	
	content.add_child(HSeparator.new())
	
	# === CORRECCIÓN GAMMA ===
	gamma_enabled_check = CheckBox.new()
	gamma_enabled_check.text = "✅ Aplicar corrección gamma"
	gamma_enabled_check.button_pressed = current_settings.gamma_enabled
	content.add_child(gamma_enabled_check)
	
	var gamma_container = _create_labeled_slider_container("Valor gamma:")
	content.add_child(gamma_container)
	
	gamma_slider = gamma_container.get_meta("slider")
	gamma_label = gamma_container.get_meta("label")
	gamma_slider.min_value = 0.5
	gamma_slider.max_value = 2.5
	gamma_slider.step = 0.01
	gamma_slider.value = current_settings.gamma_value
	gamma_label.text = "%.2f" % current_settings.gamma_value

func _create_actions_section():
	"""Crear sección de acciones - SOLO RESET"""
	var actions_container = HBoxContainer.new()
	main_container.add_child(actions_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_container.add_child(spacer)
	
	# Solo botón de reset - el aplicar está en la ventana madre
	var reset_button = Button.new()
	reset_button.text = "🔄 Restaurar Valores por Defecto"
	reset_button.custom_minimum_size.x = 200
	reset_button.pressed.connect(_on_reset_requested)
	actions_container.add_child(reset_button)

# ========================================================================
# SISTEMA DE SECCIONES COLAPSABLES CON CLASES NATIVAS
# ========================================================================

func _create_collapsible_section(title: String, expanded: bool = false) -> VBoxContainer:
	"""Crear una sección colapsable usando solo clases nativas de Godot"""
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	
	# Crear botón de encabezado para colapsar/expandir
	var header_button = Button.new()
	header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_button.text = ("▼ " if expanded else "▶ ") + title
	header_button.add_theme_font_size_override("font_size", 14)
	header_button.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	header_button.flat = true
	section.add_child(header_button)
	
	# Container para el contenido
	var content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 3)
	content_container.visible = expanded
	
	# Agregar margen izquierdo al contenido
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_child(content_container)
	section.add_child(margin)
	
	# Separador al final
	section.add_child(HSeparator.new())
	
	# Guardar referencias usando metadatos
	section.set_meta("content_container", content_container)
	section.set_meta("header_button", header_button)
	section.set_meta("expanded", expanded)
	section.set_meta("title", title)
	
	# Conectar señal del botón para alternar visibilidad
	header_button.pressed.connect(_toggle_section.bind(section))
	
	return section

func _toggle_section(section: VBoxContainer):
	"""Alternar visibilidad de una sección"""
	var content = section.get_meta("content_container") as VBoxContainer
	var button = section.get_meta("header_button") as Button
	var title = section.get_meta("title") as String
	var expanded = section.get_meta("expanded") as bool
	
	# Cambiar estado
	expanded = not expanded
	content.visible = expanded
	
	# Actualizar texto del botón
	button.text = ("▼ " if expanded else "▶ ") + title
	
	# Guardar nuevo estado
	section.set_meta("expanded", expanded)

func _get_section_content(section: VBoxContainer) -> VBoxContainer:
	"""Obtener container de contenido de una sección"""
	return section.get_meta("content_container") as VBoxContainer

# ========================================================================
# FUNCIONES AUXILIARES PARA CREAR UI
# ========================================================================

func _create_labeled_slider_container(label_text: String) -> HBoxContainer:
	"""Crear un container con label y slider"""
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.custom_minimum_size.x = 50
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(value_label)
	
	# Guardar referencias en metadatos
	container.set_meta("slider", slider)
	container.set_meta("label", value_label)
	
	return container

# ========================================================================
# CONEXIÓN DE SEÑALES
# ========================================================================

func _connect_all_signals():
	"""Conectar todas las señales de los controles de UI"""
	print("🔗 Conectando señales de controles...")
	
	# Sección de pixelización
	pixelize_enabled_check.toggled.connect(_on_pixelize_enabled_changed)
	pixel_size_slider.value_changed.connect(_on_pixel_size_changed)
	
	# Sección de reducción de colores
	reduce_colors_enabled_check.toggled.connect(_on_reduce_colors_enabled_changed)
	color_levels_slider.value_changed.connect(_on_color_levels_changed)
	
	# Sección de dithering
	dithering_enabled_check.toggled.connect(_on_dithering_enabled_changed)
	dither_strength_slider.value_changed.connect(_on_dither_strength_changed)
	
	# Sección de efectos de borde
	outline_enabled_check.toggled.connect(_on_outline_enabled_changed)
	outline_thickness_slider.value_changed.connect(_on_outline_thickness_changed)
	outline_color_picker.color_changed.connect(_on_outline_color_changed)
	outline_pixelated_check.toggled.connect(_on_outline_pixelated_changed)
	outline_smooth_slider.value_changed.connect(_on_outline_smooth_changed)
	
	# Sección de efectos avanzados
	contrast_enabled_check.toggled.connect(_on_contrast_enabled_changed)
	contrast_slider.value_changed.connect(_on_contrast_changed)
	saturation_enabled_check.toggled.connect(_on_saturation_enabled_changed)
	saturation_slider.value_changed.connect(_on_saturation_changed)
	tint_enabled_check.toggled.connect(_on_tint_enabled_changed)
	color_tint_picker.color_changed.connect(_on_color_tint_changed)
	gamma_enabled_check.toggled.connect(_on_gamma_enabled_changed)
	gamma_slider.value_changed.connect(_on_gamma_changed)
	
	print("✅ Todas las señales conectadas")

# ========================================================================
# MANEJADORES DE EVENTOS DE UI
# ========================================================================

func _on_pixelize_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.pixelize_enabled = enabled
	_update_preview_and_emit()

func _on_pixel_size_changed(value: float):
	if is_updating_ui: return
	current_settings.pixel_size = value
	pixel_size_label.text = "%.0f" % value
	_update_preview_and_emit()

func _on_reduce_colors_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.reduce_colors_enabled = enabled
	current_settings.reduce_colors = enabled
	_update_preview_and_emit()

func _on_color_levels_changed(value: float):
	if is_updating_ui: return
	current_settings.color_levels = int(value)
	color_levels_label.text = "%d" % int(value)
	_update_preview_and_emit()

func _on_dithering_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.dithering_enabled = enabled
	current_settings.enable_dithering = enabled
	_update_preview_and_emit()

func _on_dither_strength_changed(value: float):
	if is_updating_ui: return
	current_settings.dither_strength = value
	dither_strength_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_outline_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.outline_enabled = enabled
	current_settings.enable_outline = enabled
	_update_preview_and_emit()

func _on_outline_thickness_changed(value: float):
	if is_updating_ui: return
	current_settings.outline_thickness = value
	outline_thickness_label.text = "%.1f" % value
	_update_preview_and_emit()

func _on_outline_color_changed(color: Color):
	if is_updating_ui: return
	current_settings.outline_color = color
	_update_preview_and_emit()

func _on_outline_pixelated_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.outline_pixelated = enabled
	_update_preview_and_emit()

func _on_outline_smooth_changed(value: float):
	if is_updating_ui: return
	current_settings.outline_smooth = value
	outline_smooth_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_contrast_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.contrast_enabled = enabled
	_update_preview_and_emit()

func _on_contrast_changed(value: float):
	if is_updating_ui: return
	current_settings.contrast_boost = value
	contrast_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_saturation_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.saturation_enabled = enabled
	_update_preview_and_emit()

func _on_saturation_changed(value: float):
	if is_updating_ui: return
	current_settings.saturation_mult = value
	saturation_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_tint_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.tint_enabled = enabled
	_update_preview_and_emit()

func _on_color_tint_changed(color: Color):
	if is_updating_ui: return
	current_settings.color_tint = color
	_update_preview_and_emit()

func _on_gamma_enabled_changed(enabled: bool):
	if is_updating_ui: return
	current_settings.gamma_enabled = enabled
	current_settings.apply_gamma_correction = enabled
	_update_preview_and_emit()

func _on_gamma_changed(value: float):
	if is_updating_ui: return
	current_settings.gamma_value = value
	gamma_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_reset_requested():
	print("🔄 Reseteando a valores por defecto...")
	current_settings = default_settings.duplicate()
	_apply_current_settings()
	_update_preview_and_emit()
	reset_to_defaults_requested.emit()

# ========================================================================
# FUNCIONES DE ACTUALIZACIÓN Y APLICACIÓN
# ========================================================================

func _update_preview_and_emit():
	"""Actualizar vista previa y emitir señal de cambio - SIN BUSCAR MODELO DIRECTAMENTE"""
	print("Aplicando cambios del shader avanzado...")
	print("   Pixelización: %s (tamaño: %.0f)" % [current_settings.pixelize_enabled, current_settings.pixel_size])
	print("   Reducción colores: %s (%d niveles)" % [current_settings.reduce_colors, current_settings.color_levels])
	print("   Dithering: %s (fuerza: %.2f)" % [current_settings.enable_dithering, current_settings.dither_strength])
	print("   Bordes: %s (grosor: %.1f)" % [current_settings.enable_outline, current_settings.outline_thickness])
	
	# Aplicar al material de preview interno (para referencia)
	if preview_material and preview_material.shader:
		_apply_settings_to_material(preview_material)
		print("   Aplicado al material de preview interno")
	
	# CORREGIDO: Solo emitir señal para que settings_panel maneje el flujo
	shader_settings_changed.emit(current_settings.duplicate())
	print("   Señal shader_settings_changed emitida")

func _apply_settings_to_material(material: ShaderMaterial):
	"""Aplicar configuración actual al material especificado"""
	if not material or not material.shader:
		return
	
	# Aplicar parámetros de pixelización
	material.set_shader_parameter("pixel_size", current_settings.pixel_size)
	
	# Aplicar parámetros de reducción de colores
	material.set_shader_parameter("reduce_colors", current_settings.reduce_colors)
	material.set_shader_parameter("color_levels", current_settings.color_levels)
	
	# Aplicar parámetros de dithering
	material.set_shader_parameter("enable_dithering", current_settings.enable_dithering)
	material.set_shader_parameter("dither_strength", current_settings.dither_strength)
	
	# Aplicar parámetros de bordes
	material.set_shader_parameter("enable_outline", current_settings.enable_outline)
	material.set_shader_parameter("outline_thickness", current_settings.outline_thickness)
	material.set_shader_parameter("outline_color", current_settings.outline_color)
	material.set_shader_parameter("outline_pixelated", current_settings.outline_pixelated)
	material.set_shader_parameter("outline_smooth", current_settings.outline_smooth)
	
	# Aplicar efectos avanzados solo si están habilitados
	if current_settings.contrast_enabled:
		material.set_shader_parameter("contrast_boost", current_settings.contrast_boost)
	else:
		material.set_shader_parameter("contrast_boost", 1.0)
	
	if current_settings.saturation_enabled:
		material.set_shader_parameter("saturation_mult", current_settings.saturation_mult)
	else:
		material.set_shader_parameter("saturation_mult", 1.0)
	
	if current_settings.tint_enabled:
		material.set_shader_parameter("color_tint", current_settings.color_tint)
	else:
		material.set_shader_parameter("color_tint", Color.WHITE)
	
	material.set_shader_parameter("apply_gamma_correction", current_settings.apply_gamma_correction)
	material.set_shader_parameter("gamma_value", current_settings.gamma_value)

func _apply_current_settings():
	"""Aplicar configuración actual a todos los controles de UI"""
	is_updating_ui = true
	
	# Sección de pixelización
	pixelize_enabled_check.button_pressed = current_settings.pixelize_enabled
	pixel_size_slider.value = current_settings.pixel_size
	pixel_size_label.text = "%.0f" % current_settings.pixel_size
	
	# Sección de reducción de colores
	reduce_colors_enabled_check.button_pressed = current_settings.reduce_colors_enabled
	color_levels_slider.value = current_settings.color_levels
	color_levels_label.text = "%d" % current_settings.color_levels
	
	# Sección de dithering
	dithering_enabled_check.button_pressed = current_settings.dithering_enabled
	dither_strength_slider.value = current_settings.dither_strength
	dither_strength_label.text = "%.2f" % current_settings.dither_strength
	
	# Sección de efectos de borde
	outline_enabled_check.button_pressed = current_settings.outline_enabled
	outline_thickness_slider.value = current_settings.outline_thickness
	outline_thickness_label.text = "%.1f" % current_settings.outline_thickness
	outline_color_picker.color = current_settings.outline_color
	outline_pixelated_check.button_pressed = current_settings.outline_pixelated
	outline_smooth_slider.value = current_settings.outline_smooth
	outline_smooth_label.text = "%.2f" % current_settings.outline_smooth
	
	# Sección de efectos avanzados
	contrast_enabled_check.button_pressed = current_settings.contrast_enabled
	contrast_slider.value = current_settings.contrast_boost
	contrast_label.text = "%.2f" % current_settings.contrast_boost
	saturation_enabled_check.button_pressed = current_settings.saturation_enabled
	saturation_slider.value = current_settings.saturation_mult
	saturation_label.text = "%.2f" % current_settings.saturation_mult
	tint_enabled_check.button_pressed = current_settings.tint_enabled
	color_tint_picker.color = current_settings.color_tint
	gamma_enabled_check.button_pressed = current_settings.gamma_enabled
	gamma_slider.value = current_settings.gamma_value
	gamma_label.text = "%.2f" % current_settings.gamma_value
	
	is_updating_ui = false
	print("✅ Configuración aplicada a todos los controles")

# ========================================================================
# API PÚBLICA PARA INTEGRACIÓN
# ========================================================================

func get_current_settings() -> Dictionary:
	"""Obtener configuración actual para uso externo"""
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	"""Aplicar configuración externa al panel"""
	current_settings = settings.duplicate()
	_apply_current_settings()
	_update_preview_and_emit()

func get_preview_material() -> ShaderMaterial:
	"""Obtener material de vista previa configurado"""
	return preview_material
