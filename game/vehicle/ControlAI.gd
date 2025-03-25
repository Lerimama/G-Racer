extends Node2D


#signal weapon_triggered

enum AI_STATE {OFF, ON_TRACK, SEARCH, FOLLOW, HUNT, REACH_GOAL, MOUSE_CLICK, BATTLE} # ai je možgan (driver in ne vehicle
var ai_state: int = AI_STATE.OFF setget _change_ai_state

# seta spawner
var vehicle: Vehicle # temp ... Vehicle class
var controller_type: int

# navigacija
var ai_target: Node2D = null
var ai_navigation_line: Line2D
onready var navigation_agent = $NavigationAgent2D
var level_navigation: NavigationPolygonInstance # poda spawner

# motion
var motion_manager: Node2D
var ai_navigation_target_range: Array = [600, 800] # min dist 0 pomeni iskanje najbližja možna
var braking_velocity: Vector2
var breaking_distance_factor: float = 0.5 # kako daleč je ovira preden bremza
var braking_power_factor: float = 0.7 # množenje s hitrostjo ... male spremembe
var breaking_factor_near: float = 0.95
var breaking_factor_keep: float = 0.68 # nežno se ustavi
var engine_power_factor_keep: float = 0
var engine_power_factor_search: float = 0.5
var random_start_range: Array = [0.1, 1]

# vision
onready var vision: Node2D = $Vision
var keep_distance: float = 500
var near_distance: float = 800

# ai targets
var goals_to_reach: Array = [] # lovi jih v zaporedju, ko so ujeti se zbrišejo, če obstaja cilj je na koncu
var search_target_reached: bool = false
onready var target_ray: RayCast2D = $TargetRay # čekira "locked on" ... col_layer ai targets, vision brakers > bodies, areas
onready var battler: Node2D = $Battler

# debug
var current_mouse_follow_point: Vector2 = Vector2.ZERO
onready var target_line: Line2D = $TargetLine
onready var force_direction_line: Line2D = $DirectionLine
onready var debug_label: Label = $__Label


func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no0"): # idle
		self.ai_state = AI_STATE.OFF
		#	if Input.is_action_just_pressed("no1"): # idle
		#		self.ai_state = AI_STATE.ON_TRACK
		#	if Input.is_action_just_pressed("no2"): # race
		#		self.ai_state = AI_STATE.SEARCH
		#	if Input.is_action_pressed("no3"):
		#		wanted_speed = 900
		#	if Input.is_action_just_pressed("no4"): # follow leader
		##		wanted_speed = -1
		#		motion_manager.boost_vehicle()

		#	elif Input.is_action_just_pressed("left_click"): # follow leader
		#		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(global_position, level_navigation.get_local_mouse_position())
		#		ai_target = Mets.spawn_indikator(nav_path_points[0], Color(Color.blue, 0), 0, Refs.node_creation_parent)
		#		navigation_agent.set_target_location(nav_path_points[0])
		#		ai_state = AI_STATE.MOUSE_CLICK
		#		current_mouse_follow_point = nav_path_points[nav_path_points.size()-1]


func _ready() -> void:

	randomize()
	vehicle = get_parent()
	battler.vehicle = get_parent()

	vehicle.add_to_group(Refs.group_ai)
	vehicle.add_to_group(Refs.group_drivers)

	ai_navigation_line = Line2D.new()
	Refs.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = Color.red
	ai_navigation_line.z_index = 10

	# ray exceptions
	battler.scanning_ray.add_exception(vehicle)
	target_ray.add_exception(vehicle)
	for ray in vision.get_children():
		ray.add_exception(vehicle)


