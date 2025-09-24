# scripts/viewer/ui/settings_panel.gd
# Panel COMPLETO con sistema de delay integrado + SHADER AVANZADO - LISTO PARA PRODUCCION
# Input: Cambios en controles de configuracion
# Output: Señales con configuracion actualizada incluyendo delay system y shader avanzado

extends VBoxContainer



# Señales especificas de este panel
signal settings_changed(settings: Dictionary)
signal preset_applied(preset_name: String)
signal request_auto_north_detection()
# NUEVA SEÑAL: Para shader avanzado
signal shader_settings_changed(shader_settings: Dictionary)

#tamaño captura
var capture_resolution_buttons: Array[Button] = []
var current_sprite_resolution: int = 128
var resolution_info_label: Label


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

# NUEVAS VARIABLES PARA SHADER AVANZADO
var advanced_shader_panel: Control = null
var model_preview_panel: Control = null
var show_shader_panel_button: Button = null
var current_shader_settings: Dictionary = {}
var shader_currently_applied: bool = false

# NUEVO: Variable para evitar loops infinitos en sincronización
var _is_syncing_pixelize: bool = false

# NUEVO: Variable para tracking de wiggle automático
var _is_auto_wiggling: bool = false

# Configuracion interna ESTOS SON LOS PARAMETROS INICIALES
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
	"capture_area_size": 3.0,
	"auto_north_detection": false,
	"timing_validation": true,
	# NUEVOS CAMPOS PARA SHADER AVANZADO
	"use_advanced_shader": false,
	"advanced_shader": {}
}


func trigger_pixelize_wiggle_on_model_change():
	"""API pública para activar wiggle cuando cambia el modelo"""
	call_deferred("apply_wiggle_strategy_on_model_load")



func apply_wiggle_strategy_on_model_load():
	"""Aplicar estrategia wiggle al cargar modelo - SOLO SI ESTÁ ACTIVADO"""
	
	if _is_auto_wiggling:
		print("⚠️ Ya se está ejecutando wiggle, saltando...")
		return
	
	if not pixelize_check:
		print("⚠️ pixelize_check no disponible para wiggle")
		return
	
	# SOLO hacer wiggle si la pixelización está activada
	if pixelize_check.button_pressed:
		#print("🔄 Ejecutando estrategia wiggle (desactivar y reactivar pixelización)...")
		
		_is_auto_wiggling = true
		
		# Desactivar
		pixelize_check.button_pressed = false
		_on_pixelize_changed(false)
		
		# Esperar un frame
		await get_tree().process_frame
		
		# Reactivar
		pixelize_check.button_pressed = true
		_on_pixelize_changed(true)
		
		_is_auto_wiggling = false
		
		print("✅ Estrategia wiggle completada")
	else:
		print("ℹ️ Pixelización desactivada, no se aplica wiggle")
		
		
func _ready():
	print("⚙️ SettingsPanel con DELAY SYSTEM + SHADER AVANZADO inicializado")
	_create_ui()
	_apply_current_settings()
	_initialize_shader_system()

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
	basic_title.text = "Configuracion Basica"
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
	
	# SECCION MODIFICADA: EFECTOS AVANZADOS (antes era solo pixelizado)
	var effects_title = Label.new()
	effects_title.text = "🎨 EFECTOS"
	effects_title.add_theme_font_size_override("font_size", 14)
	effects_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(effects_title)
	
	# Container horizontal para checkbox y botón avanzado
	var pixelize_container = HBoxContainer.new()
	add_child(pixelize_container)
	
	# Pixelizado básico
	pixelize_check = CheckBox.new()
	pixelize_check.text = "Aplicar pixelizacion"
	pixelize_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pixelize_check.toggled.connect(_on_pixelize_changed)
	pixelize_check.button_pressed =true
	print ("pixelize_check.button_pressed " + str( pixelize_check.button_pressed))
	
	pixelize_container.add_child(pixelize_check)
	
	# Botón avanzado
	show_shader_panel_button = Button.new()
	show_shader_panel_button.text = "⚙️ Avanzado"
	show_shader_panel_button.custom_minimum_size.x = 100
	show_shader_panel_button.pressed.connect(_on_show_advanced_shader_panel)
	pixelize_container.add_child(show_shader_panel_button)
	
	# Descripción
	var effects_desc = Label.new()
	effects_desc.text = "Click 'Avanzado' para configuración detallada de efectos"
	effects_desc.add_theme_font_size_override("font_size", 9)
	effects_desc.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	effects_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(effects_desc)




# ========================================================================
# FUNCIÓN CORREGIDA: CONECTAR PANEL AVANZADO
# ========================================================================

func _get_model_preview_panel_reference():
	"""Obtener referencia al ModelPreviewPanel"""
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		model_preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if model_preview_panel:
			print("✅ ModelPreviewPanel encontrado: %s" % model_preview_panel.get_path())
		else:
			print("❌ ModelPreviewPanel no encontrado")
	else:
		print("❌ ViewerModular no encontrado")




# ========================================================================
# FUNCIÓN CORREGIDA: CREAR PANEL AVANZADO CON CONEXIONES
# ========================================================================

func _create_advanced_shader_panel():
	"""Crear panel avanzado usando el script completo AdvancedShaderPanel"""
	
	var advanced_window = Window.new()
	advanced_window.title = "Configuración Avanzada de Shader"
	advanced_window.size = Vector2i(500, 750)
	advanced_window.min_size = Vector2i(500, 700)
	advanced_window.unresizable = false
	advanced_window.transient = true
	advanced_window.exclusive = false
	
	# Posicionar ventana
	var _screen_size = DisplayServer.screen_get_size()
	advanced_window.position = Vector2i(900, 50)
	
	get_tree().current_scene.add_child(advanced_window)
	
	# Container principal
	var window_margin = MarginContainer.new()
	window_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window_margin.add_theme_constant_override("margin_left", 10)
	window_margin.add_theme_constant_override("margin_right", 10)
	window_margin.add_theme_constant_override("margin_top", 10)
	window_margin.add_theme_constant_override("margin_bottom", 60)
	advanced_window.add_child(window_margin)
	
	# ✅ CREAR PANEL AVANZADO USANDO EL SCRIPT COMPLETO
	var advanced_shader_script = load("res://scripts/ui/advanced_shader_panel.gd")
	if advanced_shader_script:
		advanced_shader_panel = advanced_shader_script.new()
		advanced_shader_panel.name = "AdvancedShaderPanel"
		window_margin.add_child(advanced_shader_panel)
		print("✅ Panel avanzado completo instanciado desde script")
	else:
		print("❌ No se pudo cargar advanced_shader_panel.gd")
		return null
	
	# Botones inferiores
	var button_background = Panel.new()
	button_background.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	button_background.size.y = 50
	advanced_window.add_child(button_background)
	
	var button_container = HBoxContainer.new()
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 15)
	button_background.add_child(button_container)
	
	var apply_button = Button.new()
	apply_button.text = "✅ Aplicar y Cerrar"
	apply_button.custom_minimum_size.x = 120
	apply_button.pressed.connect(func(): 
		# Forzar aplicación de configuración actual
		if advanced_shader_panel and advanced_shader_panel.has_method("force_emit_current_settings"):
			advanced_shader_panel.force_emit_current_settings()
		advanced_window.hide()
	)
	button_container.add_child(apply_button)
	
	var clear_button = Button.new()
	clear_button.text = "🧹 Limpiar Todo"
	clear_button.custom_minimum_size.x = 100
	clear_button.pressed.connect(_on_clear_shader_pressed)
	button_container.add_child(clear_button)
	
	var close_button = Button.new()
	close_button.text = "❌ Cerrar"
	close_button.custom_minimum_size.x = 80
	close_button.pressed.connect(func(): advanced_window.hide())
	button_container.add_child(close_button)
	
	# ✅ CONECTAR SEÑALES INMEDIATAMENTE
	_connect_advanced_shader_signals()
	
	# Configurar cierre
	advanced_window.close_requested.connect(func(): advanced_window.hide())
	
	print("✅ Panel avanzado COMPLETO creado con todas las características")
	return advanced_window



