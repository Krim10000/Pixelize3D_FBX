# scripts/tools/project_templates.gd
extends Node

# Input: Tipo de plantilla solicitada
# Output: Proyecto de ejemplo generado con assets y código

signal template_generated(path: String)
signal template_error(error: String)

# Plantillas disponibles
const TEMPLATES = {
	"rts_basic": {
		"name": "RTS Básico",
		"description": "Proyecto básico de RTS con unidad de ejemplo",
		"includes": ["unit_controller", "camera_system", "selection_system"]
	},
	"tower_defense": {
		"name": "Tower Defense",
		"description": "Sistema de torre defense con enemigos animados",
		"includes": ["enemy_spawner", "tower_system", "path_following"]
	},
	"tactical_rpg": {
		"name": "RPG Táctico", 
		"description": "Sistema de combate por turnos estilo RPG táctico",
		"includes": ["grid_movement", "turn_system", "combat_system"]
	},
	"city_builder": {
		"name": "Constructor de Ciudades",
		"description": "Sistema de construcción con edificios isométricos",
		"includes": ["building_system", "resource_manager", "grid_placement"]
	}
}

func generate_template(template_type: String, output_path: String, unit_data: Dictionary = {}):
	if not template_type in TEMPLATES:
		emit_signal("template_error", "Plantilla no encontrada: " + template_type)
		return
	
	var template = TEMPLATES[template_type]
	print("Generando plantilla: " + template.name)
	
	# Crear estructura de carpetas
	_create_project_structure(output_path, template_type)
	
	# Generar archivos según el tipo
	match template_type:
		"rts_basic":
			_generate_rts_template(output_path, unit_data)
		"tower_defense":
			_generate_td_template(output_path, unit_data)
		"tactical_rpg":
			_generate_trpg_template(output_path, unit_data)
		"city_builder":
			_generate_city_builder_template(output_path, unit_data)
	
	# Generar archivos comunes
	_generate_common_files(output_path, template)
	
	emit_signal("template_generated", output_path)

func _create_project_structure(base_path: String, template_type: String):
	var folders = [
		"",
		"scenes",
		"scenes/units",
		"scenes/ui",
		"scenes/effects",
		"scripts",
		"scripts/units",
		"scripts/systems",
		"scripts/ui",
		"scripts/utils",
		"assets",
		"assets/sprites",
		"assets/sprites/units",
		"assets/sprites/terrain",
		"assets/sprites/ui",
		"assets/sounds",
		"assets/music"
	]
	
	for folder in folders:
		DirAccess.make_dir_recursive_absolute(base_path.path_join(folder))

