# scripts/viewer/ui/file_loader_panel.gd
# Panel MEJORADO con mejor gestión de estados y protección anti-loops
# Input: Interacciones del usuario con carga de archivos
# Output: Señales controladas sin loops ni bloqueos

extends VBoxContainer

# Señales
signal file_selected(file_path: String)
signal unit_selected(unit_data: Dictionary)
signal animations_selected(animations: Array)

# UI elements
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

# ✅ MEJORADO: Variables anti-loops con timeouts
var is_loading_animations: bool = false
var last_selected_animations: Array = []
var debounce_timer: Timer
var loading_timeout_timer: Timer
var max_loading_time: float = 30.0  # Máximo 30 segundos de bloqueo

func _ready():
	_setup_timers()
	_create_ui()
	_scan_available_units()
	print("📁 FileLoaderPanel MEJORADO inicializado")

func _setup_timers():
	"""✅ MEJORADO: Configurar timers con timeout de seguridad"""
	# Timer de debounce
	debounce_timer = Timer.new()
	debounce_timer.wait_time = 0.5
	debounce_timer.one_shot = true
	debounce_timer.timeout.connect(_emit_animations_selected)
	add_child(debounce_timer)
	
	# ✅ NUEVO: Timer de timeout para evitar bloqueos permanentes
	loading_timeout_timer = Timer.new()
	loading_timeout_timer.wait_time = max_loading_time
	loading_timeout_timer.one_shot = true
	loading_timeout_timer.timeout.connect(_on_loading_timeout)
	add_child(loading_timeout_timer)

func _create_ui():
	# Título
	section_label = Label.new()
	section_label.text = "📁 Cargar Archivos FBX"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# Unidades
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
	var animations_label = Label.new()
	animations_label.text = "Animaciones:"
	add_child(animations_label)
	
	animations_container = VBoxContainer.new()
	add_child(animations_container)
	
	add_child(HSeparator.new())
	
	# Botón de carga manual
	load_file_button = Button.new()
	load_file_button.text = "📂 Cargar archivo manual..."
	load_file_button.pressed.connect(_on_load_file_pressed)
	add_child(load_file_button)

func _scan_available_units():
	"""Escanear unidades disponibles en assets/fbx/"""
	print("🔍 Escaneando unidades en assets/fbx/...")
	
	available_units.clear()
	var dir = DirAccess.open("res://assets/fbx/")
	
	if not dir:
		print("❌ No se pudo abrir assets/fbx/")
		units_option.clear()
		units_option.add_item("-- No se encontró carpeta assets/fbx/ --")
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var unit_path = "res://assets/fbx/" + folder_name
			var unit_data = _scan_unit_folder(unit_path, folder_name)
			
			if unit_data.base_files.size() > 0 or unit_data.animations.size() > 0:
				available_units.append(unit_data)
				print("✅ Unidad encontrada: %s" % folder_name)
		
		folder_name = dir.get_next()
	
	_update_units_dropdown()

func _scan_unit_folder(path: String, name: String) -> Dictionary:
	"""Escanear contenido de una carpeta de unidad"""
	var unit_data = {
		"name": name,
		"path": path,
		"base_files": [],
		"animations": []
	}
	
	var dir = DirAccess.open(path)
	if not dir:
		return unit_data
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".fbx"):
			if "base" in file_name.to_lower() or "idle" in file_name.to_lower():
				unit_data.base_files.append(file_name)
			else:
				unit_data.animations.append(file_name)
		
		file_name = dir.get_next()
	
	return unit_data

func _update_units_dropdown():
	"""Actualizar dropdown de unidades"""
	units_option.clear()
	
	if available_units.is_empty():
		units_option.add_item("-- No se encontraron unidades --")
		units_option.disabled = true
		return
	
	units_option.add_item("-- Seleccionar unidad --")
	
	for unit in available_units:
		units_option.add_item(unit.name)
	
	units_option.disabled = false
	print("📋 %d unidades disponibles" % available_units.size())

func _on_unit_selected(index: int):
	"""✅ MEJORADO: Manejar selección de unidad con reset de estado"""
	if index <= 0 or index > available_units.size():
		return
	
	# Reset estado de carga antes de cambiar unidad
	_reset_loading_state()
	
	current_unit_data = available_units[index - 1]
	print("📦 Unidad seleccionada: %s" % current_unit_data.name)
	
	# Actualizar UI
	var info_text = "Base: %d archivos | Animaciones: %d archivos" % [
		current_unit_data.base_files.size(),
		current_unit_data.animations.size()
	]
	unit_info_label.text = info_text
	
	emit_signal("unit_selected", current_unit_data)
	populate_unit_files(current_unit_data)

func populate_unit_files(unit_data: Dictionary):
	"""✅ MEJORADO: Poblar archivos con mejor gestión de estado"""
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
	"""✅ MEJORADO: Crear checkboxes con mejor protección"""
	print("🎭 Creando checkboxes para %d animaciones" % animation_files.size())
	
	# Verificar si ya estamos cargando
	if is_loading_animations:
		print("⚠️ Ya se están cargando animaciones, esperando...")
		# Esperar a que termine o timeout
		await loading_timeout_timer.timeout
	
	# Limpiar checkboxes anteriores
	for checkbox in animation_checkboxes:
		if checkbox.toggled.is_connected(_on_animation_toggled_debounced):
			checkbox.toggled.disconnect(_on_animation_toggled_debounced)
		checkbox.queue_free()
	animation_checkboxes.clear()
	
	# Reset estado
	last_selected_animations.clear()
	
	# Crear nuevos checkboxes
	for anim_file in animation_files:
		var checkbox = CheckBox.new()
		checkbox.text = _get_display_name(anim_file)
		checkbox.set_meta("filename", anim_file)
		checkbox.toggled.connect(_on_animation_toggled_debounced)
		animations_container.add_child(checkbox)
		animation_checkboxes.append(checkbox)

