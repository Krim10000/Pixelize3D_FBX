# pixelize3d_fbx/scripts/transition/transition_coordinator.gd
# Coordinador principal para el sistema de transiciones de animaciones
# Input: Base FBX + dos animaciones FBX, parámetros de transición
# Output: Sprite sheet de transición suave entre animaciones

extends Node
class_name TransitionCoordinator

# Señales
signal transition_started(anim_from: String, anim_to: String)
signal transition_progress(current_frame: int, total_frames: int, stage: String)
signal transition_complete(output_path: String)
signal transition_failed(error: String)
signal validation_complete(is_valid: bool, message: String)
signal resource_loaded(loaded_type: String, success: bool)

# Referencias a sistemas existentes
var fbx_loader: Node
var animation_manager: Node
var sprite_renderer: Node

# Configuración de transición
var transition_config: Dictionary = {
	"duration": 0.5,
	"transition_frames": 20,
	"interpolation_curve": "ease_in_out",
	"fps": 20,
	"output_path": "user://transitions/",
	"sprite_size": 128
}

# Datos de entrada
var base_data: Dictionary = {}
var animation_a_data: Dictionary = {}
var animation_b_data: Dictionary = {}

# Estado interno
var is_generating_transition: bool = false
var current_transition_model: Node3D
var loaded_resources: Dictionary = {}
var current_stage: String = ""

# Interpolador de esqueletos
var skeleton_interpolator: TransitionInterpolator

func _ready():
	print("📄 TransitionCoordinator inicializado")
	_initialize_components()

func _initialize_components():
	"""Inicializar componentes del sistema"""
	
	# Crear interpolador de esqueletos
	if not skeleton_interpolator:
		skeleton_interpolator = TransitionInterpolator.new()
		add_child(skeleton_interpolator)
	
	# Cargar e instanciar scripts existentes del sistema
	_load_system_scripts()
	
	print("✅ Componentes de transición inicializados")

func _load_system_scripts():
	"""Cargar e instanciar los scripts existentes del sistema"""
	print("📚 Cargando scripts existentes del sistema...")
	
	# Cargar FBXLoader
	var fbx_loader_script = load("res://scripts/core/fbx_loader.gd")
	if fbx_loader_script:
		fbx_loader = fbx_loader_script.new()
		fbx_loader.name = "FBXLoader"
		add_child(fbx_loader)
		
		# Conectar señales si es necesario
		if fbx_loader.has_signal("model_loaded"):
			if not fbx_loader.model_loaded.is_connected(_on_model_loaded):
				fbx_loader.model_loaded.connect(_on_model_loaded)
		
		print("✅ FBXLoader instanciado desde script existente")
	else:
		push_error("❌ No se pudo cargar scripts/core/fbx_loader.gd")
	
	# Cargar AnimationManager
	var animation_manager_script = load("res://scripts/core/animation_manager.gd")
	if animation_manager_script:
		animation_manager = animation_manager_script.new()
		animation_manager.name = "AnimationManager"
		add_child(animation_manager)
		
		print("✅ AnimationManager instanciado desde script existente")
	else:
		push_error("❌ No se pudo cargar scripts/core/animation_manager.gd")
	
	# Cargar SpriteRenderer
	var sprite_renderer_script = load("res://scripts/rendering/sprite_renderer.gd")
	if sprite_renderer_script:
		sprite_renderer = sprite_renderer_script.new()
		sprite_renderer.name = "SpriteRenderer"
		add_child(sprite_renderer)
		
		# Conectar señales de progreso
		if sprite_renderer.has_signal("rendering_progress"):
			if not sprite_renderer.rendering_progress.is_connected(_on_rendering_progress):
				sprite_renderer.rendering_progress.connect(_on_rendering_progress)
		
		if sprite_renderer.has_signal("animation_complete"):
			if not sprite_renderer.animation_complete.is_connected(_on_rendering_complete):
				sprite_renderer.animation_complete.connect(_on_rendering_complete)
		
		print("✅ SpriteRenderer instanciado desde script existente")
	else:
		push_error("❌ No se pudo cargar scripts/rendering/sprite_renderer.gd")
	
	# Verificar que tenemos todos los componentes
	var all_loaded = fbx_loader and animation_manager and sprite_renderer
	print("✅ Scripts cargados correctamente: %s" % ("SÍ" if all_loaded else "NO"))

