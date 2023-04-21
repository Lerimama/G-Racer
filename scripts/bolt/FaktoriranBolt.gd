extends KinematicBody2D

class_name Bolt, "res://assets/bolt/bolt.png"


signal just_hit # bolt in damage

var camera_follow: bool = false

var bolt_color: Color = Color.white
var trail_grad_color = Color.white
var stop_speed: float = 15
var axis_distance: float # določen glede na širino sprajta
var input_power: float
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D

# states
var power_fwd: bool
var power_rev: bool
var no_power: bool
var control_enabled: bool = true
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trneutni ožini
var shields_on = false

# positions
var gun_pos: Vector2 = Vector2(6.5, 0.5)
var shocker_pos: Vector2 = Vector2(-4.5, 0.5)
var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)

# features
var shield_loops_counter: int = 0
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni, potem je "odklopljena"
var new_bolt_trail: Object
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

# ------------------------------------------------------------------------------------------------------------------------------------

onready var camera = Global.current_camera

onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var shield: Sprite = $Shield
onready var bolt_collision: CollisionPolygon2D = $BoltCollision
onready var bolt_sprite: Sprite = $Bolt

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")
onready var animation_player: AnimationPlayer = $AnimationPlayer

# bolt profil
onready var bolt_profile: Dictionary = Profiles.bolt_profiles["basic"]
onready var bolt_sprite_texture: Texture = bolt_profile["bolt_texture"] 
onready var engine_power: int = bolt_profile["engine_power"]
onready var max_speed_reverse: int =  bolt_profile["max_speed_reverse"]
onready var turn_angle: int = bolt_profile["turn_angle"] # deg per frame
onready var rotation_multiplier: int = bolt_profile["rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = bolt_profile["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = bolt_profile["side_traction"]
onready var bounce_size: float = bolt_profile["bounce_size"]
onready var inertia: float = bolt_profile["inertia"]
onready var reload_ability: float = bolt_profile["reload_ability"]  # reload def gre v weapons
onready var on_hit_disabled_time: float = bolt_profile["on_hit_disabled_time"] 
onready var shield_loops_limit: int = bolt_profile["shield_loops_limit"] 
	
	
func _ready() -> void:
	print("bolt je redi")
	
	# bolt 
	bolt_sprite.self_modulate = bolt_color
	bolt_sprite.texture = bolt_sprite_texture
	add_to_group(Config.group_bolts)	
	axis_distance = bolt_sprite_texture.get_width()
	
#	bolt_collision.disabled = false
	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield_collision.disabled = true 
	shield.self_modulate = bolt_color 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)
	
	
func _process(delta: float) -> void:

	if camera_follow:
		camera.position = position
	
	
func _physics_process(delta: float) -> void:
	
	fp_motion(delta)
#	acceleration = input_power * transform.x * engine_power # transform.x je (-1, 0)
#	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
#	acceleration -= drag_force
#	velocity += acceleration * delta
#	if no_power and velocity.length() < 5: # da ne bo neskončno računal pozicije
#		velocity = Vector2.ZERO 
	
	fp_rotation(delta)
#	rotation_angle = rotation_dir * deg2rad(turn_angle)
#	if no_power: 
#		rotate(delta * rotation_angle * rotation_multiplier)
#	else: 
#		rotate(delta * rotation_angle)
#	steering(delta)
	
	fp_velocity(delta)
#	collision = move_and_collide(velocity * delta, false)
#	if collision:
#		on_collision()
	
	power_states()
	motion_fx()
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	
				
func power_states() -> void:
	
	# nad mejo
	if velocity.length() > stop_speed:
		power_fwd = true
		# off
		power_rev = false
		no_power = false
	# pod mejo
	elif velocity.length() < -stop_speed:
		power_rev = true
		# off
		power_fwd = false
		no_power = false
		modulate = Color.red
	# vmes
	else:
		no_power = true
		# off
		power_fwd = false
		power_rev = false


func fp_motion(delta):
	

	acceleration = input_power * transform.x * engine_power # transform.x je (-1, 0)
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
	acceleration -= drag_force
	velocity += acceleration * delta	
	
	
func fp_rotation(delta):
	

	rotation_angle = rotation_dir * deg2rad(turn_angle)
	if no_power: 
		rotate(delta * rotation_angle * rotation_multiplier)
	else: 
		rotate(delta * rotation_angle)

	steering(delta)


func fp_velocity(delta):

	collision = move_and_collide(velocity * delta, false)

	if collision:
		on_collision()	
	
	
