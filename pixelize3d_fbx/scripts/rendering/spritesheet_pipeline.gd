# pixelize3d_fbx/scripts/rendering/spritesheet_pipeline.gd
# Pipeline centralizado para generación de sprite sheets
# Input: Modelo combinado con animaciones y configuración de renderizado/exportación
# Output: Sprite sheets PNG completos con metadatos JSON

extends Node

# ========================================================================
# SEÑALES DEL PIPELINE
# ========================================================================

# Progreso del pipeline completo
signal pipeline_started(animation_name: String)
signal pipeline_progress(current_step: int, total_steps: int, message: String)
signal pipeline_complete(animation_name: String, output_path: String)
signal pipeline_failed(animation_name: String, error: String)

# Estados específicos de fases
signal rendering_phase_started(animation_name: String)
signal rendering_phase_complete(animation_name: String)
signal export_phase_started(animation_name: String)
signal export_phase_complete(animation_name: String, file_path: String)

# ========================================================================
# VARIABLES DEL PIPELINE
# ========================================================================

# Referencias a componentes
var sprite_renderer: Node
var export_manager: Node
var animation_manager: Node

# Estado del pipeline
var is_pipeline_busy: bool = false
var current_animation: String = ""
var current_config: Dictionary = {}
var pipeline_start_time: float = 0.0

# Configuración
var default_render_settings: Dictionary = {
	"directions": 16,
	"sprite_size": 256,
	"fps": 12,
	"camera_angle": 45.0,
	"camera_height": 12.0,
	"camera_distance": 20.0,
	"north_offset": 0.0,
	"pixelize": true
}

var default_export_settings: Dictionary = {
	"output_folder": "res://output/",
	"generate_metadata": true,
	"animation_mode": "current"
}

# ========================================================================
# INICIALIZACIÓN
# ========================================================================

func _ready():
	print("🏭 SpritesheetPipeline inicializado")

func setup_pipeline(renderer: Node, exporter: Node, manager: Node):
	"""Configurar referencias a componentes del pipeline"""
	sprite_renderer = renderer
	export_manager = exporter
	animation_manager = manager
	
	print("🔧 Pipeline configurado:")
	print("  - SpriteRenderer: %s" % ("✅" if sprite_renderer else "❌"))
	print("  - ExportManager: %s" % ("✅" if export_manager else "❌"))
	print("  - AnimationManager: %s" % ("✅" if animation_manager else "❌"))
	
	# Conectar señales de componentes
	_connect_component_signals()

func _connect_component_signals():
	"""Conectar señales de los componentes"""
	if sprite_renderer:
		if sprite_renderer.has_signal("frame_rendered"):
			sprite_renderer.frame_rendered.connect(_on_frame_rendered)
		if sprite_renderer.has_signal("animation_complete"):
			sprite_renderer.animation_complete.connect(_on_animation_render_complete)
		if sprite_renderer.has_signal("rendering_progress"):
			sprite_renderer.rendering_progress.connect(_on_rendering_progress)
	
	if export_manager:
		if export_manager.has_signal("export_complete"):
			export_manager.export_complete.connect(_on_export_complete)
		if export_manager.has_signal("export_failed"):
			export_manager.export_failed.connect(_on_export_failed)
		if export_manager.has_signal("export_progress"):
			export_manager.export_progress.connect(_on_export_progress)
	
	print("🔗 Señales de componentes conectadas")

# ========================================================================
# API PRINCIPAL DEL PIPELINE
# ========================================================================

