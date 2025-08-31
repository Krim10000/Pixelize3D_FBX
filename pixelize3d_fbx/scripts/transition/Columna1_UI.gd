# pixelize3d_fbx/scripts/transition/Columna1_UI.gd
# Interfaz gráfica de la Columna 1 - Sistema de carga
# Input: Interacciones del usuario para carga de modelo base y animaciones
# Output: Señales de solicitud de carga y estado visual de progreso

extends VBoxContainer
class_name Columna1UI

# === SEÑALES HACIA EL COORDINADOR ===
signal base_load_requested(file_path: String)
signal animation_a_load_requested(file_path: String)
signal animation_b_load_requested(file_path: String)
signal preview_requested()

# === COMPONENTES DE UI ===
# Sección de carga
var load_section: VBoxContainer
var folder_dialog: FileDialog
var base_file_button: Button
var base_status_label: Label

# Sección de animaciones (modo removido según feedback)
var animations_section: VBoxContainer
var animation_a_panel: VBoxContainer
var animation_a_list: ItemList
var animation_a_status: Label
var animation_b_panel: VBoxContainer
var animation_b_list: ItemList
var animation_b_status: Label

# Sección de preview
var preview_section: VBoxContainer
var preview_button: Button
var status_label: Label
var progress_bar: ProgressBar

# === ESTADO INTERNO ===
var current_folder_path: String = ""
var available_fbx_files: Array = []
var base_loaded: bool = false
var animation_a_loaded: bool = false
var animation_b_loaded: bool = false
var is_loading: bool = false

# === DATOS ===
var loaded_base_data: Dictionary = {}
var loaded_animation_a_data: Dictionary = {}
var loaded_animation_b_data: Dictionary = {}

func _ready():
	print("📋 Columna1UI inicializando...")
	_create_ui()
	_connect_signals()
	print("✅ Columna1UI listo")

func _create_ui():
	"""Crear interfaz de usuario de la Columna 1 - OPTIMIZADA"""
	print("🎨 Creando UI de Columna 1...")
	
	# Título de la columna
	var title = _create_column_title()
	add_child(title)
	
	# Separador
	add_child(HSeparator.new())
	
	# === SECCIÓN 1: CARGA DE ARCHIVOS ===
	_create_load_section()
	add_child(load_section)
	add_child(HSeparator.new())
	
	# === SECCIÓN 2: SELECCIÓN DE ANIMACIONES ===
	_create_animations_section()
	add_child(animations_section)
	add_child(HSeparator.new())
	
	# === SECCIÓN 3: PREVIEW Y ESTADO ===
	_create_preview_section()
	add_child(preview_section)
	
	print("✅ UI de Columna 1 creada (sin modo - optimizada)")

func _create_column_title() -> Control:
	"""Crear título de la columna"""
	var title_container = VBoxContainer.new()
	
	var title = Label.new()
	title.text = "📂 CARGA DE MODELOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_stylebox_override("normal", _create_title_style())
	title_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Selecciona base + 2 animaciones"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title_container.add_child(subtitle)
	
	return title_container

func _create_load_section():
	"""Crear sección de carga de archivos"""
	load_section = VBoxContainer.new()
	
	var section_title = Label.new()
	section_title.text = "🏗️ Modelo Base"
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_stylebox_override("normal", _create_section_style())
	load_section.add_child(section_title)
	
	# Botón para seleccionar carpeta
	base_file_button = Button.new()
	base_file_button.text = "📂 Seleccionar Carpeta..."
	base_file_button.pressed.connect(_on_select_folder_pressed)
	load_section.add_child(base_file_button)
	
	# Estado del modelo base
	base_status_label = Label.new()
	base_status_label.text = "No cargado - Selecciona una carpeta"
	base_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	base_status_label.add_theme_font_size_override("font_size", 10)
	base_status_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	load_section.add_child(base_status_label)
	
	# Crear diálogo de carpeta
	_create_folder_dialog()

# === SECCIÓN DE MODO COMENTADA (no corresponde a esta columna) ===
# func _create_mode_section():
# 	"""Crear sección de modo de operación - COMENTADA"""
# 	mode_section = VBoxContainer.new()
# 	var section_title = Label.new()
# 	section_title.text = "⚙️ Modo de Transición"
# 	# ... resto del código comentado

