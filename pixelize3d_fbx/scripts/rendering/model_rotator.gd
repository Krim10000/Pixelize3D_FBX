# scripts/rendering/model_rotator.gd
# Script para controlar la rotación del modelo y establecer orientación Norte relativa
# Input: Modelo 3D cargado
# Output: Modelo orientado según Norte relativo configurado por el usuario

extends Node3D

signal north_changed(new_north_angle: float)
signal model_rotated(rotation_angle: float)

# Estado del modelo
var current_model: Node3D = null
var north_angle: float = 0.0  # Ángulo del Norte relativo en grados
var user_rotation: float = 0.0  # Rotación adicional del usuario

# Variables para control interactivo
var is_rotating_model: bool = false
var mouse_sensitivity: float = 0.5
var rotation_enabled: bool = false

func _ready():
	print("🧭 ModelRotator inicializado")

# === GESTIÓN DEL MODELO ===

func set_model(model: Node3D):
	"""Asignar modelo para controlar su rotación"""
	if current_model and current_model != model:
		var old_name = current_model.name if current_model else "NULL"
		var new_name = model.name if model else "NULL"
		print("🔄 Cambiando modelo: %s -> %s" % [old_name, new_name])
	
	current_model = model
	
	if current_model:
		print("✅ Modelo asignado: %s" % current_model.name)
		# Aplicar rotación actual
		_apply_rotation()
	else:
		print("❌ Modelo removido")

func clear_model():
	"""Limpiar referencia al modelo"""
	current_model = null
	print("🗑️ Modelo limpiado")

# === CONTROL DE ORIENTACIÓN NORTE ===

func set_north_angle(angle: float):
	"""Establecer el ángulo del Norte relativo"""
	north_angle = angle
	_apply_rotation()
	emit_signal("north_changed", north_angle)
	print("🧭 Norte relativo configurado: %.1f°" % north_angle)

func get_north_angle() -> float:
	"""Obtener el ángulo actual del Norte relativo"""
	return north_angle

func reset_north():
	"""Resetear Norte relativo a 0°"""
	set_north_angle(0.0)
	print("🧭 Norte relativo reseteado")

# === ROTACIÓN MANUAL DEL USUARIO ===

func add_user_rotation(delta_angle: float):
	"""Agregar rotación del usuario al modelo"""
	user_rotation += delta_angle
	_apply_rotation()
	emit_signal("model_rotated", user_rotation)
	print("🔄 Rotación usuario: %.1f° (total: %.1f°)" % [delta_angle, user_rotation])

func set_user_rotation(angle: float):
	"""Establecer rotación absoluta del usuario"""
	user_rotation = angle
	_apply_rotation()
	emit_signal("model_rotated", user_rotation)
	print("🔄 Rotación usuario establecida: %.1f°" % user_rotation)

func reset_user_rotation():
	"""Resetear rotación del usuario"""
	user_rotation = 0.0
	_apply_rotation()
	print("🔄 Rotación usuario reseteada")

# === APLICACIÓN DE ROTACIONES ===

func _apply_rotation():
	"""Aplicar la rotación total al modelo"""
	if not current_model:
		return
	
	# Calcular rotación total
	var total_rotation = north_angle + user_rotation
	
	# Aplicar rotación en el eje Y
	current_model.rotation_degrees.y = total_rotation
	
	# Debug ocasional para no saturar consola
	if abs(total_rotation) > 0.1:
		print("↻ Modelo rotado: Norte=%.1f° + Usuario=%.1f° = %.1f°" % [
			north_angle, user_rotation, total_rotation
		])

# === CONTROL INTERACTIVO ===

func enable_rotation_control():
	"""Habilitar control interactivo de rotación del modelo"""
	rotation_enabled = true
	set_process_input(true)
	print("🎮 Control de rotación habilitado")

func disable_rotation_control():
	"""Deshabilitar control interactivo"""
	rotation_enabled = false
	set_process_input(false)
	is_rotating_model = false
	print("🛑 Control de rotación deshabilitado")

func _input(event):
	"""Manejar input para rotación del modelo"""
	if not rotation_enabled or not current_model:
		return
	
	# Usar Ctrl + Click izquierdo para rotar el modelo
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_CTRL):
			is_rotating_model = event.pressed
			var status = "ACTIVA" if is_rotating_model else "INACTIVA"
			print("🎮 Rotación modelo: %s" % status)
	
	elif event is InputEventMouseMotion and is_rotating_model:
		# Rotar modelo horizontalmente
		var delta_rotation = -event.relative.x * mouse_sensitivity
		add_user_rotation(delta_rotation)

# === FUNCIONES DE UTILIDAD ===

func get_total_rotation() -> float:
	"""Obtener rotación total actual"""
	return north_angle + user_rotation

func get_model_forward_direction() -> Vector3:
	"""Obtener dirección frontal actual del modelo"""
	if not current_model:
		return Vector3.FORWARD
	
	return current_model.transform.basis.z

func snap_to_cardinal_direction():
	"""Ajustar a dirección cardinal más cercana (0°, 90°, 180°, 270°)"""
	var current_total = get_total_rotation()
	var snapped_angle = round(current_total / 90.0) * 90.0
	
	# Mantener el norte fijo y ajustar la rotación del usuario
	set_user_rotation(snapped_angle - north_angle)
	
	print("📐 Ajustado a dirección cardinal: %.0f°" % snapped_angle)

func get_rotation_info() -> Dictionary:
	"""Obtener información completa del estado de rotación"""
	var model_name = "None"
	if current_model:
		model_name = current_model.name
	
	return {
		"has_model": current_model != null,
		"model_name": model_name,
		"north_angle": north_angle,
		"user_rotation": user_rotation,
		"total_rotation": get_total_rotation(),
		"rotation_enabled": rotation_enabled,
		"is_rotating": is_rotating_model
	}

func debug_rotation_state():
	"""Imprimir estado de rotación para debugging"""
	print("\n=== MODEL ROTATOR DEBUG ===")
	var info = get_rotation_info()
	for key in info:
		print("  %s: %s" % [key, str(info[key])])
	print("============================\n")

# === PRESETS DE ORIENTACIÓN ===

func set_preset_north(preset_name: String):
	"""Aplicar preset de orientación Norte predefinido"""
	var presets = {
		"game_north": 0.0,    # Norte del juego hacia arriba
		"world_north": 45.0,  # Norte del mundo real
		"iso_front": 315.0,   # Vista frontal isométrica
		"iso_back": 135.0     # Vista trasera isométrica
	}
	
	if presets.has(preset_name):
		set_north_angle(presets[preset_name])
		print("🧭 Preset aplicado: %s = %.1f°" % [preset_name, presets[preset_name]])
	else:
		print("❌ Preset desconocido: %s" % preset_name)
		print("Disponibles: %s" % str(presets.keys()))
