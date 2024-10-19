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


func on_hit(hitting_shape: Polygon2D, hit_vector, new_slicing_style: int):
#func on_hit(hitting_shape: Polygon2D, hit_vector: Vector2, new_slicing_style: int):
	
	# dobim origin a robu, ki ga križa hit vektor
	var hit_position: Vector2
	if hit_vector is PoolVector2Array:
		var interline = Geometry.clip_polyline_with_polygon_2d(hit_vector, breaker_shape.polygon)
#		var interline = Geometry.intersect_polyline_with_polygon_2d(hit_vector, breaker_shape.polygon)
		printt("INTERLINE",interline)
		var ind = Met.spawn_indikator(interline[0][0])
		ind.scale *= 10
		ind.modulate = Color.yellow
		var indi = Met.spawn_indikator(interline[0][1], false)
		indi.scale *= 10
		indi.modulate = Color.blue
	elif hit_vector is Vector2:
		hit_position = hit_vector #_temp
		
#	chunk_slicing_style = new_slicing_style
	origin_global_position = hit_position
	hitting_shape.polygon = match_shape_transforms(hitting_shape).polygon
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var adapted_polygon: PoolVector2Array = []
	for point in hitting_shape.polygon:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * hitting_shape.scale + hit_position
		var hitting_point_position_against_object: Vector2 = point_global_position - position
		adapted_polygon.append(hitting_point_position_against_object)

#	var sliced_polygons: Array = slice_breaker(adapted_polygon)
	if new_slicing_style == -1:
		slice_breaker(adapted_polygon, false)
	else:
		slice_breaker(adapted_polygon)
	
	
# OPERATIONS ----------------------------------------------------------------------------------
	
	
func slice_breaker(slicing_polygon: PoolVector2Array, spawn_chunks: bool = true):
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, slicing_polygon)
	# prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	
	# intersektam, da dobim chunk template
	var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_shape.polygon)
	if interecting_polygons.empty():
		print("intersection empty")
		
	break_apart(clipped_polygons, interecting_polygons, spawn_chunks)	
	#	return [clipped_polygons, interecting_polygons]
	
	
func break_apart(clipped_breaker_polygons: Array, interecting_base_polygons: Array, spawn_chunks: bool = true):
	
	# če ga prekrije, razpade celoten shape
	if clipped_breaker_polygons.empty():
		spawn_chunk(breaker_shape.polygon)
		breaker_shape.hide()
	
	# če ne razade na chunk in morebitne nove breaking objekte
	else:	
		# shape adapt
		breaker_shape.hide()
		breaker_shape.polygon = clipped_breaker_polygons.pop_front()
		breaker_shape.color = Color.purple
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
		if spawn_chunks:
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
			var closest_point: Vector2 = Geometry.get_closest_point_to_edge_2d(point, start_point, end_point)
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
	