func _connect_advanced_shader_signals():
	"""Conectar señales del panel avanzado completo"""
	if not advanced_shader_panel:
		print("❌ No hay advanced_shader_panel para conectar señales")
		return
	
	# Verificar que tiene la señal correcta
	if advanced_shader_panel.has_signal("shader_settings_changed"):
		# Conectar la señal principal
		if not advanced_shader_panel.shader_settings_changed.is_connected(_on_advanced_shader_settings_changed):
			advanced_shader_panel.shader_settings_changed.connect(_on_advanced_shader_settings_changed)
			#print("✅ Señal shader_settings_changed conectada desde panel completo")
		
		# Conectar señal de reset si existe
		if advanced_shader_panel.has_signal("reset_to_defaults_requested"):
			if not advanced_shader_panel.reset_to_defaults_requested.is_connected(_on_shader_reset_requested):
				advanced_shader_panel.reset_to_defaults_requested.connect(_on_shader_reset_requested)
				print("✅ Señal reset_to_defaults_requested conectada")
	else:
		print("❌ Panel avanzado no tiene señal shader_settings_changed")
	
	# Obtener referencia al preview panel
	_get_model_preview_panel_reference()

func _on_clear_shader_pressed():
	"""Limpiar shader completamente"""
	print("🧹 Limpiando shader...")
	_remove_shader_from_preview()
	
	# Actualizar checkbox básico
	if pixelize_check:
		pixelize_check.button_pressed = false
		current_settings.pixelize = false
		shader_currently_applied = false
	
	print("✅ Shader limpiado completamente")

# ========================================================================
# FUNCIÓN PARA AGREGAR AL _ready() EXISTENTE
# ========================================================================

func _initialize_corrected_shader_system():
	"""Inicializar sistema de shader corregido - LLAMAR EN _ready()"""
	print("🔧 Inicializando sistema de shader CORREGIDO...")
	
	# Obtener referencia al preview panel
	_get_model_preview_panel_reference()
	
	# Si ya existe el panel avanzado, conectar señales
	if advanced_shader_panel:
		_connect_advanced_shader_signals()
	
	print("✅ Sistema de shader corregido inicializado")

# ========================================================================
# FUNCIÓN DE DIAGNÓSTICO
# ========================================================================

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
	
	var seconds_label = Label.new()
	seconds_label.text = "s"
	delay_container.add_child(seconds_label)
	
	fps_equiv_label = Label.new()
	fps_equiv_label.text = "FPS Equiv: 30.0"
	fps_equiv_label.custom_minimum_size.x = 80
	fps_equiv_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	delay_container.add_child(fps_equiv_label)
	
	# Informacion de delay
	delay_info_label = Label.new()
	delay_info_label.text = "💡 Delay mas bajo = animacion mas fluida, delay mas alto = menos frames"
	delay_info_label.add_theme_font_size_override("font_size", 9)
	delay_info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	delay_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(delay_info_label)
	
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
	camera_title.text = "📷 Camara"
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
	
	# Altura de camara
	var camera_height_container = HBoxContainer.new()
	add_child(camera_height_container)
	
	var height_label = Label.new()
	height_label.text = "Altura:"
	height_label.custom_minimum_size.x = 80
	camera_height_container.add_child(height_label)
	
	camera_height_slider = HSlider.new()
	camera_height_slider.min_value = 5.0
	camera_height_slider.max_value = 30.0
	camera_height_slider.value = 12.0
	camera_height_slider.step = 0.5
	camera_height_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camera_height_slider.value_changed.connect(_on_camera_height_changed)
	camera_height_container.add_child(camera_height_slider)
	
	camera_height_label = Label.new()
	camera_height_label.text = "12.0"
	camera_height_label.custom_minimum_size.x = 40
	camera_height_container.add_child(camera_height_label)

func _on_camera_height_changed(value: float):
	"""Manejar cambio en altura de camara"""
	current_settings.camera_height = value
	camera_height_label.text = "%.1f" % value
	print("📏 Altura de camara: %.1f" % value)
	settings_changed.emit(current_settings.duplicate())


