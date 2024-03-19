extends Node2D

signal level_navigation_finished(navigation)
signal level_is_set(navigation, spawn_positions, other_)


var non_navigation_cell_positions: Array # elementi, kjer navigacija ne sme potekati
var start_lights: Node2D # opredeli se, če je semafor spawnan (če je na tilemapu)

onready var tilemap_floor: TileMap = $Floor
onready var tilemap_elements: TileMap = $Elements
onready var tilemap_edge: TileMap = $Edge

# floor
var corner_cell_TopL_regions: Array = [
	Vector2(2,3), Vector2(1,5),
	Vector2(8,6), Vector2(10,6), Vector2(12,6), Vector2(14,6),
	Vector2(3,8), Vector2(5,8), Vector2(14,8),
	Vector2(2,13), Vector2(8,13), Vector2(14,13),
	Vector2(9,15), Vector2(11,15),
	Vector2(9,17), Vector2(11,17)
	]
var corner_cell_TopR_regions: Array =[
	Vector2(0,3), Vector2(5,5),
	Vector2(7,6), Vector2(9,6), Vector2(11,6), Vector2(13,6),
	Vector2(2,8), Vector2(4,8), Vector2(13,8),
	Vector2(1,13), Vector2(7,13), Vector2(13,13),
	Vector2(8,15), Vector2(10,15),
	Vector2(8,17), Vector2(10,17)
	]
var corner_cell_BtmL_regions: Array = [
	Vector2(2,1), Vector2(1,9),
	Vector2(8,5), Vector2(10,5), Vector2(12,5), Vector2(14,5),
	Vector2(3,7), Vector2(5,7), Vector2(14,7),
	Vector2(2,12), Vector2(8,12), Vector2(14,12),
	Vector2(9,14), Vector2(11,14),
	Vector2(9,16), Vector2(11,16)
	]
var corner_cell_BtmR_regions: Array = [
	Vector2(0,1), Vector2(5,9),
	Vector2(7,5), Vector2(9,5), Vector2(11,5), Vector2(13,5),
	Vector2(2,7), Vector2(4,7), Vector2(13,7),
	Vector2(1,12), Vector2(7,12), Vector2(13,12),
	Vector2(8,14), Vector2(10,14),
	Vector2(8,16), Vector2(10,16)
	]
onready var corner_tile: PackedScene = preload("res://game/arena_elements/AreaHoleCorner.tscn")
onready var test_tile: PackedScene = preload("res://game/arena_elements/AreaHole.tscn")	

# navigacija
var navigation_cells: Array
var navigation_cells_positions: Array
var checkpoints_count: int

onready var racing_navigation_agent: NavigationAgent2D = $Positions/StartPosition/NavigationAgent2D
onready var level_navigation_line: Line2D = $LevelNavigactionLine
onready var level_position_nodes: Array = $Positions.get_children()
onready var racing_line: Node2D = $RacingLine

# sounds
onready var sounds: Node = $Sounds
onready var hit_bullet: AudioStreamPlayer = $Sounds/HitBullet
onready var hit_bullet_wall: AudioStreamPlayer = $Sounds/HitBulletWall
onready var hit_bullet_brick: AudioStreamPlayer = $Sounds/HitBulletBrick
onready var hit_misile: AudioStreamPlayer = $Sounds/HitMisile
onready var nitro: AudioStreamPlayer = $Sounds/Nitro
onready var de_nitro: AudioStreamPlayer = $Sounds/DeNitro
onready var magnet_in: AudioStreamPlayer = $Sounds/MagnetIn
onready var magnet_loop: AudioStreamPlayer = $Sounds/MagnetLoop
onready var magnet_out: AudioStreamPlayer = $Sounds/MagnetOut


func _ready() -> void:
	# debug
	printt("LEVEL")
#	$Comments.hide()
#	$ScreenSize.hide()
#	$RacingLine.hide()
#	$RacingLine.hide()
#	level_navigation_line.hide()
	Ref.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje
	
	set_level_floor() # lukenje
	set_level_elements() # elementi
	set_level_edge() # navigacija ... more bit po elementsih zato, da se prilagodi navigacija ... 
	get_navigation_racing_line()
	on_all_is_set() # pošljem vsebino levela v GM


