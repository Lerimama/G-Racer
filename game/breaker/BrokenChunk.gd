extends Polygon2D


export var use_custom_origin: bool = true
export var shape_path: NodePath = ""

var shape_polygon: PoolVector2Array = [] # da ga podam ob spawnu (prepiše grebanje exportane poti)
var sliced_polygons: Array
var slice_origin_global_position: Vector2 # ob spawnu
var BrokenDebry: PackedScene = preload("res://game/breaker/BrokenDebry.tscn")
var BrokenDebryArea: PackedScene = preload("res://game/breaker/BrokenDebryArea.tscn")
onready var custom_origin: Position2D = $CustomOrigin
onready var cracked_shapes_parent: Node2D = $CrackedShapes


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		pass
	if Input.is_action_just_pressed("no2"):
		on_slice() # debug
	if Input.is_action_just_pressed("no3"):
		build_grid()
	if Input.is_action_just_pressed("no4"):
		culor()
	if Input.is_action_just_pressed("no5"):
		pass
		
		
func _ready() -> void:
	
	if shape_polygon.empty():
		if has_node(shape_path):
			var new_polygon: Polygon2D = Polygon2D.new()
			new_polygon.polygon = get_node(shape_path).polygon
	else:
		polygon = shape_polygon
	
		
	
func on_slice():
	
	slice_polygons()
	spawn_debry_polygons(sliced_polygons)
	color.a = 0 
	sliced_polygons.clear()	
	queue_free()
	
	
func slice_polygons():
	
	var split_edge_count: int = 1
	var slice_side_count: int = 2
	
	# opredelim origin pozicijo
	randomize()
	var random_point_index = 0 #randi() % polygon.size() - 1 # 1 je da zadnje ne upošteva
	var first_point: Vector2 = polygon[random_point_index]
	var second_point: Vector2 = polygon[random_point_index + 1]
	var vector_to_next_point: Vector2 = second_point - first_point
	var slice_point: Vector2 = first_point + vector_to_next_point * 0.3 # + Vector2(50,-50) # debug ... offset, da je vidno
	
	# EDGE SPLIT
	var new_polygon_points = polygon
	for c in split_edge_count:
		new_polygon_points = split_polygon_edge(new_polygon_points)
	var new_first_point_index: int = new_polygon_points.find(first_point)
	var second_point_index: int = new_polygon_points.find(second_point)
	# odstranim pike na robu origina
	for point_index in new_polygon_points.size(): 
		if point_index > new_first_point_index and point_index < second_point_index:
			new_polygon_points.remove(point_index)
	
	# insert slice origin
	new_polygon_points.insert(random_point_index + 1, slice_point)
		
	# DAISY SLICE
	var origin_point_index: int = new_polygon_points.find(slice_point)
#	sliced_polygons = triangulate_daisy(new_polygon_points, origin_point_index)
	use_custom_origin = false
	sliced_polygons = triangulate_daisy(new_polygon_points)
	
	# SIDE SLICE
	var new_sliced_polygons: Array = sliced_polygons.duplicate()
	for c in slice_side_count:
		for poly_index in sliced_polygons.size():
			sliced_polygons.append_array(slice_sides(sliced_polygons[poly_index]))
	
	# printt("sliced", sliced_polygons.size())
	

# SLICING ------------------------------------------------------------------------------------------------------------

	
func triangulate_daisy(polygon_points: PoolVector2Array, slice_origin_index: int = -1):
	
	# OPT slice origin
	var slice_origin: Vector2 = polygon_points[slice_origin_index]	
	if slice_origin_index == -1:
		if not slice_origin_global_position == Vector2.ZERO:
			slice_origin = slice_origin_global_position - global_position
		else:	
			if polygon_points == polygon and use_custom_origin: # parent slice
				slice_origin = custom_origin.position
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
		if not slice_origin_global_position == Vector2.ZERO:
			slice_origin = slice_origin_global_position - global_position
		else:	
			if polygon_points == polygon and use_custom_origin: # parent slice
				slice_origin = custom_origin.position
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


