# pixelize3d_fbx/scripts/transition/transition_interpolator.gd
# Interpolador de esqueletos para transiciones suaves entre animaciones
# Input: Poses de esqueleto inicial y final, configuración de transición
# Output: Frames intermedios con poses interpoladas

extends Node
class_name TransitionInterpolator

# Tipos de curvas de interpolación
enum InterpolationCurve {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	CUSTOM
}

# Configuración de interpolación
var interpolation_curves = {
	"linear": InterpolationCurve.LINEAR,
	"ease_in": InterpolationCurve.EASE_IN,
	"ease_out": InterpolationCurve.EASE_OUT,
	"ease_in_out": InterpolationCurve.EASE_IN_OUT,
	"custom": InterpolationCurve.CUSTOM
}

func _ready():
	print("🔄 TransitionInterpolator inicializado")

# ========================================================================
# API PÚBLICA
# ========================================================================

func extract_skeleton_pose(model: Node3D) -> Dictionary:
	"""Extraer pose actual del esqueleto de un modelo"""
	print("🦴 Extrayendo pose del esqueleto...")
	
	var skeleton = _find_skeleton(model)
	if not skeleton:
		print("❌ No se encontró esqueleto en el modelo")
		return {}
	
	var pose_data = {
		"skeleton_name": skeleton.name,
		"bone_count": skeleton.get_bone_count(),
		"bone_poses": {},
		"bone_hierarchy": {}
	}
	
	# Extraer poses de todos los bones
	for bone_idx in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(bone_idx)
		
		# Pose del bone (transform local)
		var bone_pose = skeleton.get_bone_pose(bone_idx)
		var bone_rest = skeleton.get_bone_rest(bone_idx)
		
		pose_data.bone_poses[bone_name] = {
			"index": bone_idx,
			"pose": bone_pose,
			"rest": bone_rest,
			"parent": skeleton.get_bone_parent(bone_idx)
		}
		
		# Jerarquía
		var parent_idx = skeleton.get_bone_parent(bone_idx)
		if parent_idx >= 0:
			var parent_name = skeleton.get_bone_name(parent_idx)
			pose_data.bone_hierarchy[bone_name] = parent_name
		else:
			pose_data.bone_hierarchy[bone_name] = null
	
	print("✅ Pose extraída: %d bones" % pose_data.bone_count)
	return pose_data

func generate_transition_frames(pose_a: Dictionary, pose_b: Dictionary, config: Dictionary) -> Array:
	"""Generar frames de transición entre dos poses"""
	print("🎬 Generando frames de transición...")
	
	if pose_a.is_empty() or pose_b.is_empty():
		print("❌ Poses vacías para interpolación")
		return []
	
	if pose_a.bone_count != pose_b.bone_count:
		print("❌ Número de bones diferentes: A=%d, B=%d" % [pose_a.bone_count, pose_b.bone_count])
		return []
	
	var transition_frames = []
	var frame_count = config.get("transition_frames", 24)
	var curve_type = config.get("interpolation_curve", "ease_in_out")
	
	print("📊 Configuración:")
	print("  Frames: %d" % frame_count)
	print("  Curva: %s" % curve_type)
	print("  Bones a interpolar: %d" % pose_a.bone_count)
	
	# Generar cada frame de la transición
	for frame_idx in range(frame_count):
		var t = float(frame_idx) / float(frame_count - 1) if frame_count > 1 else 0.0
		
		# Aplicar curva de interpolación
		var eased_t = _apply_interpolation_curve(t, curve_type)
		
		# Interpolar pose para este frame
		var interpolated_pose = _interpolate_poses(pose_a, pose_b, eased_t)
		
		transition_frames.append({
			"frame_index": frame_idx,
			"time_factor": t,
			"eased_factor": eased_t,
			"pose": interpolated_pose
		})
	
	print("✅ Generados %d frames de transición" % transition_frames.size())
	return transition_frames