# ========================================================================
# API PÚBLICA
# ========================================================================

func load_base_model(file_path: String) -> bool:
	"""Cargar modelo base usando el FBXLoader instanciado"""
	if not fbx_loader:
		_emit_error("FBXLoader no disponible")
		return false
	
	print("🏗️ Cargando modelo base: %s" % file_path.get_file())
	print("🔄 DEBUG: Iniciando carga en TransitionCoordinator")
	emit_signal("resource_loaded", "base", false)  # Iniciando carga
	
	# Conectar a la señal antes de cargar
	if not fbx_loader.model_loaded.is_connected(_on_base_model_loaded):
		fbx_loader.model_loaded.connect(_on_base_model_loaded, CONNECT_ONE_SHOT)
	
	fbx_loader.load_base_model(file_path)
	
	print("🔄 DEBUG: Carga iniciada, esperando callback...")
	return true

func _on_base_model_loaded(model_data: Dictionary):
	"""Callback cuando se carga un modelo base"""
	print("🔄 DEBUG: Callback _on_base_model_loaded recibido: %s" % str(model_data.keys() if model_data else "null"))
	
	if model_data and model_data.get("type") == "base":
		base_data = model_data
		emit_signal("resource_loaded", "base", true)
		print("✅ COORDINADOR: Modelo base cargado exitosamente")
	else:
		print("❌ COORDINADOR: Error - result type: %s" % model_data.get("type", "no_type"))
		_emit_error("Error cargando modelo base")
		emit_signal("resource_loaded", "base", false)

func load_animation_a(file_path: String) -> bool:
	"""Cargar animación A usando el FBXLoader instanciado"""
	if not fbx_loader:
		_emit_error("FBXLoader no disponible")
		return false
	
	print("🎭 Cargando animación A: %s" % file_path.get_file())
	print("🔄 DEBUG: Iniciando carga animación A en TransitionCoordinator")
	emit_signal("resource_loaded", "animation_a", false)
	
	# Conectar a la señal antes de cargar
	if not fbx_loader.model_loaded.is_connected(_on_animation_a_loaded):
		fbx_loader.model_loaded.connect(_on_animation_a_loaded, CONNECT_ONE_SHOT)
	
	fbx_loader.load_animation_fbx(file_path)
	return true

func _on_animation_a_loaded(model_data: Dictionary):
	"""Callback cuando se carga animación A"""
	print("🔄 DEBUG: Callback _on_animation_a_loaded recibido")
	
	if model_data and model_data.get("type") == "animation":
		animation_a_data = model_data
		animation_a_data["source_file"] = model_data.get("file_path", "")
		emit_signal("resource_loaded", "animation_a", true)
		print("✅ COORDINADOR: Animación A cargada exitosamente")
	else:
		_emit_error("Error cargando animación A")

func load_animation_b(file_path: String) -> bool:
	"""Cargar animación B usando el FBXLoader instanciado"""
	if not fbx_loader:
		_emit_error("FBXLoader no disponible")
		return false
	
	print("🎭 Cargando animación B: %s" % file_path.get_file())
	print("🔄 DEBUG: Iniciando carga animación B en TransitionCoordinator")
	emit_signal("resource_loaded", "animation_b", false)
	
	# Conectar a la señal antes de cargar
	if not fbx_loader.model_loaded.is_connected(_on_animation_b_loaded):
		fbx_loader.model_loaded.connect(_on_animation_b_loaded, CONNECT_ONE_SHOT)
	
	fbx_loader.load_animation_fbx(file_path)
	return true

