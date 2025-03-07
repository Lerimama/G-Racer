extends Control


signal views_are_set

enum SPLITSCREEN_TILE {TWO_VER, THREE_LEFT, THREE_RIGHT, FOUR }

var views_with_drivers: Dictionary = {}
var view_camera_path: String = "Viewport/GameCamera"

onready var main_game_view: ViewportContainer = $GameView
onready var GameView: PackedScene = preload("res://game/GameView.tscn")



func _ready() -> void:

	for view in get_children():
		if not view == get_child(0):
			view.queue_free()


func reset_views():

	for view in get_children():
		if not view == get_child(0):
			view.queue_free()

	views_with_drivers.clear()


func set_game_views(drivers_for_views: Array = [], mono_screen: bool = false):

	if mono_screen:
		views_with_drivers[main_game_view] = drivers_for_views[0].driver_id
		for driver in drivers_for_views:
			driver.vehicle_camera = main_game_view.get_node(view_camera_path)
		emit_signal("views_are_set")
	else:
		# intervencija, 2. plejer ima 3. view
		if drivers_for_views.size() > 2:
			var player2: Node2D = drivers_for_views[1]
			drivers_for_views.remove(1)
			drivers_for_views.insert(2, player2)

		for driver in drivers_for_views:
			var main_camera: Camera2D = main_game_view.get_node(view_camera_path)
			if drivers_for_views.find(driver) == 0:
				views_with_drivers[main_game_view] = driver.driver_id
				driver.vehicle_camera = main_camera
			else:
				var new_game_view: ViewportContainer = GameView.instance()
				add_child(new_game_view)
				views_with_drivers[new_game_view] = driver.driver_id
				driver.vehicle_camera = new_game_view.get_node(view_camera_path)
				# camera settings
				driver.vehicle_camera.position = main_camera.position
				driver.vehicle_camera.limit_left = main_camera.limit_left
				driver.vehicle_camera.limit_top = main_camera.limit_top
				driver.vehicle_camera.limit_right = main_camera.limit_right
				driver.vehicle_camera.limit_bottom = main_camera.limit_bottom

		# duplicate world
		var world_to_inherit: World2D = main_game_view.get_node("Viewport").world_2d
		var current_game_views: Dictionary = views_with_drivers
		for view in get_children():
			if not view == world_to_inherit:
				view.get_node("Viewport").world_2d = world_to_inherit

		# tile views
		if drivers_for_views.size() > 1:
			_tile_views(drivers_for_views.size())


func _tile_views(players_count: int):

	# view size
	var splitscreen_tile: int = 0
	match players_count:
		2: splitscreen_tile = SPLITSCREEN_TILE.TWO_VER
		3: splitscreen_tile = SPLITSCREEN_TILE.THREE_RIGHT
		#		3: splitscreen_tile = SPLITSCREEN_TILE.THREE_LEFT
		4: splitscreen_tile = SPLITSCREEN_TILE.FOUR

	var v_sep: float = get_constant("vseparation")
	var h_sep: float = get_constant("hseparation")
	var full_size: Vector2 = get_viewport_rect().size

	match splitscreen_tile:
		SPLITSCREEN_TILE.TWO_VER:
			# size
			views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
			views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 1)
			# separation adapt
			views_with_drivers.keys()[0].get_node("Viewport").size.x -= h_sep/2
			views_with_drivers.keys()[1].get_node("Viewport").size.x -= h_sep/2
		SPLITSCREEN_TILE.THREE_LEFT:
			# size
			views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
			views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			# separation adapt
			views_with_drivers.keys()[2].get_node("Viewport").size.x -= h_sep/2
			views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
		SPLITSCREEN_TILE.THREE_RIGHT:
			# size
			views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 1)
			# separation adapt
			views_with_drivers.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[2].get_node("Viewport").size.x -= h_sep/2
		SPLITSCREEN_TILE.FOUR:
			# size
			views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[3].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			# separation adapt
			views_with_drivers.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			views_with_drivers.keys()[3].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2

	emit_signal("views_are_set")
