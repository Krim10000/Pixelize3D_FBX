# scripts/core/fbx_loader.gd
# Input: Rutas de archivos FBX (pueden estar fuera del proyecto)
# Output: Datos del modelo cargado CON NOMBRES DE ARCHIVO PRESERVADOS

extends Node

signal model_loaded(model_data: Dictionary)
signal load_failed(error: String)
signal load_progress(progress: float)

# Cache para optimizar carga
var loaded_models_cache = {}

# Directorio temporal para importar FBX
const TEMP_IMPORT_DIR = "res://temp_fbx_import/"
const AnimationNameFix = preload("res://scripts/core/animation_name_fix.gd")

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


#func _load_fbx_file(path: String, type: String, anim_name: String = "") -> void:
	#emit_signal("load_progress", 0.1)
	#
	## Verificar que el archivo existe
	#if not FileAccess.file_exists(path):
		#emit_signal("load_failed", "Archivo no encontrado: " + path)
		#return
	#
	#emit_signal("load_progress", 0.2)
	#
	## Determinar si el archivo está dentro del proyecto
	#var project_path = ProjectSettings.globalize_path("res://")
	#var is_external = not path.begins_with("res://") and not path.begins_with(project_path)
	#
	#var import_path = path
	#
	## Si es externo, copiarlo e intentar importación automática
	#if is_external:
		#print("Procesando archivo FBX externo: ", path.get_file())
		#import_path = await _import_external_fbx(path)
		#if import_path == "":
			#emit_signal("load_failed", "No se pudo procesar el archivo FBX externo")
			#return
	#
	#emit_signal("load_progress", 0.5)
	#
	## Intentar cargar el archivo FBX con múltiples métodos
	#var scene_resource = await _load_imported_scene(import_path)
	#if not scene_resource:
		## Intentar crear archivo .import si no existe
		#if not FileAccess.file_exists(import_path + ".import"):
			#print("Creando archivo .import para: ", import_path.get_file())
			#if _create_import_file(import_path):
				#await get_tree().create_timer(2.0).timeout
				#scene_resource = await _load_imported_scene(import_path)
		#
		#if not scene_resource:
			#var error_msg = "No se pudo cargar el archivo FBX: " + path.get_file()
			#error_msg += "\n\nPosibles soluciones:"
			#error_msg += "\n• Verifica que el archivo FBX sea válido"
			#error_msg += "\n• Intenta con un archivo FBX más simple"
			#error_msg += "\n• Coloca el archivo en res://temp_fbx_import/ manualmente"
			#
			#emit_signal("load_failed", error_msg)
			#return
	#
	#emit_signal("load_progress", 0.7)
	#
	## Instanciar la escena
	#var instance = scene_resource.instantiate()
	#if not instance:
		#emit_signal("load_failed", "No se pudo instanciar la escena FBX")
		#return
	#
	#emit_signal("load_progress", 0.8)
	#
	## CRÍTICO: Analizar estructura del FBX CON METADATOS DE ARCHIVO
	#var model_data = _analyze_fbx_structure_with_metadata(instance, type, anim_name, path)
	#
	#if model_data.is_empty():
		#instance.queue_free()
		#emit_signal("load_failed", "Estructura FBX no válida - verifica que tenga Skeleton3D y MeshInstance3D")
		#return
	#
	#emit_signal("load_progress", 1.0)
	#
	## Guardar en cache
	#var cache_key = path + "_" + type
	#if type == "animation":
		#cache_key += "_" + anim_name
	#loaded_models_cache[cache_key] = model_data
	#
	#print("FBX cargado exitosamente: ", path.get_file(), " (tipo: ", type, ")")
	#emit_signal("model_loaded", model_data)




