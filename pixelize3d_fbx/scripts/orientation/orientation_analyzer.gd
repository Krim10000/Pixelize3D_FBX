# scripts/orientation/orientation_analyzer.gd
# Sistema de Auto-Detección de Orientación Geométrica
# Input: Modelo 3D cargado
# Output: Análisis de orientación con sugerencias inteligentes

extends Node

signal analysis_complete(result: Dictionary)
signal analysis_failed(error: String)

# Configuración del análisis
var analysis_config = {
	"face_detection_enabled": true,
	"symmetry_analysis_enabled": true,
	"bone_analysis_enabled": true,
	"geometric_analysis_enabled": true,
	"confidence_threshold": 0.6
}

# Cache de análisis
var analysis_cache: Dictionary = {}
var max_cache_size: int = 20

func analyze_model_orientation(model: Node3D) -> Dictionary:
	"""Analizar orientación del modelo y sugerir norte geométrico"""
	print("🔍 Analizando orientación del modelo: %s" % model.name)
	
	# Verificar cache
	var model_hash = _calculate_model_hash(model)
	if model_hash in analysis_cache:
		print("📋 Usando análisis cacheado")
		return analysis_cache[model_hash]
	
	# Realizar análisis completo
	var analysis_result = _perform_comprehensive_analysis(model)
	
	# Cachear resultado
	_cache_analysis_result(model_hash, analysis_result)
	
	emit_signal("analysis_complete", analysis_result)
	return analysis_result

func _perform_comprehensive_analysis(model: Node3D) -> Dictionary:
	"""Realizar análisis comprehensive del modelo"""
	var analysis = {
		"model_name": model.name,
		"timestamp": Time.get_unix_time_from_system(),
		"suggested_north": 0.0,
		"confidence": 0.0,
		"reasoning": "Análisis geométrico automático",
		"alternative_orientations": [],
		"analysis_details": {},
		"bounds": AABB(),
		"center": Vector3.ZERO
	}
	
	print("📊 Iniciando análisis comprehensive...")
	
	# 1. Análisis de geometría básica
	var geometric_analysis = _analyze_basic_geometry(model)
	analysis.analysis_details["geometry"] = geometric_analysis
	analysis.bounds = geometric_analysis.bounds
	analysis.center = geometric_analysis.center
	
	# 2. Análisis de simetría
	if analysis_config.symmetry_analysis_enabled:
		var symmetry_analysis = _analyze_symmetry(model)
		analysis.analysis_details["symmetry"] = symmetry_analysis
	
	# 3. Análisis de huesos (si tiene skeleton)
	if analysis_config.bone_analysis_enabled:
		var bone_analysis = _analyze_bone_structure(model)
		analysis.analysis_details["bones"] = bone_analysis
	
	# 4. Detección de cara/frente
	if analysis_config.face_detection_enabled:
		var face_analysis = _detect_front_face(model)
		analysis.analysis_details["face"] = face_analysis
	
	# 5. Calcular orientación sugerida
	var orientation_result = _calculate_suggested_orientation(analysis.analysis_details)
	analysis.suggested_north = orientation_result.angle
	analysis.confidence = orientation_result.confidence
	analysis.reasoning = orientation_result.reasoning
	analysis.alternative_orientations = orientation_result.alternatives
	
	print("✅ Análisis completado: %.1f° (confianza: %.1f%%)" % [analysis.suggested_north, analysis.confidence * 100])
	
	return analysis

# ========================================================================
# ANÁLISIS GEOMÉTRICO BÁSICO
# ========================================================================

