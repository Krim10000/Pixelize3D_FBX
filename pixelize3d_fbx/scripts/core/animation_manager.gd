# scripts/core/animation_manager.gd
extends Node

# Input: Modelo base con meshes y animación FBX sin meshes
# Output: Modelo combinado con meshes y animaciones listo para renderizar

signal combination_complete(combined_model: Node3D)
signal combination_failed(error: String)

var base_meshes_cache = []

func set_base_meshes(meshes: Array) -> void:
	base_meshes_cache = meshes

func combine_base_with_animation(base_data: Dictionary, animation_data: Dictionary) -> Node3D:
	print("\n=== INICIANDO COMBINACIÓN ===")
	print("Base: %s (%d huesos)" % [base_data.skeleton.name, base_data.get("bone_count", 0)])
	print("Anim: %s (%d huesos)" % [animation_data.skeleton.name, animation_data.get("bone_count", 0)])
	
	# Crear un nuevo nodo raíz para el modelo combinado
	var combined_root = Node3D.new()
	combined_root.name = "Combined_" + animation_data.name
	
	# Duplicar el skeleton del modelo base (sin bone mapping por ahora)
	var new_skeleton = _duplicate_skeleton(base_data.skeleton)
	if not new_skeleton:
		print("❌ Error al duplicar skeleton")
		emit_signal("combination_failed", "Error al duplicar skeleton")
		combined_root.queue_free()
		return null
	
	combined_root.add_child(new_skeleton)
	print("✅ Skeleton duplicado: %d huesos" % new_skeleton.get_bone_count())
	
	# Añadir los meshes del modelo base al nuevo skeleton
	_attach_meshes_to_skeleton(base_data.meshes, new_skeleton)
	print("✅ Meshes anexados: %d" % base_data.meshes.size())
	
	# Copiar el AnimationPlayer de la animación
	var new_anim_player = _setup_animation_player(animation_data.animation_player, animation_data.skeleton, new_skeleton)
	if not new_anim_player:
		print("❌ Error al configurar AnimationPlayer")
		emit_signal("combination_failed", "Error al configurar AnimationPlayer")
		combined_root.queue_free()
		return null
	
	combined_root.add_child(new_anim_player)
	print("✅ AnimationPlayer configurado: %d animaciones" % new_anim_player.get_animation_list().size())
	
	# Configurar las animaciones para que apunten al nuevo skeleton
	_retarget_animations(new_anim_player, animation_data.skeleton, new_skeleton)
	print("✅ Animaciones retargeteadas")
	
	# Aplicar la pose inicial
	if new_anim_player.get_animation_list().size() > 0:
		var first_anim = new_anim_player.get_animation_list()[0]
		print("✅ Aplicando pose inicial: %s" % first_anim)
		new_anim_player.play(first_anim)
		new_anim_player.seek(0, true)
		new_anim_player.pause()  # Pausar en el primer frame
	
	print("✅ Combinación completada exitosamente")
	emit_signal("combination_complete", combined_root)
	return combined_root

