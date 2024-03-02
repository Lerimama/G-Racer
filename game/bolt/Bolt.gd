extends KinematicBody2D
class_name Bolt, "res://assets/class_icons/bolt_icon.png"


signal stat_changed (stat_owner, stat, stat_change) # bolt in damage

var bolt_owner: int
var bolt_color: Color = Color.white
var trail_pseudodecay_color = Color.white
var stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
var axis_distance: float # določen glede na širino sprajta
var input_power: float
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var rotation_angle: float
var rotation_dir: float
var collision: KinematicCollision2D
var lose_life_time: float = 2

# weapons
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trenutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 1 # poberem jo iz profilov, ali pa kot veleva pickable

# trail
var bolt_trail_active: bool = false # aktivna je ravno spawnana, neaktiva je "odklopljena"
var bolt_trail_alpha = 0.05

# engine
var engine_power = 0 # ob štartu je noga z gasa
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision # zaradi shielda ga moram imet
onready var shield: Sprite = $Shield
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var energy_bar_holder: Node2D = $EnergyBar
onready var energy_bar: Polygon2D = $EnergyBar/Bar

onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://game/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")
onready var Bullet: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var Misile: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var Shocker: PackedScene = preload("res://game/weapons/Shocker.tscn")

# bolt stats
onready var gas_count: float = Pro.default_bolt_stats["gas_count"]
onready var energy: float = Pro.default_bolt_stats["energy"]
onready var max_energy: float = Pro.default_bolt_stats["energy"] # zato, da se lahko resetira
onready var bullet_count: float = Pro.default_bolt_stats["bullet_count"]
onready var bullet_power: float = Pro.default_bolt_stats["bullet_power"]
onready var misile_count: float = Pro.default_bolt_stats["misile_count"]
onready var shocker_count: float = Pro.default_bolt_stats["shocker_count"]
# player stats
onready var player_life: int = Pro.default_player_stats["player_life"]
onready var player_points: int = Pro.default_player_stats["player_points"]
onready var player_wins: int = Pro.default_player_stats["player_wins"]
# bolt profil ... default vrednosti, ki jih lahko med igro spreminjam
onready var bolt_type: int = Pro.BoltTypes.BASIC
onready var bolt_sprite_texture: Texture = Pro.bolt_profiles[bolt_type]["bolt_texture"] 
onready var fwd_engine_power: int = Pro.bolt_profiles[bolt_type]["fwd_engine_power"]
onready var rev_engine_power: int = Pro.bolt_profiles[bolt_type]["rev_engine_power"]
onready var turn_angle: int = Pro.bolt_profiles[bolt_type]["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = Pro.bolt_profiles[bolt_type]["free_rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = Pro.bolt_profiles[bolt_type]["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = Pro.bolt_profiles[bolt_type]["side_traction"]
onready var bounce_size: float = Pro.bolt_profiles[bolt_type]["bounce_size"]
onready var inertia: float = Pro.bolt_profiles[bolt_type]["inertia"]
onready var reload_ability: float = Pro.bolt_profiles[bolt_type]["reload_ability"]  # reload def gre v weapons
onready var on_hit_disabled_time: float = Pro.bolt_profiles[bolt_type]["on_hit_disabled_time"] 

#NEU
onready var fwd_gas_usage: float = Pro.bolt_profiles[bolt_type]["fwd_gas_usage"] 
onready var rev_gas_usage: float = Pro.bolt_profiles[bolt_type]["rev_gas_usage"] 
onready var drag_force_quo: float = Pro.bolt_profiles[bolt_type]["drag_force_quo"] 
enum MotionStates {FWD, REV, IDLE} # glede na moč motorja
var current_motion_state: int = MotionStates.IDLE
var current_active_trail: Line2D
var bolt_active: bool = false setget _on_bolt_active_changed # predvsem za pošiljanje signala GMju


func _ready() -> void:

	printt("Bolt", name, bolt_owner)
	
	# bolt 
	add_to_group(Ref.group_bolts)	
	bolt_sprite.texture = bolt_sprite_texture
	axis_distance = bolt_sprite_texture.get_width()

	engines_setup() # postavi partikle za pogon
	
	# shield
	shield.modulate.a = 0 
	shield_collision.disabled = true 
	shield.self_modulate = bolt_color 
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)
	energy_bar_holder.hide()
	
	

func _physics_process(delta: float) -> void:
	# aktivacija pospeška je setana na vozniku
	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	
	# set motion states
	if engine_power > 0:
		current_motion_state = MotionStates.FWD
		manage_gas(fwd_gas_usage)
	elif engine_power < 0:
		current_motion_state = MotionStates.REV
		manage_gas(rev_gas_usage)
	elif engine_power == 0:
		current_motion_state = MotionStates.IDLE
		
	gas_count = clamp(gas_count, 0, gas_count)
	
	if bolt_active:
		if gas_count <= 0: # če zmanjka bencina je deaktiviran
			self.bolt_active = false
	else: 	
		drag_force_quo = lerp(drag_force_quo, 1, 0.05) # če je deaktiviran povečam drag in ga postopoma ustavim
	
	# sila upora raste s hitrostjo		
	var drag_force = drag * velocity * velocity.length() / drag_force_quo # množenje z velocity nam da obliko vektorja
		
	# hitrost je pospešek s časom
	acceleration -= drag_force
	velocity += acceleration * delta
	rotation_angle = rotation_dir * deg2rad(turn_angle)
	
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
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
		new_collision_particles.color = bolt_color
		new_collision_particles.set_emitting(true)
		Ref.node_creation_parent.add_child(new_collision_particles)
	
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false


func spawn_new_trail():
	
	var new_bolt_trail: Object
	new_bolt_trail = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	bolt_trail_active = true	
	
	return new_bolt_trail
	
	
func manage_trail():
	# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
	
	if velocity.length() > 0:
		
		current_active_trail.add_points(global_position)
		current_active_trail.gradient.colors[1] = trail_pseudodecay_color
		
		if velocity.length() > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	else:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena	
	

func manage_gas(gas_amount: float):
	
	gas_count += gas_amount
	gas_count = clamp(gas_count, 0, gas_count)
	emit_signal("stat_changed", bolt_owner, "gas_count", gas_count)	
	
				
func motion_fx():

	var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
	var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
	var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)	
	
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	
	# zadnji motor
	if current_motion_state == MotionStates.FWD:
		engine_particles_rear.modulate.a = velocity.length()/50
		engine_particles_rear.set_emitting(true)
		engine_particles_rear.global_position = to_global(rear_engine_pos)
		engine_particles_rear.global_rotation = bolt_sprite.global_rotation
		# spawn trail if not active
		if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
			current_active_trail = spawn_new_trail()
	elif current_motion_state == MotionStates.REV:
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
			current_active_trail = spawn_new_trail()

	# manage trail
	if bolt_trail_active:
		manage_trail()

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
	# if current_motion_state == MotionStates.FWD:
	# if fwd_motion:
	#	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	# elif current_motion_state == MotionStates.REV:
	# elif rev_motion:
	#	velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri

	
