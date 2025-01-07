extends RigidBody2D
# breaker je cel, chunk je odlomljeni del breakerja, debry so delčki narezanega chunka

signal cracks_animated

enum MATERIAL {STONE, GLASS, GRAVEL, WOOD } # GHOST, WOOD, METAL, TILES, SOIL
export (MATERIAL) var current_material: int = MATERIAL.STONE

enum MOTION {STILL, EXPLODE, FALL, MINIMIZE, DISSAPEAR} # SLIDE, CRACK, SHATTER

enum HIT_BY_TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # _temp ... ujema se z demotom
var current_hit_by_type: int = HIT_BY_TYPE.KNIFE

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS, NONE}
var current_motion: int = MOTION.STILL setget _change_motion

export var height = 500 # setget
export var elevation = 0 # setget
export var transparency: float = 1 # setget
export var is_breakable: bool = true
export (int) var crack_width: float = 0 setget _change_crack_width

var breaker_base_polygon: PoolVector2Array = [] setget _change_breaker_polygon # !!! polygon menjam samo prek tega setgeta

var crack_color: Color = Color.black
var cut_breaks_shapes: int = 1 # nobena, spodnja ali vse
var breaking_round: int = 0 # kolikokrat je bil brejker že nalomljen
var break_origin_global: Vector2 = Vector2.ZERO # se inherita skozi vse spawne
var current_breaker_velocity: Vector2 = Vector2.ZERO

# polygons
onready var breaker_base: Polygon2D = $BreakerBase
onready var breaker_crack: Polygon2D = $BreakerBase/BreakerCrack
onready var breaker_tool: Polygon2D = $BreakerTool
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# nodes
export (NodePath) var breaker_world_path: String # če je svet kaj drugega kot njegov parent
onready var breaker_parent: Node = get_parent()
onready var operator: Node = $Operator
onready var Breaker: PackedScene = load("res://game/level/breakers/breaker/Breaker.tscn")
onready var Crackers: PackedScene = preload("res://game/level/breakers/breaker/Crackers.tscn") # krekerji so po animaciji spucani

# neu ... za razmerje brejkanja
enum BREAK_SIZE {XSMALL, SMALL, MEDIUM, LARGE, XLARGE}
var current_break_size: int = BREAK_SIZE.MEDIUM


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		pass
	elif Input.is_action_just_pressed("no2"):
		_slice_chunks([breaker_tool.polygon])


func _ready() -> void:

	# določim svet spawnanja
	if breaker_world_path:
		breaker_parent = get_node(breaker_world_path)

	# če ni podana oblika, izbere defaultno
	if breaker_base_polygon.empty():
		self.breaker_base_polygon = breaker_base.polygon
	# če je podana oblika, jo prevzame
	else:
		self.breaker_base_polygon = breaker_base_polygon

	self.current_motion = current_motion
	self.crack_width = crack_width
	breaker_crack.color =  crack_color
	breaker_tool.hide()

	# SS2D breaker
	# SS2D shape spremeni brejker koližn in signalizira spremembo brejkerju
	# brejker spremeni bazna oblika
	# po prejkerju se spremeni senčka
	if has_node("SS2D_Shape_Closed"):
		$SS2D_Shape_Closed.connect("on_dirty_update", self, "_on_SS2D_dirty_update") # po spremembi, ko je vse apdejtano
		$SS2D_Shape_Closed.hide()
	elif has_node("SS2D_Shape_Open"):
		$SS2D_Shape_Open.connect("on_dirty_update", self, "_on_SS2D_dirty_update") # po spremembi, ko je vse apdejtano
		$SS2D_Shape_Open.hide()


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	current_breaker_velocity = state.get_linear_velocity()


func on_hit(hitting_node: Node2D, hit_global_position: Vector2): # shape je lahko: polygon2D, coližn shape poly, ... če se kaj pojavi vneseš tukaj

