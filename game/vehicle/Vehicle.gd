extends RigidBody2D
class_name Vehicle


signal vehicle_deactivated (vehicle)
signal stat_changed (stats_owner_id, driver_stats) # vehicle in damage

export var height: float = 0 # na redi potegne iz pro
export var elevation: float = 0
export (NodePath) var engines_path: String  # _temp ... engines
export var group_equipment_by_type: bool = true

var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju
var velocity: Vector2 = Vector2.ZERO

# driver (poda spawner)
var driver_id
var driver_profile: Dictionary
var driver_stats: Dictionary
var weapon_stats: Dictionary
var def_vehicle_profile: Dictionary
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
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var body_state: Physics2DDirectBodyState
var driver_tracker: PathFollow2D # napolni se, ko se vehicle pripiše trackerju

# drugo ...
var prev_lap_level_time: int = 0 # _temp tukaj na hitro z beleženje lap timeta

onready var controller: Node2D = $Controller # zamenja se ob spawnu AI/PLAYER
onready var motion_manager: Node2D = $Motion

onready var equip_positions: Node2D = $EquipPositions
onready var equipment: Node2D = $Equipment
onready var shape_poly: Polygon2D = $ShapePoly
onready var engines: Node2D = get_node(engines_path)

onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
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
onready var weapons_holder: Node2D = $Weapons
var masa: float
var heal_rate: float
var rank_by: int = 0 # ta podatek more vedet, da da ve kaj je namen obstoja
var turned_on: bool = false	# neodvisen on aktivitja
export (float, 5, 20, 0.5) var driving_elevation: float = 7
# sounds
onready var collision_sound: AudioStreamPlayer = $Sounds/Collision
var weapons_types_with_weapons: Dictionary = {}


func _input(event: InputEvent) -> void:

	if Input.is_action_pressed("no1"): # idle
		if driver_id == "MOU":
#			print("transform:origin", body_state.get_angular_velocity())
#			var xform = body_state.get_transform()
#			xform = xform.rotated(deg2rad(1))
##			xform.origin = Vector2.ONE
#			body_state.set_transform(xform)
#			set_applied_torque(10000000000)
#			transform.origin *= 10
			print("after", body_state.get_angular_velocity())

	if Input.is_action_pressed("no2"): # race
#		update_stat(Pros.STATS.LIFE, 3)
		if driver_id == "JOU":
			update_stat(Pros.STATS.HEALTH, -0.1)
#
	if Input.is_action_pressed("no3"): # race
		if driver_id == "JOU":
			update_stat(Pros.STATS.GAS, -100)
#		update_stat(Pros.STATS.HEALTH, 0.1)
#	if Input.is_action_pressed("no4"): # race
#	if Input.is_action_pressed("no5"): # race
#		update_stat(Pros.STATS.GAS, 100)


func _ready() -> void:

	add_to_group(Refs.group_agents)
	add_to_group(Refs.group_vehicles)
	add_to_group(Refs.group_drivers) # more bit tukaj, da ga najde

	z_as_relative = false
	z_index = Pros.z_indexes["vehicles"]
	shape_poly.color = driver_profile["driver_color"]

	equip_positions.hide()
	near_radius = get_node("NearArea/CollisionShape2D").shape.radius # za pullanje

	if driver_profile:
		vehicle_color = driver_profile["driver_color"] # driver barva ...

	_load_vehicle_parameters()
	motion_manager.set_script(def_vehicle_profile["motion_manager_path"])
	_spawn_driver_controller()
	_set_equipment()


func _process(delta: float) -> void:

#	if driver_id == "JOU":
#		print("---------------")
#		print(weapon_stats)
	# debug trail
	_drawing_trail_controls(delta)

	trail_source.update_trail(velocity.length())

	if is_active:
		if engines.engines_on: update_stat(Pros.STATS.GAS, gas_usage)
		if driver_stats[Pros.STATS.HEALTH] < 1:
			update_stat(Pros.STATS.HEALTH, heal_rate * Sets.heal_rate_factor)


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


