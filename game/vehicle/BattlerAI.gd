extends Node2D

var vehicle: Vehicle # dobi od controllerja

enum BATTLE_STATE {NONE, GUN, TURRET, LAUNCHER, DROPPER, MALA}
var battle_state: int = BATTLE_STATE.NONE
enum SELECT_TARGET_BY {TARGET_RANK, LEVEL_RANK, GAME_RANK, DISTANCE, DEFENCE}

var available_items: Array = []
var is_shooting: bool = false
var selected_item_index = 0
onready var scanning_area: Area2D = $"../ScanningArea"
onready var scanning_ray: RayCast2D = $"../ScanningRay"
var level_navigation_points: Array = []


func _ready() -> void:
	pass


func use_selected_item():

	var all_equipment_ungrouped: Array = []
	var shooting_weapons: Array = []

	if not battle_state == BATTLE_STATE.NONE:

		var battle_state_key: String = BATTLE_STATE.find_key(battle_state)
		# naberem vsa setana orožja, ne glede na tip
		for weapon_type in vehicle.weapons_types_with_weapons:
			for weapon in vehicle.weapons_types_with_weapons[weapon_type]:
				all_equipment_ungrouped.append(weapon)

		# če so grupirana, izbere vse v grupi
		if vehicle.group_equipment_by_type:
			for weapon in vehicle.weapons_types_with_weapons[battle_state_key]:
				shooting_weapons.append(weapon)
		else:
		# če nispo grupirana, izbere prvega, ki še ima metke
			var WEAPON_TYPE: Dictionary = all_equipment_ungrouped.front().WEAPON_TYPE
			var selected_weapon_type: int = WEAPON_TYPE[battle_state_key]
			for weapon in all_equipment_ungrouped:
				if weapon.weapon_type == selected_weapon_type and weapon.load_count > 0:
					shooting_weapons.append(weapon)
					break

	# weapon ai ON/OFF
	for weapon in all_equipment_ungrouped:
		if weapon in shooting_weapons and weapon.use_ai:
			weapon.weapon_ai.ai_enabled = true
		else:
			weapon.weapon_ai.ai_enabled = false

	for weapon in shooting_weapons:
		weapon.on_weapon_triggered()


func shoot(new_battle_state: int = battle_state, shoot_till_stop_call: bool = false):

	if not new_battle_state == battle_state:

		battle_state = new_battle_state

		if BATTLE_STATE.NONE:
			is_shooting = false
		else:
			match battle_state:
				BATTLE_STATE.GUN:
					use_selected_item()
					pass
				BATTLE_STATE.TURRET:
					use_selected_item()
					pass
				BATTLE_STATE.LAUNCHER:
					use_selected_item()
					pass
				BATTLE_STATE.DROPPER:
					use_selected_item()
					pass
				BATTLE_STATE.MALA:
					use_selected_item()
					pass

			if shoot_till_stop_call:
				is_shooting = true


func select_item():

	selected_item_index += 1


func _get_better_targets(current_target: Node2D):

	# naberem vse možno v scanning območju
	var possible_targets: Array = scanning_area.get_overlapping_bodies()
	possible_targets.append_array(scanning_area.get_overlapping_areas())
	possible_targets.erase(vehicle) # izločim sebe

	# izfiltriram ai tarče
	var posssible_targets_with_rank: Array = []
	for possible_target in possible_targets:
		var targets_rank: int = _get_target_rank(possible_target)
		if targets_rank > 0:
			posssible_targets_with_rank.append([possible_target, targets_rank])

	# izfiltriram samo vidne (ray colajda samo starčo)
	var targets_in_sight: Array = []
	for target_and_rank in posssible_targets_with_rank:
		if not Mets.get_directed_raycast_collision(scanning_ray, target_and_rank[0].global_position):
			targets_in_sight.append(target_and_rank[0])

	# sortiram
	var sorted_targets: Array = targets_in_sight # nesortirano
	# po ranku, level ranku ali distanci
	sorted_targets = _sort_targets_by(posssible_targets_with_rank, SELECT_TARGET_BY.TARGET_RANK)
