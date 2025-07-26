# scripts/temp/animation_test.gd
# Script temporal para diagnosticar y reparar problemas de cambio de animación
# INSTRUCCIONES: Adjuntar este script a cualquier nodo en la escena y ejecutar

extends Node

# Variables para encontrar los componentes
var animation_controls_panel: Node = null
var debug_tool = preload("res://scripts/debug/animation_debug_tool.gd")

func _ready():
	print("🔧 SCRIPT DE TEST/REPARACIÓN DE ANIMACIONES INICIADO")
	
	# Esperar un poco para que todo se inicialice
	await get_tree().create_timer(2.0).timeout
	
	# Buscar el panel de controles
	_find_animation_controls()
	
	if animation_controls_panel:
		print("✅ Panel encontrado: %s" % animation_controls_panel.name)
		
		# Ejecutar diagnóstico completo
		_run_diagnostics()
		
		# Intentar reparaciones
		_attempt_repairs()
		
		# Probar cambios manualmente
		_test_manual_changes()
	else:
		print("❌ No se encontró animation_controls_panel")

func _find_animation_controls():
	"""Buscar el panel de controles de animación en la escena"""
	print("🔍 Buscando animation_controls_panel...")
	
	# Método 1: Por nombre específico
	animation_controls_panel = get_tree().get_first_node_in_group("animation_controls")
	
	if not animation_controls_panel:
		# Método 2: Buscar por tipo y script
		var potential_panels = get_tree().get_nodes_in_group("ui")
		for node in potential_panels:
			if "animation" in node.name.to_lower() and "control" in node.name.to_lower():
				animation_controls_panel = node
				break
	
	if not animation_controls_panel:
		# Método 3: Buscar recursivamente por nombre
		animation_controls_panel = _search_node_by_name(get_tree().root, "AnimationControlsPanel")
	
	if not animation_controls_panel:
		# Método 4: Buscar HBoxContainer con OptionButton
		var hbox_containers = _find_all_nodes_of_type(get_tree().root, "HBoxContainer")
		for hbox in hbox_containers:
			for child in hbox.get_children():
				if child is OptionButton:
					animation_controls_panel = hbox
					break
			if animation_controls_panel:
				break

func _search_node_by_name(node: Node, name_to_find: String) -> Node:
	"""Buscar nodo por nombre recursivamente"""
	if node.name == name_to_find:
		return node
	
	for child in node.get_children():
		var result = _search_node_by_name(child, name_to_find)
		if result:
			return result
	
	return null

func _find_all_nodes_of_type(node: Node, type_name: String) -> Array:
	"""Encontrar todos los nodos de un tipo específico"""
	var results = []
	
	if node.get_class() == type_name:
		results.append(node)
	
	for child in node.get_children():
		results.append_array(_find_all_nodes_of_type(child, type_name))
	
	return results

func _run_diagnostics():
	"""Ejecutar diagnóstico completo"""
	print("\n🩺 EJECUTANDO DIAGNÓSTICOS...")
	
	if debug_tool:
		debug_tool.debug_animation_system(animation_controls_panel)
	
	# Diagnósticos adicionales propios
	_check_scene_structure()
	_check_animation_data()

func _check_scene_structure():
	"""Verificar estructura de la escena"""
	print("\n--- VERIFICANDO ESTRUCTURA DE ESCENA ---")
	
	# Buscar ModelPreviewPanel
	var preview_panel = _search_node_by_name(get_tree().root, "ModelPreviewPanel")
	print("ModelPreviewPanel: %s" % ("✅ Encontrado" if preview_panel else "❌ No encontrado"))
	
	# Buscar ViewerCoordinator
	var coordinator = _search_node_by_name(get_tree().root, "ViewerCoordinator")
	print("ViewerCoordinator: %s" % ("✅ Encontrado" if coordinator else "❌ No encontrado"))
	
	# Buscar FBXLoader
	var fbx_loader = _search_node_by_name(get_tree().root, "FBXLoader")
	print("FBXLoader: %s" % ("✅ Encontrado" if fbx_loader else "❌ No encontrado"))

func _check_animation_data():
	"""Verificar datos de animación en el sistema"""
	print("\n--- VERIFICANDO DATOS DE ANIMACIÓN ---")
	
	# Buscar todos los AnimationPlayer en la escena
	var animation_players = _find_all_nodes_of_type(get_tree().root, "AnimationPlayer")
	print("AnimationPlayer encontrados: %d" % animation_players.size())
	
	for i in range(animation_players.size()):
		var player = animation_players[i]
		print("  Player %d: %s" % [i, player.name])
		print("    - Animaciones: %s" % str(player.get_animation_list()))
		print("    - Reproduciendo: %s" % player.is_playing())
		print("    - Actual: '%s'" % player.current_animation)

func _attempt_repairs():
	"""Intentar reparaciones automáticas"""
	print("\n🔧 INTENTANDO REPARACIONES...")
	
	if debug_tool:
		var repaired = debug_tool.repair_animation_system(animation_controls_panel)
		if repaired:
			print("✅ Reparaciones aplicadas")
		else:
			print("ℹ️ No se necesitaron reparaciones")
	
	# Reparaciones adicionales
	_force_reconnect_signals()
	_force_enable_controls()

