# scripts/viewer/ui/model_preview_panel.gd
# Panel MEJORADO con métodos completos para control de animaciones
# Input: Modelo 3D con AnimationPlayer
# Output: Vista previa interactiva con control total

extends VBoxContainer

# Señales
signal bounds_calculated(bounds: AABB)
signal animation_started(animation_name: String)
signal animation_stopped()
signal preview_ready()

# Referencias a componentes
@onready var viewport_container = $ViewportContainer
@onready var viewport = $ViewportContainer/SubViewport
@onready var camera = $ViewportContainer/SubViewport/Camera3D
@onready var camera_controller = $ViewportContainer/SubViewport/CameraController
@onready var model_container = $ViewportContainer/SubViewport/ModelContainer
#@onready var directional_light = $ViewportContainer/SubViewport/DirectionalLight3D
@onready var directional_light = find_child("DirectionalLight3D", true, false)
@onready var model_rotator = find_child("ModelRotator")

# UI elements
var status_label: Label
var controls_help_label: Label

# Estado interno
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var current_bounds: AABB = AABB()
var preview_active: bool = false

# ✅ NUEVO: Estado de animación
var is_animation_playing: bool = false
var current_animation_name: String = ""
var capture_area_indicator: Control
var orientation_overlay: Control
var orientation_cross: Control


func _ready():
	print("🎬 ModelPreviewPanel MEJORADO inicializado")
	_setup_ui()
	_connect_signals()
	print("oooooooooooooooooooooooo camera")
	print(camera)
	
	# Configurar viewport
	if viewport:
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _setup_ui():
	"""Configurar elementos de UI básicos"""
	if not status_label:
		status_label = Label.new()
		add_child(status_label)
	
	if not controls_help_label:
		controls_help_label = Label.new()
		add_child(controls_help_label)
	
	_create_orientation_overlay()
	_create_capture_area_indicator()
	status_label.text = "Esperando modelo..."
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	controls_help_label.text = "CONTROLES: Click+Arrastrar=Rotar | Rueda=Zoom | Shift+Click=Panear"
	controls_help_label.add_theme_font_size_override("font_size", 9)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false

func _create_capture_area_indicator():
	"""Crear indicador visual del área de captura"""
	if not viewport_container:
		return
	
	# Crear overlay para el indicador
	capture_area_indicator = Control.new()
	capture_area_indicator.name = "CaptureAreaIndicator"
	capture_area_indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capture_area_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.add_child(capture_area_indicator)
	
	# Configurar para dibujar el borde
	capture_area_indicator.draw.connect(_draw_capture_area)
	
	print("✅ Indicador de área de captura creado")

func _draw_capture_area():
	"""Dibujar borde del área de captura"""
	if not viewport or not capture_area_indicator:
		return
	
	var viewport_size = viewport_container.size
	var capture_size = min(viewport_size.x, viewport_size.y)
	
	# Calcular área cuadrada centrada
	var offset_x = (viewport_size.x - capture_size) / 2.0
	print("viewport_size.x ")
	print(viewport_size.x )
	print("capture_size")
	print(capture_size)
	print("offset_x")
	print(offset_x)
	var offset_y = (viewport_size.y - capture_size) / 2.0
	print("offset_y")
	print(offset_y)
