# scripts/main.gd
extends Node

# Input: Carpeta seleccionada por el usuario con archivos FBX
# Output: Controla el flujo principal de la aplicación

signal fbx_loaded(base_model)
signal animation_loaded(animation_name)
# Señales utilizadas por el sistema de renderizado y exportación
signal rendering_complete() # Usada internamente por el sistema
signal export_complete(output_path) # Usada por export_manager

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
			var extension = file_name.get_extension().to_lower()
			if extension in ["fbx", "gltf", "glb"]:
				files.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

func _on_base_fbx_selected(filename: String):
	current_project_data.base_fbx = filename
	var full_path = current_project_data.folder_path.path_join(filename)
	
	# Cargar el modelo base
	ui_controller.show_loading_message("Cargando modelo base...")
	
	# Verificar si es GLTF/GLB (más fácil de cargar)
	if fbx_loader.is_gltf_file(full_path):
		fbx_loader.load_gltf_file(full_path, "base")
	else:
		fbx_loader.load_base_model(full_path)

func _on_model_loaded(model_data: Dictionary):
	if model_data.type == "base":
		current_project_data.loaded_base = model_data
		emit_signal("fbx_loaded", model_data)
		ui_controller.hide_loading_message()
		ui_controller.enable_animation_selection()
		
		# Extraer lista de meshes del modelo base
		var mesh_list = _extract_mesh_list(model_data.node)
		animation_manager.set_base_meshes(mesh_list)
		
	elif model_data.type == "animation":
		current_project_data.loaded_animations[model_data.name] = model_data
		emit_signal("animation_loaded", model_data.name)

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
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		var full_path = current_project_data.folder_path.path_join(anim_file)
		
		# Verificar si es GLTF/GLB
		if fbx_loader.is_gltf_file(full_path):
			fbx_loader.load_gltf_file(full_path, "animation", anim_file)
		else:
			fbx_loader.load_animation_fbx(full_path, anim_file)

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
	
	# Emitir señal de renderizado completo
	emit_signal("rendering_complete")

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