func _create_capture_area_settings():
	"""Crear configuración COMPLETA: resolución de sprite + tamaño del modelo - CON DEBUG"""
	print("🔧 Iniciando creación de capture area settings...")
	
	# ===== SECCIÓN 1: RESOLUCIÓN DE SPRITE =====
	var resolution_title = Label.new()
	resolution_title.text = "🖼️ Resolución de Sprite"
	resolution_title.add_theme_font_size_override("font_size", 14)
	resolution_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(resolution_title)
	print("✅ Título de resolución agregado")
	
	# Descripción de resolución
	var resolution_desc = Label.new()
	resolution_desc.text = "Resolución del sprite final y viewport de preview"
	resolution_desc.add_theme_font_size_override("font_size", 10)
	resolution_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	resolution_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(resolution_desc)
	print("✅ Descripción de resolución agregada")
	
	# Contenedor para botones de resolución
	var resolution_container = HBoxContainer.new()
	resolution_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(resolution_container)
	print("✅ Container de resolución agregado")
	
	# Definir opciones de resolución
	var resolution_options = [32, 64, 128, 256, 512]
	
	# Inicializar array si no existe
	if capture_resolution_buttons == null:
		capture_resolution_buttons = []
	
	# Crear botones radio para cada resolución
	for resolution in resolution_options:
		var button = Button.new()
		button.text = str(resolution)
		button.custom_minimum_size.x = 50
		button.toggle_mode = true
		button.button_group = ButtonGroup.new() if capture_resolution_buttons.is_empty() else capture_resolution_buttons[0].button_group
		
		# Configurar estado por defecto (128)
		if resolution == 128:
			button.button_pressed = true
			current_sprite_resolution = 128
		
		# Conectar señal
		button.pressed.connect(_on_resolution_selected.bind(resolution))
		
		# Tooltip informativo
		button.tooltip_text = "%dx%d píxeles" % [resolution, resolution]
		
		capture_resolution_buttons.append(button)
		resolution_container.add_child(button)
	
	print("✅ %d botones de resolución creados" % capture_resolution_buttons.size())
	
	# Label informativo de resolución actual
	resolution_info_label = Label.new()
	resolution_info_label.text = "Resolución actual: 128x128 píxeles"
	resolution_info_label.add_theme_font_size_override("font_size", 10)
	resolution_info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	resolution_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(resolution_info_label)
	print("✅ Label de info de resolución agregado")
	
	# ===== SEPARADOR =====
	add_child(HSeparator.new())
	print("✅ Separador agregado")
	
	# ===== SECCIÓN 2: TAMAÑO DEL MODELO (ÁREA DE CAPTURA) =====
	var capture_title = Label.new()
	capture_title.text = "📏 Tamaño del Modelo"
	capture_title.add_theme_font_size_override("font_size", 14)
	capture_title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(capture_title)
	print("✅ Título de tamaño agregado")
	
	# Descripción del área de captura
	var capture_desc = Label.new()
	capture_desc.text = "Controla qué tan grande se ve el modelo en el sprite final"
	capture_desc.add_theme_font_size_override("font_size", 10)
	capture_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	capture_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(capture_desc)
	print("✅ Descripción de tamaño agregada")
	
	# Slider de área de captura
	var capture_container = HBoxContainer.new()
	add_child(capture_container)
	print("✅ Container de slider agregado")
	
	var capture_label = Label.new()
	capture_label.text = "Tamaño:"
	capture_label.custom_minimum_size.x = 80
	capture_container.add_child(capture_label)
	
	capture_area_slider = HSlider.new()
	capture_area_slider.min_value = 0.5    # Modelo MUY grande (área pequeña)
	capture_area_slider.max_value = 20.0   # Modelo pequeño (área grande)
	capture_area_slider.value = 3.0        # Tamaño normal
	capture_area_slider.step = 0.1
	capture_area_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capture_area_slider.value_changed.connect(_on_capture_area_changed)
	capture_container.add_child(capture_area_slider)
	print("✅ Slider de área de captura creado")
	
	capture_area_label = Label.new()
	capture_area_label.text = str(capture_area_slider.value)
	capture_area_label.custom_minimum_size.x = 40
	capture_container.add_child(capture_area_label)
	print("✅ Label de valor de área agregado")
	
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
	print("✅ 4 botones de preset creados")
	
	# Información adicional
	var info_label = Label.new()
	info_label.text = "💡 Valores menores = modelo más grande en sprite"
	info_label.add_theme_font_size_override("font_size", 9)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(info_label)
	print("✅ Label de información agregado")
	
	print("🎯 _create_capture_area_settings() COMPLETADO EXITOSAMENTE")


# ========================================================================
# FUNCIÓN MODIFICADA: _on_resolution_selected() - CON COMPENSACIÓN AUTOMÁTICA DE TAMAÑO
# Ubicación: pixelize3d_fbx/scripts/viewer/ui/settings_panel.gd
# Input: resolution (int) - Nueva resolución seleccionada (32, 64, 128, 256, 512)
# Output: Actualiza resolución y compensa automáticamente el área de captura para mantener tamaño visual
# ========================================================================
func _on_resolution_selected(resolution: int):
	"""Manejar selección de resolución de sprite - CON COMPENSACIÓN AUTOMÁTICA DE TAMAÑO"""
	print("🖼️ Resolución seleccionada: %d (anterior: %d)" % [resolution, current_sprite_resolution])
	
	# ✅ COMPENSACIÓN AUTOMÁTICA DE TAMAÑO
	var previous_resolution = current_sprite_resolution
	var compensated_area = capture_area_slider.value
	var area_changed = false
	
	# Solo aplicar compensación si hay cambio real de resolución
	if previous_resolution > 0 and previous_resolution != resolution:
		# Calcular factor de compensación
		# Factor > 1.0 = resolución aumentó, necesitamos área menor para mantener tamaño visual
		# Factor < 1.0 = resolución disminuyó, necesitamos área mayor para mantener tamaño visual
		var resolution_factor = float(resolution) / float(previous_resolution)
		
		# Aplicar compensación (relación directa: más resolución = área proportcionalmente menor)
		var current_area = capture_area_slider.value
		compensated_area = current_area * resolution_factor
		
		print("  🔧 Compensación automática:")
		print("    Factor de resolución: %.3f (%d→%d)" % [resolution_factor, previous_resolution, resolution])
		print("    Área actual: %.2f → Área compensada: %.2f" % [current_area, compensated_area])
		
		# Aplicar límites del slider (usar extremos si se exceden)
		if compensated_area < capture_area_slider.min_value:
			compensated_area = capture_area_slider.min_value
			print("    ⚠️ Área limitada al mínimo: %.2f" % compensated_area)
		elif compensated_area > capture_area_slider.max_value:
			compensated_area = capture_area_slider.max_value
			print("    ⚠️ Área limitada al máximo: %.2f" % compensated_area)
		
		area_changed = true
	else:
		print("  ℹ️ Sin compensación (primera configuración o misma resolución)")
	
	# Actualizar configuración de resolución
	current_sprite_resolution = resolution
	current_settings.sprite_size = resolution
	
	# Actualizar label informativo de resolución
	if resolution_info_label:
		resolution_info_label.text = "Resolución actual: %dx%d píxeles" % [resolution, resolution]
	
	# ✅ APLICAR COMPENSACIÓN AL SLIDER AUTOMÁTICAMENTE
	if area_changed and compensated_area != capture_area_slider.value:
		print("  📏 Aplicando área compensada: %.2f" % compensated_area)
		# Al cambiar el slider, se disparará _on_capture_area_changed() automáticamente
		# que actualizará current_settings.capture_area_size y emitirá settings_changed
		capture_area_slider.value = compensated_area
		# NO emitimos settings_changed aquí porque _on_capture_area_changed() ya lo hará
	else:
		# Si no hubo cambio de área, emitir señal manualmente
		print("  ✅ Área de captura sin cambios: %.2f" % compensated_area)
		settings_changed.emit(_get_enhanced_settings())
	
	print("  ✅ Configuración de resolución actualizada con compensación")
	
	# Actualizar visual (esto no emite señales)
	_update_capture_area_visual()
	
	# ✅ WIGGLE FIX: Forzar re-centrado con micro-cambio del slider
	_perform_centering_wiggle()
	
	print("  🎯 Compensación automática completada - tamaño visual mantenido")
