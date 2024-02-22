extends GameManager


func _ready() -> void:

	Global.game_manager = self
	
	StrayPixel = preload("res://game/pixel/stray_cleaning.tscn")
	PlayerPixel = preload("res://game/pixel/player_cleaning.tscn")
	
	randomize()
	
#
#func _on_tilemap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array) -> void:
#	# namen: ciljni stray
#
#	# opredelim tipe pozicij
#	random_spawn_positions = random_spawn_floor_positions
#	required_spawn_positions = stray_cells_positions
#	player_start_positions = player_cells_positions
#
#	# start strays count setup
#	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
#		game_data["strays_start_count"] = required_spawn_positions.size()
#
#	# preventam preveč straysov (več kot je možnih pozicij)
#	if game_data["strays_start_count"] > random_spawn_positions.size() + required_spawn_positions.size():
#		game_data["strays_start_count"] = random_spawn_positions.size()/2 + required_spawn_positions.size()
#
#	# če ni pozicij, je en player ... random pozicija
#	if player_start_positions.empty():
#		var random_range = random_spawn_positions.size() 
#		print(random_range)
#		var p1_selected_cell_index: int = randi() % int(random_range) + 1
#		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
#		random_spawn_positions.remove(p1_selected_cell_index)
#
#	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
