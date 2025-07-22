# scripts/export/metadata_generator.gd
extends Node

# Input: Datos del spritesheet y configuración de exportación
# Output: Archivos de metadata en varios formatos para diferentes engines

# Generar metadata para Unity
func generate_unity_metadata(animation_data: Dictionary, output_path: String) -> void:
	var meta_content = """fileFormatVersion: 2
guid: %s
TextureImporter:
  internalIDToNameTable: []
  externalObjects: {}
  serializedVersion: 11
  mipmaps:
	mipMapMode: 0
	enableMipMap: 0
	sRGBTexture: 1
	linearTexture: 0
	fadeOut: 0
	borderMipMap: 0
	mipMapsPreserveCoverage: 0
	alphaTestReferenceValue: 0.5
	mipMapFadeDistanceStart: 1
	mipMapFadeDistanceEnd: 3
  bumpmap:
	convertToNormalMap: 0
	externalNormalMap: 0
	heightScale: 0.25
	normalMapFilter: 0
  isReadable: 0
  streamingMipmaps: 0
  streamingMipmapsPriority: 0
  vTOnly: 0
  grayScaleToAlpha: 0
  generateCubemap: 6
  cubemapConvolution: 0
  seamlessCubemap: 0
  textureFormat: 1
  maxTextureSize: 2048
  textureSettings:
	serializedVersion: 2
	filterMode: 0
	aniso: -1
	mipBias: -100
	wrapU: 1
	wrapV: 1
	wrapW: 1
  nPOTScale: 0
  lightmap: 0
  compressionQuality: 50
  spriteMode: 2
  spriteExtrude: 1
  spriteMeshType: 1
  alignment: 0
  spritePivot: {x: 0.5, y: 0.5}
  spritePixelsToUnits: %d
  spriteBorder: {x: 0, y: 0, z: 0, w: 0}
  spriteGenerateFallbackPhysicsShape: 1
  alphaUsage: 1
  alphaIsTransparency: 1
  spriteTessellationDetail: -1
  textureType: 8
  textureShape: 1
  singleChannelComponent: 0
  flipbookRows: 1
  flipbookColumns: 1
  maxTextureSizeSet: 0
  compressionQualitySet: 0
  textureFormatSet: 0
  ignorePngGamma: 0
  applyGammaDecoding: 0
  platformSettings:
  - serializedVersion: 3
	buildTarget: DefaultTexturePlatform
	maxTextureSize: 2048
	resizeAlgorithm: 0
	textureFormat: -1
	textureCompression: 0
	compressionQuality: 50
	crunchedCompression: 0
	allowsAlphaSplitting: 0
	overridden: 0
	androidETC2FallbackOverride: 0
	forceMaximumCompressionQuality_BC6H_BC7: 0
  spriteSheet:
	serializedVersion: 2
	sprites: %s
	outline: []
	physicsShape: []
	bones: []
	spriteID: 5e97eb03825dee720800000000000000
	internalID: 0
	vertices: []
	indices: 
	edges: []
	weights: []
	secondaryTextures: []
  spritePackingTag: 
  pSDRemoveMatte: 0
  pSDShowRemoveMatteOption: 0
  userData: 
  assetBundleName: 
  assetBundleVariant: 
"""
	
	var guid = _generate_guid()
	var sprites_data = _generate_unity_sprites_array(animation_data)
	var pixels_per_unit = animation_data.sprite_size.width / 2 # Ajustable
	
	var final_content = meta_content % [guid, pixels_per_unit, sprites_data]
	
	var file = FileAccess.open(output_path + ".meta", FileAccess.WRITE)
	if file:
		file.store_string(final_content)
		file.close()

func _generate_unity_sprites_array(animation_data: Dictionary) -> String:
	var sprites = []
	var sprite_index = 0
	
	for direction_data in animation_data.directions:
		for frame_data in direction_data.frames:
			var sprite_entry = """
	- serializedVersion: 2
	  name: %s_dir%d_frame%d
	  rect:
		serializedVersion: 2
		x: %d
		y: %d
		width: %d
		height: %d
	  alignment: 0
	  pivot: {x: 0.5, y: 0.5}
	  border: {x: 0, y: 0, z: 0, w: 0}
	  outline: []
	  physicsShape: []
	  tessellationDetail: 0
	  bones: []
	  spriteID: %s
	  internalID: %d
	  vertices: []
	  indices: 
	  edges: []
	  weights: []""" % [
				animation_data.name,
				direction_data.index,
				frame_data.index,
				frame_data.position.x,
				frame_data.position.y,
				animation_data.sprite_size.width,
				animation_data.sprite_size.height,
				_generate_sprite_id(),
				sprite_index
			]
			
			sprites.append(sprite_entry)
			sprite_index += 1
	
	return "\n".join(sprites)

