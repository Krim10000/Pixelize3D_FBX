# scripts/viewer/ui/animation_controls_panel.gd
# Panel CORREGIDO con mejor manejo de estados y timeouts
# Input: Modelo con AnimationPlayer desde populate_animations()
# Output: Control completo de animaciones sin bloqueos

extends HBoxContainer

# Señales
signal animation_selected(animation_name: String)
signal animation_change_requested(animation_name: String)
signal play_requested(animation_name: String) 
signal pause_requested()
signal stop_requested()
signal timeline_changed(position: float)
signal animation_deselected()

# UI elements
var animations_option: OptionButton
var prev_button: Button
var play_button: Button
var stop_button: Button
var next_button: Button
var timeline_slider: HSlider
var animation_counter_label: Label
var time_label: Label

# Estado interno
var available_animations: Array = []
var animation_display_names: Array = []
var current_animation_player: AnimationPlayer = null
var is_playing: bool = false
var current_animation: String = ""
var current_animation_index: int = -1

# Control de re-combinación y timeout
var is_waiting_for_recombination: bool = false
var recombination_timeout_timer: Timer
var last_requested_animation: String = ""

# Loop manager
var loop_manager: AnimationLoopManager

func _ready():
	loop_manager = AnimationLoopManager.new()
	add_child(loop_manager)
	
	_create_ui()
	_setup_timeout_timer()
	print("🎮 AnimationControlsPanel CORREGIDO inicializado")

func _setup_timeout_timer():
	"""Configurar timer para timeout de re-combinación"""
	recombination_timeout_timer = Timer.new()
	recombination_timeout_timer.wait_time = 5.0  # ✅ Reducido de 10s a 5s
	recombination_timeout_timer.one_shot = true
	recombination_timeout_timer.timeout.connect(_on_recombination_timeout)
	add_child(recombination_timeout_timer)

func _create_ui():
	# Label de animación
	var anim_label = Label.new()
	anim_label.text = "Animación:"
	add_child(anim_label)
	
	# Dropdown de animaciones
	animations_option = OptionButton.new()
	animations_option.custom_minimum_size.x = 200
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
	animations_option.item_selected.connect(_on_animation_selected)
	add_child(animations_option)
	
	add_child(VSeparator.new())
	
	# Botón anterior
	prev_button = Button.new()
	prev_button.text = "⏮️"
	prev_button.tooltip_text = "Animación anterior"
	prev_button.disabled = true
	prev_button.pressed.connect(_on_prev_animation)
	add_child(prev_button)
	
	# Botón play/pause
	play_button = Button.new()
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	play_button.disabled = true
	play_button.pressed.connect(_on_play_pause_pressed)
	add_child(play_button)
	
	# Botón stop
	stop_button = Button.new()
	stop_button.text = "⏹️"
	stop_button.tooltip_text = "Detener"
	stop_button.disabled = true
	stop_button.pressed.connect(_on_stop_pressed)
	add_child(stop_button)
	
	# Botón siguiente
	next_button = Button.new()
	next_button.text = "⏭️"
	next_button.tooltip_text = "Siguiente animación"
	next_button.disabled = true
	next_button.pressed.connect(_on_next_animation)
	add_child(next_button)
	
	add_child(VSeparator.new())
	
	# Timeline
	timeline_slider = HSlider.new()
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.step = 0.01
	timeline_slider.custom_minimum_size.x = 200
	timeline_slider.editable = false
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# Contador de animaciones
	animation_counter_label = Label.new()
	animation_counter_label.text = "-/-"
	animation_counter_label.custom_minimum_size.x = 40
	animation_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(animation_counter_label)
	
	# Label de tiempo
	time_label = Label.new()
	time_label.text = "0.0s"
	time_label.custom_minimum_size.x = 80
	add_child(time_label)

# === POBLACIÓN DE ANIMACIONES ===

