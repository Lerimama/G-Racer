extends Control
#class_name Hud


var level_lap_count: int
var level_goals: Array = []
var max_wins_count: int

var statbox_count: int = 0
var statboxes_with_drivers: Dictionary = {} # statbox in njen driver

onready var sections_holder: HBoxContainer = $HudSections
onready var left_section: VBoxContainer = $HudSections/Left
onready var right_section: VBoxContainer = $HudSections/Right
onready var center_top: VBoxContainer = $HudSections/Center/Top
onready var center_btm: VBoxContainer = $HudSections/Center/Btm

onready var game_timer: HBoxContainer = $HudSections/Center/Top/GameTimer
onready var record_lap_label: Label = $HudSections/Center/Top/RecordLap
onready var level_name: Label = $HudSections/Center/Btm/LevelName

onready var start_countdown: Control = $Popups/StartCountdown

onready var FloatingTag: PackedScene = preload("res://game/gui/FloatingTag.tscn")
onready var StatBox: PackedScene = preload("res://game/gui/hud/StatBox.tscn")


func _ready() -> void:

	# debug reset
	for sec in [$HudSections/Left, $HudSections/Right]:
		for child in sec.get_children():
			child.queue_free()


func set_hud(game_manager):

	level_lap_count = game_manager.level_profile["level_laps"]
#	level_time_limit = game_manager.level_profile["level_time_limit"]
	level_goals = game_manager.level_profile["level_goals"]
	max_wins_count = game_manager.curr_game_settings["max_wins_count"]

	var level_time_limit: int = game_manager.level_profile["level_time_limit"]

	if game_manager.level_profile["rank_by"] == Pfs.RANK_BY.TIME:
		game_timer.hunds_mode = true
	else:
		game_timer.hunds_mode = false

	# game stats
	game_timer.stop_timer()
	game_timer.reset_timer(level_time_limit)
	game_timer.show()
	record_lap_label.hide()
	for section in sections_holder.get_children():
		section.show()

	# statboxes reset
	for statbox_name_id in statboxes_with_drivers:
		statboxes_with_drivers[statbox_name_id].queue_free()
	statboxes_with_drivers.clear()
	statbox_count = 0

	# new statboxes
	for vehicle in game_manager.drivers_on_start:
		set_driver_statbox(vehicle, game_manager.level_profile["rank_by"], game_manager.drivers_on_start.size())


func set_driver_statbox(statbox_driver: Vehicle, rank_by: int, all_statboxes_count: int): # kliče GM

	statbox_count += 1

	# spawn left /right
	var new_statbox: VBoxContainer = StatBox.instance()
	if statbox_count % 2 == 0:
		right_section.add_child(new_statbox)
	else:
		left_section.add_child(new_statbox)

	statboxes_with_drivers[statbox_driver.driver_id] = new_statbox

	var driver_stats: Dictionary = statbox_driver.driver_stats
	var driver_profile: Dictionary = statbox_driver.driver_profile

	# driver line
	new_statbox.driver_name_label.text = str(statbox_driver.driver_id)
	new_statbox.driver_name_label.modulate = driver_profile["driver_color"]
	new_statbox.driver_avatar.set_texture(driver_profile["driver_avatar"])

	# driver stats
	for stat in driver_stats:
		_on_driver_stat_changed(statbox_driver.driver_id, stat, driver_stats[stat])

	if all_statboxes_count == 1: # single player
		new_statbox.set_statbox_elements(rank_by, true)
	else:
		new_statbox.set_statbox_elements(rank_by)

	# če je predzadnji bo zadnji ... na levi strani
	# če je zadnji bo zadnji na drugi strani
	if statbox_count < all_statboxes_count - 1:
		new_statbox.set_statbox_align(statbox_count)
	else:
		new_statbox.set_statbox_align(statbox_count, true)

	new_statbox.show()


func on_game_start():

	game_timer.start_timer()


func on_level_over():

	for section in sections_holder.get_children():
		section.hide()


func on_game_over():

	for section in sections_holder.get_children():
		section.hide()


func _on_driver_stat_changed(driver_id, stat_key: int, stat_value):
	# stat value je že preračunana, končna vrednost
	# tukaj se opredeli obliko zapisa

#	if stat_key == 0:
#		printt ("WIN", stat_key, stat_value)
#	if stat_key == 10:
#		printt ("RANK", driver_stat_key, stat_value)

	# opredelim drive statbox
	var statbox_to_change: Control
	for statbox_name_id in statboxes_with_drivers:
		if statboxes_with_drivers[statbox_name_id]:
			statbox_to_change = statboxes_with_drivers[statbox_name_id]
			break

	# stat_to_change ... STAT key string
	var current_key_index: int = Pfs.STATS.values().find(stat_key)
	var current_key: String = Pfs.STATS.keys()[current_key_index]
	var stat_to_change: Control = statbox_to_change.get(current_key)

	match stat_key:

		# stat_value = Int, Float
		Pfs.STATS.GAS:
			stat_to_change.stat_value = stat_value
		Pfs.STATS.HEALTH: # ENERGY BAR
			# 10 = 100 % v pseudo-bar
			var curr_health_percent: int = round(stat_value * 10)
			stat_to_change.stat_value = [curr_health_percent, 10]
		Pfs.STATS.LIFE:
			stat_to_change.stat_value = [stat_value, 3]
		Pfs.STATS.CASH:
			stat_to_change.stat_value = stat_value
		Pfs.STATS.POINTS: # default
			stat_to_change.stat_value = stat_value

		# stat_value = Array
		Pfs.STATS.GOALS_REACHED:
			stat_to_change.stat_value = [stat_value.size(), level_goals.size()]
		Pfs.STATS.WINS:
			stat_to_change.stat_value = [stat_value.size(), Sts.wins_goal_count]

		# level
		Pfs.STATS.LEVEL_RANK: # na konča
			stat_to_change.stat_value = stat_value
		Pfs.STATS.LEVEL_TIME:
			stat_to_change.stat_value = stat_value
		Pfs.STATS.LAP_COUNT: # če so krogi
			stat_to_change.stat_value = [stat_value.size(), level_lap_count]
		Pfs.STATS.BEST_LAP_TIME:
			stat_to_change.stat_value = stat_value
		Pfs.STATS.LAP_TIME: # vsak frejm
			stat_to_change.stat_value = stat_value
		_:
			stat_to_change.stat_value = stat_value


func spawn_driver_floating_tag(tag_owner: Node2D, lap_time: float, best_lap: bool = false):

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
