extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

enum TimerStates {COUNTING, STOPPED, PAUSED}
var current_timer_state: int = TimerStates.STOPPED

var limitless_mode: bool # če je gejm tajm 0 in je count-up mode
var absolute_game_time: float # pozitiven čas igre v sekundah
var coundown_second: int # za uravnavanje GO odštevanja ... opredeli s v ready

var game_time_limit: int
#onready var game_time_limit: int = Ref.game_manager.level_settings["time_limit"]
#onready var sudden_death_mode: int = Ref.game_manager.game_settings["sudden_death_mode"]
#onready var sudden_death_limit: int = Ref.game_manager.game_settings["sudden_death_limit"]
#onready var stopwatch_mode: bool = Ref.game_manager.game_settings["stopwatch_mode"]
#onready var gameover_countdown_duration: int = Ref.game_manager.game_settings["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip

var sudden_death_mode: bool
var sudden_death_limit: int
var stopwatch_mode: bool
var gameover_countdown_duration: int

func _ready() -> void:
	
	if game_time_limit == 0:
		limitless_mode = true
		stopwatch_mode = true # avtomatično pač ...
	coundown_second = gameover_countdown_duration
	modulate = Set.color_hud_base
	# debug
#	stopwatch_mode = true 
#	game_time_limit = 10


func _process(delta: float) -> void:
	
	# če je ustavljen, se tukaj ustavim
	if not current_timer_state == TimerStates.COUNTING:
		if absolute_game_time == 0:
			if not stopwatch_mode:
				$Mins.text = "%02d" % (game_time_limit / 60)
				$Secs.text = "%02d" % (game_time_limit % 60)
				$Hunds.text = "00"
				pass				
			else:
				$Mins.text = "00"
				$Secs.text = "00"
				$Hunds.text = "00"
		return
		
	# game time
	absolute_game_time += delta # stotinke ... absouletnega uporabljam za izračune v vseh modetih
	
	# display
	if stopwatch_mode:	
		$Mins.text = "%02d" % floor(absolute_game_time/60)
		$Secs.text = "%02d" % (floor(absolute_game_time) - floor(absolute_game_time/60) * 60)
		$Hunds.text = "%02d" % floor((absolute_game_time - floor(absolute_game_time)) * 100)
	else:
		var game_time_left = game_time_limit - absolute_game_time # stotinke
		$Mins.text = "%02d" % (floor(game_time_left/60))
		$Secs.text = "%02d" % (floor(game_time_left) - floor(game_time_left/60) * 60)
		$Hunds.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)	
	
	# time limits ... višja limita je prva, nižje sledijo 
	if not limitless_mode:
		# game time is up
		if absolute_game_time >= game_time_limit: 
			modulate = Set.color_red
			Ref.sound_manager.play_gui_sfx("game_countdown_a")
			stop_timer()
			emit_signal("gametime_is_up") # pošlje se v hud, ki javi GM	
		# GO countdown
		elif absolute_game_time > (game_time_limit - gameover_countdown_duration):
			# za vsakič, ko mine sekunda 
			if absolute_game_time == (game_time_limit - coundown_second): 
				coundown_second -= 1
				modulate = Set.color_yellow
				Ref.sound_manager.play_gui_sfx("game_countdown_b")
		# sudden death 
		elif absolute_game_time > (game_time_limit - sudden_death_limit) and sudden_death_mode: 
			modulate = Set.color_green
			emit_signal("sudden_death_activated") # pošlje se v hud, ki javi game managerju
		else:
			modulate = Set.color_hud_base
	
	
func start_timer():
	game_time_limit = Ref.game_manager.level_settings["time_limit"]
	sudden_death_mode = Ref.game_manager.game_settings["sudden_death_mode"]
	sudden_death_limit = Ref.game_manager.game_settings["sudden_death_limit"]
	stopwatch_mode = Ref.game_manager.game_settings["stopwatch_mode"]
	gameover_countdown_duration = Ref.game_manager.game_settings["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip	
	
	# reset vrendosti se zgodi na štart (ne na stop)
	absolute_game_time = 0
	current_timer_state = TimerStates.COUNTING


func pause_timer():
	
	current_timer_state = TimerStates.PAUSED
	modulate = Set.color_blue
	

func unpause_timer():
	
	current_timer_state = TimerStates.COUNTING
	
		
func stop_timer():
	
	current_timer_state = TimerStates.STOPPED
	modulate = Set.color_red
