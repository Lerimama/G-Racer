extends Control


var player_name: String = "NN"

# hud colors
var statbox_color: Color = Color.white setget _on_bolt_color_set

# values
var def_stat_value: int = 000
var current_stat_value: int

onready var player_line: Control = $PlayerLine

onready var stat_avatar: TextureRect = $Avatar
onready var stat_name: Label = $PlayerLine/PlayerName

onready var stat_wins: Control = $StatIconsWins
onready var stat_life: Control = $StatIconsLife
onready var stat_points: HBoxContainer = $StatPoints

onready var stat_bullet: HBoxContainer = $StatBullet
onready var stat_misile: HBoxContainer = $StatMisile
onready var stat_mina: HBoxContainer = $StatMina
onready var stat_shocker: HBoxContainer = $StatShocker

onready var stat_gas: HBoxContainer = $StatGas
onready var stat_laps_count: HBoxContainer = $StatLap
onready var stat_fastest_lap: HBoxContainer = $StatFastestLap
onready var stat_level_time: HBoxContainer = $StatLevelTime
onready var stat_level_rank: HBoxContainer = $StatRank


func _ready() -> void:
	
	stat_name.text = player_name


func _on_bolt_color_set(bolt_color):
	# mroajo bit ločeno, da jih lahko abrvam med igro
	
	for stat in get_children():
		stat.modulate = bolt_color # setget
#	stat_avatar.modulate = bolt_color # setget
#	stat_name.modulate = bolt_color # setget
#	stat_wins.def_stat_color = bolt_color # setget
#	stat_life.def_stat_color = bolt_color # setget
#	stat_misile.def_stat_color = bolt_color # setget
#	stat_mina.def_stat_color = bolt_color # setget
#	stat_shocker.def_stat_color = bolt_color # setget
#	stat_points.def_stat_color = bolt_color # setget
#	stat_bullet.def_stat_color = bolt_color # setget
#	stat_gas.def_stat_color = bolt_color # setget
#	stat_laps_count.def_stat_color = bolt_color
#	stat_fastest_lap.def_stat_color = bolt_color	
#	stat_level_time.def_stat_color = bolt_color	