#	var rect = Rect2(offset_x, offset_y, capture_size, capture_size)
	var rect = Rect2(0, offset_y, capture_size, capture_size)
	
	# Dibujar borde del área de captura
	var border_color = Color(1.0, 1.0, 0.0, 0.8)  # Amarillo semi-transparente
	var border_width = 2.0
	
	# Dibujar marco
	capture_area_indicator.draw_rect(rect, border_color, false, border_width)
	
	# Dibujar esquinas más visibles
	var corner_size = 20.0
	var corner_color = Color(1.0, 0.5, 0.0, 1.0)  # Naranja
	
	# Esquina superior izquierda
	capture_area_indicator.draw_line(
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + corner_size, rect.position.y),
		corner_color, 3.0
	)
	capture_area_indicator.draw_line(
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x, rect.position.y + corner_size),
		corner_color, 3.0
	)
	
	# Esquina superior derecha
	capture_area_indicator.draw_line(
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x - corner_size, rect.position.y),
		corner_color, 3.0
	)
	capture_area_indicator.draw_line(
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + corner_size),
		corner_color, 3.0
	)
	
	# Esquina inferior izquierda
	capture_area_indicator.draw_line(
		Vector2(rect.position.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + corner_size, rect.position.y + rect.size.y),
		corner_color, 3.0
	)
	capture_area_indicator.draw_line(
		Vector2(rect.position.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x, rect.position.y + rect.size.y - corner_size),
		corner_color, 3.0
	)
	
	# Esquina inferior derecha
	capture_area_indicator.draw_line(
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x - corner_size, rect.position.y + rect.size.y),
		corner_color, 3.0
	)
	capture_area_indicator.draw_line(
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - corner_size),
		corner_color, 3.0
	)

func update_capture_area_indicator():
	"""Actualizar indicador cuando cambie la configuración"""
	if capture_area_indicator:
		capture_area_indicator.queue_redraw()




func _connect_signals():
	"""Conectar señales entre componentes"""
	if camera_controller and camera_controller.has_signal("camera_ready"):
		camera_controller.connect("camera_ready", _on_camera_ready)
	
	if model_rotator and model_rotator.has_signal("north_changed"):
		model_rotator.connect("north_changed", _on_north_changed)

# === GESTIÓN DEL MODELO ===

func set_model(model: Node3D):
	"""✅ MEJORADO: Configurar modelo para preview"""
	print("🎬 Configurando modelo para preview: %s" % model.name)
	
	if not model_container:
		print("❌ model_container no disponible")
		return
	
	# Limpiar modelo anterior
	_clear_current_model_safe()
	
	if not model:
		status_label.text = "No hay modelo cargado"
		controls_help_label.visible = false
		return
	
	# Duplicar modelo para preview
	current_model = model.duplicate()
	current_model.name = "Preview_" + model.name
	model_container.add_child(current_model)
	
	# Buscar AnimationPlayer
	animation_player = _find_animation_player(current_model)
	
	if capture_area_indicator:
		capture_area_indicator.visible = true
		update_capture_area_indicator()
	
	
	if animation_player:
		print("✅ AnimationPlayer encontrado con %d animaciones" % animation_player.get_animation_list().size())
		_setup_animation_loops()
		
		# Conectar señales del AnimationPlayer
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		print("⚠️ No se encontró AnimationPlayer")
	
	# Calcular bounds
	current_bounds = _calculate_model_bounds_safe(current_model)
	emit_signal("bounds_calculated", current_bounds)
	
	# Configurar cámara
	if camera_controller and camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(current_bounds)
	
	# Actualizar UI
	status_label.text = "Modelo: " + model.name
	controls_help_label.visible = true
	#preview_active = true
	
	emit_signal("preview_ready")

	show_orientation_cross()
	
	print("✅ Preview configurado completamente con cruz de orientación")


# === CONTROL DE ANIMACIONES ===

func play_animation(animation_name: String):
	"""✅ NUEVO: Reproducir animación específica"""
	print("▶️ Reproduciendo animación: %s" % animation_name)
	
	if not animation_player:
		print("❌ No hay AnimationPlayer")
		return
	
	# Limpiar nombre si viene con extensión
	var clean_name = animation_name.get_basename()
	
	# Buscar la animación con diferentes variantes
	var found_animation = ""
	for anim in animation_player.get_animation_list():
		if anim == animation_name or anim == clean_name or clean_name in anim:
			found_animation = anim
			break
	
	if found_animation == "":
		print("❌ Animación no encontrada: %s" % animation_name)
		status_label.text = "Error: Animación no encontrada"
		return
	
	# Reproducir
	animation_player.play(found_animation)
	is_animation_playing = true
	current_animation_name = found_animation
	
	status_label.text = "▶️ " + _get_display_name(found_animation)
	emit_signal("animation_started", found_animation)

