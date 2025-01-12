extends Polygon2D
# braker shape > on hit > nareže vmesne chunke > chunke razbije na manjše kose

enum MATERIAL {STONE, GLASS, GRAVEL, WOOD } # GHOST, WOOD, METAL, TILES, SOIL
export (MATERIAL) var current_material: int = MATERIAL.STONE

enum MOTION {STILL, EXPLODE, FALL, MINIMIZE, DISSAPEAR} # SLIDE, CRACK, SHATTER
var current_motion: int = MOTION.STILL setget _on_change_motion

enum HIT_BY_TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # _temp ... ujema se z demotom
var current_hit_by_type: int = HIT_BY_TYPE.KNIFE

enum BREAK_SIZE {XSMALL, SMALL, MEDIUM, LARGE, XLARGE} # za razmerje brejkanja
var current_break_size: int = BREAK_SIZE.MEDIUM

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS, NONE}
enum BREAKER_TYPE {OWNER, BREAKER, DEBRY_BREAKER, DEBRY_AREA}


# -------------------------------------------------------------------------


export var height = 500 # setget
export var elevation = 0 # setget
export var transparency: float = 1 # setget
export var is_breakable: bool = true
export (int) var shape_edge_width: float = 0 setget _on_change_shape_edge_width
export (NodePath) var collision_shape_path: String # če je svet kaj drugega kot njegov parent

var shape_polygon: PoolVector2Array = [] setget _on_change_shape # !!! polygon menjam samo prek tega setgeta
var break_origin_global: Vector2 = Vector2.ZERO # se inherita skozi vse spawne
var edge_shape_color: Color = Color.black
var cut_breaks_shapes: int = 1 # nobena, spodnja ali vse
var breaking_round: int = 0 # kolikokrat je bil brejker že nalomljen
# spawn okolje ... fizični svet kjer se nahaja lastnik brejkerja
var world_node: Node # če ga ne podam ob spawnu, je parent lastnika

onready var breaker_tool: Polygon2D = $BreakerTool
onready var edge_shape: Polygon2D = $EdgeShape
onready var collision_shape: CollisionPolygon2D# = $"../CollisionPolygon2D"
onready var operator: Node = $Operator

onready var OwnerScene: PackedScene = load("res://game/level/breakers/RigidObject.tscn") # funkcije in LNF originala, fizika, breakable
onready var BreakerRigid: PackedScene = load("res://game/level/breakers/breaker/BreakerRigid.tscn") #  LNF originala, fizika, (un)breakable
onready var Debry: PackedScene = preload("res://game/level/breakers/breaker/Debry.tscn") # LNF originala, brez fizike, unbreakable
onready var CrackerBox: PackedScene = preload("res://game/level/breakers/breaker/CrackerBox.tscn") # za animacijo lomljenja na kose ... LNF originala

onready var breaker_shape_parent: Node2D = get_parent()


