extends RigidBody2D
class_name Bolt


signal stats_changed (stats_owner_id, player_stats) # bolt in damage

enum MOTION {IDLE, FWD, REV, TILT, DISARRAY} # DIZZY, DYING glede na moč motorja
var current_motion: int = MOTION.IDLE setget _on_motion_change

var bolt_active: bool = false setget _on_bolt_activity_change # predvsem za pošiljanje signala GMju	

# player profil
var player_id: int # ga seta spawner
var player_name: String # za opredelitev statistike
var bolt_color: Color = Color.red
var bolt_sprite_texture: Texture
onready var player_profile: Dictionary = Pro.player_profiles[player_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]

# player stats
onready var player_stats: Dictionary = Pro.default_player_stats.duplicate()
onready var max_energy: float = player_stats["energy"] # zato, da se lahko resetira

# bolt settings
onready var bolt_profile: Dictionary = Pro.bolt_profiles[bolt_type].duplicate()
onready var ai_target_rank: int = bolt_profile["ai_target_rank"]
onready var max_engine_rotation_deg: float = bolt_profile["max_engine_rotation_deg"]
onready var max_idle_rotation_power: float = bolt_profile["max_idle_rotation_speed"]
onready var gas_usage: float = bolt_profile["gas_usage"]

# nodes
onready var bolt_sprite: Sprite = $BoltSprite
onready var trail_position: Position2D = $TrailPosition
onready var gun_position: Position2D = $GunPosition
	
# scene
onready var CollisionParticles: PackedScene = preload("res://game/bolt/fx/BoltCollisionParticles.tscn")
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/fx/EngineParticlesRear.tscn") 
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/fx/EngineParticlesFront.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/fx/ExplodingBolt.tscn")

# driving
var rotation_dir = 0
var bolt_direction = 0 # rikverc ali naprej # VEN
var bolt_global_rotation: float # _IF računa glede na gibanje telesa
var bolt_global_position: Vector2 # _IF računa glede na gibanje telesa
var bolt_velocity: Vector2 = Vector2.ZERO # _IF računa glede na gibanje telesa
var pseudo_stop_speed: float = 15 # hitrost pri kateri ga kar ustavim	
var idle_rotation_speed: float = 0
var force_rotation: float = 0 # rotacija v smeri skupne sile motorjev ... določam v _FP (input), apliciram v _IF

# racing
var bolt_position_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju  
var race_time_on_previous_lap: float = 0

# battle
var revive_time: float = 2
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var mina_reloaded: bool = true
var mina_released: bool # če je že odvržen v trenutni ožini
onready var reload_ability: float = bolt_profile["reload_ability"] # reload def gre v weapons

# engines
var engine_power = 0
var engine_rotation_speed: float = 0.03
onready var max_engine_power: float = bolt_profile["max_engine_power"]
onready var engine_hsp: float = bolt_profile["engine_hsp"] # reload def gre v weapons
onready var power_burst_hsp: float = bolt_profile["power_burst_hsp"] # reload def gre v weapons
var current_mass: RigidBody2D # OPT naj bo znotraj kode glede na uporabljen motor ... premik engine.gd kodo
var current_engines_rotation: float = 0 # wheels 
var current_engines: Array # sprednja ali zadnja
onready var front_engine: Node2D = $DriveTrain/FrontEngine
onready var front_mass: RigidBody2D = $DriveTrain/FrontEngine/RigidBody2D
onready var rear_engine: Node2D = $DriveTrain/RearEngine
onready var rear_mass: RigidBody2D = $DriveTrain/RearEngine/RigidBody2D

# neu
onready var direction_line: Line2D = $DirectionLine
onready var collision_shape: CollisionShape2D = $CollisionShape2D
var is_shielded: bool = false # VEN
onready var revive_timer: Timer = $ReviveTimer
var bolt_body_state: Physics2DDirectBodyState
# fx
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var active_trail: Line2D
var engines_on: bool = false
onready var bolt_controller: Node = $BoltController

	
func _ready() -> void:

	add_to_group(Ref.group_bolts)	
	player_name = player_profile["player_name"]
	# bolt
	if bolt_sprite_texture:
		bolt_sprite.texture = bolt_sprite_texture
	bolt_color = player_profile["player_color"] # bolt se obarva ... 	
	bolt_sprite.modulate = bolt_color	
	
	# bolt settings	
	mass = bolt_profile["mass"]
	linear_damp = bolt_profile["lin_damp_driving"]
	angular_damp = bolt_profile["ang_damp"]
	physics_material_override.friction = bolt_profile["friction"]
	physics_material_override.bounce = bolt_profile["bounce"]
	rear_mass.angular_damp = bolt_profile["rear_lin_damp"]

	spawn_bolt_controller()


