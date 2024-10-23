extends RigidBody2D

enum MOTION {STILL, EXPLODE, FALL, SLIDE, SHATTER, DISSOLVE, DISINTEGRATE}
var current_motion: int = MOTION.STILL setget move_it

enum MATERIAL {UNBREAKABLE, GHOST, WOOD, METAL, TILES, SOIL, GLASS}
export (MATERIAL) var current_material: int = MATERIAL.WOOD

var spawn_breaker_shape_polygon: PoolVector2Array = [] # podam ob spawnanju
onready var breaker_parent: Node = get_parent()
onready var breaker_shape: Polygon2D = $BreakerShape
onready var broken_shape: Polygon2D = $BrokenShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# breaking
var origin_global_position: Vector2 # se inherita skozi vse spawne
onready var breaker_chunks_parent: Node2D = $Chunks
onready var BreakerChunk: PackedScene = preload("res://game/breaker/BreakerChunk.tscn")
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var BreakerRigid: PackedScene = load("res://game/breaker/BreakerRigid.tscn")
onready var BreakerArea: PackedScene = load("res://game/breaker/BreakerArea.tscn")

# moving
var breaker_velocity: Vector2 = Vector2.ZERO


# debug
var breaking_round: int = 0
onready var animator: Node = $Animator

func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		on_hit(broken_shape, $Position2D.position, 1)

	if Input.is_action_just_pressed("no3"):
		self.current_motion = MOTION.FALL

	
func _ready() -> void:
	
	# če ni podan spawn shape
	if not spawn_breaker_shape_polygon.empty():
		breaker_shape.polygon = spawn_breaker_shape_polygon
	collision_shape.polygon = breaker_shape.polygon
	broken_shape.hide()
	
	self.current_motion = current_motion
			

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	breaker_velocity = state.get_linear_velocity()
	
	
func on_hit(hit_shape: Object, hit_vector = null, slicing_style: int = 0, hitting_parent: Node = breaker_parent):
	
	if current_material == MATERIAL.UNBREAKABLE:
		return
	var hit_global_position: Vector2
	# cut swipe
	if hit_vector == null: 
		cut_it(hit_shape, 0)
	# break
	else:
		# click hit
		if hit_vector is Vector2:
			hit_global_position = hit_vector
			
		# swipe hit
		elif hit_vector is PoolVector2Array: 
			# dobim origin na robu, ki ga križa hit vektor
			# hit vektor je pika začetka in pika konca
			var hit_vector_pool_global: PoolVector2Array = [hit_vector[0] - global_position, hit_vector[1] - global_position]
			# za vsak rob preverim, če ga seka hit vektor
			var outline_poly: PoolVector2Array = breaker_shape.polygon
			for edge_index in outline_poly.size():
				var edge: PoolVector2Array = []
				if edge_index == outline_poly.size() - 1:
					edge = [outline_poly[edge_index], outline_poly[0]]
				else:
					edge = [outline_poly[edge_index], outline_poly[edge_index + 1]]
				var intersection_point = Geometry.segment_intersects_segment_2d(hit_vector_pool_global[0],hit_vector_pool_global[1],edge[0], edge[1])
				if intersection_point:
					hit_global_position = intersection_point + global_position
					break
			var indi = Met.spawn_indikator(hit_global_position)
			indi.modulate = Color.red
			indi.scale *= 10
			var indi1 = Met.spawn_indikator(hit_vector[0])
			indi1.modulate = Color.yellow
			indi1.scale *= 10
			var indi2 = Met.spawn_indikator(hit_vector[1])
			indi2.modulate = Color.green
			indi2.scale *= 10
			
		origin_global_position = hit_global_position
		var transformed_hit_polygon: PoolVector2Array = adapt_transforms_and_add_origin(hit_shape, hit_global_position)
		break_it(transformed_hit_polygon, slicing_style)
		
#		break_it(hit_shape.polygon, slicing_style) # debug
		
	
func cut_it(slice_line: Line2D, slicing_style: int):

	# adaptiram pozicijo poligon ... kot, da bi bil na poziciji cutting polija
	var slicing_line_adapted: PoolVector2Array = []
	for point in slice_line.points:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_to_local_position: Vector2 = point - position
		slicing_line_adapted.append(point_to_local_position)
	
	# je šel cut skozi?
	var cut_is_successful: bool = true
	for point in [slicing_line_adapted[0], slicing_line_adapted[slicing_line_adapted.size()-1]]:
		if Geometry.is_point_in_polygon(point, breaker_shape.polygon):
			cut_is_successful = false
			return
	
	# odebelim linijo in jo klipam kot poligon
	var split_line_offset: float = 2
	var fat_split_line: PoolVector2Array = Geometry.offset_polyline_2d(slicing_line_adapted, split_line_offset)[0]
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, fat_split_line)
	
	# spawnam
	for poly in clipped_polygons:
		spawn_new_breaker(poly, true)
	
	queue_free()


