# scripts/ui/debug_overlay.gd
extends Control

# Input: Información del sistema de debug
# Output: Panel visual con métricas en tiempo real

var debug_system: Node
var update_interval: float = 0.1
var update_timer: float = 0.0

# Paneles de información
var fps_label: Label
var memory_label: Label
var render_label: Label
var task_label: Label
var log_viewer: RichTextLabel

# Gráficos de rendimiento
var fps_history: Array = []
var memory_history: Array = []
var max_history_points: int = 100

func _ready():
	set_process(true)
	_create_ui()
	_apply_debug_theme()

func _create_ui():
	# Panel principal semi-transparente
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = Vector2(300, 400)
	panel.modulate = Color(1, 1, 1, 0.9)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Título
	var title = Label.new()
	title.text = "Debug Overlay"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Sección FPS
	fps_label = Label.new()
	fps_label.text = "FPS: --"
	vbox.add_child(fps_label)
	
	# Gráfico de FPS
	var fps_graph = Control.new()
	fps_graph.custom_minimum_size = Vector2(280, 60)
	fps_graph.draw.connect(_draw_fps_graph.bind(fps_graph))
	vbox.add_child(fps_graph)
	
	# Sección Memoria
	memory_label = Label.new()
	memory_label.text = "Memoria: --"
	vbox.add_child(memory_label)
	
	# Gráfico de memoria
	var memory_graph = Control.new()
	memory_graph.custom_minimum_size = Vector2(280, 60)
	memory_graph.draw.connect(_draw_memory_graph.bind(memory_graph))
	vbox.add_child(memory_graph)
	
	# Sección Renderizado
	render_label = Label.new()
	render_label.text = "Renders: 0/0"
	vbox.add_child(render_label)
	
	# Tarea actual
	task_label = Label.new()
	task_label.text = "Tarea: Ninguna"
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(task_label)
	
	vbox.add_child(HSeparator.new())
	
	# Visor de logs
	var log_label = Label.new()
	log_label.text = "Logs Recientes:"
	vbox.add_child(log_label)
	
	log_viewer = RichTextLabel.new()
	log_viewer.custom_minimum_size = Vector2(280, 150)
	log_viewer.scroll_following = true
	log_viewer.bbcode_enabled = true
	vbox.add_child(log_viewer)
	
	# Botones de control
	var button_container = HBoxContainer.new()
	vbox.add_child(button_container)
	
	var clear_button = Button.new()
	clear_button.text = "Limpiar"
	clear_button.pressed.connect(_on_clear_pressed)
	button_container.add_child(clear_button)
	
	var export_button = Button.new()
	export_button.text = "Exportar"
	export_button.pressed.connect(_on_export_pressed)
	button_container.add_child(export_button)
	
	var hide_button = Button.new()
	hide_button.text = "Ocultar"
	hide_button.pressed.connect(hide)
	button_container.add_child(hide_button)
	
	# Hacer draggable
	_make_draggable(panel)

func _apply_debug_theme():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	
	# Aplicar a todos los paneles
	for child in get_children():
		if child is PanelContainer:
			child.add_theme_stylebox_override("panel", style)

func _process(delta: float):
	update_timer += delta
	
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()

func _update_display():
	# Actualizar FPS
	var fps = Engine.get_frames_per_second()
	fps_label.text = "FPS: %d (%.2f ms)" % [fps, 1000.0 / fps if fps > 0 else 0]
	
	# Añadir a historial
	fps_history.append(fps)
	if fps_history.size() > max_history_points:
		fps_history.pop_front()
	
	# Actualizar memoria
	var static_mem = OS.get_static_memory_usage() / 1048576.0 # MB
	var video_mem = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	memory_label.text = "Memoria: %.1f MB | Video: %.1f MB" % [static_mem, video_mem]
	
	memory_history.append(static_mem)
	if memory_history.size() > max_history_points:
		memory_history.pop_front()
	
	# Actualizar info de renderizado
	if debug_system and debug_system.performance_metrics:
		var metrics = debug_system.performance_metrics
		render_label.text = "Renders: %d/%d (%.1f%% éxito)" % [
			metrics.renders_completed,
			metrics.renders_completed + metrics.renders_failed,
			100.0 * metrics.renders_completed / max(1, metrics.renders_completed + metrics.renders_failed)
		]
	
	# Actualizar tarea actual
	if has_node("/root/Main"):
		var main = get_node("/root/Main")
		if "current_project_data" in main:
			var current = main.current_project_data.get("base_fbx", "")
			if current != "":
				task_label.text = "Tarea: Procesando " + current
			else:
				task_label.text = "Tarea: Esperando..."
	
	# Forzar redibujado de gráficos
	for child in get_children():
		if child.has_method("queue_redraw"):
			child.queue_redraw()

