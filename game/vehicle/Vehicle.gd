extends RigidBody2D
class_name Vehicle


signal vehicle_deactivated (vehicle)
signal stat_changed (stats_owner_id, driver_stats) # vehicle in damage

export var height: float = 0 # na redi potegne iz pro
export var elevation: float = 0
export (NodePath) var engines_path: String  # _temp ... engines
export var group_weapons_by_type: bool = true

var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju
var velocity: Vector2 = Vector2.ZERO

# driver (poda spawner)
var driver_id
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
var on_hit_disabled_time: float
var health_effect_factor: float
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

onready var driver: Node2D = $Driver # zamenja se ob spawnu AI/PLAYER
onready var motion_manager: Node2D = $Motion

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
var rank_by: int = 0 # ta podatek more vedet, da da ve kaj je namen obstoja
var turned_on: bool = false	# neodvisen on aktivitja

export (float, 5, 20, 0.5) var driving_elevation: float = 7


func _input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1"): # idle
		if driver_id == "MOU":
			_revive()
		else:
			motion_manager.boost_vehicle()
	if Input.is_action_pressed("no2"): # race
#		if driver_id == "JOU":
		update_stat(Pfs.STATS.HEALTH, -0.1)

	if Input.is_action_pressed("no3"): # race
		update_stat(Pfs.STATS.HEALTH, 0.1)
	if Input.is_action_pressed("no4"): # race
		update_stat(Pfs.STATS.GAS, -100)
	if Input.is_action_pressed("no5"): # race
		update_stat(Pfs.STATS.GAS, 100)


func _ready() -> void:

	add_to_group(Rfs.group_agents)
	add_to_group(Rfs.group_vehicles)
	add_to_group(Rfs.group_drivers) # more bit tukaj, da ga najde

	z_as_relative = false
	z_index = Pfs.z_indexes["vehicles"]
	shape_poly.color = driver_profile["driver_color"]

	equip_positions.hide()
	near_radius = get_node("NearArea/CollisionShape2D").shape.radius # za pullanje

	if driver_profile:
		vehicle_color = driver_profile["driver_color"] # driver barva ...

	_load_vehicle_parameters()
	motion_manager.set_script(default_vehicle_profile["motion_manager_path"])
	_spawn_driver_controller()
	_set_weapons_and_staff()


func _process(delta: float) -> void:
	# debug trail
	_drawing_trail_controls(delta)

	trail_source.update_trail(velocity.length())

	if is_active:
		if engines.engines_on: update_stat(Pfs.STATS.GAS, gas_usage)
		if driver_stats[Pfs.STATS.HEALTH] < 1:
			if rank_by == Pfs.RANK_BY.TIME:
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


# LAJFLUP ----------------------------------------------------------------------------


func _die(with_explode: bool = true):

	if with_explode:

		collision_shape.set_deferred("disabled", true)
		_explode()

		if driver_stats[Pfs.STATS.GAS] <= 0: # manjko benza je permanentni die
			self.is_active = false
			queue_free()
		else:
			if rank_by == Pfs.RANK_BY.TIME:
				turn_off()
				driver.set_process_input(false)
				call_deferred("set_physics_process", false)
				call_deferred("set_process", false)
				revive_timer.start(revive_time)
			else:
				if Sts.life_as_life_taken:
					turn_off()
					driver.set_process_input(false)
					call_deferred("set_physics_process", false)
					call_deferred("set_process", false)
					revive_timer.start(revive_time)
				else:
					update_stat(Pfs.STATS.LIFE, - 1)
					if driver_stats[Pfs.STATS.LIFE] > 0: # life je array current/max
						turn_off()
						driver.set_process_input(false)
						call_deferred("set_physics_process", false)
						call_deferred("set_process", false)
						revive_timer.start(revive_time)
					else:
						self.is_active = false
						queue_free()
	else:
		self.is_active = false


func _revive():

	call_deferred("set_physics_process", true)
	call_deferred("set_process", true)
	collision_shape.set_deferred("disabled", false)
	show()
	turn_on()

	# reset energije
	update_stat(Pfs.STATS.HEALTH, 1)


func turn_on():

	engines.start_engines()
	motion_manager.motion = motion_manager.MOTION.IDLE
	turned_on = true

	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(self, "elevation", driving_elevation, 2).from(0.0).set_ease(Tween.EASE_IN_OUT)


func turn_off():

	trail_source.decay() # zazih

	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(self, "elevation", 0, 1).set_ease(Tween.EASE_IN_OUT)
	yield(turn_tween, "finished")

	engines.stop_engines()
	motion_manager.motion = motion_manager.MOTION.DISSABLED
	turned_on = false