# Generar metadata para motores web (Phaser, PixiJS)
func generate_web_metadata(animation_data: Dictionary, output_path: String) -> void:
	var atlas = {
		"frames": {},
		"meta": {
			"app": "Pixelize3D FBX",
			"version": "1.0",
			"image": animation_data.name + "_spritesheet.png",
			"format": "RGBA8888",
			"size": {
				"w": animation_data.spritesheet_size.width,
				"h": animation_data.spritesheet_size.height
			},
			"scale": "1"
		},
		"animations": {}
	}
	
	# Generar frames
	for direction_data in animation_data.directions:
		var anim_frames = []
		
		for frame_data in direction_data.frames:
			var frame_name = "%s_dir%02d_%03d" % [
				animation_data.name,
				direction_data.index,
				frame_data.index
			]
			
			atlas.frames[frame_name] = {
				"frame": {
					"x": frame_data.position.x,
					"y": frame_data.position.y,
					"w": animation_data.sprite_size.width,
					"h": animation_data.sprite_size.height
				},
				"rotated": false,
				"trimmed": false,
				"spriteSourceSize": {
					"x": 0,
					"y": 0,
					"w": animation_data.sprite_size.width,
					"h": animation_data.sprite_size.height
				},
				"sourceSize": {
					"w": animation_data.sprite_size.width,
					"h": animation_data.sprite_size.height
				}
			}
			
			anim_frames.append(frame_name)
		
		# Añadir animación por dirección
		var anim_name = "%s_dir%02d" % [animation_data.name, direction_data.index]
		atlas.animations[anim_name] = anim_frames
	
	# Guardar como JSON
	var file = FileAccess.open(output_path + "_atlas.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(atlas, "\t"))
		file.close()

# Generar archivo CSS para sprites web
func generate_css_sprites(animation_data: Dictionary, output_path: String) -> void:
	var css_content = """/* Spritesheet CSS para %s */
.sprite-%s {
	background-image: url('%s_spritesheet.png');
	background-repeat: no-repeat;
	display: inline-block;
	width: %dpx;
	height: %dpx;
}

""" % [
		animation_data.name,
		animation_data.name,
		animation_data.name,
		animation_data.sprite_size.width,
		animation_data.sprite_size.height
	]
	
	# Generar clases para cada sprite
	for direction_data in animation_data.directions:
		for frame_data in direction_data.frames:
			var class_name = "%s-dir%02d-frame%03d" % [
				animation_data.name,
				direction_data.index,
				frame_data.index
			]
			
			css_content += ".sprite-%s { background-position: -%dpx -%dpx; }\n" % [
				class_name,
				frame_data.position.x,
				frame_data.position.y
			]
	
	# Animaciones CSS
	css_content += "\n/* Animaciones */\n"
	for direction_data in animation_data.directions:
		var anim_name = "%s-dir%02d" % [animation_data.name, direction_data.index]
		var frame_count = direction_data.frame_count
		
		css_content += """
@keyframes %s {
	to { background-position-x: -%dpx; }
}

.animate-%s {
	animation: %s %fs steps(%d) infinite;
}
""" % [
			anim_name,
			animation_data.sprite_size.width * frame_count,
			anim_name,
			anim_name,
			float(frame_count) / float(animation_data.fps),
			frame_count
		]
	
	var file = FileAccess.open(output_path + "_sprites.css", FileAccess.WRITE)
	if file:
		file.store_string(css_content)
		file.close()

# Generar XML para frameworks como Starling
func generate_xml_metadata(animation_data: Dictionary, output_path: String) -> void:
	var xml_content = '<?xml version="1.0" encoding="UTF-8"?>\n'
	xml_content += '<TextureAtlas imagePath="%s_spritesheet.png">\n' % animation_data.name
	
	for direction_data in animation_data.directions:
		for frame_data in direction_data.frames:
			var subtexture_name = "%s_dir%02d_frame%03d" % [
				animation_data.name,
				direction_data.index,
				frame_data.index
			]
			
			xml_content += '\t<SubTexture name="%s" x="%d" y="%d" width="%d" height="%d"/>\n' % [
				subtexture_name,
				frame_data.position.x,
				frame_data.position.y,
				animation_data.sprite_size.width,
				animation_data.sprite_size.height
			]
	
	xml_content += '</TextureAtlas>'
	
	var file = FileAccess.open(output_path + "_atlas.xml", FileAccess.WRITE)
	if file:
		file.store_string(xml_content)
		file.close()

# Funciones auxiliares
func _generate_guid() -> String:
	# Generar un GUID simple para Unity
	var chars = "0123456789abcdef"
	var guid = ""
	
	for i in range(32):
		guid += chars[randi() % chars.length()]
		if i in [7, 11, 15, 19]:
			guid += "-"
	
	return guid

func _generate_sprite_id() -> String:
	# Generar ID único para sprites
	var id = ""
	for i in range(16):
		id += str(randi() % 10)
	return id

# Función principal para generar todos los formatos
func generate_all_metadata_formats(animation_data: Dictionary, output_path: String) -> void:
	generate_unity_metadata(animation_data, output_path)
	generate_web_metadata(animation_data, output_path)
	generate_css_sprites(animation_data, output_path)
	generate_xml_metadata(animation_data, output_path)
	
	print("Metadata generada en todos los formatos")
