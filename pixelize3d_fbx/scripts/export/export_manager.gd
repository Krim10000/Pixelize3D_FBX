# scripts/export/export_manager.gd
extends Node

# Input: Frames renderizados y configuración de exportación
# Output: Archivos PNG de spritesheets y JSON con metadata

signal export_complete(file_path: String)
signal export_failed(error: String)
signal export_progress(progress: float)

var frames_collection: Dictionary = {} # animation_name -> Array of frame_data
var export_settings: Dictionary = {}

func add_frame(frame_data: Dictionary):
	var animation_name = frame_data.animation
	
	if not animation_name in frames_collection:
		frames_collection[animation_name] = []
	
	frames_collection[animation_name].append(frame_data)
#
#func export_spritesheet(animation_name: String, output_folder: String):
	#if not animation_name in frames_collection:
		#emit_signal("export_failed", "No hay frames para la animación: " + animation_name)
		#return
	#
	#print("=== EXPORTANDO SPRITESHEET ===")
	#print("Animación: %s" % animation_name)
	#print("Frames totales: %d" % frames_collection[animation_name].size())
	#
	## Crear carpeta de salida si no existe
	#var dir = DirAccess.open(output_folder)
	#if not dir:
		#DirAccess.make_dir_recursive_absolute(output_folder)
	#
	#var frames = frames_collection[animation_name]
	#
	## Organizar frames por dirección
	#var frames_by_direction = _organize_frames_by_direction(frames)
	#
	#print("Frames organizados por dirección:")
	#for direction in frames_by_direction.keys():
		#print("  - Dirección %d: %d frames" % [direction, frames_by_direction[direction].size()])
	#
	## Determinar dimensiones del spritesheet
	#var sprite_size = frames[0].image.get_size()
	#var directions_count = frames_by_direction.size()
	#
	## CORREGIDO: Obtener frames_per_direction del Dictionary
	#var frames_per_direction = 1
	#if directions_count > 0:
		#var first_direction_key = frames_by_direction.keys()[0]
		#frames_per_direction = frames_by_direction[first_direction_key].size()
	#
	#print("Dimensiones del spritesheet:")
	#print("  - Tamaño de sprite: %dx%d" % [sprite_size.x, sprite_size.y])
	#print("  - Direcciones: %d" % directions_count)
	#print("  - Frames por dirección: %d" % frames_per_direction)
	#
	## Calcular layout del spritesheet
	#var layout = _calculate_spritesheet_layout(directions_count, frames_per_direction)
	#var sheet_width = layout.columns * sprite_size.x
	#var sheet_height = layout.rows * sprite_size.y
	#
	#print("  - Spritesheet final: %dx%d" % [sheet_width, sheet_height])
	#
	## Crear imagen del spritesheet
	#var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	#spritesheet.fill(Color(0, 0, 0, 0))  # Fondo transparente
	#
	## CORREGIDO: Colocar cada frame en el spritesheet
	#var current_row = 0
	#var direction_keys = frames_by_direction.keys()
	#direction_keys.sort()  # Ordenar direcciones
	#
	#for direction_key in direction_keys:
		#var direction_frames = frames_by_direction[direction_key]
		#
		#print("Procesando dirección %d con %d frames" % [direction_key, direction_frames.size()])
		#
		#for frame_idx in range(direction_frames.size()):
			#var frame_data = direction_frames[frame_idx]
			#var x = frame_idx * sprite_size.x
			#var y = current_row * sprite_size.y
			#
			#print("  - Frame %d en posición (%d, %d)" % [frame_idx, x, y])
			#
			## Copiar frame al spritesheet
			#spritesheet.blit_rect(
				#frame_data.image,
				#Rect2i(0, 0, sprite_size.x, sprite_size.y),
				#Vector2i(x, y)
			#)
		#
		#current_row += 1
	#
	## Guardar spritesheet
	#var filename = _sanitize_filename(animation_name) + "_spritesheet.png"
	#var file_path = output_folder.path_join(filename)
	#
	#print("Guardando spritesheet en: %s" % file_path)
	#
	#var error = spritesheet.save_png(file_path)
	#if error != OK:
		#emit_signal("export_failed", "Error al guardar PNG: " + str(error))
		#return
	#
	## Generar metadata
	#var metadata = _generate_metadata(animation_name, frames_by_direction, sprite_size, layout)
	#var metadata_path = output_folder.path_join(_sanitize_filename(animation_name) + "_metadata.json")
	#_save_metadata(metadata, metadata_path)
	#
	#print("✓ Spritesheet exportado exitosamente")
	#
	## Limpiar frames procesados
	#frames_collection.erase(animation_name)
	#
	#emit_signal("export_complete", file_path)
#

# scripts/export/export_manager.gd
# Modificar la función export_spritesheet (alrededor de la línea 50)

