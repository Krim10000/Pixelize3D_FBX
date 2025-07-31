# pixelize3d_fbx/scripts/viewer/camera_controls.gd
# Controles de cámara - VERSIÓN CORREGIDA SIN ERRORES DE OPERADOR TERNARIO
# Input: Eventos de teclado y mouse del usuario
# Output: Movimiento de cámara y rotación del modelo

extends Node

# Referencias a componentes
var camera_controller: Node
var current_model: Node3D
var ui_controller: Node

# Estado de controles
var controls_enabled: bool = true
var camera_speed: float = 5.0
var rotation_speed: float = 45.0

# Estado actual
var camera_offset: Vector3 = Vector3.ZERO
var model_rotation: Vector3 = Vector3.ZERO

# Señales
signal camera_moved(new_position: Vector3)
signal model_rotated(new_rotation: Vector3)
signal controls_toggled(enabled: bool)

func _ready():
	print("🎮 Controles de cámara inicializados")
	_setup_input_actions()

func _setup_input_actions():
	var actions_to_create = [
		"camera_left", "camera_right", "camera_up", "camera_down",
		"model_rotate_left", "model_rotate_right", 
		"model_rotate_up", "model_rotate_down",
		"reset_camera", "reset_model"
	]
	
	for action in actions_to_create:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

func setup_references(cam_controller: Node, model: Node3D, ui: Node):
	camera_controller = cam_controller
	current_model = model
	ui_controller = ui
	print("✅ Referencias de controles configuradas")

func _input(event):
	if not controls_enabled:
		return
	
	if event is InputEventKey and event.pressed:
		_handle_key_input(event)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0)

func _process(delta):
	if not controls_enabled:
		return
	
	# Controles continuos de cámara
	var camera_movement = Vector2.ZERO
	
	if Input.is_action_pressed("camera_left"):
		camera_movement.x -= 1
	if Input.is_action_pressed("camera_right"):
		camera_movement.x += 1
	if Input.is_action_pressed("camera_up"):
		camera_movement.y += 1
	if Input.is_action_pressed("camera_down"):
		camera_movement.y -= 1
	
	if camera_movement.length() > 0:
		_move_camera(camera_movement.normalized() * camera_speed * delta)
	
	# Controles de rotación del modelo
	var model_input = Vector2.ZERO
	
	if Input.is_action_pressed("model_rotate_left"):
		model_input.x -= 1
	if Input.is_action_pressed("model_rotate_right"):
		model_input.x += 1
	if Input.is_action_pressed("model_rotate_up"):
		model_input.y -= 1
	if Input.is_action_pressed("model_rotate_down"):
		model_input.y += 1
	
	if model_input.length() > 0:
		_rotate_model(model_input.normalized() * rotation_speed * delta)

func _handle_key_input(event: InputEventKey):
	match event.keycode:
		KEY_R:
			reset_camera()
		KEY_T:
			reset_model()
		KEY_F1:
			toggle_controls()

func _move_camera(movement: Vector2):
	if not camera_controller:
		return
	
	camera_offset += Vector3(movement.x, 0, movement.y)
	emit_signal("camera_moved", camera_offset)

func _zoom_camera(zoom_delta: float):
	if not camera_controller:
		return
	
	if camera_controller.has_method("set_distance"):
		var current_distance = camera_controller.camera_distance
		var new_distance = current_distance + zoom_delta
		new_distance = clamp(new_distance, 3.0, 30.0)
		camera_controller.set_distance(new_distance)
		print("🔍 Zoom: %.1f" % new_distance)

func _rotate_model(rotation_input: Vector2):
	if not current_model:
		return
	
	model_rotation.y += rotation_input.x
	model_rotation.x += rotation_input.y
	model_rotation.x = clamp(model_rotation.x, -80.0, 80.0)
	
	current_model.rotation_degrees = model_rotation
	emit_signal("model_rotated", model_rotation)

func reset_camera():
	camera_offset = Vector3.ZERO
	
	if camera_controller and camera_controller.has_method("reset_to_default"):
		camera_controller.reset_to_default()
	
	print("📷 Cámara reseteada")
	emit_signal("camera_moved", Vector3.ZERO)

func reset_model():
	model_rotation = Vector3.ZERO
	
	if current_model:
		current_model.rotation_degrees = Vector3.ZERO
	
	print("🔄 Modelo reseteado")
	emit_signal("model_rotated", Vector3.ZERO)

func set_model(model: Node3D):
	current_model = model
	reset_model()
	# ✅ CORREGIDO: Evitar operador ternario problemático
	var model_name = "NULL"
	if model:
		model_name = model.name
	print("🎭 Modelo cambiado: %s" % model_name)

func enable_controls():
	controls_enabled = true
	emit_signal("controls_toggled", true)
	print("🎮 Controles habilitados")

func disable_controls():
	controls_enabled = false
	emit_signal("controls_toggled", false)
	print("🚫 Controles deshabilitados")

func toggle_controls():
	if controls_enabled:
		disable_controls()
	else:
		enable_controls()

func set_camera_speed(speed: float):
	camera_speed = clamp(speed, 1.0, 20.0)
	print("⚡ Velocidad cámara: %.1f" % camera_speed)

func set_rotation_speed(speed: float):
	rotation_speed = clamp(speed, 10.0, 180.0)
	print("🔄 Velocidad rotación: %.1f°/s" % rotation_speed)

func apply_rts_preset():
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings({
			"camera_angle": 45.0,
			"camera_height": 12.0,
			"camera_distance": 15.0,
			"orthographic": true
		})
	
	camera_speed = 8.0
	rotation_speed = 60.0
	reset_camera()
	print("🏰 Preset RTS aplicado")

func apply_platform_preset():
	if camera_controller and camera_controller.has_method("set_camera_settings"):
		camera_controller.set_camera_settings({
			"camera_angle": 0.0,
			"camera_height": 5.0,
			"camera_distance": 12.0,
			"orthographic": true
		})
	
	camera_speed = 5.0
	rotation_speed = 30.0
	reset_camera()
	print("🏃 Preset Plataforma aplicado")

func get_control_status() -> Dictionary:
	return {
		"enabled": controls_enabled,
		"camera_offset": camera_offset,
		"model_rotation": model_rotation,
		"camera_speed": camera_speed,
		"rotation_speed": rotation_speed,
		"has_model": current_model != null,
		"has_camera": camera_controller != null
	}
