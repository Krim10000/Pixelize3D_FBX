# scripts/ui/ui_controller.gd
extends Control

# Input: Interacciones del usuario con archivos FBX importados en Godot
# Output: Señales y configuración para el proceso de renderizado

signal folder_selected(path: String)
signal base_fbx_selected(filename: String)
signal animations_selected(filenames: Array)
signal render_settings_changed(settings: Dictionary)
signal render_requested()
signal export_requested(settings: Dictionary)

# Verificación segura de nodos
@onready var main_panel := get_node_or_null("MainPanel")
@onready var progress_dialog := get_node_or_null("ProgressDialog")


# Referencias a controles UI
var instructions_panel: PanelContainer
var folder_list: ItemList
var fbx_info_panel: VBoxContainer
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
var refresh_button: Button
var export_log: RichTextLabel

# Configuración
const FBX_ASSETS_PATH = "res://assets/fbx/"
var current_folder_path: String = ""
var available_fbx_files: Array = []
var selected_animations: Array = []

func _ready():
	_create_ui()
	_connect_ui_signals()
	_apply_theme()
	_ensure_fbx_directory()
	if main_panel == null:
		push_error("[UIController] No se encontró el nodo 'MainPanel'. Verifica la jerarquía de nodos.")
	if progress_dialog == null:
		push_error("[UIController] No se encontró el nodo 'ProgressDialog'.")

func _ensure_fbx_directory():
	# Crear directorio si no existe
	DirAccess.make_dir_recursive_absolute(FBX_ASSETS_PATH)

func _create_ui():
	# Panel principal
	main_panel = PanelContainer.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_panel)
	
	var main_hbox = HSplitContainer.new()
	main_hbox.split_offset = 400
	main_panel.add_child(main_hbox)
	
	# Panel izquierdo - Instrucciones y selección
	var left_panel = _create_left_panel()
	main_hbox.add_child(left_panel)
	
	# Panel derecho - Configuración y preview
	var right_panel = _create_right_panel()
	main_hbox.add_child(right_panel)
	
	# Diálogos
	_create_dialogs()

func _create_left_panel() -> Control:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	
	# Título
	var title = Label.new()
	title.text = "Pixelize3D FBX - Generador de Sprites"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Panel de instrucciones
	instructions_panel = _create_instructions_panel()
	vbox.add_child(instructions_panel)
	
	vbox.add_child(HSeparator.new())
	
	# Sección de carpetas
	var folder_section = _create_section("📁 Paso 1: Seleccionar Unidad")
	vbox.add_child(folder_section)
	
	# Botón refrescar
	var refresh_container = HBoxContainer.new()
	folder_section.add_child(refresh_container)
	
	refresh_button = Button.new()
	refresh_button.text = "🔄 Refrescar Lista"
	refresh_button.custom_minimum_size.x = 150
	refresh_container.add_child(refresh_button)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_container.add_child(spacer)
	
	# Lista de carpetas de unidades
	folder_list = ItemList.new()
	folder_list.custom_minimum_size.y = 120
	folder_list.select_mode = ItemList.SELECT_SINGLE
	folder_section.add_child(folder_list)
	
	# Info de la carpeta seleccionada
	fbx_info_panel = _create_fbx_info_panel()
	vbox.add_child(fbx_info_panel)
	
	return vbox

func _create_instructions_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 200
	
	var scroll = ScrollContainer.new()
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "💡 Instrucciones de Uso"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var instructions = RichTextLabel.new()
	instructions.custom_minimum_size.y = 160
	instructions.bbcode_enabled = true
	instructions.text = """[b]Configuración inicial:[/b]

[b]1.[/b] Crea la estructura de carpetas en [color=cyan]res://assets/fbx/[/color]
[b]2.[/b] Organiza tus archivos FBX por unidad:
   [font_size=12][color=gray]res://assets/fbx/soldier/
   ├── soldier_base.fbx      # Modelo con meshes
   ├── soldier_idle.fbx      # Animación idle
   ├── soldier_walk.fbx      # Animación caminar
   └── soldier_attack.fbx    # Animación atacar[/color][/font_size]

[b]3.[/b] Importa los archivos FBX en Godot (automático)
[b]4.[/b] Haz clic en [color=yellow]"🔄 Refrescar Lista"[/color] para detectar las carpetas
[b]5.[/b] Selecciona una unidad y configura el renderizado

[color=orange][b]Importante:[/b] El archivo "_base.fbx" debe contener los meshes.
Los demás archivos deben contener solo las animaciones.[/color]"""
	vbox.add_child(instructions)
	
	return panel