func _process(delta: float) -> void:

	if not bolt_active:
		# če ni aktiven resetiram
		engine_power = 0
		rotation_dir = 0		
	else:		
		# v leru
		if current_motion == MOTION.IDLE:
			engine_power = 0
		# vozi
		else:
			engine_power += engine_hsp
			# fast start
			if Ref.game_manager.fast_start_window: 
				engine_power += power_burst_hsp
			engine_power = clamp(engine_power, 0, max_engine_power)
			update_gas(gas_usage)
		# lokalna rotacija motorja
		if rotation_dir == 0:
			current_engines_rotation = lerp(current_engines_rotation, 0, engine_rotation_speed * 10) # podobno hitro kot obračanje
		else:
			if current_motion == MOTION.TILT: # tiltam v vse smeri
				current_engines_rotation = deg2rad(90) * rotation_dir
			else:
				current_engines_rotation += rotation_dir * engine_rotation_speed
				current_engines_rotation = clamp(current_engines_rotation, - deg2rad(max_engine_rotation_deg), deg2rad(max_engine_rotation_deg))
		for thrust in get_engines_thrusts():
			thrust.rotation = current_engines_rotation
		# globalna rotacija sile
		#	force_rotation = current_engines_rotation + get_global_rotation() # RFK da ne striže prestavljeno v kontrolerja
	
	update_trail()
	

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	bolt_body_state = state
	bolt_velocity = get_linear_velocity()
	bolt_global_position = get_global_position()
	bolt_global_rotation = rotation # a je treba?

	if not bolt_active:
		# če ni aktiven resetiram vse sile, ki delujejo
		set_applied_force(Vector2.ZERO)
		set_applied_torque(0)
	else:	
		if current_motion == MOTION.IDLE: # idle rotacija
			set_applied_force(Vector2.ZERO)
			front_mass.set_applied_force(Vector2.ZERO)
			rear_mass.set_applied_force(Vector2.ZERO)
			linear_damp = bolt_profile["lin_damp_idle"]
			if not rotation_dir == 0:
				var rotation_acceleration: float = 15000
				idle_rotation_speed += rotation_acceleration
				idle_rotation_speed = clamp(idle_rotation_speed, 0, max_idle_rotation_power)
				set_applied_torque(idle_rotation_speed * rotation_dir)	
			else:
				set_applied_torque(0)
				idle_rotation_speed = 0	
		else:
			linear_damp = bolt_profile["lin_damp_driving"]
			var force: Vector2 = Vector2.RIGHT.rotated(force_rotation) * 100 * engine_power * bolt_direction
			if current_motion == MOTION.TILT:
				set_applied_force(force)
			else:
				set_applied_force(Vector2.ZERO) # tilt main body reset
				if current_mass: # sila na trenutni motor
					current_mass.set_applied_force(force)
				else:
					current_mass.set_applied_force(Vector2.ZERO)
			
			# debug
			var vector_to_target = force.normalized() * 100
			vector_to_target = vector_to_target.rotated(- get_global_rotation())# - get_global_rotation())
			direction_line.set_point_position(1, vector_to_target)	


# BATTLE ----------------------------------------------------------------------------


func shoot(weapon_index: int) -> void:

	weapon_index = 2 # debug
	
	match weapon_index: # enum zaporedje # OPT z enum keys
		0: # "bullet":
			if bullet_reloaded:
				if player_stats["bullet_count"] <= 0:
					return
				
				var BulletScene: PackedScene = Pro.weapon_profiles[Pro.WEAPON.BULLET]["scene"]
				var new_bullet = BulletScene.instance()
				new_bullet.global_position = gun_position.global_position
				new_bullet.global_rotation = bolt_global_rotation
				new_bullet.spawned_by = self # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				new_bullet.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_bullet)
				
				update_stat("bullet_count", - 1)
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
				
		1: # "misile":
			if misile_reloaded and player_stats["misile_count"] > 0:
				
				var MisileScene: PackedScene = Pro.weapon_profiles[Pro.WEAPON.MISILE]["scene"]
				var new_misile = MisileScene.instance()
				new_misile.global_position = gun_position.global_position
				new_misile.global_rotation = bolt_global_rotation #bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = bolt_velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				
				update_stat("misile_count", - 1)
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
				
		2: # "mina":
			if mina_reloaded and player_stats["mina_count"] > 0:	
						
				var MinaScene: PackedScene = Pro.weapon_profiles[Pro.WEAPON.MINA]["scene"]
				var new_mina = MinaScene.instance()
				new_mina.global_position = gun_position.global_position # _temp pozicija mine
				new_mina.global_rotation = bolt_global_rotation
				new_mina.spawned_by = self # ime avtorja izstrelka
				new_mina.spawned_by_color = bolt_color
				new_mina.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_mina)
				
				update_stat("mina_count", - 1)
				mina_reloaded = false
				yield(get_tree().create_timer(new_mina.reload_time / reload_ability), "timeout")
				mina_reloaded = true


