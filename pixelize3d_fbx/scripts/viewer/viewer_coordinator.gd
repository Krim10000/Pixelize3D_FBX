# scripts/viewer/viewer_coordinator.gd
# Coordinador principal del visor modular - SOLO conecta señales entre componentes
# Input: Señales de componentes UI (selección de archivos, configuraciones, etc.)
# Output: Coordinación entre componentes, delegación al sistema de renderizado principal

extends Control

# Referencias a componentes existentes del sistema principal
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

# Variables para almacenar datos cargados temporalmente
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null

func _ready():
	_connect_ui_signals()
	_connect_system_signals()
	log_panel.add_log("✅ Coordinador inicializado - Todos los componentes conectados")
	
	# 🐛 DEBUG: Verificar fbx_loader
	print("🐛 DEBUG - FBXLoader encontrado: ", fbx_loader != null)
	if fbx_loader:
		print("🐛 DEBUG - FBXLoader señales: ", fbx_loader.get_signal_list())

func _connect_ui_signals():
	# Conectar señales entre paneles UI
	file_loader_panel.file_selected.connect(_on_file_selected)
	file_loader_panel.unit_selected.connect(_on_unit_selected)
	file_loader_panel.animations_selected.connect(_on_animations_selected)
	
	if settings_panel.has_signal("settings_changed"):
		settings_panel.settings_changed.connect(_on_settings_changed)
	
	if actions_panel.has_signal("preview_requested"):
		actions_panel.preview_requested.connect(_on_preview_requested)
	
	if actions_panel.has_signal("render_requested"):
		actions_panel.render_requested.connect(_on_render_requested)
	
	animation_controls_panel.animation_selected.connect(_on_animation_selected)
	animation_controls_panel.play_requested.connect(_on_play_requested)
	animation_controls_panel.stop_requested.connect(_on_stop_requested)

func _connect_system_signals():
	# 🐛 DEBUG: Verificar conexiones de señales
	print("🐛 DEBUG - Conectando señales del sistema...")
	
	if fbx_loader and fbx_loader.has_signal("model_loaded"):
		fbx_loader.model_loaded.connect(_on_model_loaded)
		print("🐛 DEBUG - Señal model_loaded conectada")
	else:
		print("🐛 ERROR - No se pudo conectar model_loaded")
	
	if fbx_loader and fbx_loader.has_signal("load_failed"):
		fbx_loader.load_failed.connect(_on_load_failed)
		print("🐛 DEBUG - Señal load_failed conectada")
	
	if sprite_renderer and sprite_renderer.has_signal("frame_rendered"):
		sprite_renderer.frame_rendered.connect(_on_frame_rendered)

# Funciones de coordinación para manejo de archivos
func _on_file_selected(file_path: String):
	log_panel.add_log("📁 Archivo seleccionado: " + file_path.get_file())
	_load_fbx_file(file_path)

func _on_unit_selected(unit_data: Dictionary):
	log_panel.add_log("📦 Unidad seleccionada: " + unit_data.name)
	# Limpiar datos previos al cambiar de unidad
	_clear_loaded_data()
	file_loader_panel.populate_unit_files(unit_data)

func _on_animations_selected(animation_files: Array):
	log_panel.add_log("🎬 Animaciones seleccionadas: " + str(animation_files))
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		if file_loader_panel.current_unit_data.has("path"):
			var full_path = file_loader_panel.current_unit_data.path + "/" + anim_file
			log_panel.add_log("📥 Cargando animación: " + anim_file)
			
			# 🐛 DEBUG: Verificar llamada a carga de animación
			print("🐛 DEBUG - Llamando load_animation_fbx: ", full_path)
			fbx_loader.load_animation_fbx(full_path, anim_file.get_basename())

# Funciones de coordinación para configuraciones
func _on_settings_changed(settings: Dictionary):
	log_panel.add_log("⚙️ Configuración actualizada")
	# Aplicar a cámara si es necesario
	if camera_controller.has_method("apply_settings"):
		camera_controller.apply_settings(settings)

# Funciones de coordinación para acciones
func _on_preview_requested():
	log_panel.add_log("🎬 Preview solicitado")
	if current_combined_model:
		model_preview_panel.enable_preview_mode()
	else:
		log_panel.add_log("❌ No hay modelo combinado disponible para preview")

