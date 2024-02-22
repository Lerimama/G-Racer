extends Camera2D


func set_camera(tilemap_edge: Rect2, tilemap_cell_size_x: int, viewport_size: Vector2):	
	
	var corner_TL: float = tilemap_edge.position.x * tilemap_cell_size_x + tilemap_cell_size_x # k mejam prištejem edge debelino
	var corner_TR: float = tilemap_edge.end.x * tilemap_cell_size_x - tilemap_cell_size_x
	var corner_BL: float = tilemap_edge.position.y * tilemap_cell_size_x + tilemap_cell_size_x
	var corner_BR: float = tilemap_edge.end.y * tilemap_cell_size_x - tilemap_cell_size_x
	
	# limits
	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR
	
	# zoom
#	zoom.x = (limit_right - tilemap_cell_size_x) / viewport_size.x
#	zoom.y = zoom.x # (limit_bottom - tilemap_cell_size.x) / viewport_size.y

#	zoom.x = 6
#	zoom.y = 6
