# res://scripts/transition/Columna2_logic.gd
# Lógica de preview de animaciones para la Columna 2
# Input: Datos de animaciones desde Columna 1
# Output: Control de reproducción y actualización de viewports

extends Node
class_name Columna2Logic

# === SEÑALES HACIA EL COORDINADOR ===
signal preview_ready(preview_data: Dictionary)
signal playback_state_changed(animation_type: String, state: Dictionary)

# === REFERENCIAS ===
var coordinator: Node
var ui_node: Columna2UI

# === DATOS DE ANIMACIONES ===
var animation_a_data: Dictionary = {}
var animation_b_data: Dictionary = {}
var base_model_loaded:Dictionary={}
var animation_a_model: Node3D
var animation_b_model: Node3D
var animation_player_a: AnimationPlayer
var animation_player_b: AnimationPlayer

# === VIEWPORTS ===
var viewport_a: SubViewport
var viewport_b: SubViewport

# === ESTADO DE REPRODUCCIÓN ===
var playback_state_a: Dictionary = {
	"playing": false,
	"current_frame": 0,
	"total_frames": 0,
	"duration": 0.0,
	"animation_name": "",
	"loop_enabled": true
}

var playback_state_b: Dictionary = {
	"playing": false,
	"current_frame": 0,
	"total_frames": 0,
	"duration": 0.0,
	"animation_name": "",
	"loop_enabled": true
}

# === PROCESO DE ACTUALIZACIÓN ===
var update_timer: Timer

func _ready():
	print("🎬 Columna2Logic inicializando...")
	_setup_systems()
	_create_update_timer()
	print("✅ Columna2Logic listo")

func _setup_systems():
	"""Configurar referencias a sistemas"""
	# Buscar coordinador
	coordinator = get_parent()
	
	# Buscar UI node
	var columna2_container = get_node_or_null("../HSplitContainer/HSplitContainer/Columna2_Container")
	if columna2_container:
		ui_node = columna2_container.get_node_or_null("Columna2_UI")
		if ui_node:
			_connect_ui_signals()
			print("  ✅ UI conectada")

func _connect_ui_signals():
	"""Conectar señales de la UI"""
	if not ui_node:
		return
		
	ui_node.play_animation_a_requested.connect(_on_play_animation_a)
	ui_node.pause_animation_a_requested.connect(_on_pause_animation_a)
	ui_node.play_animation_b_requested.connect(_on_play_animation_b)
	ui_node.pause_animation_b_requested.connect(_on_pause_animation_b)
	
	print("  🔌 Señales UI conectadas")

func _create_update_timer():
	"""Crear timer para actualizar estados"""
	update_timer = Timer.new()
	update_timer.wait_time = 0.033  # ~30 FPS
	update_timer.timeout.connect(_update_playback_states)
	add_child(update_timer)

# ========================================================================
# API PRINCIPAL - CARGA DE DATOS
# ========================================================================

func load_animations_data(base_model_loaded:Dictionary, anim_a: Dictionary, anim_b: Dictionary):
	print("func load_animations_data")
	"""Cargar datos de animaciones desde Columna 1"""
	print("📥 Columna2Logic: Cargando datos de animaciones...")

	if animation_a_model and animation_b_model and is_instance_valid(animation_a_model) and is_instance_valid(animation_b_model):
		print("⚠️ Modelos ya cargados - ignorando llamada duplicada")
		return

	self.base_model_loaded=base_model_loaded
	print("ooooooooooooooooooooooooooooooooooooooooooooooooooo base_model_loaded")
	print(base_model_loaded)

	# Guardar datos
	animation_a_data = anim_a
	animation_b_data = anim_b
	
	# Obtener nombres de animación del array animations
	var anim_name_a = animation_a_data.name
	var anim_name_b = animation_b_data.name
		
	print("  📊 Datos recibidos:")
	print("    - Animación A: %s" % anim_name_a)
	print("    - Animación B: %s" % anim_name_b)

	
	# Configurar viewports
	_setup_viewports()
	
	# Crear modelos en viewports
	await _create_models_in_viewports()
	
	# Configurar estados de reproducción
	_configure_playback_states()
	
	# Actualizar UI
	if ui_node:
		ui_node.on_animations_loaded(animation_a_data, animation_b_data)
	
	# Notificar que el preview está listo
	emit_signal("preview_ready", {
		"animation_a_ready": animation_a_data != null,
		"animation_b_ready": animation_b_data != null
	})
	
	print("✅ Datos de animaciones cargados y configurados")

func _setup_viewports():
	"""Obtener referencias a los viewports desde la UI"""
	if ui_node:
		viewport_a = ui_node.get_viewport_a()
		viewport_b = ui_node.get_viewport_b()
		print("  🖼️ Viewports obtenidos de la UI")
		
		_configure_existing_cameras()
		
		# Verificar que los viewports tengan cámara y luz
		if viewport_a:
			var has_camera = false
			var has_light = false
			for child in viewport_a.get_children():
				if child is Camera3D:
					has_camera = true
				if child is DirectionalLight3D:
					has_light = true
			if not has_camera or not has_light:
				print("  ⚠️ Viewport A necesita cámara/luz - usando existentes de la escena")

func _create_models_in_viewports():
	"""Configurar modelos en los viewports existentes"""
	print("🎭 Configurando modelos en viewports...")
	
	# NO limpiar viewports - usar los existentes con sus cámaras y luces
	
	# Configurar viewport A
	if viewport_a:
		await _setup_viewport_with_model(viewport_a, animation_a_data, "A")
	
	# Configurar viewport B
	if viewport_b:
		await _setup_viewport_with_model(viewport_b, animation_b_data, "B")
	
	print("✅ Modelos configurados en viewports")

func _clear_viewport(viewport: SubViewport):
	"""Limpiar contenido de un viewport"""
	if not viewport:
		return
		
	for child in viewport.get_children():
		child.queue_free()

#func _setup_viewport_with_model(viewport: SubViewport, anim_data: Dictionary, id: String):
	#"""Agregar modelo al viewport existente sin modificar cámara y luz"""
	#print("func _setup_viewport_with_model")
	#print("viewport")
	#print(viewport)
	#print("anim_data")
	#print(anim_data)
	#print("id")
	#print(id)
#
	#
	#print("  🔧 Configurando modelo en viewport %s..." % id)
		#
	#await get_tree().process_frame
	#
	#var skeleton = anim_data.get("skeleton")
	#var skeleton_copy = skeleton.duplicate()
	#print("skeleton_copy")
	#print(skeleton_copy)
	#skeleton_copy.position = Vector3.ZERO
	#
	#var original_player = anim_data.get("animation_player")
	#var anim_player = original_player.duplicate()
	#anim_player.name = "AnimationPlayer_" + id
	#
	#var base_meshes = base_model_loaded.get("meshes", [])
	#for mesh_data in base_meshes:
		#var mesh_node = mesh_data.get("node") 
		#if mesh_node and is_instance_valid(mesh_node):
			#var mesh_copy = mesh_node.duplicate()
			#skeleton_copy.add_child(mesh_copy)
			#print("    ✅ Mesh copiado: %s" % mesh_copy.name)
	#
	#if id == "A":
