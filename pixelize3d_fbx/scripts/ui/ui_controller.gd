# scripts/ui/ui_controller.gd
extends Control

# Input: Interacciones del usuario
# Output: Señales y configuración para el proceso de renderizado

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

var folder_path_label: Label
var fbx_list: ItemList
var base_fbx_option: OptionButton
var animations_list: ItemList
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

var current_folder_path: String = ""
var available_fbx_files: Array = []
var selected_animations: Array = []
var preview_mode_active: bool = false

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
	
	# Diálogos (crear después del panel principal)
	_create_dialogs()

func _create_config_panel() -> Control:
	var panel = ScrollContainer.new()
	panel.name = "ConfigPanel"
	panel.custom_minimum_size = Vector2(400, 0)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Sección: Selección de carpeta
	var folder_section = _create_section("Carpeta del Proyecto")
	vbox.add_child(folder_section)
	
	var folder_hbox = HBoxContainer.new()
	folder_section.add_child(folder_hbox)
	
	folder_path_label = Label.new()
	folder_path_label.text = "No se ha seleccionado carpeta"
	folder_path_label.custom_minimum_size.x = 300
	folder_hbox.add_child(folder_path_label)
	
	var browse_button = Button.new()
	browse_button.text = "Examinar..."
	browse_button.pressed.connect(_on_browse_folder)
	folder_hbox.add_child(browse_button)
	
	# Sección: Selección de FBX base
	var base_section = _create_section("Modelo Base")
	vbox.add_child(base_section)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Seleccionar carpeta primero --")
	base_fbx_option.disabled = true
	base_section.add_child(base_fbx_option)
	
	# Sección: Selección de animaciones
	var anim_section = _create_section("Animaciones")
	vbox.add_child(anim_section)
	
	animations_list = ItemList.new()
	animations_list.custom_minimum_size.y = 150
	animations_list.select_mode = ItemList.SELECT_MULTI
	# ❌ INCORRECTO: ItemList no tiene propiedad 'disabled'
# animations_list.disabled = true

	# ✅ CORRECTO: Para desactivar ItemList usamos mouse_filter y focus_mode
	animations_list.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignora input del mouse
	animations_list.focus_mode = Control.FOCUS_NONE              # No puede recibir foco
	animations_list.modulate = Color(0.5, 0.5, 0.5, 0.8)       # Apariencia visual desactivada
	anim_section.add_child(animations_list)
	
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
	
	# Opciones adicionales
	pixelize_checkbox = CheckBox.new()
	pixelize_checkbox.text = "Aplicar pixelización"
	pixelize_checkbox.button_pressed = true
	camera_section.add_child(pixelize_checkbox)
	
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
	status_label.text = "Carga un modelo para ver preview"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.name = "ViewportContainer"
	viewport_container.stretch = true
	viewport_container.custom_minimum_size = Vector2(400, 400)
	vbox.add_child(viewport_container)
	
	preview_viewport = SubViewport.new()
	preview_viewport.name = "SubViewport"
	preview_viewport.size = Vector2i(400, 400)
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
	# Diálogo de selección de carpeta
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
	# Conectar señales de UI
	if base_fbx_option:
		base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	
	if animations_list:
		animations_list.multi_selected.connect(_on_animation_selected)
	
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	
	if render_button:
		render_button.pressed.connect(_on_render_pressed)
	
	# Conectar sliders
	for slider in [camera_angle_slider, camera_height_slider, camera_distance_slider]:
		if slider:
			slider.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar spinboxes
	for spinbox in [directions_spinbox, sprite_size_spinbox, fps_spinbox]:
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
	add_export_log("Selecciona una carpeta para comenzar")

func _on_browse_folder():
	if folder_dialog:
		folder_dialog.popup_centered(Vector2(800, 600))

func _on_folder_selected(path: String):
	current_folder_path = path
	if folder_path_label:
		folder_path_label.text = path.get_file()
	emit_signal("folder_selected", path)

func display_fbx_list(fbx_files: Array):
	available_fbx_files = fbx_files
	
	# Llenar lista de FBX base
	if base_fbx_option:
		base_fbx_option.clear()
		base_fbx_option.add_item("-- Seleccionar modelo base --")
		
		for file in fbx_files:
			base_fbx_option.add_item(file)
		
		base_fbx_option.disabled = false
	
	# Llenar lista de animaciones
	if animations_list:
		animations_list.clear()
		for file in fbx_files:
			animations_list.add_item(file)
	
	add_export_log("Encontrados %d archivos FBX" % fbx_files.size())

func _on_base_fbx_selected(index: int):
	if index > 0:
		var filename = base_fbx_option.get_item_text(index)
		emit_signal("base_fbx_selected", filename)
		add_export_log("Modelo base seleccionado: " + filename)

func enable_animation_selection():
	if animations_list:
		# ❌ INCORRECTO: ItemList no tiene propiedad 'disabled'
		# animations_list.disabled = false

		# ✅ CORRECTO: Para habilitar ItemList restauramos las propiedades
		animations_list.mouse_filter = Control.MOUSE_FILTER_PASS    # Permite input del mouse
		animations_list.focus_mode = Control.FOCUS_ALL              # Puede recibir foco
		animations_list.modulate = Color(1.0, 1.0, 1.0, 1.0)       # Apariencia visual normal
	if preview_button:
		preview_button.disabled = false
	add_export_log("Modelo base cargado correctamente")

func _on_animation_selected(index: int, selected: bool):
	selected_animations.clear()
	
	if animations_list:
		for i in range(animations_list.get_item_count()):
			if animations_list.is_selected(i):
				selected_animations.append(animations_list.get_item_text(i))
	
	if render_button:
		render_button.disabled = selected_animations.is_empty()
	
	if not selected_animations.is_empty():
		emit_signal("animations_selected", selected_animations)

# NUEVA FUNCIÓN para habilitar modo preview
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
		render_button.disabled = false
	
	# Mostrar mensaje en el log
	add_export_log("[color=green]✅ Preview activado - Modelo visible en viewport[/color]")
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
