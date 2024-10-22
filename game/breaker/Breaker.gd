extends RigidBody2D


enum MATERIAL {WOOD, METAL, TILES, SOIL, GLASS}
export (MATERIAL) var breaker_material: int = MATERIAL.WOOD

var spawn_breaker_shape_polygon: PoolVector2Array = [] # podam ob spawnanju
onready var breaker_shape: Polygon2D = $BreakerShape
onready var slicer_shape: Polygon2D = $SlicerShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# breaking
var origin_global_position: Vector2 # se inherita skozi vse spawne
#var chunk_slicing_style: int # se inherita skozi vse spawne
onready var breaker_chunks_parent: Node2D = $Chunks
onready var BreakerChunk: PackedScene = preload("res://game/breaker/BreakerChunk.tscn")

# debug
var breaking_round: int = 0


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		break_breaker(slicer_shape.polygon)
	if Input.is_action_just_pressed("no2"):
		breaker_shape.polygon = collision_shape.polygon


func _ready() -> void:
	
	# če ni podan spawn shape
	if not spawn_breaker_shape_polygon.empty():
		breaker_shape.polygon = spawn_breaker_shape_polygon
	collision_shape.polygon = breaker_shape.polygon
	slicer_shape.hide()


func on_hit(hit_shape: Object, hit_vector = null, slicing_style: int = 0):
	
	var hit_global_position: Vector2
	# cut
	if hit_vector == null: 
		cut_breaker(hit_shape, 0)
	# break
	else:
		# smack
		if hit_vector is PoolVector2Array: 
			# dobim origin na robu, ki ga križa hit vektor
			var hit_point: Vector2
			if hit_vector is PoolVector2Array:
				# hit vektor je pika začetka in pika kontakta
				var hit_vector_start_pos_adapted_to_breaker: Vector2 = hit_vector[0] - global_position
				var hit_vector_end_pos_adapted_to_breaker: Vector2 = hit_vector[1] - global_position
				var hit_vector_pool_adapted: PoolVector2Array = [hit_vector_start_pos_adapted_to_breaker, hit_vector_end_pos_adapted_to_breaker]
				hit_vector = hit_vector_pool_adapted
				# za vsak rob preverim, če ga seka hit vektor
				var outline_poly: PoolVector2Array = breaker_shape.polygon
				for edge_index in outline_poly.size():
					var edge: PoolVector2Array
					if edge_index == outline_poly.size() - 1:
						edge = [outline_poly[edge_index], outline_poly[0]]
					else:
						edge = [outline_poly[edge_index], outline_poly[edge_index + 1]]
					var intersection_point = Geometry.segment_intersects_segment_2d(hit_vector[0],hit_vector[1],edge[0], edge[1])
					if intersection_point:
						hit_point = intersection_point
						break
			hit_global_position = hit_point + global_position			
			# debug ... indi
			var indi = Met.spawn_indikator(hit_global_position)
			indi.scale *= 10
			indi.modulate = Color.blue
			var ind = Met.spawn_indikator(hit_vector[0] + global_position)
			ind.scale *= 10
			ind.modulate = Color.yellow			
		# drop
		elif hit_vector is Vector2:
			print("breakam")
			hit_global_position = hit_vector
		origin_global_position = hit_global_position
		var transformed_hit_polygon: PoolVector2Array = adapt_transforms_and_add_origin(hit_shape, hit_global_position)
		break_breaker(transformed_hit_polygon, slicing_style)
		



	
func cut_breaker(slice_line: Line2D, slicing_style: int):

	# poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var slicing_line_adapted: PoolVector2Array = []
	for point in slice_line.points:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_to_local_position: Vector2 = point - position
		slicing_line_adapted.append(point_to_local_position)
	
	# preverim, če je cut šel skozi
	var cut_is_successful: bool = true
	for point in [slicing_line_adapted[0], slicing_line_adapted[slicing_line_adapted.size()-1]]:
		if Geometry.is_point_in_polygon(point, breaker_shape.polygon):
			cut_is_successful = false
			return
	
	# odebelim linijo
	var split_line_offset: float = 2
	var fat_split_line: PoolVector2Array = Geometry.offset_polyline_2d(slicing_line_adapted, split_line_offset)[0]
	
	# A cela linija
	var outline_polygon: PoolVector2Array = breaker_shape.polygon

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(outline_polygon, fat_split_line)
	
	# odstranim morebitne dvojnike
	for poly in clipped_polygons:
		spawn_new_breaker(poly, Color.red * (clipped_polygons.find(poly)*10 + 1))
	queue_free()
	
	
	
# OPERATIONS ----------------------------------------------------------------------------------
	
	
func break_breaker(slicing_polygon: PoolVector2Array, slicing_style: int = 0):
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko
	
	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	# intersektam, da dobim chunk template
	var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_shape.polygon)
	if interecting_polygons.empty():
		print("intersection empty")
	
	# _temp	
	var clipped_breaker_polygons = clipped_polygons
	var interecting_base_polygons = interecting_polygons
	#	break_apart(clipped_polygons, interecting_polygons, slicing_style)	
	#	#	return [clipped_polygons, interecting_polygons]
	#func break_apart(clipped_breaker_polygons: Array, interecting_base_polygons: Array, slicing_style: int = 0):
	
	# brejkanje
	# če ga prekrije ... celoten shape je chunk
	if clipped_breaker_polygons.empty():
		spawn_breaker_chunk(breaker_shape.polygon)
		breaker_shape.hide()
	# če ne > chunks & new breakers
	else:	
		# shape adapt
		breaker_shape.polygon = clipped_breaker_polygons.pop_front()
		collision_shape.polygon = breaker_shape.polygon
		
		# luknja ali novi breaking object
		for poly in clipped_breaker_polygons:
			if Geometry.is_polygon_clockwise(poly): # luknja ... splitam glavni poligon
				apply_hole(poly)
				return
			else:
				spawn_new_breaker(poly, Color.green)
		# chunks
		if not slicing_style == 0:
			for chunk in breaker_chunks_parent.get_children(): # debug, dokler ne bo animirano
				chunk.queue_free()
			for poly_index in interecting_base_polygons.size(): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				spawn_breaker_chunk(interecting_base_polygons[poly_index])
	breaking_round += 1 
	
	
func spawn_breaker_chunk(template_polygon: PoolVector2Array):
	
	var new_breaker_chunk: Polygon2D = BreakerChunk.instance()
	new_breaker_chunk.chunk_polygon = template_polygon
	new_breaker_chunk.name = "Chunk_R%s" % str(breaking_round)
	new_breaker_chunk.color = Color.red
	new_breaker_chunk.modulate.a = 0.2
	new_breaker_chunk.origin_global_position = origin_global_position
	breaker_chunks_parent.add_child(new_breaker_chunk)
#	new_breaker_chunk.position += position
#	get_parent().add_child(new_breaker_chunk)
	
	# printt("new chunk", new_breaker_chunk, new_breaker_chunk.position)
		
		
func spawn_new_breaker(polygon_points: PoolVector2Array, new_color: Color = Color.red):
	
	var new_breaker = duplicate()
	new_breaker.spawn_breaker_shape_polygon = polygon_points
	new_breaker.name = "Breaker_R%s" % str(breaking_round)
	get_parent().add_child(new_breaker)
	
	new_breaker.breaker_shape.color = new_color
	new_breaker.modulate.a = 0.5
	
	# reset
#	new_breaker.collision_shape.disabled = true # _temp
	for chunk in breaker_chunks_parent.get_children():
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
	break_breaker(hole_polygon)
	

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


