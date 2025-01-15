extends Node


enum AI_STATE {IDLE, RACE, SEARCH, FOLLOW, HUNT, MOUSE_FOLLOW}
var current_ai_state: int = AI_STATE.IDLE # !!! stanja se setajo samo s tarčami

enum BATTLE_STATE {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}
var current_battle_state: int = BATTLE_STATE.NONE

# seta spawner
var controlled_bolt: RigidBody2D
var controller_type: int

# nodes
onready var navigation_agent = $NavigationAgent2D
onready var detect_ray = $DetectRay
onready var vision_ray = $VisionRay
onready var target_ray: RayCast2D = $TargetRay
onready var detect_area: Area2D = $DetectArea

# navigacija
var ai_target: Node2D = null
var level_navigation_positions: Array # poda GM ob spawnu
var ai_navigation_line: Line2D

# motion
var ai_brake_distance_factor: float = 0.5 # delež dolžine vektorja hitrosti ... vision ray je na tej dolžini
var ai_brake_factor: float = 0.8 # množenje s hitrostjo
var ai_closeup_distance: float = 70
var ai_urgent_stop_distance: float = 20
var ai_navigation_target_range: Array = [50, 300] # min dist 0 pomeni iskanje najbližja možna
var valid_target_group: String = "valid_target_group"
var last_follow_target_position: Vector2
var target_ray_angle_limit: float = 30
var target_ray_seek_length: float = 320
var target_ray_rotation_speed: float = 1
var braking_velocity: Vector2
onready var level_navigation_target: NavigationPolygonInstance = Refs.current_level.level_navigation

# debug
onready var direction_line: Line2D = $DirectionLine

# hitrosti ... še ni v uporabi
var closeup_engine_power
var search_engine_power
var hold_engine_power

var nav_target_position: Vector2 = Vector2.ZERO
var mina_released: bool # trenutno ne uporabljam ... če je že odvržen v trenutni ožini


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"): # idle
		Refs.temp_object.navigation_obstacle_2d.set_navigation(navigation_agent)
#		set_ai_target(null)
	if Input.is_action_just_pressed("no2"): # race
		set_ai_target(controlled_bolt.bolt_position_tracker)
	if Input.is_action_just_pressed("no3"):
		set_ai_target(level_navigation_target)
	if Input.is_action_just_pressed("no4"): # follow leader
		set_ai_target(controlled_bolt.bolt_position_tracker)
#		set_ai_target(Refs.game_manager.camera_leader)
	elif Input.is_action_just_pressed("left_click"): # follow leader
		var ind_pos = level_navigation_target._update_navigation_path(controlled_bolt.bolt_global_position, level_navigation_target.get_local_mouse_position())
		var indi = Mets.spawn_indikator(ind_pos[0], Color.blue, 0, Refs.node_creation_parent)
#		navigation_agent.set_target_location(level_navigation_target.get_local_mouse_position())
		set_ai_target(indi)
		MOUSE_FOLLOW_pos = ind_pos[ind_pos.size()-1]
#		get_viewport().get_mouse_position()
#		set_ai_target(indi)
#		current_ai_state = AI_STATE.HUNT


func _ready() -> void:

	randomize()

	ai_navigation_line = Line2D.new()
	Refs.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = Color.red
	ai_navigation_line.z_index = 10

	controlled_bolt.add_to_group(Refs.group_ai)
	controlled_bolt.current_motion = controlled_bolt.MOTION.FWD # debug preset motion

	detect_ray.add_exception(controlled_bolt)
	target_ray.add_exception(controlled_bolt)
	vision_ray.add_exception(controlled_bolt)


func _physics_process(delta: float) -> void:

	# ko je aktiven dela state_mašina (IDLE), ne pa tudi pogon
	if controlled_bolt.is_active:

		ai_state_machine(delta)

		# dokler ni igre je in kadar je input off je IDLE, drugače je akcija
		if Refs.game_manager.game_on:
			if is_processing_input():
				if ai_target == null and not current_ai_state == AI_STATE.IDLE: # setanje tarče za konec dissaraya
					set_ai_target(level_navigation_target)
			else:
				set_ai_target(null) # postane IDLE
		else:
			set_ai_target(null)

		# rotacija sile proti tarči
		var current_target_position: Vector2
		if ai_target == level_navigation_target:
			current_target_position = nav_target_position
		# > namesto SPODAJ
