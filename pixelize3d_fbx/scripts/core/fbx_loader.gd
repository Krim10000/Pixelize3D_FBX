# scripts/core/fbx_loader.gd
# Input: Rutas de archivos FBX (pueden estar fuera del proyecto)
# Output: Datos del modelo cargado SIN LOOPS ni procesamiento excesivo
# ✅ VERSIÓN SIMPLIFICADA para evitar loops de carga

extends Node

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
	print("🏗️ CARGANDO MODELO BASE: %s" % fbx_path.get_file())
	var cache_key = fbx_path + "_base"
	if cache_key in loaded_models_cache:
		print("✅ Cache hit para modelo base")
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	_load_fbx_file(fbx_path, "base")

func load_animation_fbx(fbx_path: String, _ignored_param: String = "") -> void:
	print("🎭 CARGANDO ANIMACIÓN: %s" % fbx_path.get_file())
	# ✅ CRÍTICO: El nombre es SIEMPRE el basename del archivo
	var animation_name = fbx_path.get_file().get_basename()
	print("🎯 Nombre de animación será: '%s'" % animation_name)
	
	var cache_key = fbx_path + "_anim_" + animation_name
	if cache_key in loaded_models_cache:
		print("✅ Cache hit para animación")
		emit_signal("model_loaded", loaded_models_cache[cache_key])
		return
	
	_load_fbx_file(fbx_path, "animation", animation_name)

# === FUNCIÓN PRINCIPAL DE CARGA SIMPLIFICADA ===

func _load_fbx_file(path: String, type: String, anim_name: String = "") -> void:
	print("\n🔄 === INICIANDO CARGA FBX ===")
	print("Archivo: %s" % path.get_file())
	print("Tipo: %s" % type)
	print("Nombre anim: %s" % anim_name)
	
	emit_signal("load_progress", 0.1)

	if not FileAccess.file_exists(path):
		emit_signal("load_failed", "Archivo no encontrado: " + path)
		return

	emit_signal("load_progress", 0.3)

	# ✅ SIMPLIFICACIÓN: Intentar carga directa primero
	var scene_resource = _try_direct_load(path)
	
	if not scene_resource:
		# Solo si falla, intentar importación externa
		emit_signal("load_progress", 0.5)
		var import_path = await _handle_external_fbx(path)
		if import_path == "":
			return
		
		scene_resource = _try_direct_load(import_path)
		
		if not scene_resource:
			emit_signal("load_failed", "No se pudo cargar el archivo FBX: " + path.get_file())
			return

	emit_signal("load_progress", 0.7)

	var instance = scene_resource.instantiate()
	if not instance:
		emit_signal("load_failed", "No se pudo instanciar la escena FBX")
		return

	emit_signal("load_progress", 0.8)

	# ✅ SIMPLIFICACIÓN CRÍTICA: Análisis directo sin procesamiento excesivo
	var model_data = _analyze_fbx_simple(instance, type, anim_name, path)
	if model_data.is_empty():
		instance.queue_free()
		emit_signal("load_failed", "Estructura FBX no válida")
		return

	emit_signal("load_progress", 1.0)

	# Guardar en cache
	var cache_key = path + "_" + type
	if type == "animation" and anim_name != "":
		cache_key += "_" + anim_name
	loaded_models_cache[cache_key] = model_data

	print("✅ FBX cargado exitosamente: %s" % path.get_file())
	print("=== FIN CARGA FBX ===\n")
	emit_signal("model_loaded", model_data)

# === FUNCIONES SIMPLIFICADAS ===

func _try_direct_load(fbx_path: String) -> PackedScene:
	"""Intentar carga directa del FBX"""
	print("🔄 Intentando carga directa: %s" % fbx_path.get_file())
	
	if ResourceLoader.exists(fbx_path):
		var result = load(fbx_path)
		if result and result is PackedScene:
			print("✅ Carga directa exitosa")
			return result
	
	print("❌ Carga directa falló")
	return null

func _handle_external_fbx(external_path: String) -> String:
	"""Manejar FBX externo de forma simple"""
	var project_path = ProjectSettings.globalize_path("res://")
	var is_external = not external_path.begins_with("res://") and not external_path.begins_with(project_path)
	
	if not is_external:
		return external_path
	
	print("📂 Archivo externo detectado, copiando...")
	
	# Copiar al directorio temporal
	var file_name = external_path.get_file()
	var safe_name = file_name.replace(" ", "_").replace("(", "").replace(")", "")
	var temp_path = TEMP_IMPORT_DIR + safe_name
	
	var error = _copy_file_to_project(external_path, temp_path)
	if error != OK:
		print("❌ Error copiando archivo: %d" % error)
		emit_signal("load_failed", "No se pudo copiar el archivo FBX al proyecto")
		return ""
	
	print("✅ Archivo copiado a: %s" % temp_path)
	
	# Esperar un poco para que Godot lo procese
	await get_tree().create_timer(2.0).timeout
	
	return temp_path

