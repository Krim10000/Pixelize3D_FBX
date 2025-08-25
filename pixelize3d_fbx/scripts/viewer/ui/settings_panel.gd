# scripts/viewer/ui/settings_panel.gd
# Panel COMPLETO con sistema de delay integrado - LISTO PARA PRODUCCION
# Input: Cambios en controles de configuracion
# Output: Señales con configuracion actualizada incluyendo delay system

extends VBoxContainer

# Señales especificas de este panel
signal settings_changed(settings: Dictionary)
signal preset_applied(preset_name: String)
signal request_auto_north_detection() 

# UI propia de este panel - EXTENDIDA PARA DELAY SYSTEM
var section_label: Label
var directions_spinbox: SpinBox
var sprite_size_spinbox: SpinBox
var fps_spinbox: SpinBox
var pixelize_check: CheckBox
var camera_angle_slider: HSlider
var camera_angle_label: Label
var north_offset_slider: HSlider
var north_offset_label: Label
var camera_height_slider: HSlider
var camera_height_label: Label

# Controles de area de captura
var capture_area_slider: HSlider
var capture_area_label: Label
var auto_north_check: CheckBox
var show_orientation_cross_check: CheckBox

# NUEVOS CONTROLES PARA DELAY SYSTEM
var delay_spinbox: SpinBox
var delay_label: Label
var fps_equiv_label: Label
var auto_delay_check: CheckBox
var delay_info_label: Label
var recommend_button: Button

# Configuracion interna - EXTENDIDA CON DELAY SYSTEM
var current_settings: Dictionary = {
	"directions": 16,
	"sprite_size": 128,
	"fps": 40,
	"frame_delay": 0.025,  # 30 FPS equivalent
	"fps_equivalent": 40.0,   # Para mostrar equivalencia
	"camera_height": 12.0,  
	"pixelize": true,
	"camera_angle": 45.0,
	"north_offset": 0.0,
	"capture_area_size": 8.0,
	"auto_north_detection": true,
	#"auto_delay_recommendation": true,  # NUEVO
	#"show_debug_frame_numbers": false,  # NUEVO
	"timing_validation": true  # NUEVO
}

func _ready():
	print("⚙️ SettingsPanel con DELAY SYSTEM inicializado")
	_create_ui()
	_apply_current_settings()

func _create_ui():
	# Titulo de seccion
	section_label = Label.new()
	section_label.text = "⚙️ Configuracion de Renderizado"
	section_label.add_theme_font_size_override("font_size", 20)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	add_child(section_label)
	
	add_child(HSeparator.new())
	
	# SECCION: CONFIGURACION BASICA
	_create_basic_settings()
	
	add_child(HSeparator.new())
	
	# NUEVA SECCION: SISTEMA DE DELAY
	_create_delay_settings()
	
	add_child(HSeparator.new())
	
	# SECCION: CONFIGURACION DE CAMARA
	_create_camera_settings()
	
	add_child(HSeparator.new())
	
	# SECCION: AREA DE CAPTURA
	_create_capture_area_settings()
	
	add_child(HSeparator.new())
	
	# SECCION: ORIENTACION
	_create_orientation_settings()

