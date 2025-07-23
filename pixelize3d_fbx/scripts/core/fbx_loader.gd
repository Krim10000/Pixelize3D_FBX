# scripts/core/fbx_loader.gd
extends Node

# Input: Rutas de archivos FBX (pueden estar fuera del proyecto)
# Output: Datos del modelo cargado (escena, skeleton, meshes, animations)

signal model_loaded(model_data: Dictionary)
signal load_failed(error: String)
signal load_progress(progress: float)

# Cache para optimizar carga
var loaded_models_cache = {}

# Directorio temporal para importar FBX
const TEMP_IMPORT_DIR = "res://temp_fbx_import/"

func _ready():
	# Crear directorio temporal si no existe
	DirAccess.make_dir_recursive_absolute(TEMP_IMPORT_DIR)

func load_base_model(fbx_path: String) -> void:
	var cache_key = fbx_path + "_base"
	if cache_key in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	_load_fbx_file(fbx_path, "base")

func load_animation_fbx(fbx_path: String, animation_name: String) -> void:
	var cache_key = fbx_path + "_anim_" + animation_name
	if cache_key in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	_load_fbx_file(fbx_path, "animation", animation_name)

func _load_fbx_file(path: String, type: String, anim_name: String = "") -> void:
	emit_signal("load_progress", 0.1)
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists(path):
		emit_signal("load_failed", "Archivo no encontrado: " + path)
		return
	
	emit_signal("load_progress", 0.2)
	
	# Determinar si el archivo está dentro del proyecto
	var project_path = ProjectSettings.globalize_path("res://")
	var is_external = not path.begins_with("res://") and not path.begins_with(project_path)
	
	var import_path = path
	
	# Si es externo, copiarlo e intentar importación automática
	if is_external:
		print("Procesando archivo FBX externo: ", path.get_file())
		import_path = await _import_external_fbx(path)
		if import_path == "":
			emit_signal("load_failed", "No se pudo procesar el archivo FBX externo")
			return
	
	emit_signal("load_progress", 0.5)
	
	# Intentar cargar el archivo FBX con múltiples métodos
	var scene_resource = await _load_imported_scene(import_path)
	if not scene_resource:
		# Intentar crear archivo .import si no existe
		if not FileAccess.file_exists(import_path + ".import"):
			print("Creando archivo .import para: ", import_path.get_file())
			if _create_import_file(import_path):
				await get_tree().create_timer(2.0).timeout
				scene_resource = await _load_imported_scene(import_path)
		
		if not scene_resource:
			var error_msg = "No se pudo cargar el archivo FBX: " + path.get_file()
			error_msg += "\n\nPosibles soluciones:"
			error_msg += "\n• Verifica que el archivo FBX sea válido"
			error_msg += "\n• Intenta con un archivo FBX más simple"
			error_msg += "\n• Coloca el archivo en res://temp_fbx_import/ manualmente"
			
			emit_signal("load_failed", error_msg)
			return
	
	emit_signal("load_progress", 0.7)
	
	# Instanciar la escena
	var instance = scene_resource.instantiate()
	if not instance:
		emit_signal("load_failed", "No se pudo instanciar la escena FBX")
		return
	
	emit_signal("load_progress", 0.8)
	
	# Analizar estructura del FBX
	var model_data = _analyze_fbx_structure(instance, type, anim_name)
	
	if model_data.is_empty():
		instance.queue_free()
		emit_signal("load_failed", "Estructura FBX no válida - verifica que tenga Skeleton3D y MeshInstance3D")
		return
	
	emit_signal("load_progress", 1.0)
	
	# Guardar en cache
	var cache_key = path + "_" + type
	if type == "animation":
		cache_key += "_" + anim_name
	loaded_models_cache[cache_key] = model_data
	
	print("FBX cargado exitosamente: ", path.get_file(), " (tipo: ", type, ")")
	emit_signal("model_loaded", model_data)

