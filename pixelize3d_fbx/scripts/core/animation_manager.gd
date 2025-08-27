# scripts/core/animation_manager.gd
# VERSIÓN MEJORADA - Input: Modelo base con meshes y animación FBX sin meshes  
# Output: Modelo combinado con meshes, animaciones Y METADATOS DE ARCHIVO preservados

extends Node

signal combination_complete(combined_model: Node3D)
signal combination_failed(error: String)

var base_meshes_cache = []
var current_building_animation_player: AnimationPlayer = null
var LoopManagerClass = preload("res://scripts/core/animation_loop_manager.gd")
var loop_manager = LoopManagerClass.new()

# ✅ NUEVO: Cache para metadatos de animaciones
var animations_metadata_cache = {}

# Cargar el script de retargeting fix y loop manager
var retargeting_fix = preload("res://scripts/core/animation_retargeting_fix.gd")

func set_base_meshes(meshes: Array) -> void:
	base_meshes_cache = meshes
	print("Base meshes cache actualizado: %d meshes" % meshes.size())
	for mesh_data in meshes:
		print("  Cache mesh: %s" % mesh_data.name)

# ✅ NUEVA FUNCIÓN: Registrar metadatos de animación
func register_animation_metadata(animation_name: String, metadata: Dictionary) -> void:
	animations_metadata_cache[animation_name] = metadata
	print("✅ Metadatos registrados para animación: %s" % animation_name)
	print("  - Archivo: %s" % metadata.get("original_filename", "desconocido"))
	print("  - Display: %s" % metadata.get("display_name", "desconocido"))

# ✅ NUEVA FUNCIÓN: Registrar múltiples metadatos de animaciones
func register_multiple_animations_metadata(animations_data: Dictionary) -> void:
	for anim_name in animations_data.keys():
		var _anim_data = animations_data[anim_name]
		pass
#metadata = animations_metadata_cache[anim_data]
		##if anim_data.has("file_metadata"):
		#register_animation_metadata(anim_name, metadata)

func combine_base_with_animation(base_data: Dictionary, animation_data: Dictionary) -> Node3D:
	print("\n=== INICIANDO COMBINACIÓN CON METADATOS ===")
	print("Base: %s (%d huesos)" % [base_data.skeleton.name, base_data.get("bone_count", 0)])
	print("Anim: %s (%d huesos)" % [animation_data.skeleton.name, animation_data.get("bone_count", 0)])
	
	# Crear un nuevo nodo raíz para el modelo combinado
	var combined_root = Node3D.new()
	combined_root.name = animation_data.get("display_name", animation_data.name)
	
	# ✅ CRÍTICO: Almacenar metadatos en el modelo combinado
	_store_metadata_in_combined_model(combined_root, base_data, animation_data)
	
	# Duplicar el skeleton del modelo base
	var new_skeleton = _duplicate_skeleton(base_data.skeleton)
	if not new_skeleton:
		print("❌ Error al duplicar skeleton")
		emit_signal("combination_failed", "Error al duplicar skeleton")
		combined_root.queue_free()
		return null
	
	# IMPORTANTE: Dar nombre específico al nuevo skeleton para retargeting
	new_skeleton.name = "Skeleton3D_combined"
	combined_root.add_child(new_skeleton)
	print("✅ Skeleton duplicado: %s con %d huesos" % [new_skeleton.name, new_skeleton.get_bone_count()])
	
	# Añadir los meshes del modelo base al nuevo skeleton
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
	
	# CORRECCIÓN CRÍTICA: Usar el nuevo sistema de retargeting
	var retargeting_success = _retarget_animations_fixed(new_anim_player, animation_data.skeleton, new_skeleton)
	if not retargeting_success:
		print("❌ Error crítico en retargeting de animaciones")
		emit_signal("combination_failed", "Error en retargeting de animaciones")
		combined_root.queue_free()
		return null
	
	print("✅ Animaciones retargeteadas correctamente")
	
	# NUEVO: Configurar loops infinitos en todas las animaciones
	loop_manager.setup_infinite_loops(new_anim_player)
	print("🔄 Loops infinitos configurados")
	
	##########################################################
	##########################################################
	##########################################################
	
	
