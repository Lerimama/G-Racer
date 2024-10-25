extends RigidBody2D

enum MOTION {STILL, EXPLODE, FALL, SLIDE, CRACK, DISSOLVE, DISINTEGRATE}
var current_motion: int = MOTION.STILL setget _change_motion

enum MATERIAL {UNBREAKABLE, GHOST, WOOD, METAL, TILES, SOIL, GLASS}
export (MATERIAL) var current_material: int = MATERIAL.WOOD

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS}
var chunk_slice_style: int = SLICE_STYLE.BLAST #setget _change_slice_style

enum ORIGIN_LOCATION {INSIDE, EDGE, OUTSIDE}
var current_origin_location: int = ORIGIN_LOCATION.INSIDE


var spawn_breaker_polygon: PoolVector2Array = [] # podam ob spawnanju
var breaker_polygon: PoolVector2Array setget _change_breaker_polygon

onready var breaker_parent: Node = get_parent()
onready var operator: Node = $Operator
onready var breaker_shape: Polygon2D = $BreakerShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var custom_split_origin: Position2D = $CustomSplitOrigin
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var BreakerRigid: PackedScene = load("res://game/breaker/BreakerRigid.tscn")
onready var BreakerArea: PackedScene = load("res://game/breaker/BreakerArea.tscn")
onready var Cracker: PackedScene = preload("res://game/breaker/Cracker.tscn")

# breaking
var origin_global_position: Vector2 # se inherita skozi vse spawne
var origin_on_edge: bool = false # sam preverja, če je bil origina na robu
var sliced_chunk_polygons: Array = [] # _temp
var chunk_polygons: Array

# moving
var current_breaker_velocity: Vector2 = Vector2.ZERO

# debug
onready var broken_shape: Polygon2D = $BrokenShape
var breaking_round: int = 1
var chunks_spawned: Array = []
var debug_solo_mode: bool = false



func _input(event: InputEvent) -> void:
	
	if debug_solo_mode and Input.is_action_just_pressed("no1") and debug_solo_mode: # debug ... solo
		on_hit(broken_shape, custom_split_origin.position, 1)
	if Input.is_action_just_pressed("no2"):
		slice_chunks()

	
func _ready() -> void:
	
	if get_parent() == get_tree().root:
		debug_solo_mode = true
		
	# če ni podan spawn shape
	if not spawn_breaker_polygon.empty():
		breaker_shape.polygon = spawn_breaker_polygon
	self.breaker_polygon = breaker_shape.polygon
	self.current_motion = current_motion
	broken_shape.hide()
			

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	current_breaker_velocity = state.get_linear_velocity()
	
	
func on_hit(hit_shape: Polygon2D, hit_vector, slicing_style: int = 0, hitting_parent: Node = breaker_parent):
	
	if current_material == MATERIAL.UNBREAKABLE:
		return
	var hit_global_position: Vector2
	# click hit
	if hit_vector is Vector2:
		hit_global_position = hit_vector
	# swipe hit
	elif hit_vector is PoolVector2Array: 
		# dobim origin na robu, ki ga križa hit vektor ... hit vektor je pika začetka in pika konca, ker drugače se lahko zgodi, da ni zunaj
		var hit_vector_pool_global: PoolVector2Array = [hit_vector[0] - global_position, hit_vector[1] - global_position]
		# za vsak rob preverim, če ima sekajočo točko
		for edge_index in breaker_polygon.size():
			var edge: PoolVector2Array = []
			if edge_index == breaker_polygon.size() - 1:
				edge = [breaker_polygon[edge_index], breaker_polygon[0]]
			else:
				edge = [breaker_polygon[edge_index], breaker_polygon[edge_index + 1]]
			var intersection_point = Geometry.segment_intersects_segment_2d(hit_vector_pool_global[0],hit_vector_pool_global[1],edge[0], edge[1])
			if intersection_point:
				hit_global_position = intersection_point + global_position
				break
		# power vector in obseg hit shapeta
		var power_vector: Vector2 = hit_vector[1] - hit_global_position
		var hit_shape_radius: float = operator.get_polygon_radius(hit_shape.polygon)
		var power_to_radius_factor: float = power_vector.length() / hit_shape_radius
		var power_adapted_hit_polygon: PoolVector2Array = []
		for point in hit_shape.polygon:
			var adapted_point: Vector2 = point * power_to_radius_factor
			power_adapted_hit_polygon.append(adapted_point)
		hit_shape.polygon = power_adapted_hit_polygon
		
	origin_global_position = hit_global_position
	
	var transformed_hit_polygon: PoolVector2Array = adapt_transforms_and_add_origin(hit_shape, hit_global_position)
	if debug_solo_mode: # debug
		break_it(hit_shape.polygon, slicing_style) # debug
		return
	break_it(transformed_hit_polygon, slicing_style)
	

		
