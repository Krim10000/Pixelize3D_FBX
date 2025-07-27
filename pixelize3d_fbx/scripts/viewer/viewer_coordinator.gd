# scripts/viewer/viewer_coordinator.gd
# Coordinador CORREGIDO - ACUMULA animaciones en lugar de reemplazar el modelo
# Input: Señales de componentes UI (selección de archivos, configuraciones, etc.)
# Output: Coordinación entre componentes, modelo combinado con TODAS las animaciones

extends Control

# Referencias a componentes existentes del sistema principal
@onready var fbx_loader = $FBXLoader
@onready var animation_manager = $AnimationManager
@onready var sprite_renderer = $SpriteRenderer
@onready var camera_controller = $HSplitContainer/RightPanel/ModelPreviewPanel/ViewportContainer/SubViewport/CameraController

# Referencias a paneles UI especializados
@onready var file_loader_panel = $HSplitContainer/LeftPanel/VBoxContainer/FileLoaderPanel
@onready var settings_panel = $HSplitContainer/LeftPanel/VBoxContainer/SettingsPanel
@onready var actions_panel = $HSplitContainer/LeftPanel/VBoxContainer/ActionsPanel
@onready var model_preview_panel = $HSplitContainer/RightPanel/ModelPreviewPanel
@onready var animation_controls_panel = $HSplitContainer/RightPanel/AnimationControlsPanel
@onready var log_panel = $HSplitContainer/RightPanel/LogPanel

# Variables para almacenar datos cargados temporalmente
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null

func _ready():
	_connect_ui_signals()
	_connect_system_signals()
	log_panel.add_log("✅ Coordinador inicializado - Todos los componentes conectados")
	
	# Debug de componentes encontrados
	_debug_component_status()

func _debug_component_status():
	"""Debug de estado de componentes al inicio"""
	print("\n🔍 === DEBUG COMPONENTES ===")
	
	var components = {
		"fbx_loader": fbx_loader,
		"animation_manager": animation_manager,
		"sprite_renderer": sprite_renderer,
		"camera_controller": camera_controller,
		"file_loader_panel": file_loader_panel,
		"settings_panel": settings_panel,
		"actions_panel": actions_panel,
		"model_preview_panel": model_preview_panel,
		"animation_controls_panel": animation_controls_panel,
		"log_panel": log_panel
	}
	
	for comp_name in components:
		var comp = components[comp_name]
		if comp:
			print("✅ %s: %s" % [comp_name, comp.name])
			if comp_name == "animation_controls_panel":
				# Debug especial para animation controls
				var signals = comp.get_signal_list()
				print("  Señales disponibles: %s" % str(signals.map(func(s): return s.name)))
		else:
			print("❌ %s: NO ENCONTRADO" % comp_name)
	
	print("🔍 =========================\n")

func _connect_ui_signals():
	"""Conectar señales de UI con manejo seguro de errores"""
	print("🔗 Conectando señales de UI...")
	
	# Conexiones básicas de file loader
	if file_loader_panel:
		_safe_connect(file_loader_panel, "file_selected", _on_file_selected)
		_safe_connect(file_loader_panel, "unit_selected", _on_unit_selected)
		_safe_connect(file_loader_panel, "animations_selected", _on_animations_selected)
	
	# Conexiones de settings panel
	if settings_panel:
		_safe_connect(settings_panel, "settings_changed", _on_settings_changed)
	
	# Conexiones de actions panel
	if actions_panel:
		_safe_connect(actions_panel, "preview_requested", _on_preview_requested)
		_safe_connect(actions_panel, "render_requested", _on_render_requested)
	
	# CONEXIONES CRÍTICAS: Animation controls panel
	if animation_controls_panel:
		print("🎭 Conectando señales de animation_controls_panel...")
		
		# Conectar con manejo seguro
		_safe_connect(animation_controls_panel, "animation_selected", _on_animation_selected)
		_safe_connect(animation_controls_panel, "play_requested", _on_play_requested)
		_safe_connect(animation_controls_panel, "pause_requested", _on_pause_requested)
		_safe_connect(animation_controls_panel, "stop_requested", _on_stop_requested)
		_safe_connect(animation_controls_panel, "timeline_changed", _on_timeline_changed)
		
		print("✅ Señales de animation_controls_panel conectadas")
	else:
		print("❌ animation_controls_panel no encontrado")

