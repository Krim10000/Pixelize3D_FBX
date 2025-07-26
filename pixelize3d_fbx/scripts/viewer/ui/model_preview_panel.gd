# scripts/viewer/ui/model_preview_panel.gd
# Panel que usa los nodos existentes de la escena viewer_modular.tscn
# Input: Modelo 3D combinado con AnimationPlayer
# Output: Preview visual en el viewport existente

extends VBoxContainer

# Señales específicas de este panel
signal model_displayed(model: Node3D)
signal preview_enabled()
signal animation_playing(animation_name: String)

# Referencias a nodos existentes en la escena (se configuran en _ready)
var preview_label: Label
var status_label: Label
var viewport_container: SubViewportContainer
var preview_viewport: SubViewport
var model_container: Node3D
var camera_3d: Camera3D
var directional_light: DirectionalLight3D
var camera_controller: Node3D
var controls_help_label: Label

# Estado interno
var current_model: Node3D = null
var animation_player: AnimationPlayer = null
var preview_active: bool = false

func _ready():
	# Buscar y configurar nodos existentes
	_find_existing_nodes()
	_setup_ui_labels()

func _find_existing_nodes():
	print("🔍 Buscando nodos existentes en la escena...")
	
	# Buscar el viewport container (debe existir en la escena)
	viewport_container = get_node_or_null("ViewportContainer")
	if viewport_container:
		preview_viewport = viewport_container.get_node_or_null("SubViewport")
		if preview_viewport:
			model_container = preview_viewport.get_node_or_null("ModelContainer")
			camera_3d = preview_viewport.get_node_or_null("Camera3D")
			directional_light = preview_viewport.get_node_or_null("DirectionalLight3D")
			camera_controller = preview_viewport.get_node_or_null("CameraController")
	
	# Validar que encontramos todos los nodos necesarios
	if not model_container:
		print("❌ ERROR: No se encontró ModelContainer en la escena")
		return
	
	if not camera_3d:
		print("❌ ERROR: No se encontró Camera3D en la escena")
		return
	
	if not preview_viewport:
		print("❌ ERROR: No se encontró SubViewport en la escena")
		return
	
	print("✅ Nodos existentes encontrados:")
	print("  - ModelContainer: ", model_container.name)
	print("  - Camera3D: ", camera_3d.name)
	print("  - SubViewport: ", preview_viewport.name)
	print("  - CameraController: ", camera_controller.name if camera_controller != null else "NULL")
	print("  - DirectionalLight3D: ", directional_light.name if directional_light != null else "NULL")
	
	# Configurar viewport para que maneje input
	if viewport_container:
		viewport_container.mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_ui_labels():
	# Buscar labels existentes o crearlos si no existen
	preview_label = get_node_or_null("PreviewLabel")
	if not preview_label:
		preview_label = Label.new()
		preview_label.name = "PreviewLabel"
		add_child(preview_label)
		move_child(preview_label, 0)  # Mover al principio
	
	status_label = get_node_or_null("PreviewStatusLabel") 
	if not status_label:
		status_label = Label.new()
		status_label.name = "PreviewStatusLabel"
		add_child(status_label)
		if preview_label:
			move_child(status_label, preview_label.get_index() + 1)
	
	# Configurar estilos
	preview_label.text = "🎬 Vista Previa del Modelo"
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	status_label.text = "Carga un modelo para ver preview"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Crear ayuda de controles si no existe
	controls_help_label = get_node_or_null("ControlsHelp")
	if not controls_help_label:
		controls_help_label = Label.new()
		controls_help_label.name = "ControlsHelp"
		add_child(controls_help_label)
	
	controls_help_label.text = "🎮 Click+Arrastrar=Rotar | Rueda=Zoom | Clic medio=Pan"
	controls_help_label.add_theme_font_size_override("font_size", 10)
	controls_help_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_help_label.visible = false

func set_model(model: Node3D):
	print("🎬 MODEL_PREVIEW_PANEL: Configurando modelo - ", model.name if model != null else "NULL")
	
	if not model_container:
		print("❌ ERROR: ModelContainer no disponible")
		return
	
	# Limpiar modelo anterior
	if current_model:
		model_container.remove_child(current_model)
		current_model.queue_free()
		current_model = null
		animation_player = null
	
	if not model:
		status_label.text = "No hay modelo cargado"
		return
	
	# Duplicar el modelo para el preview
	current_model = model.duplicate()
	model_container.add_child(current_model)
	
	# Buscar AnimationPlayer
	animation_player = _find_animation_player(current_model)
	
	# Centrar y enfocar el modelo usando los bounds CORRECTOS
	_center_and_focus_model()
	
	# Actualizar status
	status_label.text = "✅ Modelo cargado: " + current_model.name
	
	# Emitir señal
	emit_signal("model_displayed", current_model)
	
	print("✅ Modelo configurado en preview usando nodos existentes")

func enable_preview_mode():
	preview_active = true
	controls_help_label.visible = true
	status_label.text = "🎬 Preview activo - Usa controles de cámara"
	
	# Habilitar CameraController si existe
	if camera_controller and camera_controller.has_method("enable_preview_mode"):
		camera_controller.enable_preview_mode()
		print("✅ CameraController habilitado")
	
	# Comenzar animación si existe
	_start_default_animation()
	
	emit_signal("preview_enabled")
	print("🎬 Preview mode activado")

