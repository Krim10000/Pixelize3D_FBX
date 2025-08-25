# scripts/viewer/viewer_coordinator.gd
# VERSIÓN CORREGIDA - Sin errores de conexión ni declaración
# Input: Señales de UI
# Output: Coordinación limpia entre UI y Pipeline

extends Control

# ========================================================================
# CLASE AUXILIAR
# ========================================================================
class TestResults:
	var frames_captured: int = 0
	var export_success: bool = false
	var export_error: String = ""
	var last_animations_processed: Array = []
	var processing_start_time: float = 0.0
	var camera_controller: Node
	
	func reset():
		frames_captured = 0
		export_success = false
		export_error = ""

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
#@onready var sprite_renderer = get_node("SpriteRenderer")

var sprite_renderer: Node

# ✅ CORREGIDO: Variables principales
var orientation_analyzer: Node = null
var spritesheet_pipeline: Node
var export_manager: Node
var export_dialog: Control
var camera_controls: Node
var animation_monitor: Node
var camera_sync_helper: Node

# Datos del sistema
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null
var current_render_settings: Dictionary = {}

# Variables de control
var is_processing_animations: bool = false
var last_animations_processed: Array = []
var processing_start_time: float = 0.0
var is_changing_animation: bool = false
var pending_animations_for_combination: Array = []

func _ready():
	print("🎮 ViewerCoordinator CORREGIDO iniciado")
	add_to_group("coordinator")
	
		# ✅ 1. CREAR COMPONENTES PRIMERO
	_create_core_components()
		# ✅ 2. ESPERAR UN FRAME PARA QUE SE ESTABILICEN
	await get_tree().process_frame
		# ✅ 3. LUEGO INICIALIZAR EL PIPELINE
	_initialize_spritesheet_pipeline()
		# ✅ CORREGIDO: Orden correcto de inicialización
	_initialize_orientation_analyzer()
	_validate_and_connect()
	_initialize_extensions()
	_initialize_spritesheet_pipeline()
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	call_deferred("_setup_unified_camera_system")

# ✅ NUEVA FUNCIÓN: Inicializar OrientationAnalyzer correctamente
func _initialize_orientation_analyzer():
	"""Inicializar OrientationAnalyzer de forma segura"""
	print("🧠 Inicializando OrientationAnalyzer...")
	
	var analyzer_script = load("res://scripts/orientation/orientation_analyzer.gd")
	if analyzer_script:
		orientation_analyzer = analyzer_script.new()
		orientation_analyzer.name = "OrientationAnalyzer"
		add_child(orientation_analyzer)
		
		if orientation_analyzer.has_method("analyze_model_orientation"):
			print("✅ OrientationAnalyzer inicializado correctamente")
		else:
			print("❌ OrientationAnalyzer no tiene métodos esperados")
			orientation_analyzer = null
	else:
		print("❌ No se pudo cargar script de OrientationAnalyzer")
		orientation_analyzer = null

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
	if not actions_panel:
		print("❌ actions_panel no encontrado")
		return

	print("✅ Componentes validados")
	_connect_all_signals()

# ✅ CORREGIDO: Conexiones sin duplicados
func _connect_all_signals():
	"""Conectar TODAS las señales sin duplicados"""
	print("🔗 Conectando TODAS las señales...")

	# SettingsPanel
	if settings_panel:
		if settings_panel.has_signal("settings_changed"):
			if settings_panel.settings_changed.is_connected(_on_render_settings_changed):
				settings_panel.settings_changed.disconnect(_on_render_settings_changed)
			settings_panel.settings_changed.connect(_on_render_settings_changed)
			print("✅ SettingsPanel settings_changed conectado")
		
		if settings_panel.has_signal("request_auto_north_detection"):
			if settings_panel.request_auto_north_detection.is_connected(_on_auto_north_requested):
				settings_panel.request_auto_north_detection.disconnect(_on_auto_north_requested)
			settings_panel.request_auto_north_detection.connect(_on_auto_north_requested)
			print("✅ SettingsPanel auto_north conectado")
	else:
		print("❌ SettingsPanel no encontrado")

	# OrientationAnalyzer
	if orientation_analyzer and is_instance_valid(orientation_analyzer):
		if orientation_analyzer.has_signal("analysis_complete"):
			if orientation_analyzer.analysis_complete.is_connected(_on_orientation_analysis_complete):
				orientation_analyzer.analysis_complete.disconnect(_on_orientation_analysis_complete)
			orientation_analyzer.analysis_complete.connect(_on_orientation_analysis_complete)
			print("✅ OrientationAnalyzer conectado")
		if orientation_analyzer.has_signal("analysis_failed"):
			orientation_analyzer.analysis_failed.connect(_on_orientation_analysis_failed)
	else:
		print("❌ OrientationAnalyzer no disponible")

	# FileLoaderPanel
	if file_loader_panel:
		file_loader_panel.file_selected.connect(_on_file_selected)
		file_loader_panel.unit_selected.connect(_on_unit_selected)
		file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		print("✅ FileLoaderPanel conectado")

	# AnimationControlsPanel
	if animation_controls_panel:
		animation_controls_panel.animation_selected.connect(_on_animation_selected_ui)
		if animation_controls_panel.has_signal("animation_change_requested"):
			animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		if animation_controls_panel.has_signal("play_requested"):
			animation_controls_panel.play_requested.connect(_on_play_requested)
		if animation_controls_panel.has_signal("pause_requested"):
			animation_controls_panel.pause_requested.connect(_on_pause_requested)
		if animation_controls_panel.has_signal("stop_requested"):
			animation_controls_panel.stop_requested.connect(_on_stop_requested)
		print("✅ AnimationControlsPanel conectado")

	# ActionsPanel
	if actions_panel:
		actions_panel.preview_requested.connect(_on_preview_requested)
		actions_panel.render_requested.connect(_on_render_requested_refactored)
		actions_panel.export_requested.connect(_on_export_requested)
		if actions_panel.has_signal("settings_requested"):
			actions_panel.settings_requested.connect(_on_settings_requested)
		print("✅ ActionsPanel conectado")

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

# ✅ CORREGIDO: Validación antes de usar current_combined_model
func _on_auto_north_requested():
	"""Manejar solicitud de detección automática de norte - CORREGIDO"""
	print("🧭 Solicitando detección automática de norte...")
	
	if not orientation_analyzer or not is_instance_valid(orientation_analyzer):
		print("❌ OrientationAnalyzer no disponible")
		#log_panel.add_log("❌ Analizador de orientación no disponible")
		return
	
	if not current_combined_model or not is_instance_valid(current_combined_model):
		print("⚠️ No hay modelo combinado para analizar")
		#log_panel.add_log("⚠️ No hay modelo cargado para analizar orientación")
		return
	
	if current_combined_model.get_child_count() > 0:
		var current_model = current_combined_model.get_child(0)
		if orientation_analyzer.has_method("analyze_model_orientation"):
			orientation_analyzer.analyze_model_orientation(current_model)
			print("✅ Análisis de orientación iniciado")
		else:
			print("❌ OrientationAnalyzer no tiene método analyze_model_orientation")
	else:
		print("⚠️ Modelo combinado no tiene hijos para analizar")

#func _on_orientation_analysis_complete(result: Dictionary):
	#"""Manejar completación de análisis de orientación"""
	#print("🧭 Análisis completado: Norte sugerido = %.1f°" % result.get("suggested_north", 0.0))
	#
	#var new_settings = {
		#"north_offset": result.get("suggested_north", 0.0),
		#"auto_north_detection": true
	#}
	#
	#if settings_panel and settings_panel.has_method("apply_settings"):
		#settings_panel.apply_settings(new_settings)
		#print("✅ Configuración aplicada al settings panel")
	#
	#if current_combined_model and current_combined_model.get_child_count() > 0:
		#var model = current_combined_model.get_child(0)
		#model.rotation_degrees.y = result.get("suggested_north", 0.0)
		#print("✅ Modelo rotado físicamente")
	#
	#log_panel.add_log("🧭 Orientación automática aplicada: %.1f°" % result.get("suggested_north", 0.0))

func _on_orientation_analysis_complete(result: Dictionary):
	print("🧭 Análisis completado: Norte sugerido = %.1f°" % result.suggested_north)
	
	# ✅ AÑADIR OFFSET DE 270°
	var adjusted_north = result.suggested_north + 270.0
	
	# Normalizar a rango 0-360
	while adjusted_north >= 360.0:
		adjusted_north -= 360.0
	while adjusted_north < 0.0:
		adjusted_north += 360.0
	
	print("🔄 Norte ajustado con offset 270°: %.1f°" % adjusted_north)
	
	# Actualizar configuración con el resultado ajustado
	var new_settings = {
		"north_offset": adjusted_north,  # ✅ USAR VALOR AJUSTADO
		"auto_north_detection": true
	}
	
	if settings_panel and settings_panel.has_method("apply_settings"):
		settings_panel.apply_settings(new_settings)
	
	# Rotar modelo físicamente con valor ajustado
	if current_combined_model and current_combined_model.get_child_count() > 0:
		var model = current_combined_model.get_child(0)
		model.rotation_degrees.y = adjusted_north  # ✅ USAR VALOR AJUSTADO
	
	#if log_panel:
		#log_panel.add_log("🧭 Orientación automática aplicada: %.1f°" % adjusted_north)


func _on_orientation_analysis_failed(error: String):
	"""Manejar fallo en análisis de orientación"""
	print("❌ Análisis de orientación falló: %s" % error)
	#log_panel.add_log("❌ Error en análisis de orientación: " + error)

# ✅ CORREGIDO: Manejador principal de configuración
#func _on_render_settings_changed(settings: Dictionary):
	#"""Manejar cambios en configuración de renderizado - CORREGIDO"""
	#print("📡 Configuración recibida desde SettingsPanel:")
	#print("  directions: %d" % settings.get("directions", 16))
	#print("  camera_height: %.1f" % settings.get("camera_height", 12.0))
	#print("  camera_angle: %.1f°" % settings.get("camera_angle", 45.0))

	#
	## 1. Enviar al Model Preview Panel (para preview en tiempo real)
	#if model_preview_panel:
		#var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
		#if preview_camera and preview_camera.has_method("set_camera_settings"):
			#preview_camera.set_camera_settings(settings)
			#print("✅ Configuración enviada al preview camera")
			#
			#if preview_camera.has_method("update_camera_position"):
				#preview_camera.update_camera_position()
		#else:
			#print("❌ Preview camera controller no encontrado")
	#
	## 2. Enviar al Sprite Renderer (para renderizado)
	#if sprite_renderer:
		#if sprite_renderer.has_method("initialize"):
			#sprite_renderer.initialize(settings)
			#print("✅ Configuración enviada al sprite renderer")
		#
		#if sprite_renderer.has_method("update_render_settings"):
			#sprite_renderer.update_render_settings(settings)
	#
	## 3. Aplicar al pipeline
	#if spritesheet_pipeline and spritesheet_pipeline.has_method("update_pipeline_settings"):
		#spritesheet_pipeline.update_pipeline_settings(settings)
		#print("✅ Configuración enviada al pipeline")
	#
	## 4. Guardar configuración actual
	#current_render_settings = settings
	#
	#log_panel.add_log("⚙️ Configuración actualizada - direcciones: %d, altura: %.1f" % [settings.get("directions", 16), settings.get("camera_height", 12.0)])