func _safe_connect(source: Node, signal_name: String, target_method: Callable):
	"""Conectar señal de forma segura con manejo de errores"""
	if not source:
		print("❌ Fuente nula para señal: %s" % signal_name)
		return false
	
	if not source.has_signal(signal_name):
		print("⚠️ Señal '%s' no existe en %s" % [signal_name, source.name])
		return false
	
	if source.get_signal_connection_list(signal_name).size() > 0:
		# Ya está conectada
		print("ℹ️ Señal '%s' ya está conectada en %s" % [signal_name, source.name])
		return true
	
	var result = source.connect(signal_name, target_method)
	if result == OK:
		print("✅ Conectada: %s.%s" % [source.name, signal_name])
		return true
	else:
		print("❌ Error conectando %s.%s: %d" % [source.name, signal_name, result])
		return false

func _connect_system_signals():
	"""Conectar señales del sistema con debugging"""
	print("🔗 Conectando señales del sistema...")
	
	if fbx_loader:
		_safe_connect(fbx_loader, "model_loaded", _on_model_loaded)
		_safe_connect(fbx_loader, "load_failed", _on_load_failed)
		print("✅ Señales de FBXLoader conectadas")
	
	if sprite_renderer:
		_safe_connect(sprite_renderer, "frame_rendered", _on_frame_rendered)
		print("✅ Señales de SpriteRenderer conectadas")

# === MANEJADORES DE SEÑALES DE ARCHIVOS ===
func _on_file_selected(file_path: String):
	log_panel.add_log("📁 Archivo seleccionado: " + file_path.get_file())
	_load_fbx_file(file_path)

func _on_unit_selected(unit_data: Dictionary):
	log_panel.add_log("📦 Unidad seleccionada: " + unit_data.name)
	# Limpiar datos previos al cambiar de unidad
	_clear_loaded_data()
	file_loader_panel.populate_unit_files(unit_data)

func _on_animations_selected(animation_files: Array):
	log_panel.add_log("🎬 Animaciones seleccionadas: " + str(animation_files))
	
	# Cargar cada animación seleccionada
	for anim_file in animation_files:
		if file_loader_panel.current_unit_data.has("path"):
			var full_path = file_loader_panel.current_unit_data.path + "/" + anim_file
			log_panel.add_log("📥 Cargando animación: " + anim_file)
			print("🔄 Llamando load_animation_fbx: %s" % full_path)
			fbx_loader.load_animation_fbx(full_path, anim_file.get_basename())

# === MANEJADORES DE SEÑALES DE CONFIGURACIÓN ===
func _on_settings_changed(settings: Dictionary):
	log_panel.add_log("⚙️ Configuración actualizada")
	# Aplicar a cámara si es necesario
	if camera_controller.has_method("apply_settings"):
		camera_controller.apply_settings(settings)

# === MANEJADORES DE SEÑALES DE ACCIONES ===
func _on_preview_requested():
	log_panel.add_log("🎬 Preview solicitado")
	if current_combined_model:
		model_preview_panel.enable_preview_mode()
	else:
		log_panel.add_log("❌ No hay modelo combinado disponible para preview")

func _on_render_requested():
	log_panel.add_log("🎨 Renderizado solicitado")
	# Delegar al sistema existente
	var selected_animations = file_loader_panel.get_selected_animations() if file_loader_panel.has_method("get_selected_animations") else []
	var render_settings = settings_panel.get_settings() if settings_panel.has_method("get_settings") else {}
	
	if selected_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones seleccionadas")
		return
	
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base cargado")
		return
	
	_start_rendering(selected_animations, render_settings)

# === MANEJADORES DE SEÑALES DE CONTROLES DE ANIMACIÓN ===
func _on_animation_selected(animation_name: String):
	print("🎭 COORDINATOR: Animación seleccionada: %s" % animation_name)
	log_panel.add_log("🎭 Animación seleccionada: " + animation_name)
	
	# Opcional: Delegar al model_preview_panel para cambiar animación
	if model_preview_panel and model_preview_panel.has_method("play_animation"):
		print("🔄 Delegando cambio al model_preview_panel")
		model_preview_panel.play_animation(animation_name)

func _on_play_requested(animation_name: String):
	print("▶️ COORDINATOR: Play solicitado: %s" % animation_name)
	log_panel.add_log("▶️ Reproduciendo: " + animation_name)

