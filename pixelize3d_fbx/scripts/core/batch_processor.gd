# scripts/core/batch_processor.gd
# Input: Lista de unidades para procesar
# Output: Múltiples spritesheets generados en lote

extends Node

signal batch_started(total_units: int)
signal unit_started(unit_name: String, index: int)
signal unit_completed(unit_name: String, index: int)
signal unit_failed(unit_name: String, error: String)
signal batch_completed(results: Dictionary)
signal batch_progress(current: int, total: int, message: String)

var is_processing: bool = false
var should_cancel: bool = false
var current_batch_config: Dictionary = {}
var batch_results: Dictionary = {}

# Cola de procesamiento
var processing_queue: Array = []
var current_unit_index: int = 0

# Referencias a otros sistemas
var fbx_loader: Node
var animation_manager: Node
var sprite_renderer: Node
var export_manager: Node

func _ready():
	# Obtener referencias a otros sistemas
	fbx_loader = get_node("/root/Main/FBXLoader")
	animation_manager = get_node("/root/Main/AnimationManager")
	sprite_renderer = get_node("/root/Main/SpriteRenderer")
	export_manager = get_node("/root/Main/ExportManager")

func process_batch(units: Array, config: Dictionary) -> void:
	if is_processing:
		push_error("Ya hay un procesamiento en curso")
		return
	
	is_processing = true
	should_cancel = false
	processing_queue = units
	current_batch_config = config
	current_unit_index = 0
	batch_results = {
		"start_time": Time.get_unix_time_from_system(),
		"units_processed": 0,
		"units_failed": 0,
		"total_sprites_generated": 0,
		"total_time": 0.0,
		"results": []
	}
	
	emit_signal("batch_started", units.size())
	
	# Iniciar procesamiento
	_process_next_unit()

func _process_next_unit():
	if should_cancel or current_unit_index >= processing_queue.size():
		_finish_batch()
		return
	
	var unit = processing_queue[current_unit_index]
	emit_signal("unit_started", unit.name, current_unit_index)
	emit_signal("batch_progress", current_unit_index, processing_queue.size(), 
		"Procesando: " + unit.name)
	
	# Procesar unidad
	_process_unit(unit)

func _process_unit(unit: Dictionary):
	var unit_result = {
		"name": unit.name,
		"folder": unit.folder,
		"base_file": unit.base_file,
		"animations": unit.animations,
		"start_time": Time.get_unix_time_from_system(),
		"end_time": 0.0,
		"success": false,
		"sprites_generated": 0,
		"errors": [],
		"output_files": []
	}
	
	# Validar primero
	if current_batch_config.get("validate_before_render", true):
		var validator = preload("res://scripts/core/fbx_validator.gd").new()
		var validation = validator.validate_unit_folder(
			unit.folder,
			unit.base_file,
			unit.animations
		)
		
		if not validation.is_valid:
			unit_result.errors.append("Validación fallida")
			unit_result.errors.append_array(_extract_validation_errors(validation))
			_unit_failed(unit_result)
			return
		
		validator.queue_free()
	
	# Cargar modelo base
	var base_path = unit.folder.path_join(unit.base_file)
	var base_data = await _load_fbx_async(base_path, true)
	
	if not base_data:
		unit_result.errors.append("No se pudo cargar el modelo base")
		_unit_failed(unit_result)
		return
	
	# Procesar cada animación
	var animations_to_process = unit.animations
	var processed_animations = 0
	
	for anim_file in animations_to_process:
		if should_cancel:
			break
		
		emit_signal("batch_progress", current_unit_index, processing_queue.size(),
			"Procesando %s: %s" % [unit.name, anim_file])
		
		# Cargar animación
		var anim_path = unit.folder.path_join(anim_file)
		var anim_data = await _load_fbx_async(anim_path, false)
		
		if not anim_data:
			unit_result.errors.append("No se pudo cargar: " + anim_file)
			continue
		
		# Combinar y renderizar
		var success = await _render_animation(base_data, anim_data, unit, anim_file)
		
		if success:
			processed_animations += 1
			unit_result.sprites_generated += current_batch_config.render.directions
		else:
			unit_result.errors.append("Error al renderizar: " + anim_file)
	
	# Finalizar unidad
	unit_result.end_time = Time.get_unix_time_from_system()
	unit_result.success = processed_animations == animations_to_process.size()
	
	if unit_result.success:
		batch_results.units_processed += 1
		batch_results.total_sprites_generated += unit_result.sprites_generated
		emit_signal("unit_completed", unit.name, current_unit_index)
	else:
		_unit_failed(unit_result)
	
	batch_results.results.append(unit_result)
	
	# Continuar con la siguiente unidad
	current_unit_index += 1
	call_deferred("_process_next_unit")

func _load_fbx_async(path: String, is_base: bool) -> Dictionary:
	# Cargar FBX de forma asíncrona
	var loader = fbx_loader
	
	if is_base:
		loader.load_base_model(path)
	else:
		loader.load_animation_fbx(path, path.get_file().get_basename())
	
	# Esperar resultado
	var result = await loader.model_loaded
	
	if result.type == "error":
		return {}
	
	return result