func _analyze_basic_geometry(model: Node3D) -> Dictionary:
	"""Analizar geometría básica del modelo"""
	print("📐 Analizando geometría básica...")
	
	var geometry = {
		"bounds": AABB(),
		"center": Vector3.ZERO,
		"size": Vector3.ZERO,
		"aspect_ratios": {},
		"mesh_count": 0,
		"vertices_count": 0,
		"dominant_axis": "Y"
	}
	
	# Calcular bounds combinados
	var combined_bounds = _calculate_detailed_bounds(model)
	geometry.bounds = combined_bounds
	geometry.center = combined_bounds.get_center()
	geometry.size = combined_bounds.size
	
	# Calcular ratios de aspecto
	geometry.aspect_ratios = {
		"width_height": geometry.size.x / max(geometry.size.y, 0.001),
		"width_depth": geometry.size.x / max(geometry.size.z, 0.001),
		"height_depth": geometry.size.y / max(geometry.size.z, 0.001)
	}
	
	# Determinar eje dominante
	if geometry.size.y > geometry.size.x and geometry.size.y > geometry.size.z:
		geometry.dominant_axis = "Y"  # Modelo vertical
	elif geometry.size.x > geometry.size.z:
		geometry.dominant_axis = "X"  # Modelo ancho
	else:
		geometry.dominant_axis = "Z"  # Modelo profundo
	
	# Contar meshes y vértices
	var mesh_info = _count_mesh_data(model)
	geometry.mesh_count = mesh_info.mesh_count
	geometry.vertices_count = mesh_info.vertices_count
	
	print("  Bounds: %s" % str(combined_bounds))
	print("  Tamaño: %s" % str(geometry.size))
	print("  Eje dominante: %s" % geometry.dominant_axis)
	
	return geometry

#func _calculate_detailed_bounds(model: Node3D) -> AABB:
	#"""Calcular bounds detallados del modelo"""
	#var combined_aabb = AABB()
	#var first = true
	#
	#var mesh_instances = _find_all_mesh_instances(model)
	#
	#for mesh_inst in mesh_instances:
		#if mesh_inst.mesh:
			#var mesh_aabb = mesh_inst.mesh.get_aabb()
			#var global_aabb = mesh_inst.global_transform * mesh_aabb
			#
			#if first:
				#combined_aabb = global_aabb
				#first = false
			#else:
				#combined_aabb = combined_aabb.merge(global_aabb)
	#
	#return combined_aabb
# orientation_analyzer.gd

func _calculate_detailed_bounds(model: Node3D) -> AABB:
	"""Calcular bounds detallados del modelo - Versión robusta"""
	var combined_aabb = AABB()
	var mesh_instances = _find_all_mesh_instances(model)
	
	if mesh_instances.is_empty():
		push_warning("⚠️ No se encontraron mallas en el modelo")
		return AABB(Vector3.ZERO, Vector3.ZERO)
	
	for mesh_inst in mesh_instances:
		if not mesh_inst.mesh:
			continue
			
		var mesh_aabb = mesh_inst.mesh.get_aabb()
		if mesh_aabb.size == Vector3.ZERO:
			continue
			
		var transform = _get_node_transform_relative_to(mesh_inst, model)
		var transformed_aabb = transform * mesh_aabb
		
		if combined_aabb.size == Vector3.ZERO:
			combined_aabb = transformed_aabb
		else:
			combined_aabb = combined_aabb.merge(transformed_aabb)
	
	return combined_aabb

func _get_node_transform_relative_to(node: Node3D, root: Node3D) -> Transform3D:
	"""Obtener transformación relativa incluso si no está en el árbol"""
	var transform = Transform3D()
	var current = node
	
	# Recorrer hacia arriba hasta llegar al nodo raíz
	while current != null and current != root:
		transform = current.transform * transform
		current = current.get_parent()
		
		# Si llegamos a la raíz de la escena sin encontrar el root
		if current == null:
			push_warning("⚠️ El nodo no está bajo el root especificado")
			break
	
	return transform


func _count_mesh_data(model: Node3D) -> Dictionary:
	"""Contar información de meshes"""
	var info = {
		"mesh_count": 0,
		"vertices_count": 0
	}
	
	var mesh_instances = _find_all_mesh_instances(model)
	info.mesh_count = mesh_instances.size()
	
	for mesh_inst in mesh_instances:
		if mesh_inst.mesh:
			# Intentar obtener conteo de vértices
			var arrays = mesh_inst.mesh.surface_get_arrays(0)
			if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX]:
				info.vertices_count += arrays[Mesh.ARRAY_VERTEX].size()
	
	return info

# ========================================================================
# ANÁLISIS DE SIMETRÍA
# ========================================================================

