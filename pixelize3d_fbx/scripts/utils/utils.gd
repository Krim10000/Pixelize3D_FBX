# scripts/utils/utils.gd
extends Node
class_name Utils

# Input: Varias operaciones de utilidad
# Output: Funciones helper para toda la aplicación

# Constantes útiles
const SUPPORTED_IMAGE_FORMATS = ["png", "jpg", "jpeg", "webp", "bmp"]
const ISOMETRIC_ANGLES = {
	"classic": 45.0,
	"true_isometric": 35.264,  # arctan(1/√2)
	"military": 30.0,
	"chinese": 60.0
}

# Utilidades de archivos
static func ensure_directory_exists(path: String) -> bool:
	var dir = DirAccess.open(path.get_base_dir())
	if not dir:
		var error = DirAccess.make_dir_recursive_absolute(path)
		return error == OK
	return true

static func get_unique_filename(base_path: String, extension: String = "") -> String:
	var path = base_path
	if extension != "" and not extension.begins_with("."):
		extension = "." + extension
	
	if not FileAccess.file_exists(path + extension):
		return path + extension
	
	var counter = 1
	while FileAccess.file_exists(path + "_" + str(counter) + extension):
		counter += 1
	
	return path + "_" + str(counter) + extension

static func copy_file(from: String, to: String) -> Error:
	var source = FileAccess.open(from, FileAccess.READ)
	if not source:
		return ERR_FILE_NOT_FOUND
	
	var data = source.get_buffer(source.get_length())
	source.close()
	
	var dest = FileAccess.open(to, FileAccess.WRITE)
	if not dest:
		return ERR_CANT_CREATE
	
	dest.store_buffer(data)
	dest.close()
	
	return OK

