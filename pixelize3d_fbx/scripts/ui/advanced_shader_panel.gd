# scripts/ui/advanced_shader_panel.gd
# Panel avanzado de configuración del shader de pixelización con efectos de borde
# Input: Interacción del usuario con controles de configuración avanzada
# Output: Señales con configuración de shader actualizada y aplicación en tiempo real

extends VBoxContainer

# === SEÑALES DE COMUNICACIÓN ===
signal shader_settings_changed(settings: Dictionary)
signal preset_applied(preset_name: String)
signal reset_to_defaults_requested()
signal save_as_preset_requested(settings: Dictionary, name: String)

# === REFERENCIAS A CONTROLES DE UI - CORREGIDO para Godot 4.4 ===
var main_container: VBoxContainer
var preview_container: HBoxContainer
var preview_viewport: SubViewport
var preview_model: MeshInstance3D

# Sección: Pixelización Básica
var pixel_section: VBoxContainer
var pixel_size_slider: HSlider
var pixel_size_label: Label
var pixelize_enabled: CheckBox

# Sección: Reducción de Colores
var colors_section: VBoxContainer
var reduce_colors_check: CheckBox
var color_levels_slider: HSlider
var color_levels_label: Label

# Sección: Dithering
var dither_section: VBoxContainer
var enable_dithering_check: CheckBox
var dither_strength_slider: HSlider
var dither_strength_label: Label

# Sección: Efectos de Borde (NUEVO)
var outline_section: VBoxContainer
var enable_outline_check: CheckBox
var outline_thickness_slider: HSlider
var outline_thickness_label: Label
var outline_color_picker: ColorPickerButton  # CORREGIDO: ColorPickerButton en lugar de ColorPicker
var outline_pixelated_check: CheckBox
var outline_smooth_slider: HSlider
var outline_smooth_label: Label

# Sección: Efectos Avanzados de Color
var advanced_section: VBoxContainer
var contrast_slider: HSlider
var contrast_label: Label
var saturation_slider: HSlider
var saturation_label: Label
var color_tint_picker: ColorPickerButton  # CORREGIDO: ColorPickerButton
var gamma_check: CheckBox
var gamma_slider: HSlider
var gamma_label: Label

# Sección: Controles de Acción
var actions_section: VBoxContainer
var reset_button: Button
var export_button: Button
var import_button: Button

# === ESTADO INTERNO ===
var current_settings: Dictionary = {}
var preview_material: ShaderMaterial
var is_updating_ui: bool = false
var live_preview_enabled: bool = true

# === CONFIGURACIÓN INICIAL POR DEFECTO ===
var default_settings: Dictionary = {
	# Pixelización básica
	"pixel_size": 4.0,
	"pixelize_enabled": true,
	
	# Reducción de colores
	"reduce_colors": false,
	"color_levels": 16,
	
	# Dithering
	"enable_dithering": false,
	"dither_strength": 0.1,
	
	# Efectos de borde
	"enable_outline": false,
	"outline_thickness": 1.0,
	"outline_color": Color.BLACK,
	"outline_pixelated": true,
	"outline_smooth": 0.0,
	
	# Efectos avanzados
	"contrast_boost": 1.0,
	"saturation_mult": 1.0,
	"color_tint": Color.WHITE,
	"apply_gamma_correction": false,
	"gamma_value": 1.0
}

func _ready():
	print("🎨 AdvancedShaderPanel inicializando...")
	_initialize_settings()
	_create_ui_layout()
	_create_preview_area()
	_setup_material_and_shader()
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
	scroll_container.custom_minimum_size.y = 500
	add_child(scroll_container)
	
	main_container = VBoxContainer.new()
	scroll_container.add_child(main_container)
	
	# Crear todas las secciones
	_create_pixelization_section()
	_create_color_reduction_section()
	_create_dithering_section()
	_create_outline_section()  # SECCIÓN NUEVA
	_create_advanced_effects_section()
	_create_actions_section()