func export_spritesheet(animation_name: String, output_folder: String):
	if not animation_name in frames_collection:
		emit_signal("export_failed", "No hay frames para la animación: " + animation_name)
		return
	
	# Crear carpeta de salida si no existe
	var dir = DirAccess.open(output_folder)
	if not dir:
		DirAccess.make_dir_recursive_absolute(output_folder)
	
	var frames = frames_collection[animation_name]
	
	# Organizar frames por dirección
	var frames_by_direction = _organize_frames_by_direction(frames)
	
	# Determinar dimensiones del spritesheet
	var sprite_size = frames[0].image.get_size()
	var directions_count = frames_by_direction.size()
	var frames_per_direction = frames_by_direction[0].size() if directions_count > 0 else 1
	
	# CAMBIO: Ahora las direcciones van en columnas y frames en filas
	var sheet_width = directions_count * sprite_size.x  # Direcciones en X
	var sheet_height = frames_per_direction * sprite_size.y  # Frames en Y
	
	# Crear imagen del spritesheet
	var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	
	# CAMBIO: Reorganizar el loop para colocar direcciones en columnas
	for direction in range(directions_count):
		var direction_frames = frames_by_direction[direction]
		
		for frame_idx in range(direction_frames.size()):
			var frame_data = direction_frames[frame_idx]
			var x = direction * sprite_size.x  # Dirección determina columna
			var y = frame_idx * sprite_size.y  # Frame determina fila
			
			# Copiar frame al spritesheet
			spritesheet.blit_rect(
				frame_data.image,
				Rect2i(0, 0, sprite_size.x, sprite_size.y),
				Vector2i(x, y)
			)
	
func _organize_frames_by_direction(frames: Array) -> Dictionary:
	var by_direction = {}
	
	for frame_data in frames:
		var direction = frame_data.direction
		
		if not direction in by_direction:
			by_direction[direction] = []
		
		by_direction[direction].append(frame_data)
	
	# Ordenar frames dentro de cada dirección
	for direction in by_direction:
		by_direction[direction].sort_custom(_sort_by_frame_number)
	
	return by_direction

func _sort_by_frame_number(a: Dictionary, b: Dictionary) -> bool:
	return a.frame < b.frame

#func _calculate_spritesheet_layout(directions: int, frames_per_direction: int) -> Dictionary:
	## Layout simple: una fila por dirección
	#return {
		#"rows": directions,
		#"columns": frames_per_direction,
		#"total_frames": directions * frames_per_direction
	#}

func _calculate_spritesheet_layout(directions: int, frames_per_direction: int) -> Dictionary:
	# CAMBIO: Layout con direcciones en columnas y frames en filas
	return {
		"columns": directions,  # Direcciones en columnas
		"rows": frames_per_direction,  # Frames en filas
		"total_frames": directions * frames_per_direction
	}

func _generate_metadata(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary) -> Dictionary:
	var metadata = {
		"name": animation_name,
		"sprite_size": {
			"width": int(sprite_size.x),
			"height": int(sprite_size.y)
		},
		"spritesheet_size": {
			"width": layout.columns * int(sprite_size.x),
			"height": layout.rows * int(sprite_size.y)
		},
		"layout": layout,
		"directions": [],
		"total_frames": layout.total_frames,
		"fps": export_settings.get("fps", 12),
		"export_date": Time.get_datetime_string_from_system()
	}
	
	# CORREGIDO: Información por dirección
	var direction_keys = frames_by_direction.keys()
	direction_keys.sort()
	
	var row_index = 0
	for direction_key in direction_keys:
		var direction_frames = frames_by_direction[direction_key]
		var direction_data = {
			"index": direction_key,
			"angle": direction_frames[0].angle if direction_frames.size() > 0 else 0.0,
			"frame_count": direction_frames.size(),
			"frames": []
		}
		
		# Información de cada frame
		for i in range(direction_frames.size()):
			direction_data.frames.append({
				"index": i,
				"position": {
					"x": i * int(sprite_size.x),
					"y": row_index * int(sprite_size.y)
				}
			})
		
		metadata.directions.append(direction_data)
		row_index += 1
	
	return metadata

func _save_metadata(metadata: Dictionary, file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata, "\t"))
		file.close()
		print("✓ Metadata guardada en: %s" % file_path)
	else:
		push_error("No se pudo crear archivo de metadata: " + file_path)

func _sanitize_filename(original_filename: String) -> String:
	var invalid_characters = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
	var sanitized_filename = original_filename
	
	for character in invalid_characters:
		sanitized_filename = sanitized_filename.replace(character, "_")
	
	return sanitized_filename

# Función para exportar múltiples animaciones en batch
func export_all_animations(output_folder: String, settings: Dictionary):
	export_settings = settings
	
	var total_animations = frames_collection.size()
	var current = 0
	
	for animation_name in frames_collection:
		export_spritesheet(animation_name, output_folder)
		current += 1
		emit_signal("export_progress", float(current) / float(total_animations))

# Función adicional para exportar como frames individuales
func export_individual_frames(animation_name: String, output_folder: String):
	if not animation_name in frames_collection:
		emit_signal("export_failed", "No hay frames para la animación: " + animation_name)
		return
	
	var frames = frames_collection[animation_name]
	var anim_folder = output_folder.path_join(_sanitize_filename(animation_name))
	
	# Crear carpeta para la animación
	DirAccess.make_dir_recursive_absolute(anim_folder)
	
	# Guardar cada frame individual
	for frame_data in frames:
		var filename = "frame_dir%02d_f%03d.png" % [frame_data.direction, frame_data.frame]
		var file_path = anim_folder.path_join(filename)
		
		var error = frame_data.image.save_png(file_path)
		if error != OK:
			push_error("Error al guardar frame: " + file_path)
	
	emit_signal("export_complete", anim_folder)
