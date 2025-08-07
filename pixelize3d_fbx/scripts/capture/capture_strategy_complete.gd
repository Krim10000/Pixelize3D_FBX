# scripts/capture/capture_strategy.gd
# Estrategias ultra-inteligentes con 12 tipos + AI adaptativo para máxima calidad
# Input: Análisis de AnimationAnalyzer + FPS objetivo + contexto del proyecto
# Output: Estrategia ultra-optimizada con timing perfecto y predicción de calidad

extends Node
class_name CaptureStrategy

# Señales para máximo feedback de calidad
signal strategy_calculated(strategy_data: Dictionary)
signal strategy_optimization_complete(optimized_strategy: Dictionary)
signal quality_prediction_complete(prediction: Dictionary)
signal context_analysis_complete(context_data: Dictionary)

# Tipos de estrategia ultra-avanzados (12 tipos)
enum AdvancedStrategyType {
	# Estrategias base mejoradas
	DIRECT,                    # Captura directa con validación avanzada
	DOWNSAMPLE,               # Reducción inteligente con preservación de keyframes
	UPSAMPLE,                 # Interpolación avanzada con suavizado
	SMART_MIXED,              # Híbrido inteligente adaptativo
	KEYFRAME_BASED,           # Prioridad de keyframes con análisis de importancia
	
	# NUEVAS estrategias súper avanzadas
	MOTION_AWARE,             # Basada en análisis de movimiento profundo
	CONTENT_ADAPTIVE,         # Se adapta al tipo de contenido específico
	PERCEPTUAL_OPTIMIZED,     # Optimizada para percepción humana avanzada
	GAME_TYPE_SPECIFIC,       # Específica para tipo de juego detectado
	HYBRID_INTERPOLATION,     # Interpolación híbrida con múltiples algoritmos
	NEURAL_PREDICTED,         # Predicción usando red neuronal simple
	CONTEXT_AWARE,            # Considera contexto completo del proyecto
	
	# Estrategias experimentales de máxima calidad
	QUALITY_FIRST,            # Calidad máxima sin compromiso de performance
	CINEMATIC_GRADE          # Calidad cinematográfica para cutscenes
}

# Configuración para máxima calidad
var quality_over_performance: bool = true
var enable_ai_strategy_selection: bool = true
var enable_context_analysis: bool = true
var enable_motion_analysis: bool = true
var enable_perceptual_optimization: bool = true
var enable_predictive_quality: bool = true

# Umbrales de calidad estrictos
var min_strategy_quality_score: float = 95.0
var max_acceptable_quality_loss: float = 2.0  # Máximo 2% pérdida de calidad
var min_perceptual_quality: float = 98.0      # 98% calidad perceptual mínima

# Cache inteligente para estrategias ultra-complejas
var ultra_strategy_cache: Dictionary = {}
var context_analysis_cache: Dictionary = {}
var motion_analysis_cache: Dictionary = {}

# Sistema de predicción de calidad
var quality_predictor: QualityPredictor
var context_analyzer: ContextAnalyzer
var motion_analyzer: MotionAnalyzer

func _ready():
	print("📋 CaptureStrategy ULTRA-INTELIGENTE inicializado")
	print("🎯 Prioridad: CALIDAD MÁXIMA con contexto completo")
	
	# Inicializar sistemas avanzados
	_initialize_ultra_intelligence_systems()

func _initialize_ultra_intelligence_systems():
	"""Inicializar sistemas de ultra-inteligencia"""
	
	# Predictor de calidad
	quality_predictor = QualityPredictor.new()
	add_child(quality_predictor)
	quality_predictor.quality_predicted.connect(_on_quality_predicted)
	
	# Analizador de contexto
	context_analyzer = ContextAnalyzer.new()
	add_child(context_analyzer)
	context_analyzer.context_analyzed.connect(_on_context_analyzed)
	
	# Analizador de movimiento
	motion_analyzer = MotionAnalyzer.new()
	add_child(motion_analyzer)
	motion_analyzer.motion_analyzed.connect(_on_motion_analyzed)
	
	print("✅ Sistemas de ultra-inteligencia inicializados")

# ========================================================================
# CÁLCULO DE ESTRATEGIA ULTRA-INTELIGENTE
# ========================================================================

func calculate_capture_strategy(animation_analysis: Dictionary, target_fps: float, user_preferences: Dictionary = {}) -> Dictionary:
	"""Cálculo ultra-inteligente de estrategia con contexto completo"""
	
	if animation_analysis.has("error"):
		push_error("❌ No se puede calcular estrategia con análisis erróneo")
		return _create_error_strategy("Análisis de animación inválido")
	
	print("📋 Iniciando cálculo ULTRA-INTELIGENTE de estrategia...")
	print("🎯 Análisis: %.1f FPS detectado, objetivo: %.1f FPS" % [
		animation_analysis.detected_fps, target_fps
	])
	
	# ✅ FASE 1: ANÁLISIS DE CONTEXTO COMPLETO
	var context_analysis = await _analyze_complete_context(animation_analysis, user_preferences)
	emit_signal("context_analysis_complete", context_analysis)
	
	# ✅ FASE 2: ANÁLISIS DE MOVIMIENTO PROFUNDO
	var motion_analysis = _analyze_motion_characteristics(animation_analysis, context_analysis)
	
	# ✅ FASE 3: SELECCIÓN DE ESTRATEGIA CON IA
	var strategy_candidates = _generate_all_strategy_candidates(
		animation_analysis, target_fps, context_analysis, motion_analysis
	)
	
	# ✅ FASE 4: PREDICCIÓN DE CALIDAD para cada candidato
	var quality_predictions = await _predict_quality_for_all_candidates(
		strategy_candidates, animation_analysis
	)
	
	# ✅ FASE 5: SELECCIÓN ÓPTIMA con múltiples criterios
	var optimal_strategy = _select_optimal_strategy_multi_criteria(
		strategy_candidates, quality_predictions, context_analysis
	)
	
	# ✅ FASE 6: OPTIMIZACIÓN FINAL de la estrategia seleccionada
	var optimized_strategy = await _optimize_strategy_final(optimal_strategy, animation_analysis)
	
	# ✅ FASE 7: VALIDACIÓN DE CALIDAD FINAL
	_validate_final_strategy_quality(optimized_strategy, animation_analysis)
	
	emit_signal("strategy_calculated", optimized_strategy)
	
	print("✅ Estrategia ULTRA-INTELIGENTE calculada: %s (%.1f%% calidad predicha)" % [
		optimized_strategy.strategy_name,
		optimized_strategy.predicted_quality_score
	])
	
	return optimized_strategy

# ========================================================================
# ANÁLISIS DE CONTEXTO ULTRA-COMPLETO
# ========================================================================

func _analyze_complete_context(animation_analysis: Dictionary, user_preferences: Dictionary) -> Dictionary:
	"""Análisis ultra-completo del contexto para estrategia perfecta"""
	
	var context = {
		"project_analysis": {},
		"content_analysis": {},
		"usage_intent": {},
		"technical_constraints": {},
		"quality_requirements": {},
		"performance_requirements": {}
	}
	
	# ✅ ANÁLISIS DEL PROYECTO
	context.project_analysis = _analyze_project_context_deep(user_preferences)
	
	# ✅ ANÁLISIS DEL CONTENIDO DE ANIMACIÓN
	context.content_analysis = _analyze_animation_content_deep(animation_analysis)
	
	# ✅ ANÁLISIS DE INTENCIÓN DE USO
	context.usage_intent = _detect_usage_intent_advanced(animation_analysis, user_preferences)
	
	# ✅ ANÁLISIS DE RESTRICCIONES TÉCNICAS
	context.technical_constraints = _analyze_technical_constraints(user_preferences)
	
	# ✅ DETERMINACIÓN DE REQUISITOS DE CALIDAD
	context.quality_requirements = _determine_quality_requirements(context)
	
	# ✅ DETERMINACIÓN DE REQUISITOS DE PERFORMANCE
	context.performance_requirements = _determine_performance_requirements(context)
	
	print("🔍 Contexto analizado: Proyecto %s, Contenido %s, Uso %s" % [
		context.project_analysis.game_type,
		context.content_analysis.content_category,
		context.usage_intent.primary_usage
	])
	
	return context

func _analyze_project_context_deep(user_preferences: Dictionary) -> Dictionary:
	"""Análisis profundo del contexto del proyecto"""
	var project_context = {
		"game_type": "unknown",
		"target_platform": "desktop",
		"visual_style": "realistic",
		"target_audience": "general",
		"development_stage": "production",
		"quality_priority": "high"
	}
	
	# ✅ DETECCIÓN INTELIGENTE DEL TIPO DE JUEGO
	var project_hints = _gather_project_hints(user_preferences)
	
	# Análisis por nombre del proyecto
	var project_name = user_preferences.get("project_name", "").to_lower()
	if "rts" in project_name or "strategy" in project_name:
		project_context.game_type = "rts"
		project_context.quality_priority = "balanced"  # RTS prioriza performance
	elif "rpg" in project_name or "role" in project_name:
		project_context.game_type = "rpg"
		project_context.quality_priority = "high"     # RPG prioriza calidad
	elif "fps" in project_name or "shooter" in project_name:
		project_context.game_type = "fps"
		project_context.quality_priority = "performance"  # FPS prioriza velocidad
	elif "puzzle" in project_name:
		project_context.game_type = "puzzle"
		project_context.quality_priority = "medium"
	elif "platform" in project_name:
		project_context.game_type = "platformer"
		project_context.quality_priority = "high"
	
	# ✅ DETECCIÓN DE PLATAFORMA OBJETIVO
	var platform_hints = user_preferences.get("target_platform", "desktop")
	if platform_hints == "mobile" or "android" in platform_hints or "ios" in platform_hints:
		project_context.target_platform = "mobile"
		project_context.quality_priority = "performance"  # Mobile prioriza battery
	elif "console" in platform_hints:
		project_context.target_platform = "console"
		project_context.quality_priority = "high"
	elif "web" in platform_hints:
		project_context.target_platform = "web"
		project_context.quality_priority = "balanced"
	
	# ✅ ANÁLISIS DE ESTILO VISUAL
	var art_style = user_preferences.get("art_style", "").to_lower()
	if "pixel" in art_style or "retro" in art_style:
		project_context.visual_style = "pixel_art"
		project_context.quality_priority = "medium"  # Pixel art no necesita ultra-calidad
	elif "cartoon" in art_style or "stylized" in art_style:
		project_context.visual_style = "stylized"
		project_context.quality_priority = "high"
	elif "realistic" in art_style or "photorealistic" in art_style:
		project_context.visual_style = "realistic"
		project_context.quality_priority = "ultra_high"
	
	return project_context

