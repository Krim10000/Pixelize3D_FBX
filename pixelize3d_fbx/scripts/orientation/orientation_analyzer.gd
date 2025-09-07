# scripts/orientation/orientation_analyzer.gd
# VERSIÓN CON DEBUG COMPLETO PARA IDENTIFICAR ERRORES
# Input: Modelo 3D cargado
# Output: Análisis de orientación con logging detallado para debug

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
	"""Analizar orientación del modelo y sugerir norte geométrico - CON DEBUG COMPLETO"""
	print("\n🔍 === ANÁLISIS DE ORIENTACIÓN - DEBUG COMPLETO ===")
	print("🔍 Analizando orientación del modelo: %s" % model.name)
	print("🔍 Modelo type: %s" % model.get_class())
	print("🔍 Modelo children count: %d" % model.get_child_count())
	
	# Verificar cache CON DEBUG
	var model_hash = _calculate_model_hash(model)
	print("🔍 Model hash calculado: %s" % model_hash)
	print("🔍 Cache size actual: %d" % analysis_cache.size())
#	print("🔍 Cache keys: %s" % analysis_cache.keys())
	
	if model_hash in analysis_cache:
		print("📋 Usando análisis cacheado")
		var cached_result = analysis_cache[model_hash]
		print("🔍 DEBUG CACHE: suggested_north = %.1f°" % cached_result.get("suggested_north", -999))
		print("🔍 DEBUG CACHE: confidence = %.2f" % cached_result.get("confidence", -1))
		print("🔍 DEBUG CACHE: reasoning = %s" % cached_result.get("reasoning", "NO ENCONTRADO"))
		
		emit_signal("analysis_complete", cached_result)
		return cached_result
	
	print("🔍 Cache miss - realizando análisis nuevo")
	
	# Realizar análisis completo CON DEBUG
	var analysis_result = _perform_comprehensive_analysis_debug(model)
	
	# Cachear resultado CON DEBUG
	print("🔍 Cacheando resultado...")
	_cache_analysis_result(model_hash, analysis_result)
	print("🔍 Cache size después: %d" % analysis_cache.size())
	
	print("🔍 === EMITIENDO SEÑAL analysis_complete ===")
	print("🔍 Signal recipients count: %d" % get_signal_connection_list("analysis_complete").size())
#	for connection in get_signal_connection_list("analysis_complete"):
#		print("🔍 Connected to: %s.%s" % [connection.target.name, connection.method.get_method()])
	
	emit_signal("analysis_complete", analysis_result)
	
	print("🔍 === FIN ANÁLISIS DE ORIENTACIÓN ===\n")
	return analysis_result

