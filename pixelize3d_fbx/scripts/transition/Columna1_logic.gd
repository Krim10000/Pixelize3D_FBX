# pixelize3d_fbx/scripts/transition/Columna1_logic.gd
# Lógica de carga para la Columna 1 del sistema de transiciones
# Input: Solicitudes de carga de modelo base y animaciones
# Output: Datos de modelo y animaciones cargados, señales de estado

extends Node
class_name Columna1Logic

# === SEÑALES HACIA LA UI ===
signal base_loaded(model_data: Dictionary)
signal animation_loaded(animation_data: Dictionary)
signal loading_failed(error_message: String)
signal loading_progress(stage: String, progress: float)

# === SEÑALES HACIA EL COORDINADOR ===
signal animations_ready(anim_a_data: Dictionary, anim_b_data: Dictionary)

# === REFERENCIAS A SISTEMAS EXISTENTES ===
var fbx_loader: Node
var animation_manager: Node
var fbx_validator: Node
var skeleton_interpolator: TransitionInterpolator  # AÑADIDO

# === ESTADO DE CARGA ===
var loading_state: Dictionary = {
	"base_loaded": false,
	"animation_a_loaded": false,
	"animation_b_loaded": false,
	"is_loading": false
}

# === DATOS CARGADOS ===
var base_data: Dictionary = {}
var animation_a_data: Dictionary = {}
var animation_b_data: Dictionary = {}

# === RUTAS DE ARCHIVOS ===
var loaded_base_path: String = ""
var loaded_animation_a_path: String = ""
var loaded_animation_b_path: String = ""

func _ready():
	print("📂 Columna1Logic inicializando...")
	# Usar inicialización diferida para evitar problemas de timing
	_initialize_loading_systems.call_deferred()
	_connect_loader_signals.call_deferred()
	print("✅ Columna1Logic listo (inicialización diferida)")

func _initialize_loading_systems():
	"""Inicializar sistemas de carga existentes"""
	print("🔧 Inicializando sistemas de carga...")
	
	# Buscar FBXLoader existente o crear uno nuevo
	fbx_loader = _find_or_create_fbx_loader()
	
	# Buscar AnimationManager existente o crear uno nuevo
	animation_manager = _find_or_create_animation_manager()
	
	# Buscar FBXValidator existente o crear uno nuevo
	fbx_validator = _find_or_create_fbx_validator()
	
	# Crear interpolador de esqueletos
	if not skeleton_interpolator:
		skeleton_interpolator = TransitionInterpolator.new()
		skeleton_interpolator.name = "SkeletonInterpolator"
		# Usar call_deferred por seguridad si hay problemas de timing
		if get_tree().current_scene.is_node_ready():
			add_child(skeleton_interpolator)
		else:
			add_child.call_deferred(skeleton_interpolator)
		print("🔧 SkeletonInterpolator creado")
	
	print("✅ Sistemas de carga inicializados")

func _find_or_create_fbx_loader() -> Node:
	"""Buscar FBXLoader existente o crear uno nuevo - VERSION CORREGIDA"""
	var loader = get_node_or_null("/root/ViewerModular/FBXLoader")
	if not loader:
		loader = get_node_or_null("../FBXLoader")
	if not loader:
		# Crear nuevo loader usando el patrón que funciona
		var fbx_loader_script = load("res://scripts/core/fbx_loader.gd")
		if fbx_loader_script:
			loader = fbx_loader_script.new()
			loader.name = "FBXLoader"
			add_child(loader)  # Agregar al nodo actual, no a current_scene
			print("🔧 Nuevo FBXLoader creado")
		else:
			print("❌ No se pudo cargar scripts/core/fbx_loader.gd")
			return null
	else:
		print("✅ FBXLoader existente encontrado")
	
	return loader

func _find_or_create_animation_manager() -> Node:
	"""Buscar AnimationManager existente o crear uno nuevo - VERSION CORREGIDA"""
	var manager = get_node_or_null("/root/ViewerModular/AnimationManager")
	if not manager:
		manager = get_node_or_null("../AnimationManager")
	if not manager:
		# Crear nuevo manager usando el patrón que funciona
		var animation_manager_script = load("res://scripts/core/animation_manager.gd")
		if animation_manager_script:
			manager = animation_manager_script.new()
			manager.name = "AnimationManager"
			add_child(manager)  # Agregar al nodo actual
			print("🔧 Nuevo AnimationManager creado")
		else:
			print("❌ No se pudo cargar scripts/core/animation_manager.gd")
			return null
	else:
		print("✅ AnimationManager existente encontrado")
	
	return manager

