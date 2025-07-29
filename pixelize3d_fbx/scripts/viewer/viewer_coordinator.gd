# scripts/viewer/viewer_coordinator.gd
# VERSIÓN LOOP BREAKER - Evita re-poblaciones automáticas
# Input: Señales de UI
# Output: Coordinación SIN loops infinitos

extends Control

# Referencias a paneles UI
@onready var file_loader_panel = find_child("FileLoaderPanel")
@onready var settings_panel = find_child("SettingsPanel") 
@onready var actions_panel = find_child("ActionsPanel")
@onready var animation_controls_panel = find_child("AnimationControlsPanel")
@onready var model_preview_panel = find_child("ModelPreviewPanel")
@onready var log_panel = find_child("LogPanel")

# Referencias a sistemas core
@onready var fbx_loader = get_node("FBXLoader")
@onready var animation_manager = get_node("AnimationManager")
@onready var sprite_renderer = get_node("SpriteRenderer")



# Datos del sistema
var loaded_base_data: Dictionary = {}
var loaded_animations: Dictionary = {}
var current_combined_model: Node3D = null

# 🛑 VARIABLES CRÍTICAS ANTI-LOOP
var is_processing_animations: bool = false
var last_animations_processed: Array = []
var processing_start_time: float = 0.0

func _ready():
	print("🎮 ViewerCoordinator LOOP BREAKER iniciado")
	await get_tree().process_frame
	_validate_and_connect()
	file_loader_panel.connect("animations_selected", Callable(self, "_on_animations_selected"))



func _validate_and_connect():
	"""Validar y conectar de forma segura"""
	print("🔍 Validando componentes...")
	
	# Validar componentes críticos
	if not fbx_loader:
		print("❌ FBXLoader no encontrado")
		return
	if not animation_manager:
		print("❌ AnimationManager no encontrado") 
		return
	if not file_loader_panel:
		print("❌ FileLoaderPanel no encontrado")
		return
	if not log_panel:
		print("❌ LogPanel no encontrado")
		return
	
	print("✅ Componentes validados")
	
	# Conectar señales CRÍTICAS SOLAMENTE
	_connect_essential_signals()

func _connect_essential_signals():
	"""Conectar solo señales esenciales"""
	print("🔗 Conectando señales esenciales...")
	#
	## FileLoaderPanel
	#if file_loader_panel:
		#file_loader_panel.file_selected.connect(_on_file_selected)
		#file_loader_panel.unit_selected.connect(_on_unit_selected)
		#file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		## ✅ REMOVIDO: combine_and_view_requested (no existe en archivo original)
		#print("✅ FileLoaderPanel conectado")
	#
	## FBX Loader
	#if fbx_loader:
		#fbx_loader.model_loaded.connect(_on_model_loaded)
		#fbx_loader.load_failed.connect(_on_load_failed)
		#print("✅ FBXLoader conectado")
	
	## Animation Manager
	#if animation_manager:
		#animation_manager.combination_complete.connect(_on_combination_complete_safe)
		#animation_manager.combination_failed.connect(_on_combination_failed)
		#print("✅ AnimationManager conectado")
	#
	#print("🔗 Conexiones esenciales completadas")


	print("🔗 Conectando señales esenciales...")
	
	# FileLoaderPanel
	if file_loader_panel:
		file_loader_panel.file_selected.connect(_on_file_selected)
		file_loader_panel.unit_selected.connect(_on_unit_selected)
		file_loader_panel.animations_selected.connect(_on_animations_selected_protected)
		print("✅ FileLoaderPanel conectado")
	
	# ✅ NUEVA CONEXIÓN CRÍTICA
	# AnimationControlsPanel QUIZAS 
	#if animation_controls_panel:
		#animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		#print("✅ AnimationControlsPanel conectado")
	
	# FBX Loader
	if fbx_loader:
		fbx_loader.model_loaded.connect(_on_model_loaded)
		fbx_loader.load_failed.connect(_on_load_failed)
		print("✅ FBXLoader conectado")
	
	# Animation Manager
	if animation_manager:
		animation_manager.combination_complete.connect(_on_combination_complete_safe)
		animation_manager.combination_failed.connect(_on_combination_failed)
		print("✅ AnimationManager conectado")
	
	print("🔗 Conexiones esenciales completadas")