func _import_external_fbx(external_path: String) -> String:
	# Generar nombre único para el archivo temporal
	var file_name = external_path.get_file()
	var safe_name = file_name.replace(" ", "_").replace("(", "").replace(")", "")
	var temp_path = TEMP_IMPORT_DIR + safe_name
	
	# Copiar archivo al proyecto
	var error = _copy_file_to_project(external_path, temp_path)
	if error != OK:
		print("Error copiando archivo: ", error)
		emit_signal("load_failed", "No se pudo copiar el archivo FBX al proyecto. Error: " + str(error))
		return ""
	
	print("Archivo FBX copiado a: ", temp_path)
	
	# Verificar si ya está importado
	if _can_load_fbx_resource(temp_path):
		print("FBX ya estaba importado y listo")
		return temp_path
	
	# Intentar conversión directa usando FBX2glTF approach
	var converted_path = await _try_direct_fbx_conversion(temp_path)
	if converted_path != "":
		return converted_path
	
	# Si falla la conversión, mostrar instrucciones alternativas
	var error_msg = "⚠️ Error de importación FBX (código 127)\n\n"
	error_msg += "El archivo '" + file_name + "' no se pudo convertir automáticamente.\n\n"
	error_msg += "SOLUCIONES ALTERNATIVAS:\n\n"
	error_msg += "1. RECOMENDADO: Convierte el FBX a GLTF/GLB usando Blender:\n"
	error_msg += "   • Abre el FBX en Blender\n"
	error_msg += "   • Exporta como GLTF 2.0 (.glb)\n"
	error_msg += "   • Coloca el .glb en res://temp_fbx_import/\n\n"
	error_msg += "2. Verifica que el FBX tenga:\n"
	error_msg += "   • Skeleton/Armature válido\n"
	error_msg += "   • Meshes correctamente vinculados\n"
	error_msg += "   • Formato FBX 2020 o anterior\n\n"
	error_msg += "3. Intenta con otro archivo FBX de prueba\n\n"
	error_msg += "El archivo se copió a: " + temp_path
	
	emit_signal("load_failed", error_msg)
	return ""

func _copy_file_to_project(from: String, to: String) -> Error:
	# Crear directorio si no existe
	var dir = DirAccess.open("res://")
	dir.make_dir_recursive(to.get_base_dir())
	
	# Copiar archivo
	var source_file = FileAccess.open(from, FileAccess.READ)
	if not source_file:
		return ERR_FILE_NOT_FOUND
	
	var dest_file = FileAccess.open(to, FileAccess.WRITE)
	if not dest_file:
		source_file.close()
		return ERR_CANT_CREATE
	
	dest_file.store_buffer(source_file.get_buffer(source_file.get_length()))
	source_file.close()
	dest_file.close()
	
	return OK

func _can_load_fbx_resource(fbx_path: String) -> bool:
	# Verificar si podemos cargar el recurso de alguna forma
	if ResourceLoader.exists(fbx_path):
		return true
	
	# Verificar si existe el archivo importado
	var imported_path = _find_imported_scene_path(fbx_path)
	if imported_path != "" and ResourceLoader.exists(imported_path):
		return true
	
	return false

func _wait_for_import(fbx_path: String):
	# Esperar hasta que Godot importe el archivo
	var max_wait_time = 8.0  # 8 segundos máximo
	var wait_time = 0.0
	var check_interval = 0.5
	
	print("Esperando importación de: ", fbx_path.get_file())
	
	while wait_time < max_wait_time:
		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval
		
		# Verificar si el archivo .import existe o si ya podemos cargar el archivo
		if FileAccess.file_exists(fbx_path + ".import"):
			print("Archivo .import detectado, esperando procesamiento...")
			await get_tree().create_timer(1.0).timeout
			
			if _can_load_fbx_resource(fbx_path):
				print("FBX importado exitosamente en ", wait_time + 1.0, " segundos")
				break
		
		# Actualizar progreso
		emit_signal("load_progress", 0.2 + (wait_time / max_wait_time) * 0.3)
		
		# Mostrar progreso al usuario
		if int(wait_time) % 2 == 0:
			print("Importando... (", int(wait_time), "/", int(max_wait_time), " segundos)")
	
	if wait_time >= max_wait_time:
		print("Tiempo de importación agotado, continuando con carga...")
	else:
		print("Importación completada")