func pause_animation():
	"""✅ NUEVO: Pausar animación actual"""
	print("⏸️ Pausando animación")
	
	if not animation_player or not is_animation_playing:
		return
	
	animation_player.pause()
	is_animation_playing = false
	status_label.text = "⏸️ " + _get_display_name(current_animation_name)

func resume_animation():
	"""✅ NUEVO: Reanudar animación pausada"""
	print("▶️ Reanudando animación")
	
	if not animation_player or is_animation_playing:
		return
	
	animation_player.play()
	is_animation_playing = true
	status_label.text = "▶️ " + _get_display_name(current_animation_name)

func stop_animation():
	"""✅ NUEVO: Detener animación completamente"""
	print("⏹️ Deteniendo animación")
	
	if not animation_player:
		return
	
	animation_player.stop()
	is_animation_playing = false
	current_animation_name = ""
	
	if current_model:
		status_label.text = "Modelo: " + current_model.name
	else:
		status_label.text = "Listo"
	
	emit_signal("animation_stopped")

func change_animation_speed(speed: float):
	"""✅ NUEVO: Cambiar velocidad de reproducción"""
	if animation_player:
		animation_player.speed_scale = speed
		print("🎬 Velocidad de animación: %.1fx" % speed)

# === MANEJO DE EVENTOS ===

func _on_animation_finished(anim_name: String):
	"""Callback cuando termina una animación"""
	print("🏁 Animación terminada: %s" % anim_name)
	
	# Con loops infinitos, esto raramente se llamará
	# pero es útil para animaciones sin loop
	if is_animation_playing and animation_player:
		# Reiniciar si está en modo loop
		animation_player.play(anim_name)

func _on_camera_ready():
	"""Callback cuando la cámara está lista - CORREGIDO"""
	#print("📷 Cámara lista")
	# NO llamar a ninguna función de configuración de cámara aquí
	# Eso causaría recursión infinita
	
	# La cámara ya fue configurada cuando se emitió esta señal
	# Solo hacer tareas que no involucren reconfigurar la cámara:
	
	# Actualizar UI
	if preview_active:
		controls_help_label.visible = true
		status_label.text = "Vista previa activa"
		
func _on_north_changed(new_north: float):
	"""Callback cuando cambia la orientación norte"""
	#print("🧭 Norte actualizado: %.1f°" % new_north)

# === UTILIDADES ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

func _setup_animation_loops():
	"""Configurar loops infinitos para todas las animaciones"""
	if not animation_player:
		return
	
	var anim_list = animation_player.get_animation_list()
	for anim_name in anim_list:
		if animation_player.has_animation(anim_name):
			var anim_lib = animation_player.get_animation_library("")
			if anim_lib and anim_lib.has_animation(anim_name):
				var animation = anim_lib.get_animation(anim_name)
				animation.loop_mode = Animation.LOOP_LINEAR
	
	#print("🔄 Loops configurados para %d animaciones" % anim_list.size())

func _clear_current_model_safe():
	"""Limpiar modelo actual de forma segura"""
	if current_model:
		if animation_player:
			animation_player.stop()
			if animation_player.animation_finished.is_connected(_on_animation_finished):
				animation_player.animation_finished.disconnect(_on_animation_finished)
		
		current_model.queue_free()
		current_model = null
		animation_player = null
		is_animation_playing = false
		current_animation_name = ""

func _calculate_model_bounds_safe(model: Node3D) -> AABB:
	"""Calcular bounds del modelo de forma segura"""
	var bounds = AABB()
	var found_mesh = false
	
	for node in model.get_children():
		if node is MeshInstance3D:
			if not found_mesh:
				bounds = node.get_aabb()
				found_mesh = true
			else:
				bounds = bounds.merge(node.get_aabb())
	
	if not found_mesh:
		bounds = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	
	return bounds

