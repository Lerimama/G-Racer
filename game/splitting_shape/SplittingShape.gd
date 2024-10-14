extends Node2D


var shape_poly_points: PoolVector2Array = [] # če podam ob spawnanju, se aplicira na glavno obliko

onready var shape_poly: Polygon2D = $ShapePoly
onready var splitting_poly: Polygon2D = $SplittingPoly

# debug
var move_on = true

func _input(event: InputEvent) -> void:
	
	# case slice
	
	if Input.is_action_just_pressed("no1"):
		first_split(shape_poly, splitting_poly)
#		var split_polygons: Array = first_split(shape_poly, splitting_poly)
#		var main_shape: PoolVector2Array = split_polygons[0]
#		var leftovers: Array = split_polygons[1]
#		var split_shape: PoolVector2Array = split_polygons[2]
#		spawn_polygon_from_points(main_shape, Color.blue, "new_shape")
#		for leftover in leftovers:
#			spawn_polygon_from_points(leftover, Color.red, "new_shape_leftover")		
#		spawn_polygon_from_points(split_shape, Color.yellow, "new_shape")
	if Input.is_action_just_pressed("no2"):
		pass
	if Input.is_action_just_pressed("no3"):
		pass
	if Input.is_action_just_pressed("no4"):
		pass
	if Input.is_action_just_pressed("no5"):
		pass
		
	
			
func _ready() -> void:
	
	if not shape_poly_points.empty():
		shape_poly.polygon = shape_poly_points



func _process(delta: float) -> void:
	
	if move_on:
		global_position.x += 1
	
		
# najprej splitam obe obliki
# najprej klipam da dobim glavne oblike
# potem intersektam, da dobim odlomljeno obliko

# možni rezultati na glavnem poligonu:
# en klipan > glavni prevzame šejp
# več klipanih > glavni prevzame šejp, ostali postanejo samostojni (in jih tudi odnese)
	# en neklipan, ker ima luknjo
	# noben klipan, ker se ne križa

func first_split(base_polygon: Polygon2D, clip_polygon: Polygon2D):
	
	var base_points: PoolVector2Array = base_polygon.polygon
	var clip_points: PoolVector2Array = clip_polygon.polygon
	base_polygon.hide()
	clip_polygon.hide()	
	
	# klipam in dobim shape poligone
	var clipped_polygons: Array = Geometry.clip_polygons_2d(base_points, clip_points)
	var clipped_base_polygon: PoolVector2Array = clipped_polygons.pop_front()
	
	# intersektam in dobim odlomljeni del
	var split_polygons: Array = Geometry.intersect_polygons_2d(clip_points, base_points)
	var split_part: PoolVector2Array = split_polygons[0]
	
#	return [clipped_base_polygon, clipped_polygons, split_part]
	popedenaj(clipped_base_polygon, clipped_polygons, split_part)
	


func popedenaj(clipped_base_polygon, clipped_polygons, split_part):	
	
	# glavni poligon
	shape_poly.polygon = clipped_base_polygon
	shape_poly.color = Color.purple
	shape_poly.show()
	splitting_poly.queue_free()
	
	
	# main leftovers postanejo samostojni
	var spawning_parent = get_tree().root
	for poly in clipped_polygons:
		spawn_splitting_shapes(poly, Color.green, "new_shape", spawning_parent)
	
	# razbiješ split part na manjše
	

#	var clipped_shape_leftovers: Array = clipped_polygons.pop_front()
	
		
		
		
#	printt ("cliped", clipped_polygons, position_diff)
#onready var SplittingShape: PackedScene = preload("res://game/level/SplittingShape.tscn")


func spawn_splitting_shapes(polygon_points: PoolVector2Array, new_color: Color = Color.red, new_name: String = "", spawn_parent: Node2D = self):
	
	var SplittingShape: PackedScene = Pro.splitting_shape
	
#	var new_splitting_shape = SplittingShape.instance()
	var new_splitting_shape = duplicate()
	new_splitting_shape.shape_poly_points = polygon_points
	if not new_name.empty():
		new_splitting_shape.name = new_name
	get_tree().root.add_child(new_splitting_shape)
	
	new_splitting_shape.shape_poly.color = new_color
	printt("new_poly", new_splitting_shape.position, new_splitting_shape.get_parent())
	
	return new_splitting_shape
	
	
func spawn_polygon_from_points(polygon_points: PoolVector2Array, polygon_color: Color = Color.red, polygon_name: String = "", spawn_parent: Node2D = self):
		
	var new_polygon = Polygon2D.new()
	new_polygon.polygon = polygon_points
	new_polygon.color = polygon_color
	if not polygon_name.empty():
		new_polygon.name = polygon_name
	spawn_parent.add_child(new_polygon)
	new_polygon.move_on = true
	
	printt("new_poly", new_polygon.position)
	
	return new_polygon
	
	
#	spawn_setup_polygons([clipped_base], Color.blue)
#	if len(clippings) > 1:
#		spawn_setup_polygons([clippings[1]], Color.red, false)
	
#	color.a = 0
	
# pozicijo adaptiram na pozicijo glavnega ... trenutno ne dela
func adapt_position_difference(base_polygon, clip_polygon):	
	
	var position_diff: Vector2 = clip_polygon.global_position - base_polygon.global_position
	if not position_diff.length() == 0:
		var new_poly_points: PoolVector2Array = clip_polygon.polygon
		for point in new_poly_points:	
			point = point + position_diff
#		clip_polygon.polygon = new_poly_points