func _load_imported_scene(fbx_path: String) -> PackedScene:
	# Primero intentar cargar directamente el FBX
	if ResourceLoader.exists(fbx_path):
		var scene = load(fbx_path)
		if scene and scene is PackedScene:
			return scene
	
	# Buscar el archivo .scn importado
	var imported_path = _find_imported_scene_path(fbx_path)
	if imported_path != "":
		if ResourceLoader.exists(imported_path):
			var scene = load(imported_path)
			if scene and scene is PackedScene:
				return scene
	
	# Intentar cargar usando ResourceLoader con timeout
	var attempts = 0
	var max_attempts = 3
	
	while attempts < max_attempts:
		# Esperar antes de cada intento
		if attempts > 0:
			await get_tree().create_timer(1.0).timeout
		
		# Verificar múltiples extensiones posibles
		var base_path = fbx_path.get_basename()
		var possible_paths = [
			fbx_path,
			base_path + ".scn",
			base_path + ".tscn",
			base_path + ".res"
		]
		
		for test_path in possible_paths:
			if ResourceLoader.exists(test_path):
				var scene = load(test_path)
				if scene and scene is PackedScene:
					return scene
		
		# Buscar nuevamente en imported
		imported_path = _find_imported_scene_path(fbx_path)
		if imported_path != "" and ResourceLoader.exists(imported_path):
			var scene = load(imported_path)
			if scene and scene is PackedScene:
				return scene
		
		attempts += 1
	
	# Intentar método básico como último recurso
	print("Intentando carga con métodos alternativos...")
	var fallback_scene = _load_fbx_as_basic_model(fbx_path)
	if fallback_scene:
		return fallback_scene
	
	# Como último recurso, mostrar información de debug
	print("Debug - Archivos encontrados para: ", fbx_path.get_file())
	_debug_list_files_in_imported_dir(fbx_path.get_file())
	
	return null

func _find_imported_scene_path(fbx_path: String) -> String:
	# Buscar en .godot/imported/
	var file_name = fbx_path.get_file()
	var uid = file_name.sha256_text()
	
	# Patrón común de Godot para archivos importados
	var import_dir = ".godot/imported/"
	var possible_paths = [
		"res://" + import_dir + file_name + "-" + uid.substr(0, 32) + ".scn",
		"res://" + import_dir + file_name.get_basename() + "-" + uid.substr(0, 32) + ".scn"
	]
	
	for path in possible_paths:
		if FileAccess.file_exists(path):
			return path
	
	# Buscar manualmente en el directorio
	var dir = DirAccess.open("res://" + import_dir)
	if dir:
		dir.list_dir_begin()
		var found_file = dir.get_next()
		while found_file != "":
			if found_file.begins_with(file_name.get_basename()) and found_file.ends_with(".scn"):
				return "res://" + import_dir + found_file
			found_file = dir.get_next()
		dir.list_dir_end()
	
	return ""

func _analyze_fbx_structure(root: Node3D, type: String, anim_name: String = "") -> Dictionary:
	var data = {
		"type": type,
		"name": anim_name if anim_name != "" else String(root.name),  # Convertir a String
		"node": root,
		"skeleton": null,
		"meshes": [],
		"animation_player": null,
		"animations": []
	}
	
	# Buscar Node3D raíz
	if not root is Node3D:
		push_error("El nodo raíz no es Node3D: " + str(root.get_class()))
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
			print("Advertencia: No se encontraron meshes en el modelo base")
			# No retornar error aquí, puede ser que los meshes estén en otro lugar
	
	# Para animaciones: extraer lista de animaciones
	if type == "animation" and data.animation_player:
		data.animations = _extract_animation_list(data.animation_player)
		if data.animations.is_empty():
			print("Advertencia: No se encontraron animaciones en el archivo")
	
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
	
	# Buscar MeshInstance3D directamente en el skeleton
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
			if child.mesh and child.mesh.get_surface_count() > 0:
				for i in range(child.mesh.get_surface_count()):
					var material = child.get_surface_override_material(i)
					if material:
						mesh_data.materials.append(material)
					else:
						# Usar material por defecto del mesh
						var default_material = child.mesh.surface_get_material(i)
						if default_material:
							mesh_data.materials.append(default_material)
			
			meshes.append(mesh_data)
	
	# Si no encontramos meshes en el skeleton, buscar en el padre
	if meshes.is_empty():
		var parent = skeleton.get_parent()
		if parent:
			for child in parent.get_children():
				if child is MeshInstance3D:
					var mesh_data = {
						"node": child,
						"mesh_resource": child.mesh,
						"name": child.name,
						"materials": [],
						"skeleton_path": child.get_path_to(skeleton) if skeleton else NodePath()
					}
					meshes.append(mesh_data)
	
	return meshes