func motion_fx():
	
	if power_fwd:
		engine_particles_rear.modulate.a = velocity.length()/50
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.global_position = to_global(rear_engine_pos)
		engine_particles_rear.global_rotation = bolt_sprite.global_rotation
		
		# spawn trail if not active
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	elif power_rev:
		engine_particles_front_left.modulate.a = velocity.length()/10
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.global_position = to_global(front_engine_pos_L)
		engine_particles_front_left.global_rotation = bolt_sprite.global_rotation - deg2rad(180)
		engine_particles_front_right.modulate.a = velocity.length()/10
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.global_position = to_global(front_engine_pos_R)
		engine_particles_front_right.global_rotation = bolt_sprite.global_rotation - deg2rad(180)	
		# spawn trail if not active
		if bolt_trail_active == false and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# add trail points
	if bolt_trail_active == true:
		if velocity.length() > 0 or velocity.length() < 0:
			new_bolt_trail.gradient.colors[1] = trail_grad_color
			new_bolt_trail.add_points(global_position)
		else: 
		# elif velocity.length() == 0:# and no_power: # "input" je, da izločim za hitre prehode med naprej nazaj
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
	if velocity.length() > stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = velocity.length()/15 # količnik je korektor	
		new_collision_particles.color = bolt_color
		new_collision_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_collision_particles)

	
func shooting(weapon) -> void:
	
#	print("shooting")
	
	match weapon:
		"bullet":	
			if bullet_reloaded:
				var new_bullet = Bullet.instance()
#				new_bullet.global_position = bolt_sprite.global_position# + gun_pos
				new_bullet.global_position = to_global(gun_pos)
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = name # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				Global.node_creation_parent.add_child(new_bullet)
				
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		
		"misile":
			if misile_reloaded: # and misile_count > 0:			
				var new_misile = Misile.instance()
				new_misile.global_position = to_global(gun_pos)
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = name # ime avtorja izstrelka
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				Global.node_creation_parent.add_child(new_misile)
#				misile_count -= 1

				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
			
				# reload, ko je uničena				
				# Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
				# misile_reloaded = false
		
		"shocker":
			if shocker_reloaded: # and shocker_count > 0:			
				var new_shocker = Shocker.instance()
				new_shocker.global_position = to_global(shocker_pos)
				new_shocker.global_rotation = bolt_sprite.global_rotation
				new_shocker.spawned_by = name # ime avtorja izstrelka
				new_shocker.spawned_by_color = bolt_color
				Global.node_creation_parent.add_child(new_shocker)
#				shocker_count -= 1
				
				shocker_reloaded = false
				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
				shocker_reloaded= true
		
		"shield":		
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
	engine_particles_rear.modulate.a = 0
	
	engine_particles_front_left = EngineParticles.instance()
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	engine_particles_front_left.modulate.a = 0
	# rotacija se seta v FP
	Global.effects_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	engine_particles_front_right.modulate.a = 0
	# rotacija se seta v FP
	Global.effects_creation_parent.add_child(engine_particles_front_right)

		
func on_hit(hit_by: Node):
	
	if not shields_on:
		
		if hit_by.is_in_group(Config.group_bullets):
			# shake camera
			camera.add_trauma(camera.bullet_hit_shake)
			# take damage
			emit_signal("just_hit", hit_by.hit_damage, self)
			
#			manage_player_stats("damage", hit_by.hit_damage)
			# push
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate = Color.red
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 

		elif hit_by.is_in_group(Config.group_misiles):
			control_enabled = false
			# shake camera
			camera.add_trauma(camera.misile_hit_shake)
			# take damage
#			manage_player_stats("damage", hit_by.hit_damage)
			# push
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate = Color.red
			yield(get_tree().create_timer(0.05), "timeout")
			modulate = Color.white 
			# disabled
			var disabled_tween = get_tree().create_tween()
			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
			yield(disabled_tween, "finished")
			
			control_enabled = true
			
		elif hit_by.is_in_group(Config.group_shockers):
			control_enabled = false
			
			# take damage
#			manage_player_stats("damage", hit_by.hit_damage)		
			# catch
			var catch_tween = get_tree().create_tween()
			catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
			catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
			catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
			bolt_sprite.material.set_shader_param("noise_factor", 2.0)
			bolt_sprite.material.set_shader_param("speed", 0.7)
			# controlls off time	
			yield(get_tree().create_timer(hit_by.shock_time), "timeout")
			#releaase
			var relase_tween = get_tree().create_tween()
			relase_tween.tween_property(self, "engine_power", 200, 0.1)
			relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
			yield(relase_tween, "finished")
			# reset shsder
			bolt_sprite.material.set_shader_param("noise_factor", 0.0)
			bolt_sprite.material.set_shader_param("speed", 0.0)
			
			control_enabled = true
				
			
func die():
	
	# shake camera
	camera.add_trauma(camera.bolt_explosion_shake)
		
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
