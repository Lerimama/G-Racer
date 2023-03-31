extends TileMap
			

onready var DebrisParticles: PackedScene = preload("res://scenes/arena/EdgeDebrisParticles.tscn")	
onready var ExplodingEdge: PackedScene = preload("res://scenes/arena/ExplodingEdge.tscn")	

	
func on_hit (collision_object):
	
#	if collision_object.is_in_group("misiles") != true:
#		print (get_surrounding_tiles())
		
	
#	if collision_object.is_in_group("Shockers") != true:
	if collision_object.is_in_group("Bullets") == true:
		
		# debris partikli
		var new_debris_particles = DebrisParticles.instance() 
		new_debris_particles.position = collision_object.collision.position
#		new_debris_particles.rotation = collision_object.collision.normal.angle() # rotacija partiklov glede na normalo površine 
		
		
		var smer = collision_object.collision.collider_velocity
		print (new_debris_particles.direction)
		new_debris_particles.direction = smer
#		new_debris_particles.rotation = collision_object.collision.get_angle() # rotacija partiklov glede na normalo površine 
#		new_debris_particles.rotation = collision_object.collision.normal.angle() # rotacija partiklov glede na normalo površine 
#		new_hit_particles.color = spawned_by_color
		new_debris_particles.modulate = Color.red
		new_debris_particles.set_emitting(true)
		Global.effects_creation_parent.add_child(new_debris_particles)
	
		
		
		# menjava celice
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
		# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu, kar pomeni, da lahko ponesreči izbriše prazen tile
		# zato s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 
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
			update_bitmask_area(cell_position)
			
#			var cell_region_position = get_cell_autotile_coord(cell_position.x, cell_position.y) # položaj celice v autotile regiji
#			set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
			get_surrounding_tiles(cell_position)


func get_surrounding_tiles(current_tile):
	
	var surr_tiles = []
	var target_tile
	
	for y in 3:
		for x in 3:
			target_tile = current_tile + Vector2(x - 1, y - 1)
			
			if current_tile == target_tile:
				continue
			surr_tiles.append(target_tile)
#	return surr_tiles
	
	for tile in surr_tiles:
#		set_cellv(tile, -1)
		var cell_region_position = get_cell_autotile_coord(tile.x, tile.y) # položaj celice v autotile regiji
		set_cellv(tile, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
	
