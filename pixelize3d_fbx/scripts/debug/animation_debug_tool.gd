# scripts/debug/animation_debug_tool.gd
# Herramienta de debug para identificar problemas en cambios de animación
# Input: AnimationPlayer y OptionButton de controles
# Output: Debug detallado del estado y problemas

extends Node

# Función para debuggear el estado completo del sistema de animaciones
static func debug_animation_system(animation_controls_panel: Node) -> void:
	print("\n🔍 ===== DEBUG SISTEMA DE ANIMACIONES =====")
	
	if not animation_controls_panel:
		print("❌ animation_controls_panel es NULL")
		return
	
	print("✅ Panel encontrado: %s" % animation_controls_panel.name)
	
	# Debug del estado interno del panel
	_debug_panel_state(animation_controls_panel)
	
	# Debug del dropdown de animaciones
	_debug_dropdown_state(animation_controls_panel)
	
	# Debug del AnimationPlayer
	_debug_animation_player_state(animation_controls_panel)
	
	# Debug de conexiones de señales
	_debug_signal_connections(animation_controls_panel)
	
	print("🔍 ===== FIN DEBUG =====\n")

static func _debug_panel_state(panel: Node) -> void:
	print("\n--- ESTADO DEL PANEL ---")
	
	# Verificar variables internas usando has_meta() para propiedades públicas
	if panel.has_method("get_current_animation"):
		print("Current animation: %s" % panel.get_current_animation())
	
	if panel.has_method("get_available_animations"):
		print("Available animations: %s" % str(panel.get_available_animations()))
	
	if panel.has_method("has_animations"):
		print("Has animations: %s" % panel.has_animations())
	
	# Verificar propiedades directamente accesibles
	var properties_to_check = [
		"current_animation", "available_animations", "is_playing", 
		"current_animation_player", "is_changing_animation"
	]
	
	for prop in properties_to_check:
		if prop in panel:
			print("%s: %s" % [prop, str(panel[prop])])

static func _debug_dropdown_state(panel: Node) -> void:
	print("\n--- ESTADO DEL DROPDOWN ---")
	
	var dropdown = null
	
	# Buscar el dropdown de diferentes formas
	if "animations_option" in panel:
		dropdown = panel["animations_option"]
	else:
		# Buscar en hijos
		for child in panel.get_children():
			if child is OptionButton:
				dropdown = child
				break
	
	if not dropdown:
		print("❌ No se encontró OptionButton")
		return
	
	print("✅ OptionButton encontrado")
	print("  - Disabled: %s" % dropdown.disabled)
	print("  - Selected: %s" % dropdown.selected)
	print("  - Item count: %s" % dropdown.get_item_count())
	
	# Listar todos los items
	for i in range(dropdown.get_item_count()):
		var item_text = dropdown.get_item_text(i)
		var is_selected = (i == dropdown.selected)
		print("  - Item %d: '%s' %s" % [i, item_text, "(SELECTED)" if is_selected else ""])
	
	# Verificar conexiones de señal
	print("  - Señal item_selected conectada: %s" % dropdown.item_selected.get_connections().size())

static func _debug_animation_player_state(panel: Node) -> void:
	print("\n--- ESTADO DEL ANIMATION PLAYER ---")
	
	var anim_player = null
	
	if "current_animation_player" in panel:
		anim_player = panel["current_animation_player"]
	
	if not anim_player:
		print("❌ No hay AnimationPlayer asignado")
		return
	
	print("✅ AnimationPlayer encontrado: %s" % anim_player.name)
	print("  - Is playing: %s" % anim_player.is_playing())
	print("  - Current animation: '%s'" % anim_player.current_animation)
	print("  - Animation list: %s" % str(anim_player.get_animation_list()))
	
	# Debug de cada animación
	for anim_name in anim_player.get_animation_list():
		if anim_player.has_animation(anim_name):
			var anim_lib = anim_player.get_animation_library("")
			var animation = anim_lib.get_animation(anim_name)
			
			if animation:
				print("  - Anim '%s': %.2fs, Loop=%s" % [
					anim_name, 
					animation.length,
					_get_loop_mode_name(animation.loop_mode)
				])

static func _debug_signal_connections(panel: Node) -> void:
	print("\n--- CONEXIONES DE SEÑALES ---")
	
	# Verificar señales del panel
	var signals_to_check = [
		"animation_selected", "animation_changed", "play_requested", 
		"pause_requested", "stop_requested"
	]
	
	for signal_name in signals_to_check:
		if panel.has_signal(signal_name):
			var connections = panel.get_signal_connection_list(signal_name)
			print("  - %s: %d conexiones" % [signal_name, connections.size()])
		else:
			print("  - %s: SEÑAL NO EXISTE" % signal_name)

