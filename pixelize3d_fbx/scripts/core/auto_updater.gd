# scripts/core/auto_updater.gd
extends Node

# Input: Versión actual y servidor de actualizaciones
# Output: Sistema de actualización automática

signal update_check_started()
signal update_available(version_info: Dictionary)
signal update_not_available()
signal update_download_started()
signal update_download_progress(percent: float)
signal update_download_complete()
signal update_install_started()
signal update_install_complete()
signal update_error(error: String)

const CURRENT_VERSION = "1.0.0"
const UPDATE_CHECK_URL = "https://api.github.com/repos/pixelize3d/releases/latest"
const UPDATE_CHECK_INTERVAL = 3600 # Verificar cada hora

var http_request: HTTPRequest
var update_info: Dictionary = {}
var is_checking: bool = false
var is_downloading: bool = false
var auto_check_enabled: bool = true
var check_timer: Timer

var download_path: String = "user://updates"
var temp_file: String = ""

func _ready():
	_setup_http_request()
	_setup_auto_check()
	
	# Crear directorio de actualizaciones
	DirAccess.make_dir_recursive_absolute(download_path)

func _setup_http_request():
	http_request = HTTPRequest.new()
	http_request.timeout = 30.0
	add_child(http_request)

func _setup_auto_check():
	check_timer = Timer.new()
	check_timer.wait_time = UPDATE_CHECK_INTERVAL
	check_timer.timeout.connect(_on_auto_check_timeout)
	add_child(check_timer)
	
	if auto_check_enabled:
		check_timer.start()
		# Verificar al inicio después de un delay
		await get_tree().create_timer(5.0).timeout
		check_for_updates()

func check_for_updates():
	if is_checking or is_downloading:
		return
	
	is_checking = true
	emit_signal("update_check_started")
	
	# Desconectar señales anteriores
	for connection in http_request.request_completed.get_connections():
		http_request.request_completed.disconnect(connection.callable)
	
	http_request.request_completed.connect(_on_version_check_completed)
	
	var headers = ["User-Agent: Pixelize3D-Updater/" + CURRENT_VERSION]
	var error = http_request.request(UPDATE_CHECK_URL, headers)
	
	if error != OK:
		is_checking = false
		emit_signal("update_error", "Error al iniciar verificación: " + str(error))

func _on_version_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_checking = false
	
	if response_code != 200:
		emit_signal("update_error", "Error al verificar actualizaciones: " + str(response_code))
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		emit_signal("update_error", "Error al parsear respuesta del servidor")
		return
	
	var data = json.data
	if not data is Dictionary:
		emit_signal("update_error", "Respuesta del servidor inválida")
		return
	
	# Analizar información de versión
	update_info = {
		"version": data.get("tag_name", "").strip_prefix("v"),
		"name": data.get("name", ""),
		"description": data.get("body", ""),
		"download_url": "",
		"file_size": 0,
		"release_date": data.get("published_at", "")
	}
	
	# Buscar archivo de descarga apropiado
	var assets = data.get("assets", [])
	for asset in assets:
		var asset_name = asset.get("name", "")
		if _is_compatible_asset(asset_name):
			update_info.download_url = asset.get("browser_download_url", "")
			update_info.file_size = asset.get("size", 0)
			break
	
	# Comparar versiones
	if _is_newer_version(update_info.version):
		emit_signal("update_available", update_info)
	else:
		emit_signal("update_not_available")

func _is_compatible_asset(asset_name: String) -> bool:
	var os_name = OS.get_name().to_lower()
	var asset_lower = asset_name.to_lower()
	
	# Verificar compatibilidad con el sistema operativo
	match os_name:
		"windows":
			return asset_lower.ends_with(".exe") or asset_lower.contains("windows")
		"macos", "osx":
			return asset_lower.ends_with(".dmg") or asset_lower.contains("macos") or asset_lower.contains("osx")
		"linux":
			return asset_lower.ends_with(".appimage") or asset_lower.contains("linux")
		_:
			return false

func _is_newer_version(remote_version: String) -> bool:
	var current_parts = CURRENT_VERSION.split(".")
	var remote_parts = remote_version.split(".")
	
	# Comparar major.minor.patch
	for i in range(min(current_parts.size(), remote_parts.size())):
		var current_num = int(current_parts[i])
		var remote_num = int(remote_parts[i])
		
		if remote_num > current_num:
			return true
		elif remote_num < current_num:
			return false
	
	# Si todas las partes son iguales, verificar si hay más partes
	return remote_parts.size() > current_parts.size()

func download_update():
	if not update_info.has("download_url") or update_info.download_url == "":
		emit_signal("update_error", "URL de descarga no disponible")
		return
	
	if is_downloading:
		return
	
	is_downloading = true
	emit_signal("update_download_started")
	
	# Generar nombre de archivo temporal
	temp_file = download_path.path_join("update_" + str(Time.get_unix_time_from_system()) + ".tmp")
	
	# Configurar descarga
	http_request.download_file = temp_file
	http_request.use_threads = true
	
	# Desconectar señales anteriores
	for connection in http_request.request_completed.get_connections():
		http_request.request_completed.disconnect(connection.callable)
	
	http_request.request_completed.connect(_on_download_completed)
	
	# Conectar para progreso
	set_process(true)
	
	var headers = ["User-Agent: Pixelize3D-Updater/" + CURRENT_VERSION]
	var error = http_request.request(update_info.download_url, headers)
	
	if error != OK:
		is_downloading = false
		set_process(false)
		emit_signal("update_error", "Error al iniciar descarga: " + str(error))

