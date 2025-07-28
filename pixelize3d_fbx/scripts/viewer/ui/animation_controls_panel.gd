# scripts/viewer/ui/animation_controls_panel.gd
# Panel MEJORADO con navegación completa de animaciones
# Input: Modelo con AnimationPlayer desde populate_animations()
# Output: Señales que espera el coordinator + navegación y control completo de animaciones

extends HBoxContainer

# Señales que espera el viewer_coordinator.gd
signal animation_selected(animation_name: String)
signal animation_change_requested(animation_name: String)  # ✅ NUEVA: Para re-combinación
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
var animation_display_names: Array = []  # Nombres amigables basados en archivos
var current_animation_player: AnimationPlayer = null
var is_playing: bool = false
var current_animation: String = ""
var current_animation_index: int = -1

# ✅ NUEVAS VARIABLES: Control de re-combinación y timeout
var is_waiting_for_recombination: bool = false
var recombination_timeout_timer: Timer
var last_requested_animation: String = ""

# ✅ CORRECCIÓN CRÍTICA: Crear instancia del loop manager
var loop_manager: AnimationLoopManager

func _ready():
	# ✅ CORRECCIÓN: Crear instancia correcta del loop manager
	loop_manager = AnimationLoopManager.new()
	add_child(loop_manager)  # Agregar como hijo para que funcione correctamente
	
	_create_ui()
	_setup_timeout_timer()
	print("🎮 AnimationControlsPanel MEJORADO inicializado con loop_manager")

# ✅ FUNCIÓN NUEVA: Configurar timer de timeout
func _setup_timeout_timer():
	"""Configurar timer para timeout de re-combinación"""
	recombination_timeout_timer = Timer.new()
	recombination_timeout_timer.wait_time = 10.0  # 10 segundos timeout
	recombination_timeout_timer.one_shot = true
	recombination_timeout_timer.timeout.connect(_on_recombination_timeout)
	add_child(recombination_timeout_timer)
	print("⏲️ Timer de timeout configurado")

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
	
	# NUEVO: Botón anterior
	prev_button = Button.new()
	prev_button.text = "⏮️"
	prev_button.tooltip_text = "Animación anterior"
	prev_button.disabled = true
	prev_button.pressed.connect(_on_prev_animation)
	add_child(prev_button)
	
	# Botón play/pause (mejorado)
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
	
	# NUEVO: Botón siguiente
	next_button = Button.new()
	next_button.text = "⏭️"
	next_button.tooltip_text = "Siguiente animación"
	next_button.disabled = true
	next_button.pressed.connect(_on_next_animation)
	add_child(next_button)
	
	add_child(VSeparator.new())
	
	# Timeline
	timeline_slider = HSlider.new()
	timeline_slider.custom_minimum_size.x = 200
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.step = 0.01
	timeline_slider.value = 0.0
	timeline_slider.editable = false
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# NUEVO: Contador de animaciones
	animation_counter_label = Label.new()
	animation_counter_label.text = "-/-"
	animation_counter_label.custom_minimum_size.x = 40
	add_child(animation_counter_label)
	
	# Label de tiempo
	time_label = Label.new()
	time_label.text = "0.0s"
	time_label.custom_minimum_size.x = 80
	add_child(time_label)

# === FUNCIONES PRINCIPALES ===

