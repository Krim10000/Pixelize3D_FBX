# pixelize3d_fbx/scripts/rendering/delay_spritesheet_pipeline.gd
# Pipeline MODIFICADO para sistema de delay - LISTO PARA PRODUCCION Godot 4.4
# Input: Modelo combinado con animaciones y configuracion de DELAY/exportacion
# Output: Sprite sheets PNG completos con metadatos de delay

extends Node

# SEÑALES CORREGIDAS para Godot 4.4
signal pipeline_started(animation_name: String)
signal pipeline_progress(current_step: int, total_steps: int, message: String)
signal pipeline_complete(animation_name: String, output_path: String)
signal pipeline_failed(animation_name: String, error: String)
signal rendering_phase_started(animation_name: String)
signal rendering_phase_complete(animation_name: String)
signal export_phase_started(animation_name: String)
signal export_phase_complete(animation_name: String, file_path: String)
signal delay_analysis_started(animation_name: String)
signal delay_analysis_complete(animation_name: String, analysis: Dictionary)
signal delay_recommendation_applied(animation_name: String, old_delay: float, new_delay: float)
signal frame_timing_optimized(animation_name: String, timing_data: Dictionary)

# ========================================================================
# VARIABLES DEL PIPELINE MODIFICADAS PARA DELAY
# ========================================================================

# Referencias a componentes
var sprite_renderer: Node  # Sera el DelaySprite Renderer
var export_manager: Node
var animation_manager: Node

# Referencias especificas del delay system
var delay_recommender: Node
var config_manager: Node

# Estado del pipeline
var is_pipeline_busy: bool = false
var current_animation: String = ""
var current_config: Dictionary = {}
var pipeline_start_time: float = 0.0

# Configuracion modificada para delay
var default_render_settings: Dictionary = {
	"directions": 16,
	"sprite_size": 256,
	"frame_delay": 0.083333,  # Era fps: 12, ahora delay
	"fps_equivalent": 12.0,   # Para referencia
	"camera_angle": 45.0,
	"camera_height": 12.0,
	"camera_distance": 20.0,
	"north_offset": 0.0,
	"pixelize": true,
	"auto_delay_recommendation": true,  # Auto-recomendacion
	"show_debug_frame_numbers": false,  # Debug frames
	"timing_validation": true  # Validacion de timing
}

var default_export_settings: Dictionary = {
	"output_folder": "res://output/",
	"generate_metadata": true,
	"animation_mode": "current",
	"include_delay_info": true,  # Incluir info de delay
	"include_timing_analysis": true  # Incluir analisis de timing
}

# Variables especificas del delay system
var delay_analysis_cache: Dictionary = {}
var timing_optimizations: Dictionary = {}
var frame_perfect_count: int = 0

# ========================================================================
# INICIALIZACION
# ========================================================================

func _ready() -> void:
	print("⏱️ DelaySpritesheetPipeline inicializado")

func setup_pipeline(renderer: Node, exporter: Node, manager: Node) -> void:
	"""Configurar referencias a componentes del pipeline"""
	sprite_renderer = renderer  # Debe ser DelaySprite Renderer
	export_manager = exporter
	animation_manager = manager
	
	print("🔧 Delay Pipeline configurado:")
	print("  - DelaySprite Renderer: %s" % ("✅" if sprite_renderer else "❌"))
	print("  - ExportManager: %s" % ("✅" if export_manager else "❌"))
	print("  - AnimationManager: %s" % ("✅" if animation_manager else "❌"))
	
	# Configurar componentes adicionales del delay system
	_setup_delay_components()
	
	# Conectar señales de componentes
	_connect_component_signals()

