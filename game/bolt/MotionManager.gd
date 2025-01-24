extends Node


onready var bolt = get_parent()

enum MOTION {FLOAT, FWD, REV, DISARRAY}
var motion: int = MOTION.FLOAT setget _change_motion

enum FLOATING_ROTATION {FREE, SLIDE, ROTATE, LOCKED}
export (FLOATING_ROTATION) var floating_rotation: int = FLOATING_ROTATION.FREE

enum TURNING_MODE {NO_MASS, AGILE, TRACKING, DRIFTING, BOOSTED}
export (TURNING_MODE) var turning_mode: int = 0 setget _set_turning_mode

var force_on_bolt = Vector2.ZERO

# engine
var engine_power: float = 0
var max_engine_power: float = 0 # setget _change_max_engine_power
var def_max_engine_power = 1000
var max_engine_power_adon: float = 0
var max_engine_power_factor: float = 1
var accelaration_power = 0
var bolt_shift: int = 1 # -1 = rikverc, +1 = naprej, 0 ne obstaja ... za daptacijo, ker je moč motorja zmeraj pozitivna
onready var free_rotation_power: float = bolt.bolt_profile["free_rotation_power"]
onready var fast_start_engine_power: float = bolt.bolt_profile["fast_start_engine_power"]

# direction
var force_rotation: float = 0 # rotacija v smeri skupne sile motorjev ... določam v _FP (input), apliciram v _IF
var force_summ_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var rotation_dir = 0
var engine_rotation_speed: float = 0.1
onready var max_engine_rotation_deg: float = bolt.bolt_profile["max_engine_rotation_deg"]

# adapt to driving mode
var lin_damp_engine_power_adapt: float = 0.2 # 0.5 težišče je na sredini
var lin_damp_acc_adapt: float = 0.2 # 0.5 težišče je na sredini


func _ready() -> void:
#
##	self.turning_mode = turning_mode
	yield(get_parent(), "ready")
	self.turning_mode = turning_mode
	pass


func _process(delta: float) -> void:
#	printt ("FP", TURNING_MODE.keys()[turning_mode])
#	printt ("FP", round(engine_power/1000), def_max_engine_power, bolt.front_mass.get_applied_force().length(), bolt.rear_mass.get_applied_force().length())

	if not bolt.is_active:
		engine_power = 0
		rotation_dir = 0
		force_on_bolt = Vector2.ZERO
	else:
		_motion_machine()

		max_engine_power = (def_max_engine_power + max_engine_power_adon) * max_engine_power_factor
		max_engine_power *= Rfs.game_manager.game_settings["reality_engine_power_factor"]

		# debug
		var vector_to_target = force_on_bolt.normalized() * engine_power/def_max_engine_power/3
		vector_to_target = vector_to_target.rotated(- bolt.global_rotation)# - get_global_rotation()
		bolt.direction_line.set_point_position(1, vector_to_target)
		if force_on_bolt == Vector2.ZERO:
			#			bolt.direction_line.set_point_position(1, Vector2.RIGHT * 50)
			bolt.direction_line.default_color = Color.red
		else:
			bolt.direction_line.default_color = Color.green

	bolt.force = force_on_bolt