func _on_animation_b_loaded(model_data: Dictionary):
	"""Callback cuando se carga animación B"""
	print("🔄 DEBUG: Callback _on_animation_b_loaded recibido")
	
	if model_data and model_data.get("type") == "animation":
		animation_b_data = model_data
		animation_b_data["source_file"] = model_data.get("file_path", "")
		emit_signal("resource_loaded", "animation_b", true)
		print("✅ COORDINADOR: Animación B cargada exitosamente")
	else:
		_emit_error("Error cargando animación B")

func validate_transition_data() -> bool:
	"""Validar que los datos están listos para generar transición"""
	print("🔍 Validando datos para transición...")
	
	if base_data.is_empty():
		_emit_validation_result(false, "Modelo base no cargado")
		return false
	
	if animation_a_data.is_empty():
		_emit_validation_result(false, "Animación A no cargada")
		return false
		
	if animation_b_data.is_empty():
		_emit_validation_result(false, "Animación B no cargada")
		return false
	
	# Verificar compatibilidad de esqueletos
	var skeleton_compatible = _validate_skeleton_compatibility()
	if not skeleton_compatible:
		_emit_validation_result(false, "Los esqueletos de las animaciones no son compatibles")
		return false
	
	_emit_validation_result(true, "Datos válidos para transición")
	return true

func update_transition_config(new_config: Dictionary):
	"""Actualizar configuración de la transición"""
	transition_config.merge(new_config, true)
	print("⚙️ Configuración actualizada: %s" % str(transition_config))

func generate_transition() -> bool:
	"""Generar la transición y sprite sheet"""
	print("\n🎬 === GENERANDO TRANSICIÓN ===")
	
	if is_generating_transition:
		_emit_error("Ya hay una transición en proceso")
		return false
	
	if not validate_transition_data():
		return false
	
	is_generating_transition = true
	emit_signal("transition_started", 
		animation_a_data.get("name", "AnimA"), 
		animation_b_data.get("name", "AnimB")
	)
	
	# Proceso de generación
	var success = false
	current_stage = "preparing"
	emit_signal("transition_progress", 0, 100, current_stage)
	
	success = await _execute_transition_generation()
	
	is_generating_transition = false
	
	if success:
		var output_name = "transition_%s_to_%s" % [
			animation_a_data.get("name", "animA"),
			animation_b_data.get("name", "animB")
		]
		emit_signal("transition_complete", output_name)
		print("✅ Transición completada: %s" % output_name)
	else:
		emit_signal("transition_failed", "Error durante la generación")
		print("❌ Error en generación de transición")
	
	return success

# ========================================================================
# PROCESAMIENTO INTERNO
# ========================================================================

func _execute_transition_generation() -> bool:
	"""Ejecutar el proceso completo de generación"""
	
	current_stage = "combining_models"
	emit_signal("transition_progress", 10, 100, current_stage)
	
	# 1. Combinar base con ambas animaciones
	var combined_a = await _create_combined_model(base_data, animation_a_data)
	var combined_b = await _create_combined_model(base_data, animation_b_data)
	
	print("=== VERIFICACIÓN DE MODELOS COMBINADOS ===")
	print("Combined A tiene AnimationPlayer:", combined_a.has_node("AnimationPlayer"))
	print("Combined B tiene AnimationPlayer:", combined_b.has_node("AnimationPlayer"))
	
	if not combined_a or not combined_b:
		_emit_error("Error creando modelos combinados")
		return false
	
	current_stage = "extracting_poses"
	emit_signal("transition_progress", 30, 100, current_stage)
	
	
	var pose_b_initial = _extract_initial_pose(combined_b, animation_b_data.get("name", ""))
	#print("pose_b_initial") funciona
	#print(pose_b_initial) funciona
	
	
	var pose_a_final = _extract_final_pose(combined_a, animation_a_data.get("name", ""))
	print("pose_a_final")
	print(pose_a_final) #error
	
	
	if pose_a_final.is_empty() or pose_b_initial.is_empty():
		_emit_error("Error extrayendo poses de transición")
		return false
	
	current_stage = "interpolating"
	emit_signal("transition_progress", 50, 100, current_stage)
	
	# 3. Generar frames de transición
	var transition_frames = skeleton_interpolator.generate_transition_frames(
		pose_a_final, 
		pose_b_initial, 
		transition_config
	)
	
	if transition_frames.is_empty():
		_emit_error("Error generando frames de transición")
		return false
	
	current_stage = "rendering"
	emit_signal("transition_progress", 70, 100, current_stage)
	
	# 4. Crear modelo con transición completa y renderizar
	var success = await _render_transition_animation(transition_frames)
	
	# Limpieza
	if combined_a and is_instance_valid(combined_a):
		combined_a.queue_free()
	if combined_b and is_instance_valid(combined_b):
		combined_b.queue_free()
	
	return success

