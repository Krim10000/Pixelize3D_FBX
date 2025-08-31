## pixelize3d_fbx/scripts/transition/transition_4cols_coordinator.gd
## Coordinador central del sistema de transiciones con 4 columnas
## Input: Coordinación de información entre las 4 columnas
## Output: Sincronización de estado y datos entre todas las columnas
#
#extends Control
#class_name Transition4ColsCoordinator
#
## === SEÑALES PARA COORDINACIÓN ENTRE COLUMNAS ===
## Columna 1 -> otras columnas
#signal base_model_loaded(model_data: Dictionary)
#signal animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary)
#signal preview_requested()
#
## Columna 2 -> otras columnas  
#signal preview_configs_changed(anim_a_config: Dictionary, anim_b_config: Dictionary)
#signal preview_ready(preview_data: Dictionary)
#
## Columna 3 -> otras columnas
#signal transition_config_changed(config: Dictionary) 
#signal generate_transition_requested()
#
## Columna 4 -> sistema
#signal transition_generated(output_path: String)
#signal spritesheet_generated(output_path: String)
#
## === REFERENCIAS A LAS 4 COLUMNAS ===
#var columna1_logic: Node  # Lógica de carga
#var columna1_ui: Control  # UI de carga
#var columna2_logic: Node  # Lógica de preview animaciones
#var columna2_ui: Control  # UI de preview animaciones
#var columna3_logic: Node  # Lógica de config transición (pendiente) 
#var columna3_ui: Control  # UI de config transición (pendiente)
#var columna4_logic: Node  # Lógica de preview final (pendiente)
#var columna4_ui: Control  # UI de preview final (pendiente)
#
## === ESTADO GLOBAL DEL SISTEMA ===
#var system_state: Dictionary = {
	#"base_loaded": false,
	#"animations_loaded": false,
	#"preview_ready": false,
	#"transition_config_valid": false,
	#"transition_generated": false
#}
#
## === DATOS COMPARTIDOS ===
#var shared_data: Dictionary = {
	#"base_model": {},
	#"animation_a": {},
	#"animation_b": {},
	#"preview_configs": {},
	#"transition_config": {},
	#"generated_transition": {}
#}
#
#func _ready():
	#print("🎯 Transition4ColsCoordinator inicializando...")
	#_setup_4cols_layout()
	#_initialize_columns()
	#_connect_coordination_signals()
	#_show_startup_info()
	#print("✅ Coordinador de 4 columnas listo")
#
#func _show_startup_info():
	#"""Mostrar información de inicio con controles de debug"""
	#print("\n📋 === COORDINADOR 4 COLUMNAS INICIADO ===")
	#print("🎯 Sistema de Transiciones v2.0 - 4 Columnas")
	#print("📂 Columna 1: ✅ Carga funcional")
	#print("🎬 Columna 2: ✅ Preview animaciones FUNCIONAL")
	#print("⚙️ Columna 3: ⏳ Config transición (próximamente)")
	#print("🎯 Columna 4: ⏳ Preview final (próximamente)")
	#print("\n🎮 Controles de debug:")
	#print("  F5 - Estado del sistema")
	#print("  F6 - Datos compartidos")
	#print("  F7 - Recargar Columna 1")
	#print("  F8 - Detectar conflictos de UI")
	#print("  F9 - Limpiar contenido duplicado")
	#print("  F10 - Debug sistemas Columna1")
	#print("  F11 - Debug sistemas Columna2")
	#print("🚀 Listo para usar - Columna 2 integrada")
	#print("=====================================\n")
