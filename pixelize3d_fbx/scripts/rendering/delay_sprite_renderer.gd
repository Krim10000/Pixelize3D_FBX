# pixelize3d_fbx/scripts/rendering/delay_sprite_renderer.gd
# Sprite Renderer MODIFICADO para sistema de delay - LISTO PARA PRODUCCION Godot 4.4
# Input: Modelo 3D combinado con animaciones y configuracion de DELAY
# Output: Frames renderizados usando delay fijo en lugar de FPS

extends Node3D

# SEÑALES CORREGIDAS para Godot 4.4
signal frame_rendered(frame_data: Dictionary)
signal animation_complete(animation_name: String)
signal rendering_progress(current: int, total: int)
signal delay_analysis_complete(animation_name: String, analysis: Dictionary)
signal frame_timing_adjusted(frame_index: int, target_time: float, actual_time: float)

# Referencias heredadas del sistema original
var preview_panel: Control
var viewport: SubViewport
var camera: Camera3D
var camera_controller: Node3D
var model_container: Node3D
var anim_manager: Node
var orientation_analyzer: Node

# Referencias para sistema de delay
var delay_recommender: Node
var debug_overlay: Node
var timing_validator: Node

# Configuracion de renderizado modificada para delay
var render_settings: Dictionary
var current_model: Node3D
var frames_buffer: Array[Dictionary] = []

# Estado del renderizado
var is_rendering: bool = false
var current_animation: String = ""
var current_direction: int = 0
var current_frame: int = 0
var total_frames: int = 0

# Variables especificas del sistema de delay
var frame_delay: float = 0.083333  # Default: 12 FPS equivalent
var delay_recommendation_enabled: bool = true
var debug_frame_numbers_enabled: bool = false
var current_animation_duration: float = 0.0
var frame_timings: Array[float] = []  # Array con tiempos especificos de cada frame

# Estado de la camara durante renderizado
var original_viewport_mode: int
var render_backup_model: Node3D

func _ready() -> void:
	print("⏱️ DelaySprite Renderer inicializado - Sistema de DELAY activo")
	call_deferred("_initialize_delay_system")

func _initialize_delay_system() -> void:
	"""Inicializar sistema de delay"""
	_initialize_shared_references()  # Heredado del original
	_setup_delay_components()
	_setup_debug_overlay()
	_connect_delay_signals()
	
	print("✅ Sistema de delay completamente inicializado")

# ========================================================================
# CONFIGURACION DEL SISTEMA DE DELAY
# ========================================================================

func _setup_delay_components() -> void:
	"""Configurar componentes especificos del sistema de delay"""
	
	# Cargar y configurar delay recommender
	var recommender_script = load("res://scripts/capture/delay_recommendation_analyzer.gd")
	if recommender_script:
		delay_recommender = recommender_script.new()
		add_child(delay_recommender)
		print("✅ DelayRecommendationAnalyzer integrado")
	
	# Cargar timing validator (opcional)
	var validator_path = "res://scripts/capture/frame_perfect_capture_complete.gd"
	if FileAccess.file_exists(validator_path):
		var validator_script = load(validator_path)
		if validator_script:
			timing_validator = validator_script.new()
			add_child(timing_validator)
			print("✅ TimingValidator integrado")

func _setup_debug_overlay() -> void:
	"""Configurar sistema de debug overlay"""
	var overlay_path = "res://scripts/rendering/debug_frame_overlay.gd"
	if FileAccess.file_exists(overlay_path):
		var overlay_script = load(overlay_path)
		if overlay_script:
			debug_overlay = overlay_script.new()
			add_child(debug_overlay)
			
			# Configurar apariencia por defecto
			if debug_overlay.has_method("set_debug_appearance"):
				debug_overlay.set_debug_appearance({
					"font_size": 18,
					"text_color": Color.WHITE,
					"background_color": Color(0, 0, 0, 0.8),
					"corner_offset": Vector2i(8, 8)
				})
			
			print("✅ DebugFrameOverlay integrado")

func _connect_delay_signals() -> void:
	"""Conectar señales especificas del sistema de delay"""
	if delay_recommender:
		# CONEXION CORREGIDA para Godot 4.4
		if delay_recommender.has_signal("delay_recommendation_complete"):
			delay_recommender.delay_recommendation_complete.connect(_on_delay_recommendation_received)

