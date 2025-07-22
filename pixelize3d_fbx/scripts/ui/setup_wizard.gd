# scripts/ui/setup_wizard.gd
extends Control

# Input: Primera ejecución de la aplicación
# Output: Configuración inicial completa

signal setup_complete(config: Dictionary)
signal setup_cancelled()

@onready var page_container: Control = $VBoxContainer/PageContainer
@onready var navigation_buttons: HBoxContainer = $VBoxContainer/NavigationButtons
@onready var back_button: Button = $VBoxContainer/NavigationButtons/BackButton
@onready var next_button: Button = $VBoxContainer/NavigationButtons/NextButton
@onready var finish_button: Button = $VBoxContainer/NavigationButtons/FinishButton

var current_page: int = 0
var pages: Array = []
var wizard_data: Dictionary = {}

func _ready():
	_create_wizard_pages()
	_setup_navigation()
	_show_page(0)

func _create_wizard_pages():
	# Página 1: Bienvenida
	var welcome_page = _create_welcome_page()
	pages.append(welcome_page)
	page_container.add_child(welcome_page)
	
	# Página 2: Configuración de renderizado
	var render_page = _create_render_settings_page()
	pages.append(render_page)
	page_container.add_child(render_page)
	
	# Página 3: Configuración de exportación
	var export_page = _create_export_settings_page()
	pages.append(export_page)
	page_container.add_child(export_page)
	
	# Página 4: Optimización de rendimiento
	var performance_page = _create_performance_page()
	pages.append(performance_page)
	page_container.add_child(performance_page)
	
	# Página 5: Plugins y extensiones
	var plugins_page = _create_plugins_page()
	pages.append(plugins_page)
	page_container.add_child(plugins_page)
	
	# Página 6: Resumen
	var summary_page = _create_summary_page()
	pages.append(summary_page)
	page_container.add_child(summary_page)

func _create_welcome_page() -> Control:
	var page = VBoxContainer.new()
	page.name = "WelcomePage"
	
	# Logo/Imagen
	var logo = TextureRect.new()
	logo.custom_minimum_size = Vector2(400, 200)
	# logo.texture = preload("res://assets/logo.png")
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page.add_child(logo)
	
	# Título
	var title = Label.new()
	title.text = "Bienvenido a Pixelize3D FBX"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)
	
	page.add_child(HSeparator.new())
	
	# Descripción
	var desc = RichTextLabel.new()
	desc.custom_minimum_size = Vector2(600, 200)
	desc.bbcode_enabled = true
	desc.text = """[center]¡Gracias por elegir Pixelize3D FBX!

Este asistente te ayudará a configurar la herramienta por primera vez.

[b]Características principales:[/b]
• Conversión de modelos FBX a spritesheets isométricos
• Renderizado en múltiples direcciones (8, 16, 32)
• Exportación optimizada para diferentes motores de juego
• Sistema de plugins para extender funcionalidad

Haz clic en [b]Siguiente[/b] para comenzar la configuración.[/center]"""
	page.add_child(desc)
	
	# Checkbox para no mostrar de nuevo
	var skip_checkbox = CheckBox.new()
	skip_checkbox.text = "No mostrar este asistente en el futuro"
	skip_checkbox.toggled.connect(func(pressed): wizard_data["skip_wizard"] = pressed)
	page.add_child(skip_checkbox)
	
	return page

