# scripts/rendering/simplified_delay_renderer.gd
# Renderer ÚNICO Y SIMPLIFICADO con sistema de delay que funciona correctamente
# Input: Modelo 3D + configuración de delay
# Output: Frames capturados con delay preciso SIN BLOQUEOS

extends Node
class_name SimplifiedDelayRenderer

# Señales simplificadas
signal frame_rendered(frame_index: int, total_frames: int, timing_info: Dictionary)
signal animation_complete(animation_name: String, total_frames: int)
signal rendering_started(animation_name: String, settings: Dictionary)
signal rendering_failed(animation_name: String, error: String)

# Configuración base - SIMPLIFICADA
var frame_delay: float = 0.02  # 50 FPS equivalente por defecto
var stabilization_delay: float = 2.0  # 2 segundos post-carga
var current_animation_duration: float = 0.0
var current_model: Node3D = null
var current_animation_player: AnimationPlayer = null

# Estado del renderizado
var is_rendering: bool = false
var current_animation: String = ""
var current_frame: int = 0
var total_frames: int = 0
var frame_timings: Array[float] = []
var render_settings: Dictionary = {}

# Referencias necesarias
var rendering_viewport: SubViewport = null
var camera_controller: Node = null

func _ready():
	print("🎨 SimplifiedDelayRenderer inicializado")
	print("  Delay por defecto: %.3fs (%.1f FPS equiv)" % [frame_delay, 1.0/frame_delay])
	print("  Stabilization delay: %.1fs" % stabilization_delay)

# ========================================================================
# API PRINCIPAL SIMPLIFICADA
# ========================================================================

func setup_renderer(viewport: SubViewport, camera_ctrl: Node = null) -> bool:
	"""Configurar renderer con viewport y cámara"""
	if not viewport:
		push_error("❌ Viewport requerido")
		return false
	
	rendering_viewport = viewport
	camera_controller = camera_ctrl
	
	print("✅ Renderer configurado: viewport %dx%d" % [viewport.size.x, viewport.size.y])
	return true

func update_render_settings(new_settings: Dictionary) -> void:
	"""Actualizar configuración de renderizado"""
	render_settings = new_settings.duplicate()
	
	# ✅ CRÍTICO: Actualizar delay SIEMPRE que cambie la configuración
	if render_settings.has("frame_delay"):
		set_frame_delay(render_settings.frame_delay)
	
	# Actualizar otros parámetros
	if render_settings.has("stabilization_delay"):
		stabilization_delay = render_settings.stabilization_delay
	
	#print("⚙️ Configuración actualizada - delay: %.3fs, estabilización: %.1fs" % [frame_delay, stabilization_delay])

