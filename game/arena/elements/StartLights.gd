extends Node2D


signal countdown_finished


var light_index: int = 0
onready var on_lights: Array = $OnLights.get_children()
onready var off_lights: Array = $OffLights.get_children()
onready var timer: Timer = $Timer


func _ready() -> void:
	
	for light in off_lights:
		light.show()
	for light in on_lights:
		light.hide()
	
	
func start_countdown():
	
	if Ref.game_manager.game_settings["start_countdown"]:
		visible = true
		$Timer.start()
		turn_on_light()
	else:
		visible = false
		call_deferred("emit_signal", "countdown_finished") # GM yielda za ta signal


func turn_on_light():
	
	if light_index < 3:
		$CountdownA.play()
		on_lights[light_index].show()
		off_lights[light_index].hide()
		light_index += 1
		$Timer.start()
	else:
		turn_off_all_lights()
	

func turn_off_all_lights():
	
	light_index = 0
	$CountdownB.play()
	emit_signal("countdown_finished") # GM yielda za ta signal
	
	for light in on_lights:
		var turn_off_tween = get_tree().create_tween()
		turn_off_tween.tween_property(light, "modulate:a", 0, 0.2)
		turn_off_tween.tween_callback(light, "hide")



func _on_Timer_timeout() -> void:
	
	turn_on_light()