#		else:
		elif ai_target:
			if current_ai_state == AI_STATE.RACE:
				current_target_position = get_racing_position(controlled_bolt.bolt_position_tracker)
			else:
				current_target_position = ai_target.global_position
		var vector_to_target: Vector2 = current_target_position - controlled_bolt.bolt_global_position
		direction_line.set_point_position(0, Vector2.ZERO)
		direction_line.set_point_position(1, vector_to_target.rotated(- controlled_bolt.bolt_global_rotation))
		printt("current_target_position", current_target_position, vector_to_target.rotated(- controlled_bolt.bolt_global_rotation))
		controlled_bolt.force_rotation = Vector2.ZERO.angle_to_point(- vector_to_target)


func ai_state_machine(delta: float): # !!! AI_STATE se seta samo s tarčami
#	print ("current_ai_state", AI_STATE.keys()[current_ai_state])

	# > ZGORAJ namesto
	# če node tarče še obstaja, ga pošlje v SEARCH mode
	#	if not get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe
	#		set_ai_target(level_navigation_target)
	#		return

	# MOTNJA
	# če je tarča in je nedosgljiva zamenjaj setaj search tarčo
#	if ai_target and not navigation_agent.is_target_reachable(): # sanira tudi bug, ker je lahko izbran kakšen za steno
#		set_ai_target(level_navigation_target)


	print("ai target", ai_target)
	match current_ai_state:

		AI_STATE.IDLE: # target = null ... miruje s prižganim motorjem
			controlled_bolt.engine_power = 0

		AI_STATE.RACE: # šiba po najbližji poti do tarče ... target = position tracker
#			update_vision()
			var racing_line_point_position: Vector2 = get_racing_position(ai_target)
			Mets.spawn_indikator(racing_line_point_position, Color.white, controlled_bolt.rotation, Refs.node_creation_parent)

			navigation_agent.set_target_location(racing_line_point_position)
#			navigation_agent.set_target_location(ai_target.global_position)
			printt("pos", racing_line_point_position, ai_target.global_position)
#			if not racing_line_point_position == ai_target.global_position:
			controlled_bolt.engine_power = controlled_bolt.max_engine_power/2
#			var dotko = controlled_bolt.get_angle_to(racing_line_point_position)
#			if dotko < 0:
#				controlled_bolt.rotation_dir = 1
#			elif dotko > 0:
#				controlled_bolt.rotation_dir = -1
#			else:
#				controlled_bolt.rotation_dir = 0
#
#			printt ("dotko",  dotko)
#			controlled_bolt.bolt_shift = 1
#			controlled_bolt.current_motion = controlled_bolt.MOTION.FWD
		AI_STATE.SEARCH: # target = level_navigation ... vozi po navigaciji in išče novo tarčo, dokler je ne najde
			controlled_bolt.engine_power = 150 # drži samo dokler je setana, zato nitreba resetirat
			update_vision()
			# iščem tarčo
			var possible_targets: Array = get_possible_targets()
			# če ni tarče, se peljem dalje
			if not possible_targets.empty():
				set_ai_target(possible_targets[0]) # postane HUNT

		AI_STATE.FOLLOW: # target = bolt oz. karkoli drugega .... sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			# apdejt pozicije tarče, če se premika
			var ai_target_global_position: Vector2 = ai_target.global_position
			if ai_target.is_in_group(Refs.group_bolts):
				ai_target_global_position =  ai_target.bolt_global_position
#			if not navigation_agent.get_target_location() == ai_target.bolt_global_position:
#				navigation_agent.set_target_location(ai_target.bolt_global_position)
#				last_follow_target_position = ai_target.bolt_global_position # shranjujem zadnjo pozicijo, če ga izgubim
			if not navigation_agent.get_target_location() == ai_target_global_position:
				navigation_agent.set_target_location(ai_target_global_position)
				last_follow_target_position = ai_target_global_position # shranjujem zadnjo pozicijo, če ga izgubim

			# bremzanje
#			target_ray.look_at(ai_target.global_position)
			target_ray.look_at(ai_target_global_position)