func _initialize_shared_references() -> void:
	"""Inicializar referencias compartidas (heredado del original)"""
	# Buscar preview panel
	preview_panel = get_node_or_null("/root/Main/UI/ModelPreviewPanel")
	
	if preview_panel:
		viewport = preview_panel.get_node_or_null("ViewportContainer/SubViewport")
		
		if viewport:
			camera_controller = viewport.get_node_or_null("CameraController")
			model_container = viewport.get_node_or_null("ModelContainer")
			
			if camera_controller:
				camera = camera_controller.get_node_or_null("Camera3D")
	
	# Buscar animation manager
	anim_manager = get_node_or_null("/root/Main/AnimationManager")
	
	print("📡 Referencias compartidas: Preview=%s, Viewport=%s, Camera=%s" % [
		"✅" if preview_panel else "❌",
		"✅" if viewport else "❌", 
		"✅" if camera else "❌"
	])

# ========================================================================
# API PRINCIPAL CON SISTEMA DE DELAY
# ========================================================================

func update_render_settings(new_settings: Dictionary) -> void:
	"""Actualizar configuracion de renderizado con delay"""
	print("⏱️ Actualizando configuracion de delay renderer...")
	
	render_settings = new_settings.duplicate()
	
	# Extraer configuracion de delay especifica
	if render_settings.has("frame_delay"):
		frame_delay = render_settings.frame_delay
		print("  Frame delay: %.4fs (%.1f FPS equiv)" % [frame_delay, 1.0/frame_delay if frame_delay > 0 else 0])
	
	if render_settings.has("show_debug_frame_numbers"):
		debug_frame_numbers_enabled = render_settings.show_debug_frame_numbers
		if debug_overlay and debug_overlay.has_method("set_debug_enabled"):
			debug_overlay.set_debug_enabled(debug_frame_numbers_enabled)
		print("  Debug frame numbers: %s" % ("ON" if debug_frame_numbers_enabled else "OFF"))
	
	if render_settings.has("auto_delay_recommendation"):
		delay_recommendation_enabled = render_settings.auto_delay_recommendation
		print("  Auto delay recommendation: %s" % ("ON" if delay_recommendation_enabled else "OFF"))
	
	# Aplicar configuracion de camara (heredado)
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		var camera_settings: Dictionary = {
			"camera_angle": render_settings.get("camera_angle", 45.0),
			"camera_height": render_settings.get("camera_height", 12.0),
			"camera_distance": render_settings.get("camera_distance", 20.0),
			"north_offset": render_settings.get("north_offset", 270.0)
		}
		camera_controller.set_camera_settings(camera_settings)
		print("✅ Configuracion de camara aplicada")

# ========================================================================
# RENDERIZADO CON SISTEMA DE DELAY
# ========================================================================

func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int) -> void:
	"""Renderizar animacion usando sistema de delay en lugar de FPS"""
	
	# Validaciones basicas (heredadas)
	if not _validate_shared_render_prerequisites():
		animation_complete.emit(animation_name)
		return
		
	if not is_instance_valid(model):
		push_error("❌ Modelo no es valido para renderizado")
		animation_complete.emit(animation_name)
		return
	
	if is_rendering:
		print("⚠️ Ya hay un renderizado en proceso")
		animation_complete.emit(animation_name)
		return
	
	print("⏱️ Renderizando con SISTEMA DE DELAY: %s, direccion %d, angulo %.1f°" % [animation_name, direction_index, angle])
	
	# Configurar estado
	is_rendering = true
	current_animation = animation_name
	current_direction = direction_index
	current_frame = 0
	
	# Preparar viewport compartido para renderizado
	_switch_to_render_mode(model, angle)
	
	# Analisis de DELAY para esta animacion especifica
	var anim_player: AnimationPlayer = current_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(animation_name):
		var anim: Animation = anim_player.get_animation(animation_name)
		current_animation_duration = anim.length
		
		# Recomendacion automatica de DELAY si esta habilitada
		if delay_recommendation_enabled and delay_recommender:
			_request_delay_recommendation_for_animation(anim, animation_name)
		
		# Calcular frames usando DELAY en lugar de FPS
		total_frames = _calculate_total_frames_with_delay(anim.length, frame_delay)
		frame_timings = _generate_frame_timings(anim.length, total_frames)
		
		print("📊 Animacion: %s, %.3fs, %d frames con delay %.4fs" % [
			animation_name, anim.length, total_frames, frame_delay
		])
		
		# Emitir analisis completo
		delay_analysis_complete.emit(animation_name, {
			"animation_duration": anim.length,
			"frame_delay": frame_delay,
			"total_frames": total_frames,
			"fps_equivalent": 1.0 / frame_delay if frame_delay > 0 else 0,
			"frame_timings": frame_timings
		})
		
		# Iniciar renderizado de frames
		_render_next_frame_with_delay()
	else:
		# Si no hay animacion, renderizar un solo frame
		total_frames = 1
		frame_timings = [0.0]
		_render_static_frame()