func _physics_process(delta: float) -> void:


	if vehicle.is_active:

		# state from ai_target
		if not ai_state == AI_STATE.OFF:
			# dissaray
			if motion_manager.motion == motion_manager.MOTION.DISSARAY:
				self.ai_state = AI_STATE.OFF
			# SREACH > ai target
			else:
				if not ai_target:
					self.ai_state = AI_STATE.SEARCH
				elif not is_instance_valid(ai_target):
					self.ai_state = AI_STATE.SEARCH
				elif "is_active" in ai_target and not ai_target.is_active:
					self.ai_state = AI_STATE.SEARCH

		_state_machine(delta)

		var vector_to_target: Vector2 = Vector2.ZERO
		if not Input.is_action_pressed("no1") and not Input.is_action_pressed("no2"): # debug ai on rotation

			# target position
			if ai_state == AI_STATE.ON_TRACK:
				vector_to_target = _get_tracking_position(ai_target) - global_position
			elif ai_target:
				vector_to_target = ai_target.global_position - global_position

			# force on vehicle
			# player ima tole v vehiclu ... po tajmingu je tukaj malo netočno, ampakse ne opazi
			motion_manager.force_rotation = Vector2.RIGHT.angle_to_point(- vector_to_target)
			motion_manager.force_on_vehicle = Vector2.RIGHT.rotated(motion_manager.force_rotation) * motion_manager._accelarate_to_engine_power()
			#			motion_manager.current_engine_power = motion_manager.max_engine_power

		# drive as player ---------------------------------------------------------------------------
		elif Input.is_action_pressed("no1"):
			_drive_as_player(true)
		elif Input.is_action_pressed("no2"):
			_drive_as_player()

		if not _update_vision() == null:
			vehicle.set_linear_velocity(braking_velocity)


		# DEBUG ------------------------------------------------------------------------------------------

		# label
		debug_label.set_as_toplevel(true)
		debug_label.text =  "rot dir: " + str(motion_manager.rotation_dir)
		debug_label.hide()

		# debug line
		if ai_target and is_instance_valid(ai_target):
			target_line.default_color = Color.green
		else:
			target_line.default_color = Color.red
		target_line.set_point_position(1, vector_to_target.rotated(- vehicle.global_rotation))


func _update_vision():
	# zazanava tudi surrounded
	# stranski so samo za opredeljvanje smeri
	# sprednji uravnava hitrost

	var side_rays_length_extension: float = 1000 # _temp extension

	var vision_ray_center: RayCast2D = $Vision/VisionRayCenter
	var vision_ray_left: RayCast2D = $Vision/VisionRayLeft
	var vision_ray_right: RayCast2D = $Vision/VisionRayRight

	var collision_distances: Array = []
	var nowhere_to_go: bool = false

	vision_ray_center.cast_to.x = vehicle.velocity.length() * breaking_distance_factor # zmeraj dolg kot je dolga hitrost
	if vision_ray_center.is_colliding():
		# center preverja distanco
		var distance_to_collision: float = vision_ray_center.global_position.distance_to(vision_ray_center.get_collision_point())
		collision_distances.append(distance_to_collision)
		# stranici preverjata distanco
		for side_ray in [vision_ray_left, vision_ray_right]:
			side_ray.cast_to.x = distance_to_collision + side_rays_length_extension
			var distance_to_side_collision: float = side_rays_length_extension # OPT ... fejk da jo izbere .. 0 je blo včasih
			if side_ray.is_colliding():
				distance_to_side_collision = side_ray.global_position.distance_to(side_ray.get_collision_point())
			collision_distances.append(distance_to_side_collision)

		# preverim katera je najdlje in usmerim raketo v to smer
		var max_collision_distance_index: int = collision_distances.find(collision_distances.max())
		var max_collision_distance_position: Vector2 = Vector2.ZERO
		#		printt ("dist", collision_distances, collision_distances.find(collision_distances.max()))
		var rotation_adapt: float = 0
		match max_collision_distance_index:
			0: # center
				nowhere_to_go = true
				braking_velocity = vehicle.velocity * breaking_factor_keep
				# ... dodaš rikverc
				#				max_collision_distance_position = vision_ray_left.get_collision_point()
				max_collision_distance_position = global_position
				#				printt("going nowhere")
			1: # left
				max_collision_distance_position = vision_ray_left.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