func _on_pause_requested():
	print("⏸️ COORDINATOR: Pause solicitado")
	log_panel.add_log("⏸️ Animación pausada")

func _on_stop_requested():
	print("⏹️ COORDINATOR: Stop solicitado")
	log_panel.add_log("⏹️ Animación detenida")

func _on_timeline_changed(position: float):
	# Debug opcional para timeline
	# print("📍 Timeline: %.2fs" % position)
	pass

# === MANEJADORES DE SEÑALES DEL SISTEMA ===
func _on_model_loaded(model_data: Dictionary):
	print("📦 COORDINATOR: Modelo cargado - %s" % model_data.get("name", "Desconocido"))
	
	var file_type = model_data.get("type", "unknown")
	var model_name = model_data.get("name", "Unnamed")
	
	# CORRECCIÓN CRÍTICA: Arreglar nombres de animaciones antes de procesar
	if file_type == "animation" and model_data.has("animation_player"):
		var name_fix = preload("res://scripts/core/animation_name_fix.gd")
		model_data = name_fix.process_loaded_model(model_data)
		
		# Debug de animaciones después de la corrección
		name_fix.debug_animation_names(model_data.animation_player, "Después de corrección")
	
	if file_type == "base":
		print("🏗️ Modelo base detectado: %s" % model_name)
		loaded_base_data = model_data
		log_panel.add_log("✅ Modelo base cargado: " + model_name)
	elif file_type == "animation":
		print("🎭 Animación detectada: %s" % model_name)
		loaded_animations[model_name] = model_data
		log_panel.add_log("✅ Animación cargada: " + model_name)
	
	# Intentar combinación automática
	_try_combine_and_preview()

func _on_load_failed(error: String):
	print("❌ COORDINATOR: Error de carga - %s" % error)
	log_panel.add_log("❌ Error de carga: " + error)

func _on_frame_rendered(frame_data: Dictionary):
	# Manejar frames renderizados si es necesario
	pass

# === FUNCIONES DE COMBINACIÓN ===
func _load_fbx_file(file_path: String):
	"""Cargar archivo FBX detectando tipo automáticamente"""
	var file_name = file_path.get_file().get_basename()
	
	# Detectar tipo por nombre
	var is_base = file_name.to_lower().contains("base") or not file_name.to_lower().contains("walk") and not file_name.to_lower().contains("run") and not file_name.to_lower().contains("idle")
	
	if is_base:
		print("🏗️ Cargando como base: %s" % file_path)
		fbx_loader.load_base_model(file_path)
	else:
		print("🎭 Cargando como animación: %s" % file_path)
		fbx_loader.load_animation_fbx(file_path, file_name)