# === MANEJADORES PROTEGIDOS ===

func _on_file_selected(file_path: String):
	"""Manejar selección de archivo"""
	print("📁 Archivo seleccionado: %s" % file_path.get_file())
	log_panel.add_log("📁 Cargando: " + file_path.get_file())
	
	# Detectar tipo SIMPLE
	var is_base = "base" in file_path.get_file().to_lower()
	
	if is_base:
		print("🏗️ Cargando como BASE")
		fbx_loader.load_base_model(file_path)
	else:
		print("🎭 Cargando como ANIMACIÓN")
		fbx_loader.load_animation_fbx(file_path)

func _on_unit_selected(unit_data: Dictionary):
	"""Manejar selección de unidad"""
	print("📦 Unidad seleccionada: %s" % unit_data.get("name", "Unknown"))
	log_panel.add_log("📦 Unidad: " + str(unit_data.get("name", "Unknown")))
	
	# 🛑 CRITICAL: NO auto-poblar aquí para evitar loops
	# Solo pasar los datos si el panel lo solicita
	if file_loader_panel and file_loader_panel.has_method("populate_unit_files"):
		file_loader_panel.populate_unit_files(unit_data)

#func _on_animations_selected_protected(animation_files: Array):
	#"""Manejar selección de animaciones CON MÁXIMA PROTECCIÓN"""
	#print("\n🛑 === ANIMATIONS SELECTED PROTECTED ===")
	#print("Archivos recibidos: %s" % str(animation_files))
	#
	## 🛑 PROTECCIÓN 1: Evitar procesamiento simultáneo
	#if is_processing_animations:
		#var elapsed = Time.get_time_dict_from_system().second - processing_start_time
		#print("🛑 YA PROCESANDO ANIMACIONES (%.1fs transcurrido)" % elapsed)
		#if elapsed < 10:  # Si han pasado menos de 10 segundos, ignorar
			#print("🛑 IGNORANDO - muy pronto")
			#return
		#else:
			#print("⚠️ Timeout alcanzado, continuando...")
	#
	## 🛑 PROTECCIÓN 2: Evitar duplicados
	#if _arrays_equal(animation_files, last_animations_processed):
		#print("🛑 ANIMACIONES IDÉNTICAS - ignorando")
		#return
	#
	## 🛑 PROTECCIÓN 3: Validar datos básicos
	#if animation_files.is_empty():
		#print("🛑 ARRAY VACÍO - ignorando")
		#return
	#
	## 🛑 PROTECCIÓN 4: Verificar unit data
	#if not file_loader_panel or not file_loader_panel.has_method("get_current_unit_data"):
		#print("🛑 NO HAY UNIT DATA - ignorando")
		#return
	#
	#var unit_data = file_loader_panel.get_current_unit_data()
	#if unit_data.is_empty() or not unit_data.has("path"):
		#print("🛑 UNIT DATA INVÁLIDO - ignorando") 
		#return
	#
	## 🛑 MARCAR COMO PROCESANDO
	#is_processing_animations = true
	#processing_start_time = Time.get_time_dict_from_system().second
	#last_animations_processed = animation_files.duplicate()
	#
	#print("🔒 PROCESANDO ANIMACIONES - BLOQUEADO por 10 segundos")
	#log_panel.add_log("🎬 Cargando %d animaciones..." % animation_files.size())
	#
	## Cargar cada animación de forma secuencial CON DELAYS
	#for i in range(animation_files.size()):
		#var anim_file = animation_files[i]
		#var full_path = unit_data.path + "/" + anim_file
		#
		#print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		#log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])
		#
		#fbx_loader.load_animation_fbx(full_path)
		#
		## 🛑 DELAY entre cargas para evitar overflow
		#if i < animation_files.size() - 1:  # No delay después de la última
			#await get_tree().create_timer(1.0).timeout
	#
	## 🛑 DESBLOQUEAR después de un tiempo
	#await get_tree().create_timer(3.0).timeout
	#is_processing_animations = false
	#print("🔓 PROCESAMIENTO DE ANIMACIONES DESBLOQUEADO")
	#
	#print("=== FIN ANIMATIONS SELECTED ===\n")


