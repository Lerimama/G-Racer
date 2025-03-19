tool
extends BoxContainer # lahko je ver in hor

export var use_level_progress_bar: bool = true

onready var driver_name_label: Label = find_node("Name")
onready var driver_avatar: TextureRect = find_node("Avatar")
onready var lap_time_still: HBoxContainer = find_node("StatLapTime_Still")
onready var level_progress_bar: Panel = $LevelProgress/ProgressBarHolder/LevelProgressBar

# driver
onready var LIFE: HBoxContainer = find_node("StatLife")
onready var WINS: HBoxContainer = find_node("StatWins")
onready var CASH: HBoxContainer = find_node("StatCash")
onready var POINTS: HBoxContainer = find_node("StatPoints")

# vehicle
onready var LEVEL_RANK: HBoxContainer = find_node("StatLevelRank")
onready var GOALS_REACHED: HBoxContainer = find_node("GoalReached")

# time
onready var LAP_COUNT: HBoxContainer = find_node("StatLapCount")
onready var LAP_TIME: HBoxContainer = find_node("StatLapTime")
onready var BEST_LAP_TIME: HBoxContainer = find_node("StatBestLap")
onready var LEVEL_TIME: HBoxContainer = find_node("StatLevelTime")

#onready var lap_time_still: HBoxContainer = $LapTime/BoxContainer/StatLapTime_Still

# on driver hud
onready var HEALTH: HBoxContainer = find_node("StatHealth")
onready var GAS: HBoxContainer = find_node("StatGas")

onready var rank_by_points_stats: Array = [WINS, CASH, LEVEL_RANK, GOALS_REACHED,
	LIFE,
	]
onready var rank_by_time_stat: Array = [WINS, CASH, LEVEL_RANK, GOALS_REACHED,
	LAP_COUNT,
	LAP_TIME,
	BEST_LAP_TIME,
	]
onready var invisibles: MarginContainer = $Invisibles
onready var driver_id: MarginContainer = $DriverId


func _ready() -> void:

#	if use_level_progress_bar:
#		level_progress_bar.show()
#
	pass


func set_statbox_elements(rank_by: int, lap_count: int, goal_count: int, single_player: bool, one_life_mode: bool): # kliče HUD

	# reset
	for stat_holder in get_children():
		stat_holder.hide()
	driver_id.show()
	lap_time_still.hide()

	# debug
	var show_all_available_stats: bool = false
	if show_all_available_stats:
		show_all_available_stats()
		return

	# by_rank visibility
	if rank_by == Pros.RANK_BY.TIME:
		for stat in rank_by_time_stat:
			stat.get_parent().get_parent().show()
			if stat == BEST_LAP_TIME:# or stat == LEVEL_TIME:
				stat.get_parent().get_parent().hide()
	elif rank_by == Pros.RANK_BY.POINTS:
		for stat in rank_by_points_stats:
			stat.get_parent().get_parent().show()
	else:
		for stat in rank_by_time_stat:
			stat.get_parent().get_parent().hide()
		for stat in rank_by_points_stats:
			stat.get_parent().get_parent().hide()

	# specials visibility

	# en plejer ne kaže ranka
	# perverja, če je v drevesu kot samostojen stat
	if single_player:
		if get_node("Rank") in get_children():
			get_node("Rank").hide()
		else:
			LEVEL_RANK.hide()

	# en start lajf ne kaže lajfa
	if one_life_mode:
		if get_node("Life") in get_children():
			get_node("Life").hide()
		else:
			LIFE.hide()

	# lap_count in goal count
	if use_level_progress_bar:
		get_node("LevelProgress").show()
	else:
		get_node("LevelProgress").hide()
#		get_node("LapGoalCount").hide()
#	else:
	# če ni laps niti goals ... skrijem cel kontejner če obstaja
	if lap_count < 1 and goal_count == 0:
		if get_node("LapGoalCount") in get_children():
			get_node("LapGoalCount").hide()
		else:
			LAP_COUNT.hide()
			GOALS_REACHED.hide()
	# če je eno ali drugo, pedenam samo stast
	elif lap_count > 1 and goal_count == 0:
		LAP_COUNT.show()
		GOALS_REACHED.hide()
	elif lap_count < 1 and goal_count > 0:
		LAP_COUNT.hide()
		GOALS_REACHED.show()


func show_all_available_stats(): # kliče HUD

	for child in invisibles.get_children():
		child.show()
	invisibles.show()

	for stat in rank_by_time_stat:
		stat.get_parent().get_parent().show()
	for stat in rank_by_points_stats:
		stat.get_parent().get_parent().show()


func set_statbox_align(statbox_index: int, last_in_section: bool = false):

	var stats_to_align: Array = get_children()
	var statbox_offset: Vector2 = Vector2.ZERO
	var edge_margin: float = 32

	# left / right
	if statbox_index % 2 == 0:
		for stat in stats_to_align:
			stat.size_flags_horizontal = 0
		statbox_offset.x -= edge_margin
	else:
		for stat in stats_to_align:
			stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
		statbox_offset.x += edge_margin

	# top / center /btm
	if statbox_index in [0, 1]:
		alignment = BoxContainer.ALIGN_BEGIN
		statbox_offset.y -= edge_margin
	elif not last_in_section:
		alignment = BoxContainer.ALIGN_CENTER
	else:
		alignment = BoxContainer.ALIGN_END
		statbox_offset.y += edge_margin
		#		move_child($DriverId, get_child_count() - 1)

	rect_position = statbox_offset
