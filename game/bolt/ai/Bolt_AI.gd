extends RigidBody2D
#class_name Bolt


signal bolt_activity_changed
signal bolt_stat_changed (stats_owner_id, driver_stats) # bolt in damage

#enum MOTION {ENGINES_OFF, IDLE, FWD, REV} # DIZZY, DYING glede na moč motorja
#var motion: int = MOTION.IDLE setget _change_motion
#var free_motion_type: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke

export var height: float = 0 # PRO
export var elevation: float = 7 # PRO

# seta spawner
var driver_id: int
var driver_profile: Dictionary
var driver_stats: Dictionary
var bolt_profile: Dictionary
# seta ready
var bolt_type: int
var ai_target_rank: int
var bolt_color: Color = Color.red

# bolt
var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju
var bolt_body_state: Physics2DDirectBodyState

onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var revive_timer: Timer = $ReviveTimer
#onready var bolt_controller: Node = $BoltController # zamenja se ob spawnu AI/HUMAN
onready var bolt_controller: Node2D = $Controller_AI

# fx
onready var trail_source: Position2D = $TrailSource
onready var CollisionParticles: PackedScene = preload("res://game/bolt/fx/BoltCollisionParticles.tscn")
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/fx/ExplodingBolt.tscn")

# driving
var rotation_dir = 0
#var force_rotation: float = 0 # rotacija v smeri skupne sile motorjev ... določam v _FP (input), apliciram v _IF
var bolt_global_rotation: float
#var bolt_global_position: Vector2
var bolt_velocity: Vector2 = Vector2.ZERO
var bolt_shift: int = 1 # -1 = rikverc, +1 = naprej, 0 ne obstaja ... za daptacijo, ker je moč motorja zmeraj pozitivna
var pseudo_stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
onready var gas_usage: float = bolt_profile["gas_usage"]
onready var idle_motion_gas_usage: float = bolt_profile["idle_motion_gas_usage"]
onready var front_mass: RigidBody2D = $Mass/Front/FrontMass
onready var rear_mass: RigidBody2D = $Mass/Rear/RearMass

# engine power
var engine_power = 0
var max_engine_power_adon: float = 0 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
var max_engine_power_factor: float = 1 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
var max_engine_power: float = 300000
#onready var max_engine_power: float = bolt_profile["ai_max_engine_power"]
var accelaration_power: float = 10000
var engine_power_fast_start: float = 5000
# engine rotation / direction
var heading_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float = 1
var max_engine_rotation_deg: float = 35
export (NodePath) var bolt_engines_path: String  # _temp
onready var engines: Node2D = get_node(bolt_engines_path)

# battle
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var is_shooting: bool = false # način, ki je boljši za efekte

# racing
var bolt_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju
var race_time_on_previous_lap: float = 0

# debug smerna linija
onready var direction_line: Line2D = $DirectionLine

# neu
var using_nitro: bool = false
onready var bolt_hud: Node2D = $BoltHud
onready var available_weapons: Array = [$Turret, $Dropper, $LauncherL, $LauncherR]
onready var chassis: Node2D = $Chassis
onready var terrain_detect: Area2D = $TerrainDetect
onready var animation_player: AnimationPlayer = $AnimationPlayer



var ang_damp = 7
var lin_damp = 2
var lin_damp_rear = 10
onready var motion_manager: Node = $MotionManager


func _ready() -> void:
#	printt("BOLT", self.name)

	add_to_group(Rfs.group_bolts)

	z_as_relative = false
	z_index = Pfs.z_indexes["bolts"]

	# lnf
	bolt_type = driver_profile["bolt_type"]
	ai_target_rank = bolt_profile["ai_target_rank"]
	bolt_color = driver_profile["driver_color"] # bolt se obarva ...
	chassis.get_node("BoltShape").modulate = bolt_color

	# fizka
	mass = 80
	linear_damp = lin_damp
	angular_damp = ang_damp
	physics_material_override.friction = bolt_profile["friction"]
	physics_material_override.bounce = bolt_profile["bounce"]
	rear_mass.linear_damp = lin_damp_rear

	# weapon settings
	for weapon in available_weapons:
		weapon.set_weapon()

	bolt_controller.controller_type = driver_profile["controller_type"]


func _process(delta: float) -> void:

	trail_source.update_trail(bolt_velocity.length())

	if engines.engines_on: # poraba
		update_stat(Pfs.STATS.GAS, gas_usage)


