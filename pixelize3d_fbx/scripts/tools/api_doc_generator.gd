# scripts/tools/api_doc_generator.gd
extends Node

# Input: Scripts del proyecto
# Output: Documentación API en formato HTML/Markdown

signal documentation_generated(output_path: String)
signal documentation_error(error: String)

const SCRIPT_PATHS = [
	"res://scripts/main.gd",
	"res://scripts/core/",
	"res://scripts/rendering/",
	"res://scripts/export/",
	"res://scripts/ui/",
	"res://scripts/utils/"
]

var documented_classes: Dictionary = {}
var class_hierarchy: Dictionary = {}

func generate_documentation(output_path: String, format: String = "html"):
	print("Generando documentación API...")
	
	# Escanear todos los scripts
	_scan_all_scripts()
	
	# Generar documentación según formato
	match format:
		"html":
			_generate_html_documentation(output_path)
		"markdown":
			_generate_markdown_documentation(output_path)
		"json":
			_generate_json_documentation(output_path)
		_:
			emit_signal("documentation_error", "Formato no soportado: " + format)
			return
	
	emit_signal("documentation_generated", output_path)

func _scan_all_scripts():
	documented_classes.clear()
	class_hierarchy.clear()
	
	for path in SCRIPT_PATHS:
		if path.ends_with("/"):
			_scan_directory(path)
		else:
			_scan_script(path)

func _scan_directory(dir_path: String):
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".gd"):
			_scan_script(dir_path.path_join(file_name))
		elif dir.current_is_dir() and not file_name.begins_with("."):
			_scan_directory(dir_path.path_join(file_name))
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _scan_script(script_path: String):
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return
	
	var class_info = {
		"path": script_path,
		"name": script_path.get_file().get_basename(),
		"extends": "",
		"description": "",
		"signals": [],
		"properties": [],
		"methods": [],
		"constants": [],
		"enums": []
	}
	
	var in_comment_block = false
	var current_comment = []
	var line_number = 0
	
	while not file.eof_reached():
		var line = file.get_line()
		line_number += 1
		
		# Detectar bloques de comentarios
		if line.strip_edges().begins_with("#"):
			current_comment.append(line.strip_edges().substr(1).strip_edges())
		else:
			# Analizar línea de código
			if line.begins_with("extends "):
				class_info.extends = line.split(" ")[1].strip_edges()
			
			elif line.begins_with("class_name "):
				class_info.name = line.split(" ")[1].strip_edges()
			
			elif line.begins_with("signal "):
				var signal_info = _parse_signal(line, current_comment)
				class_info.signals.append(signal_info)
			
			elif line.begins_with("@export") or line.begins_with("var "):
				var property_info = _parse_property(line, current_comment)
				if property_info:
					class_info.properties.append(property_info)
			
			elif line.begins_with("func "):
				var method_info = _parse_method(line, current_comment, file)
				if method_info:
					class_info.methods.append(method_info)
			
			elif line.begins_with("const "):
				var const_info = _parse_constant(line, current_comment)
				class_info.constants.append(const_info)
			
			elif line.begins_with("enum "):
				var enum_info = _parse_enum(line, file)
				class_info.enums.append(enum_info)
			
			# Limpiar comentarios después de usarlos
			if not line.strip_edges().begins_with("#"):
				current_comment.clear()
	
	file.close()
	
	# Extraer descripción de la clase de los primeros comentarios
	if class_info.description == "" and not class_info.signals.is_empty():
		# Buscar comentarios antes del primer signal/property/method
		pass
	
	documented_classes[class_info.name] = class_info
	
	# Actualizar jerarquía
	if class_info.extends != "":
		if not class_info.extends in class_hierarchy:
			class_hierarchy[class_info.extends] = []
		class_hierarchy[class_info.extends].append(class_info.name)

func _parse_signal(line: String, comments: Array) -> Dictionary:
	var signal_match = RegEx.new()
	signal_match.compile("signal\\s+(\\w+)\\s*\\(([^)]*)\\)")
	var result = signal_match.search(line)
	
	if not result:
		return {}
	
	var params = []
	var params_str = result.get_string(2).strip_edges()
	if params_str != "":
		for param in params_str.split(","):
			var parts = param.strip_edges().split(":")
			params.append({
				"name": parts[0].strip_edges(),
				"type": parts[1].strip_edges() if parts.size() > 1 else "Variant"
			})
	
	return {
		"name": result.get_string(1),
		"parameters": params,
		"description": " ".join(comments)
	}

