# pixelize3d_fbx/scripts/transition/Columna4_UI.gd
# Interfaz de usuario para preview final de transiciones - Columna 4
# Input: Controles del usuario para preview y exportación  
# Output: Señales de control y visualización de transición generada

extends VBoxContainer
class_name Columna4UI

# === SEÑALES HACIA LÓGICA ===
signal generate_preview_requested()
signal play_requested()
signal pause_requested()
signal seek_requested(frame_index: int)
signal speed_changed(speed: float)
signal export_spritesheet_requested(config: Dictionary)

# === REFERENCIAS DE UI ===
# Viewport físico (EXCLUSIVO para Columna 4)
var viewport_container: SubViewportContainer
var viewport_3d: SubViewport
var camera_3d: Camera3D
var model_preview: Node3D
var light_3d: DirectionalLight3D

# Controles de UI (CREADOS dinámicamente)
var generate_button: Button
var status_label: Label
var progress_bar: ProgressBar

# Controles de reproducción
var playback_controls: HBoxContainer
var play_button: Button
var pause_button: Button
var stop_button: Button
var frame_slider: HSlider
var frame_info_label: Label

# Controles de velocidad
var speed_slider: HSlider
var speed_value_label: Label

# Exportación
var export_button: Button
var export_dialog: FileDialog
var export_progress: ProgressBar

# === ESTADO INTERNO ===
var is_preview_ready: bool = false
var is_playing: bool = false
var current_frame: int = 0
var total_frames: int = 0
var preview_data: Dictionary = {}

func _ready():
	print("🎯 Columna4UI inicializando...")
	_setup_physical_viewport()
	_create_transition_ui()
	_connect_internal_signals()
	_setup_initial_state()
	print("✅ Columna4UI lista - Preview de transición exclusivo ")
	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

# ========================================================================
# CONFIGURACIÓN DE VIEWPORT FÍSICO EXCLUSIVO
# ========================================================================

func _setup_physical_viewport():
	"""Configurar viewport físico EXCLUSIVO para preview de transición"""
	print("🖥️ Configurando viewport físico exclusivo para Columna 4...")
	
	# Buscar viewport físico en estructura existente
	var panel_container = get_parent().get_node("Columna4_UI/PanelContainer_PRE")
	if panel_container:
		var layout_container = panel_container.get_node_or_null("LayoutContainer_A")
		if layout_container:
			viewport_container = layout_container.get_node_or_null("SubViewportContainer_PRE")
			if viewport_container:
				viewport_3d = viewport_container.get_node_or_null("SubViewport_PRE")
				print("✅ Viewport físico encontrado: %s" % viewport_3d.get_path())
				
				# LIMPIAR viewport para uso exclusivo de Columna 4
				_clear_and_setup_exclusive_viewport()
				
			else:
				print("❌ SubViewportContainer_PRE no encontrado")
				return
		else:
			print("❌ LayoutContainer_A no encontrado")
			return
	else:
		print("❌ PanelContainer_PRE no encontrado")
		return

func _clear_and_setup_exclusive_viewport():
	"""Limpiar y configurar viewport exclusivamente para Columna 4"""
	print("🧹 Limpiando viewport para uso exclusivo de transición...")
	
	# Configurar viewport con tamaño correcto
	viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_3d.size = Vector2(128, 128)
	
	# Obtener o crear cámara exclusiva
	camera_3d = viewport_3d.get_node_or_null("Camera3D_PRE")
	if camera_3d:
		print("✅ Camera3D_PRE reutilizada")
		# Configurar para preview de transición
