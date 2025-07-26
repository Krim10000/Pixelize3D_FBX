# pixelize3d_fbx/scripts/fixes/quick_preview_fix.gd
# Script de parche rápido para arreglar el preview sin modificar mucho código
# Input: Referencias a los componentes existentes
# Output: Preview funcional

extends Node

# Este script debe ser añadido como hijo del nodo Main

var texture_rect: TextureRect
var sync_timer: Timer
var render_viewport: SubViewport
var ui_viewport_container: Control

func _ready():
	print("🔧 APLICANDO PARCHE DE PREVIEW")
	
	# Esperar a que todo esté listo
	await get_tree().create_timer(0.5).timeout
	
	# Aplicar corrección
	_apply_preview_fix()

func _apply_preview_fix():
	# Obtener referencias
	var sprite_renderer = get_parent().get_node_or_null("SpriteRenderer")
	var ui_controller = get_parent().get_node_or_null("UIController")
	
	if not sprite_renderer or not ui_controller:
		print("❌ No se encontraron componentes necesarios")
		return
	
	# Encontrar viewport de renderizado
	render_viewport = sprite_renderer.get_node_or_null("SubViewport")
	if not render_viewport:
		print("❌ No se encontró SubViewport en SpriteRenderer")
		return
	
	# Buscar ViewportContainer en UI
	ui_viewport_container = _find_node_by_name(ui_controller, "ViewportContainer")
	if not ui_viewport_container:
		print("❌ No se encontró ViewportContainer en UI")
		return
	
	print("✅ Componentes encontrados, aplicando corrección...")
	
	# CORRECCIÓN 1: Reemplazar el viewport del container con un TextureRect
	_replace_with_texture_rect()
	
	# CORRECCIÓN 2: Configurar sincronización
	_setup_texture_sync()
	
	# CORRECCIÓN 3: Forzar primera actualización
	_force_first_update()
	
	print("✅ PARCHE APLICADO - Preview debería funcionar ahora")

func _replace_with_texture_rect():
	# Ocultar todos los hijos del ViewportContainer
	for child in ui_viewport_container.get_children():
#		child.visible = false
		child.set_process(false)
		child.set_physics_process(false)
	
	# Crear TextureRect
	texture_rect = TextureRect.new()
	texture_rect.name = "PreviewTextureRect"
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_viewport_container.add_child(texture_rect)
	
	print("  ✓ TextureRect creado")

func _setup_texture_sync():
	# Crear timer para actualización
	sync_timer = Timer.new()
	sync_timer.name = "PreviewSyncTimer"
	sync_timer.wait_time = 1.0 / 30.0  # 30 FPS
	sync_timer.one_shot = false
	add_child(sync_timer)
	
	# Conectar actualización
	sync_timer.timeout.connect(_update_texture)
	sync_timer.start()
	
	print("  ✓ Sincronización configurada")

func _update_texture():
	if not render_viewport or not texture_rect:
		return
	
	# Actualizar solo si el viewport tiene contenido
	if render_viewport.get_child_count() > 1:  # Camera + Model
		var texture = render_viewport.get_texture()
		if texture:
			texture_rect.texture = texture

func _force_first_update():
	# Esperar un frame
	await get_tree().process_frame
	
	# Forzar renderizado
	if render_viewport:
		render_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Esperar otro frame
	await get_tree().process_frame
	
	# Aplicar textura
	if render_viewport and texture_rect:
		var texture = render_viewport.get_texture()
		if texture:
			texture_rect.texture = texture
			print("  ✓ Primera textura aplicada")
			
			# Buscar y ocultar label de "no preview"
			_hide_no_preview_labels()

func _hide_no_preview_labels():
	# Buscar y ocultar cualquier label que diga "no preview"
	for child in ui_viewport_container.get_children():
		if child is Label:
			child.visible = false
	
	# También buscar en el padre
	var parent = ui_viewport_container.get_parent()
	if parent:
		for child in parent.get_children():
			if child is Label and ("preview" in child.text.to_lower() or 
									"selecciona" in child.text.to_lower()):
				child.visible = false

func _find_node_by_name(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	
	for child in root.get_children():
		var result = _find_node_by_name(child, name)
		if result:
			return result
	
	return null

# Función para verificar el estado
func verify_fix():
	print("\n=== VERIFICACIÓN DEL PARCHE ===")
	print("Render Viewport: %s" % (render_viewport.get_path() if render_viewport else "NULL"))
	print("UI Container: %s" % (ui_viewport_container.get_path() if ui_viewport_container else "NULL"))
	print("TextureRect: %s" % (texture_rect.name if texture_rect else "NULL"))
	if texture_rect and texture_rect.texture:
		print("  Texture size: %s" % texture_rect.texture.get_size())
	print("Timer activo: %s" % (not sync_timer.is_stopped() if sync_timer else "NO"))
	print("==============================\n")

# Método para aplicar desde main.gd
static func apply_to_scene(main_node: Node):
	var fix = preload("res://scripts/fixes/quick_preview_fix.gd").new()
	fix.name = "QuickPreviewFix"
	main_node.add_child(fix)
