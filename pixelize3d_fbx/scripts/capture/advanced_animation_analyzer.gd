# scripts/capture/animation_analyzer.gd
# Analizador súper avanzado con 7 métodos de detección para máxima precisión
# Input: Animation de Godot desde archivo FBX cargado
# Output: Análisis ultra-preciso con múltiples validaciones cruzadas

extends Node
class_name AnimationAnalyzer

# Señales para máximo feedback de calidad
signal analysis_complete(animation_name: String, analysis_data: Dictionary)
signal analysis_error(animation_name: String, error_message: String)
signal detection_method_completed(method_name: String, result: Dictionary)
signal quality_warning(animation_name: String, warning: String)

# Configuración para máxima calidad
var enable_all_detection_methods: bool = true
var enable_cross_validation: bool = true
var enable_quality_warnings: bool = true
var enable_deep_bone_analysis: bool = true
var enable_metadata_extraction: bool = true

# Umbrales de calidad estrictos
var min_confidence_threshold: float = 0.95  # 95% confianza mínima
var fps_detection_tolerance: float = 0.01    # Tolerancia de 0.01 FPS
var keyframe_analysis_depth: int = 1000      # Análisis profundo de keyframes

# Métodos de detección avanzados
enum DetectionMethod {
	STEP_BASED,           # Método basado en Animation.step
	KEYFRAME_PATTERN,     # Análisis de patrón de keyframes
	BONE_VELOCITY,        # Análisis de velocidad de huesos
	INTERPOLATION_GAPS,   # Detección de gaps de interpolación
	FREQUENCY_ANALYSIS,   # Análisis de frecuencia de movimiento
	MOTION_SIGNATURE,     # Análisis de firma de movimiento
	METADATA_EXTRACTION,  # Extracción de metadatos FBX
	TEMPORAL_CONSISTENCY, # Análisis de consistencia temporal
	HARMONIC_ANALYSIS,    # Análisis armónico de transformaciones
	CONSENSUS_VALIDATION  # Validación por consenso de métodos
}

# Cache para análisis de máxima calidad
var quality_analysis_cache: Dictionary = {}
var bone_analysis_cache: Dictionary = {}
var frequency_analysis_cache: Dictionary = {}

func _ready():
	print("🔍 AnimationAnalyzer SÚPER AVANZADO inicializado")
	print("🎯 Prioridad: CALIDAD MÁXIMA sobre performance")

# ========================================================================
# ANÁLISIS PRINCIPAL CON MÁXIMA PRECISIÓN
# ========================================================================

func analyze_animation(anim: Animation, anim_name: String = "") -> Dictionary:
	"""Análisis súper preciso con validación cruzada de múltiples métodos"""
	if not anim:
		push_error("❌ Animación nula proporcionada para análisis")
		return _create_error_analysis("Animación nula")
	
	print("🔍 Iniciando análisis SÚPER PRECISO para: %s" % anim_name)
	
	var analysis = _create_advanced_analysis_structure(anim, anim_name)
	
	# ✅ FASE 1: ANÁLISIS BÁSICO MEJORADO
	_analyze_basic_timing_advanced(anim, analysis)
	
	# ✅ FASE 2: DETECCIÓN FPS CON 7 MÉTODOS
	var detection_results = _execute_all_detection_methods(anim, analysis)
	
	# ✅ FASE 3: VALIDACIÓN CRUZADA Y CONSENSO
	var consensus_result = _calculate_advanced_consensus(detection_results, anim, analysis)
	analysis.detected_fps = consensus_result.fps
	analysis.detection_confidence = consensus_result.confidence
	analysis.detection_methods_used = consensus_result.methods_used
	analysis.consensus_details = consensus_result.details
	
	# ✅ FASE 4: ANÁLISIS PROFUNDO DE KEYFRAMES
	if enable_deep_bone_analysis:
		_analyze_keyframes_ultra_deep(anim, analysis)
	
	# ✅ FASE 5: ANÁLISIS DE CALIDAD Y VALIDACIONES
	_analyze_quality_and_advanced_recommendations(anim, analysis)
	
	# ✅ FASE 6: VALIDACIÓN FINAL DE CALIDAD
	_validate_analysis_quality(analysis)
	
	emit_signal("analysis_complete", anim_name, analysis)
	print("✅ Análisis SÚPER PRECISO completado: %.3fs, %.1f FPS, %.1f%% confianza" % [
		analysis.length, analysis.detected_fps, analysis.detection_confidence * 100
	])
	
	return analysis

# ========================================================================
# MÉTODOS DE DETECCIÓN SÚPER AVANZADOS (7 MÉTODOS)
# ========================================================================

#func _execute_all_detection_methods(anim: Animation, analysis: Dictionary) -> Array:
func _execute_all_detection_methods(anim: Animation, _analysis: Dictionary) -> Array:
	"""Ejecutar todos los métodos de detección para máxima precisión"""
	var detection_results = []
	
	print("🔬 Ejecutando 7 métodos de detección FPS...")
	
	# Método 1: Step-based (clásico mejorado)
	var step_result = _detect_fps_step_based_advanced(anim)
	detection_results.append(step_result)
	emit_signal("detection_method_completed", "step_based", step_result)
	
	# Método 2: Patrón de keyframes súper avanzado
	var pattern_result = _detect_fps_keyframe_pattern_advanced(anim)
	detection_results.append(pattern_result)
	emit_signal("detection_method_completed", "keyframe_pattern", pattern_result)
	
	# Método 3: Velocidad de huesos (NUEVO)
	var velocity_result = _detect_fps_bone_velocity_advanced(anim)
	detection_results.append(velocity_result)
	emit_signal("detection_method_completed", "bone_velocity", velocity_result)
	
	# Método 4: Gaps de interpolación (NUEVO)
	var gaps_result = _detect_fps_interpolation_gaps(anim)
	detection_results.append(gaps_result)
	emit_signal("detection_method_completed", "interpolation_gaps", gaps_result)
	
	# Método 5: Análisis de frecuencia (NUEVO)
	var frequency_result = _detect_fps_frequency_analysis_advanced(anim)
	detection_results.append(frequency_result)
	emit_signal("detection_method_completed", "frequency_analysis", frequency_result)
	
	# Método 6: Firma de movimiento (NUEVO)
	var signature_result = _detect_fps_motion_signature(anim)
	detection_results.append(signature_result)
	emit_signal("detection_method_completed", "motion_signature", signature_result)
	
	# Método 7: Extracción de metadatos (NUEVO)
	var metadata_result = _detect_fps_metadata_extraction(anim)
	detection_results.append(metadata_result)
	emit_signal("detection_method_completed", "metadata_extraction", metadata_result)
	
	# Filtrar resultados inválidos
	detection_results = detection_results.filter(func(result): return result.fps > 0)
	
	print("✅ Completados %d métodos de detección válidos" % detection_results.size())
	return detection_results

func _detect_fps_step_based_advanced(anim: Animation) -> Dictionary:
	"""Método 1: Step-based con validaciones avanzadas"""
	var result = {
		"method": DetectionMethod.STEP_BASED,
		"method_name": "Step-Based Advanced",
		"fps": 0.0,
		"confidence": 0.0,
		"validation_data": {},
		"quality_score": 0.0
	}
	
	if anim.step > 0:
		result.fps = 1.0 / anim.step
		
		# ✅ VALIDACIÓN AVANZADA: Verificar consistencia
		var expected_frames = anim.length / anim.step
		var frame_consistency = abs(expected_frames - round(expected_frames))
		
		# ✅ VALIDACIÓN: FPS razonable
		var fps_reasonable = result.fps >= 1.0 and result.fps <= 240.0
		
		# ✅ VALIDACIÓN: Step coherente con duración
		var step_coherent = anim.step < anim.length
		
		if fps_reasonable and step_coherent and frame_consistency < 0.1:
			result.confidence = 0.95  # Alta confianza si pasa todas las validaciones
			result.quality_score = 95.0
		else:
			result.confidence = 0.5   # Confianza media si hay inconsistencias
			result.quality_score = 50.0
		
		result.validation_data = {
			"expected_frames": expected_frames,
			"frame_consistency": frame_consistency,
			"fps_reasonable": fps_reasonable,
			"step_coherent": step_coherent
		}
	
	return result

func _detect_fps_keyframe_pattern_advanced(anim: Animation) -> Dictionary:
	"""Método 2: Análisis súper avanzado de patrones de keyframes"""
	var result = {
		"method": DetectionMethod.KEYFRAME_PATTERN,
		"method_name": "Keyframe Pattern Advanced",
		"fps": 0.0,
		"confidence": 0.0,
		"keyframe_data": {},
		"pattern_analysis": {}
	}
	
	var all_keyframe_times = []
	var track_analysis = []
	
	# ✅ ANÁLISIS TRACK POR TRACK para máxima precisión
	for track_idx in range(anim.get_track_count()):
		var track_keyframes = []
		var key_count = anim.track_get_key_count(track_idx)
		
		for key_idx in range(key_count):
			var key_time = anim.track_get_key_time(track_idx, key_idx)
			track_keyframes.append(key_time)
			all_keyframe_times.append(key_time)
		
		if track_keyframes.size() > 1:
			var track_fps = _analyze_track_fps_pattern(track_keyframes, anim.length)
			track_analysis.append({
				"track_idx": track_idx,
				"fps": track_fps.fps,
				"confidence": track_fps.confidence,
				"pattern_type": track_fps.pattern_type
			})
	
	if all_keyframe_times.size() < 3:
		result.confidence = 0.0
		return result
	
	# ✅ ANÁLISIS DE INTERVALOS SÚPER PRECISO
	all_keyframe_times.sort()
	var intervals = []
	
	for i in range(1, all_keyframe_times.size()):
		var interval = all_keyframe_times[i] - all_keyframe_times[i-1]
		if interval > 0.001:  # Filtrar ruido sub-milisegundo
			intervals.append(interval)
	
	if intervals.is_empty():
		result.confidence = 0.0
		return result
	
	# ✅ ANÁLISIS ESTADÍSTICO AVANZADO de intervalos
	var interval_stats = _calculate_advanced_interval_statistics(intervals)
	
	# ✅ DETECCIÓN DE PATRÓN DOMINANTE
	var dominant_pattern = _find_dominant_interval_pattern(intervals)
	
	if dominant_pattern.confidence > 0.7:
		result.fps = 1.0 / dominant_pattern.interval
		result.confidence = dominant_pattern.confidence * 0.8  # Factor de confianza conservador
		result.keyframe_data = {
			"total_keyframes": all_keyframe_times.size(),
			"total_intervals": intervals.size(),
			"dominant_interval": dominant_pattern.interval,
			"pattern_frequency": dominant_pattern.frequency
		}
		result.pattern_analysis = interval_stats
	
	return result

func _detect_fps_bone_velocity_advanced(anim: Animation) -> Dictionary:
	"""Método 3: NUEVO - Análisis de velocidad de huesos súper preciso"""
	var result = {
		"method": DetectionMethod.BONE_VELOCITY,
		"method_name": "Bone Velocity Advanced",
		"fps": 0.0,
		"confidence": 0.0,
		"velocity_analysis": {},
		"bone_data": {}
	}
	
	# ✅ SAMPLEAR ANIMACIÓN con alta resolución temporal
	var sample_count = min(1000, int(anim.length * 120))  # Hasta 120 samples/segundo
	var bone_tracks = _find_bone_transformation_tracks(anim)
	
	if bone_tracks.is_empty():
		result.confidence = 0.0
		return result
	
	var velocity_patterns = []
	
	# ✅ ANÁLISIS POR CADA HUESO IMPORTANTE
	for track_idx in bone_tracks:
		var track_velocities = _analyze_bone_track_velocity(anim, track_idx, sample_count)
		
		if not track_velocities.is_empty():
			var velocity_fps = _extract_fps_from_velocity_pattern(track_velocities, anim.length)
			
			if velocity_fps.confidence > 0.6:
				velocity_patterns.append(velocity_fps)
	
	if velocity_patterns.is_empty():
		result.confidence = 0.0
		return result
	
	# ✅ CONSENSO DE VELOCIDADES DE MÚLTIPLES HUESOS
	var velocity_consensus = _calculate_velocity_consensus(velocity_patterns)
	
	result.fps = velocity_consensus.fps
	result.confidence = velocity_consensus.confidence
	result.velocity_analysis = velocity_consensus.analysis
	result.bone_data = {
		"analyzed_bones": bone_tracks.size(),
		"valid_patterns": velocity_patterns.size(),
		"consensus_strength": velocity_consensus.strength
	}
	
	return result

