extends RigidBody2D

# ---------------------------------------------------------
# QUICK HOW-TO:
# - Make your changes in the Editor by selecting the Node
# - Add Input Map for all input strings in the Editor
# - NB: If you do not use Joystick Left/Right Triggers update Input code.
# - NB: If you do not use Left Joystick update Input code.
# ---------------------------------------------------------

# Joystick Deadzone Thresholds
var stick_min = 0.07 # If the axis is smaller, behave as if it were 0

# Driving Properties
export (int) var acceleration = 18 
export (int) var max_forward_velocity = 2000
export (float, 0, 1, 0.001) var drag_coefficient = 0.99 # Recommended: 0.99 - Affects how fast you slow down
export (float, 0, 10, 0.01) var steering_torque = 3.75 # Affects turning speed
#export (float, 0, 20, 0.1) var steering_damp = 20 # 7 - Affects how fast the torque slows down = angular damp

# Drifting & Tire Frictionhttps://coinmarketcap.com/
export (bool) var can_drift = true
export (float, 0, 1, 0.001) var wheel_grip_sticky = 0.85 # Default drift coef (will stick to road, most of the time)
export (float, 0, 1, 0.001) var wheel_grip_slippery = 0.99 # Affects how much you "slide"
export (int) var drift_extremum = 250 # Right velocity higher than this will cause you to slide
export (int) var drift_asymptote = 20 # During a slide you need to reduce right velocity to this to gain control
var _drift_factor = wheel_grip_sticky # Determines how much (or little) your vehicle drifts

# Vehicle velocity
var velocity = Vector2(0, 0)


### ---------------------------------------------------------------------------------------------------------------------------------------------


func _ready():
	
	set_gravity_scale(0.0)
#	set_angular_damp(steering_damp) # steering_damp = angular_damp


func _physics_process(delta):
	
	velocity *= drag_coefficient # 0 means we will never slow down ever
	
	# If we can drift
	if(can_drift):
		# If we are sticking to the road
		if(_drift_factor == wheel_grip_sticky):
			# If we exceed max stick velocity, begin sliding on the road
			if(get_right_velocity().length() > drift_extremum):
				_drift_factor = wheel_grip_slippery
				print("PRIJEM")
		
		# If we are sliding on the road
		else:
			# If our side velocity is less than the drift asymptote, begin sticking to the road
			if(get_right_velocity().length() < drift_asymptote):
				_drift_factor = wheel_grip_sticky
				print("DRIFTING")

		# Add drift to velocity
		velocity = get_up_velocity() + (get_right_velocity() * 1.2)
	
	if(Input.is_action_pressed("ui_up")):
		velocity += get_up() * acceleration
	elif(Input.is_action_pressed("ui_down")):
		velocity -= get_up() * acceleration

	# Prevent exceeding max velocity
	var max_speed = (Vector2(0, -1) * max_forward_velocity).rotated(get_rotation()) # getting a Vector2 that points up (the vehicle's default forward direction), and rotate it to the same amount our vehicle is rotated.
	var x = clamp(velocity.x, -abs(max_speed.x), abs(max_speed.x)) # Then we keep the magnitude of that direction which allows us to calculate the max allowed velocity in that direction.
	var y = clamp(velocity.y, -abs(max_speed.y), abs(max_speed.y))
	velocity = Vector2(x, y)
	
	
#	var torque = lerp(0, steering_torque, velocity.length() / max_forward_velocity) # apply torque only when moving
	
	if(Input.is_action_pressed("ui_left")):
		set_angular_velocity(-steering_torque)
	elif(Input.is_action_pressed("ui_right")):
		set_angular_velocity(steering_torque)
	else:
		set_angular_velocity(0) # se neha vrtet, ko spustimo
	
	# Apply the force
	set_linear_velocity(velocity)



# Returns up direction (vehicle's forward direction) ... dobimo smer kamor je obrnjen vektor naprej (kamor je usmerjeno "prednje kolo"
func get_up():
	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))

# Returns right direction (vehicle's side direction) ... dobimo ali + desno ali -desno
func get_right():
	return Vector2(cos(-get_rotation()), sin(get_rotation()))

# Returns up velocity (vehicle's forward velocity)
func get_up_velocity():
	return get_up() * velocity.dot(get_up())

# Returns right velocity (vehicle's side velocity)
func get_right_velocity():
	return get_right() * velocity.dot(get_right())
