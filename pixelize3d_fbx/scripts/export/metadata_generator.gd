# pixelize3d_fbx/scripts/export/metadata_generator.gd
# Generador de metadatos para diferentes engines - VERSIÓN CORREGIDA
# Input: Datos del spritesheet y configuración de exportación
# Output: Archivos de metadata en varios formatos (Unity, Web, CSS, XML, Godot)

extends Node

func _ready():
	print("✅ MetadataGenerator inicializado correctamente")

# Generar metadata para Unity
func generate_unity_metadata(animation_data: Dictionary, output_path: String) -> void:
	print("🎮 Generando metadata para Unity...")
	
	var guid = _generate_guid()
	var sprites_data = _generate_unity_sprites_array(animation_data)
	var sprite_width = animation_data.get("sprite_size", {}).get("width", 64)
	var pixels_per_unit = sprite_width / 2 if sprite_width > 0 else 32
	
	var meta_content = "fileFormatVersion: 2\n"
	meta_content += "guid: " + guid + "\n"
	meta_content += "TextureImporter:\n"
	meta_content += "  internalIDToNameTable: []\n"
	meta_content += "  externalObjects: {}\n"
	meta_content += "  serializedVersion: 11\n"
	meta_content += "  mipmaps:\n"
	meta_content += "    mipMapMode: 0\n"
	meta_content += "    enableMipMap: 0\n"
	meta_content += "    sRGBTexture: 1\n"
	meta_content += "    linearTexture: 0\n"
	meta_content += "  spriteMode: 2\n"
	meta_content += "  spriteExtrude: 1\n"
	meta_content += "  spriteMeshType: 1\n"
	meta_content += "  alignment: 0\n"
	meta_content += "  spritePivot: {x: 0.5, y: 0.5}\n"
	meta_content += "  spritePixelsToUnits: " + str(pixels_per_unit) + "\n"
	meta_content += "  spriteBorder: {x: 0, y: 0, z: 0, w: 0}\n"
	meta_content += "  spriteGenerateFallbackPhysicsShape: 1\n"
	meta_content += "  alphaUsage: 1\n"
	meta_content += "  alphaIsTransparency: 1\n"
	meta_content += "  textureType: 8\n"
	meta_content += "  textureShape: 1\n"
	meta_content += "  maxTextureSize: 2048\n"
	meta_content += "  textureSettings:\n"
	meta_content += "    serializedVersion: 2\n"
	meta_content += "    filterMode: 0\n"
	meta_content += "    aniso: -1\n"
	meta_content += "    mipBias: -100\n"
	meta_content += "    wrapU: 1\n"
	meta_content += "    wrapV: 1\n"
	meta_content += "    wrapW: 1\n"
	meta_content += "  nPOTScale: 0\n"
	meta_content += "  lightmap: 0\n"
	meta_content += "  compressionQuality: 50\n"
	meta_content += "  spriteSheet:\n"
	meta_content += "    serializedVersion: 2\n"
	meta_content += "    sprites: " + sprites_data + "\n"
	meta_content += "    outline: []\n"
	meta_content += "    physicsShape: []\n"
	meta_content += "    bones: []\n"
	meta_content += "    spriteID: 5e97eb03825dee720800000000000000\n"
	meta_content += "    internalID: 0\n"
	meta_content += "    vertices: []\n"
	meta_content += "    indices: []\n"
	meta_content += "    edges: []\n"
	meta_content += "    weights: []\n"
	meta_content += "  userData: \n"
	meta_content += "  assetBundleName: \n"
	meta_content += "  assetBundleVariant: \n"
	
	var file = FileAccess.open(output_path + ".meta", FileAccess.WRITE)
	if file:
		file.store_string(meta_content)
		file.close()
		print("✅ Unity .meta generado: %s.meta" % output_path)
	else:
		push_error("❌ Error generando Unity metadata")