func on_hit(hit_by: Node):
	
	if is_shielded:
		return

	if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		update_stat("energy", - hit_by.hit_damage)
			
	if hit_by.is_in_group(Ref.group_bullets):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia)		
		Ref.current_camera.shake_camera(Ref.current_camera.bullet_hit_shake)
		
	elif hit_by.is_in_group(Ref.group_misiles):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		#		apply_central_impulse(hit_by_inertia)
		# get_contact_collider_position(contact_idx: int) # ... Returns the contact position in the collider.
		# get_contact_collider_velocity_at_position(contact_idx: int) # Returns the linear velocity vector at the collider's contact point.
		# get_contact_impulse(contact_idx: int) # Impulse created by the contact. Only implemented for Bullet physics.
		#		var hit_position: Vector2 = 
		#		var global_hit_position: Vector2 = to_global(hit_position)
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia) # OPT impuls offset ne deluej
		#		apply_impulse( to_global(Vector2.RIGHT * bolt_sprite.texture.get_size().x/2), hit_by_inertia) # debug
		Met.spawn_indikator(bolt_body_state.get_contact_collider_position(0), rotation, self, true) # debug ... indi
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		Ref.sound_manager.play_sfx("bolt_explode")
		if Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE: 
			explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa
		
	elif hit_by.is_in_group(Ref.group_mine):
		var inertia_factor: float = 400000
		var hit_by_power: float = inertia_factor
		apply_torque_impulse(hit_by_power)
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		
	# energy management	
	if player_stats["energy"] <= 0:
		lose_life()


func lose_life():

	stop_engines()
	explode()
	update_stat("life", - 1)
	
	if player_stats["life"] > 0:
		revive_timer.start(revive_time)
	else:
		queue_free()


func explode():
	
	# disable staf
	collision_shape.set_deferred("disabled", true)
	#	collision_shape.disabled = true
	if active_trail: # ugasni tejl
		active_trail.start_decay() # trail decay tween start
	visible = false
	bolt_controller.set_process_input(false)		
	set_physics_process(false)
	# resetira na revive
	#	set_applied_force(Vector2.ZERO)	
	#	set_applied_torque(0)	
	
	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = bolt_global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = bolt_velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawned_by_color = bolt_color
	new_exploding_bolt.z_index = z_index + Set.explosion_z_index
	Ref.node_creation_parent.add_child(new_exploding_bolt)	

	Ref.current_camera.shake_camera(Ref.current_camera.bolt_explosion_shake)
		

func revive_bolt():
	
	# reset pred prikazom
	collision_shape.set_deferred("disabled", false)
	#	collision_shape.disabled = false
	set_applied_force(Vector2.ZERO)
	set_applied_torque(0)
	rotation_dir = 0
	engine_power = 0
	
	# set idle
	bolt_controller.set_process_input(true)		
	set_physics_process(true)
	current_motion = MOTION.IDLE
	visible = true
	self.bolt_active = true
	
	# reset energije
	var difference_to_max_energy: float = max_energy - player_stats["energy"] # na tak način, ker energijo stats prištevajo
	update_stat("energy", difference_to_max_energy)


# UTILITY ----------------------------------------------------------------------------
	
	
func get_engines_thrusts(): # VEN ne kompliciraj

	var current_thrusts: Array = []# temp
	for engine in current_engines:
		for child in engine.get_children():
			if child.name.find("Thrust") > -1:
				current_thrusts.append(child)	
	
	return current_thrusts
	
	
