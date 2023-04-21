extends TileMap


# premaknjeno v Signals
signal navigation_completed # pošljem lokacije floor tiletov

var light_color: Color = Color.white # za barvanje debrisa		

onready var DebrisParticles: PackedScene = preload("res://scenes/arena/EdgeDebrisParticles.tscn")	
onready var ExplodingEdge: PackedScene = preload("res://scenes/arena/ExplodingEdge.tscn")	


func _ready() -> void:
	add_to_group(Config.group_arena)
	get_floor_navigation()
	Global.level_tilemap = self
	
func get_floor_navigation():
	
	var tilemap_cells_count: Vector2 = Vector2(get_viewport_rect().size.x / get_cell_size().x, get_viewport_rect().size.y / get_cell_size().y)
	var floor_cells_grid: Array # tilemap koordinate
	var floor_cells: Array # global pozicija
	
	# zapolni navigation tilemap
	for x in tilemap_cells_count.x:
		for y in tilemap_cells_count.y:	
			var cell_position: Vector2 = Vector2(x, y)
			var cell_id = get_cellv(cell_position)
			
			if cell_id == -1:
				set_cellv(cell_position, 3) # vsaka prazna je poden
				# pretvorba v globalno pozicijo
				var cell_local_position = map_to_world(cell_position)
				var cell_global_position = to_global(cell_local_position)
				
				floor_cells.append(cell_global_position)
				floor_cells_grid.append(cell_position)
	
	var id = 0
	# odstrani zunanje vrstice celic
	for floor_cell in floor_cells_grid:
		var cell_in_check: Vector2
		# preveri vse sosede
		for y in 3: 
			for x in 3:
				cell_in_check = floor_cell + Vector2(x - 1, y - 1)
				# če je vsaj ena soseda prazna, jo sprazni
				if get_cellv(cell_in_check) == 0:
					set_cellv (floor_cell, -1)
#					floor_cells.remove(id)
#					print(floor_cell)
#					print(id)
					continue
		id += 1
		
#	for obs in floor_cells:
#		if get_cellv(obs) == -1: 
#			floor_cells.remove(obs)
		
		
		
#	var new_arej = get_used_cells_by_id(3)	
#	print(get_used_cells_by_id(3))		
#	Signals.emit_signal("navigation_completed", floor_cells) # pošljemo na level, da ga potem pošlje enemiju
	emit_signal("navigation_completed", floor_cells) # pošljemo na level, da ga potem pošlje enemiju
	
	
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
			explode_tile(cell_position)


func release_debris(collision):

	var new_debris_particles = DebrisParticles.instance() 
	new_debris_particles.position = collision.position
	new_debris_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	new_debris_particles.color = light_color
	new_debris_particles.set_emitting(true)
	Global.effects_creation_parent.add_child(new_debris_particles)


func explode_tile(current_cell):
	
	damage_surrounding_cells(current_cell)
	var cell_global_position = map_to_world(current_cell)

	var new_exploding_cell = ExplodingEdge.instance()
	new_exploding_cell.global_position = cell_global_position
	Global.node_creation_parent.add_child(new_exploding_cell)


func damage_surrounding_cells(current_cell):
	
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
