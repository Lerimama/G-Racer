extends Control


# hud colors
var stat_line_color: Color = Color.white setget _on_bolt_color_set


# values
var def_stat_value: int = 000
var current_stat_value: int


onready var stat_avatar: TextureRect = $Avatar
onready var stat_name: Label = $PlayerName
onready var stat_wins: Node2D = $StatIconsWins
onready var stat_life: Node2D = $StatIconsLife
onready var stat_misile: NinePatchRect = $StatMisile
onready var stat_shocker: NinePatchRect = $StatShocker
onready var stat_points: NinePatchRect = $StatPoints
onready var stat_bullet: NinePatchRect = $StatBullet


var player_name: String = "NN"


# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:
	
	stat_name.text = player_name


func _on_bolt_color_set(bolt_color):
	
#	stat_line_color = bolt_color
	
	stat_avatar.modulate = bolt_color # setget
	stat_name.modulate = bolt_color # setget
	stat_wins.def_stat_color = bolt_color # setget
	stat_life.def_stat_color = bolt_color # setget
	stat_misile.def_stat_color = bolt_color # setget
	stat_shocker.def_stat_color = bolt_color # setget
	stat_points.def_stat_color = bolt_color # setget
	stat_bullet.def_stat_color = bolt_color # setget
#	modulate = bolt_color
	

