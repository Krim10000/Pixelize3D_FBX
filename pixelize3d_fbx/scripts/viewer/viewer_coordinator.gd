# scripts/viewer/viewer_coordinator.gd
# VERSIÓN CORREGIDA - Conecta todas las señales huérfanas
# Input: Señales de UI
# Output: Coordinación completa sin señales perdidas

extends Control

# Referencias a paneles UI
@onready var file_loader_panel = find_child("FileLoaderPanel")
@onready var settings_panel = find_child("SettingsPanel") 
@onready var actions_panel = find_child("ActionsPanel")
@onready var animation_controls_panel = find_child("AnimationControlsPanel")
@onready var model_preview_panel = find_child("ModelPreviewPanel")
@onready var log_panel = find_child("LogPanel")

# Referencias a sistemas core
@onready var fbx_loader = get_node("FBXLoader")
@onready var animation_manager = get_node("AnimationManager")
@onready var sprite_renderer = get_node("SpriteRenderer")

# Datos del sistema
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null

# Variables anti-loop
var is_processing_animations: bool = false
var last_animations_processed: Array = []
var processing_start_time: float = 0.0

# ✅ NUEVA: Variable para rastrear cambios de animación
var is_changing_animation: bool = false

func _ready():
	print("🎮 ViewerCoordinator CORREGIDO iniciado")
	await get_tree().process_frame
	_validate_and_connect()
	
	
func _validate_and_connect():
	"""Validar y conectar de forma segura"""
	print("🔍 Validando componentes...")
	
	# Validar componentes críticos
	if not fbx_loader:
		print("❌ FBXLoader no encontrado")
		return
	if not animation_manager:
		print("❌ AnimationManager no encontrado") 
		return
	if not file_loader_panel:
		print("❌ FileLoaderPanel no encontrado")
		return
	if not log_panel:
		print("❌ LogPanel no encontrado")
		return
	
	print("✅ Componentes validados")
	
	# Conectar TODAS las señales
	_connect_all_signals()

func _connect_all_signals():
	"""✅ CORREGIDO: Conectar TODAS las señales incluyendo las huérfanas"""
	print("🔗 Conectando TODAS las señales...")
	
	# FileLoaderPanel
	if file_loader_panel:
		file_loader_panel.file_selected.connect(_on_file_selected)
		file_loader_panel.unit_selected.connect(_on_unit_selected)
		file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		print("✅ FileLoaderPanel conectado")
	
	# ✅ NUEVO: AnimationControlsPanel - CONECTAR SEÑAL HUÉRFANA
	if animation_controls_panel:
		animation_controls_panel.animation_selected.connect(_on_animation_selected_ui)
		animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		animation_controls_panel.play_requested.connect(_on_play_requested)
		animation_controls_panel.pause_requested.connect(_on_pause_requested)
		animation_controls_panel.stop_requested.connect(_on_stop_requested)
		print("✅ AnimationControlsPanel COMPLETAMENTE conectado")
	
	# ✅ NUEVO: ActionsPanel - CONECTAR SEÑALES HUÉRFANAS
	if actions_panel:
		actions_panel.preview_requested.connect(_on_preview_requested)
		actions_panel.render_requested.connect(_on_render_requested)
		actions_panel.export_requested.connect(_on_export_requested)
		actions_panel.settings_requested.connect(_on_settings_requested)
		print("✅ ActionsPanel COMPLETAMENTE conectado")
	
	# FBX Loader
	if fbx_loader:
		fbx_loader.model_loaded.connect(_on_model_loaded)
		fbx_loader.load_failed.connect(_on_load_failed)
		print("✅ FBXLoader conectado")
	
	# Animation Manager
	if animation_manager:
		animation_manager.combination_complete.connect(_on_combination_complete_safe)
		animation_manager.combination_failed.connect(_on_combination_failed)
		print("✅ AnimationManager conectado")
	
	print("🔗 TODAS las conexiones completadas")

# === MANEJADORES DE ANIMACIONES CORREGIDOS ===

