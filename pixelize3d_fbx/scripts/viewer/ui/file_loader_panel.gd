# scripts/viewer/ui/file_loader_panel.gd
# Panel especializado SOLO para cargar archivos FBX
# Input: Interacciones del usuario con carga de archivos
# Output: Señales con archivos seleccionados

extends VBoxContainer

# Señales específicas de este panel
signal file_selected(file_path: String)
signal unit_selected(unit_data: Dictionary)
signal animations_selected(animations: Array)

# UI propia de este panel
var section_label: Label
var units_option: OptionButton
var unit_info_label: Label
var base_fbx_option: OptionButton
var animations_container: VBoxContainer
var load_file_button: Button

# Datos internos
var available_units: Array = []
var animation_checkboxes: Array = []
var current_unit_data: Dictionary = {}

func _ready():
	_create_ui()
	_scan_available_units()

func _create_ui():
	# Título de sección
	section_label = Label.new()
	section_label.text = "📁 Cargar Archivos FBX"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# Opción de unidades
	var units_label = Label.new()
	units_label.text = "Unidades disponibles:"
	add_child(units_label)
	
	units_option = OptionButton.new()
	units_option.add_item("-- Escaneando unidades... --")
	units_option.disabled = true
	units_option.item_selected.connect(_on_unit_selected)
	add_child(units_option)
	
	# Info de unidad
	unit_info_label = Label.new()
	unit_info_label.text = ""
	unit_info_label.add_theme_font_size_override("font_size", 10)
	unit_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	unit_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(unit_info_label)
	
	add_child(HSeparator.new())
	
	# Modelo base
	var base_label = Label.new()
	base_label.text = "Modelo base:"
	add_child(base_label)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Seleccionar unidad primero --")
	base_fbx_option.disabled = true
	base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	add_child(base_fbx_option)
	
	add_child(HSeparator.new())
	
	# Animaciones
	var anim_label = Label.new()
	anim_label.text = "Animaciones:"
	add_child(anim_label)
	
	animations_container = VBoxContainer.new()
	add_child(animations_container)
	
	add_child(HSeparator.new())
	
	# Botón de carga manual
	load_file_button = Button.new()
	load_file_button.text = "📁 Cargar FBX Manual"
	load_file_button.pressed.connect(_on_load_file_pressed)
	add_child(load_file_button)

func _scan_available_units():
	available_units.clear()
	var base_path = "res://assets/fbx/"
	
	var dir = DirAccess.open(base_path)
	if not dir:
		units_option.clear()
		units_option.add_item("-- No se encuentra assets/fbx/ --")
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var unit_data = _analyze_unit_folder(base_path + folder_name)
			if not unit_data.is_empty():
				available_units.append(unit_data)
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	_populate_units_list()

func _analyze_unit_folder(path: String) -> Dictionary:
	var unit_data = {
		"name": path.get_file(),
		"path": path,
		"base_files": [],
		"animation_files": []
	}
	
	var dir = DirAccess.open(path)
	if not dir:
		return {}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".fbx"):
			if _is_base_file(file_name):
				unit_data.base_files.append(file_name)
			else:
				unit_data.animation_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return unit_data if unit_data.base_files.size() > 0 else {}

func _is_base_file(filename: String) -> bool:
	var base_keywords = ["base", "idle", "static", "t-pose"]
	var lower_name = filename.to_lower()
	
	for keyword in base_keywords:
		if keyword in lower_name:
			return true
	
	return false

func _populate_units_list():
	units_option.clear()
	units_option.add_item("-- Seleccionar unidad --")
	
	for unit in available_units:
		units_option.add_item(unit.name)
	
	units_option.disabled = available_units.is_empty()
	
	if available_units.is_empty():
		units_option.add_item("-- No hay unidades disponibles --")

func _on_unit_selected(index: int):
	if index <= 0 or index > available_units.size():
		return
	
	current_unit_data = available_units[index - 1]
	
	# Actualizar info
	unit_info_label.text = "Carpeta: %s\nBase: %d | Animaciones: %d" % [
		current_unit_data.path,
		current_unit_data.base_files.size(),
		current_unit_data.animation_files.size()
	]
	
	emit_signal("unit_selected", current_unit_data)

func populate_unit_files(unit_data: Dictionary):
	current_unit_data = unit_data
	
	# Poblar archivos base
	base_fbx_option.clear()
	base_fbx_option.add_item("-- Seleccionar modelo base --")
	
	for base_file in unit_data.base_files:
		var display_name = base_file
		if "idle" in base_file.to_lower():
			display_name += " (recomendado)"
		base_fbx_option.add_item(display_name)
	
	base_fbx_option.disabled = false
	
	# Poblar animaciones
	_populate_animations(unit_data.animation_files)

func _populate_animations(animation_files: Array):
	# Limpiar checkboxes anteriores
	for checkbox in animation_checkboxes:
		checkbox.queue_free()
	animation_checkboxes.clear()
	
	# Crear nuevos checkboxes
	for anim_file in animation_files:
		var checkbox = CheckBox.new()
		checkbox.text = anim_file.get_basename()
		checkbox.set_meta("filename", anim_file)
		checkbox.toggled.connect(_on_animation_toggled)
		animations_container.add_child(checkbox)
		animation_checkboxes.append(checkbox)

func _on_base_fbx_selected(index: int):
	if index <= 0 or current_unit_data.is_empty():
		return
	
	var selected_file = current_unit_data.base_files[index - 1]
	var file_path = current_unit_data.path + "/" + selected_file
	emit_signal("file_selected", file_path)

func _on_animation_toggled(pressed: bool):
	var selected = get_selected_animations()
	emit_signal("animations_selected", selected)

func _on_load_file_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.fbx", "FBX Files")
	file_dialog.file_selected.connect(_on_manual_file_selected)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(800, 600))

func _on_manual_file_selected(path: String):
	emit_signal("file_selected", path)

# Función pública para obtener animaciones seleccionadas
func get_selected_animations() -> Array:
	var selected = []
	for checkbox in animation_checkboxes:
		if checkbox.button_pressed:
			selected.append(checkbox.get_meta("filename"))
	return selected

# Función pública para obtener datos de unidad actual
func get_current_unit_data() -> Dictionary:
	return current_unit_data
