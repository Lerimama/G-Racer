extends Node


signal weapon_triggered

enum AI_STATE {OFF, RACE_TRACK, SEARCH, FOLLOW, HUNT, RACE_TO_GOAL, MOUSE_CLICK} # ai je možgan (driver in ne vehicle
var ai_state: int = AI_STATE.OFF setget _change_ai_state

enum BATTLE_STATE {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}
var battle_state: int = BATTLE_STATE.NONE

# seta spawner
var controlled_vehicle: Vehicle # temp ... Vehicle class
var driver_type: int # _temp da drugi vejo? ... ne vem zakaj ... se pa ob spawnu seta

# navigacija
var ai_target: Node2D = null
var ai_navigation_line: Line2D
onready var navigation_agent = $NavigationAgent2D
var level_navigation: NavigationPolygonInstance # poda spawner

# motion
var ai_navigation_target_range: Array = [600, 800] # min dist 0 pomeni iskanje najbližja možna
var braking_velocity: Vector2
var breaking_distance_factor: float = 0.5 # kako daleč je ovira preden bremza
var braking_power_factor: float = 0.7 # množenje s hitrostjo ... male spremembe
var breaking_factor_near: float = 0.95
var breaking_factor_keep: float = 0.68 # nežno se ustavi
var engine_power_factor_keep: float = 0
var engine_power_factor_search: float = 0.5

# vision
onready var vision: Node2D = $Vision
var keep_distance: float = 500
var near_distance: float = 800

# ai targets
var search_target_reached: bool = false
onready var target_ray: RayCast2D = $TargetRay # čekira "locked on" ... col_layer ai targets, vision brakers > bodies, areas
onready var scanning_ray = $ScanningRay # skenira za vision brake ... col_layer vision brakers > bodies, areas
onready var scanning_area: Area2D = $ScanningArea # objekti na tem območju so podvrženi inšpekciji

# debug
onready var force_direction_line: Line2D = $DirectionLine
var current_mouse_follow_point: Vector2 = Vector2.ZERO# debug za mouseclick

# neu ... za zrihtat
var goals_to_reach: Array = []# lovi jih v zaporedju, ko so ujeti se zbrišejo, če obstaja cilj je na koncu
var wanted_speed: float = -1 # -1 je brez intervencije, 0 se ustavi
var mina_released: bool # trenutno ne uporabljam ... če je že odvržen v trenutni ožini
var power_speed_factor: float # delež engine_power, ki manipulira z engine powerjem in imitira hitrost
var motion_manager: Node
var fast_start_window_is_open: bool = false
var random_start_range: Array = [0.1, 1]


func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:

#	if Input.is_action_just_pressed("no0"): # idle
#		self.ai_state = AI_STATE.OFF
	if Input.is_action_just_pressed("no1"): # idle
		self.ai_state = AI_STATE.RACE_TRACK
	if Input.is_action_just_pressed("no2"): # race
		self.ai_state = AI_STATE.SEARCH
	if Input.is_action_pressed("no3"):
		wanted_speed = 900
	if Input.is_action_just_pressed("no4"): # follow leader
#		wanted_speed = -1
		motion_manager.boost_vehicle()

	elif Input.is_action_just_pressed("left_click"): # follow leader
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_vehicle.global_position, level_navigation.get_local_mouse_position())
		ai_target = Mts.spawn_indikator(nav_path_points[0], Color(Color.blue, 0), 0, Rfs.node_creation_parent)
		navigation_agent.set_target_location(nav_path_points[0])
		ai_state = AI_STATE.MOUSE_CLICK
		current_mouse_follow_point = nav_path_points[nav_path_points.size()-1]


func _ready() -> void:

	randomize()
	controlled_vehicle = get_parent()

	controlled_vehicle.add_to_group(Rfs.group_ai)
	controlled_vehicle.add_to_group(Rfs.group_drivers)

	motion_manager.is_ai = true

	ai_navigation_line = Line2D.new()
	Rfs.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = Color.red
	ai_navigation_line.z_index = 10

	# ray exceptions
	scanning_ray.add_exception(controlled_vehicle)
	target_ray.add_exception(controlled_vehicle)
	for ray in vision.get_children():
		ray.add_exception(controlled_vehicle)