static func get_files_in_directory(path: String, extensions: Array = []) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if extensions.is_empty():
				files.append(file_name)
			else:
				var file_ext = file_name.get_extension().to_lower()
				if file_ext in extensions:
					files.append(file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

# Utilidades de imagen
static func create_transparent_image(size: Vector2i) -> Image:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func resize_image_keep_aspect(image: Image, max_size: Vector2i) -> Image:
	var current_size = image.get_size()
	var scale = min(
		float(max_size.x) / current_size.x,
		float(max_size.y) / current_size.y
	)
	
	var new_size = Vector2i(
		int(current_size.x * scale),
		int(current_size.y * scale)
	)
	
	image.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	return image

static func apply_outline_to_image(image: Image, color: Color, width: int = 1) -> Image:
	var size = image.get_size()
	var outlined = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	outlined.fill(Color(0, 0, 0, 0))
	
	# Copiar imagen original
	outlined.blit_rect(image, Rect2i(0, 0, size.x, size.y), Vector2i.ZERO)
	
	# Aplicar outline
	for y in range(size.y):
		for x in range(size.x):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.01: # Pixel no transparente
				# Verificar píxeles adyacentes
				for dy in range(-width, width + 1):
					for dx in range(-width, width + 1):
						if dx == 0 and dy == 0:
							continue
						
						var nx = x + dx
						var ny = y + dy
						
						if nx >= 0 and nx < size.x and ny >= 0 and ny < size.y:
							var neighbor = image.get_pixel(nx, ny)
							if neighbor.a < 0.01: # Pixel transparente adyacente
								outlined.set_pixel(nx, ny, color)
	
	# Volver a aplicar la imagen original encima
	outlined.blit_rect(image, Rect2i(0, 0, size.x, size.y), Vector2i.ZERO)
	
	return outlined

static func create_grid_texture(cell_size: int, grid_size: Vector2i, color: Color) -> ImageTexture:
	var img = Image.create(
		cell_size * grid_size.x,
		cell_size * grid_size.y,
		false,
		Image.FORMAT_RGBA8
	)
	
	img.fill(Color(0, 0, 0, 0))
	
	# Dibujar líneas de grid
	for x in range(grid_size.x + 1):
		for y in range(cell_size * grid_size.y):
			img.set_pixel(x * cell_size, y, color)
	
	for y in range(grid_size.y + 1):
		for x in range(cell_size * grid_size.x):
			img.set_pixel(x, y * cell_size, color)
	
	return ImageTexture.create_from_image(img)

# Utilidades matemáticas
static func angle_difference(angle1: float, angle2: float) -> float:
	var diff = angle2 - angle1
	while diff > 180:
		diff -= 360
	while diff < -180:
		diff += 360
	return diff

static func snap_to_grid(position: Vector2, grid_size: float) -> Vector2:
	return Vector2(
		round(position.x / grid_size) * grid_size,
		round(position.y / grid_size) * grid_size
	)

static func world_to_isometric(world_pos: Vector3) -> Vector2:
	return Vector2(
		(world_pos.x - world_pos.z) * 0.5,
		(world_pos.x + world_pos.z) * 0.25 - world_pos.y * 0.5
	)

static func isometric_to_world(iso_pos: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(
		iso_pos.x + iso_pos.y * 2,
		-height,
		-iso_pos.x + iso_pos.y * 2
	)

# Utilidades de animación
static func calculate_frame_count(duration: float, fps: float) -> int:
	return max(1, int(duration * fps))

static func get_direction_from_angle(angle: float, directions: int) -> int:
	var normalized_angle = fmod(angle + 360.0, 360.0)
	var angle_per_direction = 360.0 / directions
	return int(round(normalized_angle / angle_per_direction)) % directions

static func get_angle_from_direction(direction: int, directions: int) -> float:
	return (360.0 / directions) * direction

# Utilidades de color
static func generate_palette(base_color: Color, count: int) -> Array:
	var palette = []
	
	for i in range(count):
		var factor = float(i) / float(count - 1)
		var color = Color()
		
		# Generar variaciones de brillo
		color.h = base_color.h
		color.s = base_color.s * (0.5 + factor * 0.5)
		color.v = base_color.v * (0.3 + factor * 0.7)
		color.a = 1.0
		
		palette.append(color)
	
	return palette

static func reduce_colors(image: Image, palette: Array) -> Image:
	var size = image.get_size()
	var reduced = image.duplicate()
	
	for y in range(size.y):
		for x in range(size.x):
			var pixel = reduced.get_pixel(x, y)
			if pixel.a > 0.01:
				var closest_color = find_closest_color(pixel, palette)
				reduced.set_pixel(x, y, closest_color)
	
	return reduced

static func find_closest_color(color: Color, palette: Array) -> Color:
	var min_distance = INF
	var closest = color
	
	for palette_color in palette:
		var distance = color_distance(color, palette_color)
		if distance < min_distance:
			min_distance = distance
			closest = palette_color
	
	return closest

static func color_distance(c1: Color, c2: Color) -> float:
	# Distancia euclidiana en espacio RGB
	var dr = c1.r - c2.r
	var dg = c1.g - c2.g
	var db = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db)

# Utilidades de metadata
static func parse_json_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("No se pudo abrir archivo JSON: " + path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Error parseando JSON: " + json.error_string)
		return {}
	
	return json.data

static func save_json_file(data: Dictionary, path: String, pretty: bool = true) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	
	var json_string = JSON.stringify(data, "\t" if pretty else "")
	file.store_string(json_string)
	file.close()
	
	return true

# Utilidades de validación
static func validate_sprite_size(size: int) -> bool:
	# Verificar que sea potencia de 2 o múltiplo de 8
	return size > 0 and (size & (size - 1)) == 0 or size % 8 == 0

static func validate_direction_count(count: int) -> bool:
	# Direcciones válidas: 4, 8, 16, 32
	return count in [4, 8, 16, 32]

static func validate_fps(fps: float) -> bool:
	return fps > 0 and fps <= 60

# Utilidades de formato
static func format_file_size(bytes: int) -> String:
	var units = ["B", "KB", "MB", "GB"]
	var index = 0
	var size = float(bytes)
	
	while size >= 1024.0 and index < units.size() - 1:
		size /= 1024.0
		index += 1
	
	return "%.2f %s" % [size, units[index]]

static func format_time_duration(seconds: float) -> String:
	if seconds < 60:
		return "%.1f segundos" % seconds
	elif seconds < 3600:
		var minutes = int(seconds / 60)
		var secs = int(seconds) % 60
		return "%d:%02d minutos" % [minutes, secs]
	else:
		var hours = int(seconds / 3600)
		var minutes = int((seconds % 3600) / 60)
		return "%d:%02d horas" % [hours, minutes]

static func format_number_with_commas(number: int) -> String:
	var str_num = str(number)
	var result = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count == 3:
			result = "," + result
			count = 0
		result = str_num[i] + result
		count += 1
	
	return result

# Generador de nombres únicos
static func generate_unique_name(base_name: String, existing_names: Array) -> String:
	if not base_name in existing_names:
		return base_name
	
	var counter = 1
	var new_name = base_name + "_" + str(counter)
	
	while new_name in existing_names:
		counter += 1
		new_name = base_name + "_" + str(counter)
	
	return new_name

# Utilidades de depuración
static func print_dict_tree(dict: Dictionary, indent: int = 0):
	var indent_str = "  ".repeat(indent)
	
	for key in dict:
		var value = dict[key]
		if value is Dictionary:
			print(indent_str + str(key) + ":")
			print_dict_tree(value, indent + 1)
		elif value is Array:
			print(indent_str + str(key) + ": [%d items]" % value.size())
		else:
			print(indent_str + str(key) + ": " + str(value))

static func create_debug_texture(size: Vector2i, color: Color, text: String = "") -> ImageTexture:
	var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# Dibujar borde
	for x in range(size.x):
		img.set_pixel(x, 0, Color.BLACK)
		img.set_pixel(x, size.y - 1, Color.BLACK)
	
	for y in range(size.y):
		img.set_pixel(0, y, Color.BLACK)
		img.set_pixel(size.x - 1, y, Color.BLACK)
	
	# TODO: Añadir texto si es necesario
	
	return ImageTexture.create_from_image(img)

# Sistema de caché simple
class SimpleCache:
	var _cache: Dictionary = {}
	var _max_size: int
	var _access_order: Array = []
	
	func _init(max_size: int = 100):
		_max_size = max_size
	
	func get(key: String, default = null):
		if key in _cache:
			# Actualizar orden de acceso
			_access_order.erase(key)
			_access_order.push_back(key)
			return _cache[key]
		return default
	
	func set(key: String, value) -> void:
		if key in _cache:
			_access_order.erase(key)
		elif _cache.size() >= _max_size:
			# Eliminar el menos recientemente usado
			var lru_key = _access_order.pop_front()
			_cache.erase(lru_key)
		
		_cache[key] = value
		_access_order.push_back(key)
	
	func clear() -> void:
		_cache.clear()
		_access_order.clear()
	
	func has(key: String) -> bool:
		return key in _cache
	
	func size() -> int:
		return _cache.size()

# Pool de objetos para optimización
class ObjectPool:
	var _pool: Array = []
	var _active: Array = []
	var _create_func: Callable
	var _reset_func: Callable
	
	func _init(create_func: Callable, reset_func: Callable = Callable()):
		_create_func = create_func
		_reset_func = reset_func
	
	func get():
		var obj
		if _pool.is_empty():
			obj = _create_func.call()
		else:
			obj = _pool.pop_back()
		
		_active.append(obj)
		return obj
	
	func release(obj) -> void:
		if obj in _active:
			_active.erase(obj)
			
			if _reset_func.is_valid():
				_reset_func.call(obj)
			
			_pool.append(obj)
	
	func release_all() -> void:
		while not _active.is_empty():
			release(_active[0])
	
	func clear() -> void:
		_pool.clear()
		_active.clear()

# Función para crear un hash único basado en contenido
static func generate_content_hash(data: Dictionary) -> String:
	var str_data = JSON.stringify(data)
	return str_data.sha256_text().substr(0, 16)

# Verificar compatibilidad del sistema
static func check_system_compatibility() -> Dictionary:
	return {
		"os": OS.get_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"cpu_cores": OS.get_processor_count(),
		"memory_mb": OS.get_static_memory_usage() / 1048576,
		"godot_version": Engine.get_version_info(),
		"compatible": true # Siempre compatible con Godot 4.4+
	}
