extends KinematicBody2D


# osnovno gibanje
export var axis_distance: int = 9 # medosna razdalja
export (int, 0, 1000) var engine_power = 500
export (int, 0, 180) var turn_angle = 15 # kot obrata per frame (stopinje)
export var free_rotation_multiplier = 20 # omogoča dovolj hitro rotacijo kadar je pri miru
export var max_speed_reverse = 70

var max_speed = 100 # _temp

# interakcija z okoljem
export (float, 0, 1.5) var friction = -1.0 # vpliv trenja s podlago (raste linearno s hitrostjo in vpliva na pospešek)
export (float, 0, 0.0010) var drag = -0.003 # vpliv upora zraka (raste kvadratno s hitrostjo in vpliva na končno hitrost)
export (float, 0, 0.1) var side_traction = 0.01 # vpliv na slajdanje ob zavoju ... manjši je, več je slajdanja
export (float, 0, 100) var mass = 10.0 # masa vpliva na vztrajnost plejerja
export (float, 0, 1) var bounce_size = 0.3 # velikost odboja		

# states
var fwd_motion: bool = false
var rev_motion: bool = false
var motion_enabled: bool = true
var weapon_reloaded: bool = true
var weapon_reload_time: float = 0.2

# notranje
var rotation_angle: float # obrat per frame v izbrani smeri
var rotation_dir: float
var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var collision: KinematicCollision2D
var bounce_angle: float

# adons
#var engine_particles = preload("res://player/EngineParticles.tscn") 
var engine_particles = preload("res://player/EngineParticles.tscn") 
var engine_particles_rear : CPUParticles2D
var engine_particles_rear_shadow : CPUParticles2D
var engine_particles_frontL : CPUParticles2D
var engine_particles_frontR : CPUParticles2D
var bullet = preload("res://player/weapons/Bullet.tscn")
#var bullet = preload("res://player/weapons/KinBullet.tscn")
var misile = preload("res://player/weapons/Misile.tscn")
var misile_loading_time: int = 120 # 60 je 1 sek
var loading_time: int = 0

# shadows
onready var sprite_texture = $Bolt.texture
var sprite_center: Vector2 = Vector2(-4.5,-5) # sprite offset
var shadow_offset: float = 5.0

var engines_alpha: float = 1.0
# trail
onready var BoltTrail = preload("res://player/BoltTrail2.tscn")

func _ready() -> void:
	
#	modulate = player_color
	add_to_group("Players")
	name = "P1"
	$Bolt.rotation_degrees = 90 # drugače je malo rotiran ... čudno?!
	
	engines_on()

	
func _process(delta: float) -> void:
	
	# partliki sledijo raketi
#	engine_particles_rear.global_position = $RearEnginePosition.global_position
#	engine_particles_frontL.global_position = $FrontEnginePositionL.global_position
#	engine_particles_frontR.global_position = $FrontEnginePositionR.global_position
#	engine_particles_rear.global_rotation = global_rotation
#	engine_particles_frontL.global_rotation = global_rotation - deg2rad(180)
#	engine_particles_frontR.global_rotation = global_rotation - deg2rad(180)	
	
	# for shadows
#	update()
	pass

	
func _physics_process(delta):
	
	# GIBANJE
	
	# partliki sledijo raketi
#	engine_particles_rear.position = $Bolt/RearEnginePosition_alt.position
	engine_particles_rear.position = $RearEnginePosition.global_position
	engine_particles_frontL.position = $FrontEnginePositionL.global_position
	engine_particles_frontR.position = $FrontEnginePositionR.global_position
#	engine_particles_rear.rotation = $Bolt/RearEnginePosition_alt.global_rotation
#	engine_particles_rear.rotation = $Bolt.global_rotation
	engine_particles_rear.rotation = global_rotation
	engine_particles_frontL.rotation = global_rotation - deg2rad(180)
	engine_particles_frontR.rotation = global_rotation - deg2rad(180)	
