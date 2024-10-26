extends RigidBody2D
# breaker je cel, chunk je odlomljeni del breakerja, debry so delčki narezanega chunka


signal cracks_animated 

enum MATERIAL {UNBREAKABLE, STONE, GLASS, } # GHOST, WOOD, METAL, TILES, SOIL
export (MATERIAL) var current_material: int = MATERIAL.STONE

enum HIT_BY_TYPE {KNIFE, HAMMER, PAINT, ROCKET} # _temp ... ujema se z demotom
var current_hit_by_type: int = HIT_BY_TYPE.KNIFE

enum MOTION {STILL, EXPLODE, FALL, MINIMIZE, DISSAPEAR} # SLIDE, CRACK, SHATTER
var current_motion: int = MOTION.STILL setget _change_motion

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS, NONE}

var breaker_base_polygon: PoolVector2Array = [] setget _change_breaker_polygon # !!! polygon menjam samo prek tega setgeta
var crack_color: Color = Color.black
export (int) var crack_width: float = 0 setget _change_crack_width
var cut_breaks_shapes: int = 1 # nobena, spodnja ali vse
var breaking_round: int = 1 # kolikokrat je bil brejker že nalomljen
var origin_global_position: Vector2 # se inherita skozi vse spawne
var current_breaker_velocity: Vector2 = Vector2.ZERO

# polygons
onready var breaker_base: Polygon2D = $BreakerBase
onready var breaker_crack: Polygon2D = $BreakerBase/BreakerCrack
onready var slicer_shape: Polygon2D = $Slicer
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# nodes
onready var breaker_parent: Node = get_parent()
onready var crackers_mask: ColorRect = $CrackersMask
onready var crackers_parent: Node2D = crackers_mask.get_node("Crackers")
onready var operator: Node = $Operator
onready var custom_split_origin: Position2D = $CustomSplitOrigin
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var Breaker: PackedScene = load("res://game/breaker/Breaker.tscn")
onready var Cracker: PackedScene = preload("res://game/breaker/Cracker.tscn")

# debug
var debug_solo_mode: bool = false


func _input(event: InputEvent) -> void:
	
	if debug_solo_mode and Input.is_action_just_pressed("no1") and debug_solo_mode:
		on_hit(custom_split_origin.position, slicer_shape)
	if Input.is_action_just_pressed("no2"):
		slice_chunks([slicer_shape.polygon])

	
func _ready() -> void:
	
	add_to_group("Breakers")
	
	if get_parent() == get_tree().root:
		debug_solo_mode = true
		
	# če ni spawnan
	if breaker_base_polygon.empty():
		self.breaker_base_polygon = breaker_base.polygon
	# če je spawnan
	else:
		self.breaker_base_polygon = breaker_base_polygon
	self.current_motion = current_motion
	self.crack_width = crack_width			
	
	breaker_crack.color =  crack_color
	slicer_shape.hide()


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	current_breaker_velocity = state.get_linear_velocity()
	
	
func on_hit(hit_vector, hit_by = null): #, hitting_parent: Node = breaker_parent):
	# opredelim: origin, smer in power
	
	if current_material == MATERIAL.UNBREAKABLE:
		return
	
	if hit_vector is Line2D: # cut
		current_hit_by_type = HIT_BY_TYPE.KNIFE
		cut_it(hit_vector)
		return
	
	else:
		var hit_by_polygon: PoolVector2Array = slicer_shape.polygon
		if "collision_shape" in hit_by:
			hit_by_polygon = hit_by.collision_shape.polygon
		
		current_hit_by_type = HIT_BY_TYPE.KNIFE
		if "tool_type" in hit_by:
			current_hit_by_type = hit_by.tool_type
		
		# swipe hit  
		if hit_vector is PoolVector2Array:
			# dobim križajoči origin na robu ... hit vektor je pika začetka in pika konca, ker drugače se lahko zgodi, da ni zunaj
			var hit_pool_to_local: PoolVector2Array = [hit_vector[0] - global_position, hit_vector[1] - global_position]
			var intersection_point: Vector2
			var intersection_data: Array = operator.get_outline_intersecting_segment(hit_pool_to_local, breaker_base_polygon)
			if not intersection_data.empty():
				intersection_point = intersection_data[0]
			origin_global_position = intersection_point + global_position
			# power vector in obseg hit zone
			var power_vector: Vector2 = hit_vector[1] - origin_global_position
			var hit_shape_radius: float = operator.get_polygon_radius(hit_by_polygon)
			var power_to_radius_factor: float = power_vector.length() / hit_shape_radius
			var power_adapted_hit_polygon: PoolVector2Array = []
			for point in hit_by_polygon:
				var adapted_point: Vector2 = point * power_to_radius_factor
				power_adapted_hit_polygon.append(adapted_point)
			hit_by_polygon = power_adapted_hit_polygon
		
		# drop hit
		elif hit_vector is Vector2:
			origin_global_position = hit_vector

		var hit_by_shape = Polygon2D.new() # ... za transforms
		hit_by_shape.polygon = hit_by_polygon
		var transformed_hit_polygon: PoolVector2Array = operator.adapt_transforms_and_add_origin(hit_by_shape, origin_global_position)
		if debug_solo_mode:
			break_it(hit_by_polygon)
			return
		break_it(transformed_hit_polygon)