#	break_origin_global = Vector2.ZERO
#	printt ("origin", break_origin_global, hitting_node.position, hitting_node.global_position)

	# opredelim data za celotno slajsanje: origin, smer, območje vpliva in moč

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
	var intersection_vector_start: Vector2 = hit_global_position - position
	var intersection_vector_end: Vector2 = intersection_vector_start + hit_by_direction * influence_radius
	var intersection_vector_pool: PoolVector2Array = [intersection_vector_start, intersection_vector_end]
	var intersection_data: Array = operator.get_outline_intersecting_segments(intersection_vector_pool, breaker_base_polygon) # [[vector2, index], ...]
	var intersection_point: Vector2

	if intersection_data.empty():
		# poiščem najbližjo štartni točki
		var closest_point_on_closest_edge: Vector2 = operator.get_outline_segment_closest_to_point(intersection_vector_start, breaker_base_polygon)[1]
		intersection_point = closest_point_on_closest_edge
		printt("No intersection on hit vector ...  new closest point", intersection_point, intersection_vector_start)
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
	break_origin_global = intersection_point + global_position

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
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_base_polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	breaking_round += 1

	# break whole
	if clipped_polygons.empty(): # če slicer prekrije celoten shape > chunk
		print("Clipped_polygons je prazen >> brejkam celega")
		chunks_to_slice.append(breaker_base_polygon)
		call_deferred("_slice_chunks", [breaker_base_polygon], true)
	# break apart
	else:
		# dobim chunk shape
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_base_polygon)
		if interecting_polygons.empty():  # zazih ... težko, da bilo prazno
			printt("Intersection empty ... no chunks. Clipped size ", clipped_polygons.size())
		self.breaker_base_polygon = clipped_polygons.pop_front()

		# hole, chunk, new breaker
		for poly in clipped_polygons:
			# hole
			if Geometry.is_polygon_clockwise(poly): # luknja ... operiram glavni poligon
				var holed_polygons: Array = operator.apply_hole(breaker_base_polygon, poly)
				self.breaker_base_polygon = holed_polygons[0]
				_break_it(holed_polygons[1])
				return
			# breaker
			else:
				_spawn_new_breaker(poly)
		# chunks
		if not current_hit_by_type == HIT_BY_TYPE.PAINT:
			for poly in interecting_polygons: # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				chunks_to_slice.append(poly)

		call_deferred("_slice_chunks", chunks_to_slice)


func _cut_it(slice_line: Line2D):

	# adaptiram pozicijo poligon ... kot, da bi bil na poziciji cutting polija
	var slicing_line_adapted: PoolVector2Array = []
	for point in slice_line.points:
		# od globalne pozicije pike odštejem globalno pozicijo breakerja
		var point_to_local_position: Vector2 = point - position
		slicing_line_adapted.append(point_to_local_position)

	# je šel cut skozi?
	var cut_is_successful: bool = true
	for point in [slicing_line_adapted[0], slicing_line_adapted[slicing_line_adapted.size()-1]]:
		if Geometry.is_point_in_polygon(point, breaker_base_polygon):
			cut_is_successful = false
			return

	# odebelim linijo in jo klipam kot poligon
	var split_line_offset: float = 1
	var fat_split_line: PoolVector2Array = Geometry.offset_polyline_2d(slicing_line_adapted, split_line_offset)[0]
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_base_polygon, fat_split_line)

	# spawnam
	cut_breaks_shapes = 1
	match cut_breaks_shapes:
		0:
			self.breaker_base_polygon = clipped_polygons.pop_front()
			for poly in clipped_polygons:
				_spawn_new_breaker(poly)
		1:
			# opredelim index najvišjega, ki ga ostane trnueten braker
			var highest_center_y: float = 0
			var highest_polygon_index: int = 0
			for poly in clipped_polygons:
				var poly_center: Vector2 = operator.get_polygon_center(poly)
				if poly_center.y < highest_center_y or highest_center_y == 0 : # najvišji ima najnižji y
					highest_center_y = poly_center.y
					highest_polygon_index = clipped_polygons.find(poly)
			self.breaker_base_polygon = clipped_polygons.pop_at(highest_polygon_index)
			for poly in clipped_polygons:
				_spawn_new_breaker(poly, true)
		2:
			for poly in clipped_polygons:
				_spawn_new_breaker(poly, true)
			queue_free()


# SLAJS (debrization) -----------------------------------------------------------------------------------------------


func _slice_chunks(chunk_polygons: Array, whole_breaker: bool = false, with_crackers: bool = true):

