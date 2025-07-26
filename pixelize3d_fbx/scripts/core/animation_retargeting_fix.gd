# scripts/core/animation_retargeting_fix.gd
# Script especializado para corregir el retargeting de animaciones
# Input: AnimationPlayer con animaciones que apuntan al skeleton original
# Output: AnimationPlayer con rutas corregidas para el nuevo skeleton

extends Node

# Función principal para corregir el retargeting de animaciones
static func fix_animation_retargeting(anim_player: AnimationPlayer, old_skeleton_name: String, new_skeleton_name: String) -> bool:
	if not anim_player:
		print("❌ AnimationPlayer inválido para retargeting")
		return false
	
	print("🔧 CORRIGIENDO RETARGETING DE ANIMACIONES")
	print("  Skeleton origen: %s" % old_skeleton_name)
	print("  Skeleton destino: %s" % new_skeleton_name)
	
	var total_tracks_updated = 0
	var animations_processed = 0
	
	# Procesar cada animación
	for anim_name in anim_player.get_animation_list():
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(anim_name)
		
		if not animation:
			print("  ⚠️ No se pudo obtener animación: %s" % anim_name)
			continue
		
		print("  🎭 Procesando: %s (%d tracks)" % [anim_name, animation.get_track_count()])
		
		var tracks_updated_in_anim = 0
		
		# Procesar cada track de la animación
		for track_idx in range(animation.get_track_count()):
			var original_path = animation.track_get_path(track_idx)
			var path_string = str(original_path)
			
			# Corregir la ruta
			var new_path_string = _fix_track_path(path_string, old_skeleton_name, new_skeleton_name)
			
			if new_path_string != path_string:
				animation.track_set_path(track_idx, NodePath(new_path_string))
				tracks_updated_in_anim += 1
				
				# Debug detallado solo para algunos tracks
				if track_idx < 3:
					print("    📍 Track %d: %s -> %s" % [track_idx, path_string, new_path_string])
		
		total_tracks_updated += tracks_updated_in_anim
		animations_processed += 1
		
		print("    ✅ Tracks actualizados: %d/%d" % [tracks_updated_in_anim, animation.get_track_count()])
	
	print("🔧 RETARGETING COMPLETADO:")
	print("  Animaciones procesadas: %d" % animations_processed)
	print("  Total tracks actualizados: %d" % total_tracks_updated)
	
	return total_tracks_updated > 0

# Función mejorada para corregir rutas de tracks
static func _fix_track_path(original_path: String, old_skeleton_name: String, new_skeleton_name: String) -> String:
	var new_path = original_path
	
	# Caso 1: Ruta absoluta con skeleton ("Skeleton3D:bone_name")
	if old_skeleton_name + ":" in original_path:
		new_path = original_path.replace(old_skeleton_name + ":", new_skeleton_name + ":")
		return new_path
	
	# Caso 2: Ruta relativa que ya empieza con "../" ("../Skeleton3D:bone_name")
	if original_path.begins_with("../") and old_skeleton_name + ":" in original_path:
		new_path = original_path.replace(old_skeleton_name + ":", new_skeleton_name + ":")
		return new_path
	
	# Caso 3: Ruta relativa sin "../" pero con skeleton ("Skeleton3D:bone_name")
	if old_skeleton_name + ":" in original_path and not original_path.begins_with("../"):
		new_path = "../" + original_path.replace(old_skeleton_name + ":", new_skeleton_name + ":")
		return new_path
	
	# Caso 4: Solo nombre de hueso ("bone_name") - asumir que va al skeleton principal
	if ":" not in original_path and not original_path.begins_with("../"):
		# Es probable que sea solo el nombre del hueso, agregar referencia al skeleton
		new_path = "../" + new_skeleton_name + ":" + original_path
		return new_path
	
	# Caso 5: Transformar property path ("Skeleton3D/bone_name")
	if "/" in original_path and old_skeleton_name in original_path:
		new_path = original_path.replace(old_skeleton_name + "/", new_skeleton_name + "/")
		return new_path
	
	return new_path

