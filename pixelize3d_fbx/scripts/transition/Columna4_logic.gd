# pixelize3d_fbx/scripts/transition/Columna4_Logic.gd
# Lógica de generación y preview de transiciones finales - Columna 4
# Input: Configuraciones de Columna 3, orientación de Columna 2, datos de esqueletos
# Output: Preview de transición generada y exportación de spritesheet

extends Node
class_name Columna4Logic

# === SEÑALES HACIA COORDINADOR ===
signal transition_preview_ready(preview_data: Dictionary)
signal frame_generated(frame_index: int, total_frames: int)
signal generation_complete(animation_resource: Animation)
signal generation_failed(error_message: String)

# === SEÑALES HACIA UI ===
signal playback_state_changed(state: Dictionary)
signal frame_updated(current_frame: int, total_frames: int)
signal generation_progress_updated(progress: float, status: String)

# === CONFIGURACIÓN Y DATOS ===
var transition_config: Dictionary = {}
var skeleton_data: Dictionary = {}
var camera_settings: Dictionary = {}
var generated_animation: Animation = null
var transition_frames: Array = []

# === CONTROL DE REPRODUCCIÓN ===
var is_playing: bool = false
var is_generating: bool = false
var current_frame: int = 0
var total_frames: int = 0
var playback_speed: float = 1.0
var playback_timer: Timer

# === ESTADO INTERNO ===
enum State {
	WAITING_DATA,
	GENERATING,
	READY,
	PLAYING,
	EXPORTING
}
var current_state: State = State.WAITING_DATA

# === REFERENCIAS ===
var animation_player: AnimationPlayer
var model_preview: Node3D
var export_manager: Node

# === INTERPOLACIÓN ===
var interpolation_types: Dictionary = {
	"Linear": _interpolate_linear,
	"Ease In": _interpolate_ease_in,
	"Ease Out": _interpolate_ease_out,
	"Ease In-Out": _interpolate_ease_in_out,
	"Smooth": _interpolate_smooth,
	"Cubic": _interpolate_cubic
}

func _ready():
	print("🎯 Columna4Logic inicializando...")
	_setup_playback_timer()
	_setup_export_manager()
	current_state = State.WAITING_DATA
	print("✅ Columna4Logic listo - Esperando datos")

func _setup_playback_timer():
	"""Configurar timer para reproducción de preview"""
	playback_timer = Timer.new()
	playback_timer.wait_time = 1.0 / 30.0  # 30 FPS por defecto
	playback_timer.timeout.connect(_on_playback_timer_timeout)
	add_child(playback_timer)

func _setup_export_manager():
	"""Configurar conexión con el sistema de exportación existente"""
	# Buscar ExportManager existente en el sistema
	export_manager = get_node_or_null("/root/ExportManager")
	if not export_manager:
		# Si no existe, intentar cargar y crear uno
		var export_script = load("res://scripts/export/export_manager.gd")
		if export_script:
			export_manager = export_script.new()
			export_manager.name = "ExportManager_Col4"
			add_child(export_manager)
			print("✅ ExportManager creado para Columna 4")
	else:
		print("✅ ExportManager encontrado en sistema")

# ========================================================================
# API PÚBLICA - CARGA DE DATOS
# ========================================================================

func load_transition_data(config: Dictionary, skeleton: Dictionary, camera: Dictionary):
	"""Cargar datos de configuración, esqueletos y cámara"""
	print("📥 Cargando datos de transición...")
	print("  Config: %s" % str(config))
	print("  Skeleton bones: %d" % skeleton.get("bones_count", 0))
	print("  Camera settings: %d parámetros" % camera.size())
	
	transition_config = config.duplicate()
	skeleton_data = skeleton.duplicate()
	camera_settings = camera.duplicate()
	
	total_frames = transition_config.get("frames", 30)
	
	# Validar datos
	if _validate_transition_data():
		current_state = State.READY
		print("✅ Datos cargados correctamente")
		_emit_state_change()
	else:
		current_state = State.WAITING_DATA
		print("❌ Datos inválidos")
		emit_signal("generation_failed", "Datos de transición inválidos")

