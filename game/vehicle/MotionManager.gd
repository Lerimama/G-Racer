extends Node2D


var managed_vehicle: Node2D  # = get_parent()

enum MOTION {DISSABLED, IDLE, IDLE_LEFT, IDLE_RIGHT, FWD, FWD_LEFT, FWD_RIGHT, REV, REV_LEFT, REV_RIGHT, DISSARAY}#, OFF}
var motion: int = MOTION.DISSABLED setget _change_motion # idle postane on game start, disejbla ga turn off, ali ukaz "od zgoraj"

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

# debug ... oblika za export
# lahko zamštraš indexe, kasneje to seta igra
export (int) var selected_rotation_motion: int = ROTATION_MOTION.DEFAULT
export (int) var selected_idle_rotation: int = ROTATION_MOTION.SPIN

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

var is_rotating: bool = false
var is_viglvagl: bool = false

#func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:
#
#	if Input.is_action_just_pressed("no1"): # idle
#		is_viglvagl = true
#		torque_on_vehicle = -100_00000
#	elif Input.is_action_just_pressed("no2"): # idle
#		is_viglvagl = true
#		torque_on_vehicle = 100_00000
#	elif Input.is_action_just_released("no1") or Input.is_action_just_released("no2"): # idle
#		is_viglvagl = false
#		torque_on_vehicle = 0
#
#	if Input.is_action_just_pressed("no3"): # idle
#		is_rotating = true
#		torque_on_vehicle = -100_00000
#	elif Input.is_action_just_pressed("no4"): # idle
#		is_rotating = true
#		torque_on_vehicle = 100_00000
#	elif Input.is_action_just_released("no3") or Input.is_action_just_released("no4"): # idle
#		is_rotating = false
#		torque_on_vehicle = 0

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
#	prints("motion", motion)
	# vigl vagl brez vpliva na silo
	#	if Sets.HEALTH_EFFECTS.MOTION in Sets.health_effects:
	#		var damage_effect_scale: float = managed_vehicle.health_effect_factor * (1 - managed_vehicle.driver_stats[Pros.STATS.HEALTH])
	#		if damage_effect_scale > 0:
	#			var vigl_limit: float = deg2rad(10)
	#			if not is_vigling:
	#				is_vigling = true
	#				var vigl_tween = get_tree().create_tween()
	#				vigl_tween.tween_property(self, "torque_on_vehicle", -10000000 * predznak, 0.5).as_relative()
	#				yield(vigl_tween, "finished")
	#				predznak = - predznak
	#				is_vigling = false
	#				if managed_vehicle.driver_id == "MOU":
	#					printt(managed_vehicle.rotation_degrees, torque_on_vehicle, predznak)
	##				printt(managed_vehicle.rotation_degrees)
	##			_drive_vigl_vagl(damage_effect_scale)

	match motion:
		MOTION.FWD, MOTION.FWD_LEFT, MOTION.FWD_RIGHT:
			if managed_vehicle.driver_profile["controller_type"] == -1:
				# force_rotation = proti tarči AI ... določa AI
#				force_on_vehicle = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
				pass
			else:
#				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				if is_viglvagl:
					var angle_diff: float = force_rotation - (managed_vehicle.global_rotation - deg2rad(90))
					force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
					force_rotation -= angle_diff
					force_on_vehicle = Vector2.RIGHT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
				elif is_rotating:
					var angle_diff: float = force_rotation - (managed_vehicle.global_rotation - deg2rad(90))
					force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
					force_rotation -= angle_diff
					# vigl vagl z vplivom na silo
					#				if Sets.HEALTH_EFFECTS.MOTION in Sets.health_effects:
					#					var damage_effect_scale: float = managed_vehicle.health_effect_factor * (1 - managed_vehicle.driver_stats[Pros.STATS.HEALTH])
					#					if damage_effect_scale > 0:
					#						var vigl_limit: float = deg2rad(10)
					#						if not is_vigling:
					#							is_vigling = true
					#							var vigl_tween = get_tree().create_tween()
					#							vigl_tween.tween_property(self, "force_rotation", vigl_limit / 3* predznak, 0.1).as_relative()
					#							yield(vigl_tween, "finished")
					#							predznak = - predznak
					#							is_vigling = false
					force_on_vehicle = Vector2.RIGHT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
				else:
					force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
					force_on_vehicle = Vector2.RIGHT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
#			force_on_vehicle = Vector2.RIGHT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
		MOTION.REV, MOTION.REV_LEFT, MOTION.REV_RIGHT:
			if managed_vehicle.driver_profile["controller_type"] == -1:
				# force_rotation = proti tarči AI ... določa AI
				force_on_vehicle = Vector2.LEFT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_vehicle = Vector2.LEFT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()
		MOTION.IDLE, MOTION.IDLE_LEFT, MOTION.IDLE_RIGHT, MOTION.DISSABLED:
			current_engine_power = lerp(current_engine_power, 0, accelarate_speed)
			force_rotation = 0
			force_on_vehicle = Vector2.ZERO # OPT ... če ni, potem niha ... z vidika sile bi bilo bolj pravilno brez
		MOTION.DISSARAY: # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart
			current_engine_power = 0
			force_rotation = 0
			force_on_vehicle = Vector2.ZERO
#	force_on_vehicle = Vector2.ZERO
#	prints ("force_on_vehicle", force_on_vehicle)


#	if Sets.HEALTH_EFFECTS.MOTION in Sets.health_effects:
#		var damage_effect_scale: float = managed_vehicle.health_effect_factor * (1 - managed_vehicle.driver_stats[Pros.STATS.HEALTH])
#		if damage_effect_scale > 0:
#			_drive_vigl_vagl(damage_effect_scale)
#
#		force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
#		force_on_vehicle = Vector2.LEFT.rotated(force_rotation + global_rotation) * _accelarate_to_engine_power()