func _create_render_settings_page() -> Control:
	var page = ScrollContainer.new()
	page.name = "RenderSettingsPage"
	
	var vbox = VBoxContainer.new()
	page.add_child(vbox)
	
	var title = Label.new()
	title.text = "Configuración de Renderizado"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Preset de calidad
	var quality_label = Label.new()
	quality_label.text = "Preset de Calidad:"
	vbox.add_child(quality_label)
	
	var quality_option = OptionButton.new()
	quality_option.add_item("Rendimiento (Rápido)")
	quality_option.add_item("Balanceado (Recomendado)")
	quality_option.add_item("Alta Calidad (Lento)")
	quality_option.selected = 1
	quality_option.item_selected.connect(func(idx): _on_quality_preset_selected(idx))
	vbox.add_child(quality_option)
	
	# Direcciones por defecto
	var dir_label = Label.new()
	dir_label.text = "\nDirecciones por defecto:"
	vbox.add_child(dir_label)
	
	var dir_container = HBoxContainer.new()
	vbox.add_child(dir_container)
	
	var dir_group = ButtonGroup.new()
	for dirs in [8, 16, 32]:
		var radio = RadioButton.new()
		radio.text = str(dirs) + " direcciones"
		radio.button_group = dir_group
		radio.pressed.connect(func(): wizard_data["default_directions"] = dirs)
		if dirs == 16:
			radio.button_pressed = true
			wizard_data["default_directions"] = 16
		dir_container.add_child(radio)
	
	# Tamaño de sprite
	var size_label = Label.new()
	size_label.text = "\nTamaño de sprite por defecto:"
	vbox.add_child(size_label)
	
	var size_slider = HSlider.new()
	size_slider.min_value = 64
	size_slider.max_value = 512
	size_slider.step = 32
	size_slider.value = 256
	size_slider.value_changed.connect(func(val): 
		wizard_data["default_sprite_size"] = int(val)
		size_value_label.text = str(int(val)) + " px"
	)
	vbox.add_child(size_slider)
	
	var size_value_label = Label.new()
	size_value_label.text = "256 px"
	vbox.add_child(size_value_label)
	
	# Efectos
	var effects_label = Label.new()
	effects_label.text = "\nEfectos:"
	vbox.add_child(effects_label)
	
	var pixelize_check = CheckBox.new()
	pixelize_check.text = "Aplicar efecto de pixelización"
	pixelize_check.button_pressed = true
	pixelize_check.toggled.connect(func(pressed): wizard_data["pixelize"] = pressed)
	vbox.add_child(pixelize_check)
	
	var shadows_check = CheckBox.new()
	shadows_check.text = "Renderizar sombras"
	shadows_check.button_pressed = true
	shadows_check.toggled.connect(func(pressed): wizard_data["shadows"] = pressed)
	vbox.add_child(shadows_check)
	
	var aa_check = CheckBox.new()
	aa_check.text = "Anti-aliasing"
	aa_check.button_pressed = true
	aa_check.toggled.connect(func(pressed): wizard_data["anti_aliasing"] = pressed)
	vbox.add_child(aa_check)
	
	return page

func _create_export_settings_page() -> Control:
	var page = VBoxContainer.new()
	page.name = "ExportSettingsPage"
	
	var title = Label.new()
	title.text = "Configuración de Exportación"
	title.add_theme_font_size_override("font_size", 24)
	page.add_child(title)
	
	page.add_child(HSeparator.new())
	
	# Formato de archivo
	var format_label = Label.new()
	format_label.text = "Formato de imagen:"
	page.add_child(format_label)
	
	var format_option = OptionButton.new()
	format_option.add_item("PNG (Recomendado)")
	format_option.add_item("WebP")
	format_option.add_item("JPEG")
	format_option.selected = 0
	format_option.item_selected.connect(func(idx): 
		wizard_data["export_format"] = ["png", "webp", "jpeg"][idx]
	)
	page.add_child(format_option)
	
	# Organización de archivos
	var org_label = Label.new()
	org_label.text = "\nOrganización de archivos:"
	page.add_child(org_label)
	
	var org_by_unit = CheckBox.new()
	org_by_unit.text = "Organizar por unidad"
	org_by_unit.button_pressed = true
	org_by_unit.toggled.connect(func(pressed): wizard_data["organize_by_unit"] = pressed)
	page.add_child(org_by_unit)
	
	var org_by_anim = CheckBox.new()
	org_by_anim.text = "Separar por animación"
	org_by_anim.button_pressed = true
	org_by_anim.toggled.connect(func(pressed): wizard_data["organize_by_animation"] = pressed)
	page.add_child(org_by_anim)
	
	# Metadata
	var meta_label = Label.new()
	meta_label.text = "\nGenerar metadata para:"
	page.add_child(meta_label)
	
	var meta_formats = {
		"JSON": true,
		"Unity": false,
		"Godot": false,
		"Web (Phaser/Pixi)": false,
		"Unreal": false
	}
	
	wizard_data["metadata_formats"] = []
	
	for format in meta_formats:
		var check = CheckBox.new()
		check.text = format
		check.button_pressed = meta_formats[format]
		check.toggled.connect(func(pressed, fmt=format):
			if pressed and not fmt in wizard_data["metadata_formats"]:
				wizard_data["metadata_formats"].append(fmt)
			elif not pressed and fmt in wizard_data["metadata_formats"]:
				wizard_data["metadata_formats"].erase(fmt)
		)
		page.add_child(check)
		
		if meta_formats[format]:
			wizard_data["metadata_formats"].append(format)
	
	# Carpeta de salida
	var output_label = Label.new()
	output_label.text = "\nCarpeta de salida por defecto:"
	page.add_child(output_label)
	
	var output_container = HBoxContainer.new()
	page.add_child(output_container)
	
	var output_path = LineEdit.new()
	output_path.text = "exports"
	output_path.custom_minimum_size.x = 300
	output_path.text_changed.connect(func(text): wizard_data["default_output_folder"] = text)
	output_container.add_child(output_path)
	
	var browse_button = Button.new()
	browse_button.text = "Examinar..."
	browse_button.pressed.connect(func(): _browse_output_folder(output_path))
	output_container.add_child(browse_button)
	
	return page