#			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(ai_target.bolt_global_position)
			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(ai_target_global_position)
			target_ray.cast_to.x = ray_velocity_length
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
			# lose target on vision breaker, gre v SEARCH mode
			if (target_ray.is_colliding() and target_ray.get_collider() == level_navigation_target) or ai_target == null:
				set_ai_target(level_navigation_target)
		AI_STATE.HUNT: # target = level object (statični) ... pobere tarčo, ki jo je videl ... ne izgubi pogleda
			# apdejt pozicije tarče, če se premika
			if not navigation_agent.get_target_location() == ai_target.global_position:
				navigation_agent.set_target_location(ai_target.global_position)
			# bremzanje
			target_ray.look_at(ai_target.global_position)
			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(ai_target.global_position)
			target_ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				var brake_factor: float = 0.95
				braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
				controlled_bolt.set_linear_velocity(braking_velocity)

			# če obstaja druga tarča izberem tisto, ki rangira najbolje
			var possible_targets: Array = get_possible_targets()
			if not possible_targets.empty():
				if possible_targets[0].ai_target_rank > ai_target.ai_target_rank:
					set_ai_target(possible_targets[0]) # menja tarčo

		AI_STATE.MOUSE_FOLLOW: # target = bolt oz. karkoli drugega .... sledi tarči, dokler se ji ne približa (če je ne vidi ima problem)
			# apdejt pozicije tarče, če se premika
			var ai_target_global_position: Vector2 = ai_target.global_position
			if ai_target.is_in_group(Refs.group_bolts):
				ai_target_global_position =  ai_target.bolt_global_position
#			if not navigation_agent.get_target_location() == ai_target.bolt_global_position:
#				navigation_agent.set_target_location(ai_target.bolt_global_position)
#				last_follow_target_position = ai_target.bolt_global_position # shranjujem zadnjo pozicijo, če ga izgubim
			if not navigation_agent.get_target_location() == ai_target_global_position:
				navigation_agent.set_target_location(ai_target_global_position)
				last_follow_target_position = ai_target_global_position # shranjujem zadnjo pozicijo, če ga izgubim

#			# bremzanje
#			target_ray.look_at(ai_target.global_position)
			target_ray.look_at(ai_target_global_position)
#			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(ai_target.bolt_global_position)
			var ray_velocity_length: float = controlled_bolt.bolt_global_position.distance_to(ai_target_global_position)
			target_ray.cast_to.x = ray_velocity_length
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
			# lose target on vision breaker, gre v SEARCH mode
#			if (target_ray.is_colliding() and target_ray.get_collider() == level_navigation_target) or ai_target == null:
#				set_ai_target(level_navigation_target)



func set_ai_target(new_ai_target: Node2D):

	#reset
	detect_ray.enabled = false
	target_ray.enabled = false
	nav_target_position = Vector2.ZERO
	# reset "valid target" grupe
	if get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe in ne tarče, ki je lahko že ne obstaja več
		ai_target.remove_from_group(valid_target_group)

	# FOLLOW
	if new_ai_target is Bolt:
		#		printt("start FOLLOW from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		current_ai_state = AI_STATE.FOLLOW

	# HUNT
	elif new_ai_target is Pickable:
		#		printt("start HUNT from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		navigation_agent.set_target_location(new_ai_target.global_position)
		current_ai_state = AI_STATE.HUNT

	# RACE
	elif new_ai_target is PathFollow2D:
		#		printt("start RACE from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AI_STATE.RACE

	# SEARCH
	elif new_ai_target == level_navigation_target:
		#		printt("start SEARCH from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		detect_ray.enabled = true
		target_ray.enabled = true
		# če je bil FOLLOW je nova tarča na zadnji vidni lokaciji stare tarče, drugače je random nav cell
		if current_ai_state == AI_STATE.FOLLOW:
			nav_target_position = get_nav_position_on_distance(last_follow_target_position)
		else:
			nav_target_position = get_nav_position_on_distance(controlled_bolt.bolt_global_position, ai_navigation_target_range)
		navigation_agent.set_target_location(nav_target_position)
		current_ai_state = AI_STATE.SEARCH

	# IDLE
	elif new_ai_target == null:
		#		printt("start IDLE from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AI_STATE.IDLE

	# debug ... mouseklik
	else:
		#		printt("start HUNT from %s" % AI_STATE.keys()[current_ai_state], "new_target: %s" % new_ai_target)