#func _detect_fps_interpolation_gaps(anim: Animation) -> Dictionary:
	#"""Método 4: NUEVO - Detección de gaps de interpolación"""
	#var result = {
		#"method": DetectionMethod.INTERPOLATION_GAPS,
		#"method_name": "Interpolation Gaps",
		#"fps": 0.0,
		#"confidence": 0.0,
		#"gap_analysis": {}
	#}
	#
	## ✅ BUSCAR GAPS EN INTERPOLACIÓN entre keyframes
	#var interpolation_gaps = []
	#
	#for track_idx in range(anim.get_track_count()):
		#var track_gaps = _find_interpolation_gaps_in_track(anim, track_idx)
		#interpolation_gaps.append_array(track_gaps)
	#
	#if interpolation_gaps.size() < 2:
		#result.confidence = 0.0
		#return result
	#
	## ✅ ANÁLISIS ESTADÍSTICO de gaps
	#var gap_statistics = _analyze_gap_distribution(interpolation_gaps, anim.length)
	#
	#if gap_statistics.has_clear_pattern:
		#result.fps = gap_statistics.implied_fps
		#result.confidence = gap_statistics.pattern_confidence
		#result.gap_analysis = gap_statistics
	#
	#return result

func _detect_fps_interpolation_gaps(anim: Animation) -> Dictionary:
	"""Método 4: Detección de gaps de interpolación súper preciso"""
	var result = {
		"method": DetectionMethod.INTERPOLATION_GAPS,
		"method_name": "Interpolation Gaps Detection",
		"fps": 0.0,
		"confidence": 0.0,
		"gap_analysis": {}
	}
	
	if anim.get_track_count() == 0:
		result.confidence = 0.0
		return result
	
	var all_gaps = []
	var track_gaps = []
	
	# ✅ ANALIZAR GAPS EN CADA TRACK
	for track_idx in range(anim.get_track_count()):  # ← CORRECCIÓN: for variable in range()
		var key_count = anim.track_get_key_count(track_idx)
		if key_count < 2:
			continue
		
		var track_keyframes = []
		for key_idx in range(key_count):  # ← CORRECCIÓN: for variable in range()
			var key_time = anim.track_get_key_time(track_idx, key_idx)
			track_keyframes.append(key_time)
		
		track_keyframes.sort()
		
		# ✅ DETECTAR GAPS DE INTERPOLACIÓN
		var gaps_in_track = []
		for i in range(1, track_keyframes.size()):  # ← CORRECCIÓN: for variable in range()
			var gap = track_keyframes[i] - track_keyframes[i-1]
			if gap > 0.001:  # Filtrar ruido
				gaps_in_track.append(gap)
				all_gaps.append(gap)
		
		if gaps_in_track.size() > 0:
			track_gaps.append({
				"track_idx": track_idx,
				"gaps": gaps_in_track,
				"gap_pattern": _analyze_gap_pattern(gaps_in_track)
			})
	
	if all_gaps.size() < 3:
		result.confidence = 0.0
		return result
	
	# ✅ ANÁLISIS ESTADÍSTICO DE GAPS
	var gap_statistics = _calculate_comprehensive_gap_statistics(all_gaps, anim.length)
	
	if gap_statistics.has_consistent_pattern:
		result.fps = 1.0 / gap_statistics.dominant_gap
		result.confidence = gap_statistics.pattern_confidence
		result.gap_analysis = gap_statistics
	
	return result


func _detect_fps_frequency_analysis_advanced(anim: Animation) -> Dictionary:
	"""Método 5: NUEVO - Análisis de frecuencia súper avanzado"""
	var result = {
		"method": DetectionMethod.FREQUENCY_ANALYSIS,
		"method_name": "Frequency Analysis Advanced",
		"fps": 0.0,
		"confidence": 0.0,
		"frequency_data": {}
	}
	
	# ✅ EXTRAER SEÑALES DE TRANSFORMACIÓN de múltiples tracks
	var transformation_signals = _extract_multi_track_signals(anim)
	
	if transformation_signals.is_empty():
		result.confidence = 0.0
		return result
	
	var frequency_analyses = []
	
	# ✅ ANÁLISIS DE FRECUENCIA POR CADA SEÑAL
	for transform_signal in transformation_signals:  # ← CORRECCIÓN: signal → transform_signal
		var freq_analysis = _perform_frequency_analysis_on_signal(transform_signal, anim.length)
		
		if freq_analysis.has_dominant_frequency:
			frequency_analyses.append(freq_analysis)
	
	if frequency_analyses.is_empty():
		result.confidence = 0.0
		return result
	
	# ✅ CONSENSO DE ANÁLISIS DE FRECUENCIAS
	var frequency_consensus = _calculate_frequency_consensus(frequency_analyses)
	
	result.fps = frequency_consensus.dominant_fps
	result.confidence = frequency_consensus.consensus_confidence
	result.frequency_data = {
		"signals_analyzed": transformation_signals.size(),
		"valid_analyses": frequency_analyses.size(),
		"dominant_frequency": frequency_consensus.dominant_frequency,
		"harmonic_strength": frequency_consensus.harmonic_strength
	}
	
	return result


func _detect_fps_motion_signature(anim: Animation) -> Dictionary:
	"""Método 6: NUEVO - Análisis de firma de movimiento"""
	var result = {
		"method": DetectionMethod.MOTION_SIGNATURE,
		"method_name": "Motion Signature",
		"fps": 0.0,
		"confidence": 0.0,
		"signature_analysis": {}
	}
	
	# ✅ CREAR FIRMA ÚNICA del movimiento de la animación
	var motion_signature = _create_comprehensive_motion_signature(anim)
	
	# ✅ ANALIZAR PATRONES REPETITIVOS en la firma
	var repetitive_patterns = _find_repetitive_patterns_in_signature(motion_signature, anim.length)
	
	if repetitive_patterns.is_empty():
		result.confidence = 0.0
		return result
	
	# ✅ EXTRAER FPS del patrón repetitivo más fuerte
	var strongest_pattern = _find_strongest_repetitive_pattern(repetitive_patterns)
	
	if strongest_pattern.strength > 0.7:
		result.fps = strongest_pattern.implied_fps
		result.confidence = strongest_pattern.strength * 0.75  # Factor conservador
		result.signature_analysis = {
			"signature_length": motion_signature.size(),
			"patterns_found": repetitive_patterns.size(),
			"strongest_pattern": strongest_pattern
		}
	
	return result

func _detect_fps_metadata_extraction(anim: Animation) -> Dictionary:
	"""Método 7: NUEVO - Extracción de metadatos FBX"""
	var result = {
		"method": DetectionMethod.METADATA_EXTRACTION,
		"method_name": "Metadata Extraction",
		"fps": 0.0,
		"confidence": 0.0,
		"metadata": {}
	}
	
	# ✅ INTENTAR EXTRAER METADATOS del resource path
	var resource_path = anim.resource_path
	if resource_path != "":
		var metadata = _extract_fbx_metadata_from_path(resource_path)
		
		if metadata.has("original_fps"):
			result.fps = metadata.original_fps
			result.confidence = metadata.metadata_confidence
			result.metadata = metadata
			return result
	
	# ✅ ANÁLISIS DE PROPIEDADES INTERNAS de la animación
	var internal_metadata = _analyze_animation_internal_properties(anim)
	
	if internal_metadata.has_fps_hints:
		result.fps = internal_metadata.suggested_fps
		result.confidence = internal_metadata.confidence
		result.metadata = internal_metadata
	
	return result

# ========================================================================
# CÁLCULO DE CONSENSO SÚPER AVANZADO
# ========================================================================

func _calculate_advanced_consensus(detection_results: Array, anim: Animation, _analysis: Dictionary) -> Dictionary:
	"""Cálculo de consenso súper avanzado con validación cruzada"""
	print("🔬 Calculando consenso avanzado de %d métodos..." % detection_results.size())
	
	var consensus = {
		"fps": 0.0,
		"confidence": 0.0,
		"methods_used": [],
		"details": {},
		"cross_validation": {}
	}
	
	if detection_results.is_empty():
		consensus.fps = 30.0  # Fallback conservador
		consensus.confidence = 0.1
		return consensus
	
	# ✅ FILTRAR RESULTADOS por calidad mínima
	var high_quality_results = detection_results.filter(
		func(result): return result.confidence >= 0.6
	)
	
	if high_quality_results.is_empty():
		high_quality_results = detection_results  # Usar todos si ninguno es de alta calidad
	
	# ✅ AGRUPACIÓN POR SIMILARIDAD DE FPS
	var fps_groups = _group_results_by_fps_similarity(high_quality_results)
	
	# ✅ SELECCIONAR GRUPO DOMINANTE
	var dominant_group = _select_dominant_fps_group(fps_groups)
	
	# ✅ CÁLCULO DE FPS PONDERADO por confianza
	var weighted_fps = 0.0
	var total_weight = 0.0
	var methods_used = []
	
	for result in dominant_group.results:
		var weight = result.confidence * result.confidence  # Peso cuadrático para favorecer alta confianza
		weighted_fps += result.fps * weight
		total_weight += weight
		methods_used.append(result.method_name)
	
	if total_weight > 0:
		consensus.fps = weighted_fps / total_weight
	else:
		consensus.fps = dominant_group.average_fps
	
	# ✅ CÁLCULO DE CONFIANZA DEL CONSENSO
	consensus.confidence = _calculate_consensus_confidence(dominant_group, detection_results)
	
	# ✅ VALIDACIÓN CRUZADA FINAL
	consensus.cross_validation = _perform_cross_validation( detection_results, consensus.fps)
	
	# ✅ AJUSTE DE CONFIANZA basado en validación cruzada
	if consensus.cross_validation.validation_passed:
		consensus.confidence = min(1.0, consensus.confidence + 0.1)  # Bonus por validación
	else:
		consensus.confidence *= 0.8  # Penalizar si falla validación cruzada
	
	consensus.methods_used = methods_used
	consensus.details = {
		"total_methods": detection_results.size(),
		"high_quality_methods": high_quality_results.size(),
		"consensus_group_size": dominant_group.results.size(),
		"fps_variance": dominant_group.variance,
		"weighted_calculation": total_weight > 0
	}
	
	print("✅ Consenso calculado: %.1f FPS (%.1f%% confianza, %d métodos)" % [
		consensus.fps, consensus.confidence * 100, methods_used.size()
	])
	
	return consensus

# ========================================================================
# ANÁLISIS PROFUNDO DE KEYFRAMES
# ========================================================================