func populate_animations(model: Node3D):
	"""✅ MEJORADO: Poblar lista de animaciones desde modelo"""
	print("🎮 Poblando animaciones desde modelo: %s" % model.name)
	
	reset_controls()
	
	# Buscar AnimationPlayer
	current_animation_player = _find_animation_player(model)
	
	if not current_animation_player:
		print("❌ No se encontró AnimationPlayer en el modelo")
		animations_option.add_item("-- No hay animaciones --")
		animations_option.disabled = true
		return
	
	# Obtener lista de animaciones
	available_animations = current_animation_player.get_animation_list()
	animation_display_names.clear()
	
	if available_animations.is_empty():
		print("❌ AnimationPlayer no tiene animaciones")
		animations_option.add_item("-- No hay animaciones --")
		animations_option.disabled = true
		return
	
	print("✅ Encontradas %d animaciones" % available_animations.size())
	
	# Configurar loops infinitos
	loop_manager.setup_infinite_loops(current_animation_player)
	
	# Obtener metadatos si existen
	var all_metadata = {}
	if model.has_meta("all_animations_metadata"):
		all_metadata = model.get_meta("all_animations_metadata")
	
	# Crear nombres descriptivos
	for anim_name in available_animations:
		var display_name = anim_name
		
		if anim_name in all_metadata:
			var metadata = all_metadata[anim_name]
			if metadata.has("filename"):
				display_name = _extract_display_name(metadata["filename"])
			elif metadata.has("display_name"):
				display_name = metadata["display_name"]
		else:
			display_name = _clean_animation_name_fallback(anim_name)
		
		animation_display_names.append(display_name)
		print("  • %s → %s" % [anim_name, display_name])
	
	# Actualizar dropdown
	_update_animations_dropdown()
	
	# Habilitar controles
	_enable_controls()
	
	# ✅ NO auto-seleccionar para evitar conflictos
	print("✅ Controles poblados - esperando selección del usuario")

func update_animations_list(animation_files: Array):
	"""✅ MEJORADO: Actualizar lista basada en archivos"""
	animations_option.clear()
	animations_option.add_item("-- Seleccionar animación --")
	
	available_animations = animation_files
	animation_display_names.clear()
	
	if animation_files.is_empty():
		animations_option.disabled = true
		_disable_all_controls()
		return
	
	# Crear nombres desde archivos
	for file_path in animation_files:
		var display_name = file_path.get_file().get_basename()
		display_name = _clean_animation_name_fallback(display_name)
		animation_display_names.append(display_name)
		animations_option.add_item(display_name)
	
	animations_option.disabled = false
	_enable_controls()

func select_animation_by_name(animation_name: String):
	"""✅ MEJORADO: Seleccionar animación por nombre"""
	for i in range(available_animations.size()):
		var anim = available_animations[i]
		if anim == animation_name or anim.get_file().get_basename() == animation_name:
			animations_option.selected = i + 1  # +1 por la opción "Seleccionar"
			_on_animation_selected(i + 1)
			return
	
	print("⚠️ Animación no encontrada: %s" % animation_name)

# === MANEJADORES DE EVENTOS ===

func _on_animation_selected(dropdown_index: int):
	"""✅ MEJORADO: Manejar selección con mejor feedback"""
	print("🎭 Selección en dropdown - índice: %d" % dropdown_index)
	
	if dropdown_index <= 0:
		_deselect_animation()
		return
	
	var anim_index = dropdown_index - 1
	if anim_index >= available_animations.size():
		print("❌ Índice fuera de rango")
		return
	
	current_animation_index = anim_index
	var selected_animation = available_animations[anim_index]
	
	print("📡 Solicitando cambio a: %s" % selected_animation)
	
	# Preparar UI para cambio
	_prepare_ui_for_animation_change(selected_animation)
	
	# Emitir señales
	emit_signal("animation_selected", selected_animation)
	emit_signal("animation_change_requested", selected_animation)

func _prepare_ui_for_animation_change(animation_name: String):
	"""✅ MEJORADO: Preparar UI con mejor feedback"""
	current_animation = animation_name
	last_requested_animation = animation_name
	is_waiting_for_recombination = true
	
	# UI de carga mejorada
	play_button.text = "⏳"
	play_button.tooltip_text = "Cargando: " + animation_display_names[current_animation_index]
	play_button.disabled = true
	stop_button.disabled = true
	timeline_slider.editable = false
	
	timeline_slider.value = 0.0
	time_label.text = "Cargando..."
	
	# Iniciar timeout
	recombination_timeout_timer.start()
	
	_update_counter_display()

