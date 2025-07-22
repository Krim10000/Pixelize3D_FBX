# scripts/main.gd
extends Node

# Input: Archivos FBX importados en Godot desde res://assets/fbx/
# Output: Controla el flujo principal con archivos ya importados

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

func _ready():
	# Configurar la aplicación para modo standalone
	get_window().title = "Pixelize3D FBX - Sprite Generator"
	get_window().size = Vector2i(1280, 720)
	
	# Conectar señales
	_connect_signals()
	
	# Verificar estructura de directorios
	_ensure_directory_structure()
	
	# Inicializar UI
	ui_controller.initialize()

func _ensure_directory_structure():
	# Crear estructura de directorios necesaria
	var directories = [
		"res://assets/",
		"res://assets/fbx/",
		"res://exports/"
	]
	
	for dir_path in directories:
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	# Crear archivo README en assets/fbx si no existe
	var readme_path = "res://assets/fbx/README.txt"
	if not FileAccess.file_exists(readme_path):
		_create_fbx_readme()

func _create_fbx_readme():
	var readme_content = """PIXELIZE3D FBX - ESTRUCTURA DE CARPETAS
=====================================

Organiza tus archivos FBX usando esta estructura:

res://assets/fbx/
├── soldier/
│   ├── soldier_base.fbx      # Modelo con meshes y skeleton
│   ├── soldier_idle.fbx      # Animación idle
│   ├── soldier_walk.fbx      # Animación caminar
│   └── soldier_attack.fbx    # Animación atacar
├── archer/
│   ├── archer_base.fbx
│   └── archer_shoot.fbx
└── mage/
	├── mage_base.fbx
	└── mage_cast.fbx

IMPORTANTE:
- El archivo "_base.fbx" debe contener meshes + skeleton
- Los archivos de animación deben contener solo animaciones
- Los nombres de huesos deben coincidir entre archivos
- Godot importará automáticamente los archivos FBX

NOTA: Después de añadir archivos, haz clic en "🔄 Refrescar Lista"
"""
	
	var file = FileAccess.open("res://assets/fbx/README.txt", FileAccess.WRITE)
	if file:
		file.store_string(readme_content)
		file.close()

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
	ui_controller.add_export_log("[color=cyan]📁 Carpeta de proyecto: " + path.get_file() + "[/color]")

func _on_base_fbx_selected(filename: String):
	current_project_data.base_fbx = filename
	var full_path = current_project_data.folder_path.path_join(filename)
	
	# Validar el archivo FBX antes de cargar
	if not _validate_base_fbx(full_path):
		ui_controller.show_error("El archivo FBX seleccionado no es válido como modelo base")
		return
	
	# Cargar el modelo base
	ui_controller.show_loading_message("Cargando modelo base: " + filename)
	fbx_loader.load_base_model(full_path)

func _validate_base_fbx(fbx_path: String) -> bool:
	# Validar que el archivo existe y está importado
	var resource = load(fbx_path)
	if not resource or not resource is PackedScene:
		ui_controller.add_export_log("[color=red]❌ Archivo no importado correctamente: " + fbx_path + "[/color]")
		return false
	
	# Instanciar para validar estructura
	var instance = resource.instantiate()
	if not instance:
		ui_controller.add_export_log("[color=red]❌ No se pudo instanciar: " + fbx_path + "[/color]")
		return false
	
	# Verificar que tiene Skeleton3D
	var skeleton = _find_node_recursive(instance, func(node): return node is Skeleton3D)
	if not skeleton:
		ui_controller.add_export_log("[color=red]❌ No se encontró Skeleton3D en: " + fbx_path + "[/color]")
		instance.queue_free()
		return false
	
	# Verificar que tiene meshes (para modelo base)
	var has_meshes = false
	for child in skeleton.get_children():
		if child is MeshInstance3D and child.mesh:
			has_meshes = true
			break
	
	if not has_meshes:
		ui_controller.add_export_log("[color=orange]⚠️ Advertencia: No se encontraron meshes en el modelo base[/color]")
	
	instance.queue_free()
	return true