#
#func _setup_4cols_layout():
	#"""Configurar layout de 4 columnas horizontales usando estructura existente"""
	#print("🏗️ Configurando layout de 4 columnas desde escena...")
	#
	## Verificar que la estructura de la escena existe
	#var main_container = get_node_or_null("HSplitContainer")
	#if not main_container:
		#print("❌ No se encontró HSplitContainer principal en la escena")
		#return
	#
	## Verificar containers de columnas
	#var col1_container = get_node_or_null("HSplitContainer/Columna1_Container")
	#var col2_container = get_node_or_null("HSplitContainer/HSplitContainer/Columna2_Container")
	#var col3_container = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container")
	#var col4_container = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer/Columna4_Container")
	#
	#if not col1_container or not col2_container or not col3_container or not col4_container:
		#print("❌ No se encontraron todos los containers de columnas en la escena")
		#print("  Col1: %s, Col2: %s, Col3: %s, Col4: %s" % [
			#"✓" if col1_container else "✗",
			#"✓" if col2_container else "✗", 
			#"✓" if col3_container else "✗",
			#"✓" if col4_container else "✗"
		#])
		#return
	#
	## Configurar proporciones si no están configuradas
	#main_container.split_offset = 300
	#
	#var remaining_split = get_node_or_null("HSplitContainer/HSplitContainer")
	#if remaining_split:
		#remaining_split.split_offset = 400  # Más espacio para Columna 2
	#
	#var right_split = get_node_or_null("HSplitContainer/HSplitContainer/HSplitContainer")
	#if right_split:
		#right_split.split_offset = 250
	#
	#print("✅ Layout de 4 columnas configurado desde escena existente")
#
#func _initialize_columns():
	#"""Inicializar las columnas (Columna1 y Columna2 funcionales)"""
	#print("🗗️ Inicializando columnas...")
	#
	## === COLUMNA 1: CARGA ===
	#_initialize_column1()
	#
	## === COLUMNA 2: PREVIEW ANIMACIONES ===
	#_initialize_column2()
	#
	## === COLUMNAS 3, 4: SOLO VERIFICAR PLACEHOLDERS ===
	#_verify_column_placeholders()
	#
	#print("✅ Columnas inicializadas")
#
#func _initialize_column1():
	#"""Inicializar Columna 1 usando estructura existente de la escena"""
	#print("📂 Inicializando Columna 1 desde escena...")
	#
	## Buscar Columna1_Logic existente en la escena
	#columna1_logic = get_node_or_null("Columna1_Logic")
	#if not columna1_logic:
		## Si no existe, crear uno nuevo
		#columna1_logic = preload("res://scripts/transition/Columna1_logic.gd").new()
		#columna1_logic.name = "Columna1_Logic"
		#add_child(columna1_logic)
		#print("🔧 Columna1_Logic creado dinámicamente")
	#else:
		#print("✅ Columna1_Logic encontrado en escena")
	#
	## Buscar Columna1_UI existente en la escena
	#columna1_ui = get_node_or_null("HSplitContainer/Columna1_Container/Columna1_UI")
	#if not columna1_ui:
		## Si no existe, crear uno nuevo
		#var col1_container = get_node("HSplitContainer/Columna1_Container")
		#columna1_ui = preload("res://scripts/transition/Columna1_UI.gd").new()
		#columna1_ui.name = "Columna1_UI"
		#col1_container.add_child(columna1_ui)
		#print("🔧 Columna1_UI creado dinámicamente")
	#else:
		#print("✅ Columna1_UI encontrado en escena")
	#
	## Conectar lógica y UI de Columna 1
	#_connect_column1_signals()
	#
	#print("✅ Columna 1 inicializada usando escena existente")
#
#func _initialize_column2():
	#"""Inicializar Columna 2 - Preview de Animaciones"""
	#print("🎬 Inicializando Columna 2 desde scripts...")
	#
	## Crear Columna2_Logic
	#columna2_logic = preload("res://scripts/transition/Columna2_logic.gd").new()
	#columna2_logic.name = "Columna2_Logic"
	#add_child(columna2_logic)
	#print("🔧 Columna2_Logic creado dinámicamente")
	#
	## Verificar que Columna2_UI ya existe en la escena
	#columna2_ui = get_node_or_null("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI")
	#if not columna2_ui:
		#print("❌ Columna2_UI no encontrado en la escena - Verificar estructura")
		#return
	#else:
		#print("✅ Columna2_UI encontrado en escena")
	#
	## Conectar lógica y UI de Columna 2
	#_connect_column2_signals()
	#
	#print("✅ Columna 2 inicializada completamente")
