## pixelize3d_fbx/scripts/export/export_manager.gd
## Export Manager MEJORADO con integración al pipeline y debugging mejorado
## Input: Frames renderizados desde pipeline y configuración de exportación
## Output: Sprite sheets PNG y archivos de metadata con comunicación optimizada al pipeline
#
#extends Node
#
## Señales
#signal export_complete(file_path: String)
#signal export_failed(error: String)
#signal export_progress(current: int, total: int, message: String)
#
## ✅ NUEVA: Señal específica para pipeline
#signal animation_export_complete(animation_name: String, file_path: String)
#signal batch_export_started(total_animations: int)
#signal batch_export_complete(successful_count: int, total_count: int)
#
## Colección de frames por animación
#var frames_collection: Dictionary = {}
#var current_export_config: Dictionary = {}
#
## ✅ NUEVO: Estado del exportador para pipeline
#var is_exporting: bool = false
#var current_batch_count: int = 0
#var total_batch_count: int = 0
#
## Referencias a otros componentes
#var metadata_generator: Node
#
#func _ready():
	#print("📤 ExportManager MEJORADO inicializado")
	## Conectar con metadata generator si existe
	#metadata_generator = get_node_or_null("../MetadataGenerator")
	#if not metadata_generator:
		#print("🔄 Creando MetadataGenerator...")
		#var metadata_script = load("res://scripts/export/metadata_generator.gd")
		#if metadata_script:
			#metadata_generator = metadata_script.new()
			#metadata_generator.name = "MetadataGenerator"
			#add_child(metadata_generator)
			#print("✅ MetadataGenerator creado")
		#else:
			#print("⚠️ Script MetadataGenerator no encontrado")
#
## ========================================================================
## FUNCIONES DE GESTIÓN DE FRAMES (MEJORADAS)
## ========================================================================
#
#func add_frame(frame_data: Dictionary):
	#"""Añadir frame a la colección con validación mejorada y notificación al pipeline"""
	#if not frame_data.has("animation"):
		#print("❌ Frame sin nombre de animación")
		#return
	#
	#var animation_name = frame_data.animation
	#
	#if not animation_name in frames_collection:
		#frames_collection[animation_name] = []
		#print("📁 Nueva colección creada para: %s" % animation_name)
	#
	#frames_collection[animation_name].append(frame_data)
	#
	## ✅ MEJORADO: Log más detallado para debugging del pipeline
	#var total_frames = frames_collection[animation_name].size()
	#var direction = frame_data.get("direction", 0)
	#var frame_num = frame_data.get("frame", 0)
	#
	## Calcular estadísticas rápidas para el pipeline
	#var directions_count = _count_directions_for_animation(animation_name)
	#
	#print("✅ Frame añadido: %s dir:%d frame:%d (total: %d frames, %d direcciones)" % [
		#animation_name, direction, frame_num, total_frames, directions_count
	#])
#
#func _count_directions_for_animation(animation_name: String) -> int:
	#"""Contar direcciones únicas para una animación específica"""
	#if not frames_collection.has(animation_name):
		#return 0
	#
	#var directions = []
	#for frame_data in frames_collection[animation_name]:
		#var direction = frame_data.get("direction", 0)
		#if not direction in directions:
			#directions.append(direction)
	#
	#return directions.size()
#
#func clear_frames(animation_name: String = ""):
	#"""Limpiar frames de animación específica o todas"""
	#if animation_name.is_empty():
		#var total_frames = 0
		#for anim in frames_collection:
			#total_frames += frames_collection[anim].size()
		#frames_collection.clear()
		#print("🗑️ Todos los frames limpiados (total: %d)" % total_frames)
	#else:
		#if animation_name in frames_collection:
			#var count = frames_collection[animation_name].size()
			#frames_collection.erase(animation_name)
			#print("🗑️ Frames de '%s' limpiados (%d frames)" % [animation_name, count])
		#else:
			#print("⚠️ No hay frames para limpiar: %s" % animation_name)
#
#func get_available_animations() -> Array:
	#"""Obtener lista de animaciones con frames disponibles"""
	#return frames_collection.keys()
#
#func has_frames(animation_name: String) -> bool:
	#"""Verificar si hay frames para una animación"""
	#var has_data = animation_name in frames_collection and frames_collection[animation_name].size() > 0
	#if not has_data:
		#print("⚠️ No hay frames para '%s'. Disponibles: %s" % [animation_name, get_available_animations()])
	#return has_data
#
## ✅ NUEVAS: Funciones específicas para el pipeline
#
#func get_frame_count_for_animation(animation_name: String) -> int:
	#"""Obtener cantidad de frames para una animación específica"""
	#if not frames_collection.has(animation_name):
		#return 0
	#return frames_collection[animation_name].size()
#
#func get_directions_for_animation(animation_name: String) -> Array:
	#"""Obtener lista de direcciones disponibles para una animación"""
	#if not frames_collection.has(animation_name):
		#return []
	#
	#var directions = []
	#for frame_data in frames_collection[animation_name]:
		#var direction = frame_data.get("direction", 0)
		#if not direction in directions:
			#directions.append(direction)
	#
	#directions.sort()
	#return directions
#
#func is_animation_complete(animation_name: String, expected_directions: int, expected_frames_per_direction: int = -1) -> bool:
	#"""Verificar si una animación está completa según expectativas"""
	#if not has_frames(animation_name):
		#return false
	#
	#var available_directions = get_directions_for_animation(animation_name)
	#if available_directions.size() != expected_directions:
		#print("⚠️ Animación '%s' incompleta: %d/%d direcciones" % [animation_name, available_directions.size(), expected_directions])
		#return false
	#
	## Si se especifica frames por dirección, verificar
	#if expected_frames_per_direction > 0:
		#var frames_by_direction = _organize_frames_by_direction(frames_collection[animation_name])
		#for direction in available_directions:
			#if frames_by_direction[direction].size() != expected_frames_per_direction:
				#print("⚠️ Animación '%s' dirección %d incompleta: %d/%d frames" % [
					#animation_name, direction, frames_by_direction[direction].size(), expected_frames_per_direction
				#])
				#return false
	#
	#return true