#		camera_3d.projection = PROJECTION_ORTHOGONAL
		camera_3d.position = Vector3(0, 2, 5)
		camera_3d.look_at(Vector3.ZERO, Vector3.UP)
		camera_3d.size = 2.5
	else:
		print("⚠️ Camera3D_PRE no encontrada, creando nueva")
		_create_transition_camera()
	
	# Obtener o crear luz exclusiva
	light_3d = viewport_3d.get_node_or_null("DirectionalLight3D_PRE")
	if light_3d:
		print("✅ DirectionalLight3D_PRE reutilizada")
	else:
		print("⚠️ DirectionalLight3D_PRE no encontrada, creando nueva")
		_create_transition_light()
	
	# CREAR contenedor EXCLUSIVO para modelo de transición
	model_preview = viewport_3d.get_node_or_null("Model_PRE")
	if model_preview:
		print("♻️ Limpiando Model_PRE para uso de transición")
		# Limpiar contenido existente
		for child in model_preview.get_children():
			child.queue_free()
	else:
		print("🆕 Creando Model_PRE exclusivo para transición")
		model_preview = Node3D.new()
		model_preview.name = "Model_PRE"
		viewport_3d.add_child(model_preview)
	
	# Aplicar estilo visual al viewport
	_apply_transition_viewport_style()
	
	print("✅ Viewport exclusivo configurado para preview de transición")

func _create_transition_camera():
	"""Crear cámara específica para transición"""
	camera_3d = Camera3D.new()
	camera_3d.name = "Camera3D_PRE"
	#camera_3d.projection = PROJECTION_ORTHOGONAL
	camera_3d.position = Vector3(0, 2, 5)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)
	camera_3d.size = 2.5
	viewport_3d.add_child(camera_3d)

func _create_transition_light():
	"""Crear luz específica para transición"""
	light_3d = DirectionalLight3D.new()
	light_3d.name = "DirectionalLight3D_PRE"
	light_3d.position = Vector3(2, 4, 3)
	light_3d.look_at(Vector3.ZERO, Vector3.UP)
	light_3d.light_energy = 1.0
	viewport_3d.add_child(light_3d)

func _apply_transition_viewport_style():
	"""Aplicar estilo específico para viewport de transición"""
	if viewport_container:
		var style_box = StyleBoxFlat.new()
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = Color(1, 0.8, 0.2)  # Dorado brillante
		style_box.bg_color = Color(0.1, 0.1, 0.1, 0.5)
		
		viewport_container.add_theme_stylebox_override("panel", style_box)
		viewport_container.custom_minimum_size = Vector2(128, 128)

# ========================================================================
# CREACIÓN DE UI ESPECÍFICA PARA TRANSICIÓN
# ========================================================================

func _create_transition_ui():
	"""Crear interfaz específica para preview de transición"""
	print("🎨 Creando UI específica de transición...")
	
	# Título específico
	_create_transition_title()
	add_child(HSeparator.new())
	
	# Controles de generación
	_create_generation_controls()
	add_child(HSeparator.new())
	
	# Controles de reproducción
	_create_playback_controls()
	add_child(HSeparator.new())
	
	# Controles de velocidad
	_create_speed_controls()
	add_child(HSeparator.new())
	
	# Controles de exportación
	_create_export_controls()
	
	print("✅ UI de transición creada maaaaauauauuauaua" )

func _create_transition_title():
	"""Crear título específico para preview de transición"""
	
	
	var  title_container = VBoxContainer.new()
	add_child(title_container)


	 
	var title = Label.new()
	title.text = " PREVIEW DE TRANSICIÓN AAAAAAAAAAAAAAAA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Animación interpolada A → B"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 8)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_container.add_child(subtitle)
	

func _create_generation_controls():
	"""Crear controles específicos de generación de transición"""
	var gen_container = VBoxContainer.new()
	
	# Botón principal
	generate_button = Button.new()
	generate_button.text = "🎬 Generar Transición MAU"
	generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	generate_button.disabled = true
	gen_container.add_child(generate_button)
	
	# Estado
	status_label = Label.new()
	status_label.text = "⏳ Esperando configuración desde Columna 3..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 8)
	gen_container.add_child(status_label)
	
	# Progreso
	progress_bar = ProgressBar.new()
	progress_bar.value = 0
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size.y = 8
	gen_container.add_child(progress_bar)
	
	add_child(gen_container)

