extends RigidBody2D
class_name TheBolt


signal stats_changed (stats_owner_id, player_stats) # bolt in damage


enum EnginesOn {FRONT, BACK, BOTH, NONE}
var current_engines_on: int = EnginesOn.NONE setget _change_engine_on

var bolt_active: bool = false setget _on_bolt_active_changed # predvsem za pošiljanje signala GMju	

# player profil
var bolt_id: int # ga seta spawner
var player_name: String # za opredelitev statistike
var bolt_color: Color = Color.red
var bolt_sprite_texture: Texture
onready var player_profile: Dictionary = Pro.player_profiles[bolt_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]
onready var controller_profile_key: int = player_profile["controller_profile"]

# player stats
onready var player_stats: Dictionary = Pro.default_player_stats.duplicate()
onready var max_energy: float = player_stats["energy"] # zato, da se lahko resetira

# bolt settings
onready var bolt_profile: Dictionary = Pro.bolt_profiles[bolt_type].duplicate()
onready var ai_target_rank: int = bolt_profile["ai_target_rank"]
onready var reload_ability: float = bolt_profile["reload_ability"] # reload def gre v weapons
onready var max_thrust_rotation_deg: float = bolt_profile["max_engine_rotation_deg"]
onready var max_idle_rotation_power: float = bolt_profile["max_idle_rotation_speed"]
onready var gas_usage: float = bolt_profile["gas_usage"]

# nodes
onready var bolt_sprite: Sprite = $BoltSprite
onready var bolt_body: RigidBody2D = $PinJoint2D/Body
onready var rigid_back: RigidBody2D = $RearPin/Rear
onready var rigid_front: RigidBody2D = $FrontPin/Front
onready var bolt_controller: Node = $BoltController
onready var rear_engine_position: Position2D = $RearEnginePosition # mina position
onready var trail_position: Position2D = $TrailPosition
onready var gun_position: Position2D = $GunPosition
	
# scene
onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/EngineParticlesRear.tscn") 
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/EngineParticlesFront.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")

# driving
var rotation_dir = 0
var engine_hsp = 3
var max_engine_power: float = 350
var current_engine_power: float = 0
var edited_engine: RigidBody2D
var wheels_to_turn: Array
var forward_direction: int = 0 # rikverc ali naprej
var engine_thrust_rotation: float = 0 # wheels 
var thrust_direction_rotation: float 
var rotation_speed: float = 0.03
var velocity: Vector2 = Vector2.ZERO
var idle_rotation_speed: float = 0
var stop_speed: float = 15 # hitrost pri kateri ga kar ustavim	

# racing
var bolt_position_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju  
var race_time_on_previous_lap: float = 0

# battle
var revive_time: float = 2
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var mina_reloaded: bool = true
var mina_released: bool # če je že odvržen v trenutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 1 # poberem jo iz profilov, ali pa kot veleva pickable
onready var BulletScene: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var MisileScene: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var MinaScene: PackedScene = preload("res://game/weapons/Mina.tscn")

# neu
onready var direction_line: Line2D = $DirectionLine
var bolt_trail_active: bool = false # aktivna je ravno spawnana, neaktiva je "odklopljena"
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var current_active_trail: Line2D


func _ready() -> void:
	
	#	scale = Vector2(0.1,0.1)
	#	add_to_group(Ref.group_bolts)	
	add_to_group(Ref.group_thebolts)	
	add_to_group(Ref.group_players)	
	
	player_name = player_profile["player_name"]
	
	# bolt
	if bolt_sprite_texture:
		bolt_sprite.texture = bolt_sprite_texture
	bolt_color = player_profile["player_color"] # bolt se obarva ... 	
	bolt_sprite.modulate = bolt_color	
	
	#	bolt_shadow.shadow_distance = bolt_max_altitude
	bolt_controller.set_controller(controller_profile_key)
	
	# bolt settings	
	mass = bolt_profile["mass"]
	linear_damp = bolt_profile["lin_damp_driving"]
	angular_damp = bolt_profile["ang_damp"]
	rigid_back.angular_damp = bolt_profile["rear_lin_damp"]
	

