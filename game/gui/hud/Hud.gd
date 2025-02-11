extends Control
class_name Hud


var record_lap_time: int = 0
var record_level_time: int = 0
var level_lap_limit: int

onready var statboxes: Array = [$StatBox, $StatBox2, $StatBox3, $StatBox4]
onready var record_lap_label: Label = $RecordLap
onready var level_name: Label = $LevelName
onready var game_timer: HBoxContainer = $GameTimer
onready var start_countdown: Control = $Popups/StartCountdown
onready var agent_huds_holder: Control = $"../AgentHuds"
onready var AgentHud = preload("res://game/gui/AgentHud.tscn")
onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")


func _ready() -> void:
#	print("HUD")

	for box in statboxes:
		box.hide()


func setup(level_profile: Dictionary, game_views: Dictionary):

	for box in statboxes:
		box.set_statbox_for_level(level_profile["level_type"])

	if level_profile["level_type"] == Pfs.BASE_TYPE.TIMED:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	# game stats
	level_lap_limit = level_profile["lap_limit"]
	game_timer.reset_timer(level_profile["time_limit"])
	game_timer.show()
	record_lap_label.hide()

	# agent huds
	for ag_hud in agent_huds_holder.get_children():
		ag_hud.queue_free()

	for view in game_views:

		# player huds
		var new_player_agent_hud = AgentHud.instance()
		agent_huds_holder.add_child(new_player_agent_hud)
		new_player_agent_hud.setup(game_views[view], view)

		# ai huds
		# _temp dokler ne spedenam ai pozicije glede na kamero
		#		# naredim control node, ki je dimenzijska kopija pripadajočega viewa
		#		$"../AgentHuds/AiHudHolder".queue_free()
		#		var new_pseudo_view: Control = Control.new()
		#		# test line var new_pseudo_view: Control = ai_agent_hud.duplicate()
		#		new_pseudo_view.rect_size = view.rect_size
		#		new_pseudo_view.rect_position = view.rect_position
		#		agent_huds_holder.add_child(new_pseudo_view)
		#		for ai_agent in get_tree().get_nodes_in_group(Rfs.group_ai):
		#			var new_ai_agent_hud = AgentHud.instance()
		#			new_ai_agent_hud.name = "AiHudHolder"
		#			new_pseudo_view.add_child(new_ai_agent_hud)
		#			new_ai_agent_hud.setup(ai_agent, view, true)


func set_agent_statbox(spawned_agent: Node2D, agents_level_stats: Dictionary): # kliče GM

	var loading_time: float = 0.5 # pred prikazom naj se v miru postavi
	var spawned_driver_statbox: Control = statboxes[spawned_agent.driver_index]
	var spawned_driver_stats: Dictionary = spawned_agent.driver_stats
	var spawned_driver_profile: Dictionary = Pfs.driver_profiles[spawned_agent.driver_index]

	# agent stats
	spawned_driver_statbox.stat_bullet.stat_value = spawned_driver_stats[Pfs.STATS.BULLET_COUNT]
	spawned_driver_statbox.stat_misile.stat_value = spawned_driver_stats[Pfs.STATS.MISILE_COUNT]
	spawned_driver_statbox.stat_mina.stat_value = spawned_driver_stats[Pfs.STATS.MINA_COUNT]
	spawned_driver_statbox.stat_gas.stat_value = spawned_driver_stats[Pfs.STATS.GAS]
	spawned_driver_statbox.stat_life.stat_value = spawned_driver_stats[Pfs.STATS.LIFE]
	spawned_driver_statbox.stat_points.stat_value = spawned_driver_stats[Pfs.STATS.POINTS]
	spawned_driver_statbox.stat_cash.stat_value = spawned_driver_stats[Pfs.STATS.CASH]
	spawned_driver_statbox.stat_wins.stat_value = spawned_driver_stats[Pfs.STATS.WINS]

	# level stats
	for stat_key in [Pfs.STATS.LAPS_FINISHED, Pfs.STATS.BEST_LAP_TIME, Pfs.STATS.LEVEL_TIME, Pfs.STATS.GOALS_REACHED]:
		update_agent_level_stats(spawned_agent.driver_index, stat_key, agents_level_stats[stat_key])

	# driver line
	spawned_driver_statbox.driver_name.text = spawned_driver_profile["driver_name"]
	spawned_driver_statbox.driver_name.modulate = spawned_driver_profile["driver_color"]
	spawned_driver_statbox.driver_avatar.set_texture(spawned_driver_profile["driver_avatar"])