func on_cut(slice_line: Line2D, break_sides_count: int = 0, slicing_style: int = 0):
	
	var chunkize = true
	
	# adaptiram pozicijo poligon ... kot, da bi bil na poziciji cutting polija
	var slicing_line_adapted: PoolVector2Array = []
	for point in slice_line.points:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_to_local_position: Vector2 = point - position
		slicing_line_adapted.append(point_to_local_position)
	
	# je šel cut skozi?
	var cut_is_successful: bool = true
	for point in [slicing_line_adapted[0], slicing_line_adapted[slicing_line_adapted.size()-1]]:
		if Geometry.is_point_in_polygon(point, breaker_polygon):
			cut_is_successful = false
			return
	
	# odebelim linijo in jo klipam kot poligon
	var split_line_offset: float = 1
	var fat_split_line: PoolVector2Array = Geometry.offset_polyline_2d(slicing_line_adapted, split_line_offset)[0]
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_polygon, fat_split_line)
	
	# spawnam
	break_sides_count = 1
	match break_sides_count:
		0:
			self.breaker_polygon = clipped_polygons.pop_front()
			for poly in clipped_polygons:
				spawn_new_breaker(poly)
		1:
			# opredelim index najvišjega
			var highest_center_y: float = 0
			var highest_polygon_index: int = 0
			for poly in clipped_polygons:
				var poly_center: Vector2 = operator.get_polygon_center(poly)
				if poly_center.y < highest_center_y or highest_center_y == 0 : # najvišji ima najnižji y
					highest_center_y = poly_center.y
					highest_polygon_index = clipped_polygons.find(poly)
			self.breaker_polygon = clipped_polygons.pop_at(highest_polygon_index)
			
			for poly in clipped_polygons:
				spawn_new_breaker(poly, true)
		2:
			for poly in clipped_polygons:
				spawn_new_breaker(poly, true)	
			queue_free()

	
					
# SPLITING ... po vrsti izvedbe ----------------------------------------------------------------------------------------------------------------


func break_it(slicing_polygon: PoolVector2Array, slicing_style: int = 0):

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	# break breaker
	if clipped_polygons.empty(): # če slicer prekrije celoten shape > chunk
		print("clipped_polygons je prazen >> brejkam celega")
		make_chunk(breaker_polygon)
		breaker_shape.hide()
	# break apart
	else:	
		# breaker new shape
#		var new_breaker_shape_poly = clipped_polygons.pop_front()
		
		# intersektam, da dobim chunk template
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_polygon)
		if interecting_polygons.empty():  # debug težko, da bilo prazno
			print("intersection empty")
		
		self.breaker_polygon = clipped_polygons.pop_front()

		# hole + chunk or new breaker
		for poly in clipped_polygons:
			if Geometry.is_polygon_clockwise(poly): # luknja ... operiram glavni poligon
				var holed_polygons: Array = operator.apply_hole(breaker_polygon, poly)
				self.breaker_polygon = holed_polygons[0]
				break_it(holed_polygons[1])
			else:
				spawn_new_breaker(poly)
		
		# chunks
		if not slicing_style == 0:
			#			for chunk in chunks_spawned: # debug, dokler ne bo animirano
			#				chunk.queue_free()
			#			chunks_spawned.clear()
			#			chunk_polygons.clear()
			for poly_index in interecting_polygons.size(): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				make_chunk(interecting_polygons[poly_index])
				
	
	breaking_round += 1 # debug
	
	if not debug_solo_mode:
		call_deferred("slice_chunks")
	
		
