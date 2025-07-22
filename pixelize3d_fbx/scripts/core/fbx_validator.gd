# scripts/core/fbx_validator.gd
extends Node

# Input: Archivo FBX para validar
# Output: Reporte de validación con errores y advertencias

signal validation_complete(report: Dictionary)
signal validation_progress(current: int, total: int)

enum ValidationLevel {
	ERROR,
	WARNING,
	INFO,
	SUCCESS
}

class ValidationResult:
	var level: ValidationLevel
	var message: String
	var details: String = ""
	var node_path: String = ""
	
	func _init(p_level: ValidationLevel, p_message: String, p_details: String = "", p_path: String = ""):
		level = p_level
		message = p_message
		details = p_details
		node_path = p_path

func validate_fbx_file(file_path: String, is_base_model: bool = true) -> Dictionary:
	var report = {
		"file_path": file_path,
		"file_name": file_path.get_file(),
		"is_valid": true,
		"is_base_model": is_base_model,
		"errors": [],
		"warnings": [],
		"info": [],
		"structure": {},
		"statistics": {}
	}
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists(file_path):
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Archivo no encontrado",
			"La ruta especificada no existe: " + file_path
		))
		report.is_valid = false
		emit_signal("validation_complete", report)
		return report
	
	# Cargar el archivo
	var scene = load(file_path)
	if not scene:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"No se pudo cargar el archivo",
			"El archivo no es un FBX válido o está corrupto"
		))
		report.is_valid = false
		emit_signal("validation_complete", report)
		return report
	
	# Instanciar la escena
	var instance = scene.instantiate()
	if not instance:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"No se pudo instanciar la escena",
			"Error al crear instancia del archivo FBX"
		))
		report.is_valid = false
		emit_signal("validation_complete", report)
		return report
	
	# Validar estructura
	_validate_structure(instance, report, is_base_model)
	
	# Generar estadísticas
	_generate_statistics(instance, report)
	
	# Limpiar
	instance.queue_free()
	
	# Determinar si es válido basado en errores
	report.is_valid = report.errors.is_empty()
	
	emit_signal("validation_complete", report)
	return report

func _validate_structure(root: Node, report: Dictionary, is_base_model: bool) -> void:
	# Validar nodo raíz
	if not root is Node3D:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Nodo raíz inválido",
			"El nodo raíz debe ser Node3D, encontrado: " + root.get_class()
		))
		return
	
	report.structure["root_node"] = root.name
	
	# Buscar Skeleton3D
	var skeleton = _find_skeleton(root)
	if not skeleton:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Skeleton3D no encontrado",
			"El archivo debe contener un nodo Skeleton3D"
		))
		return
	
	report.structure["skeleton_found"] = true
	report.structure["skeleton_path"] = root.get_path_to(skeleton)
	
	# Validar huesos
	var bone_count = skeleton.get_bone_count()
	report.structure["bone_count"] = bone_count
	
	if bone_count == 0:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Sin huesos en el skeleton",
			"El Skeleton3D no contiene huesos"
		))
	else:
		report.info.append(ValidationResult.new(
			ValidationLevel.INFO,
			"Huesos encontrados: " + str(bone_count),
			"",
			skeleton.get_path()
		))
		
		# Validar jerarquía de huesos
		_validate_bone_hierarchy(skeleton, report)
	
	# Validar meshes (solo para modelo base)
	if is_base_model:
		var meshes = _find_meshes_in_skeleton(skeleton)
		report.structure["mesh_count"] = meshes.size()
		
		if meshes.is_empty():
			report.errors.append(ValidationResult.new(
				ValidationLevel.ERROR,
				"Sin meshes en el modelo base",
				"El modelo base debe contener al menos un MeshInstance3D dentro del Skeleton3D"
			))
		else:
			for mesh in meshes:
				_validate_mesh(mesh, report)
	else:
		# Para archivos de animación, verificar que NO hay meshes
		var meshes = _find_meshes_in_skeleton(skeleton)
		if not meshes.is_empty():
			report.warnings.append(ValidationResult.new(
				ValidationLevel.WARNING,
				"Meshes encontrados en archivo de animación",
				"Los archivos de animación no deberían contener meshes (%d encontrados)" % meshes.size()
			))
	
	# Validar AnimationPlayer
	var anim_player = _find_animation_player(root)
	report.structure["animation_player_found"] = anim_player != null
	
	if is_base_model:
		# Para modelo base, AnimationPlayer es opcional
		if anim_player:
			report.info.append(ValidationResult.new(
				ValidationLevel.INFO,
				"AnimationPlayer encontrado",
				"No es necesario para modelo base pero no causa problemas"
			))
	else:
		# Para archivos de animación, AnimationPlayer es obligatorio
		if not anim_player:
			report.errors.append(ValidationResult.new(
				ValidationLevel.ERROR,
				"AnimationPlayer no encontrado",
				"Los archivos de animación deben contener un AnimationPlayer"
			))
		else:
			_validate_animations(anim_player, skeleton, report)