func _ready() -> void:

	# določim svet spawnanja
	if world_node == null:
		world_node = breaker_shape_parent.get_parent()

	if collision_shape_path:
		collision_shape = get_node(collision_shape_path)

	# če ni podana oblika, izbere defaultno
	if shape_polygon.empty():
		self.shape_polygon = polygon
	# če je podana oblika, jo prevzame
	else:
		self.shape_polygon = shape_polygon

	self.current_motion = current_motion
	self.shape_edge_width = shape_edge_width
	edge_shape.color =  edge_shape_color
	breaker_tool.hide()


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):
#	printt("HIT", hitting_node, hit_global_position)

	# shape je lahko: polygon2D, collision_shape
	# če se pojavi kaj novega vneseš tukaj

	# opredelim data za celotno slajsanje: origin, smer, območje vpliva in moč

	#	break_origin_global = Vector2.ZERO
	#	printt ("origin", break_origin_global, hitting_node.position, hitting_node.global_position)

	if not is_breakable:
		return

	if hitting_node is Line2D:
		_cut_it(hitting_node)
		return

	var hit_by_type: int = HIT_BY_TYPE.HAMMER

	# hitter properties
	var hit_shape = hitting_node.influence_area.get_child(0)
	var hit_shape_scale = hitting_node.influence_area.scale
	var hit_by_direction: Vector2 = Vector2.ZERO
	if "direction" in hitting_node:
		hit_by_direction = hitting_node.direction
	current_hit_by_type = hitting_node.object_type

	# slicing polygon
	var hit_by_polygon: PoolVector2Array = []
	if hit_shape is Polygon2D or hit_shape is CollisionPolygon2D:
		hit_by_polygon = hit_shape.polygon
	elif hit_shape is CollisionShape2D:
		print ("Hit shape je CollShape ... Uporabim Breaker tool ... naštimaj to")
		hit_by_polygon = breaker_tool.polygon

	# break origin ... vector intersection or closest point
	#	var intersection_vector_length: float = operator.get_polygon_radius(hit_by_polygon) * hit_shape_scale.x
	var influence_radius: float = operator.get_polygon_radius(hit_by_polygon) * hit_shape_scale.x
	var intersection_vector_start: Vector2 = hit_global_position - breaker_shape_parent.position
	var intersection_vector_end: Vector2 = intersection_vector_start + hit_by_direction * influence_radius
	var intersection_vector_pool: PoolVector2Array = [intersection_vector_start, intersection_vector_end]
	var intersection_data: Array = operator.get_outline_intersecting_segments(intersection_vector_pool, shape_polygon) # [[vector2, index], ...]
	var intersection_point: Vector2

	if intersection_data.empty():
		# poiščem najbližjo štartni točki
		var closest_point_on_closest_edge: Vector2 = operator.get_outline_segment_closest_to_point(intersection_vector_start, shape_polygon)[1]
		intersection_point = closest_point_on_closest_edge
#		printt("No intersection on hit vector ...  new closest point", intersection_point, intersection_vector_start)
	if intersection_data.size() == 1:
		intersection_point = intersection_data[0][0]
	elif intersection_data.size() > 1: # več presečišč > izberem najbližjo štartu hit vektorja
		var closest_point_to_hit_start: Vector2
		var shortest_dist_to_hit_start: float = 0
		for intersection in intersection_data:
			var point: Vector2 = intersection[0]
			var point_to_hit_start_dist: float = (intersection_vector_pool[0] - point).length()
			if point_to_hit_start_dist < shortest_dist_to_hit_start or shortest_dist_to_hit_start == 0:
				shortest_dist_to_hit_start = point_to_hit_start_dist
				closest_point_to_hit_start = point
		intersection_point = closest_point_to_hit_start
	break_origin_global = intersection_point + breaker_shape_parent.global_position

	# opredelim velikost prilagodim hit polygon
	var influence_radius_per_unit: float = influence_radius / Sets.unit_one
	var simplify_round_count: int = 0
	if influence_radius_per_unit < 0.5:
		current_break_size = BREAK_SIZE.XSMALL
		simplify_round_count = 3
	elif influence_radius_per_unit < 1:
		current_break_size = BREAK_SIZE.SMALL
		simplify_round_count = 3
	elif influence_radius_per_unit < 2:
		current_break_size = BREAK_SIZE.MEDIUM
		simplify_round_count = 2
	elif influence_radius_per_unit < 3.5:
		current_break_size = BREAK_SIZE.LARGE
		simplify_round_count = 1
	else:
		current_break_size = BREAK_SIZE.XLARGE
		simplify_round_count = 1

	var simple_hit_polygon = operator.simplify_outline(hit_by_polygon, simplify_round_count)
	#	printt ("rad", influence_radius_per_unit, influence_radius / Sets.unit_one)

	#		0:
	#			pass

		#	Mets.spawn_line_2d(intersection_vector_start + position, intersection_vector_end + position, get_parent())

	# break
	var transformed_hit_polygon: PoolVector2Array = operator.adapt_transforms_and_add_origin(simple_hit_polygon, break_origin_global, hit_shape_scale)
	#	var transformed_hit_polygon: PoolVector2Array = operator.adapt_transforms_and_add_origin(hit_by_polygon, break_origin_global, hit_shape_scale)
	_break_it(transformed_hit_polygon)