# BREJK (chunkization) ------------------------------------------------------------------------------------------------


func break_it(slicing_polygon: PoolVector2Array):
	
	var chunks_to_slice: Array = []
	
	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(breaker_base_polygon, slicing_polygon) # prazen je kadar se ne sekata ali pa je breaker znotraj šejpa (luknja)
	# break whole
	if clipped_polygons.empty(): # če slicer prekrije celoten shape > chunk
		print("clipped_polygons je prazen >> brejkam celega")
		chunks_to_slice.append(breaker_base_polygon)
		call_deferred("slice_chunks", [breaker_base_polygon], true)
	# break apart
	else:	
		# dobim chunk shape
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(slicing_polygon, breaker_base_polygon)
		if interecting_polygons.empty():  # zazih ... težko, da bilo prazno
			print("intersection empty")
		self.breaker_base_polygon = clipped_polygons.pop_front()
		
		# hole, chunk, new breaker
		for poly in clipped_polygons:
			# hole
			if Geometry.is_polygon_clockwise(poly): # luknja ... operiram glavni poligon
				var holed_polygons: Array = operator.apply_hole(breaker_base_polygon, poly)
				self.breaker_base_polygon = holed_polygons[0]
				break_it(holed_polygons[1])
				return
			# breaker
			else:
				spawn_breaker(poly)
		# chunks
		if not current_hit_by_type == HIT_BY_TYPE.PAINT:
			for poly in interecting_polygons: # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
				chunks_to_slice.append(poly)
	
		if not debug_solo_mode:
			call_deferred("slice_chunks", chunks_to_slice)
	
	breaking_round += 1

		
func cut_it(slice_line: Line2D, slicing_style: int = 0):

	if current_material == MATERIAL.UNBREAKABLE:
		return
			
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
				spawn_breaker(poly)
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
				spawn_breaker(poly, true)
		2:
			for poly in clipped_polygons:
				spawn_breaker(poly, true)	
			queue_free()

					
# SLAJS (debrization) -----------------------------------------------------------------------------------------------
	
			
func slice_chunks(chunk_polygons: Array, whole_breaker: bool = false, with_cracker: bool = true):

	var current_slicing_style: int = set_slicing_style()
	
	# _temp
	current_slicing_style = SLICE_STYLE.FRAGMENTS 
	with_cracker = true
	
	var spawned_chunks: Array = [] # da ji lahko potem zbriešm
	for chunk in chunk_polygons:
		
		var derby_polygons: Array
		
		match current_slicing_style:
			SLICE_STYLE.NONE:
				derby_polygons.append(chunk)
			SLICE_STYLE.GRID_SQ:
				var grid_sliced_polygons: Array = operator.slice_grid(chunk, 4)
				derby_polygons = grid_sliced_polygons[0]
				derby_polygons.append(grid_sliced_polygons[1])
			SLICE_STYLE.GRID_HEX:
				var grid_sliced_polygons: Array = operator.slice_grid(chunk, 4)
				derby_polygons = grid_sliced_polygons[0]
				derby_polygons.append(grid_sliced_polygons[1])
			SLICE_STYLE.FRAGMENTS:
				derby_polygons = split_chunk_to_polygons(chunk) # izbira stila glede na orodje in material
			SLICE_STYLE.BLAST:
				derby_polygons = split_chunk_to_polygons(chunk)
			
		if with_cracker:
			spawned_chunks.append(spawn_chunk(chunk))
			spawn_crackers(derby_polygons, chunk)
			yield(self, "cracks_animated")	
		spawn_debry(derby_polygons)
	
	for chunk in spawned_chunks:
		chunk.queue_free()
	
	if whole_breaker:
		queue_free()

	
