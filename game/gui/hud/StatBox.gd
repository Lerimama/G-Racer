tool
extends BoxContainer # lahko je ver in hor

export var use_level_progress_bar: bool = true

var statbox_color: Color = Color.white

# driver id ... locked v strukturi
onready var driver_id_holder: MarginContainer = $DriverId
onready var driver_name_label: Label = $DriverId/BoxContainer/Name
onready var driver_avatar: TextureRect = $DriverId/BoxContainer/Avatar

# driver
onready var LIFE: HBoxContainer = find_node("StatLife")
onready var WINS: HBoxContainer = find_node("StatWins")
onready var CASH: HBoxContainer = find_node("StatCash")
onready var POINTS: HBoxContainer = find_node("StatPoints")

# vehicle
onready var LEVEL_RANK: HBoxContainer = find_node("StatLevelRank")
onready var GOALS_REACHED: HBoxContainer = find_node("GoalReached")

# level
onready var LEVEL_PROGRESS: Panel = find_node("ProgressBar") #$LevelProgress/ProgressBarHolder/LevelProgressBar
onready var LAP_COUNT: HBoxContainer = find_node("StatLapCount")
onready var CURR_LAP_TIME: HBoxContainer = find_node("StatLapTime")
onready var BEST_LAP_TIME: HBoxContainer = find_node("StatBestLap")
onready var LEVEL_TIME: HBoxContainer = find_node("StatLevelTime")

onready var lap_time_still_display: HBoxContainer = find_node("StatLapTime_Still")

# on driver hud
onready var HEALTH: HBoxContainer = find_node("StatHealth")
onready var GAS: HBoxContainer = find_node("StatGas")

onready var rank_by_points_stats: Array = [WINS, CASH, LEVEL_RANK, GOALS_REACHED,
	LIFE,
	]
onready var rank_by_time_stat: Array = [WINS, CASH, LEVEL_RANK, GOALS_REACHED,
	LAP_COUNT,
	CURR_LAP_TIME,
	BEST_LAP_TIME,
	]
onready var invisibles: MarginContainer = $Invisibles


func _ready() -> void:

#	if use_level_progress_bar:
#		level_progress_bar.show()
#
	pass


func set_statbox_stats(rank_by: String, lap_count: int, goal_count: int, players_count: int, one_life_mode: bool): # kliče HUD

	# reset
	for stat_holder in get_children():
		stat_holder.hide()
	driver_id_holder.show()
	lap_time_still_display.hide()

	# by_rank visibility
	if rank_by == "TIME":
		for stat in rank_by_time_stat:
			stat.get_parent().get_parent().show()
			if stat == BEST_LAP_TIME:
				stat.get_parent().get_parent().hide()
	elif rank_by == "POINTS":
		for stat in rank_by_points_stats:
			stat.get_parent().get_parent().show()
	else:
		use_level_progress_bar = false
		lap_count = 0
		goal_count = 0
		LEVEL_PROGRESS.get_parent().get_parent().show()
		for stat in rank_by_time_stat:
			stat.get_parent().get_parent().hide()
		for stat in rank_by_points_stats:
			stat.get_parent().get_parent().hide()

	# en plejer ... ne kaže ranka
	if players_count == 1:
		# perverja, če je v drevesu kot samostojen stat
		if get_node("Rank") in get_children():
			get_node("Rank").hide()
		else:
			LEVEL_RANK.hide()
	# en lajf ... ne kaže lajfa
	if one_life_mode:
		if get_node("Life") in get_children():
			get_node("Life").hide()
		else:
			LIFE.hide()

	# progress bar
	var level_progress_container: MarginContainer = LEVEL_PROGRESS.get_parent().get_parent()
	if use_level_progress_bar:
		# resize to node ... on top se ravna po prvem POD, ostali po prvem NAD
		var above_or_below_index: int = 0
		if level_progress_container == get_child(0):
			above_or_below_index = 1
		else:
			above_or_below_index = get_children().find(level_progress_container) - 1
		var measuring_node: Control = get_child(above_or_below_index)
		measuring_node.connect("resized", self, "_on_measure_by_resized", [level_progress_container, measuring_node])
		measuring_node.rect_size = rect_size # apdejt, da se poravna

		# update
		if goal_count > 0: # goals se kažejo tudi če so krogi
			if rank_by == "TIME":
				goal_count += 1 # dodam finish line kot končen cilj
			LEVEL_PROGRESS.stage_count = goal_count
		else:
			LEVEL_PROGRESS.stage_count = lap_count
		LEVEL_PROGRESS.bar_color = statbox_color

		level_progress_container.show()
		# skrijem lapo-goal counterje
		if get_node("LapGoalCount") in get_children():
			get_node("LapGoalCount").hide()
		else:
			LAP_COUNT.hide()
			GOALS_REACHED.show()
	else:
		level_progress_container.hide()

		# lap / goal counters ... če hočem ne glede na progress bar dam ven iz tega if-a
		var no_goals_and_laps: bool = false
		if lap_count < 1 and goal_count == 0:
			no_goals_and_laps = true

		# če so counterji v svojem containerju
		if get_node("LapGoalCount") in get_children():
			if lap_count < 1 and goal_count == 0: # no_goals_and_laps
				get_node("LapGoalCount").hide()
			else:
				get_node("LapGoalCount").show()
		else:
			if lap_count < 1 and goal_count == 0: # no_goals_and_laps
				LAP_COUNT.hide()
				GOALS_REACHED.hide()
			# če je eno ali drugo, pedenam samo stast
			elif goal_count == 0:
				LAP_COUNT.show()
				GOALS_REACHED.hide()
			elif lap_count < 1:
				LAP_COUNT.hide()
				GOALS_REACHED.show()



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
