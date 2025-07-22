# scripts/core/plugin_system.gd
extends Node

# Input: Plugins externos para extender funcionalidad
# Output: Sistema extensible con hooks y eventos

signal plugin_loaded(plugin_name: String)
signal plugin_unloaded(plugin_name: String)
signal plugin_error(plugin_name: String, error: String)

var loaded_plugins: Dictionary = {}
var plugin_hooks: Dictionary = {}
var plugin_directory: String = "user://plugins"

# Definición de hooks disponibles
const HOOKS = {
	"pre_render": "Antes de renderizar un frame",
	"post_render": "Después de renderizar un frame",
	"pre_export": "Antes de exportar spritesheet",
	"post_export": "Después de exportar spritesheet",
	"fbx_loaded": "Cuando se carga un FBX",
	"animation_combined": "Cuando se combina base con animación",
	"custom_shader": "Para aplicar shaders personalizados",
	"custom_export_format": "Para formatos de exportación adicionales",
	"ui_extension": "Para añadir elementos a la UI",
	"validation_rules": "Para reglas de validación personalizadas"
}

func _ready():
	_ensure_plugin_directory()
	_scan_and_load_plugins()

func _ensure_plugin_directory():
	DirAccess.make_dir_recursive_absolute(plugin_directory)
	
	# Crear estructura de ejemplo
	var example_plugin_path = plugin_directory.path_join("example_plugin")
	DirAccess.make_dir_recursive_absolute(example_plugin_path)
	
	# Crear plugin de ejemplo si no existe
	var example_file = example_plugin_path.path_join("plugin.cfg")
	if not FileAccess.file_exists(example_file):
		_create_example_plugin(example_plugin_path)

func _create_example_plugin(path: String):
	# Crear plugin.cfg
	var config = """[plugin]

name="Example Plugin"
description="Ejemplo de plugin para Pixelize3D"
author="Tu Nombre"
version="1.0"
script="plugin.gd"
"""
	
	var cfg_file = FileAccess.open(path.path_join("plugin.cfg"), FileAccess.WRITE)
	if cfg_file:
		cfg_file.store_string(config)
		cfg_file.close()
	
	# Crear script del plugin
	var plugin_script = """extends "res://scripts/core/plugin_base.gd"

func _enter_plugin():
	print("Example Plugin activado!")
	
	# Registrar hooks
	register_hook("post_render", _on_post_render)
	register_hook("pre_export", _on_pre_export)

func _exit_plugin():
	print("Example Plugin desactivado!")

func _on_post_render(data: Dictionary):
	# Añadir watermark o efecto al frame renderizado
	if data.has("image"):
		var image = data.image
		# Aplicar algún efecto...
		print("Post-procesando frame...")

func _on_pre_export(data: Dictionary):
	# Modificar metadata antes de exportar
	if data.has("metadata"):
		data.metadata["plugin_processed"] = true
		print("Metadata modificada por plugin")
"""
	
	var script_file = FileAccess.open(path.path_join("plugin.gd"), FileAccess.WRITE)
	if script_file:
		script_file.store_string(plugin_script)
		script_file.close()

func _scan_and_load_plugins():
	var dir = DirAccess.open(plugin_directory)
	if not dir:
		push_error("No se pudo abrir directorio de plugins")
		return
	
	dir.list_dir_begin()
	var plugin_name = dir.get_next()
	
	while plugin_name != "":
		if dir.current_is_dir() and not plugin_name.begins_with("."):
			var plugin_path = plugin_directory.path_join(plugin_name)
			_try_load_plugin(plugin_path)
		
		plugin_name = dir.get_next()
	
	dir.list_dir_end()

func _try_load_plugin(path: String):
	var config_path = path.path_join("plugin.cfg")
	
	if not FileAccess.file_exists(config_path):
		return
	
	var config = ConfigFile.new()
	var error = config.load(config_path)
	
	if error != OK:
		push_error("Error cargando configuración de plugin: " + path)
		return
	
	var plugin_info = {
		"name": config.get_value("plugin", "name", "Unknown"),
		"description": config.get_value("plugin", "description", ""),
		"author": config.get_value("plugin", "author", "Unknown"),
		"version": config.get_value("plugin", "version", "1.0"),
		"script": config.get_value("plugin", "script", "plugin.gd"),
		"enabled": config.get_value("plugin", "enabled", true),
		"path": path
	}
	
	if plugin_info.enabled:
		_load_plugin(plugin_info)

func _load_plugin(info: Dictionary):
	var script_path = info.path.path_join(info.script)
	
	if not FileAccess.file_exists(script_path):
		emit_signal("plugin_error", info.name, "Script no encontrado: " + script_path)
		return
	
	var plugin_script = load(script_path)
	if not plugin_script:
		emit_signal("plugin_error", info.name, "No se pudo cargar el script")
		return
	
	var plugin_instance = plugin_script.new()
	plugin_instance.name = info.name
	plugin_instance.plugin_system = self
	
	add_child(plugin_instance)
	
	loaded_plugins[info.name] = {
		"info": info,
		"instance": plugin_instance
	}
	
	# Llamar a la función de inicialización del plugin
	if plugin_instance.has_method("_enter_plugin"):
		plugin_instance._enter_plugin()
	
	emit_signal("plugin_loaded", info.name)
	print("Plugin cargado: " + info.name)