#				Mets.spawn_indikator(max_collision_distance_position, Color.pink)
				braking_velocity = vehicle.velocity * braking_power_factor
				rotation_adapt = -1
				#				printt("turning left")
			2: # right
				max_collision_distance_position = vision_ray_right.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
				braking_velocity = vehicle.velocity * braking_power_factor
				rotation_adapt = 1
#				Mets.spawn_indikator(max_collision_distance_position, Color.orange)
				#				printerr("turning right")

		return max_collision_distance_position
	else:
		return


func _state_machine(delta: float):
#	printt ("ai_state: ", AI_STATE.keys()[ai_state], motion_manager.current_engine_power)

	match ai_state:

		AI_STATE.OFF:
			pass

		AI_STATE.ON_TRACK: # šiba po najbližji poti do tarče
			if not navigation_agent.get_target_location() == ai_target.global_position:
				var driver_tracker_position: Vector2 = _get_tracking_position(ai_target)
				navigation_agent.set_target_location(driver_tracker_position)
			if not _adjust_power_speed_limit():
				motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.SEARCH: # vozi po točkah navigacije in išče novo tarčo, dokler je ne najde
#			var new_ai_target: Node2D = _get_better_targets(ai_target)
			var new_ai_target: Node2D = battler._get_better_targets(ai_target)
			# če je našel legitimno tarčo, ga dam v hunt
			if not new_ai_target == ai_target:
				ai_target = new_ai_target
				self.ai_state = AI_STATE.HUNT
			# če ni tarče in je dosegel nav target setam novo random točko
			elif search_target_reached:
				self.ai_state = AI_STATE.SEARCH
			motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.FOLLOW: # sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			ai_target = battler._get_better_targets(ai_target)
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
			_react_to_target(ai_target)
			motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.HUNT: # pobere tarčo, ki jo je videl ... ne izgubi pogleda, ne išče boljših
			# preverjam za boljšo tarčo
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
			_react_to_target(ai_target)
			motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.REACH_GOAL: # šiba do cilja po najbližji poti
			if not navigation_agent.get_target_location() == ai_target.global_position:
				navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.current_engine_power = motion_manager.max_engine_power
			_react_to_target(ai_target)

		AI_STATE.MOUSE_CLICK:
			navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.current_engine_power = motion_manager.max_engine_power / 3
			_react_to_target(ai_target)

		AI_STATE.BATTLE:
			battle_with_target(ai_target)


func _change_ai_state(new_ai_state: int):
#	printt ("_change_ai_state", AI_STATE.keys()[new_ai_state])

	battler.scanning_ray.enabled = false
	target_ray.enabled = false

	match new_ai_state:
		AI_STATE.OFF:
			ai_target = null
			motion_manager.motion = motion_manager.MOTION.IDLE
		AI_STATE.ON_TRACK:
			ai_target = vehicle.driver_tracker
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.SEARCH:
			search_target_reached = false
			battler.scanning_ray.enabled = true
			ai_target = level_navigation.nav_position_target
#			var nav_position_target: Node2D = _get_nav_position_target(global_position, ai_navigation_target_range)
			var nav_position_target: Node2D = battler._get_nav_position_target(global_position, ai_navigation_target_range)
			navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.FOLLOW:
			# ai_target seta state mašina
			target_ray.enabled = true
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.HUNT:
			# ai_target seta state mašina
			target_ray.enabled = true
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.REACH_GOAL:
			if not goals_to_reach.empty():
				ai_target = goals_to_reach[0]
			# po pobranju novi ai_target postane next goal
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.MOUSE_CLICK:
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.BATTLE:
#			motion_manager.motion = motion_manager.MOTION.FWD
			pass

	ai_state = new_ai_state


func react_on_hit(hit_owner: Node2D):

	ai_target = hit_owner
	self.ai_state = AI_STATE.BATTLE