func play_animation(animation_name: String):
	if not animation_player:
		print("❌ No hay AnimationPlayer disponible")
		return
	
	if not animation_player.has_animation(animation_name):
		print("❌ Animación no encontrada: ", animation_name)
		return
	
	print("▶️ Reproduciendo animación: ", animation_name)
	animation_player.play(animation_name)
	status_label.text = "▶️ Reproduciendo: " + animation_name
	emit_signal("animation_playing", animation_name)

func stop_animation():
	if animation_player:
		animation_player.stop()
		status_label.text = "⏹️ Animación detenida"
		print("⏹️ Animación detenida")

func _center_and_focus_model():
	if not current_model or not camera_3d:
		return
	
	print("🎯 Centrando y enfocando modelo...")
	
	# Calcular bounds del modelo usando método CORREGIDO
	var bounds = _calculate_model_bounds_fixed(current_model)
	print("  Bounds calculados CORRECTOS: ", bounds)
	
	# Centrar el modelo en el origen
	var center_offset = -bounds.get_center()
	current_model.position = center_offset
	print("  Modelo centrado con offset: ", center_offset)
	
	# Configurar cámara para ver todo el modelo
	var model_size = bounds.size.length()
	var distance = max(model_size * 2.0, 5.0)
	
	# Posicionar cámara básica si no hay CameraController
	if not camera_controller or not camera_controller.has_method("setup_for_model"):
		camera_3d.position = Vector3(distance * 0.7, distance * 0.5, distance * 0.7)
		camera_3d.look_at(Vector3.ZERO, Vector3.UP)
		print("  Cámara posicionada manualmente a distancia: %.2f" % distance)
	else:
		# Usar CameraController si está disponible
		if camera_controller.has_method("setup_for_model"):
			camera_controller.setup_for_model(bounds)
			print("  CameraController configurado para modelo")

func _calculate_model_bounds_fixed(model: Node3D) -> AABB:
	"""
	Método CORREGIDO para calcular bounds que SÍ encuentra los meshes
	"""
	var bounds = AABB()
	var meshes_found = 0
	
	print("  🔍 Buscando meshes en modelo...")
	
	# Buscar todos los MeshInstance3D recursivamente
	meshes_found = _collect_mesh_bounds_recursive(model, bounds, 0, Transform3D.IDENTITY)
	
	if meshes_found == 0:
		print("  ⚠️ No se encontraron MeshInstance3D, usando bounds por defecto")
		bounds = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	else:
		print("  ✅ Bounds calculados de %d meshes: %s" % [meshes_found, bounds])
	
	return bounds

func _collect_mesh_bounds_recursive(node: Node3D, bounds: AABB, meshes_found: int, parent_transform: Transform3D) -> int:
	"""
	Función recursiva que SÍ encuentra los meshes correctamente
	"""
	var current_transform = parent_transform * node.transform
	
	# Si este nodo es un MeshInstance3D con mesh válido
	if node is MeshInstance3D and node.mesh:
		var mesh_bounds = node.get_aabb()
		# Transformar bounds al espacio del modelo
		var global_bounds = current_transform * mesh_bounds
		
		if meshes_found == 0:
			bounds = global_bounds
		else:
			bounds = bounds.merge(global_bounds)
		
		meshes_found += 1
		print("    ✅ Mesh #%d: %s - Bounds: %s" % [meshes_found, node.name, global_bounds])
	
	# Procesar todos los hijos
	for child in node.get_children():
		if child is Node3D:
			meshes_found = _collect_mesh_bounds_recursive(child, bounds, meshes_found, current_transform)
	
	return meshes_found

func _start_default_animation():
	if not animation_player:
		return
	
	var animations = animation_player.get_animation_list()
	if animations.size() > 0:
		var first_animation = animations[0]
		print("🎭 Iniciando animación por defecto: ", first_animation)
		animation_player.play(first_animation)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

# Funciones públicas
func get_current_model() -> Node3D:
	return current_model

func has_model() -> bool:
	return current_model != null

func get_animation_player() -> AnimationPlayer:
	return animation_player

func is_preview_active() -> bool:
	return preview_active

# Función para resetear la vista (usa CameraController si existe)
func reset_camera_view():
	if current_model and camera_controller and camera_controller.has_method("setup_for_model"):
		var bounds = _calculate_model_bounds_fixed(current_model)
		camera_controller.setup_for_model(bounds)
		print("🔄 Vista de cámara reseteada via CameraController")
	elif current_model and camera_3d:
		_center_and_focus_model()
		print("🔄 Vista de cámara reseteada manualmente")

# Debug info
func debug_preview_state():
	print("\n=== PREVIEW PANEL DEBUG (Nodos Existentes) ===")
	print("Model loaded: ", current_model != null)
	print("Animation player: ", animation_player != null)
	print("Preview active: ", preview_active)
	print("ModelContainer: ", model_container != null)
	print("Camera3D: ", camera_3d != null)
	print("CameraController: ", camera_controller != null)
	print("SubViewport: ", preview_viewport != null)
	if current_model:
		print("Model name: ", current_model.name)
		print("Model position: ", current_model.position)
	if animation_player:
		print("Available animations: ", animation_player.get_animation_list())
		print("Current animation: ", animation_player.current_animation)
		print("Is playing: ", animation_player.is_playing())
	print("=============================================\n")