func _force_reconnect_signals():
	"""Forzar reconexión de señales"""
	print("🔧 Forzando reconexión de señales...")
	
	if not animation_controls_panel:
		return
	
	# Buscar OptionButton y reconectar
	for child in animation_controls_panel.get_children():
		if child is OptionButton:
			var dropdown = child as OptionButton
			
			# Desconectar señales existentes
			if dropdown.item_selected.get_connections().size() > 0:
				print("  - Desconectando señales existentes")
				for connection in dropdown.item_selected.get_connections():
					dropdown.item_selected.disconnect(connection.callable)
			
			# Reconectar si existe el método
			if animation_controls_panel.has_method("_on_animation_selected"):
				print("  - Reconectando _on_animation_selected")
				dropdown.item_selected.connect(animation_controls_panel._on_animation_selected)
			
			# Reconectar otros métodos posibles
			var methods_to_try = ["_on_dropdown_selected", "_change_animation_clean", "_change_animation_async"]
			for method in methods_to_try:
				if animation_controls_panel.has_method(method):
					print("  - Conectando %s" % method)
					dropdown.item_selected.connect(animation_controls_panel.call.bind(method))
					break

func _force_enable_controls():
	"""Forzar habilitación de controles"""
	print("🔧 Forzando habilitación de controles...")
	
	if not animation_controls_panel:
		return
	
	# Habilitar todos los botones y dropdowns
	for child in _get_all_children_recursive(animation_controls_panel):
		if child is Button or child is OptionButton:
			if child.disabled:
				print("  - Habilitando: %s" % child.name)
				child.disabled = false

func _get_all_children_recursive(node: Node) -> Array:
	"""Obtener todos los hijos recursivamente"""
	var children = []
	
	for child in node.get_children():
		children.append(child)
		children.append_array(_get_all_children_recursive(child))
	
	return children

func _test_manual_changes():
	"""Probar cambios manuales de animación"""
	print("\n🧪 PROBANDO CAMBIOS MANUALES...")
	
	if not animation_controls_panel:
		return
	
	# Esperar un poco
	await get_tree().create_timer(1.0).timeout
	
	# Método 1: Simular selección de dropdown
	print("🧪 Test 1: Simular selección de dropdown")
	if debug_tool:
		debug_tool.simulate_dropdown_selection(animation_controls_panel, 1)
	
	await get_tree().create_timer(2.0).timeout
	
	# Método 2: Forzar cambio directo
	print("🧪 Test 2: Forzar cambio directo")
	if debug_tool:
		if animation_controls_panel.has_method("get_available_animations"):
			var anims = animation_controls_panel.get_available_animations()
			if anims.size() > 1:
				debug_tool.force_animation_change(animation_controls_panel, anims[0])
	
	await get_tree().create_timer(2.0).timeout
	
	# Método 3: Usar funciones de test si existen
	print("🧪 Test 3: Funciones de test")
	var test_methods = ["test_change_to_first", "test_change_to_second", "force_play_animation"]
	for method in test_methods:
		if animation_controls_panel.has_method(method):
			print("  - Ejecutando: %s" % method)
			if method == "force_play_animation":
				if animation_controls_panel.has_method("get_available_animations"):
					var anims = animation_controls_panel.get_available_animations()
					if anims.size() > 0:
						animation_controls_panel.call(method, anims[0])
			else:
				animation_controls_panel.call(method)
			
			await get_tree().create_timer(1.0).timeout

# FUNCIONES PÚBLICAS QUE PUEDES LLAMAR DESDE LA CONSOLA

func debug_system():
	"""Función pública para debug manual"""
	if animation_controls_panel and debug_tool:
		debug_tool.debug_animation_system(animation_controls_panel)

func repair_system():
	"""Función pública para reparación manual"""
	if animation_controls_panel and debug_tool:
		debug_tool.repair_animation_system(animation_controls_panel)

func test_animation_change(animation_name: String):
	"""Función pública para probar cambio específico"""
	if animation_controls_panel and debug_tool:
		debug_tool.force_animation_change(animation_controls_panel, animation_name)

func list_available_animations():
	"""Función pública para listar animaciones disponibles"""
	if animation_controls_panel and animation_controls_panel.has_method("get_available_animations"):
		var anims = animation_controls_panel.get_available_animations()
		print("Animaciones disponibles: %s" % str(anims))
		return anims
	else:
		print("No se pueden obtener animaciones")
		return []

# Instrucciones de uso en consola:
func _print_usage_instructions():
	print("""
🔧 INSTRUCCIONES DE USO:
Desde la consola de Godot, puedes usar:

# Debug completo
$YourNode.debug_system()

# Reparar sistema  
$YourNode.repair_system()

# Probar cambio específico
$YourNode.test_animation_change("nombre_animacion")

# Listar animaciones
$YourNode.list_available_animations()

Donde $YourNode es el nodo al que adjuntaste este script.
	""")
