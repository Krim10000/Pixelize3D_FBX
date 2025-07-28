# scripts/viewer/viewer_coordinator.gd
# Coordinador central del sistema de viewer CON PRESERVACIÓN DE METADATOS
# Input: Señales de todos los paneles UI
# Output: Coordinación entre sistemas (fbx_loader, animation_manager, etc.)

extends Control

# Referencias a paneles UI
@onready var file_loader_panel = find_child("FileLoaderPanel")
@onready var settings_panel = find_child("SettingsPanel") 
@onready var actions_panel = find_child("ActionsPanel")
@onready var animation_controls_panel = find_child("AnimationControlsPanel")
@onready var model_preview_panel = find_child("ModelPreviewPanel")
@onready var log_panel = find_child("LogPanel")

# Referencias a sistemas core
@onready var fbx_loader = get_node("/root/FBXLoader")
@onready var animation_manager = get_node("/root/AnimationManager")
@onready var sprite_renderer = get_node("/root/SpriteRenderer")
@onready var camera_controller = get_node("HSplitContainer/RightPanel/ModelPreviewPanel/ViewportContainer/SubViewport/CameraController")
# Datos del sistema
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null

# ✅ NUEVO: Mapeo de archivos para preservar nombres originales
var file_to_animation_mapping: Dictionary = {}
var animation_to_file_mapping: Dictionary = {}

func _ready():
	print("🎮 ViewerCoordinator iniciado con preservación de metadatos")
	_validate_dependencies()
	_connect_ui_signals()
	_connect_system_signals()

# ✅ FUNCIÓN NUEVA: Validar dependencias críticas
func _validate_dependencies():
	"""Validar que todas las dependencias críticas están disponibles"""
	print("Validando dependencias del sistema...")
	
	var dependencies_ok = true
	
	# Verificar FBXLoader
	if not fbx_loader:
		print("CRITICO: FBXLoader no encontrado en /root/FBXLoader")
		dependencies_ok = false
	else:
		print("FBXLoader encontrado")
	
	# Verificar AnimationManager
	if not animation_manager:
		print("CRITICO: AnimationManager no encontrado en /root/AnimationManager")
		dependencies_ok = false
	else:
		print("AnimationManager encontrado")
		
		# Verificar métodos críticos del AnimationManager
		var required_methods = ["combine_base_with_animation", "register_animation_metadata"]
		for method in required_methods:
			if not animation_manager.has_method(method):
				print("CRITICO: AnimationManager falta método: %s" % method)
				dependencies_ok = false
	
	# Verificar scripts de dependencia
	var retargeting_script_path = "res://scripts/core/animation_retargeting_fix.gd"
	var loop_manager_script_path = "res://scripts/core/animation_loop_manager.gd"
	
	if not ResourceLoader.exists(retargeting_script_path):
		print("CRITICO: animation_retargeting_fix.gd no encontrado")
		dependencies_ok = false
	else:
		print("animation_retargeting_fix.gd encontrado")
	
	if not ResourceLoader.exists(loop_manager_script_path):
		print("CRITICO: animation_loop_manager.gd no encontrado")
		dependencies_ok = false
	else:
		print("animation_loop_manager.gd encontrado")
	
	if dependencies_ok:
		print("Todas las dependencias están disponibles")
	else:
		print("FALTAN DEPENDENCIAS CRITICAS - Funcionalidad limitada")
		if log_panel:
			log_panel.add_log("ERROR: Faltan dependencias críticas del sistema")