func _on_render_requested():
	log_panel.add_log("🎨 Renderizado solicitado")
	# Delegar al sistema existente
	var selected_animations = file_loader_panel.get_selected_animations()
	var render_settings = settings_panel.get_settings() if settings_panel.has_method("get_settings") else {}
	
	if selected_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones seleccionadas")
		return
	
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base cargado")
		return
	
	_start_rendering(selected_animations, render_settings)

# Funciones de coordinación para controles de animación
func _on_animation_selected(animation_name: String):
	log_panel.add_log("🎭 Animación seleccionada: " + animation_name)

func _on_play_requested(animation_name: String):
	log_panel.add_log("▶️ Reproduciendo: " + animation_name)
	if model_preview_panel.has_method("play_animation"):
		model_preview_panel.play_animation(animation_name)

func _on_stop_requested():
	log_panel.add_log("⏹️ Animación detenida")
	if model_preview_panel.has_method("stop_animation"):
		model_preview_panel.stop_animation()

# 🐛 DEBUG: Función principal para manejo de modelos cargados con debugging extensivo
func _on_model_loaded(model_data: Dictionary):
	print("🐛 DEBUG - _on_model_loaded ejecutado!")
	print("🐛 DEBUG - Claves en model_data: ", model_data.keys())
	print("🐛 DEBUG - Contenido completo: ", model_data)
	
	# Intentar diferentes nombres de campos para file_type
	var file_type = "unknown"
	if model_data.has("file_type"):
		file_type = model_data.file_type
	elif model_data.has("type"):
		file_type = model_data.type
	elif model_data.has("kind"):
		file_type = model_data.kind
	
	var model_name = "unknown"
	if model_data.has("name"):
		model_name = model_data.name
	elif model_data.has("filename"):
		model_name = model_data.filename
	elif model_data.has("file_name"):
		model_name = model_data.file_name
	
	print("🐛 DEBUG - file_type detectado: ", file_type)
	print("🐛 DEBUG - model_name detectado: ", model_name)
	
	if file_type == "base":
		loaded_base_data = model_data
		log_panel.add_log("✅ Modelo base cargado: " + model_name)
		print("🐛 DEBUG - Modelo base almacenado")
		
	elif file_type == "animation":
		loaded_animations[model_name] = model_data
		log_panel.add_log("✅ Animación cargada: " + model_name)
		print("🐛 DEBUG - Animación almacenada: ", model_name)
	
	else:
		# Si no reconocemos el tipo, intentar detectar por contenido
		log_panel.add_log("⚠️ Tipo de archivo no reconocido: " + str(file_type))
		print("🐛 DEBUG - Tipo no reconocido, analizando contenido...")
		
		# Si tiene meshes, probablemente es base
		if model_data.has("meshes") and model_data.meshes.size() > 0:
			loaded_base_data = model_data
			log_panel.add_log("✅ Modelo base detectado por contenido: " + model_name)
		# Si solo tiene animaciones, probablemente es animación
		elif model_data.has("animation_player") or model_data.has("animations"):
			loaded_animations[model_name] = model_data
			log_panel.add_log("✅ Animación detectada por contenido: " + model_name)
	
	# Intentar combinación automática si tenemos base + al menos 1 animación
	print("🐛 DEBUG - Llamando _try_combine_and_preview...")
	_try_combine_and_preview()

func _on_load_failed(error_message: String):
	log_panel.add_log("❌ Error al cargar FBX: " + error_message)
	print("🐛 DEBUG - _on_load_failed ejecutado: ", error_message)

func _on_frame_rendered(frame_data: Dictionary):
	# El sistema existente ya maneja esto
	pass

