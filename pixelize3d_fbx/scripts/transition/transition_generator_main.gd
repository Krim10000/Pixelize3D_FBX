# pixelize3d_fbx/scripts/transition/transition_generator_main.gd
# Script principal de la herramienta de generación de transiciones
# Input: Interfaz de usuario y archivos FBX seleccionados
# Output: Sistema completo funcionando para generar transiciones suaves

extends Control
class_name TransitionGeneratorMain

# Referencias a componentes
var transition_coordinator: TransitionCoordinator
var transition_panel: TransitionPanel

# UI Layout
var sections_container: VBoxContainer
var files_section: Control
var config_section: Control  
var preview_section: Control

# Preview (opcional, para futuras mejoras)
var preview_enabled: bool = false
var preview_panel: Control

# Control de diálogos
var error_dialog_open: bool = false

func _ready():
	print("🚀 TransitionGeneratorMain inicializando...")
	_setup_ui()
	_initialize_components()
	_connect_signals()
	print("✅ Herramienta de transiciones lista para usar")

func _setup_ui():
	"""Configurar interfaz principal con 3 secciones horizontales (lado a lado)"""
	print("🎨 Configurando UI con 3 columnas horizontales...")
	
	# Título de la aplicación
	var title_bar = _create_title_bar()
	#add_child(title_bar)
	print("✅ Título creado")
	
	# Container principal con 3 columnas horizontales
	var main_container = HSplitContainer.new()
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_container)
	print("✅ Container principal creado")
	
	# === COLUMNA 1: CARGA DE ARCHIVOS ===
	files_section = _create_files_column()
	main_container.add_child(files_section)
	print("✅ Columna 1 (archivos) añadida")
	
	# Split container para las otras dos secciones
	var right_split = HSplitContainer.new()
	main_container.add_child(right_split)
	print("✅ Split derecho creado")
	
	# === COLUMNA 2: CONFIGURACIÓN Y CONTROLES ===
	config_section = _create_config_column()
	right_split.add_child(config_section)
	print("✅ Columna 2 (configuración) añadida")
	
	# === COLUMNA 3: PREVIEW ===
	preview_section = _create_preview_column()
	right_split.add_child(preview_section)
	print("✅ Columna 3 (preview) añadida")
	
	# Configurar proporciones
	main_container.split_offset = 300  # 300px para columna 1
	right_split.split_offset = 400     # 400px para columna 2, resto para columna 3
	
	print("✅ UI de 3 columnas configurada completamente")

func _create_title_bar() -> Control:
	"""Crear barra de título"""
	var title_container = VBoxContainer.new()
	title_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var title = Label.new()
	title.text = "Generador de Transiciones - Pixelize3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_stylebox_override("normal", _create_title_style())
	title_container.add_child(title)
	
	return title_container

func _create_files_column() -> Control:
	"""Crear columna de carga de archivos"""
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 280
	
	# Título
	var title = Label.new()
	title.text = "Carga"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	
	# Botón de selección
	var browse_button = Button.new()
	browse_button.text = "Seleccionar Carpeta..."
	browse_button.custom_minimum_size.y = 40
	column.add_child(browse_button)
	
	# Status
	var status_label = Label.new()
	status_label.text = "Selecciona una carpeta con archivos FBX"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	
	# Guardar referencias
	files_section = column
	files_section.set_meta("browse_button", browse_button)
	files_section.set_meta("status_label", status_label)
	
	return column

func _create_config_column() -> Control:
	"""Crear columna de configuración"""
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 380
	
	# Título
	var title = Label.new()
	title.text = "Configuración"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	
	# Container para el panel
	var panel_container = Control.new()
	panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_container.set_meta("panel_container", true)
	column.add_child(panel_container)
	
	return column

