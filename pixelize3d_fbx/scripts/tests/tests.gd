# scripts/tests/test_suite.gd
extends Node

# Input: Componentes del sistema para testear
# Output: Reporte de tests con resultados

signal test_started(test_name: String)
signal test_completed(test_name: String, success: bool, message: String)
signal all_tests_completed(results: Dictionary)

var test_results: Dictionary = {
	"total": 0,
	"passed": 0,
	"failed": 0,
	"skipped": 0,
	"tests": []
}

var current_test: String = ""
var test_start_time: int = 0

# Componentes a testear
var components = {
	"fbx_loader": null,
	"animation_manager": null,
	"sprite_renderer": null,
	"export_manager": null,
	"config_manager": null
}

func _ready():
	print("=== PIXELIZE3D TEST SUITE ===")
	_load_components()

func _load_components():
	# Cargar componentes para testing
	components.fbx_loader = preload("res://scripts/core/fbx_loader.gd").new()
	components.animation_manager = preload("res://scripts/core/animation_manager.gd").new()
	components.sprite_renderer = preload("res://scripts/rendering/sprite_renderer.gd").new()
	components.export_manager = preload("res://scripts/export/export_manager.gd").new()
	components.config_manager = preload("res://scripts/core/config_manager.gd").new()
	
	for comp in components.values():
		if comp:
			add_child(comp)

func run_all_tests():
	test_results = {
		"total": 0,
		"passed": 0,
		"failed": 0,
		"skipped": 0,
		"tests": [],
		"start_time": Time.get_unix_time_from_system()
	}
	
	print("\nIniciando suite de tests...")
	
	# Tests de componentes individuales
	await _test_config_manager()
	await _test_fbx_loader()
	await _test_animation_manager()
	await _test_sprite_renderer()
	await _test_export_manager()
	
	# Tests de integración
	await _test_full_pipeline()
	await _test_batch_processing()
	await _test_error_handling()
	
	# Tests de rendimiento
	await _test_performance()
	
	# Finalizar
	test_results.end_time = Time.get_unix_time_from_system()
	test_results.duration = test_results.end_time - test_results.start_time
	
	_print_test_summary()
	emit_signal("all_tests_completed", test_results)

# Tests individuales
func _test_config_manager():
	_start_test("ConfigManager - Cargar configuración por defecto")
	
	var config = components.config_manager
	config.load_config()
	
	# Verificar que la configuración se cargó
	if config.current_config.is_empty():
		_fail_test("La configuración está vacía")
		return
	
	# Verificar valores por defecto
	var render_config = config.get_section("render")
	if render_config.get("directions", 0) != 16:
		_fail_test("Valor por defecto incorrecto para direcciones")
		return
	
	_pass_test("Configuración cargada correctamente")
	
	# Test de presets
	_start_test("ConfigManager - Aplicar preset")
	
	config.apply_preset("RTS_Standard")
	await config.preset_loaded
	
	if config.get_config_value("render", "sprite_size") != 128:
		_fail_test("Preset no aplicado correctamente")
		return
	
	_pass_test("Preset aplicado correctamente")

func _test_fbx_loader():
	_start_test("FBXLoader - Validar archivo FBX")
	
	var loader = components.fbx_loader
	
	# Test con archivo inexistente
	var test_path = "res://test_data/missing.fbx"
	if loader.validate_fbx_file(test_path):
		_fail_test("Validación incorrecta para archivo inexistente")
		return
	
	_pass_test("Validación de archivo correcta")
	
	# Test de estructura FBX
	_start_test("FBXLoader - Analizar estructura FBX")
	
	# Crear estructura de prueba
	var test_structure = _create_test_fbx_structure()
	var analysis = loader._analyze_fbx_structure(test_structure, "base", "test")
	
	if not analysis.has("skeleton"):
		_fail_test("No se detectó skeleton en la estructura")
		test_structure.queue_free()
		return
	
	test_structure.queue_free()
	_pass_test("Análisis de estructura correcto")

