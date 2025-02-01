extends Control


signal sudden_death_activated # pošlje se v hud, ki javi game managerju
signal gametime_is_up # pošlje se v hud, ki javi game managerju

enum TIMER_MODE {COUNT_UP, COUNT_DOWN}
var timer_mode: int = TIMER_MODE.COUNT_UP

enum TIMER_STATE {COUNTING, STOPPED, PAUSED}
var timer_state: int = TIMER_STATE.STOPPED

var game_time: float # čas igre v sekundah z decimalkami
var game_time_hunds: int # čas igre v zaokroženih stotinkah

# opredelijo se bo štartu tajmerja
var hunds_mode: bool
var sudden_death_mode: bool # dela samo, če ni stopwatch mode

var game_time_limit: float
var countdown_start_limit: int
onready var mins_label: Label = $Mins
onready var secs_label: Label = $Secs
onready var hunds_label: Label = $Hunds


func _ready() -> void:

	# večino setam ob štartu tajmerja
	modulate = Rfs.color_hud_base
#	yield(Rfs.game_manager, "ready")
#	reset_timer()


func _process(delta: float) -> void:

	if timer_state == TIMER_STATE.COUNTING:
		game_time += delta
		game_time_hunds = round(game_time * 100)

		# zapišem
		if timer_mode == TIMER_MODE.COUNT_UP:
			mins_label.text = "%02d" % floor(game_time / 60)
			secs_label.text = "%02d" % (floor(game_time) - floor(game_time / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time - floor(game_time)) * 100)
		else:
			var game_time_left: float = game_time_limit - game_time
			mins_label.text = "%02d" % (floor(game_time_left / 60))
			secs_label.text = "%02d" % (floor(game_time_left) - floor(game_time_left / 60) * 60)
			hunds_label.text = "%02d" % floor((game_time_left - floor(game_time_left)) * 100)

			# game time is up
			#			printt(game_time, game_time_limit, game_time - game_time_limit)
			if game_time_left <= 0:
				modulate = Rfs.color_red
				stop_timer()
				game_time = game_time_limit # namesto spodnjega zapisa ... ne deluje
				mins_label.text = "00"
				secs_label.text = "00"
				hunds_label.text = "00"
				Rfs.sound_manager.play_gui_sfx("game_countdown_a")
				if sudden_death_mode:
					emit_signal("sudden_death_activated") # pošlje se v hud, ki javi game managerju
				else:
					emit_signal("gametime_is_up") # pošlje se v hud, ki javi GM
			# GO countdown
			elif game_time_left < countdown_start_limit: # če je countdown limit 0, ta pogoj nikoli ne velja
				# za vsakič, ko mine sekunda
				if game_time == floor(game_time):
					Rfs.sound_manager.play_gui_sfx("game_countdown_b")
				modulate = Rfs.color_yellow


func reset_timer(timer_limit: float = game_time_limit):

	# setup
	game_time_limit = timer_limit
	sudden_death_mode = Sts.sudden_death_mode
	countdown_start_limit = Sts.countdown_start_limit # čas, ko je obarvan in se sliši bip bip
	if game_time_limit == 0:
		timer_mode = TIMER_MODE.COUNT_UP
	else:
		timer_mode = TIMER_MODE.COUNT_DOWN
	if not hunds_mode:
		get_node("Dots2").hide()
		hunds_label.hide()
	else:
		get_node("Dots2").show()
		hunds_label.show()

	# reset
	modulate = Rfs.color_hud_base
	game_time = 0
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
	modulate = Rfs.color_red
