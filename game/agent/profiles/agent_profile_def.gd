#tool
extends Resource

# zaenkrat ne jemlje iz profilov
export (float, 10, 1000, 0.5) var agent_max_engine_power: float = 500
export (float, 10, 1000, 0.5) var agent_mass: float = 100
export (float, -50, 50, 0.5) var ai_power_equlizer_addon: float = -10
export (float, 100, 300, 0.5) var fast_start_power_addon: float = 200
export (float, 1, 2, 0.05) var max_engine_power_rotation_adapt: float = 1.1

export (float, 0, 50, 0.5) var height: float = 10
export (float, 0, 100, 0.5) var elevation: float =  7
export (float, -1, 0, 0.05) var gas_usage: float =  -0.1 # per HSP?
export (float, -0.1, 0, 0.01) var gas_usage_idle: float = -0.05 # per HSP?
export (int, 0, 10) var ai_target_rank: float = 5
export (float, 0, 0.5) var on_hit_disabled_time: float = 2
export (float, 0, 0.5) var gas_tank_size: float = 200 # liters
export var group_weapons_by_type: bool = true
export (float, 0, 1, 0.05) var damage_engine_power_factor: float = 1 # v kolikšnem razmerju vpliva na mol, 0 pomeni, da ne vpliva
export (float, 0, 1, 0.01) var agent_health = 1


func _set_default_parameters(managed_agent: Agent):

	var motion_manager: MotionManager = managed_agent.motion_manager

	motion_manager.max_engine_rotation_deg = 45
	motion_manager.engine_rotation_speed = 0.1
	managed_agent.mass = agent_mass

	if motion_manager.is_ai:
		motion_manager.max_engine_power = agent_max_engine_power + ai_power_equlizer_addon
		managed_agent.angular_damp = 16
		managed_agent.linear_damp = 1
	else:
		motion_manager.max_engine_power = agent_max_engine_power
		managed_agent.angular_damp = 1
		managed_agent.linear_damp = 1
		managed_agent.front_mass.mass = motion_manager.AKA_ZERO_MASS
		managed_agent.rear_mass.mass = motion_manager.AKA_ZERO_MASS
		managed_agent.front_mass.linear_damp = 0
		managed_agent.rear_mass.linear_damp = 0


func _set_motion_parameters(agent, new_motion):
#	print("resource motion", motion_manager.MOTION.keys()[new_motion])

		var motion_manager: MotionManager = agent.motion_manager

		motion_manager.torque_on_agent = 0
		var new_rotation_direction: int = 0

		match new_motion:
			motion_manager.MOTION.FWD:
				new_rotation_direction = 0
			motion_manager.MOTION.FWD_LEFT:
				new_rotation_direction = -1
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				agent.angular_damp = 14
				agent.front_mass.linear_damp = 0
				agent.rear_mass.linear_damp = 4
			motion_manager.MOTION.FWD_RIGHT:
				new_rotation_direction = 1
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				agent.angular_damp = 14
				agent.front_mass.linear_damp = 0
				agent.rear_mass.linear_damp = 4
			motion_manager.MOTION.REV:
#				rotating = false
				new_rotation_direction = 0
			motion_manager.MOTION.REV_LEFT:
				new_rotation_direction = -1
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				agent.angular_damp = 14
				agent.front_mass.linear_damp = 4
				agent.rear_mass.linear_damp = 0
			motion_manager.MOTION.REV_RIGHT:
				new_rotation_direction = 1
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				agent.angular_damp = 14
				agent.front_mass.linear_damp = 4
				agent.rear_mass.linear_damp = 0
			motion_manager.MOTION.IDLE:
				new_rotation_direction = 0
				agent.angular_damp = 3
				# _temp tole spodaj je pomoje oveč... testiraj
				# func _reset_motion():
				# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v agent "v igri"
				#				agent.front_mass.set_applied_force(Vector2.ZERO)
				#				agent.front_mass.set_applied_torque(0)
				#				agent.rear_mass.set_applied_force(Vector2.ZERO)
				#				agent.rear_mass.set_applied_torque(0)
			motion_manager.MOTION.IDLE_LEFT:
				new_rotation_direction = -1
				motion_manager.rotation_motion = motion_manager.selected_idle_rotation
				agent.angular_damp = 3
			motion_manager.MOTION.IDLE_RIGHT:
				new_rotation_direction = 1
				motion_manager.rotation_motion = motion_manager.selected_idle_rotation
				agent.angular_damp = 3
			motion_manager.MOTION.DISSARAY:
				pass # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart

#		if not new_rotation_direction == rotation_dir:
		motion_manager.rotation_dir = new_rotation_direction

		if motion_manager.rotation_dir == 0:
			_set_default_parameters(agent)
		else:
			_set_rotation_parameters(agent)


func _set_rotation_parameters(managed_agent: Agent, is_reverse: bool = false):
#	printt("rotation on resource", motion_manager.MOTION.keys()[motion_manager.motion])

	var motion_manager: MotionManager = managed_agent.motion_manager
	var rotation_motion: int = motion_manager.rotation_motion

	var front_mass_bias: float = 0.5
	match rotation_motion:
		motion_manager.ROTATION_MOTION.DEFAULT:
			motion_manager.max_engine_rotation_deg = 35
			managed_agent.angular_damp = 10
			var split_agent_mass = agent_mass / 2
			managed_agent.mass = split_agent_mass
			managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
			managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
			#			if is_reverse:
			#				managed_agent.front_mass.linear_damp = 0
			#				managed_agent.rear_mass.linear_damp = 4
			#			else:
			#			managed_agent.front_mass.linear_damp = 0
			#			managed_agent.rear_mass.linear_damp = 4
		motion_manager.ROTATION_MOTION.DRIFT:
			motion_manager.max_engine_rotation_deg = 32
			managed_agent.front_mass.linear_damp = 1
			managed_agent.rear_mass.linear_damp = 6
			var split_agent_mass = agent_mass / 2
			managed_agent.mass = split_agent_mass
			managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
			managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
		motion_manager.ROTATION_MOTION.SPIN:
			managed_agent.angular_damp = 4 # 16
			motion_manager.torque_on_agent = 9300000 * motion_manager.rotation_dir
			motion_manager.max_engine_rotation_deg = 90
		motion_manager.ROTATION_MOTION.SLIDE:
			#				force_on_agent = Vector2.DOWN.rotated(managed_agent.rotation) * rotation_dir
			#				linear_damp = managed_agent.agent_profile["idle_lin_damp"] # da ne izgubi hitrosti
			managed_agent.angular_damp = 5 # da se ne vrti, če zavija

