extends RigidBody2D


# moving like rocket
export (int) var engine_thrust = 150
export (int) var spin_thrust = 150

var thrust = Vector2()
#var spin_thrust = engine_thrust * spin_thrust_eq
var rotation_dir = 0
var screensize
var damp : = 0.0

var lokacija_rakete : Transform2D
var lokacija_ikone : Transform2D
#var speed = 0


func _ready():
	screensize = get_viewport().get_visible_rect().size
	angular_damp = 2.0
	var speeed = linear_velocity
	
func get_input():
	if Input.is_action_pressed("ui_up"):
		print("gor")
		thrust = Vector2(engine_thrust, 0)
#		position += transform.x * 2
	else:
		thrust = Vector2()


	if Input.is_action_pressed("ui_down"):
		print("gor")
		thrust = Vector2(-engine_thrust/2, 0)
#		speed -= 0.2
#		position += transform.x * 10
		
	rotation_dir = 0
	if Input.is_action_pressed("ui_right"):
		print("desno")
		rotation_dir += 1
		print("rotation_dir")
		print(rotation_dir)
	if Input.is_action_pressed("ui_left"):
		print("levo")
		rotation_dir -= 1
#	if Input.is_action_just_released("ui_left"):
#		spin_thrust = 0
#		rotation_dir = 0
			
func _process(delta):

#	print("speed")
##	print(speed)
#	print(angular_damp)
#	print("speed")
	
	get_input()


#func _physics_process(delta):
#	$WingFront.set_applied_force(thrust.rotated(rotation))
#	$WingBack.set_applied_force(thrust.rotated(rotation))
#	$WingFront.set_applied_torque(rotation_dir * spin_thrust)
#
	
func _integrate_forces(state):
	
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(rotation_dir * spin_thrust)
	
#	global_position = $WingFront.global_position
#	$WingFront.set_applied_force(thrust.rotated(rotation))
#	$WingFront.set_applied_torque(rotation_dir * spin_thrust)
##	$WingBack.set_applied_force(thrust.rotated(rotation))
	
#	lokacija_rakete = get_transform()
#	$WingFront.set_transform(lokacija_rakete)
	print("lokacija_rakete")
	print(lokacija_rakete)
	print($WingFront.get_transform())

	# wraparund camera
	var xform = state.get_transform()
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	if xform.origin.x < 0:
		xform.origin.x = screensize.x
	if xform.origin.y > screensize.y:
		xform.origin.y = 0
	if xform.origin.y < 0:
		xform.origin.y = screensize.y
	state.set_transform(xform)