func _find_or_create_fbx_validator() -> Node:
	"""Buscar FBXValidator existente o crear uno nuevo - VERSION CORREGIDA"""
	var validator = get_node_or_null("../FBXValidator")
	if not validator:
		# Crear nuevo validator usando el patrón que funciona
		var fbx_validator_script = load("res://scripts/core/fbx_validator.gd")
		if fbx_validator_script:
			validator = fbx_validator_script.new()
			validator.name = "FBXValidator"
			add_child(validator)  # Agregar al nodo actual
			print("🔧 Nuevo FBXValidator creado")
		else:
			print("❌ No se pudo cargar scripts/core/fbx_validator.gd")
			return null
	else:
		print("✅ FBXValidator existente encontrado")
	
	return validator

func _connect_loader_signals():
	"""Conectar señales de los sistemas de carga - VERSION ROBUSTA Y DIFERIDA"""
	# Verificar que los sistemas estén inicializados
	if not verify_systems_initialization():
		print("⚠️ Reintentando conexión de señales en 0.1 segundos...")
		await get_tree().create_timer(0.1).timeout
		_connect_loader_signals()  # Reintentar
		return
	
	if not fbx_loader:
		print("❌ FBXLoader no encontrado, no se pueden conectar señales")
		return
	
	print("🔗 Conectando señales del FBXLoader...")
	
	# NO conectar señales aquí - se conectan dinámicamente en cada carga
	# Esto evita conflictos entre callbacks específicos
	
	# Solo conectar señales genéricas si existen
	if fbx_loader.has_signal("loading_failed"):
		if not fbx_loader.loading_failed.is_connected(_on_loading_failed):
			fbx_loader.loading_failed.connect(_on_loading_failed)
			print("🔗 Señal loading_failed conectada (genérica)")
	
	# Conectar señales del AnimationManager si existen
	if animation_manager and animation_manager.has_signal("animation_combined"):
		if not animation_manager.animation_combined.is_connected(_on_animation_combined):
			animation_manager.animation_combined.connect(_on_animation_combined)
			print("🔗 Señal animation_combined conectada")
	
	print("✅ Señales de carga conectadas (callbacks específicos se conectan dinámicamente)")

# ========================================================================
# API PÚBLICA - MÉTODOS DE CARGA
# ========================================================================

func load_base_model(file_path: String):
	"""Cargar modelo base usando patrón del TransitionCoordinator"""
	print("🏗️ Cargando modelo base: %s" % file_path)
	
	if loading_state.is_loading:
		emit_signal("loading_failed", "Ya hay una carga en progreso")
		return
	
	# Validar archivo antes de cargar
	if not _validate_file_path(file_path):
		emit_signal("loading_failed", "Archivo no válido: " + file_path)
		return
	
	loading_state.is_loading = true
	loaded_base_path = file_path
	
	emit_signal("loading_progress", "Cargando modelo base...", 0.1)
	
	# Usar el patrón exacto del TransitionCoordinator
	if fbx_loader and fbx_loader.has_method("load_base_model"):
		# Conectar callback específico con CONNECT_ONE_SHOT
		if not fbx_loader.model_loaded.is_connected(_on_base_model_loaded):
			fbx_loader.model_loaded.connect(_on_base_model_loaded, CONNECT_ONE_SHOT)
		
		fbx_loader.load_base_model(file_path)
	else:
		_fallback_load_base_model(file_path)

func load_animation_a(file_path: String):
	"""Cargar primera animación usando patrón del TransitionCoordinator"""
	print("🎭 Cargando animación A: %s" % file_path)
	
	if loading_state.is_loading:
		emit_signal("loading_failed", "Ya hay una carga en progreso")
		return
	
	if not _validate_file_path(file_path):
		emit_signal("loading_failed", "Archivo no válido: " + file_path)
		return
	
	loading_state.is_loading = true
	loaded_animation_a_path = file_path
	
	emit_signal("loading_progress", "Cargando animación A...", 0.1)
	
	# Usar el patrón exacto del TransitionCoordinator
	if fbx_loader and fbx_loader.has_method("load_animation_fbx"):
		# Conectar callback específico con CONNECT_ONE_SHOT
		if not fbx_loader.model_loaded.is_connected(_on_animation_a_loaded):
			fbx_loader.model_loaded.connect(_on_animation_a_loaded, CONNECT_ONE_SHOT)
		
		fbx_loader.load_animation_fbx(file_path)
	else:
		_fallback_load_animation(file_path, "animation_a")

