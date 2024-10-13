extends Polygon2D
# slice je razenje
# split je dajanje narazen

enum SPLIT_ORIGIN {CUSTOM, CENTERED, LIVE}
export (SPLIT_ORIGIN) var split_origin: int = 0

enum OPERATION_STYLE {EDGE_SPLIT, SIDE_SLICE, DAISY, DELAUNAY}

# polygon shape
export var shape_to_copy_path: NodePath = ""
var shape_to_copy: Node2D = null # da ga podam ob spawnu (prepiše grebanje exportane poti)

# splitting setup
export var split_edge_count: int = 1
export var long_split_count: int = 0
export var use_custom_origin: bool = true
onready var custom_origin: Position2D = $ExplosionOrigin # origin ima samo glavni poligon
var start_slice_origin_position: Vector2 = Vector2.ZERO

# neu
var first_slice: bool = true
var SlicedRigidPoly: PackedScene = preload("res://game/level/SlicedRigidPolygon.tscn")
var setup_mode = true # spawna polygone med koraki
var sliced_polygons: Array
var mid_spawned_polygons: Array = []


func _input(event: InputEvent) -> void:
	
	# case slice
	
	if Input.is_action_just_pressed("no1"):
		slice_polygons(OPERATION_STYLE.DELAUNAY)
	if Input.is_action_just_pressed("no2"):
		slice_polygons(OPERATION_STYLE.DAISY)
	if Input.is_action_just_pressed("no3"):
		slice_polygons(OPERATION_STYLE.SIDE_SLICE)
	if Input.is_action_just_pressed("no4"):
		slice_polygons(OPERATION_STYLE.EDGE_SPLIT)
	if Input.is_action_just_pressed("no5"):
		split_and_merge_sliced_polygons()
		
		
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

	if use_custom_origin: # parent split
		start_slice_origin_position = custom_origin.position
	else:
		start_slice_origin_position = get_polygon_center(polygon)


func slice_polygons(slice_style: int):
	
	var polygons_to_slice: Array
	if first_slice:
		polygons_to_slice = [polygon]
		first_slice = false
	else:
		polygons_to_slice = sliced_polygons.duplicate()
		sliced_polygons.clear()
	
	
	for poly in polygons_to_slice:
		match slice_style:
			OPERATION_STYLE.EDGE_SPLIT:
				sliced_polygons.append(split_polygon_edge(poly))
			OPERATION_STYLE.SIDE_SLICE:
				sliced_polygons.append_array(slice_sides(poly))
			OPERATION_STYLE.DAISY:
				sliced_polygons.append_array(triangulate_delaunay(poly))
			OPERATION_STYLE.DELAUNAY:
				sliced_polygons.append_array(triangulate_daisy(poly))
	
	if setup_mode:
		spawn_setup_polygons()
	
	# skrijem parent polygon
	
	print(sliced_polygons.size())
	
	
# SLICE ------------------------------------------------------------------------------------------------------------
	
	
func triangulate_daisy(polygon_points: PoolVector2Array = polygon):
	
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
	

func triangulate_delaunay(polygon_points: PoolVector2Array = polygon):

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
	
	
func slice_sides(polygon_points: PoolVector2Array = polygon):
	
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
		first_polygon = [polygon_points[0], polygon_points[1], polygon_points[5], polygon_points[0]]
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
	

# SLICE ------------------------------------------------------------------------------------------------------------


func split_and_merge_sliced_polygons(split_at_distance: float = 200, invert: bool = false):
	
	# reset
	polygons_to_merge.clear()
	polygons_to_split.clear()
	
	var split_origin_position = start_slice_origin_position
	for split_poly in mid_spawned_polygons:
		for point in split_poly.polygon:
			var origin_to_point_distance: float = Vector2(point - split_origin_position).length()
			if origin_to_point_distance < split_at_distance and not polygons_to_split.has(split_poly):
					polygons_to_split.append(split_poly)
				
	for poly in mid_spawned_polygons:
		if not polygons_to_split.has(poly):
			poly.color = Color.red
		else:
			polygons_to_merge.append(poly)
			poly.color = Color.palegreen
			
	#	printt("polygons_to_split", mid_spawned_polygons.size(), polygons_to_split.size(), polygons_to_merge.size())
#	for 
	
	
func merge_leftover_polygons(polygons_to_merge: Array):
	for p in polygons_to_split:
		var new_rigid_polygon: RigidBody2D = SlicedRigidPoly.instance()
		# podam vektor za kopiranje
		new_rigid_polygon.sliced_polygon_shape = p
		new_rigid_polygon.position = p.position# + global_position
		# podam vektor od origina
		var polygon_center: Vector2 = get_polygon_center(p.polygon)
		new_rigid_polygon.vector_from_origin = polygon_center - custom_origin.global_position	
		Ref.node_creation_parent.add_child(new_rigid_polygon)
	pass


# SPAWN ------------------------------------------------------------------------------------------------------------
	
	
func spawn_rigid_polygons(polygons_to_spawn: Array):
	
	for poly in polygons_to_spawn:
		
		var new_rigid_polygon: RigidBody2D = SlicedRigidPoly.instance()
		# podam vektor za kopiranje
		new_rigid_polygon.sliced_polygon_shape = poly
		new_rigid_polygon.position = poly.position# + global_position
		# podam vektor od origina
		var polygon_center: Vector2 = get_polygon_center(poly.polygon)
		new_rigid_polygon.vector_from_origin = polygon_center - custom_origin.global_position	
		Ref.node_creation_parent.add_child(new_rigid_polygon)
		
#	merge_leftover_polygons()	
	
	# pucanje ostankov ob zaključku proces
	while not mid_spawned_polygons.empty():
		mid_spawned_polygons.pop_back().queue_free()
	sliced_polygons.clear()	
		
	color.a = 0 
		
	
func spawn_setup_polygons():
	
	for poly_index in sliced_polygons.size():
		var new_polygon = Polygon2D.new()
		new_polygon.polygon = sliced_polygons[poly_index]
		new_polygon.z_index = 10 # debug
		# spawnam poligon
		add_child(new_polygon)
		mid_spawned_polygons.append(new_polygon)
						
		new_polygon.color = Color.black
		new_polygon.color.v = randf()

	color.a = 0 


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


# triangulira glavni poligon, ali splitane

var polygons_to_merge: Array = []
var polygons_to_split: Array = []
		
#func merge_leftover_polygons():
#
#	printt ("merge", polygons_to_merge.size())
##	while not polygons_to_merge.size() == 1:
#	polygons_to_merge[0].color = Color.red
#	polygons_to_merge[1].color = Color.red
#	var first_poly: PoolVector2Array = polygons_to_merge[0].polygon
#	var second_poly: PoolVector2Array = polygons_to_merge[1].polygon
#	var merged: Array = Geometry.merge_polygons_2d(first_poly, second_poly)
#	polygons_to_merge.append_array(merged)
#
#
#	print (merged.size())
#	print ("-----")
		
#		for m_index in polygons_to_merge.size():
#			polygons_to_merge.erase()

#	pass