func _create_fbx_info_panel() -> VBoxContainer:
	var section = _create_section("📋 Paso 2: Configurar Archivos FBX")
	
	# Modelo base
	var base_label = Label.new()
	base_label.text = "Modelo Base:"
	section.add_child(base_label)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Seleccionar modelo base --")
	base_fbx_option.disabled = true
	section.add_child(base_fbx_option)
	
	# Estado del modelo base
	var base_status = Label.new()
	base_status.name = "BaseStatus"
	base_status.text = "❌ No seleccionado"
	base_status.add_theme_color_override("font_color", Color.RED)
	section.add_child(base_status)
	
	section.add_child(HSeparator.new())
	
	# Animaciones
	var anim_label = Label.new()
	anim_label.text = "Animaciones:"
	section.add_child(anim_label)
	
	animations_list = ItemList.new()
	animations_list.custom_minimum_size.y = 120
	animations_list.select_mode = ItemList.SELECT_MULTI
	section.add_child(animations_list)
	# Inicializar como deshabilitado
	_set_itemlist_enabled(animations_list, false)
	
	# Estado de las animaciones
	var anim_status = Label.new()
	anim_status.name = "AnimStatus"
	anim_status.text = "❌ Sin animaciones seleccionadas"
	anim_status.add_theme_color_override("font_color", Color.RED)
	section.add_child(anim_status)
	
	return section

func _create_right_panel() -> Control:
	var scroll = ScrollContainer.new()
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	# Sección de configuración de renderizado
	var render_section = _create_section("⚙️ Paso 3: Configuración de Renderizado")
	vbox.add_child(render_section)
	
	# Direcciones
	var dir_container = HBoxContainer.new()
	render_section.add_child(dir_container)
	
	dir_container.add_child(Label.new())
	dir_container.get_child(0).text = "Direcciones:"
	dir_container.get_child(0).custom_minimum_size.x = 100
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 4
	directions_spinbox.max_value = 32
	directions_spinbox.step = 4
	directions_spinbox.value = 16
	dir_container.add_child(directions_spinbox)
	
	# Tamaño de sprite
	var size_container = HBoxContainer.new()
	render_section.add_child(size_container)
	
	size_container.add_child(Label.new())
	size_container.get_child(0).text = "Tamaño sprite:"
	size_container.get_child(0).custom_minimum_size.x = 100
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 64
	sprite_size_spinbox.max_value = 1024
	sprite_size_spinbox.step = 32
	sprite_size_spinbox.value = 256
	size_container.add_child(sprite_size_spinbox)
	
	# FPS
	var fps_container = HBoxContainer.new()
	render_section.add_child(fps_container)
	
	fps_container.add_child(Label.new())
	fps_container.get_child(0).text = "FPS:"
	fps_container.get_child(0).custom_minimum_size.x = 100
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 1
	fps_spinbox.max_value = 60
	fps_spinbox.value = 12
	fps_container.add_child(fps_spinbox)
	
	# Sección de cámara
	var camera_section = _create_section("📷 Configuración de Cámara")
	vbox.add_child(camera_section)
	
	# Ángulo
	camera_section.add_child(_create_slider_container("Ángulo:", 15, 75, 45))
	camera_angle_slider = camera_section.get_child(-1).get_child(1)
	
	# Altura
	camera_section.add_child(_create_slider_container("Altura:", 1, 50, 10))
	camera_height_slider = camera_section.get_child(-1).get_child(1)
	
	# Distancia
	camera_section.add_child(_create_slider_container("Distancia:", 5, 100, 15))
	camera_distance_slider = camera_section.get_child(-1).get_child(1)
	
	# Opciones adicionales
	pixelize_checkbox = CheckBox.new()
	pixelize_checkbox.text = "Aplicar pixelización"
	pixelize_checkbox.button_pressed = true
	camera_section.add_child(pixelize_checkbox)
	
	# Botones de acción
	var action_section = _create_section("🚀 Paso 4: Generar Sprites")
	vbox.add_child(action_section)
	
	var button_container = HBoxContainer.new()
	action_section.add_child(button_container)
	
	preview_button = Button.new()
	preview_button.text = "👁️ Preview"
	preview_button.disabled = true
	button_container.add_child(preview_button)
	
	render_button = Button.new()
	render_button.text = "🎯 Renderizar"
	render_button.disabled = true
	button_container.add_child(render_button)
	
	# Log de exportación
	var log_section = _create_section("📄 Log de Progreso")
	vbox.add_child(log_section)
	
	export_log = RichTextLabel.new()
	export_log.custom_minimum_size.y = 120
	export_log.scroll_following = true
	export_log.bbcode_enabled = true
	log_section.add_child(export_log)
	
	return scroll

