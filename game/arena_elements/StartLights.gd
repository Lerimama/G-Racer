extends Node2D


signal countdown_finished

var light_index: int = 0
onready var all_lights: Array = [$Light1, $Light2, $Light3]


func _ready() -> void:

#	if not Ref.game_manager.game_settings["start_countdown"]:	
#		visible = false
	pass
	
func start_countdown():
	if Ref.game_manager.game_settings["start_countdown"]:
		yield(get_tree().create_timer(2), "timeout")
		$Timer.start()
		turn_on_light()
	else:
		yield(get_tree().create_timer(0.5), "timeout")
		emit_signal("countdown_finished") # GM yielda za ta signal
		print("START")


func turn_on_light():
	
	if light_index <= 2:
		$CountdownA.play()
		
		var current_light_to_turn_on: Sprite = all_lights[light_index]
		# print ("prižigam", current_light_to_turn_on)
		# Ref.sound_manager.play_gui_sfx("start_countdown_b")
		
		var turn_on_tween = get_tree().create_tween()
		turn_on_tween.tween_property(current_light_to_turn_on, "modulate", Set.color_red, 0.1)
		light_index += 1
	elif light_index < 3:
		light_index += 1
	else:
		turn_off_all_lights()
		light_index = 0
	

func turn_off_all_lights():
	
	$Timer.stop()
	# Ref.sound_manager.play_gui_sfx("start_countdown_a")
	emit_signal("countdown_finished") # GM yielda za ta signal
	print("START")
	
	for light in all_lights:
		var turn_off_tween = get_tree().create_tween()
		turn_off_tween.tween_property(light, "modulate:a", 0, 0.2)

	$CountdownB.play()


func _on_Timer_timeout() -> void:
	
	turn_on_light()