#
## ========================================================================
## FUNCIÓN PRINCIPAL DE EXPORTACIÓN (MEJORADA PARA PIPELINE)
## ========================================================================
#
#func export_sprite_sheets(export_config: Dictionary):
	#"""Exportar sprite sheets según configuración con mejor integración al pipeline"""
	#print("\n🚀 === INICIANDO EXPORTACIÓN DE SPRITE SHEETS (PIPELINE) ===")
	#
	## ✅ MEJORADO: Estado de exportación para pipeline
	#if is_exporting:
		#print("⚠️ Ya hay una exportación en progreso")
		#emit_signal("export_failed", "Exportación ya en progreso")
		#return
	#
	#is_exporting = true
	#current_export_config = export_config
	#
	## Debug de configuración
	#print("📋 Configuración de exportación:")
	#for key in export_config:
		#print("  %s: %s" % [key, export_config[key]])
	#
	## Debug de frames disponibles
	#print("📊 Frames disponibles:")
	#for anim_name in frames_collection:
		#var frame_count = frames_collection[anim_name].size()
		#var directions_count = _count_directions_for_animation(anim_name)
		#print("  %s: %d frames (%d direcciones)" % [anim_name, frame_count, directions_count])
	#
	#if not _validate_export_config():
		#_finish_export(false, "Configuración inválida")
		#return
	#
	## Crear carpeta de salida
	#var output_folder = export_config.get("output_folder", "res://output/")
	#print("📁 Carpeta de salida: %s" % output_folder)
	#
	#if not _ensure_output_folder(output_folder):
		#_finish_export(false, "No se pudo crear carpeta de salida")
		#return
	#
	## Determinar animaciones a exportar
	#var animations_to_export = _get_animations_to_export(export_config)
	#
	#if animations_to_export.is_empty():
		#_finish_export(false, "No hay animaciones para exportar")
		#return
	#
	#print("📋 Animaciones a exportar: %s" % str(animations_to_export))
	#
	## ✅ MEJORADO: Estado de batch para el pipeline
	#total_batch_count = animations_to_export.size()
	#current_batch_count = 0
	#
	#if total_batch_count > 1:
		#emit_signal("batch_export_started", total_batch_count)
	#
	## Exportar cada animación
	#var exported_successfully = 0
	#
	#for i in range(animations_to_export.size()):
		#var animation_name = animations_to_export[i]
		#current_batch_count = i + 1
		#
		#emit_signal("export_progress", current_batch_count, total_batch_count, "Exportando: " + animation_name)
		#
		#var success = _export_single_spritesheet(animation_name, output_folder)
		#if success:
			#exported_successfully += 1
			#print("✅ Exportación exitosa: %s" % animation_name)
			#
			## ✅ NUEVA: Señal específica por animación para el pipeline
			#var file_path = output_folder.path_join(animation_name + "_spritesheet.png")
			#emit_signal("animation_export_complete", animation_name, file_path)
		#else:
			#print("❌ Falló exportación de: %s" % animation_name)
			## No abortar, continuar con las demás
		#
		## Pequeña pausa para no saturar el sistema
		#await get_tree().process_frame
	#
	## ✅ MEJORADO: Resultado final con señales específicas para batch
	#if total_batch_count > 1:
		#emit_signal("batch_export_complete", exported_successfully, total_batch_count)
	#
	## Resultado final
	#if exported_successfully == total_batch_count:
		#print("✅ EXPORTACIÓN COMPLETADA - Todas las animaciones exportadas")
		#_finish_export(true, output_folder)
	#elif exported_successfully > 0:
		#print("⚠️ EXPORTACIÓN PARCIAL - %d/%d animaciones exportadas" % [exported_successfully, total_batch_count])
		#_finish_export(true, output_folder)  # Consideramos éxito parcial como éxito
	#else:
		#print("❌ EXPORTACIÓN FALLIDA - Ninguna animación exportada")
		#_finish_export(false, "No se pudo exportar ninguna animación")
#
#func _finish_export(success: bool, result: String):
	#"""Finalizar exportación con limpieza de estado"""
	#is_exporting = false
	#current_batch_count = 0
	#total_batch_count = 0
	#
	#if success:
		#emit_signal("export_complete", result)
	#else:
		#emit_signal("export_failed", result)
#
#func _validate_export_config() -> bool:
	#"""Validar configuración de exportación"""
	#var required_keys = ["output_folder"]
	#
	#for key in required_keys:
		#if not current_export_config.has(key):
			#print("❌ Falta parámetro requerido: %s" % key)
			#return false
	#
	#print("✅ Configuración validada")
	#return true
#
#func _ensure_output_folder(output_folder: String) -> bool:
	#"""Asegurar que la carpeta de salida existe"""
	## ✅ MEJORADO: Manejo de rutas tanto relativas como absolutas
	#var absolute_path = output_folder
	#if not output_folder.begins_with("/") and not output_folder.contains("://"):
		#absolute_path = ProjectSettings.globalize_path(output_folder)
	#
	#if DirAccess.dir_exists_absolute(absolute_path):
		#print("✅ Carpeta de salida existe: %s" % absolute_path)
		#return true
	#
	#print("📁 Creando carpeta de salida: %s" % absolute_path)
	#var error = DirAccess.make_dir_recursive_absolute(absolute_path)
	#
	#if error == OK:
		#print("✅ Carpeta creada exitosamente")
		#return true
	#else:
		#print("❌ Error creando carpeta: %d" % error)
		#return false
#
#func _get_animations_to_export(export_config: Dictionary) -> Array:
	#"""Determinar qué animaciones exportar"""
	#var animations_to_export = []
	#
	#match export_config.get("animation_mode", "current"):
		#"current":
			#var current_anim = export_config.get("current_animation", "")
			#print("🎯 Modo: animación current - %s" % current_anim)
			#if has_frames(current_anim):
				#animations_to_export.append(current_anim)
			#else:
				#print("❌ No hay frames para la animación actual: %s" % current_anim)
		#
		#"all":
			#print("🎯 Modo: todas las animaciones")
			#animations_to_export = get_available_animations()
			#if animations_to_export.is_empty():
				#print("❌ No hay animaciones con frames")
		#
		#"selected":
			#print("🎯 Modo: animaciones seleccionadas")
			#animations_to_export = export_config.get("selected_animations", [])
			## Filtrar solo las que tienen frames
			#var valid_animations = []
			#for anim in animations_to_export:
				#if has_frames(anim):
					#valid_animations.append(anim)
				#else:
					#print("⚠️ Animación seleccionada sin frames: %s" % anim)
			#animations_to_export = valid_animations
	#
	#return animations_to_export
