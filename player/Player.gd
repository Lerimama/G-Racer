extends KinematicBody2D


# osnovno gibanje
export var axis_distance: int = 9 # medosna razdalja
export (int, 0, 1000) var engine_power = 500
export (int, 0, 180) var turn_angle = 15 # kot obrata per frame (stopinje)
export var free_rotation_multiplier = 20 # omogoča dovolj hitro rotacijo kadar je pri miru
export var max_speed_reverse = 120
export var max_speed = 100 # _temp
export var force_stop_velocity: int = 8

# interakcija z okoljem
export (float, 0, 1.5) var friction = -1.0 # vpliv trenja s podlago (raste linearno s hitrostjo in vpliva na pospešek)
export (float, 0, 0.0010) var drag = -0.003 # vpliv upora zraka (raste kvadratno s hitrostjo in vpliva na končno hitrost)
export (float, 0, 0.1) var side_traction = 0.01 # vpliv na slajdanje ob zavoju ... manjši je, več je slajdanja
export (float, 0, 100) var mass = 10.0 # masa vpliva na vztrajnost plejerja
export (float, 0, 1) var bounce_size = 0.3 # velikost odboja		

var velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO

var rotation_angle: float # obrat per frame v izbrani smeri
var rotation_dir: float
var bounce_angle: float
var collision: KinematicCollision2D

# motion states
var fwd_motion: bool = false # za ločitev ali gre v rikverc ali naprej
var rev_motion: bool = false
var motion_enabled: bool = true # za nedelovanje naprej/nazaj ... input disable bilo bolje

# partikli pogona
var engine_particles_rear : CPUParticles2D
var engine_particles_frontL : CPUParticles2D
var engine_particles_frontR : CPUParticles2D

# trail
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni , potem je "odklopljena"
var new_bolt_trail: Object
var bolt_trail_stop_velocity: int = 80

# weapons
var bullet_reloaded: bool = true
var bullet_reload_time: float = 0.2
var misile_reloaded: bool = true
var misile_reload_time: float = 1.0
var new_misile: Node2D
#var new_blast: Node2D

# shield
var shields_on = false

# shadows
var sprite_center: Vector2 = Vector2(-4.5,-5) # sprite offset
var shadow_offset: float = 5.0
var engines_alpha: float = 1.0
onready var BoltTexture = $Bolt.texture


# import
onready var BoltSprite: Sprite = $Bolt # za korekcijo kota
onready var RearEnginePos: Position2D = $RearEnginePosition
onready var FrontEnginePosL: Position2D = $FrontEnginePositionL
onready var FrontEnginePosR: Position2D = $FrontEnginePositionR
onready var GunPosition: Position2D = $GunPosition

onready var ExplodingBolt: PackedScene = preload("res://player/ExplodingBolt.tscn")
onready var CollisionParticles: PackedScene = preload("res://player/fx/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://player/fx/EngineParticles.tscn") 
onready var BoltTrail: PackedScene = preload("res://player/fx/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://player/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://player/weapons/Misile.tscn")
onready var Blast: PackedScene = preload("res://player/weapons/Blast.tscn")


func _ready() -> void:
	
	add_to_group("Players")
	name = "P1"
	BoltSprite.rotation_degrees = 90 # drugače je malo rotiran ... čudno?!
	
	$shield.modulate.a = 0
	
	engines_setup() # postavi partikle za pogon
	
	
func _process(delta: float) -> void:
	
	# za senčke
#	update()

	# updejt položaja pogona 
	engine_particles_rear.position = RearEnginePos.global_position
	engine_particles_frontL.position = FrontEnginePosL.global_position
	engine_particles_frontR.position = FrontEnginePosR.global_position
	engine_particles_rear.rotation = RearEnginePos.global_rotation
	engine_particles_frontL.rotation = FrontEnginePosL.global_rotation - deg2rad(180)
	engine_particles_frontR.rotation = FrontEnginePosR.global_rotation - deg2rad(180)	
	
	
