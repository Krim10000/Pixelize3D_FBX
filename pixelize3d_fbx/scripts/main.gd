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

# NUEVA función para verificar y activar preview
#func _check_and_activate_preview():
	#print("--- VERIFICANDO ESTADO PARA PREVIEW ---")
	#print("Base cargado: %s" % (current_project_data.loaded_base != null))
	#print("Animaciones cargadas: %d" % current_project_data.loaded_animations.size())
	#print("Animaciones seleccionadas: %d" % current_project_data.selected_animations.size())
	#
	## Verificar que tenemos todo lo necesario
	#if (current_project_data.loaded_base != null and 
		#current_project_data.loaded_animations.size() > 0 and
		#not current_project_data.selected_animations.is_empty()):
		#
		#print("✅ Todo listo - Activando preview...")
		#_activate_preview_mode()
	#else:
		#print("⏳ Esperando más datos para activar preview...")


# Modificación sugerida para main.gd
# Buscar la función _check_and_activate_preview y reemplazarla por esta versión:

func _check_and_activate_preview():
	print("--- VERIFICANDO ESTADO PARA PREVIEW ---")
	
	var base_loaded = current_project_data.loaded_base != null
	var animations_loaded = current_project_data.loaded_animations.size()
	var animations_selected = current_project_data.selected_animations.size()
	
	print("Base cargado: %s" % base_loaded)
	print("Animaciones cargadas: %d" % animations_loaded)
	print("Animaciones seleccionadas: %d" % animations_selected)
	
	# MODIFICACIÓN: Activar preview incluso sin animaciones (modo debug)
	if base_loaded:
		if animations_selected > 0:
			print("✅ Todo listo - Activando preview...")
			_activate_preview_mode()
		else:
			print("⚠️  Sin animaciones seleccionadas - Activando modo debug...")
			_activate_debug_preview_mode()
	else:
		print("⚠️  Esperando que se cargue el modelo base...")

# NUEVA FUNCIÓN: Activar preview normal con animaciones
#func _activate_preview_mode():
	#print("🎬 ACTIVANDO PREVIEW MODE")
	#ui_controller.set_preview_mode(true)
	#
	## Tomar la primera animación seleccionada
	#var selected_anim = current_project_data.selected_animations[0]
	#print("Combinando para preview: %s" % selected_anim)
	#
	## Combinar modelo base con animación
	#var base_data = current_project_data.loaded_base
	#var anim_data = current_project_data.loaded_animations[selected_anim]
	#
	## Debug de la combinación
	#animation_manager.debug_combination(base_data, anim_data)
	#
	## Realizar la combinación
	#var combined_model = animation_manager.combine_base_with_animation(base_data, anim_data)
	#
	#if combined_model:
		#print("✅ Modelo combinado exitosamente - Configurando preview")
		#sprite_renderer.setup_preview(combined_model, false)  # false = modo normal
		#print("🎬 Preview activado completamente!")
	#else:
		#print("❌ Error al combinar modelo - Activando modo debug")
		#sprite_renderer.setup_preview(null, true)  # true = modo debug

# NUEVA FUNCIÓN: Activar modo debug cuando no hay animaciones
func _activate_debug_preview_mode():
	print("🔴 ACTIVANDO PREVIEW MODE DEBUG")
	ui_controller.set_preview_mode(true)
	
	# Activar directamente el modo debug del sprite renderer
	sprite_renderer.setup_preview(null, true)  # null = sin modelo, true = modo debug
	
	print("🔴 Preview debug activado - Deberías ver objetos de prueba")

# OPCIONAL: Función para forzar modo debug desde UI
func force_debug_preview():
	print("🔴 FORZANDO MODO DEBUG DESDE UI")
	sprite_renderer.setup_preview(null, true)

# OPCIONAL: Función para activar preview con modelo base solamente
func preview_base_model_only():
	if current_project_data.loaded_base:
		print("📱 ACTIVANDO PREVIEW SOLO CON MODELO BASE")
		ui_controller.set_preview_mode(true)
		
		# Usar el modelo base sin animaciones
		var base_data = current_project_data.loaded_base
		var model_node = base_data.node
		
		if model_node:
			# Crear una copia del nodo base para preview
			var preview_model = model_node.duplicate()
			sprite_renderer.setup_preview(preview_model, false)
			print("📱 Preview del modelo base activado")
		else:
			print("❌ No se pudo acceder al nodo del modelo base")
			sprite_renderer.setup_preview(null, true)  # Fallback a modo debug
	else:
		print("❌ No hay modelo base cargado")
		sprite_renderer.setup_preview(null, true)  # Fallback a modo debug

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
		
		# Notificar a UI que el preview está listo
		ui_controller.enable_preview_mode()
		
		print("🎬 Preview activado completamente!")
	else:
		print("❌ Error al combinar modelo para preview")
		ui_controller.show_error("No se pudo combinar el modelo para preview. Revisa la consola para detalles.")

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