func _parse_property(line: String, comments: Array) -> Dictionary:
	var property_info = {
		"name": "",
		"type": "Variant",
		"default": "",
		"exported": line.begins_with("@export"),
		"description": " ".join(comments)
	}
	
	# Parsear línea de propiedad
	var parts = line.split("=")
	var declaration = parts[0].strip_edges()
	
	if declaration.begins_with("@export"):
		declaration = declaration.substr(7).strip_edges()
		if declaration.begins_with("var"):
			declaration = declaration.substr(3).strip_edges()
	elif declaration.begins_with("var"):
		declaration = declaration.substr(3).strip_edges()
	else:
		return {}
	
	# Extraer nombre y tipo
	var type_parts = declaration.split(":")
	property_info.name = type_parts[0].strip_edges()
	
	if type_parts.size() > 1:
		property_info.type = type_parts[1].strip_edges()
	
	# Valor por defecto
	if parts.size() > 1:
		property_info.default = parts[1].strip_edges()
	
	return property_info

func _parse_method(line: String, comments: Array, file: FileAccess) -> Dictionary:
	var method_match = RegEx.new()
	method_match.compile("func\\s+(\\w+)\\s*\\(([^)]*)\\)")
	var result = method_match.search(line)
	
	if not result:
		return {}
	
	var method_info = {
		"name": result.get_string(1),
		"parameters": [],
		"return_type": "void",
		"description": " ".join(comments),
		"is_virtual": false,
		"is_static": line.contains("static func")
	}
	
	# Detectar métodos virtuales
	if method_info.name.begins_with("_"):
		method_info.is_virtual = true
	
	# Parsear parámetros
	var params_str = result.get_string(2).strip_edges()
	if params_str != "":
		for param in params_str.split(","):
			var param_parts = param.strip_edges().split(":")
			var param_info = {
				"name": param_parts[0].strip_edges(),
				"type": "Variant",
				"default": ""
			}
			
			# Tipo y valor por defecto
			if param_parts.size() > 1:
				var type_default = param_parts[1].strip_edges().split("=")
				param_info.type = type_default[0].strip_edges()
				if type_default.size() > 1:
					param_info.default = type_default[1].strip_edges()
			
			method_info.parameters.append(param_info)
	
	# Intentar detectar tipo de retorno
	var return_pos = line.find("->")
	if return_pos != -1:
		method_info.return_type = line.substr(return_pos + 2).split(":")[0].strip_edges()
	
	return method_info

func _parse_constant(line: String, comments: Array) -> Dictionary:
	var parts = line.split("=")
	if parts.size() < 2:
		return {}
	
	var name_part = parts[0].substr(5).strip_edges() # Quitar "const"
	var value_part = parts[1].strip_edges()
	
	return {
		"name": name_part,
		"value": value_part,
		"description": " ".join(comments)
	}

func _parse_enum(line: String, file: FileAccess) -> Dictionary:
	var enum_name = ""
	if line.contains("{"):
		enum_name = line.split("{")[0].substr(4).strip_edges()
	else:
		enum_name = line.substr(4).strip_edges()
	
	var values = []
	var current_line = line
	
	# Leer valores del enum
	while not current_line.contains("}") and not file.eof_reached():
		if current_line.contains("{"):
			current_line = current_line.split("{")[1]
		
		# Parsear valores
		var value_parts = current_line.split(",")
		for part in value_parts:
			part = part.strip_edges()
			if part != "" and part != "}":
				var value_info = {
					"name": part.split("=")[0].strip_edges(),
					"value": ""
				}
				if part.contains("="):
					value_info.value = part.split("=")[1].strip_edges()
				values.append(value_info)
		
		if not current_line.contains("}"):
			current_line = file.get_line()
	
	return {
		"name": enum_name,
		"values": values
	}

