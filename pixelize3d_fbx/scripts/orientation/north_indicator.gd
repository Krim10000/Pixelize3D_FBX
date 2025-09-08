# scripts/orientation/north_indicator.gd
# Indicador visual para mostrar la orientación norte del modelo
# Input: Bounds del modelo, orientación norte actual
# Output: Flecha 3D visual mostrando dirección norte

extends Node3D
class_name NorthIndicator

signal indicator_clicked()
signal north_changed(new_angle: float)

# Referencias a componentes visuales
var arrow_mesh: MeshInstance3D
var compass_ring: MeshInstance3D
var north_label: Label3D

# Estado
var current_north_angle: float = 0.0
var model_bounds: AABB = AABB()
var is_indicator_visible: bool = false
var scale_factor: float = 1.0

# Configuración visual
const ARROW_COLOR = Color.RED
const RING_COLOR = Color(0.5, 0.5, 0.5, 0.3)
const ARROW_LENGTH = 2.0
const RING_RADIUS = 1.5

func _ready():
	#print("🧭 NorthIndicator inicializado")
	#_create_visual_components()
	set_visible(false)

func _create_visual_components():
	"""Crear los componentes visuales del indicador"""
	_create_arrow()
	_create_compass_ring()
	_create_north_label()
	#print("✅ Componentes visuales del indicador creados")

func _create_arrow():
	"""Crear la flecha que apunta al norte"""
	arrow_mesh = MeshInstance3D.new()
	arrow_mesh.name = "NorthArrow"
	add_child(arrow_mesh)
	
	# Crear mesh de flecha personalizada
	var arrow_geometry = _create_arrow_mesh()
	arrow_mesh.mesh = arrow_geometry
	
	# Material rojo brillante
	var material = StandardMaterial3D.new()
	material.albedo_color = ARROW_COLOR
	material.emission = Color.RED * 0.3  # Brillo sutil
	material.no_depth_test = true  # Siempre visible
	arrow_mesh.set_surface_override_material(0, material)
	
	#print("🔴 Flecha norte creada")

func _create_compass_ring():
	"""Crear anillo de brújula sutil"""
	compass_ring = MeshInstance3D.new()
	compass_ring.name = "CompassRing"
	add_child(compass_ring)
	
	# Crear anillo
	var ring_mesh = _create_ring_mesh()
	compass_ring.mesh = ring_mesh
	
	# Material semitransparente
	var material = StandardMaterial3D.new()
	material.albedo_color = RING_COLOR
	material.flags_transparent = true
	material.no_depth_test = true
	compass_ring.set_surface_override_material(0, material)
	
	#print("⭕ Anillo de brújula creado")

func _create_north_label():
	"""Crear etiqueta 'N' para el norte"""
	north_label = Label3D.new()
	north_label.name = "NorthLabel"
	north_label.text = "N"
	north_label.font_size = 32
	north_label.modulate = Color.WHITE
	north_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(north_label)
	
	#print("📝 Etiqueta norte creada")

func _create_arrow_mesh() -> ArrayMesh:
	"""Crear mesh personalizado de flecha"""
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Flecha apuntando hacia +Z (norte)
	var arrow_tip = Vector3(0, 0, ARROW_LENGTH)
	var arrow_base_left = Vector3(-0.2, 0, ARROW_LENGTH * 0.7)
	var arrow_base_right = Vector3(0.2, 0, ARROW_LENGTH * 0.7)
	var arrow_tail = Vector3(0, 0, 0)
	
	# Vértices de la flecha
	vertices.append(arrow_tip)     # 0
	vertices.append(arrow_base_left)  # 1
	vertices.append(arrow_base_right) # 2
	vertices.append(arrow_tail)    # 3
	
	# Triángulos de la flecha
	indices.append_array([0, 1, 2])  # Punta
	indices.append_array([1, 3, 2])  # Base
	
	# Crear mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