func _generate_rts_template(path: String, unit_data: Dictionary):
	# Generar script de controlador de unidad RTS
	var unit_controller = """extends CharacterBody2D
class_name RTSUnit

# Configuración de sprites desde Pixelize3D
@export var sprite_data: Resource
@export var move_speed: float = 100.0
@export var rotation_speed: float = 5.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var selection_indicator: Node2D = $SelectionIndicator

var current_direction: int = 0
var target_position: Vector2
var is_selected: bool = false
var current_state: String = "idle"

# Direcciones para sprites isométricos
const DIRECTION_COUNT = %d
const DIRECTION_ANGLES = []

func _ready():
	# Inicializar ángulos de dirección
	for i in range(DIRECTION_COUNT):
		DIRECTION_ANGLES.append(i * (360.0 / DIRECTION_COUNT))
	
	# Configurar sprites si hay datos
	if sprite_data:
		_setup_sprites()
	
	# Ocultar indicador de selección
	selection_indicator.visible = false

func _setup_sprites():
	# Aquí se configurarían los sprites generados por Pixelize3D
	# El sprite_data contendría la información del spritesheet
	pass

func _physics_process(delta):
	if target_position.distance_to(global_position) > 5.0:
		# Mover hacia el objetivo
		var direction = (target_position - global_position).normalized()
		velocity = direction * move_speed
		
		# Actualizar dirección del sprite
		_update_sprite_direction(direction)
		
		# Cambiar a animación de caminar
		if current_state != "walk":
			_change_state("walk")
		
		move_and_slide()
	else:
		# Detenerse en el objetivo
		velocity = Vector2.ZERO
		if current_state != "idle":
			_change_state("idle")

func _update_sprite_direction(movement_direction: Vector2):
	# Convertir dirección de movimiento a índice de sprite
	var angle = rad_to_deg(movement_direction.angle())
	if angle < 0:
		angle += 360
	
	# Encontrar la dirección más cercana
	var closest_dir = 0
	var min_diff = 360.0
	
	for i in range(DIRECTION_COUNT):
		var diff = abs(angle - DIRECTION_ANGLES[i])
		if diff < min_diff:
			min_diff = diff
			closest_dir = i
	
	current_direction = closest_dir
	_update_sprite_animation()

func _change_state(new_state: String):
	current_state = new_state
	_update_sprite_animation()

func _update_sprite_animation():
	var anim_name = "%s_dir%d" % [current_state, current_direction]
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func move_to(position: Vector2):
	target_position = position

func select():
	is_selected = true
	selection_indicator.visible = true

func deselect():
	is_selected = false
	selection_indicator.visible = false

func attack_target(target: Node2D):
	# Implementar sistema de ataque
	target_position = global_position # Detenerse
	_change_state("attack")
	
	# Orientarse hacia el objetivo
	var direction = (target.global_position - global_position).normalized()
	_update_sprite_direction(direction)
""" % [unit_data.get("directions", 16)]
	
	_save_script(path.path_join("scripts/units/rts_unit.gd"), unit_controller)
	
	# Generar sistema de selección
	var selection_system = """extends Node2D
class_name SelectionSystem

signal units_selected(units: Array)
signal units_deselected()

var selection_box: ReferenceRect
var start_pos: Vector2
var is_selecting: bool = false
var selected_units: Array = []

func _ready():
	# Crear caja de selección
	selection_box = ReferenceRect.new()
	selection_box.border_color = Color(0, 1, 0, 0.8)
	selection_box.border_width = 2.0
	selection_box.visible = false
	add_child(selection_box)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_selection(event.position)
			else:
				_end_selection()
	
	elif event is InputEventMouseMotion and is_selecting:
		_update_selection(event.position)
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and selected_units.size() > 0:
			_command_move(event.position)

func _start_selection(pos: Vector2):
	start_pos = pos
	is_selecting = true
	selection_box.visible = true
	selection_box.position = pos
	selection_box.size = Vector2.ZERO

func _update_selection(pos: Vector2):
	var rect_pos = Vector2(min(start_pos.x, pos.x), min(start_pos.y, pos.y))
	var rect_size = Vector2(abs(pos.x - start_pos.x), abs(pos.y - start_pos.y))
	
	selection_box.position = rect_pos
	selection_box.size = rect_size

func _end_selection():
	is_selecting = false
	selection_box.visible = false
	
	# Deseleccionar unidades anteriores
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.deselect()
	
	selected_units.clear()
	
	# Seleccionar nuevas unidades
	var selection_rect = Rect2(selection_box.position, selection_box.size)
	
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is RTSUnit:
			var unit_pos = unit.get_global_transform_with_canvas().origin
			if selection_rect.has_point(unit_pos):
				selected_units.append(unit)
				unit.select()
	
	if selected_units.size() > 0:
		emit_signal("units_selected", selected_units)
	else:
		emit_signal("units_deselected")

func _command_move(screen_pos: Vector2):
	var world_pos = get_global_mouse_position()
	
	# Formación simple en grid
	var formation_size = ceil(sqrt(selected_units.size()))
	var spacing = 50.0
	var offset = -Vector2(formation_size - 1, formation_size - 1) * spacing * 0.5
	
	var index = 0
	for unit in selected_units:
		if is_instance_valid(unit):
			var row = index / int(formation_size)
			var col = index % int(formation_size)
			var formation_offset = offset + Vector2(col, row) * spacing
			unit.move_to(world_pos + formation_offset)
			index += 1
"""
	
	_save_script(path.path_join("scripts/systems/selection_system.gd"), selection_system)
	
	# Generar cámara RTS
	var camera_system = """extends Camera2D
class_name RTSCamera

@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var edge_scroll_margin: int = 20
@export var enable_edge_scroll: bool = true

var is_panning: bool = false
var pan_start_pos: Vector2

func _ready():
	# Configurar cámara
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

func _process(delta):
	# Movimiento con teclado
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("camera_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("camera_right"):
		input_vector.x += 1
	if Input.is_action_pressed("camera_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("camera_down"):
		input_vector.y += 1
	
	# Movimiento por borde de pantalla
	if enable_edge_scroll:
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_size = get_viewport().size
		
		if mouse_pos.x < edge_scroll_margin:
			input_vector.x -= 1
		elif mouse_pos.x > screen_size.x - edge_scroll_margin:
			input_vector.x += 1
		
		if mouse_pos.y < edge_scroll_margin:
			input_vector.y -= 1
		elif mouse_pos.y > screen_size.y - edge_scroll_margin:
			input_vector.y += 1
	
	# Aplicar movimiento
	if input_vector.length() > 0:
		position += input_vector.normalized() * move_speed * delta * zoom.x

func _input(event):
	# Zoom con rueda del mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_pos = event.position
			else:
				is_panning = false
	
	# Pan con mouse medio
	elif event is InputEventMouseMotion and is_panning:
		var delta = (event.position - pan_start_pos) * zoom.x
		position -= delta
		pan_start_pos = event.position

func zoom_in():
	zoom = zoom * (1.0 + zoom_speed)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func zoom_out():
	zoom = zoom * (1.0 - zoom_speed)
	zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func focus_on_units(units: Array):
	if units.is_empty():
		return
	
	# Calcular centro de las unidades
	var center = Vector2.ZERO
	for unit in units:
		if is_instance_valid(unit):
			center += unit.global_position
	
	center /= units.size()
	
	# Mover cámara al centro
	position = center
"""
	
	_save_script(path.path_join("scripts/systems/rts_camera.gd"), camera_system)
	
	# Generar escena principal
	_generate_main_scene_rts(path)