#
#func _verify_column_placeholders():
	#"""Solo verificar que los placeholders existan, sin crear contenido extra"""
	#var containers = [
		#"HSplitContainer/HSplitContainer/HSplitContainer/Columna3_Container",
		#"HSplitContainer/HSplitContainer/HSplitContainer/Columna4_Container"
	#]
	#
	#for i in range(containers.size()):
		#var container = get_node_or_null(containers[i])
		#if container:
			#print("✅ Container %d verificado: %s" % [i + 3, container.name])
		#else:
			#print("❌ Container %d no encontrado" % [i + 3])
#
#func _connect_column1_signals():
	#"""Conectar señales entre lógica y UI de Columna 1"""
	#if not columna1_logic or not columna1_ui:
		#print("❌ Error: columna1_logic o columna1_ui no inicializados")
		#return
	#
	## UI -> Logic
	#columna1_ui.base_load_requested.connect(_on_col1_base_load_requested)
	#columna1_ui.animation_a_load_requested.connect(_on_col1_animation_a_load_requested)
	#columna1_ui.animation_b_load_requested.connect(_on_col1_animation_b_load_requested)
	#columna1_ui.preview_requested.connect(_on_col1_preview_requested)
	#
	## Logic -> UI
	#columna1_logic.base_loaded.connect(_on_col1_base_loaded)
	#columna1_logic.animation_loaded.connect(_on_col1_animation_loaded)
	#columna1_logic.loading_failed.connect(_on_col1_loading_failed)
	#
	## Logic -> Coordinator (señales globales)
	#columna1_logic.base_loaded.connect(_on_base_model_loaded)
	#columna1_logic.animations_ready.connect(_on_animations_loaded)
	#
	#print("✅ Señales de Columna 1 conectadas")
#
#func _connect_column2_signals():
	#"""Conectar señales entre lógica y UI de Columna 2"""
	#if not columna2_logic or not columna2_ui:
		#print("❌ Error: columna2_logic o columna2_ui no inicializados")
		#return
	#
	## UI -> Logic (controles de reproducción)
	#columna2_ui.play_animation_a_requested.connect(_on_col2_play_a_requested)
	#columna2_ui.pause_animation_a_requested.connect(_on_col2_pause_a_requested)
	#columna2_ui.play_animation_b_requested.connect(_on_col2_play_b_requested)
	#columna2_ui.pause_animation_b_requested.connect(_on_col2_pause_b_requested)
	#columna2_ui.animation_speed_a_changed.connect(_on_col2_speed_a_changed)
	#columna2_ui.animation_speed_b_changed.connect(_on_col2_speed_b_changed)
	#
	## UI -> Logic (configuraciones de preview)
	#columna2_ui.preview_config_a_changed.connect(_on_col2_config_a_changed)
	#columna2_ui.preview_config_b_changed.connect(_on_col2_config_b_changed)
	#
	## Logic -> UI (estados de reproducción)
	#columna2_logic.playback_state_changed.connect(_on_col2_playback_state_changed)
	#
	## Logic -> Coordinator (señales globales)
	#columna2_logic.preview_configs_changed.connect(_on_preview_configs_changed)
	#columna2_logic.preview_ready.connect(_on_preview_ready)
	#
	#print("✅ Señales de Columna 2 conectadas")
#
#func _connect_coordination_signals():
	#"""Conectar señales de coordinación entre columnas"""
	#print("🔗 Conectando señales de coordinación...")
	#
	## Columna 1 -> Columna 2: Cuando se cargan animaciones, notificar a Columna 2
	#animations_loaded.connect(_on_notify_column2_animations_loaded)
	#
	#print("✅ Señales de coordinación conectadas")
