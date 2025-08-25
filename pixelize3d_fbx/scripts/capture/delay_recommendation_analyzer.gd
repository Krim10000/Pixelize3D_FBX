# pixelize3d_fbx/scripts/capture/delay_recommendation_analyzer.gd
# Sistema de Recomendacion de Delay Optimo - LISTO PARA PRODUCCION Godot 4.4
# Input: Animation de Godot desde archivo FBX cargado
# Output: Recomendacion de delay optimo para evitar frames perdidos y lograr fluidez

extends Node
class_name DelayRecommendationAnalyzer

# SEÑALES CORREGIDAS para Godot 4.4
signal delay_recommendation_complete(animation_name: String, recommendation: Dictionary)
signal delay_alternatives_found(animation_name: String, alternatives: Array)
signal frame_sync_analysis_complete(animation_name: String, sync_data: Dictionary)

# Configuracion de recomendaciones
var enable_frame_perfect_analysis: bool = true
var enable_multiple_recommendations: bool = true
var enable_fps_equivalence_display: bool = true
var min_delay_seconds: float = 0.01  # 10ms minimo (100 FPS maximo)
var max_delay_seconds: float = 1.0   # 1s maximo (1 FPS minimo)

# Presets de delays comunes con sus FPS equivalentes
var common_delays: Dictionary = {
	"ultra_smooth": {"delay": 0.016667, "fps_equivalent": 60.0, "description": "60 FPS - Ultra suave"},
	"smooth": {"delay": 0.0333333, "fps_equivalent": 30.0, "description": "30 FPS - Suave"},
	"standard": {"delay": 0.05, "fps_equivalent": 20.0, "description": "20 FPS - Estandar"},
	"cinematic": {"delay": 0.041667, "fps_equivalent": 24.0, "description": "24 FPS - Cinematografico"},
	"retro_smooth": {"delay": 0.083333, "fps_equivalent": 12.0, "description": "12 FPS - Retro suave"},
	"retro_classic": {"delay": 0.1, "fps_equivalent": 10.0, "description": "10 FPS - Retro clasico"}
}

# Cache para recomendaciones
var recommendation_cache: Dictionary = {}

func _ready() -> void:
	print("⏱️ DelayRecommendationAnalyzer inicializado")

# ========================================================================
# API PRINCIPAL DE RECOMENDACION DE DELAY
# ========================================================================

func recommend_optimal_delay(anim: Animation, anim_name: String = "") -> Dictionary:
	"""Recomendar delay optimo para la animacion"""
	if not anim:
		return _create_fallback_recommendation("Animacion nula")
	
	print("⏱️ Analizando animacion para recomendacion de delay: %s" % anim_name)
	
	# Verificar cache
	var cache_key: String = _generate_cache_key(anim, anim_name)
	if cache_key in recommendation_cache:
		print("📋 Usando recomendacion cacheada")
		return recommendation_cache[cache_key]
	
	# Analisis completo de la animacion
	var recommendation: Dictionary = _perform_delay_analysis(anim, anim_name)
	
	# Cachear resultado
	recommendation_cache[cache_key] = recommendation
	
	# EMISION CORREGIDA para Godot 4.4
	delay_recommendation_complete.emit(anim_name, recommendation)
	return recommendation

func _perform_delay_analysis(anim: Animation, anim_name: String) -> Dictionary:
	"""Realizar analisis completo para recomendacion de delay"""
	var analysis: Dictionary = {
		"animation_name": anim_name,
		"duration": anim.length,
		"recommended_delay": 0.083333,  # Default: 12 FPS
		"recommended_fps_equivalent": 12.0,
		"confidence": 0.0,
		"total_frames_estimated": 0,
		"frame_perfect": false,
		"reasoning": [],
		"alternatives": [],
		"frame_sync_data": {},
		"quality_score": 0.0
	}
	
	# 1. Analisis de duracion y frames ideales
	var duration_analysis: Dictionary = _analyze_duration_for_optimal_frames(anim)
	analysis.frame_sync_data = duration_analysis
	
	# 2. Analisis de keyframes reales
	var keyframe_analysis: Dictionary = _analyze_real_keyframes(anim)
	analysis.frame_sync_data.merge(keyframe_analysis)
	
	# 3. Calcular delay optimo
	var optimal_delay: Dictionary = _calculate_optimal_delay(duration_analysis, keyframe_analysis)
	analysis.recommended_delay = optimal_delay.delay
	analysis.recommended_fps_equivalent = delay_to_fps(optimal_delay.delay)
	analysis.confidence = optimal_delay.confidence
	analysis.total_frames_estimated = optimal_delay.estimated_frames
	analysis.frame_perfect = optimal_delay.frame_perfect
	analysis.reasoning = optimal_delay.reasoning
	
	# 4. Generar alternativas
	if enable_multiple_recommendations:
		analysis.alternatives = _generate_delay_alternatives(anim, optimal_delay)
	
	# 5. Calcular score de calidad
	analysis.quality_score = _calculate_recommendation_quality(analysis)
	
	print("✅ Delay recomendado: %.4fs (%.1f FPS equiv) con %.1f%% confianza" % [
		analysis.recommended_delay, analysis.recommended_fps_equivalent, analysis.confidence * 100
	])
	
	return analysis

