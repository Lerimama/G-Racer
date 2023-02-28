extends Node2D



func _ready() -> void:

	$ExplosionParticles.set_emitting(true)
#	$AnimatedSprite.play("flash")
	print("EXPLOZIJA")
	
	print($AnimatedSprite.play())