func render_animation(model: Node3D, animation_name: String, angle: float, direction_index: int) -> void:
	"""Renderizar animación con delay específico SIN BLOQUEOS"""
	
	# Validaciones básicas
	if is_rendering:
		print("⚠️ Ya hay un renderizado en proceso, saltando")
		animation_complete.emit(animation_name)
		return
	
	if not rendering_viewport:
		print("❌ Viewport no configurado")
		rendering_failed.emit(animation_name, "Viewport no configurado")
		return
	
	if not model or not is_instance_valid(model):
		print("❌ Modelo no válido")
		rendering_failed.emit(animation_name, "Modelo no válido")
		return
	
	#print("\n🎬 === INICIANDO RENDERIZADO ===")
	#print("Animación: %s" % animation_name)
	#print("Dirección: %d (%.1f°)" % [direction_index, angle])
	#print("Delay configurado: %.3fs (%.1f FPS equiv)" % [frame_delay, 1.0/frame_delay])
	
	# Configurar estado
	is_rendering = true
	current_animation = animation_name
	current_frame = 0
	current_model = model
	
	# ✅ CRÍTICO: Configurar viewport y cámara
	await _setup_viewport_and_camera(model, angle)
	
	# ✅ CRÍTICO: DELAY DE ESTABILIZACIÓN (2 segundos)
	#print("⏳ Esperando estabilización del modelo...")
	await get_tree().create_timer(stabilization_delay).timeout
	#print("✅ Modelo estabilizado")
	
	# Buscar AnimationPlayer
	current_animation_player = _find_animation_player(model)
	if not current_animation_player:
		print("⚠️ No se encontró AnimationPlayer, renderizando frame estático")
		await _render_single_static_frame()
		_finish_rendering()
		return
	
	# Verificar que la animación existe
	if not current_animation_player.has_animation(animation_name):
		print("❌ Animación '%s' no encontrada" % animation_name)
		rendering_failed.emit(animation_name, "Animación no encontrada")
		_finish_rendering()
		return
	
	# Obtener duración de la animación
	var animation = current_animation_player.get_animation(animation_name)
	current_animation_duration = animation.length
	
	# ✅ CRÍTICO: RECALCULAR FRAMES USANDO EL DELAY ACTUAL
	_recalculate_frames_for_current_animation()
	
	# Emitir inicio
	rendering_started.emit(animation_name, {
		"delay": frame_delay,
		"fps_equivalent": 1.0/frame_delay,
		"total_frames": total_frames,
		"duration": current_animation_duration
	})
	
	print("📊 Configuración final:")
	print("  Duración: %.3fs" % current_animation_duration)
	print("  Frame delay: %.3fs" % frame_delay)
	print("  Total frames: %d" % total_frames)
	print("  FPS equivalente: %.1f" % (1.0/frame_delay))
	
	# Iniciar renderizado de frames
	await _render_animation_frames()

# ========================================================================
# FUNCIONES INTERNAS SIMPLIFICADAS
# ========================================================================

func _recalculate_frames_for_current_animation() -> void:
	"""RECALCULAR frames usando el delay actual y la duración actual"""
	if current_animation_duration <= 0:
		total_frames = 1
		frame_timings = [0.0]
		print("⚠️ Sin duración de animación, usando 1 frame")
		return
	
	# Calcular total de frames con el delay actual
	total_frames = max(1, int(current_animation_duration / frame_delay))
	
	# Generar timings
	frame_timings.clear()
	for i in range(total_frames):
		var timing = i * frame_delay
		if timing > current_animation_duration:
			timing = current_animation_duration
		frame_timings.append(timing)
	
	print("🔢 FRAMES RECALCULADOS:")
	print("  Duración: %.3fs ÷ Delay: %.3fs = %d frames" % [current_animation_duration, frame_delay, total_frames])
	print("  Timings: [%.3f, %.3f, ..., %.3f]" % [
		frame_timings[0] if frame_timings.size() > 0 else 0.0,
		frame_timings[1] if frame_timings.size() > 1 else 0.0,
		frame_timings[-1] if frame_timings.size() > 0 else 0.0
	])

func _setup_viewport_and_camera(model: Node3D, angle: float) -> void:
	"""Configurar viewport y cámara para renderizado"""
	if not rendering_viewport:
		return
	
	# Configurar viewport
	rendering_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	# Configurar cámara si existe
	if camera_controller and camera_controller.has_method("setup_for_direction"):
		camera_controller.setup_for_direction(angle)
		await get_tree().process_frame
	
	# Asegurar que el modelo está en el viewport
	if model.get_parent() != rendering_viewport:
		if model.get_parent():
			model.get_parent().remove_child(model)
		rendering_viewport.add_child(model)
	
	await get_tree().process_frame
	print("🖼️ Viewport y cámara configurados para ángulo %.1f°" % angle)