func _setup_delay_components() -> void:
	"""Configurar componentes adicionales del delay system"""
	# Configurar delay recommender si no existe
	if not delay_recommender:
		var recommender_script = load("res://scripts/capture/delay_recommendation_analyzer.gd")
		if recommender_script:
			delay_recommender = recommender_script.new()
			add_child(delay_recommender)
			print("✅ DelayRecommendationAnalyzer integrado en pipeline")
	
	# Configurar config manager si no existe
	if not config_manager:
		config_manager = get_node_or_null("/root/ConfigManager")
		if not config_manager:
			var config_path = "res://scripts/core/delay_config_manager.gd"
			if FileAccess.file_exists(config_path):
				var config_script = load(config_path)
				if config_script:
					config_manager = config_script.new()
					add_child(config_manager)
					print("✅ DelayConfigManager integrado en pipeline")

func _connect_component_signals() -> void:
	"""Conectar señales de los componentes"""
	# Señales del sprite renderer
	if sprite_renderer:
		if sprite_renderer.has_signal("frame_rendered"):
			sprite_renderer.frame_rendered.connect(_on_frame_rendered)
		if sprite_renderer.has_signal("animation_complete"):
			sprite_renderer.animation_complete.connect(_on_animation_render_complete)
		if sprite_renderer.has_signal("rendering_progress"):
			sprite_renderer.rendering_progress.connect(_on_rendering_progress)
		
		# Señales especificas del delay system
		if sprite_renderer.has_signal("delay_analysis_complete"):
			sprite_renderer.delay_analysis_complete.connect(_on_delay_analysis_complete)
		if sprite_renderer.has_signal("frame_timing_adjusted"):
			sprite_renderer.frame_timing_adjusted.connect(_on_frame_timing_adjusted)
	
	# Señales del export manager
	if export_manager:
		if export_manager.has_signal("export_complete"):
			export_manager.export_complete.connect(_on_export_complete)
		if export_manager.has_signal("export_failed"):
			export_manager.export_failed.connect(_on_export_failed)
		if export_manager.has_signal("export_progress"):
			export_manager.export_progress.connect(_on_export_progress)
	
	# Señales del delay recommender
	if delay_recommender:
		if delay_recommender.has_signal("delay_recommendation_complete"):
			delay_recommender.delay_recommendation_complete.connect(_on_delay_recommendation_received)
	
	print("🔗 Señales de delay pipeline conectadas")

# ========================================================================
# API PRINCIPAL DEL PIPELINE MODIFICADA PARA DELAY
# ========================================================================

func generate_spritesheet(animation_name: String, config: Dictionary = {}) -> bool:
	"""
	API principal: Generar sprite sheet para una animacion especifica usando delay system
	"""
	print("\n⏱️ === INICIANDO DELAY PIPELINE DE SPRITE SHEET ===")
	print("Animacion: %s" % animation_name)
	
	if is_pipeline_busy:
		print("❌ Pipeline ocupado, no se puede iniciar")
		pipeline_failed.emit(animation_name, "Pipeline ya esta en proceso")
		return false
	
	if not _validate_pipeline_components():
		pipeline_failed.emit(animation_name, "Componentes del pipeline no disponibles")
		return false
	
	# Validacion especifica del delay system
	if not _validate_delay_system_components():
		pipeline_failed.emit(animation_name, "Delay system no disponible")
		return false
	
	# Configurar pipeline
	is_pipeline_busy = true
	current_animation = animation_name
	current_config = _merge_delay_configs(config)
	pipeline_start_time = Time.get_ticks_msec() / 1000.0
	frame_perfect_count = 0
	
	#print("📋 Configuracion de delay consolidada:")
	#print("  - Direcciones: %d" % current_config.get("directions", 16))
	#print("  - Tamaño sprite: %d" % current_config.get("sprite_size", 256))
	#print("  - Frame delay: %.4fs" % current_config.get("frame_delay", 0.083333))
	#print("  - FPS equivalente: %.1f" % current_config.get("fps_equivalent", 12.0))
	#print("  - Auto-recomendacion: %s" % ("ON" if current_config.get("auto_delay_recommendation", true) else "OFF"))
	#print("  - Debug frames: %s" % ("ON" if current_config.get("show_debug_frame_numbers", false) else "OFF"))
	#print("  - Carpeta salida: %s" % current_config.get("output_folder", "res://output/"))
	
	pipeline_started.emit(animation_name)
	
	# Iniciar proceso asincrono con delay system
	_start_delay_pipeline_process()
	
	return true

