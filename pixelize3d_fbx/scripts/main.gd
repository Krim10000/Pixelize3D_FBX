# scripts/main.gd
extends Node

# Input: Carpeta seleccionada por el usuario con archivos FBX
# Output: Controla el flujo principal de la aplicación

signal fbx_loaded(base_model)
signal animation_loaded(animation_name)
signal rendering_complete()
signal export_complete(output_path)

@onready var ui_controller = $UIController
@onready var fbx_loader = $FBXLoader
@onready var animation_manager = $AnimationManager
@onready var sprite_renderer = $SpriteRenderer
@onready var export_manager = $ExportManager

var current_project_data = {
	"folder_path": "",
	"base_fbx": "",
	"selected_animations": [],
	"render_settings": {
		"directions": 16, # 16 o 32
		"sprite_size": 256,
		"camera_angle": 45.0,
		"camera_height": 10.0,
		"camera_distance": 15.0,
		"fps": 12,
		"background_color": Color(0, 0, 0, 0)
	},
	"loaded_base": null,
	"loaded_animations": {}
}

# NUEVA VARIABLE: Timer para actualizaciones de preview
var preview_update_timer: Timer

func _ready():
	# Configurar la aplicación para modo standalone
	get_window().title = "Pixelize3D FBX - Sprite Generator"
	get_window().size = Vector2i(1280, 720)
	
	# Conectar señales
	_connect_signals()
	
	# Inicializar UI
	ui_controller.initialize()

func _connect_signals():
	# Señales de UI
	ui_controller.folder_selected.connect(_on_folder_selected)
	ui_controller.base_fbx_selected.connect(_on_base_fbx_selected)
	ui_controller.animations_selected.connect(_on_animations_selected)
	ui_controller.render_settings_changed.connect(_on_render_settings_changed)
	ui_controller.render_requested.connect(_on_render_requested)
	
	# NUEVAS SEÑALES: Controles de preview
	ui_controller.preview_play_requested.connect(_on_preview_play)
	ui_controller.preview_pause_requested.connect(_on_preview_pause)
	ui_controller.preview_stop_requested.connect(_on_preview_stop)
	
	# Señales de carga
	fbx_loader.model_loaded.connect(_on_model_loaded)
	fbx_loader.load_failed.connect(_on_load_failed)
	
	# Señales de renderizado
	sprite_renderer.frame_rendered.connect(_on_frame_rendered)
	sprite_renderer.animation_complete.connect(_on_animation_complete)
	
	# Señales de exportación
	export_manager.export_complete.connect(_on_export_complete)
	export_manager.export_failed.connect(_on_export_failed)

func _on_folder_selected(path: String):
	current_project_data.folder_path = path
	
	# Escanear archivos FBX en la carpeta
	var fbx_files = _scan_for_fbx_files(path)
	ui_controller.display_fbx_list(fbx_files)

func _scan_for_fbx_files(folder_path: String) -> Array:
	var files = []
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".fbx") or file_name.ends_with(".FBX"):
				files.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

func _on_base_fbx_selected(filename: String):
	current_project_data.base_fbx = filename
	var full_path = current_project_data.folder_path.path_join(filename)
	
	print("Archivo base seleccionado: %s" % filename)
	print("Ruta completa: %s" % full_path)
	
	# Cargar el modelo base
	ui_controller.show_loading_message("Cargando modelo base: " + filename)
	fbx_loader.load_base_model(full_path)

func _on_model_loaded(model_data: Dictionary):
	if model_data.type == "base":
		current_project_data.loaded_base = model_data
		emit_signal("fbx_loaded", model_data)
		ui_controller.hide_loading_message()
		ui_controller.enable_animation_selection()
		
		print("Modelo base cargado exitosamente:")
		print("- Skeleton: %s" % (model_data.skeleton.name if model_data.skeleton else "NULL"))
		
		# Verificar si existe antes de acceder
		var bone_count = model_data.get("bone_count", 0)
		print("- Huesos: %d" % bone_count)
		
		var mesh_count = model_data.get("meshes", []).size()
		print("- Meshes: %d" % mesh_count)
		
		# Mostrar información de meshes
		for mesh_data in model_data.get("meshes", []):
			print("Mesh encontrado: %s" % mesh_data.name)
		
		# Extraer lista de meshes del modelo base
		var skeleton = _find_skeleton(model_data.node)
		if skeleton:
			var mesh_list = animation_manager.extract_enhanced_mesh_data(skeleton)
			animation_manager.set_base_meshes(mesh_list)
		else:
			print("❌ No se encontró skeleton para extraer mesh data")
			animation_manager.set_base_meshes([])
		# Advertir si no hay huesos
		if bone_count == 0:
			print("⚠️  ADVERTENCIA: El skeleton no tiene huesos!")
			ui_controller.show_error("El modelo base no tiene estructura de huesos válida. Verifica la importación del FBX.")
		
	elif model_data.type == "animation":
		current_project_data.loaded_animations[model_data.name] = model_data
		emit_signal("animation_loaded", model_data.name)
		
		print("Animación cargada: %s" % model_data.name)
		print("- Animaciones disponibles: %d" % model_data.animations.size())
		for anim in model_data.animations:
			print("  * %s (%.2fs)" % [anim.name, anim.length])
		
		# Verificar si todo está listo para preview
		_check_and_activate_preview()