func unload_plugin(plugin_name: String):
	if not plugin_name in loaded_plugins:
		return
	
	var plugin_data = loaded_plugins[plugin_name]
	var instance = plugin_data.instance
	
	# Llamar a la función de limpieza del plugin
	if instance.has_method("_exit_plugin"):
		instance._exit_plugin()
	
	# Desregistrar todos los hooks del plugin
	for hook_name in plugin_hooks:
		plugin_hooks[hook_name].erase(plugin_name)
	
	instance.queue_free()
	loaded_plugins.erase(plugin_name)
	
	emit_signal("plugin_unloaded", plugin_name)

func register_hook(plugin_name: String, hook_name: String, callback: Callable):
	if not hook_name in HOOKS:
		push_error("Hook no válido: " + hook_name)
		return
	
	if not hook_name in plugin_hooks:
		plugin_hooks[hook_name] = {}
	
	plugin_hooks[hook_name][plugin_name] = callback

func call_hook(hook_name: String, data: Dictionary = {}):
	if not hook_name in plugin_hooks:
		return data
	
	var modified_data = data.duplicate()
	
	for plugin_name in plugin_hooks[hook_name]:
		var callback = plugin_hooks[hook_name][plugin_name]
		if callback.is_valid():
			var result = callback.call(modified_data)
			if result is Dictionary:
				modified_data = result
	
	return modified_data

func get_loaded_plugins() -> Array:
	var plugins = []
	for plugin_name in loaded_plugins:
		var plugin_data = loaded_plugins[plugin_name].duplicate()
		plugin_data["name"] = plugin_name
		plugins.append(plugin_data.info)
	return plugins

func reload_plugin(plugin_name: String):
	if plugin_name in loaded_plugins:
		var info = loaded_plugins[plugin_name].info
		unload_plugin(plugin_name)
		await get_tree().process_frame
		_load_plugin(info)

func enable_plugin(plugin_name: String):
	# Actualizar configuración del plugin
	for plugin_dir in DirAccess.get_directories_at(plugin_directory):
		var config_path = plugin_directory.path_join(plugin_dir).path_join("plugin.cfg")
		var config = ConfigFile.new()
		
		if config.load(config_path) == OK:
			if config.get_value("plugin", "name") == plugin_name:
				config.set_value("plugin", "enabled", true)
				config.save(config_path)
				
				# Recargar plugins
				_scan_and_load_plugins()
				break

func disable_plugin(plugin_name: String):
	if plugin_name in loaded_plugins:
		unload_plugin(plugin_name)
	
	# Actualizar configuración
	for plugin_dir in DirAccess.get_directories_at(plugin_directory):
		var config_path = plugin_directory.path_join(plugin_dir).path_join("plugin.cfg")
		var config = ConfigFile.new()
		
		if config.load(config_path) == OK:
			if config.get_value("plugin", "name") == plugin_name:
				config.set_value("plugin", "enabled", false)
				config.save(config_path)
				break

# API para plugins
func get_main_node() -> Node:
	return get_node("/root/Main")

func get_component(component_name: String) -> Node:
	var main = get_main_node()
	if main and main.has_node(component_name):
		return main.get_node(component_name)
	return null

func add_ui_element(element: Control, parent_name: String = ""):
	var ui_controller = get_component("UIController")
	if ui_controller:
		if parent_name != "" and ui_controller.has_node(parent_name):
			ui_controller.get_node(parent_name).add_child(element)
		else:
			ui_controller.add_child(element)

func register_export_format(format_name: String, exporter_callback: Callable):
	var export_manager = get_component("ExportManager")
	if export_manager and export_manager.has_method("register_custom_format"):
		export_manager.register_custom_format(format_name, exporter_callback)

func register_validation_rule(rule_name: String, validator_callback: Callable):
	var validator = preload("res://scripts/core/fbx_validator.gd")
	# Implementar registro de reglas personalizadas

# Sistema de eventos para comunicación entre plugins
var plugin_events: Dictionary = {}

func emit_plugin_event(event_name: String, data: Dictionary = {}):
	if event_name in plugin_events:
		for callback in plugin_events[event_name]:
			callback.call(data)

func connect_to_plugin_event(event_name: String, callback: Callable):
	if not event_name in plugin_events:
		plugin_events[event_name] = []
	plugin_events[event_name].append(callback)

func disconnect_from_plugin_event(event_name: String, callback: Callable):
	if event_name in plugin_events:
		plugin_events[event_name].erase(callback)extends Node