func _analyze_keyframes_ultra_deep(anim: Animation, analysis: Dictionary):
	"""Análisis ultra-profundo de keyframes para máxima calidad"""
	print("🔬 Iniciando análisis ULTRA-PROFUNDO de keyframes...")
	
	var ultra_deep_analysis = {
		"total_tracks": anim.get_track_count(),
		"tracks_analyzed": [],
		"keyframe_density_map": {},
		"temporal_distribution": {},
		"interpolation_analysis": {},
		"bone_hierarchy_analysis": {},
		"quality_metrics": {}
	}
	
	# ✅ ANÁLISIS TRACK POR TRACK súper detallado
	for track_idx in range(anim.get_track_count()):
		var track_analysis = _analyze_single_track_ultra_deep(anim, track_idx)
		ultra_deep_analysis.tracks_analyzed.append(track_analysis)
		
		# ✅ MAPA DE DENSIDAD de keyframes
		_update_keyframe_density_map(ultra_deep_analysis.keyframe_density_map, track_analysis)
	
	# ✅ ANÁLISIS DE DISTRIBUCIÓN TEMPORAL
	ultra_deep_analysis.temporal_distribution = _analyze_temporal_distribution( ultra_deep_analysis.tracks_analyzed)
	
	# ✅ ANÁLISIS DE JERARQUÍA DE HUESOS
	if enable_deep_bone_analysis:
		ultra_deep_analysis.bone_hierarchy_analysis = _analyze_bone_hierarchy_timing(anim, ultra_deep_analysis.tracks_analyzed)
	
	# ✅ MÉTRICAS DE CALIDAD de keyframes
	ultra_deep_analysis.quality_metrics = _calculate_keyframe_quality_metrics(ultra_deep_analysis)
	
	analysis.ultra_deep_keyframe_analysis = ultra_deep_analysis
	
	print("✅ Análisis ultra-profundo completado: %d tracks, calidad %.1f%%" % [
		ultra_deep_analysis.total_tracks,
		ultra_deep_analysis.quality_metrics.overall_quality_score
	])

# ========================================================================
# VALIDACIÓN DE CALIDAD AVANZADA
# ========================================================================

func _analyze_quality_and_advanced_recommendations(_anim: Animation, analysis: Dictionary):
	"""Análisis avanzado de calidad con recomendaciones específicas"""
	var recommendations = []
	var quality_score = 100.0
	var quality_warnings = []
	
	# ✅ VALIDACIÓN: Confianza de detección FPS
	if analysis.detection_confidence < min_confidence_threshold:
		var confidence_penalty = (min_confidence_threshold - analysis.detection_confidence) * 50
		quality_score -= confidence_penalty
		
		recommendations.append({
			"type": "critical",
			"issue": "Baja confianza en detección FPS",
			"confidence": analysis.detection_confidence * 100,
			"threshold": min_confidence_threshold * 100,
			"suggestion": "Considerar análisis manual o usar FPS estándar conocido"
		})
		
		if enable_quality_warnings:
			var warning = "Confianza FPS baja: %.1f%%" % (analysis.detection_confidence * 100)
			quality_warnings.append(warning)
			emit_signal("quality_warning", analysis.animation_name, warning)
	
	# ✅ VALIDACIÓN: Duración razonable
	if analysis.length < 0.05:  # Menos de 50ms
		quality_score -= 30.0
		recommendations.append({
			"type": "error",
			"issue": "Animación extremadamente corta",
			"duration": analysis.length,
			"suggestion": "Verificar que el archivo FBX se importó correctamente"
		})
	elif analysis.length > 300.0:  # Más de 5 minutos
		quality_score -= 10.0
		recommendations.append({
			"type": "warning",
			"issue": "Animación muy larga",
			"duration": analysis.length,
			"suggestion": "Considerar dividir en segmentos más cortos"
		})
	
	# ✅ VALIDACIÓN: FPS detectado razonable
	if analysis.detected_fps < 1.0 or analysis.detected_fps > 240.0:
		quality_score -= 40.0
		recommendations.append({
			"type": "critical",
			"issue": "FPS detectado fuera de rango razonable",
			"detected_fps": analysis.detected_fps,
			"suggestion": "Revisar archivo FBX original o forzar FPS conocido"
		})
	
	# ✅ VALIDACIÓN: Número de frames resultante
	var calculated_frames = int(analysis.length * analysis.detected_fps)
	if calculated_frames < 2:
		quality_score -= 50.0
		recommendations.append({
			"type": "critical",
			"issue": "Muy pocos frames para renderizar",
			"calculated_frames": calculated_frames,
			"suggestion": "Animación demasiado corta o FPS detectado incorrecto"
		})
	elif calculated_frames > 10000:
		quality_score -= 20.0
		recommendations.append({
			"type": "warning",
			"issue": "Muchos frames para renderizar",
			"calculated_frames": calculated_frames,
			"suggestion": "Renderizado tomará tiempo considerable"
		})
	
	# ✅ VALIDACIÓN: Consistencia entre métodos de detección
	if analysis.has("consensus_details") and analysis.consensus_details.has("fps_variance"):
		var fps_variance = analysis.consensus_details.fps_variance
		if fps_variance > 2.0:  # Varianza alta entre métodos
			quality_score -= 15.0
			recommendations.append({
				"type": "warning",
				"issue": "Alta varianza entre métodos de detección",
				"variance": fps_variance,
				"suggestion": "Métodos detectan FPS diferentes, verificar calidad del archivo"
			})
	
	analysis.quality_score = max(0.0, quality_score)
	analysis.recommendations = recommendations
	analysis.quality_warnings = quality_warnings
	analysis.quality_grade = _score_to_quality_grade(analysis.quality_score)

func _validate_analysis_quality(analysis: Dictionary):
	"""Validación final exhaustiva de la calidad del análisis"""
	var validation_passed = true
	var critical_issues = []
	
	# ✅ VALIDACIÓN CRÍTICA: Datos básicos presentes
	var required_fields = ["detected_fps", "detection_confidence", "length", "quality_score"]
	for field in required_fields:
		if not analysis.has(field):
			validation_passed = false
			critical_issues.append("Campo requerido faltante: " + field)
	
	# ✅ VALIDACIÓN CRÍTICA: Valores en rangos válidos
	if analysis.has("detected_fps"):
		if analysis.detected_fps <= 0 or not is_finite(analysis.detected_fps):
			validation_passed = false
			critical_issues.append("FPS detectado inválido: " + str(analysis.detected_fps))
	
	if analysis.has("detection_confidence"):
		if analysis.detection_confidence < 0 or analysis.detection_confidence > 1:
			validation_passed = false
			critical_issues.append("Confianza fuera de rango [0-1]: " + str(analysis.detection_confidence))
	
	analysis.validation_passed = validation_passed
	analysis.critical_issues = critical_issues
	
	if not validation_passed:
		print("❌ VALIDACIÓN FALLIDA para %s: %s" % [analysis.animation_name, str(critical_issues)])
		emit_signal("analysis_error", analysis.animation_name, "Validación crítica fallida: " + str(critical_issues))

# ========================================================================
# UTILIDADES AVANZADAS DE ANÁLISIS
# ========================================================================

func _find_bone_transformation_tracks(anim: Animation) -> Array:
	"""Encontrar tracks que contienen transformaciones de huesos"""
	var bone_tracks = []
	
	for track_idx in range(anim.get_track_count()):
		var track_path = anim.track_get_path(track_idx)
		var track_type = anim.track_get_type(track_idx)
		
		# Buscar tracks de transformación 3D (huesos)
		if track_type == Animation.TYPE_POSITION_3D or track_type == Animation.TYPE_ROTATION_3D or track_type == Animation.TYPE_SCALE_3D:
			# Filtrar por nombres típicos de huesos
			var path_str = str(track_path)
			if _looks_like_bone_track(path_str):
				bone_tracks.append(track_idx)
	
	return bone_tracks

func _looks_like_bone_track(path_str: String) -> bool:
	"""Determinar si un track path parece ser de un hueso"""
	var bone_indicators = ["bone", "joint", "spine", "arm", "leg", "head", "hand", "foot", "neck"]
	var path_lower = path_str.to_lower()
	
	for indicator in bone_indicators:
		if indicator in path_lower:
			return true
	
	# También considerar paths con "Skeleton3D" 
	if "skeleton3d" in path_lower:
		return true
	
	return false

func _analyze_track_fps_pattern(keyframe_times: Array, _animation_length: float) -> Dictionary:
	"""Analizar patrón de FPS de un track individual"""
	if keyframe_times.size() < 2:
		return {"fps": 0.0, "confidence": 0.0, "pattern_type": "insufficient_data"}
	
	keyframe_times.sort()
	var intervals = []
	
	for i in range(1, keyframe_times.size()):
		var interval = keyframe_times[i] - keyframe_times[i-1]
		if interval > 0.001:  # Filtrar intervalos muy pequeños
			intervals.append(interval)
	
	if intervals.is_empty():
		return {"fps": 0.0, "confidence": 0.0, "pattern_type": "no_intervals"}
	
	# Analizar distribución de intervalos
	var interval_analysis = _analyze_interval_distribution(intervals)
	
	var result = {
		"fps": 0.0,
		"confidence": 0.0,
		"pattern_type": interval_analysis.pattern_type,
		"interval_stats": interval_analysis
	}
	
	if interval_analysis.has_dominant_interval:
		result.fps = 1.0 / interval_analysis.dominant_interval
		result.confidence = interval_analysis.dominance_strength
	
	return result

func _calculate_advanced_interval_statistics(intervals: Array) -> Dictionary:
	"""Calcular estadísticas avanzadas de intervalos entre keyframes"""
	if intervals.is_empty():
		return {"valid": false}
	
	# Estadísticas básicas
	var mean = 0.0
	var min_interval = intervals[0]
	var max_interval = intervals[0]
	
	for interval in intervals:
		mean += interval
		min_interval = min(min_interval, interval)
		max_interval = max(max_interval, interval)
	
	mean /= intervals.size()
	
	# Varianza y desviación estándar
	var variance = 0.0
	for interval in intervals:
		variance += pow(interval - mean, 2)
	variance /= intervals.size()
	var std_deviation = sqrt(variance)
	
	# Coeficiente de variación
	var coefficient_of_variation = std_deviation / mean if mean > 0 else INF
	
	# Análisis de distribución
	var distribution_analysis = _analyze_distribution_shape(intervals, mean, std_deviation)
	
	return {
		"valid": true,
		"count": intervals.size(),
		"mean": mean,
		"std_deviation": std_deviation,
		"min": min_interval,
		"max": max_interval,
		"variance": variance,
		"coefficient_of_variation": coefficient_of_variation,
		"distribution": distribution_analysis,
		"uniformity_score": 1.0 / (1.0 + coefficient_of_variation)  # Score de uniformidad
	}

func _find_dominant_interval_pattern(intervals: Array) -> Dictionary:
	"""Encontrar el patrón de intervalo dominante con alta precisión"""
	if intervals.size() < 3:
		return {"confidence": 0.0}
	
	# Crear histograma de intervalos con bins adaptativos
	var bin_size = _calculate_adaptive_bin_size(intervals)
	var histogram = _create_interval_histogram(intervals, bin_size)
	
	# Encontrar el bin más frecuente
	var max_frequency = 0
	var dominant_interval = 0.0
	
	for bin_center in histogram:
		if histogram[bin_center] > max_frequency:
			max_frequency = histogram[bin_center]
			dominant_interval = bin_center
	
	# Calcular confianza basada en dominancia
	var total_intervals = intervals.size()
	var dominance_ratio = float(max_frequency) / total_intervals
	
	# Calcular coherencia del patrón
	var pattern_coherence = _calculate_pattern_coherence(intervals, dominant_interval, bin_size)
	
	var confidence = dominance_ratio * pattern_coherence
	
	return {
		"interval": dominant_interval,
		"frequency": max_frequency,
		"confidence": confidence,
		"dominance_ratio": dominance_ratio,
		"pattern_coherence": pattern_coherence
	}

# ========================================================================
# UTILIDADES DE ESTRUCTURA Y SOPORTE
# ========================================================================

