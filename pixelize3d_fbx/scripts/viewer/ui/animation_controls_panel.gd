# scripts/viewer/ui/animation_controls_panel.gd
# Panel COMPATIBLE con viewer_coordinator.gd y con cambios de animación funcionando
# Input: Modelo con AnimationPlayer desde populate_animations()
# Output: Señales que espera el coordinator + control funcional de animaciones

extends HBoxContainer

# Señales que espera el viewer_coordinator.gd
signal animation_selected(animation_name: String)
signal play_requested(animation_name: String) 
signal pause_requested()
signal stop_requested()
signal timeline_changed(position: float)

# UI elements
var animations_option: OptionButton
var play_button: Button
var pause_button: Button
var stop_button: Button
var timeline_slider: HSlider
var time_label: Label

# Estado interno
var available_animations: Array = []
var current_animation_player: AnimationPlayer = null
var is_playing: bool = false
var current_animation: String = ""

# Cargar managers
var loop_manager = preload("res://scripts/core/animation_loop_manager.gd")

func _ready():
	_create_ui()
	print("🎮 AnimationControlsPanel inicializado (Compatible)")

func _create_ui():
	# Label
	var anim_label = Label.new()
	anim_label.text = "Animación:"
	add_child(anim_label)
	
	# Dropdown de animaciones
	animations_option = OptionButton.new()
	animations_option.custom_minimum_size.x = 150
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
	# CONEXIÓN CRÍTICA: Conectar item_selected al manejador correcto
	animations_option.item_selected.connect(_on_animation_selected)
	add_child(animations_option)
	
	add_child(VSeparator.new())
	
	# Botones de control
	play_button = Button.new()
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	play_button.disabled = true
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)
	
	pause_button = Button.new()
	pause_button.text = "⏸️"
	pause_button.tooltip_text = "Pausar"
	pause_button.disabled = true
	pause_button.pressed.connect(_on_pause_pressed)
	add_child(pause_button)
	
	stop_button = Button.new()
	stop_button.text = "⏹️"
	stop_button.tooltip_text = "Detener"
	stop_button.disabled = true
	stop_button.pressed.connect(_on_stop_pressed)
	add_child(stop_button)
	
	add_child(VSeparator.new())
	
	# Timeline slider
	var timeline_label = Label.new()
	timeline_label.text = "Timeline:"
	add_child(timeline_label)
	
	timeline_slider = HSlider.new()
	timeline_slider.custom_minimum_size.x = 200
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.step = 0.01
	timeline_slider.editable = false
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# Time label
	time_label = Label.new()
	time_label.text = "0.0s"
	time_label.custom_minimum_size.x = 50
	add_child(time_label)

# FUNCIÓN PRINCIPAL: Poblar animaciones (llamada por coordinator)
func populate_animations(model: Node3D):
	print("🎭 POBLANDO ANIMACIONES (Compatible) - Modelo: %s" % (model.name if model else "NULL"))
	
	# Limpiar estado anterior
	reset_controls()
	
	if not model:
		print("❌ Modelo inválido")
		return
	
	# Buscar AnimationPlayer
	current_animation_player = _find_animation_player(model)
	
	if not current_animation_player:
		print("❌ No se encontró AnimationPlayer")
		animations_option.add_item("-- No hay AnimationPlayer --")
		animations_option.disabled = true
		return
	
	print("✅ AnimationPlayer encontrado: %s" % current_animation_player.name)
	
	# Obtener animaciones
	var animation_list = current_animation_player.get_animation_list()
	
	if animation_list.is_empty():
		print("❌ No hay animaciones")
		animations_option.add_item("-- No hay animaciones --")
		animations_option.disabled = true
		return
	
	# Configurar loops infinitos
	loop_manager.setup_infinite_loops(current_animation_player)
	print("🔄 Loops configurados en todas las animaciones")
	
	# Poblar dropdown
	animations_option.clear()
	animations_option.add_item("-- Seleccionar animación --")
	
	for anim_name in animation_list:
		animations_option.add_item(anim_name)
		available_animations.append(anim_name)
	
	animations_option.disabled = false
	
	# Conectar señal de animación finalizada si no está conectada
	if not current_animation_player.animation_finished.is_connected(_on_animation_finished):
		current_animation_player.animation_finished.connect(_on_animation_finished)
	
	print("✅ Controles poblados: %d animaciones" % available_animations.size())
	
	# Auto-seleccionar primera animación con delay para evitar conflictos
	call_deferred("_auto_select_first_animation")

