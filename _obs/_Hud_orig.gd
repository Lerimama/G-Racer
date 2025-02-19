extends Control
#class_name Hud


var record_lap_time: int = 0
var record_level_time: int = 0
var level_lap_limit: int

onready var statboxes: Array = [$StatBox, $StatBox2, $StatBox3, $StatBox4] # služi za beleženje box indexa in pozicijo
onready var statboxes_with_drivers: Dictionary = {} # statbox in njen driver

onready var record_lap_label: Label = $RecordLap
onready var level_name: Label = $LevelName
onready var game_timer: HBoxContainer = $GameTimer
onready var start_countdown: Control = $Popups/StartCountdown
onready var agent_huds_holder: Control = $"../AgentHuds"

onready var AgentHud: PackedScene = preload("res://game/gui/AgentHud.tscn")
onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")
onready var StatBox: PackedScene = preload("res://game/gui/hud/StatBox.tscn")


func _ready() -> void:

	# debug reset
	for box in statboxes:
		box.queue_free()
	statboxes.clear()


func set_hud(agents_starting: Array, level_type: int, level_profile: Dictionary, game_views: Dictionary):

	var level_lap_count: int = level_profile["level_laps"]
	var level_time_limit: int = level_profile["level_time_limit"]

	if level_type == Pfs.BASE_TYPE.RACING:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	# game stats
	level_lap_limit = level_lap_count
	game_timer.reset_timer(level_time_limit)
	game_timer.show()
	record_lap_label.hide()

	for agent in agents_starting:
		var agent_level_stats = Rfs.game_manager.level_stats[agent.driver_index]
		set_agent_statbox(agent, agent_level_stats, level_type)


func set_agent_statbox(statbox_agent: Node2D, driver_level_stats: Dictionary, level_type: int): # kliče GM

	# spawn
	var new_statbox: VBoxContainer = StatBox.instance()
	add_child(new_statbox)
	statboxes.append(new_statbox)

	statboxes_with_drivers[new_statbox] = statbox_agent

	var driver_stats: Dictionary = statbox_agent.driver_stats
	var driver_profile: Dictionary = Pfs.driver_profiles[statbox_agent.driver_index]

	# driver line
	new_statbox.driver_name_label.text = driver_profile["driver_name"]
	new_statbox.driver_name_label.modulate = driver_profile["driver_color"]
	new_statbox.driver_avatar.set_texture(driver_profile["driver_avatar"])
	new_statbox.stat_wins.modulate = Color.red

	# driver stats
	for stat in driver_stats:
		_on_agent_stat_changed(statbox_agent.driver_index, stat, driver_stats[stat])
	for level_stat in driver_level_stats:
		update_agent_level_stats(statbox_agent.driver_index, level_stat, driver_level_stats[level_stat])

	new_statbox.set_statbox_elements(level_type)
	new_statbox.screen_align = statboxes.find(new_statbox)
	new_statbox.show()


func on_game_start():

	game_timer.start_timer()


func on_level_over():

	game_timer.stop_timer()


func on_game_over():

	game_timer.stop_timer()

	# hide stats
	for box in statboxes:
		box.hide()
	game_timer.hide()
	record_lap_label.hide()


func _on_agent_stat_changed(driver_index, agent_stat_key: int, stat_value): # stat value je že preračunana, hud samo zapisuje

	var statbox_to_change: Control
	for statbox in statboxes_with_drivers:
		if statboxes_with_drivers[statbox].driver_index == driver_index:
			statbox_to_change = statboxes[statboxes_with_drivers.keys().find(statbox)]
			break

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
		Pfs.STATS.HEALTH:
			# poštima ga agent hud more bit zaradi spodnjega klica
			return

	stat_to_change.stat_value = stat_value


func update_agent_level_stats(driver_index, level_stat_key: int, stat_value): # stat value je že preračunana, hud samo zapisuje

	var statbox_to_change: Control
	for statbox in statboxes_with_drivers:
		if statboxes_with_drivers[statbox].driver_index == driver_index:
			statbox_to_change = statboxes[statboxes_with_drivers.keys().find(statbox)]
			break

	var stat_to_change: Node
	match level_stat_key:
		Pfs.STATS.LEVEL_RANK:
			stat_to_change = statbox_to_change.stat_level_rank
		Pfs.STATS.LAP_COUNT:
			var new_value: float
			if stat_value is Array:
				 new_value = stat_value.size() + 1
			else:
				new_value = stat_value
			stat_value = str(new_value) + "/" + str(level_lap_limit) # +1 ker kaže trnenutnega, ne končanega
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