func _create_combined_model(base: Dictionary, animation: Dictionary) -> Node3D:
	"""Crear modelo combinado usando el AnimationManager instanciado"""
	if not animation_manager:
		_emit_error("AnimationManager no disponible")
		return null
	
	if animation_manager.has_method("combine_base_with_animation"):
		var combined = animation_manager.combine_base_with_animation_for_transition(base, animation)
		print("                                       func _create_combined_model")
		print("OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO Combined  tiene AnimationPlayer:", combined.has_node("AnimationPlayer"))
		
		if not combined or not is_instance_valid(combined):
			_emit_error("Error en combinación base + animación")
			print("============================= ERROR ")
			print("Error en combinación base + animación")			
			return null
		
		
		print("============================= EXITO ")
		return combined
	else:
		_emit_error("AnimationManager no tiene método combine_base_with_animation")
		
		print("============================= ERROR ")
		print("AnimationManager no tiene método combine_base_with_animation")
		return null
#func _extract_final_pose(model: Node3D, animation_name: String) -> Dictionary:
	#"""Extraer pose final de una animación"""
	#var anim_player_2 = model.get_node_or_null("AnimationPlayer")
	#print("anim_player")
	#print(anim_player_2)
	##if not anim_player or not anim_player.has_animation(animation_name):
	##
		##print("_extract_final_pose return {}")
		##return {}
	#print( animation_a_data.get("name", ""))
	#var animation = anim_player_2.get_animation( animation_a_data.get("name", ""))
	#
	#print("animation")
	#print(animation)
	#var final_time = animation.length
	#print("final_time")
	#print(final_time)
	## Establecer pose al final de la animación
	#anim_player_2.play(animation_name)
	#anim_player_2.seek(final_time, true)
	#anim_player_2.advance(0.0)
	#
	#return skeleton_interpolator.extract_skeleton_pose(model)

func _extract_final_pose(model: Node3D, animation_name: String) -> Dictionary:
	"""Extraer pose final de una animación"""
	var anim_player = model.get_node_or_null("AnimationPlayer")
	print("anim_player: ", anim_player)
	
	# Verificar existencia del AnimationPlayer y la animación (CRUCIAL)
	if not anim_player or not anim_player.has_animation(animation_name):
		print("_extract_final_pose: AnimationPlayer o animación no encontrados")
		return {}
	
	# Usar el parámetro animation_name en lugar de animation_a_data
	var animation = anim_player.get_animation(animation_name)
	print("animation: ", animation)
	
	var final_time = animation.length
	print("final_time: ", final_time)
	
	# Establecer pose al final de la animación
	anim_player.play(animation_name)
	anim_player.seek(final_time, true)
	anim_player.advance(0.0)
	
	return skeleton_interpolator.extract_skeleton_pose(model)

func _extract_initial_pose(model: Node3D, animation_name: String) -> Dictionary:
	"""Extraer pose inicial de una animación"""
	var anim_player = model.get_node_or_null("AnimationPlayer")
	print("var anim_player = model.get_node_or_null(AnimationPlayer)")
	print(anim_player)
	if not anim_player or not anim_player.has_animation(animation_name):
		print("_extract_initial_pose, return {}")
		return {}
	
	# Establecer pose al inicio de la animación
	anim_player.play(animation_name)
	anim_player.seek(0.0, true)
	anim_player.advance(0.0)
	
	return skeleton_interpolator.extract_skeleton_pose(model)

