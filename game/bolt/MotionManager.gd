extends Node


onready var bolt = get_parent()

enum MOTION {IDLE, FWD, REV}
var motion: int = MOTION.IDLE setget _change_motion

enum ROTATION_MOTION {
	DEFAULT,
	MASSLESS,
#	AGILE,
#	TRACKING,
#	DRIFTING,
#	NITRO, # moč motorja je lahko različna je
#	NO_CONTROLS,
	# idle
	SPIN,
	SLIDE,
	FREE,
	LOCKED,
	}
var rotation_motion: int = ROTATION_MOTION.DEFAULT

const ZERO_MASS: float = 1.0 # malo vpliva vseeno more met vsaka od mas

# debug ...
# lahko zamštraš indexe, kasneje to seta igra
export (int) var selected_rotation_motion: int = ROTATION_MOTION.DEFAULT
export (int) var selected_idle_rotation: int = ROTATION_MOTION.SPIN
var is_ai: bool = false

var force_on_bolt: Vector2 = Vector2.ZERO
var torque_on_bolt: float = 0
var is_boosting: bool = false

# engine
var current_engine_power: float = 0
var engine_power_adon: float = 0
var accelarate_speed = 0.1
var max_engine_power: float
onready var reality_engine_power_factor: float = Sts.reality_engine_power_factor

# rotation
var rotation_dir = 0 setget _change_rotation_direction
var force_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float
var max_engine_rotation_deg: float
var driving_gear: int = 0

func _ready() -> void:
	#	yield(get_tree(),"idle_frame")
	#	self.rotation_dir = 0
	pass


func _process(delta: float) -> void:


	if not bolt.is_active: # tole seta tudi na startu
		current_engine_power = 0 # cela sila je pade na 0
		#		force_on_bolt = Vector2.ZERO
		#		force_rotation = 0
		self.rotation_dir = 0
	else:
		# PLAYER ima drugače kot AI ...

		_motion_machine()
		bolt.engines.manage_engines(self)

	# debu3g
	bolt.bolt_hud.rotation_label.text = MOTION.find_key(motion) + " > " + ROTATION_MOTION.find_key(rotation_motion)
	var vector_to_target = force_on_bolt.normalized() * 0.5 * current_engine_power
	vector_to_target = vector_to_target.rotated(- bolt.global_rotation)
	bolt.direction_line.set_point_position(1, vector_to_target)
	bolt.direction_line.default_color = Color.green


func _motion_machine():

	match motion:
		MOTION.FWD:
			if is_ai:
				# force_rotation = proti tarči AI ... določa AI
				force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_bolt = Vector2.RIGHT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
		MOTION.REV:
			if is_ai:
				# force_rotation = proti tarči AI ... določa AI
				force_on_bolt = Vector2.LEFT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_bolt = Vector2.LEFT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
		MOTION.IDLE:
			force_rotation = 0
			force_on_bolt = Vector2.ZERO


func _change_motion(new_motion: int):
#	printt ("MOTION ",MOTION, motion)

	if not new_motion == motion:
		motion = new_motion

	#		match motion:
	#			MOTION.IDLE:
	#			MOTION.FWD:
	#			MOTION.REV:


func _change_rotation_direction(new_rotation_direction: float):
	# za zavijanje lahko vplivam na karkoli, ker se ob vožnji naravnost vse reseta
	# če ne zavija je fizika celega bolta
	# če zavija se porazdeli glede na stil


	rotation_dir = new_rotation_direction
	_set_default_parameters()

	if rotation_dir == 0:
		torque_on_bolt = 0
