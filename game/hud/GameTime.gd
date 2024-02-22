extends Control


#export(int, -1, 1) var timer_mode
var timer_mode: = -1
var game_is_on: bool 

var game_time: float
export var time_minutes: float = 5
var time_seconds: float = 59
#export(float, 1, 60, 1) var time_seconds = 59
var current_second = time_seconds # to je za beleženje tre

var game_time_limit: float
var deathmatch_time: float
var minute_in_seconds = 60

onready var clock: Control = $clock
onready var minutes: Label = $clock/Minutes
onready var seconds: Label = $clock/Seconds
#onready var game_over: Label = $GameOver
onready var game_over: Control = $"../Popups/GameOver"


func _ready() -> void:
	
#	game_over.visible = false
	clock.visible =  true
#	get_parent().game_is_on = true
	
	minutes.text = "%02d" % time_minutes
	seconds.text = "%02d" % time_seconds

func _physics_process(delta: float) -> void:
	
	if get_parent().game_is_on:
		game_time += delta
		
		current_second = round(time_seconds + game_time * timer_mode) # -1 ena je odštevanje
		
		if current_second < 0:
			game_time = 0
			current_second = time_seconds
			time_minutes += timer_mode
			minutes.text = "%02d" % time_minutes	
		seconds.text = "%02d" % (current_second)
		
		if time_minutes < 1:
			clock.modulate = Set.color_red
		if time_minutes < 0:
			game_is_on = false
			clock.visible = false
			yield(get_tree().create_timer(1), "timeout")
			game_over.visible = true
#			modulate = Color.blue
	else: 
		game_time = 0
		
		
	
	