func _create_animations_section():
	"""Crear sección de selección de animaciones"""
	animations_section = VBoxContainer.new()
	
	var section_title = Label.new()
	section_title.text = "🎭 Selección de Animaciones"
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_stylebox_override("normal", _create_section_style())
	animations_section.add_child(section_title)
	
	# Container horizontal para las dos animaciones
	var anims_container = HBoxContainer.new()
	anims_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	animations_section.add_child(anims_container)
	
	# === ANIMACIÓN A ===
	_create_animation_a_panel()
	anims_container.add_child(animation_a_panel)
	
	# Separador vertical
	anims_container.add_child(VSeparator.new())
	
	# === ANIMACIÓN B ===
	_create_animation_b_panel()
	anims_container.add_child(animation_b_panel)

func _create_animation_a_panel():
	"""Crear panel para Animación A"""
	animation_a_panel = VBoxContainer.new()
	animation_a_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title = Label.new()
	title.text = "🅰️ Animación Inicial"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	animation_a_panel.add_child(title)
	
	# Lista de animaciones disponibles
	animation_a_list = ItemList.new()
	animation_a_list.custom_minimum_size = Vector2(130, 120)
	animation_a_list.add_item("-- Selecciona una carpeta --")
	animation_a_list.item_selected.connect(_on_animation_a_selected)
	animation_a_list.select_mode = ItemList.SELECT_SINGLE
	animation_a_panel.add_child(animation_a_list)
	
	# Estado de la animación A
	animation_a_status = Label.new()
	animation_a_status.text = "No seleccionada"
	animation_a_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animation_a_status.add_theme_font_size_override("font_size", 9)
	animation_a_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	animation_a_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	animation_a_panel.add_child(animation_a_status)

func _create_animation_b_panel():
	"""Crear panel para Animación B"""
	animation_b_panel = VBoxContainer.new()
	animation_b_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title = Label.new()
	title.text = "🅱️ Animación Final"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	animation_b_panel.add_child(title)
	
	# Lista de animaciones disponibles
	animation_b_list = ItemList.new()
	animation_b_list.custom_minimum_size = Vector2(130, 120)
	animation_b_list.add_item("-- Selecciona una carpeta --")
	animation_b_list.item_selected.connect(_on_animation_b_selected)
	animation_b_list.select_mode = ItemList.SELECT_SINGLE
	animation_b_panel.add_child(animation_b_list)
	
	# Estado de la animación B
	animation_b_status = Label.new()
	animation_b_status.text = "No seleccionada"
	animation_b_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	animation_b_status.add_theme_font_size_override("font_size", 9)
	animation_b_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	animation_b_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	animation_b_panel.add_child(animation_b_status)

func _create_preview_section():
	"""Crear sección de preview y estado"""
	preview_section = VBoxContainer.new()
	
	var section_title = Label.new()
	section_title.text = "👁️ Preview y Estado"
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_stylebox_override("normal", _create_section_style())
	preview_section.add_child(section_title)
	
	# Botón de preview (NUEVO según requisitos)
	preview_button = Button.new()
	preview_button.text = "👁️ Preview Animaciones"
	preview_button.disabled = true
	preview_button.pressed.connect(_on_preview_pressed)
	preview_section.add_child(preview_button)
	
	# Barra de progreso
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	preview_section.add_child(progress_bar)
	
	# Etiqueta de estado
	status_label = Label.new()
	status_label.text = "Selecciona archivos para comenzar"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_section.add_child(status_label)

func _create_folder_dialog():
	"""Crear diálogo para selección de carpeta"""
	folder_dialog = FileDialog.new()
	folder_dialog.size = Vector2i(800, 600)
	folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
	folder_dialog.current_dir = "res://assets"
	folder_dialog.dir_selected.connect(_on_folder_selected)
	add_child(folder_dialog)

# ========================================================================
# MANEJADORES DE EVENTOS DE UI
# ========================================================================

func _on_select_folder_pressed():
	"""Manejar clic en botón de seleccionar carpeta"""
	if folder_dialog:
		folder_dialog.popup_centered()

func _on_folder_selected(folder_path: String):
	"""Manejar selección de carpeta"""
	print("📂 Carpeta seleccionada: %s" % folder_path)
	current_folder_path = folder_path
	
	# Actualizar estado visual
	base_file_button.text = "📂 " + folder_path.get_file()
	base_status_label.text = "Analizando carpeta..."
	
	# Procesar archivos de la carpeta
	_process_folder_contents(folder_path)