func _render_transition_animation(transition_frames: Array) -> bool:
	"""Renderizar animación de transición usando el SpriteRenderer instanciado"""
	
	if not sprite_renderer:
		_emit_error("SpriteRenderer no disponible")
		return false
	
	# Crear modelo temporal con la animación de transición
	var transition_model = await _create_transition_model(transition_frames)
	
	if not transition_model:
		print("transition_model")
		print(transition_model)
		_emit_error("Error creando modelo de transición")
		return false
	
	# Configurar y ejecutar renderizado
	if sprite_renderer.has_method("initialize"):
		sprite_renderer.initialize(transition_config)
	
	if sprite_renderer.has_method("render_animation"):
		sprite_renderer.render_animation(
			transition_model, 
			"transition",
			0.0,
			transition_config.transition_frames
		)
	
	# Esperar a que termine el renderizado
	await sprite_renderer.animation_complete
	
	# Limpieza
	if transition_model and is_instance_valid(transition_model):
		transition_model.queue_free()
	
	return true

func _create_transition_model(transition_frames: Array) -> Node3D:
	"""Crear modelo temporal con animación de transición"""
	# Esta función debería crear un modelo 3D con una animación 
	# que reproduzca los frames de transición interpolados
	
	# Por ahora, usar el modelo base como placeholder
	if base_data.has("model") and base_data.model:
		var model = base_data.model.duplicate()
		
		# Aquí se implementaría la aplicación de los frames de transición
		# al esqueleto del modelo
		
		return model
	
	return null

# ========================================================================
# VALIDACIONES
# ========================================================================

func _validate_skeleton_compatibility() -> bool:
	"""Verificar que los esqueletos de las animaciones sean compatibles"""
	
	if not base_data.has("skeleton") or not animation_a_data.has("skeleton") or not animation_b_data.has("skeleton"):
		return false
	
	
	var base_skeleton = base_data.skeleton
	var base_meshes= fbx_loader._extract_meshes_simple(base_skeleton).size()
	print("var base_meshes= fbx_loader._extract_meshes_simple(base_skeleton)")
	print(base_meshes)
	var anim_a_skeleton = animation_a_data.skeleton
	var anim_b_skeleton = animation_b_data.skeleton
	
	
	
	# Verificar que tienen el mismo número de huesos
	var base_bone_count = (base_skeleton.get_bone_count())  - (base_meshes)
	var anim_a_bone_count = anim_a_skeleton.get_bone_count()
	var anim_b_bone_count = anim_b_skeleton.get_bone_count()
	
	if base_bone_count != anim_a_bone_count or base_bone_count != anim_b_bone_count:
		print("❌ Incompatibilidad: diferentes números de huesos")
		print("  Base: %d, Anim A: %d, Anim B: %d" % [base_bone_count, anim_a_bone_count, anim_b_bone_count])
		return false
	
	# Verificar que los nombres de huesos coinciden
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
# MANEJADORES DE SEÑALES
# ========================================================================

func _on_model_loaded(model_data: Dictionary):
	"""Manejar carga de modelo desde FBXLoader"""
	print("📦 Modelo cargado: %s (%s)" % [model_data.get("name", "Unknown"), model_data.get("type", "Unknown")])

func _on_rendering_progress(current: int, total: int):
	"""Manejar progreso de renderizado"""
	var progress = int((float(current) / float(total)) * 30) + 70  # 70-100% del progreso total
	emit_signal("transition_progress", progress, 100, "rendering")

func _on_rendering_complete(animation_name: String):
	"""Manejar finalización de renderizado"""
	print("✅ Renderizado completado: %s" % animation_name)
	emit_signal("transition_progress", 100, 100, "complete")

# ========================================================================
# UTILIDADES
# ========================================================================

func _emit_validation_result(is_valid: bool, message: String):
	"""Emitir resultado de validación"""
	emit_signal("validation_complete", is_valid, message)

func _emit_error(error_message: String):
	"""Emitir error y logging"""
	print("❌ TransitionCoordinator Error: %s" % error_message)
	emit_signal("transition_failed", error_message)
