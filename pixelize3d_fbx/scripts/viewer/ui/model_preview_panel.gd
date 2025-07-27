# scripts/viewer/ui/model_preview_panel.gd
# Panel CORREGIDO - ELIMINA duplicación del modelo para sincronizar AnimationPlayer
# Input: Modelo 3D combinado con AnimationPlayer desde FBXLoader
# Output: Preview visual usando el MISMO modelo que AnimationControlsPanel

extends VBoxContainer

# Señales específicas de este panel
signal model_displayed(model: Node3D)
signal preview_enabled()
signal animation_playing(animation_name: String)
signal bounds_calculated(bounds: AABB)

# Referencias a nodos existentes (configurados en _ready)
var preview_label: Label
var status_label: Label
var controls_help_label: Label
var viewport_container: SubViewportContainer
var preview_viewport: SubViewport
var model_container: Node3D
var camera_3d: Camera3D
var directional_light: DirectionalLight3D
var camera_controller: Node3D
var model_rotator: Node3D

# Estado interno
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var preview_active: bool = false

func _ready():
	_find_existing_nodes()
	_setup_specialized_scripts()
	_setup_ui_labels()
	_connect_signals()

func _find_existing_nodes():
	"""Buscar y validar nodos existentes en la escena"""
	print("🔍 PREVIEW_PANEL: Buscando nodos existentes...")
	
	# Buscar viewport container
	viewport_container = get_node_or_null("ViewportContainer")
	if viewport_container:
		preview_viewport = viewport_container.get_node_or_null("SubViewport")
		if preview_viewport:
			model_container = preview_viewport.get_node_or_null("ModelContainer")
			camera_3d = preview_viewport.get_node_or_null("Camera3D")
			directional_light = preview_viewport.get_node_or_null("DirectionalLight3D")
			camera_controller = preview_viewport.get_node_or_null("CameraController")
	
	# Validar nodos críticos
	var missing_nodes = []
	if not model_container: missing_nodes.append("ModelContainer")
	if not camera_3d: missing_nodes.append("Camera3D")
	if not preview_viewport: missing_nodes.append("SubViewport")
	if not camera_controller: missing_nodes.append("CameraController")
	
	if missing_nodes.size() > 0:
		print("❌ ERROR: Nodos faltantes: %s" % str(missing_nodes))
		return
	
	print("✅ Nodos existentes encontrados:")
	print("  - ModelContainer: %s" % model_container.name)
	print("  - Camera3D: %s" % camera_3d.name)
	print("  - CameraController: %s" % camera_controller.name)
	print("  - DirectionalLight3D: %s" % (directional_light.name if directional_light else "NULL"))

func _setup_specialized_scripts():
	"""Configurar scripts especializados para control granular"""
	# Crear ModelRotator para control de orientación
	if model_container and not model_container.get_node_or_null("ModelRotator"):
		model_rotator = Node3D.new()
		model_rotator.name = "ModelRotator"
		
		# Cargar script de forma más segura
		var script_path = "res://scripts/rendering/model_rotator.gd"
		if ResourceLoader.exists(script_path):
			var script_resource = load(script_path)
			model_rotator.set_script(script_resource)
			model_container.add_child(model_rotator)
			print("✅ ModelRotator creado y agregado")
		else:
			print("❌ ERROR: Script no encontrado: %s" % script_path)
			print("   Creando ModelRotator sin script por ahora...")
			model_container.add_child(model_rotator)
	else:
		model_rotator = model_container.get_node_or_null("ModelRotator")
		print("✅ ModelRotator encontrado")

