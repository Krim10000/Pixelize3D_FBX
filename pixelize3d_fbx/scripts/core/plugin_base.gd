# scripts/core/plugin_base.gd
extends Node
class_name PluginBase

# Input: Sistema de plugins
# Output: Clase base para crear plugins personalizados

var plugin_system: Node
var plugin_name: String = ""
var plugin_version: String = "1.0"
var plugin_settings: Dictionary = {}

# Funciones virtuales para sobrescribir
func _enter_plugin():
	# Llamado cuando el plugin se activa
	pass

func _exit_plugin():
	# Llamado cuando el plugin se desactiva
	pass

func _get_plugin_name() -> String:
	return plugin_name

# Funciones de utilidad para plugins
func register_hook(hook_name: String, callback: Callable):
	if plugin_system:
		plugin_system.register_hook(plugin_name, hook_name, callback)

func get_main() -> Node:
	if plugin_system:
		return plugin_system.get_main_node()
	return null

func get_component(name: String) -> Node:
	if plugin_system:
		return plugin_system.get_component(name)
	return null

func log(message: String, level: String = "info"):
	var prefix = "[%s] " % plugin_name
	match level:
		"error":
			push_error(prefix + message)
		"warning":
			push_warning(prefix + message)
		_:
			print(prefix + message)

func get_setting(key: String, default_value = null):
	return plugin_settings.get(key, default_value)

func set_setting(key: String, value):
	plugin_settings[key] = value
	save_settings()

func save_settings():
	var settings_path = plugin_system.plugin_directory.path_join(plugin_name).path_join("settings.json")
	Utils.save_json_file(plugin_settings, settings_path)

func load_settings():
	var settings_path = plugin_system.plugin_directory.path_join(plugin_name).path_join("settings.json")
	if FileAccess.file_exists(settings_path):
		plugin_settings = Utils.parse_json_file(settings_path)

# Eventos de plugin
func emit_event(event_name: String, data: Dictionary = {}):
	if plugin_system:
		plugin_system.emit_plugin_event(plugin_name + "." + event_name, data)

func connect_to_event(event_name: String, callback: Callable):
	if plugin_system:
		plugin_system.connect_to_plugin_event(event_name, callback)

# Acceso a la UI
func add_menu_item(menu_name: String, item_name: String, callback: Callable):
	var ui = get_component("UIController")
	if ui and ui.has_method("add_plugin_menu_item"):
		ui.add_plugin_menu_item(plugin_name, menu_name, item_name, callback)

func add_toolbar_button(text: String, icon: Texture2D, callback: Callable):
	var ui = get_component("UIController")
	if ui and ui.has_method("add_plugin_toolbar_button"):
		ui.add_plugin_toolbar_button(plugin_name, text, icon, callback)

func show_dialog(title: String, content: Control):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.add_child(content)
	dialog.popup_centered(Vector2(600, 400))
	get_tree().root.add_child(dialog)
	dialog.visibility_changed.connect(dialog.queue_free)

# Procesamiento personalizado
func process_frame(frame_data: Dictionary) -> Dictionary:
	# Sobrescribir para procesar frames
	return frame_data

func process_export(export_data: Dictionary) -> Dictionary:
	# Sobrescribir para procesar exportación
	return export_data

func validate_fbx(fbx_data: Dictionary) -> Array:
	# Sobrescribir para añadir validaciones personalizadas
	# Retornar array de errores/advertencias
	return []
