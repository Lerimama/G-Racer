extends RigidBody2D


var shape_poly_points: PoolVector2Array = [] # če podam ob spawnanju, se aplicira na glavno obliko
onready var shape_poly: Polygon2D = $ShapePoly
onready var cutting_poly: Polygon2D = $CuttingPoly
onready var breaker_parent = get_parent() # ni static, ker je lahko karkoli
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# za reset
onready var def_cutting_polygon: PoolVector2Array = cutting_poly.polygon
onready var def_cutting_poly_position: Vector2 = cutting_poly.position

var BrokenChunk: PackedScene = preload("res://game/breaker/BrokenChunk.tscn")


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("no1"):
		on_click()
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
		shape_poly.polygon = shape_poly_points
	collision_shape.polygon = shape_poly.polygon
	cutting_poly.hide()	
	

func on_hit(hitting_poly: Polygon2D, hit_position: Vector2):
	
	# prenosni poligon, ki ima pike adaptirane, kot, da bi bil na poziciji cutting polija
	var adapted_polygon: PoolVector2Array
	for point in hitting_poly.polygon:
		# od globalne pozicije pike odtejem globalno pozicijo breakerja
		var point_global_position: Vector2 = point * hitting_poly.scale + hit_position
		var hitting_point_position_against_breaker: Vector2 = point_global_position - position
		
		adapted_polygon.append(hitting_point_position_against_breaker)
	printt ("adapted", adapted_polygon)
	
	cutting_poly.polygon = adapted_polygon
	break_shape()
	
	
func on_click():
	
	# zamaknem točke glede nanjegov zamik
	# če še nima transform id (pozicije točk glede na lastno pozicjo	
	if cutting_poly.transform != Transform2D.IDENTITY:
		# The identity Transform2D with no translation, rotation or scaling applied. 
		# When applied to other data structures, IDENTITY performs no transformation.
		var transformed_polygon = cutting_poly.transform.xform(cutting_poly.polygon)
		cutting_poly.transform = Transform2D.IDENTITY
		cutting_poly.polygon = transformed_polygon	
	break_shape()
	
	
func break_shape():
	# najprej klipam da dobim glavne oblike
	# potem intersektam, da dobim odlomljeno obliko

	# klipam, da dobim shape
	var clipped_polygons: Array = Geometry.clip_polygons_2d(shape_poly.polygon, cutting_poly.polygon)
	
	# če ga prekrije, razpade base shape
	if clipped_polygons.empty():
		print ("prekriva")
		spawn_chunk(shape_poly.polygon)
	else:
		# intersektam, da dobim chunk template
		var interecting_polygons: Array = Geometry.intersect_polygons_2d(cutting_poly.polygon, shape_poly.polygon)
		if interecting_polygons.empty():
			print("intersection empty")
			return []
		finalize_breaking(clipped_polygons, interecting_polygons)

	
func finalize_breaking(clipped_base_polygons: Array, interecting_base_polygons: Array):	
	
	# adaptacija glavni poligon
	shape_poly.hide()
	shape_poly.polygon = clipped_base_polygons.pop_front()
	shape_poly.color = Color.purple
	collision_shape.polygon = shape_poly.polygon
	shape_poly.show()
	
	# če ni več poligonov, ne delam novih
#	if not clipped_base_polygons.empty():
#		return	
		
	# new breakers
	for poly in clipped_base_polygons:
		spawn_new_breaker(poly, Color.green)
	
	# chunks
	for poly_index in len(interecting_base_polygons): # zazih ... skoraj ni mogoče, da bi bil notri več kot eden
		var chunk_template: PoolVector2Array = interecting_base_polygons[poly_index]
		spawn_chunk(chunk_template)

	# reset this breaker
	
	cutting_poly.position = def_cutting_poly_position
	cutting_poly.polygon = def_cutting_polygon		
#	cutting_poly.show()	


func spawn_chunk(template_polygon: PoolVector2Array):
	
	var new_broken_chunk: Polygon2D = BrokenChunk.instance()
	new_broken_chunk.shape_polygon = template_polygon
	new_broken_chunk.color = Color.red
	add_child(new_broken_chunk)
	
	printt("new chunk", new_broken_chunk, new_broken_chunk.position)
		
		
func spawn_new_breaker(polygon_points: PoolVector2Array, new_color: Color = Color.red, new_name: String = "", spawn_parent = self):
	
	#	var NewBreaker: PackedScene = preload("res://game/breaker/Breaker.tscn")
	#	var new_splitting_shape = NewBreaker.instance()
	var new_breaker = duplicate()
	new_breaker.shape_poly_points = polygon_points
	if not new_name.empty():
		new_breaker.name = new_name
	breaker_parent.add_child(new_breaker)
	new_breaker.shape_poly.color = new_color
	
	# reset from this breaker
	new_breaker.cutting_poly.position = def_cutting_poly_position
	new_breaker.cutting_poly.polygon = def_cutting_polygon
	
	printt("new breaker", new_breaker, new_breaker.position, new_breaker.get_parent())
	

func finish_break():
	# reset breaking polyja
	cutting_poly.polygon = def_cutting_polygon
