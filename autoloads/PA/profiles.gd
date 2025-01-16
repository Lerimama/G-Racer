extends Node


func TOP(): pass


enum HighscoreTypes {NONE, POINTS, TIME}


enum TOUCH_CONTROLLER {DISABLED, BUTTONS_RIGHT, BUTTONS_LEFT, SCREEN_RIGHT, SCREEN_LEFT} # zaporedje more bit, da so SCREEN na koncu (settings uporablja)
var touch_controller_content: Dictionary = {
	TOUCH_CONTROLLER.DISABLED: {"Disabled": "Touch controls DISABLED"},
	TOUCH_CONTROLLER.BUTTONS_RIGHT:  {"Buttons Right": "On-screen BUTTONS, Burst on right"},
	TOUCH_CONTROLLER.BUTTONS_LEFT:  {"Buttons Left": "On-screen BUTTONS, Burst on left"},
	TOUCH_CONTROLLER.SCREEN_RIGHT:  {"Sliding Right": "SLIDE tracking for motion, Burst on right"},
	TOUCH_CONTROLLER.SCREEN_LEFT:  {"Sliding Left": "SLIDE tracking for motion, Burst on left"},
}

var default_player_stats: Dictionary = {
	"player_name": "Somebody", # to ime se piše v HS procesu, če igralec pusti prazno
	"player_life": 0, # se opredeli iz game_settings
	"player_energy": 0, # se opredeli iz game_settings
	"player_points": 0,
	"colors_collected": 0,
	"skill_count": 0,
	"burst_count": 0,
	"cells_traveled": 0,
}

var default_game_settings: Dictionary = { # per game
	# player
	"player_start_life": 1, # 1 lajf skrije ikone v hudu, on hit jemlje energijo ne lajfa
	"player_start_color": Global.color_dark_gray_pixel, # na začetku je bel, potem se animira v start color ... #232323, #141414
	"player_step_time": 0.09, # default hitrost
	"player_start_energy": 192,
	# points
	"color_picked_points": 10,
	"white_eliminated_points": 100,
	"cleaned_reward_points": 2, # 1 izpiše se "SUCCESS!", večja kot ena vedno podvoji trnuten skor
	# energija
	"color_picked_energy": 10,
	"cell_traveled_energy": 0,
	"on_hit_wall_energy_factor": 1, # 1 ... energija ostane ista
	"on_get_hit_energy_factor": 0, # 0 ... izguba lajfa
	# reburst
	"reburst_mode": false,
	"reburst_hit_power": 0, # 0 gre po original pravilih moči, trenutno je 5 full power
	"reburst_window_time": 0.2, # 0 je neomejen čas
	# strays
	"create_strays_count": 0,
	"spawn_white_stray_part": 0, # procenti spawnanih ... 0 ne spawna nobenega belega
	"spawn_white_stray_part_limit": 0.5, # klempam, da ni "brezveznih" situacij
	"respawn_strays_count_range": [0,0], # če je > 0, je respawn aktiviran
	"respawn_pause_time": 1, # če je 0 lahko pride do errorja (se mi zdi, da n 0, se timer sam disejbla)
	"respawn_pause_time_low": 1, # klempam navzdol na tole
	"stray_step_time": 0.4, # ne manjši od 0.2
	"stray_step_pause_time": 1, # ne sme bit manjša od stray step hitrosti (0.2), je clampana ob apliciranju
	# game
	"game_time_limit": 0, # če je nič, ni omejeno in timer je stopwatch mode
	"color_pool_colors_count": 500,
	"step_slowdown_mode": true,
	"full_power_mode": false, # vedno destroja ves stack, hitrost = max_cock_count
	"game_music_track_index": 0, # default muska v igri
	"follow_mode": false,
	"still_time_limit": 0, # 0 je disejblano ... ko si pri miru se nekaj lahko zgodi
	"show_expressions": true,
	"ranking_score_limit": 1,
	# gui
	"start_countdown": true,
	"zoom_to_level_size": false, # SHOWCASE
	"always_zoomed_in": false, # SWEEPER, ERASER # play iz GO je že zumiran
}


# GAME DATA -----------------------------------------------------------------------------------
func GAME_DATA(): pass


enum Games {CLEANER, ERASER, HUNTER, DEFENDER, SWEEPER, THE_DUEL, SHOWCASE}

var game_text: Dictionary = {
#	name_input_label_good.text = "But still ... "
	"name_input_label_GOOD": "Great work!",
	"name_input_label_BAD": "But still ...",
	"outline_record_TIME": "No record time yet ...",
	"outline_record_POINTS": "No record top score yet ...",
	"btn_empty_score_string": "Waiting for\nfirst cleaning",
}

