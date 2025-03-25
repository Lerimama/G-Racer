extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal time_is_up # pošlje se v hud, ki javi game managerju

enum TIMER_MODE {COUNT_UP, COUNT_DOWN}
var timer_mode: int = TIMER_MODE.COUNT_UP

enum TIMER_STATE {STOPPED, COUNTING, PAUSED}
var timer_state: int = TIMER_STATE.STOPPED

var game_time_secs: float # čas igre v sekundah z decimalkami
var game_time_hunds: int # čas igre v zaokroženih stotinkah

# opredelijo se bo štartu tajmerja
var hunds_mode: bool
var sudden_death_mode: bool # dela samo, če ni stopwatch mode
var start_timer_os_msecs: int = -1

var game_time_limit: float # opredeli ga reset
var countdown_start_time: int # opredeli ga reset
var sudden_death_start_time: int  # opredeli ga reset
onready var mins_label: Label = $MinSec/Mins
onready var secs_label: Label = $MinSec/Secs
onready var hunds_label: Label = $Hunds/Hunds
onready var game_coundown_sound_a: AudioStreamPlayer = $Sounds/GameCoundownA
onready var game_coundown_sound_b: AudioStreamPlayer = $Sounds/GameCoundownB


func _ready() -> void:

	# večino setam ob štartu tajmerja
	modulate = Refs.color_hud_base


func _process(delta: float) -> void:

	if timer_state == TIMER_STATE.COUNTING:
		if start_timer_os_msecs == -1:
			start_timer_os_msecs = Time.get_ticks_msec()

		# samo zapis v timerju .. OPT
		game_time_secs = float(Time.get_ticks_msec() - start_timer_os_msecs) / 1000
		game_time_hunds = game_time_secs * 100 # - (Time.get_ticks_msec() - start_timer_os_msecs) * 10

		# zapišem
		if timer_mode == TIMER_MODE.COUNT_UP:
			mins_label.text = "%02d" % floor(game_time_secs / 60)
			secs_label.text = "%02d" % (floor(game_time_secs) - floor(game_time_secs / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time_secs - floor(game_time_secs)) * 100)

		elif timer_mode == TIMER_MODE.COUNT_DOWN:
			var game_time_left: float = game_time_limit - game_time_secs
			mins_label.text = "%02d" % (floor(game_time_left / 60))
			secs_label.text = "%02d" % (floor(game_time_left) - floor(game_time_left / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)

			if game_time_left <= 0:
				stop_timer()
				game_time_secs = game_time_limit # namesto spodnjega zapisa ... ne deluje
				mins_label.text = "00"
				secs_label.text = "00"
				hunds_label.text = "00"
				modulate = Refs.color_red
				game_coundown_sound_a.play()
				emit_signal("time_is_up") # pošlje se v hud, ki javi GM
			# GO countdown
			elif game_time_left <= countdown_start_time: # če je countdown limit 0, ta pogoj nikoli ne velja
				# za vsakič, ko mine sekunda
				game_coundown_sound_b.play()
				countdown_start_time -= 1
				modulate = Refs.color_yellow
			elif sudden_death_mode and game_time_left < sudden_death_start_time:
				pass


func reset_timer(timer_limit: float = game_time_limit):

	timer_state = TIMER_STATE.STOPPED

	# setup
	game_time_limit = timer_limit
	sudden_death_mode = Sets.sudden_death_mode
	countdown_start_time = Sets.countdown_start_time # čas, ko je obarvan in se sliši bip bip
	sudden_death_start_time = Sets.sudden_death_start_time # čas, ko je obarvan in se sliši bip bip
	if game_time_limit == 0:
		timer_mode = TIMER_MODE.COUNT_UP
	else:
		timer_mode = TIMER_MODE.COUNT_DOWN
	if hunds_mode:
		hunds_label.get_parent().show()
	else:
		hunds_label.get_parent().hide()

	# reset
	modulate = Refs.color_hud_base
	start_timer_os_msecs = -1
	game_time_secs = 0
	game_time_hunds = 0
	if timer_mode == TIMER_MODE.COUNT_UP:
		mins_label.text = "00"
		secs_label.text = "00"
		hunds_label.text = "00"
	else:
		mins_label.text = "%02d" % (game_time_limit / 60)
		secs_label.text = "%02d" % (int(game_time_limit) % 60)
		hunds_label.text = "00"


func start_timer():

	reset_timer()
	timer_state = TIMER_STATE.COUNTING


func pause_timer():

	timer_state = TIMER_STATE.PAUSED


func unpause_timer():

	timer_state = TIMER_STATE.COUNTING


func stop_timer():

	timer_state = TIMER_STATE.STOPPED
	#	modulate = Refs.color_red
