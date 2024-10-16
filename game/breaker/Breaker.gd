extends RigidBody2D


var shape_poly_points: PoolVector2Array = [] # če podam ob spawnanju, se aplicira na glavno obliko

onready var breaker_shape: Polygon2D = $BreakerShape
onready var slicing_shape: Polygon2D = $SlicingShape
onready var breaker_parent = get_parent() # ni static, ker je lahko karkoli
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var chunks_parent: Node2D = $Chunks

var BrokenChunk: PackedScene = preload("res://game/breaker/BrokenChunk.tscn")
var break_origin_global_position: Vector2


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		slicing_shape.polygon = match_shape_transforms(slicing_shape).polygon
		slice_shape(slicing_shape.polygon)
		slicing_shape.hide()	
		
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
		breaker_shape.polygon = shape_poly_points
	collision_shape.polygon = breaker_shape.polygon
	slicing_shape.hide()

	
func on_hit(hitting_shape: Polygon2D, hit_position: Vector2):
	
	break_origin_global_position = hit_position
	hitting_shape.polygon = match_shape_transforms(hitting_shape).polygon
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var adapted_polygon: PoolVector2Array = []
	for point in hitting_shape.polygon:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * hitting_shape.scale + hit_position
		var hitting_point_position_against_breaker: Vector2 = point_global_position - position
		adapted_polygon.append(hitting_point_position_against_breaker)
	
	slice_shape(adapted_polygon)
	
	
# OPERATIONS ---------------------------------------------------------------------------------------------------
	
	
func slice_shape(cutting_polygon: PoolVector2Array):
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, cutting_polygon)
	
	# intersektam, da dobim chunk template
	var interecting_polygons: Array = Geometry.intersect_polygons_2d(cutting_polygon, breaker_shape.polygon)
	if interecting_polygons.empty():
		print("intersection empty")
		return []
		
	break_apart(clipped_polygons, interecting_polygons)
	
	
func break_apart(clipped_base_polygons: Array, interecting_base_polygons: Array):
	
	# če ga prekrije, razpade celoten shape
	if clipped_base_polygons.empty():
		spawn_broken_chunk(breaker_shape.polygon)
		breaker_shape.hide()
	else:	
		# shape adapt
		breaker_shape.hide()
		breaker_shape.polygon = clipped_base_polygons.pop_front()
		breaker_shape.color = Color.purple
		collision_shape.polygon = breaker_shape.polygon
		breaker_shape.show()
		# luknja ali ostanek
		for poly in clipped_base_polygons:
			if Geometry.is_polygon_clockwise(poly): # luknja ... glavni splitam poligon
				apply_hole(poly)
				return
			else: # new breakers
				spawn_new_breaker(poly, Color.green)
		# chunks
		reset_breaker() # debug
		for poly_index in interecting_base_polygons.size(): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
			var chunk_template: PoolVector2Array = interecting_base_polygons[poly_index]
			spawn_broken_chunk(chunk_template)
		

func apply_hole(hole_polygon: PoolVector2Array):
	# poiščem rob (s točko), ki je najbližje od enega od robov
	# shape splitam med najbližjo točko na izbranem robu in centrom luknje
	# ponovno slajsam novi shape
	
	# za vsako stranico shape polija preverim od slicer točk je najbliža in jo zapišem
	var distance_to_closest_point: float = 0
	var split_point_on_hole: Vector2 # za primer, če sredina oblike ni v poligonu
	var split_segment_start_index: int = 0
	var split_segment_vector: Vector2
	var closest_point_on_segment: Vector2
	var shape_polygon: PoolVector2Array = breaker_shape.polygon
	for point_index in shape_polygon.size():
		var start_point: Vector2 = shape_polygon[point_index]
		var end_point: Vector2
		if point_index < shape_polygon.size() - 1:
			end_point = breaker_shape.polygon[point_index + 1]
		else:
			end_point = breaker_shape.polygon[0]
		# za vsako točko na luknji preverim katera ja najdle enemu od robov shape
		for point in hole_polygon:
			var closest_point: Vector2 = Geometry.get_closest_point_to_segment_2d(point, start_point, end_point)
			var distance_between_points: float = (point - closest_point).length()
			# najbližja
			if distance_between_points < distance_to_closest_point or distance_to_closest_point == 0:
				closest_point_on_segment = closest_point
				split_segment_start_index = point_index
				split_segment_vector = end_point - start_point
				distance_to_closest_point = distance_between_points
				split_point_on_hole = point
				
	# split points polygon
	var split_shape_polygon: PoolVector2Array = breaker_shape.polygon
	# split point
	split_shape_polygon.insert(split_segment_start_index + 1, closest_point_on_segment)
	# hole center
	var hole_center: Vector2 = Vector2.ZERO
	for point in hole_polygon:
		hole_center += point
	hole_center /= hole_polygon.size()
	# če center ni v poligonu, povlečem do referenčne točke najbolj oddaljena točke
	if Geometry.is_point_in_polygon(hole_center, split_shape_polygon):
		split_point_on_hole = hole_center
	split_shape_polygon.insert(split_segment_start_index + 2, split_point_on_hole) # sredinska hole točka lahko ni v luknji
	# offset split point
	var split_offset: Vector2 = (Vector2.RIGHT * 0.01).rotated(split_segment_vector.angle())
	split_shape_polygon.insert(split_segment_start_index + 3, closest_point_on_segment + split_offset) # prvo shape split točko
	
	# apliciram na shape
	breaker_shape.polygon = split_shape_polygon
	slice_shape(hole_polygon)
	
	
func spawn_broken_chunk(template_polygon: PoolVector2Array):
	
	var new_broken_chunk: Polygon2D = BrokenChunk.instance()
	new_broken_chunk.shape_polygon = template_polygon
	new_broken_chunk.slice_origin_global_position = break_origin_global_position
	new_broken_chunk.color = Color.red
	new_broken_chunk.modulate.a = 0.2
	chunks_parent.add_child(new_broken_chunk)
	
	printt("new chunk", new_broken_chunk, new_broken_chunk.position)
		
		
func spawn_new_breaker(polygon_points: PoolVector2Array, new_color: Color = Color.red):
	
	var new_breaker = duplicate()
	new_breaker.shape_poly_points = polygon_points
	new_breaker.name = "Breaker"
	breaker_parent.add_child(new_breaker)
	
	new_breaker.breaker_shape.color = new_color
	new_breaker.reset_breaker()
	
	printt("new breaker", new_breaker, new_breaker.position, new_breaker.get_parent())


func reset_breaker():
	
	var current_chunks: Array = chunks_parent.get_children()
	for chunk in current_chunks:
		chunk.queue_free()


func match_shape_transforms(shape_to_transform: Polygon2D):
	
	if shape_to_transform.transform != Transform2D.IDENTITY: 
		# The identity Transform2D with no translation, rotation or scaling applied. 
		# When applied to other data structures, IDENTITY performs no transformation.
		var transformed_polygon = shape_to_transform.transform.xform(shape_to_transform.polygon)
		shape_to_transform.transform = Transform2D.IDENTITY
		shape_to_transform.polygon = transformed_polygon	
	
	return shape_to_transform
