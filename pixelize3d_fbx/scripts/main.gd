# pixelize3d_fbx/scripts/main.gd
# Script principal corregido para incluir orientación norte y exploración correcta de assets/fbx/
# Input: Exploración automática de res://assets/fbx/ y selección por checkboxes
# Output: Controla el flujo principal de la aplicación con orientación coherente

extends Node

signal fbx_loaded(base_model)
signal animation_loaded(animation_name)
signal rendering_complete()
signal export_complete(output_path)

@onready var ui_controller = $UIController
@onready var fbx_loader = $FBXLoader
@onready var animation_manager = $AnimationManager
@onready var sprite_renderer = $SpriteRenderer
@onready var export_manager = $ExportManager

# NUEVO: ViewportConnector para manejar conexión de viewports
var viewport_connector: Node

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
		"background_color": Color(0, 0, 0, 0),
		# Orientación norte del modelo (en grados)
		"north_offset": 0.0  # 0° = Norte por defecto, 90° = Este, 180° = Sur, 270° = Oeste
	},
	"loaded_base": null,
	"loaded_animations": {},
	# NUEVO: Datos de carpetas escaneadas
	"scanned_folders": {},
	"available_units": []
}

func _ready():
	print("🔧 CONFIGURANDO VIEWPORT CON CORRECCIONES")
	
	# Configurar la aplicación para modo standalone
	get_window().title = "Pixelize3D FBX - Sprite Generator"
	get_window().size = Vector2i(1280, 720)
	
	# Crear y configurar ViewportConnector
	_setup_viewport_connector()
	
	# Conectar señales
	_connect_signals()
	
	# Inicializar UI
	ui_controller.initialize()
	
	# NUEVO: Escanear carpetas del proyecto automáticamente
	_scan_project_folders()

# NUEVO: Configurar ViewportConnector
func _setup_viewport_connector():
	print("🔧 CONFIGURANDO CONEXIÓN DE VIEWPORTS")
	
	# Crear ViewportConnector si no existe
	viewport_connector = preload("res://scripts/debug/viewport_connection_fix.gd").new()
	viewport_connector.name = "ViewportConnector"
	add_child(viewport_connector)
	
	print("✅ ViewportConnector añadido")

# NUEVO: Escanear carpetas del proyecto
func _scan_project_folders():
	print("🔍 ESCANEANDO CARPETAS DE PROYECTO")
	
	var assets_fbx_path = "res://assets/fbx/"
	var dir = DirAccess.open(assets_fbx_path)
	
	if not dir:
		print("❌ No se encontró la carpeta res://assets/fbx/")
		ui_controller.show_error("No se encontró la carpeta res://assets/fbx/")
		return
	
	var found_units = []
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			var unit_path = assets_fbx_path.path_join(folder_name)
			var unit_data = _scan_unit_folder(unit_path, folder_name)
			
			if not unit_data.is_empty():
				found_units.append(unit_data)
				current_project_data.scanned_folders[folder_name] = unit_data
		
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	current_project_data.available_units = found_units
	
	if found_units.size() > 0:
		print("✅ Encontradas %d unidades en assets/fbx/" % found_units.size())
		ui_controller.display_available_units(found_units)
	else:
		print("⚠️ No se encontraron carpetas con archivos FBX en assets/fbx/")
		ui_controller.show_error("No se encontraron unidades en res://assets/fbx/")

# NUEVO: Escanear carpeta de unidad específica
func _scan_unit_folder(folder_path: String, unit_name: String) -> Dictionary:
	var fbx_files = []
	var sub_dir = DirAccess.open(folder_path)
	
	if not sub_dir:
		return {}
	
	sub_dir.list_dir_begin()
	var file_name = sub_dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".fbx") or file_name.ends_with(".FBX"):
			fbx_files.append(file_name)
		file_name = sub_dir.get_next()
	
	sub_dir.list_dir_end()
	
	if fbx_files.is_empty():
		return {}
	
	# Intentar identificar el archivo base automáticamente
	var base_file = ""
	var animations = []
	
	for file in fbx_files:
		var lower_name = file.to_lower()
		if "base" in lower_name or "mesh" in lower_name or "model" in lower_name:
			if base_file == "":
				base_file = file
		else:
			animations.append(file)
	
	# Si no se encontró un archivo base obvio, usar el primero
	if base_file == "" and fbx_files.size() > 0:
		base_file = fbx_files[0]
		animations = fbx_files.slice(1)
	
	return {
		"name": unit_name,
		"folder": folder_path,
		"base_file": base_file,
		"animations": animations,
		"all_fbx": fbx_files,
		"auto_detected": true
	}