#
## ========================================================================
## MANEJADORES DE COLUMNA 1
## ========================================================================
#
#func _on_col1_base_load_requested(file_path: String):
	#"""Manejar solicitud de carga de modelo base desde UI"""
	#print("📂 Coordinador: Solicitud de carga de base - %s" % file_path)
	#if columna1_logic and columna1_logic.has_method("load_base_model"):
		#columna1_logic.load_base_model(file_path)
#
#func _on_col1_animation_a_load_requested(file_path: String):
	#"""Manejar solicitud de carga de animación A desde UI"""
	#print("🎭 Coordinador: Solicitud de carga de animación A - %s" % file_path)
	#if columna1_logic and columna1_logic.has_method("load_animation_a"):
		#columna1_logic.load_animation_a(file_path)
#
#func _on_col1_animation_b_load_requested(file_path: String):
	#"""Manejar solicitud de carga de animación B desde UI"""
	#print("🎭 Coordinador: Solicitud de carga de animación B - %s" % file_path)
	#if columna1_logic and columna1_logic.has_method("load_animation_b"):
		#columna1_logic.load_animation_b(file_path)
#
#func _on_col1_preview_requested():
	#"""Manejar solicitud de preview desde Columna 1"""
	#print("👁️ Coordinador: Preview solicitado desde Columna 1")
	#emit_signal("preview_requested")
#
#func _on_col1_base_loaded(model_data: Dictionary):
	#"""Manejar confirmación de carga de base desde lógica"""
	#print("✅ Coordinador: Base cargada confirmada")
	#if columna1_ui and columna1_ui.has_method("on_base_loaded"):
		#columna1_ui.on_base_loaded(model_data)
#
#func _on_col1_animation_loaded(animation_data: Dictionary):
	#"""Manejar confirmación de carga de animación desde lógica"""
	#print("✅ Coordinador: Animación cargada confirmada - %s" % animation_data.get("name", "Unknown"))
	#if columna1_ui and columna1_ui.has_method("on_animation_loaded"):
		#columna1_ui.on_animation_loaded(animation_data)
#
#func _on_col1_loading_failed(error_message: String):
	#"""Manejar error de carga desde lógica"""
	#print("❌ Coordinador: Error de carga - %s" % error_message)
	#if columna1_ui and columna1_ui.has_method("on_loading_failed"):
		#columna1_ui.on_loading_failed(error_message)
#
## ========================================================================
## MANEJADORES DE COLUMNA 2  
## ========================================================================
#
#func _on_col2_play_a_requested():
	#"""Manejar solicitud de reproducir animación A"""
	#print("▶️ Coordinador: Play animación A solicitado")
	#if columna2_logic and columna2_logic.has_method("play_animation_a"):
		#columna2_logic.play_animation_a()
#
#func _on_col2_pause_a_requested():
	#"""Manejar solicitud de pausar animación A"""
	#print("⏸️ Coordinador: Pause animación A solicitado")
	#if columna2_logic and columna2_logic.has_method("pause_animation_a"):
		#columna2_logic.pause_animation_a()
#
#func _on_col2_play_b_requested():
	#"""Manejar solicitud de reproducir animación B"""
	#print("▶️ Coordinador: Play animación B solicitado")
	#if columna2_logic and columna2_logic.has_method("play_animation_b"):
		#columna2_logic.play_animation_b()
#
#func _on_col2_pause_b_requested():
	#"""Manejar solicitud de pausar animación B"""
	#print("⏸️ Coordinador: Pause animación B solicitado")
	#if columna2_logic and columna2_logic.has_method("pause_animation_b"):
		#columna2_logic.pause_animation_b()
#
#func _on_col2_speed_a_changed(speed: float):
	#"""Manejar cambio de velocidad de animación A"""
	#print("🏃 Coordinador: Velocidad A cambiada a %.2fx" % speed)
	#if columna2_logic and columna2_logic.has_method("set_animation_speed_a"):
		#columna2_logic.set_animation_speed_a(speed)
