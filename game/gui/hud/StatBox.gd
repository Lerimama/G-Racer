tool
extends Control


enum BOX_ALIGN {LT_CORNER, RT_CORNER, LB_CORNER, RB_CORNER}
export (BOX_ALIGN) var statbox_hor_align: int = BOX_ALIGN.LT_CORNER

var all_box_stats: Array

onready var stat_driver: Control = $StatDriver
onready var driver_line: HBoxContainer = $StatDriver/DriverLine
onready var driver_avatar: TextureRect = driver_line.get_node("Avatar")
onready var driver_name_label: Label = driver_line.get_node("Name")

onready var stat_wins: Control = driver_line.get_node("StatWins")
onready var stat_life: Control = $StatLife
onready var stat_points: HBoxContainer = $StatPoints
onready var stat_cash: HBoxContainer = $StatCash

onready var stat_bullet: HBoxContainer = $StatBullet
onready var stat_misile: HBoxContainer = $StatMisile
onready var stat_mina: HBoxContainer = $StatMina

onready var stat_gas: HBoxContainer = $StatGas
onready var stat_laps_count: HBoxContainer = $StatLap
onready var stat_best_lap: HBoxContainer = $StatBestLap
onready var stat_level_time: HBoxContainer = $StatLevelTime
onready var stat_level_rank: HBoxContainer = $StatRank


func _ready() -> void:

	all_box_stats = get_children()
	var driver_stat = all_box_stats.pop_front()
	all_box_stats.push_front(stat_wins)

	# poravnave po vogalih
	var nodes_to_align: Array = get_children()
	nodes_to_align.erase(driver_stat)
	nodes_to_align.append(driver_line)
	match statbox_hor_align:
		BOX_ALIGN.LT_CORNER:
			for node in nodes_to_align:
				node.alignment = BoxContainer.ALIGN_BEGIN
			self.alignment = BoxContainer.ALIGN_BEGIN
		BOX_ALIGN.RT_CORNER:
			for node in nodes_to_align:
				node.alignment = BoxContainer.ALIGN_END
			self.alignment = BoxContainer.ALIGN_BEGIN
		BOX_ALIGN.LB_CORNER:
			for node in nodes_to_align:
				node.alignment = BoxContainer.ALIGN_BEGIN
			self.alignment = BoxContainer.ALIGN_END
			move_child(stat_driver, get_child_count() - 1)
		BOX_ALIGN.RB_CORNER:
			for node in nodes_to_align:
				node.alignment = BoxContainer.ALIGN_END
			self.alignment = BoxContainer.ALIGN_END
			move_child(stat_driver, get_child_count() - 1)

	# setam širino zaradi širine imena
#	yield(get_tree(), "idle_frame")
	driver_stat.rect_min_size.x = driver_line.rect_size.x - 32
	driver_stat.rect_size.x = driver_stat.rect_min_size.x
#	655
#	rect_size.x = driver_line.rect_size.x
