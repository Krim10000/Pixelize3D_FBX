# scripts/ui/ui_controller.gd
# Input: Interacciones del usuario y textura del SpriteRenderer
# Output: Señales y configuración para el proceso de renderizado, controles de preview

extends Control

# Input: Interacciones del usuario
# Output: Señales y configuración para el proceso de renderizado

signal folder_selected(path: String)
signal base_fbx_selected(filename: String)
signal animations_selected(filenames: Array)
signal render_settings_changed(settings: Dictionary)
signal render_requested()

# SEÑALES para control de preview
signal preview_play_requested()
signal preview_pause_requested()
signal preview_stop_requested()

# Referencias a controles UI (sin @onready ya que se crean dinámicamente)
var main_panel: PanelContainer
var progress_dialog: AcceptDialog

var project_folders_list: ItemList  # CAMBIADO: Lista de carpetas de proyecto
var base_fbx_option: OptionButton
var directions_spinbox: SpinBox
var sprite_size_spinbox: SpinBox
var camera_angle_slider: HSlider
var camera_height_slider: HSlider
var camera_distance_slider: HSlider
var fps_spinbox: SpinBox
var pixelize_checkbox: CheckBox
var preview_button: Button
var render_button: Button
var export_log: RichTextLabel

# NUEVAS REFERENCIAS para log mejorado
var log_copy_button: Button
var log_clear_button: Button

# REFERENCIAS ACTUALIZADAS para controles de preview
var viewport_container: SubViewportContainer
var play_button: Button
var pause_button: Button
var stop_button: Button
var preview_status_label: Label

var current_folder_path: String = ""
var available_fbx_files: Array = []
var selected_animations: Array = []
var preview_mode_active: bool = false

# NUEVOS: Para manejo de carpetas de proyecto
var project_folders: Array = []
var current_project_folder: String = ""

func _ready():
	_create_ui()
	_connect_ui_signals()
	_apply_theme()

func _create_ui():
	# Panel principal
	main_panel = PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_panel.add_child(main_vbox)
	
	# Título
	var title = Label.new()
	title.text = "Pixelize3D FBX - Sprite Generator"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	main_vbox.add_child(HSeparator.new())
	
	# Contenedor principal con split
	var hsplit = HSplitContainer.new()
	hsplit.name = "HSplitContainer"
	hsplit.split_offset = 600
	main_vbox.add_child(hsplit)
	
	# Panel izquierdo - Configuración
	var left_panel = _create_config_panel()
	hsplit.add_child(left_panel)
	
	# Panel derecho - Preview
	var right_panel = _create_preview_panel()
	hsplit.add_child(right_panel)
	
	# Panel inferior - Log
	var log_panel = _create_log_panel()
	main_vbox.add_child(log_panel)
	
	# Diálogos (crear después del panel principal)
	_create_dialogs()