func update_energy_bar():
	
	if not energy_bar_holder.visible:
		energy_bar_holder.show()
		
	# energy_bar
	energy_bar_holder.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	energy_bar_holder.global_position = global_position + Vector2(0, 8) # negiramo rotacijo bolta, da je pri miru

	energy_bar.scale.x = energy / max_energy
	if energy_bar.scale.x < 0.5:
		energy_bar.color = Color.indianred
	else:
		energy_bar.color = Color.aquamarine		
			

# UTILITY ----------------------------------------------------------------------------


func lose_life():
	
	# shake camera
	Ref.current_camera.shake_camera(Ref.current_camera.bolt_explosion_shake)
	
	# ugasni tejl
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
	
	# "ugasni" motorje
#	engine_particles_rear.visible = false
#	engine_particles_front_left.visible = false
#	engine_particles_front_right.visible = false
	
	# spawnaj eksplozijo
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawned_by_color = bolt_color
	new_exploding_bolt.z_index = z_index + Set.explosion_z_index
	Ref.node_creation_parent.add_child(new_exploding_bolt)
	
	player_life -= 1
	emit_signal("stat_changed", bolt_owner, "player_life", player_life)
	
	bolt_collision.disabled = true
	visible = false
	set_physics_process(false)
	yield(get_tree().create_timer(lose_life_time), "timeout")
	
	# on new life
	bolt_collision.disabled = false