# BREJK (chunkization) ------------------------------------------------------------------------------------------------


func _break_it(slicing_polygon: PoolVector2Array):

	# podam
	var chunks_to_slice: Array = []

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(shape_polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	breaking_round += 1

	# break whole
	if clipped_polygons.empty(): # če slicer prekrije celoten shape > chunk
		print("Clipped_polygons je prazen >> brejkam celega")
		chunks_to_slice.append(shape_polygon)
		_slice_chunks([shape_polygon], true)
		#		call_deferred("_slice_chunks", [shape_polygon], true)
	# break apart
	else:
		# dobim chunk shape
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, shape_polygon)
		if interecting_polygons.empty():  # zazih ... težko, da bilo prazno
			printt("Intersection empty ... no chunks. Clipped size ", clipped_polygons.size())
		self.shape_polygon = clipped_polygons.pop_front()

		# hole, chunk, new breaker
		for poly in clipped_polygons:
			# hole
			if Geometry.is_polygon_clockwise(poly): # luknja ... operiram glavni poligon
				var holed_polygons: Array = operator.apply_hole(shape_polygon, poly)
				self.shape_polygon = holed_polygons[0]
				_break_it(holed_polygons[1])
				return
			# breaker
			else:
				_spawn_to_pieces(poly, BREAKER_TYPE.BREAKER)
		# chunks
		if not current_hit_by_type == HIT_BY_TYPE.PAINT:
			for poly in interecting_polygons: # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				chunks_to_slice.append(poly)

		_slice_chunks(chunks_to_slice)
		#		call_deferred("_slice_chunks", chunks_to_slice)


func _cut_it(slice_line: Line2D):

	# adaptiram pozicijo poligon ... kot, da bi bil na poziciji cutting polija
	var slicing_line_adapted: PoolVector2Array = []
	for point in slice_line.points:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_to_local_position: Vector2 = point - breaker_shape_parent.position
		slicing_line_adapted.append(point_to_local_position)

	# je šel cut skozi?
	var cut_is_successful: bool = true
	for point in [slicing_line_adapted[0], slicing_line_adapted[slicing_line_adapted.size()-1]]:
		if Geometry.is_point_in_polygon(point, shape_polygon):
			cut_is_successful = false
			return

	# odebelim linijo in jo klipam kot poligon
	var split_line_offset: float = 1
	var fat_split_line: PoolVector2Array = Geometry.offset_polyline_2d(slicing_line_adapted, split_line_offset)[0]
	var clipped_polygons: Array = Geometry.clip_polygons_2d(shape_polygon, fat_split_line)

	# spawnam
	cut_breaks_shapes = 1
	match cut_breaks_shapes:
		0:
			self.shape_polygon = clipped_polygons.pop_front()
			for poly in clipped_polygons:
				_spawn_to_pieces(poly, BREAKER_TYPE.BREAKER)
		1:
			# opredelim index najvišjega, ki ga ostane trnueten braker
			var highest_center_y: float = 0
			var highest_polygon_index: int = 0
			for poly in clipped_polygons:
				var poly_center: Vector2 = operator.get_polygon_center(poly)
				if poly_center.y < highest_center_y or highest_center_y == 0 : # najvišji ima najnižji y
					highest_center_y = poly_center.y
					highest_polygon_index = clipped_polygons.find(poly)
			self.shape_polygon = clipped_polygons.pop_at(highest_polygon_index)
			for poly in clipped_polygons:
				_spawn_to_pieces(poly, BREAKER_TYPE.BREAKER, true)
		2:
			for poly in clipped_polygons:
				_spawn_to_pieces(poly, BREAKER_TYPE.BREAKER, true)
			queue_free()


# SLAJS (debrization) -----------------------------------------------------------------------------------------------


