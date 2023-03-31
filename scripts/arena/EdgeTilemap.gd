extends TileMap

signal tilemap_completed # pošljem lokacije floor tiletov

var light_color: Color = Color.white		
#var floor_tiles: Array = []

var floor_tiles_positions: Array = []


onready var DebrisParticles: PackedScene = preload("res://scenes/arena/EdgeDebrisParticles.tscn")	
onready var ExplodingEdge: PackedScene = preload("res://scenes/arena/ExplodingEdge.tscn")	


func _ready() -> void:
	
	# resolucija tilemepa
	var screen_tiles_count: Vector2 = Vector2(get_viewport_rect().size.x / get_cell_size().x, get_viewport_rect().size.y / get_cell_size().y)
	
#	# v1 ... cel floor
#	# zapolni navigation tilemap
#	for x in screen_tiles_count.x:
#		for y in screen_tiles_count.y:	
#			var cell_id = get_cellv(Vector2(x, y))
#			if cell_id == -1:
#				set_cellv(Vector2(x, y), 3)
#
#	# tla so vsi tileti, ki imajo index navigacijskega tileta		
#	var floor_tiles: Array = get_used_cells_by_id(3)
#	for tile_position in floor_tiles:
##		set_cellv(tile_position, 4)
#		var tile_world_position_local = map_to_world(tile_position)
#		var tile_world_position = to_global(tile_world_position_local)
#		floor_tiles_positions.append(tile_world_position)
#
#	emit_signal("tilemap_completed", floor_tiles_positions) # pošljemo na level, da ga potem pošlje enemiju
	
	# v2 ... nekje spredej
	
	var floor_tiles: Array# = get_used_cells_by_id(3)
	
	# zapolni navigation tilemap
	for x in screen_tiles_count.x:
		for y in screen_tiles_count.y:	
			var cell_position: Vector2 = Vector2(x, y)
			var cell_id = get_cellv(cell_position)

			# vsaka prazna je poden
			if cell_id == -1:
				set_cellv(cell_position, 3)
				var tile_world_position_local = map_to_world(cell_position)
				var tile_world_position = to_global(tile_world_position_local)
				floor_tiles_positions.append(tile_world_position)
			
			# odstrani zunanji vrstice
			# preveri vse sosede in, če je samo ena prazna jo sprazni
				
#			for y in 3:
#				for x in 3:
#					target_cell = current_cell + Vector2(x - 1, y - 1)
#					if current_cell != target_cell:
#						surrounding_cells.append(target_cell)
#
			
			
	# tla so vsi tileti, ki imajo index navigacijskega tileta		
#	for tile_position in floor_tiles:
	
	emit_signal("tilemap_completed", floor_tiles_positions) # pošljemo na level, da ga potem pošlje enemiju
	
	
	
	
func on_hit (collision_object):
			
	if collision_object.is_in_group("Bullets") == true:
		
		# menjava celice
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized() # dodamo malo v smeri gibanja, zato, da je res izbran pravi tile
		var cell_position: Vector2 = world_to_map(collision_position) # katera celica je bila zadeta glede na global coords
		var cell_index: int = get_cellv(cell_position) # index zadete celice na poziciji v grid koordinatah
		if cell_index != -1: # če ni prazen
			var cell_region_position = get_cell_autotile_coord(cell_position.x, cell_position.y) # položaj celice v autotile regiji
			set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
		
		release_debris(collision_object.collision)
	
	
	elif collision_object.is_in_group("Misiles") == true:
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
		
		var cell_position: Vector2 = world_to_map(collision_position) # katera celica je bila zadeta glede na global coords
		var cell_index: int = get_cellv(cell_position) # index zadete celice na poziciji v grid koordinatah

		if cell_index != -1: # če ni prazen
			set_cellv(cell_position, -1) # namestimo celico iz autotile regije z id = 2
			update_bitmask_area(cell_position) # vse celice se apdejtajo glede na novo stanje
			explode(cell_position)


func release_debris(collision):

	var new_debris_particles = DebrisParticles.instance() 
	new_debris_particles.position = collision.position
	new_debris_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	new_debris_particles.color = light_color
	new_debris_particles.set_emitting(true)
	Global.effects_creation_parent.add_child(new_debris_particles)


func explode(current_cell):
	
	get_surrounding_cells(current_cell)
	var cell_global_position = map_to_world(current_cell)

	var new_exploding_cell = ExplodingEdge.instance()
	new_exploding_cell.global_position = cell_global_position
	Global.node_creation_parent.add_child(new_exploding_cell)


func get_surrounding_cells(current_cell):
	
	var surrounding_cells = []
	var target_cell
	
	for y in 3:
		for x in 3:
			target_cell = current_cell + Vector2(x - 1, y - 1)
			if current_cell != target_cell:
				surrounding_cells.append(target_cell)
	
	for cell in surrounding_cells:
		var cell_region_position = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
		set_cellv(cell, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2


func get_player_surrounding_cells(current_cell):
	
	var surrounding_cells = []
	var target_cell
	
	for y in 3:
		for x in 3:
			target_cell = current_cell + Vector2(x - 1, y - 1)
			if current_cell != target_cell:
				surrounding_cells.append(target_cell)
	
	for cell in surrounding_cells:
		var cell_region_position = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
		set_cellv(cell, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
