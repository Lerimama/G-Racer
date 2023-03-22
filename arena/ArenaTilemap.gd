extends TileMap


var cell_library: Dictionary = {
	# index zero
	"0": {
		"texture_start_position": Vector2(0, 0)
		# tukaj določi še kateri del tilemapa "odrežeš" oz na upoštevaš
		# https://youtu.be/dNb0L2hu3m0?t=1032
	}
}

signal spawn_chunk (chunk_position, sprite_cut)

# št. čankov v x in y
var chunk_count: int = 4
var offset_value: float = 16.0

func on_hit (collision_position):
	
	# kateri tilemap je bil zadet v tilemap koordinatah, namesto world koordintaha
	var cell_position: Vector2 = world_to_map(collision_position)
	# Returns the tilemap (grid-based) coordinates corresponding to the given local position.
	# To use this with a global position, first determine the local position with Node2D.to_local():
	# var local_position = my_tilemap.to_local(global_position)
	# var map_position = my_tilemap.world_to_map(local_position)
	
	# kateri tajl je bil zadet (index)
	var cell_index: int = get_cellv(cell_position) # vektor2 koordinate
	# če imaš index 0, kar je ponavadi prvi tajl je povezan s slovarjem v variabli (za čunkanje)
	# https://youtu.be/dNb0L2hu3m0?t=1194
	
	if cell_index != -1:
		var offset: Vector2
#		var chunk_sprite_cut_start = cell_library[str(cell_index)]["texture_start_position"]
		
#		for x in range (0,4):
#			for y in range (0,4):
#				var spawn_position = map_to_world(cell_position) + offset
#				var sprite_cut = chunk_sprite_cut_start + offset
#
#				emit_signal("spawn_chunk", spawn_position + Vector2(8, 8), sprite_cut)
#				# dodamo 8 pixlov v obe smeri, ker če ne bi se tileti zamaknili ... godot način
#				# https://youtu.be/dNb0L2hu3m0?t=1385
#
#				offset.y += offset_value
#			offset.y = 0
#			offset.x += offset_value
			
		set_cellv(cell_position, 1) # sprazneš ... nadomestiš s prazno
		print(cell_index)
#	set_cellv(cell_position, -1) # sprazneš ... nadomestiš s prazno