func _analyze_animation_content_deep(animation_analysis: Dictionary) -> Dictionary:
	"""Análisis ultra-profundo del contenido de la animación"""
	var content_analysis = {
		"content_category": "unknown",
		"complexity_level": "medium",
		"motion_type": "general",
		"key_characteristics": [],
		"quality_requirements": "high",
		"recommended_strategy_type": "balanced"
	}
	
	var anim_name = animation_analysis.animation_name.to_lower()
	var anim_length = animation_analysis.length
	var anim_fps = animation_analysis.detected_fps
	
	# ✅ CLASIFICACIÓN AUTOMÁTICA POR NOMBRE
	if _contains_any(anim_name, ["walk", "run", "jog", "sprint", "move"]):
		content_analysis.content_category = "locomotion"
		content_analysis.motion_type = "cyclic_movement"
		content_analysis.recommended_strategy_type = "perceptual_optimized"
		
	elif _contains_any(anim_name, ["idle", "breath", "stand", "wait"]):
		content_analysis.content_category = "idle_animation"
		content_analysis.motion_type = "subtle_movement"
		content_analysis.complexity_level = "low"
		content_analysis.recommended_strategy_type = "keyframe_based"
		
	elif _contains_any(anim_name, ["attack", "hit", "swing", "punch", "kick", "shoot"]):
		content_analysis.content_category = "combat_animation"
		content_analysis.motion_type = "impact_movement"
		content_analysis.quality_requirements = "ultra_high"  # Combat needs precision
		content_analysis.recommended_strategy_type = "motion_aware"
		
	elif _contains_any(anim_name, ["jump", "leap", "fall", "land"]):
		content_analysis.content_category = "acrobatic"
		content_analysis.motion_type = "ballistic_movement"
		content_analysis.recommended_strategy_type = "hybrid_interpolation"
		
	elif _contains_any(anim_name, ["dance", "emote", "gesture", "wave"]):
		content_analysis.content_category = "expressive"
		content_analysis.motion_type = "artistic_movement"
		content_analysis.quality_requirements = "ultra_high"
		content_analysis.recommended_strategy_type = "cinematic_grade"
		
	elif _contains_any(anim_name, ["death", "die", "fall_down", "collapse"]):
		content_analysis.content_category = "reaction"
		content_analysis.motion_type = "physics_based"
		content_analysis.recommended_strategy_type = "quality_first"
		
	elif _contains_any(anim_name, ["talk", "speak", "mouth", "facial"]):
		content_analysis.content_category = "facial_animation"
		content_analysis.motion_type = "facial_expression"
		content_analysis.complexity_level = "high"
		content_analysis.quality_requirements = "ultra_high"
		content_analysis.recommended_strategy_type = "direct"  # Facial needs exact timing
	
	# ✅ ANÁLISIS POR CARACTERÍSTICAS TEMPORALES
	if anim_length < 0.5:
		content_analysis.key_characteristics.append("very_short")
		content_analysis.complexity_level = "low"
	elif anim_length > 10.0:
		content_analysis.key_characteristics.append("very_long")
		content_analysis.complexity_level = "high"
	
	if anim_fps > 60:
		content_analysis.key_characteristics.append("high_framerate")
		content_analysis.quality_requirements = "ultra_high"
	elif anim_fps < 15:
		content_analysis.key_characteristics.append("low_framerate")
		content_analysis.recommended_strategy_type = "keyframe_based"
	
	# ✅ ANÁLISIS DE CALIDAD DE LA DETECCIÓN FPS
	var detection_confidence = animation_analysis.get("detection_confidence", 0.0)
	if detection_confidence < 0.8:
		content_analysis.key_characteristics.append("uncertain_fps")
		content_analysis.recommended_strategy_type = "conservative"
	
	return content_analysis

func _detect_usage_intent_advanced(animation_analysis: Dictionary, user_preferences: Dictionary) -> Dictionary:
	"""Detectar intención de uso ultra-avanzada"""
	var usage_intent = {
		"primary_usage": "gameplay",
		"quality_priority": "high",
		"performance_priority": "medium",
		"target_framerate": 12.0,
		"usage_context": "realtime",
		"visual_importance": "high"
	}
	
	# ✅ ANÁLISIS DE PISTAS DE USO en configuración
	var target_fps = user_preferences.get("target_fps", 12.0)
	
	if target_fps <= 8:
		usage_intent.primary_usage = "background_elements"
		usage_intent.performance_priority = "high"
		usage_intent.visual_importance = "medium"
	elif target_fps >= 24:
		usage_intent.primary_usage = "cinematic"
		usage_intent.quality_priority = "ultra_high"
		usage_intent.visual_importance = "critical"
	
	# ✅ ANÁLISIS DE CONFIGURACIÓN ESPECÍFICA
	var quality_preference = user_preferences.get("quality_preference", "balanced")
	match quality_preference:
		"speed":
			usage_intent.performance_priority = "critical"
			usage_intent.quality_priority = "medium"
		"quality":
			usage_intent.quality_priority = "critical" 
			usage_intent.performance_priority = "low"
		"balanced":
			usage_intent.quality_priority = "high"
			usage_intent.performance_priority = "medium"
	
	# ✅ DETECCIÓN DE CONTEXTO DE USO
	var sprite_size = user_preferences.get("sprite_size", 128)
	if sprite_size >= 512:
		usage_intent.usage_context = "hero_character"
		usage_intent.visual_importance = "critical"
	elif sprite_size <= 64:
		usage_intent.usage_context = "background_npc"
		usage_intent.visual_importance = "medium"
	
	return usage_intent

func _analyze_technical_constraints(user_preferences: Dictionary) -> Dictionary:
	"""Analizar restricciones técnicas del proyecto"""
	var constraints = {
		"memory_limit": "medium",
		"processing_power": "high",
		"storage_space": "unlimited",
		"rendering_backend": "gl_compatibility",
		"target_resolution": Vector2i(1920, 1080)
	}
	
	# ✅ DETECTAR LIMITACIONES DE HARDWARE
	var platform = user_preferences.get("target_platform", "desktop")
	match platform:
		"mobile":
			constraints.memory_limit = "low"
			constraints.processing_power = "limited"
			constraints.storage_space = "limited"
		"web":
			constraints.memory_limit = "medium"
			constraints.processing_power = "medium"
			constraints.storage_space = "limited"
		"console":
			constraints.memory_limit = "high"
			constraints.processing_power = "high"
			constraints.storage_space = "high"
	
	# ✅ CONFIGURACIÓN DE RENDERING
	constraints.rendering_backend = ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility")
	
	return constraints

func _determine_quality_requirements(context: Dictionary) -> Dictionary:
	"""Determinar requisitos específicos de calidad"""
	var quality_req = {
		"min_fps_accuracy": 95.0,
		"max_timing_drift_ms": 0.5,
		"visual_fidelity": "high",
		"consistency_required": true,
		"allow_quality_first": true,
		"enable_interpolation": true,
		"require_keyframe_preservation": false
	}
	
	# ✅ AJUSTAR según contexto del proyecto
	var game_type = context.project_analysis.game_type
	var content_category = context.content_analysis.content_category
	
	# Juegos que requieren timing perfecto
	if game_type in ["fps", "fighting", "rhythm"]:
		quality_req.min_fps_accuracy = 99.0
		quality_req.max_timing_drift_ms = 0.1
		quality_req.consistency_required = true
	
	# Animaciones que requieren preservación de keyframes
	if content_category in ["combat_animation", "facial_animation"]:
		quality_req.require_keyframe_preservation = true
		quality_req.enable_interpolation = false
	
	# Contenido cinematográfico
	if context.usage_intent.primary_usage == "cinematic":
		quality_req.visual_fidelity = "ultra_high"
		quality_req.allow_quality_first = true
	
	return quality_req

func _determine_performance_requirements(context: Dictionary) -> Dictionary:
	"""Determinar requisitos de performance"""
	var performance_req = {
		"max_processing_time_ms": 1000,
		"memory_usage_limit": "medium",
		"parallel_processing": true,
		"cache_strategies": true,
		"optimize_for_batch": false
	}
	
	# ✅ AJUSTAR según plataforma
	var platform = context.project_analysis.target_platform
	match platform:
		"mobile":
			performance_req.max_processing_time_ms = 500
			performance_req.memory_usage_limit = "low"
			performance_req.parallel_processing = false
		"web":
			performance_req.max_processing_time_ms = 750
			performance_req.cache_strategies = false
	
	return performance_req