func _get_target_side(target_position: Vector2):

	var target_is_on_side: Vector2 = Mts.check_left_right(controlled_vehicle, target_position)

	# vrnem rot_direction
	if target_is_on_side == Vector2.RIGHT: # RIGHT
		return 1
	elif target_is_on_side == Vector2.LEFT: # LEFT
		return -1
	else: # STREJT
		return 0


func _physics_process(delta: float) -> void:

	if controlled_vehicle.is_active:

		if motion_manager.motion == motion_manager.MOTION.DISSARAY and not ai_state == AI_STATE.OFF:
			self.ai_state = AI_STATE.OFF

		_state_machine(delta)

		# force rotation
		var vector_to_target: Vector2 = Vector2.ZERO
		if ai_target and is_instance_valid(ai_target):
		#		if ai_target and not ai_target.is_queued_for_deletion():
			force_direction_line.default_color = Color.yellow
			if ai_state == AI_STATE.RACE_TRACK:
				vector_to_target = _get_tracking_position(ai_target) - controlled_vehicle.global_position
			else:
				vector_to_target = ai_target.global_position - controlled_vehicle.global_position
		else:
			force_direction_line.default_color = Color.red
			if not ai_state == AI_STATE.OFF: # če izgubi tarčo gre v SEARCH
				self.ai_state = AI_STATE.SEARCH
		motion_manager.force_rotation = Vector2.RIGHT.angle_to_point(- vector_to_target)

		# debug line
		force_direction_line.set_point_position(0, Vector2.ZERO)
		force_direction_line.set_point_position(1, vector_to_target.rotated(- controlled_vehicle.global_rotation))

		if not _update_vision() == null:
			controlled_vehicle.set_linear_velocity(braking_velocity)

			#		if ai_target:
			#			motion_manager.force_rotation = lerp_angle(motion_manager.force_rotation, motion_manager.driving_gear * _get_target_side(ai_target.global_position) * deg2rad(motion_manager.max_engine_rotation_deg), motion_manager.engine_rotation_speed)
			##			motion_manager.rotation_dir = _get_target_side(vector_to_target)

			#		var roundabout_position = _update_vision()
			#		if roundabout_position:# is Vector2:
			#			controlled_vehicle.set_linear_velocity(braking_velocity)
			#			if roundabout_position == Vector2.ZERO:
			#				motion_manager.force_rotation = controlled_vehicle.global_position.angle_to_point(roundabout_position)
			#			else:
			#				motion_manager.force_rotation = controlled_vehicle.global_position.angle_to_point(roundabout_position)
			#			navigation_agent.set_target_location(roundabout_position) # _temp?
			#		else:
			#			motion_manager.force_rotation = Vector2.RIGHT.angle_to_point(- vector_to_target)


func _state_machine(delta: float):
#	printt ("ai_state: ", AI_STATE.keys()[ai_state], motion_manager.current_engine_power)

	match ai_state:

		AI_STATE.OFF:
			pass

		AI_STATE.RACE_TRACK: # šiba po najbližji poti do tarče
			if not navigation_agent.get_target_location() == ai_target.global_position:
				var driver_tracker_position: Vector2 = _get_tracking_position(ai_target)
				navigation_agent.set_target_location(driver_tracker_position)
				#			Mts.spawn_indikator(driver_tracker_position, Color.white, controlled_vehicle.rotation, Rfs.node_creation_parent)
			if not _adjust_power_speed_limit():
				motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.SEARCH: # vozi po točkah navigacije in išče novo tarčo, dokler je ne najde
			var new_ai_target: Node2D = _get_better_targets(ai_target)
			# če je našel legitimno tarčo, ga dam v hunt
			if not new_ai_target == ai_target:
				ai_target = new_ai_target
				self.ai_state = AI_STATE.HUNT
			# če ni tarče in je dosegel nav target setam novo random točko
			elif search_target_reached:
				self.ai_state = AI_STATE.SEARCH
			motion_manager.current_engine_power = motion_manager.max_engine_power
