# scripts/core/config_manager.gd
extends Node

# Input: Configuraciones del usuario
# Output: Archivos de configuración guardados y presets

signal config_loaded(config: Dictionary)
signal config_saved()
signal preset_loaded(preset_name: String)

const CONFIG_FILE_PATH = "user://pixelize3d_config.cfg"
const PRESETS_FILE_PATH = "user://pixelize3d_presets.json"

var current_config: Dictionary = {}
var presets: Dictionary = {}

# Configuración por defecto
var default_config = {
	"render": {
		"directions": 16,
		"sprite_size": 256,
		"fps": 12,
		"background_color": Color(0, 0, 0, 0),
		"pixelize": true,
		"pixel_scale": 4,
		"reduce_colors": false,
		"color_count": 16,
		"anti_aliasing": true,
		"shadows": true,
		"outline": false,
		"outline_color": Color.BLACK,
		"outline_width": 1.0
	},
	"camera": {
		"angle": 45.0,
		"height": 10.0,
		"distance": 15.0,
		"fov": 35.0,
		"orthographic": true,
		"orthographic_size": 10.0,
		"auto_fit": true
	},
	"export": {
		"format": "png",
		"compression": 0,
		"separate_directions": false,
		"generate_metadata": true,
		"metadata_formats": ["json", "unity", "web"],
		"organize_by_animation": true,
		"filename_pattern": "{unit}_{animation}_{direction}",
		"padding": 0,
		"trim_transparent": false
	},
	"ui": {
		"theme": "dark",
		"preview_fps": 30,
		"auto_preview": true,
		"confirm_overwrite": true,
		"recent_folders": [],
		"window_size": Vector2i(1280, 720),
		"window_position": Vector2i(100, 100)
	},
	"performance": {
		"max_parallel_renders": 4,
		"use_gpu_acceleration": true,
		"cache_models": true,
		"low_memory_mode": false
	}
}

# Presets predefinidos
var default_presets = {
	"RTS_Standard": {
		"name": "RTS Estándar",
		"description": "Configuración típica para juegos RTS isométricos",
		"config": {
			"render": {
				"directions": 16,
				"sprite_size": 128,
				"fps": 12,
				"pixelize": true,
				"pixel_scale": 2
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true
			}
		}
	},
	"RTS_HD": {
		"name": "RTS Alta Definición",
		"description": "Para juegos RTS modernos con gráficos detallados",
		"config": {
			"render": {
				"directions": 32,
				"sprite_size": 512,
				"fps": 24,
				"pixelize": false,
				"shadows": true
			},
			"camera": {
				"angle": 30.0,
				"height": 12.0,
				"distance": 20.0,
				"orthographic": true
			}
		}
	},
	"Pixel_Art": {
		"name": "Pixel Art Retro",
		"description": "Estilo pixel art clásico",
		"config": {
			"render": {
				"directions": 8,
				"sprite_size": 64,
				"fps": 8,
				"pixelize": true,
				"pixel_scale": 4,
				"reduce_colors": true,
				"color_count": 16
			},
			"camera": {
				"angle": 45.0,
				"height": 8.0,
				"distance": 12.0,
				"orthographic": true
			}
		}
	},
	"Mobile_Optimized": {
		"name": "Optimizado para Móvil",
		"description": "Configuración optimizada para juegos móviles",
		"config": {
			"render": {
				"directions": 8,
				"sprite_size": 128,
				"fps": 15,
				"pixelize": false,
				"shadows": false,
				"anti_aliasing": false
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true
			},
			"export": {
				"compression": 5,
				"trim_transparent": true
			}
		}
	}
}

func _ready():
	# Cargar configuración al iniciar
	load_config()
	load_presets()

func load_config() -> void:
	var config_file = ConfigFile.new()
	var error = config_file.load(CONFIG_FILE_PATH)
	
	if error != OK:
		# Si no existe archivo de configuración, usar valores por defecto
		current_config = default_config.duplicate(true)
		save_config()
	else:
		# Cargar configuración desde archivo
		current_config = {}
		for section in config_file.get_sections():
			current_config[section] = {}
			for key in config_file.get_section_keys(section):
				current_config[section][key] = config_file.get_value(section, key)
		
		# Asegurar que todas las claves existan
		_merge_with_defaults()
	
	emit_signal("config_loaded", current_config)

