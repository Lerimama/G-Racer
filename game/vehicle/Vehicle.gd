extends RigidBody2D
class_name Vehicle


signal driver_terminated (sebe)
signal stat_changed (stats_owner_id, driver_stats) # vehicle in damage

export var height: float = 0 # na redi potegne iz pro
export var elevation: float = 0
export (NodePath) var engines_path: String  # _temp ... engines
export var group_weapons_by_type: bool = true

var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju
var velocity: Vector2 = Vector2.ZERO

# driver (poda spawner)
var driver_name_id
var driver_profile: Dictionary
var driver_stats: Dictionary
var default_vehicle_profile: Dictionary
var vehicle_camera: Camera2D # spawner

# iz vehicle profila
#var vehicle_type: int
var vehicle_color: Color = Color.red
var gas_usage: float
var gas_usage_idle: float
var gas_tank_size: float
var near_radius: float
var damage_effect_factor: float # vpliva na health
var vehicle_damage: float # obratno od health * resiliance ... to bo enkrat health
var on_hit_disabled_time: float

var pseudo_stop_speed: float = 15 # hitrost pri kateri ga kar ustavim

# tracking
var target_rank: int
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var body_state: Physics2DDirectBodyState
var driver_tracker: PathFollow2D # napolni se, ko se vehicle pripiše trackerju

# drugo ...
var triggering_weapons: Array = []
var prev_lap_level_time: int = 0 # _temp tukaj na hitro z beleženje lap timeta

onready var control_manager: Node = $Control # zamenja se ob spawnu AI/PLAYER
onready var motion_manager: Node = $Motion

onready var equip_positions: Node2D = $EquipPositions
onready var weapons: Node2D = $Weapons
onready var equipment: Node2D = $Equipment
onready var shape_poly: Polygon2D = $ShapePoly
onready var engines: Node2D = get_node(engines_path)

onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var revive_timer: Timer = $ReviveTimer
onready var trail_source: Position2D = $TrailSource
onready var front_mass: RigidBody2D = $Mass/Front/FrontMass
onready var rear_mass: RigidBody2D = $Mass/Rear/RearMass
onready var terrain_detect: Area2D = $TerrainDetect
onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var CollisionParticles: PackedScene = preload("res://game/vehicle/fx/VehicleCollisionParticles.tscn")
onready var ExplodingVehicle: PackedScene = preload("res://game/vehicle/fx/ExplodingVehicle.tscn")

# debug
onready var direction_line: Line2D = $DirectionLine
var debug_trail_time: float = 0
var debug_trail: Line2D

# neu
export var vehicle_motion_profile: Resource = null
var masa: float
var heal_rate: float
var damage_engine_power_factor: float
var level_type: int = 0 # ta podatek more vedet, da da ve kaj je namen obstoja

func _input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1"): # idle
		motion_manager.boost_vehicle()
	if Input.is_action_pressed("no2"): # race
		if driver_name_id == "MOU":
			update_stat(Pfs.STATS.HEALTH, -0.1)
	if Input.is_action_pressed("no3"): # race
		if driver_name_id == "MOU":
			update_stat(Pfs.STATS.HEALTH, 0.1)
	if Input.is_action_pressed("no4"): # race
		if driver_name_id == "MOU":
			update_stat(Pfs.STATS.GAS, -100)
	if Input.is_action_pressed("no5"): # race
		if driver_name_id == "MOU":
			update_stat(Pfs.STATS.GAS, 100)


func _ready() -> void:

	add_to_group(Rfs.group_agents)
	add_to_group(Rfs.group_vehicles)
	add_to_group(Rfs.group_drivers) # more bit tukaj, da ga najde

	z_as_relative = false
	z_index = Pfs.z_indexes["vehicles"]

	equip_positions.hide()
	near_radius = get_node("NearArea/CollisionShape2D").shape.radius # za pullanje

	if driver_profile:
		vehicle_color = driver_profile["driver_color"] # driver barva ...

	_set_vehicle_parameters()

	# motion_manager
	var motion_manager_path = default_vehicle_profile["motion_manager_path"]
	motion_manager.set_script(motion_manager_path)

	# controller spawn (ai ima full nodetov notri
	_spawn_driver_controller()

	_set_weapons_and_staff()


