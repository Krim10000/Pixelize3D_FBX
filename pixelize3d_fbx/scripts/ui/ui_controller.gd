# pixelize3d_fbx/scripts/ui/ui_controller.gd
# Script de interfaz de usuario corregido para exploración de assets/fbx/ y checkboxes de animaciones
# Input: Interacciones del usuario (incluyendo orientación del modelo y selección por unidades)
# Output: Señales y configuración para el proceso de renderizado con orientación coherente

extends Control

signal unit_selected(unit_data: Dictionary)
signal folder_selected(path: String)
signal base_fbx_selected(filename: String)
signal animations_selected(filenames: Array)
signal render_settings_changed(settings: Dictionary)
signal render_requested()
signal export_requested(settings: Dictionary)

# Referencias a controles UI (sin @onready ya que se crean dinámicamente)
var main_panel: PanelContainer
var folder_dialog: FileDialog
var progress_dialog: AcceptDialog
var preview_viewport: SubViewport

# NUEVO: Controles para exploración de unidades
var units_option: OptionButton
var unit_info_label: Label

var folder_path_label: Label
var fbx_list: ItemList
var base_fbx_option: OptionButton

# MODIFICADO: Contenedor para checkboxes de animaciones en lugar de ItemList
var animations_container: VBoxContainer
var animation_checkboxes: Array = []

var directions_spinbox: SpinBox
var sprite_size_spinbox: SpinBox
var camera_angle_slider: HSlider
var camera_height_slider: HSlider
var camera_distance_slider: HSlider
var fps_spinbox: SpinBox
var pixelize_checkbox: CheckBox
var preview_button: Button
var render_button: Button
var export_log: RichTextLabel

# Control para orientación norte
var north_offset_slider: HSlider
var north_offset_label: Label

var current_folder_path: String = ""
var available_fbx_files: Array = []
var selected_animations: Array = []
var preview_mode_active: bool = false

# NUEVO: Datos de unidades disponibles
var available_units: Array = []
var current_unit_data: Dictionary = {}

# NUEVAS VARIABLES PARA SHADER AVANZADO
var advanced_shader_panel: Control = null
var basic_pixelize_checkbox: CheckBox = null
var show_shader_panel_button: Button = null

# Estado del panel de shader
var current_shader_settings: Dictionary = {}

func _ready():
	_create_ui()
	_connect_ui_signals()
	_apply_theme()
	_connect_north_slider_signal()
	call_deferred("_connect_north_slider_signal")

func _create_ui():
	# Panel principal
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_panel.add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "Pixelize3D FBX - Sprite Generator"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	main_vbox.add_child(HSeparator.new())
	
	# Contenedor principal con split
	var hsplit = HSplitContainer.new()
	hsplit.name = "HSplitContainer"
	hsplit.split_offset = 600
	main_vbox.add_child(hsplit)
	
	# Panel izquierdo - Configuración
	var left_panel = _create_config_panel()
	hsplit.add_child(left_panel)
	
	# Panel derecho - Preview
	var right_panel = _create_preview_panel()
	hsplit.add_child(right_panel)
	
	# Panel inferior - Log
	var log_panel = _create_log_panel()
	main_vbox.add_child(log_panel)
	
	# Diálogos (crear después del panel principal)
	_create_dialogs()

