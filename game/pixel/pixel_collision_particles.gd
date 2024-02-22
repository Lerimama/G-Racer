extends Node2D


onready var btm_particles: Particles2D = $BtmParticles
onready var top_particles: Particles2D = $TopParticles


func _ready() -> void:
	top_particles.emitting = true
	btm_particles.emitting = true
	yield(get_tree().create_timer(0.5), "timeout") # tole je precej amaterski način
	queue_free()

func _on_Particles2D2_tree_exited() -> void:
	queue_free()


func _on_Particles2D_tree_exited() -> void:
	queue_free()