#func _on_animation_change_requested(animation_name: String):
	#"""✅ NUEVO: Manejar cambio de animación solicitado desde UI"""
	#print("\n🔄 === CAMBIO DE ANIMACIÓN SOLICITADO ===")
	#print("Animación solicitada: %s" % animation_name)
	#
	## Prevenir cambios simultáneos
	#if is_changing_animation:
		#print("⚠️ Ya hay un cambio en progreso")
		#return
	#
	#is_changing_animation = true
	#log_panel.add_log("🔄 Cambiando a: " + animation_name)
	#
	## Verificar si tenemos el modelo combinado
	#if not current_combined_model:
		#print("❌ No hay modelo combinado")
		#_finish_animation_change(false, animation_name)
		#return
	#
	## Buscar el AnimationPlayer en el modelo actual
	#var anim_player = _find_animation_player(current_combined_model)
	#if not anim_player:
		#print("❌ No se encontró AnimationPlayer")
		#_finish_animation_change(false, animation_name)
		#return
	#
	## Verificar que la animación existe
	#if not anim_player.has_animation(animation_name):
		#print("❌ La animación '%s' no existe" % animation_name)
		#
		## Intentar con el nombre limpio (sin extensión)
		#var clean_name = animation_name.get_basename()
		#if anim_player.has_animation(clean_name):
			#animation_name = clean_name
			#print("✅ Usando nombre limpio: %s" % clean_name)
		#else:
			## Buscar en la lista de animaciones
			#var found = false
			#for anim in anim_player.get_animation_list():
				#if animation_name in anim or anim in animation_name:
					#animation_name = anim
					#found = true
					#print("✅ Animación encontrada como: %s" % anim)
					#break
			#
			#if not found:
				#print("❌ No se pudo encontrar la animación")
				#_finish_animation_change(false, animation_name)
				#return
	#
	## Cambiar la animación directamente
	#print("▶️ Cambiando animación a: %s" % animation_name)
	#
	## Detener animación actual si está reproduciendo
	#if anim_player.is_playing():
		#anim_player.stop()
	#
	## Configurar loop para la nueva animación
	#var anim_lib = anim_player.get_animation_library("")
	#if anim_lib and anim_lib.has_animation(animation_name):
		#var animation = anim_lib.get_animation(animation_name)
		#animation.loop_mode = Animation.LOOP_LINEAR
		#print("🔄 Loop configurado para: %s" % animation_name)
	#
	## Reproducir nueva animación
	#anim_player.play(animation_name)
	#
	## Notificar al panel de controles que el cambio se completó
	#if animation_controls_panel and animation_controls_panel.has_method("on_model_recombined"):
		## Simular que se recombinó el modelo (aunque solo cambiamos la animación)
		#animation_controls_panel.on_model_recombined(current_combined_model, animation_name)
	#
	## Actualizar preview si está activo
	#if model_preview_panel and model_preview_panel.has_method("play_animation"):
		#model_preview_panel.play_animation(animation_name)
	#
	#log_panel.add_log("✅ Animación cambiada: " + animation_name)
	#_finish_animation_change(true, animation_name)
	#
	#print("=== FIN CAMBIO DE ANIMACIÓN ===\n")

func _finish_animation_change(success: bool, animation_name: String):
	"""Finalizar proceso de cambio de animación"""
	is_changing_animation = false
	
	if not success:
		log_panel.add_log("❌ Error al cambiar animación: " + animation_name)
		
		# Notificar error al panel
		if animation_controls_panel and animation_controls_panel.has_method("_reset_ui_on_error"):
			animation_controls_panel._reset_ui_on_error("No se pudo cambiar la animación")

# === MANEJADORES DE ACCIONES ===

func _on_preview_requested():
	"""✅ NUEVO: Manejar solicitud de preview"""
	print("🎬 Preview solicitado")
	log_panel.add_log("🎬 Activando preview...")
	
	if not current_combined_model:
		log_panel.add_log("❌ No hay modelo para preview")
		return
	
	# El preview ya debería estar activo, solo confirmamos
	if model_preview_panel:
		model_preview_panel.set_model(current_combined_model)
		model_preview_panel.show()
		log_panel.add_log("✅ Preview activo")