func make_chunk(new_chunk_polygon: PoolVector2Array):
	
	var new_poly = Polygon2D.new()
	new_poly.polygon = new_chunk_polygon
	new_poly.color = Color.white
	add_child(new_poly)
	
#	new_poly.modulate.a = 0
	chunk_polygons.append(new_chunk_polygon)
	chunks_spawned.append(new_poly)
	#	print("chunk applied")

			
func slice_chunks(whole_breaker: bool = false, with_cracker: bool = false):
	
	with_cracker = true

	
	
	chunk_slice_style = SLICE_STYLE.FRAGMENTS
	
	for chunk in chunk_polygons:
		match chunk_slice_style:
			SLICE_STYLE.FRAGMENTS:
				split_chunk_to_polygons(chunk)
				if with_cracker:
					spawn_crackers(sliced_chunk_polygons, chunk)
					return
				else:
					spawn_debry_breakers(sliced_chunk_polygons)
			SLICE_STYLE.BLAST:
				split_chunk_to_polygons(chunk)
				spawn_debry_breakers(sliced_chunk_polygons)
			SLICE_STYLE.GRID_SQ:
				var grid_sliced_polygons: Array = operator.slice_grid(chunk, 4)
				spawn_crackers(grid_sliced_polygons[0], [], Color.cornflower)
				spawn_crackers(grid_sliced_polygons[1], [], Color.cornflower)	 
			SLICE_STYLE.GRID_HEX:
				var grid_sliced_polygons: Array = operator.slice_grid(chunk, 4)
				spawn_crackers(grid_sliced_polygons[0], [], Color.cornflower)	
				spawn_crackers(grid_sliced_polygons[1], [], Color.cornflower)		 
	
	for chunk in chunks_spawned: # debug, dokler ne bo animirano
		chunk.queue_free()
	chunks_spawned.clear()
	chunk_polygons.clear()
	
	if whole_breaker:
		queue_free()

	
func split_chunk_to_polygons(polygon_to_slice: PoolVector2Array):
	
	Met.spawn_indikator(origin_global_position, Color.greenyellow)
	
	var origin_position: Vector2 = origin_global_position - global_position
	var chunk_to_slice: PoolVector2Array = polygon_to_slice
	var origin_edge_index: int
	
	# preverjam origin lokacijo znotraj vs zunaj
	if Geometry.is_point_in_polygon(origin_position, chunk_to_slice):
		current_origin_location = ORIGIN_LOCATION.INSIDE
		# on edge?
		for edge_index in chunk_to_slice.size():
			var edge: PoolVector2Array = []
			if edge_index == chunk_to_slice.size() - 1:
				edge = [chunk_to_slice[edge_index], chunk_to_slice[0], chunk_to_slice[edge_index]] # FINTA ... pseudo trikotnik s podvajanjem ene od točk
			else:
				edge = [chunk_to_slice[edge_index], chunk_to_slice[edge_index + 1], chunk_to_slice[edge_index]] # FINTA
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
			chunk_to_slice = operator.split_outline_to_length(chunk_to_slice, split_edge_length)
			sliced_chunk_polygons = operator.slice_spiderweb(chunk_to_slice)
		ORIGIN_LOCATION.EDGE:
			# outline split
			var split_edge_length: int = 50
			chunk_to_slice = operator.split_outline_to_length(chunk_to_slice, split_edge_length)
			#		var split_count: int = 1 # _temp
			#		chunk_to_slice = operator.split_outline_on_part(chunk_to_slice, 0.5, split_count)
			# odstranim splitane pike na origin robu
			var origin_edge_end_point_index: int
			if origin_edge_index == chunk_to_slice.size() - 1:
				origin_edge_end_point_index = 0
			else:
				origin_edge_end_point_index = origin_edge_index + 1
			for point_index in chunk_to_slice.size(): 
				if point_index > origin_edge_index and point_index < origin_edge_end_point_index:
					chunk_to_slice.remove(point_index)
			# vstavim origin point
			chunk_to_slice.insert(origin_edge_index + 1, origin_position)
			# slajsam
			var origin_point_index: int = chunk_to_slice.find(origin_position)
			sliced_chunk_polygons = operator.triangulate_daisy(chunk_to_slice, origin_point_index)[0]
		ORIGIN_LOCATION.OUTSIDE:
#			var split_edge_length: int = 150
#			chunk_to_slice = operator.split_outline_to_length(chunk_to_slice, split_edge_length)
#			sliced_chunk_polygons = operator.triangulate_daisy(chunk_to_slice)[0]
			sliced_chunk_polygons = operator.triangulate_delaunay(chunk_to_slice, -1, 10)
			# ostranim trikotnike, ki segajo preko roba
			pass	


# SPAWN ----------------------------------------------------------------------------------------------------------------
	
		
func spawn_new_breaker(new_braker_polygon: PoolVector2Array, break_it: bool = false, new_color: Color = Color.white):
	
	var new_breaker = BreakerRigid.instance()
#	new_breaker.spawn_breaker_polygon = new_braker_polygon
	new_breaker.position = position
	new_breaker.name = "Breaker_Round%02d" % breaking_round
	breaker_parent.add_child(new_breaker)
	
	new_breaker.breaker_shape.color = new_color
	new_breaker.breaker_polygon = new_braker_polygon
	
	# če je cel za brejkerja, potem mu spawnerj potegnem čez
	if break_it:
		new_breaker.make_chunk(new_breaker.breaker_polygon)
		new_breaker.breaker_shape.hide()
		new_breaker.slice_chunks(true)
		
#		new_breaker.broken_shape.polygon = new_braker_polygon
#		print (Geometry.clip_polygons_2d(new_braker_polygon,new_breaker.broken_shape.polygon))
	
	printt("new breaker", new_breaker, new_breaker.position)
		

func spawn_debry_breakers(debry_polygons: Array, new_color: Color = Color.white):
	
	for poly in debry_polygons:
		
		# centraliziram in globaliziram
		var centralized_spawn_position: Vector2 = position
		var centralized_poly: Array = centralize_polygon(poly)
		poly = centralized_poly[0]
		centralized_spawn_position = centralized_poly[1]

		var new_breaker = BreakerRigid.instance()
		#		var new_breaker = BreakerArea.instance()
		new_breaker.name = "Breaker_Debry"
		new_breaker.spawn_breaker_polygon = poly
		new_breaker.position = centralized_spawn_position
		new_breaker.z_index = 10 # debug
		new_breaker.origin_global_position = origin_global_position
		
		breaker_parent.add_child(new_breaker)
		
		new_breaker.breaker_shape.color = Color.pink	
		new_breaker.current_material = new_breaker.MATERIAL.UNBREAKABLE
		new_breaker.current_motion = new_breaker.MOTION.EXPLODE
		
		#		printt ("new debry breaker", new_debry.position, new_debry.debry_polygon[0], polygon[0], new_debry.get_parent())		
	
	#	modulate.a = 0 	
	
	
func spawn_crackers(cracked_polygons: Array, source_chunk_polygon: PoolVector2Array = [], col: Color = Color.white, clear_before: bool = true):
	
	print("crekrs")
#	var crackers_parent: Node2D = $Crackers
	var crackers_parent: Node2D = $CrackerRect/Crackers
	var crackers_rect: Control = $CrackerRect
	printt("chunk", chunk_polygons[0])
	if not source_chunk_polygon.empty():
		var chunk_far_points: Array = operator.get_polygon_far_points(source_chunk_polygon) # L-T-R-B
		crackers_rect.rect_position = Vector2(chunk_far_points[0].x, chunk_far_points[1].y)
		crackers_rect.rect_size = Vector2(chunk_far_points[2].x, chunk_far_points[3].y) - crackers_rect.rect_position
	


	if clear_before: # debug
		while crackers_parent.get_child_count() > 0:
			crackers_parent.get_children().pop_back().queue_free()	
	
	for poly_index in cracked_polygons.size():
		var new_cracked_shape = Cracker.instance()
		new_cracked_shape.position -= crackers_rect.rect_position
		new_cracked_shape.name = "%s_Crackers" % name
		new_cracked_shape.polygon = cracked_polygons[poly_index]
		new_cracked_shape.z_index = 10 # debug
#		new_cracked_shape.cracker_color = col
#		new_cracked_shape.crack_color = Color.black
		crackers_parent.add_child(new_cracked_shape)