func _get_display_name(animation_name: String) -> String:
	"""Obtener nombre limpio para mostrar"""
	var clean_name = animation_name
	
	# Limpiar patrones comunes
	clean_name = clean_name.replace("mixamo.com", "")
	clean_name = clean_name.replace("Armature|", "")
	clean_name = clean_name.replace("_", " ")
	clean_name = clean_name.replace("-", " ")
	
	return clean_name.strip_edges().capitalize()

# === FUNCIONES PÚBLICAS DE ESTADO ===

func is_preview_active() -> bool:
	"""Verificar si el preview está activo"""
	return preview_active and current_model != null

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func get_animation_player() -> AnimationPlayer:
	"""Obtener AnimationPlayer actual"""
	return animation_player

func get_current_animation() -> String:
	"""Obtener animación actual"""
	return current_animation_name

func is_playing() -> bool:
	"""Verificar si hay animación reproduciéndose"""

	return is_animation_playing

func get_viewport_texture() -> ViewportTexture:
	"""Obtener textura del viewport para otros usos"""
	if viewport:
		return viewport.get_texture()
	return null

# === CONFIGURACIÓN DE CÁMARA ===

func set_camera_position(position: Vector3):
	"""Configurar posición de cámara"""
	if camera:
		camera.position = position


func set_camera_rotation(rotation: Vector3):
	"""Configurar rotación de cámara"""
	if camera:
		camera.rotation = rotation

func reset_camera():
	"""Resetear cámara a posición por defecto"""
	if camera_controller and camera_controller.has_method("reset_to_default"):
		camera_controller.reset_to_default()
	elif current_bounds != AABB():
		# Posición por defecto manual
		var center = current_bounds.get_center()
		var camera_size = current_bounds.get_longest_axis_size()
		camera.position = center + Vector3(camera_size, camera_size, camera_size)
		camera.look_at(center, Vector3.UP)

# === DEBUG ===

func debug_state():
	"""Debug del estado actual"""
	print("\n🎬 === MODEL PREVIEW DEBUG ===")
	print("Preview activo: %s" % preview_active)
#	print("Modelo: %s" % (current_model.name if current_model else "NULL"))
# Error original
	print("Modelo: %s" % (str(current_model.name) if current_model else "NULL"))
	#print("AnimationPlayer: %s" % (animation_player.name if animation_player else "NULL"))
	print("AnimationPlayer: %s" % (str(animation_player.name) if animation_player else "NULL"))
	if animation_player:
		print("  Animaciones: %s" % str(animation_player.get_animation_list()))
		print("  Reproduciendo: %s" % is_animation_playing)
		print("  Actual: %s" % current_animation_name)
	print("Bounds: %s" % str(current_bounds))
	print("============================\n")



func _create_orientation_overlay():
	"""Crear overlay de orientación con cruz y norte"""
	if not viewport_container:
		return
	
	# Crear overlay principal
	orientation_overlay = Control.new()
	orientation_overlay.name = "OrientationOverlay"
	orientation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.add_child(orientation_overlay)
	
	# Crear cruz de orientación
	orientation_cross = Control.new()
	orientation_cross.name = "OrientationCross"
	orientation_cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	orientation_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orientation_cross.draw.connect(_draw_orientation_cross)
	orientation_overlay.add_child(orientation_cross)
	
	print("✅ Cruz de orientación creada")

