extends Node


enum AI_STATE {OFF, RACE, SEARCH, FOLLOW, HUNT, RACE_TO_GOAL, MOUSE_CLICK} # ai je možgan (controller in ne bolt
var ai_state: int = AI_STATE.OFF setget _change_ai_state

enum BATTLE_STATE {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}
var battle_state: int = BATTLE_STATE.NONE

# seta spawner
var controlled_bolt: RigidBody2D
var controller_type: int

# nodes
onready var navigation_agent = $NavigationAgent2D
onready var detect_ray = $DetectRay # za iskanje tarče in ?
onready var vision_ray = $VisionRay # za zaviranje in ?
onready var target_ray: RayCast2D = $TargetRay # za "locked on target" in ?
onready var detect_area: Area2D = $DetectArea

# navigacija
var ai_target: Node2D = null
var ai_navigation_line: Line2D
var level_navigation_positions: Array # poda GM ob spawnu
onready var level_navigation_target_node: Position2D = Refs.current_level.level_navigation.nav_position_target
onready var level_navigation: NavigationPolygonInstance = Refs.current_level.level_navigation

# motion
var ai_brake_distance_factor: float = 0.5 # delež dolžine vektorja hitrosti ... vision ray je na tej dolžini
var ai_brake_factor: float = 0.8 # množenje s hitrostjo
var ai_closeup_distance: float = 70
var ai_urgent_stop_distance: float = 20
var ai_navigation_target_range: Array = [50, 300] # min dist 0 pomeni iskanje najbližja možna
var target_ray_angle_limit: float = 30
var target_ray_seek_length: float = 320
var target_ray_rotation_speed: float = 1
var braking_velocity: Vector2

# debug
onready var force_direction_line: Line2D = $DirectionLine

# neu
var target_prev_position: Vector2 = Vector2.ZERO # če zgubi gibajočo se tarčo gre do zadnje lokacij tarče
var current_mouse_follow_point: Vector2 = Vector2.ZERO# debug za mouseclick
var current_game_goals: Array
var vision_breaker: Node # _temp vision breaker


# ni v uporabi
var closeup_engine_power
var search_engine_power
var hold_engine_power
var engine_power_hunt: float
var engine_power_race: float
var engine_power_search: float
var mina_released: bool # trenutno ne uporabljam ... če je že odvržen v trenutni ožini



func _input(event: InputEvent) -> void:
#{OFF, RACE, SEARCH, FOLLOW, HUNT, RACE_TO_GOAL}

	if Input.is_action_just_pressed("no0"): # idle
		self.ai_state = AI_STATE.OFF
	if Input.is_action_just_pressed("no1"): # idle
		self.ai_state = AI_STATE.RACE
	if Input.is_action_just_pressed("no2"): # race
		self.ai_state = AI_STATE.SEARCH
	if Input.is_action_just_pressed("no3"):
		pass
	if Input.is_action_just_pressed("no4"): # follow leader
		pass
	elif Input.is_action_just_pressed("left_click"): # follow leader
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_bolt.bolt_global_position, level_navigation.get_local_mouse_position())
		ai_target = Mets.spawn_indikator(nav_path_points[0], Color.blue, 0, Refs.node_creation_parent)
		navigation_agent.set_target_location(nav_path_points[0])
		ai_state = AI_STATE.MOUSE_CLICK
		current_mouse_follow_point = nav_path_points[nav_path_points.size()-1]


func _ready() -> void:

	randomize()
	controlled_bolt.add_to_group(Refs.group_ai)
	controlled_bolt.motion = controlled_bolt.MOTION.FWD # debug preset motion

	ai_navigation_line = Line2D.new()
	Refs.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = Color.red
	ai_navigation_line.z_index = 10

	# ray exceptions
	detect_ray.add_exception(controlled_bolt)
	target_ray.add_exception(controlled_bolt)
	vision_ray.add_exception(controlled_bolt)


func _physics_process(delta: float) -> void:

	if controlled_bolt.is_active:
		_ai_state_machine(delta)

		# rotacija sile proti tarči ... more bit po state mašini
		var vector_to_target: Vector2 = Vector2.ZERO
		if ai_target and not ai_target.is_queued_for_deletion():
