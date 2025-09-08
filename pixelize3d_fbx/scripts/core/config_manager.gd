# pixelize3d_fbx/scripts/core/delay_config_manager.gd
# Config Manager MODIFICADO para sistema de delay - LISTO PARA PRODUCCION Godot 4.4
# Input: Configuraciones del usuario con sistema de delay
# Output: Archivos de configuracion guardados y presets con delay

extends Node

# SEÑALES CORREGIDAS para Godot 4.4
signal config_loaded(config: Dictionary)
signal config_saved()
signal preset_loaded(preset_name: String)
signal delay_preset_applied(preset_name: String, delay_config: Dictionary)
signal delay_recommendation_enabled(enabled: bool)

# Rutas de archivos
const CONFIG_FILE_PATH = "user://pixelize3d_delay_config.cfg"
const PRESETS_FILE_PATH = "user://pixelize3d_delay_presets.json"

var current_config: Dictionary = {}
var presets: Dictionary = {}

# CONFIGURACION POR DEFECTO MODIFICADA PARA DELAY
var default_config: Dictionary = {
	"render": {
		"directions": 16,
		"sprite_size": 128,
		"frame_delay": 0.083333,  # Era fps: 12, ahora delay equivalent a 12 FPS
		"fps_equivalent": 12.0,   # Mostrar equivalencia
		"background_color": Color(0, 0, 0, 0),
		"pixelize": true,
		"pixel_scale": 4,
		"reduce_colors": false,
		"color_count": 16,
		"anti_aliasing": true,
		"shadows": true,
		"outline": false,
		"outline_color": Color.BLACK,
		"outline_width": 1.0,
		"auto_delay_recommendation": true,  # Auto-recomendacion
		"show_debug_frame_numbers": false  # Debug frames
	},
	"camera": {
		"angle": 45.0,
		"height": 10.0,
		"distance": 15.0,
		"fov": 35.0,
		"orthographic": true,
		"orthographic_size": 15.0,
		"auto_fit": true,
		"manual_zoom_override": false,
		"fixed_orthographic_size": 15.0
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
		"trim_transparent": false,
		"include_delay_info": true,  # Incluir info de delay en metadata
		"include_fps_equivalent": true  # Incluir FPS equivalente
	},
	"ui": {
		"theme": "dark",
		"preview_fps": 30,  # Para preview UI, no para renderizado
		"auto_preview": true,
		"confirm_overwrite": true,
		"recent_folders": [],
		"window_size": Vector2i(1280, 720),
		"window_position": Vector2i(100, 100),
		"show_delay_recommendations": true,  # Mostrar panel de recomendaciones
		"show_fps_equivalents": true  # Mostrar equivalencias FPS
	},
	"performance": {
		"max_parallel_renders": 4,
		"use_gpu_acceleration": true,
		"cache_models": true,
		"low_memory_mode": false
	},
	"delay_system": {  # Configuracion especifica del sistema de delay
		"enabled": true,
		"auto_recommendation": true,
		"recommendation_confidence_threshold": 0.8,
		"allow_sub_millisecond_precision": true,
		"timing_validation": true,
		"frame_perfect_priority": true
	}
}

