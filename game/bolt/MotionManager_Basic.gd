extends MotionManager


func _change_rotation_direction(new_rotation_direction: float):
	# za zavijanje lahko vplivam na karkoli, ker se ob vožnji naravnost vse reseta
	# če ne zavija je fizika celega bolta
	# če zavija se porazdeli glede na stil

	rotation_dir = new_rotation_direction
	set_default_parameters()

	if rotation_dir == 0:
		torque_on_bolt = 0
	else:
		if motion == MOTION.IDLE:
			rotation_motion = selected_idle_rotation
		else:
			rotation_motion = selected_rotation_motion

		#		printt("rotation_change ",rotation_dir, MOTION.keys()[motion], ROTATION_MOTION.keys()[rotation_motion])

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
			ROTATION_MOTION.SLIDE:
				#				force_on_bolt = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
				#				linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				bolt.angular_damp = 5 # da se ne vrti, če zavija
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()

	#	_print_bolt_data()
#
#
func set_default_parameters():

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
#
#
#func use_nitro():
#	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost
#
#	if not is_boosting:
#		is_boosting = true
#		Rfs.sound_manager.play_sfx("pickable_nitro")
#		var boosting_time: float = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]
#		engine_power_adon += Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
#		yield(get_tree().create_timer(boosting_time),"timeout")
#		engine_power_adon -= Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
#		is_boosting = false
#
#
#func _print_bolt_data():
#
#	printt("engine", max_engine_power, max_engine_rotation_deg, engine_rotation_speed)
#	printt("_bolt", bolt.mass, bolt.linear_damp, bolt.angular_damp)
#	printt("_front", bolt.front_mass.mass, bolt.front_mass.linear_damp, bolt.front_mass.angular_damp)
#	printt("_rear", bolt.rear_mass.mass, bolt.rear_mass.linear_damp, bolt.rear_mass.angular_damp)
#	printt("_torq", torque_on_bolt)
#