func _create_pixelization_section():
	"""Crear sección de pixelización básica"""
	pixel_section = _create_collapsible_section("📐 Pixelización Básica", true)
	main_container.add_child(pixel_section)
	
	var content = pixel_section.get_meta("content_container")
	
	# Activar/desactivar pixelización
	pixelize_enabled = CheckBox.new()
	pixelize_enabled.text = "Aplicar pixelización"
	pixelize_enabled.button_pressed = current_settings.pixelize_enabled
	pixelize_enabled.toggled.connect(_on_pixelize_enabled_changed)
	content.add_child(pixelize_enabled)
	
	# Control de tamaño de pixel
	var pixel_container = _create_labeled_slider_container("Tamaño de pixel:")
	content.add_child(pixel_container.container)
	
	pixel_size_slider = pixel_container.slider
	pixel_size_label = pixel_container.value_label
	pixel_size_slider.min_value = 1.0
	pixel_size_slider.max_value = 32.0
	pixel_size_slider.step = 1.0
	pixel_size_slider.value = current_settings.pixel_size
	pixel_size_slider.value_changed.connect(_on_pixel_size_changed)

func _create_color_reduction_section():
	"""Crear sección de reducción de colores"""
	colors_section = _create_collapsible_section("🎨 Reducción de Colores", false)
	main_container.add_child(colors_section)
	
	var content = colors_section.get_meta("content_container")
	
	# Activar reducción de colores
	reduce_colors_check = CheckBox.new()
	reduce_colors_check.text = "Reducir paleta de colores"
	reduce_colors_check.button_pressed = current_settings.reduce_colors
	reduce_colors_check.toggled.connect(_on_reduce_colors_changed)
	content.add_child(reduce_colors_check)
	
	# Niveles de color
	var levels_container = _create_labeled_slider_container("Niveles de color:")
	content.add_child(levels_container.container)
	
	color_levels_slider = levels_container.slider
	color_levels_label = levels_container.value_label
	color_levels_slider.min_value = 2
	color_levels_slider.max_value = 64
	color_levels_slider.step = 1
	color_levels_slider.value = current_settings.color_levels
	color_levels_slider.value_changed.connect(_on_color_levels_changed)

func _create_dithering_section():
	"""Crear sección de dithering"""
	dither_section = _create_collapsible_section("🔀 Dithering", false)
	main_container.add_child(dither_section)
	
	var content = dither_section.get_meta("content_container")
	
	# Activar dithering
	enable_dithering_check = CheckBox.new()
	enable_dithering_check.text = "Aplicar dithering"
	enable_dithering_check.button_pressed = current_settings.enable_dithering
	enable_dithering_check.toggled.connect(_on_enable_dithering_changed)
	content.add_child(enable_dithering_check)
	
	# Fuerza del dithering
	var strength_container = _create_labeled_slider_container("Intensidad:")
	content.add_child(strength_container.container)
	
	dither_strength_slider = strength_container.slider
	dither_strength_label = strength_container.value_label
	dither_strength_slider.min_value = 0.0
	dither_strength_slider.max_value = 1.0
	dither_strength_slider.step = 0.01
	dither_strength_slider.value = current_settings.dither_strength
	dither_strength_slider.value_changed.connect(_on_dither_strength_changed)

