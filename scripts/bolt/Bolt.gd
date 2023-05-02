extends KinematicBody2D

class_name Bolt, "res://assets/icons/bolt_icon.png"


signal stat_changed (stat_owner, stat, stat_change) # bolt in damage

var bolt_id: String = "P1"
#var bolt_index: int
var bolt_color: Color = Color.white
var trail_pseudodecay_color = Color.white
var stop_speed: float = 15
var axis_distance: float # določen glede na širino sprajta
var input_power: float
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D

# states
var control_enabled: bool = true

var fwd_motion: bool	
var rev_motion: bool
var no_motion: bool	
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

# nitro
var nitro_active: bool =  false
var nitro_power: float # se seta s pickable
var nitro_active_time: float = 5
var tracking_active_time: float = 5

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
onready var energy_bar_holder: Node2D = $EnergyBar
onready var energy_bar: Polygon2D = $EnergyBar/Bar

onready var CollisionParticles: PackedScene = preload("res://scenes/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://scenes/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://scenes/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://scenes/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://scenes/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://scenes/weapons/Shocker.tscn")

# driver stats
#onready var life: float = Profiles.default_player_stats["life"]
#onready var points: float = Profiles.default_player_stats["life"]

# bolt stats
#onready var energy: float = Profiles.default_bolt_stats.energy
#onready var max_energy: float = Profiles.default_bolt_stats.energy # zato, da se lahko resetira
##onready var bullet_count: float = Profiles.default_bolt_stats["bullet_count"]
#onready var bullet_power: float = Profiles.default_bolt_stats.bullet_power
#onready var misile_count: float = Profiles.default_bolt_stats.misile_count
#onready var shocker_count: float = Profiles.default_bolt_stats.shocker_count

# bolt stats
onready var energy: float = Profiles.default_bolt_stats["energy"]
onready var max_energy: float = Profiles.default_bolt_stats["energy"] # zato, da se lahko resetira
#onready var bullet_count: float = Profiles.default_bolt_stats["bullet_count"]
onready var bullet_power: float = Profiles.default_bolt_stats["bullet_power"]
onready var misile_count: float = Profiles.default_bolt_stats["misile_count"]
onready var shocker_count: float = Profiles.default_bolt_stats["shocker_count"]

# bolt profil
onready var bolt_type: String = "basic" 
onready var bolt_sprite_texture: Texture = Profiles.bolt_profiles[bolt_type]["bolt_texture"] 
onready var fwd_engine_power: int = Profiles.bolt_profiles[bolt_type]["fwd_engine_power"]
onready var rev_engine_power: int = Profiles.bolt_profiles[bolt_type]["rev_engine_power"]
onready var turn_angle: int = Profiles.bolt_profiles[bolt_type]["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = Profiles.bolt_profiles[bolt_type]["free_rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = Profiles.bolt_profiles[bolt_type]["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = Profiles.bolt_profiles[bolt_type]["side_traction"]
onready var bounce_size: float = Profiles.bolt_profiles[bolt_type]["bounce_size"]
onready var inertia: float = Profiles.bolt_profiles[bolt_type]["inertia"]
onready var reload_ability: float = Profiles.bolt_profiles[bolt_type]["reload_ability"]  # reload def gre v weapons
onready var on_hit_disabled_time: float = Profiles.bolt_profiles[bolt_type]["on_hit_disabled_time"] 
onready var shield_loops_limit: int = Profiles.bolt_profiles[bolt_type]["shield_loops_limit"] 
#onready var bolt_trail_alpha: int = Profiles.bolt_profiles[bolt_type]["bolt_trail_alpha"] 


var loose_life_time: float = 2

func _ready() -> void:

	print("Žiu!. Moje ime je, ", name, "Moja identifikacija je: ", bolt_id)
	
	# bolt 
#	bolt_sprite.self_mod1ulate = bolt_color
	bolt_sprite.texture = bolt_sprite_texture
	add_to_group(Config.group_bolts)	
	axis_distance = bolt_sprite_texture.get_width()
#	bolt_index ... se določi iz spawnerja

	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield_collision.disabled = true 
	shield.self_modulate = bolt_color 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)
	

func _physics_process(delta: float) -> void:
	
	# fwd motion se seta v kontrolerjih
	# aktivacija pospeška je setana na kotrolerju
	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	
	
	# pospešek omejim z uporom
	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja ... 100 je za dapatacijo višine inputa
	acceleration -= drag_force
	
	if nitro_active and fwd_motion: # se seta ob prevozu bonusa
		engine_power = nitro_power
					
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
	update_energy_bar()
	
# IZ FP ----------------------------------------------------------------------------

	
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
			new_bolt_trail.gradient.colors[1] = trail_pseudodecay_color
			
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
	

func steering(delta: float) -> void:
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction" ... 10 je za adaptacijo inputa	
	#if fwd_motion:
	#	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	#elif rev_motion:
	#	velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri

	
func update_energy_bar():
	
	
	# energy_bar
	energy_bar_holder.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	energy_bar_holder.global_position = global_position + Vector2(0, 8) # negiramo rotacijo bolta, da je pri miru
#	energy_bar_holder.global_position = global_position + Vector2(-3.5, 8) # negiramo rotacijo bolta, da je pri miru

	energy_bar.scale.x = energy / max_energy
	if energy_bar.scale.x < 0.5:
		energy_bar.color = Color.indianred
	else:
		energy_bar.color = Color.aquamarine		
			

# FEATURES ----------------------------------------------------------------------------


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

		
func shooting(weapon: String) -> void:
	
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
				energy -= bullet_power
				if energy <= 0:
					loose_life()
					
				
				emit_signal("stat_changed", bolt_id, "energy", energy) # do GMa
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

				emit_signal("stat_changed", bolt_id, "misile_count", misile_count) # do GMa

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
				
				emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) # do GMa
				
				shocker_reloaded = false
				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
				shocker_reloaded= true
		"shield":
			activate_shield()
		
			
