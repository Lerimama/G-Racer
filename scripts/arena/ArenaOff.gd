extends TileMap




#func replace_tile(krneki):
#	print("kon")
#
#
#func on_hit (collision_object):
#
#	if collision_object.is_in_group("Shockers") != true:
#		var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
#		# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu, kar pomeni, da lahko ponesreči izbriše prazen tile
#		# zato s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 
#
#		# kateri tilemap je bil zadet (lokalna pozicija > v tilemap koordinate)
#		var cell_position: Vector2 = world_to_map(collision_position)
#
#		# kateri tajl je bil zadet (index)
#		var cell_index: int = get_cellv(cell_position) # vektor2 koordinate
#
#		if cell_index != -1: # če ni prazen
#
#			set_cellv(cell_position, 1) # sprazneš ... nadomestiš s prazno
#			print(cell_index)

#func replace_tile (cell_position):
#	print("broken index")
#
##	var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
#	# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu, kar pomeni, da lahko ponesreči izbriše prazen tile
#	# zato s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 
#
#	# kateri tilemap je bil zadet (lokalna pozicija > v tilemap koordinate)
##	var cell_position: Vector2 = world_to_map(collision_position)
#
#	# kateri tajl je bil zadet (index)
#	var cell_index: int = get_cellv(cell_position) # vektor2 koordinate
#
##	if cell_index == -1: # če ni prazen
#
#	set_cellv(cell_position, 0) # sprazneš ... nadomestiš s prazno
#	print("broken index")
#	print(cell_index)