# ========================================================================
# FUNCIÓN NUEVA: _perform_centering_wiggle()
# ========================================================================
func _perform_centering_wiggle():
	"""Realizar wiggle del slider para forzar re-centrado"""
	if not capture_area_slider:
		print("❌ No hay capture_area_slider para wiggle")
		return
	
	#print("🔄 Iniciando wiggle fix para centrado...")
	
	# Guardar valor original
	var original_value = capture_area_slider.value
	#print("  💾 Valor original del slider: %.3f" % original_value)
	
	# Calcular valores para wiggle (asegurar que estén en rango válido)
	var wiggle_up = min( capture_area_slider.value + 0.1, capture_area_slider.max_value)
	var wiggle_down = max( capture_area_slider.value - 0.1, capture_area_slider.min_value)
	
	# Si el wiggle no hace diferencia (valor muy cerca del límite), usar diferente estrategia
	if abs(wiggle_up - original_value) < 0.05:
		wiggle_up = max( capture_area_slider.value - 0.1, capture_area_slider.min_value)
	if abs(wiggle_down -  capture_area_slider.value) < 0.05:
		wiggle_down = min( capture_area_slider.value + 0.1, capture_area_slider.max_value)
	
	#print("  📈 Wiggle up: %.3f" % wiggle_up)
	#print("  📉 Wiggle down: %.3f" % wiggle_down)
	
	# Realizar wiggle con delays
	_execute_wiggle_sequence(original_value, wiggle_up, wiggle_down)

# ========================================================================
# FUNCIÓN NUEVA: _execute_wiggle_sequence()
# ========================================================================
func _execute_wiggle_sequence(original: float, up: float, down: float):
	"""Ejecutar secuencia de wiggle con timing correcto"""
	
	# Paso 1: Subir +0.1
	#print("  🔄 Paso 1: Aplicando +0.1...")
	capture_area_slider.value = capture_area_slider.value + 1
	await get_tree().process_frame
	await get_tree().process_frame  # Esperar que se procese completamente

	# Paso 3: Volver al valor original
	#print("  🔄 Paso 2: Restaurando valor original...")
	capture_area_slider.value = capture_area_slider.value -1
	await get_tree().process_frame

	
	## Paso 2: Bajar -0.1 del original (no del valor up)
	#print("  🔄 Paso 2: Aplicando -0.1...")
	#capture_area_slider.value = down
	#await get_tree().process_frame
	#await get_tree().process_frame  # Esperar que se procese completamente
	

	
	#print("  ✅ Wiggle fix completado - modelo debería estar centrado")

# ========================================================================
# FUNCIÓN ALTERNATIVA: wiggle_immediate() - Para casos extremos
# ========================================================================
func _perform_immediate_wiggle():
	"""Wiggle inmediato sin delays (alternativa más rápida)"""
	if not capture_area_slider:
		return
	
	#print("⚡ Wiggle inmediato...")
	var original = capture_area_slider.value
	
	# Cambio rápido sin esperas
	capture_area_slider.value = capture_area_slider.value + 0.1
	capture_area_slider.value = capture_area_slider.value - 0.1  
	#capture_area_slider.value = original
	
	#print("  ✅ Wiggle inmediato completado")

# ========================================================================
# FUNCIÓN DE DEBUG: test_wiggle_manually()
# ========================================================================
func test_wiggle_manually():
	"""Función para probar el wiggle manualmente desde consola"""
	print("🧪 === TESTING WIGGLE MANUAL ===")
	
	if capture_area_slider:
		#print("Valor actual del slider: %.3f" % capture_area_slider.value)
		_perform_centering_wiggle()
	else:
		print("❌ No hay slider disponible")

# ========================================================================
# COMANDOS PARA PROBAR DESDE CONSOLA:
# ========================================================================
# var settings = get_node("/root/ViewerModular/HSplitContainer/LeftPanel/SettingsPanel")
# settings.test_wiggle_manually()
#
# # O para wiggle inmediato:
# settings._perform_immediate_wiggle()
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
	if directions_spinbox: directions_spinbox.value = current_settings.directions
	if sprite_size_spinbox: sprite_size_spinbox.value = current_settings.sprite_size
	if fps_spinbox: fps_spinbox.value = current_settings.fps
	if pixelize_check: pixelize_check.button_pressed = current_settings.pixelize
	
	# Aplicar valores de delay system
	if delay_spinbox: delay_spinbox.value = current_settings.frame_delay
	
	# Aplicar valores de camara
	if camera_angle_slider: camera_angle_slider.value = current_settings.camera_angle
	if camera_height_slider: camera_height_slider.value = current_settings.camera_height
	
	# Aplicar valores de orientacion
	if north_offset_slider: north_offset_slider.value = current_settings.north_offset
	if auto_north_check: auto_north_check.button_pressed = current_settings.auto_north_detection
	
	# Aplicar area de captura
	#if capture_area_slider: capture_area_slider.value = current_settings.capture_area_size
	if not capture_resolution_buttons.is_empty():
		var target_resolution = current_settings.sprite_size
		for button in capture_resolution_buttons:
			button.button_pressed = (int(button.text) == target_resolution)
		
		if resolution_info_label:
			resolution_info_label.text = "Resolución actual: %dx%d píxeles" % [target_resolution, target_resolution]
	
	# Aplicar área de captura al slider (RESTAURADO)
	if capture_area_slider: 
		capture_area_slider.value = current_settings.capture_area_size
	
	
	# Actualizar labels
	_on_camera_angle_changed(current_settings.camera_angle)
	_on_camera_height_changed(current_settings.camera_height)  
	_on_north_offset_changed(current_settings.north_offset)
	_on_capture_area_changed(current_settings.capture_area_size)
	_on_delay_changed(current_settings.frame_delay)

# ========================================================================
# MANEJADORES DE EVENTOS - EXTENDIDOS PARA DELAY SYSTEM Y SHADER AVANZADO
# ========================================================================

func _on_setting_changed(value = null):
	"""Manejar cambios en configuracion basica"""
	# Actualizar configuracion interna
	if directions_spinbox: current_settings.directions = int(directions_spinbox.value)
	if sprite_size_spinbox: current_settings.sprite_size = int(sprite_size_spinbox.value)
	if fps_spinbox: current_settings.fps = int(fps_spinbox.value)
	if pixelize_check: current_settings.pixelize = pixelize_check.button_pressed
	
	print("⚙️ Configuracion basica actualizada")
	settings_changed.emit(_get_enhanced_settings())




