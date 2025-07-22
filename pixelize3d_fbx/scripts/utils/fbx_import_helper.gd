# scripts/utils/fbx_import_helper.gd
extends RefCounted
class_name FBXImportHelper

# Input: Archivos FBX en el proyecto de Godot
# Output: Validación y sugerencias de importación

# Estructura recomendada para archivos FBX
static func get_recommended_structure() -> String:
	return """Estructura Recomendada:

res://assets/fbx/
├── soldier/                 # Carpeta por unidad
│   ├── soldier_base.fbx    # Modelo con meshes + skeleton
│   ├── soldier_idle.fbx    # Solo animaciones
│   ├── soldier_walk.fbx    # Solo animaciones
│   └── soldier_attack.fbx  # Solo animaciones
└── archer/
	├── archer_base.fbx
	└── archer_shoot.fbx

IMPORTANTE:
- Archivo base: Contiene meshes y skeleton
- Archivos animación: Solo skeleton con animaciones
- Nombres de huesos deben coincidir exactamente
- Usar nombres descriptivos para las carpetas"""

# Validar estructura de carpetas
static func validate_folder_structure(folder_path: String) -> Dictionary:
	var result = {
		"is_valid": true,
		"warnings": [],
		"errors": [],
		"suggestions": [],
		"files": {
			"base_candidates": [],
			"animation_files": [],
			"all_fbx": []
		}
	}
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		result.is_valid = false
		result.errors.append("No se pudo acceder a la carpeta: " + folder_path)
		return result
	
	# Escanear archivos FBX
	
	
	# Escanear archivos FBX en carpeta y subcarpetas
# Escanear archivos FBX en carpeta y subcarpetas
	var all_fbx_files := _scan_fbx_files_recursive(folder_path)

	for full_path in all_fbx_files:
		var file_name: String = full_path.get_file()

		result.files.all_fbx.append(full_path)

		var lower_name = file_name.to_lower()
		if "base" in lower_name or "mesh" in lower_name:
			result.files.base_candidates.append(full_path)
		else:
			result.files.animation_files.append(full_path)

	
	
	# Validar contenido
	if result.files.all_fbx.is_empty():
		result.is_valid = false
		result.errors.append("No se encontraron archivos FBX en la carpeta")
		return result
	
	# Verificar modelo base
	if result.files.base_candidates.is_empty():
		result.warnings.append("No se detectó archivo base obvio")
		result.suggestions.append("Considera renombrar el modelo principal a '*_base.fbx'")
	elif result.files.base_candidates.size() > 1:
		result.warnings.append("Múltiples candidatos a archivo base encontrados")
		result.suggestions.append("Solo debería haber un archivo base por unidad")
	
	# Verificar animaciones
	if result.files.animation_files.is_empty() and result.files.all_fbx.size() == 1:
		result.warnings.append("Solo se encontró un archivo FBX")
		result.suggestions.append("¿Tienes archivos de animación separados?")
	
	return result

# Validar un archivo FBX específico
static func validate_fbx_file(fbx_path: String, expected_type: String = "auto") -> Dictionary:
	var result = {
		"is_valid": true,
		"file_path": fbx_path,
		"type": "unknown",
		"warnings": [],
		"errors": [],
		"info": {
			"has_skeleton": false,
			"has_meshes": false,
			"has_animations": false,
			"bone_count": 0,
			"mesh_count": 0,
			"animation_count": 0,
			"bone_names": []
		}
	}
	
	# Verificar que el archivo existe y está importado
	var resource = load(fbx_path)
	if not resource:
		result.is_valid = false
		result.errors.append("Archivo no encontrado o no importado")
		return result
	
	if not resource is PackedScene:
		result.is_valid = false
		result.errors.append("El archivo no es una PackedScene válida")
		return result
	
	# Instanciar y analizar
	var instance = resource.instantiate()
	if not instance:
		result.is_valid = false
		result.errors.append("No se pudo instanciar la escena")
		return result
	
	# Buscar componentes
	_analyze_fbx_node(instance, result)
	
	# Determinar tipo de archivo
	if result.info.has_meshes and result.info.has_skeleton:
		result.type = "base"
	elif result.info.has_skeleton and result.info.has_animations:
		result.type = "animation"
	elif result.info.has_skeleton:
		result.type = "skeleton_only"
	else:
		result.type = "unknown"
		result.warnings.append("No se pudo determinar el tipo de archivo")
	
	# Validaciones específicas por tipo
	if expected_type == "base" or result.type == "base":
		if not result.info.has_meshes:
			result.errors.append("Archivo base debe contener meshes")
			result.is_valid = false
		
		if result.info.mesh_count == 0:
			result.warnings.append("No se encontraron meshes válidos")
	
	if expected_type == "animation" or result.type == "animation":
		if not result.info.has_animations:
			result.warnings.append("Archivo de animación sin animaciones detectadas")
		
		if result.info.has_meshes:
			result.warnings.append("Archivo de animación contiene meshes (innecesario)")
	
	instance.queue_free()
	return result