#
#func _export_single_spritesheet(animation_name: String, output_folder: String) -> bool:
	#"""Exportar sprite sheet de una animación específica con debugging mejorado"""
	#print("\n--- EXPORTANDO SPRITE SHEET: %s ---" % animation_name)
	#
	#if not has_frames(animation_name):
		#print("❌ No hay frames para: %s" % animation_name)
		#return false
	#
	#var frames = frames_collection[animation_name]
	#print("📊 Total de frames: %d" % frames.size())
	#
	## Organizar frames por dirección
	#var frames_by_direction = _organize_frames_by_direction(frames)
	#print("📐 Organizados en %d direcciones" % frames_by_direction.size())
	#
	## Debug de frames por dirección
	#for direction in frames_by_direction:
		#print("  Dirección %d: %d frames" % [direction, frames_by_direction[direction].size()])
	#
	#if frames_by_direction.is_empty():
		#print("❌ No se pudieron organizar los frames por dirección")
		#return false
	#
	## Determinar dimensiones del spritesheet
	#var sprite_size = frames[0].image.get_size()
	#var directions_count = frames_by_direction.size()
	#var max_frames_per_direction = 0
	#
	## Encontrar el máximo número de frames por dirección
	#for direction in frames_by_direction:
		#var frame_count = frames_by_direction[direction].size()
		#if frame_count > max_frames_per_direction:
			#max_frames_per_direction = frame_count
	#
	#print("📏 Dimensiones: sprite=%s, direcciones=%d, max_frames=%d" % [sprite_size, directions_count, max_frames_per_direction])
	#
	## Calcular layout del spritesheet
	#var layout = _calculate_spritesheet_layout(directions_count, max_frames_per_direction)
	#var sheet_width = layout.columns * sprite_size.x
	#var sheet_height = layout.rows * sprite_size.y
	#
	#print("🖼️ Spritesheet final: %dx%d (%d cols x %d rows)" % [sheet_width, sheet_height, layout.columns, layout.rows])
	#
	## Crear imagen del spritesheet
	#var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	#spritesheet.fill(Color(0, 0, 0, 0))  # Fondo transparente
	#
	## Colocar frames en el spritesheet
	#var frames_placed = _place_frames_in_spritesheet(spritesheet, frames_by_direction, sprite_size, layout)
	#
	#if frames_placed == 0:
		#print("❌ No se pudo colocar ningún frame en el spritesheet")
		#return false
	#
	#print("✅ %d frames colocados en el spritesheet" % frames_placed)
	#
	## ✅ MEJORADO: Manejo de rutas mejorado
	#var image_path = ""
	#if output_folder.begins_with("/") or output_folder.contains("://"):
		#image_path = output_folder.path_join(animation_name + "_spritesheet.png")
	#else:
		#image_path = ProjectSettings.globalize_path(output_folder).path_join(animation_name + "_spritesheet.png")
	#
	#var save_error = spritesheet.save_png(image_path)
	#
	#if save_error != OK:
		#print("❌ Error guardando imagen: %d en %s" % [save_error, image_path])
		#return false
	#
	#print("✅ Imagen guardada: %s" % image_path)
	#
	## Generar metadatos si está disponible
	#if metadata_generator and metadata_generator.has_method("generate_json"):
		#var metadata_path = ""
		#if output_folder.begins_with("/") or output_folder.contains("://"):
			#metadata_path = output_folder.path_join(animation_name + "_metadata.json")
		#else:
			#metadata_path = ProjectSettings.globalize_path(output_folder).path_join(animation_name + "_metadata.json")
		#
		#var animation_data = _create_animation_metadata(animation_name, frames_by_direction, sprite_size, layout)
		#
		#metadata_generator.generate_json(animation_data, metadata_path)
		#print("✅ Metadatos generados: %s" % metadata_path)
	#
	#print("--- FIN EXPORTACIÓN: %s ---\n" % animation_name)
	#return true
#
#func _organize_frames_by_direction(frames: Array) -> Dictionary:
	#"""Organizar frames por dirección"""
	#var frames_by_direction = {}
	#
	#for frame_data in frames:
		#var direction = frame_data.get("direction", 0)
		#
		#if not direction in frames_by_direction:
			#frames_by_direction[direction] = []
		#
		#frames_by_direction[direction].append(frame_data)
	#
	## Ordenar frames dentro de cada dirección por número de frame
	#for direction in frames_by_direction:
		#frames_by_direction[direction].sort_custom(_sort_frames_by_number)
	#
	#return frames_by_direction
#
#func _sort_frames_by_number(a: Dictionary, b: Dictionary) -> bool:
	#"""Ordenar frames por número"""
	#return a.get("frame", 0) < b.get("frame", 0)
#
#func _calculate_spritesheet_layout(directions: int, max_frames: int) -> Dictionary:
	#"""Calcular layout del spritesheet"""
	## Layout horizontal: una fila por dirección, frames en columnas
	#return {
		#"columns": max_frames,
		#"rows": directions,
		#"type": "grid"
	#}
#
#func _place_frames_in_spritesheet(spritesheet: Image, frames_by_direction: Dictionary, sprite_size: Vector2, _layout: Dictionary) -> int:
	#"""Colocar frames en el spritesheet"""
	#var frames_placed = 0
	#var current_row = 0
	#
	#var direction_keys = frames_by_direction.keys()
	#direction_keys.sort()  # Ordenar direcciones numéricamente
	#
	#for direction_key in direction_keys:
		#var direction_frames = frames_by_direction[direction_key]
		#
		#print("  📍 Colocando dirección %d con %d frames" % [direction_key, direction_frames.size()])
		#
		#for frame_idx in range(direction_frames.size()):
			#var frame_data = direction_frames[frame_idx]
			#var x = frame_idx * sprite_size.x
			#var y = current_row * sprite_size.y
			#
			## Verificar que no nos salimos del spritesheet
			#if x + sprite_size.x <= spritesheet.get_width() and y + sprite_size.y <= spritesheet.get_height():
				## Copiar frame al spritesheet
				#var frame_image = frame_data.image
				##if frame_image and frame_image.get_size() == sprite_size:
				##Invalid operands 'Vector2i' and 'Vector2' in operator '=='.
				#if frame_image and frame_image.get_size() == Vector2i(sprite_size):
					#spritesheet.blit_rect(frame_image, Rect2(Vector2.ZERO, sprite_size), Vector2(x, y))
					#frames_placed += 1
				#else:
					#print("⚠️ Frame inválido en dirección %d, frame %d" % [direction_key, frame_idx])
			#else:
				#print("⚠️ Frame fuera de bounds: x=%d, y=%d, límites=%dx%d" % [x, y, spritesheet.get_width(), spritesheet.get_height()])
		#
		#current_row += 1
	#
	#return frames_placed