func _setup_ui_labels():
	"""Configurar labels de interfaz"""
	# Preview label principal
	preview_label = get_node_or_null("PreviewLabel")
	if not preview_label:
		preview_label = Label.new()
		preview_label.name = "PreviewLabel"
		add_child(preview_label)
		move_child(preview_label, 0)
	
	# Status label
	status_label = get_node_or_null("PreviewStatusLabel")
	if not status_label:
		status_label = Label.new()
		status_label.name = "PreviewStatusLabel"
		add_child(status_label)
		if preview_label:
			move_child(status_label, preview_label.get_index() + 1)
	
	# Controls help
	controls_help_label = get_node_or_null("ControlsHelp")
	if not controls_help_label:
		controls_help_label = Label.new()
		controls_help_label.name = "ControlsHelp"
		add_child(controls_help_label)
	
	# Configurar estilos
	preview_label.text = "🎬 Vista Previa del Modelo"
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	status_label.text = "Carga un modelo para ver preview"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	controls_help_label.text = "🎮 Click+Arrastrar=Rotar Cámara | Rueda=Zoom | Ctrl+Click=Rotar Modelo"
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
	"""CORREGIDO: Usar modelo original directamente - NO duplicar"""
	print("🎬 PREVIEW_PANEL: Configurando modelo - %s" % (model.name if model else "NULL"))
	
	if not model_container or not camera_controller:
		print("❌ ERROR: Componentes necesarios no disponibles")
		return
	
	# Limpiar modelo anterior SOLO si es diferente
	if current_model and current_model != model:
		_clear_current_model()
	
	if not model:
		status_label.text = "No hay modelo cargado"
		return
	
	# CORRECCIÓN CRÍTICA: Usar modelo original directamente (NO duplicar)
	current_model = model
	
	# Verificar si el modelo ya está en el contenedor
	if current_model.get_parent() != model_container:
		model_container.add_child(current_model)
		print("✅ Modelo agregado al contenedor preview")
	else:
		print("ℹ️ Modelo ya está en el contenedor preview")
	
	# Buscar AnimationPlayer en el modelo ORIGINAL
	animation_player = _find_animation_player(current_model)
	
	if animation_player:
		print("✅ AnimationPlayer encontrado: %s" % animation_player.name)
		print("   Animaciones disponibles: %s" % str(animation_player.get_animation_list()))
	else:
		print("⚠️ No se encontró AnimationPlayer en el modelo")
	
	# Calcular bounds usando método corregido
	var bounds = _calculate_model_bounds_corrected(current_model)
	emit_signal("bounds_calculated", bounds)
	
	# Delegar configuración a CameraController
	if camera_controller.has_method("setup_for_model"):
		camera_controller.setup_for_model(bounds)
	
	# Delegar control de rotación a ModelRotator
	if model_rotator and model_rotator.has_method("set_model"):
		model_rotator.set_model(current_model)
	
	# Actualizar status
	status_label.text = "✅ Modelo cargado: " + current_model.name
	
	# Emitir señal
	emit_signal("model_displayed", current_model)
	
	print("✅ Modelo configurado - USANDO ORIGINAL (sincronizado con AnimationControls)")

func _clear_current_model():
	"""Limpiar modelo actual - CORREGIDO para modelo original"""
	print("🧹 Limpiando modelo actual...")
	
	if current_model:
		if model_rotator and model_rotator.has_method("clear_model"):
			model_rotator.clear_model()
		
		# CORRECCIÓN: Solo remover del contenedor, NO destruir (el modelo original se usa en otros lados)
		if current_model.get_parent() == model_container:
			model_container.remove_child(current_model)
			print("✅ Modelo removido del contenedor (preservado para otros usos)")
		
		current_model = null
		animation_player = null

func _calculate_model_bounds_corrected(model: Node3D) -> AABB:
	"""
	Método CORREGIDO para calcular bounds - evita problemas de referencia en GDScript
	"""
	print("  🔍 Calculando bounds del modelo...")
	
	var all_bounds = []  # Array para acumular bounds individuales
	
	# Recolectar todos los bounds recursivamente
	_collect_mesh_bounds_to_array(model, all_bounds, Transform3D.IDENTITY)
	
	if all_bounds.size() == 0:
		print("  ⚠️ No se encontraron meshes, usando bounds por defecto")
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	
	# Combinar todos los bounds
	var final_bounds = all_bounds[0]
	for i in range(1, all_bounds.size()):
		final_bounds = final_bounds.merge(all_bounds[i])
	
	print("  ✅ Bounds calculados de %d meshes: %s" % [all_bounds.size(), final_bounds])
	return final_bounds

func _collect_mesh_bounds_to_array(node: Node3D, bounds_array: Array, parent_transform: Transform3D):
	"""
	Recolectar bounds de meshes en un array (evita problemas de referencia)
	"""
	var current_transform = parent_transform * node.transform
	
	# Si es MeshInstance3D con mesh válido
	if node is MeshInstance3D and node.mesh:
		var mesh_bounds = node.get_aabb()
		var global_bounds = current_transform * mesh_bounds
		bounds_array.append(global_bounds)
		
		print("    ✅ Mesh encontrado: %s - Bounds: %s" % [node.name, global_bounds])
	
	# Procesar hijos recursivamente
	for child in node.get_children():
		if child is Node3D:
			_collect_mesh_bounds_to_array(child, bounds_array, current_transform)

# === MODO PREVIEW ===

func enable_preview_mode():
	"""Habilitar modo preview con controles interactivos"""
	preview_active = true
	controls_help_label.visible = true
	status_label.text = "🎬 Preview activo - Usa controles de cámara y modelo"
	
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
	
	# Iniciar animación por defecto
	_start_default_animation()
	
	emit_signal("preview_enabled")
	print("🎬 Preview mode activado con delegación completa")

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

# === CONTROL DE ANIMACIONES CON LOOPS (100% SINCRÓNICO) ===

# Cargar el gestor de loops
var loop_manager = preload("res://scripts/core/animation_loop_manager.gd")

