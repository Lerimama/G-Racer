extends StaticBody2D


var magnet_color: Color = Set.color_gray5

var magnet_on: bool

var x_to_magnet: float
var y_to_magnet: float

var direction_to_magnet: float # atan2(y_to_magnet, x_to_magnet) ... kot od telesa do magneta (glede na x os) ... radiani
var distance_to_magnet: float # diagonala od telesa do magneta ... c2 = a2 + b2 ... var c = sqrt ((a * a) + (b * b))

var gravity_velocity: float # hitrost glede na distanco od magneta ...gravitacijski pospešek
var gravity_force: float = 70.0 # sila gravitacije

var velocity: Vector2 = Vector2()
var def_particle_speed: float = 0.5

var time: float = 0
var off_time: float = 2
var on_time: float = 2

onready var force_field: Area2D = $ForceField
onready var sprite: Sprite = $Sprite
onready var blackhole_particles: Particles2D = $BlackholeParticles
onready var animation_player: AnimationPlayer = $AnimationPlayer


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
#			if body.is_in_group(Ref.group_bolts):
				direction_to_magnet = Met.get_direction_to(body.global_position, global_position)
				distance_to_magnet = Met.get_distance_to(body.global_position, global_position)
				gravity_velocity = gravity_force / (distance_to_magnet * 1)
				body.velocity += Vector2(gravity_velocity, 0).rotated(direction_to_magnet)
		

func intro():
		magnet_on = true
#		blackhole_particles.emitting = true
		blackhole_particles.speed_scale = def_particle_speed
		animation_player.play("intro")


func outro():
		animation_player.play("outro")
		blackhole_particles.speed_scale = 0.7
		blackhole_particles.emitting = false
		magnet_on = false
		

func pause_me():
	set_physics_process(false)
	blackhole_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	set_physics_process(true)
	blackhole_particles.speed_scale = def_particle_speed
	animation_player.play()