func _generate_main_scene_rts(path: String):
	# Este sería el código para generar la escena principal
	# En un caso real, se crearía programáticamente o se copiaría una plantilla
	pass

func _generate_td_template(path: String, unit_data: Dictionary):
	# Tower Defense template
	var enemy_script = """extends PathFollow2D
class_name TDEnemy

@export var sprite_data: Resource
@export var health: int = 100
@export var speed: float = 50.0
@export var reward: int = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

signal enemy_died(reward: int)
signal enemy_reached_end()

var max_health: int

func _ready():
	max_health = health
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Configurar sprite
	if sprite_data:
		_setup_sprite()

func _setup_sprite():
	# Configurar con datos de Pixelize3D
	sprite.play("walk_dir0")

func _process(delta):
	# Mover a lo largo del camino
	progress += speed * delta
	
	# Actualizar dirección del sprite basado en la dirección del movimiento
	_update_sprite_direction()
	
	# Verificar si llegó al final
	if progress_ratio >= 1.0:
		emit_signal("enemy_reached_end")
		queue_free()

func _update_sprite_direction():
	# Calcular dirección basada en la tangente del camino
	var direction = Vector2.RIGHT.rotated(rotation)
	# Convertir a índice de sprite (simplificado)
	var angle = rad_to_deg(direction.angle())
	var dir_index = int((angle + 180) / 22.5) % 16
	
	var anim_name = "walk_dir%d" % dir_index
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func take_damage(amount: int):
	health -= amount
	health_bar.value = health
	
	# Efecto de daño
	sprite.modulate = Color.RED
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		die()

func die():
	emit_signal("enemy_died", reward)
	
	# Animación de muerte
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death_dir0"):
		sprite.play("death_dir0")
		await sprite.animation_finished
	
	queue_free()
"""
	
	_save_script(path.path_join("scripts/units/td_enemy.gd"), enemy_script)

