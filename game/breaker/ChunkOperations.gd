extends Node
# slice je zarezovanje
# split je dajanje narazen

enum GRID_STYLE {SQUARE, HEX, RANDOM, OCT} # _temp ... se podvaja
var current_grid_style: int = GRID_STYLE.HEX
	
	
func triangulate_daisy(polygon_points: PoolVector2Array, slice_origin_index: int = -1):
	
	var slice_origin: Vector2 = polygon_points[slice_origin_index]	
	if slice_origin_index == -1:
		if not get_parent().slice_origin_global_position == Vector2.ZERO:
			slice_origin = get_parent().slice_origin_global_position - get_parent().global_position
		else:	
			slice_origin = get_polygon_center(polygon_points)
	else:
		slice_origin = polygon_points[slice_origin_index]
		
	# trikotniki so cvetovi marjetice s konico v slice origin točki
	# vsaka točka na robu dobi svoj trikotnik do origina
	var daisy_triangles: Array
	for point_index in polygon_points.size():
		var this_point: Vector2
		var next_point: Vector2
		# zadnja točka se poveže s prvo
		if point_index == polygon_points.size() - 1:
			this_point = polygon_points[point_index]
			next_point = polygon_points[0]
		else:
			this_point = polygon_points[point_index]
			next_point = polygon_points[point_index + 1]
		# array točk trikotnika dodam med vse trikotnike
		var triangle_points: PoolVector2Array = [slice_origin, this_point, next_point] # prva je v centru
		daisy_triangles.append(triangle_points)
	
	return daisy_triangles
	

func triangulate_delaunay(polygon_points: PoolVector2Array, slice_origin_index: int = -1):

	var delaunay_triangles: Array
	
	# OPT slice origin
	var slice_origin: Vector2 = polygon_points[slice_origin_index]	
	if slice_origin_index == -1:
		if not get_parent().slice_origin_global_position == Vector2.ZERO:
			slice_origin = get_parent().slice_origin_global_position - get_parent().global_position
		else:	
			slice_origin = get_polygon_center(polygon_points)
	else:
		slice_origin = polygon_points[slice_origin_index]

	# trianguliram
	randomize()
	var triangulate_points: PoolIntArray = Geometry.triangulate_delaunay_2d(polygon_points) # int array!!
	# število trikotnikov
	var triangle_points_count: int = 3 # trikotnik pač
	var triangle_count: int = triangulate_points.size() / triangle_points_count
	# izdelava trikotnikov
	for triangle_index in triangle_count:
		# opredelim točke trenutnega trikotnika
		var triangle_points = PoolVector2Array() 
		for point in range(triangle_points_count):
			# poiščem index int točke v int array (triangulate)
			var points_used_before_count: int = triangle_index * triangle_points_count
			var points_int_array_index = points_used_before_count + point
			# poiščem točko v int točko in konvertam v Vector2
			var points_array_index: int = triangulate_points[points_int_array_index] # index dobim iz int arraya
			var current_point: Vector2 = polygon_points[points_array_index]
			# točko dodamo v array točk trenutnega trikotnika
			triangle_points.append(current_point)
		
		
		delaunay_triangles.append(triangle_points)	
	
	return delaunay_triangles
	