#			_ai_state_machine(delta)
			force_direction_line.default_color = Color.yellow
			if ai_state == AI_STATE.RACE:
				vector_to_target = _get_tracking_position(ai_target) - controlled_bolt.bolt_global_position
			else:
				vector_to_target = ai_target.global_position - controlled_bolt.bolt_global_position
		else:
			force_direction_line.default_color = Color.red
			if not ai_state == AI_STATE.OFF: # če izgubi tarčo gre v SEARCH
				self.ai_state = AI_STATE.SEARCH
		# debug line
		force_direction_line.set_point_position(0, Vector2.ZERO)
		force_direction_line.set_point_position(1, vector_to_target.rotated(- controlled_bolt.bolt_global_rotation))
		controlled_bolt.force_rotation = Vector2.ZERO.angle_to_point(- vector_to_target)


func _ai_state_machine(delta: float):
	#	printt ("ai_state: ", AI_STATE.keys()[ai_state], controlled_bolt.engine_power)
#		return

	match ai_state:
		AI_STATE.OFF:
			pass
		AI_STATE.RACE: # šiba po najbližji poti do tarče
			_update_vision()
			if not navigation_agent.get_target_location() == ai_target.global_position:
				target_prev_position = navigation_agent.get_target_location()
				var bolt_tracker_position: Vector2 = _get_tracking_position(ai_target)
				navigation_agent.set_target_location(bolt_tracker_position)
				#			Mets.spawn_indikator(bolt_tracker_position, Color.white, controlled_bolt.rotation, Refs.node_creation_parent)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power/2

		AI_STATE.SEARCH: # vozi po točkah navigacije in išče novo tarčo, dokler je ne najde
			_update_vision()
			if not _get_possible_targets().empty(): # če je kakšna tarča jo začne lovit
				self.ai_state = AI_STATE.HUNT

		AI_STATE.FOLLOW: # sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			if not navigation_agent.get_target_location() == ai_target.global_position:
				target_prev_position = navigation_agent.get_target_location()
				navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power/2
			_check_target_closeup(target_ray, ai_target.global_position)
			# lose target on vision breaker ... SEARCH new
			if target_ray.is_colliding() and target_ray.get_collider() == vision_breaker:
				if target_prev_position == Vector2.ZERO:
					self.ai_state = AI_STATE.SEARCH
				else:
					navigation_agent.set_target_location(target_prev_position)
					target_prev_position = Vector2.ZERO
			elif ai_target == null or ai_target.is_queued_for_deletion():
				if target_prev_position == Vector2.ZERO:
					self.ai_state = AI_STATE.SEARCH
				else:
					navigation_agent.set_target_location(target_prev_position)
					target_prev_position = Vector2.ZERO
			# če obstaja druga tarča izberem tisto, ki rangira najbolje
			if not _get_possible_targets().empty():
				if _get_possible_targets()[0].ai_target_rank > ai_target.ai_target_rank:
					self.ai_state = AI_STATE.FOLLOW # izbere [0] tarčo

		AI_STATE.HUNT: # pobere tarčo, ki jo je videl ... ne izgubi pogleda
			if not navigation_agent.get_target_location() == ai_target.global_position:
				target_prev_position = navigation_agent.get_target_location()
				navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power / 5
			_check_target_closeup(target_ray, ai_target.global_position)
			# lose target on vision breaker ... SEARCH new
			if target_ray.is_colliding() and target_ray.get_collider() == vision_breaker:
				if target_prev_position == Vector2.ZERO:
					self.ai_state = AI_STATE.SEARCH
				else:
					navigation_agent.set_target_location(target_prev_position)
					target_prev_position = Vector2.ZERO
			elif ai_target == null or ai_target.is_queued_for_deletion():
				if target_prev_position == Vector2.ZERO:
					self.ai_state = AI_STATE.SEARCH
				else:
					navigation_agent.set_target_location(target_prev_position)
					target_prev_position = Vector2.ZERO
			# če obstaja druga tarča izberem tisto, ki rangira najbolje
			if not _get_possible_targets().empty():
				if _get_possible_targets()[0].ai_target_rank > ai_target.ai_target_rank:
					self.ai_state = AI_STATE.HUNT # izbere [0] tarčo

		AI_STATE.RACE_TO_GOAL: # šiba do cilja po najbližji poti
			if not navigation_agent.get_target_location() == ai_target.global_position:
				navigation_agent.set_target_location(ai_target.global_position)