#	engine_particles_rear_shadow.global_position = $RearEnginePosition.global_position + Vector2(0,10)
#	engine_particles_rear_shadow.global_rotation = $RearEnginePosition.global_rotation
	acceleration = Vector2.ZERO # ko spustim gumb se resetira

	if motion_enabled:
		if Input.is_action_pressed("ui_up"):
			acceleration = transform.x * engine_power # transform.x je (-0, -1)
			
#			engine_particles_rear.global_position = $RearEnginePosition.global_position
			engine_particles_rear.set_emitting(true)
#			engine_particles_rear_shadow.set_emitting(true)
			fwd_motion = true
			
			var bolt_trail = BoltTrail.instance()
			AutoGlobal.effects_creation_parent.add_child(bolt_trail)
#			$BoltTrail.z_index(2)
			bolt_trail.add_points(global_position)
			$BoltTrail.add_points(global_position)
#			$BoltTrail.modulate = Color.rebeccapurple
			
		elif Input.is_action_just_released("ui_up"):
			engine_particles_rear.set_emitting(false)
#			engine_particles_rear_shadow.set_emitting(false)
			fwd_motion = false
			$BoltTrail.clear_points()
		if Input.is_action_pressed("ui_down"):
			rev_motion = true
			acceleration = transform.x * -engine_power
			engine_particles_frontL.set_emitting(true)
			engine_particles_frontR.set_emitting(true)
		elif Input.is_action_just_released("ui_down"):
			rev_motion = false
			engine_particles_frontR.set_emitting(false)
			engine_particles_frontL.set_emitting(false)
	
	rotation_dir = Input.get_axis("ui_left", "ui_right") # +1, -1 ali 0
	rotation_angle = rotation_dir * deg2rad(turn_angle) # vsak frejm se obrne za toliko
	
	apply_friction(delta) # preračunam "acceleration"
	calculate_steering(delta) # preračunam "rotacijo"
	
	velocity += acceleration * delta
#	velocity.x = clamp(velocity.x, -max_speed, max_speed)
#	velocity.y = clamp(velocity.y, -max_speed, max_speed)
	collision = move_and_collide(velocity * delta, false) # infinite_inertia = false

	# rotacija
	if Input.is_action_pressed("ui_down") == false && Input.is_action_pressed("ui_up") == false: # ko pogon ne deluje in je na mestu
		rotate(delta * rotation_angle * free_rotation_multiplier)
	else:
		rotate(delta * rotation_angle) # v gibanju	
	
	
	# KOLIZIJE
	
	if collision:
		velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
		bounce_angle = collision.normal.angle_to(velocity)	
		
	
	# ŠUTING
	if Input.is_action_just_pressed("pavza"):
		$CPUParticles2D.global_position = $Bolt.global_position
		$CPUParticles2D.global_rotation = $Bolt.global_rotation
		$CPUParticles2D.set_one_shot(true)
		$CPUParticles2D.set_emitting(true)
		$Bolt.modulate.a = 0
#		$CPUParticles2D.set_emitting(false)
		
		
	if Input.is_action_just_pressed("space") && weapon_reloaded == true:
		$Bolt.modulate.a = 1
#		var new_misile = misile.instance()
#		new_misile.position = $GunPosition.global_position
#		new_misile.rotation = global_rotation
#		add_child(new_misile)
#		new_misile.owner = self
#		new_misile.connect("get_hit", self, "on_got_hit")		
		var new_bullet = bullet.instance()
		new_bullet.position = $GunPosition.global_position
		new_bullet.rotation = global_rotation
		add_child(new_bullet)
		new_bullet.owner = self
		print(new_bullet.modulate)
#		new_bullet.connect("Get_hit", self, "on_got_hit")		
		
		# reload weapon
		weapon_reloaded = false
		yield(get_tree().create_timer(weapon_reload_time), "timeout")
		weapon_reloaded= true
		
		
	if Input.is_action_pressed("space"):
		
		loading_time += 1
		
		if loading_time == misile_loading_time:

			var new_misile = misile.instance()
			new_misile.position = $GunPosition.global_position
			new_misile.rotation = global_rotation
			add_child(new_misile)
			new_misile.owner = self
			new_misile.connect("get_hit", self, "on_got_hit")		
	
	if Input.is_action_just_released("space"):
			loading_time = 0