# ========================================================================
# ANALISIS DE DURACION Y FRAMES OPTIMOS
# ========================================================================

func _analyze_duration_for_optimal_frames(anim: Animation) -> Dictionary:
	"""Analizar duracion para encontrar numero optimo de frames"""
	var duration: float = anim.length
	
	var analysis: Dictionary = {
		"animation_duration": duration,
		"optimal_frame_counts": [],
		"frame_count_analysis": {}
	}
	
	# Probar diferentes cantidades de frames que resulten en delays "redondos"
	var target_frame_counts: Array[int] = [8, 10, 12, 15, 16, 20, 24, 30, 32, 40, 48, 60]
	
	for frame_count in target_frame_counts:
		if frame_count < 2:
			continue
			
		var delay_for_this_count: float = duration / frame_count
		
		# Verificar si esta en rango aceptable
		if delay_for_this_count >= min_delay_seconds and delay_for_this_count <= max_delay_seconds:
			var fps_equiv: float = delay_to_fps(delay_for_this_count)
			
			analysis.frame_count_analysis[frame_count] = {
				"delay": delay_for_this_count,
				"fps_equivalent": fps_equiv,
				"is_common_fps": _is_common_fps_equivalent(fps_equiv),
				"frame_perfect_score": _calculate_frame_perfect_score(delay_for_this_count, fps_equiv)
			}
			
			analysis.optimal_frame_counts.append({
				"frame_count": frame_count,
				"delay": delay_for_this_count,
				"fps_equivalent": fps_equiv,
				"score": analysis.frame_count_analysis[frame_count].frame_perfect_score
			})
	
	# Ordenar por score
	analysis.optimal_frame_counts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	
	return analysis

func _analyze_real_keyframes(anim: Animation) -> Dictionary:
	"""Analizar keyframes reales de la animacion"""
	var analysis: Dictionary = {
		"total_tracks": anim.get_track_count(),
		"keyframe_timing_analysis": [],
		"suggested_natural_timing": 0.0,
		"keyframe_based_recommendation": {}
	}
	
	var all_key_times: Array[float] = []
	
	# Recopilar todos los tiempos de keyframes
	for track_idx in range(anim.get_track_count()):
		var track_keys: Array[float] = []
		var key_count: int = anim.track_get_key_count(track_idx)
		
		for key_idx in range(key_count):
			var key_time: float = anim.track_get_key_time(track_idx, key_idx)
			track_keys.append(key_time)
			
			if key_time not in all_key_times:
				all_key_times.append(key_time)
		
		analysis.keyframe_timing_analysis.append({
			"track_index": track_idx,
			"key_count": key_count,
			"key_times": track_keys
		})
	
	# Analizar distribucion temporal
	if all_key_times.size() > 1:
		all_key_times.sort()
		
		# Calcular intervalos mas comunes
		var intervals: Array[float] = []
		for i in range(1, all_key_times.size()):
			var interval: float = all_key_times[i] - all_key_times[i-1]
			if interval > 0.001:  # Ignorar intervalos muy pequeños
				intervals.append(interval)
		
		if intervals.size() > 0:
			# Encontrar el intervalo mas comun
			var interval_frequency: Dictionary = {}
			for interval in intervals:
				var rounded_interval: float = round(interval * 1000) / 1000.0  # Redondear a milisegundos
				
				if rounded_interval in interval_frequency:
					interval_frequency[rounded_interval] += 1
				else:
					interval_frequency[rounded_interval] = 1
			
			# Encontrar el mas frecuente
			var most_common_interval: float = 0.0
			var max_frequency: int = 0
			
			for interval in interval_frequency:
				if interval_frequency[interval] > max_frequency:
					max_frequency = interval_frequency[interval]
					most_common_interval = interval
			
			analysis.suggested_natural_timing = most_common_interval
			analysis.keyframe_based_recommendation = {
				"suggested_delay": most_common_interval,
				"confidence": float(max_frequency) / intervals.size(),
				"fps_equivalent": delay_to_fps(most_common_interval),
				"total_intervals_analyzed": intervals.size()
			}
	
	return analysis

# ========================================================================
# CALCULO DE DELAY OPTIMO
# ========================================================================