func generate_all_spritesheets(config: Dictionary = {}) -> bool:
	"""
	Generar sprite sheets para todas las animaciones disponibles usando delay system
	"""
	if not animation_manager or not animation_manager.has_method("get_available_animation_names"):
		print("❌ No se pueden obtener animaciones disponibles")
		return false
	
	var animations: Array = animation_manager.get_available_animation_names()
	
	if animations.is_empty():
		print("❌ No hay animaciones disponibles")
		return false
	
	print("🔄 Generando %d spritesheets con delay system..." % animations.size())
	_generate_multiple_spritesheets_with_delay(animations, config)
	
	return true

# ========================================================================
# PROCESO DEL PIPELINE CON DELAY SYSTEM
# ========================================================================

func _start_delay_pipeline_process() -> void:
	"""Iniciar proceso del pipeline con delay system"""
	print("🚀 Iniciando proceso de delay pipeline...")
	
	# FASE 1: Analisis de delay optimo
	delay_analysis_started.emit(current_animation)
	await _analyze_animation_for_optimal_delay()
	
	# FASE 2: Configuracion de componentes
	pipeline_progress.emit(1, 5, "Configurando delay renderer...")
	await _configure_delay_components()
	
	# FASE 3: Renderizado con delay system
	pipeline_progress.emit(2, 5, "Renderizando con delay system...")
	rendering_phase_started.emit(current_animation)
	var render_success: bool = await _render_animation_with_delay()
	
	if not render_success:
		_finish_pipeline(false, "Error en renderizado con delay system")
		return
	
	rendering_phase_complete.emit(current_animation)
	
	# FASE 4: Optimizacion de timing
	pipeline_progress.emit(3, 5, "Optimizando timing de frames...")
	await _optimize_frame_timing()
	
	# FASE 5: Exportacion con metadata de delay
	pipeline_progress.emit(4, 5, "Exportando con metadata de delay...")
	export_phase_started.emit(current_animation)
	var export_success: bool = await _export_with_delay_metadata()
	
	if export_success:
		_finish_pipeline(true, "Pipeline de delay completado exitosamente")
	else:
		_finish_pipeline(false, "Error en exportacion con metadata de delay")

func _analyze_animation_for_optimal_delay() -> void:
	"""Analizar animacion para delay optimo"""
	if not current_config.get("auto_delay_recommendation", true):
		print("⏭️ Auto-recomendacion deshabilitada, usando delay manual")
		return
	
	if not animation_manager or not animation_manager.has_method("get_animation"):
		print("❌ No se puede obtener animacion para analisis")
		return
	
	# Obtener animacion
	var animation = animation_manager.get_animation(current_animation)
	if not animation:
		print("❌ Animacion no encontrada para analisis: %s" % current_animation)
		return
	
	print("🔬 Analizando animacion para delay optimo: %s" % current_animation)
	
	# Usar delay recommender si esta disponible
	if delay_recommender and delay_recommender.has_method("recommend_optimal_delay"):
		var recommendation: Dictionary = delay_recommender.recommend_optimal_delay(animation, current_animation)
		_process_delay_recommendation(recommendation)
	
	# Cachear analisis
	delay_analysis_cache[current_animation] = {
		"timestamp": Time.get_unix_time_from_system(),
		"original_delay": current_config.get("frame_delay", 0.083333),
		"analysis_performed": true
	}

