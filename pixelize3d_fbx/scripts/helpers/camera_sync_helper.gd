# scripts/helpers/camera_sync_helper.gd
# Helper para sincronización automática entre ModelPreviewPanel y SpriteRenderer
# Input: Inicialización automática al cargar escena
# Output: Sincronización perfecta entre preview y render

extends Node

# Referencias a sistemas
var model_preview_panel: Control
var sprite_renderer: Node3D
var viewer_coordinator: Control

# Estado de sincronización
var sync_active: bool = false
var last_camera_state: Dictionary = {}

func _ready():
	print("🔗 CameraSyncHelper iniciado")
	call_deferred("_auto_setup_sync")

func _auto_setup_sync():
	"""Configurar sincronización automática al inicio"""
	print("🔧 Configurando sincronización automática...")
	
	# Buscar componentes
	_find_components()
	
	# Establecer sincronización
	_setup_synchronization()
	
	# Validar configuración
	_validate_sync_setup()

func _find_components():
	"""Buscar componentes en la escena"""
	# Buscar ViewerCoordinator
	viewer_coordinator = _find_node_by_name(get_tree().root, "ViewerModular")
	if viewer_coordinator:
		print("✅ ViewerCoordinator encontrado: %s" % viewer_coordinator.get_path())
	
	# Buscar ModelPreviewPanel
	model_preview_panel = _find_node_by_name(get_tree().root, "ModelPreviewPanel")
	if model_preview_panel:
		print("✅ ModelPreviewPanel encontrado: %s" % model_preview_panel.get_path())
	
	# Buscar SpriteRenderer
	sprite_renderer = _find_node_by_name(get_tree().root, "SpriteRenderer")
	if sprite_renderer:
		print("✅ SpriteRenderer encontrado: %s" % sprite_renderer.get_path())

func _setup_synchronization():
	"""Establecer sincronización entre sistemas"""
	if not model_preview_panel or not sprite_renderer:
		push_error("❌ No se pueden sincronizar - componentes faltantes")
		return
	
	print("🔗 Estableciendo sincronización...")
	
	# Conectar señales del ModelPreviewPanel si están disponibles
	_connect_preview_signals()
	
	# Forzar que SpriteRenderer use referencias del preview
	_force_sprite_renderer_sync()
	
	sync_active = true
	print("✅ Sincronización establecida")

func _connect_preview_signals():
	"""Conectar señales del preview para sincronización"""
	if not model_preview_panel:
		return
	
	# Conectar bounds_calculated para sincronizar cámara
	if model_preview_panel.has_signal("bounds_calculated"):
		if not model_preview_panel.bounds_calculated.is_connected(_on_preview_bounds_changed):
			model_preview_panel.bounds_calculated.connect(_on_preview_bounds_changed)
			print("🔗 Señal bounds_calculated conectada")
	
	# Conectar preview_ready
	if model_preview_panel.has_signal("preview_ready"):
		if not model_preview_panel.preview_ready.is_connected(_on_preview_ready):
			model_preview_panel.preview_ready.connect(_on_preview_ready)
			print("🔗 Señal preview_ready conectada")

func _force_sprite_renderer_sync():
	"""Forzar que SpriteRenderer use las referencias del preview"""
	if not sprite_renderer:
		return
	
	print("🔄 Forzando sincronización de SpriteRenderer...")
	
	# Si el SpriteRenderer ya tiene el método nuevo, úsalo
	if sprite_renderer.has_method("_initialize_shared_references"):
		sprite_renderer._initialize_shared_references()
		print("✅ SpriteRenderer sincronizado usando método nuevo")
	else:
		# Fallback: forzar referencias manualmente
		_manual_reference_sync()

func _manual_reference_sync():
	"""Sincronización manual de referencias como fallback"""
	print("🔧 Aplicando sincronización manual...")
	
	# Obtener viewport del preview
	var preview_viewport = _get_preview_viewport()
	if preview_viewport and sprite_renderer.has_method("set"):
		# Intentar establecer viewport directamente
		sprite_renderer.viewport = preview_viewport
		print("📺 Viewport sincronizado manualmente")
	
	# Obtener cámara del preview
	var preview_camera = _get_preview_camera()
	if preview_camera and sprite_renderer.has_method("set"):
		sprite_renderer.camera = preview_camera
		print("📸 Cámara sincronizada manualmente")

func _get_preview_viewport() -> SubViewport:
	"""Obtener viewport del preview"""
	if not model_preview_panel:
		return null
	
	var viewport_container = model_preview_panel.get_node_or_null("ViewportContainer")
	if viewport_container:
		return viewport_container.get_node_or_null("SubViewport")
	
	return null

func _get_preview_camera() -> Camera3D:
	"""Obtener cámara del preview"""
	var viewport = _get_preview_viewport()
	if viewport:
		return viewport.get_node_or_null("Camera3D")
	
	return null