func _connect_ui_signals():
	print("🔗 Conectando señales de UI...")
	
	# Conexiones básicas de file loader
	if file_loader_panel:
		_safe_connect(file_loader_panel, "file_selected", _on_file_selected)
		_safe_connect(file_loader_panel, "unit_selected", _on_unit_selected)
		_safe_connect(file_loader_panel, "animations_selected", _on_animations_selected)
	
	# Conexiones de settings panel
	if settings_panel:
		_safe_connect(settings_panel, "settings_changed", _on_settings_changed)
	
	# Conexiones de actions panel
	if actions_panel:
		_safe_connect(actions_panel, "preview_requested", _on_preview_requested)
		_safe_connect(actions_panel, "render_requested", _on_render_requested)
	
	# CONEXIONES CRÍTICAS: Animation controls panel
	if animation_controls_panel:
		print("🎭 Conectando señales de animation_controls_panel...")
		
		# Conectar con manejo seguro
		_safe_connect(animation_controls_panel, "animation_selected", _on_animation_selected)
		_safe_connect(animation_controls_panel, "animation_change_requested", _on_animation_change_requested)  # ✅ NUEVA
		_safe_connect(animation_controls_panel, "play_requested", _on_play_requested)
		_safe_connect(animation_controls_panel, "pause_requested", _on_pause_requested)
		_safe_connect(animation_controls_panel, "stop_requested", _on_stop_requested)
		_safe_connect(animation_controls_panel, "timeline_changed", _on_timeline_changed)
		
		print("✅ Señales de animation_controls_panel conectadas")
	else:
		print("❌ animation_controls_panel no encontrado")

func _safe_connect(source: Node, signal_name: String, target_method: Callable):
	"""Conectar señal de forma segura con manejo de errores"""
	if not source:
		print("❌ Fuente nula para señal: %s" % signal_name)
		return false
	
	if not source.has_signal(signal_name):
		print("⚠️ Señal '%s' no existe en %s" % [signal_name, source.name])
		return false
	
	if source.get_signal_connection_list(signal_name).size() > 0:
		# Ya está conectada
		print("ℹ️ Señal '%s' ya está conectada en %s" % [signal_name, source.name])
		return true
	
	var result = source.connect(signal_name, target_method)
	if result == OK:
		print("✅ Conectada: %s.%s" % [source.name, signal_name])
		return true
	else:
		print("❌ Error conectando %s.%s: %d" % [source.name, signal_name, result])
		return false

func _connect_system_signals():
	"""Conectar señales del sistema con debugging"""
	print("🔗 Conectando señales del sistema...")
	
	if fbx_loader:
		_safe_connect(fbx_loader, "model_loaded", _on_model_loaded)
		_safe_connect(fbx_loader, "load_failed", _on_load_failed)
		print("✅ Señales de FBXLoader conectadas")
	
	if sprite_renderer:
		_safe_connect(sprite_renderer, "frame_rendered", _on_frame_rendered)
		print("✅ Señales de SpriteRenderer conectadas")

# === MANEJADORES DE SEÑALES DE ARCHIVOS ===
func _on_file_selected(file_path: String):
	log_panel.add_log("📁 Archivo seleccionado: " + file_path.get_file())
	_load_fbx_file(file_path)

func _on_unit_selected(unit_data: Dictionary):
	log_panel.add_log("📦 Unidad seleccionada: " + unit_data.name)
	# Limpiar datos previos al cambiar de unidad
	_clear_loaded_data()
	file_loader_panel.populate_unit_files(unit_data)

# ✅ FUNCIÓN MEJORADA: Manejar selección de animaciones con mapeo de archivos
func _on_animations_selected(animation_files: Array):
	log_panel.add_log("🎬 Animaciones seleccionadas: " + str(animation_files))
	
	# ✅ CRÍTICO: Crear mapeo de archivos a nombres de animación
	_create_file_to_animation_mapping(animation_files)
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		if file_loader_panel.current_unit_data.has("path"):
			var full_path = file_loader_panel.current_unit_data.path + "/" + anim_file
			var animation_name = anim_file.get_basename()
			
			log_panel.add_log("📥 Cargando animación: " + anim_file)
			print("🔄 Llamando load_animation_fbx: %s -> %s" % [full_path, animation_name])
			
			# ✅ Almacenar mapeo inverso para usar después
			animation_to_file_mapping[animation_name] = anim_file
			
			fbx_loader.load_animation_fbx(full_path, animation_name)

