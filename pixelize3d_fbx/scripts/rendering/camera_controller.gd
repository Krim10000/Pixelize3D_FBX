# scripts/rendering/camera_controller.gd
# Script de control de cámara que usa los nodos existentes de la escena
# Input: Referencias a Camera3D y DirectionalLight3D existentes, configuración de cámara
# Output: Control de posición, rotación y zoom de la cámara para visualización óptima

extends Node3D

signal camera_ready()
signal camera_moved()
signal north_indicator_toggled(visible: bool)

# Referencias a nodos existentes (se configuran en _ready)
var camera_3d: Camera3D
var directional_light: DirectionalLight3D
var model_container: Node3D

# NUEVO: Indicador visual de orientación norte
var north_indicator: NorthIndicator = null
var show_north_indicator: bool = false

# Configuración de cámara
@export var camera_angle: float = 45.0  # Ángulo de elevación (0-90°)
@export var camera_distance: float = 5.0  # Distancia al modelo
@export var camera_height: float = 2.0   # Altura sobre el modelo
@export var target_position: Vector3 = Vector3.ZERO
@export var use_orthographic: bool = true
@export var orthographic_size: float = 2.5  # ← AUMENTADO: 3.0 → 15.0

# Nodo pivot para rotaciones
var pivot_node: Node3D

# Variables para control de usuario
var mouse_sensitivity = 0.3
var is_rotating = false
var is_panning = false
var is_zooming = false
var preview_mode_enabled = true
var pan_start_pos: Vector2
#var config_manager = get_node_or_null("/root/ConfigManager")  # ❌ NO EXISTE
var manual_override = false  # ❌ SIEMPRE SERÁ FALSE
var manual_zoom_active: bool = true
var manual_orthographic_size: float = 2.5

# Variable para orientación norte del modelo
var current_north_offset: float = 0.0

func _ready():
	_find_existing_nodes()
	_setup_pivot_system()
	_configure_camera()
	_setup_north_indicator()
	debug_camera_state()
	#print("✅ CameraController con indicador norte inicializado")
	manual_zoom_active = true
	manual_orthographic_size = 2.5
	orthographic_size = 2.5
	
	if camera_3d and use_orthographic:
		camera_3d.size = orthographic_size
func _find_existing_nodes():
	#print("🔍 CameraController: Buscando nodos existentes...")
	
	# Buscar nodos hermanos en el SubViewport
	var parent = get_parent()
	if parent:
		camera_3d = parent.get_node_or_null("Camera3D")
		directional_light = parent.get_node_or_null("DirectionalLight3D")
		model_container = parent.get_node_or_null("ModelContainer")
	
	# Validar nodos encontrados
	if not camera_3d:
		#print("❌ ERROR: No se encontró Camera3D")
		return
	if not directional_light:
		#print("❌ ERROR: No se encontró DirectionalLight3D")
		return
	if not model_container:
		#print("❌ ERROR: No se encontró ModelContainer")
		return
	
	#print("✅ Nodos encontrados:")
	#print("  - Camera3D: %s" % camera_3d.name)
	#print("  - DirectionalLight3D: %s" % directional_light.name)
	#print("  - ModelContainer: %s" % model_container.name)

func _setup_pivot_system():
	"""Crear sistema de pivot para rotaciones suaves"""
	pivot_node = Node3D.new()
	pivot_node.name = "CameraPivot"
	add_child(pivot_node)
	
	#print("✅ Sistema de pivot creado")

func _configure_camera():
	"""Configurar la cámara existente con nuestros parámetros"""
	if not camera_3d:
		return
	
	# Configurar proyección
	if use_orthographic:
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.size = orthographic_size
	else:
		camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera_3d.fov = 35.0
	
	# Configurar distancias de renderizado
	camera_3d.near = 0.1
	camera_3d.far = 100.0
	
	# Posición inicial
	update_camera_position()
	
	#print("✅ Cámara configurada: %s, size=%.2f" % [
		#"Ortográfica" if use_orthographic else "Perspectiva",
		#orthographic_size if use_orthographic else camera_3d.fov
	#])

