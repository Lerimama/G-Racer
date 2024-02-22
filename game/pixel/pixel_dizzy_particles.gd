extends Node2D


onready var particles: Particles2D = $Particles


func _ready() -> void:
	particles.emitting = true


func _on_Particles_tree_exited() -> void:
	queue_free()

