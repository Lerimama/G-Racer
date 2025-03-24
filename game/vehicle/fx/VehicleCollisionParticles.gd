extends CPUParticles2D


func _process(delta: float) -> void:

	if not emitting: # on stanje dobi na spawnu
		queue_free()

