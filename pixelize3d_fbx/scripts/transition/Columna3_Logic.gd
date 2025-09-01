# pixelize3d_fbx/scripts/transition/Columna3_Logic.gd
# Lógica de configuración de transiciones entre esqueletos
# Input: Datos de esqueletos desde Columna1 y Columna2, configuración de UI
# Output: Configuración de transición procesada para Columna4

extends Node
class_name Columna3Logic

# === SEÑALES HACIA COORDINADOR ===
signal transition_config_changed(config: Dictionary)
signal generate_transition_requested()
signal skeleton_data_processed(skeleton_info: Dictionary)

# === SEÑALES HACIA UI ===
signal config_updated(config: Dictionary)
signal skeleton_info_ready(info: Dictionary)

# === CONFIGURACIÓN DE TRANSICIÓN ===
var transition_config: Dictionary = {
	"duration": 0.5,           # Duración en segundos (0.1 a 5.0)
	"frames": 10,              # Número de frames (10 a 120)
	"interpolation": "Linear", # Tipo de interpolación
	"valid": false             # Si la configuración es válida
}

# === DATOS DE ESQUELETOS ===
var skeleton_data: Dictionary = {
	"skeleton_pose_a": null,   # Pose del último frame de animación A
	"skeleton_pose_b": null,   # Pose del primer frame de animación B  
	"skeleton_a": null,        # Skeleton3D de referencia
	"skeleton_b": null,        # Skeleton3D de referencia
	"mesh_a": null,           # MeshInstance3D del modelo base
	"mesh_b": null,           # MeshInstance3D del modelo base (misma)
	"bones_count": 0,         # Número de bones compatibles
	"bones_info": []          # Información detallada de bones
}

# === TIPOS DE INTERPOLACIÓN DISPONIBLES ===
var interpolation_types: Array[String] = [
	"Linear",
	"Ease In", 
	"Ease Out",
	"Ease In-Out",
	"Smooth",
	"Cubic"
]

# === RANGOS DE CONFIGURACIÓN ===
const DURATION_MIN: float = 0.1
const DURATION_MAX: float = 5.0
const FRAMES_MIN: int = 10
const FRAMES_MAX: int = 120

func _ready():
	print("Columna3_Logic inicializando...")
	_reset_to_defaults()
	print("Columna3_Logic lista - Configuración de transiciones")

# ========================================================================
# API PÚBLICA - RECEPCIÓN DE DATOS
# ========================================================================

func load_skeleton_data(base_model_data: Dictionary, anim_a_data: Dictionary, anim_b_data: Dictionary):
	"""Cargar datos de esqueletos desde modelo base y animaciones"""
	print("Columna3_Logic: Cargando datos de esqueletos y mesh...")
	
	# Extraer mesh del modelo base (la misma para ambas animaciones)
	skeleton_data.mesh_a = _extract_mesh_from_base_model(base_model_data)
	skeleton_data.mesh_b = skeleton_data.mesh_a  # Misma mesh para ambas
	
	# Extraer poses específicas de los esqueletos
	skeleton_data.skeleton_pose_a = _extract_last_frame_pose(anim_a_data)
	skeleton_data.skeleton_pose_b = _extract_first_frame_pose(anim_b_data)
	
	print("DEBUG - Datos extraídos:")
	print("  Mesh base: %s" % ("OK" if skeleton_data.mesh_a else "NULL"))
	print("  Pose A (último frame): %s" % ("OK" if skeleton_data.skeleton_pose_a and not skeleton_data.skeleton_pose_a.is_empty() else "NULL"))
	print("  Pose B (primer frame): %s" % ("OK" if skeleton_data.skeleton_pose_b and not skeleton_data.skeleton_pose_b.is_empty() else "NULL"))
	
	# Validar y procesar esqueletos
	var is_valid = _validate_skeletons()
	if is_valid:
		_analyze_skeleton_compatibility()
		_emit_skeleton_info()
		transition_config.valid = true
		print("✅ Esqueletos cargados y validados para transición")
	else:
		transition_config.valid = false
		print("❌ Error en validación de esqueletos")
	
	# Emitir configuración actualizada
	emit_signal("config_updated", transition_config)
	emit_signal("transition_config_changed", transition_config)

# ========================================================================
# API PÚBLICA - CONFIGURACIÓN
# ========================================================================

