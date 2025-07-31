# pixelize3d_fbx/scripts/export/export_manager.gd
# Export Manager MEJORADO con integración al pipeline y debugging mejorado
# Input: Frames renderizados desde pipeline y configuración de exportación
# Output: Sprite sheets PNG y archivos de metadata con comunicación optimizada al pipeline

extends Node

# Señales
signal export_complete(file_path: String)
signal export_failed(error: String)
signal export_progress(current: int, total: int, message: String)

# ✅ NUEVA: Señal específica para pipeline
signal animation_export_complete(animation_name: String, file_path: String)
signal batch_export_started(total_animations: int)
signal batch_export_complete(successful_count: int, total_count: int)

# Colección de frames por animación
var frames_collection: Dictionary = {}
var current_export_config: Dictionary = {}

# ✅ NUEVO: Estado del exportador para pipeline
var is_exporting: bool = false
var current_batch_count: int = 0
var total_batch_count: int = 0

# Referencias a otros componentes
var metadata_generator: Node

func _ready():
	print("📤 ExportManager MEJORADO inicializado")
	# Conectar con metadata generator si existe
	metadata_generator = get_node_or_null("../MetadataGenerator")
	if not metadata_generator:
		print("🔄 Creando MetadataGenerator...")
		var metadata_script = load("res://scripts/export/metadata_generator.gd")
		if metadata_script:
			metadata_generator = metadata_script.new()
			metadata_generator.name = "MetadataGenerator"
			add_child(metadata_generator)
			print("✅ MetadataGenerator creado")
		else:
			print("⚠️ Script MetadataGenerator no encontrado")

# ========================================================================
# FUNCIONES DE GESTIÓN DE FRAMES (MEJORADAS)
# ========================================================================

func add_frame(frame_data: Dictionary):
	"""Añadir frame a la colección con validación mejorada y notificación al pipeline"""
	if not frame_data.has("animation"):
		print("❌ Frame sin nombre de animación")
		return
	
	var animation_name = frame_data.animation
	
	if not animation_name in frames_collection:
		frames_collection[animation_name] = []
		print("📁 Nueva colección creada para: %s" % animation_name)
	
	frames_collection[animation_name].append(frame_data)
	
	# ✅ MEJORADO: Log más detallado para debugging del pipeline
	var total_frames = frames_collection[animation_name].size()
	var direction = frame_data.get("direction", 0)
	var frame_num = frame_data.get("frame", 0)
	
	# Calcular estadísticas rápidas para el pipeline
	var directions_count = _count_directions_for_animation(animation_name)
	
	print("✅ Frame añadido: %s dir:%d frame:%d (total: %d frames, %d direcciones)" % [
		animation_name, direction, frame_num, total_frames, directions_count
	])

func _count_directions_for_animation(animation_name: String) -> int:
	"""Contar direcciones únicas para una animación específica"""
	if not frames_collection.has(animation_name):
		return 0
	
	var directions = []
	for frame_data in frames_collection[animation_name]:
		var direction = frame_data.get("direction", 0)
		if not direction in directions:
			directions.append(direction)
	
	return directions.size()

func clear_frames(animation_name: String = ""):
	"""Limpiar frames de animación específica o todas"""
	if animation_name.is_empty():
		var total_frames = 0
		for anim in frames_collection:
			total_frames += frames_collection[anim].size()
		frames_collection.clear()
		print("🗑️ Todos los frames limpiados (total: %d)" % total_frames)
	else:
		if animation_name in frames_collection:
			var count = frames_collection[animation_name].size()
			frames_collection.erase(animation_name)
			print("🗑️ Frames de '%s' limpiados (%d frames)" % [animation_name, count])
		else:
			print("⚠️ No hay frames para limpiar: %s" % animation_name)

func get_available_animations() -> Array:
	"""Obtener lista de animaciones con frames disponibles"""
	return frames_collection.keys()