func _draw_orientation_cross():
	"""Dibujar cruz de orientación con indicador de norte"""
	if not orientation_cross:
		return
	
	var viewport_size = viewport_container.size
	var center = viewport_size / 2.0
	
	# Configuración visual
	var cross_size = 60.0
	var line_width = 2.0
	var cross_color = Color(1.0, 1.0, 1.0, 0.8)  # Blanco semi-transparente
	var north_color = Color(1.0, 0.2, 0.2, 1.0)  # Rojo para norte
	
	# Dibujar cruz principal
	# Línea horizontal
	orientation_cross.draw_line(
		Vector2(center.x - cross_size, center.y),
		Vector2(center.x + cross_size, center.y),
		cross_color, line_width
	)
	
	# Línea vertical
	orientation_cross.draw_line(
		Vector2(center.x, center.y - cross_size),
		Vector2(center.x, center.y + cross_size),
		cross_color, line_width
	)
	
	# Dibujar círculo en el centro
	orientation_cross.draw_arc(
		center, 8.0, 0, TAU, 32, cross_color, line_width
	)
	
	# Obtener rotación actual del modelo para orientar la "N"
	var north_angle = 0.0
	if current_model and is_instance_valid(current_model):
		north_angle = deg_to_rad(-current_model.rotation_degrees.y)
	
	# Calcular posición del norte
	var north_distance = cross_size + 20.0
	var north_pos = Vector2(
		center.x + cos(north_angle) * north_distance,
		center.y + sin(north_angle) * north_distance
	)
	
	# Dibujar línea hacia el norte
	orientation_cross.draw_line(
		center,
		Vector2(center.x + cos(north_angle) * cross_size, center.y + sin(north_angle) * cross_size),
		north_color, line_width + 1.0
	)
	
	# Dibujar "N" para el norte
	var font = ThemeDB.fallback_font
	var font_size = 16
	orientation_cross.draw_string(
		font, 
		north_pos - Vector2(8, -8), 
		"N", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size, 
		north_color
	)
	
	# Dibujar flecha en el norte
	var arrow_size = 8.0
	var arrow_tip = Vector2(center.x + cos(north_angle) * cross_size, center.y + sin(north_angle) * cross_size)
	var arrow_left = arrow_tip + Vector2(cos(north_angle + 2.5), sin(north_angle + 2.5)) * arrow_size
	var arrow_right = arrow_tip + Vector2(cos(north_angle - 2.5), sin(north_angle - 2.5)) * arrow_size
	
	orientation_cross.draw_line(arrow_tip, arrow_left, north_color, line_width)
	orientation_cross.draw_line(arrow_tip, arrow_right, north_color, line_width)

func update_orientation_display():
	"""Actualizar visualización de orientación"""
	if orientation_cross:
		orientation_cross.queue_redraw()

func show_orientation_cross():
	"""Mostrar cruz de orientación"""
	if orientation_overlay:
		orientation_overlay.visible = true
		update_orientation_display()

func hide_orientation_cross():
	"""Ocultar cruz de orientación"""
	if orientation_overlay:
		orientation_overlay.visible = false



# ========================================================================
# NUEVAS FUNCIONES PARA SHADER AVANZADO - AGREGAR A model_preview_panel.gd
# ========================================================================

# AGREGAR ESTAS VARIABLES AL INICIO DE LA CLASE (después de var current_model)
var current_shader_settings: Dictionary = {}
var shader_applied_to_model: bool = false

# FUNCIÓN PRINCIPAL: Aplicar shader avanzado al modelo actual
func apply_advanced_shader(shader_settings: Dictionary):
	"""Aplicar configuración de shader avanzado al modelo actual en el preview"""
	print("🎨 Aplicando shader avanzado al modelo en preview...")
	print("   Modelo actual: %s" % (current_model.name if current_model else "NINGUNO"))
	
	if not current_model:
		print("   ❌ No hay modelo actual para aplicar shader")
		return
	
	# Guardar configuración
	current_shader_settings = shader_settings.duplicate()
	
	# Buscar todas las MeshInstance3D en el modelo
	var mesh_instances = _find_all_mesh_instances_in_model(current_model)
	print("   📦 Encontradas %d mesh instances en el modelo" % mesh_instances.size())
	
	var applied_count = 0
	var total_surfaces = 0
	
	for mesh_instance in mesh_instances:
		var surfaces_processed = _apply_shader_to_mesh_instance(mesh_instance, shader_settings)
		if surfaces_processed > 0:
			applied_count += 1
			total_surfaces += surfaces_processed
			print("   ✅ Shader aplicado a: %s (%d superficies)" % [mesh_instance.name, surfaces_processed])
		else:
			print("   ⚠️ No se pudo aplicar shader a: %s" % mesh_instance.name)
	
	shader_applied_to_model = applied_count > 0
	
	if shader_applied_to_model:
		print("   🎉 Shader avanzado aplicado exitosamente!")
		print("   📊 Resumen: %d mesh instances, %d superficies procesadas" % [applied_count, total_surfaces])
	else:
		print("   ❌ No se pudo aplicar shader a ninguna mesh instance")