func _extract_mesh_list(node: Node3D) -> Array:
	var meshes = []
	
	# Buscar Skeleton3D
	var skeleton = _find_skeleton(node)
	if skeleton:
		# Obtener todas las MeshInstance3D dentro del Skeleton3D
		for child in skeleton.get_children():
			if child is MeshInstance3D:
				meshes.append({
					"mesh": child.mesh,
					"material": child.get_surface_override_material(0),
					"name": child.name
				})
	
	return meshes

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func _on_animations_selected(animation_files: Array):
	current_project_data.selected_animations = animation_files
	
	print("Animaciones seleccionadas: %s" % str(animation_files))
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		var full_path = current_project_data.folder_path.path_join(anim_file)
		print("Cargando animación: %s" % full_path)
		fbx_loader.load_animation_fbx(full_path, anim_file)

func _check_and_activate_preview():
	print("--- VERIFICANDO ESTADO PARA PREVIEW ---")
	
	var base_loaded = current_project_data.loaded_base != null
	var animations_loaded = current_project_data.loaded_animations.size()
	var animations_selected = current_project_data.selected_animations.size()
	
	print("Base cargado: %s" % base_loaded)
	print("Animaciones cargadas: %d" % animations_loaded)
	print("Animaciones seleccionadas: %d" % animations_selected)
	
	# Verificar que tenemos todo lo necesario
	if (base_loaded and animations_loaded > 0 and animations_selected > 0):
		print("✅ Todo listo - Activando preview...")
		_activate_preview_mode()
	else:
		print("⏳ Esperando más datos para activar preview...")

func _activate_preview_mode():
	print("🎬 ACTIVANDO PREVIEW MODE")
	
	# Obtener primera animación cargada
	var first_anim_name = current_project_data.loaded_animations.keys()[0]
	var first_anim_data = current_project_data.loaded_animations[first_anim_name]
	
	print("Combinando para preview: %s" % first_anim_name)
	
	# Debug de datos antes de combinar
	animation_manager.debug_combination(current_project_data.loaded_base, first_anim_data)
	
	var combined_model = animation_manager.combine_base_with_animation(
		current_project_data.loaded_base,
		first_anim_data
	)
	
	if combined_model:
		print("✅ Modelo combinado exitosamente - Configurando preview")
		
		# Configurar preview en sprite renderer
		sprite_renderer.setup_preview(combined_model)
		
		# NUEVA LÍNEA: Conectar viewports para preview en tiempo real
		if _connect_preview_viewports():
			print("✅ Preview viewports conectados correctamente")
			_setup_preview_update_timer()
		else:
			print("⚠️ Problemas al conectar viewports, usando método de respaldo")
			_setup_fallback_preview()
		
		# Notificar a UI que el preview está listo
		ui_controller.enable_preview_mode()
		
		print("🎬 Preview activado completamente!")
	else:
		print("❌ Error al combinar modelo para preview")
		ui_controller.show_error("No se pudo combinar el modelo para preview. Revisa la consola para detalles.")

# NUEVA FUNCIÓN: Conectar viewports para preview en tiempo real
func _connect_preview_viewports() -> bool:
	print("📺 CONECTANDO SUBVIEWPORT PARA ANIMACIÓN EN TIEMPO REAL")
	
	# Obtener referencia al SubViewport del SpriteRenderer
	var sprite_renderer_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if not sprite_renderer_viewport:
		print("❌ ERROR: SubViewport del SpriteRenderer no encontrado")
		return false
	
	print("✅ SubViewport del SpriteRenderer encontrado: %s" % sprite_renderer_viewport.name)
	
	# Enviar textura inicial a UI
	var viewport_texture = sprite_renderer_viewport.get_texture()
	if viewport_texture:
		print("✅ Textura obtenida del viewport: %s" % str(viewport_texture.get_size()))
		ui_controller.set_preview_texture(viewport_texture)
		print("✅ Textura enviada a UIController.set_preview_texture()")
	else:
		print("❌ No se pudo obtener textura del viewport")
		return false
	
	return true

# NUEVA FUNCIÓN: Configurar timer para actualizaciones de preview
func _setup_preview_update_timer():
	print("⚡ CONFIGURANDO ACTUALIZACIONES EN TIEMPO REAL")
	
	# Crear timer si no existe
	if not preview_update_timer:
		preview_update_timer = Timer.new()
		preview_update_timer.name = "PreviewUpdateTimer"
		add_child(preview_update_timer)
	
	# Configurar timer
	preview_update_timer.wait_time = 1.0 / 30.0  # 30 FPS para preview
	preview_update_timer.timeout.connect(_update_preview_texture)
	preview_update_timer.start()
	
	print("✅ Timer de actualización configurado a 30 FPS")