# NUEVA: Configurar el indicador visual de norte
func _setup_north_indicator():
	"""Configurar el indicador visual de norte"""
	if not north_indicator:
		# Cargar la clase del indicador
		var NorthIndicatorClass = load("res://scripts/orientation/north_indicator.gd")
		north_indicator = NorthIndicatorClass.new()
		north_indicator.name = "NorthIndicator"
		
		# Añadir al scene tree (mismo nivel que la cámara)
		add_child(north_indicator)
		
		# Conectar señales
		north_indicator.indicator_clicked.connect(_on_north_indicator_clicked)
		north_indicator.north_changed.connect(_on_indicator_north_changed)
		
		#print("🧭 Indicador de norte creado y conectado")

# NUEVAS: Callbacks del indicador
func _on_north_indicator_clicked():
	"""Callback cuando se hace clic en el indicador"""
	#print("🖱️ Indicador de norte clickeado")
	# Aquí podrías abrir un menú de ajuste rápido o similar

func _on_indicator_north_changed(new_angle: float):
	"""Callback cuando el indicador cambia la orientación"""
	current_north_offset = new_angle
	set_rotation_angle(new_angle)
	#print("🧭 Norte cambiado desde indicador: %.1f°" % new_angle)

func update_camera_position():
	"""Actualizar posición de la cámara basada en parámetros actuales"""
	if not camera_3d:
		return
	
	# Calcular posición relativa
	var rad_angle = deg_to_rad(camera_angle)
	var cam_x = 0
	var cam_y = sin(rad_angle) * camera_distance + camera_height
	var cam_z = cos(rad_angle) * camera_distance
	
	# Aplicar rotación del pivot
	var pivot_transform = Transform3D.IDENTITY.rotated(Vector3.UP, deg_to_rad(pivot_node.rotation_degrees.y))
	var final_position = pivot_transform * Vector3(cam_x, cam_y, cam_z)
	
	# Posicionar cámara
	camera_3d.position = target_position + final_position
	camera_3d.look_at(target_position, Vector3.UP)
	
	emit_signal("camera_moved")


func set_rotation_angle(degrees: float):
	"""Rotar la cámara a un ángulo específico"""
	pivot_node.rotation_degrees.y = degrees
	update_camera_position()
	
	# NUEVO: Sincronizar con indicador visual
	if north_indicator:
		north_indicator.set_north_angle(current_north_offset)
	
	if abs(degrees - current_north_offset) > 0.1:
		#print("🧭 Cámara rotada a: %.1f° (norte: %.1f°)" % [degrees, current_north_offset])
		pass
func set_distance(new_distance: float):
	"""Ajustar distancia de la cámara al modelo"""
	camera_distance = clamp(new_distance, 1.0, 50.0)
	update_camera_position()
	#print("📏 Distancia ajustada: %.2f" % camera_distance)

func set_angle(new_angle: float):
	"""Ajustar ángulo de elevación de la cámara"""
	camera_angle = clamp(new_angle, 15.0, 80.0)
	update_camera_position()
	#print("📐 Ángulo ajustado: %.1f°" % camera_angle)

func set_height(new_height: float):
	"""Ajustar altura de la cámara"""
	camera_height = clamp(new_height, -5.0, 10.0)
	update_camera_position()
	#print("📏 Altura ajustada: %.2f" % camera_height)

# ← NUEVA: Función para cambiar zoom manualmente
func set_orthographic_size(new_size: float):
	"""Cambiar tamaño ortográfico manualmente"""
	if use_orthographic and camera_3d:
		orthographic_size = clamp(new_size, 1.0, 50.0)
		camera_3d.size = orthographic_size
		#print("🔍 Zoom ajustado: %.2f" % orthographic_size)

# === NUEVAS FUNCIONES DEL INDICADOR NORTE ===

func toggle_north_indicator():
	"""Alternar visibilidad del indicador de norte"""
	show_north_indicator = !show_north_indicator
	
	if north_indicator:
		if show_north_indicator:
			north_indicator.show_indicator()
		else:
			north_indicator.hide_indicator()
	
	emit_signal("north_indicator_toggled", show_north_indicator)
	#print("🧭 Indicador de norte: %s" % ("MOSTRADO" if show_north_indicator else "OCULTO"))

func set_north_indicator_visible(visible_n: bool):
	"""Establecer visibilidad del indicador de norte"""
	show_north_indicator = visible_n
	
	if north_indicator:
		if visible_n:
			north_indicator.show_indicator()
		else:
			north_indicator.hide_indicator()
	
	emit_signal("north_indicator_toggled", show_north_indicator)