func activate_shield():
	
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


func activate_nitro():
	
	# pospešek
	var nitro_tween = get_tree().create_tween()
	nitro_tween.tween_property(self, "engine_power", nitro_power, 1) # pospešek spreminja engine_power, na katereg input ne vpliva
	nitro_tween.tween_property(self, "nitro_active", true, 0)
	# trajanje
	yield(get_tree().create_timer(nitro_active_time), "timeout")
	nitro_active = false	


func on_hit(hit_by: Node):
	
	if not shields_on:
		
		if hit_by.is_in_group(Config.group_bullets):
			# shake camera
			camera.add_trauma(camera.bullet_hit_shake)
			# take damage
			take_damage(hit_by)
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
			take_damage(hit_by)
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
			take_damage(hit_by)		
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
			relase_tween.tween_property(self, "engine_power", engine_power, 0.1)
			relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
			yield(relase_tween, "finished")
			# reset shsder
			bolt_sprite.material.set_shader_param("noise_factor", 0.0)
			bolt_sprite.material.set_shader_param("speed", 0.0)
			
			control_enabled = true


func take_damage(hit_by: Node):
	
	var damage_amount: float = hit_by.hit_damage
	
	energy -= damage_amount
	energy = clamp(energy, 0, max_energy)
	energy_bar.scale.x = energy/10
	
	# za damage
	emit_signal("stat_changed", bolt_id, "energy", energy) # do GMa
	# za točke
#	emit_signal("stat_changed", hit_by, "points", damage_amount) # do GMa
	
	if energy <= 0:
		loose_life()
	
#var life = 5
func item_picked(pickable_type: String, amount: float):
	
	match pickable_type:
		"bullet":
			energy += max_energy/2
		"misile":
			misile_count += amount
			emit_signal("stat_changed", bolt_id, "misile_count", misile_count) 
		"shocker":
			shocker_count += amount
			emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) 
		"shield":
			activate_shield()
		"energy":
			energy = max_energy
		"life":
#			emit_signal("stat_changed", bolt_id, "life", amount)
			pass
		"nitro":
			nitro_power = amount
			activate_nitro()
		"tracking":
			var default_traction = side_traction
			side_traction = amount
			yield(get_tree().create_timer(tracking_active_time), "timeout")
			side_traction = default_traction
		"random":
			# žrebanje
			var selection_range: int = amount
			var selected_pickable_index = randi() % selection_range
#			var selected_pickable_index: int = Global.get_random_member_index(Profiles.Pickables_names) ... tole vključi tudi random, česar nočem
			var selected_pickable_name: String = Profiles.Pickables_names[selected_pickable_index]
			var selected_pickable_amount: float = Profiles.pickable_profiles[selected_pickable_index]["amount"]
			
			# pick again
			item_picked(selected_pickable_name, selected_pickable_amount)	
			
			
func loose_life():
	
	# shake camera
	camera.add_trauma(camera.bolt_explosion_shake)
	
	# ugasni tejl
	if bolt_trail_active:
		new_bolt_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
	
	# "ugasni" motorje
#	engine_particles_rear.visible = false
#	engine_particles_front_left.visible = false
#	engine_particles_front_right.visible = false
	
	# spawnaj eksplozijo
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
#	new_exploding_bolt.modulate = modulate
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawned_by_color = bolt_color
	Global.node_creation_parent.add_child(new_exploding_bolt)
	
	emit_signal("stat_changed", bolt_id, "life", -1)
	
	bolt_collision.disabled = true
	visible = false
	set_physics_process(false)
	yield(get_tree().create_timer(loose_life_time), "timeout")
	
	# on new life
	bolt_collision.disabled = false
#	engine_particles_rear.visible = true
#	engine_particles_front_left.visible = true
#	engine_particles_front_right.visible = true
	energy = max_energy
	set_physics_process(true)
	visible = true

#	queue_free()		


# SIGNALS ----------------------------------------------------------------------------

		
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