# === FUNCIÓN DE MODO COMENTADA (no corresponde a esta columna) ===
# func _on_mode_changed(index: int):
# 	"""Manejar cambio de modo de transición - COMENTADA"""
# 	# Funcionalidad movida a columna 3
# 	print("⚙️ Modo cambiado a: %d (comentado)" % index)

func _on_animation_a_selected(index: int):
	"""Manejar selección de animación A"""
	if index < 0 or animation_a_list.get_item_count() <= index:
		return
	
	var file_path = animation_a_list.get_item_metadata(index)
	if file_path and file_path is String:
		print("🎭 Animación A seleccionada: %s" % file_path)
		animation_a_status.text = "⏳ Cargando..."
		animation_a_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		
		# Emitir señal de solicitud de carga
		emit_signal("animation_a_load_requested", file_path)

func _on_animation_b_selected(index: int):
	"""Manejar selección de animación B"""
	if index < 0 or animation_b_list.get_item_count() <= index:
		return
	
	var file_path = animation_b_list.get_item_metadata(index)
	if file_path and file_path is String:
		print("🎭 Animación B seleccionada: %s" % file_path)
		animation_b_status.text = "⏳ Cargando..."
		animation_b_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		
		# Emitir señal de solicitud de carga
		emit_signal("animation_b_load_requested", file_path)

func _on_preview_pressed():
	"""Manejar clic en botón de preview"""
	print("👁️ Preview solicitado")
	preview_button.text = "⏳ Generando preview..."
	preview_button.disabled = true
	
	# Emitir señal de solicitud de preview
	emit_signal("preview_requested")

# ========================================================================
# PROCESAMIENTO DE ARCHIVOS
# ========================================================================

func _process_folder_contents(folder_path: String):
	"""Procesar contenido de la carpeta seleccionada"""
	print("📁 Procesando carpeta: %s" % folder_path)
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		_show_error("No se pudo acceder a la carpeta: " + folder_path)
		return
	
	# Buscar archivos FBX
	available_fbx_files.clear()
	var base_file = ""
	var animation_files = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.get_extension().to_lower() in ["fbx", "glb", "gltf"]:
			var full_path = folder_path.path_join(file_name)
			available_fbx_files.append(full_path)
			
			# Detectar archivo base vs animaciones
			if "base" in file_name.to_lower():
				base_file = full_path
			else:
				animation_files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Procesar resultados
	if available_fbx_files.is_empty():
		_show_error("No se encontraron archivos FBX en la carpeta")
		return
	
	print("📊 Archivos encontrados: %d FBX" % available_fbx_files.size())
	print("  Base: %s" % base_file)
	print("  Animaciones: %d" % animation_files.size())
	
	# Cargar modelo base automáticamente si se encontró
	if base_file:
		_auto_load_base_model(base_file)
	
	# Poblar listas de animaciones
	_populate_animation_lists(animation_files)

func _auto_load_base_model(base_path: String):
	"""Cargar modelo base automáticamente"""
	print("🏗️ Cargando base automáticamente: %s" % base_path)
	
	base_status_label.text = "⏳ Cargando modelo base..."
	base_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	# Emitir señal de solicitud de carga
	emit_signal("base_load_requested", base_path)

func _populate_animation_lists(animation_files: Array):
	"""Poblar listas de animaciones disponibles"""
	print("🎭 Poblando listas de animaciones...")
	
	# Limpiar listas
	animation_a_list.clear()
	animation_b_list.clear()
	
	# Agregar animaciones a ambas listas
	for file_path in animation_files:
		var file_name = file_path.get_file()
		
		animation_a_list.add_item(file_name)
		animation_a_list.set_item_metadata(-1, file_path)
		
		animation_b_list.add_item(file_name)
		animation_b_list.set_item_metadata(-1, file_path)
	
	# Actualizar estado si hay animaciones
	if animation_files.size() > 0:
		animation_a_status.text = "Selecciona animación inicial"
		animation_b_status.text = "Selecciona animación final"
		animation_a_status.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		animation_b_status.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		
		status_label.text = "Selecciona 2 animaciones para continuar"
	else:
		_show_error("No se encontraron archivos de animación")

# ========================================================================
# CALLBACKS DESDE EL COORDINADOR (llamadas por Columna1_logic)
# ========================================================================

func on_base_loaded(model_data: Dictionary):
	"""Callback cuando el modelo base se carga exitosamente"""
	print("✅ UI: Modelo base cargado confirmado")
	
	base_loaded = true
	loaded_base_data = model_data
	
	base_status_label.text = "✅ " + model_data.get("file_path", "").get_file()
	base_status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	_update_ui_state()

