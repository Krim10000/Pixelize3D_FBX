# scripts/viewer/ui/file_loader_panel.gd
# Panel ANTI-LOOPS que evita carga excesiva
# Input: Interacciones del usuario con carga de archivos
# Output: Señales controladas sin loops

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

# ✅ NUEVAS VARIABLES ANTI-LOOPS
var is_loading_animations: bool = false
var last_selected_animations: Array = []
var debounce_timer: Timer

func _ready():
	_setup_debounce_timer()
	_create_ui()
	_scan_available_units()
	print("📁 FileLoaderPanel ANTI-LOOPS inicializado")

# ✅ NUEVA FUNCIÓN: Setup timer para debouncing
func _setup_debounce_timer():
	"""Configurar timer para evitar eventos múltiples"""
	debounce_timer = Timer.new()
	debounce_timer.wait_time = 0.2  # 500ms de debounce
	debounce_timer.one_shot = true
	debounce_timer.timeout.connect(_emit_animations_selected)
	add_child(debounce_timer)

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
	
	# ScrollContainer para los checkboxes
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, 150)
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)
	
	animations_container = VBoxContainer.new()
	scroll_container.add_child(animations_container)
	
	add_child(HSeparator.new())
	
	# Botón de carga manual
	load_file_button = Button.new()
	load_file_button.text = "📁 Cargar FBX Manual"
	load_file_button.pressed.connect(_on_load_file_pressed)
	add_child(load_file_button)

# === ESCANEO SIMPLIFICADO ===
func _scan_available_units():
	"""Escanear carpetas en res://assets/fbx/ de forma simple"""
	print("🔍 Escaneando res://assets/fbx/...")
	
	available_units.clear()
	var base_path = "res://assets/fbx/"
	
	var dir = DirAccess.open(base_path)
	if not dir:
		print("❌ No se encuentra carpeta res://assets/fbx/")
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
				print("✅ Unidad encontrada: %s" % folder_name)
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	_populate_units_list()
	print("📋 Escaneo completo: %d unidades encontradas" % available_units.size())

