extends Node
class_name Operator


# SPLIT funkcije hendlajo uporabo preostalih in s tem hendlajo stil razreza --------------------------------------------


func split_grid(polygon_points: PoolVector2Array, shape_corner_count: int, triangulate: bool = false):

	# zbildam grid
	var built_grid_polygons: Array = build_grid_polygons(shape_corner_count)

	# trianguliram šejpe
	if triangulate:
		var triangulated_polygons: Array = []
		for poly in built_grid_polygons:
			triangulated_polygons.append_array(split_daisy(poly)[0])
		built_grid_polygons = triangulated_polygons

	# ločim šejpe na notranje, zunanje in vmes (za klipat)
	var inside_polygons: Array = []
	var between_polygons: Array = []
	for poly in built_grid_polygons:
		var points_count: int = poly.size()
		var inside_points: Array = []
		var outside_points: Array = []
		for point in poly:
			if Geometry.is_point_in_polygon(point, polygon_points):
				inside_points.append(point)
		if inside_points.size() == 0:
			continue
		elif inside_points.size() < points_count:
			between_polygons.append(poly)
		elif inside_points.size() == points_count:
			inside_polygons.append(poly)


	var intersected_grid_polygons: Array = []
	for poly in between_polygons:
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(poly, polygon_points)
		if interecting_polygons.empty():
			print("intersection empty")
		else:
			intersected_grid_polygons.append_array(interecting_polygons)

	return [inside_polygons, intersected_grid_polygons]


func split_spiderweb(polygon_points: PoolVector2Array, origin_point_index: int = -1, triangulate: bool = false):

	# vzamem najdaljšega od outline robov, ki prestavlja kratek rob
	var polygon_edges: Array = get_outline_segments_by_length(polygon_points)
#	var shortest_edge: Vector2 = polygon_edges[polygon_edges.size() - 1]
	var shortest_edge: Vector2 = polygon_edges[- 1]
	var shortest_edge_length: float = shortest_edge.length()

	# potem ga primerjam z najdaljšim robom cvetov
	var triangulated_daisy: Array = split_daisy(polygon_points)
	var daisy_polygons: Array = triangulated_daisy[0]
	var longest_edge_length: float = triangulated_daisy[1]

	# dobim število korakov rezanja ... tukaj je malo ročno vse skupaj
	var true_split_count: float = (longest_edge_length / shortest_edge_length) - 2
	true_split_count = int(true_split_count * 0.5) # 0.5, ker edge vedno splitam na polovico

	# režem
	var spiderweb_polygons: Array = daisy_polygons
	var polygons_to_erase: Array = []
	for count in true_split_count:
		for poly_index in spiderweb_polygons.size(): # more bit na index, da dela
			var poly = spiderweb_polygons[poly_index]
			spiderweb_polygons.append_array(split_sides(poly))
			polygons_to_erase.append(poly)

		for poly in polygons_to_erase:
			spiderweb_polygons.erase(poly)

	# trianguliram šejpe
	if triangulate:
		var triangulated_polygons: Array = []
		for poly in spiderweb_polygons:
			triangulated_polygons.append_array(split_daisy(poly)[0])
		spiderweb_polygons = triangulated_polygons

	return spiderweb_polygons


func split_daisy(polygon_points: PoolVector2Array, origin_point_index: int = -1):
	# nasacka cvetove iz origina
	# odstrani cvetove, ki segajo preko robov chunka
	# origin_point_index: -1 > center origin, 0 ali več > edge point origin
	# daisy je boljši z originom

	var original_shape_points: PoolVector2Array = polygon_points
	# add origin
	var origin_point: Vector2
	if origin_point_index == -1: # centralna ... izračuna center
		origin_point = get_polygon_center(polygon_points)
	else: # z roba ... uporabi točko na poligonu
		origin_point = polygon_points[origin_point_index]

	# vsaka točka na robu dobi svoj trikotnik do origina
	var longest_daisy_edge_length: float # rabim za razmerje spiderweb splitanja
	var all_daisy_triangles: Array = []
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

	# odstranim poligone izven oblike chunka
	all_daisy_triangles = reclip_polygons_to_shape(all_daisy_triangles, original_shape_points)

	# printt ("daisy", inside_daisy_triangles.size(), daisy_triangles.size())
	return [all_daisy_triangles, longest_daisy_edge_length]