# Aplicar la pose inicial de la NUEVA animación
	# Aplicar la pose inicial de la ÚLTIMA animación disponible
	var animation_list = new_anim_player.get_animation_list()
	if animation_list.size() > 0:
		var last_index = animation_list.size() - 1
		var target_anim_name = animation_list[last_index]

		print("✅ Aplicando pose inicial (última animación): %s" % target_anim_name)

		# Configurar loop y aplicar pose inicial de forma segura
		var anim_lib = new_anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(target_anim_name)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR

		# Como el AnimationPlayer ya está en el modelo combinado, puede usar play directamente
		new_anim_player.play(target_anim_name)


	
	print("✅ Combinación completada exitosamente con metadatos")
	emit_signal("combination_complete", combined_root)
	return combined_root




func combine_base_with_animation_for_transition(base_data: Dictionary, animation_data: Dictionary) -> Node3D:
	print("\n=== INICIANDO COMBINACIÓN CON METADATOS ===")
	print("Base: %s (%d huesos)" % [base_data.skeleton.name, base_data.get("bone_count", 0)])
	print("Anim: %s (%d huesos)" % [animation_data.skeleton.name, animation_data.get("bone_count", 0)])
	
	# Crear un nuevo nodo raíz para el modelo combinado
	var combined_root = Node3D.new()
	combined_root.name = animation_data.get("display_name", animation_data.name)
	
	# ✅ CRÍTICO: Almacenar metadatos en el modelo combinado
	_store_metadata_in_combined_model(combined_root, base_data, animation_data)
	
	# Duplicar el skeleton del modelo base
	var new_skeleton = _duplicate_skeleton(base_data.skeleton)
	if not new_skeleton:
		print("❌ Error al duplicar skeleton")
		emit_signal("combination_failed", "Error al duplicar skeleton")
		combined_root.queue_free()
		return null
	
	# IMPORTANTE: Dar nombre específico al nuevo skeleton para retargeting
	new_skeleton.name = "Skeleton3D_combined"
	combined_root.add_child(new_skeleton)
	print("✅ Skeleton duplicado: %s con %d huesos" % [new_skeleton.name, new_skeleton.get_bone_count()])
	
	# Añadir los meshes del modelo base al nuevo skeleton
	var meshes_to_use = base_meshes_cache if base_meshes_cache.size() > 0 else base_data.meshes
	print("DEBUG: Usando %s mesh data (%d meshes)" % [
		"cached mejorado" if meshes_to_use == base_meshes_cache else "original fbx_loader", 
		meshes_to_use.size()
	])
	
	_attach_meshes_to_skeleton(meshes_to_use, new_skeleton)
	print("✅ Meshes anexados: %d" % meshes_to_use.size())
	
	# Copiar el AnimationPlayer de la animación
	var new_anim_player = _setup_animation_player_for_transition(animation_data.animation_player, animation_data.skeleton, new_skeleton)
	if not new_anim_player:
		print("❌ Error al configurar AnimationPlayer")
		emit_signal("combination_failed", "Error al configurar AnimationPlayer")
		combined_root.queue_free()
		return null
	
	combined_root.add_child(new_anim_player)
	print("✅ AnimationPlayer configurado: %d animaciones" % new_anim_player.get_animation_list().size())
	
	# CORRECCIÓN CRÍTICA: Usar el nuevo sistema de retargeting
	var retargeting_success = _retarget_animations_fixed(new_anim_player, animation_data.skeleton, new_skeleton)
	if not retargeting_success:
		print("❌ Error crítico en retargeting de animaciones")
		emit_signal("combination_failed", "Error en retargeting de animaciones")
		combined_root.queue_free()
		return null
	
	print("✅ Animaciones retargeteadas correctamente")
	
	# NUEVO: Configurar loops infinitos en todas las animaciones
	loop_manager.setup_infinite_loops(new_anim_player)
	print("🔄 Loops infinitos configurados")
	
	##########################################################
	##########################################################
	##########################################################
	
	
