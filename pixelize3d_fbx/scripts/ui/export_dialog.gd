# pixelize3d_fbx/scripts/export/export_manager.gd
# Manager corregido para exportación de sprite sheets
# Input: Frames renderizados y configuración de exportación
# Output: Sprite sheets PNG y archivos de metadata

extends Node

# Señales
signal export_complete(file_path: String)
signal export_failed(error: String)
signal export_progress(current: int, total: int, message: String)

# Colección de frames por animación
var frames_collection: Dictionary = {}
var current_export_config: Dictionary = {}

# Referencias a otros componentes
var metadata_generator: Node

func _ready():
	# Conectar con metadata generator si existe
	metadata_generator = get_node_or_null("../MetadataGenerator")
	if not metadata_generator:
		# Crear instancia si no existe
		metadata_generator = preload("res://scripts/export/metadata_generator.gd").new()
		add_child(metadata_generator)

# === FUNCIONES DE GESTIÓN DE FRAMES ===

func add_frame(frame_data: Dictionary):
	"""Añadir frame a la colección"""
	var animation_name = frame_data.animation
	
	if not animation_name in frames_collection:
		frames_collection[animation_name] = []
	
	frames_collection[animation_name].append(frame_data)
	print("✅ Frame añadido: %s dir:%d frame:%d" % [animation_name, frame_data.direction, frame_data.frame])

func clear_frames(animation_name: String = ""):
	"""Limpiar frames de animación específica o todas"""
	if animation_name.is_empty():
		frames_collection.clear()
		print("🗑️ Todos los frames limpiados")
	else:
		frames_collection.erase(animation_name)
		print("🗑️ Frames de '%s' limpiados" % animation_name)

func get_available_animations() -> Array:
	"""Obtener lista de animaciones con frames disponibles"""
	return frames_collection.keys()

func has_frames(animation_name: String) -> bool:
	"""Verificar si hay frames para una animación"""
	return animation_name in frames_collection and frames_collection[animation_name].size() > 0

# === FUNCIÓN PRINCIPAL DE EXPORTACIÓN ===

func export_sprite_sheets(export_config: Dictionary):
	"""Exportar sprite sheets según configuración"""
	print("🚀 INICIANDO EXPORTACIÓN DE SPRITE SHEETS")
	current_export_config = export_config
	
	# Validar configuración
	if not _validate_export_config():
		return
	
	# Crear carpeta de salida
	var output_folder = export_config.output_folder
	if not DirAccess.dir_exists_absolute(output_folder):
		DirAccess.make_dir_recursive_absolute(output_folder)
	
	# Determinar animaciones a exportar
	var animations_to_export: Array = []
	
	match export_config.animation_mode:
		"current":
			# Solo la animación actual
			var current_anim = export_config.get("current_animation", "")
			if has_frames(current_anim):
				animations_to_export.append(current_anim)
			else:
				emit_signal("export_failed", "No hay frames para la animación actual: " + current_anim)
				return
		
		"all":
			# Todas las animaciones disponibles
			animations_to_export = get_available_animations()
			if animations_to_export.is_empty():
				emit_signal("export_failed", "No hay animaciones con frames para exportar")
				return
		
		"selected":
			# Animaciones seleccionadas
			animations_to_export = export_config.get("selected_animations", [])
	
	print("📋 Animaciones a exportar: %s" % str(animations_to_export))
	
	# Exportar cada animación
	var total_animations = animations_to_export.size()
	for i in range(total_animations):
		var animation_name = animations_to_export[i]
		
		emit_signal("export_progress", i + 1, total_animations, "Exportando: " + animation_name)
		
		var success = export_single_spritesheet(animation_name, output_folder)
		if not success:
			emit_signal("export_failed", "Error exportando: " + animation_name)
			return
		
		# Pequeña pausa para no saturar el sistema
		await get_tree().process_frame
	
	print("✅ EXPORTACIÓN COMPLETADA")
	emit_signal("export_complete", output_folder)

