# scripts/core/animation_loop_manager.gd
# Script completamente SINCRÓNICO para manejar loops y cambios de animación
# Input: AnimationPlayer con animaciones
# Output: Control correcto de loops y cambios de animación SIN await

extends Node

# Función para configurar todas las animaciones para loop infinito
static func setup_infinite_loops(anim_player: AnimationPlayer) -> void:
	if not anim_player:
		print("❌ AnimationPlayer inválido para configurar loops")
		return
	
	print("🔄 CONFIGURANDO LOOPS INFINITOS")
	
	var animations_configured = 0
	
	# Configurar cada animación para loop
	for anim_name in anim_player.get_animation_list():
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(anim_name)
		
		if animation:
			# Configurar loop mode
			animation.loop_mode = Animation.LOOP_LINEAR
			animations_configured += 1
			print("  ✅ Loop configurado: %s" % anim_name)
	
	print("🔄 Loops configurados: %d animaciones" % animations_configured)

# Función SINCRÓNICA para cambiar animación de forma limpia
static func change_animation_clean(anim_player: AnimationPlayer, new_animation: String) -> bool:
	if not anim_player:
		print("❌ AnimationPlayer inválido")
		return false
	
	if not anim_player.has_animation(new_animation):
		print("❌ Animación no encontrada: %s" % new_animation)
		return false
	
	print("🎭 CAMBIANDO ANIMACIÓN A: %s" % new_animation)
	
	# PASO 1: Detener animación actual
	if anim_player.is_playing():
		var current_anim = anim_player.current_animation
		print("  🛑 Deteniendo animación actual: %s" % current_anim)
		anim_player.stop()
	
	# PASO 2: Configurar loop en la nueva animación
	var anim_lib = anim_player.get_animation_library("")
	var animation = anim_lib.get_animation(new_animation)
	if animation:
		animation.loop_mode = Animation.LOOP_LINEAR
		print("  🔄 Loop configurado para: %s" % new_animation)
	
	# PASO 3: Iniciar nueva animación directamente
	print("  ▶️ Iniciando nueva animación: %s" % new_animation)
	anim_player.play(new_animation)
	
	# PASO 4: Verificar éxito
	if anim_player.is_playing() and anim_player.current_animation == new_animation:
		print("  ✅ Cambio de animación exitoso")
		return true
	else:
		print("  ❌ Falló el cambio de animación")
		return false

# Función SINCRÓNICA para iniciar animación con loop automático
static func play_animation_with_loop(anim_player: AnimationPlayer, animation_name: String) -> bool:
	if not anim_player or not anim_player.has_animation(animation_name):
		return false
	
	# Usar el método limpio
	return change_animation_clean(anim_player, animation_name)

# Función para pausar/reanudar manteniendo el loop
static func toggle_pause_with_loop(anim_player: AnimationPlayer) -> bool:
	if not anim_player:
		return false
	
	if anim_player.is_playing():
		print("⏸️ Pausando animación")
		anim_player.pause()
		return false  # Ahora está pausado
	else:
		print("▶️ Reanudando animación")
		anim_player.play()
		return true   # Ahora está reproduciendo

# Función para detener completamente y resetear
static func stop_animation_clean(anim_player: AnimationPlayer) -> void:
	if not anim_player:
		return
	
	print("⏹️ DETENIENDO ANIMACIÓN COMPLETAMENTE")
	
	# Detener reproducción
	anim_player.stop()
	
	# Limpiar estado
	anim_player.current_animation = ""
	
	# Resetear a pose de reposo si existe
	var animations = anim_player.get_animation_list()
	if animations.size() > 0:
		var first_anim = animations[0]
		anim_player.play(first_anim)
		anim_player.seek(0.0, true)
		anim_player.pause()
		print("  🎭 Reseteado a pose inicial de: %s" % first_anim)