func save_config() -> void:
	var config_file = ConfigFile.new()
	
	# Guardar todas las secciones
	for section in current_config:
		for key in current_config[section]:
			config_file.set_value(section, key, current_config[section][key])
	
	var error = config_file.save(CONFIG_FILE_PATH)
	if error == OK:
		emit_signal("config_saved")
	else:
		push_error("Error al guardar configuración: " + str(error))

func get_config_value(section: String, key: String, default_value = null):
	if section in current_config and key in current_config[section]:
		return current_config[section][key]
	return default_value

func set_config_value(section: String, key: String, value) -> void:
	if not section in current_config:
		current_config[section] = {}
	current_config[section][key] = value
	save_config()

func get_section(section: String) -> Dictionary:
	if section in current_config:
		return current_config[section]
	return {}

func update_section(section: String, values: Dictionary) -> void:
	if not section in current_config:
		current_config[section] = {}
	current_config[section].merge(values, true)
	save_config()

# Gestión de presets
func load_presets() -> void:
	var file = FileAccess.open(PRESETS_FILE_PATH, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			presets = json.data
		else:
			presets = default_presets.duplicate(true)
			save_presets()
	else:
		# Usar presets por defecto
		presets = default_presets.duplicate(true)
		save_presets()

func save_presets() -> void:
	var file = FileAccess.open(PRESETS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(presets, "\t"))
		file.close()

func get_preset(preset_name: String) -> Dictionary:
	if preset_name in presets:
		return presets[preset_name]
	return {}

func apply_preset(preset_name: String) -> void:
	if preset_name in presets:
		var preset = presets[preset_name]
		if "config" in preset:
			# Aplicar configuración del preset
			for section in preset.config:
				if section in current_config:
					current_config[section].merge(preset.config[section], true)
			
			save_config()
			emit_signal("preset_loaded", preset_name)

func save_custom_preset(preset_name: String, description: String = "") -> void:
	var preset_key = preset_name.replace(" ", "_")
	
	presets[preset_key] = {
		"name": name,
		"description": description,
		"config": current_config.duplicate(true),
		"custom": true,
		"created": Time.get_datetime_string_from_system()
	}
	
	save_presets()

func delete_preset(preset_name: String) -> bool:
	if preset_name in presets and presets[preset_name].get("custom", false):
		presets.erase(preset_name)
		save_presets()
		return true
	return false

func get_all_presets() -> Array:
	var preset_list = []
	for key in presets:
		var preset = presets[key].duplicate()
		preset["key"] = key
		preset_list.append(preset)
	return preset_list

# Funciones auxiliares
func _merge_with_defaults() -> void:
	# Asegurar que todas las claves de default_config existan en current_config
	for section in default_config:
		if not section in current_config:
			current_config[section] = {}
		
		for key in default_config[section]:
			if not key in current_config[section]:
				current_config[section][key] = default_config[section][key]

func reset_to_defaults() -> void:
	current_config = default_config.duplicate(true)
	save_config()
	emit_signal("config_loaded", current_config)

# Funciones de utilidad para acceso rápido
func get_render_settings() -> Dictionary:
	return get_section("render")

func get_camera_settings() -> Dictionary:
	return get_section("camera")

func get_export_settings() -> Dictionary:
	return get_section("export")

# Gestión de carpetas recientes
func add_recent_folder(folder_path: String) -> void:
	var recent_folders = get_config_value("ui", "recent_folders", [])
	
	# Remover si ya existe
	if folder_path in recent_folders:
		recent_folders.erase(folder_path)
	
	# Añadir al principio
	recent_folders.insert(0, folder_path)
	
	# Limitar a 10 carpetas recientes
	if recent_folders.size() > 10:
		recent_folders.resize(10)
	
	set_config_value("ui", "recent_folders", recent_folders)

func get_recent_folders() -> Array:
	return get_config_value("ui", "recent_folders", [])