func has_frames(animation_name: String) -> bool:
	"""Verificar si hay frames para una animación"""
	var has_data = animation_name in frames_collection and frames_collection[animation_name].size() > 0
	if not has_data:
		print("⚠️ No hay frames para '%s'. Disponibles: %s" % [animation_name, get_available_animations()])
	return has_data

# ✅ NUEVAS: Funciones específicas para el pipeline

func get_frame_count_for_animation(animation_name: String) -> int:
	"""Obtener cantidad de frames para una animación específica"""
	if not frames_collection.has(animation_name):
		return 0
	return frames_collection[animation_name].size()

func get_directions_for_animation(animation_name: String) -> Array:
	"""Obtener lista de direcciones disponibles para una animación"""
	if not frames_collection.has(animation_name):
		return []
	
	var directions = []
	for frame_data in frames_collection[animation_name]:
		var direction = frame_data.get("direction", 0)
		if not direction in directions:
			directions.append(direction)
	
	directions.sort()
	return directions

func is_animation_complete(animation_name: String, expected_directions: int, expected_frames_per_direction: int = -1) -> bool:
	"""Verificar si una animación está completa según expectativas"""
	if not has_frames(animation_name):
		return false
	
	var available_directions = get_directions_for_animation(animation_name)
	if available_directions.size() != expected_directions:
		print("⚠️ Animación '%s' incompleta: %d/%d direcciones" % [animation_name, available_directions.size(), expected_directions])
		return false
	
	# Si se especifica frames por dirección, verificar
	if expected_frames_per_direction > 0:
		var frames_by_direction = _organize_frames_by_direction(frames_collection[animation_name])
		for direction in available_directions:
			if frames_by_direction[direction].size() != expected_frames_per_direction:
				print("⚠️ Animación '%s' dirección %d incompleta: %d/%d frames" % [
					animation_name, direction, frames_by_direction[direction].size(), expected_frames_per_direction
				])
				return false
	
	return true

# ========================================================================
# FUNCIÓN PRINCIPAL DE EXPORTACIÓN (MEJORADA PARA PIPELINE)
# ========================================================================

