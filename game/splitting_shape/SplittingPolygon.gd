extends Polygon2D


export var use_custom_origin: bool = true
export var shape_to_copy_path: NodePath = ""

var shape_to_copy: Node2D = null # da ga podam ob spawnu (prepiše grebanje exportane poti)
var sliced_polygons: Array
var spawned_setup_polygons: Array = []
var spawned_rigid_polygons: Array = []

var SlicedRigidPoly: PackedScene = preload("res://game/splitting_shape/SlicedDebry.tscn")
onready var custom_origin: Position2D = $SplitOrigin # ima samo glavni poligon
onready var setup_polygons: Node2D = $SetupPolygons


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		on_hit()
	if Input.is_action_just_pressed("no2"):
		pass
	if Input.is_action_just_pressed("no3"):
		pass
	if Input.is_action_just_pressed("no4"):
		pass
	if Input.is_action_just_pressed("no5"):
		pass
		
		
func _ready() -> void:
	
	if has_node(shape_to_copy_path):
		var new_polygon: Polygon2D = Polygon2D.new()
		new_polygon.polygon = get_node(shape_to_copy_path).polygon
	elif shape_to_copy:
		polygon = shape_to_copy.polygon
		
	
func on_hit():
	
	slice_polygons()
	spawn_rigid_polygons(sliced_polygons)
	color.a = 0 
	sliced_polygons.clear()	
	
	
func slice_polygons():
	
	var split_edge_count: int = 1
	var split_long_count: int = 4
	
	# opredelim origin pozicijo
	randomize()
	var random_point_index = 0 #randi() % polygon.size() - 1 # 1 je da zadnje ne upošteva
	var first_point: Vector2 = polygon[random_point_index]
	var second_point: Vector2 = polygon[random_point_index + 1]
	var vector_to_next_point: Vector2 = second_point - first_point
	var split_point: Vector2 = first_point + vector_to_next_point * 0.3 # + Vector2(50,-50) # debug ... offset, da je vidno
	
	# split edge
	# splitam in odstranim pike na robu origin pike
	var new_polygon_points = polygon
	for c in split_edge_count:
		new_polygon_points = split_polygon_edge(new_polygon_points)
	var new_first_point_index: int = new_polygon_points.find(first_point)
	var second_point_index: int = new_polygon_points.find(second_point)
	# preverjam distanco vseh točk na tej stranici
	for point_index in len(new_polygon_points): 
		# omejim na stranico
		if point_index > new_first_point_index and point_index < second_point_index:
			new_polygon_points.remove(point_index)
	
	# insert split origin
	new_polygon_points.insert(random_point_index + 1, split_point)
		
	# daisy
	var origin_point_index: int = new_polygon_points.find(split_point)
	sliced_polygons = triangulate_daisy(new_polygon_points, origin_point_index)
	
	# split sides
	var new_sliced_polygons: Array = sliced_polygons.duplicate()
	for c in split_long_count:
		for poly_index in len(sliced_polygons):
			sliced_polygons.append_array(slice_sides(sliced_polygons[poly_index]))
	
	printt("sliced", sliced_polygons.size())
	

# SLICING ------------------------------------------------------------------------------------------------------------

	
func triangulate_daisy(polygon_points: PoolVector2Array, split_origin_index: int = -1):
	
	# split origin
	var split_origin: Vector2 = polygon_points[split_origin_index]	
	if split_origin_index == -1:
		if polygon_points == polygon and use_custom_origin: # parent split
			split_origin = custom_origin.position
		else:
			split_origin = get_polygon_center(polygon_points)
	else:
		split_origin = polygon_points[split_origin_index]
		
		
	# trikotniki so cvetovi marjetice s konico v slice origin točki
	# vsaka točka na robu dobi svoj trikotnik do origina
	var daisy_triangles: Array = []
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
		var triangle_points: PoolVector2Array = [split_origin, this_point, next_point] # prva je v centru
		daisy_triangles.append(triangle_points)
	
	return daisy_triangles
	

