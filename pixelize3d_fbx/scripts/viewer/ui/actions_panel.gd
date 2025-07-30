# scripts/viewer/ui/actions_panel.gd
# Panel especializado SOLO para botones de acción
# Input: Clics en botones de acción
# Output: Señales de acciones solicitadas

extends VBoxContainer

# Señales específicas de este panel
signal preview_requested()
signal render_requested()
signal export_requested()
signal settings_requested()

# UI propia de este panel
var section_label: Label
var preview_button: Button
var render_button: Button
var export_button: Button
var settings_button: Button
var progress_bar: ProgressBar
var status_label: Label

# Estado interno
var preview_enabled: bool = true
var render_enabled: bool = false
var is_processing: bool = false

func _ready():
	_create_ui()

func _create_ui():
	# Título de sección
	section_label = Label.new()
	section_label.text = "🎯 Acciones"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# Status actual
	status_label = Label.new()
	status_label.text = "Carga un modelo para comenzar"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)
	
	# Botones principales
	var main_actions = HBoxContainer.new()
	add_child(main_actions)
	
	preview_button = Button.new()
	preview_button.text = "🎬 Preview"
	preview_button.disabled = true
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_on_preview_pressed)
	main_actions.add_child(preview_button)
	
	render_button = Button.new()
	render_button.text = "🎨 Renderizar"
	render_button.disabled = true
	render_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	render_button.pressed.connect(_on_render_pressed)
	main_actions.add_child(render_button)
	
	# Botones secundarios
	var secondary_actions = HBoxContainer.new()
	add_child(secondary_actions)
	
	export_button = Button.new()
	export_button.text = "💾 Exportar"
	export_button.disabled = true
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.pressed.connect(_on_export_pressed)
	secondary_actions.add_child(export_button)
	
	settings_button = Button.new()
	settings_button.text = "⚙️ Config"
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.pressed.connect(_on_settings_pressed)
	secondary_actions.add_child(settings_button)
	
	# Barra de progreso
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	progress_bar.show_percentage = true
	add_child(progress_bar)

func _on_preview_pressed():
	if not preview_enabled:
		return
	
	set_status("🎬 Activando preview...")
	emit_signal("preview_requested")
	
	# Actualizar estado del botón
	preview_button.text = "🎬 Preview ✓"
	preview_button.add_theme_color_override("font_color", Color.GREEN)

func _on_render_pressed():
	if not render_enabled or is_processing:
		return
	
	set_status("🎨 Iniciando renderizado...")
	emit_signal("render_requested")

func _on_export_pressed():
	if is_processing:
		return
	
	set_status("💾 Exportando archivos...")
	emit_signal("export_requested")

func _on_settings_pressed():
	emit_signal("settings_requested")

# Funciones públicas para control de estado
func enable_preview_button():
	preview_enabled = true
	preview_button.disabled = false
	set_status("✅ Listo para preview")

func enable_render_button():
	render_enabled = true
	render_button.disabled = false
	set_status("✅ Listo para renderizar")

func disable_preview_button():
	preview_enabled = false
	preview_button.disabled = true
	preview_button.text = "🎬 Preview"
	preview_button.remove_theme_color_override("font_color")

func disable_render_button():
	render_enabled = false
	render_button.disabled = true

func start_processing(process_name: String):
	is_processing = true
	
	# Deshabilitar botones durante procesamiento
	preview_button.disabled = true
	render_button.disabled = true
	export_button.disabled = true
	
	# Mostrar progreso
	progress_bar.visible = true
	progress_bar.value = 0
	
	set_status( process_name + "...")

func update_progress(value: float, message: String = ""):
	progress_bar.value = value * 100
	
	if message != "":
		set_status("⏳ " + message)

func finish_processing(success: bool, message: String):
	is_processing = false
	
	# Restaurar estado de botones
	preview_button.disabled = not preview_enabled
	render_button.disabled = not render_enabled
	export_button.disabled = false
	
	# Ocultar progreso
	progress_bar.visible = false
	
	if success:
		set_status("✅ " + message)
	else:
		set_status("❌ " + message)

func set_status(message: String):
	status_label.text = message

func show_error(error_message: String):
	set_status("❌ Error: " + error_message)
	
	# Crear diálogo de error temporal
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = error_message
	add_child(error_dialog)
	error_dialog.popup_centered()
	
	# Auto-destruir el diálogo
	error_dialog.visibility_changed.connect(error_dialog.queue_free)

func show_info(info_message: String):
	set_status( info_message)

# Funciones públicas de estado
func is_preview_enabled() -> bool:
	return preview_enabled

func is_render_enabled() -> bool:
	return render_enabled

func is_currently_processing() -> bool:
	return is_processing

func get_current_status() -> String:
	return status_label.text

func reset_all_buttons():
	preview_enabled = false
	render_enabled = false
	is_processing = false
	
	preview_button.disabled = true
	render_button.disabled = true
	export_button.disabled = true
	
	preview_button.text = "🎬 Preview"
	preview_button.remove_theme_color_override("font_color")
	
	progress_bar.visible = false
	set_status("Carga un modelo para comenzar")
