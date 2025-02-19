tool
extends VBoxContainer


var all_box_stats: Array


# driver
onready var driver_line: HBoxContainer = $DriverId/DriverLine
onready var driver_avatar: TextureRect = $DriverId/DriverLine/Avatar
onready var driver_name: Label = $DriverId/DriverLine/Name
#onready var stat_cash: HBoxContainer = $StatDriver/DriverLine/StatCash
#onready var stat_points: HBoxContainer = $StatDriver/DriverLine/StatPoints
#onready var stat_gas: HBoxContainer = $StatDriver/DriverLine/StatGas

# driver
#onready var stat_cash: HBoxContainer = $DriverStats/HBoxContainer/StatCash
#onready var stat_points: HBoxContainer = $DriverStats/HBoxContainer/StatPoints
#onready var stat_gas: HBoxContainer = $DriverStats/HBoxContainer/StatGas
#
## race
#onready var stat_lap_count: HBoxContainer = $RaceStats/HBoxContainer/StatLapCount
#onready var stat_best_lap: HBoxContainer = $RaceStats/HBoxContainer/StatBestLap
#onready var stat_level_time: HBoxContainer = $RaceStats/HBoxContainer/StatLevelTime
#
## battle
#onready var stat_bullet: HBoxContainer = $BattleStats/HBoxContainer/StatBullet
#onready var stat_misile: HBoxContainer = $BattleStats/HBoxContainer/StatMisile
#onready var stat_mina: HBoxContainer = $BattleStats/HBoxContainer/StatMina

onready var LIFE: HBoxContainer = $DriverId/DriverLine/StatLife
onready var LEVEL_RANK: HBoxContainer = $DriverId/DriverLine/StatLevelRank
onready var WINS: HBoxContainer = $DriverId/DriverLine/StatWins

# driver
onready var CASH: HBoxContainer = $DriverStats/HBoxContainer/StatCash
onready var POINTS: HBoxContainer = $DriverStats/HBoxContainer/StatPoints
onready var GAS: HBoxContainer = $DriverStats/HBoxContainer/StatGas

# race
onready var LAP_COUNT: HBoxContainer = $RaceStats/HBoxContainer/StatLapCount
onready var BEST_LAP_TIME: HBoxContainer = $RaceStats/HBoxContainer/StatBestLap
onready var LEVEL_TIME: HBoxContainer = $RaceStats/HBoxContainer/StatLevelTime

# battle
onready var BULLET_COUNT: HBoxContainer = $BattleStats/HBoxContainer/StatBullet
onready var MISILE_COUNT: HBoxContainer = $BattleStats/HBoxContainer/StatMisile
onready var MINA_COUNT: HBoxContainer = $BattleStats/HBoxContainer/StatMina
onready var GOALS_REACHED: HBoxContainer = $BattleStats/HBoxContainer/GoalReached


#	enum STATS {
#	WINS, LIFE, HEALTH, POINTS, GAS, CASH,
#	BULLET_COUNT, MISILE_COUNT, MINA_COUNT, SMALL_COUNT,
#	LEVEL_RANK, LAP_COUNT, BEST_LAP_TIME, LEVEL_TIME, GOALS_REACHED
#	}

#func _ready() -> void:
#
#	all_box_stats = get_children()
#	var driver_stat = all_box_stats.pop_front()
#	all_box_stats.push_front(stat_wins)


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
	LEVEL_RANK.show()

	LAP_COUNT.show()
	BEST_LAP_TIME.show() # samo če bestič obstaja ... drugi krog
	LEVEL_TIME.show() # viden na koncu

	POINTS.show()
	CASH.show()
	GAS.show()

	GOALS_REACHED.show()
	BULLET_COUNT.show()
	MISILE_COUNT.show()
	MINA_COUNT.show()

#
#func set_statbox_elements_small(level_type: int, single_driver_mode: bool = false): # kliče HUD
#
#	# tole je treba spucat
#
#	# all
#	stat_points.show()
#	stat_cash.show()
#	stat_gas.hide()
#	stat_bullet.hide()
#	stat_misile.hide()
#	stat_mina.hide()
#
#	# hide per level
#	stat_level_rank.hide()
#	stat_lap_count.hide()
#	stat_wins.hide()
#	stat_life.hide()
#	$RaceStats.hide()
#	$BattleStats.hide()
#
#	var lap_count: = 1 # !!!
#	var goals_count: = 1 # !!!
#	match level_type:
#		Pfs.BASE_TYPE.RACING:
#			$RaceStats.show()
#			stat_level_rank.show()
#			if lap_count > 1:
#				stat_lap_count.show()
#			# ... goal_reached_count
#			if goals_count > 1:
#				print ("show goal count")
#		Pfs.BASE_TYPE.BATTLE:
#			$BattleStats.show()
#			stat_level_rank.show()
#			stat_wins.show()
#			stat_life.show()
#			# ... goal_reached_count
#			if goals_count > 1:
#				print ("show goal count")
#
#	if single_driver_mode:
#		stat_level_rank.hide()
#
#	# debug .... vsa statistika je vidna
#	$BattleStats.show()
#	stat_level_rank.show()
#	stat_wins.show()
#	stat_life.show()
#	$RaceStats.show()
#	stat_level_rank.show()
#	stat_lap_count.show()
##	modulate = Color.green


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
		move_child($StatDriver, get_child_count() - 1)
