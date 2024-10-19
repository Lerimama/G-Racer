extends Node
# slice funkcije hendlajo uporabo preostalih in s tem hendlajo stil razreza

	
func slice_grid(polygon_points: PoolVector2Array, shape_corner_count: int, triangulate: bool = false):
	
	# zbildam grid
	var built_grid_polygons: Array = build_grid_polygons(shape_corner_count)
	
	# trianguliram šejpe
	if triangulate:
		var triangulated_polygons: Array
		for poly in built_grid_polygons:
			triangulated_polygons.append_array(triangulate_daisy(poly)[0])
		built_grid_polygons = triangulated_polygons
		
	# ločim šejpe na notranje, zunanje in vmes (za klipat)
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
	
	return [inside_polygons, intersected_grid_polygons]


func slice_spiderweb(polygon_points: PoolVector2Array, origin_point_index: int = -1, triangulate: bool = false):
	
	# vzamem najdaljšega od outline robov, ki prestavlja kratek rob
	var polygon_edge_vectors: Array
	for edge_index in polygon_points.size():
		var start_edge_point: Vector2
		var end_edge_point: Vector2
		if edge_index == polygon_points.size() - 1:
			start_edge_point = polygon_points[edge_index]
			end_edge_point = polygon_points[0]
		else:
			start_edge_point = polygon_points[edge_index]
			end_edge_point = polygon_points[edge_index + 1]
		var edge_vector: Vector2 = end_edge_point - start_edge_point
		polygon_edge_vectors.append(edge_vector)
	polygon_edge_vectors.sort_custom(self, "sort_vectors_by_length")
	var shortest_edge_length: float = polygon_edge_vectors.pop_back().length()
	# potem ga primerjam z najdaljšim robom cvetov 
	var triangulated_daisy: Array = triangulate_daisy(polygon_points)
	var daisy_polygons: Array = triangulated_daisy[0]
	var longest_edge_length: float = triangulated_daisy[1]	
	
	# dobim število korakov rezanja ... tukaj je malo ročno vse skupaj
	var true_split_count: float = (longest_edge_length / shortest_edge_length) - 2
	true_split_count = int(true_split_count * 0.5) # 0.5, ker edge vedno splitam na polovico
	
	# režem
	var spiderweb_polygons: Array = daisy_polygons
	var polygons_to_erase: Array
	for count in true_split_count:
		for poly_index in spiderweb_polygons.size(): # more bit na index, da dela
			var poly = spiderweb_polygons[poly_index]
			spiderweb_polygons.append_array(slice_sides(poly))
			polygons_to_erase.append(poly)
	
		for poly in polygons_to_erase:
			spiderweb_polygons.erase(poly)

	# trianguliram šejpe
	if triangulate:
		var triangulated_polygons: Array
		for poly in spiderweb_polygons:
			triangulated_polygons.append_array(triangulate_daisy(poly)[0])
		spiderweb_polygons = triangulated_polygons
	
	return spiderweb_polygons

	
# SHAPING -----------------------------------------------------------------------------------------

	
func triangulate_daisy(polygon_points: PoolVector2Array, origin_point_index: int = -1):
	# nasacka cvetove iz origina
	# odstrani cvetove, ki segajo preko robov chunka
	# origin_point_index: -1 > center origin, 0 ali več > edge point origin
	# daisy je boljši z originom	
	
	# add origin
	var origin_point: Vector2
	if origin_point_index == -1: # centralna ... izračuna center
		origin_point = get_polygon_center(polygon_points)
	else: # z roba ... uporabi točko na poligonu
		origin_point = polygon_points[origin_point_index]
	
	# vsaka točka na robu dobi svoj trikotnik do origina
	var longest_daisy_edge_length: float # rabim za razmerje spiderweb splitanja	
	var all_daisy_triangles: Array
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
		var triangle_points: PoolVector2Array = [origin_point, this_point, next_point] # prva je v centru
		all_daisy_triangles.append(triangle_points)
		
		# zabeležim najdaljši rob ... na koncu ostane res najdaljši
		var this_edge: Vector2 = origin_point - this_point
		if this_edge.length() > longest_daisy_edge_length:
			longest_daisy_edge_length = this_edge.length()
			
	# odstranim poligone, ki segajo prek robov glavne oblike
	# ni dobro v vseh primerih ... bolje, da jih je preveč kot premalo
	#	var inside_daisy_triangles: Array = []
	#	for poly in all_daisy_triangles: 
	#		# vsak poligon, ki je v popolnosti znotraj glavne oblike je legit
	#		# če drugi poligon prekriva prvega, je array prazen
	#		if Geometry.clip_polygons_2d(poly, owner.polygon).empty():
	#			inside_daisy_triangles.append(poly)
	#	return inside_daisy_triangles # all_daisy_triangles

	# printt ("daisy", inside_daisy_triangles.size(), daisy_triangles.size())
	return [all_daisy_triangles, longest_daisy_edge_length] 
	
	
