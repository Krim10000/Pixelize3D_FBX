# scripts/ui/ui_controller.gd
extends Control

# Input: Interacciones del usuario
# Output: Señales y configuración para el proceso de renderizado

signal folder_selected(folder_name: String)
signal base_fbx_selected(filename: String)
signal animations_selected(filenames: Array)
signal render_settings_changed(settings: Dictionary)
signal render_requested()
signal export_requested(settings: Dictionary)

# Referencias a controles UI
var main_panel: PanelContainer
var progress_dialog: AcceptDialog
var preview_viewport: SubViewport

# Controles para selección de carpetas y animaciones
var folder_list: ItemList
var folder_path_label: Label
var base_fbx_option: OptionButton
var animations_container: VBoxContainer  # Contenedor de checkboxes
var animations_checkboxes: Array = []     # Array de checkboxes
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

var current_folder_name: String = ""
var available_fbx_files: Array = []
var selected_animations: Array = []

func _ready():
	_create_ui()
	_connect_ui_signals()
	_apply_theme()

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
	
	# Diálogos
	_create_dialogs()

func _create_config_panel() -> Control:
	var panel = ScrollContainer.new()
	panel.name = "ConfigPanel"
	panel.custom_minimum_size = Vector2(400, 0)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# PASO 1: Selección de carpeta
	var folder_section = _create_section("1. Seleccionar Carpeta del Proyecto")
	vbox.add_child(folder_section)
	
	var folder_info = Label.new()
	folder_info.text = "Carpetas disponibles en res://assets/fbx/:"
	folder_info.add_theme_font_size_override("font_size", 12)
	folder_section.add_child(folder_info)
	
	folder_list = ItemList.new()
	folder_list.custom_minimum_size.y = 100
	folder_list.select_mode = ItemList.SELECT_SINGLE
	folder_section.add_child(folder_list)
	
	folder_path_label = Label.new()
	folder_path_label.text = "Ninguna carpeta seleccionada"
	folder_path_label.add_theme_font_size_override("font_size", 12)
	folder_path_label.add_theme_color_override("font_color", Color.GRAY)
	folder_section.add_child(folder_path_label)
	
	# PASO 2: Selección de FBX base
	var base_section = _create_section("2. Seleccionar Modelo Base")
	vbox.add_child(base_section)
	
	var base_info = Label.new()
	base_info.text = "Archivo FBX que contiene los meshes:"
	base_info.add_theme_font_size_override("font_size", 12)
	base_section.add_child(base_info)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Selecciona una carpeta primero --")
	base_fbx_option.disabled = true
	base_section.add_child(base_fbx_option)
	
	# PASO 3: Selección de animaciones con CHECKBOXES
	var anim_section = _create_section("3. Seleccionar Animaciones")
	vbox.add_child(anim_section)
	
	var anim_info = Label.new()
	anim_info.text = "Archivos FBX con animaciones (sin meshes):"
	anim_info.add_theme_font_size_override("font_size", 12)
	anim_section.add_child(anim_info)
	
	# Contenedor scrollable para checkboxes
	var anim_scroll = ScrollContainer.new()
	anim_scroll.custom_minimum_size.y = 150
	anim_section.add_child(anim_scroll)
	
	animations_container = VBoxContainer.new()
	anim_scroll.add_child(animations_container)
	
	var anim_count_label = Label.new()
	anim_count_label.name = "AnimCountLabel"
	anim_count_label.text = "0 animaciones seleccionadas"
	anim_count_label.add_theme_font_size_override("font_size", 12)
	anim_count_label.add_theme_color_override("font_color", Color.GRAY)
	anim_section.add_child(anim_count_label)
	
	# Botones para seleccionar/deseleccionar todo
	var anim_buttons = HBoxContainer.new()
	anim_section.add_child(anim_buttons)
	
	var select_all_btn = Button.new()
	select_all_btn.text = "Seleccionar Todo"
	select_all_btn.custom_minimum_size.x = 120
	select_all_btn.pressed.connect(_on_select_all_animations)
	anim_buttons.add_child(select_all_btn)
	
	var deselect_all_btn = Button.new()
	deselect_all_btn.text = "Deseleccionar Todo"
	deselect_all_btn.custom_minimum_size.x = 120
	deselect_all_btn.pressed.connect(_on_deselect_all_animations)
	anim_buttons.add_child(deselect_all_btn)
	
	# PASO 4: Configuración de renderizado
	var render_section = _create_section("4. Configuración de Renderizado")
	vbox.add_child(render_section)
	
	# Direcciones
	var dir_container = HBoxContainer.new()
	render_section.add_child(dir_container)
	
	var dir_label = Label.new()
	dir_label.text = "Direcciones:"
	dir_label.custom_minimum_size.x = 100
	dir_container.add_child(dir_label)
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 4
	directions_spinbox.max_value = 32
	directions_spinbox.step = 4
	directions_spinbox.value = 16
	dir_container.add_child(directions_spinbox)
	
	var dir_help = Label.new()
	dir_help.text = "(4, 8, 16, 32)"
	dir_help.add_theme_font_size_override("font_size", 10)
	dir_help.add_theme_color_override("font_color", Color.GRAY)
	dir_container.add_child(dir_help)
	
	# Tamaño de sprite
	var size_container = HBoxContainer.new()
	render_section.add_child(size_container)
	
	var size_label = Label.new()
	size_label.text = "Tamaño sprite:"
	size_label.custom_minimum_size.x = 100
	size_container.add_child(size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 32
	sprite_size_spinbox.max_value = 1024
	sprite_size_spinbox.step = 32
	sprite_size_spinbox.value = 256
	size_container.add_child(sprite_size_spinbox)
	
	var size_help = Label.new()
	size_help.text = "px"
	size_help.add_theme_font_size_override("font_size", 10)
	size_help.add_theme_color_override("font_color", Color.GRAY)
	size_container.add_child(size_help)
	
	# FPS
	var fps_container = HBoxContainer.new()
	render_section.add_child(fps_container)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_label.custom_minimum_size.x = 100
	fps_container.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 1
	fps_spinbox.max_value = 60
	fps_spinbox.value = 12
	fps_container.add_child(fps_spinbox)
	
	# PASO 5: Configuración de cámara
	var camera_section = _create_section("5. Configuración de Cámara")
	vbox.add_child(camera_section)
	
	# Ángulo
	var angle_container = VBoxContainer.new()
	camera_section.add_child(angle_container)
	
	var angle_label = Label.new()
	angle_label.name = "AngleLabel"
	angle_label.text = "Ángulo: 45°"
	angle_container.add_child(angle_label)
	
	camera_angle_slider = HSlider.new()
	camera_angle_slider.min_value = 15
	camera_angle_slider.max_value = 75
	camera_angle_slider.value = 45
	camera_angle_slider.step = 1
	camera_angle_slider.custom_minimum_size.x = 200
	camera_angle_slider.value_changed.connect(func(val): angle_label.text = "Ángulo: %.0f°" % val)
	angle_container.add_child(camera_angle_slider)
	
	# Altura
	var height_container = VBoxContainer.new()
	camera_section.add_child(height_container)
	
	var height_label = Label.new()
	height_label.name = "HeightLabel"
	height_label.text = "Altura: 10.0"
	height_container.add_child(height_label)
	
	camera_height_slider = HSlider.new()
	camera_height_slider.min_value = 1
	camera_height_slider.max_value = 50
	camera_height_slider.value = 10
	camera_height_slider.step = 0.5
	camera_height_slider.custom_minimum_size.x = 200
	camera_height_slider.value_changed.connect(func(val): height_label.text = "Altura: %.1f" % val)
	height_container.add_child(camera_height_slider)
	
	# Distancia
	var distance_container = VBoxContainer.new()
	camera_section.add_child(distance_container)
	
	var distance_label = Label.new()
	distance_label.name = "DistanceLabel"
	distance_label.text = "Distancia: 15.0"
	distance_container.add_child(distance_label)
	
	camera_distance_slider = HSlider.new()
	camera_distance_slider.min_value = 5
	camera_distance_slider.max_value = 100
	camera_distance_slider.value = 15
	camera_distance_slider.step = 0.5
	camera_distance_slider.custom_minimum_size.x = 200
	camera_distance_slider.value_changed.connect(func(val): distance_label.text = "Distancia: %.1f" % val)
	distance_container.add_child(camera_distance_slider)
	
	# Opciones adicionales
	var options_container = VBoxContainer.new()
	camera_section.add_child(options_container)
	
	pixelize_checkbox = CheckBox.new()
	pixelize_checkbox.text = "Aplicar pixelización"
	pixelize_checkbox.button_pressed = true
	options_container.add_child(pixelize_checkbox)
	
	# Separador
	vbox.add_child(HSeparator.new())
	
	# PASO 6: Botones de acción
	var action_section = _create_section("6. Acciones")
	vbox.add_child(action_section)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	action_section.add_child(button_container)
	
	preview_button = Button.new()
	preview_button.text = "Preview"
	preview_button.disabled = true
	preview_button.custom_minimum_size.x = 100
	button_container.add_child(preview_button)
	
	button_container.add_child(VSeparator.new())
	
	render_button = Button.new()
	render_button.text = "Renderizar"
	render_button.disabled = true
	render_button.custom_minimum_size.x = 100
	# Estilo más prominente para el botón principal
	render_button.add_theme_color_override("font_color", Color.WHITE)
	button_container.add_child(render_button)
	
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
	
	# Crear estructura para el viewport
	var viewport_container = SubViewportContainer.new()
	viewport_container.name = "ViewportContainer"
	viewport_container.stretch = true
	viewport_container.custom_minimum_size = Vector2(400, 400)
	vbox.add_child(viewport_container)
	
	viewport_container.material = null  # Asegurar que no haya material que interfiera
	
	preview_viewport = SubViewport.new()
	preview_viewport.name = "SubViewport"
	preview_viewport.size = Vector2i(400, 400)
	preview_viewport.transparent_bg = true
	viewport_container.add_child(preview_viewport)
	
	# Info del preview
	var info_label = Label.new()
	info_label.text = "Selecciona un modelo base para ver el preview"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(info_label)
	
	return panel

func _create_log_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "LogPanel"
	panel.custom_minimum_size.y = 150
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var label = Label.new()
	label.text = "Log de Proceso"
	header_hbox.add_child(label)
	
	# Botón para limpiar log
	var clear_button = Button.new()
	clear_button.text = "Limpiar"
	clear_button.custom_minimum_size.x = 80
	clear_button.pressed.connect(_clear_log)
	header_hbox.add_child(clear_button)
	
	export_log = RichTextLabel.new()
	export_log.custom_minimum_size.y = 120
	export_log.scroll_following = true
	export_log.bbcode_enabled = true
	export_log.fit_content = true
	vbox.add_child(export_log)
	
	return panel

func _create_section(title_text: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	
	var label = Label.new()
	label.text = title_text
	label.add_theme_font_size_override("font_size", 16)
	# Color diferente para los títulos de sección
	label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	section.add_child(label)
	
	section.add_child(HSeparator.new())
	
	return section

func _create_dialogs():
	# Diálogo de progreso
	progress_dialog = AcceptDialog.new()
	progress_dialog.name = "ProgressDialog"
	progress_dialog.title = "Renderizando Spritesheets..."
	progress_dialog.dialog_hide_on_ok = false
	progress_dialog.get_ok_button().visible = false
	
	var progress_content = VBoxContainer.new()
	progress_content.custom_minimum_size = Vector2(350, 100)
	
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Preparando renderizado..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_content.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(300, 25)
	progress_bar.show_percentage = true
	progress_content.add_child(progress_bar)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.pressed.connect(_on_cancel_rendering)
	progress_content.add_child(cancel_button)
	
	progress_dialog.add_child(progress_content)
	add_child(progress_dialog)

func _connect_ui_signals():
	# Conectar señales de UI
	if folder_list:
		folder_list.item_selected.connect(_on_folder_list_selected)
	
	if base_fbx_option:
		base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	
	if render_button:
		render_button.pressed.connect(_on_render_pressed)
	
	# Conectar sliders para emisión de señales
	var sliders = [camera_angle_slider, camera_height_slider, camera_distance_slider]
	for slider in sliders:
		if slider:
			slider.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar spinboxes
	var spinboxes = [directions_spinbox, sprite_size_spinbox, fps_spinbox]
	for spinbox in spinboxes:
		if spinbox:
			spinbox.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar checkbox
	if pixelize_checkbox:
		pixelize_checkbox.toggled.connect(_on_camera_setting_changed)

func _apply_theme():
	# Aplicar tema personalizado si es necesario
	pass

func initialize():
	add_export_log("Pixelize3D FBX iniciado")
	add_export_log("Escaneando carpetas en res://assets/fbx/...")

# FUNCIÓN: Mostrar lista de carpetas
func display_folder_list(folders: Array):
	"""Muestra la lista de carpetas disponibles"""
	folder_list.clear()
	
	for folder_name in folders:
		folder_list.add_item(folder_name)
	
	add_export_log("Encontradas %d carpetas: %s" % [folders.size(), str(folders)])

func _on_folder_list_selected(index: int):
	"""Se llama cuando el usuario selecciona una carpeta"""
	var folder_name = folder_list.get_item_text(index)
	current_folder_name = folder_name
	
	# Actualizar label de ruta
	folder_path_label.text = "Carpeta seleccionada: " + folder_name
	folder_path_label.add_theme_color_override("font_color", Color.GREEN)
	
	# Limpiar selecciones anteriores
	base_fbx_option.clear()
	base_fbx_option.add_item("-- Cargando archivos FBX... --")
	base_fbx_option.disabled = true
	
	_clear_animation_checkboxes()
	
	render_button.disabled = true
	preview_button.disabled = true
	
	# Emitir señal para que main.gd procese la carpeta
	emit_signal("folder_selected", folder_name)

func display_fbx_list(fbx_files: Array):
	"""Muestra la lista de archivos FBX en la carpeta seleccionada"""
	available_fbx_files = fbx_files
	
	# Llenar lista de FBX base
	base_fbx_option.clear()
	base_fbx_option.add_item("-- Seleccionar modelo base --")
	
	for file in fbx_files:
		base_fbx_option.add_item(file)
	
	base_fbx_option.disabled = false
	
	# Crear checkboxes para animaciones
	_create_animation_checkboxes(fbx_files)
	
	add_export_log("Archivos FBX cargados: %d" % fbx_files.size())

func _create_animation_checkboxes(fbx_files: Array):
	"""Crea checkboxes para cada archivo FBX"""
	_clear_animation_checkboxes()
	
	for file in fbx_files:
		var checkbox = CheckBox.new()
		checkbox.text = file
		checkbox.toggled.connect(_on_animation_checkbox_toggled)
		
		animations_container.add_child(checkbox)
		animations_checkboxes.append(checkbox)

func _clear_animation_checkboxes():
	"""Limpia todos los checkboxes de animaciones"""
	for checkbox in animations_checkboxes:
		if is_instance_valid(checkbox):
			checkbox.queue_free()
	
	animations_checkboxes.clear()
	
	for child in animations_container.get_children():
		child.queue_free()

func _on_animation_checkbox_toggled(_pressed: bool):
	"""Se llama cuando se cambia el estado de un checkbox"""
	_update_selected_animations()

func _update_selected_animations():
	"""Actualiza la lista de animaciones seleccionadas"""
	selected_animations.clear()
	
	for checkbox in animations_checkboxes:
		if is_instance_valid(checkbox) and checkbox.button_pressed:
			selected_animations.append(checkbox.text)
	
	# Actualizar contador
	var count_label = animations_container.get_parent().get_parent().get_node_or_null("AnimCountLabel")
	if count_label:
		count_label.text = "%d animaciones seleccionadas" % selected_animations.size()
		if selected_animations.size() > 0:
			count_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			count_label.add_theme_color_override("font_color", Color.GRAY)
	
	render_button.disabled = selected_animations.is_empty()
	
	if not selected_animations.is_empty():
		emit_signal("animations_selected", selected_animations)
		add_export_log("Animaciones: %s" % str(selected_animations))

func _on_select_all_animations():
	"""Selecciona todas las animaciones"""
	for checkbox in animations_checkboxes:
		if is_instance_valid(checkbox):
			checkbox.button_pressed = true
	
	_update_selected_animations()

func _on_deselect_all_animations():
	"""Deselecciona todas las animaciones"""
	for checkbox in animations_checkboxes:
		if is_instance_valid(checkbox):
			checkbox.button_pressed = false
	
	_update_selected_animations()

func _on_base_fbx_selected(index: int):
	if index > 0:
		var filename = base_fbx_option.get_item_text(index)
		emit_signal("base_fbx_selected", filename)
		add_export_log("Modelo base: " + filename)

func enable_animation_selection():
	"""Se llama cuando el modelo base se carga exitosamente"""
	# Los checkboxes ya están habilitados desde _create_animation_checkboxes
	preview_button.disabled = false
	add_export_log("✓ Modelo base cargado. Selecciona animaciones.")

func _on_camera_setting_changed(_value = null):
	var settings = {
		"camera_angle": camera_angle_slider.value if camera_angle_slider else 45.0,
		"camera_height": camera_height_slider.value if camera_height_slider else 10.0,
		"camera_distance": camera_distance_slider.value if camera_distance_slider else 15.0,
		"directions": int(directions_spinbox.value) if directions_spinbox else 16,
		"sprite_size": int(sprite_size_spinbox.value) if sprite_size_spinbox else 256,
		"fps": int(fps_spinbox.value) if fps_spinbox else 12,
		"pixelize": pixelize_checkbox.button_pressed if pixelize_checkbox else true
	}
	emit_signal("render_settings_changed", settings)

func _on_preview_pressed():
	add_export_log("Preview activado")

func _on_render_pressed():
	add_export_log("=== INICIANDO RENDERIZADO ===")
	emit_signal("render_requested")

func _on_cancel_rendering():
	add_export_log("Renderizado cancelado por el usuario")
	hide_progress_dialog()

func show_loading_message(message: String):
	add_export_log(message)

func hide_loading_message():
	pass

func show_progress_dialog():
	if progress_dialog:
		progress_dialog.popup_centered()

func update_progress(progress: float):
	if progress_dialog:
		var progress_bar = progress_dialog.get_node_or_null("VBoxContainer/ProgressBar")
		var progress_label = progress_dialog.get_node_or_null("VBoxContainer/ProgressLabel")
		
		if progress_bar:
			progress_bar.value = progress * 100.0
		
		if progress_label:
			progress_label.text = "Renderizando... %.1f%%" % (progress * 100.0)

func hide_progress_dialog():
	if progress_dialog:
		progress_dialog.hide()

func show_error(error: String):
	add_export_log("[color=red]✗ Error: " + error + "[/color]")
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = error
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(error_dialog.queue_free)

func add_export_log(message: String):
	var timestamp = Time.get_time_string_from_system()
	if export_log:
		export_log.append_text("[%s] %s\n" % [timestamp, message])

func _clear_log():
	if export_log:
		export_log.clear()
		add_export_log("Log limpiado")

func is_preview_active() -> bool:
	return preview_button.button_pressed if preview_button else false