func _validate_bone_hierarchy(skeleton: Skeleton3D, report: Dictionary) -> void:
	var root_bones = []
	var bone_names = {}
	
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		
		# Verificar nombres duplicados
		if bone_name in bone_names:
			report.errors.append(ValidationResult.new(
				ValidationLevel.ERROR,
				"Nombre de hueso duplicado",
				"El hueso '%s' está duplicado" % bone_name
			))
		bone_names[bone_name] = i
		
		# Encontrar huesos raíz
		if skeleton.get_bone_parent(i) == -1:
			root_bones.append(i)
	
	# Verificar que hay al menos un hueso raíz
	if root_bones.is_empty():
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Sin hueso raíz",
			"La jerarquía de huesos no tiene un hueso raíz válido"
		))
	elif root_bones.size() > 1:
		report.warnings.append(ValidationResult.new(
			ValidationLevel.WARNING,
			"Múltiples huesos raíz",
			"Se encontraron %d huesos raíz, se recomienda una única jerarquía" % root_bones.size()
		))
	
	report.structure["root_bones"] = root_bones.size()
	report.structure["bone_names"] = bone_names.keys()

func _validate_mesh(mesh: MeshInstance3D, report: Dictionary) -> void:
	if not mesh.mesh:
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"MeshInstance3D sin mesh",
			"El nodo '%s' no tiene un recurso mesh asignado" % mesh.name,
			mesh.get_path()
		))
		return
	
	# Validar propiedades del mesh
	var mesh_resource = mesh.mesh
	var surface_count = mesh_resource.get_surface_count()
	
	if surface_count == 0:
		report.warnings.append(ValidationResult.new(
			ValidationLevel.WARNING,
			"Mesh sin superficies",
			"El mesh '%s' no tiene superficies" % mesh.name
		))
	
	# Verificar materiales
	var has_materials = false
	for i in range(surface_count):
		if mesh.get_surface_override_material(i) != null:
			has_materials = true
			break
	
	if not has_materials:
		report.warnings.append(ValidationResult.new(
			ValidationLevel.WARNING,
			"Sin materiales",
			"El mesh '%s' no tiene materiales asignados" % mesh.name
		))
	
	# Verificar skeleton path
	if mesh.skeleton == NodePath():
		report.warnings.append(ValidationResult.new(
			ValidationLevel.WARNING,
			"Sin skeleton vinculado",
			"El mesh '%s' no está vinculado a un skeleton" % mesh.name
		))

func _validate_animations(anim_player: AnimationPlayer, skeleton: Skeleton3D, report: Dictionary) -> void:
	var animation_list = anim_player.get_animation_list()
	report.structure["animation_count"] = animation_list.size()
	
	if animation_list.is_empty():
		report.errors.append(ValidationResult.new(
			ValidationLevel.ERROR,
			"Sin animaciones",
			"El AnimationPlayer no contiene animaciones"
		))
		return
	
	report.structure["animations"] = []
	
	for anim_name in animation_list:
		var anim = anim_player.get_animation(anim_name)
		if not anim:
			continue
		
		var anim_info = {
			"name": anim_name,
			"length": anim.length,
			"tracks": anim.get_track_count(),
			"valid_tracks": 0,
			"invalid_tracks": 0
		}
		
		# Validar tracks
		for track_idx in range(anim.get_track_count()):
			var track_path = anim.track_get_path(track_idx)
			var track_type = anim.track_get_type(track_idx)
			
			# Verificar que el track apunta a un nodo válido
			if anim_player.has_node(track_path):
				anim_info.valid_tracks += 1
			else:
				anim_info.invalid_tracks += 1
				report.warnings.append(ValidationResult.new(
					ValidationLevel.WARNING,
					"Track con ruta inválida",
					"Animación '%s': track %d apunta a nodo inexistente: %s" % [anim_name, track_idx, track_path]
				))
		
		report.structure.animations.append(anim_info)
		
		# Verificar si la animación tiene datos
		if anim_info.valid_tracks == 0:
			report.errors.append(ValidationResult.new(
				ValidationLevel.ERROR,
				"Animación sin tracks válidos",
				"La animación '%s' no tiene tracks que apunten a nodos existentes" % anim_name
			))