func _create_config_panel() -> Control:
	var panel = ScrollContainer.new()
	panel.name = "ConfigPanel"
	panel.custom_minimum_size = Vector2(400, 0)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# NUEVA SECCIÓN: Selección de Unidad
	var unit_section = _create_section("📁 Seleccionar Unidad")
	vbox.add_child(unit_section)
	
	var unit_desc = Label.new()
	unit_desc.text = "Unidades encontradas en res://assets/fbx/"
	unit_desc.add_theme_font_size_override("font_size", 10)
	unit_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	unit_section.add_child(unit_desc)
	
	units_option = OptionButton.new()
	units_option.add_item("-- Cargando unidades... --")
	units_option.disabled = true
	unit_section.add_child(units_option)
	
	unit_info_label = Label.new()
	unit_info_label.text = ""
	unit_info_label.add_theme_font_size_override("font_size", 10)
	unit_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	unit_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unit_section.add_child(unit_info_label)
	
	# Sección: Selección de FBX base
	var base_section = _create_section("Modelo Base")
	vbox.add_child(base_section)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Seleccionar unidad primero --")
	base_fbx_option.disabled = true
	base_section.add_child(base_fbx_option)
	
	# SECCIÓN MODIFICADA: Selección de animaciones con checkboxes
	var anim_section = _create_section("📋 Animaciones")
	vbox.add_child(anim_section)
	
	var anim_desc = Label.new()
	anim_desc.text = "Selecciona las animaciones a renderizar:"
	anim_desc.add_theme_font_size_override("font_size", 10)
	anim_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	anim_section.add_child(anim_desc)
	
	# Contenedor para checkboxes de animaciones
	animations_container = VBoxContainer.new()
	animations_container.name = "AnimationsContainer"
	anim_section.add_child(animations_container)
	
	var no_animations_label = Label.new()
	no_animations_label.name = "NoAnimationsLabel"
	no_animations_label.text = "Selecciona una unidad para ver animaciones disponibles"
	no_animations_label.add_theme_font_size_override("font_size", 10)
	no_animations_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	animations_container.add_child(no_animations_label)
	
	# Sección: Configuración de renderizado
	var render_section = _create_section("Configuración de Renderizado")
	vbox.add_child(render_section)
	
	# Direcciones
	var dir_hbox = HBoxContainer.new()
	render_section.add_child(dir_hbox)
	
	var dir_label = Label.new()
	dir_label.text = "Direcciones:"
	dir_hbox.add_child(dir_label)
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 4
	directions_spinbox.max_value = 32
	directions_spinbox.step = 4
	directions_spinbox.value = 16
	dir_hbox.add_child(directions_spinbox)
	
	# Tamaño de sprite
	var size_hbox = HBoxContainer.new()
	render_section.add_child(size_hbox)
	
	var size_label = Label.new()
	size_label.text = "Tamaño sprite:"
	size_hbox.add_child(size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 32
	sprite_size_spinbox.max_value = 1024
	sprite_size_spinbox.step = 32
	sprite_size_spinbox.value = 256
	size_hbox.add_child(sprite_size_spinbox)
	
	# FPS
	var fps_hbox = HBoxContainer.new()
	render_section.add_child(fps_hbox)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_hbox.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 1
	fps_spinbox.max_value = 60
	fps_spinbox.value = 12
	fps_hbox.add_child(fps_spinbox)
	
	# Sección: Configuración de cámara
	var camera_section = _create_section("Cámara")
	vbox.add_child(camera_section)
	
	# Ángulo
	var angle_label = Label.new()
	angle_label.text = "Ángulo:"
	camera_section.add_child(angle_label)
	camera_angle_slider = _create_slider(15, 75, 45)
	camera_section.add_child(camera_angle_slider)
	
	# Altura
	var height_label = Label.new()
	height_label.text = "Altura:"
	camera_section.add_child(height_label)
	camera_height_slider = _create_slider(1, 50, 10)
	camera_section.add_child(camera_height_slider)
	
	# Distancia
	var distance_label = Label.new()
	distance_label.text = "Distancia:"
	camera_section.add_child(distance_label)
	camera_distance_slider = _create_slider(5, 100, 15)
	camera_section.add_child(camera_distance_slider)
	
	# Sección: Orientación del Modelo
	var orientation_section = _create_section("🧭 Orientación del Modelo")
	vbox.add_child(orientation_section)
	
	# Descripción de la orientación
	var orientation_desc = Label.new()
	orientation_desc.text = "Ajusta la orientación del modelo para que todos los sprites sean coherentes"
	orientation_desc.add_theme_font_size_override("font_size", 10)
	orientation_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	orientation_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	orientation_section.add_child(orientation_desc)
	
	# Control de orientación norte con container horizontal
	var north_container = HBoxContainer.new()
	orientation_section.add_child(north_container)
	
	var north_label_static = Label.new()
	north_label_static.text = "Norte del modelo:"
	north_label_static.custom_minimum_size.x = 120
	north_container.add_child(north_label_static)
	
	# Slider de orientación norte (0-360 grados)
	north_offset_slider = HSlider.new()
	north_offset_slider.min_value = 0.0
	north_offset_slider.max_value = 360.0
	north_offset_slider.step = 1.0
	north_offset_slider.value = 0.0
	north_offset_slider.custom_minimum_size.x = 200
	north_container.add_child(north_offset_slider)
	
	# Label para mostrar el valor actual
	north_offset_label = Label.new()
	north_offset_label.text = "0°"
	north_offset_label.custom_minimum_size.x = 40
	north_offset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	north_container.add_child(north_offset_label)
	
	# Botones de preset para orientaciones comunes
	var preset_container = HBoxContainer.new()
	orientation_section.add_child(preset_container)
	
	var preset_label = Label.new()
	preset_label.text = "Presets:"
	preset_label.custom_minimum_size.x = 120
	preset_container.add_child(preset_label)
	
	# Botones de preset
	var north_preset = Button.new()
	north_preset.text = "Norte"
	north_preset.custom_minimum_size.x = 60
	north_preset.pressed.connect(_on_north_preset_pressed.bind(0.0))
	preset_container.add_child(north_preset)
	
	var east_preset = Button.new()
	east_preset.text = "Este"
	east_preset.custom_minimum_size.x = 60
	east_preset.pressed.connect(_on_north_preset_pressed.bind(90.0))
	preset_container.add_child(east_preset)
	
	var south_preset = Button.new()
	south_preset.text = "Sur"
	south_preset.custom_minimum_size.x = 60
	south_preset.pressed.connect(_on_north_preset_pressed.bind(180.0))
	preset_container.add_child(south_preset)
	
	var west_preset = Button.new()
	west_preset.text = "Oeste"
	west_preset.custom_minimum_size.x = 60
	west_preset.pressed.connect(_on_north_preset_pressed.bind(270.0))
	preset_container.add_child(west_preset)
	
	# SECCIÓN CORREGIDA: EFECTOS (antes era Cámara)
	var effects_section = _create_section("🎨 EFECTOS")
	vbox.add_child(effects_section)
	
	# Container horizontal para checkbox y botón avanzado
	var pixelize_container = HBoxContainer.new()
	effects_section.add_child(pixelize_container)
	
	# Checkbox básico (mantener compatibilidad)
	basic_pixelize_checkbox = CheckBox.new()
	basic_pixelize_checkbox.text = "Aplicar pixelización"
	basic_pixelize_checkbox.button_pressed = true
	basic_pixelize_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic_pixelize_checkbox.toggled.connect(_on_basic_pixelize_toggled)
	pixelize_container.add_child(basic_pixelize_checkbox)
	
	# Mantener referencia para compatibilidad
	pixelize_checkbox = basic_pixelize_checkbox
	
	# Botón avanzado
	show_shader_panel_button = Button.new()
	show_shader_panel_button.text = "⚙️ Avanzado"
	show_shader_panel_button.custom_minimum_size.x = 100
	show_shader_panel_button.pressed.connect(_on_show_advanced_shader_panel)
	pixelize_container.add_child(show_shader_panel_button)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = "Click 'Avanzado' para configuración detallada de efectos"
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_section.add_child(desc_label)
	
	# Botones de acción
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	preview_button = Button.new()
	preview_button.text = "Preview"
	preview_button.disabled = true
	button_hbox.add_child(preview_button)
	
	render_button = Button.new()
	render_button.text = "Renderizar"
	render_button.disabled = true
	button_hbox.add_child(render_button)
	
	return panel

func _create_preview_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "PreviewPanel"
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Vista Previa"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Status del preview
	var status_label = Label.new()
	status_label.name = "PreviewStatus"
	status_label.text = "Selecciona una unidad para ver preview"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.name = "ViewportContainer"
	viewport_container.stretch = false
	viewport_container.custom_minimum_size = Vector2(128, 128)
	vbox.add_child(viewport_container)
	
	preview_viewport = SubViewport.new()
	preview_viewport.name = "SubViewport"
	preview_viewport.size = Vector2i(128,128)
	preview_viewport.transparent_bg = true
	viewport_container.add_child(preview_viewport)
	
	# Instrucciones de controles
	var controls_label = Label.new()
	controls_label.name = "ControlsHelp"
	controls_label.text = "Controles: Click + Arrastrar = Rotar | Rueda = Zoom"
	controls_label.add_theme_font_size_override("font_size", 10)
	controls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.visible = false
	vbox.add_child(controls_label)
	
	return panel

func _create_log_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "LogPanel"
	panel.custom_minimum_size.y = 150
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Log de Exportación"
	vbox.add_child(label)
	
	export_log = RichTextLabel.new()
	export_log.custom_minimum_size.y = 100
	export_log.scroll_following = true
	export_log.bbcode_enabled = true
	export_log.fit_content = true
	vbox.add_child(export_log)
	
	return panel

func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	section.add_child(label)
	
	section.add_child(HSeparator.new())
	
	return section

func _create_slider(min_val: float, max_val: float, default: float) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default
	slider.step = 0.1
	return slider

func _create_dialogs():
	# Diálogo de selección de carpeta (mantenido para compatibilidad)
	folder_dialog = FileDialog.new()
	folder_dialog.name = "FileDialog"
	folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.title = "Seleccionar carpeta del proyecto"
	folder_dialog.dir_selected.connect(_on_folder_selected)
	add_child(folder_dialog)
	
	# Diálogo de progreso
	progress_dialog = AcceptDialog.new()
	progress_dialog.name = "ProgressDialog"
	progress_dialog.title = "Renderizando..."
	progress_dialog.dialog_hide_on_ok = false
	progress_dialog.get_ok_button().visible = false
	
	var progress_content = VBoxContainer.new()
	progress_content.custom_minimum_size = Vector2(300, 80)
	
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Preparando renderizado..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_content.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.show_percentage = true
	progress_content.add_child(progress_bar)
	
	progress_dialog.add_child(progress_content)
	add_child(progress_dialog)

func _connect_ui_signals():
	# NUEVO: Conectar señal de selección de unidad
	if units_option:
		units_option.item_selected.connect(_on_unit_selected)
	
	# Conectar señales de UI
	if base_fbx_option:
		base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	
	if render_button:
		render_button.pressed.connect(_on_render_pressed)
	
	# Conectar sliders (incluyendo el nuevo slider de orientación norte)
	for slider in [camera_angle_slider, camera_height_slider, camera_distance_slider, north_offset_slider]:
		if slider:
			slider.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar spinboxes
	for spinbox in [directions_spinbox, sprite_size_spinbox, fps_spinbox]:
		if spinbox:
			spinbox.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar checkbox
	if pixelize_checkbox:
		pixelize_checkbox.toggled.connect(_on_camera_setting_changed)
	
	# Conectar slider de orientación norte para actualizar el label
	if north_offset_slider:
		north_offset_slider.value_changed.connect(_on_north_offset_changed)
	
	if basic_pixelize_checkbox:
		basic_pixelize_checkbox.toggled.connect(_on_basic_pixelize_toggled)

func _apply_theme():
	# Aplicar tema personalizado si es necesario
	pass

func initialize():
	add_export_log("Pixelize3D FBX iniciado")
	add_export_log("🔍 Explorando res://assets/fbx/ para encontrar unidades...")

# NUEVA FUNCIÓN: Mostrar unidades disponibles
func display_available_units(units: Array):
	available_units = units
	
	if units_option:
		units_option.clear()
		units_option.add_item("-- Seleccionar unidad --")
		
		for unit in units:
			var display_name = "%s (%d FBX)" % [unit.name, unit.all_fbx.size()]
			units_option.add_item(display_name)
		
		units_option.disabled = false
	
	add_export_log("✅ Encontradas %d unidades en res://assets/fbx/" % units.size())

# NUEVA FUNCIÓN: Manejar selección de unidad
func _on_unit_selected(index: int):
	if index == 0:  # "-- Seleccionar unidad --"
		return
	
	var unit_index = index - 1
	if unit_index >= 0 and unit_index < available_units.size():
		current_unit_data = available_units[unit_index]
		
		# Actualizar información de la unidad
		if unit_info_label:
			var info_text = "📁 %s\n📄 Base: %s\n🎬 Animaciones: %d" % [
				current_unit_data.name,
				current_unit_data.base_file,
				current_unit_data.animations.size()
			]
			unit_info_label.text = info_text
		
		# Emitir señal para que main.gd procese la unidad
		emit_signal("unit_selected", current_unit_data)
		
		add_export_log("📁 Unidad seleccionada: %s" % current_unit_data.name)

# NUEVA FUNCIÓN: Mostrar archivos FBX de la unidad seleccionada
func display_unit_fbx_files(unit_data: Dictionary):
	current_unit_data = unit_data
	
	# Llenar lista de FBX base
	if base_fbx_option:
		base_fbx_option.clear()
		base_fbx_option.add_item("-- Seleccionar modelo base --")
		
		# Añadir archivo base sugerido primero
		if unit_data.base_file != "":
			var base_display = "%s (sugerido)" % unit_data.base_file
			base_fbx_option.add_item(base_display)
		
		# Añadir todos los archivos FBX
		for file in unit_data.all_fbx:
			if file != unit_data.base_file:  # Evitar duplicados
				base_fbx_option.add_item(file)
		
		base_fbx_option.disabled = false
	
	# CREAR CHECKBOXES PARA ANIMACIONES
	_create_animation_checkboxes(unit_data.animations)
	
	add_export_log("✅ Archivos FBX cargados para %s" % unit_data.name)

# NUEVA FUNCIÓN: Crear checkboxes para animaciones
func _create_animation_checkboxes(animations: Array):
	print("📋 CREANDO CHECKBOXES PARA ANIMACIONES")
	
	# Limpiar checkboxes anteriores
	_clear_animation_checkboxes()
	
	if animations.is_empty():
		var no_anims_label = Label.new()
		no_anims_label.text = "No se encontraron animaciones en esta unidad"
		no_anims_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		animations_container.add_child(no_anims_label)
		return
	
	# Crear checkbox para cada animación
	for anim_file in animations:
		var checkbox = CheckBox.new()
		checkbox.text = anim_file
		checkbox.toggled.connect(_on_animation_checkbox_toggled.bind(anim_file))
		
		animations_container.add_child(checkbox)
		animation_checkboxes.append(checkbox)
	
	print("✅ Creados %d checkboxes para animaciones" % animations.size())
	add_export_log("📋 %d animaciones disponibles para selección" % animations.size())

# NUEVA FUNCIÓN: Limpiar checkboxes de animaciones
func _clear_animation_checkboxes():
	# Eliminar todos los hijos del contenedor de animaciones
	for child in animations_container.get_children():
		child.queue_free()
	
	animation_checkboxes.clear()

# NUEVA FUNCIÓN: Manejar toggle de checkbox de animación
func _on_animation_checkbox_toggled(animation_file: String, pressed: bool):
	if pressed:
		if not animation_file in selected_animations:
			selected_animations.append(animation_file)
	else:
		selected_animations.erase(animation_file)
	
	# Habilitar/deshabilitar botón de renderizado
	if render_button:
		render_button.disabled = selected_animations.is_empty()
	
	# Emitir señal con animaciones seleccionadas
	if not selected_animations.is_empty():
		emit_signal("animations_selected", selected_animations)
		add_export_log("🎬 Animaciones seleccionadas: %s" % str(selected_animations))

func _on_browse_folder():
	if folder_dialog:
		folder_dialog.popup_centered(Vector2(800, 600))

func _on_folder_selected(path: String):
	# Esta función se mantiene para compatibilidad con exploración manual
	emit_signal("folder_selected", path)

# Función legacy mantenida para compatibilidad
func display_fbx_list(fbx_files: Array):
	available_fbx_files = fbx_files
	add_export_log("Encontrados %d archivos FBX" % fbx_files.size())

func _on_base_fbx_selected(index: int):
	if index > 0:
		var filename = base_fbx_option.get_item_text(index)
		# Limpiar "(sugerido)" del nombre si existe
		filename = filename.replace(" (sugerido)", "")
		emit_signal("base_fbx_selected", filename)
		add_export_log("Modelo base seleccionado: " + filename)

func enable_animation_selection():
	# Esta función se mantiene para compatibilidad
	if preview_button:
		preview_button.disabled = false
	add_export_log("Modelo base cargado correctamente")

# Función para habilitar modo preview
func enable_preview_mode():
	print("🎬 UI Preview Mode Activado")
	preview_mode_active = true
	
	# Actualizar status del preview usando búsqueda más robusta
	var status_label = _find_node_by_name(self, "PreviewStatus")
	if status_label:
		status_label.text = "✅ Preview Activo - Modelo cargado"
		status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	# Mostrar controles de ayuda
	var controls_help = _find_node_by_name(self, "ControlsHelp")
	if controls_help:
		controls_help.visible = true
	
	# Habilitar controles de preview si existen
	if preview_button:
		preview_button.disabled = false
		preview_button.text = "Preview Activo ✓"
		preview_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	# Habilitar renderizado
	if render_button:
		render_button.disabled = selected_animations.is_empty()
	
	# Mostrar mensaje en el log
	add_export_log("[color=green]✅ Preview activado - Modelo visible en viewport[/color]")
	add_export_log("🧭 Usa los controles de orientación para ajustar el norte del modelo")
	add_export_log("Controles: Click + Arrastrar para rotar vista")

# Función auxiliar para buscar nodos por nombre recursivamente
func _find_node_by_name(parent: Node, node_name: String) -> Node:
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

# Función de configuración de cámara que incluye north_offset
func _on_camera_setting_changed(_value = null):
	var settings = {
		"camera_angle": camera_angle_slider.value if camera_angle_slider else 45.0,
		"camera_height": camera_height_slider.value if camera_height_slider else 10.0,
		"camera_distance": camera_distance_slider.value if camera_distance_slider else 15.0,
		"directions": int(directions_spinbox.value) if directions_spinbox else 16,
		"sprite_size": int(sprite_size_spinbox.value) if sprite_size_spinbox else 256,
		"fps": int(fps_spinbox.value) if fps_spinbox else 30,
		"pixelize": pixelize_checkbox.button_pressed if pixelize_checkbox else true,
		# VERIFICAR que esta línea esté presente:
		"north_offset": north_offset_slider.value if north_offset_slider else 0.0
	}
	emit_signal("render_settings_changed", settings)
	print("📡 Configuración enviada con north_offset: %.0f°" % settings.north_offset)

func _connect_north_slider_signal():
	"""Conectar señal del slider de orientación norte correctamente"""
	if north_offset_slider:
		# Desconectar si ya estaba conectada para evitar duplicados
		if north_offset_slider.value_changed.is_connected(_on_north_offset_changed):
			north_offset_slider.value_changed.disconnect(_on_north_offset_changed)
		
		# Reconectar
		north_offset_slider.value_changed.connect(_on_north_offset_changed)
		print("✅ Señal de north_offset_slider conectada correctamente")

func _on_north_offset_changed(value: float):
	print("🧭 Slider norte cambiado: %.0f°" % value)
	
	if north_offset_label:
		north_offset_label.text = "%.0f°" % value
	
	# CRÍTICO: Notificar al sistema de cámara
	_on_camera_setting_changed()

func _on_north_preset_pressed(angle: float):
	print("🧭 Preset presionado: %.0f°" % angle)
	
	if north_offset_slider:
		# Cambiar valor del slider
		north_offset_slider.value = angle
		
		# IMPORTANTE: Forzar actualización del label
		if north_offset_label:
			north_offset_label.text = "%.0f°" % angle
		
		# CRÍTICO: Notificar manualmente al sistema de cámara
		_on_camera_setting_changed()
		
		add_export_log("🧭 Orientación aplicada: %.0f°" % angle)
		print("✅ Preset aplicado y notificado al sistema")

func _on_preview_pressed():
	if preview_mode_active:
		add_export_log("Preview ya está activo")
	else:
		add_export_log("Esperando que se carguen los modelos para activar preview...")

func _on_render_pressed():
	emit_signal("render_requested")

func show_loading_message(message: String):
	add_export_log("[color=yellow]⏳ %s[/color]" % message)

func hide_loading_message():
	pass

func show_progress_dialog():
	if progress_dialog:
		progress_dialog.popup_centered()

func update_progress(progress: float):
	if progress_dialog:
		var progress_bar = progress_dialog.get_node_or_null("VBoxContainer/ProgressBar")
		if progress_bar:
			progress_bar.value = progress * 100.0

func show_error(error: String):
	add_export_log("[color=red]❌ Error: %s[/color]" % error)
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = error
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.visibility_changed.connect(error_dialog.queue_free)

func add_export_log(message: String):
	var timestamp = Time.get_time_string_from_system()
	if export_log:
		export_log.append_text("[%s] %s\n" % [timestamp, message])

func is_preview_active() -> bool:
	return preview_mode_active

# === FUNCIONES PARA SHADER AVANZADO - VERSIÓN CORREGIDA ===

func _validate_shader_system() -> bool:
	"""Validar que el sistema de shader esté correctamente configurado"""
	var validation_errors = []
	
	# 1. Verificar que existe el shader avanzado
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if not ResourceLoader.exists(shader_path):
		validation_errors.append("Shader no encontrado en: " + shader_path)
	
	# 2. Verificar que existe el script del panel
	var panel_script_path = "res://scripts/ui/advanced_shader_panel.gd"
	if not ResourceLoader.exists(panel_script_path):
		validation_errors.append("Script del panel no encontrado en: " + panel_script_path)
	
	# 3. Verificar controles UI básicos
	if not basic_pixelize_checkbox:
		validation_errors.append("basic_pixelize_checkbox no está inicializado")
	if not show_shader_panel_button:
		validation_errors.append("show_shader_panel_button no está inicializado")
	
	if validation_errors.size() > 0:
		print("❌ ERRORES DE VALIDACIÓN DEL SISTEMA DE SHADER:")
		for error in validation_errors:
			print("  - " + error)
		
		var error_message = "Sistema de shader no configurado correctamente:\n"
		for error in validation_errors:
			error_message += "• " + error + "\n"
		
		show_error(error_message)
		return false
	
	print("✅ Sistema de shader validado correctamente")
	return true

func _create_advanced_shader_panel():
	"""Crear el panel avanzado de shader como ventana modal"""
	
	# Crear ventana de configuración avanzada
	var advanced_window = Window.new()  # CORREGIDO: Window en lugar de AcceptDialog
	advanced_window.title = "Configuración Avanzada de Shader"
	advanced_window.size = Vector2i(900, 900)  # CORREGIDO: Tamaño más razonable
	advanced_window.unresizable = false
	advanced_window.transient = true
	advanced_window.exclusive = false
	add_child(advanced_window)
	
	# Container principal con botones
	var main_vbox = VBoxContainer.new()
	advanced_window.add_child(main_vbox)
	
	# Crear el panel avanzado dentro de la ventana
	advanced_shader_panel = preload("res://scripts/ui/advanced_shader_panel.gd").new()
	advanced_shader_panel.name = "AdvancedShaderPanel"
	advanced_shader_panel.size = Vector2i(600, 600)
	main_vbox.add_child(advanced_shader_panel)
	
	# Botones de acción
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_FILL
	main_vbox.add_child(button_container)
	
	var apply_button = Button.new()
	apply_button.text = "Aplicar y Cerrar"
	apply_button.pressed.connect(func(): _on_advanced_shader_applied(); advanced_window.hide())
	button_container.add_child(apply_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(func(): advanced_window.hide())
	button_container.add_child(cancel_button)
	
	# Conectar señales del panel avanzado
	advanced_shader_panel.shader_settings_changed.connect(_on_advanced_shader_settings_changed)
	advanced_shader_panel.reset_to_defaults_requested.connect(_on_shader_reset_requested)
	
	# Configurar cierre con X
	advanced_window.close_requested.connect(func(): advanced_window.hide())
	
	print("✅ Panel avanzado de shader creado")
	return advanced_window

func _on_show_advanced_shader_panel():
	"""Mostrar el panel avanzado de shader con validación"""
	print("🎨 Mostrando panel avanzado de shader...")
	
	if not _validate_shader_system():
		return
	
	if not advanced_shader_panel:
		var advanced_window = _create_advanced_shader_panel()
		if not current_shader_settings.is_empty():
			advanced_shader_panel.apply_settings(current_shader_settings)
		advanced_window.popup_centered()
	else:
		var current_node = advanced_shader_panel.get_parent()
		while current_node != null and not current_node is Window:
			current_node = current_node.get_parent()
		
		if current_node and current_node is Window:
			current_node.popup_centered()
		else:
			print("⚠️ No se pudo encontrar la ventana padre")

func _on_advanced_shader_settings_changed(settings: Dictionary):
	"""Manejar cambios en configuración avanzada de shader"""
	current_shader_settings = settings.duplicate()
	
	if basic_pixelize_checkbox and settings.has("pixelize_enabled"):
		basic_pixelize_checkbox.button_pressed = settings.pixelize_enabled
	
	render_settings_changed.emit(_get_enhanced_render_settings())

func _on_basic_pixelize_toggled(enabled: bool):
	"""Manejar cambio en checkbox básico de pixelización"""
	if not current_shader_settings.is_empty():
		current_shader_settings.pixelize_enabled = enabled
		if advanced_shader_panel:
			var temp_settings = current_shader_settings.duplicate()
			advanced_shader_panel.apply_settings(temp_settings)
	
	render_settings_changed.emit(_get_enhanced_render_settings())

func _on_advanced_shader_applied():
	"""Aplicar configuración avanzada y cerrar panel"""
	if advanced_shader_panel:
		current_shader_settings = advanced_shader_panel.get_current_settings()
		print("✅ Configuración avanzada aplicada:")
		print("  Configuraciones guardadas: %d" % current_shader_settings.size())
		render_settings_changed.emit(_get_enhanced_render_settings())

func _on_shader_reset_requested():
	"""Resetear configuración de shader a valores por defecto"""
	print("🔄 Reseteando configuración de shader...")
	current_shader_settings.clear()
	
	if basic_pixelize_checkbox:
		basic_pixelize_checkbox.button_pressed = true
	
	render_settings_changed.emit(_get_enhanced_render_settings())

func _get_enhanced_render_settings() -> Dictionary:
	"""Obtener configuración de renderizado mejorada con shader avanzado"""
	var settings = {}
	
	# Configuraciones básicas existentes (mantener compatibilidad)
	if directions_spinbox:
		settings["directions"] = int(directions_spinbox.value)
	if sprite_size_spinbox:
		settings["sprite_size"] = int(sprite_size_spinbox.value)
	if camera_angle_slider:
		settings["camera_angle"] = camera_angle_slider.value
	if camera_height_slider:
		settings["camera_height"] = camera_height_slider.value
	if camera_distance_slider:
		settings["camera_distance"] = camera_distance_slider.value
	if fps_spinbox:
		settings["fps"] = int(fps_spinbox.value)
	if north_offset_slider:
		settings["north_offset"] = north_offset_slider.value
	
	# NUEVA FUNCIONALIDAD: Configuración básica de pixelización
	if basic_pixelize_checkbox:
		settings["pixelize"] = basic_pixelize_checkbox.button_pressed
	else:
		settings["pixelize"] = true  # Default
	
	# NUEVA FUNCIONALIDAD: Configuración avanzada de shader
	if not current_shader_settings.is_empty():
		# Incluir toda la configuración avanzada
		settings["advanced_shader"] = current_shader_settings.duplicate()
		settings["use_advanced_shader"] = true
		
		# Sobrescribir pixelización básica con la avanzada
		settings["pixelize"] = current_shader_settings.get("pixelize_enabled", true)
	else:
		settings["use_advanced_shader"] = false
		settings["advanced_shader"] = {}
	
	return settings

func apply_advanced_shader_to_material(material: Material, settings: Dictionary):
	"""Aplicar configuración avanzada de shader a un material"""
	
	if not material is ShaderMaterial:
		print("⚠️ Material no es ShaderMaterial, no se puede aplicar configuración avanzada")
		return
	
	var shader_material = material as ShaderMaterial
	
	# Cargar shader avanzado si no está cargado
	if not shader_material.shader:
		var advanced_shader = load("res://resources/shaders/pixelize_advanced.gdshader")
		if advanced_shader:
			shader_material.shader = advanced_shader
			print("✅ Shader avanzado cargado en material")
		else:
			print("❌ Error: No se pudo cargar shader avanzado")
			return
	
	# Aplicar todos los parámetros del shader
	var shader_settings = settings.get("advanced_shader", {})
	
	if not shader_settings.is_empty():
		# Parámetros de pixelización
		shader_material.set_shader_parameter("pixel_size", shader_settings.get("pixel_size", 4.0))
		
		# Parámetros de reducción de colores
		shader_material.set_shader_parameter("reduce_colors", shader_settings.get("reduce_colors", false))
		shader_material.set_shader_parameter("color_levels", shader_settings.get("color_levels", 16))
		
		# Parámetros de dithering
		shader_material.set_shader_parameter("enable_dithering", shader_settings.get("enable_dithering", false))
		shader_material.set_shader_parameter("dither_strength", shader_settings.get("dither_strength", 0.1))
		
		# Parámetros de borde (NUEVOS)
		shader_material.set_shader_parameter("enable_outline", shader_settings.get("enable_outline", false))
		shader_material.set_shader_parameter("outline_thickness", shader_settings.get("outline_thickness", 1.0))
		shader_material.set_shader_parameter("outline_color", shader_settings.get("outline_color", Color.BLACK))
		shader_material.set_shader_parameter("outline_pixelated", shader_settings.get("outline_pixelated", true))
		shader_material.set_shader_parameter("outline_smooth", shader_settings.get("outline_smooth", 0.0))
		
		# Efectos avanzados
		shader_material.set_shader_parameter("contrast_boost", shader_settings.get("contrast_boost", 1.0))
		shader_material.set_shader_parameter("saturation_mult", shader_settings.get("saturation_mult", 1.0))
		shader_material.set_shader_parameter("color_tint", shader_settings.get("color_tint", Color.WHITE))
		shader_material.set_shader_parameter("apply_gamma_correction", shader_settings.get("apply_gamma_correction", false))
		shader_material.set_shader_parameter("gamma_value", shader_settings.get("gamma_value", 1.0))
		
		print("✅ Configuración avanzada aplicada al material")
	else:
		print("⚠️ No hay configuración avanzada disponible")

func get_current_shader_configuration() -> Dictionary:
	"""Obtener configuración actual de shader para uso externo"""
	return current_shader_settings.duplicate()

func has_advanced_shader_settings() -> bool:
	"""Verificar si hay configuración avanzada de shader"""
	return not current_shader_settings.is_empty()