func is_north_indicator_visible() -> bool:
	"""Verificar si el indicador está visible"""
	return show_north_indicator

# === FUNCIONES DE ZOOM ===

func zoom_in():
	"""Acercar la cámara"""
	if use_orthographic:
		orthographic_size *= 0.9
		orthographic_size = max(orthographic_size, 2.0)  # ← Mínimo más seguro
		camera_3d.size = orthographic_size
		#print("🔍 Zoom in: size=%.2f" % orthographic_size)
	else:
		camera_distance *= 0.9
		camera_distance = max(camera_distance, 1.0)
		update_camera_position()
		#print("🔍 Zoom in: distance=%.2f" % camera_distance)

func zoom_out():
	"""Alejar la cámara"""
	if use_orthographic:
		orthographic_size *= 1.1
		orthographic_size = min(orthographic_size, 50.0)
		camera_3d.size = orthographic_size
		#print("🔍 Zoom out: size=%.2f" % orthographic_size)
	else:
		camera_distance *= 1.1
		camera_distance = min(camera_distance, 50.0)
		update_camera_position()
		#print("🔍 Zoom out: distance=%.2f" % camera_distance)

# === MODO PREVIEW INTERACTIVO ===

func enable_preview_mode():
	"""Habilitar controles interactivos de cámara"""
	#print("🎬 HABILITANDO PREVIEW MODE")
	preview_mode_enabled = true
	set_process_input(true)
	
	# Aplicar orientación norte si está configurada
	if current_north_offset != 0.0:
		set_rotation_angle(current_north_offset)
	
	#print("✅ Preview mode habilitado")

func disable_preview_mode():
	"""Deshabilitar controles interactivos"""
	#print("🛑 DESHABILITANDO PREVIEW MODE")
	preview_mode_enabled = false
	set_process_input(false)
	is_rotating = false
	is_panning = false

func get_preview_mode_enabled() -> bool:
	"""Verificar si preview mode está habilitado"""
	return preview_mode_enabled

func _input(event):
	"""Manejar input del usuario en preview mode"""
	if not preview_mode_enabled:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
		
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_pos = event.position
			else:
				is_panning = false
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	
	elif event is InputEventMouseMotion:
		if is_rotating:
			# Rotación horizontal
			pivot_node.rotation_degrees.y -= event.relative.x * mouse_sensitivity
			
			# Rotación vertical (ángulo de elevación)
			var new_angle = camera_angle - event.relative.y * mouse_sensitivity * 0.5
			camera_angle = clamp(new_angle, 15.0, 80.0)
			
			update_camera_position()
		
		elif is_panning:
			# Pan de cámara
			var delta = (event.position - pan_start_pos) * 0.01
			target_position.x -= delta.x
			target_position.z += delta.y
			
			update_camera_position()
			pan_start_pos = event.position

# === FUNCIONES DE UTILIDAD ===

func get_camera() -> Camera3D:
	"""Obtener referencia a la cámara"""
	return camera_3d

func reset_to_north():
	"""Resetear a orientación norte"""
	#print("🧭 Reseteando a orientación norte: %.1f°" % current_north_offset)
	set_rotation_angle(current_north_offset)

func reset_to_default():
	"""Resetear cámara a configuración por defecto"""
	camera_angle = 45.0
	camera_height = 2.0
	camera_distance = 5.0
	target_position = Vector3.ZERO
	orthographic_size = 15.0  # ← Default más seguro
	
	if camera_3d:
		camera_3d.size = orthographic_size
	
	pivot_node.rotation_degrees = Vector3.ZERO
	update_camera_position()
	#print("🔄 Cámara reseteada a valores por defecto")

func get_relative_angle() -> float:
	"""Obtener ángulo actual relativo al norte"""
	return pivot_node.rotation_degrees.y - current_north_offset

func get_current_rotation() -> float:
	"""Obtener rotación actual del pivot"""
	return pivot_node.rotation_degrees.y

func get_target_position() -> Vector3:
	"""Obtener posición objetivo de la cámara"""
	return target_position