# ========================================================================
# FUNCIONES DE DEBUG
# ========================================================================

func debug_connections():
	"""Debug de conexiones de señales"""
	print("\n🔍 === DEBUG CONEXIONES ===")
	
	if settings_panel:
		print("✅ SettingsPanel encontrado")
		if settings_panel.has_signal("settings_changed"):
			var connections = settings_panel.get_signal_connection_list("settings_changed")
			print("  settings_changed conexiones: %d" % connections.size())
			for conn in connections:
				print("    -> %s.%s" % [conn.target.name, conn.method.get_method()])
		else:
			print("❌ settings_changed signal NO existe")
	else:
		print("❌ SettingsPanel NO encontrado")
	
	print("=========================\n")

func debug_complete_system():
	"""Debug completo del sistema"""
	print("\n🔍 === DEBUG SISTEMA COMPLETO ===")
	
	# 1. Debug OrientationAnalyzer
	print("📋 ORIENTATION ANALYZER:")
	if orientation_analyzer and is_instance_valid(orientation_analyzer):
		print("✅ OrientationAnalyzer encontrado")
		print("  Tiene analyze_model_orientation: %s" % orientation_analyzer.has_method("analyze_model_orientation"))
		print("  Tiene analysis_complete signal: %s" % orientation_analyzer.has_signal("analysis_complete"))
	else:
		print("❌ OrientationAnalyzer NO disponible")
	
	# 2. Debug conexiones
	debug_connections()
	
	# 3. Debug modelo actual
	print("\n📋 MODELO ACTUAL:")
	if current_combined_model:
		print("✅ Modelo combinado: %s" % current_combined_model.name)
		print("  Hijos: %d" % current_combined_model.get_child_count())
		if current_combined_model.get_child_count() > 0:
			var first_child = current_combined_model.get_child(0)
			print("  Primer hijo: %s" % first_child.name)
			print("  Rotación actual: %s" % str(first_child.rotation_degrees))
	else:
		print("❌ No hay modelo combinado")
	
	print("=====================================\n")

# ========================================================================
# FUNCIONES DE SOPORTE PRINCIPALES
# ========================================================================

func _get_current_render_settings() -> Dictionary:
	"""Obtener configuración actual de renderizado"""
	if not current_render_settings.is_empty():
		print("📋 Usando configuración actual guardada")
		return current_render_settings.duplicate()
	
	var settings = {
		"directions": 16,
		"sprite_size": 128,
		"fps": 40,
		"frame_delay": 0.025,      # NUEVO
		"fps_equivalent": 40.0,       # NUEVO
		"auto_delay_recommendation": true,  # NUEVO
		"camera_angle": 45.0,
		"camera_height": 12.0,
		"camera_distance": 20.0,
		"north_offset": 0.0,
		"pixelize": true,
		"output_folder": "res://output/"
	}
	
	if settings_panel and settings_panel.has_method("get_current_settings"):
		var panel_settings = settings_panel.get_current_settings()
		for key in panel_settings:
			settings[key] = panel_settings[key]
		print("📋 Configuración obtenida de settings_panel")
	
	return settings

func get_current_combined_model() -> Node3D:
	"""Función pública para que el pipeline obtenga el modelo combinado"""
	return current_combined_model

# ========================================================================
# INICIALIZACIÓN DE SISTEMAS
# ========================================================================

#func _initialize_spritesheet_pipeline():
	#"""Inicializar el pipeline de sprite sheets"""
	#print("🏭 Inicializando SpritesheetPipeline...")
	#var pipeline_script = load("res://scripts/rendering/spritesheet_pipeline.gd")
	#if pipeline_script:
		#spritesheet_pipeline = pipeline_script.new()
		#spritesheet_pipeline.name = "SpritesheetPipeline"
		#add_child(spritesheet_pipeline)
		#print("✅ SpritesheetPipeline inicializado")
	#else:
		#print("❌ No se pudo cargar script de SpritesheetPipeline")

func _initialize_extensions():
	"""Inicializar extensiones básicas"""
	print("🔧 Inicializando extensiones básicas...")
	# Aquí irían las inicializaciones de export_manager, camera_controls, etc.
	print("✅ Extensiones básicas inicializadas")

func _setup_unified_camera_system():
	"""Inicializar sistema de cámara unificada"""
	print("🎥 Configurando sistema de cámara unificada...")
	var helper_script = load("res://scripts/helpers/camera_sync_helper.gd")
	if helper_script:
		camera_sync_helper = helper_script.new()
		camera_sync_helper.name = "CameraSyncHelper" 
		add_child(camera_sync_helper)
		print("✅ Sistema de cámara unificada configurado")
	else:
		print("⚠️ No se pudo cargar CameraSyncHelper")



#func _on_auto_north_requested():
	#if current_combined_model.get_child_count() > 0:
		#var current_model = current_combined_model.get_child(0)
		#orientation_analyzer.analyze_model_orientation(current_model)
	#else:
		#print("⚠️ No hay modelo cargado para analizar")
#
#func _on_orientation_analysis_complete(result: Dictionary):
	#print("🧭 Análisis completado: Norte sugerido = %.1f°" % result.suggested_north)
	#
	## Actualizar configuración con el resultado
	#var new_settings = {
		#"north_offset": result.suggested_north,
		#"auto_north_detection": true
	#}
	#
	#settings_panel.apply_settings(new_settings)
	#
	## Rotar modelo físicamente
	#if current_combined_model.get_child_count() > 0:
		#var model = current_combined_model.get_child(0)
		#model.rotation_degrees.y = result.suggested_north
#
#
#func _connect_all_signals():
	#"""Conectar TODAS las señales incluyendo las huérfanas"""
	#print("🔗 Conectando TODAS las señales...")
#
#
	#if settings_panel:
		## Verificar y desconectar señales existentes antes de reconectar
		#if settings_panel.has_signal("settings_changed"):
			## Desconectar si ya está conectada
			#if settings_panel.settings_changed.is_connected(_on_render_settings_changed):
				#settings_panel.settings_changed.disconnect(_on_render_settings_changed)
			#settings_panel.settings_changed.connect(_on_render_settings_changed)
			#print("✅ SettingsPanel settings_changed conectado")
		#
		#if settings_panel.has_signal("request_auto_north_detection"):
			## Desconectar si ya está conectada
			##if settings_panel.request_auto_north_detection.is_connected(_on_auto_north_requested):
				##settings_panel.request_auto_north_detection.disconnect(_on_auto_north_requested)
			##settings_panel.request_auto_north_detection.connect(_on_auto_north_requested)
			#print("✅ SettingsPanel auto_north conectado")
	#else:
		#print("❌ SettingsPanel no encontrado")
#
#
	## FileLoaderPanel
	#if file_loader_panel:
		#file_loader_panel.file_selected.connect(_on_file_selected)
		#file_loader_panel.unit_selected.connect(_on_unit_selected)
		#file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		#print("✅ FileLoaderPanel conectado")
#
#
	#if orientation_analyzer:
		#if orientation_analyzer.has_signal("analysis_complete"):
			## Desconectar si ya está conectada
			#if orientation_analyzer.analysis_complete.is_connected(_on_orientation_analysis_complete):
				#orientation_analyzer.analysis_complete.disconnect(_on_orientation_analysis_complete)
			#orientation_analyzer.analysis_complete.connect(_on_orientation_analysis_complete)
			#print("✅ OrientationAnalyzer conectado")
#
#func debug_connections():
	#"""Debug de conexiones de señales"""
	#print("\n🔍 === DEBUG CONEXIONES ===")
	#
	#if settings_panel:
		#print("✅ SettingsPanel encontrado")
		#if settings_panel.has_signal("settings_changed"):
			#var connections = settings_panel.get_signal_connection_list("settings_changed")
			#print("  settings_changed conexiones: %d" % connections.size())
			#for conn in connections:
				#print("    -> %s.%s" % [conn.target.name, conn.method.get_method()])
		#else:
			#print("❌ settings_changed signal NO existe")
	#else:
		#print("❌ SettingsPanel NO encontrado")
	#
	#print("=========================\n")
#
	##var ui_controller = get_node_or_null("UIController")
	##if not ui_controller:
		##ui_controller = find_child("UIController", true, false)
	#
	##if ui_controller:
		### Conectar señal de configuración de renderizado
		##if ui_controller.has_signal("render_settings_changed"):
			##ui_controller.render_settings_changed.connect(_on_render_settings_changed)
			##print("✅ UI Controller render_settings_changed conectado")
		##else:
			##print("⚠️ UI Controller no tiene señal render_settings_changed")
	##else:
		##print("⚠️ UI Controller no encontrado")
#
	## AnimationControlsPanel - CONECTAR SEÑAL HUÉRFANA
	#if animation_controls_panel:
		#animation_controls_panel.animation_selected.connect(_on_animation_selected_ui)
		#animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		#animation_controls_panel.play_requested.connect(_on_play_requested)
		#animation_controls_panel.pause_requested.connect(_on_pause_requested)
		#animation_controls_panel.stop_requested.connect(_on_stop_requested)
		#print("✅ AnimationControlsPanel COMPLETAMENTE conectado")
#
	## ActionsPanel - CONECTAR SEÑALES HUÉRFANAS
	#if actions_panel:
		#actions_panel.preview_requested.connect(_on_preview_requested)
		#actions_panel.render_requested.connect(_on_render_requested_refactored)
		#actions_panel.export_requested.connect(_on_export_requested)
		#actions_panel.settings_requested.connect(_on_settings_requested)
		#print("✅ ActionsPanel COMPLETAMENTE conectado")
#
	## FBX Loader
	#if fbx_loader:
		#fbx_loader.model_loaded.connect(_on_model_loaded)
		#fbx_loader.load_failed.connect(_on_load_failed)
		#print("✅ FBXLoader conectado")
#
	## Animation Manager
	#if animation_manager:
		#animation_manager.combination_complete.connect(_on_combination_complete_safe)
		#animation_manager.combination_failed.connect(_on_combination_failed)
		#print("✅ AnimationManager conectado")
#
	#print("🔗 TODAS las conexiones completadas")

# ========================================================================
# ✅ NUEVO: INICIALIZACIÓN DEL PIPELINE
# ========================================================================

#func _connect_pipeline_signals():
	#"""Conectar señales del pipeline"""
	#if not spritesheet_pipeline:
		#return
#
	## Señales de progreso del pipeline
	#spritesheet_pipeline.pipeline_started.connect(_on_pipeline_started)
	#spritesheet_pipeline.pipeline_progress.connect(_on_pipeline_progress)
	#spritesheet_pipeline.pipeline_complete.connect(_on_pipeline_complete)
	#spritesheet_pipeline.pipeline_failed.connect(_on_pipeline_failed)
#
	## Señales de fases específicas
	#spritesheet_pipeline.rendering_phase_started.connect(_on_rendering_phase_started)
	#spritesheet_pipeline.rendering_phase_complete.connect(_on_rendering_phase_complete)
	#spritesheet_pipeline.export_phase_started.connect(_on_export_phase_started)
	#spritesheet_pipeline.export_phase_complete.connect(_on_export_phase_complete)
#
	#print("🔗 Señales del pipeline conectadas")

# ========================================================================
# ✅ REFACTORIZADO: MANEJADORES DE ACCIONES
# ========================================================================