# Aplicar la pose inicial de la NUEVA animación
	# Aplicar la pose inicial de la ÚLTIMA animación disponible
	var animation_list = new_anim_player.get_animation_list()
	if animation_list.size() > 0:
		var last_index = animation_list.size() - 1
		var target_anim_name = animation_list[last_index]

		print("✅ Aplicando pose inicial (última animación): %s" % target_anim_name)

		# Configurar loop y aplicar pose inicial de forma segura
		var anim_lib = new_anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(target_anim_name)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR

		# Como el AnimationPlayer ya está en el modelo combinado, puede usar play directamente
		new_anim_player.play(target_anim_name)


	
	print("✅ Combinación completada exitosamente con metadatos")
	emit_signal("combination_complete", combined_root)
	return combined_root





# ✅ FUNCIÓN NUEVA: Almacenar metadatos en el modelo combinado
func _store_metadata_in_combined_model(combined_root: Node3D, base_data: Dictionary, animation_data: Dictionary) -> void:
	print("📝 ALMACENANDO METADATOS EN MODELO COMBINADO")
	
	# Metadatos del modelo base
	var base_metadata = {
		"filename": base_data.get("original_filename", "unknown_base"),
		"display_name": base_data.get("display_name", "Base Model"),
		"source_path": base_data.get("source_file_path", ""),
		"type": "base"
	}
	combined_root.set_meta("base_metadata", base_metadata)
	
	# Metadatos de la animación principal (la que se usó para combinar)
	var main_animation_metadata = {
		"filename": animation_data.get("original_filename", "unknown_animation"),
		"display_name": animation_data.get("display_name", animation_data.get("name", "Animation")),
		"source_path": animation_data.get("source_file_path", ""),
		"type": "animation",
		"animation_name": animation_data.get("name", "")
	}
	combined_root.set_meta("main_animation_metadata", main_animation_metadata)
	
	# ✅ CRÍTICO: Metadatos de TODAS las animaciones disponibles
	var all_animations_metadata = animations_metadata_cache.duplicate()
	
	# Agregar la animación actual si no está en cache
	var current_anim_name = animation_data.get("name", "")
	if current_anim_name != "" and not all_animations_metadata.has(current_anim_name):
		all_animations_metadata[current_anim_name] = animation_data.get("file_metadata", {
			"filename": animation_data.get("original_filename", "unknown"),
			"display_name": animation_data.get("display_name", current_anim_name),
			"source_path": animation_data.get("source_file_path", ""),
			"basename": current_anim_name
		})
	
	combined_root.set_meta("all_animations_metadata", all_animations_metadata)
	
	# Metadatos adicionales para debugging
	combined_root.set_meta("creation_timestamp", Time.get_unix_time_from_system())
	combined_root.set_meta("combination_info", {
		"base_bones": base_data.get("bone_count", 0),
		"animation_bones": animation_data.get("bone_count", 0),
		"meshes_count": base_data.get("meshes", []).size(),
		"animations_count": 1  # Será actualizado si se agregan más animaciones
	})
	
	print("✅ Metadatos almacenados:")
	print("  - Base: %s" % base_metadata.filename)
	print("  - Animación principal: %s" % main_animation_metadata.filename)
	print("  - Total animaciones en cache: %d" % all_animations_metadata.size())
	for anim_name in all_animations_metadata.keys():
		var anim_meta = all_animations_metadata[anim_name]
		#print("    • %s -> %s" % [anim_name, anim_meta.get("display_name", "Sin nombre")])



