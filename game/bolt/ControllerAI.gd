extends Node


enum AI_STATE {OFF, RACE_TRACK, SEARCH, FOLLOW, HUNT, RACE_TO_GOAL, MOUSE_CLICK} # ai je možgan (controller in ne bolt
var ai_state: int = AI_STATE.OFF setget _change_ai_state

enum BATTLE_STATE {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}
var battle_state: int = BATTLE_STATE.NONE

# seta spawner
var controlled_bolt: Bolt
var controller_type: int # OPT da drugi vejo? ... ne vem zakaj ... se pa ob spawnu seta

# navigacija
var ai_target: Node2D = null
var ai_navigation_line: Line2D
var level_navigation_positions: Array # poda GM ob spawnu
onready var navigation_agent = $NavigationAgent2D
onready var level_navigation_target_node: Position2D = Rfs.current_level.level_navigation.nav_position_target
onready var level_navigation: NavigationPolygonInstance = Rfs.current_level.level_navigation

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


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no0"): # idle
		self.ai_state = AI_STATE.OFF
	if Input.is_action_just_pressed("no1"): # idle
		self.ai_state = AI_STATE.RACE_TRACK
	if Input.is_action_just_pressed("no2"): # race
		self.ai_state = AI_STATE.SEARCH
	if Input.is_action_pressed("no3"):
		wanted_speed = 900
	if Input.is_action_just_pressed("no4"): # follow leader
		wanted_speed = -1
#		controlled_bolt.using_nitro = true

	elif Input.is_action_just_pressed("left_click"): # follow leader
		var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_bolt.global_position, level_navigation.get_local_mouse_position())
		ai_target = Mts.spawn_indikator(nav_path_points[0], Color.blue, 0, Rfs.node_creation_parent)
		navigation_agent.set_target_location(nav_path_points[0])
		ai_state = AI_STATE.MOUSE_CLICK
		current_mouse_follow_point = nav_path_points[nav_path_points.size()-1]


func _ready() -> void:

	# enemi koližn lejer
	controlled_bolt.set_collision_layer_bit(6, true)
	printt("controller", self.name, controlled_bolt.get_collision_layer_bit(0))

	randomize()
	controlled_bolt.add_to_group(Rfs.group_ai)

	ai_navigation_line = Line2D.new()
	Rfs.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = Color.red
	ai_navigation_line.z_index = 10

	# ray exceptions
	scanning_ray.add_exception(controlled_bolt)
	target_ray.add_exception(controlled_bolt)
	for ray in vision.get_children():
		ray.add_exception(controlled_bolt)


func _physics_process(delta: float) -> void:

	if controlled_bolt.is_active:

		# states
		_state_machine(delta)

		# force rotation
		var vector_to_target: Vector2 = Vector2.ZERO
		if ai_target and not ai_target.is_queued_for_deletion():
			force_direction_line.default_color = Color.yellow
			if ai_state == AI_STATE.RACE_TRACK:
				vector_to_target = _get_tracking_position(ai_target) - controlled_bolt.global_position
			else:
				vector_to_target = ai_target.global_position - controlled_bolt.global_position
		else:
			force_direction_line.default_color = Color.red
			if not ai_state == AI_STATE.OFF: # če izgubi tarčo gre v SEARCH
				self.ai_state = AI_STATE.SEARCH
		# debug line
		force_direction_line.set_point_position(0, Vector2.ZERO)
		force_direction_line.set_point_position(1, vector_to_target.rotated(- controlled_bolt.rotation))
#		force_direction_line.set_point_position(1, vector_to_target.rotated(- controlled_bolt.bolt_global_rotation))


		var roundabout_position = _update_vision()
		if roundabout_position:# is Vector2:
			controlled_bolt.set_linear_velocity(braking_velocity)
			if roundabout_position == Vector2.ZERO:
				pass
				controlled_bolt.force_rotation = controlled_bolt.global_position.angle_to_point(roundabout_position)
			else:
				controlled_bolt.force_rotation = controlled_bolt.global_position.angle_to_point(roundabout_position)
			navigation_agent.set_target_location(roundabout_position) # _temp?
		else:
			controlled_bolt.force_rotation = Vector2.ZERO.angle_to_point(- vector_to_target)