func load_animation_b(file_path: String):
	"""Cargar segunda animación usando patrón del TransitionCoordinator"""
	print("🎭 Cargando animación B: %s" % file_path)
	
	if loading_state.is_loading:
		emit_signal("loading_failed", "Ya hay una carga en progreso")
		return
	
	if not _validate_file_path(file_path):
		emit_signal("loading_failed", "Archivo no válido: " + file_path)
		return
	
	loading_state.is_loading = true
	loaded_animation_b_path = file_path
	
	emit_signal("loading_progress", "Cargando animación B...", 0.1)
	
	# Usar el patrón exacto del TransitionCoordinator
	if fbx_loader and fbx_loader.has_method("load_animation_fbx"):
		# Conectar callback específico con CONNECT_ONE_SHOT
		if not fbx_loader.model_loaded.is_connected(_on_animation_b_loaded):
			fbx_loader.model_loaded.connect(_on_animation_b_loaded, CONNECT_ONE_SHOT)
		
		fbx_loader.load_animation_fbx(file_path)
	else:
		_fallback_load_animation(file_path, "animation_b")

# ========================================================================
# MANEJADORES DE EVENTOS DE CARGA - PATRÓN TRANSITIONCOORDINATOR
# ========================================================================

func _on_base_model_loaded(model_data: Dictionary):
	"""Callback específico cuando se carga un modelo base - PATRÓN COORDINADOR"""
	print("🔄 DEBUG: Callback _on_base_model_loaded recibido: %s" % str(model_data.keys() if model_data else "null"))
	
	loading_state.is_loading = false
	
	if model_data and model_data.get("type") == "base":
		loading_state.base_loaded = true
		base_data = model_data.duplicate()
		
		# Agregar información adicional
		base_data["file_path"] = loaded_base_path
		base_data["load_time"] = Time.get_unix_time_from_system()
		base_data["type"] = "base"
		
		emit_signal("base_loaded", base_data)
		emit_signal("loading_progress", "Modelo base cargado", 1.0)
		print("✅ COLUMNA1: Modelo base cargado exitosamente")
	else:
		print("❌ COLUMNA1: Error - result type: %s" % model_data.get("type", "no_type"))
		emit_signal("loading_failed", "Error cargando modelo base")
	
	_check_if_ready_for_transition()

func _on_animation_a_loaded(model_data: Dictionary):
	"""Callback específico cuando se carga animación A - PATRÓN COORDINADOR"""
	print("🔄 DEBUG: Callback _on_animation_a_loaded recibido")
	
	loading_state.is_loading = false
	
	if model_data and model_data.get("type") == "animation":
		loading_state.animation_a_loaded = true
		animation_a_data = model_data.duplicate()
		animation_a_data["source_file"] = loaded_animation_a_path
		animation_a_data["file_path"] = loaded_animation_a_path
		animation_a_data["load_time"] = Time.get_unix_time_from_system()
		animation_a_data["type"] = "animation_a"
		
		emit_signal("animation_loaded", animation_a_data)
		emit_signal("loading_progress", "Animación A cargada", 1.0)
		print("✅ COLUMNA1: Animación A cargada exitosamente")
	else:
		print("❌ COLUMNA1: Error cargando animación A")
		emit_signal("loading_failed", "Error cargando animación A")
	
	_check_if_ready_for_transition()

func _on_animation_b_loaded(model_data: Dictionary):
	"""Callback específico cuando se carga animación B - PATRÓN COORDINADOR"""
	print("🔄 DEBUG: Callback _on_animation_b_loaded recibido")
	
	loading_state.is_loading = false
	
	if model_data and model_data.get("type") == "animation":
		loading_state.animation_b_loaded = true
		animation_b_data = model_data.duplicate()
		animation_b_data["source_file"] = loaded_animation_b_path
		animation_b_data["file_path"] = loaded_animation_b_path
		animation_b_data["load_time"] = Time.get_unix_time_from_system()
		animation_b_data["type"] = "animation_b"
		
		emit_signal("animation_loaded", animation_b_data)
		emit_signal("loading_progress", "Animación B cargada", 1.0)
		print("✅ COLUMNA1: Animación B cargada exitosamente")
	else:
		print("❌ COLUMNA1: Error cargando animación B")
		emit_signal("loading_failed", "Error cargando animación B")
	
	_check_if_ready_for_transition()

# MANTENER CALLBACK GENÉRICO PARA COMPATIBILIDAD
func _on_base_model_loaded_generic(model_data: Dictionary):
	"""Callback genérico para modelo base (mantener compatibilidad)"""
	_on_base_model_loaded(model_data)

