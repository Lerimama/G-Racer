extends KinematicBody2D


# player data
export var player_name: String = "P1"
var player_color: Color = Config.color_blue
export var health: int = 10
export var life: int = 3
var camera_follow: bool = false

# bolt data
export var axis_distance: int = 9
export var engine_power: int = 250
export var turn_angle: int = 15 # deg per frame
export var rotation_multiplier: int = 15 # rotacija kadar miruje
export var top_speed_reverse: int = 50
export (float, 0, 10) var drag: float = 1.0 # raste kvadratno s hitrostjo
export (float, 0, 1) var side_traction: float = 0.1
export (float, 0, 1) var bounce_size: float = 0.3		

# camerashakes
export (float, 0, 1) var bolt_explosion_shake = 1
export (float, 0, 1) var bullet_hit_shake = 0.2
export (float, 0, 1) var misile_hit_shake = 0.4

var input_power: float
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D

var power_fwd: bool
var power_rev: bool
var no_power: bool
var control_enabled: bool = true
var on_hit_disabled_time: float = 1.5

var bullet_reloaded: bool = true
var bullet_reload_time: float = 0.2
var bullet_push_factor: float = 0.1 # kako močen je potisk metka ... delež hitrosti metka
var misile_count = 5
var misile_reloaded: bool = true
var misile_reload_time: float = 1.0
var misile_push_factor = 0.5 # push eksplozije
var shocker_count = 3
var shocker_reload_time: float = 1.0
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trneutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 3
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni, potem je "odklopljena"
var new_bolt_trail: Object

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var camera = Global.current_camera
onready var gun_position = $Bolt/GunPosition
onready var rear_engine_position = $Bolt/RearEnginePosition
onready var front_engine_position_L = $Bolt/FrontEnginePositionL
onready var front_engine_position_R = $Bolt/FrontEnginePositionR

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")


func _ready() -> void:
	
	add_to_group(Config.group_players)
	add_to_group(Config.group_bolts)
	name = player_name
	
	bolt_sprite.modulate = player_color
	bolt_collision.disabled = false
	
	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield.self_modulate = player_color 
	shield_collision.disabled = true 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)

	
func _input(event: InputEvent) -> void:
	
	if control_enabled:
		input_power = Input.get_action_strength("w") - Input.get_action_strength("s") # +1, -1 ali 0
		
		rotation_dir = Input.get_axis("a", "d") # +1, -1 ali 0	
		
		if Input.is_action_just_pressed("F"):
			shooting("Bullet")
		if Input.is_action_just_released("G"):	
			shooting("Misile")
		if Input.is_action_just_released("H"):	
			shooting("Shocker")
		if Input.is_action_just_pressed("x"):
			shooting("Shield")
#		if Input.is_action_just_pressed("x"):
#			explode_and_reset()


func state_machine(delta):
	
	#motion states
	if input_power > 0 and control_enabled:
		power_fwd = true
		power_rev = false
		no_power = false
	elif input_power < 0 and control_enabled:
		power_fwd = false
		power_rev = true
		no_power = false
	elif input_power == 0 or not control_enabled:
		power_fwd = false
		power_rev = false
		no_power = true
			
		
func _physics_process(delta: float) -> void:
	
	state_machine(delta)
		
	acceleration = input_power * transform.x * engine_power # transform.x je (-1, 0)
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
	acceleration -= drag_force
	velocity += acceleration * delta
	
	if no_power and velocity.length() < 5: # da ne bo neskončno računal pozicije
		velocity = Vector2.ZERO 
	
	rotation_angle = rotation_dir * deg2rad(turn_angle)
	if no_power: 
		rotate(delta * rotation_angle * rotation_multiplier)
	else: 
		rotate(delta * rotation_angle)
	
	steering(delta)
	
	collision = move_and_collide(velocity * delta, false)
	
	if collision:
		on_collision()
	
	motion_fx(delta)
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru

	# camera follow
	if camera_follow:
		camera.position = position
	
	
func motion_fx(delta):
	
	if power_fwd:
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.position = rear_engine_position.global_position
		engine_particles_rear.rotation = rear_engine_position.global_rotation
		
		# spawn trail
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	if power_rev:
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.position = front_engine_position_L.global_position
		engine_particles_front_left.rotation = front_engine_position_L.global_rotation - deg2rad(180)
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.position = front_engine_position_R.global_position
		engine_particles_front_right.rotation = front_engine_position_R.global_rotation - deg2rad(180)	
		
		# spawn trail
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# add trail points
	if bolt_trail_active == true:
		if velocity.length() > 0:
			new_bolt_trail.gradient.colors[1] = player_color
			new_bolt_trail.add_points(global_position)
		elif velocity.length() == 0 and no_power: # "input" je, da izločim za hitre prehode med naprej nazaj
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func on_collision():
	
	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	
	# odbojni partikli
	if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = velocity.length()/15 # količnik je korektor	
		new_collision_particles.color = player_color
		new_collision_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_collision_particles)

	
