# scripts/viewer/viewer_coordinator.gd
# Coordinador principal - SOLO conecta señales entre componentes
# Input: Señales de componentes UI
# Output: Coordinación entre componentes, NO lógica de negocio

extends Control

# Referencias a componentes existentes
@onready var fbx_loader = $FBXLoader
@onready var animation_manager = $AnimationManager
@onready var sprite_renderer = $SpriteRenderer
@onready var camera_controller = $HSplitContainer/RightPanel/ModelPreviewPanel/ViewportContainer/SubViewport/CameraController

# Referencias a paneles UI especializados
@onready var file_loader_panel = $HSplitContainer/LeftPanel/VBoxContainer/FileLoaderPanel
@onready var settings_panel = $HSplitContainer/LeftPanel/VBoxContainer/SettingsPanel
@onready var actions_panel = $HSplitContainer/LeftPanel/VBoxContainer/ActionsPanel
@onready var model_preview_panel = $HSplitContainer/RightPanel/ModelPreviewPanel
@onready var animation_controls_panel = $HSplitContainer/RightPanel/AnimationControlsPanel
@onready var log_panel = $HSplitContainer/RightPanel/LogPanel

func _ready():
	_connect_ui_signals()
	_connect_system_signals()
	log_panel.add_log("✅ Coordinador inicializado - Todos los componentes conectados")

func _connect_ui_signals():
	# Conectar señales entre paneles UI
	file_loader_panel.file_selected.connect(_on_file_selected)
	file_loader_panel.unit_selected.connect(_on_unit_selected)
	
	settings_panel.settings_changed.connect(_on_settings_changed)
	
	actions_panel.preview_requested.connect(_on_preview_requested)
	actions_panel.render_requested.connect(_on_render_requested)
	
	animation_controls_panel.animation_selected.connect(_on_animation_selected)
	animation_controls_panel.play_requested.connect(_on_play_requested)
	animation_controls_panel.stop_requested.connect(_on_stop_requested)

func _connect_system_signals():
	# Conectar con componentes del sistema existente
	if fbx_loader.has_signal("model_loaded"):
		fbx_loader.model_loaded.connect(_on_model_loaded)
	
	if sprite_renderer.has_signal("frame_rendered"):
		sprite_renderer.frame_rendered.connect(_on_frame_rendered)

# Funciones de coordinación - NO lógica de negocio
func _on_file_selected(file_path: String):
	log_panel.add_log("📁 Archivo seleccionado: " + file_path.get_file())
	_load_fbx_file(file_path)

func _on_unit_selected(unit_data: Dictionary):
	log_panel.add_log("📦 Unidad seleccionada: " + unit_data.name)
	file_loader_panel.populate_unit_files(unit_data)

func _on_settings_changed(settings: Dictionary):
	log_panel.add_log("⚙️ Configuración actualizada")
	# Aplicar a cámara si es necesario
	if camera_controller.has_method("apply_settings"):
		camera_controller.apply_settings(settings)

func _on_preview_requested():
	log_panel.add_log("🎬 Preview solicitado")
	model_preview_panel.enable_preview_mode()

func _on_render_requested():
	log_panel.add_log("🎨 Renderizado solicitado")
	# Delegar al sistema existente
	var selected_animations = file_loader_panel.get_selected_animations()
	var render_settings = settings_panel.get_settings()
	
	if selected_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones seleccionadas")
		return
	
	_start_rendering(selected_animations, render_settings)

func _on_animation_selected(animation_name: String):
	log_panel.add_log("🎭 Animación seleccionada: " + animation_name)

func _on_play_requested(animation_name: String):
	log_panel.add_log("▶️ Reproduciendo: " + animation_name)
	model_preview_panel.play_animation(animation_name)

func _on_stop_requested():
	log_panel.add_log("⏹️ Animación detenida")
	model_preview_panel.stop_animation()

func _on_model_loaded(model_data: Dictionary):
	log_panel.add_log("✅ Modelo cargado exitosamente")
	
	# Pasar modelo a preview
	if model_data.has("model"):
		model_preview_panel.set_model(model_data.model)
		animation_controls_panel.populate_animations(model_data.model)
		actions_panel.enable_preview_button()

func _on_frame_rendered(frame_data: Dictionary):
	# El sistema existente ya maneja esto
	pass

# Funciones de delegación al sistema existente
func _load_fbx_file(file_path: String):
	# Usar FBXLoader existente
	var model_scene = await fbx_loader._load_fbx_file(file_path,"base")
	
	if model_scene:
		var model = model_scene.instantiate()
		
		# Usar AnimationManager existente si es necesario
		if animation_manager.has_method("process_model"):
			model = animation_manager.process_model(model)
		
		_on_model_loaded({"model": model, "scene": model_scene})
	else:
		log_panel.add_log("❌ Error al cargar FBX")

func _start_rendering(animations: Array, settings: Dictionary):
	# Delegar al sistema de renderizado existente
	log_panel.add_log("🚀 Iniciando renderizado de %d animaciones" % animations.size())
	
	# Aquí conectarías con tu main.gd existente o sprite_renderer
	# Este coordinador NO implementa la lógica de renderizado
