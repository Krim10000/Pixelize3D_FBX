# scripts/viewer/ui/model_preview_panel.gd
# Panel de preview CORREGIDO para compatibilidad total con el sistema
# Input: Modelo combinado desde viewer_coordinator
# Output: Vista previa funcional con controles de animación

extends VBoxContainer

# Señales
signal model_displayed(model: Node3D)
signal bounds_calculated(bounds: AABB)
signal preview_enabled()
signal animation_playing(animation_name: String)

# Referencias UI
@onready var viewport_container: SubViewportContainer = find_child("ViewportContainer")
@onready var viewport: SubViewport = find_child("SubViewport")
@onready var model_container: Node3D = find_child("ModelContainer")
@onready var camera_controller: Node = find_child("CameraController")
@onready var model_rotator: Node = find_child("ModelRotator")

# Labels informativos
@onready var status_label: Label = find_child("StatusLabel")
@onready var controls_help_label: Label = find_child("ControlsHelpLabel")

# Estado interno - Sin dependencias externas
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var preview_active: bool = false

# === FUNCIONES PRIVADAS DE MANEJO DE ANIMACIONES ===

func _setup_infinite_loops(anim_player: AnimationPlayer) -> void:
	"""Configurar todas las animaciones para loop infinito"""
	if not anim_player:
		print("❌ AnimationPlayer inválido para configurar loops")
		return
	
	print("🔄 CONFIGURANDO LOOPS INFINITOS")
	
	var animations_configured = 0
	
	# Configurar cada animación para loop
	for anim_name in anim_player.get_animation_list():
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(anim_name)
		
		if animation:
			# Configurar loop mode
			animation.loop_mode = Animation.LOOP_LINEAR
			animations_configured += 1
			print("✅ Loop configurado: " + anim_name)
	
	print("🔄 Loops configurados: " + str(animations_configured) + " animaciones")

func _change_animation_clean(anim_player: AnimationPlayer, new_animation: String) -> bool:
	"""Cambiar animación de forma limpia y sincrónica"""
	if not anim_player:
		print("❌ AnimationPlayer inválido")
		return false
	
	if not anim_player.has_animation(new_animation):
		print("❌ Animación no encontrada: " + new_animation)
		return false
	
	print("🎭 CAMBIANDO ANIMACIÓN A: " + new_animation)
	
	# PASO 1: Detener animación actual
	if anim_player.is_playing():
		var current_anim = anim_player.current_animation
		print("  🛑 Deteniendo animación actual: %s" % current_anim)
		anim_player.stop()
	
	# PASO 2: Configurar loop en la nueva animación
	var anim_lib = anim_player.get_animation_library("")
	var animation = anim_lib.get_animation(new_animation)
	if animation:
		animation.loop_mode = Animation.LOOP_LINEAR
		print("  🔄 Loop configurado para: %s" % new_animation)
	
	# PASO 3: Iniciar nueva animación directamente
	print("  ▶️ Iniciando nueva animación: %s" % new_animation)
	anim_player.play(new_animation)
	
	# PASO 4: Verificar éxito
	if anim_player.is_playing() and anim_player.current_animation == new_animation:
		print("  ✅ Cambio de animación exitoso")
		return true
	else:
		print("  ❌ Falló el cambio de animación")
		return false

func _stop_animation_clean(anim_player: AnimationPlayer) -> void:
	"""Detener completamente y resetear"""
	if not anim_player:
		return
	
	print("⏹️ DETENIENDO ANIMACIÓN COMPLETAMENTE")
	
	# Detener reproducción
	anim_player.stop()
	
	# Limpiar estado
	anim_player.current_animation = ""
	
	# Resetear a pose de reposo si existe
	var animations = anim_player.get_animation_list()
	if animations.size() > 0:
		var first_anim = animations[0]
		anim_player.play(first_anim)
		anim_player.seek(0.0, true)
		anim_player.pause()
		print("  🎭 Reseteado a pose inicial de: " + first_anim)