func split_chunk_to_polygons(chunk_polygon: PoolVector2Array):
	# izbira stila glede na orodje in material	
	
	var origin_position: Vector2 = origin_global_position - global_position
	var origin_edge_index: int
	
	# dobim origin lokacijo glede na poligon
	var origin_location_on_shape: int = -1 # -1 = out, 1 = in, 0 = edge
	if Geometry.is_point_in_polygon(origin_position, chunk_polygon):
		origin_edge_index = operator.get_outline_segment_with_point(origin_position, chunk_polygon)
		if origin_edge_index == - 1: # -1 pomeni, da je znotraj poligona in ni na robu
			origin_location_on_shape = 1
		else:
			origin_location_on_shape = 0
	
	printt ("slice on origin location:", origin_location_on_shape)
	
	# slajsam glede na lokacijo ... drugi parametri še pridejo
	var sliced_chunk_polygons: Array
	match origin_location_on_shape:
		-1:
			#			var split_edge_length: int = 150
			#			chunk_polygon = operator.split_outline_to_length(chunk_polygon, split_edge_length)
			sliced_chunk_polygons = operator.triangulate_delaunay(chunk_polygon, -1, 10)
		0:
			# outline split
			var split_edge_length: int = 50
			chunk_polygon = operator.split_outline_to_length(chunk_polygon, split_edge_length)
			#			var split_count: int = 1 # _temp
			#			chunk_polygon = operator.split_outline_on_part(chunk_polygon, 0.5, split_count)
			# odstranim splitane pike na origin robu
			var origin_edge_end_point_index: int
			if origin_edge_index == chunk_polygon.size() - 1:
				origin_edge_end_point_index = 0
			else:
				origin_edge_end_point_index = origin_edge_index + 1
			for point_index in chunk_polygon.size(): 
				if point_index > origin_edge_index and point_index < origin_edge_end_point_index:
					chunk_polygon.remove(point_index)
			# vstavim origin point
			chunk_polygon.insert(origin_edge_index + 1, origin_position)
			# slajsam
			var origin_point_index: int = chunk_polygon.find(origin_position)
			sliced_chunk_polygons = operator.triangulate_daisy(chunk_polygon, origin_point_index)[0]
		1:
			var split_edge_length: int = 150
			chunk_polygon = operator.split_outline_to_length(chunk_polygon, split_edge_length)
			sliced_chunk_polygons = operator.slice_spiderweb(chunk_polygon)

	
	return sliced_chunk_polygons


# SPAWN ----------------------------------------------------------------------------------------------------------------
	
		
func spawn_breaker(new_braker_polygon: PoolVector2Array, spawn_and_slice: bool = false):
	
	var new_breaker = Breaker.instance()
	new_breaker.position = position
	new_breaker.name = "Breaker_Round%02d" % breaking_round
	breaker_parent.add_child(new_breaker)
	
	new_breaker.breaker_base.color = breaker_base.color
	# setget
	new_breaker.breaker_base_polygon = new_braker_polygon
	
	# če je cel za brejkat, potem mu spawnerj potegnem čez
	if spawn_and_slice:
		new_breaker.call_deferred("slice_chunks", [new_breaker.breaker_base_polygon], true)
		
	#	printt("new breaker", new_breaker, new_breaker.position)
		