func stop_engines():

	engines_on = false
	
	if $Sounds/Engine.is_playing():
		var current_engine_volume: float = $Sounds/Engine.get_volume_db()
		var engine_stop_tween = get_tree().create_tween()
		engine_stop_tween.tween_property($Sounds/Engine, "pitch_scale", 0.5, 2)
		engine_stop_tween.tween_property($Sounds/Engine, "volume_db", -80, 2)
		yield(engine_stop_tween, "finished")
		$Sounds/Engine.stop()
		$Sounds/Engine.volume_db = current_engine_volume
	$Sounds/EngineRevup.stop()
	$Sounds/EngineStart.stop()
	
	
func start_engines():
	
	engines_on = true
	$Sounds/EngineStart.play()


func manipulate_tracking(tracking_damp: float, tracking_time: float = 0):
	
	rear_mass.linear_damp = tracking_damp
	if not tracking_time == 0: # pomeni, da se samo seta, in se bo od zunaj resetala
		yield(get_tree().create_timer(tracking_time), "timeout")
		rear_mass.linear_damp = bolt_profile["rear_lin_damp"]


func manipulate_engine_power(new_engine_power: float, power_time: float = 0):
	
	engine_power = new_engine_power # OPT tweenaj
	max_engine_power = new_engine_power
	if not power_time == 0: # pomeni, da se samo seta, in se bo od zunaj resetala
		yield(get_tree().create_timer(power_time), "timeout")
		max_engine_power = bolt_profile["max_engine_power"]
	
		
func update_gas(used_amount: float):
		
	update_stat("gas_count", used_amount)
	
	if player_stats["gas_count"] <= 0: # če zmanjka bencina je deaktiviran
		player_stats["gas_count"] = 0
		self.bolt_active = false
		
		
func update_bolt_points(points_change: int):
	
	update_stat("points", points_change)
	

func update_bolt_rank(new_bolt_rank: int):
	
	update_stat("level_rank", new_bolt_rank)


func update_stat(stat_name: String, change_value: float):
	 
	if not Ref.game_manager.game_on:
		return
			
	if stat_name == "best_lap_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_rank": 
		player_stats[stat_name] = change_value
	else:
		player_stats[stat_name] += change_value # change_value je + ali -
		
	emit_signal("stats_changed", player_id, player_stats)


func update_trail():
	
	# spawn trail if not active
	if not active_trail and bolt_velocity.length() > pseudo_stop_speed: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and bolt_velocity.length() > pseudo_stop_speed:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(bolt_global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if bolt_velocity.length() > pseudo_stop_speed and active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	elif active_trail and bolt_velocity.length() <= pseudo_stop_speed:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func lap_finished(level_lap_limit: int):
	
	# lap time
	var current_race_time: float = Ref.hud.game_timer.game_time_hunds
	var current_lap_time: float = current_race_time - race_time_on_previous_lap # če je slednja 0, je prvi krog
	var best_lap_time: float = player_stats["best_lap_time"]
	if current_lap_time < best_lap_time or best_lap_time == 0:
		update_stat("best_lap_time", current_lap_time)
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, true)
	else:
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, false)

	update_stat("laps_count", 1)
	
	race_time_on_previous_lap = current_race_time # za naslednji krog
	
	if player_stats["laps_count"] >= level_lap_limit: # trenutno končan krog je že dodan
		Ref.game_manager.bolts_finished.append(self)
		update_stat("level_time", current_race_time)
		drive_out()
	