func apply_friction(delta):
	
	if velocity.length() < 5: # če je hitrost res majhna naj se kar ustavi, da ne bo neskončno računal
		velocity = Vector2.ZERO
	
	var friction_force = velocity * friction # linearna rast s hitrostjo
	var drag_force = velocity * velocity.length() * drag # ekspotencialno naraščanje, zato je velocity na kvadrat
	
	acceleration += drag_force + friction_force


func calculate_steering(delta):
	
	# lokacija sprednje in zadnje osi
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	# nova smer je seštevek smeri obeh osi
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	# smer gibanja
	if fwd_motion:
		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction) # željeno smer gibanja doseže z zamikom "side-traction"
#		print (velocity.length())
	elif rev_motion:
#		velocity = velocity.linear_interpolate(-new_heading * velocity.length(), side_traction) # brez omejitve
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.1)
#		print (velocity.length())
		
	rotation = new_heading.angle() # sprite se obrne v smeri
	
	
func engines_on():
	# ENGINES ON
	
	engine_particles_rear = engine_particles.instance()
#	engine_particles_rear.set_as_toplevel(true) # načeloma ne rabi, ampak se mi občasno pokaže kar nekje
	engine_particles_rear.modulate.a = engines_alpha
	engine_particles_rear.global_position = $RearEnginePosition.global_position
	AutoGlobal.effects_creation_parent.add_child(engine_particles_rear)
	
	# senca partiklov
#	engine_particles_rear_shadow = engine_particles.instance()
#	engine_particles_rear_shadow.modulate = Color.black
#	engine_particles_rear_shadow.global_position = $RearEnginePosition.global_position
#	engine_particles_rear_shadow.set_as_toplevel(true)
##	engine_particles_rear_shadow.modulate.a = engines_alpha - 0.2
#	AutoGlobal.effects_creation_parent.add_child(engine_particles_rear_shadow)
	
	engine_particles_frontL = engine_particles.instance()
	engine_particles_frontL.set_as_toplevel(true)
	engine_particles_frontL.emission_rect_extents = Vector2.ZERO
	engine_particles_frontL.amount = 20
	engine_particles_frontL.initial_velocity = 50
	engine_particles_frontL.lifetime = 0.05
	engine_particles_frontL.modulate.a = engines_alpha
	AutoGlobal.effects_creation_parent.add_child(engine_particles_frontL)
	
	engine_particles_frontR = engine_particles.instance()
	engine_particles_frontR.set_as_toplevel(true)
	engine_particles_frontR.emission_rect_extents = Vector2.ZERO
	engine_particles_frontR.amount = 20
	engine_particles_frontR.initial_velocity = 50
	engine_particles_frontR.lifetime = 0.05
	engine_particles_frontR.modulate.a = engines_alpha
	AutoGlobal.effects_creation_parent.add_child(engine_particles_frontR)

	
func on_got_hit(collision_location, bullet_velocity):
#	queue_free()
	
	print ("plejer šot")
	
	pass


# for shadow
#func _draw():
#
#	var shadow_position: Vector2
#	var sprite_angle: float
#
#	sprite_angle = rotation + rad2deg(90) # z dodatkom 90 stopinj dobimo vetikalni zamik 
#	shadow_position.x = sprite_center.x - (shadow_offset * sin(sprite_angle)) # seštevanje ali odštevanje določa gor ali dol
#	shadow_position.y = sprite_center.y - ((shadow_offset) * cos(sprite_angle))
#
#	draw_set_transform(Vector2.ZERO, deg2rad(90), Vector2.ONE)
#	draw_texture(sprite_texture, shadow_position, Color( 0, 0, 0, 0.3 ))