func generate_spritesheet(animation_name: String, config: Dictionary = {}) -> bool:
	"""
	API principal: Generar sprite sheet para una animación específica
	"""
	print("\n🚀 === INICIANDO PIPELINE DE SPRITE SHEET ===")
	print("Animación: %s" % animation_name)
	
	if is_pipeline_busy:
		print("❌ Pipeline ocupado, no se puede iniciar")
		emit_signal("pipeline_failed", animation_name, "Pipeline ya está en proceso")
		return false
	
	if not _validate_pipeline_components():
		emit_signal("pipeline_failed", animation_name, "Componentes del pipeline no disponibles")
		return false
	
	# Configurar pipeline
	is_pipeline_busy = true
	current_animation = animation_name
	current_config = _merge_configs(config)
	pipeline_start_time = Time.get_ticks_msec() / 1000.0
	
	print("📋 Configuración consolidada:")
	print("  - Direcciones: %d" % current_config.get("directions", 16))
	print("  - Tamaño sprite: %d" % current_config.get("sprite_size", 256))
	print("  - Carpeta salida: %s" % current_config.get("output_folder", "res://output/"))
	
	emit_signal("pipeline_started", animation_name)
	
	# Iniciar proceso asíncrono
	_start_pipeline_process()
	
	return true

func generate_all_spritesheets(config: Dictionary = {}) -> bool:
	"""
	Generar sprite sheets para todas las animaciones disponibles
	"""
	print("\n🚀 === GENERANDO TODOS LOS SPRITE SHEETS ===")
	
	if is_pipeline_busy:
		print("❌ Pipeline ocupado")
		emit_signal("pipeline_failed", "all", "Pipeline ya está en proceso")
		return false
	
	# Obtener animaciones disponibles
	var available_animations = _get_available_animations()
	if available_animations.is_empty():
		print("❌ No hay animaciones disponibles")
		emit_signal("pipeline_failed", "all", "No hay animaciones disponibles")
		return false
	
	print("📋 Animaciones encontradas: %s" % str(available_animations))
	
	# Procesar cada animación secuencialmente
	_generate_multiple_spritesheets(available_animations, config)
	
	return true

# ========================================================================
# PROCESO INTERNO DEL PIPELINE
# ========================================================================

func _start_pipeline_process():
	"""Iniciar el proceso del pipeline de forma asíncrona"""
	print("⚙️ Iniciando proceso del pipeline...")
	
	# Fase 1: Configurar componentes
	emit_signal("pipeline_progress", 1, 4, "Configurando componentes...")
	
	if not await _configure_components():
		_finish_pipeline(false, "Error en configuración de componentes")
		return
	
	# Fase 2: Renderizado
	emit_signal("pipeline_progress", 2, 4, "Iniciando renderizado...")
	emit_signal("rendering_phase_started", current_animation)
	
	if not await _execute_rendering_phase():
		_finish_pipeline(false, "Error en fase de renderizado")
		return
	
	emit_signal("rendering_phase_complete", current_animation)
	
	# Fase 3: Exportación
	emit_signal("pipeline_progress", 3, 4, "Iniciando exportación...")
	emit_signal("export_phase_started", current_animation)
	
	if not await _execute_export_phase():
		_finish_pipeline(false, "Error en fase de exportación")
		return
	
	# Fase 4: Finalización
	emit_signal("pipeline_progress", 4, 4, "Finalizando...")
	
	var output_path = current_config.get("output_folder", "res://output/")
	emit_signal("export_phase_complete", current_animation, output_path)
	_finish_pipeline(true, "Pipeline completado exitosamente")

func _configure_components() -> bool:
	"""Configurar todos los componentes necesarios"""
	print("🔧 Configurando componentes del pipeline...")
	
	# Configurar sprite renderer
	if sprite_renderer and sprite_renderer.has_method("initialize"):
		var render_settings = _extract_render_settings(current_config)
		sprite_renderer.initialize(render_settings)
		print("  ✅ SpriteRenderer configurado")
	else:
		print("  ❌ Error configurando SpriteRenderer")
		return false
	
	# Limpiar frames anteriores en export manager
	if export_manager and export_manager.has_method("clear_frames"):
		export_manager.clear_frames()
		print("  ✅ ExportManager limpio")
	else:
		print("  ❌ Error limpiando ExportManager")
		return false
	
	# Pequeña pausa para estabilización
	await get_tree().create_timer(0.1).timeout
	return true