func _die(only_dissable: bool = false):

	if only_dissable:
		self.is_active = false
	else:
		collision_shape.set_deferred("disabled", true)
		_explode()

		if driver_stats[Pros.STATS.GAS] <= 0: # manjko benza je permanentni die
			self.is_active = false
			queue_free()
		else:
			# no life count
			if Sets.life_as_scalp or driver_stats[Pros.STATS.LIFE] == -1: # -1 pomeni, da se ne šteje
				turn_off()
				controller.set_process_input(false)
				call_deferred("set_physics_process", false)
				call_deferred("set_process", false)
				yield(get_tree().create_timer(revive_time), "timeout")
				_revive()
			# life counts
			else:
				update_stat(Pros.STATS.LIFE, - 1)
				if driver_stats[Pros.STATS.LIFE] > 0: # life je array current/max
					turn_off()
					controller.set_process_input(false)
					call_deferred("set_physics_process", false)
					call_deferred("set_process", false)
					yield(get_tree().create_timer(revive_time), "timeout")
					_revive()
				else:
					self.is_active = false
					queue_free()


func _revive():

	controller.set_process_input(true)
	call_deferred("set_physics_process", true)
	call_deferred("set_process", true)
	collision_shape.set_deferred("disabled", false)
	show()
	turn_on()

	# reset energije
	update_stat(Pros.STATS.HEALTH, 1)


func turn_on():
	# turn_on ne vpliva na motion

	engines.start_engines()
	turned_on = true

	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(self, "elevation", driving_elevation, 2).from(0.0).set_ease(Tween.EASE_IN_OUT)
	yield(turn_tween, "finished")
	motion_manager.motion = motion_manager.MOTION.IDLE


func turn_off():
	# turn_off motion disejbla

	trail_source.decay() # zazih
	engines.stop_engines()

	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(self, "elevation", 0, 1).set_ease(Tween.EASE_IN_OUT)
	yield(turn_tween, "finished")
	motion_manager.motion = motion_manager.MOTION.DISSABLED
	turned_on = false


func _change_activity(new_is_active: bool):
	# ko ga igra šteje ali pa pozabi
	# nima veze z ugašanjem in skrivanjem
	# nima veze z motion
	# kontrole so kompletno off

	is_active = new_is_active

	# postane znan igri, ni pa nujno prižgan
	if is_active:
		_load_vehicle_parameters()
		controller.set_process_input(true)
		call_deferred("set_physics_process", true)
		call_deferred("set_process", true)
	else:
		turn_off()
		_save_vehicle_parameters()
		controller.set_process_input(false)
		call_deferred("set_physics_process", false)
		call_deferred("set_process", false)
		emit_signal("vehicle_deactivated", self)


# SET -------------------------------------------------------------------------------------------------


