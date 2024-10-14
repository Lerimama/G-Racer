extends Polygon2D
# slice je razenje
# split je dajanje narazen
# polygons so array točk, polygon2D so spawned polygon ali polygon_shapes

enum SPLIT_ORIGIN {CUSTOM, CENTERED, LIVE}
export (SPLIT_ORIGIN) var split_origin: int = 0

enum OPERATION{EDGE_SPLIT, SIDE_SLICE, GRID_SLICE, DAISY, DELAUNAY}

# polygon shape
export var shape_to_copy_path: NodePath = ""
var shape_to_copy: Node2D = null # da ga podam ob spawnu (prepiše grebanje exportane poti)

# splitting setup
export var split_edge_count: int = 1
export var long_split_count: int = 0
export var use_custom_origin: bool = true
onready var custom_origin: Position2D = $SplitOrigin # origin ima samo glavni poligon
onready var explosion_origin: Position2D = $ExplosionOrigin


var start_slice_origin_position: Vector2 = Vector2.ZERO

# neu
var first_slice: bool = true
var SlicedRigidPoly: PackedScene = preload("res://game/splitting_shape/SlicedRigidPolygon.tscn")
var setup_mode = true # spawna polygone med koraki
var sliced_polygons: Array

var spawned_setup_polygons: Array = []
var spawned_rigid_polygons: Array = []
onready var setup_polygons: Node2D = $SetupPolygons
var from_side: bool = true

onready var split_range_polygon: Polygon2D = $ExplosionOrigin/Polygon2D

func _input(event: InputEvent) -> void:
	
	# case slice
	
	if Input.is_action_just_pressed("no1"):
		slice_polygons(OPERATION.DELAUNAY)
	if Input.is_action_just_pressed("no2"):
		slice_polygons(OPERATION.DAISY)
	if Input.is_action_just_pressed("no3"):
		slice_polygons(OPERATION.SIDE_SLICE)
	if Input.is_action_just_pressed("no4"):
#		cross_split(polygon, split_range_polygon.polygon)
		cross_split(self, $Polygon2D2)
		
#		printt("all spawned", get_child_count() - 1, sliced_polygons.size())
		#		slice_polygons(OPERATION.EDGE_SPLIT)
	if Input.is_action_just_pressed("no5"):
		separate_sliced_polygons()
		
		
func _ready() -> void:
	
	# če spawnam iz šejpa
	if shape_to_copy:
		polygon = shape_to_copy.polygon
		
	# če je prespawn v šejp
	elif has_node(shape_to_copy_path):
		var new_polygon: Polygon2D = Polygon2D.new()
		new_polygon.polygon = get_node(shape_to_copy_path).polygon
	
	# narežem rob
#	for split_index in split_edge_count:
#		polygon = split_polygon_edge(polygon)		
#	from_side =  false
	var new_array = polygon
	if from_side:
#		var random_point_index = randi() % polygon.size() - 1 # 1 je da zadnje ne upošteva
		var random_point_index = 1 # 1 je da zadnje ne upošteva
		var this_point: Vector2 = polygon[random_point_index]
		var next_point: Vector2 = polygon[random_point_index + 1]
		var point_vector: Vector2 = next_point - this_point		
		var split_point: Vector2 = this_point + point_vector * 0.3 + Vector2(50,-50)
		start_slice_origin_position = split_point
#		new_array.insert(random_point_index + 1, start_slice_origin_position)
	else:
		if use_custom_origin: # parent split
			start_slice_origin_position = custom_origin.position
		else:
			start_slice_origin_position = get_polygon_center(polygon)
			
			
			#preveri obe strani, da ugotovi smer
#	new_array.push_back(start_slice_origin_position)
	polygon = new_array
	printt ("hm", new_array.size())
	
	
	
