extends MotionManager


#var agent_type: int = Pfs.AGENT.BASIC
#
## zaenkrat ne jemlje iz profilov
#var agent_max_engine_power: float = 500
#var agent_mass: float = 100
#var ai_power_equlizer_addon: float = -10
#var fast_start_power_addon: float = 200
#var max_engine_power_rotation_adapt: float = 1.1
#
#
#func _set_default_parameters():
#
#	agent_motion_profile._set_default_parameters(managed_agent)
#	return
#
#	max_engine_rotation_deg = 45
#	engine_rotation_speed = 0.1
#	managed_agent.mass = agent_mass
#
#	if is_ai:
#		max_engine_power = agent_max_engine_power + ai_power_equlizer_addon
#		managed_agent.angular_damp = 16
#		managed_agent.linear_damp = 1
#	else:
#		max_engine_power = agent_max_engine_power
#		managed_agent.angular_damp = 1
#		managed_agent.linear_damp = 1
#		managed_agent.front_mass.mass = AKA_ZERO_MASS
#		managed_agent.rear_mass.mass = AKA_ZERO_MASS
#		managed_agent.front_mass.linear_damp = 0
#		managed_agent.rear_mass.linear_damp = 0
#
#
#func _change_motion(new_motion):
#
#
#	if not motion == new_motion:
#
#		motion = new_motion
#		agent_motion_profile._set_motion_parameters(managed_agent, motion)
#		return
##		_set_default_parameters()
#		torque_on_agent = 0
#
#		motion = new_motion
#		printt("motion", MOTION.keys()[motion])
##		var new_rotation_direction: int = 0
#
#
#		var rotating: bool = true
#		match motion:
#			MOTION.FWD:
##				rotating = false
#				rotation_dir = 0
#			MOTION.FWD_LEFT:
#				managed_agent.angular_damp = 14
#				rotation_dir = -1
#				rotation_motion = selected_rotation_motion
#				managed_agent.front_mass.linear_damp = 0
#				managed_agent.rear_mass.linear_damp = 4
#			MOTION.FWD_RIGHT:
#				managed_agent.angular_damp = 14
#				rotation_dir = 1
#				rotation_motion = selected_rotation_motion
#				managed_agent.front_mass.linear_damp = 0
#				managed_agent.rear_mass.linear_damp = 4
#			MOTION.REV:
##				rotating = false
#				rotation_dir = 0
#			MOTION.REV_LEFT:
#				managed_agent.angular_damp = 14
#				rotation_dir = -1
#				rotation_motion = selected_rotation_motion
#				managed_agent.front_mass.linear_damp = 4
#				managed_agent.rear_mass.linear_damp = 0
#			MOTION.REV_RIGHT:
#				managed_agent.angular_damp = 14
#				rotation_dir = 1
#				rotation_motion = selected_rotation_motion
#				managed_agent.front_mass.linear_damp = 4
#				managed_agent.rear_mass.linear_damp = 0
#			MOTION.IDLE:
##				rotating = false
#				managed_agent.angular_damp = 3
#				rotation_dir = 0
#				# _temp tole spodaj je pomoje oveč... testiraj
#				# func _reset_motion():
#				# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v agent "v igri"
#				managed_agent.front_mass.set_applied_force(Vector2.ZERO)
#				managed_agent.front_mass.set_applied_torque(0)
#				managed_agent.rear_mass.set_applied_force(Vector2.ZERO)
#				managed_agent.rear_mass.set_applied_torque(0)
##				for thrust in managed_agent.engines.all_thrusts:
##					thrust.rotation = lerp_angle(thrust.rotation, 0, 0.1)
##					thrust.stop_fx()
#			MOTION.IDLE_LEFT:
#				managed_agent.angular_damp = 3
#				rotation_dir = -1
#				rotation_motion = selected_idle_rotation
#			MOTION.IDLE_RIGHT:
#				managed_agent.angular_damp = 3
#				rotation_dir = 1
#				rotation_motion = selected_idle_rotation
#			MOTION.DISSARAY:
#				pass # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart
#
##		if not new_rotation_direction == rotation_dir:
#		if rotation_dir == 0:
#			_set_default_parameters()
#		else:
#			_set_rotation_parameters(rotation_dir)
#
#
#func _set_rotation_parameters(new_rotation_direction: float, is_reverse: bool = false):
#
#	agent_motion_profile._set_rotation_parameters(managed_agent)
#	return
#
#	var front_mass_bias: float = 0.5
#	match rotation_motion:
#		ROTATION_MOTION.DEFAULT:
#			max_engine_rotation_deg = 35
#			managed_agent.angular_damp = 10
#			#			if is_reverse:
#			#				managed_agent.front_mass.linear_damp = 0
#			#				managed_agent.rear_mass.linear_damp = 4
#			#			else:
#			#			managed_agent.front_mass.linear_damp = 0
#			#			managed_agent.rear_mass.linear_damp = 4
#			var split_agent_mass = agent_mass / 2
#			managed_agent.mass = split_agent_mass
#			managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
#			managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
#		ROTATION_MOTION.DRIFT:
#			max_engine_rotation_deg = 32
#			managed_agent.front_mass.linear_damp = 1
#			managed_agent.rear_mass.linear_damp = 6
#			var split_agent_mass = agent_mass / 2
#			managed_agent.mass = split_agent_mass
#			managed_agent.front_mass.mass = split_agent_mass * front_mass_bias
#			managed_agent.rear_mass.mass = split_agent_mass * (1 - front_mass_bias)
#		ROTATION_MOTION.SPIN:
#			managed_agent.angular_damp = 4 # 16
#			torque_on_agent = 9300000 * rotation_dir
#			max_engine_rotation_deg = 90
#		ROTATION_MOTION.SLIDE:
#			#				force_on_agent = Vector2.DOWN.rotated(managed_agent.rotation) * rotation_dir
#			#				linear_damp = managed_agent.agent_profile["idle_lin_damp"] # da ne izgubi hitrosti
#			managed_agent.angular_damp = 5 # da se ne vrti, če zavija
#			for thrust in managed_agent.engines.all_thrusts:
#				thrust.start_fx()