func _analyze_symmetry(model: Node3D) -> Dictionary:
	"""Analizar simetría del modelo"""
	print("🔄 Analizando simetría...")
	
	var symmetry = {
		"x_axis_symmetry": 0.0,
		"z_axis_symmetry": 0.0,
		"rotational_symmetry": 0.0,
		"primary_symmetry_axis": "none",
		"symmetry_center": Vector3.ZERO
	}
	
	var mesh_instances = _find_all_mesh_instances(model)
	if mesh_instances.is_empty():
		return symmetry
	
	# Analizar simetría en X (izquierda-derecha)
	symmetry.x_axis_symmetry = _calculate_axis_symmetry(mesh_instances, Vector3.RIGHT)
	
	# Analizar simetría en Z (adelante-atrás) 
	symmetry.z_axis_symmetry = _calculate_axis_symmetry(mesh_instances, Vector3.FORWARD)
	
	# Determinar eje principal de simetría
	if symmetry.x_axis_symmetry > symmetry.z_axis_symmetry and symmetry.x_axis_symmetry > 0.7:
		symmetry.primary_symmetry_axis = "X"
	elif symmetry.z_axis_symmetry > 0.7:
		symmetry.primary_symmetry_axis = "Z"
	
	print("  Simetría X: %.2f" % symmetry.x_axis_symmetry)
	print("  Simetría Z: %.2f" % symmetry.z_axis_symmetry)
	print("  Eje principal: %s" % symmetry.primary_symmetry_axis)
	
	return symmetry

func _calculate_axis_symmetry(mesh_instances: Array, axis: Vector3) -> float:
	"""Calcular simetría respecto a un eje"""
	var symmetry_score = 0.0
	var total_samples = 0
	
	for mesh_inst in mesh_instances:
		if not mesh_inst.mesh:
			continue
		
		var bounds = mesh_inst.mesh.get_aabb()
		var center = bounds.get_center()
		
		# Samplear puntos y verificar simetría
		var samples = _sample_mesh_points(mesh_inst, 10)
		for point in samples:
			var mirrored_point = point
			
			if axis == Vector3.RIGHT:
				mirrored_point.x = center.x - (point.x - center.x)
			elif axis == Vector3.FORWARD:
				mirrored_point.z = center.z - (point.z - center.z)
			
			# Verificar si existe punto simétrico
			var has_symmetric = _point_exists_in_mesh(mesh_inst, mirrored_point, 0.1)
			if has_symmetric:
				symmetry_score += 1.0
			
			total_samples += 1
	
	return symmetry_score / max(total_samples, 1)

func _sample_mesh_points(mesh_instance: MeshInstance3D, sample_count: int) -> Array:
	"""Samplear puntos de un mesh para análisis"""
	var points = []
	
	if not mesh_instance.mesh:
		return points
	
	var arrays = mesh_instance.mesh.surface_get_arrays(0)
	if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX]:
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		var step = max(1, vertices.size() / sample_count)
		
		for i in range(0, vertices.size(), step):
			if i < vertices.size():
				points.append(vertices[i])
	
	return points

func _point_exists_in_mesh(mesh_instance: MeshInstance3D, target_point: Vector3, tolerance: float) -> bool:
	"""Verificar si un punto existe en el mesh (aproximadamente)"""
	if not mesh_instance.mesh:
		return false
	
	var arrays = mesh_instance.mesh.surface_get_arrays(0)
	if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX]:
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		
		for vertex in vertices:
			if vertex.distance_to(target_point) < tolerance:
				return true
	
	return false

# ========================================================================
# ANÁLISIS DE ESTRUCTURA ÓSEA
# ========================================================================

func _analyze_bone_structure(model: Node3D) -> Dictionary:
	"""Analizar estructura de huesos para determinar orientación"""
	print("🦴 Analizando estructura ósea...")
	
	var bone_analysis = {
		"has_skeleton": false,
		"bone_count": 0,
		"hip_bone": null,
		"spine_bones": [],
		"head_bone": null,
		"suggested_forward": Vector3.ZERO,
		"confidence": 0.0
	}
	
	var skeleton = _find_skeleton(model)
	if not skeleton:
		print("  No se encontró Skeleton3D")
		return bone_analysis
	
	bone_analysis.has_skeleton = true
	bone_analysis.bone_count = skeleton.get_bone_count()
	
	# Buscar huesos importantes
	_identify_key_bones(skeleton, bone_analysis)
	
	# Calcular dirección sugerida basada en huesos
	if bone_analysis.hip_bone and bone_analysis.spine_bones.size() > 0:
		bone_analysis.suggested_forward = _calculate_forward_from_bones(skeleton, bone_analysis)
		bone_analysis.confidence = 0.8
	
	print("  Huesos encontrados: %d" % bone_analysis.bone_count)
	print("  Hip bone: %s" % str(bone_analysis.hip_bone))
	print("  Spine bones: %d" % bone_analysis.spine_bones.size())
	
	return bone_analysis