func populate_animations(model_with_player: Node3D):
	"""Función principal para poblar animaciones con nombres descriptivos"""
	print("🎭 POBLANDO ANIMACIONES MEJORADAS - Modelo: %s" % (model_with_player.name if model_with_player else "null"))
	
	# Limpiar estado anterior
	reset_controls()
	
	if not model_with_player:
		print("❌ Modelo inválido")
		return
	
	# Buscar AnimationPlayer
	current_animation_player = _find_animation_player(model_with_player)
	
	if not current_animation_player:
		print("❌ No se encontró AnimationPlayer")
		return
	
	print("✅ AnimationPlayer encontrado: %s" % current_animation_player.name)
	
	# Obtener lista de animaciones
	var animation_list = current_animation_player.get_animation_list()
	
	if animation_list.is_empty():
		print("❌ No hay animaciones")
		return
	
	print("📋 Animaciones encontradas: %s" % str(animation_list))
	
	# ✅ CORRECCIÓN: Usar método de instancia
	loop_manager.setup_infinite_loops(current_animation_player)
	print("🔄 Loops configurados en todas las animaciones")
	
	# Poblar arrays con nombres descriptivos
	available_animations.clear()
	animation_display_names.clear()
	
	for anim_name in animation_list:
		available_animations.append(anim_name)
		# MEJORAR NOMBRES: Usar metadatos reales de archivo
		var display_name = _generate_display_name_from_metadata(anim_name, model_with_player)
		animation_display_names.append(display_name)
		print("➕ Agregada: '%s' -> '%s'" % [anim_name, display_name])
	
	# Poblar dropdown
	_update_animations_dropdown()
	
	# Habilitar controles
	_enable_controls()
	
	print("✅ Controles poblados: %d animaciones" % available_animations.size())
	
	# Auto-seleccionar primera animación
	if available_animations.size() > 0:
		call_deferred("_auto_select_first_animation")

# ✅ FUNCIÓN CRÍTICA MEJORADA: Generar nombres usando metadatos reales
func _generate_display_name_from_metadata(animation_name: String, model: Node3D) -> String:
	"""Generar nombre descriptivo usando metadatos de archivo preservados"""
	
	# ✅ PASO 1: Extraer metadatos de animaciones del modelo
	var animations_metadata = {}
	if model.has_meta("all_animations_metadata"):
		animations_metadata = model.get_meta("all_animations_metadata")
		print("✅ Metadatos encontrados para %d animaciones" % animations_metadata.size())
	else:
		print("⚠️ No hay metadatos de animaciones en el modelo")
	
	# ✅ PASO 2: Buscar metadatos específicos para esta animación
	var display_name = animation_name
	
	if animations_metadata.has(animation_name):
		var anim_metadata = animations_metadata[animation_name]
		print("📋 Metadatos para '%s': %s" % [animation_name, str(anim_metadata)])
		
		# Usar display_name si está disponible
		if anim_metadata.has("display_name") and anim_metadata.display_name != "":
			display_name = anim_metadata.display_name
			print("✅ Usando display_name: %s" % display_name)
		
		# Si no, construir desde filename
		elif anim_metadata.has("filename") and anim_metadata.filename != "":
			var filename = anim_metadata.filename
			display_name = filename.get_basename()
			
			# Limpiar nombre de archivo
			display_name = _clean_filename_for_display(display_name)
			print("✅ Construido desde filename: %s -> %s" % [filename, display_name])
		
		# Si no, usar basename
		elif anim_metadata.has("basename") and anim_metadata.basename != "":
			display_name = _clean_filename_for_display(anim_metadata.basename)
			print("✅ Usando basename: %s" % display_name)
	
	else:
		print("⚠️ No hay metadatos específicos para '%s', usando fallback" % animation_name)
		# Fallback: limpiar el nombre de animación original
		display_name = _clean_animation_name_fallback(animation_name)
	
	# ✅ PASO 3: Validar y retornar
	if display_name.strip_edges() == "":
		display_name = animation_name  # Último fallback
	
	print("🎯 Nombre final para '%s': '%s'" % [animation_name, display_name])
	return display_name