# Función para verificar estado de loop de una animación
static func check_animation_loop_status(anim_player: AnimationPlayer, animation_name: String) -> Dictionary:
	var status = {
		"has_animation": false,
		"loop_enabled": false,
		"loop_mode": "NONE",
		"is_playing": false,
		"current_position": 0.0,
		"total_length": 0.0
	}
	
	if not anim_player:
		return status
	
	status.has_animation = anim_player.has_animation(animation_name)
	status.is_playing = anim_player.is_playing() and anim_player.current_animation == animation_name
	
	if status.has_animation:
		var anim_lib = anim_player.get_animation_library("")
		var animation = anim_lib.get_animation(animation_name)
		
		if animation:
			status.loop_enabled = animation.loop_mode != Animation.LOOP_NONE
			status.total_length = animation.length
			
			match animation.loop_mode:
				Animation.LOOP_NONE:
					status.loop_mode = "NONE"
				Animation.LOOP_LINEAR:
					status.loop_mode = "LINEAR"
				Animation.LOOP_PINGPONG:
					status.loop_mode = "PINGPONG"
			
			if status.is_playing:
				status.current_position = anim_player.current_animation_position
	
	return status

# Función de debug para verificar estado de loops
static func debug_all_animation_loops(anim_player: AnimationPlayer):
	if not anim_player:
		print("❌ AnimationPlayer inválido para debug")
		return
	
	print("\n🔍 DEBUG: ESTADO DE LOOPS DE ANIMACIONES")
	print("AnimationPlayer: %s" % anim_player.name)
	print("Reproduciendo: %s" % anim_player.is_playing())
	print("Animación actual: %s" % anim_player.current_animation)
	print("---")
	
	for anim_name in anim_player.get_animation_list():
		var status = check_animation_loop_status(anim_player, anim_name)
		print("🎭 %s:" % anim_name)
		print("  Loop: %s (%s)" % [status.loop_enabled, status.loop_mode])
		print("  Duración: %.2fs" % status.total_length)
		if status.is_playing:
			print("  ▶️ ACTIVA - Posición: %.2fs" % status.current_position)
		else:
			print("  ⏸️ Inactiva")
	
	print("🔍 FIN DEBUG LOOPS\n")

# Función SINCRÓNICA para configurar AnimationPlayer completo con loops
static func setup_animation_player_with_loops(anim_player: AnimationPlayer) -> void:
	if not anim_player:
		return
	
	print("🎬 CONFIGURANDO ANIMATIONPLAYER CON LOOPS")
	
	# Configurar loops en todas las animaciones
	setup_infinite_loops(anim_player)
	
	# Configurar propiedades del player
	anim_player.autoplay = ""  # No autoplay automático
	
	# Si hay animaciones, reproducir la primera automáticamente en loop
	var animations = anim_player.get_animation_list()
	if animations.size() > 0:
		var first_anim = animations[0]
		print("🎭 Iniciando animación por defecto: %s" % first_anim)
		
		# Usar método directo sincrónico
		play_animation_with_loop(anim_player, first_anim)
	
	print("✅ AnimationPlayer configurado con loops")

# Función SINCRÓNICA para aplicar una pose específica de animación
static func apply_animation_pose(anim_player: AnimationPlayer, animation_name: String, time_position: float = 0.0) -> bool:
	if not anim_player or not anim_player.has_animation(animation_name):
		print("❌ No se puede aplicar pose: animación no encontrada")
		return false
	
	print("🎭 Aplicando pose de animación: %s en tiempo %.2fs" % [animation_name, time_position])
	
	# Reproducir la animación en la posición específica
	anim_player.play(animation_name)
	anim_player.seek(time_position, true)
	anim_player.advance(0.0)
	
	return true

# Función auxiliar para obtener nombre del tipo de track
static func _get_track_type_name(track_type: int) -> String:
	match track_type:
		Animation.TYPE_ROTATION_3D:
			return "Rotation3D"
		Animation.TYPE_POSITION_3D:
			return "Position3D"
		Animation.TYPE_SCALE_3D:
			return "Scale3D"
		Animation.TYPE_BLEND_SHAPE:
			return "BlendShape"
		Animation.TYPE_VALUE:
			return "Value"
		Animation.TYPE_METHOD:
			return "Method"
		_:
			return "Unknown(%d)" % track_type
