# scripts/core/debug_system.gd
extends Node

# Input: Eventos y datos del sistema
# Output: Logs estructurados, reportes de debug, métricas

signal log_written(entry: Dictionary)
signal debug_report_generated(report: Dictionary)

enum LogLevel {
	VERBOSE,
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

var log_file: FileAccess
var log_buffer: Array = []
var current_log_level: LogLevel = LogLevel.INFO
var enable_file_logging: bool = true
var enable_console_logging: bool = true
var max_log_entries: int = 10000
var log_rotation_size: int = 10485760 # 10MB

# Métricas de rendimiento
var performance_metrics: Dictionary = {
	"renders_completed": 0,
	"renders_failed": 0,
	"average_render_time": 0.0,
	"total_render_time": 0.0,
	"memory_peak": 0,
	"errors_logged": 0,
	"warnings_logged": 0
}

# Timers para medición
var timers: Dictionary = {}

func _ready():
	_initialize_logging()
	
	# Conectar a señales del sistema
	if has_node("/root/Main"):
		var main = get_node("/root/Main")
		if main.has_signal("fbx_loaded"):
			main.fbx_loaded.connect(_on_fbx_loaded)
		if main.has_signal("rendering_complete"):
			main.rendering_complete.connect(_on_rendering_complete)
		if main.has_signal("export_complete"):
			main.export_complete.connect(_on_export_complete)

func _initialize_logging():
	if enable_file_logging:
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		var log_path = "user://logs/pixelize3d_%s.log" % timestamp
		
		# Crear directorio de logs si no existe
		DirAccess.make_dir_recursive_absolute("user://logs")
		
		log_file = FileAccess.open(log_path, FileAccess.WRITE)
		if log_file:
			write_log(LogLevel.INFO, "Sistema de logging inicializado", {"log_file": log_path})

func write_log(level: LogLevel, message: String, data: Dictionary = {}):
	if level < current_log_level:
		return
	
	var entry = {
		"timestamp": Time.get_ticks_msec(),
		"datetime": Time.get_datetime_string_from_system(),
		"level": _get_level_string(level),
		"message": message,
		"data": data,
		"caller": _get_caller_info()
	}
	
	# Añadir a buffer
	log_buffer.append(entry)
	if log_buffer.size() > max_log_entries:
		log_buffer.pop_front()
	
	# Actualizar métricas
	match level:
		LogLevel.ERROR:
			performance_metrics.errors_logged += 1
		LogLevel.WARNING:
			performance_metrics.warnings_logged += 1
	
	# Escribir a consola
	if enable_console_logging:
		_write_to_console(entry)
	
	# Escribir a archivo
	if enable_file_logging and log_file:
		_write_to_file(entry)
	
	emit_signal("log_written", entry)

func _write_to_console(entry: Dictionary):
	var formatted = "[%s] %s: %s" % [entry.level, entry.datetime, entry.message]
	
	if not entry.data.is_empty():
		formatted += " | " + JSON.stringify(entry.data)
	
	match entry.level:
		"ERROR", "CRITICAL":
			push_error(formatted)
		"WARNING":
			push_warning(formatted)
		_:
			print(formatted)

func _write_to_file(entry: Dictionary):
	if not log_file:
		return
	
	var json_entry = JSON.stringify(entry) + "\n"
	log_file.store_string(json_entry)
	log_file.flush()
	
	# Verificar rotación de logs
	if log_file.get_length() > log_rotation_size:
		_rotate_log_file()

func _rotate_log_file():
	log_file.close()
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var new_log_path = "user://logs/pixelize3d_%s.log" % timestamp
	
	log_file = FileAccess.open(new_log_path, FileAccess.WRITE)
	write_log(LogLevel.INFO, "Log rotado", {"new_file": new_log_path})

func _get_level_string(level: LogLevel) -> String:
	match level:
		LogLevel.VERBOSE: return "VERBOSE"
		LogLevel.DEBUG: return "DEBUG"
		LogLevel.INFO: return "INFO"
		LogLevel.WARNING: return "WARNING"
		LogLevel.ERROR: return "ERROR"
		LogLevel.CRITICAL: return "CRITICAL"
	return "UNKNOWN"

func _get_caller_info() -> Dictionary:
	var stack = get_stack()
	if stack.size() > 3:
		var caller = stack[3]
		return {
			"function": caller.function,
			"source": caller.source,
			"line": caller.line
		}
	return {}

# Funciones de conveniencia
func verbose(message: String, data: Dictionary = {}):
	write_log(LogLevel.VERBOSE, message, data)

func debug(message: String, data: Dictionary = {}):
	write_log(LogLevel.DEBUG, message, data)

func info(message: String, data: Dictionary = {}):
	write_log(LogLevel.INFO, message, data)

func warning(message: String, data: Dictionary = {}):
	write_log(LogLevel.WARNING, message, data)

func error(message: String, data: Dictionary = {}):
	write_log(LogLevel.ERROR, message, data)

func critical(message: String, data: Dictionary = {}):
	write_log(LogLevel.CRITICAL, message, data)

# Sistema de timing para medición de rendimiento
func start_timer(timer_name: String):
	timers[timer_name] = {
		"start": Time.get_ticks_msec(),
		"laps": []
	}
	debug("Timer iniciado", {"timer": timer_name})

func lap_timer(timer_name: String, lap_name: String = ""):
	if not timer_name in timers:
		warning("Timer no encontrado", {"timer": timer_name})
		return
	