func _emit_shader_settings():
	"""Emitir configuración - YA NO NECESARIA con el panel completo"""
	# Esta función ya no es necesaria porque el panel completo
	# maneja sus propias señales automáticamente
	print("⚠️ _emit_shader_settings() llamada - usar panel completo en su lugar")
	
func _apply_shader_to_preview_direct(shader_settings: Dictionary):
	"""Aplicar shader directamente al preview sin efectos secundarios"""
	if not model_preview_panel:
		_get_model_preview_panel_reference()
	
	if not model_preview_panel:
		print("❌ No hay ModelPreviewPanel")
		return
	
	if model_preview_panel.has_method("apply_advanced_shader"):
		model_preview_panel.apply_advanced_shader(shader_settings)
		shader_currently_applied = true
		print("✅ Shader aplicado directamente")
	else:
		print("❌ ModelPreviewPanel no tiene apply_advanced_shader")


func _apply_pixelize_to_preview_only(enabled: bool):
	"""Aplicar pixelización SOLO al preview sin emitir señales que muevan cámara"""
	
	# Obtener referencia al ModelPreviewPanel si no la tenemos
	if not model_preview_panel:
		_get_model_preview_panel_reference()
	
	if not model_preview_panel:
		print("   ⚠️ No hay referencia al ModelPreviewPanel")
		return
	
	# Crear configuración mínima para pixelización básica
	var pixelize_settings = {
		"pixelize_enabled": enabled,
		"pixel_size": 2.0,  # Valor por defecto
		"reduce_colors": false,
		"enable_dithering": false,
		"enable_outline": false
	}
	
	# Si hay configuración avanzada, usarla en su lugar
	if not current_shader_settings.is_empty():
		pixelize_settings = current_shader_settings.duplicate()
		pixelize_settings["pixelize_enabled"] = enabled
	
	# Aplicar al modelo en preview usando método aislado
	if model_preview_panel.has_method("apply_advanced_shader"):
		model_preview_panel.apply_advanced_shader(pixelize_settings)
		print("   ✅ Pixelización aplicada al preview: %s" % enabled)
	else:
		print("   ❌ ModelPreviewPanel no tiene método apply_advanced_shader")
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
	settings_changed.emit(_get_enhanced_settings())

# NUEVO: Manejador especifico para cambios en delay
func _on_delay_changed(new_delay: float):
	"""Manejar cambio de delay y sincronizar con FPS"""
	current_settings.frame_delay = new_delay
	current_settings.fps_equivalent = 1.0 / new_delay 
	
	# Actualizar FPS spinbox para mantener sincronia
	if fps_spinbox:
		fps_spinbox.value = current_settings.fps_equivalent
		current_settings.fps = int(current_settings.fps_equivalent)
	
	# Actualizar label de FPS equivalente
	_update_fps_equivalent_label()
	
	print("⏱️ Delay cambiado: %.4fs → FPS equiv: %.1f" % [new_delay, current_settings.fps_equivalent])
	settings_changed.emit(_get_enhanced_settings())
	
func _on_delay_preset_pressed(delay_value: float):
	"""Aplicar preset de delay"""
	if delay_spinbox: delay_spinbox.value = delay_value
	print("⏱️ Preset de delay aplicado: %.4fs" % delay_value)

func _on_camera_angle_changed(value: float):
	"""Manejar cambio en angulo de camara"""
	current_settings.camera_angle = value
	if camera_angle_label: camera_angle_label.text = "%.0f°" % value
	
	print("📐 Angulo de camara: %.1f°" % value)
	settings_changed.emit(_get_enhanced_settings())

func _on_north_offset_changed(value: float):
	"""Manejar cambio en orientacion norte"""
	current_settings.north_offset = value
	if north_offset_label: north_offset_label.text = "%.0f°" % value
	
	print("🧭 Orientacion norte: %.1f°" % value)
	settings_changed.emit(_get_enhanced_settings())


func _update_capture_area_visual():
	"""Actualizar indicador visual del area de captura"""
	# Buscar el ModelPreviewPanel y actualizar su indicador
	var viewer_coordinator = get_node_or_null("/root/ViewerModular")
	if viewer_coordinator:
		var preview_panel = viewer_coordinator.get_node_or_null("HSplitContainer/RightPanel/ModelPreviewPanel")
		if preview_panel and preview_panel.has_method("update_capture_area_indicator"):
			preview_panel.update_capture_area_indicator()
			#print("🔄 Indicador de area de captura actualizado")


func _on_auto_north_toggled(enabled: bool):
	"""Manejar deteccion automatica de norte"""
	current_settings.auto_north_detection = enabled
	print("🧭 Deteccion automatica de norte %s" % ("habilitada" if enabled else "deshabilitada"))
	if enabled:
		pass
		#request_auto_north_detection.emit()  # Nueva señal
	#settings_changed.emit(_get_enhanced_settings())

func _on_preset_pressed(angle: float):
	"""Manejar preset de orientacion"""
	if north_offset_slider: north_offset_slider.value = angle
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
# NUEVAS FUNCIONES PARA SHADER AVANZADO
# ========================================================================

func _validate_shader_system() -> bool:
	"""Validar que el sistema de shader esté correctamente configurado"""
	var validation_errors = []
	
	# 1. Verificar que existe el shader avanzado
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	if not ResourceLoader.exists(shader_path):
		validation_errors.append("Shader no encontrado en: " + shader_path)
	
	# 2. Verificar que existe el script del panel
	var panel_script_path = "res://scripts/ui/advanced_shader_panel.gd"
	if not ResourceLoader.exists(panel_script_path):
		validation_errors.append("Script del panel no encontrado en: " + panel_script_path)
	
	# 3. Verificar controles UI básicos
	if not pixelize_check:
		validation_errors.append("pixelize_check no está inicializado")
	if not show_shader_panel_button:
		validation_errors.append("show_shader_panel_button no está inicializado")
	
	if validation_errors.size() > 0:
		print("❌ ERRORES DE VALIDACIÓN DEL SISTEMA DE SHADER:")
		for error in validation_errors:
			print("  - " + error)
		
		var error_message = "Sistema de shader no configurado correctamente:\n"
		for error in validation_errors:
			error_message += "• " + error + "\n"
		
		_show_error(error_message)
		return false
	
	print("✅ Sistema de shader validado correctamente")
	return true