func _perform_comprehensive_analysis_debug(model: Node3D) -> Dictionary:
	"""Realizar análisis comprehensive del modelo - CON DEBUG DETALLADO"""
	print("\n📊 === ANÁLISIS COMPREHENSIVE - DEBUG ===")
	
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
	print("📊 Estructura inicial de analysis:")
	for key in analysis.keys():
		print("  %s: %s" % [key, str(analysis[key])])
	
	# 1. Análisis de geometría básica CON DEBUG
	print("\n📐 === PASO 1: ANÁLISIS GEOMÉTRICO ===")
	var geometric_analysis = _analyze_basic_geometry_debug(model)
	analysis.analysis_details["geometry"] = geometric_analysis
	analysis.bounds = geometric_analysis.bounds
	analysis.center = geometric_analysis.center
	print("📐 Resultado geometría agregado a analysis_details")
	
	# 2. Análisis de simetría CON DEBUG
	if analysis_config.symmetry_analysis_enabled:
		print("\n🔄 === PASO 2: ANÁLISIS DE SIMETRÍA ===")
		print("🔄 symmetry_analysis_enabled = true")
		var symmetry_analysis = _analyze_symmetry_debug(model)
		analysis.analysis_details["symmetry"] = symmetry_analysis
		print("🔄 Resultado simetría agregado a analysis_details")
	else:
		print("\n🔄 === PASO 2: SIMETRÍA DESHABILITADA ===")
	
	# 3. Análisis de huesos CON DEBUG
	if analysis_config.bone_analysis_enabled:
		print("\n🦴 === PASO 3: ANÁLISIS DE HUESOS ===")
		print("🦴 bone_analysis_enabled = true")
		var bone_analysis = _analyze_bone_structure_debug(model)
		analysis.analysis_details["bones"] = bone_analysis
		print("🦴 Resultado huesos agregado a analysis_details")
	else:
		print("\n🦴 === PASO 3: HUESOS DESHABILITADO ===")
	
	# 4. Detección de cara CON DEBUG
	if analysis_config.face_detection_enabled:
		print("\n👤 === PASO 4: DETECCIÓN DE CARA ===")
		print("👤 face_detection_enabled = true")
		var face_analysis = _detect_front_face_debug(model)
		analysis.analysis_details["face"] = face_analysis
		print("👤 Resultado cara agregado a analysis_details")
	else:
		print("\n👤 === PASO 4: CARA DESHABILITADA ===")
	
	# 5. Calcular orientación sugerida CON DEBUG CRÍTICO
	print("\n🧮 === PASO 5: CÁLCULO DE ORIENTACIÓN - CRÍTICO ===")
	print("🧮 analysis_details antes del cálculo:")
	for key in analysis.analysis_details.keys():
		print("  %s: %s" % [key, str(analysis.analysis_details[key])])
	
	var orientation_result = _calculate_suggested_orientation_debug(analysis.analysis_details)
	
	print("🧮 orientation_result recibido:")
	for key in orientation_result.keys():
		print("  %s: %s" % [key, str(orientation_result[key])])
	
	# ACTUALIZACIÓN CRÍTICA
	print("🧮 === ACTUALIZANDO ANALYSIS CON RESULTADO ===")
	print("🧮 ANTES: analysis.suggested_north = %.1f°" % analysis.suggested_north)
	analysis.suggested_north = orientation_result.angle
	print("🧮 DESPUÉS: analysis.suggested_north = %.1f°" % analysis.suggested_north)
	
	analysis.confidence = orientation_result.confidence
	analysis.reasoning = orientation_result.reasoning
	analysis.alternative_orientations = orientation_result.alternatives
	
	print("✅ Análisis completado: %.1f° (confianza: %.1f%%)" % [analysis.suggested_north, analysis.confidence * 100])
	
	print("📊 === ESTRUCTURA FINAL DE ANALYSIS ===")
	for key in analysis.keys():
		if key != "analysis_details":  # Skip nested structure
			print("  %s: %s" % [key, str(analysis[key])])
	
	return analysis

func _analyze_basic_geometry_debug(model: Node3D) -> Dictionary:
	"""Analizar geometría básica del modelo - CON DEBUG"""
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
	
	print("📐 Combined bounds: %s" % str(combined_bounds))
	print("📐 Center: %s" % str(geometry.center))
	print("📐 Size: %s" % str(geometry.size))
	
	# Calcular ratios de aspecto
	geometry.aspect_ratios = {
		"width_height": geometry.size.x / max(geometry.size.y, 0.001),
		"width_depth": geometry.size.x / max(geometry.size.z, 0.001),
		"height_depth": geometry.size.y / max(geometry.size.z, 0.001)
	}
	
	print("📐 Aspect ratios: %s" % str(geometry.aspect_ratios))
	
	# Determinar eje dominante
	if geometry.size.y > geometry.size.x and geometry.size.y > geometry.size.z:
		geometry.dominant_axis = "Y"  # Modelo vertical
	elif geometry.size.x > geometry.size.z:
		geometry.dominant_axis = "X"  # Modelo ancho
	else:
		geometry.dominant_axis = "Z"  # Modelo profundo
	
	print("📐 Eje dominante: %s" % geometry.dominant_axis)
	
	# Contar meshes y vértices
	var mesh_info = _count_mesh_data(model)
	geometry.mesh_count = mesh_info.mesh_count
	geometry.vertices_count = mesh_info.vertices_count
	
	print("📐 Mesh count: %d" % geometry.mesh_count)
	print("📐 Vertices count: %d" % geometry.vertices_count)
	
	return geometry