func _on_render_requested():
	"""✅ NUEVO: Manejar solicitud de renderizado"""
	print("🎨 Renderizado solicitado")
	log_panel.add_log("🎨 Iniciando renderizado...")
	
	if not current_combined_model:
		log_panel.add_log("❌ No hay modelo para renderizar")
		actions_panel.show_error("No hay modelo cargado")
		return
	
	# Delegar al sprite_renderer
	if sprite_renderer and sprite_renderer.has_method("render_current_animation"):
		actions_panel.start_processing("Renderizando sprites...")
		
		# Obtener configuración de settings_panel si existe
		var settings = {}
		if settings_panel and settings_panel.has_method("get_current_settings"):
			settings = settings_panel.get_current_settings()
		
		sprite_renderer.setup_model(current_combined_model)
		sprite_renderer.render_current_animation(settings)
	else:
		log_panel.add_log("❌ SpriteRenderer no disponible")

func _on_export_requested():
	"""✅ NUEVO: Manejar solicitud de exportación"""
	print("💾 Exportación solicitada")
	log_panel.add_log("💾 Preparando exportación...")
	
	# Aquí iría la lógica de exportación
	# Por ahora solo mostramos mensaje
	actions_panel.show_info("Función de exportación en desarrollo")
	log_panel.add_log("ℹ️ Exportación no implementada aún")

func _on_settings_requested():
	"""✅ NUEVO: Manejar solicitud de configuración"""
	print("⚙️ Configuración solicitada")
	
	# Mostrar/ocultar panel de configuración
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		log_panel.add_log("⚙️ Panel de configuración: " + ("visible" if settings_panel.visible else "oculto"))

# === MANEJADORES DE CONTROLES DE ANIMACIÓN ===

func _on_animation_selected_ui(animation_name: String):
	"""Manejar selección de animación desde UI (información)"""
	print("📍 Animación seleccionada en UI: %s" % animation_name)
	# Esta señal es solo informativa, el cambio real viene con animation_change_requested

func _on_play_requested(animation_name: String):
	"""Manejar solicitud de reproducción"""
	print("▶️ Reproducción solicitada: %s" % animation_name)
	
	if model_preview_panel and model_preview_panel.has_method("play_animation"):
		model_preview_panel.play_animation(animation_name)

func _on_pause_requested():
	"""Manejar solicitud de pausa"""
	print("⏸️ Pausa solicitada")
	
	if model_preview_panel and model_preview_panel.has_method("pause_animation"):
		model_preview_panel.pause_animation()

func _on_stop_requested():
	"""Manejar solicitud de detención"""
	print("⏹️ Detención solicitada")
	
	if model_preview_panel and model_preview_panel.has_method("stop_animation"):
		model_preview_panel.stop_animation()

# === FUNCIONES AUXILIARES ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

# === MANEJADORES EXISTENTES (sin cambios) ===

func _on_file_selected(file_path: String):
	"""Manejar selección de archivo"""
	print("📁 Archivo seleccionado: %s" % file_path.get_file())
	log_panel.add_log("📁 Cargando: " + file_path.get_file())
	
	var is_base = "base" in file_path.get_file().to_lower()
	
	if is_base:
		print("🏗️ Cargando como BASE")
		fbx_loader.load_base_model(file_path)
	else:
		print("🎭 Cargando como ANIMACIÓN")
		fbx_loader.load_animation_fbx(file_path)

func _on_unit_selected(unit_data: Dictionary):
	"""Manejar selección de unidad"""
	print("📦 Unidad seleccionada: %s" % unit_data.get("name", "Unknown"))
	log_panel.add_log("📦 Unidad: " + str(unit_data.get("name", "Unknown")))
	
	if file_loader_panel and file_loader_panel.has_method("populate_unit_files"):
		file_loader_panel.populate_unit_files(unit_data)