func _state_machine(delta: float):
#	printt ("ai_state: ", AI_STATE.keys()[ai_state], controlled_bolt.engine_power)

	match ai_state:

		AI_STATE.OFF:
			pass

		AI_STATE.RACE_TRACK: # šiba po najbližji poti do tarče
			if not navigation_agent.get_target_location() == ai_target.global_position:
				var bolt_tracker_position: Vector2 = _get_tracking_position(ai_target)
				navigation_agent.set_target_location(bolt_tracker_position)
				#			Mts.spawn_indikator(bolt_tracker_position, Color.white, controlled_bolt.rotation, Rfs.node_creation_parent)
			if not _adjust_power_speed_limit():
				controlled_bolt.engine_power = controlled_bolt.max_engine_power

		AI_STATE.SEARCH: # vozi po točkah navigacije in išče novo tarčo, dokler je ne najde
			var new_ai_target: Node2D = _get_better_targets(ai_target)
			# če je našel legitimno tarčo, ga dam v hunt
			if not new_ai_target == ai_target:
				ai_target = new_ai_target
				self.ai_state = AI_STATE.HUNT
			# če ni tarče in je dosegel nav target setam novo random točko
			elif search_target_reached:
				self.ai_state = AI_STATE.SEARCH
			controlled_bolt.engine_power = controlled_bolt.max_engine_power * engine_power_factor_search

		AI_STATE.FOLLOW: # sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			ai_target = _get_better_targets(ai_target)
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
			_react_to_target(ai_target, true)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power

		AI_STATE.HUNT: # pobere tarčo, ki jo je videl ... ne izgubi pogleda
			# preverjam za boljšo tarčo
			ai_target = _get_better_targets(ai_target)
			if not navigation_agent.get_target_location() == ai_target.global_position: # setam novo pozicijo, če je drugačna
				navigation_agent.set_target_location(ai_target.global_position)
			_react_to_target(ai_target)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power

		AI_STATE.RACE_TO_GOAL: # šiba do cilja po najbližji poti
			ai_target = goals_to_reach[0]
			if not navigation_agent.get_target_location() == ai_target.global_position:
				navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power
			_react_to_target(ai_target)

		AI_STATE.MOUSE_CLICK:
			navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.engine_power = controlled_bolt.max_engine_power / 3
			_react_to_target(ai_target)


func _adjust_power_speed_limit(speed_change_rate: float = 0.1):
	# redko ... je pa dober obvod do poenotenja kontrole z bolti z različnimi močmi
	# samo omejevanje, ker, če je ukaz navzgo, bolt ne more preko svoje max moči ... logično

	if wanted_speed == -1:
		return false

	if wanted_speed == 0:
		controlled_bolt.engine_power = 0
	else:
		var current_speed: float = controlled_bolt.bolt_body_state.get_linear_velocity().length()
		if current_speed > wanted_speed:
			controlled_bolt.engine_power = lerp(controlled_bolt.engine_power, 0, speed_change_rate)

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


	#	printt("---------")
	vision_ray_center.cast_to.x = controlled_bolt.bolt_velocity.length() * breaking_distance_factor # zmeraj dolg kot je dolga hitrost
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
#				printt("going nowhere")
				nowhere_to_go = true
				braking_velocity = controlled_bolt.bolt_velocity * breaking_factor_keep
				# ... dodaš rikverc
				#				max_collision_distance_position = vision_ray_left.get_collision_point()
				max_collision_distance_position = controlled_bolt.global_position
			1: # left
				max_collision_distance_position = vision_ray_left.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
				Mts.spawn_indikator(max_collision_distance_position, Color.pink)
				braking_velocity = controlled_bolt.bolt_velocity * braking_power_factor
				rotation_adapt = -1
				#				printt("turning left")
			2: # right
				max_collision_distance_position = vision_ray_right.get_collision_point() #+ vision_ray_right.get_collision_normal() * 100
				braking_velocity = controlled_bolt.bolt_velocity * braking_power_factor
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
			controlled_bolt.motion = controlled_bolt.MOTION.IDLE
		AI_STATE.RACE_TRACK:
			ai_target = controlled_bolt.bolt_tracker
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.SEARCH:
			search_target_reached = false
			scanning_ray.enabled = true
			ai_target = level_navigation_target_node
			var nav_position_target: Node2D = _get_nav_position_target(controlled_bolt.global_position, ai_navigation_target_range)
			navigation_agent.set_target_location(ai_target.global_position)
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.FOLLOW:
			target_ray.enabled = true
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.HUNT:
			target_ray.enabled = true
			controlled_bolt.motion = controlled_bolt.MOTION.FWD
		AI_STATE.RACE_TO_GOAL:
