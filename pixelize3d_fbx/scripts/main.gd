# scripts/main.gd
extends Node

# Input: Subcarpetas en res://assets/fbx/ con archivos FBX
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
	"selected_folder": "",
	"folder_path": "",
	"base_fbx": "",
	"selected_animations": [],
	"render_settings": {
		"directions": 16,
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

const FBX_ASSETS_PATH = "res://assets/fbx"

func _ready():
	# Configurar la aplicación para modo standalone
	get_window().title = "Pixelize3D FBX - Sprite Generator"
	get_window().size = Vector2i(1280, 720)
	
	# Conectar señales
	_connect_signals()
	
	# Inicializar UI y escanear carpetas
	ui_controller.initialize()
	_scan_fbx_folders()

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

func _scan_fbx_folders():
	"""Escanea las subcarpetas en res://assets/fbx/ y las muestra en la UI"""
	print("Escaneando carpetas en: " + FBX_ASSETS_PATH)
	
	# Verificar que la carpeta base existe
	if not DirAccess.dir_exists_absolute(FBX_ASSETS_PATH):
		ui_controller.show_error("La carpeta res://assets/fbx/ no existe")
		return
	
	var folders = _get_subdirectories(FBX_ASSETS_PATH)
	
	if folders.is_empty():
		ui_controller.add_export_log("No se encontraron subcarpetas en res://assets/fbx/")
		ui_controller.show_error("No hay subcarpetas en res://assets/fbx/\nImporta tus archivos FBX en subcarpetas.")
		return
	
	print("Encontradas %d carpetas: %s" % [folders.size(), str(folders)])
	ui_controller.display_folder_list(folders)

func _get_subdirectories(path: String) -> Array:
	"""Obtiene lista de subcarpetas en la ruta especificada"""
	var folders = []
	var dir = DirAccess.open(path)
	
	if not dir:
		push_error("No se pudo abrir directorio: " + path)
		return folders
	
	dir.list_dir_begin()
	var item_name = dir.get_next()
	
	while item_name != "":
		if dir.current_is_dir() and not item_name.begins_with("."):
			# Verificar que la carpeta tiene archivos FBX
			var folder_path = path.path_join(item_name)
			var fbx_files = _scan_fbx_files_in_folder(folder_path)
			
			if fbx_files.size() > 0:
				folders.append(item_name)
				print("Carpeta válida encontrada: %s (%d archivos FBX)" % [item_name, fbx_files.size()])
			else:
				print("Carpeta sin FBX ignorada: %s" % item_name)
		
		item_name = dir.get_next()
	
	dir.list_dir_end()
	return folders

func _scan_fbx_files_in_folder(folder_path: String) -> Array:
	"""Escanea archivos FBX en una carpeta específica"""
	var files = []
	var dir = DirAccess.open(folder_path)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".fbx") or file_name.ends_with(".FBX"):
				files.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

func _on_folder_selected(folder_name: String):
	"""Se llama cuando el usuario selecciona una carpeta"""
	current_project_data.selected_folder = folder_name
	current_project_data.folder_path = FBX_ASSETS_PATH.path_join(folder_name)
	
	print("Carpeta seleccionada: %s" % folder_name)
	print("Ruta completa: %s" % current_project_data.folder_path)
	
	# Escanear archivos FBX en la carpeta seleccionada
	var fbx_files = _scan_fbx_files_in_folder(current_project_data.folder_path)
	
	if fbx_files.is_empty():
		ui_controller.show_error("No se encontraron archivos FBX en la carpeta: " + folder_name)
		return
	
	print("Archivos FBX encontrados: %s" % str(fbx_files))
	ui_controller.display_fbx_list(fbx_files)
	ui_controller.add_export_log("Carpeta '%s' seleccionada (%d archivos FBX)" % [folder_name, fbx_files.size()])