func _create_ring_mesh() -> ArrayMesh:
	"""Crear mesh de anillo para la brújula"""
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var segments = 32
	var outer_radius = RING_RADIUS
	var inner_radius = RING_RADIUS * 0.9
	
	# Generar vértices del anillo
	for i in range(segments):
		var angle = (float(i) / float(segments)) * TAU
		
		# Vértice exterior
		vertices.append(Vector3(
			cos(angle) * outer_radius,
			0,
			sin(angle) * outer_radius
		))
		
		# Vértice interior
		vertices.append(Vector3(
			cos(angle) * inner_radius,
			0,
			sin(angle) * inner_radius
		))
	
	# Generar índices para triángulos
	for i in range(segments):
		var next_i = (i + 1) % segments
		
		var outer_current = i * 2
		var inner_current = i * 2 + 1
		var outer_next = next_i * 2
		var inner_next = next_i * 2 + 1
		
		# Dos triángulos por segmento
		indices.append_array([outer_current, inner_current, outer_next])
		indices.append_array([inner_current, inner_next, outer_next])
	
	# Crear mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh

# === FUNCIONES PRINCIPALES ===

func setup_for_model(bounds: AABB):
	"""Configurar indicador para un modelo específico"""
	model_bounds = bounds
	
	# Posicionar indicador en el centro superior del modelo
	var center = bounds.get_center()
	var height = bounds.size.y
	position = center + Vector3(0, height * 0.6, 0)
	
	# Calcular escala basada en el tamaño del modelo
	var model_size = bounds.get_longest_axis_size()
	scale_factor = max(model_size * 0.3, 0.5)  # Mínimo 0.5, máximo proporcional
	scale = Vector3.ONE * scale_factor
	
	#print("🧭 Indicador configurado - Centro: %s, Escala: %.2f" % [str(center), scale_factor])

func set_north_angle(angle_degrees: float):
	"""Establecer la orientación norte"""
	current_north_angle = angle_degrees
	
	# Rotar toda la brújula para que la flecha apunte al norte configurado
	rotation_degrees.y = -angle_degrees  # Negativo porque rotamos el indicador, no el modelo
	
	# Actualizar posición de la etiqueta
	if north_label:
		var label_distance = RING_RADIUS * scale_factor * 1.2
		var rad_angle = deg_to_rad(angle_degrees)
		north_label.position = Vector3(
			sin(rad_angle) * label_distance,
			0.1,
			cos(rad_angle) * label_distance
		)
	
	#print("🧭 Norte actualizado: %.1f°" % angle_degrees)

func show_indicator():
	"""Mostrar el indicador"""
	set_visible(true)
	is_indicator_visible = true
	#print("👁️ Indicador norte mostrado")

func hide_indicator():
	"""Ocultar el indicador"""
	set_visible(false)
	is_indicator_visible = false
	#print("🙈 Indicador norte oculto")

func toggle_indicator():
	"""Alternar visibilidad del indicador"""
	if is_indicator_visible:
		hide_indicator()
	else:
		show_indicator()

# === INTERACTIVIDAD ===

func _input(event):
	"""Manejar clics en el indicador para ajuste manual"""
	if not is_indicator_visible or not event is InputEventMouseButton:
		return
	
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Aquí podrías implementar arrastrar para rotar
		# Por ahora solo emitir señal de clic
		emit_signal("indicator_clicked")
		#print("🖱️ Indicador clickeado")

# === UTILIDADES ===

func get_visual_info() -> Dictionary:
	"""Obtener información del estado visual"""
	return {
		"visible": is_indicator_visible,
		"north_angle": current_north_angle,
		"position": position,
		"scale_factor": scale_factor,
		"model_bounds": model_bounds
	}

func debug_indicator_state():
	"""Debug del estado del indicador"""
	#print("\n=== NORTH INDICATOR DEBUG ===")
	var _info = get_visual_info()
	#for key in info:
		#print("  %s: %s" % [key, str(info[key])])
	#print("==============================\n")

# === FUNCIONES DE CONFIGURACIÓN ===

func set_arrow_color(color: Color):
	"""Cambiar color de la flecha"""
	if arrow_mesh and arrow_mesh.get_surface_override_material(0):
		var material = arrow_mesh.get_surface_override_material(0)
		material.albedo_color = color
		material.emission = color * 0.3

func set_indicator_size(size_multiplier: float):
	"""Ajustar tamaño del indicador"""
	scale_factor = size_multiplier
	scale = Vector3.ONE * scale_factor
	#print("📏 Tamaño del indicador ajustado: %.2f" % size_multiplier)