func _calculate_total_frames_with_delay(duration: float, delay: float) -> int:
	"""Calcular total de frames usando delay en lugar de FPS"""
	if delay <= 0:
		print("❌ Delay invalido: %.4fs, usando default" % delay)
		delay = 0.083333  # Fallback a 12 FPS
	
	var calculated_frames: int = int(duration / delay)
	
	# Asegurar al menos 1 frame
	if calculated_frames < 1:
		calculated_frames = 1
	
	print("🧮 Calculo de frames: %.3fs ÷ %.4fs = %d frames" % [duration, delay, calculated_frames])
	return calculated_frames

func _generate_frame_timings(duration: float, total_frames_count: int) -> Array[float]:
	"""Generar array con timings especificos de cada frame"""
	var timings: Array[float] = []
	
	if total_frames_count <= 1:
		timings.append(0.0)
		return timings
	
	# Generar timings uniformes usando delay
	for frame_idx in range(total_frames_count):
		var time: float = frame_idx * frame_delay
		
		# Asegurar que no exceda la duracion de la animacion
		if time > duration:
			time = duration
		
		timings.append(time)
	
	print("⏰ Frame timings generados: [%.3f, %.3f, ..., %.3f]" % [
		timings[0] if timings.size() > 0 else 0.0,
		timings[1] if timings.size() > 1 else 0.0,
		timings[-1] if timings.size() > 0 else 0.0
	])
	
	return timings

func _request_delay_recommendation_for_animation(anim: Animation, anim_name: String) -> void:
	"""Solicitar recomendacion de delay para la animacion"""
	if delay_recommender and delay_recommender.has_method("recommend_optimal_delay"):
		print("🎯 Solicitando recomendacion de delay para: %s" % anim_name)
		# La recomendacion se procesara en _on_delay_recommendation_received
		delay_recommender.recommend_optimal_delay(anim, anim_name)

func _on_delay_recommendation_received(animation_name: String, recommendation: Dictionary) -> void:
	"""Recibir recomendacion de delay automatica"""
	print("📨 Recomendacion recibida para %s:" % animation_name)
	print("  Delay recomendado: %.4fs (%.1f FPS equiv)" % [
		recommendation.get("recommended_delay", frame_delay),
		recommendation.get("recommended_fps_equivalent", 12.0)
	])
	print("  Confianza: %.1f%%" % (recommendation.get("confidence", 0.0) * 100))
	print("  Frame perfect: %s" % recommendation.get("frame_perfect", false))
	
	# Aplicar recomendacion si la confianza es alta
	if recommendation.get("confidence", 0.0) > 0.8:
		var recommended_delay: float = recommendation.get("recommended_delay", frame_delay)
		
		print("✅ Aplicando recomendacion automatica: %.4fs delay" % recommended_delay)
		frame_delay = recommended_delay
		
		# Recalcular frames si estamos en proceso de renderizado
		if is_rendering and current_animation_duration > 0:
			total_frames = _calculate_total_frames_with_delay(current_animation_duration, frame_delay)
			frame_timings = _generate_frame_timings(current_animation_duration, total_frames)

# ========================================================================
# RENDERIZADO DE FRAMES CON TIMING PRECISO
# ========================================================================