func _validate_animation_fbx(fbx_path: String) -> bool:
	# Similar a _validate_base_fbx pero para archivos de animación
	var resource = load(fbx_path)
	if not resource or not resource is PackedScene:
		return false
	
	var instance = resource.instantiate()
	if not instance:
		return false
	
	# Verificar que tiene Skeleton3D
	var skeleton = _find_node_recursive(instance, func(node): return node is Skeleton3D)
	if not skeleton:
		instance.queue_free()
		return false
	
	# Verificar que tiene AnimationPlayer
	var anim_player = _find_node_recursive(instance, func(node): return node is AnimationPlayer)
	if not anim_player:
		ui_controller.add_export_log("[color=orange]⚠️ Advertencia: No se encontró AnimationPlayer en: " + fbx_path + "[/color]")
		instance.queue_free()
		return true # No es crítico para archivos de animación
	
	# Verificar que tiene animaciones
	if anim_player.get_animation_list().is_empty():
		ui_controller.add_export_log("[color=orange]⚠️ Advertencia: No se encontraron animaciones en: " + fbx_path + "[/color]")
	
	instance.queue_free()
	return true

func _find_node_recursive(node: Node, condition: Callable) -> Node:
	if condition.call(node):
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, condition)
		if result:
			return result
	
	return null

func _on_model_loaded(model_data: Dictionary):
	if model_data.type == "base":
		current_project_data.loaded_base = model_data
		emit_signal("fbx_loaded", model_data)
		ui_controller.hide_loading_message()
		ui_controller.add_export_log("[color=green]✅ Modelo base cargado: " + model_data.name + "[/color]")
		ui_controller.add_export_log("[color=gray]   Huesos: %d | Meshes: %d[/color]" % [
			model_data.bone_count, model_data.meshes.size()
		])
		
		# Extraer lista de meshes del modelo base
		var mesh_list = _extract_mesh_list(model_data.node)
		animation_manager.set_base_meshes(mesh_list)
		
	elif model_data.type == "animation":
		current_project_data.loaded_animations[model_data.name] = model_data
		emit_signal("animation_loaded", model_data.name)
		ui_controller.add_export_log("[color=green]✅ Animación cargada: " + model_data.name + "[/color]")
		ui_controller.add_export_log("[color=gray]   Animaciones: %d[/color]" % model_data.animations.size())

func _extract_mesh_list(node: Node3D) -> Array:
	var meshes = []
	
	# Buscar Skeleton3D
	var skeleton = _find_node_recursive(node, func(n): return n is Skeleton3D)
	if skeleton:
		# Obtener todas las MeshInstance3D dentro del Skeleton3D
		for child in skeleton.get_children():
			if child is MeshInstance3D and child.mesh:
				meshes.append({
					"mesh": child.mesh,
					"material": child.get_surface_override_material(0),
					"name": child.name
				})
	
	return meshes

func _on_animations_selected(animation_files: Array):
	current_project_data.selected_animations = animation_files
	
	# Validar y cargar cada animación seleccionada
	for anim_file in animation_files:
		var full_path = current_project_data.folder_path.path_join(anim_file)
		
		if _validate_animation_fbx(full_path):
			fbx_loader.load_animation_fbx(full_path, anim_file.get_basename())
		else:
			ui_controller.add_export_log("[color=red]❌ Animación inválida: " + anim_file + "[/color]")

func _on_render_settings_changed(settings: Dictionary):
	current_project_data.render_settings.merge(settings, true)
	
	# Actualizar preview si está activo
	if ui_controller.is_preview_active():
		sprite_renderer.update_camera_settings(settings)

func _on_render_requested():
	if not _validate_project_data():
		ui_controller.show_error("Datos del proyecto incompletos. Asegúrate de seleccionar modelo base y animaciones.")
		return
	
	# Verificar compatibilidad de huesos
	if not _validate_bone_compatibility():
		ui_controller.show_error("Incompatibilidad de huesos entre modelo base y animaciones.")
		return
	
	# Iniciar proceso de renderizado
	ui_controller.show_progress_dialog()
	ui_controller.add_export_log("[color=cyan]🎯 Iniciando proceso de renderizado...[/color]")
	_start_rendering_process()

func _validate_project_data() -> bool:
	var valid = (
		current_project_data.loaded_base != null and
		current_project_data.selected_animations.size() > 0 and
		current_project_data.loaded_animations.size() > 0
	)
	
	if not valid:
		ui_controller.add_export_log("[color=red]❌ Validación fallida:[/color]")
		if current_project_data.loaded_base == null:
			ui_controller.add_export_log("[color=red]   - No hay modelo base cargado[/color]")
		if current_project_data.selected_animations.size() == 0:
			ui_controller.add_export_log("[color=red]   - No hay animaciones seleccionadas[/color]")
		if current_project_data.loaded_animations.size() == 0:
			ui_controller.add_export_log("[color=red]   - No hay animaciones cargadas[/color]")
	
	return valid