func slice_polygons(slice_style: int):
	
	var polygons_to_slice: Array
	if first_slice:
		polygons_to_slice = [polygon]
	else:
		polygons_to_slice = sliced_polygons.duplicate()
		sliced_polygons.clear()
	
	
	for poly in polygons_to_slice:
		match slice_style:
			OPERATION.EDGE_SPLIT:
				sliced_polygons.append(split_polygon_edge(poly))
				first_slice = false
			OPERATION.SIDE_SLICE:
				sliced_polygons.append_array(slice_sides(poly))
				first_slice = false
			OPERATION.DAISY:
				sliced_polygons.append_array(triangulate_delaunay(poly))
				first_slice = false
			OPERATION.DELAUNAY:
				sliced_polygons.append_array(triangulate_daisy(poly))
				first_slice = false
	
	if setup_mode:
		spawn_setup_polygons()
	
	# skrijem parent polygon
	
	
# SLICE ------------------------------------------------------------------------------------------------------------
	
	
func triangulate_daisy(polygon_points: PoolVector2Array): # RABIM?
	
	var daisy_triangles: Array = []
	
	# split origin
	var split_origin_position: Vector2
	if polygon_points == polygon: # parent split
		split_origin_position = start_slice_origin_position
	else:
		split_origin_position = get_polygon_center(polygon_points)
		
	# trikotniki so cvetovi marjetice s konico v slice origin točki
	# vsaka točka na robu dobi svoj trikotnik do origina
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
		var triangle_points: PoolVector2Array = [split_origin_position, this_point, next_point] # prva je v centru
		daisy_triangles.append(triangle_points)
	
	return daisy_triangles
	

func triangulate_delaunay(polygon_points: PoolVector2Array):

	var delaunay_triangles: Array = []
	
	# dodam origin točko poligona (extra split)
	var split_origin_position: Vector2
	if polygon_points == polygon and use_custom_origin: # parent split
		split_origin_position = custom_origin.position
	else:
		split_origin_position = get_polygon_center(polygon_points)

	var new_polygon_points = polygon_points
	new_polygon_points.push_back(split_origin_position)	
	
	# trianguliram
	randomize()
	var triangulate_points: PoolIntArray = Geometry.triangulate_delaunay_2d(new_polygon_points) # int array!!
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
			var current_point: Vector2 = new_polygon_points[points_array_index]
			# točko dodamo v array točk trenutnega trikotnika
			triangle_points.append(current_point)
		
		delaunay_triangles.append(triangle_points)	
	
	return delaunay_triangles
	

func slice_sides(polygon_points: PoolVector2Array):
	
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
		print("Too many or to little points to split long: ", polygon_points.size())
		var points_divisor: int = polygon_points.size() / 8
		var reduced_polygon_points: PoolVector2Array = []
		for point_index in polygon_points.size():
			if point_index % points_divisor == 0:
				printt(point_index, point_index % points_divisor)
				reduced_polygon_points.append(polygon_points[point_index])
				
		first_polygon = [reduced_polygon_points[0], reduced_polygon_points[1], reduced_polygon_points[5], reduced_polygon_points[6]] # pika[7] splita zadnjo stranico in je ne rabim
		second_polygon = [reduced_polygon_points[1], reduced_polygon_points[2], reduced_polygon_points[4], reduced_polygon_points[5]] # pika[3] splita zunanjo stranico in je ne rabim
	
	return [first_polygon, second_polygon]
	

# SPLIT ------------------------------------------------------------------------------------------------------------

# triangulira glavni poligon, ali splitane

func cross_split(base_polygon: Polygon2D, clip_polygon: Polygon2D):
	
	var base_points: PoolVector2Array = base_polygon.polygon
	var clip_points: PoolVector2Array = clip_polygon.polygon
	
	var position_diff: Vector2 = clip_polygon.global_position - base_polygon.global_position
	for point in clip_polygon.polygon:	
		point += position_diff
#	var clippings: Array = Geometry.clip_polygons_2d(base_points, clip_points)
	var clippings: Array = Geometry.clip_polygons_2d(clip_points, base_points)
	var clipped_base: PoolVector2Array = clippings[0]
	
	printt ("cliped", clippings, position_diff)
	spawn_setup_polygons([clipped_base], Color.blue)