#	engine_particles_rear.visible = true
#	engine_particles_front_left.visible = true
#	engine_particles_front_right.visible = true
	energy = max_energy
	set_physics_process(true)
	visible = true
	
	
func engines_setup():
	
	engine_particles_rear = EngineParticles.instance()
	# rotacija se seta v FP
	engine_particles_rear.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_rear)
	engine_particles_rear.modulate.a = 0
	
	engine_particles_front_left = EngineParticles.instance()
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	engine_particles_front_left.modulate.a = 0
	# rotacija se seta v FP
	engine_particles_front_left.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	engine_particles_front_right.modulate.a = 0
	engine_particles_front_right.z_index = z_index + Set.engine_z_index
	# rotacija se seta v FP
	Ref.node_creation_parent.add_child(engine_particles_front_right)

		
func shooting(weapon: String) -> void:
	
	var gun_pos: Vector2 = Vector2(6.5, 0.5)
	var shocker_pos: Vector2 = Vector2(-4.5, 0.5)	
	
	match weapon:
		"bullet":	
			if bullet_reloaded:
				if bullet_count <= 0:
					return
				var new_bullet = Bullet.instance()
				new_bullet.global_position = to_global(gun_pos)
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = self # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				new_bullet.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_bullet)
				bullet_count -= 1
				emit_signal("stat_changed", bolt_owner, "bullet_count", bullet_count) # do GMa
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		"misile":
			if misile_reloaded and misile_count > 0:			
				var new_misile = Misile.instance()
				new_misile.global_position = to_global(gun_pos)
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				misile_count -= 1
				emit_signal("stat_changed", bolt_owner, "misile_count", misile_count) # do GMa
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		"shocker":
			if shocker_reloaded and shocker_count > 0:			
				var new_shocker = Shocker.instance()
				new_shocker.global_position = to_global(shocker_pos)
				new_shocker.global_rotation = bolt_sprite.global_rotation
				new_shocker.spawned_by = self # ime avtorja izstrelka
				new_shocker.spawned_by_color = bolt_color
				new_shocker.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_shocker)
				shocker_count -= 1
				emit_signal("stat_changed", bolt_owner, "shocker_count", shocker_count) # do GMa
				shocker_reloaded = false
				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
				shocker_reloaded= true

			
func activate_shield():
	
	if shields_on == false:
		shield.modulate.a = 1
		animation_player.play("shield_on")
		shields_on = true
		bolt_collision.disabled = true
		shield_collision.disabled = false
	else:
		animation_player.play_backwards("shield_on")
		# shields_on in collisions_setup premaknjena dol na konec animacije
		shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja


func activate_nitro(nitro_power: float, nitro_time: float):

	#	fwd_engine_power = nitro_power # vhodni fwd_engine_power spremenim, ker se ne seta na vsak frame (reset na po timerju)
	#	# pospešek
	#	var nitro_tween = get_tree().create_tween()
	#	nitro_tween.tween_property(self, "engine_power", nitro_power, 1) # pospešek spreminja engine_power, na katereg input ne vpliva
	#	nitro_tween.tween_property(self, "nitro_active", true, 0)
	#	# trajanje
	#	yield(get_tree().create_timer(nitro_time), "timeout")
	#	fwd_engine_power = Pro.bolt_profiles[bolt_type]["fwd_engine_power"]
	
	if bolt_active: # če ni aktiven se sam od sebe ustavi
		drag_force_quo = Pro.bolt_profiles[bolt_type]["drag_force_quo_nitro"]	
		yield(get_tree().create_timer(nitro_time), "timeout")
		drag_force_quo = Pro.bolt_profiles[bolt_type]["drag_force_quo"]	
	