func _generate_statistics(root: Node, report: Dictionary) -> void:
	var stats = {
		"total_nodes": 0,
		"node_types": {},
		"total_polygons": 0,
		"total_vertices": 0,
		"bounds": AABB(),
		"memory_estimate": 0
	}
	
	_count_nodes_recursive(root, stats)
	
	report.statistics = stats

func _count_nodes_recursive(node: Node, stats: Dictionary) -> void:
	stats.total_nodes += 1
	
	var node_type = node.get_class()
	if not node_type in stats.node_types:
		stats.node_types[node_type] = 0
	stats.node_types[node_type] += 1
	
	# Contar polígonos y vértices para MeshInstance3D
	if node is MeshInstance3D and node.mesh:
		var mesh = node.mesh
		for surface in range(mesh.get_surface_count()):
			var arrays = mesh.surface_get_arrays(surface)
			if arrays.size() > Mesh.ARRAY_VERTEX:
				var vertices = arrays[Mesh.ARRAY_VERTEX]
				if vertices:
					stats.total_vertices += vertices.size()
					# Estimar polígonos (aproximado)
					stats.total_polygons += vertices.size() / 3
		
		# Actualizar bounds
		if stats.bounds.size == Vector3.ZERO:
			stats.bounds = node.get_aabb()
		else:
			stats.bounds = stats.bounds.merge(node.get_aabb())
	
	# Recursión
	for child in node.get_children():
		_count_nodes_recursive(child, stats)

# Funciones auxiliares
func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _find_meshes_in_skeleton(skeleton: Skeleton3D) -> Array:
	var meshes = []
	
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
	
	return meshes

# Función para validar un conjunto de archivos
func validate_unit_folder(folder_path: String, base_file: String, animation_files: Array) -> Dictionary:
	var unit_report = {
		"folder": folder_path,
		"base_file": base_file,
		"animation_files": animation_files,
		"is_valid": true,
		"base_validation": {},
		"animation_validations": [],
		"compatibility_issues": []
	}
	
	emit_signal("validation_progress", 0, animation_files.size() + 1)
	
	# Validar archivo base
	var base_path = folder_path.path_join(base_file)
	unit_report.base_validation = validate_fbx_file(base_path, true)
	
	if not unit_report.base_validation.is_valid:
		unit_report.is_valid = false
	
	emit_signal("validation_progress", 1, animation_files.size() + 1)
	
	# Validar archivos de animación
	var base_bone_names = unit_report.base_validation.structure.get("bone_names", [])
	
	for i in range(animation_files.size()):
		var anim_file = animation_files[i]
		var anim_path = folder_path.path_join(anim_file)
		var anim_validation = validate_fbx_file(anim_path, false)
		
		unit_report.animation_validations.append(anim_validation)
		
		if not anim_validation.is_valid:
			unit_report.is_valid = false
		
		# Verificar compatibilidad con el modelo base
		if anim_validation.structure.has("bone_names"):
			var anim_bone_names = anim_validation.structure.bone_names
			_check_bone_compatibility(base_bone_names, anim_bone_names, anim_file, unit_report)
		
		emit_signal("validation_progress", i + 2, animation_files.size() + 1)
	
	return unit_report

func _check_bone_compatibility(base_bones: Array, anim_bones: Array, anim_file: String, report: Dictionary) -> void:
	# Verificar que los huesos de la animación coincidan con el modelo base
	for bone in anim_bones:
		if not bone in base_bones:
			report.compatibility_issues.append({
				"file": anim_file,
				"issue": "Hueso no encontrado en modelo base",
				"bone": bone
			})
	
	# Advertir si el modelo base tiene huesos que la animación no tiene
	for bone in base_bones:
		if not bone in anim_bones:
			report.compatibility_issues.append({
				"file": anim_file,
				"issue": "Hueso del modelo base no presente en animación",
				"bone": bone,
				"severity": "warning"
			})
