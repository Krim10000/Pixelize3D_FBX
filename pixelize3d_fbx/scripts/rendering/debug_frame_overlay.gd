# pixelize3d_fbx/scripts/rendering/debug_frame_overlay.gd
# Sistema de debug overlay para numeros de frame - LISTO PARA PRODUCCION
# Input: Imagen capturada + datos del frame
# Output: Imagen con numero de frame superpuesto

extends Node
class_name DebugFrameOverlay

# Configuracion del overlay
var debug_enabled: bool = false
var font_size: int = 18
var text_color: Color = Color.WHITE
var background_color: Color = Color(0, 0, 0, 0.8)
var corner_offset: Vector2i = Vector2i(8, 8)
var font_resource: Font

# Cache de numeros renderizados para performance
var number_cache: Dictionary = {}
var max_cache_size: int = 100

func _ready():
	print("🛠️ DebugFrameOverlay inicializado")
	_setup_default_font()

func _setup_default_font():
	"""Configurar fuente por defecto"""
	# Usar fuente del sistema
	font_resource = ThemeDB.fallback_font
	if not font_resource:
		# Crear fuente basica como fallback
		font_resource = SystemFont.new()
		font_resource.font_names = ["Arial", "DejaVu Sans", "Liberation Sans"]

# ========================================================================
# API PRINCIPAL
# ========================================================================

func apply_debug_overlay(image: Image, frame_data: Dictionary) -> Image:
	"""Aplicar overlay de debug a la imagen"""
	if not debug_enabled:
		return image
	
	var frame_number = frame_data.get("frame", 0)
	var direction = frame_data.get("direction", 0) 
	var animation = frame_data.get("animation", "")
	
	# Crear texto del overlay
	var overlay_text = str(frame_number)
	
	# Si queremos mas informacion, descomentar:
	# var overlay_text = "F%d D%d" % [frame_number, direction]
	
	return await _add_text_to_image(image, overlay_text, frame_number)

func set_debug_enabled(enabled: bool):
	"""Habilitar/deshabilitar debug overlay"""
	debug_enabled = enabled
	print("🛠️ Debug frame overlay: %s" % ("ENABLED" if enabled else "DISABLED"))

func set_debug_appearance(config: Dictionary):
	"""Configurar apariencia del overlay"""
	if config.has("font_size"):
		font_size = config.font_size
	if config.has("text_color"):
		text_color = config.text_color  
	if config.has("background_color"):
		background_color = config.background_color
	if config.has("corner_offset"):
		corner_offset = config.corner_offset
	
	# Limpiar cache cuando cambia apariencia
	number_cache.clear()

# ========================================================================
# RENDERIZADO DE TEXTO EN IMAGEN
# ========================================================================

func _add_text_to_image(original_image: Image, text: String, frame_number: int) -> Image:
	"""Añadir texto a la imagen en la esquina superior derecha"""
	
	# Buscar en cache primero
	var cache_key = "%s_%d_%d" % [text, font_size, frame_number % 1000] # Limitar cache
	if cache_key in number_cache:
		return _composite_cached_overlay(original_image, number_cache[cache_key])
	
	# Crear overlay de texto
	var text_overlay = await _create_text_overlay(text)
	if text_overlay:
		# Cachear el overlay
		_cache_text_overlay(cache_key, text_overlay)
		
		# Componer con imagen original
		return _composite_overlay(original_image, text_overlay)
	
	return original_image

func _create_text_overlay(text: String) -> Image:
	"""Crear imagen del overlay de texto"""
	
	# Calcular tamaño necesario para el texto
	var text_size = _calculate_text_size(text)
	
	# Crear viewport temporal para renderizar texto
	var viewport = SubViewport.new()
	viewport.size = Vector2i(text_size.x + 16, text_size.y + 8) # Padding
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Crear contenedor con fondo
	var background = ColorRect.new()
	background.color = background_color
	background.size = viewport.size
	viewport.add_child(background)
	
	# Crear label con texto
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", font_resource)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", text_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = viewport.size
	viewport.add_child(label)
	
	# Añadir viewport temporal al arbol para renderizar
	add_child(viewport)
	
	# Forzar renderizado
	await RenderingServer.frame_post_draw
	
	# Capturar imagen
	var overlay_image = viewport.get_texture().get_image()
	
	# Limpiar viewport temporal
	viewport.queue_free()
	
	return overlay_image

