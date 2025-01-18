extends Polygon2D


export (NodePath) var shadow_casting_polygon_path: String
#export var node_height: float = 30 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 100 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.2

onready var shadow_casting_node: Node2D = get_node(shadow_casting_polygon_path)
#onready var shadow_direction: Vector2 = Vector2(700,45).normalized() setget _update_shadow_direction # odvisno od igre
#onready var shadow_length: float = 0 setget _update_shadow_length  # odvisno od igre ...  "višina" vira svetlobe, 0 je default
onready var shadow_length: float = Rfs.game_manager.shadows_length setget _update_shadow_length  # odvisno od igre ...  "višina" vira svetlobe, 0 je default
onready var shadow_direction: Vector2 = Rfs.game_manager.shadows_direction.normalized() setget _update_shadow_direction # odvisno od igre

# owner
onready var shadow_owner: Node2D = get_parent()

func _ready() -> void:

	# popravim rotacijo sence glede na globalno rotacijo poligona
	shadow_direction = shadow_direction.rotated(- global_rotation)
	if shadow_casting_node:
		_update_shadow_polygon()
	else:
		printerr ("No shadow casting node for: ", self)
		hide()


func _update_shadow_polygon():

	if shadow_owner.height == 0:
		hide()
	else:
		var original_shadow_extreme_points: Array = _get_extreme_polygon_points()
		var new_shadow_polygon: PoolVector2Array = _create_new_shadow_polygon(original_shadow_extreme_points[0], original_shadow_extreme_points[1])
		set_deferred("polygon", new_shadow_polygon)


func _get_extreme_polygon_points(checking_line_length: float = 2000):

	var check_vector: Vector2 = shadow_direction * checking_line_length
	var checking_polyline: PoolVector2Array = [- check_vector/2, check_vector/2] # točke so zamaknjene > center je VectorZERO
	Mts.spawn_line_2d(checking_polyline[0], checking_polyline[1], shadow_owner, Color.red)

	# center poligona
	var casting_node_hull: PoolVector2Array = Geometry.convex_hull_2d(shadow_casting_node.polygon)
	var all_points_sum: Vector2 = Vector2.ZERO
	for hull_point_index in casting_node_hull.size() - 1: # zadnja pika v hull je eneaka prvi in je ne upoštevam
		all_points_sum += casting_node_hull[hull_point_index]
	var center = all_points_sum / (casting_node_hull.size() - 1)
	Mts.spawn_indikator(position + center, Color.red, 0,shadow_owner)

#	var center: = Mts.centra
	# preverim točke poligona, ki so najdlje obe smeri
	var checking_polyline_normal: = checking_polyline[1].rotated(deg2rad(90)) * checking_line_length # desna prvokotnica, gledano v smeri vektorja
	Mts.spawn_line_2d(Vector2.ZERO, checking_polyline_normal, shadow_owner, Color.red)

	var polygon_points_distances: Array = []
	var left_polygon_points_indexes: Array = []
	var right_polygon_points_indexes: Array = []

	# naberem distance v zaporedju točk poligona
	# naberem indexe točk levo in desno
	for point_index in shadow_casting_node.polygon.size():
		# poiščem dolžine pravokotnih vektorje do ogljišč
		var polygon_point = shadow_casting_node.polygon[point_index]
		var closest_point_on_line: Vector2 = Geometry.get_closest_point_to_segment_uncapped_2d(polygon_point, checking_polyline[0], checking_polyline[1])
		var distance_to_checking_line: float = (closest_point_on_line - polygon_point).length()
		polygon_points_distances.append(distance_to_checking_line)
		# dot produkt točke z checking normalo
		if checking_polyline_normal.dot(polygon_point) < 0:
			left_polygon_points_indexes.append(point_index)
		elif checking_polyline_normal.dot(polygon_point) > 0:
			right_polygon_points_indexes.append(point_index)

	# opredelim najbolj oddaljeni točki na levi in desni
	var max_distance: float = 0
	var extreme_left_point_index: int
	for point_index in left_polygon_points_indexes:
		var distance_to_line: float= polygon_points_distances[point_index]
		if distance_to_line > max_distance:
			max_distance = distance_to_line
			extreme_left_point_index = point_index
	Mts.spawn_indikator(position + shadow_casting_node.polygon[extreme_left_point_index], Color.blue, 0, shadow_owner)
	max_distance = 0
	var extreme_right_point_index: int
	for point_index in right_polygon_points_indexes:
		var distance_to_line: float= polygon_points_distances[point_index]
		if distance_to_line > max_distance:
			max_distance = distance_to_line
			extreme_right_point_index = point_index
	Mts.spawn_indikator(position + shadow_casting_node.polygon[extreme_right_point_index], Color.yellow, 0,shadow_owner)


	return [extreme_left_point_index, extreme_right_point_index]