func _create_performance_page() -> Control:
	var page = VBoxContainer.new()
	page.name = "PerformancePage"
	
	var title = Label.new()
	title.text = "Optimización de Rendimiento"
	title.add_theme_font_size_override("font_size", 24)
	page.add_child(title)
	
	page.add_child(HSeparator.new())
	
	# Ejecutar benchmark
	var bench_label = Label.new()
	bench_label.text = "Analizar capacidades del sistema:"
	page.add_child(bench_label)
	
	var bench_button = Button.new()
	bench_button.text = "Ejecutar Benchmark"
	bench_button.pressed.connect(_run_benchmark)
	page.add_child(bench_button)
	
	var bench_results = RichTextLabel.new()
	bench_results.name = "BenchmarkResults"
	bench_results.custom_minimum_size = Vector2(500, 150)
	bench_results.bbcode_enabled = true
	page.add_child(bench_results)
	
	page.add_child(HSeparator.new())
	
	# Configuración manual
	var manual_label = Label.new()
	manual_label.text = "Configuración manual:"
	page.add_child(manual_label)
	
	# Renders paralelos
	var parallel_label = Label.new()
	parallel_label.text = "\nRenders paralelos:"
	page.add_child(parallel_label)
	
	var parallel_slider = HSlider.new()
	parallel_slider.min_value = 1
	parallel_slider.max_value = OS.get_processor_count()
	parallel_slider.step = 1
	parallel_slider.value = min(4, OS.get_processor_count() - 1)
	parallel_slider.value_changed.connect(func(val):
		wizard_data["max_parallel_renders"] = int(val)
		parallel_value.text = str(int(val))
	)
	page.add_child(parallel_slider)
	
	var parallel_value = Label.new()
	parallel_value.text = str(int(parallel_slider.value))
	page.add_child(parallel_value)
	
	# Modo de memoria baja
	var low_mem_check = CheckBox.new()
	low_mem_check.text = "Modo de memoria baja"
	low_mem_check.toggled.connect(func(pressed): wizard_data["low_memory_mode"] = pressed)
	page.add_child(low_mem_check)
	
	# Cache de modelos
	var cache_check = CheckBox.new()
	cache_check.text = "Cachear modelos cargados"
	cache_check.button_pressed = true
	cache_check.toggled.connect(func(pressed): wizard_data["cache_models"] = pressed)
	page.add_child(cache_check)
	
	return page