func _physics_process(delta: float) -> void:
	
	# reset accelaration
	acceleration = Vector2.ZERO
		
	# force stop
	if velocity.length() < force_stop_velocity: # če je hitrost res majhna ... 
		velocity = Vector2.ZERO # ...naj se kar ustavi, da ne bo neskončno računal pozicije
	
	if motion_enabled:
		input_motion(delta)
			
	rotation_angle = rotation_dir * deg2rad(turn_angle) # vsak frejm se obrne za toliko
	
	
	apply_friction(delta) # adaptacija "acceleration"
	calculate_steering(delta) # adaptacija "rotacijo"
	
	velocity += acceleration * delta
	
	
	collision = move_and_collide(velocity * delta, false) # infinite_inertia = false
	
	if collision:
		velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
		bounce_angle = collision.normal.angle_to(velocity)	
	
		# odbojni partikli
		if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
			var new_collision_particles = CollisionParticles.instance()
			new_collision_particles.position = collision.position
			new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
			new_collision_particles.set_emitting(true)
			AutoGlobal.effects_creation_parent.add_child(new_collision_particles)
		
	input_shooting(delta)
	add_trail_points()


func input_motion(delta: float) -> void:
	
	if Input.is_action_pressed("up"):
		acceleration = transform.x * engine_power # transform.x je (-0, -1)
		fwd_motion = true
		engine_particles_rear.set_emitting(true)
	
		# spawn trail
		if bolt_trail_active == false && velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			AutoGlobal.effects_creation_parent.add_child(new_bolt_trail)
			new_bolt_trail.connect("BoltTrail_is_gone", self, "deactivate_trail")
			bolt_trail_active = true 
		
		
	elif Input.is_action_just_released("up"):
		fwd_motion = false
		engine_particles_rear.set_emitting(false)
			
	if Input.is_action_pressed("down"):
		acceleration = transform.x * -engine_power
		rev_motion = true
		engine_particles_frontL.set_emitting(true)
		engine_particles_frontR.set_emitting(true)
	
		# spawn trail
		if bolt_trail_active == false && velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			AutoGlobal.effects_creation_parent.add_child(new_bolt_trail)
			new_bolt_trail.connect("BoltTrail_is_gone", self, "deactivate_trail")
			bolt_trail_active = true 
	
	elif Input.is_action_just_released("down"):
		rev_motion = false
		engine_particles_frontR.set_emitting(false)
		engine_particles_frontL.set_emitting(false)
	
	rotation_dir = Input.get_axis("left", "right") # +1, -1 ali 0

	# prosto vrtenje
	if Input.is_action_pressed("down") == false && Input.is_action_pressed("up") == false: # ko ni gasa niti bremze
		rotate(delta * rotation_angle * free_rotation_multiplier)
	else: # v gibanju
		rotate(delta * rotation_angle) 
	
	
func input_shooting(delta: float) -> void:
	
	# bullet	
	if Input.is_action_just_pressed("shoot_bullet") && bullet_reloaded == true:

#		velocity -= velocity/1.3 # ...naj se kar ustavi, da ne bo neskončno računal pozicije

		
		var new_bullet = Bullet.instance()
		new_bullet.position = GunPosition.global_position
		new_bullet.rotation = global_rotation
		AutoGlobal.node_creation_parent.add_child(new_bullet)
#		new_bullet.owner = self
#		new_bullet.connect("Get_hit", self, "on_got_hit")		
		
		# reload weapon
		bullet_reloaded = false
		yield(get_tree().create_timer(bullet_reload_time), "timeout")
		bullet_reloaded= true
	
	# misile
	if Input.is_action_just_released("shoot_misile") && misile_reloaded == true:	
#	if Input.is_action_just_pressed("shoot_misile") && misile_reloaded == true:	
		
		# pushback
#		velocity -= velocity/0.7 # ...naj se kar ustavi, da ne bo neskončno računal pozicije
		
		new_misile = Misile.instance()
		new_misile.position = GunPosition.global_position
		new_misile.rotation = global_rotation
		AutoGlobal.node_creation_parent.add_child(new_misile)
#		new_misile.connect("get_hit", self, "on_got_hit")		
#		new_misile.owner = self
#		new_misile.is_homming = false
		
		# reload weapon
		misile_reloaded = false
		yield(get_tree().create_timer(misile_reload_time), "timeout")
		misile_reloaded= true	
	
	# blast
	if Input.is_action_just_released("shoot_bomb"):	
		
		# pushback