# ✅ FUNCIÓN NUEVA: Crear mapeo de archivos a animaciones
func _create_file_to_animation_mapping(animation_files: Array):
	"""Crear mapeo bidireccional entre archivos y nombres de animación"""
	file_to_animation_mapping.clear()
	animation_to_file_mapping.clear()
	
	print("📋 Creando mapeo de archivos:")
	for anim_file in animation_files:
		var animation_name = anim_file.get_basename()
		file_to_animation_mapping[anim_file] = animation_name
		animation_to_file_mapping[animation_name] = anim_file
		print("  %s -> %s" % [anim_file, animation_name])
	
	print("✅ Mapeo creado: %d archivos" % animation_files.size())

# === MANEJADORES DE SEÑALES DE CONFIGURACIÓN ===
func _on_settings_changed(settings: Dictionary):
	log_panel.add_log("⚙️ Configuración actualizada")
	# Aplicar a cámara si es necesario
	if camera_controller.has_method("apply_settings"):
		camera_controller.apply_settings(settings)

# === MANEJADORES DE SEÑALES DE ACCIONES ===
func _on_preview_requested():
	log_panel.add_log("🎬 Preview solicitado")
	if current_combined_model:
		model_preview_panel.enable_preview_mode()
	else:
		log_panel.add_log("❌ No hay modelo combinado disponible para preview")

func _on_render_requested():
	log_panel.add_log("🎨 Renderizado solicitado")
	# Delegar al sistema existente
	var selected_animations = file_loader_panel.get_selected_animations() if file_loader_panel.has_method("get_selected_animations") else []
	var render_settings = settings_panel.get_settings() if settings_panel.has_method("get_settings") else {}
	
	if selected_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones seleccionadas")
		return
	
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base cargado")
		return
	
	_start_rendering(selected_animations, render_settings)

# === MANEJADORES DE SEÑALES DE CONTROLES DE ANIMACIÓN ===
func _on_animation_selected(animation_name: String):
	print("🎭 COORDINATOR: Animación seleccionada: %s" % animation_name)
	log_panel.add_log("🎭 Animación seleccionada: " + animation_name)
	
	# Opcional: Delegar al model_preview_panel para cambiar animación
	if model_preview_panel and model_preview_panel.has_method("play_animation"):
		print("🔄 Delegando cambio al model_preview_panel")
		model_preview_panel.play_animation(animation_name)

# ✅ NUEVA FUNCIÓN: Manejar solicitud de cambio de animación
func _on_animation_change_requested(animation_name: String):
	print("🔄 COORDINATOR: Cambio de animación solicitado: %s" % animation_name)
	log_panel.add_log("🔄 Re-combinando para: " + animation_name)
	
	# Verificar que tenemos los datos necesarios
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base para re-combinar")
		return
	
	if not loaded_animations.has(animation_name):
		log_panel.add_log("❌ Animación '%s' no está cargada" % animation_name)
		return
	
	# Re-combinar modelo base con la nueva animación
	_recombine_with_animation(animation_name)

