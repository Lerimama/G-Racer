tool
extends VBoxContainer

var all_box_stats: Array

# id
onready var driver_line: HBoxContainer = $DriverId/DriverLine
onready var driver_name_label: Label = $DriverId/DriverLine/Name
onready var driver_avatar: TextureRect = $DriverId/DriverLine/Avatar

# driver
onready var LIFE: HBoxContainer = find_node("StatLife")
onready var LEVEL_RANK: HBoxContainer = find_node("StatLevelRank")
onready var WINS: HBoxContainer = find_node("StatWins")
onready var HEALTH: HBoxContainer = find_node("StatHealth")
onready var CASH: HBoxContainer = find_node("StatCash")
onready var POINTS: HBoxContainer = find_node("StatPoints")
onready var GAS: HBoxContainer = find_node("StatGas")

# race
onready var LAP_COUNT: HBoxContainer = find_node("StatLapCount")
onready var BEST_LAP_TIME: HBoxContainer = find_node("StatBestLap")
onready var LEVEL_TIME: HBoxContainer = find_node("StatLevelTime")
onready var LAP_TIME: HBoxContainer = find_node("StatLapTime")

# battle
onready var BULLET_COUNT: HBoxContainer = find_node("StatBullet")
onready var MISILE_COUNT: HBoxContainer = find_node("StatMisile")
onready var MINA_COUNT: HBoxContainer = find_node("StatMina")
onready var SMALL_COUNT: HBoxContainer = find_node("StatSmallBullet")
onready var GOALS_REACHED: HBoxContainer = find_node("GoalReached")


func set_statbox_elements(level_type: int, single_driver_mode: bool = false): # kliče HUD

	# tole je treba spucat

	# debug .... hide all
	$BattleStats.hide()
	$RaceStats.hide()
	$DriverStats.hide()

	LIFE.hide()
	WINS.hide()
	LEVEL_RANK.hide()

	LAP_COUNT.hide()
	BEST_LAP_TIME.hide() # samo če bestič obstaja ... drugi krog
	LEVEL_TIME.hide() # viden na koncu

	POINTS.hide()
	CASH.hide()
	GAS.hide()

	GOALS_REACHED.hide()
	BULLET_COUNT.hide()
	MISILE_COUNT.hide()
	MINA_COUNT.hide()


	var lap_count: = 1 # !!!
	var goals_count: = 1 # !!!
	match level_type:
		Pfs.BASE_TYPE.RACING:
			$RaceStats.show()
			LEVEL_RANK.show()
#			if LAP_COUNT.size() > 1:
			LAP_COUNT.show()
#			if GOALS_REACHED.size() > 1:
			GOALS_REACHED.show()
		Pfs.BASE_TYPE.BATTLE:
			$BattleStats.show()
			LEVEL_RANK.show()
			WINS.show()
			LIFE.show()
#			if GOALS_REACHED.size() > 1:
			GOALS_REACHED.show()

	if single_driver_mode:
		LEVEL_RANK.hide()

	# debug .... vsa statistika je vidna
	$BattleStats.show()
	$RaceStats.show()
	$DriverStats.show()

	LIFE.show()
	WINS.show()
	HEALTH.show()
	LEVEL_RANK.show()

	LAP_COUNT.show()
	BEST_LAP_TIME.show() # samo če bestič obstaja ... drugi krog
	LEVEL_TIME.show() # viden na koncu
	LAP_TIME.show() # viden na koncu

	POINTS.show()
	CASH.show()
	GAS.show()

	GOALS_REACHED.show()
	BULLET_COUNT.show()
	MISILE_COUNT.show()
	MINA_COUNT.show()
	SMALL_COUNT.show()


func set_statbox_align(statbox_count: int, last_in_section: bool = false):

#	var stats_to_align: Array = [$StatDriver, $BattleStats, $RaceStats]
	var stats_to_align: Array = [$DriverId, $DriverStats, $RaceStats, $BattleStats]

	# left
	if statbox_count % 2 == 0:
		for stat in stats_to_align:
			stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
	# right
	else:
		for stat in stats_to_align:
			stat.size_flags_horizontal = 0

	# top
	if statbox_count in [1, 2]:
		alignment = BoxContainer.ALIGN_BEGIN
	# center
	elif not last_in_section:
		alignment = BoxContainer.ALIGN_CENTER
	# btm
	else:
		alignment = BoxContainer.ALIGN_END
		move_child($DriverStats, get_child_count() - 1)