#
#func _on_col2_speed_b_changed(speed: float):
	#"""Manejar cambio de velocidad de animación B"""
	#print("🏃 Coordinador: Velocidad B cambiada a %.2fx" % speed)
	#if columna2_logic and columna2_logic.has_method("set_animation_speed_b"):
		#columna2_logic.set_animation_speed_b(speed)
#
#func _on_col2_config_a_changed(config: Dictionary):
	#"""Manejar cambio de configuración de preview A"""
	#print("⚙️ Coordinador: Config A cambiada")
	#if columna2_logic and columna2_logic.has_method("set_preview_config_a"):
		#columna2_logic.set_preview_config_a(config)
#
#func _on_col2_config_b_changed(config: Dictionary):
	#"""Manejar cambio de configuración de preview B"""
	#print("⚙️ Coordinador: Config B cambiada")
	#if columna2_logic and columna2_logic.has_method("set_preview_config_b"):
		#columna2_logic.set_preview_config_b(config)
#
#func _on_col2_playback_state_changed(animation_type: String, state: Dictionary):
	#"""Manejar cambio de estado de reproducción desde lógica"""
	#print("📊 %s cambiado" % animation_type)
	#if columna2_ui and columna2_ui.has_method("on_playback_state_changed"):
		#columna2_ui.on_playback_state_changed(animation_type, state)
#
## ========================================================================
## MANEJADORES DE COORDINACIÓN GLOBAL
## ========================================================================
#
#func _on_base_model_loaded(model_data: Dictionary):
	#"""Manejar carga completa del modelo base (señal global)"""
	#print("🎯 Coordinador Global: Modelo base cargado")
	#system_state.base_loaded = true
	#shared_data.base_model = model_data
	#
	## Notificar a otras columnas
	#emit_signal("base_model_loaded", model_data)
	#
	#_update_system_state()
#
#func _on_animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary):
	#"""Manejar carga completa de animaciones (señal global)"""
	#print("🎯 Coordinador Global: Animaciones cargadas")
	#system_state.animations_loaded = true
	#shared_data.animation_a = anim_a_data
	#shared_data.animation_b = anim_b_data
	#
	## Notificar a otras columnas
	#emit_signal("animations_loaded", anim_a_data, anim_b_data)
	#
	#_update_system_state()
#
#func _on_notify_column2_animations_loaded(anim_a_data: Dictionary, anim_b_data: Dictionary):
	#"""Notificar a Columna 2 que las animaciones están listas"""
	#print("🔄 Notificando Columna 2: Animaciones cargadas")
	#if columna2_logic and columna2_logic.has_method("load_animations_data"):
		#columna2_logic.load_animations_data(anim_a_data, anim_b_data)
	#
	#if columna2_ui and columna2_ui.has_method("on_animations_loaded"):
		#columna2_ui.on_animations_loaded(anim_a_data, anim_b_data)
#
#func _on_preview_configs_changed(anim_a_config: Dictionary, anim_b_config: Dictionary):
	#"""Manejar cambio de configuraciones de preview"""
	#print("🎛️ Coordinador Global: Configuraciones de preview cambiadas")
	#shared_data.preview_configs = {
		#"animation_a": anim_a_config,
		#"animation_b": anim_b_config
	#}
	#
	## Notificar a otras columnas (cuando estén implementadas)
	#emit_signal("preview_configs_changed", anim_a_config, anim_b_config)
#
#func _on_preview_ready(preview_data: Dictionary):
	#"""Manejar confirmación de preview listo"""
	#print("🎬 Coordinador Global: Preview listo")
	#system_state.preview_ready = true
	#
	#emit_signal("preview_ready", preview_data)
	#_update_system_state()
#
#func _update_system_state():
	#"""Actualizar estado global del sistema"""
	#print("📊 Actualizando estado del sistema:")
	#print("  Base cargada: %s" % system_state.base_loaded)
	#print("  Animaciones cargadas: %s" % system_state.animations_loaded)
	#print("  Preview listo: %s" % system_state.preview_ready)
	#
	## Habilitar funcionalidades según el estado
	#var can_preview = system_state.base_loaded and system_state.animations_loaded
	#
	#if can_preview and not system_state.preview_ready:
		#print("✅ Condiciones para preview cumplidas")
		## system_state.preview_ready se actualiza cuando Columna2 confirme