#	if len(clippings) > 1:
#		spawn_setup_polygons([clippings[1]], Color.red, false)
	
	color.a = 0
	return
	
	
	
func split_polygons(separate_at_distance: float = 50, invert: bool = false):
	pass

	
func separate_sliced_polygons(separate_at_distance: float = 50, invert: bool = false):
	
	var polygons_to_spawn: Array = []
	var polygons_to_merge: Array = []
	var slice_origin_position = start_slice_origin_position
	
	# naberem polygone za splitat in jih izločim iz sliced polys
	if setup_mode:
		for setup_poly in spawned_setup_polygons:
			var in_distance: bool = false
			for point in setup_poly.polygon:
				var point_distance_from_origin: float = Vector2(point - slice_origin_position).length()
				if point_distance_from_origin < separate_at_distance:
					in_distance = true
			if in_distance:
				polygons_to_spawn.append(setup_poly.polygon)
			else:
				polygons_to_merge.append(setup_poly.polygon)
	# sliced polygons
	else:
		for poly in sliced_polygons:
			# distanca centra poligona
			#		var poly_center: Vector2 = get_polygon_center(poly)
			#		var distance_from_origin: float = Vector2(poly_center - slice_origin_position).length()
			#		if distance_from_origin < split_at_distance:
			#				polygons_to_split.append(poly)
			# distanca katere koli točke poligona
			var in_distance: bool = false
			for point in poly:
				var point_distance_from_origin: float = Vector2(point - slice_origin_position).length()
				if point_distance_from_origin < separate_at_distance:
					in_distance = true
			if in_distance:
				polygons_to_spawn.append(poly)
			else:
				polygons_to_merge.append(poly)
				
				
#	while not spawned_setup_polygons.empty():
#		spawned_setup_polygons.pop_back().queue_free()
	sliced_polygons.clear()	
	spawn_setup_polygons(polygons_to_spawn, Color.yellow)
			
#	spawn_rigid_polygons(polygons_to_spawn)
	merge_leftovers(polygons_to_merge)
#	clip_main_polygon(polygons_to_spawn)

func clip_main_polygon(clipper_polygons: Array):
	
	var main_polygon: PoolVector2Array = polygon
	
#	for clipping in clipping_polygons:
	var clipped_polygons: Array = Geometry.clip_polygons_2d(main_polygon, clipper_polygons[0])
	var clip_polygon: PoolVector2Array = []
	var hole_polygon: PoolVector2Array = []
	# clockwise je luknja
	for poly in clipped_polygons:
		if Geometry.is_polygon_clockwise(poly):
			hole_polygon = poly
		else:
			clip_polygon = poly
	# če ima luknjo, razpolovim
	if not hole_polygon.empty():
		print ("Can't clip to a hole")
		pass
		
	if not clipped_polygons.empty():
		printt("A", Geometry.is_polygon_clockwise(clipped_polygons[0]))
		spawn_setup_polygons([clipped_polygons[0]], Color.blue, false)
		if clipped_polygons.size() > 1:
			printt("B", Geometry.is_polygon_clockwise(clipped_polygons[1]))
			spawn_setup_polygons([clipped_polygons[1]], Color.red, false)




var merge_count: = 0
var merge_count_limit: = 1

func merge_leftovers(leftover_polygons: Array):
	printt("start leftovers", leftover_polygons.size())
#	# no merge
#	spawn_setup_polygons(leftover_polygons, Color.red, false)
#	return
	
	# mono merge
#	var main_poly: PoolVector2Array = leftover_polygons.pop_back()
#	var polygons_to_merge: Array = leftover_polygons.duplicate()
	
	var main_poly: PoolVector2Array = leftover_polygons[0]
	while (true):
		var merged_polygons: Array = merge_polygon_with_neighbor(main_poly, leftover_polygons)
		if merged_polygons.empty(): # pomeni, da ne najde pravega soseda
			break
		else:
			main_poly = merged_polygons[0]
			leftover_polygons = merged_polygons[1]
		
	spawn_setup_polygons([main_poly], Color.blue, false)