func _process_delay_recommendation(recommendation: Dictionary) -> void:
	"""Procesar recomendacion de delay"""
	if recommendation.get("confidence", 0.0) < 0.7:
		print("⚠️ Confianza de recomendacion baja (%.1f%%), manteniendo delay manual" % (recommendation.confidence * 100))
		return
	
	var old_delay: float = current_config.get("frame_delay", 0.083333)
	var new_delay: float = recommendation.get("recommended_delay", old_delay)
	
	if abs(new_delay - old_delay) > 0.001:  # Cambio significativo
		print("🎯 Aplicando recomendacion de delay:")
		print("  Delay anterior: %.4fs (%.1f FPS)" % [old_delay, 1.0/old_delay if old_delay > 0 else 0])
		print("  Delay recomendado: %.4fs (%.1f FPS)" % [new_delay, recommendation.get("recommended_fps_equivalent", 12.0)])
		print("  Confianza: %.1f%%" % (recommendation.confidence * 100))
		print("  Frame perfect: %s" % recommendation.get("frame_perfect", false))
		
		current_config.frame_delay = new_delay
		current_config.fps_equivalent = recommendation.get("recommended_fps_equivalent", 1.0/new_delay)
		
		if recommendation.get("frame_perfect", false):
			frame_perfect_count += 1
		
		delay_recommendation_applied.emit(current_animation, old_delay, new_delay)
	
	# Emitir analisis completo
	delay_analysis_complete.emit(current_animation, recommendation)

func _configure_delay_components() -> void:
	"""Configurar componentes para delay system"""
	print("⚙️ Configurando componentes para delay system...")
	
	# Configurar delay sprite renderer
	if sprite_renderer and sprite_renderer.has_method("update_render_settings"):
		var delay_render_settings: Dictionary = _extract_delay_render_settings(current_config)
		sprite_renderer.update_render_settings(delay_render_settings)
		print("✅ DelaySprite Renderer configurado")
	
	# Configurar export manager para metadata de delay
	if export_manager and export_manager.has_method("set_export_config"):
		var delay_export_settings: Dictionary = _extract_delay_export_settings(current_config)
		export_manager.set_export_config(delay_export_settings)
		print("✅ Export Manager configurado para delay metadata")
	
	await get_tree().process_frame

func _render_animation_with_delay() -> bool:
	"""Renderizar animacion usando delay system"""
	print("🎬 Renderizando animacion con delay system...")
	
	if not animation_manager or not animation_manager.has_method("get_combined_model"):
		print("❌ No se puede obtener modelo combinado")
		return false
	
	var combined_model: Node3D = animation_manager.get_combined_model()
	if not combined_model:
		print("❌ Modelo combinado no disponible")
		return false
	
	var total_directions: int = current_config.get("directions", 16)
	var successful_directions: int = 0
	
	print("🎯 Renderizando %d direcciones..." % total_directions)
	
	# Renderizar cada direccion
	for direction in range(total_directions):
		# Verificar que el modelo sigue siendo valido
		if not combined_model or not is_instance_valid(combined_model):
			print("❌ Modelo se invalido durante renderizado")
			break
		
		var angle: float = direction * (360.0 / total_directions)
		
		# Aplicar north offset si existe
		var north_offset: float = current_config.get("north_offset", 0.0)
		angle += north_offset
		
		#print("  🧭 Renderizando direccion %d/%d: %.1f°" % [direction + 1, total_directions, angle])
		
		# Emitir progreso de la fase de renderizado
		var progress: float = float(direction) / float(total_directions)
		var message: String = "Renderizando direccion %d/%d con delay system" % [direction + 1, total_directions]
		pipeline_progress.emit(2, 5, message)
		
		# Renderizar esta direccion usando delay system
		if sprite_renderer and sprite_renderer.has_method("render_animation"):
			sprite_renderer.render_animation(combined_model, current_animation, angle, direction)
			
			# Esperar a que termine esta direccion especifica
			await sprite_renderer.animation_complete
			successful_directions += 1
			
			print("    ✅ Direccion %d completada con delay system" % (direction + 1))
		else:
			print("    ❌ Error: metodo render_animation no disponible en delay renderer")
			break
		
		# Pequeña pausa entre direcciones
		await get_tree().process_frame
	
	# Evaluar resultado
	if successful_directions == total_directions:
		print("✅ Todas las direcciones renderizadas exitosamente con delay system (%d/%d)" % [successful_directions, total_directions])
		return true
	else:
		print("⚠️ Solo %d/%d direcciones completadas con delay system" % [successful_directions, total_directions])
		return false