func pull_bolt_on_screen(pull_position: Vector2, current_leader: RigidBody2D):
	
	#	Met.spawn_indikator(pull_position, rotation, self) # debug ... indi

	# disejblam koližne
	bolt_controller.set_process_input(false)
	collision_shape.set_deferred("disabled", true)
	#	shield_collision.set_deferred("disabled", true)	

	# reštartam trail
	if active_trail:
		active_trail.start_decay() # trail decay tween start

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(bolt_body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	bolt_controller.set_process_input(true)
	# print("KJE SI")

	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	if player_stats["laps_count"] < current_leader.player_stats["laps_count"]:
		var laps_finished_difference: int = current_leader.player_stats["laps_count"] - player_stats["laps_count"]
		update_stat("laps_count", laps_finished_difference)

	# če preskoči checkpoint, ga dodaj, če ga leader ima
	var all_checked_bolts: Array = Ref.game_manager.bolts_checked
	if all_checked_bolts.has(current_leader):
		all_checked_bolts.append(self)

	# ne dela
	#	if Ref.game_manager.current_pull_positions.has(pull_position):
	#		Ref.game_manager.current_pull_positions.erase(pull_position)

	update_gas(Ref.game_manager.game_settings["pull_gas_penalty"])


func screen_wrap():
	
	# kopirano iz tutoriala ---> https://www.youtube.com/watch?v=xsAyx2r1bQU
	var xform = bolt_body_state.get_transform()
	var screensize: Vector2 = get_viewport_rect().size
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	elif xform.origin.x < 0:
		xform.origin.x = screensize.x
	elif xform.origin.y > screensize.y:
		xform.origin.y = 0
	elif xform.origin.y < 0:
		xform.origin.y = screensize.y
	if not bolt_active:
		return
	bolt_body_state.set_transform(xform)	
	

func drive_in():
	
	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	start_engines()
	
	var drive_in_time: float = 2	
	var drive_in_finished_position: Vector2 = bolt_global_position
	var drive_in_vector: Vector2 = Ref.current_level.drive_in_position.rotated(Ref.current_level.race_start.global_rotation)
	var drive_in_start_position: Vector2 = bolt_global_position + drive_in_vector
	# premaknem ga nazaj in zapeljem do linije
	bolt_body_state.transform.origin = drive_in_start_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(bolt_body_state, "transform:origin", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")
	
	collision_shape.set_deferred("disabled", false)
	self.bolt_active = true
	
	
func drive_out():
	
	collision_shape.set_deferred("disabled", true)
	self.bolt_active = false
	
	var drive_out_time: float = 2
	var drive_out_vector: Vector2 = Ref.current_level.drive_out_position.rotated(Ref.current_level.race_finish.global_rotation)
	var drive_out_position: Vector2 = bolt_global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)
	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(bolt_body_state, "transform:rotated", angle_to_vector, drive_out_time/5) # OPT a finish line rotacija dela?
	drive_out_tween.tween_property(bolt_body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	stop_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), bolt_controller.ai_target)
	#	set_applied_force(Vector2.ZERO)
	#	set_applied_torque(0)
	#	set_physics_process(false)
	#	current_motion = MOTION.IDLE
	
			