func _on_animations_selected_protected(animation_files: Array):
	print("\n🛑 === ANIMATIONS SELECTED PROTECTED ===")
	print("Archivos recibidos: %s" % str(animation_files))

	# Protección 1: evitar carga múltiple
	if is_processing_animations:
		var elapsed = Time.get_time_dict_from_system().second - processing_start_time
		print("🛑 YA PROCESANDO ANIMACIONES (%.1fs transcurrido)" % elapsed)
		if elapsed < 10:
			print("🛑 IGNORANDO - muy pronto")
			return
		else:
			print("⚠️ Timeout alcanzado, continuando...")

	# Protección 2: evitar duplicados
	if _arrays_equal(animation_files, last_animations_processed):
		print("🛑 ANIMACIONES IDÉNTICAS - ignorando")
		return

	if animation_files.is_empty():
		print("🛑 ARRAY VACÍO - ignorando")
		return

	if not file_loader_panel or not file_loader_panel.has_method("get_current_unit_data"):
		print("🛑 NO HAY UNIT DATA - ignorando")
		return

	var unit_data = file_loader_panel.get_current_unit_data()
	if unit_data.is_empty() or not unit_data.has("path"):
		print("🛑 UNIT DATA INVÁLIDO - ignorando")
		return

	# Marcar como procesando
	is_processing_animations = true
	processing_start_time = Time.get_time_dict_from_system().second
	last_animations_processed = animation_files.duplicate()

	print("🔒 PROCESANDO ANIMACIONES - BLOQUEADO por 10 segundos")
	log_panel.add_log("🎬 Cargando %d animaciones..." % animation_files.size())

	# Cargar una por una
	for i in range(animation_files.size()):
		var anim_file = animation_files[i]
		var full_path = unit_data.path + "/" + anim_file

		print("📥 [%d/%d] Cargando: %s" % [i+1, animation_files.size(), anim_file])
		log_panel.add_log("📥 [%d/%d] %s" % [i+1, animation_files.size(), anim_file])

		fbx_loader.load_animation_fbx(full_path)

		if i < animation_files.size() - 1:
			await get_tree().create_timer(1.0).timeout  # Delay entre animaciones

	# Fin de carga
	await get_tree().create_timer(2.0).timeout
	is_processing_animations = false
	print("🔓 PROCESAMIENTO DE ANIMACIONES DESBLOQUEADO")

	# 🧠 AGREGADO: reproducir la última y actualizar paneles
	animation_controls_panel.update_animations_list(animation_files)

	var last_animation_path = animation_files[-1]
	var last_animation_name = last_animation_path.get_file().get_basename()

	animation_controls_panel.select_animation_by_name(last_animation_name)
	model_preview_panel.play_animation(last_animation_name)

	print("✅ Animación aplicada: " + last_animation_name)
	print("=== FIN ANIMATIONS SELECTED ===\n")


func _arrays_equal(a: Array, b: Array) -> bool:
	"""Comparar arrays"""
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

func _on_model_loaded(model_data: Dictionary):
	"""Manejar modelo cargado CON AUTO-COMBINE CONTROLADO"""
	print("📦 Modelo cargado: %s (%s)" % [model_data.get("name", "Unknown"), model_data.get("type", "Unknown")])
	
	if model_data.type == "base":
		loaded_base_data = model_data
		log_panel.add_log("✅ Base: " + model_data.get("name", "Unknown"))
		print("🏗️ Base almacenada")
		
	elif model_data.type == "animation":
		var anim_name = model_data.name
		loaded_animations[anim_name] = model_data
		log_panel.add_log("✅ Anim: " + anim_name)
		print("🎭 Animación almacenada: %s" % anim_name)
		
		# ✅ AUTO-COMBINE CONTROLADO: Solo si tenemos base y es la primera animación
		if not loaded_base_data.is_empty() and loaded_animations.size() == 1:
			print("🔄 Auto-combinando primera animación...")
			_safe_auto_combine_first()
		
		print("📊 Estado actual: Base=%s, Anims=%d" % [not loaded_base_data.is_empty(), loaded_animations.size()])