func _motion_machine():
#	printt("rotation_dir", rotation_dir)

	force_summ_rotation = lerp_angle(force_summ_rotation, rotation_dir * deg2rad(max_engine_rotation_deg) * bolt_shift, engine_rotation_speed)
	var rotate_to_angle: float = rotation_dir * deg2rad(bolt.bolt_profile["max_free_thrust_rotation_deg"]) # 60 je poseben deg2rad(max_engine_rotation_deg)

	#	force_on_bolt = Vector2.ZERO
	bolt.set_applied_torque(0)
	match motion:
		MOTION.FWD:
			force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift
			_accelarate()
			if Rfs.game_manager.fast_start_window:
				engine_power += fast_start_engine_power
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = force_summ_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = - force_summ_rotation
		MOTION.REV:
			force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift
			_accelarate()
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = - force_summ_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = force_summ_rotation + deg2rad(180)
		MOTION.FLOAT:
			if rotate_to_angle == 0:
				force_on_bolt = Vector2.ZERO
				engine_power = 0
				for thrust in bolt.engines.all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			else:
				match floating_rotation:
					FLOATING_ROTATION.FREE: # poravna se v smer vožnje
						engine_power = 0
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
					FLOATING_ROTATION.ROTATE:
						bolt.set_applied_torque(10000000 * rotation_dir)
						force_on_bolt = Vector2.ZERO
						bolt.front_mass.linear_damp = 4
						bolt.rear_mass.linear_damp = 4
						for thrust in bolt.engines.front_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
						for thrust in bolt.engines.rear_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
					FLOATING_ROTATION.SLIDE: # oba pogona  v smeri premika
						engine_power = 0
						for thrust in bolt.engines.all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)

		#			motion_manager.MOTION.FREE_ROTATE:
		#				rear_mass.set_applied_force(force)
		#				front_mass.set_applied_force(- force)
		#			motion_manager.MOTION.DRIFT:
		#				#				motion_manager.engine_power = max_engine_power # poskrbi za bolj "tight" obrat
		#				front_mass.set_applied_force(force)
		#				#				rear_mass.set_applied_force(Vector2.UP.rotated(rotation) * 1000 * motion_manager.rotation_dir)
		#			motion_manager.MOTION.SLIDE:
		#				front_mass.set_applied_force(force * glide_power_front)
		#				rear_mass.set_applied_force(force * glide_power_rear)


func _change_motion(new_motion: int):
#	printt ("MOTION ",MOTION, motion)

	if not new_motion == motion:
		motion = new_motion

		match motion:
			MOTION.FLOAT:
				if bolt_shift > 0:
					bolt.rear_mass.set_applied_force(Vector2.ZERO)
				else:
					bolt.front_mass.set_applied_force(Vector2.ZERO)
				bolt.angular_damp = bolt.bolt_profile["ang_damp_float"]
				for thrust in bolt.engines.all_thrusts:
					thrust.stop_fx()
				_set_floating_rotation()
			MOTION.FWD:
				bolt.rear_mass.set_applied_force(Vector2.ZERO)
				bolt.angular_damp = bolt.bolt_profile["ang_damp"]
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.REV:
				bolt.front_mass.set_applied_force(Vector2.ZERO)
				bolt.angular_damp = bolt.bolt_profile["ang_damp"]
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.DISARRAY:
				pass



func _set_turning_mode(new_turning_mode: int): # = turning_mode):

	turning_mode = new_turning_mode

#	printt ("driving", TURNING_MODE.keys()[turning_mode])
#	if not turning_mode == new_turning_mode:

	var new_front_mass_bias: float
	var mass_summ: float
	match turning_mode:
		TURNING_MODE.NO_MASS: # mid zavijanje + malo drifta
			mass_summ = bolt.bolt_profile["masa"]
			engine_rotation_speed = 0.1
			accelaration_power = 3.2
			def_max_engine_power = 1000
			new_front_mass_bias = 0.5
			bolt.angular_damp = 0
			bolt.front_mass.linear_damp = 0
			bolt.rear_mass.linear_damp = 5
			max_engine_rotation_deg = 25

#		TURNING_MODE.NAKED:
#			mass_summ = 0
#			new_front_mass_bias = 0.5
#			bolt.angular_damp = 0
#			bolt.linear_damp = 0 # imam ga za omejitev slajdanja prvega kolesa
#			bolt.front_mass.linear_damp = 0
#			bolt.rear_mass.linear_damp = 0

		TURNING_MODE.AGILE: # hitro vijuganje, nežno driftanje
			mass_summ = bolt.bolt_profile["masa"]
			accelaration_power = 3.2#000
			def_max_engine_power = 700 * 2#000
			new_front_mass_bias = 0.5
			bolt.angular_damp = 5
			bolt.front_mass.linear_damp = 2
			bolt.rear_mass.linear_damp = 8

		TURNING_MODE.TRACKING: # dolgo zavijanje, no drift
			mass_summ = bolt.bolt_profile["masa"]
			engine_rotation_speed = 0.5
			accelaration_power = 3.2#000
			def_max_engine_power = 800 * 2#000
			new_front_mass_bias = 0.5
			bolt.angular_damp = 50
			bolt.front_mass.linear_damp = 3
			bolt.rear_mass.linear_damp = 5
			max_engine_rotation_deg = 32

		TURNING_MODE.DRIFTING: # krajše zavijanje + drift
			engine_rotation_speed = 0.6
			mass_summ = bolt.bolt_profile["masa"]
			accelaration_power = 3.2
			def_max_engine_power = 700
			new_front_mass_bias = 0.2
			bolt.angular_damp = 32
			bolt.front_mass.linear_damp = 4
			bolt.rear_mass.linear_damp = 0.2
			max_engine_rotation_deg = 35


	# porazdelitev mase
	if turning_mode == TURNING_MODE.NO_MASS:
		bolt.mass = 0
		bolt.front_mass.mass = mass_summ * new_front_mass_bias
		bolt.rear_mass.mass = mass_summ * (1 - new_front_mass_bias)
	else:
		bolt.mass = mass_summ
		var front_rear_mass: float = bolt.front_mass.mass + bolt.rear_mass.mass
		bolt.front_mass.mass = front_rear_mass * new_front_mass_bias
		bolt.rear_mass.mass = front_rear_mass * (1 - new_front_mass_bias)


