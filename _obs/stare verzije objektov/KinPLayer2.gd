extends KinematicBody2D



var wheel_base = 16  # Distance from front to rear wheel
var steering_angle = 32  # Amount that front wheel turns, in degrees

var velocity = Vector2.ZERO
var steer_angle

var engine_power = 1800  # Forward acceleration force.

var acceleration = Vector2.ZERO

func get_input():
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
	steer_angle = turn * deg2rad(steering_angle)
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		acceleration = transform.x * engine_power
#	if Input.is_action_pressed("ui_down"):
#		acceleration = transform.x * -engine_power
	
func _physics_process(delta):
    acceleration = Vector2.ZERO
    get_input()
    calculate_steering(delta)
    velocity += acceleration * delta
    velocity = move_and_slide(velocity)

func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_angle) * delta
	var new_heading = (front_wheel - rear_wheel).normalized()
	velocity = new_heading * velocity.length()
	rotation = new_heading.angle()