func _create_advanced_analysis_structure(anim: Animation, anim_name: String) -> Dictionary:
	"""Crear estructura avanzada del análisis con todos los campos"""
	return {
		"animation_name": anim_name,
		"length": anim.length,
		"loop_mode": _get_loop_mode_name(anim.loop_mode),
		"detected_fps": 0.0,
		"real_frames": 0,
		"step_fps": 0.0,
		"detection_confidence": 0.0,
		"detection_methods_used": [],
		"consensus_details": {},
		"ultra_deep_keyframe_analysis": {},
		"quality_score": 100.0,
		"quality_grade": "A+",
		"quality_warnings": [],
		"recommendations": [],
		"validation_passed": false,
		"critical_issues": [],
		"analysis_timestamp": Time.get_unix_time_from_system(),
		"analyzer_version": "2.0_ULTRA_PRECISION"
	}

func _create_error_analysis(error_msg: String) -> Dictionary:
	"""Crear análisis de error con información detallada"""
	return {
		"error": true,
		"error_message": error_msg,
		"detected_fps": 30.0,  # Fallback seguro
		"detection_confidence": 0.0,
		"quality_score": 0.0,
		"quality_grade": "F",
		"analysis_timestamp": Time.get_unix_time_from_system()
	}

func _score_to_quality_grade(score: float) -> String:
	"""Convertir puntuación numérica a grado de calidad"""
	if score >= 98.0:
		return "A++"
	elif score >= 95.0:
		return "A+"
	elif score >= 90.0:
		return "A"
	elif score >= 85.0:
		return "B+"
	elif score >= 80.0:
		return "B"
	elif score >= 75.0:
		return "C+"
	elif score >= 70.0:
		return "C"
	elif score >= 60.0:
		return "D"
	else:
		return "F"

func _get_loop_mode_name(loop_mode: int) -> String:
	"""Convertir modo de loop a nombre legible"""
	match loop_mode:
		Animation.LOOP_NONE:
			return "None"
		Animation.LOOP_LINEAR:
			return "Linear"
		Animation.LOOP_PINGPONG:
			return "PingPong"
		_:
			return "Unknown"

# ========================================================================
# API PÚBLICA AVANZADA
# ========================================================================

func set_ultra_precision_mode(enabled: bool):
	"""Habilitar modo de ultra-precisión (puede ser más lento pero más preciso)"""
	enable_all_detection_methods = enabled
	enable_cross_validation = enabled
	enable_deep_bone_analysis = enabled
	
	if enabled:
		min_confidence_threshold = 0.98  # Ultra-estricto
		keyframe_analysis_depth = 2000   # Análisis súper profundo
		print("🎯 Modo ULTRA-PRECISIÓN activado")
	else:
		min_confidence_threshold = 0.95  # Estricto normal
		keyframe_analysis_depth = 1000   # Análisis normal
		print("🎯 Modo precisión normal")

func generate_detailed_analysis_report(analysis: Dictionary) -> String:
	"""Generar reporte súper detallado del análisis"""
	var report = "=== REPORTE DETALLADO DE ANÁLISIS FPS ===\n\n"
	
	report += "Animación: %s\n" % analysis.animation_name
	report += "Duración: %.3f segundos\n" % analysis.length
	report += "FPS Detectado: %.2f\n" % analysis.detected_fps
	report += "Confianza: %.1f%%\n" % (analysis.detection_confidence * 100)
	report += "Calidad: %s (%.1f puntos)\n" % [analysis.quality_grade, analysis.quality_score]
	report += "Frames Reales: %d\n\n" % analysis.get("real_frames", 0)
	
	if analysis.has("detection_methods_used"):
		report += "MÉTODOS DE DETECCIÓN UTILIZADOS:\n"
		for i in range(analysis.detection_methods_used.size()):
			report += "  %d. %s\n" % [i+1, analysis.detection_methods_used[i]]
		report += "\n"
	
	if analysis.has("consensus_details"):
		report += "DETALLES DEL CONSENSO:\n"
		var details = analysis.consensus_details
		report += "  Métodos totales: %d\n" % details.get("total_methods", 0)
		report += "  Métodos alta calidad: %d\n" % details.get("high_quality_methods", 0)
		report += "  Varianza FPS: %.3f\n\n" % details.get("fps_variance", 0)
	
	if analysis.recommendations.size() > 0:
		report += "RECOMENDACIONES:\n"
		for rec in analysis.recommendations:
			report += "  [%s] %s\n" % [rec.type.to_upper(), rec.issue]
			report += "    → %s\n" % rec.suggestion
		report += "\n"
	
	if analysis.quality_warnings.size() > 0:
		report += "ADVERTENCIAS DE CALIDAD:\n"
		for warning in analysis.quality_warnings:
			report += "  ⚠️ %s\n" % warning
		report += "\n"
	
	report += "Análisis completado: %s\n" % Time.get_datetime_string_from_system()
	report += "Versión del analizador: %s\n" % analysis.get("analyzer_version", "Unknown")
	
	return report



# ========================================================================
# FUNCIONES AUXILIARES PARA ANÁLISIS DE FRECUENCIA
# ========================================================================

func _extract_multi_track_signals(anim: Animation) -> Array:
	"""Extraer señales de transformación de múltiples tracks"""
	var signals = []
	
	if not anim or anim.get_track_count() == 0:
		return signals
	
	# ✅ PROCESAR CADA TRACK DE LA ANIMACIÓN
	for track_idx in range(anim.get_track_count()):
		var track_type = anim.track_get_type(track_idx)
		
		# Solo procesar tracks de transformación
		if track_type == Animation.TYPE_POSITION_3D or track_type == Animation.TYPE_ROTATION_3D or track_type == Animation.TYPE_SCALE_3D:
			var track_signal = _extract_track_signal(anim, track_idx)
			if not track_signal.is_empty():
				signals.append({
					"track_index": track_idx,
					"track_type": track_type,
					"signal_data": track_signal,
					"track_path": anim.track_get_path(track_idx)
				})
	
	print("🔬 Extraídas %d señales de transformación" % signals.size())
	return signals

func _extract_track_signal(anim: Animation, track_idx: int) -> Array:
	"""Extraer señal de datos de un track específico"""
	var signal_data = []
	var key_count = anim.track_get_key_count(track_idx)
	
	if key_count < 2:
		return signal_data
	
	# ✅ EXTRAER DATOS DE CADA KEYFRAME
	for key_idx in range(key_count):
		var key_time = anim.track_get_key_time(track_idx, key_idx)
		var key_value = anim.track_get_key_value(track_idx, key_idx)
		
		# Convertir valor a magnitud para análisis de frecuencia
		var magnitude = _calculate_value_magnitude(key_value)
		
		signal_data.append({
			"time": key_time,
			"magnitude": magnitude,
			"original_value": key_value
		})
	
	return signal_data

func _calculate_value_magnitude(value) -> float:
	"""Calcular magnitud de un valor de keyframe"""
	if value is Vector3:
		return value.length()
	elif value is Quaternion:
		# Para rotaciones, usar ángulo de rotación
		return abs(value.get_angle())
	elif value is float:
		return abs(value)
	elif value is int:
		return abs(float(value))
	else:
		return 1.0  # Fallback

func _perform_frequency_analysis_on_signal(transform_signal: Dictionary, animation_length: float) -> Dictionary:
	"""Realizar análisis de frecuencia en una señal de transformación"""
	var analysis = {
		"has_dominant_frequency": false,
		"dominant_frequency": 0.0,
		"frequency_strength": 0.0,
		"harmonic_content": {},
		"frequency_spectrum": []
	}
	
	var signal_data = transform_signal.signal_data
	if signal_data.size() < 3:
		return analysis
	
	# ✅ ANÁLISIS BÁSICO DE FRECUENCIA usando diferencias temporales
	var time_intervals = []
	var magnitude_changes = []
	
	for i in range(1, signal_data.size()):
		var time_diff = signal_data[i].time - signal_data[i-1].time
		var magnitude_diff = abs(signal_data[i].magnitude - signal_data[i-1].magnitude)
		
		if time_diff > 0.001:  # Evitar divisiones por cero
			time_intervals.append(time_diff)
			magnitude_changes.append(magnitude_diff)
	
	if time_intervals.is_empty():
		return analysis
	
	# ✅ DETECTAR FRECUENCIA DOMINANTE
	var dominant_interval = _find_most_common_interval(time_intervals)
	if dominant_interval > 0.0:
		analysis.dominant_frequency = 1.0 / dominant_interval
		analysis.has_dominant_frequency = true
		
		# ✅ CALCULAR FUERZA DE LA FRECUENCIA
		analysis.frequency_strength = _calculate_frequency_strength(time_intervals, dominant_interval)
		
		# ✅ ANÁLISIS ARMÓNICO BÁSICO
		analysis.harmonic_content = _analyze_harmonic_content(time_intervals, dominant_interval)
	
	return analysis

func _find_most_common_interval(intervals: Array) -> float:
	"""Encontrar el intervalo más común en una array de intervalos"""
	if intervals.is_empty():
		return 0.0
	
	# Crear histograma con bins adaptativos
	var bin_size = 0.01  # 10ms bins
	var histogram = {}
	
	for interval in intervals:
		var bin_key = round(interval / bin_size) * bin_size
		if bin_key in histogram:
			histogram[bin_key] += 1
		else:
			histogram[bin_key] = 1
	
	# Encontrar el bin con mayor frecuencia
	var max_count = 0
	var most_common_interval = 0.0
	
	for bin_key in histogram:
		if histogram[bin_key] > max_count:
			max_count = histogram[bin_key]
			most_common_interval = bin_key
	
	return most_common_interval

func _calculate_frequency_strength(intervals: Array, dominant_interval: float) -> float:
	"""Calcular la fuerza/confianza de una frecuencia dominante"""
	if intervals.is_empty() or dominant_interval <= 0.0:
		return 0.0
	
	var tolerance = dominant_interval * 0.1  # 10% tolerancia
	var matching_intervals = 0
	
	for interval in intervals:
		if abs(interval - dominant_interval) <= tolerance:
			matching_intervals += 1
	
	return float(matching_intervals) / intervals.size()

func _analyze_harmonic_content(intervals: Array, fundamental_interval: float) -> Dictionary:
	"""Analizar contenido armónico de los intervalos"""
	var harmonic_analysis = {
		"fundamental_strength": 0.0,
		"second_harmonic": 0.0,
		"third_harmonic": 0.0,
		"harmonic_ratio": 0.0
	}
	
	if intervals.is_empty() or fundamental_interval <= 0.0:
		return harmonic_analysis
	
	var tolerance = fundamental_interval * 0.15  # 15% tolerancia
	var fundamental_count = 0
	var second_harmonic_count = 0
	var third_harmonic_count = 0
	
	for interval in intervals:
		# Fundamental
		if abs(interval - fundamental_interval) <= tolerance:
			fundamental_count += 1
		# Segunda armónica (mitad del período)
		elif abs(interval - fundamental_interval/2.0) <= tolerance:
			second_harmonic_count += 1
		# Tercera armónica (tercio del período)
		elif abs(interval - fundamental_interval/3.0) <= tolerance:
			third_harmonic_count += 1
	
	var total_intervals = intervals.size()
	if total_intervals > 0:
		harmonic_analysis.fundamental_strength = float(fundamental_count) / total_intervals
		harmonic_analysis.second_harmonic = float(second_harmonic_count) / total_intervals
		harmonic_analysis.third_harmonic = float(third_harmonic_count) / total_intervals
		
		# Ratio armónico general
		var harmonic_content = fundamental_count + second_harmonic_count + third_harmonic_count
		harmonic_analysis.harmonic_ratio = float(harmonic_content) / total_intervals
	
	return harmonic_analysis