# Analizar recursivamente los nodos del FBX
static func _analyze_fbx_node(node: Node, result: Dictionary):
	if node is Skeleton3D:
		result.info.has_skeleton = true
		result.info.bone_count = node.get_bone_count()
		
		# Extraer nombres de huesos
		for i in range(node.get_bone_count()):
			result.info.bone_names.append(node.get_bone_name(i))
		
		# Buscar meshes dentro del skeleton
		for child in node.get_children():
			if child is MeshInstance3D and child.mesh:
				result.info.has_meshes = true
				result.info.mesh_count += 1
	
	elif node is AnimationPlayer:
		result.info.has_animations = true
		result.info.animation_count = node.get_animation_list().size()
	
	elif node is MeshInstance3D and node.mesh:
		result.info.has_meshes = true
		result.info.mesh_count += 1
	
	# Recursión
	for child in node.get_children():
		_analyze_fbx_node(child, result)

# Comparar compatibilidad de huesos entre archivos
static func compare_bone_compatibility(base_bones: Array, anim_bones: Array) -> Dictionary:
	var result = {
		"compatible": true,
		"missing_in_animation": [],
		"missing_in_base": [],
		"bone_count_match": false
	}
	
	result.bone_count_match = base_bones.size() == anim_bones.size()
	
	# Buscar huesos faltantes
	for bone in base_bones:
		if not bone in anim_bones:
			result.missing_in_animation.append(bone)
			result.compatible = false
	
	for bone in anim_bones:
		if not bone in base_bones:
			result.missing_in_base.append(bone)
	
	return result

# Generar reporte completo de una unidad
static func generate_unit_report(unit_folder: String) -> Dictionary:
	var report = {
		"unit_name": unit_folder.get_file(),
		"folder_path": unit_folder,
		"timestamp": Time.get_datetime_string_from_system(),
		"overall_status": "unknown",
		"folder_validation": {},
		"files": {},
		"compatibility": {},
		"recommendations": []
	}
	
	# Validar estructura de carpeta
	report.folder_validation = validate_folder_structure(unit_folder)
	
	# Validar cada archivo FBX
	for fbx_file in report.folder_validation.files.all_fbx:
		var fbx_path = unit_folder.path_join(fbx_file)
		report.files[fbx_file] = validate_fbx_file(fbx_path)
	
	# Análisis de compatibilidad
	var base_files = report.folder_validation.files.base_candidates
	if base_files.size() > 0:
		var base_file = base_files[0]
		var base_validation = report.files[base_file]
		
		for anim_file in report.folder_validation.files.animation_files:
			if anim_file in report.files:
				var anim_validation = report.files[anim_file]
				var compatibility = compare_bone_compatibility(
					base_validation.info.bone_names,
					anim_validation.info.bone_names
				)
				report.compatibility[anim_file] = compatibility
	
	# Determinar estado general
	var has_errors = false
	for file_name in report.files:
		if not report.files[file_name].is_valid:
			has_errors = true
			break
	
	if has_errors:
		report.overall_status = "error"
	elif report.folder_validation.warnings.size() > 0:
		report.overall_status = "warning"
	else:
		report.overall_status = "ok"
	
	# Generar recomendaciones
	report.recommendations = _generate_recommendations(report)
	
	return report

