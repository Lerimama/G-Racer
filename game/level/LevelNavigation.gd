extends NavigationPolygonInstance


export var nav_points_density: float = 0
var path = []

var map
export (NodePath) var character_path: String# = $Navmesh
#export (NodePath) var : String# = $Navmesh
onready var character = $Character

onready var navmesh: NavigationPolygonInstance = self
var level_navigation_points: Array = []


func _ready():
	# use call deferred to make sure the entire SceneTree Nodes are setup
	# else yield on 'physics_frame' in a _ready() might get stuck
	if not character_path.empty():
		character = get_node(character_path)
	_get_navigation_points()
	call_deferred("setup_navserver")

func _get_navigation_points(): # density ...  na koliko

	if nav_points_density == 0:
		nav_points_density = get_viewport_rect().size.x / 50

	var navigation_polygon: NavigationPolygon = navpoly
	var outer_outline_polygon: PoolVector2Array = navigation_polygon.get_outline(0)
	printt ("out count", navigation_polygon.get_outline_count(), navigation_polygon.make_polygons_from_outlines())
	# dimenzija zunanjega polygona, da ne grem po skončnem polju
#	var nav_limits_square: Panel = $Size

	var navigation_hull: Array = Geometry.convex_hull_2d(outer_outline_polygon)
	var hull_point_x_values: Array = []
	var hull_point_y_values: Array = []
	for point in navigation_hull:
		hull_point_x_values.append(point.x)
		hull_point_y_values.append(point.y)
	var nav_polygon_size_x: float = abs(hull_point_x_values.max() - hull_point_x_values.min())
	var nav_polygon_size_y: float = abs(hull_point_y_values.max() - hull_point_y_values.min())
	var nav_polygon_position: Vector2 = Vector2(hull_point_x_values.min(), hull_point_y_values.min())


	# točke znotraj kvadrata zunanjega poligona
	var points_in_navigation_hull: Array = []
	var x_count: int = round(nav_polygon_size_x / nav_points_density)
	var y_count: int = round(nav_polygon_size_y / nav_points_density)
	for x in x_count:
		for y in y_count:
			var current_point: Vector2 = Vector2(x * nav_points_density, y * nav_points_density)
			current_point += nav_polygon_position # adaptiram za pozicijo nodeta
			points_in_navigation_hull.append(current_point)

	# točke zunanjega poligona
	var navigation_nav_points: Array = []
	for point in points_in_navigation_hull:
		if Geometry.is_point_in_polygon(point, outer_outline_polygon):
			navigation_nav_points.append(point)

	# ven točke notranjih poligonov (luknje znotraj navigacije)
	for poly in navigation_polygon.get_polygon_count():
		if poly > 0: # preskočim prvega, ki je zunanji
			var current_poly = navigation_polygon.get_outline(poly)
			for nav_point in points_in_navigation_hull:
				if Geometry.is_point_in_polygon(nav_point, current_poly):
					navigation_nav_points.erase(nav_point)

	# adaptacija za pozicijo navmesha
	for nav_point in navigation_nav_points:
		nav_point += global_position
#		Mets.spawn_indikator(nav_point, Color.blue, 0, Refs.node_creation_parent, false)

	level_navigation_points = navigation_nav_points.duplicate()


func _input(event):
	if not event.is_action_pressed("left_click"):
		return
#	var selected_cell: Vector2
#	if not level_navigation_points.empty():
#		for nav_cell in level_navigation_points:
#			var nav_cell_global = nav_cell# - global_position
#			var curr_shortest_length = 0
#			if (nav_cell_global - get_global_mouse_position()).length() < curr_shortest_length or curr_shortest_length == 0:
#				selected_cell = nav_cell_global
#	else:
#		selected_cell = get_local_mouse_position()
#	Mets.spawn_indikator(selected_cell, Color.blue, 0, Refs.node_creation_parent, false)

#	_update_navigation_path(character.position, selected_cell)


func setup_navserver():

	# create a new navigation map
	map = Navigation2DServer.map_create()
	Navigation2DServer.map_set_active(map, true)

	# create a new navigation region and add it to the map
	var region = Navigation2DServer.region_create()
	Navigation2DServer.region_set_transform(region, Transform())
	Navigation2DServer.region_set_map(region, map)

	# sets navigation mesh for the region
	var navigation_poly = NavigationMesh.new()
	navigation_poly = navmesh.navpoly
	Navigation2DServer.region_set_navpoly(region, navigation_poly)

	# wait for Navigation2DServer sync to adapt to made changes
	yield(get_tree(), "physics_frame")

#	_get_navigation_points()

func move_along_path(distance):

	var last_point = character.position

	while path.size():
		var distance_between_points = last_point.distance_to(path[0])
		# The position to move to falls between two points.
		if distance <= distance_between_points:
			character.position = last_point.linear_interpolate(path[0], distance / distance_between_points)
			return
		# The position is past the end of the segment.
		distance -= distance_between_points
		last_point = path[0]
		path.remove(0)
	# The character reached the end of the path.
	character.position = last_point
	set_process(false)

func _get_things_to_get_out_off_navigation():
	pass

var navigation_path: Line2D = Line2D.new()

func _update_navigation_path(start_position, end_position):
	# map_get_path is part of the avigation2DServer class.
	# It returns a PoolVector2Array of points that lead you
	# from the start_position to the end_position.
	path = Navigation2DServer.map_get_path(map,start_position, end_position, true)

	if navigation_path.points.empty():
		navigation_path = Line2D.new()
		navigation_path.points = path
		add_child(navigation_path)
	elif navigation_path.points.empty():
		navigation_path.points = path
	else:
		navigation_path.points = path
	# The first point is always the start_position.
	# We don't need it in this example as it corresponds to the character's position.
	path.remove(0)

	return path
#	set_process(true)


#func _process(delta):
##	var walk_distance = character_speed * delta
#	move_along_path(walk_distance)