#	var current_slicing_style: int = _get_slicing_style()

	# _temp
	with_crackers = true

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
		if with_crackers:
			spawned_chunks.append(_spawn_chunk(chunk))
			var crackers_reveal
			var new_crackers = _spawn_cracers_mask(chunk_debry_polygons, chunk) # _temp ne dela s signalom, a bi bilo bolje
			#			yield(new_crackers, "cracks_animation_finished")
			yield(get_tree().create_timer(new_crackers.crackers_reveal_time), "timeout")
		for debry_polygon in chunk_debry_polygons:
			_spawn_new_breaker(debry_polygon, false, true)
#		_spawn_debry(chunk_debry_polygons)


	for chunk in spawned_chunks:
		chunk.queue_free()

	if whole_breaker:
		queue_free()


func _split_chunk_to_polygons(chunk_polygon: PoolVector2Array):
	# izbira stila glede na orodje in material

	var origin_position: Vector2 = break_origin_global - global_position
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
#			print("slice origin OUTSIDE")
			polygon_with_origin.append(origin_position)
#			sliced_chunk_polygons = operator.split_delaunay(chunk_polygon, 10)
		0: # edge ... splitam edge na origin točki
#			print("slice origin EDGE")
			polygon_with_origin.insert(origin_edge_index + 1, origin_position)
		1: # notri ... dodam origin
#			print("slice on origin INSIDE")
			polygon_with_origin.append(origin_position)
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


func _spawn_new_breaker(new_braker_polygon: PoolVector2Array, spawn_and_slice: bool = false, is_debry: bool = false):

	# spawn
	var new_breaker = Breaker.instance()
	if is_debry:
		# centraliziram polygon in globaliziram pozicijo
		var centralized_polygon_data: Array = operator.centralize_polygon_position(new_braker_polygon)
		var centralized_global_position: Vector2 = centralized_polygon_data[1] + position
		var centralized_breaker_polygon: PoolVector2Array = centralized_polygon_data[0]
		new_breaker.name =  name + "_Debry"
		new_braker_polygon = centralized_polygon_data[0]
		new_breaker.position = centralized_global_position
		new_breaker.is_breakable = false
		new_breaker.height = 0 # _temo debryshadows
		new_breaker.elevation = 0 # _temo debryshadows
	else:
		new_breaker.name = name + "_Round_%d" % breaking_round
		new_breaker.position = position
	breaker_parent.add_child(new_breaker)

	# setup
	if breaker_base.texture:
		_copy_texture_between_shapes(new_breaker.breaker_base, breaker_base)
		new_breaker.breaker_base.texture_offset = new_breaker.position - position # ne-debry je ZERO
	new_breaker.breaker_base.color = breaker_base.color
	new_breaker.break_origin_global = break_origin_global # za animacijo debryja

	# setgets ... mora bit po spawnu, da se izvede setget
	if is_debry: # _temp
		new_breaker.crack_width = 2
		#		new_breaker.current_motion = new_breaker.MOTION.STILL
		new_breaker.current_motion = new_breaker.MOTION.EXPLODE
	new_breaker.breaker_base_polygon = new_braker_polygon
	if spawn_and_slice:
		new_breaker.call_deferred("_slice_chunks", [new_breaker.breaker_base_polygon], true)


func _spawn_chunk(new_chunk_polygon: PoolVector2Array):

	var new_poly: Polygon2D = Polygon2D.new()
	new_poly.polygon = new_chunk_polygon
	new_poly.color = breaker_base.color
	add_child(new_poly)

	if breaker_base.texture:
		_copy_texture_between_shapes(new_poly, breaker_base)

	return new_poly


func _spawn_cracers_mask(cracked_polygons: Array, chunk_polygon: PoolVector2Array):

	var new_cracers = Crackers.instance()
	new_cracers.breaker_position =  position
	new_cracers.break_origin_global = break_origin_global
	new_cracers.cracked_polygons = cracked_polygons
	new_cracers.chunk_polygon = chunk_polygon
	new_cracers.breaker_shape = breaker_base
	add_child(new_cracers)

	return new_cracers