func _calculate_frequency_consensus(frequency_analyses: Array) -> Dictionary:
	"""Calcular consenso de múltiples análisis de frecuencia"""
	var consensus = {
		"dominant_fps": 0.0,
		"dominant_frequency": 0.0,
		"consensus_confidence": 0.0,
		"harmonic_strength": 0.0,
		"frequency_distribution": {}
	}
	
	if frequency_analyses.is_empty():
		return consensus
	
	# ✅ RECOPILAR TODAS LAS FRECUENCIAS DETECTADAS
	var all_frequencies = []
	var all_strengths = []
	
	for analysis in frequency_analyses:
		if analysis.has_dominant_frequency:
			all_frequencies.append(analysis.dominant_frequency)
			all_strengths.append(analysis.frequency_strength)
	
	if all_frequencies.is_empty():
		return consensus
	
	# ✅ ENCONTRAR FRECUENCIA DOMINANTE POR CONSENSO
	var frequency_consensus = _find_frequency_consensus(all_frequencies, all_strengths)
	
	consensus.dominant_frequency = frequency_consensus.frequency
	consensus.dominant_fps = frequency_consensus.frequency  # En este contexto, frecuencia = FPS
	consensus.consensus_confidence = frequency_consensus.confidence
	
	# ✅ CALCULAR FUERZA ARMÓNICA PROMEDIO
	var total_harmonic_strength = 0.0
	for analysis in frequency_analyses:
		if analysis.has("harmonic_content"):
			total_harmonic_strength += analysis.harmonic_content.get("harmonic_ratio", 0.0)
	
	if frequency_analyses.size() > 0:
		consensus.harmonic_strength = total_harmonic_strength / frequency_analyses.size()
	
	return consensus

func _find_frequency_consensus(frequencies: Array, strengths: Array) -> Dictionary:
	"""Encontrar consenso entre múltiples frecuencias detectadas"""
	var consensus_result = {
		"frequency": 0.0,
		"confidence": 0.0
	}
	
	if frequencies.is_empty():
		return consensus_result
	
	# ✅ AGRUPAR FRECUENCIAS SIMILARES
	var frequency_groups = _group_similar_frequencies(frequencies, strengths)
	
	# ✅ ENCONTRAR EL GRUPO MÁS FUERTE
	var strongest_group = null
	var max_group_strength = 0.0
	
	for group in frequency_groups:
		if group.total_strength > max_group_strength:
			max_group_strength = group.total_strength
			strongest_group = group
	
	if strongest_group:
		consensus_result.frequency = strongest_group.average_frequency
		consensus_result.confidence = min(1.0, strongest_group.total_strength / frequencies.size())
	
	return consensus_result

func _group_similar_frequencies(frequencies: Array, strengths: Array) -> Array:
	"""Agrupar frecuencias similares para consenso"""
	var groups = []
	
	if frequencies.size() != strengths.size():
		return groups
	
	var tolerance_percent = 0.1  # 10% tolerancia
	
	for i in range(frequencies.size()):
		var freq = frequencies[i]
		var strength = strengths[i]
		var placed_in_group = false
		
		# ✅ INTENTAR COLOCAR EN GRUPO EXISTENTE
		for group in groups:
			var tolerance = group.average_frequency * tolerance_percent
			if abs(freq - group.average_frequency) <= tolerance:
				# Agregar a grupo existente
				group.frequencies.append(freq)
				group.strengths.append(strength)
				group.total_strength += strength
				
				# Recalcular promedio
				var freq_sum = 0.0
				for group_freq in group.frequencies:
					freq_sum += group_freq
				group.average_frequency = freq_sum / group.frequencies.size()
				
				placed_in_group = true
				break
		
		# ✅ CREAR NUEVO GRUPO SI NO SE COLOCÓ
		if not placed_in_group:
			groups.append({
				"average_frequency": freq,
				"frequencies": [freq],
				"strengths": [strength],
				"total_strength": strength
			})
	
	return groups



# ========================================================================
# FUNCIONES DE ANÁLISIS BÁSICO FALTANTES
# ========================================================================

func _analyze_basic_timing_advanced(anim: Animation, analysis: Dictionary):
	"""Análisis básico de timing con validaciones avanzadas"""
	if not anim:
		return
	
	# ✅ ANÁLISIS DE STEP BÁSICO
	if anim.step > 0:
		analysis.step_fps = 1.0 / anim.step
		analysis.real_frames = int(anim.length / anim.step)
	else:
		analysis.step_fps = 0.0
		analysis.real_frames = 0
	
	# ✅ ANÁLISIS DE TRACKS BÁSICO
	analysis.track_count = anim.get_track_count()
	analysis.total_keyframes = 0
	
	for track_idx in range(anim.get_track_count()):
		analysis.total_keyframes += anim.track_get_key_count(track_idx)
	
	# ✅ DENSIDAD DE KEYFRAMES
	if analysis.length > 0:
		analysis.keyframe_density = analysis.total_keyframes / analysis.length

# ========================================================================
# FUNCIONES DE ANÁLISIS DE GAPS FALTANTES
# ========================================================================

func _analyze_gap_pattern(gaps: Array) -> Dictionary:
	"""Analizar patrón en gaps de interpolación"""
	if gaps.is_empty():
		return {"pattern_type": "none", "confidence": 0.0}
	
	var avg_gap = 0.0
	for gap in gaps:
		avg_gap += gap
	avg_gap /= gaps.size()
	
	return {
		"pattern_type": "regular" if _is_regular_pattern(gaps) else "irregular",
		"average_gap": avg_gap,
		"confidence": 0.8 if _is_regular_pattern(gaps) else 0.3
	}

func _calculate_comprehensive_gap_statistics(gaps: Array, animation_length: float) -> Dictionary:
	"""Calcular estadísticas comprehensivas de gaps"""
	if gaps.is_empty():
		return {"has_consistent_pattern": false}
	
	gaps.sort()
	var median_gap = gaps[gaps.size() / 2]
	var gap_variance = _calculate_variance(gaps)
	
	return {
		"has_consistent_pattern": gap_variance < 0.001,
		"dominant_gap": median_gap,
		"pattern_confidence": 0.9 - gap_variance * 10.0,
		"gap_count": gaps.size(),
		"total_coverage": gaps.size() * median_gap / animation_length
	}

# ========================================================================
# FUNCIONES DE ANÁLISIS DE MOTION SIGNATURE FALTANTES
# ========================================================================

func _create_comprehensive_motion_signature(anim: Animation) -> Dictionary:
	"""Crear firma única del movimiento de la animación"""
	var signature = {
		"position_signature": [],
		"rotation_signature": [],
		"scale_signature": [],
		"combined_signature": [],
		"signature_length": 0
	}
	
	if not anim or anim.get_track_count() == 0:
		return signature
	
	# ✅ CREAR FIRMA POR TIPO DE TRACK
	for track_idx in range(anim.get_track_count()):
		var track_type = anim.track_get_type(track_idx)
		var track_signature = _create_track_signature(anim, track_idx)
		
		match track_type:
			Animation.TYPE_POSITION_3D:
				signature.position_signature.append(track_signature)
			Animation.TYPE_ROTATION_3D:
				signature.rotation_signature.append(track_signature)
			Animation.TYPE_SCALE_3D:
				signature.scale_signature.append(track_signature)
	
	# ✅ COMBINAR FIRMAS EN UNA FIRMA UNIFICADA
	signature.combined_signature = _combine_track_signatures([
		signature.position_signature,
		signature.rotation_signature, 
		signature.scale_signature
	])
	
	signature.signature_length = signature.combined_signature.size()
	return signature

func _create_track_signature(anim: Animation, track_idx: int) -> Array:
	"""Crear firma de un track individual"""
	var signature = []
	var key_count = anim.track_get_key_count(track_idx)
	
	for key_idx in range(key_count):
		var key_time = anim.track_get_key_time(track_idx, key_idx)
		var key_value = anim.track_get_key_value(track_idx, key_idx)
		var magnitude = _calculate_value_magnitude(key_value)
		
		signature.append({
			"time": key_time,
			"magnitude": magnitude,
			"normalized_time": key_time / anim.length
		})
	
	return signature

func _combine_track_signatures(signature_groups: Array) -> Array:
	"""Combinar múltiples firmas de tracks en una firma unificada"""
	var combined = []
	var all_points = []
	
	# Recopilar todos los puntos temporales
	for group in signature_groups:
		for track_signature in group:
			for point in track_signature:
				all_points.append(point)
	
	# Ordenar por tiempo
	all_points.sort_custom(func(a, b): return a.time < b.time)
	
	return all_points

func _find_repetitive_patterns_in_signature(signature: Dictionary, animation_length: float) -> Array:
	"""Encontrar patrones repetitivos en la firma de movimiento"""
	var patterns = []
	var combined_signature = signature.combined_signature
	
	if combined_signature.size() < 4:
		return patterns
	
	# ✅ BUSCAR PATRONES DE DIFERENTES LONGITUDES
	var max_pattern_length = min(combined_signature.size() / 2, 10)
	
	for pattern_length in range(2, max_pattern_length + 1):
		var pattern = _find_pattern_of_length(combined_signature, pattern_length, animation_length)
		if pattern.strength > 0.5:
			patterns.append(pattern)
	
	return patterns

func _find_pattern_of_length(signature: Array, pattern_length: int, animation_length: float) -> Dictionary:
	"""Buscar un patrón de longitud específica en la firma"""
	var pattern_result = {
		"length": pattern_length,
		"strength": 0.0,
		"repetitions": 0,
		"pattern_interval": 0.0
	}
	
	if signature.size() < pattern_length * 2:
		return pattern_result
	
	var best_pattern_strength = 0.0
	var best_interval = 0.0
	
	# ✅ PROBAR DIFERENTES INTERVALOS
	var max_repetitions = int(animation_length * 10)  # Hasta 10 Hz
	
	for repetitions in range(2, max_repetitions + 1):
		var interval = animation_length / repetitions
		var pattern_strength = _calculate_pattern_strength_at_interval(signature, interval, pattern_length)
		
		if pattern_strength > best_pattern_strength:
			best_pattern_strength = pattern_strength
			best_interval = interval
			pattern_result.repetitions = repetitions
	
	pattern_result.strength = best_pattern_strength
	pattern_result.pattern_interval = best_interval
	
	return pattern_result

func _calculate_pattern_strength_at_interval(signature: Array, interval: float, pattern_length: int) -> float:
	"""Calcular la fuerza de un patrón en un intervalo específico"""
	if signature.size() < pattern_length or interval <= 0:
		return 0.0
	
	var matches = 0
	var total_comparisons = 0
	var tolerance = interval * 0.1  # 10% tolerancia
	
	# Comparar puntos separados por el intervalo
	for i in range(signature.size() - pattern_length):
		for j in range(pattern_length):
			if i + j >= signature.size():
				break
			
			var current_point = signature[i + j]
			var expected_time = current_point.time + interval
			
			# Buscar punto correspondiente en el siguiente ciclo
			var found_match = false
			for k in range(signature.size()):
				var compare_point = signature[k]
				if abs(compare_point.time - expected_time) <= tolerance:
					var magnitude_diff = abs(compare_point.magnitude - current_point.magnitude)
					if magnitude_diff <= current_point.magnitude * 0.2:  # 20% tolerancia magnitud
						matches += 1
					found_match = true
					break
			
			total_comparisons += 1
			
			if not found_match:
				break
	
	return float(matches) / max(1, total_comparisons)

func _find_strongest_repetitive_pattern(patterns: Array) -> Dictionary:
	"""Encontrar el patrón repetitivo más fuerte"""
	if patterns.is_empty():
		return {"strength": 0.0}
	
	var strongest_pattern = patterns[0]
	
	for pattern in patterns:
		if pattern.strength > strongest_pattern.strength:
			strongest_pattern = pattern
	
	return strongest_pattern