func _auto_select_first_animation():
	"""Auto-seleccionar primera animación después de poblar"""
	if available_animations.size() > 0:
		print("🎯 Auto-seleccionando primera animación: %s" % available_animations[0])
		animations_option.selected = 1  # Índice 1 = primera animación
		_on_animation_selected(1)

# MANEJADOR CRÍTICO: Selección de animación en dropdown
func _on_animation_selected(index: int):
	print("🖱️ ANIMACIÓN SELECCIONADA - Índice: %d" % index)
	
	# Validar índice
	if index <= 0 or index > available_animations.size():
		print("❌ Índice inválido, deshabilitando controles")
		_disable_all_controls()
		return
	
	# Obtener nombre de animación seleccionada
	var selected_animation = available_animations[index - 1]
	print("🎭 Seleccionada: '%s'" % selected_animation)
	
	# Cambiar inmediatamente usando loop manager
	_change_to_animation(selected_animation)
	
	# Configurar timeline para esta animación
	if current_animation_player and current_animation_player.has_animation(selected_animation):
		var animation = current_animation_player.get_animation(selected_animation)
		timeline_slider.max_value = animation.length
		timeline_slider.value = 0.0
		time_label.text = "0.0s / %.1fs" % animation.length
	
	# EMITIR SEÑAL que espera el coordinator
	emit_signal("animation_selected", selected_animation)
	print("📡 Señal animation_selected emitida: %s" % selected_animation)

# FUNCIÓN CRÍTICA: Cambio real de animación
func _change_to_animation(animation_name: String):
	print("⚡ CAMBIANDO A ANIMACIÓN: %s" % animation_name)
	
	if not current_animation_player or not current_animation_player.has_animation(animation_name):
		print("❌ AnimationPlayer inválido o animación no existe")
		return
	
	# Usar loop_manager para cambio limpio
	var success = loop_manager.change_animation_clean(current_animation_player, animation_name)
	
	if success:
		current_animation = animation_name
		is_playing = true
		
		# Actualizar UI
		play_button.text = "⏸️"
		play_button.tooltip_text = "Pausar"
		_enable_controls()
		
		print("✅ Cambio exitoso a: %s" % animation_name)
	else:
		print("❌ Falló el cambio de animación")

# MANEJADORES DE BOTONES
func _on_play_pressed():
	print("🎮 PLAY/PAUSE presionado")
	
	if not current_animation_player or current_animation == "":
		print("❌ No hay animación activa")
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
		current_animation_player.play()
		is_playing = true
		play_button.text = "⏸️"
		play_button.tooltip_text = "Pausar"
		emit_signal("play_requested", current_animation)
		print("▶️ Reproduciendo")

func _on_pause_pressed():
	print("⏸️ PAUSE presionado")
	_on_play_pressed()  # Reutilizar lógica de play/pause

func _on_stop_pressed():
	print("🛑 STOP presionado")
	
	if not current_animation_player:
		return
	
	current_animation_player.stop()
	is_playing = false
	
	# Reset UI
	play_button.text = "▶️"
	play_button.tooltip_text = "Reproducir"
	timeline_slider.value = 0.0
	
	if current_animation_player.has_animation(current_animation):
		var animation = current_animation_player.get_animation(current_animation)
		time_label.text = "0.0s / %.1fs" % animation.length
	
	emit_signal("stop_requested")
	print("⏹️ Detenido")