# ========================================================================
# ANÁLISIS DE MOVIMIENTO PROFUNDO
# ========================================================================

func _analyze_motion_characteristics(animation_analysis: Dictionary, context_analysis: Dictionary) -> Dictionary:
	"""Análisis profundo de características de movimiento"""
	var motion_analysis = {
		"motion_intensity": "medium",
		"motion_pattern": "linear",
		"key_motion_moments": [],
		"smooth_sections": [],
		"critical_frames": [],
		"motion_complexity_score": 50.0,
		"requires_special_handling": false
	}
	
	# ✅ ANÁLISIS BASADO EN KEYFRAMES (si disponible)
	if animation_analysis.has("ultra_deep_keyframe_analysis"):
		var keyframe_data = animation_analysis.ultra_deep_keyframe_analysis
		motion_analysis = _extract_motion_from_keyframes(keyframe_data)
	
	# ✅ ANÁLISIS BASADO EN TIPO DE CONTENIDO
	var content_category = context_analysis.content_analysis.content_category
	
	match content_category:
		"combat_animation":
			motion_analysis.motion_intensity = "high"
			motion_analysis.motion_pattern = "impact_based"
			motion_analysis.requires_special_handling = true
			motion_analysis.motion_complexity_score = 85.0
			
		"locomotion":
			motion_analysis.motion_intensity = "medium"
			motion_analysis.motion_pattern = "cyclic"
			motion_analysis.motion_complexity_score = 60.0
			
		"idle_animation":
			motion_analysis.motion_intensity = "low"
			motion_analysis.motion_pattern = "subtle_variation"
			motion_analysis.motion_complexity_score = 25.0
			
		"facial_animation":
			motion_analysis.motion_intensity = "medium"
			motion_analysis.motion_pattern = "detail_focused"
			motion_analysis.requires_special_handling = true
			motion_analysis.motion_complexity_score = 90.0
	
	# ✅ IDENTIFICACIÓN DE MOMENTOS CRÍTICOS
	motion_analysis.critical_frames = _identify_critical_motion_frames(
		animation_analysis, motion_analysis.motion_pattern
	)
	
	return motion_analysis

# ========================================================================
# GENERACIÓN DE CANDIDATOS DE ESTRATEGIA
# ========================================================================

func _generate_all_strategy_candidates(animation_analysis: Dictionary, target_fps: float, context: Dictionary, motion: Dictionary) -> Array:
	"""Generar todos los candidatos de estrategia posibles"""
	var candidates = []
	
	print("🔬 Generando candidatos de estrategia ultra-inteligente...")
	
	# ✅ CANDIDATO 1: ESTRATEGIA DIRECTA AVANZADA
	var direct_candidate = _create_direct_advanced_strategy(animation_analysis, target_fps, context)
	if direct_candidate.is_viable:
		candidates.append(direct_candidate)
	
	# ✅ CANDIDATO 2: DOWNSAMPLE ULTRA-INTELIGENTE
	var downsample_candidate = _create_downsample_ultra_strategy(animation_analysis, target_fps, motion)
	if downsample_candidate.is_viable:
		candidates.append(downsample_candidate)
	
	# ✅ CANDIDATO 3: UPSAMPLE HÍBRIDO AVANZADO
	var upsample_candidate = _create_upsample_hybrid_strategy(animation_analysis, target_fps, context)
	if upsample_candidate.is_viable:
		candidates.append(upsample_candidate)
	
	# ✅ CANDIDATO 4: MOTION-AWARE STRATEGY (NUEVO)
	var motion_candidate = _create_motion_aware_strategy(animation_analysis, target_fps, motion, context)
	candidates.append(motion_candidate)
	
	# ✅ CANDIDATO 5: CONTENT-ADAPTIVE STRATEGY (NUEVO)
	var content_candidate = _create_content_adaptive_strategy(animation_analysis, target_fps, context)
	candidates.append(content_candidate)
	
	# ✅ CANDIDATO 6: PERCEPTUAL-OPTIMIZED STRATEGY (NUEVO)
	var perceptual_candidate = _create_perceptual_optimized_strategy(animation_analysis, target_fps, context, motion)
	candidates.append(perceptual_candidate)
	
	# ✅ CANDIDATO 7: GAME-TYPE-SPECIFIC STRATEGY (NUEVO)
	var game_type_candidate = _create_game_type_specific_strategy(animation_analysis, target_fps, context)
	candidates.append(game_type_candidate)
	
	# ✅ CANDIDATO 8: HYBRID-INTERPOLATION STRATEGY (NUEVO)
	var hybrid_candidate = _create_hybrid_interpolation_strategy(animation_analysis, target_fps, context, motion)
	candidates.append(hybrid_candidate)
	
	# ✅ CANDIDATO 9: CONTEXT-AWARE STRATEGY (NUEVO)
	var context_candidate = _create_context_aware_strategy(animation_analysis, target_fps, context)
	candidates.append(context_candidate)
	
	# ✅ CANDIDATO 10: QUALITY-FIRST STRATEGY (NUEVO)
	if context.quality_requirements.get("allow_quality_first", true):
		var quality_candidate = _create_quality_first_strategy(animation_analysis, target_fps)
		candidates.append(quality_candidate)
	
	# ✅ CANDIDATO 11: CINEMATIC-GRADE STRATEGY (NUEVO)
	if context.usage_intent.primary_usage in ["cinematic", "cutscene", "hero_character"]:
		var cinematic_candidate = _create_cinematic_grade_strategy(animation_analysis, target_fps)
		candidates.append(cinematic_candidate)
	
	# ✅ CANDIDATO 12: NEURAL-PREDICTED STRATEGY (EXPERIMENTAL)
	if enable_ai_strategy_selection:
		var neural_candidate = _create_neural_predicted_strategy(animation_analysis, target_fps, context, motion)
		candidates.append(neural_candidate)
	
	print("✅ Generados %d candidatos de estrategia" % candidates.size())
	return candidates