func _on_animation_loaded(animation_data: Dictionary):
	"""Manejar carga exitosa de animación - GENÉRICO PARA COMPATIBILIDAD"""
	print("🔄 Callback genérico _on_animation_loaded - redirigiendo...")
	
	# Este callback genérico ahora es menos importante
	# porque usamos callbacks específicos
	var anim_type = animation_data.get("type", "unknown")
	print("✅ Animación cargada (genérico): %s" % anim_type)

func _on_loading_failed(error_message: String):
	"""Manejar error de carga"""
	print("❌ Error de carga: %s" % error_message)
	
	loading_state.is_loading = false
	emit_signal("loading_failed", error_message)
	emit_signal("loading_progress", "Error: " + error_message, 0.0)

func _check_if_ready_for_transition():
	"""Verificar si todas las animaciones están listas para transición"""
	if loading_state.animation_a_loaded and loading_state.animation_b_loaded:
		print("🎯 Todas las animaciones cargadas, listo para transición")
		emit_signal("animations_ready", animation_a_data, animation_b_data)

func _on_model_loaded(model_data: Dictionary):
	"""Manejador general para modelos cargados"""
	print("📦 Modelo cargado: %s (%s)" % [model_data.get("name", "Unknown"), model_data.get("type", "Unknown")])
	
	# Redireccionar según el tipo
	var model_type = model_data.get("type", "")
	
	if model_type == "base":
		_on_base_model_loaded(model_data)
	elif model_type == "animation":
		_on_animation_loaded(model_data)
	else:
		print("⚠️ Tipo de modelo desconocido: %s" % model_type)

func _on_animation_combined(combined_model: Node3D, animation_name: String):
	"""Manejar modelo combinado desde AnimationManager"""
	print("🔗 Modelo combinado creado: %s" % animation_name)
	# Este manejador se puede usar para optimizaciones futuras

# ========================================================================
# MÉTODOS DE VALIDACIÓN
# ========================================================================

func _validate_file_path(file_path: String) -> bool:
	"""Validar que el archivo existe y es un FBX"""
	if not file_path or file_path.is_empty():
		print("❌ Ruta de archivo vacía")
		return false
	
	if not file_path.get_extension().to_lower() in ["fbx", "glb", "gltf"]:
		print("❌ Formato de archivo no soportado: %s" % file_path.get_extension())
		return false
	
	if not FileAccess.file_exists(file_path):
		print("❌ Archivo no existe: %s" % file_path)
		return false
	
	return true

func validate_compatibility() -> Dictionary:
	"""Validar compatibilidad entre modelo base y animaciones - VERSION ROBUSTA"""
	var validation_result = {
		"is_valid": false,
		"errors": [],
		"warnings": [],
		"info": []
	}
	
	if not loading_state.base_loaded:
		validation_result.errors.append("Modelo base no cargado")
		return validation_result
	
	if not (loading_state.animation_a_loaded and loading_state.animation_b_loaded):
		validation_result.errors.append("No todas las animaciones están cargadas")
		return validation_result
	
	# Verificar compatibilidad de esqueletos usando método robusto
	var skeleton_compatible = _validate_skeleton_compatibility_robust()
	if not skeleton_compatible:
		validation_result.errors.append("Los esqueletos de las animaciones no son compatibles")
		return validation_result
	
	# Si llega aquí, todo está bien
	validation_result.is_valid = true
	validation_result.info.append("Archivos cargados y compatibles")
	
	return validation_result

func _validate_skeleton_compatibility_robust() -> bool:
	"""Verificar compatibilidad de esqueletos de forma robusta"""
	
	if not base_data.has("skeleton") or not animation_a_data.has("skeleton") or not animation_b_data.has("skeleton"):
		print("❌ No se encontraron esqueletos en los datos")
		return false
	
	var base_skeleton = base_data.skeleton
	var anim_a_skeleton = animation_a_data.skeleton
	var anim_b_skeleton = animation_b_data.skeleton
	
	# Obtener número de huesos (considerando meshes en el base)
	var base_meshes_count = 0
	if fbx_loader and fbx_loader.has_method("_extract_meshes_simple"):
		base_meshes_count = fbx_loader._extract_meshes_simple(base_skeleton).size()
	
	var base_bone_count = base_skeleton.get_bone_count() - base_meshes_count
	var anim_a_bone_count = anim_a_skeleton.get_bone_count()
	var anim_b_bone_count = anim_b_skeleton.get_bone_count()
	
	# Verificar números de huesos
	if base_bone_count != anim_a_bone_count or base_bone_count != anim_b_bone_count:
		print("❌ Incompatibilidad: diferentes números de huesos")
		print("  Base: %d, Anim A: %d, Anim B: %d" % [base_bone_count, anim_a_bone_count, anim_b_bone_count])
		return false
	
	# Verificar nombres de huesos
	for i in range(base_bone_count):
		var base_bone_name = base_skeleton.get_bone_name(i)
		var anim_a_bone_name = anim_a_skeleton.get_bone_name(i)
		var anim_b_bone_name = anim_b_skeleton.get_bone_name(i)
		
		if base_bone_name != anim_a_bone_name or base_bone_name != anim_b_bone_name:
			print("❌ Incompatibilidad: nombres de huesos diferentes en índice %d" % i)
			print("  Base: %s, Anim A: %s, Anim B: %s" % [base_bone_name, anim_a_bone_name, anim_b_bone_name])
			return false
	
	print("✅ Esqueletos compatibles: %d huesos coincidentes" % base_bone_count)
	return true

