extends TileMap


signal spawn_chunk (chunk_position, sprite_cut)

# št. čankov v x in y
var chunk_count: int = 4
var offset_value: float = 16.0

func on_hit (collision_object):
	
	if collision_object.is_in_group("Shockers") != true:
		var collision_position = collision_object.collision.position + collision_object.velocity.normalized()
		# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu, kar pomeni, da lahko ponesreči izbriše prazen tile
		# zato s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 
		
		# kateri tilemap je bil zadet v tilemap koordinatah, namesto world koordintaha
		var cell_position: Vector2 = world_to_map(collision_position)
		# Returns the tilemap (grid-based) coordinates corresponding to the given local position.
		# To use this with a global position, first determine the local position with Node2D.to_local():
		# var local_position = my_tilemap.to_local(global_position)
		# var map_position = my_tilemap.world_to_map(local_position)

		# kateri tajl je bil zadet (index)
		var cell_index: int = get_cellv(cell_position) # vektor2 koordinate
		# če imaš index 0, kar je ponavadi prvi tajl je povezan s slovarjem v variabli (za čunkanje) ... https://youtu.be/dNb0L2hu3m0?t=1194


		if cell_index != -1: # če ni prazen
			var offset: Vector2

			set_cellv(cell_position, 1) # sprazneš ... nadomestiš s prazno
			print(cell_index)