func _toggle_pause_with_loop(anim_player: AnimationPlayer) -> bool:
	"""Pausar/reanudar manteniendo el loop"""
	if not anim_player:
		return false
	
	if anim_player.is_playing():
		print("⏸️ Pausando animación")
		anim_player.pause()
		return false  # Ahora está pausado
	else:
		print("▶️ Reanudando animación")
		anim_player.play()
		return true   # Ahora está reproduciendo

# === INICIALIZACIÓN ===

func _ready():
	print("🎬 ModelPreviewPanel inicializado (CORREGIDO)")
	_setup_ui()
	_connect_signals()

func _setup_ui():
	"""Configurar elementos de UI básicos"""
	if not status_label:
		status_label = Label.new()
		add_child(status_label)
	
	if not controls_help_label:
		controls_help_label = Label.new()
		add_child(controls_help_label)
	
	# Configurar estilos
	status_label.text = "Esperando modelo..."
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	controls_help_label.text = "CONTROLES: Click+Arrastrar=Rotar Camara | Rueda=Zoom | Ctrl+Click=Rotar Modelo"
	controls_help_label.add_theme_font_size_override("font_size", 9)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false

func _connect_signals():
	"""Conectar señales entre componentes"""
	if camera_controller and camera_controller.has_signal("camera_ready"):
		camera_controller.connect("camera_ready", _on_camera_ready)
	
	if model_rotator and model_rotator.has_signal("north_changed"):
		model_rotator.connect("north_changed", _on_north_changed)
		model_rotator.connect("model_rotated", _on_model_rotated)

# === GESTIÓN DEL MODELO ===

func set_model(model: Node3D):
	"""✅ FUNCIÓN CORREGIDA: Configurar modelo para preview"""
	print("🎬 PREVIEW_PANEL: Configurando modelo - " + str(model.name if model != null else "NULL"))	
	if not model_container:
		print("❌ ERROR: model_container no disponible")
		return
	
	# Limpiar modelo anterior de forma segura
	_clear_current_model_safe()
	
	if not model:
		status_label.text = "No hay modelo cargado"
		return
	
	# ✅ CORRECCIÓN: Duplicar modelo para preview (evitar conflictos)
	current_model = model.duplicate()
	current_model.name = "Preview_" + model.name
	model_container.add_child(current_model)
	
	# Buscar AnimationPlayer en el modelo
	animation_player = _find_animation_player(current_model)
	
	if animation_player:
		print("✅ AnimationPlayer encontrado: " + str(animation_player.get_animation_list().size()) + " animaciones")
		# ✅ CORRECCIÓN: Usar función privada directamente
		_setup_infinite_loops(animation_player)
	else:
		print("⚠️ No se encontró AnimationPlayer en el modelo")
	
	# Calcular bounds usando método mejorado
	var bounds = _calculate_model_bounds_safe(current_model)
	emit_signal("bounds_calculated", bounds)
	
	# Configurar cámara si está disponible
	if camera_controller and camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(bounds)
	elif camera_controller and camera_controller.has_method("focus_on_bounds"):
		camera_controller.focus_on_bounds(bounds)
	
	# Configurar rotador si está disponible
	if model_rotator and model_rotator.has_method("set_model"):
		model_rotator.set_model(current_model)
	
	# Actualizar status
	status_label.text = "✅ Modelo cargado: " + current_model.name
	
	# Iniciar animación por defecto de forma segura
	call_deferred("_start_default_animation_safe")
	
	# Emitir señal
	emit_signal("model_displayed", current_model)
	
	print("✅ Modelo configurado en preview: " + current_model.name)

# ✅ FUNCIÓN NUEVA: Limpiar modelo anterior de forma segura
func _clear_current_model_safe():
	"""Limpiar modelo anterior de forma segura y síncrona"""
	if current_model and is_instance_valid(current_model):
		print("🧹 Limpiando modelo anterior: " + current_model.name)
		
		# Detener animaciones antes de liberar
		if animation_player and is_instance_valid(animation_player):
			animation_player.stop()
		
		# Remover del contenedor antes de liberar
		if current_model.get_parent():
			current_model.get_parent().remove_child(current_model)
		
		# Liberar inmediatamente
		current_model.queue_free()
		current_model = null
		animation_player = null
		
		print("✅ Modelo anterior limpiado")

