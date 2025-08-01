# pixelize3d_fbx/scripts/debug/animation_monitor.gd
# Monitor en tiempo real de animaciones activas en el sistema
# Input: Nodo raíz de la escena
# Output: Reporte en tiempo real de animaciones reproduciendo

extends Node
class_name AnimationMonitor

# Variables de estado
var monitoring_enabled: bool = false
var update_interval: float = 1.0  # Actualizar cada segundo
var timer: Timer

signal animations_status_changed(active_count: int, total_count: int)

func _ready():
	# Configurar timer para monitoreo automático
	timer = Timer.new()
	timer.wait_time = update_interval
	timer.timeout.connect(_monitor_animations)
	add_child(timer)

# ========================================================================
# FUNCIONES PÚBLICAS DE MONITOREO
# ========================================================================

func start_monitoring(interval: float = 1.0):
	"""Iniciar monitoreo automático de animaciones"""
	update_interval = interval
	timer.wait_time = interval
	monitoring_enabled = true
	timer.start()
	print("🔍 Monitor de animaciones iniciado (cada %.1fs)" % interval)

func stop_monitoring():
	"""Detener monitoreo automático"""
	monitoring_enabled = false
	timer.stop()
	print("🔍 Monitor de animaciones detenido")

func get_animations_snapshot() -> Dictionary:
	"""Obtener snapshot actual de todas las animaciones"""
	var all_players = _find_all_animation_players()
	var snapshot = {
		"timestamp": Time.get_time_dict_from_system(),
		"total_players": all_players.size(),
		"active_players": 0,
		"players_detail": []
	}
	
	for player in all_players:
		var player_info = _get_player_info(player)
		snapshot.players_detail.append(player_info)
		
		if player_info.is_playing:
			snapshot.active_players += 1
	
	return snapshot

func print_current_status():
	"""Imprimir estado actual de todas las animaciones"""
	var snapshot = get_animations_snapshot()
	
	print("\n🎬 === ESTADO DE ANIMACIONES ===")
	print("⏰ Timestamp: %02d:%02d:%02d" % [
		snapshot.timestamp.hour,
		snapshot.timestamp.minute, 
		snapshot.timestamp.second
	])
	print("📊 Total AnimationPlayers: %d" % snapshot.total_players)
	print("▶️ Animaciones activas: %d" % snapshot.active_players)
	print("⏸️ Animaciones inactivas: %d" % (snapshot.total_players - snapshot.active_players))
	
	print("\n📋 DETALLE POR PLAYER:")
	for player_info in snapshot.players_detail:
		var status_icon = "▶️" if player_info.is_playing else "⏸️"
		print("  %s %s (%s)" % [status_icon, player_info.name, player_info.path])
		
		if player_info.is_playing:
			print("      🎭 Animación: '%s'" % player_info.current_animation)
			print("      ⏱️ Posición: %.2fs / %.2fs" % [player_info.position, player_info.length])
			print("      🔄 Progress: %.1f%%" % (player_info.progress * 100))
		
		if player_info.animations.size() > 0:
			print("      📚 Disponibles: %s" % str(player_info.animations))
	
	print("===============================\n")

func get_active_animations_count() -> int:
	"""Obtener solo el número de animaciones activas"""
	var count = 0
	var all_players = _find_all_animation_players()
	
	for player in all_players:
		if player.is_playing():
			count += 1
	
	return count

func get_detailed_active_animations() -> Array:
	"""Obtener lista detallada de animaciones activas"""
	var active_animations = []
	var all_players = _find_all_animation_players()
	
	for player in all_players:
		if player.is_playing():
			active_animations.append({
				"player_name": player.name,
				"player_path": player.get_path(),
				"animation_name": player.current_animation,
				"position": player.current_animation_position,
				"progress": _get_animation_progress(player)
			})
	
	return active_animations

# ========================================================================
# FUNCIONES DE MONITOREO AUTOMÁTICO
# ========================================================================

func _monitor_animations():
	"""Función llamada automáticamente por el timer"""
	if not monitoring_enabled:
		return
	
	var active_count = get_active_animations_count()
	var total_count = _find_all_animation_players().size()
	
	# Emitir señal con el estado actual
	emit_signal("animations_status_changed", active_count, total_count)
	
	# Log opcional (puedes comentar si no quieres spam)
	print("🔍 Monitor: %d/%d animaciones activas" % [active_count, total_count])

# ========================================================================
# FUNCIONES AUXILIARES
# ========================================================================

func _find_all_animation_players() -> Array:
	"""Encontrar todos los AnimationPlayers en la escena"""
	var players = []
	_recursive_find_animation_players(get_tree().root, players)
	return players

func _recursive_find_animation_players(node: Node, players: Array):
	"""Búsqueda recursiva de AnimationPlayers"""
	if node is AnimationPlayer:
		players.append(node)
	
	for child in node.get_children():
		_recursive_find_animation_players(child, players)

func _get_player_info(player: AnimationPlayer) -> Dictionary:
	"""Obtener información detallada de un AnimationPlayer"""
	var info = {
		"name": player.name,
		"path": str(player.get_path()),
		"is_playing": player.is_playing(),
		"current_animation": player.current_animation,
		"position": 0.0,
		"length": 0.0,
		"progress": 0.0,
		"animations": player.get_animation_list()
	}
	
	if player.is_playing() and player.current_animation != "":
		info.position = player.current_animation_position
		
		var anim = player.get_animation(player.current_animation)
		if anim:
			info.length = anim.length
			info.progress = info.position / info.length if info.length > 0 else 0.0
	
	return info

func _get_animation_progress(player: AnimationPlayer) -> float:
	"""Obtener progreso de la animación actual (0.0 - 1.0)"""
	if not player.is_playing() or player.current_animation == "":
		return 0.0
	
	var anim = player.get_animation(player.current_animation)
	if not anim or anim.length <= 0:
		return 0.0
	
	return player.current_animation_position / anim.length

# ========================================================================
# FUNCIONES DE CONVENIENCIA PARA USO EN CONSOLA
# ========================================================================

func quick_scan():
	"""Función rápida para usar en consola"""
	print_current_status()

func start_monitor():
	"""Función rápida para iniciar monitoreo"""
	start_monitoring(1.0)

func stop_monitor():
	"""Función rápida para detener monitoreo"""
	stop_monitoring()

func count():
	"""Función rápida para obtener conteo"""
	var active = get_active_animations_count()
	var total = _find_all_animation_players().size()
	print("🎬 Animaciones: %d activas / %d total" % [active, total])
	return active
