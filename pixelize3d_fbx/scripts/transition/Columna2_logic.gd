# res://scripts/transition/Columna2_logic.gd
# Lógica de preview de animaciones para la Columna 2
# Input: Datos de animaciones desde Columna 1
# Output: Control de reproducción y actualización de viewports

extends Node
class_name Columna2Logic

# === SEÑALES HACIA EL COORDINADOR ===
signal preview_ready(preview_data: Dictionary)
signal playback_state_changed(animation_type: String, state: Dictionary)

# === REFERENCIAS ===
var coordinator: Node
var ui_node: Columna2UI

# === DATOS DE ANIMACIONES ===
var animation_a_data: Dictionary = {}
var animation_b_data: Dictionary = {}
var animation_a_model: Node3D
var animation_b_model: Node3D
var animation_player_a: AnimationPlayer
var animation_player_b: AnimationPlayer

# === VIEWPORTS ===
var viewport_a: SubViewport
var viewport_b: SubViewport

# === ESTADO DE REPRODUCCIÓN ===
var playback_state_a: Dictionary = {
	"playing": false,
	"current_frame": 0,
	"total_frames": 0,
	"duration": 0.0,
	"animation_name": "",
	"loop_enabled": true
}

var playback_state_b: Dictionary = {
	"playing": false,
	"current_frame": 0,
	"total_frames": 0,
	"duration": 0.0,
	"animation_name": "",
	"loop_enabled": true
}

# === PROCESO DE ACTUALIZACIÓN ===
var update_timer: Timer

func _ready():
	print("🎬 Columna2Logic inicializando...")
	_setup_systems()
	_create_update_timer()
	print("✅ Columna2Logic listo")

func _setup_systems():
	"""Configurar referencias a sistemas"""
	# Buscar coordinador
	coordinator = get_parent()
	
	# Buscar UI node
	var columna2_container = get_node_or_null("../HSplitContainer/HSplitContainer/Columna2_Container")
	if columna2_container:
		ui_node = columna2_container.get_node_or_null("Columna2_UI")
		if ui_node:
			_connect_ui_signals()
			print("  ✅ UI conectada")

func _connect_ui_signals():
	"""Conectar señales de la UI"""
	if not ui_node:
		return
		
	ui_node.play_animation_a_requested.connect(_on_play_animation_a)
	ui_node.pause_animation_a_requested.connect(_on_pause_animation_a)
	ui_node.play_animation_b_requested.connect(_on_play_animation_b)
	ui_node.pause_animation_b_requested.connect(_on_pause_animation_b)
	
	print("  🔌 Señales UI conectadas")

func _create_update_timer():
	"""Crear timer para actualizar estados"""
	update_timer = Timer.new()
	update_timer.wait_time = 0.033  # ~30 FPS
	update_timer.timeout.connect(_update_playback_states)
	add_child(update_timer)

# ========================================================================
# API PRINCIPAL - CARGA DE DATOS
# ========================================================================

func load_animations_data(anim_a: Dictionary, anim_b: Dictionary):
	print("func load_animations_data")
	"""Cargar datos de animaciones desde Columna 1"""
	print("📥 Columna2Logic: Cargando datos de animaciones...")
	

	
	# Guardar datos
	animation_a_data = anim_a
	animation_b_data = anim_b
	
	# Obtener nombres de animación del array animations
	var anim_name_a = animation_a_data.name
	var anim_name_b = animation_b_data.name
		
	print("  📊 Datos recibidos:")
	print("    - Animación A: %s" % anim_name_a)
	print("    - Animación B: %s" % anim_name_b)

	
	# Configurar viewports
	_setup_viewports()
	
	# Crear modelos en viewports
	await _create_models_in_viewports()
	
	# Configurar estados de reproducción
	_configure_playback_states()
	
	# Actualizar UI
	if ui_node:
		ui_node.on_animations_loaded(animation_a_data, animation_b_data)
	
	# Notificar que el preview está listo
	emit_signal("preview_ready", {
		"animation_a_ready": animation_a_data != null,
		"animation_b_ready": animation_b_data != null
	})
	
	print("✅ Datos de animaciones cargados y configurados")

func _setup_viewports():
	"""Obtener referencias a los viewports desde la UI"""
	if ui_node:
		viewport_a = ui_node.get_viewport_a()
		viewport_b = ui_node.get_viewport_b()
		print("  🖼️ Viewports obtenidos de la UI")
		
		# Verificar que los viewports tengan cámara y luz
		if viewport_a:
			var has_camera = false
			var has_light = false
			for child in viewport_a.get_children():
				if child is Camera3D:
					has_camera = true
				if child is DirectionalLight3D:
					has_light = true
			if not has_camera or not has_light:
				print("  ⚠️ Viewport A necesita cámara/luz - usando existentes de la escena")