#			controlled_vehicle.engine_power = controlled_vehicle.max_engine_power * engine_power_factor_search

		AI_STATE.FOLLOW: # sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			ai_target = _get_better_targets(ai_target)
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
#			_react_to_target(ai_target, true)
			_react_to_target(ai_target)
			motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.HUNT: # pobere tarčo, ki jo je videl ... ne izgubi pogleda
			# preverjam za boljšo tarčo
			ai_target = _get_better_targets(ai_target)
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
			_react_to_target(ai_target)
			motion_manager.current_engine_power = motion_manager.max_engine_power

		AI_STATE.RACE_TO_GOAL: # šiba do cilja po najbližji poti
			# _temp ... se zgodi manjko tarče ... setaj goal tarčo drugje kot zdaj
			if not navigation_agent.get_target_location() == ai_target.global_position:
				navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.current_engine_power = motion_manager.max_engine_power
			_react_to_target(ai_target)

		AI_STATE.MOUSE_CLICK:
			navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.current_engine_power = motion_manager.max_engine_power / 3
			_react_to_target(ai_target)


func _react_to_target(react_target: Node2D, keep_on_distance: bool = false, be_aggressive: bool = false):
	# keep_on_distance - ustavi na distanci in jo vzdržuje
	# aggresive - posešuje do tarče

	# debug
	#	keep_distance = 500
	#	near_distance = 800
	#	keep_on_distance = true
	#	be_aggressive = false

	var any_collider = Mts.get_directed_raycast_collision(target_ray, react_target.global_position)

	var target_in_sight: bool = false
	if any_collider and any_collider == react_target and is_instance_valid(react_target):
	#	if any_collider and any_collider == react_target and not react_target.is_queued_for_deletion():
		target_in_sight = true

	if target_in_sight:
		var target_closeup_breaking_factor: float = 1
		var distance_to_target = controlled_vehicle.global_position.distance_to(react_target.global_position)
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
		braking_velocity = controlled_vehicle.velocity * target_closeup_breaking_factor
		controlled_vehicle.set_linear_velocity(braking_velocity)
	else:
		# če izgubi pogled na tarčo, še zmeraj v tistem trenutku videl
		navigation_agent.set_target_location(controlled_vehicle.global_position)


func _adjust_power_speed_limit(speed_change_rate: float = 0.1):
	# redko ... je pa dober obvod do poenotenja kontrole z agenti z različnimi močmi
	# samo omejevanje, ker, če je ukaz navzgo, vehicle ne more preko svoje max moči ... logično

	if wanted_speed == -1:
		return false

	if wanted_speed == 0:
		motion_manager.current_engine_power = 0
	else:
		var current_speed: float = controlled_vehicle.body_state.get_linear_velocity().length()
		if current_speed > wanted_speed:
			motion_manager.current_engine_power = lerp(motion_manager.current_engine_power, 0, speed_change_rate)

	return true


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

	vision_ray_center.cast_to.x = controlled_vehicle.velocity.length() * breaking_distance_factor # zmeraj dolg kot je dolga hitrost
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
				braking_velocity = controlled_vehicle.velocity * breaking_factor_keep
				# ... dodaš rikverc
				#				max_collision_distance_position = vision_ray_left.get_collision_point()
				max_collision_distance_position = controlled_vehicle.global_position
				#				printt("going nowhere")
			1: # left
				max_collision_distance_position = vision_ray_left.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
				Mts.spawn_indikator(max_collision_distance_position, Color.pink)
				braking_velocity = controlled_vehicle.velocity * braking_power_factor
				rotation_adapt = -1
				#				printt("turning left")
			2: # right
				max_collision_distance_position = vision_ray_right.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
				braking_velocity = controlled_vehicle.velocity * braking_power_factor
				rotation_adapt = 1
				Mts.spawn_indikator(max_collision_distance_position, Color.orange)
				#				printerr("turning right")

		return max_collision_distance_position
	else:
		return