func combine_base_with_multiple_animations(base_data: Dictionary, animations_data: Dictionary) -> Node3D:
	"""Función mejorada para combinar base con múltiples animaciones preservando metadatos"""
	print("\n=== COMBINACIÓN CON MÚLTIPLES ANIMACIONES ===")
	print("Base: %s" % base_data.get("display_name", base_data.get("name", "Unknown")))
	print("Animaciones a combinar: %d" % animations_data.size())

	# Registrar metadatos de todas las animaciones
	register_multiple_animations_metadata(animations_data)

	# Usar la primera animación como base para la combinación
	var first_anim_name = animations_data.keys()[-1]
	var first_anim_data = animations_data[first_anim_name]

	# Realizar combinación base
	var combined_model = combine_base_with_animation(base_data, first_anim_data)
	if not combined_model:
		return null

	# Agregar las demás animaciones al AnimationPlayer
	var anim_player = combined_model.get_node_or_null("AnimationPlayer")
	if anim_player:
		var added_animations = 0
		var anim_lib = anim_player.get_animation_library("")

		for anim_name in animations_data.keys():
			if anim_name == first_anim_name:
				continue  # Ya está incluida

			var anim_data = animations_data[anim_name]
			if anim_data.has("animation_player") and anim_data.animation_player:
				# Copiar animaciones adicionales
				for extra_anim_name in anim_data.animation_player.get_animation_list():
					var extra_animation = anim_data.animation_player.get_animation(extra_anim_name)
					if extra_animation:
						var new_anim = extra_animation.duplicate(true)
						anim_lib.add_animation(anim_name, new_anim)  # Usar el nombre del archivo, no el nombre técnico
						added_animations += 1
						print("  ✅ Agregada animación: %s" % anim_name)
						print("added_animations: "+ added_animations)

		print("✅ Total animaciones en modelo combinado: %d" % (anim_player.get_animation_list().size()))

		# ✅ FORZAR POSE INICIAL DE LA ÚLTIMA ANIMACIÓN
		var anims = anim_player.get_animation_list()
		if anims.size() > 0:
			var last_anim = anims[anims.size() - 1]
			print("✅ Reproduciendo animación final agregada: %s" % last_anim)
			anim_player.play(last_anim)

		# Actualizar metadatos con información de animaciones múltiples
		var combination_info = combined_model.get_meta("combination_info", {})
		combination_info["animations_count"] = anim_player.get_animation_list().size()
		combined_model.set_meta("combination_info", combination_info)

	# ✅ Forzar la reproducción de la última animación agregada
	if anim_player:
		var anim_list = anim_player.get_animation_list()
		if anim_list.size() > 0:
			var last_anim = anim_list[anim_list.size() - 1]
			if anim_player.has_animation(last_anim):
				print("🎯 Reproduciendo directamente última animación agregada: %s" % last_anim)
				anim_player.play(last_anim)
			else:
				print("❌ La animación '%s' no está disponible para reproducción" % last_anim)




	return combined_model


# ✅ NUEVA FUNCIÓN: Extraer metadatos de modelo combinado
func extract_metadata_from_combined_model(combined_model: Node3D) -> Dictionary:
	"""Extraer todos los metadatos almacenados en un modelo combinado"""
	if not combined_model:
		return {}
	
	return {
		"base_metadata": combined_model.get_meta("base_metadata", {}),
		"main_animation_metadata": combined_model.get_meta("main_animation_metadata", {}),
		"all_animations_metadata": combined_model.get_meta("all_animations_metadata", {}),
		"combination_info": combined_model.get_meta("combination_info", {}),
		"creation_timestamp": combined_model.get_meta("creation_timestamp", 0)
	}