func _validate_transition_data() -> bool:
	"""Validar que todos los datos necesarios estén presentes"""
	# Validar configuración
	if not transition_config.has("duration") or not transition_config.has("frames"):
		print("❌ Configuración incompleta")
		return false
	
	if not transition_config.has("interpolation"):
		print("❌ Tipo de interpolación no especificado")
		return false
	
	# Validar datos de esqueleto
	if not skeleton_data.has("skeleton_pose_a") or not skeleton_data.has("skeleton_pose_b"):
		print("❌ Poses de esqueleto faltantes")
		return false
	
	if skeleton_data.get("bones_count", 0) <= 0:
		print("❌ Información de bones inválida")
		return false
	
	print("✅ Validación exitosa")
	return true

# ========================================================================
# GENERACIÓN DE TRANSICIÓN
# ========================================================================

func generate_transition_animation():
	"""Generar animación de transición entre las dos poses"""
	if current_state != State.READY:
		print("❌ No se puede generar: estado actual %s" % State.keys()[current_state])
		return false
	
	print("🎬 Iniciando generación de transición...")
	current_state = State.GENERATING
	is_generating = true
	_emit_state_change()
	
	# Inicializar progreso
	emit_signal("generation_progress_updated", 0.0, "Iniciando generación...")
	
	# Generar frames de transición
	var success = await _generate_transition_frames()
	
	if success:
		# Crear Animation resource
		success = _create_animation_resource()
	
	is_generating = false
	
	if success:
		current_state = State.READY
		print("✅ Transición generada exitosamente")
		emit_signal("generation_complete", generated_animation)
		emit_signal("transition_preview_ready", _get_preview_data())
	else:
		current_state = State.WAITING_DATA
		print("❌ Error en generación de transición")
		emit_signal("generation_failed", "Error durante la generación")
	
	_emit_state_change()
	return success

func _generate_transition_frames() -> bool:
	"""Generar frames interpolados de la transición"""
	transition_frames.clear()
	
	var pose_a = skeleton_data.skeleton_pose_a
	var pose_b = skeleton_data.skeleton_pose_b
	var interpolation_func = interpolation_types.get(transition_config.interpolation, _interpolate_linear)
	
	print("📸 Generando %d frames con interpolación %s" % [total_frames, transition_config.interpolation])
	
	for frame_index in range(total_frames):
		# Calcular factor de interpolación (0.0 a 1.0)
		var t = float(frame_index) / float(total_frames - 1) if total_frames > 1 else 0.0
		
		# Aplicar curva de interpolación
		var interpolated_t = interpolation_func.call(t)
		
		# Generar pose interpolada
		var interpolated_pose = _interpolate_skeleton_pose(pose_a, pose_b, interpolated_t)
		
		# Guardar frame
		var frame_data = {
			"index": frame_index,
			"time": t * transition_config.duration,
			"t_factor": interpolated_t,
			"pose": interpolated_pose
		}
		transition_frames.append(frame_data)
		
		# Actualizar progreso
		var progress = float(frame_index + 1) / float(total_frames)
		emit_signal("generation_progress_updated", progress, "Frame %d/%d" % [frame_index + 1, total_frames])
		emit_signal("frame_generated", frame_index, total_frames)
		
		# Yield ocasionalmente para no bloquear
		if frame_index % 10 == 0:
			await get_tree().process_frame
	
	print("✅ %d frames generados" % transition_frames.size())
	return true