func _set_equipment():

	weapons_types_with_weapons.clear()

	for weapon in weapons_holder.get_children():
		if weapon in equip_positions.positions_equiped.values():
			weapon.set_weapon(self)
			if "load_count" in weapon: # če ma ammo ali več kosov ... ni mala
				weapon_stats[weapon] = weapon.load_count
				if not weapon.weapon_type in weapons_types_with_weapons:
					weapons_types_with_weapons[weapon.weapon_type] = [weapon]
				else:
					weapons_types_with_weapons[weapon.weapon_type].append(weapon)
			else:
				weapon_stats[weapon] = 0
		else:
			weapon.hide()

	# equipement
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
		vehicle_motion_profile.height = height
		vehicle_motion_profile.driving_elevation = driving_elevation
		vehicle_motion_profile.gas_tank_size = gas_tank_size
		# vehicle_motion_profile.gas_usage = gas_usage
		# vehicle_motion_profile.gas_usage_idle = gas_usage_idle
		# vehicle_motion_profile.masa = masa
		vehicle_motion_profile.on_hit_disabled_time = on_hit_disabled_time
		vehicle_motion_profile.group_equipment_by_type = group_equipment_by_type
		vehicle_motion_profile.health_effect_factor = health_effect_factor
		vehicle_motion_profile.heal_rate = heal_rate
		# motion manager
		vehicle_motion_profile.start_max_engine_power = motion_manager.start_max_engine_power
		vehicle_motion_profile.ai_power_equlizer_addon = motion_manager.ai_power_equlizer_addon
		vehicle_motion_profile.fast_start_power_addon = motion_manager.fast_start_power_addon
		vehicle_motion_profile.max_engine_power_rotation_adapt = motion_manager.max_engine_power_rotation_adapt
	else:
		def_vehicle_profile["health_effect_factor"] = health_effect_factor
		def_vehicle_profile["heal_rate"] = heal_rate
		def_vehicle_profile["on_hit_disabled_time"] = on_hit_disabled_time
		def_vehicle_profile["height"] = height
		def_vehicle_profile["driving_elevation"] = driving_elevation
		def_vehicle_profile["gas_tank_size"] = gas_tank_size
		def_vehicle_profile["gas_usage"] = gas_usage
		def_vehicle_profile["gas_usage_idle"] = gas_usage_idle


func _load_vehicle_parameters(): # vsebinski, ne fizični

	if vehicle_motion_profile:
		health_effect_factor = vehicle_motion_profile.health_effect_factor
		heal_rate = vehicle_motion_profile.heal_rate
		on_hit_disabled_time = vehicle_motion_profile.on_hit_disabled_time
		height = vehicle_motion_profile.height
		driving_elevation = vehicle_motion_profile.driving_elevation
		gas_tank_size = vehicle_motion_profile.gas_tank_size
		gas_usage = vehicle_motion_profile.gas_usage
		gas_usage_idle = vehicle_motion_profile.gas_usage_idle
	else:
		health_effect_factor = def_vehicle_profile["health_effect_factor"]
		heal_rate = def_vehicle_profile["heal_rate"]
		on_hit_disabled_time = def_vehicle_profile["on_hit_disabled_time"]
		height = def_vehicle_profile["height"]
		driving_elevation = def_vehicle_profile["driving_elevation"]
		gas_tank_size = def_vehicle_profile["gas_tank_size"]
		gas_usage = def_vehicle_profile["gas_usage"]
		gas_usage_idle = def_vehicle_profile["gas_usage_idle"]


func _spawn_driver_controller():

	var drivers_driver_profile: Dictionary = Pros.controller_profiles[driver_profile["controller_type"]]
	var DriverController: PackedScene = drivers_driver_profile["controller_scene"]

	# spawn na vrh vehicleovega drevesa
	controller = DriverController.instance()
	controller.vehicle = self
	controller.motion_manager = motion_manager
	controller.controller_type = driver_profile["controller_type"]

	call_deferred("add_child", controller)
	call_deferred("move_child", controller, 0)


# ON ------------------------------------------------------------------------------------------------