func _on_animations_selected_protected(animation_files: Array):
	"""Manejar selección de animaciones con protección anti-loops"""
	print("\n🛑 === ANIMATIONS SELECTED PROTECTED ===")
	print("Archivos recibidos: %s" % str(animation_files))

	# Protecciones existentes
	if is_processing_animations:
		var elapsed = Time.get_ticks_msec() / 1000.0 - processing_start_time
		print("🛑 YA PROCESANDO ANIMACIONES (%.1fs transcurrido)" % elapsed)
		if elapsed < 10:
			print("🛑 IGNORANDO - muy pronto")
			return
		else:
			print("⚠️ Timeout alcanzado, continuando...")

	if _arrays_equal(animation_files, last_animations_processed):
		print("🛑 ANIMACIONES IDÉNTICAS - ignorando")
		return

	if animation_files.is_empty():
		print("🛑 ARRAY VACÍO - ignorando")
		return

	if not file_loader_panel or not file_loader_panel.has_method("get_current_unit_data"):
		print("🛑 NO HAY UNIT DATA - ignorando")
		return

	var unit_data = file_loader_panel.get_current_unit_data()
	if unit_data.is_empty() or not unit_data.has("path"):
		print("🛑 UNIT DATA INVÁLIDO - ignorando")
		return

	# Marcar como procesando
	is_processing_animations = true
	processing_start_time = Time.get_ticks_msec() / 1000.0
	last_animations_processed = animation_files.duplicate()

	print("🔒 PROCESANDO ANIMACIONES - BLOQUEADO por 10 segundos")
	log_panel.add_log("🎬 Cargando %d animaciones..." % animation_files.size())

	# Cargar una por una
	for i in range(animation_files.size()):
		var anim_file = animation_files[i]
		var full_path = unit_data.path + "/" + anim_file

		print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])

		fbx_loader.load_animation_fbx(full_path)

		if i < animation_files.size() - 1:
			await get_tree().create_timer(1.0).timeout

	# Fin de carga
	await get_tree().create_timer(2.0).timeout
	is_processing_animations = false
	print("🔓 PROCESAMIENTO DE ANIMACIONES DESBLOQUEADO")

	# Actualizar paneles
	#animation_controls_panel.update_animations_list(animation_files)

	var last_animation_path = animation_files[-1]
	var last_animation_name = last_animation_path.get_file().get_basename()

	#animation_controls_panel.select_animation_by_name(last_animation_name)
	#model_preview_panel.play_animation(last_animation_name)
	if loaded_base_data and loaded_animations.size() > 0:
		print("LLAMANDO A _combine_all_animations ")

		_combine_all_animations()  # <-- ESTA ES LA LÍNEA CRÍTICA
	print("✅ Animación aplicada: " + last_animation_name)
	print("=== FIN ANIMATIONS SELECTED ===\n")

func _on_model_loaded(model_data: Dictionary):
	"""Manejar modelo cargado"""
	print("📦 Modelo cargado: %s (%s)" % [model_data.get("name", "Unknown"), model_data.get("type", "Unknown")])
	
	if model_data.type == "base":
		loaded_base_data = model_data
		log_panel.add_log("✅ Base: " + str(model_data.get("name", "Unknown")))
		
		if actions_panel:
			actions_panel.set_status("Base cargada - selecciona animaciones")
			
		_try_auto_combine()
	else:
		var anim_name = model_data.get("name", "Unknown")
		loaded_animations[anim_name] = model_data
		log_panel.add_log("✅ Animación: " + anim_name)
		
		_try_auto_combine()

func _on_load_failed(error_message: String):
	"""Manejar error de carga"""
	print("❌ Error de carga: %s" % error_message)
	log_panel.add_log("❌ Error: " + error_message)
	
	is_processing_animations = false

func _try_auto_combine():
	"""Intentar combinar automáticamente cuando tengamos base + animación"""
	if loaded_base_data.is_empty() or loaded_animations.is_empty():
		return
	
	if current_combined_model != null:
		return
	
	print("🔄 Auto-combinando modelo...")
	log_panel.add_log("🔄 Combinando modelo...")
	
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	if combined:
		_on_combination_complete_safe(combined)

func _on_combination_complete_safe(combined_model: Node3D):
	"""Manejar combinación exitosa de forma segura"""
	if not combined_model:
		print("❌ Modelo combinado es null")
		return
	
	print("✅ Combinación exitosa: %s" % combined_model.name)
	log_panel.add_log("✅ Modelo combinado listo")
	
	current_combined_model = combined_model
	
	# Actualizar preview
	if model_preview_panel and model_preview_panel.has_method("set_model"):
		model_preview_panel.set_model(current_combined_model)
		print("✅ Preview actualizado")
	
	# Poblar controles
	_safe_populate_animation_controls()
	
	# Habilitar botones de acción
	if actions_panel:
		actions_panel.enable_preview_button()
		actions_panel.enable_render_button()
		actions_panel.set_status("✅ Modelo listo para renderizar")