func triangulate_delaunay(polygon_points: PoolVector2Array, origin_point_index: int = -1, add_points_count: int = 0, merge_to_rectangles: bool = false):
	# nasacka vse mogoče neprekrivajoče se trikotnik
	# indexi točk ne vplivajo na rezultat
	# origin_point_index: -2 > no origin, -1 > center origin, 0 ali več > edge point origin
	# delaunay je boljši brez origina

	# add origin
	if origin_point_index == -1:
		polygon_points.append(get_polygon_center(polygon_points))
	elif origin_point_index >= 0:
		polygon_points.append(polygon_points[origin_point_index])
	
	# add random points
	if add_points_count > 0:
		polygon_points = add_random_points_on_polygon(polygon_points, add_points_count)
	
	# trianguliram
	randomize()
	var delaunay_triangles: Array
	var triangulate_points: PoolIntArray = Geometry.triangulate_delaunay_2d(polygon_points) # int array!!
	# iz števila točk dobim število trikotnikov, ki jih moram narest
	var triangle_count: int = triangulate_points.size() / 3 # 3 ... trikotnik pač
	# izdelava trikotnikov
	for triangle_index in triangle_count:
		# opredelim točke trenutnega trikotnika
		var triangle_points = PoolVector2Array() 
		for point in range(3):
			# poiščem index int točke v int array (triangulate)
			var points_used_before_count: int = triangle_index * 3
			var points_int_array_index: int = points_used_before_count + point
			# poiščem točko v int točko in konvertam v Vector2
			var points_array_index: int = triangulate_points[points_int_array_index] # index dobim iz int arraya
			var current_point: Vector2 = polygon_points[points_array_index]
			# točko dodamo v array točk trenutnega trikotnika
			triangle_points.append(current_point)
		delaunay_triangles.append(triangle_points)	
	
	# merge
	if merge_to_rectangles:
		delaunay_triangles = merge_neighboring_polygons(delaunay_triangles)
	
	# odstranim poligone, ki segajo prek robov glavne oblike
	# ni dobro v vseh primerih ... bolje, da jih je preveč kot premalo
	#	var inside_daisy_triangles: Array = []
	#	for poly in delaunay_triangles: 
	#		# vsak poligon, ki je v popolnosti znotraj glavne oblike je legit
	#		# če drugi poligon prekriva prvega, je array prazen
	#		if Geometry.clip_polygons_2d(poly, owner.polygon).empty():
	#			inside_daisy_triangles.append(poly)
	#	return inside_daisy_triangles # all_daisy_triangles
	
	return delaunay_triangles

	
