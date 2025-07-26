# pixelize3d_fbx/scripts/debug/viewport_connection_fix.gd
# Script corregido para conectar los viewports del SpriteRenderer con la UI
# Input: Textura del viewport de renderizado
# Output: Textura visible en el preview de la UI

extends Node

# Este script debe ejecutarse desde main.gd para conectar los viewports

#func connect_preview_viewports():
	#print("🔗 CONECTANDO VIEWPORTS PARA PREVIEW")
	#
	## CORREGIDO: Referencias desde viewport_connector (hijo de main)
	#var ui_controller = get_node("../UIController")
	#var sprite_renderer = get_node("../SpriteRenderer")
	#
	## Viewport del renderizado (estructura: SpriteRenderer/SubViewport)
	#var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
	#
	## CORREGIDO: Buscar ViewportContainer en lugar de preview_viewport
	#var viewport_container = _find_viewport_container(ui_controller)
	#
	#if not render_viewport:
		#print("❌ No se encontró render_viewport en SpriteRenderer")
		#print("   Buscando en: %s" % sprite_renderer.get_path())
		#for child in sprite_renderer.get_children():
			#print("   Hijo disponible: %s" % child.name)
		#return false
		#
	#if not viewport_container:
		#print("❌ No se encontró ViewportContainer en UIController")
		#return false
	#
	#print("✅ Render viewport y ViewportContainer encontrados")
	#print("  Render viewport: %s" % render_viewport.name)
	#print("  ViewportContainer: %s" % viewport_container.name)
	#
	## NUEVA SOLUCIÓN: Usar el método de TextureRect directamente
	#return _setup_texture_based_preview(render_viewport, viewport_container)

# Reemplaza la función problemática con:
func connect_preview_viewports():
	print("🔗 CONECTANDO VIEWPORTS - VERSIÓN CORREGIDA")
	
	var ui_controller = get_node("../UIController")
	var sprite_renderer = get_node("../SpriteRenderer")
	
	var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if not render_viewport:
		return false
	
	# Buscar cualquier container en la UI
	for child in ui_controller.get_children():
		if "viewport" in child.name.to_lower() or "preview" in child.name.to_lower():
			# Crear TextureRect directamente
			var tex_rect = TextureRect.new()
			tex_rect.name = "PreviewTexture"
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			child.add_child(tex_rect)
			
			# Timer para actualizar
			var timer = Timer.new()
			timer.wait_time = 0.033
			timer.timeout.connect(func(): 
				if render_viewport.get_texture():
					tex_rect.texture = render_viewport.get_texture()
			)
			add_child(timer)
			timer.start()
			
			return true
	
	return false
	
# NUEVA FUNCIÓN: Configurar preview basado en TextureRect
func _setup_texture_based_preview(render_viewport: SubViewport, viewport_container: Control) -> bool:
	print("🖼️ CONFIGURANDO PREVIEW BASADO EN TEXTURERECT")
	
	# Buscar o crear TextureRect en el container
	var texture_rect = _find_or_create_texture_rect(viewport_container)
	if not texture_rect:
		print("❌ No se pudo crear TextureRect")
		return false
	
	# CORREGIDO: Configurar timer primero
	var sync_timer = Timer.new()
	sync_timer.name = "TexturePreviewSyncTimer"
	sync_timer.wait_time = 1.0 / 30.0  # 30 FPS
	sync_timer.autostart = true
	add_child(sync_timer)
	
	# Configurar callable ANTES de iniciar
	var update_callable = _update_texture_preview.bind(render_viewport, texture_rect)
	sync_timer.timeout.connect(update_callable)
	
	# Iniciar timer manualmente
	sync_timer.start()
	
	# NUEVO: Forzar primera actualización de forma síncrona
	_force_immediate_texture_update(render_viewport, texture_rect)
	
	print("✅ Preview basado en TextureRect configurado")
	print("   Timer: %s, Autostart: %s, Activo: %s" % [sync_timer.name, sync_timer.autostart, not sync_timer.is_stopped()])
	return true

# NUEVA FUNCIÓN: Forzar actualización inmediata (sin await)
func _force_immediate_texture_update(viewport: SubViewport, texture_rect: TextureRect):
	print("🚀 APLICANDO TEXTURA INMEDIATA")
	
	# Forzar renderizado inmediato
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Obtener textura inmediatamente
	var texture = viewport.get_texture()
	if texture:
		texture_rect.texture = texture
		print("✅ Textura inmediata aplicada: %s" % texture.get_size())
		
		# Ocultar mensaje de "no preview"
		var viewport_container = texture_rect.get_parent()
		var no_preview_label = _find_no_preview_label(viewport_container)
		if no_preview_label:
			no_preview_label.visible = false
			print("✅ Mensaje 'no preview' ocultado")
	else:
		print("❌ No se pudo obtener textura inmediata")
		# Intentar en el siguiente frame
		call_deferred("_retry_texture_update", viewport, texture_rect)

# NUEVA FUNCIÓN: Reintentar actualización de textura
func _retry_texture_update(viewport: SubViewport, texture_rect: TextureRect):
	print("🔄 REINTENTANDO ACTUALIZACIÓN DE TEXTURA")
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var texture = viewport.get_texture()
	if texture:
		texture_rect.texture = texture
		print("✅ Textura aplicada en reintento: %s" % texture.get_size())

# NUEVA FUNCIÓN: Buscar o crear TextureRect
func _find_or_create_texture_rect(container: Control) -> TextureRect:
	# Buscar TextureRect existente
	for child in container.get_children():
		if child is TextureRect:
			print("✅ TextureRect existente encontrado: %s" % child.name)
			return child
	
	# Crear nuevo TextureRect si no existe
	print("📝 Creando nuevo TextureRect para preview")
	var texture_rect = TextureRect.new()
	texture_rect.name = "PreviewTextureRect"
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	container.add_child(texture_rect)
	print("✅ TextureRect creado: %s" % texture_rect.name)
	return texture_rect