func _validate_bone_compatibility() -> bool:
	# Verificar que los huesos del modelo base coinciden con las animaciones
	var base_skeleton = current_project_data.loaded_base.skeleton
	if not base_skeleton:
		return false
	
	var base_bones = []
	for i in range(base_skeleton.get_bone_count()):
		base_bones.append(base_skeleton.get_bone_name(i))
	
	for anim_name in current_project_data.loaded_animations:
		var anim_data = current_project_data.loaded_animations[anim_name]
		var anim_skeleton = anim_data.skeleton
		
		if anim_skeleton:
			var anim_bones = []
			for i in range(anim_skeleton.get_bone_count()):
				anim_bones.append(anim_skeleton.get_bone_name(i))
			
			# Verificar que los huesos principales coinciden
			for bone in base_bones:
				if not bone in anim_bones:
					ui_controller.add_export_log("[color=red]❌ Hueso '%s' no encontrado en animación '%s'[/color]" % [bone, anim_name])
					return false
	
	ui_controller.add_export_log("[color=green]✅ Compatibilidad de huesos verificada[/color]")
	return true

func _start_rendering_process():
	var total_animations = current_project_data.selected_animations.size()
	var total_directions = current_project_data.render_settings.directions
	var total_tasks = total_animations * total_directions
	var current_task = 0
	
	ui_controller.add_export_log("[color=cyan]📊 Total a renderizar: %d animaciones × %d direcciones = %d renders[/color]" % [
		total_animations, total_directions, total_tasks
	])
	
	sprite_renderer.initialize(current_project_data.render_settings)
	
	for anim_name in current_project_data.selected_animations:
		var anim_file_name = anim_name.get_basename() if anim_name.ends_with(".fbx") else anim_name
		
		if anim_file_name in current_project_data.loaded_animations:
			var anim_data = current_project_data.loaded_animations[anim_file_name]
			
			ui_controller.add_export_log("[color=yellow]🔄 Procesando: " + anim_name + "[/color]")
			
			# Combinar modelo base con animación
			var combined_model = animation_manager.combine_base_with_animation(
				current_project_data.loaded_base,
				anim_data
			)
			
			if not combined_model:
				ui_controller.add_export_log("[color=red]❌ Error combinando modelo con animación: " + anim_name + "[/color]")
				continue
			
			# Renderizar en todas las direcciones
			for direction in range(current_project_data.render_settings.directions):
				var angle = (360.0 / current_project_data.render_settings.directions) * direction
				
				sprite_renderer.render_animation(
					combined_model,
					anim_file_name,
					angle,
					direction
				)
				
				current_task += 1
				var progress = float(current_task) / float(total_tasks)
				var message = "Renderizando %s - Dirección %d/%d" % [
					anim_name, direction + 1, current_project_data.render_settings.directions
				]
				ui_controller.update_progress(progress, message)

func _on_frame_rendered(frame_data: Dictionary):
	# Acumular frames para el spritesheet
	export_manager.add_frame(frame_data)

func _on_animation_complete(animation_name: String):
	# Exportar spritesheet de esta animación
	var output_path = current_project_data.folder_path.path_join("../../../exports")
	DirAccess.make_dir_recursive_absolute(output_path)
	
	export_manager.export_spritesheet(animation_name, output_path)
	ui_controller.add_export_log("[color=green]✅ Renderizado completo: " + animation_name + "[/color]")

func _on_export_complete(file_path: String):
	emit_signal("export_complete", file_path)
	ui_controller.add_export_log("[color=green]💾 Exportado: " + file_path.get_file() + "[/color]")
	
	# Verificar si hemos terminado todo
	if export_manager.frames_collection.is_empty():
		_finish_rendering_process()

func _finish_rendering_process():
	ui_controller.hide_progress_dialog()
	ui_controller.add_export_log("[color=lime]🎉 ¡Proceso completado exitosamente![/color]")
	ui_controller.add_export_log("[color=cyan]📁 Revisa la carpeta 'exports' para los archivos generados[/color]")
	
	# Mostrar resumen
	var export_folder = current_project_data.folder_path.path_join("../../../exports")
	ui_controller.add_export_log("[color=gray]Ubicación: " + export_folder + "[/color]")

func _on_export_failed(error: String):
	ui_controller.show_error("Error en exportación: " + error)

func _on_load_failed(error: String):
	ui_controller.show_error("Error al cargar FBX: " + error)
	ui_controller.hide_loading_message()

# Función para salir de la aplicación
func _on_quit_requested():
	get_tree().quit()
