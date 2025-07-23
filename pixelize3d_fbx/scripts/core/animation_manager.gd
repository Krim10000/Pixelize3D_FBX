# scripts/core/animation_manager.gd
# Input: Modelo base con meshes y animación FBX sin meshes  
# Output: Modelo combinado con meshes y animaciones listo para renderizar

extends Node

signal combination_complete(combined_model: Node3D)
signal combination_failed(error: String)

var base_meshes_cache = []

func set_base_meshes(meshes: Array) -> void:
	base_meshes_cache = meshes
	print("Base meshes cache actualizado: %d meshes" % meshes.size())
	for mesh_data in meshes:
		print("  Cache mesh: %s" % mesh_data.name)

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
	# CORRECCIÓN: Usar el cache mejorado en lugar de base_data.meshes
	var meshes_to_use = base_meshes_cache if base_meshes_cache.size() > 0 else base_data.meshes
	print("DEBUG: Usando %s mesh data (%d meshes)" % [
		"cached mejorado" if meshes_to_use == base_meshes_cache else "original fbx_loader", 
		meshes_to_use.size()
	])
	
	_attach_meshes_to_skeleton(meshes_to_use, new_skeleton)
	print("✅ Meshes anexados: %d" % meshes_to_use.size())
	
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

#func _duplicate_skeleton(original_skeleton: Skeleton3D) -> Skeleton3D:
	#print("--- DUPLICANDO SKELETON ---")
	#var new_skeleton = Skeleton3D.new()
	#new_skeleton.name = original_skeleton.name + "_combined"
	#
	#print("Filtrando meshes del skeleton:")
	#var valid_bones = 0
	#for i in range(original_skeleton.get_bone_count()):
		#var bone_name = original_skeleton.get_bone_name(i)
		#if !_is_mesh_node(bone_name):
			#valid_bones += 1
	#print("Huesos válidos: %d/%d" % [valid_bones, original_skeleton.get_bone_count()])
	#
	## Copiar la estructura de huesos
	#for i in range(original_skeleton.get_bone_count()):
		#var bone_name = original_skeleton.get_bone_name(i)
		#var bone_parent = original_skeleton.get_bone_parent(i)
		#var bone_rest = original_skeleton.get_bone_rest(i)
		#
		## Filtrar meshes que no son huesos reales
		#if _is_mesh_node(bone_name):
			#print("  Omitiendo mesh: %s" % bone_name)
			#continue
		#
		#new_skeleton.add_bone(bone_name)
		#var new_bone_index = new_skeleton.get_bone_count() - 1
		#
		## Ajustar índice del padre si es necesario
		#if bone_parent >= 0:
			#var adjusted_parent = _find_adjusted_parent_index(original_skeleton, new_skeleton, bone_parent)
			#if adjusted_parent >= 0:
				#new_skeleton.set_bone_parent(new_bone_index, adjusted_parent)
		#
		#new_skeleton.set_bone_rest(new_bone_index, bone_rest)
		#
		## Copiar la pose actual
		#var bone_pose = original_skeleton.get_bone_pose(i)
		#new_skeleton.set_bone_pose_position(new_bone_index, bone_pose.origin)
		#new_skeleton.set_bone_pose_rotation(new_bone_index, bone_pose.basis.get_rotation_quaternion())
		#new_skeleton.set_bone_pose_scale(new_bone_index, bone_pose.basis.get_scale())
		#
		#print("  Hueso copiado: %s (índice %d)" % [bone_name, new_bone_index])
	#
	#print("Skeleton duplicado: %d huesos reales" % new_skeleton.get_bone_count())
	#return new_skeleton