func _create_outline_section():
	"""Crear sección de efectos de borde - NUEVA FUNCIONALIDAD"""
	outline_section = _create_collapsible_section("🖼️ Efectos de Borde", false)
	main_container.add_child(outline_section)
	
	var content = outline_section.get_meta("content_container")
	
	# Activar bordes
	enable_outline_check = CheckBox.new()
	enable_outline_check.text = "Mostrar bordes"
	enable_outline_check.button_pressed = current_settings.enable_outline
	enable_outline_check.toggled.connect(_on_enable_outline_changed)
	content.add_child(enable_outline_check)
	
	# Grosor del borde
	var thickness_container = _create_labeled_slider_container("Grosor del borde:")
	content.add_child(thickness_container.container)
	
	outline_thickness_slider = thickness_container.slider
	outline_thickness_label = thickness_container.value_label
	outline_thickness_slider.min_value = 0.5
	outline_thickness_slider.max_value = 8.0
	outline_thickness_slider.step = 0.1
	outline_thickness_slider.value = current_settings.outline_thickness
	outline_thickness_slider.value_changed.connect(_on_outline_thickness_changed)
	
	# Color del borde
	var color_container = HBoxContainer.new()
	content.add_child(color_container)
	
	var color_label = Label.new()
	color_label.text = "Color del borde:"
	color_label.custom_minimum_size.x = 120
	color_container.add_child(color_label)
	
	# ColorPicker compacto para Godot 4.4
	var color_button = ColorPickerButton.new()
	color_button.custom_minimum_size = Vector2(80, 30)
	color_button.color = current_settings.outline_color
	color_button.color_changed.connect(_on_outline_color_changed)
	color_container.add_child(color_button)
	
	# Guardar referencia como ColorPicker para compatibilidad
	outline_color_picker = color_button
	
	# Borde pixelizado
	outline_pixelated_check = CheckBox.new()
	outline_pixelated_check.text = "Borde pixelizado"
	outline_pixelated_check.button_pressed = current_settings.outline_pixelated
	outline_pixelated_check.toggled.connect(_on_outline_pixelated_changed)
	content.add_child(outline_pixelated_check)
	
	# Suavizado del borde
	var smooth_container = _create_labeled_slider_container("Suavizado:")
	content.add_child(smooth_container.container)
	
	outline_smooth_slider = smooth_container.slider
	outline_smooth_label = smooth_container.value_label
	outline_smooth_slider.min_value = 0.0
	outline_smooth_slider.max_value = 1.0
	outline_smooth_slider.step = 0.01
	outline_smooth_slider.value = current_settings.outline_smooth
	outline_smooth_slider.value_changed.connect(_on_outline_smooth_changed)

func _create_advanced_effects_section():
	"""Crear sección de efectos avanzados"""
	advanced_section = _create_collapsible_section("⚡ Efectos Avanzados", false)
	main_container.add_child(advanced_section)
	
	var content = advanced_section.get_meta("content_container")
	
	# Contraste
	var contrast_container = _create_labeled_slider_container("Contraste:")
	content.add_child(contrast_container.container)
	
	contrast_slider = contrast_container.slider
	contrast_label = contrast_container.value_label
	contrast_slider.min_value = 0.5
	contrast_slider.max_value = 2.0
	contrast_slider.step = 0.01
	contrast_slider.value = current_settings.contrast_boost
	contrast_slider.value_changed.connect(_on_contrast_changed)
	
	# Saturación
	var saturation_container = _create_labeled_slider_container("Saturación:")
	content.add_child(saturation_container.container)
	
	saturation_slider = saturation_container.slider
	saturation_label = saturation_container.value_label
	saturation_slider.min_value = 0.0
	saturation_slider.max_value = 2.0
	saturation_slider.step = 0.01
	saturation_slider.value = current_settings.saturation_mult
	saturation_slider.value_changed.connect(_on_saturation_changed)
	
	# Tinte de color
	var tint_container = HBoxContainer.new()
	content.add_child(tint_container)
	
	var tint_label = Label.new()
	tint_label.text = "Tinte de color:"
	tint_label.custom_minimum_size.x = 120
	tint_container.add_child(tint_label)
	
	# ColorPickerButton compacto para Godot 4.4
	var tint_button = ColorPickerButton.new()
	tint_button.custom_minimum_size = Vector2(80, 30)
	tint_button.color = current_settings.color_tint
	tint_button.color_changed.connect(_on_color_tint_changed)
	tint_container.add_child(tint_button)
	
	# Guardar referencia
	color_tint_picker = tint_button
	
	# Corrección gamma
	gamma_check = CheckBox.new()
	gamma_check.text = "Aplicar corrección gamma"
	gamma_check.button_pressed = current_settings.apply_gamma_correction
	gamma_check.toggled.connect(_on_gamma_check_changed)
	content.add_child(gamma_check)
	
	# Valor gamma
	var gamma_container = _create_labeled_slider_container("Valor gamma:")
	content.add_child(gamma_container.container)
	
	gamma_slider = gamma_container.slider
	gamma_label = gamma_container.value_label
	gamma_slider.min_value = 0.5
	gamma_slider.max_value = 2.5
	gamma_slider.step = 0.01
	gamma_slider.value = current_settings.gamma_value
	gamma_slider.value_changed.connect(_on_gamma_value_changed)