#
#func _create_animation_metadata(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary) -> Dictionary:
	#"""Crear metadatos de la animación"""
	#var directions_data = []
	#
	#for direction in frames_by_direction:
		#directions_data.append({
			#"index": direction,
			#"frame_count": frames_by_direction[direction].size()
		#})
	#
	#return {
		#"name": animation_name,
		#"sprite_size": {
			#"width": sprite_size.x,
			#"height": sprite_size.y
		#},
		#"layout": layout,
		#"directions": directions_data,
		#"total_frames": _count_total_frames(frames_by_direction),
		#"exported_at": Time.get_datetime_string_from_system()
	#}
#
#func _count_total_frames(frames_by_direction: Dictionary) -> int:
	#"""Contar total de frames"""
	#var total = 0
	#for direction in frames_by_direction:
		#total += frames_by_direction[direction].size()
	#return total
#
## ========================================================================
## FUNCIONES DE DEBUG Y UTILIDAD (MEJORADAS)
## ========================================================================
#
#func debug_export_state():
	#"""Debug del estado del export manager"""
	#print("\n📤 === EXPORT MANAGER DEBUG (MEJORADO) ===")
	#print("Estado de exportación: %s" % ("🔄 Activo" if is_exporting else "⏸️ Inactivo"))
	#
	#if is_exporting:
		#print("Progreso batch: %d/%d animaciones" % [current_batch_count, total_batch_count])
	#
	#print("Animaciones con frames: %d" % frames_collection.size())
	#
	#for anim_name in frames_collection:
		#var frames = frames_collection[anim_name]
		#var directions_count = _count_directions_for_animation(anim_name)
		#print("  %s: %d frames (%d direcciones)" % [anim_name, frames.size(), directions_count])
		#
		## Mostrar distribución por direcciones
		#var directions = {}
		#for frame in frames:
			#var dir = frame.get("direction", 0)
			#if not dir in directions:
				#directions[dir] = 0
			#directions[dir] += 1
		#
		#for direction in directions:
			#print("    Dirección %d: %d frames" % [direction, directions[direction]])
	#
	#print("==============================\n")
#
#func get_export_stats() -> Dictionary:
	#"""Obtener estadísticas de exportación mejoradas"""
	#var total_frames = 0
	#var directions_used = []
	#var animations_stats = {}
	#
	#for anim_name in frames_collection:
		#var frames = frames_collection[anim_name]
		#total_frames += frames.size()
		#
		#var anim_directions = []
		#for frame in frames:
			#var direction = frame.get("direction", 0)
			#if not direction in directions_used:
				#directions_used.append(direction)
			#if not direction in anim_directions:
				#anim_directions.append(direction)
		#
		#animations_stats[anim_name] = {
			#"frames": frames.size(),
			#"directions": anim_directions.size()
		#}
	#
	#return {
		#"animations_count": frames_collection.size(),
		#"total_frames": total_frames,
		#"directions_used": directions_used.size(),
		#"has_metadata_generator": metadata_generator != null,
		#"is_exporting": is_exporting,
		#"batch_progress": {
			#"current": current_batch_count,
			#"total": total_batch_count
		#},
		#"animations_stats": animations_stats
	#}
#
## ✅ NUEVAS: Funciones públicas específicas para el pipeline
#
#func get_export_status() -> Dictionary:
	#"""Obtener estado actual de exportación para el pipeline"""
	#return {
		#"is_busy": is_exporting,
		#"current_batch": current_batch_count,
		#"total_batch": total_batch_count,
		#"has_frames": not frames_collection.is_empty(),
		#"available_animations": get_available_animations()
	#}
#
#func is_busy() -> bool:
	#"""Verificar si el exportador está ocupado"""
	#return is_exporting
#
#func force_reset_export_state():
	#"""Reset forzado del estado de exportación"""
	#print("🚨 FORCE RESET: Estado de exportación")
	#is_exporting = false
	#current_batch_count = 0
	#total_batch_count = 0
	#current_export_config.clear()
	#print("✅ Estado de exportación reseteado")
#
## ✅ NUEVA: Función para exportar una sola animación (API simplificada para pipeline)
#func export_single_animation(animation_name: String, output_folder: String, config: Dictionary = {}) -> bool:
	#"""API simplificada para exportar una sola animación - optimizada para pipeline"""
	#if is_exporting:
		#print("❌ Exportador ocupado")
		#return false
	#
	#if not has_frames(animation_name):
		#print("❌ No hay frames para '%s'" % animation_name)
		#return false
	#
	#print("🚀 Exportación rápida: %s → %s" % [animation_name, output_folder])
	#
	## Configuración mínima
	#var export_config = {
		#"output_folder": output_folder,
		#"animation_mode": "current",
		#"current_animation": animation_name,
		#"generate_metadata": config.get("generate_metadata", true)
	#}
	#
	## Agregar configuraciones adicionales
	#for key in config:
		#export_config[key] = config[key]
	#
	## Usar función de exportación principal
	#export_sprite_sheets(export_config)
	#
	#return true



# pixelize3d_fbx/scripts/export/export_manager.gd
# MODIFICADO: Soporte para división automática de spritesheets cuando exceden límites
# Input: Frames renderizados y configuración de exportación  
# Output: Múltiples sprite sheets PNG si es necesario, con metadatos de reconstrucción

extends Node

# Señales
signal export_complete(file_path: String)
signal export_failed(error: String)
signal export_progress(current: int, total: int, message: String)

# ✅ NUEVOS: Límites y configuración de división automática
const MAX_TEXTURE_SIZE: int = 16384  # Límite máximo de textura
const SAFETY_MARGIN: int = 256       # Margen de seguridad
const EFFECTIVE_LIMIT: int = MAX_TEXTURE_SIZE - SAFETY_MARGIN

