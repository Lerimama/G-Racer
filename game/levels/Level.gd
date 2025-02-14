extends Node2D
class_name Level

signal level_is_set(navigation, spawn_positions, other_)

var level_type: int = 0 # določi glede na pripete elemente = LEVEL_TYPE.RACE_TRACK

export (NodePath) var camera_limits_rect_path: String # lahko ga tudi ni ... potem ni meja
export (NodePath) var level_finish_path: String # lahko ga tudi ni
export (NodePath) var level_track_path: String # lahko ga tudi ni
export (Array, NodePath) var level_goals_paths: Array = [] # lahko jih tudi ni
export var reach_goals_in_sequence: bool = false

var level_finish: Node2D
var level_track: Path2D
var level_goals: Array = []
var navigation_cells_positions: Array = []

onready var level_navigation: NavigationPolygonInstance = $Tracking/LevelNavigation
onready var tilemap_objects: TileMap = $Objects/Objects
onready var camera_limits_rect: Panel # = $CameraLimits

# start
onready var level_start: Node2D = $Tracking/LevelStart
onready var start_lights: Node2D = $Tracking/LevelStart/StartLights
onready var start_camera_position_node: Position2D = $Tracking/LevelStart/CameraPosition
onready var start_positions_node: Node2D = $Tracking/LevelStart/StartPositions
onready var drive_in_position: Vector2 = $Tracking/LevelStart/DriveInPosition.position
onready var finish_camera_position_node: Position2D = $Tracking/LevelFinish/CameraPosition
onready var drive_out_position: Vector2 = $Tracking/LevelFinish/DriveOutPosition.position


var goal_reached_signal: String = "reached_by"


func _ready() -> void:
#	printt("LEVELS")

	# debug
	$__ScreenSize.hide()
	$__Labels.hide()
	$__WorldMeters.hide()

	Rfs.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level

	for child in start_positions_node.get_children():
		child.hide()


func setup():

	# camera limits
	if camera_limits_rect_path:
		 camera_limits_rect = get_node(camera_limits_rect_path)
	# tracking curve
	if level_track_path:
		 level_track = get_node(level_track_path)
	# finish
	if level_finish_path:
		level_finish = get_node(level_finish_path)
		level_finish.is_active = true # def je ugasnjen
	# goals
	for goal_path in level_goals_paths:
		var current_goal: Node2D = get_node(goal_path)
		if current_goal.has_signal(goal_reached_signal):
			level_goals.append(get_node(goal_path))
		get_node(goal_path).show()

	# set type
	var curr_level_type: int = Pfs.BASE_TYPE.UNDEFINED
	if level_finish or not level_goals.empty():
		curr_level_type = Pfs.BASE_TYPE.TIMED
	else:
		curr_level_type = Pfs.BASE_TYPE.UNTIMED

	# pošljem
	if curr_level_type == Pfs.BASE_TYPE.UNDEFINED:
		printerr("Level stays UNDEFINED on spawn")
	else:
		_set_level_objects()
		navigation_cells_positions = level_navigation.level_navigation_points.duplicate()
		_resize_to_level_size()

		var camera_nodes: Array = [camera_limits_rect, start_camera_position_node, finish_camera_position_node]

		emit_signal("level_is_set", curr_level_type, start_positions_node.get_children(), camera_nodes, navigation_cells_positions, level_goals)


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
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_GHOST
				spawn_tile_offset = brick_tile_offset
			42: # brick magnet
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_MAGNET
				spawn_tile_offset = brick_tile_offset
			43: # brick target
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_TARGET
				spawn_tile_offset = brick_tile_offset
			44: # brick bouncer
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_BOUNCER
				spawn_tile_offset = brick_tile_offset
			45: # brick light
				level_object_key = Pfs.LEVEL_OBJECT.FLATLIGHT
				spawn_tile_offset = brick_tile_offset
			6: # goal pillar
				level_object_key = Pfs.LEVEL_OBJECT.GOAL_PILLAR
				spawn_tile_offset = pillar_tile_offset

		if level_object_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			var scene_to_spawn: PackedScene = Pfs.level_object_profiles[level_object_key]["object_scene"]
			var new_object_scene = scene_to_spawn.instance()
			new_object_scene.position = cell_global_position + spawn_tile_offset
			new_object_scene.level_object_key = level_object_key
			$Objects.add_child(new_object_scene)


func spawn_pickable(spawn_global_position: Vector2, pickable_name: String, pickable_index: int):

	var scene_to_spawn: PackedScene = preload("res://game/level/pickables/Pickable.tscn")
	var pickable_tile_offset: Vector2 = Vector2(8,8)

	var new_pickable_scene = scene_to_spawn.instance() #
	new_pickable_scene.position = spawn_global_position + pickable_tile_offset
	new_pickable_scene.pickable_key = pickable_index
	$Pickables.add_child(new_pickable_scene)


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


func _exit_tree() -> void:
	#	print ("LEVEL GRE")
	pass