func _try_combine_and_preview():
	"""CORREGIDO: Combinar y acumular animaciones en lugar de reemplazar"""
	print("🔄 Intentando combinación - Base: %s, Anims: %d" % [not loaded_base_data.is_empty(), loaded_animations.size()])
	
	# Verificar que tenemos los datos necesarios
	if loaded_base_data.is_empty():
		log_panel.add_log("⏳ Esperando modelo base...")
		return
	
	if loaded_animations.is_empty():
		log_panel.add_log("⏳ Esperando animaciones...")
		return
	
	# CORRECCIÓN CRÍTICA: Verificar si ya tenemos un modelo combinado
	if current_combined_model == null:
		# Primera vez: crear modelo combinado
		log_panel.add_log("🔄 Creando modelo combinado inicial...")
		print("🔄 Primera combinación - Creando modelo base...")
		
		# Obtener primera animación para la combinación inicial
		var first_anim_name = loaded_animations.keys()[0]
		var first_anim_data = loaded_animations[first_anim_name]
		
		log_panel.add_log("🎭 Combinando con: " + first_anim_name)
		print("🎭 Usando animación inicial: %s" % first_anim_name)
		
		# Crear modelo combinado inicial
		current_combined_model = animation_manager.combine_base_with_animation(
			loaded_base_data, 
			first_anim_data
		)
		
		if current_combined_model:
			log_panel.add_log("✅ Modelo combinado inicial creado")
			print("✅ Modelo base creado exitosamente")
		else:
			log_panel.add_log("❌ Error al crear modelo inicial")
			print("❌ Error en combinación inicial")
			return
	
	# NUEVA FUNCIONALIDAD: Agregar animaciones adicionales al modelo existente
	var existing_anim_player = current_combined_model.get_node_or_null("AnimationPlayer")
	if existing_anim_player:
		var existing_anims = existing_anim_player.get_animation_list()
		print("🎭 Modelo actual tiene: %s" % str(existing_anims))
		
		# Verificar qué animaciones nuevas necesitamos agregar
		var new_animations_to_add = []
		for anim_name in loaded_animations.keys():
			if not existing_anim_player.has_animation(anim_name):
				new_animations_to_add.append(anim_name)
		
		# Agregar animaciones nuevas
		for anim_name in new_animations_to_add:
			var anim_data = loaded_animations[anim_name]
			print("➕ Agregando nueva animación: %s" % anim_name)
			log_panel.add_log("➕ Agregando animación: " + anim_name)
			
			if _add_animation_to_existing_model(current_combined_model, anim_data):
				print("✅ Animación agregada: %s" % anim_name)
			else:
				print("❌ Error agregando: %s" % anim_name)
	
	# Configurar preview con modelo combinado (actualizado)
	if current_combined_model:
		log_panel.add_log("✅ Modelo con todas las animaciones listo")
		print("✅ Configurando preview con modelo actualizado...")
		
		# Configurar preview panel
		if model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
			print("✅ Modelo pasado a preview panel")
		
		# CRÍTICO: Actualizar controles de animación con TODAS las animaciones
		if animation_controls_panel.has_method("populate_animations"):
			animation_controls_panel.populate_animations(current_combined_model)
			print("✅ Controles de animación actualizados")
		else:
			print("❌ animation_controls_panel no tiene populate_animations")
		
		# Habilitar botón de preview
		if actions_panel and actions_panel.has_method("enable_preview_button"):
			actions_panel.enable_preview_button()
		
		# Debug del modelo final
		var final_anim_player = current_combined_model.get_node_or_null("AnimationPlayer")
		if final_anim_player:
			print("🎯 MODELO FINAL: %d animaciones total" % final_anim_player.get_animation_list().size())
			print("   Animaciones: %s" % str(final_anim_player.get_animation_list()))
		
		log_panel.add_log("🎬 Preview listo con %d animaciones" % final_anim_player.get_animation_list().size())

func _add_animation_to_existing_model(combined_model: Node3D, new_anim_data: Dictionary) -> bool:
	"""MEJORADA: Agregar una animación a un modelo combinado existente"""
	print("➕ DEBUG: Intentando agregar animación...")
	print("  Modelo: %s" % combined_model.name)
	print("  Nueva animación: %s" % new_anim_data.get("name", "SIN_NOMBRE"))
	
	var existing_anim_player = combined_model.get_node_or_null("AnimationPlayer")
	var new_anim_player = new_anim_data.get("animation_player", null)
	
	if not existing_anim_player:
		print("❌ No se encontró AnimationPlayer existente")
		return false
	
	if not new_anim_player:
		print("❌ No se encontró AnimationPlayer en nueva animación")
		return false
	
	print("  AnimationPlayer existente: %d animaciones" % existing_anim_player.get_animation_list().size())
	print("  AnimationPlayer nuevo: %d animaciones" % new_anim_player.get_animation_list().size())
	
	# Debug de nombres antes de copiar
	print("  Animaciones existentes: %s" % str(existing_anim_player.get_animation_list()))
	print("  Animaciones nuevas: %s" % str(new_anim_player.get_animation_list()))
	
	# Copiar cada animación del nuevo AnimationPlayer al existente
	var animations_added = 0
	var anim_lib_source = new_anim_player.get_animation_library("")
	var anim_lib_dest = existing_anim_player.get_animation_library("")
	
	if not anim_lib_source or not anim_lib_dest:
		print("❌ No se pudieron obtener las librerías de animación")
		return false
	
	for anim_name in new_anim_player.get_animation_list():
		print("  🔍 Procesando animación: '%s'" % anim_name)
		
		if existing_anim_player.has_animation(anim_name):
			print("    ⚠️ Ya existe, saltando: '%s'" % anim_name)
			continue
		
		# Obtener la animación del player de origen
		var animation = anim_lib_source.get_animation(anim_name)
		
		if animation:
			# Crear una copia de la animación
			var animation_copy = animation.duplicate()
			
			if animation_copy:
				# Agregar la animación al player de destino
				var add_result = anim_lib_dest.add_animation(anim_name, animation_copy)
				
				if add_result == OK:
					print("    ✅ Animación copiada: %s (%.2fs)" % [anim_name, animation.length])
					animations_added += 1
				else:
					print("    ❌ Error agregando animación al destino: %s" % anim_name)
			else:
				print("    ❌ Error duplicando animación: %s" % anim_name)
		else:
			print("    ❌ No se pudo obtener animación: %s" % anim_name)
	
	if animations_added > 0:
		print("  🔧 Aplicando post-procesamiento a %d nuevas animaciones..." % animations_added)
		
		# Aplicar retargeting a las nuevas animaciones
		var skeleton = combined_model.get_node_or_null("Skeleton3D_combined")
		if skeleton:
			# Cargar el script de retargeting
			var retargeting_fix = preload("res://scripts/core/animation_retargeting_fix.gd")
			
			# Solo retargetear las animaciones nuevas
			var success = retargeting_fix.fix_animation_retargeting(
				existing_anim_player, 
				new_anim_data.skeleton.name, 
				skeleton.name
			)
			
			if success:
				print("    ✅ Retargeting aplicado a nuevas animaciones")
			else:
				print("    ⚠️ Warning: Retargeting falló, pero animaciones agregadas")
		
		# Configurar loops para las nuevas animaciones
		var loop_manager = preload("res://scripts/core/animation_loop_manager.gd")
		loop_manager.setup_infinite_loops(existing_anim_player)
		
		print("    🔄 Loops configurados para todas las animaciones")
		print("  ✅ Total animaciones en modelo: %d" % existing_anim_player.get_animation_list().size())
		return true
	else:
		print("  ❌ No se agregaron animaciones nuevas")
		return false

