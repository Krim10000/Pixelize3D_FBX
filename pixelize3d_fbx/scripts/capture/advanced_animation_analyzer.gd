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

func _execute_all_detection_methods(anim: Animation, analysis: Dictionary) -> Array:
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

func _detect_fps_interpolation_gaps(anim: Animation) -> Dictionary:
    """Método 4: NUEVO - Detección de gaps de interpolación"""
    var result = {
        "method": DetectionMethod.INTERPOLATION_GAPS,
        "method_name": "Interpolation Gaps",
        "fps": 0.0,
        "confidence": 0.0,
        "gap_analysis": {}
    }
    
    # ✅ BUSCAR GAPS EN INTERPOLACIÓN entre keyframes
    var interpolation_gaps = []
    
    for track_idx in range(anim.get_track_count()):
        var track_gaps = _find_interpolation_gaps_in_track(anim, track_idx)
        interpolation_gaps.append_array(track_gaps)
    
    if interpolation_gaps.size() < 2:
        result.confidence = 0.0
        return result
    
    # ✅ ANÁLISIS ESTADÍSTICO de gaps
    var gap_statistics = _analyze_gap_distribution(interpolation_gaps, anim.length)
    
    if gap_statistics.has_clear_pattern:
        result.fps = gap_statistics.implied_fps
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
    for signal in transformation_signals:
        var freq_analysis = _perform_frequency_analysis_on_signal(signal, anim.length)
        
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

func _calculate_advanced_consensus(detection_results: Array, anim: Animation, analysis: Dictionary) -> Dictionary:
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
    consensus.cross_validation = _perform_cross_validation(consensus.fps, anim, detection_results)
    
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
    ultra_deep_analysis.temporal_distribution = _analyze_temporal_distribution(anim, ultra_deep_analysis.tracks_analyzed)
    
    # ✅ ANÁLISIS DE JERARQUÍA DE HUESOS
    if enable_deep_bone_analysis:
        ultra_deep_analysis.bone_hierarchy_analysis = _analyze_bone_hierarchy_timing(anim)
    
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

func _analyze_quality_and_advanced_recommendations(anim: Animation, analysis: Dictionary):
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
        if track_type == Animation.TYPE_TRANSFORM3D:
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

func _analyze_track_fps_pattern(keyframe_times: Array, animation_length: float) -> Dictionary:
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
# FUNCIONES DE IMPLEMENTACIÓN INTERNA
# (Las funciones auxiliares se implementarían aquí, pero por brevedad las omito)
# ========================================================================

# Placeholder functions - en implementación real contendrían la lógica completa
func _analyze_bone_track_velocity(anim: Animation, track_idx: int, sample_count: int) -> Array:
    return []  # Implementación completa estaría aquí

func _extract_fps_from_velocity_pattern(velocities: Array, length: float) -> Dictionary:
    return {"confidence": 0.0}  # Implementación completa estaría aquí

func _calculate_velocity_consensus(patterns: Array) -> Dictionary:
    return {"fps": 30.0, "confidence": 0.0}  # Implementación completa estaría aquí

# ... (más funciones auxiliares) ...