func _draw_fps_graph(graph: Control):
	if fps_history.is_empty():
		return
	
	var size = graph.size
	var max_fps = 120.0
	var min_fps = 0.0
	
	# Dibujar líneas de referencia
	graph.draw_line(Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5), 
		Color(0.3, 0.3, 0.3, 0.5), 1.0)
	graph.draw_string(graph.get_theme_default_font(), Vector2(5, size.y * 0.5), 
		"60", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.5))
	
	# Dibujar gráfico
	var points = PackedVector2Array()
	for i in range(fps_history.size()):
		var x = (i / float(max_history_points - 1)) * size.x
		var y = size.y - (fps_history[i] / max_fps) * size.y
		points.append(Vector2(x, y))
	
	if points.size() > 1:
		# Color basado en FPS
		var current_fps = fps_history[-1]
		var color = Color.GREEN if current_fps >= 60 else Color.YELLOW if current_fps >= 30 else Color.RED
		
		for i in range(points.size() - 1):
			graph.draw_line(points[i], points[i + 1], color, 2.0)

func _draw_memory_graph(graph: Control):
	if memory_history.is_empty():
		return
	
	var size = graph.size
	var max_memory = 0.0
	
	# Encontrar máximo
	for mem in memory_history:
		max_memory = max(max_memory, mem)
	
	max_memory = max(max_memory * 1.2, 100.0) # Añadir margen
	
	# Dibujar líneas de referencia
	var ref_lines = [0.25, 0.5, 0.75]
	for ref in ref_lines:
		var y = size.y * (1.0 - ref)
		graph.draw_line(Vector2(0, y), Vector2(size.x, y), 
			Color(0.3, 0.3, 0.3, 0.3), 1.0)
		graph.draw_string(graph.get_theme_default_font(), Vector2(5, y), 
			"%.0f MB" % (max_memory * ref), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 
			Color(0.5, 0.5, 0.5))
	
	# Dibujar gráfico
	var points = PackedVector2Array()
	for i in range(memory_history.size()):
		var x = (i / float(max_history_points - 1)) * size.x
		var y = size.y - (memory_history[i] / max_memory) * size.y
		points.append(Vector2(x, y))
	
	if points.size() > 1:
		for i in range(points.size() - 1):
			graph.draw_line(points[i], points[i + 1], Color.CYAN, 2.0)

func add_log_entry(entry: Dictionary):
	var color = _get_log_color(entry.level)
	var formatted = "[color=%s][%s][/color] %s" % [
		color,
		entry.level,
		entry.message
	]
	
	log_viewer.append_text(formatted + "\n")
	
	# Limitar líneas en el visor
	if log_viewer.get_line_count() > 100:
		log_viewer.clear()
		log_viewer.append_text("[color=gray]... logs anteriores truncados ...[/color]\n")

func _get_log_color(level: String) -> String:
	match level:
		"ERROR", "CRITICAL": return "#ff4444"
		"WARNING": return "#ffaa44"
		"INFO": return "#44ff44"
		"DEBUG": return "#4444ff"
		_: return "#ffffff"

func _make_draggable(panel: Control):
	var dragging = false
	var drag_offset = Vector2.ZERO
	
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				dragging = event.pressed
				drag_offset = event.position
		elif event is InputEventMouseMotion and dragging:
			panel.position += event.position - drag_offset
	)

func _on_clear_pressed():
	log_viewer.clear()
	fps_history.clear()
	memory_history.clear()

func _on_export_pressed():
	if debug_system:
		var report = debug_system.generate_debug_report()
		var path = "user://debug_report_%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
		
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(report, "\t"))
			file.close()
			
			log_viewer.append_text("[color=green]Reporte exportado a: %s[/color]\n" % path)

# Atajos de teclado
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F3:
				visible = !visible
			KEY_F4:
				if visible:
					_on_export_pressed()

# Conectar al sistema de debug
func connect_to_debug_system(system: Node):
	debug_system = system
	if debug_system.has_signal("log_written"):
		debug_system.log_written.connect(add_log_entry)
