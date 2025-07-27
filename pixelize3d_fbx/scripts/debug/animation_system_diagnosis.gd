# scripts/debug/animation_system_diagnosis.gd
# Script de diagnóstico COMPLETO para el sistema de animaciones
# Input: Escena ViewerModular
# Output: Diagnóstico detallado y comandos de reparación

extends Node

# Función principal de diagnóstico
static func diagnose_animation_system(viewer_node: Node) -> Dictionary:
	print("\n🔍 === DIAGNÓSTICO COMPLETO DEL SISTEMA DE ANIMACIONES ===")
	
	var report = {
		"problems_found": [],
		"recommendations": [],
		"animation_controls_state": {},
		"model_preview_state": {},
		"coordinator_state": {},
		"animation_players": []
	}
	
	# 1. Encontrar componentes
	var animation_controls = _find_animation_controls(viewer_node)
	var model_preview = _find_model_preview(viewer_node)
	var coordinator = viewer_node  # Asumiendo que el viewer_node ES el coordinator
	
	if not animation_controls:
		report.problems_found.append("❌ AnimationControlsPanel no encontrado")
		return report
	
	if not model_preview:
		report.problems_found.append("❌ ModelPreviewPanel no encontrado")
		return report
	
	print("✅ Componentes encontrados:")
	print("  - AnimationControls: %s" % animation_controls.name)
	print("  - ModelPreview: %s" % model_preview.name)
	
	# 2. Diagnosticar cada componente
	report.animation_controls_state = _diagnose_animation_controls(animation_controls)
	report.model_preview_state = _diagnose_model_preview(model_preview)
	report.coordinator_state = _diagnose_coordinator(coordinator)
	
	# 3. Comparar AnimationPlayers
	var ac_player = _get_animation_player_from_controls(animation_controls)
	var mp_player = _get_animation_player_from_preview(model_preview)
	
	if ac_player and mp_player:
		if ac_player == mp_player:
			print("✅ MISMO AnimationPlayer - Sincronización correcta")
		else:
			report.problems_found.append("❌ DIFERENTES AnimationPlayers detectados")
			print("❌ AnimationControls usa: %s" % ac_player.name)
			print("❌ ModelPreview usa: %s" % mp_player.name)
			
			# Comparar contenido
			_compare_animation_players(ac_player, mp_player, report)
	
	# 4. Probar flujo de cambio de animación
	_test_animation_change_flow(animation_controls, model_preview, report)
	
	# 5. Generar recomendaciones
	_generate_recommendations(report)
	
	print("🔍 === DIAGNÓSTICO COMPLETADO ===\n")
	return report

static func _find_animation_controls(node: Node) -> Node:
	"""Buscar AnimationControlsPanel"""
	if node.name.contains("AnimationControls"):
		return node
	
	for child in node.get_children():
		var result = _find_animation_controls(child)
		if result:
			return result
	
	return null

static func _find_model_preview(node: Node) -> Node:
	"""Buscar ModelPreviewPanel"""
	if node.name.contains("ModelPreview"):
		return node
	
	for child in node.get_children():
		var result = _find_model_preview(child)
		if result:
			return result
	
	return null

static func _diagnose_animation_controls(panel: Node) -> Dictionary:
	"""Diagnosticar estado del AnimationControlsPanel"""
	print("\n🎭 DIAGNÓSTICO ANIMATION CONTROLS:")
	
	var state = {
		"has_dropdown": false,
		"dropdown_enabled": false,
		"dropdown_items": 0,
		"available_animations": [],
		"current_animation": "",
		"current_player": null,
		"buttons_enabled": false,
		"signal_connected": false
	}
	
	# Verificar dropdown
	if "animations_option" in panel:
		var dropdown = panel.animations_option
		state.has_dropdown = true
		state.dropdown_enabled = not dropdown.disabled
		state.dropdown_items = dropdown.get_item_count()
		
		print("  Dropdown:")
		print("    - Habilitado: %s" % state.dropdown_enabled)
		print("    - Items: %d" % state.dropdown_items)
		print("    - Seleccionado: %d" % dropdown.selected)
		
		# Listar items
		for i in range(dropdown.get_item_count()):
			var item_text = dropdown.get_item_text(i)
			print("    - [%d] %s %s" % [i, item_text, "(★)" if i == dropdown.selected else ""])
		
		# Verificar conexión de señal
		state.signal_connected = dropdown.item_selected.get_connections().size() > 0
		print("    - Señal conectada: %s" % state.signal_connected)
	
	# Verificar animaciones disponibles
	if "available_animations" in panel:
		state.available_animations = panel.available_animations.duplicate()
		print("  Animaciones disponibles: %s" % str(state.available_animations))
	
	# Verificar animación actual
	if "current_animation" in panel:
		state.current_animation = panel.current_animation
		print("  Animación actual: '%s'" % state.current_animation)
	
	# Verificar AnimationPlayer
	if "current_animation_player" in panel:
		state.current_player = panel.current_animation_player
		if state.current_player:
			print("  AnimationPlayer: %s" % state.current_player.name)
			print("    - Reproduciendo: %s" % state.current_player.is_playing())
			print("    - Animación actual: '%s'" % state.current_player.current_animation)
		else:
			print("  AnimationPlayer: NULL")
	
	# Verificar botones
	if "play_button" in panel and "pause_button" in panel and "stop_button" in panel:
		state.buttons_enabled = not panel.play_button.disabled
		print("  Botones habilitados: %s" % state.buttons_enabled)
	
	return state

