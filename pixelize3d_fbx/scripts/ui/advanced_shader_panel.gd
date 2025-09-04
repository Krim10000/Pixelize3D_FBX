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

# === REFERENCIAS A CONTROLES DE UI ===
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

# Sección: Efectos de Borde
var outline_section: VBoxContainer
var enable_outline_check: CheckBox
var outline_thickness_slider: HSlider
var outline_thickness_label: Label
var outline_color_picker: ColorPickerButton
var outline_pixelated_check: CheckBox
var outline_smooth_slider: HSlider
var outline_smooth_label: Label

# Sección: Efectos Avanzados de Color
var advanced_effects: CheckBox
var advanced_section: VBoxContainer
var contrast_slider: HSlider
var contrast_label: Label
var saturation_slider: HSlider
var saturation_label: Label
var color_tint_picker: ColorPickerButton
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
var debug_mode: bool = false  # Control para mensajes de depuración

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
	"advanced_effects_enabled": false,
	"contrast_boost": 1.0,
	"saturation_mult": 1.0,
	"color_tint": Color(1, 1, 1, 1),
	"apply_gamma_correction": false,
	"gamma_value": 1.0
}

func _ready():
	if debug_mode:
		print("🎨 AdvancedShaderPanel inicializando...")
	_initialize_settings()
	_create_ui_layout()
	_setup_material_and_shader()
	_apply_current_settings()
	if debug_mode:
		print("✅ AdvancedShaderPanel completamente inicializado")

# ========================================================================
# INICIALIZACIÓN Y CONFIGURACIÓN
# ========================================================================

func _initialize_settings():
	"""Inicializar configuración con valores por defecto"""
	current_settings = default_settings.duplicate()
	if debug_mode:
		print("⚙️ Configuración inicializada con valores por defecto")

func _create_ui_layout():
	"""Crear layout principal de la interfaz"""
	if debug_mode:
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
	scroll_container.add_child(main_container)
	
	# Crear todas las secciones
	_create_pixelization_section()
	_create_color_reduction_section()
	_create_dithering_section()
	_create_outline_section()
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
	"""Crear sección de efectos de borde"""
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
	
	outline_color_picker = ColorPickerButton.new()
	outline_color_picker.custom_minimum_size = Vector2(80, 30)
	outline_color_picker.color = current_settings.outline_color
	outline_color_picker.color_changed.connect(_on_outline_color_changed)
	color_container.add_child(outline_color_picker)
	
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
	
	# Checkbox para activar/desactivar efectos avanzados
	advanced_effects = CheckBox.new()
	advanced_effects.text = "Aplicar Efectos avanzados"
	advanced_effects.button_pressed = current_settings.advanced_effects_enabled
	advanced_effects.toggled.connect(_on_advanced_effects_toggled)
	content.add_child(advanced_effects)
	
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
	
	color_tint_picker = ColorPickerButton.new()
	color_tint_picker.custom_minimum_size = Vector2(80, 30)
	color_tint_picker.color = current_settings.color_tint
	color_tint_picker.color_changed.connect(_on_color_tint_changed)
	tint_container.add_child(color_tint_picker)
	
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
	
	# Actualizar estado inicial de controles avanzados
	_update_advanced_controls_state()

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
	
	# Botón exportar (oculto hasta implementar)
	export_button = Button.new()
	export_button.text = "💾 Exportar Config"
	export_button.pressed.connect(_on_export_pressed)
	export_button.visible = false  # Ocultar hasta implementar
	buttons_container.add_child(export_button)
	
	# Botón importar (oculto hasta implementar)
	import_button = Button.new()
	import_button.text = "📂 Importar Config"
	import_button.pressed.connect(_on_import_pressed)
	import_button.visible = false  # Ocultar hasta implementar
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