#			if not goals_to_reach.empty():
#				ai_target = goals_to_reach[0]
			controlled_bolt.motion = controlled_bolt.MOTION.FWD

		AI_STATE.MOUSE_CLICK:
			controlled_bolt.motion = controlled_bolt.MOTION.FWD

	ai_state = new_ai_state


# HELPERS ----------------------------------------------------------------------------------------------


func _get_better_targets(current_target: Node2D):

	# naberem vse možno v scanning območju
	var possible_targets: Array = scanning_area.get_overlapping_bodies()
	possible_targets.append_array(scanning_area.get_overlapping_areas())
	# izločim sebe
	possible_targets.erase(controlled_bolt)

	# naberem ai tarče
	var legit_targets: Array = []
	for possible_target in possible_targets:
		if "ai_target_rank" in possible_target: # zazih ... scen se odvija samo na področju ai_targets
			if possible_target.ai_target_rank > 0:
				legit_targets.append(possible_target)

	# naberem samo vidne
	var targets_in_sight: Array = []
	for legit_target in legit_targets:
		if not Mts.get_raycast_collision_to_position(scanning_ray, legit_target.global_position):
			targets_in_sight.append(legit_target)

	# dobim top rangirano tarčo
	var target_ranks: Array = []
	for target_in_sight in targets_in_sight:
		target_ranks.append(target_in_sight.ai_target_rank)
	var top_ranked_target_index: int = target_ranks.find(target_ranks.max())

	# ... manjka razvrščanje po distanci poleg ranga
	#	printt ("targets", possible_targets, legit_targets, targets_in_sight, top_ranked_target_index)

	if top_ranked_target_index > -1:
		return targets_in_sight[top_ranked_target_index]
	else:
		return current_target


func _get_nav_position_target(from_position: Vector2, distance_range: Array = [0, 50], in_front: bool = true):

	if level_navigation_positions.empty():
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

		for nav_position in level_navigation_positions:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			all_nav_pos_distances.append(current_cell_distance) # zaloga, če je ne najde na distanci
			# najprej izbere vse na predpisani dolžini
			if current_cell_distance > distance_range[0] and current_cell_distance < distance_range[1]:
				if in_front:
					var vector_to_position: Vector2 = nav_position - controlled_bolt.global_position
					var current_angle_to_bolt_deg: float = rad2deg(controlled_bolt.get_angle_to(nav_position))
					# najbolj spredaj
					if current_angle_to_bolt_deg < 30 and current_angle_to_bolt_deg > - 30 :
						front_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.yellow, controlled_bolt.rotation, Rfs.node_creation_parent)
					# na straneh
					elif current_angle_to_bolt_deg < 90 and current_angle_to_bolt_deg > -90 :
						side_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.blue, controlled_bolt.rotation, Rfs.node_creation_parent)
					# ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position) # Mts.spawn_indikator(nav_position, Color.green, controlled_bolt.rotation, Rfs.node_creation_parent)
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