func _calculate_text_size(text: String) -> Vector2i:
	"""Calcular tamaño aproximado del texto"""
	# Calculo aproximado basado en font_size
	var char_width = font_size * 0.6  # Aproximacion
	var char_height = font_size * 1.2
	
	return Vector2i(int(text.length() * char_width), int(char_height))

func _composite_overlay(base_image: Image, overlay_image: Image) -> Image:
	"""Componer overlay con imagen base en esquina superior derecha"""
	var result = base_image.duplicate()
	
	# Calcular posicion en esquina superior derecha
	var base_size = result.get_size()
	var overlay_size = overlay_image.get_size()
	
	var pos_x = base_size.x - overlay_size.x - corner_offset.x
	var pos_y = corner_offset.y
	
	# Asegurar que no se sale de bounds
	pos_x = max(0, pos_x)
	pos_y = max(0, pos_y)
	
	# Componer imagenes pixel por pixel
	_blit_with_alpha(result, overlay_image, Vector2i(pos_x, pos_y))
	
	return result

func _composite_cached_overlay(base_image: Image, cached_overlay: Dictionary) -> Image:
	"""Componer usando overlay cacheado"""
	var result = base_image.duplicate()
	var overlay_image = cached_overlay.image
	var position = cached_overlay.position
	
	# Recalcular posicion por si el tamaño de base cambio
	var base_size = result.get_size() 
	var overlay_size = overlay_image.get_size()
	
	var pos_x = base_size.x - overlay_size.x - corner_offset.x
	var pos_y = corner_offset.y
	
	pos_x = max(0, pos_x)
	pos_y = max(0, pos_y)
	
	_blit_with_alpha(result, overlay_image, Vector2i(pos_x, pos_y))
	
	return result

func _blit_with_alpha(dst: Image, src: Image, position: Vector2i):
	"""Mezclar imagen con soporte alpha"""
	var src_size = src.get_size()
	var dst_size = dst.get_size()
	
	for y in range(src_size.y):
		for x in range(src_size.x):
			var dst_x = position.x + x
			var dst_y = position.y + y
			
			# Verificar bounds
			if dst_x >= 0 and dst_x < dst_size.x and dst_y >= 0 and dst_y < dst_size.y:
				var src_pixel = src.get_pixel(x, y)
				
				# Solo dibujar si el pixel tiene alpha > 0
				if src_pixel.a > 0.01:
					if src_pixel.a >= 0.99:
						# Alpha completa, reemplazar directamente  
						dst.set_pixel(dst_x, dst_y, src_pixel)
					else:
						# Mezclar con alpha
						var dst_pixel = dst.get_pixel(dst_x, dst_y)
						var blended = _blend_colors(dst_pixel, src_pixel, src_pixel.a)
						dst.set_pixel(dst_x, dst_y, blended)

func _blend_colors(base: Color, overlay: Color, alpha: float) -> Color:
	"""Mezclar colores con alpha blending"""
	var inv_alpha = 1.0 - alpha
	return Color(
		base.r * inv_alpha + overlay.r * alpha,
		base.g * inv_alpha + overlay.g * alpha, 
		base.b * inv_alpha + overlay.b * alpha,
		max(base.a, overlay.a)
	)

# ========================================================================
# CACHE MANAGEMENT
# ========================================================================

func _cache_text_overlay(key: String, overlay_image: Image):
	"""Cachear overlay de texto para reutilizacion"""
	if number_cache.size() >= max_cache_size:
		_cleanup_cache()
	
	number_cache[key] = {
		"image": overlay_image,
		"timestamp": Time.get_ticks_msec()
	}