func _setup_material_and_shader():
	"""Configurar material y shader avanzado"""
	preview_material = ShaderMaterial.new()
	
	# Cargar shader avanzado con error handling para Godot 4.4
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path) as Shader
		if shader:
			preview_material.shader = shader
			if debug_mode:
				print("✅ Shader avanzado cargado exitosamente")
		else:
			push_error("❌ Error: El archivo existe pero no se pudo cargar como Shader")
	else:
		push_error("❌ Error: Archivo de shader no encontrado en: %s" % shader_path)

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
	if pixel_size_label:
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
	if color_levels_label:
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
	if dither_strength_label:
		dither_strength_label.text = "%.2f" % value
	_update_preview_and_emit()

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
	if outline_thickness_label:
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
	if outline_smooth_label:
		outline_smooth_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_advanced_effects_toggled(enabled: bool):
	"""Manejar cambio en activación de efectos avanzados"""
	if is_updating_ui:
		return
	
	current_settings.advanced_effects_enabled = enabled
	_update_advanced_controls_state()
	_update_preview_and_emit()

func _on_contrast_changed(value: float):
	"""Manejar cambio en contraste"""
	if is_updating_ui:
		return
	
	current_settings.contrast_boost = value
	if contrast_label:
		contrast_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_saturation_changed(value: float):
	"""Manejar cambio en saturación"""
	if is_updating_ui:
		return
	
	current_settings.saturation_mult = value
	if saturation_label:
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
	if gamma_label:
		gamma_label.text = "%.2f" % value
	_update_preview_and_emit()

func _on_reset_pressed():
	"""Resetear a configuración por defecto"""
	if debug_mode:
		print("🔄 Reseteando configuración a valores por defecto...")
	current_settings = default_settings.duplicate()
	_apply_current_settings()
	reset_to_defaults_requested.emit()

func _on_export_pressed():
	"""Exportar configuración actual"""
	if debug_mode:
		print("💾 Exportando configuración...")
	# TODO: Implementar exportación

func _on_import_pressed():
	"""Importar configuración"""
	if debug_mode:
		print("📂 Importando configuración...")
	# TODO: Implementar importación

# ========================================================================
# FUNCIONES PRINCIPALES DE APLICACIÓN
# ========================================================================

func _update_advanced_controls_state():
	"""Actualizar estado de controles avanzados basado en el checkbox"""
	var enabled = current_settings.advanced_effects_enabled
	
	if contrast_slider:
		contrast_slider.editable = enabled
	if saturation_slider:
		saturation_slider.editable = enabled
	if color_tint_picker:
		color_tint_picker.disabled = not enabled
	if gamma_check:
		gamma_check.disabled = not enabled
	if gamma_slider:
		gamma_slider.editable = enabled

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
	if advanced_effects:
		advanced_effects.button_pressed = current_settings.advanced_effects_enabled
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
	
	# Actualizar estado de controles avanzados
	_update_advanced_controls_state()
	
	is_updating_ui = false
	
	# Aplicar shader al modelo inmediatamente después de cargar configuración
	call_deferred("_force_preview_update")

func _update_preview_and_emit():
	"""Actualizar vista previa y emitir señal de cambio"""
	if not live_preview_enabled:
		return
	
	# Actualizar material de vista previa interno
	if preview_material and preview_material.shader:
		_apply_settings_to_material(preview_material)
	
	# Forzar actualización del preview en tiempo real
	call_deferred("_force_preview_update")
	
	# Emitir señal con configuración actualizada
	shader_settings_changed.emit(current_settings.duplicate())