func _extract_animation_list(anim_player: AnimationPlayer) -> Array:
	var animations = []
	
	# Obtener animaciones de todas las librerías
	for library_name in anim_player.get_animation_library_list():
		var library = anim_player.get_animation_library(library_name)
		if library:
			for anim_name in library.get_animation_list():
				var anim = library.get_animation(anim_name)
				if anim:
					animations.append({
						"name": anim_name,
						"length": anim.length,
						"step": anim.step,
						"loop": anim.loop_mode != Animation.LOOP_NONE,
						"resource": anim,
						"library": library_name
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
		if model_data.has("node") and model_data.node:
			model_data.node.queue_free()
	
	loaded_models_cache.clear()

# Validar si un archivo es FBX válido
func validate_fbx_file(path: String) -> bool:
	var extension = path.get_extension().to_lower()
	if not extension in ["fbx", "gltf", "glb"]:
		return false
	
	return FileAccess.file_exists(path)

# Función para verificar si es archivo GLTF/GLB (más fácil de importar)
func is_gltf_file(path: String) -> bool:
	var extension = path.get_extension().to_lower()
	return extension in ["gltf", "glb"]

# Cargar archivo GLTF/GLB (más confiable que FBX)
func load_gltf_file(path: String, type: String, anim_name: String = "") -> void:
	print("Cargando archivo GLTF/GLB: ", path.get_file())
	
	# Los archivos GLTF/GLB son más fáciles de importar
	var cache_key = path + "_" + type
	if type == "animation":
		cache_key += "_" + anim_name
	
	if cache_key in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	# Cargar directamente (GLTF/GLB se importan automáticamente)
	await _load_fbx_file(path, type, anim_name)

# Función para obtener estadísticas del FBX cargado
func get_fbx_stats(model_data: Dictionary) -> Dictionary:
	var bounds_size = Vector3.ZERO
	if model_data.has("bounds") and model_data.bounds is AABB:
		bounds_size = model_data.bounds.size
	
	return {
		"name": model_data.get("name", "Unknown"),
		"type": model_data.get("type", "Unknown"),
		"bone_count": model_data.get("bone_count", 0),
		"mesh_count": model_data.get("meshes", []).size(),
		"animation_count": model_data.get("animations", []).size(),
		"bounds_size": bounds_size
	}

func cleanup_temp_files():
	var dir = DirAccess.open(TEMP_IMPORT_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

# Función para diagnosticar problemas de FBX
func diagnose_fbx_issues(folder_path: String) -> Dictionary:
	var diagnosis = {
		"fbx_files": [],
		"gltf_files": [],
		"problematic_files": [],
		"suggestions": []
	}
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		return diagnosis
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var extension = file_name.get_extension().to_lower()
			var full_path = folder_path + "/" + file_name
			
			match extension:
				"fbx":
					diagnosis.fbx_files.append(full_path)
					# Verificar si tiene espacios o caracteres especiales
					if " " in file_name or "(" in file_name or ")" in file_name:
						diagnosis.problematic_files.append({
							"file": file_name,
							"issue": "Nombre con espacios/caracteres especiales"
						})
				"gltf", "glb":
					diagnosis.gltf_files.append(full_path)
				"blend":
					diagnosis.suggestions.append("Archivo Blender encontrado: " + file_name + " - Puedes exportarlo como GLTF")
		
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Generar sugerencias
	if diagnosis.gltf_files.size() > 0:
		diagnosis.suggestions.append("✅ ARCHIVOS GLTF/GLB ENCONTRADOS - Estos funcionan mejor que FBX")
	
	if diagnosis.problematic_files.size() > 0:
		diagnosis.suggestions.append("⚠️ Archivos FBX con nombres problemáticos encontrados")
	
	if diagnosis.fbx_files.size() > 0 and diagnosis.gltf_files.size() == 0:
		diagnosis.suggestions.append("💡 RECOMENDACIÓN: Convierte los FBX a GLTF usando Blender para mejor compatibilidad")
	
	return diagnosis

# Función para crear archivo de prueba si todo falla
func create_test_model() -> Dictionary:
	print("Creando modelo de prueba básico...")
	
	# Crear escena simple con skeleton
	var root = Node3D.new()
	root.name = "TestModel"
	
	var skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	
	# Agregar hueso simple
	skeleton.add_bone("Root")
	skeleton.set_bone_rest(0, Transform3D.IDENTITY)
	skeleton.set_bone_pose_rotation(0, Quaternion.IDENTITY)
	skeleton.set_bone_pose_position(0, Vector3.ZERO)
	
	# Crear mesh simple
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TestMesh"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2, 4, 1)  # Tamaño de personaje básico
	mesh_instance.mesh = box_mesh
	
	skeleton.add_child(mesh_instance)
	
	# Crear datos del modelo
	var model_data = {
		"type": "base",
		"name": "TestModel",
		"node": root,
		"skeleton": skeleton,
		"meshes": [{
			"node": mesh_instance,
			"mesh_resource": box_mesh,
			"name": "TestMesh",
			"materials": [],
			"skeleton_path": mesh_instance.get_path_to(skeleton)
		}],
		"animation_player": null,
		"animations": [],
		"bounds": AABB(Vector3(-1, -2, -0.5), Vector3(2, 4, 1)),
		"bone_count": 1
	}
	
	print("Modelo de prueba creado exitosamente")
	return model_data

func _debug_list_files_in_imported_dir(fbx_filename: String):
	# Función de debug para listar archivos en .godot/imported/
	var import_dir = ".godot/imported/"
	var dir = DirAccess.open("res://" + import_dir)
	
	if dir:
		print("Archivos en ", import_dir, " que contienen '", fbx_filename.get_basename(), "':")
		dir.list_dir_begin()
		var found_file = dir.get_next()
		while found_file != "":
			if found_file.contains(fbx_filename.get_basename()) or found_file.contains(fbx_filename):
				print("  - ", found_file)
			found_file = dir.get_next()
		dir.list_dir_end()
	else:
		print("No se pudo acceder al directorio de importación")

# Intentar conversión directa del FBX
func _try_direct_fbx_conversion(fbx_path: String) -> String:
	print("Intentando conversión directa del FBX...")
	
	# Crear archivo .import manualmente para forzar importación
	var success = _create_import_file(fbx_path)
	if success:
		print("Archivo .import creado exitosamente")
		await get_tree().create_timer(1.0).timeout
		
		# Verificar si podemos cargar ahora
		if _can_load_fbx_resource(fbx_path):
			print("FBX convertido y listo para usar")
			return fbx_path
		
		# Buscar archivo importado
		var imported_path = _find_imported_scene_path(fbx_path)
		if imported_path != "" and ResourceLoader.exists(imported_path):
			print("Archivo importado encontrado: ", imported_path)
			return fbx_path
	
	print("Conversión directa falló, probando alternativas...")
	return ""

# Crear archivo .import para forzar la importación
func _create_import_file(fbx_path: String) -> bool:
	var import_file_path = fbx_path + ".import"
	
	# Generar UIDs únicos
	var uid1 = _generate_uid()
	var uid2 = _generate_uid()
	var file_name = fbx_path.get_file()
	var hash_suffix = uid2.substr(0, 32)
	
	# Configuración de importación estándar para FBX
	var import_config = "[remap]\n\n"
	import_config += "importer=\"scene\"\n"
	import_config += "importer_version=1\n"
	import_config += "type=\"PackedScene\"\n"
	import_config += "uid=\"uid://" + uid1 + "\"\n"
	import_config += "path=\"res://.godot/imported/" + file_name + "-" + hash_suffix + ".scn\"\n\n"
	import_config += "[deps]\n\n"
	import_config += "source_file=\"" + fbx_path + "\"\n"
	import_config += "dest_files=[\"res://.godot/imported/" + file_name + "-" + hash_suffix + ".scn\"]\n\n"
	import_config += "[params]\n\n"
	import_config += "nodes/root_type=\"\"\n"
	import_config += "nodes/root_name=\"\"\n"
	import_config += "nodes/apply_root_scale=true\n"
	import_config += "nodes/root_scale=1.0\n"
	import_config += "meshes/ensure_tangents=true\n"
	import_config += "meshes/generate_lods=true\n"
	import_config += "meshes/create_shadow_meshes=true\n"
	import_config += "meshes/light_baking=1\n"
	import_config += "meshes/lightmap_texel_size=0.2\n"
	import_config += "meshes/force_disable_compression=false\n"
	import_config += "skins/use_named_skins=true\n"
	import_config += "animation/import=true\n"
	import_config += "animation/fps=30\n"
	import_config += "animation/trimming=false\n"
	import_config += "animation/remove_immutable_tracks=true\n"
	import_config += "animation/import_rest_as_RESET=false\n"
	import_config += "import_script/path=\"\"\n"
	import_config += "_subresources={}\n"
	import_config += "gltf/naming_version=1\n"
	import_config += "gltf/embedded_image_handling=1\n"
	
	var file = FileAccess.open(import_file_path, FileAccess.WRITE)
	if file:
		file.store_string(import_config)
		file.close()
		print("Archivo .import creado: ", import_file_path)
		return true
	else:
		print("Error creando archivo .import")
		return false

# Generar UID único
func _generate_uid() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var uid = ""
	for i in range(32):
		uid += chars[randi() % chars.length()]
	return uid

# Forzar importación con métodos alternativos
func _force_import_fbx(fbx_path: String):
	print("Forzando importación de FBX...")
	
	# Crear directorio de importación si no existe
	DirAccess.make_dir_recursive_absolute("res://.godot/imported/")
	
	# Esperar tiempo adicional para procesamiento
	var wait_time = 0.0
	var max_wait = 10.0
	
	while wait_time < max_wait:
		await get_tree().create_timer(0.5).timeout
		wait_time += 0.5
		
		# Verificar si el archivo fue importado
		if _can_load_fbx_resource(fbx_path):
			print("Importación exitosa después de ", wait_time, " segundos")
			return
		
		# Verificar archivos importados
		var imported_path = _find_imported_scene_path(fbx_path)
		if imported_path != "" and ResourceLoader.exists(imported_path):
			print("Archivo importado encontrado: ", imported_path)
			return
	
	print("Tiempo de espera agotado para importación")

# Método alternativo para cargar FBX usando recursos básicos
func _load_fbx_as_basic_model(fbx_path: String) -> PackedScene:
	print("Intentando carga básica del FBX...")
	
	# Intentar diferentes métodos de carga secuencialmente
	var result = null
	
	# Método 1: Carga directa
	if ResourceLoader.exists(fbx_path):
		result = load(fbx_path)
		if result and result is PackedScene:
			print("Carga exitosa usando load() directo")
			return result
	
	# Método 2: ResourceLoader con tipo específico
	if ResourceLoader.exists(fbx_path):
		result = ResourceLoader.load(fbx_path, "PackedScene")
		if result and result is PackedScene:
			print("Carga exitosa usando ResourceLoader con PackedScene")
			return result
	
	# Método 3: ResourceLoader sin tipo específico
	if ResourceLoader.exists(fbx_path):
		result = ResourceLoader.load(fbx_path, "")
		if result and result is PackedScene:
			print("Carga exitosa usando ResourceLoader sin tipo")
			return result
	
	# Método 4: Verificar si existe un plugin FBX loader
	var fbx_loader_path = "res://addons/fbx_loader/fbx_loader.gd"
	if ResourceLoader.exists(fbx_loader_path):
		var fbx_loader = load(fbx_loader_path)
		if fbx_loader:
			print("Plugin FBX loader encontrado, pero implementación pendiente")
			# TODO: Implementar uso del plugin si está disponible
	
	print("No se pudo cargar FBX con métodos alternativos")
	return null