func _on_show_advanced_shader_panel():
	"""Mostrar el panel avanzado completo"""
	print("🎨 Mostrando panel avanzado completo...")
	
	# Validar sistema básico
	if not pixelize_check or not show_shader_panel_button:
		print("❌ Sistema de UI no está inicializado correctamente")
		return
	
	# Crear o mostrar ventana
	if not advanced_shader_panel:
		var advanced_window = _create_advanced_shader_panel()
		if not advanced_window:
			print("❌ No se pudo crear panel avanzado")
			return
		
		# Aplicar configuración actual si existe
		if not current_shader_settings.is_empty() and advanced_shader_panel.has_method("apply_settings"):
			advanced_shader_panel.apply_settings(current_shader_settings)
			print("✅ Configuración actual aplicada al panel")
		
		advanced_window.popup()
	else:
		# Buscar la ventana padre del panel
		var current_node = advanced_shader_panel.get_parent()
		while current_node != null and not current_node is Window:
			current_node = current_node.get_parent()
		
		if current_node and current_node is Window:
			# Aplicar configuración actual antes de mostrar
			if not current_shader_settings.is_empty() and advanced_shader_panel.has_method("apply_settings"):
				advanced_shader_panel.apply_settings(current_shader_settings)
			
			current_node.popup()
			print("✅ Panel avanzado mostrado con configuración actualizada")
		else:
			print("❌ No se pudo encontrar la ventana padre del panel")



func force_reload_advanced_panel():
	"""Forzar recarga completa del panel avanzado - para debugging"""
	print("🔄 Forzando recarga del panel avanzado...")
	
	# Limpiar panel existente
	if advanced_shader_panel:
		var parent_window = advanced_shader_panel.get_parent()
		while parent_window and not parent_window is Window:
			parent_window = parent_window.get_parent()
		
		if parent_window and parent_window is Window:
			parent_window.queue_free()
		
		advanced_shader_panel = null
	
	# Limpiar configuración
	current_shader_settings.clear()
	shader_currently_applied = false
	
	print("✅ Panel limpiado - próxima apertura creará panel completo nuevo")