func _analyze_symmetry_debug(model: Node3D) -> Dictionary:
	"""Analizar simetría del modelo - CON DEBUG"""
	print("🔄 Analizando simetría...")
	
	var symmetry = {
		"x_axis_symmetry": 0.0,
		"z_axis_symmetry": 0.0,
		"rotational_symmetry": 0.0,
		"primary_symmetry_axis": "none",
		"symmetry_center": Vector3.ZERO,
		"confidence": 0.0
	}
	
	# Placeholder - en una implementación real aquí iría análisis de simetría
	print("🔄 NOTA: Análisis de simetría es placeholder")
	print("🔄 Devolviendo valores por defecto")
	
	for key in symmetry.keys():
		print("🔄 %s: %s" % [key, str(symmetry[key])])
	
	return symmetry

func _analyze_bone_structure_debug(model: Node3D) -> Dictionary:
	"""Analizar estructura de huesos - CON DEBUG"""
	print("🦴 Analizando estructura de huesos...")
	
	var bones = {
		"has_skeleton": false,
		"skeleton_count": 0,
		"bone_count": 0,
		"suggested_forward": Vector3.FORWARD,
		"confidence": 0.0,
		"reasoning": "No skeleton encontrado"
	}
	
	# Buscar Skeleton3D nodes
	var skeletons = _find_all_skeletons(model)
	bones.skeleton_count = skeletons.size()
	bones.has_skeleton = skeletons.size() > 0
	
	print("🦴 Skeletons encontrados: %d" % bones.skeleton_count)
	
	if bones.has_skeleton:
		var skeleton = skeletons[0]
		bones.bone_count = skeleton.get_bone_count()
		print("🦴 Bone count en primer skeleton: %d" % bones.bone_count)
		
		if bones.bone_count > 0:
			bones.confidence = 0.3  # Confidence básica
			bones.reasoning = "Skeleton encontrado con %d huesos" % bones.bone_count
		else:
			bones.reasoning = "Skeleton sin huesos"
	else:
		print("🦴 No se encontraron Skeleton3D nodes")
	
	for key in bones.keys():
		print("🦴 %s: %s" % [key, str(bones[key])])
	
	return bones

func _detect_front_face_debug(model: Node3D) -> Dictionary:
	"""Detectar cara/frente del modelo - CON DEBUG"""
	print("👤 Detectando cara/frente...")
	
	var face = {
		"has_face": false,
		"face_center": Vector3.ZERO,
		"detected_front": Vector3.FORWARD,
		"confidence": 0.0,
		"reasoning": "No se detectó cara"
	}
	
	# Buscar meshes que podrían ser cara
	var face_meshes = _find_face_meshes(model)
	face.has_face = face_meshes.size() > 0
	
	print("👤 Meshes de cara encontrados: %d" % face_meshes.size())
	
	if face.has_face:
		face.confidence = 0.2  # Confidence básica
		face.reasoning = "Detectados %d meshes faciales" % face_meshes.size()
	else:
		print("👤 No se encontraron meshes faciales")
	
	for key in face.keys():
		print("👤 %s: %s" % [key, str(face[key])])
	
	return face

func _calculate_suggested_orientation_debug(analysis_details: Dictionary) -> Dictionary:
	"""Calcular orientación sugerida basada en todos los análisis - CON DEBUG EXTENSO"""
	print("\n🧮 === CÁLCULO DE ORIENTACIÓN SUGERIDA - DEBUG CRÍTICO ===")
	print("🧮 analysis_details recibido:")
