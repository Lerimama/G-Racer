extends Node2D

signal level_navigation_finished(navigation)
signal level_is_set(navigation, spawn_positions, other_)

enum LevelTypes {RACE, RACE_LAPS, BATTLE}
export (LevelTypes) var level_type: int = LevelTypes.RACE

var single_tile_offset: Vector2 = Vector2(4,4)
var double_tile_offset: Vector2 = Vector2(8,8)
	
# navigacija
var navigation_cells: Array
var navigation_cells_positions: Array
var non_navigation_cell_positions: Array # elementi, kjer navigacija ne sme potekati
onready var racing_track: Path2D = $RacingTrack

# tilemaps
onready var tilemap_floor: TileMap = $Floor
onready var tilemap_elements: TileMap = $Elements
onready var tilemap_edge: TileMap = $Edge
onready var background_space: Sprite = $BackgroundSpace
onready var background: Node2D = $Background

# floor
onready var AreaNitro: PackedScene = preload("res://game/arena/areas/AreaNitro.tscn")
onready var AreaGravel: PackedScene = preload("res://game/arena/areas/AreaGravel.tscn")
onready var AreaHole: PackedScene = preload("res://game/arena/areas/AreaHole.tscn")	
# elements
onready var GoalPillar: PackedScene = preload("res://game/arena/elements/GoalPillar.tscn")
onready var BrickGhost: PackedScene = preload("res://game/arena/bricks/BrickGhost.tscn")
onready var BrickBouncer: PackedScene = preload("res://game/arena/bricks/BrickBouncer.tscn")
onready var BrickMagnet: PackedScene = preload("res://game/arena/bricks/BrickMagnet.tscn")
onready var BrickTarget: PackedScene = preload("res://game/arena/bricks/BrickTarget.tscn")
onready var BrickLight: PackedScene = preload("res://game/arena/bricks/BrickLight.tscn")
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

# sounds
#onready var sounds: Node = $Sounds
#onready var hit_bullet: AudioStreamPlayer = $Sounds/HitBullet
#onready var hit_bullet_wall: AudioStreamPlayer = $Sounds/HitBulletWall
#onready var hit_bullet_brick: AudioStreamPlayer = $Sounds/HitBulletBrick
#onready var hit_misile: AudioStreamPlayer = $Sounds/HitMisile
#onready var nitro: AudioStreamPlayer = $Sounds/Nitro
#onready var de_nitro: AudioStreamPlayer = $Sounds/DeNitro
#onready var magnet_in: AudioStreamPlayer = $Sounds/MagnetIn
#onready var magnet_loop: AudioStreamPlayer = $Sounds/MagnetLoop
#onready var magnet_out: AudioStreamPlayer = $Sounds/MagnetOut

# neu
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

	
func _ready() -> void:
	printt("LEVEL")
	
	Ref.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje

	# debug hide
	if not Set.debug_mode:
		$_Comments.hide()
		$_ScreenSize.hide()
		$_Instructions.hide()

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
	if finish_line.visible:
		finish_line.monitoring = true
	if background_space.visible:
		background_space.get_node("Zvezde").emitting = true
		
	set_level_floor() # luknje
	set_level_elements() # elementi
	set_level_navigation() # navigacija ... more bit po elementsih zato, da se prilagodi navigacija ... 
	# get_navigation_racing_line() ... uporabno ko bo main racing line avtomatiziran 
	on_all_is_set() # pošljem vsebino levela v GM


func _physics_process(delta: float) -> void:
	
	update_tile_shaders()
	
	
func on_all_is_set():
	
	# setam šejderje
	set_level_shaders()
	update_tile_shaders()
	# pošljem signal
	emit_signal("level_is_set", navigation_cells, navigation_cells_positions)


# SET SHADERS --------------------------------------------------------------------------------------------------------


func update_tile_shaders():
	
	
	var tile_with_shader_id: int # za kateri tajl setamo transforme
	
	for tilemap in [tilemap_edge, tilemap_floor]:
		match tilemap:
			tilemap_floor:
				tile_with_shader_id = 5
			tilemap_edge:
				tile_with_shader_id = 0
				
		var tilemap_material: ShaderMaterial = tilemap.tile_set.tile_get_material(tile_with_shader_id)
		var local_to_view: Transform2D = tilemap.get_viewport_transform() * tilemap.global_transform
		var view_to_local: Transform2D = local_to_view.affine_inverse()
		tilemap_material.set_shader_param("view_to_local", view_to_local)
	
	