func _create_preview_column() -> Control:
	"""Crear columna de preview"""
	var column = VBoxContainer.new()
	
	# Título
	var title = Label.new()
	title.text = "Vista Previa"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	
	# Content
	var preview_content = VBoxContainer.new()
	preview_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Controles de preview
	var preview_controls = VBoxContainer.new()
	
	var play_button = Button.new()
	play_button.text = "▶️ Reproducir Transición"
	play_button.disabled = true
	preview_controls.add_child(play_button)
	
	var preview_slider = HSlider.new()
	preview_slider.min_value = 0.0
	preview_slider.max_value = 1.0
	preview_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_controls.add_child(preview_slider)
	
	var time_label = Label.new()
	time_label.text = "0.0s / 1.0s"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 10)
	preview_controls.add_child(time_label)
	
	preview_content.add_child(preview_controls)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 15
	preview_content.add_child(spacer2)
	
	# Placeholder para futuro modelo 3D
	var model_placeholder = Control.new()
	model_placeholder.custom_minimum_size = Vector2(280, 200)
	model_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var placeholder_bg = ColorRect.new()
	placeholder_bg.color = Color(0.05, 0.05, 0.1)
	placeholder_bg.anchors_preset = Control.PRESET_FULL_RECT
	model_placeholder.add_child(placeholder_bg)
	
	var placeholder_text = Label.new()
	placeholder_text.text = "Vista 3D\n(Próximamente)\n\nAquí se mostrará:\n• Modelo 3D\n• Preview en tiempo real\n• Control de la transición"
	placeholder_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_text.anchors_preset = Control.PRESET_FULL_RECT
	placeholder_text.add_theme_font_size_override("font_size", 10)
	placeholder_text.modulate = Color(0.7, 0.7, 0.7)
	model_placeholder.add_child(placeholder_text)
	
	preview_content.add_child(model_placeholder)
	column.add_child(preview_content)
	
	return column

func _initialize_components():
	"""Inicializar componentes del sistema"""
	print("🔧 Inicializando componentes...")
	
	# Crear TransitionCoordinator
	transition_coordinator = TransitionCoordinator.new()
	add_child(transition_coordinator)
	print("✅ TransitionCoordinator añadido")
	
	# Encontrar container para el panel
	var panel_container = config_section.get_children().filter(func(child): return child.has_meta("panel_container"))[0]
	if panel_container:
		print("✅ panel_container encontrado")
		
		# Crear TransitionPanel
		transition_panel = TransitionPanel.new()
		panel_container.add_child(transition_panel)
		print("✅ TransitionPanel añadido al contenedor")
	else:
		push_error("❌ No se encontró panel_container")
	
	print("✅ Componentes inicializados")

func _connect_signals():
	"""Conectar señales entre componentes"""
	print("🔌 Conectando señales...")
	
	# Conectar botón de carpeta
	var browse_button = files_section.get_meta("browse_button")
	if browse_button:
		browse_button.pressed.connect(_on_folder_browse_pressed)
	
	# Señales del panel hacia el coordinador
	if transition_panel:
		transition_panel.base_load_requested.connect(_on_base_load_requested)
		transition_panel.animation_a_load_requested.connect(_on_animation_a_load_requested)
		transition_panel.animation_b_load_requested.connect(_on_animation_b_load_requested)
		transition_panel.transition_generate_requested.connect(_on_transition_generate_requested)
		transition_panel.settings_changed.connect(_on_settings_changed)
	
	# Señales del coordinador hacia el panel
	if transition_coordinator:
		transition_coordinator.validation_complete.connect(_on_validation_complete)
		transition_coordinator.transition_progress.connect(_on_transition_progress)
		transition_coordinator.transition_complete.connect(_on_transition_complete)
		transition_coordinator.transition_failed.connect(_on_transition_failed)
	
	print("✅ Señales conectadas correctamente")

# ========================================================================
# MANEJADORES DE EVENTOS DE CARPETA
# ========================================================================

func _on_folder_browse_pressed():
	"""Manejar selección automática de carpeta"""
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.current_dir = "res://assets/"
	
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))
	
	var selected = await file_dialog.dir_selected
	file_dialog.queue_free()
	
	if selected != "":
		print("📂 Carpeta seleccionada: %s" % selected)
		_process_folder_automatically(selected)