var game_data: Dictionary = {

	Games.CLEANER: {
			"game": Games.CLEANER, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.POINTS,
			"game_name": "Cleaner",
			"level_name": "", # prazn pomeni samo uporabo game_name
			"description": "%d minutes to show your cleaning skills!" % 5,
			"home_btn_desc": "%d minutes to show your cleaning skills!" % 5,
			"game_over_subtitle_CLEANED": "You are the brightest of them all!",
			"game_over_subtitle_TIME": "Time is up!", # time up
			"game_over_subtitle_LIFE": "Can't handle the colors?", # lost life
			"game_over_subtitle_RECORD": "You've set a new record!",
#			"game_scene_path": "res://game/game.tscn"
			},
	Games.DEFENDER: {
			"game": Games.DEFENDER, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.POINTS,
			"game_name": "Defender",
			"level_name": "",
			"description": "Stop the invading strays from taking over!",
			"home_btn_desc": "Stop the invading strays from taking over!",
			"game_over_subtitle_CLEANED": "You are the brightest of them all!",
			"game_over_subtitle_TIME": "You were overpowered.", # full sceen
			"game_over_subtitle_LIFE": "You were surrounded.", # surrounded
			"game_over_subtitle_RECORD": "You've set a new record!",
			# štart
			"level_goal_count": 10, # igra je "goal_mode" ... uporablja var current level
			"spawn_round_range": [1, 1], # random spawn count, največ 120 - 8
			"line_steps_per_spawn_round": 1, # na koliko stepov se spawna nova runda
			# level up
			"level_goal_count_grow": 10, # dodatno prištejem
			"line_step_pause_time_factor": 0.8, # množim z vsakim levelom
			"spawn_round_range_grow": [1, 2], # množim [spodnjo, zgornjo] mejo
			"game_scene_path": "res://game/game_defender.tscn"
			},
	Games.HUNTER: {
			"game": Games.HUNTER, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.POINTS,
			"game_name": "Hunter",
			"level_name": "",
			"description" : "Keep the saturation in check as colors keep popping in!",
			"home_btn_desc" : "Keep the saturation in check as colors keep popping in!",
			"game_over_subtitle_CLEANED": "You are the brightest of them all!",
			"game_over_subtitle_TIME": "Your screen is drowning in colors.", # full sceen,
			"game_over_subtitle_LIFE": "You were surrounded.", # surrounded
			"game_over_subtitle_RECORD": "You've set a new record!",
			# štart
			"level_goal_count": 1, # igra je "goal_mode" ... uporablja var current level
			# level up
			"level_goal_count_grow": 10,
			"create_strays_count_grow": 0, # default seta tilemp
			"respawn_strays_count_range_grow": [1,3], # prištejem ... default v settingsih [2,8]
			"respawn_pause_time_factor": 0.80, # default v settingsih 3
			"spawn_white_stray_part_grow": 0, # omejena na 2. level na set_new_level ... default v settingsih 0.21
#			"game_scene_path": "res://game/game.tscn"
			},
	Games.ERASER: {
			"game": Games.ERASER, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.TIME,
			"game_name": "Eraser",
			"level_name": "XS",
			"description": "Erasing sprint! %d designs need to be completely erased!" % 9,
			"home_btn_desc": "Erasing sprint! %d designs need to be completely erased!" % 9,
			"game_over_subtitle_CLEANED": "You are the brightest of them all!",
			"game_over_subtitle_TIME": "You need to be faster!", # lost momentum,
			"game_over_subtitle_LIFE": "Is the White to bright?", # če ostanejo samo beli
			"game_over_subtitle_RECORD": "You've set a new record!",
#			"game_scene_path": "res://game/game.tscn"
			},
	Games.SWEEPER: {
			"game": Games.SWEEPER, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.TIME,
			"game_name": "Sweeper",
			"level_name": "%02d" % 1,
			"description": "Sweep them all in one move! %d screens need a quick cleaning service." % 16,
			"home_btn_desc": "Sweep them all in one move! %d screens need a quick cleaning service." % 16,
			"Prop" : "Destroy the first stray and keep your momentum by pressing in the next target's direction.",
			"game_over_subtitle_CLEANED": "That was impressive!",
			"game_over_subtitle_TIME": "You missed the target.", # nemogoče,
			"game_over_subtitle_LIFE": "You missed the target.", # če ostanejo samo beli
			"game_over_subtitle_RECORD": "You've set a new record!",
#			"game_scene_path": "res://game/game.tscn"
			},
	Games.THE_DUEL: {
			"game": Games.THE_DUEL, # key igre je key lootlocker tabele
			"highscore_type": HighscoreTypes.NONE,
			"game_name": "The Duel",
			"level_name": "",
			"tilemap_path": "res://game/tilemaps/tilemap_duel.tscn",
			"description": "Couch showdown! Battle for the ultimate cleaning champ title!",
			"home_btn_desc": "Couch showdown! Battle for the ultimate cleaning champ title!",
			"Prop": "Hit the opposing player\nto take his life and\nhalf of his points.",
			"game_over_subtitle_CLEANED": "...", # nemogoče,
			"game_over_subtitle_TIME_DRAW": "You both collected the same amount of points.", # draw
			"game_over_subtitle_TIME_WIN": " was %d points better than ", # winner/loser
			"game_over_subtitle_TIME_TIGHT": " was better by only one point.", # winner/loser
			"game_over_subtitle_LIFE": " couldn't handle all the saturation.", # player X lose all life
#			"game_scene_path": "res://game/game.tscn"
			},
}