#
##func _is_mesh_node(bone_name: String) -> bool:
	### CORRECCIÓN: Lógica específica para detectar meshes vs huesos reales
	### Input: Nombre de un elemento del skeleton (String)
	### Output: true si es un mesh que debe filtrarse, false si es un hueso real
	##
	### REGLA 1: Si tiene prefijo de hueso conocido, ES un hueso real (mantener)
	##var known_bone_prefixes = ["mixamorig_", "mixamorig:", "Armature_", "RIG_", "rig_"]
	##for prefix in known_bone_prefixes:
		##if bone_name.begins_with(prefix):
			##return false  # Es un hueso real, no filtrar
	##
	### REGLA 2: Si NO tiene prefijo de hueso Y contiene indicadores de mesh, ES un mesh (filtrar)
	##var mesh_indicators = ["Body", "Pants", "Shirt", "Hair", "Mesh", "Geo", "Clothing"]
	##for indicator in mesh_indicators:
		##if indicator in bone_name:
			##print("  DEBUG: Detectado como mesh por indicador '%s': %s" % [indicator, bone_name])
			##return true  # Es un mesh, filtrar
	##
	### REGLA 3: Patrones específicos que indican meshes (sin prefijo de hueso)
	##if bone_name.ends_with("_mesh") or bone_name.ends_with("_Mesh"):
		##print("  DEBUG: Detectado como mesh por sufijo: %s" % bone_name)
		##return true
	##
	### REGLA 4: Si empieza con mayúscula y no tiene prefijo de hueso, probablemente es mesh
	##if bone_name[0].to_upper() == bone_name[0] and not "_" in bone_name:
		##print("  DEBUG: Detectado como posible mesh (sin prefijo, mayúscula): %s" % bone_name)
		##return true
	##
	### REGLA 5: En caso de duda, mantener (más seguro para no romper rigs)
	##print("  DEBUG: Manteniendo elemento ambiguo como hueso: %s" % bone_name)
	##return false