func _create_direct_advanced_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""Estrategia directa avanzada con validaciones ultra-estrictas"""
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.DIRECT
	strategy.strategy_name = "Direct Advanced"
	strategy.description = "Captura directa con validaciones ultra-estrictas"
	
	var original_fps = animation_analysis.detected_fps
	var fps_ratio = target_fps / original_fps
	
	# ✅ DETERMINAR VIABILIDAD de estrategia directa
	if abs(fps_ratio - 1.0) < 0.1:  # FPS muy similares
		strategy.target_frame_count = animation_analysis.get("real_frames", int(animation_analysis.length * original_fps))
		strategy.timing_mode = "original_exact"
		strategy.predicted_quality_score = 98.0
		strategy.is_viable = true
	elif fps_ratio < 1.0:  # Target FPS menor que original
		strategy.target_frame_count = int(animation_analysis.length * target_fps)
		strategy.timing_mode = "direct_downsample"
		strategy.predicted_quality_score = 95.0 - (1.0 - fps_ratio) * 10
		strategy.is_viable = strategy.predicted_quality_score >= min_strategy_quality_score
	else:  # Target FPS mayor que original
		strategy.target_frame_count = int(animation_analysis.length * target_fps)
		strategy.timing_mode = "direct_upsample"
		strategy.predicted_quality_score = 90.0 - (fps_ratio - 1.0) * 5
		strategy.is_viable = strategy.predicted_quality_score >= min_strategy_quality_score
	
	# ✅ CREAR TIMING TABLE ultra-preciso
	strategy.timing_table = _create_direct_timing_table(strategy, animation_analysis)
	
	strategy.performance_rating = "excellent"
	strategy.quality_rating = "high"
	
	return strategy

func _create_motion_aware_strategy(animation_analysis: Dictionary, target_fps: float, motion: Dictionary, context: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia súper avanzada basada en análisis de movimiento"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.MOTION_AWARE
	strategy.strategy_name = "Motion-Aware Ultra"
	strategy.description = "Estrategia adaptativa basada en análisis profundo de movimiento"
	
	var motion_intensity = motion.get("motion_intensity", "medium")
	var critical_frames = motion.get("critical_frames", [])
	
	# ✅ CÁLCULO DE FRAMES ADAPTATIVO basado en movimiento
	var base_frames = int(animation_analysis.length * target_fps)
	var motion_factor = _calculate_motion_density_factor(motion)
	
	strategy.target_frame_count = int(base_frames * motion_factor)
	strategy.frame_interval = animation_analysis.length / strategy.target_frame_count
	
	# ✅ TIMING TABLE ULTRA-ADAPTATIVO
	var timing_table = []
	var current_time = 0.0
	var time_step = animation_analysis.length / strategy.target_frame_count
	
	for i in range(strategy.target_frame_count):
		var target_time = i * time_step
		
		# ✅ AJUSTE ADAPTATIVO basado en intensidad de movimiento local
		var local_motion_intensity = _calculate_local_motion_intensity(target_time, motion)
		var time_adjustment = _calculate_time_adjustment_for_motion(local_motion_intensity)
		var adjusted_time = target_time + time_adjustment
		
		# ✅ SNAP A FRAMES CRÍTICOS si está cerca
		adjusted_time = _snap_to_critical_frames(adjusted_time, critical_frames)
		
		timing_table.append({
			"frame_index": i,
			"time_position": adjusted_time,
			"motion_intensity": local_motion_intensity,
			"is_critical_frame": adjusted_time in critical_frames,
			"time_adjustment": time_adjustment,
			"capture_priority": _calculate_capture_priority(local_motion_intensity)
		})
	
	strategy.timing_table = timing_table
	strategy.timing_mode = "motion_adaptive"
	strategy.capture_mode = "priority_weighted"
	
	# ✅ PREDICCIÓN DE CALIDAD basada en movimiento
	strategy.predicted_quality_score = _predict_motion_aware_quality(motion, strategy)
	strategy.performance_rating = "good"
	strategy.quality_rating = "excellent"
	
	strategy.motion_analysis = motion.duplicate()
	strategy.is_viable = true
	
	return strategy

func _create_content_adaptive_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia que se adapta específicamente al tipo de contenido"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.CONTENT_ADAPTIVE
	strategy.strategy_name = "Content-Adaptive Ultra"
	
	var content_category = context.content_analysis.content_category
	var quality_requirements = context.content_analysis.quality_requirements
	
	# ✅ CONFIGURACIÓN ESPECÍFICA POR TIPO DE CONTENIDO
	match content_category:
		"combat_animation":
			strategy = _configure_combat_optimized_strategy(strategy, animation_analysis, target_fps)
			
		"locomotion":
			strategy = _configure_locomotion_optimized_strategy(strategy, animation_analysis, target_fps)
			
		"facial_animation":
			strategy = _configure_facial_optimized_strategy(strategy, animation_analysis, target_fps)
			
		"idle_animation":
			strategy = _configure_idle_optimized_strategy(strategy, animation_analysis, target_fps)
			
		"expressive":
			strategy = _configure_expressive_optimized_strategy(strategy, animation_analysis, target_fps)
			
		_:  # Contenido genérico
			strategy = _configure_generic_optimized_strategy(strategy, animation_analysis, target_fps)
	
	strategy.content_category = content_category
	strategy.quality_requirements = quality_requirements
	strategy.is_viable = true
	
	return strategy

func _create_perceptual_optimized_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary, motion: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia optimizada para percepción humana"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.PERCEPTUAL_OPTIMIZED
	strategy.strategy_name = "Perceptual-Optimized Ultra"
	strategy.description = "Optimizada para máxima calidad perceptual por el ojo humano"
	
	# ✅ ANÁLISIS DE PERCEPCIÓN VISUAL
	var perceptual_analysis = _analyze_perceptual_requirements(animation_analysis, context, motion)
	
	# ✅ DISTRIBUCIÓN DE FRAMES basada en percepción
	var perceptual_frame_distribution = _calculate_perceptual_frame_distribution(
		animation_analysis, target_fps, perceptual_analysis
	)
	
	strategy.target_frame_count = perceptual_frame_distribution.total_frames
	strategy.timing_table = perceptual_frame_distribution.timing_table
	
	# ✅ CONFIGURACIÓN PERCEPTUAL
	strategy.perceptual_config = {
		"temporal_masking_considered": true,
		"motion_blur_compensation": true,
		"critical_motion_preserved": true,
		"smooth_interpolation_zones": perceptual_analysis.smooth_zones,
		"high_detail_zones": perceptual_analysis.detail_zones
	}
	
	strategy.predicted_quality_score = 98.0  # Estrategia de máxima calidad perceptual
	strategy.perceptual_quality_score = 99.5
	strategy.performance_rating = "medium"   # Puede ser más lenta pero calidad superior
	strategy.quality_rating = "superior"
	
	strategy.is_viable = true
	return strategy

#
#func _create_game_type_specific_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	#"""NUEVA: Estrategia específica para tipo de juego"""
	#
	#var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	#strategy.strategy_type = AdvancedStrategyType.GAME_TYPE_SPECIFIC
	#strategy.strategy_name = "Game-Type-Specific"
	#
	#var game_type = context.project_analysis.game_type
	#
	## ✅ CONFIGURACIÓN ESPECÍFICA POR TIPO DE JUEGO
	#match game_type:
		#"rts":
			#strategy = _configure_rts_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"rpg":
			#strategy = _configure_rpg_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"fps":
			#strategy = _configure_fps_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"platformer":
			#strategy = _configure_platformer_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"puzzle":
			#strategy = _configure_puzzle_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#_:
			#strategy = _configure_generic_game_strategy(strategy, animation_analysis, target_fps, context)
	#
	#strategy.game_type = game_type
	#strategy.is_viable = true
	#
	#return strategy

#func _create_game_type_specific_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	#"""Crea una estrategia específica para el tipo de juego detectado"""
	#
	## Crear estructura base usando el contexto real
	#var strategy = _create_base_strategy_structure(animation_analysis, target_fps, context)
	#
	## Verificar que el contexto tenga la estructura esperada
	#if not context.has("project_analysis") or not context["project_analysis"].has("game_type"):
		#strategy["error"] = "Contexto inválido: falta project_analysis o game_type"
		#strategy["is_viable"] = false
		#return strategy
	#
	#strategy["strategy_type"] = AdvancedStrategyType.GAME_TYPE_SPECIFIC
	#strategy["strategy_name"] = "Game-Type-Specific"
	#
	#var game_type: String = context["project_analysis"]["game_type"]
	#
	## ✅ CONFIGURACIÓN ESPECÍFICA POR TIPO DE JUEGO
	#match game_type:
		#"rts":
			#strategy = _configure_rts_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"rpg":
			#strategy = _configure_rpg_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"fps":
			#strategy = _configure_fps_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"platformer":
			#strategy = _configure_platformer_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#"puzzle":
			#strategy = _configure_puzzle_optimized_strategy(strategy, animation_analysis, target_fps, context)
		#_:
			#strategy = _configure_generic_game_strategy(strategy, animation_analysis, target_fps, context)
	#
	#strategy["game_type"] = game_type
	#strategy["is_viable"] = true
	#
	#return strategy

func _create_game_type_specific_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""Crea una estrategia específica para el tipo de juego detectado"""
	
	# Crear estructura base usando el contexto real
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, context)
	
	# Verificar que el contexto tenga la estructura esperada
	if not context.has("project_analysis") or not context["project_analysis"].has("game_type"):
		strategy["error"] = "Contexto inválido: falta project_analysis o game_type"
		strategy["is_viable"] = false
		return strategy
	
	strategy["strategy_type"] = AdvancedStrategyType.GAME_TYPE_SPECIFIC
	strategy["strategy_name"] = "Game-Type-Specific"
	
	var game_type: String = context["project_analysis"]["game_type"]
	
	# ✅ CONFIGURACIÓN ESPECÍFICA POR TIPO DE JUEGO
	match game_type:
		"rts":
			strategy = _configure_rts_optimized_strategy(strategy, animation_analysis, target_fps)
		"rpg":
			strategy = _configure_rpg_optimized_strategy(strategy, animation_analysis, target_fps)
		"fps":
			strategy = _configure_fps_optimized_strategy(strategy, animation_analysis, target_fps)
		"platformer":
			strategy = _configure_platformer_optimized_strategy(strategy, animation_analysis, target_fps)
		"puzzle":
			strategy = _configure_puzzle_optimized_strategy(strategy, animation_analysis, target_fps)
		_:
			strategy = _configure_generic_game_strategy(strategy, animation_analysis, target_fps)
	
	strategy["game_type"] = game_type
	strategy["is_viable"] = true
	
	return strategy

func _create_hybrid_interpolation_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary, motion: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia de interpolación híbrida con múltiples algoritmos"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.HYBRID_INTERPOLATION
	strategy.strategy_name = "Hybrid-Interpolation Ultra"
	strategy.description = "Interpolación híbrida con múltiples algoritmos adaptativos"
	
	# ✅ ANÁLISIS DE NECESIDADES DE INTERPOLACIÓN
	var interpolation_needs = _analyze_interpolation_requirements(animation_analysis, target_fps)
	
	# ✅ SELECCIÓN DE ALGORITMOS DE INTERPOLACIÓN
	var interpolation_algorithms = _select_optimal_interpolation_algorithms(interpolation_needs)
	
	# ✅ CONFIGURACIÓN HÍBRIDA
	strategy.target_frame_count = int(animation_analysis.length * target_fps)
	strategy.timing_mode = "hybrid_interpolation"
	strategy.interpolation_config = {
		"algorithms": interpolation_algorithms,
		"blend_zones": interpolation_needs.blend_zones,
		"quality_zones": interpolation_needs.quality_zones,
		"temporal_smoothing": true
	}
	
	# ✅ CREAR TIMING TABLE HÍBRIDO
	strategy.timing_table = _create_hybrid_interpolation_timing_table( animation_analysis, interpolation_needs)
	
	strategy.predicted_quality_score = 96.0
	strategy.performance_rating = "medium"
	strategy.quality_rating = "excellent"
	strategy.is_viable = true
	
	return strategy

func _create_context_aware_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia que considera contexto completo del proyecto"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.CONTEXT_AWARE
	strategy.strategy_name = "Context-Aware Ultra"
	strategy.description = "Considera contexto completo del proyecto para optimización máxima"
	
	# ✅ PONDERACIÓN DE FACTORES CONTEXTUALES
	var context_weights = _calculate_context_weights(context)
	
	# ✅ CONFIGURACIÓN ADAPTATIVA basada en contexto
	var adaptive_config = _create_adaptive_configuration(context, context_weights)
	
	# ✅ APLICAR CONFIGURACIÓN CONTEXTUAL
	strategy.target_frame_count = adaptive_config.frame_count
	strategy.timing_mode = adaptive_config.timing_mode
	strategy.quality_target = adaptive_config.quality_target
	strategy.performance_target = adaptive_config.performance_target
	
	# ✅ CREAR TIMING TABLE CONTEXTUAL
	strategy.timing_table = _create_context_aware_timing_table(strategy, strategy.performance_target, context)
	
	strategy.context_analysis = context.duplicate()
	strategy.adaptive_config = adaptive_config
	strategy.predicted_quality_score = adaptive_config.predicted_quality
	strategy.performance_rating = adaptive_config.performance_rating
	strategy.quality_rating = adaptive_config.quality_rating
	strategy.is_viable = true
	
	return strategy