func set_duration(duration: float):
	"""Establecer duración de la transición"""
	var clamped_duration = clamp(duration, DURATION_MIN, DURATION_MAX)
	transition_config.duration = clamped_duration
	
	print("Duración configurada: %.2fs" % clamped_duration)
	_emit_config_change()

func set_frames(frames: int):
	"""Establecer número de frames"""
	var clamped_frames = clamp(frames, FRAMES_MIN, FRAMES_MAX)
	transition_config.frames = clamped_frames
	
	print("Frames configurados: %d" % clamped_frames)
	_emit_config_change()

func set_interpolation(interpolation_type: String):
	"""Establecer tipo de interpolación"""
	if interpolation_type in interpolation_types:
		transition_config.interpolation = interpolation_type
		print("Interpolación configurada: %s" % interpolation_type)
		_emit_config_change()
	else:
		print("❌ Tipo de interpolación no válido: %s" % interpolation_type)

func reset_to_defaults():
	"""Resetear configuración a valores por defecto"""
	print("Reseteando configuración a valores por defecto...")
	_reset_to_defaults()
	_emit_config_change()

# ========================================================================
# API PÚBLICA - GENERACIÓN
# ========================================================================

func request_generate_transition():
	"""Solicitar generación de transición"""
	if not transition_config.valid:
		print("❌ No se puede generar: configuración no válida")
		return false
	
	print("🎬 Solicitando generación de transición...")
	print("  Duración: %.2fs" % transition_config.duration)
	print("  Frames: %d" % transition_config.frames) 
	print("  Interpolación: %s" % transition_config.interpolation)
	
	emit_signal("generate_transition_requested")
	return true

# ========================================================================
# GETTERS PÚBLICOS
# ========================================================================

func get_transition_config() -> Dictionary:
	"""Obtener configuración actual con información de poses"""
	var config = transition_config.duplicate()
	config["skeleton_ready"] = is_ready_for_transition()
	config["bones_count"] = skeleton_data.bones_count
	config["has_poses"] = (skeleton_data.skeleton_pose_a != null and 
						   skeleton_data.skeleton_pose_b != null and
						   not skeleton_data.skeleton_pose_a.is_empty() and 
						   not skeleton_data.skeleton_pose_b.is_empty())
	return config

func get_skeleton_info() -> Dictionary:
	"""Obtener información de esqueletos y poses"""
	return {
		"bones_count": skeleton_data.bones_count,
		"bones_info": skeleton_data.bones_info,
		"has_mesh": skeleton_data.mesh_a != null,
		"has_pose_a": skeleton_data.skeleton_pose_a != null and not skeleton_data.skeleton_pose_a.is_empty(),
		"has_pose_b": skeleton_data.skeleton_pose_b != null and not skeleton_data.skeleton_pose_b.is_empty(),
		"pose_a_info": skeleton_data.skeleton_pose_a.get("source", "none") if skeleton_data.skeleton_pose_a else "none",
		"pose_b_info": skeleton_data.skeleton_pose_b.get("source", "none") if skeleton_data.skeleton_pose_b else "none",
		"is_ready": is_ready_for_transition()
	}

func get_interpolation_types() -> Array[String]:
	"""Obtener tipos de interpolación disponibles"""
	return interpolation_types.duplicate()

func is_ready_for_transition() -> bool:
	"""Verificar si está listo para generar transición"""
	return (transition_config.valid and 
			skeleton_data.skeleton_pose_a != null and 
			skeleton_data.skeleton_pose_b != null and
			not skeleton_data.skeleton_pose_a.is_empty() and 
			not skeleton_data.skeleton_pose_b.is_empty() and
			skeleton_data.mesh_a != null)

# ========================================================================
# PROCESAMIENTO INTERNO DE ESQUELETOS Y POSES
# ========================================================================

func _extract_mesh_from_base_model(base_model_data: Dictionary) -> MeshInstance3D:
	"""Extraer MeshInstance3D del modelo base"""
	print("Extrayendo mesh del modelo base...")
	
	if not base_model_data.has("model_node"):
		print("❌ No se encontró model_node en base_model_data")
		return null
	
	var base_model = base_model_data.model_node
	if not base_model is Node3D:
		print("❌ model_node no es Node3D")
		return null
	
	# Buscar MeshInstance3D en el modelo base
	var mesh = _find_mesh_in_node(base_model)
	if mesh:
		print("✅ Mesh encontrado en modelo base: %s" % mesh.name)
		return mesh
	else:
		print("❌ No se encontró MeshInstance3D en modelo base")
		return null

