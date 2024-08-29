extends Bolt

enum AiStates {IDLE, RACE, SEEK, FOLLOW, HUNT}
enum AiAttackingMode {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}

var current_ai_state: int = AiStates.IDLE
var current_attacking_mode: int = AiAttackingMode.NONE

onready var navigation_agent = $NavigationAgent2D
onready var detect_ray = $DetectRay
onready var vision_ray = $VisionRay
onready var target_ray: RayCast2D = $TargetRay
onready var detect_area: Area2D = $DetectArea

var ai_target: Node2D = null
var level_navigation_positions: Array # poda GM ob spawnu
var ai_navigation_line: Line2D # debug

onready var max_engine_power = Pro.ai_profile["max_engine_power"] # 80
onready var searching_engine_power = max_engine_power * 0.8 

# neu
# ai settings .. v Profile
var ai_brake_distance_factor: float = 0.5 # delež dolžine vektorja hitrosti ... vision ray je na tej dolžini
var ai_brake_factor: float = 0.8 # množenje s hitrostjo
var ai_closeup_distance: float = 70
var ai_urgent_stop_distance: float = 20
var ai_target_min_distance: float = 70
var ai_target_max_distance: float = 120
onready var edge_navigation_tilemap: TileMap = Ref.current_level.tilemap_edge
var valid_target_group: String = "valid_target_group"	
var last_follow_target_position: Vector2
var target_ray_angle_limit: float = 30
var target_ray_seek_length: float = 320
var target_ray_rotation_speed: float = 1

onready var freee: bool = true

func _ready() -> void:
	
	add_to_group(Ref.group_ai)
	#	bolt_hud.hide()
	
	# debug ... spawn navigation line
	ai_navigation_line = Line2D.new()
	Ref.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = bolt_color
	ai_navigation_line.z_index = 10
#	ai_navigation_line.hide()
	randomize()
	

func _physics_process(delta: float) -> void:
	
	if not bolt_active:
		return

	manage_ai_states(delta)
	
	if current_motion_state == MotionStates.DISARRAY:
		ai_target = null
	else:
		if ai_target == null and not current_ai_state == AiStates.IDLE: # setanje tarče za konec dissaraya
			set_ai_target(edge_navigation_tilemap)
		var next_position: Vector2 = navigation_agent.get_next_location()
		acceleration = position.direction_to(next_position) * engine_power
		steering(delta) # more bi pred rotacijo, da se upošteva ... ne vem če kaj vpliva
		rotation = velocity.angle()
		# vision
		vision_ray.cast_to.x = velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
		if vision_ray.is_colliding():
			velocity *= ai_brake_factor

	
func manage_ai_states(delta: float):
	
	# če node tarče še obstaja, ga pošlje v SEEK mode
	if not get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe
		set_ai_target(edge_navigation_tilemap)	
		return
			
	match current_ai_state:
		
		AiStates.IDLE: 
			# miruje s prižganim motorjem
			# target = null	
			engine_power = 0
		
		AiStates.RACE: 
			# šiba po najbližji poti do tarče
			# target = position tracker
			navigation_agent.set_target_location(get_racing_position(ai_target))
			engine_power = max_engine_power	
		
		AiStates.SEEK: 
			# išče novo tarčo, dokler je ne najde
			# target = edge_navigation_tilemap
			var possible_targets: Array = get_possible_targets()
			if not possible_targets.empty():
				if "ai_target_rank" in ai_target:
					var best_target_rank: int = possible_targets[0].ai_target_rank 
					if best_target_rank > ai_target.ai_target_rank:
						set_ai_target(possible_targets[0]) # postane HUNT
				else:
					set_ai_target(possible_targets[0]) # postane HUNT
			engine_power = max_engine_power
	
		AiStates.FOLLOW: 
			# sledi tarči, dokler se ji ne približa ... če je ne vidi ima problem
			# target = bolt
			# apdejt pozicije tarče, če se premika
			if not navigation_agent.get_target_location() == ai_target.global_position: 
				navigation_agent.set_target_location(ai_target.global_position)
				# sharanjujem zadnjo pozicijo, da lažje sledim
				last_follow_target_position = ai_target.global_position
			# regulacija hitrosti
			target_ray.look_at(ai_target.global_position)
			var ray_velocity_length: float = global_position.distance_to(ai_target.global_position)
			target_ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				velocity *= ai_brake_factor
				engine_power = 0.1 # če je čista 0 se noče vrtet 
			elif ray_velocity_length < ai_closeup_distance:
				var brake_factor: float = 0.95
				velocity *= ai_brake_factor
				engine_power = max_engine_power
			else:
				engine_power = max_engine_power	
			# loose target on vision breaker, gre v SEEK mode
			if (target_ray.is_colliding() and target_ray.get_collider() == edge_navigation_tilemap) or ai_target == null:
				set_ai_target(edge_navigation_tilemap)
		
		AiStates.HUNT: 
			# pobere tarčo, ki jo je videl ... ne izgubi pogleda
			# tarča = level object
			# apdejt pozicije tarče, če se premika
			if not navigation_agent.get_target_location() == ai_target.global_position: 
				navigation_agent.set_target_location(ai_target.global_position)			
			# regulacija hitrosti
			target_ray.look_at(ai_target.global_position)
			var ray_velocity_length: float = global_position.distance_to(ai_target.global_position)
			target_ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				var brake_factor: float = 0.95
				velocity *= ai_brake_factor			
			engine_power = max_engine_power
			# gleda za boljšo tarčo
			#			var possible_targets: Array = get_possible_targets()
			#			if not possible_targets.empty():
			#				if possible_targets[0].ai_target_rank > ai_target.ai_target_rank:
			#					set_ai_target(possible_targets[0]) # postane HUNT ali follow		
			if ai_target == null:
				set_ai_target(edge_navigation_tilemap)
	
	# printt("Current state: %s" % AiStates.keys()[current_ai_state], ai_target)
	
	# če tarča ni več d
	if ai_target and not navigation_agent.is_target_reachable(): # sanira tudi bug, ker je lahko izbran kakšen za steno
		set_ai_target(edge_navigation_tilemap)	
	
		
