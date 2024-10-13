extends StaticBody2D


func _ready() -> void:
	pass


#func explode_tile(current_cell):
#
##	var surrounding_cells: Array = []
##	var target_cell: Vector2
#
#	# zadeta celica dobi celico, ki explodira	
##	var cell_global_position = map_to_world(current_cell)
#	var new_exploding_cell = ExplodingEdge.instance()
#	new_exploding_cell.global_position = cell_global_position
#	new_exploding_cell.z_index = z_index + Set.explosion_z_index
#	Ref.node_creation_parent.add_child(new_exploding_cell)
#
#	# poiščem sosede in jim dodam poškodovani autotile
#	for y in 3:
#		for x in 3:
#			target_cell = current_cell + Vector2(x - 1, y - 1)
#			if current_cell != target_cell:
#				surrounding_cells.append(target_cell)
#	for cell in surrounding_cells:
#		var cell_region_position = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
#		set_cellv(cell, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