#			_check_target_closeup(target_ray, ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power/2
		AI_STATE.MOUSE_CLICK:
			navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power


func _change_ai_state(new_ai_state: int):
#	printt ("_change_ai_state", AI_STATE.keys()[new_ai_state])

	# reset
	detect_ray.enabled = false
	target_ray.enabled = false
	target_prev_position = Vector2.ZERO

	match new_ai_state:
		AI_STATE.OFF:
			controlled_bolt.motion = controlled_bolt.MOTION.IDLE
		AI_STATE.RACE:
			ai_target = controlled_bolt.bolt_tracker
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.SEARCH:
			detect_ray.enabled = true
			target_ray.enabled = true
			var nav_position_target: Node = _get_nav_position_target(controlled_bolt.bolt_global_position, ai_navigation_target_range)
			ai_target = level_navigation_target_node
#			navigation_agent.set_target_location(nav_position_target.global_position)
			navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.FOLLOW:
			target_ray.enabled = true
			ai_target = _get_possible_targets()[0]
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.HUNT:
			target_ray.enabled = true
			ai_target = _get_possible_targets()[0]
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.RACE_TO_GOAL:
			target_ray.enabled = true
			ai_target = current_game_goals[0]
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.MOUSE_CLICK:
			target_ray.enabled = true
#			navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.motion = controlled_bolt.MOTION.FWD

#	navigation_agent.set_target_location(ai_target.global_position)
	ai_state = new_ai_state


# HELPERS ----------------------------------------------------------------------------------------------


func _get_possible_targets():

	# detect area nabira
	var all_possible_targets: Array = detect_area.get_overlapping_bodies()
	all_possible_targets.append_array(detect_area.get_overlapping_areas())

	# izločim sebe in rank = 0
	all_possible_targets.erase(controlled_bolt)

	# detect ray rotira in nabira
	detect_ray.cast_to.x = target_ray_seek_length
	detect_ray.rotation_degrees += target_ray_rotation_speed
	if detect_ray.rotation_degrees > target_ray_angle_limit:
		detect_ray.rotation_degrees = -target_ray_angle_limit
	if detect_ray.is_colliding() and not detect_ray.get_collider() == level_navigation:
		all_possible_targets.append(detect_ray.get_collider())
	#	# target ray rotira in nabira
	#	target_ray.cast_to.x = target_ray_seek_length
	#	target_ray.rotation_degrees += target_ray_rotation_speed
	#	if target_ray.rotation_degrees > target_ray_angle_limit:
	#		target_ray.rotation_degrees = -target_ray_angle_limit
	#	if target_ray.is_colliding() and not target_ray.get_collider() == level_navigation:
	#		all_possible_targets.append(target_ray.get_collider())


	for target in all_possible_targets:
		if not "ai_target_rank" in ai_target: # naj bi imeli vsi na tem koližn levelu
			all_possible_targets.erase(target)
		elif target.ai_target_rank == 0:
			all_possible_targets.erase(target)

	# če ni tarče
	if all_possible_targets.empty():
		return all_possible_targets

	# rangiram po ranku
	all_possible_targets.sort_custom(self, "_sort_objects_by_ai_rank")
	# rangiram po potrebi
	#	if player_stats["bullet_count"] == 0 and player_stats["misile_count"] == 0:
	#		for target in all_possible_targets:
	#			if "pickable_key" in target:
	#				if target.pickable_key == Pros.AMMO.BULLET or target.pickable_key == Pros.AMMO.MISILE:
	#					all_possible_targets.push_front(target)
	# rangiram po distanci

	# detect ray preveri, če so tarče za steno
	var targets_behind_wall: Array = []
	for possible_target in all_possible_targets:
		target_ray.force_raycast_update()
		target_ray.look_at(possible_target.global_position)
		var target_ray_length: float = controlled_bolt.bolt_global_position.distance_to(possible_target.global_position)
		target_ray.cast_to.x = target_ray_length
		if target_ray.is_colliding() and target_ray.get_collider() == level_navigation:
			targets_behind_wall.append(possible_target)
	#	var targets_behind_wall: Array = []
	#	for possible_target in all_possible_targets:
	#		detect_ray.force_raycast_update()
	#		detect_ray.look_at(possible_target.global_position)
	#		var detect_ray_length: float = controlled_bolt.bolt_global_position.distance_to(possible_target.global_position)
	#		detect_ray.cast_to.x = detect_ray_length
	#		if detect_ray.is_colliding() and detect_ray.get_collider() == level_navigation_target_node:
	#			targets_behind_wall.append(possible_target)
	#			# printt("walled", Pros.PICKABLE.keys()[possible_target.pickable_key])



	for target_behind_wall in targets_behind_wall:
		all_possible_targets.erase(target_behind_wall)

	# if not all_possible_targets.empty():
	#	printt("all targets %s" % all_possible_targets.size(), "walled targets %s" % targets_behind_wall.size(), "selected target %s" % Pros.PICKABLE.keys()[all_possible_targets[0].pickable_key])

	return all_possible_targets