#func _apply_settings_to_material(material: ShaderMaterial):
	#"""Aplicar configuración actual al material"""
	#if not material or not material.shader:
		#return
	#
	## Aplicar parámetros de pixelización
	#material.set_shader_parameter("pixel_size", current_settings.pixel_size)
	#material.set_shader_parameter("pixelize_enabled", current_settings.pixelize_enabled)
	#
	## Aplicar parámetros de reducción de colores
	#material.set_shader_parameter("reduce_colors", current_settings.reduce_colors)
	#material.set_shader_parameter("color_levels", current_settings.color_levels)
	#
	## Aplicar parámetros de dithering
	#material.set_shader_parameter("enable_dithering", current_settings.enable_dithering)
	#material.set_shader_parameter("dither_strength", current_settings.dither_strength)
	#
	## Aplicar parámetros de bordes
	#material.set_shader_parameter("enable_outline", current_settings.enable_outline)
	#material.set_shader_parameter("outline_thickness", current_settings.outline_thickness)
	#material.set_shader_parameter("outline_color", current_settings.outline_color)
	#material.set_shader_parameter("outline_pixelated", current_settings.outline_pixelated)
	#material.set_shader_parameter("outline_smooth", current_settings.outline_smooth)
	#
	## Aplicar efectos avanzados (solo si están habilitados)
	#var apply_advanced = current_settings.advanced_effects_enabled
	#
	#material.set_shader_parameter("contrast_boost", 
		#current_settings.contrast_boost if apply_advanced else 1.0)
	#material.set_shader_parameter("saturation_mult", 
		#current_settings.saturation_mult if apply_advanced else 1.0)
	#material.set_shader_parameter("color_tint", 
		#current_settings.color_tint if apply_advanced else Color.WHITE)
	#material.set_shader_parameter("apply_gamma_correction", 
		#current_settings.apply_gamma_correction if apply_advanced else false)
	#material.set_shader_parameter("gamma_value", 
		#current_settings.gamma_value if apply_advanced else 1.0)

func _apply_settings_to_material(material: ShaderMaterial):
	"""Aplicar configuración actual al material"""
	if not material or not material.shader:
		return
	
	# Aplicar parámetros de pixelización
	material.set_shader_parameter("pixel_size", current_settings.pixel_size)
	material.set_shader_parameter("pixelize_enabled", current_settings.pixelize_enabled)
	
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
	
	# Aplicar efectos avanzados (solo si están habilitados)
	var apply_advanced = current_settings.advanced_effects_enabled
	
	# Contraste: usar valor configurado si está activado, valor neutro (1.0) si no
	material.set_shader_parameter("contrast_boost", 
		current_settings.contrast_boost if apply_advanced else 1.0)
	
	# Saturación: usar valor configurado si está activado, valor neutro (1.0) si no
	material.set_shader_parameter("saturation_mult", 
		current_settings.saturation_mult if apply_advanced else 1.0)
	
	# Tinte de color: usar valor configurado si está activado, color neutro (blanco) si no
	# El color neutro debe ser (1, 1, 1, 1) para no afectar los colores originales
	material.set_shader_parameter("color_tint", 
		current_settings.color_tint if apply_advanced else Color(1, 1, 1, 1))
	
	# Corrección gamma: aplicar solo si está activado
	material.set_shader_parameter("apply_gamma_correction", 
		current_settings.apply_gamma_correction if apply_advanced else false)
	
	# Valor gamma: usar valor configurado si está activado, valor neutro (1.0) si no
	material.set_shader_parameter("gamma_value", 
		current_settings.gamma_value if apply_advanced else 1.0)
# ========================================================================
# FUNCIONES PARA CONECTAR CON EL MODELO DEL PREVIEW
# ========================================================================

func _force_preview_update():
	"""Forzar actualización inmediata del modelo del preview"""
	if debug_mode:
		print("🔄 Forzando actualización de preview...")
	
	# Intentar múltiples métodos para aplicar al preview
	var success = false
	
	# Método 1: Aplicación directa al modelo
	if _apply_shader_to_preview_model():
		success = true
		if debug_mode:
			print("✅ Método 1: Aplicación directa exitosa")
	
	# Método 2: A través del ViewerCoordinator
	if not success:
		success = _apply_through_coordinator()
		if success and debug_mode:
			print("✅ Método 2: A través de coordinator exitoso")
	
	if not success and debug_mode:
		print("❌ No se pudo aplicar shader al preview")
		_debug_preview_state()

