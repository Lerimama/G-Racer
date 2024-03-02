extends Node2D


signal level_is_set(navigation, spawn_positions, other_)

onready var tilemap_floor: TileMap = $Floor
onready var tilemap_elements: TileMap = $Elements
onready var tilemap_edge: TileMap = $Edge

onready var positions: Array = $Positions.get_children()
onready var racing_line: Node2D = $RacingLine


func _ready() -> void:
	
	Ref.current_level = self # zaenkrat samo zaradi pozicij ... lahko bi bolje
	printt("Level ")
	set_level_floor()
	set_level_edge()
	set_level_elements()


func get_tilemap_cells(tilemap: TileMap):

	
	var tilemap_cells: Array # celice v gridu
	
	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:	
			var cell: Vector2 = Vector2(x, y)
			tilemap_cells.append(cell)
	
	return tilemap_cells


# ELEMENTS ---------------------------------------------------------------------------------------------------------------------------------


onready var goal_pillar: PackedScene = preload("res://game/arena_elements/GoalPillar.tscn")
onready var brick_ghost: PackedScene = preload("res://game/arena_elements/BrickGhost.tscn")
onready var brick_bouncer: PackedScene = preload("res://game/arena_elements/BrickBouncer.tscn")
onready var brick_magnet: PackedScene = preload("res://game/arena_elements/BrickMagnet.tscn")
onready var brick_target: PackedScene = preload("res://game/arena_elements/BrickTarget.tscn")
onready var brick_light: PackedScene = preload("res://game/arena_elements/BrickLight.tscn")
onready var area_nitro: PackedScene = preload("res://game/arena_elements/AreaNitro.tscn")
onready var area_tracking: PackedScene = preload("res://game/arena_elements/AreaTracking.tscn")
onready var area_gravel: PackedScene = preload("res://game/arena_elements/AreaGravel.tscn")
onready var area_finish: PackedScene = preload("res://game/arena_elements/AreaFinish.tscn")

onready var pickable_energy: PackedScene = preload("res://game/arena_elements/pickables/PickableEnergy.tscn")
onready var pickable_life: PackedScene = preload("res://game/arena_elements/pickables/PickableLife.tscn")
onready var pickable_bullet: PackedScene = preload("res://game/arena_elements/pickables/PickableBullet.tscn")
onready var pickable_misile: PackedScene = preload("res://game/arena_elements/pickables/PickableMisile.tscn")
onready var pickable_shocker: PackedScene = preload("res://game/arena_elements/pickables/PickableShocker.tscn")
onready var pickable_shield: PackedScene = preload("res://game/arena_elements/pickables/PickableShield.tscn")
onready var pickable_nitro: PackedScene = preload("res://game/arena_elements/pickables/PickableNitro.tscn")
onready var pickable_tracking: PackedScene = preload("res://game/arena_elements/pickables/PickableTracking.tscn")
onready var pickable_random: PackedScene = preload("res://game/arena_elements/pickables/PickableRandom.tscn")
onready var pickable_gas: PackedScene = preload("res://game/arena_elements/pickables/PickableGas.tscn")


func set_level_elements():
	

	var element_cells = get_tilemap_cells(tilemap_edge) # poberem celice edga, da je prave velikosti
	
	for cell in element_cells:
		
		var cell_index = tilemap_elements.get_cellv(cell)
		var cell_local_position = tilemap_elements.map_to_world(cell)
		var cell_global_position = tilemap_elements.to_global(cell_local_position)	
	
		match cell_index:
			6: # goal pillar
				spawn_element(cell_global_position, goal_pillar, Vector2(13,12))
				tilemap_elements.set_cellv(cell, -1)
				
			7: # brick ghost
				spawn_element(cell_global_position, brick_ghost, Vector2(5,4))
				tilemap_elements.set_cellv(cell, -1)
			8: # brick bouncer
				spawn_element(cell_global_position, brick_bouncer, Vector2(5,4))
				tilemap_elements.set_cellv(cell, -1)
			9: # brick magnet
				spawn_element(cell_global_position, brick_magnet, Vector2(5,4))
				tilemap_elements.set_cellv(cell, -1)
			10: # brick target
				spawn_element(cell_global_position, brick_target, Vector2(5,4))
				tilemap_elements.set_cellv(cell, -1)
			11: # brick light
				spawn_element(cell_global_position, brick_light, Vector2(5,4))
				tilemap_elements.set_cellv(cell, -1)
				
			12: # area nitro
				spawn_element(cell_global_position, area_nitro, Vector2(5,4))
			13: # area magnet
				spawn_element(cell_global_position, area_gravel, Vector2(5,4))
			23: # area finish
				spawn_element(cell_global_position, area_finish, Vector2(9,8))
