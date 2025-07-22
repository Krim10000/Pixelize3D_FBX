# scripts/cli/cli_interface.gd
extends Node

# Input: Argumentos de línea de comandos
# Output: Spritesheets generados sin GUI

var exit_code: int = 0
var silent_mode: bool = false

# Componentes necesarios
var fbx_loader: Node
var animation_manager: Node
var sprite_renderer: Node
var export_manager: Node
var batch_processor: Node
var config_manager: Node

func _ready():
	# Detectar si estamos en modo CLI
	var args = OS.get_cmdline_args()
	
	if "--help" in args or "-h" in args:
		_print_help()
		get_tree().quit(0)
		return
	
	if "--cli" in args or "--headless" in args:
		# Modo CLI activado
		_setup_cli_mode()
		_process_cli_arguments(args)
	else:
		# Modo GUI normal
		push_warning("Ejecutando en modo GUI. Use --cli para modo línea de comandos")

func _setup_cli_mode():
	# Configurar para ejecución sin ventana
	get_window().mode = Window.MODE_MINIMIZED
	
	# Desactivar audio
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	
	# Crear componentes necesarios
	_create_components()

func _create_components():
	# Crear instancias de los componentes necesarios
	fbx_loader = preload("res://scripts/core/fbx_loader.gd").new()
	fbx_loader.name = "FBXLoader"
	add_child(fbx_loader)
	
	animation_manager = preload("res://scripts/core/animation_manager.gd").new()
	animation_manager.name = "AnimationManager"
	add_child(animation_manager)
	
	sprite_renderer = preload("res://scripts/rendering/sprite_renderer.gd").new()
	sprite_renderer.name = "SpriteRenderer"
	add_child(sprite_renderer)
	
	export_manager = preload("res://scripts/export/export_manager.gd").new()
	export_manager.name = "ExportManager"
	add_child(export_manager)
	
	batch_processor = preload("res://scripts/core/batch_processor.gd").new()
	batch_processor.name = "BatchProcessor"
	add_child(batch_processor)
	
	config_manager = preload("res://scripts/core/config_manager.gd").new()
	config_manager.name = "ConfigManager"
	add_child(config_manager)

func _process_cli_arguments(args: Array):
	var parsed_args = _parse_arguments(args)
	
	# Validar argumentos requeridos
	if not _validate_arguments(parsed_args):
		exit_code = 1
		get_tree().quit(exit_code)
		return
	
	# Configurar modo silencioso
	silent_mode = parsed_args.has("silent") or parsed_args.has("s")
	
	# Ejecutar comando
	match parsed_args.get("command", ""):
		"render":
			_execute_render(parsed_args)
		"batch":
			_execute_batch(parsed_args)
		"validate":
			_execute_validate(parsed_args)
		"config":
			_execute_config(parsed_args)
		"benchmark":
			_execute_benchmark(parsed_args)
		_:
			_print_error("Comando no reconocido: " + parsed_args.get("command", ""))
			exit_code = 1
			get_tree().quit(exit_code)

func _parse_arguments(args: Array) -> Dictionary:
	var parsed = {
		"command": "",
		"positional": [],
		"options": {}
	}
	
	var i = 0
	while i < args.size():
		var arg = args[i]
		
		if arg == "--cli" or arg == "--headless":
			i += 1
			continue
		
		if arg.begins_with("--"):
			# Argumento largo
			var key = arg.substr(2)
			if i + 1 < args.size() and not args[i + 1].begins_with("-"):
				parsed.options[key] = args[i + 1]
				i += 2
			else:
				parsed.options[key] = true
				i += 1
		elif arg.begins_with("-"):
			# Argumento corto
			var key = arg.substr(1)
			if i + 1 < args.size() and not args[i + 1].begins_with("-"):
				parsed.options[key] = args[i + 1]
				i += 2
			else:
				parsed.options[key] = true
				i += 1
		else:
			# Argumento posicional
			if parsed.command == "":
				parsed.command = arg
			else:
				parsed.positional.append(arg)
			i += 1
	
	# Mapear argumentos cortos a largos
	_map_short_arguments(parsed.options)
	
	return parsed