static func _get_loop_mode_name(loop_mode: int) -> String:
	match loop_mode:
		Animation.LOOP_NONE:
			return "NONE"
		Animation.LOOP_LINEAR:
			return "LINEAR"
		Animation.LOOP_PINGPONG:
			return "PINGPONG"
		_:
			return "UNKNOWN(%d)" % loop_mode

# Función para simular un cambio de animación manualmente
static func force_animation_change(panel: Node, animation_name: String) -> void:
	print("\n🎭 FORZANDO CAMBIO DE ANIMACIÓN: %s" % animation_name)
	
	if not panel:
		print("❌ Panel inválido")
		return
	
	# Intentar diferentes métodos de cambio
	var methods_to_try = [
		"_change_animation_clean",
		"_change_animation_async", 
		"play_animation",
		"force_play_animation"
	]
	
	for method_name in methods_to_try:
		if panel.has_method(method_name):
			print("🔧 Intentando método: %s" % method_name)
			panel.call(method_name, animation_name)
			return
	
	print("❌ No se encontró método para cambiar animación")

# Función para simular selección en dropdown
static func simulate_dropdown_selection(panel: Node, animation_index: int) -> void:
	print("\n🖱️ SIMULANDO SELECCIÓN EN DROPDOWN: índice %d" % animation_index)
	
	var dropdown = null
	if "animations_option" in panel:
		dropdown = panel["animations_option"]
	
	if not dropdown:
		print("❌ No se encontró dropdown")
		return
	
	if animation_index < 0 or animation_index >= dropdown.get_item_count():
		print("❌ Índice fuera de rango")
		return
	
	# Simular selección
	dropdown.selected = animation_index
	print("✅ Dropdown actualizado a índice %d" % animation_index)
	
	# Simular emisión de señal
	if dropdown.item_selected.get_connections().size() > 0:
		print("🔗 Emitiendo señal item_selected")
		dropdown.item_selected.emit(animation_index)
	else:
		print("❌ No hay conexiones para item_selected")
		
		# Intentar llamar manualmente al handler
		if panel.has_method("_on_animation_selected"):
			print("🔧 Llamando _on_animation_selected manualmente")
			panel._on_animation_selected(animation_index)

# Función para verificar y reparar el sistema de animaciones
static func repair_animation_system(panel: Node) -> bool:
	print("\n🔧 REPARANDO SISTEMA DE ANIMACIONES")
	
	if not panel:
		print("❌ Panel inválido")
		return false
	
	var repairs_made = 0
	
	# Reparación 1: Verificar estado de bloqueo
	if "is_changing_animation" in panel and panel["is_changing_animation"]:
		print("🔧 Desbloqueando estado is_changing_animation")
		panel["is_changing_animation"] = false
		repairs_made += 1
	
	# Reparación 2: Habilitar controles si están deshabilitados
	var buttons_to_enable = ["play_button", "pause_button", "stop_button"]
	for button_name in buttons_to_enable:
		if button_name in panel:
			var button = panel[button_name]
			if button and button.disabled:
				print("🔧 Habilitando %s" % button_name)
				button.disabled = false
				repairs_made += 1
	
	# Reparación 3: Verificar dropdown
	if "animations_option" in panel:
		var dropdown = panel["animations_option"]
		if dropdown and dropdown.disabled and dropdown.get_item_count() > 1:
			print("🔧 Habilitando dropdown de animaciones")
			dropdown.disabled = false
			repairs_made += 1
	
	# Reparación 4: Reconectar señales si es necesario
	if "animations_option" in panel:
		var dropdown = panel["animations_option"]
		if dropdown and dropdown.item_selected.get_connections().size() == 0:
			if panel.has_method("_on_animation_selected"):
				print("🔧 Reconectando señal item_selected")
				dropdown.item_selected.connect(panel._on_animation_selected)
				repairs_made += 1
	
	print("🔧 Reparaciones completadas: %d" % repairs_made)
	return repairs_made > 0

# Función para test completo del sistema
static func test_animation_changes(panel: Node) -> void:
	print("\n🧪 PROBANDO CAMBIOS DE ANIMACIÓN")
	
	debug_animation_system(panel)
	
	# Intentar reparar si hay problemas
	repair_animation_system(panel)
	
	# Probar cambio manual
	if "available_animations" in panel:
		var animations = panel["available_animations"]
		if animations and animations.size() > 1:
			var test_anim = animations[1] if animations.size() > 1 else animations[0]
			print("\n🧪 Probando cambio a: %s" % test_anim)
			
			# Método 1: Simular dropdown
			simulate_dropdown_selection(panel, 1)
			
			# Esperar un poco y verificar
			await panel.get_tree().create_timer(0.5).timeout
			
			# Método 2: Forzar cambio directo
			force_animation_change(panel, test_anim)
			
			print("🧪 Test completado")
	
	# Debug final
	print("\n--- ESTADO DESPUÉS DEL TEST ---")
	_debug_panel_state(panel)
	_debug_animation_player_state(panel)
