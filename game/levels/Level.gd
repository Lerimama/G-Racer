extends Node2D

signal level_navigation_finished(navigation)
signal level_is_set(navigation, spawn_positions, other_)


# navigacija
var navigation_cells: Array
var navigation_cells_positions: Array
var checkpoints_count: int
var non_navigation_cell_positions: Array # elementi, kjer navigacija ne sme potekati
onready var racing_navigation_agent: NavigationAgent2D = $Positions/StartPosition/NavigationAgent2D

# tilemaps
onready var tilemap_floor: TileMap = $Floor
onready var tilemap_elements: TileMap = $Elements
onready var tilemap_edge: TileMap = $Edge

# level elements
onready var level_navigation_line: Line2D = $LevelNavigationLine # zaenkrat ne uporabljam
onready var position_nodes: Array = $Positions.get_children()
onready var racing_line: Node2D = $RacingLine
onready var finish_line: Area2D = $FinishLine
onready var start_lights: Node2D = $StartLights
onready var background_space: Sprite = $BackgroundSpace

# obs
onready var area_hole_scene: PackedScene = preload("res://game/arena_elements/areas/AreaHole.tscn")	

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

# elements
onready var BrickGhost: PackedScene = preload("res://game/arena_elements/bricks/BrickGhost.tscn")
onready var BrickBouncer: PackedScene = preload("res://game/arena_elements/bricks/BrickBouncer.tscn")
onready var BrickMagnet: PackedScene = preload("res://game/arena_elements/bricks/BrickMagnet.tscn")
onready var BrickTarget: PackedScene = preload("res://game/arena_elements/bricks/BrickTarget.tscn")
onready var BrickLight: PackedScene = preload("res://game/arena_elements/bricks/BrickLight.tscn")
onready var AreaNitro: PackedScene = preload("res://game/arena_elements/areas/AreaNitro.tscn")
onready var AreaGravel: PackedScene = preload("res://game/arena_elements/areas/AreaGravel.tscn")
onready var PickableBullet: PackedScene = Pro.pickable_profiles["BULLET"]["scene_path"]
onready var PickableMisile: PackedScene = Pro.pickable_profiles["MISILE"]["scene_path"]
onready var PickableMina: PackedScene = Pro.pickable_profiles["MINA"]["scene_path"]
onready var PickableShocker: PackedScene = Pro.pickable_profiles["SHOCKER"]["scene_path"]
onready var PickableShield: PackedScene = Pro.pickable_profiles["SHIELD"]["scene_path"]
onready var PickableEnergy: PackedScene = Pro.pickable_profiles["ENERGY"]["scene_path"]
onready var PickableLife: PackedScene = Pro.pickable_profiles["LIFE"]["scene_path"]
onready var PickableNitro: PackedScene = Pro.pickable_profiles["NITRO"]["scene_path"]
onready var PickableTracking: PackedScene = Pro.pickable_profiles["TRACKING"]["scene_path"]
onready var PickableRandom: PackedScene = Pro.pickable_profiles["RANDOM"]["scene_path"]
onready var PickableGas: PackedScene = Pro.pickable_profiles["GAS"]["scene_path"]
onready var PickablePoints: PackedScene = Pro.pickable_profiles["POINTS"]["scene_path"]
	
	
	
func _ready() -> void:
	# debug
	printt("LEVEL")
	if not Set.debug_mode:
		$Positions.hide()
		$Comments.hide()
		$ScreenSize.hide()
		$Instructions.hide()
		$RacingLine.hide()
	level_navigation_line.hide()
	$StartLabel.show()
	
	Ref.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje
	
	# kar je skrito, ne deluje
	if background_space.visible:
		background_space.get_node("Zvezde").emitting = true
	if finish_line.visible:
		finish_line.monitoring = true
	if not Ref.game_manager.game_settings["start_countdown"]:	
		start_lights.hide()
		
		
	set_level_floor() # luknje
	set_level_elements() # elementi
	set_level_navigation() # navigacija ... more bit po elementsih zato, da se prilagodi navigacija ... 
	# get_navigation_racing_line() ... uporabno ko bo main racing line avtomatiziran 
	on_all_is_set() # pošljem vsebino levela v GM


func get_navigation_racing_line():
	
	racing_navigation_agent.set_target_location(position_nodes[5].global_position)
	level_navigation_line.points = racing_navigation_agent.get_nav_path()

	
func _physics_process(delta: float) -> void:
	
	racing_navigation_agent.get_next_location()
	
	
func on_all_is_set():
	
	emit_signal("level_is_set", position_nodes, navigation_cells, navigation_cells_positions, checkpoints_count)