func export_sprite_sheets(export_config: Dictionary):
	"""Exportar sprite sheets según configuración con mejor integración al pipeline"""
	print("\n🚀 === INICIANDO EXPORTACIÓN DE SPRITE SHEETS (PIPELINE) ===")
	
	# ✅ MEJORADO: Estado de exportación para pipeline
	if is_exporting:
		print("⚠️ Ya hay una exportación en progreso")
		emit_signal("export_failed", "Exportación ya en progreso")
		return
	
	is_exporting = true
	current_export_config = export_config
	
	# Debug de configuración
	print("📋 Configuración de exportación:")
	for key in export_config:
		print("  %s: %s" % [key, export_config[key]])
	
	# Debug de frames disponibles
	print("📊 Frames disponibles:")
	for anim_name in frames_collection:
		var frame_count = frames_collection[anim_name].size()
		var directions_count = _count_directions_for_animation(anim_name)
		print("  %s: %d frames (%d direcciones)" % [anim_name, frame_count, directions_count])
	
	if not _validate_export_config():
		_finish_export(false, "Configuración inválida")
		return
	
	# Crear carpeta de salida
	var output_folder = export_config.get("output_folder", "res://output/")
	print("📁 Carpeta de salida: %s" % output_folder)
	
	if not _ensure_output_folder(output_folder):
		_finish_export(false, "No se pudo crear carpeta de salida")
		return
	
	# Determinar animaciones a exportar
	var animations_to_export = _get_animations_to_export(export_config)
	
	if animations_to_export.is_empty():
		_finish_export(false, "No hay animaciones para exportar")
		return
	
	print("📋 Animaciones a exportar: %s" % str(animations_to_export))
	
	# ✅ MEJORADO: Estado de batch para el pipeline
	total_batch_count = animations_to_export.size()
	current_batch_count = 0
	
	if total_batch_count > 1:
		emit_signal("batch_export_started", total_batch_count)
	
	# Exportar cada animación
	var exported_successfully = 0
	
	for i in range(animations_to_export.size()):
		var animation_name = animations_to_export[i]
		current_batch_count = i + 1
		
		emit_signal("export_progress", current_batch_count, total_batch_count, "Exportando: " + animation_name)
		
		var success = _export_single_spritesheet(animation_name, output_folder)
		if success:
			exported_successfully += 1
			print("✅ Exportación exitosa: %s" % animation_name)
			
			# ✅ NUEVA: Señal específica por animación para el pipeline
			var file_path = output_folder.path_join(animation_name + "_spritesheet.png")
			emit_signal("animation_export_complete", animation_name, file_path)
		else:
			print("❌ Falló exportación de: %s" % animation_name)
			# No abortar, continuar con las demás
		
		# Pequeña pausa para no saturar el sistema
		await get_tree().process_frame
	
	# ✅ MEJORADO: Resultado final con señales específicas para batch
	if total_batch_count > 1:
		emit_signal("batch_export_complete", exported_successfully, total_batch_count)
	
	# Resultado final
	if exported_successfully == total_batch_count:
		print("✅ EXPORTACIÓN COMPLETADA - Todas las animaciones exportadas")
		_finish_export(true, output_folder)
	elif exported_successfully > 0:
		print("⚠️ EXPORTACIÓN PARCIAL - %d/%d animaciones exportadas" % [exported_successfully, total_batch_count])
		_finish_export(true, output_folder)  # Consideramos éxito parcial como éxito
	else:
		print("❌ EXPORTACIÓN FALLIDA - Ninguna animación exportada")
		_finish_export(false, "No se pudo exportar ninguna animación")

func _finish_export(success: bool, result: String):
	"""Finalizar exportación con limpieza de estado"""
	is_exporting = false
	current_batch_count = 0
	total_batch_count = 0
	
	if success:
		emit_signal("export_complete", result)
	else:
		emit_signal("export_failed", result)

func _validate_export_config() -> bool:
	"""Validar configuración de exportación"""
	var required_keys = ["output_folder"]
	
	for key in required_keys:
		if not current_export_config.has(key):
			print("❌ Falta parámetro requerido: %s" % key)
			return false
	
	print("✅ Configuración validada")
	return true

func _ensure_output_folder(output_folder: String) -> bool:
	"""Asegurar que la carpeta de salida existe"""
	# ✅ MEJORADO: Manejo de rutas tanto relativas como absolutas
	var absolute_path = output_folder
	if not output_folder.begins_with("/") and not output_folder.contains("://"):
		absolute_path = ProjectSettings.globalize_path(output_folder)
	
	if DirAccess.dir_exists_absolute(absolute_path):
		print("✅ Carpeta de salida existe: %s" % absolute_path)
		return true
	
	print("📁 Creando carpeta de salida: %s" % absolute_path)
	var error = DirAccess.make_dir_recursive_absolute(absolute_path)
	
	if error == OK:
		print("✅ Carpeta creada exitosamente")
		return true
	else:
		print("❌ Error creando carpeta: %d" % error)
		return false

func _get_animations_to_export(export_config: Dictionary) -> Array:
	"""Determinar qué animaciones exportar"""
	var animations_to_export = []
	
	match export_config.get("animation_mode", "current"):
		"current":
			var current_anim = export_config.get("current_animation", "")
			print("🎯 Modo: animación current - %s" % current_anim)
			if has_frames(current_anim):
				animations_to_export.append(current_anim)
			else:
				print("❌ No hay frames para la animación actual: %s" % current_anim)
		
		"all":
			print("🎯 Modo: todas las animaciones")
			animations_to_export = get_available_animations()
			if animations_to_export.is_empty():
				print("❌ No hay animaciones con frames")
		
		"selected":
			print("🎯 Modo: animaciones seleccionadas")
			animations_to_export = export_config.get("selected_animations", [])
			# Filtrar solo las que tienen frames
			var valid_animations = []
			for anim in animations_to_export:
				if has_frames(anim):
					valid_animations.append(anim)
				else:
					print("⚠️ Animación seleccionada sin frames: %s" % anim)
			animations_to_export = valid_animations
	
	return animations_to_export