func _calculate_optimal_delay(duration_analysis: Dictionary, keyframe_analysis: Dictionary) -> Dictionary:
	"""Calcular el delay optimo basado en todos los analisis"""
	var result: Dictionary = {
		"delay": 0.083333,  # Default 12 FPS
		"estimated_frames": 12,
		"confidence": 0.0,
		"frame_perfect": false,
		"reasoning": [],
		"calculation_method": "hybrid"
	}
	
	var candidates: Array[Dictionary] = []
	
	# Candidato 1: Basado en frames optimos
	if duration_analysis.optimal_frame_counts.size() > 0:
		var best_frame_option: Dictionary = duration_analysis.optimal_frame_counts[0]
		candidates.append({
			"delay": best_frame_option.delay,
			"frames": best_frame_option.frame_count,
			"confidence": 0.8,
			"source": "frame_count_optimization",
			"fps_equiv": best_frame_option.fps_equivalent
		})
		result.reasoning.append("Frame count optimization: %d frames → %.4fs delay" % [best_frame_option.frame_count, best_frame_option.delay])
	
	# Candidato 2: Basado en keyframes naturales
	if keyframe_analysis.has("keyframe_based_recommendation") and keyframe_analysis.keyframe_based_recommendation.confidence > 0.3:
		var keyframe_rec: Dictionary = keyframe_analysis.keyframe_based_recommendation
		candidates.append({
			"delay": keyframe_rec.suggested_delay,
			"frames": int(duration_analysis.animation_duration / keyframe_rec.suggested_delay),
			"confidence": keyframe_rec.confidence,
			"source": "natural_keyframe_timing",
			"fps_equiv": keyframe_rec.fps_equivalent
		})
		result.reasoning.append("Natural keyframe timing: %.4fs interval detected" % keyframe_rec.suggested_delay)
	
	# Candidato 3: Preset mas cercano
	var closest_preset: Dictionary = _find_closest_common_delay(duration_analysis.animation_duration)
	if closest_preset.confidence > 0.6:
		candidates.append({
			"delay": closest_preset.delay,
			"frames": closest_preset.estimated_frames,
			"confidence": closest_preset.confidence,
			"source": "common_preset_match",
			"fps_equiv": closest_preset.fps_equivalent
		})
		result.reasoning.append("Common preset match: %s" % closest_preset.preset_name)
	
	# Seleccionar el mejor candidato
	if candidates.size() > 0:
		# Ordenar por confianza
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.confidence > b.confidence)
		var best_candidate: Dictionary = candidates[0]
		
		result.delay = best_candidate.delay
		result.estimated_frames = best_candidate.frames
		result.confidence = best_candidate.confidence
		result.calculation_method = best_candidate.source
		
		# Verificar si es "frame perfect"
		var frames_decimal: float = duration_analysis.animation_duration / result.delay
		var frames_integer: float = round(frames_decimal)
		result.frame_perfect = abs(frames_decimal - frames_integer) < 0.01
		
		if result.frame_perfect:
			result.reasoning.append("Frame-perfect: %.1f frames (no decimales)" % frames_integer)
			result.confidence = min(1.0, result.confidence + 0.2)  # Bonus por frame-perfect
	
	return result

# ========================================================================
# GENERACION DE ALTERNATIVAS
# ========================================================================

func _generate_delay_alternatives(anim: Animation, optimal_delay: Dictionary) -> Array[Dictionary]:
	"""Generar alternativas de delay"""
	var alternatives: Array[Dictionary] = []
	var duration: float = anim.length
	
	# Alternativas basadas en presets comunes
	for preset_name in common_delays:
		var preset: Dictionary = common_delays[preset_name]
		var frames_with_preset: float = duration / preset.delay
		
		if abs(frames_with_preset - round(frames_with_preset)) < 0.1:
			# Esta alternativa da frames enteros
			alternatives.append({
				"delay": preset.delay,
				"fps_equivalent": preset.fps_equivalent,
				"estimated_frames": int(round(frames_with_preset)),
				"frame_perfect": true,
				"description": preset.description,
				"quality_score": 90.0,
				"reasoning": "Preset frame-perfect"
			})
	
	# Alternativas ±20% del optimo
	var base_delay: float = optimal_delay.delay
	var variations: Array[float] = [0.8, 0.9, 1.1, 1.2]
	
	for variation in variations:
		var alt_delay: float = base_delay * variation
		
		# Verificar que este en rango valido
		if alt_delay >= min_delay_seconds and alt_delay <= max_delay_seconds:
			var alt_frames: float = duration / alt_delay
			var is_frame_perfect: bool = abs(alt_frames - round(alt_frames)) < 0.05
			
			alternatives.append({
				"delay": alt_delay,
				"fps_equivalent": delay_to_fps(alt_delay),
				"estimated_frames": int(round(alt_frames)),
				"frame_perfect": is_frame_perfect,
				"description": "Variacion %.0f%% del optimo" % ((variation - 1.0) * 100),
				"quality_score": 70.0 + (30.0 if is_frame_perfect else 0.0),
				"reasoning": "Mathematical variation"
			})
	
	# Ordenar por calidad
	alternatives.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.quality_score > b.quality_score)
	
	# Limitar a top 5
	if alternatives.size() > 5:
		alternatives = alternatives.slice(0, 5)
	
	return alternatives