#
#		printt ("new cracked poly", new_cracked_shape.color, new_cracked_shape.polygon[0])		

	#	modulate.a = 0
	if not source_chunk_polygon.empty():
	
		# istočasno tvinam rect masko in pozicijo polignov ... tako ostanejo poligoni "pri miru"
		var rect_start_offset: Vector2 = Vector2.ZERO#(crackers_rect.rect_size.x/2, crackers_rect.rect_size.y/2)
		#		var rect_start_offset: Vector2 = Vector2(crackers_rect.rect_size.x/2, crackers_rect.rect_size.y/2)
		var rect_start_position: Vector2 = crackers_rect.rect_position + rect_start_offset
		var rect_start_scale: Vector2 = Vector2.ZERO
		rect_start_scale.x = crackers_rect.rect_size.x
		var reveal_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		reveal_tween.tween_property(crackers_rect, "rect_size", crackers_rect.rect_size, 1).from(rect_start_scale)
		reveal_tween.parallel().tween_property(crackers_rect, "rect_position", crackers_rect.rect_position, 1).from(rect_start_position)
		reveal_tween.parallel().tween_property(crackers_parent, "position", Vector2.ZERO, 1).from(- rect_start_offset)
		yield(reveal_tween, "finished")
		spawn_debry_breakers(cracked_polygons)
		for child in crackers_parent.get_children():
			child.queue_free()
		queue_free()
		
#	reveal_tween.parallel().tween_property(crackers_parent, "rect_position", crackers_parent.rect_position, 1).from(operator.get_polygon_center(source_chunk_polygon))
	
	
# UTILITI ----------------------------------------------------------------------------------------------------------------
	

func adapt_transforms_and_add_origin(shape_to_transform: Polygon2D, origin_position: Vector2): # je to origin position?
	
	shape_to_transform.polygon = operator.reset_shape_transforms(shape_to_transform).polygon
	
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var transformed_polygon: PoolVector2Array = []
	for point in shape_to_transform.polygon:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * shape_to_transform.scale + origin_position
		var hitting_point_position_against_object: Vector2 = point_global_position - position
		transformed_polygon.append(hitting_point_position_against_object)

	return transformed_polygon


func centralize_polygon(polygon_points: PoolVector2Array):
	# pred: spawned pozicija je enaka breakerjevi, notranji poligon je zamaknjen
	# po: spawned ima origin v središču shape polygona
	
	var chunk_center = operator.get_polygon_center(polygon_points)# + def_chunk_global_pos
	
	var moved_polygon_points: PoolVector2Array = []
	for point in polygon_points:
		var moved_point = point - chunk_center# + global_position
		moved_polygon_points.append(moved_point)
		
	return [moved_polygon_points, chunk_center + global_position]


func _exit_tree() -> void:
	
	if "bodies_to_slice" in breaker_parent:
		breaker_parent.bodies_to_slice.erase(self) # demo


func _change_breaker_polygon(new_breaker_polygon: PoolVector2Array):
	
	breaker_polygon = new_breaker_polygon
	breaker_shape.polygon = breaker_polygon
#	breaker_shape.set_deferred("polygon", breaker_polygon)
	collision_shape.set_deferred("polygon", breaker_polygon)
	
	
func _change_motion(new_motion_state: int):
	
	current_motion =  new_motion_state
	if not current_motion == MOTION.STILL: # debug
		current_motion =  MOTION.FALL
	match current_motion:
		MOTION.STILL:
			mode = RigidBody2D.MODE_STATIC
		MOTION.FALL:
			gravity_scale = 1
			mode = RigidBody2D.MODE_RIGID
#			var force_vector = global_position - origin_global_position
#			apply_central_impulse(force_vector * 1)
		MOTION.EXPLODE:
			gravity_scale = 0
			mode = RigidBody2D.MODE_RIGID
			linear_damp = 2
			var force_vector = global_position - origin_global_position
			apply_central_impulse(force_vector * 20)
		MOTION.DISSOLVE:
			gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var dissolve_tween = get_tree().create_tween()
			dissolve_tween.tween_property(self, "modulate:a", 0, random_duration).set_delay(random_delay)
		MOTION.CRACK:
			pass