func _change_activity(new_is_active: bool):
	# ko ga igra šteje ali pa pozabi
	# nima veze z ugašanjem in skrivanjem
	# nima veze z motion
	# kontrole so kompletno off

	if not new_is_active == is_active:
		is_active = new_is_active

		# postane znan igri, ni pa nujno prižgan
		if is_active:
			_load_vehicle_parameters()
			driver.set_process_input(true)
			call_deferred("set_physics_process", true)
			call_deferred("set_process", true)
		else:
			turn_off()
			_save_vehicle_parameters()
			driver.set_process_input(false)
			call_deferred("set_physics_process", false)
			call_deferred("set_process", false)

			emit_signal("vehicle_deactivated", self)


# SET -------------------------------------------------------------------------------------------------


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


func _save_vehicle_parameters(): # vsebinski, ne fizični
	# marsikaj se me igro ne spreminja, pa vseeno ... junevernou

	if vehicle_motion_profile:
		# vehicle
		vehicle_motion_profile.target_rank = target_rank
		vehicle_motion_profile.height = height
		vehicle_motion_profile.driving_elevation = driving_elevation
		vehicle_motion_profile.gas_tank_size = gas_tank_size
		vehicle_motion_profile.gas_usage = gas_usage
		vehicle_motion_profile.gas_usage_idle = gas_usage_idle
		vehicle_motion_profile.masa = masa
		vehicle_motion_profile.on_hit_disabled_time = on_hit_disabled_time
		vehicle_motion_profile.group_weapons_by_type = group_weapons_by_type
		vehicle_motion_profile.health_effect_factor = health_effect_factor
		vehicle_motion_profile.heal_rate = heal_rate
		# motion manager
		vehicle_motion_profile.start_max_engine_power = motion_manager.start_max_engine_power
		vehicle_motion_profile.ai_power_equlizer_addon = motion_manager.ai_power_equlizer_addon
		vehicle_motion_profile.fast_start_power_addon = motion_manager.fast_start_power_addon
		vehicle_motion_profile.max_engine_power_rotation_adapt = motion_manager.max_engine_power_rotation_adapt
	else:
		default_vehicle_profile["health_effect_factor"] = health_effect_factor
		default_vehicle_profile["heal_rate"] = heal_rate
		default_vehicle_profile["on_hit_disabled_time"] = on_hit_disabled_time
		default_vehicle_profile["target_rank"] = target_rank
		default_vehicle_profile["height"] = height
		default_vehicle_profile["driving_elevation"] = driving_elevation
		default_vehicle_profile["gas_tank_size"] = gas_tank_size
		default_vehicle_profile["gas_usage"] = gas_usage
		default_vehicle_profile["gas_usage_idle"] = gas_usage_idle


func _load_vehicle_parameters(): # vsebinski, ne fizični

	if vehicle_motion_profile:
		health_effect_factor = vehicle_motion_profile.health_effect_factor
		heal_rate = vehicle_motion_profile.heal_rate
		on_hit_disabled_time = vehicle_motion_profile.on_hit_disabled_time
		target_rank = vehicle_motion_profile.target_rank
		height = vehicle_motion_profile.height
		driving_elevation = vehicle_motion_profile.driving_elevation
		gas_tank_size = vehicle_motion_profile.gas_tank_size
		gas_usage = vehicle_motion_profile.gas_usage
		gas_usage_idle = vehicle_motion_profile.gas_usage_idle
	else:
		health_effect_factor = default_vehicle_profile["health_effect_factor"]
		heal_rate = default_vehicle_profile["heal_rate"]
		on_hit_disabled_time = default_vehicle_profile["on_hit_disabled_time"]
		target_rank = default_vehicle_profile["target_rank"]
		height = default_vehicle_profile["height"]
		driving_elevation = default_vehicle_profile["driving_elevation"]
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
	driver = DriverController.instance()
	driver.vehicle = self
	driver.motion_manager = motion_manager
	if not driver_profile["driver_type"] == Pfs.DRIVER_TYPE.AI:
		driver.controller_type = driver_profile["controller_type"]

	call_deferred("add_child", driver)
	call_deferred("move_child", driver, 0)

# ON ------------------------------------------------------------------------------------------------


