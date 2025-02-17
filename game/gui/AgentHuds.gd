extends Control


var view_imitators: Dictionary = {}

onready var view_imitator: Control = $ViewImitator
onready var first_agent_hud: VBoxContainer = $ViewImitator/AgentHud
onready var AgentHud: PackedScene = preload("res://game/gui/AgentHud.tscn")


func set_agent_huds(game_views: Dictionary, one_screen_mode: bool):

	# debug reset
	if first_agent_hud:
		first_agent_hud.queue_free()
		first_agent_hud = null

	if one_screen_mode:
		var imitated_view: ViewportContainer = game_views.keys()[0]
		for player_agent in get_tree().get_nodes_in_group(Rfs.group_players):
			var new_player_agent_hud: Control = AgentHud.instance()
			view_imitator.add_child(new_player_agent_hud)
			new_player_agent_hud.set_agent_hud(player_agent, imitated_view)
		# view predstavnik je prvik plejer
		view_imitators[view_imitator] = game_views.values()[0]
		# ai huds
		for ai_agent in get_tree().get_nodes_in_group(Rfs.group_ai):
			var new_ai_agent_hud: Control = AgentHud.instance()
			view_imitator.add_child(new_ai_agent_hud)
			new_ai_agent_hud.set_agent_hud(ai_agent, imitated_view, true)
	else:
		# agent huds and view imitators
		for view in game_views:
			# spawnam view imitatorja, ki je dimenzijska kopija pripadajočega viewa
			var view_imitator_template: Control = Mts.remove_chidren_and_get_template([view_imitator])
			var new_view_imitator: Control = view_imitator_template.duplicate()
			add_child(new_view_imitator)
			# player hud
			var player_agent: Agent = game_views[view]
			var new_player_agent_hud = new_view_imitator.get_node("AgentHud")
			new_player_agent_hud.set_agent_hud(player_agent, view)
			# view predstavnik je pripadajoči plejer
			view_imitators[new_view_imitator] = player_agent
			# ai huds
			for ai_agent in get_tree().get_nodes_in_group(Rfs.group_ai):
				var new_ai_agent_hud: Control = AgentHud.instance()
				new_view_imitator.add_child(new_ai_agent_hud)
				new_ai_agent_hud.set_agent_hud(ai_agent, view, true)

	# aplciram game_views dimezije na imitatorja
	_set_imitators_size(game_views)


func remove_view_imitator(game_views: Dictionary): # GM na activity change

	var view_added: bool = false

	# preverim kateri player je removed ... views in imitatorji imajo skupnega plejerja
	var view_imitator_to_remove: Control
	for player in view_imitators.values():
		if not game_views.values().has(player):
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
		var view_player: Agent = game_views[view]
		if view_imitators.values().has(view_player):
			var view_imitator_to_set: Control = view_imitators.find_key(view_player)
			view_imitator_to_set.rect_size = view.rect_size
			view_imitator_to_set.rect_position = view.rect_position
