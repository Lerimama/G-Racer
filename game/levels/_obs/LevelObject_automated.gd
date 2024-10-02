extends StaticBody2D


export var object_altitude: float = 100 setget _change_object_alt
export var shadow_direction: Vector2 = Vector2(-1,1) setget _change_shadow_dir # poberi iz igre

export var object_SSD_material: Resource
export var shadow_SSD_material: Resource
export var shade_SSD_material: Resource

onready var object_shape: Node2D = $ObjectShapeSSD
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

# neu
var shadow_resolution: float = 1


func _ready() -> void:

	# dodam glavni material
	object_shape.shape_material = object_SSD_material
	print(object_shape._points._points)
	print(object_shape.get_vertices())
	print(object_shape._curve)
	var shadow_poly: PoolVector2Array = update_shadow_polygon()
#	print (shadow_poly)
	# pike v šejpu
#	var shape_points = object_shape._points._points
#	for p in shape_points:
#		print (p)

	# naredim senco iz poligona
	var shadow_shape: Node2D = object_shape.duplicate()
	shadow_shape.name = "Shadow" 
	shadow_shape.collision_polygon_node_path = ""
	add_child(shadow_shape)
	move_child(shadow_shape, 0)
#	shadow_shape.position += shadow_direction * altitude
#	shadow_shape.modulate.a = 0.2
	
	var new_curve_points: SS2D_Point_Array = SS2D_Point_Array.new()
	for p in shadow_poly:
		new_curve_points.add_point(p)
	shadow_shape._update_curve(new_curve_points)
	shadow_shape.modulate.a = 0.5	
	
	# dodam bottom shade
	var shade_shape: Node2D = object_shape.duplicate()
	shade_shape.name = "Shade" 
	shade_shape.shape_material = shade_SSD_material
	shade_shape.collision_polygon_node_path = ""
	add_child(shade_shape)
	move_child(shade_shape, 0)
	
	
func update_shadow_polygon():
	
	# shadow polygons iz koližna
	# za vsak korak sence naredim in poligon kopijo koližna in ga dodam v array	
	# shadow polygons
	# za vsak korak sence naredim in poligon kopijo koližna in ga dodam v array
	var shapes_to_merge: Array
	var polygons_to_merge: Array
	
	for step in 100:
		var old_vector_points: PoolVector2Array = $CollisionPolygon2D.polygon
#		print("OP", old_vector_points)
		var new_vector_points: PoolVector2Array = []
		# točke v poligonu zamaknem pod kotom in jih pripišem novemu poligon poolu
		for point in old_vector_points:
			point += shadow_direction * shadow_resolution * step
			new_vector_points.insert(0, point)
#			new_vector_points.append(point)
		polygons_to_merge.append(new_vector_points)
#		print("NP", new_vector_points)
	
	# merganje
	# prvega in drugega vzamem ven, ju združim in združenega vrnem nazaj v to_merge array
	while polygons_to_merge.size() > 1:
		var first_poly: PoolVector2Array = polygons_to_merge.pop_front()
		var second_poly: PoolVector2Array = polygons_to_merge.pop_front()
		var new_merged_poly: Array = Geometry.merge_polygons_2d(first_poly, second_poly)
#		print(first_poly.size(), second_poly.size())
		for point in new_merged_poly[0]:
	#		print(Geometry.is_point_in_polygon(point,new_polygon.polygon) )
			if Geometry.is_point_in_polygon(point, new_merged_poly[0]):
				var id = new_merged_poly[0].find(point)
				new_merged_poly[0].remove(id)
		polygons_to_merge.append(new_merged_poly[0])
	
	var new_polygon: = Polygon2D.new()
	new_polygon.polygon = polygons_to_merge[0]
	add_child(new_polygon)
	
	
			
		
	
	new_polygon.modulate = Color.red	
	new_polygon.modulate.a = 0.2	
	move_child(new_polygon, 0)

	print (polygons_to_merge[0])
	return polygons_to_merge[0]


func _change_object_alt(new_altitude: float):
	object_altitude = new_altitude
	update_shadow_polygon()
	
	
func _change_shadow_dir(new_direction: Vector2):
	shadow_direction = new_direction
	update_shadow_polygon()
	
	
