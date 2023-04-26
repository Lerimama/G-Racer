extends KinematicBody2D

class_name Bolt, "res://assets/bolt/bolt.png"


signal stat_changed (stat, stat_change) # bolt in damage

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
var fwd_motion: bool	
var rev_motion: bool
var no_motion: bool	
var control_enabled: bool = true
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trneutni ožini
var shields_on = false
var camera_follow: bool = false

var shield_loops_counter: int = 0

# trail
var new_bolt_trail: Object
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni, potem je "odklopljena"
var bolt_trail_alpha = 0.05

# engine
var engine_power = 0 # ob štartu je noga z gasa
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

# positions
var gun_pos: Vector2 = Vector2(6.5, 0.5)
var shocker_pos: Vector2 = Vector2(-4.5, 0.5)
var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)


# ------------------------------------------------------------------------------------------------------------------------------------

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision # zaradi shielda ga moram imet
onready var shield: Sprite = $Shield
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var camera = Global.current_camera
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var health_bar: Polygon2D = $HealthBar

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")

# bolt stats
onready var health: float = Profiles.default_bolt_stats["health"]
onready var max_health: float = Profiles.default_bolt_stats["health"] # zato, da se lahko resetira
onready var bullet_count: float = Profiles.default_bolt_stats["bullet_count"]
onready var misile_count: float = Profiles.default_bolt_stats["misile_count"]
onready var shocker_count: float = Profiles.default_bolt_stats["shocker_count"]

# bolt profil
onready var bolt_sprite_texture: Texture = Profiles.bolt_profiles["basic"]["bolt_texture"] 
onready var fwd_engine_power: int = Profiles.bolt_profiles["basic"]["fwd_engine_power"]
onready var rev_engine_power: int = Profiles.bolt_profiles["basic"]["rev_engine_power"]
onready var turn_angle: int = Profiles.bolt_profiles["basic"]["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = Profiles.bolt_profiles["basic"]["free_rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = Profiles.bolt_profiles["basic"]["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = Profiles.bolt_profiles["basic"]["side_traction"]
onready var bounce_size: float = Profiles.bolt_profiles["basic"]["bounce_size"]
onready var inertia: float = Profiles.bolt_profiles["basic"]["inertia"]
onready var reload_ability: float = Profiles.bolt_profiles["basic"]["reload_ability"]  # reload def gre v weapons
onready var on_hit_disabled_time: float = Profiles.bolt_profiles["basic"]["on_hit_disabled_time"] 
onready var shield_loops_limit: int = Profiles.bolt_profiles["basic"]["shield_loops_limit"] 


func _ready() -> void:
	
	# bolt 
	bolt_sprite.self_modulate = bolt_color
	bolt_sprite.texture = bolt_sprite_texture
	add_to_group(Config.group_bolts)	
	axis_distance = bolt_sprite_texture.get_width()
	
	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield_collision.disabled = true 
	shield.self_modulate = bolt_color 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)
	
# FP -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# fwd motion se seta v kontrolerjih
	# aktivacija pospeška je setana na kotrolerju
	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	
	# pospešek omejim z uporom
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja ... 100 je za dapatacijo višine inputa
	acceleration -= drag_force
	
	# "hitrost" je pospešek s časom
	velocity += acceleration * delta	

	rotation_angle = rotation_dir * deg2rad(turn_angle)
#	if velocity.length() < stop_speed: 
#		rotate(delta * rotation_angle * free_rotation_multiplier)
#	else: 
#		rotate(delta * rotation_angle)
	
	rotate(delta * rotation_angle)
	steering(delta)	# vpliva na ai !!!

	collision = move_and_collide(velocity * delta, false)

	if collision:
		on_collision()	
			
	motion_fx()
	update_health_bar()
	
func on_collision():
	
	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	
	# odbojni partikli
	if velocity.length() > stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
#		new_collision_particles.amount = clamp(new_collision_particles.amount, 1, velocity.length()/15) 
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
		new_collision_particles.color = bolt_color
		new_collision_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_collision_particles)