func shooting(weapons) -> void:
	
	match weapons:
		"Bullet":	
			if bullet_reloaded:
				var new_bullet = Bullet.instance()
				new_bullet.position = gun_position.global_position
				new_bullet.rotation = gun_position.global_rotation
				new_bullet.spawned_by = name # ime avtorja izstrelka
				new_bullet.spawned_by_color = player_color
				Global.node_creation_parent.add_child(new_bullet)
				
				bullet_reloaded = false
				yield(get_tree().create_timer(bullet_reload_time), "timeout")
				bullet_reloaded= true
		
		"Misile":
			if misile_reloaded and misile_count > 0:			
				var new_misile = Misile.instance()
				new_misile.position = gun_position.global_position
				new_misile.rotation = gun_position.global_rotation
				new_misile.spawned_by = name # ime avtorja izstrelka
				new_misile.spawned_by_color = player_color
				new_misile.spawned_by_speed = velocity.length()
				Global.node_creation_parent.add_child(new_misile)
				
				Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
				misile_reloaded = false
				misile_count -= 1
		
		"Shocker":
			if shocker_count > 0:			
				var new_shocker = Shocker.instance()
				new_shocker.rotation = rear_engine_position.global_rotation
				new_shocker.global_position = rear_engine_position.global_position
				new_shocker.spawned_by = name # ime avtorja izstrelka
				new_shocker.spawned_by_color = player_color
				Global.node_creation_parent.add_child(new_shocker)
				
				shocker_count -= 1
		
		"Shield":		
			if shields_on == false:
				shield.modulate.a = 1
				animation_player.play("shield_on")
				shields_on = true
				bolt_collision.disabled = true
				shield_collision.disabled = false
			else:
				animation_player.play_backwards("shield_on")
				# shields_on = false # premaknjeno dol na konec animacije
				# collisions setup premaknjeno dol na konec animacije
				shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja

	
func on_misile_destroyed(): # iz signala
	misile_reloaded= true	
	

func steering(delta: float) -> void:
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	if power_fwd:
		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	elif power_rev:
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), top_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri


func engines_setup():
	
	engine_particles_rear = EngineParticles.instance()
	engine_particles_rear.position = rear_engine_position.global_position
	engine_particles_rear.rotation = rear_engine_position.global_rotation
	Global.effects_creation_parent.add_child(engine_particles_rear)
	
	engine_particles_front_left = EngineParticles.instance()
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	engine_particles_front_left.position = front_engine_position_L.global_position
	engine_particles_front_left.rotation = front_engine_position_L.global_rotation - deg2rad(180)
	Global.effects_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	engine_particles_front_right.position = front_engine_position_R.global_position
	engine_particles_front_right.rotation = front_engine_position_R.global_rotation - deg2rad(180)	
	Global.effects_creation_parent.add_child(engine_particles_front_right)


func on_hit(collision_object: Node):
	
	if not shields_on:
		
		if collision_object.is_in_group(Config.group_bullets):
			# shake camera
			camera.add_trauma(bullet_hit_shake)
			# take damage
			health -= collision_object.hit_damage
			if health <= 0:
				die()
#				explode_and_reset()
				pass
			# push
			velocity = collision_object.velocity * bullet_push_factor
			# utripne	
			modulate = Color.red
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 


		elif collision_object.is_in_group(Config.group_misiles):
			control_enabled = false
			# shake camera
			camera.add_trauma(misile_hit_shake)
			# take damage
			health -= collision_object.hit_damage
			if health <= 0:
				die()
#				explode_and_reset()
				pass			
			# push
			velocity = collision_object.velocity * misile_push_factor
			# utripne	
			modulate = Color.red
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 
			# disabled
			var disabled_tween = get_tree().create_tween()
			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
			yield(disabled_tween, "finished")
			
			# enable controls
			control_enabled = true
			
		elif collision_object.is_in_group(Config.group_shockers):
			
			control_enabled = false
#			if control_enabled == true: 
			
			# catch
			var catch_tween = get_tree().create_tween()
			catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
			catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
			catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
			bolt_sprite.material.set_shader_param("noise_factor", 2.0)
			bolt_sprite.material.set_shader_param("speed", 0.7)
				
			yield(get_tree().create_timer(collision_object.shock_time), "timeout")
			
			#releaase
			var relase_tween = get_tree().create_tween()
			relase_tween.tween_property(self, "engine_power", 200, 0.1)
			relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
			yield(relase_tween, "finished")
			
			bolt_sprite.material.set_shader_param("noise_factor", 0.0)
			bolt_sprite.material.set_shader_param("speed", 0.0)
			control_enabled = true
				
			
func die():
	
	# najprej explodiraj 
	# potem ugasni sprite in coll 
	# potem ugasni motor in štartaj trail decay
	# explozijo izključi ko grejo partikli ven
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate = modulate
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	Global.node_creation_parent.add_child(new_exploding_bolt)
	queue_free()		


func _on_shield_animation_finished(anim_name: String) -> void:
	
	shield_loops_counter += 1
	
	match anim_name:
		"shield_on":	
			# končan outro ... resetiramo lupe in ustavimo animacijo
			if shield_loops_counter > shield_loops_limit:
				animation_player.stop(false) # včasih sem rabil, da se ne cikla, zdaj pa je okej, ker ob
				shield_loops_counter = 0
				shields_on = false
				bolt_collision.disabled = false
				shield_collision.disabled = true
			# končan intro ... zaženi prvi loop
			else:
				animation_player.play("shielding")
		"shielding":
			# dokler je loop manjši od limita ... replayamo animacijo
			if shield_loops_counter < shield_loops_limit:
				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
			# konec loopa, ko je limit dosežen
			elif shield_loops_counter >= shield_loops_limit:
				animation_player.play_backwards("shield_on")


	
func explode_and_reset():
	
	# shake camera
	camera.add_trauma(bolt_explosion_shake)
	
	if visible == true:
		var new_exploding_bolt = ExplodingBolt.instance()
		new_exploding_bolt.global_position = global_position
		new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
		new_exploding_bolt.spawned_by_color = player_color
		new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
		Global.node_creation_parent.add_child(new_exploding_bolt)
		visible = false
	else:
		visible = true
		health = 5 # podamo hitrost, da se premika s hitrostjo bolta
	