func _load_fbx_file(path: String, type: String, anim_name: String = "") -> void:
	emit_signal("load_progress", 0.1)

	if not FileAccess.file_exists(path):
		emit_signal("load_failed", "Archivo no encontrado: " + path)
		return

	emit_signal("load_progress", 0.2)

	var project_path = ProjectSettings.globalize_path("res://")
	var is_external = not path.begins_with("res://") and not path.begins_with(project_path)
	var import_path = path

	if is_external:
		print("Procesando archivo FBX externo: ", path.get_file())
		import_path = await _import_external_fbx(path)
		if import_path == "":
			emit_signal("load_failed", "No se pudo procesar el archivo FBX externo")
			return

	emit_signal("load_progress", 0.5)

	var scene_resource = await _load_imported_scene(import_path)
	if not scene_resource:
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

	var instance = scene_resource.instantiate()
	if not instance:
		emit_signal("load_failed", "No se pudo instanciar la escena FBX")
		return

	# ✅ Corrección de nombres de animaciones
	var anim_player := instance.get_node_or_null("AnimationPlayer")
	if anim_player:
		var base_name = path.get_file().get_basename()
		AnimationNameFix.process_loaded_model({
			"animation_player": anim_player,
			"name": base_name
		})
		AnimationNameFix.debug_animation_names(anim_player, base_name)
	else:
		print("⚠️ No se encontró AnimationPlayer en:", path)

	emit_signal("load_progress", 0.8)

	var model_data = _analyze_fbx_structure_with_metadata(instance, type, anim_name, path)
	if model_data.is_empty():
		instance.queue_free()
		emit_signal("load_failed", "Estructura FBX no válida - verifica que tenga Skeleton3D y MeshInstance3D")
		return

	emit_signal("load_progress", 1.0)

	var cache_key = path + "_" + type
	if type == "animation":
		cache_key += "_" + anim_name
	loaded_models_cache[cache_key] = model_data

	print("FBX cargado exitosamente: ", path.get_file(), " (tipo: ", type, ")")
	emit_signal("model_loaded", model_data)


# ✅ FUNCIÓN NUEVA: Analizar estructura CON preservación de metadatos de archivo
func _analyze_fbx_structure_with_metadata(root: Node3D, type: String, anim_name: String, original_path: String) -> Dictionary:
	# Extraer información de archivo ANTES de analizar estructura
	var file_metadata = _extract_file_metadata(original_path, anim_name)
	
	# Realizar análisis normal de estructura
	var data = _analyze_fbx_structure_base(root, type, anim_name)
	
	if data.is_empty():
		return {}
	
	# ✅ CRÍTICO: Agregar metadatos de archivo al data
	data["original_filename"] = file_metadata.filename
	data["source_file_path"] = file_metadata.full_path
	data["display_name"] = file_metadata.display_name
	data["file_metadata"] = file_metadata
	
	print("✅ Metadatos de archivo preservados:")
	print("  - Archivo original: %s" % file_metadata.filename)
	print("  - Nombre display: %s" % file_metadata.display_name)
	print("  - Ruta completa: %s" % file_metadata.full_path)
	
	return data

# ✅ FUNCIÓN NUEVA: Extraer metadatos limpios del archivo
func _extract_file_metadata(file_path: String, anim_name: String) -> Dictionary:
	var filename = file_path.get_file()
	var basename = filename.get_basename()
	
	# Generar nombre de display limpio
	var display_name = _generate_clean_display_name(basename, anim_name)
	
	return {
		"filename": filename,
		"basename": basename,
		"full_path": file_path,
		"display_name": display_name,
		"directory": file_path.get_base_dir(),
		"extension": filename.get_extension()
	}

# ✅ FUNCIÓN NUEVA: Generar nombre de display limpio desde el archivo
func _generate_clean_display_name(basename: String, anim_name: String) -> String:
	var display_name = basename
	
	# Usar basename si anim_name está vacío o es genérico
	if anim_name == "" or anim_name == basename:
		display_name = basename
	else:
		# Usar anim_name si es más descriptivo
		display_name = anim_name
	
	# Limpiar nombres técnicos comunes
	display_name = display_name.replace("mixamo.com", "")
	display_name = display_name.replace("Armature|", "")
	display_name = display_name.replace("Take001", "")
	display_name = display_name.replace("Take 001", "")
	display_name = display_name.replace("_", " ")
	display_name = display_name.replace("-", " ")
	display_name = display_name.strip_edges()
	
	# Capitalizar primera letra de cada palabra
	var words = display_name.split(" ")
	for i in range(words.size()):
		if words[i].length() > 0:
			words[i] = words[i].capitalize()
	
	var result = " ".join(words)
	
	# Si el resultado está vacío, usar el basename original
	if result.strip_edges() == "":
		result = basename.replace("_", " ").capitalize()
	
	return result