func _generate_trpg_template(path: String, unit_data: Dictionary):
	# Tactical RPG template
	var grid_unit_script = """extends Node2D
class_name TacticalUnit

@export var sprite_data: Resource
@export var move_range: int = 3
@export var attack_range: int = 1
@export var health: int = 100
@export var damage: int = 20

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var grid_position: Vector2i
var is_player_unit: bool = true
var has_moved: bool = false
var has_acted: bool = false

signal unit_selected()
signal unit_moved(from: Vector2i, to: Vector2i)
signal unit_attacked(target: TacticalUnit)

func _ready():
	add_to_group("tactical_units")
	
	if sprite_data:
		_setup_sprite()

func _setup_sprite():
	# Configurar sprites de Pixelize3D
	sprite.play("idle_dir4") # Dirección frontal por defecto

func setup(grid_pos: Vector2i, is_player: bool):
	grid_position = grid_pos
	is_player_unit = is_player
	
	# Colorear según el equipo
	if not is_player:
		sprite.modulate = Color(1.0, 0.8, 0.8)

func get_movement_tiles() -> Array:
	# Calcular tiles alcanzables (Manhattan distance)
	var tiles = []
	
	for x in range(-move_range, move_range + 1):
		for y in range(-move_range, move_range + 1):
			if abs(x) + abs(y) <= move_range:
				var tile = grid_position + Vector2i(x, y)
				# Aquí se verificaría si el tile es válido
				tiles.append(tile)
	
	return tiles

func move_to(target_pos: Vector2i):
	var old_pos = grid_position
	grid_position = target_pos
	has_moved = true
	
	# Animar movimiento
	var tween = create_tween()
	tween.tween_property(self, "position", _grid_to_world(target_pos), 0.5)
	
	emit_signal("unit_moved", old_pos, target_pos)

func attack(target: TacticalUnit):
	has_acted = true
	
	# Orientarse hacia el objetivo
	_face_target(target.position)
	
	# Reproducir animación de ataque
	sprite.play("attack_dir4")
	await sprite.animation_finished
	
	# Aplicar daño
	target.take_damage(damage)
	
	sprite.play("idle_dir4")
	emit_signal("unit_attacked", target)

func take_damage(amount: int):
	health -= amount
	
	# Efecto de daño
	sprite.modulate = Color.RED
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	if health <= 0:
		die()

func die():
	sprite.play("death_dir4")
	await sprite.animation_finished
	queue_free()

func _face_target(target_pos: Vector2):
	var direction = (target_pos - position).normalized()
	var angle = rad_to_deg(direction.angle())
	
	# Convertir a 8 direcciones
	var dir_index = int((angle + 202.5) / 45) % 8
	# Aquí se actualizaría el sprite según la dirección

func reset_turn():
	has_moved = false
	has_acted = false
	sprite.modulate = Color.WHITE

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# Convertir coordenadas de grid a mundo
	var tile_size = 64
	return Vector2(grid_pos) * tile_size
"""
	
	_save_script(path.path_join("scripts/units/tactical_unit.gd"), grid_unit_script)

func _generate_city_builder_template(path: String, unit_data: Dictionary):
	# City Builder template
	var building_script = """extends Node2D
class_name Building

@export var sprite_data: Resource
@export var building_name: String = "Casa"
@export var size: Vector2i = Vector2i(1, 1)
@export var cost: Dictionary = {"madera": 10, "piedra": 5}
@export var production: Dictionary = {}
@export var requires_road: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

var grid_position: Vector2i
var is_placed: bool = false
var is_active: bool = false
var production_timer: float = 0.0

signal building_placed()
signal resources_produced(resources: Dictionary)

func _ready():
	add_to_group("buildings")
	
	if sprite_data:
		_setup_sprite()
	
	# Configurar área de colisión
	_setup_collision()

func _setup_sprite():
	# Usar sprite de Pixelize3D
	# Los edificios usualmente tienen una sola dirección
	if sprite_data and sprite_data.texture:
		sprite.texture = sprite_data.texture

func _setup_collision():
	var shape = RectangleShape2D.new()
	shape.size = Vector2(size) * 64 # Asumiendo tiles de 64x64
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)

func _process(delta):
	if is_placed and is_active and not production.is_empty():
		production_timer += delta
		
		if production_timer >= 5.0: # Producir cada 5 segundos
			_produce_resources()
			production_timer = 0.0

func place_at(grid_pos: Vector2i):
	grid_position = grid_pos
	position = Vector2(grid_pos) * 64
	is_placed = true
	
	# Verificar conexión a carretera si es necesario
	if requires_road:
		is_active = _check_road_connection()
	else:
		is_active = true
	
	emit_signal("building_placed")

func _check_road_connection() -> bool:
	# Verificar tiles adyacentes por carreteras
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for dir in directions:
		var check_pos = grid_position + dir
		# Aquí se verificaría si hay una carretera en check_pos
		pass
	
	return true # Placeholder

func _produce_resources():
	emit_signal("resources_produced", production)
	
	# Efecto visual de producción
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)

func can_afford(resources: Dictionary) -> bool:
	for resource in cost:
		if not resource in resources or resources[resource] < cost[resource]:
			return false
	return true

func get_info() -> Dictionary:
	return {
		"name": building_name,
		"cost": cost,
		"production": production,
		"requires_road": requires_road,
		"size": size
	}
"""
	
	_save_script(path.path_join("scripts/buildings/building.gd"), building_script)