func battle_with_target(battle_target: Node2D):

	# najprej target ray preveri, če ga vidi
	var any_collider = Mets.get_directed_raycast_collision(target_ray, battle_target.global_position)
	var target_in_sight: bool = false
	if any_collider and any_collider == battle_target and is_instance_valid(battle_target):
		target_in_sight = true

	var shooting_distance: float = 2000
	if target_in_sight:
		if global_position.distance_to(battle_target.global_position) > shooting_distance:
			motion_manager.current_engine_power = motion_manager.max_engine_power / 4
			motion_manager.motion = motion_manager.MOTION.FWD
		else:
			motion_manager.motion = motion_manager.MOTION.IDLE
			battler.use_selected_item()


func _react_to_target(react_target: Node2D, keep_on_distance: bool = false, be_aggressive: bool = false):
	# keep_on_distance - ustavi na distanci in jo vzdržuje
	# aggresive - posešuje do tarče

	# debug
	#	keep_distance = 500
	#	near_distance = 800
	#	keep_on_distance = true
	#	be_aggressive = false

	var any_collider = Mets.get_directed_raycast_collision(target_ray, react_target.global_position)

	var target_in_sight: bool = false
	if any_collider and any_collider == react_target and is_instance_valid(react_target):
	#	if any_collider and any_collider == react_target and not react_target.is_queued_for_deletion():
		target_in_sight = true

	if target_in_sight:
		var target_closeup_breaking_factor: float = 1
		var distance_to_target = global_position.distance_to(react_target.global_position)
		if distance_to_target < keep_distance:
			if keep_on_distance: # ustavi tik pred tarčo
				target_closeup_breaking_factor = breaking_factor_keep
				motion_manager.current_engine_power = motion_manager.max_engine_power * engine_power_factor_keep
			elif be_aggressive: # fuuul power čez tarčo
				motion_manager.current_engine_power = motion_manager.max_engine_power
			else: # spusti gasa čez tarčo
				motion_manager.current_engine_power = 0
			motion_manager.current_engine_power = 0
		elif distance_to_target < near_distance:
			if be_aggressive: # pospešuje proti tarči
				motion_manager.current_engine_power = motion_manager.max_engine_power
				motion_manager.boost_vehicle()
			else: # upočasnuje proti tarči
				target_closeup_breaking_factor = breaking_factor_near
		else:
			motion_manager.current_engine_power = motion_manager.max_engine_power
		braking_velocity = vehicle.velocity * target_closeup_breaking_factor
		vehicle.set_linear_velocity(braking_velocity)
	else:
		# če izgubi pogled na tarčo, še zmeraj v tistem trenutku videl
		navigation_agent.set_target_location(global_position)


func _get_tracking_position(position_tracker: PathFollow2D):
	# tracker offset je vehilu najbližja točka na liniji
	# križanje ali bližina dveh delov krivulje povzroči preskok trackerja
	# ...
	# zgleda da je križanje po defaultu že okej, torej pedenam samo za bližino
	# na bližino še vedno preskoči, kar je problem samo v izjemnih primerih level designa
	# ... mogoče včasih celo hočeš, da preskoči

	var track_prediction_limit: int = 150
	var target_total_offset: float

	# offset mora rast ali padat z določeno omejitvijo, če preskoči +/- limito uporabim prev_tracker offset
	# ... nisem zihr, če vpliva ... mogoče bolje na unit_offset?
	if abs(position_tracker.offset - prev_tracker_offset) < track_prediction_limit:
		target_total_offset = position_tracker.offset + track_target_prediction
		prev_tracker_offset = position_tracker.offset
	else:
		#		printt("NOT REGULAR", prev_tracker_offset)
		target_total_offset = prev_tracker_offset + track_target_prediction
		prev_tracker_offset = position_tracker.offset

	var driver_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	var point_global_position: Vector2 = driver_tracker_curve.interpolate_baked(target_total_offset)

	return point_global_position


func on_goal_reached(goal_reached: Node2D, level_finish_line: Node2D):

	goals_to_reach.erase(goal_reached)
	if goals_to_reach.empty():
		if level_finish_line.is_enabled:
			ai_target = level_finish_line
		else:
			self.ai_state = AI_STATE.OFF
	else:
		ai_target = goals_to_reach.front()


# SIGNALI ------------------------------------------------------------------------------------------------