func _interpolate_skeleton_pose(pose_a: Dictionary, pose_b: Dictionary, t: float) -> Dictionary:
	"""Interpolar entre dos poses de esqueleto"""
	var interpolated_pose = {}
	
	# Interpolar cada bone
	for bone_name in pose_a.keys():
		if bone_name in pose_b:
			var bone_a = pose_a[bone_name]
			var bone_b = pose_b[bone_name]
			
			# Interpolar posición, rotación y escala
			var interpolated_bone = {}
			
			if bone_a.has("position") and bone_b.has("position"):
				interpolated_bone.position = bone_a.position.lerp(bone_b.position, t)
			
			if bone_a.has("rotation") and bone_b.has("rotation"):
				var quat_a = Quaternion(bone_a.rotation.x, bone_a.rotation.y, bone_a.rotation.z, bone_a.rotation.w)
				var quat_b = Quaternion(bone_b.rotation.x, bone_b.rotation.y, bone_b.rotation.z, bone_b.rotation.w)
				var interpolated_quat = quat_a.slerp(quat_b, t)
				interpolated_bone.rotation = Vector4(interpolated_quat.x, interpolated_quat.y, interpolated_quat.z, interpolated_quat.w)
			
			if bone_a.has("scale") and bone_b.has("scale"):
				interpolated_bone.scale = bone_a.scale.lerp(bone_b.scale, t)
			
			interpolated_pose[bone_name] = interpolated_bone
	
	return interpolated_pose

func _create_animation_resource() -> bool:
	"""Crear Animation resource de Godot desde los frames generados"""
	print("🎞️ Creando Animation resource...")
	
	generated_animation = Animation.new()
	generated_animation.length = transition_config.duration
	
	# Crear tracks para cada bone
	var bone_names = skeleton_data.skeleton_pose_a.keys()
	var track_index = 0
	
	for bone_name in bone_names:
		# Track de posición
		var pos_track_index = generated_animation.add_track(Animation.TYPE_POSITION_3D)
		generated_animation.track_set_path(pos_track_index, NodePath("Skeleton3D:" + bone_name))
		
		# Track de rotación  
		var rot_track_index = generated_animation.add_track(Animation.TYPE_ROTATION_3D)
		generated_animation.track_set_path(rot_track_index, NodePath("Skeleton3D:" + bone_name))
		
		# Track de escala
		var scale_track_index = generated_animation.add_track(Animation.TYPE_SCALE_3D)
		generated_animation.track_set_path(scale_track_index, NodePath("Skeleton3D:" + bone_name))
		
		# Agregar keyframes
		for frame_data in transition_frames:
			var time = frame_data.time
			var pose = frame_data.pose
			
			if bone_name in pose:
				var bone_data = pose[bone_name]
				
				if bone_data.has("position"):
					generated_animation.track_insert_key(pos_track_index, time, bone_data.position)
				
				if bone_data.has("rotation"):
					var rot = bone_data.rotation
					var quat = Quaternion(rot.x, rot.y, rot.z, rot.w)
					generated_animation.track_insert_key(rot_track_index, time, quat)
				
				if bone_data.has("scale"):
					generated_animation.track_insert_key(scale_track_index, time, bone_data.scale)
	
	print("✅ Animation resource creado con %d tracks" % generated_animation.get_track_count())
	return true

# ========================================================================
# FUNCIONES DE INTERPOLACIÓN
# ========================================================================

func _interpolate_linear(t: float) -> float:
	return t

func _interpolate_ease_in(t: float) -> float:
	return t * t

func _interpolate_ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

