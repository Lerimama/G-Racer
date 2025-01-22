extends Node2D


signal level_is_set(navigation, spawn_positions, other_)

enum LEVEL_TYPE {RACE_TRACK, RACE_LAPS, BATTLE, CHASE, RACE_GOAL}
var level_type: int # določi glede na pripete elemente = LEVEL_TYPE.RACE_TRACK
#export (LEVEL_TYPE) var level_type: int = LEVEL_TYPE.RACE_TRACK

export (Array, NodePath) var level_goals_paths: Array = [] # lahko jih tudi ni
export (NodePath) var level_finish_path: String # lahko ga tudi ni
export (NodePath) var level_track_path: String # lahko ga tudi ni

var level_finish: Node2D
var level_track: Path2D
var level_goals: Array = []
var navigation_cells_positions: Array = []

onready var level_navigation: NavigationPolygonInstance = $LevelNavigation
onready var tilemap_objects: TileMap = $Objects/Objects
onready var camera_limits_rect: Panel = $CameraLimits

# start
onready var level_start: Node2D = $Racing/LevelStart
onready var start_lights: Node2D = $Racing/LevelStart/StartLights
onready var start_camera_position_node: Position2D = $Racing/LevelStart/CameraPosition
onready var start_positions_node: Node2D = $Racing/LevelStart/StartPositions
onready var drive_in_position: Vector2 = $Racing/LevelStart/DriveInPosition.position
onready var finish_camera_position_node: Position2D = $Racing/LevelFinish/CameraPosition
onready var drive_out_position: Vector2 = $Racing/LevelFinish/DriveOutPosition.position


func _ready() -> void:
#	printt("LEVEL")

	$__ScreenSize.hide() # debug

	Rfs.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje
	Rfs.node_creation_parent = $NCP # rabim, da lahko hitro vse spucam in resetiram level
	for child in start_positions_node.get_children():
		child.hide()

	# nodepaths
	if level_track_path:
		 level_track = get_node(level_track_path)
	if level_finish_path:
		 level_finish = get_node(level_finish_path)
	for goal_path in level_goals_paths:
		level_goals.append(get_node(goal_path))

	# level type
	if level_goals.empty() and not level_finish:
		level_type = LEVEL_TYPE.BATTLE
	else:
		if level_track:
			level_type = LEVEL_TYPE.RACE_TRACK
		elif level_finish: # ma cilj in gole
			level_type = LEVEL_TYPE.RACE_GOAL
		else:
			level_type = LEVEL_TYPE.CHASE

	match level_type:
		LEVEL_TYPE.BATTLE:
			level_start.hide()
			if level_finish:
				level_finish.hide()
				level_finish.get_node("FinishLine").set_deferred("monitoring", false)
				# Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		LEVEL_TYPE.RACE_TRACK:
			level_start.show()
			if level_finish:
				level_finish.show()
		LEVEL_TYPE.RACE_GOAL: # _temp level
			level_start.show()
			if level_finish:
				level_finish.show()
		LEVEL_TYPE.CHASE:
			level_start.show()
			if level_finish:
				level_finish.show()


	_set_level_objects()
	navigation_cells_positions = $LevelNavigation.level_navigation_points.duplicate()

	_resize_to_level_size()

	emit_signal("level_is_set", navigation_cells_positions) # pošljem v GM


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
#				non_navigation_cell_positions.append(cell_global_position)
#				for surrounding_cell in get_surrounding_cells(cell, true):
#					if not non_navigation_cell_positions.has(surrounding_cell):
#						non_navigation_cell_positions.append(surrounding_cell)
			42: # brick magnet
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_MAGNET
				spawn_tile_offset = brick_tile_offset
#				non_navigation_cell_positions.append(cell_global_position)
#				for surrounding_cell in get_surrounding_cells(cell, true):
#					if not non_navigation_cell_positions.has(surrounding_cell):
#						non_navigation_cell_positions.append(surrounding_cell)
			43: # brick target
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_TARGET
				spawn_tile_offset = brick_tile_offset