func apply_transition_to_model(model: Node3D, transition_frames: Array) -> bool:
	"""Aplicar transición de frames a un modelo creando animación"""
	print("🎭 Aplicando transición al modelo...")
	
	var skeleton = _find_skeleton(model)
	if not skeleton:
		print("❌ No se encontró esqueleto en el modelo")
		return false
	
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if not anim_player:
		print("❌ No se encontró AnimationPlayer en el modelo")
		return false
	
	# Crear nueva animación con los frames de transición
	var transition_animation = Animation.new()
	var fps = 24.0
	var duration = float(transition_frames.size()) / fps
	
	transition_animation.length = duration
	transition_animation.loop_mode = Animation.LOOP_NONE
	
	print("📊 Creando animación:")
	print("  Duración: %.2fs" % duration)
	print("  Frames: %d" % transition_frames.size())
	
	# Crear tracks para cada bone
	var bone_count = skeleton.get_bone_count()
	var tracks_created = 0
	
	for bone_idx in range(bone_count):
		var bone_name = skeleton.get_bone_name(bone_idx)
		var bone_path = str(skeleton.get_path_to(skeleton)) + ":" + str(bone_name)
		
		# Track de posición
		var pos_track = transition_animation.add_track(Animation.TYPE_POSITION_3D)
		transition_animation.track_set_path(pos_track, bone_path)
		
		# Track de rotación
		var rot_track = transition_animation.add_track(Animation.TYPE_ROTATION_3D)
		transition_animation.track_set_path(rot_track, bone_path)
		
		# Track de escala
		var scale_track = transition_animation.add_track(Animation.TYPE_SCALE_3D)
		transition_animation.track_set_path(scale_track, bone_path)
		
		# Agregar keyframes para cada frame de transición
		for frame_data in transition_frames:
			var time = float(frame_data.frame_index) / fps
			var pose = frame_data.pose
			
			if pose.bone_poses.has(bone_name):
				var bone_transform = pose.bone_poses[bone_name].pose
				
				# Keyframes
				transition_animation.track_insert_key(pos_track, time, bone_transform.origin)
				transition_animation.track_insert_key(rot_track, time, bone_transform.basis.get_rotation_quaternion())
				transition_animation.track_insert_key(scale_track, time, bone_transform.basis.get_scale())
		
		tracks_created += 1
	
	# Añadir animación al AnimationPlayer
	var anim_lib = anim_player.get_animation_library("")
	if not anim_lib:
		anim_lib = AnimationLibrary.new()
		anim_player.add_animation_library("", anim_lib)
	
	anim_lib.add_animation("transition_animation", transition_animation)
	
	print("✅ Transición aplicada: %d tracks creados" % tracks_created)
	return true

# ========================================================================
# INTERPOLACIÓN DE POSES
# ========================================================================

func _interpolate_poses(pose_a: Dictionary, pose_b: Dictionary, t: float) -> Dictionary:
	"""Interpolar entre dos poses usando factor t (0.0 a 1.0)"""
	
	var interpolated_pose = {
		"skeleton_name": pose_a.skeleton_name,
		"bone_count": pose_a.bone_count,
		"bone_poses": {},
		"bone_hierarchy": pose_a.bone_hierarchy
	}
	
	# Interpolar cada bone
	for bone_name in pose_a.bone_poses.keys():
		if not pose_b.bone_poses.has(bone_name):
			print("⚠️ Bone %s no encontrado en pose B, usando pose A" % bone_name)
			interpolated_pose.bone_poses[bone_name] = pose_a.bone_poses[bone_name]
			continue
		
		var bone_a = pose_a.bone_poses[bone_name]
		var bone_b = pose_b.bone_poses[bone_name]
		
		# Interpolar transform del bone
		var transform_a = bone_a.pose
		var transform_b = bone_b.pose
		
		var interpolated_transform = _interpolate_transforms(transform_a, transform_b, t)
		
		interpolated_pose.bone_poses[bone_name] = {
			"index": bone_a.index,
			"pose": interpolated_transform,
			"rest": bone_a.rest,  # Rest pose no cambia
			"parent": bone_a.parent
		}
	
	return interpolated_pose