func _process(delta: float) -> void:

	# debug trail
	#	if Input.is_action_pressed("T"):
	#		if not debug_trail:
	#			debug_trail = Line2D.new()
	#			debug_trail.z_index = 1000
	#			Rfs.node_creation_parent.add_child(debug_trail)
	#		else:
	#			debug_trail_time += delta
	#			if debug_trail_time > 0.1:
	#				debug_trail.add_point(global_position)
	#				debug_trail_time = 0
	#	if Input.is_action_just_released("T"):
	#		debug_trail_time = 0
	#		debug_trail = null

	trail_source.update_trail(velocity.length())

	if engines.engines_on: # poraba
		update_stat(Pfs.STATS.GAS, gas_usage)

	# heal
	if driver_stats[Pfs.STATS.HEALTH] < 1 and is_active:
		if level_type == Pfs.BASE_TYPE.RACING:
			update_stat(Pfs.STATS.HEALTH, heal_rate * Sts.time_game_heal_rate_factor)
		else:
			update_stat(Pfs.STATS.HEALTH, heal_rate * Sts.points_game_heal_rate_factor)


func _integrate_forces(state: Physics2DDirectBodyState) -> void: # get state in set forces
	# print("power %s / " % motion_manager.current_engine_power, "force %s" % force)

	body_state = state
	velocity = state.get_linear_velocity() # tole je bol prej brez stejta

	if is_active:
		set_applied_torque(motion_manager.torque_on_vehicle)
		match motion_manager.motion:
			motion_manager.MOTION.IDLE, motion_manager.MOTION.IDLE_LEFT, motion_manager.MOTION.IDLE_RIGHT:
				# sila je 0 samo, če ni idle rotacije ali pa ja ROTATION, ker rotiram s torqu
				front_mass.set_applied_force(motion_manager.force_on_vehicle)
				rear_mass.set_applied_force(-motion_manager.force_on_vehicle)
			motion_manager.MOTION.FWD, motion_manager.MOTION.FWD_LEFT, motion_manager.MOTION.FWD_RIGHT:
				front_mass.set_applied_force(motion_manager.force_on_vehicle)
				rear_mass.set_applied_force(Vector2.ZERO)
			motion_manager.MOTION.REV, motion_manager.MOTION.REV_LEFT, motion_manager.MOTION.REV_RIGHT:
				front_mass.set_applied_force(Vector2.ZERO)
				rear_mass.set_applied_force(motion_manager.force_on_vehicle)


# LAJF ----------------------------------------------------------------------------


func on_hit(hit_by: Node2D, hit_global_position: Vector2):

	if not is_shielded:

		update_stat(Pfs.STATS.HEALTH, - hit_by.hit_damage)

		if "hit_inertia" in hit_by:
			var local_hit_position: Vector2 = hit_global_position - position
			var hitter_rot_vector: Vector2 = Vector2.RIGHT.rotated(hit_by.global_rotation)
			apply_impulse(local_hit_position, hitter_rot_vector * hit_by.hit_inertia) # OPT misile impulse knockback ... ne deluje?

	if vehicle_camera:
		vehicle_camera.shake_camera(hit_by)


func on_item_picked(pickable_key: int):

	match pickable_key:
		Pfs.PICKABLE.PICKABLE_SHIELD:
			_spawn_shield()
		Pfs.PICKABLE.PICKABLE_NITRO:
			motion_manager.boost_vehicle()
		_:
			# če spreminja statistiko
			if "driver_stat" in Pfs.pickable_profiles[pickable_key].keys():
				var change_value: float = Pfs.pickable_profiles[pickable_key]["value"]
				var change_stat_key: int = Pfs.pickable_profiles[pickable_key]["driver_stat"]
				update_stat(change_stat_key, change_value)