func on_model_recombined(new_model: Node3D, animation_name: String):
	"""✅ MEJORADO: Callback cuando el modelo está listo"""
	print("✅ Modelo listo para: %s" % animation_name)
	
	# Detener timeout
	if not recombination_timeout_timer.is_stopped():
		recombination_timeout_timer.stop()
	
	# Verificar que es la animación esperada
	if animation_name != last_requested_animation and last_requested_animation != "":
		print("⚠️ Recibido '%s' pero esperábamos '%s'" % [animation_name, last_requested_animation])
	
	# Actualizar AnimationPlayer si es necesario
	var new_player = _find_animation_player(new_model)
	if new_player and new_player != current_animation_player:
		current_animation_player = new_player
		loop_manager.setup_infinite_loops(current_animation_player)
	
	# Completar cambio
	_on_animation_change_completed(animation_name)

#func _on_animation_change_completed(animation_name: String):
	#"""✅ MEJORADO: Finalizar cambio de animación"""
	#print("✅ Cambio completado: %s" % animation_name)
	#
	## Limpiar estado de espera
	#is_waiting_for_recombination = false
	#last_requested_animation = ""
	#
	## Restaurar controles
	#is_playing = true
	#play_button.text = "⏸️"
	#play_button.tooltip_text = "Pausar"
	#play_button.disabled = false
	#stop_button.disabled = false
	#timeline_slider.editable = true
	#
	## Actualizar timeline
	#if current_animation_player and current_animation_player.has_animation(animation_name):
		#var animation = current_animation_player.get_animation(animation_name)
		#timeline_slider.max_value = animation.length
		#timeline_slider.value = 0.0
		#time_label.text = "0.0s / %.1fs" % animation.length
	#
	#_update_counter_display()

func _on_recombination_timeout():
	"""✅ MEJORADO: Manejar timeout con recuperación"""
	if is_waiting_for_recombination:
		print("⏰ Timeout en cambio de animación")
		
		# Intentar reproducir directamente si tenemos el player
		if current_animation_player and current_animation_player.has_animation(last_requested_animation):
			print("🔧 Intentando reproducción directa...")
			current_animation_player.play(last_requested_animation)
			_on_animation_change_completed(last_requested_animation)
		else:
			_reset_ui_on_error("Timeout al cambiar animación")

func _reset_ui_on_error(error_msg: String = "Error"):
	"""✅ MEJORADO: Reset con mejor feedback"""
	print("❌ Error: %s" % error_msg)
	
	# Detener timeout si está activo
	if not recombination_timeout_timer.is_stopped():
		recombination_timeout_timer.stop()
	
	# Limpiar estado
	is_waiting_for_recombination = false
	last_requested_animation = ""
	is_playing = false
	
	# UI de error temporal
	play_button.text = "⚠️"
	play_button.tooltip_text = error_msg
	play_button.disabled = false
	time_label.text = "Error"
	
	# Restaurar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"

# === CONTROLES DE REPRODUCCIÓN ===

func _on_play_pause_pressed():
	"""✅ MEJORADO: Play/pause con validación"""
	if current_animation == "" or not current_animation_player:
		return
	
	if is_waiting_for_recombination:
		print("⚠️ Esperando cambio de animación...")
		return
	
	if is_playing:
		current_animation_player.pause()
		is_playing = false
		play_button.text = "▶️"
		play_button.tooltip_text = "Continuar"
		emit_signal("pause_requested")
	else:
		if not current_animation_player.is_playing():
			current_animation_player.play(current_animation)
		else:
			current_animation_player.play()
		is_playing = true
		play_button.text = "⏸️"
		play_button.tooltip_text = "Pausar"
		emit_signal("play_requested", current_animation)

func _on_stop_pressed():
	"""Detener animación"""
	if not current_animation_player:
		return
	
	loop_manager.stop_animation_clean(current_animation_player)
	is_playing = false
	
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	timeline_slider.value = 0.0
	
	if current_animation != "":
		var animation = current_animation_player.get_animation(current_animation)
		time_label.text = "0.0s / %.1fs" % animation.length
	
	emit_signal("stop_requested")