static func _diagnose_model_preview(panel: Node) -> Dictionary:
	"""Diagnosticar estado del ModelPreviewPanel"""
	print("\n🎬 DIAGNÓSTICO MODEL PREVIEW:")
	
	var state = {
		"has_model": false,
		"model_name": "",
		"animation_player": null,
		"preview_active": false
	}
	
	# Verificar modelo actual
	if "current_model" in panel:
		var model = panel.current_model
		if model:
			state.has_model = true
			state.model_name = model.name
			print("  Modelo actual: %s" % state.model_name)
		else:
			print("  Modelo actual: NULL")
	
	# Verificar AnimationPlayer
	if "animation_player" in panel:
		state.animation_player = panel.animation_player
		if state.animation_player:
			print("  AnimationPlayer: %s" % state.animation_player.name)
			print("    - Reproduciendo: %s" % state.animation_player.is_playing())
			print("    - Animación actual: '%s'" % state.animation_player.current_animation)
		else:
			print("  AnimationPlayer: NULL")
	
	# Verificar preview activo
	if "preview_active" in panel:
		state.preview_active = panel.preview_active
		print("  Preview activo: %s" % state.preview_active)
	
	return state

static func _diagnose_coordinator(coordinator: Node) -> Dictionary:
	"""Diagnosticar estado del coordinator"""
	print("\n🔗 DIAGNÓSTICO COORDINATOR:")
	
	var state = {
		"has_combined_model": false,
		"model_name": "",
		"signals_connected": false
	}
	
	# Verificar modelo combinado
	if "current_combined_model" in coordinator:
		var model = coordinator.current_combined_model
		if model:
			state.has_combined_model = true
			state.model_name = model.name
			print("  Modelo combinado: %s" % state.model_name)
		else:
			print("  Modelo combinado: NULL")
	
	return state

static func _get_animation_player_from_controls(panel: Node) -> AnimationPlayer:
	"""Obtener AnimationPlayer del AnimationControlsPanel"""
	if "current_animation_player" in panel:
		return panel.current_animation_player
	return null

static func _get_animation_player_from_preview(panel: Node) -> AnimationPlayer:
	"""Obtener AnimationPlayer del ModelPreviewPanel"""
	if "animation_player" in panel:
		return panel.animation_player
	return null

static func _compare_animation_players(player1: AnimationPlayer, player2: AnimationPlayer, report: Dictionary):
	"""Comparar dos AnimationPlayers"""
	print("\n🆚 COMPARANDO ANIMATION PLAYERS:")
	print("  Player 1: %s" % player1.name)
	print("  Player 2: %s" % player2.name)
	
	var anims1 = player1.get_animation_list()
	var anims2 = player2.get_animation_list()
	
	print("  Animaciones Player 1: %s" % str(anims1))
	print("  Animaciones Player 2: %s" % str(anims2))
	
	if anims1 != anims2:
		report.problems_found.append("❌ Los AnimationPlayers tienen diferentes animaciones")

static func _test_animation_change_flow(controls: Node, preview: Node, report: Dictionary):
	"""Probar el flujo de cambio de animación"""
	print("\n🧪 PROBANDO FLUJO DE CAMBIO DE ANIMACIÓN:")
	
	# Verificar si hay animaciones disponibles
	if not "available_animations" in controls:
		report.problems_found.append("❌ No hay available_animations en controls")
		return
	
	var animations = controls.available_animations
	if animations.size() < 2:
		print("  ⚠️ Se necesitan al menos 2 animaciones para probar")
		return
	
	# Intentar cambio manual
	var test_anim = animations[1] if animations.size() > 1 else animations[0]
	print("  🎯 Probando cambio a: %s" % test_anim)
	
	# Verificar método _change_to_animation
	if controls.has_method("_change_to_animation"):
		print("  ✅ Método _change_to_animation encontrado")
	else:
		report.problems_found.append("❌ Método _change_to_animation no encontrado en controls")
	
	# Verificar método play_animation en preview
	if preview.has_method("play_animation"):
		print("  ✅ Método play_animation encontrado en preview")
	else:
		report.problems_found.append("❌ Método play_animation no encontrado en preview")