func _on_preview_requested():
	"""Manejar solicitud de preview con sistema unificado"""
	print("🎬 Preview solicitado - sistema unificado")
	#log_panel.add_log("🎬 Activando preview unificado...")

	if not current_combined_model or not is_instance_valid(current_combined_model):
		#log_panel.add_log("❌ No hay modelo válido para preview")
		return

	# Usar ModelPreviewPanel directamente - SpriteRenderer se sincronizará automáticamente
	if model_preview_panel and model_preview_panel.has_method("set_model"):
		model_preview_panel.set_model(current_combined_model)
		#log_panel.add_log("✅ Preview unificado configurado")

	# Verificar sincronización si está disponible
	if camera_sync_helper and camera_sync_helper.has_method("_validate_sync_setup"):
		camera_sync_helper._validate_sync_setup()

func _on_render_requested_refactored():
	"""✅ REFACTORIZADO: Manejar solicitud de renderizado usando pipeline"""
	print("🎨 Renderizado solicitado - USANDO PIPELINE")
	#log_panel.add_log("🎨 Iniciando renderizado con pipeline...")

	# Validar prerrequisitos
	if not current_combined_model or not is_instance_valid(current_combined_model):
		#log_panel.add_log("❌ No hay modelo válido para renderizar")
		if actions_panel:
			actions_panel.show_error("No hay modelo cargado")
		return

	if not spritesheet_pipeline:
		#log_panel.add_log("❌ Pipeline no disponible")
		if actions_panel:
			actions_panel.show_error("Pipeline no inicializado")
		return

	if spritesheet_pipeline.is_busy():
		#log_panel.add_log("⚠️ Pipeline ocupado")
		if actions_panel:
			actions_panel.show_error("Pipeline ocupado, espera a que termine")
		return

	# Obtener animación actual
	var current_anim = _get_current_animation_name()
	if current_anim == "":
		#log_panel.add_log("❌ No hay animación seleccionada")
		if actions_panel:
			actions_panel.show_error("Selecciona una animación")
		return

	# Obtener configuración
	var config = _get_current_render_settings()

	# ✅ USAR PIPELINE: Una sola línea limpia en lugar de 200+ líneas de lógica
	var success = spritesheet_pipeline.generate_spritesheet(current_anim, config)

	if not success:
		#log_panel.add_log("❌ No se pudo iniciar pipeline")
		if actions_panel:
			actions_panel.show_error("Error iniciando pipeline")

func _on_export_requested():
	"""Manejar solicitud de exportación - VERSIÓN CORREGIDA"""
	print("💾 Exportación solicitada - VERSIÓN CORREGIDA")
	#log_panel.add_log("💾 Abriendo diálogo de exportación...")

	if not current_combined_model or not is_instance_valid(current_combined_model):
		if actions_panel:
			actions_panel.show_error("No hay modelo cargado")
		return

	# ✅ CORREGIDO: Verificar métodos antes de llamarlos
	if export_dialog:
		var available_animations = _get_available_animation_names()
		if export_dialog.has_method("setup_dialog"):
			export_dialog.setup_dialog(sprite_renderer, export_manager, available_animations)
		elif export_dialog.has_method("setup_export_data"):
			export_dialog.setup_export_data(available_animations)
		
		export_dialog.popup_centered()
	else:
		pass
		#log_panel.add_log("❌ Diálogo de exportación no disponible")

func _on_settings_requested():
	"""Manejar solicitud de configuración"""
	print("⚙️ Configuración solicitada")

	# Mostrar/ocultar panel de configuración
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		#log_panel.add_log("⚙️ Panel de configuración: " + ("visible" if settings_panel.visible else "oculto"))

# ========================================================================
# ✅ NUEVOS: MANEJADORES DE SEÑALES DEL PIPELINE
# ========================================================================

func _on_pipeline_started(animation_name: String):
	"""Manejar inicio del pipeline"""
	print("🚀 Pipeline iniciado: %s" % animation_name)
	#log_panel.add_log("🚀 Pipeline iniciado: " + animation_name)

	if actions_panel:
		actions_panel.start_processing("Iniciando pipeline...")

func _on_pipeline_progress(current_step: int, total_steps: int, message: String):
	"""Manejar progreso del pipeline"""
	var progress = float(current_step) / float(total_steps)
	#log_panel.add_log("📊 %s (%d/%d)" % [message, current_step, total_steps])

	if actions_panel:
		actions_panel.update_progress(progress, message)

func _on_pipeline_complete(animation_name: String, output_path: String):
	"""Manejar completación exitosa del pipeline"""
	#print("✅ Pipeline completado: %s → %s" % [animation_name, output_path])
	#log_panel.add_log("✅ Sprite sheet generado: " + animation_name)
	#log_panel.add_log("📁 Ubicación: " + output_path)

	if actions_panel:
		actions_panel.finish_processing(true, "Sprite sheet generado exitosamente")

func _on_pipeline_failed(animation_name: String, error: String):
	"""Manejar fallo del pipeline"""
	print("❌ Pipeline falló: %s - %s" % [animation_name, error])
	#log_panel.add_log("❌ Error en pipeline: " + error)

	if actions_panel:
		actions_panel.finish_processing(false, "Error: " + error)

func _on_rendering_phase_started(animation_name: String):
	"""Manejar inicio de fase de renderizado"""
	#log_panel.add_log("🎬 Iniciando renderizado: " + animation_name)

func _on_rendering_phase_complete(animation_name: String):
	"""Manejar completación de fase de renderizado"""
	#log_panel.add_log("✅ Renderizado completado: " + animation_name)

func _on_export_phase_started(animation_name: String):
	"""Manejar inicio de fase de exportación"""
	#log_panel.add_log("📤 Iniciando exportación: " + animation_name)

func _on_export_phase_complete(animation_name: String, file_path: String):
	"""Manejar completación de fase de exportación"""
	#log_panel.add_log("✅ Exportación completada: " + animation_name +" en " + file_path)

# ========================================================================
# MANEJADORES DE CONTROLES DE ANIMACIÓN (SIN CAMBIOS)
# ========================================================================

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

# ========================================================================
# MANEJADORES DE ANIMACIONES (SIN CAMBIOS SIGNIFICATIVOS)
# ========================================================================

func _on_animation_change_requested(animation_name: String):
	"""Manejar cambio con búsqueda más inteligente - VERSIÓN CORREGIDA"""
	print("\n🔄 === CAMBIO DE ANIMACIÓN SOLICITADO ===")
	print("Animación solicitada: %s" % animation_name)

	if is_changing_animation:
		print("⚠️ Ya hay un cambio en progreso")
		return

	is_changing_animation = true
	#log_panel.add_log("🔄 Cambiando a: " + animation_name)

	# ✅ CRÍTICO: Validar modelo antes de usar
	if not current_combined_model or not is_instance_valid(current_combined_model):
		print("❌ No hay modelo combinado válido")
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
	
	#log_panel.add_log("✅ Animación cambiada: " + found_animation)
	_finish_animation_change(true, found_animation)
	
	print("=== FIN CAMBIO DE ANIMACIÓN ===\n")

func _finish_animation_change(success: bool, animation_name: String):
	"""Finalizar proceso de cambio de animación"""
	is_changing_animation = false
	
	if not success:
		#log_panel.add_log("❌ Error al cambiar animación: " + animation_name)
		
		# Notificar error al panel
		if animation_controls_panel and animation_controls_panel.has_method("_reset_ui_on_error"):
			animation_controls_panel._reset_ui_on_error("No se pudo cambiar la animación")

# ========================================================================
# MANEJADORES EXISTENTES (SIN CAMBIOS)
# ========================================================================

func _on_file_selected(file_path: String):
	"""Manejar selección de archivo"""
	print("📁 Archivo seleccionado: %s" % file_path.get_file())
	#log_panel.add_log("📁 Cargando: " + file_path.get_file())
	
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
	#log_panel.add_log("📦 Unidad: " + str(unit_data.get("name", "Unknown")))
	
	if file_loader_panel and file_loader_panel.has_method("populate_unit_files"):
		file_loader_panel.populate_unit_files(unit_data)

func _on_animations_selected_protected(animation_files: Array):
	"""Manejar selección de animaciones con protección anti-loops - CORREGIDO"""
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
	#log_panel.add_log("🎬 Cargando %d animaciones..." % animation_files.size())

	# ✅ CRÍTICO: Limpiar modelo anterior antes de cargar nuevas animaciones
	_safe_cleanup_current_model()
	
	# Limpiar animaciones cargadas para recargar todas
	loaded_animations.clear()
	pending_animations_for_combination = animation_files.duplicate()

	# Cargar TODAS las animaciones
	for i in range(animation_files.size()):
		var anim_file = animation_files[i]
		var full_path = unit_data.path + "/" + anim_file

		print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		#log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])

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

func _safe_cleanup_current_model():
	"""Limpiar modelo actual de forma completamente segura"""
	if current_combined_model and is_instance_valid(current_combined_model):
		print("🧹 Limpiando modelo anterior: %s" % current_combined_model.name)
		
		# Remover de sprite_renderer si está ahí
		if sprite_renderer and sprite_renderer.has_method("stop_preview"):
			sprite_renderer.stop_preview()
		
		# Remover de model_preview_panel si está ahí
		if model_preview_panel and model_preview_panel.has_method("clear_model"):
			model_preview_panel.clear_model()
		
		# Finalmente liberar
		current_combined_model.queue_free()
		current_combined_model = null
		
		print("✅ Modelo anterior limpiado")

func _combine_all_animations():
	"""Combinar TODAS las animaciones en un solo modelo - CORREGIDO"""
	print("\n🔄 === COMBINANDO TODAS LAS ANIMACIONES ===")
	print("Base disponible: %s" % loaded_base_data.get("name", "Unknown"))
	print("Animaciones disponibles: %d" % loaded_animations.size())
	
	# Usar la primera animación como base para la combinación
	var first_anim_name = loaded_animations.keys()[-1]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinando base con primera animación: %s" % first_anim_name)
	
	# ✅ CRÍTICO: Verificar que los datos son válidos antes de combinar
	if loaded_base_data.is_empty() or first_anim_data.is_empty():
		print("❌ Datos de base o animación vacíos")
		return
	
	# Combinar base + primera animación
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)

	if not combined or not is_instance_valid(combined):
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
		#log_panel.add_log("✅ Base: " + str(model_data.get("name", "Unknown")))
		
		if actions_panel:
			actions_panel.set_status("Base cargada - selecciona animaciones")
			
		_try_auto_combine()
	else:
		var anim_name = model_data.get("name", "Unknown")
		loaded_animations[anim_name] = model_data
		#log_panel.add_log("✅ Animación: " + anim_name)
		
		_try_auto_combine()

func _on_load_failed(error_message: String):
	"""Manejar error de carga"""
	print("❌ Error de carga: %s" % error_message)
	#log_panel.add_log("❌ Error: " + error_message)
	
	is_processing_animations = false

func _try_auto_combine():
	"""Intentar combinar automáticamente cuando tengamos base + animación"""
	if loaded_base_data.is_empty() or loaded_animations.is_empty():
		return
	
	if current_combined_model != null and is_instance_valid(current_combined_model):
		return
	
	print("🔄 Auto-combinando modelo...")
	#log_panel.add_log("🔄 Combinando modelo...")
	
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	if combined and is_instance_valid(combined):
		_on_combination_complete_safe(combined)

