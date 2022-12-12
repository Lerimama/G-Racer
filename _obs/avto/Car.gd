extends RigidBody2D


## 1. obračanje in potovanje prvega kolesa
## 2. povlečeš podatke o drugem kolesu (print to ček data)
## 3. dodaš kalkulacijo za celo telo

var car_heading; # končna smer avta smer avta ... presek smer fw in bw?  
#var fw_steer_angle; # kot koleasa gleda na kot avtomobila in bw
var fw_heading; # smer prvega kolesa 
var wheelBase; # medosna razdalja

var wheel_base = 64  # medosna razdalja
#var fw_rotation # smer prvega kolesa 


var carSpeed;

var breaking_power = -450
var max_speed_reverse = 250


var drag_coefficient = 0.95 # upor zraka
var drift_factor = 0.97 # prijemna cesti

#export (float, 0, 10, 0.01) var steering_torque = 3.75 # Affects turning speed
#export (float, 0, 20, 0.1) var steering_damp = 20 # 7 - Affects how fast the torque slows down = angular damp

# TRENUTNO V UPORABI
var fw_rotation : int = 0
var fw_start_angle = 0  # največja rotacija sprednjega kolesa per frame (radiani)
var fw_angle = 90  # največja rotacija sprednjega kolesa per frame (radiani)
var fw_max_angle = deg2rad(45)  # največja rotacija sprednjega kolesa per frame (radiani)

var velocity = Vector2.ZERO
var engine_power = 10  # Forward acceleration force.
var acceleration = Vector2.ZERO




func get_input():
#
#	var fw_rotation_multiplier = 0
#
#	if Input.is_action_pressed("ui_right"):
#		fw_rotation_multiplier += 1
##		set_angular_velocity(fw_rotation_multiplier)
#	if Input.is_action_pressed("ui_left"):
#		fw_rotation_multiplier -= 1
##		set_angular_velocity(fw_rotation_multiplier)
#
#	# obračanje prednjega kolesa
#	fw_rotation = fw_rotation_multiplier * deg2rad(fw_rotation_per_frame)
##	fw_rotation = fw_rotation_multiplier * fw_rotation_per_frame
#
##	velocity = Vector2.ZERO # na štartu je 0
#	velocity *= drag_coefficient
#
#	if Input.is_action_pressed("ui_up"):
##		velocity += get_up()* engine_power
#		acceleration = transform.y * engine_power
#	if Input.is_action_pressed("ui_down"):
##		velocity -= get_up()* engine_power
#		acceleration = transform.y * breaking_power
	pass
	
func _physics_process(delta):
	
#	NAJPREJ OBRNEM KOLO (SPRITE) V ŽELENI SMERI

	fw_rotation = 0

	if Input.is_action_pressed("ui_right"):
		fw_rotation += 1
	if Input.is_action_pressed("ui_left"):
		fw_rotation -= 1
		
#	$FrontWheel.rotation = lerp(0, fw_rotation, 0.1)	
	$FrontWheel.rotation = fw_rotation
	
#	POTEM PREMAKNEMO VOZILO V SMERI KOLESA	
	
	var fw_heading = rad2deg(fw_rotation)

	print("fw_rotation")
	print(fw_rotation)
	print(fw_heading)
	

	if(Input.is_action_pressed("ui_up")):
		velocity += transform.y*engine_power
	elif(Input.is_action_pressed("ui_down")):
		velocity -= transform.y*engine_power
	
	# Apply the force
	set_linear_velocity(velocity)
	set_angular_velocity(fw_rotation)
		

	
#	velocity *= drag_coefficient # 0 means we will never slow down ever
#
#	# If we can drift
#	if(can_drift):
#		# If we are sticking to the road
#		if(_drift_factor == wheel_grip_sticky):
#			# If we exceed max stick velocity, begin sliding on the road
#			if(get_right_velocity().length() > drift_extremum):
#				_drift_factor = wheel_grip_slippery
#				print("PRIJEM")
#
#		# If we are sliding on the road
#		else:
#			# If our side velocity is less than the drift asymptote, begin sticking to the road
#			if(get_right_velocity().length() < drift_asymptote):
#				_drift_factor = wheel_grip_sticky
#				print("DRIGTING")
#
#	# Add drift to velocity
#	velocity = get_up_velocity() + (get_right_velocity() * 0.1)
#
#	if(Input.is_action_pressed("ui_up")):
#		velocity += get_up() * acceleration
#	elif(Input.is_action_pressed("ui_down")):
#		velocity -= get_up() * acceleration
#
#	# Prevent exceeding max velocity
#	var max_speed = (Vector2(0, -1) * max_forward_velocity).rotated(get_rotation()) # getting a Vector2 that points up (the vehicle's default forward direction), and rotate it to the same amount our vehicle is rotated.
#	var x = clamp(velocity.x, -abs(max_speed.x), abs(max_speed.x)) # Then we keep the magnitude of that direction which allows us to calculate the max allowed velocity in that direction.
#	var y = clamp(velocity.y, -abs(max_speed.y), abs(max_speed.y))
#	velocity = Vector2(x, y)
#
#
#	var torque = lerp(0, steering_torque, velocity.length() / max_forward_velocity) # apply torque only when moving
#
#	if(Input.is_action_pressed("ui_left")):
#		set_angular_velocity(-torque)
#	elif(Input.is_action_pressed("ui_right")):
#		set_angular_velocity(torque)
#
#
#	# Apply the force
#	set_linear_velocity(velocity)
	
	