func _create_playback_controls():
	"""Crear controles de reproducción de transición"""
	var playback_container = VBoxContainer.new()
	
	# Label
	var label = Label.new()
	label.text = "Reproducción de Transición:"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	playback_container.add_child(label)
	
	# Botones
	playback_controls = HBoxContainer.new()
	
	play_button = Button.new()
	play_button.text = "▶️"
	play_button.custom_minimum_size = Vector2(30, 25)
	play_button.disabled = true
	playback_controls.add_child(play_button)
	
	pause_button = Button.new()
	pause_button.text = "⏸️"
	pause_button.custom_minimum_size = Vector2(30, 25)
	pause_button.disabled = true
	playback_controls.add_child(pause_button)
	
	stop_button = Button.new()
	stop_button.text = "⏹️"
	stop_button.custom_minimum_size = Vector2(30, 25)
	stop_button.disabled = true
	playback_controls.add_child(stop_button)
	
	playback_container.add_child(playback_controls)
	
	# Slider de frames
	frame_slider = HSlider.new()
	frame_slider.min_value = 0
	frame_slider.max_value = 100
	frame_slider.step = 1
#	frame_slider.disabled = true
	playback_container.add_child(frame_slider)
	
	# Info de frame
	frame_info_label = Label.new()
	frame_info_label.text = "Frame: 0/0  Tiempo: 0.00s"
	frame_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame_info_label.add_theme_font_size_override("font_size", 8)
	playback_container.add_child(frame_info_label)
	
	add_child(playback_container)

func _create_speed_controls():
	"""Crear controles de velocidad de reproducción"""
	var speed_container = VBoxContainer.new()
	
	# Label
	var label = Label.new()
	label.text = "Velocidad:"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	speed_container.add_child(label)
	
	# Container horizontal
	var speed_h_container = HBoxContainer.new()
	
	speed_slider = HSlider.new()
	speed_slider.min_value = 0.1
	speed_slider.max_value = 3.0
	speed_slider.value = 1.0
	speed_slider.step = 0.1
	speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
#	speed_slider.disabled = true
	speed_h_container.add_child(speed_slider)
	
	speed_value_label = Label.new()
	speed_value_label.text = "1.0x"
	speed_value_label.custom_minimum_size.x = 40
	speed_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_h_container.add_child(speed_value_label)
	
	speed_container.add_child(speed_h_container)
	add_child(speed_container)

func _create_export_controls():
	"""Crear controles de exportación de spritesheet"""
	var export_container = VBoxContainer.new()
	
	# Label
	var label = Label.new()
	label.text = "Exportar Spritesheet:"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	export_container.add_child(label)
	
	# Botón exportar
	export_button = Button.new()
	export_button.text = "📁 Exportar Spritesheet"
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.disabled = true
	export_container.add_child(export_button)
	
	# Progreso de exportación
	export_progress = ProgressBar.new()
	export_progress.value = 0
	export_progress.visible = false
	export_progress.custom_minimum_size.y = 8
	export_container.add_child(export_progress)
	
	add_child(export_container)

func _connect_internal_signals():
	"""Conectar señales de controles creados"""
	if generate_button:
		generate_button.pressed.connect(_on_generate_pressed)
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	
	if frame_slider:
		frame_slider.value_changed.connect(_on_frame_slider_changed)
	
	if speed_slider:
		speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	if export_button:
		export_button.pressed.connect(_on_export_pressed)

func _setup_initial_state():
	"""Configurar estado inicial"""
	_update_ui_state(false, false, 0, 0)

# ========================================================================
# MANEJADORES DE EVENTOS DE UI
# ========================================================================

func _on_generate_pressed():
	"""Generar preview de transición"""
	print("🎬 Generando preview de transición...")
	if generate_button:
		generate_button.disabled = true
		generate_button.text = "⏳ Generando transición..."
	
	emit_signal("generate_preview_requested")

func _on_play_pressed():
	"""Reproducir transición"""
	print("▶️ Reproduciendo transición")
	emit_signal("play_requested")