func _cleanup_cache():
	"""Limpiar cache manteniendo solo los mas recientes"""
	var keys = number_cache.keys()
	
	# Ordenar por timestamp y mantener solo la mitad mas reciente
	keys.sort_custom(func(a, b): return number_cache[a].timestamp > number_cache[b].timestamp)
	
	var keep_count = max_cache_size / 2
	for i in range(keep_count, keys.size()):
		number_cache.erase(keys[i])

# ========================================================================
# UTILIDADES ADICIONALES
# ========================================================================

func create_simple_number_overlay(frame_number: int, image_size: Vector2i) -> Image:
	"""Crear overlay simple solo con numero (version optimizada)"""
	
	# Crear imagen pequeña para el numero
	var overlay_size = Vector2i(32, 20)  # Tamaño fijo pequeño
	var overlay = Image.create(overlay_size.x, overlay_size.y, false, Image.FORMAT_RGBA8)
	
	# Fondo semi-transparente
	overlay.fill(background_color)
	
	# Dibujar numero pixel por pixel (version basica)
	# Para numeros 0-9, usar una fuente bitmap simple
	_draw_simple_number(overlay, frame_number)
	
	return overlay

func _draw_simple_number(image: Image, number: int):
	"""Dibujar numero usando pixels (implementacion basica)"""
	var digit_patterns = _get_digit_patterns()
	var num_str = str(number)
	
	var start_x = 2
	var start_y = 2
	
	for i in range(num_str.length()):
		var digit = int(num_str[i])
		if digit in digit_patterns:
			_draw_digit_pattern(image, digit_patterns[digit], start_x + i * 6, start_y)

func _get_digit_patterns() -> Dictionary:
	"""Obtener patrones de pixeles para digitos 0-9"""
	return {
		0: [
			"111",
			"101", 
			"101",
			"101",
			"111"
		],
		1: [
			"010",
			"110",
			"010",
			"010",
			"111"
		],
		2: [
			"111",
			"001",
			"111", 
			"100",
			"111"
		],
		3: [
			"111",
			"001",
			"111",
			"001", 
			"111"
		],
		4: [
			"101",
			"101",
			"111",
			"001",
			"001"
		],
		5: [
			"111",
			"100",
			"111",
			"001",
			"111"
		],
		6: [
			"111",
			"100", 
			"111",
			"101",
			"111"
		],
		7: [
			"111",
			"001",
			"001",
			"001",
			"001"
		],
		8: [
			"111",
			"101",
			"111",
			"101",
			"111"
		],
		9: [
			"111", 
			"101",
			"111",
			"001",
			"111"
		]
	}

func _draw_digit_pattern(image: Image, pattern: Array, start_x: int, start_y: int):
	"""Dibujar patron de digito en la imagen"""
	for y in range(pattern.size()):
		var row = pattern[y]
		for x in range(row.length()):
			if row[x] == '1':
				var px = start_x + x
				var py = start_y + y
				if px < image.get_width() and py < image.get_height():
					image.set_pixel(px, py, text_color)

# ========================================================================
# API PUBLICA EXTENDIDA
# ========================================================================

func get_debug_status() -> Dictionary:
	"""Obtener estado del sistema de debug"""
	return {
		"enabled": debug_enabled,
		"font_size": font_size,
		"text_color": text_color,
		"background_color": background_color,
		"cache_size": number_cache.size(),
		"max_cache": max_cache_size
	}

func clear_cache():
	"""Limpiar cache manualmente"""
	number_cache.clear()
	print("🛠️ Debug overlay cache cleared")

# Funcion estatica para uso facil
static func add_frame_number_to_image(image: Image, frame_number: int) -> Image:
	"""Funcion estatica rapida para añadir numero de frame"""
	var overlay = DebugFrameOverlay.new()
	overlay.debug_enabled = true
	var result = await overlay.apply_debug_overlay(image, {"frame": frame_number})
	overlay.queue_free()
	return result