# ========================================================================
# FUNCIONES DE METADATOS FBX FALTANTES
# ========================================================================

func _extract_fbx_metadata_from_path(anim_name: String) -> Dictionary:
	"""Extraer metadatos FBX del nombre/path de animación"""
	var metadata = {
		"has_fps_hint": false,
		"suggested_fps": 0.0,
		"confidence": 0.0,
		"source_hints": []
	}
	
	if anim_name.is_empty():
		return metadata
	
	# ✅ BUSCAR INDICADORES DE FPS EN EL NOMBRE
	var fps_patterns = ["24fps", "30fps", "60fps", "24f", "30f", "60f", "_24", "_30", "_60"]
	
	for pattern in fps_patterns:
		if pattern in anim_name.to_lower():
			metadata.has_fps_hint = true
			metadata.suggested_fps = float(pattern.replace("fps", "").replace("f", "").replace("_", ""))
			metadata.confidence = 0.7
			metadata.source_hints.append("filename_pattern")
			break
	
	# ✅ BUSCAR OTROS INDICADORES
	if "cinema" in anim_name.to_lower() or "film" in anim_name.to_lower():
		metadata.suggested_fps = 24.0
		metadata.confidence = 0.6
		metadata.source_hints.append("cinema_context")
	elif "tv" in anim_name.to_lower() or "broadcast" in anim_name.to_lower():
		metadata.suggested_fps = 30.0
		metadata.confidence = 0.6
		metadata.source_hints.append("broadcast_context")
	
	return metadata

func _analyze_animation_internal_properties(anim: Animation) -> Dictionary:
	"""Analizar propiedades internas de la animación"""
	var properties = {
		"has_step_info": false,
		"step_consistency": 0.0,
		"track_consistency": 0.0,
		"interpolation_hints": {},
		"quality_indicators": []
	}
	
	if not anim:
		return properties
	
	# ✅ ANÁLISIS DE STEP
	properties.has_step_info = anim.step > 0
	if properties.has_step_info:
		properties.step_consistency = 1.0  # Step existe
		properties.quality_indicators.append("has_step_timing")
	
	# ✅ ANÁLISIS DE CONSISTENCIA DE TRACKS
	var track_intervals = []
	for track_idx in range(anim.get_track_count()):
		var key_count = anim.track_get_key_count(track_idx)
		if key_count > 1:
			var first_time = anim.track_get_key_time(track_idx, 0)
			var last_time = anim.track_get_key_time(track_idx, key_count - 1)
			var avg_interval = (last_time - first_time) / (key_count - 1)
			track_intervals.append(avg_interval)
	
	if track_intervals.size() > 1:
		var variance = _calculate_variance(track_intervals)
		var mean = _calculate_mean(track_intervals)
		properties.track_consistency = 1.0 - min(1.0, variance / max(0.001, mean))
	
	return properties

# ========================================================================
# FUNCIONES DE CONSENSO FALTANTES
# ========================================================================

func _group_results_by_fps_similarity(results: Array) -> Array:
	"""Agrupar resultados por similitud de FPS"""
	var groups = []
	var tolerance = 0.1  # Tolerancia de 0.1 FPS
	
	for result in results:
		if result.fps <= 0:
			continue
		
		var placed_in_group = false
		
		for group in groups:
			if abs(result.fps - group.average_fps) <= tolerance:
				group.results.append(result)
				group.total_confidence += result.confidence
				
				# Recalcular promedio ponderado
				var weighted_sum = 0.0
				var confidence_sum = 0.0
				for r in group.results:
					weighted_sum += r.fps * r.confidence
					confidence_sum += r.confidence
				
				if confidence_sum > 0:
					group.average_fps = weighted_sum / confidence_sum
				
				placed_in_group = true
				break
		
		if not placed_in_group:
			groups.append({
				"average_fps": result.fps,
				"results": [result],
				"total_confidence": result.confidence,
				"group_size": 1
			})
	
	# Actualizar tamaños de grupo
	for group in groups:
		group.group_size = group.results.size()
	
	return groups

func _select_dominant_fps_group(groups: Array) -> Dictionary:
	"""Seleccionar el grupo de FPS dominante"""
	if groups.is_empty():
		return {"fps": 30.0, "confidence": 0.0}
	
	var best_group = null
	var best_score = 0.0
	
	for group in groups:
		# Score basado en confianza total y tamaño del grupo
		var score = group.total_confidence * (1.0 + group.group_size * 0.1)
		
		if score > best_score:
			best_score = score
			best_group = group
	
	if best_group:
		return {
			"fps": best_group.average_fps,
			"confidence": min(1.0, best_group.total_confidence / best_group.group_size),
			"group_size": best_group.group_size,
			"methods_used": best_group.results.map(func(r): return r.method_name)
		}
	
	return {"fps": 30.0, "confidence": 0.0}

func _calculate_consensus_confidence(consensus_result: Dictionary, detection_results: Array) -> float:
	"""Calcular confianza del consenso"""
	if detection_results.is_empty():
		return 0.0
	
	var methods_agreeing = 0
	var total_confidence = 0.0
	var tolerance = 0.5  # Tolerancia de 0.5 FPS para considerar acuerdo
	
	for result in detection_results:
		if abs(result.fps - consensus_result.fps) <= tolerance:
			methods_agreeing += 1
			total_confidence += result.confidence
	
	var agreement_ratio = float(methods_agreeing) / detection_results.size()
	var average_confidence = total_confidence / max(1, methods_agreeing)
	
	# Combinar ratio de acuerdo con confianza promedio
	return (agreement_ratio * 0.7) + (average_confidence * 0.3)

func _perform_cross_validation(detection_results: Array, consensus_result: Dictionary) -> Dictionary:
	"""Realizar validación cruzada de resultados"""
	var validation = {
		"passed": true,
		"validation_score": 0.0,
		"issues_found": [],
		"quality_assessment": "high"
	}
	
	if detection_results.size() < 2:
		validation.issues_found.append("insufficient_methods")
		validation.quality_assessment = "low"
		validation.validation_score = 0.3
		return validation
	
	# ✅ VALIDAR CONSISTENCIA ENTRE MÉTODOS
	var consistent_methods = 0
	var tolerance = 1.0  # Tolerancia de 1 FPS
	
	for result in detection_results:
		if abs(result.fps - consensus_result.fps) <= tolerance:
			consistent_methods += 1
	
	var consistency_ratio = float(consistent_methods) / detection_results.size()
	
	# ✅ VALIDAR CONFIANZA GENERAL
	var total_confidence = 0.0
	for result in detection_results:
		total_confidence += result.confidence
	
	var average_confidence = total_confidence / detection_results.size()
	
	# ✅ CALCULAR SCORE DE VALIDACIÓN
	validation.validation_score = (consistency_ratio * 0.6) + (average_confidence * 0.4)
	
	if validation.validation_score >= 0.8:
		validation.quality_assessment = "high"
	elif validation.validation_score >= 0.6:
		validation.quality_assessment = "medium"
	else:
		validation.quality_assessment = "low"
		validation.issues_found.append("low_consensus")
	
	validation.passed = validation.validation_score >= 0.5
	
	return validation

# ========================================================================
# FUNCIONES DE ANÁLISIS PROFUNDO DE KEYFRAMES FALTANTES
# ========================================================================

func _analyze_single_track_ultra_deep(anim: Animation, track_idx: int) -> Dictionary:
	"""Análisis ultra-profundo de un track individual"""
	var analysis = {
		"track_index": track_idx,
		"track_type": anim.track_get_type(track_idx),
		"key_count": anim.track_get_key_count(track_idx),
		"timing_analysis": {},
		"value_analysis": {},
		"quality_score": 0.0
	}
	
	if analysis.key_count < 2:
		return analysis
	
	# ✅ ANÁLISIS DE TIMING
	var key_times = []
	var key_values = []
	
	for key_idx in range(analysis.key_count):
		key_times.append(anim.track_get_key_time(track_idx, key_idx))
		key_values.append(anim.track_get_key_value(track_idx, key_idx))
	
	analysis.timing_analysis = _analyze_key_timing_distribution(key_times, anim.length)
	analysis.value_analysis = _analyze_key_value_distribution(key_values)
	
	# ✅ CALCULAR SCORE DE CALIDAD
	analysis.quality_score = _calculate_track_quality_score(analysis)
	
	return analysis

func _analyze_key_timing_distribution(key_times: Array, animation_length: float) -> Dictionary:
	"""Analizar distribución temporal de keyframes"""
	var timing_analysis = {
		"uniformity": 0.0,
		"intervals": [],
		"interval_variance": 0.0,
		"coverage": 0.0
	}
	
	if key_times.size() < 2:
		return timing_analysis
	
	# ✅ CALCULAR INTERVALOS
	for i in range(1, key_times.size()):
		timing_analysis.intervals.append(key_times[i] - key_times[i-1])
	
	# ✅ ANÁLISIS DE UNIFORMIDAD
	if timing_analysis.intervals.size() > 0:
		var mean_interval = _calculate_mean(timing_analysis.intervals)
		timing_analysis.interval_variance = _calculate_variance(timing_analysis.intervals)
		
		if mean_interval > 0:
			timing_analysis.uniformity = 1.0 - min(1.0, timing_analysis.interval_variance / mean_interval)
	
	# ✅ COBERTURA TEMPORAL
	if animation_length > 0:
		timing_analysis.coverage = (key_times[-1] - key_times[0]) / animation_length
	
	return timing_analysis

func _analyze_key_value_distribution(key_values: Array) -> Dictionary:
	"""Analizar distribución de valores de keyframes"""
	var value_analysis = {
		"value_range": 0.0,
		"value_variance": 0.0,
		"smooth_transitions": 0.0,
		"value_type": "unknown"
	}
	
	if key_values.is_empty():
		return value_analysis
	
	# ✅ DETERMINAR TIPO DE VALOR
	var first_value = key_values[0]
	if first_value is Vector3:
		value_analysis.value_type = "Vector3"
		value_analysis = _analyze_vector3_values(key_values)
	elif first_value is Quaternion:
		value_analysis.value_type = "Quaternion"
		value_analysis = _analyze_quaternion_values(key_values)
	elif first_value is float or first_value is int:
		value_analysis.value_type = "scalar"
		value_analysis = _analyze_scalar_values(key_values)
	
	return value_analysis

func _analyze_vector3_values(values: Array) -> Dictionary:
	"""Analizar valores Vector3"""
	var analysis = {
		"value_type": "Vector3",
		"magnitude_range": 0.0,
		"direction_changes": 0,
		"smooth_transitions": 0.0
	}
	
	if values.size() < 2:
		return analysis
	
	var magnitudes = []
	var direction_changes = 0
	
	for i in range(values.size()):
		var vec = values[i] as Vector3
		magnitudes.append(vec.length())
		
		if i > 0:
			var prev_vec = values[i-1] as Vector3
			if prev_vec.length() > 0 and vec.length() > 0:
				var dot_product = prev_vec.normalized().dot(vec.normalized())
				if dot_product < 0.8:  # Cambio significativo de dirección
					direction_changes += 1
	
	analysis.magnitude_range = magnitudes.max() - magnitudes.min()
	analysis.direction_changes = direction_changes
	analysis.smooth_transitions = 1.0 - (float(direction_changes) / max(1, values.size() - 1))
	
	return analysis

func _analyze_quaternion_values(values: Array) -> Dictionary:
	"""Analizar valores Quaternion"""
	var analysis = {
		"value_type": "Quaternion",
		"angle_range": 0.0,
		"rotation_changes": 0,
		"smooth_transitions": 0.0
	}
	
	if values.size() < 2:
		return analysis
	
	var angles = []
	var significant_changes = 0
	
	for i in range(values.size()):
		var quat = values[i] as Quaternion
		angles.append(quat.get_angle())
		
		if i > 0:
			var prev_quat = values[i-1] as Quaternion
			var angle_diff = abs(quat.get_angle() - prev_quat.get_angle())
			if angle_diff > 0.1:  # Cambio significativo
				significant_changes += 1
	
	analysis.angle_range = angles.max() - angles.min()
	analysis.rotation_changes = significant_changes
	analysis.smooth_transitions = 1.0 - (float(significant_changes) / max(1, values.size() - 1))
	
	return analysis

