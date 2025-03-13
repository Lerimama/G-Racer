extends Node2D


signal countdown_finished

var light_index: int = 0

onready var on_lights: Array = $OnLights.get_children()
onready var off_lights: Array = $OffLights.get_children()
onready var light_timer: Timer = $LightTimer
onready var countdown_a: AudioStreamPlayer = $Sounds/CountdownA
onready var countdown_b: AudioStreamPlayer = $Sounds/CountdownB


func _ready() -> void:

	visible = Sts.start_countdown

	for light in off_lights:
		light.show()
	for light in on_lights:
		light.hide()


func start_countdown():

	show()
	light_timer.start()
	turn_on_light()


func turn_on_light():

	if light_index < 3:
		countdown_a.play()
		on_lights[light_index].show()
		off_lights[light_index].hide()
		light_index += 1
		light_timer.start()
	else:
		turn_off_all_lights()


func turn_off_all_lights():

	light_index = 0
	countdown_b.play()

	var off_time: float = 0.2
	for light in on_lights:
		var turn_off_tween = get_tree().create_tween()
		turn_off_tween.tween_property(light, "modulate:a", 0, off_time)
		turn_off_tween.tween_callback(light, "hide")
	yield(get_tree().create_timer(off_time), "timeout")
	emit_signal("countdown_finished") # GM yielda za ta signal



func _on_Timer_timeout() -> void:

	turn_on_light()