func spawn_debry(debry_polygons: Array):
	
	for poly in debry_polygons:
		
		# centraliziram in globaliziram
		var centralized_spawn_position: Vector2 = position
		var centralized_poly: Array = operator.centralize_polygon_position(poly)
		poly = centralized_poly[0]
		centralized_spawn_position = centralized_poly[1]

		var new_breaker = Breaker.instance()
		new_breaker.name = "Breaker_Debry"
		new_breaker.position = centralized_spawn_position
		new_breaker.origin_global_position = origin_global_position
		breaker_parent.add_child(new_breaker)
		
		new_breaker.breaker_base.color = breaker_base.color
		# setgets
		new_breaker.crack_width = 2
		new_breaker.breaker_base_polygon = poly
		new_breaker.current_material = new_breaker.MATERIAL.UNBREAKABLE
		new_breaker.current_motion = new_breaker.MOTION.EXPLODE
		
		#		printt ("new debry breaker", new_debry.position, new_debry.debry_polygon[0], polygon[0], new_debry.get_parent())		
	
	
func spawn_chunk(new_chunk_polygon: PoolVector2Array):
	
	var new_poly = Polygon2D.new()
	new_poly.polygon = new_chunk_polygon
	new_poly.color = Color.white
	add_child(new_poly)
	
	return new_poly
		
			
func spawn_crackers(cracked_polygons: Array, chunk_polygon: PoolVector2Array):
	
	# setam creckers_rect končne vrednosti
	var chunk_far_points: Array = operator.get_polygon_far_points(chunk_polygon) # L-T-R-B
	crackers_mask.rect_position = Vector2(chunk_far_points[0].x, chunk_far_points[1].y)
	crackers_mask.rect_size = Vector2(chunk_far_points[2].x, chunk_far_points[3].y) - crackers_mask.rect_position

	for poly_index in cracked_polygons.size():
		var new_cracked_shape = Cracker.instance()
		new_cracked_shape.position -= crackers_mask.rect_position
		new_cracked_shape.name = "%s_Crackers" % name
		new_cracked_shape.polygon = cracked_polygons[poly_index]
		new_cracked_shape.cracker_color = breaker_base.color
		new_cracked_shape.crack_color = Color.black
		crackers_parent.add_child(new_cracked_shape)
		
	# animiram ... narjeno za hor wide
	# istočasno tweenam rect masko in pozicijo polignov ... tako ostanejo poligoni "pri miru"
	var rect_start_offset: Vector2 = Vector2.ZERO
	var rect_start_position: Vector2 = crackers_mask.rect_position + rect_start_offset
	var rect_start_scale: Vector2 = Vector2.ZERO
	
	# če ni origina, potem animiram po dolžini
	if not origin_global_position: # temp ... način crackers reveal
		rect_start_scale.x = crackers_mask.rect_size.x
	
	var reveal_time: float = 1
	var reveal_tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	reveal_tween.tween_property(crackers_mask, "rect_size", crackers_mask.rect_size, reveal_time).from(rect_start_scale)
	reveal_tween.parallel().tween_property(crackers_mask, "rect_position", crackers_mask.rect_position, reveal_time).from(rect_start_position)
	reveal_tween.parallel().tween_property(crackers_parent, "position", Vector2.ZERO, reveal_time).from(- rect_start_offset)
	yield(reveal_tween, "finished")
	
	emit_signal("cracks_animated")	
	
	# pucam krekerje
	for child in crackers_parent.get_children():
		child.queue_free()
		
	
# UTILITI ----------------------------------------------------------------------------------------------------------------
	

func set_slicing_style(sliced_by_type: int = current_hit_by_type):
	
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
	
	
func _change_motion(new_motion_state: int):
	
	current_motion =  new_motion_state
	
	# _temp
	if not current_motion == MOTION.STILL: 
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
		MOTION.DISSAPEAR:
			gravity_scale = 0
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var dissolve_tween = get_tree().create_tween()
			dissolve_tween.tween_property(self, "modulate:a", 0, random_duration).set_delay(random_delay)
		MOTION.CRACK:
			pass


func _change_crack_width(new_width: float):
	
	if breaker_crack:
		var offset_polygons: Array = Geometry.offset_polygon_2d(breaker_crack.polygon, new_width)
		if offset_polygons.size() == 1:
			breaker_crack.polygon = offset_polygons[0]
			crack_width = new_width # šele tukaj, da ne morem setat, če je error
		else:
			printt("Error! Offset to big ... multiple inset_polygons result", new_width)	
			#			breaker_crack.color = Color.red


func _exit_tree() -> void:
	
	if "bodies_to_slice" in breaker_parent: # _temp ... demo
		breaker_parent.bodies_to_slice.erase(self)


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()
