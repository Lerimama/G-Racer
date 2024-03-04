extends StaticBody2D


var magnet_color: Color = Set.color_gray5

var magnet_on: bool

var def_particle_speed: float = 0.5
var gravity_force: float = 70.0 # sila gravitacije

var time: float = 0
var off_time: float = 2
var on_time: float = 2

onready var force_field: Area2D = $ForceField
onready var sprite: Sprite = $Sprite
onready var blackhole_particles: Particles2D = $BlackholeParticles
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var magnet_points: int = Set.default_game_settings["magnet_brick_points"]


func _ready() -> void:
	
	pass


func _physics_process(delta: float) -> void:
	
	time += delta 
	
	if time > off_time and not magnet_on:
		intro()
		time = 0
	elif time > on_time and magnet_on:
		time = 0
		outro()

	if magnet_on:
		var detected_bodies = force_field.get_overlapping_bodies()
		for body in detected_bodies:
			if body is Bolt:
				var vector_to_magnet: Vector2 = body.global_position.direction_to(global_position)
				var distance_to_magnet: float = body.global_position.distance_to(global_position)
				var gravity_velocity: float = gravity_force / (distance_to_magnet * 1)
				body.velocity += Vector2(gravity_velocity, 0).rotated(vector_to_magnet.angle())
				body.get_points(magnet_points)
		

func intro():
#		blackhole_particles.emitting = true
		blackhole_particles.speed_scale = def_particle_speed
		animation_player.play("intro")


func outro():
		magnet_on = false
		animation_player.play("outro")
		blackhole_particles.speed_scale = 0.7
		blackhole_particles.emitting = false
		

func pause_me():
	set_physics_process(false)
	blackhole_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	set_physics_process(true)
	blackhole_particles.speed_scale = def_particle_speed
	animation_player.play()



func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"intro":
			magnet_on = true
			
