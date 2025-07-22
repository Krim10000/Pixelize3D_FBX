# scripts/main_scene_structure.gd
# Este script crea la estructura de nodos para la escena principal
extends Node

# Input: Ninguno
# Output: Escena principal configurada con todos los componentes

static func create_main_scene() -> PackedScene:
	var root = Node.new()
	root.name = "Main"
	root.set_script(preload("res://scripts/main.gd"))
	
	# Crear componentes principales
	var ui_controller = Control.new()
	ui_controller.name = "UIController"
	ui_controller.set_script(preload("res://scripts/ui/ui_controller.gd"))
	ui_controller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(ui_controller)
	
	var fbx_loader = Node.new()
	fbx_loader.name = "FBXLoader"
	fbx_loader.set_script(preload("res://scripts/core/fbx_loader.gd"))
	root.add_child(fbx_loader)
	
	var animation_manager = Node.new()
	animation_manager.name = "AnimationManager"
	animation_manager.set_script(preload("res://scripts/core/animation_manager.gd"))
	root.add_child(animation_manager)
	
	var sprite_renderer = Node3D.new()
	sprite_renderer.name = "SpriteRenderer"
	sprite_renderer.set_script(preload("res://scripts/rendering/sprite_renderer.gd"))
	root.add_child(sprite_renderer)
	
	# Crear SubViewport para el sprite renderer
	var sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.size = Vector2i(512, 512)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	sub_viewport.transparent_bg = true
	sprite_renderer.add_child(sub_viewport)
	
	# Crear camera controller dentro del viewport
	var camera_controller = Node3D.new()
	camera_controller.name = "CameraController"
	camera_controller.set_script(preload("res://scripts/rendering/camera_controller.gd"))
	sub_viewport.add_child(camera_controller)
	
	var export_manager = Node.new()
	export_manager.name = "ExportManager"
	export_manager.set_script(preload("res://scripts/export/export_manager.gd"))
	root.add_child(export_manager)
	
	# Guardar la escena
	var scene = PackedScene.new()
	scene.pack(root)
	
	return scene

# Script de utilidad para crear la estructura de carpetas del proyecto
static func setup_project_structure():
	var directories = [
		"res://scenes",
		"res://scenes/ui",
		"res://scenes/rendering",
		"res://scripts",
		"res://scripts/core",
		"res://scripts/rendering",
		"res://scripts/export",
		"res://scripts/ui",
		"res://resources",
		"res://resources/shaders",
		"res://resources/themes",
		"res://exports"
	]
	
	for dir in directories:
		DirAccess.make_dir_recursive_absolute(dir)
	
	print("Estructura de proyecto creada exitosamente")

# Función para validar que todos los scripts existen
static func validate_scripts() -> bool:
	var required_scripts = [
		"res://scripts/main.gd",
		"res://scripts/core/fbx_loader.gd",
		"res://scripts/core/animation_manager.gd",
		"res://scripts/rendering/camera_controller.gd",
		"res://scripts/rendering/sprite_renderer.gd",
		"res://scripts/export/export_manager.gd",
		"res://scripts/ui/ui_controller.gd"
	]
	
	var all_exist = true
	for script_path in required_scripts:
		if not FileAccess.file_exists(script_path):
			push_error("Script faltante: " + script_path)
			all_exist = false
	
	return all_exist

# Configuración inicial del proyecto
static func initialize_project():
	# Crear estructura de carpetas
	setup_project_structure()
	
	# Validar scripts
	if not validate_scripts():
		push_error("Faltan scripts requeridos. Por favor, asegúrate de que todos los archivos estén en su lugar.")
		return
	
	# Crear y guardar la escena principal
	var main_scene = create_main_scene()
	ResourceSaver.save(main_scene, "res://scenes/main.tscn")
	
	print("Proyecto inicializado correctamente")
	print("Puedes ejecutar la escena principal desde: res://scenes/main.tscn")
