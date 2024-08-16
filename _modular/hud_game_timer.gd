extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

enum TimerStates {COUNTING, STOPPED, PAUSED}
var current_timer_state: int = TimerStates.STOPPED

var game_time: float # pozitiven čas igre v sekundah z decimalkami
var countdown_second: int # za uravnavanje GO odštevanja ... opredeli s v ready
var game_time_hunds: float # stotinke ... ker LL beleži samo cela števila

var game_time_limit: int
var sudden_death_mode: bool
var sudden_death_limit: int
var stopwatch_mode: bool
var gameover_countdown_duration: int

# bugfixing
var correction_timer_seconds: float = 0
onready var correction_timer: Timer = $CorrectionTimer

	
func _ready() -> void:
	
	# večino setam ob štartu tajmerja
	
	modulate = Global.color_hud_text
	# ker ga moduliram tukaj in je label ima na node tu setano font color override
	game_time_limit = Global.game_manager.game_settings["game_time_limit"]

	
func _process(delta: float) -> void:
	
	# če ne štopam, poskrbim, da je ura prava
	if not current_timer_state == TimerStates.COUNTING:
		# če je čas na nuli zapiše drugače glede na mode
		if game_time == 0:
			if not stopwatch_mode:
				$Mins.text = "%02d" % (game_time_limit / 60)
				$Secs.text = "%02d" % (game_time_limit % 60)
				$Hunds.text = "00"
				pass				
			else:
				$Mins.text = "00"
				$Secs.text = "00"
				$Hunds.text = "00"
	else:	
		# game time
		game_time += delta # sekunde z decimalkami ... absouletnega uporabljam za izračune v vseh modetih
		game_time_hunds = round(game_time * 100)
		
		# display
		if stopwatch_mode:	
			$Mins.text = "%02d" % floor(game_time/60)
			$Secs.text = "%02d" % (floor(game_time) - floor(game_time/60) * 60)
			$Hunds.text = "%02d" % floor((game_time - floor(game_time)) * 100)
		else:
			var game_time_left = game_time_limit - game_time # stotinke
			$Mins.text = "%02d" % (floor(game_time_left/60))
			$Secs.text = "%02d" % (floor(game_time_left) - floor(game_time_left/60) * 60)
			$Hunds.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)	
			
			# game time is up
			if game_time >= game_time_limit: 
				Global.sound_manager.play_sfx("game_countdown_b")
				stop_timer()
				$Mins.text = "00"
				$Secs.text = "00"
				$Hunds.text = "00"
				emit_signal("gametime_is_up") # pošlje se v hud, ki javi GM	
			# GO countdown
			elif game_time > (game_time_limit - gameover_countdown_duration):
				# za vsakič, ko mine sekunda 
				if game_time == round(game_time): 
					countdown_second -= 1
					modulate = Global.color_yellow
					Global.sound_manager.play_sfx("game_countdown_a")
			# sudden death 
			elif game_time > (game_time_limit - sudden_death_limit) and sudden_death_mode: 
				modulate = Global.color_green
				emit_signal("sudden_death_activated") # pošlje se v hud, ki javi game managerju
			else:
				modulate = Global.color_hud_text


func reset_timer():
	
	game_time = 0
	modulate = Global.color_hud_text
	
	
func start_timer():
	
	# je na ready game_time_limit = Global.game_manager.game_settings["game_time_limit"]
	gameover_countdown_duration = 5 # čas, ko je obarvan in se sliši bip bip	

	if game_time_limit == 0:
		stopwatch_mode = true # avtomatično pač ...
	countdown_second = gameover_countdown_duration	
		
	#	correction_timer.start()
	
	# reset vrendosti se zgodi na štart (ne na stop)
	game_time = 0
	current_timer_state = TimerStates.COUNTING


func pause_timer():
	
	#	correction_timer.set_paused(true)
	current_timer_state = TimerStates.PAUSED
#	modulate = Global.color_blue
	

func unpause_timer():
	
	#	correction_timer.set_paused(false)
	current_timer_state = TimerStates.COUNTING
	
		
func stop_timer():
	
	#	correction_timer.stop()	
	current_timer_state = TimerStates.STOPPED
#	modulate = Global.color_red


func _on_CorrectionTimer_timeout() -> void:
	
	correction_timer_seconds += 1
	
