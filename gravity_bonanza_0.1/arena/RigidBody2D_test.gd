extends RigidBody2D



var first_touch
var release


export var rotation_per_frame = 200  # rotacija je narejena tako, da na vsak frejm obrača za določen kot
var current_rotation : float

var velocity = Vector2.ZERO
export var engine_power = 20  # pospešek

export var drag_coefficient = 0.98 # količlnik upora zraka 1 je 0
export var drift_factor = 0.9 # opredeli vektor stranskega gibanja 


func _ready() -> void:
	
	add_to_group("obsticles")

func get_input():

	var rotation_multiplier = 0

	if Input.is_action_pressed("ui_right"):
		rotation_multiplier = 1
	if Input.is_action_pressed("ui_left"):
		rotation_multiplier = -1

	current_rotation = rotation_multiplier * deg2rad(rotation_per_frame)

	if Input.is_action_pressed("ui_up"):
		velocity += forward_direction() * engine_power
	if Input.is_action_pressed("ui_down"):
		velocity -= forward_direction() * engine_power/4

	velocity = forward_velocity() + (side_velocity() * drift_factor) # skupna hitrost gibanja je seštevek x in y vektorjev
#	velocity *= drag_coefficient # upoštevam upor zraka, ki raste s hitrostjo


func _process(delta: float) -> void:
	
	get_input()
	
	if (Input.is_action_just_pressed("click")):
		first_touch = get_global_mouse_position()
	if (Input.is_action_just_released("click")):
		release = get_global_mouse_position()
		
		var dir = -(release - first_touch).normalized()
		
		linear_velocity = dir *delta * 30000


#func _physics_process(delta):
#
#	get_input()
##	set_linear_velocity(velocity)
#	set_angular_velocity(current_rotation)
#	linear_velocity = velocity*delta


## računanje vektorjev smeri in hitrosti

func forward_direction():
# smer vektorja "naprej"
	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))

func side_direction():
# smer vektorja "desno"
	return Vector2(cos(-get_rotation()), sin(get_rotation()))

func forward_velocity():
# smer in moč vektorja gor
	return forward_direction() * velocity.dot(forward_direction())

func side_velocity():
# smer in moč vektorja desno
	return side_direction() * velocity.dot(side_direction())
