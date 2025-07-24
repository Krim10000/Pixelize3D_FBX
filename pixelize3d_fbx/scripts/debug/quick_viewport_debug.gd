# pixelize3d_fbx/scripts/debug/quick_viewport_debug.gd
# Script temporal para debugging rápido del preview
# Adjúntalo a cualquier nodo en la escena para testing

extends Node

func _ready():
	# Esperar a que todo se cargue
	await get_tree().create_timer(2.0).timeout
	debug_everything()

func _input(event):
	# Presiona F12 para debug manual
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			debug_everything()

func debug_everything():
	print("\n" + "="*50)
	print("🔍 DEBUGGING COMPLETO DEL PREVIEW")
	print("="*50)
	
	var main = get_node("/root/Main")
	
	# 1. Verificar estructura de nodos
	print("\n📁 ESTRUCTURA DE NODOS:")
	_debug_node_tree(main, 0)
	
	# 2. Estado del SpriteRenderer
	print("\n🎬 SPRITE RENDERER:")
	var sprite_renderer = main.get_node_or_null("SpriteRenderer")
	if sprite_renderer:
		print("  ✅ SpriteRenderer encontrado")
		var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
		if render_viewport:
			print("  ✅ Render viewport encontrado")
			print("    Tamaño: %s" % render_viewport.size)
			print("    Hijos: %d" % render_viewport.get_child_count())
			
			# Verificar si hay modelo en el viewport
			for child in render_viewport.get_children():
				print("      - %s" % child.name)
				if "combined" in child.name.to_lower():
					print("        ✅ Modelo combinado encontrado!")
					_debug_model_details(child)
		else:
			print("  ❌ Render viewport NO encontrado")
	else:
		print("  ❌ SpriteRenderer NO encontrado")
	
	# 3. Estado del UIController
	print("\n🖥️ UI CONTROLLER:")
	var ui_controller = main.get_node_or_null("UIController")
	if ui_controller:
		print("  ✅ UIController encontrado")
		if ui_controller.has_method("is_preview_active"):
			print("    Preview activo: %s" % ui_controller.is_preview_active())
		
		# Buscar viewport de preview
		var preview_viewport = _find_preview_viewport(ui_controller)
		if preview_viewport:
			print("  ✅ Preview viewport encontrado: %s" % preview_viewport.name)
			print("    Tamaño: %s" % preview_viewport.size)
			print("    Hijos: %d" % preview_viewport.get_child_count())
		else:
			print("  ❌ Preview viewport NO encontrado")
	else:
		print("  ❌ UIController NO encontrado")
	
	# 4. Verificar texturas
	print("\n🖼️ VERIFICACIÓN DE TEXTURAS:")
	_debug_textures()
	
	print("\n" + "="*50)
	print("FIN DEL DEBUGGING")
	print("="*50 + "\n")

func _debug_node_tree(node: Node, level: int):
	var indent = "  ".repeat(level)
	var class_name = node.get_class()
	print("%s%s (%s)" % [indent, node.name, class_name])
	
	# Solo mostrar primeros 2 niveles para no saturar
	if level < 2:
		for child in node.get_children():
			_debug_node_tree(child, level + 1)

func _debug_model_details(model: Node3D):
	print("        📊 DETALLES DEL MODELO:")
	print("          Posición: %s" % model.global_position)
	print("          Escala: %s" % model.scale)
	
	# Buscar skeleton
	var skeleton = _find_skeleton(model)
	if skeleton:
		print("          ✅ Skeleton: %d huesos" % skeleton.get_bone_count())
		
		# Contar meshes
		var mesh_count = 0
		for child in skeleton.get_children():
			if child is MeshInstance3D:
				mesh_count += 1
		print("          ✅ Meshes: %d" % mesh_count)
	
	# Buscar AnimationPlayer
	var anim_player = model.get_node_or_null("AnimationPlayer")
	if anim_player:
		print("          ✅ AnimationPlayer")
		if anim_player.is_playing():
			print("            🎵 Reproduciendo: %s" % anim_player.current_animation)
		else:
			print("            ⏸️ Detenido")

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	
	return null

func _find_preview_viewport(node: Node) -> SubViewport:
	if node is SubViewport and "preview" in node.name.to_lower():
		return node
	
	for child in node.get_children():
		var result = _find_preview_viewport(child)
		if result:
			return result
	
	return null

func _debug_textures():
	var main = get_node("/root/Main")
	var sprite_renderer = main.get_node_or_null("SpriteRenderer")
	
	if sprite_renderer:
		var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
		if render_viewport:
			var texture = render_viewport.get_texture()
			if texture:
				print("  ✅ Textura del render viewport:")
				print("    Tipo: %s" % texture.get_class())
				print("    Tamaño: %s" % texture.get_size())
			else:
				print("  ❌ Sin textura en render viewport")
	
	# Forzar renderizado
	if sprite_renderer:
		var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
		if render_viewport:
			render_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			print("  🔄 Forzado un frame de renderizado")
