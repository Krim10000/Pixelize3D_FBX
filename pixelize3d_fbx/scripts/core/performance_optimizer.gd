# scripts/core/performance_optimizer.gd
extends Node

# Input: Configuración de renderizado y recursos del sistema
# Output: Configuración optimizada para mejor rendimiento

signal optimization_complete(optimized_config: Dictionary)
signal performance_report(report: Dictionary)

var system_info: Dictionary = {}
var performance_metrics: Dictionary = {}

func _ready():
	_gather_system_info()

func _gather_system_info():
	system_info = {
		"cpu_count": OS.get_processor_count(),
		"cpu_name": OS.get_processor_name(),
		"memory_total": OS.get_static_memory_usage(),
		"video_adapter_name": RenderingServer.get_video_adapter_name(),
		"video_adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"video_memory_used": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"os_name": OS.get_name(),
		"godot_version": Engine.get_version_info()
	}

func optimize_render_settings(base_config: Dictionary, unit_count: int = 1) -> Dictionary:
	var optimized = base_config.duplicate(true)
	
	# Analizar capacidades del sistema
	var gpu_tier = _detect_gpu_tier()
	var available_memory = _get_available_memory()
	var cpu_cores = system_info.cpu_count
	
	# Optimizar basado en el hardware
	if gpu_tier == "low":
		optimized = _apply_low_end_optimizations(optimized)
	elif gpu_tier == "medium":
		optimized = _apply_medium_optimizations(optimized)
	else:
		optimized = _apply_high_end_optimizations(optimized)
	
	# Ajustar para procesamiento por lotes
	if unit_count > 1:
		optimized = _optimize_for_batch(optimized, unit_count)
	
	# Optimizaciones específicas de memoria
	if available_memory < 4096: # Menos de 4GB disponibles
		optimized = _apply_memory_optimizations(optimized)
	
	emit_signal("optimization_complete", optimized)
	return optimized

func _detect_gpu_tier() -> String:
	var gpu_name = system_info.video_adapter_name.to_lower()
	var gpu_vendor = system_info.video_adapter_vendor.to_lower()
	
	# Detección simple basada en nombres conocidos
	if "nvidia" in gpu_vendor:
		if "rtx 40" in gpu_name or "rtx 30" in gpu_name:
			return "high"
		elif "rtx 20" in gpu_name or "gtx 16" in gpu_name:
			return "medium"
		else:
			return "low"
	elif "amd" in gpu_vendor:
		if "rx 7" in gpu_name or "rx 6" in gpu_name:
			return "high"
		elif "rx 5" in gpu_name:
			return "medium"
		else:
			return "low"
	elif "intel" in gpu_vendor:
		if "arc" in gpu_name:
			return "medium"
		else:
			return "low"
	
	# Por defecto, asumir tier medio
	return "medium"

func _get_available_memory() -> int:
	# Estimar memoria disponible (en MB)
	var used_memory = OS.get_static_memory_usage() / 1048576
	var total_memory = OS.get_static_memory_peak_usage() / 1048576 * 2 # Estimación
	return int(total_memory - used_memory)

func _apply_low_end_optimizations(config: Dictionary) -> Dictionary:
	# Reducir calidad para GPUs de gama baja
	config.render.sprite_size = min(config.render.sprite_size, 128)
	config.render.anti_aliasing = false
	config.render.shadows = false
	config.render.pixelize = true # Pixelización puede ocultar baja calidad
	config.render.pixel_scale = max(config.render.pixel_scale, 4)
	
	config.camera.orthographic = true # Ortográfico es más ligero
	
	config.performance.max_parallel_renders = 1
	config.performance.use_gpu_acceleration = false
	config.performance.low_memory_mode = true
	
	return config

func _apply_medium_optimizations(config: Dictionary) -> Dictionary:
	# Balance entre calidad y rendimiento
	config.render.sprite_size = min(config.render.sprite_size, 256)
	config.render.anti_aliasing = true
	config.render.shadows = true
	
	config.performance.max_parallel_renders = min(2, system_info.cpu_count / 2)
	config.performance.use_gpu_acceleration = true
	
	return config

func _apply_high_end_optimizations(config: Dictionary) -> Dictionary:
	# Máxima calidad para hardware potente
	config.render.anti_aliasing = true
	config.render.shadows = true
	
	config.performance.max_parallel_renders = min(4, system_info.cpu_count - 2)
	config.performance.use_gpu_acceleration = true
	config.performance.cache_models = true
	
	return config

func _optimize_for_batch(config: Dictionary, unit_count: int) -> Dictionary:
	# Ajustar para procesamiento por lotes
	if unit_count > 10:
		# Reducir calidad para procesar más rápido
		config.render.sprite_size = min(config.render.sprite_size, 256)
		config.performance.cache_models = true
		
		# Limitar renders paralelos basado en memoria
		var memory_per_render = 512 # MB estimados
		var max_parallel = _get_available_memory() / memory_per_render
		config.performance.max_parallel_renders = min(
			config.performance.max_parallel_renders,
			int(max_parallel)
		)
	
	return config

func _apply_memory_optimizations(config: Dictionary) -> Dictionary:
	# Optimizaciones para sistemas con poca memoria
	config.performance.low_memory_mode = true
	config.performance.cache_models = false # No cachear para ahorrar memoria
	config.performance.max_parallel_renders = 1
	
	# Reducir tamaño de viewport
	config.render.sprite_size = min(config.render.sprite_size, 128)
	
	return config