# Generar recomendaciones basadas en el reporte
static func _generate_recommendations(report: Dictionary) -> Array:
	var recommendations = []
	
	# Recomendaciones por estructura de carpeta
	recommendations.append_array(report.folder_validation.suggestions)
	
	# Recomendaciones por archivos
	for file_name in report.files:
		var file_validation = report.files[file_name]
		
		if not file_validation.is_valid:
			recommendations.append("Revisar archivo: " + file_name + " - " + 
				(file_validation.errors[0] if file_validation.errors.size() > 0 else "Error desconocido"))
		
		for warning in file_validation.warnings:
			recommendations.append("Archivo " + file_name + ": " + warning)
	
	# Recomendaciones por compatibilidad
	for anim_file in report.compatibility:
		var compat = report.compatibility[anim_file]
		if not compat.compatible:
			recommendations.append("Incompatibilidad de huesos en: " + anim_file)
			
			for missing_bone in compat.missing_in_animation:
				recommendations.append("  - Hueso faltante: " + missing_bone)
	
	return recommendations

# Generar archivo de reporte en formato texto
static func save_report_to_file(report: Dictionary, output_path: String):
	var content = "REPORTE DE VALIDACIÓN FBX\n"
	content += "=".repeat(50) + "\n\n"
	
	content += "Unidad: " + report.unit_name + "\n"
	content += "Fecha: " + report.timestamp + "\n"
	content += "Estado: " + report.overall_status.to_upper() + "\n\n"
	
	# Archivos encontrados
	content += "ARCHIVOS FBX ENCONTRADOS:\n"
	content += "-".repeat(30) + "\n"
	for file_name in report.files:
		var file_info = report.files[file_name]
		var status = "✓" if file_info.is_valid else "✗"
		content += "%s %s (%s)\n" % [status, file_name, file_info.type]
		
		if file_info.info.bone_count > 0:
			content += "  Huesos: %d\n" % file_info.info.bone_count
		if file_info.info.mesh_count > 0:
			content += "  Meshes: %d\n" % file_info.info.mesh_count
		if file_info.info.animation_count > 0:
			content += "  Animaciones: %d\n" % file_info.info.animation_count
	
	# Recomendaciones
	if report.recommendations.size() > 0:
		content += "\nRECOMENDACIONES:\n"
		content += "-".repeat(30) + "\n"
		for i in range(report.recommendations.size()):
			content += "%d. %s\n" % [i + 1, report.recommendations[i]]
	
	# Guardar archivo
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

# Función de utilidad para crear estructura de ejemplo
static func create_example_structure(base_path: String):
	var example_units = ["soldier", "archer", "mage"]
	
	for unit in example_units:
		var unit_path = base_path.path_join(unit)
		DirAccess.make_dir_recursive_absolute(unit_path)
		
		# Crear archivos README de ejemplo
		var readme_content = "Coloca aquí los archivos FBX para la unidad: " + unit + "\n\n"
		readme_content += "Archivos necesarios:\n"
		readme_content += "- " + unit + "_base.fbx (modelo con meshes)\n"
		readme_content += "- " + unit + "_idle.fbx (animación idle)\n"
		readme_content += "- " + unit + "_walk.fbx (animación caminar)\n"
		readme_content += "- " + unit + "_attack.fbx (animación atacar)\n"
		
		var readme_path = unit_path.path_join("README.txt")
		var file = FileAccess.open(readme_path, FileAccess.WRITE)
		if file:
			file.store_string(readme_content)
			file.close()



static func _scan_fbx_files_recursive(path: String) -> Array:
	var result := []
	var dir = DirAccess.open(path)
	if dir == null:
		return result
	
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		
		var full_path = path.path_join(name)
		if dir.current_is_dir():
			result += _scan_fbx_files_recursive(full_path)
		elif name.to_lower().ends_with(".fbx"):
			result.append(full_path)
		
		name = dir.get_next()
	dir.list_dir_end()
	return result