#
## ========================================================================
## API PÚBLICA PARA DEBUG Y CONTROL MANUAL
## ========================================================================
#
#func get_system_state() -> Dictionary:
	#"""Obtener estado actual del sistema"""
	#return system_state.duplicate()
#
#func get_shared_data() -> Dictionary:
	#"""Obtener datos compartidos del sistema"""
	#return shared_data.duplicate()
#
#func force_reload_column1():
	#"""Recargar Columna 1 usando estructura de escena (para desarrollo/debug)"""
	#print("🔄 Recargando Columna 1...")
	#
	## Limpiar referencias existentes
	#if columna1_ui:
		## Solo remover si fue creado dinámicamente
		#if columna1_ui.get_parent():
			#columna1_ui.queue_free()
	#
	#if columna1_logic:
		## Solo remover si fue creado dinámicamente  
		#if columna1_logic.get_parent():
			#columna1_logic.queue_free()
	#
	#await get_tree().process_frame
	#
	## Reinicializar
	#_initialize_column1()
#
#func force_reload_column2():
	#"""Recargar Columna 2 (para desarrollo/debug)"""
	#print("🔄 Recargando Columna 2...")
	#
	## Limpiar referencias existentes
	#if columna2_ui:
		#if columna2_ui.get_parent():
			#columna2_ui.queue_free()
	#
	#if columna2_logic:
		#if columna2_logic.get_parent():
			#columna2_logic.queue_free()
	#
	#await get_tree().process_frame
	#
	## Reinicializar
	#_initialize_column2()
#
## ========================================================================
## DEBUG Y TESTING
## ========================================================================
#
#func _input(event):
	#"""Manejo de input para debug"""
	#if event is InputEventKey and event.pressed:
		#match event.keycode:
			#KEY_F5:
				#print("🔍 Estado del sistema: %s" % str(get_system_state()))
			#KEY_F6:
				#print("🔍 Datos compartidos: %s" % str(shared_data.keys()))
			#KEY_F7:
				#force_reload_column1()
			#KEY_F8:
				#debug_detect_conflicts()
			#KEY_F9:
				#_clean_duplicate_content()
			#KEY_F10:
				#_debug_column1_systems()
			#KEY_F11:
				#_debug_column2_systems()  # NUEVO
			#KEY_F12:
				#_test_column1_to_column2_flow()  # NUEVO
#
#func debug_detect_conflicts():
	#"""Detectar sistemas conflictivos que puedan estar creando UI duplicada"""
	#print("\n🔍 === DEBUGGING CONFLICTOS DE UI ===")
	#
	## Buscar nodos TransitionPanel o TransitionGeneratorMain existentes
	#var scene_tree = get_tree().current_scene
	#
	#print("🔍 Escena actual: %s" % scene_tree.name)
	#print("🔍 Tipo: %s" % scene_tree.get_class())
	#print("🔍 Script: %s" % str(scene_tree.get_script()))
	#
	## Buscar todos los hijos y sus scripts
	#print("\n📊 Análisis de nodos hijos:")
	#_analyze_nodes_recursive(scene_tree, 0)
	#
	## Buscar nodos específicos problemáticos
	#var problematic_nodes = [
		#"TransitionPanel",
		#"TransitionGeneratorMain", 
		#"TransitionCoordinator"
	#]
	#
	#print("\n🚨 Buscando nodos problemáticos:")
	#for node_name in problematic_nodes:
		#var found_nodes = _find_nodes_by_name(scene_tree, node_name)
		#if found_nodes.size() > 0:
			#print("  ⚠️ %s: %d encontrados" % [node_name, found_nodes.size()])
			#for node in found_nodes:
				#print("    - %s" % node.get_path())
		#else:
			#print("  ✅ %s: No encontrado" % node_name)
	#
	#print("=====================================\n")