# ✅ FUNCIÓN NUEVA: Limpiar nombre de archivo para display
func _clean_filename_for_display(filename: String) -> String:
	"""Limpiar nombre de archivo para mostrar de forma amigable"""
	var clean_name = filename
	
	# Remover extensiones comunes
	clean_name = clean_name.replace(".fbx", "")
	clean_name = clean_name.replace(".gltf", "")
	clean_name = clean_name.replace(".glb", "")
	
	# Limpiar nombres técnicos de Mixamo y otros
	clean_name = clean_name.replace("mixamo.com", "")
	clean_name = clean_name.replace("Armature|", "")
	clean_name = clean_name.replace("Take001", "")
	clean_name = clean_name.replace("Take 001", "")
	clean_name = clean_name.replace("_action", "")
	clean_name = clean_name.replace("-action", "")
	
	# Reemplazar caracteres de separación
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	clean_name = clean_name.replace(".", " ")
	
	# Limpiar espacios múltiples
	while "  " in clean_name:
		clean_name = clean_name.replace("  ", " ")
	
	clean_name = clean_name.strip_edges()
	
	# Capitalizar primera letra de cada palabra
	var words = clean_name.split(" ")
	for i in range(words.size()):
		if words[i].length() > 0:
			words[i] = words[i].capitalize()
	
	return " ".join(words)

# ✅ FUNCIÓN NUEVA: Fallback para limpiar nombres de animación
func _clean_animation_name_fallback(animation_name: String) -> String:
	"""Fallback para limpiar nombres cuando no hay metadatos"""
	var clean_name = animation_name
	
	# Limpiar patrones comunes de nombres técnicos
	clean_name = clean_name.replace("mixamo.com", "")
	clean_name = clean_name.replace("Armature|", "")
	clean_name = clean_name.replace("Take001", "")
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.strip_edges()
	
	# Si queda muy corto o vacío, usar el original
	if clean_name.length() < 3:
		clean_name = animation_name
	
	# Capitalizar
	clean_name = clean_name.capitalize()
	
	return clean_name

func _update_animations_dropdown():
	"""Actualizar dropdown con nombres descriptivos"""
	animations_option.clear()
	animations_option.add_item("-- Ninguna seleccionada --")  # Opción de des-selección
	
	for i in range(animation_display_names.size()):
		animations_option.add_item(animation_display_names[i])
	
	_update_counter_display()

func _update_counter_display():
	"""Actualizar contador de animaciones"""
	if current_animation_index >= 0 and available_animations.size() > 0:
		animation_counter_label.text = "%d/%d" % [current_animation_index + 1, available_animations.size()]
	else:
		animation_counter_label.text = "-/%d" % available_animations.size()

# === NAVEGACIÓN DE ANIMACIONES ===

func _on_prev_animation():
	"""Navegar a animación anterior"""
	if available_animations.size() == 0:
		return
	
	var new_index: int
	if current_animation_index <= 0:
		# Navegación circular: ir al final
		new_index = available_animations.size() - 1
	else:
		new_index = current_animation_index - 1
	
	print("⏮️ Navegando a animación anterior: índice %d" % new_index)
	_select_animation_by_index(new_index)

func _on_next_animation():
	"""Navegar a siguiente animación"""
	if available_animations.size() == 0:
		return
	
	var new_index: int
	if current_animation_index >= available_animations.size() - 1:
		# Navegación circular: ir al principio
		new_index = 0
	else:
		new_index = current_animation_index + 1
	
	print("⏭️ Navegando a siguiente animación: índice %d" % new_index)
	_select_animation_by_index(new_index)

func _select_animation_by_index(index: int):
	"""Seleccionar animación por índice y solicitar re-combinación"""
	if index < 0 or index >= available_animations.size():
		print("❌ Índice de animación inválido: %d" % index)
		return
	
	# Actualizar dropdown (índice + 1 porque el 0 es "-- Ninguna --")
	animations_option.selected = index + 1
	
	# ✅ CRÍTICO: Usar el manejador que solicita re-combinación
	_on_animation_selected(index + 1)

func _auto_select_first_animation():
	"""Auto-seleccionar primera animación"""
	if available_animations.size() > 0:
		print("🎯 Auto-seleccionando primera animación")
		_select_animation_by_index(0)

# === MANEJADORES DE EVENTOS ===

