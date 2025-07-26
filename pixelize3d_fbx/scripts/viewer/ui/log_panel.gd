# scripts/viewer/ui/log_panel.gd
# Panel especializado SOLO para logging y mensajes
# Input: Mensajes de log desde otros componentes
# Output: Visualización de log con controles

extends VBoxContainer

# Señales específicas de este panel
signal log_cleared()
signal log_exported(file_path: String)

# UI propia de este panel
var section_label: Label
var log_text: RichTextLabel
var controls_container: HBoxContainer
var clear_button: Button
var export_button: Button
var auto_scroll_check: CheckBox
var filter_option: OptionButton

# Estado interno
var log_entries: Array = []
var max_entries: int = 500
var auto_scroll: bool = true
var current_filter: String = "all"

# Tipos de log
enum LogType {
	INFO,
	WARNING,
	ERROR,
	SUCCESS,
	DEBUG
}

func _ready():
	_create_ui()

func _create_ui():
	# Título de sección
	section_label = Label.new()
	section_label.text = "📝 Log de Eventos"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	# Controles del log
	controls_container = HBoxContainer.new()
	add_child(controls_container)
	
	# Filtro
	var filter_label = Label.new()
	filter_label.text = "Filtro:"
	controls_container.add_child(filter_label)
	
	filter_option = OptionButton.new()
	filter_option.add_item("Todos")
	filter_option.add_item("Info")
	filter_option.add_item("Warnings")
	filter_option.add_item("Errores")
	filter_option.add_item("Success")
	filter_option.add_item("Debug")
	filter_option.item_selected.connect(_on_filter_changed)
	controls_container.add_child(filter_option)
	
	controls_container.add_child(VSeparator.new())
	
	# Auto-scroll
	auto_scroll_check = CheckBox.new()
	auto_scroll_check.text = "Auto-scroll"
	auto_scroll_check.button_pressed = true
	auto_scroll_check.toggled.connect(_on_auto_scroll_toggled)
	controls_container.add_child(auto_scroll_check)
	
	controls_container.add_child(VSeparator.new())
	
	# Botones
	clear_button = Button.new()
	clear_button.text = "🗑️ Limpiar"
	clear_button.pressed.connect(_on_clear_pressed)
	controls_container.add_child(clear_button)
	
	export_button = Button.new()
	export_button.text = "💾 Exportar"
	export_button.pressed.connect(_on_export_pressed)
	controls_container.add_child(export_button)
	
	# Área de texto del log
	log_text = RichTextLabel.new()
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.selection_enabled = true
	log_text.fit_content = true
	add_child(log_text)

func add_log(message: String, type: LogType = LogType.INFO):
	var timestamp = Time.get_time_string_from_system()
	
	var log_entry = {
		"timestamp": timestamp,
		"message": message,
		"type": type,
		"formatted": _format_log_entry(timestamp, message, type)
	}
	
	log_entries.append(log_entry)
	
	# Mantener límite de entradas
	while log_entries.size() > max_entries:
		log_entries.pop_front()
	
	_refresh_display()

func add_info(message: String):
	add_log(message, LogType.INFO)

func add_warning(message: String):
	add_log(message, LogType.WARNING)

func add_error(message: String):
	add_log(message, LogType.ERROR)

func add_success(message: String):
	add_log(message, LogType.SUCCESS)

func add_debug(message: String):
	add_log(message, LogType.DEBUG)

func _format_log_entry(timestamp: String, message: String, type: LogType) -> String:
	var color = "white"
	var icon = "ℹ️"
	
	match type:
		LogType.INFO:
			color = "lightblue"
			icon = "ℹ️"
		LogType.WARNING:
			color = "yellow"
			icon = "⚠️"
		LogType.ERROR:
			color = "red"
			icon = "❌"
		LogType.SUCCESS:
			color = "lightgreen"
			icon = "✅"
		LogType.DEBUG:
			color = "gray"
			icon = "🐛"
	
	return "[color=%s][%s] %s %s[/color]" % [color, timestamp, icon, message]

func _refresh_display():
	var filtered_entries = _get_filtered_entries()
	
	log_text.clear()
	
	for entry in filtered_entries:
		log_text.append_text(entry.formatted + "\n")
	
	# Auto-scroll si está habilitado
	if auto_scroll:
		await get_tree().process_frame
		log_text.scroll_to_line(log_text.get_line_count() - 1)

func _get_filtered_entries() -> Array:
	if current_filter == "all":
		return log_entries
	
	var filter_type = LogType.INFO
	
	match current_filter:
		"info":
			filter_type = LogType.INFO
		"warning":
			filter_type = LogType.WARNING
		"error":
			filter_type = LogType.ERROR
		"success":
			filter_type = LogType.SUCCESS
		"debug":
			filter_type = LogType.DEBUG
	
	var filtered = []
	for entry in log_entries:
		if entry.type == filter_type:
			filtered.append(entry)
	
	return filtered

func _on_filter_changed(index: int):
	var filters = ["all", "info", "warning", "error", "success", "debug"]
	current_filter = filters[index] if index < filters.size() else "all"
	_refresh_display()

func _on_auto_scroll_toggled(pressed: bool):
	auto_scroll = pressed
	log_text.scroll_following = pressed

func _on_clear_pressed():
	log_entries.clear()
	log_text.clear()
	add_info("Log limpiado")
	emit_signal("log_cleared")

func _on_export_pressed():
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var file_path = "user://log_export_%s.txt" % timestamp
	
	_export_to_file(file_path)

func _export_to_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		add_error("No se pudo crear archivo de exportación")
		return
	
	# Escribir encabezado
	file.store_line("=== Pixelize3D FBX Viewer - Log Export ===")
	file.store_line("Exportado: %s" % Time.get_datetime_string_from_system())
	file.store_line("Total entradas: %d" % log_entries.size())
	file.store_line("=".repeat(50))
	file.store_line("")
	
	# Escribir entradas
	for entry in log_entries:
		var clean_message = entry.message.strip_edges()
		file.store_line("[%s] %s" % [entry.timestamp, clean_message])
	
	file.close()
	
	add_success("Log exportado a: " + file_path)
	emit_signal("log_exported", file_path)

# Funciones públicas
func get_log_entries() -> Array:
	return log_entries.duplicate()

func get_entry_count() -> int:
	return log_entries.size()

func clear_log():
	_on_clear_pressed()

func set_max_entries(max_count: int):
	max_entries = max_count
	
	# Ajustar entradas actuales si es necesario
	while log_entries.size() > max_entries:
		log_entries.pop_front()
	
	_refresh_display()

func set_filter(filter_name: String):
	var filters = ["all", "info", "warning", "error", "success", "debug"]
	var index = filters.find(filter_name)
	
	if index >= 0:
		filter_option.selected = index
		_on_filter_changed(index)

func get_log_summary() -> Dictionary:
	var summary = {
		"total": log_entries.size(),
		"info": 0,
		"warning": 0,
		"error": 0,
		"success": 0,
		"debug": 0
	}
	
	for entry in log_entries:
		match entry.type:
			LogType.INFO:
				summary.info += 1
			LogType.WARNING:
				summary.warning += 1
			LogType.ERROR:
				summary.error += 1
			LogType.SUCCESS:
				summary.success += 1
			LogType.DEBUG:
				summary.debug += 1
	
	return summary

func has_errors() -> bool:
	for entry in log_entries:
		if entry.type == LogType.ERROR:
			return true
	return false

func get_recent_errors() -> Array:
	var errors = []
	for entry in log_entries:
		if entry.type == LogType.ERROR:
			errors.append(entry.message)
	return errors
