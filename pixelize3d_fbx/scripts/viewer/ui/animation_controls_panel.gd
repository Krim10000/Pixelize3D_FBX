# scripts/viewer/ui/animation_controls_panel.gd
# Panel especializado SOLO para controles de animación
# Input: Modelo con AnimationPlayer
# Output: Señales de control de animaciones

extends HBoxContainer

# Señales específicas de este panel
signal animation_selected(animation_name: String)
signal play_requested(animation_name: String)
signal pause_requested()
signal stop_requested()
signal timeline_changed(position: float)

# UI propia de este panel
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

func _ready():
	_create_ui()

func _create_ui():
	# Selector de animaciones
	var anim_label = Label.new()
	anim_label.text = "Animación:"
	add_child(anim_label)
	
	animations_option = OptionButton.new()
	animations_option.custom_minimum_size.x = 150
	animations_option.add_item("-- No hay animaciones --")
	animations_option.disabled = true
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
	
	# Timeline
	var timeline_label = Label.new()
	timeline_label.text = "Timeline:"
	add_child(timeline_label)
	
	timeline_slider = HSlider.new()
	timeline_slider.custom_minimum_size.x = 200
	timeline_slider.min_value = 0.0
	timeline_slider.max_value = 1.0
	timeline_slider.step = 0.01
#	timeline_slider.disabled = true
	timeline_slider.value_changed.connect(_on_timeline_changed)
	add_child(timeline_slider)
	
	# Tiempo actual
	time_label = Label.new()
	time_label.text = "0.0s"
	time_label.custom_minimum_size.x = 50
	add_child(time_label)

func populate_animations(model: Node3D):
	current_animation_player = _find_animation_player(model)
	
	animations_option.clear()
	available_animations.clear()
	
	if not current_animation_player:
		animations_option.add_item("-- No hay AnimationPlayer --")
		animations_option.disabled = true
		_disable_all_controls()
		return
	
	var animation_list = current_animation_player.get_animation_list()
	
	if animation_list.is_empty():
		animations_option.add_item("-- No hay animaciones --")
		animations_option.disabled = true
		_disable_all_controls()
		return
	
	# Poblar lista
	animations_option.add_item("-- Seleccionar animación --")
	for anim_name in animation_list:
		animations_option.add_item(anim_name)
		available_animations.append(anim_name)
	
	animations_option.disabled = false
	
	# Conectar señales del AnimationPlayer
	if not current_animation_player.animation_finished.is_connected(_on_animation_finished):
		current_animation_player.animation_finished.connect(_on_animation_finished)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _disable_all_controls():
	play_button.disabled = true
	pause_button.disabled = true
	stop_button.disabled = true
	timeline_slider.disabled = true

func _enable_controls():
	play_button.disabled = false
	pause_button.disabled = false
	stop_button.disabled = false
	timeline_slider.disabled = false

func _on_animation_selected(index: int):
	if index <= 0 or index > available_animations.size():
		_disable_all_controls()
		return
	
	current_animation = available_animations[index - 1]
	_enable_controls()
	
	# Configurar timeline para esta animación
	if current_animation_player and current_animation_player.has_animation(current_animation):
		var animation = current_animation_player.get_animation(current_animation)
		timeline_slider.max_value = animation.length
		timeline_slider.value = 0.0
		time_label.text = "0.0s / %.1fs" % animation.length
	
	emit_signal("animation_selected", current_animation)

func _on_play_pressed():
	if current_animation_player and current_animation != "":
		current_animation_player.play(current_animation)
		is_playing = true
		
		# Actualizar UI
		play_button.text = "⏸️"
		play_button.tooltip_text = "Pausar"
		
		emit_signal("play_requested", current_animation)

func _on_pause_pressed():
	if current_animation_player:
		if is_playing:
			current_animation_player.pause()
			is_playing = false
			play_button.text = "▶️"
			play_button.tooltip_text = "Continuar"
		else:
			current_animation_player.play()
			is_playing = true
			play_button.text = "⏸️"
			play_button.tooltip_text = "Pausar"
		
		emit_signal("pause_requested")

func _on_stop_pressed():
	if current_animation_player:
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

func _on_timeline_changed(value: float):
	if current_animation_player and current_animation != "":
		current_animation_player.seek(value, true)
		
		if current_animation_player.has_animation(current_animation):
			var animation = current_animation_player.get_animation(current_animation)
			time_label.text = "%.1fs / %.1fs" % [value, animation.length]
		
		emit_signal("timeline_changed", value)

func _on_animation_finished(animation_name: String):
	if animation_name == current_animation:
		is_playing = false
		play_button.text = "▶️"
		play_button.tooltip_text = "Reproducir"

func _process(delta):
	# Actualizar timeline durante reproducción
	if is_playing and current_animation_player and current_animation != "":
		if current_animation_player.is_playing():
			var current_time = current_animation_player.current_animation_position
			timeline_slider.value = current_time
			
			if current_animation_player.has_animation(current_animation):
				var animation = current_animation_player.get_animation(current_animation)
				time_label.text = "%.1fs / %.1fs" % [current_time, animation.length]

# Funciones públicas
func get_current_animation() -> String:
	return current_animation

func get_available_animations() -> Array:
	return available_animations.duplicate()

func has_animations() -> bool:
	return not available_animations.is_empty()

func reset_controls():
	animations_option.clear()
	animations_option.add_item("-- No hay animaciones --")
	available_animations.clear()
	current_animation = ""
	current_animation_player = null
	is_playing = false
	_disable_all_controls()