func _map_short_arguments(options: Dictionary):
	var mappings = {
		"h": "help",
		"s": "silent",
		"i": "input",
		"o": "output",
		"b": "base",
		"a": "animations",
		"d": "directions",
		"r": "resolution",
		"p": "preset",
		"c": "config"
	}
	
	for short in mappings:
		if short in options:
			options[mappings[short]] = options[short]
			options.erase(short)

func _validate_arguments(parsed: Dictionary) -> bool:
	var command = parsed.get("command", "")
	
	match command:
		"render":
			if not parsed.options.has("input"):
				_print_error("Falta argumento requerido: --input")
				return false
			if not parsed.options.has("base"):
				_print_error("Falta argumento requerido: --base")
				return false
		"batch":
			if not parsed.options.has("input"):
				_print_error("Falta argumento requerido: --input")
				return false
		"validate":
			if not parsed.options.has("input"):
				_print_error("Falta argumento requerido: --input")
				return false
	
	return true

func _execute_render(args: Dictionary):
	_print_info("Iniciando renderizado...")
	
	var input_folder = args.options.get("input", "")
	var base_file = args.options.get("base", "")
	var output_folder = args.options.get("output", "exports")
	
	# Configurar parámetros
	var config = _build_render_config(args.options)
	
	# Obtener lista de animaciones
	var animations = []
	if args.options.has("animations"):
		animations = args.options.animations.split(",")
	else:
		# Escanear todas las animaciones en la carpeta
		animations = _scan_animations(input_folder, base_file)
	
	if animations.is_empty():
		_print_error("No se encontraron animaciones para procesar")
		exit_code = 1
		get_tree().quit(exit_code)
		return
	
	_print_info("Procesando %d animaciones..." % animations.size())
	
	# Crear unidad para procesar
	var unit = {
		"name": input_folder.get_file(),
		"folder": input_folder,
		"base_file": base_file,
		"animations": animations
	}
	
	# Configurar batch processor para una sola unidad
	batch_processor.batch_completed.connect(_on_batch_completed)
	batch_processor.unit_failed.connect(_on_unit_failed)
	
	config["output_folder"] = output_folder
	batch_processor.process_batch([unit], config)

func _execute_batch(args: Dictionary):
	_print_info("Iniciando procesamiento por lotes...")
	
	var input_folder = args.options.get("input", "")
	var output_folder = args.options.get("output", "exports")
	var config_file = args.options.get("config", "")
	
	# Cargar configuración
	var config = {}
	if config_file != "":
		config = _load_config_file(config_file)
	else:
		config = _build_render_config(args.options)
	
	# Escanear unidades
	var units = batch_processor.scan_for_units(input_folder)
	
	if units.is_empty():
		_print_error("No se encontraron unidades para procesar en: " + input_folder)
		exit_code = 1
		get_tree().quit(exit_code)
		return
	
	_print_info("Encontradas %d unidades para procesar" % units.size())
	
	# Configurar y ejecutar
	batch_processor.batch_completed.connect(_on_batch_completed)
	batch_processor.unit_started.connect(_on_unit_started)
	batch_processor.unit_completed.connect(_on_unit_completed)
	batch_processor.unit_failed.connect(_on_unit_failed)
	
	config["output_folder"] = output_folder
	batch_processor.process_batch(units, config)