func _process(_delta):
	if is_downloading and http_request.get_downloaded_bytes() > 0:
		var total = update_info.file_size
		var downloaded = http_request.get_downloaded_bytes()
		
		if total > 0:
			var percent = (float(downloaded) / float(total)) * 100.0
			emit_signal("update_download_progress", percent)

func _on_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_downloading = false
	set_process(false)
	http_request.download_file = ""
	
	if response_code != 200:
		emit_signal("update_error", "Error al descargar: " + str(response_code))
		_cleanup_temp_file()
		return
	
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("update_error", "Descarga fallida: " + str(result))
		_cleanup_temp_file()
		return
	
	emit_signal("update_download_complete")
	
	# Verificar integridad del archivo descargado
	if not FileAccess.file_exists(temp_file):
		emit_signal("update_error", "Archivo descargado no encontrado")
		return
	
	var file = FileAccess.open(temp_file, FileAccess.READ)
	if not file:
		emit_signal("update_error", "No se pudo abrir el archivo descargado")
		return
	
	var file_size = file.get_length()
	file.close()
	
	if file_size != update_info.file_size:
		emit_signal("update_error", "Tamaño de archivo incorrecto")
		_cleanup_temp_file()
		return
	
	# Todo OK, proceder con instalación
	_prepare_installation()

func _prepare_installation():
	emit_signal("update_install_started")
	
	# Renombrar archivo temporal al nombre final
	var final_name = "Pixelize3D_" + update_info.version + _get_file_extension()
	var final_path = download_path.path_join(final_name)
	
	var dir = DirAccess.open(download_path)
	if dir:
		dir.rename(temp_file.get_file(), final_name)
		temp_file = final_path
	
	# Crear script de actualización
	_create_update_script(final_path)
	
	emit_signal("update_install_complete")

func _get_file_extension() -> String:
	match OS.get_name().to_lower():
		"windows":
			return ".exe"
		"macos", "osx":
			return ".dmg"
		"linux":
			return ".appimage"
		_:
			return ""

func _create_update_script(installer_path: String):
	var script_content = ""
	var script_path = ""
	
	match OS.get_name().to_lower():
		"windows":
			script_path = download_path.path_join("update.bat")
			script_content = """@echo off
echo Esperando a que se cierre Pixelize3D...
timeout /t 3 /nobreak > nul
echo Iniciando actualización...
start "" "%s"
del "%%~f0"
""" % installer_path
			
		"linux":
			script_path = download_path.path_join("update.sh")
			script_content = """#!/bin/bash
echo "Esperando a que se cierre Pixelize3D..."
sleep 3
echo "Iniciando actualización..."
chmod +x "%s"
"%s" &
rm -- "$0"
""" % [installer_path, installer_path]
			
		"macos", "osx":
			script_path = download_path.path_join("update.command")
			script_content = """#!/bin/bash
echo "Esperando a que se cierre Pixelize3D..."
sleep 3
echo "Montando imagen de disco..."
hdiutil attach "%s"
echo "Actualización lista para instalar"
rm -- "$0"
""" % installer_path
	
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(script_content)
		file.close()
		
		# Hacer ejecutable en Unix
		if OS.get_name() in ["Linux", "macOS", "OSX"]:
			OS.execute("chmod", ["+x", script_path])

func install_update():
	if not FileAccess.file_exists(temp_file):
		emit_signal("update_error", "Archivo de actualización no encontrado")
		return
	
	var script_path = ""
	match OS.get_name().to_lower():
		"windows":
			script_path = download_path.path_join("update.bat")
		"linux":
			script_path = download_path.path_join("update.sh")
		"macos", "osx":
			script_path = download_path.path_join("update.command")
	
	if FileAccess.file_exists(script_path):
		# Ejecutar script de actualización y cerrar aplicación
		OS.create_process(script_path, [])
		get_tree().quit()
	else:
		emit_signal("update_error", "Script de actualización no encontrado")

func _cleanup_temp_file():
	if temp_file != "" and FileAccess.file_exists(temp_file):
		DirAccess.remove_absolute(temp_file)
		temp_file = ""

func _on_auto_check_timeout():
	if auto_check_enabled:
		check_for_updates()

# Configuración
func set_auto_check(enabled: bool):
	auto_check_enabled = enabled
	
	if enabled and not check_timer.is_stopped():
		check_timer.start()
	elif not enabled:
		check_timer.stop()

func get_update_info() -> Dictionary:
	return update_info

func get_current_version() -> String:
	return CURRENT_VERSION

# Función para verificar actualizaciones de plugins
func check_plugin_updates():
	# Implementar verificación de actualizaciones de plugins
	pass