#func _spawn_crackers(cracked_polygons: Array, chunk_polygon: PoolVector2Array, new_cracers_mask):
#
#	var crackers_parent = new_cracers_mask.get_node("Crackers")
#
#	# chunk rect za animacijo maske
#	var chunk_far_points: Array = operator.get_polygon_far_points(chunk_polygon) # L-T-R-B
#	var chunk_position: Vector2 = Vector2(chunk_far_points[0].x, chunk_far_points[1].y)
#	var chunk_size: Vector2 = Vector2(chunk_far_points[2].x, chunk_far_points[3].y) - chunk_position
#
#	for poly_index in cracked_polygons.size():
#		var new_cracker: Polygon2D = Cracker.instance()
#		new_cracker.position -= chunk_position
#		new_cracker.polygon = cracked_polygons[poly_index]
#		new_cracker.name = "%s_Crackers" % name
#		new_cracker.cracker_color = breaker_base.color
#		new_cracker.crack_color = Color.black
#		crackers_parent.add_child(new_cracker)
#
#		if breaker_base.texture:
#			_copy_texture_between_shapes(new_cracker, breaker_base)
#
#	# pozicije za animacijo
#	var start_mask_size: Vector2 # lahko je 0 ali pa hor / ver razširjena
#	var start_mask_position: Vector2 # začne v slice-originu v breakerju slice z size 0
#	var start_crackers_position: Vector2 # razlika med začetnoin končno pozicijo maske (slice-origin pos in chunk pos)
#	var end_mask_position: Vector2 = chunk_position # pozicija izvora znotraj brejkerja
#	var end_mask_size: Vector2 = chunk_size
#	var end_crackers_position: Vector2 = Vector2.ZERO # konča na svoji def poziciji znotraj maske (0,0)
#
#	if break_origin_global:
#		start_mask_size = Vector2.ZERO
#		start_mask_position = break_origin_global - position # origin pozicija lokalno
#		start_crackers_position = end_mask_position - start_mask_position
#	else:
#		start_mask_position = chunk_position # pozicija izvora znotraj brejkerja
#		start_mask_size = Vector2(end_mask_size.x, 0)
#		start_crackers_position = crackers_parent.position
#
#	# postavim
#	crackers_parent.position = start_crackers_position
#	new_cracers_mask.rect_position = start_mask_position
#	new_cracers_mask.rect_size = start_mask_size
#
#	# animiram istočasno tweenam rect masko in crackers parent ... crackerji zgledajo pri miru
#	var reveal_time: float = 0.5
#	var reveal_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_QUART)
#	reveal_tween.tween_property(new_cracers_mask, "rect_size", end_mask_size, reveal_time)
#	reveal_tween.parallel().tween_property(new_cracers_mask, "rect_position", end_mask_position, reveal_time)
#	reveal_tween.parallel().tween_property(new_cracers_mask, "position", end_crackers_position, reveal_time)
#	yield(reveal_tween, "finished")
#
#	emit_signal("cracks_animated")
#
#	# pucam krekerje po animaciji
#	for child in crackers_parent.get_children():
#		child.queue_free()


#func _spawn_crackers_orig(cracked_polygons: Array, chunk_polygon: PoolVector2Array):
#
#	# chunk rect za animacijo maske
#	var chunk_far_points: Array = operator.get_polygon_far_points(chunk_polygon) # L-T-R-B
#	var chunk_position: Vector2 = Vector2(chunk_far_points[0].x, chunk_far_points[1].y)
#	var chunk_size: Vector2 = Vector2(chunk_far_points[2].x, chunk_far_points[3].y) - chunk_position
#
#	for poly_index in cracked_polygons.size():
#		var new_cracker: Polygon2D = Cracker.instance()
#		new_cracker.position -= chunk_position
#		new_cracker.polygon = cracked_polygons[poly_index]
#		new_cracker.name = "%s_Crackers" % name
#		new_cracker.cracker_color = breaker_base.color
#		new_cracker.crack_color = Color.black
#		crackers_parent.add_child(new_cracker)
#
#		if breaker_base.texture:
#			_copy_texture_between_shapes(new_cracker, breaker_base)
#
#	# pozicije za animacijo
#	var start_mask_size: Vector2 # lahko je 0 ali pa hor / ver razširjena
#	var start_mask_position: Vector2 # začne v slice-originu v breakerju slice z size 0
#	var start_crackers_position: Vector2 # razlika med začetnoin končno pozicijo maske (slice-origin pos in chunk pos)
#	var end_mask_position: Vector2 = chunk_position # pozicija izvora znotraj brejkerja
#	var end_mask_size: Vector2 = chunk_size
#	var end_crackers_position: Vector2 = Vector2.ZERO # konča na svoji def poziciji znotraj maske (0,0)
#
#	if break_origin_global:
#		start_mask_size = Vector2.ZERO
#		start_mask_position = break_origin_global - position # origin pozicija lokalno
#		start_crackers_position = end_mask_position - start_mask_position
#	else:
#		start_mask_position = chunk_position # pozicija izvora znotraj brejkerja
#		start_mask_size = Vector2(end_mask_size.x, 0)
#		start_crackers_position = crackers_parent.position
#
#	# postavim
#	crackers_mask.rect_position = start_mask_position
#	crackers_mask.rect_size = start_mask_size
#	crackers_parent.position = start_crackers_position
#
#	# animiram istočasno tweenam rect masko in crackers parent ... crackerji zgledajo pri miru
#	var reveal_time: float = 0.5
#	var reveal_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_QUART)
#	reveal_tween.tween_property(crackers_mask, "rect_size", end_mask_size, reveal_time)
#	reveal_tween.parallel().tween_property(crackers_mask, "rect_position", end_mask_position, reveal_time)
#	reveal_tween.parallel().tween_property(crackers_parent, "position", end_crackers_position, reveal_time)
#	yield(reveal_tween, "finished")
#
#	emit_signal("cracks_animated")
#
#	# pucam krekerje
#	for child in crackers_parent.get_children():
#		child.queue_free()