func _find_skeleton(model: Node3D) -> Skeleton3D:
	"""Buscar Skeleton3D en el modelo"""
	if model is Skeleton3D:
		return model
	
	for child in model.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func _identify_key_bones(skeleton: Skeleton3D, analysis: Dictionary):
	"""Identificar huesos clave del skeleton"""
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i).to_lower()
		
		# Buscar hueso de cadera/pelvis
		if "hip" in bone_name or "pelvis" in bone_name or "root" in bone_name:
			analysis.hip_bone = i
		
		# Buscar huesos de columna
		if "spine" in bone_name or "back" in bone_name:
			analysis.spine_bones.append(i)
		
		# Buscar hueso de cabeza
		if "head" in bone_name or "skull" in bone_name:
			analysis.head_bone = i

func _calculate_forward_from_bones(skeleton: Skeleton3D, analysis: Dictionary) -> Vector3:
	"""Calcular dirección forward basada en estructura ósea"""
	if not analysis.hip_bone or analysis.spine_bones.is_empty():
		return Vector3.FORWARD
	
	# Usar dirección de cadera a primera vértebra como referencia
	var hip_transform = skeleton.get_bone_global_pose(analysis.hip_bone)
	var spine_transform = skeleton.get_bone_global_pose(analysis.spine_bones[0])
	
	var spine_direction = (spine_transform.origin - hip_transform.origin).normalized()
	
	# El "forward" típicamente es perpendicular a la columna
	var forward = Vector3.FORWARD
	if abs(spine_direction.y) > 0.8:  # Columna vertical
		forward = hip_transform.basis.z.normalized()
	
	return forward

# ========================================================================
# DETECCIÓN DE CARA/FRENTE
# ========================================================================

func _detect_front_face(model: Node3D) -> Dictionary:
	"""Detectar la cara/frente del modelo"""
	print("👁️ Detectando cara/frente...")
	
	var face_analysis = {
		"has_face_geometry": false,
		"detected_front": Vector3.FORWARD,
		"confidence": 0.0,
		"face_center": Vector3.ZERO,
		"eye_positions": []
	}
	
	# Buscar geometría de cara por nombres de mesh
	var face_meshes = _find_face_meshes(model)
	if face_meshes.size() > 0:
		face_analysis.has_face_geometry = true
		face_analysis.face_center = _calculate_face_center(face_meshes)
		face_analysis.detected_front = _calculate_face_direction(face_meshes)
		face_analysis.confidence = 0.7
	
	# Buscar ojos específicamente
	var eye_meshes = _find_eye_meshes(model)
	if eye_meshes.size() >= 2:
		face_analysis.eye_positions = _get_eye_positions(eye_meshes)
		face_analysis.detected_front = _calculate_forward_from_eyes(face_analysis.eye_positions)
		face_analysis.confidence = 0.9
	
	print("  Cara detectada: %s" % face_analysis.has_face_geometry)
	print("  Ojos encontrados: %d" % face_analysis.eye_positions.size())
	print("  Dirección frontal: %s" % str(face_analysis.detected_front))
	
	return face_analysis

func _find_face_meshes(model: Node3D) -> Array:
	"""Buscar meshes que podrían ser cara"""
	var face_meshes = []
	var mesh_instances = _find_all_mesh_instances(model)
	
	for mesh_inst in mesh_instances:
		var mesh_name = mesh_inst.name.to_lower()
		if ("face" in mesh_name or "head" in mesh_name or 
			"eye" in mesh_name or "mouth" in mesh_name or 
			"nose" in mesh_name):
			face_meshes.append(mesh_inst)
	
	return face_meshes