func update_stat(stat_key: int, stat_value):
#	print("stat key", Pros.STATS.keys()[stat_key])
	# statistika se preračuna in pošlje naprej nova vrednost
	# change_value je lahko:
	#	+/- delta value ... driver_stats += change_value >> default
	#	end value ... driver_stats = change_value
	# 	trenuten čas

	if not stat_value == null: # da lahko apdejtam samo prikaz brez vrednosti
		match stat_key:
			# vehicle
			Pros.STATS.GAS:
				if is_in_group(Refs.group_players) or Sets.ai_gas_on:
					# dmg fx
					if Sets.HEALTH_EFFECTS.GAS in Sets.health_effects:
						var damage_effect_scale: float = health_effect_factor * (1 - driver_stats[Pros.STATS.HEALTH])
						var damaged_gas_usage: float = stat_value + stat_value * damage_effect_scale
						stat_value = damaged_gas_usage
					# stat
					driver_stats[stat_key] += stat_value
					if driver_stats[Pros.STATS.GAS] <= 0:
						driver_stats[Pros.STATS.GAS] = 0
						_die(true)
					elif driver_stats[Pros.STATS.GAS] > gas_tank_size: # povečam max ... obstaja zaradi hud gas bar
						gas_tank_size = driver_stats[Pros.STATS.GAS]
			Pros.STATS.HEALTH:
				driver_stats[stat_key] += stat_value # change_value je + ali -
				driver_stats[Pros.STATS.HEALTH] = clamp(driver_stats[Pros.STATS.HEALTH], 0, 1) # kadar maxiram max heath lahko dodam samo 1 in je ok
				if driver_stats[Pros.STATS.HEALTH] == 0:
					_die()
			# driver
			Pros.STATS.LIFE:
				driver_stats[stat_key] += stat_value
			Pros.STATS.GOALS_REACHED: # goal nodes names or duplicate?
				driver_stats[stat_key].append(stat_value)
			Pros.STATS.WINS: # level names
				# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
				driver_stats[stat_key].append(stat_value)
				#			driver_stats[stat_key] += stat_value
			# level
			Pros.STATS.LEVEL_PROGRESS:
				driver_stats[stat_key] = stat_value
			Pros.STATS.LEVEL_RANK:
				driver_stats[stat_key] = stat_value
			Pros.STATS.LEVEL_TIME: # na finished
				driver_stats[stat_key] = stat_value
			Pros.STATS.LAP_COUNT:
				# dobiš level time in odšteješ prev lap level time
				var lap_time: int = stat_value - prev_lap_level_time
				prev_lap_level_time = stat_value
				driver_stats[stat_key].append(lap_time)
				# best lap
				var curr_best_lap_time: float = driver_stats[Pros.STATS.BEST_LAP_TIME]
				if not lap_time == 0:
					if lap_time < curr_best_lap_time or curr_best_lap_time == 0:
						driver_stats[Pros.STATS.BEST_LAP_TIME] = lap_time
						call_deferred("emit_signal", "stat_changed", driver_id, Pros.STATS.BEST_LAP_TIME, lap_time) # deferred da je za lap time signalom
			Pros.STATS.LAP_TIME: # vsak frejm
				var curr_game_time: float = stat_value
				var lap_time: float = curr_game_time - prev_lap_level_time
				driver_stats[stat_key] = lap_time

			_: # default
				if stat_key in driver_stats:
					driver_stats[stat_key] += stat_value
				else:
					print("stat is not legit: ", stat_key)
					return

	emit_signal("stat_changed", driver_id, stat_key, driver_stats[stat_key])


func on_hit(hit_by: Node2D, hit_global_position: Vector2):

	if not is_shielded:

		update_stat(Pros.STATS.HEALTH, - hit_by.hit_damage)

		if "hit_inertia" in hit_by:
			var local_hit_position: Vector2 = hit_global_position - position
			var hitter_rot_vector: Vector2 = Vector2.RIGHT.rotated(hit_by.global_rotation)
			apply_impulse(local_hit_position, hitter_rot_vector * hit_by.hit_inertia) # OPT misile impulse knockback ... ne deluje?

		if vehicle_camera:
			vehicle_camera.shake_camera(hit_by)

		if Sets.life_as_scalp and driver_stats[Pros.STATS.HEALTH] <= 0:
			if "weapon_owner" in hit_by:
				hit_by.weapon_owner.update_stat(Pros.STATS.LIFE, 1)
			else: # ne sme prit do tega not gud
				hit_by.update_stat(Pros.STATS.LIFE, 1)


	if driver_profile["controller_type"] == -1:
		if "weapon_owner" in hit_by:
			controller.react_on_hit(hit_by.weapon_owner)
		else: # ne sme prit do tega not gud
			print ("hit by brez ownerja: ", hit_by)
			controller.react_on_hit(hit_by)


