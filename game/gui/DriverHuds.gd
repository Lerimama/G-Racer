extends Control


var view_imitators_with_drivers: Dictionary = {} # imitatorja je dimenzijska kopija pripadajočega viewa

onready var view_imitator: Control = $ViewImitator # nikoli ga ne zbrišemm
onready var DriverHud: PackedScene = preload("res://game/gui/DriverHud.tscn")



func _ready() -> void:

	# debug reset
	if $ViewImitator/DriverHud:
		$ViewImitator/DriverHud.queue_free()


func set_driver_huds(game_manager: Game, one_screen_mode: bool):

	var game_views_with_drivers: Dictionary = game_manager.game_views_with_drivers

	# reset, razen vzorčnega
	for imitator in get_children():
		if not imitator == get_child(0):
			imitator.queue_free()
	view_imitators_with_drivers.clear()


	if one_screen_mode:
		var imitated_view: ViewportContainer = game_views_with_drivers.keys()[0]

		for driver in game_manager.drivers_on_start:
			var new_driver_hud: Control = DriverHud.instance()
			view_imitator.add_child(new_driver_hud)
			if driver.motion_manager.is_ai:
				new_driver_hud.set_driver_hud(driver, imitated_view, true)
			else:
				new_driver_hud.set_driver_hud(driver, imitated_view)
		view_imitators_with_drivers[view_imitator] = game_views_with_drivers.values()[0] # view owner je 1. plejer

	else:
		for view in game_views_with_drivers:

			# spawn imitatoraja
			var new_view_imitator: Control = view_imitator.duplicate()
			add_child(new_view_imitator)

			# player hud
			var new_driver_hud: Control = DriverHud.instance()
			new_view_imitator.add_child(new_driver_hud)
			var player_driver: Vehicle = game_views_with_drivers[view]
			new_driver_hud.set_driver_hud(player_driver, view)
			# v slovar
			view_imitators_with_drivers[new_view_imitator] = player_driver
			# ai huds
			for ai_driver in game_manager.drivers_on_start:
				if ai_driver.motion_manager.is_ai:
					var new_ai_hud: Control = DriverHud.instance()
					new_view_imitator.add_child(new_ai_hud)
					new_ai_hud.set_driver_hud(ai_driver, view, true)

	# aplciram game_views dimezije na imitatorja
	_set_imitators_size(game_views_with_drivers)


func remove_view_imitator(game_views: Dictionary): # GM na activity change

	var view_added: bool = false

	# preverim kateri player je removed ... views in imitatorji imajo skupnega plejerja
	var view_imitator_to_remove: Control
	for player in view_imitators_with_drivers.values():
		if not player in game_views.values():
			view_imitator_to_remove = view_imitators_with_drivers.find_key(player)
			break

	# removam imitatorja
	view_imitator_to_remove.queue_free()
	view_imitators_with_drivers.erase(view_imitator_to_remove)

	# apliciram nove dimezije
	_set_imitators_size(game_views)


func _set_imitators_size(game_views: Dictionary):

	# počakam na apdejt active_view dimenzij
	yield(get_tree(), "idle_frame")

	# setam novo velikost ... views in imitatorji imajo skupnega plejerja
	for view in game_views:
		var view_player: Vehicle = game_views[view]
		if view_player in view_imitators_with_drivers.values():
			var view_imitator_to_set: Control = view_imitators_with_drivers.find_key(view_player)
			view_imitator_to_set.rect_size = view.rect_size
			view_imitator_to_set.rect_position = view.rect_position
