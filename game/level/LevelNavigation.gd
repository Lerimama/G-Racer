extends NavigationPolygonInstance


export var nav_positions_density: float = 0 # v mreža

var level_navigation_points: Array = []
var navigation_path_points: PoolVector2Array = []
var navigation_server_map: RID
var navigation_path_line: Line2D = Line2D.new()

onready var nav_position_target: Position2D = $PositionTarget


func _ready():
	# use call deferred to make sure the entire SceneTree Nodes are setup
	# else yield on 'physics_frame' in a _ready() might get stuck
	_get_navigation_points()
	call_deferred("setup_navserver")


func _get_navigation_points(): # density ...  na koliko

	if nav_positions_density == 0:
		nav_positions_density = get_viewport_rect().size.x / 50

	var navigation_polygon: NavigationPolygon = navpoly
	var outer_outline_polygon: PoolVector2Array = navigation_polygon.get_outline(0)

	# bounding box zunanjega polygona, da ne nabiram po neskončnem polju
	var navigation_hull: Array = Geometry.convex_hull_2d(outer_outline_polygon)
	var hull_point_x_values: Array = []
	var hull_point_y_values: Array = []
	for point in navigation_hull:
		hull_point_x_values.append(point.x)
		hull_point_y_values.append(point.y)
	var nav_polygon_size_x: float = abs(hull_point_x_values.max() - hull_point_x_values.min())
	var nav_polygon_size_y: float = abs(hull_point_y_values.max() - hull_point_y_values.min())
	var nav_polygon_position: Vector2 = Vector2(hull_point_x_values.min(), hull_point_y_values.min())

	# boundig-box points
	var points_in_navigation_hull: Array = []
	var x_count: int = round(nav_polygon_size_x / nav_positions_density)
	var y_count: int = round(nav_polygon_size_y / nav_positions_density)
	for x in x_count:
		for y in y_count:
			var current_point: Vector2 = Vector2(x * nav_positions_density, y * nav_positions_density)
			current_point += nav_polygon_position # adaptiram za pozicijo nodeta
			points_in_navigation_hull.append(current_point)

	# outer poligon points
	var navigation_nav_points: Array = []
	for point in points_in_navigation_hull:
		if Geometry.is_point_in_polygon(point, outer_outline_polygon):
			navigation_nav_points.append(point)

	# inner poligon points delete
	print("get_polygon_count", navigation_polygon.get_outline_count())
	for outline_count in navigation_polygon.get_outline_count():
		if outline_count > 0: # preskočim prvega, ki je zunanji
			var current_poly = navigation_polygon.get_outline(outline_count)
			for nav_point in points_in_navigation_hull:
				if Geometry.is_point_in_polygon(nav_point, current_poly):
					navigation_nav_points.erase(nav_point)

	# adaptacija na pozicijo navigation nodeta
	for nav_point in navigation_nav_points:
		#		Mets.spawn_indikator(nav_point, Color.red, 0, self)
		nav_point += global_position

	level_navigation_points = navigation_nav_points


func setup_navserver():

	# create a new navigation map
	navigation_server_map = Navigation2DServer.map_create()
	Navigation2DServer.map_set_active(navigation_server_map, true)

	# create a new navigation region and add it to the map
	var navigation_region = Navigation2DServer.region_create()
	Navigation2DServer.region_set_transform(navigation_region, Transform())
	Navigation2DServer.region_set_map(navigation_region, navigation_server_map)

	# sets navigation mesh for the region
	var navigation_poly = NavigationMesh.new() # ??? tukaj je navigation_poly "NavigationMesh"
	navigation_poly = self.navpoly # ??? tukaj je navigation_poly "NavigationPolygon"
	Navigation2DServer.region_set_navpoly(navigation_region, navigation_poly)

	# wait for Navigation2DServer sync to adapt to made changes
	yield(get_tree(), "physics_frame")


func _update_navigation_path(start_position: Vector2, end_position: Vector2):
	# map_get_path is part of the avigation2DServer class.
	# It returns a PoolVector2Array of points that lead you
	# from the start_position to the end_position.

	navigation_path_points = Navigation2DServer.map_get_path(navigation_server_map, start_position, end_position, true)

	if navigation_path_line.points.empty():
		navigation_path_line = Line2D.new()
		navigation_path_line.points = navigation_path_points
		add_child(navigation_path_line)
	elif navigation_path_line.points.empty():
		navigation_path_line.points = navigation_path_points
	else:
		navigation_path_line.points = navigation_path_points

	# The first point is always the start_position.
	# We don't need it in this example as it corresponds to the character's position.
	navigation_path_points.remove(0)

	return navigation_path_points