func get_view_info() -> Dictionary:
	"""Obtener información completa del estado de la cámara"""
	return {
		"camera_position": camera_3d.global_position if camera_3d else Vector3.ZERO,
		"camera_rotation": camera_3d.global_rotation_degrees if camera_3d else Vector3.ZERO,
		"pivot_rotation": pivot_node.rotation_degrees.y,
		"north_offset": current_north_offset,
		"relative_angle": get_relative_angle(),
		"target": target_position,
		"distance": camera_distance,
		"angle": camera_angle,
		"height": camera_height,
		"orthographic_size": camera_3d.size if camera_3d and use_orthographic else 0.0,
		"preview_mode": preview_mode_enabled,
		# NUEVO: información del indicador
		"north_indicator_visible": show_north_indicator,
		"north_indicator_info": north_indicator.get_visual_info() if north_indicator else {}
	}

func debug_camera_state():
	"""Imprimir estado actual de la cámara para debugging"""
	#print("\n=== CAMERA CONTROLLER DEBUG CON INDICADOR ===")
	var info = get_view_info()
	for key in info:
		print("  %s: %s" % [key, str(info[key])])
	
	# Debug específico del indicador
	if north_indicator:
		north_indicator.debug_indicator_state()
	
	print("============================================\n")


func set_camera_settings(settings: Dictionary):
	"""Aplicar configuración de cámara desde diccionario - CORREGIDO"""
	#print("--- APLICANDO CONFIGURACIÓN DE CÁMARA CON INDICADOR ---")
	
	if settings.has("camera_angle"):
		camera_angle = settings.camera_angle
		#print("  Ángulo: %.1f°" % camera_angle)
	
	if settings.has("camera_height"):
		camera_height = settings.camera_height
		#print("  Altura: %.1f" % camera_height)
	
	if settings.has("camera_distance"):
		camera_distance = settings.camera_distance
		#print("  Distancia: %.1f" % camera_distance)
	
	if settings.has("target_position"):
		target_position = settings.target_position
		#print("  Target: %s" % str(target_position))
	
	if settings.has("north_offset"):
		current_north_offset = settings.north_offset
		#print("  Norte relativo: %.1f°" % current_north_offset)
		
		# NUEVO: Sincronizar indicador
		if north_indicator:
			north_indicator.set_north_angle(current_north_offset)
		
		# Aplicar orientación si estamos en preview
		if preview_mode_enabled:
			set_rotation_angle(current_north_offset)
	
	if settings.has("orthographic_size"):
		orthographic_size = settings.orthographic_size
		if camera_3d and use_orthographic:
			camera_3d.size = orthographic_size
		#print("  Tamaño ortográfico: %.1f" % orthographic_size)
	
	# ✅ CORRECCIÓN: Capturar configuración manual CORRECTAMENTE
	if settings.has("manual_zoom_override"):
		manual_zoom_active = settings.manual_zoom_override
		
		if settings.has("fixed_orthographic_size"):
			manual_orthographic_size = settings.fixed_orthographic_size
		elif settings.has("capture_area_size"):
			# ✅ NUEVO: También aceptar capture_area_size directamente
			manual_orthographic_size = settings.capture_area_size
		elif settings.has("orthographic_size"):
			# ✅ FALLBACK: Usar orthographic_size si está disponible
			manual_orthographic_size = settings.orthographic_size
		
		if manual_zoom_active and use_orthographic:
			orthographic_size = manual_orthographic_size
			if camera_3d:
				camera_3d.size = orthographic_size
			#print("🔧 Zoom manual activado: %.1f" % orthographic_size)
	
	# ✅ NUEVO: También capturar si viene capture_area_size sin manual_zoom_override
	elif settings.has("capture_area_size"):
		manual_zoom_active = true
		manual_orthographic_size = settings.capture_area_size
		
		if use_orthographic:
			orthographic_size = manual_orthographic_size
			if camera_3d:
				camera_3d.size = orthographic_size
			#print("🔧 Área de captura aplicada como zoom manual: %.1f" % orthographic_size)
	
	# NUEVO: Manejar visibilidad del indicador
	if settings.has("show_north_indicator"):
		set_north_indicator_visible(settings.show_north_indicator)
	
	update_camera_position()
	#print("✅ Configuración aplicada con indicador sincronizado")



