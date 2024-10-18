extends Polygon2D
# slice je zarezovanje
# split je dajanje narazen

enum SLICE_STYLE {BLAST, GRID_SQ, GRID_HEX}
var chunk_slice_style: int = SLICE_STYLE.BLAST #setget _change_slice_style

var chunk_polygon: PoolVector2Array # ob spawnu
var slice_origin_global_position: Vector2 # ob spawnu ... če ga ni, se uporabi sredino
var sliced_polygons: Array
onready var crackers_parent: Node2D = $Crackers
onready var slicing_operations: Node = $SlicingOperations
onready var DebryRigid: PackedScene = preload("res://game/breaker/DebryRigid.tscn")
onready var DebryArea: PackedScene = preload("res://game/breaker/DebryArea.tscn")
onready var Cracker: PackedScene = preload("res://game/breaker/Cracker.tscn")


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no2"):
		if chunk_slice_style == SLICE_STYLE.BLAST:
			chunk_slice_style = SLICE_STYLE.BLAST
		slice_chunk()
	if Input.is_action_just_pressed("no3"):
		chunk_slice_style = SLICE_STYLE.GRID_SQ
		slice_chunk()
	if Input.is_action_just_pressed("no4"):
		chunk_slice_style = SLICE_STYLE.GRID_HEX
		slice_chunk()
	if Input.is_action_just_pressed("no5"):
		pass
		
		
func _ready() -> void:
	
	if not chunk_polygon.empty():
		polygon = chunk_polygon	
	
	
func slice_chunk():

	match chunk_slice_style:
		SLICE_STYLE.BLAST:
			slice_polygons()
			spawn_debry(sliced_polygons)
		SLICE_STYLE.GRID_SQ:
			slicing_operations.current_grid_style = slicing_operations.GRID_STYLE.SQUARE
			sliced_polygons = slicing_operations.slice_grid(polygon)
			spawn_crack_polygons(sliced_polygons[0], Color.cornflower)	
			spawn_crack_polygons(sliced_polygons[1], Color.cornflower, false)	
		SLICE_STYLE.GRID_HEX:
			slicing_operations.current_grid_style = slicing_operations.GRID_STYLE.HEX
			sliced_polygons = slicing_operations.slice_grid(polygon)
			spawn_crack_polygons(sliced_polygons[0], Color.cornflower)	
			spawn_crack_polygons(sliced_polygons[1], Color.cornflower, false)	
	
#	color.a = 0 
#	sliced_polygons.clear()	
#	queue_free()
	

	
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
		new_polygon_points = slicing_operations.split_polygon_edge(new_polygon_points)
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
	sliced_polygons = slicing_operations.triangulate_daisy(new_polygon_points)
	
	# SIDE SLICE
	var new_sliced_polygons: Array = sliced_polygons.duplicate()
	for c in slice_side_count:
		for poly_index in sliced_polygons.size():
			sliced_polygons.append_array(slicing_operations.slice_horizontal(sliced_polygons[poly_index]))
	
	# printt("sliced", sliced_polygons.size())


# SPAWN ------------------------------------------------------------------------------------------------------------
	
		
func spawn_debry(debry_polygons: Array = sliced_polygons, new_color: Color = Color.blue):
		
	# spawnam v node, kjer je original Breaker shape ... po logiki
	var new_debry_parent = get_parent() # ni static type, ker je lahko karkoli
	if not new_debry_parent == get_tree().root:
		new_debry_parent = get_parent().get_parent().get_parent()
		
	for poly in debry_polygons:
		#		var new_debry: RigidBody2D = DebryRigid.instance()
		var new_debry: Node2D = DebryArea.instance()
		new_debry.debry_polygon = poly
		new_debry.z_index = 10 # debug
		new_debry.position += global_position
		new_debry_parent.add_child(new_debry)
		
		# printt ("new debry poly", new_debry.position, new_debry.debry_polygon[0], polygon[0], new_debry.get_parent())		
	
	color.a = 0 
	
	
func spawn_crack_polygons(cracked_polygons: Array = sliced_polygons, new_color: Color = Color.black, clear_before: bool = true):
	
	if clear_before: # debug
		while crackers_parent.get_child_count() > 0:
			crackers_parent.get_children().pop_back().queue_free()	
	
	for poly_index in cracked_polygons.size():
		var new_cracked_shape = Cracker.instance()
		new_cracked_shape.polygon = cracked_polygons[poly_index]
		new_cracked_shape.z_index = 10 # debug
		new_cracked_shape.color = new_color
		crackers_parent.add_child(new_cracked_shape)
		new_cracked_shape.get_node("EdgeLine").points = new_cracked_shape.polygon
		if cracked_polygons.size() > 1: # debug
			new_cracked_shape.color.v = randf()
	
		# printt ("new cracked poly", new_polygon2d.color, new_polygon2d.polygon[0], polygon[0])		

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