func _recombine_with_animation(animation_name: String):
	"""✅ FUNCIÓN MEJORADA: Re-combinar modelo base con animación específica"""
	print("⚡ RE-COMBINANDO CON: %s" % animation_name)
	
	if not animation_manager:
		print("❌ AnimationManager no disponible para re-combinación")
		log_panel.add_log("❌ Error: AnimationManager no disponible")
		_notify_recombination_failed(animation_name, "AnimationManager no disponible")
		return
	
	var animation_data = loaded_animations.get(animation_name, {})
	
	if animation_data.is_empty():
		print("❌ Datos de animación no encontrados: %s" % animation_name)
		log_panel.add_log("❌ Error: Datos de animación no encontrados")
		_notify_recombination_failed(animation_name, "Datos de animación no encontrados")
		return
	
	# Limpiar modelo combinado anterior de forma segura
	_cleanup_previous_combined_model()
	
	print("🔄 Iniciando re-combinación...")
	
	# Crear nuevo modelo combinado
	current_combined_model = animation_manager.combine_base_with_animation(
		loaded_base_data, 
		animation_data
	)
	
	if current_combined_model:
		print("✅ Re-combinación exitosa")
		log_panel.add_log("✅ Modelo re-combinado: " + animation_name)
		
		# Actualizar preview
		if model_preview_panel and model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
		
		# ✅ CRÍTICO: Notificar al panel de controles que la re-combinación está lista
		if animation_controls_panel and animation_controls_panel.has_method("on_model_recombined"):
			animation_controls_panel.on_model_recombined(current_combined_model, animation_name)
		else:
			print("❌ animation_controls_panel.on_model_recombined no disponible")
		
	else:
		print("❌ Error en re-combinación")
		log_panel.add_log("❌ Error re-combinando: " + animation_name)
		_notify_recombination_failed(animation_name, "Error en proceso de combinación")

# ✅ FUNCIÓN NUEVA: Limpiar modelo anterior de forma segura
func _cleanup_previous_combined_model():
	"""Limpiar modelo combinado anterior de forma segura"""
	if current_combined_model and is_instance_valid(current_combined_model):
		print("🧹 Limpiando modelo combinado anterior: %s" % current_combined_model.name)
		
		# Remover del preview si está ahí
		if model_preview_panel and model_preview_panel.has_method("_clear_current_model_safe"):
			model_preview_panel._clear_current_model_safe()
		
		# Liberar el modelo
		current_combined_model.queue_free()
		current_combined_model = null
		
		print("✅ Modelo anterior limpiado")

# ✅ FUNCIÓN NUEVA: Notificar fallo en re-combinación
func _notify_recombination_failed(animation_name: String, error_reason: String):
	"""Notificar al panel de controles que falló la re-combinación"""
	if animation_controls_panel and animation_controls_panel.has_method("_reset_ui_on_error"):
		animation_controls_panel._reset_ui_on_error("Re-combinación falló: " + error_reason)
	else:
		print("❌ No se pudo notificar error al animation_controls_panel")

func _on_play_requested(animation_name: String):
	print("▶️ COORDINATOR: Play solicitado: %s" % animation_name)
	log_panel.add_log("▶️ Reproduciendo: " + animation_name)

func _on_pause_requested():
	print("⏸️ COORDINATOR: Pause solicitado")
	log_panel.add_log("⏸️ Animación pausada")

func _on_stop_requested():
	print("⏹️ COORDINATOR: Stop solicitado")
	log_panel.add_log("⏹️ Animación detenida")

func _on_timeline_changed(position: float):
	# Debug opcional para timeline
	# print("📍 Timeline: %.2fs" % position)
	pass

# === MANEJADORES DE SEÑALES DEL SISTEMA ===
# ✅ FUNCIÓN MEJORADA: Cargar modelo con preservación de metadatos
func _on_model_loaded(model_data: Dictionary):
	print("📦 COORDINATOR: Modelo cargado - %s" % model_data.get("name", "Desconocido"))
	
	var file_type = model_data.get("type", "unknown")
	var model_name = model_data.get("name", "Unnamed")
	
	if file_type == "base":
		print("🏗️ Modelo base detectado: %s" % model_name)
		loaded_base_data = model_data
		log_panel.add_log("✅ Modelo base cargado: " + model_name)
	elif file_type == "animation":
		print("🎭 Animación detectada: %s" % model_name)
		loaded_animations[model_name] = model_data
		log_panel.add_log("✅ Animación cargada: " + model_name)
		
		# ✅ NUEVO: Registrar metadatos en animation_manager
		if animation_manager and model_data.has("file_metadata"):
			animation_manager.register_animation_metadata(model_name, model_data.file_metadata)
			print("📝 Metadatos registrados en animation_manager para: %s" % model_name)
	
	# Intentar combinación automática
	_try_combine_and_preview()