func _find_eye_meshes(model: Node3D) -> Array:
	"""Buscar meshes específicos de ojos"""
	var eye_meshes = []
	var mesh_instances = _find_all_mesh_instances(model)
	
	for mesh_inst in mesh_instances:
		var mesh_name = mesh_inst.name.to_lower()
		if "eye" in mesh_name:
			eye_meshes.append(mesh_inst)
	
	return eye_meshes

func _calculate_face_center(face_meshes: Array) -> Vector3:
	"""Calcular centro de la cara"""
	var total_center = Vector3.ZERO
	
	for mesh_inst in face_meshes:
		if mesh_inst.mesh:
			var bounds = mesh_inst.mesh.get_aabb()
			total_center += bounds.get_center()
	
	return total_center / max(face_meshes.size(), 1)

func _calculate_face_direction(face_meshes: Array) -> Vector3:
	"""Calcular dirección frontal de la cara"""
	# Simplificado: asumir que la cara mira hacia +Z
	return Vector3.FORWARD

func _get_eye_positions(eye_meshes: Array) -> Array:
	"""Obtener posiciones de los ojos"""
	var positions = []
	
	for mesh_inst in eye_meshes:
		if mesh_inst.mesh:
			var bounds = mesh_inst.mesh.get_aabb()
			positions.append(bounds.get_center())
	
	return positions

func _calculate_forward_from_eyes(eye_positions: Array) -> Vector3:
	"""Calcular dirección forward basada en posición de ojos"""
	if eye_positions.size() < 2:
		return Vector3.FORWARD
	
	# Vector entre ojos para determinar orientación
	var eye_vector = (eye_positions[1] - eye_positions[0]).normalized()
	
	# El forward es perpendicular al vector entre ojos
	var forward = Vector3.FORWARD
	if abs(eye_vector.x) > 0.8:  # Ojos están en X
		forward = Vector3.FORWARD
	elif abs(eye_vector.z) > 0.8:  # Ojos están en Z
		forward = Vector3.RIGHT
	
	return forward

# ========================================================================
# CÁLCULO DE ORIENTACIÓN SUGERIDA
# ========================================================================

func _calculate_suggested_orientation(analysis_details: Dictionary) -> Dictionary:
	"""Calcular orientación sugerida basada en todos los análisis"""
	print("🧮 Calculando orientación sugerida...")
	
	var result = {
		"angle": 0.0,
		"confidence": 0.0,
		"reasoning": "Análisis geométrico automático",
		"alternatives": []
	}
	
	var weighted_suggestions = []
	
	# Sugerencia basada en simetría
	if analysis_details.has("symmetry"):
		var symmetry = analysis_details.symmetry
		if symmetry.primary_symmetry_axis == "X":
			weighted_suggestions.append({"angle": 0.0, "weight": 0.3, "source": "simetría X"})
		elif symmetry.primary_symmetry_axis == "Z":
			weighted_suggestions.append({"angle": 90.0, "weight": 0.3, "source": "simetría Z"})
	
	# Sugerencia basada en huesos
	if analysis_details.has("bones") and analysis_details.bones.confidence > 0.5:
		var bone_forward = analysis_details.bones.suggested_forward
		var bone_angle = _vector_to_angle(bone_forward)
		weighted_suggestions.append({
			"angle": bone_angle, 
			"weight": 0.5, 
			"source": "estructura ósea"
		})
	
	# Sugerencia basada en cara
	if analysis_details.has("face") and analysis_details.face.confidence > 0.5:
		var face_forward = analysis_details.face.detected_front
		var face_angle = _vector_to_angle(face_forward)
		weighted_suggestions.append({
			"angle": face_angle, 
			"weight": 0.6, 
			"source": "detección facial"
		})
	
	# Sugerencia basada en geometría (fallback)
	if analysis_details.has("geometry"):
		var geometry = analysis_details.geometry
		var geometric_angle = _suggest_angle_from_geometry(geometry)
		weighted_suggestions.append({
			"angle": geometric_angle, 
			"weight": 0.2, 
			"source": "análisis geométrico"
		})
	
	# Calcular ángulo ponderado
	if weighted_suggestions.size() > 0:
		result = _calculate_weighted_angle(weighted_suggestions)
	
	# Generar alternativas (orientaciones cardinales)
	result.alternatives = [
		{"angle": 0.0, "label": "Norte (0°)"},
		{"angle": 90.0, "label": "Este (90°)"},
		{"angle": 180.0, "label": "Sur (180°)"},
		{"angle": 270.0, "label": "Oeste (270°)"}
	]
	
	print("  Ángulo sugerido: %.1f°" % result.angle)
	print("  Confianza: %.1f%%" % (result.confidence * 100))
	print("  Razón: %s" % result.reasoning)
	
	return result