#	sorted_targets = _sort_targets_by(targets_in_sight, SELECT_TARGET_BY.LEVEL_RANK)
#	sorted_targets = _sort_targets_by(targets_in_sight, SELECT_TARGET_BY.DISTANCE)


	if sorted_targets.empty():
		return current_target # če je null gre v search
	else:
		return sorted_targets.front()


func _get_target_rank(unranked_target: Node2D):

	var targets_rank: int = 0

	if "level_object_key" in unranked_target:
		match unranked_target.level_object_key:
			Pros.LEVEL_OBJECT.BRICK_TARGET:
				targets_rank = 5
			Pros.LEVEL_OBJECT.FLATLIGHT:
				targets_rank = 3
	elif "pickable_key" in unranked_target:
		match unranked_target.pickable_key:
			Pros.PICKABLE.CASH, Pros.PICKABLE.POINTS:
				targets_rank = 10
			Pros.PICKABLE.SHIELD:
				targets_rank = 5
			Pros.PICKABLE.GUN, Pros.PICKABLE.LAUNCHER, Pros.PICKABLE.DROPPER:
				targets_rank = 0
			Pros.PICKABLE.HEALTH, Pros.PICKABLE.LIFE, Pros.PICKABLE.GAS:
				targets_rank = 3
			Pros.PICKABLE.NITRO, Pros.PICKABLE.RANDOM, Pros.LEVEL_OBJECT.GOAL_PILLAR:
				targets_rank = 2
	elif unranked_target.is_in_group(Refs.group_players):
		targets_rank = 1

	return targets_rank


func _sort_targets_by(available_targets: Array, select_target_by: int):

	match select_target_by:
		SELECT_TARGET_BY.TARGET_RANK:
			# available_targets = array arrayev
			available_targets.sort_custom(self, "_sort_targets_by_rank_array")
			# tarče v zaporedju rank arrays
			var ranked_targets: Array = []
			for rank_array in available_targets:
				ranked_targets.append(rank_array[0])
			available_targets = ranked_targets
			available_targets.sort_custom(self, "_sort_targets_by_rank_array")
		SELECT_TARGET_BY.LEVEL_RANK, SELECT_TARGET_BY.GAME_RANK:
			var targets_with_level_rank: Array
			for target in available_targets:
				if target.is_in_group(Refs.group_drivers):
					targets_with_level_rank.append(target)
			targets_with_level_rank.sort_custom(self, "_sort_targets_by_level_rank")
			available_targets = targets_with_level_rank
		SELECT_TARGET_BY.DISTANCE:
			available_targets.sort_custom(self, "_sort_targets_by_distance")

	return available_targets


func _get_nav_position_target(from_position: Vector2, distance_range: Array = [0, 50], in_front: bool = true):

	# samo prvič ... pri dirkanju nikoli
	# ... preveri če se pozna na performance
	if level_navigation_points.empty():
		level_navigation_points = get_parent().level_navigation.get_navigation_points()

	# če level nima navigacije
	if level_navigation_points.empty():
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

		for nav_position in level_navigation_points:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			all_nav_pos_distances.append(current_cell_distance) # zaloga, če je ne najde na distanci
			# najprej izbere vse na predpisani dolžini
			if current_cell_distance > distance_range[0] and current_cell_distance < distance_range[1]:
				if in_front:
					var vector_to_position: Vector2 = nav_position - global_position
					var current_angle_to_vehicle_deg: float = rad2deg(vehicle.get_angle_to(nav_position))
					# najbolj spredaj
					if current_angle_to_vehicle_deg < 30 and current_angle_to_vehicle_deg > - 30 :
						front_cells_for_random_selection.append(nav_position)
					# na straneh
					elif current_angle_to_vehicle_deg < 90 and current_angle_to_vehicle_deg > -90 :
						side_cells_for_random_selection.append(nav_position)
					# ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position)
				else:
					all_cells_for_random_selection.append(nav_position)

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

	# nav target samo premaknem na željeno pozicijo, ostane pa isti
	get_parent().level_navigation.nav_position_target.global_position = selected_nav_position

	return get_parent().level_navigation.nav_position_target


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