# ✅ FUNCIÓN CORREGIDA: Calcular bounds de forma segura
func _calculate_model_bounds_safe(model: Node3D) -> AABB:
	"""Calcular bounds del modelo de forma segura"""
	var bounds = AABB()
	var found_bounds = false
	
	if not model:
		return AABB(Vector3.ZERO, Vector3(2, 2, 2))  # Bounds por defecto
	
	# Buscar meshes en el modelo
	var mesh_instances = _find_all_mesh_instances(model)
	
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh:
			var mesh_bounds = mesh_instance.mesh.get_aabb()
			# Aplicar transform del mesh instance
			mesh_bounds = mesh_instance.transform * mesh_bounds
			
			if not found_bounds:
				bounds = mesh_bounds
				found_bounds = true
			else:
				bounds = bounds.merge(mesh_bounds)
	
	# Si no se encontraron bounds, usar bounds por defecto
	if not found_bounds:
		bounds = AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
		print("⚠️ No se encontraron bounds, usando por defecto")
	else:
		print("✅ Bounds calculados: " + str(bounds))
	
	return bounds

# ✅ FUNCIÓN NUEVA: Encontrar todas las instancias de mesh
func _find_all_mesh_instances(node: Node) -> Array:
	"""Encontrar recursivamente todas las instancias de mesh"""
	var mesh_instances = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(_find_all_mesh_instances(child))
	
	return mesh_instances

# ✅ FUNCIÓN CORREGIDA: Iniciar animación por defecto de forma segura
func _start_default_animation_safe():
	"""Iniciar primera animación disponible de forma segura"""
	if not animation_player or not is_instance_valid(animation_player):
		print("⚠️ No hay AnimationPlayer válido para iniciar animación")
		return
	
	var animations = animation_player.get_animation_list()
	if animations.size() == 0:
		print("⚠️ No hay animaciones disponibles")
		status_label.text += " (Sin animaciones)"
		return
	
	var first_animation = animations[0]
	print("🎭 Iniciando animación por defecto: " + first_animation)
	
	# ✅ CORRECCIÓN: Usar método privado directamente
	var success = _change_animation_clean(animation_player, first_animation)
	
	if success:
		status_label.text += " - Animando: " + first_animation
		emit_signal("animation_playing", first_animation)
		print("✅ Animación iniciada: " + first_animation)
	else:
		print("❌ Error al iniciar animación: " + first_animation)
		status_label.text += " (Error en animación)"

# === CONTROL DE ANIMACIONES MEJORADO ===

func play_animation(animation_name: String):
	"""✅ FUNCIÓN CORREGIDA: Reproducir animación específica"""
	if not animation_player or not is_instance_valid(animation_player):
		print("❌ No hay AnimationPlayer disponible")
		return
	
	if not animation_player.has_animation(animation_name):
		print("❌ Animación no encontrada: " + animation_name)
		return
	
	print("🎭 Cambiando a animación: " + animation_name)
	status_label.text = "🔄 Cambiando animación..."
	
	# ✅ CORRECCIÓN: Usar método privado directamente
	var success = _change_animation_clean(animation_player, animation_name)
	
	if success:
		status_label.text = "🔄 Reproduciendo en loop: " + animation_name
		emit_signal("animation_playing", animation_name)
		print("✅ Animación iniciada en loop: " + animation_name)
	else:
		status_label.text = "❌ Error al cambiar animación"
		print("❌ Error al cambiar animación: " + animation_name)

func stop_animation():
	"""Detener animación actual completamente"""
	if animation_player and is_instance_valid(animation_player):
		_stop_animation_clean(animation_player)
		status_label.text = "⏹️ Animación detenida"
		print("⏹️ Animación detenida completamente")

func toggle_pause_animation():
	"""Pausar/reanudar animación manteniendo el loop"""
	if not animation_player or not is_instance_valid(animation_player):
		return
	
	var is_playing = _toggle_pause_with_loop(animation_player)
	
	if is_playing:
		status_label.text = "▶️ Reproduciendo en loop: " + animation_player.current_animation
	else:
		status_label.text = "⏸️ Pausado: " + animation_player.current_animation