#				tilemap_elements.set_cellv(cell, -1)
				
			14: # pickable bullet
				spawn_element(cell_global_position, pickable_bullet, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			15: # pickable misile
				spawn_element(cell_global_position, pickable_misile, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			16: # pickable shocker
				spawn_element(cell_global_position, pickable_shocker, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			17: # pickable shield
				spawn_element(cell_global_position, pickable_shield, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			18: # pickable energy
				spawn_element(cell_global_position, pickable_energy, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			19: # pickable life
				spawn_element(cell_global_position, pickable_life, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			20: # pickable nitro
				spawn_element(cell_global_position, pickable_nitro, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			21: # pickable tracking
				spawn_element(cell_global_position, pickable_tracking, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			22: # pickable random
				spawn_element(cell_global_position, pickable_random, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)
			27: # pickable gas
				spawn_element(cell_global_position, pickable_gas, Vector2(9,8))
				tilemap_elements.set_cellv(cell, -1)


func spawn_element(element_global_position: Vector2, element_scene: PackedScene, element_center_offset: Vector2):
	
	var new_element_scene = element_scene.instance() #
	new_element_scene.position = element_global_position + element_center_offset
	add_child(new_element_scene)	


# EDGE ---------------------------------------------------------------------------------------------------------------------------------


func set_level_edge():
	
	var edge_cells = get_tilemap_cells(tilemap_elements) # celice v obliki grid koordinat

	var navigation_cells: Array
	var navigation_cells_positions: Array

	for cell in edge_cells:
		var cell_index = tilemap_edge.get_cellv(cell)
		var cell_local_position = tilemap_edge.map_to_world(cell)
		var cell_global_position = tilemap_edge.to_global(cell_local_position)

		# če je prazna, jo zamenjam z navigacijsko celico
		if cell_index == -1:
			tilemap_edge.set_cellv(cell, 13)
			navigation_cells.append(cell) # grid pozicije
			navigation_cells_positions.append(cell_global_position)
			
	# odstrani zunanje rob navigacije (rob je vsaka, ki ima eno od sosednjih celic prazno
#	var navigation_cell_index = 0
#	for cell in navigation_cells:
#		var cell_in_check: Vector2
#		# pregledam 5 celic v ver in hor smeri
#		for y in 5: 
#			for x in 5:
#				cell_in_check = cell + Vector2(x - 2, y - 2) # čekirana celica je v sredini 5 pregledanih celic
#				if tilemap_edge.get_cellv(cell_in_check) == 0:
#					tilemap_edge.set_cellv (cell, -1)
#					break # ko je ena prazna, ne rabi več čekirat
#		navigation_cell_index += 1
#	yield(get_tree().create_timer(0.1), "timeout")
	
	emit_signal("level_is_set", positions, navigation_cells, navigation_cells_positions)



# FLOOR --------------------------------------------------------------------------------------------------------------------------------


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
	
	
func set_level_floor():
	# poberi vse celice podna
	# vse ki so prazne so del luknje
	# vsem praznim pripiši luknjo
	# vse vogalne, ki so index X in outotile koordinate Y ... so del luknje
	# vsem v autotiletu pripiši GapRL, ...
	# vse ostale so background	
	
	var floor_cells = get_tilemap_cells(tilemap_floor)
	
	for cell in floor_cells:
		var cell_index = tilemap_floor.get_cellv(cell)
		var cell_local_position = tilemap_floor.map_to_world(cell)
		var cell_global_position = tilemap_floor.to_global(cell_local_position)
		
		if cell_index == -1:
			spawn_hole(cell_global_position)
		
		# če ni prazen, ampak ima id podn tajla
		elif cell_index == 0:
			# spawn_corner
			var cell_autotile_region = tilemap_floor.get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
#			set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
			if corner_cell_TopL_regions.has(cell_autotile_region):
				spawn_corner(cell_global_position, "TopL")
			if corner_cell_TopR_regions.has(cell_autotile_region):
				spawn_corner(cell_global_position, "TopR")
			if corner_cell_BtmL_regions.has(cell_autotile_region):
				spawn_corner(cell_global_position, "BtmL")
			if corner_cell_BtmR_regions.has(cell_autotile_region):
				spawn_corner(cell_global_position, "BtmR")	

	
func spawn_corner(global_pos, corner_type):
	
	var new_corner_tile = corner_tile.instance()
	new_corner_tile.global_position = global_pos + Vector2(5,4) # dodan zamik centra
	get_parent().call_deferred("add_child",new_corner_tile )
	match corner_type:
		"TopL":
			new_corner_tile.rotation_degrees = 0
		"TopR":
			new_corner_tile.rotation_degrees = 90
		"BtmL":
			new_corner_tile.rotation_degrees = -90
		"BtmR":
			new_corner_tile.rotation_degrees = 180


func spawn_hole(global_pos):
	
	var new_tile = test_tile.instance()
	new_tile.global_position = global_pos + Vector2(5,4)
	get_parent().call_deferred("add_child",new_tile)

