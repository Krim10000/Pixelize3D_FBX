# pixelize3d_fbx/scripts/transition/transition_4cols_coordinator.gd
# Coordinador central del sistema de transiciones con 4 columnas
# Input: Coordinación de información entre las 4 columnas
# Output: Sincronización de estado y datos entre todas las columnas

extends Control
class_name Transition4ColsCoordinator

# === SEÑALES PARA COORDINACIÓN ENTRE COLUMNAS ===
# Columna 1 -> otras columnas
signal base_model_loaded(model_data: Dictionary)
signal animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary)
signal preview_requested()

# Columna 2 -> otras columnas  
signal preview_configs_changed(anim_a_config: Dictionary, anim_b_config: Dictionary)
signal preview_ready(preview_data: Dictionary)

# Columna 3 -> otras columnas
signal transition_config_changed(config: Dictionary) 
signal generate_transition_requested()

# Columna 4 -> sistema
signal transition_generated(output_path: String)
signal spritesheet_generated(output_path: String)

# === REFERENCIAS A LAS 4 COLUMNAS ===
var columna1_logic: Node  # Lógica de carga
var columna1_ui: Control  # UI de carga
var columna2_logic: Node  # Lógica de preview animaciones
var columna2_ui: Control  # UI de preview animaciones
var columna3_logic: Node  # Lógica de config transición
var columna3_ui: Control  # UI de config transición
var columna4_logic: Node  # Lógica de preview final (pendiente)
var columna4_ui: Control  # UI de preview final (pendiente)

# === ESTADO GLOBAL DEL SISTEMA ===
var system_state: Dictionary = {
	"base_loaded": false,
	"animations_loaded": false,
	"preview_ready": false,
	"transition_config_valid": false,
	"transition_generated": false
}

# === DATOS COMPARTIDOS ===
var shared_data: Dictionary = {
	"base_model": {},
	"animation_a": {},
	"animation_b": {},
	"preview_configs": {},
	"transition_config": {},
	"generated_transition": {}
}

func _ready():
	print("Transition4ColsCoordinator inicializando...")
	_setup_4cols_layout()
	_initialize_columns()
	_connect_coordination_signals()
	_show_startup_info()
	_connect_column1_to_column2()
	print("Coordinador de 4 columnas listo")


func _connect_column1_to_column2():
	"""Conectar flujo de datos entre columnas"""
	var col1_logic = get_node("Columna1_Logic")
	var col2_logic = get_node("Columna2_Logic")
	var col2_ui = get_node("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI")
	
	if col1_logic and col2_logic:
		# Cuando Columna1 tenga las animaciones listas
		col1_logic.animations_ready.connect(_on_animations_ready)
	
	if col2_logic and col2_ui:
		# Conectar lógica con UI de Columna2
		col2_logic.playback_state_changed.connect(col2_ui.on_playback_state_changed)

func _on_animations_ready(anim_a_data: Dictionary, anim_b_data: Dictionary):
	"""Cuando las animaciones están listas, enviarlas a Columna2 Y Columna3"""
	print("=== _on_animations_ready EJECUTANDOSE ===")
	print("  anim_a_data keys: %s" % str(anim_a_data.keys()))
	print("  anim_b_data keys: %s" % str(anim_b_data.keys()))
	print("  shared_data.base_model keys: %s" % str(shared_data.base_model.keys()))
	
	var col2_logic = get_node("Columna2_Logic")
	if col2_logic:
		col2_logic.load_animations_data(shared_data.base_model, anim_a_data, anim_b_data)
	
	# FIXME: Si shared_data.base_model está vacío, buscar base_model desde Columna1
	var base_model_data = shared_data.base_model
	if base_model_data.is_empty() and columna1_logic and columna1_logic.has_method("get_loaded_data"):
		print("⚠️ shared_data.base_model vacío, obteniendo desde Columna1...")
		var loaded_data = columna1_logic.get_loaded_data()
		base_model_data = loaded_data.get("base", {})
		print("  Base data desde Columna1: %s" % str(base_model_data.keys()))
	
	# Enviar datos a Columna 3 (incluyendo modelo base)
	if columna3_logic and columna3_logic.has_method("load_skeleton_data"):
		print("Enviando datos de esqueletos a Columna 3...")
		print("  Base model keys: %s" % str(base_model_data.keys()))
		columna3_logic.load_skeleton_data(base_model_data, anim_a_data, anim_b_data)
		print("✅ Datos enviados a Columna 3")
	else:
		print("❌ Columna3_logic no disponible o sin método load_skeleton_data")
		if not columna3_logic:
			print("  columna3_logic es null")
		elif not columna3_logic.has_method("load_skeleton_data"):
			print("  columna3_logic no tiene método load_skeleton_data")
	
	print("=== _on_animations_ready COMPLETADO ===\n")

