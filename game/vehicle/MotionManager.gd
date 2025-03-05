extends Node2D


var managed_vehicle: Node2D  # = get_parent()

enum MOTION {DISSABLED, IDLE, IDLE_LEFT, IDLE_RIGHT, FWD, FWD_LEFT, FWD_RIGHT, REV, REV_LEFT, REV_RIGHT, DISSARAY}#, OFF}
var motion: int = MOTION.IDLE setget _change_motion

enum ROTATION_MOTION {
	DEFAULT,
	DRIFT,
	SPIN,
	SLIDE,
#	AGILE,
#	TRACKING,
	}
var rotation_motion: int = ROTATION_MOTION.DEFAULT

const AKA_ZERO_MASS: float = 1.0 # malo vpliva vseeno more met vsaka od mas

# debug ...
# lahko zamštraš indexe, kasneje to seta igra
export (int) var selected_rotation_motion: int = ROTATION_MOTION.DEFAULT
export (int) var selected_idle_rotation: int = ROTATION_MOTION.SPIN
var is_ai: bool = false

var force_on_vehicle: Vector2 = Vector2.ZERO
var torque_on_vehicle: float = 0
var is_boosting: bool = false

# engine
var current_engine_power: float = 0
var engine_power_addon: float = 0
var accelarate_speed = 0.1
var max_engine_power: float

# rotation
var rotation_dir = 0
var force_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float
var max_engine_rotation_deg: float
var driving_gear: int = 0
var engine_power_percentage: float # neu namesto engine power

# neu
var vehicle_motion_profile: Resource
var start_max_engine_power: float = 500
var ai_power_equlizer_addon: float = -10
var fast_start_power_addon: float = 200
var max_engine_power_rotation_adapt: float = 1.1
# kasneje se tudi seta glede na opremo
var front_mass_bias: float = 0.5
var mass_manipulate_part: float = 0.5

func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no0"): # idle
		motion = MOTION.DISSARAY


func _ready() -> void:

	managed_vehicle = get_parent()

	if managed_vehicle.vehicle_motion_profile:
		vehicle_motion_profile = managed_vehicle.vehicle_motion_profile
		yield(managed_vehicle, "ready")
		vehicle_motion_profile._set_default_parameters(managed_vehicle)
	else:
		yield(managed_vehicle, "ready")
		_set_default_parameters()


func _process(delta: float) -> void:

	if not managed_vehicle.is_active: # tole seta tudi na startu
		current_engine_power = 0 # cela sila je pade na 0
	else:
		# PLAYER ima drugače kot AI ...
		_motion_machine()
		managed_vehicle.engines.manage_engines(self)

	# debug
	var vector_to_target = force_on_vehicle.normalized() * 0.5 * current_engine_power
	vector_to_target = vector_to_target.rotated(- global_rotation)
	managed_vehicle.direction_line.set_point_position(1, vector_to_target)
	managed_vehicle.direction_line.default_color = Color.green


func _motion_machine():

	match motion:
		MOTION.FWD, MOTION.FWD_LEFT, MOTION.FWD_RIGHT:
			if is_ai:
				# force_rotation = proti tarči AI ... določa AI
				force_on_vehicle = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_vehicle = Vector2.RIGHT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
		MOTION.REV, MOTION.REV_LEFT, MOTION.REV_RIGHT:
			if is_ai:
				# force_rotation = proti tarči AI ... določa AI
				force_on_vehicle = Vector2.LEFT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_vehicle = Vector2.LEFT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
		MOTION.IDLE, MOTION.IDLE_LEFT, MOTION.IDLE_RIGHT, MOTION.DISSABLED:
			force_rotation = 0
			force_on_vehicle = Vector2.ZERO
		MOTION.DISSARAY: # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart
			force_rotation = 0
			force_on_vehicle = Vector2.ZERO