#	print("🧮 Keys disponibles: %s" % analysis_details.keys())
	
	for key in analysis_details.keys():
		print("🧮 %s content: %s" % [key, str(analysis_details[key])])
	
	var result = {
		"angle": 0.0,
		"confidence": 0.0,
		"reasoning": "Análisis geométrico automático",
		"alternatives": []
	}
	
	var weighted_suggestions = []
	print("🧮 weighted_suggestions inicializado vacío")
	
	# Sugerencia basada en simetría
	print("\n🧮 === PROCESANDO SIMETRÍA ===")
	if analysis_details.has("symmetry"):
		var symmetry = analysis_details.symmetry
		print("🧮 symmetry encontrada: %s" % str(symmetry))
		print("🧮 primary_symmetry_axis: %s" % symmetry.get("primary_symmetry_axis", "NO_ENCONTRADO"))
		print("🧮 confidence: %.2f" % symmetry.get("confidence", -1))
		
		if symmetry.get("primary_symmetry_axis", "") == "X":
			var suggestion = {"angle": 0.0, "weight": 0.3, "source": "simetría X"}
			weighted_suggestions.append(suggestion)
			print("🧮 ✅ Agregada sugerencia de simetría X: %s" % str(suggestion))
		elif symmetry.get("primary_symmetry_axis", "") == "Z":
			var suggestion = {"angle": 270, "weight": 0.3, "source": "simetría Z"}
			weighted_suggestions.append(suggestion)
			print("🧮 ✅ Agregada sugerencia de simetría Z: %s" % str(suggestion))
		else:
			print("🧮 ❌ No se agregó sugerencia de simetría (axis: %s)" % symmetry.get("primary_symmetry_axis", ""))
	else:
		print("🧮 ❌ No hay datos de simetría en analysis_details")
	
	# Sugerencia basada en huesos
	print("\n🧮 === PROCESANDO HUESOS ===")
	if analysis_details.has("bones"):
		var bones = analysis_details.bones
		print("🧮 bones encontrado: %s" % str(bones))
		print("🧮 confidence: %.2f" % bones.get("confidence", -1))
		
		if bones.get("confidence", 0.0) > 0.5:
			var bone_forward = bones.get("suggested_forward", Vector3.FORWARD)
			var bone_angle = _vector_to_angle(bone_forward)
			var suggestion = {"angle": bone_angle, "weight": 0.5, "source": "estructura ósea"}
			weighted_suggestions.append(suggestion)
			print("🧮 ✅ Agregada sugerencia de huesos: %s" % str(suggestion))
		else:
			print("🧮 ❌ No se agregó sugerencia de huesos (confidence: %.2f < 0.5)" % bones.get("confidence", 0.0))
	else:
		print("🧮 ❌ No hay datos de huesos en analysis_details")
	
	# Sugerencia basada en cara
	print("\n🧮 === PROCESANDO CARA ===")
	if analysis_details.has("face"):
		var face = analysis_details.face
		print("🧮 face encontrada: %s" % str(face))
		print("🧮 confidence: %.2f" % face.get("confidence", -1))
		
		if face.get("confidence", 0.0) > 0.5:
			var face_forward = face.get("detected_front", Vector3.FORWARD)
			var face_angle = _vector_to_angle(face_forward)
			var suggestion = {"angle": face_angle, "weight": 0.6, "source": "detección facial"}
			weighted_suggestions.append(suggestion)
			print("🧮 ✅ Agregada sugerencia facial: %s" % str(suggestion))
		else:
			print("🧮 ❌ No se agregó sugerencia facial (confidence: %.2f < 0.5)" % face.get("confidence", 0.0))
	else:
		print("🧮 ❌ No hay datos de cara en analysis_details")
	
	# Sugerencia basada en geometría (fallback)
	print("\n🧮 === PROCESANDO GEOMETRÍA ===")
	if analysis_details.has("geometry"):
		var geometry = analysis_details.geometry
		print("🧮 geometry encontrada: %s" % str(geometry))
		var geometric_angle = _suggest_angle_from_geometry(geometry)
		var suggestion = {"angle": geometric_angle, "weight": 0.2, "source": "análisis geométrico"}
		weighted_suggestions.append(suggestion)
		print("🧮 ✅ Agregada sugerencia geométrica: %s" % str(suggestion))
	else:
		print("🧮 ❌ No hay datos de geometría en analysis_details")
	
	print("\n🧮 === RESULTADO DE SUGERENCIAS ===")
	print("🧮 weighted_suggestions.size() = %d" % weighted_suggestions.size())
	for i in range(weighted_suggestions.size()):
		var sugg = weighted_suggestions[i]
		print("🧮 [%d] angle=%.1f°, weight=%.2f, source=%s" % [i, sugg.angle, sugg.weight, sugg.source])
	
	# Calcular ángulo ponderado
	if weighted_suggestions.size() > 0:
		print("🧮 === CALCULANDO ÁNGULO PONDERADO ===")
		var calculated_result = _calculate_weighted_angle_debug(weighted_suggestions)
		result.angle = calculated_result.angle
		result.confidence = calculated_result.confidence
		result.reasoning = calculated_result.reasoning
		print("🧮 ✅ Ángulo ponderado calculado: %.1f°" % result.angle)
	else:
		print("🧮 ❌ PROBLEMA CRÍTICO: No hay sugerencias válidas")
		print("🧮 result.angle permanecerá en: %.1f°" % result.angle)
	
	# Generar alternativas
	result.alternatives = [
		{"angle": 0.0, "label": "Norte (0°)"},
		{"angle": 90.0, "label": "Este (90°)"},
		{"angle": 180.0, "label": "Sur (180°)"},
		{"angle": 270.0, "label": "Oeste (270°)"}
	]
	
	print("\n🧮 === RESULTADO FINAL ===")
	print("🧮 angle: %.1f°" % result.angle)
	print("🧮 confidence: %.1f%%" % (result.confidence * 100))
	print("🧮 reasoning: %s" % result.reasoning)
	print("🧮 alternatives count: %d" % result.alternatives.size())
	
	return result