func setup_for_model(model_bounds: AABB):
	"""Configurar cámara para encuadrar un modelo específico - RESPETANDO CONFIGURACIÓN MANUAL"""
	#print("--- CONFIGURANDO CÁMARA PARA MODELO ---")
	#print("Bounds del modelo: %s" % str(model_bounds))
	
	# Centrar objetivo en el modelo
	target_position = model_bounds.get_center()
	#print("Target position: %s" % str(target_position))
	
	# Calcular distancia apropiada SOLO si no hay override manual
	var model_size = model_bounds.get_longest_axis_size()
	
	# ✅ CRÍTICO: Solo actualizar camera_distance si no hay configuración manual
	if not manual_zoom_active:
		camera_distance = max(model_size * 1.5, 3.0)  # Mínimo 3 unidades
		camera_height = model_size * 0.3  # Altura proporcional
	
	#print("Model size: %.2f, Distance: %.2f, Height: %.2f" % [model_size, camera_distance, camera_height])
	
	# ✅ CORRECCIÓN CRÍTICA: Respetar configuración manual
	if use_orthographic:
		if manual_zoom_active:
			# ✅ USAR CONFIGURACIÓN MANUAL
			orthographic_size = manual_orthographic_size
			if camera_3d:
				camera_3d.size = orthographic_size
			#print("🔧 Usando tamaño ortográfico MANUAL: %.2f" % orthographic_size)
		else:
			# ✅ SOLO USAR AUTO SI NO HAY CONFIGURACIÓN MANUAL
			orthographic_size = max(model_size * 1.8, 8.0)  # 80% padding mínimo + mínimo absoluto
			if camera_3d:
				camera_3d.size = orthographic_size
			#print("📏 Tamaño ortográfico AUTO: %.2f (model_size: %.2f)" % [orthographic_size, model_size])
	
	# NUEVO: Configurar indicador de norte para el modelo
	if north_indicator:
		north_indicator.setup_for_model(model_bounds)
		north_indicator.set_north_angle(current_north_offset)
		
		# Mostrar indicador si está habilitado
		if show_north_indicator:
			north_indicator.show_indicator()
		else:
			north_indicator.hide_indicator()
	
	update_camera_position()
	#print("✅ Cámara e indicador configurados para modelo")
	emit_signal("camera_ready")

# ========================================================================
# ✅ FUNCIÓN DE DEBUG: Verificar estado de configuración manual
# ========================================================================

func debug_manual_zoom_state():
	"""Debug del estado de configuración manual"""
	#print("\n🔍 === DEBUG CONFIGURACIÓN MANUAL ===")
	#print("manual_zoom_active: %s" % manual_zoom_active)
	#print("manual_orthographic_size: %.2f" % manual_orthographic_size)
	#print("orthographic_size actual: %.2f" % orthographic_size)
	#print("camera_3d.size: %.2f" % (camera_3d.size if camera_3d else 0.0))
	#print("use_orthographic: %s" % use_orthographic)
	#print("=====================================\n")

# ========================================================================
# ✅ FUNCIÓN AUXILIAR: Forzar aplicación de zoom manual
# ========================================================================

func force_apply_manual_zoom(size: float):
	"""Forzar aplicación de zoom manual (para debug/testing)"""
	#print("🔧 Forzando zoom manual: %.2f" % size)
	
	manual_zoom_active = true
	manual_orthographic_size = size
	orthographic_size = size
	
	if camera_3d and use_orthographic:
		camera_3d.size = size
	
	update_camera_position()
	#print("✅ Zoom manual forzado aplicado")

# ========================================================================
# ✅ FUNCIÓN AUXILIAR: Resetear configuración manual
# ========================================================================

func reset_manual_zoom():
	"""Resetear configuración manual y volver al modo automático"""
	#print("🔄 Reseteando configuración manual")
	
	manual_zoom_active = false
	manual_orthographic_size = 15.0
	
	# Re-aplicar configuración automática si hay un modelo
	# (esto requerirá que se llame setup_for_model nuevamente)
	#print("✅ Configuración manual reseteada - modo automático activado")

# ========================================================================
# ✅ FUNCIONES PÚBLICAS PARA VERIFICACIÓN
# ========================================================================

func is_manual_zoom_active() -> bool:
	"""Verificar si el zoom manual está activo"""
	return manual_zoom_active

func get_manual_zoom_size() -> float:
	"""Obtener el tamaño de zoom manual actual"""
	return manual_orthographic_size

func get_current_zoom_info() -> Dictionary:
	"""Obtener información completa del zoom actual"""
	return {
		"manual_active": manual_zoom_active,
		"manual_size": manual_orthographic_size,
		"current_orthographic_size": orthographic_size,
		"camera_size": camera_3d.size if camera_3d else 0.0,
		"use_orthographic": use_orthographic
	}