func _sort_objects_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši

	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false


func _get_nav_position_target(from_position: Vector2, distance_range: Array = [0, 50], in_front: bool = true):

	if level_navigation_positions.empty():
		return null

	var selected_nav_position: Vector2 = Vector2.ZERO
	var all_cells_for_random_selection: Array = []
	var front_cells_for_random_selection: Array = []
	var side_cells_for_random_selection: Array = []
	var all_nav_pos_distances: Array = [] # zaloga, če je ne najde na distanci

	if distance_range[0] > 0:
		#		if not Mets.all_indikators_spawned.empty():
		#			for n in Mets.all_indikators_spawned:
		#				n.queue_free()
		#			Mets.all_indikators_spawned.clear()
		var current_min_cell_distance: float = 0
		var current_min_cell_angle: float = 0

		for nav_position in level_navigation_positions:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			all_nav_pos_distances.append(current_cell_distance) # zaloga, če je ne najde na distanci
			# najprej izbere vse na predpisani dolžini
			if current_cell_distance > distance_range[0] and current_cell_distance < distance_range[1]:
				if in_front:
					var vector_to_position: Vector2 = nav_position - controlled_bolt.bolt_global_position
					var current_angle_to_bolt_deg: float = rad2deg(controlled_bolt.get_angle_to(nav_position))
					# najbolj spredaj
					if current_angle_to_bolt_deg < 30 and current_angle_to_bolt_deg > - 30 :
						front_cells_for_random_selection.append(nav_position) # Mets.spawn_indikator(nav_position, Color.yellow, controlled_bolt.rotation, Refs.node_creation_parent)
					# na straneh
					elif current_angle_to_bolt_deg < 90 and current_angle_to_bolt_deg > -90 :
						side_cells_for_random_selection.append(nav_position) # Mets.spawn_indikator(nav_position, Color.blue, controlled_bolt.rotation, Refs.node_creation_parent)
					# ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position) # Mets.spawn_indikator(nav_position, Color.green, controlled_bolt.rotation, Refs.node_creation_parent)
				else:
					all_cells_for_random_selection.append(nav_position) # Mets.spawn_indikator(nav_position, Color.turquoise, 0, Refs.node_creation_parent)

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
		selected_nav_position = level_navigation_positions[closest_position_index]

	# premik position nodeta
	level_navigation_target_node.global_position = selected_nav_position

	return level_navigation_target_node


func _get_tracking_position(position_tracker: PathFollow2D):

	var point_on_curve_global_position: Vector2
	var ai_target_prediction: float = 500
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var bolt_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	point_on_curve_global_position = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)

	return point_on_curve_global_position


func _update_vision():

	vision_ray.cast_to.x = controlled_bolt.bolt_velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
	if vision_ray.is_colliding():
		braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
		controlled_bolt.set_linear_velocity(braking_velocity)


