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
var columna3_logic: Node  # Lógica de config transición (pendiente) 
var columna3_ui: Control  # UI de config transición (pendiente)
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
	"""Cuando las animaciones están listas, enviarlas a Columna2"""
	var col2_logic = get_node("Columna2_Logic")
	if col2_logic:
		col2_logic.load_animations_data(anim_a_data, anim_b_data)




func _show_startup_info():
	"""Mostrar información de inicio con controles de debug"""
	print("\n=== COORDINADOR 4 COLUMNAS INICIADO ===")
	print("Sistema de Transiciones v2.0 - 4 Columnas")
	print("Columna 1: Carga funcional")
	print("Columna 2: Preview animaciones FUNCIONAL")
	print("Columna 3: Config transición (próximamente)")
	print("Columna 4: Preview final (próximamente)")
	print("\nControles de debug:")
	print("  F5 - Estado del sistema")
	print("  F6 - Debug Columna 1")
	print("  F7 - Debug Columna 2")
	print("  F8 - Debug coordinador")
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
	
	# Columnas 3 y 4: Verificar placeholders
	_verify_column_placeholders()
	
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

#func _initialize_column2():
	#"""Inicializar Columna 2 - Preview de Animaciones VERSIÓN SIMPLIFICADA"""
	#print("Inicializando Columna 2 desde scripts (versión simplificada)...")
	#
	## Crear Columna2_Logic usando script simplificado
	#var columna2_logic_script = load("res://scripts/transition/Columna2_Logic.gd")
	##res://scripts/transition/Columna2_logic.gd
	#if columna2_logic_script:
		#columna2_logic = columna2_logic_script.new()
		#columna2_logic.name = "Columna2_Logic"
		#add_child(columna2_logic)
		#print("Columna2_Logic creado dinámicamente (versión simplificada)")
	#else:
		#print("Error: No se pudo cargar Columna2_Logic.gd")
		#return
	#
	## Verificar que Columna2_UI ya existe en la escena
	#columna2_ui = get_node_or_null("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI")
	#if not columna2_ui:
		#print("Columna2_UI no encontrado en la escena - Intentando crear dinámicamente")
		#
		## Intentar crear dinámicamente si no existe
		#var columna2_container = get_node_or_null("HSplitContainer/HSplitContainer/Columna2_Container")
		#if columna2_container:
			#var columna2_ui_script = load("res://scripts/transition/Columna2_UI.gd")
			#if columna2_ui_script:
				#columna2_ui = columna2_ui_script.new()
				#columna2_ui.name = "Columna2_UI"
				#columna2_container.add_child(columna2_ui)
				#print("Columna2_UI creado dinámicamente (versión simplificada)")
			#else:
				#print("Error: No se pudo cargar Columna2_UI.gd")
				#return
		#else:
			#print("Error: Contenedor Columna2 no encontrado")
			#return
	#else:
		#print("Columna2_UI encontrado en escena")
	#
	## Conectar lógica y UI de Columna 2
	#_connect_column2_signals()
	#
	#print("Columna 2 inicializada completamente (versión simplificada)")
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

#func _find_existing_columna2_logic(node: Node) -> Node:
	#"""Buscar instancia existente de Columna2Logic recursivamente"""
	## Verificar si este nodo tiene los métodos característicos
	#if node.has_method("load_animations_data") and node.has_method("setup_viewport_with_camera_and_model"):
		#print("DEBUG: Encontrado Columna2Logic existente en: %s" % node.get_path())
		#return node
	#
	## Buscar en hijos
	#for child in node.get_children():
		#var found = _find_existing_columna2_logic(child)
		#if found:
			#return found
	#
	#return null



func _verify_column_placeholders():
	"""Solo verificar que los placeholders existan, sin crear contenido extra"""
	var containers = [
		"HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container",
		"HSplitContainer/HSplitContainer/HSplitContainer/Columna4_Container"
	]
	
	for i in range(containers.size()):
		var container = get_node_or_null(containers[i])
		if container:
			print("Container %d verificado: %s" % [i + 3, container.name])
		else:
			print("Container %d no encontrado" % [i + 3])

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
	
	# ELIMINADO - Señales de configuración de preview (no existen en versión simplificada)
	# columna2_ui.preview_config_a_changed.connect(_on_col2_config_a_changed)
	# columna2_ui.preview_config_b_changed.connect(_on_col2_config_b_changed)
	
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

# ELIMINADO - Métodos de configuración de preview (no existen en versión simplificada)
# func _on_col2_config_a_changed(config: Dictionary):
# func _on_col2_config_b_changed(config: Dictionary):

func _on_col2_playback_state_changed(animation_type: String, state: Dictionary):
	"""Manejar cambio de estado de reproducción desde lógica"""
	#print("Coordinador: Estado de %s cambiado" % animation_type)
	if columna2_ui and columna2_ui.has_method("on_playback_state_changed"):
		columna2_ui.on_playback_state_changed(animation_type, state)

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
		columna2_logic.load_animations_data(anim_a_data, anim_b_data)
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
	
	print("\nDatos compartidos:")
	print("  Base model size: %d keys" % shared_data.base_model.size())
	print("  Animation A size: %d keys" % shared_data.animation_a.size())
	print("  Animation B size: %d keys" % shared_data.animation_b.size())
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

#func _find_existing_columna2_logic(node: Node) -> Node:
	#"""Buscar instancia existente de Columna2Logic recursivamente"""
	## Verificar si este nodo tiene los métodos característicos
	#if node.has_method("load_animations_data") and node.has_method("setup_viewport_with_camera_and_model"):
		#print("DEBUG: Encontrado Columna2Logic existente en: %s" % node.get_path())
		#return node
	#
	## Buscar en hijos
	#for child in node.get_children():
		#var found = _find_existing_columna2_logic(child)
		#if found:
			#return found
	#
	#return null

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