func _on_combination_complete_safe(combined_model: Node3D):
	"""Manejar combinación exitosa de forma segura - CORREGIDO"""
	if not combined_model or not is_instance_valid(combined_model):
		print("❌ Modelo combinado no es válido")
		return
	
	print("✅ Combinación exitosa: %s" % combined_model.name)
	#log_panel.add_log("✅ Modelo combinado listo")
	
	current_combined_model = combined_model
	
	# Actualizar preview
	if model_preview_panel and model_preview_panel.has_method("set_model"):
		model_preview_panel.set_model(current_combined_model)
		print("✅ Preview actualizado")
	
	# Poblar controles
	_safe_populate_animation_controls()
	
	# Habilitar botones de acción
	if actions_panel:
		actions_panel.enable_render_button()
		actions_panel.set_status("✅ Modelo listo para renderizar")

func _safe_populate_animation_controls():
	"""Poblar controles de animación de forma segura"""
	if not current_combined_model or not is_instance_valid(current_combined_model):
		print("❌ No hay modelo combinado válido para poblar controles")
		return
	
	if not animation_controls_panel:
		print("❌ No hay animation_controls_panel")
		return
	
	if not animation_controls_panel.has_method("populate_animations"):
		print("❌ populate_animations no disponible")
		return
	
	print("🎮 Poblando controles de animación")
	#log_panel.add_log("🎮 Controles de animación listos")
	animation_controls_panel.populate_animations(current_combined_model)
	print("✅ Animation controls poblados exitosamente")

func _on_combination_failed(error: String):
	"""Manejar error de combinación"""
	print("❌ Error combinación: %s" % error)
	#log_panel.add_log("❌ Error combinación: " + error)

# ========================================================================
# FUNCIONES AUXILIARES (SIN CAMBIOS)
# ========================================================================

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