func _create_config_panel() -> Control:
	var panel = ScrollContainer.new()
	panel.name = "ConfigPanel"
	panel.custom_minimum_size = Vector2(400, 0)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Sección: Selección de carpeta de proyecto
	var folder_section = _create_section("Carpetas de Proyecto")
	vbox.add_child(folder_section)
	
	var folder_info = Label.new()
	folder_info.text = "Carpetas encontradas en res://assets/fbx/"
	folder_info.add_theme_font_size_override("font_size", 12)
	folder_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	folder_section.add_child(folder_info)
	
	project_folders_list = ItemList.new()
	project_folders_list.name = "ProjectFoldersList"
	project_folders_list.custom_minimum_size.y = 120
	project_folders_list.select_mode = ItemList.SELECT_SINGLE
	project_folders_list.item_selected.connect(_on_project_folder_selected)
	folder_section.add_child(project_folders_list)
	
	# Sección: Selección de FBX base
	var base_section = _create_section("Modelo Base")
	vbox.add_child(base_section)
	
	base_fbx_option = OptionButton.new()
	base_fbx_option.add_item("-- Seleccionar carpeta primero --")
	base_fbx_option.disabled = true
	base_section.add_child(base_fbx_option)
	
	# Sección: Selección de animaciones CON CHECKBOXES
	var anim_section = _create_section("Animaciones")
	vbox.add_child(anim_section)
	
	var anim_info = Label.new()
	anim_info.text = "Marca las animaciones que deseas usar:"
	anim_info.add_theme_font_size_override("font_size", 12)
	anim_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	anim_section.add_child(anim_info)
	
	# Contenedor scroll para animaciones con checkboxes
	var anim_scroll = ScrollContainer.new()
	anim_scroll.custom_minimum_size.y = 150
	anim_section.add_child(anim_scroll)
	
	var anim_vbox = VBoxContainer.new()
	anim_vbox.name = "AnimationsCheckboxContainer"
	anim_scroll.add_child(anim_vbox)
	
	# Nota: Los checkboxes se crearán dinámicamente en display_fbx_list()
	
	# Sección: Configuración de renderizado
	var render_section = _create_section("Configuración de Renderizado")
	vbox.add_child(render_section)
	
	# Direcciones
	var dir_hbox = HBoxContainer.new()
	render_section.add_child(dir_hbox)
	
	var dir_label = Label.new()
	dir_label.text = "Direcciones:"
	dir_hbox.add_child(dir_label)
	
	directions_spinbox = SpinBox.new()
	directions_spinbox.min_value = 4
	directions_spinbox.max_value = 32
	directions_spinbox.step = 4
	directions_spinbox.value = 16
	dir_hbox.add_child(directions_spinbox)
	
	# Tamaño de sprite
	var size_hbox = HBoxContainer.new()
	render_section.add_child(size_hbox)
	
	var size_label = Label.new()
	size_label.text = "Tamaño sprite:"
	size_hbox.add_child(size_label)
	
	sprite_size_spinbox = SpinBox.new()
	sprite_size_spinbox.min_value = 32
	sprite_size_spinbox.max_value = 1024
	sprite_size_spinbox.step = 32
	sprite_size_spinbox.value = 256
	size_hbox.add_child(sprite_size_spinbox)
	
	# FPS
	var fps_hbox = HBoxContainer.new()
	render_section.add_child(fps_hbox)
	
	var fps_label = Label.new()
	fps_label.text = "FPS:"
	fps_hbox.add_child(fps_label)
	
	fps_spinbox = SpinBox.new()
	fps_spinbox.min_value = 1
	fps_spinbox.max_value = 60
	fps_spinbox.value = 12
	fps_hbox.add_child(fps_spinbox)
	
	# Sección: Configuración de cámara
	var camera_section = _create_section("Cámara")
	vbox.add_child(camera_section)
	
	# Ángulo
	var angle_label = Label.new()
	angle_label.text = "Ángulo:"
	camera_section.add_child(angle_label)
	camera_angle_slider = _create_slider(15, 75, 45)
	camera_section.add_child(camera_angle_slider)
	
	# Altura
	var height_label = Label.new()
	height_label.text = "Altura:"
	camera_section.add_child(height_label)
	camera_height_slider = _create_slider(1, 50, 10)
	camera_section.add_child(camera_height_slider)
	
	# Distancia
	var distance_label = Label.new()
	distance_label.text = "Distancia:"
	camera_section.add_child(distance_label)
	camera_distance_slider = _create_slider(5, 100, 15)
	camera_section.add_child(camera_distance_slider)
	
	# Opciones adicionales
	pixelize_checkbox = CheckBox.new()
	pixelize_checkbox.text = "Aplicar pixelización"
	pixelize_checkbox.button_pressed = true
	camera_section.add_child(pixelize_checkbox)
	
	# Botones de acción
	var button_hbox = HBoxContainer.new()
	vbox.add_child(button_hbox)
	
	preview_button = Button.new()
	preview_button.text = "Preview"
	preview_button.disabled = true
	button_hbox.add_child(preview_button)
	
	render_button = Button.new()
	render_button.text = "Renderizar"
	render_button.disabled = true
	button_hbox.add_child(render_button)
	
	return panel