#				non_navigation_cell_positions.append(cell_global_position)
#				for surrounding_cell in get_surrounding_cells(cell, true):
#					if not non_navigation_cell_positions.has(surrounding_cell):
#						non_navigation_cell_positions.append(surrounding_cell)
			44: # brick bouncer
				level_object_key = Pfs.LEVEL_OBJECT.BRICK_BOUNCER
				spawn_tile_offset = brick_tile_offset
#				non_navigation_cell_positions.append(cell_global_position)
#				for surrounding_cell in get_surrounding_cells(cell, true):
#					if not non_navigation_cell_positions.has(surrounding_cell):
#						non_navigation_cell_positions.append(surrounding_cell)
			45: # brick light
				level_object_key = Pfs.LEVEL_OBJECT.FLATLIGHT
				spawn_tile_offset = brick_tile_offset
			6: # goal pillar
				level_object_key = Pfs.LEVEL_OBJECT.GOAL_PILLAR
				spawn_tile_offset = pillar_tile_offset
#				non_navigation_cell_positions.append(cell_global_position)

		if level_object_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			var scene_to_spawn: PackedScene = Pfs.level_object_profiles[level_object_key]["object_scene"]
			var new_object_scene = scene_to_spawn.instance()
			new_object_scene.position = cell_global_position + spawn_tile_offset
			new_object_scene.level_object_key = level_object_key
			add_child(new_object_scene)

	_set_pickables()


func _set_pickables():


	if tilemap_objects.get_used_cells().empty():
		return

	for cell in tilemap_objects.get_used_cells():

		var cell_index = tilemap_objects.get_cellv(cell)
		var cell_local_position = tilemap_objects.map_to_world(cell)
		var cell_global_position = tilemap_objects.to_global(cell_local_position)

		var pickable_key: int = -1
		match cell_index:
			14:
				pickable_key = Pfs.PICKABLE.PICKABLE_BULLET
			15:
				pickable_key = Pfs.PICKABLE.PICKABLE_MISILE
			35:
				pickable_key = Pfs.PICKABLE.PICKABLE_MINA
			17:
				pickable_key = Pfs.PICKABLE.PICKABLE_SHIELD
			18:
				pickable_key = Pfs.PICKABLE.PICKABLE_HEALTH
			19:
				pickable_key = Pfs.PICKABLE.PICKABLE_LIFE
			20:
				pickable_key = Pfs.PICKABLE.PICKABLE_NITRO
			27:
				pickable_key = Pfs.PICKABLE.PICKABLE_GAS
			30:
				pickable_key = Pfs.PICKABLE.PICKABLE_POINTS
			31:
				pickable_key = Pfs.PICKABLE.PICKABLE_CASH
			22:
				pickable_key = Pfs.PICKABLE.PICKABLE_RANDOM

		if pickable_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			spawn_pickable(cell_global_position, "pickable_name_as_key", pickable_key)


# UTILITI ---------------------------------------------------------------------------------------------------------------------------------------


func spawn_pickable(spawn_global_position: Vector2, pickable_name: String, pickable_index: int):

	var scene_to_spawn: PackedScene = preload("res://game/level/pickables/Pickable.tscn")
	var pickable_tile_offset: Vector2 = Vector2(8,8)

	var new_pickable_scene = scene_to_spawn.instance() #
	new_pickable_scene.position = spawn_global_position + pickable_tile_offset
	new_pickable_scene.pickable_key = pickable_index
	add_child(new_pickable_scene)


func _resize_to_level_size():

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


#func _get_surrounding_cells(surrounded_cell: Vector2, return_global_positions: bool = false):
#
#	var surrounding_cells: Array = []
#	var surrounding_cells_global_positions: Array = []
#	var target_cell: Vector2
#
#	for y in 3:
#		for x in 3:
#			target_cell = surrounded_cell + Vector2(x - 1, y - 1)
#			if surrounded_cell != target_cell:
#				surrounding_cells.append(target_cell)
#
#	if return_global_positions:
#		for loc_cell in surrounding_cells:
#			var cell_loc_position = tilemap_objects.map_to_world(loc_cell)
#			var cell_glo_position = tilemap_objects.to_global(cell_loc_position)
#			surrounding_cells_global_positions.append(cell_glo_position)
#		return surrounding_cells_global_positions
#	else:
#		return surrounding_cells

