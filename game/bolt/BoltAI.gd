extends Bolt

enum AiStates {IDLE, RACE, SEARCH, FOLLOW, CHASE}
enum AiAttackingMode {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}

var current_ai_state: int = AiStates.IDLE
var current_attacking_mode: int = AiAttackingMode.NONE

onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray = $VisionRay
onready var follow_ray: RayCast2D = $CheckRay
onready var detect_area: Area2D = $DetectArea

var ai_target: Node2D
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
		
# neu
var ai_target_min_distance: float = 70
var ai_target_max_distance: float = 120
onready var edge_navigation_tilemap: TileMap = Ref.current_level.tilemap_edge
var seek_angle: float = 60
var seek_ray_length: float = 500
		

func _ready() -> void:
	
	add_to_group(Ref.group_ai)
	bolt_hud.hide()
	
	# debug ... spawn navigation line
	ai_navigation_line = Line2D.new()
	Ref.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = bolt_color

#	for ray in [$CheckRay, $SeekRay, $VisionRay]:
#		ray.add_exception(Ref.game_arena.screen_area)
#		ray.add_exception(Ref.game_arena.screen_edge)
#		ray.add_exception(Ref.current_level.checkpoint)
#		ray.add_exception(Ref.current_level.finish_line)
		# ray.add_exception(Ref.current_level.start_line)
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

	vision(delta)

	
func manage_ai_states(delta: float):

	match current_ai_state:
		
		AiStates.IDLE: # miruje s prižganim motorjem
			# target = null	
			engine_power = 0
			seek_ray.enabled = false
		
		AiStates.RACE: # šiba po najbližji poti do tarče
			# target = position tracker
			navigation_agent.set_target_location(get_racing_position(ai_target))
			engine_power = max_engine_power	
			seek_ray.enabled = false
		
		AiStates.SEARCH: # išče novo tarčo
			# target = edge_navigation_tilemap
			seek_ray.enabled = true
			var possible_targets: Array = get_detected_targets()
			if not possible_targets.empty():
				set_ai_target(possible_targets[0]) # postane CHASE
			engine_power = max_engine_power
		
		AiStates.FOLLOW: # sledi tarči, dokler se ji ne približa ... če je ne vidi ima problem
			# če se premika, navigacijo apdejtam s pozicijo tarče
			if not navigation_agent.get_target_location() == ai_target.global_position: 
				navigation_agent.set_target_location(ai_target.global_position)
			seek_ray.enabled = false
			follow_ray.enabled = true
			
			# regulacija hitrosti
			follow_ray.look_at(ai_target.global_position)
			var follow_ray_length: float = global_position.distance_to(ai_target.global_position)
			follow_ray.cast_to.x = follow_ray_length
			if follow_ray_length < ai_urgent_stop_distance:
				velocity *= ai_brake_factor
				engine_power = 0.1 # če je čista 0 se noče vrtet 
			elif follow_ray_length < ai_closeup_distance:
				engine_power = max_engine_power
				var ai_brake_factor: float = 0.95
				velocity *= ai_brake_factor
			else:
				engine_power = max_engine_power	
			
			# loose target, če je vsme vision breaker, gre v SEARCH mode
			if follow_ray.is_colliding():
				set_ai_target(edge_navigation_tilemap)
		
		AiStates.CHASE: # lovi tarčo dokler je ne ujame ... ne izgubi pogleda? ...
			# target = level element
			follow_ray.enabled = true
			seek_ray.enabled = true
			
			# follow ray spremlja tarčo
			follow_ray.look_at(ai_target.global_position)
			var follow_ray_length: float = global_position.distance_to(ai_target.global_position)
			follow_ray.cast_to.x = follow_ray_length
			
			# gleda za boljšo tarčo
#			var possible_targets: Array = get_detected_targets()
#			if not possible_targets.empty():
#				if possible_targets[0].ai_target_rank > ai_target.ai_target_rank:
#					set_ai_target(possible_targets[0]) # postane CHASE ali follow		
			
			engine_power = max_engine_power
			
			# loose target, če je vsme vision breaker, gre v SEARCH mode
			#			if follow_ray.is_colliding():
			#				set_ai_target(edge_navigation_tilemap)
		
#	printt("Current state: %s" % AiStates.keys()[current_ai_state], ai_target)


func get_detected_targets():
	
	# vsi zaznani objekti (na layerju ai_targets)
	var all_possible_targets: Array = detect_area.get_overlapping_bodies()
	all_possible_targets.append_array(detect_area.get_overlapping_areas())
	if all_possible_targets.empty():
		return all_possible_targets
	# rangiraj po ai ranku
	all_possible_targets.sort_custom(self, "sort_objects_by_ai_rank")
	
	# naberem tarče, ki niso vidne in jih zbrišem iz možnih tarč
	var targets_behind_wall: Array
	for possible_target in all_possible_targets:
		seek_ray.look_at(possible_target.global_position)
		var seek_ray_length: float = global_position.distance_to(possible_target.global_position)
		seek_ray.cast_to.x = seek_ray_length
		if seek_ray.is_colliding():
			targets_behind_wall.append(possible_target)
		seek_ray.force_raycast_update()
	for target_behind_wall in targets_behind_wall:
		all_possible_targets.erase(target_behind_wall)
	
	#	printt("all_possible_targets", targets_behind_wall.size(),all_possible_targets.size())
	
	return all_possible_targets
	
	
func set_ai_target(new_ai_target: Node2D):
	
	if new_ai_target is Bolt: # debug