func _safe_auto_combine_first():
	"""Auto-combinar primera animación de forma segura"""
	if loaded_base_data.is_empty() or loaded_animations.is_empty():
		return
	
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinación segura: base + %s" % first_anim_name)
	log_panel.add_log("🔄 Combinando automáticamente con: " + first_anim_name)
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	if combined:
		current_combined_model = combined
		print("✅ Auto-combinación exitosa")
		
		# ✅ POBLAR CONTROLES AUTOMÁTICAMENTE (solo una vez)
		_safe_populate_animation_controls()

func _on_load_failed(error: String):
	"""Manejar error de carga"""
	print("❌ Error: %s" % error)
	log_panel.add_log("❌ Error: " + error)

func _on_combination_complete_safe(combined_model: Node3D):
	"""Manejar combinación completa CON POPULATE SEGURO"""
	print("✅ Combinación completa")
	current_combined_model = combined_model
	log_panel.add_log("✅ Modelo combinado listo")
	
	# Actualizar preview panel
	if model_preview_panel and model_preview_panel.has_method("set_model"):
		model_preview_panel.set_model(current_combined_model)
		print("✅ Preview panel actualizado")
	
	# ✅ POBLAR CONTROLES DE ANIMACIÓN automáticamente
	_safe_populate_animation_controls()
	
	if actions_panel and actions_panel.has_method("enable_preview_button"):
		actions_panel.enable_preview_button()
		print("✅ Botón preview habilitado")

func _safe_populate_animation_controls():
	"""Poblar controles de animación de forma segura"""
	if not current_combined_model:
		print("❌ No hay modelo combinado para poblar controles")
		return
	
	if not animation_controls_panel:
		print("❌ No hay animation_controls_panel")
		return
	
	if not animation_controls_panel.has_method("populate_animations"):
		print("❌ populate_animations no disponible")
		return
	
	print("🎮 Poblando controles de animación AUTOMÁTICAMENTE")
	log_panel.add_log("🎮 Controles de animación listos")
	animation_controls_panel.populate_animations(current_combined_model)
	print("✅ Animation controls poblados exitosamente")

func _on_combination_failed(error: String):
	"""Manejar error de combinación"""
	print("❌ Error combinación: %s" % error)
	log_panel.add_log("❌ Error combinación: " + error)

# === FUNCIÓN PÚBLICA PARA COMBINAR MANUALMENTE ===

func combine_and_view():
	"""FUNCIÓN PÚBLICA: Combinar y preparar vista (callable desde consola)"""
	print("🔄 === COMBINACIÓN MANUAL PÚBLICA ===")
	log_panel.add_log("🔄 Combinando y preparando vista...")
	
	if loaded_base_data.is_empty():
		log_panel.add_log("❌ No hay modelo base cargado")
		print("❌ No hay base para combinar")
		return false
	
	if loaded_animations.is_empty():
		log_panel.add_log("❌ No hay animaciones cargadas")
		print("❌ No hay animaciones para combinar")
		return false
	
	# Combinar con la primera animación disponible
	var first_anim_name = loaded_animations.keys()[0]
	var first_anim_data = loaded_animations[first_anim_name]
	
	print("🔄 Combinación pública: base + %s" % first_anim_name)
	log_panel.add_log("🔄 Combinando con: " + first_anim_name)
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, first_anim_data)
	if combined:
		current_combined_model = combined
		print("✅ Combinación pública exitosa")
		log_panel.add_log("✅ Combinación exitosa - preparando controles...")
		
		# Actualizar preview
		if model_preview_panel and model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
		
		# Poblar controles de animación
		_safe_populate_animation_controls()
		
		# Habilitar preview
		if actions_panel and actions_panel.has_method("enable_preview_button"):
			actions_panel.enable_preview_button()
		
		log_panel.add_log("🎮 ¡Listo! Usa los controles de animación")
		return true
	else:
		log_panel.add_log("❌ Error en combinación")
		print("❌ Error en combinación")
		return false

# === FUNCIONES MANUALES MEJORADAS ===

