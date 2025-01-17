extends Node2D


signal level_is_set(navigation, spawn_positions, other_)

enum LEVEL_TYPE {RACE, RACE_LAPS, BATTLE, CHASE, RACE_GOAL}
export (LEVEL_TYPE) var level_type: int = LEVEL_TYPE.RACE

# navigacija
var navigation_cells_positions: Array
var non_navigation_cell_positions: Array # elementi, kjer navigacija ne sme potekati

onready var checkpoint: Area2D = $Racing/Checkpoint
onready var level_track: Path2D = $Racing/LevelTrack
onready var level_navigation: NavigationPolygonInstance = $LevelNavigation
onready var tilemap_objects: TileMap = $Objects/Objects
onready var camera_limits_rect: Panel = $CameraLimits

# start
onready var level_start: Node2D = $Racing/LevelStart
onready var start_lights: Node2D = $Racing/LevelStart/StartLights
onready var start_camera_position_node: Position2D = $Racing/LevelStart/CameraPosition
onready var start_positions_node: Node2D = $Racing/LevelStart/StartPositions
onready var drive_in_position: Vector2 = $Racing/LevelStart/DriveInPosition.position

# finish
onready var level_finish: Node2D = $Racing/LevelFinish
onready var finish_line: Area2D = $Racing/LevelFinish/FinishLine
onready var finish_camera_position_node: Position2D = $Racing/LevelFinish/CameraPosition
onready var drive_out_position: Vector2 = $Racing/LevelFinish/DriveOutPosition.position

# neu
onready var temp_level_goals: Array = [$Racing/Checkpoint, $Racing/LevelFinish]


func _ready() -> void:
	printt("LEVEL", temp_level_goals)

	$__ScreenSize.hide() # debug

	Refs.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje
	for child in start_positions_node.get_children():
		child.hide()

	match level_type:
		LEVEL_TYPE.BATTLE:
			level_start.hide()
			checkpoint.hide()
			level_finish.hide()
			finish_line.set_deferred("monitoring", false)
			# Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
			#			finish_line.monitoring = false
		LEVEL_TYPE.RACE:
			level_start.show()
			checkpoint.hide()
			level_finish.show()
			finish_line.set_deferred("monitoring", true)
		LEVEL_TYPE.RACE_LAPS:
			level_start.show()
			checkpoint.show()
			level_finish.show()
			finish_line.set_deferred("monitoring", true)
		LEVEL_TYPE.RACE_GOAL: # _temp level
			level_start.show()
			checkpoint.show()
			level_finish.show()
			finish_line.set_deferred("monitoring", true)
		LEVEL_TYPE.CHASE:
			#			level_start.hide()
			#			level_finish.hide()
			checkpoint.show()
			finish_line.set_deferred("monitoring", true)

	# kar je skrito, ne deluje
	if checkpoint.visible:
		#		checkpoint.monitoring = true
		checkpoint.set_deferred("monitoring", true)
	else:
		#		checkpoint.monitoring = false
		checkpoint.set_deferred("monitoring", false)

	set_level_objects()
	navigation_cells_positions = $LevelNavigation.level_navigation_points.duplicate()
#	set_level_navigation() # navigacija ... more bit po objects zato, da se prilagodi navigacija ...

	resize_to_level_size()

	emit_signal("level_is_set", navigation_cells_positions) # pošljem v GM


func set_level_objects():

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
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			42: # brick magnet
				level_object_key = Pros.LEVEL_OBJECT.BRICK_MAGNET
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			43: # brick target
				level_object_key = Pros.LEVEL_OBJECT.BRICK_TARGET
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			44: # brick bouncer
				level_object_key = Pros.LEVEL_OBJECT.BRICK_BOUNCER
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			45: # brick light
				level_object_key = Pros.LEVEL_OBJECT.FLATLIGHT
				spawn_tile_offset = brick_tile_offset
			6: # goal pillar
				level_object_key = Pros.LEVEL_OBJECT.GOAL_PILLAR
				spawn_tile_offset = pillar_tile_offset
				non_navigation_cell_positions.append(cell_global_position)

		if level_object_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			var scene_to_spawn: PackedScene = Pros.level_object_profiles[level_object_key]["object_scene"]
			var new_object_scene = scene_to_spawn.instance()
			new_object_scene.position = cell_global_position + spawn_tile_offset
			new_object_scene.level_object_key = level_object_key
			add_child(new_object_scene)

	set_pickables()


func set_pickables():


	if tilemap_objects.get_used_cells().empty():
		return

	for cell in tilemap_objects.get_used_cells():

		var cell_index = tilemap_objects.get_cellv(cell)
		var cell_local_position = tilemap_objects.map_to_world(cell)
		var cell_global_position = tilemap_objects.to_global(cell_local_position)

		var pickable_key: int = -1
		match cell_index:
			14:
				pickable_key = Pros.PICKABLE.PICKABLE_BULLET
			15:
				pickable_key = Pros.PICKABLE.PICKABLE_MISILE
			35:
				pickable_key = Pros.PICKABLE.PICKABLE_MINA
			17:
				pickable_key = Pros.PICKABLE.PICKABLE_SHIELD
			18:
				pickable_key = Pros.PICKABLE.PICKABLE_HEALTH
			19:
				pickable_key = Pros.PICKABLE.PICKABLE_LIFE
			20:
				pickable_key = Pros.PICKABLE.PICKABLE_NITRO
			27:
				pickable_key = Pros.PICKABLE.PICKABLE_GAS
			30:
				pickable_key = Pros.PICKABLE.PICKABLE_POINTS
			31:
				pickable_key = Pros.PICKABLE.PICKABLE_CASH
			22:
				pickable_key = Pros.PICKABLE.PICKABLE_RANDOM

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


func resize_to_level_size():

	# naberem rektangle za risajzat
	var nodes_to_resize: Array = []
	nodes_to_resize.append_array($Background.get_children())

	# resize and set
	for node in nodes_to_resize:
		node.rect_position = camera_limits_rect.rect_position
		node.rect_size = camera_limits_rect.rect_size
		if node.material:
			node.material.set_shader_param("node_size", camera_limits_rect.rect_size)


func get_tilemap_cells(tilemap: TileMap):
	# kadar me zanimajo tudi prazne celice

	var tilemap_cells: Array = [] # celice v gridu

	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:
			var cell: Vector2 = Vector2(x, y)
			tilemap_cells.append(cell)

	return tilemap_cells


func get_surrounding_cells(surrounded_cell: Vector2, return_global_positions: bool = false):

	var surrounding_cells: Array = []
	var surrounding_cells_global_positions: Array = []
	var target_cell: Vector2

	for y in 3:
		for x in 3:
			target_cell = surrounded_cell + Vector2(x - 1, y - 1)
			if surrounded_cell != target_cell:
				surrounding_cells.append(target_cell)

	if return_global_positions:
		for loc_cell in surrounding_cells:
			var cell_loc_position = tilemap_objects.map_to_world(loc_cell)
			var cell_glo_position = tilemap_objects.to_global(cell_loc_position)
			surrounding_cells_global_positions.append(cell_glo_position)
		return surrounding_cells_global_positions
	else:
		return surrounding_cells


# SIGNALI ---------------------------------------------------------------------------------------------------------------------------------------


func _on_FinishLine_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts):
		Refs.game_manager.bolt_across_finish_line(body)


func _on_Checkpoint_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts):
		if not Refs.game_manager.bolts_checked.has(body):
			Refs.game_manager.bolts_checked.append(body)