func _slice_chunks(chunk_polygons: Array, slice_whole_breaker: bool = false, slice_with_crackers: bool = true):

	#	var current_slicing_style: int = _get_slicing_style()

	# debug
	slice_with_crackers = true

	var spawned_chunks: Array = [] # da ji lahko potem zbriešm
	for chunk in chunk_polygons:
		var chunk_debry_polygons: Array
		#		var current_slicing_style = SLICE_STYLE.FRAGMENTS
		#		match current_slicing_style:
		#			SLICE_STYLE.NONE:
		#				chunk_derby_polygons.append(chunk)
		##			SLICE_STYLE.GRID_SQ:
		##				var grid_sliced_polygons: Array = operator.split_grid(chunk, 4)
		##				chunk_derby_polygons = grid_sliced_polygons[0]
		##				chunk_derby_polygons.append(grid_sliced_polygons[1])
		##			SLICE_STYLE.GRID_HEX:
		##				var grid_sliced_polygons: Array = operator.split_grid(chunk, 4)
		##				chunk_derby_polygons = grid_sliced_polygons[0]
		##				chunk_derby_polygons.append(grid_sliced_polygons[1])
		#			SLICE_STYLE.FRAGMENTS:
		#				chunk_derby_polygons = _split_chunk_to_polygons(chunk) # izbira stila glede na orodje in material
		#			SLICE_STYLE.BLAST:
		#				chunk_derby_polygons = _split_chunk_to_polygons(chunk)
		chunk_debry_polygons = _split_chunk_to_polygons(chunk)
		if slice_with_crackers:
			spawned_chunks.append(_spawn_chunk(chunk))
			var crackers_reveal
			var new_crackers = _spawn_crackers(chunk_debry_polygons, chunk) # OPT ... ne dela s signalom, a bi bilo bolje
			#			yield(new_crackers, "cracks_animation_finished")
			yield(get_tree().create_timer(new_crackers.crackers_reveal_time), "timeout")
		for debry_polygon in chunk_debry_polygons:
			_spawn_to_pieces(debry_polygon, BREAKER_TYPE.DEBRY_AREA)



	for chunk in spawned_chunks:
		chunk.queue_free()

	if slice_whole_breaker:
		queue_free()


func _split_chunk_to_polygons(chunk_polygon: PoolVector2Array):
	# izbira stila glede na orodje in material

	var origin_position: Vector2 = break_origin_global - breaker_shape_parent.global_position
	var is_on_edge_distance: float = 10

	# origin type (edge index)
	var origin_edge_index: int
	var origin_location_on_shape: int = -1 # -1 = out, 1 = in, 0 = edge
	if Geometry.is_point_in_polygon(origin_position, chunk_polygon):
		origin_edge_index = operator.get_outline_segment_closest_to_point(origin_position, chunk_polygon, is_on_edge_distance)[0]
		if origin_edge_index == - 1: # -1 pomeni, da je znotraj poligona in ni na robu
			origin_location_on_shape = 1
		else:
			origin_location_on_shape = 0

	# origin location
	var sliced_chunk_polygons: Array
	var polygon_with_origin: PoolVector2Array = chunk_polygon
	match origin_location_on_shape:
		-1: # zunaj ... dodam origin in reclipam slicane poligone
			polygon_with_origin.append(origin_position)
			#			print("slice origin OUTSIDE")
			#			sliced_chunk_polygons = operator.split_delaunay(chunk_polygon, 10)
		0: # edge ... splitam edge na origin točki
			#			print("slice origin EDGE")
			polygon_with_origin.insert(origin_edge_index + 1, origin_position)
		1: # notri ... dodam origin
			polygon_with_origin.append(origin_position)
			#			print("slice on origin INSIDE")
			#			var split_edge_length: int = 150
			#			chunk_polygon = operator.split_outline_to_length(chunk_polygon, split_edge_length)
			#			sliced_chunk_polygons = operator.split_spiderweb(chunk_polygon)

	# za delaunay
	var delaunay_add_points_count: int = 0
	var daisy_side_split_count: int = 0
	match current_break_size:
		BREAK_SIZE.XSMALL:
			delaunay_add_points_count = 0
			daisy_side_split_count = 0
		BREAK_SIZE.SMALL:
			delaunay_add_points_count = 2
			daisy_side_split_count = 0
		BREAK_SIZE.MEDIUM:
			delaunay_add_points_count = 6
			daisy_side_split_count = 1
		BREAK_SIZE.LARGE:
			delaunay_add_points_count = 10
			daisy_side_split_count = 3
		BREAK_SIZE.XLARGE:
			delaunay_add_points_count = 14
			daisy_side_split_count = 6

	# tool type

	#	var side_sliced_polygons: Array
	#	for poly in first_slice_polys:
	#		var new_poly = operator.split_outline_on_part(poly)
	#		side_sliced_polygons.append_array(operator.split_delaunay(new_poly))
	#	sliced_chunk_polygons = side_sliced_polygons
	#	sliced_chunk_polygons = operator.split_daisy(desplit_chunk_polygon, origin_edge_index + 1)[0]
	#	sliced_chunk_polygons = operator.split_spiderweb(desplit_chunk_polygon)

	var tool_slice_polygons: Array
	match current_hit_by_type:
		HIT_BY_TYPE.KNIFE: # delunay
			tool_slice_polygons = operator.split_delaunay(chunk_polygon, delaunay_add_points_count)
			pass
		HIT_BY_TYPE.HAMMER: # delunay
			tool_slice_polygons = operator.split_delaunay(chunk_polygon, delaunay_add_points_count)
		HIT_BY_TYPE.PAINT:#erase
			pass
		HIT_BY_TYPE.EXPLODING: # daisy / spiderweb
			tool_slice_polygons = operator.split_daisy(polygon_with_origin, origin_edge_index + 1)[0]
			pass

	sliced_chunk_polygons = tool_slice_polygons

	return sliced_chunk_polygons


