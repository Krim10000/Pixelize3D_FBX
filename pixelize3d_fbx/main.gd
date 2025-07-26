extends Control

@onready var file_dialog = $FileDialog
@onready var viewport = $VBoxContainer/ViewportContainer/SubViewport
@onready var model_container = $VBoxContainer/ViewportContainer/SubViewport/ModelContainer
@onready var anim_option = $VBoxContainer/HBoxContainer/OptionButton
@onready var play_button = $VBoxContainer/HBoxContainer/Play
var current_model: Node3D = null
var animation_player: AnimationPlayer = null

func _ready():
	file_dialog.file_selected.connect(_on_file_selected)
	play_button.pressed.connect(_on_play_pressed)

func _on_load_pressed():
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	# Limpiar modelo anterior
	if current_model:
		model_container.remove_child(current_model)
		current_model.queue_free()
	
	# Cargar nuevo modelo
	var model_resource = load(path)
	if model_resource is PackedScene:
		current_model = model_resource.instantiate()
		model_container.add_child(current_model)
		
		# Buscar AnimationPlayer
		_find_animation_player(current_model)
		
		# Configurar controles
		_setup_animation_controls()

func _find_animation_player(node: Node):
	animation_player = null
	if node is AnimationPlayer:
		animation_player = node
		return
	
	for child in node.get_children():
		_find_animation_player(child)
		
	if animation_player == null:
		print("Advertencia: No se encontró AnimationPlayer en el modelo")

func _setup_animation_controls():
	anim_option.clear()
	play_button.disabled = true
	
	if animation_player:
		var animations = animation_player.get_animation_list()
		if animations.size() > 0:
			play_button.disabled = false
			for anim in animations:
				anim_option.add_item(anim)

func _on_play_pressed():
	if animation_player and anim_option.selected >= 0:
		var anim_name = anim_option.get_item_text(anim_option.selected)
		animation_player.play(anim_name)

func _on_stop_pressed():
	if animation_player:
		animation_player.stop()