func _interpolate_ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func _interpolate_smooth(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

func _interpolate_cubic(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

# ========================================================================
# CONTROL DE REPRODUCCIÓN
# ========================================================================

func play_preview():
	"""Iniciar reproducción del preview"""
	if current_state != State.READY or transition_frames.is_empty():
		print("❌ No se puede reproducir: estado %s, frames %d" % [State.keys()[current_state], transition_frames.size()])
		return false
	
	print("▶️ Iniciando reproducción de preview")
	is_playing = true
	current_state = State.PLAYING
	current_frame = 0
	
	# Configurar velocidad de reproducción
	var fps = total_frames / transition_config.duration * playback_speed
	playback_timer.wait_time = 1.0 / fps
	playback_timer.start()
	
	_emit_state_change()
	_apply_frame_to_preview(current_frame)
	return true

func pause_preview():
	"""Pausar reproducción del preview"""
	print("⏸️ Pausando reproducción")
	is_playing = false
	current_state = State.READY
	playback_timer.stop()
	_emit_state_change()

func seek_to_frame(frame_index: int):
	"""Ir a un frame específico"""
	frame_index = clamp(frame_index, 0, total_frames - 1)
	current_frame = frame_index
	
	_apply_frame_to_preview(current_frame)
	emit_signal("frame_updated", current_frame, total_frames)

func set_playback_speed(speed: float):
	"""Establecer velocidad de reproducción"""
	playback_speed = clamp(speed, 0.1, 3.0)
	
	# Actualizar timer si está reproduciendo
	if is_playing:
		var fps = total_frames / transition_config.duration * playback_speed
		playback_timer.wait_time = 1.0 / fps

func _on_playback_timer_timeout():
	"""Manejar timeout del timer de reproducción"""
	if not is_playing or transition_frames.is_empty():
		return
	
	current_frame += 1
	
	if current_frame >= total_frames:
		# Loop o parar
		current_frame = 0  # Loop por ahora
	
	_apply_frame_to_preview(current_frame)
	emit_signal("frame_updated", current_frame, total_frames)

func _apply_frame_to_preview(frame_index: int):
	"""Aplicar pose de frame específico al modelo de preview"""
	if frame_index < 0 or frame_index >= transition_frames.size():
		return
	
	var frame_data = transition_frames[frame_index]
	var pose = frame_data.pose
	
	# Aplicar pose al modelo (esto se implementaría según el sistema de preview)
	# Por ahora solo emitir señal con los datos
	emit_signal("frame_updated", frame_index, total_frames)

# ========================================================================
# EXPORTACIÓN DE SPRITESHEET
# ========================================================================

func export_spritesheet(output_path: String, export_config: Dictionary = {}) -> bool:
	"""Exportar transición como spritesheet"""
	if current_state == State.WAITING_DATA or transition_frames.is_empty():
		print("❌ No se puede exportar: sin datos de transición")
		return false
	
	print("📁 Iniciando exportación de spritesheet...")
	current_state = State.EXPORTING
	_emit_state_change()
	
	# Configuración de exportación por defecto
	var final_config = {
		"sprite_size": 128,
		"directions": 1,  # Solo una dirección para transición
		"background_transparent": true,
		"generate_metadata": true
	}
	final_config.merge(export_config, true)
	
	# Añadir configuración de cámara y transición
	final_config.merge(camera_settings, true)
	final_config["animation_name"] = "transition"
	final_config["total_frames"] = total_frames
	final_config["duration"] = transition_config.duration
	
	# Usar ExportManager existente
	var success = false
	if export_manager and export_manager.has_method("export_transition_spritesheet"):
		success = await export_manager.export_transition_spritesheet(
			transition_frames,
			output_path,
			final_config
		)
	else:
		print("❌ ExportManager no disponible o método no encontrado")
	
	current_state = State.READY
	_emit_state_change()
	
	if success:
		print("✅ Spritesheet exportado exitosamente")
	else:
		print("❌ Error en exportación de spritesheet")
	
	return success

# ========================================================================
# UTILIDADES Y HELPERS
# ========================================================================

func _emit_state_change():
	"""Emitir cambio de estado"""
	var state_data = {
		"state": State.keys()[current_state],
		"is_playing": is_playing,
		"is_generating": is_generating,
		"current_frame": current_frame,
		"total_frames": total_frames,
		"has_animation": generated_animation != null,
		"playback_speed": playback_speed
	}
	emit_signal("playback_state_changed", state_data)

func _get_preview_data() -> Dictionary:
	"""Obtener datos para preview"""
	return {
		"animation": generated_animation,
		"frames": transition_frames,
		"config": transition_config,
		"camera_settings": camera_settings,
		"total_frames": total_frames,
		"duration": transition_config.duration
	}

# ========================================================================
# API PÚBLICA - GETTERS
# ========================================================================

func get_current_state() -> String:
	return State.keys()[current_state]

func is_ready_for_preview() -> bool:
	return current_state == State.READY and not transition_frames.is_empty()

func is_ready_for_export() -> bool:
	return is_ready_for_preview() and generated_animation != null

func get_transition_info() -> Dictionary:
	return {
		"duration": transition_config.get("duration", 0.0),
		"frames": total_frames,
		"interpolation": transition_config.get("interpolation", "Linear"),
		"current_frame": current_frame,
		"progress": float(current_frame) / float(max(total_frames - 1, 1))
	}