enum GRID_STYLE {SQUARE}
var grid_shapes: Array

func slice_grid():
	
	# ločim vse točke na notranje in zunanje 
	# ločim vse grid šejpe na čisto zunaj, za klipat, in čisto notri
	var outside_polygons: Array
	var inside_polygons: Array
	var between_polygons: Array
	
	for poly in grid_polygons:
		var points_count: int = poly.size()
		var inside_points: Array
		var outside_points: Array
		for point in poly:
			if Geometry.is_point_in_polygon(point, polygon):
				inside_points.append(point)
		if inside_points.size() == 0:
			outside_polygons.append(poly)
		elif inside_points.size() < points_count:
			between_polygons.append(poly)
		elif inside_points.size() == points_count:
			inside_polygons.append(poly)
			
	
	printt ("all grid polyis", inside_polygons.size(), between_polygons.size(), outside_polygons.size())
	
	
var grid_polygons: Array
func build_grid(grid_shape_corner_count: int = 4):
	
	var start_position: Vector2 = Vector2.ZERO
	var grid_split_count: int = 10 
	var grid_split_size: float = 5
	var shape_grid_x_index: int = 0
	var shape_grid_y_index: int = 0
	
	for x in grid_split_count:
		shape_grid_x_index += 1
		for y in grid_split_count:
			shape_grid_y_index += 1
			
			var rectangle_position: Vector2 = Vector2(shape_grid_x_index - 1, shape_grid_y_index - 1) * grid_split_size # -1 , da začne z 0 pozicijo
			
			var point_LT: Vector2 = rectangle_position
			var point_RT: Vector2 = rectangle_position + Vector2(0, grid_split_size) 
			var point_RB: Vector2 = rectangle_position + Vector2(grid_split_size, grid_split_size)
			var point_LB: Vector2 = rectangle_position + Vector2(0, grid_split_size)
			var rectangle_polygon: PoolVector2Array = [point_LT, point_RT, point_RB, point_LB]
			grid_polygons.append(rectangle_polygon)
			
#			# debug
#			var new_poly = Polygon2D.new()			
#			new_poly.position = rectangle_position
#			new_poly.polygon = rectangle_polygon
#			new_poly.color = Color.purple
#			get_tree().root.add_child(new_poly)
#			grid_shapes.append(new_poly)
		
	slice_grid()	
	printt ("GRID", grid_polygons.size(), grid_shapes.size())			
				
func culor():
	
	for p in grid_shapes:
		p.modulate = Color.yellow
		printt ("sh color", p.modulate)


# SPAWN ------------------------------------------------------------------------------------------------------------
	
		
func spawn_debry_polygons(polygons_to_spawn: Array = sliced_polygons, polygon_color: Color = Color.blue):
		
	# spawnam v node, kjer je original Breaker shape ... po logiki
	var new_debry_parent = get_parent().get_parent().get_parent() # ni static type, ker je lahko karkoli
	
	for poly in polygons_to_spawn:
#		var new_debry: RigidBody2D = BrokenDebry.instance()
		var new_debry: Node2D = BrokenDebryArea.instance()
		new_debry.debry_polygon = poly
		new_debry.z_index = 10 # debug
		new_debry.position += global_position
#		new_debry.vector_from_origin = 
#		new_debry.modulate = polygon_color
#		new_debry.modulate.v = randf() * 1.5
		new_debry_parent.add_child(new_debry)
		
	
func spawn_crack_polygons(from_polygons: Array = sliced_polygons, polygon_color: Color = Color.black, clear_before: bool = true):
	
	if clear_before: # debug
		while cracked_shapes_parent.get_child_count() > 0:
			cracked_shapes_parent.get_children().pop_back().queue_free()	
	
	for poly_index in from_polygons.size():
		var new_polygon = Polygon2D.new()
		new_polygon.polygon = from_polygons[poly_index]
		new_polygon.z_index = 10 # debug
		# spawnam poligon
		cracked_shapes_parent.add_child(new_polygon)
						
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

	var neighbor_polygons: Array
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
	var polygons_to_remove: Array
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