# SPAWN ----------------------------------------------------------------------------------------------------------------


func _spawn_to_pieces(new_piece_polygon: PoolVector2Array, new_breaker_type: int, spawn_and_slice: bool = false):
	# vedno ima LNF originala
	# OWNER: funkcije, fizika, breakable
	# BREAKER: fizika, breakable
	# DEBRY_BREAKER: fizika, unbreakable
	# DEBRY_AREA: no fizik, unbreakable

#	printt("spawn %s" % BREAKER_TYPE.keys()[new_breaker_type], breaker_shape_parent)

	var new_piece: Node2D

	match new_breaker_type:
		BREAKER_TYPE.OWNER:
			new_piece = OwnerScene.instance()
			new_piece.name = breaker_shape_parent.name + "_Round_%d" % breaking_round
			new_piece.position = breaker_shape_parent.position

			var new_breaker_owner_breaker = new_piece.get_node(name)
			new_breaker_owner_breaker.world_node = world_node

		BREAKER_TYPE.BREAKER:
			new_piece = BreakerRigid.instance()
			new_piece.name = name + "_Round_%d" % breaking_round
			new_piece.position = position

			var new_breaker_breaker = new_piece.get_node(name)
			new_breaker_breaker.world_node = world_node

		BREAKER_TYPE.DEBRY_BREAKER:
			# centraliziram polygon ... 0,0 pozicija je v centru poligona (zamaknem točke)
			var centralized_polygon_data: Array = operator.centralize_polygon_position(new_piece_polygon)
			var centralized_breaker_polygon: PoolVector2Array = centralized_polygon_data[0]
			new_piece_polygon = centralized_polygon_data[0]
			# global pozicija ... lokalno v globalno
			var centralized_global_position: Vector2 = centralized_polygon_data[1] + breaker_shape_parent.position
			# spawn
			new_piece = BreakerRigid.instance()
			new_piece.name =  name + "_DebryBreaker"
			new_piece.position = centralized_global_position
			new_piece.is_breakable = false
			new_piece.height = 0 # _temo debryshadows
			new_piece.elevation = 0 # _temo debryshadows

			var new_breaker_breaker = new_piece.get_node(name)
			new_breaker_breaker.world_node = world_node

		BREAKER_TYPE.DEBRY_AREA:
			# centraliziram polygon ... 0,0 pozicija je v centru poligona (zamaknem točke)
			var centralized_polygon_data: Array = operator.centralize_polygon_position(new_piece_polygon)
			var centralized_breaker_polygon: PoolVector2Array = centralized_polygon_data[0]
			new_piece_polygon = centralized_polygon_data[0]
			# global pozicija ... lokalno v globalno
			var centralized_global_position: Vector2 = centralized_polygon_data[1] + breaker_shape_parent.position
			# sapwn
			new_piece = Debry.instance()
			new_piece.name =  name + "_DebryArea"
			new_piece.position = centralized_global_position
			new_piece.debry_owner = breaker_shape_parent
			# debug senčke
			new_piece.height = 0 # _temo debryshadows
			new_piece.elevation = 0 # _temo debryshadows

	world_node.add_child(new_piece)


	# after setup
	if new_breaker_type == BREAKER_TYPE.DEBRY_AREA: # area ma skript že na glavnem nodetu
		if texture:
			_copy_texture_between_shapes(new_piece.debry_shape, self)
			new_piece.debry_shape.texture_offset = new_piece.position - breaker_shape_parent.position # ne-debry je ZERO
		new_piece.debry_shape.color = color
		new_piece.shape_polygon = new_piece_polygon
		new_piece.break_origin_global = break_origin_global # za animacijo debryja
		new_piece.shape_edge_width = 2
		new_piece.current_motion = new_piece.MOTION.STILL

	else:
		var internal_breaker_shape: Polygon2D = new_piece.get_node(name)
		if texture:
			_copy_texture_between_shapes(internal_breaker_shape, self)
			internal_breaker_shape.texture_offset = new_piece.position - breaker_shape_parent.position # ne-debry je ZERO
		internal_breaker_shape.color = color
		internal_breaker_shape.shape_polygon = new_piece_polygon
		internal_breaker_shape.break_origin_global = break_origin_global # za animacijo debryja
		if new_breaker_type == BREAKER_TYPE.DEBRY_BREAKER:
			internal_breaker_shape.shape_edge_width = 2
			internal_breaker_shape.current_motion = new_piece.MOTION.EXPLODE

		# spawn_and_slice je lahko samo OWNER ali BREAKER
		if spawn_and_slice:
			new_piece._slice_chunks([new_piece.shape_polygon], true)
			#			new_piece.call_deferred("_slice_chunks", [new_piece.shape_polygon], true)