#	acceleration = Vector2.ZERO
#	get_input()
#	if fw_rotation >= fw_max_angle:
#		fw_rotation = 0
#
#
#	velocity *= drag_coefficient
#
##	$FrontWheel.rotation = fw_rotation
#
#	# obračanje prednjega kolesa
##	print("get_rotation()")
##	print(get_rotation())
#
#
#
#
#
#
#
#
##	fw_rotation = fw_rotation_multiplier * fw_rotation_per_frame
##	print(fw_heading)
#	velocity *= drag_coefficient
#
#	if Input.is_action_pressed("ui_up"):
##		velocity += get_up()* engine_power
#		acceleration = transform.y * engine_power
#	if Input.is_action_pressed("ui_down"):
##		velocity -= get_up()* engine_power
#		acceleration = transform.y * breaking_power
#
#
#
#
#
#
#	velocity += acceleration * delta
#	set_linear_velocity(acceleration)
#
##	print(velocity)
#	calculate_steering(delta)
##	velocity = move_and_slide(velocity)
	
	# Apply the force
#	set_angular_velocity(fw_rotation)
#	add_torque(fw_rotation)
#	$FrontWheel.rotation = fw_rotation
	
	
#	print("fw_rotation")
#	print(str(rad2deg(fw_rotation)) + " deg")
#	print(str(rad2deg($FrontWheel.get_rotation())) + " deg")
#	print("$BackWheel.rotation")
#	print($BackWheel.rotation)

# moje čaranje
#func fw_direction():
#	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))
#
#func bw_direction():
#	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))


# Returns up direction (vehicle's forward direction)
func get_up():
	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))

# Returns right direction
func get_right():
	return Vector2(cos(-get_rotation()), sin(get_rotation()))

# Returns up velocity (vehicle's forward velocity)
func get_up_velocity():
	return get_up() * velocity.dot(get_up())

# Returns right velocity
func get_right_velocity():
	return get_right() * velocity.dot(get_right())



func calculate_steering(delta):


#	1. Find the wheel positions.
#
#	Vector2 frontWheel = carLocation + wheelBase/2 * new Vector2( cos(carHeading) , sin(carHeading) );
#	Vector2 backWheel = carLocation - wheelBase/2 * new Vector2( cos(carHeading) , sin(carHeading) );
#
#	backWheel += carSpeed * dt * new Vector2(cos(carHeading) , sin(carHeading));
#	frontWheel += carSpeed * dt * new Vector2(cos(carHeading+steerAngle) , sin(carHeading+steerAngle));
#
#	carLocation = (frontWheel + backWheel) / 2;
#	carHeading = atan2( frontWheel.Y - backWheel.Y , frontWheel.X - backWheel.X );
#

	var fw_position : Vector2 = position + transform.x * wheel_base / 2.0
	var bw_position : Vector2 = position - transform.x * wheel_base / 2.0


#	2. Move the wheels forward.
	bw_position += velocity * delta
#	fw_position += velocity.rotated(fw_rotation) * delta

#	$FrontWheel.global_position = fw_position
#	$BackWheel.position = bw_position
#	$Car.position = (fw_position - bw_position).normalized()
#
#	3. Find the new direction vector.
	var new_heading = (fw_position - bw_position).normalized()

#	4. Set the velocity and rotation to the new direction.

#	velocity = new_heading * velocity.length()

	# tukaj ugotavljamo smer naprej / nazaj
	var d = new_heading.dot(velocity.normalized())

	# če gre naprej
	if d > 0:
		velocity = new_heading * velocity.length()

	# če gre nazaj
	if d < 0:
		velocity = -new_heading * velocity.length() # min(velocity.length(), max_speed_reverse)

	rotation = new_heading.angle()