# === FUNCIONES DE LIMPIEZA ===
func _clear_loaded_data():
	"""Limpiar datos cargados"""
	loaded_base_data.clear()
	loaded_animations.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Resetear controles de animación
	if animation_controls_panel and animation_controls_panel.has_method("reset_controls"):
		animation_controls_panel.reset_controls()
	
	log_panel.add_log("🧹 Datos de modelos limpiados")

# === FUNCIONES DE RENDERIZADO ===
func _start_rendering(animations: Array, settings: Dictionary):
	"""Delegar renderizado al sistema principal"""
	log_panel.add_log("🚀 Iniciando renderizado de %d animaciones" % animations.size())
	
	# Esta función debe conectar con tu sistema de renderizado principal (main.gd)
	log_panel.add_log("📝 Datos de renderizado:")
	log_panel.add_log("  • Base: " + loaded_base_data.get("name", "desconocido"))
	log_panel.add_log("  • Animaciones: " + str(animations))
	log_panel.add_log("  • Configuración: " + str(settings.keys()))
	
	# TODO: Aquí conectarías con tu main.gd existente o sprite_renderer
	# Ejemplo: get_tree().call_group("main_system", "start_batch_rendering", loaded_base_data, loaded_animations, settings)

# === FUNCIONES DE DEBUG ===
func get_current_state() -> Dictionary:
	"""Obtener estado actual (útil para debugging)"""
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_loaded": loaded_animations.size(),
		"combined_model_ready": current_combined_model != null,
		"animation_names": loaded_animations.keys()
	}

func debug_all_connections():
	"""Debug de todas las conexiones de señales"""
	print("\n🔍 === DEBUG CONEXIONES ===")
	
	if animation_controls_panel:
		print("🎭 Animation Controls Panel:")
		var signals = ["animation_selected", "play_requested", "pause_requested", "stop_requested"]
		
		for signal_name in signals:
			if animation_controls_panel.has_signal(signal_name):
				var connections = animation_controls_panel.get_signal_connection_list(signal_name)
				print("  %s: %d conexiones" % [signal_name, connections.size()])
			else:
				print("  %s: ❌ SEÑAL NO EXISTE" % signal_name)
	
	print("🔍 =======================\n")

func test_animation_controls():
	"""Función de test para animation controls"""
	print("🧪 PROBANDO ANIMATION CONTROLS...")
	
	if animation_controls_panel:
		if animation_controls_panel.has_method("debug_state"):
			animation_controls_panel.debug_state()
		
		if animation_controls_panel.has_method("test_change_animation"):
			animation_controls_panel.test_change_animation()
	else:
		print("❌ animation_controls_panel no disponible")
