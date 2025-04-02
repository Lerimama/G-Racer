extends Node2D
class_name Level


enum LEVEL_TYPE {
	FREE_RIDE, # none rank, no time limit
	RACING_TRACK, # time rank, laps, no damage / elements: start line + tracking line + finish line
	RACING_GOALS, # time rank, no laps, no damage / elements: start line + goals + finish line
	BATTLE_GOALS, # points rank, no laps, damage / elements: goals
	BATTLE_SCALPS, # scalps rank, no laps, damage, / elements: drivers
	MISSION, # none rank, time limit / elements: drivers
	}
export (LEVEL_TYPE) var level_type: int = LEVEL_TYPE.FREE_RIDE

export (NodePath) var camera_limits_path: String # lahko ga tudi ni ... potem ni meja
export (Array, NodePath) var level_goals_paths: Array = [] # lahko jih tudi ni
export var reach_goals_in_sequence: bool = false

var available_pickable_positions: Array = []
var level_goals: Array = [] # pobere povezane
var level_start_positions: Dictionary = {} # [global_position, global_rotation]

var camera_limits: Control # če ga ni, kamera nima limita
onready var camera_position_2d: Position2D = $Elements/StartCameraPosition

onready var start_positions_holder: Node2D = $Elements/StartPositions
onready var start_line_position_2d: Position2D = $Elements/StartLine/StartPosition
onready var tracking_line: Path2D = $Elements/TrackingLine
onready var finish_line: Node2D = $Elements/FinishLine
onready var start_line: Node2D = $Elements/StartLine
onready var level_navigation: NavigationPolygonInstance = $Elements/LevelNavigation
onready var tilemap_objects: TileMap = $Objects/Objects


func _ready() -> void:
#	printt("LEVEL")

	# debug
	$__ScreenSize.hide()
	$__Labels.hide()
	$__WorldMeters.hide()
	camera_position_2d.hide()
	tracking_line.hide()

	Refs.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level


func set_level(drivers_count: int):

	match level_type:

		LEVEL_TYPE.FREE_RIDE:
			# no ranking, neomejen čas
			start_line.is_enabled = false
			tracking_line.is_enabled = false
			finish_line.is_enabled = false
			level_goals.clear()
			available_pickable_positions = level_navigation.get_navigation_points()
			_spawn_random_pickables()
		LEVEL_TYPE.RACING_TRACK:
			# time rank, start line + tracking line + finish line
			start_line.is_enabled = true
			tracking_line.is_enabled = true
			finish_line.is_enabled = true
			level_goals.clear()
		LEVEL_TYPE.RACING_GOALS:
			# time rank, no laps, start line + goals + finish line
			start_line.is_enabled = true
			tracking_line.is_enabled = false
			finish_line.is_enabled = true
			_set_level_goals()
		LEVEL_TYPE.BATTLE_GOALS:
			# time rank, no laps, start line + goals + finish line
			start_line.is_enabled = false
			tracking_line.is_enabled = false
			finish_line.is_enabled = false
			_set_level_goals()

		LEVEL_TYPE.BATTLE_SCALPS:
			start_line.is_enabled = false
			tracking_line.is_enabled = false
			finish_line.is_enabled = false
			level_goals.clear()
			available_pickable_positions = level_navigation.get_navigation_points()
			_spawn_random_pickables()

		LEVEL_TYPE.MISSION:
			start_line.is_enabled = false
			tracking_line.is_enabled = false
			finish_line.is_enabled = false
			_set_level_goals()

	#	yield(get_tree(), "idle_frame") # za "completed" ... ne rabim ker yildam spodaj

	# camera
	if camera_limits_path:
		camera_limits = get_node(camera_limits_path)
		for edge_rect in camera_limits:
			var edge_collision: CollisionShape2D = edge_rect.get_child(0).get_child(0)
			edge_collision.disabled = false # def je disabled

	_set_level_objects()
	_set_to_level_size()
	yield(_set_start_positions(drivers_count), "completed")


func _set_level_goals(): # kliče tudi GM na nov krog

	level_goals.clear()
	var goal_reached_signal_name: String = "reached_by"
	for goal_path in level_goals_paths:
		var goal: Node2D = get_node(goal_path)
		if goal.has_signal(goal_reached_signal_name): # vsak goal more met signal
			level_goals.append(goal)
			if "is_enabled" in goal:
				goal.is_enabled = true
			goal.show()
		else:
			goal.hide()