func set_level_shaders():
	# shader node resizam ne velikost floor tilemapa
	# setam šejder parametre
	
	# velikost floor tilemapa
	var first_floor_cell = tilemap_floor.get_used_cells().pop_front()
	var last_floor_cell = tilemap_floor.get_used_cells().pop_back()
	var floor_rect_position = tilemap_floor.map_to_world(first_floor_cell)
	var floor_rect_size = tilemap_floor.map_to_world(last_floor_cell) - tilemap_floor.map_to_world(first_floor_cell)
	
	var nodes_to_resize: Array
	# background
	for node in background.get_children():
		if node.material:
			nodes_to_resize.append(node)
	# floor
	for node in tilemap_floor.get_children():
		nodes_to_resize.append(node)
	# edge
	for node in tilemap_edge.get_children():
		nodes_to_resize.append(node)
	# resize and set shader
	for node in nodes_to_resize:
		node.rect_position = floor_rect_position
		node.rect_size = floor_rect_size
		node.material.set_shader_param("node_size", floor_rect_size)

	# noise screen
	var tajlmeps: Array = [tilemap_edge, tilemap_floor]
	
	var tile_with_shader_id: int
	
	for tm in tajlmeps:
		match tm:
			tilemap_floor:
		#		var tm: TileMap = tilemap_floor
				tile_with_shader_id = 5
			#	var tm: TileMap = tilemap_elements
			#	var tile_with_shader_id: int = 36
			tilemap_edge:
				tile_with_shader_id = 0
				pass
				
		var ts: TileSet = tm.tile_set
		var sm: String = ts.tile_get_name(tile_with_shader_id)
		var tile = ts.find_tile_by_name(sm)
		var mat: ShaderMaterial = ts.tile_get_material(tile_with_shader_id)
		var local_to_view: Transform2D = tm.get_viewport_transform() * tm.global_transform
		var view_to_local: Transform2D = local_to_view.affine_inverse()
		#		printt ("shader_par", ts, tm, sm, local_to_view, view_to_local)
		mat.set_shader_param("view_to_local", view_to_local)		


# SET TILEMAPS --------------------------------------------------------------------------------------------------------

		
func set_level_floor():
	


	
		
	for cell in tilemap_floor.get_used_cells():
		
		var cell_index = tilemap_floor.get_cellv(cell)
		
		var cell_local_position = tilemap_floor.map_to_world(cell)
		var cell_global_position = tilemap_floor.to_global(cell_local_position)	
		var scene_to_spawn: PackedScene
		
		match cell_index:

			1: # area nitro
				spawn_element(cell_global_position, AreaNitro, single_tile_offset)
			2: # area gravel
				spawn_element(cell_global_position, AreaGravel, single_tile_offset)
				non_navigation_cell_positions.append(cell_global_position)
			3: # area hole
				return
				spawn_element(cell_global_position, AreaHole, single_tile_offset)
				non_navigation_cell_positions.append(cell_global_position)


func set_level_elements():
	
	if tilemap_elements.get_used_cells().empty():
		return
		
	for cell in tilemap_elements.get_used_cells():
		
		var cell_index = tilemap_elements.get_cellv(cell)
		
		var cell_local_position = tilemap_elements.map_to_world(cell)
		var cell_global_position = tilemap_elements.to_global(cell_local_position)	
		var scene_to_spawn: PackedScene
		
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
				spawn_element(cell_global_position, GoalPillar, Vector2(36,36))
				tilemap_elements.set_cellv(cell, -1)
				non_navigation_cell_positions.append(cell_global_position)


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


func spawn_element(element_global_position: Vector2, element_scene: PackedScene, element_center_offset: Vector2):
	
	var new_element_scene = element_scene.instance() #
	new_element_scene.position = element_global_position + element_center_offset
	add_child(new_element_scene)
	
	return new_element_scene


func _on_AreaFinish_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		Ref.game_manager.on_finish_line_crossed(body)
	

func _on_Checkpoint_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if not Ref.game_manager.bolts_checked.has(body):
			Ref.game_manager.bolts_checked.append(body)
