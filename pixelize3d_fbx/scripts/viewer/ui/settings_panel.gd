# scripts/viewer/ui/settings_panel.gd
# Panel especializado SOLO para configuración de renderizado
# Input: Cambios en controles de configuración
# Output: Señales con configuración actualizada

extends VBoxContainer

# Señales específicas de este panel
signal settings_changed(settings: Dictionary)
signal preset_applied(preset_name: String)

# UI propia de este panel
var section_label: Label
var directions_spinbox: SpinBox
var sprite_size_spinbox: SpinBox
var fps_spinbox: SpinBox
var pixelize_check: CheckBox
var camera_angle_slider: HSlider
var camera_angle_label: Label
var north_offset_slider: HSlider
var north_offset_label: Label

# Configuración interna
var current_settings: Dictionary = {
	"directions": 16,
	"sprite_size": 256,
	"fps": 12,
	"pixelize": true,
	"camera_angle": 45.0,
	"north_offset": 0.0
}

func _ready():
	_create_ui()
	_apply_current_settings()

func _create_ui():
	# Título de sección
	section_label = Label.new()
	section_label.text = "⚙️ Configuración de Renderizado"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# Direcciones
	var directions_container = HBoxContainer.new()
	add_child(directions_container)
	
	var directions_label = Label.new()
	directions_label.text = "Direcciones:"
	directions_label.custom_minimum_size.x = 100
	directions_container.add_child(directions_label)
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 8
	directions_spinbox.max_value = 32
	directions_spinbox.step = 8
	directions_spinbox.value = 16
	directions_spinbox.value_changed.connect(_on_setting_changed)
	directions_container.add_child(directions_spinbox)
	
	# Tamaño de sprite
	var sprite_size_container = HBoxContainer.new()
	add_child(sprite_size_container)
	
	var sprite_size_label = Label.new()
	sprite_size_label.text = "Tamaño sprite:"
	sprite_size_label.custom_minimum_size.x = 100
	sprite_size_container.add_child(sprite_size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 64
	sprite_size_spinbox.max_value = 1024
	sprite_size_spinbox.step = 64
	sprite_size_spinbox.value = 256
	sprite_size_spinbox.value_changed.connect(_on_setting_changed)
	sprite_size_container.add_child(sprite_size_spinbox)
	
	# FPS
	var fps_container = HBoxContainer.new()
	add_child(fps_container)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_label.custom_minimum_size.x = 100
	fps_container.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 6
	fps_spinbox.max_value = 30
	fps_spinbox.value = 12
	fps_spinbox.value_changed.connect(_on_setting_changed)
	fps_container.add_child(fps_spinbox)
	
	# Pixelizado
	pixelize_check = CheckBox.new()
	pixelize_check.text = "Aplicar pixelización"
	pixelize_check.button_pressed = true
	pixelize_check.toggled.connect(_on_setting_changed)
	add_child(pixelize_check)
	
	add_child(HSeparator.new())
	
	# Configuración de cámara
	var camera_title = Label.new()
	camera_title.text = "📐 Cámara"
	camera_title.add_theme_font_size_override("font_size", 14)
	camera_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(camera_title)
	
	# Ángulo de cámara
	var camera_angle_container = HBoxContainer.new()
	add_child(camera_angle_container)
	
	var angle_label = Label.new()
	angle_label.text = "Ángulo:"
	angle_label.custom_minimum_size.x = 80
	camera_angle_container.add_child(angle_label)
	
	camera_angle_slider = HSlider.new()
	camera_angle_slider.min_value = 15.0
	camera_angle_slider.max_value = 75.0
	camera_angle_slider.value = 45.0
	camera_angle_slider.step = 1.0
	camera_angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camera_angle_slider.value_changed.connect(_on_camera_angle_changed)
	camera_angle_container.add_child(camera_angle_slider)
	
	camera_angle_label = Label.new()
	camera_angle_label.text = "45°"
	camera_angle_label.custom_minimum_size.x = 40
	camera_angle_container.add_child(camera_angle_label)
	
	add_child(HSeparator.new())
	
	# Orientación del modelo
	var orientation_title = Label.new()
	orientation_title.text = "🧭 Orientación"
	orientation_title.add_theme_font_size_override("font_size", 14)
	orientation_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(orientation_title)
	
	# Norte del modelo
	var north_container = HBoxContainer.new()
	add_child(north_container)
	
	var north_label = Label.new()
	north_label.text = "Norte:"
	north_label.custom_minimum_size.x = 80
	north_container.add_child(north_label)
	
	north_offset_slider = HSlider.new()
	north_offset_slider.min_value = 0.0
	north_offset_slider.max_value = 360.0
	north_offset_slider.value = 0.0
	north_offset_slider.step = 1.0
	north_offset_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	north_offset_slider.value_changed.connect(_on_north_offset_changed)
	north_container.add_child(north_offset_slider)
	
	north_offset_label = Label.new()
	north_offset_label.text = "0°"
	north_offset_label.custom_minimum_size.x = 40
	north_container.add_child(north_offset_label)
	
	# Presets de orientación
	var presets_container = HBoxContainer.new()
	add_child(presets_container)
	
	var presets_label = Label.new()
	presets_label.text = "Presets:"
	presets_label.custom_minimum_size.x = 80
	presets_container.add_child(presets_label)
	
	var north_btn = Button.new()
	north_btn.text = "N"
	north_btn.custom_minimum_size.x = 30
	north_btn.pressed.connect(_on_preset_pressed.bind(0.0))
	presets_container.add_child(north_btn)
	
	var east_btn = Button.new()
	east_btn.text = "E"
	east_btn.custom_minimum_size.x = 30
	east_btn.pressed.connect(_on_preset_pressed.bind(90.0))
	presets_container.add_child(east_btn)
	
	var south_btn = Button.new()
	south_btn.text = "S"
	south_btn.custom_minimum_size.x = 30
	south_btn.pressed.connect(_on_preset_pressed.bind(180.0))
	presets_container.add_child(south_btn)
	
	var west_btn = Button.new()
	west_btn.text = "W"
	west_btn.custom_minimum_size.x = 30
	west_btn.pressed.connect(_on_preset_pressed.bind(270.0))
	presets_container.add_child(west_btn)

func _apply_current_settings():
	# Aplicar valores actuales a controles
	directions_spinbox.value = current_settings.directions
	sprite_size_spinbox.value = current_settings.sprite_size
	fps_spinbox.value = current_settings.fps
	pixelize_check.button_pressed = current_settings.pixelize
	camera_angle_slider.value = current_settings.camera_angle
	north_offset_slider.value = current_settings.north_offset
	
	# Actualizar labels
	_on_camera_angle_changed(current_settings.camera_angle)
	_on_north_offset_changed(current_settings.north_offset)

func _on_setting_changed(value = null):
	# Actualizar configuración interna
	current_settings.directions = int(directions_spinbox.value)
	current_settings.sprite_size = int(sprite_size_spinbox.value)
	current_settings.fps = int(fps_spinbox.value)
	current_settings.pixelize = pixelize_check.button_pressed
	
	emit_signal("settings_changed", current_settings.duplicate())

func _on_camera_angle_changed(value: float):
	current_settings.camera_angle = value
	camera_angle_label.text = "%.0f°" % value
	emit_signal("settings_changed", current_settings.duplicate())

func _on_north_offset_changed(value: float):
	current_settings.north_offset = value
	north_offset_label.text = "%.0f°" % value
	emit_signal("settings_changed", current_settings.duplicate())

func _on_preset_pressed(angle: float):
	north_offset_slider.value = angle
	emit_signal("preset_applied", "orientation_%.0f" % angle)

# Funciones públicas
func get_settings() -> Dictionary:
	return current_settings.duplicate()

func apply_settings(settings: Dictionary):
	for key in settings:
		if key in current_settings:
			current_settings[key] = settings[key]
	
	_apply_current_settings()
	emit_signal("settings_changed", current_settings.duplicate())

func reset_to_defaults():
	current_settings = {
		"directions": 16,
		"sprite_size": 256,
		"fps": 12,
		"pixelize": true,
		"camera_angle": 45.0,
		"north_offset": 0.0
	}
	
	_apply_current_settings()
	emit_signal("settings_changed", current_settings.duplicate())

func apply_preset(preset_name: String):
	match preset_name:
		"rts_standard":
			current_settings.directions = 16
			current_settings.sprite_size = 256
			current_settings.camera_angle = 45.0
		
		"high_quality":
			current_settings.sprite_size = 512
			current_settings.fps = 24
		
		"fast_preview":
			current_settings.directions = 8
			current_settings.sprite_size = 128
			current_settings.fps = 8
	
	_apply_current_settings()
	emit_signal("preset_applied", preset_name)
	emit_signal("settings_changed", current_settings.duplicate())