func play_animation(animation_name: String):
	"""CORREGIDO: Reproducir animación usando el MISMO AnimationPlayer que AnimationControls"""
	if not animation_player:
		print("❌ No hay AnimationPlayer disponible")
		return
	
	if not animation_player.has_animation(animation_name):
		print("❌ Animación no encontrada: %s" % animation_name)
		return
	
	print("🎭 PREVIEW: Cambiando a animación: %s" % animation_name)
	status_label.text = "🔄 Cambiando animación..."
	
	# Usar el cambio limpio sincrónico
	var success = loop_manager.change_animation_clean(animation_player, animation_name)
	
	if success:
		status_label.text = "🔄 Reproduciendo en loop: " + animation_name
		emit_signal("animation_playing", animation_name)
		print("✅ PREVIEW: Animación iniciada en loop: %s" % animation_name)
	else:
		status_label.text = "❌ Error al cambiar animación"
		print("❌ PREVIEW: Error al cambiar animación: %s" % animation_name)

func stop_animation():
	"""Detener animación actual completamente"""
	if animation_player:
		loop_manager.stop_animation_clean(animation_player)
		status_label.text = "⏹️ Animación detenida"
		print("⏹️ PREVIEW: Animación detenida completamente")

func _start_default_animation():
	"""Iniciar primera animación disponible con loop"""
	if not animation_player:
		return
	
	# Configurar todas las animaciones para loop infinito
	loop_manager.setup_infinite_loops(animation_player)
	
	var animations = animation_player.get_animation_list()
	if animations.size() > 0:
		var first_animation = animations[0]
		print("🎭 PREVIEW: Iniciando animación por defecto con loop: %s" % first_animation)
		# Usar call_deferred para evitar conflictos de inicialización
		call_deferred("_play_first_animation", first_animation)

func _play_first_animation(animation_name: String):
	"""Helper para reproducir primera animación de forma diferida"""
	if animation_player and animation_player.has_animation(animation_name):
		# Usar el método limpio sincrónico
		loop_manager.change_animation_clean(animation_player, animation_name)

func toggle_pause_animation():
	"""Pausar/reanudar animación manteniendo el loop"""
	if not animation_player:
		return
	
	var is_playing = loop_manager.toggle_pause_with_loop(animation_player)
	
	if is_playing:
		status_label.text = "▶️ Reproduciendo en loop: " + animation_player.current_animation
	else:
		status_label.text = "⏸️ Pausado: " + animation_player.current_animation

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
		print("🧭 Norte relativo configurado: %.1f°" % angle)

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
	print("📷 Cámara lista para preview")

func _on_north_changed(new_angle: float):
	"""Callback cuando cambia el Norte relativo"""
	print("🧭 Norte relativo actualizado: %.1f°" % new_angle)

func _on_model_rotated(rotation_angle: float):
	"""Callback cuando el usuario rota el modelo"""
	print("🔄 Modelo rotado por usuario: %.1f°" % rotation_angle)

# === FUNCIONES PÚBLICAS ===

func get_current_model() -> Node3D:
	"""Obtener modelo actual"""
	return current_model

func has_model() -> bool:
	"""Verificar si hay modelo cargado"""
	return current_model != null

func get_animation_player() -> AnimationPlayer:
	"""Obtener AnimationPlayer del modelo"""
	return animation_player

func is_preview_active() -> bool:
	"""Verificar si preview está activo"""
	return preview_active

func reset_camera_view():
	"""Resetear vista de cámara usando CameraController"""
	if current_model and camera_controller and camera_controller.has_method("setup_for_model"):
		var bounds = _calculate_model_bounds_corrected(current_model)
		camera_controller.setup_for_model(bounds)
		print("🔄 Vista reseteada via CameraController")

# === DEBUGGING ===

func debug_preview_state():
	"""Imprimir estado completo para debugging"""
	print("\n=== PREVIEW PANEL DEBUG (CORREGIDO - Modelo Original) ===")
	print("Model loaded: %s" % (current_model != null))
	print("Animation player: %s" % (animation_player != null))
	print("Preview active: %s" % preview_active)
	print("CameraController: %s" % (camera_controller != null))
	print("ModelRotator: %s" % (model_rotator != null))
	
	if current_model:
		print("Model name: %s" % current_model.name)
		print("Model position: %s" % str(current_model.position))
		print("Model is original: %s" % (not current_model.name.begins_with("Preview_")))
	
	if animation_player:
		print("Available animations: %s" % str(animation_player.get_animation_list()))
		print("Current animation: %s" % animation_player.current_animation)
		print("Is playing: %s" % animation_player.is_playing())
	
	# Debug de componentes especializados
	if camera_controller and camera_controller.has_method("debug_camera_state"):
		camera_controller.debug_camera_state()
	
	if model_rotator and model_rotator.has_method("debug_rotation_state"):
		model_rotator.debug_rotation_state()
	
	print("========================================================\n")