# UTILITI ----------------------------------------------------------------------------------------------------------------


func _on_SS2D_dirty_update(): # samo SS2D breaker

	self.breaker_base_polygon = collision_shape.polygon


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


func _change_breaker_polygon(new_breaker_polygon: PoolVector2Array):

	breaker_base_polygon = new_breaker_polygon
	breaker_base.polygon = breaker_base_polygon
	breaker_crack.polygon = breaker_base_polygon
	self.crack_width = crack_width
	collision_shape.set_deferred("polygon", breaker_base_polygon)

	$PolygonShadow._update_shadow_polygon()


func _change_motion(new_motion_state: int):

	current_motion =  new_motion_state

	# _temp
	if not current_motion == MOTION.STILL:
		current_motion =  MOTION.MINIMIZE

	match current_motion:
		MOTION.STILL:
#			mode = RigidBody2D.MODE_STATIC
			set_deferred("mode", RigidBody2D.MODE_STATIC)
		MOTION.FALL:
			gravity_scale = 1
			set_deferred("mode", RigidBody2D.MODE_RIGID)
		MOTION.EXPLODE:
			gravity_scale = 0
#			mode = RigidBody2D.MODE_RIGID
			set_deferred("mode", RigidBody2D.MODE_RIGID)
			linear_damp = 2
			var force_vector = global_position - break_origin_global
			apply_central_impulse(force_vector * 20)
		MOTION.DISSAPEAR:
			set_deferred("mode", RigidBody2D.MODE_RIGID)
			gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var dissolve_tween = get_tree().create_tween()
			dissolve_tween.tween_property(self, "modulate:a", 0, random_duration).set_delay(random_delay)
			yield(dissolve_tween, "finished")
			queue_free()
		MOTION.MINIMIZE:
			set_deferred("mode", RigidBody2D.MODE_RIGID)
			gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var minimize_tween = get_tree().create_tween()
			minimize_tween.tween_property(self, "scale", Vector2.ZERO, random_duration).set_delay(random_delay)
			yield(minimize_tween, "finished")
			queue_free()
		MOTION.CRACK:
			pass


func _change_crack_width(new_width: float):

	if breaker_crack:
		var offset_polygons: Array = Geometry.offset_polygon_2d(breaker_crack.polygon, new_width)
		if offset_polygons.size() == 1:
			breaker_crack.polygon = offset_polygons[0]
			crack_width = new_width # šele tukaj, da ne morem setat, če je error
		else:
			crack_width = new_width / 2
			#			printt("Breaker offset to big (multiple inset_polygons) ... polovička", crack_width)


func _exit_tree() -> void:

	if "bodies_to_slice" in breaker_parent: # _temp ... demo
		breaker_parent.bodies_to_slice.erase(self)


func _on_VisibilityNotifier2D_screen_exited() -> void:

	if get_parent().name == "BreakingGame":
		queue_free()
