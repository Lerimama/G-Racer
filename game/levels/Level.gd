extends Node2D
class_name Level

signal level_is_set(navigation, spawn_positions, other_)

export (NodePath) var camera_limits_rect_path: String # lahko ga tudi ni ... potem ni meja
export (Array, NodePath) var level_goals_paths: Array = [] # lahko jih tudi ni
export var reach_goals_in_sequence: bool = false

var available_pickable_positions: Array = []
var level_goals: Array = [] # pobere povezane

var camera_limits_rect: Panel # če ga ni, kamera nima limita
onready var camera_position_node: Position2D = $Tracking/StartCameraPosition

onready var level_track: Path2D = $Tracking/LevelTrack
onready var level_finish: Node2D = $Tracking/FinishLine
onready var level_start: Node2D = $Tracking/StartLine
onready var level_navigation: NavigationPolygonInstance = $Tracking/LevelNavigation
onready var tilemap_objects: TileMap = $Objects/Objects

onready var start_positions_holder: Node2D = $Tracking/StartPositions
onready var level_start_position_node: Position2D = $Tracking/StartLine/StartPosition
var level_start_positions: Array = []


func _ready() -> void:
#	printt("LEVEL")

	# debug
	$__ScreenSize.hide()
	$__Labels.hide()
	$__WorldMeters.hide()
	camera_position_node.hide()

	Refs.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level

	start_positions_holder.position_count = 4

func set_level():

	# camera
	if camera_limits_rect_path:
		 camera_limits_rect = get_node(camera_limits_rect_path)

	# start positions
	if level_start.is_enabled:
		start_positions_holder.global_position = level_start_position_node.global_position

	for driver_position in start_positions_holder.get_child(0).get_children():
		print(driver_position)
		var curr_driver_position: Vector2 = driver_position.get_child(0).global_position
		level_start_positions.append(curr_driver_position)

	# goals
	var goal_reached_signal_name: String = "reached_by" # vsak goal more met to
	for goal_path in level_goals_paths:
		var current_goal: Node2D = get_node(goal_path)
		if current_goal.has_signal(goal_reached_signal_name):
			if "is_enabled" in current_goal:
				current_goal.is_enabled = true
			level_goals.append(current_goal)
		current_goal.show()

	# rank type
	var level_ranking_type: int = 0
	if level_finish.is_enabled or not level_goals.empty():
		level_ranking_type = Pros.RANK_BY.TIME
	else:
		level_ranking_type = Pros.RANK_BY.POINTS

	_set_level_objects()
	available_pickable_positions = level_navigation.level_navigation_points.duplicate()

	_resize_to_level_size()

	# pošljem
	emit_signal(
		"level_is_set",
		level_ranking_type,
		level_start_positions,
#		level_start.start_positions_holder.get_children(),
		camera_limits_rect,
		camera_position_node,
		level_goals
		)


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


func spawn_pickable(pickable_key: int = -1):

	if not available_pickable_positions.empty():

		if pickable_key == -1: # random pickable
			pickable_key = Pros.pickable_profiles.keys().pick_random()

		var random_cell_position: Vector2 = available_pickable_positions.pick_random()
		var NewPickable: PackedScene = preload("res://game/level/pickables/Pickable.tscn")

		var new_pickable = NewPickable.instance()
		new_pickable.global_position = random_cell_position
		new_pickable.pickable_key = pickable_key
		$Pickables.add_child(new_pickable)

		new_pickable.connect("tree_exiting", self, "_on_pickable_picked",[new_pickable.global_position])

		# odstranim celico iz arraya tistih na voljo
		available_pickable_positions.erase(random_cell_position)


func _on_pickable_picked(pickable_position: Vector2):

	if not pickable_position in available_pickable_positions:
		available_pickable_positions.append(pickable_position)


func _resize_to_level_size():

	if camera_limits_rect: # OPT najdi rešitev če ni

		# naberem rektangle za risajzat
		var nodes_to_resize: Array = []
		nodes_to_resize.append_array($Background.get_children())

		# resize and set
		for node in nodes_to_resize:
			node.rect_position = camera_limits_rect.rect_position
			node.rect_size = camera_limits_rect.rect_size
			if node.material:
				node.material.set_shader_param("node_size", camera_limits_rect.rect_size)


func _get_tilemap_cells(tilemap: TileMap):
	# kadar me zanimajo tudi prazne celice

	var tilemap_cells: Array = [] # celice v gridu

	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:
			var cell: Vector2 = Vector2(x, y)
			tilemap_cells.append(cell)

	return tilemap_cells