#		velocity -= velocity/0.7 # ...naj se kar ustavi, da ne bo neskončno računal pozicije
		
		var new_blast = Blast.instance()
		new_blast.position = GunPosition.global_position
		new_blast.rotation = global_rotation
		AutoGlobal.node_creation_parent.add_child(new_blast)
#		new_misile.connect("get_hit", self, "on_got_hit")		
#		new_misile.owner = self
#		new_misile.is_homming = false
		
		# reload weapon
		misile_reloaded = false
		yield(get_tree().create_timer(misile_reload_time), "timeout")
		misile_reloaded= true		
	
	# explode
	if Input.is_action_just_pressed("bolt_explode"):
		explode()
	
	if Input.is_action_just_pressed("bolt_reset"):
		reset_player()
		
	if Input.is_action_just_pressed("shield_toggle"):
		
		if shields_on == false:
			$AnimationPlayer.play("shield_on")
			shields_on = true
		else:
			$AnimationPlayer.play_backwards("shield_on")
#			$shield.visible = false
			shields_on = false
		
			
func engines_setup(): # spawnamo paritkle pogona
	
	# naprej
	engine_particles_rear = EngineParticles.instance()
	engine_particles_rear.position = RearEnginePos.global_position
	engine_particles_rear.rotation = RearEnginePos.global_rotation
	engine_particles_rear.modulate.a = engines_alpha
	AutoGlobal.effects_creation_parent.add_child(engine_particles_rear)
	
	# rikverc levo
	engine_particles_frontL = EngineParticles.instance()
	engine_particles_frontL.emission_rect_extents = Vector2.ZERO
	engine_particles_frontL.amount = 20
	engine_particles_frontL.initial_velocity = 50
	engine_particles_frontL.lifetime = 0.05
	engine_particles_frontL.position = FrontEnginePosL.global_position
	engine_particles_frontL.rotation = FrontEnginePosL.global_rotation - deg2rad(180)
	engine_particles_frontL.modulate.a = engines_alpha
	AutoGlobal.effects_creation_parent.add_child(engine_particles_frontL)
	
	# rikverc desno
	engine_particles_frontR = EngineParticles.instance()
	engine_particles_frontR.emission_rect_extents = Vector2.ZERO
	engine_particles_frontR.amount = 20
	engine_particles_frontR.initial_velocity = 50
	engine_particles_frontR.lifetime = 0.05
	engine_particles_frontR.position = FrontEnginePosR.global_position
	engine_particles_frontR.rotation = FrontEnginePosR.global_rotation - deg2rad(180)	
	engine_particles_frontR.modulate.a = engines_alpha
	AutoGlobal.effects_creation_parent.add_child(engine_particles_frontR)

		
func apply_friction(delta: float) -> void:
	
	var friction_force = velocity * friction # linearna rast s hitrostjo
	var drag_force = velocity * velocity.length() * drag # ekspotencialno naraščanje, zato je velocity na kvadrat
	
	acceleration += drag_force + friction_force


func calculate_steering(delta: float) -> void:
	
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
	elif rev_motion:
		# velocity = velocity.linear_interpolate(-new_heading * velocity.length(), side_traction) # brez omejitve
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.1)
		
	rotation = new_heading.angle() # sprite se obrne v smeri
	
		
func add_trail_points():
	
	if bolt_trail_active == true:
		if velocity.length() > 0:
			new_bolt_trail.add_points(global_position)
		elif velocity.length() == 0 && Input.is_action_pressed("ui_up") == false && Input.is_action_pressed("ui_down") == false: # "input" je, da izločim za hitre prehode med naprej nazaj
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func explode():
	
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = BoltSprite.global_rotation
#	new_exploding_bolt.modulate = Color.red
	new_exploding_bolt.modulate = modulate
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	AutoGlobal.node_creation_parent.add_child(new_exploding_bolt)
	
	print ("DISAPEAR - Player")
#	queue_free()
	visible = false


func reset_player():
	visible = true

# SIGNALI

func on_got_hit(collision_location: Vector2, bullet_velocity: Vector2):
	

#	print ("DISAPEAR - Player")
#	queue_free()
	print ("plejer šot")
	pass


# SHADOWS
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