func _render_animation(base_data: Dictionary, anim_data: Dictionary, unit: Dictionary, anim_file: String) -> bool:
	# Combinar modelo base con animación
	var combined_model = animation_manager.combine_base_with_animation(base_data, anim_data)
	
	if not combined_model:
		return false
	
	# ✅ CRÍTICO: Verificar que el modelo es válido antes de usarlo
	if not is_instance_valid(combined_model):
		print("❌ Modelo combinado no es válido")
		return false
	
	# Configurar renderizado
	sprite_renderer.initialize(current_batch_config.render)
	
	var frames_rendered = 0
	var total_frames = current_batch_config.render.directions
	
	# Renderizar cada dirección
	for direction in range(current_batch_config.render.directions):
		if should_cancel:
			break
		
		# ✅ CRÍTICO: Verificar modelo antes de cada dirección
		if not is_instance_valid(combined_model):
			print("❌ Modelo se invalidó durante el renderizado")
			break
		
		var angle = (360.0 / current_batch_config.render.directions) * direction
		
		sprite_renderer.render_animation(
			combined_model,
			anim_file.get_basename(),
			angle,
			direction
		)
		
		# Esperar a que se complete el renderizado
		await sprite_renderer.animation_complete
		frames_rendered += 1
		
		emit_signal("batch_progress", current_unit_index, processing_queue.size(),
			"Renderizando %s: %s (%d/%d)" % [unit.name, anim_file, frames_rendered, total_frames])
	
	# Exportar spritesheet - CORREGIDO
	var output_path = _get_output_path(unit, anim_file)
	var export_config = {
		"output_folder": output_path,
		"animation_mode": "current",
		"current_animation": anim_file.get_basename()
	}
	export_manager.export_sprite_sheets(export_config)
	await export_manager.export_complete
	
	# ✅ CRÍTICO: Limpiar modelo combinado SEGURO
	if is_instance_valid(combined_model):
		combined_model.queue_free()
	
	return frames_rendered == total_frames

func _get_output_path(unit: Dictionary, anim_file: String) -> String:
	var base_output = current_batch_config.get("output_folder", "res://exports")
	
	if current_batch_config.export.get("organize_by_unit", true):
		return base_output.path_join(unit.name)
	else:
		return base_output

func _unit_failed(unit_result: Dictionary):
	batch_results.units_failed += 1
	emit_signal("unit_failed", unit_result.name, unit_result.errors[0] if unit_result.errors.size() > 0 else "Error desconocido")

func _finish_batch():
	is_processing = false
	batch_results.end_time = Time.get_unix_time_from_system()
	batch_results.total_time = batch_results.end_time - batch_results.start_time
	
	emit_signal("batch_completed", batch_results)
	
	# Generar reporte
	_generate_batch_report()

func _generate_batch_report():
	var report = "=== REPORTE DE PROCESAMIENTO POR LOTES ===\n\n"
	report += "Tiempo total: %.2f segundos\n" % batch_results.total_time
	report += "Unidades procesadas: %d/%d\n" % [batch_results.units_processed, processing_queue.size()]
	report += "Sprites generados: %d\n\n" % batch_results.total_sprites_generated
	
	if batch_results.units_failed > 0:
		report += "UNIDADES FALLIDAS:\n"
		for result in batch_results.results:
			if not result.success:
				report += "- %s:\n" % result.name
				for error in result.errors:
					report += "  * %s\n" % error
				report += "\n"
	
	# Guardar reporte
	var report_path = current_batch_config.get("output_folder", "res://exports").path_join("batch_report.txt")
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()

func _extract_validation_errors(validation: Dictionary) -> Array:
	var errors = []
	
	if validation.has("base_validation") and validation.base_validation.has("errors"):
		for error in validation.base_validation.errors:
			errors.append("Base: " + error.message)
	
	if validation.has("animation_validations"):
		for anim_val in validation.animation_validations:
			if anim_val.has("errors"):
				for error in anim_val.errors:
					errors.append(anim_val.file_name + ": " + error.message)
	
	return errors

func cancel_batch():
	should_cancel = true
	emit_signal("batch_progress", current_unit_index, processing_queue.size(), "Cancelando...")

# Función para escanear carpetas automáticamente
func scan_for_units(root_folder: String) -> Array:
	var units = []
	var dir = DirAccess.open(root_folder)
	
	if not dir:
		return units
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		var folder_path = root_folder.path_join(folder_name)
		
		if dir.current_is_dir() and not folder_name.begins_with("."):
			# Buscar archivos FBX en la carpeta
			var unit_data = _scan_unit_folder(folder_path, folder_name)
			
			if unit_data:
				units.append(unit_data)
		
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	return units

func _scan_unit_folder(folder_path: String, unit_name: String) -> Dictionary:
	var fbx_files = []
	var sub_dir = DirAccess.open(folder_path)
	
	if not sub_dir:
		return {}
	
	sub_dir.list_dir_begin()
	var file_name = sub_dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".fbx") or file_name.ends_with(".FBX"):
			fbx_files.append(file_name)
		file_name = sub_dir.get_next()
	
	sub_dir.list_dir_end()
	
	if fbx_files.is_empty():
		return {}
	
	# Intentar identificar el archivo base automáticamente
	var base_file = ""
	var animations = []
	
	for file in fbx_files:
		var lower_name = file.to_lower()
		if "base" in lower_name or "mesh" in lower_name or "model" in lower_name:
			if base_file == "":
				base_file = file
		else:
			animations.append(file)
	
	# Si no se encontró un archivo base obvio, usar el primero
	if base_file == "" and fbx_files.size() > 0:
		base_file = fbx_files[0]
		animations = fbx_files.slice(1)
	
	return {
		"name": unit_name,
		"folder": folder_path,
		"base_file": base_file,
		"animations": animations,
		"auto_detected": true
	}