#	spawn_setup_polygons(new_leftovers, Color.red, false)	
	spawn_setup_polygons(leftover_polygons, Color(1,1,1,0.5), false)	
	
	
func merge_polygon_with_neighbor(main_polygon: PoolVector2Array, leftover_polygons: Array):
	
	# najdem prvega soseda in ga mergam vse sosede enega šejpa
	var neighbor_polygon: PoolVector2Array = []
	var weaker_neighbor_polygon: PoolVector2Array = []
#	for point in home_polygon:
#		for poly in leftover_polygons:
#			if poly.has(point):
#				neighbor_polygon = poly
#				break
			
	for poly in leftover_polygons:
		var shared_points_count: int = 0 				
		for poly_point in poly:
			if Geometry.is_point_in_polygon(poly_point, main_polygon):
				shared_points_count += 1
#		if shared_points_count > 1:
#			neighbor_polygon = poly
		if shared_points_count > 0:
#		elif shared_points_count == 1:
			weaker_neighbor_polygon = poly
	
	if neighbor_polygon:
		print("mergam")
		var merged_polygons = Geometry.merge_polygons_2d(main_polygon, neighbor_polygon)
		main_polygon = merged_polygons[0]
		leftover_polygons.erase(neighbor_polygon)
		leftover_polygons.erase(main_polygon)
		printt("END leftovers", leftover_polygons.size())
		return [main_polygon, leftover_polygons]	
	elif weaker_neighbor_polygon:
		print("mergam slabši sosed.")
		var merged_polygons = Geometry.merge_polygons_2d(main_polygon, weaker_neighbor_polygon)
		main_polygon = merged_polygons[0]
		leftover_polygons.erase(weaker_neighbor_polygon)
		leftover_polygons.erase(main_polygon)
		printt("END leftovers", leftover_polygons.size())
		return [main_polygon, leftover_polygons]	
	else:
		print("Error ... ni pravega soseda.")
		printt("END leftovers", leftover_polygons.size())
		return []	
	
			
				

	# mergam sosede
	# dokler ne brejkam ponavljam združevanje glavne oblik z vsakim od sosedov
	# brejkam, ko ni več polignov za removat
#	var polygons_to_remove: Array = []
#	while (true): 
#		for neighbor in neighbor_polygons:
#			var merged_polygons = Geometry.merge_polygons_2d(neighbor, home_polygon)
#			home_polygon = merged_polygons[0] # če mergam, spremenim polygon_in_check z merged pikami			
#			polygons_to_remove.append(neighbor) # zabeležim, da je za odstranit
#
#		if polygons_to_remove.size() == neighbor_polygons.size():
#			break
#
#	# spucam združene sosede iz vseh za mergat
#	for poly in neighbor_polygons:
#		leftover_polygons.erase(poly)
#	neighbor_polygons.clear()		
	

		
			
func merge_polygon_with_neighbors(home_polygon: PoolVector2Array, leftover_polygons: Array):
	
	# naberem vse sosede enega šejpa
	var neighbor_polygons: Array = []
	for point in home_polygon:
		for poly in leftover_polygons:
			if poly.has(point):
				neighbor_polygons.append(poly)
				break
				
	#	for poly in leftover_polygons:
	#		for poly_point in poly:
	#			if Geometry.is_point_in_polygon(poly_point, home_polygon):
	#				neighbor_polygons.append(poly)

	# mergam sosede
	# dokler ne brejkam ponavljam združevanje glavne oblik z vsakim od sosedov
	# brejkam, ko ni več polignov za removat
	var polygons_to_remove: Array = []
	while (true): 
		for neighbor in neighbor_polygons:
			var merged_polygons = Geometry.merge_polygons_2d(home_polygon, neighbor)
			home_polygon = merged_polygons[0] # če mergam, spremenim polygon_in_check z merged pikami			
			polygons_to_remove.append(neighbor) # zabeležim, da je za odstranit
		
		if polygons_to_remove.size() == neighbor_polygons.size():
			break
	
	# spucam združene sosede iz vseh za mergat
	for poly in neighbor_polygons:
		leftover_polygons.erase(poly)
	neighbor_polygons.clear()		
	
	printt("END leftovers", leftover_polygons.size())
		
	return [home_polygon, leftover_polygons]	
		
		
	# če je glavni poligon preklan in nastane več glavnih poligonov
	# vsak poligon preverim, če si kakšno od točk deli s kakšnim še ne dodanim poligonom
	#	var polygons_to_check: Array = polygons_to_merge.duplicate()
	#	var checked_polygons: Array = []
	#	var nejbr_poliz: Array = []
	#	for poly_index in polygons_to_merge.size():
	#		var first_polygon = polygons_to_merge[poly_index]
	#		#  vsako točko poligona preverim, če je v katerem od ostalih poligonov		
	#		for point in first_polygon:
	#			for poly in polygons_to_check:
	#				if poly.has(point):
	#					nejbr_poliz.append(poly)
	#					polygons_to_check.erase(poly)
	#		# dodam med preverjene
	#		checked_polygons.append(first_polygon)
	#		polygons_to_check.erase(first_polygon)