func _spawn_chunk(new_chunk_polygon: PoolVector2Array):
	# chunk je odlomljen kos, ki se razbije na manjše dele ... LNF originala

	var new_broken_chunk: Polygon2D = Polygon2D.new()
	new_broken_chunk.name = name + "_Chunk"
	new_broken_chunk.polygon = new_chunk_polygon
	new_broken_chunk.color = color
	add_child(new_broken_chunk)

	if texture:
		_copy_texture_between_shapes(new_broken_chunk, self)

	return new_broken_chunk


func _spawn_crackers(cracked_polygons: Array, chunk_polygon: PoolVector2Array):
	# po animaciji se kvefrijajo

	var new_box_of_crackers = CrackerBox.instance()
	new_box_of_crackers.breaker_position = breaker_shape_parent.position
	new_box_of_crackers.break_origin_global = break_origin_global
	new_box_of_crackers.cracked_polygons = cracked_polygons
	new_box_of_crackers.chunk_polygon = chunk_polygon
	new_box_of_crackers.breaker_shape = self
	add_child(new_box_of_crackers)

	return new_box_of_crackers # za kvefrijanje


# UTILITI ----------------------------------------------------------------------------------------------------------------


func _copy_texture_between_shapes(copy_to: Polygon2D, copy_from: Polygon2D):

	copy_to.texture = copy_from.texture
	copy_to.texture_offset = copy_from.texture_offset
	copy_to.rotation_degrees = copy_from.rotation_degrees
	copy_to.texture_scale = copy_from.texture_scale


func _get_slicing_style(sliced_by_type: int = current_hit_by_type):

	var material_tool_combo: Array = [current_material, sliced_by_type]
	var slice_style: int

	match sliced_by_type:
		HIT_BY_TYPE.HAMMER:
			slice_style = SLICE_STYLE.FRAGMENTS
		HIT_BY_TYPE.KNIFE:
			slice_style = SLICE_STYLE.FRAGMENTS
		HIT_BY_TYPE.PAINT:
			slice_style = SLICE_STYLE.FRAGMENTS
		HIT_BY_TYPE.ROCKET:
			pass

	return slice_style