#	if not is_active: # resetiram, če ni aktiven
#		engine_power = 0
#		rotation_dir = 0
#	else:
##		_motion_state_machine()
#
#		max_engine_power = (max_engine_power + max_engine_power_adon) * max_engine_power_factor
#		engine_power = clamp(engine_power, 0, max_engine_power)
#		update_stat(Pfs.STATS.GAS, gas_usage)


#func _motion_state_machine():
#
#	heading_rotation = lerp_angle(heading_rotation, rotation_dir * deg2rad(90) * bolt_shift, engine_rotation_speed)
#	var max_free_thrust_rotation_deg: float = 90 # PRO
#	var rotate_to_angle: float = rotation_dir * deg2rad(max_free_thrust_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)
#
#	match motion_manager.motion:
#		motion_manager.MOTION.IDLE:
#			engine_power = 0
#			for thrust in engines.all_thrusts:
#				thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
#		motion_manager.MOTION.FWD:
#			engine_power += accelaration_power
#			if Rfs.game_manager.fast_start_window:
#				engine_power += engine_power_fast_start
#			for thrust in engines.front_thrusts:
#				thrust.rotation = heading_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
#			for thrust in engines.rear_thrusts:
#				thrust.rotation = - heading_rotation
#		motion_manager.MOTION.REV:
#			engine_power += accelaration_power
#			for thrust in engines.front_thrusts:
#				thrust.rotation = - heading_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
#			for thrust in engines.rear_thrusts:
#				thrust.rotation = heading_rotation + deg2rad(180)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	bolt_body_state = state
	bolt_velocity = state.get_linear_velocity() # tole je bol prej brez stejta

	if is_active:
		# sile na neuporabljeno masso se resetirajo ob menjavi motion stanja
		match motion_manager.motion:
			motion_manager.MOTION.IDLE:
				front_mass.set_applied_force(motion_manager.force_on_bolt)
				rear_mass.set_applied_force(- motion_manager.force_on_bolt)
			motion_manager.MOTION.FWD:
				front_mass.set_applied_force(motion_manager.force_on_bolt)
				rear_mass.set_applied_force(Vector2.ZERO)
			motion_manager.MOTION.REV:
				rear_mass.set_applied_force(motion_manager.force_on_bolt)
				front_mass.set_applied_force(Vector2.ZERO)



#func _integrate_forces(state: Physics2DDirectBodyState) -> void: # get state in set forces
#	# print("power %s / " % motion_manager.current_engine_power, "force %s" % force)
#
#	bolt_body_state = state
#	bolt_velocity = state.get_linear_velocity() # tole je bol prej brez stejta
#
#	if is_active:
#		set_applied_torque(motion_manager.torque_on_bolt)
#		match motion_manager.motion:
#			motion_manager.MOTION.IDLE:
#				# sila je 0 samo, če ni idle rotacije ali pa ja ROTATION, ker rotiram s torqu
#				front_mass.set_applied_force(motion_manager.force_on_bolt)
#				rear_mass.set_applied_force(- motion_manager.force_on_bolt)
#			motion_manager.MOTION.FWD:
#				front_mass.set_applied_force(motion_manager.force_on_bolt)
#				rear_mass.set_applied_force(Vector2.ZERO)
#			motion_manager.MOTION.REV:
#				rear_mass.set_applied_force(motion_manager.force_on_bolt)
#				front_mass.set_applied_force(Vector2.ZERO)


#func _change_motion(new_motion: int):
#
#	# nastavim nov engine
#	if not new_motion == motion_manager.motion:
#		motion_manager.motion = new_motion
#		match motion_manager.motion:
#			motion_manager.MOTION.IDLE:
#				if bolt_shift > 0:
#					rear_mass.set_applied_force(Vector2.ZERO)
#				else:
#					front_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = lin_damp
#				angular_damp = ang_damp
#				for thrust in engines.all_thrusts:
#					thrust.stop_fx()
#			motion_manager.MOTION.FWD:
#				rear_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = lin_damp
#				angular_damp = ang_damp
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()
#			motion_manager.MOTION.REV:
#				front_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = lin_damp
#				angular_damp = ang_damp
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()


func _change_activity(new_is_active: bool):

	if not new_is_active == is_active:
		is_active = new_is_active
		match is_active:
			true:
				bolt_controller.set_process_input(true)
			false: # ga upočasnim v trenutni smeri
				reset_bolt()
				bolt_controller.set_process_input(false)
				# nočeš ga skos slišat, če je multiplejer
				engines.shutdown_engines()
#				Rfs.game_manager.on_bolt_activity_change()

		emit_signal("bolt_activity_changed", is_active)