func _duplicate_skeleton(original_skeleton: Skeleton3D) -> Skeleton3D:
	print("--- DUPLICANDO SKELETON ---")
	var new_skeleton = Skeleton3D.new()
	new_skeleton.name = original_skeleton.name + "_combined"
	
	# Lista de huesos críticos que NUNCA deben ser filtrados
	var critical_bones = [
		"mixamorig_HeadTop_End", 
		"mixamorig_Hips", 
		"mixamorig_Spine",
		"mixamorig_Spine1",
		"mixamorig_Spine2",
		"mixamorig_Neck",
		"mixamorig_Head"
	]
	
	# Copiar la estructura de huesos
	for i in range(original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(i)
		var bone_parent = original_skeleton.get_bone_parent(i)
		var bone_rest = original_skeleton.get_bone_rest(i)
		
		# Verificar si es un hueso crítico (no filtrar)
		if bone_name in critical_bones:
			print("  ✅ Hueso crítico preservado: %s" % bone_name)
		else:
			# Filtrar meshes que no son huesos reales
			if _is_mesh_node(bone_name):
				print("  Omitiendo mesh: %s" % bone_name)
				continue
		
		new_skeleton.add_bone(bone_name)
		var new_bone_index = new_skeleton.get_bone_count() - 1
		
		# Ajustar índice del padre si es necesario
		if bone_parent >= 0:
			# Buscar el primer ancestro que exista en el nuevo skeleton
			var current_parent_idx = bone_parent
			var adjusted_parent = -1
			while current_parent_idx >= 0:
				var parent_name = original_skeleton.get_bone_name(current_parent_idx)
				adjusted_parent = new_skeleton.find_bone(parent_name)
				if adjusted_parent >= 0:
					break
				current_parent_idx = original_skeleton.get_bone_parent(current_parent_idx)
			
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
	
	# Verificar integridad del esqueleto
	var critical_missing = []
	for bone in critical_bones:
		if new_skeleton.find_bone(bone) == -1:
			critical_missing.append(bone)
	
	if critical_missing.size() > 0:
		printerr("❌ ERROR: Huesos críticos faltantes: ", critical_missing)
		new_skeleton.queue_free()
		return null
	
	return new_skeleton

# Reemplaza la función _is_mesh_node con esta versión mejorada

func _is_mesh_node(bone_name: String) -> bool:
	# REGLA 0: Excepciones para huesos Mixamo críticos
	var critical_bones = ["mixamorig_HeadTop_End", "mixamorig_Hips", "mixamorig_Spine"]
	if bone_name in critical_bones:
		return false  # Nunca filtrar estos huesos
	
	# REGLA 1: Prefijos de hueso conocidos
	var known_bone_prefixes = ["mixamorig_", "Bone_", "bone_", "Bip_", "bip_"]
	for prefix in known_bone_prefixes:
		if bone_name.begins_with(prefix):
			return false  # Es un hueso real
	
	# REGLA 2: Palabras clave de mesh
	var mesh_keywords = ["Body", "Top", "Pants", "Shirt", "Hair", "Mesh", "Geo", "Clothing"]
	for keyword in mesh_keywords:
		if keyword in bone_name:
			# Excluir si está en un prefijo de hueso conocido
			var is_exception = false
			for prefix in known_bone_prefixes:
				if bone_name.begins_with(prefix):
					is_exception = true
					break
					
			if !is_exception:
				return true
	
	# REGLA 3: Formato de nombre de objeto
	if bone_name[0].to_upper() == bone_name[0] && bone_name.find("_") == -1:
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
		new_mesh_instance.set_meta("is_attached_mesh", true)
		# Configurar el skeleton path
		new_mesh_instance.skeleton = NodePath("..")
		
		# Aplicar materiales correctamente
		if mesh_data.has("materials") and mesh_data.materials.size() > 0:
			for i in range(mesh_data.materials.size()):
				if mesh_data.materials[i] != null:
					new_mesh_instance.set_surface_override_material(i, mesh_data.materials[i])
					print("    Material aplicado en superficie %d: %s" % [i, mesh_data.materials[i].resource_name if mesh_data.materials[i].resource_name else "Material"])
		
		# Añadir al skeleton ANTES de configurar el skin
		skeleton.add_child(new_mesh_instance)
		
		# CORRECCIÓN CLAVE: Retargetear el skin original al skeleton combinado
		if mesh_data.has("original_skin") and mesh_data.original_skin:
			var retargeted_skin = _retarget_skin_to_skeleton(mesh_data.original_skin, skeleton)
			if retargeted_skin:
				new_mesh_instance.skin = retargeted_skin
				print("    ✅ Skin retargeteado exitosamente")
			else:
				print("    ❌ Error al retargetear skin")
		else:
			print("    ⚠️  No hay skin original para retargetear")
		
		print("  Mesh anexado: %s" % mesh_data.name)
		print("    Mesh resource: %s" % (mesh_data.mesh_resource.get_class() if mesh_data.mesh_resource else "NULL"))
		print("    Surfaces: %d" % (mesh_data.mesh_resource.get_surface_count() if mesh_data.mesh_resource else 0))
		print("    Skeleton path: %s" % new_mesh_instance.skeleton)
		print("    Skin asignado: %s" % (new_mesh_instance.skin != null))
		
		# Debug: Verificar el estado final del mesh
		call_deferred("_debug_mesh_skin_binding", new_mesh_instance, skeleton)

# Función de debug para verificar el skin binding (se ejecuta después del frame)
func _debug_mesh_skin_binding(mesh_instance: MeshInstance3D, skeleton: Skeleton3D):
	if not mesh_instance or not skeleton:
		return
		
	print("  DEBUG SKIN BINDING - %s:" % mesh_instance.name)
	print("    Skeleton válido: %s" % (skeleton != null))
	print("    Skeleton path: %s" % mesh_instance.skeleton)
	print("    Skin asignado: %s" % (mesh_instance.skin != null))
	
	if mesh_instance.skin:
		print("    Skin bind count: %d" % mesh_instance.skin.get_bind_count())
		print("    Skeleton bone count: %d" % skeleton.get_bone_count())
		
		# Verificar que los bind names coincidan con los huesos del skeleton
		var missing_bones = []
		for i in range(mesh_instance.skin.get_bind_count()):
			var bind_name = mesh_instance.skin.get_bind_name(i)
			if skeleton.find_bone(bind_name) == -1:
				missing_bones.append(bind_name)
		
		if missing_bones.size() > 0:
			print("    ❌ Huesos faltantes en skin: %s" % str(missing_bones))
		else:
			print("    ✅ Todos los bind names encontrados en skeleton")
	else:
		print("    ❌ Sin skin asignado - el mesh no se deformará con animaciones")

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

# Función mejorada para extraer mesh data desde un skeleton
# Esta función debe usarse en lugar de _extract_mesh_list en main.gd
func extract_enhanced_mesh_data(skeleton: Skeleton3D) -> Array:
	var meshes = []
	
	print("--- EXTRAYENDO MESH DATA MEJORADO ---")
	print("Skeleton: %s (%d huesos)" % [skeleton.name, skeleton.get_bone_count()])
	
	# Buscar MeshInstance3D directamente en el skeleton
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			var mesh_data = {
				"node": child,
				"mesh_resource": child.mesh,
				"name": child.name,
				"materials": [],
				"skeleton_path": child.get_path_to(skeleton),
				"original_skin": child.skin  # Guardar referencia pero no usar directamente
			}
			
			# Extraer TODOS los materiales de todas las superficies
			if child.mesh and child.mesh.get_surface_count() > 0:
				for i in range(child.mesh.get_surface_count()):
					var material = null
					
					# Prioridad a material override
					if child.get_surface_override_material(i):
						material = child.get_surface_override_material(i)
					# Si no hay override, usar material del mesh
					elif child.mesh.surface_get_material(i):
						material = child.mesh.surface_get_material(i)
					
					mesh_data.materials.append(material)
					
					print("  Mesh: %s, Superficie %d: %s" % [
						child.name, 
						i, 
						material.resource_name if material and material.resource_name else "Sin material"
					])
			
			# Debug adicional
			print("  Mesh encontrado: %s" % child.name)
			print("    Mesh resource: %s" % (child.mesh.get_class() if child.mesh else "NULL"))
			print("    Surfaces: %d" % (child.mesh.get_surface_count() if child.mesh else 0))
			print("    Materiales extraídos: %d" % mesh_data.materials.size())
			print("    Skin original: %s" % (child.skin != null))
			
			meshes.append(mesh_data)
	
	print("Total meshes extraídos: %d" % meshes.size())
	return meshes

# Función para retargetear un skin al skeleton combinado
# Input: Skin original y skeleton combinado
# Output: Skin nuevo compatible con el skeleton combinado
#func _retarget_skin_to_skeleton(original_skin: Skin, target_skeleton: Skeleton3D) -> Skin:
	#if not original_skin or not target_skeleton:
		#print("    DEBUG: Parámetros inválidos para retargeting")
		#return null
	#
	#print("    DEBUG: Retargeteando skin...")
	#print("      Skin original bind count: %d" % original_skin.get_bind_count())
	#print("      Target skeleton bone count: %d" % target_skeleton.get_bone_count())
	#
	#var new_skin = Skin.new()
	#var successful_binds = 0
	#var failed_binds = []
	#
	## Procesar cada bind del skin original
	#for i in range(original_skin.get_bind_count()):
		#var bind_name = original_skin.get_bind_name(i)
		#var bind_pose = original_skin.get_bind_pose(i)
		#
		## Buscar el hueso correspondiente en el skeleton de destino
		#var bone_index = target_skeleton.find_bone(bind_name)
		#
		#if bone_index >= 0:
			## El hueso existe en el skeleton de destino
			#new_skin.add_bind(bone_index, bind_pose)
			#new_skin.set_bind_name(new_skin.get_bind_count() - 1, bind_name)
			#successful_binds += 1
			#print("        ✅ Bind mapeado: %s -> índice %d" % [bind_name, bone_index])
		#else:
			## El hueso no existe, intentar mapeo alternativo
			#var mapped_name = _try_alternative_bone_mapping(bind_name, target_skeleton)
			#if mapped_name != "":
				#var alt_bone_index = target_skeleton.find_bone(mapped_name)
				#if alt_bone_index >= 0:
					#new_skin.add_bind(alt_bone_index, bind_pose)
					#new_skin.set_bind_name(new_skin.get_bind_count() - 1, mapped_name)
					#successful_binds += 1
					#print("        ✅ Bind mapeado (alternativo): %s -> %s (índice %d)" % [bind_name, mapped_name, alt_bone_index])
				#else:
					#failed_binds.append(bind_name)
			#else:
				#failed_binds.append(bind_name)
				#print("        ❌ Hueso no encontrado: %s" % bind_name)
	#
	#print("      Resultado: %d/%d binds exitosos" % [successful_binds, original_skin.get_bind_count()])
	#
	#if failed_binds.size() > 0:
		#print("      Binds fallidos: %s" % str(failed_binds))
	#
	## Solo devolver el skin si tenemos un número razonable de binds exitosos
	#if successful_binds > 0 and (float(successful_binds) / float(original_skin.get_bind_count())) > 0.5:
		#print("    ✅ Skin retargeteado exitosamente")
		#return new_skin
	#else:
		#print("    ❌ Muy pocos binds exitosos para un skin funcional")
		#return null

func _retarget_skin_to_skeleton(original_skin: Skin, target_skeleton: Skeleton3D) -> Skin:
	if not original_skin or not target_skeleton:
		printerr("❌ Error: Parámetros inválidos para retargeting de skin")
		return null
	
	print("    DEBUG: Retargeteando skin...")
	print("      Skin original bind count: %d" % original_skin.get_bind_count())
	print("      Target skeleton bone count: %d" % target_skeleton.get_bone_count())
	
	var new_skin = Skin.new()
	var successful_binds = 0
	var failed_binds = []
	
	# Crear lista de nombres de huesos en el target skeleton
	var target_bone_names = []
	for i in range(target_skeleton.get_bone_count()):
		target_bone_names.append(target_skeleton.get_bone_name(i))
	
	# Procesar cada bind del skin original
	for i in range(original_skin.get_bind_count()):
		var bind_name = original_skin.get_bind_name(i)
		var bind_pose = original_skin.get_bind_pose(i)
		
		# Buscar el hueso correspondiente en el skeleton de destino
		var bone_index = target_skeleton.find_bone(bind_name)
		
		if bone_index >= 0:
			# El hueso existe en el skeleton de destino
			new_skin.add_bind(bone_index, bind_pose)
			new_skin.set_bind_name(new_skin.get_bind_count() - 1, bind_name)
			successful_binds += 1
			print("        ✅ Bind mapeado: %s -> índice %d" % [bind_name, bone_index])
		else:
			# Intentar mapeo alternativo
			var alternative_name = ""
			var alternative_index = -1
			
			# Estrategia 1: Buscar por similitud de nombre
			for target_name in target_bone_names:
				if bind_name.similarity(target_name) > 0.85:
					alternative_name = target_name
					alternative_index = target_skeleton.find_bone(target_name)
					break
			
			# Estrategia 2: Variaciones comunes
			if alternative_index == -1:
				var variations = [
					bind_name.replace("mixamorig:", "mixamorig_"),
					bind_name.replace("mixamorig_", "mixamorig:"),
					bind_name.replace(" ", "_"),
					bind_name.to_lower(),
					bind_name.to_upper()
				]
				
				for variant in variations:
					if variant in target_bone_names:
						alternative_name = variant
						alternative_index = target_skeleton.find_bone(variant)
						break
			
			if alternative_index >= 0:
				new_skin.add_bind(alternative_index, bind_pose)
				new_skin.set_bind_name(new_skin.get_bind_count() - 1, bind_name)
				successful_binds += 1
				print("        🔄 Bind alternativo: %s -> %s (índice %d)" % [bind_name, alternative_name, alternative_index])
			else:
				failed_binds.append(bind_name)
				print("        ❌ Hueso no encontrado: %s" % bind_name)
	
	print("      Resultado: %d/%d binds exitosos" % [successful_binds, original_skin.get_bind_count()])
	
	# Manejar binds fallidos críticos
	var critical_bones = ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Head"]
	var critical_failed = []
	for bone in critical_bones:
		if bone in failed_binds:
			critical_failed.append(bone)
	
	if critical_failed.size() > 0:
		printerr("❌ ERROR: Binds críticos faltantes: ", critical_failed)
		return null
	
	# Crear skin solo si tenemos suficientes binds exitosos
	if successful_binds == 0:
		printerr("❌ ERROR: Ningún bind exitoso en el skin")
		return null
	
	# Advertencia si faltan muchos binds
	var success_rate = float(successful_binds) / original_skin.get_bind_count()
	if success_rate < 0.9:
		printerr("⚠️ ADVERTENCIA: Solo %.1f%% de binds exitosos" % (success_rate * 100))
	
	return new_skin


# Función auxiliar para mapeo alternativo de nombres de huesos
func _try_alternative_bone_mapping(bind_name: String, skeleton: Skeleton3D) -> String:
	# Intentar variaciones comunes del nombre del hueso
	var alternatives = []
	
	# Variaciones de prefijos Mixamo
	if bind_name.begins_with("mixamorig:"):
		alternatives.append(bind_name.replace("mixamorig:", "mixamorig_"))
	elif bind_name.begins_with("mixamorig_"):
		alternatives.append(bind_name.replace("mixamorig_", "mixamorig:"))
	
	# Probar sin prefijos
	if ":" in bind_name:
		alternatives.append(bind_name.split(":")[1])
	elif "_" in bind_name and bind_name.begins_with("mixamorig"):
		alternatives.append(bind_name.substr(10))  # Remover "mixamorig_"
	
	# Variaciones de mayúsculas/minúsculas
	alternatives.append(bind_name.to_lower())
	alternatives.append(bind_name.to_upper())
	
	# Buscar cada alternativa en el skeleton
	for alt_name in alternatives:
		if skeleton.find_bone(alt_name) >= 0:
			return alt_name
	
	return ""  # No se encontró alternativa