func _on_load_failed(error: String):
	print("❌ COORDINATOR: Error de carga - %s" % error)
	log_panel.add_log("❌ Error de carga: " + error)

func _on_frame_rendered(frame_data: Dictionary):
	# Manejar frames renderizados si es necesario
	pass

# === FUNCIONES DE COMBINACIÓN ===
func _load_fbx_file(file_path: String):
	"""Cargar archivo FBX detectando tipo automáticamente"""
	var file_name = file_path.get_file().get_basename()
	
	# Detectar tipo por nombre
	var is_base = file_name.to_lower().contains("base") or not file_name.to_lower().contains("walk") and not file_name.to_lower().contains("run") and not file_name.to_lower().contains("idle")
	
	if is_base:
		print("🏗️ Cargando como base: %s" % file_path)
		fbx_loader.load_base_model(file_path)
	else:
		print("🎭 Cargando como animación: %s" % file_path)
		fbx_loader.load_animation_fbx(file_path, file_name)

# ✅ FUNCIÓN MEJORADA: Combinación con metadatos completos
func _try_combine_and_preview():
	"""Intentar combinar y configurar preview con metadatos preservados"""
	print("🔄 Intentando combinación con metadatos - Base: %s, Anims: %d" % [not loaded_base_data.is_empty(), loaded_animations.size()])
	
	# Verificar que tenemos los datos necesarios
	if loaded_base_data.is_empty():
		log_panel.add_log("⏳ Esperando modelo base...")
		return
	
	if loaded_animations.is_empty():
		log_panel.add_log("⏳ Esperando animaciones...")
		return
	
	log_panel.add_log("🔄 Combinando modelo base con animaciones...")
	print("🔄 Iniciando combinación con metadatos...")
	
	# Limpiar modelo combinado anterior
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# ✅ MEJORADO: Usar combinación múltiple si hay múltiples animaciones
	if loaded_animations.size() > 1:
		print("🎭 Usando combinación múltiple para %d animaciones" % loaded_animations.size())
		current_combined_model = animation_manager.combine_base_with_multiple_animations(
			loaded_base_data, 
			loaded_animations
		)
	else:
		# Obtener primera animación para la combinación inicial
		var first_anim_name = loaded_animations.keys()[0]
		var first_anim_data = loaded_animations[first_anim_name]
		
		log_panel.add_log("🎭 Combinando con: " + first_anim_name)
		print("🎭 Usando animación: %s" % first_anim_name)
		
		# Usar animation_manager para combinar
		current_combined_model = animation_manager.combine_base_with_animation(
			loaded_base_data, 
			first_anim_data
		)
	
	if current_combined_model:
		log_panel.add_log("✅ Modelo combinado exitosamente")
		print("✅ Combinación exitosa, configurando preview...")
		
		# ✅ DEBUG: Mostrar metadatos del modelo combinado
		animation_manager.debug_combined_model_with_metadata(current_combined_model)
		
		# Configurar preview con modelo combinado
		if model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
			print("✅ Modelo pasado a preview panel")
		
		# CRÍTICO: Poblar controles de animación con modelo combinado
		if animation_controls_panel.has_method("populate_animations"):
			animation_controls_panel.populate_animations(current_combined_model)
			print("✅ Controles de animación poblados")
		else:
			print("❌ animation_controls_panel no tiene populate_animations")
		
		# Habilitar botón de preview en acciones
		if actions_panel and actions_panel.has_method("enable_preview_button"):
			actions_panel.enable_preview_button()
		
		log_panel.add_log("🎬 Preview listo para usar")
		
	else:
		log_panel.add_log("❌ Error al combinar modelo - revisa los logs de animation_manager")
		print("❌ Error en combinación")

# === FUNCIONES DE LIMPIEZA ===
func _clear_loaded_data():
	"""Limpiar datos cargados CON MAPEOS"""
	loaded_base_data.clear()
	loaded_animations.clear()
	
	# ✅ Limpiar mapeos de archivos
	file_to_animation_mapping.clear()
	animation_to_file_mapping.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Resetear controles de animación
	if animation_controls_panel and animation_controls_panel.has_method("reset_controls"):
		animation_controls_panel.reset_controls()
	
	log_panel.add_log("🧹 Datos de modelos y mapeos limpiados")