func on_hit(hit_by: Node):
	
	if not shields_on:
		
		if hit_by.is_in_group(Ref.group_bullets):
			# shake camera
			Ref.current_camera.shake_camera(Ref.current_camera.bullet_hit_shake)
			# take damage
			take_damage(hit_by)
			# push
			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
			# utripne	
			modulate.a = 0.2
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate:a", 1, 0.1) 
			
		elif hit_by.is_in_group(Ref.group_misiles):
			bolt_active = false
			# shake camera
			Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
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
			bolt_active = true
			
		elif hit_by.is_in_group(Ref.group_shockers):
			bolt_active = false
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
			bolt_active = true


func get_points(points_added: int): # kličem od zunaj ob dodajanju točk
	
	player_points += points_added
	player_points = clamp(player_points, 0, player_points)
	emit_signal("stat_changed", bolt_owner, "player_points", player_points) # do GMa
	

func take_damage(hit_by: Node):
	
	var damage_amount: float = hit_by.hit_damage
	
	energy -= damage_amount
	energy = clamp(energy, 0, max_energy)
	energy_bar.scale.x = energy/10
	
	# za damage
	emit_signal("stat_changed", bolt_owner, "energy", energy) # do GMa
	
	if energy <= 0:
		lose_life()

	
func item_picked(pickable_type_key: String):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_type_key]["pickable_value"]
	var pickable_time: float = Pro.pickable_profiles[pickable_type_key]["pickable_time"]
	
	match pickable_type_key:
		"BULLET":
			bullet_count += pickable_value
			emit_signal("stat_changed", bolt_owner, "bullet_count", bullet_count) 
		"MISILE":
			misile_count += pickable_value
			emit_signal("stat_changed", bolt_owner, "misile_count", misile_count) 
		"SHOCKER":
			shocker_count += pickable_value
			emit_signal("stat_changed", bolt_owner, "shocker_count", shocker_count) 
		"SHIELD":
			shield_loops_limit = pickable_value
			activate_shield()
		"ENERGY":
			energy = max_energy
		"GAS":
			gas_count += pickable_value
			emit_signal("stat_changed", bolt_owner, "gas_count", gas_count)
		"LIFE":
			player_life += pickable_value
			emit_signal("stat_changed", bolt_owner, "player_life", player_life)
		"NITRO":
			activate_nitro(pickable_value, pickable_time)
		"TRACKING":
			var default_traction = side_traction
			side_traction = pickable_value
			yield(get_tree().create_timer(pickable_time), "timeout")
			side_traction = default_traction
		"RANDOM":
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			item_picked(random_pickable_key) # pick selected
			
			
# PRIVAT ------------------------------------------------------------------------------------------------

signal bolt_activity_changed (bolt_is_active)

func _on_bolt_active_changed(bolt_is_active: bool):
	
	bolt_active = bolt_is_active
	emit_signal("bolt_activity_changed", self)
#	print ("ACT", is_bolt_active)


func _on_shield_animation_finished(anim_name: String) -> void:
	
	shield_loops_counter += 1
	
	match anim_name:
		"shield_on":	
			# končan intro ... zaženi prvi loop
			if shield_loops_counter <= shield_loops_limit:
				animation_player.play("shielding")
			# končan outro ... resetiramo lupe in ustavimo animacijo
			else:
				animation_player.stop(false) # včasih sem rabil, da se ne cikla, zdaj pa je okej, ker ob
				shield_loops_counter = 0
				shields_on = false
				bolt_collision.disabled = false
				shield_collision.disabled = true
		"shielding":
			# dokler je loop manjši od limita ... replayamo animacijo
			if shield_loops_counter < shield_loops_limit:
				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
			# konec loopa, ko je limit dosežen
			elif shield_loops_counter >= shield_loops_limit:
				animation_player.play_backwards("shield_on")
