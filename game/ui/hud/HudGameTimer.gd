extends Control


signal sudden_death_active # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

var limitless_mode: bool # če je gejm tajm 0 in je count-up mode

onready var game_time_limit: int = Set.default_game_settings["game_time_limit"]
onready var sudden_death_mode: int = Set.default_game_settings["suddent_death_mode"]
onready var sudden_death_limit: int = Set.default_game_settings["sudden_death_limit"]
onready var stopwatch_mode: bool = Set.default_game_settings["stopwatch_mode"]
onready var gameover_countdown_duration: int = Set.default_game_settings["gameover_countdown_duration"] # čas, ko je obarvan in se sliši bip bip

# neu 
var hundreds_mode: bool = true # če so stotinke, timerjev sekundni signal ni zaznan
var current_minutes: float = 0
var current_seconds: float = 0
var current_hundreds: float = 0
var current_game_time: int # čas igre stotinkah ... skor isto kot time_since_start
# optimiziraj
var current_second: int = 0 # trenutna sekunda znotraj minutnega kroga ... ia izpis na uri
var game_time_seconds: int = 0 # čas igre v sekundah ... GLAVNI TIMER, po katerem se vse umerja ... zadelovanje timerja


func _ready() -> void:
	
	modulate = Set.color_hud_base
	
	# display pred štartom
	if not stopwatch_mode:
		$Mins.text = "%02d" % (game_time_limit / 60)
		$Secs.text = "%02d" % (game_time_limit % 60)
		hundreds_mode
		$Dots2.hide()
		$Hunds.hide()
	elif game_time_limit == 0:
		limitless_mode = true
	
	
	
func _process(delta: float) -> void:
	
	# če ne štopam se tukaj ustavim
	if $Timer.is_stopped() or $Timer.paused:
		return
		
	# game time
	current_game_time += delta * 100 # stotinke
	var current_clock_time: Array = Met.get_clock_time(current_game_time)
	printt("current_clock_time", current_clock_time)
	
	# display
	$Mins.text = "%02d" % current_clock_time[0]
	$Secs.text = "%02d" % current_clock_time[1]
	$Hunds.text = "%02d" % current_clock_time[2]
		
		
	current_second = int(game_time_seconds) % 60
	if not stopwatch_mode: # samo sekunde
		if game_time_seconds <= 0: # time is up
			stop_timer()
			current_second = 0
			modulate = Set.color_red
			emit_signal("gametime_is_up") # pošlje se v hud, ki javi game managerju		
		if sudden_death_mode:
			if game_time_seconds > sudden_death_limit:
				modulate = Set.color_hud_base
			elif game_time_seconds == sudden_death_limit:
				emit_signal("sudden_death_active") # pošlje se v hud, ki javi game managerju		
			elif game_time_seconds < sudden_death_limit:
				modulate = Set.color_red
	else:
		if game_time_seconds >= game_time_limit and not limitless_mode: # ker uravnavam s časom, ki je PRETEKEL
			stop_timer()
			emit_signal("gametime_is_up")
			print("gametime_is_up")
		if sudden_death_mode:
			if game_time_seconds < game_time_limit - sudden_death_limit:
				modulate = Set.color_hud_base
			elif game_time_seconds == game_time_limit - sudden_death_limit:
				emit_signal("sudden_death_active") # pošlje se v hud, ki javi game managerju		
			elif game_time_seconds > game_time_limit - sudden_death_limit:
				modulate = Set.color_red

	
func start_timer():

	# reset vrendosti ... zazih
	current_game_time = 0
		
	modulate = Set.color_hud_base

	if not stopwatch_mode:
		# če odštevam je začetna številka enaka time limitu v
		game_time_seconds = game_time_limit
		# sekunde v obsegu minute
		current_second = game_time_seconds % 60
		$Mins.text = "%02d" % (game_time_seconds / 60)
		$Secs.text = "%02d" % current_second
		$Hunds.text = "00"	
	else:
		# če prišteam je začetna številka 0
		game_time_seconds = 0
		$Mins.text = "00"
		$Secs.text = "00"
		$Hunds.text = "00"	
	
	$Timer.start()


func pause_timer():
	
	$Timer.set_paused(true)
	modulate = Set.color_blue
	

func unpause_timer():
	
	$Timer.set_paused(false)
	modulate = Set.color_hud_base
	
		
func stop_timer():
	
	$Timer.stop()
	modulate = Set.color_red
	
		
func _on_Timer_timeout() -> void:
	
	if not hundreds_mode:
		print("Timer second")
		add_time_seconds(1)

	
func add_time_seconds(seconds_to_add: float):

#	time_since_start += seconds_to_add
	
	if not stopwatch_mode:
		game_time_seconds -= 1
		# game over countdown
		if game_time_seconds < 1:
			Ref.sound_manager.play_gui_sfx("game_countdown_b")
			modulate = Set.color_red
		elif game_time_seconds <= gameover_countdown_duration and game_time_seconds > 0:
			Ref.sound_manager.play_gui_sfx("game_countdown_a")
			modulate = Set.color_red
	else:
		game_time_seconds += 1
		# game over countdown
		if not limitless_mode:
			if game_time_seconds > game_time_limit - 1:
				Ref.sound_manager.play_gui_sfx("countdown_b")
				modulate = Set.color_red
			elif game_time_seconds >= game_time_limit - gameover_countdown_duration:
				Ref.sound_manager.play_gui_sfx("countdown_a")
				modulate = Set.color_red

	
	