func _export_single_spritesheet(animation_name: String, output_folder: String) -> bool:
	"""Exportar sprite sheet de una animación específica con debugging mejorado"""
	print("\n--- EXPORTANDO SPRITE SHEET: %s ---" % animation_name)
	
	if not has_frames(animation_name):
		print("❌ No hay frames para: %s" % animation_name)
		return false
	
	var frames = frames_collection[animation_name]
	print("📊 Total de frames: %d" % frames.size())
	
	# Organizar frames por dirección
	var frames_by_direction = _organize_frames_by_direction(frames)
	print("📐 Organizados en %d direcciones" % frames_by_direction.size())
	
	# Debug de frames por dirección
	for direction in frames_by_direction:
		print("  Dirección %d: %d frames" % [direction, frames_by_direction[direction].size()])
	
	if frames_by_direction.is_empty():
		print("❌ No se pudieron organizar los frames por dirección")
		return false
	
	# Determinar dimensiones del spritesheet
	var sprite_size = frames[0].image.get_size()
	var directions_count = frames_by_direction.size()
	var max_frames_per_direction = 0
	
	# Encontrar el máximo número de frames por dirección
	for direction in frames_by_direction:
		var frame_count = frames_by_direction[direction].size()
		if frame_count > max_frames_per_direction:
			max_frames_per_direction = frame_count
	
	print("📏 Dimensiones: sprite=%s, direcciones=%d, max_frames=%d" % [sprite_size, directions_count, max_frames_per_direction])
	
	# Calcular layout del spritesheet
	var layout = _calculate_spritesheet_layout(directions_count, max_frames_per_direction)
	var sheet_width = layout.columns * sprite_size.x
	var sheet_height = layout.rows * sprite_size.y
	
	print("🖼️ Spritesheet final: %dx%d (%d cols x %d rows)" % [sheet_width, sheet_height, layout.columns, layout.rows])
	
	# Crear imagen del spritesheet
	var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	spritesheet.fill(Color(0, 0, 0, 0))  # Fondo transparente
	
	# Colocar frames en el spritesheet
	var frames_placed = _place_frames_in_spritesheet(spritesheet, frames_by_direction, sprite_size, layout)
	
	if frames_placed == 0:
		print("❌ No se pudo colocar ningún frame en el spritesheet")
		return false
	
	print("✅ %d frames colocados en el spritesheet" % frames_placed)
	
	# ✅ MEJORADO: Manejo de rutas mejorado
	var image_path = ""
	if output_folder.begins_with("/") or output_folder.contains("://"):
		image_path = output_folder.path_join(animation_name + "_spritesheet.png")
	else:
		image_path = ProjectSettings.globalize_path(output_folder).path_join(animation_name + "_spritesheet.png")
	
	var save_error = spritesheet.save_png(image_path)
	
	if save_error != OK:
		print("❌ Error guardando imagen: %d en %s" % [save_error, image_path])
		return false
	
	print("✅ Imagen guardada: %s" % image_path)
	
	# Generar metadatos si está disponible
	if metadata_generator and metadata_generator.has_method("generate_json"):
		var metadata_path = ""
		if output_folder.begins_with("/") or output_folder.contains("://"):
			metadata_path = output_folder.path_join(animation_name + "_metadata.json")
		else:
			metadata_path = ProjectSettings.globalize_path(output_folder).path_join(animation_name + "_metadata.json")
		
		var animation_data = _create_animation_metadata(animation_name, frames_by_direction, sprite_size, layout)
		
		metadata_generator.generate_json(animation_data, metadata_path)
		print("✅ Metadatos generados: %s" % metadata_path)
	
	print("--- FIN EXPORTACIÓN: %s ---\n" % animation_name)
	return true