func _change_ai_state(new_ai_state: int):
#	printt ("_change_ai_state", AI_STATE.keys()[new_ai_state])

	scanning_ray.enabled = false
	target_ray.enabled = false

	match new_ai_state:
		AI_STATE.OFF:
			ai_target = null
			motion_manager.motion = motion_manager.MOTION.IDLE
		AI_STATE.RACE_TRACK:
			ai_target = controlled_vehicle.driver_tracker
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.SEARCH:
			search_target_reached = false
			scanning_ray.enabled = true
			ai_target = level_navigation.nav_position_target
			var nav_position_target: Node2D = _get_nav_position_target(controlled_vehicle.global_position, ai_navigation_target_range)
			navigation_agent.set_target_location(ai_target.global_position)
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.FOLLOW:
			target_ray.enabled = true
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.HUNT:
			target_ray.enabled = true
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.RACE_TO_GOAL:
			if not goals_to_reach.empty():
				ai_target = goals_to_reach[0]
			motion_manager.motion = motion_manager.MOTION.FWD
		AI_STATE.MOUSE_CLICK:
			motion_manager.motion = motion_manager.MOTION.FWD

	ai_state = new_ai_state


func goal_reached(goal_reached: Node2D, extra_target: Node2D = null):

	goals_to_reach.erase(goal_reached)

	if extra_target: # level finish, ...
		ai_target = extra_target
	elif not goals_to_reach.empty():
		ai_target = goals_to_reach.front()
	else:
		ai_target = null
		self.ai_state = AI_STATE.OFF


# HELPERS ----------------------------------------------------------------------------------------------


func _get_better_targets(current_target: Node2D):

	# naberem vse možno v scanning območju
	var possible_targets: Array = scanning_area.get_overlapping_bodies()
	possible_targets.append_array(scanning_area.get_overlapping_areas())
	# izločim sebe
	possible_targets.erase(controlled_vehicle)

	# naberem ai tarče
	var legit_targets: Array = []
	for possible_target in possible_targets:
		if "target_rank" in possible_target: # zazih ... scen se odvija samo na področju ai_targets
			if possible_target.target_rank > 0:
				legit_targets.append(possible_target)

	# naberem samo vidne
	var targets_in_sight: Array = []
	for legit_target in legit_targets:
		if not Mts.get_directed_raycast_collision(scanning_ray, legit_target.global_position):
			targets_in_sight.append(legit_target)

	# dobim top rangirano tarčo
	var target_ranks: Array = []
	for target_in_sight in targets_in_sight:
		target_ranks.append(target_in_sight.target_rank)
	var top_ranked_target_index: int = target_ranks.find(target_ranks.max())

	# ... manjka razvrščanje po distanci poleg ranga
	#	printt ("targets", possible_targets, legit_targets, targets_in_sight, top_ranked_target_index)

	if top_ranked_target_index > -1:
		return targets_in_sight[top_ranked_target_index]
	else:
		return current_target