func _on_pause_pressed():
	"""Pausar transición"""
	print("⏸️ Pausando transición")
	emit_signal("pause_requested")

func _on_stop_pressed():
	"""Detener transición"""
	print("⏹️ Deteniendo transición")
	emit_signal("seek_requested", 0)
	emit_signal("pause_requested")

func _on_frame_slider_changed(value: float):
	"""Cambiar frame de transición"""
	var frame_index = int(value)
	current_frame = frame_index
	_update_frame_info()
	emit_signal("seek_requested", frame_index)

func _on_speed_slider_changed(value: float):
	"""Cambiar velocidad de reproducción"""
	if speed_value_label:
		speed_value_label.text = "%.1fx" % value
	emit_signal("speed_changed", value)

func _on_export_pressed():
	"""Exportar spritesheet de transición"""
	print("📁 Exportando spritesheet de transición...")
	
	if not export_dialog:
		_setup_export_dialog()
	
	export_dialog.popup_centered(Vector2i(600, 400))

func _setup_export_dialog():
	"""Configurar diálogo de exportación"""
	export_dialog = FileDialog.new()
	export_dialog.title = "Exportar Spritesheet de Transición"
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.current_dir = "res://output/"
	export_dialog.current_file = "transition_spritesheet.png"
	add_child(export_dialog)
	
	export_dialog.file_selected.connect(_on_export_file_selected)

func _on_export_file_selected(path: String):
	"""Archivo de exportación seleccionado"""
	print("📁 Exportando a: %s" % path)
	
	var export_config = {
		"sprite_size": 128,
		"output_path": path,
		"background_transparent": true,
		"generate_metadata": true
	}
	
	emit_signal("export_spritesheet_requested", export_config)
	
	if export_progress:
		export_progress.visible = true
	if export_button:
		export_button.disabled = true
		export_button.text = "📁 Exportando..."

# ========================================================================
# MANEJADORES DESDE LÓGICA
# ========================================================================

func on_playback_state_changed(state: Dictionary):
	"""Estado de reproducción cambió"""
	is_playing = state.get("is_playing", false)
	is_preview_ready = state.get("state", "") == "READY"
	total_frames = state.get("total_frames", 0)
	current_frame = state.get("current_frame", 0)
	
	_update_playback_controls()
	_update_frame_info()

func on_frame_updated(frame_index: int, total: int):
	"""Frame actualizado"""
	current_frame = frame_index
	total_frames = total
	
	if frame_slider:
		frame_slider.set_value_no_signal(frame_index)
	
	_update_frame_info()

func on_generation_progress_updated(progress: float, status: String):
	"""Progreso de generación actualizado"""
	if progress_bar:
		progress_bar.value = progress * 100
	
	if status_label:
		status_label.text = status

func on_generation_complete():
	"""Generación completada"""
	is_preview_ready = true
	
	if generate_button:
		generate_button.disabled = false
		generate_button.text = "✅ Transición Generada"
		generate_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	if status_label:
		status_label.text = "✅ Transición lista para reproducir"
		status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	_update_playback_controls()
	_update_export_controls()

func on_generation_failed(error: String):
	"""Generación falló"""
	if generate_button:
		generate_button.disabled = false
		generate_button.text = "❌ Error - Reintentar"
		generate_button.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	
	if status_label:
		status_label.text = "❌ Error: " + error
		status_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

func on_export_complete(success: bool, result_path: String = ""):
	"""Exportación completada"""
	if export_progress:
		export_progress.visible = false
	
	if export_button:
		export_button.disabled = false
		
		if success:
			export_button.text = "✅ Spritesheet Exportado"
			export_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			export_button.text = "❌ Error - Reintentar"
			export_button.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

# ========================================================================
# UTILIDADES DE UI
# ========================================================================