func _create_plugins_page() -> Control:
	var page = VBoxContainer.new()
	page.name = "PluginsPage"
	
	var title = Label.new()
	title.text = "Plugins y Extensiones"
	title.add_theme_font_size_override("font_size", 24)
	page.add_child(title)
	
	page.add_child(HSeparator.new())
	
	var desc = Label.new()
	desc.text = "Los plugins permiten extender la funcionalidad de Pixelize3D.\nSelecciona los plugins que deseas activar:"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(desc)
	
	page.add_child(HSeparator.new())
	
	# Lista de plugins disponibles
	var available_plugins = [
		{
			"name": "Batch Optimizer",
			"description": "Optimiza automáticamente los ajustes para procesamiento por lotes",
			"enabled": true
		},
		{
			"name": "Advanced Shaders",
			"description": "Shaders adicionales para efectos especiales",
			"enabled": false
		},
		{
			"name": "Cloud Export",
			"description": "Exporta directamente a servicios en la nube",
			"enabled": false
		},
		{
			"name": "Animation Retargeting",
			"description": "Reutiliza animaciones entre diferentes modelos",
			"enabled": false
		}
	]
	
	wizard_data["enabled_plugins"] = []
	
	for plugin in available_plugins:
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 5)
		
		var check = CheckBox.new()
		check.text = plugin.name
		check.button_pressed = plugin.enabled
		check.toggled.connect(func(pressed, pname=plugin.name):
			if pressed and not pname in wizard_data["enabled_plugins"]:
				wizard_data["enabled_plugins"].append(pname)
			elif not pressed and pname in wizard_data["enabled_plugins"]:
				wizard_data["enabled_plugins"].erase(pname)
		)
		container.add_child(check)
		
		if plugin.enabled:
			wizard_data["enabled_plugins"].append(plugin.name)
		
		var desc_label = Label.new()
		desc_label.text = "  " + plugin.description
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.add_theme_font_size_override("font_size", 12)
		container.add_child(desc_label)
		
		page.add_child(container)
	
	# Actualizaciones automáticas
	page.add_child(HSeparator.new())
	
	var updates_check = CheckBox.new()
	updates_check.text = "Buscar actualizaciones automáticamente"
	updates_check.button_pressed = true
	updates_check.toggled.connect(func(pressed): wizard_data["auto_updates"] = pressed)
	page.add_child(updates_check)
	
	return page

func _create_summary_page() -> Control:
	var page = VBoxContainer.new()
	page.name = "SummaryPage"
	
	var title = Label.new()
	title.text = "Resumen de Configuración"
	title.add_theme_font_size_override("font_size", 24)
	page.add_child(title)
	
	page.add_child(HSeparator.new())
	
	var summary_text = RichTextLabel.new()
	summary_text.name = "SummaryText"
	summary_text.bbcode_enabled = true
	summary_text.custom_minimum_size = Vector2(600, 400)
	page.add_child(summary_text)
	
	return page

func _setup_navigation():
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	finish_button.visible = false

func _show_page(index: int):
	current_page = index
	
	# Ocultar todas las páginas
	for page in pages:
		page.visible = false
	
	# Mostrar página actual
	if index >= 0 and index < pages.size():
		pages[index].visible = true
		
		# Actualizar página de resumen si es la última
		if index == pages.size() - 1:
			_update_summary_page()
	
	# Actualizar botones
	back_button.disabled = index == 0
	next_button.visible = index < pages.size() - 1
	finish_button.visible = index == pages.size() - 1

func _on_back_pressed():
	if current_page > 0:
		_show_page(current_page - 1)

func _on_next_pressed():
	if current_page < pages.size() - 1:
		_show_page(current_page + 1)

func _on_finish_pressed():
	# Aplicar configuración
	_apply_configuration()
	emit_signal("setup_complete", wizard_data)
	queue_free()

func _on_quality_preset_selected(index: int):
	match index:
		0: # Rendimiento
			wizard_data["quality_preset"] = "performance"
			wizard_data["shadows"] = false
			wizard_data["anti_aliasing"] = false
			wizard_data["default_sprite_size"] = 128
		1: # Balanceado
			wizard_data["quality_preset"] = "balanced"
			wizard_data["shadows"] = true
			wizard_data["anti_aliasing"] = true
			wizard_data["default_sprite_size"] = 256
		2: # Alta calidad
			wizard_data["quality_preset"] = "high"
			wizard_data["shadows"] = true
			wizard_data["anti_aliasing"] = true
			wizard_data["default_sprite_size"] = 512