func _generate_html_documentation(output_path: String):
	var html = """<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Pixelize3D FBX - Documentación API</title>
	<style>
		body {
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
			line-height: 1.6;
			color: #333;
			max-width: 1200px;
			margin: 0 auto;
			padding: 20px;
			background: #f5f5f5;
		}
		.header {
			background: #2c3e50;
			color: white;
			padding: 30px;
			border-radius: 8px;
			margin-bottom: 30px;
		}
		.header h1 {
			margin: 0;
			font-size: 2.5em;
		}
		.header p {
			margin: 10px 0 0 0;
			opacity: 0.9;
		}
		.sidebar {
			float: left;
			width: 250px;
			background: white;
			padding: 20px;
			border-radius: 8px;
			box-shadow: 0 2px 4px rgba(0,0,0,0.1);
		}
		.content {
			margin-left: 300px;
			background: white;
			padding: 30px;
			border-radius: 8px;
			box-shadow: 0 2px 4px rgba(0,0,0,0.1);
		}
		.class {
			margin-bottom: 50px;
			padding-bottom: 30px;
			border-bottom: 2px solid #eee;
		}
		.class-name {
			font-size: 2em;
			color: #2c3e50;
			margin-bottom: 10px;
		}
		.extends {
			color: #7f8c8d;
			font-style: italic;
		}
		.section {
			margin: 30px 0;
		}
		.section h3 {
			color: #34495e;
			border-bottom: 1px solid #eee;
			padding-bottom: 10px;
		}
		.member {
			margin: 20px 0;
			padding: 15px;
			background: #f8f9fa;
			border-left: 3px solid #3498db;
			border-radius: 4px;
		}
		.member-name {
			font-weight: bold;
			color: #2c3e50;
			font-family: 'Courier New', monospace;
		}
		.member-type {
			color: #e74c3c;
			font-family: 'Courier New', monospace;
		}
		.member-desc {
			margin-top: 8px;
			color: #555;
		}
		.parameter {
			margin-left: 20px;
			font-family: 'Courier New', monospace;
			color: #666;
		}
		code {
			background: #f1f1f1;
			padding: 2px 6px;
			border-radius: 3px;
			font-family: 'Courier New', monospace;
		}
		.navigation {
			list-style: none;
			padding: 0;
		}
		.navigation li {
			margin: 5px 0;
		}
		.navigation a {
			color: #3498db;
			text-decoration: none;
			display: block;
			padding: 5px 10px;
			border-radius: 4px;
			transition: background 0.2s;
		}
		.navigation a:hover {
			background: #ecf0f1;
		}
		@media (max-width: 768px) {
			.sidebar {
				float: none;
				width: auto;
				margin-bottom: 20px;
			}
			.content {
				margin-left: 0;
			}
		}
	</style>
</head>
<body>
	<div class="header">
		<h1>Pixelize3D FBX - Documentación API</h1>
		<p>Referencia completa de clases y métodos</p>
		<p>Generado: %s</p>
	</div>
	
	<div class="sidebar">
		<h3>Navegación</h3>
		<ul class="navigation">
%s
		</ul>
	</div>
	
	<div class="content">
		<h2>Referencia de Clases</h2>
%s
	</div>
	
	<script>
		// Navegación suave
		document.querySelectorAll('a[href^="#"]').forEach(anchor => {
			anchor.addEventListener('click', function (e) {
				e.preventDefault();
				document.querySelector(this.getAttribute('href')).scrollIntoView({
					behavior: 'smooth'
				});
			});
		});
	</script>
</body>
</html>""" % [
		Time.get_datetime_string_from_system(),
		_generate_html_navigation(),
		_generate_html_classes()
	]
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(html)
		file.close()
		print("Documentación HTML generada: " + output_path)
	else:
		emit_signal("documentation_error", "No se pudo crear archivo HTML")

func _generate_html_navigation() -> String:
	var nav = ""
	
	# Agrupar por categoría
	var categories = {
		"Core": [],
		"Rendering": [],
		"Export": [],
		"UI": [],
		"Utils": [],
		"Other": []
	}
	
	for class_name in documented_classes:
		var class_info = documented_classes[class_name]
		var category = "Other"
		
		if "core" in class_info.path:
			category = "Core"
		elif "rendering" in class_info.path:
			category = "Rendering"
		elif "export" in class_info.path:
			category = "Export"
		elif "ui" in class_info.path:
			category = "UI"
		elif "utils" in class_info.path:
			category = "Utils"
		
		categories[category].append(class_name)
	
	for category in categories:
		if categories[category].size() > 0:
			nav += "<li><strong>%s</strong><ul>" % category
			for class_name in categories[category]:
				nav += '<li><a href="#%s">%s</a></li>' % [class_name, class_name]
			nav += "</ul></li>"
	
	return nav

