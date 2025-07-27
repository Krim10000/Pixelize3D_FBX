# scripts/core/animation_name_fix.gd
# Corrección CRÍTICA para nombres de animaciones
# Input: AnimationPlayer con animaciones mal nombradas
# Output: AnimationPlayer con nombres correctos basados en archivos FBX

extends Node

# Función para corregir nombres de animaciones en AnimationPlayer
static func fix_animation_names(anim_player: AnimationPlayer, correct_name: String) -> bool:
	"""Renombrar animación 'mixamo_com' al nombre correcto del archivo FBX"""
	
	if not anim_player:
		print("❌ AnimationPlayer inválido")
		return false
	
	var anim_library = anim_player.get_animation_library("")
	if not anim_library:
		print("❌ No se encontró library de animaciones")
		return false
	
	# Buscar animación con nombre genérico
	var generic_names = ["mixamo_com", "default", "Animation"]
	var found_generic = ""
	
	for generic_name in generic_names:
		if anim_library.has_animation(generic_name):
			found_generic = generic_name
			break
	
	if found_generic == "":
		print("⚠️ No se encontró animación genérica para renombrar")
		return false
	
	# Verificar que el nombre correcto no exista ya
	if anim_library.has_animation(correct_name):
		print("⚠️ Animación '%s' ya existe, no se necesita renombrar" % correct_name)
		return true
	
	# Obtener la animación
	var animation = anim_library.get_animation(found_generic)
	if not animation:
		print("❌ No se pudo obtener animación '%s'" % found_generic)
		return false
	
	# Crear copia con el nombre correcto
	var animation_copy = animation.duplicate()
	
	# Agregar con el nombre correcto
	anim_library.add_animation(correct_name, animation_copy)
	
	# Remover la animación con nombre genérico
	anim_library.remove_animation(found_generic)
	
	print("✅ Animación renombrada: '%s' -> '%s'" % [found_generic, correct_name])
	return true

# Función para procesar modelo cargado y corregir nombres
static func process_loaded_model(model_data: Dictionary) -> Dictionary:
	"""Procesar modelo recién cargado para corregir nombres de animaciones"""
	
	if not model_data.has("animation_player") or not model_data.has("name"):
		return model_data
	
	var anim_player = model_data.animation_player
	var correct_name = model_data.name
	
	print("🔧 Procesando animaciones para: %s" % correct_name)
	
	# Corregir nombres de animaciones
	var success = fix_animation_names(anim_player, correct_name)
	
	if success:
		print("✅ Nombres corregidos para: %s" % correct_name)
	
	return model_data

# Función para debug de animaciones
static func debug_animation_names(anim_player: AnimationPlayer, context: String = ""):
	"""Debug de nombres de animaciones"""
	
	if not anim_player:
		print("❌ AnimationPlayer nulo para debug")
		return
	
	var prefix = "🔍 DEBUG ANIMS"
	if context != "":
		prefix += " (%s)" % context
	
	print("%s:" % prefix)
	print("  AnimationPlayer: %s" % anim_player.name)
	
	var animation_list = anim_player.get_animation_list()
	print("  Total animaciones: %d" % animation_list.size())
	
	for i in range(animation_list.size()):
		var anim_name = animation_list[i]
		var anim = anim_player.get_animation(anim_name)
		print("  [%d] '%s' - %.2fs" % [i, anim_name, anim.length if anim else 0.0])

# Función para validar que las animaciones tengan nombres únicos
static func validate_unique_names(anim_player: AnimationPlayer) -> Dictionary:
	"""Validar que todas las animaciones tengan nombres únicos y descriptivos"""
	
	var result = {
		"valid": true,
		"problems": [],
		"suggestions": []
	}
	
	if not anim_player:
		result.valid = false
		result.problems.append("AnimationPlayer nulo")
		return result
	
	var animation_list = anim_player.get_animation_list()
	var generic_names = ["mixamo_com", "default", "Animation", "Take 001"]
	
	for anim_name in animation_list:
		# Verificar nombres genéricos
		if anim_name in generic_names:
			result.valid = false
			result.problems.append("Nombre genérico encontrado: '%s'" % anim_name)
			result.suggestions.append("Renombrar '%s' a un nombre descriptivo" % anim_name)
		
		# Verificar nombres vacíos o muy cortos
		if anim_name.length() < 3:
			result.valid = false
			result.problems.append("Nombre muy corto: '%s'" % anim_name)
			result.suggestions.append("Usar nombre más descriptivo que '%s'" % anim_name)
	
	return result