func _process_folder_automatically(folder_path: String):
	"""Procesar carpeta automáticamente detectando base y animaciones"""
	print("🔍 Procesando carpeta automáticamente: %s" % folder_path)
	
	var status_label = files_section.get_meta("status_label")
	
	# Escanear archivos FBX en la carpeta
	var fbx_files = _scan_fbx_files(folder_path)
	
	if fbx_files.is_empty():
		status_label.text = "❌ No se encontraron archivos FBX"
		return
	
	print("📄 Archivos FBX encontrados: %d" % fbx_files.size())
	for file in fbx_files:
		print("  • %s" % file.get_file())
	
	# Detectar archivo base
	var base_file = _detect_base_file(fbx_files)
	var animation_files = _get_animation_files(fbx_files, base_file)
	
	if not base_file:
		status_label.text = "❌ No se encontró archivo base"
		return
	
	if animation_files.size() < 2:
		status_label.text = "⚠️ Pocas animaciones encontradas"
		return
	
	# Cargar automáticamente
	_auto_load_detected_files(base_file, animation_files, status_label)

func _scan_fbx_files(folder_path: String) -> Array:
	"""Escanear archivos FBX en una carpeta"""
	var fbx_files = []
	var dir = DirAccess.open(folder_path)
	
	if not dir:
		print("❌ No se pudo abrir carpeta: %s" % folder_path)
		return fbx_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.get_extension().to_lower() == "fbx":
			var full_path = folder_path.path_join(file_name)
			fbx_files.append(full_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return fbx_files

func _detect_base_file(fbx_files: Array) -> String:
	"""Detectar cuál archivo es la base"""
	
	# Buscar archivo que contenga "base" en el nombre
	for file_path in fbx_files:
		var file_name = file_path.get_file().to_lower()
		if "base" in file_name:
			print("✅ Archivo base detectado: %s" % file_path.get_file())
			return file_path
	
	# Si no hay "base", buscar patrones alternativos
	for file_path in fbx_files:
		var file_name = file_path.get_file().to_lower()
		if "mesh" in file_name or "model" in file_name or "character" in file_name:
			print("✅ Archivo base detectado (alternativo): %s" % file_path.get_file())
			return file_path
	
	print("❌ No se pudo detectar archivo base")
	return ""

func _get_animation_files(all_files: Array, base_file: String) -> Array:
	"""Obtener archivos de animación (todos excepto la base)"""
	var animation_files = []
	
	for file_path in all_files:
		if file_path != base_file:
			animation_files.append(file_path)
	
	print("🎭 Archivos de animación detectados: %d" % animation_files.size())
	return animation_files

func _auto_load_detected_files(base_file: String, animation_files: Array, status_label: Label):
	"""Cargar automáticamente archivos detectados"""
	print("🚀 Iniciando carga automática...")
	
	# Actualizar UI
	status_label.text = "📄 Procesando automáticamente..."
	
	print("🔄 DEBUG: Conectando al callback existente...")
	# Usar el callback ya existente _on_model_loaded del coordinator
	if not transition_coordinator.has_signal("resource_loaded"):
		print("❌ ERROR: TransitionCoordinator no tiene señal resource_loaded")
		return
	
	# Conectar a la señal existente
	if not transition_coordinator.resource_loaded.is_connected(_on_coordinator_resource_loaded):
		transition_coordinator.resource_loaded.connect(_on_coordinator_resource_loaded.bind(base_file, animation_files, status_label))
	
	print("🔄 DEBUG: Llamando a transition_coordinator.load_base_model()...")
	# Cargar base
	transition_coordinator.load_base_model(base_file)
	
	print("🔄 DEBUG: load_base_model() llamado, esperando señal resource_loaded...")

func _on_coordinator_resource_loaded(loaded_type: String, success: bool, base_file: String, animation_files: Array, status_label: Label):
	"""Callback cuando el coordinator carga un recurso"""
	print("🔄 DEBUG: _on_coordinator_resource_loaded - type: %s, success: %s" % [loaded_type, success])
	
	if loaded_type == "base":
		if success:
			status_label.text = "✅ Base: %s (%d anims)" % [base_file.get_file(), animation_files.size()]
			
			print("🔄 DEBUG: Llamando a transition_panel.on_base_loaded()...")
			# ✅ CRÍTICO: Actualizar UI del panel con el estado de la base
			transition_panel.on_base_loaded(success, base_file.get_file())
			
			print("🔄 DEBUG: Llamando a transition_panel.populate_animation_lists()...")
			# Enviar animaciones al panel para que las muestre
			transition_panel.populate_animation_lists(animation_files)
			
			print("✅ Carga automática completada")
			
			# Desconectar para evitar callbacks futuros
			if transition_coordinator.resource_loaded.is_connected(_on_coordinator_resource_loaded):
				transition_coordinator.resource_loaded.disconnect(_on_coordinator_resource_loaded)
				
		else:
			status_label.text = "❌ Error cargando base"
			print("❌ DEBUG: Error en carga de base")
			transition_panel.on_base_loaded(false, base_file.get_file())

# ========================================================================
# MANEJADORES DE EVENTOS DEL PANEL
# ========================================================================

func _on_base_load_requested(file_path: String):
	"""Manejar solicitud de carga de base"""
	print("📁 Cargando base: %s" % file_path.get_file())
	
	# Conectar callback temporal usando resource_loaded
	if not transition_coordinator.resource_loaded.is_connected(_on_manual_resource_loaded):
		transition_coordinator.resource_loaded.connect(_on_manual_resource_loaded.bind(file_path), CONNECT_ONE_SHOT)
	
	transition_coordinator.load_base_model(file_path)

func _on_manual_resource_loaded(loaded_type: String, success: bool, file_path: String):
	"""Callback para carga manual"""
	print("🔄 DEBUG: _on_manual_resource_loaded - type: %s, success: %s" % [loaded_type, success])
	
	if loaded_type == "base":
		transition_panel.on_base_loaded(success, file_path.get_file())
		
		if success:
			print("✅ Base cargada exitosamente")
		else:
			print("❌ Error cargando base")

func _on_animation_a_load_requested(file_path: String):
	"""Manejar solicitud de carga de animación A"""
	print("🎭 Cargando animación A: %s" % file_path.get_file())
	
	var success = transition_coordinator.load_animation_a(file_path)
	
	if success:
		print("✅ Animación A iniciada exitosamente")
		# La validación se hará cuando se complete la carga
		await get_tree().create_timer(0.5).timeout  # Dar tiempo para la carga
		_try_auto_validate()
	else:
		print("❌ Error iniciando carga de animación A")

func _on_animation_b_load_requested(file_path: String):
	"""Manejar solicitud de carga de animación B"""
	print("🎭 Cargando animación B: %s" % file_path.get_file())
	
	var success = transition_coordinator.load_animation_b(file_path)
	
	if success:
		print("✅ Animación B iniciada exitosamente")
		# La validación se hará cuando se complete la carga
		await get_tree().create_timer(0.5).timeout  # Dar tiempo para la carga
		_try_auto_validate()
	else:
		print("❌ Error iniciando carga de animación B")

func _on_settings_changed(config: Dictionary):
	"""Manejar cambios en configuración"""
	print("⚙️ Configuración actualizada: %s" % str(config))
	transition_coordinator.update_transition_config(config)

func _on_transition_generate_requested():
	"""Manejar solicitud de generación"""
	print("🎬 Iniciando generación de transición...")
	
	# Validar primero
	var is_valid = transition_coordinator.validate_transition_data()
	if not is_valid:
		print("❌ Datos no válidos para transición")
		return
	
	# Generar transición (este método aún usa await internamente)
	var success = await transition_coordinator.generate_transition()
	if success:
		print("✅ Transición generada exitosamente")
	else:
		print("❌ Error generando transición")

# ========================================================================
# MANEJADORES DE EVENTOS DEL COORDINADOR
# ========================================================================

func _on_validation_complete(is_valid: bool, message: String):
	"""Manejar resultado de validación"""
	print("🔍 Validación: %s - %s" % [("✅" if is_valid else "❌"), message])
	transition_panel.on_validation_result(is_valid, message)

func _on_transition_progress(current: int, total: int, stage: String):
	"""Manejar progreso de transición"""
	print("📊 Progreso: %d/%d (%s)" % [current, total, stage])
	transition_panel.on_transition_progress(current, total)

func _on_transition_complete(output_name: String):
	"""Manejar transición completada"""
	print("🎉 Transición completada: %s" % output_name)
	transition_panel.on_transition_complete(output_name)
	
	# Mostrar dialogo de éxito
	_show_success_dialog(output_name)

func _on_transition_failed(error: String):
	"""Manejar error en transición"""
	print("💥 Error en transición: %s" % error)
	transition_panel.on_transition_failed(error)
	
	# Mostrar diálogo de error
	_show_error_dialog(error)

# ========================================================================
# UTILIDADES Y HELPERS
# ========================================================================

func _try_auto_validate():
	"""Intentar validación automática cuando se cargan archivos"""
	
	# Esperar un frame para que se procesen las cargas
	await get_tree().process_frame
	
	# Solo validar si tenemos todo cargado
	if transition_coordinator and transition_coordinator.base_data.size() > 0 and \
	   transition_coordinator.animation_a_data.size() > 0 and \
	   transition_coordinator.animation_b_data.size() > 0:
		
		print("🔍 Ejecutando validación automática...")
		transition_coordinator.validate_transition_data()

func _show_help():
	"""Mostrar ayuda del sistema"""
	var help_dialog = AcceptDialog.new()
	help_dialog.title = "Ayuda - Generador de Transiciones"
	
	var help_text = """🔄 Generador de Transiciones - Pixelize3D

📋 PASOS PARA USAR (AUTOMÁTICO):

1️⃣ Seleccionar Carpeta:
   • Click "Seleccionar Carpeta..."
   • Navega a una carpeta con archivos FBX
   • El sistema detectará automáticamente:
	 ✅ Base: archivo con 'base' en el nombre
	 ✅ Animaciones: resto de archivos FBX

2️⃣ Seleccionar Transición:
   • Animación A: Escoge de la lista inicial
   • Animación B: Escoge de la lista final
   • Solo se puede seleccionar UNA de cada lista

3️⃣ Configurar Transición:
   • Duración: Tiempo de la transición en segundos
   • Frames: Cantidad de frames intermedios a generar
   • Curva: Tipo de interpolación (recomendado: Ease In-Out)
   • FPS: Frames por segundo del sprite sheet final

4️⃣ Generar:
   • Presiona "Validar" para verificar compatibilidad
   • Presiona "Generar" para crear el sprite sheet

📁 ESTRUCTURA DE CARPETA RECOMENDADA:
res://assets/character_knight/
├── knight_base.fbx    ← Base (se detecta por "base")
├── walk.fbx          ← Animación 1
├── run.fbx           ← Animación 2
└── idle.fbx          ← Animación 3

📄 SALIDA:
El sprite sheet se guardará como: transition_walk_to_run.png

⚠️ REQUISITOS:
• Al menos 1 archivo con "base" en el nombre
• Al menos 2 archivos de animación adicionales
• Mismo esqueleto en todos los archivos

🎮 ATAJOS DE TECLADO:
F1 - Esta ayuda
F2 - Estado del sistema
F3 - Debug coordinador
F4 - Test sistema de carpetas
"""
	
	help_dialog.dialog_text = help_text
	add_child(help_dialog)
	help_dialog.popup_centered(Vector2i(650, 600))
	
	# Auto-destruir cuando se cierre
	help_dialog.confirmed.connect(func(): help_dialog.queue_free())

func _show_success_dialog(output_name: String):
	"""Mostrar diálogo de éxito"""
	var success_dialog = AcceptDialog.new()
	success_dialog.title = "🎉 Transición Generada"
	success_dialog.dialog_text = "La transición se generó exitosamente:\n\n📄 " + output_name + ".png\n\n¡Ya puedes usar tu sprite sheet de transición!"
	
	add_child(success_dialog)
	success_dialog.popup_centered(Vector2i(400, 200))
	success_dialog.confirmed.connect(func(): success_dialog.queue_free())

#var error_dialog_open: bool = false

func _show_error_dialog(error_message: String):
	"""Mostrar diálogo de error"""
	# Prevenir múltiples diálogos abiertos
	if error_dialog_open:
		print("⚠️ Diálogo de error ya abierto, ignorando: %s" % error_message)
		return
	
	error_dialog_open = true
	
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "❌ Error"
	error_dialog.dialog_text = "Error generando la transición:\n\n" + error_message + "\n\nRevisa la configuración y archivos cargados."
	
	add_child(error_dialog)
	error_dialog.popup_centered(Vector2i(450, 200))
	
	# Limpiar flag cuando se cierre
	error_dialog.confirmed.connect(func(): 
		error_dialog_open = false
		error_dialog.queue_free()
	)

func _create_title_style() -> StyleBox:
	"""Crear estilo para la barra de título"""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

# ========================================================================
# API PÚBLICA PARA INTEGRACIÓN
# ========================================================================

func load_files_programmatically(base_path: String, anim_a_path: String, anim_b_path: String):
	"""Cargar archivos programáticamente (para testing o integración)"""
	print("🔧 Carga programática de archivos...")
	
	# Usar el nuevo sistema de callbacks
	_on_base_load_requested(base_path)
	
	# Dar tiempo para que se complete la carga de base
	await get_tree().create_timer(1.0).timeout
	
	_on_animation_a_load_requested(anim_a_path)
	_on_animation_b_load_requested(anim_b_path)
	
	print("✅ Cargas programáticas iniciadas")

func set_transition_config(config: Dictionary):
	"""Configurar transición programáticamente"""
	if transition_coordinator:
		transition_coordinator.update_transition_config(config)
		print("⚙️ Configuración aplicada programáticamente")

func generate_transition_programmatically() -> bool:
	"""Generar transición programáticamente"""
	if transition_coordinator:
		# Nota: La generación aún usa el sistema de await interno
		# Solo la carga de archivos se cambió a callbacks
		return await transition_coordinator.generate_transition()
	return false

func get_transition_status() -> Dictionary:
	"""Obtener estado actual del sistema"""
	if not transition_coordinator:
		return {"status": "not_initialized"}
	
	return {
		"status": "ready",
		"base_loaded": transition_coordinator.base_data.size() > 0,
		"anim_a_loaded": transition_coordinator.animation_a_data.size() > 0,
		"anim_b_loaded": transition_coordinator.animation_b_data.size() > 0,
		"is_generating": transition_coordinator.is_generating_transition
	}

# ========================================================================
# TESTING Y DEBUG
# ========================================================================

func _input(event):
	"""Manejo de input para testing/debug"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_show_help()
			KEY_F2:
				print("🔍 Estado actual: %s" % str(get_transition_status()))
			KEY_F3:
				if transition_coordinator:
					print("🦴 Datos del coordinador:")
					print("  Base: %s" % str(transition_coordinator.base_data.keys()))
					print("  Anim A: %s" % str(transition_coordinator.animation_a_data.keys()))
					print("  Anim B: %s" % str(transition_coordinator.animation_b_data.keys()))
			KEY_F4:
				_test_folder_system()

func _test_folder_system():
	"""Probar sistema de carpetas con datos de ejemplo"""
	print("🧪 === TESTING SISTEMA DE CARPETAS ===")
	
	# Simular una carpeta de ejemplo
	var test_folder = "res://assets/test_character"
	print("🧪 Simulando carga de: %s" % test_folder)
	_process_folder_automatically(test_folder)
	
	print("🧪 === FIN TEST ===")

func _show_startup_info():
	"""Mostrar información de inicio"""
	print("\n📋 === INFORMACIÓN DE INICIO ===")
	print("📄 Generador de Transiciones v1.0")
	print("📂 Directorio base: res://assets/")
	print("🎮 Controles:")
	print("  F1 - Ayuda")
	print("  F2 - Estado actual")
	print("  F3 - Debug coordinador") 
	print("  F4 - Test sistema de carpetas")
	print("🔍 Selecciona una carpeta para comenzar")
	print("=====================================\n")