func export_single_spritesheet(animation_name: String, output_folder: String) -> bool:
	"""Exportar sprite sheet de una animación específica"""
	print("--- EXPORTANDO SPRITE SHEET: %s ---" % animation_name)
	
	if not has_frames(animation_name):
		print("❌ No hay frames para: %s" % animation_name)
		return false
	
	var frames = frames_collection[animation_name]
	
	# Organizar frames por dirección
	var frames_by_direction = _organize_frames_by_direction(frames)
	print("📐 Organizados en %d direcciones" % frames_by_direction.size())
	
	# Determinar dimensiones del spritesheet
	var sprite_size = frames[0].image.get_size()
	var directions_count = frames_by_direction.size()
	var max_frames_per_direction = 0
	
	# Encontrar el máximo número de frames por dirección
	for direction in frames_by_direction:
		var frame_count = frames_by_direction[direction].size()
		if frame_count > max_frames_per_direction:
			max_frames_per_direction = frame_count
	
	print("📏 Sprite size: %s, Direcciones: %d, Max frames: %d" % [sprite_size, directions_count, max_frames_per_direction])
	
	# Calcular layout del spritesheet
	var layout = _calculate_spritesheet_layout(directions_count, max_frames_per_direction)
	var sheet_width = layout.columns * sprite_size.x
	var sheet_height = layout.rows * sprite_size.y
	
	print("🖼️ Spritesheet final: %dx%d (%d cols x %d rows)" % [sheet_width, sheet_height, layout.columns, layout.rows])
	
	# Crear imagen del spritesheet
	var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	spritesheet.fill(Color(0, 0, 0, 0))  # Fondo transparente
	
	# Colocar frames en el spritesheet
	var current_row = 0
	var direction_keys = frames_by_direction.keys()
	direction_keys.sort()  # Ordenar direcciones numéricamente
	
	for direction_key in direction_keys:
		var direction_frames = frames_by_direction[direction_key]
		direction_frames.sort_custom(_sort_frames_by_number)
		
		print("  📍 Procesando dirección %d con %d frames" % [direction_key, direction_frames.size()])
		
		for frame_idx in range(direction_frames.size()):
			var frame_data = direction_frames[frame_idx]
			var x = frame_idx * sprite_size.x
			var y = current_row * sprite_size.y
			
			# Verificar que no nos salimos del spritesheet
			if x + sprite_size.x <= sheet_width and y + sprite_size.y <= sheet_height:
				# Copiar frame al spritesheet
				spritesheet.blit_rect(
					frame_data.image,
					Rect2i(0, 0, sprite_size.x, sprite_size.y),
					Vector2i(x, y)
				)
				print("    ✅ Frame %d colocado en (%d, %d)" % [frame_idx, x, y])
			else:
				print("    ❌ Frame %d fuera de límites" % frame_idx)
		
		current_row += 1
	
	# Guardar spritesheet
	var filename = _sanitize_filename(animation_name) + "_spritesheet.png"
	var file_path = output_folder.path_join(filename)
	
	print("💾 Guardando spritesheet en: %s" % file_path)
	
	var error = spritesheet.save_png(file_path)
	if error != OK:
		print("❌ Error al guardar PNG: " + str(error))
		return false
	
	# Generar metadata si está habilitado
	if current_export_config.get("generate_metadata", true):
		_generate_metadata_for_animation(animation_name, frames_by_direction, sprite_size, layout, output_folder)
	
	print("✅ Spritesheet '%s' exportado exitosamente" % animation_name)
	return true

# === FUNCIONES AUXILIARES ===

func _organize_frames_by_direction(frames: Array) -> Dictionary:
	"""Organizar frames por dirección"""
	var by_direction = {}
	
	for frame_data in frames:
		var direction = frame_data.direction
		
		if not direction in by_direction:
			by_direction[direction] = []
		
		by_direction[direction].append(frame_data)
	
	return by_direction

func _sort_frames_by_number(a: Dictionary, b: Dictionary) -> bool:
	"""Ordenar frames por número de frame"""
	return a.frame < b.frame

func _calculate_spritesheet_layout(directions: int, frames_per_direction: int) -> Dictionary:
	"""Calcular layout óptimo del spritesheet"""
	# Layout simple: frames horizontalmente, direcciones verticalmente
	return {
		"columns": frames_per_direction,
		"rows": directions,
		"type": "grid"
	}

func _sanitize_filename(filename: String) -> String:
	"""Limpiar nombre de archivo de caracteres problemáticos"""
	var sanitized = filename.replace(" ", "_")
	sanitized = sanitized.replace("/", "_")
	sanitized = sanitized.replace("\\", "_")
	sanitized = sanitized.replace(":", "_")
	sanitized = sanitized.replace("*", "_")
	sanitized = sanitized.replace("?", "_")
	sanitized = sanitized.replace("\"", "_")
	sanitized = sanitized.replace("<", "_")
	sanitized = sanitized.replace(">", "_")
	sanitized = sanitized.replace("|", "_")
	return sanitized