func _test_animation_manager():
	_start_test("AnimationManager - Combinar base con animación")
	
	var manager = components.animation_manager
	
	# Crear datos de prueba
	var base_data = _create_test_base_data()
	var anim_data = _create_test_animation_data()
	
	var combined = manager.combine_base_with_animation(base_data, anim_data)
	
	if not combined:
		_fail_test("Fallo al combinar modelo")
		return
	
	# Verificar que tiene skeleton y animation player
	var has_skeleton = false
	var has_anim_player = false
	
	for child in combined.get_children():
		if child is Skeleton3D:
			has_skeleton = true
		elif child is AnimationPlayer:
			has_anim_player = true
	
	combined.queue_free()
	
	if not has_skeleton or not has_anim_player:
		_fail_test("Estructura combinada incompleta")
		return
	
	_pass_test("Combinación exitosa")

func _test_sprite_renderer():
	_start_test("SpriteRenderer - Inicialización")
	
	var renderer = components.sprite_renderer
	var settings = {
		"sprite_size": 256,
		"directions": 8,
		"camera_angle": 45.0,
		"camera_height": 10.0,
		"camera_distance": 15.0,
		"fps": 12
	}
	
	renderer.initialize(settings)
	
	# Verificar viewport
	var viewport = renderer.get_node_or_null("SubViewport")
	if not viewport:
		_fail_test("SubViewport no creado")
		return
	
	if viewport.size != Vector2i(256, 256):
		_fail_test("Tamaño de viewport incorrecto")
		return
	
	_pass_test("Renderizador inicializado correctamente")

func _test_export_manager():
	_start_test("ExportManager - Generar metadata")
	
	var exporter = components.export_manager
	
	# Crear datos de prueba
	var test_data = {
		"animation": "walk",
		"direction": 0,
		"frame": 0,
		"image": Image.create(64, 64, false, Image.FORMAT_RGBA8)
	}
	
	exporter.add_frame(test_data)
	
	# Verificar que se añadió el frame
	if not "walk" in exporter.frames_collection:
		_fail_test("Frame no añadido a la colección")
		return
	
	_pass_test("Gestión de frames correcta")

# Tests de integración
func _test_full_pipeline():
	_start_test("Pipeline completo - Base + Animación → Spritesheet")
	
	# Este test simularía el proceso completo
	# En un entorno real, usaríamos archivos FBX de prueba
	
	_skip_test("Requiere archivos FBX de prueba")

func _test_batch_processing():
	_start_test("Procesamiento por lotes")
	
	# Test del batch processor
	var batch_processor = preload("res://scripts/core/batch_processor.gd").new()
	add_child(batch_processor)
	
	# Verificar escaneo de carpetas
	var test_units = batch_processor._scan_unit_folder("res://test_data", "test_unit")
	
	if test_units.is_empty():
		_skip_test("No hay datos de prueba para batch")
	else:
		_pass_test("Batch processor funcional")
	
	batch_processor.queue_free()

func _test_error_handling():
	_start_test("Manejo de errores - Archivo corrupto")
	
	# Simular varios casos de error
	var loader = components.fbx_loader
	
	# Conectar a señal de error
	var error_received = false
	loader.load_failed.connect(func(error): error_received = true)
	
	# Intentar cargar archivo inválido
	loader.load_base_model("res://invalid.fbx")
	
	await get_tree().create_timer(0.5).timeout
	
	if not error_received:
		_fail_test("No se emitió señal de error")
		return
	
	_pass_test("Errores manejados correctamente")

func _test_performance():
	_start_test("Rendimiento - Renderizado de frames")
	
	var start_time = Time.get_ticks_msec()
	
	# Simular renderizado de múltiples frames
	for i in range(10):
		var test_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
		test_image.fill(Color(randf(), randf(), randf()))
		
		# Simular procesamiento
		await get_tree().process_frame
	
	var elapsed = Time.get_ticks_msec() - start_time
	
	if elapsed > 1000: # Más de 1 segundo para 10 frames
		_fail_test("Rendimiento bajo: %d ms para 10 frames" % elapsed)
		return
	
	_pass_test("Rendimiento aceptable: %d ms para 10 frames" % elapsed)