# FUNCIÓN AUXILIAR: Encontrar todas las MeshInstance3D en el modelo
func _find_all_mesh_instances_in_model(model: Node3D) -> Array:
	"""Encontrar recursivamente todas las MeshInstance3D en el modelo"""
	var mesh_instances = []
	
	# Si el nodo actual es MeshInstance3D, agregarlo
	if model is MeshInstance3D:
		mesh_instances.append(model)
	
	# Buscar recursivamente en todos los hijos
	for child in model.get_children():
		if child is Node3D:
			mesh_instances.append_array(_find_all_mesh_instances_in_model(child))
	
	return mesh_instances

# FUNCIÓN AUXILIAR: Aplicar shader a una MeshInstance3D específica
func _apply_shader_to_mesh_instance(mesh_instance: MeshInstance3D, shader_settings: Dictionary) -> int:
	"""Aplicar shader a todas las superficies de una MeshInstance3D"""
	if not mesh_instance or not mesh_instance.mesh:
		return 0
	
	var surfaces_processed = 0
	var surface_count = mesh_instance.mesh.get_surface_count()
	
	print("     Procesando %s con %d superficies..." % [mesh_instance.name, surface_count])
	
	for surface_idx in range(surface_count):
		if _apply_shader_to_surface(mesh_instance, surface_idx, shader_settings):
			surfaces_processed += 1
	
	return surfaces_processed

# FUNCIÓN AUXILIAR: Aplicar shader a una superficie específica
func _apply_shader_to_surface(mesh_instance: MeshInstance3D, surface_idx: int, shader_settings: Dictionary) -> bool:
	"""Aplicar shader avanzado a una superficie específica de la mesh"""
	var target_material = null
	var material_source = ""
	
	# 1. Verificar si ya tiene surface override material
	var surface_override = mesh_instance.get_surface_override_material(surface_idx)
	if surface_override:
		target_material = surface_override
		material_source = "surface_override"
	
	# 2. Si no tiene override, crear uno desde el material original
	elif mesh_instance.mesh.surface_get_material(surface_idx):
		var original_material = mesh_instance.mesh.surface_get_material(surface_idx)
		target_material = original_material.duplicate()
		mesh_instance.set_surface_override_material(surface_idx, target_material)
		material_source = "created_from_original"
		print("       Creado material override para superficie %d" % surface_idx)
	
	# 3. Si no hay material, crear uno nuevo
	else:
		target_material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(surface_idx, target_material)
		material_source = "created_new"
		print("       Creado material nuevo para superficie %d" % surface_idx)
	
	if not target_material:
		print("       ❌ No se pudo obtener material para superficie %d" % surface_idx)
		return false
	
	# 4. Convertir a ShaderMaterial si es necesario
	var shader_material = _convert_to_shader_material(target_material, mesh_instance, surface_idx)
	if not shader_material:
		print("       ❌ No se pudo convertir a ShaderMaterial superficie %d" % surface_idx)
		return false
	
	# 5. Cargar y aplicar el shader avanzado
	if not _ensure_advanced_shader_loaded(shader_material):
		print("       ❌ No se pudo cargar shader avanzado para superficie %d" % surface_idx)
		return false
	
	# 6. Aplicar todos los parámetros del shader
	_apply_shader_parameters(shader_material, shader_settings)
	
	print("       ✅ Superficie %d: shader aplicado (%s)" % [surface_idx, material_source])
	return true