#	spawned_driver_statbox.driver_avatar.set_texture(spawned_driver_profile["driver_avatar_png"])
	spawned_driver_statbox.stat_wins.modulate = Color.red
	yield(get_tree().create_timer(loading_time), "timeout") # dam cajt, da se vse razbarva iz zelene
	spawned_driver_statbox.visible = true


func on_game_start():

	game_timer.start_timer()


func on_level_finished():

	game_timer.stop_timer()


func on_game_over():

	game_timer.stop_timer()
	_hide_stats()


func _hide_stats():

	for box in statboxes:
		box.hide()
	game_timer.hide()
	record_lap_label.hide()


func _on_agent_stat_changed(driver_index: int, agent_stat_key: int, stat_value): # stat value je že preračunana, hud samo zapisuje

	var statbox_to_change: Control = statboxes[driver_index] # agent id kot index je enak indexu statboxa v statboxih
	var stat_to_change: Node
	match agent_stat_key:
		Pfs.STATS.SMALL_COUNT:
			return
		Pfs.STATS.BULLET_COUNT:
			stat_to_change = statbox_to_change.stat_bullet
		Pfs.STATS.MISILE_COUNT:
			stat_to_change = statbox_to_change.stat_misile
		Pfs.STATS.MINA_COUNT:
			stat_to_change = statbox_to_change.stat_mina
		Pfs.STATS.GAS:
			stat_to_change = statbox_to_change.stat_gas
		Pfs.STATS.LIFE:
			stat_to_change = statbox_to_change.stat_life
		Pfs.STATS.POINTS:
			stat_to_change = statbox_to_change.stat_points
		Pfs.STATS.CASH:
			stat_to_change = statbox_to_change.stat_cash
		Pfs.STATS.WINS:
			stat_to_change = statbox_to_change.stat_wins
		# Pfs.STATS.HEALTH: # poštima ga agent hud

	stat_to_change.stat_value = stat_value


func update_agent_level_stats(driver_index: int, level_stat_key: int, stat_value): # stat value je že preračunana, hud samo zapisuje

	var statbox_to_change: Control = statboxes[driver_index] # agent id kot index je enak indexu statboxa v statboxih
	var stat_to_change: Node
	match level_stat_key:
		Pfs.STATS.LEVEL_RANK:
			stat_to_change = statbox_to_change.stat_level_rank
		Pfs.STATS.LAPS_FINISHED:
			stat_value = str(stat_value.size() + 1) + "/" + str(level_lap_limit) # +1 ker kaže trnenutnega, ne končanega
			stat_to_change = statbox_to_change.stat_lap_count
		Pfs.STATS.BEST_LAP_TIME:
			var agents_best_lap_time: float = stat_value
			if agents_best_lap_time > 0:
				if agents_best_lap_time < record_lap_time or record_lap_time == 0:
					record_lap_time = agents_best_lap_time
					Mts.write_clock_time(record_lap_time, record_lap_label.get_node("TimeLabel"))
					if not record_lap_label.visible:
						record_lap_label.show()
			stat_to_change = statbox_to_change.stat_best_lap
		Pfs.STATS.LEVEL_TIME:
			stat_to_change = statbox_to_change.stat_level_time
		Pfs.STATS.GOALS_REACHED:
			# še čaka ... stat_to_change = statbox_to_change.stat_lap_count
			#			stat_value = stat_value.size()
			return

	stat_to_change.stat_value = stat_value


func spawn_agent_floating_tag(tag_owner: Node2D, lap_time: float, best_lap: bool = false):

	var new_floating_tag = FloatingTag.instance()

	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = tag_owner.global_position
	new_floating_tag.tag_owner = tag_owner
	new_floating_tag.scale = Vector2.ONE * Sts.game_camera_zoom_factor

	new_floating_tag.content_to_show = lap_time
	new_floating_tag.tag_type = new_floating_tag.TAG_TYPE.TIME
	Rfs.node_creation_parent.add_child(new_floating_tag) # OPT ... floating bi raje v hudu
	if best_lap == true:
		new_floating_tag.modulate = Rfs.color_green
	else:
		new_floating_tag.modulate = Rfs.color_red


func _on_GameTimer_gametime_is_up() -> void:

	Rfs.game_manager.end_level()
