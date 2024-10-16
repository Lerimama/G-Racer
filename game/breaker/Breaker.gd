extends RigidBody2D


var shape_poly_points: PoolVector2Array = [] # če podam ob spawnanju, se aplicira na glavno obliko

onready var shape_poly: Polygon2D = $ShapePoly
onready var slicing_poly: Polygon2D = $CuttingPoly
onready var breaker_parent = get_parent() # ni static, ker je lahko karkoli
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

var BrokenChunk: PackedScene = preload("res://game/breaker/BrokenChunk.tscn")


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		on_press()
	if Input.is_action_just_pressed("no2"):
		pass
	if Input.is_action_just_pressed("no3"):
		pass
	if Input.is_action_just_pressed("no4"):
		pass
	if Input.is_action_just_pressed("no5"):
		pass


func _ready() -> void:
	
	# če ni podan spawn shape
	if not shape_poly_points.empty():
		shape_poly.polygon = shape_poly_points
	collision_shape.polygon = shape_poly.polygon
	slicing_poly.hide()


func on_hit(hitting_poly: Polygon2D, hit_position: Vector2):
	
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var adapted_polygon: PoolVector2Array = []
	for point in hitting_poly.polygon:
		# od globalne pozicije pike odtejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * hitting_poly.scale + hit_position
		var hitting_point_position_against_breaker: Vector2 = point_global_position - position
		
		adapted_polygon.append(hitting_point_position_against_breaker)
	
	slice_shape(adapted_polygon)
	
	
func on_press():
	
	# zamaknem točke glede nanjegov zamik
	# če še nima transform id (pozicije točk glede na lastno pozicjo	
	if slicing_poly.transform != Transform2D.IDENTITY:
		# The identity Transform2D with no translation, rotation or scaling applied. 
		# When applied to other data structures, IDENTITY performs no transformation.
		var transformed_polygon = slicing_poly.transform.xform(slicing_poly.polygon)
		slicing_poly.transform = Transform2D.IDENTITY
		slicing_poly.polygon = transformed_polygon	
	
	slice_shape(slicing_poly.polygon)
	slicing_poly.hide()	
	
	
func slice_shape(cutting_polygon: PoolVector2Array):
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(shape_poly.polygon, cutting_polygon)
	
	# če ga prekrije, razpade celoten shape
	if clipped_polygons.empty():
		print ("prekriva")
		spawn_chunk(shape_poly.polygon)
		shape_poly.hide()
#		queue_free()
	else:
		# intersektam, da dobim chunk template
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(cutting_polygon, shape_poly.polygon)
		if interecting_polygons.empty():
			print("intersection empty")
			return []
		break_apart(clipped_polygons, interecting_polygons)
	
	
func break_apart(clipped_base_polygons: Array, interecting_base_polygons: Array):	
	
	# shape adapt
	shape_poly.hide()
	shape_poly.polygon = clipped_base_polygons.pop_front()
	shape_poly.color = Color.purple
	collision_shape.polygon = shape_poly.polygon
	shape_poly.show()
	
	# shape leftovers
	for poly in clipped_base_polygons:
		if Geometry.is_polygon_clockwise(poly): # luknja ... glavni splitam poligon
			split_shape_with_hole(poly)
			return
		else: # new breakers
			spawn_new_breaker(poly, Color.green)
	
	# chunks
	for poly_index in len(interecting_base_polygons): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
		var chunk_template: PoolVector2Array = interecting_base_polygons[poly_index]
		spawn_chunk(chunk_template)


func split_shape_with_hole(hole_polygon: PoolVector2Array):
	# poiščem rob (s točko), ki je najbližje od enega od robov
	# shape splitam med najbližjo točko na izbranem robu in centrom luknje
	# ponovno slajsam novi shape
	
	# za vsako stranico shape polija preverim od slicer točk je najbliža in jo zapišem
	var distance_to_closest_point: float = 0
	var split_segment_start_index: int = 0
	var split_segment_vector: Vector2
	var split_point_on_segment: Vector2
	var shape_polygon: PoolVector2Array = shape_poly.polygon
	for point_index in shape_polygon.size():
		var start_point: Vector2 = shape_polygon[point_index]
		var end_point: Vector2
		if point_index < shape_polygon.size() - 1:
			end_point = shape_poly.polygon[point_index + 1]
		else:
			end_point = shape_poly.polygon[0]
		# za vsako točko na luknji preverim katera ja najdle enemu od robov shape
		for point in hole_polygon:
			var closest_point: Vector2 = Geometry.get_closest_point_to_segment_2d(point, start_point, end_point)
			var distance_between_points: float = (point - closest_point).length()
			if distance_between_points < distance_to_closest_point or distance_to_closest_point == 0:
				split_point_on_segment = closest_point
				split_segment_start_index = point_index
				split_segment_vector = end_point - start_point
				distance_to_closest_point = distance_between_points
	
	# split points polygon
	var split_shape_polygon: PoolVector2Array = shape_poly.polygon
	# split point
	split_shape_polygon.insert(split_segment_start_index + 1, split_point_on_segment)
	# hole center
	var hole_center: Vector2
	for point in hole_polygon:
		hole_center += point
	hole_center /= hole_polygon.size()
	split_shape_polygon.insert(split_segment_start_index + 2, hole_center) # sredinska hole točko
	# offset split point
	var split_offset: Vector2 = Vector2(0, 0.001).rotated(split_segment_vector.angle())
	split_shape_polygon.insert(split_segment_start_index + 3, split_point_on_segment + split_offset) # prvo shape split točko
	
	# apliciram na shape
	shape_poly.polygon = split_shape_polygon
	slice_shape(hole_polygon)
	
onready var chunks: Node2D = $Chunks
	
func spawn_chunk(template_polygon: PoolVector2Array):
	
	var new_broken_chunk: Polygon2D = BrokenChunk.instance()
	new_broken_chunk.shape_polygon = template_polygon
	new_broken_chunk.color = Color.red
	new_broken_chunk.modulate.a = 0.2
	chunks.add_child(new_broken_chunk)
	
	#	printt("new chunk", new_broken_chunk, new_broken_chunk.position)
		
		
func spawn_new_breaker(polygon_points: PoolVector2Array, new_color: Color = Color.red, new_name: String = "", spawn_parent = self):
	
	#	var NewBreaker: PackedScene = preload("res://game/breaker/Breaker.tscn")
	#	var new_splitting_shape = NewBreaker.instance()
	var new_breaker = duplicate()
	new_breaker.shape_poly_points = polygon_points
	if not new_name.empty():
		new_breaker.name = new_name
	breaker_parent.add_child(new_breaker)
	new_breaker.shape_poly.color = new_color
	
	# reset
	for chunk in new_breaker.chunks.get_children():
		chunk.queue_free()
#	while .get_child_count() > 0:
#		new_breaker.chunks.get_children().pop_back().queue_free()
		
	
	#	printt("new breaker", new_breaker, new_breaker.position, new_breaker.get_parent())
	