func _create_preview_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "PreviewPanel"
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Vista Previa"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Status del preview
	preview_status_label = Label.new()
	preview_status_label.name = "PreviewStatus"
	preview_status_label.text = "Carga un modelo para ver preview"
	preview_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	preview_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(preview_status_label)
	
	# OPCIÓN B: Usar SubViewportContainer para animación en tiempo real
	var preview_viewport_container = SubViewportContainer.new()
	preview_viewport_container.name = "ViewportContainer"
	preview_viewport_container.stretch = true
	preview_viewport_container.custom_minimum_size = Vector2(400, 400)
	vbox.add_child(preview_viewport_container)
	
	# Mensaje cuando no hay preview (se muestra/oculta según estado)
	var no_preview_label = Label.new()
	no_preview_label.name = "NoPreviewLabel"
	no_preview_label.text = "No hay preview disponible"
	no_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	no_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_preview_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	no_preview_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_viewport_container.add_child(no_preview_label)
	
	# NUEVO: Controles de preview (Play/Pause/Stop)
	var controls_hbox = HBoxContainer.new()
	controls_hbox.name = "PreviewControls"
	controls_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(controls_hbox)
	
	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "▶️ Play"
	play_button.disabled = true
	play_button.pressed.connect(_on_play_pressed)
	controls_hbox.add_child(play_button)
	
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "⏸️ Pause"
	pause_button.disabled = true
	pause_button.pressed.connect(_on_pause_pressed)
	controls_hbox.add_child(pause_button)
	
	stop_button = Button.new()
	stop_button.name = "StopButton"
	stop_button.text = "⏹️ Stop"
	stop_button.disabled = true
	stop_button.pressed.connect(_on_stop_pressed)
	controls_hbox.add_child(stop_button)
	
	# Instrucciones de controles
	var controls_label = Label.new()
	controls_label.name = "ControlsHelp"
	controls_label.text = "Controles: Click + Arrastrar = Rotar | Rueda = Zoom"
	controls_label.add_theme_font_size_override("font_size", 10)
	controls_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.visible = false
	vbox.add_child(controls_label)
	
	return panel

func _create_log_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "LogPanel"
	panel.custom_minimum_size.y = 150
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Header con título y botones
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var label = Label.new()
	label.text = "Log de Eventos"
	header_hbox.add_child(label)
	
	# Spacer para empujar botones a la derecha
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	# Botones del log
	log_copy_button = Button.new()
	log_copy_button.text = "📋 Copiar Todo"
	log_copy_button.custom_minimum_size.x = 100
	log_copy_button.pressed.connect(_on_log_copy_pressed)
	header_hbox.add_child(log_copy_button)
	
	log_clear_button = Button.new()
	log_clear_button.text = "🗑️ Limpiar"
	log_clear_button.custom_minimum_size.x = 80
	log_clear_button.pressed.connect(_on_log_clear_pressed)
	header_hbox.add_child(log_clear_button)
	
	# ScrollContainer para el log con scroll mejorado
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size.y = 100
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(log_scroll)
	
	export_log = RichTextLabel.new()
	export_log.custom_minimum_size.y = 100
	export_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	export_log.scroll_following = true
	export_log.bbcode_enabled = true
	export_log.fit_content = true
	export_log.selection_enabled = true  # Permitir selección de texto
	log_scroll.add_child(export_log)
	
	return panel

