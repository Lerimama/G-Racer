extends Node2D


signal countdown_finished

var light_index: int = 0

onready var on_lights: Array = $OnLights.get_children()
onready var off_lights: Array = $OffLights.get_children()
onready var countdown_a: AudioStreamPlayer = $Sounds/CountdownA
onready var countdown_b: AudioStreamPlayer = $Sounds/CountdownB


func _ready() -> void:

#	visible = Sets.start_countdown
	show()

	for light in off_lights:
		light.show()
	for light in on_lights:
		light.hide()


func start_countdown():

	turn_on_light()


func turn_on_light():

	if light_index < on_lights.size():
		countdown_a.play()
		on_lights[light_index].show()
		off_lights[light_index].hide()
		light_index += 1
		yield(get_tree().create_timer(1), "timeout")
		turn_on_light()
	else:
#		yield(get_tree().create_timer(1), "timeout") # razlika do ene sekunde
		turn_off_all_lights()


func turn_off_all_lights():

	light_index = 0
	countdown_b.play()

	var off_time: float = 0.05
	var turn_off_tween = get_tree().create_tween()
	turn_off_tween.tween_property(self, "modulate:a", 0, off_time)
	yield(turn_off_tween, "finished")
	# ni signala ker igra štopa sama
	#	emit_signal("countdown_finished") # GM yielda za ta signal
	hide()



func _on_Timer_timeout() -> void:

	turn_on_light()
