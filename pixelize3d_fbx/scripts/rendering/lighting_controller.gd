# scripts/rendering/lighting_controller.gd
# Script para controlar la iluminación de la escena de preview
# Input: Configuración de iluminación desde settings
# Output: Iluminación optimizada para visualización de modelos 3D

extends DirectionalLight3D

signal lighting_changed()

# Configuración de iluminación
@export var use_three_point_lighting: bool = true
@export var key_light_intensity: float = 1.0
@export var fill_light_intensity: float = 0.5
@export var rim_light_intensity: float = 0.3

# Referencias a luces adicionales (se crean dinámicamente)
var fill_light: DirectionalLight3D
var rim_light: DirectionalLight3D

# Estado de iluminación
var lighting_preset: String = "default"
var is_setup: bool = false

func _ready():
	_setup_main_light()
	if use_three_point_lighting:
		_create_additional_lights()
	_apply_lighting_preset("default")
	print("💡 LightingController inicializado")

# === CONFIGURACIÓN INICIAL ===

func _setup_main_light():
	"""Configurar la luz principal (este nodo DirectionalLight3D)"""
	# Configurar como luz clave (key light)
	name = "KeyLight"
	light_energy = key_light_intensity
	light_color = Color(1.0, 0.95, 0.9)  # Luz cálida
	rotation_degrees = Vector3(-45, -45, 0)
	
	# Configurar sombras
	shadow_enabled = true
	shadow_bias = 0.1
	directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	directional_shadow_max_distance = 50.0
	
	print("💡 Luz principal configurada")

func _create_additional_lights():
	"""Crear luces adicionales para sistema de tres puntos"""
	var parent = get_parent()
	if not parent:
		print("❌ No se puede crear luces adicionales: sin padre")
		return
	
	# Luz de relleno (fill light)
	fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = fill_light_intensity
	fill_light.light_color = Color(0.9, 0.95, 1.0)  # Luz fría
	fill_light.rotation_degrees = Vector3(-30, 135, 0)
	fill_light.shadow_enabled = false
	parent.add_child(fill_light)
	
	# Luz de borde (rim light)
	rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_energy = rim_light_intensity
	rim_light.light_color = Color(1.0, 1.0, 1.0)  # Luz neutra
	rim_light.rotation_degrees = Vector3(45, 180, 0)
	rim_light.shadow_enabled = false
	parent.add_child(rim_light)
	
	print("💡 Sistema de tres puntos creado")
	is_setup = true

# === PRESETS DE ILUMINACIÓN ===

func _apply_lighting_preset(preset_name: String):
	"""Aplicar preset de iluminación predefinido"""
	lighting_preset = preset_name
	
	match preset_name:
		"default":
			_set_lighting_config(1.0, 0.5, 0.3, Color(1.0, 0.95, 0.9))
		"bright":
			_set_lighting_config(1.5, 0.7, 0.4, Color(1.0, 1.0, 1.0))
		"soft":
			_set_lighting_config(0.8, 0.6, 0.2, Color(1.0, 0.95, 0.85))
		"dramatic":
			_set_lighting_config(1.2, 0.3, 0.5, Color(1.0, 0.9, 0.8))
		"studio":
			_set_lighting_config(1.1, 0.8, 0.6, Color(0.95, 0.98, 1.0))
		_:
			print("❌ Preset desconocido: %s" % preset_name)
			return
	
	print("💡 Preset aplicado: %s" % preset_name)
	emit_signal("lighting_changed")

func _set_lighting_config(key_energy: float, fill_energy: float, rim_energy: float, key_color: Color):
	"""Configurar energías y colores de las luces"""
	# Luz principal (este nodo)
	light_energy = key_energy
	light_color = key_color
	
	# Luces adicionales
	if fill_light:
		fill_light.light_energy = fill_energy
	if rim_light:
		rim_light.light_energy = rim_energy

# === FUNCIONES PÚBLICAS ===

func set_lighting_preset(preset_name: String):
	"""Cambiar preset de iluminación"""
	_apply_lighting_preset(preset_name)

func set_key_light_intensity(intensity: float):
	"""Ajustar intensidad de luz principal"""
	key_light_intensity = clamp(intensity, 0.0, 3.0)
	light_energy = key_light_intensity
	print("💡 Intensidad luz principal: %.2f" % intensity)
	emit_signal("lighting_changed")