func _react_to_target(react_target: Node2D, keep_on_distance: bool = false, be_aggressive: bool = false):
	# keep_on_distance - ustavi na distanci in jo vzdržuje
	# aggresive - posešuje do tarče

	# debug
	#	keep_distance = 500
	#	near_distance = 800
	#	keep_on_distance = true
	#	be_aggressive = false

	var any_collider = Mts.get_raycast_collision_to_position(target_ray, react_target.global_position)

	var target_in_sight: bool = false
	if any_collider and any_collider == react_target and not react_target.is_queued_for_deletion():
		target_in_sight = true

	if target_in_sight:
		var target_closeup_breaking_factor: float = 1
		var distance_to_target = controlled_bolt.global_position.distance_to(react_target.global_position)
		if distance_to_target < keep_distance:
			if keep_on_distance: # ustavi tik pred tarčo
				target_closeup_breaking_factor = breaking_factor_keep
				controlled_bolt.engine_power = controlled_bolt.max_engine_power * engine_power_factor_keep
			elif be_aggressive: # fuuul power čez tarčo
				controlled_bolt.engine_power = controlled_bolt.max_engine_power
			else: # spusti gasa čez tarčo
				controlled_bolt.engine_power = 0
			controlled_bolt.engine_power = 0
		elif distance_to_target < near_distance:
			if be_aggressive: # pospešuje proti tarči
				controlled_bolt.engine_power = controlled_bolt.max_engine_power
				controlled_bolt.use_nitro = true
			else: # upočasnuje proti tarči
				target_closeup_breaking_factor = breaking_factor_near
		else:
			controlled_bolt.engine_power = controlled_bolt.max_engine_power
		braking_velocity = controlled_bolt.bolt_velocity * target_closeup_breaking_factor
		controlled_bolt.set_linear_velocity(braking_velocity)
	else:
		# če izgubi pogled na tarčo, še zmeraj v tistem trenutku videl
		navigation_agent.set_target_location(controlled_bolt.global_position)


func in_disarray(damage_amount: float): # dmg 5 raketa, 1 metk
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


# trenutno ne uporabljam
func _sort_objects_by_ai_rank(stuff_1, stuff_2): # descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if stuff_1.ai_target_rank > stuff_2.ai_target_rank:
	    return true
	return false


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_game_state_change(new_game_state: bool, level_settings: Dictionary): # od GMja

	# level type
	var level_type: int = level_settings["level_type"]

	if new_game_state == true:
		match level_type: # enums so v levelu
			Rfs.current_level.LEVEL_TYPE.RACE_TRACK:
				self.ai_state = AI_STATE.RACE_TRACK
			Rfs.current_level.LEVEL_TYPE.BATTLE:
				self.ai_state = AI_STATE.SEARCH
			Rfs.current_level.LEVEL_TYPE.CHASE:
				self.ai_state = AI_STATE.SEARCH
			Rfs.current_level.LEVEL_TYPE.RACE_GOAL:
				goals_to_reach = Rfs.current_level.level_goals.duplicate()
				if Rfs.current_level.level_finish:
					goals_to_reach.append(Rfs.current_level.level_finish)
				self.ai_state = AI_STATE.RACE_TO_GOAL
	else:
		#		printt ("game on SMS", new_game_state)
		self.ai_state = AI_STATE.OFF
		controlled_bolt.motion = controlled_bolt.MOTION.IDLE


func _on_NavigationAgent2D_path_changed() -> void:
#	print("nav path changed")

	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_target_reached() -> void:
#	print("nav target reached")

		if ai_state == AI_STATE.MOUSE_CLICK:
			var nav_path_points: PoolVector2Array = level_navigation._update_navigation_path(controlled_bolt.global_position, current_mouse_follow_point)
			ai_target = Mts.spawn_indikator(nav_path_points[0], Color.blue, 0, Rfs.node_creation_parent)
			navigation_agent.set_target_location(nav_path_points[0])
			ai_state = AI_STATE.MOUSE_CLICK

		elif ai_state == AI_STATE.SEARCH:
			search_target_reached = true


func _on_NavigationAgent2D_navigation_finished() -> void:
#	print("nav finished")
	pass


func _on_NavigationAgent2D_velocity_computed(safe_velocity: Vector2) -> void: # za avoidance

	var new_position: Vector2= navigation_agent.get_next_location()
	navigation_agent.set_target_location(new_position)
	navigation_agent.set_velocity(controlled_bolt.bolt_velocity)

	print("avoided")





# OBS --------------------------------------