# Colección de frames por animación
var frames_collection: Dictionary = {}
var current_export_config: Dictionary = {}

# Referencias a otros componentes
var metadata_generator: Node

# ✅ NUEVO: Estado de división automática
var auto_split_enabled: bool = true
var current_split_info: Dictionary = {}

func _ready():
	print("📤 ExportManager MEJORADO con división automática iniciado")
	
	# Conectar con metadata generator si existe
	metadata_generator = get_node_or_null("../MetadataGenerator")
	if not metadata_generator:
		# Crear instancia si no existe
		#metadata_generator = preload("res://scripts/export/metadata_generator.gd").new()
		var metadata_script = load("res://scripts/export/metadata_generator.gd")
		if metadata_script:
			metadata_generator = metadata_script.new()
			metadata_generator.name = "MetadataGenerator"
			add_child(metadata_generator)
			print("✅ MetadataGenerator creado")
	else:
		print("⚠️ MetadataGenerator no disponible - continuando sin metadatos")
		add_child(metadata_generator)
		
	print("✅ Límite de textura configurado: %dpx (límite efectivo: %dpx)" % [MAX_TEXTURE_SIZE, EFFECTIVE_LIMIT])

# ========================================================================
# FUNCIONES DE GESTIÓN DE FRAMES (SIN CAMBIOS)
# ========================================================================

func add_frame(frame_data: Dictionary):
	"""Añadir frame a la colección"""
	var animation_name = frame_data.animation
	
	if not animation_name in frames_collection:
		frames_collection[animation_name] = []
	
	frames_collection[animation_name].append(frame_data)

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

# ========================================================================
# EXPORTACIÓN PRINCIPAL CON DIVISIÓN AUTOMÁTICA
# ========================================================================

func export_sprite_sheets(export_config: Dictionary):
	"""Exportar sprite sheets con división automática si es necesario"""
	print("\n📤 === INICIANDO EXPORTACIÓN CON DIVISIÓN AUTOMÁTICA ===")
	
	current_export_config = export_config
	var animation_mode = export_config.get("animation_mode", "current")
	var output_folder = export_config.get("output_folder", "res://output/")
	
	# Crear carpeta de salida
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))
	
	var animations_to_export = []
	
	# Determinar animaciones a exportar
	if animation_mode == "current":
		var current_animation = export_config.get("current_animation", "")
		if current_animation != "":
			animations_to_export.append(current_animation)
	elif animation_mode == "all":
		animations_to_export = get_available_animations()
	
	if animations_to_export.is_empty():
		print("❌ No hay animaciones para exportar")
		emit_signal("export_failed", "No hay animaciones para exportar")
		return
	
	print("📋 Animaciones a exportar: %s" % str(animations_to_export))
	
	# Exportar cada animación
	var successful_exports = 0
	
	for i in range(animations_to_export.size()):
		var animation_name = animations_to_export[i]
		
		print("\n--- Exportando %d/%d: %s ---" % [i + 1, animations_to_export.size(), animation_name])
		emit_signal("export_progress", i + 1, animations_to_export.size(), "Exportando " + animation_name)
		
		# ✅ EXPORTACIÓN CON DIVISIÓN AUTOMÁTICA
		var export_result = _export_single_animation_with_auto_split(animation_name, output_folder)
		
		if export_result.success:
			successful_exports += 1
			print("✅ %s exportado exitosamente" % animation_name)
			
			# Emitir señal por cada archivo generado
			for file_path in export_result.generated_files:
				emit_signal("export_complete", file_path)
		else:
			print("❌ Error exportando %s: %s" % [animation_name, export_result.error])
			emit_signal("export_failed", "Error en " + animation_name + ": " + export_result.error)
			return
	
	print("\n✅ === EXPORTACIÓN COMPLETADA ===")
	print("Animaciones exportadas: %d/%d" % [successful_exports, animations_to_export.size()])
	
	if successful_exports == animations_to_export.size():
		emit_signal("export_complete", output_folder)
	else:
		emit_signal("export_failed", "Solo %d/%d animaciones exportadas" % [successful_exports, animations_to_export.size()])

# ========================================================================
# EXPORTACIÓN INDIVIDUAL CON DIVISIÓN AUTOMÁTICA
# ========================================================================

