extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

enum TimerStates {COUNTING, STOPPED, PAUSED}
var current_timer_state: int = TimerStates.STOPPED


var game_time: float # čas igre v sekundah z decimalkami
var game_time_hunds: int # čas igre v zaokroženih stotinkah
var limitless_mode: bool # če je gejm tajm 0 in je count-up mode
var coundown_second: int # za uravnavanje GO odštevanja ... opredeli s v ready

var game_time_limit: int
var sudden_death_mode: bool
var sudden_death_limit: int
var stopwatch_mode: bool
var gameover_countdown_duration: int

onready var mins_label: Label = $Mins
onready var secs_label: Label = $Secs
onready var hunds_label: Label = $Hunds

func _ready() -> void:
	
	# večino setam ob štartu tajmerja
		

	modulate = Ref.color_hud_base
	# debug
#	stopwatch_mode = true 
#	game_time_limit = 10


func _process(delta: float) -> void:
	
	# če je ustavljen, se tukaj ustavim
	if not current_timer_state == TimerStates.COUNTING:
		if game_time == 0:
			if not stopwatch_mode:
				mins_label.text = "%02d" % (game_time_limit / 60.0)
				secs_label.text = "%02d" % (game_time_limit % 60)
				hunds_label.text = "00"
				pass				
			else:
				mins_label.text = "00"
				secs_label.text = "00"
				hunds_label.text = "00"
		return
		
	# game time
	game_time += delta # sekunde z decimalkami ... uporabljam za izračune v vseh modetih
	game_time_hunds = round(game_time * 100)
	
	# display
	if stopwatch_mode:	
		mins_label.text = "%02d" % floor(game_time/60)
		secs_label.text = "%02d" % (floor(game_time) - floor(game_time / 60.0) * 60)
		hunds_label.text = "%02d" % floor((game_time - floor(game_time)) * 100)
	else:
		var game_time_left = game_time_limit - game_time # stotinke
		mins_label.text = "%02d" % (floor(game_time_left/60))
		secs_label.text = "%02d" % (floor(game_time_left) - floor(game_time_left / 60.0) * 60)
		hunds_label.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)	
	
	# time limits ... višja limita je prva, nižje sledijo 
	if not limitless_mode:
		# game time is up
		if game_time >= game_time_limit: 
			modulate = Ref.color_red
			Ref.sound_manager.play_gui_sfx("game_countdown_a")
			stop_timer()
			emit_signal("gametime_is_up") # pošlje se v hud, ki javi GM	
		# GO countdown
		elif game_time > (game_time_limit - gameover_countdown_duration):
			# za vsakič, ko mine sekunda 
			if game_time == (game_time_limit - coundown_second): 
				coundown_second -= 1
				modulate = Ref.color_yellow
				Ref.sound_manager.play_gui_sfx("game_countdown_b")
		# sudden death 
		elif game_time > (game_time_limit - sudden_death_limit) and sudden_death_mode: 
			modulate = Ref.color_green
			emit_signal("sudden_death_activated") # pošlje se v hud, ki javi game managerju
		else:
			modulate = Ref.color_hud_base
	

func reset_timer():
	game_time = 0
	modulate = Ref.color_hud_base

	
func start_timer():

	game_time_limit = Ref.game_manager.level_settings["time_limit"]
	sudden_death_mode = Ref.game_manager.game_settings["sudden_death_mode"]
	sudden_death_limit = Ref.game_manager.game_settings["sudden_death_limit"]
	stopwatch_mode = Ref.game_manager.game_settings["stopwatch_mode"]
	gameover_countdown_duration = Ref.game_manager.game_settings["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip	

	if game_time_limit == 0:
		limitless_mode = true
		stopwatch_mode = true # avtomatično pač ...
	coundown_second = gameover_countdown_duration	
		
	# reset vrendosti se zgodi na štart (ne na stop)
	game_time = 0
	current_timer_state = TimerStates.COUNTING


func pause_timer():
	
	current_timer_state = TimerStates.PAUSED
	modulate = Ref.color_blue
	

func unpause_timer():
	
	current_timer_state = TimerStates.COUNTING
	
		
func stop_timer():
	
	current_timer_state = TimerStates.STOPPED
	modulate = Ref.color_red