	var current_time = Time.get_ticks_msec()
	var lap_time = current_time - timers[timer_name].start
	
	timers[timer_name].laps.append({
		"name": lap_name,
		"time": lap_time
	})
	
	debug("Timer lap", {
		"timer": timer_name,
		"lap": lap_name,
		"time_ms": lap_time
	})

func stop_timer(timer_name: String) -> float:
	if not timer_name in timers:
		warning("Timer no encontrado", {"timer": timer_name})
		return 0.0
	
	var total_time = Time.get_ticks_msec() - timers[timer_name].start
	
	info("Timer finalizado", {
		"timer": timer_name,
		"total_time_ms": total_time,
		"laps": timers[timer_name].laps
	})
	
	timers.erase(timer_name)
	return total_time

# Generación de reportes de debug
func generate_debug_report() -> Dictionary:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"session_info": _get_session_info(),
		"performance_metrics": performance_metrics,
		"recent_errors": _get_recent_errors(),
		"recent_warnings": _get_recent_warnings(),
		"system_state": _get_system_state(),
		"memory_usage": _get_memory_usage()
	}
	
	emit_signal("debug_report_generated", report)
	return report

func _get_session_info() -> Dictionary:
	return {
		"start_time": Time.get_unix_time_from_system(),
		"godot_version": Engine.get_version_info(),
		"os": OS.get_name(),
		"cpu_count": OS.get_processor_count(),
		"log_entries": log_buffer.size()
	}

func _get_recent_errors() -> Array:
	var errors = []
	for entry in log_buffer:
		if entry.level in ["ERROR", "CRITICAL"]:
			errors.append(entry)
	
	# Retornar últimos 50 errores
	if errors.size() > 50:
		return errors.slice(-50)
	return errors

func _get_recent_warnings() -> Array:
	var warnings = []
	for entry in log_buffer:
		if entry.level == "WARNING":
			warnings.append(entry)
	
	# Retornar últimas 50 advertencias
	if warnings.size() > 50:
		return warnings.slice(-50)
	return warnings

func _get_system_state() -> Dictionary:
	var state = {
		"rendering_active": false,
		"current_task": "",
		"models_loaded": 0,
		"exports_pending": 0
	}
	
	# Obtener estado de componentes si existen
	if has_node("/root/Main/SpriteRenderer"):
		var renderer = get_node("/root/Main/SpriteRenderer")
		state.rendering_active = renderer.is_rendering if "is_rendering" in renderer else false
	
	return state

func _get_memory_usage() -> Dictionary:
	return {
		"static_memory": OS.get_static_memory_usage(),
		"static_memory_peak": OS.get_static_memory_peak_usage(),
		"video_memory": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"texture_memory": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"buffer_memory": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)
	}

# Exportar logs
func export_logs(output_path: String, format: String = "json"):
	match format:
		"json":
			_export_logs_json(output_path)
		"csv":
			_export_logs_csv(output_path)
		"txt":
			_export_logs_text(output_path)
		_:
			error("Formato de exportación no soportado", {"format": format})

func _export_logs_json(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var logs_data = {
			"export_date": Time.get_datetime_string_from_system(),
			"total_entries": log_buffer.size(),
			"metrics": performance_metrics,
			"logs": log_buffer
		}
		file.store_string(JSON.stringify(logs_data, "\t"))
		file.close()
		info("Logs exportados", {"path": path, "format": "json"})

func _export_logs_csv(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# Header
		file.store_line("Timestamp,Level,Message,Data")
		
		# Entries
		for entry in log_buffer:
			var line = "%s,%s,\"%s\",\"%s\"" % [
				entry.datetime,
				entry.level,
				entry.message.replace('"', '""'),
				JSON.stringify(entry.data).replace('"', '""')
			]
			file.store_line(line)
		
		file.close()
		info("Logs exportados", {"path": path, "format": "csv"})

func _export_logs_text(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		for entry in log_buffer:
			var line = "[%s] %s: %s" % [entry.level, entry.datetime, entry.message]
			if not entry.data.is_empty():
				line += " | " + JSON.stringify(entry.data)
			file.store_line(line)
		
		file.close()
		info("Logs exportados", {"path": path, "format": "txt"})

# Callbacks para eventos del sistema
func _on_fbx_loaded(model_data: Dictionary):
	info("FBX cargado", {
		"type": model_data.get("type", "unknown"),
		"name": model_data.get("name", ""),
		"meshes": model_data.get("meshes", []).size(),
		"bones": model_data.get("bone_count", 0)
	})

func _on_rendering_complete():
	performance_metrics.renders_completed += 1
	info("Renderizado completado", {"total_renders": performance_metrics.renders_completed})

func _on_export_complete(file_path: String):
	info("Exportación completada", {"file": file_path})

# Limpieza
func _exit_tree():
	if log_file:
		write_log(LogLevel.INFO, "Cerrando sistema de logging")
		log_file.close()

# Función para debug visual (overlay)
func create_debug_overlay() -> Control:
	var overlay = preload("res://scripts/ui/debug_overlay.gd").new()
	overlay.debug_system = self
	return overlay