func _generate_metadata_for_animation(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2i, layout: Dictionary, output_folder: String):
	"""Generar archivos de metadata para la animación"""
	print("📄 Generando metadata para: %s" % animation_name)
	
	# Estructura de metadata
	var metadata = {
		"animation_name": animation_name,
		"sprite_size": {
			"width": sprite_size.x,
			"height": sprite_size.y
		},
		"spritesheet_size": {
			"width": layout.columns * sprite_size.x,
			"height": layout.rows * sprite_size.y
		},
		"layout": layout,
		"directions": [],
		"total_frames": 0,
		"fps": current_export_config.get("fps", 12),
		"export_date": Time.get_datetime_string_from_system()
	}
	
	# Añadir información de cada dirección
	var direction_keys = frames_by_direction.keys()
	direction_keys.sort()
	
	var row_index = 0
	for direction_key in direction_keys:
		var direction_frames = frames_by_direction[direction_key]
		direction_frames.sort_custom(_sort_frames_by_number)
		
		var direction_data = {
			"index": direction_key,
			"angle": direction_key * (360.0 / frames_by_direction.size()),
			"frame_count": direction_frames.size(),
			"row": row_index,
			"frames": []
		}
		
		# Añadir información de cada frame
		for frame_idx in range(direction_frames.size()):
			var frame_info = {
				"index": frame_idx,
				"x": frame_idx * sprite_size.x,
				"y": row_index * sprite_size.y,
				"width": sprite_size.x,
				"height": sprite_size.y
			}
			direction_data.frames.append(frame_info)
		
		metadata.directions.append(direction_data)
		metadata.total_frames += direction_frames.size()
		row_index += 1
	
	# Guardar metadata JSON
	var json_path = output_folder.path_join(_sanitize_filename(animation_name) + "_metadata.json")
	_save_json_metadata(metadata, json_path)
	
	# Generar formatos adicionales si están habilitados
	if metadata_generator:
		var formats = current_export_config.get("metadata_formats", ["json"])
		var base_path = output_folder.path_join(_sanitize_filename(animation_name))
		
		if "unity" in formats:
			metadata_generator.generate_unity_metadata(metadata, base_path)
		if "web" in formats:
			metadata_generator.generate_web_metadata(metadata, base_path)
		if "css" in formats:
			metadata_generator.generate_css_sprites(metadata, base_path)

func _save_json_metadata(metadata: Dictionary, file_path: String):
	"""Guardar metadata en formato JSON"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(metadata, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Metadata JSON guardado: %s" % file_path)
	else:
		print("❌ Error guardando metadata JSON: %s" % file_path)

func _validate_export_config() -> bool:
	"""Validar configuración de exportación"""
	if not current_export_config.has("output_folder"):
		emit_signal("export_failed", "Carpeta de destino no especificada")
		return false
	
	if not current_export_config.has("animation_mode"):
		emit_signal("export_failed", "Modo de animación no especificado")
		return false
	
	var output_folder = current_export_config.output_folder
	if output_folder.is_empty():
		emit_signal("export_failed", "Carpeta de destino vacía")
		return false
	
	# Verificar permisos de escritura
	var test_file = output_folder.path_join("test_write.tmp")
	var file = FileAccess.open(test_file, FileAccess.WRITE)
	if file:
		file.close()
		DirAccess.remove_absolute(test_file)
		print("✅ Permisos de escritura verificados")
	else:
		emit_signal("export_failed", "Sin permisos de escritura en: " + output_folder)
		return false
	
	return true

# === FUNCIONES DE INFORMACIÓN ===

func get_export_stats() -> Dictionary:
	"""Obtener estadísticas de la colección actual"""
	var stats = {
		"animations": frames_collection.size(),
		"total_frames": 0,
		"directions": {},
		"sprite_sizes": {}
	}
	
	for animation_name in frames_collection:
		var frames = frames_collection[animation_name]
		stats.total_frames += frames.size()
		
		for frame_data in frames:
			# Contar direcciones
			var dir = frame_data.direction
			if not dir in stats.directions:
				stats.directions[dir] = 0
			stats.directions[dir] += 1
			
			# Contar tamaños de sprite
			var size_key = "%dx%d" % [frame_data.image.get_width(), frame_data.image.get_height()]
			if not size_key in stats.sprite_sizes:
				stats.sprite_sizes[size_key] = 0
			stats.sprite_sizes[size_key] += 1
	
	return stats

func estimate_export_time(config: Dictionary) -> float:
	"""Estimar tiempo de exportación en segundos"""
	var animations_count = 1
	if config.animation_mode == "all":
		animations_count = frames_collection.size()
	elif config.animation_mode == "selected":
		animations_count = config.get("selected_animations", []).size()
	
	# Estimación: ~1-3 segundos por animación dependiendo del tamaño
	var avg_frames_per_animation = 50  # Estimación
	var time_per_frame = 0.02  # 20ms por frame
	
	return animations_count * avg_frames_per_animation * time_per_frame