func set_ai_target(new_ai_target: Node2D):
	
	detect_ray.enabled = false
	target_ray.enabled = false
	
	# reset "valid target" grupe
	if get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe in ne tarče, ki je lahko že ne obstaja več
		ai_target.remove_from_group(valid_target_group)
	
	if new_ai_target is Bolt: # debug
		# printt("start FOLLOW from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		current_ai_state = AiStates.FOLLOW
	
	elif new_ai_target is Pickable:		
		# printt("start HUNT from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		navigation_agent.set_target_location(new_ai_target.global_position)
		current_ai_state = AiStates.HUNT
	
	elif new_ai_target is PathFollow2D:
		# printt("start RACE from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AiStates.RACE	
	
	elif new_ai_target == edge_navigation_tilemap:
		# printt("start SEEK from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		detect_ray.enabled = true
		target_ray.enabled = true
		var target_navigation_cell_position: Vector2 = Vector2.ZERO
		# če je bil FOLLOW je nova tarča na zadnji vidni lokaciji stare tarče, drugače je random nav cell
		if freee:
			target_navigation_cell_position = get_nav_cell_on_distance(global_position,150, 1000)
			navigation_agent.set_target_location(target_navigation_cell_position)
		else:
			if current_ai_state == AiStates.FOLLOW:
				target_navigation_cell_position = get_nav_cell_on_distance(last_follow_target_position)
			else:
				target_navigation_cell_position = get_nav_cell_on_distance(global_position, ai_target_min_distance, ai_target_max_distance)
			navigation_agent.set_target_location(target_navigation_cell_position)
		current_ai_state = AiStates.SEEK
	
	elif new_ai_target == null:
		
		printt("start IDLE from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AiStates.IDLE
	
	# apliciram target in ga dam v "valid target" grupo
	ai_target = new_ai_target	
	ai_target.add_to_group(valid_target_group)
	

# PER STATE ----------------------------------------------------------------------------------------------


func get_possible_targets():
	
	# detect area nabira
	var all_possible_targets: Array = detect_area.get_overlapping_bodies()
	all_possible_targets.append_array(detect_area.get_overlapping_areas())
	
	# izločim sebe in rank = 0
	all_possible_targets.erase(self)
	for target in all_possible_targets:
		if target.ai_target_rank == 0:
			all_possible_targets.erase(target)
	
	# target ray rotira in nabira
	target_ray.cast_to.x = target_ray_seek_length
	target_ray.rotation_degrees += target_ray_rotation_speed
	if target_ray.rotation_degrees > target_ray_angle_limit:
		target_ray.rotation_degrees = -target_ray_angle_limit	
	if target_ray.is_colliding() and not target_ray.get_collider() == edge_navigation_tilemap:
		all_possible_targets.append(target_ray.get_collider())
	
	# če ni tarče 
	if all_possible_targets.empty():
		return all_possible_targets
	
	# rangiram po ranku
	all_possible_targets.sort_custom(self, "sort_objects_by_ai_rank")
	# rangiram po potrebi
	#	if player_stats["bullet_count"] == 0 and player_stats["misile_count"] == 0:
	#		for target in all_possible_targets:
	#			if "pickable_key" in target:
	#				if target.pickable_key == Pro.Weapons.BULLET or target.pickable_key == Pro.Weapons.MISILE:
	#					all_possible_targets.push_front(target)
	# rangiram po distanci
	
	# detect ray preveri, če so tarče za steno
	var targets_behind_wall: Array = []
	for possible_target in all_possible_targets:
		detect_ray.force_raycast_update()
		detect_ray.look_at(possible_target.global_position)
		var detect_ray_length: float = global_position.distance_to(possible_target.global_position)
		detect_ray.cast_to.x = detect_ray_length
		if detect_ray.is_colliding() and detect_ray.get_collider() == edge_navigation_tilemap:
			targets_behind_wall.append(possible_target)
			# printt("walled", Pro.Pickables.keys()[possible_target.pickable_key])
	for target_behind_wall in targets_behind_wall:
		all_possible_targets.erase(target_behind_wall)
	
	# if not all_possible_targets.empty():
	#	printt("all targets %s" % all_possible_targets.size(), "walled targets %s" % targets_behind_wall.size(), "selected target %s" % Pro.Pickables.keys()[all_possible_targets[0].pickable_key])
	
	return all_possible_targets


func sort_objects_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši
	
	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false

	
func get_nav_cell_on_distance(from_position: Vector2, min_distance: float = 0, max_distance: float = 50, in_front: bool = true):
	
#	var selected_nav_position: Vector2
#	if freee:
#		var all_cells_for_random_selection: Array = []
#		pass
#
#	else:
		var selected_nav_position: Vector2
		var all_cells_for_random_selection: Array = []
		var front_cells_for_random_selection: Array = []
		var side_cells_for_random_selection: Array = []
		
		# random select, če ne iščem do 0
		var random_select: bool = true
		if min_distance == 0:
			in_front = false
			random_select = false
			
		var current_min_cell_distance: float = 0
		var current_min_cell_angle: float = 0
		
		# debug
		if not Met.all_indikators_spawned.empty():
			for n in Met.all_indikators_spawned:
				n.queue_free()
			Met.all_indikators_spawned.clear()
		
		for nav_position in level_navigation_positions:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			# najprej izbere vse po razponu
			if current_cell_distance > min_distance and current_cell_distance < max_distance:
				if in_front:
					var vector_to_position: Vector2 = nav_position - global_position
					var current_angle_to_bolt_deg: float = rad2deg(get_angle_to(nav_position))
					# če je najbolj spredaj
					#				var indi = Met.spawn_indikator(nav_position, global_rotation, Ref.node_creation_parent, false)
					if current_angle_to_bolt_deg < 30  and current_angle_to_bolt_deg > - 30 :
						front_cells_for_random_selection.append(nav_position)
					# če je na straneh
					elif current_angle_to_bolt_deg < 90  and current_angle_to_bolt_deg > -90 :
						side_cells_for_random_selection.append(nav_position)
					#					indi.modulate = Color.black
					# če ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position)
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
				selected_nav_position = Met.get_random_member(side_cells_for_random_selection)
			else:
				selected_nav_position = Met.get_random_member(front_cells_for_random_selection)
		elif random_select:
			selected_nav_position = Met.get_random_member(all_cells_for_random_selection)
			
		return selected_nav_position

	
func get_navigation_position_on_distance(from_position: Vector2, min_distance: float = 0, max_distance: float = 50, in_front: bool = true):
	
	var selected_nav_position: Vector2
	var all_cells_for_random_selection: Array = []
	var front_cells_for_random_selection: Array = []
	var side_cells_for_random_selection: Array = []
	
	# random select, če ne iščem do 0
	var random_select: bool = true
	if min_distance == 0:
		in_front = false
		random_select = false
		
	var current_min_cell_distance: float = 0
	var current_min_cell_angle: float = 0
	
	# debug
	if not Met.all_indikators_spawned.empty():
		for n in Met.all_indikators_spawned:
			n.queue_free()
		Met.all_indikators_spawned.clear()
	
	for nav_position in level_navigation_positions:
		var current_cell_distance: float = nav_position.distance_to(from_position)
		# najprej izbere vse po razponu
		if current_cell_distance > min_distance and current_cell_distance < max_distance:
			if in_front:
				var vector_to_position: Vector2 = nav_position - global_position
				var current_angle_to_bolt_deg: float = rad2deg(get_angle_to(nav_position))
				# če je najbolj spredaj
				#				var indi = Met.spawn_indikator(nav_position, global_rotation, Ref.node_creation_parent, false)
				if current_angle_to_bolt_deg < 30  and current_angle_to_bolt_deg > - 30 :
					front_cells_for_random_selection.append(nav_position)
				# če je na straneh
				elif current_angle_to_bolt_deg < 90  and current_angle_to_bolt_deg > -90 :
					side_cells_for_random_selection.append(nav_position)
				#					indi.modulate = Color.black
				# če ni v razponu kota
				else:
					all_cells_for_random_selection.append(nav_position)
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
			selected_nav_position = Met.get_random_member(side_cells_for_random_selection)
		else:
			selected_nav_position = Met.get_random_member(front_cells_for_random_selection)
	elif random_select:
		selected_nav_position = Met.get_random_member(all_cells_for_random_selection)
		
	return selected_nav_position


func get_racing_position(position_tracker: PathFollow2D):
	
	var ai_target_point_on_curve: Vector2
	var ai_target_prediction: float = 50
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var bolt_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	ai_target_point_on_curve = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)
	
	return ai_target_point_on_curve
		

# SIGNALI ------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void: # debug
	
	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_navigation_finished() -> void:
	
	print("nav reached")
	
	if current_ai_state == AiStates.SEEK:
#		if freee:
#			set_ai_target(edge_navigation_tilemap)	
#		else:
			set_ai_target(edge_navigation_tilemap)	
	
	
func _on_NavigationAgent2D_target_reached() -> void:
	
	print("target reached")
	#	if current_ai_state == AiStates.HUNT:
	#		set_ai_target(edge_navigation_tilemap)	
	pass