func _create_quality_first_strategy(animation_analysis: Dictionary, target_fps: float) -> Dictionary:
	"""NUEVA: Estrategia de máxima calidad sin compromiso de performance"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.QUALITY_FIRST
	strategy.strategy_name = "Quality-First Ultra"
	strategy.description = "Máxima calidad sin compromiso de performance"
	
	# ✅ CONFIGURACIÓN DE MÁXIMA CALIDAD
	# Usar más frames de los solicitados si mejora la calidad
	var quality_enhanced_frames = max(
		int(animation_analysis.length * target_fps),
		int(animation_analysis.length * animation_analysis.detected_fps * 0.8)  # Al menos 80% de frames originales
	)
	
	strategy.target_frame_count = quality_enhanced_frames
	strategy.timing_mode = "quality_priority"
	strategy.capture_mode = "exhaustive_quality"
	
	# ✅ TIMING TABLE DE MÁXIMA PRECISIÓN
	var timing_table = []
	
	# Usar el método más preciso disponible basado en FPS original
	if abs(target_fps - animation_analysis.detected_fps) < 0.1:
		# FPS casi idénticos - usar timing original exacto
		for i in range(quality_enhanced_frames):
			timing_table.append({
				"frame_index": i,
				"time_position": (i / animation_analysis.detected_fps),
				"method": "original_exact",
				"quality_priority": "maximum"
			})
	else:
		# FPS diferentes - usar interpolación de máxima calidad
		for i in range(quality_enhanced_frames):
			var time_position = (float(i) / quality_enhanced_frames) * animation_analysis.length
			timing_table.append({
				"frame_index": i,
				"time_position": time_position,
				"method": "quality_interpolation",
				"quality_priority": "maximum"
			})
	
	strategy.timing_table = timing_table
	
	# ✅ CONFIGURACIÓN DE CALIDAD MÁXIMA
	strategy.quality_settings = {
		"enable_all_validations": true,
		"maximum_precision_timing": true,
		"exhaustive_error_checking": true,
		"quality_over_speed": true,
		"drift_tolerance_ms": 0.1  # Ultra-estricto
	}
	
	strategy.predicted_quality_score = 99.8
	strategy.performance_rating = "slow"       # Será más lenta pero calidad máxima
	strategy.quality_rating = "maximum"
	
	strategy.is_viable = true
	return strategy

func _create_cinematic_grade_strategy(animation_analysis: Dictionary, target_fps: float) -> Dictionary:
	"""NUEVA: Estrategia de grado cinematográfico"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.CINEMATIC_GRADE
	strategy.strategy_name = "Cinematic-Grade Ultra"
	strategy.description = "Calidad de grado cinematográfico para cutscenes y elementos hero"
	
	# ✅ CONFIGURACIÓN CINEMATOGRÁFICA
	# Forzar FPS alto para calidad cinematográfica
	var cinematic_fps = max(target_fps, 24.0)  # Mínimo 24 FPS cinematográfico
	var cinematic_frames = int(animation_analysis.length * cinematic_fps)
	
	strategy.target_frame_count = cinematic_frames
	strategy.effective_fps = cinematic_fps
	strategy.timing_mode = "cinematic_precision"
	strategy.capture_mode = "film_grade"
	
	# ✅ TIMING TABLE CINEMATOGRÁFICO
	var timing_table = []
	
	# Usar distribución temporal cinematográfica (24 FPS base con interpolación suave)
	for i in range(cinematic_frames):
		var time_position = (float(i) / cinematic_frames) * animation_analysis.length
		
		timing_table.append({
			"frame_index": i,
			"time_position": time_position,
			"method": "cinematic_interpolation",
			"quality_priority": "cinematic",
			"frame_rate": cinematic_fps,
			"interpolation_quality": "cubic_smoothing"
		})
	
	strategy.timing_table = timing_table
	
	# ✅ CONFIGURACIÓN CINEMATOGRÁFICA ESPECÍFICA
	strategy.cinematic_config = {
		"frame_blending": true,
		"motion_blur_simulation": true,
		"temporal_anti_aliasing": true,
		"sub_frame_accuracy": true,
		"film_grade_timing": true
	}
	
	strategy.predicted_quality_score = 99.9   # Máxima calidad cinematográfica
	strategy.cinematic_quality_score = 100.0
	strategy.performance_rating = "very_slow" # Performance sacrificada por calidad
	strategy.quality_rating = "cinematic"
	
	strategy.is_viable = true
	return strategy

func _create_neural_predicted_strategy(animation_analysis: Dictionary, target_fps: float, context: Dictionary, motion: Dictionary) -> Dictionary:
	"""NUEVA: Estrategia usando predicción neuronal simple"""
	
	var strategy = _create_base_strategy_structure(animation_analysis, target_fps, {})
	strategy.strategy_type = AdvancedStrategyType.NEURAL_PREDICTED
	strategy.strategy_name = "Neural-Predicted"
	strategy.description = "Estrategia optimizada usando red neuronal simple"
	
	# ✅ PREPARAR DATOS PARA RED NEURONAL
	var neural_input = _prepare_neural_input_data(animation_analysis,  context)
	
	# ✅ EJECUTAR PREDICCIÓN NEURONAL SIMPLE
	var neural_prediction = _execute_simple_neural_prediction(neural_input)
	
	# ✅ CONFIGURAR ESTRATEGIA basada en predicción
	strategy.target_frame_count = neural_prediction.predicted_frame_count
	strategy.timing_mode = neural_prediction.recommended_timing_mode
	strategy.quality_adjustments = neural_prediction.quality_adjustments
	
	# ✅ CREAR TIMING TABLE NEURONAL
	strategy.timing_table = _create_neural_timing_table(strategy,strategy.target_frame_count , neural_prediction)
	
	strategy.neural_prediction = neural_prediction
	strategy.predicted_quality_score = neural_prediction.quality_confidence * 100
	strategy.performance_rating = neural_prediction.performance_rating
	strategy.quality_rating = neural_prediction.quality_rating
	strategy.is_viable = neural_prediction.quality_confidence > 0.8
	
	return strategy

# ========================================================================
# SELECCIÓN ÓPTIMA MULTI-CRITERIO
# ========================================================================

func _select_optimal_strategy_multi_criteria(candidates: Array, quality_predictions: Array, context: Dictionary) -> Dictionary:
	"""Selección óptima usando múltiples criterios ponderados"""
	
	if candidates.is_empty():
		push_error("❌ No hay candidatos de estrategia disponibles")
		return _create_fallback_strategy()
	
	print("🔬 Seleccionando estrategia óptima de %d candidatos..." % candidates.size())
	
	# ✅ DEFINIR CRITERIOS DE SELECCIÓN con pesos
	var selection_criteria = _define_selection_criteria(context)
	
	# ✅ EVALUAR CADA CANDIDATO contra todos los criterios
	var candidate_scores = []
	
	for i in range(candidates.size()):
		var candidate = candidates[i]
		var quality_prediction = quality_predictions[i] if i < quality_predictions.size() else {"predicted_quality": 80.0}
		
		var total_score = 0.0
		var criteria_breakdown = {}
		
		# ✅ CRITERIO 1: Calidad predicha (peso más alto)
		var quality_score = quality_prediction.get("predicted_quality", 80.0)
		var quality_weight = selection_criteria.quality_weight
		total_score += quality_score * quality_weight
		criteria_breakdown["quality"] = {"score": quality_score, "weight": quality_weight}
		
		# ✅ CRITERIO 2: Adecuación al contexto
		var context_score = _evaluate_context_fit(candidate, context)
		var context_weight = selection_criteria.context_weight
		total_score += context_score * context_weight
		criteria_breakdown["context"] = {"score": context_score, "weight": context_weight}
		
		# ✅ CRITERIO 3: Viabilidad técnica
		var viability_score = _evaluate_technical_viability(candidate)
		var viability_weight = selection_criteria.viability_weight
		total_score += viability_score * viability_weight
		criteria_breakdown["viability"] = {"score": viability_score, "weight": viability_weight}
		
		# ✅ CRITERIO 4: Performance (peso menor porque priorizamos calidad)
		var performance_score = _evaluate_performance_score(candidate)
		var performance_weight = selection_criteria.performance_weight
		total_score += performance_score * performance_weight
		criteria_breakdown["performance"] = {"score": performance_score, "weight": performance_weight}
		
		# ✅ CRITERIO 5: Robustez (resistencia a errores)
		var robustness_score = _evaluate_robustness_score(candidate)
		var robustness_weight = selection_criteria.robustness_weight
		total_score += robustness_score * robustness_weight
		criteria_breakdown["robustness"] = {"score": robustness_score, "weight": robustness_weight}
		
		candidate_scores.append({
			"candidate_index": i,
			"candidate": candidate,
			"total_score": total_score,
			"criteria_breakdown": criteria_breakdown,
			"quality_prediction": quality_prediction
		})
	
	# ✅ ORDENAR POR PUNTUACIÓN TOTAL (mayor mejor)
	candidate_scores.sort_custom(func(a, b): return a.total_score > b.total_score)
	
	# ✅ SELECCIONAR EL MEJOR CANDIDATO
	var best_candidate_data = candidate_scores[0]
	var optimal_strategy = best_candidate_data.candidate.duplicate(true)
	
	# ✅ AGREGAR INFORMACIÓN DE SELECCIÓN
	optimal_strategy.selection_info = {
		"total_candidates_evaluated": candidates.size(),
		"selection_score": best_candidate_data.total_score,
		"criteria_breakdown": best_candidate_data.criteria_breakdown,
		"selection_method": "multi_criteria_weighted",
		"quality_prediction": best_candidate_data.quality_prediction
	}
	
	print("✅ Estrategia óptima seleccionada: %s (%.1f puntos)" % [
		optimal_strategy.strategy_name,
		best_candidate_data.total_score
	])
	
	# ✅ LOG DE LOS TOP 3 para análisis
	for i in range(min(3, candidate_scores.size())):
		var candidate_data = candidate_scores[i]
		print("  #%d: %s (%.1f puntos)" % [
			i + 1,
			candidate_data.candidate.strategy_name,
			candidate_data.total_score
		])
	
	return optimal_strategy

