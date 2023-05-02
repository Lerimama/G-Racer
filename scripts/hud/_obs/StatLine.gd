extends Node2D


onready var stat_icon: TextureRect = $Icon
onready var stat_label: Label = $Label

# hud colors
var def_stat_color: Color = Color.white setget _on_bolt_color_set
var minus_color: Color = Config.color_red
var plus_color: Color = Config.color_green
var off_color: Color = Config.color_gray0

var color_blink_time: float = 0.5

# values
var def_stat_value: int = 0
var current_stat_value: int = 5 setget _on_stat_change

onready var stat_icon_1: Sprite = $StatIcon1
onready var stat_icon_2: Sprite = $StatIcon2
onready var stat_icon_3: Sprite = $StatIcon3
onready var stat_icon_4: Sprite = $StatIcon4
onready var stat_icon_5: Sprite = $StatIcon5

onready var life_on: Node2D = $LifeOn

var stat_icons: Array

# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:
	
	stat_icons = [
		stat_icon_1,
		stat_icon_2,
		stat_icon_3,
		stat_icon_4,
		stat_icon_5,
	]

func _on_stat_change(new_stat_value):
	
	# s pomočjo vrednosti stata naslavljam ikono z indexom kolikor ma še lajfa
	var current_icon = stat_icons[current_stat_value - 1]
	
	# če bo šlo navzgor
	if new_stat_value > current_stat_value:
		
		current_icon.modulate = plus_color
		yield(get_tree().create_timer(1), "timeout")
		current_icon.modulate = off_color
		
		current_stat_value = new_stat_value
	
	# če bo šlo navzdol
	elif new_stat_value < current_stat_value:
		
		current_icon.modulate = minus_color
		yield(get_tree().create_timer(1), "timeout")
		current_icon.modulate = off_color
		
		current_stat_value = new_stat_value


func _on_bolt_color_set(bolt_color):
	def_stat_color = bolt_color
	
	for icon in stat_icons:
		icon.modulate = def_stat_color