func _on_timeline_changed(value: float):
	if current_animation_player and current_animation != "":
		current_animation_player.seek(value, true)
		
		if current_animation_player.has_animation(current_animation):
			var animation = current_animation_player.get_animation(current_animation)
			time_label.text = "%.1fs / %.1fs" % [value, animation.length]
		
		emit_signal("timeline_changed", value)

func _on_animation_finished(animation_name: String):
	"""Callback cuando termina una animación"""
	if animation_name == current_animation:
		# Como tenemos loop infinito, esto no debería pasar normalmente
		print("🔄 Animación terminada (reloop): %s" % animation_name)

func _process(delta):
	"""Actualizar timeline durante reproducción"""
	if is_playing and current_animation_player and current_animation != "":
		if current_animation_player.is_playing():
			var current_time = current_animation_player.current_animation_position
			timeline_slider.value = current_time
			
			if current_animation_player.has_animation(current_animation):
				var animation = current_animation_player.get_animation(current_animation)
				time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]

# FUNCIONES DE CONTROL UI
func _disable_all_controls():
	"""Deshabilitar todos los controles"""
	play_button.disabled = true
	pause_button.disabled = true
	stop_button.disabled = true
	timeline_slider.editable = false

func _enable_controls():
	"""Habilitar controles cuando hay animación válida"""
	play_button.disabled = false
	pause_button.disabled = false
	stop_button.disabled = false
	timeline_slider.editable = true

# FUNCIONES DE UTILIDAD
func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func reset_controls():
	"""Reset completo del estado (llamado por coordinator)"""
	print("🔄 Reseteando controles de animación")
	
	# Limpiar estado
	available_animations.clear()
	current_animation = ""
	current_animation_player = null
	is_playing = false
	
	# Reset UI
	animations_option.clear()
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
	_disable_all_controls()
	
	timeline_slider.value = 0.0
	time_label.text = "0.0s"

# FUNCIONES PÚBLICAS (para compatibility)
func get_current_animation() -> String:
	"""Obtener animación actual"""
	return current_animation

func get_available_animations() -> Array:
	"""Obtener lista de animaciones disponibles"""
	return available_animations.duplicate()

func has_animations() -> bool:
	"""Verificar si hay animaciones disponibles"""
	return not available_animations.is_empty()

func is_animation_playing() -> bool:
	"""Verificar si hay animación reproduciéndose"""
	return is_playing and current_animation_player and current_animation_player.is_playing()

# FUNCIONES DE DEBUG
func debug_state():
	"""Debug del estado actual"""
	print("\n=== ANIMATION CONTROLS DEBUG ===")
	print("Current animation: '%s'" % current_animation)
	print("Is playing: %s" % is_playing)
	print("Available animations: %s" % str(available_animations))
	print("AnimationPlayer: %s" % (current_animation_player.name if current_animation_player else "NULL"))
	print("Dropdown selected: %d" % animations_option.selected)
	print("Dropdown items: %d" % animations_option.get_item_count())
	
	if current_animation_player:
		print("Player info:")
		print("  - Is playing: %s" % current_animation_player.is_playing())
		print("  - Current: '%s'" % current_animation_player.current_animation)
		print("  - Animation list: %s" % str(current_animation_player.get_animation_list()))
	
	print("================================\n")

# FUNCIÓN DE TEST MANUAL
func test_change_animation():
	"""Función de test para cambiar a segunda animación disponible"""
	if available_animations.size() > 1:
		var test_anim = available_animations[1]
		print("🧪 TEST: Cambiando manualmente a: %s" % test_anim)
		animations_option.selected = 2  # Índice 2 = segunda animación
		_on_animation_selected(2)
	else:
		print("🧪 TEST: No hay suficientes animaciones para test")