#		target_ray.enabled = true
		navigation_agent.set_target_location(new_ai_target.global_position)
		current_ai_state = AI_STATE.MOUSE_FOLLOW

	# apliciram target in ga dam v "valid target" grupo
	ai_target = new_ai_target
	if ai_target:
		ai_target.add_to_group(valid_target_group)


# UTILITI ----------------------------------------------------------------------------------------------


# SEARCH
func get_possible_targets(): # SEARCH

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
	if detect_ray.is_colliding() and not detect_ray.get_collider() == level_navigation_target:
		all_possible_targets.append(detect_ray.get_collider())
	#	# target ray rotira in nabira
	#	target_ray.cast_to.x = target_ray_seek_length
	#	target_ray.rotation_degrees += target_ray_rotation_speed
	#	if target_ray.rotation_degrees > target_ray_angle_limit:
	#		target_ray.rotation_degrees = -target_ray_angle_limit
	#	if target_ray.is_colliding() and not target_ray.get_collider() == level_navigation_target:
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
	all_possible_targets.sort_custom(self, "sort_objects_by_ai_rank")
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
		if target_ray.is_colliding() and target_ray.get_collider() == level_navigation_target:
			targets_behind_wall.append(possible_target)
	#	var targets_behind_wall: Array = []
	#	for possible_target in all_possible_targets:
	#		detect_ray.force_raycast_update()
	#		detect_ray.look_at(possible_target.global_position)
	#		var detect_ray_length: float = controlled_bolt.bolt_global_position.distance_to(possible_target.global_position)
	#		detect_ray.cast_to.x = detect_ray_length
	#		if detect_ray.is_colliding() and detect_ray.get_collider() == level_navigation_target:
	#			targets_behind_wall.append(possible_target)
	#			# printt("walled", Pros.PICKABLE.keys()[possible_target.pickable_key])



	for target_behind_wall in targets_behind_wall:
		all_possible_targets.erase(target_behind_wall)

	# if not all_possible_targets.empty():
	#	printt("all targets %s" % all_possible_targets.size(), "walled targets %s" % targets_behind_wall.size(), "selected target %s" % Pros.PICKABLE.keys()[all_possible_targets[0].pickable_key])

	return all_possible_targets


# SEARCH
func sort_objects_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši

	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false


# SEARCH
func get_nav_position_on_distance(from_position: Vector2, distance_range: Array = [0, 50], in_front: bool = true):

	if level_navigation_positions.empty():
		print("empty", level_navigation_positions.size(), Refs.current_level.navigation_cells_positions.size(), Refs.current_level.level_navigation.level_navigation_points.size())
		return
	var selected_nav_position: Vector2
	var all_cells_for_random_selection: Array = []
	var front_cells_for_random_selection: Array = []
	var side_cells_for_random_selection: Array = []
	var min_distance: float = distance_range[0]
	var max_distance: float = distance_range[1]

	# random select samo, če ne iščem do 0 (najbližja možna)
	var random_select: bool = true
	if min_distance == 0:
		in_front = false
		random_select = false

	var current_min_cell_distance: float = 0
	var current_min_cell_angle: float = 0

	if not Mets.all_indikators_spawned.empty():
		for n in Mets.all_indikators_spawned:
			n.queue_free()
		Mets.all_indikators_spawned.clear()

	for nav_position in level_navigation_positions:
		var current_cell_distance: float = nav_position.distance_to(from_position)
		# najprej izbere vse po razponu
		if current_cell_distance > min_distance and current_cell_distance < max_distance:
			if in_front:
				var vector_to_position: Vector2 = nav_position - controlled_bolt.bolt_global_position
				var current_angle_to_bolt_deg: float = rad2deg(controlled_bolt.get_angle_to(nav_position))
				# če je najbolj spredaj
				#				var indi = Mets.spawn_indikator(nav_position, global_rotation, Refs.node_creation_parent, false)
				if current_angle_to_bolt_deg < 30  and current_angle_to_bolt_deg > - 30 :
					front_cells_for_random_selection.append(nav_position)
#					# debug ind
					var indi = Mets.spawn_indikator(nav_position, Color.red, controlled_bolt.rotation, Refs.node_creation_parent)