# FUNCIÓN EXISTENTE MEJORADA: Nuevo sistema de retargeting
func _retarget_animations_fixed(anim_player: AnimationPlayer, old_skeleton: Skeleton3D, new_skeleton: Skeleton3D) -> bool:
	print("🔧 INICIANDO RETARGETING CORREGIDO")
	
	# Debug de rutas antes del retargeting
	retargeting_fix.debug_animation_paths(anim_player)
	
	# Aplicar el fix de retargeting
	var success = retargeting_fix.fix_animation_retargeting(
		anim_player, 
		old_skeleton.name, 
		new_skeleton.name
	)
	
	if not success:
		print("❌ Falló el retargeting de animaciones")
		return false
	
	# Validar que las rutas sean correctas después del retargeting
	var validation = retargeting_fix.validate_animation_paths(anim_player, new_skeleton)
	
	print("📊 RESULTADO DE VALIDACIÓN:")
	print("  Tracks válidos: %d" % validation.valid_tracks)
	print("  Tracks inválidos: %d" % validation.invalid_tracks)
	
	# Considerar exitoso si al menos 80% de los tracks son válidos
	var total_tracks = validation.valid_tracks + validation.invalid_tracks
	var success_rate = float(validation.valid_tracks) / float(total_tracks) if total_tracks > 0 else 0.0
	
	if success_rate >= 0.8:
		print("✅ Retargeting exitoso (%.1f%% tracks válidos)" % (success_rate * 100))
		return true
	else:
		print("❌ Retargeting falló (solo %.1f%% tracks válidos)" % (success_rate * 100))
		return false