func _create_actions_section():
	"""Crear sección de acciones"""
	actions_section = VBoxContainer.new()
	main_container.add_child(actions_section)
	
	var actions_title = Label.new()
	actions_title.text = "🔧 Acciones"
	actions_title.add_theme_font_size_override("font_size", 14)
	actions_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	actions_section.add_child(actions_title)
	
	var buttons_container = HBoxContainer.new()
	actions_section.add_child(buttons_container)
	
	# Botón reset
	reset_button = Button.new()
	reset_button.text = "🔄 Resetear"
	reset_button.pressed.connect(_on_reset_pressed)
	buttons_container.add_child(reset_button)
	
	# Botón exportar
	export_button = Button.new()
	export_button.text = "💾 Exportar Config"
	export_button.pressed.connect(_on_export_pressed)
	buttons_container.add_child(export_button)
	
	# Botón importar
	import_button = Button.new()
	import_button.text = "📂 Importar Config"
	import_button.pressed.connect(_on_import_pressed)
	buttons_container.add_child(import_button)

# ========================================================================
# FUNCIONES DE UTILIDAD PARA CREAR UI
# ========================================================================

func _create_collapsible_section(title: String, expanded: bool = false) -> VBoxContainer:
	"""Crear una sección colapsable usando controles nativos"""
	var section_container = VBoxContainer.new()
	
	# Botón de encabezado
	var header_button = Button.new()
	var arrow = "▼ " if expanded else "► "
	header_button.text = arrow + title
	header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_button.flat = true
	section_container.add_child(header_button)
	
	# Container de contenido
	var content_container = VBoxContainer.new()
	content_container.visible = expanded
	section_container.add_child(content_container)
	
	# Conectar toggle
	header_button.pressed.connect(func():
		content_container.visible = !content_container.visible
		var new_arrow = "▼ " if content_container.visible else "► "
		header_button.text = new_arrow + title
	)
	
	# Añadir referencia al contenido para fácil acceso
	section_container.set_meta("content_container", content_container)
	
	return section_container

func _create_labeled_slider_container(label_text: String) -> Dictionary:
	"""Crear container con slider y label de valor"""
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.custom_minimum_size.x = 60
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(value_label)
	
	return {
		"container": container,
		"label": label,
		"slider": slider,
		"value_label": value_label
	}

# ========================================================================
# CONFIGURACIÓN DE MATERIAL Y SHADER
# ========================================================================

func _create_preview_area():
	"""Crear área de vista previa en tiempo real"""
	# Esta función se puede expandir para incluir vista previa 3D
	print("🔍 Área de vista previa configurada")

func _setup_material_and_shader():
	"""Configurar material y shader avanzado"""
	preview_material = ShaderMaterial.new()
	
	# Cargar shader avanzado con error handling para Godot 4.4
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path) as Shader
		if shader:
			preview_material.shader = shader
			print("✅ Shader avanzado cargado exitosamente")
		else:
			print("❌ Error: El archivo existe pero no se pudo cargar como Shader")
	else:
		print("❌ Error: Archivo de shader no encontrado en: %s" % shader_path)
		print("   Asegúrate de que el shader esté guardado en la ubicación correcta")

# ========================================================================
# MANEJADORES DE EVENTOS DE UI
# ========================================================================

func _on_pixelize_enabled_changed(enabled: bool):
	"""Manejar cambio en activación de pixelización"""
	if is_updating_ui:
		return
	
	current_settings.pixelize_enabled = enabled
	_update_preview_and_emit()