# === NAVEGACIÓN ===

func _on_prev_animation():
	"""Navegar a animación anterior"""
	if available_animations.is_empty():
		return
	
	var new_index = current_animation_index - 1
	if new_index < 0:
		new_index = available_animations.size() - 1
	
	_select_animation_by_index(new_index)

func _on_next_animation():
	"""Navegar a siguiente animación"""
	if available_animations.is_empty():
		return
	
	var new_index = current_animation_index + 1
	if new_index >= available_animations.size():
		new_index = 0
	
	_select_animation_by_index(new_index)

func _select_animation_by_index(index: int):
	"""Seleccionar por índice"""
	if index >= 0 and index < available_animations.size():
		animations_option.selected = index + 1
		_on_animation_selected(index + 1)

# === TIMELINE ===
#
#func _on_timeline_changed(value: float):
	#"""Manejar cambio en timeline"""
	#if current_animation_player and current_animation != "" and not is_waiting_for_recombination:
		#current_animation_player.seek(value, true)
		#
		#var animation = current_animation_player.get_animation(current_animation)
		#time_label.text = "%.1fs / %.1fs" % [value, animation.length]
		#
		#emit_signal("timeline_changed", value)
#
##func _process(_delta):
	##"""Actualizar timeline durante reproducción"""
	##if is_playing and current_animation_player and current_animation != "" and not is_waiting_for_recombination:
		##if current_animation_player.is_playing():
			##var current_time = current_animation_player.current_animation_position
			##
			##if not timeline_slider.has_focus():
				##timeline_slider.value = current_time
			##
			##var animation = current_animation_player.get_animation(current_animation)
###			time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]

# === UTILIDADES ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _extract_display_name(filename: String) -> String:
	"""Extraer nombre limpio de archivo"""
	var base_name = filename.get_file().get_basename()
	var clean_name = base_name
	
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	
	while "  " in clean_name:
		clean_name = clean_name.replace("  ", " ")
	
	return clean_name.capitalize()

#func _clean_animation_name_fallback(animation_name: String) -> String:
	#"""Limpiar nombre de animación"""
	#var clean_name = animation_name
	#
	#clean_name = clean_name.replace("mixamo.com", "")
	#clean_name = clean_name.replace("Armature|", "")
	#clean_name = clean_name.replace("Take001", "")
	#clean_name = clean_name.replace("_", " ")
	#clean_name = clean_name.strip_edges()
	#
	#if clean_name.length() < 3:
		#clean_name = animation_name
	#
	#return clean_name.capitalize()

func _update_animations_dropdown():
	"""Actualizar dropdown"""
	animations_option.clear()
	animations_option.add_item("-- Seleccionar animación --")
	
	for display_name in animation_display_names:
		animations_option.add_item(display_name)
	
	_update_counter_display()

func _update_counter_display():
	"""Actualizar contador"""
	if current_animation_index >= 0 and available_animations.size() > 0:
		animation_counter_label.text = "%d/%d" % [current_animation_index + 1, available_animations.size()]
	else:
		animation_counter_label.text = "-/%d" % available_animations.size()

func _enable_controls():
	"""Habilitar controles básicos"""
	animations_option.disabled = false
	prev_button.disabled = false
	next_button.disabled = false

func _disable_all_controls():
	"""Deshabilitar todos los controles"""
	animations_option.disabled = true
	prev_button.disabled = true
	play_button.disabled = true
	stop_button.disabled = true
	next_button.disabled = true
	timeline_slider.editable = false

func _deselect_animation():
	"""Des-seleccionar animación"""
	if current_animation_player:
		loop_manager.stop_animation_clean(current_animation_player)
	
	current_animation = ""
	current_animation_index = -1
	is_playing = false
	
	play_button.text = "▶️"
	play_button.disabled = true
	stop_button.disabled = true
	timeline_slider.value = 0.0
	time_label.text = "0.0s"
	
	_update_counter_display()
	emit_signal("animation_deselected")

