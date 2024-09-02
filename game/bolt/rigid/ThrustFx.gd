extends Node2D

onready var thrust_particles: Particles2D = $ThrustParticles


func _ready() -> void:
	thrust_particles.emitting = false


func start_fx(reverse_direction: bool = false):
	
	thrust_particles.emitting = true
	
	if reverse_direction:
		thrust_particles.get_process_material().direction.x = 1
	else:
		thrust_particles.get_process_material().direction.x = -1


func stop_fx():
	
	thrust_particles.emitting = false