#					indi.modulate = Color.yellow
				# če je na straneh
				elif current_angle_to_bolt_deg < 90  and current_angle_to_bolt_deg > -90 :
					side_cells_for_random_selection.append(nav_position)
					#					# debug ind
					#					var indi = Mets.spawn_indikator(nav_position, Color.red, controlled_bolt.rotation, Refs.node_creation_parent)
					#					indi.modulate = Color.blue
				# če ni v razponu kota
				else:
					all_cells_for_random_selection.append(nav_position)
					#					# debug ind
					#					var indi = Mets.spawn_indikator(nav_position, Color.red, controlled_bolt.rotation, Refs.node_creation_parent)
					#					indi.modulate = Color.green
			else:
				# random select, samo nabiram za žrebanje,
				if random_select:
					all_cells_for_random_selection.append(nav_position)
				# izberem najbližjo
				else:
					if current_cell_distance < current_min_cell_distance or current_min_cell_distance == 0:
						current_min_cell_distance = current_cell_distance
						selected_nav_position = nav_position

	# žrebam iz sprednjih ali vseh na voljo
	if front_cells_for_random_selection.empty() and side_cells_for_random_selection.empty():
		in_front = false
	if in_front:
		if front_cells_for_random_selection.empty():
			selected_nav_position = Mets.get_random_member(side_cells_for_random_selection)
		else:
			selected_nav_position = Mets.get_random_member(front_cells_for_random_selection)
	elif random_select:
		selected_nav_position = Mets.get_random_member(all_cells_for_random_selection)

	return selected_nav_position


# RACE
func get_racing_position(position_tracker: PathFollow2D):

	var point_on_curve_global_position: Vector2
	var ai_target_prediction: float = 500
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var bolt_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	point_on_curve_global_position = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)

	return point_on_curve_global_position


func update_vision():

	vision_ray.cast_to.x = controlled_bolt.bolt_velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
	if vision_ray.is_colliding():
		braking_velocity = controlled_bolt.bolt_velocity * ai_brake_factor
		controlled_bolt.set_linear_velocity(braking_velocity)


func in_disarray(damage_amount: float): # 5 raketa, 1 metk
	# drugačen smisel ... to je stvar, ko težko voziš ... dodaš "čudne" sile

#	current_motion = MotionStates.DISARRAY
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
#	current_motion = MotionStates.IDLE
	pass


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void:
	print("nav changed")

	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_navigation_finished() -> void:

	print("nav reached")
	if current_ai_state == AI_STATE.SEARCH:
		set_ai_target(level_navigation_target)
##	elif current_ai_state == AI_STATE.RACE:
##		set_ai_target(controlled_bolt.bolt_position_tracker.global_position)
#
#	elif current_ai_state == AI_STATE.MOUSE_FOLLOW:
#		var ind_pos = level_navigation_target._update_navigation_path(controlled_bolt.bolt_global_position, level_navigation_target.get_local_mouse_position())
#		var indi = Mets.spawn_indikator(ind_pos[0], Color.blue, 0, Refs.node_creation_parent)
##		navigation_agent.set_target_location(level_navigation_target.get_local_mouse_position())
##		set_ai_target(indi)
#		set_ai_target(indi)


var MOUSE_FOLLOW_pos: Vector2
func _on_NavigationAgent2D_target_reached() -> void:
#	current_ai_state = AI_STATE.MOUSE_FOLLOW
	if current_ai_state == AI_STATE.MOUSE_FOLLOW:
		var ind_pos = level_navigation_target._update_navigation_path(controlled_bolt.bolt_global_position, MOUSE_FOLLOW_pos)
		var indi = Mets.spawn_indikator(ind_pos[0], Color.blue, 0, Refs.node_creation_parent)
	#	var indi = Mets.spawn_indikator(level_navigation_target.get_local_mouse_position(), Color.blue, 0, Refs.node_creation_parent)
	#		navigation_agent.set_target_location(level_navigation_target.get_local_mouse_position())
	#		set_ai_target(indi)
		set_ai_target(indi)
#	navigation_agent.set_target_location(ind_pos[0])
#	elif current_ai_state == AI_STATE.RACE:
#		set_ai_target(controlled_bolt.bolt_position_tracker)
	print("target reached")
	#	if current_ai_state == AI_STATE.HUNT:
	#		set_ai_target(level_navigation_target)
	pass