func _optimize_frame_timing() -> void:
	"""Optimizar timing de frames"""
	print("⚡ Optimizando timing de frames...")
	
	# Recopilar datos de timing si estan disponibles
	var timing_data: Dictionary = {
		"animation_name": current_animation,
		"frame_delay": current_config.get("frame_delay", 0.083333),
		"fps_equivalent": current_config.get("fps_equivalent", 12.0),
		"frame_perfect_optimizations": frame_perfect_count,
		"timing_validation_enabled": current_config.get("timing_validation", true)
	}
	
	# Guardar optimizaciones para esta animacion
	timing_optimizations[current_animation] = timing_data
	
	# Emitir datos de timing optimizado
	frame_timing_optimized.emit(current_animation, timing_data)
	
	await get_tree().process_frame

func _export_with_delay_metadata() -> bool:
	"""Exportar con metadata de delay"""
	print("📦 Exportando con metadata de delay...")
	
	if not export_manager or not export_manager.has_method("export_sprite_sheets"):
		print("❌ Export Manager no disponible")
		return false
	
	# Preparar configuracion de exportacion con delay metadata
	var enhanced_export_config: Dictionary = current_config.duplicate()
	
	# Añadir informacion especifica del delay system
	enhanced_export_config.delay_metadata = {
		"frame_delay": current_config.get("frame_delay", 0.083333),
		"fps_equivalent": current_config.get("fps_equivalent", 12.0),
		"auto_recommendation_used": current_config.get("auto_delay_recommendation", true),
		"frame_perfect_achieved": frame_perfect_count > 0,
		"timing_analysis": timing_optimizations.get(current_animation, {}),
		"delay_analysis": delay_analysis_cache.get(current_animation, {}),
		"generation_timestamp": Time.get_unix_time_from_system()
	}
	
	# Añadir configuracion de animacion actual
	enhanced_export_config.current_animation = current_animation
	enhanced_export_config.animation_mode = "current"
	
	#print("📋 Configuracion de exportacion con delay:")
	#print("  - Frame delay: %.4fs" % enhanced_export_config.delay_metadata.frame_delay)
	#print("  - FPS equivalente: %.1f" % enhanced_export_config.delay_metadata.fps_equivalent)
	#print("  - Frame perfect: %s" % enhanced_export_config.delay_metadata.frame_perfect_achieved)
	#
	# Iniciar exportacion
	export_manager.export_sprite_sheets(enhanced_export_config)
	
	# Esperar a que complete
	await export_manager.export_complete
	return true

# ========================================================================
# FUNCIONES AUXILIARES PARA DELAY SYSTEM
# ========================================================================

func _validate_delay_system_components() -> bool:
	"""Validar componentes especificos del delay system"""
	if sprite_renderer and not sprite_renderer.has_method("set_frame_delay"):
		print("❌ Sprite Renderer no es compatible con delay system")
		return false
	
	return true

