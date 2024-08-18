extends Control


onready var player_line: Control = $PlayerLine
onready var player_avatar: TextureRect = $PlayerLine/Avatar
onready var player_name_label: Label = $PlayerLine/PlayerName

#onready var stat_wins: Control = $StatWins
onready var stat_wins: Control = $PlayerLine/StatWins
onready var stat_life: Control = $StatLife
onready var stat_points: HBoxContainer = $StatPoints

onready var stat_bullet: HBoxContainer = $StatBullet
onready var stat_misile: HBoxContainer = $StatMisile
onready var stat_mina: HBoxContainer = $StatMina
onready var stat_shocker: HBoxContainer = $StatShocker

onready var stat_gas: HBoxContainer = $StatGas
onready var stat_laps_count: HBoxContainer = $StatLap
onready var stat_best_lap: HBoxContainer = $StatBestLap
onready var stat_level_time: HBoxContainer = $StatLevelTime
onready var stat_level_rank: HBoxContainer = $StatRank

#var player_name: String = "NN"
#var player_avatar_texture: Texture
#var player_color: Color = Color.white

#func _ready() -> void:
#
#	player_name_label.modulate = player_color
#	stat_wins.modulate = player_color
#	player_name_label.text = player_name


