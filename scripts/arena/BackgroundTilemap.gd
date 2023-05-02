extends TileMap


#onready var tilemap_rect = get_parent().get_used_rect()
#onready var tilemap_cell_size = get_parent().cell_size
#onready var color = Color(0.0, 1.0, 0.0)

signal floor_completed # pošljem luknje v tleh

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
#onready var DebrisParticles: PackedScene = preload("res://scenes/arena/EdgeDebrisParticles.tscn")	
#onready var ExplodingEdge: PackedScene = preload("res://scenes/arena/ExplodingEdge.tscn")	
onready var test_tile: PackedScene = preload("res://scenes/arena/FloorGap.tscn")
onready var corner_tile: PackedScene = preload("res://scenes/arena/FloorGapCorner.tscn")



func _ready() -> void:
	
#	add_to_group(Config.group_arena)
	get_floor_tiles()
#	Global.level_tilemap = self
	
	
func get_floor_tiles():
	
	# koliko celic je na celem ekranu
	var cell_count_x: float = get_viewport_rect().size.x / get_cell_size().x
	var cell_count_y: float = get_viewport_rect().size.y / get_cell_size().y
	var floor_cells_grid: Array # grid koordinate
	var floor_cells: Array # global koordinate
	
	# prečesi vse celice na tilemapu
	for x in cell_count_x:
		for y in cell_count_y:	
			
			var cell: Vector2 = Vector2(x, y)
			var cell_index = get_cellv(cell)
			# pretvorba v globalno pozicijo
			var cell_local_position = map_to_world(cell)
			var cell_global_position = to_global(cell_local_position)
			
			# če je index -1 daj tja luknjo
			if cell_index == -1:
				spawn_hole(cell_global_position)
				
			# če ni prazen, ampak ima id podn tajla
			elif cell_index == 0:
				
				# spawn_corner
				var cell_autotile_region = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
#				set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
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

#	$new_corner_tile.connect("path_changed", self, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš
	
	
func spawn_hole(global_pos):
	
	var new_tile = test_tile.instance()
	new_tile.global_position = global_pos + Vector2(5,4)
	get_parent().call_deferred("add_child",new_tile )
#	get_parent().add_child (new_tile)
	
	
func on_hit (collision_object):
			
	if collision_object.is_in_group("Bullets") == true:
		
		# menjava celice
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized() # dodamo malo v smeri gibanja, zato, da je res izbran pravi tile
		var cell_position: Vector2 = world_to_map(collision_position) # katera celica je bila zadeta glede na global coords
		var cell_index: int = get_cellv(cell_position) # index zadete celice na poziciji v grid koordinatah
		if cell_index != -1: # če ni prazen
			var cell_region_position = get_cell_autotile_coord(cell_position.x, cell_position.y) # položaj celice v autotile regiji
			set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
		
	
	
	elif collision_object.is_in_group("Misiles") == true:
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
		
		var cell_position: Vector2 = world_to_map(collision_position) # katera celica je bila zadeta glede na global coords
		var cell_index: int = get_cellv(cell_position) # index zadete celice na poziciji v grid koordinatah

		if cell_index != -1: # če ni prazen
			set_cellv(cell_position, -1) # namestimo celico iz autotile regije z id = 2
			update_bitmask_area(cell_position) # vse celice se apdejtajo glede na novo stanje
#			explode_tile(cell_position)
	
	# poberi vse celice podna
	# vse ki so prazne so del luknje
	# vsem praznim pripiši gap
	# vse, ki so index X in outotile koordinate Y ... so del luknje
	# vsem v outo tiletu pripiši GapRL, ...
	# vse ostale so background

#func release_debris(collision):
#
#	var new_debris_particles = DebrisParticles.instance() 
#	new_debris_particles.position = collision.position
#	new_debris_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
#	new_debris_particles.color = light_color
#	new_debris_particles.set_emitting(true)
#	Global.effects_creation_parent.add_child(new_debris_particles)


#func explode_tile(current_cell):
#
#	damage_surrounding_cells(current_cell)
#	var cell_global_position = map_to_world(current_cell)
#
#	var new_exploding_cell = ExplodingEdge.instance()
#	new_exploding_cell.global_position = cell_global_position
#	Global.node_creation_parent.add_child(new_exploding_cell)


func damage_surrounding_cells(current_cell):
	
	var surrounding_cells: Array = []
	var target_cell
	
	for y in 3:
		for x in 3:
			target_cell = current_cell + Vector2(x - 1, y - 1)
			if current_cell != target_cell:
				surrounding_cells.append(target_cell)
	
	for cell in surrounding_cells:
		var cell_region_position = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
		set_cellv(cell, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
