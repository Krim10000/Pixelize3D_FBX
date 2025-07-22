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
	# Crear un nuevo nodo raíz para el modelo combinado
	var combined_root = Node3D.new()
	combined_root.name = "Combined_" + animation_data.name
	
	# Duplicar el skeleton del modelo base
	var new_skeleton = _duplicate_skeleton(base_data.skeleton)
	if not new_skeleton:
		emit_signal("combination_failed", "Error al duplicar skeleton")
		combined_root.queue_free()
		return null
	
	combined_root.add_child(new_skeleton)
	
	# Añadir los meshes del modelo base al nuevo skeleton
	_attach_meshes_to_skeleton(base_data.meshes, new_skeleton)
	
	# Copiar el AnimationPlayer de la animación
	var new_anim_player = _setup_animation_player(animation_data.animation_player, animation_data.skeleton, new_skeleton)
	if not new_anim_player:
		emit_signal("combination_failed", "Error al configurar AnimationPlayer")
		combined_root.queue_free()
		return null
	
	combined_root.add_child(new_anim_player)
	
	# Configurar las animaciones para que apunten al nuevo skeleton
	_retarget_animations(new_anim_player, animation_data.skeleton, new_skeleton)
	
	# Aplicar la pose inicial
	if new_anim_player.has_animation("default") or animation_data.animations.size() > 0:
		var first_anim = animation_data.animations[0].name if animation_data.animations.size() > 0 else "default"
		new_anim_player.play(first_anim)
		new_anim_player.seek(0, true)
		new_anim_player.stop()
	
	emit_signal("combination_complete", combined_root)
	return combined_root

func _duplicate_skeleton(original_skeleton: Skeleton3D) -> Skeleton3D:
	var new_skeleton = Skeleton3D.new()
	new_skeleton.name = original_skeleton.name + "_combined"
	
	# Copiar la estructura de huesos
	for i in range(original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(i)
		var bone_parent = original_skeleton.get_bone_parent(i)
		var bone_rest = original_skeleton.get_bone_rest(i)
		
		new_skeleton.add_bone(bone_name)
		
		if bone_parent >= 0:
			new_skeleton.set_bone_parent(i, bone_parent)
		
		new_skeleton.set_bone_rest(i, bone_rest)
		
		# Copiar la pose actual
		var bone_pose = original_skeleton.get_bone_pose(i)
		new_skeleton.set_bone_pose_position(i, bone_pose.origin)
		new_skeleton.set_bone_pose_rotation(i, bone_pose.basis.get_rotation_quaternion())
		new_skeleton.set_bone_pose_scale(i, bone_pose.basis.get_scale())
	
	return new_skeleton

func _attach_meshes_to_skeleton(meshes: Array, skeleton: Skeleton3D) -> void:
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
		
		# Si el mesh original tenía información de skin, copiarla
		if mesh_data.node and mesh_data.node.skin:
			new_mesh_instance.skin = mesh_data.node.skin

func _setup_animation_player(original_player: AnimationPlayer, original_skeleton: Skeleton3D, new_skeleton: Skeleton3D) -> AnimationPlayer:
	if not original_player:
		return null
	
	var new_player = AnimationPlayer.new()
	new_player.name = "AnimationPlayer"
	
	# Copiar todas las animaciones
	for anim_name in original_player.get_animation_list():
		var original_anim = original_player.get_animation(anim_name)
		if original_anim:
			var new_anim = original_anim.duplicate(true)
			new_player.add_animation_library("", AnimationLibrary.new())
			new_player.get_animation_library("").add_animation(anim_name, new_anim)
	
	# Configurar el root node
	new_player.root_node = NodePath("..")
	
	return new_player

func _retarget_animations(anim_player: AnimationPlayer, old_skeleton: Skeleton3D, new_skeleton: Skeleton3D) -> void:
	# Obtener las rutas de los nodos
	var old_skeleton_path = old_skeleton.get_path()
	var new_skeleton_path = anim_player.get_node("..").get_path_to(new_skeleton)
	
	# Para cada animación, actualizar las rutas de los tracks
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation_library("").get_animation(anim_name)
		if not anim:
			continue
		
		for track_idx in range(anim.get_track_count()):
			var track_path = anim.track_get_path(track_idx)
			var path_string = String(track_path)
			
			# Si el track apunta al skeleton antiguo, actualizarlo
			if path_string.begins_with(String(old_skeleton_path)):
				# Reemplazar la ruta del skeleton antiguo con la del nuevo
				var relative_path = path_string.substr(String(old_skeleton_path).length())
				var new_path = String(new_skeleton_path) + relative_path
				anim.track_set_path(track_idx, NodePath(new_path))

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