func reset_controls():
	"""Reset completo"""
	if current_animation_player and is_playing:
		loop_manager.stop_animation_clean(current_animation_player)
	
	current_animation_player = null
	available_animations.clear()
	animation_display_names.clear()
	current_animation = ""
	current_animation_index = -1
	is_playing = false
	is_waiting_for_recombination = false
	
	animations_option.clear()
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
	
	_disable_all_controls()
	play_button.text = "▶️"
	timeline_slider.value = 0.0
	animation_counter_label.text = "-/-"
	time_label.text = "0.0s"

# === FUNCIONES PÚBLICAS ===

func has_animations() -> bool:
	return available_animations.size() > 0

func get_current_animation() -> String:
	return current_animation

func get_available_animations() -> Array:
	return available_animations.duplicate()

func get_current_animation_index() -> int:
	return current_animation_index

#func debug_state():
	#"""Debug detallado del estado"""
	#print("\n🎮 === ANIMATION CONTROLS DEBUG ===")
	#print("Animaciones disponibles: %d" % available_animations.size())
	#print("Animación actual: %s (índice %d)" % [current_animation, current_animation_index])
	#print("Estado: %s" % ("reproduciendo" if is_playing else "detenido"))
	#print("Esperando cambio: %s" % is_waiting_for_recombination)
	#if is_waiting_for_recombination:
		#print("  Esperando: %s" % last_requested_animation)
		#print("  Timeout en: %.1fs" % recombination_timeout_timer.time_left)
	#print("================================\n")
# Mejoras para animation_controls_panel.gd
# Reemplaza estas funciones para mejor manejo de nombres:

func _on_animation_change_completed(animation_name: String):
	"""✅ MEJORADO: Finalizar cambio con actualización correcta del estado"""
	print("✅ Cambio completado: %s" % animation_name)
	
	# Limpiar estado de espera
	is_waiting_for_recombination = false
	last_requested_animation = ""
	
	# IMPORTANTE: Actualizar el nombre actual de la animación
	current_animation = animation_name  # Usar el nombre real encontrado
	
	# Restaurar controles
	is_playing = true
	play_button.text = "⏸️"
	play_button.tooltip_text = "Pausar"
	play_button.disabled = false
	stop_button.disabled = false
	timeline_slider.editable = true
	
	# Actualizar timeline
	if current_animation_player and current_animation_player.has_animation(animation_name):
		var anim_lib = current_animation_player.get_animation_library("")
		if anim_lib and anim_lib.has_animation(animation_name):
			var animation = anim_lib.get_animation(animation_name)
			if animation:
				timeline_slider.max_value = animation.length
				timeline_slider.value = 0.0
				time_label.text = "0.0s / %.1fs" % animation.length
	
	_update_counter_display()

#func _process(_delta):
	#"""Actualizar timeline durante reproducción - MEJORADO"""
	#if is_playing and current_animation_player and current_animation != "" and not is_waiting_for_recombination:
		#if current_animation_player.is_playing():
			#var current_time = current_animation_player.current_animation_position
			#
			#if not timeline_slider.has_focus():
				#timeline_slider.value = current_time
			#
			## Obtener la animación actual del player (más confiable)
			#var playing_anim = current_animation_player.current_animation
			#if playing_anim != "" and current_animation_player.has_animation(playing_anim):
				#var anim_lib = current_animation_player.get_animation_library("")
				#if anim_lib and anim_lib.has_animation(playing_anim):
					#var animation = anim_lib.get_animation(playing_anim)
					#if animation:
						#time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]





func _clean_animation_name_fallback(animation_name: String) -> String:
	"""✅ MEJORADO: Limpiar nombres con caracteres especiales"""
	var clean_name = animation_name
	
	# Primero, remover extensión si existe
	if clean_name.ends_with(".fbx"):
		clean_name = clean_name.get_basename()
	
	# Limpiar patrones comunes
	clean_name = clean_name.replace("mixamo.com", "")
	clean_name = clean_name.replace("Armature|", "")
	clean_name = clean_name.replace("Take001", "")
	
	# Manejar paréntesis (como en "Zombie Death(1)")
	clean_name = clean_name.replace("(", " ")
	clean_name = clean_name.replace(")", "")
	
	# Reemplazar guiones bajos y guiones
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	
	# Limpiar espacios múltiples
	while "  " in clean_name:
		clean_name = clean_name.replace("  ", " ")
	
	clean_name = clean_name.strip_edges()
	
	# Si queda muy corto, usar el original
	if clean_name.length() < 3:
		clean_name = animation_name.get_basename()
	
	return clean_name.capitalize()