func _extract_last_frame_pose(anim_data: Dictionary) -> Dictionary:
	"""Extraer pose del último frame de la animación"""
	print("Extrayendo último frame de animación A...")
	
	if not anim_data.has("model_node"):
		print("❌ No se encontró model_node en anim_data")
		return {}
	
	var model = anim_data.model_node
	var skeleton = _find_skeleton_in_node(model)
	var anim_player = _find_animation_player_in_node(model)
	
	if not skeleton or not anim_player:
		print("❌ No se encontró skeleton o AnimationPlayer")
		return {}
	
	# Obtener la animación
	var anim_list = anim_player.get_animation_list()
	if anim_list.is_empty():
		print("❌ No hay animaciones en el AnimationPlayer")
		return {}
	
	var anim_name = anim_list[0]  # Usar la primera animación
	var animation = anim_player.get_animation(anim_name)
	
	if not animation:
		print("❌ No se pudo obtener la animación: %s" % anim_name)
		return {}
	
	# Ir al último frame
	var last_time = animation.length
	anim_player.play(anim_name)
	anim_player.seek(last_time, true)
	
	# Extraer pose actual
	var pose = _extract_skeleton_current_pose(skeleton)
	pose["source"] = "last_frame_anim_a"
	pose["animation_name"] = anim_name
	pose["time"] = last_time
	
	# Guardar referencia al skeleton
	skeleton_data.skeleton_a = skeleton
	
	print("✅ Último frame extraído - %d bones" % pose.get("bone_count", 0))
	return pose

func _extract_first_frame_pose(anim_data: Dictionary) -> Dictionary:
	"""Extraer pose del primer frame de la animación"""
	print("Extrayendo primer frame de animación B...")
	
	if not anim_data.has("model_node"):
		print("❌ No se encontró model_node en anim_data")
		return {}
	
	var model = anim_data.model_node
	var skeleton = _find_skeleton_in_node(model)
	var anim_player = _find_animation_player_in_node(model)
	
	if not skeleton or not anim_player:
		print("❌ No se encontró skeleton o AnimationPlayer")
		return {}
	
	# Obtener la animación
	var anim_list = anim_player.get_animation_list()
	if anim_list.is_empty():
		print("❌ No hay animaciones en el AnimationPlayer")
		return {}
	
	var anim_name = anim_list[0]  # Usar la primera animación
	var animation = anim_player.get_animation(anim_name)
	
	if not animation:
		print("❌ No se pudo obtener la animación: %s" % anim_name)
		return {}
	
	# Ir al primer frame (tiempo 0)
	anim_player.play(anim_name)
	anim_player.seek(0.0, true)
	
	# Extraer pose actual
	var pose = _extract_skeleton_current_pose(skeleton)
	pose["source"] = "first_frame_anim_b"
	pose["animation_name"] = anim_name
	pose["time"] = 0.0
	
	# Guardar referencia al skeleton
	skeleton_data.skeleton_b = skeleton
	
	print("✅ Primer frame extraído - %d bones" % pose.get("bone_count", 0))
	return pose

func _extract_skeleton_current_pose(skeleton: Skeleton3D) -> Dictionary:
	"""Extraer la pose actual del esqueleto"""
	var pose_data = {
		"skeleton_name": skeleton.name,
		"bone_count": skeleton.get_bone_count(),
		"bone_poses": {},
		"bone_hierarchy": {}
	}
	
	# Extraer poses de todos los bones
	for bone_idx in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(bone_idx)
		
		# Pose actual del bone
		var bone_pose = skeleton.get_bone_pose(bone_idx)
		var bone_rest = skeleton.get_bone_rest(bone_idx)
		var bone_global = skeleton.get_bone_global_pose(bone_idx)
		
		pose_data.bone_poses[bone_name] = {
			"index": bone_idx,
			"local_pose": bone_pose,
			"rest_pose": bone_rest,
			"global_pose": bone_global,
			"parent_idx": skeleton.get_bone_parent(bone_idx)
		}
		
		# Jerarquía
		var parent_idx = skeleton.get_bone_parent(bone_idx)
		if parent_idx >= 0:
			var parent_name = skeleton.get_bone_name(parent_idx)
			pose_data.bone_hierarchy[bone_name] = parent_name
		else:
			pose_data.bone_hierarchy[bone_name] = null
	
	return pose_data