# SORTERS ----------------------------------------------------------------------------------------------


func _sort_targets_by_rank_array(target_array_1: Array, target_array_2: Array): # asc ... TRUE = A before B

	if target_array_1[1] < target_array_2[1]:
	    return true
	return false


func _sort_targets_by_level_rank(driver_1: Vehicle, driver_2: Vehicle): # asc ... TRUE = B before A

	var driver_1_rank: int = driver_1.driver_stats[Pros.STATS.LEVEL_RANK]
	var driver_2_rank: int = driver_2.driver_stats[Pros.STATS.LEVEL_RANK]
	if driver_1_rank < driver_2_rank:
		return true
	return false


func _sort_targets_by_distance(target_1: Node2D, target_2: Node2D): # asc ... TRUE = B before A

	var distance_to_target_1: float = (target_1.global_position - global_position).length()
	var distance_to_target_2: float = (target_2.global_position - global_position).length()
	if distance_to_target_1 < distance_to_target_2:
		return true
	return false



#var target_ray
#var keep_distance
#var braking_velocity
#var breaking_factor_keep
#var engine_power_factor_keep
#var near_distance
#var breaking_factor_near
#func _react_to_target(react_target: Node2D, keep_on_distance: bool = false, be_aggressive: bool = false):
#	# keep_on_distance - ustavi na distanci in jo vzdržuje
#	# aggresive - posešuje do tarče
#
#	# debug
#	#	keep_distance = 500
#	#	near_distance = 800
#	#	keep_on_distance = true
#	#	be_aggressive = false
#	var motion_manager: Node2D = vehicle.motion_manager
#	var navigation_agent: NavigationAgent2D = get_parent().navigation_agent
#	var any_collider = Mets.get_directed_raycast_collision(target_ray, react_target.global_position)
#
#	var target_in_sight: bool = false
#	if any_collider and any_collider == react_target and is_instance_valid(react_target):
#	#	if any_collider and any_collider == react_target and not react_target.is_queued_for_deletion():
#		target_in_sight = true
#
#	if target_in_sight:
#		var target_closeup_breaking_factor: float = 1
#		var distance_to_target = global_position.distance_to(react_target.global_position)
#		if distance_to_target < keep_distance:
#			if keep_on_distance: # ustavi tik pred tarčo
#				target_closeup_breaking_factor = breaking_factor_keep
#				motion_manager.current_engine_power = motion_manager.max_engine_power * engine_power_factor_keep
#			elif be_aggressive: # fuuul power čez tarčo
#				motion_manager.current_engine_power = motion_manager.max_engine_power
#			else: # spusti gasa čez tarčo
#				motion_manager.current_engine_power = 0
#			motion_manager.current_engine_power = 0
#		elif distance_to_target < near_distance:
#			if be_aggressive: # pospešuje proti tarči
#				motion_manager.current_engine_power = motion_manager.max_engine_power
#				motion_manager.boost_vehicle()
#			else: # upočasnuje proti tarči
#				target_closeup_breaking_factor = breaking_factor_near
#		else:
#			motion_manager.current_engine_power = motion_manager.max_engine_power
#		braking_velocity = vehicle.velocity * target_closeup_breaking_factor
#		vehicle.set_linear_velocity(braking_velocity)
#	else:
#		# če izgubi pogled na tarčo, še zmeraj v tistem trenutku videl
#		navigation_agent.set_target_location(global_position)