# SET TILEMAPS --------------------------------------------------------------------------------------------------------

		
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
				spawn_element(cell_global_position, BrickGhost, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			8: # brick bouncer
				spawn_element(cell_global_position, BrickBouncer, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			9: # brick magnet
				spawn_element(cell_global_position, BrickMagnet, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			10: # brick target
				spawn_element(cell_global_position, BrickTarget, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
			11: # brick light
				spawn_element(cell_global_position, BrickLight, single_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
				
			# ------------------------------------------------------------------------------------------------------
				
			28: # area nitro ... 12
				spawn_element(cell_global_position, AreaNitro, single_tile_offset)
			29: # area gravel ... 13
				spawn_element(cell_global_position, AreaGravel, single_tile_offset)
				non_navigation_cell_positions.append(cell_global_position)
#			23: # area finish
#				spawn_element(cell_global_position, scene_to_spawn, single_tile_offset)
#				non_navigation_cell_positions.append(cell_global_position)
##				tilemap_elements.set_cellv(cell, -1)

			# ------------------------------------------------------------------------------------------------------

			14: # pickable bullet
				spawn_element(cell_global_position, PickableBullet, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			15: # pickable misile
				spawn_element(cell_global_position, PickableMisile, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			35: # pickable mina
				spawn_element(cell_global_position, PickableMina, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			16: # pickable shocker
				spawn_element(cell_global_position, PickableShocker, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			17: # pickable shield
				spawn_element(cell_global_position, PickableShield, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			18: # pickable energy
				spawn_element(cell_global_position, PickableEnergy, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			19: # pickable life
				spawn_element(cell_global_position, PickableLife, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			20: # pickable nitro
				spawn_element(cell_global_position, PickableNitro, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			21: # pickable tracking
				spawn_element(cell_global_position, PickableTracking, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			22: # pickable random
				spawn_element(cell_global_position, PickableRandom, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			27: # pickable gas
				spawn_element(cell_global_position, PickableGas, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)
			30: # pickable points
				spawn_element(cell_global_position, PickablePoints, double_tile_offset)
				tilemap_elements.set_cellv(cell, -1)

			# ------------------------------------------------------------------------------------------------------
			
			6: # goal pillar
				var GoalPillar: PackedScene = preload("res://game/arena_elements/GoalPillar.tscn")
				spawn_element(cell_global_position, scene_to_spawn, Vector2(36,36))
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)
#			32: # semafor
#				scene_to_spawn = preload("res://game/arena_elements/StartLights.tscn")
#				start_lights = spawn_element(cell_global_position, scene_to_spawn, double_tile_offset)
#				tilemap_elements.set_cellv(cell, -1)
			33: # checkpoint_hor
				var checkpoint_rotation: float = 0
				spawn_checkpoint(cell_global_position, checkpoint_rotation)
				tilemap_elements.set_cellv(cell, -1)
			34: # checkpoint_ver
				var checkpoint_rotation: float = 90
				spawn_checkpoint(cell_global_position, checkpoint_rotation)
				tilemap_elements.set_cellv(cell, -1)


func set_level_navigation():
	
	var edge_cells = get_tilemap_cells(tilemap_edge) # celice v obliki grid koordinat
	var range_to_check = 1 # št. celic v vsako stran čekiranja  
	
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
		
		tilemap_edge.bake_navigation = true
		
	# zelene spremenim prazne po navigaciji
	for cell in edge_cells:
		var cell_index = tilemap_edge.get_cellv(cell)
		if cell_index == 5:
			tilemap_edge.set_cellv(cell, -1)


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
	if checkpoint_rotation == 90: # če rotiram je hor zamik
		new_checkpoint_scene.global_rotation = deg2rad(checkpoint_rotation) # + element_center_offset
		new_checkpoint_scene.position.x += 8# + element_center_offset
	new_checkpoint_scene.modulate.a = 0
	add_child(new_checkpoint_scene)
	
	return new_checkpoint_scene


func spawn_element(element_global_position: Vector2, element_scene: PackedScene, element_center_offset: Vector2):
	
	var new_element_scene = element_scene.instance() #
	new_element_scene.position = element_global_position + element_center_offset
	add_child(new_element_scene)
	
	return new_element_scene
		

func spawn_hole(global_pos):
	
	return
	var new_hole_scene = area_hole_scene.instance()
	new_hole_scene.global_position = global_pos + Vector2(5,4)
	get_parent().call_deferred("add_child", new_hole_scene)
	

# SIGNALI --------------------------------------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void:
	
	level_navigation_line.points = racing_navigation_agent.get_nav_path()
	