# ========================================================================
# MÉTODOS FALLBACK PARA CARGA
# ========================================================================

func _fallback_load_base_model(file_path: String):
	"""Carga fallback del modelo base si no hay FBXLoader"""
	print("🔄 Usando carga fallback para modelo base")
	
	# Intentar cargar usando el sistema de recursos de Godot
	var scene = load(file_path) as PackedScene
	if scene:
		var instance = scene.instantiate()
		var model_data = {
			"model": instance,
			"file_path": file_path,
			"bones": _extract_bone_info(instance),
			"type": "base_model"
		}
		_on_base_model_loaded(model_data)
	else:
		_on_loading_failed("No se pudo cargar el modelo base: " + file_path)

func _fallback_load_animation(file_path: String, anim_type: String):
	"""Carga fallback de animación si no hay FBXLoader"""
	print("🔄 Usando carga fallback para animación: %s" % anim_type)
	
	var scene = load(file_path) as PackedScene
	if scene:
		var instance = scene.instantiate()
		var animation_data = {
			"model": instance,
			"file_path": file_path,
			"animations": _extract_animation_info(instance),
			"type": anim_type
		}
		_on_animation_loaded(animation_data)
	else:
		_on_loading_failed("No se pudo cargar la animación: " + file_path)

func _extract_bone_info(model: Node3D) -> Array:
	"""Extraer información de huesos del modelo"""
	var bones = []
	var skeleton = _find_skeleton_in_model(model)
	if skeleton:
		for i in range(skeleton.get_bone_count()):
			bones.append({
				"name": skeleton.get_bone_name(i),
				"parent": skeleton.get_bone_parent(i)
			})
	return bones

func _extract_animation_info(model: Node3D) -> Array:
	"""Extraer información de animaciones del modelo"""
	var animations = []
	var anim_player = _find_animation_player_in_model(model)
	if anim_player:
		var anim_lib = anim_player.get_animation_library("")
		if anim_lib:
			for anim_name in anim_lib.get_animation_list():
				animations.append({
					"name": anim_name,
					"length": anim_lib.get_animation(anim_name).length
				})
	return animations

func _find_skeleton_in_model(model: Node3D) -> Skeleton3D:
	"""Buscar Skeleton3D en el modelo recursivamente"""
	if model is Skeleton3D:
		return model
	
	# Búsqueda recursiva en todos los descendientes
	for child in model.get_children():
		if child is Skeleton3D:
			return child
		elif child is Node3D:
			var result = _find_skeleton_in_model(child)
			if result:
				return result
	
	return null

func _find_animation_player_in_model(model: Node3D) -> AnimationPlayer:
	"""Buscar AnimationPlayer en el modelo recursivamente"""
	# Buscar en hijos directos primero
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	
	# Búsqueda recursiva en todos los descendientes
	for child in model.get_children():
		var result = _find_animation_player_in_model(child)
		if result:
			return result
	
	return null

# ========================================================================
# API PÚBLICA PARA CONSULTA DE ESTADO
# ========================================================================

func get_loading_state() -> Dictionary:
	"""Obtener estado actual de carga"""
	return loading_state.duplicate()

func get_loaded_data() -> Dictionary:
	"""Obtener todos los datos cargados"""
	return {
		"base": base_data.duplicate(),
		"animation_a": animation_a_data.duplicate(),
		"animation_b": animation_b_data.duplicate()
	}

func is_ready_for_transition() -> bool:
	"""Verificar si está listo para generar transición"""
	return loading_state.base_loaded and loading_state.animation_a_loaded and loading_state.animation_b_loaded