func _accelarate_to_engine_power(current_max_engine_power: float = max_engine_power):

	current_engine_power = lerp(current_engine_power, current_max_engine_power + engine_power_addon, accelarate_speed)
	current_engine_power = clamp(current_engine_power, 0, current_engine_power)

	engine_power_percentage = current_engine_power / current_max_engine_power
	if current_max_engine_power == 0: engine_power_percentage = 0

	# upoštevam health kot poškodovano vozilo
	if Sts.health_effects_vehicle:
		var damage_effect_scale: float = managed_vehicle.health_effect_factor * (1 - managed_vehicle.driver_stats[Pfs.STATS.HEALTH])
		current_engine_power -= current_engine_power * damage_effect_scale

	# debug ... ai engine power je počasen
	if managed_vehicle.is_in_group(Rfs.group_ai):
		current_engine_power /=10

#	return current_engine_power * Sts.world_hsp_power_factor
	return 0


func _change_motion(new_motion):
#	printt("motion", MOTION.keys()[motion])

	if not motion == new_motion:
		motion = new_motion

		# edini rotation_dir setter
		match motion:
			MOTION.FWD, MOTION.REV, MOTION.IDLE, MOTION.DISSABLED:
				rotation_dir = 0
			MOTION.FWD_LEFT, MOTION.REV_LEFT, MOTION.IDLE_LEFT:
				rotation_dir = -1
			MOTION.FWD_RIGHT, MOTION.REV_RIGHT, MOTION.IDLE_RIGHT:
				rotation_dir = 1

		if vehicle_motion_profile:
			vehicle_motion_profile._set_motion_parameters(managed_vehicle, motion)

		else:
			torque_on_vehicle = 0
			_set_default_parameters()

			match motion:
				MOTION.FWD, MOTION.REV:
					managed_vehicle.angular_damp = 14
					managed_vehicle.front_mass.linear_damp = 0
					managed_vehicle.rear_mass.linear_damp = 4
				MOTION.FWD_LEFT:
					rotation_motion = selected_rotation_motion
					managed_vehicle.angular_damp = 14
					managed_vehicle.front_mass.linear_damp = 0
					managed_vehicle.rear_mass.linear_damp = 4
				MOTION.FWD_RIGHT:
					rotation_motion = selected_rotation_motion
					managed_vehicle.angular_damp = 14
					managed_vehicle.front_mass.linear_damp = 0
					managed_vehicle.rear_mass.linear_damp = 4
				MOTION.REV_LEFT:
					rotation_motion = selected_rotation_motion
					managed_vehicle.angular_damp = 14
					managed_vehicle.front_mass.linear_damp = 4
					managed_vehicle.rear_mass.linear_damp = 0
				MOTION.REV_RIGHT:
					rotation_motion = selected_rotation_motion
					managed_vehicle.angular_damp = 14
					managed_vehicle.front_mass.linear_damp = 4
					managed_vehicle.rear_mass.linear_damp = 0
				MOTION.IDLE:
					managed_vehicle.angular_damp = 1
				MOTION.IDLE_LEFT:
					rotation_motion = selected_idle_rotation
					managed_vehicle.angular_damp = 3
				MOTION.IDLE_RIGHT:
					rotation_motion = selected_idle_rotation
					managed_vehicle.angular_damp = 3
				MOTION.DISSABLED:
					pass
				MOTION.DISSARAY:
					pass # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart

			if not rotation_dir == 0:
				_set_rotation_parameters(rotation_dir)



func _set_rotation_parameters(is_reverse: bool = false):
#	printt("rotation on resource", motion_manager.MOTION.keys()[motion_manager.motion])

	match rotation_motion:
		ROTATION_MOTION.DEFAULT:
			max_engine_rotation_deg = 35
			managed_vehicle.angular_damp = 10
			# masa vehicla
			var manipulate_part_mass: float = managed_vehicle.mass * mass_manipulate_part
			managed_vehicle.mass -= manipulate_part_mass
			managed_vehicle.front_mass.mass = manipulate_part_mass * front_mass_bias
			managed_vehicle.rear_mass.mass = manipulate_part_mass * (1 - front_mass_bias)
			#			if is_reverse:
			#				managed_vehicle.front_mass.linear_damp = 0
			#				managed_vehicle.rear_mass.linear_damp = 4
			#			else:
			#			managed_vehicle.front_mass.linear_damp = 0
			#			managed_vehicle.rear_mass.linear_damp = 4
		ROTATION_MOTION.DRIFT:
			max_engine_rotation_deg = 32
			managed_vehicle.front_mass.linear_damp = 1
			managed_vehicle.rear_mass.linear_damp = 6
			# masa vehicla
			var manipulate_part_mass: float = managed_vehicle.mass * mass_manipulate_part
			managed_vehicle.mass -= manipulate_part_mass
			managed_vehicle.front_mass.mass = manipulate_part_mass * front_mass_bias
			managed_vehicle.rear_mass.mass = manipulate_part_mass * (1 - front_mass_bias)
		ROTATION_MOTION.SPIN:
			managed_vehicle.angular_damp = 4 # 16
			torque_on_vehicle = 9300000 * rotation_dir
			max_engine_rotation_deg = 90
		ROTATION_MOTION.SLIDE:
			#				force_on_vehicle = Vector2.DOWN.rotated(managed_vehicle.rotation) * rotation_dir
			#				linear_damp = managed_vehicle.default_vehicle_profile["idle_lin_damp"] # da ne izgubi hitrosti
			managed_vehicle.angular_damp = 5 # da se ne vrti, če zavija




