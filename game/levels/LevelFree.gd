extends Node2D


signal level_is_set(navigation, spawn_positions, other_)

enum LevelTypes {RACE, RACE_LAPS, BATTLE}
export (LevelTypes) var level_type: int = LevelTypes.RACE

# navigacija
var navigation_cells_positions: Array
var non_navigation_cell_positions: Array # elementi, kjer navigacija ne sme potekati

onready var start_camera_position_node: Position2D = $RaceStart/CameraPosition
onready var finish_camera_position_node: Position2D = $RaceFinish/CameraPosition
onready var finish_line: Area2D = $RaceFinish/FinishLine
onready var race_start_node: Node2D = $RaceStart
onready var start_lights: Node2D = $RaceStart/StartLights
onready var race_finish_node: Node2D = $RaceFinish
onready	var checkpoint: Area2D = $Checkpoint 
onready var start_positions_node: Node2D = $RaceStart/StartPositions
onready var finish_out_position: Vector2 = $RaceFinish/FinishOutPosition.global_position
onready var finish_out_distance: float = race_finish_node.global_position.distance_to($RaceFinish/FinishOutPosition.global_position)
onready var racing_track: Path2D = $RacingTrack
onready var tilemap_floor: TileMap = $_obs/Floor
onready var tilemap_objects: TileMap = $Objects
onready var tilemap_edge: TileMap = $_obs/Edge

onready var camera_limits_rect: Panel = $CameraLimits
	
func _ready() -> void:
	printt("LEVEL")
	
	Ref.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje

	# debug
	$_ScreenSize.hide()

	match level_type:
		LevelTypes.BATTLE:
			race_start_node.hide()
			race_finish_node.hide()
			checkpoint.hide()
		LevelTypes.RACE:
			race_start_node.show()
			race_finish_node.show()
			checkpoint.hide()
			race_start_node.get_node("StartLine").show()	
		LevelTypes.RACE_LAPS:
			race_start_node.show()
			race_finish_node.show()
			checkpoint.show()
			race_start_node.get_node("StartLine").hide()	
			
	# kar je skrito, ne deluje
	if checkpoint.visible:
		checkpoint.monitoring = true
	else: 
		checkpoint.monitoring = false
	if race_finish_node.visible:
		finish_line.monitoring = true
	else:
		finish_line.monitoring = false
		
	set_level_floor() # luknje
	set_level_objects() # elementi

	set_level_navigation() # navigacija ... more bit po objects zato, da se prilagodi navigacija ... 
		
	resize_to_level_size()
	
	emit_signal("level_is_set", navigation_cells_positions) # pošljem v GM
	
	
func set_level_floor():
	
	var area_tile_offset: Vector2 = Vector2(4,4)
	
	for cell in tilemap_floor.get_used_cells():
		
		var cell_index = tilemap_floor.get_cellv(cell)
		
		var cell_local_position = tilemap_floor.map_to_world(cell)
		var cell_global_position = tilemap_floor.to_global(cell_local_position)	
		
		var area_key: int = -1
		match cell_index:
			1:
				area_key = Pro.LevelAreas.AREA_NITRO
			2:
				area_key = Pro.LevelAreas.AREA_GRAVEL
			3:
				area_key = Pro.LevelAreas.AREA_HOLE
			4:
				area_key = Pro.LevelAreas.AREA_TRACKING

		if area_key > -1: # preskok celic, ki imajo druge id-je
			var scene_to_spawn: PackedScene = Pro.level_areas_profiles[area_key]["area_scene"]	
			var new_area_scene = scene_to_spawn.instance()
			new_area_scene.position = cell_global_position + area_tile_offset
			new_area_scene.level_area_key = area_key
			add_child(new_area_scene)
	

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
			6: # goal pillar
				level_object_key = Pro.LevelObjects.GOAL_PILLAR
				spawn_tile_offset = pillar_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
			7: # brick ghost
				level_object_key = Pro.LevelObjects.BRICK_GHOST
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			8: # brick bouncer
				level_object_key = Pro.LevelObjects.BRICK_BOUNCER
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			9: # brick magnet
				level_object_key = Pro.LevelObjects.BRICK_MAGNET
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			10: # brick target
				level_object_key = Pro.LevelObjects.BRICK_TARGET
				spawn_tile_offset = brick_tile_offset
				non_navigation_cell_positions.append(cell_global_position)
				for surrounding_cell in get_surrounding_cells(cell, true):
					if not non_navigation_cell_positions.has(surrounding_cell):
						non_navigation_cell_positions.append(surrounding_cell)
			11: # brick light
				level_object_key = Pro.LevelObjects.BRICK_LIGHT
				spawn_tile_offset = brick_tile_offset

		if level_object_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			var scene_to_spawn: PackedScene = Pro.level_object_profiles[level_object_key]["object_scene"]	
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
				pickable_key = Pro.Pickables.PICKABLE_BULLET
			15:
				pickable_key = Pro.Pickables.PICKABLE_MISILE
			35:
				pickable_key = Pro.Pickables.PICKABLE_MINA
			17:
				pickable_key = Pro.Pickables.PICKABLE_SHIELD
			18:
				pickable_key = Pro.Pickables.PICKABLE_ENERGY
			19:
				pickable_key = Pro.Pickables.PICKABLE_LIFE
			20:
				pickable_key = Pro.Pickables.PICKABLE_NITRO
			21:
				pickable_key = Pro.Pickables.PICKABLE_TRACKING
			27:
				pickable_key = Pro.Pickables.PICKABLE_GAS
			30:
				pickable_key = Pro.Pickables.PICKABLE_POINTS
			22:
				pickable_key = Pro.Pickables.PICKABLE_RANDOM
		
		if pickable_key > -1: # preskok celic, ki imajo druge id-je
			tilemap_objects.set_cellv(cell, -1)
			spawn_pickable(cell_global_position, "pickable_name_as_key", pickable_key)
		
			