func _execute_validate(args: Dictionary):
	_print_info("Validando archivos FBX...")
	
	var input_path = args.options.get("input", "")
	var validator = preload("res://scripts/core/fbx_validator.gd").new()
	
	# Determinar si es un archivo o carpeta
	var dir = DirAccess.open(input_path)
	if dir:
		# Es una carpeta, validar como unidad
		var base_file = args.options.get("base", "")
		if base_file == "":
			_print_error("Para validar una carpeta, especifique el archivo base con --base")
			exit_code = 1
			get_tree().quit(exit_code)
			return
		
		var animations = _scan_animations(input_path, base_file)
		var report = validator.validate_unit_folder(input_path, base_file, animations)
		
		_print_validation_report(report)
	else:
		# Es un archivo individual
		var report = validator.validate_fbx_file(input_path)
		_print_validation_report(report)
	
	validator.queue_free()
	get_tree().quit(exit_code)

func _execute_config(args: Dictionary):
	var action = args.positional[0] if args.positional.size() > 0 else "show"
	
	match action:
		"show":
			_show_current_config()
		"list-presets":
			_list_presets()
		"apply-preset":
			if args.positional.size() > 1:
				_apply_preset(args.positional[1])
			else:
				_print_error("Especifique el nombre del preset")
		"save":
			if args.options.has("output"):
				_save_config(args.options.output)
			else:
				_print_error("Especifique archivo de salida con --output")
		_:
			_print_error("Acción de configuración no válida: " + action)
	
	get_tree().quit(exit_code)

func _execute_benchmark(args: Dictionary):
	_print_info("Ejecutando benchmark del sistema...")
	
	var optimizer = preload("res://scripts/core/performance_optimizer.gd").new()
	add_child(optimizer)
	
	var results = optimizer.run_system_benchmark()
	
	_print_info("\n=== RESULTADOS DEL BENCHMARK ===")
	_print_info("CPU Score: %.1f/100" % results.cpu_score)
	_print_info("GPU Score: %.1f/100" % results.gpu_score)
	_print_info("Memory Score: %.1f/100" % results.memory_score)
	_print_info("Overall Score: %.1f/100" % results.overall_score)
	_print_info("\nConfiguración recomendada:")
	_print_info("- Preset: " + results.recommended_settings.preset)
	_print_info("- Tamaño sprite: %d" % results.recommended_settings.sprite_size)
	_print_info("- Direcciones: %d" % results.recommended_settings.directions)
	
	optimizer.queue_free()
	get_tree().quit(0)

func _build_render_config(options: Dictionary) -> Dictionary:
	var config = config_manager.get_section("render").duplicate()
	config.merge(config_manager.get_section("camera").duplicate())
	config.merge(config_manager.get_section("export").duplicate())
	
	# Aplicar preset si se especificó
	if options.has("preset"):
		config_manager.apply_preset(options.preset)
		config = config_manager.current_config.duplicate(true)
	
	# Sobrescribir con opciones de línea de comandos
	if options.has("directions"):
		config.render.directions = int(options.directions)
	if options.has("resolution"):
		config.render.sprite_size = int(options.resolution)
	if options.has("fps"):
		config.render.fps = int(options.fps)
	if options.has("no-shadows"):
		config.render.shadows = false
	if options.has("no-pixelize"):
		config.render.pixelize = false
	
	return config