# FUNCIÓN AUXILIAR: Crear estilo para botones
func _create_button_style(color: Color) -> StyleBoxFlat:
	"""Crear estilo visual para botones"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _on_shader_reset_requested():
	"""Resetear configuración de shader a valores por defecto"""
	print("🔄 Reseteando configuración de shader...")
	current_shader_settings.clear()
	
	if pixelize_check:
		pixelize_check.button_pressed = false
		current_settings.pixelize = false
	
	settings_changed.emit(_get_enhanced_settings())

func _show_error(message: String):
	"""Mostrar mensaje de error"""
	print("❌ Error: %s" % message)
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = message
	get_tree().current_scene.add_child(error_dialog)
	error_dialog.popup()
	error_dialog.confirmed.connect(error_dialog.queue_free)

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
		
		if delay_spinbox: delay_spinbox.value = recommended_delay
		# El cambio en delay_spinbox disparara _on_delay_changed automaticamente

func validate_delay_settings() -> bool:
	"""Validar configuracion de delay"""
	var delay = current_settings.frame_delay
	if delay <= 0 or delay > 1.0:
		print("❌ Delay invalido: %.4fs" % delay)
		return false
	
	return true

# ========================================================================
# FUNCIONES PUBLICAS - EXTENDIDAS CON SHADER AVANZADO
# ========================================================================

func get_settings() -> Dictionary:
	"""Obtener configuracion actual completa"""
	return _get_enhanced_settings()

func get_current_settings() -> Dictionary:
	"""Alias para compatibilidad"""
	return get_settings()

func apply_settings(settings: Dictionary):
	"""Aplicar configuracion externa"""
	print("📥 Aplicando configuracion externa: %s" % str(settings))
	
	for key in settings:
		if key in current_settings:
			current_settings[key] = settings[key]
	
	# Manejar configuración de shader avanzado
	if settings.has("advanced_shader") and not settings.advanced_shader.is_empty():
		current_shader_settings = settings.advanced_shader.duplicate()
		current_settings.use_advanced_shader = true
	
	# Sincronizar FPS y delay si es necesario
	_sync_fps_and_delay()
	
	_apply_current_settings()
	settings_changed.emit(_get_enhanced_settings())

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
	"""Resetear a valores por defecto con delay system y shader avanzado"""
	print("🔄 Reseteando a valores por defecto con delay system y shader avanzado")
	
	current_settings = {
		"directions": 16,
		"sprite_size": 128,
		"fps": 30,
		"frame_delay": 0.033333,  # 30 FPS equivalent
		"fps_equivalent": 30.0,   
		"pixelize": false,
		"camera_angle": 45.0,
		"camera_height": 12.0,
		"north_offset": 0.0,
		"capture_area_size": 2.5,
		"auto_north_detection": false,
		"timing_validation": true,
		"use_advanced_shader": false,
		"advanced_shader": {}
	}
	
	current_shader_settings.clear()
	
	_apply_current_settings()
	settings_changed.emit(_get_enhanced_settings())

# ========================================================================
# FUNCIONES PARA COMPATIBILIDAD CON SISTEMA EXISTENTE
# ========================================================================

func get_current_shader_configuration() -> Dictionary:
	"""Obtener configuración actual de shader para uso externo"""
	return current_shader_settings.duplicate()

func has_advanced_shader_settings() -> bool:
	"""Verificar si hay configuración avanzada de shader"""
	return not current_shader_settings.is_empty()


# ========================================================================
# FUNCIONES DE INFORMACION Y DEBUG
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
	"""Obtener informacion del delay system"""
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

func debug_settings():
	"""Debug de configuracion actual con delay system y shader avanzado"""
	print("\n=== SETTINGS PANEL DEBUG CON DELAY SYSTEM + SHADER AVANZADO ===")
	print("Configuracion actual:")
	for key in current_settings:
		print("  %s: %s" % [key, str(current_settings[key])])
	
	print("\nDelay System:")
	print("  Frame delay: %.4fs" % current_settings.frame_delay)
	print("  FPS equivalent: %.1f" % current_settings.fps_equivalent)
	
	print("\nShader Avanzado:")
	print("  Use advanced shader: %s" % current_settings.use_advanced_shader)
	print("  Advanced shader settings: %d" % current_shader_settings.size())
	if not current_shader_settings.is_empty():
		for key in current_shader_settings:
			print("    %s: %s" % [key, str(current_shader_settings[key])])
	print("===============================================\n")

func validate_settings() -> bool:
	"""Validar que la configuracion sea valida - EXTENDIDA CON SHADER"""
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
	
	# VALIDACIONES PARA DELAY SYSTEM
	if current_settings.frame_delay < 0.001 or current_settings.frame_delay > 1.0:
		print("❌ Frame delay invalido: %.4fs" % current_settings.frame_delay)
		valid = false
	
	if current_settings.fps_equivalent < 1.0 or current_settings.fps_equivalent > 1000.0:
		print("❌ FPS equivalente invalido: %.1f" % current_settings.fps_equivalent)
		valid = false
	
	return valid





# AGREGAR AL FINAL DE _ready() O EN NUEVA FUNCIÓN DE INICIALIZACIÓN:
func _initialize_shader_system_isolated():
	"""Inicializar sistema de shader avanzado - COMPLETAMENTE AISLADO"""
	_get_model_preview_panel_reference()
	
	# Si el panel ya existe, conectar señales aisladas
	if advanced_shader_panel:
		_connect_advanced_shader_signals()






func _apply_postprocessing_to_current_model():
	"""Aplicar post-processing al modelo actual"""
	if not model_preview_panel:
		return
	
	if not current_shader_settings.is_empty():
		if model_preview_panel.has_method("apply_postprocessing"):
			model_preview_panel.apply_postprocessing(current_shader_settings)
		elif model_preview_panel.has_method("apply_advanced_shader"):
			model_preview_panel.apply_advanced_shader(current_shader_settings)
		print("🔄 Post-processing re-aplicado al modelo actual")
# NUEVA FUNCIÓN: Aplicar shader al modelo en el preview
func _apply_shader_to_preview_model(shader_settings: Dictionary):
	"""Aplicar configuración de shader al modelo en el ModelPreviewPanel"""
	if not model_preview_panel:
		print("   ⚠️ No hay referencia al ModelPreviewPanel")
		return
	
	if model_preview_panel.has_method("apply_advanced_shader"):
		model_preview_panel.apply_advanced_shader(shader_settings)
		print("   ✅ Shader aplicado al modelo en preview")
	else:
		print("   ❌ ModelPreviewPanel no tiene método apply_advanced_shader")


# AGREGAR AL FINAL DE _ready() O EN NUEVA FUNCIÓN DE INICIALIZACIÓN:
func _initialize_shader_system():
	"""Inicializar sistema de shader avanzado"""
	_get_model_preview_panel_reference()
	
	# Si el panel ya existe, conectar señales
	if advanced_shader_panel:
		_connect_advanced_shader_signals()

# FUNCIÓN AUXILIAR: Verificar estado del sistema de shader (OPCIONAL - para debug)
func debug_shader_system():
	"""Debug del estado del sistema de shader"""
	print("\n🔍 === DEBUG SISTEMA DE SHADER ===")
	print("advanced_shader_panel: %s" % ("✅" if advanced_shader_panel else "❌"))
	print("model_preview_panel: %s" % ("✅" if model_preview_panel else "❌"))
	print("current_shader_settings: %d elementos" % current_shader_settings.size())
	
	if model_preview_panel:
		print("model_preview_panel.current_model: %s" % ("✅" if model_preview_panel.current_model else "❌"))
	
	print("================================\n")





# AGREGAR ESTAS FUNCIONES FALTANTES en settings_panel.gd

# ========================================================================
# FUNCIÓN FALTANTE: _on_size_preset_pressed()
# ========================================================================
func _on_size_preset_pressed(size_value: float):
	"""Manejar preset de tamaño"""
	if capture_area_slider: 
		capture_area_slider.value = size_value
		#print("📐 Preset de tamaño aplicado: %.1f" % size_value)
	else:
		print("❌ capture_area_slider no existe para aplicar preset")

# ========================================================================
# FUNCIÓN MEJORADA: _on_capture_area_changed() con debug
# ========================================================================
func _on_capture_area_changed(value: float):
	"""Manejar cambio en area de captura (CON DEBUG)"""
	#print("📏 _on_capture_area_changed llamado con valor: %.1f" % value)
	
	current_settings.capture_area_size = value
	if capture_area_label: 
		capture_area_label.text = "%.1f" % value
		#print("  ✅ Label actualizado: %s" % capture_area_label.text)
	else:
		print("  ❌ capture_area_label no existe")
	
	# Convertir a configuración de cámara (para compatibilidad)
	current_settings.manual_zoom_override = true
	current_settings.fixed_orthographic_size = value
	
	#print("  ✅ Settings actualizados:")
	#print("    capture_area_size: %.1f" % current_settings.capture_area_size)
	#print("    manual_zoom_override: %s" % current_settings.manual_zoom_override)
	#
	settings_changed.emit(_get_enhanced_settings())
	_update_capture_area_visual()
	#print("  ✅ Señales emitidas")

# ========================================================================
# FUNCIÓN DE VERIFICACIÓN: validate_ui_elements()
# ========================================================================
func validate_ui_elements():
	"""Validar que todos los elementos de UI existen"""
	#print("\n🔍 === VALIDACIÓN ELEMENTOS UI ===")
	
	var validation = {
		"capture_area_slider": capture_area_slider != null,
		"capture_area_label": capture_area_label != null,
		"capture_resolution_buttons": capture_resolution_buttons != null and capture_resolution_buttons.size() > 0,
		"resolution_info_label": resolution_info_label != null
	}
	
	for element in validation:
		var status = "✅" if validation[element] else "❌"
		#print("%s %s: %s" % [status, element, validation[element]])
	
	var all_valid = true
	for value in validation.values():
		if not value:
			all_valid = false
			break
	
	#print("🎯 Estado general: %s" % ("✅ TODOS VÁLIDOS" if all_valid else "❌ FALTAN ELEMENTOS"))
	#print("===================================\n")
	
	return all_valid


func trigger_centering_wiggle():
	"""Función pública para ejecutar wiggle de centrado desde otros scripts"""
	#print("📡 Wiggle de centrado solicitado externamente...")
	_perform_centering_wiggle()


func debug_corrected_shader_system():
	"""Debug del sistema de shader corregido"""
	#print("\n🔍 === DEBUG SISTEMA CORREGIDO ===")
	#print("model_preview_panel: %s" % ("✅" if model_preview_panel else "❌"))
	#print("advanced_shader_panel: %s" % ("✅" if advanced_shader_panel else "❌"))
	#print("shader_currently_applied: %s" % shader_currently_applied)
	
	if advanced_shader_panel and advanced_shader_panel.has_signal("shader_settings_changed"):
		var connections = advanced_shader_panel.get_signal_connection_list("shader_settings_changed")
		#print("Conexiones: %d" % connections.size())
	
	#print("===================================\n")





# ========================================================================
# REEMPLAZAR ESTAS FUNCIONES EN settings_panel.gd
# ========================================================================

func _apply_basic_shader_to_preview():
	"""Aplicar canvas post-processing básico al preview"""
	if not model_preview_panel:
		_get_model_preview_panel_reference()
	
	if not model_preview_panel:
		print("❌ No hay ModelPreviewPanel para aplicar canvas post-processing")
		return
	
	# Configuración básica de canvas post-processing
	var basic_canvas_settings = {
		"pixelize_enabled": true,
		"pixel_size": 2.0,
		"reduce_colors": false,
		"color_levels": 16,
		"enable_dithering": false,
		"dither_strength": 0.1,
		"contrast_enabled": false,
		"contrast_boost": 1.0,
		"saturation_enabled": false,
		"saturation_mult": 1.0,
		"tint_enabled": false,
		"color_tint": Color.WHITE,
		"post_processing": true,
		"canvas_postprocess": true,
		"shader_path": "res://resources/shaders/pixelize_postprocess.gdshader"
	}
	
	# Si hay configuración avanzada, usarla en su lugar
	if not current_shader_settings.is_empty():
		basic_canvas_settings = current_shader_settings.duplicate()
		basic_canvas_settings["pixelize_enabled"] = true
		basic_canvas_settings["post_processing"] = true
		basic_canvas_settings["canvas_postprocess"] = true
	
	# Aplicar al preview usando canvas post-processing
	if model_preview_panel.has_method("apply_postprocessing"):
		model_preview_panel.apply_postprocessing(basic_canvas_settings)
		shader_currently_applied = true
		print("✅ Canvas post-processing básico aplicado al preview")
	elif model_preview_panel.has_method("apply_advanced_shader"):
		model_preview_panel.apply_advanced_shader(basic_canvas_settings)
		shader_currently_applied = true
		print("✅ Canvas post-processing aplicado via apply_advanced_shader")
	else:
		print("❌ ModelPreviewPanel no tiene métodos de canvas post-processing")

func _remove_shader_from_preview():
	"""QUITAR canvas post-processing del preview (reversible)"""
	if not model_preview_panel:
		_get_model_preview_panel_reference()
	
	if not model_preview_panel:
		print("❌ No hay ModelPreviewPanel para quitar canvas post-processing")
		return
	
	# Usar método de limpieza de canvas post-processing
	if model_preview_panel.has_method("clear_postprocessing"):
		model_preview_panel.clear_postprocessing()
		shader_currently_applied = false
		#print("✅ Canvas post-processing removido del preview")
	elif model_preview_panel.has_method("clear_advanced_shader"):
		model_preview_panel.clear_advanced_shader()
		shader_currently_applied = false
		print("✅ Shader removido via clear_advanced_shader")
	else:
		print("❌ ModelPreviewPanel no tiene métodos de limpieza")

func _on_advanced_shader_settings_changed(settings: Dictionary):
	"""Manejar cambios en configuración avanzada de canvas post-processing"""
	current_shader_settings = settings.duplicate()
	
	# Asegurar que sea canvas post-processing
	current_shader_settings["post_processing"] = true
	current_shader_settings["canvas_postprocess"] = true
	
	# Actualizar checkbox básico si existe
	if pixelize_check and settings.has("pixelize_enabled"):
		pixelize_check.button_pressed = settings.pixelize_enabled
		current_settings.pixelize = settings.pixelize_enabled
	
	# Emitir señal con configuración actualizada
	settings_changed.emit(_get_enhanced_settings())
	
	# Aplicar inmediatamente al modelo actual si existe
	_apply_canvas_postprocessing_to_current_model()

# ========================================================================
# AÑADIR ESTA NUEVA FUNCIÓN
# ========================================================================

func _apply_canvas_postprocessing_to_current_model():
	"""Aplicar canvas post-processing al modelo actual"""
	if not model_preview_panel:
		return
	
	if not current_shader_settings.is_empty():
		# Asegurar flags de canvas
		current_shader_settings["canvas_postprocess"] = true
		current_shader_settings["post_processing"] = true
		
		if model_preview_panel.has_method("apply_postprocessing"):
			model_preview_panel.apply_postprocessing(current_shader_settings)
		elif model_preview_panel.has_method("apply_advanced_shader"):
			model_preview_panel.apply_advanced_shader(current_shader_settings)
		print("🔄 Canvas post-processing re-aplicado al modelo actual")

# ========================================================================
# MODIFICAR ESTAS FUNCIONES EXISTENTES
# ========================================================================

func _on_pixelize_changed(enabled: bool):
	"""Manejar cambio en checkbox de pixelización - MODIFICADO PARA CANVAS"""
	current_settings.pixelize = enabled
	
	if enabled:
		#print("🎨 Aplicando canvas post-processing básico...")
		_apply_basic_shader_to_preview()
	else:
		#print("🧹 Removiendo canvas post-processing...")
		_remove_shader_from_preview()
	
	# Emitir señal de cambio
	settings_changed.emit(_get_enhanced_settings())

func _get_enhanced_settings() -> Dictionary:
	"""Obtener configuración mejorada con canvas post-processing - MODIFICADO"""
	var settings = current_settings.duplicate()
	
	# NUEVA FUNCIONALIDAD: Configuración básica de pixelización canvas
	if pixelize_check:
		settings["pixelize"] = pixelize_check.button_pressed
	else:
		settings["pixelize"] = true  # Default
	
	# NUEVA FUNCIONALIDAD: Configuración avanzada de canvas shader
	if not current_shader_settings.is_empty():
		# Incluir toda la configuración avanzada con flags de canvas
		settings["advanced_shader"] = current_shader_settings.duplicate()
		settings["use_advanced_shader"] = true
		settings["canvas_postprocess"] = true
		
		# Sobrescribir pixelización básica con la avanzada
		settings["pixelize"] = current_shader_settings.get("pixelize_enabled", true)
	else:
		settings["use_advanced_shader"] = false
		settings["advanced_shader"] = {}
		settings["canvas_postprocess"] = false
	
	return settings

# ========================================================================
# FUNCIONES DE DEBUG (NUEVAS)
# ========================================================================

func debug_canvas_shader_system():
	"""Debug del sistema de canvas shader"""
	#print("\n🔍 === DEBUG SISTEMA DE CANVAS SHADER ===")
	#print("advanced_shader_panel: %s" % ("✅" if advanced_shader_panel else "❌"))
	#print("model_preview_panel: %s" % ("✅" if model_preview_panel else "❌"))
	#print("current_shader_settings: %d elementos" % current_shader_settings.size())
	#print("canvas_postprocess flag: %s" % current_shader_settings.get("canvas_postprocess", false))
	#
	if model_preview_panel:
		#print("model_preview_panel.current_model: %s" % ("✅" if model_preview_panel.current_model else "❌"))
		if model_preview_panel.has_method("get_postprocess_status"):
			var _status = model_preview_panel.get_postprocess_status()
			#print("postprocess_status: %s" % status)
	
	#print("=====================================\n")