func triangulate_delaunay(polygon_points: PoolVector2Array, split_origin_index: int = -1):

	var delaunay_triangles: Array = []
	
	# split origin
	var split_origin: Vector2 = polygon_points[split_origin_index]	
	if split_origin_index == -1:
		if polygon_points == polygon and use_custom_origin: # parent split
			split_origin = custom_origin.position
		else:
			split_origin = get_polygon_center(polygon_points)
	else:
		split_origin = polygon_points[split_origin_index]

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


# SPAWN ------------------------------------------------------------------------------------------------------------
	
		
func spawn_rigid_polygons(polygons_to_spawn: Array = sliced_polygons, polygon_color: Color = Color.blue):
		
	for poly in polygons_to_spawn:
		var new_rigid_polygon: RigidBody2D = SlicedRigidPoly.instance()
		new_rigid_polygon.sliced_polygon_points = poly
		new_rigid_polygon.z_index = 10 # debug
		new_rigid_polygon.position += global_position
		
		# podam vektor od origina
#		var polygon_center: Vector2 = get_polygon_center(poly.polygon)
#		new_rigid_polygon.vector_from_origin = polygon_center - custom_origin.global_position	
		
		# debug
		new_rigid_polygon.modulate = polygon_color
		new_rigid_polygon.modulate.v = randf() * 1.5
		if Ref.node_creation_parent:
			Ref.node_creation_parent.add_child(new_rigid_polygon)
		else:
			get_tree().root.add_child(new_rigid_polygon)
		
		spawned_rigid_polygons.append(new_rigid_polygon)
		
	
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
			new_polygon.color.v = randf()
			
	color.a = 0 


# UTILITI ------------------------------------------------------------------------------------------------------------

	
func merge_polygon_with_single_neighbor(main_polygon: PoolVector2Array, other_polygons: Array):
	
	# najdem prvega soseda in ga mergam vse sosede enega šejpa
	var neighbor_polygon: PoolVector2Array = []
	var shared_points_limit: int = 2
	for poly in other_polygons:
		var shared_points_count: int = 0 				
		for poly_point in poly:
			if Geometry.is_point_in_polygon(poly_point, main_polygon):
				shared_points_count += 1
		if shared_points_count >= shared_points_limit:
			neighbor_polygon = poly
	
	if neighbor_polygon:
		print("mergam")
		var merged_polygons = Geometry.merge_polygons_2d(main_polygon, neighbor_polygon)
		main_polygon = merged_polygons[0]
		other_polygons.erase(neighbor_polygon)
		other_polygons.erase(main_polygon)
		printt("END leftovers", other_polygons.size())
		return [main_polygon, other_polygons] # vrnem chunk in preostale za združevat
	else:
		print("Error ... ni pravega soseda.")
		printt("END leftovers", other_polygons.size())
		return []	
		
			
func merge_polygon_with_neighbors(main_polygon: PoolVector2Array, other_polygons: Array):

	var neighbor_polygons: Array = []
	var shared_points_limit: int = 2
	for poly in other_polygons:
		var shared_points_count: int = 0 				
		for poly_point in poly:
			if Geometry.is_point_in_polygon(poly_point, main_polygon):
				shared_points_count += 1
		if shared_points_count >= shared_points_limit:
			neighbor_polygons.append(poly)
				
	# mergam sosede
	# dokler ne brejkam ponavljam združevanje glavne oblik z vsakim od sosedov
	# brejkam, ko ni več polignov za removat
	var polygons_to_remove: Array = []
	while (true): 
		for neighbor in neighbor_polygons:
			var merged_polygons = Geometry.merge_polygons_2d(main_polygon, neighbor)
			main_polygon = merged_polygons[0] # če mergam, spremenim polygon_in_check z merged pikami			
			polygons_to_remove.append(neighbor) # zabeležim, da je za odstranit
		
		if polygons_to_remove.size() == neighbor_polygons.size():
			break
	
	# spucam združene sosede iz vseh za mergat
	for poly in neighbor_polygons:
		other_polygons.erase(poly)
	neighbor_polygons.clear()		
	
	printt("END leftovers", other_polygons.size())
		
	return [main_polygon, other_polygons] # vrnem chunk in preostale za združevat


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
