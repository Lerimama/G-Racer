extends TileMap


signal tilemap_completed

var floor_global_positions: Array # tla so prazne + stray + no-stray + player
var random_spawn_floor_positions: Array # ostanejo prazne in so prostor za random spawn
var stray_global_positions: Array
var no_stray_global_positions: Array
var player_global_positions: Array 


func _ready() -> void:
	
	Global.current_tilemap = self
	get_tiles()


func get_tiles():
	
	# prečesi vse celice in določi globalne pozicije
	for x in get_used_rect().size.x: # širina v celicah
		for y in get_used_rect().size.y: # višina širina v celicah	 
			
			# pretvorba v globalno pozicijo
			var cell: Vector2 = Vector2(x, y) # grid pozicija celice
			var cell_local_position: Vector2 = map_to_world(cell)
			var cell_global_position: Vector2 = to_global(cell_local_position) # pozicija je levo-zgornji vogal celice
			
			# zaznavanje tiletov
			var cell_index = get_cellv(cell)
			match cell_index:
				0: # floor
					floor_global_positions.append(cell_global_position)
					random_spawn_floor_positions.append(cell_global_position)
				5: # stray spawn positions
					stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0) # menjam za celico tal
					floor_global_positions.append(cell_global_position)
				2: # no stray
					no_stray_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
				4: # player 1 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
				6: # player 2 spawn position
					player_global_positions.append(cell_global_position)
					set_cellv(cell, 0)
					floor_global_positions.append(cell_global_position)
	
	# pošljem v intro
	emit_signal("tilemap_completed", random_spawn_floor_positions, stray_global_positions, no_stray_global_positions, player_global_positions)
	
	
func get_collision_tile_id(collider: Node2D, direction: Vector2): # collider je node ki se zaleteva in ne collision object
	
	# pozicija celice stene
	var collider_position = collider.position
	var colliding_cell_position = collider_position + direction * cell_size.x # dodamo celico v smeri gibanja, da ne izber pozicije pixla
	
	# index tileta
	var colliding_cell_grid_position: Vector2 = world_to_map(colliding_cell_position) # katera celica je bila zadeta glede na global coords
	var tile_index: int = get_cellv(colliding_cell_grid_position) # index zadete celice na poziciji v grid koordinatah
	
	return tile_index