func get_navigation_racing_line():
	
	racing_navigation_agent.set_target_location(level_position_nodes[5].global_position)
	level_navigation_line.points = racing_navigation_agent.get_nav_path()
	

	
func _physics_process(delta: float) -> void:
	
	racing_navigation_agent.get_next_location()
	
	
# SET TILEMAPS --------------------------------------------------------------------------------------------------------


func on_all_is_set():
	
	emit_signal("level_is_set", level_position_nodes, navigation_cells, navigation_cells_positions, checkpoints_count)

		
func set_level_floor():
	# poberi vse celice podna, tudi prazne
	# vsem praznim pripiši luknjo
	# vse ostale so background	
	
	var floor_cells = get_tilemap_cells(tilemap_floor)
	
	if floor_cells.empty(): # če je prazen se navigacija ne seta
		return
		
	for cell in floor_cells:
		var cell_index = tilemap_floor.get_cellv(cell)
		var cell_local_position = tilemap_floor.map_to_world(cell)
		var cell_global_position = tilemap_floor.to_global(cell_local_position)
		
		if cell_index == -1:
			spawn_hole(cell_global_position)
			non_navigation_cell_positions.append(cell_global_position)


func set_level_elements():
	

#	var element_cells = get_tilemap_cells(tilemap_edge) # poberem celice edga, da je prave velikosti
	if tilemap_elements.get_used_cells().empty():
		return
		
	for cell in tilemap_elements.get_used_cells():
		
		var cell_index = tilemap_elements.get_cellv(cell)
		
		var cell_local_position = tilemap_elements.map_to_world(cell)
		var cell_global_position = tilemap_elements.to_global(cell_local_position)	
		var scene_to_spawn: PackedScene
		var single_tile_offset: Vector2 = Vector2(4,4)
		var double_tile_offset: Vector2 = Vector2(8,8)
		
		match cell_index:

			7: # brick ghost
				scene_to_spawn = preload("res://game/arena_elements/BrickGhost.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			8: # brick bouncer
				scene_to_spawn = preload("res://game/arena_elements/BrickBouncer.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			9: # brick magnet
				scene_to_spawn = preload("res://game/arena_elements/BrickMagnet.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			10: # brick target
				scene_to_spawn = preload("res://game/arena_elements/BrickTarget.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			11: # brick light
				scene_to_spawn = preload("res://game/arena_elements/BrickLight.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				
			# ------------------------------------------------------------------------------------------------------
				
			28: # area nitro ... 12
				scene_to_spawn = preload("res://game/arena_elements/AreaNitro.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
			29: # area gravel ... 13
				scene_to_spawn = preload("res://game/arena_elements/AreaGravel.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				non_navigation_cell_positions.append(cell_global_position)
			23: # area finish
				scene_to_spawn = preload("res://game/arena_elements/AreaFinish.tscn")
				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
				non_navigation_cell_positions.append(cell_global_position)
#				tilemap_elements.set_cellv(cell, -1)

			# ------------------------------------------------------------------------------------------------------

			14: # pickable bullet
				scene_to_spawn = Pro.pickable_profiles["BULLET"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			15: # pickable misile
				scene_to_spawn = Pro.pickable_profiles["MISILE"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			16: # pickable shocker
				scene_to_spawn = Pro.pickable_profiles["SHOCKER"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			17: # pickable shield
				scene_to_spawn = Pro.pickable_profiles["SHIELD"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			18: # pickable energy
				scene_to_spawn = Pro.pickable_profiles["ENERGY"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			19: # pickable life
				scene_to_spawn = Pro.pickable_profiles["LIFE"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			20: # pickable nitro
				scene_to_spawn = Pro.pickable_profiles["NITRO"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			21: # pickable tracking
				scene_to_spawn = Pro.pickable_profiles["TRACKING"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			22: # pickable random
				scene_to_spawn = Pro.pickable_profiles["RANDOM"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			27: # pickable gas
				scene_to_spawn = Pro.pickable_profiles["GAS"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			30: # pickable points
				scene_to_spawn = Pro.pickable_profiles["POINTS"]["scene_path"]
				spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)

			# ------------------------------------------------------------------------------------------------------
			
			6: # goal pillar
				scene_to_spawn = preload("res://game/arena_elements/GoalPillar.tscn")
				spawn_element(cell_global_position, scene_to_spawn, Vector2(36,36))
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			32: # semafor
				scene_to_spawn = preload("res://game/arena_elements/StartLights.tscn")
				start_lights = spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			33: # checkpoint_hor
				var checkpoint_rotation: float = 0
				spawn_checkpoint(cell_global_position, checkpoint_rotation)
				tilemap_elements.set_cellv(cell, -1)
			34: # checkpoint_ver
				var checkpoint_rotation: float = 90
				spawn_checkpoint(cell_global_position, checkpoint_rotation)
				tilemap_elements.set_cellv(cell, -1)


func set_level_edge():
	
	var edge_cells = get_tilemap_cells(tilemap_edge) # celice v obliki grid koordinat
	var range_to_check = 2 # št. celic v vsako stran čekiranja  
	
	for cell in edge_cells:
		var cell_index = tilemap_edge.get_cellv(cell)
		var cell_local_position = tilemap_edge.map_to_world(cell)
		var cell_global_position = tilemap_edge.to_global(cell_local_position)
		
		# če je prazna in ni zasedena z elemenotom, jo zamenjam z navigacijsko celico
		if cell_index == -1:
			if not non_navigation_cell_positions.has(cell_global_position):
				tilemap_edge.set_cellv(cell, 13)
				navigation_cells.append(cell) # grid pozicije
				navigation_cells_positions.append(cell_global_position)
				
				# če ima za soseda rob, pomeni, da je zunanja in jo odstranim
				var cell_in_check: Vector2
				var empy_cell_in_check_count: int = 0
				for y in (range_to_check * 2 + 1): # pregledam 5 celic v ver in hor smeri, s čekirano v sredini
					for x in (range_to_check * 2 + 1):
						cell_in_check = cell + Vector2(x - range_to_check, y - range_to_check) # čekirana celica je v sredini 5 pregledanih celic
						if tilemap_edge.get_cellv(cell_in_check) == 0 and empy_cell_in_check_count != 2:
							tilemap_edge.set_cellv (cell, -1)
							# zbrišem iz arrayev navigacije
							navigation_cells.erase(cell)
							navigation_cells_positions.erase(cell_global_position)
							empy_cell_in_check_count += 1
						else:
							empy_cell_in_check_count = 0
#							break
				print(empy_cell_in_check_count)


func get_tilemap_cells(tilemap: TileMap):
	# kadar me zanimajo tudi prazne celice
	
	var tilemap_cells: Array # celice v gridu
	
	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:	
			var cell: Vector2 = Vector2(x, y)
			tilemap_cells.append(cell)
	
	return tilemap_cells
	
	
# SPAWN --------------------------------------------------------------------------------------------------------


func spawn_checkpoint(checkpoint_global_position: Vector2, checkpoint_rotation: float):
	
	checkpoints_count += 1
	var Checkpoint: PackedScene =  preload("res://game/arena_elements/Checkpoint.tscn")
	var new_checkpoint_scene = Checkpoint.instance() #
	new_checkpoint_scene.position = checkpoint_global_position# + element_center_offset
	
	# če rotiram je hor zamik
	if checkpoint_rotation == 90:
		new_checkpoint_scene.global_rotation = deg2rad(checkpoint_rotation) # + element_center_offset
		new_checkpoint_scene.position.x += 8# + element_center_offset
#	new_checkpoint_scene.modulate = Color.green
	add_child(new_checkpoint_scene)
	
	return new_checkpoint_scene


func spawn_element(element_global_position: Vector2, element_scene: PackedScene, element_center_offset: Vector2):
	
	var new_element_scene = element_scene.instance() #
	new_element_scene.position = element_global_position + element_center_offset
	add_child(new_element_scene)
	
	return new_element_scene
		

func spawn_hole(global_pos):
	
	var new_tile = test_tile.instance()
	new_tile.global_position = global_pos + Vector2(5,4)
	get_parent().call_deferred("add_child",new_tile)
	

# SIGNALI --------------------------------------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void:
	
	level_navigation_line.points = racing_navigation_agent.get_nav_path()
	