func _update_playback_controls():
	"""Actualizar controles de reproducción"""
	var play_enabled = is_preview_ready and not is_playing
	var pause_enabled = is_preview_ready and is_playing
	
	if play_button:
		play_button.disabled = not play_enabled
	
	if pause_button:
		pause_button.disabled = not pause_enabled
	
	if stop_button:
		stop_button.disabled = not is_preview_ready
	
	#if frame_slider:
		#frame_slider.disabled = not is_preview_ready
		#frame_slider.max_value = max(total_frames - 1, 0)
	#
	#if speed_slider:
		#speed_slider.disabled = not is_preview_ready

func _update_export_controls():
	"""Actualizar controles de exportación"""
	var export_enabled = is_preview_ready and not is_playing
	
	if export_button:
		export_button.disabled = not export_enabled

func _update_frame_info():
	"""Actualizar información de frame"""
	if frame_info_label and total_frames > 0:
		var duration = preview_data.get("duration", 1.0)
		var current_time = (float(current_frame) / float(total_frames - 1)) * duration if total_frames > 1 else 0.0
		
		frame_info_label.text = "Frame: %d/%d  Tiempo: %.2fs" % [current_frame, total_frames, current_time]

func _update_ui_state(ready: bool, playing: bool, frame: int, total: int):
	"""Actualizar estado general"""
	is_preview_ready = ready
	is_playing = playing
	current_frame = frame
	total_frames = total
	
	_update_playback_controls()
	_update_export_controls()
	_update_frame_info()

# ========================================================================
# API PÚBLICA
# ========================================================================

func enable_generation():
	"""Habilitar generación cuando hay datos válidos"""
	if generate_button:
		generate_button.disabled = false
		generate_button.text = "🎬 Generar Transición guau"
		generate_button.remove_theme_color_override("font_color")
	
	if status_label:
		status_label.text = "⚡ Listo para generar transición A → B"
		status_label.add_theme_color_override("font_color", Color(1, 1, 0.2))

func load_preview_data(data: Dictionary):
	"""Cargar datos de preview generado"""
	preview_data = data.duplicate()
	total_frames = data.get("total_frames", 0)
	
	if data.has("camera_settings"):
		_apply_camera_settings(data.camera_settings)

func _apply_camera_settings(settings: Dictionary):
	"""Aplicar configuración de cámara"""
	if not camera_3d:
		return
	
	print("📷 Aplicando configuración de cámara a transición:")
	print("  Orthographic size: %.1f" % settings.get("orthographic_size", 2.5))
	print("  Camera distance: %.1f" % settings.get("camera_distance", 5.0))
	
	if settings.has("orthographic_size"):
		camera_3d.size = settings.orthographic_size
	
	if settings.has("camera_distance"):
		camera_3d.position.z = settings.camera_distance
	
	if model_preview and settings.has("north_offset"):
		model_preview.rotation_degrees.y = settings.north_offset

func load_transition_model(model_node: Node3D):
	"""Cargar modelo específico para transición"""
	if not model_preview:
		print("❌ Model_PRE no disponible")
		return
	
	# Limpiar contenido anterior
	for child in model_preview.get_children():
		child.queue_free()
	
	# Agregar nuevo modelo de transición
	model_preview.add_child(model_node)
	print("✅ Modelo de transición cargado")

# ========================================================================
# DEBUG
# ========================================================================

func debug_ui_state():
	"""Debug de estado"""
	print("=== DEBUG COLUMNA4 UI - TRANSICIÓN ===")
	print("Preview listo: %s" % is_preview_ready)
	print("Reproduciendo: %s" % is_playing)
	print("Frame actual: %d/%d" % [current_frame, total_frames])
	print("Viewport exclusivo: %s" % ("✅ OK" if viewport_3d else "❌ NULL"))
	print("Modelo de transición: %s" % ("✅ OK" if model_preview else "❌ NULL"))
	print("Controles creados: %s" % ("✅ OK" if generate_button else "❌ NULL"))
	print("====================================")

func get_viewport_3d() -> SubViewport:
	"""Obtener viewport exclusivo"""
	return viewport_3d

func get_model_preview_container() -> Node3D:
	"""Obtener contenedor del modelo de transición"""
	return model_preview