# PRESETS MODIFICADOS PARA USAR DELAY EN LUGAR DE FPS
var default_presets: Dictionary = {
	"ultra_smooth": {
		"name": "Ultra Suave (60 FPS equiv)",
		"description": "Para animaciones ultra suaves - equivalente a 60 FPS",
		"config": {
			"render": {
				"directions": 16,
				"sprite_size": 128,
				"frame_delay": 0.016667,  # 60 FPS equivalent
				"fps_equivalent": 60.0,
				"pixelize": false,
				"shadows": true,
				"anti_aliasing": true,
				"auto_delay_recommendation": true
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true,
				"auto_fit": true,
				"manual_zoom_override": false,
				"fixed_orthographic_size": 15.0
			}
		}
	},
	"cinematic": {
		"name": "Cinematografico (24 FPS equiv)",
		"description": "Estilo cinematografico - equivalente a 24 FPS",
		"config": {
			"render": {
				"directions": 16,
				"sprite_size": 128,
				"frame_delay": 0.041667,  # 24 FPS equivalent
				"fps_equivalent": 24.0,
				"pixelize": false,
				"shadows": true,
				"anti_aliasing": true
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true,
				"auto_fit": true,
				"manual_zoom_override": false,
				"fixed_orthographic_size": 15.0
			}
		}
	},
	"rts_standard": {
		"name": "RTS Estandar (30 FPS equiv)",
		"description": "Configuracion tipica para juegos RTS - equivalente a 30 FPS",
		"config": {
			"render": {
				"directions": 16,
				"sprite_size": 128,
				"frame_delay": 0.033333,  # 30 FPS equivalent
				"fps_equivalent": 30.0,
				"pixelize": true,
				"pixel_scale": 2,
				"auto_delay_recommendation": true,
				"show_debug_frame_numbers": false
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true,
				"auto_fit": true,
				"manual_zoom_override": false,
				"fixed_orthographic_size": 15.0
			}
		}
	},
	"pixel_art_classic": {
		"name": "Pixel Art Clasico (12 FPS equiv)",
		"description": "Estilo pixel art retro clasico - equivalente a 12 FPS",
		"config": {
			"render": {
				"directions": 8,  # Menos direcciones estilo retro
				"sprite_size": 64,
				"frame_delay": 0.083333,  # 12 FPS equivalent
				"fps_equivalent": 12.0,
				"pixelize": true,
				"pixel_scale": 6,
				"reduce_colors": true,
				"color_count": 8,  # Paleta mas limitada
				"show_debug_frame_numbers": true
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true,
				"auto_fit": false,
				"manual_zoom_override": true,
				"fixed_orthographic_size": 10.0  # Zoom mas cerrado
			}
		}
	},
	"debug_fast": {
		"name": "Debug Rapido (10 FPS equiv)",
		"description": "Para debug rapido - equivalente a 10 FPS",
		"config": {
			"render": {
				"directions": 4,  # Solo 4 direcciones para debug
				"sprite_size": 64,
				"frame_delay": 0.1,  # 10 FPS equivalent
				"fps_equivalent": 10.0,
				"pixelize": false,
				"shadows": false,
				"show_debug_frame_numbers": true  # Debug siempre ON
			},
			"camera": {
				"angle": 45.0,
				"height": 10.0,
				"distance": 15.0,
				"orthographic": true,
				"auto_fit": false,
				"manual_zoom_override": true,
				"fixed_orthographic_size": 25.0  # Zoom muy alejado
			}
		}
	}
}

func _ready() -> void:
	print("⏱️ DelayConfigManager inicializado")
	# Cargar configuracion al iniciar
	load_config()
	load_presets()

# ========================================================================
# FUNCIONES DE CONFIGURACION
# ========================================================================

func load_config() -> void:
	var config_file: ConfigFile = ConfigFile.new()
	var error: int = config_file.load(CONFIG_FILE_PATH)
	
	if error != OK:
		#print("📁 No se encontro config de delay, usando valores por defecto")
		current_config = default_config.duplicate(true)
		save_config()
	else:
		#print("📁 Cargando config de delay desde archivo")
		current_config = {}
		for section in config_file.get_sections():
			current_config[section] = {}
			for key in config_file.get_section_keys(section):
				current_config[section][key] = config_file.get_value(section, key)
		
		# Migracion: Convertir configs antiguos FPS a delay
		_migrate_fps_to_delay_config()
		
		# Asegurar que todas las claves existan
		_merge_with_defaults()
	
	# EMISION CORREGIDA para Godot 4.4
	config_loaded.emit(current_config)

func _migrate_fps_to_delay_config() -> void:
	"""Migrar configuracion antigua FPS a nueva configuracion delay"""
	var migrated: bool = false
	
	if current_config.has("render"):
		# Si existe fps pero no frame_delay, convertir
		if current_config.render.has("fps") and not current_config.render.has("frame_delay"):
			var old_fps: float = current_config.render.fps
			var new_delay: float = 1.0 / old_fps if old_fps > 0 else 0.083333
			
			current_config.render.frame_delay = new_delay
			current_config.render.fps_equivalent = old_fps
			current_config.render.erase("fps")  # Remover campo obsoleto
			
			migrated = true
			#print("🔄 Migrado FPS %.1f → delay %.4fs" % [old_fps, new_delay])
	
	if migrated:
		save_config()
		#print("✅ Migracion de FPS a delay completada")

func save_config() -> void:
	var config_file: ConfigFile = ConfigFile.new()
	
	# Guardar todas las secciones
	for section in current_config:
		for key in current_config[section]:
			config_file.set_value(section, key, current_config[section][key])
	
	var error: int = config_file.save(CONFIG_FILE_PATH)
	if error == OK:
		config_saved.emit()
		print("💾 Configuracion de delay guardada")
	else:
		push_error("❌ Error al guardar configuracion de delay: " + str(error))