func _on_animation_selected(dropdown_index: int):
	"""Manejar selección en dropdown - CON RE-COMBINACIÓN"""
	print("🖱️ SELECCIÓN EN DROPDOWN - Índice: %d" % dropdown_index)
	
	if dropdown_index <= 0:
		# Opción "-- Ninguna seleccionada --"
		print("🚫 Des-seleccionando animación")
		_deselect_animation()
		return
	
	# Validar índice
	var anim_index = dropdown_index - 1
	if anim_index >= available_animations.size():
		print("❌ Índice fuera de rango")
		return
	
	# Actualizar estado interno
	current_animation_index = anim_index
	var selected_animation = available_animations[anim_index]
	var display_name = animation_display_names[anim_index]
	
	print("🎭 Seleccionada: '%s' (%s)" % [selected_animation, display_name])
	
	# ✅ CRÍTICO: Solicitar re-combinación en lugar de cambio local
	print("📡 Solicitando re-combinación para: %s" % selected_animation)
	emit_signal("animation_change_requested", selected_animation)
	
	# Actualizar UI (pero no cambiar animación aún)
	_update_counter_display()
	_prepare_ui_for_animation_change(selected_animation)
	
	# Emitir señal tradicional para compatibilidad
	emit_signal("animation_selected", selected_animation)

func _deselect_animation():
	"""Des-seleccionar animación actual"""
	print("🚫 DES-SELECCIONANDO ANIMACIÓN")
	
	# ✅ CORRECCIÓN: Usar método de instancia
	if current_animation_player:
		loop_manager.stop_animation_clean(current_animation_player)
	
	# Limpiar estado
	current_animation = ""
	current_animation_index = -1
	is_playing = false
	
	# Actualizar UI
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	timeline_slider.value = 0.0
	time_label.text = "0.0s"
	_update_counter_display()
	
	# Deshabilitar algunos controles
	play_button.disabled = true
	stop_button.disabled = true
	timeline_slider.editable = false
	
	# Emitir señal
	emit_signal("animation_deselected")
	print("✅ Animación des-seleccionada")

func _prepare_ui_for_animation_change(animation_name: String):
	"""Preparar UI para cambio de animación CON TIMEOUT"""
	current_animation = animation_name
	last_requested_animation = animation_name
	is_waiting_for_recombination = true
	
	# Mostrar estado de "cargando"
	play_button.text = "⏳"
	play_button.tooltip_text = "Cargando animación..."
	play_button.disabled = true
	stop_button.disabled = true
	timeline_slider.editable = false
	
	# Timeline temporal
	timeline_slider.value = 0.0
	time_label.text = "Cargando..."
	
	# ✅ NUEVO: Iniciar timer de timeout
	recombination_timeout_timer.start()
	
	print("⏳ UI preparada para cambio a: %s (timeout: %.1fs)" % [animation_name, recombination_timeout_timer.wait_time])

# ✅ FUNCIÓN NUEVA: Timeout de re-combinación
func _on_recombination_timeout():
	"""Manejar timeout de re-combinación"""
	if is_waiting_for_recombination:
		print("⏰ TIMEOUT: Re-combinación tardó demasiado para '%s'" % last_requested_animation)
		
		# Restaurar UI a estado de error
		play_button.text = "⚠️"
		play_button.tooltip_text = "Error: Timeout en cambio de animación"
		play_button.disabled = false  # Permitir retry
		stop_button.disabled = false
		time_label.text = "Error (Timeout)"
		
		# Limpiar estado de espera
		is_waiting_for_recombination = false
		last_requested_animation = ""
		
		print("🔄 UI reseteada después de timeout")

func _on_animation_change_completed(animation_name: String):
	"""Callback cuando se completa el cambio de animación CON CLEANUP"""
	print("✅ Cambio de animación completado: %s" % animation_name)
	
	# ✅ NUEVO: Detener timer de timeout
	if recombination_timeout_timer.is_stopped() == false:
		recombination_timeout_timer.stop()
	
	# Limpiar estado de espera
	is_waiting_for_recombination = false
	last_requested_animation = ""
	
	# Restaurar controles
	play_button.text = "⏸️"  # Asumimos que inicia reproduciendo
	play_button.tooltip_text = "Pausar"
	play_button.disabled = false
	stop_button.disabled = false
	timeline_slider.editable = true
	is_playing = true
	
	# Actualizar timeline para la nueva animación
	_update_timeline_for_animation(animation_name)
	
	print("🎬 Controles restaurados para: %s" % animation_name)