func _render_next_frame_with_delay() -> void:
	"""Renderizar siguiente frame usando timing de delay preciso"""
	if current_frame >= total_frames:
		_finish_rendering()
		return
	
	if not current_model or not is_instance_valid(current_model):
		push_error("❌ Modelo se invalido durante el renderizado")
		_finish_rendering()
		return
	
	# Obtener timing especifico para este frame
	var target_time: float = 0.0
	if current_frame < frame_timings.size():
		target_time = frame_timings[current_frame]
	
	print("⏰ Renderizando frame %d/%d en tiempo %.4fs" % [current_frame + 1, total_frames, target_time])
	
	# Aplicar timing preciso al AnimationPlayer
	_apply_precise_frame_timing(target_time)
	
	# Esperar frames para garantizar render limpio
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	
	# Configurar viewport para captura
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	
	# Captura del frame usando viewport compartido
	var image: Image = viewport.get_texture().get_image().duplicate()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	# Aplicar debug overlay si esta habilitado
	if debug_frame_numbers_enabled and debug_overlay:
		var frame_data_for_debug: Dictionary = {
			"frame": current_frame,
			"direction": current_direction,
			"animation": current_animation
		}
		if debug_overlay.has_method("apply_debug_overlay"):
			image = debug_overlay.apply_debug_overlay(image, frame_data_for_debug)

	var frame_data: Dictionary = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": current_frame,
		"angle": _get_current_camera_angle(),
		"image": image,
		"timing_data": {
			"target_time": target_time,
			"frame_delay": frame_delay,
			"fps_equivalent": 1.0 / frame_delay if frame_delay > 0 else 0
		}
	}

	# EMISION CORREGIDA para Godot 4.4
	frame_rendered.emit(frame_data)
	rendering_progress.emit(current_frame + 1, total_frames)

	current_frame += 1
	call_deferred("_render_next_frame_with_delay")

func _apply_precise_frame_timing(target_time: float) -> void:
	"""Aplicar timing preciso al AnimationPlayer"""
	var anim_player: AnimationPlayer = current_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not anim_player:
		return
	
	# Aplicar seek preciso
	anim_player.seek(target_time, true)
	anim_player.advance(0.0)
	
	# Validar timing aplicado
	var actual_time: float = anim_player.current_animation_position
	var timing_error: float = abs(actual_time - target_time)
	
	if timing_error > 0.001:  # Mas de 1ms de error
		print("⚠️ Timing error: target=%.4fs, actual=%.4fs, error=%.4fs" % [
			target_time, actual_time, timing_error
		])
	
	# Emitir informacion de timing
	frame_timing_adjusted.emit(current_frame, target_time, actual_time)

# ========================================================================
# FUNCIONES AUXILIARES Y HEREDADAS
# ========================================================================

func _validate_shared_render_prerequisites() -> bool:
	"""Validar prerrequisitos compartidos (heredado)"""
	if not preview_panel:
		print("❌ No hay preview panel disponible")
		return false
	
	if not viewport:
		print("❌ No hay viewport disponible")
		return false
	
	if not camera:
		print("❌ No hay camara disponible")
		return false
	
	return true

func _switch_to_render_mode(model: Node3D, angle: float) -> void:
	"""Cambiar a modo de renderizado (heredado con mejoras)"""
	print("🔄 Cambiando a modo renderizado con delay system...")
	
	current_model = model
	
	# Backup del modelo del preview si existe
	if model_container and model_container.get_child_count() > 0:
		render_backup_model = model_container.get_child(0)
		model_container.remove_child(render_backup_model)
		print("💾 Backup del modelo del preview realizado")
	
	# Añadir modelo para renderizado
	if model_container:
		model_container.add_child(model)
	
	# Configurar rotacion
	if camera_controller and camera_controller.has_method("set_rotation_angle"):
		camera_controller.set_rotation_angle(angle)
	
	# Backup configuracion original del viewport
	original_viewport_mode = viewport.render_target_update_mode
	
	print("✅ Modo renderizado configurado")

func _finish_rendering() -> void:
	"""Finalizar renderizado y restaurar estado (heredado)"""
	is_rendering = false
	_restore_preview_mode()
	# EMISION CORREGIDA para Godot 4.4
	animation_complete.emit(current_animation)
	print("✅ Renderizado con delay system completado")

func _restore_preview_mode() -> void:
	"""Restaurar modo preview (heredado)"""
	if render_backup_model and is_instance_valid(render_backup_model):
		_safe_switch_model_in_container(render_backup_model)
		render_backup_model = null
		print("✅ Modelo del preview restaurado")
	
	if original_viewport_mode >= 0:
		viewport.render_target_update_mode = original_viewport_mode
	
	current_model = null
	print("✅ Modo preview restaurado")

func _safe_switch_model_in_container(new_model: Node3D) -> void:
	"""Cambio seguro de modelo en container (heredado)"""
	if not model_container:
		return
	
	# Remover modelo actual si existe
	for child in model_container.get_children():
		model_container.remove_child(child)
	
	# Añadir nuevo modelo
	model_container.add_child(new_model)