func on_animation_loaded(animation_data: Dictionary):
	"""Callback cuando una animación se carga exitosamente"""
	var anim_type = animation_data.get("type", "unknown")
	print("✅ UI: Animación cargada confirmada - %s" % anim_type)
	
	if anim_type == "animation_a":
		animation_a_loaded = true
		loaded_animation_a_data = animation_data
		animation_a_status.text = "✅ " + animation_data.get("file_path", "").get_file()
		animation_a_status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	elif anim_type == "animation_b":
		animation_b_loaded = true
		loaded_animation_b_data = animation_data
		animation_b_status.text = "✅ " + animation_data.get("file_path", "").get_file()
		animation_b_status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	_update_ui_state()

func on_loading_failed(error_message: String):
	"""Callback cuando falla la carga"""
	print("❌ UI: Error de carga - %s" % error_message)
	
	is_loading = false
	progress_bar.visible = false
	
	_show_error(error_message)
	_update_ui_state()

# ========================================================================
# ACTUALIZACIÓN DE ESTADO
# ========================================================================

func _update_ui_state():
	"""Actualizar estado de la interfaz según los datos cargados"""
	var all_loaded = base_loaded and animation_a_loaded and animation_b_loaded
	
	# Actualizar botón de preview
	preview_button.disabled = not all_loaded
	
	if all_loaded:
		preview_button.text = "👁️ Preview Animaciones"
		status_label.text = "✅ Listo para preview y transición"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		var missing = []
		if not base_loaded: missing.append("base")
		if not animation_a_loaded: missing.append("animación A") 
		if not animation_b_loaded: missing.append("animación B")
		
		status_label.text = "Faltan: " + ", ".join(missing)
		status_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))

func _show_error(message: String):
	"""Mostrar mensaje de error"""
	print("❌ Error: %s" % message)
	
	status_label.text = "❌ " + message
	status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	
	# Reset visual states on error
	if not base_loaded:
		base_status_label.text = "❌ Error al cargar"
		base_status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	
	if not animation_a_loaded:
		animation_a_status.text = "❌ Error al cargar"
		animation_a_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		
	if not animation_b_loaded:
		animation_b_status.text = "❌ Error al cargar"
		animation_b_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

# ========================================================================
# CONECTAR SEÑALES
# ========================================================================

func _connect_signals():
	"""Conectar señales internas"""
	print("🔗 Conectando señales de Columna1UI...")
	# Las conexiones principales se manejan en el coordinador
	print("✅ Señales conectadas")

# ========================================================================
# ESTILOS DE UI
# ========================================================================

func _create_title_style() -> StyleBox:
	"""Crear estilo para títulos"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	return style

func _create_section_style() -> StyleBox:
	"""Crear estilo para secciones"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	return style

# ========================================================================
# API PÚBLICA PARA DEBUG
# ========================================================================

func get_ui_state() -> Dictionary:
	"""Obtener estado actual de la UI"""
	return {
		"base_loaded": base_loaded,
		"animation_a_loaded": animation_a_loaded,
		"animation_b_loaded": animation_b_loaded,
		"current_folder": current_folder_path,
		"available_files": available_fbx_files.size()
	}

func reset_ui():
	"""Resetear UI a estado inicial"""
	print("🔄 Reseteando UI de Columna 1...")
	
	# Reset flags
	base_loaded = false
	animation_a_loaded = false
	animation_b_loaded = false
	is_loading = false
	
	# Reset data
	loaded_base_data.clear()
	loaded_animation_a_data.clear()
	loaded_animation_b_data.clear()
	
	# Reset visuals
	base_file_button.text = "📂 Seleccionar Carpeta..."
	base_status_label.text = "No cargado - Selecciona una carpeta"
	animation_a_status.text = "No seleccionada"
	animation_b_status.text = "No seleccionada"
	status_label.text = "Selecciona archivos para comenzar"
	
	# Clear lists
	animation_a_list.clear()
	animation_b_list.clear()
	animation_a_list.add_item("-- Selecciona una carpeta --")
	animation_b_list.add_item("-- Selecciona una carpeta --")
	
	progress_bar.visible = false
	preview_button.text = "👁️ Preview Animaciones"
	preview_button.disabled = true
	
	print("✅ UI de Columna 1 reseteada")