func _interpolate_transforms(transform_a: Transform3D, transform_b: Transform3D, t: float) -> Transform3D:
	"""Interpolar entre dos Transform3D"""
	
	# Interpolación de posición (lineal)
	var pos = transform_a.origin.lerp(transform_b.origin, t)
	
	# Interpolación de rotación (esférica)
	var rot_a = transform_a.basis.get_rotation_quaternion()
	var rot_b = transform_b.basis.get_rotation_quaternion()
	var rot = rot_a.slerp(rot_b, t)
	
	# Interpolación de escala (lineal)
	var scale_a = transform_a.basis.get_scale()
	var scale_b = transform_b.basis.get_scale()
	var scale = scale_a.lerp(scale_b, t)
	
	# Crear nuevo transform
	var result = Transform3D()
	result.origin = pos
	result.basis = Basis.from_scale(scale) * Basis(rot)
	
	return result

# ========================================================================
# CURVAS DE INTERPOLACIÓN
# ========================================================================

func _apply_interpolation_curve(t: float, curve_type: String) -> float:
	"""Aplicar curva de interpolación al factor t"""
	
	var curve = interpolation_curves.get(curve_type, InterpolationCurve.LINEAR)
	
	match curve:
		InterpolationCurve.LINEAR:
			return t
		
		InterpolationCurve.EASE_IN:
			return t * t
		
		InterpolationCurve.EASE_OUT:
			return 1.0 - pow(1.0 - t, 2.0)
		
		InterpolationCurve.EASE_IN_OUT:
			if t < 0.5:
				return 2.0 * t * t
			else:
				return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
		
		InterpolationCurve.CUSTOM:
			# Para curvas custom, se podría usar una curva de Bézier o similar
			return _custom_curve(t)
		
		_:
			return t

func _custom_curve(t: float) -> float:
	"""Curva personalizada - puede ser modificada según necesidades"""
	# Ejemplo: curva suave tipo S
	return t * t * (3.0 - 2.0 * t)

# ========================================================================
# UTILIDADES
# ========================================================================

func _find_skeleton(node: Node) -> Skeleton3D:
	"""Buscar Skeleton3D en el modelo recursivamente"""
	
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func validate_pose_compatibility(pose_a: Dictionary, pose_b: Dictionary) -> bool:
	"""Validar que dos poses son compatibles para interpolación"""
	
	if pose_a.is_empty() or pose_b.is_empty():
		return false
	
	if pose_a.bone_count != pose_b.bone_count:
		print("❌ Número de bones diferentes")
		return false
	
	# Verificar que tienen los mismos bones
	for bone_name in pose_a.bone_poses.keys():
		if not pose_b.bone_poses.has(bone_name):
			print("❌ Bone %s no encontrado en pose B" % bone_name)
			return false
	
	return true

func get_transition_preview(pose_a: Dictionary, pose_b: Dictionary, t: float) -> Dictionary:
	"""Obtener preview de interpolación para un factor t específico"""
	
	if not validate_pose_compatibility(pose_a, pose_b):
		return {}
	
	return _interpolate_poses(pose_a, pose_b, t)

# ========================================================================
# DEBUG Y UTILIDADES
# ========================================================================

func debug_pose_info(pose: Dictionary) -> void:
	"""Mostrar información de debug de una pose"""
	if pose.is_empty():
		print("❌ Pose vacía")
		return
	
	print("🦴 Debug Pose:")
	print("  Esqueleto: %s" % pose.get("skeleton_name", "Unknown"))
	print("  Bones: %d" % pose.get("bone_count", 0))
	
	for bone_name in pose.bone_poses.keys():
		var bone = pose.bone_poses[bone_name]
		var transform = bone.pose
		print("    %s: pos=(%s) rot=(%s)" % [
			bone_name,
			var_to_str(transform.origin),
			var_to_str(transform.basis.get_euler())
		])