func on_game_start(game_level: Node2D): # od GMja

	# random start
	randomize()
	var random_start_delay: float = rand_range(random_start_range[0], random_start_range[1])
	yield(get_tree().create_timer(random_start_delay), "timeout")

	# RACING_TRACK
	if vehicle.driver_tracker:
		self.ai_state = AI_STATE.ON_TRACK
	# RACING_GOALS, BATTLE_GOALS
	elif not game_level.level_goals.empty():
		goals_to_reach = game_level.level_goals.duplicate()
		self.ai_state = AI_STATE.REACH_GOAL
	# BATTLE_GOALS
	elif game_level.finish_line.is_enabled:
		ai_target = game_level.finish_line
		self.ai_state = AI_STATE.REACH_GOAL
	# FREE_RIDE, BATTLE_
	else:
		self.ai_state = AI_STATE.SEARCH


func _on_NavigationAgent2D_path_changed() -> void:
#	print("nav path changed")

	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_target_reached() -> void:
#	print("nav target reached")

	if ai_state == AI_STATE.MOUSE_CLICK:
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(global_position, current_mouse_follow_point)
		ai_target = Mets.spawn_indikator(nav_path_points[0], Color.blue, 0, Refs.node_creation_parent)
		navigation_agent.set_target_location(nav_path_points[0])
		ai_state = AI_STATE.MOUSE_CLICK

	elif ai_state == AI_STATE.SEARCH:
		search_target_reached = true


func _on_NavigationAgent2D_navigation_finished() -> void:
	print("nav finished")
	pass


func _on_NavigationAgent2D_velocity_computed(safe_velocity: Vector2) -> void: # za avoidance

	var new_position: Vector2= navigation_agent.get_next_location()
	navigation_agent.set_target_location(new_position)
	navigation_agent.set_velocity(vehicle.velocity)

	print("avoided")



#  LAB ------------------------------------------------------------------------------------------------------


var track_target_prediction: float = 500 # za preprečitve križanja ... trenutno ne uporabljam? ker dela brez?
var prev_tracker_offset: float = 0
var wanted_speed: float = -1 # -1 je brez intervencije, 0 se ustavi
var curr_side: Vector2


func _adjust_power_speed_limit(speed_change_rate: float = 0.1):
	# redko ... je pa dober obvod do poenotenja kontrole z agenti z različnimi močmi
	# samo omejevanje, ker, če je ukaz navzgo, vehicle ne more preko svoje max moči ... logično

	if wanted_speed == -1:
		return false

	if wanted_speed == 0:
		motion_manager.current_engine_power = 0
	else:
		var current_speed: float = vehicle.body_state.get_linear_velocity().length()
		if current_speed > wanted_speed:
			motion_manager.current_engine_power = lerp(motion_manager.current_engine_power, 0, speed_change_rate)

	return true


func _get_target_position_side(target_position: Vector2):

	var checker_vector_rotated: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	var vector_to_target: Vector2 = target_position - global_position
	var is_target_on_right: float = checker_vector_rotated.cross(vector_to_target) # .dot doda 90 stopinj
#	var is_target_on_right: int = checker_vector_rotated.dot(vector_to_target) # .dot doda 90 stopinj
#	var is_target_on_right: float = checker_vector_rotated.dot(vector_to_target) # .dot doda 90 stopinj

	# RIGHT
	if is_target_on_right > 0:
#		print ("kva je na RIGHT ", is_target_on_right)
		return Vector2.RIGHT
	# LEFT
	elif is_target_on_right < 0:
#		print ("kva je na LEFT ", is_target_on_right)
		return Vector2.LEFT
	# STREJT
	else:
#		print ("kva je na zero ", is_target_on_right)
		return Vector2.ZERO