func _vector_to_angle(vector: Vector3) -> float:
	"""Convertir vector direccional a ángulo en grados"""
	return rad_to_deg(atan2(vector.x, vector.z))

func _suggest_angle_from_geometry(geometry: Dictionary) -> float:
	"""Sugerir ángulo basado en geometría"""
	# Si el modelo es más ancho que profundo, sugerir orientación lateral
	if geometry.aspect_ratios.width_depth > 1.5:
		return 90.0
	
	# Si es más profundo que ancho, sugerir orientación frontal
	if geometry.aspect_ratios.width_depth < 0.7:
		return 0.0
	
	# Para modelos cuadrados, mantener orientación por defecto
	return 0.0

func _calculate_weighted_angle(suggestions: Array) -> Dictionary:
	"""Calcular ángulo ponderado de múltiples sugerencias"""
	var total_weight = 0.0
	var weighted_sum = 0.0
	var reasoning_parts = []
	
	for suggestion in suggestions:
		total_weight += suggestion.weight
		weighted_sum += suggestion.angle * suggestion.weight
		reasoning_parts.append(suggestion.source)
	
	var final_angle = weighted_sum / max(total_weight, 0.001)
	var confidence = min(total_weight / 1.0, 1.0)  # Normalizar a 0-1
	
	# Redondear a múltiplo de 45° para orientaciones más naturales
	final_angle = round(final_angle / 45.0) * 45.0
	
	# Asegurar que esté en rango 0-359
	while final_angle < 0:
		final_angle += 360.0
	while final_angle >= 360:
		final_angle -= 360.0
	
	return {
		"angle": final_angle,
		"confidence": confidence,
		"reasoning": "Basado en: " + ", ".join(reasoning_parts)
	}

# ========================================================================
# UTILIDADES Y CACHE
# ========================================================================

func _find_all_mesh_instances(node: Node) -> Array:
	"""Buscar todas las instancias de mesh"""
	var meshes = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_all_mesh_instances(child))
	
	return meshes

func _calculate_model_hash(model: Node3D) -> String:
	"""Calcular hash único del modelo para cache"""
	var hash_data = model.name + str(model.get_child_count())
	
	# Agregar información de meshes para hash más específico
	var mesh_instances = _find_all_mesh_instances(model)
	for mesh_inst in mesh_instances:
		hash_data += mesh_inst.name
		if mesh_inst.mesh:
			hash_data += str(mesh_inst.mesh.get_rid())
	
	return hash_data.sha256_text().substr(0, 16)

func _cache_analysis_result(model_hash: String, result: Dictionary):
	"""Cachear resultado de análisis"""
	analysis_cache[model_hash] = result
	
	# Limpiar cache si excede tamaño máximo
	if analysis_cache.size() > max_cache_size:
		var oldest_key = analysis_cache.keys()[0]
		analysis_cache.erase(oldest_key)

func clear_cache():
	"""Limpiar cache de análisis"""
	analysis_cache.clear()
	print("🧹 Cache de análisis limpiado")

func get_cache_info() -> Dictionary:
	"""Obtener información del cache"""
	return {
		"cache_size": analysis_cache.size(),
		"max_cache_size": max_cache_size,
		"cached_models": analysis_cache.keys()
	}

# ========================================================================
# API PÚBLICA PARA TESTING
# ========================================================================

func analyze_model_quick(model: Node3D) -> float:
	"""Análisis rápido que solo retorna ángulo sugerido"""
	var full_analysis = analyze_model_orientation(model)
	return full_analysis.suggested_north

func set_analysis_config(config: Dictionary):
	"""Configurar parámetros de análisis"""
	analysis_config.merge(config, true)
	print("🔧 Configuración de análisis actualizada")

func get_analysis_config() -> Dictionary:
	"""Obtener configuración actual"""
	return analysis_config.duplicate(true)