func _create_models_in_viewports():
	"""Configurar modelos en los viewports existentes"""
	print("🎭 Configurando modelos en viewports...")
	
	# NO limpiar viewports - usar los existentes con sus cámaras y luces
	
	# Configurar viewport A
	if viewport_a:
		await _setup_viewport_with_model(viewport_a, animation_a_data, "A")
	
	# Configurar viewport B
	if viewport_b:
		await _setup_viewport_with_model(viewport_b, animation_b_data, "B")
	
	print("✅ Modelos configurados en viewports")

func _clear_viewport(viewport: SubViewport):
	"""Limpiar contenido de un viewport"""
	if not viewport:
		return
		
	for child in viewport.get_children():
		child.queue_free()

func _setup_viewport_with_model(viewport: SubViewport, anim_data: Dictionary, id: String):
	"""Agregar modelo al viewport existente sin modificar cámara y luz"""
	print("func _setup_viewport_with_model")
	print("viewport")
	print(viewport)
	print("anim_data")
	print(anim_data)
	print("id")
	print(id)
	if not viewport:
		return
	
	print("  🔧 Configurando modelo en viewport %s..." % id)
	
	# Buscar y limpiar solo modelos anteriores (no cámara ni luz)
	#for child in viewport.get_children():
		#if child.name.begins_with("Model_") :
			#print("    🗑️ Removiendo modelo anterior: %s" % child.name)
			#child.queue_free()
	
	await get_tree().process_frame
	
	var skeleton = anim_data.get("skeleton")
	var skeleton_copy = skeleton.duplicate()
	skeleton_copy.position = Vector3.ZERO
	var original_player = anim_data.get("animation_player")
	var anim_player = original_player.duplicate()
	anim_player.name = "AnimationPlayer_" + id
	if id == "A":
		#var model_container = find_child("/../../%Model_A")
		#var model_container = find_child("/../%Model_A")
		var model_container = get_parent().get_node("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/SubViewportContainer_A/SubViewport_A/Model_A")
		print("model_container_A")
		print(model_container)
		#viewport.add_child(model_container)
		model_container.add_child(skeleton_copy)
		print("    ✅ Skeleton_A agregado")
		model_container.add_child(anim_player)
		animation_a_model = model_container
		animation_player_a = anim_player
		animation_a_model.position = Vector3(0, 0, 0)
		animation_a_model.scale = Vector3.ONE
		print("    ✅ Modelo A configurado con AnimationPlayer")
	else:
		#var model_container = find_child("/../../%Model_B")
		var model_container = get_parent().get_node("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/SubViewportContainer_B/SubViewport_B/Model_B")
		print("model_container_B")
		print(model_container)
		#viewport.add_child(model_container)
		model_container.add_child(skeleton_copy)
		print("    ✅ Skeleton_B agregado")
		model_container.add_child(anim_player)
		animation_b_model = model_container
		animation_player_b = anim_player
		animation_b_model.position = Vector3(0, 0, 0)
		animation_b_model.scale = Vector3.ONE
		print("    ✅ Modelo B configurado con AnimationPlayer")
		
		
	# Crear un nodo contenedor para el modelo
	## Duplicar skeleton si existe
	#var skeleton = anim_data.get("skeleton")
	#if skeleton:
		#var skeleton_copy = skeleton.duplicate()
		#skeleton_copy.position = Vector3.ZERO
		#if id == "A":
			#model_container.add_child(skeleton_copy)
		#else:
			#model_container.add_child(skeleton_copy)
		#print("    ✅ Skeleton agregado")
	#
	# Duplicar y configurar AnimationPlayer
	
	#if original_player:
