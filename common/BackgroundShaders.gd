extends Node2D

onready var tilemap_floor: TileMap
onready var tilemap_elements: TileMap
onready var tilemap_edge: TileMap

func _ready() -> void:
	pass # Replace with function body.


# kopirano iz višjega nodeta
func set_level_shaders():
	# shader node resizam ne velikost floor tilemapa
	# setam šejder parametre
	
	# velikost floor tilemapa
	var first_floor_cell = tilemap_floor.get_used_cells().pop_front()
	var last_floor_cell = tilemap_floor.get_used_cells().pop_back()
	var floor_rect_position = tilemap_floor.map_to_world(first_floor_cell)
	var floor_rect_size = tilemap_floor.map_to_world(last_floor_cell) - tilemap_floor.map_to_world(first_floor_cell)
	
	var nodes_to_resize: Array = []
	# background
	for node in get_children():
		if node.material:
			nodes_to_resize.append(node)
	# floor
	for node in tilemap_floor.get_children():
		nodes_to_resize.append(node)
	# edge
	for node in tilemap_edge.get_children():
		nodes_to_resize.append(node)
	# resize and set shader
	for node in nodes_to_resize:
		node.rect_position = floor_rect_position
		node.rect_size = floor_rect_size
		node.material.set_shader_param("node_size", floor_rect_size)

	# noise screen
	var curr_tilemaps: Array = [tilemap_edge, tilemap_floor]
	
	var tile_with_shader_id: int
	
	for tm in curr_tilemaps:
		match tm:
			tilemap_floor:
		#		var tm: TileMap = tilemap_floor
				tile_with_shader_id = 5
			#	var tm: TileMap = tilemap_elements
			#	var tile_with_shader_id: int = 36
			tilemap_edge:
				tile_with_shader_id = 0
				pass
				
		var ts: TileSet = tm.tile_set
		var sm: String = ts.tile_get_name(tile_with_shader_id)
		var mat: ShaderMaterial = ts.tile_get_material(tile_with_shader_id)
		var local_to_view: Transform2D = tm.get_viewport_transform() * tm.global_transform
		var view_to_local: Transform2D = local_to_view.affine_inverse()
		#		printt ("shader_par", ts, tm, sm, local_to_view, view_to_local)
		mat.set_shader_param("view_to_local", view_to_local)	

func update_tile_shaders():
	
	
	var tile_with_shader_id: int # za kateri tajl setamo transforme
	
	for tilemap in [tilemap_edge, tilemap_floor]:
		match tilemap:
			tilemap_floor:
				tile_with_shader_id = 5
			tilemap_edge:
				tile_with_shader_id = 0

		var tilemap_material: ShaderMaterial = tilemap.tile_set.tile_get_material(tile_with_shader_id)
		var local_to_view: Transform2D = tilemap.get_viewport_transform() * tilemap.global_transform
		var view_to_local: Transform2D = local_to_view.affine_inverse()
		tilemap_material.set_shader_param("view_to_local", view_to_local)
	