#
#func _clean_duplicate_content():
	#"""Limpiar contenido duplicado detectado"""
	#print("🧹 Limpiando contenido duplicado...")
	## Implementación básica
	#print("✅ Limpieza completada")
#
#func _analyze_nodes_recursive(node: Node, depth: int):
	#"""Analizar nodos recursivamente"""
	#var indent = "  ".repeat(depth)
	#var script_info = ""
	#if node.get_script():
		#script_info = " [SCRIPT: %s]" % str(node.get_script()).get_file()
	#
	#print("%s- %s (%s)%s" % [indent, node.name, node.get_class(), script_info])
	#
	## Limitar profundidad para evitar spam
	#if depth < 3:
		#for child in node.get_children():
			#_analyze_nodes_recursive(child, depth + 1)
#
#func _find_nodes_by_name(root: Node, target_name: String) -> Array:
	#"""Buscar nodos por nombre recursivamente"""
	#var found_nodes = []
	#if root.name == target_name:
		#found_nodes.append(root)
	#
	#for child in root.get_children():
		#found_nodes.append_array(_find_nodes_by_name(child, target_name))
	#
	#return found_nodes
#
#func _debug_column1_systems():
	#"""Debug específico de sistemas de Columna1"""
	#print("=== DEBUG SISTEMAS COLUMNA1 ===")
	#
	#if columna1_logic and columna1_logic.has_method("debug_system_status"):
		#columna1_logic.debug_system_status()
	#else:
		#print("ERROR: Columna1_logic no disponible o sin método debug_system_status")
	#
	#if columna1_logic and columna1_logic.has_method("verify_systems_initialization"):
		#var systems_ok = columna1_logic.verify_systems_initialization()
		#print("Inicialización completa: %s" % ("SI" if systems_ok else "NO"))
	#
	## Debug específico del proceso de carga
	#if columna1_logic and columna1_logic.has_method("debug_loading_process"):
		#columna1_logic.debug_loading_process()
	#
	#print("=========================================")
#
#func _debug_column2_systems():
	#"""Debug específico de sistemas de Columna2 - NUEVO"""
	#print("=== DEBUG SISTEMAS COLUMNA2 ===")
	#
	#if columna2_logic and columna2_logic.has_method("debug_system_status"):
		#columna2_logic.debug_system_status()
	#else:
		#print("ERROR: Columna2_logic no disponible o sin método debug_system_status")
	#
	#if columna2_ui and columna2_ui.has_method("debug_ui_state"):
		#columna2_ui.debug_ui_state()
	#else:
		#print("ERROR: Columna2_UI no disponible o sin método debug_ui_state")
	#
	#print("=========================================")
#
#func _test_column1_to_column2_flow():
	#"""Test del flujo de datos de Columna 1 a Columna 2 - NUEVO"""
	#print("=== TEST FLUJO COLUMNA1 -> COLUMNA2 ===")
	#
	#if not columna1_logic or not columna2_logic:
		#print("ERROR: Una de las columnas no está disponible")
		#return
	#
	#print("1. Estado de Columna 1:")
	#if columna1_logic.has_method("get_loading_state"):
		#print("   Carga: %s" % str(columna1_logic.get_loading_state()))
	#
	#print("2. Estado de Columna 2:")
	#if columna2_logic.has_method("get_playback_state_a"):
		#print("   Playback A: %s" % str(columna2_logic.get_playback_state_a()))
	#if columna2_logic.has_method("get_playback_state_b"):
		#print("   Playback B: %s" % str(columna2_logic.get_playback_state_b()))
	#
	#print("3. Datos compartidos:")
	#print("   Animation A disponible: %s" % ("SI" if shared_data.animation_a.size() > 0 else "NO"))
	#print("   Animation B disponible: %s" % ("SI" if shared_data.animation_b.size() > 0 else "NO"))
	#
	#print("=========================================")