#
		#if id == "A":
			#model_container.add_child(anim_player)
		#else:
			#model_container.add_child(anim_player)
		## Verificar y configurar animaciones
		#var animations = anim_data.get("animations", [])
		#if animations.size() > 0:
			#var anim_name = animations[0]
			#print("    🎬 Animación disponible: %s" % anim_name)
			#
			# Copiar las animaciones del player original
			#if original_player.has_animation_library(""):
				#var lib = original_player.get_animation_library("")
				#if lib:
					#var new_lib = AnimationLibrary.new()
					#for anim in lib.get_animation_list():
						#new_lib.add_animation(anim, lib.get_animation(anim))
					#anim_player.add_animation_library("", new_lib)
					#print("    ✅ Biblioteca de animaciones copiada")
		
		# Guardar referencias
		#if id == "A":
			#animation_a_model = model_container_A
			#animation_player_a = anim_player
			#animation_a_model.position = Vector3(0, 0, 0)
			#animation_a_model.scale = Vector3.ONE
			#print("    ✅ Modelo A configurado con AnimationPlayer")
		#else:
			#animation_b_model = model_container_B
			#animation_player_b = anim_player
			#animation_b_model.position = Vector3(0, 0, 0)
			#animation_b_model.scale = Vector3.ONE
			#print("    ✅ Modelo B configurado con AnimationPlayer")
	
	# Ajustar posición y escala del modelo
	#model_container.position = Vector3(0, 0, 0)
	#model_container.scale = Vector3.ONE
	
	# Esperar un frame para asegurar que todo esté listo
	await get_tree().process_frame

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer en el nodo o sus hijos"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _configure_playback_states():
	print("func _configure_playback_states():
")
	"""Configurar estados iniciales de reproducción"""
	print("⚙️ Configurando estados de reproducción...")
	
	# Configurar estado A
	var anim_name_a = animation_a_data.get("display_name", "")
	print("anim_name_a")
	print(anim_name_a)
	
	#if anim_name_a == "" and animation_a_data.has("animations") and animation_a_data.animations.size() > 0:
		#anim_name_a = animation_a_data.display_name
	
	if animation_player_a and anim_name_a != "":
		playback_state_a.animation_name = anim_name_a
		print("playback_state_a.animation_name")
		print(playback_state_a.animation_name)
		
		# Buscar en la biblioteca de animaciones
		#if animation_player_a.has_animation_library(""):
			#var lib = animation_player_a.get_animation_library("")
			#if lib and lib.has_animation(anim_name_a):
				#var anim = lib.get_animation(anim_name_a)
				#playback_state_a.duration = anim.length
				#playback_state_a.total_frames = int(anim.length * 30)  # Asumiendo 30 FPS
				#print("  ✅ Estado A configurado: %s (%.2fs)" % [anim_name_a, anim.length])
	
	# Configurar estado B
	var anim_name_b = animation_b_data.get("display_name", "")
	#if anim_name_b == "" and animation_b_data.has("animations") and animation_b_data.animations.size() > 0:
		#anim_name_b = animation_b_data.display_name
	
	if animation_player_b and anim_name_b != "":
		playback_state_b.animation_name = anim_name_b
		print("playback_state_b.animation_name")
		print(playback_state_b.animation_name)
		
		# Buscar en la biblioteca de animaciones
		#if animation_player_b.has_animation_library(""):
			#var lib = animation_player_b.get_animation_library("")
			#if lib and lib.has_animation(anim_name_b):
				#var anim = lib.get_animation(anim_name_b)
				#playback_state_b.duration = anim.length
				#playback_state_b.total_frames = int(anim.length * 30)  # Asumiendo 30 FPS
				#print("  ✅ Estado B configurado: %s (%.2fs)" % [anim_name_b, anim.length])

# ========================================================================
# CONTROL DE REPRODUCCIÓN
# ========================================================================

func _on_play_animation_a():
	print("func _on_play_animation_a():")
	"""Iniciar reproducción de animación A"""
	#if not animation_player_a or playback_state_a.animation_name == "":
		#print("  ⚠️ No se puede reproducir animación A")
		#return
	#
	print("▶ Reproduciendo animación A: %s" % playback_state_a.animation_name)
	
	# Usar el nombre con el prefijo de la biblioteca si es necesario
	var anim_to_play = playback_state_a.animation_name
	print("anim_to_play")
	print(anim_to_play)
	print("00000000000000000000000000000000playback_state_a")
	print(playback_state_a)
	
	#if animation_player_a.has_animation_library(""):
		#var lib = animation_player_a.get_animation_library("")
		#if lib and lib.has_animation(anim_to_play):
			## Si la animación está en la biblioteca por defecto, agregar prefijo
			#anim_to_play = anim_to_play  # La biblioteca "" no necesita prefijo
	
	animation_player_a.play(anim_to_play)
	playback_state_a.playing = true
	
	
	# Iniciar actualización de estados
	if not update_timer.is_stopped():
		update_timer.stop()
	update_timer.start()
	
	_emit_playback_state("animation_a")

func _on_pause_animation_a():
	"""Pausar animación A"""
	if animation_player_a:
		print("⏸ Pausando animación A")
		animation_player_a.pause()
		playback_state_a.playing = false
		_emit_playback_state("animation_a")

func _on_play_animation_b():
	"""Iniciar reproducción de animación B"""
	print("func _on_play_animation_b():")
	if not animation_player_b or playback_state_b.animation_name == "":
		print("  ⚠️ No se puede reproducir animación B")
		return
	
	print("▶ Reproduciendo animación B: %s" % playback_state_b.animation_name)
	
	# Usar el nombre con el prefijo de la biblioteca si es necesario
	var anim_to_play = playback_state_b.animation_name
	print("anim_to_play")
	print(anim_to_play)
	#if animation_player_b.has_animation_library(""):
		#var lib = animation_player_b.get_animation_library("")
		#if lib and lib.has_animation(anim_to_play):
			## Si la animación está en la biblioteca por defecto, agregar prefijo
			#anim_to_play = anim_to_play  # La biblioteca "" no necesita prefijo
	
	animation_player_b.play(anim_to_play)
	playback_state_b.playing = true
	
	# Iniciar actualización de estados
	if not update_timer.is_stopped():
		update_timer.stop()
	update_timer.start()
	
	_emit_playback_state("animation_b")

func _on_pause_animation_b():
	"""Pausar animación B"""
	if animation_player_b:
		print("⏸ Pausando animación B")
		animation_player_b.pause()
		playback_state_b.playing = false
		_emit_playback_state("animation_b")

# ========================================================================
# ACTUALIZACIÓN DE ESTADOS
# ========================================================================

func _update_playback_states():
	"""Actualizar estados de reproducción"""
	var any_playing = false
	
	# Actualizar estado A
	if animation_player_a and playback_state_a.playing:
		if animation_player_a.is_playing():
			var current_pos = animation_player_a.current_animation_position
			playback_state_a.current_frame = int(current_pos * 30)
			_emit_playback_state("animation_a")
			any_playing = true
		else:
			# Animación terminó
			playback_state_a.playing = false
			playback_state_a.current_frame = 0
			_emit_playback_state("animation_a")
	
	# Actualizar estado B
	if animation_player_b and playback_state_b.playing:
		if animation_player_b.is_playing():
			var current_pos = animation_player_b.current_animation_position
			playback_state_b.current_frame = int(current_pos * 30)
			_emit_playback_state("animation_b")
			any_playing = true
		else:
			# Animación terminó
			playback_state_b.playing = false
			playback_state_b.current_frame = 0
			_emit_playback_state("animation_b")
	
	# Detener timer si no hay animaciones reproduciéndose
	if not any_playing:
		update_timer.stop()

func _emit_playback_state(animation_type: String):
	"""Emitir estado de reproducción actualizado"""
	var state = playback_state_a if animation_type == "animation_a" else playback_state_b
	emit_signal("playback_state_changed", animation_type, state)

# ========================================================================
# API PÚBLICA
# ========================================================================

func get_animation_a_state() -> Dictionary:
	"""Obtener estado de animación A"""
	return playback_state_a.duplicate()

func get_animation_b_state() -> Dictionary:
	"""Obtener estado de animación B"""
	return playback_state_b.duplicate()

func get_preview_data() -> Dictionary:
	"""Obtener datos de preview"""
	return {
		"animation_a": {
			"loaded": animation_a_model != null,
			"playing": playback_state_a.playing,
			"animation_name": playback_state_a.animation_name
		},
		"animation_b": {
			"loaded": animation_b_model != null,
			"playing": playback_state_b.playing,
			"animation_name": playback_state_b.animation_name
		}
	}

# ========================================================================
# DEBUG
# ========================================================================

func debug_system_status():
	"""Debug del estado del sistema"""
	print("=== DEBUG COLUMNA2 LOGIC ===")
	print("Viewports:")
	print("  - Viewport A: %s" % (viewport_a != null))
	print("  - Viewport B: %s" % (viewport_b != null))
	print("Modelos cargados:")
	print("  - Modelo A: %s" % (animation_a_model != null))
	print("  - Modelo B: %s" % (animation_b_model != null))
	print("AnimationPlayers:")
	print("  - Player A: %s" % (animation_player_a != null))
	print("  - Player B: %s" % (animation_player_b != null))
	print("Animaciones:")
	print("  - Animación A: %s" % playback_state_a.animation_name)
	print("  - Animación B: %s" % playback_state_b.animation_name)
	print("Estados de reproducción:")
	print("  - A: %s (Frame %d/%d)" % [
		"Playing" if playback_state_a.playing else "Stopped",
		playback_state_a.current_frame,
		playback_state_a.total_frames
	])
	print("  - B: %s (Frame %d/%d)" % [
		"Playing" if playback_state_b.playing else "Stopped",
		playback_state_b.current_frame,
		playback_state_b.total_frames
	])
	print("============================")