func _accelarate_to_engine_power(current_max_engine_power: float = max_engine_power):
#	printt (current_engine_power , max_engine_power, force_on_vehicle.length())

	current_engine_power = lerp(current_engine_power, current_max_engine_power + engine_power_addon, accelarate_speed)
#	current_engine_power = lerp(current_engine_power, current_max_engine_power + engine_power_addon, pow(accelarate_speed, 2))
	current_engine_power = clamp(current_engine_power, 0, current_engine_power)

	engine_power_percentage = current_engine_power / current_max_engine_power
	if current_max_engine_power == 0:
		engine_power_percentage = 0

	# dmg fx
	if Sets.HEALTH_EFFECTS.POWER in Sets.health_effects:
		var adapt_factor: float = 0.001
		var damage_effect_scale: float = managed_vehicle.health_effect_factor * (1 - managed_vehicle.driver_stats[Pros.STATS.HEALTH])
		var damaged_engine_power: float = current_engine_power - current_engine_power * damage_effect_scale * adapt_factor
		current_engine_power = damaged_engine_power

#	if managed_vehicle.driver_id == "MOU":
#		current_engine_power /= 15
	return current_engine_power * Sets.world_hsp_power_factor


func _change_motion(new_motion):

	motion = new_motion

	match motion: # edini rotation_dir setter
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
				# kadar je na tleh, al pa mu igra ukaže
				# ne spremeni nič ... setani ostanejo default parametri
				# je zato, da driving ne deluje
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
			#				linear_damp = managed_vehicle.def_vehicle_profile["idle_lin_damp"] # da ne izgubi hitrosti
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

			if managed_vehicle.driver_profile["controller_type"] == -1:
				max_engine_power = start_max_engine_power + ai_power_equlizer_addon
				managed_vehicle.angular_damp = 16
			else:
				max_engine_power = start_max_engine_power
				managed_vehicle.angular_damp = 14


# SPECIALS ------------------------------------------------------------------------------------


var is_vigling: bool = false
var predznak: int = -1
func _drive_vigl_vagl(vigl_vagl_amount: float):
	# dela, ampak prekine vpliv forca
	# tween je testno bolje z lerpom (in timer)

	var vigl_limit: float = deg2rad(10)
	if not is_vigling:
		is_vigling = true
		var vigl_tween = get_tree().create_tween()
		vigl_tween.tween_property(managed_vehicle, "position:x", 10.0 * predznak, 0.1).as_relative()
		vigl_tween.tween_property(managed_vehicle, "global_rotation", vigl_limit * predznak, 0.1).as_relative()
		yield(vigl_tween, "finished")
		predznak = - predznak
		is_vigling = false

	printt("drive vigl vagl", vigl_vagl_amount)



func drive_in(drive_in_position: Vector2, drive_in_rotation: float = 0, drive_in_time: float = 1):


	managed_vehicle.collision_shape.set_deferred("disabled", true) # lahko pride iz stene
	managed_vehicle.modulate.a = 1

	managed_vehicle.is_active = true
	managed_vehicle.turn_on()
	self.motion = MOTION.DISSABLED

	# premaknem ga nazaj in zapeljem do štartne pozicije na katero je spawnan
#	var vector_to_drive_in_position: Vector2 = Vector2.RIGHT.rotated(global_rotation) * global_position.length()
#	managed_vehicle.body_state.transform.origin = global_position - vector_to_drive_in_position
#	# animiram do orig pozicije
#	var drive_in_tween = get_tree().create_tween()
#	drive_in_tween.tween_property(managed_vehicle.body_state, "transform:origin", global_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
#	yield(drive_in_tween, "finished")

	managed_vehicle.collision_shape.set_deferred("disabled", false)


func drive_out(drive_out_position: Vector2, drive_out_time: float = 1):

	managed_vehicle.collision_shape.set_deferred("disabled", true)
	managed_vehicle.is_active = false

	self.motion = MOTION.FWD

	force_rotation = Vector2.RIGHT.angle_to_point(drive_out_position)
	force_on_vehicle = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
	yield(get_tree().create_timer(drive_out_time), "timeout")
#	managed_vehicle.modulate.a = 0
	managed_vehicle.turn_off()


func boost_vehicle(added_power: float = 0, boosting_time: float = 0):
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	if not is_boosting:
		is_boosting = true

		managed_vehicle.engines.boost_engines() # fx

		if added_power == 0:
			added_power = Pros.equipment_profiles[Pros.EQUIPMENT.NITRO]["nitro_power_addon"]
		engine_power_addon += added_power

		if boosting_time > 0:
			yield(get_tree().create_timer(boosting_time),"timeout")
		else:
			managed_vehicle.engines.boost_engines(false)
			boosting_time = Pros.equipment_profiles[Pros.EQUIPMENT.NITRO]["time"]

		engine_power_addon -= added_power
		is_boosting = false


func _print_vehicle_data():

	printt("engine", max_engine_power, max_engine_rotation_deg, engine_rotation_speed)
	printt("_vehicle", managed_vehicle.mass, managed_vehicle.linear_damp, managed_vehicle.angular_damp)
	printt("_front", managed_vehicle.front_mass.mass, managed_vehicle.front_mass.linear_damp, managed_vehicle.front_mass.angular_damp)
	printt("_rear", managed_vehicle.rear_mass.mass, managed_vehicle.rear_mass.linear_damp, managed_vehicle.rear_mass.angular_damp)
	printt("_torq", torque_on_vehicle)


