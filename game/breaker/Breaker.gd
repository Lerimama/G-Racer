extends RigidBody2D


enum MATERIAL {WOOD, METAL, TILES, SOIL, GLASS}
export (MATERIAL) var breaker_material: int = MATERIAL.WOOD

var breaker_shape_polygon: PoolVector2Array = [] # podam ob spawnanju
onready var breaker_shape: Polygon2D = $BreakerShape
onready var slicer_shape: Polygon2D = $SlicerShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# breaking
var origin_global_position: Vector2 # se inherita skozi vse spawne
#var chunk_slicing_style: int # se inherita skozi vse spawne
onready var chunks_parent: Node2D = $Chunks
onready var Chunk: PackedScene = preload("res://game/breaker/Chunk.tscn")

# debug
var breaking_round: int = 0


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		slice_breaker(slicer_shape.polygon)


func _ready() -> void:
	
	# če ni podan spawn shape
	if not breaker_shape_polygon.empty():
		breaker_shape.polygon = breaker_shape_polygon
	collision_shape.polygon = breaker_shape.polygon
	slicer_shape.hide()


#func on_drop(drop_shape: Polygon2D, drop_position: Vector2, slicing_style: int):
#
#	origin_global_position = drop_position
#	drop_shape.polygon = match_shape_transforms(drop_shape).polygon
#	# od globalne pozicije pike odštejem globalno pozicijo breakerja
#	var drop_polygon_adapted: PoolVector2Array
#	for point in drop_shape.polygon:
#		var point_global_position: Vector2 = point * drop_shape.scale + drop_position
#		var hitting_point_position_against_object: Vector2 = point - position
#		drop_polygon_adapted.append(hitting_point_position_against_object)
#
##	var sliced_polygons: Array = slice_breaker(adapted_polygon)
#	slice_breaker(drop_polygon_adapted)
#
##	chunk_slicing_style = new_slicing_style
#	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
#	var adapted_polygon: PoolVector2Array = []
#	for point in hitting_shape.polygon:
#		# od globalne pozicije pike odštejem globalno pozicijo breakerja
#		var point_global_position: Vector2 = point * hitting_shape.scale + hit_position
#		var hitting_point_position_against_object: Vector2 = point_global_position - position
#		adapted_polygon.append(hitting_point_position_against_object)
#
##	var sliced_polygons: Array = slice_breaker(adapted_polygon)
#	if new_slicing_style == -1:
#		slice_breaker(adapted_polygon, false)
#	else:
#		slice_breaker(adapted_polygon)









func adapt_transforms_and_add_origin(shape_to_transform: Polygon2D, origin_position: Vector2): # je to origin position?
	
	shape_to_transform.polygon = match_shape_transforms(shape_to_transform).polygon
	
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var transformed_polygon: PoolVector2Array = []
	for point in shape_to_transform.polygon:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * shape_to_transform.scale + origin_position
		var hitting_point_position_against_object: Vector2 = point_global_position - position
		transformed_polygon.append(hitting_point_position_against_object)

	return transformed_polygon
	


func on_drop(drop_shape: Polygon2D, drop_global_position: Vector2, slicing_style: int):

	origin_global_position = drop_global_position
#	drop_shape.polygon = match_shape_transforms(drop_shape).polygon
#
#	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
#	var drop_polygon_adapted: PoolVector2Array = []
#	for point in drop_shape.polygon:
#		# od globalne pozicije pike odštejem globalno pozicijo breakerja
#		var point_global_position: Vector2 = point * drop_shape.scale + drop_position
#		var hitting_point_position_against_object: Vector2 = point_global_position - position
#		drop_polygon_adapted.append(hitting_point_position_against_object)

	var drop_polygon_adapted: PoolVector2Array = adapt_transforms_and_add_origin(drop_shape, drop_global_position)
	slice_breaker(drop_polygon_adapted, slicing_style)


func on_hit(hit_shape: Polygon2D, hit_vector: PoolVector2Array, slicing_style: int):
	
	# dobim origin a robu, ki ga križa hit vektor
	var hit_point: Vector2
#	var hit_edge_index: Vector2
	if hit_vector is PoolVector2Array:
		var hit_vector_start_pos_adapted_to_breaker: Vector2 = hit_vector[0] - global_position
		var hit_vector_end_pos_adapted_to_breaker: Vector2 = hit_vector[1] - global_position
		var hit_vector_pool_adapted: PoolVector2Array = [hit_vector_start_pos_adapted_to_breaker, hit_vector_end_pos_adapted_to_breaker]
		
		hit_vector = hit_vector_pool_adapted
		
		
		var poly: PoolVector2Array = breaker_shape.polygon
		
		# za vsak rob preverim, če ga seka hit vektor
		for edge_index in poly.size():
			var edge: PoolVector2Array
			if edge_index == poly.size() - 1:
				edge = [poly[edge_index], poly[0]]
			else:
				edge = [poly[edge_index], poly[edge_index + 1]]
			var intersection_point = Geometry.segment_intersects_segment_2d(hit_vector[0],hit_vector[1],edge[0], edge[1])
			if intersection_point:
				hit_point = intersection_point
				break
			
	var hit_global_position: Vector2 = hit_point + global_position			
	origin_global_position = hit_global_position
	
	var indi = Met.spawn_indikator(hit_global_position)
	indi.scale *= 10
	indi.modulate = Color.blue
	var ind = Met.spawn_indikator(hit_vector[0] + global_position)
	ind.scale *= 10
	ind.modulate = Color.yellow
		
		