func _check_target_closeup(ray, target_position):

	match ai_state:
		AI_STATE.FOLLOW, AI_STATE.MOUSE_CLICK: # približa in miruje, ko se oddalji gre spet naprej
			ray.look_at(target_position)
			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(target_position)
			ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
				controlled_bolt.set_linear_velocity(braking_velocity)
				controlled_bolt.engine_power = 0.1 # če je čista 0 se noče vrtet
			elif ray_velocity_length < ai_closeup_distance:
				var brake_factor: float = 0.95
				braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
				controlled_bolt.set_linear_velocity(braking_velocity)
				controlled_bolt.engine_power = controlled_bolt.max_engine_power/2
			elif ray_velocity_length >= ai_closeup_distance:
				controlled_bolt.engine_power = controlled_bolt.max_engine_power
		AI_STATE.HUNT, AI_STATE.RACE_TO_GOAL: # se ustavi in povozi
			ray.look_at(target_position)
			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(target_position)
			ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				var brake_factor: float = 0.95
				braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
				controlled_bolt.set_linear_velocity(braking_velocity)


func in_disarray(damage_amount: float): # 5 raketa, 1 metk
	# drugačen smisel ... to je stvar, ko težko voziš ... dodaš "čudne" sile

	#	motion = MotionStates.DISARRAY
	#	set_process_input(false)
	#	var dissaray_time_factor: float = 0.6 # uravnano, da naredi pol kroga na 1 damage
	#	var disarray_rotation_dir: float = damage_amount # vedno je -1, 0, ali +1, samo tukaj jo povečam, da dobim hitro rotacijo
	#	var on_hit_disabled_time: float = dissaray_time_factor * damage_amount
	#	# random disarray direction
	#	var dissaray_random_direction = randi() % 2
	#	if dissaray_random_direction == 0:
	#		rotation_dir = - disarray_rotation_dir
	#	else:
	#		rotation_dir = disarray_rotation_dir
	#	dissaray_tween = get_tree().create_tween()
	#	dissaray_tween.tween_property(self, "bolt_velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek
	#	dissaray_tween.parallel().tween_property(self, "rotation_dir", 0, on_hit_disabled_time)#.set_ease(Tween.EASE_IN) # tajmiram pojemek
	#	yield(dissaray_tween, "finished")
	#	set_process_input(true)
	#	motion = MotionStates.OFF
	pass


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_game_state_change(new_game_state: bool, level_settings: Dictionary): # od GMja

	if new_game_state == true:
		#		printt ("game on SMS", new_game_state, level_settings)
		match level_settings["level_type"]: # enums so v levelu
			"RACING":
				Refs.current_level.level_type = Refs.current_level.LEVEL_TYPE.RACE
				self.ai_state = AI_STATE.RACE
			"BATTLE":
				Refs.current_level.level_type = Refs.current_level.LEVEL_TYPE.BATTLE
				self.ai_state = AI_STATE.SEARCH
			"RACE_GOAL":
				Refs.current_level.level_type = Refs.current_level.LEVEL_TYPE.RACE_GOAL
				current_game_goals = Refs.current_level.temp_level_goals.duplicate()
				self.ai_state = AI_STATE.RACE_TO_GOAL
	else:
		#		printt ("game on SMS", new_game_state)
		self.ai_state = AI_STATE.OFF
		controlled_bolt.motion = controlled_bolt.MOTION.IDLE


func _on_message_from_game_manager(message_type, message_content): # od GMja

	printt ("message in", message_content)
	# lap, finished, check point


func _on_NavigationAgent2D_path_changed() -> void:
	print("nav path changed")

	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_navigation_finished() -> void:
	print("nav finished")


func _on_NavigationAgent2D_target_reached() -> void:

	if ai_state == AI_STATE.RACE_TO_GOAL:
		current_game_goals.pop_front()
		self.ai_state = AI_STATE.RACE_TO_GOAL
	elif ai_state == AI_STATE.MOUSE_CLICK:
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_bolt.bolt_global_position, current_mouse_follow_point)
		ai_target = Mets.spawn_indikator(nav_path_points[0], Color.blue, 0, Refs.node_creation_parent)
		navigation_agent.set_target_location(nav_path_points[0])
		ai_state = AI_STATE.MOUSE_CLICK

	print("nav target reached")