func motion_fx():
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	
	if fwd_motion:
		engine_particles_rear.modulate.a = velocity.length()/50
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.global_position = to_global(rear_engine_pos)
		engine_particles_rear.global_rotation = bolt_sprite.global_rotation
		
		# spawn trail if not active
		if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			new_bolt_trail.modulate.a = bolt_trail_alpha
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
			
	elif rev_motion:
		engine_particles_front_left.modulate.a = velocity.length()/10
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_left.global_position = to_global(front_engine_pos_L)
		engine_particles_front_left.global_rotation = bolt_sprite.global_rotation - deg2rad(180)
		engine_particles_front_right.modulate.a = velocity.length()/10
		engine_particles_front_right.set_emitting(true)
		engine_particles_front_right.global_position = to_global(front_engine_pos_R)
		engine_particles_front_right.global_rotation = bolt_sprite.global_rotation - deg2rad(180)	
		
		# spawn trail if not active
		if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			new_bolt_trail = BoltTrail.instance()
			new_bolt_trail.modulate.a = bolt_trail_alpha
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 

	# manage trail
	if bolt_trail_active:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		if velocity.length() > 0:
			new_bolt_trail.add_points(global_position)
			new_bolt_trail.gradient.colors[1] = trail_grad_color
			
			if velocity.length() > stop_speed and new_bolt_trail.modulate.a < bolt_trail_alpha:
				# če se premikam in se je tril že začel skrivat ga prikažem
				var trail_grad = get_tree().create_tween()
				trail_grad.tween_property(new_bolt_trail, "modulate:a", bolt_trail_alpha, 0.5)
			else:
				# če grem počasi ga skrijem
				var trail_grad = get_tree().create_tween()
				trail_grad.tween_property(new_bolt_trail, "modulate:a", 0, 0.5)
		# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
		else:
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
	
func update_health_bar():
	
	# health_bar
	health_bar.rotation = -(rotation) # negiramo rotacijo bolta, da je pri miru
	health_bar.global_position = global_position + Vector2(-3.5, 8) # negiramo rotacijo bolta, da je pri miru

	health_bar.scale.x = health / max_health
	if health_bar.scale.x < 0.5:
		health_bar.color = Color.indianred
	else:
		health_bar.color = Color.aquamarine		

func steering(delta: float) -> void:
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction" ... 10 je za adaptacijo inputa	
#	if fwd_motion:
#		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
#	elif rev_motion:
#		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
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
		
# battle ------------------------------------------------------

func shooting(weapon) -> void:
	
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
			if misile_reloaded and misile_count > 0:			
				var new_misile = Misile.instance()
				new_misile.global_position = to_global(gun_pos)
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = name # ime avtorja izstrelka
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				Global.node_creation_parent.add_child(new_misile)
				misile_count -= 1

				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		
		"shocker":
			if shocker_reloaded and shocker_count > 0:			
				var new_shocker = Shocker.instance()
				new_shocker.global_position = to_global(shocker_pos)
				new_shocker.global_rotation = bolt_sprite.global_rotation
				new_shocker.spawned_by = name # ime avtorja izstrelka
				new_shocker.spawned_by_color = bolt_color
				Global.node_creation_parent.add_child(new_shocker)
				shocker_count -= 1
				
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
				# shields_on in collisions_setup # premaknjeno dol na konec animacije
				shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja
		
func on_hit(hit_by: Node):
	
	if not shields_on:
		
		if hit_by.is_in_group(Config.group_bullets):
			# shake camera
			camera.add_trauma(camera.bullet_hit_shake)
			# take damage
			take_damage(hit_by.hit_damage)
			# push
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate.a = 0.2
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate:a", 1, 0.1) 

		elif hit_by.is_in_group(Config.group_misiles):
			control_enabled = false
			# shake camera
			camera.add_trauma(camera.misile_hit_shake)
			# take damage
			take_damage(hit_by.hit_damage)
			# push
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate.a = 0.2
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate:a", 1, 0.1) 
			# disabled
			var disabled_tween = get_tree().create_tween()
			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
			yield(disabled_tween, "finished")
			
			control_enabled = true
			
		elif hit_by.is_in_group(Config.group_shockers):
			control_enabled = false
			# take damage
			take_damage(hit_by.hit_damage)		
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

func take_damage(damage_amount):
	
#	emit_signal("stat_changed", damage_amount) # pošiljanje v HUD
	
	health -= damage_amount
	health_bar.scale.x = health/10
	if health <= 0:
		die()
			
func die():
	
	# shake camera
	camera.add_trauma(camera.bolt_explosion_shake)
	if bolt_trail_active:
		new_bolt_trail.start_decay() # trail decayp tween start
		bolt_trail_active = false
	
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate = modulate
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	Global.node_creation_parent.add_child(new_exploding_bolt)
	
	queue_free()		

# signals ------------------------------------------------------
		
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