func _analyze_scalar_values(values: Array) -> Dictionary:
	"""Analizar valores escalares"""
	var analysis = {
		"value_type": "scalar",
		"value_range": 0.0,
		"variance": 0.0,
		"smooth_transitions": 0.0
	}
	
	if values.is_empty():
		return analysis
	
	var float_values = []
	for val in values:
		float_values.append(float(val))
	
	analysis.value_range = float_values.max() - float_values.min()
	analysis.variance = _calculate_variance(float_values)
	
	# Calcular suavidad de transiciones
	var abrupt_changes = 0
	for i in range(1, float_values.size()):
		var change = abs(float_values[i] - float_values[i-1])
		if change > analysis.value_range * 0.3:  # Cambio mayor al 30% del rango
			abrupt_changes += 1
	
	analysis.smooth_transitions = 1.0 - (float(abrupt_changes) / max(1, float_values.size() - 1))
	
	return analysis

func _calculate_track_quality_score(track_analysis: Dictionary) -> float:
	"""Calcular score de calidad de un track"""
	var base_score = 70.0
	
	# Bonus por uniformidad temporal
	if track_analysis.timing_analysis.has("uniformity"):
		base_score += track_analysis.timing_analysis.uniformity * 20.0
	
	# Bonus por transiciones suaves
	if track_analysis.value_analysis.has("smooth_transitions"):
		base_score += track_analysis.value_analysis.smooth_transitions * 10.0
	
	return min(100.0, base_score)

func _update_keyframe_density_map(analysis: Dictionary, track_analysis: Dictionary):
	"""Actualizar mapa de densidad de keyframes"""
	if not analysis.has("keyframe_density_map"):
		analysis.keyframe_density_map = {}
	
	var track_idx = track_analysis.track_index
	var density = float(track_analysis.key_count) / max(0.001, analysis.length)
	
	analysis.keyframe_density_map[track_idx] = {
		"density": density,
		"quality_score": track_analysis.quality_score,
		"key_count": track_analysis.key_count
	}

func _analyze_temporal_distribution(analysis: Dictionary):
	"""Analizar distribución temporal global"""
	if not analysis.has("keyframe_density_map"):
		return
	
	var temporal_analysis = {
		"average_density": 0.0,
		"density_variance": 0.0,
		"hotspots": [],
		"distribution_quality": 0.0
	}
	
	var densities = []
	for track_idx in analysis.keyframe_density_map:
		densities.append(analysis.keyframe_density_map[track_idx].density)
	
	if densities.size() > 0:
		temporal_analysis.average_density = _calculate_mean(densities)
		temporal_analysis.density_variance = _calculate_variance(densities)
		
		# Calcular calidad de distribución
		if temporal_analysis.average_density > 0:
			temporal_analysis.distribution_quality = 1.0 - min(1.0, 
				temporal_analysis.density_variance / temporal_analysis.average_density)
	
	analysis.temporal_distribution = temporal_analysis

func _analyze_bone_hierarchy_timing(anim: Animation, analysis: Dictionary):
	"""Analizar timing de jerarquía de huesos"""
	var hierarchy_analysis = {
		"bone_tracks": [],
		"hierarchy_consistency": 0.0,
		"synchronized_bones": 0
	}
	
	# ✅ IDENTIFICAR TRACKS DE HUESOS
	for track_idx in range(anim.get_track_count()):
		var track_path = str(anim.track_get_path(track_idx))
		if "Skeleton3D" in track_path or "Armature" in track_path:
			hierarchy_analysis.bone_tracks.append({
				"track_index": track_idx,
				"path": track_path,
				"key_count": anim.track_get_key_count(track_idx)
			})
	
	# ✅ ANALIZAR CONSISTENCIA DE JERARQUÍA
	if hierarchy_analysis.bone_tracks.size() > 1:
		var key_counts = hierarchy_analysis.bone_tracks.map(func(bt): return bt.key_count)
		var count_variance = _calculate_variance(key_counts)
		var count_mean = _calculate_mean(key_counts)
		
		if count_mean > 0:
			hierarchy_analysis.hierarchy_consistency = 1.0 - min(1.0, count_variance / count_mean)
	
	analysis.bone_hierarchy_analysis = hierarchy_analysis

func _calculate_keyframe_quality_metrics(analysis: Dictionary):
	"""Calcular métricas de calidad de keyframes"""
	var quality_metrics = {
		"overall_quality": 0.0,
		"timing_quality": 0.0,
		"distribution_quality": 0.0,
		"consistency_quality": 0.0
	}
	
	# ✅ CALIDAD DE DISTRIBUCIÓN TEMPORAL
	if analysis.has("temporal_distribution"):
		quality_metrics.distribution_quality = analysis.temporal_distribution.distribution_quality
	
	# ✅ CALIDAD DE CONSISTENCIA DE JERARQUÍA
	if analysis.has("bone_hierarchy_analysis"):
		quality_metrics.consistency_quality = analysis.bone_hierarchy_analysis.hierarchy_consistency
	
	# ✅ CALIDAD GENERAL PROMEDIO
	var quality_values = [
		quality_metrics.timing_quality,
		quality_metrics.distribution_quality,
		quality_metrics.consistency_quality
	]
	
	var valid_qualities = quality_values.filter(func(q): return q > 0)
	if valid_qualities.size() > 0:
		quality_metrics.overall_quality = _calculate_mean(valid_qualities)
	
	analysis.keyframe_quality_metrics = quality_metrics

# ========================================================================
# FUNCIONES DE ANÁLISIS DE INTERVALOS Y DISTRIBUCIONES FALTANTES
# ========================================================================

func _analyze_interval_distribution(intervals: Array) -> Dictionary:
	"""Analizar distribución de intervalos entre keyframes"""
	var distribution = {
		"has_dominant_interval": false,
		"dominant_interval": 0.0,
		"dominance_strength": 0.0,
		"pattern_type": "irregular",
		"uniformity_score": 0.0
	}
	
	if intervals.size() < 3:
		return distribution
	
	# ✅ ENCONTRAR INTERVALO DOMINANTE
	var histogram = _create_simple_histogram(intervals, 20)  # 20 bins
	var max_frequency = 0
	var dominant_bin = 0.0
	
	for bin_value in histogram:
		if histogram[bin_value] > max_frequency:
			max_frequency = histogram[bin_value]
			dominant_bin = bin_value
	
	if max_frequency > intervals.size() * 0.3:  # Al menos 30% de los intervalos
		distribution.has_dominant_interval = true
		distribution.dominant_interval = dominant_bin
		distribution.dominance_strength = float(max_frequency) / intervals.size()
		distribution.pattern_type = "regular"
	
	# ✅ CALCULAR UNIFORMIDAD
	var mean_interval = _calculate_mean(intervals)
	var variance = _calculate_variance(intervals)
	
	if mean_interval > 0:
		distribution.uniformity_score = 1.0 - min(1.0, variance / mean_interval)
	
	return distribution

func _create_simple_histogram(values: Array, bin_count: int) -> Dictionary:
	"""Crear histograma simple de valores"""
	var histogram = {}
	
	if values.is_empty():
		return histogram
	
	var min_val = values.min()
	var max_val = values.max()
	var bin_size = (max_val - min_val) / bin_count
	
	if bin_size == 0:
		histogram[min_val] = values.size()
		return histogram
	
	for value in values:
		var bin_index = int((value - min_val) / bin_size)
		bin_index = min(bin_index, bin_count - 1)  # Asegurar que no exceda
		var bin_center = min_val + (bin_index + 0.5) * bin_size
		
		if bin_center in histogram:
			histogram[bin_center] += 1
		else:
			histogram[bin_center] = 1
	
	return histogram

func _analyze_distribution_shape(intervals: Array, mean: float, std_deviation: float) -> Dictionary:
	"""Analizar forma de la distribución"""
	var shape_analysis = {
		"shape_type": "unknown",
		"skewness": 0.0,
		"kurtosis": 0.0,
		"normality_score": 0.0
	}
	
	if intervals.size() < 5:
		return shape_analysis
	
	# ✅ CALCULAR SKEWNESS (asimetría)
	var skewness_sum = 0.0
	for interval in intervals:
		if std_deviation > 0:
			skewness_sum += pow((interval - mean) / std_deviation, 3)
	
	shape_analysis.skewness = skewness_sum / intervals.size()
	
	# ✅ CALCULAR KURTOSIS
	var kurtosis_sum = 0.0
	for interval in intervals:
		if std_deviation > 0:
			kurtosis_sum += pow((interval - mean) / std_deviation, 4)
	
	shape_analysis.kurtosis = (kurtosis_sum / intervals.size()) - 3.0  # Excess kurtosis
	
	# ✅ CLASIFICAR FORMA
	if abs(shape_analysis.skewness) < 0.5 and abs(shape_analysis.kurtosis) < 0.5:
		shape_analysis.shape_type = "normal"
		shape_analysis.normality_score = 0.9
	elif shape_analysis.skewness > 0.5:
		shape_analysis.shape_type = "right_skewed"
		shape_analysis.normality_score = 0.3
	elif shape_analysis.skewness < -0.5:
		shape_analysis.shape_type = "left_skewed"
		shape_analysis.normality_score = 0.3
	else:
		shape_analysis.shape_type = "irregular"
		shape_analysis.normality_score = 0.1
	
	return shape_analysis

func _calculate_adaptive_bin_size(intervals: Array) -> float:
	"""Calcular tamaño de bin adaptativo para histogramas"""
	if intervals.size() < 3:
		return 0.01  # Bin size por defecto
	
	# Usar regla de Sturges modificada
	var n = intervals.size()
	var suggested_bins = max(5, int(log(n) / log(2)) + 1)
	
	var min_val = intervals.min()
	var max_val = intervals.max()
	var range_val = max_val - min_val
	
	if range_val == 0:
		return 0.01
	
	return range_val / suggested_bins

func _create_interval_histogram(intervals: Array, bin_size: float) -> Dictionary:
	"""Crear histograma de intervalos con tamaño de bin específico"""
	var histogram = {}
	
	if intervals.is_empty() or bin_size <= 0:
		return histogram
	
	for interval in intervals:
		var bin_center = round(interval / bin_size) * bin_size
		
		if bin_center in histogram:
			histogram[bin_center] += 1
		else:
			histogram[bin_center] = 1
	
	return histogram

func _calculate_pattern_coherence(intervals: Array, dominant_interval: float, bin_size: float) -> float:
	"""Calcular coherencia del patrón dominante"""
	if intervals.is_empty() or dominant_interval <= 0 or bin_size <= 0:
		return 0.0
	
	var tolerance = bin_size * 0.5
	var coherent_intervals = 0
	
	for interval in intervals:
		if abs(interval - dominant_interval) <= tolerance:
			coherent_intervals += 1
	
	return float(coherent_intervals) / intervals.size()



# ========================================================================
# FUNCIONES DE ANÁLISIS DE VELOCIDAD DE HUESOS COMPLETAS
# ========================================================================