func _generate_unity_sprites_array(animation_data: Dictionary) -> String:
	var sprites = []
	var sprite_index = 0
	
	for direction_data in animation_data.get("directions", []):
		for frame_data in direction_data.get("frames", []):
			# Corregido: Usar formato de cadena para rellenar con ceros
			var frame_name = "%s_dir%02d_frame%03d" % [
				animation_data.get("animation_name", "sprite"),
				direction_data.get("index", 0),
				frame_data.get("index", 0)
			]
			
			var sprite_entry = "\n    - serializedVersion: 2\n"
			sprite_entry += "      name: " + frame_name + "\n"
			sprite_entry += "      rect:\n"
			sprite_entry += "        serializedVersion: 2\n"
			sprite_entry += "        x: " + str(frame_data.get("x", 0)) + "\n"
			sprite_entry += "        y: " + str(frame_data.get("y", 0)) + "\n"
			sprite_entry += "        width: " + str(frame_data.get("width", 64)) + "\n"
			sprite_entry += "        height: " + str(frame_data.get("height", 64)) + "\n"
			sprite_entry += "      alignment: 0\n"
			sprite_entry += "      pivot: {x: 0.5, y: 0.5}\n"
			sprite_entry += "      border: {x: 0, y: 0, z: 0, w: 0}\n"
			sprite_entry += "      outline: []\n"
			sprite_entry += "      physicsShape: []\n"
			sprite_entry += "      tessellationDetail: 0\n"
			sprite_entry += "      bones: []\n"
			sprite_entry += "      spriteID: " + _generate_sprite_id() + "\n"
			sprite_entry += "      internalID: " + str(sprite_index) + "\n"
			sprite_entry += "      vertices: []\n"
			sprite_entry += "      indices: []\n"
			sprite_entry += "      edges: []\n"
			sprite_entry += "      weights: []"
			
			sprites.append(sprite_entry)
			sprite_index += 1
	
	return sprites.join("")

