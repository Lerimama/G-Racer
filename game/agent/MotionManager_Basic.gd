extends MotionManager


var agent_type: int = Pfs.AGENT.BASIC

# zaenkrat ne jemlje iz profilov
var agent_max_engine_power: float = 500
var agent_mass: float = 100
var ai_power_equlizer_addon: float = -10
var fast_start_power_addon: float = 200


func _set_default_parameters():

	max_engine_rotation_deg = 45
	engine_rotation_speed = 0.1
	managed_agent.mass = agent_mass

	if is_ai:
		max_engine_power = agent_max_engine_power + ai_power_equlizer_addon
		managed_agent.angular_damp = 16
		managed_agent.linear_damp = 1
	else:
		max_engine_power = agent_max_engine_power
		managed_agent.angular_damp = 1
		managed_agent.linear_damp = 1
		managed_agent.front_mass.mass = AKA_ZERO_MASS
		managed_agent.rear_mass.mass = AKA_ZERO_MASS
		managed_agent.front_mass.linear_damp = 0
		managed_agent.rear_mass.linear_damp = 0


func _change_rotation_direction(new_rotation_direction: float):

	rotation_dir = new_rotation_direction

	_set_default_parameters()
	torque_on_agent = 0

	if rotation_dir == 0:
		if motion == MOTION.IDLE: # ang_damp, če pridem iz rotacije v idle
			managed_agent.angular_damp = 3
		else: # ang_damp, če pridem iz rotacije v vožnjo naravnost ... smerni popravki
			managed_agent.angular_damp = 14
	else:
		if motion == MOTION.IDLE:
			rotation_motion = selected_idle_rotation
		else:
			rotation_motion = selected_rotation_motion

		var front_mass_bias: float = 0.5
		match rotation_motion:
			ROTATION_MOTION.DEFAULT:
				max_engine_rotation_deg = 35
				managed_agent.angular_damp = 10
				managed_agent.front_mass.linear_damp = 0
				managed_agent.rear_mass.linear_damp = 4
				var split_agent_mass = agent_mass / 2
				managed_agent.mass = split_agent_mass
				managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
				managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
			ROTATION_MOTION.DRIFT:
				max_engine_rotation_deg = 32
				managed_agent.front_mass.linear_damp = 1
				managed_agent.rear_mass.linear_damp = 6
				var split_agent_mass = agent_mass / 2
				managed_agent.mass = split_agent_mass
				managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
				managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
			ROTATION_MOTION.SPIN:
				managed_agent.angular_damp = 4 # 16
				torque_on_agent = 9300000 * rotation_dir
				max_engine_rotation_deg = 90
			ROTATION_MOTION.SLIDE:
				#				force_on_agent = Vector2.DOWN.rotated(managed_agent.rotation) * rotation_dir
				#				linear_damp = managed_agent.agent_profile["idle_lin_damp"] # da ne izgubi hitrosti
				managed_agent.angular_damp = 5 # da se ne vrti, če zavija
				for thrust in managed_agent.engines.all_thrusts:
					thrust.start_fx()

	#	_print_agent_data()