func _merge_delay_configs(user_config: Dictionary) -> Dictionary:
	"""Fusionar configuracion del usuario con valores por defecto de delay"""
	var merged_render: Dictionary = default_render_settings.duplicate()
	var merged_export: Dictionary = default_export_settings.duplicate()
	
	# Fusionar configuraciones
	for key in user_config:
		if key in merged_render:
			merged_render[key] = user_config[key]
		elif key in merged_export:
			merged_export[key] = user_config[key]
	
	# Validaciones especificas del delay system
	if merged_render.has("frame_delay"):
		var delay: float = merged_render.frame_delay
		if delay <= 0 or delay > 1.0:
			print("⚠️ Delay invalido (%.4fs), usando default" % delay)
			merged_render.frame_delay = 0.083333
			merged_render.fps_equivalent = 12.0
		else:
			merged_render.fps_equivalent = 1.0 / delay
	
	# Combinar ambas configuraciones
	var final_config: Dictionary = merged_render.duplicate()
	for key in merged_export:
		final_config[key] = merged_export[key]
	
	return final_config

func _extract_delay_render_settings(config: Dictionary) -> Dictionary:
	"""Extraer configuraciones de renderizado para delay system"""
	var delay_keys: Array[String] = [
		"directions", "sprite_size", "frame_delay", "fps_equivalent", 
		"camera_angle", "camera_height", "camera_distance", "north_offset", 
		"pixelize", "auto_delay_recommendation", "show_debug_frame_numbers", "timing_validation"
	]
	var delay_render_settings: Dictionary = {}
	
	for key in delay_keys:
		if config.has(key):
			delay_render_settings[key] = config[key]
	
	return delay_render_settings

func _extract_delay_export_settings(config: Dictionary) -> Dictionary:
	"""Extraer configuraciones de exportacion para delay system"""
	var delay_export_keys: Array[String] = [
		"output_folder", "generate_metadata", "animation_mode", 
		"include_delay_info", "include_timing_analysis"
	]
	var delay_export_settings: Dictionary = {}
	
	for key in delay_export_keys:
		if config.has(key):
			delay_export_settings[key] = config[key]
	
	return delay_export_settings

# ========================================================================
# MANEJADORES DE SEÑALES
# ========================================================================

func _on_frame_rendered(frame_data: Dictionary) -> void:
	"""Manejar frame renderizado"""
	pass  # El export manager se encarga de recopilar frames

func _on_animation_render_complete(animation_name: String) -> void:
	"""Manejar completacion de renderizado de animacion"""
	print("✅ Renderizado de direccion completado: %s" % animation_name)

func _on_rendering_progress(current: int, total: int) -> void:
	"""Manejar progreso de renderizado"""
	pass  # Ya manejado en el bucle principal

# Nuevos manejadores especificos del delay system
func _on_delay_analysis_complete(animation_name: String, analysis: Dictionary) -> void:
	"""Manejar analisis de delay completado"""
	print("🔬 Analisis de delay completado para: %s" % animation_name)
	print("  - Delay recomendado: %.4fs" % analysis.get("recommended_delay", 0.083333))
	print("  - Confianza: %.1f%%" % (analysis.get("confidence", 0.0) * 100))

func _on_frame_timing_adjusted(frame_index: int, target_time: float, actual_time: float) -> void:
	"""Manejar ajuste de timing de frame"""
	var timing_error: float = abs(actual_time - target_time)
	if timing_error > 0.001:  # Solo reportar errores significativos
		print("⏰ Timing ajustado frame %d: target=%.4fs, actual=%.4fs (error=%.4fs)" % [
			frame_index, target_time, actual_time, timing_error
		])

func _on_delay_recommendation_received(animation_name: String, recommendation: Dictionary) -> void:
	"""Manejar recomendacion de delay recibida"""
	print("📨 Recomendacion de delay recibida para %s" % animation_name)
	_process_delay_recommendation(recommendation)

# Manejadores de exportacion
func _on_export_complete(file_path: String) -> void:
	"""Manejar completacion exitosa de exportacion"""
	print("✅ Exportacion con delay metadata completada: %s" % file_path)
	export_phase_complete.emit(current_animation, file_path)