func _process(delta: float) -> void:
	# power
	if current_engines_on == EnginesOn.NONE:
		current_engine_power = 0
	else:
		current_engine_power += engine_hsp
		current_engine_power = clamp(current_engine_power, 0, max_engine_power)
	
	# rotation
	if rotation_dir == 0:
		engine_thrust_rotation = 0
	else:
		engine_thrust_rotation += rotation_dir * rotation_speed
		engine_thrust_rotation = clamp(engine_thrust_rotation, - deg2rad(max_thrust_rotation_deg), deg2rad(max_thrust_rotation_deg))
		
		var bolt_body_rotation: float = get_global_rotation()
		thrust_direction_rotation = engine_thrust_rotation + bolt_body_rotation

	for wheel in wheels_to_turn:
		wheel.rotation = engine_thrust_rotation

	# manage trail
	if bolt_trail_active:
		manage_trail()
	
	# poraba bencina
	#	if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
	#		if current_motion_state == MotionStates.FWD:
	manage_gas(gas_usage)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	velocity = get_linear_velocity()
	
	if current_engines_on == EnginesOn.NONE:
		set_applied_force(Vector2.ZERO)
		
		rigid_front.set_applied_force(Vector2.ZERO)
		rigid_back.set_applied_force(Vector2.ZERO)
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
		var force: Vector2 
		if current_engines_on == EnginesOn.BOTH:
			force = Vector2(0, rotation_dir).rotated(get_global_rotation()) * 100 * current_engine_power
			set_applied_force(force)
		else:
			set_applied_force(Vector2.ZERO)
			force = Vector2.RIGHT.rotated(thrust_direction_rotation) * 100 * current_engine_power * forward_direction
			if edited_engine:
				if not current_engine_power == 0:
					edited_engine.set_applied_force(force)
				else:
					edited_engine.set_applied_force(Vector2.ZERO)
		# debug
		var vector_to_target = force.normalized() * 100
		vector_to_target = vector_to_target.rotated(- get_global_rotation())# - get_global_rotation())
		direction_line.set_point_position(1, vector_to_target)	


# BATTLE ----------------------------------------------------------------------------


func shoot(weapon_index: int) -> void:
	
	match weapon_index:
		0: # "bullet":
			if bullet_reloaded:
				if player_stats["bullet_count"] <= 0:
					return
				var new_bullet = BulletScene.instance()
				new_bullet.global_position = gun_position.global_position
				new_bullet.global_rotation = bolt_sprite.global_rotation
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
				var new_misile = MisileScene.instance()
				new_misile.global_position = gun_position.global_position
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				update_stat("misile_count", - 1)
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		2: # "mina":
			if mina_reloaded and player_stats["mina_count"] > 0:			
				var new_mina = MinaScene.instance()
				new_mina.global_position = rear_engine_position.global_position
				new_mina.global_rotation = bolt_sprite.global_rotation
				new_mina.spawned_by = self # ime avtorja izstrelka
				new_mina.spawned_by_color = bolt_color
				new_mina.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_mina)
				update_stat("mina_count", - 1)
				mina_reloaded = false
				yield(get_tree().create_timer(new_mina.reload_time / reload_ability), "timeout")
				mina_reloaded = true


func on_hit(hit_by: Node):
	
	if shields_on:
		return

	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		update_stat("energy", - hit_by.hit_damage)
				
	if hit_by.is_in_group(Ref.group_bullets):
		Ref.current_camera.shake_camera(Ref.current_camera.bullet_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity / mass
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_misiles):
		
		Ref.sound_manager.play_sfx("bolt_explode")
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE: 
			explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_mine):
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		in_disarray(hit_by.hit_damage)
		
	# energy management	
	if player_stats["energy"] <= 0:
		lose_life()


