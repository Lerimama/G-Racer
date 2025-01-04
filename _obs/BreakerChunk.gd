extends Polygon2D
# slice je zarezovanje
# split je dajanje narazen

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS}
var chunk_slice_style: int = SLICE_STYLE.BLAST #setget _change_slice_style

var chunk_polygon: PoolVector2Array = [] # ob spawnu
enum ORIGIN_LOCATION {INSIDE, EDGE, OUTSIDE}
var current_origin_location: int = ORIGIN_LOCATION.INSIDE

var origin_on_edge: bool = false # sam preverja, če je bil origina na robu
var origin_global_position: Vector2 # na spawn
var sliced_polygons: Array = [] # _temp

onready var operator: Node = $Operator
onready var debry_parent: Node # na spawn
onready var crackers_parent: Node2D = $Crackers
onready var Cracker: PackedScene = preload("res://breaker/Cracker.tscn")
onready var BreakerRigid: PackedScene = load("res://breaker/BreakerRigid.tscn")
onready var BreakerArea: PackedScene = load("res://breaker/BreakerArea.tscn")


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no2"):
		chunk_slice_style = SLICE_STYLE.BLAST
		slice_chunk()


func _ready() -> void:

	if not chunk_polygon.empty():
		polygon = chunk_polygon


func slice_chunk():

	match chunk_slice_style:
		SLICE_STYLE.BLAST:
#			var new_sliced_polygon = slice_polygons()
#			spawn_debry(new_sliced_polygon)
			slice_chunk()
			spawn_debry(sliced_polygons)
		SLICE_STYLE.GRID_SQ:
			var grid_sliced_polygons = operator.split_grid(polygon, 4)
			spawn_crackers(grid_sliced_polygons[0], Color.cornflower)
			spawn_crackers(grid_sliced_polygons[1], Color.cornflower)
		SLICE_STYLE.GRID_HEX:
			var grid_sliced_polygons = operator.split_grid(polygon, 6)
			spawn_crackers(grid_sliced_polygons[0], Color.cornflower)
			spawn_crackers(grid_sliced_polygons[1], Color.cornflower, false)
	queue_free()

	#	color.a = 0
	#	sliced_polygons.clear()
	#	queue_free()


func slice_polygons():

	var origin_position: Vector2 = origin_global_position - global_position
	var polygon_to_slice: PoolVector2Array = polygon
	var origin_edge_index: int

	# preverjam origin lokacijo znotraj vs zunaj
	if Geometry.is_point_in_polygon(origin_position, chunk_polygon):
		current_origin_location = ORIGIN_LOCATION.INSIDE
		# on edge?
		for edge_index in polygon_to_slice.size():
			var edge: PoolVector2Array = []
			if edge_index == polygon_to_slice.size() - 1:
				edge = [polygon_to_slice[edge_index], polygon_to_slice[0], polygon_to_slice[edge_index]] # FINTA ... pseudo trikotnik s podvajanjem ene od točk
			else:
				edge = [polygon_to_slice[edge_index], polygon_to_slice[edge_index + 1], polygon_to_slice[edge_index]] # FINTA
			if Geometry.is_point_in_polygon(origin_position, edge):
				origin_edge_index = edge_index
				current_origin_location = ORIGIN_LOCATION.EDGE
				break
	else:
		current_origin_location = ORIGIN_LOCATION.OUTSIDE


	# FROM EDGE
	printt ("slice on origin location:", ORIGIN_LOCATION.keys()[current_origin_location])
	match current_origin_location:
		ORIGIN_LOCATION.INSIDE:
			var split_edge_length: int = 150
			polygon_to_slice = operator.split_outline_to_length(polygon_to_slice, split_edge_length)
			sliced_polygons = operator.split_spiderweb(polygon_to_slice)
		ORIGIN_LOCATION.EDGE:
			# outline split
			var split_edge_length: int = 50
			polygon_to_slice = operator.split_outline_to_length(polygon_to_slice, split_edge_length)
			#		var split_count: int = 1 # _temp
			#		polygon_to_slice = operator.split_outline_on_part(polygon_to_slice, 0.5, split_count)
			# odstranim splitane pike na origin robu
			var origin_edge_end_point_index: int
			if origin_edge_index == polygon_to_slice.size() - 1:
				origin_edge_end_point_index = 0
			else:
				origin_edge_end_point_index = origin_edge_index + 1
			for point_index in polygon_to_slice.size():
				if point_index > origin_edge_index and point_index < origin_edge_end_point_index:
					polygon_to_slice.remove(point_index)
			# vstavim origin point
			polygon_to_slice.insert(origin_edge_index + 1, origin_position)
			# slajsam
			var origin_point_index: int = polygon_to_slice.find(origin_position)
			sliced_polygons = operator.split_daisy(polygon_to_slice, origin_point_index)[0]
		ORIGIN_LOCATION.OUTSIDE:
			# ostranim trikotnike, ki segajo preko roba
			pass