func split_delaunay(polygon_points: PoolVector2Array, add_points_count: int = 0, merge_to_rectangles: bool = false):
	# nasacka vse mogoče neprekrivajoče se trikotnik
	# indexi točk ne vplivajo na rezultat
	# origin_point_index: -2 > no origin, -1 > center origin, 0 ali več > edge point origin
	# delaunay je boljši brez origina

	var original_shape_points: PoolVector2Array = polygon_points

#	# add origin
#	if origin_point_index == -1:
#		pass
##		polygon_points.append(get_polygon_center(polygon_points))
#	elif origin_point_index >= 0:
#		polygon_points.append(polygon_points[origin_point_index])

	# add random points
	if add_points_count > 0:
		var new_polygon_points = add_random_points_to_polygon(polygon_points, add_points_count)
		polygon_points = new_polygon_points

	# trianguliram
	randomize()
	var delaunay_triangles: Array = []
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

	# odstranim poligone izven oblike chunka (glede na njihov center)
	delaunay_triangles = reclip_polygons_to_shape(delaunay_triangles, original_shape_points)

	# merge
	if merge_to_rectangles:
		delaunay_triangles = merge_neighboring_polygons(delaunay_triangles)

	return delaunay_triangles


func split_sides(polygon_points: PoolVector2Array, split_part: float = 0.5):
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
		print("Too many or to little points to split sides: ", polygon_points.size())
		var points_divisor: int = polygon_points.size() / 8
		var reduced_polygon: PoolVector2Array = []
		for point_index in polygon_points.size():
			if point_index % points_divisor == 0:
				reduced_polygon.append(polygon_points[point_index])
		first_polygon = [reduced_polygon[0], reduced_polygon[1], reduced_polygon[5], reduced_polygon[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [reduced_polygon[1], reduced_polygon[2], reduced_polygon[4], reduced_polygon[5]] # pika[3] splita zunanjo stranico in je ne rabim

	return [first_polygon, second_polygon]


# OPERATIONS ---------------------------------------------------------------------------------------------------


func split_outline_on_part(polygon_outline_points: PoolVector2Array, var split_part: float = 0.5, split_count: int = 1):

	for count in split_count:

		var split_points_to_add: Array = []
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

	var split_outline_checked: Array = split_outline_on_length(polygon_outline_points, max_edge_length) # 0 = edge pike, 1 = trua

	var is_outline_correct: bool = split_outline_checked[1]
	while not is_outline_correct:
		split_outline_checked = split_outline_on_length(split_outline_checked[0], max_edge_length)
		is_outline_correct = split_outline_checked[1]

	var new_outline_points: Array = split_outline_checked[0]

	return new_outline_points


func simplify_outline(polygon_points: PoolVector2Array, set_round_count: int = -1, points_left_count: int = 5):

	# število rund
	var round_count: int
	if set_round_count == -1:
		var remove_points_count_limit: int = polygon_points.size() - points_left_count
		var remove_points_per_round: float = floor(polygon_points.size() / 2)
		round_count = ceil(remove_points_count_limit / remove_points_per_round)
	else:
		round_count = set_round_count

	var current_simple_polygon: PoolVector2Array = polygon_points # po vsaki rundi ga napolenm in potem ponovno pregledujem
	for rnd in round_count:
#		print ("-----")
#		printt ("runda", round_count)
		var simple_poly: PoolVector2Array = []
		for point_index in current_simple_polygon.size():
			if point_index % 2 == 0:
				simple_poly.append(current_simple_polygon[point_index])
				# če je zadnja runda in je število novih pik enako željenemu
				if rnd == round_count - 1 and set_round_count == -1:
					if simple_poly.size() == points_left_count:
						break
		current_simple_polygon = simple_poly

	return current_simple_polygon


func desplit_polygon_segment(polygon_outline_points: PoolVector2Array, segment_start_index: int):
	# odstranim splitane pike na (origin) robu

	var desplit_polygon: PoolVector2Array = polygon_outline_points

	var segment_end_index: int
	if segment_start_index == desplit_polygon.size() - 1:
		segment_end_index = 0
	else:
		segment_end_index = segment_start_index + 1

	for point_index in desplit_polygon.size():
		if point_index > segment_start_index and point_index < segment_end_index:
				desplit_polygon.remove(point_index)

	return desplit_polygon


func split_outline_on_length(polygon_outline_points: PoolVector2Array, max_edge_length: float):

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


func reclip_polygons_to_shape(polygons_to_refactor: Array, refactor_to_polygon: PoolVector2Array):

	var refactored_polygons: Array = []

	var inside_triangles: Array = []
	var outside_triangles: Array = []
	for poly in polygons_to_refactor:
		var poly_center: Vector2 = get_polygon_center(poly)
		if Geometry.is_point_in_polygon(poly_center, refactor_to_polygon):
			inside_triangles.append(poly)
		else:
			outside_triangles.append(poly)

	refactored_polygons = inside_triangles

	var intersected_outside_triangles: Array = []
	for poly in outside_triangles:
		var intesected_polygons: Array = Geometry.intersect_polygons_2d(poly, refactor_to_polygon)
		if not intesected_polygons.empty():
			intersected_outside_triangles.append_array(intesected_polygons)

	refactored_polygons.append_array(intersected_outside_triangles)

	return refactored_polygons


func apply_hole(base_polygon, hole_polygon: PoolVector2Array):
	# poiščem rob (s točko), ki je najbližje od enega od robov
	# shape splitam med najbližjo točko na izbranem robu in centrom luknje
	# ponovno slajsam novi shape
	# bolje? ... lahko bi ga naredil podobno kot cut linijo

	# za vsako stranico shape polija preverim od split točk je najbliža in jo zapišem
	var distance_to_closest_point: float = 0
	var split_point_on_hole: Vector2 # za primer, če sredina oblike ni v poligonu
	var split_edge_start_index: int = 0
	var split_edge_vector: Vector2
	var closest_point_on_edge: Vector2
	var shape_polygon: PoolVector2Array = base_polygon
	for point_index in shape_polygon.size():
		var start_point: Vector2 = shape_polygon[point_index]
		var end_point: Vector2
		if point_index < shape_polygon.size() - 1:
			end_point = base_polygon[point_index + 1]
		else:
			end_point = base_polygon[0]
		# za vsako točko na luknji preverim katera ja najdle enemu od robov shape
		for point in hole_polygon:
			var closest_point: Vector2 = Geometry.get_closest_point_to_segment_2d(point, start_point, end_point)
			var distance_between_points: float = (point - closest_point).length()
			# najbližja
			if distance_between_points < distance_to_closest_point or distance_to_closest_point == 0:
				closest_point_on_edge = closest_point
				split_edge_start_index = point_index
				split_edge_vector = end_point - start_point
				distance_to_closest_point = distance_between_points
				split_point_on_hole = point

	# split points polygon
	var split_shape_polygon: PoolVector2Array = base_polygon
	# split point
	split_shape_polygon.insert(split_edge_start_index + 1, closest_point_on_edge)
	# hole center
	var hole_center: Vector2 = Vector2.ZERO
	for point in hole_polygon:
		hole_center += point
	hole_center /= hole_polygon.size()
	# če center ni v poligonu, povlečem do referenčne točke najbolj oddaljena točke
	if Geometry.is_point_in_polygon(hole_center, split_shape_polygon):
		split_point_on_hole = hole_center
	split_shape_polygon.insert(split_edge_start_index + 2, split_point_on_hole) # sredinska hole točka lahko ni v luknji
	# offset split point
	var split_offset: Vector2 = (Vector2.RIGHT * 0.01).rotated(split_edge_vector.angle())
	split_shape_polygon.insert(split_edge_start_index + 3, closest_point_on_edge + split_offset) # prvo shape split točko

	# apliciram na shape
	var split_base_polygon: PoolVector2Array = split_shape_polygon

	return [split_shape_polygon, hole_polygon]


func merge_neighboring_polygons(polygons_to_merge: Array):

	var merged_polygons: Array = []

	while not polygons_to_merge.empty():
		var main_polygon: PoolVector2Array = polygons_to_merge.pop_back()
		var merging_polygons: Array = merge_polygon_with_neighbor(main_polygon, polygons_to_merge)
		merged_polygons.append(merging_polygons[0])
		polygons_to_merge = merging_polygons[1]
		# če je bil merge uspešen je merging polygon mergan, possible nejbrs pa so za enomanjši
		# če merge ni bil uspešen je merging polygon enak in possible nejbrs tudi

	return merged_polygons


func merge_polygon_with_neighbor(merging_polygon: PoolVector2Array, possible_neighbors: Array):

	# med sabo se mergajo samo trikotniki (izognem se že merganim)
	if not merging_polygon.size() == 3:
		return

	# najdem prvega soseda z dvema pikama in ga mergam
	# če soseda ni, pošljem nazaj iste oblike in ste možne sosede
	var neighbor_polygon: PoolVector2Array = []
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


func build_grid_polygons(shape_corner_count: int):

	var grid_polygons: Array = []
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
			var shape_polygon: PoolVector2Array = []
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


func add_random_points_to_polygon(polygon_points: PoolVector2Array, add_points_count: int):

#	var polygon_far_points: Array = get_polygon_far_points(polygon_points) # L-T-R-B

	var polygon_bounding_rect: Rect2 = get_polygon_bounding_rect(polygon_points) # L-T-R-B
#	var chunk_position: Vector2 = chunk_far_points_rect.position
#	var chunk_size: Vector2 = chunk_far_points_rect.size


	# najprej dobim množico rendom točk
	var random_added_points: PoolVector2Array = []
	for point in range(add_points_count):
#		var random_x: float = rand_range(polygon_far_points[0].x, polygon_far_points[2].x)
#		var random_y: float = rand_range(polygon_far_points[1].y, polygon_far_points[3].y)
		var random_x: float = rand_range(polygon_bounding_rect.position.x, polygon_bounding_rect.size.x)
		var random_y: float = rand_range(polygon_bounding_rect.position.y, polygon_bounding_rect.size.y)
		var random_point: Vector2 = Vector2(random_x, random_y)
		random_added_points.append(random_point)

	# zavržem zunanje in na robu ... ne ponovljam dokler je kakšna, ker se lahko zacikla
	var inside_added_points: PoolVector2Array = []
	for point in random_added_points:
		# če je v poligonu, preverim še, če je na robu
		if Geometry.is_point_in_polygon(point, polygon_points):
			var intersection_edge_index: int = get_outline_segment_closest_to_point(point, polygon_points, 0)[0]
			if intersection_edge_index == -1: # _temp ... dodaš distanco?
				inside_added_points.append(point)
	# apliciram dodatne točke
	for point in inside_added_points:
		polygon_points.append(point)

	return polygon_points


# GETTERS ------------------------------------------------------------------------------------------------------


func get_outline_segments_by_length(outline_polygon: PoolVector2Array):

	var outline_segments_by_length: Array = []

	for edge_index in outline_polygon.size():
		var start_edge_point: Vector2
		var end_edge_point: Vector2
		if edge_index == outline_polygon.size() - 1:
			start_edge_point = outline_polygon[edge_index]
			end_edge_point = outline_polygon[0]
		else:
			start_edge_point = outline_polygon[edge_index]
			end_edge_point = outline_polygon[edge_index + 1]
		var edge_vector: Vector2 = end_edge_point - start_edge_point
		outline_segments_by_length.append(edge_vector)

	outline_segments_by_length.sort_custom(self, "sort_vectors_by_length")

	return outline_segments_by_length


func get_outline_intersecting_segments(hit_segment: PoolVector2Array, outline_polygon: PoolVector2Array, global: bool = false):

	var all_intersections: Array = [] # array, da lahko preverejam uspešnost

	for edge_index in outline_polygon.size():
		var edge: PoolVector2Array = []
		if edge_index == outline_polygon.size() - 1:
			edge = [outline_polygon[edge_index], outline_polygon[0]]
		else:
			edge = [outline_polygon[edge_index], outline_polygon[edge_index + 1]]

		var new_intersection_point = Geometry.segment_intersects_segment_2d(hit_segment[0],hit_segment[1],edge[0], edge[1])
		if new_intersection_point:
			var new_intersection_data: Array = [new_intersection_point]
			new_intersection_data.append(edge_index)
			all_intersections.append(new_intersection_data)
#			break

	return all_intersections


func get_outline_segment_closest_to_point(point: Vector2, intersected_polygon: PoolVector2Array, distance_from_point_limit: float = -1):
	# poiščem segment, ki je najbližje točki in v omejeni distanci

	var closest_edge_index: int = -1
	var shortest_distance_to_point: float = 0
	var closest_point_on_closest_edge: Vector2 = point

	for edge_index in intersected_polygon.size():
		var start_point: Vector2
		var end_point: Vector2
		if edge_index == intersected_polygon.size() - 1:
			start_point = intersected_polygon[edge_index]
			end_point = intersected_polygon[0]
		else:
			start_point = intersected_polygon[edge_index]
			end_point = intersected_polygon[edge_index + 1]

		var closest_point_on_edge = Geometry.get_closest_point_to_segment_2d(point, start_point, end_point)
		var edge_distance_to_point: float = (point - closest_point_on_edge).length()
		if edge_distance_to_point < shortest_distance_to_point or shortest_distance_to_point == 0:
			if distance_from_point_limit == -1 or edge_distance_to_point < distance_from_point_limit:
				shortest_distance_to_point = edge_distance_to_point
				closest_edge_index = edge_index
				closest_point_on_closest_edge = closest_point_on_edge

	return [closest_edge_index, closest_point_on_closest_edge]


func get_polygon_radius(polygon_points: PoolVector2Array, point_index: int = -1):

	var polygon_center: Vector2 = get_polygon_center(polygon_points)

	if point_index == -1:
		var max_radius: float = 0
		for point in polygon_points:
			var radius_on_point: float = (point - polygon_center).length()
			if radius_on_point > max_radius:
				max_radius = radius_on_point
		return max_radius
	else:
		var radius_on_point: float = (polygon_points[point_index] - polygon_center).length()
		return	radius_on_point


func get_polygon_far_points(polygon_points: PoolVector2Array):

	var points_to_sort: Array = polygon_points

	# x
	points_to_sort.sort_custom(self, "sort_vectors_by_x")
	var far_right_point: Vector2 = points_to_sort[0]
#	var far_left_point: Vector2 = points_to_sort[points_to_sort.size() - 1]
	var far_left_point: Vector2 = points_to_sort[- 1]

	# Y
	points_to_sort.sort_custom(self, "sort_vectors_by_y")
	var far_down_point: Vector2 = points_to_sort[0]
#	var far_up_point: Vector2 = points_to_sort[points_to_sort.size() - 1]
	var far_up_point: Vector2 = points_to_sort[- 1]

	var far_points: Array = [far_left_point, far_up_point, far_right_point, far_down_point]

	return far_points


func get_polygon_bounding_rect(polygon_points: PoolVector2Array):

	var polygon_hull: Array = Geometry.convex_hull_2d(polygon_points)
	var hull_point_x_values: Array = []
	var hull_point_y_values: Array = []
	for point in polygon_hull:
		hull_point_x_values.append(point.x)
		hull_point_y_values.append(point.y)

	var bounding_rect: Rect2
	bounding_rect.position = Vector2(hull_point_x_values.min(), hull_point_x_values.min())
	var bounding_rect_size_x: float = abs(hull_point_x_values.max() - hull_point_x_values.min())
	var bounding_rect_size_y: float = abs(hull_point_y_values.max() - hull_point_y_values.min())
	bounding_rect.size = Vector2(bounding_rect_size_x, bounding_rect_size_y)

	return bounding_rect


func get_polygon_center(polygon_points: PoolVector2Array):
	# seštejem zunanje točke poligon in jih delim s njihovim številom

	var center_position: Vector2 = Vector2.ZERO
	var polygon_points_hull: PoolVector2Array = Geometry.convex_hull_2d(polygon_points)
	var all_points_sum: Vector2 = Vector2.ZERO

	for hull_point_index in polygon_points_hull.size() - 1: # zadnja pika v hull je enaka prvi in je ne upoštevam
		all_points_sum += polygon_points_hull[hull_point_index]

	center_position = all_points_sum / (polygon_points_hull.size() - 1)

	return center_position

# OLD ... zgornja naj bi delala bolje
#	var center_position: Vector2 = Vector2.ZERO
#	# trikotnik
#	if polygon_points.size() == 3:
#		for point in polygon_points:
#			center_position += point
#		center_position /= 3
#
#	# 4 in več kotnik
#	elif polygon_points.size() > 3:
#		# poišče center	skrajnih 4 točk
#		var polygon_far_points: PoolVector2Array = get_polygon_far_points(polygon_points) # L-T-R-B
#		for point in polygon_far_points:
#			center_position += point
#		center_position /= 4
#
#	return center_position


# UTILITI ------------------------------------------------------------------------------------------


func centralize_polygon_position(polygon_points: PoolVector2Array):
	# pred: spawned pozicija je enaka breakerjevi, notranji poligon je zamaknjen
	# po: spawned ima origin v središču shape polygona

	var polygon_centralized_position: Vector2 = get_polygon_center(polygon_points)# + def_chunk_global_pos

	var moved_polygon_points: PoolVector2Array = []
	for point in polygon_points:
		var moved_point = point - polygon_centralized_position
		moved_polygon_points.append(moved_point)

#	return [moved_polygon_points, polygon_center + owner.position] # global_position]
	return [moved_polygon_points, polygon_centralized_position] # global_position]


func adapt_transforms_and_add_origin(polygon_to_transform: PoolVector2Array, origin_position: Vector2, shape_scale: Vector2 = Vector2.ONE, shape_rotation: float = 0):

	var transforming_shape: Polygon2D = Polygon2D.new() # ... za transforms
	transforming_shape.polygon = polygon_to_transform
	transforming_shape.scale = shape_scale
	transforming_shape.rotation = shape_rotation # še ni vpeljano

	transforming_shape.polygon = reset_shape_transforms(transforming_shape).polygon

	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var transformed_polygon: PoolVector2Array = []
	for point in transforming_shape.polygon:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * transforming_shape.scale + origin_position
		var hitting_point_position_against_object: Vector2 = point_global_position - owner.position
		transformed_polygon.append(hitting_point_position_against_object)

	return transformed_polygon


func reset_shape_transforms(shape_to_transform: Polygon2D):

	if shape_to_transform.transform != Transform2D.IDENTITY:
		# The identity Transform2D with no translation, rotation or scaling applied.
		# When applied to other data structures, IDENTITY performs no transformation.
		var transformed_polygon = shape_to_transform.transform.xform(shape_to_transform.polygon)
		shape_to_transform.transform = Transform2D.IDENTITY
		shape_to_transform.polygon = transformed_polygon

	return shape_to_transform


func sort_vectors_by_length(vector_1, vector_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if vector_1.length() > vector_2.length():
	    return true
	return false


func sort_vectors_by_x(vector_1, vector_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if vector_1.x > vector_2.x:
	    return true
	return false


func sort_vectors_by_y(vector_1, vector_2):# descending ... večji index je boljši
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if vector_1.y > vector_2.y:
	    return true
	return false