func _export_single_animation_with_auto_split(animation_name: String, output_folder: String) -> Dictionary:
	"""Exportar una animación con división automática si es necesario"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": [],
		"split_info": {}
	}
	
	# Validar que existen frames
	if not has_frames(animation_name):
		result.error = "No hay frames para la animación"
		return result
	
	var frames = frames_collection[animation_name]
	
	# Organizar frames por dirección
	var frames_by_direction = _organize_frames_by_direction(frames)
	print("📐 Organizados en %d direcciones" % frames_by_direction.size())
	
	# Determinar dimensiones
	var sprite_size = frames[0].image.get_size()
	var directions_count = frames_by_direction.size()
	var max_frames_per_direction = _get_max_frames_per_direction(frames_by_direction)
	
	print("📏 Análisis: sprite=%s, direcciones=%d, max_frames=%d" % [sprite_size, directions_count, max_frames_per_direction])
	
	# ✅ CÁLCULO INTELIGENTE CON DIVISIÓN AUTOMÁTICA
	var layout_analysis = _analyze_layout_and_calculate_splits(sprite_size, directions_count, max_frames_per_direction)
	
	if layout_analysis.needs_split:
		print("🔄 División automática requerida: %d partes" % layout_analysis.split_count)
		result = _export_with_automatic_splitting(animation_name, frames_by_direction, sprite_size, layout_analysis, output_folder)
	else:
		print("✅ Spritesheet único suficiente")
		result = _export_single_spritesheet(animation_name, frames_by_direction, sprite_size, layout_analysis.layout, output_folder)
	
	result.split_info = layout_analysis
	return result

# ========================================================================
# ANÁLISIS DE LAYOUT Y CÁLCULO DE DIVISIONES
# ========================================================================

func _analyze_layout_and_calculate_splits(sprite_size: Vector2, directions: int, max_frames: int) -> Dictionary:
	"""Analizar layout y calcular divisiones necesarias"""
	var analysis = {
		"sprite_size": sprite_size,
		"directions": directions,
		"max_frames": max_frames,
		"needs_split": false,
		"split_count": 1,
		"frames_per_split": max_frames,
		"layout": {},
		"split_layouts": [],
		"total_width": 0,
		"total_height": 0,
		"exceeds_width": false,
		"exceeds_height": false
	}
	
	# ✅ CALCULAR DIMENSIONES TOTALES PROPUESTAS
	analysis.total_width = max_frames * int(sprite_size.x)
	analysis.total_height = directions * int(sprite_size.y)
	
	print("🔍 Dimensiones calculadas: %dx%d" % [analysis.total_width, analysis.total_height])
	
	# ✅ VERIFICAR LÍMITES
	analysis.exceeds_width = analysis.total_width > EFFECTIVE_LIMIT
	analysis.exceeds_height = analysis.total_height > EFFECTIVE_LIMIT
	
	if analysis.exceeds_width or analysis.exceeds_height:
		analysis.needs_split = true
		
		if analysis.exceeds_width:
			print("⚠️ Excede límite de ancho: %d > %d" % [analysis.total_width, EFFECTIVE_LIMIT])
			# ✅ CALCULAR FRAMES MÁXIMOS POR SPLIT BASADO EN ANCHO
			analysis.frames_per_split = int(EFFECTIVE_LIMIT / sprite_size.x)
			analysis.split_count = int(ceil(float(max_frames) / analysis.frames_per_split))
			
		if analysis.exceeds_height:
			print("⚠️ Excede límite de altura: %d > %d" % [analysis.total_height, EFFECTIVE_LIMIT])
			# Si también excede altura, necesitamos estrategia diferente
			if analysis.exceeds_width:
				# Ya se calculó split por ancho, validar que altura resultante sea válida
				var split_height = directions * int(sprite_size.y)
				if split_height > EFFECTIVE_LIMIT:
					print("❌ ERROR: Aún con división por ancho, la altura excede límites")
					print("   Solución requerida: Reducir número de direcciones o sprite_size")
			else:
				# Solo excede altura - dividir por direcciones (no implementado en esta versión)
				print("⚠️ División por direcciones no implementada - usar menos direcciones")
	
	# ✅ GENERAR LAYOUTS DE DIVISIÓN
	if analysis.needs_split and analysis.split_count > 1:
		analysis.split_layouts = _generate_split_layouts(analysis)
	else:
		# Layout único
		analysis.layout = {
			"columns": max_frames,
			"rows": directions,
			"type": "single"
		}
	
	print("📊 Análisis completado:")
	print("  - Necesita división: %s" % analysis.needs_split)
	print("  - Partes: %d" % analysis.split_count)
	print("  - Frames por parte: %d" % analysis.frames_per_split)
	
	return analysis

func _generate_split_layouts(analysis: Dictionary) -> Array:
	"""Generar layouts para cada split"""
	var layouts = []
	var remaining_frames = analysis.max_frames
	var frames_per_split = analysis.frames_per_split
	
	for split_idx in range(analysis.split_count):
		var frames_in_this_split = min(frames_per_split, remaining_frames)
		
		var layout = {
			"split_index": split_idx,
			"columns": frames_in_this_split,
			"rows": analysis.directions,
			"frame_start": split_idx * frames_per_split,
			"frame_end": split_idx * frames_per_split + frames_in_this_split - 1,
			"frame_count": frames_in_this_split,
			"type": "split_part"
		}
		
		layouts.append(layout)
		remaining_frames -= frames_in_this_split
		
		print("  📄 Split %d: frames %d-%d (%d frames, %dx%d)" % [
			split_idx, layout.frame_start, layout.frame_end, 
			layout.frame_count, layout.columns, layout.rows
		])
	
	return layouts

# ========================================================================
# EXPORTACIÓN CON MÚLTIPLES SPRITESHEETS
# ========================================================================

func _export_with_automatic_splitting(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout_analysis: Dictionary, output_folder: String) -> Dictionary:
	"""Exportar con división automática en múltiples spritesheets"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": [],
		"split_count": layout_analysis.split_count
	}
	
	print("🔄 Iniciando exportación dividida en %d partes..." % layout_analysis.split_count)
	
	var all_metadata = []
	
	# ✅ EXPORTAR CADA SPLIT
	for split_idx in range(layout_analysis.split_count):
		var split_layout = layout_analysis.split_layouts[split_idx]
		
		print("\n--- Exportando parte %d/%d ---" % [split_idx + 1, layout_analysis.split_count])
		
		# ✅ FILTRAR FRAMES PARA ESTE SPLIT
		var split_frames = _filter_frames_for_split(frames_by_direction, split_layout)
		
		# ✅ CREAR NOMBRE DE ARCHIVO CON SUFIJO
		var split_filename_base = animation_name
		if layout_analysis.split_count > 1:
			split_filename_base += "_part%d" % (split_idx + 1)
		
		# ✅ EXPORTAR ESTE SPLIT
		var split_result = _export_split_spritesheet(split_filename_base, split_frames, sprite_size, split_layout, output_folder)
		
		if not split_result.success:
			result.error = "Error en split %d: %s" % [split_idx + 1, split_result.error]
			return result
		
		result.generated_files.append_array(split_result.generated_files)
		
		# ✅ GUARDAR METADATA DE ESTE SPLIT
		all_metadata.append(split_result.metadata)
	
	# ✅ GENERAR METADATA MAESTRO DE RECONSTRUCCIÓN
	var master_metadata_result = _generate_master_reconstruction_metadata(animation_name, all_metadata, layout_analysis, output_folder)
	
	if master_metadata_result.success:
		result.generated_files.append_array(master_metadata_result.generated_files)
		result.success = true
		print("✅ Exportación dividida completada: %d archivos generados" % result.generated_files.size())
	else:
		result.error = "Error generando metadata maestro: " + master_metadata_result.error
	
	return result