var tilemap_paths: Dictionary = {
	# zaporedje vpliva na zaporedje gumbov
	# če je število tilemapov večje od ena ima svoj ekran
	Games.ERASER: [
			"res://game/tilemaps/eraser/tilemap_eraser_xs.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_s.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_m.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_l.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_xl.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_checker.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_maze.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_shark.tscn",
			"res://game/tilemaps/eraser/tilemap_eraser_snake.tscn",
#			"res://game/tilemaps/eraser/tilemap_eraser_butter.tscn",
			],
	Games.SWEEPER: [
			"res://game/tilemaps/sweeper/tilemap_sweeper_01.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_02.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_03.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_04.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_05.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_06.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_07.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_08.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_09.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_10.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_11.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_12.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_13.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_14.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_15.tscn",
			"res://game/tilemaps/sweeper/tilemap_sweeper_16.tscn" # pixel astray
			],
	Games.CLEANER: ["res://game/tilemaps/tilemap_cleaner.tscn"],
	Games.DEFENDER: ["res://game/tilemaps/tilemap_defender.tscn"],
	Games.HUNTER: ["res://game/tilemaps/tilemap_hunter.tscn"],
	Games.THE_DUEL: ["res://game/tilemaps/tilemap_duel.tscn"],
}


# PROCES -----------------------------------------------------------------------------------


var html5_mode: bool = false # skrije ExitGameBtn v home, GO in pavzi
var touch_available: bool = false
var debug_mode: bool = false
var tutorial_music_track_index: int = 3
# settings (home)
var use_default_color_theme: bool = true # sejvam
var pregame_screen_on: bool = true # sejvam
var camera_shake_on: bool = true # sejvam
var tutorial_mode: bool = true # sejvam
var analytics_mode: bool = true
var brightness: float = 1 setget _change_brightness # 0.6 > 1.1 ... def = 1
var vsync_on: bool = true setget _change_vsync
var set_touch_controller: int = TOUCH_CONTROLLER.BUTTONS_RIGHT
var screen_touch_sensitivity: float = 0.1 # 0 - 20% VP width ... def 0.1 ... ročno nastavljen ticker node
var game_settings: Dictionary
var current_game_data: Dictionary # ob štartu igre se vrednosti injicirajo v "current_game_data"
var start_with_method: String = "home_in_intro"

var game_scene_path: String = "res://game/game.tscn"
var game_scene_defender_path: String = "res://game/game_defender.tscn"
var home_scene_path: String = "res://home/home.tscn"


func _ready() -> void:

	# opredelim app mode
	if OS.get_name() == "HTML5":
		html5_mode = true
	else:
		html5_mode = false
	analytics_mode = not html5_mode # vsa analitika preverja, če je v modu
	vsync_on = not html5_mode
	tutorial_mode = not html5_mode
	touch_available = OS.has_touchscreen_ui_hint()
	debug_mode = OS.is_debug_build()

	# nastavim sejvane settingse
	if not html5_mode:
		# slovar sejvam v data
		var apply_game_settings: Dictionary = Data.read_settings_from_file() # če fileta ni, pobere trenutno setane vrednosti
		pregame_screen_on = apply_game_settings["pregame_screen_on"]
		camera_shake_on = apply_game_settings["camera_shake_on"]
		tutorial_mode = apply_game_settings["tutorial_mode"]
		analytics_mode = apply_game_settings["analytics_mode"]
		self.vsync_on = apply_game_settings["vsync_on"]
		# neu
		set_touch_controller = apply_game_settings["touch_controller"]
		screen_touch_sensitivity = apply_game_settings["touch_sensitivity"]

	tutorial_mode = false # _temp

	# če greš iz menija je tole povoženo
	if debug_mode:
#		var debug_game = Games.SHOWCASE # fix camera
#		var debug_game = Games.CLEANER
#		var debug_game = Games.ERASER
#		var debug_game = Games.HUNTER
		var debug_game = Games.DEFENDER
#		var debug_game = Games.SWEEPER
#		var debug_game = Games.THE_DUEL

		start_with_method = "home_in_intro"
#		start_with_method = "home_in_no_intro"
#		start_with_method = "game_in"

#		vsync_on = false
#		analytics_mode = false
#		pregame_screen_on = false
		tutorial_mode = false
#		html5_mode = true
#		touch_available = true
#		debug_mode = false
#		game_settings["player_start_life"] = 2

		set_game_data(debug_game)
		game_settings["start_countdown"] = false
#		game_settings["ranking_score_limit"] = 1
#	start_with_method = "home_in_no_intro"



func set_game_data(selected_game):

	game_scene_path = "res://game/game.tscn" # reset defaulta, ker se spremeni v defenderju
	game_settings = default_game_settings.duplicate() # naloži default, potrebne spremeni ob loadanju igre

	game_settings["pregame_screen_on"] = pregame_screen_on # da se seta aka per-game in osnovnega ne spreminjam

	match selected_game:
		Games.CLEANER:
			current_game_data = game_data[Games.CLEANER].duplicate()
			game_settings["game_time_limit"] = 300
			game_settings["create_strays_count"] = 500
			game_settings["start_countdown"] = false
		Games.ERASER:
			current_game_data = game_data[Games.ERASER].duplicate()
			game_settings["game_time_limit"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["spawn_white_stray_part"] = 0.11 # 10 posto
#			current_game_data["level_name"] = "XL"
			match current_game_data["level_name"]:
				"XS": game_settings["create_strays_count"] = 32
				"S": game_settings["create_strays_count"] = 50
				"M": game_settings["create_strays_count"] = 140
				"L": game_settings["create_strays_count"] = 230
				"XL": game_settings["create_strays_count"] = 320
				_: pass # določa tilemap
		Games.HUNTER:
			current_game_data = game_data[Games.HUNTER].duplicate()
			game_settings["respawn_strays_count_range"] = [2, 8]
			game_settings["respawn_pause_time"] = 3
			game_settings["spawn_white_stray_part"] = 0.32
			game_settings["start_countdown"] = false
		Games.DEFENDER:
			current_game_data = game_data[Games.DEFENDER].duplicate()
			game_scene_path = game_scene_defender_path
			game_settings["full_power_mode"] = true
			game_settings["create_strays_count"] = 1
			game_settings["start_countdown"] = false
			game_settings["follow_mode"] = true
		Games.SWEEPER:
			current_game_data = game_data[Games.SWEEPER].duplicate()
#			current_game_data["level_name"] = "04"
			game_settings["player_start_life"] = 1
			game_settings["on_hit_wall_energy_factor"] = 0
			game_settings["player_start_color"] = Color.white
			game_settings["color_picked_points"] = 0
			game_settings["cleaned_reward_points"] = 1
			game_settings["reburst_mode"] = true
			game_settings["reburst_window_time"] = 0
			game_settings["game_music_track_index"] = 3
			# zoom-in je samo prvi level iz home menija
			# med igro se seta na off, da ostane zoomiran
			tutorial_mode = false # _temp rabi posebn tutorial
		Games.THE_DUEL:
			current_game_data = game_data[Games.THE_DUEL].duplicate()
			game_settings["player_start_life"] = 3
			game_settings["game_time_limit"] = 180 # tilemap set
			game_settings["respawn_strays_count_range"] = [1, 14]
			game_settings["spawn_white_stray_part"] = 0.21
			tutorial_mode = false


func _change_brightness(set_value: float):
	# najprej preveri home env, če ga ni je v pvza meniju

	var arena_enviroment: Environment
	var enviroment_node: WorldEnvironment = Global.game_manager.get_node("ArenaEnvironment")
	if enviroment_node == null:
		enviroment_node = Global.game_arena.get_node("ArenaEnvironment")
	arena_enviroment = enviroment_node.environment

	brightness = set_value
	arena_enviroment.adjustment_brightness = brightness


func _change_vsync(set_on: bool):

	vsync_on = set_on
	OS.vsync_enabled = vsync_on
	#	print ("vsync post ", OS.vsync_enabled)