func item_picked(pickable_key: int):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
	var pickable_time: float = Pro.pickable_profiles[pickable_key]["time"]
	
	match pickable_key:
		Pro.PICKABLE.PICKABLE_BULLET:
			if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
				player_stats["misile_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("bullet_count", pickable_value)
		Pro.PICKABLE.PICKABLE_MISILE:
			if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("misile_count", pickable_value)
		Pro.PICKABLE.PICKABLE_MINA:
			if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["misile_count"] = 0
			update_stat("mina_count", pickable_value)
		Pro.PICKABLE.PICKABLE_SHIELD:
			spawn_shield(pickable_value, pickable_time)
		Pro.PICKABLE.PICKABLE_ENERGY:
			player_stats["energy"] = max_energy
		Pro.PICKABLE.PICKABLE_GAS:
			update_stat("gas_count", pickable_value)
		Pro.PICKABLE.PICKABLE_LIFE:
			update_stat("life", pickable_value)
		Pro.PICKABLE.PICKABLE_NITRO:
			manipulate_engine_power(pickable_value, pickable_time)
		Pro.PICKABLE.PICKABLE_TRACKING:
			manipulate_engine_power(pickable_value, pickable_time)
		Pro.PICKABLE.PICKABLE_POINTS:
			update_bolt_points(pickable_value)
		Pro.PICKABLE.PICKABLE_RANDOM:
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			item_picked(random_pickable_key) # pick selected

		
func spawn_new_trail(): # OPT trail kodo v engine kodo
	
	var BoltTrail: PackedScene = preload("res://game/bolt/fx/BoltTrail.tscn")
	var new_bolt_trail: Line2D = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	new_bolt_trail.width = 20
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	# signal za deaktivacijo, če ni bila že prej
	new_bolt_trail.connect("trail_is_exiting", self, "_on_trail_exiting")
	
	return new_bolt_trail		


func spawn_shield(shield_duration: float, shield_time: float):
	
	var ShieldScene: PackedScene = Pro.weapon_profiles[Pro.WEAPON.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = bolt_global_position
	new_shield.spawned_by = self # ime avtorja izstrelka
	new_shield.z_index = z_index + Set.weapons_z_index
	new_shield.scale = Vector2.ONE * 4
	new_shield.shield_time = shield_duration
	
	Ref.node_creation_parent.add_child(new_shield)

	
func spawn_bolt_controller():

	 # zbrišem placeholder
	bolt_controller.queue_free()
	
	# opredelim controller sceno
	var players_controller_profile: Dictionary = Pro.controller_profiles[player_profile["controller_type"]]	
	var BoltController: PackedScene = players_controller_profile["controller_scene"]
	
	# spawn na vrh boltovega drevesa
	bolt_controller = BoltController.instance()
	bolt_controller.controlled_bolt = self 
	bolt_controller.controller_type = player_profile["controller_type"]
	call_deferred("add_child", bolt_controller)
	call_deferred("move_child", bolt_controller, 0)
	
	
# PRIVAT ------------------------------------------------------------------------------------------------


func _on_bolt_activity_change(bolt_is_active: bool):
	
	bolt_active = bolt_is_active
	#	printt("bolt_active", bolt_is_active, self)		
	
	# če je aktiven ga upočasnim v trenutni smeri
	var deactivate_time: float = 1.5
	
	match bolt_active:
		false:
			rotation_dir = 0
			engine_power = 0
			bolt_controller.set_process_input(false)
			stop_engines() # nočeš ga skos slišat, če je multiplejer
			Ref.game_manager.check_for_level_finished()
		true:	
			bolt_controller.set_process_input(true)
			
	
func _on_motion_change(new_motion: int):
	
	if current_motion == new_motion:
		return
	
	# resetiram trenutni engine
	if current_mass:
		current_mass.set_applied_force(Vector2.ZERO)
	idle_rotation_speed = 0 # OPT al tukej al _IF?
	set_applied_torque(0)  # OPT al tukej al _IF
	# thrust
	
	for thrust in get_engines_thrusts():
		thrust.rotation = 0
		thrust.stop_fx()	
		
	# nastavim nov engine		
	current_motion = new_motion
	match current_motion:
		MOTION.FWD:
			current_mass = front_mass
			bolt_direction = 1
			current_engines = [front_engine]
#			for child in current_engines[0].get_children():
#				if child.name.find("Thrust") > -1:
#					current_thrusts.append(child)
			for thrust in get_engines_thrusts():
				thrust.start_fx()
		MOTION.REV:
			current_engines = [rear_engine]
			current_mass = rear_mass
			bolt_direction = -1
#			current_engines = [$DriveTrain/RearEngine/ThrustL, $DriveTrain/RearEngine/ThrustR]
#			for child in current_engines[0].get_children():
#				if child.name.find("Thrust") > -1:
#					current_thrusts.append(child)
			for thrust in get_engines_thrusts():
				thrust.start_fx(true)
		MOTION.TILT:
			bolt_direction = 1
			current_engines = [front_engine, rear_engine]
#			for thrust in get_engines_thrusts([rear_engine]):
#			for engine in current_engines:
#				for child in engine.get_children():
#					if child.name.find("Thrust") > -1:
#						current_thrusts.append(child)
##			current_engines = [$DriveTrain/FrontEngine/ThrustL, $DriveTrain/FrontEngine/ThrustR, $DriveTrain/RearEngine/ThrustL, $DriveTrain/RearEngine/ThrustR]
		MOTION.IDLE:
			bolt_direction = 0
			current_mass = null


func _on_trail_exiting(exiting_trail: Line2D):
	
	if exiting_trail == active_trail:
		active_trail = null
	

func _on_ReviveTimer_timeout() -> void:
	
	revive_bolt()

	
func _on_Bolt_body_entered(body: Node) -> void:
	
	if not $Sounds/HitWall2.is_playing():
		$Sounds/HitWall.play()
		$Sounds/HitWall2.play()

	# odbojni partikli
	if bolt_velocity.length() > pseudo_stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = bolt_body_state.get_contact_local_position(0)
		new_collision_particles.rotation = bolt_body_state.get_contact_local_normal(0).angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = (bolt_velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
		new_collision_particles.color = bolt_color
		new_collision_particles.set_emitting(true)
		Ref.node_creation_parent.add_child(new_collision_particles)

	if active_trail:
		active_trail.start_decay() # trail decay tween start
	

func _exit_tree() -> void: # pospravljanje morebitnih smeti

	# da ne pušča smeti za sabo 

	#	for sound in sounds.get_children():
	#		sound.stop()
	#	if engine_particles_rear:
	#		engine_particles_rear.queue_free()
	#	if engine_particles_front_left:
	#		engine_particles_front_left.queue_free()
	#	if engine_particles_front_right:
	#		engine_particles_front_right.queue_free()
	##	active_trail.start_decay() # trail decay tween start
	
	self.bolt_active = false # zazih
	if Ref.current_camera.follow_target == self:
		Ref.current_camera.follow_target = null