func _create_new_shadow_polygon(extreme_left_point_index, extreme_right_point_index):
	# naredim senčko tako, da dupliciram original polygon
	# pozicije vseh polygonov morajo bit iste kot default senčka

	# offset shadow poligon ... dodam zamaknjene original točke
	var shadow_offset_in_direction: Vector2 = shadow_direction * (node_elevation + shadow_length)
	var offset_shadow_polygon: PoolVector2Array
	for point in shadow_casting_node.polygon:
		offset_shadow_polygon.append(point + shadow_offset_in_direction)

	# new shadow ... točke
	var new_shadow_polygon: PoolVector2Array = []

	# naberem indexe original poligona in jih prilagodim za zaporedno dodajanje
	# upoštevam, da je med zaporedjem lahko index 0
	var offset_polygon_indexes: Array = []
	for point_index in shadow_casting_node.polygon.size():
		offset_polygon_indexes.append(point_index)
	# nabrane indexe zamaknem za index extrem left
	for point_index in offset_polygon_indexes:
		offset_polygon_indexes.push_back(offset_polygon_indexes.pop_front())
		if point_index > extreme_left_point_index:
			break
	# back points
	var back_points_count: int = 0
	# preštejem točke od levega do desnega extrema
	for count in offset_polygon_indexes:
		if count == extreme_right_point_index:
			break
		back_points_count += 1
	# dodam točke iz original poligona
	for point_count in back_points_count:
		new_shadow_polygon.append(shadow_casting_node.polygon[offset_polygon_indexes[point_count]])
	new_shadow_polygon.append(shadow_casting_node.polygon[extreme_right_point_index])

	# front points
	var front_wall_points_count: int = shadow_casting_node.polygon.size() - back_points_count # je preostanek točk
	for point_count in front_wall_points_count:
		var point_index_in_polygon: int = back_points_count + point_count
		new_shadow_polygon.append(offset_shadow_polygon[offset_polygon_indexes[point_index_in_polygon]])
	new_shadow_polygon.append(offset_shadow_polygon[extreme_left_point_index])
	#	Mts.spawn_polygon_2d(new_shadow_polygon, shadow_owner, Color(Color.red, 0.5))

	var merged_new_to_offset: Array = Geometry.merge_polygons_2d(new_shadow_polygon, offset_shadow_polygon)
	var merged_to_shadow: Array = Geometry.merge_polygons_2d(shadow_casting_node.polygon,  merged_new_to_offset[0])
	#	Mts.spawn_polygon_2d(merged_shadow[0], shadow_owner, Color(Color.yellow, 0.5))

#	return merged_to_shadow[0]
	set_deferred("polygon", merged_to_shadow[0])


func _update_shadow_length(new_length: float):

	shadow_length = new_length
	_update_shadow_polygon()


func _update_shadow_direction(new_direction: Vector2):

	shadow_direction = new_direction.normalized()
	_update_shadow_polygon()