# Generar metadata para motores web (Phaser, PixiJS)
func generate_web_metadata(animation_data: Dictionary, output_path: String) -> void:
	print("🌐 Generando metadata para web...")
	
	var atlas = {
		"frames": {},
		"meta": {
			"app": "Pixelize3D FBX",
			"version": "1.0",
			"image": animation_data.get("animation_name", "sprite") + "_spritesheet.png",
			"format": "RGBA8888",
			"size": {
				"w": animation_data.get("spritesheet_size", {}).get("width", 512),
				"h": animation_data.get("spritesheet_size", {}).get("height", 512)
			},
			"scale": "1"
		},
		"animations": {}
	}
	
	# Generar frames
	for direction_data in animation_data.get("directions", []):
		var anim_frames = []
		
		for frame_data in direction_data.get("frames", []):
			# Corregido: Usar formato de cadena para rellenar con ceros
			var frame_name = "%s_dir%02d_frame%03d" % [
				animation_data.get("animation_name", "sprite"),
				direction_data.get("index", 0),
				frame_data.get("index", 0)
			]
			
			atlas.frames[frame_name] = {
				"frame": {
					"x": frame_data.get("x", 0),
					"y": frame_data.get("y", 0),
					"w": frame_data.get("width", 64),
					"h": frame_data.get("height", 64)
				},
				"rotated": false,
				"trimmed": false,
				"spriteSourceSize": {
					"x": 0,
					"y": 0,
					"w": frame_data.get("width", 64),
					"h": frame_data.get("height", 64)
				},
				"sourceSize": {
					"w": frame_data.get("width", 64),
					"h": frame_data.get("height", 64)
				}
			}
			
			anim_frames.append(frame_name)
		
		# Añadir animación por dirección
		var anim_name = "%s_dir%02d" % [
			animation_data.get("animation_name", "sprite"),
			direction_data.get("index", 0)
		]
		atlas.animations[anim_name] = anim_frames
	
	# Guardar como JSON
	var file = FileAccess.open(output_path + "_atlas.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(atlas, "\t"))
		file.close()
		print("✅ Web atlas generado: %s_atlas.json" % output_path)
	else:
		push_error("❌ Error generando web metadata")

# Generar archivo CSS para sprites web

# Generar XML para frameworks como Starling
func generate_xml_metadata(animation_data: Dictionary, output_path: String) -> void:
	print("📄 Generando XML metadata...")
	
	var animation_name = animation_data.get("animation_name", "sprite")
	var xml_content = '<?xml version="1.0" encoding="UTF-8"?>\n'
	xml_content += '<TextureAtlas imagePath="' + animation_name + '_spritesheet.png">\n'
	
	for direction_data in animation_data.get("directions", []):
		for frame_data in direction_data.get("frames", []):
			# Corregido: Usar formato de cadena para rellenar con ceros
			var subtexture_name = "%s_dir%02d_frame%03d" % [
				animation_name,
				direction_data.get("index", 0),
				frame_data.get("index", 0)
			]
			
			xml_content += '\t<SubTexture name="' + subtexture_name + '" x="' + str(frame_data.get("x", 0)) + '" y="' + str(frame_data.get("y", 0)) + '" width="' + str(frame_data.get("width", 64)) + '" height="' + str(frame_data.get("height", 64)) + '"/>\n'
	
	xml_content += '</TextureAtlas>'
	
	var file = FileAccess.open(output_path + "_atlas.xml", FileAccess.WRITE)
	if file:
		file.store_string(xml_content)
		file.close()
		print("✅ XML atlas generado: %s_atlas.xml" % output_path)
	else:
		push_error("❌ Error generando XML metadata")

# Generar metadata para Godot SpriteFrames
func generate_godot_metadata(animation_data: Dictionary, output_path: String) -> void:
	print("🎯 Generando metadata para Godot...")
	
	var godot_data = {
		"unit_name": animation_data.get("animation_name", "sprite"),
		"sprite_sheet_path": animation_data.get("animation_name", "sprite") + "_spritesheet.png",
		"frame_width": animation_data.get("sprite_size", {}).get("width", 64),
		"frame_height": animation_data.get("sprite_size", {}).get("height", 64),
		"directions": animation_data.get("directions", []).size(),
		"fps": animation_data.get("fps", 12),
		"total_frames": animation_data.get("total_frames", 0),
		"animations": {}
	}
	
	# Generar información de animaciones por dirección
	for direction_data in animation_data.get("directions", []):
		var dir_index = direction_data.get("index", 0)
		var directions_count = godot_data.directions
		var angle = dir_index * (360.0 / directions_count) if directions_count > 0 else 0.0
		
		godot_data.animations["dir_%02d" % dir_index] = {
			"direction": dir_index,
			"angle": angle,
			"frames": direction_data.get("frame_count", 1),
			"frame_data": direction_data.get("frames", [])
		}
	
	var file = FileAccess.open(output_path + "_godot.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(godot_data, "\t"))
		file.close()
		print("✅ Godot metadata generado: %s_godot.json" % output_path)
	else:
		push_error("❌ Error generando Godot metadata")

# Funciones auxiliares
func _generate_guid() -> String:
	"""Generar un GUID simple para Unity"""
	var chars = "0123456789abcdef"
	var guid = ""
	
	for i in range(32):
		guid += chars[randi() % chars.length()]
		if i in [7, 11, 15, 19]:
			guid += "-"
	
	return guid

func _generate_sprite_id() -> String:
	"""Generar ID único para sprites"""
	var id = ""
	for i in range(16):
		id += str(randi() % 10)
	return id

func _sanitize_filename(filename: String) -> String:
	"""Limpiar nombre de archivo de caracteres problemáticos"""
	var sanitized = filename.replace(" ", "_")
	sanitized = sanitized.replace("/", "_")
	sanitized = sanitized.replace("\\", "_")
	sanitized = sanitized.replace(":", "_")
	sanitized = sanitized.replace("*", "_")
	sanitized = sanitized.replace("?", "_")
	sanitized = sanitized.replace("\"", "_")
	sanitized = sanitized.replace("<", "_")
	sanitized = sanitized.replace(">", "_")
	sanitized = sanitized.replace("|", "_")
	return sanitized

# Función principal para generar todos los formatos
func generate_all_metadata_formats(animation_data: Dictionary, output_path: String) -> void:
	print("📋 Generando todos los formatos de metadata...")
	
	generate_godot_metadata(animation_data, output_path)
	generate_web_metadata(animation_data, output_path)
	generate_css_sprites(animation_data, output_path)
	generate_xml_metadata(animation_data, output_path)
	
	print("✅ Metadata generada en todos los formatos")

# Funciones de configuración
func get_supported_formats() -> Array:
	"""Obtener lista de formatos soportados"""
	return [
		"json",      # JSON básico
		"unity",     # Unity .meta
		"web",       # Web atlas (Phaser/PixiJS)
		"css",       # CSS sprites
		"xml",       # XML atlas (Starling)
		"godot"      # Godot SpriteFrames
	]

func generate_format(format: String, animation_data: Dictionary, output_path: String) -> bool:
	"""Generar un formato específico"""
	match format:
		"unity":
			generate_unity_metadata(animation_data, output_path)
		"web":
			generate_web_metadata(animation_data, output_path)
		"css":
			generate_css_sprites(animation_data, output_path)
		"xml":
			generate_xml_metadata(animation_data, output_path)
		"godot":
			generate_godot_metadata(animation_data, output_path)
		_:
			push_error("❌ Formato no soportado: %s" % format)
			return false
	
	return true

func get_format_info() -> Dictionary:
	"""Obtener información sobre los formatos soportados"""
	return {
		"json": {
			"name": "JSON Básico",
			"description": "Metadata básica en formato JSON",
			"extension": ".json"
		},
		"unity": {
			"name": "Unity Meta",
			"description": "Archivo .meta para Unity",
			"extension": ".meta"
		},
		"web": {
			"name": "Web Atlas",
			"description": "Atlas JSON para Phaser/PixiJS",
			"extension": "_atlas.json"
		},
		"css": {
			"name": "CSS Sprites",
			"description": "Hoja de estilos CSS para sprites web",
			"extension": "_sprites.css"
		},
		"xml": {
			"name": "XML Atlas",
			"description": "Atlas XML para Starling y otros",
			"extension": "_atlas.xml"
		},
		"godot": {
			"name": "Godot Metadata",
			"description": "Metadata optimizada para Godot",
			"extension": "_godot.json"
		}
	}

# Funciones de debug y prueba
func test_metadata_generation():
	"""Función de prueba para verificar que el generador funciona"""
	print("🧪 Probando generación de metadata...")
	
	# Datos de prueba
	var test_data = {
		"animation_name": "test_animation",
		"sprite_size": {"width": 64, "height": 64},
		"fps": 12,
		"total_frames": 8,
		"spritesheet_size": {"width": 256, "height": 128},
		"directions": [
			{
				"index": 0,
				"frame_count": 4,
				"frames": [
					{"index": 0, "x": 0, "y": 0, "width": 64, "height": 64},
					{"index": 1, "x": 64, "y": 0, "width": 64, "height": 64},
					{"index": 2, "x": 128, "y": 0, "width": 64, "height": 64},
					{"index": 3, "x": 192, "y": 0, "width": 64, "height": 64}
				]
			},
			{
				"index": 1,
				"frame_count": 4,
				"frames": [
					{"index": 0, "x": 0, "y": 64, "width": 64, "height": 64},
					{"index": 1, "x": 64, "y": 64, "width": 64, "height": 64},
					{"index": 2, "x": 128, "y": 64, "width": 64, "height": 64},
					{"index": 3, "x": 192, "y": 64, "width": 64, "height": 64}
				]
			}
		]
	}
	
	var test_path = "res://temp/test_metadata"
	
	# Crear directorio temporal
	if not DirAccess.dir_exists_absolute("res://temp/"):
		DirAccess.make_dir_recursive_absolute("res://temp/")
	
	# Generar todos los formatos
	generate_all_metadata_formats(test_data, test_path)
	
	print("✅ Prueba de metadata completada")
	print("📁 Archivos generados en: res://temp/")

func validate_animation_data(animation_data: Dictionary) -> bool:
	"""Validar que los datos de animación tienen la estructura correcta"""
	if not animation_data.has("animation_name"):
		push_error("❌ Falta animation_name")
		return false
	
	if not animation_data.has("directions") or not animation_data.directions is Array:
		push_error("❌ Falta directions o no es Array")
		return false
	
	if animation_data.directions.is_empty():
		push_error("❌ No hay direcciones en los datos")
		return false
	
	for direction_data in animation_data.directions:
		if not direction_data.has("frames") or not direction_data.frames is Array:
			push_error("❌ Dirección sin frames válidos")
			return false
	
	print("✅ Datos de animación válidos")
	return true

func get_generation_stats() -> Dictionary:
	"""Obtener estadísticas del generador"""
	return {
		"supported_formats": get_supported_formats().size(),
		"formats": get_supported_formats(),
		"status": "ready"
	}


# Generar archivo CSS para sprites web

# Generar archivo CSS para sprites web
# Generar archivo CSS para sprites web
func generate_css_sprites(animation_data: Dictionary, output_path: String) -> void:
	print("🎨 Generando CSS sprites...")
	
	var animation_name = animation_data.get("animation_name", "sprite")
	var sprite_width = animation_data.get("sprite_size", {}).get("width", 64)
	var sprite_height = animation_data.get("sprite_size", {}).get("height", 64)
	
	# Crear contenido CSS base
	var css_content = "/* Spritesheet CSS para " + animation_name + " */\n"
	css_content += ".sprite-" + animation_name + " {\n"
	css_content += "    background-image: url('" + animation_name + "_spritesheet.png');\n"
	css_content += "    background-repeat: no-repeat;\n"
	css_content += "    display: inline-block;\n"
	css_content += "    width: " + str(sprite_width) + "px;\n"
	css_content += "    height: " + str(sprite_height) + "px;\n"
	css_content += "}\n\n"
	
	# Generar clases para cada sprite
	for direction_data in animation_data.get("directions", []):
		var dir_idx = direction_data.get("index", 0)
		for frame_data in direction_data.get("frames", []):
			var frame_idx = frame_data.get("index", 0)
			
			# Crear nombres con formato manual - versión optimizada
			var dir_str = str(dir_idx)
			var frame_str = str(frame_idx)
			
			# Rellenar con ceros según sea necesario
			if dir_idx < 10:
				dir_str = "0" + dir_str
			
			match frame_str.length():
				1:
					frame_str = "00" + frame_str
				2:
					frame_str = "0" + frame_str
			
			# Construir class_name
			var cls_name = animation_name
			cls_name = cls_name + "-dir" + dir_str + "-frame" + frame_str
			
			# Construir la línea CSS
			var css_line = ".sprite-" + cls_name
			css_line = css_line + " { background-position: -" + str(frame_data.get("x", 0))
			css_line = css_line + "px -" + str(frame_data.get("y", 0)) + "px; }\n"
			
			css_content = css_content + css_line
	
	# Generar animaciones CSS
	css_content = css_content + "\n/* Animaciones CSS */\n"
	for direction_data in animation_data.get("directions", []):
		var dir_idx = direction_data.get("index", 0)
		var dir_str = str(dir_idx)
		if dir_idx < 10:
			dir_str = "0" + dir_str
			
		var anim_name = animation_name
		anim_name = anim_name + "-dir" + dir_str
		
		var frame_count = direction_data.get("frame_count", 1)
		var fps = animation_data.get("fps", 12)
		var total_width = sprite_width * frame_count
		var duration = float(frame_count) / float(fps)
		
		# Crear keyframes
		css_content = css_content + "\n@keyframes " + anim_name + " {\n"
		css_content = css_content + "    0% { background-position-x: 0px; }\n"
		css_content = css_content + "    100% { background-position-x: -" + str(total_width) + "px; }\n"
		css_content = css_content + "}\n"
		
		# Crear clase de animación
		css_content = css_content + "\n.animate-" + anim_name + " {\n"
		css_content = css_content + "    animation: " + anim_name
		css_content = css_content + " " + str(duration)
		css_content = css_content + "s steps(" + str(frame_count) + ") infinite;\n"
		css_content = css_content + "}\n"
	
	var file = FileAccess.open(output_path + "_sprites.css", FileAccess.WRITE)
	if file:
		file.store_string(css_content)
		file.close()
		print("✅ CSS sprites generado: %s_sprites.css" % output_path)
	else:
		push_error("❌ Error generando CSS sprites")