func break_it(slicing_polygon: PoolVector2Array, slicing_style: int = 0):
	
	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_shape.polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	# intersektam, da dobim chunk template
	var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_shape.polygon)
	if interecting_polygons.empty():  # debug težko, da bilo prazno
		print("intersection empty")
	# break breaker
	if clipped_polygons.empty(): # če slicer prekrije celoten shape > chunk
		print("brejkam celega")
		spawn_breaker_chunk(breaker_shape.polygon)
		breaker_shape.hide()
	# break apart
	else:	
		# breaker new shape
		breaker_shape.polygon = clipped_polygons.pop_front()
		collision_shape.polygon = breaker_shape.polygon
		# hole + chunk or new breaker
		for poly in clipped_polygons:
			if Geometry.is_polygon_clockwise(poly): # luknja ... operiram glavni poligon
				apply_hole(poly)
				spawn_breaker_chunk(poly)
				return
			else:
				spawn_new_breaker(poly)
		# chunks
		if not slicing_style == 0:
			for chunk in breaker_chunks_parent.get_children(): # debug, dokler ne bo animirano
				chunk.queue_free()
			for poly_index in interecting_polygons.size(): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				spawn_breaker_chunk(interecting_polygons[poly_index])
	breaking_round += 1 # debug


func move_it(new_motion_state: int):
	
	current_motion =  new_motion_state
	if not current_motion == MOTION.STILL: # debug
		current_motion =  MOTION.EXPLODE
	match current_motion:
		MOTION.STILL:
			mode = RigidBody2D.MODE_STATIC
		MOTION.FALL:
			mode = RigidBody2D.MODE_RIGID
			var force_vector = global_position - origin_global_position
			apply_central_impulse(force_vector * 1)
		MOTION.EXPLODE:
			gravity_scale = 0
			mode = RigidBody2D.MODE_RIGID
			linear_damp = 2
			var force_vector = global_position - origin_global_position
			apply_central_impulse(force_vector * 20)
	
	
# SPAWN ----------------------------------------------------------------------------------------------------------------
	
		
func spawn_breaker_chunk(new_chunk_polygon: PoolVector2Array):
	
	
	var new_breaker_chunk: Polygon2D = BreakerChunk.instance()
	new_breaker_chunk.chunk_polygon = new_chunk_polygon
	new_breaker_chunk.name = "BreakerChunk_Round%02d" % breaking_round
	new_breaker_chunk.color = Color.red
	new_breaker_chunk.texture = breaker_shape.texture
	new_breaker_chunk.texture_scale = breaker_shape.texture_scale
	new_breaker_chunk.origin_global_position = origin_global_position
	new_breaker_chunk.debry_parent = breaker_parent
	breaker_chunks_parent.add_child(new_breaker_chunk)
	
#	randomize()
#	new_breaker_chunk.color = Color (randf(), randf(), randf(), 1)
#	new_breaker_chunk.color.v = randf()
	
	# printt("new chunk", new_breaker_chunk, new_breaker_chunk.position)
		
		
func spawn_new_breaker(new_braker_polygon: PoolVector2Array, break_it: bool = false, new_color: Color = Color.white):
	
	var new_breaker = BreakerRigid.instance()
	new_breaker.spawn_breaker_shape_polygon = new_braker_polygon
	new_breaker.position = position
	new_breaker.name = "Breaker_Round%02d" % breaking_round
	breaker_parent.add_child(new_breaker)
	
	new_breaker.breaker_shape.color = new_color
	
	# če je cel za brejkerja, potem mu spawnerj potegnem čez
	if break_it:
		new_breaker.breaker_shape.polygon = new_braker_polygon
#		Note: To translate the polygon's vertices specifically, use the Transform2D.xform() method:
		

# UTILITI ----------------------------------------------------------------------------------------------------------------
	
	
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
	break_it(hole_polygon)
	

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


func _exit_tree() -> void:
	
	if "bodies_to_slice" in breaker_parent:
		breaker_parent.bodies_to_slice.erase(self) # demo