#		_set_default_parameters()
	else:
		print("is_ai ", is_ai)
		if motion == MOTION.IDLE:
			rotation_motion = selected_idle_rotation
		else:
			rotation_motion = selected_rotation_motion

		printt("rotation_change ",rotation_dir, MOTION.keys()[motion], ROTATION_MOTION.keys()[rotation_motion])

		torque_on_bolt = 0
		bolt.linear_damp = 0
		var front_mass_bias: float

		var bolt_mass: float = bolt.bolt_profile["masa"]
		match rotation_motion:
			ROTATION_MOTION.DEFAULT: # mid zavijanje + malo drifta
				max_engine_power = 800
				max_engine_rotation_deg = 25
				bolt.angular_damp = 0
				bolt.front_mass.linear_damp = 1
				bolt.rear_mass.linear_damp = 5
				front_mass_bias = 0.5
				bolt.front_mass.mass = bolt_mass * front_mass_bias
				bolt.rear_mass.mass = bolt_mass * (1 - front_mass_bias)
			ROTATION_MOTION.MASSLESS: # mid zavijanje + malo drifta
				max_engine_power = 800
				max_engine_rotation_deg = 25
				bolt.angular_damp = 0
				bolt.front_mass.linear_damp = 0
				bolt.rear_mass.linear_damp = 5
				front_mass_bias = 0.5
				bolt.front_mass.mass = bolt_mass * front_mass_bias
				bolt.rear_mass.mass = bolt_mass * (1 - front_mass_bias)
			ROTATION_MOTION.SPIN: # mid zavijanje + malo drifta
				torque_on_bolt = 10000000 * rotation_dir
#				bolt.mass = bolt_mass
				bolt.front_mass.mass = ZERO_MASS
				bolt.rear_mass.mass = ZERO_MASS
				max_engine_rotation_deg = 90
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			ROTATION_MOTION.FREE:
				for thrust in bolt.engines.all_thrusts:
					thrust.stop_fx()
			ROTATION_MOTION.LOCKED:
				pass
			ROTATION_MOTION.SLIDE:
#				force_on_bolt = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
#				linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				bolt.angular_damp = 5 # da se ne vrti, če zavija
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
		_print_bolt_data()


func _accelarate_to_engine_power():

	# če je dodatek k moči klempam na max power + dodatek
	if engine_power_adon == 0:
		current_engine_power = lerp(current_engine_power, max_engine_power, accelarate_speed)
	else:
		current_engine_power = lerp(current_engine_power, max_engine_power + engine_power_adon, accelarate_speed)
	current_engine_power = clamp(current_engine_power, 0, current_engine_power)

	return current_engine_power * reality_engine_power_factor


func _set_default_parameters():

	if is_ai:
	# bolt
		max_engine_power = bolt.bolt_profile["max_engine_power"]
		max_engine_rotation_deg = 45
		engine_rotation_speed = 0.1
		bolt.mass = bolt.bolt_profile["masa"]
		bolt.angular_damp = 5
		bolt.linear_damp = 1 # 1

	else:
		# bolt
		max_engine_power = bolt.bolt_profile["max_engine_power"]
		max_engine_rotation_deg = 45
		engine_rotation_speed = 0.1
		bolt.mass = bolt.bolt_profile["masa"]
		bolt.angular_damp = 16 # 16
		bolt.linear_damp = 1 # 1

		# front rear
		bolt.front_mass.mass = ZERO_MASS
		bolt.rear_mass.mass = ZERO_MASS
		bolt.front_mass.linear_damp = 0
		bolt.rear_mass.linear_damp = 0


func use_nitro():
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	if not is_boosting:
		is_boosting = true
		Rfs.sound_manager.play_sfx("pickable_nitro")
		var boosting_time: float = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]
		engine_power_adon += Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
		yield(get_tree().create_timer(boosting_time),"timeout")
		engine_power_adon -= Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
		is_boosting = false


func _print_bolt_data():

	printt("engine", max_engine_power, max_engine_rotation_deg, engine_rotation_speed)
	printt("_bolt", bolt.mass, bolt.linear_damp, bolt.angular_damp)
	printt("_front", bolt.front_mass.mass, bolt.front_mass.linear_damp, bolt.front_mass.angular_damp)
	printt("_rear", bolt.rear_mass.mass, bolt.rear_mass.linear_damp, bolt.rear_mass.angular_damp)
	printt("_torq", torque_on_bolt)