func _on_export_failed(error: String) -> void:
	"""Manejar fallo en exportacion"""
	print("❌ Error en exportacion con delay metadata: %s" % error)
	_finish_pipeline(false, "Error en exportacion: " + error)

func _on_export_progress(current: int, total: int, message: String) -> void:
	"""Manejar progreso de exportacion"""
	var phase_progress: float = float(current) / float(total) * 0.2  # 20% del total
	var overall_progress: float = 0.8 + phase_progress  # Fase final empieza en 80%
	
	pipeline_progress.emit(4, 5, message)

# ========================================================================
# FINALIZACION DEL PIPELINE
# ========================================================================

func _finish_pipeline(success: bool, message: String) -> void:
	"""Finalizar pipeline con estadisticas de delay system"""
	is_pipeline_busy = false
	
	var duration: float = (Time.get_ticks_msec() / 1000.0) - pipeline_start_time
	
	print("\n⏱️ === PIPELINE DE DELAY %s ===" % ("COMPLETADO" if success else "FALLO"))
	print("Duracion: %.1fs" % duration)
	print("Frame perfect optimizations: %d" % frame_perfect_count)
	print("Timing optimizations: %d" % timing_optimizations.size())
	print("Mensaje: %s" % message)
	
	if success:
		pipeline_complete.emit(current_animation, current_config.get("output_folder", "res://output/"))
	else:
		pipeline_failed.emit(current_animation, message)

# ========================================================================
# FUNCIONES AUXILIARES
# ========================================================================

func _validate_pipeline_components() -> bool:
	"""Validar que todos los componentes esten disponibles"""
	if not sprite_renderer:
		print("❌ SpriteRenderer no disponible")
		return false
	
	if not export_manager:
		print("❌ ExportManager no disponible")
		return false
	
	if not animation_manager:
		print("❌ AnimationManager no disponible")
		return false
	
	return true

func _generate_multiple_spritesheets_with_delay(animations: Array, config: Dictionary) -> void:
	"""Generar multiples sprite sheets con delay system"""
	print("🔄 Procesando %d animaciones con delay system..." % animations.size())
	
	is_pipeline_busy = true
	var successful_animations: int = 0
	var total_animations: int = animations.size()
	
	for i in range(animations.size()):
		var anim_name: String = animations[i]
		#print("\n--- Procesando animacion %d/%d con delay: %s ---" % [i + 1, total_animations, anim_name])
		
		# Configurar para esta animacion
		current_animation = anim_name
		current_config = _merge_delay_configs(config)
		
		# Ejecutar pipeline para esta animacion
		pipeline_started.emit(anim_name)
		
		var success: bool = await generate_spritesheet(anim_name, config)
		
		if success:
			successful_animations += 1
		
		# Pequeña pausa entre animaciones
		await get_tree().process_frame
	
	print("\n✅ Proceso multiple completado: %d/%d animaciones exitosas con delay system" % [successful_animations, total_animations])
	_finish_pipeline(successful_animations > 0, "Proceso multiple completado")

# ========================================================================
# API PUBLICA ESPECIFICA DEL DELAY SYSTEM
# ========================================================================

func get_delay_pipeline_status() -> Dictionary:
	"""Obtener estado del delay pipeline"""
	return {
		"pipeline_busy": is_pipeline_busy,
		"current_animation": current_animation,
		"delay_system_enabled": current_config.get("auto_delay_recommendation", true),
		"frame_perfect_count": frame_perfect_count,
		"timing_optimizations": timing_optimizations.size(),
		"cached_analyses": delay_analysis_cache.size()
	}

func clear_delay_cache() -> void:
	"""Limpiar cache de analisis de delay"""
	delay_analysis_cache.clear()
	timing_optimizations.clear()
	frame_perfect_count = 0
	print("🗑️ Cache de delay pipeline limpiado")

func is_busy() -> bool:
	"""Verificar si el pipeline esta ocupado"""
	return is_pipeline_busy