static func _generate_recommendations(report: Dictionary):
	"""Generar recomendaciones basadas en problemas encontrados"""
	print("\n💡 RECOMENDACIONES:")
	
	if "❌ DIFERENTES AnimationPlayers detectados" in report.problems_found:
		var rec = "Usar el mismo AnimationPlayer en ambos sistemas (modelo original, no duplicado)"
		report.recommendations.append(rec)
		print("  • " + rec)
	
	if "❌ Método _change_to_animation no encontrado en controls" in report.problems_found:
		var rec = "Implementar método _change_to_animation en AnimationControlsPanel"
		report.recommendations.append(rec)
		print("  • " + rec)
	
	if report.problems_found.is_empty():
		print("  ✅ No se encontraron problemas críticos")

# FUNCIONES DE REPARACIÓN AUTOMÁTICA

static func repair_animation_system(viewer_node: Node) -> bool:
	"""Intentar reparación automática del sistema"""
	print("\n🔧 === INICIANDO REPARACIÓN AUTOMÁTICA ===")
	
	var animation_controls = _find_animation_controls(viewer_node)
	if not animation_controls:
		print("❌ No se puede reparar: AnimationControlsPanel no encontrado")
		return false
	
	var repairs_made = 0
	
	# Reparación 1: Habilitar dropdown si está deshabilitado
	if "animations_option" in animation_controls:
		var dropdown = animation_controls.animations_option
		if dropdown.disabled and dropdown.get_item_count() > 1:
			dropdown.disabled = false
			print("✅ Dropdown habilitado")
			repairs_made += 1
	
	# Reparación 2: Reconectar señales
	if "animations_option" in animation_controls:
		var dropdown = animation_controls.animations_option
		if dropdown.item_selected.get_connections().size() == 0:
			if animation_controls.has_method("_on_animation_selected"):
				dropdown.item_selected.connect(animation_controls._on_animation_selected)
				print("✅ Señal item_selected reconectada")
				repairs_made += 1
	
	# Reparación 3: Habilitar botones
	var buttons = ["play_button", "pause_button", "stop_button"]
	for button_name in buttons:
		if button_name in animation_controls:
			var button = animation_controls[button_name]
			if button.disabled:
				button.disabled = false
				print("✅ Botón %s habilitado" % button_name)
				repairs_made += 1
	
	print("🔧 Reparaciones aplicadas: %d" % repairs_made)
	return repairs_made > 0

# FUNCIÓN DE PRUEBA MANUAL

static func test_animation_change_manual(viewer_node: Node, animation_name: String) -> bool:
	"""Probar cambio de animación manualmente"""
	print("\n🧪 PROBANDO CAMBIO MANUAL A: %s" % animation_name)
	
	var animation_controls = _find_animation_controls(viewer_node)
	var model_preview = _find_model_preview(viewer_node)
	
	if not animation_controls or not model_preview:
		print("❌ Componentes no encontrados")
		return false
	
	# Método 1: Usar AnimationControlsPanel
	if animation_controls.has_method("_change_to_animation"):
		print("🔧 Intentando via AnimationControlsPanel...")
		animation_controls._change_to_animation(animation_name)
	
	# Método 2: Usar ModelPreviewPanel
	if model_preview.has_method("play_animation"):
		print("🔧 Intentando via ModelPreviewPanel...")
		model_preview.play_animation(animation_name)
	
	return true

# FUNCIÓN PARA USAR DESDE LA CONSOLA
static func quick_diagnosis(viewer_node: Node):
	"""Diagnóstico rápido para usar desde la consola"""
	var report = diagnose_animation_system(viewer_node)
	
	print("\n📋 === RESUMEN RÁPIDO ===")
	print("Problemas encontrados: %d" % report.problems_found.size())
	for problem in report.problems_found:
		print("  " + problem)
	
	print("\nRecomendaciones: %d" % report.recommendations.size())
	for rec in report.recommendations:
		print("  • " + rec)
	
	print("\n🔧 ¿Intentar reparación automática? Usa:")
	print("  repair_animation_system($ViewerModular)")