func _generate_html_classes() -> String:
	var content = ""
	
	for class_name in documented_classes:
		var class_info = documented_classes[class_name]
		
		content += '<div class="class" id="%s">' % class_name
		content += '<h2 class="class-name">%s</h2>' % class_name
		
		if class_info.extends != "":
			content += '<p class="extends">Extends: %s</p>' % class_info.extends
		
		if class_info.description != "":
			content += '<p class="description">%s</p>' % class_info.description
		
		# Signals
		if class_info.signals.size() > 0:
			content += '<div class="section"><h3>Signals</h3>'
			for signal_info in class_info.signals:
				content += _generate_html_signal(signal_info)
			content += '</div>'
		
		# Properties
		if class_info.properties.size() > 0:
			content += '<div class="section"><h3>Properties</h3>'
			for prop in class_info.properties:
				content += _generate_html_property(prop)
			content += '</div>'
		
		# Methods
		if class_info.methods.size() > 0:
			content += '<div class="section"><h3>Methods</h3>'
			for method in class_info.methods:
				content += _generate_html_method(method)
			content += '</div>'
		
		# Constants
		if class_info.constants.size() > 0:
			content += '<div class="section"><h3>Constants</h3>'
			for const in class_info.constants:
				content += _generate_html_constant(const)
			content += '</div>'
		
		content += '</div>'
	
	return content

func _generate_html_signal(signal_info: Dictionary) -> String:
	var html = '<div class="member">'
	html += '<span class="member-name">%s</span>' % signal_info.name
	
	if signal_info.parameters.size() > 0:
		html += '('
		var params = []
		for param in signal_info.parameters:
			params.append('<span class="member-type">%s</span> %s' % [param.type, param.name])
		html += ", ".join(params)
		html += ')'
	
	if signal_info.description != "":
		html += '<div class="member-desc">%s</div>' % signal_info.description
	
	html += '</div>'
	return html

func _generate_html_property(prop: Dictionary) -> String:
	var html = '<div class="member">'
	
	if prop.exported:
		html += '<span style="color: #27ae60;">@export</span> '
	
	html += '<span class="member-name">%s</span>: <span class="member-type">%s</span>' % [
		prop.name, prop.type
	]
	
	if prop.default != "":
		html += ' = <code>%s</code>' % prop.default
	
	if prop.description != "":
		html += '<div class="member-desc">%s</div>' % prop.description
	
	html += '</div>'
	return html

func _generate_html_method(method: Dictionary) -> String:
	var html = '<div class="member">'
	
	if method.is_static:
		html += '<span style="color: #9b59b6;">static</span> '
	
	html += '<span class="member-name">%s</span>' % method.name
	
	# Parámetros
	html += '('
	if method.parameters.size() > 0:
		var params = []
		for param in method.parameters:
			var param_str = '<span class="member-type">%s</span> %s' % [param.type, param.name]
			if param.default != "":
				param_str += ' = <code>%s</code>' % param.default
			params.append(param_str)
		html += ", ".join(params)
	html += ')'
	
	if method.return_type != "void":
		html += ' -> <span class="member-type">%s</span>' % method.return_type
	
	if method.description != "":
		html += '<div class="member-desc">%s</div>' % method.description
	
	html += '</div>'
	return html

func _generate_html_constant(const: Dictionary) -> String:
	var html = '<div class="member">'
	html += '<span class="member-name">%s</span> = <code>%s</code>' % [
		const.name, const.value
	]
	
	if const.description != "":
		html += '<div class="member-desc">%s</div>' % const.description
	
	html += '</div>'
	return html

func _generate_markdown_documentation(output_path: String):
	var md = """# Pixelize3D FBX - Documentación API

Generado: %s

## Índice

%s

## Referencia de Clases

%s
""" % [
		Time.get_datetime_string_from_system(),
		_generate_markdown_toc(),
		_generate_markdown_classes()
	]
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(md)
		file.close()
		print("Documentación Markdown generada: " + output_path)

func _generate_markdown_toc() -> String:
	var toc = ""
	for class_name in documented_classes:
		toc += "- [%s](#%s)\n" % [class_name, class_name.to_lower()]
	return toc

func _generate_markdown_classes() -> String:
	var content = ""
	
	for class_name in documented_classes:
		var class_info = documented_classes[class_name]
		
		content += "## %s\n\n" % class_name
		
		if class_info.extends != "":
			content += "*Extends: %s*\n\n" % class_info.extends
		
		if class_info.description != "":
			content += "%s\n\n" % class_info.description
		
		# Generar secciones...
		# Similar a HTML pero en formato Markdown
	
	return content

func _generate_json_documentation(output_path: String):
	var json_data = {
		"generated": Time.get_datetime_string_from_system(),
		"version": "1.0.0",
		"classes": documented_classes,
		"hierarchy": class_hierarchy
	}
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(json_data, "\t"))
		file.close()
		print("Documentación JSON generada: " + output_path)