func _render_animation_frames() -> void:
	"""Renderizar todos los frames de la animación"""
	if not current_animation_player:
		return
	
	print("🎬 Iniciando renderizado de %d frames..." % total_frames)
	
	for frame_idx in range(total_frames):
		current_frame = frame_idx
		var frame_time = frame_timings[frame_idx]
		
		print("  Frame %d/%d: tiempo %.3fs" % [frame_idx + 1, total_frames, frame_time])
		
		# Posicionar animación en el tiempo exacto
		current_animation_player.play(current_animation)
		current_animation_player.seek(frame_time)
		
		# Esperar estabilización del frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Capturar frame
		await _capture_current_frame(frame_idx)
		
		# Emitir progreso
		frame_rendered.emit(frame_idx, total_frames, {
			"timing": frame_time,
			"delay": frame_delay,
			"fps_equivalent": 1.0/frame_delay
		})
		
		# Pequeña pausa entre frames para evitar bloqueos
		await get_tree().process_frame
	
	_finish_rendering()

func _capture_current_frame(frame_index: int) -> void:
	"""Capturar frame actual del viewport"""
	if not rendering_viewport:
		return
	
	# Forzar renderizado
	rendering_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	# Aquí se podría guardar la imagen si fuera necesario
	# var texture = rendering_viewport.get_texture()
	# var image = texture.get_image()
	# ... guardar imagen ...
	
	print("    ✅ Frame %d capturado" % (frame_index + 1))

func _render_single_static_frame() -> void:
	"""Renderizar un solo frame estático"""
	total_frames = 1
	frame_timings = [0.0]
	current_frame = 0
	
	await _capture_current_frame(0)
	frame_rendered.emit(0, 1, {"timing": 0.0, "delay": frame_delay})

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer en el modelo"""
	if not node or not is_instance_valid(node):
		return null
	
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _finish_rendering() -> void:
	"""Finalizar proceso de renderizado"""
	is_rendering = false
	var completed_animation = current_animation
	var completed_frames = total_frames
	
	# Limpiar estado
	current_animation = ""
	current_frame = 0
	current_model = null
	current_animation_player = null
	current_animation_duration = 0.0
	
	print("✅ Renderizado completado: %s (%d frames)" % [completed_animation, completed_frames])
	animation_complete.emit(completed_animation, completed_frames)

# ========================================================================
# API PÚBLICA PARA CONFIGURACIÓN
# ========================================================================

func set_frame_delay(new_delay: float) -> void:
	"""Establecer delay de frame (SIEMPRE recalcula frames si hay animación activa)"""
	if new_delay <= 0:
		print("❌ Delay inválido: %.4fs, usando por defecto" % new_delay)
		new_delay = 0.02
	
	var old_delay = frame_delay
	frame_delay = new_delay
	
	print("⏱️ Delay actualizado: %.4fs → %.4fs (%.1f FPS equiv)" % [old_delay, frame_delay, 1.0/frame_delay])
	
	# ✅ CRÍTICO: SIEMPRE recalcular si tenemos una duración de animación
	if current_animation_duration > 0:
		_recalculate_frames_for_current_animation()
		print("🔄 Frames recalculados automáticamente por cambio de delay")

func set_stabilization_delay(new_delay: float) -> void:
	"""Establecer delay de estabilización post-carga"""
	stabilization_delay = max(0.1, new_delay)
	print("⏳ Stabilization delay: %.1fs" % stabilization_delay)

func get_current_status() -> Dictionary:
	"""Obtener estado actual del renderer"""
	return {
		"is_rendering": is_rendering,
		"frame_delay": frame_delay,
		"fps_equivalent": 1.0/frame_delay,
		"stabilization_delay": stabilization_delay,
		"current_animation": current_animation,
		"current_frame": current_frame,
		"total_frames": total_frames,
		"animation_duration": current_animation_duration
	}

func force_stop_rendering() -> void:
	"""Parar renderizado forzadamente"""
	if is_rendering:
		print("🛑 Parando renderizado forzadamente")
		rendering_failed.emit(current_animation, "Renderizado detenido por usuario")
		_finish_rendering()