#
		#var model_container = get_parent().get_node("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_A/LayoutContainer_A/SubViewportContainer_A/SubViewport_A/Model_A")
		#print("model_container_A")
		#print(model_container)
		#model_container.add_child(skeleton_copy)
		#print("    ✅ Skeleton_A agregado")
		#model_container.add_child(anim_player)
		#animation_a_model = model_container
		#animation_player_a = anim_player
		#animation_a_model.position = Vector3(0, 0, 0)
		#animation_a_model.scale = Vector3.ONE
		#_auto_center_and_orient_model(model_container, viewport)
		#print("    ✅ Modelo A configurado con AnimationPlayer")
	#else:
		##var model_container = find_child("/../../%Model_B")
		#var model_container = get_parent().get_node("HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_B/LayoutContainer_B/SubViewportContainer_B/SubViewport_B/Model_B")
		#print("model_container_B")
		#print(model_container)
		#model_container.add_child(skeleton_copy)
		#print("    ✅ Skeleton_B agregado")
		#model_container.add_child(anim_player)
		#animation_b_model = model_container
		#animation_player_b = anim_player
		#animation_b_model.position = Vector3(0, 0, 0)
		#animation_b_model.scale = Vector3.ONE
		#_auto_center_and_orient_model(model_container, viewport)
		#print("    ✅ Modelo B configurado con AnimationPlayer")
		#
	#
	#await get_tree().process_frame
#
	#print("oooooooooooooooooooooooooo anim_data_final")
	#print(anim_data)


# res://scripts/transition/Columna2_logic.gd  
# Función COMPLETAMENTE AISLADA para evitar que las animaciones se reproduzcan en ambos viewports
# Input: viewport, datos de animación, ID del modelo
# Output: Modelo completamente independiente con AnimationPlayer aislado

# res://scripts/transition/Columna2_logic.gd
# Función usando el AnimationManager existente que ya funciona correctamente
# Input: viewport, datos de animación, ID del modelo
# Output: Modelo funcional usando el sistema probado del proyecto

func _setup_viewport_with_model(viewport: SubViewport, anim_data: Dictionary, id: String):
	"""Configurar modelo usando el AnimationManager existente que ya funciona"""
	print("=== CONFIGURANDO MODELO CON ANIMATION_MANAGER %s ===" % id)
	
	if not viewport:
		print("❌ Viewport inválido")
		return
	
	await get_tree().process_frame
	
	# === OBTENER ANIMATION_MANAGER DEL SISTEMA EXISTENTE ===
	var animation_manager = _get_animation_manager()
	if not animation_manager:
		print("❌ AnimationManager no encontrado")
		return
	
	print("✅ AnimationManager encontrado: %s" % animation_manager.get_path())
	
	# === USAR LA FUNCIÓN QUE YA FUNCIONA EN TU PROYECTO ===
	var combined_model = animation_manager.combine_base_with_animation_for_transition(
		base_model_loaded, 
		anim_data
	)
	
	if not combined_model:
		print("❌ Error combinando modelo con AnimationManager")
		return
		
	print("✅ Modelo combinado creado: %s" % combined_model.name)
	
	# === DAR NOMBRE ÚNICO AL MODELO COMBINADO ===
	combined_model.name = "CombinedModel_" + id
	
	# === OBTENER CONTENEDOR Y AGREGAR MODELO ===
	var model_container = _get_model_container(id)
	if not model_container:
		print("❌ No se encontró contenedor para modelo %s" % id)
		return
	
	# Limpiar contenedor completamente
	_clear_model_container_completely(model_container)
	
	# Agregar el modelo combinado al contenedor
	model_container.add_child(combined_model)
	
	# === ENCONTRAR EL ANIMATIONPLAYER EN EL MODELO COMBINADO ===
	var animation_player = _find_animation_player_in_model(combined_model)
	if not animation_player:
		print("❌ No se encontró AnimationPlayer en modelo combinado")
		return
		
	print("✅ AnimationPlayer encontrado: %s" % animation_player.name)
	print("   Animaciones disponibles: %s" % animation_player.get_animation_list())
	
	# === CONFIGURAR REFERENCIAS GLOBALES ===
	if id == "A":
		animation_a_model = combined_model
		animation_player_a = animation_player
		print("✅ Referencias A configuradas")
	else:
		animation_b_model = combined_model
		animation_player_b = animation_player
		print("✅ Referencias B configuradas")
	
	# === CENTRAR MODELO ===
	_auto_center_and_orient_model(model_container, viewport)
	
	await get_tree().process_frame
	
	# === DEBUG FINAL ===
	print("=== MODELO %s CONFIGURADO CON ANIMATION_MANAGER ===" % id)
	#print("Modelo combinado: %s" % combined_model.get_path())
	#print("AnimationPlayer: %s" % animation_player.get_path())
	#print("Animaciones: %s" % animation_player.get_animation_list())
	#print("Modelo en contenedor: %s" % model_container.get_children())
	print("================================================")

func _get_animation_manager() -> Node:
	"""Obtener AnimationManager del sistema existente"""
	
	# Intentar múltiples rutas posibles
	var possible_paths = [
		"/root/Transition4ColsMain/Columna1_Logic/AnimationManager",
		"../Columna1_Logic/AnimationManager", 
		"/root/Transition4ColsMain/AnimationManager",
		"../AnimationManager"
	]
	
	for path in possible_paths:
		var manager = get_node_or_null(path)
		if manager:
			print("AnimationManager encontrado en: %s" % path)
			return manager
	
	# Si no se encuentra, buscar en el árbol
	var root = get_tree().current_scene
	return _find_animation_manager_recursive(root)

func _find_animation_manager_recursive(node: Node) -> Node:
	"""Buscar AnimationManager recursivamente en el árbol"""
	
	# Verificar si este nodo tiene los métodos característicos del AnimationManager
	if node.has_method("combine_base_with_animation_for_transition"):
		print("AnimationManager encontrado por método: %s" % node.get_path())
		return node
	
	# Buscar por nombre
	if node.name == "AnimationManager" or "AnimationManager" in node.name:
		print("AnimationManager encontrado por nombre: %s" % node.get_path())
		return node
	
	# Buscar en hijos
	for child in node.get_children():
		var found = _find_animation_manager_recursive(child)
		if found:
			return found
	
	return null