func _on_pixel_size_changed(value: float):
	"""Manejar cambio en tamaño de pixel"""
	if is_updating_ui:
		return
	
	current_settings.pixel_size = value
	pixel_size_label.text = "%.0f" % value
	_update_preview_and_emit()

func _on_reduce_colors_changed(enabled: bool):
	"""Manejar cambio en reducción de colores"""
	if is_updating_ui:
		return
	
	current_settings.reduce_colors = enabled
	_update_preview_and_emit()

func _on_color_levels_changed(value: float):
	"""Manejar cambio en niveles de color"""
	if is_updating_ui:
		return
	
	current_settings.color_levels = int(value)
	color_levels_label.text = "%d" % int(value)
	_update_preview_and_emit()

func _on_enable_dithering_changed(enabled: bool):
	"""Manejar cambio en activación de dithering"""
	if is_updating_ui:
		return
	
	current_settings.enable_dithering = enabled
	_update_preview_and_emit()

func _on_dither_strength_changed(value: float):
	"""Manejar cambio en fuerza de dithering"""
	if is_updating_ui:
		return
	
	current_settings.dither_strength = value
	dither_strength_label.text = "%.2f" % value
	_update_preview_and_emit()

# === NUEVOS MANEJADORES PARA EFECTOS DE BORDE ===

func _on_enable_outline_changed(enabled: bool):
	"""Manejar cambio en activación de bordes"""
	if is_updating_ui:
		return
	
	current_settings.enable_outline = enabled
	_update_preview_and_emit()

func _on_outline_thickness_changed(value: float):
	"""Manejar cambio en grosor de borde"""
	if is_updating_ui:
		return
	
	current_settings.outline_thickness = value
	outline_thickness_label.text = "%.1f" % value
	_update_preview_and_emit()

func _on_outline_color_changed(color: Color):
	"""Manejar cambio en color de borde"""
	if is_updating_ui:
		return
	
	current_settings.outline_color = color
	_update_preview_and_emit()

func _on_outline_pixelated_changed(enabled: bool):
	"""Manejar cambio en pixelización de borde"""
	if is_updating_ui:
		return
	
	current_settings.outline_pixelated = enabled
	_update_preview_and_emit()

func _on_outline_smooth_changed(value: float):
	"""Manejar cambio en suavizado de borde"""
	if is_updating_ui:
		return
	
	current_settings.outline_smooth = value
	outline_smooth_label.text = "%.2f" % value
	_update_preview_and_emit()

# === MANEJADORES PARA EFECTOS AVANZADOS ===

func _on_contrast_changed(value: float):
	"""Manejar cambio en contraste"""
	if is_updating_ui:
		return
	
	current_settings.contrast_boost = value
	contrast_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_saturation_changed(value: float):
	"""Manejar cambio en saturación"""
	if is_updating_ui:
		return
	
	current_settings.saturation_mult = value
	saturation_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_color_tint_changed(color: Color):
	"""Manejar cambio en tinte de color"""
	if is_updating_ui:
		return
	
	current_settings.color_tint = color
	_update_preview_and_emit()

func _on_gamma_check_changed(enabled: bool):
	"""Manejar cambio en activación de gamma"""
	if is_updating_ui:
		return
	
	current_settings.apply_gamma_correction = enabled
	_update_preview_and_emit()

func _on_gamma_value_changed(value: float):
	"""Manejar cambio en valor gamma"""
	if is_updating_ui:
		return
	
	current_settings.gamma_value = value
	gamma_label.text = "%.2f" % value
	_update_preview_and_emit()

# === MANEJADORES DE ACCIONES ===

func _on_reset_pressed():
	"""Resetear a configuración por defecto"""
	print("🔄 Reseteando configuración a valores por defecto...")
	current_settings = default_settings.duplicate()
	_apply_current_settings()
	reset_to_defaults_requested.emit()

func _on_export_pressed():
	"""Exportar configuración actual"""
	print("💾 Exportando configuración...")
	# Implementar lógica de exportación
	
func _on_import_pressed():
	"""Importar configuración"""
	print("📂 Importando configuración...")
	# Implementar lógica de importación

