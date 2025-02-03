extends MotionManager


var bolt_type: int = Pfs.BOLTS.BASIC

# zaenkrat ne jemlje iz profilov
var bolt_max_engine_power: float = 500
var bolt_mass: float = 100
var ai_power_equlizer_addon: float = -10
var fast_start_power_addon: float = 200


func _set_default_parameters():

	max_engine_rotation_deg = 45
	engine_rotation_speed = 0.1
	bolt.mass = bolt_mass

	if is_ai:
		max_engine_power = bolt_max_engine_power + ai_power_equlizer_addon
		bolt.angular_damp = 16
		bolt.linear_damp = 1
	else:
		max_engine_power = bolt_max_engine_power
		bolt.angular_damp = 1
		bolt.linear_damp = 1
		bolt.front_mass.mass = AKA_ZERO_MASS
		bolt.rear_mass.mass = AKA_ZERO_MASS
		bolt.front_mass.linear_damp = 0
		bolt.rear_mass.linear_damp = 0


func _change_rotation_direction(new_rotation_direction: float):

	rotation_dir = new_rotation_direction

	_set_default_parameters()
	torque_on_bolt = 0

	if rotation_dir == 0:
		if motion == MOTION.IDLE: # ang_damp, če pridem iz rotacije v idle
			bolt.angular_damp = 3
		else: # ang_damp, če pridem iz rotacije v vožnjo naravnost ... smerni popravki
			bolt.angular_damp = 14
	else:
		if motion == MOTION.IDLE:
			rotation_motion = selected_idle_rotation
		else:
			rotation_motion = selected_rotation_motion

		var front_mass_bias: float = 0.5
		match rotation_motion:
			ROTATION_MOTION.DEFAULT:
				max_engine_rotation_deg = 35
				bolt.angular_damp = 10
				bolt.front_mass.linear_damp = 0
				bolt.rear_mass.linear_damp = 4
				var split_bolt_mass = bolt_mass / 2
				bolt.mass = split_bolt_mass
				bolt.front_mass.mass = split_bolt_mass * front_mass_bias
				bolt.rear_mass.mass = split_bolt_mass * (1 - front_mass_bias)
			ROTATION_MOTION.DRIFT:
				max_engine_rotation_deg = 32
				bolt.front_mass.linear_damp = 1
				bolt.rear_mass.linear_damp = 6
				var split_bolt_mass = bolt_mass / 2
				bolt.mass = split_bolt_mass
				bolt.front_mass.mass = split_bolt_mass * front_mass_bias
				bolt.rear_mass.mass = split_bolt_mass * (1 - front_mass_bias)
			ROTATION_MOTION.SPIN:
				bolt.angular_damp = 4 # 16
				torque_on_bolt = 9300000 * rotation_dir
				max_engine_rotation_deg = 90
			ROTATION_MOTION.SLIDE:
				#				force_on_bolt = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
				#				linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				bolt.angular_damp = 5 # da se ne vrti, če zavija
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()

	#	_print_bolt_data()