func _update_timeline_for_animation(animation_name: String):
	"""Actualizar timeline para la animación seleccionada"""
	if current_animation_player and current_animation_player.has_animation(animation_name):
		var animation = current_animation_player.get_animation(animation_name)
		timeline_slider.max_value = animation.length
		timeline_slider.value = 0.0
		time_label.text = "0.0s / %.1fs" % animation.length

# === CONTROLES DE REPRODUCCIÓN ===

func _on_play_pause_pressed():
	"""Manejar botón play/pause unificado - CORREGIDO"""
	print("🎮 PLAY/PAUSE presionado")
	
	if current_animation == "":
		print("❌ No hay animación seleccionada")
		return
	
	if not current_animation_player:
		print("❌ No hay AnimationPlayer")
		return
	
	# Verificar que la animación actual existe
	if not current_animation_player.has_animation(current_animation):
		print("❌ Animación '%s' no existe en el player actual" % current_animation)
		return
	
	if is_playing:
		# Pausar
		current_animation_player.pause()
		is_playing = false
		play_button.text = "▶️"
		play_button.tooltip_text = "Continuar"
		emit_signal("pause_requested")
		print("⏸️ Pausado")
	else:
		# Reproducir/Continuar
		current_animation_player.play(current_animation)
		is_playing = true
		play_button.text = "⏸️"
		play_button.tooltip_text = "Pausar"
		emit_signal("play_requested", current_animation)
		print("▶️ Reproduciendo")

func _on_stop_pressed():
	"""Manejar botón stop - CORREGIDO"""
	print("🛑 STOP presionado")
	
	if not current_animation_player or current_animation == "":
		return
	
	# ✅ CORRECCIÓN: Usar método de instancia
	loop_manager.stop_animation_clean(current_animation_player)
	is_playing = false
	
	# Reset UI
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	timeline_slider.value = 0.0
	
	# Actualizar tiempo
	if current_animation_player.has_animation(current_animation):
		var animation = current_animation_player.get_animation(current_animation)
		time_label.text = "0.0s / %.1fs" % animation.length
	
	emit_signal("stop_requested")
	print("⏹️ Detenido y reseteado")

func _on_timeline_changed(value: float):
	"""Manejar cambio en timeline"""
	if current_animation_player and current_animation != "":
		if current_animation_player.has_animation(current_animation):
			current_animation_player.seek(value, true)
			
			var animation = current_animation_player.get_animation(current_animation)
			time_label.text = "%.1fs / %.1fs" % [value, animation.length]
			
			emit_signal("timeline_changed", value)

# === ACTUALIZACIÓN AUTOMÁTICA ===

func _process(_delta):
	"""Actualizar timeline automáticamente durante reproducción"""
	if is_playing and current_animation_player and current_animation != "":
		if current_animation_player.is_playing() and current_animation_player.has_animation(current_animation):
			var current_time = current_animation_player.current_animation_position
			
			# Actualizar slider solo si no se está arrastrando
			if not timeline_slider.has_focus():
				timeline_slider.value = current_time
			
			# Actualizar label de tiempo
			var animation = current_animation_player.get_animation(current_animation)
			time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]

# === CONTROL DE UI ===

func _enable_controls():
	"""Habilitar controles básicos cuando hay animaciones"""
	var animations_available = available_animations.size() > 0
	
	animations_option.disabled = not animations_available
	prev_button.disabled = not animations_available
	next_button.disabled = not animations_available