func _get_nav_position_target(from_position: Vector2, distance_range: Array = [0, 50], in_front: bool = true):

	var level_navigation_points: Array = level_navigation.level_navigation_points

	if level_navigation_points.empty():
		return null

	var selected_nav_position: Vector2 = Vector2.ZERO
	var all_cells_for_random_selection: Array = []
	var front_cells_for_random_selection: Array = []
	var side_cells_for_random_selection: Array = []
	var all_nav_pos_distances: Array = [] # zaloga, če je ne najde na distanci

	if distance_range[0] > 0:
		#		if not Mts.all_indikators_spawned.empty():
		#			for n in Mts.all_indikators_spawned:
		#				n.queue_free()
		#			Mts.all_indikators_spawned.clear()
		var current_min_cell_distance: float = 0
		var current_min_cell_angle: float = 0

		for nav_position in level_navigation_points:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			all_nav_pos_distances.append(current_cell_distance) # zaloga, če je ne najde na distanci
			# najprej izbere vse na predpisani dolžini
			if current_cell_distance > distance_range[0] and current_cell_distance < distance_range[1]:
				if in_front:
					var vector_to_position: Vector2 = nav_position - controlled_vehicle.global_position
					var current_angle_to_vehicle_deg: float = rad2deg(controlled_vehicle.get_angle_to(nav_position))
					# najbolj spredaj
					if current_angle_to_vehicle_deg < 30 and current_angle_to_vehicle_deg > - 30 :
						front_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.yellow, controlled_vehicle.rotation, Rfs.node_creation_parent)
					# na straneh
					elif current_angle_to_vehicle_deg < 90 and current_angle_to_vehicle_deg > -90 :
						side_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.blue, controlled_vehicle.rotation, Rfs.node_creation_parent)
					# ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.green, controlled_vehicle.rotation, Rfs.node_creation_parent)
				else:
					all_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.turquoise, 0, Rfs.node_creation_parent)

		# žrebam ... najprej iz sprednjih
		if in_front:
			if not front_cells_for_random_selection.empty():
				selected_nav_position = front_cells_for_random_selection.pick_random()
			elif not side_cells_for_random_selection.empty():
				selected_nav_position = side_cells_for_random_selection.pick_random()
		else:
			selected_nav_position = all_cells_for_random_selection.pick_random()

	# če ni našel primerne točke (ali je ni iskal, če je min_distance = 0)
	if selected_nav_position == Vector2.ZERO:
		var closest_position_index: int = all_nav_pos_distances.find_last(all_nav_pos_distances.min())
		selected_nav_position = level_navigation_points[closest_position_index]

	# nav target premaknem na željeno pozicijo
	level_navigation.nav_position_target.global_position = selected_nav_position

	return level_navigation.nav_position_target


func _get_tracking_position(position_tracker: PathFollow2D):

	var point_on_curve_global_position: Vector2
	var ai_target_prediction: float = 500
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var driver_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	point_on_curve_global_position = driver_tracker_curve.interpolate_baked(ai_target_total_offset)

	return point_on_curve_global_position


func in_disarray(damage_amount: float): # dmg 5 raketa, 1 metk
	pass


# trenutno ne uporabljam
func _sort_objects_by_ai_rank(stuff_1, stuff_2): # descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if stuff_1.target_rank > stuff_2.target_rank:
	    return true
	return false


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_game_stage_change(game_manager: Game): # od GMja

#	var game_is_on: bool = false

	match game_manager.game_stage:
		game_manager.GAME_STAGE.PLAYING:
			# random start
			randomize()
			var random_start_delay: float = rand_range(random_start_range[0], random_start_range[1])
			yield(get_tree().create_timer(random_start_delay), "timeout")
			# level type
			if controlled_vehicle.driver_tracker:
				self.ai_state = AI_STATE.RACE_TRACK
			elif not goals_to_reach.empty():
				self.ai_state = AI_STATE.RACE_TO_GOAL
			elif game_manager.game_level.level_finish:
				ai_target = game_manager.game_level.level_finish
				self.ai_state = AI_STATE.RACE_TO_GOAL
			else:
				self.ai_state = AI_STATE.SEARCH
		game_manager.GAME_STAGE.END_SUCCESS, game_manager.GAME_STAGE.END_FAIL:
			self.ai_state = AI_STATE.OFF
			motion_manager.motion = motion_manager.MOTION.IDLE


func _on_NavigationAgent2D_path_changed() -> void:
#	print("nav path changed")

	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_target_reached() -> void:
#	print("nav target reached")

	if ai_state == AI_STATE.MOUSE_CLICK:
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_vehicle.global_position, current_mouse_follow_point)
		ai_target = Mts.spawn_indikator(nav_path_points[0], Color.blue, 0, Rfs.node_creation_parent)
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
	navigation_agent.set_velocity(controlled_vehicle.velocity)

	print("avoided")