func _on_change_shape(new_breaker_polygon: PoolVector2Array):

	shape_polygon = new_breaker_polygon
	polygon = shape_polygon
	edge_shape.polygon = shape_polygon
	self.shape_edge_width = shape_edge_width
	collision_shape.polygon = shape_polygon
	#	collision_shape.set_deferred("polygon", shape_polygon)

	if breaker_shape_parent.has_node("ShapeShadow"):
		breaker_shape_parent.get_node("ShapeShadow").update_shadows()


func _on_change_motion(new_motion_state: int):

	current_motion =  new_motion_state

#	printt("Breaker MOTION", MOTION.keys()[current_motion])

	# debug
#	if not current_motion == MOTION.STILL:
#		current_motion = MOTION.MINIMIZE

	match current_motion:
		MOTION.STILL:
			if breaker_shape_parent is RigidBody2D:
				breaker_shape_parent.mode = RigidBody2D.MODE_RIGID
				#				breaker_shape_parent.set_deferred("mode", RigidBody2D.MODE_STATIC)
		MOTION.FALL:
			if breaker_shape_parent is RigidBody2D:
				breaker_shape_parent.gravity_scale = 1
				breaker_shape_parent.mode = RigidBody2D.MODE_RIGID
				#				breaker_shape_parent.set_deferred("mode", RigidBody2D.MODE_RIGID)
			else:
				print("animate FALL")
				pass
		MOTION.EXPLODE:
			if breaker_shape_parent is RigidBody2D:
				breaker_shape_parent.gravity_scale = 0
				breaker_shape_parent.mode = RigidBody2D.MODE_RIGID
				#				breaker_shape_parent.set_deferred("mode", RigidBody2D.MODE_RIGID)
				breaker_shape_parent.linear_damp = 2
				var force_vector = breaker_shape_parent.global_position - break_origin_global
				breaker_shape_parent.apply_central_impulse(force_vector * 20)
			else:
				print("animate EXPLOSION")
				pass
		MOTION.DISSAPEAR:
			if breaker_shape_parent is RigidBody2D:
				#				breaker_shape_parent.set_deferred("mode", RigidBody2D.MODE_RIGID)
				breaker_shape_parent.mode = RigidBody2D.MODE_RIGID
				breaker_shape_parent.gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			yield(get_tree().create_timer(random_delay), "timeout")
			var animation_tween = get_tree().create_tween()
			animation_tween.tween_property(breaker_shape_parent, "modulate:a", 0, random_duration).set_delay(random_delay)
			animation_tween.tween_callback(breaker_shape_parent, "queue_free")
		MOTION.MINIMIZE:
			if breaker_shape_parent is RigidBody2D:
				#				breaker_shape_parent.set_deferred("mode", RigidBody2D.MODE_RIGID)
				breaker_shape_parent.mode = RigidBody2D.MODE_RIGID
				breaker_shape_parent.gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			yield(get_tree().create_timer(random_delay), "timeout")
			var animation_tween = get_tree().create_tween()
			animation_tween.tween_property(breaker_shape_parent, "scale", Vector2.ZERO, random_duration).set_delay(random_delay)
			animation_tween.tween_callback(breaker_shape_parent, "queue_free")
		MOTION.CRACK:
			pass


func _on_change_shape_edge_width(new_width: float):

	if edge_shape:
		var offset_polygons: Array = Geometry.offset_polygon_2d(edge_shape.polygon, new_width)
		if offset_polygons.size() == 1:
			edge_shape.polygon = offset_polygons[0]
			shape_edge_width = new_width # šele tukaj, da ne morem setat, če je error
		else:
			shape_edge_width = new_width / 2
			#			printt("Breaker offset to big (multiple inset_polygons) ... polovička", shape_edge_width)


func _on_VisibilityNotifier2D_screen_exited() -> void:

	print("Out of screen")