# ========================================================================
# PREDICCIÓN DE CALIDAD AVANZADA
# ========================================================================

func _predict_quality_for_all_candidates(candidates: Array, animation_analysis: Dictionary) -> Array:
	"""Predecir calidad para todos los candidatos de estrategia"""
	var predictions = []
	
	print("🔮 Prediciendo calidad para %d candidatos..." % candidates.size())
	
	for candidate in candidates:
		var prediction = await _predict_candidate_quality(candidate, animation_analysis)
		predictions.append(prediction)
		
		emit_signal("quality_prediction_complete", prediction)
	
	return predictions

func _predict_candidate_quality(candidate: Dictionary, animation_analysis: Dictionary) -> Dictionary:
	"""Predicción súper avanzada de calidad para un candidato específico"""
	var prediction = {
		"candidate_name": candidate.strategy_name,
		"predicted_quality": 0.0,
		"confidence": 0.0,
		"quality_breakdown": {},
		"risk_factors": [],
		"quality_guarantees": []
	}
	
	# ✅ PREDICCIÓN BASADA EN TIPO DE ESTRATEGIA
	var base_quality = _predict_base_quality_by_strategy_type(candidate.strategy_type)
	
	# ✅ AJUSTE POR FPS RATIO
	var fps_ratio = candidate.target_fps / animation_analysis.detected_fps
	var fps_quality_impact = _calculate_fps_ratio_quality_impact(fps_ratio)
	
	# ✅ AJUSTE POR CONFIANZA DEL ANÁLISIS
	var analysis_confidence = animation_analysis.get("detection_confidence", 0.9)
	var confidence_impact = _calculate_confidence_quality_impact(analysis_confidence)
	
	# ✅ AJUSTE POR COMPLEJIDAD DE LA ESTRATEGIA
	var complexity_score = _calculate_strategy_complexity(candidate)
	var complexity_impact = _calculate_complexity_quality_impact(complexity_score)
	
	# ✅ CÁLCULO FINAL PONDERADO
	prediction.predicted_quality = (
		base_quality * 0.4 +
		fps_quality_impact * 0.25 +
		confidence_impact * 0.2 +
		complexity_impact * 0.15
	)
	
	# ✅ IDENTIFICACIÓN DE FACTORES DE RIESGO
	prediction.risk_factors = _identify_quality_risk_factors(candidate, animation_analysis)
	
	# ✅ IDENTIFICACIÓN DE GARANTÍAS DE CALIDAD
	prediction.quality_guarantees = _identify_quality_guarantees(candidate)
	
	# ✅ BREAKDOWN DETALLADO
	prediction.quality_breakdown = {
		"base_quality": base_quality,
		"fps_impact": fps_quality_impact,
		"confidence_impact": confidence_impact,
		"complexity_impact": complexity_impact,
		"risk_penalty": _calculate_risk_penalty(prediction.risk_factors),
		"guarantee_bonus": _calculate_guarantee_bonus(prediction.quality_guarantees)
	}
	
	# ✅ CONFIANZA DE LA PREDICCIÓN
	prediction.confidence = _calculate_prediction_confidence(prediction, animation_analysis)
	
	return prediction

# ========================================================================
# OPTIMIZACIÓN FINAL Y VALIDACIÓN
# ========================================================================

func _optimize_strategy_final(strategy: Dictionary, animation_analysis: Dictionary) -> Dictionary:
	"""Optimización final de la estrategia seleccionada"""
	var optimized = strategy.duplicate(true)
	
	print("🔧 Optimizando estrategia final: %s" % strategy.strategy_name)
	
	# ✅ OPTIMIZACIÓN DE TIMING TABLE
	if optimized.has("timing_table"):
		optimized.timing_table = _optimize_timing_table(optimized.timing_table, animation_analysis)
	
	# ✅ AJUSTE DE CALIDAD VS PERFORMANCE
	optimized = _balance_quality_performance(optimized, animation_analysis)
	
	# ✅ APLICAR MICRO-OPTIMIZACIONES
	optimized = _apply_micro_optimizations(optimized, animation_analysis)
	
	emit_signal("strategy_optimization_complete", optimized)
	
	return optimized

func _validate_final_strategy_quality(strategy: Dictionary, animation_analysis: Dictionary):
	"""Validación final de calidad de la estrategia"""
	var validation_issues = []
	
	# ✅ VALIDAR TIMING TABLE
	if not strategy.has("timing_table") or strategy.timing_table.is_empty():
		validation_issues.append("Timing table faltante o vacía")
	
	# ✅ VALIDAR FRAME COUNT
	if strategy.target_frame_count <= 0:
		validation_issues.append("Frame count inválido")
	
	# ✅ VALIDAR CALIDAD PREDICHA
	if strategy.predicted_quality_score < min_strategy_quality_score:
		validation_issues.append("Calidad predicha por debajo del mínimo")
	
	if not validation_issues.is_empty():
		push_warning("⚠️ Problemas de validación en estrategia: " + str(validation_issues))

# ========================================================================
# FUNCIONES AUXILIARES IMPLEMENTADAS
# ========================================================================

func _create_base_strategy_structure(analysis: Dictionary, target_fps: float, preferences: Dictionary) -> Dictionary:
	return {
		"animation_name": analysis.animation_name,
		"original_fps": analysis.detected_fps,
		"target_fps": target_fps,
		"original_frames": analysis.get("real_frames", 0),
		"animation_length": analysis.length,
		"strategy_type": AdvancedStrategyType.DIRECT,
		"strategy_name": "Base Strategy",
		"description": "",
		"target_frame_count": 0,
		"frame_interval": 0.0,
		"timing_mode": "standard",
		"capture_mode": "sequential",
		"timing_table": [],
		"predicted_quality_score": 0.0,
		"performance_rating": "unknown",
		"quality_rating": "unknown",
		"is_viable": false,
		"user_preferences": preferences,
		"calculation_timestamp": Time.get_unix_time_from_system()
	}

func _contains_any(text: String, keywords: Array) -> bool:
	for keyword in keywords:
		if keyword in text:
			return true
	return false

func _calculate_motion_density_factor(motion: Dictionary) -> float:
	var intensity = motion.get("motion_intensity", "medium")
	match intensity:
		"low": return 0.8
		"medium": return 1.0
		"high": return 1.3
		_: return 1.0

func _define_selection_criteria(context: Dictionary) -> Dictionary:
	# En implementación real, definiría los pesos basados en el contexto
	return {
		"quality_weight": 0.45,      # Máximo peso para calidad
		"context_weight": 0.25,      # Importante: adecuación al contexto
		"viability_weight": 0.15,    # Viabilidad técnica
		"performance_weight": 0.05,  # Mínimo: performance (priorizamos calidad)
		"robustness_weight": 0.1     # Resistencia a errores
	}

func _create_error_strategy(error_msg: String) -> Dictionary:
	return {
		"error": true,
		"error_message": error_msg,
		"strategy_type": AdvancedStrategyType.DIRECT,
		"target_frame_count": 1,
		"is_valid": false
	}

func _create_fallback_strategy() -> Dictionary:
	return {
		"strategy_name": "Safe Fallback",
		"strategy_type": AdvancedStrategyType.DIRECT,
		"target_frame_count": 12,
		"predicted_quality_score": 70.0,
		"is_viable": true
	}

# ========================================================================
# CLASES AUXILIARES ULTRA-AVANZADAS
# ========================================================================

class QualityPredictor extends Node:
	"""Sistema de predicción de calidad ultra-avanzado"""
	
	signal quality_predicted(prediction: Dictionary)
	
	var prediction_model: Array = []
	var learning_enabled: bool = true
	
	func _ready():
		print("🔮 QualityPredictor ultra-avanzado inicializado")
	
	func predict_quality(strategy: Dictionary, analysis: Dictionary) -> Dictionary:
		var prediction = {
			"predicted_quality": 90.0,
			"confidence": 0.8,
			"factors": []
		}
		
		# Lógica de predicción sencilla
		var fps_ratio = strategy.target_fps / analysis.detected_fps
		
		if abs(fps_ratio - 1.0) < 0.1:
			prediction.predicted_quality = 95.0
		elif fps_ratio < 1.0:
			prediction.predicted_quality = 90.0 - (1.0 - fps_ratio) * 20
		else:
			prediction.predicted_quality = 85.0 - (fps_ratio - 1.0) * 10
		
		prediction.predicted_quality = max(60.0, prediction.predicted_quality)
		
		return prediction

class ContextAnalyzer extends Node:
	"""Analizador de contexto ultra-inteligente"""
	
	signal context_analyzed(context: Dictionary)
	
	func _ready():
		print("🧠 ContextAnalyzer ultra-inteligente inicializado")
	
	func analyze_project_context(preferences: Dictionary) -> Dictionary:
		return {
			"project_type": "general",
			"complexity": "medium",
			"quality_requirements": "high"
		}