func _die(with_explode: bool = true):

	self.is_active = false # v setget se aktivnost disejbla in nastavi IDLE

	if with_explode:
		collision_shape.set_deferred("disabled", true)
		_explode()
		if driver_stats[Pfs.STATS.GAS] <= 0: # manjko benza je permanentni die
			emit_signal("driver_terminated", self)
			queue_free()
		else:
			if level_type == Pfs.BASE_TYPE.RACING:
				revive_timer.start(revive_time)
			else:
				update_stat(Pfs.STATS.LIFE, - 1)
				if driver_stats[Pfs.STATS.LIFE][0] > 0: # life je array current/max
					revive_timer.start(revive_time)
				else:
					emit_signal("driver_terminated", self)
					queue_free()


func _explode():

	if vehicle_camera:
		vehicle_camera.shake_camera(self)

	# spawn eksplozije
	var new_exploding_vehicle = ExplodingVehicle.instance()
	new_exploding_vehicle.global_position = global_position
	new_exploding_vehicle.global_rotation = global_rotation
	new_exploding_vehicle.modulate.a = 1
	new_exploding_vehicle.velocity = velocity # podamo hitrost, da se premika s hitrostjo vehila
	new_exploding_vehicle.spawner_color = vehicle_color
	new_exploding_vehicle.z_index = z_index + 1
	Rfs.node_creation_parent.add_child(new_exploding_vehicle)

	hide()


func _revive():

	# reset pred prikazom
	self.is_active = true
	collision_shape.set_deferred("disabled", false)
	engines.start_engines() # med igro je se avtomatsko prižge
	show()

	# reset energije
	update_stat(Pfs.STATS.HEALTH, 1)


func _set_weapons_and_staff():

		# set weapons
	for weapon in weapons.get_children():
		# če je opremljeno na pozicijo
		# če ni uniq tip in bi moralo bit, ga ne dodam v trriggered
		var legit: bool = true
		if weapon in equip_positions.positions_equiped.values():
			weapon.set_weapon(self)
			var used_for_triggering: bool = true
			if weapon.weapon_type == weapon.WEAPON_TYPE.MALA: # temp MALA not used for trggering
				used_for_triggering = false
			if group_weapons_by_type:
				for trigg_weapon in triggering_weapons:
					if "weapon_type" in trigg_weapon and trigg_weapon.weapon_type == weapon.weapon_type:
						used_for_triggering = false
			if used_for_triggering:
				if weapon.has_method("_on_weapon_triggered"):
						weapon.connect("weapon_shot", self, "_on_weapon_shot")
						triggering_weapons.append(weapon)
		else:
			weapon.hide()

	# set equipement
	for equip in equipment.get_children():
		if equip in equip_positions.positions_equiped.values():
			print ("equipment")
		else:
			print ("hide")
			equip.hide()


func _set_vehicle_parameters(): # vsebinski, ne fizični

	if vehicle_motion_profile:
		damage_engine_power_factor = vehicle_motion_profile.damage_engine_power_factor
		heal_rate = vehicle_motion_profile.heal_rate
		vehicle_damage = vehicle_motion_profile.vehicle_damage
		damage_effect_factor = vehicle_motion_profile.damage_effect_factor
		on_hit_disabled_time = vehicle_motion_profile.on_hit_disabled_time
		target_rank = vehicle_motion_profile.target_rank
		height = vehicle_motion_profile.height
		elevation = vehicle_motion_profile.elevation
		gas_tank_size = vehicle_motion_profile.gas_tank_size
		gas_usage = vehicle_motion_profile.gas_usage
		gas_usage_idle = vehicle_motion_profile.gas_usage_idle
	else:
		damage_engine_power_factor = default_vehicle_profile["damage_engine_power_factor"]
		heal_rate = default_vehicle_profile["heal_rate"]
		on_hit_disabled_time = default_vehicle_profile["on_hit_disabled_time"]
		damage_effect_factor = default_vehicle_profile["damage_effect_factor"]
		target_rank = default_vehicle_profile["target_rank"]
		height = default_vehicle_profile["height"]
		elevation = default_vehicle_profile["elevation"]
		gas_tank_size = default_vehicle_profile["gas_tank_size"]
		gas_usage = default_vehicle_profile["gas_usage"]
		gas_usage_idle = default_vehicle_profile["gas_usage_idle"]


