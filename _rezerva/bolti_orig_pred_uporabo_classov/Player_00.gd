extends KinematicBody2D


var camera_follow: bool = false


var player_index: int # ga dobi iz game managerja ob kreaciji
var player_name: String = "P1"
var player_profile: Dictionary
var player_color: Color
## Your custom description goes right here and will show in the docs
var axis_distance: int



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

# weapons
var bullet_reloaded: bool = true
var bullet_push_factor: float = 0.1 # kako močen je potisk metka ... delež hitrosti metka
var misile_reloaded: bool = true
var misile_push_factor = 0.5 # push eksplozije
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trneutni ožini

# features
var shields_on = false
var shield_loops_counter: int = 0
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni, potem je "odklopljena"
var new_bolt_trail: Object
var trail_grad_color = Color.white

# positions
var gun_pos: Vector2 = Vector2(6.5, 0.5)
var shocker_pos: Vector2 = Vector2(-4.5, 0.5)
var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)

# controls
var controller_profile_name: String
var controller_profile: Dictionary
var controller_actions: Dictionary

var fwd_action# = controller_actions["fwd_action"]
var rev_action# = controller_actions["rev_action"]
var left_action# = controller_actions["left_action"]
var right_action# = controller_actions["right_action"]
var shoot_bullet_action# = controller_actions["shoot_bullet_action"]
var shoot_misile_action# = controller_actions["shoot_misile_action"]
var shoot_shocker_action# = controller_actions["shoot_shocker_action"]

var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var health_bar: Polygon2D = $EnergyPoly
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var camera = Global.current_camera

onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://game/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://game/weapons/Shocker.tscn")