# Función auxiliar para cargar archivos FBX con debugging
func _load_fbx_file(file_path: String):
	print("🐛 DEBUG - _load_fbx_file llamado con: ", file_path)
	
	# Determinar si es archivo base basándose en el nombre
	var filename = file_path.get_file().to_lower()
	var is_base_file = false
	
	# Heurística para determinar si es archivo base
	var base_keywords = ["base", "idle", "static", "t-pose", "tpose"]
	for keyword in base_keywords:
		if keyword in filename:
			is_base_file = true
			break
	
	# Si no se detecta como base, asumir que es base si no tenemos uno cargado
	if not is_base_file and loaded_base_data.is_empty():
		is_base_file = true
		log_panel.add_log("🔍 Asumiendo como modelo base (no hay base cargado)")
	
	print("🐛 DEBUG - Detectado como base: ", is_base_file)
	
	# Cargar según el tipo detectado
	if is_base_file:
		print("🐛 DEBUG - Llamando load_base_model...")
		fbx_loader.load_base_model(file_path)
	else:
		var anim_name = file_path.get_file().get_basename()
		print("🐛 DEBUG - Llamando load_animation_fbx con nombre: ", anim_name)
		fbx_loader.load_animation_fbx(file_path, anim_name)

# Función clave para combinar base + animaciones y mostrar preview
func _try_combine_and_preview():
	print("🐛 DEBUG - _try_combine_and_preview ejecutado")
	print("🐛 DEBUG - Base vacío: ", loaded_base_data.is_empty())
	print("🐛 DEBUG - Animaciones count: ", loaded_animations.size())
	
	# Verificar que tenemos los datos necesarios
	if loaded_base_data.is_empty():
		log_panel.add_log("⏳ Esperando modelo base...")
		return
	
	if loaded_animations.is_empty():
		log_panel.add_log("⏳ Esperando animaciones...")
		return
	
	log_panel.add_log("🔄 Combinando modelo base con animaciones...")
	print("🐛 DEBUG - Iniciando combinación...")
	
	# Limpiar modelo combinado anterior
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Obtener primera animación para la combinación inicial
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	log_panel.add_log("🎭 Combinando con: " + first_anim_name)
	print("🐛 DEBUG - Usando animación: ", first_anim_name)
	
	# Usar animation_manager para combinar
	current_combined_model = animation_manager.combine_base_with_animation(
		loaded_base_data, 
		first_anim_data
	)
	
	if current_combined_model:
		log_panel.add_log("✅ Modelo combinado exitosamente")
		print("🐛 DEBUG - Combinación exitosa, configurando preview...")
		
		# Configurar preview con modelo combinado
		if model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
			print("🐛 DEBUG - Modelo pasado a preview panel")
		
		# Poblar controles de animación con modelo combinado (que tiene AnimationPlayer)
		animation_controls_panel.populate_animations(current_combined_model)
		print("🐛 DEBUG - Controles de animación poblados")
		
		# Habilitar botón de preview en acciones
		if actions_panel.has_method("enable_preview_button"):
			actions_panel.enable_preview_button()
		
		log_panel.add_log("🎬 Preview listo para usar")
		
	else:
		log_panel.add_log("❌ Error al combinar modelo - revisa los logs de animation_manager")
		print("🐛 DEBUG - Error en combinación")

# Función para limpiar datos cargados
func _clear_loaded_data():
	loaded_base_data.clear()
	loaded_animations.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Resetear controles de animación
	animation_controls_panel.reset_controls()
	
	log_panel.add_log("🧹 Datos de modelos limpiados")

# Función para delegar renderizado al sistema principal
func _start_rendering(animations: Array, settings: Dictionary):
	log_panel.add_log("🚀 Iniciando renderizado de %d animaciones" % animations.size())
	
	# Esta función debe conectar con tu sistema de renderizado principal (main.gd)
	# Por ahora solo registra la solicitud
	log_panel.add_log("📝 Datos de renderizado:")
	log_panel.add_log("  • Base: " + loaded_base_data.get("name", "desconocido"))
	log_panel.add_log("  • Animaciones: " + str(animations))
	log_panel.add_log("  • Configuración: " + str(settings.keys()))
	
	# TODO: Aquí conectarías con tu main.gd existente o sprite_renderer
	# Ejemplo: get_tree().call_group("main_system", "start_batch_rendering", loaded_base_data, loaded_animations, settings)

# Función para obtener estado actual (útil para debugging)
func get_current_state() -> Dictionary:
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_loaded": loaded_animations.size(),
		"combined_model_ready": current_combined_model != null,
		"animation_names": loaded_animations.keys()
	}