func _get_preview_camera_controller() -> Node3D:
	"""Obtener camera controller del preview"""
	var viewport = _get_preview_viewport()
	if viewport:
		return viewport.get_node_or_null("CameraController")
	
	return null

# ========================================================================
# MANEJO DE SEÑALES
# ========================================================================

func _on_preview_bounds_changed(bounds: AABB):
	"""Manejar cambio de bounds en preview"""
	print("📐 Bounds del preview cambiaron: %s" % str(bounds))
	
	# El SpriteRenderer automáticamente usará la misma cámara,
	# por lo que no necesitamos hacer nada extra aquí
	last_camera_state["bounds"] = bounds

func _on_preview_ready():
	"""Manejar cuando preview está listo"""
	print("🎬 Preview listo - verificando sincronización")
	_validate_sync_setup()

# ========================================================================
# VALIDACIÓN Y DEBUG
# ========================================================================

func _validate_sync_setup():
	"""Validar que la sincronización esté correcta"""
	print("🔍 Validando configuración de sincronización...")
	
	var preview_viewport = _get_preview_viewport()
	var preview_camera = _get_preview_camera()
	var preview_controller = _get_preview_camera_controller()
	
	print("📊 Estado de sincronización:")
	print("  Preview Viewport: %s" % ("✅" if preview_viewport else "❌"))
	print("  Preview Camera: %s" % ("✅" if preview_camera else "❌"))
	print("  Preview Controller: %s" % ("✅" if preview_controller else "❌"))
	
	if sprite_renderer:
		var sprite_viewport = sprite_renderer.get("viewport")
		var sprite_camera = sprite_renderer.get("camera")
		
		print("  SpriteRenderer Viewport: %s" % ("✅" if sprite_viewport else "❌"))
		print("  SpriteRenderer Camera: %s" % ("✅" if sprite_camera else "❌"))
		
		# Verificar si están usando las mismas referencias
		if preview_viewport and sprite_viewport:
			var same_viewport = (preview_viewport == sprite_viewport)
			print("  ✅ MISMO VIEWPORT: %s" % ("SÍ" if same_viewport else "NO"))
			
			if same_viewport:
				print("🎯 SINCRONIZACIÓN PERFECTA CONFIRMADA")
			else:
				print("⚠️ VIEWPORT DIFERENTE - Corrigiendo...")
				_force_sprite_renderer_sync()
	
	if sync_active:
		print("✅ Sincronización validada correctamente")
	else:
		print("❌ Problemas en sincronización detectados")

# ========================================================================
# API PÚBLICA
# ========================================================================

func get_shared_viewport() -> SubViewport:
	"""API pública para obtener viewport compartido"""
	return _get_preview_viewport()

func get_shared_camera() -> Camera3D:
	"""API pública para obtener cámara compartida"""
	return _get_preview_camera()

func get_shared_camera_controller() -> Node3D:
	"""API pública para obtener camera controller compartido"""
	return _get_preview_camera_controller()

func is_sync_active() -> bool:
	"""Verificar si la sincronización está activa"""
	return sync_active

func force_resync():
	"""Forzar re-sincronización manual"""
	print("🔄 Forzando re-sincronización...")
	_setup_synchronization()

func debug_sync_state():
	"""Debug completo del estado de sincronización"""
	print("\n🔗 === CAMERA SYNC DEBUG ===")
	print("Sync activo: %s" % sync_active)
	print("ModelPreviewPanel: %s" % ("✅" if model_preview_panel else "❌"))
	print("SpriteRenderer: %s" % ("✅" if sprite_renderer else "❌"))
	
	var preview_viewport = _get_preview_viewport()
	var preview_camera = _get_preview_camera()
	
	if preview_viewport:
		print("Preview Viewport path: %s" % preview_viewport.get_path())
		print("Preview Viewport size: %s" % str(preview_viewport.size))
	
	if preview_camera:
		print("Preview Camera path: %s" % preview_camera.get_path())
		print("Preview Camera position: %s" % str(preview_camera.position))
	
	if sprite_renderer:
		if sprite_renderer.has_method("debug_shared_state"):
			sprite_renderer.debug_shared_state()
	
	print("==============================\n")

# ========================================================================
# UTILIDADES
# ========================================================================

func _find_node_by_name(root: Node, node_name: String) -> Node:
	"""Buscar nodo por nombre recursivamente"""
	if root.name == node_name:
		return root
	
	for child in root.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

# ========================================================================
# AUTO-INICIALIZACIÓN PARA FÁCIL USO
# ========================================================================

# Función estática para uso fácil desde otros scripts
static func setup_automatic_sync():
	"""Configurar sincronización automática - llamar desde main scene"""
	var helper_script = load("res://scripts/helpers/camera_sync_helper.gd")
	var helper_instance = helper_script.new()
	helper_instance.name = "CameraSyncHelper"
	
	# Añadir a la escena principal
	var main_scene = Engine.get_main_loop().current_scene
	main_scene.add_child(helper_instance)
	
	print("🚀 CameraSyncHelper configurado automáticamente")