func _on_base_fbx_selected(index: int):
	"""Manejar selección de archivo base"""
	if index <= 0 or current_unit_data.is_empty():
		return
	
	var base_files = current_unit_data.get("base_files", [])
	if index - 1 < base_files.size():
		var selected_file = base_files[index - 1]
		var file_path = current_unit_data.get("path", "") + "/" + selected_file
		
		print("📂 Base seleccionado: %s" % selected_file)
		emit_signal("file_selected", file_path)

func _on_animation_toggled_debounced(pressed: bool):
	"""✅ MEJORADO: Toggle con mejor manejo de estado"""
	print("🎭 Toggle de animación: %s" % ("ON" if pressed else "OFF"))
	
	# Verificar si ya estamos procesando
	if is_loading_animations:
		var time_loading = (max_loading_time - loading_timeout_timer.time_left)
		print("⚠️ Ya cargando por %.1fs..." % time_loading)
		
		# Si llevamos mucho tiempo, forzar reset
		if time_loading > 10.0:
			print("⚠️ Forzando reset por tiempo excesivo")
			_reset_loading_state()
	
	# Reiniciar timer de debounce
	debounce_timer.stop()
	debounce_timer.start()

func _emit_animations_selected():
	"""✅ MEJORADO: Emitir con protección mejorada"""
	print("📡 Emitiendo animaciones seleccionadas")
	
	var selected = get_selected_animations()
	
	# Verificar si cambió la selección
	if _arrays_equal(selected, last_selected_animations):
		print("ℹ️ Selección sin cambios")
		return
	
	print("🎭 Nueva selección: %d animaciones" % selected.size())
	last_selected_animations = selected.duplicate()
	
	# Marcar como cargando y activar timeout
	is_loading_animations = true
	loading_timeout_timer.start()
	
	emit_signal("animations_selected", selected)
	
	# ✅ MEJORADO: Reset más rápido
	await get_tree().create_timer(1.0).timeout
	if is_loading_animations:
		_reset_loading_state()

func _on_loading_timeout():
	"""✅ NUEVO: Manejar timeout de carga"""
	print("⏰ TIMEOUT: Carga tomó demasiado tiempo")
	_reset_loading_state()
	
	# Notificar al usuario
	if section_label:
		var original_text = section_label.text
		section_label.text = "⚠️ Timeout en carga - reintente"
		section_label.add_theme_color_override("font_color", Color.ORANGE)
		
		await get_tree().create_timer(3.0).timeout
		section_label.text = original_text
		section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))

func _reset_loading_state():
	"""✅ MEJORADO: Reset completo de estado"""
	print("🔄 Reset de estado de carga")
	
	is_loading_animations = false
	
	if debounce_timer.time_left > 0:
		debounce_timer.stop()
	
	if loading_timeout_timer.time_left > 0:
		loading_timeout_timer.stop()

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
	print("📂 Archivo manual: %s" % path)
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

func enable_animation_selection():
	"""Habilitar selección de animaciones"""
	print("✅ Selección de animaciones habilitada")
	for checkbox in animation_checkboxes:
		checkbox.disabled = false

func disable_animation_selection():
	"""Deshabilitar selección de animaciones"""
	print("🔒 Selección de animaciones deshabilitada")
	for checkbox in animation_checkboxes:
		checkbox.disabled = true

func reset_loading_state():
	"""Reset público del estado"""
	_reset_loading_state()

# === UTILIDADES ===

func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar si dos arrays son iguales"""
	if a.size() != b.size():
		return false
	
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	
	return true

func _get_display_name(filename: String) -> String:
	"""Obtener nombre limpio para mostrar"""
	var base_name = filename.get_file().get_basename()
	var clean_name = base_name
	
	# Limpiar patrones comunes
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	clean_name = clean_name.replace("mixamo", "")
	clean_name = clean_name.replace(".com", "")
	
	# Capitalizar
	clean_name = clean_name.strip_edges().capitalize()
	
	return clean_name

# === DEBUG ===

func debug_state():
	"""Debug del estado actual"""
	print("\n📁 === FILE LOADER DEBUG ===")
	print("Unidades: %d" % available_units.size())
	print("Unidad actual: %s" % current_unit_data.get("name", "Ninguna"))
	print("Checkboxes: %d" % animation_checkboxes.size())
	print("Seleccionadas: %s" % str(get_selected_animations()))
	print("PROTECCIONES:")
	print("  Cargando: %s" % is_loading_animations)
	print("  Última selección: %s" % str(last_selected_animations))
	print("  Debounce activo: %s (%.1fs)" % [debounce_timer.time_left > 0, debounce_timer.time_left])
	print("  Timeout activo: %s (%.1fs)" % [loading_timeout_timer.time_left > 0, loading_timeout_timer.time_left])
	print("==========================\n")

func force_reset():
	"""Reset de emergencia"""
	print("🚨 RESET DE EMERGENCIA")
	
	_reset_loading_state()
	
	# Limpiar checkboxes
	for checkbox in animation_checkboxes:
		checkbox.button_pressed = false
	
	last_selected_animations.clear()
	
	print("✅ Reset de emergencia completado")
