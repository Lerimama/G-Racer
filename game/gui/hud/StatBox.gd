tool
extends VBoxContainer


enum BOX_ALIGN {LT_CORNER, RT_CORNER, LB_CORNER, RB_CORNER}
export (BOX_ALIGN) var statbox_hor_align: int = BOX_ALIGN.LT_CORNER setget _change_screen_align

var all_box_stats: Array

# driver
onready var stat_driver: Control = $StatDriver
onready var driver_line: HBoxContainer = $StatDriver/DriverLine
onready var driver_avatar: TextureRect = $StatDriver/DriverLine/Avatar
onready var driver_name: Label = $StatDriver/DriverLine/Name
onready var stat_cash: HBoxContainer = $StatDriver/DriverLine/StatCash
onready var stat_points: HBoxContainer = $StatDriver/DriverLine/StatPoints
onready var stat_gas: HBoxContainer = $StatDriver/DriverLine/StatGas
# race
onready var stat_level_rank: HBoxContainer = $StatDriver/DriverLine/StatLevelRank
onready var stat_lap_count: HBoxContainer = $StatDriver/DriverLine/StatLapCount
onready var stat_best_lap: HBoxContainer = $RaceStats/HBoxContainer/StatBestLap
onready var stat_level_time: HBoxContainer = $RaceStats/HBoxContainer/StatLevelTime
#battler
onready var stat_life: HBoxContainer = $StatDriver/DriverLine/StatLife
onready var stat_wins: HBoxContainer = $BattleStats/HBoxContainer/StatWins
onready var stat_bullet: HBoxContainer = $BattleStats/HBoxContainer/StatBullet
onready var stat_misile: HBoxContainer = $BattleStats/HBoxContainer/StatMisile
onready var stat_mina: HBoxContainer = $BattleStats/HBoxContainer/StatMina


func _ready() -> void:

	all_box_stats = get_children()
	var driver_stat = all_box_stats.pop_front()
	all_box_stats.push_front(stat_wins)

#	self.statbox_hor_align = statbox_hor_align

	# poravnave po vogalih
#	var stats_to_align: Array = [$StatDriver, $BattleStats, $RaceStats]
#	match statbox_hor_align:
#		BOX_ALIGN.LT_CORNER:
#			self.alignment = BoxContainer.ALIGN_BEGIN
#		BOX_ALIGN.RT_CORNER:
#			for stat in stats_to_align:
#				stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
#			self.alignment = BoxContainer.ALIGN_BEGIN
#		BOX_ALIGN.LB_CORNER:
#			self.alignment = BoxContainer.ALIGN_END
#			move_child(stat_driver, get_child_count() - 1)
#		BOX_ALIGN.RB_CORNER:
#			for stat in stats_to_align:
#				stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
#			self.alignment = BoxContainer.ALIGN_END
#			move_child(stat_driver, get_child_count() - 1)


func set_statbox_for_level(level_type: int): # kliče HUD

	# all
	stat_points.show()
	stat_cash.show()
	stat_gas.hide()
	stat_bullet.hide()
	stat_misile.hide()
	stat_mina.hide()

	# hide per level
	stat_level_rank.hide()
	stat_lap_count.hide()
	stat_wins.hide()
	stat_life.hide()
	$RaceStats.hide()
	$BattleStats.hide()

	var lap_count: = 1 # !!!
	var goals_count: = 1 # !!!
	match level_type:
		Pfs.BASE_TYPE.RACING:
			$RaceStats.show()
			stat_level_rank.show()
			if lap_count > 1:
				stat_lap_count.show()
			# ... goal_reached_count
			if goals_count > 1:
				print ("show goal count")
		Pfs.BASE_TYPE.BATTLE:
			$BattleStats.show()
			stat_level_rank.show()
			stat_wins.show()
			stat_life.show()
			# ... goal_reached_count
			if goals_count > 1:
				print ("show goal count")

	# debug .... vsa statistika je vidna
	$BattleStats.show()
	stat_level_rank.show()
	stat_wins.show()
	stat_life.show()
	$RaceStats.show()
	stat_level_rank.show()
	stat_lap_count.show()



func _change_screen_align(new_screen_align: int):

	if not get_parent():
		return
#	if statbox_hor_align == new_screen_align:
#		return

	statbox_hor_align = new_screen_align
	printt("change", statbox_hor_align, new_screen_align)
	# poravnave po vogalih
	var stats_to_align: Array = [$StatDriver, $BattleStats, $RaceStats]
	match statbox_hor_align:
		BOX_ALIGN.LT_CORNER:
			alignment = BoxContainer.ALIGN_BEGIN
			anchor_left = 0
			anchor_top = 0
			anchor_right = 0
			anchor_bottom = 0

		BOX_ALIGN.RT_CORNER:
			for stat in stats_to_align:
				stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
			alignment = BoxContainer.ALIGN_BEGIN
			anchor_left = 1
			anchor_top = 0
			anchor_right = 1
			anchor_bottom = 0
#			rect_position.x = get_parent().rect_size.x - rect_size.x
			rect_position.x -= rect_size.x
		BOX_ALIGN.LB_CORNER:
			alignment = BoxContainer.ALIGN_END
			anchor_left = 0
			anchor_top = 1
			anchor_right = 0
			anchor_bottom = 1
			move_child(stat_driver, get_child_count() - 1)
#			rect_position.y = get_parent().rect_size.y - rect_size.y
			rect_position.y -= rect_size.y
		BOX_ALIGN.RB_CORNER:
			for stat in stats_to_align:
				stat.size_flags_horizontal = MarginContainer.SIZE_SHRINK_END
			alignment = BoxContainer.ALIGN_END
			anchor_left = 1
			anchor_top = 1
			anchor_right = 1
			anchor_bottom = 1
			move_child(stat_driver, get_child_count() - 1)
			rect_position.x -= rect_size.x
			rect_position.y -= rect_size.y
#			rect_position.y = get_parent().rect_size.y - rect_size.y
#			rect_position.x = get_parent().rect_size.x - rect_size.x