# Funciones auxiliares de testing
func _start_test(name: String):
	current_test = name
	test_start_time = Time.get_ticks_msec()
	test_results.total += 1
	
	print("\n[TEST] " + name)
	emit_signal("test_started", name)

func _pass_test(message: String = ""):
	var duration = Time.get_ticks_msec() - test_start_time
	test_results.passed += 1
	
	var result = {
		"name": current_test,
		"status": "PASSED",
		"message": message,
		"duration": duration
	}
	test_results.tests.append(result)
	
	print("  ✓ PASSED (%d ms) %s" % [duration, message])
	emit_signal("test_completed", current_test, true, message)

func _fail_test(message: String):
	var duration = Time.get_ticks_msec() - test_start_time
	test_results.failed += 1
	
	var result = {
		"name": current_test,
		"status": "FAILED", 
		"message": message,
		"duration": duration
	}
	test_results.tests.append(result)
	
	print("  ✗ FAILED (%d ms) %s" % [duration, message])
	emit_signal("test_completed", current_test, false, message)

func _skip_test(reason: String):
	test_results.skipped += 1
	
	var result = {
		"name": current_test,
		"status": "SKIPPED",
		"message": reason,
		"duration": 0
	}
	test_results.tests.append(result)
	
	print("  - SKIPPED: " + reason)
	emit_signal("test_completed", current_test, true, reason)

func _print_test_summary():
	print("\n=== RESUMEN DE TESTS ===")
	print("Total: %d" % test_results.total)
	print("Exitosos: %d (%.1f%%)" % [
		test_results.passed,
		100.0 * test_results.passed / test_results.total
	])
	print("Fallidos: %d" % test_results.failed)
	print("Omitidos: %d" % test_results.skipped)
	print("Duración: %.2f segundos" % test_results.duration)
	
	if test_results.failed > 0:
		print("\nTESTS FALLIDOS:")
		for test in test_results.tests:
			if test.status == "FAILED":
				print("  - %s: %s" % [test.name, test.message])

# Funciones para crear estructuras de prueba
func _create_test_fbx_structure() -> Node3D:
	var root = Node3D.new()
	root.name = "TestFBX"
	
	var skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	
	# Añadir huesos de prueba
	skeleton.add_bone("Root")
	skeleton.add_bone("Bone1")
	skeleton.set_bone_parent(1, 0)
	
	# Añadir mesh de prueba
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TestMesh"
	mesh_instance.mesh = BoxMesh.new()
	skeleton.add_child(mesh_instance)
	
	return root

func _create_test_base_data() -> Dictionary:
	var skeleton = Skeleton3D.new()
	skeleton.add_bone("Root")
	
	return {
		"type": "base",
		"name": "test_base",
		"skeleton": skeleton,
		"meshes": [{
			"node": MeshInstance3D.new(),
			"mesh_resource": BoxMesh.new(),
			"name": "TestMesh",
			"materials": []
		}]
	}

func _create_test_animation_data() -> Dictionary:
	var anim_player = AnimationPlayer.new()
	var skeleton = Skeleton3D.new()
	skeleton.add_bone("Root")
	
	# Crear animación de prueba
	var animation = Animation.new()
	animation.length = 1.0
	
	var library = AnimationLibrary.new()
	library.add_animation("test_anim", animation)
	anim_player.add_animation_library("", library)
	
	return {
		"type": "animation",
		"name": "test_anim",
		"skeleton": skeleton,
		"animation_player": anim_player,
		"animations": [{
			"name": "test_anim",
			"length": 1.0,
			"fps": 30.0,
			"loop": true
		}]
	}

# Función para ejecutar tests desde línea de comandos
func run_cli_tests():
	await run_all_tests()
	
	# Salir con código apropiado
	var exit_code = 0 if test_results.failed == 0 else 1
	get_tree().quit(exit_code)