func manual_combine_with_animation(animation_name: String = ""):
	"""Combinar manualmente con animación específica"""
	if loaded_base_data.is_empty():
		print("❌ No hay base para combinar")
		return false
	
	if loaded_animations.is_empty():
		print("❌ No hay animaciones para combinar")
		return false
	
	# Si no se especifica animación, usar la primera
	var target_anim_name = animation_name
	if target_anim_name == "" or not loaded_animations.has(target_anim_name):
		target_anim_name = loaded_animations.keys()[0]
	
	var anim_data = loaded_animations[target_anim_name]
	
	print("🔄 Combinación manual específica: base + %s" % target_anim_name)
	log_panel.add_log("🔄 Combinando con: " + target_anim_name)
	
	var combined = animation_manager.combine_base_with_animation(loaded_base_data, anim_data)
	if combined:
		current_combined_model = combined
		print("✅ Combinación manual exitosa")
		
		# Actualizar todo
		if model_preview_panel and model_preview_panel.has_method("set_model"):
			model_preview_panel.set_model(current_combined_model)
		
		_safe_populate_animation_controls()
		
		if actions_panel and actions_panel.has_method("enable_preview_button"):
			actions_panel.enable_preview_button()
		
		return true
	
	return false

func list_available_animations() -> Array:
	"""Listar animaciones disponibles para combinar"""
	return loaded_animations.keys()

func get_combination_status() -> String:
	"""Obtener estado de combinación legible"""
	if loaded_base_data.is_empty():
		return "❌ No hay modelo base"
	
	if loaded_animations.is_empty():
		return "❌ No hay animaciones"
	
	if current_combined_model == null:
		return "⚠️ Base y animaciones listas - usar 'Combinar y Ver'"
	
	return "✅ Modelo combinado listo con %d animaciones" % loaded_animations.size()

# === FUNCIONES PÚBLICAS ===

func get_current_state() -> Dictionary:
	"""Estado actual simple"""
	return {
		"base_loaded": not loaded_base_data.is_empty(),
		"animations_count": loaded_animations.size(),
		"combined_ready": current_combined_model != null,
		"processing": is_processing_animations
	}

func force_reset():
	"""Reset completo del coordinator"""
	print("🚨 FORCE RESET COORDINATOR")
	
	# Reset flags
	is_processing_animations = false
	last_animations_processed.clear()
	processing_start_time = 0.0
	
	# Clear data
	loaded_base_data.clear()
	loaded_animations.clear()
	
	if current_combined_model:
		current_combined_model.queue_free()
		current_combined_model = null
	
	# Reset panels
	if file_loader_panel and file_loader_panel.has_method("_emergency_reset"):
		file_loader_panel._emergency_reset()
	
	if animation_controls_panel and animation_controls_panel.has_method("reset_controls"):
		animation_controls_panel.reset_controls()
	
	print("✅ COORDINATOR RESET COMPLETO")

func debug_state():
	"""Debug detallado del estado"""
	print("\n🎮 === COORDINATOR DEBUG DETALLADO ===")
	var state = get_current_state()
	print("📊 ESTADO GENERAL:")
	print("  Base cargada: %s" % state.base_loaded)
	print("  Animaciones: %d" % state.animations_count)
	print("  Modelo combinado: %s" % state.combined_ready)
	print("  Procesando: %s" % state.processing)
	
	print("\n📁 ARCHIVOS CARGADOS:")
	if state.base_loaded:
		print("  Base: %s" % loaded_base_data.get("name", "Unknown"))
	
	print("  Animaciones cargadas:")
	for anim_name in loaded_animations.keys():
		print("    - %s" % anim_name)
	
	print("\n🔧 ESTADO DE COMBINACIÓN:")
	print("  %s" % get_combination_status())
	
	print("\n🎮 CONTROLES DE ANIMACIÓN:")
	if animation_controls_panel:
		if animation_controls_panel.has_method("has_animations"):
			var has_anims = animation_controls_panel.has_animations()
			print("  Controles poblados: %s" % has_anims)
		else:
			print("  Estado de controles: Desconocido")
	else:
		print("  ❌ No hay animation_controls_panel")
	
	print("\n💡 ACCIONES SUGERIDAS:")
	if not state.base_loaded:
		print("  1. Selecciona y carga un modelo base")
	elif state.animations_count == 0:
		print("  1. Selecciona animaciones con checkboxes")
	elif not state.combined_ready:
		print("  1. Desde consola ejecuta: get_node('ViewerModular').combine_and_view()")
		print("     O espera a que se auto-combine con la primera animación")
	else:
		print("  1. ✅ Todo listo - usa los controles de animación")
	
	print("\n🔧 COMANDOS ÚTILES DESDE CONSOLA:")
	print("  - get_node('ViewerModular').combine_and_view()")
	print("  - get_node('ViewerModular').debug_state()")
	print("  - get_node('ViewerModular').get_combination_status()")
	
	print("=========================================\n")


