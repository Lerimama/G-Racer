extends Polygon2D
# slice je zarezovanje
# split je dajanje narazen

enum SLICE_STYLE {BLAST, GRID_SQ, GRID_HEX}
var chunk_slice_style: int = SLICE_STYLE.BLAST #setget _change_slice_style

# ob spawnu
var chunk_polygon: PoolVector2Array = [] # ob spawnu
var origin_on_edge: bool = true # na spawn ali pa glede na to kje je točka
var origin_global_position: Vector2 # na spawn

var sliced_polygons: Array
onready var crackers_parent: Node2D = $Crackers
onready var slicing_operations: Node = $SlicingOperations
onready var DebryRigid: PackedScene = preload("res://game/breaker/DebryRigid.tscn")
onready var DebryArea: PackedScene = preload("res://game/breaker/DebryArea.tscn")
onready var Cracker: PackedScene = preload("res://game/breaker/Cracker.tscn")

var split_edge_count: int = 1
var split_edge_length: int = 100
var slice_side_count: int = 1


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no2"):
		if chunk_slice_style == SLICE_STYLE.BLAST:
			chunk_slice_style = SLICE_STYLE.BLAST
		slice_chunk()
	if Input.is_action_just_pressed("no3"):
		chunk_slice_style = SLICE_STYLE.GRID_SQ
		slice_chunk()
	if Input.is_action_just_pressed("no4"):
		chunk_slice_style = SLICE_STYLE.GRID_HEX
		slice_chunk()
	if Input.is_action_just_pressed("no5"):
		pass
		
		
func _ready() -> void:
	
	if not chunk_polygon.empty():
		polygon = chunk_polygon	
	
	
func slice_chunk():

	match chunk_slice_style:
		SLICE_STYLE.BLAST:
			slice_polygons()
			spawn_debry(sliced_polygons)
		SLICE_STYLE.GRID_SQ:
			slicing_operations.current_grid_style = slicing_operations.GRID_STYLE.SQUARE
			var grid_sliced_polygons = slicing_operations.slice_grid(polygon, false)
			spawn_crackers(grid_sliced_polygons[0], Color.cornflower)	
			spawn_crackers(grid_sliced_polygons[1], Color.cornflower, false)	 
		SLICE_STYLE.GRID_HEX:
			slicing_operations.current_grid_style = slicing_operations.GRID_STYLE.HEX
			var grid_sliced_polygons = slicing_operations.slice_grid(polygon)
			spawn_crackers(grid_sliced_polygons[0], Color.cornflower)	
			spawn_crackers(grid_sliced_polygons[1], Color.cornflower, false)	 
	
	#	color.a = 0 
	#	sliced_polygons.clear()	
	#	queue_free()


func slice_polygons():
	# 1. split edge
	# 2. insert_origin_point
	# 3. slice daisy
	# 3. slice horizontal
	
	origin_on_edge = false # debug
	
	var new_polygon: PoolVector2Array = polygon
	
	# FROM EDGE
	if origin_on_edge:
		
		# dobim podatke origin roba ... pred splitanjem
		var origin_edge_index: int = 5
		# ... manjka iskanje edga, najbližjega origin točki in točke na njem
		var lokacija_zadetka = origin_global_position
		
		# debug random edge na fifty fifty
		var start_edge_point: Vector2 = polygon[origin_edge_index]
		var end_edge_point: Vector2 = polygon[origin_edge_index + 1]
		var edge_vector: Vector2 = end_edge_point - start_edge_point
		var fixed_slice_origin: Vector2 = start_edge_point + edge_vector * 0.5 # + Vector2(50,-50) # debug ... offset, da je vidno		
	
		# SPLIT EDGE
		new_polygon = slicing_operations.split_outline_to_length(new_polygon, split_edge_length)
	
		# odstranim splitane pike na origin robu
		var new_start_edge_point_index: int = new_polygon.find(start_edge_point)
		var new_end_edge_point_index: int = new_polygon.find(end_edge_point)
		for point_index in new_polygon.size(): 
			if point_index > new_start_edge_point_index and point_index < new_end_edge_point_index:
				new_polygon.remove(point_index)
	
		# vstavim origin point
		new_polygon.insert(new_start_edge_point_index + 1, fixed_slice_origin)
		
		printt("sliced_polygons pre", sliced_polygons.size())
		
		# DAISY SLICE
		var origin_point_index: int = new_polygon.find(fixed_slice_origin)
		sliced_polygons = slicing_operations.triangulate_daisy(new_polygon, origin_point_index)
	# CENTRAL
	else:
		printt("sliced_polygons pre", sliced_polygons.size())
		new_polygon = slicing_operations.split_outline_to_length(new_polygon, split_edge_length)
		sliced_polygons = slicing_operations.slice_spiderweb(new_polygon)

	printt("sliced_polygons post", sliced_polygons.size())
	

# SPAWN ------------------------------------------------------------------------------------------------------------
	
		
func spawn_debry(debry_polygons: Array = sliced_polygons, new_color: Color = Color.blue):
		
	var new_debry_parent = get_parent() # debug ... spawn parents
	if not new_debry_parent == get_tree().root:
		new_debry_parent = get_parent().get_parent()
		
	for poly in debry_polygons:
		#		var new_debry: RigidBody2D = DebryRigid.instance()
		var new_debry: Node2D = DebryArea.instance()
		new_debry.name = "%s_Debry" % name
		new_debry.debry_polygon = poly
		new_debry.z_index = 10 # debug
		new_debry.position += global_position
		new_debry_parent.add_child(new_debry)
		new_debry.modulate.a = 0.4
		
		# printt ("new debry poly", new_debry.position, new_debry.debry_polygon[0], polygon[0], new_debry.get_parent())		
	
	color.a = 0 
	
	
func spawn_crackers(cracked_polygons: Array = sliced_polygons, new_color: Color = Color.black, clear_before: bool = true):
	
	if clear_before: # debug
		while crackers_parent.get_child_count() > 0:
			crackers_parent.get_children().pop_back().queue_free()	
	
	for poly_index in cracked_polygons.size():
		var new_cracked_shape = Cracker.instance()
		new_cracked_shape.name = "%s_Crackers" % name
		new_cracked_shape.polygon = cracked_polygons[poly_index]
		new_cracked_shape.z_index = 10 # debug
		new_cracked_shape.color = new_color
		crackers_parent.add_child(new_cracked_shape)
		new_cracked_shape.get_node("EdgeLine").points = new_cracked_shape.polygon
		randomize()
		if cracked_polygons.size() > 1: # debug
			new_cracked_shape.color.v = randf()
	
		# printt ("new cracked poly", new_polygon2d.color, new_polygon2d.polygon[0], polygon[0])		

	color.a = 0