func _execute_rendering_phase() -> bool:
	"""Ejecutar la fase de renderizado completa"""
	print("🎬 === FASE DE RENDERIZADO ===")
	
	# Obtener modelo combinado
	var combined_model = _get_combined_model()
	if not combined_model:
		print("❌ No hay modelo combinado válido")
		return false
	
	# Configurar preview en sprite renderer
	if sprite_renderer.has_method("setup_preview"):
		var preview_settings = _extract_render_settings(current_config)
		sprite_renderer.setup_preview(combined_model, preview_settings)
		print("✅ Preview configurado para renderizado")
	
	# Renderizar todas las direcciones secuencialmente
	var success = await _render_all_directions_sequential(combined_model)
	
	if success:
		print("✅ Fase de renderizado completada")
		return true
	else:
		print("❌ Error en fase de renderizado")
		return false

func _execute_export_phase() -> bool:
	"""Ejecutar la fase de exportación"""
	print("📤 === FASE DE EXPORTACIÓN ===")
	
	# Verificar que tenemos frames para exportar
	if not export_manager.has_frames(current_animation):
		print("❌ No hay frames renderizados para exportar")
		return false
	
	# Configurar exportación
	var export_config = _extract_export_settings(current_config)
	export_config["current_animation"] = current_animation
	export_config["animation_mode"] = "current"
	
	print("📋 Configuración de exportación:")
	print("  - Animación: %s" % current_animation)
	print("  - Carpeta: %s" % export_config.get("output_folder", ""))
	print("  - Metadatos: %s" % export_config.get("generate_metadata", true))
	
		# ✅ NUEVO: Debug de límites antes de exportar
	if export_manager.has_method("debug_layout_calculation"):
		var sprite_size = Vector2(current_config.get("sprite_size", 256), current_config.get("sprite_size", 256))
		var directions = current_config.get("directions", 16)
		
		# Estimar frames aproximados (rough estimate)
		var estimated_frames = 30  # Valor por defecto
		if current_config.has("fps") and current_config.has("animation_length"):
			estimated_frames = int(current_config.fps * current_config.animation_length)
		
		print("🔍 Pre-análisis de división automática:")
		export_manager.debug_layout_calculation(sprite_size, directions, estimated_frames)
	
	
	# Crear carpeta de salida si no existe
	var output_folder = export_config.get("output_folder", "res://output/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))
	
	# Ejecutar exportación
	export_manager.export_sprite_sheets(export_config)
	
	# Esperar a que termine la exportación (las señales manejarán el resultado)
	return true

# ========================================================================
# RENDERIZADO SECUENCIAL (MIGRADO DESDE VIEWER_COORDINATOR)
# ========================================================================

func configure_texture_limits(max_size: int = 16384, safety_margin: int = 256):
	"""Configurar límites de textura para división automática"""
	if export_manager and export_manager.has_method("set_texture_limits"):
		export_manager.set_texture_limits(max_size, safety_margin)
		print("🔧 Límites de textura configurados: %dpx (margen: %dpx)" % [max_size, safety_margin])

func enable_auto_split(enabled: bool = true):
	"""Habilitar/deshabilitar división automática"""
	if export_manager and export_manager.has_method("set_auto_split_enabled"):
		export_manager.set_auto_split_enabled(enabled)
		print("🔄 División automática: %s" % ("HABILITADA" if enabled else "DESHABILITADA"))



func get_split_preview(sprite_size: int, directions: int, estimated_frames: int) -> Dictionary:
	"""Obtener preview de cómo se dividiría una animación"""
	if export_manager and export_manager.has_method("debug_layout_calculation"):
		var size_vector = Vector2(sprite_size, sprite_size)
		return export_manager.debug_layout_calculation(size_vector, directions, estimated_frames)
	
	return {"needs_split": false, "error": "Export manager no disponible"}

func _render_all_directions_sequential(combined_model: Node3D) -> bool:
	"""Renderizar todas las direcciones secuencialmente - MIGRADO desde viewer_coordinator"""
	print("🔄 Renderizando direcciones secuencialmente...")
	
	if not combined_model or not is_instance_valid(combined_model):
		print("❌ Modelo combinado no válido")
		return false
	
	var total_directions = current_config.get("directions", 16)
	var successful_directions = 0
	
	print("📐 Total direcciones a renderizar: %d" % total_directions)
	
	for direction in range(total_directions):
		# Verificar que el modelo sigue siendo válido
		if not combined_model or not is_instance_valid(combined_model):
			print("❌ Modelo se invalidó durante renderizado")
			break
		
		var angle = direction * (360.0 / total_directions)
		
		# Aplicar north offset si existe
		var north_offset = current_config.get("north_offset", 0.0)
		angle += north_offset
		
		print("  📐 Renderizando dirección %d/%d: %.1f°" % [direction + 1, total_directions, angle])
		
		# Emitir progreso de la fase de renderizado
		var progress = float(direction) / float(total_directions)
		var message = "Renderizando dirección %d/%d" % [direction + 1, total_directions]
		emit_signal("pipeline_progress", 2, 4, message)  # Phase 2 de 4
		
		# Renderizar esta dirección
		if sprite_renderer.has_method("render_animation"):
			sprite_renderer.render_animation(combined_model, current_animation, angle, direction)
			
			# Esperar a que termine esta dirección específica
			await sprite_renderer.animation_complete
			successful_directions += 1
			
			print("    ✅ Dirección %d completada" % (direction + 1))
		else:
			print("    ❌ Error: método render_animation no disponible")
			break
		
		# Pequeña pausa entre direcciones
		await get_tree().process_frame
	
	# Evaluar resultado
	if successful_directions == total_directions:
		print("✅ Todas las direcciones renderizadas exitosamente (%d/%d)" % [successful_directions, total_directions])
		return true
	else:
		print("⚠️ Solo %d/%d direcciones completadas" % [successful_directions, total_directions])
		return false

# ========================================================================
# PROCESAMIENTO MÚLTIPLE
# ========================================================================

func _generate_multiple_spritesheets(animations: Array, config: Dictionary):
	"""Generar múltiples sprite sheets secuencialmente"""
	print("🔄 Procesando %d animaciones..." % animations.size())
	
	is_pipeline_busy = true
	var successful_animations = 0
	var total_animations = animations.size()
	
	for i in range(animations.size()):
		var anim_name = animations[i]
		print("\n--- Procesando animación %d/%d: %s ---" % [i + 1, total_animations, anim_name])
		
		# Configurar para esta animación
		current_animation = anim_name
		current_config = _merge_configs(config)
		
		# Ejecutar pipeline para esta animación
		emit_signal("pipeline_started", anim_name)
		
		var success = true
		
		# Configurar componentes
		if not await _configure_components():
			success = false
		
		# Renderizar
		if success:
			emit_signal("rendering_phase_started", anim_name)
			var combined_model = _get_combined_model()
			if combined_model:
				success = await _render_all_directions_sequential(combined_model)
			else:
				success = false
			emit_signal("rendering_phase_complete", anim_name)
		
		# Exportar
		if success:
			emit_signal("export_phase_started", anim_name)
			success = await _execute_export_phase()
			if success:
				# Esperar señal de export_complete
				await export_manager.export_complete
		
		if success:
			successful_animations += 1
			var output_path = current_config.get("output_folder", "res://output/")
			emit_signal("export_phase_complete", anim_name, output_path)
			emit_signal("pipeline_complete", anim_name, output_path)
		else:
			emit_signal("pipeline_failed", anim_name, "Error en procesamiento")
		
		# Pausa entre animaciones
		await get_tree().create_timer(0.5).timeout
	
	# Resultado final
	is_pipeline_busy = false
	print("\n✅ Procesamiento múltiple completado: %d/%d animaciones exitosas" % [successful_animations, total_animations])

# ========================================================================
# MANEJADORES DE SEÑALES DE COMPONENTES
# ========================================================================

func _on_frame_rendered(frame_data: Dictionary):
	"""Manejar frame renderizado desde sprite_renderer"""
	# Reenviar frame al export_manager
	if export_manager and export_manager.has_method("add_frame"):
		export_manager.add_frame(frame_data)

func _on_animation_render_complete(animation_name: String):
	"""Manejar completación de renderizado de animación"""
	# Esta señal se usa internamente en _render_all_directions_sequential
	pass

func _on_rendering_progress(current: int, total: int):
	"""Manejar progreso de renderizado"""
	# Convertir progreso de renderizado a progreso de pipeline
	# (fase 2 de 4, con progreso interno)
	var phase_progress = float(current) / float(total) * 0.25  # 25% del total
	var overall_progress = 0.5 + phase_progress  # Fase 2 empieza en 50%
	var message = "Renderizando frame %d/%d" % [current, total]
	
	# Emitir como progreso de fase específica si es necesario
	pass

func _on_export_complete(output_path: String):
	"""Manejar completación exitosa de exportación"""
	print("✅ Exportación completada: %s" % output_path)
	# La lógica de finalización se maneja en _execute_export_phase

func _on_export_failed(error: String):
	"""Manejar fallo en exportación"""
	print("❌ Error en exportación: %s" % error)
	_finish_pipeline(false, "Error en exportación: " + error)

func _on_export_progress(current: int, total: int, message: String):
	"""Manejar progreso de exportación"""
	# Convertir progreso de exportación a progreso de pipeline
	# (fase 3 de 4)
	var phase_progress = float(current) / float(total) * 0.25  # 25% del total
	var overall_progress = 0.75 + phase_progress  # Fase 3 empieza en 75%
	
	emit_signal("pipeline_progress", 3, 4, message)

# ========================================================================
# FUNCIONES AUXILIARES
# ========================================================================

func _validate_pipeline_components() -> bool:
	"""Validar que todos los componentes estén disponibles"""
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

func _merge_configs(user_config: Dictionary) -> Dictionary:
	"""Fusionar configuración del usuario con valores por defecto"""
	var merged_render = default_render_settings.duplicate()
	var merged_export = default_export_settings.duplicate()
	
	# Fusionar configuraciones
	for key in user_config:
		if key in merged_render:
			merged_render[key] = user_config[key]
		elif key in merged_export:
			merged_export[key] = user_config[key]
	
	# Combinar ambas configuraciones
	var final_config = merged_render.duplicate()
	for key in merged_export:
		final_config[key] = merged_export[key]
	
	return final_config

func _extract_render_settings(config: Dictionary) -> Dictionary:
	"""Extraer solo configuraciones de renderizado"""
	var render_keys = ["directions", "sprite_size", "fps", "camera_angle", "camera_height", "camera_distance", "north_offset", "pixelize"]
	var render_settings = {}
	
	for key in render_keys:
		if config.has(key):
			render_settings[key] = config[key]
	
	return render_settings

func _extract_export_settings(config: Dictionary) -> Dictionary:
	"""Extraer solo configuraciones de exportación"""
	var export_keys = ["output_folder", "generate_metadata", "animation_mode"]
	var export_settings = {}
	
	for key in export_keys:
		if config.has(key):
			export_settings[key] = config[key]
	
	return export_settings

func _get_combined_model() -> Node3D:
	"""Obtener modelo combinado desde el coordinator (via get_tree)"""
	# Buscar viewer_coordinator en el árbol
	var coordinator = get_tree().get_first_node_in_group("coordinator")
	if not coordinator:
		# Buscar por nombre común
		coordinator = get_node_or_null("/root/Main/ViewerCoordinator")
		if not coordinator:
			coordinator = get_tree().current_scene.get_node_or_null("ViewerCoordinator")
	
	if coordinator and coordinator.has_method("get_current_combined_model"):
		return coordinator.get_current_combined_model()
	elif coordinator and coordinator.has("current_combined_model"):
		return coordinator.current_combined_model
	
	print("⚠️ No se pudo obtener modelo combinado desde coordinator")
	return null

func _get_available_animations() -> Array:
	"""Obtener lista de animaciones disponibles"""
	var combined_model = _get_combined_model()
	if not combined_model:
		return []
	
	var anim_player = _find_animation_player(combined_model)
	if anim_player:
		return anim_player.get_animation_list()
	
	return []

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if not node or not is_instance_valid(node):
		return null
	
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _finish_pipeline(success: bool, message: String):
	"""Finalizar el pipeline"""
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - pipeline_start_time
	
	print("\n🏁 === PIPELINE FINALIZADO ===")
	print("Resultado: %s" % ("✅ ÉXITO" if success else "❌ FALLO"))
	print("Mensaje: %s" % message)
	print("Tiempo transcurrido: %.2f segundos" % elapsed_time)
	print("Animación: %s" % current_animation)
	print("==============================")
	
	# Limpiar estado
	is_pipeline_busy = false
	var final_animation = current_animation
	var output_path = current_config.get("output_folder", "res://output/")
	
	current_animation = ""
	current_config.clear()
	
	# Emitir señal final
	if success:
		emit_signal("pipeline_complete", final_animation, output_path)
	else:
		emit_signal("pipeline_failed", final_animation, message)

# ========================================================================
# API DE ESTADO Y DEBUG
# ========================================================================

func get_pipeline_status() -> Dictionary:
	"""Obtener estado actual del pipeline CON INFO DE DIVISIÓN AUTOMÁTICA"""
	var base_status = {
		"is_busy": is_pipeline_busy,
		"current_animation": current_animation,
		"current_config": current_config,
		"elapsed_time": (Time.get_ticks_msec() / 1000.0) - pipeline_start_time if is_pipeline_busy else 0.0,
		"components_ready": _validate_pipeline_components()
	}
	
	# ✅ AÑADIR INFORMACIÓN DE DIVISIÓN AUTOMÁTICA
	if export_manager and export_manager.has_method("get_texture_limits_info"):
		base_status["auto_split_info"] = export_manager.get_texture_limits_info()
	
	# ✅ AÑADIR PREVIEW DE DIVISIÓN SI HAY CONFIGURACIÓN ACTUAL
	if not current_config.is_empty() and current_animation != "":
		var sprite_size = current_config.get("sprite_size", 256)
		var directions = current_config.get("directions", 16)
		var estimated_frames = 30  # Estimación por defecto
		
		if current_config.has("fps") and current_config.has("animation_length"):
			estimated_frames = int(current_config.fps * current_config.animation_length)
		
		base_status["division_preview"] = get_split_preview(sprite_size, directions, estimated_frames)
	
	return base_status

func debug_pipeline_state():
	"""Debug del estado del pipeline"""
	print("\n🏭 === PIPELINE DEBUG ===")
	var status = get_pipeline_status()
	
	print("Estado: %s" % ("🔄 OCUPADO" if status.is_busy else "⏸️ LIBRE"))
	print("Animación actual: %s" % status.current_animation)
	print("Componentes listos: %s" % ("✅" if status.components_ready else "❌"))
	
	if status.is_busy:
		print("Tiempo transcurrido: %.2f segundos" % status.elapsed_time)
		print("Configuración actual:")
		for key in status.current_config:
			print("  %s: %s" % [key, status.current_config[key]])
	
	print("========================\n")

func force_reset_pipeline():
	"""Reset forzado del pipeline en caso de emergencia"""
	print("🚨 RESET FORZADO DEL PIPELINE")
	
	is_pipeline_busy = false
	current_animation = ""
	current_config.clear()
	pipeline_start_time = 0.0
	
	print("✅ Pipeline reseteado completamente")

# ========================================================================
# FUNCIONES PÚBLICAS PARA USO EXTERNO
# ========================================================================

func get_current_combined_model() -> Node3D:
	"""Función pública para obtener modelo combinado"""
	return _get_combined_model()

func is_busy() -> bool:
	"""Verificar si el pipeline está ocupado"""
	return is_pipeline_busy

func get_default_config() -> Dictionary:
	"""Obtener configuración por defecto"""
	return _merge_configs({})