# ========================================================================
# FUNCIONES PRINCIPALES DE APLICACIÓN
# ========================================================================

func _connect_all_signals():
	"""Conectar todas las señales de los controles"""
	print("🔗 Conectando señales de controles...")

func _apply_current_settings():
	"""Aplicar configuración actual a todos los controles"""
	is_updating_ui = true
	
	# Aplicar valores a pixelización
	if pixelize_enabled:
		pixelize_enabled.button_pressed = current_settings.pixelize_enabled
	if pixel_size_slider:
		pixel_size_slider.value = current_settings.pixel_size
		pixel_size_label.text = "%.0f" % current_settings.pixel_size
	
	# Aplicar valores a reducción de colores
	if reduce_colors_check:
		reduce_colors_check.button_pressed = current_settings.reduce_colors
	if color_levels_slider:
		color_levels_slider.value = current_settings.color_levels
		color_levels_label.text = "%d" % current_settings.color_levels
	
	# Aplicar valores a dithering
	if enable_dithering_check:
		enable_dithering_check.button_pressed = current_settings.enable_dithering
	if dither_strength_slider:
		dither_strength_slider.value = current_settings.dither_strength
		dither_strength_label.text = "%.2f" % current_settings.dither_strength
	
	# Aplicar valores a bordes
	if enable_outline_check:
		enable_outline_check.button_pressed = current_settings.enable_outline
	if outline_thickness_slider:
		outline_thickness_slider.value = current_settings.outline_thickness
		outline_thickness_label.text = "%.1f" % current_settings.outline_thickness
	if outline_color_picker:
		outline_color_picker.color = current_settings.outline_color
	if outline_pixelated_check:
		outline_pixelated_check.button_pressed = current_settings.outline_pixelated
	if outline_smooth_slider:
		outline_smooth_slider.value = current_settings.outline_smooth
		outline_smooth_label.text = "%.2f" % current_settings.outline_smooth
	
	# Aplicar valores a efectos avanzados
	if contrast_slider:
		contrast_slider.value = current_settings.contrast_boost
		contrast_label.text = "%.2f" % current_settings.contrast_boost
	if saturation_slider:
		saturation_slider.value = current_settings.saturation_mult
		saturation_label.text = "%.2f" % current_settings.saturation_mult
	if color_tint_picker:
		color_tint_picker.color = current_settings.color_tint
	if gamma_check:
		gamma_check.button_pressed = current_settings.apply_gamma_correction
	if gamma_slider:
		gamma_slider.value = current_settings.gamma_value
		gamma_label.text = "%.2f" % current_settings.gamma_value
	
	is_updating_ui = false
	print("✅ Configuración aplicada a controles")

func _update_preview_and_emit():
	"""Actualizar vista previa y emitir señal de cambio"""
	if not live_preview_enabled:
		return
	
	# Actualizar material de vista previa si existe
	if preview_material and preview_material.shader:
		_apply_settings_to_material(preview_material)
	
	# Emitir señal con configuración actualizada
	shader_settings_changed.emit(current_settings.duplicate())

func _apply_settings_to_material(material: ShaderMaterial):
	"""Aplicar configuración actual al material"""
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
	
	# Aplicar efectos avanzados
	material.set_shader_parameter("contrast_boost", current_settings.contrast_boost)
	material.set_shader_parameter("saturation_mult", current_settings.saturation_mult)
	material.set_shader_parameter("color_tint", current_settings.color_tint)
	material.set_shader_parameter("apply_gamma_correction", current_settings.apply_gamma_correction)
	material.set_shader_parameter("gamma_value", current_settings.gamma_value)

# ========================================================================
# API PÚBLICA PARA INTEGRACIÓN
# ========================================================================

func get_current_settings() -> Dictionary:
	"""Obtener configuración actual"""
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	"""Aplicar configuración externa"""
	current_settings = settings.duplicate()
	_apply_current_settings()

func get_preview_material() -> ShaderMaterial:
	"""Obtener material de vista previa configurado"""
	return preview_material