func _on_base_fbx_selected(filename: String):
	"""Se llama cuando el usuario selecciona el archivo base"""
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
		print("- Skeleton: %s" % model_data.skeleton.name)
		print("- Huesos: %d" % model_data.bone_count)
		print("- Meshes: %d" % model_data.meshes.size())
		
		# Extraer lista de meshes del modelo base
		var mesh_list = _extract_mesh_list(model_data.node)
		animation_manager.set_base_meshes(mesh_list)
		
	elif model_data.type == "animation":
		current_project_data.loaded_animations[model_data.name] = model_data
		emit_signal("animation_loaded", model_data.name)
		
		print("Animación cargada: %s" % model_data.name)
		print("- Animaciones disponibles: %d" % model_data.animations.size())
		for anim in model_data.animations:
			print("  * %s (%.2fs)" % [anim.name, anim.length])

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
				print("Mesh encontrado: %s" % child.name)
	
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
	"""Se llama cuando el usuario selecciona animaciones"""
	current_project_data.selected_animations = animation_files
	
	print("Animaciones seleccionadas: %s" % str(animation_files))
	
	# Limpiar animaciones cargadas anteriormente
	current_project_data.loaded_animations.clear()
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		var full_path = current_project_data.folder_path.path_join(anim_file)
		print("Cargando animación: %s" % full_path)
		fbx_loader.load_animation_fbx(full_path, anim_file.get_basename())

func _on_render_settings_changed(settings: Dictionary):
	current_project_data.render_settings.merge(settings, true)
	
	# Actualizar preview si está activo
	if ui_controller.is_preview_active():
		sprite_renderer.update_camera_settings(settings)

func _on_render_requested():
	if not _validate_project_data():
		ui_controller.show_error("Datos del proyecto incompletos")
		return
	
	print("=== INICIANDO RENDERIZADO ===")
	print("Carpeta: %s" % current_project_data.selected_folder)
	print("Base: %s" % current_project_data.base_fbx)
	print("Animaciones: %s" % str(current_project_data.selected_animations))
	print("Configuración: %s" % str(current_project_data.render_settings))
	
	# Iniciar proceso de renderizado
	ui_controller.show_progress_dialog()
	_start_rendering_process()

func _validate_project_data() -> bool:
	var valid = (
		current_project_data.loaded_base != null and
		current_project_data.selected_animations.size() > 0 and
		current_project_data.loaded_animations.size() == current_project_data.selected_animations.size()
	)
	
	if not valid:
		print("Validación fallida:")
		print("- Base loaded: %s" % (current_project_data.loaded_base != null))
		print("- Animations selected: %d" % current_project_data.selected_animations.size())
		print("- Animations loaded: %d" % current_project_data.loaded_animations.size())
	
	return valid

func _start_rendering_process():
	var total_tasks = current_project_data.selected_animations.size() * current_project_data.render_settings.directions
	var current_task = 0
	
	print("Total de tasks a renderizar: %d" % total_tasks)
	
	sprite_renderer.initialize(current_project_data.render_settings)
	
	for anim_name in current_project_data.selected_animations:
		var anim_file_base = anim_name.get_basename()
		
		if anim_file_base in current_project_data.loaded_animations:
			var anim_data = current_project_data.loaded_animations[anim_file_base]
			
			print("Procesando animación: %s" % anim_file_base)
			
			# Combinar modelo base con animación
			var combined_model = animation_manager.combine_base_with_animation(
				current_project_data.loaded_base,
				anim_data
			)
			
			if not combined_model:
				ui_controller.show_error("Error al combinar modelo base con animación: " + anim_file_base)
				continue
			
			# Renderizar en todas las direcciones
			for direction in range(current_project_data.render_settings.directions):
				var angle = (360.0 / current_project_data.render_settings.directions) * direction
				
				print("Renderizando dirección %d/%d (ángulo %.1f°)" % [direction + 1, current_project_data.render_settings.directions, angle])
				
				sprite_renderer.render_animation(
					combined_model,
					anim_file_base,
					angle,
					direction
				)
				
				current_task += 1
				ui_controller.update_progress(float(current_task) / float(total_tasks))
		else:
			print("WARNING: Animación no cargada: %s" % anim_file_base)

func _on_frame_rendered(frame_data: Dictionary):
	# Acumular frames para el spritesheet
	export_manager.add_frame(frame_data)

func _on_animation_complete(animation_name: String):
	print("Animación completada: %s" % animation_name)
	
	# Exportar spritesheet de esta animación
	var output_path = current_project_data.folder_path.path_join("exports")
	export_manager.export_spritesheet(animation_name, output_path)

func _on_export_complete(file_path: String):
	emit_signal("export_complete", file_path)
	ui_controller.add_export_log("Exportado: " + file_path.get_file())

func _on_export_failed(error: String):
	ui_controller.show_error("Error en exportación: " + error)

func _on_load_failed(error: String):
	ui_controller.show_error("Error al cargar FBX: " + error)
	ui_controller.hide_loading_message()

# Función para salir de la aplicación
func _on_quit_requested():
	get_tree().quit()