func _merge_with_defaults() -> void:
	"""Fusionar con configuracion por defecto para asegurar todas las claves"""
	for section in default_config:
		if not section in current_config:
			current_config[section] = {}
		
		for key in default_config[section]:
			if not key in current_config[section]:
				current_config[section][key] = default_config[section][key]

# ========================================================================
# API DE CONFIGURACION DE DELAY
# ========================================================================

func get_delay_config() -> Dictionary:
	"""Obtener configuracion especifica de delay"""
	var delay_config: Dictionary = {}
	
	# Extraer configuracion de delay de render
	if current_config.has("render"):
		var render: Dictionary = current_config.render
		delay_config = {
			"frame_delay": render.get("frame_delay", 0.083333),
			"fps_equivalent": render.get("fps_equivalent", 12.0),
			"auto_delay_recommendation": render.get("auto_delay_recommendation", true),
			"show_debug_frame_numbers": render.get("show_debug_frame_numbers", false)
		}
	
	# Añadir configuracion especifica del delay system
	if current_config.has("delay_system"):
		delay_config.merge(current_config.delay_system)
	
	return delay_config

func set_delay_config(delay_config: Dictionary) -> void:
	"""Establecer configuracion especifica de delay"""
	if not current_config.has("render"):
		current_config.render = {}
	
	if not current_config.has("delay_system"):
		current_config.delay_system = {}
	
	# Aplicar configuracion de delay
	for key in delay_config:
		if key in ["frame_delay", "fps_equivalent", "auto_delay_recommendation", "show_debug_frame_numbers"]:
			current_config.render[key] = delay_config[key]
		else:
			current_config.delay_system[key] = delay_config[key]
	
	save_config()
	print("⚙️ Configuracion de delay actualizada")

func get_config_value(section: String, key: String, default_value = null):
	"""Obtener valor de configuracion"""
	if section in current_config and key in current_config[section]:
		return current_config[section][key]
	return default_value

func set_config_value(section: String, key: String, value) -> void:
	"""Establecer valor de configuracion"""
	if not section in current_config:
		current_config[section] = {}
	current_config[section][key] = value
	save_config()

func get_section(section: String) -> Dictionary:
	"""Obtener seccion completa"""
	if section in current_config:
		return current_config[section]
	return {}

# ========================================================================
# GESTION DE PRESETS DE DELAY
# ========================================================================

func load_presets() -> void:
	"""Cargar presets de delay"""
	var file: FileAccess = FileAccess.open(PRESETS_FILE_PATH, FileAccess.READ)
	
	if file:
		var json_string: String = file.get_as_text()
		file.close()
		
		var json: JSON = JSON.new()
		var parse_result: int = json.parse(json_string)
		
		if parse_result == OK:
			presets = json.data
		else:
			print("❌ Error parseando presets de delay")
			presets = default_presets.duplicate(true)
	else:
		print("📁 No se encontraron presets, usando defaults")
		presets = default_presets.duplicate(true)
		save_presets()

func save_presets() -> void:
	"""Guardar presets de delay"""
	var file: FileAccess = FileAccess.open(PRESETS_FILE_PATH, FileAccess.WRITE)
	
	if file:
		var json_string: String = JSON.stringify(presets, "\t")
		file.store_string(json_string)
		file.close()
		print("💾 Presets de delay guardados")
	else:
		push_error("❌ Error guardando presets de delay")

func apply_delay_preset(preset_name: String) -> bool:
	"""Aplicar preset de delay"""
	if not preset_name in presets:
		print("❌ Preset de delay no encontrado: %s" % preset_name)
		return false
	
	var preset: Dictionary = presets[preset_name]
	print("🎯 Aplicando preset de delay: %s" % preset.name)
	
	# Aplicar configuracion del preset
	if preset.has("config"):
		for section in preset.config:
			if not section in current_config:
				current_config[section] = {}
			
			for key in preset.config[section]:
				current_config[section][key] = preset.config[section][key]
	
	save_config()
	
	# EMISIONES CORREGIDAS para Godot 4.4
	preset_loaded.emit(preset_name)
	
	var delay_config: Dictionary = get_delay_config()
	delay_preset_applied.emit(preset_name, delay_config)
	
	#print("✅ Preset '%s' aplicado: delay=%.4fs (%.1f FPS equiv)" % [
		#preset_name, 
		#delay_config.get("frame_delay", 0.083333),
		#delay_config.get("fps_equivalent", 12.0)
	#])
	
	return true