func debug_state():
	"""Debug mejorado con información de animación actual"""
	print("\n🎮 === ANIMATION CONTROLS DEBUG ===")
	print("Animaciones disponibles: %d" % available_animations.size())
	for i in range(available_animations.size()):
		var marker = "→" if i == current_animation_index else " "
		print(" %s [%d] %s (%s)" % [marker, i, available_animations[i], animation_display_names[i]])
	
	print("\nEstado actual:")
	print("  Animación actual (variable): '%s'" % current_animation)
	print("  Índice actual: %d" % current_animation_index)
	
	if current_animation_player:
		print("  AnimationPlayer:")
		print("    - Reproduciendo: %s" % current_animation_player.is_playing())
		print("    - Animación activa: '%s'" % current_animation_player.current_animation)
		print("    - Lista completa: %s" % str(current_animation_player.get_animation_list()))
	
	print("  Estado: %s" % ("reproduciendo" if is_playing else "detenido"))
	print("  Esperando cambio: %s" % is_waiting_for_recombination)
	
	if is_waiting_for_recombination:
		print("    - Esperando: %s" % last_requested_animation)
		print("    - Timeout en: %.1fs" % recombination_timeout_timer.time_left)
	
	print("================================\n")



# scripts/viewer/ui/animation_controls_panel.gd
# CORRECCIÓN: Función _process mejorada para la barra de tiempo

# === ACTUALIZACIÓN AUTOMÁTICA CORREGIDA ===

func _process(_delta):
	"""Actualizar timeline automáticamente durante reproducción - VERSIÓN CORREGIDA"""
	# ✅ CORRECCIÓN: Verificaciones más robustas
	if not _is_timeline_update_valid():
		return
	
	# Obtener tiempo actual del AnimationPlayer
	var current_time = current_animation_player.current_animation_position
	var animation = current_animation_player.get_animation(current_animation)
	
	if not animation:
		return
	
	# ✅ CORRECCIÓN: Solo actualizar si el slider no está siendo arrastrado por el usuario
	if not timeline_slider.has_focus():
		# Actualizar posición del slider de forma suave
		timeline_slider.value = current_time
	
	# ✅ CORRECCIÓN: Siempre actualizar el label de tiempo (incluso si el slider tiene focus)
	time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]

func _is_timeline_update_valid() -> bool:
	"""Verificar si es válido actualizar el timeline"""
	# Verificar estado de reproducción
	if not is_playing:
		return false
	
	# Verificar AnimationPlayer
	if not current_animation_player:
		print("⚠️ Timeline: No hay current_animation_player")
		return false
	
	if not is_instance_valid(current_animation_player):
		print("⚠️ Timeline: current_animation_player no es válido")
		return false
	
	# Verificar animación actual
	if current_animation == "":
		return false
	
	if not current_animation_player.has_animation(current_animation):
		print("⚠️ Timeline: Animación '%s' no existe en player" % current_animation)
		return false
	
	# Verificar que realmente esté reproduciéndose
	if not current_animation_player.is_playing():
		print("⚠️ Timeline: AnimationPlayer no está reproduciendo (desincronizado)")
		# ✅ CORRECCIÓN: Auto-reparar desincronización
		_fix_playback_desync()
		return false
	
	return true

func _fix_playback_desync():
	"""Corregir desincronización entre UI y AnimationPlayer"""
	print("🔧 Corrigiendo desincronización de reproducción")
	
	if current_animation_player and current_animation != "":
		if current_animation_player.has_animation(current_animation):
			# Verificar si debería estar reproduciéndose según la UI
			if is_playing:
				print("  ➤ Reiniciando reproducción en AnimationPlayer")
				current_animation_player.play(current_animation)
			else:
				print("  ➤ UI indica pausa, actualizando estado")
				# La UI ya refleja el estado correcto

