extends Control


export var countdown_time: float = 5
#export(int, -1, 1) var timer_mode
var timer_mode: = -1

#var game_is_on: bool = false 
var current_time = 0 # to je za beleženje tre


onready var count_down: Label = $CountDown
onready var start: Label = $Start


func _ready() -> void:
	
	start.visible =  false
	count_down.visible =  true
	
func _physics_process(delta: float) -> void:
	
	current_time += delta
	
	if not Ref.game_manager.game_on:
#	if not get_parent().game_is_on:
		if current_time < (countdown_time - 1): # - 1 zato  ker se končana prvi sekundi
			count_down.text = "%02d" % round(countdown_time - current_time)
		else:
			yield(get_tree().create_timer(0), "timeout")
			count_down.visible =  false
			yield(get_tree().create_timer(0.2), "timeout")
			start.visible = true
			yield(get_tree().create_timer(1), "timeout")
#			start.visible = false
#			yield(get_tree().create_timer(5.5), "timeout")
#			Ref.game_manager.game_on = true
#	if game_is_on:
#
#		current_second = round(time_seconds + game_time * timer_mode) # -1 ena je odštevanje
#
#		if current_second < 0:
#			game_time = 0
#			current_second = time_seconds
#			time_minutes += timer_mode
#			minutes.text = "%02d" % time_minutes	
#
#		if time_minutes < 1:
#			clock.modulate = Set.color_red
#		if time_minutes < 0:
#			game_is_on = false
#			clock.visible = false
#			yield(get_tree().create_timer(1), "timeout")
#			game_over.visible = true
#			modulate = Color.blue
#	else: 
#		game_time = 0
#
		
	
	