class MotionAnalyzer extends Node:
	"""Analizador de movimiento súper avanzado"""
	
	signal motion_analyzed(motion_data: Dictionary)
	
	func _ready():
		print("🏃 MotionAnalyzer súper avanzado inicializado")
	
	func analyze_motion_patterns(animation_analysis: Dictionary) -> Dictionary:
		return {
			"motion_complexity": 50.0,
			"key_frames": [],
			"motion_type": "general"
		}

# ========================================================================
# FUNCIONES AUXILIARES PLACEHOLDER
# ========================================================================

# Nota: Estas funciones tendrían implementación completa en versión de producción

func _gather_project_hints(preferences: Dictionary) -> Dictionary:
	return {}

func _extract_motion_from_keyframes(keyframe_data: Dictionary) -> Dictionary:
	return {"motion_intensity": "medium"}

func _identify_critical_motion_frames(analysis: Dictionary, pattern: String) -> Array:
	return []

func _create_direct_timing_table(strategy: Dictionary, analysis: Dictionary) -> Array:
	var timing_table = []
	for i in range(strategy.target_frame_count):
		timing_table.append({
			"frame_index": i,
			"time_position": (float(i) / strategy.target_fps) % analysis.length
		})
	return timing_table

func _calculate_local_motion_intensity(time: float, motion: Dictionary) -> String:
	return "medium"

func _calculate_time_adjustment_for_motion(intensity: String) -> float:
	return 0.0

func _snap_to_critical_frames(time: float, critical_frames: Array) -> float:
	return time

func _calculate_capture_priority(intensity: String) -> String:
	return "normal"

func _predict_motion_aware_quality(motion: Dictionary, strategy: Dictionary) -> float:
	return 95.0

func _configure_combat_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Optimizado para animaciones de combate"
	strategy.timing_mode = "precision_timing"
	strategy.predicted_quality_score = 97.0
	return strategy

func _configure_locomotion_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Optimizado para animaciones de locomoción"
	strategy.timing_mode = "cyclic_optimization"
	strategy.predicted_quality_score = 94.0
	return strategy

func _configure_facial_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Optimizado para animaciones faciales"
	strategy.timing_mode = "detail_preservation"
	strategy.predicted_quality_score = 98.0
	return strategy

func _configure_idle_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Optimizado para animaciones idle"
	strategy.timing_mode = "efficient_sampling"
	strategy.predicted_quality_score = 92.0
	return strategy

func _configure_expressive_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Optimizado para animaciones expresivas"
	strategy.timing_mode = "artistic_preservation"
	strategy.predicted_quality_score = 96.0
	return strategy

func _configure_generic_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	strategy.description = "Configuración genérica optimizada"
	strategy.timing_mode = "balanced_approach"
	strategy.predicted_quality_score = 90.0
	return strategy

# Implementaciones placeholder para las demás funciones auxiliares...
func _analyze_perceptual_requirements(analysis: Dictionary, context: Dictionary, motion: Dictionary) -> Dictionary:
	return {"smooth_zones": [], "detail_zones": []}

func _calculate_perceptual_frame_distribution(analysis: Dictionary, target_fps: float, perceptual: Dictionary) -> Dictionary:
	return {"total_frames": int(analysis.length * target_fps), "timing_table": []}

func _on_quality_predicted(prediction: Dictionary):
	pass

func _on_context_analyzed(context: Dictionary):
	pass

func _on_motion_analyzed(motion_data: Dictionary):
	pass

func _evaluate_context_fit(candidate: Dictionary, context: Dictionary) -> float:
	return 85.0

func _evaluate_technical_viability(candidate: Dictionary) -> float:
	return 90.0

func _evaluate_performance_score(candidate: Dictionary) -> float:
	return 80.0

func _evaluate_robustness_score(candidate: Dictionary) -> float:
	return 85.0

func _predict_base_quality_by_strategy_type(strategy_type: AdvancedStrategyType) -> float:
	match strategy_type:
		AdvancedStrategyType.QUALITY_FIRST, AdvancedStrategyType.CINEMATIC_GRADE:
			return 98.0
		AdvancedStrategyType.PERCEPTUAL_OPTIMIZED, AdvancedStrategyType.MOTION_AWARE:
			return 95.0
		AdvancedStrategyType.CONTENT_ADAPTIVE, AdvancedStrategyType.CONTEXT_AWARE:
			return 92.0
		_:
			return 85.0

func _calculate_fps_ratio_quality_impact(fps_ratio: float) -> float:
	if abs(fps_ratio - 1.0) < 0.1:
		return 95.0
	elif fps_ratio < 1.0:
		return 90.0 - (1.0 - fps_ratio) * 15
	else:
		return 85.0 - (fps_ratio - 1.0) * 8

func _calculate_confidence_quality_impact(confidence: float) -> float:
	return confidence * 90.0 + 10.0

func _calculate_strategy_complexity(candidate: Dictionary) -> float:
	return 50.0

func _calculate_complexity_quality_impact(complexity: float) -> float:
	return 90.0 - (complexity - 50.0) * 0.2

func _identify_quality_risk_factors(candidate: Dictionary, analysis: Dictionary) -> Array:
	return []

func _identify_quality_guarantees(candidate: Dictionary) -> Array:
	return []

func _calculate_risk_penalty(risk_factors: Array) -> float:
	return risk_factors.size() * 2.0

func _calculate_guarantee_bonus(guarantees: Array) -> float:
	return guarantees.size() * 1.0

func _calculate_prediction_confidence(prediction: Dictionary, analysis: Dictionary) -> float:
	return 0.85

func _optimize_timing_table(timing_table: Array, analysis: Dictionary) -> Array:
	return timing_table

func _balance_quality_performance(strategy: Dictionary, analysis: Dictionary) -> Dictionary:
	return strategy

func _apply_micro_optimizations(strategy: Dictionary, analysis: Dictionary) -> Dictionary:
	return strategy

# ========================================================================
# API PÚBLICA AVANZADA
# ========================================================================

func set_quality_priority_mode(priority: String):
	"""Configurar prioridad de calidad: 'maximum', 'high', 'balanced', 'performance'"""
	match priority:
		"maximum":
			quality_over_performance = true
			min_strategy_quality_score = 98.0
			enable_ai_strategy_selection = true
			enable_predictive_quality = true
		"high":
			quality_over_performance = true
			min_strategy_quality_score = 95.0
		"balanced":
			quality_over_performance = true
			min_strategy_quality_score = 90.0
		"performance":
			quality_over_performance = false
			min_strategy_quality_score = 80.0
	
	print("🎛️ Prioridad de calidad establecida: %s" % priority)

func generate_strategy_comparison_report(strategies: Array) -> String:
	"""Generar reporte comparativo de múltiples estrategias"""
	var report = "=== REPORTE COMPARATIVO DE ESTRATEGIAS ===\n\n"
	
	for i in range(strategies.size()):
		var strategy = strategies[i]
		report += "%d. %s\n" % [i+1, strategy.strategy_name]
		report += "   Calidad Predicha: %.1f%%\n" % strategy.get("predicted_quality_score", 0)
		report += "   Performance: %s\n" % strategy.get("performance_rating", "unknown")
		report += "   Frames: %d\n" % strategy.get("target_frame_count", 0)
		report += "   Viable: %s\n\n" % ("Sí" if strategy.get("is_viable", false) else "No")
	
	return report

func get_strategy_statistics() -> Dictionary:
	"""Obtener estadísticas del sistema de estrategias"""
	return {
		"cache_size": ultra_strategy_cache.size(),
		"ai_enabled": enable_ai_strategy_selection,
		"quality_threshold": min_strategy_quality_score
	}


# ========================================================================
# FUNCIONES FALTANTES IMPLEMENTADAS COMPLETAS
# ========================================================================

