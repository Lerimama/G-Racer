extends Particles2D


var velocity: Vector2


func _process(delta: float) -> void:
	
	global_position += velocity/2 * delta
	
	# pojemek
	velocity *= 0.9988 
	