# ✅ FUNCIÓN REFACTORIZADA: Análisis base de estructura (sin metadatos)
func _analyze_fbx_structure_base(root: Node3D, type: String, anim_name: String) -> Dictionary:
	var data = {
		"type": type,
		"name": anim_name if anim_name != "" else root.name,
		"skeleton": null,
		"meshes": [],
		"animations": [],
		"animation_player": null,
		"bone_count": 0,
		"bounds": AABB()
	}
	
	# Buscar skeleton
	var skeleton = _find_skeleton(root)
	if not skeleton:
		print("❌ No se encontró Skeleton3D en el FBX")
		return {}
	
	data.skeleton = skeleton
	data.bone_count = skeleton.get_bone_count()
	
	# Buscar AnimationPlayer
	var anim_player = _find_animation_player(root)
	if anim_player:
		data.animation_player = anim_player
		data.animations = anim_player.get_animation_list()
		print("✅ AnimationPlayer encontrado con %d animaciones" % data.animations.size())
	else:
		print("⚠️ No se encontró AnimationPlayer")
	
	# Extraer meshes del skeleton
	if type == "base":
		data.meshes = _extract_meshes_from_skeleton(skeleton)
		data.bounds = _calculate_model_bounds(data.meshes)
		print("✅ Extraídos %d meshes del modelo base" % data.meshes.size())
	
	return data

# FUNCIONES EXISTENTES (sin cambios significativos)
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

func _try_direct_fbx_conversion(fbx_path: String) -> String:
	print("Intentando conversión directa del FBX...")
	
	# Esperar tiempo para que Godot procese la importación automáticamente
	await _wait_for_import(fbx_path)
	
	# Verificar si fue importado exitosamente
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

func _calculate_model_bounds(meshes: Array) -> AABB:
	var bounds = AABB()
	var first_mesh = true
	
	for mesh_data in meshes:
		if mesh_data.mesh_resource and mesh_data.mesh_resource.get_aabb:
			var mesh_bounds = mesh_data.mesh_resource.get_aabb()
			if first_mesh:
				bounds = mesh_bounds
				first_mesh = false
			else:
				bounds = bounds.merge(mesh_bounds)
	
	return bounds

# FUNCIONES DE UTILIDAD ADICIONALES

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

func _generate_uid() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var uid = ""
	for i in range(32):
		uid += chars[randi() % chars.length()]
	return uid

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
	
	print("No se pudo cargar FBX con métodos alternativos")
	return null

func _debug_list_files_in_imported_dir(filename: String):
	print("Listando archivos en .godot/imported/ para debug:")
	var dir = DirAccess.open("res://.godot/imported/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var count = 0
		while file_name != "" and count < 10:  # Limitar a 10 archivos para debug
			if filename.get_basename() in file_name:
				print("  Encontrado: " + file_name)
			file_name = dir.get_next()
			count += 1
		dir.list_dir_end()

# FUNCIONES ADICIONALES PARA COMPATIBILIDAD CON GLTF/GLB

func load_gltf_directly(gltf_path: String) -> void:
	"""Función adicional para cargar GLTF/GLB directamente (mejor que FBX)"""
	var cache_key = gltf_path + "_gltf"
	if cache_key in loaded_models_cache:
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	# GLTF se carga directamente sin problemas de importación
	await _load_fbx_file(gltf_path, "animation")

func get_fbx_stats(model_data: Dictionary) -> Dictionary:
	"""Función para obtener estadísticas del FBX cargado"""
	var bounds_size = Vector3.ZERO
	if model_data.has("bounds") and model_data.bounds is AABB:
		bounds_size = model_data.bounds.size
	
	return {
		"name": model_data.get("display_name", model_data.get("name", "Unknown")),
		"original_filename": model_data.get("original_filename", "Unknown"),
		"type": model_data.get("type", "Unknown"),
		"bone_count": model_data.get("bone_count", 0),
		"mesh_count": model_data.get("meshes", []).size(),
		"animation_count": model_data.get("animations", []).size(),
		"bounds_size": bounds_size
	}

func cleanup_temp_files():
	"""Limpiar archivos temporales"""
	var dir = DirAccess.open(TEMP_IMPORT_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
