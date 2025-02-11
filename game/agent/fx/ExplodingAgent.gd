extends Node2D


export var decay_time: float = 1.0

var spawner_color: Color
var velocity: Vector2
#var decay_done: bool = false # za preverjanje ali je stvar že končana (usklajeno med partilci in shardi

onready var decay_timer: Timer = $Timer
onready var debris_particles: CPUParticles2D = $DebrisParticles
onready var explosion_particles: Particles2D = $ExplosionParticles
onready var explosion_blast: AnimatedSprite = $ExplosionBlast


func _ready() -> void:

	explosion_blast.play("default")
	yield(get_tree().create_timer(0.05), "timeout")
	debris_particles.set_emitting(true)

#	explosion_particles.process_material.color_ramp.gradient.colors[0] = spawner_color
	explosion_particles.process_material.color_ramp.gradient.colors[1] = spawner_color
	explosion_particles.process_material.color_ramp.gradient.colors[2] = spawner_color
	explosion_particles.set_emitting(true)

	decay_timer.wait_time = decay_time
	decay_timer.start()


func _process(delta: float) -> void:

	global_position += velocity/2 * delta

	# pojemek
	velocity *= 0.9985


func _on_Timer_timeout() -> void:
	queue_free()