func reset_loading_state():
	"""Resetear estado de carga"""
	print("🔄 Reseteando estado de carga...")
	
	loading_state = {
		"base_loaded": false,
		"animation_a_loaded": false,
		"animation_b_loaded": false,
		"is_loading": false
	}
	
	base_data.clear()
	animation_a_data.clear()
	animation_b_data.clear()
	
	loaded_base_path = ""
	loaded_animation_a_path = ""
	loaded_animation_b_path = ""
	
	print("✅ Estado de carga reseteado")

# ========================================================================
# API PÚBLICA ADICIONAL PARA TESTING Y DEBUG
# ========================================================================

func get_base_skeleton() -> Skeleton3D:
	"""Obtener esqueleto del modelo base"""
	if base_data.has("skeleton"):
		return base_data.skeleton
	return null

func get_animation_data_by_type(anim_type: String) -> Dictionary:
	"""Obtener datos de animación por tipo"""
	match anim_type:
		"animation_a":
			return animation_a_data
		"animation_b":
			return animation_b_data
		_:
			return {}

func create_combined_models_for_testing() -> Array:
	"""Crear modelos combinados para testing usando fbx_loader (útil para debug)"""
	if not is_ready_for_transition():
		print("❌ No está listo para crear modelos combinados")
		return []
	
	print("🧪 Creando modelos combinados para testing usando fbx_loader...")
	var combined_a = create_combined_model(base_data, animation_a_data)
	var combined_b = create_combined_model(base_data, animation_b_data)
	
	if combined_a and combined_b:
		print("✅ Ambos modelos combinados creados exitosamente")
	else:
		print("❌ Error creando uno o ambos modelos combinados")
	
	return [combined_a, combined_b]

func test_pose_extraction() -> Dictionary:
	"""Testing de extracción de poses usando fbx_loader"""
	print("🧪 === TESTING EXTRACCIÓN DE POSES CON FBX_LOADER ===")
	
	if not is_ready_for_transition():
		return {"error": "No hay datos suficientes para testing"}
	
	# Crear modelos combinados usando fbx_loader
	var combined_a = create_combined_model(base_data, animation_a_data)
	var combined_b = create_combined_model(base_data, animation_b_data)
	
	if not combined_a or not combined_b:
		return {"error": "No se pudieron crear modelos combinados con fbx_loader"}
	
	print("✅ Modelos combinados creados, extrayendo poses...")
	
	var pose_a_final = extract_final_pose(combined_a, animation_a_data.get("name", ""))
	var pose_b_initial = extract_initial_pose(combined_b, animation_b_data.get("name", ""))
	
	# Logging de resultados
	print("📊 Resultados de extracción:")
	print("  Pose A final: %d huesos" % pose_a_final.size())
	print("  Pose B inicial: %d huesos" % pose_b_initial.size())
	
	# Limpieza
	if combined_a: 
		combined_a.queue_free()
		print("🧹 Combined A limpiado")
	if combined_b: 
		combined_b.queue_free()
		print("🧹 Combined B limpiado")
	
	var success = not pose_a_final.is_empty() and not pose_b_initial.is_empty()
	print("✅ Test completado - Éxito: %s" % success)
	
	return {
		"pose_a_final": pose_a_final,
		"pose_b_initial": pose_b_initial,
		"poses_extracted": success,
		"pose_a_bone_count": pose_a_final.size(),
		"pose_b_bone_count": pose_b_initial.size()
	}

# ========================================================================
# DEBUG Y VERIFICACIÓN DE INICIALIZACIÓN
# ========================================================================

func debug_system_status():
	"""Debug del estado de inicialización de sistemas"""
	print("\n🔍 === ESTADO DE SISTEMAS COLUMNA1 ===")
	print("📚 FBXLoader: %s" % ("✅ OK" if fbx_loader else "❌ NULL"))
	if fbx_loader:
		print("  - Ruta: %s" % fbx_loader.get_path())
		print("  - Script: %s" % str(fbx_loader.get_script()))
	
	print("🎭 AnimationManager: %s" % ("✅ OK" if animation_manager else "❌ NULL"))
	if animation_manager:
		print("  - Ruta: %s" % animation_manager.get_path())
	
	print("✅ FBXValidator: %s" % ("✅ OK" if fbx_validator else "❌ NULL"))
	if fbx_validator:
		print("  - Ruta: %s" % fbx_validator.get_path())
	
	print("🦴 SkeletonInterpolator: %s" % ("✅ OK" if skeleton_interpolator else "❌ NULL"))
	if skeleton_interpolator:
		print("  - Ruta: %s" % skeleton_interpolator.get_path())
	
	print("📊 Estado de carga: %s" % str(loading_state))
	print("=====================================\n")