# SPAWN ------------------------------------------------------------------------------------------------------------
	
	
		
func spawn_rigid_polygons(polygons_to_spawn: Array):
		
	for poly in polygons_to_spawn:
		var new_rigid_polygon: RigidBody2D = SlicedRigidPoly.instance()
		new_rigid_polygon.sliced_polygon_points = poly
		new_rigid_polygon.z_index = 10 # debug
		new_rigid_polygon.position += global_position
		
		# podam vektor od origina
#		var polygon_center: Vector2 = get_polygon_center(poly.polygon)
#		new_rigid_polygon.vector_from_origin = polygon_center - custom_origin.global_position	
		
		# debug
		new_rigid_polygon.modulate = Color.yellow
		new_rigid_polygon.modulate.v = randf() * 1.5
		if Ref.node_creation_parent:
			Ref.node_creation_parent.add_child(new_rigid_polygon)
		else:
			get_tree().root.add_child(new_rigid_polygon)
		
		color.a = 0 
			
			
func spawn_rigid_polygons_from_2ds(polygons_to_spawn: Array):
		
	for poly in polygons_to_spawn:
		
		var new_rigid_polygon: RigidBody2D = SlicedRigidPoly.instance()
		# podam vektor za kopiranje
		new_rigid_polygon.sliced_polygon_shape = poly
		new_rigid_polygon.z_index = 10 # debug
		
		# podam vektor od origina
#		var polygon_center: Vector2 = get_polygon_center(poly.polygon)
#		new_rigid_polygon.vector_from_origin = polygon_center - custom_origin.global_position	
		
		# debug
		if Ref.node_creation_parent:
			Ref.node_creation_parent.add_child(new_rigid_polygon)
		else:
			get_tree().root.add_child(new_rigid_polygon)
		
	# pucanje ostankov ob zaključku procesa
	while not spawned_setup_polygons.empty():
		spawned_setup_polygons.pop_back().queue_free()
	sliced_polygons.clear()		
		
	color.a = 0 
	

	
	
func spawn_setup_polygons(from_polygons: Array = sliced_polygons, polygon_color: Color = Color.black, clear_before: bool = true):
	
	if clear_before: # debug
		while not spawned_setup_polygons.empty():
			spawned_setup_polygons.pop_back().queue_free()	
		spawned_setup_polygons.clear()
	
	for poly_index in from_polygons.size():
		var new_polygon = Polygon2D.new()
		new_polygon.polygon = from_polygons[poly_index]
		new_polygon.z_index = 10 # debug
		# spawnam poligon
		setup_polygons.add_child(new_polygon)
						
		spawned_setup_polygons.append(new_polygon)
		new_polygon.color = polygon_color
		if from_polygons.size() > 1:
			new_polygon.color.v = randf() * 1.5
			
	color.a = 0 
#	clean_lefovers()

# UTILITI ------------------------------------------------------------------------------------------------------------