# ========================================================================
# FUNCIONES AUXILIARES
# ========================================================================

func delay_to_fps(delay: float) -> float:
	"""Convertir delay a FPS equivalente"""
	if delay <= 0:
		return 0.0
	return 1.0 / delay

func fps_to_delay(fps: float) -> float:
	"""Convertir FPS a delay equivalente"""
	if fps <= 0:
		return 1.0
	return 1.0 / fps

func _is_common_fps_equivalent(fps: float) -> bool:
	"""Verificar si el FPS equivalente es comun (24, 30, 60, etc.)"""
	var common_fps: Array[int] = [10, 12, 15, 20, 24, 30, 48, 60]
	for common in common_fps:
		if abs(fps - common) < 0.5:
			return true
	return false

func _calculate_frame_perfect_score(delay: float, fps_equiv: float) -> float:
	"""Calcular score de frame-perfect"""
	var base_score: float = 50.0
	
	# Bonus por FPS comun
	if _is_common_fps_equivalent(fps_equiv):
		base_score += 30.0
	
	# Bonus por delays "redondos"
	var delay_ms: float = delay * 1000
	if abs(delay_ms - round(delay_ms)) < 0.1:
		base_score += 20.0
	
	return base_score

func _find_closest_common_delay(duration: float) -> Dictionary:
	"""Encontrar el preset de delay mas cercano que funcione bien"""
	var best_match: Dictionary = {
		"delay": 0.083333,
		"fps_equivalent": 12.0,
		"estimated_frames": 12,
		"confidence": 0.0,
		"preset_name": "retro_smooth"
	}
	
	var best_score: float = 0.0
	
	for preset_name in common_delays:
		var preset: Dictionary = common_delays[preset_name]
		var estimated_frames: float = duration / preset.delay
		var frame_error: float = abs(estimated_frames - round(estimated_frames))
		
		# Score basado en que tan "redondo" queda el numero de frames
		var score: float = 1.0 - frame_error
		
		if score > best_score:
			best_score = score
			best_match = {
				"delay": preset.delay,
				"fps_equivalent": preset.fps_equivalent,
				"estimated_frames": int(round(estimated_frames)),
				"confidence": score,
				"preset_name": preset_name
			}
	
	return best_match

func _calculate_recommendation_quality(analysis: Dictionary) -> float:
	"""Calcular score de calidad de la recomendacion"""
	var quality: float = 50.0
	
	# Bonus por alta confianza
	quality += analysis.confidence * 30.0
	
	# Bonus por frame-perfect
	if analysis.frame_perfect:
		quality += 20.0
	
	return min(100.0, quality)

func _generate_cache_key(anim: Animation, anim_name: String) -> String:
	"""Generar clave de cache"""
	return "%s_%.3f_%d" % [anim_name, anim.length, anim.get_track_count()]

func _create_fallback_recommendation(error_msg: String) -> Dictionary:
	"""Crear recomendacion de fallback"""
	return {
		"animation_name": "unknown",
		"duration": 0.0,
		"recommended_delay": 0.083333,  # 12 FPS safe default
		"recommended_fps_equivalent": 12.0,
		"confidence": 0.1,
		"total_frames_estimated": 12,
		"frame_perfect": false,
		"reasoning": ["Fallback due to error: " + error_msg],
		"alternatives": [],
		"quality_score": 10.0,
		"error": error_msg
	}

# ========================================================================
# API PUBLICA ADICIONAL
# ========================================================================

func get_common_delay_presets() -> Dictionary:
	"""Obtener presets de delay comunes"""
	return common_delays.duplicate()

func validate_delay(delay: float) -> Dictionary:
	"""Validar si un delay esta en rango aceptable"""
	return {
		"valid": delay >= min_delay_seconds and delay <= max_delay_seconds,
		"fps_equivalent": delay_to_fps(delay),
		"too_fast": delay < min_delay_seconds,
		"too_slow": delay > max_delay_seconds,
		"recommended_range": "%.3fs - %.3fs" % [min_delay_seconds, max_delay_seconds]
	}

func clear_recommendation_cache() -> void:
	"""Limpiar cache de recomendaciones"""
	recommendation_cache.clear()
	print("🗑️ Cache de recomendaciones limpiado")