func _apply_shader_to_preview_model() -> bool:
	"""Aplicar shader avanzado al modelo del preview en tiempo real"""
	var preview_model = _find_preview_model()
	if not preview_model:
		if debug_mode:
			print("⚠️ No se encontró modelo de preview para aplicar shader")
		return false
	
	# Aplicar shader a todas las mallas del modelo
	var meshes_updated = 0
	meshes_updated = _apply_shader_to_node_recursive(preview_model, meshes_updated)
	
	if meshes_updated > 0:
		if debug_mode:
			print("✅ Shader avanzado aplicado a %d mesh(es)" % meshes_updated)
		return true
	else:
		if debug_mode:
			print("⚠️ No se encontraron meshes para aplicar shader")
		return false

func _find_preview_model() -> Node3D:
	"""Buscar el modelo del preview en ModelContainer"""
	
	# Ruta exacta confirmada desde viewer_modular.tscn
	var model_container_path = "/root/ViewerModular/HSplitContainer/RightPanel/ModelPreviewPanel/ViewportContainer/SubViewport/ModelContainer"
	var model_container = get_node_or_null(model_container_path)
	
	if model_container:
		if debug_mode:
			print("✅ ModelContainer encontrado en: %s" % model_container_path)
		
		# Buscar el modelo dentro de ModelContainer
		for child in model_container.get_children():
			if child is Node3D and ("Model" in child.name or "Combined" in child.name or _has_mesh_instance(child)):
				if debug_mode:
					print("✅ Modelo encontrado en ModelContainer: %s" % child.name)
				return child
	else:
		if debug_mode:
			print("❌ ModelContainer no encontrado en la ruta esperada")
		# Búsqueda alternativa más específica
		return _search_for_model_in_viewports()
	
	return null

func _search_for_model_in_viewports() -> Node3D:
	"""Búsqueda alternativa en viewports si la ruta principal falla"""
	var root_scene = get_tree().current_scene
	
	# Buscar todos los SubViewport en la escena
	var viewports = _find_all_nodes_of_type(root_scene, "SubViewport")
	
	for viewport in viewports:
		# Buscar ModelContainer dentro del viewport
		var model_container = viewport.get_node_or_null("ModelContainer")
		if model_container:
			for child in model_container.get_children():
				if child is Node3D and _has_mesh_instance(child):
					if debug_mode:
						print("✅ Modelo encontrado en búsqueda alternativa: %s" % child.name)
					return child
	
	if debug_mode:
		print("❌ No se encontró modelo en ningún viewport")
	return null

func _find_all_nodes_of_type(node: Node, type_name: String) -> Array:
	"""Buscar todos los nodos de un tipo específico recursivamente"""
	var results = []
	
	if node.get_class() == type_name:
		results.append(node)
	
	for child in node.get_children():
		results.append_array(_find_all_nodes_of_type(child, type_name))
	
	return results

func _has_mesh_instance(node: Node) -> bool:
	"""Verificar si un nodo tiene MeshInstance3D (directamente o en hijos)"""
	if node is MeshInstance3D:
		return true
	
	for child in node.get_children():
		if child is MeshInstance3D:
			return true
		if _has_mesh_instance(child):
			return true
	
	return false

