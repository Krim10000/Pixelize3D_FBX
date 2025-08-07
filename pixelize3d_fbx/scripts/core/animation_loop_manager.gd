# scripts/core/animation_loop_manager.gd
# Script completamente SINCRÓNICO para manejar loops y cambios de animación
# Input: AnimationPlayer con animaciones
# Output: Control correcto de loops y cambios de animación SIN await

# scripts/core/animation_loop_manager.gd
# Administrador de reproducción de animaciones con bucles seguros

extends Node
class_name AnimationLoopManager

# === FUNCIONES PÚBLICAS ===

func change_animation_clean(animation_player: AnimationPlayer, animation_name: String) -> bool:
	"""
	Reproduce una animación limpiamente en bucle.
	Detiene la anterior y asegura loop.
	"""
	if not animation_player:
		push_error("❌ [LoopManager] AnimationPlayer nulo")
		return false
	
	if not animation_player.has_animation(animation_name):
		push_error("❌ [LoopManager] Animación '%s' no encontrada" % animation_name)
		return false
	
	# Detener animación actual
	if animation_player.is_playing():
		print("⏹️ [LoopManager] Deteniendo animación actual: %s" % animation_player.current_animation)
		animation_player.stop()
	
	# Configurar loop en la animación
	var anim = animation_player.get_animation(animation_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR  # ❗ Usa LOOP_LINEAR en Godot 4
	
	# Reproducir desde el inicio con mezcla
	animation_player.play(animation_name, -1.0, 0.2)
	print("▶️ [LoopManager] Reproduciendo animación limpia: %s" % animation_name)
	return true

func stop_animation_clean(animation_player: AnimationPlayer) -> void:
	"""
	Detiene por completo la animación actual.
	"""
	if animation_player and animation_player.is_playing():
		print("🛑 [LoopManager] Deteniendo animación: %s" % animation_player.current_animation)
		animation_player.stop()

func setup_infinite_loops(animation_player: AnimationPlayer) -> void:
	"""
	Establece todas las animaciones del AnimationPlayer como loops infinitos.
	"""
	if not animation_player:
		return
	
	for ani_name in animation_player.get_animation_list():
		var anim = animation_player.get_animation(ani_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR  # ❗ LOOP_LINEAR es el modo estándar

func toggle_pause_with_loop(animation_player: AnimationPlayer) -> bool:
	"""
	Pausa o reanuda la animación manteniendo el loop.
	Retorna true si está reproduciendo después del cambio.
	"""
	if not animation_player:
		return false
	
	if animation_player.is_playing():
		animation_player.pause()
		print("⏸️ [LoopManager] Animación pausada")
		return false
	else:
		animation_player.play()
		print("▶️ [LoopManager] Animación reanudada")
		return true