# === CONTROL DE PREVIEW MODE ===

func enable_preview_mode():
	"""Habilitar modo preview completo"""
	preview_active = true
	controls_help_label.visible = true
	
	# Habilitar CameraController
	if camera_controller and camera_controller.has_method("enable_preview_mode"):
		camera_controller.enable_preview_mode()
		print("✅ CameraController habilitado")
	
	# Habilitar ModelRotator  
	if model_rotator and model_rotator.has_method("enable_rotation_control"):
		model_rotator.enable_rotation_control()
		print("✅ ModelRotator habilitado")
	
	# Configurar viewport para input
	if viewport_container:
		viewport_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	emit_signal("preview_enabled")
	print("🎬 Preview mode activado")

func disable_preview_mode():
	"""Deshabilitar modo preview"""
	preview_active = false
	controls_help_label.visible = false
	
	# Deshabilitar controles
	if camera_controller and camera_controller.has_method("disable_preview_mode"):
		camera_controller.disable_preview_mode()
	
	if model_rotator and model_rotator.has_method("disable_rotation_control"):
		model_rotator.disable_rotation_control()
	
	print("🛑 Preview mode deshabilitado")

# === FUNCIONES DE UTILIDAD ===

func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

# === CONTROL DE ORIENTACIÓN ===

func set_north_angle(angle: float):
	"""Configurar ángulo de Norte relativo"""
	if model_rotator and model_rotator.has_method("set_north_angle"):
		model_rotator.set_north_angle(angle)
		print("🧭 Norte relativo configurado: " + str(angle) + "°")

func reset_model_orientation():
	"""Resetear orientación del modelo"""
	if model_rotator and model_rotator.has_method("reset_north"):
		model_rotator.reset_north()
	if model_rotator and model_rotator.has_method("reset_user_rotation"):
		model_rotator.reset_user_rotation()
	print("🔄 Orientación del modelo reseteada")

# === CALLBACKS DE SEÑALES ===

func _on_camera_ready():
	"""Callback cuando la cámara está lista"""
	print("📹 Cámara lista en preview")

func _on_north_changed(angle: float):
	"""Callback cuando cambia el norte"""
	print("🧭 Norte cambiado: " + str(angle) + "°")

func _on_model_rotated(_model_rotation: Vector3):
	"""Callback cuando se rota el modelo"""
			# Debug opcional: print("🔄 Modelo rotado: " + str(_model_rotation))
	pass

# === FUNCIONES DE DEBUG ===

func debug_preview_state():
	"""Debug del estado del preview"""
	print("\n🎬 === DEBUG PREVIEW PANEL ===")
	print("Preview activo: " + str(preview_active))
	print("Modelo actual: " + str(current_model.name if current_model != null else "null"))
	print("AnimationPlayer: " + str(animation_player.name if animation_player != null else "null"))
	
	if animation_player:
		print("Animaciones disponibles: " + str(animation_player.get_animation_list()))
		print("Animación actual: " + str(animation_player.current_animation))
		print("Reproduciendo: " + str(animation_player.is_playing()))
	
	print("Componentes:")
	print("  CameraController: %s" % ("✅" if camera_controller else "❌"))
	print("  ModelRotator: %s" % ("✅" if model_rotator else "❌"))
	print("  ViewportContainer: %s" % ("✅" if viewport_container else "❌"))
	print("================================\n")

# === FUNCIONES PÚBLICAS ADICIONALES ===

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func get_animation_player() -> AnimationPlayer:
	"""Obtener animation player actual"""
	return animation_player

func has_model() -> bool:
	"""Verificar si hay modelo cargado"""
	return current_model != null and is_instance_valid(current_model)

func get_model_bounds() -> AABB:
	"""Obtener bounds del modelo actual"""
	if current_model:
		return _calculate_model_bounds_safe(current_model)
	return AABB()

# === LIMPIEZA ===

func _exit_tree():
	"""Limpiar al salir"""
	_clear_current_model_safe()
