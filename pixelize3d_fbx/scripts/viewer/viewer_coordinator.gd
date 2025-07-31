# scripts/viewer/viewer_coordinator.gd
# VERSIÓN CORREGIDA - Sin funciones duplicadas
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

# Variables para rastrear cambios de animación
var is_changing_animation: bool = false

# Variables para extensiones de renderizado y exportación
var export_manager: Node
var export_dialog: Control
var camera_controls: Node
var rendering_in_progress: bool = false
var current_render_settings: Dictionary = {}

# Variable para rastrear animaciones pendientes de combinación
var pending_animations_for_combination: Array = []

func _ready():
	print("🎮 ViewerCoordinator CORREGIDO iniciado")
	await get_tree().process_frame
	_validate_and_connect()
	_initialize_extensions()
	
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
	_connect_all_signals()

func _connect_all_signals():
	"""Conectar TODAS las señales incluyendo las huérfanas"""
	print("🔗 Conectando TODAS las señales...")
	
	# FileLoaderPanel
	if file_loader_panel:
		file_loader_panel.file_selected.connect(_on_file_selected)
		file_loader_panel.unit_selected.connect(_on_unit_selected)
		file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		print("✅ FileLoaderPanel conectado")
	
	# AnimationControlsPanel - CONECTAR SEÑAL HUÉRFANA
	if animation_controls_panel:
		animation_controls_panel.animation_selected.connect(_on_animation_selected_ui)
		animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		animation_controls_panel.play_requested.connect(_on_play_requested)
		animation_controls_panel.pause_requested.connect(_on_pause_requested)
		animation_controls_panel.stop_requested.connect(_on_stop_requested)
		print("✅ AnimationControlsPanel COMPLETAMENTE conectado")
	
	# ActionsPanel - CONECTAR SEÑALES HUÉRFANAS
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

# === MANEJADORES DE ACCIONES (VERSIONES ÚNICAS) ===

func _on_preview_requested():
	"""Manejar solicitud de preview"""
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
	"""Manejar solicitud de renderizado - VERSIÓN MEJORADA"""
	print("🎨 Renderizado solicitado - VERSIÓN MEJORADA")
	log_panel.add_log("🎨 Iniciando renderizado completo...")
	
	if not current_combined_model:
		log_panel.add_log("❌ No hay modelo para renderizar")
		if actions_panel:
			actions_panel.show_error("No hay modelo cargado")
		return
	
	if rendering_in_progress:
		log_panel.add_log("⚠️ Ya hay un renderizado en progreso")
		return
	
	# Obtener configuración actual
	current_render_settings = _get_current_render_settings()
	
	# Preparar para renderizado
	rendering_in_progress = true
	if actions_panel:
		actions_panel.start_processing("Renderizando sprites...")
	
	# Limpiar frames anteriores
	if export_manager:
		export_manager.clear_frames()
	
	# Configurar sprite renderer
	if sprite_renderer:
		if sprite_renderer.has_method("setup_model"):
			sprite_renderer.setup_model(current_combined_model)
		
		# Iniciar renderizado de la animación actual
		var current_anim = _get_current_animation_name()
		if current_anim:
			_start_animation_rendering(current_anim)
		else:
			log_panel.add_log("❌ No hay animación seleccionada")
			rendering_in_progress = false
	else:
		log_panel.add_log("❌ SpriteRenderer no disponible")
		rendering_in_progress = false

func _on_export_requested():
	"""Manejar solicitud de exportación - VERSIÓN MEJORADA"""
	print("💾 Exportación solicitada - VERSIÓN MEJORADA")
	log_panel.add_log("💾 Abriendo diálogo de exportación...")
	
	if not current_combined_model:
		if actions_panel:
			actions_panel.show_error("No hay modelo cargado")
		return
	
	# Configurar diálogo con datos actuales
	if export_dialog:
		var available_animations = _get_available_animation_names()
		export_dialog.setup_dialog(sprite_renderer, export_manager, available_animations)
		export_dialog.popup_centered()
	else:
		log_panel.add_log("❌ Diálogo de exportación no disponible")