# NUEVA FUNCIÓN: Actualizar preview de textura
func _update_texture_preview(viewport: SubViewport, texture_rect: TextureRect):
	if viewport and texture_rect:
		# CORREGIDO: Forzar actualización del viewport
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		var texture = viewport.get_texture()
		if texture:
			texture_rect.texture = texture
			
			# Debug ocasional para verificar que funciona
			if randf() < 0.01:  # 1% de las veces
				print("🔄 Textura actualizada: %s -> %s" % [texture.get_size(), texture_rect.name])

# NUEVA FUNCIÓN: Forzar actualización inicial
func _force_initial_texture_update(viewport: SubViewport, texture_rect: TextureRect):
	print("🚀 FORZANDO ACTUALIZACIÓN INICIAL DE TEXTURA")
	
	# Esperar un frame para que el modelo esté renderizado
	await get_tree().process_frame
	
	# Forzar renderizado
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	
	# Obtener textura
	var texture = viewport.get_texture()
	if texture:
		texture_rect.texture = texture
		print("✅ Textura inicial aplicada: %s" % texture.get_size())
		
		# Ocultar mensaje de "no preview"
		var viewport_container = texture_rect.get_parent()
		var no_preview_label = _find_no_preview_label(viewport_container)
		if no_preview_label:
			no_preview_label.visible = false
	else:
		print("❌ No se pudo obtener textura inicial")

# NUEVA FUNCIÓN: Buscar label de "no preview"
func _find_no_preview_label(container: Node) -> Label:
	for child in container.get_children():
		if child is Label and "NoPreview" in child.name:
			return child
	return null

# SOLUCIÓN ALTERNATIVA: Usar TextureRect para mostrar la textura
func setup_texture_display_alternative():
	print("🖼️ CONFIGURANDO DISPLAY ALTERNATIVO CON TEXTURE")
	
	# CORREGIDO: Referencias desde viewport_connector
	var ui_controller = get_node("../UIController")
	var sprite_renderer = get_node("../SpriteRenderer")
	
	# Buscar el viewport container en la UI
	var viewport_container = _find_viewport_container(ui_controller)
	if not viewport_container:
		print("❌ No se encontró ViewportContainer en UI")
		return false
	
	# Buscar o crear TextureRect
	var texture_rect = _find_or_create_texture_rect(viewport_container)
	if not texture_rect:
		print("❌ No se pudo crear TextureRect")
		return false
	
	var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if not render_viewport:
		print("❌ No se encontró SubViewport")
		return false
	
	# NUEVO: Forzar actualización inicial
	_force_initial_texture_update(render_viewport, texture_rect)
	
	# Configurar timer para actualizar textura
	var texture_timer = Timer.new()
	texture_timer.name = "TextureUpdateTimer"
	texture_timer.wait_time = 1.0 / 30.0
	texture_timer.autostart = true
	add_child(texture_timer)
	
	var update_callable = _update_texture_preview.bind(render_viewport, texture_rect)
	texture_timer.timeout.connect(update_callable)
	
	print("✅ Display alternativo configurado")
	return true

func _find_viewport_container(node: Node) -> Control:
	if node.name == "ViewportContainer":
		return node
	
	for child in node.get_children():
		var result = _find_viewport_container(child)
		if result:
			return result
	
	return null

# Función de debugging para verificar estado de viewports
func debug_viewport_states():
	print("\n=== DEBUG VIEWPORTS ===")
	
	# CORREGIDO: Referencias desde viewport_connector
	var ui_controller = get_node("../UIController")
	var sprite_renderer = get_node("../SpriteRenderer")
	
	print("📁 ESTRUCTURA DE NODOS:")
	print("  viewport_connector path: %s" % get_path())
	print("  ui_controller path: %s" % ui_controller.get_path())
	print("  sprite_renderer path: %s" % sprite_renderer.get_path())
	
	# Render viewport
	var render_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if render_viewport:
		print("📹 RENDER VIEWPORT:")
		print("  Path: %s" % render_viewport.get_path())
		print("  Tamaño: %s" % render_viewport.size)
		print("  Hijos: %d" % render_viewport.get_child_count())
		print("  Update mode: %d" % render_viewport.render_target_update_mode)
		print("  Transparente: %s" % render_viewport.transparent_bg)
		
		for child in render_viewport.get_children():
			print("    - %s (%s)" % [child.name, child.get_class()])
		
		var texture = render_viewport.get_texture()
		if texture:
			print("  Textura: %s (%s)" % [texture.get_class(), texture.get_size()])
		else:
			print("  ❌ Sin textura")
	else:
		print("❌ Render viewport no encontrado en SpriteRenderer")
		print("   Hijos disponibles en SpriteRenderer:")
		for child in sprite_renderer.get_children():
			print("     - %s (%s)" % [child.name, child.get_class()])
	
	# UI ViewportContainer
	var viewport_container = _find_viewport_container(ui_controller)
	if viewport_container:
		print("🖥️ UI VIEWPORT CONTAINER:")
		print("  Path: %s" % viewport_container.get_path())
		print("  Tamaño: %s" % viewport_container.size)
		print("  Hijos: %d" % viewport_container.get_child_count())
		
		for child in viewport_container.get_children():
			print("    - %s (%s)" % [child.name, child.get_class()])
			if child is TextureRect:
				var texture = child.texture
				print("      Textura: %s" % (texture.get_class() if texture else "NULL"))
	else:
		print("❌ ViewportContainer no encontrado")
	
	print("========================\n")