func _apply_shader_to_node_recursive(node: Node, meshes_updated: int) -> int:
	"""Aplicar shader a todos los MeshInstance3D de un nodo recursivamente"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if _apply_shader_to_mesh_instance(mesh_instance):
			meshes_updated += 1
			if debug_mode:
				print("  - Shader aplicado a: %s" % mesh_instance.name)
	
	for child in node.get_children():
		meshes_updated = _apply_shader_to_node_recursive(child, meshes_updated)
	
	return meshes_updated

func _apply_shader_to_mesh_instance(mesh_instance: MeshInstance3D) -> bool:
	"""Aplicar shader avanzado a una instancia de mesh específica"""
	if not mesh_instance or not mesh_instance.mesh:
		return false
	
	# Crear material con shader avanzado si no existe
	var shader_material = _create_or_get_shader_material(mesh_instance)
	if not shader_material:
		return false
	
	# Aplicar configuración actual al material
	_apply_settings_to_material(shader_material)
	
	# Aplicar el material a todas las superficies
	for surface_idx in range(mesh_instance.mesh.get_surface_count()):
		mesh_instance.set_surface_override_material(surface_idx, shader_material)
	
	return true

func _create_or_get_shader_material(mesh_instance: MeshInstance3D) -> ShaderMaterial:
	"""Crear o obtener material con shader avanzado para una instancia de mesh"""
	
	# Verificar si ya tiene un material con nuestro shader
	var existing_material = mesh_instance.get_surface_override_material(0)
	if existing_material is ShaderMaterial:
		var shader_mat = existing_material as ShaderMaterial
		if shader_mat.shader and shader_mat.shader.resource_path.ends_with("pixelize_advanced.gdshader"):
			return shader_mat
	
	# Crear nuevo material con shader avanzado
	var shader_material = ShaderMaterial.new()
	
	# Cargar shader avanzado
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path) as Shader
		if shader:
			shader_material.shader = shader
			if debug_mode:
				print("✅ Shader avanzado aplicado a mesh: %s" % mesh_instance.name)
			return shader_material
		else:
			push_error("❌ Error cargando shader desde: %s" % shader_path)
	else:
		push_error("❌ Shader no encontrado en: %s" % shader_path)
	
	return null

func _apply_through_coordinator() -> bool:
	"""Aplicar shader a través del ViewerCoordinator"""
	var coordinator = get_node_or_null("/root/ViewerModular")
	if not coordinator:
		return false
	
	# Buscar método para actualizar preview
	if coordinator.has_method("apply_advanced_shader_to_preview"):
		coordinator.apply_advanced_shader_to_preview(current_settings)
		return true
	
	return false

func _debug_preview_state():
	"""Debug del estado actual del preview"""
	if not debug_mode:
		return
	
	print("\n🔍 === DEBUG ESTADO DEL PREVIEW ===")
	
	# Verificar modelo
	var model = _find_preview_model()
	if model:
		print("✅ Modelo encontrado: %s" % model.name)
		print("  Ruta: %s" % model.get_path())
		
		# Verificar meshes
		var mesh_count = 0
		mesh_count = _count_meshes_recursive(model, mesh_count)
		print("  MeshInstance3D encontradas: %d" % mesh_count)
		
		# Verificar materiales
		_debug_materials_recursive(model)
	else:
		print("❌ No se encontró modelo del preview")
	
	print("=====================================\n")

func _count_meshes_recursive(node: Node, count: int) -> int:
	"""Contar meshes recursivamente"""
	if node is MeshInstance3D:
		count += 1
	
	for child in node.get_children():
		count = _count_meshes_recursive(child, count)
	
	return count

func _debug_materials_recursive(node: Node):
	"""Debug de materiales recursivamente"""
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		print("  Mesh: %s" % mesh_instance.name)
		
		for i in range(mesh_instance.mesh.get_surface_count() if mesh_instance.mesh else 0):
			var material = mesh_instance.get_surface_override_material(i)
			if material:
				print("    Superficie %d: %s" % [i, material.get_class()])
				if material is ShaderMaterial:
					var shader_mat = material as ShaderMaterial
					print("      Shader: %s" % (shader_mat.shader.resource_path if shader_mat.shader else "null"))
			else:
				print("    Superficie %d: sin material override" % i)
	
	for child in node.get_children():
		_debug_materials_recursive(child)

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

func set_debug_mode(enabled: bool):
	"""Activar/desactivar modo de depuración"""
	debug_mode = enabled

func set_live_preview(enabled: bool):
	"""Activar/desactivar vista previa en tiempo real"""
	live_preview_enabled = enabled