func split_polygon_edge(poly_edge_points: PoolVector2Array):
	
	var split_points_to_add: Array = []
	
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
		var split_point: Vector2 = this_point + point_vector/2
		split_points_to_add.append(split_point)
	
	# dodam split points v poligon ... ločeno, da imam bolj pod kontrolo zaporedje
	var point_index_grow: int = 1 # adaptiram na spreminjajoč index obstoječih točk v poligonu
	for point_index in split_points_to_add.size():
		poly_edge_points.insert(point_index + point_index_grow, split_points_to_add[point_index])
		point_index_grow += 1
	
	return poly_edge_points



func split_polygon_edge_on_distance(poly_edge_points: PoolVector2Array = polygon, split_on_distance: float = 0):
	
	var split_points_to_add: Array = []
	
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
		# distanco spremenim delež dolžine vektorja
		var split_part: float
		if point_vector.length() > 0:
			split_part = split_on_distance / point_vector.length()
		else:
			split_part = 0
		# če je distanca večja od dolžine vektorja, ne splitam 
		if split_part >= 1:
			split_part = 0.5
		elif split_on_distance == 0:
			split_part = 0.5
		elif split_part > 0:
			var split_point: Vector2 = this_point + point_vector * split_part
			split_points_to_add.append(split_point)
	
	# dodam split points v poligon ... ločeno, da imam bolj pod kontrolo zaporedje
	var point_index_grow: int = 1 # adaptiram na spreminjajoč index obstoječih točk v poligonu
	for point_index in split_points_to_add.size():
		poly_edge_points.insert(point_index + point_index_grow, split_points_to_add[point_index])
		point_index_grow += 1
	
	return poly_edge_points


func get_polygon_center(poly_points: PoolVector2Array):
	
	var center_position: Vector2 = Vector2.ZERO
	for p in poly_points:
		center_position += p
	center_position /= poly_points.size()
	
	return center_position


func sort_sides_by_length(side_1, side_2):
	
	if side_1.length() > side_2.length():
	    return true
	return false



		

##	while(true):
##		print("mergam")
##		# združim enega s sosedi in zbrišem sosede iz ostankov
##		var merged_polygons: Array = merge_polygon_with_neighbors(merged_polygon, leftover_polygons)
##
##		merged_polygon = merged_polygons[0]
##		leftover_polygons = merged_polygons[1]
##
##		if leftover_polygons.empty():
##			break
#

	
	# v1 ... na koncu ostanejo čudni poligoni
	#	var polygons_to_remove: Array
	#	while(true):
	#		polygons_to_remove = []
	#		for child_index in setup_polygons.get_child_count():
	#			var child = setup_polygons.get_child(child_index)
	#			var found_polygon: Polygon2D = child as Polygon2D
	#			if found_polygon == null or found_polygon.is_queued_for_deletion():
	#				continue
	#			if found_polygon.transform != Transform2D.IDENTITY:
	#				var transformed_polygon = found_polygon.transform.xform(found_polygon.polygon)
	#				found_polygon.transform = Transform2D.IDENTITY
	#				found_polygon.polygon = transformed_polygon
	#
	#			for child_subindex in child_index:
	#				var other_child = setup_polygons.get_child(child_subindex)
	#				var other_found_polygon:Polygon2D = other_child as Polygon2D
	#				if other_found_polygon == null or other_found_polygon.is_queued_for_deletion():
	#					continue
	#				var merged_polygons = Geometry.merge_polygons_2d(found_polygon.polygon, other_found_polygon.polygon)
	#				# če se nista mergala ... ni samo enega poligona, potem skipnem, ker ni delovalo
	#				if merged_polygons.size() != 1: 
	#					continue
	#				# če sta se mergala setam merganega za naslednjega za iteracijo
	#				other_found_polygon.polygon = merged_polygons[0]
	#				polygons_to_remove.append(found_polygon)
	#				break
	#		# grem ven iz loopa
	#		if polygons_to_remove.size() == 0:
	#			break
	#		for polygon_to_remove in polygons_to_remove:
	#			polygon_to_remove.queue_free()
	#	print("polygons_to_remove", polygons_to_remove.size())	