# LAJF ----------------------------------------------------------------------------


func on_hit(hit_by: Node2D, hit_global_position: Vector2):

	if is_shielded:
		return

	update_stat(Pfs.STATS.HEALTH, - hit_by.hit_damage)

	if hit_by.is_in_group(Rfs.group_bullets):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia)
		Rfs.game_camera.shake_camera(Rfs.game_camera.bullet_hit_shake)

	elif hit_by.is_in_group(Rfs.group_misiles):
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
		apply_impulse(local_hit_position, hit_by_inertia) # OPT misile impulse knockback ... ne deluje?
		Rfs.game_camera.shake_camera(Rfs.game_camera.misile_hit_shake)
		Rfs.sound_manager.play_sfx("bolt_explode")
		_explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa

	elif hit_by.is_in_group(Rfs.group_mine):
		var inertia_factor: float = 400000
		var hit_by_power: float = inertia_factor
		apply_torque_impulse(hit_by_power)
		Rfs.game_camera.shake_camera(Rfs.game_camera.misile_hit_shake)


func _destroy_bolt():

	_explode()
	motion_manager.motion = motion_manager.MOTION.ENGINES_OFF
	engines.shutdown_engines()
	self.is_active = false
	update_stat(Pfs.STATS.LIFE, - 1)

	if driver_stats[Pfs.STATS.LIFE] > 0:
		revive_timer.start(revive_time)
	else:
		queue_free()


func _explode():

	# disable staf
	collision_shape.set_deferred("disabled", true)
	#	collision_shape.disabled = true

	trail_source.decay()

	visible = false
	bolt_controller.set_process_input(false)
	set_physics_process(false)
	# resetira na revive

	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = chassis.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = bolt_velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawner_color = bolt_color
	new_exploding_bolt.z_index = z_index + 1
	Rfs.node_creation_parent.add_child(new_exploding_bolt)

	Rfs.game_camera.shake_camera(Rfs.game_camera.bolt_explosion_shake)


func _revive_bolt():

	# reset pred prikazom
	collision_shape.set_deferred("disabled", false)
	#	collision_shape.disabled = false

	self.is_active = true
	bolt_controller.set_process_input(true)
	set_physics_process(true)
	visible = true

	# reset energije
	update_stat(Pfs.STATS.HEALTH, 1)


# UTILITI ------------------------------------------------------------------------------------------------


func reset_bolt():
	# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v bolt "v igri"

	motion_manager.motion = motion_manager.MOTION.IDLE
	front_mass.set_applied_force(Vector2.ZERO)
	front_mass.set_applied_torque(0)
	rear_mass.set_applied_force(Vector2.ZERO)
	rear_mass.set_applied_torque(0)
	rotation_dir = 0
	engine_power = 0
	for thrust in engines.all_thrusts:
		thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
		thrust.stop_fx()


#func drive_in(drive_in_time: float = 2):

func drive_in(drive_in_time: float, drive_in_vector: Vector2):

	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	motion_manager.motion = motion_manager.MOTION.IDLE
	engines.start_engines()

	#	var drive_in_time: float = 2
	var drive_in_finished_position: Vector2 = global_position
	drive_in_vector = Rfs.current_level.drive_in_position.rotated(Rfs.current_level.level_start.global_rotation)
	var drive_in_start_position: Vector2 = global_position + drive_in_vector
	# premaknem ga nazaj in zapeljem do linije
	bolt_body_state.transform.origin = drive_in_start_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(bolt_body_state, "transform:origin", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")

	collision_shape.set_deferred("disabled", false)
	self.is_active = true


func drive_out(drive_out_time: float, drive_out_vector: Vector2):
#func drive_out():

	collision_shape.set_deferred("disabled", true)
	self.is_active = false

#	var drive_out_time: float = 2
	drive_out_vector = Rfs.current_level.drive_out_position.rotated(Rfs.current_level.level_finish.global_rotation)
	var drive_out_position: Vector2 = global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)
	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(bolt_body_state, "transform:rotated", angle_to_vector, drive_out_time/5)
	drive_out_tween.tween_property(bolt_body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	engines.shutdown_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), bolt_controller.ai_target)
	#	set_physics_process(false)
	#	motion_manager.motion = motion_manager.MOTION.IDLE


#func use_nitro():
#	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost
#
#	if not using_nitro:
#		Rfs.sound_manager.play_sfx("pickable_nitro")
#		max_engine_power_adon = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
#		engine_power += Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
#		yield(get_tree().create_timer(Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]),"timeout")
#		max_engine_power_adon = 0
#		using_nitro = false