func verify_systems_initialization() -> bool:
	"""Verificar que todos los sistemas estén inicializados correctamente"""
	var all_systems_ok = (
		fbx_loader != null and
		animation_manager != null and
		fbx_validator != null and
		skeleton_interpolator != null
	)
	
	if not all_systems_ok:
		print("❌ No todos los sistemas están inicializados")
		debug_system_status()
	else:
		print("✅ Todos los sistemas inicializados correctamente")
	
	return all_systems_ok

# ========================================================================
# FUNCIONES DE DEBUG Y TESTING PARA RESOLVER PROBLEMA DE CARGA
# ========================================================================

func debug_loading_process():
	"""Debug completo del proceso de carga para identificar el problema"""
	print("\n🔍 === DEBUG PROCESO DE CARGA ===")
	
	print("1. Verificando FBXLoader:")
	if fbx_loader:
		print("  ✅ FBXLoader existe")
		print("  📍 Ruta: %s" % fbx_loader.get_path())
		print("  🔧 Script: %s" % str(fbx_loader.get_script()))
		print("  📡 Señales disponibles:")
		
		var signals = fbx_loader.get_signal_list()
		for sig in signals:
			print("    - %s" % sig.name)
			
		# Verificar métodos críticos
		print("  🛠️ Métodos disponibles:")
		print("    - load_base_model: %s" % ("✅" if fbx_loader.has_method("load_base_model") else "❌"))
		print("    - load_animation_fbx: %s" % ("✅" if fbx_loader.has_method("load_animation_fbx") else "❌"))
		print("    - combine_base_with_animation_for_transition: %s" % ("✅" if fbx_loader.has_method("combine_base_with_animation_for_transition") else "❌"))
	else:
		print("  ❌ FBXLoader NO EXISTE")
	
	print("\n2. Estado actual de carga:")
	print("  📊 loading_state: %s" % str(loading_state))
	print("  📂 Base cargada: %s (ruta: %s)" % (loading_state.base_loaded),( loaded_base_path))
	print("  🎭 Anim A cargada: %s (ruta: %s)" % (loading_state.animation_a_loaded),( loaded_animation_a_path))
	print("  🎭 Anim B cargada: %s (ruta: %s)" % (loading_state.animation_b_loaded),( loaded_animation_b_path))
	
	print("\n3. Conexiones de señales:")
	if fbx_loader and fbx_loader.has_signal("model_loaded"):
		var connections = fbx_loader.model_loaded.get_connections()
		print("  📡 model_loaded conectada a %d callbacks:" % connections.size())
		for conn in connections:
			print("    - %s::%s" % [conn["target"].name, conn["method"]])
	
	print("=====================================\n")

func test_animation_loading_flow():
	"""Test específico del flujo de carga de animaciones"""
	print("\n🧪 === TEST FLUJO DE CARGA DE ANIMACIONES ===")
	
	if not fbx_loader:
		print("❌ No se puede testear - FBXLoader no disponible")
		return
	
	# Test de conexión de señales
	print("1. Testeando conexión de señal model_loaded...")
	
	if fbx_loader.has_signal("model_loaded"):
		# Crear callback de test
		var test_callback = func(data): print("🔔 TEST: Callback recibido - tipo: %s" % data.get("type", "unknown"))
		
		fbx_loader.model_loaded.connect(test_callback, CONNECT_ONE_SHOT)
		print("  ✅ Callback de test conectado")
	else:
		print("  ❌ Señal model_loaded no existe")
	
	print("\n2. Estado antes de carga:")
	print("  - is_loading: %s" % loading_state.is_loading)
	
	print("\n3. Rutas configuradas:")
	print("  - base_path: %s" % loaded_base_path)
	print("  - anim_a_path: %s" % loaded_animation_a_path)
	print("  - anim_b_path: %s" % loaded_animation_b_path)
	
	print("=====================================\n")

