extends NinePatchRect


# hud colors
var def_icon_color : Color = GameProfiles.default_game_theme["icon_color"]
var def_label_color : Color = GameProfiles.default_game_theme["label_color"]
var minus_color : Color = GameProfiles.default_game_theme["minus_color"]
var plus_color : Color = GameProfiles.default_game_theme["plus_color"]

# values
var counter_def_value : int = 0
var current_value = counter_def_value


# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:
#	$Label.modulate = def_label_color
#	$Icon.modulate = def_icon_color

	pass

func _fx_on_stat_change(new_value):

	if new_value > current_value:
		$Tween.interpolate_property($Label, "modulate", plus_color, def_label_color, 2, Tween.CONNECT_ONESHOT, Tween.EASE_OUT)
		$Tween.start()
		current_value = new_value

#	elif new_value < current_value:
#		$Tween.interpolate_property($Label, "modulate", minus_color, def_label_color, 0.7, Tween.CONNECT_ONESHOT, Tween.EASE_OUT)
#		$Tween.start()
#		current_value = new_value
#
