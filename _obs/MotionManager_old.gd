extends Node


onready var bolt = get_parent()

enum MOTION {IDLE, FWD, REV}
var motion: int = MOTION.IDLE setget _change_motion

enum ROTATION_MOTION {
	STRAIGHT,
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
var rotation_motion: int = ROTATION_MOTION.STRAIGHT

const ZERO_MASS: float =  1.0
# debug
export (int) var selected_rotation_motion: int = ROTATION_MOTION.MASSLESS
export (int) var selected_idle_rotation: int = ROTATION_MOTION.SPIN
var is_ai: bool = false

var force_on_bolt: Vector2 = Vector2.ZERO
var torque_on_bolt: float = 0

# engine
var current_engine_power: float = 0
var engine_power_adon: float = 0
var accelarate_speed = 0.1
var max_engine_power: float
var is_boosted = false
onready var reality_engine_power_factor: float = Sts.reality_engine_power_factor

# rotation
var rotation_dir = 0 setget _change_rotation_direction
var force_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed = 0.1
var max_engine_rotation_deg: float

# idle rotations
onready var fast_start_engine_power: float = bolt.bolt_profile["fast_start_engine_power"]
onready var spin_torque: float = bolt.bolt_profile["spin_torque"]
#onready var free_rotation_power: float = bolt.bolt_profile["free_rotation_power"]


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


	# debu3g
	bolt.bolt_hud.rotation_label.text = MOTION.find_key(motion) + " > " + ROTATION_MOTION.find_key(rotation_motion)
	var vector_to_target = force_on_bolt.normalized() * 0.5 * current_engine_power
	vector_to_target = vector_to_target.rotated(- bolt.global_rotation)
	bolt.direction_line.set_point_position(1, vector_to_target)
	bolt.direction_line.default_color = Color.green


func _accelarate_to_engine_power():

	# če je dodatek k moči klempam na max power + dodatek
	if engine_power_adon == 0:
		current_engine_power = lerp(current_engine_power, max_engine_power, accelarate_speed)
	else:
		current_engine_power = lerp(current_engine_power, max_engine_power + engine_power_adon, accelarate_speed)
	current_engine_power = clamp(current_engine_power, 0, current_engine_power)

	return current_engine_power * reality_engine_power_factor

func _motion_machine():

	match motion:
		MOTION.FWD:
			if is_ai:
				# force_rotation določa AI ...  je proti tarči
				force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_bolt =  Vector2.RIGHT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = force_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = - force_rotation
		MOTION.REV:
			if is_ai:
				# force_rotation določa AI
				force_on_bolt = Vector2.LEFT.rotated(force_rotation) * _accelarate_to_engine_power()
			else:
				force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_bolt =  Vector2.LEFT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()

			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = - force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = force_rotation + deg2rad(180)
		MOTION.IDLE:
			var rotate_to_angle: float = rotation_dir * deg2rad(bolt.bolt_profile["max_free_thrust_rotation_deg"]) # 60 je poseben deg2rad(max_engine_rotation_deg)
			force_rotation = 0
#			force_on_bolt = Vector2.ZERO
#			if not is_ai:
#				force_on_bolt = Vector2.ZERO
#			else:
#				force_on_bolt = Vector2.RIGHT.rotated(force_rotation)
			if rotate_to_angle == 0:
				for thrust in bolt.engines.all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			else:
				match rotation_motion:
					ROTATION_MOTION.FREE: # poravna se v smer vožnje
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
					ROTATION_MOTION.SPIN:
						for thrust in bolt.engines.front_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
						for thrust in bolt.engines.rear_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
					ROTATION_MOTION.SLIDE: # oba pogona  v smeri premika
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)
					_:
						pass


func _motion_machine_old():

	match motion:
		MOTION.FWD:
			if not is_ai:
				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
			force_on_bolt =  Vector2.RIGHT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = force_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = - force_rotation
		MOTION.REV:
			if not is_ai:
				force_rotation = lerp_angle(force_rotation, -rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
			force_on_bolt =  Vector2.LEFT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = - force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = force_rotation + deg2rad(180)
		MOTION.IDLE:
			var rotate_to_angle: float = rotation_dir * deg2rad(bolt.bolt_profile["max_free_thrust_rotation_deg"]) # 60 je poseben deg2rad(max_engine_rotation_deg)
			force_rotation = 0
			if not is_ai:
				force_on_bolt = Vector2.ZERO
			if rotate_to_angle == 0:
				for thrust in bolt.engines.all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			else:
				match rotation_motion:
					ROTATION_MOTION.FREE: # poravna se v smer vožnje
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
					ROTATION_MOTION.SPIN:
						for thrust in bolt.engines.front_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
						for thrust in bolt.engines.rear_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
					ROTATION_MOTION.SLIDE: # oba pogona  v smeri premika
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)
					_:
						pass