func _render_static_frame() -> void:
	"""Renderizar frame estatico (heredado con mejoras)"""
	await get_tree().process_frame
	
	if not viewport:
		push_error("❌ Viewport no disponible para frame estatico")
		_finish_rendering()
		return
	
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await RenderingServer.frame_post_draw
	
	var image: Image = viewport.get_texture().get_image()
	
	if render_settings.get("pixelize", true):
		image = _apply_pixelization(image)
	
	# Aplicar debug overlay para frame estatico
	if debug_frame_numbers_enabled and debug_overlay:
		var frame_data_for_debug: Dictionary = {
			"frame": 0,
			"direction": current_direction,
			"animation": current_animation
		}
		if debug_overlay.has_method("apply_debug_overlay"):
			image = debug_overlay.apply_debug_overlay(image, frame_data_for_debug)
	
	var frame_data: Dictionary = {
		"animation": current_animation,
		"direction": current_direction,
		"frame": 0,
		"angle": _get_current_camera_angle(),
		"image": image,
		"timing_data": {
			"target_time": 0.0,
			"frame_delay": frame_delay,
			"fps_equivalent": 1.0 / frame_delay if frame_delay > 0 else 0
		}
	}
	
	frame_rendered.emit(frame_data)
	_finish_rendering()

func _apply_pixelization(image: Image) -> Image:
	"""Aplicar pixelizacion (heredado)"""
	# Implementacion basica de pixelizacion
	if not render_settings.get("pixelize", false):
		return image
	
	var pixel_scale: int = render_settings.get("pixel_scale", 4)
	var original_size: Vector2i = image.get_size()
	
	# Reducir tamaño
	var reduced_size: Vector2i = Vector2i(
		max(1, original_size.x / pixel_scale),
		max(1, original_size.y / pixel_scale)
	)
	
	image.resize(reduced_size.x, reduced_size.y, Image.INTERPOLATE_NEAREST)
	
	# Volver al tamaño original
	image.resize(original_size.x, original_size.y, Image.INTERPOLATE_NEAREST)
	
	return image

func _get_current_camera_angle() -> float:
	"""Obtener angulo actual de la camara (heredado)"""
	if camera_controller and camera_controller.has_method("get_relative_angle"):
		return camera_controller.get_relative_angle()
	elif camera_controller and camera_controller.has_node("pivot_node"):
		return camera_controller.get_node("pivot_node").rotation_degrees.y
	else:
		return 0.0

# ========================================================================
# API ESPECIFICA DEL SISTEMA DE DELAY
# ========================================================================

func get_current_delay_info() -> Dictionary:
	"""Obtener informacion actual del sistema de delay"""
	return {
		"frame_delay": frame_delay,
		"fps_equivalent": 1.0 / frame_delay if frame_delay > 0 else 0,
		"total_frames": total_frames,
		"current_frame": current_frame,
		"animation_duration": current_animation_duration,
		"debug_enabled": debug_frame_numbers_enabled,
		"auto_recommendation": delay_recommendation_enabled,
		"frame_timings_count": frame_timings.size()
	}

func set_frame_delay(new_delay: float) -> void:
	"""Establecer delay de frame especifico"""
	if new_delay <= 0:
		print("❌ Delay invalido: %.4fs" % new_delay)
		return
	
	frame_delay = new_delay
	print("⏱️ Delay actualizado: %.4fs (%.1f FPS equiv)" % [frame_delay, 1.0/frame_delay])
	
	# Si estamos renderizando, recalcular frames
	if is_rendering and current_animation_duration > 0:
		total_frames = _calculate_total_frames_with_delay(current_animation_duration, frame_delay)
		frame_timings = _generate_frame_timings(current_animation_duration, total_frames)
		print("🔄 Frames recalculados: %d" % total_frames)

func enable_debug_frame_numbers(enabled: bool) -> void:
	"""Habilitar/deshabilitar numeros de frame debug"""
	debug_frame_numbers_enabled = enabled
	
	if debug_overlay and debug_overlay.has_method("set_debug_enabled"):
		debug_overlay.set_debug_enabled(enabled)
	
	print("🛠️ Debug frame numbers: %s" % ("ENABLED" if enabled else "DISABLED"))

func get_delay_statistics() -> Dictionary:
	"""Obtener estadisticas del sistema de delay"""
	return {
		"recommended_delays_received": 1 if delay_recommender else 0,
		"total_frames_rendered": current_frame,
		"average_timing_error": 0.0,  # Se podria implementar con tracking
		"debug_overlays_applied": current_frame if debug_frame_numbers_enabled else 0
	}