func _set_start_positions(new_positions_count: int):
	# naredim slovar start pozicij z rotacijo

	level_start_positions.clear()
	start_positions_holder.position_count = new_positions_count

	yield(get_tree(), "idle_frame")

	for count in new_positions_count:
		var driver_position_2d: Position2D = start_positions_holder.active_position_2ds[count]
		var new_driver_position: Vector2 = driver_position_2d.global_position
		var new_driver_rotation: float = driver_position_2d.global_rotation
		# pozicije na gridu ni potrenbo adaptirat ... nevemzakaj
		if not start_positions_holder.positions_shape == start_positions_holder.POSITIONS_SHAPE.GRID:
			new_driver_position += start_positions_holder.global_position
			new_driver_position += start_positions_holder.current_positions_holder.rect_position
		level_start_positions[count] = [new_driver_position, new_driver_rotation]


func _set_level_objects():

	if tilemap_objects.get_used_cells().empty():
		return

	var brick_tile_offset: Vector2 = Vector2(4, 4)
	var pillar_tile_offset: Vector2 = Vector2(36, 36)

	for cell in tilemap_objects.get_used_cells():


		var cell_index = tilemap_objects.get_cellv(cell)
		var cell_local_position = tilemap_objects.map_to_world(cell)
		var cell_global_position = tilemap_objects.to_global(cell_local_position)

		var spawn_tile_offset: Vector2
		var level_object_key: int = -1
		match cell_index:
			41: # brick ghost
				level_object_key = Pros.LEVEL_OBJECT.BRICK_GHOST
				spawn_tile_offset = brick_tile_offset
			42: # brick magnet
				level_object_key = Pros.LEVEL_OBJECT.BRICK_MAGNET
				spawn_tile_offset = brick_tile_offset
			43: # brick target
				level_object_key = Pros.LEVEL_OBJECT.BRICK_TARGET
				spawn_tile_offset = brick_tile_offset
			44: # brick bouncer
				level_object_key = Pros.LEVEL_OBJECT.BRICK_BOUNCER
				spawn_tile_offset = brick_tile_offset
			45: # brick light
				level_object_key = Pros.LEVEL_OBJECT.FLATLIGHT
				spawn_tile_offset = brick_tile_offset
			6: # goal pillar
				level_object_key = Pros.LEVEL_OBJECT.GOAL_PILLAR
				spawn_tile_offset = pillar_tile_offset

		if level_object_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			var scene_to_spawn: PackedScene = Pros.level_object_profiles[level_object_key]["object_scene"]
			var new_object_scene = scene_to_spawn.instance()
			new_object_scene.position = cell_global_position + spawn_tile_offset
			new_object_scene.level_object_key = level_object_key
			$Objects.add_child(new_object_scene)


func _set_to_level_size():

	if camera_limits: # OPT najdi rešitev če ni

		# naberem rektangle za risajzat
		var nodes_to_resize: Array = []
		nodes_to_resize.append_array($Background.get_children())

		# resize and set
		for node in nodes_to_resize:
			node.rect_position = camera_limits.rect_position
			node.rect_size = camera_limits.rect_size
			if node.material:
				node.material.set_shader_param("node_size", camera_limits.rect_size)


func _spawn_random_pickables(): # SCALPS and FREE

	if get_tree().get_nodes_in_group(Refs.group_pickables).size() <= Sets.pickables_count_limit - 1:
		var random_pickable: Pickable = _spawn_pickable(Pros.pickable_profiles.keys().pick_random())
		random_pickable.connect("tree_exiting", self, "_on_random_pickable_exited", [random_pickable.global_position])
	# nova se spawna se ob pobranju
	# random timer reštart
	#	var random_pickable_spawn_time: int = [1, 2, 3].pick_random()
	#	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # OPT ... uvedi node timer
	#	_spawn_random_pickables()


func _spawn_pickable(pickable_key: int):

	if not available_pickable_positions.empty():

		var random_cell_position: Vector2 = available_pickable_positions.pick_random()
		var NewPickable: PackedScene = preload("res://game/level/pickables/Pickable.tscn")

		var new_pickable = NewPickable.instance()
		new_pickable.global_position = random_cell_position
		new_pickable.pickable_key = pickable_key
		$Pickables.add_child(new_pickable)

		# odstranim celico iz arraya tistih na voljo
		available_pickable_positions.erase(random_cell_position)

		return new_pickable


func _on_random_pickable_exited(pickable_position: Vector2): # samo za random type spawn

	if not pickable_position in available_pickable_positions:
		available_pickable_positions.append(pickable_position)

	_spawn_pickable(Pros.pickable_profiles.keys().pick_random())


