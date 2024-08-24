extends Control


enum AlignOptions {LT_CORNER, RT_CORNER, LB_CORNER, RB_CORNER}
export (AlignOptions) var statbox_hor_align: int = AlignOptions.LT_CORNER 
	
onready var player_line: HBoxContainer = $PlayerLine
onready var player_avatar: TextureRect = $PlayerLine/Avatar
onready var player_name_label: Label = $PlayerLine/PlayerName

onready var stat_wins: Control = $PlayerLine/StatWins
onready var stat_life: Control = $StatLife
onready var stat_points: HBoxContainer = $StatPoints

onready var stat_bullet: HBoxContainer = $StatBullet
onready var stat_misile: HBoxContainer = $StatMisile
onready var stat_mina: HBoxContainer = $StatMina

onready var stat_gas: HBoxContainer = $StatGas
onready var stat_laps_count: HBoxContainer = $StatLap
onready var stat_best_lap: HBoxContainer = $StatBestLap
onready var stat_level_time: HBoxContainer = $StatLevelTime
onready var stat_level_rank: HBoxContainer = $StatRank


func _ready() -> void:
	
	# poravnave po vogalih
	match statbox_hor_align:
		AlignOptions.LT_CORNER:
			for node in get_children():
				node.alignment = BoxContainer.ALIGN_BEGIN
			self.alignment = BoxContainer.ALIGN_BEGIN
		AlignOptions.RT_CORNER:
			for node in get_children():
				node.alignment = BoxContainer.ALIGN_END 
			self.alignment = BoxContainer.ALIGN_BEGIN
		AlignOptions.LB_CORNER:
			for node in get_children():
				node.alignment = BoxContainer.ALIGN_BEGIN
			self.alignment = BoxContainer.ALIGN_END
		AlignOptions.RB_CORNER:
			for node in get_children():
				node.alignment = BoxContainer.ALIGN_END
			self.alignment = BoxContainer.ALIGN_END