func lose_life():
	
#	stop_engines()
	explode()
#	bolt_collision.disabled = true
	visible = false
	set_process_input(false)		
	set_physics_process(false)
	
	update_stat("life", - 1)
	
	if player_stats["life"] > 0:
		revive_bolt()
	else:
		self.bolt_active = false
		queue_free()
	

func revive_bolt():
	
	print("revieve")
	yield(get_tree().create_timer(revive_time), "timeout")
	# on new life
#	bolt_collision.disabled = false
	# reset pred prikazom
#	current_motion_state = MotionStates.IDLE
#	dissaray_tween.kill()
#	velocity = Vector2.ZERO
	rotation_dir = 0
	current_engine_power = 0
	set_process_input(true)		
	set_physics_process(true)
	visible = true
	self.bolt_active = true
	
	var difference_to_max_energy: float = max_energy - player_stats["energy"]
	update_stat("energy", difference_to_max_energy)


# UTILITY ----------------------------------------------------------------------------

	
func on_lap_finished(level_lap_limit: int):
	
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
		self.bolt_active = false # more bit za spremembo statistike
		drive_out()
	

func manage_trail():
	# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
	var velocity_len = get_linear_velocity().length()
	
	if velocity_len > 0:
	#	if velocity.length() > 0:
		
		current_active_trail.add_points(global_position)
		current_active_trail.gradient.colors[1] = trail_pseudodecay_color
		
		#		if velocity.length() > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
		if velocity_len > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
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

		
func spawn_new_trail():
	
	var new_bolt_trail: Object
	new_bolt_trail = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	bolt_trail_active = true	
	
	return new_bolt_trail		


func explode():
	
	# efekti in posledice
	Ref.current_camera.shake_camera(Ref.current_camera.bolt_explosion_shake)
	if bolt_trail_active: # ugasni tejl
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawned_by_color = bolt_color
	new_exploding_bolt.z_index = z_index + Set.explosion_z_index
	Ref.node_creation_parent.add_child(new_exploding_bolt)	

	