func _create_basic_settings():
	"""Crear configuracion basica"""
	var basic_title = Label.new()
	basic_title.text = "📋 Configuracion Basica"
	basic_title.add_theme_font_size_override("font_size", 14)
	basic_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(basic_title)
	
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
	
	# Tamaño de sprite (RESOLUCION)
	var sprite_size_container = HBoxContainer.new()
	add_child(sprite_size_container)
	
	var sprite_size_label = Label.new()
	sprite_size_label.text = "Resolucion:"
	sprite_size_label.custom_minimum_size.x = 100
	sprite_size_container.add_child(sprite_size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 64
	sprite_size_spinbox.max_value = 512
	sprite_size_spinbox.step = 64
	sprite_size_spinbox.value = 128
	sprite_size_spinbox.value_changed.connect(_on_setting_changed)
	sprite_size_container.add_child(sprite_size_spinbox)
	
	# FPS (MANTENIDO PARA COMPATIBILIDAD)
	var fps_container = HBoxContainer.new()
	add_child(fps_container)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_label.custom_minimum_size.x = 100
	fps_container.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 6
	fps_spinbox.max_value = 60
	fps_spinbox.value = 30
	fps_spinbox.value_changed.connect(_on_fps_changed)
	fps_container.add_child(fps_spinbox)
	
	# Pixelizado
	pixelize_check = CheckBox.new()
	pixelize_check.text = "Aplicar pixelizacion"
	pixelize_check.button_pressed = true
	pixelize_check.toggled.connect(_on_setting_changed)
	add_child(pixelize_check)

# NUEVA SECCION: SISTEMA DE DELAY
func _create_delay_settings():
	"""Crear controles del sistema de delay"""
	var delay_title = Label.new()
	delay_title.text = "⏱️ Sistema de Delay (Avanzado)"
	delay_title.add_theme_font_size_override("font_size", 14)
	delay_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	add_child(delay_title)
	
	# Descripcion del sistema
	var delay_desc = Label.new()
	delay_desc.text = "Control preciso de timing usando delays en lugar de FPS"
	delay_desc.add_theme_font_size_override("font_size", 10)
	delay_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	delay_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(delay_desc)
	
	# Frame Delay
	var delay_container = HBoxContainer.new()
	add_child(delay_container)
	
	delay_label = Label.new()
	delay_label.text = "Frame Delay:"
	delay_label.custom_minimum_size.x = 100
	delay_container.add_child(delay_label)
	
	delay_spinbox = SpinBox.new()
	delay_spinbox.min_value = 0.01   # 100 FPS max
	delay_spinbox.max_value = 1.0    # 1 FPS min  
	delay_spinbox.step = 0.001       # 1ms precision
	delay_spinbox.value = current_settings.frame_delay
	delay_spinbox.value_changed.connect(_on_delay_changed)
	delay_container.add_child(delay_spinbox)
	#current_settings.frame_delay = delay_spinbox.value
	
	
	var seconds_label = Label.new()
	seconds_label.text = "s"
	delay_container.add_child(seconds_label)
	
	fps_equiv_label = Label.new()
	fps_equiv_label.text = "FPS Equiv: 30.0"
	fps_equiv_label.custom_minimum_size.x = 80
	fps_equiv_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	delay_container.add_child(fps_equiv_label)
	
	# Auto delay recommendation
	#auto_delay_check = CheckBox.new()
	#auto_delay_check.text = "Auto-recomendacion de delay optimo"
	#auto_delay_check.button_pressed = current_settings.auto_delay_recommendation
	#auto_delay_check.toggled.connect(_on_auto_delay_toggled)
	#add_child(auto_delay_check)
	
	# Informacion de delay
	delay_info_label = Label.new()
	delay_info_label.text = "💡 Delay mas bajo = animacion mas fluida, delay mas alto = menos frames"
	delay_info_label.add_theme_font_size_override("font_size", 9)
	delay_info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	delay_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(delay_info_label)
	
	# Boton para obtener recomendacion manual
	var recommend_container = HBoxContainer.new()
	add_child(recommend_container)
	
	var recommend_spacer = Control.new()
	recommend_spacer.custom_minimum_size.x = 100
	recommend_container.add_child(recommend_spacer)
	
	#recommend_button = Button.new()
	#recommend_button.text = "Obtener Recomendacion"
	#recommend_button.pressed.connect(_on_recommend_delay_pressed)
	#recommend_container.add_child(recommend_button)
	
	# Presets de delay comunes
	var delay_presets_container = HBoxContainer.new()
	add_child(delay_presets_container)
	
	var presets_label = Label.new()
	presets_label.text = "Presets:"
	presets_label.custom_minimum_size.x = 100
	delay_presets_container.add_child(presets_label)
	
	var fps_60_btn = Button.new()
	fps_60_btn.text = "60 FPS"
	fps_60_btn.custom_minimum_size.x = 50
	fps_60_btn.pressed.connect(_on_delay_preset_pressed.bind(0.016667))
	fps_60_btn.tooltip_text = "Ultra suave - 0.017s delay"
	delay_presets_container.add_child(fps_60_btn)
	
	var fps_30_btn = Button.new()
	fps_30_btn.text = "30 FPS"
	fps_30_btn.custom_minimum_size.x = 50
	fps_30_btn.pressed.connect(_on_delay_preset_pressed.bind(0.033333))
	fps_30_btn.tooltip_text = "Suave - 0.033s delay"
	delay_presets_container.add_child(fps_30_btn)
	
	var fps_24_btn = Button.new()
	fps_24_btn.text = "24 FPS"
	fps_24_btn.custom_minimum_size.x = 50
	fps_24_btn.pressed.connect(_on_delay_preset_pressed.bind(0.041667))
	fps_24_btn.tooltip_text = "Cinematico - 0.042s delay"
	delay_presets_container.add_child(fps_24_btn)
	
	var fps_12_btn = Button.new()
	fps_12_btn.text = "12 FPS"
	fps_12_btn.custom_minimum_size.x = 50
	fps_12_btn.pressed.connect(_on_delay_preset_pressed.bind(0.083333))
	fps_12_btn.tooltip_text = "Retro - 0.083s delay"
	delay_presets_container.add_child(fps_12_btn)

func _create_camera_settings():
	"""Crear configuracion de camara"""
	var camera_title = Label.new()
	camera_title.text = "📐 Camara"
	camera_title.add_theme_font_size_override("font_size", 14)
	camera_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(camera_title)
	
	# Angulo de camara
	var camera_angle_container = HBoxContainer.new()
	add_child(camera_angle_container)
	
	var angle_label = Label.new()
	angle_label.text = "Angulo:"
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

	# Altura (comentada en original, mantengo la logica)
	# altura
	#var camera_height_container = HBoxContainer.new()
	#add_child(camera_height_container)
	#
	#var height_label = Label.new()
	#height_label.text = "Altura:"
	#height_label.custom_minimum_size.x = 80
	#camera_height_container.add_child(height_label)
	#
	#camera_height_slider = HSlider.new()
	#camera_height_slider.min_value = 5.0
	#camera_height_slider.max_value = 25.0
	#camera_height_slider.value = 12.0
	#camera_height_slider.step = 0.5
	#camera_height_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#camera_height_slider.value_changed.connect(_on_camera_height_changed)
	#camera_height_container.add_child(camera_height_slider)
	#
	#camera_height_label = Label.new()
	#camera_height_label.text = "12.0"
	#camera_height_label.custom_minimum_size.x = 40
	#camera_height_container.add_child(camera_height_label)

func _on_camera_height_changed(value: float):
	"""Manejar cambio en altura de camara"""
	current_settings.camera_height = value
	#camera_height_label.text = "%.1f" % value
	
	print("📏 Altura de camara: %.1f" % value)
	settings_changed.emit(current_settings.duplicate())

func _create_capture_area_settings():
	"""Crear configuracion de area de captura"""
	var capture_title = Label.new()
	capture_title.text = "🖼️ Area de Captura"
	capture_title.add_theme_font_size_override("font_size", 14)
	capture_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(capture_title)
	
	# Descripcion del area de captura
	var capture_desc = Label.new()
	capture_desc.text = "Controla que tan grande se ve el modelo en el sprite final"
	capture_desc.add_theme_font_size_override("font_size", 10)
	capture_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	capture_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(capture_desc)
	
	# Slider de area de captura
	var capture_container = HBoxContainer.new()
	add_child(capture_container)
	
	var capture_label = Label.new()
	capture_label.text = "Tamaño:"
	capture_label.custom_minimum_size.x = 80
	capture_container.add_child(capture_label)
	
	capture_area_slider = HSlider.new()
	capture_area_slider.min_value = 0.5    # Modelo MUY grande (area pequeña)
	capture_area_slider.max_value = 20.0   # Modelo pequeño (area grande)
	capture_area_slider.value = 4.5        # Tamaño normal
	capture_area_slider.step = 0.5
	capture_area_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capture_area_slider.value_changed.connect(_on_capture_area_changed)
	capture_container.add_child(capture_area_slider)
	
	capture_area_label = Label.new()
	capture_area_label.text = "8.0"
	capture_area_label.custom_minimum_size.x = 40
	capture_container.add_child(capture_area_label)
	
	# Botones de presets de tamaño
	var size_presets_container = HBoxContainer.new()
	add_child(size_presets_container)
	
	var size_presets_label = Label.new()
	size_presets_label.text = "Presets:"
	size_presets_label.custom_minimum_size.x = 80
	size_presets_container.add_child(size_presets_label)
	
	var size_huge_btn = Button.new()
	size_huge_btn.text = "Gigante"
	size_huge_btn.custom_minimum_size.x = 55
	size_huge_btn.pressed.connect(_on_size_preset_pressed.bind(4.0))
	size_huge_btn.tooltip_text = "Modelo muy grande en el sprite"
	size_presets_container.add_child(size_huge_btn)
	
	var size_big_btn = Button.new()
	size_big_btn.text = "Grande"
	size_big_btn.custom_minimum_size.x = 55
	size_big_btn.pressed.connect(_on_size_preset_pressed.bind(6.0))
	size_presets_container.add_child(size_big_btn)
	
	var size_normal_btn = Button.new()
	size_normal_btn.text = "Normal"
	size_normal_btn.custom_minimum_size.x = 55
	size_normal_btn.pressed.connect(_on_size_preset_pressed.bind(8.0))
	size_presets_container.add_child(size_normal_btn)
	
	var size_small_btn = Button.new()
	size_small_btn.text = "Pequeño"
	size_small_btn.custom_minimum_size.x = 55
	size_small_btn.pressed.connect(_on_size_preset_pressed.bind(12.0))
	size_presets_container.add_child(size_small_btn)
	
	# Informacion adicional
	var info_label = Label.new()
	info_label.text = "💡 Valores menores = modelo mas grande en sprite"
	info_label.add_theme_font_size_override("font_size", 9)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(info_label)

func _create_orientation_settings():
	"""Crear configuracion de orientacion"""
	var orientation_title = Label.new()
	orientation_title.text = "🧭 Orientacion"
	orientation_title.add_theme_font_size_override("font_size", 14)
	orientation_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(orientation_title)
	
	# Checkbox para mostrar cruz
	show_orientation_cross_check = CheckBox.new()
	show_orientation_cross_check.text = "Mostrar cruz de orientacion"
	show_orientation_cross_check.button_pressed = true
	show_orientation_cross_check.toggled.connect(_on_orientation_cross_toggled)
	add_child(show_orientation_cross_check)
	
	# Deteccion automatica de norte
	auto_north_check = CheckBox.new()
	auto_north_check.text = "Detectar orientacion norte automaticamente"
	auto_north_check.button_pressed = true
	auto_north_check.toggled.connect(_on_auto_north_toggled)
	add_child(auto_north_check)
	
	# Descripcion de deteccion automatica
	var auto_desc = Label.new()
	auto_desc.text = "El sistema analiza la geometria del modelo para determinar el frente"
	auto_desc.add_theme_font_size_override("font_size", 9)
	auto_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	auto_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(auto_desc)
	
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
	
	# Presets de orientacion
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
	north_btn.tooltip_text = "Norte (0°)"
	presets_container.add_child(north_btn)
	
	var east_btn = Button.new()
	east_btn.text = "E"
	east_btn.custom_minimum_size.x = 30
	east_btn.pressed.connect(_on_preset_pressed.bind(90.0))
	east_btn.tooltip_text = "Este (90°)"
	presets_container.add_child(east_btn)
	
	var south_btn = Button.new()
	south_btn.text = "S"
	south_btn.custom_minimum_size.x = 30
	south_btn.pressed.connect(_on_preset_pressed.bind(180.0))
	south_btn.tooltip_text = "Sur (180°)"
	presets_container.add_child(south_btn)
	
	var west_btn = Button.new()
	west_btn.text = "W"
	west_btn.custom_minimum_size.x = 30
	west_btn.pressed.connect(_on_preset_pressed.bind(270.0))
	west_btn.tooltip_text = "Oeste (270°)"
	presets_container.add_child(west_btn)

# ========================================================================
# APLICACION DE CONFIGURACION
# ========================================================================

func _apply_current_settings():
	"""Aplicar valores actuales a controles"""
	print("🔧 Aplicando configuracion actual a controles")
	
	# Aplicar valores basicos
	directions_spinbox.value = current_settings.directions
	sprite_size_spinbox.value = current_settings.sprite_size
	fps_spinbox.value = current_settings.fps
	pixelize_check.button_pressed = current_settings.pixelize
	
	# Aplicar valores de delay system
	delay_spinbox.value = current_settings.frame_delay
	#auto_delay_check.button_pressed = current_settings.auto_delay_recommendation
	
	# Aplicar valores de camara
	camera_angle_slider.value = current_settings.camera_angle
	#camera_height_slider.value = current_settings.camera_height  
	
	# Aplicar valores de orientacion
	north_offset_slider.value = current_settings.north_offset
	auto_north_check.button_pressed = current_settings.auto_north_detection
	
	# Aplicar area de captura
	capture_area_slider.value = current_settings.capture_area_size
	
	# Actualizar labels
	_on_camera_angle_changed(current_settings.camera_angle)
	_on_camera_height_changed(current_settings.camera_height)  
	_on_north_offset_changed(current_settings.north_offset)
	_on_capture_area_changed(current_settings.capture_area_size)
	_on_delay_changed(current_settings.frame_delay)

# ========================================================================
# MANEJADORES DE EVENTOS - EXTENDIDOS PARA DELAY SYSTEM
# ========================================================================

func _on_setting_changed(value = null):
	"""Manejar cambios en configuracion basica"""
	# Actualizar configuracion interna
	current_settings.directions = int(directions_spinbox.value)
	current_settings.sprite_size = int(sprite_size_spinbox.value)
	current_settings.fps = int(fps_spinbox.value)
	current_settings.pixelize = pixelize_check.button_pressed
	
	print("⚙️ Configuracion basica actualizada")
	settings_changed.emit(current_settings.duplicate())

# NUEVO: Manejador especifico para cambios en FPS
func _on_fps_changed(new_fps: float):
	"""Manejar cambio de FPS y sincronizar con delay"""
	current_settings.fps = int(new_fps)
	
	# Actualizar delay automaticamente cuando FPS cambia
	current_settings.frame_delay = 1.0 / new_fps if new_fps > 0 else 0.033333
	current_settings.fps_equivalent = new_fps
	
	# Actualizar delay spinbox para mantener sincronia
	if delay_spinbox:
		delay_spinbox.value = current_settings.frame_delay
	
	# Actualizar label de FPS equivalente
	_update_fps_equivalent_label()
	
	print("🔄 FPS cambiado: %.1f → delay: %.4fs" % [new_fps, current_settings.frame_delay])
	settings_changed.emit(current_settings.duplicate())

# NUEVO: Manejador especifico para cambios en delay
func _on_delay_changed(new_delay: float):
	"""Manejar cambio de delay y sincronizar con FPS"""
	current_settings.frame_delay = new_delay
	current_settings.fps_equivalent = 1.0 / new_delay if new_delay > 0 else 0
	
	# Actualizar FPS spinbox para mantener sincronia
	if fps_spinbox:
		fps_spinbox.value = current_settings.fps_equivalent
		current_settings.fps = int(current_settings.fps_equivalent)
	
	# Actualizar label de FPS equivalente
	_update_fps_equivalent_label()
	
	print("⏱️ Delay cambiado: %.4fs → FPS equiv: %.1f" % [new_delay, current_settings.fps_equivalent])
	settings_changed.emit(current_settings.duplicate())

# NUEVO: Manejador para auto-recomendacion de delay
#func _on_auto_delay_toggled(enabled: bool):
	#"""Manejar toggle de auto-recomendacion"""
	#current_settings.auto_delay_recommendation = enabled
	#recommend_button.disabled = not enabled
	#
	#print("🎯 Auto-recomendacion de delay: %s" % ("ON" if enabled else "OFF"))
	#settings_changed.emit(current_settings.duplicate())

# NUEVO: Manejador para solicitar recomendacion manual
#func _on_recommend_delay_pressed():
	#"""Solicitar recomendacion manual de delay"""
	#print("🔍 Solicitando recomendacion manual de delay...")
	#recommend_button.text = "Analizando..."
	#recommend_button.disabled = true
	#
	## Emitir señal para que el coordinador maneje la recomendacion
	## TODO: Implementar conexion con delay analyzer
	#
	## Restaurar boton despues de un tiempo (simulado)
	#var timer = get_tree().create_timer(2.0)
	#timer.timeout.connect(_on_recommendation_timeout)

#func _on_recommendation_timeout():
	#"""Restaurar boton de recomendacion"""
	#recommend_button.text = "Obtener Recomendacion"
	#recommend_button.disabled = auto_delay_check.button_pressed

# NUEVO: Manejador para presets de delay
func _on_delay_preset_pressed(delay_value: float):
	"""Aplicar preset de delay"""
	delay_spinbox.value = delay_value
	print("⏱️ Preset de delay aplicado: %.4fs" % delay_value)

func _on_camera_angle_changed(value: float):
	"""Manejar cambio en angulo de camara"""
	current_settings.camera_angle = value
	camera_angle_label.text = "%.0f°" % value
	
	print("📐 Angulo de camara: %.1f°" % value)
	settings_changed.emit(current_settings.duplicate())

func _on_north_offset_changed(value: float):
	"""Manejar cambio en orientacion norte"""
	current_settings.north_offset = value
	north_offset_label.text = "%.0f°" % value
	
	print("🧭 Orientacion norte: %.1f°" % value)
	settings_changed.emit(current_settings.duplicate())

func _on_capture_area_changed(value: float):
	"""Manejar cambio en area de captura"""
	current_settings.capture_area_size = value
	capture_area_label.text = "%.1f" % value
	
	# Convertir a configuracion de camara (para compatibilidad)
	current_settings.manual_zoom_override = true
	current_settings.fixed_orthographic_size = value
	
	print("🖼️ Area de captura: %.1f" % value)
	settings_changed.emit(current_settings.duplicate())

	_update_capture_area_visual()

func _update_capture_area_visual():
	"""Actualizar indicador visual del area de captura"""
	# Buscar el ModelPreviewPanel y actualizar su indicador
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		var preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if preview_panel and preview_panel.has_method("update_capture_area_indicator"):
			preview_panel.update_capture_area_indicator()
			print("🔄 Indicador de area de captura actualizado")

func _on_size_preset_pressed(size_value: float):
	"""Manejar preset de tamaño"""
	capture_area_slider.value = size_value
	print("📐 Preset de tamaño aplicado: %.1f" % size_value)

func _on_auto_north_toggled(enabled: bool):
	"""Manejar deteccion automatica de norte"""
	current_settings.auto_north_detection = enabled
	print("🧭 Deteccion automatica de norte %s" % ("habilitada" if enabled else "deshabilitada"))
	if enabled:
		request_auto_north_detection.emit()  # Nueva señal
	settings_changed.emit(current_settings.duplicate())

func _on_preset_pressed(angle: float):
	"""Manejar preset de orientacion"""
	north_offset_slider.value = angle
	print("🧭 Preset de orientacion aplicado: %.1f°" % angle)
	preset_applied.emit("orientation_%.0f" % angle)

func _on_orientation_cross_toggled(enabled: bool):
	"""Manejar mostrar/ocultar cruz de orientacion"""
	print("🎯 Cruz de orientacion: %s" % ("visible" if enabled else "oculta"))
	
	# Buscar preview panel y actualizar
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		var preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if preview_panel:
			if enabled:
				if preview_panel.has_method("show_orientation_cross"):
					preview_panel.show_orientation_cross()
			else:
				if preview_panel.has_method("hide_orientation_cross"):
					preview_panel.hide_orientation_cross()

# ========================================================================
# FUNCIONES AUXILIARES PARA DELAY SYSTEM
# ========================================================================

func _update_fps_equivalent_label():
	"""Actualizar label de FPS equivalente"""
	if fps_equiv_label:
		fps_equiv_label.text = "FPS Equiv: %.1f" % current_settings.fps_equivalent

func get_delay_settings() -> Dictionary:
	"""Obtener configuracion especifica de delay"""
	return {
		"frame_delay": current_settings.frame_delay,
		"fps_equivalent": current_settings.fps_equivalent,
		"auto_delay_recommendation": current_settings.auto_delay_recommendation,
		"show_debug_frame_numbers": current_settings.get("show_debug_frame_numbers", false),
		"timing_validation": current_settings.get("timing_validation", true)
	}

func apply_delay_recommendation(recommendation: Dictionary):
	"""Aplicar recomendacion de delay recibida"""
	if recommendation.has("recommended_delay"):
		var recommended_delay = recommendation.recommended_delay
		print("✅ Aplicando recomendacion: %.4fs delay" % recommended_delay)
		
		delay_spinbox.value = recommended_delay
		# El cambio en delay_spinbox disparara _on_delay_changed automaticamente

func validate_delay_settings() -> bool:
	"""Validar configuracion de delay"""
	var delay = current_settings.frame_delay
	if delay <= 0 or delay > 1.0:
		print("❌ Delay invalido: %.4fs" % delay)
		return false
	
	return true

# ========================================================================
# FUNCIONES PUBLICAS - EXTENDIDAS
# ========================================================================

func get_settings() -> Dictionary:
	"""Obtener configuracion actual completa"""
	return current_settings.duplicate()

func get_current_settings() -> Dictionary:
	"""Alias para compatibilidad"""
	return get_settings()

func apply_settings(settings: Dictionary):
	"""Aplicar configuracion externa"""
	print("📥 Aplicando configuracion externa: %s" % str(settings))
	
	for key in settings:
		if key in current_settings:
			current_settings[key] = settings[key]
	
	# Sincronizar FPS y delay si es necesario
	_sync_fps_and_delay()
	
	_apply_current_settings()
	settings_changed.emit(current_settings.duplicate())

func _sync_fps_and_delay():
	"""Sincronizar valores de FPS y delay"""
	# Si tenemos FPS pero no delay, calcular delay
	if current_settings.has("fps") and not current_settings.has("frame_delay"):
		current_settings.frame_delay = 1.0 / current_settings.fps if current_settings.fps > 0 else 0.033333
		current_settings.fps_equivalent = current_settings.fps
	
	# Si tenemos delay pero no FPS equivalente, calcular FPS
	elif current_settings.has("frame_delay") and not current_settings.has("fps_equivalent"):
		current_settings.fps_equivalent = 1.0 / current_settings.frame_delay if current_settings.frame_delay > 0 else 30.0
		current_settings.fps = int(current_settings.fps_equivalent)

func reset_to_defaults():
	"""Resetear a valores por defecto con delay system"""
	print("🔄 Reseteando a valores por defecto con delay system")
	
	current_settings = {
		"directions": 16,
		"sprite_size": 128,
		"fps": 30,
		"frame_delay": 0.033333,  # 30 FPS equivalent
		"fps_equivalent": 30.0,   
		"pixelize": true,
		"camera_angle": 45.0,
		"camera_height": 12.0,
		"north_offset": 0.0,
		"capture_area_size": 4.5,
		"auto_north_detection": true,
		"auto_delay_recommendation": true,  
		"show_debug_frame_numbers": true,  
		"timing_validation": true
	}
	
	_apply_current_settings()
	settings_changed.emit(current_settings.duplicate())

func apply_preset(preset_name: String):
	"""Aplicar preset especifico - EXTENDIDO CON DELAY SYSTEM"""
	print("🎯 Aplicando preset con delay system: %s" % preset_name)
	
	match preset_name:
		"rts_standard":
			current_settings.directions = 16
			current_settings.sprite_size = 128
			current_settings.camera_angle = 45.0
			current_settings.capture_area_size = 8.0
			current_settings.auto_north_detection = true
			current_settings.frame_delay = 0.033333  # 30 FPS
			current_settings.fps_equivalent = 30.0
			current_settings.fps = 30
		
		"high_quality":
			current_settings.sprite_size = 128
			current_settings.fps = 24
			current_settings.frame_delay = 0.041667  # 24 FPS cinematico
			current_settings.fps_equivalent = 24.0
			current_settings.capture_area_size = 6.0
			current_settings.auto_north_detection = true
		
		"fast_preview":
			current_settings.directions = 8
			current_settings.sprite_size = 256
			current_settings.fps = 15
			current_settings.frame_delay = 0.066667  # 15 FPS
			current_settings.fps_equivalent = 15.0
			current_settings.capture_area_size = 10.0
			current_settings.auto_north_detection = true
		
		"model_showcase":
			current_settings.sprite_size = 128
			current_settings.fps = 60
			current_settings.frame_delay = 0.016667  # 60 FPS ultra smooth
			current_settings.fps_equivalent = 60.0
			current_settings.capture_area_size = 4.0
			current_settings.auto_north_detection = true
			current_settings.directions = 16
		
		"pixel_art":
			current_settings.sprite_size = 64
			current_settings.fps = 12
			current_settings.frame_delay = 0.083333  # 12 FPS retro
			current_settings.fps_equivalent = 12.0
			current_settings.capture_area_size = 6.0
			current_settings.pixelize = true
			current_settings.directions = 8
		
		"debug_large":
			current_settings.sprite_size = 128
			current_settings.fps = 10
			current_settings.frame_delay = 0.1  # 10 FPS debug
			current_settings.fps_equivalent = 10.0
			current_settings.capture_area_size = 3.0
			current_settings.directions = 4
	
	_apply_current_settings()
	preset_applied.emit(preset_name)
	settings_changed.emit(current_settings.duplicate())

# ========================================================================
# FUNCIONES DE INFORMACION - EXTENDIDAS
# ========================================================================

func get_capture_info() -> String:
	"""Obtener informacion de captura para mostrar al usuario"""
	var area = current_settings.capture_area_size
	var description = ""
	
	if area <= 4.0:
		description = "Gigante - El modelo llena casi todo el sprite"
	elif area <= 6.0:
		description = "Grande - Modelo prominente en el sprite"
	elif area <= 8.0:
		description = "Normal - Tamaño balanceado"
	elif area <= 12.0:
		description = "Pequeño - Modelo con mucho espacio alrededor"
	else:
		description = "Muy pequeño - Modelo se ve lejano"
	
	return "Area: %.1f (%s)" % [area, description]

func get_orientation_info() -> String:
	"""Obtener informacion de orientacion"""
	var angle = current_settings.north_offset
	var direction = ""
	
	if angle >= 0 and angle < 45:
		direction = "Norte"
	elif angle >= 45 and angle < 135:
		direction = "Este"
	elif angle >= 135 and angle < 225:
		direction = "Sur"
	elif angle >= 225 and angle < 315:
		direction = "Oeste"
	else:
		direction = "Norte"
	
	return "%.0f° (%s)" % [angle, direction]

func get_delay_info() -> String:
	"""NUEVO: Obtener informacion del delay system"""
	var delay = current_settings.frame_delay
	var fps_equiv = current_settings.fps_equivalent
	
	var quality = ""
	if fps_equiv >= 60:
		quality = "Ultra suave"
	elif fps_equiv >= 30:
		quality = "Suave"
	elif fps_equiv >= 24:
		quality = "Cinematico"
	elif fps_equiv >= 12:
		quality = "Estandar"
	else:
		quality = "Retro"
	
	return "Delay: %.3fs (%.1f FPS - %s)" % [delay, fps_equiv, quality]

# ========================================================================
# FUNCIONES DE DEBUG - EXTENDIDAS
# ========================================================================

func debug_settings():
	"""Debug de configuracion actual con delay system"""
	print("\n=== SETTINGS PANEL DEBUG CON DELAY SYSTEM ===")
	print("Configuracion actual:")
	for key in current_settings:
		print("  %s: %s" % [key, str(current_settings[key])])
	
	print("\nDelay System:")
	print("  Frame delay: %.4fs" % current_settings.frame_delay)
	print("  FPS equivalent: %.1f" % current_settings.fps_equivalent)
	print("  Auto-recomendacion: %s" % current_settings.auto_delay_recommendation)
	print("===============================================\n")

func validate_settings() -> bool:
	"""Validar que la configuracion sea valida - EXTENDIDA"""
	var valid = true
	
	if current_settings.directions < 4 or current_settings.directions > 32:
		print("❌ Direcciones invalidas: %d" % current_settings.directions)
		valid = false
	
	if current_settings.sprite_size < 32 or current_settings.sprite_size > 2048:
		print("❌ Tamaño de sprite invalido: %d" % current_settings.sprite_size)
		valid = false
	
	if current_settings.fps < 1 or current_settings.fps > 120:
		print("❌ FPS invalido: %d" % current_settings.fps)
		valid = false
	
	if current_settings.capture_area_size < 1.0 or current_settings.capture_area_size > 50.0:
		print("❌ Area de captura invalida: %.1f" % current_settings.capture_area_size)
		valid = false
	
	# NUEVAS VALIDACIONES PARA DELAY SYSTEM
	if current_settings.frame_delay < 0.001 or current_settings.frame_delay > 1.0:
		print("❌ Frame delay invalido: %.4fs" % current_settings.frame_delay)
		valid = false
	
	if current_settings.fps_equivalent < 1.0 or current_settings.fps_equivalent > 1000.0:
		print("❌ FPS equivalente invalido: %.1f" % current_settings.fps_equivalent)
		valid = false
	
	return valid
