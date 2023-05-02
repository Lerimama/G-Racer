extends NinePatchRect

#
##colors
#
#var def_icon_color : Color = Color.white
#var def_label_color : Color = Color.white
#var minus_color : Color = Color.red
#var plus_color : Color = Color.green 	# drugačna ker se to zgodi na bonus efekt 
#
#var current_color : Color
#
#
## values
#
#var counter_def_value : int = 0	# bo določeno s strani game rules fileta
#var current_value = counter_def_value 
#
#
## -------------------------------------------------------------------------------------------------------------------------------
#
#
#func _ready() -> void:
#	$Label.modulate = def_label_color
#	$Icon.modulate = def_icon_color
#
#func _fx_on_stat_change(new_value):
#
#	if new_value > current_value:  
#		$Tween.interpolate_property($Label, "modulate", plus_color, def_label_color, 2, Tween.CONNECT_ONESHOT, Tween.EASE_OUT)
#		$Tween.start()
#		current_value = new_value
#
#	elif new_value < current_value:
#		$Tween.interpolate_property($Label, "modulate", minus_color, def_label_color, 0.7, Tween.CONNECT_ONESHOT, Tween.EASE_OUT)
#		$Tween.start()
#		current_value = new_value
#