func force_animation_loading_with_debug(file_path: String, anim_type: String):
	"""Forzar carga de animación con debug extensivo"""
	print("\n🚀 === CARGA FORZADA CON DEBUG: %s ===\n" % anim_type.to_upper())
	
	print("1. Pre-validaciones:")
	print("  📁 Archivo existe: %s" % ("✅" if FileAccess.file_exists(file_path) else "❌"))
	print("  🔧 FBXLoader disponible: %s" % ("✅" if fbx_loader else "❌"))
	print("  📡 Método load_animation_fbx: %s" % ("✅" if fbx_loader and fbx_loader.has_method("load_animation_fbx") else "❌"))
	
	if not fbx_loader or not fbx_loader.has_method("load_animation_fbx"):
		print("❌ No se puede continuar - requisitos no cumplidos")
		return
	
	print("\n2. Configurando callback específico...")
	var callback_connected = false
	
	match anim_type:
		"animation_a":
			if not fbx_loader.model_loaded.is_connected(_on_animation_a_loaded):
				fbx_loader.model_loaded.connect(_on_animation_a_loaded, CONNECT_ONE_SHOT)
				callback_connected = true
				print("  ✅ Callback _on_animation_a_loaded conectado")
		"animation_b":
			if not fbx_loader.model_loaded.is_connected(_on_animation_b_loaded):
				fbx_loader.model_loaded.connect(_on_animation_b_loaded, CONNECT_ONE_SHOT)
				callback_connected = true
				print("  ✅ Callback _on_animation_b_loaded conectado")
	
	if not callback_connected:
		print("  ⚠️ Callback ya estaba conectado o tipo inválido")
	
	print("\n3. Ejecutando carga...")
	loading_state.is_loading = true
	
	match anim_type:
		"animation_a":
			loaded_animation_a_path = file_path
		"animation_b":
			loaded_animation_b_path = file_path
	
	print("  🎭 Llamando fbx_loader.load_animation_fbx(%s)" % file_path)
	fbx_loader.load_animation_fbx(file_path)
	
	print("  ⏳ Carga iniciada - esperando callback...")
	print("=====================================\n")

# ========================================================================
# MÉTODOS AVANZADOS DE PROCESAMIENTO (del documento adjunto)
# ========================================================================

func create_combined_model(base_data: Dictionary, animation_data: Dictionary) -> Node3D:
	"""Crear modelo combinado usando fbx_loader.combine_base_with_animation_for_transition"""
	if not fbx_loader:
		print("❌ FBXLoader no disponible para combinación")
		return null
	
	print("🔧 Creando modelo combinado usando FBXLoader...")
	
	if fbx_loader.has_method("combine_base_with_animation_for_transition"):
		var combined = fbx_loader.combine_base_with_animation_for_transition(base_data, animation_data)
		print("✅ Modelo combinado creado con fbx_loader - AnimationPlayer:", combined.has_node("AnimationPlayer") if combined else false)
		
		if not combined or not is_instance_valid(combined):
			print("❌ Error en combinación base + animación usando fbx_loader")
			return null
		
		return combined
	else:
		print("❌ FBXLoader no tiene método combine_base_with_animation_for_transition")
		return null

func extract_final_pose(model: Node3D, animation_name: String) -> Dictionary:
	"""Extraer pose final de una animación"""
	var anim_player = model.get_node_or_null("AnimationPlayer")
	print("🎭 Extrayendo pose final - AnimationPlayer: ", anim_player)
	
	# Verificar existencia del AnimationPlayer y la animación
	if not anim_player or not anim_player.has_animation(animation_name):
		print("❌ AnimationPlayer o animación '%s' no encontrados" % animation_name)
		return {}
	
	var animation = anim_player.get_animation(animation_name)
	print("📊 Animación: ", animation)
	
	var final_time = animation.length
	print("⏰ Tiempo final: ", final_time)
	
	# Establecer pose al final de la animación
	anim_player.play(animation_name)
	anim_player.seek(final_time, true)
	anim_player.advance(0.0)
	
	if skeleton_interpolator and skeleton_interpolator.has_method("extract_skeleton_pose"):
		return skeleton_interpolator.extract_skeleton_pose(model)
	else:
		print("❌ SkeletonInterpolator no disponible")
		return {}

func extract_initial_pose(model: Node3D, animation_name: String) -> Dictionary:
	"""Extraer pose inicial de una animación"""
	var anim_player = model.get_node_or_null("AnimationPlayer")
	print("🎭 Extrayendo pose inicial - AnimationPlayer: ", anim_player)
	
	if not anim_player or not anim_player.has_animation(animation_name):
		print("❌ AnimationPlayer o animación '%s' no encontrados" % animation_name)
		return {}
	
	# Establecer pose al inicio de la animación
	anim_player.play(animation_name)
	anim_player.seek(0.0, true)
	anim_player.advance(0.0)
	
	if skeleton_interpolator and skeleton_interpolator.has_method("extract_skeleton_pose"):
		return skeleton_interpolator.extract_skeleton_pose(model)
	else:
		print("❌ SkeletonInterpolator no disponible")
		return {}