func _calculate_weighted_angle_debug(suggestions: Array) -> Dictionary:
	"""Calcular ángulo ponderado de múltiples sugerencias - CON DEBUG"""
	print("🧮 === CALCULANDO ÁNGULO PONDERADO ===")
	
	var total_weight = 0.0
	var weighted_sum = 0.0
	var reasoning_parts = []
	
	for suggestion in suggestions:
		print("🧮 Procesando: angle=%.1f°, weight=%.2f, source=%s" % [suggestion.angle, suggestion.weight, suggestion.source])
		total_weight += suggestion.weight
		weighted_sum += suggestion.angle * suggestion.weight
		reasoning_parts.append(suggestion.source)
	
	print("🧮 total_weight = %.2f" % total_weight)
	print("🧮 weighted_sum = %.2f" % weighted_sum)
	
	var final_angle = weighted_sum / max(total_weight, 0.001)
	var confidence = min(total_weight / 1.0, 1.0)  # Normalizar a 0-1
	
	print("🧮 final_angle (antes redondeo) = %.2f°" % final_angle)
	print("🧮 confidence = %.2f" % confidence)
	
	# Redondear a múltiplo de 45° para orientaciones más naturales
	final_angle = round(final_angle / 45.0) * 45.0
	
	# Asegurar que esté en rango 0-359
	while final_angle < 0:
		final_angle += 360.0
	while final_angle >= 360:
		final_angle -= 360.0
	
	print("🧮 final_angle (después redondeo) = %.1f°" % final_angle)
	
	return {
		"angle": final_angle,
		"confidence": confidence,
		"reasoning": "Basado en: " + ", ".join(reasoning_parts)
	}

# ========================================================================
# FUNCIONES DE UTILIDAD CON DEBUG
# ========================================================================

func _find_all_skeletons(node: Node) -> Array:
	"""Buscar todos los Skeleton3D en el modelo"""
	var skeletons = []
	
	if node is Skeleton3D:
		skeletons.append(node)
	
	for child in node.get_children():
		skeletons.append_array(_find_all_skeletons(child))
	
	return skeletons

func _find_face_meshes(model: Node3D) -> Array:
	"""Buscar meshes que podrían representar cara"""
	var face_meshes = []
	var mesh_instances = _find_all_mesh_instances(model)
	
	for mesh_inst in mesh_instances:
		var mesh_name = mesh_inst.name.to_lower()
		if "head" in mesh_name or "face" in mesh_name or "eye" in mesh_name:
			face_meshes.append(mesh_inst)
	
	return face_meshes