func _on_animations_selected(animations: Array) -> void:
	if animations.is_empty():
		animation_controls_panel.update_animations_list([])
		model_preview_panel.stop_animation()
		return

	animation_controls_panel.update_animations_list(animations)

	var last_animation_path = animations[-1]
	var last_animation_name = last_animation_path.get_file().get_basename()

	animation_controls_panel.select_animation_by_name(last_animation_name)
	model_preview_panel.play_animation(last_animation_name)



	# ✅ NUEVA CONEXIÓN CRÍTICA
	## AnimationControlsPanel
	#if animation_controls_panel:
		#animation_controls_panel.animation_change_requested.connect(_on_animation_change_requested)
		#print("✅ AnimationControlsPanel conectado")
	
	# FBX Loader
	#if fbx_loader:
		#fbx_loader.model_loaded.connect(_on_model_loaded)
		#fbx_loader.load_failed.connect(_on_load_failed)
		#print("✅ FBXLoader conectado")
	
	# Animation Manager
	#if animation_manager:
		#animation_manager.combination_complete.connect(_on_combination_complete_safe)
		#animation_manager.combination_failed.connect(_on_combination_failed)
		#print("✅ AnimationManager conectado")
	#
	print("🔗 Conexiones esenciales completadas")

## ✅ NUEVA FUNCIÓN: Manejar cambio de animación
#func _on_animation_change_requested(animation_name: String):
	#"""Manejar solicitud de cambio de animación desde los controles"""
	#print("\n🎭 === CAMBIO DE ANIMACIÓN SOLICITADO ===")
	#print("Animación solicitada: %s" % animation_name)
	#
	## Verificar que tenemos lo necesario
	#if loaded_base_data.is_empty():
		#print("❌ No hay modelo base para recombinar")
		#log_panel.add_log("❌ Error: No hay modelo base")
		#return
	#
	#if not loaded_animations.has(animation_name):
		#print("❌ Animación '%s' no está cargada" % animation_name)
		#log_panel.add_log("❌ Error: Animación no encontrada")
		#return
	#
	## Obtener datos de la animación
	#var anim_data = loaded_animations[animation_name]
	#
	#print("🔄 Re-combinando modelo con animación: %s" % animation_name)
	#log_panel.add_log("🔄 Cambiando a: " + animation_name)
	#
	## Combinar base con la nueva animación
	#var combined = animation_manager.combine_base_with_animation(loaded_base_data, anim_data)
	#
	#if combined:
		## Liberar modelo anterior si existe
		#if current_combined_model and is_instance_valid(current_combined_model):
			#current_combined_model.queue_free()
		#
		## Actualizar referencia
		#current_combined_model = combined
		#
		#print("✅ Re-combinación exitosa")
		#log_panel.add_log("✅ Animación cambiada")
		#
		## Actualizar preview con el nuevo modelo
		#if model_preview_panel and model_preview_panel.has_method("set_model"):
			#model_preview_panel.set_model(current_combined_model)
		#
		## ✅ CRÍTICO: Notificar al panel de controles que la re-combinación está lista
		#if animation_controls_panel and animation_controls_panel.has_method("on_model_recombined"):
			#animation_controls_panel.on_model_recombined(current_combined_model, animation_name)
		#
		## Actualizar otros paneles si es necesario
		#if actions_panel and actions_panel.has_method("enable_preview_button"):
			#actions_panel.enable_preview_button()
	#else:
		#print("❌ Falló la re-combinación")
		#log_panel.add_log("❌ Error al cambiar animación")
		#
		## Notificar error al panel de controles
		#if animation_controls_panel and animation_controls_panel.has_method("_reset_ui_on_error"):
			#animation_controls_panel._reset_ui_on_error("Falló la re-combinación")
	#
	#print("=== FIN CAMBIO DE ANIMACIÓN ===\n")
