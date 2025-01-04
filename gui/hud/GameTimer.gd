extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

enum TIMER_STATE {COUNTING, STOPPED, PAUSED}
var current_timer_state: int = TIMER_STATE.STOPPED

var game_time: float # čas igre v sekundah z decimalkami
var game_time_hunds: int # čas igre v zaokroženih stotinkah

# opredelijo se bo štartu tajmerja
var hunds_mode: bool
var stopwatch_mode: bool 
var sudden_death_mode: bool # dela samo, če ni stopwatch mode
 
var game_time_limit: float
var countdown_start_limit: int
onready var mins_label: Label = $Mins
onready var secs_label: Label = $Secs
onready var hunds_label: Label = $Hunds


func _ready() -> void:
	
	# večino setam ob štartu tajmerja
	modulate = Refs.color_hud_base
	reset_timer()


func _process(delta: float) -> void:
	
	if current_timer_state == TIMER_STATE.COUNTING:
		game_time += delta
		game_time_hunds = round(game_time * 100)
		
		# zapišem
		if stopwatch_mode:	
			mins_label.text = "%02d" % floor(game_time / 60)
			secs_label.text = "%02d" % (floor(game_time) - floor(game_time / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time - floor(game_time)) * 100)
		else:
			var game_time_left: float = game_time_limit - game_time
			mins_label.text = "%02d" % (floor(game_time_left / 60))
			secs_label.text = "%02d" % (floor(game_time_left) - floor(game_time_left / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)	
		
			# game time is up
			printt(game_time, game_time_limit, game_time - game_time_limit)
			if game_time_left <= 0:
				modulate = Refs.color_red
				stop_timer()
				game_time = game_time_limit # namesto spodnjega zapisa ... ne deluje
				mins_label.text = "00"
				secs_label.text = "00"
				hunds_label.text = "00"
				Refs.sound_manager.play_gui_sfx("game_countdown_a")
				if sudden_death_mode:
					emit_signal("sudden_death_activated") # pošlje se v hud, ki javi game managerju
				else:				
					emit_signal("gametime_is_up") # pošlje se v hud, ki javi GM	
			# GO countdown
			elif game_time_left < countdown_start_limit: # če je countdown limit 0, ta pogoj nikoli ne velja
				# za vsakič, ko mine sekunda 
				if game_time == floor(game_time): 
					Refs.sound_manager.play_gui_sfx("game_countdown_b")
				modulate = Refs.color_yellow
	

func reset_timer():
	
	# skrijem stotinke?
	if not hunds_mode:
		get_node("Dots2").hide()
		hunds_label.hide()
	
	modulate = Refs.color_hud_base
	
	game_time = 0
	game_time_hunds = 0

	if stopwatch_mode:
		mins_label.text = "00"
		secs_label.text = "00"
		hunds_label.text = "00"
	else:
		mins_label.text = "%02d" % (game_time_limit / 60)
		secs_label.text = "%02d" % (int(game_time_limit) % 60)
		hunds_label.text = "00"
	
	
func start_timer():

	game_time_limit = Refs.game_manager.level_settings["time_limit"]
	sudden_death_mode = Refs.game_manager.game_settings["sudden_death_mode"]
	countdown_start_limit = Refs.game_manager.game_settings["countdown_start_limit"] # čas, ko je obarvan in se sliši bip bip	
	
	if game_time_limit == 0:
		stopwatch_mode = true
		
	reset_timer()
	current_timer_state = TIMER_STATE.COUNTING


func pause_timer():
	
	current_timer_state = TIMER_STATE.PAUSED
	

func unpause_timer():
	
	current_timer_state = TIMER_STATE.COUNTING
	
		
func stop_timer():
	
	current_timer_state = TIMER_STATE.STOPPED
	modulate = Refs.color_red