func _analyze_fbx_simple(root: Node3D, type: String, anim_name: String, original_path: String) -> Dictionary:
	"""Análisis simplificado sin loops"""
	print("🔍 Analizando estructura FBX...")
	
	# ✅ CRÍTICO: Para animaciones, usar SIEMPRE el basename del archivo
	var final_name = anim_name
	if type == "animation":
		final_name = original_path.get_file().get_basename()
		print("🎯 Nombre final para animación: '%s'" % final_name)
	
	var data = {
		"type": type,
	   #"name": final_name if final_name != "" else root.name,
		"name": StringName(final_name) if final_name != "" else root.name,
		"skeleton": null,
		"meshes": [],
		"animations": [],
		"animation_player": null,
		"bone_count": 0,
		"bounds": AABB(),
		# Metadatos básicos
		"original_filename": original_path.get_file(),
		"display_name": _generate_display_name(original_path.get_file().get_basename()),
		"file_metadata": {
			"filename": original_path.get_file(),
			"basename": original_path.get_file().get_basename(),
			"full_path": original_path,
			"display_name": _generate_display_name(original_path.get_file().get_basename())
		}
	}
	
	# Buscar skeleton
	var skeleton = _find_skeleton(root)
	if not skeleton:
		print("❌ No se encontró Skeleton3D")
		return {}
	
	data.skeleton = skeleton
	data.bone_count = skeleton.get_bone_count()
	print("✅ Skeleton encontrado: %d huesos" % data.bone_count)
	
	# Buscar AnimationPlayer
	var anim_player = _find_animation_player(root)
	if anim_player:
		data.animation_player = anim_player
		data.animations = anim_player.get_animation_list()
		print("✅ AnimationPlayer: %d animaciones" % data.animations.size())
		
		# ✅ CRÍTICO: SOLO para animaciones específicas, renombrar la primera animación
		if type == "animation" and final_name != "" and data.animations.size() > 0:
			_rename_first_animation_only(anim_player, final_name)
	else:
		print("⚠️ No se encontró AnimationPlayer")
	
	# Extraer meshes solo para modelos base
	if type == "base":
		data.meshes = _extract_meshes_simple(skeleton)
		print("✅ Meshes extraídos: %d" % data.meshes.size())
	
	return data

func _rename_first_animation_only(anim_player: AnimationPlayer, target_name: String):
	"""Renombrar SOLO la primera animación, evitando loops"""
	var animation_list = anim_player.get_animation_list()
	if animation_list.size() == 0:
		return
	
	var first_anim_name = animation_list[0]
	if first_anim_name == target_name:
		print("ℹ️ Primera animación ya tiene el nombre correcto: %s" % target_name)
		return
	
	print("🔄 Renombrando primera animación: '%s' -> '%s'" % [first_anim_name, target_name])
	
	var anim_lib = anim_player.get_animation_library("")
	var animation = anim_lib.get_animation(first_anim_name)
	
	if animation and _is_valid_name(target_name):
		var result = anim_lib.add_animation(target_name, animation)
		if result == OK:
			anim_lib.remove_animation(first_anim_name)
			print("✅ Renombrado exitoso")
		else:
			print("❌ Error renombrando: código %d" % result)
	else:
		print("❌ No se pudo renombrar: animación=%s, nombre_válido=%s" % [animation != null, _is_valid_name(target_name)])

func _is_valid_name(name_file: String) -> bool:
	"""Validación simple de nombre"""
	return name_file.strip_edges() != "" and not name_file.contains(":") and not name_file.contains("/")

func _generate_display_name(basename: String) -> String:
	"""Generar nombre de display simple"""
	var display_name = basename.replace("_", " ").replace("-", " ")
	
	# Capitalizar primera letra de cada palabra
	var words = display_name.split(" ")
	for i in range(words.size()):
		if words[i].length() > 0:
			words[i] = words[i].capitalize()
	
	return " ".join(words)

# === FUNCIONES DE BÚSQUEDA BÁSICAS ===

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

func _extract_meshes_simple(skeleton: Skeleton3D) -> Array:
	"""Extracción simple de meshes"""
	var meshes = []
	
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
			
			# Extraer materiales básicos
			if child.mesh and child.mesh.get_surface_count() > 0:
				for i in range(child.mesh.get_surface_count()):
					var material = child.get_surface_override_material(i)
					if not material:
						material = child.mesh.surface_get_material(i)
					mesh_data.materials.append(material)
			
			meshes.append(mesh_data)
	
	return meshes

func _copy_file_to_project(from: String, to: String) -> Error:
	"""Copia simple de archivo"""
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

# === FUNCIONES DE DEBUG ===

func debug_loaded_data():
	"""Debug simple del estado de carga"""
	print("\n🔍 === DEBUG FBX LOADER ===")
	print("Cache entries: %d" % loaded_models_cache.size())
	for key in loaded_models_cache.keys():
		var data = loaded_models_cache[key]
		print("  %s: %s (%s)" % [key, data.get("name", "Unknown"), data.get("type", "Unknown")])
	print("=============================\n")


func load_animation_resource(fbx_path: String) -> Animation:
	"""Carga una animación FBX y devuelve el recurso Animation directamente (sin reemplazar modelo)"""
	var scene_resource = _try_direct_load(fbx_path)
	if not scene_resource:
		var import_path = await _handle_external_fbx(fbx_path)
		if import_path == "":
			return null
		scene_resource = _try_direct_load(import_path)
		if not scene_resource:
			printerr("❌ No se pudo cargar el FBX de animación: %s" % fbx_path)
			return null

	var instance = scene_resource.instantiate()
	if not instance:
		printerr("❌ No se pudo instanciar la escena")
		return null

	var anim_player = _find_animation_player(instance)
	if not anim_player:
		printerr("❌ No se encontró AnimationPlayer en %s" % fbx_path)
		instance.queue_free()
		return null

	var animation_names = anim_player.get_animation_list()
	if animation_names.is_empty():
		printerr("❌ No se encontraron animaciones en %s" % fbx_path)
		instance.queue_free()
		return null

	var animation = anim_player.get_animation(animation_names[0])
	instance.queue_free()
	return animation