func _find_animation_player_in_node(node: Node) -> AnimationPlayer:
	"""Buscar recursivamente un AnimationPlayer en el árbol de nodos"""
	if node is AnimationPlayer:
		return node as AnimationPlayer
		
	for child in node.get_children():
		var anim_player = _find_animation_player_in_node(child)
		if anim_player:
			return anim_player
	
	return null

func _find_skeleton_in_node(node: Node) -> Skeleton3D:
	"""Buscar recursivamente un Skeleton3D en el árbol de nodos"""
	if node is Skeleton3D:
		return node as Skeleton3D
	
	for child in node.get_children():
		var skeleton = _find_skeleton_in_node(child)
		if skeleton:
			return skeleton
	
	return null

func _find_mesh_in_node(node: Node) -> MeshInstance3D:
	"""Buscar recursivamente un MeshInstance3D en el árbol de nodos"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
		
	for child in node.get_children():
		var mesh = _find_mesh_in_node(child)
		if mesh:
			return mesh
	
	return null

func _validate_skeletons() -> bool:
	"""Validar que las poses de esqueletos sean compatibles"""
	var pose_a = skeleton_data.skeleton_pose_a
	var pose_b = skeleton_data.skeleton_pose_b
	
	if not pose_a or not pose_b:
		print("❌ Una o ambas poses son null")
		return false
	
	if pose_a.is_empty() or pose_b.is_empty():
		print("❌ Una o ambas poses están vacías")
		return false
	
	var bones_a = pose_a.get("bone_count", 0)
	var bones_b = pose_b.get("bone_count", 0)
	
	if bones_a != bones_b:
		print("❌ Poses incompatibles: %d vs %d bones" % [bones_a, bones_b])
		return false
	
	if bones_a == 0:
		print("❌ Poses sin bones")
		return false
	
	# Verificar que los nombres de bones coincidan
	var bones_a_names = pose_a.bone_poses.keys()
	var bones_b_names = pose_b.bone_poses.keys()
	
	for bone_name in bones_a_names:
		if not bone_name in bones_b_names:
			print("❌ Bone '%s' no encontrado en pose B" % bone_name)
			return false
	
	print("✅ Poses compatibles: %d bones" % bones_a)
	return true

func _analyze_skeleton_compatibility():
	"""Analizar compatibilidad detallada de poses de esqueletos"""
	var pose_a = skeleton_data.skeleton_pose_a
	var bone_count = pose_a.get("bone_count", 0)
	
	skeleton_data.bones_count = bone_count
	skeleton_data.bones_info.clear()
	
	for bone_name in pose_a.bone_poses.keys():
		var bone_data_a = pose_a.bone_poses[bone_name]
		var bone_info = {
			"index": bone_data_a.index,
			"name": bone_name,
			"parent": bone_data_a.parent_idx,
			"has_pose_a": true,
			"has_pose_b": skeleton_data.skeleton_pose_b.bone_poses.has(bone_name)
		}
		skeleton_data.bones_info.append(bone_info)
	
	print("Análisis de poses completado: %d bones analizados" % bone_count)

# ========================================================================
# INTERPOLACIÓN DE BONES
# ========================================================================

func interpolate_bone_pose(bone_pose_a: Transform3D, bone_pose_b: Transform3D, t: float, interpolation_type: String) -> Transform3D:
	"""Interpolar entre dos poses de bone usando el tipo especificado"""
	var adjusted_t = _apply_interpolation_curve(t, interpolation_type)
	
	# Interpolar posición
	var position = bone_pose_a.origin.lerp(bone_pose_b.origin, adjusted_t)
	
	# Interpolar rotación (quaternion)
	var quat_a = Quaternion(bone_pose_a.basis)
	var quat_b = Quaternion(bone_pose_b.basis)
	var rotation = quat_a.slerp(quat_b, adjusted_t)
	
	# Interpolar escala
	var scale_a = bone_pose_a.basis.get_scale()
	var scale_b = bone_pose_b.basis.get_scale()
	var scale = scale_a.lerp(scale_b, adjusted_t)
	
	# Construir transform final
	var result = Transform3D()
	result.basis = Basis(rotation).scaled(scale)
	result.origin = position
	
	return result

func generate_transition_frames() -> Array:
	"""Generar frames de transición interpolados entre las poses"""
	if not transition_config.valid:
		print("❌ Configuración no válida para generar frames")
		return []
	
	var frames = []
	var pose_a = skeleton_data.skeleton_pose_a
	var pose_b = skeleton_data.skeleton_pose_b
	var frame_count = transition_config.frames
	
	print("Generando %d frames de transición..." % frame_count)
	
	for frame_idx in range(frame_count + 1):  # +1 para incluir frame final
		var t = float(frame_idx) / float(frame_count)
		var interpolated_pose = _interpolate_poses(pose_a, pose_b, t)
		
		frames.append({
			"frame_index": frame_idx,
			"time": t,
			"pose": interpolated_pose
		})
	
	print("✅ %d frames de transición generados" % frames.size())
	return frames

func _interpolate_poses(pose_a: Dictionary, pose_b: Dictionary, t: float) -> Dictionary:
	"""Interpolar entre dos poses usando factor t (0.0 a 1.0)"""
	var interpolated_pose = {
		"skeleton_name": pose_a.skeleton_name,
		"bone_count": pose_a.bone_count,
		"bone_poses": {},
		"bone_hierarchy": pose_a.bone_hierarchy,
		"interpolation_factor": t
	}
	
	# Interpolar cada bone
	for bone_name in pose_a.bone_poses.keys():
		if pose_b.bone_poses.has(bone_name):
			var bone_data_a = pose_a.bone_poses[bone_name]
			var bone_data_b = pose_b.bone_poses[bone_name]
			
			var pose_a_transform = bone_data_a.local_pose
			var pose_b_transform = bone_data_b.local_pose
			
			var interpolated_transform = interpolate_bone_pose(
				pose_a_transform, 
				pose_b_transform, 
				t, 
				transition_config.interpolation
			)
			
			interpolated_pose.bone_poses[bone_name] = {
				"index": bone_data_a.index,
				"local_pose": interpolated_transform,
				"parent_idx": bone_data_a.parent_idx
			}
	
	return interpolated_pose

func _apply_interpolation_curve(t: float, interpolation_type: String) -> float:
	"""Aplicar curva de interpolación al valor t"""
	match interpolation_type:
		"Linear":
			return t
		"Ease In":
			return t * t
		"Ease Out":
			return 1.0 - (1.0 - t) * (1.0 - t)
		"Ease In-Out":
			if t < 0.5:
				return 2.0 * t * t
			else:
				return 1.0 - 2.0 * (1.0 - t) * (1.0 - t)
		"Smooth":
			return t * t * (3.0 - 2.0 * t)  # smoothstep
		"Cubic":
			return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)  # smootherstep
		_:
			return t  # Fallback a linear

# ========================================================================
# UTILIDADES INTERNAS
# ========================================================================

func _reset_to_defaults():
	"""Resetear configuración a valores por defecto internamente"""
	transition_config.duration = 0.5
	transition_config.frames = 10
	transition_config.interpolation = "Linear"
	transition_config.valid = false

func _emit_config_change():
	"""Emitir señales de cambio de configuración"""
	emit_signal("config_updated", transition_config)
	emit_signal("transition_config_changed", transition_config)

func _emit_skeleton_info():
	"""Emitir información de esqueletos procesada"""
	var info = {
		"bones_count": skeleton_data.bones_count,
		"bones_info": skeleton_data.bones_info,
		"has_mesh_a": skeleton_data.mesh_a != null,
		"has_mesh_b": skeleton_data.mesh_b != null,
		"has_pose_a": skeleton_data.skeleton_pose_a != null and not skeleton_data.skeleton_pose_a.is_empty(),
		"has_pose_b": skeleton_data.skeleton_pose_b != null and not skeleton_data.skeleton_pose_b.is_empty(),
		"pose_a_source": skeleton_data.skeleton_pose_a.get("source", "unknown") if skeleton_data.skeleton_pose_a else "none",
		"pose_b_source": skeleton_data.skeleton_pose_b.get("source", "unknown") if skeleton_data.skeleton_pose_b else "none",
		"is_valid": transition_config.valid
	}
	
	emit_signal("skeleton_info_ready", info)
	emit_signal("skeleton_data_processed", info)