func _enable_playback_controls():
	"""Habilitar controles de reproducción cuando hay animación seleccionada"""
	play_button.disabled = false
	stop_button.disabled = false
	timeline_slider.editable = true

func reset_controls():
	"""Reset completo del panel"""
	print("🔄 Reseteando controles de animación")
	
	# ✅ CORRECCIÓN: Usar método de instancia
	if current_animation_player and is_playing:
		loop_manager.stop_animation_clean(current_animation_player)
	
	# Limpiar estado
	current_animation_player = null
	available_animations.clear()
	animation_display_names.clear()
	current_animation = ""
	current_animation_index = -1
	is_playing = false
	
	# Reset UI
	animations_option.clear()
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
	
	prev_button.disabled = true
	play_button.disabled = true
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	stop_button.disabled = true
	next_button.disabled = true
	
	timeline_slider.editable = false
	timeline_slider.value = 0.0
	animation_counter_label.text = "-/-"
	time_label.text = "0.0s"

# === FUNCIONES DE UTILIDAD ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

# === FUNCIONES PÚBLICAS PARA COORDINATOR ===

func on_model_recombined(new_model: Node3D, animation_name: String):
	"""✅ FUNCIÓN MEJORADA: Llamada por coordinator cuando se re-combina modelo"""
	print("🔄 Modelo re-combinado recibido para: %s" % animation_name)
	
	# Verificar que estamos esperando esta re-combinación
	if not is_waiting_for_recombination:
		print("⚠️ Re-combinación recibida pero no esperada")
		return
	
	if animation_name != last_requested_animation:
		print("⚠️ Re-combinación para '%s' pero esperábamos '%s'" % [animation_name, last_requested_animation])
		# Continuar de todos modos
	
	# Actualizar referencia al AnimationPlayer
	current_animation_player = _find_animation_player(new_model)
	
	if not current_animation_player:
		print("❌ No se encontró AnimationPlayer en modelo re-combinado")
		_reset_ui_on_error("No se encontró AnimationPlayer")
		return
	
	# Verificar que la animación existe
	if not current_animation_player.has_animation(animation_name):
		print("❌ Animación '%s' no existe en modelo re-combinado" % animation_name)
		_reset_ui_on_error("Animación no encontrada: " + animation_name)
		return
	
	# ✅ CORRECCIÓN: Usar método de instancia
	loop_manager.setup_infinite_loops(current_animation_player)
	
	# Iniciar la animación automáticamente
	var success = loop_manager.change_animation_clean(current_animation_player, animation_name)
	
	if success:
		_on_animation_change_completed(animation_name)
	else:
		print("❌ Falló iniciar animación en modelo re-combinado")
		_reset_ui_on_error("Error al iniciar animación")

func _reset_ui_on_error(error_message: String = "Error"):
	"""✅ FUNCIÓN MEJORADA: Resetear UI cuando hay error en cambio de animación"""
	print("💥 Error en cambio de animación: %s" % error_message)
	
	# Detener timer de timeout
	if recombination_timeout_timer and not recombination_timeout_timer.is_stopped():
		recombination_timeout_timer.stop()
	
	# Limpiar estado de espera
	is_waiting_for_recombination = false
	last_requested_animation = ""
	
	# UI de error
	play_button.text = "❌"
	play_button.tooltip_text = "Error: " + error_message
	play_button.disabled = false  # Permitir retry
	stop_button.disabled = false
	timeline_slider.editable = false
	time_label.text = "Error"
	is_playing = false
	
	print("🔄 UI reseteada después de error")

func has_animations() -> bool:
	"""Verificar si hay animaciones disponibles"""
	return available_animations.size() > 0

func get_current_animation() -> String:
	"""Obtener animación actual"""
	return current_animation

func get_available_animations() -> Array:
	"""Obtener lista de animaciones disponibles"""
	return available_animations.duplicate()

func get_current_animation_index() -> int:
	"""Obtener índice de animación actual"""
	return current_animation_index