func _spawn_driver_controller():

	var DriverController: PackedScene
	if driver_profile["driver_type"] == Pfs.DRIVER_TYPE.AI:
		DriverController = Pfs.ai_profile["driver_scene"]
	else:
		var drivers_driver_profile: Dictionary = Pfs.controller_profiles[driver_profile["controller_type"]]
		DriverController = drivers_driver_profile["driver_scene"]

	# spawn na vrh vehicleovega drevesa
	control_manager = DriverController.instance()
	control_manager.controlled_vehicle = self
	control_manager.motion_manager = motion_manager
	if not driver_profile["driver_type"] == Pfs.DRIVER_TYPE.AI:
		control_manager.controller_type = driver_profile["controller_type"]

	call_deferred("add_child", control_manager)
	call_deferred("move_child", control_manager, 0)


func _change_activity(new_is_active: bool):

	if not new_is_active == is_active:
		is_active = new_is_active

		# shranim trenutno stanje bolta v profil
		if vehicle_motion_profile:
			vehicle_motion_profile.update_profile_parameters(self)

		# postane znan igri, ni pa nujno prižgan
		if is_active:

			# če kameri sledi meni, jo nulliram
			if vehicle_camera and vehicle_camera.follow_target == self:
				vehicle_camera.follow_target = null

			control_manager.set_process_input(true)
			call_deferred("set_physics_process", true)
			call_deferred("set_process", true)
			update_stat(Pfs.STATS.WINS, driver_stats[Pfs.STATS.WINS]) # temp WINS pozicija

		# ga upočasnim v trenutni smeri
		else:
			# motion
			motion_manager.motion = motion_manager.MOTION.IDLE
			set_applied_force(Vector2.ZERO)
			set_applied_torque(0)

			# vehile
			trail_source.decay() # zazih
			engines.stop_engines()

			# procesi
			control_manager.set_process_input(false)
			call_deferred("set_physics_process", false)
			call_deferred("set_process", false)

			# resource apdejt
			if vehicle_motion_profile:
				vehicle_motion_profile.update_profile_parameters(self)


func _on_weapon_shot(stat_key: int, change_value):

	driver_stats[stat_key] += change_value # change_value je + ali -
	emit_signal("stat_changed", driver_name_id, stat_key, driver_stats[stat_key])


func _evaluate_damage(damaged_health: float):

	var damage_size_from_health: float = 1 - damaged_health
	var real_damage_size: float = damage_size_from_health * damage_effect_factor
	vehicle_damage = real_damage_size


func update_stat(stat_key: int, change_value):
	# statistika se preračuna in pošlje naprej nova vrednost

	# health
	match stat_key:

		Pfs.STATS.LEVEL_TIME,Pfs.STATS.LAP_TIME,Pfs.STATS.LAP_TIME:
			driver_stats[stat_key] = change_value # change_value je + ali -

		Pfs.STATS.LEVEL_RANK:
			driver_stats[stat_key] = change_value # change_value je + ali -

		Pfs.STATS.GAS:
			driver_stats[stat_key] += change_value # change_value je + ali -
			# manjka becina
			if driver_stats[Pfs.STATS.GAS] <= 0:
				driver_stats[Pfs.STATS.GAS] = 0
				_die(false)