func _set_default_parameters(): # fizični, ne vsebinski22

	if managed_vehicle:

		if vehicle_motion_profile:
			vehicle_motion_profile._set_default_parameters(managed_vehicle)
		else:
			max_engine_rotation_deg = 45
			engine_rotation_speed = 0.1
			managed_vehicle.mass = managed_vehicle.masa
			managed_vehicle.linear_damp = 1
			managed_vehicle.front_mass.mass = AKA_ZERO_MASS
			managed_vehicle.rear_mass.mass = AKA_ZERO_MASS
			managed_vehicle.front_mass.linear_damp = 0
			managed_vehicle.rear_mass.linear_damp = 0

			if is_ai:
				max_engine_power = start_max_engine_power + ai_power_equlizer_addon
				managed_vehicle.angular_damp = 16
			else:
				max_engine_power = start_max_engine_power
				managed_vehicle.angular_damp = 14

# SPECIALS ------------------------------------------------------------------------------------


func drive_in(drive_in_position: Vector2, drive_in_time: float = 1):

	managed_vehicle.collision_shape.set_deferred("disabled", true) # lahko pride iz stene
	managed_vehicle.modulate.a = 1

	managed_vehicle.is_active = true
	managed_vehicle.turn_on()

	# premaknem ga nazaj in zapeljem do štartne pozicije na katero je spawnan
	var vector_to_drive_in_position: Vector2 = - Vector2.RIGHT.rotated(global_rotation) * (drive_in_position - global_position).length()
	managed_vehicle.body_state.transform.origin = global_position + vector_to_drive_in_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(managed_vehicle.body_state, "transform:origin", global_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")

	managed_vehicle.collision_shape.set_deferred("disabled", false)


func drive_out(drive_out_position: Vector2, drive_out_time: float = 1):

	managed_vehicle.collision_shape.set_deferred("disabled", true)
	managed_vehicle.is_active = false

	motion = MOTION.FWD

	force_rotation = Vector2.RIGHT.angle_to_point(drive_out_position)
	force_on_vehicle = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
	yield(get_tree().create_timer(drive_out_time), "timeout")
#	managed_vehicle.modulate.a = 0
	managed_vehicle.turn_off()


func boost_vehicle(added_power: float = 0, boosting_time: float = 0):
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	if not is_boosting:
		is_boosting = true
		Rfs.sound_manager.play_sfx("pickable_nitro")
		if added_power == 0:
			added_power = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_addon"]
		engine_power_addon += added_power
		if boosting_time == 0:
			boosting_time = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]
		yield(get_tree().create_timer(boosting_time),"timeout")

		engine_power_addon -= added_power
		is_boosting = false


func _print_vehicle_data():

	printt("engine", max_engine_power, max_engine_rotation_deg, engine_rotation_speed)
	printt("_vehicle", managed_vehicle.mass, managed_vehicle.linear_damp, managed_vehicle.angular_damp)
	printt("_front", managed_vehicle.front_mass.mass, managed_vehicle.front_mass.linear_damp, managed_vehicle.front_mass.angular_damp)
	printt("_rear", managed_vehicle.rear_mass.mass, managed_vehicle.rear_mass.linear_damp, managed_vehicle.rear_mass.angular_damp)
	printt("_torq", torque_on_vehicle)