func navigate_to_animation(index: int) -> bool:
	"""Navegar programáticamente a una animación específica"""
	if index >= 0 and index < available_animations.size():
		_select_animation_by_index(index)
		return true
	return false

# === ATAJOS DE TECLADO (OPCIONALES) ===

func _input(event):
	"""Manejar atajos de teclado"""
	if not has_focus():
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				if not prev_button.disabled:
					_on_prev_animation()
			KEY_RIGHT:
				if not next_button.disabled:
					_on_next_animation()
			KEY_SPACE:
				if not play_button.disabled:
					_on_play_pause_pressed()
			KEY_ESCAPE:
				if current_animation_index >= 0:
					animations_option.selected = 0
					_on_animation_selected(0)

# === FUNCIONES DE DEBUG ===

func debug_state():
	"""Debug del estado actual CON METADATOS"""
	print("\n🎮 === ANIMATION CONTROLS DEBUG MEJORADO ===")
	print("AnimationPlayer: %s" % (current_animation_player.name if current_animation_player else "null"))
	print("Animaciones disponibles: %d" % available_animations.size())
	for i in range(available_animations.size()):
		var marker = " ◀️" if i == current_animation_index else ""
		print("  [%d] %s -> %s%s" % [i, available_animations[i], animation_display_names[i], marker])
	print("Animación actual: %s (índice %d)" % [current_animation, current_animation_index])
	print("Estado: %s" % ("reproduciendo" if is_playing else "pausado/detenido"))
	print("Controles habilitados: Prev=%s, Play=%s, Stop=%s, Next=%s" % [
		not prev_button.disabled, not play_button.disabled, not stop_button.disabled, not next_button.disabled
	])
	
	# ✅ DEBUG DE METADATOS
	print("\n📝 METADATOS DE MODELO:")
	if current_animation_player and current_animation_player.get_parent():
		var model = current_animation_player.get_parent()
		if model.has_meta("all_animations_metadata"):
			var metadata = model.get_meta("all_animations_metadata")
			print("  Metadatos encontrados para %d animaciones:" % metadata.size())
			for anim_name in metadata.keys():
				var anim_meta = metadata[anim_name]
				print("    • %s: %s (%s)" % [anim_name, 
				anim_meta.get("display_name", "Sin display"), 
				anim_meta.get("filename", "Sin archivo")])
		else:
			print("  ❌ No hay metadatos de animaciones en el modelo")
		
		if model.has_meta("base_metadata"):
			var base_meta = model.get_meta("base_metadata")
			print("  Base: %s (%s)" % [
			base_meta.get("display_name", "Sin nombre"), 
			base_meta.get("filename", "Sin archivo")])
	
	# ✅ DEBUG DE LOOP MANAGER
	if loop_manager:
		loop_manager.debug_animation_state(current_animation_player)
	
	print("===============================================\n")



func update_animations_list(new_animations: Array) -> void:
	animations_option.clear()
	available_animations = new_animations
	animation_display_names.clear()

	if new_animations.size() == 0:
		animations_option.add_item("-- No hay animaciones --")
		animations_option.disabled = true
		emit_signal("animation_deselected")
		return

	for i in range(new_animations.size()):
		var anim_path = new_animations[i]
		var anim_name = anim_path.get_file().get_basename()
		animation_display_names.append(anim_name)
		animations_option.add_item(anim_name)

	animations_option.disabled = false
	_play_animation_by_index(new_animations.size() - 1)  # última animación
	

func _play_animation_by_index(index: int) -> void:
	if index < 0 or index >= available_animations.size():
		return
	current_animation_index = index
	current_animation = available_animations[index]
	emit_signal("play_requested", current_animation)
	animations_option.select(index)

func select_animation_by_name(animation_name: String) -> void:
	for i in range(available_animations.size()):
		var anim_path = available_animations[i]
		var anim_name = anim_path.get_file().get_basename()
		if anim_name == animation_name:
			current_animation_index = i
			current_animation = anim_path
			animations_option.select(i)
			emit_signal("play_requested", current_animation)
			return