# SPAWN ------------------------------------------------------------------------------------------------------------


func spawn_debry(debry_polygons: Array, new_color: Color = Color.white):

	if not debry_parent:
		debry_parent = get_tree().root # debug ... spawn parents

	print("spawning debry")
	for poly in debry_polygons:

		# centraliziram in globaliziram
		var centralized_spawn_position: Vector2 = position
		var centralized_poly: Array = centralize_polygon(poly)
		poly = centralized_poly[0]
		centralized_spawn_position = centralized_poly[1]

		var new_breaker = BreakerRigid.instance()
#		var new_breaker = BreakerArea.instance()
		new_breaker.name = "Breaker_Debry"
		new_breaker.spawn_breaker_shape_polygon = poly
		new_breaker.position = centralized_spawn_position
		new_breaker.z_index = 10 # debug
		new_breaker.origin_global_position = origin_global_position
		debry_parent.add_child(new_breaker)


		new_breaker.breaker_shape.color = Color.pink
		new_breaker.current_material = new_breaker.MATERIAL.UNBREAKABLE
		new_breaker.current_motion = new_breaker.MOTION.EXPLODE
		# printt ("new debry poly", new_debry.position, new_debry.debry_polygon[0], polygon[0], new_debry.get_parent())
	color.a = 0


func spawn_crackers(cracked_polygons: Array, new_color: Color = Color.black, clear_before: bool = true):

	if clear_before: # debug
		while crackers_parent.get_child_count() > 0:
			crackers_parent.get_children().pop_back().queue_free()

	for poly_index in cracked_polygons.size():
		var new_cracked_shape = Cracker.instance()
		new_cracked_shape.name = "%s_Crackers" % name
		new_cracked_shape.polygon = cracked_polygons[poly_index]
		new_cracked_shape.z_index = 10 # debug
		new_cracked_shape.color = new_color
		crackers_parent.add_child(new_cracked_shape)
		new_cracked_shape.get_node("EdgeLine").points = new_cracked_shape.polygon
		randomize()
		if cracked_polygons.size() > 1: # debug
			new_cracked_shape.color.v = randf()

		# printt ("new cracked poly", new_polygon2d.color, new_polygon2d.polygon[0], polygon[0])

	color.a = 0


func centralize_polygon(polygon_points: PoolVector2Array):
	# pre: spawned pozicija je enaka breakerjev, potem pa je notranji poligon zamaknjen
	# post: spawned pozicija je v središču spawnanega nodeta (tudi središče notranjega poligona)

	var chunk_center = operator.get_polygon_center(polygon_points)# + def_chunk_global_pos

	var moved_polygon_points: PoolVector2Array = []
	for point in polygon_points:
		var moved_point = point - chunk_center# + global_position
		moved_polygon_points.append(moved_point)

	return [moved_polygon_points, chunk_center + global_position]