#				self.is_active = false
			# povečam max ... obstaja zaradi hud gas bar
			elif driver_stats[Pfs.STATS.GAS] > gas_tank_size:
				gas_tank_size = driver_stats[Pfs.STATS.GAS]

		Pfs.STATS.HEALTH:
			driver_stats[stat_key] += change_value # change_value je + ali -
			driver_stats[Pfs.STATS.HEALTH] = clamp(driver_stats[Pfs.STATS.HEALTH], 0, 1) # kadar maxiram max heath lahko dodam samo 1 in je ok
			_evaluate_damage(driver_stats[Pfs.STATS.HEALTH])
			if driver_stats[Pfs.STATS.HEALTH] == 0:
				_die()

		Pfs.STATS.GOALS_REACHED, Pfs.STATS.WINS: # arrays
			driver_stats[stat_key].append(change_value)

		Pfs.STATS.LAP_COUNT:
			driver_stats[stat_key].append(change_value)
			# preverjam best lap
			var curr_lap_time: float = change_value
			var is_best_lap: bool = true
			for lap_time in Pfs.STATS.LAP_COUNT:
				if curr_lap_time > lap_time:
					is_best_lap = false
					break
			if is_best_lap:
				Pfs.STATS.BEST_LAP_TIME = curr_lap_time
				emit_signal("stat_changed", driver_name_id, Pfs.STATS.BEST_LAP_TIME, curr_lap_time)

		Pfs.STATS.LIFE:
			var new_life_count: int = driver_stats[stat_key] + change_value
			var max_life_count: int = Pfs.start_driver_stats[stat_key]
			driver_stats[stat_key] = [new_life_count, max_life_count]
		_:
			#			print(driver_stats.keys()[stat_key])
			driver_stats[stat_key] += change_value # change_value je + ali -

	emit_signal("stat_changed", driver_name_id, stat_key, driver_stats[stat_key])


# UTILITI ------------------------------------------------------------------------------------------------


func drive_in(drive_in_vector: Vector2 = Vector2.ZERO, drive_in_time: float = 1):

	self.is_active = true

	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	motion_manager.motion = motion_manager.MOTION.IDLE
	engines.start_engines()

	var drive_in_finished_position: Vector2 = global_position
	var drive_in_start_position: Vector2 = global_position + drive_in_vector
	# premaknem ga nazaj in zapeljem do linije
	body_state.transform.origin = drive_in_start_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(body_state, "transform:origin", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")

	collision_shape.set_deferred("disabled", false)


func drive_out(drive_out_vector: Vector2 = Vector2.ZERO, drive_out_time: float = 1):

	collision_shape.set_deferred("disabled", true)
	self.is_active = false

	var drive_out_position: Vector2 = global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)

	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(body_state, "transform:rotated", angle_to_vector, drive_out_time/5)
	drive_out_tween.tween_property(body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	engines.stop_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), control_manager.ai_target)
	#	set_physics_process(false)
	#	motion_manager.motion = motion_manager.MOTION.IDLE


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


func pull_on_screen(pull_position: Vector2): # kliče GM

	# disejblam koližne
	control_manager.set_process_input(false)
	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	control_manager.set_process_input(true)

	update_stat(Pfs.STATS.GAS, Sts.pull_gas_penalty)


func screen_wrap(): # ne uporabljam

	# kopirano iz tutoriala ---> https://www.youtube.com/watch?v=xsAyx2r1bQU
	var xform = body_state.get_transform()
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
	body_state.set_transform(xform)


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_ReviveTimer_timeout() -> void:

	_revive()


func _on_Vehicle_body_entered(body: Node2D) -> void:

	if not $Sounds/HitWall2.is_playing():
		$Sounds/HitWall.play()
		$Sounds/HitWall2.play()

	# odbojni partikli
	if velocity.length() > pseudo_stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = body_state.get_contact_local_position(0)
		new_collision_particles.rotation = body_state.get_contact_local_normal(0).angle() # rotacija partiklov glede na normalo površine
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič
		new_collision_particles.color = vehicle_color
		new_collision_particles.set_emitting(true)
		Rfs.node_creation_parent.add_child(new_collision_particles)

	trail_source.decay()


func _exit_tree() -> void: # če ni samo za za debug je nekaj narobe ... da se brez tega
	# pospravljanje morebitnih smeti
	#	printt("smeti", name, is_active)

	#	if vehicle_motion_profile:
	#		vehicle_motion_profile.update_profile_parameters(self)
	#
	#	self.is_active = false # zazih
	#	if vehicle_camera:
	#		if vehicle_camera.follow_target == self:
	#			vehicle_camera.follow_target = null
	#	trail_source.decay()

	pass