func on_item_picked(pickable_key: int):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
	
	match pickable_key:
		Pro.Pickables.PICKABLE_BULLET:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["misile_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("bullet_count", pickable_value)
		Pro.Pickables.PICKABLE_MISILE:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("misile_count", pickable_value)
		Pro.Pickables.PICKABLE_MINA:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["misile_count"] = 0
			update_stat("mina_count", pickable_value)
		Pro.Pickables.PICKABLE_SHIELD:
			shield_loops_limit = pickable_value
#			activate_shield()
		Pro.Pickables.PICKABLE_ENERGY:
			player_stats["energy"] = max_energy
		Pro.Pickables.PICKABLE_GAS:
			update_stat("gas_count", pickable_value)
		Pro.Pickables.PICKABLE_LIFE:
			update_stat("life", pickable_value)
		Pro.Pickables.PICKABLE_NITRO:
#			activate_nitro(pickable_value, Pro.pickable_profiles[pickable_key]["duration"])
			pass
		Pro.Pickables.PICKABLE_TRACKING:
#			var default_traction = side_traction
#			side_traction = pickable_value
#			yield(get_tree().create_timer(Pro.pickable_profiles[pickable_key]["duration"]), "timeout")
#			side_traction = default_traction
			pass
		Pro.Pickables.PICKABLE_POINTS:
			update_bolt_points(pickable_value)
		Pro.Pickables.PICKABLE_RANDOM:
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			on_item_picked(random_pickable_key) # pick selected
		

# PRIVAT ------------------------------------------------------------------------------------------------


func _on_bolt_active_changed(bolt_is_active: bool):
	
	bolt_active = bolt_is_active
	# če je aktiven ga upočasnim v trenutni smeri
	#	var deactivate_time: float = 1.5
	#	if bolt_active == false:
	#		rotation_dir = 0
	#		var deactivate_tween = get_tree().create_tween()
	#		deactivate_tween.tween_property(self, "velocity", Vector2.ZERO, deactivate_time) # tajmiram pojemek 
	#		deactivate_tween.parallel().tween_property(self, "engine_power", 0, deactivate_time)
	#		stop_engines()
	#		Ref.game_manager.check_for_level_finished()
		
	printt("bolt_active", bolt_is_active, self)		
	
	
func _change_engine_on(new_engine_on: int):
	
	if current_engines_on == new_engine_on:
		return
	
	# resetiram trenutni engine
	if edited_engine:
		edited_engine.set_applied_force(Vector2.ZERO)
	# če je rotiral na mestu
	idle_rotation_speed = 0
	set_applied_torque(0) 
	# thrust
	for wheel in wheels_to_turn:
		wheel.rotation = 0
		wheel.get_node("ThrustFx").stop_fx()	
		
	# nastavim nov engine		
	current_engines_on = new_engine_on

	match current_engines_on:
		EnginesOn.FRONT:
			edited_engine = rigid_front
			forward_direction = 1
			wheels_to_turn = [$Wheels/WheelFrontL, $Wheels/WheelFrontR]
			for wheel in wheels_to_turn:
				wheel.get_node("ThrustFx").start_fx()
		EnginesOn.BACK:
			edited_engine = rigid_back
			forward_direction = -1
			wheels_to_turn = [$Wheels/WheelRearL, $Wheels/WheelRearR]
			for wheel in wheels_to_turn:
				wheel.get_node("ThrustFx").start_fx(true)
		EnginesOn.BOTH:
			forward_direction = 1
			wheels_to_turn = [$Wheels/WheelFrontL, $Wheels/WheelFrontR, $Wheels/WheelRearL, $Wheels/WheelRearR]
		EnginesOn.NONE:
			forward_direction = 0
			edited_engine = null
	
	
# STATS ------------------------------------------------------------------------------------------------


func manage_gas(gas_usage: float):
	
	if not bolt_active: 
		return
		
	update_stat("gas_count", gas_usage)
	
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
		
	emit_signal("stats_changed", bolt_id, player_stats)

			
func _exit_tree() -> void:
	#	for sound in sounds.get_children():
	#		sound.stop()
	#	if engine_particles_rear:
	#		engine_particles_rear.queue_free()
	#	if engine_particles_front_left:
	#		engine_particles_front_left.queue_free()
	#	if engine_particles_front_right:
	#		engine_particles_front_right.queue_free()
	##	current_active_trail.start_decay() # trail decay tween start
	#	bolt_trail_active = false
	if Ref.current_camera.follow_target == self:
		Ref.current_camera.follow_target = null


# PRAZNE ... ZA POPEDENAT ---------------------------------------------------------------------------------------------------------------------------------------------------


func in_disarray(damage_amount: float): # 5 raketa, 1 metk
	
#	current_motion_state = MotionStates.DISARRAY
#	set_process_input(false)		
#	var dissaray_time_factor: float = 0.6 # uravnano, da naredi pol kroga na 1 damage
#	var disarray_rotation_dir: float = damage_amount # vedno je -1, 0, ali +1, samo tukaj jo povečam, da dobim hitro rotacijo
#	var on_hit_disabled_time: float = dissaray_time_factor * damage_amount
#	# random disarray direction
#	var dissaray_random_direction = randi() % 2
#	if dissaray_random_direction == 0:
#		rotation_dir = - disarray_rotation_dir
#	else:
#		rotation_dir = disarray_rotation_dir
#	dissaray_tween = get_tree().create_tween()
#	dissaray_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
#	dissaray_tween.parallel().tween_property(self, "rotation_dir", 0, on_hit_disabled_time)#.set_ease(Tween.EASE_IN) # tajmiram pojemek 
#	yield(dissaray_tween, "finished")
#	set_process_input(true)		
#	current_motion_state = MotionStates.IDLE
	pass
	
	
func on_collision():
	
	#	if not $Sounds/HitWall2.is_playing():
	#		$Sounds/HitWall.play()
	#		$Sounds/HitWall2.play()
	#
	#	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	#	# odbojni partikli
	#	if velocity.length() > stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
	#		var new_collision_particles = CollisionParticles.instance()
	#		new_collision_particles.position = collision.position
	#		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	#		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
	#		new_collision_particles.color = bolt_color
	#		new_collision_particles.set_emitting(true)
	#		Ref.node_creation_parent.add_child(new_collision_particles)
	#
	#	if bolt_trail_active:
	#		current_active_trail.start_decay() # trail decay tween start
	#		bolt_trail_active = false
	
	pass
	

func activate_nitro(nitro_power: float, nitro_time: float):
	if bolt_active: # če ni aktiven se sam od sebe ustavi
		#		var current_drag_div = drag_div
		#		drag_div = Pro.level_areas_profiles[Pro.LevelAreas.AREA_NITRO]["drag_div"]
		#		yield(get_tree().create_timer(nitro_time), "timeout")
		#		drag_div = current_drag_div
		pass


func pull_bolt_on_screen(pull_position: Vector2, current_leader: Node2D):
	
	#	if not bolt_active:
	#		return
	#
	#	bolt_collision.set_deferred("disabled", true)
	#	shield_collision.set_deferred("disabled", true)	
	#
	#	# reštartam trail
	#	if bolt_trail_active:
	#		current_active_trail.start_decay() # trail decay tween start
	#		bolt_trail_active = false
	#
	#	var pull_time: float = 0.2
	#	var pull_tween = get_tree().create_tween()
	#	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	#	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	#	yield(pull_tween, "finished")
	#
	#	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	#	if player_stats["laps_count"] < current_leader.player_stats["laps_count"]:
	#		var laps_finished_difference: int = current_leader.player_stats["laps_count"] - player_stats["laps_count"]
	#		update_stat("laps_count", laps_finished_difference)
	#
	#	# če preskoči checkpoint, ga dodaj, če ga leader ima
	#	var all_checked_bolts: Array = Ref.game_manager.bolts_checked
	#	if all_checked_bolts.has(current_leader):
	#		all_checked_bolts.append(self)
	#
	#	# ne dela
	#	#	if Ref.game_manager.current_pull_positions.has(pull_position):
	#	#		Ref.game_manager.current_pull_positions.erase(pull_position)
	#
	#	manage_gas(Ref.game_manager.game_settings["pull_gas_penalty"])
	
	pass


func drive_in(drive_in_time: float):
	
	#	# da ugotovim, kdaj so vsi zapeljani# bolt.bolt_collision.set_disabled(true) # da ga ne moti morebitna stena
	#	var drive_in_finished_position: Vector2 = global_position
	#	var drive_in_distance: float = 50
	#	global_position -= drive_in_distance * transform.x
	#
	modulate.a = 1
	#	current_motion_state = MotionStates.FWD # za fx
	#	start_engines()
	#
	#	var intro_drive_tween = get_tree().create_tween()
	#	intro_drive_tween.tween_property(self, "global_position", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	pass
	
	
func drive_out():
	
	#	var drive_out_rotation = Ref.current_level.race_start_node.get_rotation_degrees() - 90
	#	var drive_out_vector: Vector2 = Ref.current_level.race_start_node.global_position - Ref.current_level.finish_out_position
	#	var drive_out_position: Vector2 = global_position - drive_out_vector
	#
	#	var drive_out_time: float = 2
	#	var drive_out_tween = get_tree().create_tween()
	#	drive_out_tween.tween_callback(bolt_collision, "set_disabled", [true])
	#	drive_out_tween.tween_property(self, "rotation_degrees", drive_out_rotation, drive_out_time/5)
	#	drive_out_tween.parallel().tween_property(self, "global_position", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	#	drive_out_tween.tween_property(self, "modulate:a", 0, drive_out_time) # če je krožna dirka in ne gre iz ekrana
	pass
