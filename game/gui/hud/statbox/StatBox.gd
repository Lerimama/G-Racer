tool
extends BoxContainer # lahko je ver in hor

export var use_level_progress_bar: bool = true

var statbox_color: Color = Color.white

# driver id ... locked v strukturi
onready var driver_id_holder: MarginContainer = $DriverId
onready var driver_name_label: Label = $DriverId/BoxContainer/Name
onready var driver_avatar: TextureRect = $DriverId/BoxContainer/Avatar

# driver
onready var SCALPS: HBoxContainer = find_node("StatLife")
onready var WINS: HBoxContainer = find_node("StatWins")
onready var CASH: HBoxContainer = find_node("StatCash")
onready var POINTS: HBoxContainer = find_node("StatPoints")

# level
onready var LEVEL_RANK: HBoxContainer = find_node("StatLevelRank")
onready var GOALS_REACHED: HBoxContainer = find_node("GoalReached")
onready var LEVEL_PROGRESS: Panel = find_node("ProgressBar") #$LevelProgress/ProgressBarHolder/LevelProgressBar
onready var LAP_COUNT: HBoxContainer = find_node("StatLapCount")
onready var LAP_TIME: HBoxContainer = find_node("StatLapTime")


onready var rank_by_points_stats: Array = [CASH, LEVEL_RANK, GOALS_REACHED,
	POINTS,
	]
onready var rank_by_scalps_stats: Array = [CASH, LEVEL_RANK, GOALS_REACHED,
	SCALPS,
	]
onready var rank_by_time_stat: Array = [CASH, LEVEL_RANK, GOALS_REACHED,
	LAP_COUNT,
	LAP_TIME,
	]
onready var invisibles: MarginContainer = $Invisibles


func _ready() -> void:

#	if use_level_progress_bar:
#		level_progress_bar.show()
#
	pass


func set_statbox_stats(rank_by: int, lap_count: int, goal_count: int, players_count: int): # kliče HUD

	# reset
	for stat_holder in get_children():
		stat_holder.hide()
	driver_id_holder.show()

	# by_rank visibility
	match rank_by:
		Levs.RANK_BY.TIME:
			use_level_progress_bar = true
			for stat in rank_by_time_stat:
				stat.get_parent().get_parent().show()
		Levs.RANK_BY.POINTS:
			use_level_progress_bar = false # ?
			for stat in rank_by_points_stats:
				stat.get_parent().get_parent().show()
			lap_count = 0
		Levs.RANK_BY.SCALPS:
			use_level_progress_bar = false
			for stat in rank_by_scalps_stats:
				stat.get_parent().get_parent().show()
		Levs.RANK_BY.NONE:
			use_level_progress_bar = false
			lap_count = 0
			goal_count = 0
			for stat in rank_by_time_stat:
				stat.get_parent().get_parent().hide()
			for stat in rank_by_points_stats:
				stat.get_parent().get_parent().hide()
			for stat in rank_by_scalps_stats:
				stat.get_parent().get_parent().hide()

	# en plejer ... ne kaže ranka
	if players_count == 1:
		# perverja, če je v drevesu kot samostojen stat
		if get_node("Rank") in get_children():
			get_node("Rank").hide()
		else:
			LEVEL_RANK.hide()

	# progress bar
	if use_level_progress_bar:
		_set_level_progress_bar(lap_count, goal_count)
		# skrijem lapo-goal counterje
		if get_node("LapGoalCount") in get_children():
			get_node("LapGoalCount").hide()
		else:
			LAP_COUNT.hide()
			GOALS_REACHED.hide()
	else:
		LEVEL_PROGRESS.get_parent().get_parent().hide()

		# lap / goal counters ... če hočem ne glede na progress bar dam ven iz tega if-a
		if get_node("LapGoalCount") in get_children():
		# solo margin container
			if lap_count < 1 and goal_count == 0:
				get_node("LapGoalCount").hide()
			else:
				get_node("LapGoalCount").show()
		else:
		# grupni margin container
			if lap_count > 1:
				LAP_COUNT.show()
			else:
				LAP_COUNT.hide()
			if goal_count > 0:
				GOALS_REACHED.show()
			else:
				GOALS_REACHED.hide()


func _set_level_progress_bar(lap_count: int, goal_count: int):

	var level_progress_container: MarginContainer = LEVEL_PROGRESS.get_parent().get_parent()

	# resize to node ... on top se ravna po prvem POD, ostali po prvem NAD
	var above_or_below_index: int = 0
	if level_progress_container == get_child(0):
		above_or_below_index = 1
	else:
		above_or_below_index = get_children().find(level_progress_container) - 1
	var measuring_node: Control = get_child(above_or_below_index)
	measuring_node.connect("resized", self, "_on_measure_by_resized", [level_progress_container, measuring_node])
	measuring_node.rect_size = rect_size # apdejt, da se poravna

	# update stats
	if goal_count > 0: # goals se kažejo tudi če so krogi
		# dodam finish line kot končen cilj
		# rank by time ma zmeraj finish line
		# drugače je rank by points
		#		if rank_by == Levs.RANK_BY.TIME:
		goal_count += 1
		LEVEL_PROGRESS.stage_count = goal_count
	else:
		LEVEL_PROGRESS.stage_count = lap_count
	LEVEL_PROGRESS.bar_color = statbox_color

	level_progress_container.show()

func _on_measure_by_resized(container_to_resize: Control, measure_by: Control):

	container_to_resize.rect_min_size.x = measure_by.rect_size.x
	container_to_resize.rect_size.x = measure_by.rect_size.x # ta vrstica, je v prmeru ko grem navzdol
	# level progres rebuilda tickse na svoj resize signal, da ga resiza kaj drugega


func set_statbox_align(statbox_section: int, is_last_in_section: bool = false):

	var index_in_section: int = get_parent().get_children().find(self)

	var stats_to_align: Array = get_children()
	var statbox_offset: Vector2 = Vector2.ZERO
	var edge_margin: float = 32

	# horizontal align
	match statbox_section:
		-1: # left
			for stat in stats_to_align:
				stat.size_flags_horizontal = 0
			statbox_offset.x -= edge_margin
		1: # right
			for stat in stats_to_align:
				stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
			statbox_offset.x += edge_margin
			size_flags_horizontal = BoxContainer.SIZE_SHRINK_END
		0: # center
			pass

	# vertical align
	if index_in_section == 0: # top
		alignment = BoxContainer.ALIGN_BEGIN
		statbox_offset.y -= edge_margin
	elif not is_last_in_section: # middle
		alignment = BoxContainer.ALIGN_CENTER
	else: # bottom
		alignment = BoxContainer.ALIGN_END
		statbox_offset.y += edge_margin
		#		move_child($DriverId, get_child_count() - 1)

	rect_position = statbox_offset