# Función para validar que las rutas de animación sean correctas
static func validate_animation_paths(anim_player: AnimationPlayer, skeleton: Skeleton3D) -> Dictionary:
	var validation_result = {
		"valid_tracks": 0,
		"invalid_tracks": 0,
		"missing_bones": [],
		"animations_validated": 0
	}
	
	if not anim_player or not skeleton:
		return validation_result
	
	print("🔍 VALIDANDO RUTAS DE ANIMACIÓN")
	
	# Crear lista de huesos disponibles
	var available_bones = []
	for i in range(skeleton.get_bone_count()):
		available_bones.append(skeleton.get_bone_name(i))
	
	# Validar cada animación
	for anim_name in anim_player.get_animation_list():
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(anim_name)
		
		if not animation:
			continue
		
		validation_result.animations_validated += 1
		
		# Validar cada track
		for track_idx in range(animation.get_track_count()):
			var track_path = animation.track_get_path(track_idx)
			var path_string = str(track_path)
			
			# Verificar si la ruta es válida
			if _is_valid_track_path(path_string, skeleton, available_bones):
				validation_result.valid_tracks += 1
			else:
				validation_result.invalid_tracks += 1
				
				# Intentar extraer nombre del hueso de la ruta
				var bone_name = _extract_bone_name_from_path(path_string)
				if bone_name != "" and bone_name not in available_bones:
					if bone_name not in validation_result.missing_bones:
						validation_result.missing_bones.append(bone_name)
	
	print("🔍 VALIDACIÓN COMPLETADA:")
	print("  Tracks válidos: %d" % validation_result.valid_tracks)
	print("  Tracks inválidos: %d" % validation_result.invalid_tracks)
	print("  Animaciones validadas: %d" % validation_result.animations_validated)
	
	if validation_result.missing_bones.size() > 0:
		print("  ⚠️ Huesos faltantes: %s" % str(validation_result.missing_bones))
	
	return validation_result

# Función para verificar si una ruta de track es válida
static func _is_valid_track_path(path_string: String, skeleton: Skeleton3D, available_bones: Array) -> bool:
	# Si la ruta contiene un nombre de hueso válido, probablemente es correcta
	var bone_name = _extract_bone_name_from_path(path_string)
	
	if bone_name != "":
		return bone_name in available_bones
	
	return false

# Función para extraer el nombre del hueso de una ruta de track
static func _extract_bone_name_from_path(path_string: String) -> String:
	# Casos comunes:
	# "../Skeleton3D:mixamorig_Hips"
	# "Skeleton3D:mixamorig_Hips"
	# "mixamorig_Hips"
	
	if ":" in path_string:
		var parts = path_string.split(":")
		if parts.size() >= 2:
			return parts[1]
	else:
		# Podría ser solo el nombre del hueso
		var cleaned_path = path_string.replace("../", "").replace("/", "")
		if cleaned_path != "" and not cleaned_path.begins_with("Skeleton"):
			return cleaned_path
	
	return ""

# Función para aplicar una pose específica de animación
static func apply_animation_pose(anim_player: AnimationPlayer, animation_name: String, time_position: float = 0.0) -> bool:
	if not anim_player or not anim_player.has_animation(animation_name):
		print("❌ No se puede aplicar pose: animación no encontrada")
		return false
	
	print("🎭 Aplicando pose de animación: %s en tiempo %.2fs" % [animation_name, time_position])
	
	# Reproducir la animación en la posición específica
	anim_player.play(animation_name)
	anim_player.seek(time_position, true)
	
	# Forzar actualización
	anim_player.advance(0.0)
	
	return true

# Función de debug para inspeccionar todas las rutas de animación
static func debug_animation_paths(anim_player: AnimationPlayer):
	print("\n🔍 DEBUG: INSPECCIONANDO RUTAS DE ANIMACIÓN")
	
	if not anim_player:
		print("❌ AnimationPlayer inválido")
		return
	
	for anim_name in anim_player.get_animation_list():
		print("🎭 Animación: %s" % anim_name)
		
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(anim_name)
		
		if not animation:
			print("  ❌ No se pudo obtener animación")
			continue
		
		print("  Tracks: %d" % animation.get_track_count())
		
		# Mostrar solo los primeros 5 tracks para evitar spam
		var max_tracks_to_show = min(animation.get_track_count(), 5)
		
		for track_idx in range(max_tracks_to_show):
			var track_path = animation.track_get_path(track_idx)
			var track_type = animation.track_get_type(track_idx)
			var track_type_name = _get_track_type_name(track_type)
			
			print("    [%d] %s (%s)" % [track_idx, str(track_path), track_type_name])
		
		if animation.get_track_count() > max_tracks_to_show:
			print("    ... y %d tracks más" % (animation.get_track_count() - max_tracks_to_show))
	
	print("🔍 FIN DEBUG RUTAS\n")

# Función auxiliar para obtener nombre del tipo de track
static func _get_track_type_name(track_type: int) -> String:
	match track_type:
		Animation.TYPE_ROTATION_3D:
			return "Rotation3D"
		Animation.TYPE_POSITION_3D:
			return "Position3D"
		Animation.TYPE_SCALE_3D:
			return "Scale3D"
		Animation.TYPE_BLEND_SHAPE:
			return "BlendShape"
		Animation.TYPE_VALUE:
			return "Value"
		Animation.TYPE_METHOD:
			return "Method"
		_:
			return "Unknown(%d)" % track_type