func _avoid_obsticles(vector_to_target: Vector2 = Vector2.ZERO): # # _temp še ne dela

	if ai_target:
		motion_manager.force_rotation = lerp_angle(motion_manager.force_rotation, motion_manager.driving_gear * _get_target_position_side(ai_target.global_position).x * deg2rad(motion_manager.max_engine_rotation_deg), motion_manager.engine_rotation_speed)
		#		motion_manager.rotation_dir = _get_target_side(vector_to_target)

	var roundabout_position = _update_vision()
	if roundabout_position:# is Vector2:
		vehicle.set_linear_velocity(braking_velocity)
		if roundabout_position == Vector2.ZERO:
			motion_manager.force_rotation = global_position.angle_to_point(roundabout_position)
		else:
			motion_manager.force_rotation = global_position.angle_to_point(roundabout_position)
		navigation_agent.set_target_location(roundabout_position) # _temp?
	else:
		motion_manager.force_rotation = Vector2.RIGHT.angle_to_point(- vector_to_target)


func _drive_as_player(follow_mouse: bool = false): # _temp func
	# dela vse, samo ne obrne se vedno do pravega kota oz rotacije

	#	motion_manager.current_engine_power /= 2
	#	motion_manager.torque_on_vehicle = 0
	#	vehicle.angular_damp = 1000
	#	vehicle.angular_damp = 100

	var target_pos: Vector2
	if follow_mouse:
		target_pos = get_global_mouse_position()
	else:
		# force on vehicle
		if ai_state == AI_STATE.ON_TRACK:
			target_pos = _get_tracking_position(ai_target)
#				vector_to_target = _get_tracking_position(ai_target) - global_position
		elif ai_target:
			target_pos = ai_target.global_position
#				vector_to_target = ai_target.global_position - global_position

		# on mouse follow
		var new_target_side: Vector2 = _get_target_position_side(target_pos)
		curr_side = new_target_side
		match curr_side:
			Vector2.RIGHT:
				motion_manager.motion = motion_manager.MOTION.IDLE_RIGHT
			Vector2.LEFT:
				motion_manager.motion = motion_manager.MOTION.IDLE_LEFT
			Vector2.ZERO:
				motion_manager.motion = motion_manager.MOTION.IDLE

		# FWD?
		var vehicle_fwd_vector: Vector2 = Vector2.RIGHT.rotated(global_rotation) * 300
		var vehicle_to_target_vector: Vector2 = global_position + vehicle_fwd_vector
		var angle_to_target_vector: float = Vector2.RIGHT.rotated(global_rotation).angle_to(target_pos)
		var angle_to_target_vector_deg: float = rad2deg(angle_to_target_vector)
		var limit_deg: float = 50
		if angle_to_target_vector_deg > -limit_deg and angle_to_target_vector_deg < limit_deg:
			print("angle in ..........................", rad2deg(angle_to_target_vector))
			motion_manager.engine_rotation_speed = 0.01
			motion_manager.motion = motion_manager.MOTION.FWD
			if rad2deg(angle_to_target_vector) < 0:
				motion_manager.motion = motion_manager.MOTION.FWD_RIGHT
			elif rad2deg(angle_to_target_vector) > 0:
				motion_manager.motion = motion_manager.MOTION.FWD_LEFT
			else:
				motion_manager.motion = motion_manager.MOTION.FWD
#				match motion_manager.rotation_dir:
#					1:
#						motion_manager.motion = motion_manager.MOTION.FWD_RIGHT
#					-1:
#						motion_manager.motion = motion_manager.MOTION.FWD_LEFT
#					0:
#						motion_manager.motion = motion_manager.MOTION.FWD

		# force
		motion_manager.force_rotation = lerp_angle(motion_manager.force_rotation, motion_manager.rotation_dir * angle_to_target_vector, motion_manager.engine_rotation_speed)
		var angle_to_target = Vector2.RIGHT.rotated(global_rotation).angle_to(target_pos)
		motion_manager.force_rotation = lerp_angle(motion_manager.force_rotation, angle_to_target, motion_manager.engine_rotation_speed)
		motion_manager.force_on_vehicle = Vector2.RIGHT.rotated(motion_manager.force_rotation + global_rotation) * motion_manager._accelarate_to_engine_power()

		# debug
		force_direction_line.set_as_toplevel(true)
		force_direction_line.set_point_position(0, global_position)
		force_direction_line.set_point_position(1, vehicle_to_target_vector)