func _vector_to_angle(vector: Vector3) -> float:
	"""Convertir vector direccional a ángulo en grados"""
	return rad_to_deg(atan2(vector.x, vector.z))

func _suggest_angle_from_geometry(geometry: Dictionary) -> float:
	"""Sugerir ángulo basado en geometría - CORREGIDO para spritesheets"""
	print("🧮 Sugiriendo ángulo desde geometría...")
	print("🧮 aspect_ratios: %s" % str(geometry.get("aspect_ratios", {})))
	
	var aspect_ratios = geometry.get("aspect_ratios", {})
	var dominant_axis = geometry.get("dominant_axis", "Y")
	var width_depth = aspect_ratios.get("width_depth", 1.0)
	var height_depth = aspect_ratios.get("height_depth", 1.0)
	var width_height = aspect_ratios.get("width_height", 1.0)
	
	print("🧮 width_depth ratio: %.2f" % width_depth)
	print("🧮 height_depth ratio: %.2f" % height_depth)
	print("🧮 width_height ratio: %.2f" % width_height)
	print("🧮 dominant_axis: %s" % dominant_axis)
	
	# 🎭 DETECTAR HUMANOIDE: vertical, alto, poco profundo
	if (dominant_axis == "Y" and 
		height_depth > 4.0 and 
		width_height < 1.2):
		print("🎭 HUMANOIDE DETECTADO - orientando hacia la derecha (Norte spritesheet)")
		print("🎭 Criterios cumplidos:")
		print("🎭   - Eje dominante Y: ✅")
		print("🎭   - height_depth > 4.0: %.2f ✅" % height_depth)
		print("🎭   - width_height < 1.2: %.2f ✅" % width_height)
		return 270.0  # 90° = Este = "mirar hacia la derecha" = Norte para spritesheets
	
	# 🏗️ LÓGICA ORIGINAL para objetos NO-humanoides
	print("🏗️ Aplicando lógica para objetos/vehículos...")
	
	# Si el modelo es más ancho que profundo, sugerir orientación lateral
	if width_depth > 1.5:
		print("🧮 Modelo ancho → sugerencia: 90°")
		return 270.0
	
	# Si es más profundo que ancho, sugerir orientación frontal  
	if width_depth < 0.7:
		print("🧮 Modelo profundo → sugerencia: 0°")
		return 0.0
	
	
	
	print("🧮 width_depth ratio: %.2f" % width_depth)
	print("🧮 height_depth ratio: %.2f" % height_depth)
	print("🧮 width_height ratio: %.2f" % width_height)
	print("🧮 dominant_axis: %s" % dominant_axis)
	
	# 🎭 DETECTAR HUMANOIDE: vertical, alto, poco profundo
	if (dominant_axis == "Y" and 
		height_depth > 4.0 and 
		width_height < 1.2):
		print("🎭 HUMANOIDE DETECTADO - manteniendo orientación frontal")
		print("🎭 Criterios cumplidos:")
		print("🎭   - Eje dominante Y: ✅")
		print("🎭   - height_depth > 4.0: %.2f ✅" % height_depth)
		print("🎭   - width_height < 1.2: %.2f ✅" % width_height)
		return 0.0
	
	# 🏗️ LÓGICA ORIGINAL para objetos NO-humanoides
	print("🏗️ Aplicando lógica para objetos/vehículos...")
	
	# Si el modelo es más ancho que profundo, sugerir orientación lateral
	if width_depth > 1.5:
		print("🧮 Modelo ancho → sugerencia: 90°")
		return 270.0
	
	# Si es más profundo que ancho, sugerir orientación frontal
	if width_depth < 0.7:
		print("🧮 Modelo profundo → sugerencia: 0°")
		return 0.0
	
	# Para modelos cuadrados, mantener orientación por defecto
	print("🧮 Modelo equilibrado → sugerencia: 0°")
	return 0.0
# ========================================================================
# FUNCIONES EXISTENTES (sin modificar)
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