func _analyze_bone_track_velocity(anim: Animation, track_idx: int, sample_count: int) -> Array:
	"""Analizar velocidad de movimiento de un track de hueso con muestreo detallado"""
	var velocity_data = []
	
	if not anim or track_idx >= anim.get_track_count() or sample_count < 2:
		return velocity_data
	
	var track_type = anim.track_get_type(track_idx)
	var key_count = anim.track_get_key_count(track_idx)
	
	if key_count < 2:
		return velocity_data
	
	# ✅ MUESTREO UNIFORME A LO LARGO DE LA ANIMACIÓN
	var time_step = anim.length / (sample_count - 1)
	var previous_value = null
	var previous_time = 0.0
	
	for sample_idx in range(sample_count):
		var sample_time = sample_idx * time_step
		var current_value = _interpolate_track_value_at_time(anim, track_idx, sample_time)
		
		if sample_idx > 0 and previous_value != null and current_value != null:
			var time_delta = sample_time - previous_time
			var velocity = _calculate_value_velocity(previous_value, current_value, time_delta)
			
			velocity_data.append({
				"time": sample_time,
				"velocity_magnitude": velocity,
				"time_delta": time_delta,
				"track_type": track_type
			})
		
		previous_value = current_value
		previous_time = sample_time
	
	return velocity_data

func _interpolate_track_value_at_time(anim: Animation, track_idx: int, time: float):
	"""Interpolar valor de track en un tiempo específico"""
	var key_count = anim.track_get_key_count(track_idx)
	
	if key_count == 0:
		return null
	
	if key_count == 1:
		return anim.track_get_key_value(track_idx, 0)
	
	# ✅ ENCONTRAR KEYS ANTES Y DESPUÉS DEL TIEMPO
	var before_key_idx = -1
	var after_key_idx = -1
	
	for key_idx in range(key_count):
		var key_time = anim.track_get_key_time(track_idx, key_idx)
		
		if key_time <= time:
			before_key_idx = key_idx
		if key_time >= time and after_key_idx == -1:
			after_key_idx = key_idx
			break
	
	# ✅ INTERPOLAR ENTRE KEYS
	if before_key_idx == -1:
		return anim.track_get_key_value(track_idx, 0)
	elif after_key_idx == -1:
		return anim.track_get_key_value(track_idx, key_count - 1)
	elif before_key_idx == after_key_idx:
		return anim.track_get_key_value(track_idx, before_key_idx)
	else:
		var before_time = anim.track_get_key_time(track_idx, before_key_idx)
		var after_time = anim.track_get_key_time(track_idx, after_key_idx)
		var before_value = anim.track_get_key_value(track_idx, before_key_idx)
		var after_value = anim.track_get_key_value(track_idx, after_key_idx)
		
		var t = (time - before_time) / (after_time - before_time)
		return _interpolate_values(before_value, after_value, t)

func _interpolate_values(value1, value2, t: float):
	"""Interpolar entre dos valores según su tipo"""
	if value1 is Vector3 and value2 is Vector3:
		return (value1 as Vector3).lerp(value2 as Vector3, t)
	elif value1 is Quaternion and value2 is Quaternion:
		return (value1 as Quaternion).slerp(value2 as Quaternion, t)
	elif (value1 is float or value1 is int) and (value2 is float or value2 is int):
		return float(value1) + (float(value2) - float(value1)) * t
	else:
		return value2  # Fallback

func _calculate_value_velocity(previous_value, current_value, time_delta: float) -> float:
	"""Calcular velocidad entre dos valores"""
	if time_delta <= 0:
		return 0.0
	
	var magnitude_change = 0.0
	
	if previous_value is Vector3 and current_value is Vector3:
		magnitude_change = (current_value as Vector3).distance_to(previous_value as Vector3)
	elif previous_value is Quaternion and current_value is Quaternion:
		magnitude_change = abs((current_value as Quaternion).get_angle() - (previous_value as Quaternion).get_angle())
	elif (previous_value is float or previous_value is int) and (current_value is float or current_value is int):
		magnitude_change = abs(float(current_value) - float(previous_value))
	else:
		magnitude_change = 0.0
	
	return magnitude_change / time_delta

func _extract_fps_from_velocity_pattern(velocities: Array, length: float) -> Dictionary:
	"""Extraer FPS basado en patrones de velocidad"""
	var result = {
		"fps": 0.0,
		"confidence": 0.0,
		"pattern_strength": 0.0,
		"velocity_analysis": {}
	}
	
	if velocities.size() < 4 or length <= 0:
		return result
	
	# ✅ ANALIZAR PICOS Y VALLES EN LA VELOCIDAD
	var velocity_peaks = _find_velocity_peaks(velocities)
	var velocity_valleys = _find_velocity_valleys(velocities)
	
	# ✅ CALCULAR INTERVALOS ENTRE PICOS
	var peak_intervals = []
	for i in range(1, velocity_peaks.size()):
		var interval = velocity_peaks[i].time - velocity_peaks[i-1].time
		if interval > 0.01:  # Filtrar intervalos muy pequeños
			peak_intervals.append(interval)
	
	if peak_intervals.size() < 2:
		return result
	
	# ✅ ENCONTRAR PATRÓN DOMINANTE EN INTERVALOS
	var dominant_interval = _find_most_common_interval(peak_intervals)
	
	if dominant_interval > 0:
		result.fps = 1.0 / dominant_interval
		result.pattern_strength = _calculate_interval_consistency(peak_intervals, dominant_interval)
		result.confidence = result.pattern_strength * 0.8  # Factor de confianza conservador
		
		result.velocity_analysis = {
			"peak_count": velocity_peaks.size(),
			"valley_count": velocity_valleys.size(),
			"dominant_interval": dominant_interval,
			"interval_consistency": result.pattern_strength,
			"average_velocity": _calculate_average_velocity(velocities)
		}
	
	return result

func _find_velocity_peaks(velocities: Array) -> Array:
	"""Encontrar picos en los datos de velocidad"""
	var peaks = []
	
	if velocities.size() < 3:
		return peaks
	
	# ✅ CALCULAR THRESHOLD DINÁMICO
	var velocity_magnitudes = velocities.map(func(v): return v.velocity_magnitude)
	var mean_velocity = _calculate_mean(velocity_magnitudes)
	var velocity_std = sqrt(_calculate_variance(velocity_magnitudes))
	var threshold = mean_velocity + velocity_std * 0.5  # Picos significativos
	
	# ✅ DETECTAR PICOS LOCALES
	for i in range(1, velocities.size() - 1):
		var current = velocities[i].velocity_magnitude
		var previous = velocities[i-1].velocity_magnitude
		var next = velocities[i+1].velocity_magnitude
		
		if current > previous and current > next and current > threshold:
			peaks.append({
				"index": i,
				"time": velocities[i].time,
				"magnitude": current
			})
	
	return peaks

func _find_velocity_valleys(velocities: Array) -> Array:
	"""Encontrar valles en los datos de velocidad"""
	var valleys = []
	
	if velocities.size() < 3:
		return valleys
	
	# ✅ CALCULAR THRESHOLD DINÁMICO
	var velocity_magnitudes = velocities.map(func(v): return v.velocity_magnitude)
	var mean_velocity = _calculate_mean(velocity_magnitudes)
	var velocity_std = sqrt(_calculate_variance(velocity_magnitudes))
	var threshold = mean_velocity - velocity_std * 0.3  # Valles significativos
	
	# ✅ DETECTAR VALLES LOCALES
	for i in range(1, velocities.size() - 1):
		var current = velocities[i].velocity_magnitude
		var previous = velocities[i-1].velocity_magnitude
		var next = velocities[i+1].velocity_magnitude
		
		if current < previous and current < next and current < threshold:
			valleys.append({
				"index": i,
				"time": velocities[i].time,
				"magnitude": current
			})
	
	return valleys

func _calculate_interval_consistency(intervals: Array, reference_interval: float) -> float:
	"""Calcular consistencia de intervalos respecto a un intervalo de referencia"""
	if intervals.is_empty() or reference_interval <= 0:
		return 0.0
	
	var tolerance = reference_interval * 0.15  # 15% tolerancia
	var consistent_intervals = 0
	
	for interval in intervals:
		if abs(interval - reference_interval) <= tolerance:
			consistent_intervals += 1
	
	return float(consistent_intervals) / intervals.size()

func _calculate_average_velocity(velocities: Array) -> float:
	"""Calcular velocidad promedio"""
	if velocities.is_empty():
		return 0.0
	
	var total_velocity = 0.0
	for velocity_data in velocities:
		total_velocity += velocity_data.velocity_magnitude
	
	return total_velocity / velocities.size()

func _calculate_velocity_consensus(patterns: Array) -> Dictionary:
	"""Crear consenso entre múltiples análisis de velocidad"""
	var consensus = {
		"fps": 0.0,
		"confidence": 0.0,
		"method_agreement": 0.0,
		"dominant_pattern": {},
		"supporting_patterns": []
	}
	
	if patterns.is_empty():
		return consensus
	
	# ✅ FILTRAR PATRONES VÁLIDOS
	var valid_patterns = patterns.filter(func(p): return p.confidence > 0.3 and p.fps > 1.0 and p.fps < 240.0)
	
	if valid_patterns.is_empty():
		return consensus
	
	# ✅ AGRUPAR PATRONES SIMILARES
	var fps_groups = _group_similar_fps_values(valid_patterns.map(func(p): return p.fps))
	
	# ✅ SELECCIONAR GRUPO DOMINANTE
	var best_group = null
	var best_score = 0.0
	
	for group in fps_groups:
		# Calcular score ponderado por confianza
		var total_confidence = 0.0
		var pattern_count = 0
		
		for pattern in valid_patterns:
			var tolerance = group.average_fps * 0.1  # 10% tolerancia
			if abs(pattern.fps - group.average_fps) <= tolerance:
				total_confidence += pattern.confidence
				pattern_count += 1
		
		var group_score = total_confidence * pattern_count
		
		if group_score > best_score:
			best_score = group_score
			best_group = {
				"fps": group.average_fps,
				"confidence": total_confidence / max(1, pattern_count),
				"supporting_patterns": pattern_count
			}
	
	if best_group:
		consensus.fps = best_group.fps
		consensus.confidence = best_group.confidence
		consensus.method_agreement = float(best_group.supporting_patterns) / valid_patterns.size()
		consensus.dominant_pattern = best_group
	
	return consensus

func _group_similar_fps_values(fps_values: Array) -> Array:
	"""Agrupar valores de FPS similares"""
	var groups = []
	var tolerance_percent = 0.08  # 8% tolerancia
	
	for fps in fps_values:
		var placed = false
		
		for group in groups:
			var tolerance = group.average_fps * tolerance_percent
			if abs(fps - group.average_fps) <= tolerance:
				group.fps_values.append(fps)
				# Recalcular promedio
				var sum = 0.0
				for val in group.fps_values:
					sum += val
				group.average_fps = sum / group.fps_values.size()
				placed = true
				break
		
		if not placed:
			groups.append({
				"average_fps": fps,
				"fps_values": [fps]
			})
	
	return groups


# ========================================================================
# FUNCIONES MATEMÁTICAS BÁSICAS FALTANTES
# ========================================================================

func _calculate_mean(values: Array) -> float:
	"""Calcular media aritmética de un array de valores"""
	if values.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += float(value)
	
	return sum / values.size()

func _calculate_variance(values: Array) -> float:
	"""Calcular varianza de un array de valores"""
	if values.size() < 2:
		return 0.0
	
	var mean = _calculate_mean(values)
	var variance_sum = 0.0
	
	for value in values:
		var diff = float(value) - mean
		variance_sum += diff * diff
	
	return variance_sum / values.size()

func _is_regular_pattern(values: Array) -> bool:
	"""Determinar si hay un patrón regular en los valores"""
	if values.size() < 3:
		return false
	
	var variance = _calculate_variance(values)
	var mean = _calculate_mean(values)
	
	if mean <= 0:
		return false
	
	# Coeficiente de variación < 15% indica patrón regular
	var coefficient_of_variation = sqrt(variance) / mean
	return coefficient_of_variation < 0.15