func _duplicate_skeleton(original_skeleton: Skeleton3D) -> Skeleton3D:
	print("--- DUPLICANDO SKELETON ---")
	var new_skeleton = Skeleton3D.new()
	new_skeleton.name = original_skeleton.name + "_combined"
	
	# Copiar la estructura de huesos
	for i in range(original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(i)
		var bone_parent = original_skeleton.get_bone_parent(i)
		var bone_rest = original_skeleton.get_bone_rest(i)
		
		# Filtrar meshes que no son huesos reales
		if _is_mesh_node(bone_name):
			print("  Omitiendo mesh: %s" % bone_name)
			continue
		
		new_skeleton.add_bone(bone_name)
		var new_bone_index = new_skeleton.get_bone_count() - 1
		
		# Ajustar índice del padre si es necesario
		if bone_parent >= 0:
			var adjusted_parent = _find_adjusted_parent_index(original_skeleton, new_skeleton, bone_parent)
			if adjusted_parent >= 0:
				new_skeleton.set_bone_parent(new_bone_index, adjusted_parent)
		
		new_skeleton.set_bone_rest(new_bone_index, bone_rest)
		
		# Copiar la pose actual
		var bone_pose = original_skeleton.get_bone_pose(i)
		new_skeleton.set_bone_pose_position(new_bone_index, bone_pose.origin)
		new_skeleton.set_bone_pose_rotation(new_bone_index, bone_pose.basis.get_rotation_quaternion())
		new_skeleton.set_bone_pose_scale(new_bone_index, bone_pose.basis.get_scale())
		
		print("  Hueso copiado: %s (índice %d)" % [bone_name, new_bone_index])
	
	print("Skeleton duplicado: %d huesos reales" % new_skeleton.get_bone_count())
	return new_skeleton

func _is_mesh_node(bone_name: String) -> bool:
	# Detectar si un "hueso" es realmente un mesh
	var mesh_indicators = ["Body", "Top", "Pants", "Shirt", "Hair", "Head", "Mesh", "Geo"]
	
	for indicator in mesh_indicators:
		if indicator in bone_name:
			return true
	
	# También verificar si no tiene prefijo de hueso
	if not bone_name.begins_with("mixamorig"):
		return true
	
	return false

func _find_adjusted_parent_index(original_skeleton: Skeleton3D, new_skeleton: Skeleton3D, original_parent_index: int) -> int:
	# Encontrar el índice ajustado del padre en el nuevo skeleton
	var parent_bone_name = original_skeleton.get_bone_name(original_parent_index)
	
	# Si el padre es un mesh, buscar el primer ancestro que sea un hueso real
	if _is_mesh_node(parent_bone_name):
		var ancestor_index = original_skeleton.get_bone_parent(original_parent_index)
		if ancestor_index >= 0:
			return _find_adjusted_parent_index(original_skeleton, new_skeleton, ancestor_index)
		else:
			return -1
	
	# Buscar el hueso en el nuevo skeleton
	return new_skeleton.find_bone(parent_bone_name)

func _attach_meshes_to_skeleton(meshes: Array, skeleton: Skeleton3D) -> void:
	print("--- ANEXANDO MESHES ---")
	for mesh_data in meshes:
		var new_mesh_instance = MeshInstance3D.new()
		new_mesh_instance.name = mesh_data.name
		new_mesh_instance.mesh = mesh_data.mesh_resource
		
		# Configurar el skeleton path
		new_mesh_instance.skeleton = NodePath("..")
		
		# Aplicar materiales
		for i in range(mesh_data.materials.size()):
			if i < new_mesh_instance.get_surface_override_material_count():
				new_mesh_instance.set_surface_override_material(i, mesh_data.materials[i])
		
		skeleton.add_child(new_mesh_instance)
		print("  Mesh anexado: %s" % mesh_data.name)
		
		# Si el mesh original tenía información de skin, copiarla
		if mesh_data.has("node") and mesh_data.node and mesh_data.node.skin:
			new_mesh_instance.skin = mesh_data.node.skin

func _setup_animation_player(original_player: AnimationPlayer, _original_skeleton: Skeleton3D, _new_skeleton: Skeleton3D) -> AnimationPlayer:
	print("--- CONFIGURANDO ANIMATION PLAYER ---")
	if not original_player:
		print("❌ No hay AnimationPlayer original")
		return null
	
	var new_player = AnimationPlayer.new()
	new_player.name = "AnimationPlayer"
	
	# Crear biblioteca de animaciones
	var anim_library = AnimationLibrary.new()
	new_player.add_animation_library("", anim_library)
	
	# Copiar todas las animaciones
	for anim_name in original_player.get_animation_list():
		var original_anim = original_player.get_animation(anim_name)
		if original_anim:
			var new_anim = original_anim.duplicate(true)
			anim_library.add_animation(anim_name, new_anim)
			print("  Animación copiada: %s (%.2fs)" % [anim_name, new_anim.length])
	
	# Configurar el root node
	new_player.root_node = NodePath("..")
	
	return new_player

func _retarget_animations(anim_player: AnimationPlayer, old_skeleton: Skeleton3D, new_skeleton: Skeleton3D) -> void:
	print("--- RETARGETING ANIMATIONS ---")
	print("Old skeleton: %s" % old_skeleton.name)
	print("New skeleton: %s" % new_skeleton.name)
	
	# Crear mapeo de huesos para el retargeting
	var bone_mapping = _create_bone_mapping(old_skeleton, new_skeleton)
	print("Mapeo de huesos creado: %d coincidencias" % bone_mapping.size())
	
	# Actualizar rutas en las animaciones
	for anim_name in anim_player.get_animation_list():
		var anim_lib = anim_player.get_animation_library("")
		var anim = anim_lib.get_animation(anim_name)
		if not anim:
			continue
		
		print("Retargeting animación: %s (%d tracks)" % [anim_name, anim.get_track_count()])
		
		var tracks_updated = 0
		for track_idx in range(anim.get_track_count()):
			var track_path = anim.track_get_path(track_idx)
			var path_string = str(track_path)
			
			# Actualizar ruta para apuntar al nuevo skeleton
			var new_path = _convert_animation_path(path_string, old_skeleton.name, new_skeleton.name)
			if new_path != path_string:
				anim.track_set_path(track_idx, NodePath(new_path))
				tracks_updated += 1
		
		print("  Tracks actualizados: %d/%d" % [tracks_updated, anim.get_track_count()])

func _create_bone_mapping(old_skeleton: Skeleton3D, new_skeleton: Skeleton3D) -> Dictionary:
	var mapping = {}
	
	# Mapear huesos con nombres exactos primero
	for i in range(new_skeleton.get_bone_count()):
		var new_bone_name = new_skeleton.get_bone_name(i)
		var old_bone_index = old_skeleton.find_bone(new_bone_name)
		
		if old_bone_index >= 0:
			mapping[new_bone_name] = new_bone_name
		else:
			# Intentar mapeo con limpieza de nombres
			var cleaned_name = _clean_bone_name(new_bone_name)
			var old_cleaned_index = -1
			
			for j in range(old_skeleton.get_bone_count()):
				if _clean_bone_name(old_skeleton.get_bone_name(j)) == cleaned_name:
					old_cleaned_index = j
					break
			
			if old_cleaned_index >= 0:
				mapping[new_bone_name] = old_skeleton.get_bone_name(old_cleaned_index)
	
	return mapping

func _clean_bone_name(bone_name: String) -> String:
	var cleaned = bone_name
	
	# Remover prefijos comunes de Mixamo
	if cleaned.begins_with("mixamorig:"):
		cleaned = cleaned.substr(10)
	elif cleaned.begins_with("mixamorig_"):
		cleaned = cleaned.substr(10)
	
	# Remover otros prefijos comunes
	var common_prefixes = ["RIG_", "rig_", "Armature_", "armature_"]
	for prefix in common_prefixes:
		if cleaned.begins_with(prefix):
			cleaned = cleaned.substr(prefix.length())
			break
	
	return cleaned

func _convert_animation_path(original_path: String, old_skeleton_name: String, new_skeleton_name: String) -> String:
	var new_path = original_path
	
	# Reemplazar nombre del skeleton en la ruta
	if old_skeleton_name in new_path:
		new_path = new_path.replace(old_skeleton_name + ":", new_skeleton_name + ":")
	
	# Manejar rutas relativas
	if new_path.begins_with("../"):
		# Ya es una ruta relativa, solo asegurar que apunte al skeleton correcto
		if old_skeleton_name + ":" in new_path:
			new_path = new_path.replace(old_skeleton_name + ":", new_skeleton_name + ":")
	else:
		# Convertir a ruta relativa si es necesario
		if new_skeleton_name + ":" in new_path and not new_path.begins_with("../"):
			new_path = "../" + new_path
	
	return new_path

# Función para obtener información de una animación específica
func get_animation_info(anim_player: AnimationPlayer, anim_name: String) -> Dictionary:
	if not anim_player or not anim_player.has_animation(anim_name):
		return {}
	
	var anim = anim_player.get_animation(anim_name)
	
	return {
		"name": anim_name,
		"length": anim.length,
		"fps": 1.0 / anim.step if anim.step > 0 else 30.0,
		"frame_count": int(anim.length / anim.step) if anim.step > 0 else int(anim.length * 30.0),
		"loop": anim.loop_mode != Animation.LOOP_NONE
	}

# Función para preparar un modelo para renderizado
func prepare_model_for_rendering(model: Node3D, frame: int, total_frames: int, animation_name: String) -> void:
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		return
	
	if anim_player.has_animation(animation_name):
		anim_player.play(animation_name)
		var time = (float(frame) / float(total_frames)) * anim_player.get_animation(animation_name).length
		anim_player.seek(time, true)
		
		# Forzar actualización de la pose
		anim_player.advance(0.0)

# Función de debug para mostrar información del skeleton
func debug_skeleton_info(skeleton: Skeleton3D, title: String = "Skeleton Info"):
	print("\n=== %s ===" % title)
	print("Nombre: %s" % skeleton.name)
	print("Cantidad de huesos: %d" % skeleton.get_bone_count())
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		var parent = skeleton.get_bone_parent(i)
		var parent_name = "ROOT" if parent < 0 else skeleton.get_bone_name(parent)
		print("  [%d] %s <- %s" % [i, bone_name, parent_name])

# Función de debug para probar combinación
func debug_combination(base_data: Dictionary, animation_data: Dictionary):
	print("\n=== DEBUG COMBINATION ===")
	
	if not base_data or not animation_data:
		print("❌ Datos faltantes")
		return
	
	print("Base skeleton: %s (%d huesos)" % [base_data.skeleton.name, base_data.get("bone_count", 0)])
	print("Anim skeleton: %s (%d huesos)" % [animation_data.skeleton.name, animation_data.get("bone_count", 0)])
	
	# Mostrar primeros 10 huesos de cada uno
	print("\nPrimeros 10 huesos del base:")
	for i in range(min(10, base_data.skeleton.get_bone_count())):
		print("  %s" % base_data.skeleton.get_bone_name(i))
	
	print("\nPrimeros 10 huesos de la animación:")  
	for i in range(min(10, animation_data.skeleton.get_bone_count())):
		print("  %s" % animation_data.skeleton.get_bone_name(i))
	
	# Verificar compatibilidad
	var compatible_bones = 0
	for i in range(animation_data.skeleton.get_bone_count()):
		var anim_bone = animation_data.skeleton.get_bone_name(i)
		if base_data.skeleton.find_bone(anim_bone) >= 0:
			compatible_bones += 1
	
	print("Huesos compatibles: %d/%d (%.1f%%)" % [
		compatible_bones, 
		animation_data.skeleton.get_bone_count(),
		100.0 * compatible_bones / animation_data.skeleton.get_bone_count()
	])
