# scripts/rendering/camera_controller.gd
extends Node3D

# Input: Configuración de renderizado (ángulo, altura, distancia)
# Output: Posicionamiento correcto de la cámara para cada dirección

signal camera_ready()

@export var camera_angle: float = 45.0 # Ángulo isométrico (30-60 grados típicamente)
@export var camera_height: float = 10.0
@export var camera_distance: float = 15.0
@export var target_position: Vector3 = Vector3.ZERO
@export var use_orthographic: bool = true
@export var orthographic_size: float = 10.0

var camera_3d: Camera3D
var pivot_node: Node3D
var light_rig: Node3D

func _ready():
	_setup_camera_rig()
	_setup_lighting()

func _setup_camera_rig():
	# Crear nodo pivot para rotación
	pivot_node = Node3D.new()
	pivot_node.name = "CameraPivot"
	add_child(pivot_node)
	
	# Crear cámara
	camera_3d = Camera3D.new()
	camera_3d.name = "RenderCamera"
	
	if use_orthographic:
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.size = orthographic_size
	else:
		camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera_3d.fov = 35.0
	
	# Configurar propiedades de renderizado
	camera_3d.near = 0.1
	camera_3d.far = 100.0
	
	pivot_node.add_child(camera_3d)
	
	# Posicionar cámara inicial
	update_camera_position()

func _setup_lighting():
	light_rig = Node3D.new()
	light_rig.name = "LightRig"
	add_child(light_rig)
	
	# Luz direccional principal (key light)
	var key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_energy = 1.0
	key_light.light_color = Color(1.0, 0.95, 0.9)
	key_light.rotation_degrees = Vector3(-45, -45, 0)
	key_light.shadow_enabled = true
	key_light.shadow_bias = 0.1
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key_light.directional_shadow_max_distance = 50.0
	light_rig.add_child(key_light)
	
	# Luz de relleno (fill light)
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = 0.5
	fill_light.light_color = Color(0.9, 0.95, 1.0)
	fill_light.rotation_degrees = Vector3(-30, 135, 0)
	fill_light.shadow_enabled = false
	light_rig.add_child(fill_light)
	
	# Luz de borde (rim light)
	var rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_energy = 0.3
	rim_light.light_color = Color(1.0, 1.0, 1.0)
	rim_light.rotation_degrees = Vector3(45, 180, 0)
	rim_light.shadow_enabled = false
	light_rig.add_child(rim_light)

func update_camera_position():
	# Calcular posición de la cámara basada en ángulo isométrico
	var rad_angle = deg_to_rad(camera_angle)
	
	# Posición relativa de la cámara
	var cam_x = 0
	var cam_y = camera_height
	var cam_z = camera_distance
	
	camera_3d.position = Vector3(cam_x, cam_y, cam_z)
	
	# Rotar la cámara para mirar al objetivo
	camera_3d.look_at(target_position, Vector3.UP)

func set_rotation_angle(degrees: float):
	# Rotar el pivot para cambiar la dirección de vista
	pivot_node.rotation_degrees.y = degrees

func set_camera_settings(settings: Dictionary):
	if settings.has("camera_angle"):
		camera_angle = settings.camera_angle
	if settings.has("camera_height"):
		camera_height = settings.camera_height
	if settings.has("camera_distance"):
		camera_distance = settings.camera_distance
	if settings.has("target_position"):
		target_position = settings.target_position
	
	update_camera_position()
	
	# Actualizar tamaño ortográfico si es necesario
	if use_orthographic and settings.has("orthographic_size"):
		orthographic_size = settings.orthographic_size
		camera_3d.size = orthographic_size

func get_camera() -> Camera3D:
	return camera_3d

func calculate_orthographic_size_for_bounds(bounds: AABB) -> float:
	# Calcular el tamaño ortográfico necesario para encuadrar el modelo
	var diagonal = bounds.get_longest_axis_size()
	var padding = 1.2 # 20% de padding
	
	return diagonal * padding

func setup_for_model(model_bounds: AABB):
	# Centrar el objetivo en el modelo
	target_position = model_bounds.get_center()
	
	# Ajustar la distancia y el tamaño ortográfico
	var model_size = model_bounds.get_longest_axis_size()
	camera_distance = model_size * 2.0
	
	if use_orthographic:
		orthographic_size = calculate_orthographic_size_for_bounds(model_bounds)
		camera_3d.size = orthographic_size
	
	update_camera_position()
	emit_signal("camera_ready")

# Funciones de utilidad para previsualización
func enable_preview_mode():
	# En modo preview, permitir rotación interactiva
	set_process_input(true)

func disable_preview_mode():
	set_process_input(false)

var mouse_sensitivity = 0.3
var is_rotating = false

func _input(event):
	if not is_processing_input():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
	
	elif event is InputEventMouseMotion and is_rotating:
		pivot_node.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		
		# Limitar rotación vertical
		var new_angle = camera_angle - event.relative.y * mouse_sensitivity * 0.5
		camera_angle = clamp(new_angle, 15.0, 75.0)
		update_camera_position()

# Obtener la matriz de vista actual para debugging
func get_view_info() -> Dictionary:
	return {
		"camera_position": camera_3d.global_position,
		"camera_rotation": camera_3d.global_rotation_degrees,
		"pivot_rotation": pivot_node.rotation_degrees.y,
		"target": target_position,
		"orthographic_size": camera_3d.size if use_orthographic else 0.0
	}