# FUNCIÓN AUXILIAR: Convertir material a ShaderMaterial
func _convert_to_shader_material(material: Material, mesh_instance: MeshInstance3D, surface_idx: int) -> ShaderMaterial:
	"""Convertir un material a ShaderMaterial preservando propiedades"""
	
	# Si ya es ShaderMaterial, devolverlo directamente
	if material is ShaderMaterial:
		return material as ShaderMaterial
	
	# Crear nuevo ShaderMaterial
	var shader_material = ShaderMaterial.new()
	
	# Preservar propiedades importantes si es StandardMaterial3D
	if material is StandardMaterial3D:
		var std_material = material as StandardMaterial3D
		
		# Preservar textura principal (albedo)
		if std_material.albedo_texture:
			shader_material.set_shader_parameter("main_texture", std_material.albedo_texture)
		
		# Preservar color albedo
		if std_material.albedo_color != Color.WHITE:
			shader_material.set_shader_parameter("base_color", std_material.albedo_color)
		
		print("       🔄 Material convertido de StandardMaterial3D a ShaderMaterial")
	else:
		print("       🔄 Material convertido de %s a ShaderMaterial" % material.get_class())
	
	# Asignar el nuevo ShaderMaterial a la superficie
	mesh_instance.set_surface_override_material(surface_idx, shader_material)
	
	return shader_material

# FUNCIÓN AUXILIAR: Asegurar que el shader avanzado esté cargado
func _ensure_advanced_shader_loaded(shader_material: ShaderMaterial) -> bool:
	"""Asegurar que el shader avanzado esté cargado en el material"""
	var shader_path = "res://resources/shaders/pixelize_advanced.gdshader"
	
	# Si ya tiene el shader correcto, retornar true
	if shader_material.shader and shader_material.shader.resource_path == shader_path:
		return true
	
	# Cargar el shader avanzado
	if ResourceLoader.exists(shader_path):
		var advanced_shader = load(shader_path) as Shader
		if advanced_shader:
			shader_material.shader = advanced_shader
			print("       🔧 Shader avanzado cargado desde: %s" % shader_path)
			return true
		else:
			print("       ❌ Error: No se pudo cargar como Shader: %s" % shader_path)
			return false
	else:
		print("       ❌ Error: Archivo de shader no encontrado: %s" % shader_path)
		return false

# FUNCIÓN AUXILIAR: Aplicar parámetros del shader
func _apply_shader_parameters(shader_material: ShaderMaterial, shader_settings: Dictionary):
	"""Aplicar todos los parámetros del shader avanzado al material"""
	
	# Parámetros de pixelización
	shader_material.set_shader_parameter("pixel_size", shader_settings.get("pixel_size", 4.0))
	
	# Parámetros de reducción de colores
	shader_material.set_shader_parameter("reduce_colors", shader_settings.get("reduce_colors", false))
	shader_material.set_shader_parameter("color_levels", shader_settings.get("color_levels", 16))
	
	# Parámetros de dithering
	shader_material.set_shader_parameter("enable_dithering", shader_settings.get("enable_dithering", false))
	shader_material.set_shader_parameter("dither_strength", shader_settings.get("dither_strength", 0.1))
	
	# Parámetros de bordes
	shader_material.set_shader_parameter("enable_outline", shader_settings.get("enable_outline", false))
	shader_material.set_shader_parameter("outline_thickness", shader_settings.get("outline_thickness", 1.0))
	shader_material.set_shader_parameter("outline_color", shader_settings.get("outline_color", Color.BLACK))
	shader_material.set_shader_parameter("outline_pixelated", shader_settings.get("outline_pixelated", true))
	shader_material.set_shader_parameter("outline_smooth", shader_settings.get("outline_smooth", 0.0))
	
	# Efectos avanzados - aplicar solo si están habilitados
	var contrast_value = 1.0
	if shader_settings.get("contrast_enabled", false):
		contrast_value = shader_settings.get("contrast_boost", 1.0)
	shader_material.set_shader_parameter("contrast_boost", contrast_value)
	
	var saturation_value = 1.0
	if shader_settings.get("saturation_enabled", false):
		saturation_value = shader_settings.get("saturation_mult", 1.0)
	shader_material.set_shader_parameter("saturation_mult", saturation_value)
	
	var tint_color = Color.WHITE
	if shader_settings.get("tint_enabled", false):
		tint_color = shader_settings.get("color_tint", Color.WHITE)
	shader_material.set_shader_parameter("color_tint", tint_color)
	
	var apply_gamma = shader_settings.get("gamma_enabled", false)
	shader_material.set_shader_parameter("apply_gamma_correction", apply_gamma)
	shader_material.set_shader_parameter("gamma_value", shader_settings.get("gamma_value", 1.0))