# === FUNCIONES DE RENDERIZADO ===
func _start_rendering(animations: Array, settings: Dictionary):
	"""Delegar renderizado al sistema principal"""
	log_panel.add_log("🚀 Iniciando renderizado de %d animaciones" % animations.size())
	
	# Esta función debe conectar con tu sistema de renderizado principal (main.gd)
	log_panel.add_log("📝 Datos de renderizado:")
	log_panel.add_log("  • Base: " + loaded_base_data.get("name", "desconocido"))
	log_panel.add_log("  • Animaciones: " + str(animations))
	log_panel.add_log("  • Configuración: " + str(settings.keys()))
	
	# TODO: Aquí conectarías con tu main.gd existente o sprite_renderer
	# Ejemplo: get_tree().call_group("main_system", "start_batch_rendering", loaded_base_data, loaded_animations, settings)

# === FUNCIONES DE DEBUG ===
func get_current_state() -> Dictionary:
	"""Obtener estado actual CON MAPEOS (útil para debugging)"""
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_loaded": loaded_animations.size(),
		"combined_model_ready": current_combined_model != null,
		"animation_names": loaded_animations.keys(),
		"file_mappings": file_to_animation_mapping,
		"animation_mappings": animation_to_file_mapping
	}

func debug_all_connections():
	"""Debug de todas las conexiones de señales"""
	print("\n🔍 === DEBUG CONEXIONES ===")
	
	if animation_controls_panel:
		print("🎭 Animation Controls Panel:")
		var signals = ["animation_selected", "play_requested", "pause_requested", "stop_requested"]
		
		for signal_name in signals:
			if animation_controls_panel.has_signal(signal_name):
				var connections = animation_controls_panel.get_signal_connection_list(signal_name)
				print("  %s: %d conexiones" % [signal_name, connections.size()])
			else:
				print("  %s: ❌ SEÑAL NO EXISTE" % signal_name)
	
	print("🔍 =======================\n")

# ✅ FUNCIÓN NUEVA: Debug de mapeos de archivos
func debug_file_mappings():
	"""Debug de mapeos de archivos"""
	print("\n📋 === DEBUG MAPEOS DE ARCHIVOS ===")
	print("Archivo -> Animación:")
	for file_name in file_to_animation_mapping.keys():
		print("  %s -> %s" % [file_name, file_to_animation_mapping[file_name]])
	
	print("\nAnimación -> Archivo:")
	for anim_name in animation_to_file_mapping.keys():
		print("  %s -> %s" % [anim_name, animation_to_file_mapping[anim_name]])
	print("===================================\n")

func test_animation_controls():
	"""Función de test para animation controls"""
	print("🧪 PROBANDO ANIMATION CONTROLS...")
	
	if animation_controls_panel:
		if animation_controls_panel.has_method("debug_state"):
			animation_controls_panel.debug_state()
		
		if animation_controls_panel.has_method("test_change_animation"):
			animation_controls_panel.test_change_animation()
	else:
		print("❌ animation_controls_panel no disponible")

# ✅ FUNCIÓN NUEVA: Obtener nombre de archivo para una animación
func get_original_filename_for_animation(animation_name: String) -> String:
	"""Obtener el nombre de archivo original para una animación"""
	if animation_to_file_mapping.has(animation_name):
		return animation_to_file_mapping[animation_name]
	return animation_name  # Fallback

# ✅ FUNCIÓN NUEVA: Obtener nombre de animación para un archivo
func get_animation_name_for_file(filename: String) -> String:
	"""Obtener el nombre de animación para un archivo"""
	if file_to_animation_mapping.has(filename):
		return file_to_animation_mapping[filename]
	return filename.get_basename()  # Fallback