func _browse_output_folder(line_edit: LineEdit):
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.dir_selected.connect(func(path): line_edit.text = path)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _run_benchmark():
	var results_label = get_node("VBoxContainer/PageContainer/PerformancePage/BenchmarkResults")
	results_label.text = "[color=yellow]Ejecutando benchmark...[/color]"
	
	# Simular benchmark
	await get_tree().create_timer(2.0).timeout
	
	var optimizer = preload("res://scripts/core/performance_optimizer.gd").new()
	add_child(optimizer)
	var results = optimizer.run_system_benchmark()
	optimizer.queue_free()
	
	var results_text = """[b]Resultados del Benchmark:[/b]
CPU Score: [color=%s]%.1f/100[/color]
GPU Score: [color=%s]%.1f/100[/color]
Memory Score: [color=%s]%.1f/100[/color]

[b]Puntuación Total: %.1f/100[/b]

Configuración recomendada: [b]%s[/b]
""" % [
		_get_score_color(results.cpu_score), results.cpu_score,
		_get_score_color(results.gpu_score), results.gpu_score,
		_get_score_color(results.memory_score), results.memory_score,
		results.overall_score,
		results.recommended_settings.preset.capitalize()
	]
	
	results_label.text = results_text
	
	# Aplicar recomendaciones
	wizard_data.merge(results.recommended_settings, true)

func _get_score_color(score: float) -> String:
	if score >= 70:
		return "green"
	elif score >= 40:
		return "yellow"
	else:
		return "red"

func _update_summary_page():
	var summary = get_node("VBoxContainer/PageContainer/SummaryPage/SummaryText")
	
	var text = """[b]Tu configuración:[/b]

[b]Renderizado:[/b]
• Direcciones por defecto: %d
• Tamaño de sprite: %d px
• Pixelización: %s
• Sombras: %s
• Anti-aliasing: %s

[b]Exportación:[/b]
• Formato: %s
• Organizar por unidad: %s
• Metadata: %s

[b]Rendimiento:[/b]
• Renders paralelos: %d
• Modo memoria baja: %s
• Cache de modelos: %s

[b]Plugins activados:[/b]
%s

[b]Actualizaciones automáticas:[/b] %s

[color=green]¡Todo listo para comenzar![/color]
""" % [
		wizard_data.get("default_directions", 16),
		wizard_data.get("default_sprite_size", 256),
		"Sí" if wizard_data.get("pixelize", true) else "No",
		"Sí" if wizard_data.get("shadows", true) else "No",
		"Sí" if wizard_data.get("anti_aliasing", true) else "No",
		wizard_data.get("export_format", "png").to_upper(),
		"Sí" if wizard_data.get("organize_by_unit", true) else "No",
		", ".join(wizard_data.get("metadata_formats", ["JSON"])),
		wizard_data.get("max_parallel_renders", 4),
		"Sí" if wizard_data.get("low_memory_mode", false) else "No",
		"Sí" if wizard_data.get("cache_models", true) else "No",
		"• " + "\n• ".join(wizard_data.get("enabled_plugins", ["Ninguno"])),
		"Sí" if wizard_data.get("auto_updates", true) else "No"
	]
	
	summary.text = text

func _apply_configuration():
	# Guardar configuración usando el ConfigManager
	var config_manager = preload("res://scripts/core/config_manager.gd").new()
	
	# Convertir wizard_data al formato del config manager
	var config = {
		"render": {
			"directions": wizard_data.get("default_directions", 16),
			"sprite_size": wizard_data.get("default_sprite_size", 256),
			"pixelize": wizard_data.get("pixelize", true),
			"shadows": wizard_data.get("shadows", true),
			"anti_aliasing": wizard_data.get("anti_aliasing", true)
		},
		"export": {
			"format": wizard_data.get("export_format", "png"),
			"organize_by_unit": wizard_data.get("organize_by_unit", true),
			"metadata_formats": wizard_data.get("metadata_formats", ["JSON"])
		},
		"performance": {
			"max_parallel_renders": wizard_data.get("max_parallel_renders", 4),
			"low_memory_mode": wizard_data.get("low_memory_mode", false),
			"cache_models": wizard_data.get("cache_models", true)
		},
		"ui": {
			"skip_wizard": wizard_data.get("skip_wizard", false)
		}
	}
	
	config_manager.current_config = config
	config_manager.save_config()
	config_manager.queue_free()