func get_all_delay_presets() -> Array[Dictionary]:
	"""Obtener todos los presets de delay disponibles"""
	var preset_list: Array[Dictionary] = []
	
	for preset_name in presets:
		var preset: Dictionary = presets[preset_name]
		preset_list.append({
			"key": preset_name,
			"name": preset.get("name", preset_name),
			"description": preset.get("description", "Sin descripcion"),
			"delay": _extract_delay_from_preset(preset),
			"fps_equivalent": _extract_fps_from_preset(preset)
		})
	
	return preset_list

func _extract_delay_from_preset(preset: Dictionary) -> float:
	"""Extraer delay de un preset"""
	if preset.has("config") and preset.config.has("render"):
		return preset.config.render.get("frame_delay", 0.083333)
	return 0.083333

func _extract_fps_from_preset(preset: Dictionary) -> float:
	"""Extraer FPS equivalente de un preset"""
	if preset.has("config") and preset.config.has("render"):
		return preset.config.render.get("fps_equivalent", 12.0)
	return 12.0

# ========================================================================
# UTILIDADES DE CONVERSION
# ========================================================================

func delay_to_fps(delay: float) -> float:
	"""Convertir delay a FPS equivalente"""
	if delay <= 0:
		return 0.0
	return 1.0 / delay

func fps_to_delay(fps: float) -> float:
	"""Convertir FPS a delay equivalente"""
	if fps <= 0:
		return 1.0
	return 1.0 / fps

func validate_delay(delay: float) -> Dictionary:
	"""Validar si un delay es valido"""
	var min_delay: float = 0.001  # 1000 FPS max
	var max_delay: float = 1.0    # 1 FPS min
	
	return {
		"valid": delay >= min_delay and delay <= max_delay,
		"delay": delay,
		"fps_equivalent": delay_to_fps(delay),
		"too_fast": delay < min_delay,
		"too_slow": delay > max_delay,
		"recommended_range": "%.3fs - %.3fs (%.1f - %.1f FPS)" % [
			min_delay, max_delay, delay_to_fps(max_delay), delay_to_fps(min_delay)
		]
	}

# ========================================================================
# API PUBLICA ADICIONAL
# ========================================================================

func create_custom_delay_preset(preset_name: String, delay: float, description: String = "") -> bool:
	"""Crear preset personalizado de delay"""
	if preset_name == "" or delay <= 0:
		return false
	
	var validation: Dictionary = validate_delay(delay)
	if not validation.valid:
		print("❌ Delay invalido para preset: %.4fs" % delay)
		return false
	
	var fps_equiv: float = delay_to_fps(delay)
	
	presets[preset_name] = {
		"name": preset_name,
		"description": description if description != "" else "Preset personalizado - %.1f FPS equiv" % fps_equiv,
		"config": {
			"render": {
				"frame_delay": delay,
				"fps_equivalent": fps_equiv,
				"auto_delay_recommendation": false  # Presets personalizados no usan auto-recomendacion
			}
		}
	}
	
	save_presets()
	#print("✅ Preset personalizado creado: %s (%.4fs delay)" % [preset_name, delay])
	return true

func delete_custom_preset(preset_name: String) -> bool:
	"""Eliminar preset personalizado"""
	if preset_name in default_presets:
		print("❌ No se puede eliminar preset por defecto: %s" % preset_name)
		return false
	
	if preset_name in presets:
		presets.erase(preset_name)
		save_presets()
		print("🗑️ Preset eliminado: %s" % preset_name)
		return true
	
	return false

func get_delay_system_status() -> Dictionary:
	"""Obtener estado del sistema de delay"""
	var delay_config: Dictionary = get_delay_config()
	
	return {
		"system_enabled": delay_config.get("enabled", true),
		"auto_recommendation": delay_config.get("auto_recommendation", true),
		"current_delay": delay_config.get("frame_delay", 0.083333),
		"current_fps_equivalent": delay_config.get("fps_equivalent", 12.0),
		"debug_enabled": delay_config.get("show_debug_frame_numbers", false),
		"total_presets": presets.size(),
		"timing_validation": delay_config.get("timing_validation", true)
	}

# ========================================================================
# API HEREDADA PARA COMPATIBILIDAD
# ========================================================================

func apply_preset(preset_name: String) -> bool:
	"""Alias para aplicar preset (compatibilidad con sistema actual)"""
	return apply_delay_preset(preset_name)
