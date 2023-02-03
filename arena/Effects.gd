extends Node2D




# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

onready var partikli = preload("res://player/EngineParticles.tscn")
var particles_test

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	AutoGlobal.effects_creation_parent = self
	print("AutoGlobal.effects_creation_parent = self")
	
#	particles_test = partikli.instance()
##	particles_test.set_as_toplevel(true) # načeloma ne rabi, ampak se mi občasno pokaže kar nekje
##	particles_test.modulate.a = engines_alpha
##	AutoGlobal.effects_creation_parent.add_child(particles_test)
#	particles_test.global_position = get_local_mouse_position()
#	add_child(particles_test)
#	particles_test.set_one_shot(false)
#	particles_test.set_emitting(true)
#	particles_test.modulate = AutoGlobal.effects_creation_parent.modulate

	pass # Replace with function body.

func _process(delta: float) -> void:
	
#	particles_test.global_position = get_local_mouse_position()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	pass