# Monitoreo de rendimiento en tiempo real
var monitoring_active: bool = false
var frame_times: Array = []
var memory_samples: Array = []

func start_performance_monitoring():
	monitoring_active = true
	frame_times.clear()
	memory_samples.clear()
	set_process(true)

func stop_performance_monitoring() -> Dictionary:
	monitoring_active = false
	set_process(false)
	
	return _generate_performance_report()

func _process(delta: float):
	if not monitoring_active:
		return
	
	# Registrar tiempo de frame
	frame_times.append(delta)
	if frame_times.size() > 300: # Mantener últimos 5 segundos a 60fps
		frame_times.pop_front()
	
	# Registrar uso de memoria
	memory_samples.append({
		"time": Time.get_ticks_msec(),
		"static_memory": OS.get_static_memory_usage(),
		"video_memory": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	})
	
	if memory_samples.size() > 60: # Mantener último minuto
		memory_samples.pop_front()

func _generate_performance_report() -> Dictionary:
	var report = {
		"average_frame_time": 0.0,
		"max_frame_time": 0.0,
		"min_frame_time": 999.0,
		"estimated_fps": 0.0,
		"memory_peak": 0,
		"memory_average": 0,
		"video_memory_peak": 0,
		"render_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"texture_memory": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	}
	
	# Analizar tiempos de frame
	if frame_times.size() > 0:
		var total_time = 0.0
		for time in frame_times:
			total_time += time
			report.max_frame_time = max(report.max_frame_time, time)
			report.min_frame_time = min(report.min_frame_time, time)
		
		report.average_frame_time = total_time / frame_times.size()
		report.estimated_fps = 1.0 / report.average_frame_time if report.average_frame_time > 0 else 0
	
	# Analizar memoria
	if memory_samples.size() > 0:
		var total_memory = 0
		var total_video = 0
		
		for sample in memory_samples:
			report.memory_peak = max(report.memory_peak, sample.static_memory)
			report.video_memory_peak = max(report.video_memory_peak, sample.video_memory)
			total_memory += sample.static_memory
			total_video += sample.video_memory
		
		report.memory_average = total_memory / memory_samples.size()
	
	emit_signal("performance_report", report)
	return report

# Sugerencias de optimización basadas en métricas
func get_optimization_suggestions(metrics: Dictionary) -> Array:
	var suggestions = []
	
	# FPS bajo
	if metrics.estimated_fps < 30 and metrics.estimated_fps > 0:
		suggestions.append({
			"issue": "FPS bajo",
			"severity": "high",
			"suggestion": "Reducir tamaño de sprite o desactivar sombras"
		})
	
	# Uso alto de memoria
	if metrics.memory_peak > 2147483648: # 2GB
		suggestions.append({
			"issue": "Uso alto de memoria",
			"severity": "medium",
			"suggestion": "Activar modo de memoria baja o reducir cache de modelos"
		})
	
	# Muchas llamadas de renderizado
	if metrics.render_calls > 1000:
		suggestions.append({
			"issue": "Demasiadas llamadas de renderizado",
			"severity": "medium",
			"suggestion": "Optimizar meshes o reducir número de direcciones"
		})
	
	# Memoria de video alta
	if metrics.video_memory_peak > 1073741824: # 1GB
		suggestions.append({
			"issue": "Uso alto de memoria de video",
			"severity": "medium",
			"suggestion": "Reducir resolución de texturas o tamaño de sprite"
		})
	
	return suggestions

# Benchmark rápido del sistema
func run_system_benchmark() -> Dictionary:
	var benchmark_results = {
		"cpu_score": 0,
		"gpu_score": 0,
		"memory_score": 0,
		"overall_score": 0,
		"recommended_settings": {}
	}
	
	# Test de CPU (operaciones matemáticas)
	var cpu_start = Time.get_ticks_usec()
	for i in range(1000000):
		var _result = sqrt(i) * sin(i)
	var cpu_time = (Time.get_ticks_usec() - cpu_start) / 1000.0
	benchmark_results.cpu_score = max(0, 100 - (cpu_time / 10))
	
	# Test de GPU (renderizado)
	# Este es un placeholder - en producción usarías un test real de GPU
	var gpu_tier = _detect_gpu_tier()
	benchmark_results.gpu_score = {"low": 30, "medium": 60, "high": 90}.get(gpu_tier, 50)
	
	# Test de memoria
	var available_mem = _get_available_memory()
	benchmark_results.memory_score = min(100, (available_mem / 8192.0) * 100)
	
	# Puntuación general
	benchmark_results.overall_score = (
		benchmark_results.cpu_score * 0.3 +
		benchmark_results.gpu_score * 0.5 +
		benchmark_results.memory_score * 0.2
	)
	
	# Recomendar configuración basada en puntuación
	if benchmark_results.overall_score >= 70:
		benchmark_results.recommended_settings = {
			"preset": "high_quality",
			"sprite_size": 512,
			"directions": 32,
			"enable_all_effects": true
		}
	elif benchmark_results.overall_score >= 40:
		benchmark_results.recommended_settings = {
			"preset": "balanced",
			"sprite_size": 256,
			"directions": 16,
			"enable_all_effects": false
		}
	else:
		benchmark_results.recommended_settings = {
			"preset": "performance",
			"sprite_size": 128,
			"directions": 8,
			"enable_all_effects": false
		}
	
	return benchmark_results