func set_level_navigation(): # samo unfree 

	var navigation_polygon: NavigationPolygon = $NavigationPolygonInstance.navpoly
	var outer_polygon: PoolVector2Array = navigation_polygon.get_outline(0)
	
	# dimenzija zunanjega polygona, da ne grem po skončnem polju
	var nav_limits_square: Rect2 = Rect2(Vector2(0, 0), Vector2(0, 0)) 
	for point in outer_polygon:
		if point.x > nav_limits_square.size.x:
			nav_limits_square.size.x = point.x
		elif point.x < nav_limits_square.position.x or nav_limits_square.position.x == 0:
			nav_limits_square.position.x = point.x
		if point.y > nav_limits_square.size.y:
			nav_limits_square.size.y = point.y
		elif point.y < nav_limits_square.position.y or nav_limits_square.position.y == 0:
			nav_limits_square.position.y = point.y
	
	# naberem vse točke znotraj kvadrata zunanjega poligona (glede na gostoto)
	var nav_point_density: int = 8
	var outer_square_points: Array
	var x_count: int = round(nav_limits_square.size.x / nav_point_density)
	var y_count: int = round(nav_limits_square.size.y / nav_point_density)
	for x in x_count:
		for y in y_count:
			var current_point: Vector2 = Vector2(x * nav_point_density, y * nav_point_density)
			current_point += nav_limits_square.position # adaptiram za pozicijo nodeta
			outer_square_points.append(current_point)
	# naberem vse točke glavnega poligona
	var navigation_shape_nav_points: Array
	for nav_point in outer_square_points:
		if Geometry.is_point_in_polygon(nav_point, outer_polygon):
			navigation_shape_nav_points.append(nav_point)
	# odstranim točke notranjih poligonov (luknje znotraj navigacije)
	for poly in navigation_polygon.get_polygon_count():
		if poly > 0: # preskočim prvega, ki je zunanji
			var current_poly = navigation_polygon.get_outline(poly)
			for nav_point in outer_square_points:
				if Geometry.is_point_in_polygon(nav_point, current_poly):
					navigation_shape_nav_points.erase(nav_point)
	
	#	for p in navigation_shape_nav_points: # debug
	#		Met.spawn_indikator(p, global_rotation, Ref.node_creation_parent, false)
		
	navigation_cells_positions = navigation_shape_nav_points.duplicate()
		

		
# UTILITI ---------------------------------------------------------------------------------------------------------------------------------------


func spawn_pickable(spawn_global_position: Vector2, pickable_name: String, pickable_index: int):
	
	var scene_to_spawn: PackedScene = preload("res://game/arena/pickables/Pickable.tscn")
	var pickable_tile_offset: Vector2 = Vector2(8,8)
	
	var new_pickable_scene = scene_to_spawn.instance() #
	new_pickable_scene.position = spawn_global_position + pickable_tile_offset
	new_pickable_scene.pickable_key = pickable_index
	add_child(new_pickable_scene)
			

func resize_to_level_size():
	
	# dobim velikost levela (floor tilemapa)
	var first_floor_cell = tilemap_floor.get_used_cells().pop_front()
	var last_floor_cell: Vector2
	var floor_rect_position: Vector2
	var floor_rect_size: Vector2
	if not tilemap_floor.get_used_cells().empty():
		last_floor_cell = tilemap_floor.get_used_cells().pop_back()
		floor_rect_position = tilemap_floor.map_to_world(first_floor_cell)
		floor_rect_size = tilemap_floor.map_to_world(last_floor_cell) - tilemap_floor.map_to_world(first_floor_cell)
	
	# naberem rektangle za risajzat
	var nodes_to_resize: Array = tilemap_edge.get_children()
	nodes_to_resize.append_array($Background.get_children())
	
	# resize and set
	for node in nodes_to_resize:
		node.rect_position = floor_rect_position
		node.rect_size = floor_rect_size
		if node.material:
			node.material.set_shader_param("node_size", floor_rect_size)

	
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
	
	if body.is_in_group(Ref.group_bolts):
		Ref.game_manager.on_finish_line_crossed(body)
	elif body.is_in_group(Ref.group_thebolts):
		Ref.game_manager.on_finish_line_crossed(body)
	

func _on_Checkpoint_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if not Ref.game_manager.bolts_checked.has(body):
			Ref.game_manager.bolts_checked.append(body)
	elif body.is_in_group(Ref.group_thebolts):
		if not Ref.game_manager.bolts_checked.has(body):
			Ref.game_manager.bolts_checked.append(body)