func revup():

	$Sounds/EngineRevup.play()
	for thrust in engines.all_thrusts:
		thrust.start_fx(true)


func _spawn_shield():

	var ShieldScene: PackedScene = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = global_position
	new_shield.spawner = self # ime avtorja izstrelka
	new_shield.scale = Vector2.ONE
	new_shield.shield_time = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["time"]

	Rfs.node_creation_parent.add_child(new_shield)


func pull_bolt_on_screen(pull_position: Vector2, current_leader: RigidBody2D):

	# disejblam koližne
	bolt_controller.set_process_input(false)
	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(bolt_body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	bolt_controller.set_process_input(true)

	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	if driver_stats[Pfs.STATS.LAPS_FINISHED] < current_leader.driver_stats[Pfs.STATS.LAPS_FINISHED]:
		var laps_finished_difference: int = current_leader.driver_stats[Pfs.STATS.LAPS_FINISHED] - driver_stats[Pfs.STATS.LAPS_FINISHED]
#	if driver_stats["laps_count"] < current_leader.driver_stats["laps_count"]:
#		var laps_finished_difference: int = current_leader.driver_stats["laps_count"] - driver_stats["laps_count"]
#		__update_bolts_level_stats("laps_count", laps_finished_difference)

	# če preskoči checkpoint, ga dodaj, če ga leader ima
#	var all_checked_bolts: Array = Rfs.game_manager.bolts_checked #  trega ni več
	var all_checked_bolts: Array = Rfs.game_manager.bolts_in_game # začasno

	if all_checked_bolts.has(current_leader):
		all_checked_bolts.append(self)

	# ne dela
	#	if Rfs.game_manager.current_pull_positions.has(pull_position):
	#		Rfs.game_manager.current_pull_positions.erase(pull_position)

	update_stat(Pfs.STATS.GAS, Rfs.game_manager.game_settings["pull_gas_penalty"])


	#func __update_bolts_level_stats(stat_name: String, change_value: float): # samo za pull bolt
	#
	#
	#	if not Rfs.game_manager.game_on:
	#		return
	#
	#	if stat_name == "best_lap_time":
	#		driver_stats[stat_name] = change_value
	#	elif stat_name == "level_time":
	#		driver_stats[stat_name] = change_value
	#	elif stat_name == "level_rank":
	#		driver_stats[stat_name] = change_value
	#
	#	emit_signal("stats_changed", driver_id, driver_stats)


func screen_wrap(): # ne uporabljam

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
	if not is_active:
		return
	bolt_body_state.set_transform(xform)


func on_item_picked(pickable_key: int):

	match pickable_key:
		Pfs.PICKABLE.PICKABLE_SHIELD:
			_spawn_shield()
		Pfs.PICKABLE.PICKABLE_NITRO:
			motion_manager.use_nitro()
		_:
			# če spreminja statistiko
			if Pfs.pickable_profiles[pickable_key].keys().has("driver_stat"):
				var change_value: float = Pfs.pickable_profiles[pickable_key]["value"]
				var change_stat_key: int = Pfs.pickable_profiles[pickable_key]["driver_stat"]
				update_stat(change_stat_key, change_value)


func update_stat(stat_key: int, change_value):

	if not Rfs.game_manager.game_on:
		return

	var curr_stat_name: String
	driver_stats[stat_key] += change_value # change_value je + ali -

	# health management
	if stat_key == Pfs.STATS.HEALTH:
		driver_stats[Pfs.STATS.HEALTH] = clamp(driver_stats[Pfs.STATS.HEALTH], 0, 1) # more bigt , ker max heath zmeri dodam 1
		if driver_stats[Pfs.STATS.HEALTH] == 0:
			_destroy_bolt()
		return # poštima ga bolt hud

	# gas management
	if driver_stats[Pfs.STATS.GAS] <= 0: # če zmanjka bencina je deaktiviran
		driver_stats[Pfs.STATS.GAS] = 0
		self.is_active = false

	emit_signal("bolt_stat_changed", driver_id, stat_key, driver_stats[stat_key])


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_ReviveTimer_timeout() -> void:

	_revive_bolt()


func _on_Bolt_body_entered(body: Node2D) -> void:

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
		Rfs.node_creation_parent.add_child(new_collision_particles)

	trail_source.decay()


func _exit_tree() -> void:

	self.is_active = false # zazih
	if Rfs.game_camera.follow_target == self:
		Rfs.game_camera.follow_target = null
	trail_source.decay()