func _safe_populate_animation_controls():
	"""Poblar controles de animación de forma segura"""
	if not current_combined_model:
		print("❌ No hay modelo combinado para poblar controles")
		return
	
	if not animation_controls_panel:
		print("❌ No hay animation_controls_panel")
		return
	
	if not animation_controls_panel.has_method("populate_animations"):
		print("❌ populate_animations no disponible")
		return
	
	print("🎮 Poblando controles de animación")
	log_panel.add_log("🎮 Controles de animación listos")
	animation_controls_panel.populate_animations(current_combined_model)
	print("✅ Animation controls poblados exitosamente")

func _on_combination_failed(error: String):
	"""Manejar error de combinación"""
	print("❌ Error combinación: %s" % error)
	log_panel.add_log("❌ Error combinación: " + error)

func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar arrays"""
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

# === FUNCIONES PÚBLICAS ===

func combine_and_view():
	"""Combinar y preparar vista manualmente"""
	print("🔄 === COMBINACIÓN MANUAL ===")
	log_panel.add_log("🔄 Combinando y preparando vista...")
	
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base cargado")
		return false
	
	if loaded_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones cargadas")
		return false
	
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinando: base + %s" % first_anim_name)
	log_panel.add_log("🔄 Combinando con: " + first_anim_name)
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	if combined:
		current_combined_model = combined
		print("✅ Combinación exitosa")
		log_panel.add_log("✅ Combinación exitosa")
		
		if model_preview_panel:
			model_preview_panel.set_model(current_combined_model)
		
		_safe_populate_animation_controls()
		
		#if actions_panel:
			#actions_panel.enable_preview_button()
			#actions_panel.enable_render_button()
		
		log_panel.add_log("🎮 ¡Listo! Usa los controles")
		return true
	else:
		log_panel.add_log("❌ Error en combinación")
		return false

func get_current_state() -> Dictionary:
	"""Estado actual del sistema"""
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_count": loaded_animations.size(),
		"combined_ready": current_combined_model != null,
		"processing": is_processing_animations,
		"changing_animation": is_changing_animation
	}

func debug_state():
	"""Debug detallado del estado"""
	print("\n🎮 === COORDINATOR DEBUG ===")
	var state = get_current_state()
	print("📊 ESTADO:")
	print("  Base cargada: %s" % state.base_loaded)
	print("  Animaciones: %d" % state.animations_count)
	print("  Modelo combinado: %s" % state.combined_ready)
	print("  Procesando: %s" % state.processing)
	print("  Cambiando animación: %s" % state.changing_animation)
	
	if animation_controls_panel:
		print("\n🎮 ANIMATION CONTROLS:")
		if animation_controls_panel.has_method("debug_state"):
			animation_controls_panel.debug_state()
	
	print("===========================\n")


# Correcciones para el ViewerCoordinator para manejar múltiples animaciones
# Agrega estas funciones mejoradas a viewer_coordinator.gd:

# Variable adicional para rastrear si necesitamos recombinar
var pending_animations_for_combination: Array = []

#func _on_animations_selected_protected(animation_files: Array):
	#"""Manejar selección de animaciones - MEJORADO para múltiples"""
	#print("\n🛑 === ANIMATIONS SELECTED PROTECTED ===")
	#print("Archivos recibidos: %s" % str(animation_files))
#
	## Protecciones existentes...
	#if is_processing_animations:
		#var elapsed = Time.get_ticks_msec() / 1000.0 - processing_start_time
		#print("🛑 YA PROCESANDO ANIMACIONES (%.1fs transcurrido)" % elapsed)
		#if elapsed < 10:
			#print("🛑 IGNORANDO - muy pronto")
			#return
		#else:
			#print("⚠️ Timeout alcanzado, continuando...")
#
	#if _arrays_equal(animation_files, last_animations_processed):
		#print("🛑 ANIMACIONES IDÉNTICAS - ignorando")
		#return
#
	#if animation_files.is_empty():
		#print("🛑 ARRAY VACÍO - ignorando")
		#return
#
	#var unit_data = file_loader_panel.get_current_unit_data()
	#if unit_data.is_empty() or not unit_data.has("path"):
		#print("🛑 UNIT DATA INVÁLIDO - ignorando")
		#return
#
	## Marcar como procesando
	#is_processing_animations = true
	#processing_start_time = Time.get_ticks_msec() / 1000.0
	#last_animations_processed = animation_files.duplicate()
#
	#print("🔒 PROCESANDO ANIMACIONES - BLOQUEADO")
	#log_panel.add_log("🎬 Cargando %d animaciones..." % animation_files.size())
#
	## ✅ NUEVO: Limpiar animaciones cargadas para recargar todas
	#loaded_animations.clear()
	#pending_animations_for_combination = animation_files.duplicate()
#
	## Cargar TODAS las animaciones
	#for i in range(animation_files.size()):
		#var anim_file = animation_files[i]
		#var full_path = unit_data.path + "/" + anim_file
#
		#print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		#log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])
#
		#fbx_loader.load_animation_fbx(full_path)
#
		#if i < animation_files.size() - 1:
			#await get_tree().create_timer(0.5).timeout
#
	## ✅ NUEVO: Esperar y luego combinar TODO
	#await get_tree().create_timer(1.0).timeout
	#
	## Combinar todas las animaciones
	#if loaded_base_data and loaded_animations.size() > 0:
		#_combine_all_animations()
	#
	#is_processing_animations = false
	#print("🔓 PROCESAMIENTO DESBLOQUEADO")
	#print("=== FIN ANIMATIONS SELECTED ===\n")

func _combine_all_animations():
	"""✅ NUEVA FUNCIÓN: Combinar TODAS las animaciones en un solo modelo"""
	print("\n🔄 === COMBINANDO TODAS LAS ANIMACIONES ===")
	print("Base disponible: %s" % loaded_base_data.get("name", "Unknown"))
	print("Animaciones disponibles: %d" % loaded_animations.size())
	
	# Usar la primera animación como base para la combinación
	var first_anim_name = loaded_animations.keys()[-1]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinando base con primera animación: %s" % first_anim_name)
	
	# Combinar base + primera animación
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	#var combined = animation_manager.combine_base_with_multiple_animations(loaded_base_data, first_anim_data)

	#combine_base_with_multiple_animations
	if not combined:
		print("❌ Error en combinación inicial")
		return
	
	# ✅ CRÍTICO: Agregar las demás animaciones al modelo combinado
	#if loaded_animations.size() > 1:
		#print("📋 Agregando %d animaciones adicionales..." % (loaded_animations.size() - 1))
		#
		#var combined_anim_player = _find_animation_player(combined)
		#if combined_anim_player:
			## Obtener la librería de animaciones
			#var anim_lib = combined_anim_player.get_animation_library("")
			#if not anim_lib:
				#print("❌ No se encontró librería de animaciones")
				#return
			#
			## Agregar cada animación adicional
			#var added_count = 0
			#for anim_name in loaded_animations:
				#if anim_name == first_anim_name:
					#continue  # Skip la primera que ya está
				#
				#var anim_data = loaded_animations[anim_name]
				#if anim_data.has("model"):
					#var anim_model = anim_data["model"]
					#var source_player = _find_animation_player(anim_model)
					#
					#if source_player:
						#var source_anims = source_player.get_animation_list()
						#for source_anim_name in source_anims:
							## Copiar la animación
							#var source_lib = source_player.get_animation_library("")
							#if source_lib and source_lib.has_animation(source_anim_name):
								#var anim_to_copy = source_lib.get_animation(source_anim_name)
								#
								## Usar el nombre limpio de la animación
								#var clean_name = anim_name
								#if source_anim_name != "mixamo_com" and source_anim_name != "":
									#clean_name = source_anim_name
								#
								#print("  + Agregando: %s" % clean_name)
								#
								## Clonar y agregar la animación
								#var anim_copy = anim_to_copy.duplicate()
								#anim_lib.add_animation(clean_name, anim_copy)
								#added_count += 1
				#
			#print("✅ Agregadas %d animaciones adicionales" % added_count)
			#
			## Configurar loops para todas
			#var all_anims = combined_anim_player.get_animation_list()
			#for anim in all_anims:
				#if anim_lib.has_animation(anim):
					#var animation = anim_lib.get_animation(anim)
					#animation.loop_mode = Animation.LOOP_LINEAR
			#
			#print("📋 Total de animaciones en el modelo: %d" % all_anims.size())
			#print("  Animaciones: %s" % str(all_anims))
	#
	# Guardar el modelo combinado
	current_combined_model = combined
	
	# Actualizar UI
	_on_combination_complete_safe(combined)
	
	# Actualizar lista de animaciones en el panel
	if animation_controls_panel:
		# Crear lista de nombres de archivo para el panel
		var file_names = []
		for anim_name in loaded_animations.keys():
			file_names.append(anim_name + ".fbx")
		
		animation_controls_panel.update_animations_list(file_names)
		
		# Seleccionar la primera
		if file_names.size() > 0:
			animation_controls_panel.select_animation_by_name(first_anim_name)
	
	print("=== FIN COMBINACIÓN MÚLTIPLE ===\n")

func _on_animation_change_requested(animation_name: String):
	"""✅ MEJORADO: Manejar cambio con búsqueda más inteligente"""
	print("\n🔄 === CAMBIO DE ANIMACIÓN SOLICITADO ===")
	print("Animación solicitada: %s" % animation_name)
	
	if is_changing_animation:
		print("⚠️ Ya hay un cambio en progreso")
		return
	
	is_changing_animation = true
	log_panel.add_log("🔄 Cambiando a: " + animation_name)
	
	if not current_combined_model:
		print("❌ No hay modelo combinado")
		_finish_animation_change(false, animation_name)
		return
	
	var anim_player = _find_animation_player(current_combined_model)
	if not anim_player:
		print("❌ No se encontró AnimationPlayer")
		_finish_animation_change(false, animation_name)
		return
	
	# ✅ MEJORADO: Búsqueda más inteligente de animaciones
	var found_animation = ""
	var clean_name = animation_name.get_basename()  # Quitar .fbx
	
	print("🔍 Buscando animación: '%s' (limpio: '%s')" % [animation_name, clean_name])
	print("📋 Animaciones disponibles: %s" % str(anim_player.get_animation_list()))
	
	# Buscar coincidencia exacta primero
	if anim_player.has_animation(animation_name):
		found_animation = animation_name
	elif anim_player.has_animation(clean_name):
		found_animation = clean_name
	else:
		# Buscar en loaded_animations para obtener el nombre correcto
		for loaded_name in loaded_animations.keys():
			if loaded_name == clean_name or loaded_name == animation_name:
				# Este es el archivo que queremos, buscar su animación
				if anim_player.has_animation(loaded_name):
					found_animation = loaded_name
					break
				# También probar con el nombre del archivo sin extensión
				var file_base = loaded_name.get_basename()
				if anim_player.has_animation(file_base):
					found_animation = file_base
					break
		
		# Si aún no encontramos, buscar parcialmente
		if found_animation == "":
			for anim in anim_player.get_animation_list():
				if clean_name in anim or anim in clean_name:
					found_animation = anim
					break
	
	if found_animation == "":
		print("❌ No se encontró la animación '%s'" % animation_name)
		print("   Animaciones disponibles: %s" % str(anim_player.get_animation_list()))
		_finish_animation_change(false, animation_name)
		return
	
	print("✅ Animación encontrada: '%s'" % found_animation)
	
	# Cambiar la animación
	if anim_player.is_playing():
		anim_player.stop()
	
	# Configurar loop
	var anim_lib = anim_player.get_animation_library("")
	if anim_lib and anim_lib.has_animation(found_animation):
		var animation = anim_lib.get_animation(found_animation)
		animation.loop_mode = Animation.LOOP_LINEAR
	
	# Reproducir
	anim_player.play(found_animation)
	
	# Notificar al panel
	if animation_controls_panel and animation_controls_panel.has_method("on_model_recombined"):
		animation_controls_panel.on_model_recombined(current_combined_model, found_animation)
	
	# Actualizar preview
	if model_preview_panel and model_preview_panel.has_method("play_animation"):
		model_preview_panel.play_animation(found_animation)
	
	log_panel.add_log("✅ Animación cambiada: " + found_animation)
	_finish_animation_change(true, found_animation)
	
	print("=== FIN CAMBIO DE ANIMACIÓN ===\n")


# Parte crítica de _on_animation_change_requested en viewer_coordinator.gd
# Esta es la búsqueda mejorada que encuentra animaciones con nombres problemáticos:

	# ✅ BÚSQUEDA INTELIGENTE DE ANIMACIONES
  # Quitar .fbx si existe
	
	print("🔍 Buscando animación: '%s' (limpio: '%s')" % [animation_name, clean_name])
	print("📋 Animaciones disponibles: %s" % str(anim_player.get_animation_list()))
	
	# 1. Buscar coincidencia exacta
	if anim_player.has_animation(animation_name):
		found_animation = animation_name
	elif anim_player.has_animation(clean_name):
		found_animation = clean_name
	else:
		# 2. Buscar en loaded_animations para mapear nombres
		for loaded_name in loaded_animations.keys():
			# Ejemplo: "Zombie Death(1)" == "Zombie Death(1).fbx".get_basename()
			if loaded_name == clean_name or loaded_name == animation_name:
				if anim_player.has_animation(loaded_name):
					found_animation = loaded_name
					break
		
		# 3. Si aún no encontramos, buscar parcialmente
		if found_animation == "":
			# Quitar caracteres problemáticos para comparación
			var search_name = clean_name.replace("(", "").replace(")", "").strip_edges()
			
			for anim in anim_player.get_animation_list():
				var anim_clean = anim.replace("(", "").replace(")", "").strip_edges()
				
				# Comparación flexible
				if search_name in anim_clean or anim_clean in search_name:
					found_animation = anim
					print("   ✅ Encontrada por búsqueda parcial: '%s'" % anim)
					break
	
	if found_animation == "":
		print("❌ No se encontró la animación '%s'" % animation_name)
		print("   Disponibles: %s" % str(anim_player.get_animation_list()))
		_finish_animation_change(false, animation_name)
		return
	
	print("✅ Animación encontrada: '%s'" % found_animation)


# scripts/viewer/viewer_coordinator.gd
# INTEGRACIÓN: Agregar esta llamada en la función force_reset() existente

func force_reset():
	"""Reset completo del coordinator"""
	print("🚨 FORCE RESET COORDINATOR")
	
	# Reset flags
	is_processing_animations = false
	last_animations_processed.clear()
	processing_start_time = 0.0
	
	# Clear data
	loaded_base_data.clear()
	loaded_animations.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# ✅ NUEVO: Reset del sistema de animaciones del AnimationManager
	if animation_manager and animation_manager.has_method("reset_animation_system"):
		animation_manager.reset_animation_system()
		print("🔄 Sistema de animaciones reseteado")
	
	# Reset panels
	if file_loader_panel and file_loader_panel.has_method("_emergency_reset"):
		file_loader_panel._emergency_reset()
	
	if animation_controls_panel and animation_controls_panel.has_method("reset_controls"):
		animation_controls_panel.reset_controls()
	
	print("✅ COORDINATOR RESET COMPLETO")

# ✅ FUNCIÓN NUEVA: Reset público fácil de usar desde consola
func full_system_reset():
	"""Reset completo del sistema - función pública para usar desde consola"""
	print("🔥 === FULL SYSTEM RESET SOLICITADO ===")
	force_reset()
	print("✅ Full system reset completado")
	print("💡 Ahora puedes cargar nuevas animaciones desde cero")

# ✅ FUNCIÓN NUEVA: Debug del estado del AnimationManager
func debug_animation_manager():
	"""Debug específico del AnimationManager"""
	print("\n🎭 === ANIMATION MANAGER DEBUG ===")
	if not animation_manager:
		print("❌ AnimationManager no encontrado")
		return
	
	# Verificar si tiene el AnimationPlayer en construcción
	if animation_manager.has_method("get_current_building_animation_player"):
		var building_player = animation_manager.get_current_building_animation_player()
		if building_player:
			print("🔧 AnimationPlayer en construcción: %s" % building_player.name)
			print("   Animaciones: %d" % building_player.get_animation_list().size())
			for anim_name in building_player.get_animation_list():
				print("     - %s" % anim_name)
		else:
			print("✅ No hay AnimationPlayer en construcción")
	
	# Verificar cachés
	print("📦 Estado de cachés:")
	print("   Base meshes cache: %d items" % (animation_manager.base_meshes_cache.size() if animation_manager.has_method("get") else 0))
	print("   Animations metadata cache: %d items" % (animation_manager.animations_metadata_cache.size() if animation_manager.has_method("get") else 0))
	
	print("=========================================\n")