# === FUNCIONES DE TIMELINE MEJORADAS ===

func _on_timeline_changed(value: float):
	"""Manejar cambio manual en timeline - VERSIÓN MEJORADA"""
	if not current_animation_player or current_animation == "":
		return
	
	if not current_animation_player.has_animation(current_animation):
		print("❌ Timeline: Animación no encontrada al cambiar posición")
		return
	
	# ✅ CORRECCIÓN: Seek mejorado con manejo de estados
	var was_playing = current_animation_player.is_playing()
	
	# Hacer seek
	current_animation_player.seek(value, true)
	
	# ✅ CORRECCIÓN: Preservar estado de reproducción después del seek
	if was_playing and not current_animation_player.is_playing():
		current_animation_player.play(current_animation)
	
	# Actualizar label inmediatamente
	var animation = current_animation_player.get_animation(current_animation)
	time_label.text = "%.1fs / %.1fs" % [value, animation.length]
	
	emit_signal("timeline_changed", value)

func _update_timeline_for_animation(animation_name: String):
	"""Actualizar timeline para la animación seleccionada - VERSIÓN MEJORADA"""
	print("🎬 Actualizando timeline para: %s" % animation_name)
	
	if not current_animation_player or not current_animation_player.has_animation(animation_name):
		print("❌ No se puede actualizar timeline: animación no encontrada")
		_reset_timeline_to_default()
		return
	
	var animation = current_animation_player.get_animation(animation_name)
	
	# Configurar rango del slider
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = animation.length
	timeline_slider.step = 0.01  # 10ms de precisión
	timeline_slider.value = 0.0
	
	# Actualizar label
	time_label.text = "0.0s / %.1fs" % animation.length
	
	# Habilitar edición
	timeline_slider.editable = true
	
	print("✅ Timeline configurado: 0.0s - %.1fs" % animation.length)

func _reset_timeline_to_default():
	"""Resetear timeline a valores por defecto"""
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.value = 0.0
	timeline_slider.editable = false
	time_label.text = "0.0s"

# === FUNCIÓN DE DEBUG PARA TIMELINE ===

func debug_timeline_state():
	"""Debug específico del timeline - función para usar desde consola"""
	print("\n🎬 === TIMELINE DEBUG ===")
	print("is_playing: %s" % is_playing)
	print("current_animation: '%s'" % current_animation)
	print("current_animation_player: %s" % ("VÁLIDO" if current_animation_player else "NULL"))
	
	if current_animation_player:
		print("  Player válido: %s" % is_instance_valid(current_animation_player))
		print("  Player reproduciendo: %s" % current_animation_player.is_playing())
		print("  Animación actual del player: '%s'" % current_animation_player.current_animation)
		print("  Posición actual: %.2fs" % current_animation_player.current_animation_position)
		print("  Animaciones disponibles: %s" % str(current_animation_player.get_animation_list()))
	
	print("Timeline slider:")
	print("  Valor: %.2f" % timeline_slider.value)
	print("  Rango: %.2f - %.2f" % [timeline_slider.min_value, timeline_slider.max_value])
	print("  Editable: %s" % timeline_slider.editable)
	print("  Tiene focus: %s" % timeline_slider.has_focus())
	
	print("Time label: '%s'" % time_label.text)
	print("========================\n")


func get_selected_animation() -> String:
	"""Obtener la animación actualmente seleccionada"""
	if current_animation_index >= 0 and current_animation_index < available_animations.size():
		var selected_animation = available_animations[current_animation_index]
		print("🎯 Animación seleccionada: %s (índice %d)" % [selected_animation, current_animation_index])
		return selected_animation
	
	print("⚠️ No hay animación seleccionada válida (índice: %d, total: %d)" % [current_animation_index, available_animations.size()])
	return ""

func get_selected_animation_clean_name() -> String:
	"""Obtener el nombre limpio de la animación seleccionada (sin .fbx)"""
	var selected = get_selected_animation()
	if selected == "":
		return ""
	
	# Remover .fbx si existe
	if selected.ends_with(".fbx"):
		return selected.get_basename()
	
	return selected