func update_stat(stat_key: int, stat_value):
#	print("stat key", Pfs.STATS.keys()[stat_key])
	# statistika se preračuna in pošlje naprej nova vrednost
	# change_value je lahko:
	#	+/- delta value ... driver_stats += change_value >> default
	#	end value ... driver_stats = change_value
	# 	trenuten čas

	match stat_key:
		# vehicle
		Pfs.STATS.GAS:
			Sts.ai_gas_on = false
			if is_in_group(Rfs.group_players) or Sts.ai_gas_on:
				driver_stats[stat_key] += stat_value
				if driver_stats[Pfs.STATS.GAS] <= 0:
					driver_stats[Pfs.STATS.GAS] = 0
					_die(false)
				elif driver_stats[Pfs.STATS.GAS] > gas_tank_size: # povečam max ... obstaja zaradi hud gas bar
					gas_tank_size = driver_stats[Pfs.STATS.GAS]
		Pfs.STATS.HEALTH:
			driver_stats[stat_key] += stat_value # change_value je + ali -
			driver_stats[Pfs.STATS.HEALTH] = clamp(driver_stats[Pfs.STATS.HEALTH], 0, 1) # kadar maxiram max heath lahko dodam samo 1 in je ok
			if driver_stats[Pfs.STATS.HEALTH] == 0:
				_die()
		# driver
		Pfs.STATS.LIFE:
			driver_stats[stat_key] += stat_value
		Pfs.STATS.GOALS_REACHED: # goal nodes names or duplicate?
			driver_stats[stat_key].append(stat_value)
		Pfs.STATS.WINS: # level names
			# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
			driver_stats[stat_key].append(stat_value)
			#			driver_stats[stat_key] += stat_value
		# level
		Pfs.STATS.LEVEL_RANK:
			driver_stats[stat_key] = stat_value
		Pfs.STATS.LEVEL_TIME: # na finished
			driver_stats[stat_key] = stat_value
		Pfs.STATS.LAP_COUNT:
			driver_stats[stat_key].append(stat_value)
			prev_lap_level_time = stat_value
			# best lap
			var curr_best_lap_time: float = driver_stats[Pfs.STATS.BEST_LAP_TIME]
			var lap_time: float = stat_value
			if not lap_time == 0:
				if lap_time < curr_best_lap_time or curr_best_lap_time == 0:
					driver_stats[Pfs.STATS.BEST_LAP_TIME] = lap_time
					# deferred da je za lap count signalom
					call_deferred("emit_signal", "stat_changed", driver_id, Pfs.STATS.BEST_LAP_TIME, lap_time)
					emit_signal("stat_changed", driver_id, Pfs.STATS.BEST_LAP_TIME, lap_time)

		Pfs.STATS.LAP_TIME: # vsak frejm
			printt("LAP time", prev_lap_level_time, stat_value)
			var curr_game_time: float = stat_value
			var lap_time: float = curr_game_time - prev_lap_level_time
			driver_stats[stat_key] = lap_time

		_: # default
			driver_stats[stat_key] += stat_value

	emit_signal("stat_changed", driver_id, stat_key, driver_stats[stat_key])


func on_hit(hit_by: Node2D, hit_global_position: Vector2):

	if not is_shielded:

		update_stat(Pfs.STATS.HEALTH, - hit_by.hit_damage)

		if "hit_inertia" in hit_by:
			var local_hit_position: Vector2 = hit_global_position - position
			var hitter_rot_vector: Vector2 = Vector2.RIGHT.rotated(hit_by.global_rotation)
			apply_impulse(local_hit_position, hitter_rot_vector * hit_by.hit_inertia) # OPT misile impulse knockback ... ne deluje?

		if vehicle_camera:
			vehicle_camera.shake_camera(hit_by)

		if Sts.life_as_life_taken and driver_stats[Pfs.STATS.HEALTH] <= 0:
			if "spawner" in hit_by: # debug zaradi debug no2
				hit_by.spawner.update_stat(Pfs.STATS.LIFE, 1)


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


func _on_weapon_shot(stat_key: int, change_value):

	driver_stats[stat_key] += change_value # change_value je + ali -
	emit_signal("stat_changed", driver_id, stat_key, driver_stats[stat_key])


# UTILITI ------------------------------------------------------------------------------------------------


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
	#	driver.set_process_input(false)
	#	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.1
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(body_state, "transform:origin", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	#	transform.origin = pull_position
	#	collision_shape.set_deferred("disabled", false)
	#	driver.set_process_input(true)

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


func _drawing_trail_controls(delta: float):

	if Input.is_action_pressed("T"):
		if not debug_trail:
			debug_trail = Line2D.new()
			debug_trail.z_index = 1000
			Rfs.node_creation_parent.add_child(debug_trail)
		else:
			debug_trail_time += delta
			if debug_trail_time > 0.1:
				debug_trail.add_point(global_position)
				debug_trail_time = 0
	if Input.is_action_just_released("T"):
		debug_trail_time = 0
		debug_trail = null


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
	#	self.is_active = false # zazih

	pass