func _analyze_unit_folder(path: String) -> Dictionary:
	"""Analizar carpeta de unidad de forma simple"""
	var unit_data = {
		"name": path.get_file(),
		"path": path,
		"base_files": [],
		"animations": []
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
				unit_data.animations.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return unit_data if unit_data.base_files.size() > 0 else {}

func _is_base_file(filename: String) -> bool:
	"""Detectar si es archivo base de forma simple"""
	var base_keywords = ["base", "idle", "static", "t-pose", "mesh", "model"]
	var lower_name = filename.to_lower()
	
	for keyword in base_keywords:
		if keyword in lower_name:
			return true
	
	return false

func _populate_units_list():
	"""Poblar lista de unidades en el dropdown"""
	units_option.clear()
	units_option.add_item("-- Seleccionar unidad --")
	
	for unit in available_units:
		var display_text = "%s (%d FBX)" % [unit.name, unit.base_files.size() + unit.animations.size()]
		units_option.add_item(display_text)
	
	units_option.disabled = available_units.is_empty()
	
	if available_units.is_empty():
		units_option.add_item("-- No hay unidades disponibles --")

# === MANEJADORES DE EVENTOS ===
func _on_unit_selected(index: int):
	"""Manejar selección de unidad"""
	print("📦 Unidad seleccionada, índice: %d" % index)
	
	if index <= 0 or index > available_units.size():
		return
	
	current_unit_data = available_units[index - 1]
	
	# Actualizar info
	unit_info_label.text = "Carpeta: %s\nBase: %d | Animaciones: %d" % [
		current_unit_data.path,
		current_unit_data.base_files.size(),
		current_unit_data.animations.size()
	]
	
	print("📋 Datos de unidad: %s" % str(current_unit_data))
	emit_signal("unit_selected", current_unit_data)

func populate_unit_files(unit_data: Dictionary):
	"""Poblar archivos de una unidad específica"""
	print("📋 Poblando archivos de unidad: %s" % unit_data.get("name", "Desconocida"))
	
	current_unit_data = unit_data
	
	# Poblar archivos base
	base_fbx_option.clear()
	base_fbx_option.add_item("-- Seleccionar modelo base --")
	
	var base_files = unit_data.get("base_files", [])
	for base_file in base_files:
		var display_name = base_file
		if "idle" in base_file.to_lower() or "base" in base_file.to_lower():
			display_name += " (recomendado)"
		base_fbx_option.add_item(display_name)
	
	base_fbx_option.disabled = false
	
	# Poblar animaciones
	var animations = unit_data.get("animations", [])
	_populate_animations(animations)
	
	print("✅ Archivos poblados: %d base, %d animaciones" % [base_files.size(), animations.size()])

func _populate_animations(animation_files: Array):
	"""Crear checkboxes para animaciones SIN LOOPS"""
	print("🎭 Creando checkboxes para %d animaciones" % animation_files.size())
	
	# ✅ PROTECCIÓN: Evitar populate durante carga
	if is_loading_animations:
		print("⚠️ Ya se están cargando animaciones, omitiendo populate")
		return
	
	# Limpiar checkboxes anteriores
	for checkbox in animation_checkboxes:
		# ✅ CORREGIDO: Usar el nombre correcto de la función
		if checkbox.toggled.is_connected(_on_animation_toggled_debounced):
			checkbox.toggled.disconnect(_on_animation_toggled_debounced)
		checkbox.queue_free()
	animation_checkboxes.clear()
	
	# Limpiar estado anterior
	last_selected_animations.clear()
	
	# Crear nuevos checkboxes
	for anim_file in animation_files:
		var checkbox = CheckBox.new()
		checkbox.text = anim_file.get_basename()
		checkbox.set_meta("filename", anim_file)
		checkbox.toggled.connect(_on_animation_toggled_debounced)  # ✅ USAR VERSIÓN DEBOUNCED
		animations_container.add_child(checkbox)
		animation_checkboxes.append(checkbox)
		print("📋 Checkbox creado: %s" % anim_file)

func _on_base_fbx_selected(index: int):
	"""Manejar selección de archivo base"""
	if index <= 0 or current_unit_data.is_empty():
		return
	
	var base_files = current_unit_data.get("base_files", [])
	if index - 1 < base_files.size():
		var selected_file = base_files[index - 1]
		var file_path = current_unit_data.get("path", "") + "/" + selected_file
		
		print("📂 Archivo base seleccionado: %s" % selected_file)
		emit_signal("file_selected", file_path)

# ✅ NUEVA FUNCIÓN: Toggle con debouncing
func _on_animation_toggled_debounced(pressed: bool):
	"""Manejar toggle de checkbox CON DEBOUNCING para evitar loops"""
	print("🎭 Toggle de animación (debounced): %s" % pressed)
	
	# ✅ PROTECCIÓN: Evitar múltiples cargas simultáneas
	if is_loading_animations:
		print("⚠️ Ya se están cargando animaciones, ignorando toggle")
		return
	
	# Reiniciar timer de debounce
	debounce_timer.stop()
	debounce_timer.start()
	
	print("⏱️ Timer de debounce iniciado (%.1fs)" % debounce_timer.wait_time)

func _emit_animations_selected():
	"""Emitir señal de animaciones seleccionadas CON PROTECCIÓN"""
	print("📡 Emitiendo animaciones seleccionadas después de debounce")
	
	var selected = get_selected_animations()
	
	# ✅ PROTECCIÓN: Solo emitir si realmente cambió la selección
	if _arrays_equal(selected, last_selected_animations):
		print("ℹ️ Selección no cambió, omitiendo emisión")
		return
	
	print("🎭 Nueva selección de animaciones: %s" % str(selected))
	last_selected_animations = selected.duplicate()
	
	# ✅ PROTECCIÓN: Marcar como cargando para evitar loops
	is_loading_animations = true
	
	emit_signal("animations_selected", selected)
	
	# ✅ IMPORTANTE: Resetear flag después de un tiempo
	#await get_tree().create_timer(2.0).timeout
	is_loading_animations = false
	print("🔓 Flag de carga reseteado")

func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar si dos arrays son iguales"""
	if a.size() != b.size():
		return false
	
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	
	return true

func _on_load_file_pressed():
	"""Carga manual de archivo"""
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.fbx", "FBX Files")
	file_dialog.file_selected.connect(_on_manual_file_selected)
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(800, 600))

func _on_manual_file_selected(path: String):
	"""Archivo seleccionado manualmente"""
	print("📂 Archivo manual seleccionado: %s" % path)
	emit_signal("file_selected", path)

# === FUNCIONES PÚBLICAS ===
func get_selected_animations() -> Array:
	"""Obtener animaciones seleccionadas"""
	var selected = []
	for checkbox in animation_checkboxes:
		if checkbox.button_pressed:
			selected.append(checkbox.get_meta("filename"))
	return selected

func get_current_unit_data() -> Dictionary:
	"""Obtener datos de unidad actual"""
	return current_unit_data

# ✅ NUEVA FUNCIÓN: Habilitar selección de animaciones desde coordinator
func enable_animation_selection():
	"""Habilitar selección de animaciones (llamada desde coordinator)"""
	print("✅ Habilitando selección de animaciones")
	# No hace nada especial, solo confirma que está lista
	pass

# ✅ NUEVA FUNCIÓN: Resetear estado de carga
func reset_loading_state():
	"""Resetear estado de carga manualmente"""
	print("🔄 Reseteando estado de carga manualmente")
	is_loading_animations = false
	last_selected_animations.clear()
	if debounce_timer and debounce_timer.time_left > 0:
		debounce_timer.stop()

# === FUNCIONES DE DEBUG ===
func debug_state():
	"""Debug del estado actual CON INFO DE PROTECCIÓN"""
	print("\n📁 === FILE LOADER DEBUG ANTI-LOOPS ===")
	print("Unidades escaneadas: %d" % available_units.size())
	print("Unidad actual: %s" % current_unit_data.get("name", "Ninguna"))
	print("Checkboxes creados: %d" % animation_checkboxes.size())
	print("Animaciones seleccionadas: %s" % str(get_selected_animations()))
	print("🔒 PROTECCIONES:")
	print("  - Cargando animaciones: %s" % is_loading_animations)
	print("  - Última selección: %s" % str(last_selected_animations))
	print("  - Timer debounce activo: %s" % (debounce_timer.time_left > 0))
	print("==========================================\n")

func force_reset():
	"""Función de emergencia para resetear todo"""
	print("🚨 RESET DE EMERGENCIA del FileLoaderPanel")
	
	# Detener timer
	if debounce_timer:
		debounce_timer.stop()
	
	# Resetear flags
	is_loading_animations = false
	last_selected_animations.clear()
	
	# Limpiar checkboxes
	for checkbox in animation_checkboxes:
		if checkbox.toggled.is_connected(_on_animation_toggled_debounced):
			checkbox.toggled.disconnect(_on_animation_toggled_debounced)
		checkbox.button_pressed = false
	
	print("✅ Reset de emergencia completado")