func _organize_frames_by_direction(frames: Array) -> Dictionary:
	"""Organizar frames por dirección"""
	var frames_by_direction = {}
	
	for frame_data in frames:
		var direction = frame_data.get("direction", 0)
		
		if not direction in frames_by_direction:
			frames_by_direction[direction] = []
		
		frames_by_direction[direction].append(frame_data)
	
	# Ordenar frames dentro de cada dirección por número de frame
	for direction in frames_by_direction:
		frames_by_direction[direction].sort_custom(_sort_frames_by_number)
	
	return frames_by_direction

func _sort_frames_by_number(a: Dictionary, b: Dictionary) -> bool:
	"""Ordenar frames por número"""
	return a.get("frame", 0) < b.get("frame", 0)

func _calculate_spritesheet_layout(directions: int, max_frames: int) -> Dictionary:
	"""Calcular layout del spritesheet"""
	# Layout horizontal: una fila por dirección, frames en columnas
	return {
		"columns": max_frames,
		"rows": directions,
		"type": "grid"
	}

func _place_frames_in_spritesheet(spritesheet: Image, frames_by_direction: Dictionary, sprite_size: Vector2, _layout: Dictionary) -> int:
	"""Colocar frames en el spritesheet"""
	var frames_placed = 0
	var current_row = 0
	
	var direction_keys = frames_by_direction.keys()
	direction_keys.sort()  # Ordenar direcciones numéricamente
	
	for direction_key in direction_keys:
		var direction_frames = frames_by_direction[direction_key]
		
		print("  📍 Colocando dirección %d con %d frames" % [direction_key, direction_frames.size()])
		
		for frame_idx in range(direction_frames.size()):
			var frame_data = direction_frames[frame_idx]
			var x = frame_idx * sprite_size.x
			var y = current_row * sprite_size.y
			
			# Verificar que no nos salimos del spritesheet
			if x + sprite_size.x <= spritesheet.get_width() and y + sprite_size.y <= spritesheet.get_height():
				# Copiar frame al spritesheet
				var frame_image = frame_data.image
				#if frame_image and frame_image.get_size() == sprite_size:
				#Invalid operands 'Vector2i' and 'Vector2' in operator '=='.
				if frame_image and frame_image.get_size() == Vector2i(sprite_size):
					spritesheet.blit_rect(frame_image, Rect2(Vector2.ZERO, sprite_size), Vector2(x, y))
					frames_placed += 1
				else:
					print("⚠️ Frame inválido en dirección %d, frame %d" % [direction_key, frame_idx])
			else:
				print("⚠️ Frame fuera de bounds: x=%d, y=%d, límites=%dx%d" % [x, y, spritesheet.get_width(), spritesheet.get_height()])
		
		current_row += 1
	
	return frames_placed

func _create_animation_metadata(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary) -> Dictionary:
	"""Crear metadatos de la animación"""
	var directions_data = []
	
	for direction in frames_by_direction:
		directions_data.append({
			"index": direction,
			"frame_count": frames_by_direction[direction].size()
		})
	
	return {
		"name": animation_name,
		"sprite_size": {
			"width": sprite_size.x,
			"height": sprite_size.y
		},
		"layout": layout,
		"directions": directions_data,
		"total_frames": _count_total_frames(frames_by_direction),
		"exported_at": Time.get_datetime_string_from_system()
	}

func _count_total_frames(frames_by_direction: Dictionary) -> int:
	"""Contar total de frames"""
	var total = 0
	for direction in frames_by_direction:
		total += frames_by_direction[direction].size()
	return total

