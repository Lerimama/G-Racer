extends RigidBody2D

var steering_com = 0.0
var force_com = 1.0

#var force_com = Vector2(8.0, 12.0)
#var steering_com = Vector2(-512, 512)

#func _ready():
#    set_process_input(true)
##    set_fixed_process(true)
##    var shape = RectangleShape2D.new()
##    shape.set_extents(Vector2(8, 20))
##    add_shape(shape)
#



#### GODOT DOCS CASE
var thrust = Vector2(0, 150)
var torque = 150

func _integrate_forces(state):
	if Input.is_action_pressed("ui_up"):
		applied_force = -thrust.rotated(rotation)
	else:
		applied_force = Vector2()
	var rotation_dir = 0
	if Input.is_action_pressed("ui_right"):
		rotation_dir += 1
	if Input.is_action_pressed("ui_left"):
		rotation_dir -= 1
	applied_torque = rotation_dir * torque

#func _physics_process(delta: float) -> void:
#
#	var obj_global_transform = get_global_transform()
#	var obj_linear_velocity = get_linear_velocity()
#
#	#   get the orthogonal velocity vector
#	var right_velocity = obj_global_transform.x * obj_global_transform.x.dot(obj_linear_velocity)
#
#	#   decrease the force in proportion to the velocity to stop endless acceleration
#	var force = force_com - force_com * clamp(obj_linear_velocity.length() / 400.0, 0.0, 1.0)
#	var steering_torque = steering_com
#
#	if obj_global_transform.y.dot(obj_linear_velocity) < 0.0:
#
#	#   if reversing, reverse the steering
#		steering_torque = -steering_com
#
#	#   make reversing much slower
#	if force_com <= 0.0:
#		force *= 0.1
#
#	#   apply the side force, the lower this is the more the car slides
#	#   make the sliding depend on the power command somewhat
#	apply_impulse(Vector2(), -right_velocity * 0.07 * clamp(1.0 / abs(force), 0.01, 1.0))
#	apply_impulse(Vector2(), obj_global_transform.basis_xform(Vector2(0, force)))
#
#	#   scale the steering torque with velocity to prevent turning the car when not moving
#	set_applied_torque(steering_torque * obj_linear_velocity.length() / 200.0)