func _on_settings_requested():
	"""Manejar solicitud de configuración"""
	print("⚙️ Configuración solicitada")
	
	# Mostrar/ocultar panel de configuración
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		log_panel.add_log("⚙️ Panel de configuración: " + ("visible" if settings_panel.visible else "oculto"))

# === MANEJADORES DE CONTROLES DE ANIMACIÓN ===

func _on_animation_selected_ui(animation_name: String):
	"""Manejar selección de animación desde UI (información)"""
	print("📍 Animación seleccionada en UI: %s" % animation_name)

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

# === MANEJADORES DE ANIMACIONES ===

func _on_animation_change_requested(animation_name: String):
	"""Manejar cambio con búsqueda más inteligente"""
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
	
	# Búsqueda más inteligente de animaciones
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

func _finish_animation_change(success: bool, animation_name: String):
	"""Finalizar proceso de cambio de animación"""
	is_changing_animation = false
	
	if not success:
		log_panel.add_log("❌ Error al cambiar animación: " + animation_name)
		
		# Notificar error al panel
		if animation_controls_panel and animation_controls_panel.has_method("_reset_ui_on_error"):
			animation_controls_panel._reset_ui_on_error("No se pudo cambiar la animación")

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

	# Limpiar animaciones cargadas para recargar todas
	loaded_animations.clear()
	pending_animations_for_combination = animation_files.duplicate()

	# Cargar TODAS las animaciones
	for i in range(animation_files.size()):
		var anim_file = animation_files[i]
		var full_path = unit_data.path + "/" + anim_file

		print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])

		fbx_loader.load_animation_fbx(full_path)

		if i < animation_files.size() - 1:
			await get_tree().create_timer(0.5).timeout

	# Esperar y luego combinar TODO
	await get_tree().create_timer(1.0).timeout
	
	# Combinar todas las animaciones
	if loaded_base_data and loaded_animations.size() > 0:
		_combine_all_animations()
	
	is_processing_animations = false
	print("🔓 PROCESAMIENTO DESBLOQUEADO")
	
	# Fin de carga
	var last_animation_path = animation_files[-1]
	var last_animation_name = last_animation_path.get_file().get_basename()
	print("✅ Animación aplicada: " + last_animation_name)
	print("=== FIN ANIMATIONS SELECTED ===\n")

func _combine_all_animations():
	"""Combinar TODAS las animaciones en un solo modelo"""
	print("\n🔄 === COMBINANDO TODAS LAS ANIMACIONES ===")
	print("Base disponible: %s" % loaded_base_data.get("name", "Unknown"))
	print("Animaciones disponibles: %d" % loaded_animations.size())
	
	# Usar la primera animación como base para la combinación
	var first_anim_name = loaded_animations.keys()[-1]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinando base con primera animación: %s" % first_anim_name)
	
	# Combinar base + primera animación
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)

	if not combined:
		print("❌ Error en combinación inicial")
		return
	
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

