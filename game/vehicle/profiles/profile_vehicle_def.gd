extends Resource


export (float, 10, 1000, 0.5) var start_max_engine_power: float = 500
export (float, 10, 1000, 0.5) var masa: float = 100
export (float, -50, 50, 0.5) var ai_power_equlizer_addon: float = -10
export (float, 100, 300, 0.5) var fast_start_power_addon: float = 200 # rabi driver
export (float, 1, 2, 0.05) var max_engine_power_rotation_adapt: float = 1.1

export (float, 0, 50, 0.5) var height: float = 10
export (float, 0, 100, 0.5) var driving_elevation: float =  7
export (float, -1, 0, 0.05) var gas_usage: float =  -0.1 # per HSP?
export (float, -0.1, 0, 0.01) var gas_usage_idle: float = -0.05 # per HSP?
export (float, 0, 0.5) var on_hit_disabled_time: float = 2
export (float, 0, 0.5) var gas_tank_size: float = 200 # liters

# neu
export var group_equipment_by_type: bool = true
export (float, 0, 1, 0.1) var heal_rate: float = 0.5
export (float, 0, 1, 0.1) var health_effect_factor: float = 1

# kasneje se tudi seta glede na opremo
export var front_mass_bias: float = 0.5
export var mass_manipulate_part: float = 0.5


func _set_default_parameters(managed_vehicle: Vehicle):

	var motion_manager: Node2D = managed_vehicle.motion_manager
	motion_manager.max_engine_rotation_deg = 45
	motion_manager.engine_rotation_speed = 0.1
	managed_vehicle.mass = masa
	managed_vehicle.front_mass.mass = motion_manager.AKA_ZERO_MASS
	managed_vehicle.rear_mass.mass = motion_manager.AKA_ZERO_MASS
	managed_vehicle.linear_damp = 1
	managed_vehicle.front_mass.linear_damp = 0
	managed_vehicle.rear_mass.linear_damp = 0

	if managed_vehicle.is_in_group(Refs.group_ai):
		motion_manager.max_engine_power = start_max_engine_power + ai_power_equlizer_addon
		managed_vehicle.angular_damp = 16
	else:
		motion_manager.max_engine_power = start_max_engine_power
		managed_vehicle.angular_damp = 14


func _set_motion_parameters(vehicle: Vehicle, new_motion: int):
#	print("resource motion", motion_manager.MOTION.keys()[new_motion])

		var motion_manager: Node2D = vehicle.motion_manager
#		printt("motion", motion_manager.MOTION.keys()[new_motion])

		motion_manager.torque_on_vehicle = 0

		_set_default_parameters(vehicle)

		match new_motion:
			motion_manager.MOTION.FWD, motion_manager.MOTION.REV:
				#				_set_default_parameters(vehicle)
				pass
			motion_manager.MOTION.FWD_LEFT:
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				vehicle.angular_damp = 14
				vehicle.front_mass.linear_damp = 0
				vehicle.rear_mass.linear_damp = 4
			motion_manager.MOTION.FWD_RIGHT:
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				vehicle.angular_damp = 14
				vehicle.front_mass.linear_damp = 0
				vehicle.rear_mass.linear_damp = 4
			motion_manager.MOTION.REV_LEFT:
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				vehicle.angular_damp = 14
				vehicle.front_mass.linear_damp = 4
				vehicle.rear_mass.linear_damp = 0
			motion_manager.MOTION.REV_RIGHT:
				motion_manager.rotation_motion = motion_manager.selected_rotation_motion
				vehicle.angular_damp = 14
				vehicle.front_mass.linear_damp = 4
				vehicle.rear_mass.linear_damp = 0
			motion_manager.MOTION.IDLE:
				vehicle.angular_damp = 1
			motion_manager.MOTION.IDLE_LEFT:
				motion_manager.rotation_motion = motion_manager.selected_idle_rotation
				vehicle.angular_damp = 3
			motion_manager.MOTION.IDLE_RIGHT:
				motion_manager.rotation_motion = motion_manager.selected_idle_rotation
				vehicle.angular_damp = 3
			motion_manager.MOTION.DISSARAY:
				pass # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart

		if not motion_manager.rotation_dir == 0:
			_set_rotation_parameters(vehicle)


func _set_rotation_parameters(managed_vehicle: Vehicle, is_reverse: bool = false):
#	printt("rotation on resource", motion_manager.MOTION.keys()[motion_manager.motion])

	var motion_manager: Node2D = managed_vehicle.motion_manager
	var rotation_motion: int = motion_manager.rotation_motion

	match rotation_motion:
		motion_manager.ROTATION_MOTION.DEFAULT:
			motion_manager.max_engine_rotation_deg = 35
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
		motion_manager.ROTATION_MOTION.DRIFT:
			motion_manager.max_engine_rotation_deg = 32
			managed_vehicle.front_mass.linear_damp = 1
			managed_vehicle.rear_mass.linear_damp = 6
			# masa vehicla
			var manipulate_part_mass: float = managed_vehicle.mass * mass_manipulate_part
			managed_vehicle.mass -= manipulate_part_mass
			managed_vehicle.front_mass.mass = manipulate_part_mass * front_mass_bias
			managed_vehicle.rear_mass.mass = manipulate_part_mass * (1 - front_mass_bias)
		motion_manager.ROTATION_MOTION.SPIN:
			managed_vehicle.angular_damp = 4 # 16
			motion_manager.torque_on_vehicle = 9300000 * motion_manager.rotation_dir
			motion_manager.max_engine_rotation_deg = 90
		motion_manager.ROTATION_MOTION.SLIDE:
			#				force_on_vehicle = Vector2.DOWN.rotated(managed_vehicle.rotation) * rotation_dir
			#				linear_damp = managed_vehicle.vehicle_profile["idle_lin_damp"] # da ne izgubi hitrosti
			managed_vehicle.angular_damp = 5 # da se ne vrti, če zavija