func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	section.add_child(label)
	
	var separator = HSeparator.new()
	section.add_child(separator)
	
	return section

func _create_slider_container(label_text: String, min_val: float, max_val: float, default: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default
	slider.step = 0.1
	slider.custom_minimum_size.x = 150
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(default)
	value_label.custom_minimum_size.x = 40
	container.add_child(value_label)
	
	slider.value_changed.connect(func(val): value_label.text = "%.1f" % val)
	
	return container

func _create_dialogs():
	# Diálogo de progreso
	progress_dialog = AcceptDialog.new()
	progress_dialog.title = "Renderizando..."
	progress_dialog.dialog_hide_on_ok = false
	
	var progress_vbox = VBoxContainer.new()
	progress_dialog.add_child(progress_vbox)
	
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Iniciando renderizado..."
	progress_vbox.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size.x = 300
	progress_vbox.add_child(progress_bar)
	
	add_child(progress_dialog)

func _connect_ui_signals():
	# Conectar señales de UI
	refresh_button.pressed.connect(_on_refresh_pressed)
	folder_list.item_selected.connect(_on_folder_selected)
	base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	animations_list.multi_selected.connect(_on_animation_selected)
	preview_button.pressed.connect(_on_preview_pressed)
	render_button.pressed.connect(_on_render_pressed)
	
	# Conectar sliders
	for slider in [camera_angle_slider, camera_height_slider, camera_distance_slider]:
		if slider:
			slider.value_changed.connect(_on_camera_setting_changed)

func _apply_theme():
	# Aplicar colores al panel de instrucciones
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_color = Color(0.3, 0.5, 0.7, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	instructions_panel.add_theme_stylebox_override("panel", style)

# Función helper para habilitar/deshabilitar ItemList
func _set_itemlist_enabled(item_list: ItemList, enabled: bool):
	if not item_list:
		return
	
	if enabled:
		item_list.mouse_filter = Control.MOUSE_FILTER_PASS
		item_list.modulate = Color.WHITE
	else:
		item_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_list.modulate = Color(1, 1, 1, 0.5)

func initialize():
	add_export_log("[color=green]✅ Pixelize3D FBX iniciado[/color]")
	add_export_log("[color=yellow]💡 Configura tus archivos FBX en: res://assets/fbx/[/color]")
	_refresh_folder_list()
	
	# Asegurar que los controles estén en el estado inicial correcto
	_set_itemlist_enabled(animations_list, false)

func _on_refresh_pressed():
	add_export_log("🔄 Refrescando lista de carpetas...")
	_refresh_folder_list()

func _refresh_folder_list():
	folder_list.clear()
	
	var dir = DirAccess.open(FBX_ASSETS_PATH)
	if not dir:
		add_export_log("[color=red]❌ No se pudo acceder a: " + FBX_ASSETS_PATH + "[/color]")
		return
	
	var folders = []
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			# Verificar que la carpeta contiene archivos FBX
			var fbx_count = _count_fbx_files(FBX_ASSETS_PATH.path_join(folder_name))
			if fbx_count > 0:
				folders.append({
					"name": folder_name,
					"count": fbx_count
				})
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Añadir carpetas a la lista
	for folder_data in folders:
		var display_name = "%s (%d FBX)" % [folder_data.name, folder_data.count]
		folder_list.add_item(display_name)
		folder_list.set_item_metadata(folder_list.get_item_count() - 1, folder_data.name)
	
	if folders.is_empty():
		add_export_log("[color=orange]⚠️ No se encontraron carpetas con archivos FBX[/color]")
		folder_list.add_item("-- No hay unidades disponibles --")
		folder_list.set_item_disabled(0, true)
	else:
		add_export_log("[color=green]✅ Encontradas %d unidades[/color]" % folders.size())

func _count_fbx_files(path: String) -> int:
	var dir = DirAccess.open(path)
	if not dir:
		return 0
	
	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".fbx") or file_name.ends_with(".FBX"):
			# Verificar que es realmente un archivo FBX importado
			var full_path = path.path_join(file_name)
			if _validate_fbx_import(full_path):
				count += 1
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return count

func _validate_fbx_import(fbx_path: String) -> bool:
	# Verificar que el archivo FBX está correctamente importado
	var resource = load(fbx_path)
	if resource and resource is PackedScene:
		return true
	return false

func _on_folder_selected(index: int):
	if folder_list.get_item_metadata(index) == null:
		return
	
	var folder_name = folder_list.get_item_metadata(index)
	current_folder_path = FBX_ASSETS_PATH.path_join(folder_name)
	
	add_export_log("[color=cyan]📁 Carpeta seleccionada: " + folder_name + "[/color]")
	
	# Escanear archivos FBX en la carpeta
	var fbx_files = _scan_fbx_files(current_folder_path)
	_populate_fbx_lists(fbx_files)
	
	emit_signal("folder_selected", current_folder_path)

func _scan_fbx_files(folder_path: String) -> Array:
	var files = []
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if (file_name.ends_with(".fbx") or file_name.ends_with(".FBX")) and _validate_fbx_import(folder_path.path_join(file_name)):
				files.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

func _populate_fbx_lists(fbx_files: Array):
	available_fbx_files = fbx_files
	
	# Limpiar listas
	base_fbx_option.clear()
	base_fbx_option.add_item("-- Seleccionar modelo base --")
	animations_list.clear()
	
	# Separar archivos base y animaciones
	var base_files = []
	var anim_files = []
	
	for file in fbx_files:
		var lower_name = file.to_lower()
		if "base" in lower_name or "mesh" in lower_name or lower_name.ends_with("_base.fbx"):
			base_files.append(file)
		else:
			anim_files.append(file)
	
	# Llenar lista de archivos base
	for file in base_files:
		base_fbx_option.add_item(file)
	
	# Si no hay archivos base obvios, añadir todos
	if base_files.is_empty():
		for file in fbx_files:
			base_fbx_option.add_item(file)
	
	# Llenar lista de animaciones
	for file in anim_files:
		animations_list.add_item(file)
	
	# Si no hay archivos de animación obvios, añadir todos menos el base
	if anim_files.is_empty():
		for file in fbx_files:
			animations_list.add_item(file)
	
	# Activar controles
	base_fbx_option.disabled = fbx_files.is_empty()
	_set_itemlist_enabled(animations_list, not fbx_files.is_empty())
	
	# Actualizar estado
	_update_fbx_status()
	
	add_export_log("[color=green]✅ Encontrados %d archivos FBX[/color]" % fbx_files.size())

func _update_fbx_status():
	var base_status = fbx_info_panel.get_node("BaseStatus")
	var anim_status = fbx_info_panel.get_node("AnimStatus")
	
	# Estado del modelo base
	if base_fbx_option.selected > 0:
		base_status.text = "✅ Modelo base seleccionado"
		base_status.add_theme_color_override("font_color", Color.GREEN)
	else:
		base_status.text = "❌ No seleccionado"
		base_status.add_theme_color_override("font_color", Color.RED)
	
	# Estado de las animaciones
	var selected_count = 0
	for i in range(animations_list.get_item_count()):
		if animations_list.is_selected(i):
			selected_count += 1
	
	if selected_count > 0:
		anim_status.text = "✅ %d animaciones seleccionadas" % selected_count
		anim_status.add_theme_color_override("font_color", Color.GREEN)
	else:
		anim_status.text = "❌ Sin animaciones seleccionadas"
		anim_status.add_theme_color_override("font_color", Color.RED)
	
	# Activar botones si todo está listo
	var ready_to_render = base_fbx_option.selected > 0 and selected_count > 0
	preview_button.disabled = not ready_to_render
	render_button.disabled = not ready_to_render

func _on_base_fbx_selected(index: int):
	if index > 0:
		var filename = base_fbx_option.get_item_text(index)
		emit_signal("base_fbx_selected", filename)
		add_export_log("[color=green]✅ Modelo base: " + filename + "[/color]")
	
	_update_fbx_status()

func _on_animation_selected(index: int, selected: bool):
	selected_animations.clear()
	
	for i in range(animations_list.get_item_count()):
		if animations_list.is_selected(i):
			selected_animations.append(animations_list.get_item_text(i))
	
	if not selected_animations.is_empty():
		emit_signal("animations_selected", selected_animations)
		add_export_log("[color=green]✅ Seleccionadas %d animaciones[/color]" % selected_animations.size())
	
	_update_fbx_status()

func _on_camera_setting_changed(value: float):
	var settings = {
		"camera_angle": camera_angle_slider.value,
		"camera_height": camera_height_slider.value,
		"camera_distance": camera_distance_slider.value,
		"directions": int(directions_spinbox.value),
		"sprite_size": int(sprite_size_spinbox.value),
		"fps": int(fps_spinbox.value),
		"pixelize": pixelize_checkbox.button_pressed
	}
	emit_signal("render_settings_changed", settings)

func _on_preview_pressed():
	add_export_log("[color=yellow]👁️ Activando preview...[/color]")

func _on_render_pressed():
	add_export_log("[color=cyan]🎯 Iniciando renderizado...[/color]")
	emit_signal("render_requested")

func show_progress_dialog():
	progress_dialog.popup_centered()

func update_progress(progress: float, message: String = ""):
	var progress_bar = progress_dialog.get_node("ProgressBar")
	var progress_label = progress_dialog.get_node("ProgressLabel")
	
	if progress_bar:
		progress_bar.value = progress * 100.0
	
	if progress_label and message != "":
		progress_label.text = message

func hide_progress_dialog():
	progress_dialog.hide()

func show_error(error: String):
	add_export_log("[color=red]❌ Error: " + error + "[/color]")
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = error
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.visibility_changed.connect(error_dialog.queue_free)

func add_export_log(message: String):
	var timestamp = Time.get_time_string_from_system().substr(0, 5)
	export_log.append_text("[color=gray][%s][/color] %s\n" % [timestamp, message])

# Funciones adicionales para compatibilidad
func display_fbx_list(fbx_files: Array):
	# Esta función se mantiene por compatibilidad con main.gd
	pass

func enable_animation_selection():
	# Esta función se mantiene por compatibilidad con main.gd
	pass

func show_loading_message(message: String):
	add_export_log("[color=yellow]⏳ " + message + "[/color]")

func hide_loading_message():
	pass

func is_preview_active() -> bool:
	return preview_button.button_pressed if preview_button else false