#	hit_shape.polygon = match_shape_transforms(hit_shape).polygon
#	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
#	var adapted_polygon: PoolVector2Array = []
#	for point in hit_shape.polygon:
#		# od globalne pozicije pike odštejem globalno pozicijo breakerja
#		var point_global_position: Vector2 = point * hit_shape.scale + hit_position
#		var hitting_point_position_against_object: Vector2 = point_global_position - position
#		adapted_polygon.append(hitting_point_position_against_object)

	var hit_polygon_adapted: PoolVector2Array = adapt_transforms_and_add_origin(hit_shape, hit_global_position)

	slice_breaker(hit_polygon_adapted, slicing_style)
	
	
# OPERATIONS ----------------------------------------------------------------------------------
	
	
func slice_breaker(slicing_polygon: PoolVector2Array, slicing_style: int = 0):
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, slicing_polygon)
	# prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	
	# intersektam, da dobim chunk template
	var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_shape.polygon)
	
	if interecting_polygons.empty():
		print("intersection empty")
		
	break_apart(clipped_polygons, interecting_polygons, slicing_style)	
	#	return [clipped_polygons, interecting_polygons]
	
	
func break_apart(clipped_breaker_polygons: Array, interecting_base_polygons: Array, slicing_style: int = 0):
	
	# če ga prekrije, razpade celoten shape
	if clipped_breaker_polygons.empty():
		spawn_chunk(breaker_shape.polygon)
		breaker_shape.hide()
	
	# če ne razade na chunk in morebitne nove breaking objekte
	else:	
		# shape adapt
		breaker_shape.hide()
		breaker_shape.polygon = clipped_breaker_polygons.pop_front()
#		breaker_shape.color = Color.purple
		collision_shape.polygon = breaker_shape.polygon
		breaker_shape.show()
		
		# luknja ali novi breaking object
		for poly in clipped_breaker_polygons:
			if Geometry.is_polygon_clockwise(poly): # luknja ... splitam glavni poligon
				apply_hole(poly)
				return
			else:
				spawn_new_breaker(poly, Color.green)
		
		# chunks
		if not slicing_style == 0:
			for chunk in chunks_parent.get_children(): # debug, dokler ne bo animirano
				chunk.queue_free()
			for poly_index in interecting_base_polygons.size(): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				var chunk_template: PoolVector2Array = interecting_base_polygons[poly_index]
				spawn_chunk(chunk_template)
	
	breaking_round += 1 
	
	
func spawn_chunk(template_polygon: PoolVector2Array):
	
	var new_broken_chunk: Polygon2D = Chunk.instance()
	new_broken_chunk.chunk_polygon = template_polygon
	new_broken_chunk.name = "Chunk_R%s" % str(breaking_round)
	new_broken_chunk.color = Color.red
	new_broken_chunk.modulate.a = 0.2
	new_broken_chunk.origin_global_position = origin_global_position
	chunks_parent.add_child(new_broken_chunk)
	
	# printt("new chunk", new_broken_chunk, new_broken_chunk.position)
		
		
func spawn_new_breaker(polygon_points: PoolVector2Array, new_color: Color = Color.red):
	
	var new_breaker = duplicate()
	new_breaker.breaker_shape_polygon = polygon_points
	new_breaker.name = "Breaker_R%s" % str(breaking_round)
	get_parent().add_child(new_breaker)
	
	new_breaker.breaker_shape.color = new_color
	for chunk in chunks_parent.get_children():
		chunk.queue_free()
	
	# printt("new breaking obj", new_breaker, new_breaker.position, new_breaker.get_parent())


func match_shape_transforms(shape_to_transform: Polygon2D):
	
	if shape_to_transform.transform != Transform2D.IDENTITY: 
		# The identity Transform2D with no translation, rotation or scaling applied. 
		# When applied to other data structures, IDENTITY performs no transformation.
		var transformed_polygon = shape_to_transform.transform.xform(shape_to_transform.polygon)
		shape_to_transform.transform = Transform2D.IDENTITY
		shape_to_transform.polygon = transformed_polygon	
	
	return shape_to_transform


func apply_hole(hole_polygon: PoolVector2Array):
	# poiščem rob (s točko), ki je najbližje od enega od robov
	# shape splitam med najbližjo točko na izbranem robu in centrom luknje
	# ponovno slajsam novi shape
	
	# za vsako stranico shape polija preverim od slicer točk je najbliža in jo zapišem
	var distance_to_closest_point: float = 0
	var split_point_on_hole: Vector2 # za primer, če sredina oblike ni v poligonu
	var split_edge_start_index: int = 0
	var split_edge_vector: Vector2
	var closest_point_on_edge: Vector2
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
				closest_point_on_edge = closest_point
				split_edge_start_index = point_index
				split_edge_vector = end_point - start_point
				distance_to_closest_point = distance_between_points
				split_point_on_hole = point
				
	# split points polygon
	var split_shape_polygon: PoolVector2Array = breaker_shape.polygon
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
	breaker_shape.polygon = split_shape_polygon
	slice_breaker(hole_polygon)
	