func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar arrays"""
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

# ========================================================================
# INICIALIZACIÓN DE EXTENSIONES - ✅ MODIFICADO PARA INCLUIR MONITOR
# ========================================================================

#func _initialize_extensions():
	#"""Inicializar extensiones de renderizado y exportación"""
	#print("🔧 Inicializando extensiones...")
	#
	## Crear ExportManager si no existe
	#_setup_export_manager()
	#
	## Crear controles de cámara
	#_setup_camera_controls()
	#
	## Crear diálogo de exportación
	#_setup_export_dialog()
	#
	## ✅ NUEVO: Configurar monitor de animaciones
	#_setup_animation_monitor()
	#
	## Conectar señales adicionales
	#_connect_extension_signals()
	#
	#print("✅ Extensiones inicializadas")

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

# ========================================================================
# ✅ NUEVA FUNCIÓN: CONFIGURAR MONITOR DE ANIMACIONES
# ========================================================================

func _setup_animation_monitor():
	"""Configurar monitor de animaciones"""
	var monitor_script = load("res://scripts/debug/animation_monitor.gd")
	if monitor_script:
		animation_monitor = monitor_script.new()
		animation_monitor.name = "AnimationMonitor"
		add_child(animation_monitor)
		
		# Configuración inicial
		animation_monitor.update_interval = 1.0  # Actualizar cada segundo
		
		print("✅ Monitor de animaciones configurado")
	else:
		print("⚠️ Script AnimationMonitor no encontrado")

# ========================================================================
# CONECTAR SEÑALES DE EXTENSIONES - ✅ MODIFICADO PARA INCLUIR MONITOR
# ========================================================================

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
	
	# Controles de cámara
	if camera_controls:
		if camera_controls.has_signal("camera_moved"):
			camera_controls.camera_moved.connect(_on_camera_moved)
		if camera_controls.has_signal("model_rotated"):
			camera_controls.model_rotated.connect(_on_model_rotated)
	
	# ✅ NUEVO: Monitor de animaciones
	if animation_monitor:
		if animation_monitor.has_signal("animations_status_changed"):
			animation_monitor.animations_status_changed.connect(_on_animations_status_changed)
	
	print("🔗 Señales de extensiones conectadas")

# ========================================================================
# ✅ NUEVA FUNCIÓN: MANEJADOR DE SEÑALES DEL MONITOR
# ========================================================================

func _on_animations_status_changed(active_count: int, total_count: int):
	"""Manejar cambios en el estado de animaciones"""
	# Log solo si hay múltiples animaciones activas (posible problema)
	if active_count > 1:
		print("⚠️ MÚLTIPLES ANIMACIONES DETECTADAS: %d/%d activas" % [active_count, total_count])
		#log_panel.add_log("⚠️ Múltiples animaciones detectadas: %d activas" % active_count)
	elif active_count == 0 and total_count > 0:
		# Esto podría indicar que las animaciones se detuvieron inesperadamente
		print("🔍 Todas las animaciones se detuvieron (%d disponibles)" % total_count)

# ========================================================================
# FUNCIONES DE SOPORTE (SIMPLIFICADAS)
# ========================================================================

#func _get_current_render_settings() -> Dictionary:
	#"""Obtener configuración actual de renderizado"""
	#
	#if not current_render_settings.is_empty():
		#print("📋 Usando configuración actual guardada")
		#return current_render_settings.duplicate()
	#
	#
	#
	
	## Fallback: usar la primera animación disponible
	#if current_combined_model and is_instance_valid(current_combined_model):
		#var anim_player = _find_animation_player(current_combined_model)
		#if anim_player and anim_player.get_animation_list().size() > 0:
			#return anim_player.get_animation_list()[0]
	#
	#return ""

func _get_available_animation_names() -> Array:
	"""Obtener lista de animaciones disponibles"""
	var animations = []
	
	if current_combined_model and is_instance_valid(current_combined_model):
		var anim_player = _find_animation_player(current_combined_model)
		if anim_player:
			animations = anim_player.get_animation_list()
	
	return animations

# ========================================================================
# MANEJADORES DE EXPORTACIÓN (SIN CAMBIOS SIGNIFICATIVOS)
# ========================================================================

func _on_export_dialog_started(config: Dictionary):
	"""Manejar inicio de exportación desde diálogo"""
	print("🚀 Exportación iniciada con configuración:")
	print(config)
	
	# Añadir animación actual si es necesario
	if config.get("animation_mode") == "current":
		config["current_animation"] = _get_current_animation_name()
	
	# ✅ AGREGADO: Debug del estado antes de exportar
	if export_manager and export_manager.has_method("debug_export_state"):
		export_manager.debug_export_state()
	
	# Iniciar exportación
	if export_manager and export_manager.has_method("export_sprite_sheets"):
		export_manager.export_sprite_sheets(config)
	else:
		#log_panel.add_log("❌ ExportManager no disponible")
		pass

func _on_export_dialog_cancelled():
	"""Manejar cancelación de exportación"""
	log_panel.add_log("❌ Exportación cancelada por usuario")

func _on_export_progress(current: int, total: int, message: String):
	"""Actualizar progreso de exportación"""
	if export_dialog and export_dialog.has_method("update_progress"):
		export_dialog.update_progress(current, total, message)

func _on_export_complete(output_folder: String):
	"""Manejar completación exitosa de exportación"""
	print("✅ Exportación completada en: %s" % output_folder)
	
	if export_dialog and export_dialog.has_method("export_completed"):
		export_dialog.export_completed(true, "Exportación completada exitosamente")
	
	#log_panel.add_log("✅ Sprites exportados a: %s" % output_folder)

func _on_export_failed(error: String):
	"""Manejar fallo en exportación"""
	print("❌ Exportación falló: %s" % error)
	
	if export_dialog and export_dialog.has_method("export_completed"):
		export_dialog.export_completed(false, error)
	
	#log_panel.add_log("❌ Error en exportación: %s" % error)

# ========================================================================
# MANEJADORES DE CONTROLES DE CÁMARA (SIN CAMBIOS)
# ========================================================================

func _on_camera_moved(new_position: Vector3):
	"""Manejar movimiento de cámara"""
	# Actualizar preview si es necesario
	pass

func _on_model_rotated(new_rotation: Vector3):
	"""Manejar rotación de modelo"""
	# ✅ CRÍTICO: Validar modelo antes de usar
	if current_combined_model and is_instance_valid(current_combined_model):
		current_combined_model.rotation_degrees = new_rotation
	
	# Actualizar controles de cámara con referencia al modelo
	if camera_controls and camera_controls.has_method("set_model"):
		camera_controls.set_model(current_combined_model)

# ========================================================================
# ✅ NUEVAS FUNCIONES PÚBLICAS PARA EL PIPELINE
# ========================================================================

#func get_current_combined_model() -> Node3D:
	#"""Función pública para que el pipeline obtenga el modelo combinado"""
	#return current_combined_model

# ========================================================================
# FUNCIONES PÚBLICAS PARA DEBUG Y CONTROL MANUAL - ✅ MODIFICADAS
# ========================================================================

func force_reset():
	"""Reset completo del coordinator - CORREGIDO"""
	print("🚨 FORCE RESET COORDINATOR")
	
	# Reset flags
	is_processing_animations = false
	last_animations_processed.clear()
	processing_start_time = 0.0
	is_changing_animation = false
	
	# Clear data
	loaded_base_data.clear()
	loaded_animations.clear()
	pending_animations_for_combination.clear()
	
	# ✅ CRÍTICO: Limpiar modelo de forma segura
	_safe_cleanup_current_model()
	
	# ✅ NUEVO: Reset del pipeline
	if spritesheet_pipeline and spritesheet_pipeline.has_method("force_reset_pipeline"):
		spritesheet_pipeline.force_reset_pipeline()
		print("🔄 Pipeline reseteado")
	
	# ✅ NUEVO: Reset del monitor de animaciones
	if animation_monitor:
		animation_monitor.stop_monitoring()
		print("🔄 Monitor de animaciones detenido")
	
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

func get_current_state() -> Dictionary:
	"""Estado actual del sistema - ✅ MODIFICADO PARA INCLUIR MONITOR"""
	var pipeline_status = {}
	if spritesheet_pipeline:
		pipeline_status = spritesheet_pipeline.get_pipeline_status()
	
	# ✅ NUEVO: Estado del monitor de animaciones
	var monitor_status = {}
	if animation_monitor:
		var snapshot = animation_monitor.get_animations_snapshot()
		monitor_status = {
			"total_players": snapshot.total_players,
			"active_players": snapshot.active_players,
			"monitoring_enabled": animation_monitor.monitoring_enabled
		}
	
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_count": loaded_animations.size(),
		"combined_ready": current_combined_model != null and is_instance_valid(current_combined_model),
		"processing": is_processing_animations,
		"changing_animation": is_changing_animation,
		"export_manager_available": export_manager != null,
		"camera_controls_available": camera_controls != null,
		"pipeline_available": spritesheet_pipeline != null,
		"pipeline_status": pipeline_status,
		# ✅ NUEVO: Estado del monitor
		"animation_monitor_available": animation_monitor != null,
		"monitor_status": monitor_status
	}

func debug_state():
	"""Debug detallado del estado - ✅ MODIFICADO PARA INCLUIR MONITOR"""
	print("\n🎮 === COORDINATOR DEBUG (REFACTORIZADO) ===")
	var state = get_current_state()
	print("📊 ESTADO:")
	print("  Base cargada: %s" % state.base_loaded)
	print("  Animaciones: %d" % state.animations_count)
	print("  Modelo combinado: %s" % state.combined_ready)
	print("  Procesando: %s" % state.processing)
	print("  Cambiando animación: %s" % state.changing_animation)
	print("  Pipeline disponible: %s" % ("✅" if state.pipeline_available else "❌"))
	
	if animation_controls_panel and animation_controls_panel.has_method("debug_state"):
		print("\n🎮 ANIMATION CONTROLS:")
		animation_controls_panel.debug_state()
	
	# ✅ NUEVO: Debug del pipeline
	if spritesheet_pipeline and spritesheet_pipeline.has_method("debug_pipeline_state"):
		spritesheet_pipeline.debug_pipeline_state()
	
	# ✅ NUEVO: Debug del monitor de animaciones
	if animation_monitor:
		print("\n🔍 MONITOR DE ANIMACIONES:")
		var snapshot = animation_monitor.get_animations_snapshot()
		print("  Total AnimationPlayers: %d" % snapshot.total_players)
		print("  Animaciones activas: %d" % snapshot.active_players)
		print("  Monitoreo activo: %s" % animation_monitor.monitoring_enabled)
		
		if snapshot.active_players > 0:
			print("  🎬 ANIMACIONES ACTIVAS:")
			var active_anims = animation_monitor.get_detailed_active_animations()
			for anim in active_anims:
				print("    - %s: %s (%.1f%%)" % [
					anim.player_name, 
					anim.animation_name, 
					anim.progress * 100
				])
	
	print("==============================\n")

# ========================================================================
# ✅ NUEVAS FUNCIONES SIMPLIFICADAS PARA USO PÚBLICO
# ========================================================================

func generate_spritesheet_simple(animation_name: String = "") -> bool:
	"""API simple para generar sprite sheet - usar desde consola"""
	if not spritesheet_pipeline:
		print("❌ Pipeline no disponible")
		return false
	
	var anim_to_use = animation_name
	if anim_to_use == "":
		anim_to_use = _get_current_animation_name()
	
	if anim_to_use == "":
		print("❌ No hay animación para renderizar")
		return false
	
	print("🚀 Generando sprite sheet simple: %s" % anim_to_use)
	return spritesheet_pipeline.generate_spritesheet(anim_to_use)

func generate_all_spritesheets_simple() -> bool:
	"""API simple para generar todos los sprite sheets"""
	if not spritesheet_pipeline:
		print("❌ Pipeline no disponible")
		return false
	
	print("🚀 Generando todos los sprite sheets")
	return spritesheet_pipeline.generate_all_spritesheets()

# Función legacy para compatibilidad - ahora usa pipeline
func generate_complete_spritesheet():
	"""Función legacy - ahora redirige al pipeline"""
	print("⚠️ Función legacy detectada - redirigiendo a pipeline")
	return generate_spritesheet_simple()

# ========================================================================
# ✅ NUEVAS FUNCIONES PÚBLICAS PARA CONTROL DEL MONITOR
# ========================================================================

func start_animation_monitoring(interval: float = 1.0):
	"""Iniciar monitoreo automático de animaciones"""
	if animation_monitor:
		animation_monitor.start_monitoring(interval)
		print("🔍 Monitoreo de animaciones iniciado")
	else:
		print("❌ Monitor de animaciones no disponible")

func stop_animation_monitoring():
	"""Detener monitoreo automático de animaciones"""
	if animation_monitor:
		animation_monitor.stop_monitoring()
		print("🔍 Monitoreo de animaciones detenido")
	else:
		print("❌ Monitor de animaciones no disponible")

func get_animations_report() -> Dictionary:
	"""Obtener reporte detallado de animaciones"""
	if animation_monitor:
		return animation_monitor.get_animations_snapshot()
	else:
		return {"error": "Monitor no disponible"}

func print_animations_status():
	"""Imprimir estado actual de animaciones"""
	if animation_monitor:
		animation_monitor.print_current_status()
	else:
		print("❌ Monitor de animaciones no disponible")

func count_active_animations() -> int:
	"""Obtener conteo rápido de animaciones activas"""
	if animation_monitor:
		return animation_monitor.get_active_animations_count()
	else:
		return -1

#func _setup_unified_camera_system():
	#"""Inicializar sistema de cámara unificada"""
	#print("🎥 Configurando sistema de cámara unificada...")
#
	## Crear helper de sincronización
	#var helper_script = load("res://scripts/helpers/camera_sync_helper.gd")
	#if helper_script:
		#camera_sync_helper = helper_script.new()
		#camera_sync_helper.name = "CameraSyncHelper" 
		#add_child(camera_sync_helper)
		#print("✅ Sistema de cámara unificada configurado")
	#else:
		#print("⚠️ No se pudo cargar CameraSyncHelper")

# ========================================================================
# FUNCIONES DE DEBUG PARA EL SISTEMA UNIFICADO
# ========================================================================

func debug_unified_camera_system():
	"""Debug del sistema de cámara unificada"""
	print("\n🎥 === DEBUG SISTEMA CÁMARA UNIFICADA ===")
	print("CameraSyncHelper: %s" % ("✅" if camera_sync_helper else "❌"))

	if camera_sync_helper:
		camera_sync_helper.debug_sync_state()

	if sprite_renderer and sprite_renderer.has_method("debug_shared_state"):
		sprite_renderer.debug_shared_state()

	print("==========================================\n")

func get_unified_camera_info() -> Dictionary:
	"""Obtener información del sistema de cámara unificada"""
	var info = {
		"sync_helper_active": camera_sync_helper != null,
		"shared_viewport": null,
		"shared_camera": null,
		"sync_status": "unknown"
	}

	if camera_sync_helper:
		info.sync_status = "active" if camera_sync_helper.is_sync_active() else "inactive"
		
		if camera_sync_helper.has_method("get_shared_viewport"):
			info.shared_viewport = camera_sync_helper.get_shared_viewport()
		
		if camera_sync_helper.has_method("get_shared_camera"):
			info.shared_camera = camera_sync_helper.get_shared_camera()

	return info


#func _on_render_settings_changed(settings: Dictionary):
	#"""Manejar cambios en configuración de renderizado desde UI"""
	#print("📡 Configuración recibida desde UI:")
	#print("  Norte: %.0f°" % settings.get("north_offset", 0.0))
	#
	## Enviar al camera_controller si existe un modelo
	#if current_combined_model and is_instance_valid(current_combined_model):
		## Buscar camera_controller en sprite_renderer
		#if sprite_renderer:
			#var camera_controller = sprite_renderer.get_node_or_null("CameraController")
			#if camera_controller and camera_controller.has_method("set_camera_settings"):
				#camera_controller.set_camera_settings(settings)
				#print("✅ Configuración enviada al camera_controller")
			#else:
				#print("❌ Camera controller no encontrado en sprite_renderer")
		#
		## También enviar al model_preview_panel si existe
		#if model_preview_panel:
			#var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
			#if preview_camera and preview_camera.has_method("set_camera_settings"):
				#preview_camera.set_camera_settings(settings)
				#print("✅ Configuración enviada al preview camera")
	#else:
		#print("⚠️ No hay modelo combinado para aplicar configuración")
#
	## También actualizar configuración interna
	#log_panel.add_log("⚙️ Configuración actualizada - Norte: %.0f°" % settings.get("north_offset", 0.0))


#func _on_render_settings_changed(settings: Dictionary):
	#"""Manejar cambios en configuración de renderizado desde UI - CORREGIDO"""
	#print("📡 Configuración recibida desde UI:")
	#print("  camera_height: %.1f" % settings.get("camera_height", 12.0))
	#print("  camera_angle: %.1f°" % settings.get("camera_angle", 45.0))
	#print("  Norte: %.0f°" % settings.get("north_offset", 0.0))
	#
	## ✅ CORREGIDO: Enviar DIRECTAMENTE al preview camera
	#if model_preview_panel:
		#var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
		#if preview_camera and preview_camera.has_method("set_camera_settings"):
			#preview_camera.set_camera_settings(settings)
			#print("✅ Configuración enviada al preview camera")
			#
			## ✅ NUEVO: Forzar actualización inmediata
			#if preview_camera.has_method("update_camera_position"):
				#preview_camera.update_camera_position()
				#print("🔄 Posición de cámara actualizada inmediatamente")
		#else:
			#print("❌ Preview camera controller no encontrado")
			## Debug: mostrar path completo del preview panel
			#if model_preview_panel:
				#print("🔍 Preview panel encontrado en: %s" % model_preview_panel.get_path())
				#var viewport_container = model_preview_panel.get_node_or_null("ViewportContainer")
				#if viewport_container:
					#print("🔍 ViewportContainer encontrado")
					#var subviewport = viewport_container.get_node_or_null("SubViewport")
					#if subviewport:
						#print("🔍 SubViewport encontrado")
						#print("🔍 Hijos de SubViewport: %s" % str(subviewport.get_children().map(func(n): return n.name)))
					#else:
						#print("❌ SubViewport NO encontrado")
				#else:
					#print("❌ ViewportContainer NO encontrado")
	#else:
		#print("❌ model_preview_panel no encontrado")
	#
	## También actualizar configuración interna
	#log_panel.add_log("⚙️ Configuración actualizada - altura: %.1f" % settings.get("camera_height", 12.0))


#func _on_render_settings_changed(settings: Dictionary):
	#"""Manejar cambios en configuración de renderizado desde UI - ARREGLADO"""
	#print("📡 Configuración recibida desde SettingsPanel:")
	#print("  directions: %d" % settings.get("directions", 16))
	#print("  camera_height: %.1f" % settings.get("camera_height", 12.0))
	#print("  camera_angle: %.1f°" % settings.get("camera_angle", 45.0))
	#print("  sprite_size: %d" % settings.get("sprite_size", 512))
	#print("  Norte: %.0f°" % settings.get("north_offset", 0.0))
	#
	## ✅ CRÍTICO: Enviar configuración a TODOS los sistemas
	#
	## 1. Enviar al Model Preview Panel (para preview en tiempo real)
	#if model_preview_panel:
		#var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
		#if preview_camera and preview_camera.has_method("set_camera_settings"):
			#preview_camera.set_camera_settings(settings)
			#print("✅ Configuración enviada al preview camera")
			#
			## Forzar actualización inmediata
			#if preview_camera.has_method("update_camera_position"):
				#preview_camera.update_camera_position()
		#else:
			#print("❌ Preview camera controller no encontrado")
	#
	## 2. Enviar al Sprite Renderer (para renderizado)
	#if sprite_renderer:
		## ✅ NUEVO: Inicializar configuración directamente
		#if sprite_renderer.has_method("initialize"):
			#sprite_renderer.initialize(settings)
			#print("✅ Configuración enviada al sprite renderer")
		#
		## ✅ NUEVO: También actualizar configuración interna
		#if sprite_renderer.has_method("update_render_settings"):
			#sprite_renderer.update_render_settings(settings)
	#
	## 3. ✅ NUEVO: Aplicar configuración al pipeline si existe
	#if spritesheet_pipeline and spritesheet_pipeline.has_method("update_pipeline_settings"):
		#spritesheet_pipeline.update_pipeline_settings(settings)
		#print("✅ Configuración enviada al pipeline")
	#
	## ✅ NUEVO: Guardar configuración como configuración actual del sistema
	#current_render_settings = settings
	#
	## Log para confirmación
	#log_panel.add_log("⚙️ Configuración actualizada - direcciones: %d, altura: %.1f" % [settings.get("directions", 16), settings.get("camera_height", 12.0)])
#
## ✅ AGREGAR: Variable para mantener configuración actual
#var current_render_settings: Dictionary = {}
#


func debug_preview_camera_path():
	"""Debug para encontrar la ruta correcta al camera controller"""
	print("\n🔍 === DEBUG PREVIEW CAMERA PATH ===")
	
	if model_preview_panel:
		print("✅ model_preview_panel encontrado: %s" % model_preview_panel.get_path())
		
		# Explorar estructura
		for child in model_preview_panel.get_children():
			print("  - %s" % child.name)
			if child.name == "ViewportContainer":
				for subchild in child.get_children():
					print("    - %s" % subchild.name)
					if subchild.name == "SubViewport":
						for subsubchild in subchild.get_children():
							print("      - %s" % subsubchild.name)
	else:
		print("❌ model_preview_panel NO encontrado")
	
	print("=====================================\n")

# En viewer_coordinator.gd - REEMPLAZAR CON:

# Y en la función _ready() o crear nueva función:
#func _create_core_components():
	#"""Crear componentes core que no existen en la escena"""
	#print("🔧 Creando componentes core...")
	#
	## 1. Crear SpriteRenderer
	#var sprite_script = load("res://scripts/rendering/sprite_renderer.gd")
	#if sprite_script:
		#sprite_renderer = sprite_script.new()
		#sprite_renderer.name = "SpriteRenderer"
		#add_child(sprite_renderer)
		#print("✅ SpriteRenderer creado")
	#else:
		#print("❌ No se pudo cargar script de SpriteRenderer")
	#
	## 2. Crear ExportManager  
	#var export_script = load("res://scripts/export/export_manager.gd")
	#if export_script:
		#export_manager = export_script.new()
		#export_manager.name = "ExportManager"
		#add_child(export_manager)
		#print("✅ ExportManager creado")
	#else:
		#print("❌ No se pudo cargar script de ExportManager")
	#
	#print("✅ Componentes core creados")



# En viewer_coordinator.gd - FUNCIÓN A AÑADIR/CORREGIR:

func _create_core_components():
	"""Crear componentes core que no existen en la escena"""
	print("🔧 Creando componentes core...")
	
	# ✅ Crear SpriteRenderer
	var sprite_script = load("res://scripts/rendering/sprite_renderer.gd")
	if sprite_script:
		sprite_renderer = sprite_script.new()
		sprite_renderer.name = "SpriteRenderer"
		add_child(sprite_renderer)
		print("✅ SpriteRenderer creado")
	else:
		print("❌ No se pudo cargar script de SpriteRenderer")
	
	# ✅ Crear ExportManager  
	var export_script = load("res://scripts/export/export_manager.gd")
	if export_script:
		export_manager = export_script.new()
		export_manager.name = "ExportManager"
		add_child(export_manager)
		print("✅ ExportManager creado")
	else:
		print("❌ No se pudo cargar script de ExportManager")
	
	print("✅ Componentes core creados")

# ✅ CORREGIR LA FUNCIÓN DE INICIALIZACIÓN DEL PIPELINE:
func _initialize_spritesheet_pipeline():
	"""Inicializar el pipeline de sprite sheets"""
	print("🏭 Inicializando SpritesheetPipeline...")
	
	# ✅ VALIDAR COMPONENTES ANTES DE CREAR PIPELINE
	if not sprite_renderer:
		print("❌ SpriteRenderer no disponible para pipeline")
		return
	
	if not export_manager:
		print("❌ ExportManager no disponible para pipeline")
		return
	
	var pipeline_script = load("res://scripts/rendering/spritesheet_pipeline.gd")
	if pipeline_script:
		spritesheet_pipeline = pipeline_script.new()
		spritesheet_pipeline.name = "SpritesheetPipeline"
		add_child(spritesheet_pipeline)
		
		# ✅ CONFIGURAR CON COMPONENTES VALIDADOS
		spritesheet_pipeline.setup_pipeline(sprite_renderer, export_manager, animation_manager)
		
		# ✅ VERIFICAR QUE LA CONFIGURACIÓN FUNCIONÓ
		await get_tree().process_frame  # Esperar un frame
		
		_connect_pipeline_signals()
		
		print("✅ SpritesheetPipeline inicializado y configurado")
	else:
		print("❌ No se pudo cargar script de SpritesheetPipeline")



# scripts/viewer/viewer_coordinator.gd
# FUNCIÓN CORREGIDA - Sin errores de conexión duplicada
# Input: spritesheet_pipeline con señales disponibles
# Output: Conexiones seguras sin duplicados + logging detallado

# ========================================================================
# ✅ NUEVA FUNCIÓN: DESCONECTAR SEÑALES DEL PIPELINE DE FORMA SEGURA
# ========================================================================

func _disconnect_pipeline_signals():
	"""Desconectar señales del pipeline de forma segura"""
	if not spritesheet_pipeline:
		return
	
	print("🔌 Desconectando señales del pipeline...")
	
	# Lista de señales y sus manejadores para desconectar
	var signal_connections = [
		{"signal": "pipeline_started", "handler": _on_pipeline_started},
		{"signal": "pipeline_progress", "handler": _on_pipeline_progress},
		{"signal": "pipeline_complete", "handler": _on_pipeline_complete},
		{"signal": "pipeline_failed", "handler": _on_pipeline_failed},
		{"signal": "rendering_phase_started", "handler": _on_rendering_phase_started},
		{"signal": "rendering_phase_complete", "handler": _on_rendering_phase_complete},
		{"signal": "export_phase_started", "handler": _on_export_phase_started},
		{"signal": "export_phase_complete", "handler": _on_export_phase_complete}
	]
	
	var disconnected_count = 0
	
	for connection in signal_connections:
		var signal_name = connection.signal
		var handler = connection.handler
		
		# Verificar si la señal existe en el objeto
		if spritesheet_pipeline.has_signal(signal_name):
			# Verificar si está conectada antes de desconectar
			if spritesheet_pipeline.is_connected(signal_name, handler):
				spritesheet_pipeline.disconnect(signal_name, handler)
				disconnected_count += 1
				print("  ✅ Desconectado: %s" % signal_name)
			else:
				print("  ⚪ No conectado: %s" % signal_name)
		else:
			print("  ❌ Señal no existe: %s" % signal_name)
	
	print("🔌 Pipeline signals desconectadas: %d/%d" % [disconnected_count, signal_connections.size()])

# ========================================================================
# ✅ FUNCIÓN CORREGIDA: CONECTAR SEÑALES DEL PIPELINE SIN DUPLICADOS
# ========================================================================

func _connect_pipeline_signals():
	"""Conectar señales del pipeline verificando duplicados"""
	if not spritesheet_pipeline:
		print("❌ spritesheet_pipeline no disponible para conectar señales")
		return
	
	print("🔗 Conectando señales del pipeline (con verificación anti-duplicados)...")
	
	# Lista de señales y sus manejadores para conectar
	var signal_connections = [
		{"signal": "pipeline_started", "handler": _on_pipeline_started, "description": "Inicio del pipeline"},
		{"signal": "pipeline_progress", "handler": _on_pipeline_progress, "description": "Progreso del pipeline"},
		{"signal": "pipeline_complete", "handler": _on_pipeline_complete, "description": "Pipeline completado"},
		{"signal": "pipeline_failed", "handler": _on_pipeline_failed, "description": "Pipeline falló"},
		{"signal": "rendering_phase_started", "handler": _on_rendering_phase_started, "description": "Inicio renderizado"},
		{"signal": "rendering_phase_complete", "handler": _on_rendering_phase_complete, "description": "Renderizado completo"},
		{"signal": "export_phase_started", "handler": _on_export_phase_started, "description": "Inicio exportación"},
		{"signal": "export_phase_complete", "handler": _on_export_phase_complete, "description": "Exportación completa"}
	]
	
	var connected_count = 0
	var skipped_count = 0
	var error_count = 0
	
	for connection in signal_connections:
		var signal_name = connection.signal
		var handler = connection.handler
		var description = connection.description
		
		# Verificar si la señal existe en el objeto
		if not spritesheet_pipeline.has_signal(signal_name):
			print("  ❌ Señal no existe: %s (%s)" % [signal_name, description])
			error_count += 1
			continue
		
		# Verificar si ya está conectada
		if spritesheet_pipeline.is_connected(signal_name, handler):
			print("  ⚠️ Ya conectado: %s (%s)" % [signal_name, description])
			skipped_count += 1
			continue
		
		# Intentar conectar la señal
		var connection_result = spritesheet_pipeline.connect(signal_name, handler)
		if connection_result == OK:
			connected_count += 1
			print("  ✅ Conectado: %s (%s)" % [signal_name, description])
		else:
			error_count += 1
			print("  ❌ Error conectando: %s (%s) - Error: %s" % [signal_name, description, str(connection_result)])
	
	# Reporte final
	print("🔗 Resumen conexiones pipeline:")
	print("  ✅ Conectadas: %d" % connected_count)
	print("  ⚠️ Saltadas (ya conectadas): %d" % skipped_count)
	print("  ❌ Errores: %d" % error_count)
	print("  📊 Total procesadas: %d/%d" % [connected_count + skipped_count, signal_connections.size()])
	
	# Validar que las conexiones críticas estén funcionando
	if connected_count > 0 or skipped_count > 0:
		print("✅ Pipeline signals operativo")
	else:
		print("❌ ADVERTENCIA: Ninguna señal del pipeline conectada")

# ========================================================================
# ✅ FUNCIÓN AUXILIAR: VERIFICAR ESTADO DE CONEXIONES
# ========================================================================

func debug_pipeline_connections():
	"""Debug del estado actual de conexiones del pipeline"""
	if not spritesheet_pipeline:
		print("❌ spritesheet_pipeline no disponible")
		return
	
	print("\n🔍 === DEBUG CONEXIONES PIPELINE ===")
	
	var pipeline_signals = [
		"pipeline_started", "pipeline_progress", "pipeline_complete", "pipeline_failed",
		"rendering_phase_started", "rendering_phase_complete", 
		"export_phase_started", "export_phase_complete"
	]
	
	for signal_name in pipeline_signals:
		if spritesheet_pipeline.has_signal(signal_name):
			var connections = spritesheet_pipeline.get_signal_connection_list(signal_name)
			print("📡 %s: %d conexiones" % [signal_name, connections.size()])
			
			for conn in connections:
				if conn.has("callable"):
					print("    -> %s.%s" % [conn.callable.get_object().name if conn.callable.get_object() else "null", conn.callable.get_method()])
				elif conn.has("target") and conn.has("method"):
					print("    -> %s.%s" % [conn.target.name if conn.target else "null", conn.method])
		else:
			print("❌ %s: Señal no existe" % signal_name)
	
	print("=====================================\n")

# ========================================================================
# ✅ FUNCIÓN AUXILIAR: FORZAR RESET DE CONEXIONES
# ========================================================================

func force_reset_pipeline_connections():
	"""Forzar reset completo de conexiones del pipeline"""
	print("🚨 FORCE RESET - Conexiones del pipeline")
	
	# Primero desconectar todas
	_disconnect_pipeline_signals()
	
	# Esperar un frame para que se estabilice
	await get_tree().process_frame
	
	# Luego reconectar
	_connect_pipeline_signals()
	
	# Verificar resultado
	debug_pipeline_connections()
	
	print("✅ Reset de conexiones completado")

# ========================================================================
# ✅ CORECCIÓN: FUNCIÓN PARA PASAR PARÁMETROS DE ÁREA DE CAPTURA
# ========================================================================

#func _get_current_render_settings_with_capture_area() -> Dictionary:
	#"""Obtener configuración actual incluyendo parámetros de área de captura"""
	#
	## Obtener configuración base
	#var settings = _get_current_render_settings()
	#
	## ✅ ARREGLAR: Asegurar que el parámetro de tamaño se incluya correctamente
	#if settings_panel and settings_panel.has_method("get_capture_area_settings"):
		#var capture_settings = settings_panel.get_capture_area_settings()
		#
		## Validar y agregar configuración de área de captura
		#if capture_settings.has("capture_size"):
			#settings["capture_size"] = capture_settings.capture_size
			#print("✅ Área de captura - tamaño: %d" % capture_settings.capture_size)
		#
		#if capture_settings.has("capture_enabled"):
			#settings["capture_enabled"] = capture_settings.capture_enabled
			#print("✅ Área de captura - habilitada: %s" % capture_settings.capture_enabled)
			#
		## Asegurar que sprite_size coincida con capture_size si está habilitado
		#if capture_settings.get("capture_enabled", false) and capture_settings.has("capture_size"):
			#settings["sprite_size"] = capture_settings.capture_size
			#print("🔄 sprite_size actualizado a capture_size: %d" % capture_settings.capture_size)
	#else:
		## Fallback: usar sprite_size como capture_size si no hay configuración específica
		#if settings.has("sprite_size"):
			#settings["capture_size"] = settings.sprite_size
			#settings["capture_enabled"] = true
			#print("⚠️ Usando sprite_size como capture_size: %d" % settings.sprite_size)
	#
	#return settings

# ========================================================================
# ✅ FUNCIÓN CORREGIDA: RENDERIZADO CON PARÁMETROS CORRECTOS
# ========================================================================

#func _on_render_requested_with_capture_fix():
	#"""✅ VERSIÓN CORREGIDA: Manejar renderizado con parámetros de área de captura"""
	#print("🎨 Renderizado solicitado - CON CORRECCIÓN DE ÁREA DE CAPTURA")
	#log_panel.add_log("🎨 Iniciando renderizado con área de captura...")
#
	## Validar prerrequisitos
	#if not current_combined_model or not is_instance_valid(current_combined_model):
		#log_panel.add_log("❌ No hay modelo válido para renderizar")
		#if actions_panel:
			#actions_panel.show_error("No hay modelo cargado")
		#return
#
	#if not spritesheet_pipeline:
		#log_panel.add_log("❌ Pipeline no disponible")
		#if actions_panel:
			#actions_panel.show_error("Pipeline no inicializado")
		#return
#
	#if spritesheet_pipeline.is_busy():
		#log_panel.add_log("⚠️ Pipeline ocupado")
		#if actions_panel:
			#actions_panel.show_error("Pipeline ocupado, espera a que termine")
		#return
#
	## Obtener animación actual
	#var current_anim = _get_current_animation_name()
	#if current_anim == "":
		#log_panel.add_log("❌ No hay animación seleccionada")
		#if actions_panel:
			#actions_panel.show_error("Selecciona una animación")
		#return
#
	## ✅ CORRECCIÓN: Obtener configuración incluyendo área de captura
	#var config = _get_current_render_settings_with_capture_area()
	#
	## Debug de configuración
	#print("📋 Configuración de renderizado:")
	#print("  sprite_size: %d" % config.get("sprite_size", 512))
	#print("  capture_size: %d" % config.get("capture_size", 512))
	#print("  capture_enabled: %s" % config.get("capture_enabled", true))
	#print("  directions: %d" % config.get("directions", 16))
#
	## ✅ USAR PIPELINE con configuración corregida
	#var success = spritesheet_pipeline.generate_spritesheet(current_anim, config)
#
	#if not success:
		#log_panel.add_log("❌ No se pudo iniciar pipeline")
		#if actions_panel:
			#actions_panel.show_error("Error iniciando pipeline")
	#else:
		#log_panel.add_log("✅ Pipeline iniciado con área de captura: %d" % config.get("capture_size", 512))

# ========================================================================
# ✅ FUNCIÓN DE VALIDACIÓN: VERIFICAR PIPELINE COMPLETAMENTE CONFIGURADO
# ========================================================================

func validate_pipeline_setup() -> bool:
	"""Validar que el pipeline esté completamente configurado"""
	print("\n🔍 === VALIDACIÓN PIPELINE SETUP ===")
	
	var validation_passed = true
	
	# 1. Verificar que existe el pipeline
	if not spritesheet_pipeline:
		print("❌ spritesheet_pipeline no existe")
		validation_passed = false
	else:
		print("✅ spritesheet_pipeline existe")
	
	# 2. Verificar métodos críticos del pipeline
	if spritesheet_pipeline:
		var required_methods = ["generate_spritesheet", "is_busy", "setup_pipeline"]
		for method in required_methods:
			if spritesheet_pipeline.has_method(method):
				print("✅ Método disponible: %s" % method)
			else:
				print("❌ Método faltante: %s" % method)
				validation_passed = false
	
	# 3. Verificar conexiones de señales
	if spritesheet_pipeline:
		var required_signals = ["pipeline_started", "export_phase_complete", "export_phase_started"]
		for signal_name in required_signals:
			if spritesheet_pipeline.has_signal(signal_name):
				var connections = spritesheet_pipeline.get_signal_connection_list(signal_name)
				if connections.size() > 0:
					print("✅ Señal conectada: %s (%d conexiones)" % [signal_name, connections.size()])
				else:
					print("⚠️ Señal sin conectar: %s" % signal_name)
			else:
				print("❌ Señal faltante: %s" % signal_name)
				validation_passed = false
	
	# 4. Verificar componentes del pipeline
	if spritesheet_pipeline:
		if spritesheet_pipeline.sprite_renderer:
			print("✅ sprite_renderer configurado en pipeline")
		else:
			print("❌ sprite_renderer faltante en pipeline")
			validation_passed = false
			
		if spritesheet_pipeline.export_manager:
			print("✅ export_manager configurado en pipeline")
		else:
			print("❌ export_manager faltante en pipeline")
			validation_passed = false
	
	print("📊 Validación pipeline: %s" % ("✅ PASÓ" if validation_passed else "❌ FALLÓ"))
	print("=====================================\n")
	
	return validation_passed



# scripts/viewer/viewer_coordinator.gd
# CORRECCIÓN: Pasar correctamente parámetros de área de captura
# Input: settings_changed del settings_panel con capture_area_size
# Output: Configuración correcta para sprite_renderer con camera_distance

# ========================================================================
# ✅ FUNCIÓN CORREGIDA: OBTENER CONFIGURACIÓN CON ÁREA DE CAPTURA
# ========================================================================

func _get_current_render_settings_with_capture_area() -> Dictionary:
	"""Obtener configuración actual incluyendo parámetros de área de captura CORREGIDOS"""
	
	# Obtener configuración base
	var settings = _get_current_render_settings()
	
	print("🔍 Debug configuración original:")
	print("  sprite_size: %d" % settings.get("sprite_size", 128))
	print("  capture_area_size: %s" % str(settings.get("capture_area_size", "NO ENCONTRADO")))
	
	# ✅ CORRECCIÓN: La configuración ya viene con capture_area_size del settings_panel
	if settings.has("capture_area_size"):
		var capture_area = settings.capture_area_size
		
		print("✅ capture_area_size encontrado: %.1f" % capture_area)
		
		# ✅ CRÍTICO: Convertir capture_area_size a camera_distance
		# Lógica: capture_area más pequeño = modelo más grande = cámara más cerca
		var camera_distance = capture_area * 2.0  # Factor de conversión
		settings["camera_distance"] = camera_distance
		
		# ✅ CRÍTICO: También configurar orthographic_size para cámaras ortográficas
		settings["orthographic_size"] = capture_area
		settings["manual_zoom_override"] = true
		settings["fixed_orthographic_size"] = capture_area
		
		print("🔄 Conversiones aplicadas:")
		print("  capture_area_size: %.1f → camera_distance: %.1f" % [capture_area, camera_distance])
		print("  orthographic_size: %.1f" % capture_area)
		
	else:
		# ✅ FALLBACK: Si no se encuentra capture_area_size, usar valores por defecto
		print("⚠️ capture_area_size NO encontrado, usando valores por defecto")
		settings["capture_area_size"] = 8.0
		settings["camera_distance"] = 16.0
		settings["orthographic_size"] = 8.0
		settings["manual_zoom_override"] = true
		settings["fixed_orthographic_size"] = 8.0
	
	# ✅ DEBUG: Mostrar configuración final
	print("📋 Configuración final para renderizado:")
	print("  sprite_size: %d" % settings.get("sprite_size", 128))
	print("  capture_area_size: %.1f" % settings.get("capture_area_size", 8.0))
	print("  camera_distance: %.1f" % settings.get("camera_distance", 16.0))
	print("  orthographic_size: %.1f" % settings.get("orthographic_size", 8.0))
	
	return settings

# ========================================================================
# ✅ FUNCIÓN CORREGIDA: CONFIGURACIÓN DE RENDERIZADO CON DEBUG EXTENDIDO
# ========================================================================

func _on_render_settings_changed(settings: Dictionary):
	"""Manejar cambios en configuración de renderizado - VERSIÓN CON DEBUG EXTENDIDO"""
	print("\n📡 === CONFIGURACIÓN RECIBIDA DESDE SETTINGS_PANEL ===")
	print("  directions: %d" % settings.get("directions", 16))
	print("  camera_height: %.1f" % settings.get("camera_height", 12.0))
	print("  camera_angle: %.1f°" % settings.get("camera_angle", 45.0))
	print("  sprite_size: %d" % settings.get("sprite_size", 128))
	print("  capture_area_size: %.1f" % settings.get("capture_area_size", 8.0))
	print("  north_offset: %.0f°" % settings.get("north_offset", 0.0))
	print("====================================================")

	# ✅ CRÍTICO: Convertir capture_area_size a configuración de cámara
	var enhanced_settings = settings.duplicate()
	
	if settings.has("capture_area_size"):
		var capture_area = settings.capture_area_size
		
		# Convertir a camera_distance
		enhanced_settings["camera_distance"] = capture_area * 2.0
		enhanced_settings["orthographic_size"] = capture_area
		enhanced_settings["manual_zoom_override"] = true
		enhanced_settings["fixed_orthographic_size"] = capture_area
		
		print("🔄 Parámetros de cámara calculados:")
		print("  camera_distance: %.1f" % enhanced_settings["camera_distance"])
		print("  orthographic_size: %.1f" % enhanced_settings["orthographic_size"])
	
	# 1. Enviar al Model Preview Panel (para preview en tiempo real)
	if model_preview_panel:
		var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
		if preview_camera and preview_camera.has_method("set_camera_settings"):
			preview_camera.set_camera_settings(enhanced_settings)
			print("✅ Configuración MEJORADA enviada al preview camera")
			
			if preview_camera.has_method("update_camera_position"):
				preview_camera.update_camera_position()
		else:
			print("❌ Preview camera controller no encontrado")
	
	# 2. Enviar al Sprite Renderer (para renderizado) - CON CONFIGURACIÓN MEJORADA
	if sprite_renderer:
		if sprite_renderer.has_method("initialize"):
			sprite_renderer.initialize(enhanced_settings)
			print("✅ Configuración MEJORADA enviada al sprite renderer")
		
		if sprite_renderer.has_method("update_render_settings"):
			sprite_renderer.update_render_settings(enhanced_settings)
			print("✅ Configuración MEJORADA actualizada en sprite renderer")
	
	# 3. Aplicar al pipeline - CON CONFIGURACIÓN MEJORADA
	if spritesheet_pipeline and spritesheet_pipeline.has_method("update_pipeline_settings"):
		spritesheet_pipeline.update_pipeline_settings(enhanced_settings)
		print("✅ Configuración MEJORADA enviada al pipeline")
	
	# 4. Guardar configuración actual - CON MEJORAS
	current_render_settings = enhanced_settings
	
	#log_panel.add_log("⚙️ Configuración actualizada - área: %.1f, distancia: %.1f" % [
		#enhanced_settings.get("capture_area_size", 8.0), 
		#enhanced_settings.get("camera_distance", 16.0)
	#])

# ========================================================================
# ✅ FUNCIÓN CORREGIDA: RENDERIZADO CON CONFIGURACIÓN MEJORADA
# ========================================================================

func _on_render_requested_with_capture_fix():
	"""✅ VERSIÓN CORREGIDA: Manejar renderizado con parámetros de área de captura MEJORADOS"""
	#print("\n🎨 === RENDERIZADO CON ÁREA DE CAPTURA CORREGIDA ===")
	#log_panel.add_log("🎨 Iniciando renderizado con área de captura corregida...")

	# Validar prerrequisitos
	if not current_combined_model or not is_instance_valid(current_combined_model):
		#log_panel.add_log("❌ No hay modelo válido para renderizar")
		if actions_panel:
			actions_panel.show_error("No hay modelo cargado")
		return

	if not spritesheet_pipeline:
		#log_panel.add_log("❌ Pipeline no disponible")
		if actions_panel:
			actions_panel.show_error("Pipeline no inicializado")
		return

	if spritesheet_pipeline.is_busy():
		#log_panel.add_log("⚠️ Pipeline ocupado")
		if actions_panel:
			actions_panel.show_error("Pipeline ocupado, espera a que termine")
		return

	# Obtener animación actual
	var current_anim = _get_current_animation_name()
	if current_anim == "":
		#log_panel.add_log("❌ No hay animación seleccionada")
		if actions_panel:
			actions_panel.show_error("Selecciona una animación")
		return

	# ✅ CORRECCIÓN: Obtener configuración con área de captura corregida
	var config = _get_current_render_settings_with_capture_area()
	
	# ✅ DEBUG EXTENDIDO: Mostrar configuración completa
	print("📋 Configuración final para pipeline:")
	print("  animation: %s" % current_anim)
	print("  sprite_size: %d" % config.get("sprite_size", 128))
	print("  capture_area_size: %.1f" % config.get("capture_area_size", 8.0))
	print("  camera_distance: %.1f" % config.get("camera_distance", 16.0))
	print("  orthographic_size: %.1f" % config.get("orthographic_size", 8.0))
	print("  camera_height: %.1f" % config.get("camera_height", 12.0))
	print("  camera_angle: %.1f°" % config.get("camera_angle", 45.0))
	print("  directions: %d" % config.get("directions", 16))

	# ✅ USAR PIPELINE con configuración corregida
	var success = spritesheet_pipeline.generate_spritesheet(current_anim, config)

	if not success:
		#log_panel.add_log("❌ No se pudo iniciar pipeline")
		if actions_panel:
			actions_panel.show_error("Error iniciando pipeline")
	else:
		pass
		#log_panel.add_log("✅ Pipeline iniciado con área: %.1f → distancia: %.1f" % [
			#config.get("capture_area_size", 8.0), 
			#config.get("camera_distance", 16.0)
		#])

# ========================================================================
# ✅ FUNCIÓN DE DEBUG: VERIFICAR CADENA DE PARÁMETROS
# ========================================================================

func debug_capture_area_chain():
	"""Debug completo de la cadena de parámetros de área de captura"""
	print("\n🔍 === DEBUG CADENA ÁREA DE CAPTURA ===")
	
	# 1. Verificar settings_panel
	if settings_panel and settings_panel.has_method("get_settings"):
		var panel_settings = settings_panel.get_settings()
		print("📋 SETTINGS_PANEL:")
		print("  capture_area_size: %s" % str(panel_settings.get("capture_area_size", "NO ENCONTRADO")))
		print("  manual_zoom_override: %s" % str(panel_settings.get("manual_zoom_override", "NO ENCONTRADO")))
		print("  fixed_orthographic_size: %s" % str(panel_settings.get("fixed_orthographic_size", "NO ENCONTRADO")))
	else:
		print("❌ settings_panel no disponible o no tiene get_settings()")
	
	# 2. Verificar current_render_settings
	print("\n📋 CURRENT_RENDER_SETTINGS:")
	if not current_render_settings.is_empty():
		print("  capture_area_size: %s" % str(current_render_settings.get("capture_area_size", "NO ENCONTRADO")))
		print("  camera_distance: %s" % str(current_render_settings.get("camera_distance", "NO ENCONTRADO")))
		print("  orthographic_size: %s" % str(current_render_settings.get("orthographic_size", "NO ENCONTRADO")))
	else:
		print("  current_render_settings está vacío")
	
	# 3. Verificar configuración final
	print("\n📋 CONFIGURACIÓN PROCESADA:")
	var processed_config = _get_current_render_settings_with_capture_area()
	print("  capture_area_size: %s" % str(processed_config.get("capture_area_size", "NO ENCONTRADO")))
	print("  camera_distance: %s" % str(processed_config.get("camera_distance", "NO ENCONTRADO")))
	print("  orthographic_size: %s" % str(processed_config.get("orthographic_size", "NO ENCONTRADO")))
	
	# 4. Verificar sprite_renderer
	if sprite_renderer:
		print("\n📋 SPRITE_RENDERER:")
		if sprite_renderer.has_method("get_render_settings"):
			var renderer_settings = sprite_renderer.get_render_settings()
			print("  render_settings disponibles: %s" % str(renderer_settings.keys() if renderer_settings else "NO DISPONIBLE"))
		else:
			print("  No tiene método get_render_settings()")
		
		# Verificar cámara del renderer
		if sprite_renderer.camera_controller:
			print("  camera_controller disponible: ✅")
			if sprite_renderer.camera_controller.has_method("get_current_settings"):
				var camera_settings = sprite_renderer.camera_controller.get_current_settings()
				print("  camera_distance actual: %s" % str(camera_settings.get("camera_distance", "NO ENCONTRADO")))
				print("  orthographic_size actual: %s" % str(camera_settings.get("orthographic_size", "NO ENCONTRADO")))
		else:
			print("  camera_controller: ❌")
	else:
		print("\n❌ sprite_renderer no disponible")
	
	print("==========================================\n")

# ========================================================================
# ✅ FUNCIÓN DE VALIDACIÓN: VERIFICAR QUE PREVIEW Y RENDER COINCIDAN
# ========================================================================

func validate_preview_render_consistency():
	"""Verificar que preview y renderizado usen la misma configuración"""
	print("\n🔍 === VALIDACIÓN CONSISTENCIA PREVIEW-RENDER ===")
	
	var preview_config = {}
	var render_config = {}
	
	# Obtener configuración del preview
	if model_preview_panel:
		var preview_camera = model_preview_panel.get_node_or_null("ViewportContainer/SubViewport/CameraController")
		if preview_camera and preview_camera.has_method("get_current_settings"):
			preview_config = preview_camera.get_current_settings()
	
	# Obtener configuración del renderer
	render_config = _get_current_render_settings_with_capture_area()
	
	# Comparar parámetros críticos
	var comparison_params = ["camera_distance", "orthographic_size", "camera_height", "camera_angle"]
	
	print("📊 COMPARACIÓN PREVIEW vs RENDER:")
	var all_match = true
	
	for param in comparison_params:
		var preview_val = preview_config.get(param, "NO DISPONIBLE")
		var render_val = render_config.get(param, "NO DISPONIBLE")
		
		var match_status = "✅" if preview_val == render_val else "❌"
		if preview_val != render_val:
			all_match = false
		
		print("  %s: Preview=%.2f, Render=%.2f %s" % [
			param, 
			float(str(preview_val)) if preview_val != "NO DISPONIBLE" else 0.0,
			float(str(render_val)) if render_val != "NO DISPONIBLE" else 0.0,
			match_status
		])
	
	print("\n📋 RESULTADO: %s" % ("✅ CONSISTENTE" if all_match else "❌ INCONSISTENTE"))
	print("=================================================\n")
	
	return all_match

func _get_current_animation_name() -> String:
	"""Obtener nombre de la animación actual - CORREGIDO PARA RENDERIZADO"""
	
	# ✅ MÉTODO 1: Usar get_current_animation() que SÍ existe
	if animation_controls_panel and animation_controls_panel.has_method("get_current_animation"):
		var current_anim = animation_controls_panel.get_current_animation()
		if current_anim != "":
			# ✅ CRÍTICO: Limpiar .fbx si existe
			if current_anim.ends_with(".fbx"):
				current_anim = current_anim.get_basename()
			print("🎯 Animación desde panel: %s" % current_anim)
			return current_anim
	
	# ✅ MÉTODO 2: Usar get_selected_animation() si existe (después de agregarlo)
	if animation_controls_panel and animation_controls_panel.has_method("get_selected_animation"):
		var selected_anim = animation_controls_panel.get_selected_animation()
		if selected_anim != "":
			# ✅ CRÍTICO: Limpiar .fbx para que AnimationPlayer lo encuentre
			if selected_anim.ends_with(".fbx"):
				selected_anim = selected_anim.get_basename()
			print("🎯 Animación seleccionada (limpia): %s" % selected_anim)
			return selected_anim
	
	# ✅ MÉTODO 3: Usar información de índice actual del panel
	if animation_controls_panel and animation_controls_panel.has_method("get_current_animation_index"):
		var current_index = animation_controls_panel.get_current_animation_index()
		if current_index >= 0:
			var available_anims = animation_controls_panel.get_available_animations()
			if current_index < available_anims.size():
				var selected_anim = available_anims[current_index]
				# ✅ CRÍTICO: Limpiar .fbx
				if selected_anim.ends_with(".fbx"):
					selected_anim = selected_anim.get_basename()
				print("🎯 Animación por índice %d (limpia): %s" % [current_index, selected_anim])
				return selected_anim
	
	# ✅ MÉTODO 4: Obtener de AnimationPlayer actualmente reproduciendo
	if current_combined_model and is_instance_valid(current_combined_model):
		var anim_player = _find_animation_player(current_combined_model)
		if anim_player and anim_player.is_playing():
			var playing_anim = anim_player.current_animation
			if playing_anim != "":
				print("🎯 Animación reproduciendo: %s" % playing_anim)
				return playing_anim
	
	# ❌ FALLBACK MEJORADO: Si todo falla, intentar obtener la primera disponible
	# PERO emitir una advertencia clara
	if current_combined_model and is_instance_valid(current_combined_model):
		var anim_player = _find_animation_player(current_combined_model)
		if anim_player and anim_player.get_animation_list().size() > 0:
			var first_anim = anim_player.get_animation_list()[0]
			print("⚠️ FALLBACK: Usando primera animación: %s" % first_anim)
			print("   Esto indica que no se detectó correctamente la animación seleccionada")
			return first_anim
	
	print("❌ No se pudo determinar animación actual")
	return ""