func _connect_signals():
	# Señales de UI
	ui_controller.unit_selected.connect(_on_unit_selected)
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

# NUEVO: Manejar selección de unidad
func _on_unit_selected(unit_data: Dictionary):
	print("📁 Unidad seleccionada: %s" % unit_data.name)
	current_project_data.folder_path = unit_data.folder
	
	# Limpiar datos anteriores
	current_project_data.loaded_base = null
	current_project_data.loaded_animations.clear()
	current_project_data.selected_animations.clear()
	
	# Notificar a UI para que muestre los FBX de esta unidad
	ui_controller.display_unit_fbx_files(unit_data)

func _on_folder_selected(path: String):
	# Esta función se mantiene para compatibilidad, pero ahora usa el escaneo automático
	current_project_data.folder_path = path
	
	# Escanear archivos FBX en la carpeta (método legacy)
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
	
	# Cargar modelo base
	fbx_loader.load_base_model(full_path)

func _on_model_loaded(loaded_data: Dictionary):
	var file_type = loaded_data.get("file_type", "unknown")
	var model_name = loaded_data.get("name", "unknown")
	
	if file_type == "base":
		current_project_data.loaded_base = loaded_data
		ui_controller.enable_animation_selection()
		
		# Verificar si tenemos todo para activar preview
		_check_and_activate_preview()
		
	elif file_type == "animation":
		current_project_data.loaded_animations[model_name] = loaded_data
		print("Animación cargada: %s" % model_name)
		
		# Verificar si tenemos todo para activar preview
		_check_and_activate_preview()

func _find_node_by_name(parent: Node, node_name: String) -> Node:
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, node_name)
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

# Función para verificar y activar preview
func _check_and_activate_preview():
	print("--- VERIFICANDO ESTADO PARA PREVIEW ---")
	print("Base cargado: %s" % (current_project_data.loaded_base != null))
	print("Animaciones cargadas: %d" % current_project_data.loaded_animations.size())
	print("Animaciones seleccionadas: %d" % current_project_data.selected_animations.size())
	
	# Verificar que tenemos todo lo necesario
	if (current_project_data.loaded_base != null and 
		current_project_data.loaded_animations.size() > 0 and
		not current_project_data.selected_animations.is_empty()):
		
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
		
		# Configurar preview en sprite renderer con orientación norte
		sprite_renderer.setup_preview(combined_model, current_project_data.render_settings)
		
		# Conectar viewports usando el ViewportConnector
		if viewport_connector:
			viewport_connector.connect_preview_viewports()
		
		# Notificar a UI que el preview está listo
		ui_controller.enable_preview_mode()
		
		print("🎬 Preview activado completamente!")
	else:
		print("❌ Error al combinar modelo para preview")
		ui_controller.show_error("No se pudo combinar el modelo para preview. Revisa la consola para detalles.")

func _on_render_settings_changed(settings: Dictionary):
	# Agregar soporte para north_offset
	current_project_data.render_settings.merge(settings, true)
	
	# Debug de la configuración actualizada
	if settings.has("north_offset"):
		print("🧭 Orientación norte actualizada: %.1f°" % settings.north_offset)
	
	# Actualizar preview si está activo (incluyendo nueva orientación)
	if ui_controller.is_preview_active():
		sprite_renderer.update_camera_settings(current_project_data.render_settings)

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
			
			# Renderizar en todas las direcciones con orientación norte aplicada
			for direction in range(current_project_data.render_settings.directions):
				# Calcular ángulo base para esta dirección
				var base_angle = (360.0 / current_project_data.render_settings.directions) * direction
				
				# Aplicar offset de orientación norte
				var final_angle = base_angle + current_project_data.render_settings.get("north_offset", 0.0)
				
				# Debug ocasional para verificar ángulos
				if direction == 0:  # Solo mostrar para la primera dirección
					print("🧭 Dirección %d: ángulo base=%.1f°, offset=%.1f°, final=%.1f°" % [
						direction, base_angle, 
						current_project_data.render_settings.get("north_offset", 0.0), 
						final_angle
					])
				
				sprite_renderer.render_animation(
					combined_model,
					anim_name,
					final_angle,  # Usar ángulo con orientación aplicada
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