func set_fill_light_intensity(intensity: float):
	"""Ajustar intensidad de luz de relleno"""
	fill_light_intensity = clamp(intensity, 0.0, 2.0)
	if fill_light:
		fill_light.light_energy = fill_light_intensity
	print("💡 Intensidad luz relleno: %.2f" % intensity)
	emit_signal("lighting_changed")

func set_rim_light_intensity(intensity: float):
	"""Ajustar intensidad de luz de borde"""
	rim_light_intensity = clamp(intensity, 0.0, 1.0)
	if rim_light:
		rim_light.light_energy = rim_light_intensity
	print("💡 Intensidad luz borde: %.2f" % intensity)
	emit_signal("lighting_changed")

func toggle_shadows(enabled: bool):
	"""Activar/desactivar sombras"""
	shadow_enabled = enabled
	print("💡 Sombras: %s" % ("ACTIVADAS" if enabled else "DESACTIVADAS"))
	emit_signal("lighting_changed")

func set_key_light_angle(elevation: float, azimuth: float):
	"""Ajustar ángulo de la luz principal"""
	rotation_degrees = Vector3(elevation, azimuth, 0)
	print("💡 Ángulo luz principal: Elevación=%.1f°, Azimut=%.1f°" % [elevation, azimuth])
	emit_signal("lighting_changed")

# === CONFIGURACIÓN DESDE DICCIONARIO ===

func apply_lighting_settings(settings: Dictionary):
	"""Aplicar configuración de iluminación desde diccionario"""
	print("--- APLICANDO CONFIGURACIÓN DE ILUMINACIÓN ---")
	
	if settings.has("preset"):
		set_lighting_preset(settings.preset)
	
	if settings.has("key_intensity"):
		set_key_light_intensity(settings.key_intensity)
	
	if settings.has("fill_intensity"):
		set_fill_light_intensity(settings.fill_intensity)
	
	if settings.has("rim_intensity"):
		set_rim_light_intensity(settings.rim_intensity)
	
	if settings.has("shadows_enabled"):
		toggle_shadows(settings.shadows_enabled)
	
	if settings.has("key_elevation") and settings.has("key_azimuth"):
		set_key_light_angle(settings.key_elevation, settings.key_azimuth)
	
	print("✅ Configuración de iluminación aplicada")

# === FUNCIONES DE UTILIDAD ===

func get_lighting_info() -> Dictionary:
	"""Obtener información completa del estado de iluminación"""
	return {
		"preset": lighting_preset,
		"key_intensity": light_energy,
		"fill_intensity": fill_light.light_energy if fill_light else 0.0,
		"rim_intensity": rim_light.light_energy if rim_light else 0.0,
		"shadows_enabled": shadow_enabled,
		"key_color": light_color,
		"key_rotation": rotation_degrees,
		"three_point_setup": is_setup
	}

func reset_lighting():
	"""Resetear iluminación a valores por defecto"""
	_apply_lighting_preset("default")
	rotation_degrees = Vector3(-45, -45, 0)
	shadow_enabled = true
	print("🔄 Iluminación reseteada")

func optimize_for_model_type(model_type: String):
	"""Optimizar iluminación según tipo de modelo"""
	match model_type:
		"character":
			_apply_lighting_preset("studio")
		"building":
			_apply_lighting_preset("bright")
		"vehicle":
			_apply_lighting_preset("dramatic")
		"nature":
			_apply_lighting_preset("soft")
		_:
			_apply_lighting_preset("default")
	
	print("💡 Iluminación optimizada para: %s" % model_type)

# === DEBUGGING ===

func debug_lighting_state():
	"""Imprimir estado de iluminación para debugging"""
	print("\n=== LIGHTING CONTROLLER DEBUG ===")
	var info = get_lighting_info()
	for key in info:
		print("  %s: %s" % [key, str(info[key])])
	print("==================================\n")

# === PRESETS DISPONIBLES ===

func get_available_presets() -> Array:
	"""Obtener lista de presets disponibles"""
	return ["default", "bright", "soft", "dramatic", "studio"]

func get_preset_description(preset_name: String) -> String:
	"""Obtener descripción de un preset"""
	var descriptions = {
		"default": "Iluminación equilibrada para uso general",
		"bright": "Iluminación intensa para modelos detallados",
		"soft": "Iluminación suave para ambientes cálidos",
		"dramatic": "Iluminación contrastada para efectos dramáticos",
		"studio": "Iluminación profesional para presentaciones"
	}
	
	return descriptions.get(preset_name, "Preset desconocido")