func on_item_picked(pickable_key: int):

	var pickable_key_index: int = Pros.PICKABLE.values().find(pickable_key)
	var pickable_key_name: String = Pros.PICKABLE.keys()[pickable_key_index]

	match pickable_key:
		Pros.PICKABLE.SHIELD:
			_spawn_shield()
		Pros.PICKABLE.NITRO:
			motion_manager.boost_vehicle()
		# weapons
		Pros.PICKABLE.GUN, Pros.PICKABLE.TURRET, Pros.PICKABLE.LAUNCHER, Pros.PICKABLE.DROPPER, Pros.PICKABLE.MALA:
			if not weapons_types_with_weapons.empty():
				# vzamem tipe orožij s prvega orožja na voljo in poiščem enak key
				var WEAPON_TYPE: Dictionary = weapons_types_with_weapons.values().front().front().WEAPON_TYPE
				for weapon_type_key in WEAPON_TYPE:
					if weapon_type_key == pickable_key_name:
						var weapon_type: int = WEAPON_TYPE[weapon_type_key]
						# če grupiram, apgrejdam samo prvo orožje ... count ga potem množi s številom enakih orožij
						# če ne, apgrejdam vsa orožja ... ali kolikor hočem
						if group_equipment_by_type:
							weapons_types_with_weapons[weapon_type].front().load_count = Pros.pickable_profiles[pickable_key]["value"]
						else:
							for weapon in weapons_types_with_weapons[weapon_type]:
								weapon.load_count = Pros.pickable_profiles[pickable_key]["value"]
						break
		_: # stats
			# poiščem STAT z enakim "key", kot je pickable key
			var stat_key_index: int = Pros.STATS.keys().find(pickable_key_name)
			if stat_key_index > -1:
				var change_value: float = Pros.pickable_profiles[pickable_key]["value"]
				var change_stat_key: int = Pros.STATS.values()[stat_key_index]
				update_stat(change_stat_key, Pros.pickable_profiles[pickable_key]["value"])


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
	Refs.node_creation_parent.add_child(new_exploding_vehicle)

	hide()


func _spawn_shield():

	var ShieldScene: PackedScene = Pros.equipment_profiles[Pros.EQUIPMENT.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = global_position
	new_shield.spawner = self # ime avtorja izstrelka
	new_shield.scale = Vector2.ONE
	new_shield.shield_time = Pros.equipment_profiles[Pros.EQUIPMENT.SHIELD]["time"]

	Refs.node_creation_parent.add_child(new_shield)


func pull_on_screen(pull_position: Vector2): # kliče GM
	return
		# disejblam koližne
	#	controller.set_process_input(false)
	#	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.1
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(body_state, "transform:origin", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	#	transform.origin = pull_position
	#	collision_shape.set_deferred("disabled", false)
	#	controller.set_process_input(true)

	update_stat(Pros.STATS.GAS, Sets.pull_gas_penalty)


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
			Refs.node_creation_parent.add_child(debug_trail)
		else:
			debug_trail_time += delta
			if debug_trail_time > 0.1:
				debug_trail.add_point(global_position)
				debug_trail_time = 0
	if Input.is_action_just_released("T"):
		debug_trail_time = 0
		debug_trail = null


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_Vehicle_collision(body: Node2D) -> void:

	collision_sound.play()

	# odbojni partikli
	if velocity.length() > pseudo_stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = body_state.get_contact_local_position(0)
		new_collision_particles.rotation = body_state.get_contact_local_normal(0).angle() # rotacija partiklov glede na normalo površine
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič
		new_collision_particles.color = vehicle_color
		new_collision_particles.set_emitting(true) # ker je one-shot ne morem prednastaviti
		Refs.node_creation_parent.add_child(new_collision_particles)

	trail_source.decay()


func _exit_tree() -> void: # če ni samo za za debug je nekaj narobe ... da se brez tega
	# pospravljanje morebitnih smeti
	#	printt("smeti", name, is_active)
	#	self.is_active = false # zazih

	pass