func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar arrays"""
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

# === INICIALIZACIÓN DE EXTENSIONES ===

func _initialize_extensions():
	"""Inicializar extensiones de renderizado y exportación"""
	print("🔧 Inicializando extensiones...")
	
	# Crear ExportManager si no existe
	_setup_export_manager()
	
	# Crear controles de cámara
	_setup_camera_controls()
	
	# Crear diálogo de exportación
#	_setup_export_dialog()
	
	# Conectar señales adicionales
	_connect_extension_signals()
	
	print("✅ Extensiones inicializadas")

func _setup_export_manager():
	"""Configurar Export Manager"""
	export_manager = get_node_or_null("ExportManager")
	
	if not export_manager:
		# Crear ExportManager usando script si existe
		var export_script = load("res://scripts/export/export_manager.gd")
		if export_script:
			export_manager = export_script.new()
			export_manager.name = "ExportManager"
			add_child(export_manager)
			print("✅ ExportManager creado")
		else:
			print("⚠️ Script ExportManager no encontrado")
	else:
		print("✅ ExportManager encontrado")

func _setup_camera_controls():
	"""Configurar controles de cámara"""
	var camera_script = load("res://scripts/viewer/camera_controls.gd")
	if camera_script:
		camera_controls = camera_script.new()
		camera_controls.name = "CameraControls"
		add_child(camera_controls)
		
		# Conectar con sprite_renderer si existe
		if sprite_renderer:
			var camera_controller = sprite_renderer.get_node_or_null("CameraController")
			if camera_controller:
				camera_controls.setup_references(camera_controller, null, self)
		
		print("✅ Controles de cámara configurados")
	else:
		print("⚠️ Script CameraControls no encontrado")

func _setup_export_dialog():
	"""Configurar diálogo de exportación"""
	var dialog_script = load("res://scripts/ui/export_dialog.gd")
	if dialog_script:
		# Crear instancia y verificar el tipo
		var dialog_instance = dialog_script.new()
		if dialog_instance is Control:
			export_dialog = dialog_instance
			export_dialog.name = "ExportDialog"
			add_child(export_dialog)
			print("✅ Diálogo de exportación creado")
		else:
			print("❌ El script ExportDialog no hereda de Control")
			dialog_instance.queue_free()
	else:
		print("⚠️ Script ExportDialog no encontrado")

func _connect_extension_signals():
	"""Conectar señales de las extensiones"""
	
	# ExportManager
	if export_manager:
		if export_manager.has_signal("export_complete"):
			export_manager.export_complete.connect(_on_export_complete)
		if export_manager.has_signal("export_failed"):
			export_manager.export_failed.connect(_on_export_failed)
		if export_manager.has_signal("export_progress"):
			export_manager.export_progress.connect(_on_export_progress)
	
	# ExportDialog
	if export_dialog:
		if export_dialog.has_signal("export_started"):
			export_dialog.export_started.connect(_on_export_dialog_started)
		if export_dialog.has_signal("export_cancelled"):
			export_dialog.export_cancelled.connect(_on_export_dialog_cancelled)
	
	# SpriteRenderer
	if sprite_renderer:
		if sprite_renderer.has_signal("frame_rendered"):
			sprite_renderer.frame_rendered.connect(_on_frame_rendered)
		if sprite_renderer.has_signal("animation_complete"):
			sprite_renderer.animation_complete.connect(_on_animation_render_complete)
		if sprite_renderer.has_signal("rendering_progress"):
			sprite_renderer.rendering_progress.connect(_on_rendering_progress)
	
	# Controles de cámara
	if camera_controls:
		if camera_controls.has_signal("camera_moved"):
			camera_controls.camera_moved.connect(_on_camera_moved)
		if camera_controls.has_signal("model_rotated"):
			camera_controls.model_rotated.connect(_on_model_rotated)
	
	print("🔗 Señales de extensiones conectadas")

# === FUNCIONES DE SOPORTE PARA RENDERIZADO ===

func _get_current_render_settings() -> Dictionary:
	"""Obtener configuración actual de renderizado"""
	var settings = {
		"directions": 16,
		"sprite_size": 256,
		"fps": 12,
		"camera_angle": 45.0,
		"camera_height": 12.0,
		"north_offset": 0.0,
		"pixelize": true
	}
	
	# Obtener de settings_panel si existe
	if settings_panel and settings_panel.has_method("get_current_settings"):
		var panel_settings = settings_panel.get_current_settings()
		for key in panel_settings:
			settings[key] = panel_settings[key]
	
	return settings

func _get_current_animation_name() -> String:
	"""Obtener nombre de la animación actual"""
	if animation_controls_panel and animation_controls_panel.has_method("get_selected_animation"):
		return animation_controls_panel.get_selected_animation()
	
	# Fallback: usar la primera animación disponible
	if current_combined_model:
		var anim_player = _find_animation_player(current_combined_model)
		if anim_player and anim_player.get_animation_list().size() > 0:
			return anim_player.get_animation_list()[0]
	
	return ""

func _get_available_animation_names() -> Array:
	"""Obtener lista de animaciones disponibles"""
	var animations = []
	
	if current_combined_model:
		var anim_player = _find_animation_player(current_combined_model)
		if anim_player:
			animations = anim_player.get_animation_list()
	
	return animations

func _start_animation_rendering(animation_name: String):
	"""Iniciar renderizado de una animación específica"""
	print("🚀 Iniciando renderizado de: %s" % animation_name)
	
	if not sprite_renderer or not sprite_renderer.has_method("render_animation"):
		log_panel.add_log("❌ Función de renderizado no disponible")
		rendering_in_progress = false
		return
	
	# Configurar modelo en sprite renderer##Invalid call. Nonexistent function 'setup_model' in base 'Node3D (sprite_renderer.gd)'.
	sprite_renderer.setup_preview(current_combined_model, current_render_settings)
	
	# Obtener configuración de renderizado
	var directions = current_render_settings.get("directions", 16)
	var total_directions = directions
	
	log_panel.add_log("🎬 Renderizando %d direcciones..." % total_directions)
	
	# Iniciar renderizado para cada dirección
	_render_all_directions(animation_name, total_directions)

func _render_all_directions(animation_name: String, total_directions: int):
	"""Renderizar todas las direcciones de una animación"""
	print("🔄 Renderizando todas las direcciones...")
	
	for direction in range(total_directions):
		var angle = direction * (360.0 / total_directions)
		
		# Aplicar north offset si existe
		var north_offset = current_render_settings.get("north_offset", 0.0)
		angle += north_offset
		
		print("  📐 Dirección %d: %.1f°" % [direction, angle])
		
		# Renderizar esta dirección
		if sprite_renderer.has_method("render_animation"):
			sprite_renderer.render_animation(current_combined_model, animation_name, angle, direction)
		
		# Pequeña pausa entre direcciones
		await get_tree().create_timer(0.1).timeout

# === MANEJADORES DE SEÑALES DE RENDERIZADO ===

func _on_frame_rendered(frame_data: Dictionary):
	"""Manejar frame renderizado"""
	# Añadir frame al export manager
	if export_manager:
		export_manager.add_frame(frame_data)
	
	# Actualizar progreso si es necesario
	print("📸 Frame renderizado: %s dir:%d frame:%d" % [
		frame_data.get("animation", ""),
		frame_data.get("direction", 0),
		frame_data.get("frame", 0)
	])

func _on_animation_render_complete(animation_name: String):
	"""Manejar completación de renderizado de animación"""
	rendering_in_progress = false
	
	print("✅ Renderizado completado: %s" % animation_name)
	log_panel.add_log("✅ Renderizado de '%s' completado" % animation_name)
	
	if actions_panel:
		actions_panel.complete_processing("Renderizado completado")

func _on_rendering_progress(current: int, total: int):
	"""Actualizar progreso de renderizado"""
	if actions_panel:
		# Calcular el porcentaje de progreso (valor entre 0.0 y 1.0)
		var progress_value = float(current) / float(total) if total > 0 else 0.0
		
		# Crear mensaje descriptivo
		var message = "Renderizando: %d/%d" % [current, total]
		
		# Llamar a la función con los parámetros correctos
		actions_panel.update_progress(progress_value, message)
#func update_progress(value: float, message: String = ""):

# === MANEJADORES DE EXPORTACIÓN ===

func _on_export_dialog_started(config: Dictionary):
	"""Manejar inicio de exportación desde diálogo"""
	print("🚀 Exportación iniciada con configuración:")
	print(config)
	
	# Añadir animación actual si es necesario
	if config.get("animation_mode") == "current":
		config["current_animation"] = _get_current_animation_name()
	
	# Iniciar exportación
	if export_manager:
		export_manager.export_sprite_sheets(config)
	else:
		log_panel.add_log("❌ ExportManager no disponible")

func _on_export_dialog_cancelled():
	"""Manejar cancelación de exportación"""
	log_panel.add_log("❌ Exportación cancelada por usuario")

func _on_export_progress(current: int, total: int, message: String):
	"""Actualizar progreso de exportación"""
	if export_dialog:
		export_dialog.update_progress(current, total, message)

func _on_export_complete(output_folder: String):
	"""Manejar completación exitosa de exportación"""
	print("✅ Exportación completada en: %s" % output_folder)
	
	if export_dialog:
		export_dialog.export_completed(true, "Exportación completada exitosamente")
	
	log_panel.add_log("✅ Sprites exportados a: %s" % output_folder)

func _on_export_failed(error: String):
	"""Manejar fallo en exportación"""
	print("❌ Exportación falló: %s" % error)
	
	if export_dialog:
		export_dialog.export_completed(false, error)
	
	log_panel.add_log("❌ Error en exportación: %s" % error)

# === MANEJADORES DE CONTROLES DE CÁMARA ===

func _on_camera_moved(new_position: Vector3):
	"""Manejar movimiento de cámara"""
	# Actualizar preview si es necesario
	pass

func _on_model_rotated(new_rotation: Vector3):
	"""Manejar rotación de modelo"""
	# Actualizar modelo actual
	if current_combined_model:
		current_combined_model.rotation_degrees = new_rotation
	
	# Actualizar controles de cámara con referencia al modelo
	if camera_controls:
		camera_controls.set_model(current_combined_model)

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
		"changing_animation": is_changing_animation,
		"rendering_in_progress": rendering_in_progress,
		"export_manager_available": export_manager != null,
		"camera_controls_available": camera_controls != null,
		"current_render_settings": current_render_settings
	}

func get_system_status() -> Dictionary:
	"""Obtener estado completo del sistema"""
	return get_current_state()

func show_export_dialog():
	"""Mostrar diálogo de exportación manualmente"""
	_on_export_requested()

func start_full_render():
	"""Iniciar renderizado completo manualmente"""
	_on_render_requested()

func force_reset():
	"""Reset completo del coordinator"""
	print("🚨 FORCE RESET COORDINATOR")
	
	# Reset flags
	is_processing_animations = false
	last_animations_processed.clear()
	processing_start_time = 0.0
	is_changing_animation = false
	rendering_in_progress = false
	
	# Clear data
	loaded_base_data.clear()
	loaded_animations.clear()
	current_render_settings.clear()
	pending_animations_for_combination.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Reset del sistema de animaciones del AnimationManager
	if animation_manager and animation_manager.has_method("reset_animation_system"):
		animation_manager.reset_animation_system()
		print("🔄 Sistema de animaciones reseteado")
	
	# Reset panels
	if file_loader_panel and file_loader_panel.has_method("_emergency_reset"):
		file_loader_panel._emergency_reset()
	
	if animation_controls_panel and animation_controls_panel.has_method("reset_controls"):
		animation_controls_panel.reset_controls()
	
	print("✅ COORDINATOR RESET COMPLETO")

func full_system_reset():
	"""Reset completo del sistema - función pública para usar desde consola"""
	print("🔥 === FULL SYSTEM RESET SOLICITADO ===")
	force_reset()
	print("✅ Full system reset completado")
	print("💡 Ahora puedes cargar nuevas animaciones desde cero")

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
	print("  Renderizando: %s" % ("🔄 Sí" if state.rendering_in_progress else "⏸️ No"))
	
	if animation_controls_panel:
		print("\n🎮 ANIMATION CONTROLS:")
		if animation_controls_panel.has_method("debug_state"):
			animation_controls_panel.debug_state()
	
	print("===========================\n")

func debug_extensions():
	"""Debug de las extensiones"""
	print("\n🔧 === DEBUG EXTENSIONES ===")
	print("ExportManager: %s" % ("✅ Disponible" if export_manager else "❌ No disponible"))
	print("ExportDialog: %s" % ("✅ Disponible" if export_dialog else "❌ No disponible"))
	print("CameraControls: %s" % ("✅ Disponible" if camera_controls else "❌ No disponible"))
	print("Renderizando: %s" % ("🔄 Sí" if rendering_in_progress else "⏸️ No"))
	
	if export_manager and export_manager.has_method("get_export_stats"):
		var stats = export_manager.get_export_stats()
		print("📊 Stats de exportación: %s" % str(stats))
	
	print("⚙️ Render settings actuales: %s" % str(current_render_settings))
	print("===============================\n")

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
	if animation_manager.has_method("get_cache_info"):
		var cache_info = animation_manager.get_cache_info()
		print("   Cache info: %s" % str(cache_info))
	
	print("=========================================\n")

func enable_camera_controls():
	"""Habilitar controles de cámara"""
	if camera_controls:
		camera_controls.enable_controls()

func disable_camera_controls():
	"""Deshabilitar controles de cámara"""
	if camera_controls:
		camera_controls.disable_controls()

func apply_game_mode_preset(mode: String):
	"""Aplicar preset de modo de juego"""
	if camera_controls:
		match mode:
			"rts":
				camera_controls.apply_rts_preset()
			"platform":
				camera_controls.apply_platform_preset()