func _filter_frames_for_split(frames_by_direction: Dictionary, split_layout: Dictionary) -> Dictionary:
	"""Filtrar frames que corresponden a un split específico"""
	var filtered_frames = {}
	
	var frame_start = split_layout.frame_start
	var frame_end = split_layout.frame_end
	
	print("🔍 Filtrando frames %d-%d para split..." % [frame_start, frame_end])
	
	for direction in frames_by_direction:
		filtered_frames[direction] = []
		var direction_frames = frames_by_direction[direction]
		
		# Ordenar frames para asegurar orden correcto
		direction_frames.sort_custom(_sort_frames_by_number)
		
		# Filtrar frames en el rango de este split
		for i in range(direction_frames.size()):
			if i >= frame_start and i <= frame_end:
				var frame_data = direction_frames[i].duplicate()
				# Actualizar índice relativo al split
				frame_data.frame = i - frame_start
				filtered_frames[direction].append(frame_data)
		
		print("  📍 Dirección %d: %d frames filtrados" % [direction, filtered_frames[direction].size()])
	
	return filtered_frames

func _export_split_spritesheet(filename_base: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary, output_folder: String) -> Dictionary:
	"""Exportar un spritesheet individual de un split"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": [],
		"metadata": {}
	}
	
	# ✅ CREAR IMAGEN DEL SPRITESHEET
	var sheet_width = layout.columns * int(sprite_size.x)
	var sheet_height = layout.rows * int(sprite_size.y)
	
	print("🖼️ Creando spritesheet: %dx%d (%d cols x %d rows)" % [sheet_width, sheet_height, layout.columns, layout.rows])
	
	var spritesheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	spritesheet.fill(Color(0, 0, 0, 0))  # Fondo transparente
	
	# ✅ COLOCAR FRAMES
	var frames_placed = _place_frames_in_spritesheet(spritesheet, frames_by_direction, sprite_size, layout)
	
	if frames_placed == 0:
		result.error = "No se pudo colocar ningún frame"
		return result
	
	print("✅ %d frames colocados en el spritesheet" % frames_placed)
	
	# ✅ GUARDAR IMAGEN
	var image_filename = filename_base + "_spritesheet.png"
	var image_path = output_folder.path_join(image_filename)
	
	var save_error = spritesheet.save_png(ProjectSettings.globalize_path(image_path))
	
	if save_error != OK:
		result.error = "Error guardando imagen: " + str(save_error)
		return result
	
	print("✅ Imagen guardada: %s" % image_path)
	result.generated_files.append(image_path)
	
	# ✅ GENERAR METADATA DEL SPLIT
	if current_export_config.get("generate_metadata", true):
		var metadata_result = _generate_split_metadata(filename_base, frames_by_direction, sprite_size, layout, output_folder)
		
		if metadata_result.success:
			result.generated_files.append_array(metadata_result.generated_files)
			result.metadata = metadata_result.metadata
		else:
			print("⚠️ Error generando metadata: %s" % metadata_result.error)
	
	result.success = true
	return result

# ========================================================================
# EXPORTACIÓN DE SPRITESHEET ÚNICO (VERSIÓN ORIGINAL MEJORADA)
# ========================================================================

func _export_single_spritesheet(animation_name: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary, output_folder: String) -> Dictionary:
	"""Exportar spritesheet único cuando no se necesita división"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": []
	}
	
	print("🖼️ Exportando spritesheet único...")
	
	# Usar el mismo método que para splits pero sin división
	layout["split_index"] = 0
	layout["frame_start"] = 0
	layout["frame_end"] = _get_max_frames_per_direction(frames_by_direction) - 1
	
	var export_result = _export_split_spritesheet(animation_name, frames_by_direction, sprite_size, layout, output_folder)
	
	result.success = export_result.success
	result.error = export_result.error
	result.generated_files = export_result.generated_files
	
	return result

# ========================================================================
# GENERACIÓN DE METADATA
# ========================================================================