#		print("start FOLLOW from %s" % AiStates.keys()[current_ai_state])
		current_ai_state = AiStates.FOLLOW
	
	elif new_ai_target is Pickable:		
		print("start element CHASE from %s" % AiStates.keys()[current_ai_state])
		current_ai_state = AiStates.CHASE
		navigation_agent.set_target_location(new_ai_target.global_position)
	
	elif new_ai_target is PathFollow2D:
		print("start RACE from %s" % AiStates.keys()[current_ai_state])
		current_ai_state = AiStates.RACE	
	
	elif new_ai_target == edge_navigation_tilemap:
		print("start SEARCH from %s" % AiStates.keys()[current_ai_state])
		var target_navigation_cell_position: Vector2 = Vector2.ZERO
		# če je bil FOLLOW je nova tarča na zadnji vidni lokaciji stare tarče, drugače je random nav cell
		if current_ai_state == AiStates.FOLLOW:
			var last_follow_target_position: Vector2 = ai_target.global_position
			target_navigation_cell_position = get_nav_cell_on_distance(last_follow_target_position)
		else:
			target_navigation_cell_position = get_nav_cell_on_distance(global_position, ai_target_min_distance, ai_target_max_distance)
		navigation_agent.set_target_location(target_navigation_cell_position)
		current_ai_state = AiStates.SEARCH
	
	elif new_ai_target == null:
		print("start IDLE from %s" % AiStates.keys()[current_ai_state])
		current_ai_state = AiStates.IDLE
	
	ai_target = new_ai_target	
	
	
func get_nav_cell_on_distance(from_position: Vector2, min_distance: float = 0, max_distance: float = 50, in_front: bool = true):
	
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
	
	
func select_target_on_priority(possible_target: Node2D):
	# plan
	# naberem vse element v vidnem polju, ki imajo ai_rank
	# dam jih v array in razporedim po prioriti ranku
	# potem vključim še razporejanje glede na razdaljo do tarče in smer proti glavnemu cilju
	
	# če dirkam
	match AiStates:
		AiStates.RACE:
			if possible_target.is_in_group(Ref.group_players):
				set_ai_target(possible_target)
		AiStates.SEARCH:
			if possible_target.is_in_group(Ref.group_players):
				set_ai_target(possible_target)


func sort_objects_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši
	
	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false
	

func vision(delta: float):
	
	vision_ray.cast_to.x = velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
	if vision_ray.is_colliding():
		velocity *= ai_brake_factor
		select_target_on_priority(vision_ray.get_collider())
	
		
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
#	return
#
	print("navigation finished")
	if current_ai_state == AiStates.SEARCH:
#	if current_ai_state == AiStates.SEARCH or current_ai_state == AiStates.CHASE:
		set_ai_target(edge_navigation_tilemap)	
#	elif current_ai_state == AiStates.CHASE:
#		set_ai_target(edge_navigation_tilemap)	
#	var new_navigation_cell_position: Vector2 = get_nav_cell_on_distance(global_position, ai_target_min_distance, ai_target_max_distance)
#	navigation_agent.set_target_location(new_navigation_cell_position)
	
	
func _on_NavigationAgent2D_target_reached() -> void:
	return
	print("target reached")
	if current_ai_state == AiStates.SEARCH:
#	if current_ai_state == AiStates.SEARCH or current_ai_state == AiStates.CHASE:
		set_ai_target(edge_navigation_tilemap)	
	elif current_ai_state == AiStates.CHASE:
		set_ai_target(edge_navigation_tilemap)	


	
func on_item_picked(pickable_key: int):

#	if pickable == ai_target:
	set_ai_target(edge_navigation_tilemap)	
		
		
#	var pickable_key: int = pickable.pickable_key
##	var pickable_key: int
#	var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
#
#	match pickable_key:
#		Pro.Pickables.PICKABLE_BULLET:
#			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#				player_stats["misile_count"] = 0
#				player_stats["mina_count"] = 0
#			update_stat("bullet_count", pickable_value)
#		Pro.Pickables.PICKABLE_MISILE:
#			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#				player_stats["bullet_count"] = 0
#				player_stats["mina_count"] = 0
#			update_stat("misile_count", pickable_value)
#		Pro.Pickables.PICKABLE_MINA:
#			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
#				player_stats["bullet_count"] = 0
#				player_stats["misile_count"] = 0
#			update_stat("mina_count", pickable_value)
#		Pro.Pickables.PICKABLE_SHIELD:
#			shield_loops_limit = pickable_value
#			activate_shield()
#		Pro.Pickables.PICKABLE_ENERGY:
#			player_stats["energy"] = max_energy
#		Pro.Pickables.PICKABLE_GAS:
#			update_stat("gas_count", pickable_value)
#		Pro.Pickables.PICKABLE_LIFE:
#			update_stat("life", pickable_value)
#		Pro.Pickables.PICKABLE_NITRO:
#			activate_nitro(pickable_value, Pro.pickable_profiles[pickable_key]["duration"])
#		Pro.Pickables.PICKABLE_TRACKING:
#			var default_traction = side_traction
#			side_traction = pickable_value
#			yield(get_tree().create_timer(Pro.pickable_profiles[pickable_key]["duration"]), "timeout")
#			side_traction = default_traction
#		Pro.Pickables.PICKABLE_POINTS:
#			update_bolt_points(pickable_value)
#		Pro.Pickables.PICKABLE_RANDOM:
#			var random_range: int = Pro.pickable_profiles.keys().size()
#			var random_pickable_index = randi() % random_range
#			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
#			on_item_picked(random_pickable_key) # pick selected