func _ai_motion_machine():

	bolt.angular_damp = 10

	match motion:
		MOTION.FWD:
			force_on_bolt =  Vector2.RIGHT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = force_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = - force_rotation
		MOTION.REV:
			force_on_bolt =  Vector2.LEFT.rotated(force_rotation + bolt.global_rotation) * _accelarate_to_engine_power()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = - force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = force_rotation + deg2rad(180)
		MOTION.IDLE:
			var rotate_to_angle: float = rotation_dir * deg2rad(bolt.bolt_profile["max_free_thrust_rotation_deg"]) # 60 je poseben deg2rad(max_engine_rotation_deg)
			force_rotation = 0
			if not is_ai:
				force_on_bolt = Vector2.ZERO
			if rotate_to_angle == 0:
				for thrust in bolt.engines.all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			else:
				match rotation_motion:
					ROTATION_MOTION.FREE: # poravna se v smer vožnje
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
					ROTATION_MOTION.SPIN:
						for thrust in bolt.engines.front_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
						for thrust in bolt.engines.rear_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
					ROTATION_MOTION.SLIDE: # oba pogona  v smeri premika
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)
					_:
						pass


func _change_motion(new_motion: int):
#	printt ("MOTION ",MOTION, motion)

	if not new_motion == motion:
		motion = new_motion

		match motion:
			MOTION.IDLE:
				for thrust in bolt.engines.all_thrusts:
					thrust.stop_fx()
			MOTION.FWD:
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.REV:
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()


func _change_rotation_direction(new_rotation_direction: float):
	# za zavijanje lahko vplivam na karkoli, ker se ob vožnji naravnost vse reseta
	# če ne zavija je fizika celega bolta
	# če zavija se porazdeli glede na stil

	rotation_dir = new_rotation_direction

	if rotation_dir == 0:
		rotation_motion = ROTATION_MOTION.STRAIGHT
	elif motion == MOTION.IDLE:
		rotation_motion = selected_idle_rotation
	else:
		rotation_motion = selected_rotation_motion
	torque_on_bolt = 0
	var front_mass_bias: float
	var all_mass: float = bolt.bolt_profile["masa"]

	match rotation_motion:
		ROTATION_MOTION.STRAIGHT: # mid zavijanje + malo drifta
			bolt.mass = all_mass
			bolt.front_mass.mass = ZERO_MASS
			bolt.rear_mass.mass = ZERO_MASS
			bolt.front_mass.linear_damp = 0
			bolt.rear_mass.linear_damp = 0
			max_engine_power = bolt.bolt_profile["max_engine_power"]
			max_engine_rotation_deg = bolt.bolt_profile["max_engine_rotation_deg"]
			bolt.angular_damp = bolt.bolt_profile["ang_damp"]
			bolt.linear_damp = bolt.bolt_profile["lin_damp"]
		ROTATION_MOTION.MASSLESS: # mid zavijanje + malo drifta
			max_engine_power = bolt.bolt_profile["max_engine_power_massless"]
			max_engine_rotation_deg = bolt.bolt_profile["max_engine_rotation_deg_massless"]
			front_mass_bias = bolt.bolt_profile["front_mass_bias_massless"]
			bolt.angular_damp = bolt.bolt_profile["ang_damp_massless"]
			bolt.front_mass.linear_damp = bolt.bolt_profile["lin_damp_front_massless"]
			bolt.rear_mass.linear_damp = bolt.bolt_profile["lin_damp_rear_massless"]
		ROTATION_MOTION.SPIN: # mid zavijanje + malo drifta
			torque_on_bolt = spin_torque * rotation_dir # cca 10000000
			bolt.mass = all_mass
			bolt.front_mass.mass = ZERO_MASS
			bolt.rear_mass.mass = ZERO_MASS
			bolt.front_mass.linear_damp = 0
			bolt.rear_mass.linear_damp = 0
			max_engine_power = bolt.bolt_profile["max_engine_power"]
			max_engine_rotation_deg = bolt.bolt_profile["max_engine_rotation_deg"]
			bolt.angular_damp = bolt.bolt_profile["ang_damp"]
			bolt.linear_damp = bolt.bolt_profile["lin_damp"]
			for thrust in bolt.engines.all_thrusts:
				thrust.start_fx()
		ROTATION_MOTION.FREE:
			for thrust in bolt.engines.all_thrusts:
				thrust.stop_fx()
		ROTATION_MOTION.LOCKED:
			pass
		ROTATION_MOTION.SLIDE:
			#						bolt.force = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
			#			linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
			bolt.angular_damp = bolt.bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
			for thrust in bolt.engines.all_thrusts:
				thrust.start_fx()



	# porazdelitev mase, če ni STRAIGHT
	if rotation_motion == ROTATION_MOTION.MASSLESS:
		bolt.mass = ZERO_MASS
		bolt.linear_damp = 0
		bolt.front_mass.mass = all_mass * front_mass_bias
		bolt.rear_mass.mass = all_mass * (1 - front_mass_bias)

	# preventma mass = 0 error
#	bolt.front_mass.mass = clamp(bolt.front_mass.mass, 0.1, bolt.front_mass.mass)
#	bolt.rear_mass.mass = clamp(bolt.rear_mass.mass, 0.1, bolt.rear_mass.mass)
#	bolt.mass = clamp(bolt.mass, 0.1, bolt.front_mass.mass)

func use_nitro():
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	is_boosted = true
	Rfs.sound_manager.play_sfx("pickable_nitro")
	current_engine_power += Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"] * 2
	yield(get_tree().create_timer(Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]),"timeout")
	is_boosted = false