func slice_horizontal(polygon_points: PoolVector2Array):
	# 3-je koti so najmanj ... po splitanju 6
	# število pik po splitanju je zmeraj 2-kratnik original števila pik
	
	# splitam vse robove na polovico
	polygon_points = split_polygon_edge(polygon_points)
	
	# zbildam nova poligona iz nastalih pik
	var first_polygon: PoolVector2Array = []
	var second_polygon: PoolVector2Array = []
	# trikotnik ... iz origin točke [0]
	if polygon_points.size() == 6:
		# prvi je trikotnik iz točke 0
		first_polygon = [polygon_points[0], polygon_points[2], polygon_points[5]]
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	# pravokotnik ... iz origin točke [0]
	elif polygon_points.size() == 8: 
		# prvi je kvadrat iz točke 0
		first_polygon = [polygon_points[0], polygon_points[1], polygon_points[5], polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	elif polygon_points.size() > 8: # odstranim točke med vogalnimi točkami
		print("Too many or to little points to slice long: ", polygon_points.size())
		var points_divisor: int = polygon_points.size() / 8
		var reduced_polygon_points: PoolVector2Array = []
		for point_index in polygon_points.size():
			if point_index % points_divisor == 0:
				printt(point_index, point_index % points_divisor)
				reduced_polygon_points.append(polygon_points[point_index])
				
		first_polygon = [reduced_polygon_points[0], reduced_polygon_points[1], reduced_polygon_points[5], reduced_polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [reduced_polygon_points[1], reduced_polygon_points[2], reduced_polygon_points[4], reduced_polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	
	return [first_polygon, second_polygon]


func slice_vertical(polygon_points: PoolVector2Array): # ni še ... 
	# 3-je koti so najmanj ... po splitanju 6
	# število pik po splitanju je zmeraj 2-kratnik original števila pik
	
	# splitam vse robove na polovico
	polygon_points = split_polygon_edge(polygon_points)
	
	# zbildam nova poligona iz nastalih pik
	var first_polygon: PoolVector2Array = []
	var second_polygon: PoolVector2Array = []
	# trikotnik ... iz origin točke [0]
	if polygon_points.size() == 6:
		# prvi je trikotnik iz točke 0
		first_polygon = [polygon_points[0], polygon_points[2], polygon_points[5]]
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	# pravokotnik ... iz origin točke [0]
	elif polygon_points.size() == 8: 
		# prvi je kvadrat iz točke 0
		first_polygon = [polygon_points[0], polygon_points[1], polygon_points[5], polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	elif polygon_points.size() > 8: # odstranim točke med vogalnimi točkami
		print("Too many or to little points to slice long: ", polygon_points.size())
		var points_divisor: int = polygon_points.size() / 8
		var reduced_polygon_points: PoolVector2Array = []
		for point_index in polygon_points.size():
			if point_index % points_divisor == 0:
				printt(point_index, point_index % points_divisor)
				reduced_polygon_points.append(polygon_points[point_index])
				
		first_polygon = [reduced_polygon_points[0], reduced_polygon_points[1], reduced_polygon_points[5], reduced_polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [reduced_polygon_points[1], reduced_polygon_points[2], reduced_polygon_points[4], reduced_polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	
	return [first_polygon, second_polygon]
	
	
func slice_grid(polygon_points: PoolVector2Array):
	
	var built_grid_polygons: Array = build_grid_polygons()
	
	# ločim vse točke na notranje in zunanje 
	# ločim vse grid šejpe na čisto zunaj, za klipat, in čisto notri
	var inside_polygons: Array
	var between_polygons: Array
	
	for poly in built_grid_polygons:
		var points_count: int = poly.size()
		var inside_points: Array
		var outside_points: Array
		for point in poly:
			if Geometry.is_point_in_polygon(point, polygon_points):
				inside_points.append(point)
		if inside_points.size() == 0:
			continue
		elif inside_points.size() < points_count:
			between_polygons.append(poly)
		elif inside_points.size() == points_count:
			inside_polygons.append(poly)
			
	
	var intersected_grid_polygons: Array
	for poly in between_polygons:
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(poly, polygon_points)
		if interecting_polygons.empty():
			print("intersection empty")
		else:
			intersected_grid_polygons.append_array(interecting_polygons)	

	# printt ("grid polys", inside_polygons.size(), intersected_grid_polygons.size())
	return [inside_polygons, intersected_grid_polygons]


# UTILITI ------------------------------------------------------------------------------------------


func build_grid_polygons(shape_corner_count: int = 4):

	var grid_polygons: Array
	var grid_split_count: int = 30
	var shape_segment_length: int = 50
			
	var column_index: int = 0 # x os
	var row_index: float = -1 # y os ... -1, da začne pri vrhu ... ne vem zakaj 
	var column_offset: float
	var row_offset: float
	
	# za vsako kolumno, narediš eno vrstico
	for column in grid_split_count: # hor os
		column_index += 1
		row_index = -1 # reset
		for row in grid_split_count: # ver os
			row_index += 1
			
			# lokacija nove pike
			match current_grid_style:
				GRID_STYLE.SQUARE:
					shape_corner_count = 4
					column_offset = shape_segment_length * column_index
					row_offset = shape_segment_length * row_index
				GRID_STYLE.HEX:
					shape_corner_count = 6
					var rotated_side: Vector2 = Vector2(shape_segment_length, 0).rotated(deg2rad(30))
					var long_length: int = round(rotated_side.x)
					var short_length: int = round(rotated_side.y)
					column_offset = (short_length + shape_segment_length) * column_index
					row_offset = long_length * 2 * row_index
					if not column % 2 == 0: 
						row_offset += long_length
				GRID_STYLE.OCT:
					shape_corner_count = 8
					var rotated_side: Vector2 = Vector2(shape_segment_length, 0).rotated(deg2rad(45))
					var side_length_on_grid: int = round(rotated_side.y)
					var first_column_position_adapt: float = shape_segment_length + side_length_on_grid
					var shape_width: float = shape_segment_length + side_length_on_grid * 2
					column_offset = first_column_position_adapt + shape_width * (column_index - 1)
					row_offset = shape_width * row_index
			
			# izdelava polygona
			var shape_polygon: PoolVector2Array
			var shape_origin_position: Vector2 = Vector2(column_offset, row_offset)
			var shape_inside_angle: float = deg2rad(360 / shape_corner_count)
			var shape_segment_vector: Vector2 = Vector2.RIGHT * shape_segment_length
			for count in shape_corner_count:
				var new_point: Vector2
				if count == 0:
					new_point = shape_origin_position # prva točka je na točki trenutnega šejpa
				else: # prve točke ne spreminjam
					var prev_point: Vector2 = shape_polygon[count - 1]
					new_point = prev_point + shape_segment_vector.rotated(shape_inside_angle * count)
					# pixel-perfect
					new_point.x = round(new_point.x)
					new_point.y = round(new_point.y)
				shape_polygon.append(new_point)	
			
			grid_polygons.append(shape_polygon)
	
	return grid_polygons	


func split_polygon_edge(poly_edge_points: PoolVector2Array, split_distance: float = 0.5):
	
	var split_points_to_add: Array
	
	# generiram split points
	for point_index in poly_edge_points.size():
		var this_point: Vector2
		var next_point: Vector2
		# zadnja točka se poveže s prvo
		if point_index == poly_edge_points.size() - 1:
			this_point = poly_edge_points[point_index]
			next_point = poly_edge_points[0]
		else:
			this_point = poly_edge_points[point_index]
			next_point = poly_edge_points[point_index + 1]
		var point_vector: Vector2 = next_point - this_point
		var split_point: Vector2 = this_point + point_vector * split_distance
		split_points_to_add.append(split_point)
	
	# dodam split points v poligon ... ločeno, da imam bolj pod kontrolo zaporedje
	var point_index_grow: int = 1 # adaptiram na spreminjajoč index obstoječih točk v poligonu
	for point_index in split_points_to_add.size():
		poly_edge_points.insert(point_index + point_index_grow, split_points_to_add[point_index])
		point_index_grow += 1
	
	return poly_edge_points


func get_polygon_center(poly_points: PoolVector2Array):
	
	# poiščem 4 skrajne točke oblike
	var max_left_point: Vector2
	var max_right_point: Vector2
	var max_up_point: Vector2
	var max_down_point: Vector2
	for point in poly_points:
		if point.x > max_right_point.x or max_right_point.x == 0:
			max_right_point = point
		elif point.x < max_left_point.x or max_left_point.x == 0:
			max_left_point = point
		if point.y > max_down_point.y or max_down_point.y == 0:
			max_down_point = point
		elif point.y < max_up_point.y or max_up_point.y == 0:
			max_up_point = point
			
	var center_position: Vector2 = Vector2.ZERO
	for point in [max_left_point, max_up_point, max_right_point, max_down_point]:
		center_position += point
	center_position /= 4
	
	return center_position