# NUEVA FUNCIÓN: Actualizar textura de preview periódicamente
#func _update_preview_texture():
	#var sprite_renderer_viewport = sprite_renderer.get_node_or_null("SubViewport")
	#if sprite_renderer_viewport and ui_controller:
		#var texture = sprite_renderer_viewport.get_texture()
		#if texture:
			#ui_controller.set_preview_texture(texture)

func _update_preview_texture():
	"""Actualizar textura de preview con forzado de renderizado"""
	var sprite_renderer_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if sprite_renderer_viewport and ui_controller:
		# CRÍTICO: Forzar actualización del viewport antes de capturar
		sprite_renderer_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		sprite_renderer_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		# Ahora capturar la textura actualizada
		var texture = sprite_renderer_viewport.get_texture()
		if texture:
			ui_controller.set_preview_texture(texture)

# NUEVA FUNCIÓN: Método de respaldo para preview
func _setup_fallback_preview():
	print("🔄 CONFIGURANDO PREVIEW DE RESPALDO")
	
	var viewport = sprite_renderer.get_node("SubViewport")
	if viewport:
		# Crear timer para actualizar textura periódicamente
		var fallback_timer = Timer.new()
		fallback_timer.wait_time = 1.0 / 15.0  # 15 FPS para respaldo
		fallback_timer.autostart = true
		add_child(fallback_timer)
		
		fallback_timer.timeout.connect(_update_fallback_preview.bind(viewport))
		print("✅ Preview de respaldo configurado")

func _update_fallback_preview(viewport: SubViewport):
	if viewport and ui_controller:
		var texture = viewport.get_texture()
		if texture:
			ui_controller.set_preview_texture(texture)

# NUEVAS FUNCIONES: Controles de preview
func _on_preview_play():
	print("▶️ PREVIEW PLAY")
	if sprite_renderer.has_method("_on_preview_play"):
		sprite_renderer._on_preview_play()

func _on_preview_pause():
	print("⏸️ PREVIEW PAUSE")
	if sprite_renderer.has_method("_on_preview_pause"):
		sprite_renderer._on_preview_pause()

func _on_preview_stop():
	print("⏹️ PREVIEW STOP")
	if sprite_renderer.has_method("stop_preview"):
		sprite_renderer.stop_preview()
	
	# Detener timer de actualización
	if preview_update_timer:
		preview_update_timer.stop()

func _on_render_settings_changed(settings: Dictionary):
	current_project_data.render_settings.merge(settings, true)
	
	# Actualizar preview si está activo
	if ui_controller.is_preview_active():
		sprite_renderer.update_camera_settings(settings)

func _on_render_requested():
	if not _validate_project_data():
		ui_controller.show_error("Datos del proyecto incompletos")
		return
	
	# Iniciar proceso de renderizado
	ui_controller.show_progress_dialog()
	_start_rendering_process()

func _validate_project_data() -> bool:
	return (
		current_project_data.loaded_base != null and
		current_project_data.selected_animations.size() > 0 and
		current_project_data.loaded_animations.size() > 0
	)

func _start_rendering_process():
	var total_tasks = current_project_data.selected_animations.size() * current_project_data.render_settings.directions
	var current_task = 0
	
	sprite_renderer.initialize(current_project_data.render_settings)
	
	for anim_name in current_project_data.selected_animations:
		if anim_name in current_project_data.loaded_animations:
			var anim_data = current_project_data.loaded_animations[anim_name]
			
			# Combinar modelo base con animación
			var combined_model = animation_manager.combine_base_with_animation(
				current_project_data.loaded_base,
				anim_data
			)
			
			# Renderizar en todas las direcciones
			for direction in range(current_project_data.render_settings.directions):
				var angle = (360.0 / current_project_data.render_settings.directions) * direction
				
				sprite_renderer.render_animation(
					combined_model,
					anim_name,
					angle,
					direction
				)
				
				current_task += 1
				ui_controller.update_progress(float(current_task) / float(total_tasks))

func _on_frame_rendered(frame_data: Dictionary):
	# Acumular frames para el spritesheet
	export_manager.add_frame(frame_data)

func _on_animation_complete(animation_name: String):
	# Exportar spritesheet de esta animación
	var output_path = current_project_data.folder_path.path_join("exports")
	export_manager.export_spritesheet(animation_name, output_path)

func _on_export_complete(file_path: String):
	emit_signal("export_complete", file_path)
	ui_controller.add_export_log("Exportado: " + file_path)

func _on_export_failed(error: String):
	ui_controller.show_error("Error en exportación: " + error)

func _on_load_failed(error: String):
	ui_controller.show_error("Error al cargar FBX: " + error)
	ui_controller.hide_loading_message()

# Función para salir de la aplicación
func _on_quit_requested():
	get_tree().quit()

# FUNCIÓN DE UTILIDAD: Buscar nodos por nombre
func _find_node_by_name(parent: Node, target_name: String) -> Node:
	if parent.name == target_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	
	return null