func _create_section(title: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	section.add_child(label)
	
	section.add_child(HSeparator.new())
	
	return section

func _create_slider(min_val: float, max_val: float, default: float) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default
	slider.step = 0.1
	return slider

func _create_dialogs():
	# Diálogo de progreso
	progress_dialog = AcceptDialog.new()
	progress_dialog.name = "ProgressDialog"
	progress_dialog.title = "Renderizando..."
	progress_dialog.dialog_hide_on_ok = false
	progress_dialog.get_ok_button().visible = false
	
	var progress_content = VBoxContainer.new()
	progress_content.custom_minimum_size = Vector2(300, 80)
	
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "Preparando renderizado..."
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_content.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.show_percentage = true
	progress_content.add_child(progress_bar)
	
	progress_dialog.add_child(progress_content)
	add_child(progress_dialog)

func _connect_ui_signals():
	# Conectar señales de UI
	if base_fbx_option:
		base_fbx_option.item_selected.connect(_on_base_fbx_selected)
	
	# NOTA: Los checkboxes de animaciones se conectan dinámicamente en _create_animation_checkboxes()
	
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
	
	if render_button:
		render_button.pressed.connect(_on_render_pressed)
	
	# Conectar sliders
	for slider in [camera_angle_slider, camera_height_slider, camera_distance_slider]:
		if slider:
			slider.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar spinboxes
	for spinbox in [directions_spinbox, sprite_size_spinbox, fps_spinbox]:
		if spinbox:
			spinbox.value_changed.connect(_on_camera_setting_changed)
	
	# Conectar checkbox
	if pixelize_checkbox:
		pixelize_checkbox.toggled.connect(_on_camera_setting_changed)

func _apply_theme():
	# Aplicar tema personalizado si es necesario
	pass

func initialize():
	add_export_log("Pixelize3D FBX iniciado")
	add_export_log("Escaneando carpetas de proyecto...")
	_scan_project_folders()
	# ELIMINADO: Verificación inicial del SpriteRenderer que causaba errores innecesarios

# NUEVA FUNCIÓN: Escanear carpetas en res://assets/fbx/
func _scan_project_folders():
	"""Escanear recursivamente las carpetas en res://assets/fbx/ que contengan archivos FBX"""
	print("🔍 ESCANEANDO CARPETAS DE PROYECTO")
	
	project_folders.clear()
	
	var base_path = "res://assets/fbx/"
	var dir = DirAccess.open(base_path)
	
	if dir == null:
		add_export_log("[color=red]❌ Error: No se pudo acceder a res://assets/fbx/[/color]")
		return
	
	_scan_directory_recursive(dir, base_path, "")
	
	# Llenar la lista de carpetas
	if project_folders_list:
		project_folders_list.clear()
		
		if project_folders.is_empty():
			project_folders_list.add_item("No se encontraron carpetas con archivos FBX")
			project_folders_list.set_item_disabled(0, true)
			add_export_log("[color=yellow]⚠️ No se encontraron carpetas con archivos FBX[/color]")
		else:
			for folder_info in project_folders:
				var display_name = "%s (%d archivos FBX)" % [folder_info.name, folder_info.fbx_count]
				project_folders_list.add_item(display_name)
			
			add_export_log("📁 Encontradas %d carpetas con archivos FBX" % project_folders.size())
			add_export_log("✨ Selecciona una carpeta para comenzar")

func _scan_directory_recursive(dir: DirAccess, base_path: String, relative_path: String):
	"""Escanear directorio recursivamente buscando archivos FBX"""
	var current_path = base_path + relative_path
	var fbx_files = []
	
	# Escanear archivos en el directorio actual
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".fbx"):
				fbx_files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Si encontramos archivos FBX, agregar esta carpeta
	if fbx_files.size() > 0:
		var folder_name = relative_path if relative_path != "" else "raíz"
		project_folders.append({
			"name": folder_name,
			"path": current_path,
			"fbx_files": fbx_files,
			"fbx_count": fbx_files.size()
		})
	
	# Escanear subdirectorios
	dir.list_dir_begin()
	file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var sub_path = relative_path + file_name + "/"
			var sub_dir = DirAccess.open(current_path + file_name)
			if sub_dir:
				_scan_directory_recursive(sub_dir, base_path, sub_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()

# NUEVA FUNCIÓN: Manejar selección de carpeta de proyecto
func _on_project_folder_selected(index: int):
	"""Callback cuando se selecciona una carpeta de proyecto"""
	if index >= 0 and index < project_folders.size():
		var folder_info = project_folders[index]
		current_project_folder = folder_info.path
		current_folder_path = folder_info.path
		
		add_export_log("📁 Carpeta seleccionada: %s" % folder_info.name)
		add_export_log("🔍 Cargando archivos FBX de la carpeta...")
		
		emit_signal("folder_selected", folder_info.path)
		
		# Cargar archivos FBX de esta carpeta
		display_fbx_list(folder_info.fbx_files)

func display_fbx_list(fbx_files: Array):
	"""Mostrar lista de archivos FBX - evitar duplicaciones"""
	if available_fbx_files == fbx_files:
		# Si ya tenemos los mismos archivos, no duplicar el proceso
		return
		
	available_fbx_files = fbx_files
	
	# Llenar lista de FBX base
	if base_fbx_option:
		base_fbx_option.clear()
		base_fbx_option.add_item("-- Seleccionar modelo base --")
		
		for file in fbx_files:
			base_fbx_option.add_item(file)
		
		base_fbx_option.disabled = false
	
	# NUEVO: Crear checkboxes para animaciones
	_create_animation_checkboxes(fbx_files)
	
	add_export_log("📋 Disponibles %d archivos FBX para selección" % fbx_files.size())

# NUEVA FUNCIÓN: Crear checkboxes para animaciones (CORREGIDA)
func _create_animation_checkboxes(fbx_files: Array):
	"""Crear checkboxes dinámicamente para cada archivo FBX (animaciones)"""
	print("📋 CREANDO CHECKBOXES PARA ANIMACIONES")
	
	# Encontrar el contenedor de checkboxes
	var checkbox_container = _find_node_by_name(self, "AnimationsCheckboxContainer")
	if not checkbox_container:
		print("❌ No se encontró AnimationsCheckboxContainer")
		return
	
	# Limpiar checkboxes existentes
	for child in checkbox_container.get_children():
		checkbox_container.remove_child(child)
		child.queue_free()
	
	# Crear checkbox para cada archivo FBX
	for fbx_file in fbx_files:
		var checkbox = CheckBox.new()
		checkbox.name = "AnimCheckbox_" + fbx_file.get_basename()
		checkbox.text = fbx_file
		checkbox.button_pressed = false
		
		# CORREGIDO: Usar callable para bind correcto
		var callback = func(pressed: bool): _on_animation_checkbox_toggled(pressed, fbx_file)
		checkbox.toggled.connect(callback)
		
		checkbox_container.add_child(checkbox)
	
	print("✅ Creados %d checkboxes para animaciones" % fbx_files.size())

# NUEVA FUNCIÓN: Manejar toggle de checkboxes de animaciones (CORREGIDA)
func _on_animation_checkbox_toggled(pressed: bool, fbx_file: String):
	"""Callback cuando se marca/desmarca un checkbox de animación"""
	if pressed and fbx_file not in selected_animations:
		selected_animations.append(fbx_file)
		add_export_log("✅ Animación seleccionada: %s" % fbx_file)
	elif not pressed and fbx_file in selected_animations:
		selected_animations.erase(fbx_file)
		add_export_log("❌ Animación deseleccionada: %s" % fbx_file)
	
	# Actualizar estado del botón de renderizado
	if render_button:
		render_button.disabled = selected_animations.is_empty()
	
	# Mostrar resumen de selecciones
	if selected_animations.size() > 0:
		add_export_log("📋 Total animaciones seleccionadas: %d" % selected_animations.size())
		emit_signal("animations_selected", selected_animations)
	else:
		add_export_log("📋 Ninguna animación seleccionada")
	
	print("📋 Animaciones seleccionadas: %s" % str(selected_animations))

func _on_base_fbx_selected(index: int):
	if index > 0:
		var filename = base_fbx_option.get_item_text(index)
		emit_signal("base_fbx_selected", filename)
		add_export_log("🎯 Modelo base seleccionado: " + filename)
		add_export_log("👆 Ahora selecciona las animaciones que deseas usar")

func enable_animation_selection():
	# ACTUALIZADO: Habilitar checkboxes de animaciones
	var checkbox_container = _find_node_by_name(self, "AnimationsCheckboxContainer")
	if checkbox_container:
		for child in checkbox_container.get_children():
			if child is CheckBox:
				child.disabled = false
				child.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Apariencia normal
		
		add_export_log("📋 Checkboxes de animaciones habilitados")
		add_export_log("☑️ Marca las animaciones que quieres incluir")
	
	if preview_button:
		preview_button.disabled = false
	add_export_log("✅ Modelo base cargado correctamente")
#
#func enable_animation_selection():
	## ACTUALIZADO: Habilitar checkboxes de animaciones
	#var checkbox_container = _find_node_by_name(self, "AnimationsCheckboxContainer")
	#if checkbox_container:
		#for child in checkbox_container.get_children():
			#if child is CheckBox:
				#child.disabled = false
				#child.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Apariencia normal
		#
		#add_export_log("📋 Checkboxes de animaciones habilitados")
	#
	#if preview_button:
		#preview_button.disabled = false
	#add_export_log("Modelo base cargado correctamente")

# NUEVA FUNCIÓN: Copiar todo el log al clipboard
func _on_log_copy_pressed():
	"""Copiar todo el contenido del log al clipboard"""
	if export_log:
		var log_text = export_log.get_parsed_text()
		DisplayServer.clipboard_set(log_text)
		add_export_log("[color=blue]📋 Log copiado al portapapeles[/color]")
		print("📋 Log copiado al portapapeles")

# NUEVA FUNCIÓN: Limpiar el log
func _on_log_clear_pressed():
	"""Limpiar todo el contenido del log"""
	if export_log:
		export_log.clear()
		add_export_log("Pixelize3D FBX - Log reiniciado")
		print("🗑️ Log limpiado")

# FUNCIÓN MEJORADA: Habilitar modo preview con controles
func enable_preview_mode():
	print("🎬 UI Preview Mode Activado")
	preview_mode_active = true
	
	# Actualizar status del preview
	if preview_status_label:
		preview_status_label.text = "✅ Preview Activo - Modelo cargado"
		preview_status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	# Mostrar controles de ayuda
	var controls_help = _find_node_by_name(self, "ControlsHelp")
	if controls_help:
		controls_help.visible = true
	
	# Habilitar controles de preview
	if preview_button:
		preview_button.disabled = false
		preview_button.text = "Preview Activo ✓"
		preview_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	# NUEVO: Habilitar botones de control de animación
	if play_button:
		play_button.disabled = false
	if pause_button:
		pause_button.disabled = false
	if stop_button:
		stop_button.disabled = false
	
	# Habilitar renderizado
	if render_button:
		render_button.disabled = false
	
	# Mostrar mensaje en el log
	add_export_log("[color=green]✅ Preview activado - Modelo visible en viewport[/color]")
	add_export_log("Controles: Click + Arrastrar para rotar vista")
	add_export_log("Usa los botones Play/Pause para controlar la animación")

# NUEVA FUNCIÓN: Copiar todo el log al clipboard
#func _on_log_copy_pressed():
	#"""Copiar todo el contenido del log al clipboard"""
	#if export_log:
		#var log_text = export_log.get_parsed_text()
		#DisplayServer.clipboard_set(log_text)
		#add_export_log("[color=blue]📋 Log copiado al portapapeles[/color]")
		#print("📋 Log copiado al portapapeles")
#
## NUEVA FUNCIÓN: Limpiar el log
#func _on_log_clear_pressed():
	#"""Limpiar todo el contenido del log"""
	#if export_log:
		#export_log.clear()
		#add_export_log("Pixelize3D FBX - Log reiniciado")
		#print("🗑️ Log limpiado")

# NUEVA FUNCIÓN CRÍTICA: Conectar SubViewport del SpriteRenderer (RUTA CORREGIDA)
func set_preview_texture(_texture: ViewportTexture):
	"""Recibe la textura del SpriteRenderer y conecta el SubViewport para animación en tiempo real"""
	print("📺 CONECTANDO SUBVIEWPORT PARA ANIMACIÓN EN TIEMPO REAL")
	
	# CORREGIDO: Usar ruta correcta (main en minúscula)
	var sprite_renderer = get_node_or_null("/root/main/SpriteRenderer")
	
	if not sprite_renderer:
		print("❌ ERROR: SpriteRenderer no encontrado en /root/main/SpriteRenderer")
		add_export_log("[color=red]❌ Error: SpriteRenderer no encontrado[/color]")
		
		# DEBUG: Mostrar qué nodos existen realmente
		print("🔍 DEBUG: Nodos disponibles en /root/main/:")
		var main_scene = get_node_or_null("/root/main")
		if main_scene:
			for child in main_scene.get_children():
				print("  - %s (%s)" % [child.name, child.get_class()])
		else:
			print("  ❌ No se pudo acceder a /root/main")
		return
	
	var sprite_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if not sprite_viewport:
		print("❌ ERROR: SubViewport del SpriteRenderer no encontrado")
		add_export_log("[color=red]❌ Error: SubViewport del SpriteRenderer no encontrado[/color]")
		return
	
	# Encontrar nuestro ViewportContainer
	var ui_viewport_container = _find_node_by_name(self, "ViewportContainer")
	if not ui_viewport_container:
		print("❌ ERROR: ViewportContainer no encontrado en UI")
		add_export_log("[color=red]❌ Error: ViewportContainer no encontrado[/color]")
		return
	
	# Actualizar referencia
	viewport_container = ui_viewport_container
	
	print("🔗 REUBICANDO SUBVIEWPORT PARA PREVIEW EN TIEMPO REAL")
	
	# Remover SubViewport del SpriteRenderer temporalmente
	sprite_renderer.remove_child(sprite_viewport)
	
	# Limpiar ViewportContainer si tiene hijos
	for child in viewport_container.get_children():
		if child.name == "NoPreviewLabel":
			child.visible = false  # Ocultar mensaje, no eliminar
		else:
			viewport_container.remove_child(child)
			child.queue_free()
	
	# Agregar SubViewport a nuestro ViewportContainer
	viewport_container.add_child(sprite_viewport)
	
	print("✅ SubViewport conectado exitosamente al ViewportContainer")
	
	# Actualizar status
	if preview_status_label:
		preview_status_label.text = "🎬 Preview activo - Animación en tiempo real"
		preview_status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	
	add_export_log("[color=green]📺 Preview en tiempo real activado exitosamente[/color]")
	add_export_log("🎬 Ahora deberías ver la animación moviéndose")

# NUEVAS FUNCIONES: Controles de animación
func _on_play_pressed():
	"""Callback para botón Play"""
	print("▶️ UI: Play solicitado")
	emit_signal("preview_play_requested")
	add_export_log("▶️ Reproduciendo animación")
	
	# Actualizar estados de botones
	if play_button:
		play_button.disabled = true
	if pause_button:
		pause_button.disabled = false

func _on_pause_pressed():
	"""Callback para botón Pause"""
	print("⏸️ UI: Pause solicitado")
	emit_signal("preview_pause_requested")
	add_export_log("⏸️ Animación pausada")
	
	# Actualizar estados de botones
	if play_button:
		play_button.disabled = false
	if pause_button:
		pause_button.disabled = true

func _on_stop_pressed():
	"""Callback para botón Stop"""
	print("⏹️ UI: Stop solicitado")
	emit_signal("preview_stop_requested")
	add_export_log("⏹️ Animación detenida")
	
	# Actualizar estados de botones
	if play_button:
		play_button.disabled = false
	if pause_button:
		pause_button.disabled = true

# NUEVA FUNCIÓN: Para que el SpriteRenderer notifique cuándo limpiar
func prepare_for_preview_cleanup():
	"""Preparar UI para que el SpriteRenderer recupere su SubViewport"""
	print("🔄 PREPARANDO PARA LIMPIEZA DE PREVIEW")
	
	# Buscar y remover el SubViewport de nuestro ViewportContainer
	if viewport_container:
		var sprite_viewport = null
		for child in viewport_container.get_children():
			if child is SubViewport:
				sprite_viewport = child
				break
		
		if sprite_viewport:
			viewport_container.remove_child(sprite_viewport)
			print("✅ SubViewport removido del ViewportContainer")
			return sprite_viewport
	
	return null

# Función auxiliar para buscar nodos por nombre recursivamente
func _find_node_by_name(parent: Node, node_name: String) -> Node:
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

func _on_camera_setting_changed(_value = null):
	var settings = {
		"camera_angle": camera_angle_slider.value if camera_angle_slider else 45.0,
		"camera_height": camera_height_slider.value if camera_height_slider else 10.0,
		"camera_distance": camera_distance_slider.value if camera_distance_slider else 15.0,
		"directions": int(directions_spinbox.value) if directions_spinbox else 16,
		"sprite_size": int(sprite_size_spinbox.value) if sprite_size_spinbox else 256,
		"fps": int(fps_spinbox.value) if fps_spinbox else 12,
		"pixelize": pixelize_checkbox.button_pressed if pixelize_checkbox else true
	}
	emit_signal("render_settings_changed", settings)

func _on_preview_pressed():
	if preview_mode_active:
		add_export_log("✅ Preview ya está activo")
	else:
		add_export_log("⏳ Esperando que se carguen los modelos para activar preview...")

func _on_render_pressed():
	if selected_animations.is_empty():
		add_export_log("[color=yellow]⚠️ Selecciona al menos una animación antes de renderizar[/color]")
		return
	
	add_export_log("🚀 Iniciando renderizado...")
	emit_signal("render_requested")

func show_loading_message(message: String):
	add_export_log("[color=yellow]⏳ %s[/color]" % message)

func hide_loading_message():
	pass

func show_progress_dialog():
	if progress_dialog:
		progress_dialog.popup_centered()

func update_progress(progress: float):
	if progress_dialog:
		var progress_bar = progress_dialog.get_node_or_null("VBoxContainer/ProgressBar")
		if progress_bar:
			progress_bar.value = progress * 100.0

func show_error(error: String):
	add_export_log("[color=red]❌ Error: %s[/color]" % error)
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Error"
	error_dialog.dialog_text = error
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.visibility_changed.connect(error_dialog.queue_free)

func add_export_log(message: String):
	var timestamp = Time.get_time_string_from_system()
	if export_log:
		export_log.append_text("[%s] %s\n" % [timestamp, message])

func is_preview_active() -> bool:
	return preview_mode_active

# FUNCIÓN ACTUALIZADA: Limpiar preview cuando se cierra
func clear_preview():
	"""Limpiar el preview y restablecer controles"""
	print("🧹 LIMPIANDO PREVIEW Y REUBICANDO SUBVIEWPORT")
	preview_mode_active = false
	
	# Buscar el SubViewport que está en nuestro ViewportContainer
	if viewport_container:
		var sprite_viewport = null
		for child in viewport_container.get_children():
			if child is SubViewport:
				sprite_viewport = child
				break
		
		# Si encontramos el SubViewport, devolverlo al SpriteRenderer
		if sprite_viewport:
			viewport_container.remove_child(sprite_viewport)
			
			# CORREGIDO: Usar ruta correcta (main en minúscula)
			var sprite_renderer = get_node_or_null("/root/main/SpriteRenderer")
			if sprite_renderer:
				sprite_renderer.add_child(sprite_viewport)
				print("✅ SubViewport devuelto al SpriteRenderer")
			else:
				print("❌ No se pudo devolver SubViewport - SpriteRenderer no encontrado")
	
	# Mostrar mensaje de "no preview"
	var no_preview_label = _find_node_by_name(self, "NoPreviewLabel")
	if no_preview_label:
		no_preview_label.visible = true
	
	# Desactivar controles
	if play_button:
		play_button.disabled = true
	if pause_button:
		pause_button.disabled = true
	if stop_button:
		stop_button.disabled = true
	
	# Actualizar status
	if preview_status_label:
		preview_status_label.text = "Carga un modelo para ver preview"
		preview_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	add_export_log("🔄 Preview limpiado - SubViewport reubicado")