# bolt
onready var bolt_profile: Dictionary = Profiles.bolt_profiles["basic"]
onready var bolt_texture: Texture = bolt_profile["bolt_texture"] 
onready var engine_power: int = bolt_profile["fwd_engine_power"]
onready var turn_angle: int = bolt_profile["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = bolt_profile["free_rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = bolt_profile["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = bolt_profile["side_traction"]
onready var bounce_size: float = bolt_profile["bounce_size"]
onready var inertia: float = bolt_profile["inertia"]
onready var reload_ability: float = bolt_profile["reload_ability"]  # reload def gre v weapons
onready var on_hit_disabled_time: float = bolt_profile["on_hit_disabled_time"] 
onready var shield_loops_limit: int = bolt_profile["shield_loops_limit"] 

# plejer stats
onready var health: float = Profiles.default_bolt_stats["health"] # tale se sreminja z igro
onready var max_health: float = Profiles.default_bolt_stats["health"] # tole je konstanta da se lahko vrne
onready var bullet_count = Profiles.default_bolt_stats["bullet_count"]
onready var misile_count = Profiles.default_bolt_stats["misile_count"]
onready var shocker_count = Profiles.default_bolt_stats["shocker_count"]

#onready var max_speed_reverse: int =  bolt_profile["max_speed_reverse"]
var max_speed_reverse: float =  50

	
	
func _ready() -> void:
		
	# profili
	player_profile = Profiles.default_player_profiles[player_name]
	controller_profile_name = player_profile["controller_profile"]
#	controller_profile = Profiles.default_controller_profiles[controller_profile_name]
	controller_actions = Profiles.default_controller_actions[controller_profile_name]
	player_color = player_profile["player_color"]
	
	# plejer 
	name = player_name
	bolt_sprite.self_modulate = player_color
	bolt_sprite.texture = bolt_texture
	axis_distance = bolt_texture.get_width()
	add_to_group(Config.group_players)
	add_to_group(Config.group_bolts)	

	print(player_name)
	print(controller_profile_name)
	
	# controls
	fwd_action = controller_actions["fwd_action"]
	rev_action = controller_actions["rev_action"]
	left_action = controller_actions["left_action"]
	right_action = controller_actions["right_action"]
	shoot_bullet_action = controller_actions["shoot_bullet_action"]
	shoot_misile_action = controller_actions["shoot_misile_action"]
	shoot_shocker_action = controller_actions["shoot_shocker_action"]
	
	# ----------------------------------------------------------------------
	
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
		input_power = Input.get_action_strength(fwd_action) - Input.get_action_strength(rev_action) # +1, -1 ali 0
		rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0	

		if Input.is_action_just_pressed(shoot_bullet_action):
			shooting("Bullet")
		if Input.is_action_just_released(shoot_misile_action):	
			shooting("Misile")
		if Input.is_action_just_released(shoot_shocker_action):	
			shooting("Shocker")

	

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
	

func _process(delta: float) -> void:
	
	if camera_follow:
		camera.position = position
		
	
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
		rotate(delta * rotation_angle * free_rotation_multiplier)
	else: 
		rotate(delta * rotation_angle)
	
	steering(delta)
	
	collision = move_and_collide(velocity * delta, false)
	
	if collision:
		on_collision()
	
	motion_fx(delta)
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	health_bar.rotation = -(rotation) # negiramo rotacijo bolta, da je pri miru
	health_bar.global_position = global_position + Vector2(-3.5, 8) # negiramo rotacijo bolta, da je pri miru
	
	health_bar.scale.x = health / max_health
	if health_bar.scale.x < 0.5:
		health_bar.color = Color.indianred
	else:
		health_bar.color = Color.aquamarine
	
	
func motion_fx(delta):
		
	if power_fwd:
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.global_position = to_global(rear_engine_pos)
		engine_particles_rear.global_rotation = bolt_sprite.global_rotation
		
		# spawn trail
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	if power_rev:
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.global_position = to_global(front_engine_pos_L)
		engine_particles_front_left.global_rotation = bolt_sprite.global_rotation - deg2rad(180)
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.global_position = to_global(front_engine_pos_R)
		engine_particles_front_right.global_rotation = bolt_sprite.global_rotation - deg2rad(180)	
		
		# spawn trail
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# add trail points
	if bolt_trail_active == true:
		if velocity.length() > 0:
			new_bolt_trail.gradient.colors[1] = trail_grad_color
			new_bolt_trail.add_points(global_position)
		elif velocity.length() == 0 and no_power: # "input" je, da izločim za hitre prehode med naprej nazaj
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena

	# engine transparency
	if velocity.length() < 100:
		engine_particles_rear.modulate.a = velocity.length()/100
		engine_particles_front_left.modulate.a = velocity.length()/100
		engine_particles_front_right.modulate.a = velocity.length()/100
	else:
		engine_particles_rear.modulate.a = 1
		engine_particles_front_left.modulate.a = 1
		engine_particles_front_right.modulate.a = 1
		

func on_collision():
	
	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	
	# odbojni partikli
	if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
		new_collision_particles.color = player_color
		new_collision_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_collision_particles)

	
func shooting(weapons) -> void:
	match weapons:
		"Bullet":	
			if bullet_reloaded:
				var new_bullet = Bullet.instance()
#				new_bullet.global_position = bolt_sprite.global_position# + gun_pos
				new_bullet.global_position = to_global(gun_pos)
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = name # ime avtorja izstrelka
				new_bullet.spawned_by_color = player_color
				Global.node_creation_parent.add_child(new_bullet)
				
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		
		"Misile":
			if misile_reloaded and misile_count > 0:			
				var new_misile = Misile.instance()
				new_misile.global_position = to_global(gun_pos)
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = name # ime avtorja izstrelka
				new_misile.spawned_by_color = player_color
				new_misile.spawned_by_speed = velocity.length()
				Global.node_creation_parent.add_child(new_misile)
				misile_count -= 1

				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
			
		"Shocker":
			if shocker_reloaded and shocker_count > 0:			
				var new_shocker = Shocker.instance()
				new_shocker.global_position = to_global(shocker_pos)
				new_shocker.global_rotation = bolt_sprite.global_rotation
				new_shocker.spawned_by = name # ime avtorja izstrelka
				new_shocker.spawned_by_color = player_color
				Global.node_creation_parent.add_child(new_shocker)
				shocker_count -= 1
				
				shocker_reloaded = false
				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
				shocker_reloaded= true
		
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
		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri


func engines_setup():
	
			
	engine_particles_rear = EngineParticles.instance()
	# rotacija se seta v FP
	Global.effects_creation_parent.add_child(engine_particles_rear)
	
	engine_particles_front_left = EngineParticles.instance()
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	# rotacija se seta v FP
	Global.effects_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	# rotacija se seta v FP
	Global.effects_creation_parent.add_child(engine_particles_front_right)


func on_hit(hit_by: Node):
	
	if not shields_on:
		
		if hit_by.is_in_group(Config.group_bullets):
			# shake camera
#			camera.add_trauma(camera.bullet_hit_shake)
			# take damage
			health -= hit_by.hit_damage
			health_bar.scale.x = health/10
			
			if health <= 0:
				die()
#				explode_and_reset()
				pass
			# push
#			velocity = collision_object.velocity * bullet_push_factor
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate.a = 0.2
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate:a", 1, 0.1) 


		elif hit_by.is_in_group(Config.group_misiles):
			control_enabled = false
			# shake camera
#			camera.add_trauma(camera.misile_hit_shake)
			# take damage
			health -= hit_by.hit_damage
			if health <= 0:
				die()
#				explode_and_reset()
				pass			
			# push
#			velocity = collision_object.velocity * misile_push_factor
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate.a = 0.2
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate:a", 1, 0.1) 
			# disabled
			var disabled_tween = get_tree().create_tween()
			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
			yield(disabled_tween, "finished")
			
			# enable controls
			control_enabled = true
			
		elif hit_by.is_in_group(Config.group_shockers):
			
			control_enabled = false
			
			# catch
			var catch_tween = get_tree().create_tween()
			catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
			catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
			catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
			bolt_sprite.material.set_shader_param("noise_factor", 2.0)
			bolt_sprite.material.set_shader_param("speed", 0.7)
				
			yield(get_tree().create_timer(hit_by.shock_time), "timeout")
			
			#releaase
			var relase_tween = get_tree().create_tween()
			relase_tween.tween_property(self, "engine_power", 200, 0.1)
			relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
			yield(relase_tween, "finished")
			
			bolt_sprite.material.set_shader_param("noise_factor", 0.0)
			bolt_sprite.material.set_shader_param("speed", 0.0)
			control_enabled = true
				
			
func die():
	
#	camera.add_trauma(camera.bolt_explosion_shake)
		
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
#	camera.add_trauma(camera.bolt_explosion_shake)
	
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
	