func _load_config_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_print_error("No se pudo abrir archivo de configuración: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		_print_error("Error al parsear configuración: " + json.error_string)
		return {}
	
	return json.data

func _scan_animations(folder: String, base_file: String) -> Array:
	var animations = []
	var dir = DirAccess.open(folder)
	
	if not dir:
		return animations
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if (file_name.ends_with(".fbx") or file_name.ends_with(".FBX")) and file_name != base_file:
			animations.append(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return animations

# Callbacks
func _on_batch_completed(results: Dictionary):
	_print_info("\n=== PROCESAMIENTO COMPLETADO ===")
	_print_info("Tiempo total: %.2f segundos" % results.total_time)
	_print_info("Unidades procesadas: %d" % results.units_processed)
	_print_info("Unidades fallidas: %d" % results.units_failed)
	_print_info("Sprites generados: %d" % results.total_sprites_generated)
	
	exit_code = 0 if results.units_failed == 0 else 1
	get_tree().quit(exit_code)

func _on_unit_started(unit_name: String, index: int):
	if not silent_mode:
		_print_info("Procesando: " + unit_name)

func _on_unit_completed(unit_name: String, index: int):
	if not silent_mode:
		_print_info("Completado: " + unit_name)

func _on_unit_failed(unit_name: String, error: String):
	_print_error("Fallo en " + unit_name + ": " + error)

# Funciones de impresión
func _print_info(message: String):
	if not silent_mode:
		print(message)

func _print_error(message: String):
	push_error(message)
	printerr(message)

func _print_validation_report(report: Dictionary):
	print("\n=== REPORTE DE VALIDACIÓN ===")
	print("Archivo: " + report.file_name)
	print("Válido: " + ("SÍ" if report.is_valid else "NO"))
	
	if report.errors.size() > 0:
		print("\nERRORES:")
		for error in report.errors:
			print("  - " + error.message)
			if error.details != "":
				print("    " + error.details)
	
	if report.warnings.size() > 0:
		print("\nADVERTENCIAS:")
		for warning in report.warnings:
			print("  - " + warning.message)
	
	if report.has("statistics"):
		print("\nESTADÍSTICAS:")
		print("  - Nodos totales: %d" % report.statistics.total_nodes)
		print("  - Vértices: %d" % report.statistics.total_vertices)
		print("  - Polígonos: %d" % report.statistics.total_polygons)
	
	exit_code = 0 if report.is_valid else 1

func _show_current_config():
	var config = config_manager.current_config
	print(JSON.stringify(config, "\t"))

func _list_presets():
	var presets = config_manager.get_all_presets()
	print("\nPRESETS DISPONIBLES:")
	for preset in presets:
		print("\n%s:" % preset.key)
		print("  Nombre: " + preset.name)
		print("  Descripción: " + preset.description)

func _apply_preset(preset_name: String):
	config_manager.apply_preset(preset_name)
	_print_info("Preset aplicado: " + preset_name)

func _save_config(path: String):
	var config = config_manager.current_config
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(config, "\t"))
		file.close()
		_print_info("Configuración guardada en: " + path)
	else:
		_print_error("No se pudo guardar la configuración")
		exit_code = 1

func _print_help():
	print("""
Pixelize3D FBX - Generador de Spritesheets v1.0

USO:
  godot --headless --cli [comando] [opciones]

COMANDOS:
  render      Renderizar una unidad individual
  batch       Procesar múltiples unidades
  validate    Validar archivos FBX
  config      Gestionar configuración
  benchmark   Ejecutar benchmark del sistema

OPCIONES GLOBALES:
  -h, --help              Mostrar esta ayuda
  -s, --silent            Modo silencioso

OPCIONES DE RENDER:
  -i, --input <carpeta>   Carpeta con archivos FBX
  -o, --output <carpeta>  Carpeta de salida (default: exports)
  -b, --base <archivo>    Archivo FBX base con meshes
  -a, --animations <lista> Lista de animaciones separadas por comas
  -d, --directions <n>    Número de direcciones (8, 16, 32)
  -r, --resolution <n>    Tamaño del sprite en píxeles
  -p, --preset <nombre>   Aplicar preset de configuración
  --fps <n>               Frames por segundo
  --no-shadows            Desactivar sombras
  --no-pixelize           Desactivar efecto de pixelización

EJEMPLOS:
  # Renderizar una unidad
  godot --headless --cli render -i units/soldier -b soldier_base.fbx -o output

  # Procesar múltiples unidades
  godot --headless --cli batch -i units/ -o output --preset RTS_Standard

  # Validar archivos
  godot --headless --cli validate -i units/soldier -b soldier_base.fbx

  # Ver configuración actual
  godot --headless --cli config show

  # Ejecutar benchmark
  godot --headless --cli benchmark
""")
