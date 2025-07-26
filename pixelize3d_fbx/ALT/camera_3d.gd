extends Camera3D

@export var rotation_speed: float = 0.01
@export var zoom_speed: float = 0.1
@export var pan_speed: float = 0.005

var target_distance: float = 5.0
var current_rotation: Vector2 = Vector2.ZERO
var target: Vector3 = Vector3.ZERO
var is_rotating: bool = false
var is_panning: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _ready():
	# Configuración inicial
	position = Vector3(0, 0, target_distance)
	look_at(target)

func _input(event):
	# Rotación con clic izquierdo
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
		
		# Zoom con rueda del ratón
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = max(0.5, target_distance - zoom_speed * 10)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance += zoom_speed * 10
	
	# Pan con clic derecho
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		is_panning = event.pressed
	
	# Guardar posición del ratón para movimiento
	if event is InputEventMouseMotion:
		last_mouse_pos = event.position

func _process(delta):
	# Actualizar posición de la cámara
	var new_position = Vector3(0, 0, target_distance)
	
	# Aplicar rotación
	var rotation_transform = Transform3D.IDENTITY
	rotation_transform = rotation_transform.rotated(Vector3.UP, current_rotation.x)
	rotation_transform = rotation_transform.rotated(rotation_transform.basis.x, current_rotation.y)
	new_position = rotation_transform * new_position
	
	position = new_position
	
	# Mirar al objetivo
	look_at(target)
	
	# Manejar rotación
	if is_rotating and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_pos
		current_rotation.x -= mouse_delta.x * rotation_speed
		current_rotation.y = clamp(current_rotation.y - mouse_delta.y * rotation_speed, -PI/2 + 0.01, PI/2 - 0.01)
		last_mouse_pos = get_viewport().get_mouse_position()
	
	# Manejar pan
	if is_panning and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_pos
		var right = global_transform.basis.x
		var up = global_transform.basis.y
		
		target += right * -mouse_delta.x * pan_speed
		target += up * mouse_delta.y * pan_speed
		
		last_mouse_pos = get_viewport().get_mouse_position()

# Función para ajustar la cámara al modelo
func fit_to_model(model: Node3D):
	# Calcular el bounding box del modelo
	var aabb = _calculate_model_aabb(model)
	
	if aabb.size == Vector3.ZERO:
		# Si no se puede calcular el AABB, usar posición por defecto
		target = Vector3.ZERO
		target_distance = 5.0
		current_rotation = Vector2.ZERO
		return
	
	# Calcular centro del modelo
	var center = aabb.position + aabb.size / 2.0
	target = center
	
	# Calcular distancia necesaria para que el modelo quepa en la vista
	var size = max(aabb.size.x, aabb.size.y, aabb.size.z)
	var fov_rad = deg_to_rad(fov)
	var distance = (size / 2.0) / tan(fov_rad / 2.0)
	
	# Añadir un margen
	target_distance = distance * 1.5
	
	# Resetear rotación
	current_rotation = Vector2.ZERO
	
	# Actualizar posición inmediatamente
	var new_position = Vector3(0, 0, target_distance)
	position = new_position
	look_at(target)

# Función recursiva para calcular el AABB del modelo
func _calculate_model_aabb(node: Node3D) -> AABB:
	var aabb = AABB()
	var first = true
	
	if node is MeshInstance3D:
		aabb = node.get_aabb()
		first = false
	
	for child in node.get_children():
		if child is Node3D:
			var child_aabb = _calculate_model_aabb(child)
			if not child_aabb.size == Vector3.ZERO:
				if first:
					aabb = child_aabb
					first = false
				else:
					aabb = aabb.merge(child_aabb)
	
	return aabb
