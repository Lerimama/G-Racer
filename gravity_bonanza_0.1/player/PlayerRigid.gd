extends RigidBody2D


# osnovno gibanje
export var axis_distance: int = 32  # medosna razdalja
export (int, 0, 1000) var engine_power = 800
export (int, 0, 180) var turn_angle = 15  # kot obrata per frame (stopinje)
export var free_rotation_multiplier = 10 # omogoča dovolj hitro rotacijo kadar je gas na 0
#export (float, 0, 100) var mass = 10
export (float, 0, 1) var bounce_size = 0.3		
#export var max_speed_reverse : int = 300
var collision: KinematicCollision2D
var bounce_angle

# vpliv okolja
#export (float, 0, 1.5) var friction = -1 # vpliv trenja s podlago (raste linearno s hitrostjo in vpliva na pospešek)
export (float, 0, 0.0010) var drag = -0.0001 # vpliv upora zraka (raste kvadratno s hitrostjo in vpliva na končno hitrost)
export (float, 0, 1) var side_traction = 0.2

# driftanje
#var slip_speed : int = 700 # hitrost nad katero začne driftat
#var traction_fast : float = 0.1 # ko drsi
#var traction_slow : float = 0.5 # ko ne drsi

# state machine
var test_state : bool = false
var fwd_motion: bool = false
var rev_motion: bool = false
var motion_enabled: bool = true #old

# notranje
var rotation_angle: float # "kot obrata per frame" v določeni smeri (levo ali desno)
var rotation_dir: float
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO


####################################################################################################################################


func _ready() -> void:
	
	# smer ob štartu
	rotation = deg2rad(-90)
#	modulate = player_color
#	add_to_group("players")
	
	
func _process(delta: float) -> void:
	$Particles2D.emitting = true
	$Particles2D.emitting = false
	
	
	
func _physics_process(delta):
	
	acceleration = Vector2.ZERO # ko spustim gumb se resetira
	
	if motion_enabled == true:
		if Input.is_action_pressed("ui_up"):
			acceleration = transform.x * engine_power # transform.x je (-0, -1)
			fwd_motion = true
		elif Input.is_action_just_released("ui_up"):
			fwd_motion = false
		if Input.is_action_pressed("ui_down"):
			acceleration = transform.x * -engine_power
			rev_motion = true
		elif Input.is_action_just_released("ui_down"):
			rev_motion = false
			$Particles2D.emitting = true
		
		
	rotation_dir = 1 # ko spustim gumb se resetira ... neki ne  vpliva?
	rotation_dir = Input.get_axis("ui_left", "ui_right") # +1 ali -1
	
	if rotation_dir == 1:
		$AnimatedSprite.play("Desno", false) # animacija desno, rewind false
	elif rotation_dir == -1:
		$AnimatedSprite.play("Levo", false) # animacija levo, rewind false
	elif rotation_dir == 0:
		$AnimatedSprite.stop() # animacija desno, rewind false
		$AnimatedSprite.set_frame(0) # animacija desno, rewind false
		
	rotation_angle = rotation_dir * deg2rad(turn_angle) # vsak frejm se obrne za toliko
	
	
	# GIBANJE -------------------------------------------------------------------------------------
	
	apply_friction(delta)
	calculate_steering(delta)
	
	velocity += acceleration * delta
#	velocity = move_and_slide(velocity)
#	collision = move_and_collide(velocity * delta, false) # infinite_inertia = false


	# rotacija 
	if rev_motion == false && fwd_motion == false: # ko pogon ne deluje
		rotate(delta * rotation_angle * free_rotation_multiplier)
	else:	# ko pogon ne deluje
		rotate(delta * rotation_angle)	
	
			
#	if test_state:
#		rotate(delta)	
#		print(rotation_angle)
	
	# KOLIZIJE -------------------------------------------------------------------------------------
	
	
	if collision:
		test_state = true
		velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
		bounce_angle = collision.normal.angle_to(velocity)	
		$redline.global_position = collision.collider.get_collision_pos()
		$greenline.global_position = global_position
		
		
		# rigid body
		if collision.collider.is_class("RigidBody2D"):

			# vztrajnost telesa
			var collider_mass: float = collision.collider.get("mass")
			var collider_velocity: Vector2 = collision.collider.get("linear_velocity")
			var collider_inertia: Vector2 = collider_velocity * collider_mass

			#vztrajnost plejerja
			var player_inertia: Vector2 = velocity * mass

			# odboj telesa
			collision.collider.apply_central_impulse(-collision.normal * player_inertia) # odboj rigidnega telesa glede na našo inercijo

			# odboj plejerja
			velocity = velocity + collider_inertia

	if test_state:
#		if rad2deg(bounce_angle) < 0:
#			rotate(delta*-bounce_angle*10)	
#		elif rad2deg(bounce_angle) > 0:
#			rotate(delta*bounce_angle)
		
		
		
		$redline.rotation_degrees = rad2deg(bounce_angle) + 90
		$greenline.rotation_degrees = rad2deg(rotation_angle)
		
		
		
		
# vplivi okolja	
func apply_friction(delta):
	
	# če je hitrost res majhna naj se kar ustavi, da ne bo neskončno računal
	if velocity.length() < 5: 
		velocity = Vector2.ZERO
	
	# trenje in upor	
	var friction_force = velocity * friction # linearna rast s hitrostjo
	var drag_force = velocity * velocity.length() * drag # ekspotencialno naraščanje, zato je velocity na kvadrat
	
	# pri nižjih hitrostih je trenje bolj očitno ... počasen štart 
#	if velocity.length() < 100:
#		friction_force *= 5 # do 6.6 še deluje
	
	acceleration += drag_force + friction_force

	
# adaptcija za zavijanje po tirnici 
func calculate_steering(delta):
	
	# lokacija sprednje in zadnje osi
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	# nova smer je seštevek smeri obeh osi
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	# driftanje
#	var traction = traction_slow
#	if velocity.length() > slip_speed: # ko presežemo določeno hitrost začne drset
#		traction = traction_fast
#	if velocity.length() == 0: # ko presežemo določeno hitrost začne drset
#		traction = no_taction
#	print (traction)
	
	if fwd_motion == true: # gremo naprej
		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction) # željeno smer gibanja doseže z zamikom (ker slajda) glede na "traction"
	elif rev_motion == true:
		velocity = velocity.linear_interpolate(-new_heading * velocity.length(), side_traction)
#		velocity = -new_heading * min(velocity.length(), max_speed_reverse) # omejitev hitrosti
	
	rotation = new_heading.angle() # sprite se obrne v smeri
	
#	# dot produkt, da ugotovimo ali se gibamo rikverc ali naprej
#	var d = new_heading.dot(velocity.normalized()) # ugotavljamo ali gre rikverc al naprej
#	if engine_on:
#		if d > 0: # gremo naprej
##			velocity = new_heading * velocity.length() # moč gibanja pomnožimo z smerjo gibanja
#			velocity = velocity.linear_interpolate(new_heading * velocity.length(), traction) # željeno smer gibanja doseže z zamikom (ker slajda) glede na "traction"
#		if d < 0: # gremo v rikverc
#			velocity = -new_heading * min(velocity.length(), max_speed_reverse) # moč gibanja pomnožimo z smerjo
#		rotation = new_heading.angle() # sprite se obrne v smeri