# ========================================================================
# FUNCIONES DE DEBUG Y UTILIDAD (MEJORADAS)
# ========================================================================

func debug_export_state():
	"""Debug del estado del export manager"""
	print("\n📤 === EXPORT MANAGER DEBUG (MEJORADO) ===")
	print("Estado de exportación: %s" % ("🔄 Activo" if is_exporting else "⏸️ Inactivo"))
	
	if is_exporting:
		print("Progreso batch: %d/%d animaciones" % [current_batch_count, total_batch_count])
	
	print("Animaciones con frames: %d" % frames_collection.size())
	
	for anim_name in frames_collection:
		var frames = frames_collection[anim_name]
		var directions_count = _count_directions_for_animation(anim_name)
		print("  %s: %d frames (%d direcciones)" % [anim_name, frames.size(), directions_count])
		
		# Mostrar distribución por direcciones
		var directions = {}
		for frame in frames:
			var dir = frame.get("direction", 0)
			if not dir in directions:
				directions[dir] = 0
			directions[dir] += 1
		
		for direction in directions:
			print("    Dirección %d: %d frames" % [direction, directions[direction]])
	
	print("==============================\n")

func get_export_stats() -> Dictionary:
	"""Obtener estadísticas de exportación mejoradas"""
	var total_frames = 0
	var directions_used = []
	var animations_stats = {}
	
	for anim_name in frames_collection:
		var frames = frames_collection[anim_name]
		total_frames += frames.size()
		
		var anim_directions = []
		for frame in frames:
			var direction = frame.get("direction", 0)
			if not direction in directions_used:
				directions_used.append(direction)
			if not direction in anim_directions:
				anim_directions.append(direction)
		
		animations_stats[anim_name] = {
			"frames": frames.size(),
			"directions": anim_directions.size()
		}
	
	return {
		"animations_count": frames_collection.size(),
		"total_frames": total_frames,
		"directions_used": directions_used.size(),
		"has_metadata_generator": metadata_generator != null,
		"is_exporting": is_exporting,
		"batch_progress": {
			"current": current_batch_count,
			"total": total_batch_count
		},
		"animations_stats": animations_stats
	}

# ✅ NUEVAS: Funciones públicas específicas para el pipeline

func get_export_status() -> Dictionary:
	"""Obtener estado actual de exportación para el pipeline"""
	return {
		"is_busy": is_exporting,
		"current_batch": current_batch_count,
		"total_batch": total_batch_count,
		"has_frames": not frames_collection.is_empty(),
		"available_animations": get_available_animations()
	}

func is_busy() -> bool:
	"""Verificar si el exportador está ocupado"""
	return is_exporting

func force_reset_export_state():
	"""Reset forzado del estado de exportación"""
	print("🚨 FORCE RESET: Estado de exportación")
	is_exporting = false
	current_batch_count = 0
	total_batch_count = 0
	current_export_config.clear()
	print("✅ Estado de exportación reseteado")

# ✅ NUEVA: Función para exportar una sola animación (API simplificada para pipeline)
func export_single_animation(animation_name: String, output_folder: String, config: Dictionary = {}) -> bool:
	"""API simplificada para exportar una sola animación - optimizada para pipeline"""
	if is_exporting:
		print("❌ Exportador ocupado")
		return false
	
	if not has_frames(animation_name):
		print("❌ No hay frames para '%s'" % animation_name)
		return false
	
	print("🚀 Exportación rápida: %s → %s" % [animation_name, output_folder])
	
	# Configuración mínima
	var export_config = {
		"output_folder": output_folder,
		"animation_mode": "current",
		"current_animation": animation_name,
		"generate_metadata": config.get("generate_metadata", true)
	}
	
	# Agregar configuraciones adicionales
	for key in config:
		export_config[key] = config[key]
	
	# Usar función de exportación principal
	export_sprite_sheets(export_config)
	
	return true