# FUNCIÓN PÚBLICA: Re-aplicar shader cuando cambie el modelo
func _on_model_changed_reapply_shader():
	"""Re-aplicar shader cuando el modelo cambia (llamar en show_model)"""
	if not current_shader_settings.is_empty() and current_model:
		print("🔄 Re-aplicando shader al nuevo modelo...")
		apply_advanced_shader(current_shader_settings)

# FUNCIÓN PÚBLICA: Limpiar shader del modelo
func clear_advanced_shader():
	"""Limpiar shader avanzado del modelo actual"""
	if not current_model:
		return
	
	print("🧹 Limpiando shader avanzado del modelo...")
	
	var mesh_instances = _find_all_mesh_instances_in_model(current_model)
	var cleared_count = 0
	
	for mesh_instance in mesh_instances:
		for surface_idx in range(mesh_instance.mesh.get_surface_count() if mesh_instance.mesh else 0):
			# Remover surface override material para volver al original
			mesh_instance.set_surface_override_material(surface_idx, null)
			cleared_count += 1
	
	current_shader_settings.clear()
	shader_applied_to_model = false
	
	print("✅ Shader limpiado de %d superficies" % cleared_count)

# FUNCIÓN PÚBLICA: Obtener estado del shader
func get_shader_status() -> Dictionary:
	"""Obtener información del estado actual del shader"""
	return {
		"shader_applied": shader_applied_to_model,
		"settings_count": current_shader_settings.size(),
		"has_model": current_model != null,
		"model_name": current_model.name if current_model else ""
	}

# MODIFICAR LA FUNCIÓN EXISTENTE show_model PARA RE-APLICAR SHADER
# AGREGAR AL FINAL DE LA FUNCIÓN show_model EXISTENTE:
func _reapply_shader_after_model_change():
	"""Llamar al final de show_model para re-aplicar shader"""
	if not current_shader_settings.is_empty():
		# Usar call_deferred para asegurar que el modelo esté completamente cargado
		call_deferred("_on_model_changed_reapply_shader")

# FUNCIÓN DE DEBUG (OPCIONAL): Debug del estado del shader
func debug_shader_state():
	"""Debug del estado actual del shader en el modelo"""
	print("\n🔍 === DEBUG SHADER EN MODEL PREVIEW ===")
	print("Modelo actual: %s" % (current_model.name if current_model else "NINGUNO"))
	print("Shader aplicado: %s" % shader_applied_to_model)
	print("Configuración: %d parámetros" % current_shader_settings.size())
	
	if current_model:
		var mesh_instances = _find_all_mesh_instances_in_model(current_model)
		print("Mesh instances encontradas: %d" % mesh_instances.size())
		
		for mesh_instance in mesh_instances:
			print("  • %s:" % mesh_instance.name)
			if mesh_instance.mesh:
				for surface_idx in range(mesh_instance.mesh.get_surface_count()):
					var override_mat = mesh_instance.get_surface_override_material(surface_idx)
					if override_mat:
						var is_shader_mat = override_mat is ShaderMaterial
						var has_advanced_shader = false
						if is_shader_mat and override_mat.shader:
							has_advanced_shader = "pixelize_advanced" in override_mat.shader.resource_path
						print("    Superficie %d: %s %s" % [
							surface_idx,
							"ShaderMaterial" if is_shader_mat else override_mat.get_class(),
							"(shader avanzado)" if has_advanced_shader else ""
						])
					else:
						print("    Superficie %d: sin override" % surface_idx)
			else:
				print("    Sin mesh")
	
	print("=========================================\n")