func _generate_split_metadata(filename_base: String, frames_by_direction: Dictionary, sprite_size: Vector2, layout: Dictionary, output_folder: String) -> Dictionary:
	"""Generar metadata para un split específico"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": [],
		"metadata": {}
	}
	
	# ✅ CREAR ESTRUCTURA DE METADATA
	var metadata = {
		"split_info": {
			"is_split_part": layout.has("split_index"),
			"split_index": layout.get("split_index", 0),
			"frame_start": layout.get("frame_start", 0),
			"frame_end": layout.get("frame_end", 0),
			"total_splits": 1  # Se actualizará en metadata maestro
		},
		"animation_name": filename_base,
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
		"total_frames": 0,
		"fps": current_export_config.get("fps", 12),
		"export_date": Time.get_datetime_string_from_system()
	}
	
	# ✅ AÑADIR INFORMACIÓN DE DIRECCIONES
	var direction_keys = frames_by_direction.keys()
	direction_keys.sort()
	
	var row_index = 0
	for direction_key in direction_keys:
		var direction_frames = frames_by_direction[direction_key]
		
		var direction_data = {
			"index": direction_key,
			"angle": direction_key * (360.0 / direction_keys.size()),
			"frame_count": direction_frames.size(),
			"row": row_index,
			"frames": []
		}
		
		# Añadir información de cada frame
		for frame_idx in range(direction_frames.size()):
			var frame_info = {
				"index": frame_idx,
				"global_index": frame_idx + layout.get("frame_start", 0),  # Índice global
				"x": frame_idx * int(sprite_size.x),
				"y": row_index * int(sprite_size.y),
				"width": int(sprite_size.x),
				"height": int(sprite_size.y)
			}
			direction_data.frames.append(frame_info)
		
		metadata.directions.append(direction_data)
		metadata.total_frames += direction_frames.size()
		row_index += 1
	
	# ✅ GUARDAR METADATA JSON
	var metadata_filename = filename_base + "_metadata.json"
	var metadata_path = output_folder.path_join(metadata_filename)
	
	var file = FileAccess.open(ProjectSettings.globalize_path(metadata_path), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata, "\t"))
		file.close()
		
		result.generated_files.append(metadata_path)
		result.metadata = metadata
		result.success = true
		
		print("✅ Metadata generado: %s" % metadata_path)
	else:
		result.error = "No se pudo crear archivo de metadata"
	
	return result

func _generate_master_reconstruction_metadata(animation_name: String, all_split_metadata: Array, layout_analysis: Dictionary, output_folder: String) -> Dictionary:
	"""Generar metadata maestro para reconstruir animación completa"""
	var result = {
		"success": false,
		"error": "",
		"generated_files": []
	}
	
	print("📋 Generando metadata maestro de reconstrucción...")
	
	# ✅ CREAR METADATA MAESTRO
	var master_metadata = {
		"reconstruction_info": {
			"is_split_animation": true,
			"total_splits": layout_analysis.split_count,
			"frames_per_split": layout_analysis.frames_per_split,
			"total_frames": layout_analysis.max_frames,
			"split_reason": "exceeds_texture_limits",
			"max_texture_size": MAX_TEXTURE_SIZE
		},
		"animation_name": animation_name,
		"sprite_size": {
			"width": int(layout_analysis.sprite_size.x),
			"height": int(layout_analysis.sprite_size.y)
		},
		"total_directions": layout_analysis.directions,
		"fps": current_export_config.get("fps", 12),
		"splits": [],
		"usage_instructions": {
			"description": "Esta animación fue dividida automáticamente en múltiples spritesheets",
			"godot_usage": "Cargar cada parte y combinar frames en SpriteFrames",
			"web_usage": "Cargar todas las partes y crear una animación secuencial"
		},
		"export_date": Time.get_datetime_string_from_system()
	}
	
	# ✅ AÑADIR INFORMACIÓN DE CADA SPLIT
	for i in range(all_split_metadata.size()):
		var split_metadata = all_split_metadata[i]
		
		var split_info = {
			"split_index": i,
			"filename": animation_name + "_part%d_spritesheet.png" % (i + 1),
			"metadata_file": animation_name + "_part%d_metadata.json" % (i + 1),
			"frame_range": {
				"start": split_metadata.split_info.frame_start,
				"end": split_metadata.split_info.frame_end,
				"count": split_metadata.total_frames / layout_analysis.directions
			},
			"dimensions": split_metadata.spritesheet_size
		}
		
		master_metadata.splits.append(split_info)
	
	# ✅ GUARDAR METADATA MAESTRO
	var master_filename = animation_name + "_master_metadata.json"
	var master_path = output_folder.path_join(master_filename)
	
	var file = FileAccess.open(ProjectSettings.globalize_path(master_path), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(master_metadata, "\t"))
		file.close()
		
		result.generated_files.append(master_path)
		result.success = true
		
		print("✅ Metadata maestro generado: %s" % master_path)
		print("📄 Estructura de reconstrucción documentada para %d splits" % layout_analysis.split_count)
	else:
		result.error = "No se pudo crear metadata maestro"
	
	return result

# ========================================================================
# FUNCIONES AUXILIARES (MEJORADAS Y NUEVAS)
# ========================================================================

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

func _get_max_frames_per_direction(frames_by_direction: Dictionary) -> int:
	"""Obtener el máximo número de frames por dirección"""
	var max_frames = 0
	
	for direction in frames_by_direction:
		var frame_count = frames_by_direction[direction].size()
		if frame_count > max_frames:
			max_frames = frame_count
	
	return max_frames

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
			var x = frame_idx * int(sprite_size.x)
			var y = current_row * int(sprite_size.y)
			
			# Verificar que no nos salimos del spritesheet
			if x + sprite_size.x <= spritesheet.get_width() and y + sprite_size.y <= spritesheet.get_height():
				# Copiar frame al spritesheet
				var frame_image = frame_data.image
				if frame_image and frame_image.get_size() == Vector2i(sprite_size):
					spritesheet.blit_rect(frame_image, Rect2(Vector2.ZERO, sprite_size), Vector2(x, y))
					frames_placed += 1
				else:
					print("⚠️ Frame inválido en dirección %d, frame %d" % [direction_key, frame_idx])
			else:
				print("⚠️ Frame fuera de bounds: x=%d, y=%d, límites=%dx%d" % [x, y, spritesheet.get_width(), spritesheet.get_height()])
		
		current_row += 1
	
	return frames_placed

# ========================================================================
# FUNCIONES DE CONFIGURACIÓN Y DEBUG
# ========================================================================

func set_auto_split_enabled(enabled: bool):
	"""Habilitar/deshabilitar división automática"""
	auto_split_enabled = enabled
	print("🔄 División automática: %s" % ("HABILITADA" if enabled else "DESHABILITADA"))

func get_texture_limits_info() -> Dictionary:
	"""Obtener información sobre límites de textura"""
	return {
		"max_texture_size": MAX_TEXTURE_SIZE,
		"safety_margin": SAFETY_MARGIN,
		"effective_limit": EFFECTIVE_LIMIT,
		"auto_split_enabled": auto_split_enabled
	}

func debug_export_state():
	"""Debug del estado del export manager"""
	print("\n📤 === EXPORT MANAGER DEBUG (CON DIVISIÓN AUTOMÁTICA) ===")
	print("Estado de exportación: %s" % ("🔄 Activo" if false else "⏸️ Inactivo"))  # Variable is_exporting no visible
	print("División automática: %s" % ("✅ HABILITADA" if auto_split_enabled else "❌ DESHABILITADA"))
	print("Límite de textura: %dpx (efectivo: %dpx)" % [MAX_TEXTURE_SIZE, EFFECTIVE_LIMIT])
	print("Animaciones disponibles: %d" % frames_collection.size())
	
	for anim_name in frames_collection:
		var frame_count = frames_collection[anim_name].size()
		print("  - %s: %d frames" % [anim_name, frame_count])
	
	print("=======================================================\n")

func debug_layout_calculation(sprite_size: Vector2, directions: int, max_frames: int):
	"""Debug del cálculo de layout"""
	print("\n🔍 === DEBUG CÁLCULO DE LAYOUT ===")
	var analysis = _analyze_layout_and_calculate_splits(sprite_size, directions, max_frames)
	
	print("Análisis completado:")
	print("  Sprite size: %s" % str(sprite_size))
	print("  Direcciones: %d" % directions)
	print("  Max frames: %d" % max_frames)
	print("  Dimensiones totales: %dx%d" % [analysis.total_width, analysis.total_height])
	print("  Necesita división: %s" % analysis.needs_split)
	
	if analysis.needs_split:
		print("  Partes necesarias: %d" % analysis.split_count)
		print("  Frames por parte: %d" % analysis.frames_per_split)
		
		for i in range(analysis.split_layouts.size()):
			var layout = analysis.split_layouts[i]
			print("    Split %d: frames %d-%d (%dx%d)" % [
				i, layout.frame_start, layout.frame_end, 
				layout.columns * int(sprite_size.x), layout.rows * int(sprite_size.y)
			])
	
	print("====================================\n")
	
	return analysis
