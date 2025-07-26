# scripts/viewer/ui/model_preview_panel.gd
# Panel especializado SOLO para mostrar preview del modelo 3D
# Input: Modelo 3D para mostrar
# Output: Visualización interactiva del modelo

extends VBoxContainer

# Señales específicas de este panel
signal model_displayed(model: Node3D)
signal preview_enabled()
signal animation_playing(animation_name: String)

# UI propia de este panel
var section_label: Label
var status_label: Label
var viewport_container: SubViewportContainer
var preview_viewport: SubViewport
var camera_container: Node3D
var model_container: Node3D
var controls_help_label: Label

# Estado interno
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var preview_active: bool = false

func _ready():
	_create_ui()

func _create_ui():
	# Título
	section_label = Label.new()
	section_label.text = "👁️ Vista Previa del Modelo"
	section_label.add_theme_font_size_override("font_size", 16)
	section_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(section_label)
	
	# Status
	status_label = Label.new()
	status_label.text = "Carga un modelo para comenzar"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)
	
	# Viewport para preview
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(viewport_container)
	
	preview_viewport = SubViewport.new()
	preview_viewport.transparent_bg = true
	preview_viewport.handle_input_locally = false
	preview_viewport.size = Vector2i(400, 400)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport_container.add_child(preview_viewport)
	
	# Cámara para el preview
	camera_container = Node3D.new()
	camera_container.name = "PreviewCameraController"
	preview_viewport.add_child(camera_container)
	
	# Luz
	var light = DirectionalLight3D.new()
	#light.transform = Transform3D(0.707107, -0.5, 0.5, 0, 0.707107, 0.707107, -0.707107, -0.5, 0.5, 0, 5, 0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	preview_viewport.add_child(light)
	
	# Contenedor para modelos
	model_container = Node3D.new()
	model_container.name = "ModelContainer"
	preview_viewport.add_child(model_container)
	
	# Ayuda de controles
	controls_help_label = Label.new()
	controls_help_label.text = "💡 Click+Arrastrar=Rotar | Rueda=Zoom"
	controls_help_label.add_theme_font_size_override("font_size", 10)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false
	add_child(controls_help_label)

func set_model(model: Node3D):
	# Limpiar modelo anterior
	if current_model:
		model_container.remove_child(current_model)
		current_model.queue_free()
	
	current_model = model.duplicate()
	model_container.add_child(current_model)
	
	# Centrar modelo
	_center_model()
	
	# Buscar AnimationPlayer
	animation_player = _find_animation_player(current_model)
	
	# Configurar cámara
	_setup_camera()
	
	# Actualizar status
	status_label.text = "✅ Modelo cargado: " + current_model.name
	
	emit_signal("model_displayed", current_model)

func enable_preview_mode():
	preview_active = true
	controls_help_label.visible = true
	status_label.text = "🎬 Preview activo - Modelo interactivo"
	
	# Habilitar input en viewport
	preview_viewport.handle_input_locally = true
	
	emit_signal("preview_enabled")

func play_animation(animation_name: String):
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		status_label.text = "▶️ Reproduciendo: " + animation_name
		emit_signal("animation_playing", animation_name)

func stop_animation():
	if animation_player:
		animation_player.stop()
		status_label.text = "⏹️ Animación detenida"

func _center_model():
	if not current_model:
		return
	
	var bounds = _calculate_bounds(current_model)
	if bounds.size.length() > 0:
		current_model.position = -bounds.get_center()

func _calculate_bounds(model: Node3D) -> AABB:
	var bounds = AABB()
	var first = true
	
	for child in model.get_children():
		if child is MeshInstance3D:
			var mesh_bounds = child.get_aabb()
			if first:
				bounds = mesh_bounds
				first = false
			else:
				bounds = bounds.merge(mesh_bounds)
	
	if first:
		bounds = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	
	return bounds

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _setup_camera():
	# Configuración básica de cámara para preview
	if not current_model:
		return
	
	var bounds = _calculate_bounds(current_model)
	var size = bounds.size.length()
	
	# Crear cámara simple si no existe
	var camera = camera_container.get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera_container.add_child(camera)
	
	# Posicionar cámara
	var distance = max(size * 2.0, 5.0)
	camera.position = Vector3(distance * 0.7, distance * 0.5, distance * 0.7)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Configurar proyección
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = max(size * 1.5, 3.0)

# Input básico para rotar cámara
func _input(event):
	if not preview_active or not current_model:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Simple rotación con mouse
			pass
	
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Rotar cámara container
		camera_container.rotation_degrees.y -= event.relative.x * 0.5
		camera_container.rotation_degrees.x = clamp(
			camera_container.rotation_degrees.x - event.relative.y * 0.5,
			-80, 80
		)

# Funciones públicas
func get_current_model() -> Node3D:
	return current_model

func has_model() -> bool:
	return current_model != null

func get_animation_player() -> AnimationPlayer:
	return animation_player

func is_preview_active() -> bool:
	return preview_active