func _accelarate():

#	var acc_tween = get_tree().create_tween()
#	acc_tween.tween_property(bolt, "engine_power", max_engine_power * 2, 1).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_BOUNCE)
#	engine_power += accelaration_power
	engine_power = lerp(engine_power, max_engine_power, 0.1)



func	_set_floating_rotation():
#	printt("set", FLOATING_ROTATION.keys()[floating_rotation])

	match floating_rotation:
		FLOATING_ROTATION.FREE:
			pass
		FLOATING_ROTATION.LOCKED:
			pass
		FLOATING_ROTATION.SLIDE:
			bolt.force = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
			#			linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
			bolt.angular_damp = bolt.bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
			for thrust in bolt.engines.all_thrusts:
				thrust.start_fx()
		FLOATING_ROTATION.ROTATE:
#			bolt.angular_damp = 0 # če tega ni moraš prekinit tipko, da se preklopi preko FLOAT stanja
			bolt.front_mass.linear_damp = 0
			bolt.rear_mass.linear_damp = 0
			for thrust in bolt.engines.all_thrusts:
				thrust.start_fx()


func _zaloga_turningov():
	pass
#		TURNING_MODE.SLOW_VOH: # dolgo zavijanje, no drift
#			bolt.mass = 1
#			engine_rotation_speed = 0.5
#			accelaration_power = 32000
#			def_max_engine_power = 250#800#000
#			new_front_mass_bias = 0.5
#			bolt.angular_damp = 0
#			bolt.front_mass.linear_damp = 0
#			bolt.rear_mass.linear_damp = 10
#
##			bolt.angular_damp = 10
#			bolt.front_mass.angular_damp = 100
#			bolt.rear_mass.angular_damp = 10
#			max_engine_rotation_deg = 32

#		TURNING_MODE.DEFAULT:
#			mass_summ = bolt.bolt_profile["masa"]
#			engine_rotation_speed = bolt.bolt_profile["engine_rotation_speed"]
#			max_engine_rotation_deg = bolt.bolt_profile["max_engine_rotation_deg"]
#			accelaration_power = bolt.bolt_profile["accelaration_power"]
#			def_max_engine_power = bolt.bolt_profile["max_engine_power"]
#			#
#			new_front_mass_bias = bolt.bolt_profile["front_mass_bias"]
#			bolt.angular_damp = bolt.bolt_profile["ang_damp"]
#			bolt.front_mass.linear_damp = bolt.bolt_profile["lin_damp_front"]
#			bolt.rear_mass.linear_damp = bolt.bolt_profile["lin_damp_rear"]
#
#		TURNING_MODE.ORIG:
#			mass_summ = bolt.bolt_profile["masa"]
#			engine_rotation_speed = 0.1
#			max_engine_rotation_deg = 90
#			accelaration_power = 5#000
#			def_max_engine_power = 500 * 2#000
#			bolt.mass = 80 # 800 kil, front in rear teža se uporablja bolj za razmerje
#			bolt.angular_damp = 16 # regulacija ostrine zavijanja ... tudi driftanja
#			bolt.linear_damp = 2 # imam ga za omejitev slajdanja prvega kolesa
#			bolt.rear_mass.mass = 1
#			bolt.rear_mass.linear_damp = 3 # regulacija driftanja
#			bolt.rear_mass.angular_damp = -1 # 0 proj def
#			bolt.front_mass.mass = 1
#			bolt.front_mass.linear_damp = -1 # 0 proj def
#			bolt.front_mass.angular_damp = -1 # 0 proj def