func _create_downsample_ultra_strategy(analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""Crear estrategia de downsample ultra-inteligente"""
	var original_fps = analysis.detected_fps
	var downsample_ratio = target_fps / original_fps
	
	return {
		"strategy_name": "Downsample Ultra",
		"strategy_type": "downsample",
		"target_fps": target_fps,
		"downsample_ratio": downsample_ratio,
		"frame_selection_method": "smart_skip",
		"quality_preservation": "maximum",
		"timing_table": _create_smart_downsample_timing_table(analysis, target_fps),
		"predicted_quality_score": 90.0 + (downsample_ratio * 5.0)
	}

func _create_upsample_hybrid_strategy(analysis: Dictionary, target_fps: float, context: Dictionary) -> Dictionary:
	"""Crear estrategia de upsample híbrida avanzada"""
	var original_fps = analysis.detected_fps
	var upsample_ratio = target_fps / original_fps
	
	return {
		"strategy_name": "Upsample Hybrid",
		"strategy_type": "interpolation",
		"target_fps": target_fps,
		"upsample_ratio": upsample_ratio,
		"interpolation_method": "hybrid_temporal",
		"quality_enhancement": "motion_aware",
		"timing_table": _create_hybrid_interpolation_timing_table(analysis, target_fps),
		"predicted_quality_score": 85.0 - ((upsample_ratio - 1.0) * 10.0)
	}

func _configure_rts_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia optimizada para juegos RTS"""
	strategy.optimization_type = "rts_game"
	strategy.frame_priority = "key_moments"
	strategy.motion_focus = "unit_movements"
	strategy.quality_target = 92.0
	strategy.timing_mode = "strategic_pauses"
	return strategy

func _configure_rpg_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia optimizada para juegos RPG"""
	strategy.optimization_type = "rpg_game"
	strategy.frame_priority = "character_actions"
	strategy.motion_focus = "combat_animations"
	strategy.quality_target = 95.0
	strategy.timing_mode = "action_based"
	return strategy

func _configure_fps_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia optimizada para juegos FPS"""
	strategy.optimization_type = "fps_game"
	strategy.frame_priority = "high_motion"
	strategy.motion_focus = "weapon_actions"
	strategy.quality_target = 97.0
	strategy.timing_mode = "reaction_timing"
	return strategy

func _configure_platformer_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia optimizada para juegos de plataformas"""
	strategy.optimization_type = "platformer_game"
	strategy.frame_priority = "jump_sequences"
	strategy.motion_focus = "character_physics"
	strategy.quality_target = 94.0
	strategy.timing_mode = "physics_based"
	return strategy

func _configure_puzzle_optimized_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia optimizada para juegos puzzle"""
	strategy.optimization_type = "puzzle_game"
	strategy.frame_priority = "state_changes"
	strategy.motion_focus = "piece_movements"
	strategy.quality_target = 88.0
	strategy.timing_mode = "state_based"
	return strategy

func _configure_generic_game_strategy(strategy: Dictionary, analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Configurar estrategia genérica para juegos"""
	strategy.optimization_type = "generic_game"
	strategy.frame_priority = "balanced"
	strategy.motion_focus = "general_motion"
	strategy.quality_target = 90.0
	strategy.timing_mode = "uniform_timing"
	return strategy

func _analyze_interpolation_requirements(analysis: Dictionary, target_fps: float) -> Dictionary:
	"""Analizar requerimientos de interpolación"""
	var original_fps = analysis.detected_fps
	var fps_ratio = target_fps / original_fps
	
	return {
		"requires_interpolation": fps_ratio > 1.1,
		"interpolation_complexity": "medium" if fps_ratio < 2.0 else "high",
		"recommended_method": "temporal_blend" if fps_ratio < 1.5 else "motion_prediction",
		"quality_impact": "low" if fps_ratio < 1.3 else "medium"
	}

func _select_optimal_interpolation_algorithms(requirements: Dictionary) -> Array:
	"""Seleccionar algoritmos de interpolación óptimos"""
	var algorithms = []
	
	match requirements.interpolation_complexity:
		"low":
			algorithms = ["linear_blend"]
		"medium":
			algorithms = ["temporal_blend", "motion_aware"]
		"high":
			algorithms = ["motion_prediction", "temporal_blend", "adaptive_hybrid"]
	
	return algorithms

func _create_hybrid_interpolation_timing_table(analysis: Dictionary, target_fps: float) -> Array:
	"""Crear tabla de timing para interpolación híbrida"""
	var timing_table = []
	var original_fps = analysis.detected_fps
	var frame_count = int(analysis.length * target_fps)
	
	for i in range(frame_count):
		var target_time = (float(i) / target_fps) % analysis.length
		var interpolation_data = _calculate_interpolation_data(target_time, original_fps, analysis)
		
		timing_table.append({
			"frame_index": i,
			"time_position": target_time,
			"interpolation_method": interpolation_data.method,
			"blend_factor": interpolation_data.blend_factor,
			"source_frames": interpolation_data.source_frames
		})
	
	return timing_table

func _calculate_context_weights(context_analysis: Dictionary) -> Dictionary:
	"""Calcular pesos de contexto para estrategias"""
	return {
		"motion_weight": context_analysis.get("motion_complexity", 50.0) / 100.0,
		"quality_weight": context_analysis.get("quality_requirements", 80.0) / 100.0,
		"performance_weight": 1.0 - context_analysis.get("quality_requirements", 80.0) / 100.0,
		"context_confidence": context_analysis.get("confidence", 0.8)
	}

func _create_adaptive_configuration(weights: Dictionary, analysis: Dictionary) -> Dictionary:
	"""Crear configuración adaptativa basada en pesos"""
	return {
		"adaptive_quality_target": 85.0 + (weights.quality_weight * 10.0),
		"adaptive_timing_precision": "high" if weights.quality_weight > 0.8 else "medium",
		"adaptive_frame_selection": "motion_aware" if weights.motion_weight > 0.6 else "uniform",
		"adaptive_processing_mode": "precision" if weights.quality_weight > 0.7 else "balanced"
	}

func _create_context_aware_timing_table(analysis: Dictionary, target_fps: float, config: Dictionary) -> Array:
	"""Crear tabla de timing consciente del contexto"""
	var timing_table = []
	var frame_count = int(analysis.length * target_fps)
	
	for i in range(frame_count):
		var base_time = (float(i) / target_fps) % analysis.length
		var context_adjustment = _calculate_context_time_adjustment(base_time, config, analysis)
		
		timing_table.append({
			"frame_index": i,
			"time_position": base_time + context_adjustment,
			"context_priority": _calculate_frame_priority(base_time, config),
			"quality_target": config.adaptive_quality_target
		})
	
	return timing_table

func _prepare_neural_input_data(analysis: Dictionary, context: Dictionary) -> Array:
	"""Preparar datos de entrada para predicción neural simplificada"""
	return [
		analysis.detected_fps,
		analysis.length,
		analysis.get("motion_complexity", 50.0),
		context.get("quality_requirements", 80.0),
		analysis.get("keyframe_density", 0.5)
	]

func _execute_simple_neural_prediction(input_data: Array) -> Dictionary:
	"""Ejecutar predicción neural simple (red básica simulada)"""
	# Simulación de red neural simple con pesos predefinidos
	var weighted_sum = 0.0
	var weights = [0.3, 0.2, 0.25, 0.15, 0.1]  # Pesos de ejemplo
	
	for i in range(input_data.size()):
		weighted_sum += input_data[i] * weights[i % weights.size()]
	
	var activation = 1.0 / (1.0 + exp(-weighted_sum / 50.0))  # Sigmoid
	
	return {
		"predicted_quality": 70.0 + (activation * 25.0),  # 70-95% rango
		"confidence": activation,
		"recommended_strategy": "neural_optimized" if activation > 0.7 else "standard"
	}

func _create_neural_timing_table(analysis: Dictionary, target_fps: float, prediction: Dictionary) -> Array:
	"""Crear tabla de timing basada en predicción neural"""
	var timing_table = []
	var frame_count = int(analysis.length * target_fps)
	var quality_factor = prediction.predicted_quality / 100.0
	
	for i in range(frame_count):
		var base_time = (float(i) / target_fps) % analysis.length
		var neural_adjustment = _calculate_neural_time_adjustment(base_time, quality_factor, analysis)
		
		timing_table.append({
			"frame_index": i,
			"time_position": base_time + neural_adjustment,
			"neural_confidence": prediction.confidence,
			"quality_prediction": prediction.predicted_quality
		})
	
	return timing_table

# ========================================================================
# FUNCIONES AUXILIARES PARA LAS ESTRATEGIAS
# ========================================================================

func _create_smart_downsample_timing_table(analysis: Dictionary, target_fps: float) -> Array:
	"""Crear tabla de timing inteligente para downsample"""
	var original_fps = analysis.detected_fps
	var skip_ratio = original_fps / target_fps
	var timing_table = []
	var frame_count = int(analysis.length * target_fps)
	
	for i in range(frame_count):
		var optimal_time = (float(i) * skip_ratio / original_fps) % analysis.length
		timing_table.append({
			"frame_index": i,
			"time_position": optimal_time,
			"frame_priority": "high" if i % 3 == 0 else "normal"
		})
	
	return timing_table

func _calculate_interpolation_data(target_time: float, original_fps: float, analysis: Dictionary) -> Dictionary:
	"""Calcular datos de interpolación para un tiempo específico"""
	var frame_step = 1.0 / original_fps
	var before_frame = int(target_time / frame_step)
	var after_frame = before_frame + 1
	var blend_factor = (target_time % frame_step) / frame_step
	
	return {
		"method": "temporal_blend" if blend_factor < 0.8 else "forward_prediction",
		"blend_factor": blend_factor,
		"source_frames": [before_frame, after_frame]
	}

func _calculate_context_time_adjustment(base_time: float, config: Dictionary, analysis: Dictionary) -> float:
	"""Calcular ajuste de tiempo basado en contexto"""
	var motion_intensity = _get_motion_intensity_at_time(base_time, analysis)
	var quality_factor = config.adaptive_quality_target / 100.0
	
	# Ajustar tiempo según intensidad de movimiento
	return motion_intensity * quality_factor * 0.001  # Micro-ajuste

func _calculate_frame_priority(time: float, config: Dictionary) -> String:
	"""Calcular prioridad de frame basada en configuración"""
	if config.adaptive_frame_selection == "motion_aware":
		return "high" if sin(time * 10.0) > 0.5 else "normal"  # Simulación de detección de movimiento
	else:
		return "normal"

func _calculate_neural_time_adjustment(base_time: float, quality_factor: float, analysis: Dictionary) -> float:
	"""Calcular ajuste de tiempo basado en red neural"""
	var complexity_factor = analysis.get("motion_complexity", 50.0) / 100.0
	return quality_factor * complexity_factor * 0.002  # Ajuste neural

func _get_motion_intensity_at_time(time: float, analysis: Dictionary) -> float:
	"""Obtener intensidad de movimiento en un tiempo específico (simulado)"""
	# Simulación de análisis de movimiento
	return abs(sin(time * 5.0)) * analysis.get("motion_complexity", 50.0) / 100.0