func _generate_common_files(path: String, template: Dictionary):
	# Generar project.godot
	var project_config = """[application]

config/name="%s Example"
config/description="Ejemplo generado con Pixelize3D mostrando sprites isométricos"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.4")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720

[input]

camera_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
camera_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
camera_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194320,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
camera_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194322,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}

[rendering]

renderer/rendering_method="gl_compatibility"
""" % template.name
	
	_save_file(path.path_join("project.godot"), project_config)
	
	# Generar README
	var readme = """# %s - Ejemplo de Pixelize3D

Este proyecto fue generado automáticamente por Pixelize3D como ejemplo de %s.

## Características

- Sprites isométricos pre-renderizados en múltiples direcciones
- Sistema de %s funcional
- Código base listo para expandir

## Cómo usar

1. Abre el proyecto en Godot 4.4
2. Importa tus propios spritesheets generados con Pixelize3D
3. Actualiza las referencias de sprites en los scripts
4. Ejecuta la escena principal

## Estructura del proyecto

- `scenes/` - Escenas del juego
- `scripts/` - Scripts de lógica
- `assets/sprites/` - Lugar para tus spritesheets
- `assets/sounds/` - Efectos de sonido
- `assets/music/` - Música de fondo

## Personalización

Los scripts están diseñados para ser fácilmente modificables. Busca comentarios
que indican dónde conectar tus propios sprites de Pixelize3D.

## Créditos

Generado con Pixelize3D FBX Sprite Generator
""" % [template.name, template.description, template.name]
	
	_save_file(path.path_join("README.md"), readme)
	
	# Generar archivo de instrucciones de integración
	var integration_guide = """# Guía de Integración de Sprites

## Pasos para integrar tus sprites de Pixelize3D:

1. **Exportar sprites desde Pixelize3D**
   - Asegúrate de exportar con el mismo número de direcciones configurado en el template
   - Guarda los archivos PNG y JSON de metadata

2. **Importar en el proyecto**
   - Copia los archivos PNG a `assets/sprites/units/`
   - Copia los archivos JSON a la misma carpeta

3. **Configurar los sprites**
   - Abre el script de la unidad correspondiente
   - En la función `_setup_sprites()`, carga tu spritesheet
   - Usa la metadata JSON para configurar las animaciones

## Ejemplo de código:

```gdscript
func _setup_sprites():
	# Cargar spritesheet
	var texture = load("res://assets/sprites/units/mi_unidad_spritesheet.png")
	
	# Cargar metadata
	var file = FileAccess.open("res://assets/sprites/units/mi_unidad_metadata.json", FileAccess.READ)
	var metadata = JSON.parse_string(file.get_as_text())
	file.close()
	
	# Configurar SpriteFrames
	var frames = SpriteFrames.new()
	
	# Crear animaciones para cada dirección
	for dir_data in metadata.directions:
		for anim_name in ["idle", "walk", "attack"]:
			var full_anim_name = "%s_dir%d" % [anim_name, dir_data.index]
			frames.add_animation(full_anim_name)
			
			# Añadir frames...
	
	sprite.sprite_frames = frames
```

## Tips:

- Usa la misma nomenclatura de animaciones en todos tus sprites
- Mantén consistente el número de direcciones
- Considera el tamaño de los sprites para el rendimiento
"""
	
	_save_file(path.path_join("INTEGRATION_GUIDE.md"), integration_guide)

func _save_script(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
	else:
		push_error("No se pudo crear script: " + path)

func _save_file(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

# Función para listar plantillas disponibles
func get_available_templates() -> Array:
	var templates = []
	for key in TEMPLATES:
		var template = TEMPLATES[key].duplicate()
		template["id"] = key
		templates.append(template)
	return templates
