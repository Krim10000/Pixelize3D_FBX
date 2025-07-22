# scripts/core/fbx_loader.gd
extends Node

# Input: Rutas de archivos FBX
# Output: Datos del modelo cargado (escena, skeleton, meshes, animations)

signal model_loaded(model_data: Dictionary)
signal load_failed(error: String)
signal load_progress(progress: float)

# Cache para optimizar carga
var loaded_models_cache = {}

func load_base_model(fbx_path: String) -> void:
	if fbx_path in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[fbx_path])
		return
	
	_load_fbx_file(fbx_path, "base")

func load_animation_fbx(fbx_path: String, animation_name: String) -> void:
	var cache_key = fbx_path + "_anim"
	if cache_key in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	_load_fbx_file(fbx_path, "animation", animation_name)

func _load_fbx_file(path: String, type: String, anim_name: String = "") -> void:
	# Verificar que el archivo existe
	if not FileAccess.file_exists(path):
		emit_signal("load_failed", "Archivo no encontrado: " + path)
		return
	
	# Cargar el archivo FBX
	var scene = load(path)
	if not scene:
		emit_signal("load_failed", "No se pudo cargar el archivo FBX: " + path)
		return
	
	# Instanciar la escena
	var instance = scene.instantiate()
	if not instance:
		emit_signal("load_failed", "No se pudo instanciar la escena FBX")
		return
	
	# Analizar estructura del FBX
	var model_data = _analyze_fbx_structure(instance, type, anim_name)
	
	if model_data.is_empty():
		instance.queue_free()
		emit_signal("load_failed", "Estructura FBX no válida")
		return
	
	# Guardar en cache
	var cache_key = path
	if type == "animation":
		cache_key += "_anim"
	loaded_models_cache[cache_key] = model_data
	
	emit_signal("model_loaded", model_data)

func _analyze_fbx_structure(root: Node3D, type: String, anim_name: String = "") -> Dictionary:
	var data = {
		"type": type,
		"name": anim_name if anim_name != "" else root.name,
		"node": root,
		"skeleton": null,
		"meshes": [],
		"animation_player": null,
		"animations": []
	}
	
	# Buscar Node3D raíz
	if not root is Node3D:
		push_error("El nodo raíz no es Node3D")
		return {}
	
	# Buscar Skeleton3D
	data.skeleton = _find_node_of_type(root, "Skeleton3D")
	if not data.skeleton:
		push_error("No se encontró Skeleton3D en el FBX")
		return {}
	
	# Buscar AnimationPlayer
	data.animation_player = _find_node_of_type(root, "AnimationPlayer")
	
	# Para modelo base: buscar MeshInstance3D dentro del Skeleton3D
	if type == "base":
		data.meshes = _extract_meshes_from_skeleton(data.skeleton)
		if data.meshes.is_empty():
			push_error("No se encontraron meshes en el modelo base")
			return {}
	
	# Para animaciones: extraer lista de animaciones
	if type == "animation" and data.animation_player:
		data.animations = _extract_animation_list(data.animation_player)
		if data.animations.is_empty():
			push_error("No se encontraron animaciones en el archivo")
			return {}
	
	# Extraer información adicional
	data["bounds"] = _calculate_model_bounds(data)
	data["bone_count"] = data.skeleton.get_bone_count() if data.skeleton else 0
	
	return data

func _find_node_of_type(node: Node, type_name: String) -> Node:
	# Buscar recursivamente un nodo del tipo especificado
	if node.get_class() == type_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_of_type(child, type_name)
		if result:
			return result
	
	return null

func _extract_meshes_from_skeleton(skeleton: Skeleton3D) -> Array:
	var meshes = []
	
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			var mesh_data = {
				"node": child,
				"mesh_resource": child.mesh,
				"name": child.name,
				"materials": [],
				"skeleton_path": child.get_path_to(skeleton)
			}
			
			# Extraer materiales
			for i in range(child.get_surface_override_material_count()):
				var material = child.get_surface_override_material(i)
				if material:
					mesh_data.materials.append(material)
			
			meshes.append(mesh_data)
	
	return meshes

func _extract_animation_list(anim_player: AnimationPlayer) -> Array:
	var animations = []
	
	for anim_name in anim_player.get_animation_list():
		var anim = anim_player.get_animation(anim_name)
		if anim:
			animations.append({
				"name": anim_name,
				"length": anim.length,
				"fps": anim.step,
				"loop": anim.loop_mode != Animation.LOOP_NONE,
				"resource": anim
			})
	
	return animations

func _calculate_model_bounds(model_data: Dictionary) -> AABB:
	var combined_aabb = AABB()
	var first = true
	
	# Calcular bounds combinados de todos los meshes
	for mesh_data in model_data.meshes:
		if mesh_data.mesh_resource and mesh_data.mesh_resource is Mesh:
			var mesh_aabb = mesh_data.mesh_resource.get_aabb()
			
			if first:
				combined_aabb = mesh_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(mesh_aabb)
	
	return combined_aabb

# Función auxiliar para limpiar recursos
func clear_cache() -> void:
	for key in loaded_models_cache:
		var model_data = loaded_models_cache[key]
		if model_data.node:
			model_data.node.queue_free()
	
	loaded_models_cache.clear()

# Validar si un archivo es FBX válido
func validate_fbx_file(path: String) -> bool:
	if not path.ends_with(".fbx") and not path.ends_with(".FBX"):
		return false
	
	return FileAccess.file_exists(path)
