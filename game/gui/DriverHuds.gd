extends Control


var view_imitators: Dictionary = {}

onready var view_imitator: Control = $ViewImitator
onready var first_driver_hud: VBoxContainer = $ViewImitator/DriverHud
onready var DriverHud: PackedScene = preload("res://game/gui/DriverHud.tscn")


func set_driver_huds(game_views: Dictionary, one_screen_mode: bool):

	# debug reset
	if first_driver_hud:
		first_driver_hud.queue_free()
		first_driver_hud = null

	if one_screen_mode:
		var imitated_view: ViewportContainer = game_views.keys()[0]
		for player_driver in get_tree().get_nodes_in_group(Rfs.group_players):
			var new_player_driver_hud: Control = DriverHud.instance()
			view_imitator.add_child(new_player_driver_hud)
			new_player_driver_hud.set_driver_hud(player_driver, imitated_view)
		# view predstavnik je prvik plejer
		view_imitators[view_imitator] = game_views.values()[0]
		# ai huds
		for ai_driver in get_tree().get_nodes_in_group(Rfs.group_ai):
			var new_ai_driver_hud: Control = DriverHud.instance()
			view_imitator.add_child(new_ai_driver_hud)
			new_ai_driver_hud.set_driver_hud(ai_driver, imitated_view, true)
	else:
		# vehicle huds and view imitators
		for view in game_views:
			# spawnam view imitatorja, ki je dimenzijska kopija pripadajočega viewa
			var view_imitator_template: Control = Mts.remove_chidren_and_get_template([view_imitator])
			var new_view_imitator: Control = view_imitator_template.duplicate()
			add_child(new_view_imitator)
			# player hud
			var player_driver: Vehicle = game_views[view]
			var new_player_driver_hud = new_view_imitator.get_node("DriverHud")
			new_player_driver_hud.set_driver_hud(player_driver, view)
			# view predstavnik je pripadajoči plejer
			view_imitators[new_view_imitator] = player_driver
			# ai huds
			for ai_driver in get_tree().get_nodes_in_group(Rfs.group_ai):
				var new_ai_driver_hud: Control = DriverHud.instance()
				new_view_imitator.add_child(new_ai_driver_hud)
				new_ai_driver_hud.set_driver_hud(ai_driver, view, true)

	# aplciram game_views dimezije na imitatorja
	_set_imitators_size(game_views)


func remove_view_imitator(game_views: Dictionary): # GM na activity change

	var view_added: bool = false

	# preverim kateri player je removed ... views in imitatorji imajo skupnega plejerja
	var view_imitator_to_remove: Control
	for player in view_imitators.values():
		if not player in game_views.values():
			view_imitator_to_remove = view_imitators.find_key(player)
			break

	# removam imitatorja
	view_imitator_to_remove.queue_free()
	view_imitators.erase(view_imitator_to_remove)

	# apliciram nove dimezije
	_set_imitators_size(game_views)


func _set_imitators_size(game_views: Dictionary):

	# počakam na apdejt active_view dimenzij
	yield(get_tree(), "idle_frame")

	# setam novo velikost ... views in imitatorji imajo skupnega plejerja
	for view in game_views:
		var view_player: Vehicle = game_views[view]
		if view_player in view_imitators.values():
			var view_imitator_to_set: Control = view_imitators.find_key(view_player)
			view_imitator_to_set.rect_size = view.rect_size
			view_imitator_to_set.rect_position = view.rect_position