# FUNCIÓN EXISTENTE MEJORADA: Duplicar skeleton con nombres consistentes
func _duplicate_skeleton(original_skeleton: Skeleton3D) -> Skeleton3D:
	print("--- DUPLICANDO SKELETON ---")
	
	if not original_skeleton:
		print("❌ Skeleton original inválido")
		return null
	
	var new_skeleton = Skeleton3D.new()
	
	# Copiar cada hueso del skeleton original
	for i in range(original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(i)
		var bone_parent = original_skeleton.get_bone_parent(i)
		var bone_rest = original_skeleton.get_bone_rest(i)
		var bone_pose = original_skeleton.get_bone_pose(i)
		
		# Agregar hueso al nuevo skeleton
		new_skeleton.add_bone(bone_name)
		new_skeleton.set_bone_parent(i, bone_parent)
		new_skeleton.set_bone_rest(i, bone_rest)
		new_skeleton.set_bone_pose_position(i, bone_pose.origin)
		new_skeleton.set_bone_pose_rotation(i, bone_pose.basis.get_rotation_quaternion())
		new_skeleton.set_bone_pose_scale(i, bone_pose.basis.get_scale())
		
		# Verificar huesos críticos para debug
		if bone_name.contains("Hips") or bone_name.contains("Spine") or bone_name.contains("Head"):
			print("  ✅ Hueso crítico preservado: %s" % bone_name)
		
		#print("  Hueso copiado: %s (índice %d)" % [bone_name, i])
	
	print("Skeleton duplicado: %d huesos reales" % new_skeleton.get_bone_count())
	return new_skeleton



func _attach_meshes_to_skeleton(mesh_data_array: Array, skeleton: Skeleton3D) -> void:
	print("--- ANEXANDO MESHES ---")
	
	for mesh_data in mesh_data_array:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.name = mesh_data.name
		mesh_instance.mesh = mesh_data.mesh_resource
		
		# Aplicar materiales
		for i in range(mesh_data.materials.size()):
			if i < mesh_instance.mesh.get_surface_count():
				var material = mesh_data.materials[i]
				if material:
					mesh_instance.set_surface_override_material(i, material)
					print("    Material aplicado en superficie %d: %s" % [
						i, 
						material.resource_name if material.resource_name else "Material sin nombre"
					])
		
		# Configurar skeleton path
		mesh_instance.skeleton = NodePath("..")
		
		# MEJORA: Retargetear skin correctamente
		if mesh_data.has("original_skin") and mesh_data.original_skin:
			print("    DEBUG: Retargeteando skin...")
			var new_skin = _retarget_skin_to_skeleton(mesh_data.original_skin, skeleton)
			if new_skin:
				mesh_instance.skin = new_skin
				print("    ✅ Skin retargeteado exitosamente")
			else:
				print("    ❌ Falló retargeting de skin, usando original")
				mesh_instance.skin = mesh_data.original_skin
		else:
			print("    ⚠️ No hay skin original para retargetear")
		
		# Agregar al skeleton
		skeleton.add_child(mesh_instance)
		
		print("  Mesh anexado: %s" % mesh_instance.name)
		print("    Mesh resource: %s" % (mesh_instance.mesh.get_class() if mesh_instance.mesh else "NULL"))
		print("    Surfaces: %d" % (mesh_instance.mesh.get_surface_count() if mesh_instance.mesh else 0))
		print("    Skeleton path: %s" % str(mesh_instance.skeleton))
		print("    Skin asignado: %s" % (mesh_instance.skin != null))

# FUNCIÓN EXISTENTE: Retargetear skin (sin cambios)
func _retarget_skin_to_skeleton(original_skin: Skin, target_skeleton: Skeleton3D) -> Skin:
	if not original_skin or not target_skeleton:
		printerr("❌ Error: Parámetros inválidos para retargeting de skin")
		return null
	
	print("      Skin original bind count: %d" % original_skin.get_bind_count())
	print("      Target skeleton bone count: %d" % target_skeleton.get_bone_count())
	
	var new_skin = Skin.new()
	var successful_binds = 0
	
	# Procesar cada bind del skin original
	for i in range(original_skin.get_bind_count()):
		var bind_name = original_skin.get_bind_name(i)
		var bind_pose = original_skin.get_bind_pose(i)
		
		# Buscar el hueso correspondiente en el skeleton de destino
		var bone_index = target_skeleton.find_bone(bind_name)
		
		if bone_index >= 0:
			new_skin.add_bind(bone_index, bind_pose)
			new_skin.set_bind_name(new_skin.get_bind_count() - 1, bind_name)
			successful_binds += 1
			#print("        ✅ Bind mapeado: %s -> índice %d" % [bind_name, bone_index])
		else:
			print("        ❌ Hueso no encontrado: %s" % bind_name)
	
	print("      Resultado: %d/%d binds exitosos" % [successful_binds, original_skin.get_bind_count()])
	
	# Devolver skin solo si tenemos suficientes binds exitosos
	if successful_binds > 0 and (float(successful_binds) / float(original_skin.get_bind_count())) > 0.5:
		return new_skin
	else:
		print("      ❌ Muy pocos binds exitosos para un skin funcional")
		return null

func _extract_meshes_from_skeleton(skeleton: Skeleton3D) -> Array:
	var meshes = []
	
	print("--- EXTRAYENDO MESHES CON SKIN AUTO-GENERATION ---")
	
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			var mesh_data = {
				"node": child,
				"mesh_resource": child.mesh,
				"name": child.name,
				"materials": [],
				"skeleton_path": child.get_path_to(skeleton),
				"original_skin": child.skin
			}
			
			# Extraer materiales
			if child.mesh and child.mesh.get_surface_count() > 0:
				for i in range(child.mesh.get_surface_count()):
					var material = null
					
					if child.get_surface_override_material(i):
						material = child.get_surface_override_material(i)
					elif child.mesh.surface_get_material(i):
						material = child.mesh.surface_get_material(i)
					
					mesh_data.materials.append(material)
			
			print("  Mesh: %s - Skin existente detectado" % child.name if child.skin else "  Mesh: %s - Sin skin" % child.name)
			meshes.append(mesh_data)
	
	print("Total meshes extraídos: %d" % meshes.size())
	return meshes

# NUEVA FUNCIÓN: Debug del modelo combinado CON METADATOS
func debug_combined_model_with_metadata(combined_model: Node3D):
	print("\n🔍 DEBUG MODELO COMBINADO CON METADATOS")
	print("Nombre: %s" % combined_model.name)
	
	# Extraer y mostrar metadatos
	var metadata = extract_metadata_from_combined_model(combined_model)
	
	print("📝 METADATOS ALMACENADOS:")
	if metadata.has("base_metadata"):
		var base_meta = metadata.base_metadata
		print("  Base: %s (%s)" % [base_meta.get("display_name", "Sin nombre"), base_meta.get("filename", "Sin archivo")])
	
	if metadata.has("all_animations_metadata"):
		var anims_meta = metadata.all_animations_metadata
		print("  Animaciones disponibles: %d" % anims_meta.size())
		for anim_name in anims_meta.keys():
			var anim_meta = anims_meta[anim_name]
			print("    • %s -> %s (%s)" % [anim_name, anim_meta.get("display_name", "Sin nombre"), anim_meta.get("filename", "Sin archivo")])
	
	# Buscar skeleton
	var skeleton = combined_model.get_node_or_null("Skeleton3D_combined")
	if skeleton:
		print("✅ Skeleton encontrado: %d huesos" % skeleton.get_bone_count())
		
		# Contar meshes
		var mesh_count = 0
		for child in skeleton.get_children():
			if child is MeshInstance3D:
				mesh_count += 1
		
		print("✅ Meshes: %d" % mesh_count)
	else:
		print("❌ No se encontró skeleton")
	
	# Buscar AnimationPlayer
	var anim_player = combined_model.get_node_or_null("AnimationPlayer")
	if anim_player:
		print("✅ AnimationPlayer: %d animaciones" % anim_player.get_animation_list().size())
		
		# Validar rutas de animación
		if skeleton:
			var validation = retargeting_fix.validate_animation_paths(anim_player, skeleton)
			print("📊 Validación de animaciones:")
			print("  Tracks válidos: %d" % validation.valid_tracks)
			print("  Tracks inválidos: %d" % validation.invalid_tracks)
	else:
		print("❌ No se encontró AnimationPlayer")
	
	print("🔍 FIN DEBUG CON METADATOS\n")

# FUNCIONES EXISTENTES SIN CAMBIOS (preparar modelo, etc.)
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

func prepare_model_for_rendering(model: Node3D, frame: int, total_frames: int, animation_name: String) -> void:
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		return
	
	if anim_player.has_animation(animation_name):
		var anim = anim_player.get_animation(animation_name)
		var time_position = (float(frame) / float(total_frames)) * anim.length
		
		anim_player.play(animation_name)
		anim_player.seek(time_position, true)
		anim_player.advance(0.0)  # Forzar actualización


func add_animation_to_base_model(animation_player: AnimationPlayer, animation: Animation, anim_id: String) -> void:
	"""Agrega una animación al AnimationPlayer especificado"""
	if not animation_player:
		printerr("⚠️ No hay AnimationPlayer válido (nulo)")
		return

	if animation_player.has_animation(anim_id):
		print("ℹ️ Animación '%s' ya existe, sobrescribiendo..." % anim_id)

	animation_player.add_animation(anim_id, animation)
	print("✅ Animación '%s' agregada al modelo base" % anim_id)

func _setup_animation_player(original_player: AnimationPlayer, _original_skeleton: Skeleton3D, _new_skeleton: Skeleton3D) -> AnimationPlayer:
	print("--- CONFIGURANDO ANIMATION PLAYER (NUEVO) ---")
	if not original_player:
		print("❌ No hay AnimationPlayer original")
		return null
	
	var target_player: AnimationPlayer
	var anim_library: AnimationLibrary
	
	# PASO 1: Determinar si usar AnimationPlayer existente o crear nuevo
	if current_building_animation_player == null:
		print("🆕 Primera animación - creando AnimationPlayer nuevo")
		target_player = AnimationPlayer.new()
		target_player.name = "AnimationPlayer"
		
		# Crear biblioteca de animaciones vacía
		anim_library = AnimationLibrary.new()
		target_player.add_animation_library("", anim_library)
		
		# Configurar root_node relativo al modelo combinado
		target_player.root_node = NodePath("..")
		
		# Almacenar referencia para futuras llamadas
		current_building_animation_player = target_player
		print("✅ AnimationPlayer creado y almacenado")
	else:
		print("♻️  Reutilizando AnimationPlayer existente")
		target_player = current_building_animation_player
		anim_library = target_player.get_animation_library("")
		
		# COMPATIBILIDAD: Si el AnimationPlayer ya tiene padre, removerlo para poder agregarlo al nuevo modelo
		if target_player.get_parent():
			print("🔄 Removiendo AnimationPlayer del padre anterior para reutilizar")
			target_player.get_parent().remove_child(target_player)
	
	# PASO 2: Agregar todas las animaciones del original_player al target_player
	var added_count = 0
	for anim_name in original_player.get_animation_list():
		var original_anim = original_player.get_animation(anim_name)
		if original_anim:
			# Verificar si la animación ya existe
			if anim_library.has_animation(anim_name):
				print("  ⚠️  Animación '%s' ya existe, sobrescribiendo..." % anim_name)
			
			# Duplicar y agregar la animación
			var new_anim = original_anim.duplicate(true)
			anim_library.add_animation(anim_name, new_anim)
			added_count += 1
			print("  ✅ Animación agregada: %s (%.2fs)" % [anim_name, new_anim.length])
	
	print("📊 Resumen: %d animaciones agregadas, total actual: %d" % [added_count, target_player.get_animation_list().size()])
	print("📤 Retornando AnimationPlayer (padre removido si era necesario)")
	
	return target_player



func _setup_animation_player_for_transition(original_player: AnimationPlayer, _original_skeleton: Skeleton3D, _new_skeleton: Skeleton3D) -> AnimationPlayer:
	print("--- CONFIGURANDO ANIMATION PLAYER (_setup_animation_player_for_transition) ---")
	if not original_player:
		print("❌ No hay AnimationPlayer original")
		return null
	
	var target_player: AnimationPlayer
	var anim_library: AnimationLibrary
	
	# PASO 1: Determinar si usar AnimationPlayer existente o crear nuevo
	
	print(" creando AnimationPlayer nuevo")
	target_player = AnimationPlayer.new()
	target_player.name = "AnimationPlayer"
	
	# Crear biblioteca de animaciones vacía
	anim_library = AnimationLibrary.new()
	target_player.add_animation_library("", anim_library)
	
	# Configurar root_node relativo al modelo combinado
	target_player.root_node = NodePath("..")
	
	# Almacenar referencia para futuras llamadas
	current_building_animation_player = target_player
	print("✅ AnimationPlayer creado y almacenado")
	
	# PASO 2: Agregar todas las animaciones del original_player al target_player
	var added_count = 0
	for anim_name in original_player.get_animation_list():
		var original_anim = original_player.get_animation(anim_name)
		if original_anim:
			# Verificar si la animación ya existe
			if anim_library.has_animation(anim_name):
				print("  ⚠️  Animación '%s' ya existe, sobrescribiendo..." % anim_name)
			
			# Duplicar y agregar la animación
			var new_anim = original_anim.duplicate(true)
			anim_library.add_animation(anim_name, new_anim)
			added_count += 1
			print("  ✅ Animación agregada: %s (%.2fs)" % [anim_name, new_anim.length])
	
	print("📊 Resumen: %d animaciones agregadas, total actual: %d" % [added_count, target_player.get_animation_list().size()])

	return target_player



# FUNCIÓN NUEVA: Limpiar el AnimationPlayer en construcción (LLAMAR CUANDO USUARIO REINICIE)
func _reset_building_animation_player() -> void:
	"""Limpiar la referencia al AnimationPlayer en construcción"""
	print("🧹 Limpiando referencia de AnimationPlayer en construcción")
	current_building_animation_player = null

# FUNCIÓN PÚBLICA: Reset manual del sistema de animaciones (para uso desde coordinator)
func reset_animation_system() -> void:
	"""Reset completo del sistema cuando el usuario decide reiniciar"""
	print("🔄 RESET MANUAL DEL SISTEMA DE ANIMACIONES")
	_reset_building_animation_player()
	# Limpiar también otros cachés si es necesario
	base_meshes_cache.clear()
	animations_metadata_cache.clear()
	print("✅ Sistema de animaciones reseteado completamente")

# FUNCIÓN NUEVA: Obtener el AnimationPlayer en construcción (para debugging)
func get_current_building_animation_player() -> AnimationPlayer:
	"""Obtener el AnimationPlayer que se está construyendo actualmente"""
	return current_building_animation_player