func _show_startup_info():
	"""Mostrar información de inicio con controles de debug"""
	print("\n=== COORDINADOR 4 COLUMNAS INICIADO ===")
	print("Sistema de Transiciones v2.0 - 4 Columnas")
	print("Columna 1: ✅ Carga funcional")
	print("Columna 2: ✅ Preview animaciones FUNCIONAL")
	print("Columna 3: ✅ Config transición FUNCIONAL")
	print("Columna 4: ⏳ Preview final (próximamente)")
	print("\nControles de debug:")
	print("  F5 - Estado del sistema")
	print("  F6 - Debug Columna 1")
	print("  F7 - Debug Columna 2")
	print("  F8 - Debug coordinador")
	print("  F9 - Debug Columna 3")
	print("===============================================\n")

func _input(event):
	"""Manejar teclas de debug"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				debug_system_state()
			KEY_F6:
				_debug_column1_systems()
			KEY_F7:
				_debug_column2_systems()
			KEY_F8:
				debug_coordinator_state()
			KEY_F9:
				_debug_column3_systems()

# ========================================================================
# CONFIGURACIÓN DEL LAYOUT DE 4 COLUMNAS
# ========================================================================

func _setup_4cols_layout():
	"""Configurar layout de 4 columnas verificando estructura existente"""
	print("Configurando layout de 4 columnas...")
	
	# Verificar estructura básica
	var main_hsplit = get_node_or_null("HSplitContainer")
	if not main_hsplit:
		print("Error: HSplitContainer principal no encontrado")
		return
	
	print("Estructura de 4 columnas verificada")

func _initialize_columns():
	"""Inicializar las 4 columnas del sistema"""
	print("Inicializando las 4 columnas...")
	
	# Columna 1: Sistema de carga
	_initialize_column1()
	
	# Columna 2: Preview de animaciones
	_initialize_column2()
	
	# Columna 3: Configuración de transiciones
	_initialize_column3()
	
	# Columna 4: Solo verificar placeholder
	_verify_column4_placeholder()
	
	print("Inicialización de columnas completada")

func _initialize_column1():
	"""Inicializar Columna 1 - Sistema de carga"""
	print("Inicializando Columna 1 desde escena existente...")
	
	# Buscar Columna1_Logic existente en la escena
	columna1_logic = get_node_or_null("Columna1_Logic")
	if not columna1_logic:
		# Si no existe, crear uno nuevo
		columna1_logic = preload("res://scripts/transition/Columna1_logic.gd").new()
		columna1_logic.name = "Columna1_Logic"
		add_child(columna1_logic)
		print("Columna1_Logic creado dinámicamente")
	else:
		print("Columna1_Logic encontrado en escena")
	
	# Buscar Columna1_UI existente en la escena
	columna1_ui = get_node_or_null("HSplitContainer/Columna1_Container/Columna1_UI")
	if not columna1_ui:
		# Si no existe, crear uno nuevo
		var col1_container = get_node("HSplitContainer/Columna1_Container")
		columna1_ui = preload("res://scripts/transition/Columna1_UI.gd").new()
		columna1_ui.name = "Columna1_UI"
		col1_container.add_child(columna1_ui)
		print("Columna1_UI creado dinámicamente")
	else:
		print("Columna1_UI encontrado en escena")
	
	# Conectar lógica y UI de Columna 1
	_connect_column1_signals()
	
	print("Columna 1 inicializada usando escena existente")

func _initialize_column2():
	"""Inicializar Columna 2 - SIN CARGA DE ARCHIVOS"""
	print("Inicializando Columna 2 (buscando instancia existente)...")
	
	# Buscar instancia existente en la escena por métodos característicos
	var root = get_tree().current_scene
	#columna2_logic = _find_existing_columna2_logic(root)
	columna2_logic = get_node("Columna2_Logic")
	print("columna2_logic")
	print(columna2_logic)
	
	
	if columna2_logic:
		print("Columna2_Logic REUTILIZADO desde escena: %s" % columna2_logic.get_path())
	else:
		print("ERROR: No se encontró instancia existente de Columna2_Logic")
		print("Creando nueva instancia directamente...")
		# Crear directamente desde la clase (sin cargar archivo)
		columna2_logic = Columna2Logic.new()
		columna2_logic.name = "Columna2_Logic_Created"
		add_child(columna2_logic)
		print("Columna2_Logic creado directamente desde clase")
	
	# Buscar UI existente
	var possible_ui_paths = [
		"HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI",
		"HSplitContainer/Columna2_Container/Columna2_UI",
		"Columna2_Container/Columna2_UI"
	]
	
	for path in possible_ui_paths:
		columna2_ui = get_node_or_null(path)
		if columna2_ui:
			print("Columna2_UI encontrado en: %s" % path)
			break
	
	if not columna2_ui:
		print("ERROR: Columna2_UI no encontrado - creando nuevo")
		var container = get_node_or_null("HSplitContainer/HSplitContainer/Columna2_Container")
		if container:
			columna2_ui = Columna2UI.new()
			columna2_ui.name = "Columna2_UI_Created"
			container.add_child(columna2_ui)
			print("Columna2_UI creado directamente")
		else:
			print("ERROR: Contenedor no encontrado")
			return
	
	# Conectar señales
	_connect_column2_signals()
	print("Columna 2 inicializada (método directo)")

func _initialize_column3():
	"""Inicializar Columna 3 - Configuración de transiciones"""
	print("⚙️ Inicializando Columna 3...")
	
	# PREVENIR INICIALIZACIÓN DUPLICADA
	if columna3_logic != null or columna3_ui != null:
		print("⚠️ Columna 3 ya inicializada - evitando duplicación")
		print("  columna3_logic existe: %s" % ("SI" if columna3_logic else "NO"))
		print("  columna3_ui existe: %s" % ("SI" if columna3_ui else "NO"))
		return
	
	# Debug inicial
	print("DEBUG _initialize_column3:")
	print("  columna3_logic antes: %s" % ("EXISTS" if columna3_logic else "NULL"))
	print("  columna3_ui antes: %s" % ("EXISTS" if columna3_ui else "NULL"))
	
	# Crear Columna3_Logic
	print("Intentando cargar Columna3_Logic.gd...")
	var columna3_logic_script = load("res://scripts/transition/Columna3_Logic.gd")
	if columna3_logic_script:
		print("✅ Script Columna3_Logic.gd cargado exitosamente")
		columna3_logic = columna3_logic_script.new()
		columna3_logic.name = "Columna3_Logic"
		add_child(columna3_logic)
		print("✅ Columna3_Logic creado dinámicamente: %s" % columna3_logic.get_path())
	else:
		print("❌ Error: No se pudo cargar Columna3_Logic.gd")
		print("  Ruta esperada: res://scripts/transition/Columna3_Logic.gd")
		return
	
	# Buscar contenedor de Columna 3
	print("Buscando contenedor de Columna 3...")
	var col3_container = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container")
	if not col3_container:
		print("❌ Error: Contenedor Columna3 no encontrado")
		print("  Ruta esperada: HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container")
		return
	else:
		print("✅ Contenedor encontrado: %s" % col3_container.get_path())
		print("  Hijos actuales: %d" % col3_container.get_child_count())
	
	# Verificar si ya hay UI en el contenedor
	var existing_ui = null
	for child in col3_container.get_children():
		if child.name == "Columna3_UI":
			existing_ui = child
			break
	
	if existing_ui:
		print("⚠️ Ya existe Columna3_UI - removiendo duplicado")
		existing_ui.queue_free()
	
	# Remover placeholder label si existe
	print("Removiendo placeholders existentes...")
	var removed_count = 0
	for child in col3_container.get_children():
		if child is Label:
			print("  Removiendo Label: %s" % child.name)
			child.queue_free()
			removed_count += 1
	print("  Placeholders removidos: %d" % removed_count)
	
	# Crear Columna3_UI
	print("Intentando cargar Columna3_UI.gd...")
	var columna3_ui_script = load("res://scripts/transition/Columna3_UI.gd")
	if columna3_ui_script:
		print("✅ Script Columna3_UI.gd cargado exitosamente")
		columna3_ui = columna3_ui_script.new()
		columna3_ui.name = "Columna3_UI"
		col3_container.add_child(columna3_ui)
		print("✅ Columna3_UI creado dinámicamente: %s" % columna3_ui.get_path())
	else:
		print("❌ Error: No se pudo cargar Columna3_UI.gd")
		print("  Ruta esperada: res://scripts/transition/Columna3_UI.gd")
		return
	
	# Conectar señales
	print("Conectando señales de Columna 3...")
	_connect_column3_signals()
	
	# Debug final
	print("DEBUG _initialize_column3 FINAL:")
#	print("  columna3_logic después: %s (%s)" % ("EXISTS" if columna3_logic else "NULL"), (columna3_logic.get_path() if columna3_logic else "N/A"))
	#print("  columna3_ui después: %s (%s)" % ("EXISTS" if columna3_ui else "NULL"), (columna3_ui.get_path() if columna3_ui else "N/A"))
	
	print("✅ Columna 3 inicializada completamente")

func _verify_column4_placeholder():
	"""Solo verificar que el placeholder de Columna 4 exista"""
	var col4_container = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer/Columna4_Container")
	
	if col4_container:
		print("✅ Container Columna 4 verificado: %s" % col4_container.name)
	else:
		print("❌ Container Columna 4 no encontrado")

# ========================================================================
# CONEXIÓN DE SEÑALES - COLUMNA 1
# ========================================================================

func _connect_column1_signals():
	"""Conectar señales entre lógica y UI de Columna 1"""
	if not columna1_logic or not columna1_ui:
		print("Error: columna1_logic o columna1_ui no inicializados")
		return
	
	# UI -> Logic
	columna1_ui.base_load_requested.connect(_on_col1_base_load_requested)
	columna1_ui.animation_a_load_requested.connect(_on_col1_animation_a_load_requested)
	columna1_ui.animation_b_load_requested.connect(_on_col1_animation_b_load_requested)
	columna1_ui.preview_requested.connect(_on_col1_preview_requested)
	
	# Logic -> UI
	columna1_logic.base_loaded.connect(_on_col1_base_loaded)
	columna1_logic.animation_loaded.connect(_on_col1_animation_loaded)
	columna1_logic.loading_failed.connect(_on_col1_loading_failed)
	
	# Logic -> Coordinator (señales globales)
	columna1_logic.base_loaded.connect(_on_base_model_loaded)
	columna1_logic.animations_ready.connect(_on_animations_loaded)
	
	print("Señales de Columna 1 conectadas")

# ========================================================================
# CONEXIÓN DE SEÑALES - COLUMNA 2 VERSIÓN SIMPLIFICADA
# ========================================================================

func _connect_column2_signals():
	"""Conectar señales entre lógica y UI de Columna 2 - VERSIÓN SIMPLIFICADA"""
	if not columna2_logic or not columna2_ui:
		print("Error: columna2_logic o columna2_ui no inicializados")
		return
	
	# UI -> Logic (controles de reproducción) - CON VERIFICACIÓN
	if columna2_ui.has_signal("play_animation_a_requested"):
		columna2_ui.play_animation_a_requested.connect(_on_col2_play_a_requested)
		print("Señal play_animation_a_requested conectada")
	
	if columna2_ui.has_signal("pause_animation_a_requested"):
		columna2_ui.pause_animation_a_requested.connect(_on_col2_pause_a_requested)
		print("Señal pause_animation_a_requested conectada")
	
	if columna2_ui.has_signal("play_animation_b_requested"):
		columna2_ui.play_animation_b_requested.connect(_on_col2_play_b_requested)
		print("Señal play_animation_b_requested conectada")
	
	if columna2_ui.has_signal("pause_animation_b_requested"):
		columna2_ui.pause_animation_b_requested.connect(_on_col2_pause_b_requested)
		print("Señal pause_animation_b_requested conectada")
	
	if columna2_ui.has_signal("animation_speed_a_changed"):
		columna2_ui.animation_speed_a_changed.connect(_on_col2_speed_a_changed)
		print("Señal animation_speed_a_changed conectada")
	
	if columna2_ui.has_signal("animation_speed_b_changed"):
		columna2_ui.animation_speed_b_changed.connect(_on_col2_speed_b_changed)
		print("Señal animation_speed_b_changed conectada")
	
	# Logic -> UI (estados de reproducción) - CONEXIÓN ROBUSTA
	if columna2_logic.has_signal("playback_state_changed"):
		columna2_logic.playback_state_changed.connect(_on_col2_playback_state_changed)
		print("Señal playback_state_changed conectada")
	else:
		print("Advertencia: Señal playback_state_changed no encontrada en Columna2_logic")
	
	# Logic -> Coordinator (señales globales) - CONEXIÓN ROBUSTA
	if columna2_logic.has_signal("preview_ready"):
		columna2_logic.preview_ready.connect(_on_preview_ready)
		print("Señal preview_ready conectada")
	else:
		print("Advertencia: Señal preview_ready no encontrada")
	
	print("Señales de Columna 2 conectadas (versión simplificada)")

# ========================================================================
# CONEXIÓN DE SEÑALES - COLUMNA 3
# ========================================================================

func _connect_column3_signals():
	"""Conectar señales entre lógica y UI de Columna 3"""
	print("Conectando señales de Columna 3...")
	
	if not columna3_logic or not columna3_ui:
		print("❌ Error: columna3_logic o columna3_ui no inicializados")
		print("  columna3_logic: %s" % ("EXISTS" if columna3_logic else "NULL"))
		print("  columna3_ui: %s" % ("EXISTS" if columna3_ui else "NULL"))
		return
	
	print("✅ Ambos componentes disponibles, conectando...")
	
	# UI -> Logic
	columna3_ui.duration_changed.connect(_on_col3_duration_changed)
	print("  ✓ duration_changed conectada")
	
	columna3_ui.frames_changed.connect(_on_col3_frames_changed)
	print("  ✓ frames_changed conectada")
	
	columna3_ui.interpolation_changed.connect(_on_col3_interpolation_changed)
	print("  ✓ interpolation_changed conectada")
	
	columna3_ui.reset_requested.connect(_on_col3_reset_requested)
	print("  ✓ reset_requested conectada")
	
	columna3_ui.generate_requested.connect(_on_col3_generate_requested)
	print("  ✓ generate_requested conectada")
	
	# Logic -> UI
	columna3_logic.config_updated.connect(_on_col3_config_updated)
	print("  ✓ config_updated conectada")
	
	columna3_logic.skeleton_info_ready.connect(_on_col3_skeleton_info_ready)
	print("  ✓ skeleton_info_ready conectada")
	
	# Logic -> Coordinator (señales globales)
	columna3_logic.transition_config_changed.connect(_on_transition_config_changed)
	print("  ✓ transition_config_changed conectada")
	
	columna3_logic.generate_transition_requested.connect(_on_generate_transition_requested)
	print("  ✓ generate_transition_requested conectada")
	
	print("✅ Todas las señales de Columna 3 conectadas exitosamente")

func _connect_coordination_signals():
	"""Conectar señales de coordinación entre columnas"""
	print("Conectando señales de coordinación...")
	
	# Columna 1 -> Columna 2: Cuando se cargan animaciones, notificar a Columna 2
	animations_loaded.connect(_on_notify_column2_animations_loaded)
	
	print("Señales de coordinación conectadas")

# ========================================================================
# MANEJADORES DE COLUMNA 1
# ========================================================================

func _on_col1_base_load_requested(file_path: String):
	"""Manejar solicitud de carga de modelo base desde UI"""
	print("Coordinador: Solicitud de carga de base - %s" % file_path)
	if columna1_logic and columna1_logic.has_method("load_base_model"):
		columna1_logic.load_base_model(file_path)

func _on_col1_animation_a_load_requested(file_path: String):
	"""Manejar solicitud de carga de animación A desde UI"""
	print("Coordinador: Solicitud de carga de animación A - %s" % file_path)
	if columna1_logic and columna1_logic.has_method("load_animation_a"):
		columna1_logic.load_animation_a(file_path)

func _on_col1_animation_b_load_requested(file_path: String):
	"""Manejar solicitud de carga de animación B desde UI"""
	print("Coordinador: Solicitud de carga de animación B - %s" % file_path)
	if columna1_logic and columna1_logic.has_method("load_animation_b"):
		columna1_logic.load_animation_b(file_path)

func _on_col1_preview_requested():
	"""Manejar solicitud de preview desde Columna 1"""
	print("Coordinador: Preview solicitado desde Columna 1")
	emit_signal("preview_requested")

func _on_col1_base_loaded(model_data: Dictionary):
	"""Manejar confirmación de carga de base desde lógica"""
	print("Coordinador: Base cargada confirmada")
	if columna1_ui and columna1_ui.has_method("on_base_loaded"):
		columna1_ui.on_base_loaded(model_data)

func _on_col1_animation_loaded(animation_data: Dictionary):
	"""Manejar confirmación de carga de animación desde lógica"""
	print("Coordinador: Animación cargada confirmada - %s" % animation_data.get("name", "Unknown"))
	if columna1_ui and columna1_ui.has_method("on_animation_loaded"):
		columna1_ui.on_animation_loaded(animation_data)

func _on_col1_loading_failed(error_message: String):
	"""Manejar error de carga desde lógica"""
	print("Coordinador: Error de carga - %s" % error_message)
	if columna1_ui and columna1_ui.has_method("on_loading_failed"):
		columna1_ui.on_loading_failed(error_message)

# ========================================================================
# MANEJADORES DE COLUMNA 2 - VERSIÓN SIMPLIFICADA
# ========================================================================

func _on_col2_play_a_requested():
	"""Manejar solicitud de reproducir animación A"""
	print("Coordinador: Play animación A solicitado")
	if columna2_logic and columna2_logic.has_method("play_animation_a"):
		columna2_logic.play_animation_a()

func _on_col2_pause_a_requested():
	"""Manejar solicitud de pausar animación A"""
	print("Coordinador: Pause animación A solicitado")
	if columna2_logic and columna2_logic.has_method("pause_animation_a"):
		columna2_logic.pause_animation_a()

func _on_col2_play_b_requested():
	"""Manejar solicitud de reproducir animación B"""
	print("Coordinador: Play animación B solicitado")
	if columna2_logic and columna2_logic.has_method("play_animation_b"):
		columna2_logic.play_animation_b()

func _on_col2_pause_b_requested():
	"""Manejar solicitud de pausar animación B"""
	print("Coordinador: Pause animación B solicitado")
	if columna2_logic and columna2_logic.has_method("pause_animation_b"):
		columna2_logic.pause_animation_b()

func _on_col2_speed_a_changed(speed: float):
	"""Manejar cambio de velocidad de animación A - VERSIÓN SIMPLIFICADA"""
	print("Coordinador: Velocidad A cambiada a %.2fx" % speed)
	if columna2_logic and columna2_logic.has_method("set_animation_speed"):
		columna2_logic.set_animation_speed("animation_a", speed)

func _on_col2_speed_b_changed(speed: float):
	"""Manejar cambio de velocidad de animación B - VERSIÓN SIMPLIFICADA"""
	print("Coordinador: Velocidad B cambiada a %.2fx" % speed)
	if columna2_logic and columna2_logic.has_method("set_animation_speed"):
		columna2_logic.set_animation_speed("animation_b", speed)

func _on_col2_playback_state_changed(animation_type: String, state: Dictionary):
	"""Manejar cambio de estado de reproducción desde lógica"""
	#print("Coordinador: Estado de %s cambiado" % animation_type)
	if columna2_ui and columna2_ui.has_method("on_playback_state_changed"):
		columna2_ui.on_playback_state_changed(animation_type, state)

# ========================================================================
# MANEJADORES DE COLUMNA 3
# ========================================================================

func _on_col3_duration_changed(duration: float):
	"""Manejar cambio de duración desde UI"""
	print("Coordinador: Duración cambiada a %.2fs" % duration)
	if columna3_logic and columna3_logic.has_method("set_duration"):
		columna3_logic.set_duration(duration)

func _on_col3_frames_changed(frames: int):
	"""Manejar cambio de frames desde UI"""
	print("Coordinador: Frames cambiados a %d" % frames)
	if columna3_logic and columna3_logic.has_method("set_frames"):
		columna3_logic.set_frames(frames)

func _on_col3_interpolation_changed(interpolation_type: String):
	"""Manejar cambio de interpolación desde UI"""
	print("Coordinador: Interpolación cambiada a %s" % interpolation_type)
	if columna3_logic and columna3_logic.has_method("set_interpolation"):
		columna3_logic.set_interpolation(interpolation_type)

func _on_col3_reset_requested():
	"""Manejar solicitud de reset desde UI"""
	print("Coordinador: Reset de configuración solicitado")
	if columna3_logic and columna3_logic.has_method("reset_to_defaults"):
		columna3_logic.reset_to_defaults()

func _on_col3_generate_requested():
	"""Manejar solicitud de generación desde UI"""
	print("=== SOLICITUD DE GENERACIÓN DESDE COLUMNA 3 ===")
	print("Coordinador: Generación de transición solicitada")
	
	if not columna3_logic:
		print("❌ columna3_logic es NULL")
		return
	
	if not columna3_logic.has_method("request_generate_transition"):
		print("❌ columna3_logic no tiene método request_generate_transition")
		return
	
	print("✅ Llamando request_generate_transition en Columna3_Logic...")
	var result = columna3_logic.request_generate_transition()
	print("  Resultado: %s" % str(result))
	print("=== FIN SOLICITUD DE GENERACIÓN ===\n")

func _on_col3_config_updated(config: Dictionary):
	"""Manejar actualización de configuración desde lógica"""
	print("Coordinador: Configuración actualizada")
	if columna3_ui and columna3_ui.has_method("on_config_updated"):
		columna3_ui.on_config_updated(config)

func _on_col3_skeleton_info_ready(info: Dictionary):
	"""Manejar información de esqueletos lista"""
	print("Coordinador: Información de esqueletos lista")
	if columna3_ui and columna3_ui.has_method("on_skeleton_info_ready"):
		columna3_ui.on_skeleton_info_ready(info)

# ========================================================================
# MANEJADORES DE COORDINACIÓN GLOBAL
# ========================================================================

func _on_base_model_loaded(model_data: Dictionary):
	"""Manejar carga completa del modelo base (señal global)"""
	print("Coordinador Global: Modelo base cargado")
	system_state.base_loaded = true
	shared_data.base_model = model_data
	
	# Notificar a otras columnas
	emit_signal("base_model_loaded", model_data)
	
	_update_system_state()

func _on_animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary):
	"""Manejar carga completa de animaciones (señal global)"""
	print("Coordinador Global: Animaciones cargadas")
	
	# DEBUG DETALLADO: Verificar qué datos llegan desde Columna1
	print("DEBUG - Datos recibidos desde Columna1_logic:")
	print("  Animación A recibida - Keys: %s" % str(anim_a_data.keys()))
	for key in anim_a_data.keys():
		var value = anim_a_data[key]
		if value is Node3D:
			print("    %s: Node3D (%s)" % [key, value.name if value else "null"])
		else:
			print("    %s: %s (%s)" % [key, str(value), type_string(typeof(value))])
	
	print("  Animación B recibida - Keys: %s" % str(anim_b_data.keys()))
	for key in anim_b_data.keys():
		var value = anim_b_data[key]
		if value is Node3D:
			print("    %s: Node3D (%s)" % [key, value.name if value else "null"])
		else:
			print("    %s: %s (%s)" % [key, str(value), type_string(typeof(value))])
	
	system_state.animations_loaded = true
	shared_data.animation_a = anim_a_data
	shared_data.animation_b = anim_b_data
	
	# Notificar a otras columnas
	emit_signal("animations_loaded", anim_a_data, anim_b_data)
	
	_update_system_state()

func _on_transition_config_changed(config: Dictionary):
	"""Manejar cambio de configuración de transición (señal global)"""
	print("Coordinador Global: Configuración de transición cambiada")
	system_state.transition_config_valid = config.get("valid", false)
	shared_data.transition_config = config
	
	# Emitir señal global
	emit_signal("transition_config_changed", config)
	
	_update_system_state()

func _on_generate_transition_requested():
	"""Manejar solicitud de generación de transición (señal global)"""
	print("Coordinador Global: Generación de transición solicitada")
	
	# Verificar que el sistema esté listo
	if not system_state.animations_loaded:
		print("❌ No se puede generar: animaciones no cargadas")
		return
	
	if not system_state.transition_config_valid:
		print("❌ No se puede generar: configuración no válida")
		return
	
	# Emitir señal global
	emit_signal("generate_transition_requested")
	print("🎬 Solicitud de generación propagada al sistema")

func _on_notify_column2_animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary):
	"""Notificar a Columna 2 que las animaciones están listas"""
	print("Notificando Columna 2: Animaciones cargadas")
	
	# DEBUG DETALLADO: Verificar estado de Columna2_logic
	print("DEBUG - Estado de Columna2_logic:")
	print("  columna2_logic existe: %s" % ("Si" if columna2_logic else "No"))
	if columna2_logic:
		print("  Nombre: %s" % columna2_logic.name)
		print("  Ruta: %s" % columna2_logic.get_path())
		print("  Script: %s" % str(columna2_logic.get_script()))
		print("  Método load_animations_data: %s" % ("Si" if columna2_logic.has_method("load_animations_data") else "No"))
		print("  Es válido: %s" % ("Si" if is_instance_valid(columna2_logic) else "No"))
	
	# Intentar encontrar Columna2_logic si no está disponible
	if not columna2_logic or not is_instance_valid(columna2_logic):
		print("Buscando Columna2_logic en el árbol de nodos...")
		columna2_logic = get_node_or_null("Columna2_Logic")
		if columna2_logic:
			print("Columna2_logic encontrado en ruta directa")
		else:
			# Buscar en todos los hijos
			for child in get_children():
				if child.name == "Columna2_Logic":
					columna2_logic = child
					print("Columna2_logic encontrado como hijo: %s" % child.get_path())
					break
	
	if columna2_logic and columna2_logic.has_method("load_animations_data"):
		#columna2_logic.load_animations_data(anim_a_data, anim_b_data)
		columna2_logic.load_animations_data(shared_data.base_model, anim_a_data, anim_b_data)
		print("Datos enviados a Columna2_logic")
	else:
		print("Columna2_logic no disponible o sin método load_animations_data")
	
	if columna2_ui and columna2_ui.has_method("on_animations_loaded"):
		columna2_ui.on_animations_loaded(anim_a_data, anim_b_data)
		print("Datos enviados a Columna2_UI")
	else:
		print("Columna2_ui no disponible")

func _on_preview_ready(preview_data: Dictionary):
	"""Manejar confirmación de preview listo - VERSIÓN SIMPLIFICADA"""
	print("Coordinador Global: Preview listo")
	system_state.preview_ready = true
	
	emit_signal("preview_ready", preview_data)
	_update_system_state()

func _update_system_state():
	"""Actualizar estado global del sistema"""
	print("Actualizando estado del sistema:")
	print("  Base cargada: %s" % system_state.base_loaded)
	print("  Animaciones cargadas: %s" % system_state.animations_loaded)
	print("  Preview listo: %s" % system_state.preview_ready)
	print("  Config transición válida: %s" % system_state.transition_config_valid)
	
	# Habilitar funcionalidades según el estado
	var can_preview = system_state.base_loaded and system_state.animations_loaded
	
	if can_preview and not system_state.preview_ready:
		print("Condiciones para preview cumplidas")
		# system_state.preview_ready se actualiza cuando Columna2 confirme

# ========================================================================
# API PÚBLICA PARA DEBUG Y CONTROL MANUAL
# ========================================================================

func get_system_state() -> Dictionary:
	"""Obtener estado actual del sistema"""
	return system_state.duplicate()

func get_shared_data() -> Dictionary:
	"""Obtener datos compartidos del sistema"""
	return shared_data.duplicate()

func force_reload_column1():
	"""Recargar Columna 1 usando estructura de escena (para desarrollo/debug)"""
	print("Forzando recarga de Columna 1...")
	_initialize_column1()

func force_reload_column2():
	"""Recargar Columna 2 usando estructura de escena (para desarrollo/debug)"""
	print("Forzando recarga de Columna 2...")
	_initialize_column2()

func force_reload_column3():
	"""Recargar Columna 3 usando estructura de escena (para desarrollo/debug)"""
	print("Forzando recarga de Columna 3...")
	_initialize_column3()

# ========================================================================
# MÉTODOS DE DEBUG Y TESTING
# ========================================================================

func debug_system_state():
	"""Debug completo del estado del coordinador"""
	print("\n=== DEBUG COORDINADOR 4 COLUMNAS ===")
	print("Estado del sistema:")
	for key in system_state.keys():
		print("  %s: %s" % [key, system_state[key]])
	
	print("\nColumnas inicializadas:")
	print("  Columna1_Logic: %s" % ("OK" if columna1_logic else "NULL"))
	print("  Columna1_UI: %s" % ("OK" if columna1_ui else "NULL"))
	print("  Columna2_Logic: %s" % ("OK" if columna2_logic else "NULL"))
	print("  Columna2_UI: %s" % ("OK" if columna2_ui else "NULL"))
	print("  Columna3_Logic: %s" % ("OK" if columna3_logic else "NULL"))
	print("  Columna3_UI: %s" % ("OK" if columna3_ui else "NULL"))
	
	print("\nDatos compartidos:")
	print("  Base model size: %d keys" % shared_data.base_model.size())
	print("  Animation A size: %d keys" % shared_data.animation_a.size())
	print("  Animation B size: %d keys" % shared_data.animation_b.size())
	print("  Transition config size: %d keys" % shared_data.transition_config.size())
	print("=====================================\n")

func debug_coordinator_state():
	"""Debug específico del coordinador"""
	print("\n=== DEBUG ESTADO COORDINADOR ===")
	print("Hijos directos:")
	for i in range(get_child_count()):
		var child = get_child(i)
		print("  %d. %s (%s)" % [i, child.name, child.get_class()])
	
	print("\nEstructura HSplitContainer:")
	var hsplit = get_node_or_null("HSplitContainer")
	if hsplit:
		_analyze_nodes_recursive(hsplit, 0)
	print("=================================\n")

func _debug_column1_systems():
	"""Debug específico de sistemas de Columna1"""
	print("=== DEBUG SISTEMAS COLUMNA1 ===")
	
	if columna1_logic and columna1_logic.has_method("debug_system_status"):
		columna1_logic.debug_system_status()
	else:
		print("ERROR: Columna1_logic no disponible o sin método debug_system_status")
	
	if columna1_logic and columna1_logic.has_method("verify_systems_initialization"):
		var systems_ok = columna1_logic.verify_systems_initialization()
		print("Inicialización completa: %s" % ("SI" if systems_ok else "NO"))
	
	# Debug específico del proceso de carga
	if columna1_logic and columna1_logic.has_method("debug_loading_process"):
		columna1_logic.debug_loading_process()
	
	print("=========================================")

func _debug_column2_systems():
	"""Debug específico de sistemas de Columna2"""
	print("=== DEBUG SISTEMAS COLUMNA2 ===")
	
	if columna2_logic and columna2_logic.has_method("debug_system_status"):
		columna2_logic.debug_system_status()
	else:
		print("ERROR: Columna2_logic no disponible o sin método debug_system_status")
	
	if columna2_ui and columna2_ui.has_method("debug_ui_state"):
		columna2_ui.debug_ui_state()
	else:
		print("ERROR: Columna2_UI no disponible o sin método debug_ui_state")
	
	print("=========================================")

func _debug_column3_systems():
	"""Debug específico de sistemas de Columna 3"""
	print("\n=== DEBUG COLUMNA 3 ===")
	print("Columna3_Logic: %s" % ("OK" if columna3_logic else "NULL"))
	print("Columna3_UI: %s" % ("OK" if columna3_ui else "NULL"))
	
	if columna3_logic:
		print("Columna3_Logic detalles:")
		print("  Nombre: %s" % columna3_logic.name)
		print("  Ruta: %s" % columna3_logic.get_path())
		print("  Script: %s" % str(columna3_logic.get_script()))
		print("  Método load_skeleton_data: %s" % ("SI" if columna3_logic.has_method("load_skeleton_data") else "NO"))
		print("  Es válido: %s" % ("SI" if is_instance_valid(columna3_logic) else "NO"))
		
		if columna3_logic.has_method("is_ready_for_transition"):
			print("  Config válida: %s" % columna3_logic.is_ready_for_transition())
		if columna3_logic.has_method("get_transition_config"):
			var config = columna3_logic.get_transition_config()
			print("  Duración: %.2fs" % config.get("duration", 0))
			print("  Frames: %d" % config.get("frames", 0))
			print("  Interpolación: %s" % config.get("interpolation", "None"))
	else:
		print("❌ Columna3_Logic es NULL - verificar inicialización")
	
	if columna3_ui:
		print("Columna3_UI detalles:")
		print("  Nombre: %s" % columna3_ui.name)
		print("  Ruta: %s" % columna3_ui.get_path())
		print("  Es válido: %s" % ("SI" if is_instance_valid(columna3_ui) else "NO"))
	else:
		print("❌ Columna3_UI es NULL - verificar inicialización")
	
	print("Estado del sistema - Config válida: %s" % system_state.transition_config_valid)
	
	# DEBUG ADICIONAL: Verificar contenedor
	var col3_container = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container")
	if col3_container:
		print("Columna3_Container encontrado:")
		print("  Hijos: %d" % col3_container.get_child_count())
		for i in range(col3_container.get_child_count()):
			var child = col3_container.get_child(i)
			print("    %d. %s (%s)" % [i, child.name, child.get_class()])
	else:
		print("❌ Columna3_Container NO encontrado")
	
	print("========================\n")

func _analyze_nodes_recursive(node: Node, depth: int):
	"""Analizar nodos recursivamente"""
	var indent = "  ".repeat(depth)
	var script_info = ""
	if node.get_script():
		script_info = " [SCRIPT: %s]" % str(node.get_script()).get_file()
	
	print("%s- %s (%s)%s" % [indent, node.name, node.get_class(), script_info])
	
	# Limitar profundidad para evitar spam
	if depth < 3:
		for child in node.get_children():
			_analyze_nodes_recursive(child, depth + 1)