func _find_animation_player_in_model(model: Node3D) -> AnimationPlayer:
	"""Encontrar AnimationPlayer en el modelo combinado"""
	
	# Buscar directamente
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if anim_player:
		return anim_player
	
	# Buscar con nombres alternativos
	for child in model.get_children():
		if child is AnimationPlayer:
			return child
	
	# Buscar recursivamente
	return _find_animation_player_recursive(model)

func _find_animation_player_recursive(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer recursivamente"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player_recursive(child)
		if result:
			return result
	
	return null

func _get_model_container(id: String) -> Node3D:
	"""Obtener contenedor específico para el modelo"""
	var container_path: String
	
	if id == "A":
		container_path = "HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_A/LayoutContainer_A/SubViewportContainer_A/SubViewport_A/Model_A"
	else:
		container_path = "HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_B/LayoutContainer_B/SubViewportContainer_B/SubViewport_B/Model_B"
	
	return get_parent().get_node_or_null(container_path)

func _clear_model_container_completely(container: Node3D):
	"""Limpiar completamente el contenedor del modelo"""
	print("🧹 Limpiando contenedor: %s" % container.name)
	
	for child in container.get_children():
		if child is Node3D:
			print("    🗑️ Removiendo: %s" % child.name)
			child.queue_free()
	
	# Esperar que se liberen los nodos
	await get_tree().process_frame

# === FUNCIONES DE CONTROL USANDO EL SISTEMA EXISTENTE ===

func _on_play_animation_a():
	"""Reproducir animación A usando AnimationPlayer del modelo combinado"""
	print("▶ PLAY con AnimationManager - Animación A")
	
	if not animation_player_a or not is_instance_valid(animation_player_a):
		print("❌ AnimationPlayer A no disponible")
		return
	
	var anim_name = playback_state_a.animation_name
	if anim_name == "":
		# Intentar usar la primera animación disponible
		var available_animations = animation_player_a.get_animation_list()
		if available_animations.size() > 0:
			anim_name = available_animations[0]
			playback_state_a.animation_name = anim_name
			print("🔧 Usando primera animación disponible: %s" % anim_name)
		else:
			print("❌ No hay animaciones disponibles")
			return
	
	# Verificar que la animación existe
	if not animation_player_a.has_animation(anim_name):
		print("❌ Animación '%s' no encontrada" % anim_name)
		print("    Animaciones disponibles: %s" % animation_player_a.get_animation_list())
		return
	
	# Reproducir animación
	animation_player_a.stop()  # Detener cualquier animación previa
	animation_player_a.play(anim_name)
	playback_state_a.playing = true
	
	print("✅ Animación A iniciada: %s" % anim_name)
	print("    Estado reproducción: %s" % animation_player_a.is_playing())
	
	# Iniciar timer de actualización
	if not update_timer.is_stopped():
		update_timer.stop()
	update_timer.start()
	
	_emit_playback_state("animation_a")

func _on_play_animation_b():
	"""Reproducir animación B usando AnimationPlayer del modelo combinado"""
	print("▶ PLAY con AnimationManager - Animación B")
	
	if not animation_player_b or not is_instance_valid(animation_player_b):
		print("❌ AnimationPlayer B no disponible")
		return
	
	var anim_name = playback_state_b.animation_name
	if anim_name == "":
		# Intentar usar la primera animación disponible
		var available_animations = animation_player_b.get_animation_list()
		if available_animations.size() > 0:
			anim_name = available_animations[0]
			playback_state_b.animation_name = anim_name
			print("🔧 Usando primera animación disponible: %s" % anim_name)
		else:
			print("❌ No hay animaciones disponibles")
			return
	
	# Verificar que la animación existe
	if not animation_player_b.has_animation(anim_name):
		print("❌ Animación '%s' no encontrada" % anim_name)
		print("    Animaciones disponibles: %s" % animation_player_b.get_animation_list())
		return
	
	# Reproducir animación
	animation_player_b.stop()  # Detener cualquier animación previa
	animation_player_b.play(anim_name)
	playback_state_b.playing = true
	
	print("✅ Animación B iniciada: %s" % anim_name)
	print("    Estado reproducción: %s" % animation_player_b.is_playing())
	
	# Iniciar timer de actualización
	if not update_timer.is_stopped():
		update_timer.stop()
	update_timer.start()
	
	_emit_playback_state("animation_b")

# === CONFIGURACIÓN DE ESTADOS MEJORADA ===

func _configure_playback_states():
	"""Configurar estados de reproducción usando datos reales del AnimationPlayer"""
	print("func _configure_playback_states():")
	print("⚙️ Configurando estados de reproducción...")
	
	# Configurar estado A
	var anim_name_a = animation_a_data.get("display_name", "")
	if anim_name_a == "":
		anim_name_a = animation_a_data.get("name", "")
	
	print("anim_name_a: %s" % anim_name_a)
	
	if animation_player_a and anim_name_a != "":
		# Verificar qué animaciones tiene realmente el player
		var available_anims_a = animation_player_a.get_animation_list()
		print("AnimationPlayer A tiene: %s" % available_anims_a)
		
		# Buscar la animación correcta
		var final_anim_name_a = _find_matching_animation(available_anims_a, anim_name_a)
		
		playback_state_a.animation_name = final_anim_name_a
		print("playback_state_a.animation_name: %s" % playback_state_a.animation_name)
		
		# Obtener duración real
		if animation_player_a.has_animation(final_anim_name_a):
			var animation = animation_player_a.get_animation(final_anim_name_a)
			playback_state_a.duration = animation.length
			playback_state_a.total_frames = int(animation.length * 30)
	
	# Configurar estado B
	var anim_name_b = animation_b_data.get("display_name", "")
	if anim_name_b == "":
		anim_name_b = animation_b_data.get("name", "")
	
	print("anim_name_b: %s" % anim_name_b)
	
	if animation_player_b and anim_name_b != "":
		# Verificar qué animaciones tiene realmente el player
		var available_anims_b = animation_player_b.get_animation_list()
		print("AnimationPlayer B tiene: %s" % available_anims_b)
		
		# Buscar la animación correcta
		var final_anim_name_b = _find_matching_animation(available_anims_b, anim_name_b)
		
		playback_state_b.animation_name = final_anim_name_b
		print("playback_state_b.animation_name: %s" % playback_state_b.animation_name)
		
		# Obtener duración real
		if animation_player_b.has_animation(final_anim_name_b):
			var animation = animation_player_b.get_animation(final_anim_name_b)
			playback_state_b.duration = animation.length
			playback_state_b.total_frames = int(animation.length * 30)

func _find_matching_animation(available_animations: Array, target_name: String) -> String:
	"""Encontrar la animación que coincida con el nombre objetivo"""
	
	# Buscar coincidencia exacta primero
	for anim_name in available_animations:
		if anim_name == target_name:
			return anim_name
	
	# Buscar coincidencia parcial
	for anim_name in available_animations:
		if target_name in anim_name or anim_name in target_name:
			print("🔍 Coincidencia encontrada: '%s' -> '%s'" % [target_name, anim_name])
			return anim_name
	
	# Si no encuentra nada, usar la primera disponible
	if available_animations.size() > 0:
		print("🔍 Usando primera animación: %s" % available_animations[0])
		return available_animations[0]
	
	print("❌ No se encontraron animaciones")
	return ""


func _create_isolated_skeleton(original_skeleton: Skeleton3D, id: String) -> Skeleton3D:
	"""Crear skeleton completamente independiente con nombre único"""
	var isolated_skeleton = Skeleton3D.new()
	isolated_skeleton.name = "Skeleton3D_Isolated_" + id  # Nombre único crítico
	
	# Copiar estructura de huesos exacta
	for bone_idx in range(original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(bone_idx)
		var bone_parent = original_skeleton.get_bone_parent(bone_idx)
		var bone_rest = original_skeleton.get_bone_rest(bone_idx)
		var bone_pose = original_skeleton.get_bone_pose(bone_idx)
		
		isolated_skeleton.add_bone(bone_name)
		isolated_skeleton.set_bone_parent(bone_idx, bone_parent)
		isolated_skeleton.set_bone_rest(bone_idx, bone_rest)
		isolated_skeleton.set_bone_pose_position(bone_idx, bone_pose.origin)
		isolated_skeleton.set_bone_pose_rotation(bone_idx, bone_pose.basis.get_rotation_quaternion())
		isolated_skeleton.set_bone_pose_scale(bone_idx, bone_pose.basis.get_scale())
	
	isolated_skeleton.position = Vector3.ZERO
	print("Skeleton aislado: %d huesos copiados" % isolated_skeleton.get_bone_count())
	return isolated_skeleton

func _attach_isolated_meshes(isolated_skeleton: Skeleton3D, id: String):
	"""Agregar meshes completamente independientes al skeleton aislado"""
	var base_meshes = base_model_loaded.get("meshes", [])
	
	for mesh_data in base_meshes:
		var mesh_node = mesh_data.get("node")
		if mesh_node and is_instance_valid(mesh_node):
			# CRÍTICO: Usar duplicate(DUPLICATE_WITH_SIGNALS | DUPLICATE_GROUPS | DUPLICATE_SCRIPTS)
			# para asegurar copia completa
			var isolated_mesh = mesh_node.duplicate(7)  # Todas las flags
			isolated_mesh.name = mesh_node.name + "_Isolated_" + id
			
			# CRÍTICO: Reconfigurar skeleton path para apuntar al padre
			#if isolated_mesh.has_method("set") and isolated_mesh.has_property("skeleton"):
			if isolated_mesh.has_method("set") :
				isolated_mesh.skeleton = NodePath("..")
				
			isolated_skeleton.add_child(isolated_mesh)
			print("    ✅ Mesh aislado: %s -> %s" % [mesh_node.name, isolated_mesh.name])

func _create_isolated_animation_player(original_player: AnimationPlayer, isolated_skeleton: Skeleton3D, id: String) -> AnimationPlayer:
	"""Crear AnimationPlayer completamente aislado con rutas retargeteadas"""
	var isolated_player = AnimationPlayer.new()
	isolated_player.name = "AnimationPlayer_Isolated_" + id  # Nombre único crítico
	
	# CRÍTICO: Root node debe apuntar al contenedor padre
	isolated_player.root_node = NodePath("..")
	
	# Crear biblioteca de animaciones independiente
	var isolated_library = AnimationLibrary.new()
	isolated_player.add_animation_library("", isolated_library)
	
	# Copiar cada animación con retargeting completo
	for anim_name in original_player.get_animation_list():
		var original_animation = original_player.get_animation(anim_name)
		if original_animation:
			var isolated_animation = _create_isolated_animation(original_animation, isolated_skeleton, id)
			isolated_library.add_animation(anim_name, isolated_animation)
			print("    ✅ Animación aislada: %s" % anim_name)
	
	print("AnimationPlayer aislado: %d animaciones copiadas" % isolated_player.get_animation_list().size())
	return isolated_player

func _create_isolated_animation(original_animation: Animation, isolated_skeleton: Skeleton3D, id: String) -> Animation:
	"""Crear animación completamente aislada con rutas retargeteadas"""
	var isolated_animation = original_animation.duplicate(true)
	
	# RETARGETING CRÍTICO: Actualizar TODOS los track paths
	for track_idx in range(isolated_animation.get_track_count()):
		var original_path = isolated_animation.track_get_path(track_idx)
		var original_path_str = str(original_path)
		
		# Reemplazar rutas para apuntar al skeleton aislado
		var isolated_path_str = _retarget_animation_path(original_path_str, isolated_skeleton.name, id)
		
		if isolated_path_str != original_path_str:
			isolated_animation.track_set_path(track_idx, NodePath(isolated_path_str))
			
			# Debug solo primeros tracks
			if track_idx < 2:
				print("      🔄 Track retargeteado: %s -> %s" % [original_path_str, isolated_path_str])
	
	# Configurar loop automáticamente
	isolated_animation.loop_mode = Animation.LOOP_LINEAR
	
	return isolated_animation

func _retarget_animation_path(original_path: String, isolated_skeleton_name: String, id: String) -> String:
	"""Retargetear path de animación para apuntar al skeleton aislado específico"""
	
	# Patrones comunes que necesitan ser retargeteados:
	# "Skeleton3D:Bone_Name" -> "Skeleton3D_Isolated_A:Bone_Name"  
	# "../Skeleton3D/Bone_Name" -> "../Skeleton3D_Isolated_A/Bone_Name"
	# "Skeleton3D/MeshInstance3D" -> "Skeleton3D_Isolated_A/MeshInstance3D_Isolated_A"
	
	var retargeted_path = original_path
	
	# Caso 1: Rutas que empiezan con nombre del skeleton
	if retargeted_path.begins_with("Skeleton3D"):
		retargeted_path = retargeted_path.replace("Skeleton3D", isolated_skeleton_name)
	
	# Caso 2: Rutas relativas con ../Skeleton3D  
	retargeted_path = retargeted_path.replace("../Skeleton3D", "../" + isolated_skeleton_name)
	retargeted_path = retargeted_path.replace("./Skeleton3D", "./" + isolated_skeleton_name)
	
	# Caso 3: MeshInstance3D dentro del skeleton
	retargeted_path = retargeted_path.replace("MeshInstance3D", "MeshInstance3D_Isolated_" + id)
	
	# Caso 4: Cualquier referencia directa al skeleton sin path
	if "Skeleton3D" in retargeted_path and isolated_skeleton_name not in retargeted_path:
		retargeted_path = retargeted_path.replace("Skeleton3D", isolated_skeleton_name)
	
	return retargeted_path

#func _get_model_container(id: String) -> Node3D:
	#"""Obtener contenedor específico para el modelo"""
	#var container_path: String
	#
	#if id == "A":
		#container_path = "HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_A/LayoutContainer_A/SubViewportContainer_A/SubViewport_A/Model_A"
	#else:
		#container_path = "HSplitContainer/HSplitContainer/Columna2_Container/Columna2_UI/PanelContainer_B/LayoutContainer_B/SubViewportContainer_B/SubViewport_B/Model_B"
	#
	#return get_parent().get_node_or_null(container_path)

func _clear_model_container(container: Node3D):
	"""Limpiar selectivamente el contenedor del modelo"""
	var nodes_to_remove = []
	
	for child in container.get_children():
		# Solo remover nodos que NO pertenezcan al modelo actual que estamos creando
		if child is Skeleton3D or child is AnimationPlayer:
			# Verificar si es un nodo temporal o mal configurado
			if not child.name.contains("_Isolated_"):
				nodes_to_remove.append(child)
				print("    🗑️ Marcando para remover: %s (no aislado)" % child.name)
			else:
				print("    ✅ Manteniendo: %s (ya aislado)" % child.name)
	
	# Remover solo los nodos marcados
	for node in nodes_to_remove:
		node.queue_free()
	
	# Esperar solo si removimos algo
	if nodes_to_remove.size() > 0:
		await get_tree().process_frame

# === FUNCIONES DE CONTROL AISLADO ===

#func _on_play_animation_a():
	#"""Reproducir animación A de forma completamente aislada"""
	#print("▶ PLAY AISLADO - Animación A")
	#
	#if not animation_player_a or not is_instance_valid(animation_player_a):
		#print("❌ AnimationPlayer A no disponible")
		#return
	#
	#var anim_name = playback_state_a.animation_name
	#if anim_name == "":
		#print("❌ No hay animación configurada para A")
		#return
	#
	## Verificar que la animación existe en el player aislado
	#if not animation_player_a.has_animation(anim_name):
		#print("❌ Animación '%s' no encontrada en AnimationPlayer A aislado" % anim_name)
		#print("    Animaciones disponibles: %s" % animation_player_a.get_animation_list())
		#return
	#
	## CRÍTICO: Solo reproducir en el AnimationPlayer aislado A
	#animation_player_a.stop()  # Detener cualquier animación previa
	#animation_player_a.play(anim_name)
	#playback_state_a.playing = true
	#
	## Verificar que NO se esté reproduciendo en B
	#if animation_player_b and animation_player_b.is_playing():
		#print("⚠️ DETECTADO: AnimationPlayer B también reproduciéndose - DETENIENDO")
		#animation_player_b.stop()
		#playback_state_b.playing = false
	#
	#print("✅ Animación A iniciada en modo AISLADO")
	#
	#if not update_timer.is_stopped():
		#update_timer.stop()
	#update_timer.start()
	#
	#_emit_playback_state("animation_a")
#
#func _on_play_animation_b():
	#"""Reproducir animación B de forma completamente aislada"""
	#print("▶ PLAY AISLADO - Animación B")
	#
	#if not animation_player_b or not is_instance_valid(animation_player_b):
		#print("❌ AnimationPlayer B no disponible")
		#return
	#
	#var anim_name = playback_state_b.animation_name
	#if anim_name == "":
		#print("❌ No hay animación configurada para B")
		#return
	#
	## Verificar que la animación existe en el player aislado
	#if not animation_player_b.has_animation(anim_name):
		#print("❌ Animación '%s' no encontrada en AnimationPlayer B aislado" % anim_name)
		#print("    Animaciones disponibles: %s" % animation_player_b.get_animation_list())
		#return
	#
	## CRÍTICO: Solo reproducir en el AnimationPlayer aislado B
	#animation_player_b.stop()  # Detener cualquier animación previa
	#animation_player_b.play(anim_name)
	#playback_state_b.playing = true
	#
	## Verificar que NO se esté reproduciendo en A
	#if animation_player_a and animation_player_a.is_playing():
		#print("⚠️ DETECTADO: AnimationPlayer A también reproduciéndose - DETENIENDO")
		#animation_player_a.stop()
		#playback_state_a.playing = false
	#
	#print("✅ Animación B iniciada en modo AISLADO")
	#
	#if not update_timer.is_stopped():
		#update_timer.stop()
	#update_timer.start()
	#
	#_emit_playback_state("animation_b")




func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Buscar AnimationPlayer en el nodo o sus hijos"""
	if node is AnimationPlayer:
		return node
	
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	
	return null

#func _configure_playback_states():
	#print("func _configure_playback_states():")
	#
	#"""Configurar estados iniciales de reproducción"""
	#print("⚙️ Configurando estados de reproducción...")
	#
	## Configurar estado A
	#var anim_name_a = animation_a_data.get("display_name", "")
	#print("anim_name_a")
	#print(anim_name_a)
	#
	#if animation_player_a and anim_name_a != "":
		#playback_state_a.animation_name = anim_name_a
		#print("playback_state_a.animation_name")
		#print(playback_state_a.animation_name)
		#
	#
	## Configurar estado B
	#var anim_name_b = animation_b_data.get("display_name", "")
	#
	#if animation_player_b and anim_name_b != "":
		#playback_state_b.animation_name = anim_name_b
		#print("playback_state_b.animation_name")
		#print(playback_state_b.animation_name)
		#
#
## ========================================================================
## CONTROL DE REPRODUCCIÓN
## ========================================================================
#
##func _on_play_animation_a():
	##print("func _on_play_animation_a():")
	##"""Iniciar reproducción de animación A"""
	###
	##print("▶ Reproduciendo animación A: %s" % playback_state_a.animation_name)
	##
	### Usar el nombre con el prefijo de la biblioteca si es necesario
	##var anim_to_play = playback_state_a.animation_name
	##print("anim_to_play")
	##print(anim_to_play)
	##print("00000000000000000000000000000000playback_state_a")
	##print(playback_state_a)
	##
	##animation_player_a.play(anim_to_play)
	##playback_state_a.playing = true
	##
	##
	### Iniciar actualización de estados
	##if not update_timer.is_stopped():
		##update_timer.stop()
	##update_timer.start()
	##
	##_emit_playback_state("animation_a")

func _on_pause_animation_a():
	"""Pausar animación A"""
	if animation_player_a:
		print("⏸ Pausando animación A")
		animation_player_a.pause()
		playback_state_a.playing = false
		_emit_playback_state("animation_a")
		playback_state_a.current_frame = playback_state_a.total_frames
		
		

#func _on_play_animation_b():
	#"""Iniciar reproducción de animación B"""
	#print("func _on_play_animation_b():")
	#if not animation_player_b or playback_state_b.animation_name == "":
		#print("  ⚠️ No se puede reproducir animación B")
		#return
	#
	#print("▶ Reproduciendo animación B: %s" % playback_state_b.animation_name)
	#
	## Usar el nombre con el prefijo de la biblioteca si es necesario
	#var anim_to_play = playback_state_b.animation_name
	#print("anim_to_play")
	#print(anim_to_play)
	##if animation_player_b.has_animation_library(""):
		##var lib = animation_player_b.get_animation_library("")
		##if lib and lib.has_animation(anim_to_play):
			### Si la animación está en la biblioteca por defecto, agregar prefijo
			##anim_to_play = anim_to_play  # La biblioteca "" no necesita prefijo
	#
	#animation_player_b.play(anim_to_play)
	#playback_state_b.playing = true
	#
	## Iniciar actualización de estados
	#if not update_timer.is_stopped():
		#update_timer.stop()
	#update_timer.start()
	#
	#_emit_playback_state("animation_b")

func _on_pause_animation_b():
	"""Pausar animación B"""
	if animation_player_b:
		print("⏸ Pausando animación B")
		animation_player_b.pause()
		playback_state_b.playing = false
		_emit_playback_state("animation_b")
		playback_state_b.current_frame = 0	
# ========================================================================
# ACTUALIZACIÓN DE ESTADOS
# ========================================================================

func _update_playback_states():
	"""Actualizar estados de reproducción"""
	var any_playing = false
	
	# Actualizar estado A
	if animation_player_a and playback_state_a.playing:
		if animation_player_a.is_playing():
			var current_pos = animation_player_a.current_animation_position
			playback_state_a.current_frame = int(current_pos * 30)
			_emit_playback_state("animation_a")
			any_playing = true
		else:
			# Animación terminó
			playback_state_a.playing = false
			playback_state_a.current_frame = playback_state_a.total_frames
			_emit_playback_state("animation_a")
	
	# Actualizar estado B
	if animation_player_b and playback_state_b.playing:
		if animation_player_b.is_playing():
			var current_pos = animation_player_b.current_animation_position
			playback_state_b.current_frame = int(current_pos * 30)
			_emit_playback_state("animation_b")
			any_playing = true
		else:
			# Animación terminó
			playback_state_b.playing = false
			playback_state_b.current_frame = 0
			_emit_playback_state("animation_b")
	
	# Detener timer si no hay animaciones reproduciéndose
	if not any_playing:
		update_timer.stop()

func _emit_playback_state(animation_type: String):
	"""Emitir estado de reproducción actualizado"""
	var state = playback_state_a if animation_type == "animation_a" else playback_state_b
	emit_signal("playback_state_changed", animation_type, state)

# ========================================================================
# API PÚBLICA
# ========================================================================

func get_animation_a_state() -> Dictionary:
	"""Obtener estado de animación A"""
	return playback_state_a.duplicate()

func get_animation_b_state() -> Dictionary:
	"""Obtener estado de animación B"""
	return playback_state_b.duplicate()

func get_preview_data() -> Dictionary:
	"""Obtener datos de preview"""
	return {
		"animation_a": {
			"loaded": animation_a_model != null,
			"playing": playback_state_a.playing,
			"animation_name": playback_state_a.animation_name
		},
		"animation_b": {
			"loaded": animation_b_model != null,
			"playing": playback_state_b.playing,
			"animation_name": playback_state_b.animation_name
		}
	}

# ========================================================================
# DEBUG
# ========================================================================

func debug_system_status():
	"""Debug del estado del sistema"""
	print("=== DEBUG COLUMNA2 LOGIC ===")
	print("Viewports:")
	print("  - Viewport A: %s" % (viewport_a != null))
	print("  - Viewport B: %s" % (viewport_b != null))
	print("Modelos cargados:")
	print("  - Modelo A: %s" % (animation_a_model != null))
	print("  - Modelo B: %s" % (animation_b_model != null))
	print("AnimationPlayers:")
	print("  - Player A: %s" % (animation_player_a != null))
	print("  - Player B: %s" % (animation_player_b != null))
	print("Animaciones:")
	print("  - Animación A: %s" % playback_state_a.animation_name)
	print("  - Animación B: %s" % playback_state_b.animation_name)
	print("Estados de reproducción:")
	print("  - A: %s (Frame %d/%d)" % [
		"Playing" if playback_state_a.playing else "Stopped",
		playback_state_a.current_frame,
		playback_state_a.total_frames
	])
	print("  - B: %s (Frame %d/%d)" % [
		"Playing" if playback_state_b.playing else "Stopped",
		playback_state_b.current_frame,
		playback_state_b.total_frames
	])
	print("============================")





# === CONFIGURACIÓN DE MODELOS ===
var camera_controller_a: Node
var camera_controller_b: Node
var orientation_analyzer: Node
var model_bounds_a: AABB = AABB()
var model_bounds_b: AABB = AABB()

# Configuración compartida
var current_model_settings: Dictionary = {
	"camera_height": 2.5,
	"camera_angle": 45.0,
	"north_offset": 0.0,
	"camera_distance": 5.0,
	"orthographic_size": 2.5,
	"manual_zoom_active": false
}

# === CONFIGURACIÓN FIJA ===
var current_capture_area: float = 2.5
var current_north_angle: float = 0.0

#func _create_camera_controllers():
	#"""Crear controladores de cámara para ambos viewports"""
	#var camera_controller_script = load("res://scripts/rendering/camera_controller.gd")
	#
	## Camera Controller A
	#camera_controller_a = camera_controller_script.new()
	#camera_controller_a.name = "CameraController_A"
	#viewport_a.add_child(camera_controller_a)
	#
	## Camera Controller B
	#camera_controller_b = camera_controller_script.new()
	#camera_controller_b.name = "CameraController_B"
	#viewport_b.add_child(camera_controller_b)
	#
	## Configurar cámaras existentes
	#var camera_a = viewport_a.get_node_or_null("Camera3D_A")
	#var camera_b = viewport_b.get_node_or_null("Camera3D_B")
	#
	#if camera_a:
		#camera_controller_a.camera_3d = camera_a
		#camera_controller_a.use_orthographic = true
	#
	#if camera_b:
		#camera_controller_b.camera_3d = camera_b  
		#camera_controller_b.use_orthographic = true


func set_capture_area(size: float):
	"""Cambiar área de captura en ambas cámaras"""
	current_capture_area = size
	
	var camera_a = viewport_a.get_node("Camera3D_A")
	if camera_a:
		camera_a.size = size
	
	var camera_b = viewport_b.get_node("Camera3D_B")
	if camera_b:
		camera_b.size = size

func set_model_orientation(angle: float):
	"""Cambiar orientación de ambos modelos"""
	current_north_angle = angle
	
	if animation_a_model:
		animation_a_model.rotation_degrees.y = angle
	if animation_b_model:
		animation_b_model.rotation_degrees.y = angle
		
func _calculate_model_bounds(model_container: Node3D) -> AABB:
	"""Calcular bounds del modelo"""
	var combined_bounds = AABB()
	var first = true
	
	for child in model_container.get_children():
		if child is Skeleton3D:
			for skeleton_child in child.get_children():
				if skeleton_child is MeshInstance3D and skeleton_child.mesh:
					var mesh_bounds = skeleton_child.mesh.get_aabb()
					var global_bounds = skeleton_child.global_transform * mesh_bounds
					
					if first:
						combined_bounds = global_bounds
						first = false
					else:
						combined_bounds = combined_bounds.merge(global_bounds)
	
	return combined_bounds

#func _setup_model_configuration(model_container: Node3D, camera_controller: Node, model_id: String):
	#"""Configurar modelo con centrado automático"""
	#var bounds = _calculate_model_bounds(model_container)
	#
	#if model_id == "A":
		#model_bounds_a = bounds
	#else:
		#model_bounds_b = bounds
	#
	## Configurar cámara para el modelo
	#if camera_controller and camera_controller.has_method("setup_for_model"):
		#camera_controller.setup_for_model(bounds)
	#
	## Aplicar configuración actual
	#if camera_controller and camera_controller.has_method("set_camera_settings"):
		#camera_controller.set_camera_settings(current_model_settings)


func _auto_center_and_orient_model(model_container: Node3D, viewport: SubViewport):
	"""Centrar y orientar modelo automáticamente"""
	var bounds = _calculate_model_bounds(model_container)
	var center = bounds.get_center()
	
	# CENTRADO AUTOMÁTICO: Mover modelo para que su centro esté en origen
	model_container.position = -center
	
	# ORIENTACIÓN AUTOMÁTICA: Rotar hacia el norte (0°)
	model_container.rotation_degrees.y = 0.0
	
	# Configurar cámara para encuadrar el modelo centrado
	var camera = viewport.get_node("Camera3D_A" if viewport == viewport_a else "Camera3D_B")
	if camera:
		# Mantener parámetros fijos, solo ajustar target
		var model_size = bounds.get_longest_axis_size()
		var auto_size = max(model_size * 1.8, 2.5)
		camera.size = current_model_settings.get("capture_area_size", auto_size)

func apply_model_settings(settings: Dictionary):
	"""Aplicar configuración a ambos modelos"""
	current_model_settings.merge(settings, true)
	
	if camera_controller_a and camera_controller_a.has_method("set_camera_settings"):
		camera_controller_a.set_camera_settings(current_model_settings)
	
	if camera_controller_b and camera_controller_b.has_method("set_camera_settings"):
		camera_controller_b.set_camera_settings(current_model_settings)

func set_north_offset(angle: float):
	"""Establecer orientación norte para ambos modelos"""
	current_model_settings["north_offset"] = angle
	
	# Aplicar rotación física a los modelos
	if animation_a_model:
		animation_a_model.rotation_degrees.y = angle
	if animation_b_model:
		animation_b_model.rotation_degrees.y = angle
	
	apply_model_settings(current_model_settings)
	
	
	
func request_auto_north_detection():
	"""Solicitar detección automática de orientación"""
	if not orientation_analyzer:
		var analyzer_script = load("res://scripts/orientation/orientation_analyzer.gd")
		orientation_analyzer = analyzer_script.new()
		orientation_analyzer.name = "OrientationAnalyzer"
		add_child(orientation_analyzer)
		orientation_analyzer.analysis_complete.connect(_on_orientation_analysis_complete)
	
	# Analizar primer modelo disponible
	if animation_a_model and animation_a_model.get_child_count() > 0:
		var skeleton = animation_a_model.get_child(0)
		orientation_analyzer.analyze_model_orientation(skeleton)

func _on_orientation_analysis_complete(result: Dictionary):
	"""Aplicar resultado de análisis de orientación"""
	var suggested_angle = result.get("suggested_north", 0.0)
	set_north_offset(suggested_angle)
	
	if ui_node:
		ui_node.north_slider.value = suggested_angle

func recenter_models():
	"""Recentrar ambos modelos"""
	pass
	#if animation_a_model:
		#_setup_model_configuration(animation_a_model, camera_controller_a, "A")
	#if animation_b_model:
		#_setup_model_configuration(animation_b_model, camera_controller_b, "B")
#


func _configure_existing_cameras():
	"""Usar parámetros EXACTOS del proyecto original"""
	# Valores exactos del CameraController original
	var camera_angle = 45.0
	var camera_distance = 5.0 
	var camera_height = 2.0
	var orthographic_size = 2.5
	
	# Calcular posición usando la fórmula exacta del original
	var rad_angle = deg_to_rad(camera_angle)
	var cam_x = 0
	var cam_y = sin(rad_angle) * camera_distance + camera_height  # 5.535534
	var cam_z = cos(rad_angle) * camera_distance                  # 3.535534
	var camera_position = Vector3(cam_x, cam_y, cam_z)
	
	# Configurar Camera3D_A con parámetros exactos
	var camera_a = viewport_a.get_node("Camera3D_A")
	if camera_a:
		camera_a.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_a.size = orthographic_size
		camera_a.near = 0.1
		camera_a.far = 100.0
		camera_a.position = camera_position
		camera_a.look_at(Vector3.ZERO, Vector3.UP)  # Esto genera la rotación correcta
	
	# Camera3D_B idéntica
	var camera_b = viewport_b.get_node("Camera3D_B")
	if camera_b:
		camera_b.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_b.size = orthographic_size
		camera_b.near = 0.1
		camera_b.far = 100.0
		camera_b.position = camera_position
		camera_b.look_at(Vector3.ZERO, Vector3.UP)
	
	_configure_existing_lights()

func _configure_existing_lights():
	"""Configurar luces físicas existentes"""
	var light_a = viewport_a.get_node("DirectionalLight3D_A")
	if light_a:
		light_a.light_energy = 1.0
		light_a.light_color = Color(1.0, 0.95, 0.9)
		light_a.rotation_degrees = Vector3(-45, -45, 0)
		light_a.shadow_enabled = true
	
	var light_b = viewport_b.get_node("DirectionalLight3D_B")
	if light_b:
		light_b.light_energy = 1.0
		light_b.light_color = Color(1.0, 0.95, 0.9)
		light_b.rotation_degrees = Vector3(-45, -45, 0)
		light_b.shadow_enabled = true




# === NUEVA FUNCIÓN: COMPARAR FRAMES USANDO TOTAL_FRAMES ===
func compare_animation_frames():
	"""Posicionar animación A en último frame y B en primer frame usando total_frames"""
	print("🔄 Comparando frames usando sistema total_frames")
	print("  Estado A: %d/%d frames" % [playback_state_a.current_frame, playback_state_a.total_frames])
	print("  Estado B: %d/%d frames" % [playback_state_b.current_frame, playback_state_b.total_frames])
	
	# Detener timer de actualización
	if not update_timer.is_stopped():
		update_timer.stop()
	
	# Detener ambas animaciones
	if animation_player_a and is_instance_valid(animation_player_a):
		animation_player_a.stop()
		playback_state_a.playing = false
	
	if animation_player_b and is_instance_valid(animation_player_b):
		animation_player_b.stop()
		playback_state_b.playing = false
	
	# Posicionar animación A en último frame
	_set_animation_to_last_frame("A")
	
	# Posicionar animación B en primer frame  
	_set_animation_to_first_frame("B")
	
	print("✅ Animaciones posicionadas para comparación")
	
	# Actualizar UI con nuevos estados
	_emit_playback_state("animation_a")
	_emit_playback_state("animation_b")

func _set_animation_to_last_frame(animation_id: String):
	"""Posicionar animación específica en su último frame"""
	var animation_player: AnimationPlayer
	var playback_state: Dictionary
	
	if animation_id == "A":
		animation_player = animation_player_a
		playback_state = playback_state_a
	else:
		animation_player = animation_player_b
		playback_state = playback_state_b
	
	if not animation_player or not is_instance_valid(animation_player):
		print("❌ AnimationPlayer %s no válido" % animation_id)
		return
	
	var anim_name = playback_state.animation_name
	if anim_name == "" or not animation_player.has_animation(anim_name):
		print("❌ Animación %s no encontrada: %s" % [animation_id, anim_name])
		return
	
	var animation = animation_player.get_animation(anim_name)
	if not animation:
		print("❌ No se pudo obtener animación %s: %s" % [animation_id, anim_name])
		return
	
	# Calcular posición del último frame
	var total_frames = playback_state.total_frames
	if total_frames <= 0:
		total_frames = int(animation.length * 30)  # Fallback a 30 FPS
		playback_state.total_frames = total_frames
	
	var last_frame = total_frames 
	var frame_duration = animation.length / total_frames
	var last_position = last_frame * frame_duration
	
	# Posicionar en último frame
	animation_player.play(anim_name)
	animation_player.seek(last_position)
	animation_player.pause()
	
	# Actualizar estado
	playback_state.current_frame = last_frame
	playback_state.playing = false
	
	print("✅ Animación %s -> último frame: %d/%d (%.3fs)" % [animation_id, last_frame, total_frames, last_position])

func _set_animation_to_first_frame(animation_id: String):
	"""Posicionar animación específica en su primer frame"""
	var animation_player: AnimationPlayer
	var playback_state: Dictionary
	
	if animation_id == "A":
		animation_player = animation_player_a
		playback_state = playback_state_a
	else:
		animation_player = animation_player_b
		playback_state = playback_state_b
	
	if not animation_player or not is_instance_valid(animation_player):
		print("❌ AnimationPlayer %s no válido" % animation_id)
		return
	
	var anim_name = playback_state.animation_name
	if anim_name == "" or not animation_player.has_animation(anim_name):
		print("❌ Animación %s no encontrada: %s" % [animation_id, anim_name])
		return
	
	# Posicionar en primer frame
	animation_player.play(anim_name)
	animation_player.seek(0.0)
	animation_player.pause()
	
	# Actualizar estado
	playback_state.current_frame = 0
	playback_state.playing = false
	
	print("✅ Animación %s -> primer frame: 0/%d (0.000s)" % [animation_id, playback_state.total_frames])

# === FUNCIONES ADICIONALES DE CONTROL FRAME POR FRAME ===

func set_animation_frame(animation_id: String, target_frame: int):
	"""Posicionar animación en frame específico - función genérica útil"""
	var animation_player: AnimationPlayer
	var playback_state: Dictionary
	
	if animation_id == "A":
		animation_player = animation_player_a
		playback_state = playback_state_a
	else:
		animation_player = animation_player_b
		playback_state = playback_state_b
	
	if not animation_player or not is_instance_valid(animation_player):
		print("❌ AnimationPlayer %s no válido" % animation_id)
		return
	
	var anim_name = playback_state.animation_name
	if anim_name == "" or not animation_player.has_animation(anim_name):
		print("❌ Animación %s no encontrada: %s" % [animation_id, anim_name])
		return
	
	var animation = animation_player.get_animation(anim_name)
	var total_frames = playback_state.total_frames
	if total_frames <= 0:
		total_frames = int(animation.length * 30)
	
	# Limitar frame al rango válido
	target_frame = clamp(target_frame, 0, total_frames - 1)
	
	# Calcular posición temporal
	var frame_duration = animation.length / total_frames
	var target_position = target_frame * frame_duration
	
	# Detener timer si está corriendo
	if not update_timer.is_stopped():
		update_timer.stop()
	
	# Posicionar
	animation_player.play(anim_name)
	animation_player.seek(target_position)
	animation_player.pause()
	
	# Actualizar estado
	playback_state.current_frame = target_frame
	playback_state.playing = false
	
	print("✅ Animación %s posicionada en frame: %d/%d (%.3fs)" % [animation_id, target_frame, total_frames, target_position])
	
	# Emitir actualización de estado
	_emit_playback_state("animation_" + animation_id.to_lower())

# === VERSIÓN SIMPLE PARA EL BOTÓN DE UI ===
func quick_compare_frames():
	"""Versión simple para llamar desde UI - A último, B primero"""
	compare_animation_frames()


# En Columna2_UI.gd solo necesitas esto:

# Agregar en _create_model_config_panel() después de orient_value_label:
# 
# # === BOTÓN PARA COMPARAR FRAMES ===
# var separator = HSeparator.new()
# vbox.add_child(separator)
# 
# compare_frames_button = Button.new()
# compare_frames_button.text = "Comparar: A=Final | B=Inicio"
# compare_frames_button.custom_minimum_size = Vector2(0, 30)
# compare_frames_button.pressed.connect(_on_compare_frames_pressed)
# vbox.add_child(compare_frames_button)

# Y agregar esta función en Columna2_UI.gd:
# 
# func _on_compare_frames_pressed():
# 	"""Solicitar comparación de frames a la lógica"""
# 	var logic = get_node("../../../../Columna2_Logic")
# 	if logic and logic.has_method("quick_compare_frames"):
# 		logic.quick_compare_frames()
# 	else:
# 		print("❌ No se pudo acceder a Columna2_Logic")