func slice_sides(polygon_points: PoolVector2Array, split_part: float = 0.5):
	# 3-je koti so najmanj ... po splitanju 6
	# število pik po splitanju je zmeraj 2-kratnik original števila pik
	
	var polygon_origin_point: Vector2 = polygon_points[0]
	
	# splitam vse robove na polovico
	polygon_points = split_outline_on_part(polygon_points, split_part)
	
	var new_origin_point_index: int = polygon_points.find(polygon_origin_point) # zazih ... v bistvu se ne spremeni
	
	# zbildam nova poligona iz nastalih pik
	var first_polygon: PoolVector2Array = []
	var second_polygon: PoolVector2Array = []
	# trikotnik ... iz origin točke [0]
	if polygon_points.size() == 6:
		# prvi je trikotnik iz točke 0
		first_polygon = [polygon_points[0], polygon_points[1], polygon_points[5]]
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	# pravokotnik ... iz origin točke [0]
	elif polygon_points.size() == 8: 
		# prvi je kvadrat iz točke 0
		first_polygon = [polygon_points[0], polygon_points[1], polygon_points[5], polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [polygon_points[1], polygon_points[2], polygon_points[4], polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	elif polygon_points.size() > 8: # odstranim točke med vogalnimi točkami
		print("Too many or to little points to slice long: ", polygon_points.size())
		var points_divisor: int = polygon_points.size() / 8
		var reduced_polygon: PoolVector2Array = []
		for point_index in polygon_points.size():
			if point_index % points_divisor == 0:
				reduced_polygon.append(polygon_points[point_index])
		first_polygon = [reduced_polygon[0], reduced_polygon[1], reduced_polygon[5], reduced_polygon[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [reduced_polygon[1], reduced_polygon[2], reduced_polygon[4], reduced_polygon[5]] # pika[3] splita zunanjo stranico in je ne rabim
	
	return [first_polygon, second_polygon]		


func split_outline_on_part(polygon_outline_points: PoolVector2Array, var split_part: float = 0.5, split_count: int = 1):
	
	for count in split_count:
		
		var split_points_to_add: Array
		# za vsak edge dodam split točko na split_part delu
		for edge_index in polygon_outline_points.size():
			var start_edge_point: Vector2
			var end_edge_point: Vector2
			if edge_index == polygon_outline_points.size() - 1:
				start_edge_point = polygon_outline_points[edge_index]
				end_edge_point = polygon_outline_points[0]
			else:
				start_edge_point = polygon_outline_points[edge_index]
				end_edge_point = polygon_outline_points[edge_index + 1]
			var edge_vector: Vector2 = end_edge_point - start_edge_point
			var split_point: Vector2 = start_edge_point + edge_vector * split_part
			split_points_to_add.append(split_point)
		
		# dodam split points v poligon ... ločeno, da imam bolj pod kontrolo zaporedje
		var point_index_grow: int = 1 # adaptiram na spreminjajoč index obstoječih točk v poligonu
		for point_index in split_points_to_add.size():
			polygon_outline_points.insert(point_index + point_index_grow, split_points_to_add[point_index])
			point_index_grow += 1			
	
	return polygon_outline_points
	

func split_outline_to_length(polygon_outline_points: PoolVector2Array, max_edge_length: float):
	
	#	max_edge_length = 30 # _temp
	var split_outline_checked: Array = split_to_length_loop(polygon_outline_points, max_edge_length) # 0 = edge pike, 1 = trua
	
	var is_outline_correct: bool = split_outline_checked[1]
	while not is_outline_correct:
		split_outline_checked = split_to_length_loop(split_outline_checked[0], max_edge_length)
		is_outline_correct = split_outline_checked[1]
	
	var new_outline_points: Array = split_outline_checked[0]
	
	return new_outline_points


# UTILITI ------------------------------------------------------------------------------------------

	
func merge_neighboring_polygons(polygons_to_merge: Array):
	
	var merged_polygons: Array
	
	while not polygons_to_merge.empty():
		var main_polygon: PoolVector2Array = polygons_to_merge.pop_back()
		var merging_polygons: Array = merge_polygon_with_neighbor(main_polygon, polygons_to_merge)
		merged_polygons.append(merging_polygons[0])
		polygons_to_merge = merging_polygons[1]
		# če je bil merge uspešen je merging polygon mergan, possible nejbrs pa so za enomanjši
		# če merge ni bil uspešen je merging polygon enak in possible nejbrs tudi
		# printt ("delaunay", merged_polygons.size(), polygons_to_merge.size())
	
	return merged_polygons

	
func merge_polygon_with_neighbor(merging_polygon: PoolVector2Array, possible_neighbors: Array):
	
	# med sabo se mergajo samo trikotniki (izognem se že merganim)
	if not merging_polygon.size() == 3:
		return
	
	# najdem prvega soseda z dvema pikama in ga mergam
	# če soseda ni, pošljem nazaj iste oblike in ste možne sosede
	var neighbor_polygon: PoolVector2Array
	var shared_points_limit: int = 2
	for poly in possible_neighbors:
		var shared_points_count: int = 0 				
		for point in poly:
			if Geometry.is_point_in_polygon(point, merging_polygon):
				shared_points_count += 1
		if shared_points_count >= shared_points_limit:
			neighbor_polygon = poly
			var merged_polygons = Geometry.merge_polygons_2d(merging_polygon, neighbor_polygon)
			merging_polygon = merged_polygons[0]
			possible_neighbors.erase(neighbor_polygon)
			break # če brejk ni se 
	
	# če je bil merge uspešen je merging polygon mergan, possible nejbrs pa so za enomanjši
	# če merge ni bil uspešen je merging polygon enak in possible nejbrs tudi
	return [merging_polygon, possible_neighbors]
		
	
func split_to_length_loop(polygon_outline_points: PoolVector2Array, max_edge_length: float):
	
	var new_outline_points: Array = polygon_outline_points
	var split_part: float = 0.5
	
	# za vsak edge preverim dolžino in ga splitam dokler ni krajši od določene
	for edge_index in polygon_outline_points.size():
		var start_point: Vector2
		var end_point: Vector2
		if edge_index == polygon_outline_points.size() - 1:
			start_point = polygon_outline_points[edge_index]
			end_point = polygon_outline_points[0]
		else:
			start_point = polygon_outline_points[edge_index]
			end_point = polygon_outline_points[edge_index + 1]
		# splitam, če je večji od
		var edge_vector: Vector2 = end_point - start_point
		if edge_vector.length() > max_edge_length:
			var split_point: Vector2 = start_point + edge_vector * split_part
			var start_point_in_new_outline_points_index: int = new_outline_points.find(start_point)
			new_outline_points.insert(start_point_in_new_outline_points_index + 1, split_point)
			
	# preverim, če je še kakšen rob predolg ... resplitam
	var all_edges_correct: bool = true
	
	for edge_index in new_outline_points.size():
		var start_point: Vector2
		var end_point: Vector2
		if edge_index == new_outline_points.size() - 1:
			start_point = new_outline_points[edge_index]
			end_point = new_outline_points[0]
		else:
			start_point = new_outline_points[edge_index]
			end_point = new_outline_points[edge_index + 1]
		var edge_vector: Vector2 = end_point - start_point
		if edge_vector.length() > max_edge_length:
			all_edges_correct = false
			break
			
	# printt ("longs", too_long.size())
	return [new_outline_points, all_edges_correct]
	
	
func build_grid_polygons(shape_corner_count: int):

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
			match shape_corner_count:
				4:
					column_offset = shape_segment_length * column_index
					row_offset = shape_segment_length * row_index
				6:
					shape_corner_count = 6
					var rotated_side: Vector2 = Vector2(shape_segment_length, 0).rotated(deg2rad(30))
					var long_length: int = round(rotated_side.x)
					var short_length: int = round(rotated_side.y)
					column_offset = (short_length + shape_segment_length) * column_index
					row_offset = long_length * 2 * row_index
					if not column % 2 == 0: 
						row_offset += long_length
				3,5,7,8,_:
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


func add_random_points_on_polygon(polygon_points: PoolVector2Array, add_points_count: int):
	print (add_points_count)
#	add_points_count = 100
	
	# poiščem 4 skrajne točke oblike
	var max_left_point: Vector2
	var max_right_point: Vector2
	var max_up_point: Vector2
	var max_down_point: Vector2
	for point in polygon_points:
		if point.x > max_right_point.x or max_right_point.x == 0:
			max_right_point = point
		elif point.x < max_left_point.x or max_left_point.x == 0:
			max_left_point = point
		if point.y > max_down_point.y or max_down_point.y == 0:
			max_down_point = point
		elif point.y < max_up_point.y or max_up_point.y == 0:
			max_up_point = point
	
	var polygon_with_added_points: PoolVector2Array
	for point in range(add_points_count):
		var random_x: float = rand_range(max_left_point.x, max_right_point.x)
		var random_y: float = rand_range(max_up_point.y, max_down_point.y)
		var random_point: Vector2 = Vector2(random_x, random_y)
		polygon_with_added_points.append(random_point)

	# zavržem tiste zunaj glavnega poligona 
	# ponovljam postopek dokler so vse znotraj
	
	var points_outside_base_polygon: PoolVector2Array
	for point in polygon_with_added_points:
		if not Geometry.is_point_in_polygon(point, polygon_points):
			points_outside_base_polygon.append(point)
	
	for point in points_outside_base_polygon:
		var point_add_points_polygon_index: int = polygon_with_added_points.find(point)
		polygon_with_added_points.remove(point_add_points_polygon_index)
	
	# trenutno je tako, točke samo odstranim, 
	# ena random pika se lahko skos spavna zunaj ... zato je to kar ok
	
	return polygon_with_added_points
	

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


func sort_vectors_by_length(vector_1, vector_2): 
	# ascending ... večji je boljši

	if vector_1.length() > vector_2.length():
	    return true
	return false	
